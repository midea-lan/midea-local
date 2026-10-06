"""Test CA support for Toshiba IoLIFE refrigerators (55 AA CC 33 frame).

The frames below were captured from a Toshiba GR-Y540XFS.
"""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ca import DeviceAttributes, MideaCADevice
from midealocal.devices.ca.message import (
    MessageQuery,
    MessageToshibaCAResponse,
    MessageToshibaQuery,
    extract_toshiba_frame,
    toshiba_crc16,
    toshiba_frame_header,
)
from midealocal.message import (
    MessageCheckSumError,
    MessageLenError,
    MessageQueryAppliance,
)

# Status answer: compressor running, all doors closed, ice making, ambient 22.4 C
STATUS_RUNNING = bytes.fromhex(
    "55aacc334d0001ca000000000000038000000002000c0c0000000000810000000000e000"
    "000e646464640c190c0c001600063c63633263630000070000000000000000000000000000"
    "ffffffffffff98c3",
)
# Status answer while the ice maker reports a water shortage
STATUS_WATER_SHORTAGE = bytes.fromhex(
    "55aacc334d0001ca000000000000038000000002000c0c10000000000b00ee000000e400"
    "000e646464640c190c0c001600063c63633263630000070000000000000000000000000000"
    "ffffffffffff4106",
)


def _frame(body: bytes, data_type: int = 0x0004) -> bytes:
    """Wrap a body in a Toshiba frame, as the device does for notifications."""
    stream = toshiba_frame_header(len(body), data_type) + body
    return bytes(stream + toshiba_crc16(stream).to_bytes(2, "little"))


def _status_frame(**changes: int) -> bytes:
    """Return STATUS_RUNNING with some body bytes replaced (``b5=0x02``)."""
    _, body = extract_toshiba_frame(STATUS_RUNNING)
    edited = bytearray(body)
    for index, value in changes.items():
        edited[int(index[1:])] = value
    return _frame(bytes(edited), data_type=0x0003)


class TestToshibaFrame:
    """Test the Toshiba frame helpers and query."""

    def test_query_serialize(self) -> None:
        """The query matches what the device answers."""
        assert MessageToshibaQuery().serialize().hex(" ") == (
            "55 aa cc 33 0f 00 01 ca 00 00 00 00 00 00 03 00 00 35 7c"
        )

    def test_extract_ignores_padding(self) -> None:
        """AES padding after the frame is ignored."""
        data_type, body = extract_toshiba_frame(STATUS_RUNNING + b"\x00" * 15)
        assert data_type == 0x03
        assert len(body) == 63

    def test_extract_rejects_bad_crc(self) -> None:
        """A frame with a wrong CRC raises."""
        broken = STATUS_RUNNING[:-1] + bytes([STATUS_RUNNING[-1] ^ 0xFF])
        with pytest.raises(MessageCheckSumError):
            extract_toshiba_frame(broken)

    def test_extract_rejects_short_or_foreign(self) -> None:
        """AA frames and truncated frames raise."""
        with pytest.raises(MessageLenError):
            extract_toshiba_frame(bytes.fromhex("aa0bca000000000000030000"))
        with pytest.raises(MessageLenError):
            extract_toshiba_frame(STATUS_RUNNING[:40])


class TestToshibaResponse:
    """Test parsing Toshiba frames."""

    def test_status_running(self) -> None:
        """Parse a full status answer."""
        message = MessageToshibaCAResponse(STATUS_RUNNING)
        assert message.ice_maker_status == "running"
        assert message.ice_making_mode == "normal"
        assert message.power_saving_mode == "power_saving_auto_plus"
        assert message.upper_freezer_mode == "normal"
        assert message.chilled_room_mode == "normal"
        assert message.refrigerator_setting_level == "medium"
        assert message.freezer_setting_level == "medium"
        assert message.refrigerator_door is False
        assert message.vegetable_door is False
        assert message.estimated_power == 129
        assert message.daily_energy == 0
        assert message.error_code == 0
        assert message.ambient_temperature == pytest.approx(22.4)
        assert not hasattr(message, "refrigerator_high_temperature")

    def test_status_water_shortage(self) -> None:
        """Water shortage, power and energy are little-endian."""
        message = MessageToshibaCAResponse(STATUS_WATER_SHORTAGE)
        assert message.ice_maker_status == "water_shortage"
        assert message.estimated_power == 11
        assert message.daily_energy == 238
        assert message.ambient_temperature == pytest.approx(22.8)

    @pytest.mark.parametrize(
        ("changes", "attribute", "expected"),
        [
            ({"b5": 0x02}, "refrigerator_setting_level", "weak"),
            ({"b5": 0x16}, "refrigerator_setting_level", "strong"),
            ({"b6": 0x11}, "freezer_setting_level", "slightly_strong"),
            ({"b3": 0x04, "b5": 0x80}, "refrigerator_setting_level", "auto"),
            ({"b3": 0x04}, "power_saving_mode", "low_power_cooling"),
            ({"b4": 0x01}, "upper_freezer_mode", "quick_freezing"),
            ({"b4": 0x09}, "upper_freezer_mode", "frozen_rice"),
            ({"b1": 0x01}, "chilled_room_mode", "power_low_temp"),
            ({"b1": 0x02}, "chilled_room_mode", "deli_chilled"),
            ({"b1": 0x22}, "chilled_room_mode", "thawing"),
            ({"b7": 0x01}, "ice_making_mode", "quick"),
            ({"b7": 0x02}, "ice_making_mode", "off"),
            ({"b7": 0x20}, "ice_maker_status", "ice_full"),
            ({"b8": 0x01}, "vegetable_sterilization", True),
            ({"b10": 0x01}, "moisturizing", True),
            ({"b11": 0x01}, "refrigerator_door", True),
            ({"b11": 0x02}, "freezer_door", True),
            ({"b11": 0x08}, "vegetable_door", True),
            ({"b16": 0x91, "b17": 0x01}, "error_code", 401),
            ({"b16": 0xFF, "b17": 0xFF}, "error_code", None),
        ],
    )
    def test_status_values(
        self,
        changes: dict[str, int],
        attribute: str,
        expected: object,
    ) -> None:
        """Values seen on the device when switching modes in the IoLIFE app."""
        message = MessageToshibaCAResponse(_status_frame(**changes))
        assert getattr(message, attribute) == expected

    def test_door_notification(self) -> None:
        """Door info uses a different bit order and carries temperature alarms."""
        message = MessageToshibaCAResponse(_frame(bytes([0x22, 0x12, 0x01])))
        assert message.vegetable_door is True
        assert message.freezer_door is True
        assert message.refrigerator_door is False
        assert message.upper_freezer_door is False
        assert message.refrigerator_high_temperature is True
        assert message.freezer_high_temperature is False
        assert not hasattr(message, "ice_maker_status")

    def test_auto_saving_notification(self) -> None:
        """Auto power saving info is pushed with function type 0x05."""
        body = bytes.fromhex("0503000101e9fff7fff2fffbff0400ebff00")
        message = MessageToshibaCAResponse(_frame(body))
        assert message.auto_saving_status == "normal"
        assert not hasattr(message, "refrigerator_door")

    def test_short_status_body(self) -> None:
        """A status body without the error code and temperature fields."""
        _, body = extract_toshiba_frame(STATUS_RUNNING)
        message = MessageToshibaCAResponse(_frame(body[:16], data_type=0x0003))
        assert message.ice_maker_status == "running"
        assert not hasattr(message, "error_code")
        assert not hasattr(message, "ambient_temperature")

    def test_negative_ambient_temperature(self) -> None:
        """The ambient temperature is a signed value."""
        message = MessageToshibaCAResponse(_status_frame(b18=0x9C, b19=0xFF))
        assert message.ambient_temperature == pytest.approx(-10.0)

    def test_door_notification_without_alarms(self) -> None:
        """A door body without the alarm byte leaves the alarms unset."""
        message = MessageToshibaCAResponse(_frame(bytes([0x22, 0x01])))
        assert message.refrigerator_door is True
        assert not hasattr(message, "refrigerator_high_temperature")

    def test_str(self) -> None:
        """The debug representation lists the parsed fields."""
        text = str(MessageToshibaCAResponse(STATUS_WATER_SHORTAGE))
        assert "'ice_maker_status': 'water_shortage'" in text

    def test_unknown_function_sets_nothing(self) -> None:
        """Log frames (e.g. 0x21) are parsed without attributes."""
        message = MessageToshibaCAResponse(_frame(bytes([0x21]) + bytes(20)))
        assert message.function_type == 0x21
        assert not hasattr(message, "error_code")


class TestToshibaDevice:
    """Test the CA device with a Toshiba refrigerator."""

    device: MideaCADevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Create a CA device."""
        self.device = MideaCADevice(
            name="Toshiba",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="0000000D",
            subtype=0,
            customize="",
        )

    def test_query_only_after_appliance_query_failed(self) -> None:
        """Midea refrigerators never receive the Toshiba query."""
        queries = self.device.build_query()
        assert [type(query) for query in queries] == [MessageQuery]
        self.device._unsupported_protocol.append(MessageQueryAppliance.__name__)
        queries = self.device.build_query()
        assert [type(query) for query in queries] == [
            MessageQuery,
            MessageToshibaQuery,
        ]

    def test_process_status_then_door(self) -> None:
        """Status answers and door notifications update the attributes."""
        status = self.device.process_message(STATUS_WATER_SHORTAGE)
        assert status[DeviceAttributes.ice_maker_status] == "water_shortage"
        assert self.device.attributes[DeviceAttributes.refrigerator_door] is False
        assert (
            self.device.attributes[DeviceAttributes.refrigerator_high_temperature]
            is None
        )

        status = self.device.process_message(_frame(bytes([0x22, 0x01, 0x00])))
        assert status == {
            DeviceAttributes.refrigerator_door: True,
            DeviceAttributes.vegetable_door: False,
            DeviceAttributes.ice_door: False,
            DeviceAttributes.upper_freezer_door: False,
            DeviceAttributes.freezer_door: False,
            DeviceAttributes.refrigerator_high_temperature: False,
            DeviceAttributes.freezer_high_temperature: False,
        }
        # values only carried by the status frame are kept
        assert self.device.attributes[DeviceAttributes.ice_maker_status] == (
            "water_shortage"
        )

    def test_midea_frames_still_use_ca_parser(self) -> None:
        """AA frames keep going through the existing parser."""
        header = bytearray([0xAA] + [0x00] * 7 + [ProtocolVersion.V1, 0x03])
        body = bytearray(32)
        status = self.device.process_message(bytes(header + body + b"\x00"))
        assert DeviceAttributes.ice_maker_status not in status
