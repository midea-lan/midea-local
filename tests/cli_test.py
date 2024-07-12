"""Midea Local CLI tests."""

import json
import logging
import subprocess  # noqa: S404
import sys
from argparse import Namespace
from pathlib import Path
from unittest import IsolatedAsyncioTestCase
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from midealocal.cli import (
    ElementMissing,
    MideaCLI,
    get_config_file_path,
)
from midealocal.cloud import MSmartHomeCloud
from midealocal.device import ProtocolVersion


class TestMideaCLI(IsolatedAsyncioTestCase):
    """Test Midea CLI."""

    def setUp(self) -> None:
        """Create namespace for testing."""
        self.cli = MideaCLI()
        self.namespace = Namespace(
            cloud_name="MSmartHome",
            username="user",
            password="pass",
            host="192.168.0.1",
            message=bytes.fromhex("00a1a2ac0f2a0000"),
            device_type=bytearray(),
            device_sn="",
            user=False,
            debug=True,
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

        assert isinstance(cloud, MSmartHomeCloud)
        assert cloud._account == self.namespace.username
        assert cloud._password == self.namespace.password
        assert cloud._session == mock_session_instance

        self.namespace.cloud_name = None
        with pytest.raises(ElementMissing):
            await self.cli._get_cloud()

    async def test_discover(self) -> None:
        """Test discover."""
        mock_device = {
            "device_id": 1,
            "protocol": ProtocolVersion.V3,
            "type": "AC",
            "ip_address": "192.168.0.2",
            "port": 6444,
            "model": "AC123",
            "sn": "AC123",
        }
        mock_cloud_instance = AsyncMock()
        mock_device_instance = MagicMock()
        mock_device_instance.connect.return_value = True
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
        ):
            mock_discover.return_value = {1: mock_device}
            mock_cloud_instance.get_cloud_keys.return_value = {
                0: {"token": "token", "key": "key"},
            }
            mock_cloud_instance.get_default_keys.return_value = {
                99: {"token": "token", "key": "key"},
            }

            await self.cli.discover()  # V3 device

            mock_device["protocol"] = ProtocolVersion.V2
            await self.cli.discover()  # V2 device

            mock_device_instance.connect.return_value = False
            await self.cli.discover()  # connect failed

            mock_discover.return_value = {}

            await self.cli.discover()  # No devices

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
                protocol=ProtocolVersion.V2,
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

    async def test_download(self) -> None:
        """Test download."""
        mock_device = {
            "device_id": 1,
            "protocol": ProtocolVersion.V3,
            "type": 0xAC,
            "ip_address": "192.168.0.2",
            "port": 6444,
            "model": "AC123",
            "sn": "AC123",
        }
        mock_cloud_instance = AsyncMock()
        with (
            patch(
                "midealocal.cli.discover",
                side_effect=[{}, {1: mock_device}, {1: mock_device}],
            ) as mock_discover,
            patch.object(
                self.cli,
                "_get_cloud",
                return_value=mock_cloud_instance,
            ),
        ):
            await self.cli.download()  # No device found
            mock_discover.assert_called_once_with(ip_address=self.namespace.host)
            mock_discover.reset_mock()

            mock_cloud_instance.login.side_effect = [False, True]
            await self.cli.download()  # Cloud login failed
            mock_discover.assert_called_once_with(ip_address=self.namespace.host)
            mock_discover.reset_mock()
            mock_cloud_instance.login.assert_called_once()
            mock_cloud_instance.login.reset_mock()

            await self.cli.download()
            mock_discover.assert_called_once_with(ip_address=self.namespace.host)
            mock_cloud_instance.login.assert_called_once()
            mock_cloud_instance.download_lua.assert_called_once_with(
                str(Path()),
                mock_device["type"],
                mock_device["sn"],
                mock_device["model"],
            )

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

    def test_get_config_file_path(self) -> None:
        """Test get config file path."""
        mock_path = MagicMock()
        with (
            patch("midealocal.cli.Path", return_value=mock_path),
            patch.object(mock_path, "exists", return_value=False),
        ):
            get_config_file_path()
