"""Test x26 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.x26.message import (
    DeviceMode,
    Message26Base,
    Message26Body,
    Message26Response,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full x26 response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMessage26Base:
    """Test x26 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = Message26Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test x26 Message Query."""

    def test_query_body(self) -> None:
        """Test query body only contains the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01])
        assert msg._body == bytearray([])


class TestMessageSet:
    """Test x26 Message Set."""

    def test_set_body_default(self) -> None:
        """Test set body defaults."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        body = msg._body
        assert len(body) == 39
        assert body[0] == 0x00  # main light off
        assert body[2] == 0x00  # night light off
        assert body[8] == 0x00  # heat off
        assert body[9] == 0x00  # heat temperature
        assert body[12] == 0x00  # bath off
        assert body[17] == 0x00  # ventilation off
        assert body[20] == 0x00  # dry off
        assert body[25] == 0x00  # blow off
        assert body[11] == 0xFD  # directions default to oscillate
        assert body[16] == 0xFD
        assert body[19] == 0xFD
        assert body[24] == 0xFD
        assert body[27] == 0xFD

    def test_set_body_lights(self) -> None:
        """Test set body with lights on."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.main_light = True
        msg.night_light = True
        body = msg._body
        assert body[0] == 0x01
        assert body[2] == 0x01

    @pytest.mark.parametrize(
        ("mode", "expected_temperature"),
        [
            (DeviceMode.HEAT_HIGH, 55),
            (DeviceMode.HEAT_LOW, 30),
        ],
    )
    def test_set_body_heat_modes(
        self,
        mode: DeviceMode,
        expected_temperature: int,
    ) -> None:
        """Test set body heat modes."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.mode = mode
        body = msg._body
        assert body[8] == 0x01
        assert body[9] == expected_temperature

    @pytest.mark.parametrize(
        ("mode", "flag_index"),
        [
            (DeviceMode.BATH, 12),
            (DeviceMode.VENTILATION, 17),
            (DeviceMode.DRY, 20),
            (DeviceMode.BLOW, 25),
        ],
    )
    def test_set_body_other_modes(self, mode: DeviceMode, flag_index: int) -> None:
        """Test set body non-heat modes."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.mode = mode
        body = msg._body
        assert body[8] == 0x00
        assert body[9] == 0x00
        assert body[flag_index] == 0x01

    def test_read_field(self) -> None:
        """Test read field returns stored values or zero."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.fields = {"MAIN_LIGHT_BRIGHTNESS": 100, "DELAY_ENABLE": 0}
        assert msg.read_field("MAIN_LIGHT_BRIGHTNESS") == 100
        assert msg.read_field("DELAY_ENABLE") == 0
        assert msg.read_field("MISSING") == 0
        assert msg._body[1] == 100


class TestMessage26Body:
    """Test x26 Message Body."""

    def test_body_parses_values(self) -> None:
        """Test body value parsing."""
        raw = bytearray(47)
        raw[0] = 0x01
        raw[1] = 0x01  # main light
        raw[2] = 100  # main light brightness
        raw[31] = 50  # current humidity
        raw[32] = 1  # current radar
        raw[33] = 25  # current temperature
        parsed = Message26Body(raw)
        assert parsed.main_light is True
        assert parsed.night_light is False
        assert parsed.current_humidity == 50
        assert parsed.current_radar == 1
        assert parsed.current_temperature == 25
        assert parsed.mode == 0
        assert parsed.direction == 0xFD
        assert parsed.fields["MAIN_LIGHT_BRIGHTNESS"] == 100


class TestMessage26Response:
    """Test x26 Message Response."""

    def test_response_parses_body(self) -> None:
        """Test response with the handled body type parses attributes."""
        body = bytearray(47)
        body[0] = 0x01
        body[1] = 0x01  # main light
        body[31] = 50  # current humidity
        msg = Message26Response(_build_message(MessageType.query, body))
        assert hasattr(msg, "main_light")
        assert hasattr(msg, "night_light")
        assert hasattr(msg, "current_humidity")
        assert msg.fields["MAIN_LIGHT_BRIGHTNESS"] == 0

    def test_response_unhandled_body_type(self) -> None:
        """Test response with an unhandled body type parses nothing."""
        body = bytearray(47)
        body[0] = 0x02
        msg = Message26Response(_build_message(MessageType.query, body))
        assert not hasattr(msg, "main_light")
        assert not hasattr(msg, "fields")

    def test_response_unhandled_message_type(self) -> None:
        """Test response with an unhandled message type parses nothing."""
        body = bytearray(47)
        body[0] = 0x01
        msg = Message26Response(_build_message(MessageType.notify2, body))
        assert not hasattr(msg, "main_light")
        assert not hasattr(msg, "fields")
