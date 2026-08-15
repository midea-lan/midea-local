"""Test E1 device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e1 import DeviceAttributes, MideaE1Device
from midealocal.devices.e1.message import (
    MessageLock,
    MessagePower,
    MessageQuery,
    MessageStorage,
    MessageWork,
)
from midealocal.exceptions import ValueWrongType
from midealocal.message import MessageType


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
        assert modes[0x04] == "eco_wash"
        modes[0x04] = "changed"
        assert self.device.modes[0x04] == "eco_wash"

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
        with pytest.raises(ValueWrongType, match="Unsupported work mode"):
            self.device.set_work_mode(0x11)

    def test_start_work(self) -> None:
        """Test starting the currently selected work mode."""
        self.device._attributes[DeviceAttributes.mode] = "eco_wash"
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.start_work()

        message = mock_build_send.call_args.args[0]
        assert isinstance(message, MessageWork)
        assert message.mode == 0x04

    @pytest.mark.parametrize("mode", [None, 0, "neutral_gear"])
    def test_start_work_requires_selected_mode(self, mode: str | int | None) -> None:
        """Test starting requires a non-neutral selected mode."""
        self.device._attributes[DeviceAttributes.mode] = mode
        with pytest.raises(ValueWrongType, match="No work mode selected"):
            self.device.start_work()

    def test_start_work_rejects_invalid_mode_type(self) -> None:
        """Test starting rejects an invalid stored mode."""
        self.device._attributes[DeviceAttributes.mode] = 4
        with pytest.raises(ValueWrongType, match="Invalid work mode"):
            self.device.start_work()

    @staticmethod
    def _message(message_type: MessageType, body: bytearray) -> bytes:
        header = bytearray(
            [0xAA, *([0x00] * 7), ProtocolVersion.V1, message_type],
        )
        crc = bytearray([0x00])
        return bytes(header + body + crc)

    def test_process_message_maps_status_progress_and_mode(self) -> None:
        """Test process message maps status, progress and mode via lookup tables."""
        body = bytearray(40)
        body[1] = 0x03  # status running
        body[2] = 0x04  # mode eco_wash
        body[9] = 0x03  # progress rinse
        new_status = self.device.process_message(
            self._message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.status] == "running"
        assert self.device.attributes[DeviceAttributes.mode] == "eco_wash"
        assert self.device.attributes[DeviceAttributes.progress] == "rinse"
        assert new_status[DeviceAttributes.status.value] == "running"

    def test_process_message_unknown_status_mode_and_progress(self) -> None:
        """Test process message returns None for unmapped lookup values."""
        body = bytearray(40)
        body[1] = 0xFF  # unknown status
        body[2] = 0xFF  # unknown mode
        body[9] = 0xFF  # out-of-range progress
        self.device.process_message(self._message(MessageType.query, body))
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.progress] is None

    def test_process_message_unhandled_message_type(self) -> None:
        """Test process message ignores unhandled message/body type combinations."""
        body = bytearray(40)
        new_status = self.device.process_message(
            self._message(MessageType.notify2, body),
        )
        assert new_status == {}

    def test_set_attribute_rejects_non_bool(self) -> None:
        """Test set attribute rejects non-bool values."""
        with pytest.raises(ValueWrongType, match="Expected bool"):
            self.device.set_attribute(DeviceAttributes.power.value, "on")

    def test_set_attribute_power(self) -> None:
        """Test set attribute power sends a power message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
        message = mock_build_send.call_args.args[0]
        assert isinstance(message, MessagePower)
        assert message.power is True

    def test_set_attribute_child_lock(self) -> None:
        """Test set attribute child lock sends a lock message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.child_lock.value, True)
        message = mock_build_send.call_args.args[0]
        assert isinstance(message, MessageLock)
        assert message.lock is True

    def test_set_attribute_storage(self) -> None:
        """Test set attribute storage sends a storage message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.storage.value, True)
        message = mock_build_send.call_args.args[0]
        assert isinstance(message, MessageStorage)
        assert message.storage is True

    def test_set_attribute_unknown_attribute_is_noop(self) -> None:
        """Test set attribute with an unsupported attribute sends nothing."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, True)
        mock_build_send.assert_not_called()
