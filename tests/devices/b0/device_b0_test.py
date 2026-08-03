"""Test B0 Device."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.b0 import DeviceAttributes, MideaB0Device
from midealocal.devices.b0.message import (
    MessageQuery00,
    MessageQuery01,
    MessageQuery31,
)
from midealocal.message import MessageType


def _build_device(subtype: int) -> MideaB0Device:
    """Build a Midea B0 device with the given subtype."""
    return MideaB0Device(
        name="Test Device",
        device_id=1,
        ip_address="192.168.1.1",
        port=12345,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V1,
        model="test_model",
        subtype=subtype,
        customize="",
    )


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full B0 response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMideaB0Device:
    """Test Midea B0 Device."""

    device: MideaB0Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea B0 Device setup."""
        self.device = _build_device(1)

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.fire_power] is None
        assert self.device.attributes[DeviceAttributes.child_lock] is False

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 3
        assert isinstance(queries[0], MessageQuery00)
        assert isinstance(queries[1], MessageQuery01)
        assert isinstance(queries[2], MessageQuery31)

    def test_process_message_31(self) -> None:
        """Test process message with a 31 body on a subtype above zero."""
        body = bytearray(18)
        body[0] = 0x31
        body[1] = 0x03  # status "Working"
        body[6] = 0  # hours
        body[7] = 1  # minutes
        body[8] = 30  # seconds
        body[9] = 0x01  # mode "Microwave"
        body[11] = 80  # temperature above
        body[14] = 0x05  # fire power "Medium"
        body[15] = 0xFF  # weight
        body[16] = 0x4B  # child lock, door, water shortage, preheat end
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.door] is True
        assert self.device.attributes[DeviceAttributes.status] == "Working"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 90
        assert self.device.attributes[DeviceAttributes.current_temperature] == 80
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is True
        assert self.device.attributes[DeviceAttributes.mode] == "Microwave"
        assert self.device.attributes[DeviceAttributes.fire_power] == "Medium"
        assert self.device.attributes[DeviceAttributes.child_lock] is True
        assert new_status[DeviceAttributes.status.value] == "Working"

    def test_process_message_31_time_unfreeze(self) -> None:
        """Test process message with the time defrost mode on a 31 body."""
        body = bytearray(18)
        body[0] = 0x31
        body[1] = 0x03  # status "Working"
        body[6] = 0  # hours
        body[7] = 1  # minutes
        body[8] = 0  # seconds
        body[9] = 0xA1  # mode "Time Unfreeze"
        body[14] = 0x03  # fire power "Medium Low"
        self.device.process_message(_build_message(MessageType.query, body))
        assert self.device.attributes[DeviceAttributes.status] == "Working"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 60
        assert self.device.attributes[DeviceAttributes.mode] == "Time Unfreeze"
        assert self.device.attributes[DeviceAttributes.fire_power] == "Medium Low"

    def test_process_message_41(self) -> None:
        """Test process message with a 41 body variant."""
        body = bytearray(18)
        body[0] = 0x41
        body[1] = 0x04  # status "Finished"
        body[6] = 0xFF  # hours unset
        body[7] = 0xFF  # minutes unset
        body[8] = 0xFF  # seconds unset
        body[9] = 0xE0  # mode "Auto"
        body[11] = 0  # no temperature above
        body[13] = 60  # temperature under
        body[14] = 0x0A  # fire power "High"
        body[15] = 10  # weight
        body[16] = 0x20  # preheat working
        self.device.process_message(_build_message(MessageType.notify1, body))
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] == "Finished"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 60
        assert self.device.attributes[DeviceAttributes.mode] == "Auto"
        assert self.device.attributes[DeviceAttributes.fire_power] == "High"
        assert self.device.attributes[DeviceAttributes.child_lock] is False

    def test_process_message_01_subtype_zero(self) -> None:
        """Test process message with a 01 body on subtype zero."""
        device = _build_device(0)
        body = bytearray(34)
        body[0] = 0x01
        body[22] = 1  # hours
        body[23] = 1  # minutes
        body[24] = 0xFF  # seconds unset
        body[27] = 0x01  # temperature fallback high byte
        body[28] = 44  # temperature fallback low byte
        body[31] = 0x02  # status "Working"
        body[32] = 0x12  # door and water change reminder
        new_status = device.process_message(_build_message(MessageType.query, body))
        assert device.attributes[DeviceAttributes.door] is True
        assert device.attributes[DeviceAttributes.status] == "Working"
        assert device.attributes[DeviceAttributes.time_remaining] == 3660
        assert device.attributes[DeviceAttributes.current_temperature] == 300
        assert device.attributes[DeviceAttributes.tank_ejected] is False
        assert device.attributes[DeviceAttributes.water_shortage] is False
        assert device.attributes[DeviceAttributes.water_change_reminder] is True
        assert device.attributes[DeviceAttributes.mode] is None
        assert new_status[DeviceAttributes.door.value] is True

    def test_process_message_default_body_subtype_zero(self) -> None:
        """Test process message with the default body on subtype zero."""
        device = _build_device(0)
        body = bytearray(17)
        body[0] = 0x82  # unhandled body type with the door bit set
        body[1] = 0x02  # mode "Baking"
        body[2] = 1  # minutes
        body[3] = 30  # seconds
        body[14] = 5  # raw fire power
        device.process_message(_build_message(MessageType.set, body))
        assert device.attributes[DeviceAttributes.door] is True
        assert device.attributes[DeviceAttributes.status] == "Working"
        assert device.attributes[DeviceAttributes.time_remaining] == 90
        assert device.attributes[DeviceAttributes.mode] == "Baking"
        assert device.attributes[DeviceAttributes.fire_power] == 5

    def test_process_message_04_body(self) -> None:
        """Test process message with a 04 body updates nothing."""
        body = bytearray(18)
        body[0] = 0x04
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert new_status == {}

    def test_process_message_short_body(self) -> None:
        """Test process message with a too short body updates nothing."""
        body = bytearray(12)
        body[0] = 0x01
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert new_status == {}

    def test_set_attribute(self) -> None:
        """Test set attribute is a no-op."""
        self.device.set_attribute(DeviceAttributes.child_lock.value, True)
        assert self.device.attributes[DeviceAttributes.child_lock] is False
