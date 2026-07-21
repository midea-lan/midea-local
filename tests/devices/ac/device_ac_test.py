"""Test AC Device."""

from types import SimpleNamespace
from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ac import DeviceAttributes, MideaACDevice
from midealocal.devices.ac.message import (
    MessageCapabilitiesAdditionalQuery,
    MessageCapabilitiesQuery,
    MessageGroupOneQuery,
    MessageGroupZeroQuery,
    MessageHumidityQuery,
    MessageNewProtocolQuery,
    MessagePowerQuery,
    MessageQuery,
    MessageSubProtocolFreshAirSet,
    MessageSubProtocolQuery,
    MessageSubProtocolQuery10,
    MessageSubProtocolQuery11,
    MessageSubProtocolQuery30,
    PowerFormats,
)
from midealocal.message import MessageBase


class TestMideaACDevice:
    """Test Midea AC Device."""

    device: MideaACDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea AC Device setup."""
        self.device = MideaACDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize='{"temperature_step": 1, "power_analysis_method": 2}',
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.prompt_tone]
        assert not self.device.attributes[DeviceAttributes.power]
        assert self.device.attributes[DeviceAttributes.mode] == 0
        assert self.device.attributes[DeviceAttributes.target_temperature] == 24.0
        assert self.device.attributes[DeviceAttributes.fan_speed] == 102
        assert not self.device.attributes[DeviceAttributes.swing_vertical]
        assert not self.device.attributes[DeviceAttributes.swing_horizontal]
        assert not self.device.attributes[DeviceAttributes.power_saving]
        assert not self.device.attributes[DeviceAttributes.out_silent]
        assert self.device.temperature_step == 1
        assert self.device.fresh_air_fan_speeds is not None
        assert DeviceAttributes.compressor_frequency not in self.device.attributes
        assert not self.device.fresh_air_exhaust_fan_speeds

    @staticmethod
    def _make_device(model: str, subtype: int) -> MideaACDevice:
        """Create a model-specific AC device."""
        return MideaACDevice(
            name="Model Device",
            device_id=2,
            ip_address="192.168.1.2",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model=model,
            subtype=subtype,
            customize="",
        )

    @staticmethod
    def _response(body: bytearray) -> bytes:
        """Wrap an AC response body in a complete query frame."""
        header = bytearray([0xAA, 0, 0xAC, 0, 0, 0, 0, 0, 1, 3])
        header[1] = len(header) + len(body)
        frame = header + body
        frame.append(MessageBase.checksum(frame[1:]))
        return bytes(frame)

    def test_customize_accepts_bcd_energy_binary_power_format(self) -> None:
        """Test customize can select BCD energy with binary realtime power."""
        device = MideaACDevice(
            name="Custom Power Format Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model="test_model",
            subtype=1,
            customize='{"power_analysis_method": 101}',
        )

        assert device._power_analysis_method == PowerFormats.BCD_ENERGY_BINARY_POWER

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with (
            patch.object(self.device, "send_message_v2") as mock_build_send,
            patch(
                "midealocal.devices.ac.MessageACResponse",
            ) as mock_message_response,
        ):
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.power.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.mode.value, 2)
            mock_build_send.assert_called()

            self.device.set_target_temperature(26, 2)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.prompt_tone.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.screen_display.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.breezeless.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.indirect_wind.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(
                DeviceAttributes.screen_display_alternate.value,
                False,
            )
            mock_build_send.assert_called()

            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = True
            mock_message.timer = 30
            mock_message.fresh_air_power = False
            mock_message.fresh_air_1 = 1

            self.device.process_message(b"")

            self.device.set_attribute(DeviceAttributes.fresh_air_power.value, True)
            mock_build_send.assert_called()

            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = 1
            self.device.process_message(b"")

            self.device.set_attribute(DeviceAttributes.fresh_air_mode.value, "Medium")
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.fresh_air_fan_speed.value, 50)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.comfort_mode.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.power_saving.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.fresh_air_mode.value, False)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.out_silent.value, True)
            mock_build_send.assert_called()

            self.device.set_attribute(DeviceAttributes.out_silent.value, False)
            mock_build_send.assert_called()

    def test_build_query(self) -> None:
        """Test build query."""
        self.device._used_subprotocol = True
        queries = self.device.build_query()
        assert len(queries) == 3
        assert isinstance(queries[0], MessageSubProtocolQuery)
        assert isinstance(queries[1], MessageSubProtocolQuery)
        assert isinstance(queries[2], MessageSubProtocolQuery)

        self.device._used_subprotocol = False
        queries = self.device.build_query()
        assert len(queries) == 10
        assert isinstance(queries[0], MessageQuery)
        assert isinstance(queries[1], MessageNewProtocolQuery)
        assert isinstance(queries[2], MessagePowerQuery)
        assert isinstance(queries[3], MessageHumidityQuery)
        assert isinstance(queries[4], MessageGroupZeroQuery)
        assert isinstance(queries[5], MessageGroupOneQuery)
        assert isinstance(queries[6], MessageGroupTwoQuery)
        assert isinstance(queries[7], MessageGroupSevenQuery)
        assert isinstance(queries[8], MessageCapabilitiesQuery)
        assert isinstance(queries[9], MessageCapabilitiesAdditionalQuery)

    def test_bb_model_builds_distinct_queries_and_attributes(self) -> None:
        """Test verified BB model starts with independent BB queries."""
        device = self._make_device("23096633", 1)

        queries = device.build_query()

        assert [type(query) for query in queries] == [
            MessageSubProtocolQuery10,
            MessageSubProtocolQuery11,
            MessageSubProtocolQuery30,
        ]
        assert DeviceAttributes.compressor_frequency in device.attributes
        assert DeviceAttributes.compressor_target_frequency in device.attributes
        assert DeviceAttributes.fresh_air_exhaust_power in device.attributes
        assert device.fresh_air_fan_speeds == [
            "off",
            "low",
            "medium",
            "high",
            "full",
        ]
        assert device.fresh_air_exhaust_fan_speeds == [
            "off",
            "silent",
            "high",
            "full",
        ]

    @pytest.mark.parametrize("model", ["22390001", "22390003"])
    def test_c1_diagnostics_model_adds_group_query(self, model: str) -> None:
        """Test verified multi-split models query C1 group 0x41."""
        device = self._make_device(model, 8)

        queries = device.build_query()

        assert isinstance(queries[-1], MessageGroupOneQuery)
        assert DeviceAttributes.compressor_frequency in device.attributes
        assert DeviceAttributes.compressor_target_frequency in device.attributes
        assert DeviceAttributes.compressor_current in device.attributes
        assert DeviceAttributes.outdoor_unit_total_current in device.attributes
        assert DeviceAttributes.outdoor_unit_voltage in device.attributes

    @pytest.mark.parametrize(
        ("model", "subtype"),
        [("unknown", 1), ("23096633", 8), ("22390001", 1)],
    )
    def test_model_attribute_gating(self, model: str, subtype: int) -> None:
        """Test diagnostics and commands require an exact model/subtype pair."""
        device = self._make_device(model, subtype)

        assert DeviceAttributes.compressor_frequency not in device.attributes
        assert DeviceAttributes.fresh_air_exhaust_power not in device.attributes
        queries = device.build_query()
        assert isinstance(queries[0], MessageQuery)
        assert not any(
            isinstance(
                query,
                (
                    MessageGroupOneQuery,
                    MessageSubProtocolQuery10,
                    MessageSubProtocolQuery11,
                    MessageSubProtocolQuery30,
                ),
            )
            for query in queries
        )
        with patch.object(device, "build_send") as build_send:
            device.set_attribute(
                DeviceAttributes.fresh_air_exhaust_power,
                True,
            )
            build_send.assert_not_called()

    def test_actual_frequency_only_model_gating(self) -> None:
        """Test the naturally detected BB model exposes only actual frequency."""
        actual_only = self._make_device("23096725", 1)

        assert DeviceAttributes.compressor_frequency in actual_only.attributes
        assert DeviceAttributes.power_factor in actual_only.attributes
        assert (
            DeviceAttributes.compressor_target_frequency not in actual_only.attributes
        )

    def test_process_bb_airflow_and_frequency(self) -> None:
        """Test verified BB model publishes airflow and compressor frequency."""
        device = self._make_device("23096633", 1)
        basic_body = bytearray(56)
        basic_body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x11])
        basic_body[51] = 0x01
        basic_body[52] = 60
        basic_body[53] = 100
        outdoor_body = bytearray(24)
        outdoor_body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x30])
        outdoor_body[16] = 49
        outdoor_body[17] = 47

        airflow = device.process_message(self._response(basic_body))
        frequency = device.process_message(self._response(outdoor_body))

        assert airflow[DeviceAttributes.fresh_air_power] is True
        assert airflow[DeviceAttributes.fresh_air_fan_speed] == 60
        assert airflow[DeviceAttributes.fresh_air_mode] == "medium"
        assert airflow[DeviceAttributes.fresh_air_exhaust_power] is False
        assert airflow[DeviceAttributes.fresh_air_exhaust_speed] == 100
        assert airflow[DeviceAttributes.fresh_air_exhaust_mode] == "off"
        assert frequency[DeviceAttributes.compressor_frequency] == 47
        assert frequency[DeviceAttributes.compressor_target_frequency] == 49

    def test_process_bb_power_factor(self) -> None:
        """Test the verified BB model publishes its reported power factor."""
        device = self._make_device("23096725", 1)
        outdoor_body = bytearray(40)
        outdoor_body[:6] = bytearray([0xBB, 0, 0, 0, 0, 0x30])
        outdoor_body[17] = 47
        outdoor_body[38] = 93

        status = device.process_message(self._response(outdoor_body))

        assert status[DeviceAttributes.compressor_frequency] == 47
        assert status[DeviceAttributes.power_factor] == 93

    def test_process_c1_frequency(self) -> None:
        """Test verified C1 model publishes compressor frequency."""
        device = self._make_device("22390001", 8)
        body = bytearray([0xC1, 0, 0, 0x41, 47, 49, 3, 4, 229, 0])

        status = device.process_message(self._response(body))

        assert status[DeviceAttributes.compressor_frequency] == 47
        assert status[DeviceAttributes.compressor_target_frequency] == 49
        assert status[DeviceAttributes.compressor_current] == 3
        assert status[DeviceAttributes.outdoor_unit_total_current] == 4
        assert status[DeviceAttributes.outdoor_unit_voltage] == 229

    def test_bb_fresh_air_set_attribute(self) -> None:
        """Test BB model sends intake and exhaust single-control commands."""
        device = self._make_device("23096633", 1)
        with patch.object(device, "build_send") as build_send:
            device.set_attribute(DeviceAttributes.fresh_air_mode, "medium")
            intake = build_send.call_args.args[0]
            assert isinstance(intake, MessageSubProtocolFreshAirSet)
            assert intake.power is True
            assert intake.speed == 60
            assert intake.exhaust is False

            device.set_attribute(DeviceAttributes.fresh_air_exhaust_mode, "high")
            exhaust = build_send.call_args.args[0]
            assert isinstance(exhaust, MessageSubProtocolFreshAirSet)
            assert exhaust.power is True
            assert exhaust.speed == 80
            assert exhaust.exhaust is True

            device.set_attribute(DeviceAttributes.fresh_air_exhaust_power, False)
            exhaust_off = build_send.call_args.args[0]
            assert exhaust_off.power is False
            assert exhaust_off.exhaust is True

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealocal.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
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
            mock_message.power_saving = True
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
            mock_message.out_silent = True

            result = self.device.process_message(b"")
            assert result[DeviceAttributes.power.value]
            assert not result[DeviceAttributes.prompt_tone.value]
            assert result[DeviceAttributes.mode.value] == 1
            assert result[DeviceAttributes.target_temperature.value] == 25.0
            assert result[DeviceAttributes.fan_speed.value] == 102
            assert result[DeviceAttributes.swing_vertical.value]
            assert result[DeviceAttributes.swing_horizontal.value]
            assert result[DeviceAttributes.smart_eye.value]
            assert result[DeviceAttributes.dry.value]
            assert result[DeviceAttributes.aux_heating.value]
            assert result[DeviceAttributes.boost_mode.value]
            assert result[DeviceAttributes.power_saving.value]
            assert result[DeviceAttributes.sleep_mode.value]
            assert result[DeviceAttributes.frost_protect.value]
            assert result[DeviceAttributes.comfort_mode.value]
            assert result[DeviceAttributes.eco_mode.value]
            assert result[DeviceAttributes.natural_wind.value]
            assert result[DeviceAttributes.temp_fahrenheit.value]
            assert result[DeviceAttributes.screen_display.value]
            assert result[DeviceAttributes.screen_display_alternate.value]
            assert result[DeviceAttributes.full_dust.value]
            assert result[DeviceAttributes.indoor_temperature.value] is None
            assert result[DeviceAttributes.outdoor_temperature.value] is None
            assert result[DeviceAttributes.indoor_humidity.value] is None
            assert result[DeviceAttributes.breezeless.value]
            assert result[DeviceAttributes.total_energy_consumption.value] is None
            assert result[DeviceAttributes.current_energy_consumption.value] is None
            assert result[DeviceAttributes.realtime_power.value] is None
            assert result[DeviceAttributes.fresh_air_power.value]
            assert result[DeviceAttributes.fresh_air_mode.value] == "off"
            assert result[DeviceAttributes.fresh_air_1.value] == 1
            assert result[DeviceAttributes.fresh_air_2.value] == 1
            assert result[DeviceAttributes.out_silent.value]

            mock_message.fresh_air_fan_speed = 55
            mock_message.fresh_air_1 = None
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.fresh_air_mode.value] == "low"

            mock_message.fresh_air_power = False
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.fresh_air_mode.value] == "off"

            mock_message.power = False
            result = self.device.process_message(b"")
            assert not result[DeviceAttributes.screen_display.value]
            assert not self.device.attributes[DeviceAttributes.screen_display]

    def test_process_message_group_data(self) -> None:
        """Test that group 1/2/7 data is stored in the device attributes."""
        with patch("midealocal.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.power = True
            mock_message.fresh_air_power = False
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = None
            mock_message.swing_vertical = False
            # group 1
            mock_message.compressor_frequency = 28
            mock_message.target_compressor_frequency = 25
            mock_message.compressor_current = 1
            mock_message.compressor_voltage = 232
            mock_message.indoor_coil_temperature = 20.5
            mock_message.evaporator_temperature = 4.0
            mock_message.condenser_temperature = 26.0
            mock_message.outdoor_ambient_temperature = 19.0
            mock_message.discharge_pipe_temperature = 36
            # group 2
            mock_message.indoor_fan_speed = 424
            mock_message.target_indoor_fan_speed = 416
            mock_message.water_pump_running = False
            # group 7
            mock_message.compressor_power = 269

            result = self.device.process_message(b"")

            assert result[DeviceAttributes.compressor_frequency.value] == 28
            assert result[DeviceAttributes.target_compressor_frequency.value] == 25
            assert result[DeviceAttributes.compressor_current.value] == 1
            assert result[DeviceAttributes.compressor_voltage.value] == 232
            assert result[DeviceAttributes.indoor_coil_temperature.value] == 20.5
            assert result[DeviceAttributes.evaporator_temperature.value] == 4.0
            assert result[DeviceAttributes.condenser_temperature.value] == 26.0
            assert result[DeviceAttributes.outdoor_ambient_temperature.value] == 19.0
            assert result[DeviceAttributes.discharge_pipe_temperature.value] == 36
            assert result[DeviceAttributes.indoor_fan_speed.value] == 424
            assert result[DeviceAttributes.target_indoor_fan_speed.value] == 416
            assert result[DeviceAttributes.water_pump_running.value] is False
            assert result[DeviceAttributes.compressor_power.value] == 269

    def test_set_attribute_group_data_is_read_only(self) -> None:
        """Test that group data attributes never send a set message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            for attr in [
                DeviceAttributes.compressor_frequency,
                DeviceAttributes.target_compressor_frequency,
                DeviceAttributes.compressor_current,
                DeviceAttributes.compressor_voltage,
                DeviceAttributes.indoor_coil_temperature,
                DeviceAttributes.evaporator_temperature,
                DeviceAttributes.condenser_temperature,
                DeviceAttributes.outdoor_ambient_temperature,
                DeviceAttributes.discharge_pipe_temperature,
                DeviceAttributes.indoor_fan_speed,
                DeviceAttributes.target_indoor_fan_speed,
                DeviceAttributes.water_pump_running,
                DeviceAttributes.compressor_power,
            ]:
                self.device.set_attribute(attr.value, 1)
            mock_build_send.assert_not_called()

    def test_set_target_temperature(self) -> None:
        """Test set target temperature."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_target_temperature(22.5, 1)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert message.target_temperature == 22.5
            assert message.mode == 1
            assert message.power
            self.device._used_subprotocol = True
            self.device.set_target_temperature(22.5, 1)

    def test_process_message_ignores_stale_c0_temperatures_after_new_protocol(
        self,
    ) -> None:
        """After 0x7e temperatures are seen, stale C0 temperatures are ignored."""
        new_protocol_msg = SimpleNamespace(
            body_type=ListTypes.B5,
            has_subtype8_temperature=True,
            power=True,
            target_temperature=27.0,
            indoor_temperature=28.8,
            outdoor_temperature=None,
        )
        stale_c0_msg = SimpleNamespace(
            body_type=ListTypes.C0,
            power=True,
            target_temperature=16.0,
            indoor_temperature=4.2,
            outdoor_temperature=None,
        )

        with patch(
            "midealocal.devices.ac.MessageACResponse",
            side_effect=[new_protocol_msg, stale_c0_msg],
        ):
            first = self.device.process_message(b"")
            assert first[DeviceAttributes.target_temperature.value] == 27.0
            assert first[DeviceAttributes.indoor_temperature.value] == 28.8

            second = self.device.process_message(b"")
            assert DeviceAttributes.target_temperature.value not in second
            assert DeviceAttributes.indoor_temperature.value not in second
            assert self.device.attributes[DeviceAttributes.target_temperature] == 27.0
            assert self.device.attributes[DeviceAttributes.indoor_temperature] == 28.8

    def test_power_saving_control(self) -> None:
        """Test power saving control and preset exclusivity."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power_saving, True)
            message = mock_build_send.call_args[0][0]
            assert message.power_saving
            assert not message.boost_mode
            assert not message.sleep_mode
            assert not message.eco_mode
            assert not message.comfort_mode
            assert not message.frost_protect

            self.device._attributes[DeviceAttributes.power_saving] = True
            self.device.set_target_temperature(22.5, None)
            message = mock_build_send.call_args[0][0]
            assert message.power_saving

            self.device.set_attribute(DeviceAttributes.boost_mode, True)
            message = mock_build_send.call_args[0][0]
            assert message.boost_mode
            assert not message.power_saving

    def test_power_saving_unsupported_for_subprotocol(self) -> None:
        """Test power saving is not sent with the unsupported subprotocol."""
        self.device._used_subprotocol = True
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power_saving, True)
            mock_build_send.assert_not_called()

    def test_set_swing(self) -> None:
        """Test set swing."""
        with patch.object(self.device, "send_message_v2") as mock_build_send:
            self.device.set_swing(True, False)
            mock_build_send.assert_called()

    def test_self_clean_syncs_from_self_clean_active(self) -> None:
        """Test that self_clean attribute tracks self_clean_active status reports."""
        with patch("midealocal.devices.ac.MessageACResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.used_subprotocol = False
            mock_message.power = False
            mock_message.fresh_air_power = False
            mock_message.fresh_air_fan_speed = 0
            mock_message.fresh_air_1 = None
            mock_message.fresh_air_2 = None
            mock_message.swing_vertical = False
            mock_message.indoor_temperature = None
            mock_message.outdoor_temperature = None
            mock_message.indoor_humidity = None
            mock_message.total_energy_consumption = None
            mock_message.current_energy_consumption = None
            mock_message.realtime_power = None

            mock_message.self_clean_active = True
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.self_clean.value] is True
            assert self.device.attributes[DeviceAttributes.self_clean] is True

            mock_message.self_clean_active = False
            result = self.device.process_message(b"")
            assert result[DeviceAttributes.self_clean.value] is False
            assert self.device.attributes[DeviceAttributes.self_clean] is False

    def test_invalid_customize_format(self) -> None:
        """Test invalid customize format."""
        self.device.set_customize("{")
