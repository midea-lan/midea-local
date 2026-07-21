"""Test E6 device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e6 import DeviceAttributes, MideaE6Device


class TestMideaE6Device:
    """Test E6 device."""

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Set up E6 device."""
        self.device = MideaE6Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize='{"temperature_step": 1}',
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.temperature_min] == [30.0, 35.0]
        assert self.device.attributes[DeviceAttributes.temperature_max] == [80.0, 60.0]

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealocal.devices.e6.MessageE6Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.main_power = True
            mock_message.heating_power = False
            mock_message.heating_working = True
            mock_message.bathing_working = False
            mock_message.temperature_min = [25.0, 30.0]
            mock_message.temperature_max = [75.0, 55.0]
            mock_message.heating_temperature = 45.0
            mock_message.bathing_temperature = 40.0
            mock_message.heating_leaving_temperature = 43.0
            mock_message.bathing_leaving_temperature = 38.0
            mock_message.cold_water_single = True
            mock_message.cold_water_dot = False
            mock_message.heating_modes = "home_mode"

            result = self.device.process_message(b"")

            assert result[DeviceAttributes.main_power.value] is True
            assert result[DeviceAttributes.heating_power.value] is False
            assert result[DeviceAttributes.heating_working.value] is True
            assert result[DeviceAttributes.bathing_working.value] is False
            assert result[DeviceAttributes.temperature_min.value] == [25.0, 30.0]
            assert result[DeviceAttributes.temperature_max.value] == [75.0, 55.0]
            assert result[DeviceAttributes.heating_temperature.value] == 45.0
            assert result[DeviceAttributes.bathing_temperature.value] == 40.0
            assert result[DeviceAttributes.heating_leaving_temperature.value] == 43.0
            assert result[DeviceAttributes.bathing_leaving_temperature.value] == 38.0
            assert result[DeviceAttributes.cold_water_single.value] is True
            assert result[DeviceAttributes.cold_water_dot.value] is False
            assert result[DeviceAttributes.heating_modes.value] == "home_mode"
