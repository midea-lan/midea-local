"""Test cc message."""

from midealocal.const import ProtocolVersion
from midealocal.crc8 import calculate
from midealocal.devices.cc.message import (
    CCControlId,
    CCGeneralMessageBody,
    MessageFEControl,
    MessageQuery,
)


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
