"""Test c3 message."""

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.c3.const import C3DeviceMode, C3SilentLevel
from midealocal.devices.c3.message import (
    MessageC3Base,
    MessageC3Response,
    MessageQuery,
    MessageQueryBasic,
    MessageQueryDisinfect,
    MessageQueryECO,
    MessageQueryHMIPara,
    MessageQueryInstall,
    MessageQuerySilence,
    MessageSet,
    MessageSetDisinfect,
    MessageSetECO,
    MessageSetSilent,
)
from midealocal.message import ListTypes, MessageType


class TestMessageC3Base:
    """Test C3 Message Base."""

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageC3Base(
            protocol_version=ProtocolVersion.V1,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )
        with pytest.raises(NotImplementedError):
            _ = msg.body


class TestC3MessageQuery:
    """Test C3 message query."""

    def test_query_body(self) -> None:
        """Test query body."""
        msg: MessageQuery = MessageQueryBasic(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x1])
        assert msg.body == expected_body

        msg = MessageQueryDisinfect(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x9])
        assert msg.body == expected_body

        msg = MessageQuerySilence(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x5])
        assert msg.body == expected_body

        msg = MessageQueryECO(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x7])
        assert msg.body == expected_body

        msg = MessageQueryInstall(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0x8])
        assert msg.body == expected_body

        msg = MessageQueryHMIPara(protocol_version=ProtocolVersion.V1)
        expected_body = bytearray([0xA])
        assert msg.body == expected_body


class TestC3MessageSet:
    """Test C3 message set."""

    def test_set_body(self) -> None:
        """Test set body."""
        msg = MessageSet(protocol_version=ProtocolVersion.V1)
        msg.zone1_power = True
        msg.zone2_power = True
        msg.dhw_power = True
        msg.mode = C3DeviceMode.COOL
        msg.zone_target_temp = [23.0, 22.0]
        msg.dhw_target_temp = 45
        msg.room_target_temp = 24.0
        msg.zone1_curve = True
        msg.zone2_curve = True
        msg.tbh = True
        msg.fast_dhw = True

        expected_body = bytearray(
            [
                msg.body_type,
                0x1 | 0x2 | 0x4,
                0x2,
                23,
                22,
                45,
                24 * 2,
                0x1 | 0x2 | 0x4 | 0x8,
            ],
        )
        assert msg.body == expected_body


class TestC3MessageSetSilent:
    """Test C3 message set silent."""

    def test_set_silent_body(self) -> None:
        """Test set silent body."""
        msg = MessageSetSilent(protocol_version=ProtocolVersion.V1)
        expected_body_off = bytearray([0x5] + [0x0] * 9)
        expected_body_silent = bytearray([0x5, 0x1] + [0x0] * 8)
        expected_body_super_silent = bytearray([0x5, 0x3] + [0x0] * 8)
        assert msg.body == expected_body_off
        msg.silent_mode = True
        assert msg.body == expected_body_off  # mode true and level unset

        msg.silent_level = C3SilentLevel.SILENT
        assert msg.body == expected_body_silent
        msg.silent_mode = False
        assert msg.body == expected_body_off  # mode false and level silent

        msg.silent_level = C3SilentLevel.SUPER_SILENT
        assert msg.body == expected_body_off  # mode false and level super silent
        msg.silent_mode = True
        assert msg.body == expected_body_super_silent


class TestC3MessageSetECO:
    """Test C3 message set ECO."""

    def test_set_eco_body(self) -> None:
        """Test set ECO body."""
        msg = MessageSetECO(protocol_version=ProtocolVersion.V1)
        expected_body_off = bytearray([0x7] + [0x0] * 6)
        expected_body_eco = bytearray([0x7, 0x1] + [0x0] * 5)

        assert msg.body == expected_body_off
        msg.eco_mode = True
        assert msg.body == expected_body_eco


class TestC3MessageSetDisinfect:
    """Test C3 message set disinfect."""

    def test_set_disinfect_body(self) -> None:
        """Test set disinfect body."""
        msg = MessageSetDisinfect(protocol_version=ProtocolVersion.V1)
        expected_body_off = bytearray([0x9] + [0x0] * 4)
        expected_body_on = bytearray([0x9, 0x1] + [0x0] * 3)

        assert msg.body == expected_body_off
        msg.disinfect = True
        assert msg.body == expected_body_on


class TestMessageC3Response:
    """Test Message C3 Response."""

    @pytest.fixture(autouse=True)
    def _setup_header(self) -> None:
        """Do setup header."""
        self.header = bytearray(
            [
                0xAA,
                0x00,
                0xC3,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x00,  # message type
            ],
        )

    def test_message_generic_response(self) -> None:
        """Test message generic response."""
        body = bytearray(
            [
                ListTypes.X01,
                0x01
                | 0x04
                | 0x08
                | 0x20,  # BYTE 1: zone_power1 + dhw_power + zone1_curve + tbh
                0x30,  # BYTE 2: temp_type [True, True]
                0x2 | 0x8,  # BYTE 3: silent on, eco on
                0x3,  # BYTE 4: Mode HEAT
                0x2,  # BYTE 5: Mode Auto COOL
                21,  # BYTE 6: Zone1 Target Temp
                22,  # BYTE 7: Zone2 Target Temp
                42,  # BYTE 8: DHW Target Temp
                45,  # BYTE 9: Room Target Temp * 2
                30,  # BYTE 10: zone1_heating_temp_max
                20,  # BYTE 11: zone1_heating_temp_min
                25,  # BYTE 12: zone1_cooling_temp_max
                16,  # BYTE 13: zone1_cooling_temp_min
                35,  # BYTE 14: zone2_heating_temp_max
                20,  # BYTE 15: zone2_heating_temp_min
                30,  # BYTE 16: zone2_cooling_temp_max
                18,  # BYTE 17: zone2_cooling_temp_min
                61,  # BYTE 18: room_temp_max / 2
                32,  # BYTE 19: room_temp_min / 2
                50,  # BYTE 20: dhw_temp_max
                34,  # BYTE 21: dhw_temp_min
                44,  # BYTE 22: tank_actual_temperature
                0x0,  # BYTE 23; error_code
                0x0,  # BYTE 24; tbh_control
                0x0,  # CRC
            ],
        )

        for message_type in (
            MessageType.set,
            MessageType.query,
            MessageType.notify1,
            MessageType.notify2,
        ):
            self.header[-1] = message_type
            response = MessageC3Response(bytes(self.header + body))

            assert response.body_type == ListTypes.X01
            assert hasattr(response, "zone1_power")
            assert response.zone1_power is True
            assert hasattr(response, "zone2_power")
            assert response.zone2_power is False
            assert hasattr(response, "dhw_power")
            assert response.dhw_power is True
            assert hasattr(response, "zone1_curve")
            assert response.zone1_curve is True
            assert hasattr(response, "zone2_curve")
            assert response.zone2_curve is False
            assert hasattr(response, "tbh")
            assert response.tbh is True
            assert hasattr(response, "fast_dhw")
            assert response.fast_dhw is False
            assert hasattr(response, "zone_temp_type")
            assert response.zone_temp_type == [True, True]
            assert hasattr(response, "silent_mode")
            assert response.silent_mode is True
            assert hasattr(response, "eco_mode")
            assert response.eco_mode is True
            assert hasattr(response, "mode")
            assert response.mode == C3DeviceMode.HEAT
            assert hasattr(response, "mode_auto")
            assert response.mode_auto == C3DeviceMode.COOL
            assert hasattr(response, "zone_target_temp")
            assert response.zone_target_temp == [21.0, 22.0]
            assert hasattr(response, "dhw_target_temp")
            assert response.dhw_target_temp == 42.0
            assert hasattr(response, "room_target_temp")
            assert response.room_target_temp == 22.5
            assert hasattr(response, "zone_heating_temp_max")
            assert response.zone_heating_temp_max == [30.0, 35.0]
            assert hasattr(response, "zone_heating_temp_min")
            assert response.zone_heating_temp_min == [20.0, 20.0]
            assert hasattr(response, "zone_cooling_temp_max")
            assert response.zone_cooling_temp_max == [25.0, 30.0]
            assert hasattr(response, "zone_cooling_temp_min")
            assert response.zone_cooling_temp_min == [16.0, 18.0]
            assert hasattr(response, "room_temp_max")
            assert response.room_temp_max == 30.5
            assert hasattr(response, "room_temp_min")
            assert response.room_temp_min == 16.0
            assert hasattr(response, "dhw_temp_max")
            assert response.dhw_temp_max == 50
            assert hasattr(response, "dhw_temp_min")
            assert response.dhw_temp_min == 34
            assert hasattr(response, "tank_actual_temperature")
            assert response.tank_actual_temperature == 44
            assert hasattr(response, "error_code")
            assert response.error_code == 0x0

    def test_message_notify1_x04_response(self) -> None:
        """Test message notify1 x04 response."""
        self.header[-1] = MessageType.notify1
        body = bytearray(
            [
                ListTypes.X04,
                0x01 | 0x04,  # BYTE 1: status_dhw + status_heating
                0x32,  # BYTE 2: total_energy_consumption
                0x1A,  # BYTE 3: total_energy_consumption
                0xB3,  # BYTE 4: total_energy_consumption
                0xC2,  # BYTE 5: total_energy_consumption
                21,  # BYTE 6: total_produced_energy
                22,  # BYTE 7: total_produced_energy
                42,  # BYTE 8: total_produced_energy
                45,  # BYTE 9: total_produced_energy
                30,  # BYTE 10: outdoor_temperature is  t4
                40,  # BYTE 12: zone1_temp_set
                50,  # BYTE 13: zone2_temp_set
                45,  # BYTE 14: t5s
                55,  # BYTE 15: tas
                0x0,  # CRC
            ],
        )
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == ListTypes.X04
        assert hasattr(response, "status_tbh")
        assert response.status_tbh is False
        assert hasattr(response, "status_dhw")
        assert response.status_dhw is True
        assert hasattr(response, "status_ibh")
        assert response.status_ibh is False
        assert hasattr(response, "status_heating")
        assert response.status_heating is True
        assert hasattr(response, "total_energy_consumption")
        assert response.total_energy_consumption == 214750114754
        assert hasattr(response, "total_produced_energy")
        assert response.total_produced_energy == 90195765805
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == 30
        assert hasattr(response, "zone1_temp_set")
        assert response.zone1_temp_set == 40
        assert hasattr(response, "zone2_temp_set")
        assert response.zone2_temp_set == 50
        assert hasattr(response, "t5s")
        assert response.t5s == 45
        assert hasattr(response, "tas")
        assert response.tas == 55

        body[10] = 253
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "outdoor_temperature")
        assert response.outdoor_temperature == -3

    def test_message_silence_response(self) -> None:
        """Test message silence response."""
        self.header[-1] = MessageType.query
        body = bytearray(
            [
                ListTypes.X05,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is False
        assert hasattr(response, "silent_level")
        assert response.silent_level == C3SilentLevel.OFF.name

        body[1] = 0x1
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is True
        assert hasattr(response, "silent_level")
        assert response.silent_level == C3SilentLevel.SILENT.name

        body[1] = 0x8
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is False
        assert hasattr(response, "silent_level")
        assert response.silent_level == C3SilentLevel.OFF.name

        body[1] = 0x9
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is True
        assert hasattr(response, "silent_level")
        assert response.silent_level == C3SilentLevel.SUPER_SILENT.name

    def test_message_eco_response(self) -> None:
        """Test message ECO response."""
        self.header[-1] = MessageType.query
        body = bytearray([ListTypes.X07, 0x03, 0x00])
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == ListTypes.X07
        assert hasattr(response, "eco_function_state")
        assert response.eco_function_state is True
        assert hasattr(response, "eco_timer_state")
        assert response.eco_timer_state is True

        body[1] = 0x0
        response = MessageC3Response(bytes(self.header + body))
        assert hasattr(response, "eco_function_state")
        assert response.eco_function_state is False
        assert hasattr(response, "eco_timer_state")
        assert response.eco_timer_state is False

    def test_message_disinfect_response(self) -> None:
        """Test message disinfect response."""
        self.header[-1] = MessageType.query
        body = bytearray(
            [
                ListTypes.X09,
                0x03,  # BYTE 1: disinfect + disinfect_run
                5,  # BYTE 2: disinfect_set_weekday
                10,  # BYTE 3: disinfect_start_hour
                30,  # BYTE 4: disinfect_start_minutes
                0x00,  # CRC
            ],
        )
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == ListTypes.X09
        assert hasattr(response, "disinfect")
        assert response.disinfect is True
        assert hasattr(response, "disinfect_run")
        assert response.disinfect_run is True
        assert hasattr(response, "disinfect_set_weekday")
        assert response.disinfect_set_weekday == 5
        assert hasattr(response, "disinfect_start_hour")
        assert response.disinfect_start_hour == 10
        assert hasattr(response, "disinfect_start_minutes")
        assert response.disinfect_start_minutes == 30

    def test_message_unitpara_response(self) -> None:
        """Test message unit parameters response."""
        self.header[-1] = MessageType.query
        body = bytearray(88)  # body type + 86 data bytes + CRC
        body[0] = ListTypes.X10
        body[1] = 50  # comp_run_freq
        body[2] = 2  # unit_mode_run
        body[4] = 8  # fan_speed / 10
        body[6] = 9  # fg_capacity_need
        body[8] = 30  # temp_t4
        body[10] = 40  # temp_tw_in
        body[11] = 35  # temp_tw_out
        body[18] = 1  # odu_voltage high byte
        body[19] = 44  # odu_voltage low byte
        body[22] = 5  # odu_model
        body[43] = 2  # pressure_high high byte
        body[70] = 10  # total_electricity0 low byte
        body[83] = 1  # instant_power0 high byte
        body[84] = 244  # instant_power0 low byte
        response = MessageC3Response(bytes(self.header + body))
        assert response.body_type == ListTypes.X10
        assert hasattr(response, "comp_run_freq")
        assert response.comp_run_freq == 50
        assert hasattr(response, "unit_mode_run")
        assert response.unit_mode_run == 2
        assert hasattr(response, "fan_speed")
        assert response.fan_speed == 80
        assert hasattr(response, "fg_capacity_need")
        assert response.fg_capacity_need == 9
        assert hasattr(response, "temp_t4")
        assert response.temp_t4 == 30
        assert hasattr(response, "temp_tw_in")
        assert response.temp_tw_in == 40
        assert hasattr(response, "temp_tw_out")
        assert response.temp_tw_out == 35
        assert hasattr(response, "odu_voltage")
        assert response.odu_voltage == 300
        assert hasattr(response, "odu_model")
        assert response.odu_model == 5
        assert hasattr(response, "pressure_high")
        assert response.pressure_high == 512
        assert hasattr(response, "total_electricity0")
        assert response.total_electricity0 == 10
        assert hasattr(response, "instant_power0")
        assert response.instant_power0 == 500
