"""Test AC Device"""

import unittest
from unittest.mock import patch

from midealocal.devices.ac import DeviceAttributes, MideaACDevice
from midealocal.devices.ac.message import MessageSubProtocolQuery


class TestMideaACDevice(unittest.TestCase):
    """Test Midea AC Device."""

    def setUp(self) -> None:
        """Setup test."""
        self.device = MideaACDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            protocol=1,
            model="test_model",
            subtype=1,
            customize='{"temperature_step": 1, "power_analysis_method": 2}',
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        self.assertEqual(self.device.attributes[DeviceAttributes.prompt_tone], True)
        self.assertEqual(self.device.attributes[DeviceAttributes.power], False)
        self.assertEqual(self.device.attributes[DeviceAttributes.mode], 0)
        self.assertEqual(
            self.device.attributes[DeviceAttributes.target_temperature], 24.0
        )
        self.assertEqual(self.device.attributes[DeviceAttributes.fan_speed], 102)
        self.assertEqual(self.device.attributes[DeviceAttributes.swing_vertical], False)
        self.assertEqual(
            self.device.attributes[DeviceAttributes.swing_horizontal], False
        )
        self.assertEqual(self.device.temperature_step, 1)
        self.assertIsNotNone(self.device.fresh_air_fan_speeds)

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.mode.value, 2)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.target_temperature.value, 26.0)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.prompt_tone.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.screen_display.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(
                DeviceAttributes.screen_display_alternate.value, False
            )
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.fresh_air_power.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.fresh_air_mode.value, "Medium")
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.comfort_mode.value, True)
            mock_build_send.assert_called()

    def test_build_query(self) -> None:
        """Test build query."""
        setattr(self.device, "_used_subprotocol", True)
        queries = self.device.build_query()
        self.assertEqual(len(queries), 3)
        self.assertIsInstance(queries[0], MessageSubProtocolQuery)
        self.assertIsInstance(queries[1], MessageSubProtocolQuery)
        self.assertIsInstance(queries[2], MessageSubProtocolQuery)

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealocal.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = True
            mock_message.prompt_tone = False
            mock_message.power = True
            mock_message.mode = 1
            mock_message.target_temperature = 25.0
            mock_message.fan_speed = 102
            mock_message.swing_vertical = True
            mock_message.swing_horizontal = True
            mock_message.smart_eye = True
            mock_message.dry = True
            mock_message.aux_heating = True
            mock_message.boost_mode = True
            mock_message.sleep_mode = True
            mock_message.frost_protect = True
            mock_message.comfort_mode = True
            mock_message.eco_mode = True
            mock_message.natural_wind = True
            mock_message.temp_fahrenheit = True
            mock_message.screen_display = True
            mock_message.screen_display_alternate = True
            mock_message.full_dust = True
            mock_message.indoor_temperature = None
            mock_message.outdoor_temperature = None
            mock_message.indoor_humidity = None
            mock_message.breezeless = True
            mock_message.total_energy_consumption = None
            mock_message.current_energy_consumption = None
            mock_message.realtime_power = None
            mock_message.fresh_air_power = True
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = 1
            mock_message.fresh_air_2 = 1

            result = self.device.process_message(bytearray())
            self.assertTrue(result[DeviceAttributes.power.value])
            self.assertFalse(result[DeviceAttributes.prompt_tone.value])
            self.assertEqual(result[DeviceAttributes.mode.value], 1)
            self.assertEqual(result[DeviceAttributes.target_temperature.value], 25.0)
            self.assertEqual(result[DeviceAttributes.fan_speed.value], 102)
            self.assertTrue(result[DeviceAttributes.swing_vertical.value])
            self.assertTrue(result[DeviceAttributes.swing_horizontal.value])
            self.assertTrue(result[DeviceAttributes.smart_eye.value])
            self.assertTrue(result[DeviceAttributes.dry.value])
            self.assertTrue(result[DeviceAttributes.aux_heating.value])
            self.assertTrue(result[DeviceAttributes.boost_mode.value])
            self.assertTrue(result[DeviceAttributes.sleep_mode.value])
            self.assertTrue(result[DeviceAttributes.frost_protect.value])
            self.assertTrue(result[DeviceAttributes.comfort_mode.value])
            self.assertTrue(result[DeviceAttributes.eco_mode.value])
            self.assertTrue(result[DeviceAttributes.natural_wind.value])
            self.assertTrue(result[DeviceAttributes.temp_fahrenheit.value])
            self.assertTrue(result[DeviceAttributes.screen_display.value])
            self.assertTrue(result[DeviceAttributes.screen_display_alternate.value])
            self.assertTrue(result[DeviceAttributes.full_dust.value])
            self.assertEqual(result[DeviceAttributes.indoor_temperature.value], None)
            self.assertEqual(result[DeviceAttributes.outdoor_temperature.value], None)
            self.assertEqual(result[DeviceAttributes.indoor_humidity.value], None)
            self.assertTrue(result[DeviceAttributes.breezeless.value])
            self.assertEqual(
                result[DeviceAttributes.total_energy_consumption.value], None
            )
            self.assertEqual(
                result[DeviceAttributes.current_energy_consumption.value], None
            )
            self.assertEqual(result[DeviceAttributes.realtime_power.value], None)
            self.assertTrue(result[DeviceAttributes.fresh_air_power.value])
            self.assertEqual(result[DeviceAttributes.fresh_air_mode.value], "Off")
            self.assertEqual(result[DeviceAttributes.fresh_air_1.value], 1)
            self.assertEqual(result[DeviceAttributes.fresh_air_2.value], 1)

            mock_message.fresh_air_fan_speed = 55
            mock_message.fresh_air_1 = None
            result = self.device.process_message(bytearray())
            self.assertEqual(result[DeviceAttributes.fresh_air_mode.value], "Medium")

            mock_message.fresh_air_power = False
            result = self.device.process_message(bytearray())
            self.assertEqual(result[DeviceAttributes.fresh_air_mode.value], "Off")

    def test_set_target_temperature(self) -> None:
        """Test set target temperature."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_target_temperature(22.5, 1)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            self.assertEqual(message.target_temperature, 22.5)
            self.assertEqual(message.mode, 1)
            self.assertTrue(message.power)
