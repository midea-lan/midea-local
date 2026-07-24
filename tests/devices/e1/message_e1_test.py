"""Test E1 messages."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e1.message import (
    E1GeneralMessageBody,
    MessageE1Base,
    MessageE1Response,
    MessageLock,
    MessagePower,
    MessageQuery,
    MessageStorage,
    MessageWork,
)
from midealocal.message import ListTypes, MessageType


def test_work_message_body() -> None:
    """Test work message body."""
    message = MessageWork(ProtocolVersion.V1)
    assert message.body == bytearray([0x08, 0x03, 0x00, 0x00, 0x00])

    message.mode = 0x04
    assert message.body == bytearray([0x08, 0x03, 0x04, 0x00, 0x00])


class TestMessageE1Base:
    """Test E1 message base."""

    def test_body_not_implemented(self) -> None:
        """Test base body raises NotImplementedError."""
        message = MessageE1Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )
        with pytest.raises(NotImplementedError):
            _ = message.body


class TestMessagePower:
    """Test E1 message power."""

    @pytest.mark.parametrize(("power", "expected"), [(True, 0x01), (False, 0x00)])
    def test_power_body(self, power: bool, expected: int) -> None:
        """Test power body reflects the requested state."""
        message = MessagePower(ProtocolVersion.V1)
        message.power = power
        assert message.body == bytearray([0x08, expected, 0x00, 0x00, 0x00])


class TestMessageLock:
    """Test E1 message lock."""

    @pytest.mark.parametrize(("lock", "expected"), [(True, 0x03), (False, 0x04)])
    def test_lock_body(self, lock: bool, expected: int) -> None:
        """Test lock body reflects the requested state."""
        message = MessageLock(ProtocolVersion.V1)
        message.lock = lock
        assert message.body == bytearray([0x83, expected, *([0x00] * 36)])


class TestMessageStorage:
    """Test E1 message storage."""

    @pytest.mark.parametrize(("storage", "expected"), [(True, 0x01), (False, 0x00)])
    def test_storage_body(self, storage: bool, expected: int) -> None:
        """Test storage body reflects the requested state."""
        message = MessageStorage(ProtocolVersion.V1)
        message.storage = storage
        assert message.body == bytearray(
            [0x81, 0x00, 0x00, 0x00, expected, *([0xFF] * 6), *([0x00] * 27)],
        )


class TestMessageQuery:
    """Test E1 message query."""

    def test_query_body(self) -> None:
        """Test query body only contains the body type byte."""
        message = MessageQuery(ProtocolVersion.V1)
        assert message.body == bytearray([0x00])


class TestE1GeneralMessageBody:
    """Test E1 general message body."""

    def test_full_body(self) -> None:
        """Test parsing a full-length body sets every attribute."""
        body = bytearray(40)
        body[1] = 0x03  # power on, status Running
        body[2] = 0x04  # mode
        body[3] = 0x05  # additional
        body[4] = 0x3F  # diyflag, uv/uv_switch, dry, dry_status, waterswitch, ...
        body[5] = 0xFE  # door closed + all other switch/status bits set
        body[6] = 45  # time_remaining (low byte)
        body[9] = 0x03  # progress
        body[10] = 7  # error_code
        body[11] = 55  # temperature
        body[13] = 2  # softwater
        body[16] = 1  # wrong_operation
        body[17] = 4  # storage_set_time
        body[18] = 5  # storage_remaining
        body[24] = 9  # bright
        body[32] = 1  # left_time_high
        body[33] = 60  # humidity

        result = E1GeneralMessageBody(body)

        assert result.power is True
        assert result.status == 0x03
        assert result.mode == 0x04
        assert result.additional == 0x05
        assert result.door is True
        assert result.doorswitch is False
        assert result.rinse_aid is True
        assert result.lack_bright is True
        assert result.salt is True
        assert result.lack_softwater is True
        assert result.start is True
        assert result.child_lock is True
        assert result.dryswitch is True
        assert result.storage is True
        assert result.drystatus is True
        assert result.storage_status is True
        assert result.water_lack is True
        assert result.diyflag is True
        assert result.uv is True
        assert result.uv_switch is True
        assert result.dry is True
        assert result.dry_status is True
        assert result.waterswitch is True
        assert result.dry_step_switch is True
        assert result.time_remaining == 1 * 256 + 45
        assert result.progress == 0x03
        assert result.storage_set_time == 4
        assert result.storage_remaining == 5
        assert result.temperature == 55
        assert result.humidity == 60
        assert result.error_code == 7
        assert result.softwater == 2
        assert result.wrong_operation == 1
        assert result.bright == 9

    def test_short_body_defaults(self) -> None:
        """Test parsing a short body falls back to default values."""
        body = bytearray(18)
        body[1] = 0x00
        body[6] = 30  # time_remaining, no high byte available

        result = E1GeneralMessageBody(body)

        assert result.time_remaining == 30
        assert result.storage_set_time is False
        assert result.storage_remaining is False
        assert result.humidity is None
        assert result.bright is None

    def test_start_false_when_paused_without_start_bit(self) -> None:
        """Test start is False when status is paused and start bit is unset."""
        body = bytearray(40)
        body[1] = 0x02  # status Delay
        body[5] = 0x00  # start_pause bit unset

        result = E1GeneralMessageBody(body)

        assert result.start is False


class TestMessageE1Response:
    """Test E1 message response."""

    @staticmethod
    def _message(message_type: MessageType, body_type: int) -> bytes:
        header = bytearray(
            [0xAA, *([0x00] * 7), ProtocolVersion.V1, message_type],
        )
        body = bytearray(40)
        body[0] = body_type
        crc = bytearray([0x00])
        return bytes(header + body + crc)

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.set, 0x00),
            (MessageType.set, 0x07),
            (MessageType.query, 0x00),
            (MessageType.notify1, 0x00),
        ],
    )
    def test_handled_combinations_parse_body(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test handled message/body type combinations parse the general body."""
        message = MessageE1Response(self._message(message_type, body_type))
        assert hasattr(message, "power")
        assert hasattr(message, "temperature")

    @pytest.mark.parametrize(
        ("message_type", "body_type"),
        [
            (MessageType.set, 0x08),
            (MessageType.notify2, 0x00),
        ],
    )
    def test_unhandled_combinations_skip_body(
        self,
        message_type: MessageType,
        body_type: int,
    ) -> None:
        """Test unhandled message/body type combinations skip parsing."""
        message = MessageE1Response(self._message(message_type, body_type))
        assert not hasattr(message, "power")
