"""Test cloud."""

import json
from hashlib import md5
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import ClassVar
from unittest import IsolatedAsyncioTestCase
from unittest.mock import AsyncMock, Mock, patch

import pytest
from aiohttp import ClientConnectionError, ClientSession, ClientTimeout, web

from midealan.cloud import (
    DEFAULT_KEYS,
    SUPPORTED_CLOUDS,
    MeijuCloud,
    MideaAirCloud,
    MideaCloud,
    SmartHomeCloud,
    _mask_token,
    get_default_cloud,
    get_midea_cloud,
    get_preset_account_cloud,
)
from midealan.exceptions import CloudAuthError, CloudError, ElementMissing

# ``CloudSecurity.get_udp_id(100, method)``. Hard-coded on purpose: deriving them
# with the same helper the implementation calls would not catch a request that
# sends the wrong method's UDP ID.
UDP_IDS = {
    1: "dec4da86e0aeefadde14a4e553680b9b",
    2: "b2dd199071d527a33c8239833a5bf5fb",
}


def _token_requests(session: Mock) -> list[tuple[str, dict]]:
    """Return (url, payload) for every getToken request the client actually sent.

    The response side_effect only controls what comes back; these assertions
    pin down what goes out, so a regression to the v1 endpoint or to a
    string-valued ``applianceCodes`` cannot pass silently.
    """
    out = []
    for call in session.request.await_args_list:
        url = call.args[1] if len(call.args) > 1 else call.kwargs.get("url", "")
        if "getToken" not in url:
            continue
        out.append((url, json.loads(call.kwargs["data"])))
    return out


class CloudTest(IsolatedAsyncioTestCase):
    """Cloud test case."""

    responses: ClassVar[dict[str, bytes]] = {}

    def setUp(self) -> None:
        """Set tests up."""
        file_path = Path(__file__)
        for file in Path.iterdir(Path(file_path.parent, "responses")):
            file_path = Path(file)
            with file_path.open(
                encoding="utf-8",
            ) as f:
                self.responses[file_path.name] = bytes(f.read(), encoding="utf-8")

    def test_lua_download_metadata(self) -> None:
        """Test lua download metadata validation and filename sanitization."""
        metadata = MideaCloud._get_lua_download_metadata(
            "downloads",
            {"url": "url", "fileName": "../lua.lua"},
            "serial",
        )
        assert metadata == ("url", Path("downloads/lua.lua"))

        with self.assertLogs("midealan.cloud", level="WARNING") as logs:
            assert (
                MideaCloud._get_lua_download_metadata(
                    "downloads",
                    {"fileName": "lua.lua"},
                    "serial",
                )
                is None
            )
            assert (
                MideaCloud._get_lua_download_metadata(
                    "downloads",
                    {"url": "", "fileName": "lua.lua"},
                    "serial",
                )
                is None
            )
            assert (
                MideaCloud._get_lua_download_metadata(
                    "downloads",
                    {"url": "url"},
                    "serial",
                )
                is None
            )
            assert (
                MideaCloud._get_lua_download_metadata(
                    "downloads",
                    {"url": "url", "fileName": None},
                    "serial",
                )
                is None
            )
            assert (
                MideaCloud._get_lua_download_metadata(
                    "downloads",
                    {"url": "url", "fileName": ".."},
                    "serial",
                )
                is None
            )
        assert len(logs.output) == 5

    def test_get_midea_cloud(self) -> None:
        """Test get midea cloud."""
        session = AsyncMock()
        assert isinstance(get_midea_cloud("美的美居", session, "", ""), MeijuCloud)
        assert isinstance(
            get_midea_cloud("SmartHome", session, "", ""),
            SmartHomeCloud,
        )
        assert isinstance(get_midea_cloud("Midea Air", session, "", ""), MideaAirCloud)
        assert isinstance(
            get_midea_cloud("NetHome Plus", session, "", ""),
            MideaAirCloud,
        )
        assert isinstance(
            get_midea_cloud("Ariston Clima", session, "", ""),
            MideaAirCloud,
        )
        with pytest.raises(ElementMissing):
            get_midea_cloud("Invalid", session, "", "")

    async def test_get_default_cloud(self) -> None:
        """Test get default cloud name."""
        default_cloud = get_default_cloud()
        assert default_cloud == "NetHome Plus"

    async def test_get_default_cloud_missing(self) -> None:
        """Test get default cloud name without any default cloud."""
        with (
            patch.dict(
                "midealan.cloud.SUPPORTED_CLOUDS",
                {"NoDefault": {}},
                clear=True,
            ),
            pytest.raises(ElementMissing),
        ):
            get_default_cloud()

    def test_mask_token(self) -> None:
        """Test _mask_token."""
        assert _mask_token("") == ""
        assert _mask_token("1234567890") == "12345*****"

    async def test_get_cloud_servers(self) -> None:
        """Test get cloud servers."""
        servers = await MideaCloud.get_cloud_servers()
        assert len(servers.items()) == 5

    async def test_midea_cloud_api_request_timeout(self) -> None:
        """Test _api_request retries and returns None on timeout."""
        session = Mock()
        session.request = AsyncMock(side_effect=TimeoutError("timeout"))
        security = Mock()
        security.sign.return_value = "signature"
        cloud = MideaCloud(
            session=session,
            security=security,
            app_id="appid",
            app_key="appkey",
            account="account",
            password="password",
            api_url="http://api.url/",
        )
        with self.assertLogs("midealan.cloud", level="WARNING") as logs:
            assert await cloud._api_request(endpoint="/endpoint", data={}) is None
        assert len(logs.output) == 3

    async def test_get_preset_account_cloud(self) -> None:
        """Test get preset cloud account."""
        credentials = get_preset_account_cloud()
        assert credentials["password"] == "a0d6e30c94b15"
        assert credentials["cloud_name"] == "NetHome Plus"

    async def test_midea_cloud_unimplemented(self) -> None:
        """Test unimplemented MideaCloud methods."""
        session = Mock()
        security = Mock()
        cloud = MideaCloud(
            session=session,
            security=security,
            app_id="appid",
            app_key="appkey",
            account="account",
            password="password",
            api_url="http://api.url/",
        )
        assert cloud._make_general_data() == {}
        with pytest.raises(NotImplementedError):
            await cloud.login()
        with pytest.raises(NotImplementedError):
            await cloud.list_appliances(None)
        with pytest.raises(NotImplementedError):
            await cloud.download_lua("path", 10, "0000AC000ABCD1234000")
        with pytest.raises(NotImplementedError):
            await cloud.download_plugin("path", 10, "0000AC000ABCD1234000")

    async def test_meijucloud_login_success(self) -> None:
        """Test MeijuCloud login."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

    async def test_meijucloud_login_invalid_user(self) -> None:
        """Test MeijuCloud login invalid user."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["cloud_invalid_response.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert not await cloud.login()

    async def test_meijucloud_login_api_request_none(self) -> None:
        """Test MeijuCloud login failure when the login response is missing."""
        session = Mock()
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(cloud, "_api_request", AsyncMock(return_value=None)),
            self.assertLogs("midealan.cloud", level="WARNING") as logs,
        ):
            assert not await cloud.login()
        assert "Meiju Cloud login failed" in logs.output[0]

    async def test_meijucloud_login_response_none(self) -> None:
        """Test MeijuCloud login failure when the final login API returns none."""
        session = Mock()
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(cloud, "_get_login_id", AsyncMock(return_value="loginid")),
            patch.object(cloud, "_api_request", AsyncMock(return_value=None)),
            self.assertLogs("midealan.cloud", level="WARNING") as logs,
        ):
            assert not await cloud.login()
        assert "Meiju Cloud login failed" in logs.output[0]

    async def test_meijucloud_get_keys(self) -> None:
        """Test MeijuCloud get_cloud_keys."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                # get_cloud_keys() lists homes first, then queries the v2
                # endpoint per method until one home returns keys.
                self.responses["meijucloud_list_home.json"],
                self.responses["meijucloud_get_keys1.json"],
                self.responses["meijucloud_get_keys2.json"],
                self.responses["meijucloud_list_home.json"],
                self.responses["meijucloud_get_keys1.json"],
                self.responses["cloud_invalid_response.json"],
                self.responses["meijucloud_list_home.json"],
                self.responses["cloud_invalid_response.json"],
                self.responses["meijucloud_get_keys2.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None

        # test method1 + method2
        keys3: dict = await cloud.get_cloud_keys(100)
        # test response token/key
        assert keys3[1]["token"] == "method1_return_token1"
        assert keys3[1]["key"] == "method1_return_key1"
        assert keys3[2]["token"] == "method2_return_token2"
        assert keys3[2]["key"] == "method2_return_key2"
        # simple test default key with length
        assert len(keys3) == 2

        # test method1
        keys1: dict = await cloud.get_cloud_keys(100)
        # test response token/key
        assert keys1[1]["token"] == "method1_return_token1"
        assert keys1[1]["key"] == "method1_return_key1"
        # simple test default key with length
        assert len(keys1) == 1

        # test method2
        keys2: dict = await cloud.get_cloud_keys(100)
        # test response token/key
        assert keys2[2]["token"] == "method2_return_token2"
        assert keys2[2]["key"] == "method2_return_key2"
        # simple test default key with length
        assert len(keys2) == 1

        # test only default key
        keys = await cloud.get_default_keys()
        assert len(keys) == 1
        assert keys == DEFAULT_KEYS

        # Pin the outbound contract: every lookup must hit v2 and send
        # homegroupId + udpid + a list-valued applianceCodes.
        requests = _token_requests(session)
        assert requests
        for url, payload in requests:
            assert url.endswith("/v2/iot/secure/getToken")
            assert payload["applianceCodes"] == ["100"]
        # Each of the three lookups stops at the first home that returns a key,
        # so the exact sequence is home "1" x method 1, method 2 -- three times.
        assert [(p["homegroupId"], p["udpid"]) for _url, p in requests] == [
            ("1", UDP_IDS[1]),
            ("1", UDP_IDS[2]),
        ] * 3

    async def test_meijucloud_get_keys_v2_fallback_to_v1(self) -> None:
        """Test MeijuCloud falls back to the v1 endpoint when v2 returns nothing."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["meijucloud_list_home.json"],
                # v2, home 1: both methods come back empty
                self.responses["cloud_invalid_response.json"],
                self.responses["cloud_invalid_response.json"],
                # v2, home 2: same
                self.responses["cloud_invalid_response.json"],
                self.responses["cloud_invalid_response.json"],
                # v1 fallback
                self.responses["meijucloud_get_keys1.json"],
                self.responses["meijucloud_get_keys2.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None

        keys: dict = await cloud.get_cloud_keys(100)
        assert keys[1]["token"] == "method1_return_token1"
        assert keys[1]["key"] == "method1_return_key1"
        assert keys[2]["token"] == "method2_return_token2"
        assert keys[2]["key"] == "method2_return_key2"
        assert len(keys) == 2

        # v2 is tried for both homes x both methods, then v1 once per method.
        requests = _token_requests(session)
        v2 = [r for r in requests if r[0].endswith("/v2/iot/secure/getToken")]
        v1 = [r for r in requests if r[0].endswith("/v1/iot/secure/getToken")]
        for _url, payload in v2:
            assert payload["applianceCodes"] == ["100"]
        for _url, payload in v1:
            # the inherited v1 implementation sends the plain string form
            assert payload["applianceCodes"] == "100"
        # Both homes are tried, each with both methods, in order.
        assert [(p["homegroupId"], p["udpid"]) for _url, p in v2] == [
            ("1", UDP_IDS[1]),
            ("1", UDP_IDS[2]),
            ("2", UDP_IDS[1]),
            ("2", UDP_IDS[2]),
        ]
        # The full ordered endpoint sequence: four v2 calls then two v1 calls,
        # proving no v1 request is interleaved into the v2 phase.
        assert [url.rsplit("=", 1)[-1] for url, _payload in requests] == [
            *(["/v2/iot/secure/getToken"] * 4),
            *(["/v1/iot/secure/getToken"] * 2),
        ]
        # v1 keeps the method-specific UDP ID but carries no home.
        assert [p["udpid"] for _url, p in v1] == [UDP_IDS[1], UDP_IDS[2]]
        assert all("homegroupId" not in p for _url, p in v1)

    async def test_meijucloud_get_keys_no_home(self) -> None:
        """Test MeijuCloud get_cloud_keys when the home list is unavailable."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                # list_home fails, so v2 is skipped entirely
                self.responses["cloud_invalid_response.json"],
                # v1 fallback
                self.responses["meijucloud_get_keys1.json"],
                self.responses["cloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None

        keys: dict = await cloud.get_cloud_keys(100)
        assert keys[1]["token"] == "method1_return_token1"
        assert len(keys) == 1

        # No home list means v2 is skipped entirely; only v1 is called.
        requests = _token_requests(session)
        assert requests
        for url, _payload in requests:
            assert url.endswith("/v1/iot/secure/getToken")

    async def test_meijucloud_get_keys_ignores_nonmatching_token(self) -> None:
        """Test get_cloud_keys skips non-matching token entries.

        Non-matching tokens are ignored on both the v2 path (all homes and
        methods) and the inherited v1 fallback, so the overall result is empty.
        """
        nonmatching = (
            b'{"code": 0, "data": {"tokenlist": [{"udpId": "wrong", '
            b'"token": "TOK", "key": "KEY"}]}}'
        )
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["meijucloud_list_home.json"],
                # v2: two homes x two methods, every token has a wrong udpId
                nonmatching,
                nonmatching,
                nonmatching,
                nonmatching,
                # v1 fallback: both methods also non-matching
                nonmatching,
                nonmatching,
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.get_cloud_keys(100) == {}

    async def test_meijucloud_list_home(self) -> None:
        """Test MeijuCloud list_home."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["meijucloud_list_home.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        homes = await cloud.list_home()
        assert homes is not None
        assert len(homes.keys()) == 2
        assert homes[1] == "Home 1"
        assert homes[2] == "Home 2"

        response.read = AsyncMock(
            return_value=self.responses["cloud_invalid_response.json"],
        )
        assert await cloud.list_home() is None

    async def test_meijucloud_list_appliances(self) -> None:
        """Test MeijuCloud list_appliances."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_list_appliances.json"],
                self.responses["cloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()
        appliances = await cloud.list_appliances("1")
        assert appliances is not None
        assert len(appliances.keys()) == 2
        appliance = appliances.get(1)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == "mySecretKey"
        assert appliance.get("sn8") == "9d52c159"
        assert appliance.get("model_number") == 10
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == "Product Model"
        assert appliance.get("online")

        appliance = appliances.get(2)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name 2"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == ""
        assert appliance.get("sn8") == "00000000"
        assert appliance.get("model_number") == 0
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == "00000000"
        assert not appliance.get("online")

        appliances = await cloud.list_appliances("1")
        assert appliances is None

    async def test_meijucloud_get_device_info(self) -> None:
        """Test MeijuCloud get_device_info."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_get_device_info.json"],
                self.responses["meijucloud_get_device_info_alt.json"],
                self.responses["cloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        device = await cloud.get_device_info(1)
        assert device is not None
        assert device.get("name") == "Appliance Name"
        assert device.get("type") == 0xAC
        assert device.get("sn") == "mySecretKey"
        assert device.get("sn8") == "9d52c159"
        assert device.get("model_number") == 10
        assert device.get("manufacturer_code") == "1234"
        assert device.get("model") == "Product Model"
        assert device.get("online")

        device = await cloud.get_device_info(2)
        assert device is not None
        assert device.get("name") == "Appliance Name 2"
        assert device.get("type") == 0xAC
        assert device.get("sn") == ""
        assert device.get("sn8") == "00000000"
        assert device.get("model_number") == 0
        assert device.get("manufacturer_code") == "1234"
        assert device.get("model") == "00000000"
        assert not device.get("online")
        assert device.get("des") is None
        assert device.get("active_status") == 1
        assert device.get("active_time") == "2024-06-12 10:45:45"
        assert device.get("master_id") is None
        assert device.get("wifi_version") == "059009012205"
        assert device.get("enterprise") == "0000"
        assert device.get("is_other_equipment") is None
        assert device.get("attrs") is None
        assert device.get("room_name") is None
        assert device.get("bt_mac") == "54B8740FA801"
        assert device.get("bt_token") is None
        assert device.get("hotspot_name") is None
        assert device.get("is_bluetooth") == 0
        assert device.get("bind_type") is None
        assert device.get("ability") is None
        assert device.get("name_changed") is None
        assert not device.get("support_wot")
        assert device.get("template_of_tsl") is None
        assert device.get("shadow_level") is None
        assert device.get("smart_product_id") == 10004256
        assert device.get("brand") is None

        device = await cloud.get_device_info(99)
        assert device is None

    async def test_meijucloud_download_lua(self) -> None:
        """Test MeijuCloud download_lua."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
                self.responses["meijucloud_download_lua.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="9d52c159dcdd32bac5109cf54080fca7")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        with TemporaryDirectory() as tmpdir:
            file = await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010")
            assert file is not None
            file_path = Path(file)
            assert Path.exists(file_path)
            Path.unlink(file_path)
            session.get.assert_awaited_once_with(
                "returnedURL",
                timeout=ClientTimeout(10),
            )

            res.status = 404
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )
            with patch.object(
                cloud,
                "_api_request",
                AsyncMock(return_value={"url": "returnedURL"}),
            ):
                assert await cloud.download_lua(tmpdir, 10, "00000000") is None
            with patch.object(cloud, "_api_request", AsyncMock(return_value=None)):
                assert await cloud.download_lua(tmpdir, 10, "00000000") is None

    async def test_meijucloud_download_lua_empty_payload(self) -> None:
        """Test MeijuCloud download_lua with an empty payload."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        with TemporaryDirectory() as tmpdir:
            result = await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010")
            assert result is None

    async def test_meijucloud_download_plugin(self) -> None:
        """Test MeijuCloud download_plugin."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=(
                b'{"code": 0, "data": {"list": [{"url": "http://host/plugin.zip"}]}}'
            ),
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.read = AsyncMock(return_value=b"plugin content")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None

        with TemporaryDirectory() as tmpdir:
            file = await cloud.download_plugin(tmpdir, 10, "0000AC000ABCD1234000")
            assert file is not None
            file_path = Path(file)
            assert file_path.name == "plugin.zip"
            assert Path.exists(file_path)
            Path.unlink(file_path)

            res.status = 404
            assert (
                await cloud.download_plugin(tmpdir, 10, "0000AC000ABCD1234000") is None
            )

    async def test_meijucloud_download_plugin_empty_payload(self) -> None:
        """Test MeijuCloud download_plugin with an empty payload."""
        session = Mock()
        res = Mock()
        res.status = 200
        res.read = AsyncMock(return_value=b"")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(
                cloud,
                "_api_request",
                AsyncMock(return_value={"list": [{"url": "http://host/plugin.zip"}]}),
            ),
            TemporaryDirectory() as tmpdir,
        ):
            assert (
                await cloud.download_plugin(
                    tmpdir,
                    10,
                    "0000AC000ABCD1234000",
                )
                is None
            )

    async def test_meijucloud_download_plugin_no_response(self) -> None:
        """Test MeijuCloud download_plugin when the API returns nothing."""
        session = Mock()
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(cloud, "_api_request", AsyncMock(return_value=None)),
            TemporaryDirectory() as tmpdir,
        ):
            assert (
                await cloud.download_plugin(
                    tmpdir,
                    10,
                    "0000AC000ABCD1234000",
                )
                is None
            )

    async def test_msmartcloud_login_success(self) -> None:
        """Test MSmartCloud login."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

    async def test_msmartcloud_login_invalid_user(self) -> None:
        """Test MSmartCloud login invalid user."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["cloud_invalid_response.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert not await cloud.login()

    async def test_msmartcloud_login_api_request_none(self) -> None:
        """Test MSmartCloud login failure when login response is missing."""
        session = Mock()
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(cloud, "_get_login_id", AsyncMock(return_value="loginid")),
            patch.object(cloud, "_api_request", AsyncMock(return_value=None)),
            self.assertLogs("midealan.cloud", level="WARNING") as logs,
        ):
            assert not await cloud.login()
        assert "SmartHome Cloud login failed" in logs.output[0]

    async def test_msmartcloud_list_home(self) -> None:
        """Test MSmartCloud list_home."""
        session = Mock()
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        homes = await cloud.list_home()
        assert homes is not None
        assert len(homes.keys()) == 1

    async def test_msmartcloud_list_appliances(self) -> None:
        """Test MSmartCloud list_appliances."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["msmartcloud_list_appliances.json"],
                self.responses["cloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()
        appliances = await cloud.list_appliances(None)
        assert appliances is not None
        assert len(appliances.keys()) == 2
        appliance = appliances.get(1)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == "1234567890abcdef1234567890abcdef"
        assert appliance.get("sn8") == "0abcdef1"
        assert appliance.get("model_number") == 10
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == "0abcdef1"
        assert appliance.get("online")

        appliance = appliances.get(2)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name 2"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == ""
        assert appliance.get("sn8") == ""
        assert appliance.get("model_number") == 0
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == ""
        assert not appliance.get("online")

        appliances = await cloud.list_appliances(None)
        assert appliances is None

    async def test_msmartcloud_get_device_info(self) -> None:
        """Test MSmartCloud get_device_info."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["msmartcloud_list_appliances.json"],
                ClientConnectionError(),
                self.responses["msmartcloud_list_appliances.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        device = await cloud.get_device_info(1)
        assert device is not None
        assert device.get("name") == "Appliance Name"
        assert device.get("type") == 0xAC
        assert device.get("sn") == "1234567890abcdef1234567890abcdef"
        assert device.get("sn8") == "0abcdef1"
        assert device.get("model_number") == 10
        assert device.get("manufacturer_code") == "1234"
        assert device.get("model") == "0abcdef1"
        assert device.get("online")

        device = await cloud.get_device_info(99)
        assert device is None

    async def test_msmartcloud_download_lua(self) -> None:
        """Test MSmartCloud download_lua."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="4ABE0FE395F3AD3B6BC4D223F1ADFA7C")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        with TemporaryDirectory() as tmpdir:
            file = await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010")
            assert file is not None
            file_path = Path(file)
            assert Path.exists(file_path)
            Path.unlink(file_path)
            session.get.assert_awaited_once_with(
                "returnedURL",
                timeout=ClientTimeout(10),
            )
            with patch.object(
                cloud,
                "_api_request",
                AsyncMock(return_value={"url": "returnedURL"}),
            ):
                assert await cloud.download_lua(tmpdir, 10, "00000000") is None
            with patch.object(cloud, "_api_request", AsyncMock(return_value=None)):
                assert await cloud.download_lua(tmpdir, 10, "00000000") is None

    async def test_msmartcloud_download_lua_empty_payload(self) -> None:
        """Test MSmartCloud download_lua with an empty payload."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        with TemporaryDirectory() as tmpdir:
            result = await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010")
            assert result is None

    async def test_msmartcloud_download_lua_non_ok_response(self) -> None:
        """Test MSmartCloud download_lua with a non-OK download response."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 404
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        with TemporaryDirectory() as tmpdir:
            result = await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010")
            assert result is None

    async def test_msmartcloud_download_plugin(self) -> None:
        """Test MSmartCloud download_plugin."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=(
                b'{"code": 0, "data": {"result": [{"url": "http://host/plugin.zip"}]}}'
            ),
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.read = AsyncMock(return_value=b"plugin content")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None

        with TemporaryDirectory() as tmpdir:
            file = await cloud.download_plugin(tmpdir, 10, "0000AC000ABCD1234000")
            assert file is not None
            file_path = Path(file)
            assert file_path.name == "plugin.zip"
            assert Path.exists(file_path)
            Path.unlink(file_path)

            res.status = 404
            assert (
                await cloud.download_plugin(tmpdir, 10, "0000AC000ABCD1234000") is None
            )

    async def test_msmartcloud_download_plugin_empty_payload(self) -> None:
        """Test MSmartCloud download_plugin with an empty payload."""
        session = Mock()
        res = Mock()
        res.status = 200
        res.read = AsyncMock(return_value=b"")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(
                cloud,
                "_api_request",
                AsyncMock(return_value={"result": [{"url": "http://host/plugin.zip"}]}),
            ),
            TemporaryDirectory() as tmpdir,
        ):
            assert (
                await cloud.download_plugin(
                    tmpdir,
                    10,
                    "0000AC000ABCD1234000",
                )
                is None
            )

    async def test_msmartcloud_download_plugin_non_ok_response(self) -> None:
        """Test MSmartCloud download_plugin with a non-OK download response."""
        session = Mock()
        res = Mock()
        res.status = 404
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(
                cloud,
                "_api_request",
                AsyncMock(return_value={"result": [{"url": "http://host/plugin.zip"}]}),
            ),
            TemporaryDirectory() as tmpdir,
        ):
            assert (
                await cloud.download_plugin(
                    tmpdir,
                    10,
                    "0000AC000ABCD1234000",
                )
                is None
            )

    async def test_msmartcloud_download_plugin_no_response(self) -> None:
        """Test MSmartCloud download_plugin when the API returns nothing."""
        session = Mock()
        cloud = get_midea_cloud(
            "SmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(cloud, "_api_request", AsyncMock(return_value=None)),
            TemporaryDirectory() as tmpdir,
        ):
            result = await cloud.download_plugin(
                tmpdir,
                10,
                "0000AC000ABCD1234000",
            )
            assert result is None

    async def test_mideaaircloud_login_success(self) -> None:
        """Test MideaAirCloud login."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["mideaaircloud_login_id.json"],
                self.responses["mideaaircloud_login.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

    async def test_mideaaircloud_login_api_request_none(self) -> None:
        """Test MideaAirCloud login failure when login response is missing."""
        session = Mock()
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            patch.object(cloud, "_get_login_id", AsyncMock(return_value="loginid")),
            patch.object(cloud, "_api_request", AsyncMock(return_value=None)),
            self.assertLogs("midealan.cloud", level="WARNING") as logs,
        ):
            assert not await cloud.login()
        assert "Midea Air Cloud login failed" in logs.output[0]

    async def test_mideaaircloud_login_invalid_user(self) -> None:
        """Test MideaAirCloud login invalid user."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["mideaaircloud_invalid_response.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert not await cloud.login()

    async def test_mideaaircloud_api_request_timeout(self) -> None:
        """Test MideaAirCloud _api_request retries on timeout."""
        session = Mock()
        session.request = AsyncMock(side_effect=TimeoutError("timeout"))
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with self.assertLogs("midealan.cloud", level="WARNING") as logs:
            assert await cloud._api_request(endpoint="/endpoint", data={}) is None
        assert len(logs.output) == 3

    async def test_mideaaircloud_api_request_success_without_payload(self) -> None:
        """Test MideaAirCloud _api_request with no result or data payload."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(return_value=b'{"errorCode": 0}')
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud._api_request(endpoint="/endpoint", data={}) is None

    async def test_mideaaircloud_download_lua(self) -> None:
        """Test MideaAirCloud download_lua against the legacy backend."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["mideaaircloud_login_id.json"],
                self.responses["mideaaircloud_login.json"],
                self.responses["mideaaircloud_download_lua.json"],
                self.responses["mideaaircloud_download_lua.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        app_key = SUPPORTED_CLOUDS["Midea Air"]["app_key"]
        lua_key = (
            md5(app_key.encode("ascii"), usedforsecurity=False)
            .hexdigest()[:16]
            .encode("ascii")
        )
        res.text = AsyncMock(
            return_value=cloud._security.aes_encrypt(
                b"function test() return 1 end",
                lua_key,
            ).hex(),
        )
        assert await cloud.login()

        with TemporaryDirectory() as tmpdir:
            file = await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010")
            assert file is not None
            file_path = Path(file)
            assert Path.exists(file_path)
            assert file_path.read_text().startswith(  # noqa: ASYNC240
                'local bit = require "bit"',
            )
            Path.unlink(file_path)
            session.get.assert_awaited_once_with(
                "returnedURL",
                timeout=ClientTimeout(10),
            )

            res.status = 404
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )
            with patch.object(
                cloud,
                "_api_request",
                AsyncMock(return_value={"url": "returnedURL"}),
            ):
                assert await cloud.download_lua(tmpdir, 10, "00000000") is None

    async def test_mideaaircloud_download_lua_no_response(self) -> None:
        """Test MideaAirCloud download_lua with no lua metadata."""
        session = Mock()
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            TemporaryDirectory() as tmpdir,
            patch.object(cloud, "_api_request", AsyncMock(return_value=None)),
        ):
            assert await cloud.download_lua(tmpdir, 10, "00000000") is None
        session.get.assert_not_called()

    async def test_mideaaircloud_download_lua_empty_payload(self) -> None:
        """Test MideaAirCloud download_lua with an empty lua payload."""
        session = Mock()
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            TemporaryDirectory() as tmpdir,
            patch.object(
                cloud,
                "_api_request",
                AsyncMock(return_value={"url": "url", "fileName": "lua.lua"}),
            ),
        ):
            assert await cloud.download_lua(tmpdir, 10, "00000000") is None

    async def test_mideaaircloud_download_lua_decrypt_failure(self) -> None:
        """Test MideaAirCloud download_lua handles invalid encrypted lua."""
        session = Mock()
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="not-hex")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with (
            TemporaryDirectory() as tmpdir,
            patch.object(
                cloud,
                "_api_request",
                AsyncMock(return_value={"url": "url", "fileName": "lua.lua"}),
            ),
            self.assertLogs("midealan.cloud", level="WARNING") as logs,
        ):
            assert await cloud.download_lua(tmpdir, 10, "00000000") is None
        assert "Failed to decrypt lua for appliance 00000000" in logs.output[0]

    async def test_mideaaircloud_download_plugin_not_implemented(self) -> None:
        """Test MideaAirCloud does not implement download_plugin."""
        session = Mock()
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with pytest.raises(NotImplementedError):
            await cloud.download_plugin("path", 10, "0000AC000ABCD1234000")

    async def test_mideaaircloud_list_home(self) -> None:
        """Test MideaAirCloud list_home."""
        session = Mock()
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        homes = await cloud.list_home()
        assert homes is not None
        assert len(homes.keys()) == 1

    async def test_mideaaircloud_list_appliances(self) -> None:
        """Test MideaAirCloud list_appliances."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["mideaaircloud_login_id.json"],
                self.responses["mideaaircloud_login.json"],
                self.responses["mideaaircloud_list_appliances.json"],
                self.responses["mideaaircloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()
        appliances = await cloud.list_appliances(None)
        assert appliances is not None
        assert len(appliances.keys()) == 2
        appliance = appliances.get(1)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == "1234567890abcdef1234567890abcdef"
        assert appliance.get("sn8") == "0abcdef1"
        assert appliance.get("model_number") == 10
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == "0abcdef1"
        assert appliance.get("online")

        appliance = appliances.get(2)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name 2"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == ""
        assert appliance.get("sn8") == ""
        assert appliance.get("model_number") == 0
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == ""
        assert not appliance.get("online")

        appliances = await cloud.list_appliances(None)
        assert appliances is None

    async def test_mideaaircloud_get_device_info(self) -> None:
        """Test MideaAirCloud get_device_info."""
        session = Mock()
        response1 = Mock()
        response1.read = AsyncMock(
            return_value=self.responses["mideaaircloud_login_id.json"],
        )
        response2 = Mock()
        response2.read = AsyncMock(
            return_value=self.responses["mideaaircloud_login.json"],
        )
        response3 = Mock()
        response3.read = AsyncMock(
            return_value=self.responses["mideaaircloud_list_appliances.json"],
        )

        session.request = AsyncMock(
            side_effect=[
                response1,
                response2,
                response3,
                ClientConnectionError(),
                response3,
            ],
        )
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        device = await cloud.get_device_info(1)
        assert device is not None
        assert device.get("name") == "Appliance Name"
        assert device.get("type") == 0xAC
        assert device.get("sn") == "1234567890abcdef1234567890abcdef"
        assert device.get("sn8") == "0abcdef1"
        assert device.get("model_number") == 10
        assert device.get("manufacturer_code") == "1234"
        assert device.get("model") == "0abcdef1"
        assert device.get("online")

        device = await cloud.get_device_info(99)
        assert device is None


class DayReportTest(IsolatedAsyncioTestCase):
    """Day report test case."""

    @staticmethod
    def _cloud(
        session: Mock,
        api_url: str = "https://mp-prod.smartmidea.net/mas/v5/app/proxy?alias=",
    ) -> MideaCloud:
        """Build a cloud client for the day report tests."""
        return MideaCloud(
            session=session,
            security=Mock(),
            app_id="appid",
            app_key="appkey",
            account="account",
            password="password",
            api_url=api_url,
        )

    @staticmethod
    def _session(payload: object) -> Mock:
        """Return a session whose single request answers with a payload."""
        response = Mock()
        response.json = AsyncMock(return_value=payload)
        session = Mock()
        session.request = AsyncMock(return_value=response)
        return session

    async def test_get_day_report(self) -> None:
        """Request the usage report with the access token and proxy alias."""
        session = self._session({"retCode": "0", "result": {"date": "2026-09-10"}})
        cloud = self._cloud(session)
        cloud.set_access_token("token")
        result = await cloud.get_day_report(100)
        assert result == {"date": "2026-09-10"}
        call = session.request.await_args
        assert call.args[0] == "POST"
        assert call.args[1] == (
            "https://mp-prod.smartmidea.net/mas/v5/app/proxy?alias=/cfhrs/e3/v1/api"
        )
        assert call.kwargs["headers"] == {
            "content-type": "application/json; charset=utf-8",
            "accessToken": "token",
        }
        assert call.kwargs["json"] == {
            "msg": "dayReportV2",
            "params": {"applianceId": "100"},
        }
        assert call.kwargs["allow_redirects"] is False

    async def test_get_day_report_does_not_follow_redirect(self) -> None:
        """Do not follow day-report redirects with the access token header."""
        target_tokens: list[str | None] = []

        async def target_handler(request: web.Request) -> web.Response:
            target_tokens.append(request.headers.get("accessToken"))
            return web.json_response({"retCode": "0", "result": {}})

        target_runner = web.AppRunner(web.Application())
        target_runner.app.router.add_post("/target", target_handler)
        await target_runner.setup()
        target_site = web.TCPSite(target_runner, "127.0.0.1", 0)
        await target_site.start()
        assert target_site._server is not None
        target_port = target_site._server.sockets[0].getsockname()[1]

        async def redirect_handler(_request: web.Request) -> web.Response:
            return web.Response(
                status=307,
                headers={"Location": f"http://127.0.0.1:{target_port}/target"},
            )

        redirect_runner = web.AppRunner(web.Application())
        redirect_runner.app.router.add_post("/mas/v5/app/proxy", redirect_handler)
        await redirect_runner.setup()
        redirect_site = web.TCPSite(redirect_runner, "127.0.0.1", 0)
        await redirect_site.start()
        assert redirect_site._server is not None
        redirect_port = redirect_site._server.sockets[0].getsockname()[1]

        try:
            async with ClientSession() as session:
                cloud = self._cloud(
                    session,
                    api_url=f"http://127.0.0.1:{redirect_port}/mas/v5/app/proxy?alias=",
                )
                cloud.set_access_token("token")
                with pytest.raises(CloudError):
                    await cloud.get_day_report(100)
        finally:
            await redirect_runner.cleanup()
            await target_runner.cleanup()
        assert target_tokens == []

    async def test_get_day_report_empty_result(self) -> None:
        """Return None when the cloud holds no report for the appliance."""
        session = self._session({"retCode": "0"})
        cloud = self._cloud(session)
        cloud.set_access_token("token")
        assert await cloud.get_day_report(100) is None

    async def test_get_day_report_auth_error(self) -> None:
        """Map a rejected access token to CloudAuthError."""
        session = self._session({"code": 40002, "msg": "token invalid"})
        cloud = self._cloud(session)
        cloud.set_access_token("token")
        with pytest.raises(CloudAuthError):
            await cloud.get_day_report(100)

    async def test_get_day_report_gateway_error(self) -> None:
        """Map a gateway error to CloudError."""
        session = self._session({"code": 1234, "msg": "boom"})
        cloud = self._cloud(session)
        cloud.set_access_token("token")
        with pytest.raises(CloudError):
            await cloud.get_day_report(100)

    async def test_get_day_report_failed_ret_code(self) -> None:
        """Map a non-zero retCode to CloudError."""
        session = self._session({"retCode": "1", "desc": "no report"})
        cloud = self._cloud(session)
        cloud.set_access_token("token")
        with pytest.raises(CloudError):
            await cloud.get_day_report(100)

    async def test_get_day_report_invalid_response(self) -> None:
        """Reject a response that is not a JSON object."""
        session = self._session([])
        cloud = self._cloud(session)
        cloud.set_access_token("token")
        with pytest.raises(CloudError):
            await cloud.get_day_report(100)

    async def test_get_day_report_request_failure(self) -> None:
        """Map a connection failure to CloudError."""
        session = Mock()
        session.request = AsyncMock(side_effect=ClientConnectionError())
        cloud = self._cloud(session)
        cloud.set_access_token("token")
        with pytest.raises(CloudError):
            await cloud.get_day_report(100)

    async def test_get_day_report_no_token(self) -> None:
        """Reject a report request without an access token."""
        with pytest.raises(CloudAuthError):
            await self._cloud(Mock()).get_day_report(100)

    async def test_get_day_report_no_alias(self) -> None:
        """Reject a report request on a cloud without the proxy alias."""
        cloud = self._cloud(
            Mock(),
            api_url="https://mapp.appsmb.com",  # codespell:ignore
        )
        cloud.set_access_token("token")
        with pytest.raises(CloudError):
            await cloud.get_day_report(100)
