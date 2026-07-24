"""Test E8 Device."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.e8 import DeviceAttributes, MideaE8Device
from midealocal.devices.e8.message import MessageE8Base, MessageQuery
from midealocal.message import ListTypes, MessageType


class TestMideaE8Device:
    """Test Midea E8 Device."""

    device: MideaE8Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea E8 Device setup."""
        self.device = MideaE8Device(
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
        assert self.device.attributes[DeviceAttributes.status] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.keep_warm_remaining] is None
        assert self.device.attributes[DeviceAttributes.working_time] is None
        assert self.device.attributes[DeviceAttributes.target_temperature] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.finished] is None
        assert self.device.attributes[DeviceAttributes.water_shortage] is None

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_set_attribute(self) -> None:
        """Test set attribute is a no-op."""
        self.device.set_attribute(DeviceAttributes.status.value, True)

    def test_query_response(self) -> None:
        """Test query response with valid status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.E8] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(44)
        body[0] = 0xAA  # body type
        body[6] = 0x02  # sub command
        body[11] = 0x02  # status -> Working
        body[16] = 0x01  # time remaining hours
        body[17] = 0x01  # time remaining minutes
        body[18] = 0x01  # time remaining seconds
        body[19] = 0x00  # keep warm hours
        body[20] = 0x01  # keep warm minutes
        body[21] = 0x1E  # keep warm seconds
        body[28] = 0x00  # working time hours
        body[29] = 0x02  # working time minutes
        body[30] = 0x05  # working time seconds
        body[39] = 0x3C  # target/current temperature
        body[41] = 0x01  # finished
        body[43] = 0x01  # water shortage
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.status] == "Working"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 3661
        assert self.device.attributes[DeviceAttributes.keep_warm_remaining] == 90
        assert self.device.attributes[DeviceAttributes.working_time] == 125
        assert self.device.attributes[DeviceAttributes.target_temperature] == 60
        assert self.device.attributes[DeviceAttributes.current_temperature] == 60
        assert self.device.attributes[DeviceAttributes.finished] is True
        assert self.device.attributes[DeviceAttributes.water_shortage] is True
        assert result[DeviceAttributes.status.value] == "Working"

    @pytest.mark.parametrize("sub_cmd", [0x02, 0x04, 0x06])
    def test_set_response(self, sub_cmd: int) -> None:
        """Test set response with error status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.E8] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.set])
        body = bytearray(44)
        body[0] = 0xAA  # body type
        body[6] = sub_cmd
        body[11] = 0xFF  # status -> Error
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.status] == "Error"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.keep_warm_remaining] == 0
        assert self.device.attributes[DeviceAttributes.working_time] == 0
        assert self.device.attributes[DeviceAttributes.finished] is False
        assert self.device.attributes[DeviceAttributes.water_shortage] is False

    def test_notify_response_unknown_status(self) -> None:
        """Test notify1 response with unknown status."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.E8] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(44)
        body[0] = 0xAA  # body type
        body[6] = 0x02  # sub command
        body[11] = 0x63  # unknown status
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.status] is None

    def test_unexpected_sub_command(self) -> None:
        """Test unexpected sub command updates nothing."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.E8] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(44)
        body[0] = 0xAA  # body type
        body[6] = 0x05  # unexpected sub command
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert result == {}

    def test_short_body_response(self) -> None:
        """Test short body response updates nothing."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.E8] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(6)
        body[0] = 0xAA  # body type
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert result == {}


class TestMessageE8Base:
    """Test E8 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageE8Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.AA,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test E8 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0xAA, 0x55, 0x00, 0x01, 0x00, 0x00])
