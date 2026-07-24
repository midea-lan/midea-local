"""Test EA message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ea.message import MessageEABase, MessageQuery
from midealocal.message import MessageType


class TestMessageEABase:
    """Test EA Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageEABase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test EA Message Query."""

    def test_query_body(self) -> None:
        """Test query body is a fixed payload."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0xAA, 0x55, 0x01, 0x03, 0x00])

    def test_query_inner_body_empty(self) -> None:
        """Test query inner body is empty."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg._body == bytearray([])
