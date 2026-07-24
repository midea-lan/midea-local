"""Test B6 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.b6.message import (
    B6ExceptionBody,
    B6FeedbackBody,
    B6GeneralBody,
    B6NewProtocolBody,
    B6SpecialBody,
    MessageB6Base,
    MessageB6Response,
    MessageQuery,
    MessageQueryTips,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


def _build_message(
    protocol_version: int,
    message_type: MessageType,
    body: bytearray,
) -> bytes:
    """Build a full B6 response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [protocol_version] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMessageB6Base:
    """Test B6 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageB6Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X11,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestMessageQuery:
    """Test B6 Message Query."""

    def test_query_new_protocol(self) -> None:
        """Test query with the new protocol version."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V2)
        assert msg.body_type == ListTypes.X11
        assert msg.body == bytearray([0x11])

    def test_query_old_protocol(self) -> None:
        """Test query with an old protocol version."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V1)
        assert msg.body_type == ListTypes.X31
        assert msg.body == bytearray([0x31])


class TestMessageQueryTips:
    """Test B6 Message Query Tips."""

    def test_query_tips_body(self) -> None:
        """Test query tips body."""
        msg = MessageQueryTips(protocol_version=ProtocolVersion.V1)
        assert msg.body_type == ListTypes.X02
        assert msg.body == bytearray([0x02, 0x01])


class TestMessageSetOldProtocol:
    """Test B6 Message Set with protocol version 0 or 1."""

    def test_body_defaults(self) -> None:
        """Test set body defaults."""
        msg = MessageSet(protocol_version=0)
        assert msg.body_type == ListTypes.X22
        assert msg._body == bytearray(
            [0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        )

    def test_body_light_on(self) -> None:
        """Test set body with light on."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.light = 1
        assert msg._body == bytearray(
            [0x01, 0x1A, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        )

    def test_body_light_off(self) -> None:
        """Test set body with light off."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.light = 0
        assert msg._body == bytearray(
            [0x01, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        )

    def test_body_power_on_with_fan_level(self) -> None:
        """Test set body with power on and a fan level."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        msg.fan_level = 2
        assert msg._body == bytearray(
            [0x01, 0xFF, 0x02, 0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        )

    def test_body_power_on_without_fan_level(self) -> None:
        """Test set body with power on and no fan level."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        assert msg._body == bytearray(
            [0x01, 0xFF, 0x02, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        )

    def test_body_power_off(self) -> None:
        """Test set body with power off."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = False
        assert msg._body == bytearray(
            [0x01, 0xFF, 0x03, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        )

    def test_body_fan_level_zero(self) -> None:
        """Test set body with fan level zero."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.fan_level = 0
        assert msg._body == bytearray(
            [0x01, 0xFF, 0x03, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        )

    def test_body_fan_level_set(self) -> None:
        """Test set body with a positive fan level."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.fan_level = 3
        assert msg._body == bytearray(
            [0x01, 0xFF, 0x02, 0x03, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
        )


class TestMessageSetNewProtocol:
    """Test B6 Message Set with protocol version 2."""

    def test_body_defaults(self) -> None:
        """Test set body defaults."""
        msg = MessageSet(protocol_version=ProtocolVersion.V2)
        assert msg.body_type == ListTypes.X11
        assert msg._body == bytearray([0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])

    def test_body_power_on_with_fan_level(self) -> None:
        """Test set body with power on and a fan level."""
        msg = MessageSet(protocol_version=ProtocolVersion.V2)
        msg.power = True
        msg.fan_level = 3
        assert msg._body == bytearray([0x01, 0x01, 0xFF, 0x02, 0x03, 0xFF, 0xFF])

    def test_body_power_on_without_fan_level(self) -> None:
        """Test set body with power on and no fan level."""
        msg = MessageSet(protocol_version=ProtocolVersion.V2)
        msg.power = True
        assert msg._body == bytearray([0x01, 0x01, 0xFF, 0x02, 0x01, 0xFF, 0xFF])

    def test_body_power_off(self) -> None:
        """Test set body with power off."""
        msg = MessageSet(protocol_version=ProtocolVersion.V2)
        msg.power = False
        assert msg._body == bytearray([0x01, 0x01, 0xFF, 0x01, 0xFF, 0xFF, 0xFF])

    def test_body_fan_level_zero(self) -> None:
        """Test set body with fan level zero."""
        msg = MessageSet(protocol_version=ProtocolVersion.V2)
        msg.fan_level = 0
        assert msg._body == bytearray([0x01, 0x01, 0xFF, 0x01, 0xFF, 0xFF, 0xFF])

    def test_body_fan_level_set(self) -> None:
        """Test set body with a positive fan level."""
        msg = MessageSet(protocol_version=ProtocolVersion.V2)
        msg.fan_level = 2
        assert msg._body == bytearray([0x01, 0x01, 0xFF, 0x02, 0x02, 0xFF, 0xFF])

    def test_body_light_on(self) -> None:
        """Test set body with light on."""
        msg = MessageSet(protocol_version=ProtocolVersion.V2)
        msg.light = 1
        assert msg._body == bytearray([0x01, 0x02, 0x02, 0x01, 0xFF, 0xFF, 0xFF])

    def test_body_light_off(self) -> None:
        """Test set body with light off."""
        msg = MessageSet(protocol_version=ProtocolVersion.V2)
        msg.light = 0
        assert msg._body == bytearray([0x01, 0x02, 0x02, 0x00, 0xFF, 0xFF, 0xFF])


class TestB6MessageBodies:
    """Test B6 message bodies."""

    def test_feedback_body(self) -> None:
        """Test feedback body."""
        body = B6FeedbackBody(bytearray([0x11, 0x01]))
        assert body.data == bytearray([0x11, 0x01])

    def test_exception_body(self) -> None:
        """Test exception body."""
        body = B6ExceptionBody(bytearray([0x32, 0x01]))
        assert body.data == bytearray([0x32, 0x01])

    def test_general_body_all_unset(self) -> None:
        """Test general body with all bytes unset."""
        body = B6GeneralBody(bytearray([0x11, 0xFF, 0xFF, 0xFF, 0x00, 0x03]))
        assert not hasattr(body, "light")
        assert body.power is False
        assert body.fan_level == 0
        assert body.oilcup_full is True
        assert body.cleaning_reminder is True

    def test_general_body_power_on(self) -> None:
        """Test general body with power on and a plain fan level."""
        body = B6GeneralBody(bytearray([0x11, 0x01, 0x02, 0x05, 0x00, 0x00]))
        assert body.light is True
        assert body.power is True
        assert body.fan_level == 5
        assert body.oilcup_full is False
        assert body.cleaning_reminder is False

    def test_general_body_fan_level_from_power_byte(self) -> None:
        """Test general body where the power byte forces the fan level."""
        body = B6GeneralBody(bytearray([0x11, 0x00, 0x14, 0x05, 0x00, 0x00]))
        assert body.light is False
        assert body.power is True
        assert body.fan_level == 0x16

    @pytest.mark.parametrize(
        ("raw_level", "expected"),
        [(110, 1), (135, 2), (150, 3), (200, 4)],
    )
    def test_general_body_fan_level_ranges(self, raw_level: int, expected: int) -> None:
        """Test general body fan level range mapping."""
        body = B6GeneralBody(bytearray([0x11, 0xFF, 0xFF, raw_level, 0x00, 0x00]))
        assert body.fan_level == expected

    def test_new_protocol_body(self) -> None:
        """Test new protocol body with all fields set."""
        pack = bytearray(19)
        pack[1] = 0x02  # power on
        pack[2] = 0x03  # fan level
        pack[6] = 0x01  # light on
        pack[18] = 0x06  # oilcup full and cleaning reminder
        body = B6NewProtocolBody(bytearray([0x11, 0x01, 0x13]) + pack)
        assert body.power is True
        assert body.fan_level == 3
        assert body.light is True
        assert body.oilcup_full is True
        assert body.cleaning_reminder is True

    def test_new_protocol_body_unset_bytes(self) -> None:
        """Test new protocol body with unset pack bytes."""
        pack = bytearray(19)
        pack[1] = 0xFF
        pack[2] = 0xFF
        pack[6] = 0xFF
        body = B6NewProtocolBody(bytearray([0x11, 0x01, 0x13]) + pack)
        assert not hasattr(body, "power")
        assert not hasattr(body, "fan_level")
        assert not hasattr(body, "light")
        assert body.oilcup_full is False
        assert body.cleaning_reminder is False

    def test_new_protocol_body_power_off(self) -> None:
        """Test new protocol body with power off."""
        pack = bytearray(19)
        pack[1] = 0x01  # power off value
        pack[2] = 0xFF
        pack[6] = 0xFF
        body = B6NewProtocolBody(bytearray([0x11, 0x01, 0x13]) + pack)
        assert body.power is False

    def test_new_protocol_body_not_parsed(self) -> None:
        """Test new protocol body with an unhandled second byte."""
        body = B6NewProtocolBody(bytearray([0x11, 0x02, 0x00]))
        assert not hasattr(body, "power")
        assert not hasattr(body, "oilcup_full")

    def test_special_body(self) -> None:
        """Test special body with all fields set."""
        body = B6SpecialBody(bytearray([0x22, 0x01, 0x01, 0x02, 0x03]))
        assert body.light is True
        assert body.power is True
        assert body.fan_level == 3

    def test_special_body_unset_bytes(self) -> None:
        """Test special body with unset bytes."""
        body = B6SpecialBody(bytearray([0x22, 0x01, 0xFF, 0xFF, 0xFF]))
        assert not hasattr(body, "light")
        assert body.power is False
        assert not hasattr(body, "fan_level")


class TestMessageB6Response:
    """Test B6 Message Response."""

    def test_set_special_body(self) -> None:
        """Test set response with a special body."""
        body = bytearray([0x22, 0x01, 0x01, 0x02, 0x03])
        msg = MessageB6Response(_build_message(0x01, MessageType.set, body))
        assert getattr(msg, "light", None) is True
        assert getattr(msg, "power", None) is True
        assert getattr(msg, "fan_level", None) == 3

    def test_set_x11_body_ignored(self) -> None:
        """Test set response with an X11 body is ignored."""
        body = bytearray([0x11, 0x01, 0x01, 0x02, 0x03])
        msg = MessageB6Response(_build_message(0x01, MessageType.set, body))
        assert not hasattr(msg, "power")

    def test_query_general_body(self) -> None:
        """Test query response with a general body on an old protocol."""
        body = bytearray([0x11, 0x01, 0x02, 0x02, 0x00, 0x03])
        msg = MessageB6Response(_build_message(0x01, MessageType.query, body))
        assert getattr(msg, "light", None) is True
        assert getattr(msg, "power", None) is True
        assert getattr(msg, "fan_level", None) == 2
        assert getattr(msg, "oilcup_full", None) is True
        assert getattr(msg, "cleaning_reminder", None) is True

    def test_query_new_protocol_body(self) -> None:
        """Test query response with a new protocol body."""
        pack = bytearray(19)
        pack[1] = 0x02
        pack[2] = 0x02
        pack[6] = 0x01
        body = bytearray([0x31, 0x01, 0x13]) + pack
        msg = MessageB6Response(_build_message(0x02, MessageType.query, body))
        assert getattr(msg, "power", None) is True
        assert getattr(msg, "fan_level", None) == 2
        assert getattr(msg, "light", None) is True

    def test_query_exception_body(self) -> None:
        """Test query response with an exception body."""
        body = bytearray([0x32, 0x01, 0x00])
        msg = MessageB6Response(_build_message(0x01, MessageType.query, body))
        assert not hasattr(msg, "power")

    def test_query_unhandled_body(self) -> None:
        """Test query response with an unhandled body type."""
        body = bytearray([0x33, 0x01, 0x00])
        msg = MessageB6Response(_build_message(0x01, MessageType.query, body))
        assert not hasattr(msg, "power")

    def test_notify1_general_body(self) -> None:
        """Test notify1 response with a general body on an old protocol."""
        body = bytearray([0x41, 0x01, 0x02, 0x01, 0x00, 0x00])
        msg = MessageB6Response(_build_message(0x00, MessageType.notify1, body))
        assert getattr(msg, "power", None) is True
        assert getattr(msg, "fan_level", None) == 1

    def test_notify1_new_protocol_body(self) -> None:
        """Test notify1 response with a new protocol body."""
        pack = bytearray(19)
        pack[1] = 0x00
        pack[2] = 0x01
        pack[6] = 0x00
        body = bytearray([0x11, 0x01, 0x13]) + pack
        msg = MessageB6Response(_build_message(0x02, MessageType.notify1, body))
        assert getattr(msg, "power", None) is False
        assert getattr(msg, "fan_level", None) == 1
        assert getattr(msg, "light", None) is False

    def test_notify1_exception_body(self) -> None:
        """Test notify1 response with an exception body."""
        body = bytearray([0x0A, 0xA1, 0x00])
        msg = MessageB6Response(_build_message(0x01, MessageType.notify1, body))
        assert not hasattr(msg, "power")

    def test_notify1_tips_body(self) -> None:
        """Test notify1 response with a tips body."""
        body = bytearray([0x0A, 0xA2, 0x03])
        msg = MessageB6Response(_build_message(0x01, MessageType.notify1, body))
        assert getattr(msg, "oilcup_full", None) is True
        assert getattr(msg, "cleaning_reminder", None) is True

    def test_notify1_unhandled_x0a_body(self) -> None:
        """Test notify1 response with an unhandled X0A sub body."""
        body = bytearray([0x0A, 0xA3, 0x03])
        msg = MessageB6Response(_build_message(0x01, MessageType.notify1, body))
        assert not hasattr(msg, "oilcup_full")

    def test_exception2_response(self) -> None:
        """Test exception2 response is ignored."""
        body = bytearray([0xA1, 0x00, 0x00])
        msg = MessageB6Response(_build_message(0x01, MessageType.exception2, body))
        assert not hasattr(msg, "power")

    def test_unhandled_message_type(self) -> None:
        """Test response with an unhandled message type."""
        body = bytearray([0x11, 0x01, 0x00])
        msg = MessageB6Response(_build_message(0x01, MessageType.notify2, body))
        assert not hasattr(msg, "power")
