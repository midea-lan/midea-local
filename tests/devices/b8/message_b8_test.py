"""Test B8 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.b8.message import (
    MessageB8Base,
    MessageQuery,
)
from midealocal.message import ListTypes, MessageType


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
