"""Test FC message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.fc.message import (
    MessageFCBase,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType

SET_BODY_LENGTH = 20


class TestMessageFCBase:
    """Test FC Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageFCBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body

    def test_message_serial_wraps(self) -> None:
        """Test message serial number wraps around."""
        MessageFCBase._message_serial = 253
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg._message_id == 1

    def test_message_serial_increments(self) -> None:
        """Test message serial number increments."""
        MessageFCBase._message_serial = 10
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg._message_id == 11


class TestMessageQuery:
    """Test FC Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert body[0] == ListTypes.X41
        assert body[1:20] == bytearray(
            [
                0x00,
                0x00,
                0xFF,
                0x03,
                0x00,
                0x00,
                0x02,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        assert body[-2] == msg._message_id
        assert len(msg.serialize()) > 0


class TestMessageSet:
    """Test FC Message Set."""

    def test_body_defaults(self) -> None:
        """Test set body defaults."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        body = msg._body
        assert len(body) == SET_BODY_LENGTH
        assert body[0] == 0x02
        assert body[1] == 0
        assert body[2] == 0
        assert body[7] == 0x00
        assert body[8] == 0
        assert body[9] == 0x00
        assert body[13] == 0
        assert body[14] == 0x08
        assert body[15] == 0
        assert body[16] == 0

    def test_body_all_set(self) -> None:
        """Test set body with all fields set."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        msg.prompt_tone = True
        msg.detect_mode = 2
        msg.mode = 0x20
        msg.fan_speed = 59
        msg.child_lock = True
        msg.screen_display = 6
        msg.anion = True
        msg.standby = True
        msg.standby_detect = [50, 30]
        body = msg._body
        assert body[0] == 0x4B
        assert body[1] == 0x20
        assert body[2] == 59
        assert body[7] == 0x80
        assert body[8] == 6
        assert body[9] == 0x20
        assert body[13] == 1
        assert body[14] == 0x04
        assert body[15] == 50
        assert body[16] == 30

    def test_full_body_has_type_serial_and_crc(self) -> None:
        """Test full body contains body type, serial number and CRC."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert body[0] == ListTypes.X48
        assert len(body) == SET_BODY_LENGTH + 3
        assert body[-2] == msg._message_id
