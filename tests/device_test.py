"""Midea Local device test."""

from unittest import IsolatedAsyncioTestCase
from unittest.mock import MagicMock, patch

import pytest

from midealocal.cloud import default_keys
from midealocal.device import (
    AuthException,
    CapabilitiesFailed,
    MideaDevice,
    RefreshFailed,
)
from midealocal.exceptions import SocketException


class MideaDeviceTest(IsolatedAsyncioTestCase):
    """Midea device test case."""

    device: MideaDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea A1 Device setup."""
        self.device = MideaDevice(
            name="Test Device",
            device_id=1,
            device_type=0xAC,
            ip_address="192.168.1.100",
            port=6444,
            token=default_keys[99]["token"],
            key=default_keys[99]["key"],
            protocol=3,
            model="test_model",
            subtype=1,
            attributes={},
        )
        self.device.close()

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert len(self.device.attributes) == 0
        assert self.device.name == "Test Device"
        assert self.device.device_id == 1
        assert self.device.device_type == 0xAC
        assert self.device.model == "test_model"
        assert self.device.subtype == 1

    def test_connect(self) -> None:
        """Test connect."""
        with (
            patch("socket.socket.connect") as connect_mock,
            patch.object(
                self.device,
                "authenticate",
                side_effect=[AuthException(), None, None, None],
            ),
            patch.object(
                self.device,
                "refresh_status",
                side_effect=[RefreshFailed(), None, None],
            ),
            patch.object(
                self.device,
                "get_capabilities",
                side_effect=[CapabilitiesFailed(), None],
            ),
        ):
            connect_mock.side_effect = [
                TimeoutError(),
                OSError(),
                None,
                None,
                None,
                None,
            ]
            assert self.device.connect(True, True) is False
            assert self.device.available is False

            assert self.device.connect(True, True) is False
            assert self.device.available is False

            assert self.device.connect(True, True) is False
            assert self.device.available is False

            assert self.device.connect(True, True) is False
            assert self.device.available is False

            assert self.device.connect(True, True) is False
            assert self.device.available is False

            assert self.device.connect(True, True) is True
            assert self.device.available is True

    def test_authenticate(self) -> None:
        """Test authenticate."""
        socket_mock = MagicMock()
        with patch.object(
            socket_mock,
            "recv",
            side_effect=[
                bytearray(),
                bytearray(
                    [0x00] * (8 + 32)
                    + [
                        0xCE,
                        0x8C,
                        0xFB,
                        0xF1,
                        0x65,
                        0x90,
                        0xD1,
                        0x07,
                        0x6D,
                        0xF8,
                        0x3A,
                        0x3B,
                        0x67,
                        0xCC,
                        0x6B,
                        0xB6,
                        0x80,
                        0xF6,
                        0x0E,
                        0x3D,
                        0xFF,
                        0xE7,
                        0x74,
                        0x92,
                        0x14,
                        0x4D,
                        0xE9,
                        0xD2,
                        0xD5,
                        0x74,
                        0x7E,
                        0x6F,
                    ],
                ),
            ],
        ):
            self.device._socket = None
            with pytest.raises(SocketException):
                self.device.authenticate()

            self.device._socket = socket_mock
            with pytest.raises(AuthException):
                self.device.authenticate()

            self.device.authenticate()
