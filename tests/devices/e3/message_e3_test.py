"""Test E3 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e3.message import (
    MessageE3Base,
    MessageNewProtocolSet,
    MessagePower,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


class TestMessageE3Base:
    """Test E3 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageE3Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test E3 Message Query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01, 0x01])


class TestMessagePower:
    """Test E3 Message Power."""

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


class TestMessageSet:
    """Test E3 Message Set."""

    @pytest.mark.parametrize(
        ("attrs", "byte1", "byte2", "byte4"),
        [
            ({}, 0x02, 0x00, 0),
            ({"zero_cold_water": True}, 0x03, 0x00, 0),
            ({"protection": True}, 0x02, 0x08, 0),
            ({"zero_cold_pulse": True}, 0x02, 0x10, 0),
            ({"smart_volume": True}, 0x02, 0x20, 0),
            ({"target_temperature": 40.5}, 0x02, 0x00, 40),
        ],
    )
    def test_set_body(
        self,
        attrs: dict[str, bool | float],
        byte1: int,
        byte2: int,
        byte4: int,
    ) -> None:
        """Test set body for each settable attribute."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        for key, value in attrs.items():
            setattr(msg, key, value)
        expected = bytearray([0x01, byte1, byte2, 0x00, byte4] + [0x00] * 9)
        assert msg.body[1:] == expected
        assert msg.body_type == ListTypes.X04


class TestMessageNewProtocolSet:
    """Test E3 Message New Protocol Set."""

    @pytest.mark.parametrize(
        ("key", "value", "expected_key", "expected_value"),
        [
            ("target_temperature", 40.5, 0x08, 40),
            ("zero_cold_water", True, 0x03, 0x01),
            ("zero_cold_pulse", False, 0x04, 0x00),
            ("smart_volume", True, 0x07, 0x01),
        ],
    )
    def test_new_protocol_set_body(
        self,
        key: str,
        value: bool | float,
        expected_key: int,
        expected_value: int,
    ) -> None:
        """Test new protocol set body for each parameter."""
        msg = MessageNewProtocolSet(protocol_version=ProtocolVersion.V1)
        msg.key = key
        msg.value = value
        expected = bytearray([expected_key, expected_value] + [0x00] * 17)
        assert msg.body[1:] == expected
        assert msg.body_type == ListTypes.X14
