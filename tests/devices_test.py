"""Midea local device selector tests."""

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices import device_selector
from midealocal.devices.ac import MideaACDevice
from midealocal.devices.x13 import Midea13Device


class TestDeviceSelector:
    """Test device_selector."""

    def test_device_selector_high_type(self) -> None:
        """Test device_selector with a device type >= 0xA0."""
        device = device_selector(
            name="Test Device",
            device_id=1,
            device_type=DeviceType.AC,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="",
        )
        assert isinstance(device, MideaACDevice)

    def test_device_selector_low_type(self) -> None:
        """Test device_selector with a device type < 0xA0 (x-prefixed module)."""
        device = device_selector(
            name="Test Device",
            device_id=1,
            device_type=DeviceType.X13,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="",
            mac="1234567890ab",
        )
        assert isinstance(device, Midea13Device)

    def test_device_selector_unknown_type(self) -> None:
        """Test device_selector with an unknown device type."""
        device = device_selector(
            name="Test Device",
            device_id=1,
            device_type=DeviceType.X00,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="",
        )
        assert device is None
