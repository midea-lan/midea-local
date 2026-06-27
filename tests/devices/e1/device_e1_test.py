"""Test E1 device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e1 import DeviceAttributes, MideaE1Device
from midealocal.devices.e1.message import MessageQuery, MessageWork


class TestMideaE1Device:
    """Test E1 device."""

    device: MideaE1Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Set up E1 device."""
        self.device = MideaE1Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="test_customize",
        )

    def test_modes(self) -> None:
        """Test work modes are exposed without allowing mutation."""
        modes = self.device.modes
        assert modes[0x04] == "ECO Wash"
        modes[0x04] = "Changed"
        assert self.device.modes[0x04] == "ECO Wash"

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_set_work_mode(self) -> None:
        """Test setting a supported work mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_work_mode(0x04)

        message = mock_build_send.call_args.args[0]
        assert isinstance(message, MessageWork)
        assert message.mode == 0x04

    def test_set_work_mode_rejects_unknown_mode(self) -> None:
        """Test setting an unknown work mode."""
        with pytest.raises(ValueError, match="Unsupported work mode"):
            self.device.set_work_mode(0x11)

    def test_start_work(self) -> None:
        """Test starting the currently selected work mode."""
        self.device._attributes[DeviceAttributes.mode] = "ECO Wash"
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.start_work()

        message = mock_build_send.call_args.args[0]
        assert isinstance(message, MessageWork)
        assert message.mode == 0x04

    @pytest.mark.parametrize("mode", [None, 0, "Neutral Gear"])
    def test_start_work_requires_selected_mode(self, mode: str | int | None) -> None:
        """Test starting requires a non-neutral selected mode."""
        self.device._attributes[DeviceAttributes.mode] = mode
        with pytest.raises(ValueError, match="No work mode selected"):
            self.device.start_work()

    def test_start_work_rejects_invalid_mode_type(self) -> None:
        """Test starting rejects an invalid stored mode."""
        self.device._attributes[DeviceAttributes.mode] = 4
        with pytest.raises(TypeError, match="Invalid work mode"):
            self.device.start_work()
