"""Test EC Device."""

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.devices.ec import DeviceAttributes, MideaECDevice
from midealocal.devices.ec.message import MessageECBase, MessageQuery
from midealocal.message import ListTypes, MessageType


class TestMideaECDevice:
    """Test Midea EC Device."""

    device: MideaECDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea EC Device setup."""
        self.device = MideaECDevice(
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
        assert self.device.attributes[DeviceAttributes.cooking] is False
        assert self.device.attributes[DeviceAttributes.mode] == 0
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.keep_warm_time] is None
        assert self.device.attributes[DeviceAttributes.top_temperature] is None
        assert self.device.attributes[DeviceAttributes.bottom_temperature] is None
        assert self.device.attributes[DeviceAttributes.progress] == "Unknown"
        assert self.device.attributes[DeviceAttributes.with_pressure] is None

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    @pytest.mark.parametrize(
        ("message_type", "sub_body_type"),
        [
            (MessageType.set, 0x02),
            (MessageType.query, 0x03),
            (MessageType.notify1, 0x04),
            (MessageType.notify1, 0x3D),
        ],
    )
    def test_general_response(
        self,
        message_type: MessageType,
        sub_body_type: int,
    ) -> None:
        """Test general response with known mode and progress."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.EC] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([message_type])
        body = bytearray(24)
        body[3] = sub_body_type
        body[4] = 0x02  # mode low byte -> cook_rice
        body[5] = 0x00  # mode high byte
        body[8] = 0x03  # progress -> Keep-warm
        body[12] = 0x01  # time remaining minutes
        body[13] = 0x1E  # time remaining seconds
        body[16] = 0x00  # keep warm minutes
        body[17] = 0x2D  # keep warm seconds
        body[21] = 0x32  # top temperature
        body[22] = 0x3C  # bottom temperature
        body[23] = 0x04  # with pressure
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.cooking] is False
        assert self.device.attributes[DeviceAttributes.mode] == "cook_rice"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 90
        assert self.device.attributes[DeviceAttributes.keep_warm_time] == 45
        assert self.device.attributes[DeviceAttributes.top_temperature] == 50
        assert self.device.attributes[DeviceAttributes.bottom_temperature] == 60
        assert self.device.attributes[DeviceAttributes.progress] == "Keep-warm"
        assert self.device.attributes[DeviceAttributes.with_pressure] is True
        assert result[DeviceAttributes.progress.value] == "Keep-warm"

    def test_general_response_unknown_mode_and_progress(self) -> None:
        """Test general response with cloud mode and unknown progress."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.EC] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(24)
        body[3] = 0x03  # sub body type
        body[4] = 0xF4  # mode low byte
        body[5] = 0x01  # mode high byte -> 500, out of list -> Cloud
        body[8] = 0x20  # progress out of list -> Unknown
        self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.cooking] is False
        assert self.device.attributes[DeviceAttributes.mode] == "Cloud"
        assert self.device.attributes[DeviceAttributes.progress] == "Unknown"
        assert self.device.attributes[DeviceAttributes.with_pressure] is False

    def test_notify_response_new_body(self) -> None:
        """Test notify1 response with new body."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.EC] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(50)
        body[3] = 0x01  # sub body type
        body[11] = 0x01  # progress -> Cooking
        body[16] = 0x02  # time remaining minutes
        body[17] = 0x1E  # time remaining seconds
        body[19] = 0x01  # keep warm minutes
        body[20] = 0x0A  # keep warm seconds
        body[33] = 0x01  # with pressure
        body[48] = 0x5F  # top temperature
        body[49] = 0x62  # bottom temperature
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.cooking] is True
        assert self.device.attributes[DeviceAttributes.time_remaining] == 150
        assert self.device.attributes[DeviceAttributes.keep_warm_time] == 70
        assert self.device.attributes[DeviceAttributes.top_temperature] == 95
        assert self.device.attributes[DeviceAttributes.bottom_temperature] == 98
        assert self.device.attributes[DeviceAttributes.progress] == "Cooking"
        assert self.device.attributes[DeviceAttributes.with_pressure] is True
        assert result[DeviceAttributes.cooking.value] is True

    def test_notify_response_mode_only(self) -> None:
        """Test notify1 response with mode-only body."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.EC] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.notify1])
        body = bytearray(6)
        body[3] = 0x06  # sub body type
        body[4] = 0xC7  # mode low byte -> 199 -> diy
        body[5] = 0x00  # mode high byte
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert self.device.attributes[DeviceAttributes.mode] == "diy"
        assert result == {DeviceAttributes.mode.value: "diy"}

    def test_unexpected_response(self) -> None:
        """Test unexpected sub body type updates nothing."""
        header = bytearray(
            [0xAA, 0x00, DeviceType.EC] + [0x00] * 5 + [ProtocolVersion.V1],
        ) + bytearray([MessageType.query])
        body = bytearray(24)
        body[3] = 0x05  # unexpected sub body type
        result = self.device.process_message(bytes(header + body + bytearray(1)))
        assert result == {}


class TestMessageECBase:
    """Test EC Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageECBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test EC Message Query."""

    def test_query_body(self) -> None:
        """Test query body override and internal body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray(
            [0xAA, 0x55, 0x01, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
        )
        assert msg._body == bytearray([])
