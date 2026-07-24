"""Test CF message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.cf.message import (
    MessageCFBase,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


class TestMessageCFBase:
    """Test CF Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageCFBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test CF Message Query."""

    def test_query_body(self) -> None:
        """Test query body contains only the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01])


class TestMessageSet:
    """Test CF Message Set."""

    def test_set_body_defaults(self) -> None:
        """Test set body with default values."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01, 0x00, 0x00, 0xFF, 0xFF])

    def test_set_body_with_values(self) -> None:
        """Test set body with power, mode, temperature and aux heating."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        msg.mode = 2
        msg.target_temperature = 24.5
        msg.aux_heating = True
        assert msg.body == bytearray([0x01, 0x01, 0x02, 24, 0x01])

    def test_set_body_aux_heating_off(self) -> None:
        """Test set body with aux heating explicitly off."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.aux_heating = False
        assert msg.body == bytearray([0x01, 0x00, 0x00, 0xFF, 0x00])
