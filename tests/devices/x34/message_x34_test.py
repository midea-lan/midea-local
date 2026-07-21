"""Test x34 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.x34.message import (
    Message34Base,
    Message34Body,
    MessageLock,
    MessagePower,
    MessageQuery,
    MessageStorage,
)
from midealocal.message import ListTypes, MessageType


class TestMessage34Base:
    """Test x34 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = Message34Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test x34 Message Query."""

    def test_query_body(self) -> None:
        """Test query body is only the body type."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body_type == ListTypes.X00
        assert msg._body == bytearray([])
        assert msg.body == bytearray([0x00])


class TestMessagePower:
    """Test x34 Message Power."""

    @pytest.mark.parametrize(
        ("power", "expected_byte"),
        [(True, 0x01), (False, 0x00)],
    )
    def test_power_body(self, power: bool, expected_byte: int) -> None:
        """Test power body."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        msg.power = power
        assert msg.body_type == ListTypes.X08
        assert msg._body == bytearray([expected_byte, 0x00, 0x00, 0x00])


class TestMessageLock:
    """Test x34 Message Lock."""

    @pytest.mark.parametrize(
        ("lock", "expected_byte"),
        [(True, 0x03), (False, 0x04)],
    )
    def test_lock_body(self, lock: bool, expected_byte: int) -> None:
        """Test lock body."""
        msg = MessageLock(protocol_version=ProtocolVersion.V1)
        msg.lock = lock
        assert msg.body_type == ListTypes.X83
        assert msg._body == bytearray([expected_byte]) + bytearray([0x00] * 36)


class TestMessageStorage:
    """Test x34 Message Storage."""

    @pytest.mark.parametrize(
        ("storage", "expected_byte"),
        [(True, 0x01), (False, 0x00)],
    )
    def test_storage_body(self, storage: bool, expected_byte: int) -> None:
        """Test storage body."""
        msg = MessageStorage(protocol_version=ProtocolVersion.V1)
        msg.storage = storage
        assert msg.body_type == ListTypes.X81
        assert msg._body == (
            bytearray([0x00, 0x00, 0x00, expected_byte])
            + bytearray([0xFF] * 6)
            + bytearray([0x00] * 27)
        )


class TestMessage34Body:
    """Test x34 Message Body."""

    def test_start_pause_sets_start(self) -> None:
        """Test start_pause bit sets start to True."""
        body = bytearray(25)
        body[5] = 0x08  # start_pause
        parsed = Message34Body(body)
        assert parsed.start is True

    @pytest.mark.parametrize("status", [2, 3])
    def test_status_clears_start(self, status: int) -> None:
        """Test delay/running status without start_pause sets start to False."""
        body = bytearray(25)
        body[1] = status
        parsed = Message34Body(body)
        assert parsed.start is False

    def test_idle_status_leaves_start_unset(self) -> None:
        """Test idle status without start_pause leaves start unset."""
        body = bytearray(25)
        body[1] = 1
        parsed = Message34Body(body)
        assert hasattr(parsed, "start") is False

    def test_long_body_optional_fields(self) -> None:
        """Test a long body parses storage_remaining and humidity."""
        body = bytearray(34)
        body[18] = 12  # storage_remaining
        body[33] = 60  # humidity
        parsed = Message34Body(body)
        assert parsed.storage_remaining == 12
        assert parsed.humidity == 60

    def test_short_body_optional_fields(self) -> None:
        """Test a short body has no humidity."""
        body = bytearray(25)
        body[18] = 7  # storage_remaining
        parsed = Message34Body(body)
        assert parsed.storage_remaining == 7
        assert parsed.humidity is None
