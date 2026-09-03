"""Test cloud."""

import json
import logging
from collections.abc import Callable, Iterator
from contextlib import AbstractContextManager, nullcontext
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any, ClassVar
from unittest import IsolatedAsyncioTestCase
from unittest.mock import AsyncMock, Mock, patch

import pytest
from aiohttp import ClientConnectionError

from midealocal.cloud import (
    _RETRY_ATTEMPTS,
    DEFAULT_KEYS,
    MeijuCloud,
    MideaAirCloud,
    MideaCloud,
    SmartHomeCloud,
    ToshibaIOLife,
    _mask_token,
    _redact_data,
    get_default_cloud,
    get_midea_cloud,
    get_preset_account_cloud,
)
from midealocal.exceptions import (
    CloudLoginError,
    ElementMissing,
    MideaCloudError,
    NoDeviceRegistered,
    cloud_api_error,
)

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


def _load_responses() -> dict[str, bytes]:
    """Load all JSON fixtures from tests/responses/ once."""
    return {
        fp.name: fp.read_bytes()
        for fp in (Path(__file__).parent / "responses").iterdir()
        if fp.is_file()
    }


_RESPONSES: dict[str, bytes] = _load_responses()

_TOSHIBA_APP_KEY = "00000000000000000000000000000000"
_TOSHIBA_ACCESS_TOKEN = (
    "e4ddcc22d5ccc270e3b1c876df7c9a8d0a31b22810d0e532c2dd921bb9e0389f"
)
_TOSHIBA_ENCRYPTED_SN = (
    "e1f17526c18d049e4862e19f5d6cd269"
    "df9b09edd41d4b2627b35dbb2d47b963"
    "a433df71998b41d4dc354e9bdf78902a"
)
_TOSHIBA_EXPECTED_SN = "0008AC0000000000000000000000BEEF"

# 9999 "system error": a well-formed body that must be retried in place. Two
# spellings so the same value works for the v5 proxy ("code") and the legacy
# mapp.appsmb.com backend ("errorCode").
_SYSTEM_ERROR_9999 = json.dumps({"code": 9999, "errorCode": 9999}).encode()


@pytest.fixture(autouse=True)
def _no_retry_backoff() -> Iterator[None]:
    """Drop the transient-retry back-off so retry paths run without waiting."""
    with patch("midealocal.cloud.sleep", new=AsyncMock()):
        yield


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("code", "msg"),
    [
        (3102, "Account or password incorrect, please re-enter"),
        (3144, "login failed, loginId is empty, please login again"),
        (7610, "Too many failed login attempts, please try again 5 minutes later"),
        (65027, "该用户在线登录设备已超过上限,请更换账号登录"),
    ],
)
async def test_msmartcloud_login_raises_cloud_login_error(code: int, msg: str) -> None:
    """Test known login-step error codes surface as CloudLoginError.

    3102/3144/7610/65027 are actionable failures of the login / loginId step;
    callers need the code to show the right message, so login() must raise
    rather than return a bare False.
    """
    session = Mock()
    response = Mock()
    response.read = AsyncMock(
        side_effect=[
            _RESPONSES["msmartcloud_reroute.json"],
            json.dumps({"code": code, "msg": msg}).encode(),
        ],
    )
    session.request = AsyncMock(return_value=response)
    cloud = get_midea_cloud(
        "SmartHome",
        session=session,
        account="account",
        password="password",
    )
    with pytest.raises(CloudLoginError) as err:
        await cloud.login()
    assert err.value.code == code


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("cloud_name", "read_side_effect", "warns_rejected"),
    [
        pytest.param(
            "SmartHome",
            [_RESPONSES["cloud_invalid_response.json"]] * 2,
            True,
            id="unclassified-code",
        ),
        pytest.param(
            "SmartHome",
            # re_route and login/id each burn a full retry budget on 9999.
            [_SYSTEM_ERROR_9999] * (_RETRY_ATTEMPTS * 2),
            True,
            id="system-error-9999-v5-proxy",
        ),
        pytest.param(
            "Midea Air",
            # A 9999 that never clears must exhaust the legacy backend's retries
            # and then surface, not loop forever.
            [_SYSTEM_ERROR_9999] * _RETRY_ATTEMPTS,
            True,
            id="system-error-9999-legacy-appsmb",
        ),
        pytest.param(
            "SmartHome",
            [_RESPONSES["msmartcloud_reroute.json"], *[ClientConnectionError()] * 3],
            False,
            id="unreachable",
        ),
        pytest.param(
            "Midea Air",
            [ClientConnectionError()] * _RETRY_ATTEMPTS,
            False,
            id="unreachable-legacy-appsmb",
        ),
    ],
)
async def test_login_returns_false(
    cloud_name: str,
    read_side_effect: list,
    warns_rejected: bool,
    caplog: pytest.LogCaptureFixture,
) -> None:
    """login() returns False (never raises) for non-actionable failures.

    The last case exhausts every retry with no JSON body, leaving the local
    ``{"code": -1}`` sentinel, which must be logged as "already handled" -- no
    "rejected the request" warning and no exception.
    """
    session = Mock()
    response = Mock()
    response.read = AsyncMock(side_effect=read_side_effect)
    session.request = AsyncMock(return_value=response)
    cloud = get_midea_cloud(
        cloud_name,
        session=session,
        account="account",
        password="password",
    )
    with caplog.at_level(logging.WARNING, logger="midealocal.cloud"):
        assert not await cloud.login()
    assert ("rejected the request" in caplog.text) is warns_rejected


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("cloud_name", "reads"),
    [
        pytest.param(
            "SmartHome",
            [
                "msmartcloud_reroute.json",
                _SYSTEM_ERROR_9999,
                "cloud_login_id.json",
                "msmartcloud_login.json",
            ],
            id="v5-proxy",
        ),
        pytest.param(
            "Midea Air",
            [
                "mideaaircloud_login_id.json",
                _SYSTEM_ERROR_9999,
                "mideaaircloud_login.json",
            ],
            id="legacy-appsmb",
        ),
    ],
)
async def test_login_retries_transient_system_error(
    cloud_name: str,
    reads: list[str | bytes],
    caplog: pytest.LogCaptureFixture,
) -> None:
    """A single 9999 during login is resent and recovers.

    The infamous "system error" is a sporadic server fault; midea-beautiful-air
    likewise retries it rather than failing the login.
    """
    session = Mock()
    response = Mock()
    response.read = AsyncMock(
        side_effect=[r if isinstance(r, bytes) else _RESPONSES[r] for r in reads],
    )
    session.request = AsyncMock(return_value=response)
    cloud = get_midea_cloud(
        cloud_name,
        session=session,
        account="account",
        password="password",
    )
    with caplog.at_level(logging.WARNING, logger="midealocal.cloud"):
        assert await cloud.login()
    assert "transient error 9999" in caplog.text
    assert "rejected the request" not in caplog.text


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("get_token_reads", "expectation", "expected_keys"),
    [
        pytest.param(
            [_RESPONSES["cloud_no_permission.json"]],
            pytest.raises(NoDeviceRegistered),
            None,
            id="permission-error-raises",
        ),
        pytest.param(
            [_RESPONSES["cloud_invalid_response.json"]] * 2,
            nullcontext(),
            {},
            id="other-error-returns-empty",
        ),
    ],
)
async def test_msmartcloud_get_cloud_keys_error_handling(
    get_token_reads: list[bytes],
    expectation: AbstractContextManager[Any],
    expected_keys: dict[int, dict[str, str]] | None,
) -> None:
    """get_cloud_keys raises NoDeviceRegistered on 3201, swallows other codes.

    3201 means the account does not own the appliance, so callers can tell the
    user to sign in with the account that paired it; any other non-zero code is
    transient/unknown and must not abort key retrieval.
    """
    session = Mock()
    response = Mock()
    response.read = AsyncMock(
        side_effect=[
            _RESPONSES["msmartcloud_reroute.json"],
            _RESPONSES["cloud_login_id.json"],
            _RESPONSES["msmartcloud_login.json"],
            *get_token_reads,
        ],
    )
    session.request = AsyncMock(return_value=response)
    cloud = get_midea_cloud(
        "SmartHome",
        session=session,
        account="account",
        password="password",
    )
    assert await cloud.login()

    with expectation as err:
        result = await cloud.get_cloud_keys(100)

    if expected_keys is None:
        assert err.value.code == 3201
        assert err.value.message == "You have no permissions."
    else:
        assert result == expected_keys


class CloudTest(IsolatedAsyncioTestCase):
    """Cloud test case."""

    responses: ClassVar[dict[str, bytes]] = _RESPONSES

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
                "midealocal.cloud.SUPPORTED_CLOUDS",
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

    def test_redact_data_masks_token_and_key(self) -> None:
        """Test _redact_data masks getToken credentials.

        Without an explicit rule the generic patterns only chew up the digit
        runs inside a hex credential, which leaves most of it readable while
        looking redacted.
        """
        token = "AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899"
        key = "0011223344556677889900112233445566778899001122334455667788990011"
        raw = str(
            (
                '{"code":0,"data":{"tokenlist":[{'
                f'"udpId":"abc","token":"{token}","key":"{key}"'
                "}]}}"
            ).encode(),
        )

        redacted = _redact_data(raw)

        # exact masked form -- the generic patterns alone produce a different,
        # mostly-readable string, so this is what makes the test discriminating
        assert f'"token":"{_mask_token(token)}"' in redacted
        assert f'"key":"{_mask_token(key)}"' in redacted
        assert token not in redacted
        assert key not in redacted
        # unrelated fields are untouched
        assert '"udpId":"abc"' in redacted

    def test_redact_data_handles_escaped_quotes(self) -> None:
        """Test _redact_data masks credentials rendered with escaped quotes."""
        token = "DEADBEEFDEADBEEFDEADBEEFDEADBEEF"
        redacted = _redact_data(f'{{\\"token\\": \\"{token}\\"}}')
        assert token not in redacted

    async def test_get_cloud_keys_does_not_log_credentials(self) -> None:
        """Test get_cloud_keys keeps token material out of the debug log."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["meijucloud_list_home.json"],
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

        with self.assertLogs("midealocal.cloud", level="DEBUG") as logs:
            keys = await cloud.get_cloud_keys(100)

        assert keys[1]["token"] == "method1_return_token1"
        blob = "\n".join(logs.output)
        assert "method1_return_token1" not in blob
        assert "method1_return_key1" not in blob
        # the replacement line still says something useful
        assert "token entries" in blob

    async def test_get_cloud_servers(self) -> None:
        """Test get cloud servers."""
        servers = await MideaCloud.get_cloud_servers()
        assert len(servers.items()) == 6

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

    async def test_meijucloud_get_keys_skips_foreign_udpid(self) -> None:
        """Test get_cloud_keys ignores tokenlist entries for other devices.

        A home can hold several appliances, so ``tokenlist`` may carry entries
        whose ``udpId`` belongs to a different device. Taking the first entry
        instead of the matching one would hand the device someone else's
        credentials, so the mismatching entry has to be skipped.
        """
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["meijucloud_list_home.json"],
                # method 1: our entry, followed by another device's
                self.responses["meijucloud_get_keys_foreign_udpid.json"],
                # method 2: nothing for us
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

        keys = await cloud.get_cloud_keys(100)

        # the matching entry wins; the foreign one never leaks in
        assert len(keys) == 1
        assert keys[1]["token"] == "method1_return_token1"
        assert keys[1]["key"] == "method1_return_key1"
        assert all(k["token"] != "other_device_token" for k in keys.values())

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

            res.status = 404
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )

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

    def test_cloud_api_error_factory(self) -> None:
        """Test cloud_api_error picks the most specific subclass per code."""
        assert type(cloud_api_error(3201, "")) is NoDeviceRegistered
        assert type(cloud_api_error(7610, "")) is CloudLoginError
        assert type(cloud_api_error(65027, "")) is CloudLoginError
        # unknown code falls back to the base class, and the meaning table
        # enriches the string for known-but-generic codes
        generic = cloud_api_error(9999, "system error")
        assert type(generic) is MideaCloudError
        assert "transient" in str(generic)
        assert cloud_api_error(4242, "boom").code == 4242

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
                b'{"errorCode": 0}',
                self.responses["mideaaircloud_download_lua.json"],
                b'{"errorCode": 0, "data": {"url": "u", "fileName": "../evil.lua"}}',
                b'{"errorCode": 0, "data": {"url": "u", "fileName": "..\\\\evil.lua"}}',
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        # Hex-encoded AES-128-ECB blob keyed by md5("Midea Air" app_key)[:16]
        # that decrypts to a small valid lua snippet.
        res.text = AsyncMock(
            return_value=(
                "f424cd84479c665a7e8a82d3b6bea6b67a1fdc95a7783791a6ff35b2953a158a"
            ),
        )
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "Midea Air",
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
            assert file_path.read_text().startswith(  # noqa: ASYNC240
                'local bit = require "bit"',
            )
            Path.unlink(file_path)

            res.status = 404
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )

            # luaGet answers with errorCode 0 but no payload: _api_request
            # returns None and download_lua bails out.
            res.status = 200
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )

            # The lua file server returns an empty body.
            res.text = AsyncMock(return_value="")
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )

            # A cloud-supplied fileName with path components is rejected and
            # nothing is written outside the target directory.
            res.status = 200
            res.text = AsyncMock(
                return_value=(
                    "f424cd84479c665a7e8a82d3b6bea6b67a1fdc95a7783791a6ff35b2953a158a"
                ),
            )
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )
            assert not (Path(tmpdir).parent / "evil.lua").exists()

            # The same rule applies to a Windows-style separator.
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )
            assert not (Path(tmpdir).parent / "evil.lua").exists()

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


@pytest.fixture(name="make_toshiba_cloud")
def make_toshiba_cloud_fixture() -> Callable[[Mock], ToshibaIOLife]:
    """Return a factory for ToshibaIOLife clouds on a mocked session."""

    def _make(session: Mock) -> ToshibaIOLife:
        cloud = get_midea_cloud(
            "Toshiba Iolife",
            session=session,
            account="account",
            password="password",
        )
        assert isinstance(cloud, ToshibaIOLife)
        cloud._app_key = _TOSHIBA_APP_KEY
        return cloud

    return _make


class TestToshibaDecryptSn:
    """Parametrized unit tests for ToshibaIOLife._decrypt_sn."""

    @pytest.mark.parametrize(
        ("encrypted_sn", "access_token", "expected"),
        [
            (_TOSHIBA_ENCRYPTED_SN, _TOSHIBA_ACCESS_TOKEN, _TOSHIBA_EXPECTED_SN),
            (_TOSHIBA_ENCRYPTED_SN, None, ""),
            ("", _TOSHIBA_ACCESS_TOKEN, ""),
            ("deadbeef" * 4, _TOSHIBA_ACCESS_TOKEN, ""),
            ("nothexatall", _TOSHIBA_ACCESS_TOKEN, ""),
            (_TOSHIBA_ENCRYPTED_SN, "nothexatall", ""),
        ],
    )
    def test_decrypt_sn(
        self,
        make_toshiba_cloud: Callable[[Mock], ToshibaIOLife],
        encrypted_sn: str,
        access_token: str | None,
        expected: str,
    ) -> None:
        """_decrypt_sn returns correct SN or '' on error/empty input."""
        cloud = make_toshiba_cloud(Mock())
        cloud._access_token = access_token
        assert cloud._decrypt_sn(encrypted_sn) == expected


class ToshibaIOLifeTest(IsolatedAsyncioTestCase):
    """ToshibaIOLife cloud async tests."""

    responses: ClassVar[dict[str, bytes]] = _RESPONSES
    make_cloud: Callable[[Mock], ToshibaIOLife]

    @pytest.fixture(autouse=True)
    def _inject_cloud_factory(
        self,
        make_toshiba_cloud: Callable[[Mock], ToshibaIOLife],
    ) -> None:
        """Share the cloud factory with these unittest-style tests."""
        self.make_cloud = make_toshiba_cloud

    async def test_list_appliances_success(self) -> None:
        """list_appliances decrypts SN inline and skips virtual devices."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["mideaaircloud_login_id.json"],
                self.responses["mideaaircloud_login.json"],
                self.responses["toshibaiolife_list_appliances.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = self.make_cloud(session)
        assert await cloud.login()
        cloud._access_token = _TOSHIBA_ACCESS_TOKEN

        appliances = await cloud.list_appliances(None)
        assert len(appliances) == 1

        dev = appliances[12345678]
        assert dev["name"] == "Living Room AC"
        assert dev["type"] == 0xAC
        assert dev["sn"] == _TOSHIBA_EXPECTED_SN
        assert dev["sn8"] == "00000000"
        assert dev["model_number"] == 10
        assert dev["manufacturer_code"] == "0008"
        assert dev["model"] == "00000000"
        assert dev["online"] is True

    async def test_list_appliances_uses_cloud_app_version(self) -> None:
        """AppVersion comes from the SUPPORTED_CLOUDS entry."""
        cloud = self.make_cloud(Mock())
        cloud._access_token = _TOSHIBA_ACCESS_TOKEN
        request = AsyncMock(return_value=[])
        with patch.object(cloud, "_api_request", new=request):
            await cloud.list_appliances(None)
        assert request.await_args is not None
        assert request.await_args.kwargs["data"]["appVersion"] == "3.4.0"

    async def test_list_appliances_skips_malformed_entries(self) -> None:
        """Entries with an unusable id or type are skipped, not fatal."""
        cloud = self.make_cloud(Mock())
        cloud._access_token = _TOSHIBA_ACCESS_TOKEN
        good = {
            "id": "12345678",
            "type": "0xAC",
            "name": "Living Room AC",
            "modelNumber": "10",
            "onlineStatus": "1",
        }
        with patch.object(
            cloud,
            "_api_request",
            new=AsyncMock(
                return_value=[
                    {"id": "not-a-number", "type": "0xAC"},
                    {"id": "1", "type": "not-hex"},
                    {"type": "0xAC"},
                    {"id": "2", "type": None},
                    good,
                ],
            ),
        ):
            appliances = await cloud.list_appliances(None)
        assert list(appliances) == [12345678]

    async def test_list_appliances_non_numeric_model_number(self) -> None:
        """A non-numeric modelNumber falls back to 0 rather than raising."""
        cloud = self.make_cloud(Mock())
        cloud._access_token = _TOSHIBA_ACCESS_TOKEN
        with patch.object(
            cloud,
            "_api_request",
            new=AsyncMock(
                return_value=[
                    {
                        "id": "12345678",
                        "type": "0xAC",
                        "name": "Living Room AC",
                        "modelNumber": "RAS-X221DZ",
                        "onlineStatus": "1",
                    },
                ],
            ),
        ):
            appliances = await cloud.list_appliances(None)
        assert appliances[12345678]["model_number"] == 0

    async def test_list_appliances_api_failure(self) -> None:
        """list_appliances returns empty dict when the API returns an error."""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["mideaaircloud_invalid_response.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = self.make_cloud(session)
        cloud._access_token = _TOSHIBA_ACCESS_TOKEN
        assert await cloud.list_appliances(None) == {}

    async def test_list_appliances_non_list_response(self) -> None:
        """list_appliances returns empty dict when the API returns a non-list."""
        cloud = self.make_cloud(Mock())
        cloud._access_token = _TOSHIBA_ACCESS_TOKEN
        with patch.object(
            cloud,
            "_api_request",
            new=AsyncMock(return_value={"result": []}),
        ):
            assert await cloud.list_appliances(None) == {}

    async def test_list_appliances_skips_non_mapping_entries(self) -> None:
        """list_appliances silently skips non-mapping entries in the list."""
        entry = {
            "id": "12345678",
            "type": "0xAC",
            "name": "Living Room AC",
            "modelNumber": 10,
            "onlineStatus": "1",
            "sn": _TOSHIBA_ENCRYPTED_SN,
        }
        cloud = self.make_cloud(Mock())
        cloud._access_token = _TOSHIBA_ACCESS_TOKEN
        with patch.object(
            cloud,
            "_api_request",
            new=AsyncMock(return_value=["not-a-mapping", entry]),
        ):
            appliances = await cloud.list_appliances(None)
        assert len(appliances) == 1
