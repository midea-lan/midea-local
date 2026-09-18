"""Midea Local CLI tests."""

import json
import logging
import runpy
import subprocess
import sys
import warnings
from argparse import Namespace
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import IsolatedAsyncioTestCase, skipIf
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from midealocal.cli import (
    MideaCLI,
    get_config_file_path,
    get_devices_cache_path,
    main,
)
from midealocal.cloud import MideaAirCloud, SmartHomeCloud
from midealocal.const import ProtocolVersion
from midealocal.device import AuthException, NoSupportedProtocol
from midealocal.discover import _extract_mac
from midealocal.exceptions import (
    CloudLoginError,
    NoDeviceRegistered,
    SocketException,
)

_DEFAULT_KEYS = {99: {"key": "key99", "token": "token99"}}


@pytest.fixture
def cli() -> MideaCLI:
    """Return a MideaCLI with the minimal namespace the cloud-key paths need."""
    instance = MideaCLI()
    instance.session = AsyncMock()
    instance.namespace = Namespace(
        cloud_name="SmartHome",
        username="user",
        password="pass",
    )
    return instance


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("login_side_effect", "get_cloud_keys_side_effect"),
    [
        pytest.param(
            None,
            NoDeviceRegistered(3201, "You have no permissions"),
            id="device-bound-to-other-account",
        ),
        pytest.param(
            CloudLoginError(7610, "rate limited"),
            None,
            id="login-rejected",
        ),
    ],
)
async def test_get_keys_falls_back_to_default_keys(
    cli: MideaCLI,
    login_side_effect: Exception | None,
    get_cloud_keys_side_effect: Exception | None,
) -> None:
    """_get_keys returns only the default keys when the cloud path fails.

    ``login_side_effect=None`` leaves an AsyncMock (truthy) so the flow reaches
    ``get_cloud_keys``; a raised ``get_cloud_keys`` would break ``keys ==``.
    """
    mock_cloud = AsyncMock()
    mock_cloud.get_default_keys.return_value = _DEFAULT_KEYS
    mock_cloud.login.side_effect = login_side_effect
    mock_cloud.get_cloud_keys.side_effect = get_cloud_keys_side_effect

    with patch("midealocal.cli.get_midea_cloud", return_value=mock_cloud):
        keys = await cli._get_keys(0)

    assert keys == _DEFAULT_KEYS


class TestMideaCLI(IsolatedAsyncioTestCase):
    """Test Midea CLI."""

    def setUp(self) -> None:
        """Create namespace for testing."""
        self.cli = MideaCLI()
        self.namespace = Namespace(
            cloud_name="SmartHome",
            username="user",
            password="pass",
            host="192.168.0.1",
            message=bytes.fromhex("00a1a2ac0f2a0000"),
            device_type=bytearray(),
            device_sn="",
            user=False,
            debug=True,
            get_sn=False,
            attribute="power",
            value="0",
            attr_type="bool",
            func=MagicMock(),
        )
        self.cli.namespace = self.namespace

    async def test_get_cloud(self) -> None:
        """Test get cloud."""
        mock_session_instance = AsyncMock()
        with (
            patch("aiohttp.ClientSession", return_value=mock_session_instance),
        ):
            cloud = await self.cli._get_cloud()

        assert isinstance(cloud, SmartHomeCloud)
        assert cloud._account == self.namespace.username
        assert cloud._password == self.namespace.password
        assert cloud._session == mock_session_instance

        # test default cloud
        self.namespace.cloud_name = None
        cloud = await self.cli._get_cloud()
        assert isinstance(cloud, MideaAirCloud)
        assert cloud._session == mock_session_instance

    async def test_get_keys(self) -> None:
        """Test get keys."""
        mock_cloud = AsyncMock()
        with (
            patch("midealocal.cli.get_midea_cloud", return_value=mock_cloud),
            patch.object(
                mock_cloud,
                "get_default_keys",
                return_value={99: {"key": "key99", "token": "token99"}},
            ) as mock_default_keys,
            patch.object(
                mock_cloud,
                "get_cloud_keys",
                return_value={
                    0: {"key": "key0", "token": "token0"},
                    1: {"key": "key1", "token": "token1"},
                },
            ) as mock_cloud_keys,
            patch.object(mock_cloud, "login", side_effect=[True, False]),
        ):
            keys = await self.cli._get_keys(0)
            assert len(keys) == 3
            assert keys[0]["key"] == "key0"
            assert keys[1]["key"] == "key1"
            assert keys[99]["key"] == "key99"
            assert keys[0]["token"] == "token0"
            assert keys[1]["token"] == "token1"
            assert keys[99]["token"] == "token99"
            mock_default_keys.assert_called_once()
            mock_default_keys.reset_mock()
            mock_cloud_keys.assert_called_once_with(0)
            mock_cloud_keys.reset_mock()

            keys = await self.cli._get_keys(0)
            assert len(keys) == 1
            assert keys[99]["key"] == "key99"
            assert keys[99]["token"] == "token99"
            mock_default_keys.assert_called_once()
            mock_cloud_keys.assert_not_called()

    def test_extract_mac(self) -> None:
        """Test _extract_mac."""
        expected_mac = "1234567890ab"
        mac = _extract_mac(
            reply=b"",
            ssid_len=0,
            sn="a" * 16 + expected_mac + "1234",
        )
        assert mac == expected_mac
        mac2 = _extract_mac(
            reply=b"a" * 63 + b"bb" + b"\x12\x34\x56\x78\x90\xab",
            ssid_len=2,
            sn="a" * 16 + expected_mac + "1234",
        )
        assert mac2 == expected_mac
        mac3 = _extract_mac(b"", 1, "shortsn")
        assert mac3 is None

    async def test_discover(self) -> None:
        """Test discover."""
        mock_device = {
            "device_id": 1,
            "protocol": ProtocolVersion.V3,
            "type": "AC",
            "ip_address": "192.168.0.2",
            "port": 6444,
            "model": "AC123000",
            "sn": "0000AC12300000001234567890ABCDEF",
            "mac": "1234567890AB",
        }
        mock_cloud_instance = AsyncMock()
        mock_device_instance = MagicMock()
        mock_device_instance.connect.return_value = True
        tmpdir = TemporaryDirectory()
        self.addCleanup(tmpdir.cleanup)
        cache_file = Path(tmpdir.name) / "midea-devices.json"
        with (
            patch(
                "midealocal.cli.discover",
            ) as mock_discover,
            patch.object(
                self.cli,
                "_get_cloud",
                return_value=mock_cloud_instance,
            ),
            patch(
                "midealocal.cli.device_selector",
                return_value=mock_device_instance,
            ),
            patch.object(
                mock_device_instance,
                "refresh_status",
            ) as refresh_status_mock,
            patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=cache_file,
            ),
        ):
            mock_discover.return_value = {1: mock_device}
            mock_cloud_instance.get_cloud_keys.return_value = {
                0: {"token": "token", "key": "key"},
            }
            mock_cloud_instance.get_default_keys.return_value = {
                99: {"token": "token", "key": "key"},
            }

            # test V3 device get_sn
            self.namespace.get_sn = True
            await self.cli.discover()  # test V3 device get_sn
            mock_discover.assert_called()
            # set get_sn to default False after test done
            self.namespace.get_sn = False

            # test V3 device: connect() already authenticated, discover only
            # calls refresh_status once and stops trying further candidate
            # keys once one connects successfully.
            refresh_status_mock.side_effect = None
            await self.cli.discover()  # V3 device
            refresh_status_mock.assert_called_with(True)
            refresh_status_mock.reset_mock()
            # the successful call above cached a key for this device; clear it
            # so the failure scenarios below hit the cloud path fresh, with
            # both candidate keys available.
            cache_file.unlink()

            # V3 device where refresh_status raises: each failure is caught and
            # the device is simply not added to the list.
            refresh_status_mock.side_effect = [AuthException, NoSupportedProtocol]
            assert await self.cli.discover() == []
            refresh_status_mock.reset_mock()

            refresh_status_mock.side_effect = [SocketException, None]
            await self.cli.discover()  # V3 device SocketException on first key
            refresh_status_mock.reset_mock()
            cache_file.unlink()  # the second key succeeded and got cached

            refresh_status_mock.side_effect = [OSError, None]
            await self.cli.discover()  # V3 device OSError on first key
            refresh_status_mock.reset_mock()
            cache_file.unlink()  # the second key succeeded and got cached

            mock_device["protocol"] = ProtocolVersion.V2
            refresh_status_mock.side_effect = None
            await self.cli.discover()  # V2 device
            refresh_status_mock.assert_called_with(True)
            refresh_status_mock.reset_mock()

            mock_device_instance.connect.return_value = False
            await self.cli.discover()  # connect failed

            mock_discover.return_value = {}

            await self.cli.discover()  # No devices

    async def test_try_connect_auth_exception_does_not_log_key(self) -> None:
        """Test the AuthException log message never includes the actual key/token."""
        mock_device_instance = MagicMock()
        mock_device_instance.connect.return_value = True
        mock_device_instance.refresh_status.side_effect = AuthException
        device = {
            "device_id": 1,
            "protocol": ProtocolVersion.V3,
            "type": "AC",
            "ip_address": "192.168.0.2",
            "port": 6444,
            "model": "AC123000",
            "sn": "0000AC12300000001234567890ABCDEF",
            "mac": "1234567890AB",
        }
        secret_key = {"token": "supersecrettoken", "key": "supersecretkey"}
        with (
            patch(
                "midealocal.cli.device_selector",
                return_value=mock_device_instance,
            ),
            self.assertLogs("cli", level="DEBUG") as log,
        ):
            success = self.cli._try_connect(device, secret_key, [])

        assert success is False
        logged_text = "\n".join(log.output)
        assert "supersecrettoken" not in logged_text
        assert "supersecretkey" not in logged_text

    async def test_discover_caches_working_key_and_stops_trying_others(self) -> None:
        """Test discover caches the winning key and skips remaining candidates."""
        mock_device = {
            "device_id": 1,
            "protocol": ProtocolVersion.V3,
            "type": "AC",
            "ip_address": "192.168.0.2",
            "port": 6444,
            "model": "AC123000",
            "sn": "0000AC12300000001234567890ABCDEF",
            "mac": "1234567890AB",
        }
        mock_device_instance = MagicMock()
        mock_device_instance.connect.return_value = True
        with TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "midea-devices.json"
            with (
                patch(
                    "midealocal.cli.discover",
                    return_value={1: mock_device},
                ),
                patch.object(
                    self.cli,
                    "_get_keys",
                    return_value={
                        0: {"token": "cloudtoken", "key": "cloudkey"},
                        99: {"token": "defaulttoken", "key": "defaultkey"},
                    },
                ) as mock_get_keys,
                patch(
                    "midealocal.cli.device_selector",
                    return_value=mock_device_instance,
                ) as mock_device_selector,
                patch(
                    "midealocal.cli.get_devices_cache_path",
                    return_value=cache_file,
                ),
            ):
                result = await self.cli.discover()

            mock_get_keys.assert_called_once_with(1)
            # only the first candidate key is tried once it connects
            mock_device_selector.assert_called_once_with(
                name=1,
                device_id=1,
                device_type="AC",
                ip_address="192.168.0.2",
                port=6444,
                token="cloudtoken",
                key="cloudkey",
                device_protocol=ProtocolVersion.V3,
                model="AC123000",
                subtype=0,
                customize="",
                mac="1234567890AB",
                serial_number="0000AC12300000001234567890ABCDEF",
            )
            assert result == [mock_device_instance]
            cached = json.loads(cache_file.read_text(encoding="utf-8"))
            assert cached == {
                "devices": [
                    {"device_id": "1", "token": "cloudtoken", "key": "cloudkey"},
                ],
            }

    async def test_discover_uses_cached_key_without_cloud_calls(self) -> None:
        """Test discover tries a cached token/key first, with no cloud calls."""
        mock_device = {
            "device_id": 1,
            "protocol": ProtocolVersion.V3,
            "type": "AC",
            "ip_address": "192.168.0.2",
            "port": 6444,
            "model": "AC123000",
            "sn": "0000AC12300000001234567890ABCDEF",
            "mac": "1234567890AB",
        }
        mock_device_instance = MagicMock()
        mock_device_instance.connect.return_value = True
        with TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "midea-devices.json"
            cache_file.write_text(
                json.dumps(
                    {
                        "devices": [
                            {
                                "device_id": "1",
                                "token": "cachedtoken",
                                "key": "cachedkey",
                            },
                        ],
                    },
                ),
                encoding="utf-8",
            )
            with (
                patch(
                    "midealocal.cli.discover",
                    return_value={1: mock_device},
                ),
                patch.object(self.cli, "_get_cloud") as mock_get_cloud,
                patch(
                    "midealocal.cli.device_selector",
                    return_value=mock_device_instance,
                ) as mock_device_selector,
                patch(
                    "midealocal.cli.get_devices_cache_path",
                    return_value=cache_file,
                ),
                self.assertLogs("cli", level="INFO") as log,
            ):
                result = await self.cli.discover()

            mock_get_cloud.assert_not_called()
            mock_device_selector.assert_called_once_with(
                name=1,
                device_id=1,
                device_type="AC",
                ip_address="192.168.0.2",
                port=6444,
                token="cachedtoken",
                key="cachedkey",
                device_protocol=ProtocolVersion.V3,
                model="AC123000",
                subtype=0,
                customize="",
                mac="1234567890AB",
                serial_number="0000AC12300000001234567890ABCDEF",
            )
            assert result == [mock_device_instance]
            assert any(
                "Found cached token/key, using those instead of asking cloud" in message
                for message in log.output
            )

    async def test_discover_falls_back_to_cloud_when_cached_key_fails(self) -> None:
        """Test a stale cached key falls back to the cloud instead of giving up."""
        mock_device = {
            "device_id": 1,
            "protocol": ProtocolVersion.V3,
            "type": "AC",
            "ip_address": "192.168.0.2",
            "port": 6444,
            "model": "AC123000",
            "sn": "0000AC12300000001234567890ABCDEF",
            "mac": "1234567890AB",
        }
        mock_device_instance = MagicMock()
        # the stale cached key fails to even connect; a fresh cloud key does
        mock_device_instance.connect.side_effect = [False, True]
        with TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "midea-devices.json"
            cache_file.write_text(
                json.dumps(
                    {
                        "devices": [
                            {
                                "device_id": "1",
                                "token": "staletoken",
                                "key": "stalekey",
                            },
                        ],
                    },
                ),
                encoding="utf-8",
            )
            with (
                patch(
                    "midealocal.cli.discover",
                    return_value={1: mock_device},
                ),
                patch.object(
                    self.cli,
                    "_get_keys",
                    return_value={0: {"token": "freshtoken", "key": "freshkey"}},
                ) as mock_get_keys,
                patch(
                    "midealocal.cli.device_selector",
                    return_value=mock_device_instance,
                ) as mock_device_selector,
                patch(
                    "midealocal.cli.get_devices_cache_path",
                    return_value=cache_file,
                ),
            ):
                result = await self.cli.discover()

            mock_get_keys.assert_called_once_with(1)
            assert mock_device_selector.call_count == 2
            assert mock_device_selector.call_args_list[0].kwargs["token"] == (
                "staletoken"
            )
            assert mock_device_selector.call_args_list[1].kwargs["token"] == (
                "freshtoken"
            )
            assert result == [mock_device_instance]
            # the fresh, working key replaces the stale cached one
            cached = json.loads(cache_file.read_text(encoding="utf-8"))
            assert cached == {
                "devices": [
                    {"device_id": "1", "token": "freshtoken", "key": "freshkey"},
                ],
            }

    async def test_get_cached_device_keys(self) -> None:
        """Test _get_cached_device_keys reads a matching entry, or returns None."""
        with TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "midea-devices.json"
            cache_file.write_text(
                json.dumps(
                    {"devices": [{"device_id": "1", "token": "tok", "key": "key"}]},
                ),
                encoding="utf-8",
            )
            with patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=cache_file,
            ):
                assert await self.cli._get_cached_device_keys(1) == {
                    "token": "tok",
                    "key": "key",
                }
                assert await self.cli._get_cached_device_keys(2) is None

            with patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=Path(tmpdir) / "does-not-exist.json",
            ):
                assert await self.cli._get_cached_device_keys(1) is None

    async def test_get_cached_device_keys_ignores_malformed_cache(self) -> None:
        """Test malformed cache data is treated as a cache miss, not a crash."""
        with TemporaryDirectory() as tmpdir:
            # invalid JSON
            invalid_json = Path(tmpdir) / "invalid.json"
            invalid_json.write_text("not json", encoding="utf-8")
            with patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=invalid_json,
            ):
                assert await self.cli._get_cached_device_keys(1) is None

            # JSON root is not an object
            non_object_root = Path(tmpdir) / "list.json"
            non_object_root.write_text(json.dumps([1, 2, 3]), encoding="utf-8")
            with patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=non_object_root,
            ):
                assert await self.cli._get_cached_device_keys(1) is None

            # a "devices" entry that isn't an object
            bad_entry = Path(tmpdir) / "bad_entry.json"
            bad_entry.write_text(json.dumps({"devices": ["oops"]}), encoding="utf-8")
            with patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=bad_entry,
            ):
                assert await self.cli._get_cached_device_keys(1) is None

            # a matching entry missing its token/key
            missing_fields = Path(tmpdir) / "missing_fields.json"
            missing_fields.write_text(
                json.dumps({"devices": [{"device_id": "1"}]}),
                encoding="utf-8",
            )
            with patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=missing_fields,
            ):
                assert await self.cli._get_cached_device_keys(1) is None

    async def test_cache_device_keys_write_failure_is_logged_not_raised(
        self,
    ) -> None:
        """Test a cache write failure (e.g. read-only filesystem) doesn't raise."""
        with TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "midea-devices.json"
            with (
                patch(
                    "midealocal.cli.get_devices_cache_path",
                    return_value=cache_file,
                ),
                patch.object(Path, "replace", side_effect=OSError("disk full")),
            ):
                await self.cli._cache_device_keys(1, {"token": "tok", "key": "key"})

    @skipIf(
        sys.platform == "win32",
        "Windows has no POSIX permission bits for chmod to set.",
    )
    async def test_cache_device_keys_sets_owner_only_permissions(self) -> None:
        """Test the cache file is written with owner-only (0600) permissions."""
        with TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "midea-devices.json"
            with patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=cache_file,
            ):
                await self.cli._cache_device_keys(1, {"token": "tok", "key": "key"})

            assert cache_file.stat().st_mode & 0o777 == 0o600
            # no leftover temp file from the atomic write
            assert not cache_file.with_name(cache_file.name + ".tmp").exists()

    async def test_cache_device_keys_replaces_existing_entry(self) -> None:
        """Test _cache_device_keys overwrites a stale entry for the same device."""
        with TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "midea-devices.json"
            cache_file.write_text(
                json.dumps(
                    {"devices": [{"device_id": "1", "token": "old", "key": "old"}]},
                ),
                encoding="utf-8",
            )
            with patch(
                "midealocal.cli.get_devices_cache_path",
                return_value=cache_file,
            ):
                await self.cli._cache_device_keys(1, {"token": "new", "key": "new"})

            cached = json.loads(cache_file.read_text(encoding="utf-8"))
            assert cached == {
                "devices": [{"device_id": "1", "token": "new", "key": "new"}],
            }

    def test_message(self) -> None:
        """Test message."""
        mock_device_instance = MagicMock()
        with patch(
            "midealocal.cli.device_selector",
            return_value=mock_device_instance,
        ) as mock_device_selector:
            mock_device_selector.return_value = mock_device_instance

            self.cli.message()

            mock_device_selector.assert_called_once_with(
                device_id=0,
                name="",
                device_type=int(self.namespace.message[2]),
                ip_address="192.168.192.168",
                port=6664,
                device_protocol=ProtocolVersion.V2,
                model="0000",
                token="",
                key="",
                subtype=0,
                customize="",
            )
            mock_device_instance.process_message.assert_called_once_with(
                self.namespace.message,
            )

    def test_save(self) -> None:
        """Test save."""
        mock_path_instance = MagicMock()
        with patch("midealocal.cli.get_config_file_path") as mock_get_config_file_path:
            mock_get_config_file_path.return_value = mock_path_instance

            self.cli.save()

            mock_get_config_file_path.assert_called_once_with(not self.namespace.user)
            mock_path_instance.open.assert_called_once_with(mode="w+", encoding="utf-8")
            handle = mock_path_instance.open.return_value.__enter__.return_value
            handle.write.assert_called_once_with(
                json.dumps(
                    {
                        "username": self.namespace.username,
                        "password": self.namespace.password,
                        "cloud_name": self.namespace.cloud_name,
                    },
                ),
            )
            mock_path_instance.chmod.assert_called_once_with(0o600)

    async def test_download(self) -> None:
        """Test download."""
        mock_device = {
            "device_id": 1,
            "protocol": ProtocolVersion.V3,
            "type": 0xAC,
            "ip_address": "192.168.0.2",
            "port": 6444,
            "model": "ABCD1234",
            "sn": "0000AC000ABCD1234000000000000000",
        }
        # An AC serial number: the type byte at sn[4:6] is "00", so the type
        # must come from the cloud appliance list, not the serial number.
        cloud_sn = "00000051222270043261305102930000"
        cloud_appliance = {
            "name": "AC",
            "type": 0xAC,
            "sn": cloud_sn,
            "sn8": "22270043",
            "model_number": 44204,
            "manufacturer_code": "0000",
            "model": "KFR-72L",
            "online": True,
        }
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.list_appliances.return_value = {1: cloud_appliance}
        with (
            patch(
                "midealocal.cli.discover",
                side_effect=[
                    {},  # test no device
                    {1: mock_device},  # test download lua with host ip
                ],
            ) as mock_discover,
            patch.object(
                self.cli,
                "_get_cloud",
                return_value=mock_cloud_instance,
            ),
        ):
            # cloud login failed: nothing is discovered or downloaded
            mock_cloud_instance.login.return_value = False
            await self.cli.download()
            mock_cloud_instance.login.assert_called_once()
            mock_discover.assert_not_called()
            mock_cloud_instance.download_lua.assert_not_called()
            mock_cloud_instance.login.reset_mock()

            mock_cloud_instance.login.return_value = True

            # host mode but no device found
            await self.cli.download()
            mock_discover.assert_called_once_with(ip_address=self.namespace.host)
            mock_discover.reset_mock()
            mock_cloud_instance.download_lua.assert_not_called()

            # download lua with host (device type comes from discovery)
            await self.cli.download()
            mock_discover.assert_called_once_with(ip_address=self.namespace.host)
            mock_discover.reset_mock()
            mock_cloud_instance.download_lua.assert_called_once_with(
                str(Path()),
                mock_device["type"],
                mock_device["sn"],
                mock_device["model"],
                "0000",
            )
            mock_cloud_instance.download_lua.reset_mock()
            mock_cloud_instance.download_plugin.assert_called_once_with(
                str(Path()),
                mock_device["type"],
                mock_device["sn"],
            )
            mock_cloud_instance.download_plugin.reset_mock()

            # download lua with SN: type and model resolved from the cloud list
            # (the AC serial's sn[4:6] is "00", so the cloud value fixes it)
            self.namespace.host = None
            self.namespace.device_sn = cloud_sn
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once_with(
                str(Path()),
                cloud_appliance["type"],
                cloud_sn,
                cloud_appliance["model"],
                cloud_appliance["manufacturer_code"],
            )
            mock_cloud_instance.download_lua.reset_mock()
            mock_cloud_instance.download_plugin.assert_called_once_with(
                str(Path()),
                cloud_appliance["type"],
                cloud_sn,
            )
            mock_cloud_instance.download_plugin.reset_mock()

            # download lua with SN and explicit device_type override: the legacy
            # path, which uses the argument and derives the model from the SN
            # without consulting the cloud account.
            self.namespace.device_sn = cloud_sn
            self.namespace.device_type = bytes.fromhex("AC")
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once_with(
                str(Path()),
                0xAC,
                cloud_sn,
                cloud_sn[9:17],
                "0000",
            )
            mock_cloud_instance.download_lua.reset_mock()
            self.namespace.device_type = bytearray()

            # SN not on the account and no device_type: legacy fallback derives
            # the type from sn[4:6] (0xFF here) and the model from sn[9:17].
            unknown_sn = "0000FF00UNKNOWN00000000000000000"
            self.namespace.device_sn = unknown_sn
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once_with(
                str(Path()),
                0xFF,
                unknown_sn,
                unknown_sn[9:17],
                "0000",
            )
            mock_cloud_instance.download_lua.reset_mock()

            # SN not on the account with explicit device_type: honored as-is
            self.namespace.device_sn = unknown_sn
            self.namespace.device_type = bytes.fromhex("B0")
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once_with(
                str(Path()),
                0xB0,
                unknown_sn,
                unknown_sn[9:17],
                "0000",
            )
            mock_cloud_instance.download_lua.reset_mock()
            self.namespace.device_type = bytearray()

            # no host and no SN: download every device in the cloud account
            self.namespace.host = None
            self.namespace.device_sn = None
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once_with(
                str(Path()),
                cloud_appliance["type"],
                cloud_sn,
                cloud_appliance["model"],
                cloud_appliance["manufacturer_code"],
            )
            mock_cloud_instance.download_lua.reset_mock()

            # no host, no SN, and no devices on the account
            mock_cloud_instance.list_appliances.return_value = {}
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_not_called()

    async def test_download_not_supported(self) -> None:
        """Download on a cloud without lua/plugin support is handled cleanly."""
        cloud_sn = "0000FA00ABCD1234000000000000000A"
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.return_value = True
        mock_cloud_instance.list_appliances.return_value = {}
        # MideaAirCloud raises NotImplementedError for these downloads.
        mock_cloud_instance.download_lua.side_effect = NotImplementedError
        mock_cloud_instance.download_plugin.side_effect = NotImplementedError
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = cloud_sn
            self.namespace.device_type = bytes.fromhex("FA")
            # Must not raise: the NotImplementedError is caught and logged.
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once()
            # lua download failed, so the plugin download is not attempted.
            mock_cloud_instance.download_plugin.assert_not_called()

    async def test_download_lua_only(self) -> None:
        """A cloud with lua but no plugin support downloads lua and warns."""
        cloud_sn = "0000FA00ABCD1234000000000000000A"
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.return_value = True
        mock_cloud_instance.list_appliances.return_value = {}
        # Legacy MideaAirCloud: lua downloads, plugin is not supported.
        mock_cloud_instance.download_lua.return_value = "fileName.lua"
        mock_cloud_instance.download_plugin.side_effect = NotImplementedError
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = cloud_sn
            self.namespace.device_type = bytes.fromhex("FA")
            # Must not raise: the plugin NotImplementedError is caught and the
            # successful lua download stands.
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once()
            mock_cloud_instance.download_plugin.assert_called_once()

    async def test_download_lua_returns_none(self) -> None:
        """download_lua returning None skips the plugin download."""
        cloud_sn = "0000FA00ABCD1234000000000000000A"
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.return_value = True
        mock_cloud_instance.list_appliances.return_value = {}
        # The cloud reports failure by returning None instead of raising.
        mock_cloud_instance.download_lua.return_value = None
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = cloud_sn
            self.namespace.device_type = bytes.fromhex("FA")
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once()
            mock_cloud_instance.download_plugin.assert_not_called()

    async def test_download_cloud_login_error(self) -> None:
        """download() bails out cleanly when login raises CloudLoginError."""
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.side_effect = CloudLoginError(7610, "rate limited")
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = ""
            # Must not raise, and must not proceed to enumerate appliances.
            await self.cli.download()
            mock_cloud_instance.list_appliances.assert_not_called()
            mock_cloud_instance.download_lua.assert_not_called()

    async def test_download_plugin_error_is_isolated(self) -> None:
        """A plugin download error is logged without discarding the lua file."""
        cloud_sn = "0000FA00ABCD1234000000000000000A"
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.return_value = True
        mock_cloud_instance.list_appliances.return_value = {}
        mock_cloud_instance.download_lua.return_value = "fileName.lua"
        mock_cloud_instance.download_plugin.side_effect = ValueError("boom")
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = cloud_sn
            self.namespace.device_type = bytes.fromhex("FA")
            # Must not raise: the plugin error is caught and logged.
            await self.cli.download()
            mock_cloud_instance.download_lua.assert_called_once()
            mock_cloud_instance.download_plugin.assert_called_once()

    async def test_download_bulk_multiple_devices(self) -> None:
        """Bulk download runs once for every device in the cloud account."""
        appliance_a = {
            "type": 0xAC,
            "sn": "0000AC00AAAA1111000000000000000A",
            "model": "MODEL-A",
            "manufacturer_code": "0000",
        }
        appliance_b = {
            "type": 0xC3,
            "sn": "0000C300BBBB2222000000000000000B",
            "model": "MODEL-B",
            "manufacturer_code": "0011",
        }
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.return_value = True
        mock_cloud_instance.list_appliances.return_value = {
            1: appliance_a,
            2: appliance_b,
        }
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = None
            await self.cli.download()

        assert mock_cloud_instance.download_lua.call_count == 2
        for appliance in (appliance_a, appliance_b):
            mock_cloud_instance.download_lua.assert_any_call(
                str(Path()),
                appliance["type"],
                appliance["sn"],
                appliance["model"],
                appliance["manufacturer_code"],
            )
        assert mock_cloud_instance.download_plugin.call_count == 2

    async def test_download_bulk_isolates_device_failure(self) -> None:
        """One device error must not abort the remaining bulk downloads."""
        appliance_a = {
            "type": 0xAC,
            "sn": "0000AC00AAAA1111000000000000000A",
            "model": "MODEL-A",
            "manufacturer_code": "0000",
        }
        appliance_b = {
            "type": 0xC3,
            "sn": "0000C300BBBB2222000000000000000B",
            "model": "MODEL-B",
            "manufacturer_code": "0011",
        }
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.return_value = True
        mock_cloud_instance.list_appliances.return_value = {
            1: appliance_a,
            2: appliance_b,
        }
        # The first device raises a non-NotImplementedError; the second must
        # still be processed.
        mock_cloud_instance.download_lua.side_effect = [
            ValueError("bad payload"),
            "b.lua",
        ]
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = None
            await self.cli.download()

        assert mock_cloud_instance.download_lua.call_count == 2
        # The failed device skips its plugin; only the healthy one downloads it.
        mock_cloud_instance.download_plugin.assert_called_once_with(
            str(Path()),
            appliance_b["type"],
            appliance_b["sn"],
        )

    async def test_download_by_sn_non_hex_type_byte(self) -> None:
        """A --device-sn whose type byte is not hex falls back to type 0."""
        # 32 chars (SERIAL_TYPE1_LENGTH) with a non-hex "ZZ" at sn[4:6].
        bad_sn = "0000ZZ00ABCD1234000000000000000A"
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.return_value = True
        mock_cloud_instance.list_appliances.return_value = {}
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = bad_sn
            # Must not raise a ValueError from bytes.fromhex.
            await self.cli.download()

        mock_cloud_instance.download_lua.assert_called_once_with(
            str(Path()),
            0,
            bad_sn,
            bad_sn[9:17],
            "0000",
        )

    async def test_download_by_sn_short_serial(self) -> None:
        """A --device-sn shorter than a type-1 serial defaults to type 0."""
        short_sn = "SHORTSN"
        mock_cloud_instance = AsyncMock()
        mock_cloud_instance.login.return_value = True
        mock_cloud_instance.list_appliances.return_value = {}
        with patch.object(self.cli, "_get_cloud", return_value=mock_cloud_instance):
            self.namespace.host = None
            self.namespace.device_sn = short_sn
            await self.cli.download()

        mock_cloud_instance.download_lua.assert_called_once_with(
            str(Path()),
            0,
            short_sn,
            short_sn[9:17],
            "0000",
        )

    async def test_set_attribute(self) -> None:
        """Test set attribute."""
        mock_device_instance = MagicMock()
        mock_device_instance.connect.return_value = True
        with (
            patch.object(
                self.cli,
                "discover",
                side_effect=[
                    [],
                    [mock_device_instance],
                    [mock_device_instance],
                    [mock_device_instance],
                ],
            ),
        ):
            await self.cli.set_attribute()
            mock_device_instance.set_attribute.assert_not_called()

            await self.cli.set_attribute()
            mock_device_instance.set_attribute.assert_called_once_with("power", False)
            mock_device_instance.reset_mock()

            self.namespace.attribute = "mode"
            self.namespace.value = "2"
            self.namespace.attr_type = "int"

            await self.cli.set_attribute()
            mock_device_instance.set_attribute.assert_called_once_with("mode", 2)
            mock_device_instance.reset_mock()

            self.namespace.attribute = "attr"
            self.namespace.value = "string"
            self.namespace.attr_type = "str"

            await self.cli.set_attribute()
            mock_device_instance.set_attribute.assert_called_once_with("attr", "string")

    def test_run(self) -> None:
        """Test run."""
        mock_logger = MagicMock()
        with (
            patch("logging.basicConfig") as mock_basic_config,
            patch("logging.getLogger", return_value=mock_logger),
            patch.object(mock_logger, "setLevel") as mock_set_level,
        ):
            self.cli.session = AsyncMock()
            self.cli.run(self.namespace)
            mock_basic_config.assert_called_once_with(level=logging.DEBUG)
            mock_basic_config.reset_mock()
            mock_set_level.assert_called_with(logging.INFO)
            mock_set_level.reset_mock()
            self.namespace.func.assert_called_once()

            # Test coroutine function
            self.namespace.func = AsyncMock()
            self.namespace.debug = False
            self.cli.run(self.namespace)
            mock_basic_config.assert_called_once_with(level=logging.INFO)
            mock_set_level.assert_called_with(logging.WARNING)
            self.namespace.func.assert_called_once()

    def test_run_log_file(self) -> None:
        """Test run also writes logs to a file when --log-file is set."""
        mock_logger = MagicMock()
        mock_file_handler = MagicMock()
        with TemporaryDirectory() as tmpdir:
            log_file = str(Path(tmpdir) / "midea-local-test.log")
            with (
                patch("logging.basicConfig"),
                patch("logging.getLogger", return_value=mock_logger),
                patch(
                    "logging.FileHandler",
                    return_value=mock_file_handler,
                ) as mock_file_handler_cls,
            ):
                self.cli.session = AsyncMock()
                self.namespace.log_file = log_file
                self.cli.run(self.namespace)

        mock_file_handler_cls.assert_called_once_with(
            log_file,
            mode="w",
            encoding="utf-8",
        )
        mock_file_handler.setFormatter.assert_called_once()
        mock_logger.addHandler.assert_called_once_with(mock_file_handler)

    def test_main_call(self) -> None:
        """Test main call."""
        # Command to run the script
        cmd = [
            sys.executable,
            "-m",
            "midealocal.cli",
        ]
        clear_config = False
        if not get_config_file_path().exists():
            clear_config = True
            subprocess.run([*cmd, "save"], capture_output=True, text=True, check=False)  # noqa: S603

        # Run the command and capture the output
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)  # noqa: S603

        # Check if the script executed without errors
        assert result.returncode == 2

        result = subprocess.run(  # noqa: S603
            [*cmd, "save"],
            capture_output=True,
            text=True,
            check=False,
        )

        assert result.returncode == 0

        if clear_config:
            get_config_file_path().unlink()

    def test_main(self) -> None:
        """Test main entry parses args and merges config file values."""
        with TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "midea-local.json"
            config_file.write_text(
                json.dumps({"username": "configuser", "password": "configpass"}),
                encoding="utf-8",
            )
            exit_code: int | str | None = None
            with (
                patch.object(sys, "argv", ["midealocal", "discover", "-p", "argpass"]),
                patch(
                    "midealocal.cli.get_config_file_path",
                    return_value=config_file,
                ),
                patch.object(MideaCLI, "run") as mock_run,
            ):
                try:
                    main()
                except SystemExit as exc:
                    exit_code = exc.code

            assert exit_code == 0
            mock_run.assert_called_once()
            namespace = mock_run.call_args[0][0]
            # username not passed on command line: filled from the config file
            assert namespace.username == "configuser"
            # password passed on command line: config value is not applied
            assert namespace.password == "argpass"
            assert namespace.func.__name__ == "discover"

    def test_main_module_entry(self) -> None:
        """Test the __main__ guard when running the module as a script."""
        with (
            patch.object(sys, "argv", ["midealocal.cli", "--version"]),
            warnings.catch_warnings(),
        ):
            # runpy warns when re-executing an already imported module
            warnings.simplefilter("ignore", RuntimeWarning)
            with pytest.raises(SystemExit) as exit_info:
                runpy.run_module("midealocal.cli", run_name="__main__")

        assert exit_info.value.code == 0

    def test_get_config_file_path(self) -> None:
        """Test get config file path."""
        mock_path = MagicMock()
        with (
            patch("midealocal.cli.Path", return_value=mock_path),
            patch.object(mock_path, "exists", return_value=False),
        ):
            get_config_file_path()

    def test_get_devices_cache_path(self) -> None:
        """Test get devices cache path."""
        assert get_devices_cache_path() == Path("midea-devices.json")
