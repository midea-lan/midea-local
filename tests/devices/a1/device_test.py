"""Test a1 Device"""

import unittest
from unittest.mock import patch
from midealocal.devices.a1 import MideaA1Device, DeviceAttributes
from midealocal.devices.a1.message import MessageQuery, MessageSet


class TestMideaA1Device(unittest.TestCase):
    """Test Midea A1 Device."""

    def setUp(self) -> None:
        """Setup test."""
        self.device = MideaA1Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            protocol=3,
            model="test_model",
            subtype=1,
            customize="test_customize",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        self.assertEqual(self.device.attributes[DeviceAttributes.power], False)
        self.assertEqual(self.device.attributes[DeviceAttributes.prompt_tone], True)
        self.assertEqual(self.device.attributes[DeviceAttributes.fan_speed], "Medium")
        self.assertEqual(self.device.attributes[DeviceAttributes.target_humidity], 35)

    def test_modes(self) -> None:
        """Test modes."""
        self.assertEqual(
            self.device.modes,
            ["Manual", "Continuous", "Auto", "Clothes-Dry", "Shoes-Dry"],
        )

    def test_fan_speeds(self) -> None:
        """Test fan speeds."""
        self.assertEqual(
            self.device.fan_speeds, ["Lowest", "Low", "Medium", "High", "Auto", "Off"]
        )

    def test_water_level_sets(self) -> None:
        """Test water level sets."""
        self.assertEqual(self.device.water_level_sets, ["25", "50", "75", "100"])

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealocal.devices.a1.MessageA1Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.protocol_version = 3
            mock_message.power = True
            mock_message.prompt_tone = False
            mock_message.fan_speed = 40
            mock_message.target_humidity = 40
            mock_message.mode = 0
            mock_message.tank = 60
            mock_message.water_level_set = "50"
            new_status = self.device.process_message(b"")
            self.assertEqual(new_status[DeviceAttributes.power.value], True)
            self.assertEqual(new_status[DeviceAttributes.prompt_tone.value], False)
            self.assertEqual(new_status[DeviceAttributes.fan_speed.value], "Low")
            self.assertEqual(new_status[DeviceAttributes.target_humidity.value], 40)
            self.assertEqual(new_status[DeviceAttributes.tank_full.value], True)

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        self.assertEqual(len(queries), 1)
        self.assertIsInstance(queries[0], MessageQuery)

    def test_make_message_set(self) -> None:
        """Test make message set."""
        message_set = self.device.make_message_set()
        self.assertIsInstance(message_set, MessageSet)
        self.assertEqual(message_set.power, False)
        self.assertEqual(message_set.prompt_tone, True)
        self.assertEqual(message_set.fan_speed, 60)

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.mode, "Auto")
            mock_build_send.assert_called_once()

            self.device.set_attribute(DeviceAttributes.fan_speed, "Medium")
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.water_level_set, "75")
            mock_build_send.assert_called()