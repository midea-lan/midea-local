"""Midea local C3 message."""

from enum import IntEnum

from midealan.const import DeviceType
from midealan.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

TEMP_NEG_VALUE = 127
# Outdoor fan speed is transmitted as RPM / 10.
FAN_SPEED_FACTOR = 10

# Error code lookup (source: Midea Modbus documentation V4.7,
# 0052003044313 V.E, "Error code table 1", page 11).
# Format: raw_value -> (display_code, human_description).
# All entries below were cross-checked against that source; the four
# codes previously marked "unknown" (Hd, HE, L2, L9) plus L8 are now
# filled in, and three codes (E1, H9, HA) whose text had been
# shifted from neighbouring rows during transcription are corrected.
C3_ERROR_CODE_TABLE: dict[int, tuple[str, str]] = {
    1: ("E0", "Water flow fault (E8 displayed 3 times)"),
    2: (
        "E1",
        (
            "Phase loss, or neutral and live wire connected reversely "
            "(three-phase units only)"
        ),
    ),
    3: ("E2", "Communication fault between controller and hydraulic module"),
    4: ("E3", "Final outlet water temp. sensor (T1) fault"),
    5: ("E4", "Water tank temp. sensor (T5) fault"),
    6: ("E5", "Condenser outlet refrigerant temp. sensor (T3) fault"),
    7: ("E6", "Ambient temp. sensor (T4) fault"),
    8: ("E7", "Buffer tank up temp. sensor (Tbt1) fault"),
    9: ("E8", "Water flow failure"),
    10: ("E9", "Suction temp. sensor (Th) fault"),
    11: ("EA", "Discharge temp. sensor (Tp) fault"),
    12: ("Eb", "Solar temp. sensor (Tsolar) fault"),
    13: ("Ec", "Buffer tank low temp. sensor (Tbt2) fault"),
    14: ("Ed", "Inlet water temp. sensor (Tw_in) malfunction"),
    15: ("EE", "Hydraulic module EEPROM failure"),
    20: ("P0", "Low pressure switch protection"),
    21: ("P1", "High pressure switch protection"),
    23: ("P3", "Compressor overcurrent protection"),
    24: ("P4", "High discharge temperature protection"),
    25: ("P5", "|Tw_out - Tw_in| value too big protection"),
    26: ("P6", "Inverter module protection"),
    31: ("Pb", "Anti-freeze mode"),
    33: ("Pd", "High refrigerant outlet temp. protection of condenser"),
    38: ("PP", "Tw_out - Tw_in unusual protection"),
    39: ("H0", "Communication fault: hydraulic PCB B <-> main control PCB B"),
    40: ("H1", "Communication fault: inverter PCB A <-> main control PCB B"),
    41: ("H2", "Refrigerant liquid temp. sensor (T2) fault"),
    42: ("H3", "Refrigerant gas temp. sensor (T2B) fault"),
    43: ("H4", "Three times P6 (L0/L1) protection"),
    44: ("H5", "Room temp. sensor (Ta) fault"),
    45: ("H6", "DC fan motor fault"),
    46: ("H7", "Voltage protection"),
    47: ("H8", "Pressure sensor fault"),
    48: ("H9", "Outlet water temp. sensor for Zone 2 (Tw2) fault"),
    49: ("HA", "Outlet water temp. sensor (Tw_out) fault"),
    50: ("Hb", "3 times PP protection and Tw_out < 7C"),
    52: ("Hd", "Communication fault between hydraulic modules (parallel)"),
    53: ("HE", "Communication error: main board <-> thermostat transfer board"),
    54: ("HF", "Inverter module board EEPROM fault"),
    55: ("HH", "H6 displayed 10 times in 2 hours"),
    57: ("HP", "Low pressure protection (Pe<0.6) occurred 3 times in 1 hour"),
    65: ("C7", "Transducer module temperature too high protection"),
    112: ("bH", "PED PCB fault"),
    116: ("F1", "Low DC generatrix voltage protection"),
    134: ("L0", "Module protection"),
    135: ("L1", "DC generatrix low voltage protection"),
    136: ("L2", "DC generatrix high voltage protection"),
    138: ("L4", "MCE fault"),
    139: ("L5", "Zero speed protection"),
    141: ("L7", "Phase sequence fault"),
    142: ("L8", "Speed difference > 15Hz between front and back clock"),
    143: ("L9", "Speed difference > 15Hz between real and setting speed"),
}


class C3SilentLevel(IntEnum):
    """C3 Silent Level."""

    OFF = 0x0
    SILENT = 0x1
    SUPER_SILENT = 0x3


class C3DeviceMode(IntEnum):
    """C3 Device Mode."""

    COOL = 2
    HEAT = 3


class MessageC3Base(MessageRequest):
    """C3 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize C3 message base."""
        super().__init__(
            device_type=DeviceType.C3,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageC3Base):
    """C3 message query."""

    def __init__(self, protocol_version: int, body_type: ListTypes) -> None:
        """Initialize C3 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageQueryBasic(MessageQuery):
    """C3 Message query basic."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query basic."""
        super().__init__(protocol_version, ListTypes.X01)


class MessageQuerySilence(MessageQuery):
    """C3 Message query silence."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X05)


class MessageQueryECO(MessageQuery):
    """C3 Message query ECO."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X07)


class MessageQueryInstall(MessageQuery):
    """C3 Message query INSTALL."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X08)


class MessageQueryDisinfect(MessageQuery):
    """C3 Message query Disinfect."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X09)


class MessageQueryUnitPara(MessageQuery):
    """C3 Message query UNITPARA."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X10)


class MessageQueryHMIPara(MessageQuery):
    """C3 Message query HMIPARA."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X0A)


class MessageSet(MessageC3Base):
    """C3 message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X01,
        )
        self.zone1_power = False
        self.zone2_power = False
        self.dhw_power = False
        self.mode = 0
        self.zone_target_temp = [25.0, 25.0]
        self.dhw_target_temp = 40.0
        self.room_target_temp = 25.0
        self.zone1_curve = False
        self.zone2_curve = False
        self.fast_dhw = False
        self.tbh = False

    @property
    def _body(self) -> bytearray:
        # Byte 1
        zone1_power = 0x01 if self.zone1_power else 0x00
        zone2_power = 0x02 if self.zone2_power else 0x00
        dhw_power = 0x04 if self.dhw_power else 0x00
        # Byte 7
        zone1_curve = 0x01 if self.zone1_curve else 0x00
        zone2_curve = 0x02 if self.zone2_curve else 0x00
        tbh = 0x04 if self.tbh else 0x00
        fast_dhw = 0x08 if self.fast_dhw else 0x00
        room_target_temp = int(self.room_target_temp * 2)
        zone1_target_temp = int(self.zone_target_temp[0])
        zone2_target_temp = int(self.zone_target_temp[1])
        dhw_target_temp = int(self.dhw_target_temp)
        return bytearray(
            [
                zone1_power | zone2_power | dhw_power,
                self.mode,
                zone1_target_temp,
                zone2_target_temp,
                dhw_target_temp,
                room_target_temp,
                zone1_curve | zone2_curve | tbh | fast_dhw,
            ],
        )


class MessageSetSilent(MessageC3Base):
    """C3 message set silent."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message set silent."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X05,
        )
        self.silent_mode = False
        self.silent_level = C3SilentLevel.OFF

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                self.silent_level if self.silent_mode else C3SilentLevel.OFF,
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


class MessageSetECO(MessageC3Base):
    """C3 message set eco."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message set eco."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X07,
        )
        self.eco_mode = False

    @property
    def _body(self) -> bytearray:
        eco_mode = 0x01 if self.eco_mode else 0

        return bytearray([eco_mode, 0x00, 0x00, 0x00, 0x00, 0x00])


class MessageSetDisinfect(MessageC3Base):
    """C3 message set Disinfect."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message set eco."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X09,
        )
        self.disinfect = False

    @property
    def _body(self) -> bytearray:
        disinfect = 0x01 if self.disinfect else 0

        return bytearray([disinfect, 0x00, 0x00, 0x00])


class C3BasicBody(MessageBody):
    """C3 Basic message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 message body."""
        super().__init__(body)
        # BodyBytes 1
        self.zone1_power = body[data_offset + 0] & 0x01 > 0
        self.zone2_power = body[data_offset + 0] & 0x02 > 0
        self.dhw_power = body[data_offset + 0] & 0x04 > 0
        self.zone1_curve = body[data_offset + 0] & 0x08 > 0
        self.zone2_curve = body[data_offset + 0] & 0x10 > 0
        self.tbh = body[data_offset + 0] & 0x20 > 0
        self.fast_dhw = body[data_offset + 0] & 0x40 > 0
        self.remote_onoff = body[data_offset + 0] & 0x80 > 0
        # BodyBytes 2
        self.heat = body[data_offset + 1] & 0x01 > 0
        self.cool = body[data_offset + 1] & 0x02 > 0
        self.dhw = body[data_offset + 1] & 0x04 > 0
        self.double_zone = body[data_offset + 1] & 0x08 > 0
        self.zone_temp_type = [
            body[data_offset + 1] & 0x10 > 0,
            body[data_offset + 1] & 0x20 > 0,
        ]
        self.room_thermal_support = body[data_offset + 1] & 0x40 > 0
        self.room_thermal_state = body[data_offset + 1] & 0x80 > 0
        # BodyBytes 3
        self.time_set = body[data_offset + 2] & 0x01 > 0
        self.silent_mode = body[data_offset + 2] & 0x02 > 0
        self.holiday_on = body[data_offset + 2] & 0x04 > 0
        self.eco_mode = body[data_offset + 2] & 0x08 > 0
        self.zone_terminal_type = body[data_offset + 2]
        # BodyBytes 4
        self.mode = body[data_offset + 3]
        self.mode_auto = body[data_offset + 4]
        # zone1, zone2
        self.zone_target_temp = [
            float(body[data_offset + 5]),
            float(body[data_offset + 6]),
        ]
        self.dhw_target_temp = float(body[data_offset + 7])
        self.room_target_temp = float(body[data_offset + 8] / 2)
        # zone1, zone2
        self.zone_heating_temp_max = [
            float(body[data_offset + 9]),
            float(body[data_offset + 13]),
        ]
        self.zone_heating_temp_min = [
            float(body[data_offset + 10]),
            float(body[data_offset + 14]),
        ]
        self.zone_cooling_temp_max = [
            float(body[data_offset + 11]),
            float(body[data_offset + 15]),
        ]
        self.zone_cooling_temp_min = [
            float(body[data_offset + 12]),
            float(body[data_offset + 16]),
        ]
        self.room_temp_max = float(body[data_offset + 17] / 2)
        self.room_temp_min = float(body[data_offset + 18] / 2)
        self.dhw_temp_max = float(body[data_offset + 19])
        self.dhw_temp_min = float(body[data_offset + 20])
        self.tank_actual_temperature = float(body[data_offset + 21])
        self.error_code = body[data_offset + 22]
        if self.error_code == 0:
            self.error_code_description = "No error"
        else:
            _code_info = C3_ERROR_CODE_TABLE.get(self.error_code)
            if _code_info:
                self.error_code_description = f"{_code_info[0]}: {_code_info[1]}"
            else:
                self.error_code_description = f"Unknown code (raw={self.error_code})"
        self.tbh_control = body[data_offset + 23] & 0x80 > 0
        self.SysEnergyAnaEN = body[data_offset + 23] & 0x20 > 0
        self.HMIEnergyAnaSetEN = body[data_offset + 23] & 0x40 > 0


class C3EnergyBody(MessageBody):
    """C3 Energy MSG_TYPE_UP_POWER4 message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 notify1 message body."""
        super().__init__(body)
        status_byte = body[data_offset]
        # bit0
        self.status_heating = (status_byte & 0x01) > 0
        # bit1
        self.status_cool = (status_byte & 0x02) > 0
        # bit2
        self.status_dhw = (status_byte & 0x04) > 0
        # bit3
        self.status_tbh = (status_byte & 0x08) > 0
        # bit4
        self.status_ibh = (status_byte & 0x10) > 0
        # 32 bit big-endian counters: the lua multiplies the top byte by
        # 16777216 (<< 24), not 4294967296.
        # total_energy_consumption
        self.total_energy_consumption = (
            (body[data_offset + 1] << 24)
            + (body[data_offset + 2] << 16)
            + (body[data_offset + 3] << 8)
            + (body[data_offset + 4])
        )
        # total_produced_energy
        self.total_produced_energy = (
            (body[data_offset + 5] << 24)
            + (body[data_offset + 6] << 16)
            + (body[data_offset + 7] << 8)
            + (body[data_offset + 8])
        )
        base_value = body[data_offset + 9]
        self.outdoor_temperature = float(
            (base_value - 256) if base_value > TEMP_NEG_VALUE else base_value,
        )  # outdoor_temperature is t4
        self.zone1_temp_set = float(body[data_offset + 10])
        self.zone2_temp_set = float(body[data_offset + 11])
        self.t5s = body[data_offset + 12]
        self.tas = body[data_offset + 13]


class C3SilenceBody(MessageBody):
    """C3 Silence message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 query silence message body."""
        super().__init__(body)
        self.silent_mode = body[data_offset] & 0x1 > 0
        self.silent_level = C3SilentLevel(
            (body[data_offset] & 0x1) + ((body[data_offset] & 0x8) >> 2)
            if self.silent_mode
            else C3SilentLevel.OFF.value,
        ).name
        # Message protocol information:
        # silence_function_state: Byte 1, BIT 0
        # silence_timer1_state: Byte 1, BIT 1
        # silence_timer2_state: Byte 1, BIT 2
        # silence_function_level: Byte 1, BIT 3
        # silence_timer1_starthour: Byte 2
        # silence_timer1_startmin: Byte 3
        # silence_timer1_endhour: Byte 4
        # silence_timer1_endmin: Byte 5
        # silence_timer2_starthour: Byte 6
        # silence_timer2_startmin: Byte 7
        # silence_timer2_endhour: Byte 8
        # silence_timer2_endmin: Byte 9


class C3ECOBody(MessageBody):
    """C3 ECO message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 ECO message body."""
        super().__init__(body)
        self.eco_function_state = body[data_offset] & 0x01 > 0
        self.eco_timer_state = body[data_offset] & 0x02 > 0


class C3DisinfectBody(MessageBody):
    """C3 Disinfect message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 Disinfect message body."""
        super().__init__(body)
        self.disinfect = body[data_offset] & 0x01 > 0
        self.disinfect_run = body[data_offset] & 0x02 > 0
        self.disinfect_set_weekday = body[data_offset + 1]
        self.disinfect_start_hour = body[data_offset + 2]
        self.disinfect_start_minutes = body[data_offset + 3]


class C3UnitParaBody(MessageBody):
    """C3 UnitPara message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 UnitPara message body."""
        super().__init__(body)
        self.comp_run_freq = body[data_offset]
        self.unit_mode_run = body[data_offset + 1]
        # Outdoor fan speed, transmitted as RPM / 10 in a single byte.
        # It lives at data_offset + 2, directly after unit_mode_run; the
        # previous data_offset + 3 read a neighbouring byte that is small and
        # nearly constant while the unit runs, so fan_speed was reported as a
        # fixed low value (typically 20) regardless of the real fan command.
        self.fan_speed = body[data_offset + 2] * FAN_SPEED_FACTOR
        # lua _bodyBytes[5]; data_offset + 5 is the disabled `tempset` byte.
        self.fg_capacity_need = body[data_offset + 4]
        self.temp_t3 = body[data_offset + 6]
        self.temp_t4 = body[data_offset + 7]
        self.temp_tp = body[data_offset + 8]
        self.temp_tw_in = body[data_offset + 9]
        self.temp_tw_out = body[data_offset + 10]
        self.temp_tsolar = body[data_offset + 11]
        self.hydbox_subtype = body[data_offset + 12]
        self.fg_usb_info_connect = body[data_offset + 13]
        # self.usb_index_max  body[data_offset + 14]
        # lua _bodyBytes[17], compressor current in A. Already decoded by
        # C3UnitParaUpBody; enabled here so the polled response carries it too.
        self.odu_comp_current = body[data_offset + 16]
        self.odu_voltage = body[data_offset + 17] * 256 + body[data_offset + 18]
        self.exv_current = body[data_offset + 19] * 256 + body[data_offset + 20]
        self.odu_model = body[data_offset + 21]
        # self.unit_online_num  body[data_offset + 22]
        # self.current_code  body[data_offset + 23]
        self.temp_t1 = body[data_offset + 33]
        self.temp_tw2 = body[data_offset + 34]
        self.temp_t2 = body[data_offset + 35]
        self.temp_t2b = body[data_offset + 36]
        self.temp_t5 = body[data_offset + 37]
        self.temp_ta = body[data_offset + 38]
        self.temp_tb_t1 = body[data_offset + 39]
        self.temp_tb_t2 = body[data_offset + 40]
        self.hydrobox_capacity = body[data_offset + 41]
        self.pressure_high = body[data_offset + 42] * 256 + body[data_offset + 43]
        self.pressure_low = body[data_offset + 44] * 256 + body[data_offset + 45]
        self.temp_th = body[data_offset + 46]
        self.machine_type = body[data_offset + 47]
        self.odu_target_fre = body[data_offset + 48]
        self.dc_current = body[data_offset + 49]
        self.temp_tf = body[data_offset + 51]
        self.idu_t1s1 = body[data_offset + 52]
        self.idu_t1s2 = body[data_offset + 53]
        self.water_flower = body[data_offset + 54] * 256 + body[data_offset + 55]
        self.odu_plan_vol_lmt = body[data_offset + 56]
        # lua _bodyBytes[58] * 256 + _bodyBytes[59]; the low byte was dropped.
        self.current_unit_capacity = (
            body[data_offset + 57] * 256 + body[data_offset + 58]
        )
        self.sphera_ahs_voltage = body[data_offset + 59]
        self.temp_t4a_ver = body[data_offset + 60]
        self.water_pressure = body[data_offset + 61] * 256 + body[data_offset + 62]
        self.room_rel_hum = body[data_offset + 63]
        # lua _bodyBytes[65]; data_offset + 63 duplicated room_rel_hum.
        # On a 171H120F this byte reads 0 while the MSG_TYPE_UP_UNITPARA
        # notify reports pwmPumpOut = 99, so this firmware appears not to
        # populate it in the query response. _bodyBytes[66], which happens
        # to hold a constant 99, is marked reserved by the lua and is not
        # used here.
        self.pwm_pump_out = body[data_offset + 64]
        self.total_electricity0 = (
            (body[data_offset + 66] << 24)
            + (body[data_offset + 67] << 16)
            + (body[data_offset + 68] << 8)
            + (body[data_offset + 69])
        )
        self.total_thermal0 = (
            (body[data_offset + 70] << 24)
            + (body[data_offset + 71] << 16)
            + (body[data_offset + 72] << 8)
            + (body[data_offset + 73])
        )
        self.heat_elec_total_consum0 = (
            (body[data_offset + 74] << 24)
            + (body[data_offset + 75] << 16)
            + (body[data_offset + 76] << 8)
            + (body[data_offset + 77])
        )
        self.heat_elec_total_capacity0 = (
            (body[data_offset + 78] << 24)
            + (body[data_offset + 79] << 16)
            + (body[data_offset + 80] << 8)
            + (body[data_offset + 81])
        )
        self.instant_power0 = (body[data_offset + 82] << 8) + (body[data_offset + 83])
        self.instant_renew_power0 = (body[data_offset + 84] << 8) + (
            body[data_offset + 85]
        )
        # lua _bodyBytes[87..90] as a 32 bit value; data_offset + 84,85
        # duplicated instant_renew_power0. Read defensively: the lua frame runs
        # to _bodyBytes[191] but this parser previously stopped at
        # data_offset + 85, so shorter bodies must not raise.
        self.total_renew_power0 = (
            (self.read_byte(body, data_offset + 86) << 24)
            + (self.read_byte(body, data_offset + 87) << 16)
            + (self.read_byte(body, data_offset + 88) << 8)
            + self.read_byte(body, data_offset + 89)
        )


class C3UnitParaUpBody(MessageBody):
    """C3 UnitPara notify (MSG_TYPE_UP_UNITPARA) message body.

    The unit pushes this unsolicited between polls. It carries the same
    quantities as the X10 query response but in its own, shorter layout, so
    the attribute names deliberately match C3UnitParaBody: whichever message
    arrives last refreshes the same device attributes.

    Layout from the official C3 lua for the 171H120F module,
    MSG_TYPE_UP_UNITPARA block. The lua is 1-indexed, so _bodyBytes[N] is
    body[data_offset + N - 1].

    Only the fields C3UnitParaBody already exposes are decoded here. The lua
    block continues with a long Sys* energy-analysis section that reuses the
    same byte ranges for several different names, so it is not parsed.
    """

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 UnitPara notify message body."""
        super().__init__(body)
        self.comp_run_freq = body[data_offset]
        self.fan_speed = body[data_offset + 1] * FAN_SPEED_FACTOR
        self.temp_t3 = body[data_offset + 2]
        self.temp_t4 = body[data_offset + 3]
        self.temp_tp = body[data_offset + 4]
        self.temp_tw_in = body[data_offset + 5]
        self.temp_tw_out = body[data_offset + 6]
        self.odu_comp_current = body[data_offset + 7]
        self.odu_voltage = body[data_offset + 8] * 256 + body[data_offset + 9]
        self.temp_t1 = body[data_offset + 10]
        self.temp_tw2 = body[data_offset + 11]
        self.temp_t2 = body[data_offset + 12]
        self.temp_t2b = body[data_offset + 13]
        self.temp_t5 = body[data_offset + 14]
        self.temp_ta = body[data_offset + 15]
        self.pressure_high = body[data_offset + 16] * 256 + body[data_offset + 17]
        self.pressure_low = body[data_offset + 18] * 256 + body[data_offset + 19]
        self.temp_th = body[data_offset + 20]
        self.odu_target_fre = body[data_offset + 21]
        self.temp_tf = body[data_offset + 22]
        self.idu_t1s1 = body[data_offset + 23]
        self.idu_t1s2 = body[data_offset + 24]
        self.water_flower = body[data_offset + 25] * 256 + body[data_offset + 26]
        self.current_unit_capacity = (
            body[data_offset + 27] * 256 + body[data_offset + 28]
        )
        self.water_pressure = body[data_offset + 29] * 256 + body[data_offset + 30]
        self.room_rel_hum = body[data_offset + 31]
        self.total_electricity0 = (
            (body[data_offset + 32] << 24)
            + (body[data_offset + 33] << 16)
            + (body[data_offset + 34] << 8)
            + (body[data_offset + 35])
        )
        self.total_thermal0 = (
            (body[data_offset + 36] << 24)
            + (body[data_offset + 37] << 16)
            + (body[data_offset + 38] << 8)
            + (body[data_offset + 39])
        )
        # NOTE: _bodyBytes[41..48] are given two conflicting meanings by the
        # lua (heatElecTotConsum0 / heatTotCapacity0 overlap SysHeatDay*), and
        # on a real unit heatElecTotConsum0 reads 0 here while the X10 query
        # reports 2249 at the same moment. Not decoded.
        self.instant_power0 = (body[data_offset + 48] << 8) + (body[data_offset + 49])
        self.instant_renew_power0 = (body[data_offset + 50] << 8) + (
            body[data_offset + 51]
        )
        self.total_renew_power0 = (
            (body[data_offset + 52] << 24)
            + (body[data_offset + 53] << 16)
            + (body[data_offset + 54] << 8)
            + (body[data_offset + 55])
        )
        self.unit_mode_run = body[data_offset + 59]


class MessageC3Response(MessageResponse):
    """C3 message response."""

    # Populated dynamically by MessageResponse.set_attr(), which copies
    # every attribute of the parsed body onto the response via setattr().
    # mypy cannot see attributes added that way; declaring them here as
    # class-level annotations has no effect on runtime behaviour (set_attr()
    # remains the only place that assigns them) and only gives mypy the
    # static type it needs for the accesses in message_c3_test.py.
    error_code: int
    error_code_description: str

    def __init__(self, message: bytes) -> None:
        """Initialize C3 message response."""
        super().__init__(bytearray(message))
        if (
            self.message_type
            in [MessageType.set, MessageType.notify1, MessageType.query]
            and self.body_type == ListTypes.X01
        ) or self.message_type == MessageType.notify2:
            self.set_body(C3BasicBody(super().body, data_offset=1))
        elif (
            self.message_type == MessageType.notify1 and self.body_type == ListTypes.X04
        ):
            self.set_body(C3EnergyBody(super().body, data_offset=1))
        elif self.message_type == MessageType.query and self.body_type == ListTypes.X05:
            self.set_body(C3SilenceBody(super().body, data_offset=1))
        elif (
            self.message_type == MessageType.notify1 and self.body_type == ListTypes.X05
        ):
            self.set_body(C3UnitParaUpBody(super().body, data_offset=1))
        elif self.body_type == ListTypes.X07:
            self.set_body(C3ECOBody(super().body, data_offset=1))
        elif self.body_type == ListTypes.X09:
            self.set_body(C3DisinfectBody(super().body, data_offset=1))
        elif self.body_type == ListTypes.X10:
            self.set_body(C3UnitParaBody(super().body, data_offset=1))
        self.set_attr()
