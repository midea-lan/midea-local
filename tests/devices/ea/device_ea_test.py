"""Test EA Device."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ea import DeviceAttributes, MideaEADevice
from midealocal.devices.ea.message import MessageQuery
from midealocal.message import MessageType

PROTOCOL_NONE = 0x00


class TestMideaEADevice:
    """Test Midea EA Device."""

    device: MideaEADevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea EA Device setup."""
        self.device = MideaEADevice(
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
        assert self.device.attributes[DeviceAttributes.keep_warm] is False
        assert self.device.attributes[DeviceAttributes.mode] == 0
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.keep_warm_time] is None
        assert self.device.attributes[DeviceAttributes.top_temperature] is None
        assert self.device.attributes[DeviceAttributes.bottom_temperature] is None
        assert self.device.attributes[DeviceAttributes.progress] == "unknown"

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_set_attribute_noop(self) -> None:
        """Test set attribute is a no-op for this device."""
        self.device.set_attribute(DeviceAttributes.mode.value, 1)

    def test_process_message_body1_set(self) -> None:
        """Test process message with a V0 set message parses EABody1."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [PROTOCOL_NONE] + [MessageType.set],
        )
        body = bytearray(30)
        body[5] = 0x16  # EABody1 marker
        body[6] = 2  # mode low byte -> cook_rice
        body[14] = 2  # progress Cooking
        body[18] = 90  # top temperature
        body[19] = 85  # bottom temperature
        body[22] = 1  # time remaining hours
        body[23] = 30  # time remaining minutes
        body[26] = 0  # keep warm time hours
        body[27] = 45  # keep warm time minutes
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.cooking] is True
        assert self.device.attributes[DeviceAttributes.keep_warm] is False
        assert self.device.attributes[DeviceAttributes.mode] == "cook_rice"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 90
        assert self.device.attributes[DeviceAttributes.keep_warm_time] == 45
        assert self.device.attributes[DeviceAttributes.top_temperature] == 90
        assert self.device.attributes[DeviceAttributes.bottom_temperature] == 85
        assert self.device.attributes[DeviceAttributes.progress] == "cooking"
        assert new_status[DeviceAttributes.cooking.value] is True

    def test_process_message_body2_query(self) -> None:
        """Test process message with a V0 query message parses EABody2."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [PROTOCOL_NONE] + [MessageType.query],
        )
        body = bytearray(62)
        body[6] = 0x52  # EABody2 marker
        body[7] = 0xC3  # EABody2 marker
        body[9] = 3  # progress Keep-warm
        body[20] = 60  # bottom temperature
        body[21] = 70  # top temperature
        body[50] = 2  # time remaining hours
        body[51] = 0  # time remaining minutes
        body[54] = 1  # keep warm time hours
        body[55] = 5  # keep warm time minutes
        body[58] = 3  # mode low byte -> fast_cook_rice
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.cooking] is False
        assert self.device.attributes[DeviceAttributes.keep_warm] is True
        assert self.device.attributes[DeviceAttributes.mode] == "fast_cook_rice"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 120
        assert self.device.attributes[DeviceAttributes.keep_warm_time] == 65
        assert self.device.attributes[DeviceAttributes.top_temperature] == 70
        assert self.device.attributes[DeviceAttributes.bottom_temperature] == 60
        assert self.device.attributes[DeviceAttributes.progress] == "keep_warm"

    def test_process_message_body1_query(self) -> None:
        """Test process message with a V0 query message parses EABody1."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [PROTOCOL_NONE] + [MessageType.query],
        )
        body = bytearray(30)
        body[5] = 0x3D  # EABody1 marker
        body[6] = 1  # mode low byte -> reserve
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.cooking] is False
        assert self.device.attributes[DeviceAttributes.keep_warm] is False
        assert self.device.attributes[DeviceAttributes.mode] == "reserve"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 0
        assert self.device.attributes[DeviceAttributes.keep_warm_time] == 0
        assert self.device.attributes[DeviceAttributes.top_temperature] == 0
        assert self.device.attributes[DeviceAttributes.bottom_temperature] == 0
        assert self.device.attributes[DeviceAttributes.progress] == "idle"

    def test_process_message_body1_notify(self) -> None:
        """Test process message with a V0 notify1 message parses EABody1."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [PROTOCOL_NONE] + [MessageType.notify1],
        )
        body = bytearray(30)
        body[5] = 0x3D  # EABody1 marker
        body[14] = 4  # progress out of range
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.mode] == "smart"
        assert self.device.attributes[DeviceAttributes.progress] == "unknown"

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.set, 0x02),
            (MessageType.query, 0x03),
            (MessageType.notify1, 0x04),
        ],
    )
    def test_process_message_body3(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test process message with a V1 message parses EABody3."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(26)
        body[3] = body_type
        body[4] = 3  # mode low byte -> fast_cook_rice
        body[8] = 2  # progress Cooking
        body[12] = 1  # time remaining hours
        body[13] = 10  # time remaining minutes
        body[20] = 95  # top temperature
        body[21] = 88  # bottom temperature
        body[22] = 0  # keep warm time hours
        body[23] = 30  # keep warm time minutes
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.cooking] is True
        assert self.device.attributes[DeviceAttributes.keep_warm] is False
        assert self.device.attributes[DeviceAttributes.mode] == "fast_cook_rice"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 70
        assert self.device.attributes[DeviceAttributes.keep_warm_time] == 30
        assert self.device.attributes[DeviceAttributes.top_temperature] == 95
        assert self.device.attributes[DeviceAttributes.bottom_temperature] == 88
        assert self.device.attributes[DeviceAttributes.progress] == "cooking"

    def test_process_message_body3_cloud_mode(self) -> None:
        """Test process message maps out-of-range mode and progress values."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.query],
        )
        body = bytearray(26)
        body[3] = 0x03
        body[4] = 44  # mode low byte
        body[5] = 1  # mode high byte -> 300, out of range
        body[8] = 9  # progress out of range
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.mode] == "cloud"
        assert self.device.attributes[DeviceAttributes.progress] == "unknown"

    @pytest.mark.parametrize("sub_type", [2, 4, 6, 8, 10, 0x62])
    def test_process_message_new_body(self, sub_type: int) -> None:
        """Test process message with a notify1 message parses EABodyNew."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(64)
        body[3] = 0x01  # EABodyNew marker
        body[6] = sub_type
        body[7] = 1  # mode low byte -> reserve
        body[11] = 2  # progress Cooking
        body[16] = 1  # time remaining hours
        body[17] = 0  # time remaining minutes
        body[19] = 0  # keep warm time hours
        body[20] = 50  # keep warm time minutes
        body[60] = 99  # top temperature
        body[61] = 77  # bottom temperature
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.cooking] is True
        assert self.device.attributes[DeviceAttributes.keep_warm] is False
        assert self.device.attributes[DeviceAttributes.mode] == "reserve"
        assert self.device.attributes[DeviceAttributes.time_remaining] == 60
        assert self.device.attributes[DeviceAttributes.keep_warm_time] == 50
        assert self.device.attributes[DeviceAttributes.top_temperature] == 99
        assert self.device.attributes[DeviceAttributes.bottom_temperature] == 77
        assert self.device.attributes[DeviceAttributes.progress] == "cooking"

    def test_process_message_new_body_unknown_subtype(self) -> None:
        """Test process message with an unknown EABodyNew subtype updates nothing."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(64)
        body[3] = 0x01  # EABodyNew marker
        body[6] = 0  # unknown subtype
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {}

    def test_process_message_mode_only(self) -> None:
        """Test process message with a notify1 X06 message updates only mode."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(8)
        body[3] = 0x06  # mode-only marker
        body[4] = 2  # mode low byte -> cook_rice
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {DeviceAttributes.mode.value: "cook_rice"}
        assert self.device.attributes[DeviceAttributes.mode] == "cook_rice"
        assert self.device.attributes[DeviceAttributes.progress] == "unknown"

    @pytest.mark.parametrize(
        ("protocol", "message_type"),
        [
            (PROTOCOL_NONE, MessageType.set),
            (PROTOCOL_NONE, MessageType.query),
            (PROTOCOL_NONE, MessageType.notify2),
            (ProtocolVersion.V1, MessageType.set),
            (ProtocolVersion.V1, MessageType.notify2),
        ],
    )
    def test_process_message_unhandled(
        self,
        protocol: int,
        message_type: MessageType,
    ) -> None:
        """Test process message with an unhandled message updates nothing."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [protocol] + [message_type],
        )
        body = bytearray(64)
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {}
