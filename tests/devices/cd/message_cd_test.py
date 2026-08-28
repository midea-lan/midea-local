"""Test CD message."""

from typing import Any

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.cd.message import (
    CD01MessageBody,
    CDB1MessageBody,
    CDDailyTimerBody,
    CDGeneralMessageBody,
    CDSterilizeSetBody,
    CDWeeklyScheduleBody,
    MessageCDBase,
    MessageCDResponse,
    MessageQuery,
    MessageQueryB1,
    MessageQueryDaily,
    MessageQueryWeekly,
    MessageSet,
    MessageSetDaily,
    MessageSetMaintenance,
    MessageSetSterilize,
    MessageSetWeekly,
)
from midealocal.message import ListTypes, MessageType


class TestMessageCDBase:
    """Test CD message base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageCDBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestCDMessageQueries:
    """Test CD query message bodies."""

    def test_query_body(self) -> None:
        """Status query body is queryType=0x01 after the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01, 0x01])

    def test_query_weekly_body(self) -> None:
        """Weekly query body uses body type 0x02."""
        msg = MessageQueryWeekly(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x02, 0x01])

    def test_query_daily_body(self) -> None:
        """Daily query body uses body type 0x03."""
        msg = MessageQueryDaily(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x03, 0x01])

    def test_query_b1_body_and_crc(self) -> None:
        """B1 query requests all official water-heater function tags."""
        body = MessageQueryB1(protocol_version=ProtocolVersion.V1).body
        assert body[:-1] == bytearray.fromhex(
            "b10810001100120013001400150006001600",
        )
        assert body[-1] == 0x6B


class TestMessageSet:
    """Test CD message set body construction."""

    def test_default_body(self) -> None:
        """Default set body encodes power off with old-protocol scaling."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert body[0] == 0x01  # body_type
        assert body[1] == 0x01  # constant
        assert body[2] == 0x00  # power off
        assert body[3] == 0x00  # mode
        assert body[4] == 30  # 0 * 2 + 30 (old protocol)
        assert body[8] == 0x00  # flags
        assert body[9] == 0x00
        assert body[10] == 0x00
        assert body[21] == 0  # max_temperature

    def test_old_protocol_temperature(self) -> None:
        """Old protocol doubles the temperature and adds 30."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.target_temperature = 40.0
        assert msg.body[4] == 110

    def test_new_protocol_temperature(self) -> None:
        """New protocol sends the raw temperature value."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.use_old_protocol = False
        msg.target_temperature = 40.0
        assert msg.body[4] == 40

    def test_flags_and_vacation_days(self) -> None:
        """Vacation, fahrenheit and preserved mute bits build byte8."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        msg.mode = 0x02
        msg.vacation_flag = True
        msg.fahrenheit = True
        msg.fields = {"byte8": 0x0F}  # only 0x08 (mute) is preserved
        msg.vacation_days = 300
        msg.target_temperature = 65.0
        msg.vacation_temperature = 65.0
        body = msg.body
        assert body[2] == 0x01
        assert body[3] == 0x02
        assert body[8] == 0x10 | 0x80 | 0x08
        assert body[9] == 0x01  # 300 >> 8
        assert body[10] == 0x2C  # 300 & 0xFF
        assert body[21] == 65  # vacationTsValue

    def test_read_field(self) -> None:
        """read_field returns int values and 0 for missing/empty fields."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.fields = {"trValue": "5", "openPTC": 0}
        assert msg.read_field("trValue") == 5
        assert msg.read_field("openPTC") == 0
        assert msg.read_field("missing") == 0

    def test_schedule_mode_uses_basic_control_byte_22(self) -> None:
        """Timer/schedule selection is preserved in ordinary controls."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.schedule_mode = 2
        assert msg.body[22] == 2


class TestMessageSetMaintenance:
    """Test the dedicated B0 function flag control."""

    def test_flags_are_preserved_and_crc_is_appended(self) -> None:
        """B0 changes maintenance without dropping unrelated flag bits."""
        msg = MessageSetMaintenance(protocol_version=ProtocolVersion.V1)
        msg.ac_heater_priority = True
        msg.high_temp_reminder = False
        msg.maintenance_reminder = True
        msg.reserved_flags = 0x18
        assert msg.body == bytearray.fromhex("b0011000011d56")


class TestMessageSetDaily:
    """Test NetHome daily timer controls."""

    def test_complete_timer_body(self) -> None:
        """Daily timer uses body type 2 and the official forty-byte layout."""
        msg = MessageSetDaily(protocol_version=ProtocolVersion.V1)
        msg.daily_timer_schedule = {
            "amount": 1,
            "single_timer_on": True,
            "single_timer_off": False,
            "timers": [
                {
                    "effect": True,
                    "openhour": 6,
                    "openmin": 30,
                    "closehour": 8,
                    "closemin": 0,
                    "temperature": 55,
                    "mode": 1,
                },
            ],
        }
        body = msg.body
        assert len(body) == 40
        assert body[:10] == bytearray([2, 1, 1, 0x41, 6, 30, 8, 0, 55, 1])


class TestCDB1MessageBody:
    """Test B1 TLV parsing used to make B0 writes lossless."""

    def test_function_and_capability_tlvs(self) -> None:
        """Function flags and extended model metadata are decoded."""
        body = bytearray.fromhex("b108000010011d0000110101")
        parsed = CDB1MessageBody(body)
        assert parsed.ac_heater_priority is True
        assert parsed.high_temp_reminder is False
        assert parsed.maintenance_reminder is True
        assert parsed.b0_reserved_flags == 0x18
        assert parsed.new_version_water_heater is True

    def test_omitted_tlv_does_not_publish_unknown_values(self) -> None:
        """Attributes for TLVs absent from a B1 response are not published."""
        parsed = CDB1MessageBody(bytearray.fromhex("b1080000110101"))
        assert parsed.new_version_water_heater is True
        assert not hasattr(parsed, "maintenance_reminder")


class TestMessageSetSterilizeClamp:
    """Test MessageSetSterilize clamp helpers with invalid inputs."""

    def test_clamp_unparseable_string(self) -> None:
        """Unparsable strings fall back to the minimum."""
        assert MessageSetSterilize.clamp_week("abc") == 0
        assert MessageSetSterilize.clamp_hour("abc") == 0

    def test_clamp_unsupported_type(self) -> None:
        """Unsupported types fall back to the minimum."""
        assert MessageSetSterilize.clamp_week(None) == 0
        assert MessageSetSterilize.clamp_minute(object()) == 0


class TestMessageSetWeekly:
    """Test CD weekly control message body."""

    def test_empty_schedule_body(self) -> None:
        """No schedule produces an all-zero slot body."""
        msg = MessageSetWeekly(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert body[0] == 0x07  # body_type
        assert body[1] == 0x01  # constant
        assert len(body) == 177
        assert all(byte == 0 for byte in body[2:])

    def test_schedule_and_maintenance_flags(self) -> None:
        """Slots and day-0 maintenance bits are encoded."""
        msg = MessageSetWeekly(protocol_version=ProtocolVersion.V1)
        msg.weekly_schedule = {
            0: [
                {
                    "effect": True,
                    "opentime": 10,
                    "closetime": 20,
                    "temperature": 45,
                    "mode": 2,
                },
            ],
            1: [
                {"effect": False},
                {
                    "effect": True,
                    "opentime": 300,  # masked to 0x2C
                    "closetime": 30,
                    "temperature": 50,
                    "mode": 4,
                },
            ],
        }
        msg.maintenance_reminder = True
        msg.maintenance_warn = True
        body = msg.body
        # day 0: timer 1 effect + maintenance bits
        assert body[2] == 0x01 | 0x40 | 0x80
        # day 0 slot 0 data at body[9..12]
        assert body[9] == 10
        assert body[10] == 20
        assert body[11] == 45
        assert body[12] == 2
        # day 1: timer 2 effect only
        assert body[3] == 0x02
        # day 1 slot 1 data at body[9 + 24 + 4]
        assert body[37] == 300 & 0xFF
        assert body[38] == 30
        assert body[39] == 50
        assert body[40] == 4
        # remaining days untouched
        assert body[8] == 0x00


class TestCDGeneralMessageBody:
    """Test CDGeneralMessageBody parsing of real-device status bytes."""

    def test_extended_capabilities_and_limits(self) -> None:
        """RSJRAC extended status bytes are exposed only when present."""
        body = bytearray(69)
        body[2] = 0x03
        body[57:61] = bytearray([70, 35, 70, 60])
        body[61] = 65
        body[62] = 0x03
        body[63:67] = bytearray([1, 2, 1, 0x7F])
        body[67:69] = bytearray([100, 2])
        parsed = CDGeneralMessageBody(body)
        assert parsed.max_temperature_upper_limit == 70.0
        assert parsed.max_temperature_lower_limit == 35.0
        assert parsed.auto_disinfect is True
        assert parsed.support_boost_mode is True
        assert parsed.support_silent_mode is True
        assert parsed.support_tou is True
        assert parsed.remaining_hot_water_max == 100
        assert parsed.force_e_heating_status == 2

    def test_extended_boost_mode_flag(self) -> None:
        """Extended status byte 52 exposes Boost without affecting legacy bits."""
        body = bytearray(69)
        body[52] = 0x10
        body[53:56] = bytearray([1, 1, 1])
        parsed = CDGeneralMessageBody(body)
        assert parsed.mode == 0x09
        assert parsed.holiday_mode is False
        assert parsed.hybrid_motion_mode is False
        assert parsed.support_heat_pump_mode is True
        assert parsed.support_smart_mode is True
        assert parsed.support_negative_temperature is True

    # Real-device status bodies (body_type=0x01):
    #   msg1: 70C disinfection, sterilize ON
    #   msg2: 65C disinfection, sterilize ON
    #   msg3: 60C disinfection, sterilize OFF
    MSG1_HEX = (
        "010113279239391346134126090000002a1e2a1e008600000000000187040000000000"
        "780000433f3f3f3f3f3f000c000000004200000101004641463c4601000000"
    )
    MSG2_HEX = (
        "010113279239391346134126090000002a1e2a1e008600000000000187040000000000"
        "780000433f3f3f3f3f3f000c000000004200000101004641463c4101000000"
    )
    MSG3_HEX = (
        "010193279239391346134126090000002a1e2a1e008600000000000087040000000000"
        "780000433f3f3f3f3f3f000c000000004200000101004641463c3c00000000"
    )
    # Real payloads reported from thermostat UI / official app:
    #   malformed-ui: disinfection ON, invalid body[61]=0xF7 and body[45]=0x88
    #   app-fix-60:   disinfection corrected to 60C, week=4
    #   app-fix-64:   disinfection set to 64C, week=4
    MALFORMED_UI_HEX = (
        "010113388833340d44454126090000002a1e2a1e003000000000000887040000000000"
        "780000433f3f3f3f3f3f880e050000004400000101014641463cf701000000"
    )
    APP_FIX_60_HEX = (
        "010113388833340d44454126090000002a1e2a1e003000000000000887040000000000"
        "780000433f3f3f3f3f3f040e050000004400000101014641463c3c01000000"
    )
    APP_FIX_64_HEX = (
        "010113388a34350d44454126090000002a1e2a1e003000000000000887040000000000"
        "780000433f3f3f3f3f3f040e050000004400000101014641463c4001000000"
    )

    def _parse(self, hex_str: str) -> CDGeneralMessageBody:
        return CDGeneralMessageBody(bytearray.fromhex(hex_str))

    def test_sterilize_on_70c(self) -> None:
        """msg1 has sterilize=True and disinfection_temperature=70.0."""
        body = self._parse(self.MSG1_HEX)
        assert body.sterilize is True
        assert body.disinfect is True
        assert body.disinfection_temperature == 70.0
        assert body.maintenance_reminder is True

    def test_sterilize_on_65c(self) -> None:
        """msg2 has sterilize=True and disinfection_temperature=65.0."""
        body = self._parse(self.MSG2_HEX)
        assert body.sterilize is True
        assert body.disinfect is True
        assert body.disinfection_temperature == 65.0

    def test_sterilize_off_60c(self) -> None:
        """msg3 stores disinfection_temperature=60.0 while sterilize is false."""
        body = self._parse(self.MSG3_HEX)
        assert body.sterilize is False
        assert body.disinfect is False
        assert body.disinfection_temperature == 60.0

    def test_max_temperature_all_messages(self) -> None:
        """body[10]=0x41=65 gives max_temperature=65."""
        for hex_str in (self.MSG1_HEX, self.MSG2_HEX, self.MSG3_HEX):
            body = self._parse(hex_str)
            assert body.max_temperature == 65.0

    def test_vacation_temperature_all_messages(self) -> None:
        """body[51]=0x42=66 gives vacation_temperature=66.0."""
        for hex_str in (self.MSG1_HEX, self.MSG2_HEX, self.MSG3_HEX):
            body = self._parse(hex_str)
            assert body.vacation_temperature == 66.0

    def test_power_on_all_sterilize_on_messages(self) -> None:
        """body[2] bit 0 = 1 gives power=True."""
        for hex_str in (self.MSG1_HEX, self.MSG2_HEX, self.MSG3_HEX):
            body = self._parse(hex_str)
            assert body.power is True

    def test_malformed_ui_status_uses_temperature_fallback(self) -> None:
        """Malformed frame uses disinfection temperature fallback."""
        body = self._parse(self.MALFORMED_UI_HEX)
        assert body.sterilize is True
        assert body.disinfection_temperature == 68.0
        assert body.auto_sterilize_week == 136
        assert body.auto_sterilize_hour == 14
        assert body.auto_sterilize_minute == 5

    def test_app_corrected_status_60c(self) -> None:
        """Correct app payload keeps week/day and 60C setpoint."""
        body = self._parse(self.APP_FIX_60_HEX)
        assert body.sterilize is True
        assert body.auto_sterilize_week == 4
        assert body.disinfection_temperature == 60.0

    def test_app_corrected_status_64c(self) -> None:
        """Correct app payload keeps week/day and 64C setpoint."""
        body = self._parse(self.APP_FIX_64_HEX)
        assert body.sterilize is True
        assert body.auto_sterilize_week == 4
        assert body.disinfection_temperature == 64.0

    def test_invalid_status_week_is_read_raw(self) -> None:
        """Invalid status weekday is exposed exactly as read."""
        raw = bytearray.fromhex(self.APP_FIX_60_HEX)
        raw[45] = 7
        body = CDGeneralMessageBody(raw)
        assert body.auto_sterilize_week == 7
        assert body.disinfection_temperature == 60.0

    def test_invalid_status_minute_is_read_raw(self) -> None:
        """Invalid status minute is exposed exactly as read."""
        raw = bytearray.fromhex(self.APP_FIX_60_HEX)
        raw[47] = 86
        body = CDGeneralMessageBody(raw)
        assert body.auto_sterilize_week == 4
        assert body.auto_sterilize_hour == 14
        assert body.auto_sterilize_minute == 86


class TestCDSterilizeSetBody:
    """Test CDSterilizeSetBody disambiguation of body[3]."""

    def _make_body(
        self,
        sterilize_on: bool,
        byte3: int,
        hour: int = 0,
        minute: int = 0,
    ) -> bytearray:
        """Build a minimal CDSterilizeSetBody payload."""
        # body[0]=body_type(0x06), body[1]=constant(0x01),
        # body[2]=sterilizeEffect, body[3]=week/temp, body[4]=hour, body[5]=minute
        return bytearray(
            [
                0x06,  # body_type
                0x01,  # constant
                0x80 if sterilize_on else 0x00,  # sterilizeEffect
                byte3,  # week value OR celsius x2 temperature echo
                hour,
                minute,
            ],
        )

    # --- temperature echo (body[3] encoded as C x2 in [120,140], even) ---

    def test_temp_echo_on_sets_disinfection_temperature(self) -> None:
        """body[3]=132 sets disinfection_temperature=66.0 when on."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=132))
        assert parsed.disinfection_temperature == 66.0

    def test_temp_echo_on_keeps_raw_auto_sterilize_week(self) -> None:
        """body[3]=132 when sterilize ON also remains available as raw week."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=132))
        assert parsed.auto_sterilize_week == 132

    def test_temp_echo_off_sets_disinfection_temperature(self) -> None:
        """body[3]=132 still carries setpoint echo when off."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=False, byte3=132))
        assert parsed.disinfection_temperature == 66.0

    def test_temp_echo_off_keeps_raw_auto_sterilize_week(self) -> None:
        """body[3]=132 when sterilize OFF also remains available as raw week."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=False, byte3=132))
        assert parsed.auto_sterilize_week == 132

    def test_temp_echo_out_of_range_high(self) -> None:
        """body[3]=145 is outside encoded temperature, so keep it as raw week."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=145))
        assert parsed.disinfection_temperature is None
        assert parsed.auto_sterilize_week == 145

    def test_temp_echo_boundary_min(self) -> None:
        """body[3]=128 gives disinfection_temperature=64.0."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=128))
        assert parsed.disinfection_temperature == 64.0
        assert parsed.auto_sterilize_week == 128

    def test_temp_echo_boundary_max(self) -> None:
        """body[3]=140 gives disinfection_temperature=70.0."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=140))
        assert parsed.disinfection_temperature == 70.0
        assert parsed.auto_sterilize_week == 140

    def test_temp_echo_60_encodes_120_and_keeps_raw_week(self) -> None:
        """body[3]=120 is parsed as temperature and kept raw."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=120))
        assert parsed.disinfection_temperature == 60.0
        assert parsed.auto_sterilize_week == 120

    # --- weekday (body[3] in [0, 6]) ---

    def test_week_value_sets_auto_sterilize_week(self) -> None:
        """body[3]=4 gives auto_sterilize_week=4, not temperature."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=4))
        assert parsed.auto_sterilize_week == 4
        assert parsed.disinfection_temperature is None

    def test_week_value_zero_sets_auto_sterilize_week(self) -> None:
        """body[3]=0 gives auto_sterilize_week=0."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=0))
        assert parsed.auto_sterilize_week == 0
        assert parsed.disinfection_temperature is None

    def test_week_out_of_range_is_read_raw(self) -> None:
        """body[3]=7 is invalid as weekday but must not be clamped on read."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=False, byte3=7))
        assert parsed.auto_sterilize_week == 7
        assert parsed.disinfection_temperature is None

    def test_disinfect_flag_matches_sterilize(self) -> None:
        """Disinfect attribute mirrors sterilize_on regardless of body[3]."""
        on = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=4))
        assert on.sterilize is True
        assert on.disinfect is True
        off = CDSterilizeSetBody(self._make_body(sterilize_on=False, byte3=4))
        assert off.sterilize is False
        assert off.disinfect is False

    def test_hour_and_minute_always_decoded(self) -> None:
        """Hour and minute are always decoded from body[4/5]."""
        parsed = CDSterilizeSetBody(
            self._make_body(sterilize_on=True, byte3=132, hour=3, minute=30),
        )
        assert parsed.auto_sterilize_hour == 3
        assert parsed.auto_sterilize_minute == 30

    def test_invalid_echo_minute_is_read_raw(self) -> None:
        """SET echoes with impossible minute values are exposed exactly as read."""
        parsed = CDSterilizeSetBody(
            self._make_body(sterilize_on=True, byte3=4, hour=18, minute=86),
        )
        assert parsed.auto_sterilize_week == 4
        assert parsed.auto_sterilize_hour == 18
        assert parsed.auto_sterilize_minute == 86

    def test_disinfect_temp_min_constant(self) -> None:
        """DISINFECT_TEMP_MIN is 60.0."""
        assert MessageSetSterilize.DISINFECT_TEMP_MIN == 60.0

    def test_disinfect_temp_max_constant(self) -> None:
        """DISINFECT_TEMP_MAX is 70.0."""
        assert MessageSetSterilize.DISINFECT_TEMP_MAX == 70.0


class TestMessageSetSterilize:
    """Test MessageSetSterilize body construction."""

    def test_default_body_uses_week(self) -> None:
        """Default construction uses week value 0 in body[3]."""
        msg = MessageSetSterilize(protocol_version=1)
        body = msg.body
        # body[0]=0x06 (body_type), body[1]=0x01, body[2]=0x00 (off), body[3]=week
        assert body[0] == 0x06
        assert body[1] == 0x01
        assert body[2] == 0x00
        assert body[3] == 0x00

    def test_sterilize_on_sets_byte2(self) -> None:
        """sterilize_on=True sets body[2]=0x80."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.sterilize_on = True
        assert msg.body[2] == 0x80

    def test_extended_body_appends_direct_temperature(self) -> None:
        """Recognised new models use NetHome's seventh direct-Celsius byte."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.extended_body = True
        msg.week = 4
        msg.hour = 14
        msg.minute = 5
        msg.disinfection_temperature = 67.0
        assert msg.body == bytearray([0x06, 0x01, 0x00, 4, 14, 5, 67])

    def test_week_value_sent_when_no_temperature(self) -> None:
        """Week value is placed in body[3] when disinfection_temperature is None."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.week = 4
        assert msg.body[3] == 4

    def test_disinfection_temperature_does_not_override_week(self) -> None:
        """SET payload keeps body[3] as week even when temperature is known."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.week = 4
        msg.disinfection_temperature = 67.0
        assert msg.body[3] == 4

    def test_disinfection_temperature_60_is_not_encoded(self) -> None:
        """60C is read/diagnostic state only; SET still sends week."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.week = 4
        msg.disinfection_temperature = 60.0
        assert msg.body[3] == 4

    def test_disinfection_temperature_70_is_not_encoded(self) -> None:
        """70C is read/diagnostic state only; SET still sends week."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.week = 4
        msg.disinfection_temperature = 70.0
        assert msg.body[3] == 4

    def test_disinfection_temperature_below_min_is_not_encoded(self) -> None:
        """Out-of-range temperature state cannot affect SET schedule bytes."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.week = 4
        msg.disinfection_temperature = 50.0
        assert msg.body[3] == 4

    def test_disinfection_temperature_above_max_is_not_encoded(self) -> None:
        """Out-of-range temperature state cannot affect SET schedule bytes."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.week = 4
        msg.disinfection_temperature = 80.0
        assert msg.body[3] == 4

    def test_week_value_is_clamped_to_valid_range(self) -> None:
        """Week fallback cannot exceed the known weekday range."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.week = 200
        assert msg.body[3] == 6
        msg.week = -5
        assert msg.body[3] == 0

    def test_hour_minute_always_in_body(self) -> None:
        """Hour and minute are placed in body[4] and body[5]."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.hour = 3
        msg.minute = 30
        assert msg.body[4] == 3
        assert msg.body[5] == 30

    def test_hour_minute_are_clamped_to_valid_range(self) -> None:
        """Direct message use clamps auto-sterilize time fields."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.hour = 30
        msg.minute = 99
        assert msg.body[4] == 23
        assert msg.body[5] == 59
        msg.hour = -1
        msg.minute = -1
        assert msg.body[4] == 0
        assert msg.body[5] == 0

    def test_setting_none_disinfection_temperature_restores_week(self) -> None:
        """Resetting disinfection_temperature to None sends week value again."""
        msg = MessageSetSterilize(protocol_version=1)
        msg.week = 4
        msg.disinfection_temperature = 65.0
        assert msg.body[3] == 4
        msg.disinfection_temperature = None
        assert msg.body[3] == 4  # week restored


class TestMessageSetRsjracBody:
    """Regression tests for CD controlType=0x01 25-byte SET body (#468)."""

    def test_body_length_is_25_with_type(self) -> None:
        """MessageSet.body is body_type + 24-byte payload."""
        msg = MessageSet(protocol_version=8)
        msg.power = True
        msg.mode = 0x02
        msg.target_temperature = 63
        msg.use_old_protocol = False
        msg.ts_max = 65
        body = msg.body
        assert len(body) == 25
        assert body[0] == 0x01
        assert body[4] == 63
        assert body[23] == 65
        assert body[24] == 0

    def test_ts_max_zero_falls_back(self) -> None:
        """Zero tsMax falls back to the default (never emitted as 0)."""
        msg = MessageSet(protocol_version=8)
        msg.power = True
        msg.mode = 0x01
        msg.target_temperature = 60
        msg.use_old_protocol = False
        msg.ts_max = 0
        assert msg.body[23] == MessageSet.DEFAULT_TS_MAX

    def test_ts_max_unparseable_falls_back(self) -> None:
        """A non-numeric tsMax falls back to the default instead of raising."""
        msg = MessageSet(protocol_version=8)
        msg.power = True
        msg.mode = 0x01
        msg.target_temperature = 60
        msg.use_old_protocol = False
        bad_ts_max: Any = "abc"
        msg.ts_max = bad_ts_max
        assert msg.body[23] == MessageSet.DEFAULT_TS_MAX

    def test_tr_clamped(self) -> None:
        """Out-of-range Tr is clamped to default 5."""
        msg = MessageSet(protocol_version=8)
        msg.power = True
        msg.mode = 0x01
        msg.target_temperature = 60
        msg.use_old_protocol = False
        msg.ts_max = 65
        msg.fields = {"trValue": 13}
        assert msg.body[5] == 5

    def test_open_ptc_forced_zero(self) -> None:
        """Normal sets force openPTC=0 even if fields claim otherwise."""
        msg = MessageSet(protocol_version=8)
        msg.power = True
        msg.mode = 0x02
        msg.target_temperature = 63
        msg.use_old_protocol = False
        msg.ts_max = 65
        msg.fields = {"openPTC": 1, "trValue": 5}
        assert msg.body[6] == 0

    def test_vacation_days_in_body(self) -> None:
        """Vacation SET encodes days in full[9..10]."""
        msg = MessageSet(protocol_version=8)
        msg.power = True
        msg.mode = 0x01
        msg.target_temperature = 50
        msg.use_old_protocol = False
        msg.ts_max = 65
        msg.vacation_flag = True
        msg.vacation_days = 30
        msg.vacation_temperature = 50
        body = msg.body
        assert body[9] == 0
        assert body[10] == 30
        assert body[21] == 50
        assert body[23] == 65


class TestCDGeneralMessageBodySynthetic:
    """Test CDGeneralMessageBody branches with synthetic bodies."""

    def _body(self) -> bytearray:
        body = bytearray(63)
        body[0] = 0x01
        return body

    def test_compatibilizing_mode(self) -> None:
        """body[2] bit 0x08 maps to mode 0x03."""
        body = self._body()
        body[2] = 0x08
        assert CDGeneralMessageBody(body).mode == 0x03

    def test_wind_low(self) -> None:
        """body[27] bit 0x40 maps to low wind."""
        body = self._body()
        body[27] = 0x40
        assert CDGeneralMessageBody(body).wind == "low"

    def test_wind_high(self) -> None:
        """body[27] bit 0x80 maps to high wind."""
        body = self._body()
        body[27] = 0x80
        assert CDGeneralMessageBody(body).wind == "high"

    def test_smart_mode_flag(self) -> None:
        """body[28] bit 0x20 maps to mode 0x04."""
        body = self._body()
        body[28] = 0x20
        assert CDGeneralMessageBody(body).mode == 0x04

    def test_typeinfo_smart_fallback(self) -> None:
        """A typeinfo of 0x04 without mode flags falls back to Smart."""
        body = self._body()
        body[29] = 0x04
        parsed = CDGeneralMessageBody(body)
        assert parsed.mode == 0x04
        assert parsed.typeinfo == 0x04

    def test_short_vacation_body_has_no_days(self) -> None:
        """Vacation bit without the day bytes leaves vacation_days at 0."""
        body = bytearray(37)
        body[0] = 0x01
        body[35] = 0x01
        parsed = CDGeneralMessageBody(body)
        assert parsed.vacation_mode is True
        assert parsed.mode == 0x05
        assert parsed.vacation_days == 0

    def test_old_length_body_defaults(self) -> None:
        """Old (short) bodies default the extended attributes.

        `water_level` is gated on the actual index it reads
        (`len(body) > 34` for `body[34]`), so a body of length 35 has a
        valid `water_level` while everything else past `NEW_BODY_LENGTH`
        (35) still defaults.
        """
        body = bytearray(35)
        body[0] = 0x01
        parsed = CDGeneralMessageBody(body)
        assert parsed.water_level == 0
        assert parsed.vacation_mode is False
        assert parsed.smart_grid is False
        assert parsed.multi_terminal is False
        assert parsed.fahrenheit is False
        assert parsed.weekly_effects is None
        assert parsed.maintain_warn_tag is False
        assert parsed.mute_effect is False
        assert parsed.auto_sterilize_week is None
        assert parsed.vacation_temperature is None
        assert parsed.disinfection_temperature is None
        assert parsed.sterilize is False

    @pytest.mark.parametrize("length", [30, 31, 32, 33, 34])
    def test_water_level_none_on_boundary_lengths(self, length: int) -> None:
        """Bodies shorter than the `body[34]` read parse safely.

        `water_level` is gated on `len(body) > 34`, so bodies in the
        30-34 length range parse cleanly with `water_level is None`
        instead of raising an `IndexError`.
        """
        body = bytearray(length)
        body[0] = 0x01
        parsed = CDGeneralMessageBody(body)
        assert parsed.water_level is None


class TestCD01MessageBody:
    """Test CD SET echo body (controlType=0x01)."""

    def test_full_echo(self) -> None:
        """A full echo decodes power, mode, fields and vacation days."""
        body = bytearray([0x01, 0x01, 0x01, 0x02, 110, 1, 2, 3, 0x10, 0x01, 0x2C])
        parsed = CD01MessageBody(body)
        assert parsed.power is True
        assert parsed.mode == 0x02
        assert parsed.target_temperature == 110.0
        assert parsed.fields == {
            "trValue": 1,
            "openPTC": 2,
            "ptcTemp": 3,
            "byte8": 0x10,
        }
        assert parsed.vacation_mode is True
        assert parsed.vacation_days == 300

    def test_short_echo_has_no_vacation_days(self) -> None:
        """A short echo without day bytes reports 0 vacation days."""
        body = bytearray([0x01, 0x01, 0x00, 0x01, 100, 0, 0, 0, 0x00])
        parsed = CD01MessageBody(body)
        assert parsed.power is False
        assert parsed.vacation_mode is False
        assert parsed.vacation_days == 0


class TestCDWeeklyScheduleBody:
    """Test CD weekly schedule query response body."""

    def test_full_schedule(self) -> None:
        """A full-length body parses all 7 days and 6 slots."""
        body = bytearray(177)
        body[0] = 0x02
        body[2] = 0x01 | 0x20  # day 0 timers 1 and 6
        body[9] = 10
        body[10] = 20
        body[11] = 45
        body[12] = 2
        parsed = CDWeeklyScheduleBody(body)
        assert parsed.weekly_schedule is not None
        assert parsed.weekly_schedule[0][0] == {
            "effect": True,
            "opentime": 10,
            "closetime": 20,
            "temperature": 45,
            "mode": 2,
        }
        assert parsed.weekly_schedule[0][5]["effect"] is True
        assert parsed.weekly_schedule[6][5]["effect"] is False

    def test_short_body_is_ignored(self) -> None:
        """Short bodies leave the schedule as None."""
        parsed = CDWeeklyScheduleBody(bytearray(50))
        assert parsed.weekly_schedule is None


class TestCDDailyTimerBody:
    """Test CD daily timer query response body."""

    def test_full_timer(self) -> None:
        """A full-length body parses the 6-slot daily programme."""
        body = bytearray(40)
        body[0] = 0x03
        body[2] = 2
        body[3] = 0x01 | 0x80  # timer 1 effect + single_timer_off
        body[4] = 6
        body[5] = 30
        body[6] = 8
        body[7] = 15
        body[8] = 45
        body[9] = 2
        parsed = CDDailyTimerBody(body)
        assert parsed.daily_timer_schedule is not None
        assert parsed.daily_timer_schedule["amount"] == 2
        assert parsed.daily_timer_schedule["single_timer_on"] is False
        assert parsed.daily_timer_schedule["single_timer_off"] is True
        assert parsed.daily_timer_schedule["timers"][0] == {
            "effect": True,
            "openhour": 6,
            "openmin": 30,
            "closehour": 8,
            "closemin": 15,
            "temperature": 45,
            "mode": 2,
        }

    def test_short_body_is_ignored(self) -> None:
        """Short bodies leave the timer schedule as None."""
        parsed = CDDailyTimerBody(bytearray(10))
        assert parsed.daily_timer_schedule is None


def _build_response(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full CD response message."""
    header = bytearray([0xAA, 0x00, 0xCD, 0x00, 0x00, 0x00, 0x00, 0x00])
    header += bytearray([ProtocolVersion.V1, message_type])
    return bytes(header + body + bytearray([0x00]))


class TestMessageCDResponse:
    """Test CD message response body dispatch."""

    def _general_body(self) -> bytearray:
        body = bytearray(63)
        body[0] = 0x01
        body[2] = 0x01  # power on
        return body

    def test_query_general(self) -> None:
        """Query responses with body type 0x01 use the general body."""
        response = MessageCDResponse(
            _build_response(MessageType.query, self._general_body()),
        )
        assert getattr(response, "power", None) is True

    def test_notify2_general(self) -> None:
        """Notify2 responses with body type 0x01 use the general body."""
        response = MessageCDResponse(
            _build_response(MessageType.notify2, self._general_body()),
        )
        assert getattr(response, "power", None) is True

    def test_query_weekly(self) -> None:
        """Query responses with body type 0x02 use the weekly body."""
        body = bytearray(177)
        body[0] = 0x02
        response = MessageCDResponse(_build_response(MessageType.query, body))
        assert getattr(response, "weekly_schedule", None) is not None

    def test_query_daily(self) -> None:
        """Query responses with body type 0x03 use the daily timer body."""
        body = bytearray(40)
        body[0] = 0x03
        response = MessageCDResponse(_build_response(MessageType.query, body))
        assert getattr(response, "daily_timer_schedule", None) is not None

    def test_set_general_echo(self) -> None:
        """Set responses with body type 0x01 use the SET echo body."""
        body = bytearray([0x01, 0x01, 0x01, 0x02, 110, 1, 2, 3, 0x10, 0x00, 30])
        response = MessageCDResponse(_build_response(MessageType.set, body))
        assert getattr(response, "fields", None) == {
            "trValue": 1,
            "openPTC": 2,
            "ptcTemp": 3,
            "byte8": 0x10,
        }

    def test_set_sterilize_echo(self) -> None:
        """Set responses with body type 0x06 use the sterilize echo body."""
        body = bytearray([0x06, 0x01, 0x80, 0x04, 14, 5])
        response = MessageCDResponse(_build_response(MessageType.set, body))
        assert getattr(response, "sterilize", None) is True
        assert getattr(response, "auto_sterilize_week", None) == 4

    def test_unparsed_query_body_type(self) -> None:
        """Query responses with an unknown body type stay undecoded."""
        body = bytearray(63)
        body[0] = 0x04
        response = MessageCDResponse(_build_response(MessageType.query, body))
        assert getattr(response, "power", None) is None

    def test_unparsed_set_body_type(self) -> None:
        """Set responses with an unknown body type stay undecoded."""
        body = bytearray(63)
        body[0] = 0x07
        response = MessageCDResponse(_build_response(MessageType.set, body))
        assert getattr(response, "power", None) is None
