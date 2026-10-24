"""Test DB message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.db.message import (
    MessageDBBase,
    MessagePower,
    MessageQuery,
    MessageSet,
    MessageStart,
)
from midealocal.message import ListTypes, MessageType


class TestMessageDBBase:
    """Test DB Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageDBBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X03,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test DB Message Query."""

    def test_query_body(self) -> None:
        """Test query body contains only the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x03])


class TestMessagePower:
    """Test DB Message Power."""

    def test_power_body_on(self) -> None:
        """Test power body with power on."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        msg.power = True
        assert msg.body == bytearray([0x02, 0x01] + [0xFF] * 20)

    def test_power_body_off(self) -> None:
        """Test power body with power off."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x02, 0x00] + [0xFF] * 20)


class TestMessageSet:
    """Test parameter writes preserve power and work status."""

    @pytest.mark.parametrize(
        "parameters",
        [
            {},
            {3: 0x03},
            {6: 0x04},
            {3: 0x03, 6: 0x04},
            {4: 5, 7: 5, 8: 25, 9: 8, 10: 4, 11: 0},
        ],
    )
    def test_parameter_body(
        self,
        parameters: dict[int, int],
    ) -> None:
        """Only explicitly selected fields differ from the unchanged sentinel."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1, parameters=parameters)
        expected = bytearray([0x02] + [0xFF] * 21)
        for offset, value in parameters.items():
            expected[offset + 1] = value
        assert msg.body == expected
        assert msg.message_type == MessageType.set


class TestMessageStart:
    """Test DB Message Start."""

    def test_start_body(self) -> None:
        """Test start body with washing data."""
        msg = MessageStart(protocol_version=ProtocolVersion.V1)
        msg.start = True
        msg.washing_data = bytearray([0x01, 0x02])
        assert msg.body == bytearray([0x02, 0xFF, 0x01, 0x01, 0x02])

    def test_pause_body(self) -> None:
        """Test pause body."""
        msg = MessageStart(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x02, 0xFF, 0x00])
