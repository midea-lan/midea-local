"""Test AD message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ad.message import (
    Message21Query,
    Message31Query,
    MessageADBase,
)
from midealocal.message import ListTypes, MessageType


class TestMessageADBase:
    """Test AD Message Base."""

    def test_message_id_increment(self) -> None:
        """Test message Id Increment."""
        msg = MessageADBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X21,
        )
        msg2 = MessageADBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X21,
        )
        assert msg2._message_id == msg._message_id + 1
        # test reset
        for _ in range(254 - msg2._message_id):
            msg = MessageADBase(
                protocol_version=ProtocolVersion.V1,
                message_type=MessageType.query,
                body_type=ListTypes.X21,
            )
        assert msg._message_id == 1

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageADBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X21,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessage21Query:
    """Test Message21Query."""

    def test_query_body(self) -> None:
        """Test query body: body type, payload, message id and CRC."""
        msg = Message21Query(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert body[:2] == bytearray([0x21, 0x01])
        assert body[2] == msg._message_id
        assert len(body) == 4


class TestMessage31Query:
    """Test Message31Query."""

    def test_query_body(self) -> None:
        """Test query body: body type, payload, message id and CRC."""
        msg = Message31Query(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert body[:2] == bytearray([0x31, 0x01])
        assert body[2] == msg._message_id
        assert len(body) == 4
