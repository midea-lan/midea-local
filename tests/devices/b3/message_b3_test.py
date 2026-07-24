"""Test B3 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.b3.message import (
    B3MessageBody24,
    MessageB3Base,
    MessageQuery,
)
from midealocal.message import ListTypes, MessageType


class TestMessageB3Base:
    """Test B3 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageB3Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X31,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test B3 Message Query."""

    def test_query_body(self) -> None:
        """Test query body contains only the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x31])


class TestB3MessageBody24:
    """Test B3 message body 24."""

    @pytest.mark.parametrize(
        (
            "top_bytes",
            "bottom_bytes",
            "top_remaining",
            "bottom_remaining",
        ),
        [
            ((0x01, 0x00), (0x02, 0x00), 60, 120),
            ((0xFF, 0x05), (0xFF, 0x07), 5, 7),
            ((0xFF, 0xFF), (0xFF, 0xFF), 0, 0),
        ],
    )
    def test_body_24(
        self,
        top_bytes: tuple[int, int],
        bottom_bytes: tuple[int, int],
        top_remaining: int,
        bottom_remaining: int,
    ) -> None:
        """Test body 24 parsing with hour/minute/unset remaining bytes."""
        body = bytearray(20)
        body[0] = 0x24  # Body type
        body[5] = 0x02  # top status
        body[6] = 0x01  # top mode
        body[7] = 40  # top temperature
        body[8] = top_bytes[0]
        body[9] = top_bytes[1]
        body[10] = 0x01  # first bottom status (overwritten)
        body[11] = 0x02  # first bottom mode (overwritten)
        body[12] = 50  # first bottom temperature (overwritten)
        body[13] = 0x01  # first bottom remaining (overwritten)
        body[14] = 0x01  # first bottom remaining (overwritten)
        body[15] = 0x03  # bottom status
        body[16] = 0x02  # bottom mode
        body[17] = 60  # bottom temperature
        body[18] = bottom_bytes[0]
        body[19] = bottom_bytes[1]
        message = B3MessageBody24(body)
        assert message.top_compartment_status == 0x02
        assert message.top_compartment_mode == 0x01
        assert message.top_compartment_temperature == 40
        assert message.top_compartment_remaining == top_remaining
        assert message.bottom_compartment_status == 0x03
        assert message.bottom_compartment_mode == 0x02
        assert message.bottom_compartment_temperature == 60
        assert message.bottom_compartment_remaining == bottom_remaining
