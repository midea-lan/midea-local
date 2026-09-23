"""Test B8 message."""

import pytest

from midealan.const import ProtocolVersion
from midealan.devices.b8.message import (
    B8StatusType,
    MessageB8Base,
    MessageQuery,
    MessageSet,
    MessageSetCommand,
    MessageSetMovement,
    MessageSetVoiceVolume,
)
from midealan.message import ListTypes, MessageType


class TestMessageB8Base:
    """Test B8 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageB8Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X32,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test B8 Message Query."""

    def test_query_body(self) -> None:
        """Test query body only contains the body type and the query flag."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([ListTypes.X32, 0x01])

    def test_parts_query_body(self) -> None:
        """Test parts query body."""
        msg = MessageQuery(
            protocol_version=ProtocolVersion.V1,
            body_type=ListTypes.X35,
            status_type=B8StatusType.X01,
        )
        assert msg.body == bytearray([ListTypes.X35, 0x01])


class TestMessageSet:
    """Test B8 Message Set."""

    def test_work_mode_body(self) -> None:
        """Test work mode command body matches the legacy Lua protocol layout."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.clean_mode = 0x09
        msg.fan_level = 0x03
        msg.water_level = 0x02
        msg.speak_level = 0x02
        msg.zone_id = 3
        assert msg.body == bytearray(
            [
                ListTypes.X22,
                0x02,
                0x00,
                0x02,
                0x00,
                0x09,
                0x03,
                0x00,
                0x02,
                0x02,
                3,
            ]
            + [0x00] * 6,
        )
        assert msg.header[1] == 27


class TestMessageSetCommand:
    """Test B8 Message Set Command."""

    def test_charge_body(self) -> None:
        """Test charge command body length."""
        msg = MessageSetCommand(ProtocolVersion.V1, 0x01)
        assert msg.body == bytearray([ListTypes.X22, 0x01, 0x00])
        assert msg.header[1] == 13


class TestMessageSetMovement:
    """Test B8 Message Set Movement."""

    def test_movement_body(self) -> None:
        """Test movement command body."""
        msg = MessageSetMovement(ProtocolVersion.V1, 0x03)
        assert msg.body == bytearray(
            [
                ListTypes.X22,
                0x02,
                0x00,
                0x01,
                0x03,
            ]
            + [0x00] * 12,
        )
        assert msg.header[1] == 27


class TestMessageSetVoiceVolume:
    """Test B8 Message Set Voice Volume."""

    def test_voice_volume_body(self) -> None:
        """Test voice volume command body."""
        msg = MessageSetVoiceVolume(ProtocolVersion.V1, 120)
        assert msg.body == bytearray([ListTypes.X22, 0x0A, 100])
        assert msg.header[1] == 13
