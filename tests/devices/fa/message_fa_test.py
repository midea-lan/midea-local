"""Test FA message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.fa.message import (
    PROTOCOL_V5,
    FAGeneralMessageBody,
    MessageFABase,
    MessageFAResponse,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType

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
        assert msg._body[2] == expected

    @pytest.mark.parametrize(
        ("mode", "mode_set_overrides", "expected"),
        [
            pytest.param(2, None, 0x07, id="no_override"),
            pytest.param(3, {3: 0x29}, 0x29, id="override_match"),
            pytest.param(2, {3: 0x29}, 0x07, id="override_not_matching"),
        ],
    )
    def test_body_mode(
        self,
        mode: int,
        mode_set_overrides: dict[int, int] | None,
        expected: int,
    ) -> None:
        """Test set body mode, with and without a customized override table."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.mode = mode
        msg.mode_set_overrides = mode_set_overrides
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

    @pytest.mark.parametrize(
        ("mode", "expected"),
        [
            pytest.param(7, 0x0F, id="storm"),
            pytest.param(20, 0x29, id="self_selection"),
        ],
    )
    def test_body_mode_protocol_v5(self, mode: int, expected: int) -> None:
        """Test set body mode uses the 5-bit raw table index on protocol 5."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.fa_message_protocol = PROTOCOL_V5
        msg.mode = mode
        assert msg._body[3] == expected

    def test_body_voice(self) -> None:
        """Test set body voice."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.voice = 0x04
        assert msg._body[1] == 0x04

    def test_body_target_temperature_valid(self) -> None:
        """Test set body target temperature applies the +41 offset."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.target_temperature = 20
        assert msg._body[5] == 61

    def test_body_target_temperature_out_of_range(self) -> None:
        """Test set body ignores an out-of-range target temperature."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.target_temperature = 51
        assert msg._body[5] == 0

    def test_body_target_humidity_valid(self) -> None:
        """Test set body target humidity."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.target_humidity = 55
        assert msg._body[6] == 55

    def test_body_target_humidity_out_of_range(self) -> None:
        """Test set body ignores an out-of-range target humidity."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.target_humidity = 0
        assert msg._body[6] == 0

    @pytest.mark.parametrize(
        ("anion", "anophelifuge", "expected"),
        [
            pytest.param(True, None, 0x01, id="anion_on"),
            pytest.param(False, None, 0x02, id="anion_off"),
            pytest.param(None, True, 0x04, id="anophelifuge_on"),
            pytest.param(None, False, 0x08, id="anophelifuge_off"),
            pytest.param(True, True, 0x05, id="both_on"),
        ],
    )
    def test_body_anion_anophelifuge(
        self,
        anion: bool | None,
        anophelifuge: bool | None,
        expected: int,
    ) -> None:
        """Test set body anion and anophelifuge share byte 8."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.anion = anion
        msg.anophelifuge = anophelifuge
        assert msg._body[8] == expected

    @pytest.mark.parametrize(
        ("body_feeling_scan", "expected"),
        [(True, 1), (False, 2)],
    )
    def test_body_body_feeling_scan(
        self,
        body_feeling_scan: bool,
        expected: int,
    ) -> None:
        """Test set body body_feeling_scan."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.body_feeling_scan = body_feeling_scan
        assert msg._body[14] == expected

    def test_body_scene(self) -> None:
        """Test set body scene."""
        msg = MessageSet(ProtocolVersion.V1, 1)
        msg.scene = 3
        assert msg._body[15] == 3


class TestFAGeneralMessageBody:
    """Test FA general message body."""

    def test_short_body_defaults(self) -> None:
        """Test short body default values."""
        body = FAGeneralMessageBody(bytearray(10))
        assert body.child_lock is False
        assert body.power is False
        assert body.fan_speed == 0
        assert body.tilting_angle == 0
        assert body.humidify is False
        assert body.waterions is False
        assert body.display_on_off is False
        assert body.fa_message_protocol == 0
        assert body.error_code == 0
        assert body.voice == 0
        assert body.anion is False
        assert body.anophelifuge is False
        assert body.body_feeling_scan is False
        assert body.scene == 0
        assert body.humidify_feedback is None
        assert body.temperature_feedback is None
        assert body.target_temperature is None
        assert body.target_humidity is None
        assert not hasattr(body, "mode")

    def test_anion_anophelifuge_default_on_short_body(self) -> None:
        """Test anion and anophelifuge default to False with a short body."""
        body = FAGeneralMessageBody(bytearray(9))
        assert body.anion is False
        assert body.anophelifuge is False

    def test_protocol_v5_body(self) -> None:
        """Test protocol 5 fields, decoded to match the T_0000_FA_560000F3 lua."""
        body = bytearray(36)
        body[1] = 5  # error_code
        body[2] = 0x04  # voice: open_buzzer
        body[3] = 0x09  # child_lock on + auto_power_off_flag
        body[4] = 0x0F  # power on, mode=7 (storm)
        body[5] = 10  # fan_speed
        body[6] = 61  # target_temperature raw (20C + 41)
        body[7] = 55  # target_humidity
        body[9] = 0x29  # anion on, anophelifuge off, humidify="1"
        body[12] = 45  # humidify_feedback
        body[13] = 59  # temperature_feedback raw (18C + 41)
        body[15] = 1  # body_feeling_scan on
        body[16] = 3  # scene: read
        body[23] = 5  # protocol version
        parsed = FAGeneralMessageBody(body)
        assert parsed.fa_message_protocol == 5
        assert parsed.child_lock is True
        assert parsed.power is True
        assert parsed.mode == 7
        assert parsed.fan_speed == 10
        assert parsed.target_temperature == 20
        assert parsed.target_humidity == 55
        assert parsed.error_code == 5
        assert parsed.voice == 0x04
        assert parsed.anion is True
        assert parsed.anophelifuge is False
        assert parsed.body_feeling_scan is True
        assert parsed.scene == 3
        assert parsed.humidify_feedback == 45
        assert parsed.temperature_feedback == 18


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
        assert getattr(msg, "mode", None) == 0
        assert getattr(msg, "fan_speed", None) == 3

    def test_notify2_response_ignored(self) -> None:
        """Test notify2 response is not parsed."""
        body = bytearray(10)
        msg = MessageFAResponse(
            _build_message(ProtocolVersion.V1, MessageType.notify2, body),
        )
        assert not hasattr(msg, "power")
