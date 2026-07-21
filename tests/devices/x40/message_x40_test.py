"""Test 40 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.x40.message import (
    MessageQuery,
    MessageSet,
    MessageX40Base,
    MessageX40Body,
    MessageX40Response,
)
from midealocal.message import ListTypes, MessageType


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full 40 response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMessageX40Base:
    """Test 40 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageX40Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test 40 Message Query."""

    def test_query_body(self) -> None:
        """Test query body only contains the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg._body == bytearray([])
        assert msg.body == bytearray([0x01])


class TestMessageSet:
    """Test 40 Message Set."""

    def test_read_field(self) -> None:
        """Test read field returns stored values and zero otherwise."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.fields = {"MAIN_LIGHT_BRIGHTNESS": 55, "NIGHT_LIGHT_ENABLE": False}
        assert msg.read_field("MAIN_LIGHT_BRIGHTNESS") == 55
        assert msg.read_field("NIGHT_LIGHT_ENABLE") == 0
        assert msg.read_field("MISSING") == 0

    @pytest.mark.parametrize(
        ("fan_speed", "blow", "fan_speed_byte"),
        [
            (0, 0, 0xFF),
            (1, 1, 30),
            (2, 1, 100),
        ],
    )
    def test_body(self, fan_speed: int, blow: int, fan_speed_byte: int) -> None:
        """Test set body layout."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.fields = {"MAIN_LIGHT_BRIGHTNESS": 55, "SMELLY_THRESHOLD": 7}
        msg.light = True
        msg.fan_speed = fan_speed
        msg.direction = 90
        msg.ventilation = True
        msg.smelly_sensor = True
        body = msg._body
        assert len(body) == 39
        assert body[0] == 1  # light
        assert body[1] == 55  # main light brightness field
        assert body[17] == 1  # ventilation
        assert body[25] == blow
        assert body[26] == fan_speed_byte
        assert body[27] == 90  # direction
        assert body[37] == 1  # smelly sensor
        assert body[38] == 7  # smelly threshold field

    def test_body_defaults(self) -> None:
        """Test set body defaults with everything off."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.direction = 0xFD
        body = msg._body
        assert body[0] == 0  # light
        assert body[17] == 0  # ventilation
        assert body[25] == 0  # blow
        assert body[26] == 0xFF  # fan speed
        assert body[27] == 0xFD  # direction
        assert body[37] == 0  # smelly sensor


class TestMessageX40Body:
    """Test 40 message body."""

    @pytest.mark.parametrize(
        ("blow", "blow_speed", "fan_speed"),
        [
            (0, 0, 0),
            (1, 30, 1),
            (1, 31, 2),
        ],
    )
    def test_body(self, blow: int, blow_speed: int, fan_speed: int) -> None:
        """Test body parsing including the fan speed mapping."""
        raw = bytearray(47)
        raw[0] = 0x01
        raw[1] = 1  # light
        raw[2] = 55  # main light brightness
        raw[13] = 1  # bath enable
        raw[18] = 1  # ventilation
        raw[21] = 1  # drying enable
        raw[26] = blow
        raw[27] = blow_speed
        raw[28] = 80  # direction
        raw[33] = 50  # current temperature
        raw[45] = 1  # smelly sensor
        raw[46] = 7  # smelly threshold
        body = MessageX40Body(raw)
        assert body.light is True
        assert body.fields["MAIN_LIGHT_BRIGHTNESS"] == 55
        assert body.fields["BATH_ENABLE"] is True
        assert body.ventilation is True
        assert body.fields["DRYING_ENABLE"] is True
        assert body.direction == 80
        assert body.current_temperature == 50
        assert body.smelly_sensor == 1
        assert body.fields["SMELLY_THRESHOLD"] == 7
        assert body.fan_speed == fan_speed


class TestMessageX40Response:
    """Test 40 Message Response."""

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.set, MessageType.notify1, MessageType.query],
    )
    def test_response_parsed(self, message_type: MessageType) -> None:
        """Test response with a handled type parses attributes."""
        raw = bytearray(47)
        raw[0] = 0x01
        raw[1] = 1  # light
        raw[26] = 1  # blow
        raw[27] = 100  # blow speed
        msg = MessageX40Response(_build_message(message_type, raw))
        assert getattr(msg, "light", None) is True
        assert getattr(msg, "fan_speed", None) == 2
        assert "MAIN_LIGHT_BRIGHTNESS" in msg.fields

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.query, 0x02),
            (MessageType.notify2, 0x01),
        ],
    )
    def test_response_not_parsed(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test response with an unhandled type parses nothing."""
        raw = bytearray(47)
        raw[0] = body_type
        raw[1] = 1
        msg = MessageX40Response(_build_message(message_type, raw))
        assert not hasattr(msg, "light")
