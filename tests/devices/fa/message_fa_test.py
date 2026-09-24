"""Test FA message."""

import pytest

from midealan.const import ProtocolVersion
from midealan.devices.fa.message import (
    FA_MESSAGE_PROTOCOL_V6,
    MAX_V6_FAN_SPEED,
    V6_DEFAULT_SWING_ANGLE,
    V6_DEFAULT_SWING_ANGLE_CODE,
    V6_MAX_NORMAL_SWING_ANGLE,
    FAGeneralMessageBody,
    MessageFABase,
    MessageFAResponse,
    MessageNewSet,
    MessageQuery,
    MessageSet,
    MessageV6Set,
    _get_bits,
    _new_angle_to_code,
    _parse_temperature,
    _value_to_code,
)
from midealan.message import ListTypes, MessageType

SHORT_BODY_LENGTH = 18
LONG_BODY_LENGTH = 49


def _build_message(
    protocol_version: int,
    message_type: MessageType,
    body: bytearray,
) -> bytes:
    """Build a full FA response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [protocol_version] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMessageFABase:
    """Test FA Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageFABase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test FA Message Query."""

    def test_query_body(self) -> None:
        """Test query body is empty."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([])
        assert msg._body == bytearray([])


class TestMessageSet:
    """Test FA Message Set."""

    @pytest.mark.parametrize(
        ("subtype", "length", "byte13"),
        [
            (1, SHORT_BODY_LENGTH, 0xFF),
            (ListTypes.X0A, SHORT_BODY_LENGTH, 0x00),
            (ListTypes.A1, SHORT_BODY_LENGTH, 0xFF),
            (0, LONG_BODY_LENGTH, 0x00),
            (ListTypes.X0B, LONG_BODY_LENGTH, 0x00),
        ],
    )
    def test_body_subtypes(self, subtype: int, length: int, byte13: int) -> None:
        """Test set body length and marker depending on subtype."""
        msg = MessageSet(ProtocolVersion.V1, subtype)
        body = msg._body
        assert len(body) == length
        assert body[13] == byte13

    @pytest.mark.parametrize(
        ("power", "expected"),
        [(True, 1), (False, 0)],
    )
    def test_body_power(self, power: bool, expected: int) -> None:
        """Test set body power."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.power = power
        assert msg._body[3] == expected

    @pytest.mark.parametrize(
        ("lock", "expected"),
        [(True, 1), (False, 2)],
    )
    def test_body_lock(self, lock: bool, expected: int) -> None:
        """Test set body lock."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.lock = lock
        assert msg.lock is lock
        assert msg._body[2] == expected

    @pytest.mark.parametrize(
        ("mode", "expected"),
        [
            (3, 0x07),  # Sleep
            (11, 0x17),  # Customize
        ],
    )
    def test_body_mode(self, mode: int, expected: int) -> None:
        """Test set body mode."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.mode = mode
        assert msg._body[3] == expected

    def test_body_fan_speed_valid(self) -> None:
        """Test set body with a valid fan speed."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.fan_speed = 26
        assert msg._body[4] == 26

    def test_body_fan_speed_invalid(self) -> None:
        """Test set body with an out-of-range fan speed."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.fan_speed = 27
        assert msg._body[4] == 0

    def test_body_legacy_controls_match_lua_layout(self) -> None:
        """Test legacy controls use the T_0000_FA_17.lua offsets."""
        msg = MessageSet(ProtocolVersion.V1, 0)
        msg.voice = "open_buzzer"
        msg.target_temperature = 25
        msg.humidity = 50
        msg.anophelifuge = True
        msg.anion = True
        msg.body_feeling_scan = True
        msg.scene = "sleep"

        body = msg._body
        assert body[1] == 4
        assert body[5] == 66
        assert body[6] == 50
        assert body[8] == 0x05
        assert body[14] == 1
        assert body[15] == 4

    def test_body_legacy_controls_support_off_values(self) -> None:
        """Test legacy boolean controls encode their Lua off values."""
        msg = MessageSet(ProtocolVersion.V1, 0)
        msg.anophelifuge = False
        msg.anion = False
        msg.body_feeling_scan = False

        body = msg._body
        assert body[8] == 0x0A
        assert body[14] == 2

    def test_body_legacy_controls_ignore_invalid_enum_and_temperature(self) -> None:
        """Test legacy controls omit values rejected by the Lua protocol."""
        msg = MessageSet(ProtocolVersion.V1, 0)
        msg.voice = "unknown"
        msg.target_temperature = 51
        msg.humidity = 0
        msg.scene = "unknown"

        body = msg._body
        assert body[1] == 0
        assert body[5] == 0
        assert body[6] == 0
        assert body[15] == 0

        msg.target_temperature = -41
        assert msg._body[5] == 0

    @pytest.mark.parametrize(
        ("oscillate", "expected"),
        [(True, 1), (False, 0)],
    )
    def test_body_oscillate(self, oscillate: bool, expected: int) -> None:
        """Test set body oscillate."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.oscillate = oscillate
        assert msg._body[7] == expected

    def test_body_oscillation_angle(self) -> None:
        """Test set body oscillation angle."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.oscillation_angle = 3
        assert msg._body[7] == 0xB1

    def test_body_oscillation_mode(self) -> None:
        """Test set body oscillation mode."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.oscillation_mode = 2
        assert msg._body[7] == 0x85

    def test_body_tilting_angle_long_body(self) -> None:
        """Test set body tilting angle with a long body."""
        msg = MessageSet(ProtocolVersion.V1, 0)
        msg.tilting_angle = 5
        assert msg._body[24] == 5

    def test_body_tilting_angle_short_body(self) -> None:
        """Test set body tilting angle is skipped with a short body."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.tilting_angle = 5
        assert len(msg._body) == SHORT_BODY_LENGTH

    @pytest.mark.parametrize(
        ("humidify", "expected"),
        [(True, 0x20), (False, 0x10)],
    )
    def test_body_humidify(self, humidify: bool, expected: int) -> None:
        """Test set body humidify."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.humidify = humidify
        assert msg._body[8] == expected

    @pytest.mark.parametrize(
        ("waterions", "expected"),
        [(True, 0x01), (False, 0x02)],
    )
    def test_body_waterions(self, waterions: bool, expected: int) -> None:
        """Test set body waterions with a long body."""
        msg = MessageSet(ProtocolVersion.V1, 0)
        msg.waterions = waterions
        assert msg._body[33] == expected

    @pytest.mark.parametrize(
        ("display", "expected"),
        [(True, 0x40), (False, 0x80)],
    )
    def test_body_display(self, display: bool, expected: int) -> None:
        """Test set body display with a long body."""
        msg = MessageSet(ProtocolVersion.V1, 0)
        msg.display_on_off = display
        assert msg._body[18] == expected

    def test_serialize(self) -> None:
        """Test set message serializes."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.power = True
        assert len(msg.serialize()) > 0


class TestMessageNewSet:
    """Test the FA protocol v5 set message."""

    def test_body_controls_match_lua_layout(self) -> None:
        """Test the v5 control fields and offsets from the Lua protocol."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)
        msg.power = True
        msg.voice = "open_buzzer"
        msg.child_lock = True
        msg.mode = 3
        msg.fan_speed = 3
        msg.target_temperature = 25
        msg.humidity = 50
        msg.oscillate = True
        msg.oscillation_mode = "both"
        msg.oscillation_angle = 60
        msg.tilting_angle = 60
        msg.humidify = True
        msg.anophelifuge = True
        msg.anion = True
        msg.body_feeling_scan = True
        msg.scene = "sleep"
        msg.auto_power_off = True
        msg.display_on_off = True
        msg.waterions = True

        body = msg._body
        assert body[1] == 4
        assert body[2] == 1
        assert body[3] == 0x07
        assert body[4] == 3
        assert body[5] == 66
        assert body[6] == 50
        assert body[7] == 0x0C
        assert body[8] == 0x35
        assert body[14] == 1
        assert body[15] == 4
        assert body[18] == 0x40
        assert body[22] == 5
        assert body[23] == 0x40
        assert body[33] == 1
        assert body[50] == 12

    def test_body_mode_only_clears_invalid_marker(self) -> None:
        """Test a mode-only command marks the mode byte as valid."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)
        msg.mode = 3

        assert msg._body[3] == 0x06

    def test_body_invalid_controls_are_omitted(self) -> None:
        """Test invalid v5 controls do not write out-of-range values."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)
        msg.voice = "unknown"
        msg.fan_speed = 27
        msg.target_temperature = 51
        msg.humidity = 0
        msg.oscillation_angle = "invalid"
        msg.tilting_angle = -1
        msg.scene = "unknown"

        body = msg._body
        assert body[1] == 0
        assert body[4] == 0
        assert body[5] == 0
        assert body[6] == 0
        assert body[15] == 0

    def test_body_optional_control_variants(self) -> None:
        """Test special temperature, enum, and non-boolean control values."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)
        msg.voice = 1
        msg.target_temperature = 0x80
        msg.oscillation_mode = "invalid"
        msg.oscillation_angle = "off"
        msg.tilting_angle = "off"
        msg.humidify = 4

        body = msg._body
        assert body[1] == 1
        assert body[5] == 0x80
        assert body[8] == 0x40
        assert body[50] == 0
        assert body[24] == 0

    def test_body_defaults_match_lua_layout(self) -> None:
        """Test protocol marker and invalid-control defaults."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)

        assert len(msg._body) == 51
        assert msg._body[3] == 0x80
        assert msg._body[7] == 0x80
        assert msg._body[22] == 5
        assert msg._body[50] == 0

    def test_body_oscillation_on_matches_lua_layout(self) -> None:
        """Test the v5 oscillation enable command."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)
        msg.oscillate = True
        msg.oscillation_mode = "oscillation"
        msg.oscillation_angle = 1275

        assert msg._body[7] == 0x02
        assert msg._body[50] == 0xFF

    def test_body_oscillation_off_matches_lua_layout(self) -> None:
        """Test the v5 oscillation disable command."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)
        msg.oscillate = False
        msg.oscillation_mode = "oscillation"
        msg.oscillation_angle = 0

        assert msg._body[7] == 0x02
        assert msg._body[50] == 0

    def test_helper_edge_cases(self) -> None:
        """Test protocol helper edge cases."""
        assert _get_bits(bytearray(), 0, 0, 1) == 0
        assert _parse_temperature(0x80) == 0x80
        assert _parse_temperature(0) is None
        assert _value_to_code(True, {}) == 1
        assert _value_to_code(4, {}) == 4
        assert _value_to_code("unknown", {1: "known"}) is None
        assert _new_angle_to_code("off") == 0
        assert _new_angle_to_code(V6_DEFAULT_SWING_ANGLE) == (
            V6_DEFAULT_SWING_ANGLE_CODE
        )
        assert _new_angle_to_code("invalid") is None
        assert _new_angle_to_code("60") == 12
        assert _new_angle_to_code(1280) is None
        assert _new_angle_to_code(1270, max_angle=V6_MAX_NORMAL_SWING_ANGLE) is None
        assert _new_angle_to_code(1269, max_angle=V6_MAX_NORMAL_SWING_ANGLE) == 253
        assert _new_angle_to_code("60", {1: "60"}) == 1

    def test_body_horizontal_angle_sets_default_direction(self) -> None:
        """Test a horizontal angle uses the Lua lr direction."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)
        msg.oscillation_mode = "oscillation"
        msg.oscillation_angle = 60

        assert msg._body[7] == 0x02
        assert msg._body[50] == 12

    def test_body_vertical_angle_sets_default_direction(self) -> None:
        """Test a vertical angle uses the Lua ud direction."""
        msg = MessageNewSet(ProtocolVersion.V1, 0)
        msg.oscillation_mode = "tilting"
        msg.tilting_angle = 60

        assert msg._body[7] == 0x04
        assert msg._body[24] == 12


class TestMessageV6Set:
    """Test the FA protocol v6 set message."""

    def test_body_fan_speed_supports_lua_range(self) -> None:
        """Test v6 accepts the Lua-defined 1..100 fan speed range."""
        msg = MessageV6Set(ProtocolVersion.V1, 0)
        msg.fan_speed = MAX_V6_FAN_SPEED

        assert msg._body[4] == MAX_V6_FAN_SPEED

        msg.fan_speed = MAX_V6_FAN_SPEED + 1
        assert msg._body[4] == 0

    def test_body_defaults_match_lua_layout(self) -> None:
        """Test the v6 body length, marker, and invalid defaults."""
        msg = MessageV6Set(ProtocolVersion.V1, 0)

        assert len(msg.body) == 63
        assert len(msg._body) == 62
        assert msg._body[3] == 0x80
        assert msg._body[7] == 0x80
        assert msg._body[22] == FA_MESSAGE_PROTOCOL_V6
        assert msg._body[24] == 0xFF
        assert msg._body[50] == 0xFF

    def test_body_oscillation_on_matches_lua_layout(self) -> None:
        """Test the v6 horizontal oscillation enable command."""
        msg = MessageV6Set(ProtocolVersion.V1, 0)
        msg.oscillate = True
        msg.oscillation_mode = "oscillation"
        msg.oscillation_angle = 1275

        assert msg._body[34] == 0x02
        assert msg._body[50] == 0xFF

    def test_body_oscillation_default_matches_lua_layout(self) -> None:
        """Test the v6 default horizontal oscillation command."""
        msg = MessageV6Set(ProtocolVersion.V1, 0)
        msg.oscillate = True
        msg.oscillation_mode = "oscillation"
        msg.oscillation_angle = V6_DEFAULT_SWING_ANGLE

        assert msg._body[34] == 0x02
        assert msg._body[50] == V6_DEFAULT_SWING_ANGLE_CODE

    def test_body_angle_sets_default_v6_direction(self) -> None:
        """Test v6 angle-only commands set their axis direction."""
        msg = MessageV6Set(ProtocolVersion.V1, 0)
        msg.oscillation_angle = 60

        assert msg._body[34] == 0x02
        assert msg._body[50] == 12

        msg = MessageV6Set(ProtocolVersion.V1, 0)
        msg.tilting_angle = 60

        assert msg._body[34] == 0x08
        assert msg._body[24] == 12

    def test_body_oscillation_off_matches_lua_layout(self) -> None:
        """Test the v6 horizontal oscillation disable command."""
        msg = MessageV6Set(ProtocolVersion.V1, 0)
        msg.oscillate = False
        msg.oscillation_mode = "oscillation"
        msg.oscillation_angle = 0

        assert msg._body[34] == 0x02
        assert msg._body[50] == 0

    def test_body_unsupported_v6_mode_is_omitted(self) -> None:
        """Test unsupported v6 swing modes do not encode as swing off."""
        msg = MessageV6Set(ProtocolVersion.V1, 0)
        msg.oscillation_mode = "curve-w"

        assert msg._body[34] == 0


class TestFAGeneralMessageBody:
    """Test FA general message body."""

    def test_short_body_defaults(self) -> None:
        """Test short body default values."""
        body = FAGeneralMessageBody(bytearray(10))
        assert body.child_lock is False
        assert body.power is False
        assert body.mode == 0
        assert body.fan_speed == 0
        assert body.tilting_angle == 0
        assert body.humidify is False
        assert body.waterions is False
        assert body.display_on_off is False

    def test_legacy_mode_uses_bits_one_through_four(self) -> None:
        """Test legacy mode does not consume the protocol v5 bit."""
        body = bytearray(36)
        body[4] = 0x23  # power on, bit 5 set, legacy mode remains 1

        parsed = FAGeneralMessageBody(body)

        assert parsed.mode == 1

    def test_protocol_v5_body(self) -> None:
        """Test fields and offsets from the model-specific Lua protocol."""
        body = bytearray(52)
        body[3] = 0x01
        body[4] = 0x07
        body[5] = 3
        body[6] = 66
        body[7] = 50
        body[8] = 0x35
        body[9] = 0x30
        body[12] = 55
        body[13] = 66
        body[15] = 1
        body[16] = 4
        body[19] = 0x40
        body[23] = 5
        body[24] = 0x40
        body[25] = 3
        body[34] = 1
        body[51] = 0xFF

        parsed = FAGeneralMessageBody(body)

        assert parsed.protocol_version == 5
        assert parsed.is_new_protocol is True
        assert parsed.child_lock is True
        assert parsed.power is True
        assert parsed.mode == 3
        assert parsed.fan_speed == 3
        assert parsed.target_temperature == 25.0
        assert parsed.humidity == 50
        assert parsed.oscillate is True
        assert parsed.oscillation_mode == 2
        assert parsed.oscillation_angle == 0xFF
        assert parsed.tilting_angle == 3
        assert parsed.humidify is True
        assert parsed.humidify_mode == "1"
        assert parsed.auto_power_off is True
        assert parsed.display_on_off is True
        assert parsed.waterions is True
        assert parsed.humidify_feedback == 55
        assert parsed.temperature_feedback == 25.0
        assert parsed.body_feeling_scan is True
        assert parsed.scene == "sleep"

    def test_protocol_v6_body(self) -> None:
        """Test v6 swing fields use the model-specific Lua offsets."""
        body = bytearray(63)
        body[23] = FA_MESSAGE_PROTOCOL_V6
        body[5] = MAX_V6_FAN_SPEED
        body[25] = 0xFF
        body[35] = 0x02
        body[51] = 0xFF

        parsed = FAGeneralMessageBody(body)

        assert parsed.protocol_version == FA_MESSAGE_PROTOCOL_V6
        assert parsed.is_new_protocol is True
        assert parsed.is_v6_protocol is True
        assert parsed.fan_speed == MAX_V6_FAN_SPEED
        assert parsed.oscillate is False
        assert parsed.oscillation_mode == 0
        assert parsed.oscillation_angle == 0xFF
        assert parsed.tilting_angle == 0xFF

    def test_protocol_v6_body_swing_off(self) -> None:
        """Test a v6 zero angle is decoded as swing off."""
        body = bytearray(63)
        body[23] = FA_MESSAGE_PROTOCOL_V6
        body[35] = 0x02

        parsed = FAGeneralMessageBody(body)

        assert parsed.oscillate is False
        assert parsed.oscillation_mode == 0
        assert parsed.oscillation_angle == 0

    def test_protocol_v6_default_swing_is_active(self) -> None:
        """Test Lua's default swing angle is decoded as active."""
        body = bytearray(63)
        body[23] = FA_MESSAGE_PROTOCOL_V6
        body[51] = 0xFE

        parsed = FAGeneralMessageBody(body)

        assert parsed.oscillate is True
        assert parsed.oscillation_mode == 1
        assert parsed.oscillation_angle == 0xFE

    @pytest.mark.parametrize(
        ("swing_byte", "swing_angle", "tilting_angle", "expected_mode"),
        [
            (0x01, 0xFF, 0xFF, 7),
            (0x0A, 12, 12, 6),
            (0x08, 0, 12, 2),
        ],
    )
    def test_protocol_v6_swing_mode_branches(
        self,
        swing_byte: int,
        swing_angle: int,
        tilting_angle: int,
        expected_mode: int,
    ) -> None:
        """Test v6 DIY, both-axis, and vertical-only swing modes."""
        body = bytearray(63)
        body[23] = FA_MESSAGE_PROTOCOL_V6
        body[25] = tilting_angle
        body[35] = swing_byte
        body[51] = swing_angle

        parsed = FAGeneralMessageBody(body)

        assert parsed.oscillate is True
        assert parsed.oscillation_mode == expected_mode


class TestMessageFAResponse:
    """Test FA message response."""

    def test_query_response(self) -> None:
        """Test query response parses the general body."""
        body = bytearray(36)
        body[3] = 0x01
        body[4] = 0x03
        body[5] = 0x03
        msg = MessageFAResponse(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )
        assert getattr(msg, "power", None) is True
        assert getattr(msg, "child_lock", None) is True
        assert getattr(msg, "mode", None) == 1
        assert getattr(msg, "fan_speed", None) == 3

    def test_notify2_response_ignored(self) -> None:
        """Test notify2 response is not parsed."""
        body = bytearray(10)
        msg = MessageFAResponse(
            _build_message(ProtocolVersion.V1, MessageType.notify2, body),
        )
        assert not hasattr(msg, "power")

    def test_protocol_v5_response(self) -> None:
        """Test a protocol v5 response uses the extended body parser."""
        body = bytearray(52)
        body[4] = 0x07
        body[5] = 3
        body[23] = 5
        body[51] = 0x03

        msg = MessageFAResponse(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert msg.protocol_version == 5
        assert getattr(msg, "oscillate", None) is True
        assert getattr(msg, "oscillation_angle", None) == 3
        assert getattr(msg, "tilting_angle", None) == 0

    def test_protocol_v6_response(self) -> None:
        """Test a protocol v6 response uses the extended body parser."""
        body = bytearray(63)
        body[23] = FA_MESSAGE_PROTOCOL_V6
        body[35] = 0x02
        body[51] = 0x0C

        msg = MessageFAResponse(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert msg.protocol_version == FA_MESSAGE_PROTOCOL_V6
        assert getattr(msg, "is_v6_protocol", False) is True
        assert getattr(msg, "oscillate", None) is True
        assert getattr(msg, "oscillation_angle", None) == 0x0C

    def test_protocol_v6_default_swing_response(self) -> None:
        """Test the real v6 default swing response shape."""
        body = bytearray(63)
        body[23] = FA_MESSAGE_PROTOCOL_V6
        body[51] = 0xFE

        msg = MessageFAResponse(
            _build_message(ProtocolVersion.V1, MessageType.query, body),
        )

        assert getattr(msg, "oscillate", None) is True
        assert getattr(msg, "oscillation_mode", None) == 1
        assert getattr(msg, "oscillation_angle", None) == 0xFE
