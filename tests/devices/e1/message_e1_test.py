"""Test E1 messages."""

from midealocal.const import ProtocolVersion
from midealocal.devices.e1.message import MessageWork


def test_work_message_body() -> None:
    """Test work message body."""
    message = MessageWork(ProtocolVersion.V1)
    assert message.body == bytearray([0x08, 0x03, 0x00, 0x00, 0x00])

    message.mode = 0x04
    assert message.body == bytearray([0x08, 0x03, 0x04, 0x00, 0x00])
