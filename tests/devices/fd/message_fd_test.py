"""Test FD message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.crc8 import calculate
from midealocal.devices.fd.message import (
    MessageFDBase,
    MessageFDResponse,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full FD response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMessageFDBase:
    """Test FD Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageFDBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body

    def test_message_serial_increments(self) -> None:
        """Test message serial increments per message."""
        MessageFDBase._message_serial = 5
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg._message_id == 6

    def test_message_serial_wraps(self) -> None:
        """Test message serial wraps back to one."""
        MessageFDBase._message_serial = 253
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg._message_id == 1


class TestMessageQuery:
    """Test FD Message Query."""

    def test_query_body(self) -> None:
        """Test query body layout, message id and checksum."""
        MessageFDBase._message_serial = 0
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert len(body) == 22
        assert body[0] == ListTypes.X41
        assert body[1] == 0x81
        assert body[-2] == 1  # message id
        assert body[-1] == calculate(body[:-1])


class TestMessageSet:
    """Test FD Message Set."""

    def test_set_body_defaults(self) -> None:
        """Test set body defaults."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        body = msg._body
        assert len(body) == 21
        assert body[0] == 0x02  # power off, prompt tone off
        assert body[2] == 0x00  # fan speed
        assert body[6] == 50  # target humidity
        assert body[8] == 0x07  # screen display
        assert body[9] == 0x01  # mode
        assert body[14] == 0x00  # disinfect not set

    @pytest.mark.parametrize(
        ("power", "prompt_tone", "disinfect", "first_byte", "disinfect_byte"),
        [
            (True, False, None, 0x03, 0x00),
            (False, True, True, 0x42, 0x01),
            (True, True, False, 0x43, 0x02),
        ],
    )
    def test_set_body_flags(
        self,
        power: bool,
        prompt_tone: bool,
        disinfect: bool | None,
        first_byte: int,
        disinfect_byte: int,
    ) -> None:
        """Test set body power, prompt tone and disinfect flags."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = power
        msg.prompt_tone = prompt_tone
        # assigned via vars as mypy infers the attribute type as None
        vars(msg)["disinfect"] = disinfect
        body = msg._body
        assert body[0] == first_byte
        assert body[14] == disinfect_byte


class TestMessageFDResponse:
    """Test FD Message Response."""

    def test_response_c8_keeps_fan_speed(self) -> None:
        """Test response with a C8 body keeps a fan speed above minimum."""
        body = bytearray(38)
        body[0] = 0xC8
        body[3] = 40
        msg = MessageFDResponse(_build_message(MessageType.query, body))
        assert msg.fan_speed == 40

    def test_response_c8_low_fan_speed(self) -> None:
        """Test response with a low fan speed remaps it to one."""
        body = bytearray(38)
        body[0] = 0xC8
        body[3] = 3
        msg = MessageFDResponse(_build_message(MessageType.query, body))
        assert msg.fan_speed == 1

    def test_response_a0_body(self) -> None:
        """Test response with a short A0 body without disinfect."""
        body = bytearray(29)
        body[0] = 0xA0
        body[1] = 0x01
        body[3] = 60
        msg = MessageFDResponse(_build_message(MessageType.notify1, body))
        assert hasattr(msg, "power")
        assert msg.fan_speed == 60
        assert not hasattr(msg, "disinfect")

    def test_response_a0_disinfect_zero(self) -> None:
        """Test response with a zero disinfect field leaves it unset."""
        body = bytearray(31)
        body[0] = 0xA0
        msg = MessageFDResponse(_build_message(MessageType.notify1, body))
        assert not hasattr(msg, "disinfect")

    @pytest.mark.parametrize("body_type", [0xB0, 0xB1, 0x55])
    def test_response_unhandled_body_type(self, body_type: int) -> None:
        """Test response with unhandled body types parses nothing."""
        body = bytearray(38)
        body[0] = body_type
        msg = MessageFDResponse(_build_message(MessageType.query, body))
        assert not hasattr(msg, "power")
        assert not hasattr(msg, "fan_speed")

    def test_response_unhandled_message_type(self) -> None:
        """Test response with an unhandled message type parses nothing."""
        body = bytearray(38)
        body[0] = 0xC8
        msg = MessageFDResponse(_build_message(MessageType.notify2, body))
        assert not hasattr(msg, "power")
        assert not hasattr(msg, "fan_speed")
