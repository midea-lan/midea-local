"""Test FD Device."""

from types import SimpleNamespace
from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.fd import DeviceAttributes, MideaFDDevice
from midealocal.devices.fd.message import MessageQuery, MessageSet
from midealocal.message import MessageType


def _build_device(subtype: int) -> MideaFDDevice:
    """Build a Midea FD device with the given subtype."""
    return MideaFDDevice(
        name="Test Device",
        device_id=1,
        ip_address="192.168.1.1",
        port=12345,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V1,
        model="test_model",
        subtype=subtype,
        customize="",
    )


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full FD response message."""
    header = bytearray(
        [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
    )
    return bytes(header + body + bytearray([0x00]))


class TestMideaFDDevice:
    """Test Midea FD Device."""

    device: MideaFDDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea FD Device setup."""
        self.device = _build_device(1)

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.fan_speed] is None
        assert self.device.attributes[DeviceAttributes.prompt_tone] is True
        assert self.device.attributes[DeviceAttributes.target_humidity] == 60
        assert self.device.attributes[DeviceAttributes.current_humidity] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] is None
        assert self.device.attributes[DeviceAttributes.tank] == 0
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.screen_display] is None
        assert self.device.attributes[DeviceAttributes.disinfect] is None

    def test_modes(self) -> None:
        """Test modes property."""
        assert self.device.modes == [
            "Manual",
            "Auto",
            "Continuous",
            "Living-Room",
            "Bed-Room",
            "Kitchen",
            "Sleep",
        ]

    def test_fan_speeds_old(self) -> None:
        """Test fan speeds property with an old subtype."""
        assert self.device.fan_speeds == [
            "Lowest",
            "Low",
            "Medium",
            "High",
            "Auto",
            "Off",
        ]

    def test_fan_speeds_new(self) -> None:
        """Test fan speeds property with a new subtype uses new speed keys."""
        device = _build_device(6)
        assert device.fan_speeds == [
            "Lowest",
            "Low",
            "Medium",
            "High",
            "Auto",
            "Off",
        ]
        body = bytearray(36)
        body[0] = 0xC8
        body[3] = 39
        device.process_message(_build_message(MessageType.query, body))
        assert device.attributes[DeviceAttributes.fan_speed] == "Low"

    def test_screen_displays(self) -> None:
        """Test screen displays property."""
        assert self.device.screen_displays == ["Bright", "Dim", "Off"]

    def test_detect_modes(self) -> None:
        """Test detect modes property."""
        assert self.device.detect_modes == ["Off", "PM 2.5", "Methanal"]

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_process_message_c8(self) -> None:
        """Test process message with a C8 body including disinfect."""
        body = bytearray(38)
        body[0] = 0xC8
        body[1] = 0x01  # power on
        body[3] = 40  # fan speed "Low"
        body[7] = 55  # target humidity
        body[8] = 0x10  # mode 1 "Manual"
        body[9] = 0x06  # screen display "Dim"
        body[10] = 2  # tank
        body[16] = 45  # current humidity
        body[17] = 90  # current temperature raw
        body[34] = 0x01  # disinfect on
        new_status = self.device.process_message(
            _build_message(MessageType.query, body),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.fan_speed] == "Low"
        assert self.device.attributes[DeviceAttributes.target_humidity] == 55
        assert self.device.attributes[DeviceAttributes.mode] == "Manual"
        assert self.device.attributes[DeviceAttributes.screen_display] == "Dim"
        assert self.device.attributes[DeviceAttributes.tank] == 2
        assert self.device.attributes[DeviceAttributes.current_humidity] == 45
        assert self.device.attributes[DeviceAttributes.current_temperature] == 20.0
        assert self.device.attributes[DeviceAttributes.disinfect] is True
        assert new_status[DeviceAttributes.power.value] is True

    def test_process_message_c8_short(self) -> None:
        """Test process message with a short C8 body without disinfect."""
        body = bytearray(36)
        body[0] = 0xC8
        body[3] = 3  # low raw fan speed is remapped to 1 "Lowest"
        body[8] = 0x70  # mode 7 "Sleep"
        body[9] = 0x03  # unknown screen display
        body[17] = 70
        self.device.process_message(_build_message(MessageType.set, body))
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.fan_speed] == "Lowest"
        assert self.device.attributes[DeviceAttributes.mode] == "Sleep"
        assert self.device.attributes[DeviceAttributes.screen_display] is None
        assert self.device.attributes[DeviceAttributes.current_temperature] == 10.0
        assert self.device.attributes[DeviceAttributes.disinfect] is None

    def test_process_message_a0(self) -> None:
        """Test process message with an A0 body including disinfect off."""
        body = bytearray(31)
        body[0] = 0xA0
        body[1] = 0x01  # power on
        body[3] = 60  # fan speed "Medium"
        body[7] = 50  # target humidity
        body[9] = 0x00  # screen display "Bright"
        body[10] = 0x0A  # tank 10, mode 2 "Auto"
        body[16] = 40  # current humidity
        body[17] = 70  # current temperature raw
        body[27] = 0x02  # disinfect off
        self.device.process_message(_build_message(MessageType.notify1, body))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.fan_speed] == "Medium"
        assert self.device.attributes[DeviceAttributes.target_humidity] == 50
        assert self.device.attributes[DeviceAttributes.mode] == "Auto"
        assert self.device.attributes[DeviceAttributes.screen_display] == "Bright"
        assert self.device.attributes[DeviceAttributes.tank] == 10
        assert self.device.attributes[DeviceAttributes.current_humidity] == 40
        assert self.device.attributes[DeviceAttributes.current_temperature] == 10.0
        assert self.device.attributes[DeviceAttributes.disinfect] is False

    def test_process_message_fan_speed_unknown(self) -> None:
        """Test process message with an unknown fan speed sets None."""
        body = bytearray(36)
        body[0] = 0xC8
        body[3] = 50  # not a known speed key
        self.device.process_message(_build_message(MessageType.query, body))
        assert self.device.attributes[DeviceAttributes.fan_speed] is None

    def test_process_message_unknown_values(self) -> None:
        """Test process message with out-of-range values sets None.

        A mode above the modes list length cannot be produced by the C8/A0
        body parsers, so the response is patched to exercise the fallback.
        """
        response = SimpleNamespace(mode=10, fan_speed=999, screen_display=99)
        with patch(
            "midealocal.devices.fd.MessageFDResponse",
            return_value=response,
        ):
            new_status = self.device.process_message(b"")
        assert new_status == {
            DeviceAttributes.mode.value: None,
            DeviceAttributes.fan_speed.value: None,
            DeviceAttributes.screen_display.value: None,
        }
        assert self.device.attributes[DeviceAttributes.mode] is None
        assert self.device.attributes[DeviceAttributes.fan_speed] is None
        assert self.device.attributes[DeviceAttributes.screen_display] is None

    def test_process_message_unhandled_body_type(self) -> None:
        """Test process message with an unhandled body type updates nothing."""
        body = bytearray(38)
        body[0] = 0xB0
        with patch("midealocal.message.MessageResponse.set_attr") as mock_set_attr:
            new_status = self.device.process_message(
                _build_message(MessageType.query, body),
            )
            mock_set_attr.assert_called_once()
        assert new_status == {}

    def test_make_message_set_defaults(self) -> None:
        """Test make message set with default attributes."""
        message = self.device.make_message_set()
        assert message.power is False
        assert message.prompt_tone is True
        assert message.mode == 1
        assert message.fan_speed == 40
        assert message.screen_display == 0
        assert message.disinfect is None

    def test_make_message_set_populated(self) -> None:
        """Test make message set with populated attributes."""
        self.device._attributes[DeviceAttributes.mode] = "Continuous"
        self.device._attributes[DeviceAttributes.fan_speed] = "High"
        self.device._attributes[DeviceAttributes.screen_display] = "Off"
        self.device._attributes[DeviceAttributes.disinfect] = True
        message = self.device.make_message_set()
        assert message.mode == 3
        assert message.fan_speed == 80
        assert message.screen_display == 7
        assert message.disinfect is True

    def test_set_attribute_prompt_tone(self) -> None:
        """Test set attribute prompt tone updates without sending."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            patch.object(self.device, "update_all") as mock_update_all,
        ):
            self.device.set_attribute(DeviceAttributes.prompt_tone.value, False)
            mock_build_send.assert_not_called()
            mock_update_all.assert_called_once_with(
                {DeviceAttributes.prompt_tone.value: False},
            )
        assert self.device.attributes[DeviceAttributes.prompt_tone] is False

    def test_set_attribute_mode(self) -> None:
        """Test set attribute mode converts the name to its index."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "Auto")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.mode == 2

    def test_set_attribute_mode_invalid(self) -> None:
        """Test set attribute with an unknown mode keeps the default."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode.value, "Invalid")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.mode == 1

    def test_set_attribute_fan_speed(self) -> None:
        """Test set attribute fan speed converts the name to its key."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, "Medium")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.fan_speed == 60

    def test_set_attribute_fan_speed_invalid(self) -> None:
        """Test set attribute with an unknown fan speed keeps the default."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, "Turbo")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.fan_speed == 40

    def test_set_attribute_screen_display(self) -> None:
        """Test set attribute screen display converts the name to its key."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.screen_display.value, "Dim")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.screen_display == 6

    def test_set_attribute_screen_display_falsy(self) -> None:
        """Test set attribute with a falsy screen display turns it off."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.screen_display.value, "")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.screen_display == 7

    def test_set_attribute_screen_display_invalid(self) -> None:
        """Test set attribute with an unknown screen display keeps the default."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.screen_display.value, "Invalid")
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.screen_display == 0

    def test_set_attribute_power(self) -> None:
        """Test set attribute power sends the value."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.power is True

    def test_set_attribute_disinfect(self) -> None:
        """Test set attribute disinfect sends the value."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageSet)
            assert message.disinfect is True
