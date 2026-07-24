"""Test B1 Device."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.b1 import DeviceAttributes, MideaB1Device
from midealocal.devices.b1.message import MessageB1Base, MessageQuery
from midealocal.message import ListTypes, MessageType


class TestMideaB1Device:
    """Test Midea B1 Device."""

    device: MideaB1Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea B1 Device setup."""
        self.device = MideaB1Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize="",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_set_attribute(self) -> None:
        """Test set attribute is a no-op."""
        self.device.set_attribute(DeviceAttributes.door.value, True)
        assert self.device.attributes[DeviceAttributes.door] is False

    def test_query_response(self) -> None:
        """Test query response with valid status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(20)
        body[1] = 0x03  # status -> Working
        body[6] = 0x01  # hours
        body[7] = 0x02  # minutes
        body[8] = 0x03  # seconds
        body[16] = 0x1E  # door + tank_ejected + water_shortage + change_reminder
        body[19] = 0x32  # current_temperature
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is True
        assert self.device.attributes[DeviceAttributes.status] == "Working"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 3723
        assert self.device.attributes[DeviceAttributes.current_temperature] == 50
        assert self.device.attributes[DeviceAttributes.tank_ejected] is True
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is True
        assert self.device.attributes[DeviceAttributes.water_shortage] is True
        assert result[DeviceAttributes.status.value] == "Working"

    def test_notify_response_invalid_status(self) -> None:
        """Test notify1 response with unknown status and invalid times."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(20)
        body[1] = 0x99  # unknown status
        body[6] = 0xFF  # invalid hours
        body[7] = 0xFF  # invalid minutes
        body[8] = 0xFF  # invalid seconds
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 0
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False

    def test_unexpected_response(self) -> None:
        """Test unexpected message type updates nothing."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B1] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.set])
        body = bytearray(20)
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert result == {}


class TestMessageB1Base:
    """Test B1 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageB1Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test B1 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x00])
