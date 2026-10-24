"""Tests for Toshiba IoLife x0008ac message module."""

import pytest

from midealocal.crc8 import calculate as crc8_854
from midealocal.devices.x0008ac.message import (
    _C0_BODY_MIN_LEN,
    _MSG_TYPE_QUERY,
    MessageQuery,
    MessageSet,
    ToshibaIolifeA1Body,
    ToshibaIolifeB0Body,
    ToshibaIolifeB5Body,
    ToshibaIolifeC0Body,
    _assemble_frame,
    _decode_temp,
    _parse_frame,
    parse_ac_response,
)

# Property IDs referenced in set-command assertions
_PROP_POWER = 0x0001
_PROP_MODE = 0x0002
_PROP_TARGET_TEMP = 0x0003
_PROP_INDOOR_TEMP = 0x0004
_PROP_OUTDOOR_TEMP = 0x0005


def _make_frame(body: list[int], msg_type: int = _MSG_TYPE_QUERY) -> bytes:
    return bytes(_assemble_frame(body, msg_type))


class TestDecodeTemp:
    """Tests for _decode_temp."""

    def test_valid_positive(self) -> None:
        """Return (raw - 50) / 2 + 0.1 * decimal for a positive temperature."""
        # (100 - 50) / 2 + 0.1 * 3 = 25.3
        assert _decode_temp(100, 3) == pytest.approx(25.3)

    def test_valid_negative(self) -> None:
        """Return a negative value when raw puts the temp below zero."""
        # (40 - 50) / 2 + 0.1 * 3 = -4.7
        assert _decode_temp(40, 3) == pytest.approx(-4.7)

    def test_zero_decimal(self) -> None:
        """Return exact half-degree when decimal nibble is 0."""
        assert _decode_temp(100, 0) == pytest.approx(25.0)

    def test_invalid_sentinel_low(self) -> None:
        """Return None for raw value 0x00 (not-installed sentinel)."""
        assert _decode_temp(0x00, 0) is None

    def test_invalid_sentinel_high(self) -> None:
        """Return None for raw value 0xFF (not-installed sentinel)."""
        assert _decode_temp(0xFF, 0) is None


class TestFrameValidation:
    """Tests for the _parse_frame guards, reached through parse_ac_response."""

    def test_bad_magic_raises(self) -> None:
        """A frame that does not start with the Toshiba magic is rejected."""
        frame = bytearray(_assemble_frame([0xC0, *([0] * 27)], _MSG_TYPE_QUERY))
        frame[0] = 0x00
        with pytest.raises(ValueError, match="Bad frame magic"):
            _parse_frame(bytes(frame))

    def test_crc_mismatch_raises(self) -> None:
        """A frame whose CRC-16 does not match its body is rejected."""
        frame = bytearray(_assemble_frame([0xC0, *([0] * 27)], _MSG_TYPE_QUERY))
        frame[-1] ^= 0xFF
        with pytest.raises(ValueError, match="CRC mismatch"):
            _parse_frame(bytes(frame))

    def test_parse_ac_response_swallows_bad_frames(self) -> None:
        """parse_ac_response returns None rather than raising on a bad frame."""
        frame = bytearray(_assemble_frame([0xC0, *([0] * 27)], _MSG_TYPE_QUERY))
        frame[-1] ^= 0xFF
        assert parse_ac_response(bytes(frame)) is None

    def test_unknown_body_type_returns_none(self) -> None:
        """A frame whose body type has no parser is ignored, not fatal."""
        frame = _assemble_frame([0xFF, *([0] * 27)], _MSG_TYPE_QUERY)
        assert parse_ac_response(bytes(frame)) is None

    def test_empty_body_returns_none(self) -> None:
        """A well-formed frame carrying no body at all is ignored."""
        frame = _assemble_frame([], _MSG_TYPE_QUERY)
        assert parse_ac_response(bytes(frame)) is None


class TestRequestPlaceholders:
    """The base class requires header/_body; the Toshiba frame is built in serialize."""

    @pytest.mark.parametrize("request_class", [MessageQuery, MessageSet])
    def test_header_and_body_are_empty(
        self,
        request_class: type[MessageQuery] | type[MessageSet],
    ) -> None:
        """Both placeholders return an empty bytearray."""
        message = request_class()
        assert message.header == bytearray([])
        assert message._body == bytearray([])


class TestAssembleAndParseFrame:
    """Tests for _assemble_frame and _parse_frame."""

    def test_magic_bytes(self) -> None:
        """Assembled frame begins with the 4-byte Toshiba magic prefix."""
        frame = _make_frame([0xC0] + [0] * 21)
        assert frame[:4] == bytes([0x55, 0xAA, 0xCC, 0x33])

    def test_device_byte_is_ac(self) -> None:
        """Device class byte at offset 7 is always 0xAC."""
        frame = _make_frame([0xC0] + [0] * 21)
        assert frame[7] == 0xAC

    def test_body_round_trip(self) -> None:
        """Body parsed from an assembled frame matches the original body."""
        body = [0xC0, 0x01, 0x10, 0x64] + [0] * 18
        frame = _make_frame(body)
        _msg_type, parsed_body = _parse_frame(frame)
        assert list(parsed_body) == body

    def test_msg_type_in_frame(self) -> None:
        """Msg-type word is stored little-endian at frame[14:16]."""
        frame = _make_frame([0xC0] + [0] * 21, msg_type=0x0002)
        assert frame[14] == 0x02
        assert frame[15] == 0x00

    def test_too_short_raises(self) -> None:
        """_parse_frame raises ValueError for frames shorter than the minimum."""
        with pytest.raises(ValueError, match="Frame too short"):
            _parse_frame(b"\x55\xaa\xcc\x33")


class TestMessageQuery:
    """Tests for MessageQuery serialization."""

    def test_fixed_body_bytes(self) -> None:
        """Query body starts with the fixed 0x41 0x81 0x00 0xFF header."""
        frame = MessageQuery().serialize()
        # body starts at frame[16]: 0x41, 0x81, 0x00, 0xFF
        assert frame[16] == 0x41
        assert frame[17] == 0x81
        assert frame[18] == 0x00
        assert frame[19] == 0xFF

    def test_msg_type_is_query(self) -> None:
        """Msg-type word encodes _MSG_TYPE_QUERY (0x0003)."""
        frame = MessageQuery().serialize()
        assert frame[14] == 0x03  # _MSG_TYPE_QUERY = 0x0003
        assert frame[15] == 0x00

    def test_frame_total_length(self) -> None:
        """Serialized query is exactly 40 bytes (16 header + 22 body + 2 CRC16)."""
        assert len(MessageQuery().serialize()) == 40

    def test_seq_in_valid_range(self) -> None:
        """Sequence number is within [1, 254]."""
        frame = MessageQuery().serialize()
        seq = frame[36]  # body[20] = seq
        assert 1 <= seq <= 254

    def test_seq_increments(self) -> None:
        """Each new query increments the global sequence counter."""
        s1 = MessageQuery().serialize()[36]
        s2 = MessageQuery().serialize()[36]
        assert s2 == (s1 % 254) + 1

    def test_crc8_over_body_prefix(self) -> None:
        """Last body byte is the CRC-8 of the first 21 body bytes."""
        frame = MessageQuery().serialize()
        body = list(frame[16:38])  # 22 body bytes
        expected = crc8_854(bytearray(body[:21]))
        assert body[21] == expected


class TestMessageSet:
    """Tests for MessageSet serialization."""

    def test_msg_type_is_set(self) -> None:
        """Msg-type word encodes _MSG_TYPE_SET (0x0002)."""
        cmd = MessageSet()
        cmd.set_param(0x0001, bytearray([1]))
        frame = cmd.serialize()
        assert frame[14] == 0x02  # _MSG_TYPE_SET = 0x0002
        assert frame[15] == 0x00

    def test_body_type_is_b0(self) -> None:
        """SET frame body type byte is 0xB0."""
        cmd = MessageSet()
        cmd.set_param(0x0001, bytearray([1]))
        frame = cmd.serialize()
        assert frame[16] == 0xB0

    def test_power_param_encoded_correctly(self) -> None:
        """Power param is encoded in FOUR-format at frame[18:]."""
        cmd = MessageSet()
        cmd.set_param(_PROP_POWER, bytearray([1]))
        frame = cmd.serialize()
        # FOUR-format: [param_lo, param_hi, len, value] at frame[18:]
        assert frame[17] == 1  # param count
        assert frame[18] == 0x01  # _PROP_POWER low
        assert frame[19] == 0x00  # _PROP_POWER high
        assert frame[20] == 0x01  # length
        assert frame[21] == 0x01  # value=1 (on)

    def test_target_temp_param(self) -> None:
        """Target temperature param ID is 0x03."""
        cmd = MessageSet()
        cmd.set_param(_PROP_TARGET_TEMP, bytearray([int(22.0 * 2)]))  # 44
        frame = cmd.serialize()
        assert frame[18] == 0x03  # _PROP_TARGET_TEMP low
        assert frame[21] == 44

    def test_multiple_params_count(self) -> None:
        """Param count byte reflects the number of set_param calls."""
        cmd = MessageSet()
        cmd.set_param(_PROP_POWER, bytearray([1]))
        cmd.set_param(_PROP_MODE, bytearray([2]))
        frame = cmd.serialize()
        assert frame[17] == 2


class TestParseAcResponse:
    """Tests for parse_ac_response dispatch."""

    def test_c0_dispatches_to_c0_body(self) -> None:
        """0xC0 body type returns a ToshibaIolifeC0Body instance."""
        body = [0] * _C0_BODY_MIN_LEN
        body[0] = 0xC0
        assert isinstance(parse_ac_response(_make_frame(body)), ToshibaIolifeC0Body)

    def test_d0_dispatches_to_c0_body(self) -> None:
        """0xD0 body type also returns a ToshibaIolifeC0Body instance."""
        body = [0] * _C0_BODY_MIN_LEN
        body[0] = 0xD0
        assert isinstance(parse_ac_response(_make_frame(body)), ToshibaIolifeC0Body)

    def test_a1_dispatches_to_a1_body(self) -> None:
        """0xA1 body type returns a ToshibaIolifeA1Body instance."""
        body = [0xA1] + [0] * 18
        assert isinstance(parse_ac_response(_make_frame(body)), ToshibaIolifeA1Body)

    def test_b0_dispatches_to_b0_body(self) -> None:
        """0xB0 body type returns a ToshibaIolifeB0Body instance."""
        body = [0xB0, 0] + [0] * 10
        assert isinstance(parse_ac_response(_make_frame(body)), ToshibaIolifeB0Body)

    def test_b5_dispatches_to_b5_body(self) -> None:
        """0xB5 body type returns a ToshibaIolifeB5Body instance."""
        body = [0xB5, 0] + [0] * 10
        assert isinstance(parse_ac_response(_make_frame(body)), ToshibaIolifeB5Body)

    def test_unknown_body_type_returns_none(self) -> None:
        """Unknown body type returns None."""
        body = [0x99] + [0] * 21
        assert parse_ac_response(_make_frame(body)) is None

    def test_too_short_frame_returns_none(self) -> None:
        """Frame shorter than minimum returns None."""
        assert parse_ac_response(b"\x55\xaa") is None

    def test_c0_body_below_min_len_returns_none(self) -> None:
        """C0 body shorter than _C0_BODY_MIN_LEN returns None."""
        body = [0xC0] + [0] * (_C0_BODY_MIN_LEN - 2)  # one byte short
        assert parse_ac_response(_make_frame(body)) is None


class TestToshibaIolifeC0Body:
    """Tests for C0/D0 status body parsing."""

    @pytest.fixture
    def body(self) -> bytearray:
        """Return a 28-byte C0 body with all fields populated."""
        b = bytearray(28)
        b[0] = 0xC0
        b[1] = 0x01  # power bit → True
        b[2] = 0x10  # mode = (0x10 & 0xF0) >> 4 = 1
        b[3] = 0x64  # fan_speed = 0x64 & 0x7F = 100
        b[4] = 0x2C  # target_temp = (0x2C & 0x7F) / 2.0 = 22.0
        b[10] = 40  # indoor_humidity
        b[11] = 0x12  # swing_vertical=1, swing_horizontal=2
        b[13] = 100  # indoor_raw
        b[14] = 60  # outdoor_raw
        b[15] = 0x23  # decimal nibbles: indoor=3, outdoor=2
        b[16] = 0x07  # eco=1, anion=1, dry=1
        b[17] = 0x20  # full_dust (bit 5)
        b[18] = 0x01  # breezeless on (bit 0)
        b[19] = 0x05  # wind_ud_angle
        b[20] = 0x03  # wind_lr_angle
        b[24] = 0x30  # breezeless direction=3 (右側) in high nibble
        b[21] = 0x17  # energy_save=1, dehumidify=3, comfort_mode=1
        b[23] = 0x05  # error_code (len=28 > _C0_ERROR_MIN_LEN=26)
        return b

    def test_power_on(self, body: bytearray) -> None:
        """Power is True when bit 0 of byte 1 is set."""
        assert ToshibaIolifeC0Body(body).power is True

    def test_power_off(self) -> None:
        """Power is False when byte 1 is zero."""
        body = bytearray([0xC0] + [0] * 21)
        assert ToshibaIolifeC0Body(body).power is False

    def test_mode(self, body: bytearray) -> None:
        """Mode is the upper nibble of byte 2 shifted right by 4."""
        assert ToshibaIolifeC0Body(body).mode == 1

    def test_fan_speed(self, body: bytearray) -> None:
        """fan_speed is byte 3 with the high bit masked off."""
        assert ToshibaIolifeC0Body(body).fan_speed == 100

    def test_target_temperature(self, body: bytearray) -> None:
        """target_temperature is (byte 4 & 0x7F) / 2.0."""
        assert ToshibaIolifeC0Body(body).target_temperature == 22.0

    def test_indoor_humidity(self, body: bytearray) -> None:
        """indoor_humidity comes from byte 10."""
        assert ToshibaIolifeC0Body(body).indoor_humidity == 40

    def test_swing(self, body: bytearray) -> None:
        """swing_vertical and swing_horizontal come from nibbles of byte 11."""
        parsed = ToshibaIolifeC0Body(body)
        assert parsed.swing_vertical == 1
        assert parsed.swing_horizontal == 2

    def test_indoor_temperature(self, body: bytearray) -> None:
        """indoor_temperature is decoded from bytes 13 and the low nibble of byte 15."""
        # (100 - 50) / 2 + 0.1 * 3 = 25.3
        assert ToshibaIolifeC0Body(body).indoor_temperature == pytest.approx(25.3)

    def test_outdoor_temperature(self, body: bytearray) -> None:
        """Outdoor temperature decoded from byte 14 and high nibble of byte 15."""
        # (60 - 50) / 2 + 0.1 * 2 = 5.2
        assert ToshibaIolifeC0Body(body).outdoor_temperature == pytest.approx(5.2)

    def test_outdoor_temp_sentinel_is_none(self, body: bytearray) -> None:
        """outdoor_temperature is None when byte 14 is 0xFF."""
        body[14] = 0xFF
        assert ToshibaIolifeC0Body(body).outdoor_temperature is None

    def test_flags1(self, body: bytearray) -> None:
        """eco_mode, anion, dry, clean_manual, cleaning come from byte 16."""
        parsed = ToshibaIolifeC0Body(body)
        assert parsed.eco_mode is True
        assert parsed.anion is True
        assert parsed.dry is True
        assert parsed.clean_manual is False
        assert parsed.cleaning is False

    def test_clean_bits(self) -> None:
        """clean_manual is bit4 and cleaning is bit5 of byte 16."""
        body = bytearray(28)
        body[0] = 0xC0
        body[16] = 0x22  # 0b00100010: anion=1, cleaning=1 (matches live capture)
        parsed = ToshibaIolifeC0Body(body)
        assert parsed.anion is True
        assert parsed.clean_manual is False
        assert parsed.cleaning is True

    def test_filter_full(self, body: bytearray) -> None:
        """full_dust is True when bit 5 of byte 17 is set."""
        assert ToshibaIolifeC0Body(body).full_dust is True

    def test_breezeless_value(self) -> None:
        """Breezeless is the low nibble of body[18] (Lua no_wind_sense, 0-5)."""
        body = bytearray(28)
        body[0] = 0xC0
        body[18] = 0x03
        assert ToshibaIolifeC0Body(body).breezeless == 3

    def test_breezeless_off(self) -> None:
        """Breezeless is 0 when the low nibble of body[18] is clear."""
        body = bytearray(28)
        body[0] = 0xC0
        body[24] = 0x30  # a different property (0x70) lives here
        assert ToshibaIolifeC0Body(body).breezeless == 0

    def test_breezeless_ignores_byte24(self) -> None:
        """body[24] holds new_no_wind_sense/area, which must not leak in."""
        body = bytearray(28)
        body[0] = 0xC0
        body[18] = 0x01
        body[24] = 0x70  # area=1, new_no_wind_sense=3
        assert ToshibaIolifeC0Body(body).breezeless == 1

    def test_swing_angles(self, body: bytearray) -> None:
        """Swing angle vertical and horizontal come from bytes 19 and 20."""
        parsed = ToshibaIolifeC0Body(body)
        assert parsed.wind_ud_angle == 5
        assert parsed.wind_lr_angle == 3

    def test_flags4(self, body: bytearray) -> None:
        """energy_save, dehumidify, and comfort_mode come from byte 21."""
        parsed = ToshibaIolifeC0Body(body)
        assert parsed.energy_save is True
        assert parsed.dehumidify == 3
        assert parsed.comfort_mode is True

    def test_error_code_present(self, body: bytearray) -> None:
        """error_code comes from byte 23 when the body is long enough."""
        assert ToshibaIolifeC0Body(body).error_code == 5

    def test_error_code_absent_when_body_short(self) -> None:
        """error_code is 0 when the body does not include the error byte."""
        body = bytearray([0xC0] + [0] * 21)  # exactly _C0_BODY_MIN_LEN, no error byte
        assert ToshibaIolifeC0Body(body).error_code == 0


class TestToshibaIolifeA1Body:
    """Tests for A1 temperature notification body."""

    def test_temperatures(self) -> None:
        """Both temperatures are decoded from bytes 13-14 and nibbles of byte 18."""
        body = bytearray(19)
        body[0] = 0xA1
        body[13] = 100  # indoor_raw
        body[14] = 60  # outdoor_raw
        body[18] = 0x23  # decimal: indoor=3, outdoor=2
        parsed = ToshibaIolifeA1Body(body)
        assert parsed.indoor_temperature == pytest.approx(25.3)
        assert parsed.outdoor_temperature == pytest.approx(5.2)

    def test_outdoor_sentinel_is_none(self) -> None:
        """outdoor_temperature is None when byte 14 is 0xFF."""
        body = bytearray(19)
        body[0] = 0xA1
        body[13] = 100
        body[14] = 0xFF  # invalid sentinel
        assert ToshibaIolifeA1Body(body).outdoor_temperature is None

    def test_indoor_sentinel_is_none(self) -> None:
        """indoor_temperature is None when byte 13 is 0x00."""
        body = bytearray(19)
        body[0] = 0xA1
        body[13] = 0x00  # invalid sentinel
        assert ToshibaIolifeA1Body(body).indoor_temperature is None


class TestToshibaIolifeB0Body:
    """Tests for B0 property response body (FIVE-format: 4-byte header per param)."""

    def test_power_and_mode(self) -> None:
        """Power and mode are decoded from FIVE-format params in a B0 body."""
        # Format: [body_type, count, param_lo, param_hi, pad=0x00, len, val...]
        body = bytearray(
            [
                0xB0,
                2,
                0x01,
                0x00,
                0x00,
                0x01,
                0x01,  # _PROP_POWER = True
                0x02,
                0x00,
                0x00,
                0x01,
                0x02,  # _PROP_MODE = 2
            ],
        )
        parsed = ToshibaIolifeB0Body(body)
        assert parsed.power is True
        assert parsed.mode == 2

    def test_target_temperature(self) -> None:
        """target_temperature is value_byte / 2.0 for the 0x0003 param."""
        # value byte 44 → 44 / 2.0 = 22.0
        body = bytearray(
            [
                0xB0,
                1,
                0x03,
                0x00,
                0x00,
                0x01,
                44,
            ],
        )
        assert ToshibaIolifeB0Body(body).target_temperature == 22.0

    def test_indoor_and_outdoor_temperature(self) -> None:
        """Temp props decode as integer + 0.1 * decimal from a 2-byte value."""
        # Temperature props: 2 bytes [integer, decimal] → data[0] + 0.1 * data[1]
        body = bytearray(
            [
                0xB0,
                2,
                0x04,
                0x00,
                0x00,
                0x02,
                25,
                3,  # indoor = 25.3
                0x05,
                0x00,
                0x00,
                0x02,
                5,
                2,  # outdoor = 5.2
            ],
        )
        parsed = ToshibaIolifeB0Body(body)
        assert parsed.indoor_temperature == pytest.approx(25.3)
        assert parsed.outdoor_temperature == pytest.approx(5.2)

    def test_eco_mode(self) -> None:
        """eco_mode is True when param 0x000D value is 0x01."""
        body = bytearray([0xB0, 1, 0x0D, 0x00, 0x00, 0x01, 0x01])
        assert ToshibaIolifeB0Body(body).eco_mode is True


class TestToshibaIolifeB5Body:
    """Tests for B5 property notification body (FOUR-format: 3-byte header)."""

    def test_power_and_mode(self) -> None:
        """Power and mode are decoded from FOUR-format params in a B5 body."""
        # Format: [body_type, count, param_lo, param_hi, len, val...]
        body = bytearray(
            [
                0xB5,
                2,
                0x01,
                0x00,
                0x01,
                0x01,  # _PROP_POWER = True
                0x02,
                0x00,
                0x01,
                0x03,  # _PROP_MODE = 3
            ],
        )
        parsed = ToshibaIolifeB5Body(body)
        assert parsed.power is True
        assert parsed.mode == 3

    def test_target_temperature(self) -> None:
        """target_temperature is value_byte / 2.0 for the 0x0003 param."""
        body = bytearray([0xB5, 1, 0x03, 0x00, 0x01, 44])
        assert ToshibaIolifeB5Body(body).target_temperature == 22.0

    def test_eco_mode(self) -> None:
        """eco_mode is True when param 0x000D value is 0x01."""
        body = bytearray([0xB5, 1, 0x0D, 0x00, 0x01, 0x01])
        assert ToshibaIolifeB5Body(body).eco_mode is True
