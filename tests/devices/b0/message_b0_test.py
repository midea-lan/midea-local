"""Test B0 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.b0.message import (
    B0Message01Body,
    B0Message31Body,
    B0MessageBody,
    MessageB0Base,
    MessageB0Response,
    MessageIncreaseControl,
    MessageQuery00,
    MessageQuery01,
    MessageQuery31,
    MessageSetControl,
    MessageSetNotWorkMode,
    MessageSetWorkMode,
)
from midealocal.message import ListTypes, MessageType


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full B0 response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMessageB0Base:
    """Test B0 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageB0Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQueries:
    """Test B0 Message Queries."""

    def test_query_00_body(self) -> None:
        """Test query 00 body only contains the body type."""
        msg = MessageQuery00(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x00])

    def test_query_01_body(self) -> None:
        """Test query 01 body only contains the body type."""
        msg = MessageQuery01(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x01])

    def test_query_31_body(self) -> None:
        """Test query 31 body only contains the body type."""
        msg = MessageQuery31(protocol_version=ProtocolVersion.V1)
        assert msg.body == bytearray([0x31])


class TestMessageSetWorkMode:
    """Test B0 Message Set Work Mode."""

    def test_body_defaults(self) -> None:
        """Test set work mode body defaults."""
        msg = MessageSetWorkMode(protocol_version=ProtocolVersion.V1)
        assert msg._body == bytearray(
            [
                0x01,
                0x00,
                0x00,
                0x00,
                0x11,
                0x00,
                0x00,  # hours
                0x01,  # minutes
                0x00,  # seconds
                0xFF,  # mode
                0x00,  # temperature high
                0x00,  # temperature low
                0x00,
                0x00,
                0xFF,  # fire power
                0xFF,
                0xFF,
                0x00,
            ],
        )

    def test_body_custom(self) -> None:
        """Test set work mode body with custom values."""
        msg = MessageSetWorkMode(
            protocol_version=ProtocolVersion.V1,
            mode=0x01,
            fire_power=0x05,
            work_time=3725,
            temperature=300,
        )
        body = msg._body
        assert body[6] == 1  # hours
        assert body[7] == 2  # minutes
        assert body[8] == 5  # seconds
        assert body[9] == 0x01  # mode
        assert body[10] == 0x01  # temperature high
        assert body[11] == 44  # temperature low
        assert body[12] == 0x01
        assert body[13] == 44
        assert body[14] == 0x05  # fire power


class TestMessageSetNotWorkMode:
    """Test B0 Message Set Not Work Mode."""

    def test_body_defaults(self) -> None:
        """Test set not work mode body defaults."""
        msg = MessageSetNotWorkMode(protocol_version=ProtocolVersion.V1)
        assert msg._body == bytearray([0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])

    def test_body_status(self) -> None:
        """Test set not work mode body with a status value."""
        msg = MessageSetNotWorkMode(
            protocol_version=ProtocolVersion.V1,
            status=0x03,
            child_lock=0x01,
            door=0x00,
        )
        assert msg._body == bytearray([0x02, 0x03, 0x01, 0xFF, 0xFF, 0x00])

    def test_body_power(self) -> None:
        """Test set not work mode body falls back to the power value."""
        msg = MessageSetNotWorkMode(
            protocol_version=ProtocolVersion.V1,
            power=0x02,
        )
        assert msg._body == bytearray([0x02, 0x02, 0xFF, 0xFF, 0xFF, 0xFF])


class TestMessageIncreaseControl:
    """Test B0 Message Increase Control."""

    def test_body_defaults(self) -> None:
        """Test increase control body defaults."""
        msg = MessageIncreaseControl(protocol_version=ProtocolVersion.V1)
        body = msg._body
        assert body[0] == 0x03
        assert body[6] == 0  # hours
        assert body[7] == 0  # minutes
        assert body[8] == 0  # seconds
        assert body[11] == 0xFF  # temperature increase unset

    def test_body_custom(self) -> None:
        """Test increase control body with custom values."""
        msg = MessageIncreaseControl(
            protocol_version=ProtocolVersion.V1,
            time_increase=3661,
            temperature_increase=15,
        )
        body = msg._body
        assert body[6] == 1
        assert body[7] == 1
        assert body[8] == 1
        assert body[11] == 15


class TestMessageSetControl:
    """Test B0 Message Set Control."""

    def test_body_defaults(self) -> None:
        """Test set control body defaults."""
        msg = MessageSetControl(protocol_version=ProtocolVersion.V1)
        body = msg._body
        assert body[0] == 0x04
        assert body[6] == 0xFF  # hours unset
        assert body[7] == 0xFF  # minutes unset
        assert body[8] == 0xFF  # seconds unset
        assert body[10] == 0xFF  # temperature disabled
        assert body[11] == 0xFF  # temperature unset
        assert body[14] == 0xFF  # fire power

    def test_body_custom(self) -> None:
        """Test set control body with custom values."""
        msg = MessageSetControl(
            protocol_version=ProtocolVersion.V1,
            work_time=3661,
            fire_power=0x08,
            temperature=120,
        )
        body = msg._body
        assert body[6] == 1
        assert body[7] == 1
        assert body[8] == 1
        assert body[10] == 0x00  # temperature enabled
        assert body[11] == 120
        assert body[14] == 0x08


class TestB0MessageBodies:
    """Test B0 message bodies."""

    def test_default_body_short(self) -> None:
        """Test default body with a too short payload sets nothing."""
        body = B0MessageBody(bytearray(10))
        assert not hasattr(body, "door")
        assert not hasattr(body, "status")

    def test_default_body(self) -> None:
        """Test default body parsing."""
        raw = bytearray(17)
        raw[0] = 0x82  # door bit and status
        raw[1] = 0x02  # mode
        raw[2] = 2  # minutes
        raw[3] = 5  # seconds
        raw[4] = 1  # work stage
        raw[5] = 2  # error code
        raw[6] = 3  # tips code
        raw[7] = 4  # maintain
        raw[14] = 5  # fire power
        body = B0MessageBody(raw)
        assert body.door is True
        assert body.status == 0x02
        assert body.mode == 0x02
        assert body.time_remaining == 125
        assert body.work_stage == 1
        assert body.error_code == 2
        assert body.tips_code == 3
        assert body.maintain == 4
        assert body.fire_power == 5

    def test_01_body_time_unset(self) -> None:
        """Test 01 body with unset time bytes and a direct temperature."""
        raw = bytearray(34)
        raw[0] = 0x01
        raw[22] = 0xFF
        raw[23] = 0xFF
        raw[24] = 0xFF
        raw[25] = 0x01  # temperature high byte
        raw[26] = 44  # temperature low byte
        raw[31] = 0x03
        raw[32] = 0x0C  # tank ejected and water shortage
        body = B0Message01Body(raw)
        assert body.time_remaining == 0
        assert body.current_temperature == 300
        assert body.status == 0x03
        assert body.door is False
        assert body.tank_ejected is True
        assert body.water_shortage is True
        assert body.water_change_reminder is False

    def test_31_body_preheat_off(self) -> None:
        """Test 31 body with preheat off and no valid temperatures."""
        raw = bytearray(18)
        raw[0] = 0x31
        raw[1] = 0x02
        raw[11] = 0xFF  # invalid temperature above
        raw[13] = 0xFF  # invalid temperature under
        raw[15] = 10  # weight
        body = B0Message31Body(raw)
        assert body.pre_heat == "Off"
        assert not hasattr(body, "current_temperature")
        assert body.weight == 100
        assert body.people_number == 10

    def test_31_body_preheat_working(self) -> None:
        """Test 31 body with preheat working."""
        raw = bytearray(18)
        raw[0] = 0x31
        raw[16] = 0x20  # preheat bit
        body = B0Message31Body(raw)
        assert body.pre_heat == "Working"
        assert body.error_code == 0

    def test_31_body_preheat_end(self) -> None:
        """Test 31 body with preheat end and the error bit."""
        raw = bytearray(18)
        raw[0] = 0x31
        raw[16] = 0xC0  # preheat end and error bits
        body = B0Message31Body(raw)
        assert body.pre_heat == "End"
        assert body.error_code == 1


class TestMessageB0Response:
    """Test B0 Message Response."""

    def test_response_31_body(self) -> None:
        """Test response with a 31 body parses attributes."""
        body = bytearray(18)
        body[0] = 0x31
        body[1] = 0x03
        msg = MessageB0Response(bytearray(_build_message(MessageType.query, body)))
        assert hasattr(msg, "status")

    def test_response_04_body(self) -> None:
        """Test response with a 04 body parses nothing."""
        body = bytearray(18)
        body[0] = 0x04
        msg = MessageB0Response(bytearray(_build_message(MessageType.query, body)))
        assert not hasattr(msg, "status")

    def test_response_unhandled_message_type(self) -> None:
        """Test response with an unhandled message type parses nothing."""
        body = bytearray(18)
        body[0] = 0x31
        msg = MessageB0Response(bytearray(_build_message(MessageType.notify2, body)))
        assert not hasattr(msg, "status")
