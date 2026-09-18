"""Test C3 Device."""

from unittest.mock import patch

import pytest

from midealan.const import ProtocolVersion
from midealan.devices.c3 import (
    DeviceAttributes,
    MideaC3Device,
)
from midealan.devices.c3.message import (
    C3DeviceMode,
    C3SilentLevel,
    MessageQueryBasic,
    MessageQueryDisinfect,
    MessageQueryECO,
    MessageQuerySilence,
)


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
            == C3SilentLevel.OFF.name
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
                C3SilentLevel.SILENT.name,
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
        with patch("midealan.devices.c3.MessageC3Response") as mock_message_response:
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

            assert result[DeviceAttributes.zone1_room_temp_mode.value] is True
            assert result[DeviceAttributes.zone2_room_temp_mode.value] is False
            assert result[DeviceAttributes.zone1_water_temp_mode.value] is False
            assert result[DeviceAttributes.zone2_water_temp_mode.value] is True

            mock_message.zone1_power = False
            mock_message.zone2_power = False

            result = self.device.process_message(b"")

            assert result[DeviceAttributes.mode.value] == 3

    def test_process_message_without_zone_temp_type(self) -> None:
        """Test process message without zone temperature metadata."""

        class FakeMessage:
            zone1_power = True
            zone2_power = False
            dhw_power = True

        with patch("midealan.devices.c3.MessageC3Response") as mock_message_response:
            mock_message_response.return_value = FakeMessage()

            result = self.device.process_message(b"")

        assert result[DeviceAttributes.zone1_power.value] is True
        assert DeviceAttributes.zone_temp_type.value not in result

    def test_process_message_without_any_known_attributes(self) -> None:
        """Test process message when no known attributes are present."""

        class FakeMessage:
            pass

        with patch("midealan.devices.c3.MessageC3Response") as mock_message_response:
            mock_message_response.return_value = FakeMessage()
            result = self.device.process_message(b"")

        assert result == {}

    def test_set_target_temperature(self) -> None:
        """Test set target temperature."""
        with pytest.raises(ValueError):  # noqa: PT011
            self.device.set_target_temperature(22.5, 1)
        with patch("midealan.devices.c3.MessageC3Response") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.zone_temp_type = [True, False]
            self.device.process_message(b"")

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_target_temperature(22.5, 1, 0)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.mode == 1
            assert message.zone1_power

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_target_temperature(23, 1, 1)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.room_target_temp == 23
            assert message.mode == 1
            assert message.zone2_power

    def test_set_mode(self) -> None:
        """Test set mode."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_mode(0, C3DeviceMode.COOL)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.zone1_power is True
            assert message.mode == C3DeviceMode.COOL

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_mode(1, C3DeviceMode.HEAT)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.zone2_power is True
            assert message.mode == C3DeviceMode.HEAT

    def test_set_mode_none_target_uses_existing_zone_state(self) -> None:
        """Test set target temperature without mode keeps power untouched."""
        self.device._attributes[DeviceAttributes.mode] = C3DeviceMode.HEAT
        self.device._attributes[DeviceAttributes.zone2_power] = True
        existing_zone2_power = self.device._attributes[DeviceAttributes.zone2_power]
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_target_temperature(23, None, 1)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.room_target_temp == 23
            assert message.mode == C3DeviceMode.HEAT
            assert message.zone2_power == existing_zone2_power

    def test_set_attribute_unknown_value_is_ignored(self) -> None:
        """Unknown attributes do not build a message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute("unknown_attribute", True)
        mock_build_send.assert_not_called()

    def test_set_silent_level_ignores_non_string_value(self) -> None:
        """Silent level updates ignore non-string inputs."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.silent_level.value, True)
        mock_build_send.assert_not_called()

    def test_set_customize_without_temperature_step(self) -> None:
        """Customize JSON without temperature_step still updates defaults."""
        with patch.object(self.device, "update_all") as mock_update_all:
            self.device.set_customize('{"other": 1}')
        mock_update_all.assert_called_once_with(
            {"temperature_step": self.device._default_temperature_step},
        )
        assert self.device.temperature_step == self.device._default_temperature_step

    def test_set_customize_empty_string_keeps_default(self) -> None:
        """Empty customize input resets to default without updating state."""
        with patch.object(self.device, "update_all") as mock_update_all:
            self.device.set_customize("")
        mock_update_all.assert_not_called()
        assert self.device.temperature_step == self.device._default_temperature_step

    def test_invalid_customize_format(self) -> None:
        """Test invalid customize format."""
        self.device.set_customize("{")
        self.device.set_customize('{"temperature_step":"10"}')

    def test_process_message_unit_para_exposes_odu_runtime(self) -> None:
        """Test X10 outdoor-unit runtime values reach the device attributes."""
        # Real-device X10 (UNITPARA) frame: compressor 0x39 = 57 Hz, mode
        # 0x02 = cooling, outdoor fan 0x40 = 640 RPM.
        header = bytearray(
            [0xAA, 0x00, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x03],
        )
        body = bytearray(88)  # body type + 86 data bytes + CRC
        body[0] = 0x10
        body[1:5] = b"\x39\x02\x40\x02"

        new_status = self.device.process_message(bytes(header + body))

        assert new_status[DeviceAttributes.comp_run_freq.value] == 57
        assert new_status[DeviceAttributes.unit_mode_run.value] == C3DeviceMode.COOL
        assert new_status[DeviceAttributes.fan_speed.value] == 640
        assert self.device.attributes[DeviceAttributes.comp_run_freq] == 57
        assert self.device.attributes[DeviceAttributes.unit_mode_run] == 2
        assert self.device.attributes[DeviceAttributes.fan_speed] == 640

    def test_process_message_unit_para_exposes_odu_telemetry(self) -> None:
        """Test the X10 telemetry values reach the device attributes.

        Real capture from a Hyundai HYHC-V30W/D2RN8 (OEM-equivalent Midea
        MHC-V30W/D2RN8, protocol 3, module 171H120F). The unit serial in the
        tail of the frame has been replaced with zeroes; no parsed field is
        affected.
        """
        header = bytearray(
            [0xAA, 0x00, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x03],
        )
        body = bytes.fromhex(
            "1021023f0205002426500d0b7f070000000300e200881e0100000000040081482048"
            "0b190a0919197f7f64042400640f03220c3536ffff00000000000000000000006300"
            "002fa000000000000008c90000000000e600000000000000000015172d2d2d2d2d2d"
            "2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d"
            "2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d30303030303030303030"
            "303030303030303030303030303030303030303030300000000000000000",
        )

        new_status = self.device.process_message(bytes(header + body + bytes(1)))

        expected = {
            "comp_run_freq": 33,
            "unit_mode_run": 2,
            "fan_speed": 630,
            "fg_capacity_need": 5,
            "temp_t3": 36,
            "temp_tp": 80,
            "temp_tw_in": 13,
            "temp_tw_out": 11,
            "odu_comp_current": 3,
            "odu_voltage": 226,
            "exv_current": 136,
            "temp_t1": 11,
            "temp_t2": 10,
            "temp_t2b": 9,
            "pressure_high": 1060,
            "pressure_low": 100,
            "temp_th": 15,
            "odu_target_fre": 34,
            "temp_tf": 54,
        }
        for name, value in expected.items():
            assert new_status[name] == value, name
            assert self.device.attributes[DeviceAttributes[name]] == value, name
