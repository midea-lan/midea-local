"""Test DC message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.dc.message import (
    MessageDCBase,
    MessagePower,
    MessageQuery,
    MessageSetAISwitch,
    MessageStart,
)
from midealocal.message import ListTypes, MessageType


class TestMessageDCBase:
    """Test DC Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageDCBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X03,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test DC Message Query."""

    def test_query_body(self) -> None:
        """Test query body contains only the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x03])


class TestMessagePower:
    """Test DC Message Power."""

    def test_power_body_on(self) -> None:
        """Test power body with power on."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        msg.power = True
        assert msg.body == bytearray([0x02, 0x01, 0xFF])

    def test_power_body_off(self) -> None:
        """Test power body with power off."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x02, 0x00, 0xFF])


class TestMessageStart:
    """Test DC Message Start."""

    def test_start_body(self) -> None:
        """Test start body with washing data."""
        msg = MessageStart(protocol_version=ProtocolVersion.V1)
        msg.start = True
        msg.washing_data = bytearray([0x01, 0x02])
        assert msg.body == bytearray([0x02, 0xFF, 0x01, 0x01, 0x02])

    def test_stop_body(self) -> None:
        """Test stop body."""
        msg = MessageStart(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x02, 0xFF, 0x00])


class TestMessageSetAISwitch:
    """Test DC Message Set AI Switch.

    Byte offsets and the on/off AND-mask values (0xDF/0xCF) come
    from the DC lua reference (T_0000_DC_5.lua): commandSpec's
    ai_switch = {offset = 234, bits = 2} places it at byte-relative
    index 18 (floor(234 / 8) + 1 - 12) within the 21-byte control
    body, bit-offset 234 % 8 = 2, and bits2Config[2] maps off/on to
    0xCF/0xDF.
    """

    def test_body_on(self) -> None:
        """Test ai_switch on only touches byte 18 of the control body."""
        msg = MessageSetAISwitch(protocol_version=ProtocolVersion.V1)
        msg.ai_switch = True
        expected = bytearray([0xFF] * 21)
        expected[18] = 0xDF
        assert msg.body == bytearray([0x02]) + expected

    def test_body_off(self) -> None:
        """Test ai_switch off only touches byte 18 of the control body."""
        msg = MessageSetAISwitch(protocol_version=ProtocolVersion.V1)
        expected = bytearray([0xFF] * 21)
        expected[18] = 0xCF
        assert msg.body == bytearray([0x02]) + expected
