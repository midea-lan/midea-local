"""Test E6 device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.e6 import DeviceAttributes, MideaE6Device
from midealocal.devices.e6.message import MessageQuery, MessageSet


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

    def test_temperature_step(self) -> None:
        """Test temperature_step property reflects customize."""
        assert self.device.temperature_step == 1.0

    def test_build_query(self) -> None:
        """Test build_query returns a single query message."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_heating_modes(self) -> None:
        """Test heating_modes property returns available modes."""
        assert self.device.heating_modes == [
            "normal",
            "out",
            "home",
            "sleep",
        ]

    def test_preset_modes(self) -> None:
        """Test preset_modes property returns available modes."""
        assert self.device.preset_modes == [
            "normal",
            "out",
            "home",
            "sleep",
        ]

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.main_power, True),
            (DeviceAttributes.heating_power, True),
            (DeviceAttributes.heating_temperature, 50.0),
            (DeviceAttributes.bathing_temperature, 40.0),
            (DeviceAttributes.heating_modes, "normal"),
            (DeviceAttributes.cold_water_single, True),
            (DeviceAttributes.cold_water_dot, True),
        ],
    )
    def test_set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Test set_attribute builds and sends a set message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(attr, value)
            mock_build_send.assert_called_once()
            sent_message = mock_build_send.call_args[0][0]
            assert isinstance(sent_message, MessageSet)
            assert getattr(sent_message, str(attr)) == value

    def test_set_attribute_unknown(self) -> None:
        """Test set_attribute ignores unknown attributes."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute("unknown_attribute", True)
            mock_build_send.assert_not_called()

    def test_set_customize_invalid_json(self) -> None:
        """Test set_customize logs and continues on invalid JSON."""
        device = MideaE6Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="not-valid-json",
        )
        assert device.temperature_step is None
