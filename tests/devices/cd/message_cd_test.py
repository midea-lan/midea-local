"""Test CD message."""

from midealocal.devices.cd.message import (
    CDSterilizeSetBody,
    MessageSetSterilize,
)


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
                byte3,  # week bitmap OR celsius×2 temperature echo
                hour,
                minute,
            ],
        )

    # --- temperature echo (body[3] > 127) ---

    def test_temp_echo_on_sets_disinfection_temperature(self) -> None:
        """body[3]=132 (66°C×2, >127) when sterilize ON → disinfection_temperature=66.0."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=132))
        assert parsed.disinfection_temperature == 66.0

    def test_temp_echo_on_does_not_set_auto_sterilize_week(self) -> None:
        """body[3]=132 (>127) when sterilize ON → auto_sterilize_week stays None (not 132)."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=132))
        # Must NOT be stored as week bitmap – 132 is not a valid 7-bit value
        assert parsed.auto_sterilize_week is None

    def test_temp_echo_off_does_not_set_disinfection_temperature(self) -> None:
        """body[3]=132 (>127) when sterilize OFF → disinfection_temperature stays None."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=False, byte3=132))
        assert parsed.disinfection_temperature is None

    def test_temp_echo_off_does_not_set_auto_sterilize_week(self) -> None:
        """body[3]=132 (>127) when sterilize OFF → auto_sterilize_week stays None."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=False, byte3=132))
        assert parsed.auto_sterilize_week is None

    def test_temp_echo_out_of_range_high(self) -> None:
        """body[3]=145 (72.5°C×2, >127 but above max 70°C) → disinfection_temperature=None."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=145))
        assert parsed.disinfection_temperature is None
        assert parsed.auto_sterilize_week is None

    def test_temp_echo_boundary_min(self) -> None:
        """body[3]=128 (64°C×2, >127) → disinfection_temperature=64.0 (within [60,70])."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=128))
        assert parsed.disinfection_temperature == 64.0
        assert parsed.auto_sterilize_week is None

    def test_temp_echo_boundary_max(self) -> None:
        """body[3]=140 (70°C×2, >127) → disinfection_temperature=70.0 (at max)."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=140))
        assert parsed.disinfection_temperature == 70.0
        assert parsed.auto_sterilize_week is None

    # --- week bitmap (body[3] ≤ 127) ---

    def test_week_bitmap_sets_auto_sterilize_week(self) -> None:
        """body[3]=12 (week bitmap ≤127) → auto_sterilize_week=12, not temperature."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=12))
        assert parsed.auto_sterilize_week == 12
        assert parsed.disinfection_temperature is None

    def test_week_bitmap_zero_sets_auto_sterilize_week(self) -> None:
        """body[3]=0 (no days scheduled) → auto_sterilize_week=0."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=0))
        assert parsed.auto_sterilize_week == 0
        assert parsed.disinfection_temperature is None

    def test_week_bitmap_boundary(self) -> None:
        """body[3]=127 (all 7 days, maximum week bitmap) → stored as week bitmap."""
        parsed = CDSterilizeSetBody(self._make_body(sterilize_on=False, byte3=127))
        assert parsed.auto_sterilize_week == 127
        assert parsed.disinfection_temperature is None

    def test_disinfect_flag_matches_sterilize(self) -> None:
        """disinfect attribute mirrors sterilize_on regardless of body[3]."""
        on = CDSterilizeSetBody(self._make_body(sterilize_on=True, byte3=12))
        assert on.sterilize is True
        assert on.disinfect is True
        off = CDSterilizeSetBody(self._make_body(sterilize_on=False, byte3=12))
        assert off.sterilize is False
        assert off.disinfect is False

    def test_hour_and_minute_always_decoded(self) -> None:
        """auto_sterilize_hour and auto_sterilize_minute are always decoded from body[4/5]."""
        parsed = CDSterilizeSetBody(
            self._make_body(sterilize_on=True, byte3=132, hour=3, minute=30),
        )
        assert parsed.auto_sterilize_hour == 3
        assert parsed.auto_sterilize_minute == 30

    def test_disinfect_temp_min_constant(self) -> None:
        """DISINFECT_TEMP_MIN is 60.0."""
        assert MessageSetSterilize.DISINFECT_TEMP_MIN == 60.0  # noqa: PLR2004

    def test_disinfect_temp_max_constant(self) -> None:
        """DISINFECT_TEMP_MAX is 70.0."""
        assert MessageSetSterilize.DISINFECT_TEMP_MAX == 70.0  # noqa: PLR2004
