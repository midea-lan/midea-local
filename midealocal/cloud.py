"""Midea Local cloud."""

import base64
import json
import logging
import re
import time
from asyncio import Lock, sleep
from collections.abc import Callable, Mapping
from datetime import UTC, datetime
from hashlib import md5
from http import HTTPStatus
from pathlib import PurePosixPath, PureWindowsPath
from secrets import token_hex
from typing import Any, cast

import aiofiles
from aiohttp import ClientConnectionError, ClientSession, ClientTimeout
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

from midealocal.exceptions import (
    CLOUD_ERRORS,
    LOGIN_ERROR_CODES,
    NO_PERMISSION_CODES,
    TRANSIENT_CLOUD_ERROR_CODES,
    ElementMissing,
    cloud_api_error,
)

from .security import (
    CloudSecurity,
    MeijuCloudSecurity,
    MideaAirSecurity,
    MSmartCloudSecurity,
)

SN8_MIN_SERIAL_LENGTH = 17

# Cloud error codes that have a dedicated, actionable exception subclass; every
# other non-zero code is logged and surfaced as ``None``.
RAISE_FOR_ERROR_CODES = NO_PERMISSION_CODES | LOGIN_ERROR_CODES

# Total attempts for a single cloud API call before giving up.
_RETRY_ATTEMPTS = 3

# Base delay between retries of a transient cloud error, scaled by attempt.
_TRANSIENT_RETRY_BACKOFF_SECONDS = 1.0

_LOGGER = logging.getLogger(__name__)

SUPPORTED_CLOUDS: dict[str, Any] = {
    "美的美居": {
        "class_name": "MeijuCloud",
        "app_id": "900",
        "app_key": "46579c15",
        "login_key": "ad0ee21d48a64bf49f4fb583ab76e799",
        "iot_key": bytes.fromhex(
            format(9795516279659324117647275084689641883661667, "x"),
        ).decode(),
        "hmac_key": bytes.fromhex(
            format(117390035944627627450677220413733956185864939010425, "x"),
        ).decode(),
        "api_url": "https://mp-prod.smartmidea.net/mas/v5/app/proxy?alias=",
    },
    "SmartHome": {
        "class_name": "SmartHomeCloud",
        "app_id": "1010",
        "app_key": "ac21b9f9cbfe4ca5a88562ef25e2b768",
        "iot_key": bytes.fromhex(format(7882822598523843940, "x")).decode(),
        "hmac_key": bytes.fromhex(
            format(117390035944627627450677220413733956185864939010425, "x"),
        ).decode(),
        "api_url": "https://mp-prod.appsmb.com/mas/v5/app/proxy?alias=",
    },
    "Midea Air": {
        "class_name": "MideaAirCloud",
        "app_id": "1117",
        "app_key": "ff0cf6f5f0c3471de36341cab3f7a9af",
        "api_url": "https://mapp.appsmb.com",  # codespell:ignore
    },
    "NetHome Plus": {
        "default": True,
        "class_name": "MideaAirCloud",
        "app_id": "1017",
        "app_key": "3742e9e5842d4ad59c2db887e12449f9",
        "api_url": "https://mapp.appsmb.com",  # codespell:ignore
    },
    "Ariston Clima": {
        "class_name": "MideaAirCloud",
        "app_id": "1005",
        "app_key": "434a209a5ce141c3b726de067835d7f0",
        "api_url": "https://mapp.appsmb.com",  # codespell:ignore
    },
    "OS Comfort": {
        "class_name": "MideaAirCloud",
        "app_id": "1114",
        "app_key": "02021a881e4d4b21d7fed806719e5440",
        "api_url": "https://mapp.appsmb.com",  # codespell:ignore
    },
    "Toshiba Iolife": {
        "class_name": "ToshibaIOLife",
        "app_id": "1203",
        "app_key": "09c4d09f0da1513bb62dc7b6b0af9c11",
        "api_url": "https://app.iolife.toshiba-lifestyle.com",
        "app_version": "3.4.0",
        # The API does not return an enterpriseCode, so this is the fallback.
        # 0x0008 is Toshiba's code: the app ships it as APP_ENTERPRISE
        # and it prefixes every T_0008_* protocol file.
        "manufacturer_code": "0008",
    },
}

DEFAULT_KEYS = {
    99: {
        "token": "ee755a84a115703768bcc7c6c13d3d629aa416f1e2fd798beb9f78cbb1381d09"
        "1cc245d7b063aad2a900e5b498fbd936c811f5d504b2e656d4f33b3bbc6d1da3",
        "key": "ed37bd31558a4b039aaf4e7a7a59aa7a75fd9101682045f69baf45d28380ae5c",
    },
}

PRESET_ACCOUNT_DATA = [
    39182118275972017797890111985649342047468653967530949796945843010512,
    39182118275980892824833804202177448991093361348247890162501600564413,
    39182118275972017797890111985649342050088014265865102175083010656997,
]


def get_default_cloud() -> str:
    """Return default cloud."""
    for key, value in SUPPORTED_CLOUDS.items():
        if value.get("default"):
            return key
    raise ElementMissing


def get_preset_account_cloud() -> dict[str, str]:
    """Return preset account data for cloud login."""
    username: str = bytes.fromhex(
        format((PRESET_ACCOUNT_DATA[0] ^ PRESET_ACCOUNT_DATA[1]), "X"),
    ).decode("utf-8", errors="ignore")
    password: str = bytes.fromhex(
        format((PRESET_ACCOUNT_DATA[0] ^ PRESET_ACCOUNT_DATA[2]), "X"),
    ).decode("utf-8", errors="ignore")

    return {
        "username": username,
        "password": password,
        "cloud_name": get_default_cloud(),
    }


block = "*"


def _mask_token(token: str) -> str:
    """Mask token but keep first 5 chars."""
    if not token:
        return token

    visible = token[:5]
    return visible + block * max(0, len(token) - len(visible))


# ``"token": "..."`` / ``"key": "..."`` as they appear in a getToken response,
# tolerating escaped quotes from ``str(bytes)`` rendering.
_CREDENTIAL_FIELD = re.compile(
    r'(\\?["\'](?:token|key)\\?["\']\s*:\s*\\?["\'])([^"\'\\]+)',
    re.IGNORECASE,
)


def _redact_data(data: str) -> str:
    """Redact sensitive data."""
    # Do this first: the generic patterns below only chew up parts of a token,
    # which leaves most of the credential readable and looks redacted.
    data = _CREDENTIAL_FIELD.sub(lambda m: m.group(1) + _mask_token(m.group(2)), data)
    patterns = [
        # Email
        r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
        # Phone number
        r"(?:\+?\d{1,3})?[-.\s]?(?:\(?\d{2,4}\)?[-.\s]?)?\d{3,4}[-.\s]?\d{4}",
        # Credit card
        r"\b(?:\d[ -]*?){13,19}\b",
        # BTC address
        r"\b(?:bc1|[13])[a-zA-HJ-NP-Z0-9]{25,62}\b",
        # IPv4
        r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
        # Simple street address
        (
            r"\b\d{1,5}\s+[A-Za-z0-9\s]{3,40}"
            r"(?:Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Way|Boulevard|Blvd)\b"
        ),
    ]

    for pattern in patterns:
        data = re.sub(
            pattern,
            lambda m: _mask_token(m.group(0)),
            data,
            flags=re.IGNORECASE,
        )

    return data


class MideaCloud:
    """Midea Cloud."""

    def __init__(
        self,
        session: ClientSession,
        security: CloudSecurity,
        app_id: str,
        app_key: str,
        account: str,
        password: str,
        api_url: str,
    ) -> None:
        """Initialize Midea Cloud."""
        self._device_id = CloudSecurity.get_deviceid(account)
        self._session = session
        self._security = security
        self._api_lock = Lock()
        self._app_id = app_id
        self._app_key = app_key
        self._account = account
        self._password = password
        self._api_url = api_url
        self._access_token: str | None = None
        self._uid: str | None = None
        self._login_id = ""

    def _make_general_data(self) -> dict[str, Any]:
        """Return the base fields every MSmart-style (v5 proxy) request carries.

        ``MideaAirCloud`` overrides this with the legacy ``mapp.appsmb.com``
        shape; ``MeijuCloud`` and ``SmartHomeCloud`` share this one.
        """
        return {
            "src": self._app_id,
            "format": "2",
            "stamp": datetime.now(tz=UTC).strftime("%Y%m%d%H%M%S"),
            "platformId": "1",
            "deviceId": self._device_id,
            "reqId": token_hex(16),
            "uid": self._uid,
            "clientType": "1",
            "appId": self._app_id,
            "language": "en_US",
        }

    async def _api_request(
        self,
        endpoint: str,
        data: dict[str, Any],
        header: dict[str, Any] | None = None,
        raise_for_error: bool = False,
    ) -> dict | None:
        header = header or {}
        if not data.get("reqId"):
            data.update({"reqId": token_hex(16)})
        if not data.get("stamp"):
            data.update(
                {"stamp": datetime.now(tz=UTC).strftime("%Y%m%d%H%M%S")},
            )
        random = str(int(time.time()))
        url = self._api_url + endpoint
        dump_data = json.dumps(data)
        sign = self._security.sign("", dump_data, random)
        header.update(
            {
                "content-type": "application/json; charset=utf-8",
                "secretVersion": "1",
                "sign": sign,
                "random": random,
            },
        )
        if self._uid is not None:
            header.update({"uid": self._uid})
        if self._access_token is not None:
            header.update({"accessToken": self._access_token})
        response: dict = {"code": -1}
        for attempt in range(_RETRY_ATTEMPTS):
            try:
                async with self._api_lock:
                    r = await self._session.request(
                        "POST",
                        url,
                        headers=header,
                        data=dump_data,
                        timeout=ClientTimeout(10),
                    )
                    raw = await r.read()
                    _LOGGER.debug(
                        "Midea cloud API url: %s, \n data: %s, \n response: %s",
                        url,
                        _redact_data(str(data)),
                        _redact_data(str(raw)),
                    )
                    response = json.loads(raw)
            except (TimeoutError, ClientConnectionError, json.JSONDecodeError) as e:
                _LOGGER.warning(
                    "Midea cloud API error, url: %s, error: %s",
                    url,
                    repr(e),
                )
                continue
            if not await self._retry_if_transient(url, int(response["code"]), attempt):
                break
        code = int(response["code"])
        if code == 0 and "data" in response:
            return cast("dict", response["data"])
        self._handle_error_code(
            url,
            code,
            str(response.get("msg") or ""),
            raise_for_error,
        )
        return None

    def _handle_error_code(
        self,
        url: str,
        code: int,
        message: str,
        raise_for_error: bool,
    ) -> None:
        """Log a non-zero cloud error code and raise if it maps to a known error.

        ``code`` -1 is the local "no reply" sentinel already logged by the
        caller, so it is skipped here.
        """
        if code == -1:
            return
        slug = CLOUD_ERRORS.get(code, "cloud_error")
        _LOGGER.warning(
            "Midea cloud API url: %s rejected the request with code %s (%s): %s",
            url,
            code,
            slug,
            message,
        )
        if raise_for_error and code in RAISE_FOR_ERROR_CODES:
            raise cloud_api_error(code, message)

    async def _retry_if_transient(self, url: str, code: int, attempt: int) -> bool:
        """Return whether ``code`` is a transient error worth resending.

        9999 "system error" comes back sporadically for otherwise valid calls;
        a short back-off and resend usually succeeds. When retries remain this
        waits and returns True so the caller loops again; otherwise the code is
        left in ``response`` to be surfaced by ``_handle_error_code``.
        """
        if code not in TRANSIENT_CLOUD_ERROR_CODES or attempt >= _RETRY_ATTEMPTS - 1:
            return False
        _LOGGER.warning(
            "Midea cloud API url: %s returned transient error %s; retry %s of %s",
            url,
            code,
            attempt + 1,
            _RETRY_ATTEMPTS - 1,
        )
        await sleep(_TRANSIENT_RETRY_BACKOFF_SECONDS * (attempt + 1))
        return True

    async def _get_login_id(self) -> str | None:
        data = self._make_general_data()
        data.update({"loginAccount": f"{self._account}"})
        if response := await self._api_request(
            endpoint="/v1/user/login/id/get",
            data=data,
            raise_for_error=True,
        ):
            return response.get("loginId")
        return None

    async def login(self) -> bool:
        """Authenticate."""
        raise NotImplementedError

    @staticmethod
    async def get_default_keys() -> dict[int, dict[str, Any]]:
        """Get default cloud keys."""
        return DEFAULT_KEYS

    @staticmethod
    def _store_matching_tokens(
        result: dict[int, dict[str, Any]],
        tokens: list[dict[str, Any]],
        udp_id: str | None,
        method: int,
    ) -> None:
        """Store the tokenlist entry that matches the method-specific udp id."""
        for token in tokens:
            if token["udpId"] == udp_id:
                result[method] = {
                    "token": token["token"].lower(),
                    "key": token["key"].lower(),
                }

    async def _retrieve_cloud_keys(
        self,
        appliance_id: int,
        endpoint: str,
        extra_data: dict[str, Any],
    ) -> dict[int, dict[str, Any]]:
        """Query ``endpoint`` for a token/key with UDP methods 1 and 2.

        ``extra_data`` carries the per-endpoint payload quirks: v1 wants
        ``applianceCodes`` as a bare string, v2 wants it as a list plus a
        ``homegroupId``.
        """
        result: dict[int, dict[str, Any]] = {}
        for method in (1, 2):
            udp_id = self._security.get_udp_id(appliance_id, method)
            data = self._make_general_data()
            data.update({"udpid": udp_id, **extra_data})
            response = await self._api_request(
                endpoint=endpoint,
                data=data,
                raise_for_error=True,
            )
            # Log only the entry count: the payload carries token/key material.
            tokens = (response or {}).get("tokenlist") or []
            _LOGGER.debug(
                "getToken %s for appliance_id %s method %s returned %s token entries",
                endpoint,
                appliance_id,
                method,
                len(tokens),
            )
            self._store_matching_tokens(
                result=result,
                tokens=tokens,
                udp_id=udp_id,
                method=method,
            )
        return result

    async def get_cloud_keys(self, appliance_id: int) -> dict[int, dict[str, Any]]:
        """Get keys for device."""
        # ``applianceCodes``: the MSmartHome ("SmartHome") cloud rejects getToken
        # with 3004 "value is illegal" without it; other clouds ignore the field.
        return await self._retrieve_cloud_keys(
            appliance_id,
            "/v1/iot/secure/getToken",
            {"applianceCodes": str(appliance_id)},
        )

    @staticmethod
    async def get_cloud_servers() -> dict[int, str]:
        """Get available cloud servers."""
        return {i: cloud for i, cloud in enumerate(SUPPORTED_CLOUDS, start=1)}

    async def list_home(self) -> dict[int, Any] | None:
        """List homes."""
        return {1: "My home"}

    async def list_appliances(
        self,
        home_id: str | None,
    ) -> dict[int, dict[str, Any]] | None:
        """List appliances."""
        raise NotImplementedError

    async def get_device_info(self, device_id: int) -> dict[str, Any] | None:
        """Get device information."""
        if (response := await self.list_appliances(home_id=None)) and (
            int(device_id) in response
        ):
            return cast("dict", response[device_id])
        return None

    async def download_lua(
        self,
        path: str,
        device_type: int,
        sn: str,
        model_number: str | None = None,
        manufacturer_code: str = "0000",
    ) -> str | None:
        """Download lua integration."""
        raise NotImplementedError

    async def download_plugin(
        self,
        path: str,
        device_type: int,
        sn: str,
    ) -> str | None:
        """Download lua integration."""
        raise NotImplementedError

    @staticmethod
    def _safe_download_name(file_name: str) -> str | None:
        """Return file_name if it is a single path component, else None.

        The cloud controls the file name; a name with a separator could write
        outside the target directory. Both separator styles are checked since
        Windows is a supported platform.
        """
        if file_name in {"", ".."} or (
            PurePosixPath(file_name).name != file_name
            or PureWindowsPath(file_name).name != file_name
        ):
            _LOGGER.error(
                "Refusing download file name with path components: %s",
                file_name,
            )
            return None
        return file_name

    async def _fetch_lua_file(
        self,
        path: str,
        response: dict[str, Any],
        decrypt: Callable[[str], str],
    ) -> str | None:
        """Download, decrypt and write the lua file described by a luaGet response.

        ``response`` carries ``url`` and ``fileName``; ``decrypt`` turns the
        downloaded ciphertext into lua source.
        """
        res = await self._session.get(response["url"])
        if res.status != HTTPStatus.OK:
            return None
        lua = await res.text()
        if not lua:
            return None
        file_name = self._safe_download_name(response["fileName"])
        if file_name is None:
            return None
        stream = ('local bit = require "bit"\n' + decrypt(lua)).replace("\r\n", "\n")
        fnm = f"{path}/{file_name}"
        async with aiofiles.open(fnm, "w") as fp:
            await fp.write(stream)
        return fnm

    async def _fetch_plugin_file(self, path: str, url: str) -> str | None:
        """Download the plugin binary at ``url`` and write it under ``path``."""
        file_name = self._safe_download_name(url.rsplit("/", maxsplit=1)[-1])
        if file_name is None:
            return None
        res = await self._session.get(url)
        if res.status != HTTPStatus.OK:
            return None
        plugin = await res.read()
        if not plugin:
            return None
        fnm = f"{path}/{file_name}"
        async with aiofiles.open(fnm, "wb") as fp:
            await fp.write(plugin)
        return fnm


class MeijuCloud(MideaCloud):
    """Meiju Cloud."""

    def __init__(
        self,
        cloud_name: str,
        session: ClientSession,
        account: str,
        password: str,
    ) -> None:
        """Initialize Meiju Cloud."""
        cloud_data = SUPPORTED_CLOUDS[cloud_name]
        super().__init__(
            session=session,
            security=MeijuCloudSecurity(
                login_key=cloud_data["login_key"],
                iot_key=cloud_data["iot_key"],
                hmac_key=cloud_data["hmac_key"],
            ),
            app_id=cloud_data["app_id"],
            app_key=cloud_data["app_key"],
            account=account,
            password=password,
            api_url=cloud_data["api_url"],
        )

    async def login(self) -> bool:
        """Authenticate to Meiju Cloud."""
        if login_id := await self._get_login_id():
            self._login_id = login_id
            stamp = datetime.now(tz=UTC).strftime("%Y%m%d%H%M%S")
            data = {
                "iotData": {
                    "clientType": 1,
                    "deviceId": self._device_id,
                    "iampwd": self._security.encrypt_iam_password(
                        self._login_id,
                        self._password,
                    ),
                    "iotAppId": self._app_id,
                    "loginAccount": self._account,
                    "password": self._security.encrypt_password(
                        self._login_id,
                        self._password,
                    ),
                    "reqId": token_hex(16),
                    "stamp": stamp,
                },
                "data": {
                    "appKey": self._app_key,
                    "deviceId": self._device_id,
                    "platform": 2,
                },
                "timestamp": stamp,
                "stamp": stamp,
            }
            if response := await self._api_request(
                endpoint="/mj/user/login",
                data=data,
                raise_for_error=True,
            ):
                self._access_token = response["mdata"]["accessToken"]
                self._security.set_aes_keys(
                    self._security.aes_decrypt_with_fixed_key(response["key"]),
                    b"0",
                )

                return True
        _LOGGER.warning("Meiju Cloud login failed for device %s", self._device_id)
        return False

    async def list_home(self) -> dict[int, Any] | None:
        """List Meiju Cloud homes."""
        if response := await self._api_request(
            endpoint="/v1/homegroup/list/get",
            data={},
        ):
            homes = {}
            for home in response["homeList"]:
                homes.update({int(home["homegroupId"]): home["name"]})
            return homes
        return None

    async def get_cloud_keys(self, appliance_id: int) -> dict[int, dict[str, Any]]:
        """Get keys for device from the Meiju cloud.

        Meiju retired the `/v1/iot/secure/getToken` endpoint the base class uses:
        its gateway now answers `{"code": 40404}` / "the access address does not
        exist", so no keys come back at all and every V3 device fails to
        authenticate with "Can't get available token from Midea server".

        The replacement is `/v2/iot/secure/getToken`, which additionally requires
        `homegroupId` and expects `applianceCodes` as a list -- passing the plain
        string the v1 endpoint accepted makes it answer `1002 none parameter is
        found`.

        Falls back to the inherited v1 implementation when v2 yields nothing, so
        this stays a no-op for clouds or accounts the old endpoint still serves.
        """
        for home_id in await self.list_home() or {}:
            result = await self._retrieve_cloud_keys(
                appliance_id,
                "/v2/iot/secure/getToken",
                {
                    "homegroupId": str(home_id),
                    "applianceCodes": [str(appliance_id)],
                },
            )
            if result:
                return result
        _LOGGER.debug(
            "v2 getToken returned no keys for appliance_id %s, "
            "falling back to the v1 endpoint",
            appliance_id,
        )
        return await super().get_cloud_keys(appliance_id)

    async def list_appliances(
        self,
        home_id: str | None,
    ) -> dict[int, dict[str, Any]] | None:
        """List Meiju Cloud devices."""
        data = {"homegroupId": home_id}
        if response := await self._api_request(
            endpoint="/v1/appliance/home/list/get",
            data=data,
        ):
            appliances = {}
            for home in response.get("homeList") or []:
                for room in home.get("roomList") or []:
                    for appliance in room.get("applianceList"):
                        try:
                            model_number = int(appliance.get("modelNumber", 0))
                        except (ValueError, TypeError):
                            model_number = 0
                        device_info = {
                            "name": appliance.get("name"),
                            "type": int(appliance.get("type"), 16),
                            "sn": (
                                self._security.aes_decrypt(appliance.get("sn"))
                                if appliance.get("sn")
                                else ""
                            ),
                            "sn8": appliance.get("sn8", "00000000"),
                            "model_number": model_number,
                            "manufacturer_code": appliance.get(
                                "enterpriseCode",
                                "0000",
                            ),
                            "model": appliance.get("productModel"),
                            "online": appliance.get("onlineStatus") == "1",
                        }
                        sn8 = device_info.get("sn8")
                        if not sn8 or len(sn8) == 0:
                            device_info["sn8"] = "00000000"
                        model = device_info.get("model")
                        if not model or len(model) == 0:
                            device_info["model"] = device_info["sn8"]
                        appliances[int(appliance["applianceCode"])] = device_info
            return appliances
        return None

    async def get_device_info(self, device_id: int) -> dict[str, Any] | None:
        """Get device information.

        API url: https://mp-prod.smartmidea.net/mas/v5/app/proxy?alias=/v1/appliance/info/get
        header:
        input: {'applianceCode': 21000***830**18,
            'reqId': 'b11bb9083be6d77906fe1c9f019cdea0', 'stamp': '20240710092728'}
        response: b'{"code":0,"msg":null,"data":{"id":null,
            "applianceCode":21000***830**18,
            "sn":"7105f17f36a6afcce272f8053e2be60fd74b1a4baca120afaad83011bb50e8d5f3678bf88e32ea11885394e1a32c9c0e",
            "onlineStatus":1,"type":"0xDB","modelNumber":"12877",
            "name":"device_name_bytearray",
            "des":null,"activeStatus":1,"activeTime":"2024-06-12 10:45:45",
            "masterId":null,"wifiVersion":"059009012205","enterprise":"0000",
            "isOtherEquipment":null,"attrs":null,"roomName":null,
            "btMac":"54B8740FA801","btToken":null,"hotspotName":null,
            "isBluetooth":0,"bindType":null,"ability":null,"nameChanged":null,
            "sn8":"38127874","supportWot":false,"templateOfTSL":null,
            "shadowLevel":null,"smartProductId":10004256,"brand":null}}'
        """
        data = {"applianceCode": device_id}
        if response := await self._api_request(
            endpoint="/v1/appliance/info/get",
            data=data,
        ):
            try:
                model_number = int(response.get("modelNumber", 0))
            except (ValueError, TypeError):
                model_number = 0
            model_type = response.get("type")
            device_info = {
                "name": response.get("name"),
                "type": int(model_type, 16) if model_type else 0,
                "sn": self._security.aes_decrypt(response.get("sn") or ""),
                "sn8": response.get("sn8", "00000000"),
                "model_number": model_number,
                "manufacturer_code": response.get("enterpriseCode", "0000"),
                "model": response.get("productModel"),
                "online": response.get("onlineStatus") == "1",
                "des": response.get("des", None),
                "active_status": response.get("activeStatus", None),
                "active_time": response.get("activeTime", None),
                "master_id": response.get("masterId", None),
                "wifi_version": response.get("wifiVersion", None),
                "enterprise": response.get("enterprise", None),
                "is_other_equipment": response.get("isOtherEquipment", None),
                "attrs": response.get("attrs", None),
                "room_name": response.get("roomName", None),
                "bt_mac": response.get("btMac", None),
                "bt_token": response.get("btToken", None),
                "hotspot_name": response.get("hotspotName", None),
                "is_bluetooth": response.get("isBluetooth", None),
                "bind_type": response.get("bindType", None),
                "ability": response.get("ability", None),
                "name_changed": response.get("nameChanged", None),
                "support_wot": response.get("supportWot", None),
                "template_of_tsl": response.get("templateOfTSL", None),
                "shadow_level": response.get("shadowLevel", None),
                "smart_product_id": response.get("smartProductId", None),
                "brand": response.get("brand", None),
            }
            sn8 = device_info.get("sn8")
            if sn8 is None or len(sn8) == 0:
                device_info["sn8"] = "00000000"
            model = device_info.get("model")
            if model is None or len(model) == 0:
                device_info["model"] = device_info["sn8"]
            return device_info
        return None

    async def download_lua(
        self,
        path: str,
        device_type: int,
        sn: str,
        model_number: str | None = None,  # noqa: ARG002
        manufacturer_code: str = "0000",
    ) -> str | None:
        """Download lua integration."""
        data = {
            "applianceSn": sn,
            "applianceType": hex(device_type),
            "applianceMFCode": manufacturer_code,
            "version": "0",
            "iotAppId": self._app_id,
        }
        if response := await self._api_request(
            endpoint="/v1/appliance/protocol/lua/luaGet",
            data=data,
        ):
            return await self._fetch_lua_file(
                path,
                response,
                self._security.aes_decrypt_with_fixed_key,
            )
        return None

    async def download_plugin(
        self,
        path: str,
        device_type: int,
        sn: str,
    ) -> str | None:
        """Download lua integration."""
        data = self._make_general_data()
        data.update(
            {
                "clientVersion": "201",
                "match": "1",
                "applianceList": [
                    {
                        "appModel": sn[9:17],
                        "appType": hex(device_type),
                        "modelNumber": "0",
                    },
                ],
            },
        )
        if response := await self._api_request(
            endpoint="/v1/plugin/update/getplugin",
            data=data,
        ):
            _LOGGER.debug("response: %s, type: %s", response, type(response))
            return await self._fetch_plugin_file(path, response["list"][0]["url"])
        return None


class SmartHomeCloud(MideaCloud):
    """MSmart Home Cloud."""

    def __init__(
        self,
        cloud_name: str,
        session: ClientSession,
        account: str,
        password: str,
    ) -> None:
        """Initialize MSmart Cloud."""
        cloud_data = cast("dict[str, Any]", SUPPORTED_CLOUDS[cloud_name])
        super().__init__(
            session=session,
            security=MSmartCloudSecurity(
                login_key=cloud_data["app_key"],
                iot_key=cloud_data["iot_key"],
                hmac_key=cloud_data["hmac_key"],
            ),
            app_id=cloud_data["app_id"],
            app_key=cloud_data["app_key"],
            account=account,
            password=password,
            api_url=cloud_data["api_url"],
        )
        self._auth_base = base64.b64encode(
            f"{self._app_key}:{cloud_data['iot_key']}".encode(
                "ascii",
            ),
        ).decode("ascii")

    async def _api_request(
        self,
        endpoint: str,
        data: dict[str, Any],
        header: dict[str, Any] | None = None,
        raise_for_error: bool = False,
    ) -> dict[str, Any] | None:
        header = header or {}
        header.update(
            {"x-recipe-app": self._app_id, "authorization": f"Basic {self._auth_base}"},
        )

        return await super()._api_request(endpoint, data, header, raise_for_error)

    async def _re_route(self) -> None:
        data = self._make_general_data()
        data.update({"userType": "0", "userName": f"{self._account}"})
        if (
            response := await self._api_request(
                endpoint="/v1/multicloud/platform/user/route",
                data=data,
            )
        ) and (api_url := response.get("masUrl")):
            self._api_url = api_url

    async def login(self) -> bool:
        """Authenticate to MSmart Cloud."""
        await self._re_route()
        if login_id := await self._get_login_id():
            self._login_id = login_id
            iot_data = self._make_general_data()
            iot_data.pop("uid")
            stamp = datetime.now(tz=UTC).strftime("%Y%m%d%H%M%S")
            iot_data.update(
                {
                    "iampwd": self._security.encrypt_iam_password(
                        self._login_id,
                        self._password,
                    ),
                    "loginAccount": self._account,
                    "password": self._security.encrypt_password(
                        self._login_id,
                        self._password,
                    ),
                    "stamp": stamp,
                },
            )
            data = {
                "iotData": iot_data,
                "data": {
                    "appKey": self._app_key,
                    "deviceId": self._device_id,
                    "platform": "2",
                },
                "stamp": stamp,
            }
            if response := await self._api_request(
                endpoint="/mj/user/login",
                data=data,
                raise_for_error=True,
            ):
                self._uid = response["uid"]
                self._access_token = response["mdata"]["accessToken"]
                self._security.set_aes_keys(
                    response["accessToken"],
                    response["randomData"],
                )
                return True
        _LOGGER.warning("SmartHome Cloud login failed for device %s", self._device_id)
        return False

    async def list_appliances(
        self,
        home_id: str | None,  # noqa: ARG002
    ) -> dict[int, dict[str, Any]] | None:
        """List MSmart Cloud Devices."""
        data = self._make_general_data()
        if response := await self._api_request(
            endpoint="/v1/appliance/user/list/get",
            data=data,
        ):
            appliances = {}
            for appliance in response["list"]:
                try:
                    model_number = int(appliance.get("modelNumber", 0))
                except ValueError:
                    model_number = 0
                device_info = {
                    "name": appliance.get("name"),
                    "type": int(appliance.get("type"), 16),
                    "sn": self._security.aes_decrypt(appliance.get("sn") or ""),
                    "sn8": "",
                    "model_number": model_number,
                    "manufacturer_code": appliance.get("enterpriseCode", "0000"),
                    "model": "",
                    "online": appliance.get("onlineStatus") == "1",
                }
                serial_num = device_info.get("sn")
                device_info["sn8"] = (
                    serial_num[9:17]
                    if (serial_num and len(serial_num) > SN8_MIN_SERIAL_LENGTH)
                    else ""
                )
                device_info["model"] = device_info.get("sn8")
                appliances[int(appliance["id"])] = device_info
            return appliances
        return None

    async def download_lua(
        self,
        path: str,
        device_type: int,
        sn: str,
        model_number: str | None = None,
        manufacturer_code: str = "0000",
    ) -> str | None:
        """Download lua integration."""
        data = self._make_general_data()
        data.update(
            {
                "applianceMFCode": manufacturer_code,
                "applianceType": hex(device_type),
                "applianceSn": self._security.aes_encrypt_with_fixed_key(
                    sn.encode("ascii"),
                ).hex(),
                "version": "0",
                "encryptedType ": "2",
            },
        )
        if model_number is not None:
            data["modelNumber"] = model_number
        if response := await self._api_request(
            endpoint="/v2/luaEncryption/luaGet",
            data=data,
        ):
            return await self._fetch_lua_file(
                path,
                response,
                self._security.aes_decrypt_with_fixed_key,
            )
        return None

    async def download_plugin(
        self,
        path: str,
        device_type: int,
        sn: str,
    ) -> str | None:
        """Download lua integration."""
        data = self._make_general_data()
        data.update(
            {
                "clientVersion": "0",
                "applianceList": [
                    {
                        "appModel": sn[9:17],
                        "appType": hex(device_type),
                        "modelNumber": "0",
                    },
                ],
            },
        )
        if response := await self._api_request(
            endpoint="/v1/plugin/update/overseas/get",
            data=data,
        ):
            _LOGGER.debug("response: %s, type: %s", response, type(response))
            return await self._fetch_plugin_file(path, response["result"][0]["url"])
        return None


class MideaAirCloud(MideaCloud):
    """Midea Air Cloud."""

    def __init__(
        self,
        cloud_name: str,
        session: ClientSession,
        account: str,
        password: str,
    ) -> None:
        """Initialize Midea Air Cloud."""
        cloud_data = cast("dict[str, Any]", SUPPORTED_CLOUDS[cloud_name])
        super().__init__(
            session=session,
            security=MideaAirSecurity(login_key=cloud_data["app_key"]),
            app_id=cloud_data["app_id"],
            app_key=cloud_data["app_key"],
            account=account,
            password=password,
            api_url=cloud_data["api_url"],
        )
        self._session_id: str | None = None

    def _make_general_data(self) -> dict[str, Any]:
        data = {
            "src": self._app_id,
            "format": "2",
            "stamp": datetime.now(tz=UTC).strftime("%Y%m%d%H%M%S"),
            "deviceId": self._device_id,
            "reqId": token_hex(16),
            "clientType": "1",
            "appId": self._app_id,
        }
        if self._session_id is not None:
            data.update({"sessionId": self._session_id})
        return data

    async def _api_request(
        self,
        endpoint: str,
        data: dict[str, Any],
        header: dict[str, Any] | None = None,
        raise_for_error: bool = False,
    ) -> dict[str, Any] | None:
        header = header or {}
        url = self._api_url + endpoint

        sign = self._security.sign(url, data, "")
        data.update({"sign": sign})
        if self._uid is not None:
            header.update({"uid": self._uid})
        if self._access_token is not None:
            header.update({"accessToken": self._access_token})
        response: dict = {"errorCode": -1}
        for attempt in range(_RETRY_ATTEMPTS):
            try:
                async with self._api_lock:
                    r = await self._session.request(
                        "POST",
                        url,
                        headers=header,
                        data=data,
                        timeout=ClientTimeout(10),
                    )
                    raw = await r.read()
                    _LOGGER.debug(
                        "Midea cloud API url: %s, data: %s, response: %s",
                        url,
                        data,
                        raw,
                    )
                    response = json.loads(raw)
            except (TimeoutError, ClientConnectionError, json.JSONDecodeError) as e:
                _LOGGER.warning(
                    "Midea cloud API error, url: %s, error: %s",
                    url,
                    repr(e),
                )
                continue
            if not await self._retry_if_transient(
                url,
                int(response["errorCode"]),
                attempt,
            ):
                break
        error_code = int(response["errorCode"])
        if error_code == 0:
            if "result" in response:
                return cast("dict[str, Any]", response["result"])
            # The legacy lua endpoint returns its payload under "data" instead
            # of "result"; fall back to it so download_lua can read the url.
            if "data" in response:
                return cast("dict[str, Any]", response["data"])
        else:
            self._handle_error_code(
                url,
                error_code,
                str(response.get("msg") or ""),
                raise_for_error,
            )
        return None

    async def login(self) -> bool:
        """Authenticate to Midea Air Cloud."""
        if login_id := await self._get_login_id():
            self._login_id = login_id
            data = self._make_general_data()
            data.update(
                {
                    "loginAccount": self._account,
                    "password": self._security.encrypt_password(
                        self._login_id,
                        self._password,
                    ),
                },
            )
            if response := await self._api_request(
                endpoint="/v1/user/login",
                data=data,
                raise_for_error=True,
            ):
                self._access_token = response["accessToken"]
                self._uid = response["userId"]
                self._session_id = response["sessionId"]
                return True
        _LOGGER.warning("Midea Air Cloud login failed for device %s", self._device_id)
        return False

    async def list_appliances(
        self,
        home_id: str | None,  # noqa: ARG002
    ) -> dict[int, dict[str, Any]] | None:
        """List Midea Air devices."""
        data = self._make_general_data()
        if response := await self._api_request(
            endpoint="/v1/appliance/user/list/get",
            data=data,
        ):
            appliances = {}
            for appliance in response["list"]:
                try:
                    model_number = int(appliance.get("modelNumber", 0))
                except ValueError:
                    model_number = 0
                device_info = {
                    "name": appliance.get("name"),
                    "type": int(appliance.get("type"), 16),
                    "sn": appliance.get("sn"),
                    "sn8": "",
                    "model_number": model_number,
                    "manufacturer_code": appliance.get("enterpriseCode", "0000"),
                    "model": "",
                    "online": appliance.get("onlineStatus") == "1",
                }
                serial_num = device_info.get("sn")
                device_info["sn8"] = (
                    serial_num[9:17]
                    if (serial_num and len(serial_num) > SN8_MIN_SERIAL_LENGTH)
                    else ""
                )
                device_info["model"] = device_info.get("sn8")
                appliances[int(appliance["id"])] = device_info
            return appliances
        return None

    async def download_lua(
        self,
        path: str,
        device_type: int,
        sn: str,
        model_number: str | None = None,  # noqa: ARG002
        manufacturer_code: str = "0000",
    ) -> str | None:
        """Download lua integration.

        The legacy ``mapp.appsmb.com`` backend returns the lua payload under
        ``data`` (handled by :meth:`_api_request`) and serves a hex-encoded
        AES-128-ECB file keyed by the app key (see
        :meth:`MideaAirSecurity.decrypt_appliance_lua`).
        """
        data = self._make_general_data()
        data.update(
            {
                "applianceSn": sn,
                "applianceType": hex(device_type),
                "applianceMFCode": manufacturer_code,
                "version": "0",
            },
        )
        if response := await self._api_request(
            endpoint="/v1/appliance/protocol/lua/luaGet",
            data=data,
        ):
            return await self._fetch_lua_file(
                path,
                response,
                cast("MideaAirSecurity", self._security).decrypt_appliance_lua,
            )
        return None


class ToshibaIOLife(MideaAirCloud):
    """Toshiba IOLife cloud."""

    def __init__(
        self,
        cloud_name: str,
        session: ClientSession,
        account: str,
        password: str,
    ) -> None:
        """Initialize Toshiba IOLife cloud."""
        super().__init__(
            cloud_name=cloud_name,
            session=session,
            account=account,
            password=password,
        )
        cloud_data = cast("dict[str, Any]", SUPPORTED_CLOUDS[cloud_name])
        self._app_version: str = cloud_data["app_version"]
        self._manufacturer_code: str = cloud_data["manufacturer_code"]

    def _decrypt_sn(self, encrypted_sn: str) -> str:
        """Decrypt SN blob from home/page/list/info.

        The server encrypts the SN string with AES-128-ECB using a session
        data_key derived from the accessToken:
          aes_key  = MD5(app_key)[:16]
          data_key = AES_ECB_decrypt(bytes.fromhex(accessToken), aes_key)
          sn       = AES_ECB_decrypt(bytes.fromhex(encrypted_sn), data_key)
        """
        if not self._access_token or not encrypted_sn:
            return ""
        try:
            aes_key = (
                md5(
                    self._app_key.encode(),
                    usedforsecurity=False,
                )
                .hexdigest()[:16]
                .encode()
            )
            token_bytes = bytes.fromhex(self._access_token)
            data_key = bytes(
                unpad(AES.new(aes_key, AES.MODE_ECB).decrypt(token_bytes), 16),
            )
            sn_bytes = bytes.fromhex(encrypted_sn)
            plain = unpad(AES.new(data_key[:16], AES.MODE_ECB).decrypt(sn_bytes), 16)
            return plain.decode()
        except ValueError:
            _LOGGER.debug("Failed to decrypt appliance SN")
            return ""

    async def list_appliances(
        self,
        home_id: str | None = None,  # noqa: ARG002
    ) -> dict[int, dict[str, Any]]:
        """Get Toshiba IOLife devices."""
        data = self._make_general_data()
        data["appVersion"] = self._app_version
        # home/page/list/info returns result as a bare list, not {list: [...]}
        page_list: Any = await self._api_request(
            endpoint="/v1/appliance/user/home/page/list/info",
            data=data,
        )
        if not isinstance(page_list, list):
            return {}

        appliances: dict[int, dict[str, Any]] = {}
        for appliance in page_list:
            if not isinstance(appliance, Mapping):
                continue
            # Skip virtual/batch devices
            if (
                appliance.get("type") == "0x_BATCH_AC"
                or appliance.get("id") == "virtual_ag_0xAC"
            ):
                continue
            try:
                device_id = int(appliance["id"])
                device_type = int(appliance["type"], 16)
            except (ValueError, KeyError, TypeError):
                _LOGGER.debug("Skipping malformed appliance entry: %s", appliance)
                continue
            try:
                model_number = int(appliance.get("modelNumber", 0))
            except (ValueError, TypeError):
                model_number = 0
            sn = self._decrypt_sn(appliance.get("sn", ""))
            sn8 = sn[9:17] if len(sn) > SN8_MIN_SERIAL_LENGTH else ""
            appliances[device_id] = {
                "name": appliance.get("name"),
                "type": device_type,
                "sn": sn,
                "sn8": sn8,
                "model_number": model_number,
                "manufacturer_code": appliance.get(
                    "enterpriseCode",
                    self._manufacturer_code,
                ),
                "model": sn8,
                "online": appliance.get("onlineStatus") == "1",
            }

        return appliances


def get_midea_cloud(
    cloud_name: str,
    session: ClientSession,
    account: str,
    password: str,
) -> MideaCloud:
    """Get Midea Cloud implementation."""
    if cloud_name not in SUPPORTED_CLOUDS:
        raise ElementMissing(
            f"Unsupported Cloud specified: {cloud_name}",
        )

    cloud_data = cast("dict[str, Any]", SUPPORTED_CLOUDS[cloud_name])
    return cast(
        "MideaCloud",
        globals()[cloud_data["class_name"]](
            cloud_name=cloud_name,
            session=session,
            account=account,
            password=password,
        ),
    )
