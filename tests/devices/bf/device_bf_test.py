"""Test BF Device."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.bf import DeviceAttributes, MideaBFDevice
from midealocal.devices.bf.message import MessageBFBase, MessageQuery, MessageSet
from midealocal.message import ListTypes, MessageType


class TestMideaBFDevice:
    """Test Midea BF Device."""

    device: MideaBFDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea BF Device setup."""
        self.device = MideaBFDevice(
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
        assert self.device.attributes[DeviceAttributes.door] is None
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.tank_ejected] is None
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is None
        assert self.device.attributes[DeviceAttributes.water_shortage] is None

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
            [0xAA, 0x00, DeviceType.BF] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(33)
        body[0] = 0x01  # body type
        body[22] = 0x01  # hours
        body[23] = 0x01  # minutes
        body[24] = 0x01  # seconds
        body[25] = 0x01  # temperature high byte
        body[26] = 0x2C  # temperature low byte -> 300
        body[31] = 0x03  # status -> Working
        body[32] = 0x16  # door + tank_ejected + change_reminder
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is True
        assert self.device.attributes[DeviceAttributes.status] == "working"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 3661
        assert self.device.attributes[DeviceAttributes.current_temperature] == 300
        assert self.device.attributes[DeviceAttributes.tank_ejected] is True
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is True
        assert self.device.attributes[DeviceAttributes.water_shortage] is False
        assert result[DeviceAttributes.status.value] == "working"

    def test_notify_response_fallback_temperature(self) -> None:
        """Test notify1 response with fallback temperature and unknown status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.BF] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(33)
        body[0] = 0x01  # body type
        body[22] = 0xFF  # invalid hours
        body[23] = 0xFF  # invalid minutes
        body[24] = 0xFF  # invalid seconds
        body[27] = 0x00  # fallback temperature high byte
        body[28] = 0x64  # fallback temperature low byte -> 100
        body[31] = 0x07  # unknown status
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.door] is False
        assert self.device.attributes[DeviceAttributes.status] == "unknown"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.current_temperature] == 100
        assert self.device.attributes[DeviceAttributes.tank_ejected] is False
        assert self.device.attributes[DeviceAttributes.water_change_reminder] is False

    def test_unexpected_response(self) -> None:
        """Test unexpected body type updates nothing."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.BF] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(33)
        body[0] = 0x02  # unexpected body type
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert result == {}


class TestMessageBFBase:
    """Test BF Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageBFBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test BF Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01])


class TestMessageSet:
    """Test BF Message Set."""

    @pytest.mark.parametrize(
        ("power", "child_lock", "power_byte", "child_lock_byte"),
        [
            (None, None, 0xFF, 0xFF),
            (True, True, 0x11, 0x01),
            (False, False, 0x01, 0x00),
        ],
    )
    def test_set_body(
        self,
        power: bool | None,
        child_lock: bool | None,
        power_byte: int,
        child_lock_byte: int,
    ) -> None:
        """Test set body."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = power
        msg.child_lock = child_lock
        expected_body = bytearray([0x02, power_byte, child_lock_byte] + [0xFF] * 7)
        assert msg.body == expected_body
