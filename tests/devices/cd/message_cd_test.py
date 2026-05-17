"""Test CD message."""

from midealocal.devices.cd.message import (
    CDGeneralMessageBody,
    CDSterilizeSetBody,
    MessageSetSterilize,
)


class TestCDGeneralMessageBody:
    """Test CDGeneralMessageBody parsing of real-device status bytes."""

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
