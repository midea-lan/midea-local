"""Test CC Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.cc import DeviceAttributes, MideaCCDevice
from midealocal.devices.cc.message import (
    CCControlId,
    MessageFEControl,
    MessageQuery,
    MessageSet,
)
from midealocal.message import MessageType


def _build_message(message_type: MessageType, body: bytearray) -> bytes:
    """Build a full CC response message."""
    header = bytearray([0xAA, 0x00, 0xCC, 0x00, 0x00, 0x00, 0x00, 0x00])
    header += bytearray([ProtocolVersion.V1, message_type])
    return bytes(header + body + bytearray([0x00]))


def _legacy_frame(
    byte1: int = 0x88,
    fan_speed: int = 0x10,
    temp_int: int = 24,
    temp_dot: int = 5,
    indoor: int = 90,
    byte13: int = 0x00,
    byte14: int = 0x00,
    byte20: int = 0x00,
    message_type: MessageType = MessageType.query,
) -> bytes:
    """Build a legacy (non-0xFE) CC query response frame."""
    body = bytearray(22)
    body[0] = 0x01  # body_type X01
    body[1] = byte1
    body[2] = fan_speed
    body[3] = temp_int
    body[4] = indoor
    body[13] = byte13
    body[14] = byte14
    body[19] = temp_dot
    body[20] = byte20
    return _build_message(message_type, body)


def _fe_frame(fan_speed: int = 5) -> bytes:
    """Build a 0xFE VRF panel CC query response frame."""
    body = bytearray(70)
    body[0] = 0x01  # body_type X01
    body[1] = 0xFE  # format byte -> 0xFE path
    body[8] = 1  # power on
    body[11] = 128  # target temperature -> 128 / 2 - 40 = 24.0
    body[12] = 0
    body[13] = 235  # indoor temperature -> 235 / 10 = 23.5
    body[31] = 0x02  # operational mode COOL -> index 4
    body[34] = fan_speed
    body[41] = 0x06  # vertical louver auto -> swing on
    body[56] = 1  # eco on
    body[60] = 1  # sleep on
    return _build_message(MessageType.query, body)


class TestMideaCCDevice:
    """Test Midea CC Device."""

    device: MideaCCDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea CC Device setup."""
        self.device = MideaCCDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize="",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.mode] == 1
        assert self.device.attributes[DeviceAttributes.target_temperature] == 26.0
        assert self.device.attributes[DeviceAttributes.fan_speed] == 0x80
        assert self.device.attributes[DeviceAttributes.fan_speed_level] is None
        assert self.device.attributes[DeviceAttributes.indoor_temperature] is None
        assert self.device.attributes[DeviceAttributes.aux_heating] is False
        assert self.device.fan_modes is None

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_process_message_legacy_7level(self) -> None:
        """Legacy frame without 3-level flag selects the 7-level fan table."""
        new_status = self.device.process_message(
            _legacy_frame(byte14=0x80),
        )
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == 4
        assert self.device.attributes[DeviceAttributes.target_temperature] == 24.5
        assert self.device.attributes[DeviceAttributes.indoor_temperature] == 25.0
        assert self.device.attributes[DeviceAttributes.fan_speed] == "level_5"
        assert self.device.attributes[DeviceAttributes.temperature_precision] == 1
        assert self.device.attributes[DeviceAttributes.aux_heating] is False
        assert new_status[DeviceAttributes.fan_speed.value] == "level_5"
        assert self.device.fan_modes == list(
            MideaCCDevice._fan_speeds_7level.values(),
        )

    def test_process_message_legacy_3level_and_aux(self) -> None:
        """3-level flag selects the 3-level table; aux heat status 1 sets aux."""
        new_status = self.device.process_message(
            _legacy_frame(fan_speed=0x08, byte13=0x40, byte14=0x20),
        )
        assert self.device.attributes[DeviceAttributes.fan_speed_level] is True
        assert self.device.attributes[DeviceAttributes.fan_speed] == "medium"
        assert self.device.attributes[DeviceAttributes.aux_heat_status] == 1
        assert self.device.attributes[DeviceAttributes.aux_heating] is True
        assert new_status[DeviceAttributes.aux_heating.value] is True
        assert self.device.fan_modes == list(
            MideaCCDevice._fan_speeds_3level.values(),
        )

    def test_process_message_aux_heating_reset(self) -> None:
        """Aux heating flips back to False when heat status clears."""
        self.device.process_message(_legacy_frame(byte14=0x20))
        assert self.device.attributes[DeviceAttributes.aux_heating] is True
        new_status = self.device.process_message(_legacy_frame(byte14=0x00))
        assert self.device.attributes[DeviceAttributes.aux_heating] is False
        assert new_status[DeviceAttributes.aux_heating.value] is False

    def test_process_message_unknown_fan_speed(self) -> None:
        """A fan speed value not in the table maps to None."""
        new_status = self.device.process_message(_legacy_frame(fan_speed=0x03))
        assert self.device.attributes[DeviceAttributes.fan_speed] is None
        assert new_status[DeviceAttributes.fan_speed.value] is None

    def test_process_message_unparsed(self) -> None:
        """A set/X01 frame is not parsed and yields no status."""
        body = bytearray(22)
        body[0] = 0x01
        new_status = self.device.process_message(
            _build_message(MessageType.set, body),
        )
        assert new_status == {}

    def test_process_message_fe_format(self) -> None:
        """0xFE frames switch the device to the VRF fan table and control path."""
        new_status = self.device.process_message(_fe_frame(fan_speed=5))
        assert self.device._is_fe_format is True
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.mode] == 4
        assert self.device.attributes[DeviceAttributes.target_temperature] == 24.0
        assert self.device.attributes[DeviceAttributes.indoor_temperature] == 23.5
        assert self.device.attributes[DeviceAttributes.fan_speed] == "level_5"
        assert self.device.attributes[DeviceAttributes.swing] is True
        assert new_status[DeviceAttributes.fan_speed.value] == "level_5"
        assert self.device.fan_modes == list(MideaCCDevice._fan_speeds_fe.values())

    def test_make_message_set_maps_fan_speed(self) -> None:
        """make_message_set maps the fan speed name back to its raw key."""
        self.device.process_message(_legacy_frame(fan_speed=0x08, byte13=0x40))
        message = self.device.make_message_set()
        assert isinstance(message, MessageSet)
        assert message.fan_speed == 0x08
        assert message.power is True
        assert message.mode == 4
        assert message.target_temperature == 24.5

    def test_make_message_set_unknown_fan_speed_keeps_default(self) -> None:
        """An unresolved fan speed (None) does not crash make_message_set."""
        self.device.process_message(_legacy_frame(fan_speed=0x08, byte13=0x40))
        self.device.process_message(_legacy_frame(fan_speed=0x03, byte13=0x40))
        assert self.device.attributes[DeviceAttributes.fan_speed] is None
        message = self.device.make_message_set()
        assert message.fan_speed == 0x80

    def test_set_attribute_power_without_fan_speeds(self) -> None:
        """Without a known fan table the default raw fan speed is kept."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert isinstance(msg, MessageSet)
            assert msg.power is True
            assert msg.fan_speed == 0x80

    def test_set_attribute_mode_forces_power(self) -> None:
        """Setting the mode also powers the device on."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode.value, 3)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.mode == 3
            assert msg.power is True

    def test_set_attribute_eco_mode_clears_sleep(self) -> None:
        """Enabling eco mode clears sleep mode."""
        self.device._attributes[DeviceAttributes.sleep_mode] = True
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.eco_mode.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.eco_mode is True
            assert msg.sleep_mode is False

    def test_set_attribute_sleep_mode_clears_eco(self) -> None:
        """Enabling sleep mode clears eco mode."""
        self.device._attributes[DeviceAttributes.eco_mode] = True
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.sleep_mode.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.sleep_mode is True
            assert msg.eco_mode is False

    def test_set_attribute_aux_heating_on(self) -> None:
        """Enabling aux heating sends heat status 1."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.aux_heating.value, True)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.aux_heat_status == 1

    def test_set_attribute_aux_heating_off(self) -> None:
        """Disabling aux heating sends heat status 2."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.aux_heating.value, False)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.aux_heat_status == 2

    def test_set_attribute_fan_speed_valid(self) -> None:
        """A known fan speed name is mapped to its raw key."""
        self.device.process_message(_legacy_frame(fan_speed=0x08, byte13=0x40))
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, "high")
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.fan_speed == 0x40

    def test_set_attribute_fan_speed_invalid_keeps_current(self) -> None:
        """An unknown fan speed name still sends the current fan speed."""
        self.device.process_message(_legacy_frame(fan_speed=0x08, byte13=0x40))
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, "Bogus")
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.fan_speed == 0x08

    def test_set_attribute_sensor_not_sent(self) -> None:
        """Sensor attributes never build a set message."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(
                DeviceAttributes.indoor_temperature.value,
                25,
            )
            self.device.set_attribute(DeviceAttributes.fan_speed_level.value, True)
            mock_send.assert_not_called()

    def test_set_target_temperature_with_mode(self) -> None:
        """Setting temperature with a mode powers on and applies the mode."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_target_temperature(22.5, 3)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert isinstance(msg, MessageSet)
            assert msg.target_temperature == 22.5
            assert msg.power is True
            assert msg.mode == 3

    def test_set_target_temperature_without_mode(self) -> None:
        """Setting temperature without a mode keeps the current power state."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_target_temperature(21.0, None)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg.target_temperature == 21.0
            assert msg.power is False

    def test_hvac_modes(self) -> None:
        """Test hvac_modes lists every generic HVAC mode name."""
        assert self.device.hvac_modes == [
            "off",
            "fan_only",
            "dry",
            "heat",
            "cool",
            "auto",
        ]

    def test_fan_mode_before_and_after_speed_table_resolved(self) -> None:
        """Test fan_mode is None until the fan speed table is known."""
        assert self.device.fan_mode is None
        self.device.process_message(_legacy_frame(fan_speed=0x08))
        assert (
            self.device.fan_mode == self.device.attributes[DeviceAttributes.fan_speed]
        )
        assert isinstance(self.device.fan_mode, str)

    def test_set_fan_mode(self) -> None:
        """Test set_fan_mode writes the fan_speed attribute."""
        self.device.process_message(_legacy_frame(fan_speed=0x08))
        fan_modes = self.device.fan_modes
        assert fan_modes is not None
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_fan_mode(fan_modes[0])
            mock_send.assert_called_once()

    def test_swing_mode(self) -> None:
        """Test swing_mode is derived from the swing attribute."""
        self.device._attributes[DeviceAttributes.swing] = False
        assert self.device.swing_mode == "off"
        self.device._attributes[DeviceAttributes.swing] = True
        assert self.device.swing_mode == "on"

    def test_swing_mode_invalid_type_returns_none(self) -> None:
        """Test swing_mode returns None for an unexpected attribute type."""
        self.device._attributes[DeviceAttributes.swing] = None
        assert self.device.swing_mode is None

    def test_swing_modes(self) -> None:
        """Test swing_modes lists off/on."""
        assert self.device.swing_modes == ["off", "on"]

    def test_set_swing_mode(self) -> None:
        """Test set_swing_mode writes the swing attribute."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_swing_mode("on")
            msg = mock_send.call_args[0][0]
            assert msg.swing is True

    def test_temperature_step(self) -> None:
        """Test temperature_step mirrors temperature_precision."""
        self.device._attributes[DeviceAttributes.temperature_precision] = 1
        assert self.device.temperature_step == 1.0

    def test_temperature_step_invalid_type_returns_none(self) -> None:
        """Test temperature_step returns None for an unexpected attribute type."""
        self.device._attributes[DeviceAttributes.temperature_precision] = None
        assert self.device.temperature_step is None


class TestMideaCCDeviceFEControl:
    """Test Midea CC Device 0xFE VRF control path."""

    device: MideaCCDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea CC Device setup in 0xFE mode."""
        self.device = MideaCCDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize="",
        )
        self.device.process_message(_fe_frame(fan_speed=3))

    def test_fe_temperature_value(self) -> None:
        """Target temperatures are encoded as value * 2 + 80."""
        assert self.device._fe_temperature_value(24.0) == 128
        assert self.device._fe_temperature_value(17.5) == 115

    def test_set_target_temperature_with_mode(self) -> None:
        """FE temperature set with mode sends power + mode + temperature."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_target_temperature(24.0, 3)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert isinstance(msg, MessageFEControl)
            assert msg._controls == [
                (CCControlId.POWER, 1),
                (CCControlId.MODE, 0x03),
                (CCControlId.TARGET_TEMPERATURE, 128),
            ]

    def test_set_target_temperature_without_mode(self) -> None:
        """FE temperature set without mode sends only the temperature."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_target_temperature(24.0, None)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg._controls == [(CCControlId.TARGET_TEMPERATURE, 128)]

    def test_set_attribute_power(self) -> None:
        """FE power set sends a single POWER control."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            self.device.set_attribute(DeviceAttributes.power.value, False)
            assert mock_send.call_count == 2
            assert mock_send.call_args_list[0][0][0]._controls == [
                (CCControlId.POWER, 1),
            ]
            assert mock_send.call_args_list[1][0][0]._controls == [
                (CCControlId.POWER, 0),
            ]

    def test_set_attribute_mode(self) -> None:
        """FE mode set sends power on plus the mapped FE mode value."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode.value, 3)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg._controls == [
                (CCControlId.POWER, 1),
                (CCControlId.MODE, 0x03),
            ]

    def test_set_attribute_mode_unknown_defaults_to_cool(self) -> None:
        """Unknown mode indexes fall back to the FE cool mode value."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.mode.value, 9)
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg._controls == [
                (CCControlId.POWER, 1),
                (CCControlId.MODE, 0x02),
            ]

    def test_set_attribute_fan_speed_valid(self) -> None:
        """FE fan speed name maps to the numeric FE speed value."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, "level_3")
            mock_send.assert_called_once()
            msg = mock_send.call_args[0][0]
            assert msg._controls == [(CCControlId.FAN_SPEED, 3)]

    def test_set_attribute_fan_speed_invalid_not_sent(self) -> None:
        """Unknown FE fan speed names do not send anything."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.fan_speed.value, "Bogus")
            mock_send.assert_not_called()

    def test_set_attribute_eco_and_sleep(self) -> None:
        """FE eco and sleep controls carry the boolean value."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.eco_mode.value, True)
            self.device.set_attribute(DeviceAttributes.sleep_mode.value, False)
            assert mock_send.call_count == 2
            assert mock_send.call_args_list[0][0][0]._controls == [
                (CCControlId.ECO, 1),
            ]
            assert mock_send.call_args_list[1][0][0]._controls == [
                (CCControlId.SLEEP, 0),
            ]

    def test_set_attribute_swing(self) -> None:
        """FE swing on sends the auto louver angle, off sends zero."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.swing.value, True)
            self.device.set_attribute(DeviceAttributes.swing.value, False)
            assert mock_send.call_count == 2
            assert mock_send.call_args_list[0][0][0]._controls == [
                (CCControlId.SWING, 0x06),
            ]
            assert mock_send.call_args_list[1][0][0]._controls == [
                (CCControlId.SWING, 0x00),
            ]

    def test_set_attribute_unsupported_not_sent(self) -> None:
        """Attributes without an FE control id are ignored."""
        with patch.object(self.device, "build_send") as mock_send:
            self.device.set_attribute(DeviceAttributes.night_light.value, True)
            mock_send.assert_not_called()
