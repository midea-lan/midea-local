"""Test CE message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ce.message import (
    MessageCEBase,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


class TestMessageCEBase:
    """Test CE Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageCEBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test CE Message Query."""

    def test_query_body(self) -> None:
        """Test query body contains only the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01])


class TestMessageSet:
    """Test CE Message Set."""

    def test_set_body_defaults(self) -> None:
        """Test set body with default values."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00])

    def test_set_body_with_values(self) -> None:
        """Test set body with all flags enabled."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        msg.fan_speed = 5
        msg.link_to_ac = True
        msg.sleep_mode = True
        msg.eco_mode = True
        msg.aux_heating = True
        msg.powerful_purify = True
        msg.scheduled = True
        msg.child_lock = True
        assert msg.body == bytearray([0x01, 0x81, 5, 0x1F, 0x01, 0x00, 0x7F])
