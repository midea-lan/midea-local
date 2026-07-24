"""Test C2 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.c2.message import (
    C2Notify1MessageBody,
    MessageC2Base,
    MessagePower,
    MessagePowerOff,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


class TestMessageC2Base:
    """Test C2 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageC2Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test C2 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01, 0x01])


class TestMessagePower:
    """Test C2 Message Power."""

    def test_power_on(self) -> None:
        """Test power on body switches body type to 0x01."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        msg.power = True
        assert msg.body[1:] == bytearray([0x01])
        assert msg.body_type == ListTypes.X01

    def test_power_off(self) -> None:
        """Test power off body switches body type to 0x02."""
        msg = MessagePower(protocol_version=ProtocolVersion.V1)
        msg.power = False
        assert msg.body[1:] == bytearray([0x01])
        assert msg.body_type == ListTypes.X02


class TestMessagePowerOff:
    """Test C2 Message Power Off."""

    def test_power_off_body(self) -> None:
        """Test power off body."""
        msg = MessagePowerOff(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x02, 0x01])


class TestMessageSet:
    """Test C2 Message Set."""

    @pytest.mark.parametrize(
        ("attr", "value", "expected"),
        [
            ("child_lock", True, bytearray([0x10, 0x10])),
            ("child_lock", False, bytearray([0x10, 0x00])),
            ("sensor_light", True, bytearray([0x01, 0x02])),
            ("water_temp_level", 3, bytearray([0x09, 0x03])),
            ("seat_temp_level", 4, bytearray([0x0A, 0x20])),
            ("dry_level", 2, bytearray([0x0C, 0x04])),
            ("foam_shield", True, bytearray([0x1F, 0x04])),
        ],
    )
    def test_set_body(
        self,
        attr: str,
        value: bool | int,
        expected: bytearray,
    ) -> None:
        """Test set body for each settable attribute."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        setattr(msg, attr, value)
        assert msg.body[1:] == expected
        assert msg.body_type == ListTypes.X14


class TestC2Notify1MessageBody:
    """Test C2 Notify1 Message Body."""

    def test_notify1_body(self) -> None:
        """Test notify1 body initialization."""
        body = C2Notify1MessageBody(bytearray([0x01, 0x00]))
        assert body.data == bytearray([0x01, 0x00])
