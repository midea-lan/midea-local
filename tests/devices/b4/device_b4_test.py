"""Test B4 Device."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.b4 import DeviceAttributes, MideaB4Device
from midealocal.devices.b4.message import MessageB4Base, MessageQuery
from midealocal.message import ListTypes, MessageType


class TestMideaB4Device:
    """Test Midea B4 Device."""

    device: MideaB4Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea B4 Device setup."""
        self.device = MideaB4Device(
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

    def test_query_response(self) -> None:
        """Test query response with valid status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B4] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(33)
        body[0] = 0x01  # body type
        body[16] = 0x1C  # tank_ejected + water_shortage + change_reminder
        body[22] = 0x01  # hours
        body[23] = 0x01  # minutes
        body[24] = 0x01  # seconds
        body[25] = 0x01  # temperature high byte
        body[26] = 0x2C  # temperature low byte -> 300
        body[31] = 0x04  # status -> Finished
        body[32] = 0x02  # door
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is True
        assert self.device.attributes[DeviceAttributes.status] == "Finished"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 3661
        assert self.device.attributes[DeviceAttributes.current_temperature] == 300
        assert self.device.attributes[DeviceAttributes.tank_ejected] is True
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is True
        assert self.device.attributes[DeviceAttributes.water_shortage] is True
        assert result[DeviceAttributes.status.value] == "Finished"

    def test_notify_response_fallback_temperature(self) -> None:
        """Test notify1 response with fallback temperature and unknown status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B4] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(33)
        body[0] = 0x01  # body type
        body[22] = 0xFF  # invalid hours
        body[23] = 0xFF  # invalid minutes
        body[24] = 0xFF  # invalid seconds
        body[27] = 0x00  # fallback temperature high byte
        body[28] = 0x64  # fallback temperature low byte -> 100
        body[31] = 0x99  # unknown status
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 100
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False

    def test_unexpected_response(self) -> None:
        """Test unexpected body type updates nothing."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.B4] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(33)
        body[0] = 0x02  # unexpected body type
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert result == {}


class TestMessageB4Base:
    """Test B4 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageB4Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test B4 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01])
