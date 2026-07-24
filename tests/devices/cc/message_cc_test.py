"""Test cc message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.crc8 import calculate
from midealocal.devices.cc.message import (
    CCControlId,
    CCGeneralMessageBody,
    MessageCCBase,
    MessageCCResponse,
    MessageFEControl,
    MessageQuery,
    MessageSet,
)
from midealocal.message import ListTypes, MessageType


class TestCCMessageBase:
    """Test CC message base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageCCBase(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestCCMessageQuery:
    """Test CC message query."""

    def test_query_body(self) -> None:
        """Test query body (body_type byte followed by 23 zero bytes)."""
        msg = MessageQuery(protocol_version=ProtocolVersion.V3)
        assert msg.body == bytearray([0x01]) + bytearray([0x00] * 23)


class TestCCGeneralMessageBody:
    """Test CC general message body."""

    def test_legacy_body(self) -> None:
        """Legacy (non-0xFE) payloads keep the original decoding."""
        body = bytearray(21)
        # body[1] is power/mode (not 0xFE) -> legacy path
        body[1] = 0x80 | 0x04  # power on, mode bit2
        body[3] = 24  # target temperature integer
        body[4] = 90  # indoor temperature -> (90 - 40) / 2 = 25
        message = CCGeneralMessageBody(body)
        assert message.is_fe_format is False
        assert message.power is True
        assert message.indoor_temperature == 25.0

    def test_fe_body(self) -> None:
        """0xFE VRF panel payloads use the new decoding."""
        body = bytearray(90)
        body[0] = 0x01
        body[1] = 0xFE  # format byte -> 0xFE path
        body[8] = 1  # power on
        body[11] = 128  # target temperature -> 128 / 2 - 40 = 24.0
        body[12] = 0
        body[13] = 235  # indoor temperature -> 235 / 10 = 23.5
        body[21] = 0  # celsius
        body[31] = 0x02  # operational mode COOL -> index 4
        body[34] = 5  # fan speed level 5
        body[41] = 0x06  # vertical louver auto -> swing on
        body[56] = 1  # eco on
        body[60] = 1  # sleep on
        message = CCGeneralMessageBody(body)
        assert message.is_fe_format is True
        assert message.power is True
        assert message.target_temperature == 24.0
        assert message.indoor_temperature == 23.5
        assert message.mode == 4
        assert message.fan_speed == 5
        assert message.swing is True
        assert message.eco_mode is True
        assert message.sleep_mode is True
        assert message.temp_fahrenheit is False

    def test_fe_body_invalid_indoor_temperature(self) -> None:
        """A zero (no-reading) indoor temperature is reported as None."""
        body = bytearray(90)
        body[1] = 0xFE
        body[12] = 0
        body[13] = 0  # no reading (device off) -> None rather than 0.0
        message = CCGeneralMessageBody(body)
        assert message.indoor_temperature is None


class TestCCMessageSet:
    """Test CC message set body."""

    def test_default_body(self) -> None:
        """Default set body encodes power off, mode 4 and 26 degrees."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        body = msg.body
        assert body[0] == 0xC3  # body_type
        assert body[1] == 0x08  # power off, mode 4 -> 1 << 3
        assert body[2] == 0x80  # fan speed auto
        assert body[3] == 26  # temperature integer
        assert body[6] == 0x00  # eco/ventilation/swing/aux all off
        assert body[7] == 0xFF  # non-stepless fan speed
        assert body[8] == 0x00  # sleep/night light off
        assert body[11] == 0  # temperature dot

    def test_full_body(self) -> None:
        """All flags set are encoded into the expected bytes."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.power = True
        msg.mode = 1
        msg.fan_speed = 0x40
        msg.target_temperature = 24.5
        msg.eco_mode = True
        msg.ventilation = True
        msg.swing = True
        msg.aux_heat_status = 1
        msg.sleep_mode = True
        msg.night_light = True
        body = msg.body
        assert body[1] == 0x80 | 0x01  # power on, mode 1
        assert body[2] == 0x40
        assert body[3] == 24
        assert body[6] == 0x01 | 0x08 | 0x04 | 0x10  # eco|vent|swing|aux x10
        assert body[8] == 0x10 | 0x08  # sleep|night light
        assert body[11] == 5  # 0.5 degree dot

    def test_aux_heat_status_x20(self) -> None:
        """Aux heat status 2 is encoded as 0x20."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.aux_heat_status = 2
        assert msg.body[6] == 0x20


class TestMessageFEControl:
    """Test CC 0xFE key-value control frame."""

    def test_power_control_body(self) -> None:
        """A single power control builds the expected TLV frame."""
        MessageFEControl._message_id = 0
        msg = MessageFEControl(
            protocol_version=ProtocolVersion.V3,
            controls=[(CCControlId.POWER, 1)],
        )
        payload = bytearray([0x00, 0x00, 0x01, 0x01, 0xFF, 0x01])
        payload.append(calculate(payload))
        assert msg.body == payload

    def test_multi_control_body(self) -> None:
        """Power + mode controls are concatenated in order."""
        MessageFEControl._message_id = 0
        msg = MessageFEControl(
            protocol_version=ProtocolVersion.V3,
            controls=[(CCControlId.POWER, 1), (CCControlId.MODE, 0x03)],
        )
        payload = bytearray(
            [0x00, 0x00, 0x01, 0x01, 0xFF, 0x00, 0x12, 0x01, 0x03, 0xFF, 0x01],
        )
        payload.append(calculate(payload))
        assert msg.body == payload

    def test_private_body_is_empty(self) -> None:
        """The unused _body property stays empty (body is fully overridden)."""
        msg = MessageFEControl(
            protocol_version=ProtocolVersion.V3,
            controls=[(CCControlId.POWER, 1)],
        )
        assert msg._body == bytearray()


def _build_response(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full CC response message."""
    header = bytearray([0xAA, 0x00, 0xCC, 0x00, 0x00, 0x00, 0x00, 0x00])
    header += bytearray([ProtocolVersion.V1, message_type])
    return bytes(header + body + bytearray([0x00]))


class TestMessageCCResponse:
    """Test CC message response parsing."""

    def _legacy_body(self, body_type: int) -> bytearray:
        body = bytearray(22)
        body[0] = body_type
        body[1] = 0x81  # power on, mode 1
        body[4] = 90  # indoor temperature 25.0
        return body

    def test_query_x01_parsed(self) -> None:
        """Query responses with body type X01 are decoded."""
        response = MessageCCResponse(
            _build_response(MessageType.query, self._legacy_body(0x01)),
        )
        assert getattr(response, "power", None) is True
        assert getattr(response, "indoor_temperature", None) == 25.0

    def test_notify1_x01_parsed(self) -> None:
        """Notify1 responses with body type X01 are decoded."""
        response = MessageCCResponse(
            _build_response(MessageType.notify1, self._legacy_body(0x01)),
        )
        assert getattr(response, "power", None) is True

    def test_notify2_x01_parsed(self) -> None:
        """Notify2 responses with body type X01 are decoded."""
        response = MessageCCResponse(
            _build_response(MessageType.notify2, self._legacy_body(0x01)),
        )
        assert getattr(response, "power", None) is True

    def test_set_c3_parsed(self) -> None:
        """Set responses with body type C3 are decoded."""
        response = MessageCCResponse(
            _build_response(MessageType.set, self._legacy_body(0xC3)),
        )
        assert getattr(response, "power", None) is True

    def test_set_x01_not_parsed(self) -> None:
        """Set responses with body type X01 are left undecoded."""
        response = MessageCCResponse(
            _build_response(MessageType.set, self._legacy_body(0x01)),
        )
        assert getattr(response, "power", None) is None
