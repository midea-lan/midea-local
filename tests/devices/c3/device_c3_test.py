"""Test C3 Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.c3 import (
    DeviceAttributes,
    MideaC3Device,
)
from midealocal.devices.c3.message import (
    C3DeviceMode,
    C3SilentLevel,
    MessageQueryBasic,
    MessageQueryDisinfect,
    MessageQueryECO,
    MessageQuerySilence,
)
from tests.base_classes_test import DummyHVACMode


class TestMideaC3Device:
    """Test Midea C3 Device."""

    device: MideaC3Device

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea C3 Device setup."""
        self.device = MideaC3Device(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize='{"temperature_step": 1}',
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.zone1_power] is False
        assert self.device.attributes[DeviceAttributes.zone2_power] is False
        assert self.device.attributes[DeviceAttributes.dhw_power] is False
        assert self.device.attributes[DeviceAttributes.zone1_curve] is False
        assert self.device.attributes[DeviceAttributes.zone2_curve] is False
        assert self.device.attributes[DeviceAttributes.disinfect] is False
        assert self.device.attributes[DeviceAttributes.fast_dhw] is False
        assert self.device.attributes[DeviceAttributes.zone_temp_type] == [False, False]
        assert self.device.attributes[DeviceAttributes.zone1_room_temp_mode] is False
        assert self.device.attributes[DeviceAttributes.zone2_room_temp_mode] is False
        assert self.device.attributes[DeviceAttributes.zone1_water_temp_mode] is False
        assert self.device.attributes[DeviceAttributes.zone2_water_temp_mode] is False
        assert self.device.attributes[DeviceAttributes.silent_mode] is False
        assert (
            self.device.attributes[DeviceAttributes.silent_level]
            == C3SilentLevel.OFF.name.lower()
        )
        assert self.device.attributes[DeviceAttributes.eco_mode] is False
        assert self.device.attributes[DeviceAttributes.tbh] is False
        assert self.device.attributes[DeviceAttributes.mode] == 1
        assert self.device.attributes[DeviceAttributes.mode_auto] == 1
        assert self.device.attributes[DeviceAttributes.zone_target_temp] == [25, 25]
        assert self.device.attributes[DeviceAttributes.dhw_target_temp] == 25
        assert self.device.attributes[DeviceAttributes.room_target_temp] == 30
        assert self.device.attributes[DeviceAttributes.zone_heating_temp_max] == [
            55,
            55,
        ]
        assert self.device.attributes[DeviceAttributes.zone_heating_temp_min] == [
            25,
            25,
        ]
        assert self.device.attributes[DeviceAttributes.zone_cooling_temp_max] == [
            25,
            25,
        ]
        assert self.device.attributes[DeviceAttributes.zone_cooling_temp_min] == [5, 5]
        assert self.device.attributes[DeviceAttributes.room_temp_max] == 60
        assert self.device.attributes[DeviceAttributes.room_temp_min] == 34
        assert self.device.attributes[DeviceAttributes.dhw_temp_max] == 60
        assert self.device.attributes[DeviceAttributes.dhw_temp_min] == 20
        assert self.device.attributes[DeviceAttributes.tank_actual_temperature] is None
        assert self.device.attributes[DeviceAttributes.target_temperature] == [25, 25]
        assert self.device.attributes[DeviceAttributes.temperature_max] == [0, 0]
        assert self.device.attributes[DeviceAttributes.temperature_min] == [0, 0]
        assert self.device.attributes[DeviceAttributes.total_energy_consumption] is None
        assert self.device.attributes[DeviceAttributes.status_heating] is None
        assert self.device.attributes[DeviceAttributes.status_dhw] is None
        assert self.device.attributes[DeviceAttributes.status_tbh] is None
        assert self.device.attributes[DeviceAttributes.status_ibh] is None
        assert self.device.attributes[DeviceAttributes.total_produced_energy] is None
        assert self.device.attributes[DeviceAttributes.outdoor_temperature] is None
        assert self.device.attributes[DeviceAttributes.error_code] == 0
        assert self.device.temperature_step == 1
        assert len(self.device.silent_modes) == 3

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "send_message_v2") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.zone1_power.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.zone1_power.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.eco_mode.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.disinfect.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.silent_mode.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(
                DeviceAttributes.silent_level.value,
                C3SilentLevel.SILENT.name.lower(),
            )

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 5
        assert isinstance(queries[0], MessageQueryBasic)
        assert isinstance(queries[1], MessageQueryDisinfect)
        assert isinstance(queries[2], MessageQuerySilence)
        assert isinstance(queries[3], MessageQueryECO)

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealocal.devices.c3.MessageC3Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.zone1_power = True
            mock_message.zone2_power = False
            mock_message.dhw_power = True
            mock_message.zone1_curve = False
            mock_message.zone2_curve = True
            mock_message.disinfect = False
            mock_message.fast_dhw = True
            mock_message.zone_temp_type = [True, False]
            mock_message.zone1_room_temp_mode = True
            mock_message.zone2_room_temp_mode = False
            mock_message.zone1_water_temp_mode = False
            mock_message.zone2_water_temp_mode = True
            mock_message.mode = 2
            mock_message.mode_auto = C3DeviceMode.COOL
            mock_message.zone_target_temp = [25, 30]
            mock_message.dhw_target_temp = 40
            mock_message.room_target_temp = 22
            mock_message.zone_heating_temp_max = [55, 55]
            mock_message.zone_heating_temp_min = [25, 25]
            mock_message.zone_cooling_temp_max = [25, 25]
            mock_message.zone_cooling_temp_min = [5, 5]
            mock_message.room_temp_max = 60
            mock_message.room_temp_min = 34
            mock_message.dhw_temp_max = 60
            mock_message.dhw_temp_min = 20
            mock_message.tank_actual_temperature = 50
            mock_message.target_temperature = [25, 25]
            mock_message.temperature_max = [0, 0]
            mock_message.temperature_min = [0, 0]
            mock_message.total_energy_consumption = 100
            mock_message.status_heating = 1
            mock_message.status_dhw = 1
            mock_message.status_tbh = 0
            mock_message.status_ibh = 0
            mock_message.total_produced_energy = 200
            mock_message.outdoor_temperature = 18
            mock_message.error_code = 0

            result = self.device.process_message(b"")

            assert result[DeviceAttributes.zone1_power.value] is True
            assert result[DeviceAttributes.zone2_power.value] is False
            assert result[DeviceAttributes.dhw_power.value] is True
            assert result[DeviceAttributes.zone1_curve.value] is False
            assert result[DeviceAttributes.zone2_curve.value] is True
            assert result[DeviceAttributes.disinfect.value] is False
            assert result[DeviceAttributes.fast_dhw.value] is True
            assert result[DeviceAttributes.zone_temp_type.value] == [True, False]
            assert result[DeviceAttributes.zone1_room_temp_mode.value] is False
            assert result[DeviceAttributes.zone2_room_temp_mode.value] is False
            assert result[DeviceAttributes.zone1_water_temp_mode.value] is True
            assert result[DeviceAttributes.zone2_water_temp_mode.value] is False
            assert result[DeviceAttributes.mode.value] == 2
            assert result[DeviceAttributes.mode_auto.value] == 2
            assert result[DeviceAttributes.zone_target_temp.value] == [25, 30]
            assert result[DeviceAttributes.dhw_target_temp.value] == 40
            assert result[DeviceAttributes.room_target_temp.value] == 22
            assert result[DeviceAttributes.zone_heating_temp_max.value] == [55, 55]
            assert result[DeviceAttributes.zone_heating_temp_min.value] == [25, 25]
            assert result[DeviceAttributes.zone_cooling_temp_max.value] == [25, 25]
            assert result[DeviceAttributes.zone_cooling_temp_min.value] == [5, 5]
            assert result[DeviceAttributes.room_temp_max.value] == 60
            assert result[DeviceAttributes.room_temp_min.value] == 34
            assert result[DeviceAttributes.dhw_temp_max.value] == 60
            assert result[DeviceAttributes.dhw_temp_min.value] == 20
            assert result[DeviceAttributes.tank_actual_temperature.value] == 50
            assert result[DeviceAttributes.total_energy_consumption.value] == 100
            assert result[DeviceAttributes.status_heating.value] == 1
            assert result[DeviceAttributes.status_dhw.value] == 1
            assert result[DeviceAttributes.status_tbh.value] == 0
            assert result[DeviceAttributes.status_ibh.value] == 0
            assert result[DeviceAttributes.total_produced_energy.value] == 200
            assert result[DeviceAttributes.outdoor_temperature.value] == 18
            assert result[DeviceAttributes.error_code.value] == 0

            mock_message.zone2_power = True
            mock_message.zone_temp_type = [False, True]
            mock_message.mode = C3DeviceMode.HEAT
            mock_message.mode_auto = C3DeviceMode.HEAT

            result = self.device.process_message(b"")

            mock_message.zone1_power = False
            mock_message.zone2_power = False

            result = self.device.process_message(b"")

            assert result[DeviceAttributes.mode.value] == 3

    def test_set_target_temperature(self) -> None:
        """Test set target temperature."""
        with pytest.raises(ValueError):  # noqa: PT011
            self.device.set_raw_target_temperature(22.5, 1)
        with patch("midealocal.devices.c3.MessageC3Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.zone_temp_type = [True, False]
            self.device.process_message(b"")

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_raw_target_temperature(22.5, 1, 0)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.mode == 1
            assert message.zone1_power

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_raw_target_temperature(23, 1, 1)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.room_target_temp == 23
            assert message.mode == 1
            assert message.zone2_power

    def test_set_mode(self) -> None:
        """Test set mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device._set_mode(0, C3DeviceMode.COOL)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.zone1_power is True
            assert message.mode == C3DeviceMode.COOL

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device._set_mode(1, C3DeviceMode.HEAT)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.zone2_power is True
            assert message.mode == C3DeviceMode.HEAT

    def test_invalid_customize_format(self) -> None:
        """Test invalid customize format."""
        self.device.set_customize("{")
        self.device.set_customize('{"temperature_step":"10"}')

    def test_hvac_modes(self) -> None:
        """Test hvac_modes lists every generic HVAC mode name."""
        assert self.device.raw_hvac_modes == ["off", "auto", "cool", "heat"]

    def test_hvac_mode_requires_zone(self) -> None:
        """Test hvac_mode raises when zone isn't set."""
        with pytest.raises(ValueError, match="`zone` must be set"):
            self.device.raw_hvac_mode()

    @pytest.mark.parametrize(
        ("zone", "power_attr"),
        [(0, DeviceAttributes.zone1_power), (1, DeviceAttributes.zone2_power)],
    )
    def test_hvac_mode_per_zone_power(
        self,
        zone: int,
        power_attr: DeviceAttributes,
    ) -> None:
        """Test hvac_mode reads the zone-specific power attribute."""
        self.device._attributes[power_attr] = False
        assert self.device.raw_hvac_mode(zone) == "off"

        self.device._attributes[power_attr] = True
        self.device._attributes[DeviceAttributes.mode] = C3DeviceMode.HEAT
        assert self.device.raw_hvac_mode(zone) == "heat"

    def test_set_hvac_mode_unsupported(self) -> None:
        """Test unsupported MideaHVACMode."""
        with pytest.raises(ValueError, match="Unsupported hvac mode"):
            self.device.set_hvac_mode(DummyHVACMode.INVALID, 0)

    def test_hvac_mode_invalid_type_returns_none(self) -> None:
        """Test hvac_mode returns None for an unexpected attribute type."""
        self.device._attributes[DeviceAttributes.zone1_power] = "not_a_bool"
        assert self.device.raw_hvac_mode(0) is None

    def test_hvac_mode_invalid_mode_index_returns_none(self) -> None:
        """Test hvac_mode returns None for a mode index out of range."""
        self.device._attributes[DeviceAttributes.zone1_power] = True
        self.device._attributes[DeviceAttributes.mode] = 999
        assert self.device.raw_hvac_mode(0) is None

    def test_set_hvac_mode_requires_zone(self) -> None:
        """Test set_hvac_mode raises when zone isn't set."""
        with pytest.raises(ValueError, match="`zone` must be set"):
            self.device.set_raw_hvac_mode("heat")

    def test_set_hvac_mode_off_powers_off_the_zone(self) -> None:
        """Test set_hvac_mode with off powers off only the requested zone."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_raw_hvac_mode("off", 1)
            message = mock_build_send.call_args[0][0]
            assert message.zone2_power is False

    def test_set_hvac_mode_sets_mode_via_set_mode(self) -> None:
        """Test set_hvac_mode delegates to set_mode with the protocol index."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_raw_hvac_mode("heat", 0)
            message = mock_build_send.call_args[0][0]
            assert message.zone1_power is True
            assert message.mode == C3DeviceMode.HEAT

    def test_set_hvac_mode_unsupported_value_raises(self) -> None:
        """Test set_hvac_mode raises for a mode not in hvac_modes."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            pytest.raises(ValueError, match="Unsupported hvac mode"),
        ):
            self.device.set_raw_hvac_mode("not_a_real_mode", 0)
        mock_build_send.assert_not_called()
