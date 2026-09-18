"""Test c3 message."""

import pytest

from midealan.const import ProtocolVersion
from midealan.devices.c3.message import (
    C3DeviceMode,
    C3SilentLevel,
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
from midealan.message import ListTypes, MessageType


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

    def test_message_unit_para_response(self) -> None:
        """Test message unit-parameter response."""
        header = bytearray(self.header)
        header[-1] = 0x02
        body = bytearray(90)
        body[0] = ListTypes.X10
        body[1] = 7
        body[2] = 3
        body[3] = 4  # fan_speed / 10
        body[4] = 2  # not fan_speed, must not leak into it
        body[6] = 11
        body[7] = 12
        body[8] = 13
        body[9] = 14
        body[10] = 15
        body[11] = 16
        body[12] = 17
        body[13] = 18
        body[17] = 1
        body[18] = 2
        body[19] = 3
        body[20] = 4
        body[21] = 5
        body[33] = 19
        body[34] = 20
        body[35] = 21
        body[36] = 22
        body[37] = 23
        body[38] = 24
        body[39] = 25
        body[40] = 26
        body[41] = 27
        body[42] = 28
        body[43] = 29
        body[44] = 30
        body[45] = 31
        body[46] = 32
        body[47] = 33
        body[48] = 34
        body[49] = 35
        body[51] = 36
        body[52] = 37
        body[53] = 38
        body[54] = 39
        body[55] = 40
        body[56] = 41
        body[57] = 42
        body[59] = 43
        body[60] = 44
        body[61] = 45
        body[63] = 46
        body[66] = 0
        body[67] = 1
        body[68] = 2
        body[69] = 3
        body[70] = 4
        body[71] = 5
        body[72] = 6
        body[73] = 7
        body[74] = 8
        body[75] = 9
        body[76] = 10
        body[77] = 11
        body[78] = 12
        body[79] = 13
        body[80] = 14
        body[81] = 15
        body[82] = 16
        body[83] = 17

        response = MessageC3Response(bytes(header + body + bytearray([0x00])))

        assert response.body_type == ListTypes.X10
        assert response.__dict__["comp_run_freq"] == 7
        assert response.__dict__["unit_mode_run"] == 3
        assert response.__dict__["fan_speed"] == 40

    def test_message_unhandled_body_type_falls_through(self) -> None:
        """Test response dispatch when body type is not handled."""
        header = bytearray(self.header)
        header[-1] = 0x02
        body = bytearray([0x08, 0x00, 0x00])
        response = MessageC3Response(bytes(header + body))
        assert response.body_type == 0x08

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
        assert response.total_energy_consumption == 840610754
        assert hasattr(response, "total_produced_energy")
        assert response.total_produced_energy == 353774125
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
        body[3] = 8  # fan_speed / 10
        body[4] = 2  # not fan_speed, must not leak into it
        body[5] = 9  # fg_capacity_need
        body[6] = 3  # tempset, disabled in the lua; must not leak into it
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


class TestC3UnitParaFanSpeed:
    """Regression tests for the X10 (UNITPARA) outdoor fan speed offset.

    The frames below are taken from LAN captures of a Hyundai HYHC-V30W/D2RN8
    monobloc heat pump (OEM-equivalent Midea MHC-V30W/D2RN8, device type 0xC3,
    protocol version 3, Wi-Fi module 171H120F). Only the first four X10 data
    bytes are pinned, because those are the ones the capture confirms:

    * data[0] - compressor running frequency in Hz
    * data[1] - unit running mode (2 = cooling)
    * data[2] - outdoor fan speed in RPM / 10
    * data[3] - a different, near-constant quantity that the pre-fix parser
      mistakenly reported as the fan speed

    The remaining data bytes are left at zero; this test intentionally asserts
    only on the fields the captures verify.
    """

    HEADER = bytearray(
        [
            0xAA,
            0x00,
            0xC3,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x03,  # protocol version 3
            MessageType.query,
        ],
    )

    @staticmethod
    def _build_response(data_head: bytes) -> MessageC3Response:
        """Build an X10 query response whose payload starts with data_head."""
        body = bytearray(88)  # body type + 86 data bytes + CRC
        body[0] = ListTypes.X10
        body[1 : 1 + len(data_head)] = data_head
        return MessageC3Response(
            bytes(TestC3UnitParaFanSpeed.HEADER + body),
        )

    @pytest.mark.parametrize(
        ("data_head", "comp_run_freq", "fan_speed"),
        [
            # Cooling at 57 Hz, fan command 0x40 -> 640 RPM (Super Silent).
            (b"\x39\x02\x40\x02", 57, 640),
            # Cooling at 35 Hz, fan command 0x3f -> 630 RPM (Super Silent).
            (b"\x23\x02\x3f\x02", 35, 630),
            # Compressor thermo-off: the outdoor fan keeps running for a short
            # post-run at 0x4a -> 740 RPM while the compressor is already at 0.
            (b"\x00\x02\x4a\x02", 0, 740),
            # Post-run finished: fan command 0 and the fans physically stopped.
            (b"\x00\x02\x00\x02", 0, 0),
        ],
        ids=["cooling_57hz", "cooling_35hz", "thermo_off_fan_post_run", "fan_stopped"],
    )
    def test_fan_speed_is_read_after_unit_mode_run(
        self,
        data_head: bytes,
        comp_run_freq: int,
        fan_speed: int,
    ) -> None:
        """Test fan speed comes from the byte right after the running mode."""
        response = self._build_response(data_head)

        assert response.body_type == ListTypes.X10
        assert hasattr(response, "comp_run_freq")
        assert hasattr(response, "unit_mode_run")
        assert hasattr(response, "fan_speed")
        assert response.comp_run_freq == comp_run_freq
        assert response.unit_mode_run == C3DeviceMode.COOL
        assert response.unit_mode_run == 2
        assert response.fan_speed == fan_speed

    def test_fan_speed_is_independent_of_compressor_state(self) -> None:
        """Test a stopped compressor does not force the fan speed to zero."""
        running = self._build_response(b"\x39\x02\x40\x02")
        post_run = self._build_response(b"\x00\x02\x4a\x02")
        stopped = self._build_response(b"\x00\x02\x00\x02")
        assert hasattr(running, "comp_run_freq")
        assert hasattr(post_run, "comp_run_freq")
        assert hasattr(post_run, "fan_speed")
        assert hasattr(stopped, "comp_run_freq")
        assert hasattr(stopped, "fan_speed")

        assert running.comp_run_freq > 0
        assert post_run.comp_run_freq == 0
        assert post_run.fan_speed > 0
        assert stopped.comp_run_freq == 0
        assert stopped.fan_speed == 0


class TestC3Energy32BitCounters:
    """The 32 bit energy counters against the official C3 lua protocol.

    Reference: `T_0000_C3_171H120F_2023062601.lua`. Every one of these counters
    is built as `_bodyBytes[n] * 16777216 + _bodyBytes[n+1] * 65536 +
    _bodyBytes[n+2] * 256 + _bodyBytes[n+3]`, so the most significant byte is
    shifted by 24, not 32. The bug only shows once a counter passes 2 ** 24,
    which is why the existing fixtures never caught it.
    """

    HEADER = bytearray([0xAA, 0x00, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00])

    def _response(self, msg_type: int, values: dict[int, int]) -> MessageC3Response:
        """Build a C3 response with the given body bytes set."""
        header = bytearray(self.HEADER)
        header[-1] = msg_type
        body = bytearray(96)
        body[0] = ListTypes.X04 if msg_type == MessageType.notify1 else ListTypes.X10
        for index, value in values.items():
            body[index] = value
        return MessageC3Response(bytes(header + body))

    def test_notify_energy_counters_are_32_bit(self) -> None:
        """Test the notify1 0x04 totals use a 24 bit shift on the top byte."""
        response = self._response(
            MessageType.notify1,
            {2: 0x01, 3: 0x02, 4: 0x03, 5: 0x04, 6: 0x0A, 7: 0x0B, 8: 0x0C, 9: 0x0D},
        )
        assert hasattr(response, "total_energy_consumption")
        assert hasattr(response, "total_produced_energy")
        assert response.total_energy_consumption == 0x01020304
        assert response.total_produced_energy == 0x0A0B0C0D

    def test_unit_para_energy_counters_are_32_bit(self) -> None:
        """Test the X10 totals use a 24 bit shift on the top byte."""
        response = self._response(
            MessageType.query,
            {
                67: 0x01,
                68: 0x02,
                69: 0x03,
                70: 0x04,
                71: 0x05,
                72: 0x06,
                73: 0x07,
                74: 0x08,
                75: 0x09,
                76: 0x0A,
                77: 0x0B,
                78: 0x0C,
                79: 0x0D,
                80: 0x0E,
                81: 0x0F,
                82: 0x10,
            },
        )
        assert hasattr(response, "total_electricity0")
        assert hasattr(response, "total_thermal0")
        assert hasattr(response, "heat_elec_total_consum0")
        assert hasattr(response, "heat_elec_total_capacity0")
        assert response.total_electricity0 == 0x01020304
        assert response.total_thermal0 == 0x05060708
        assert response.heat_elec_total_consum0 == 0x090A0B0C
        assert response.heat_elec_total_capacity0 == 0x0D0E0F10


class TestC3UnitParaNotify:
    """The MSG_TYPE_UP_UNITPARA notify body (message type 0x04, body 0x05).

    The frame below is a real capture from a Hyundai HYHC-V30W/D2RN8
    (OEM-equivalent Midea MHC-V30W/D2RN8, protocol 3, module 171H120F). The
    unit pushes this message unsolicited between polls; 41 of them appeared
    alongside 782 X10 query responses in the same session.

    Every value asserted here was cross-checked against the X10 query response
    captured immediately before it, and agreed to within sampling drift.
    """

    HEADER = bytearray(
        [0xAA, 0x00, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, MessageType.notify1],
    )

    BODY = bytes.fromhex(
        "05213f24264d0d0b0400e10b1909081919041000640b2237ffff0000000000000000"
        "002fa000000000000000000000000001010000000000000b94630200000000000000"
        "00000000000000000000000000000000000000000000000000000000000000000000"
        "00000000000000000000000000000000000000000000000000000000000000000000"
        "00000000000000000000000000000000000000000000000000000000000000000000"
        "00000000000000000000000000000000000000000000000000000000000000000000"
        "00000000000000000000000000000000000000000000000000000000000000000000"
        "00",
    )

    def test_notify_unit_para_is_parsed(self) -> None:
        """Test the notify body decodes into the shared runtime attributes."""
        response = MessageC3Response(bytes(self.HEADER + self.BODY + bytes([0x00])))

        assert response.body_type == ListTypes.X05
        assert hasattr(response, "unit_mode_run")
        assert hasattr(response, "comp_run_freq")
        assert hasattr(response, "fan_speed")
        assert hasattr(response, "temp_t3")
        assert hasattr(response, "temp_t4")
        assert hasattr(response, "temp_tp")
        assert hasattr(response, "temp_tw_in")
        assert hasattr(response, "temp_tw_out")
        assert hasattr(response, "odu_comp_current")
        assert hasattr(response, "odu_voltage")
        assert hasattr(response, "temp_t1")
        assert hasattr(response, "temp_t2")
        assert hasattr(response, "temp_t2b")
        assert hasattr(response, "pressure_high")
        assert hasattr(response, "pressure_low")
        assert hasattr(response, "odu_target_fre")
        assert hasattr(response, "temp_tf")
        assert hasattr(response, "total_electricity0")
        assert response.comp_run_freq == 33
        assert response.fan_speed == 630
        assert response.unit_mode_run == C3DeviceMode.COOL
        assert response.temp_t3 == 36
        assert response.temp_t4 == 38
        assert response.temp_tp == 77
        assert response.temp_tw_in == 13
        assert response.temp_tw_out == 11
        assert response.odu_comp_current == 4
        assert response.odu_voltage == 225
        assert response.temp_t1 == 11
        assert response.temp_t2 == 9
        assert response.temp_t2b == 8
        assert response.pressure_high == 1040
        assert response.pressure_low == 100
        assert response.odu_target_fre == 34
        assert response.temp_tf == 55
        assert response.total_electricity0 == 12192

    def test_query_x05_is_still_the_silence_body(self) -> None:
        """Test a query 0x05 still parses as silence, not as unit parameters."""
        header = bytearray(self.HEADER)
        header[-1] = MessageType.query
        body = bytearray.fromhex("050b170016320e001100")
        response = MessageC3Response(bytes(header + body + bytes([0x00])))

        assert response.body_type == ListTypes.X05
        assert hasattr(response, "silent_mode")
        assert response.silent_mode is True
        assert not hasattr(response, "comp_run_freq")


class TestC3UnitParaLuaOffsets:
    """Offsets in the X10 body checked against the official C3 lua protocol.

    Reference: `T_0000_C3_171H120F_2023062601.lua`, `MSG_TYPE_QUERY_UNITPARA`.
    The lua is 1-indexed, so `_bodyBytes[N]` is `body[data_offset + N - 1]`.
    Each case places a distinct decoy on the byte the parser used to read, so
    a regression cannot pass by picking up the neighbouring value.
    """

    HEADER = bytearray(
        [0xAA, 0x00, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, MessageType.query],
    )

    @staticmethod
    def _build_response(values: dict[int, int]) -> MessageC3Response:
        """Build an X10 query response with the given body bytes set."""
        body = bytearray(96)
        body[0] = ListTypes.X10
        for index, value in values.items():
            body[index] = value
        return MessageC3Response(bytes(TestC3UnitParaLuaOffsets.HEADER + body))

    def test_fg_capacity_need_lua_byte_5(self) -> None:
        """Test fg_capacity_need is lua _bodyBytes[5], not the tempset byte."""
        response = self._build_response({5: 9, 6: 3})
        assert hasattr(response, "fg_capacity_need")
        assert response.fg_capacity_need == 9

    def test_current_unit_capacity_is_16_bit(self) -> None:
        """Test current_unit_capacity is lua _bodyBytes[58] * 256 + [59]."""
        response = self._build_response({58: 2, 59: 44})
        assert hasattr(response, "current_unit_capacity")
        assert response.current_unit_capacity == 556

    def test_pwm_pump_out_lua_byte_65(self) -> None:
        """Test pwm_pump_out is lua _bodyBytes[65], decoded independently."""
        response = self._build_response({64: 46, 65: 80, 66: 99})
        assert hasattr(response, "room_rel_hum")
        assert hasattr(response, "pwm_pump_out")
        assert response.room_rel_hum == 46
        assert response.pwm_pump_out == 80

    def test_total_renew_power0_is_32_bit(self) -> None:
        """Test total_renew_power0 is lua _bodyBytes[87..90], not [85..86]."""
        response = self._build_response({85: 1, 86: 244, 89: 1, 90: 2})
        assert hasattr(response, "instant_renew_power0")
        assert hasattr(response, "total_renew_power0")
        assert response.instant_renew_power0 == 500
        assert response.total_renew_power0 == 258

    def test_short_body_does_not_raise(self) -> None:
        """Test a body that stops at the old maximum still parses."""
        body = bytearray(88)  # body type + 86 data bytes + CRC
        body[0] = ListTypes.X10
        response = MessageC3Response(bytes(self.HEADER + body))
        assert hasattr(response, "total_renew_power0")
        assert response.total_renew_power0 == 0


class TestC3UnitParaOutdoorTelemetryOffsets:
    """Pin the X10 body offsets for the outdoor-unit telemetry fields.

    Each case sets the field's byte(s) and puts a different decoy on each
    neighbouring byte, so a regression that shifts an offset by one cannot
    pass. Offsets match `T_0000_C3_171H120F_2023062601.lua`
    (`MSG_TYPE_QUERY_UNITPARA`) and were cross-checked against a real-device
    capture; the unit for the two pressures is still unconfirmed, as the lua
    applies no scaling and names none.
    """

    HEADER = bytearray(
        [0xAA, 0x00, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, MessageType.query],
    )

    @staticmethod
    def _build_response(values: dict[int, int]) -> MessageC3Response:
        """Build an X10 query response with the given body bytes set."""
        body = bytearray(96)
        body[0] = ListTypes.X10
        for index, value in values.items():
            body[index] = value
        return MessageC3Response(
            bytes(TestC3UnitParaOutdoorTelemetryOffsets.HEADER + body),
        )

    @pytest.mark.parametrize(
        ("attribute", "values", "expected"),
        [
            ("temp_t3", {6: 99, 7: 33, 8: 88}, 33),
            ("temp_tp", {8: 88, 9: 41, 10: 77}, 41),
            ("odu_comp_current", {16: 99, 17: 12, 18: 88}, 12),
            ("exv_current", {19: 99, 20: 1, 21: 200, 22: 88}, 456),
            ("temp_t1", {33: 99, 34: 21, 35: 88}, 21),
            ("temp_t2", {35: 99, 36: 7, 37: 88}, 7),
            ("temp_t2b", {36: 99, 37: 9, 38: 88}, 9),
            ("pressure_low", {44: 99, 45: 2, 46: 10, 47: 88}, 522),
            ("temp_th", {46: 99, 47: 25, 48: 88}, 25),
            ("odu_target_fre", {48: 99, 49: 60, 50: 88}, 60),
            ("temp_tf", {51: 99, 52: 44, 53: 88}, 44),
        ],
    )
    def test_field_is_read_from_its_offset(
        self,
        attribute: str,
        values: dict[int, int],
        expected: int,
    ) -> None:
        """Test each telemetry field decodes from the expected body offset."""
        response = self._build_response(values)
        assert hasattr(response, attribute)
        assert getattr(response, attribute) == expected


class TestC3ErrorCodeDescription:
    """Test C3 error_code_description derived from C3_ERROR_CODE_TABLE."""

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

    def _build_body(self, error_code: int) -> bytearray:
        """Build a minimal X01 body with the given error_code byte."""
        return bytearray(
            [
                ListTypes.X01,
                0x0,  # BYTE 1
                0x0,  # BYTE 2
                0x0,  # BYTE 3
                0x0,  # BYTE 4: Mode
                0x0,  # BYTE 5: Mode Auto
                0,  # BYTE 6: Zone1 Target Temp
                0,  # BYTE 7: Zone2 Target Temp
                0,  # BYTE 8: DHW Target Temp
                0,  # BYTE 9: Room Target Temp * 2
                0,  # BYTE 10
                0,  # BYTE 11
                0,  # BYTE 12
                0,  # BYTE 13
                0,  # BYTE 14
                0,  # BYTE 15
                0,  # BYTE 16
                0,  # BYTE 17
                0,  # BYTE 18
                0,  # BYTE 19
                0,  # BYTE 20
                0,  # BYTE 21
                0,  # BYTE 22: tank_actual_temperature
                error_code,  # BYTE 23: error_code
                0x0,  # BYTE 24; tbh_control
                0x0,  # CRC
            ],
        )

    def test_error_code_zero_is_no_error(self) -> None:
        """error_code 0 maps to the 'No error' description."""
        self.header[-1] = MessageType.query
        response = MessageC3Response(bytes(self.header + self._build_body(0)))

        assert response.error_code == 0
        assert response.error_code_description == "No error"

    def test_error_code_known_value_maps_to_table_entry(self) -> None:
        """A known error_code maps to its display code and description."""
        self.header[-1] = MessageType.query
        response = MessageC3Response(bytes(self.header + self._build_body(9)))

        assert response.error_code == 9
        assert response.error_code_description == ("E8: Water flow failure")

    def test_error_code_unknown_value_falls_back_to_raw(self) -> None:
        """An error_code with no table entry reports the raw value."""
        self.header[-1] = MessageType.query
        response = MessageC3Response(bytes(self.header + self._build_body(200)))

        assert response.error_code == 200
        assert response.error_code_description == "Unknown code (raw=200)"

    @pytest.mark.parametrize(
        ("error_code", "expected_description"),
        [
            (
                2,
                (
                    "E1: Phase loss, or neutral and live wire connected reversely "
                    "(three-phase units only)"
                ),
            ),
            (48, "H9: Outlet water temp. sensor for Zone 2 (Tw2) fault"),
            (49, "HA: Outlet water temp. sensor (Tw_out) fault"),
            (
                52,
                "Hd: Communication fault between hydraulic modules (parallel)",
            ),
            (
                53,
                "HE: Communication error: main board <-> thermostat transfer board",
            ),
            (136, "L2: DC generatrix high voltage protection"),
            (141, "L7: Phase sequence fault"),
            (142, "L8: Speed difference > 15Hz between front and back clock"),
            (143, "L9: Speed difference > 15Hz between real and setting speed"),
        ],
        ids=[
            "raw_2_E1",
            "raw_48_H9",
            "raw_49_HA",
            "raw_52_Hd",
            "raw_53_HE",
            "raw_136_L2",
            "raw_141_L7",
            "raw_142_L8",
            "raw_143_L9",
        ],
    )
    def test_error_code_corrected_entries_match_source_pdf(
        self,
        error_code: int,
        expected_description: str,
    ) -> None:
        """Regression test for entries fixed against Modbus V4.7 table 1.

        These nine raw codes previously either carried text shifted from a
        neighbouring row (2, 48, 49) or a placeholder "Unknown / description
        unclear in source document" (52, 53, 136, 142, 143), or an unsourced
        addition (141). Values are taken from Midea Modbus documentation
        V4.7 (0052003044313 V.E), "Error code table 1", page 11.
        """
        self.header[-1] = MessageType.query
        response = MessageC3Response(
            bytes(self.header + self._build_body(error_code)),
        )

        assert response.error_code == error_code
        assert response.error_code_description == expected_description
