"""Test x13 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.x13.message import Message13Base, MessageQuery, MessageSet
from midealocal.message import ListTypes, MessageType


class TestMessage13Base:
    """Test x13 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = Message13Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X24,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test x13 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x24, 0x00, 0x00, 0x00, 0x00])


class TestMessageSet:
    """Test x13 Message Set."""

    @pytest.mark.parametrize(
        ("attr", "value", "expected_byte", "expected_body_type"),
        [
            ("power", True, 0x01, ListTypes.X01),
            ("power", False, 0x00, ListTypes.X01),
            ("effect", 2, 0x03, ListTypes.X01),
            ("effect", 5, 0x06, ListTypes.X01),
            ("effect", 0, 0x00, ListTypes.X00),  # effect 0 is out of set range
            ("color_temperature", 128, 0x80, ListTypes.X03),
            ("brightness", 100, 0x64, ListTypes.X04),
        ],
    )
    def test_set_body(
        self,
        attr: str,
        value: bool | int,
        expected_byte: int,
        expected_body_type: ListTypes,
    ) -> None:
        """Test set body for each settable attribute."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        setattr(msg, attr, value)
        assert msg._body == bytearray([expected_byte, 0x00, 0x00, 0x00])
        assert msg.body_type == expected_body_type

    def test_set_body_default(self) -> None:
        """Test set body with no attribute set is empty."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        assert msg._body == bytearray([0x00, 0x00, 0x00, 0x00])
        assert msg.body_type == ListTypes.X00
