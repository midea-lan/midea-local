"""Test CA message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ca.message import (
    CAExceptionMessageBody,
    CAGeneralMessageBody,
    CANotify00MessageBody,
    CANotify01MessageBody,
    MessageCABase,
    MessageCAResponse,
    MessageQuery,
)
from midealocal.message import ListTypes, MessageType


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full CA response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


def _general_body(length: int) -> bytearray:
    """Build a CA general body with representative values."""
    body = bytearray(length)
    body[0] = 0x00
    body[1] = 0xFF  # all mode bits
    body[2] = 0x35  # refrigerator 5, freezer -15
    body[5] = 0x02  # variable mode
    body[6] = 0x00  # all powers on
    body[7] = 0xFF
    body[8] = 0xFF
    body[9] = 70  # freezing fahrenheit
    body[10] = 0xFF  # refrigeration fahrenheit
    body[11] = 30  # leach expire day
    body[12] = 0x10
    body[13] = 0x01  # energy consumption 272
    body[14] = 0xFF
    body[15] = 0xFF
    body[16] = 0x01  # is_error set, humidity level 0
    body[17] = 110  # refrigerator actual 5.0
    body[18] = 90  # freezer actual -5.0
    body[19] = 100  # flex actual 0.0
    body[20] = 120  # right flex actual 10.0
    body[21] = 1
    body[22] = 1  # fast cold 257
    body[23] = 2
    body[24] = 0  # fast freeze 2
    return body


class TestMessageCABase:
    """Test CA Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageCABase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test CA Message Query."""

    def test_query_body(self) -> None:
        """Test query body only contains the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x00])


class TestCAGeneralMessageBody:
    """Test CA general message body."""

    def test_short_body(self) -> None:
        """Test general body without the optional trailing bytes."""
        raw = _general_body(25)
        raw[3] = 0  # flex zone out of range
        raw[4] = 40  # right flex zone out of range
        body = CAGeneralMessageBody(raw)
        assert body.code_mode is True
        assert body.freezing_mode is True
        assert body.smart_mode is True
        assert body.energy_saving_mode is True
        assert body.holiday_mode is True
        assert body.moisturize_mode is True
        assert body.preservation_mode is True
        assert body.acmeFreezing_mode is True
        assert body.refrigerator_setting_temp == 5
        assert body.freezer_setting_temp == -15
        assert body.flex_zone_setting_temp == 0
        assert body.right_flex_zone_setting_temp == 0
        assert body.variable_mode == 0x02
        assert body.refrigeration_power is True
        assert body.l_variable_power is True
        assert body.r_variable_power is True
        assert body.freezing_power is True
        assert body.cross_peak_electricity_enter == 0
        assert body.cross_peak_electricity is False
        assert body.all_refrigeration_power is False
        assert body.remove_dew == 0x01
        assert body.humidify == 0x02
        assert body.unfreeze == 0x04
        assert body.temperature_unit == 0x08
        assert body.flood_light == 0x10
        assert body.function_switch == 0xC0
        assert body.radar_mode == 0x01
        assert body.milk_mode == 0x02
        assert body.iced_mode == 0x04
        assert body.plasma_aseptic_mode == 0x08
        assert body.acquire_icea_mode == 0x10
        assert body.brash_icea_mode == 0x20
        assert body.acquire_water_mode == 0x40
        assert body.freezing_ice_machine_power == 0x80
        assert body.freezing_fahrenheit == 70
        assert body.refrigeration_fahrenheit == 0xFC
        assert body.leach_expire_day == 30
        assert body.energy_consumption == 272
        assert body.freezing_motor_reset_status == 0x01
        assert body.freezing_motor_deicing_status == 0x02
        assert body.freezing_ice_machine_water_status == 0x04
        assert body.freezing_all_ice_status == 0x08
        assert body.human_induction == 0x10
        assert body.refrigeration_door_power == 0x01
        assert body.freezing_door_power == 0x02
        assert body.variable_door_power == 0x10
        assert body.storage_iceHome_door_state == 0x20
        assert body.bar_door_power == 0x04
        assert body.ice_mouth_power == 0x08
        assert body.is_error == 0x01
        assert body.interval_room_humidity_level == 0x00
        assert body.refrigerator_actual_temp == 5.0
        assert body.freezer_actual_temp == -5.0
        assert body.flex_zone_actual_temp == 0.0
        assert body.right_flex_zone_actual_temp == 10.0
        assert body.fast_cold_minute == 257
        assert body.fast_freeze_minute == 2
        assert not hasattr(body, "microcrystal_fresh")
        assert not hasattr(body, "humidity_setting")
        assert not hasattr(body, "storage_left_door_auto")

    def test_full_body(self) -> None:
        """Test general body with all optional trailing bytes."""
        raw = _general_body(32)
        raw[3] = 5  # flex zone positive range
        raw[4] = 50  # right flex zone negative range
        raw[27] = 0x15  # microcrystal, electronic smell, humidity high
        raw[28] = 3
        raw[29] = 4
        raw[30] = 0x85
        raw[31] = 0xFF
        body = CAGeneralMessageBody(raw)
        assert body.flex_zone_setting_temp == -14
        assert body.right_flex_zone_setting_temp == -20
        assert body.microcrystal_fresh is True
        assert body.dry_zone is False
        assert body.electronic_smell is True
        assert body.humidity == 0x10
        assert body.normal_temperature_level == 3
        assert body.function_zone_level == 4
        assert body.humidity_setting == 5
        assert body.smart_humidity == 0x80
        assert body.storage_left_door_auto == 0x03
        assert body.storage_right_door_auto == 0x0C
        assert body.freezer_door_auto == 0x30
        assert body.freezer_door_auto_control == 0x40
        assert body.storage_door_auto_control == 0x80

    def test_temperature_branches(self) -> None:
        """Test general body remaining flex zone temperature branches."""
        raw = _general_body(25)
        raw[3] = 49  # flex zone negative range
        raw[4] = 1  # right flex zone positive range
        body = CAGeneralMessageBody(raw)
        assert body.flex_zone_setting_temp == -19
        assert body.right_flex_zone_setting_temp == -18


class TestCAExceptionMessageBody:
    """Test CA exception message body."""

    def test_exception_body(self) -> None:
        """Test exception body parsing."""
        body = CAExceptionMessageBody(bytearray([0x01, 0x1F, 0xFF, 0x0F]))
        assert body.refrigerator_door_overtime is True
        assert body.freezer_door_overtime is True
        assert body.bar_door_overtime is True
        assert body.flex_zone_door_overtime is True
        assert body.ice_miachine_full == 0x10
        assert body.refrigeration_sensor_error == 0x01
        assert body.refrigeration_deforsting_sensor_error == 0x02
        assert body.ring_temperature_sensor_error == 0x04
        assert body.flex_zone_sensor_error == 0x08
        assert body.right_flex_zone_sensor_error == 0x10
        assert body.freezing_high_temperature == 0x20
        assert body.freezing_sensor_error == 0x40
        assert body.freezing_defrosting_sensor_error == 0x80
        assert body.ice_electrical_machinery_error == 0x01
        assert body.refrigeration_defrosting_overtime == 0x02
        assert body.freezing_defrosting_overtime == 0x04
        assert body.zeroCrossingCheckError == 0x08
        assert body.eepromReadWriteError == 0x04

    def test_exception_body_clear(self) -> None:
        """Test exception body with no error bits."""
        body = CAExceptionMessageBody(bytearray([0x01, 0x00, 0x00, 0x00]))
        assert body.refrigerator_door_overtime is False
        assert body.freezer_door_overtime is False
        assert body.bar_door_overtime is False
        assert body.flex_zone_door_overtime is False


class TestCANotify00MessageBody:
    """Test CA notify00 message body."""

    def test_notify00_body(self) -> None:
        """Test notify00 body parsing."""
        body = CANotify00MessageBody(bytearray([0x00, 0x17]))
        assert body.refrigerator_door is True
        assert body.freezer_door is True
        assert body.bar_door is True
        assert body.flex_zone_door is True

    def test_notify00_body_closed(self) -> None:
        """Test notify00 body with all doors closed."""
        body = CANotify00MessageBody(bytearray([0x00, 0x00]))
        assert body.refrigerator_door is False
        assert body.freezer_door is False
        assert body.bar_door is False
        assert body.flex_zone_door is False


class TestCANotify01MessageBody:
    """Test CA notify01 message body."""

    @pytest.mark.parametrize(
        ("flex_raw", "right_raw", "flex_expected", "right_expected"),
        [
            (5, 50, -14, -20),
            (49, 1, -19, -18),
            (0, 60, 0, 0),
        ],
    )
    def test_notify01_body(
        self,
        flex_raw: int,
        right_raw: int,
        flex_expected: int,
        right_expected: int,
    ) -> None:
        """Test notify01 body parsing."""
        raw = bytearray(41)
        raw[0] = 0x01
        raw[37] = 4
        raw[38] = 3
        raw[39] = flex_raw
        raw[40] = right_raw
        body = CANotify01MessageBody(raw)
        assert body.refrigerator_setting_temp == 4
        assert body.freezer_setting_temp == -15
        assert body.flex_zone_setting_temp == flex_expected
        assert body.right_flex_zone_setting_temp == right_expected


class TestMessageCAResponse:
    """Test CA Message Response."""

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.query, MessageType.set],
    )
    def test_general_response(self, message_type: MessageType) -> None:
        """Test query and set responses with a general body."""
        msg = MessageCAResponse(_build_message(message_type, _general_body(25)))
        assert getattr(msg, "energy_consumption", None) == 272

    def test_notify1_general_response(self) -> None:
        """Test notify1 response with a general body."""
        body = _general_body(25)
        body[0] = 0x02
        msg = MessageCAResponse(_build_message(MessageType.notify1, body))
        assert getattr(msg, "energy_consumption", None) == 272

    def test_general_response_too_short(self) -> None:
        """Test query response with a too short general body."""
        body = bytearray(15)
        msg = MessageCAResponse(_build_message(MessageType.query, body))
        assert not hasattr(msg, "energy_consumption")

    def test_exception_response(self) -> None:
        """Test exception response."""
        body = bytearray([0x01, 0x0F, 0x00, 0x00])
        msg = MessageCAResponse(_build_message(MessageType.exception, body))
        assert getattr(msg, "refrigerator_door_overtime", None) is True

    def test_query_exception_response(self) -> None:
        """Test query response with an exception body."""
        body = bytearray([0x02, 0x0F, 0x00, 0x00])
        msg = MessageCAResponse(_build_message(MessageType.query, body))
        assert getattr(msg, "freezer_door_overtime", None) is True

    def test_notify1_00_response(self) -> None:
        """Test notify1 response with a notify00 body."""
        body = bytearray([0x00, 0x07])
        msg = MessageCAResponse(_build_message(MessageType.notify1, body))
        assert getattr(msg, "refrigerator_door", None) is True
        assert getattr(msg, "freezer_door", None) is True
        assert getattr(msg, "bar_door", None) is True
        assert getattr(msg, "flex_zone_door", None) is False

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.query, MessageType.notify1],
    )
    def test_notify01_response(self, message_type: MessageType) -> None:
        """Test query and notify1 responses with a notify01 body."""
        body = bytearray(41)
        body[0] = 0x01
        body[37] = 5
        body[38] = 2
        msg = MessageCAResponse(_build_message(message_type, body))
        assert getattr(msg, "refrigerator_setting_temp", None) == 5
        assert getattr(msg, "freezer_setting_temp", None) == -14

    def test_unhandled_response(self) -> None:
        """Test response with an unhandled message type."""
        body = bytearray(25)
        msg = MessageCAResponse(_build_message(MessageType.notify2, body))
        assert not hasattr(msg, "energy_consumption")
