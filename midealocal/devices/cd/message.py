"""Midea local CD message."""

from typing import Any, NotRequired, TypedDict

from midealocal.const import DeviceType
from midealocal.crc8 import calculate
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

OLD_BODY_LENGTH = 29  # T_0000_CD_3.lua body length 29
NEW_BODY_LENGTH = 35  # T_0000_CD_000K86A2_3 body length 34
EXTENDED_BODY_LENGTH = (
    45  # T_0000_CD_RSJRAC01_2023070401.lua extended body (auto_sterilize)
)

# Weekly schedule body: 7 days x 6 slots x 4 fields starting at body[9]
# body[9..176]: slot layout is {opentime, closetime, settemperature, modevalue}
WEEKLY_SCHEDULE_BODY_LENGTH = 176
# Daily timer body:
# 6 slots x 6 fields starting at body[4] (2 control bytes + effects byte)
DAILY_TIMER_BODY_LENGTH = 39
BODY_TYPE_GENERAL = 0x01
BODY_TYPE_WEEKLY = 0x02
BODY_TYPE_DAILY = 0x03
BODY_TYPE_STERILIZE = 0x06
BODY_TYPE_B0 = 0xB0
BODY_TYPE_B1 = 0xB1


class WeeklyTimer(TypedDict):
    """One writable weekly timer slot."""

    effect: NotRequired[bool]
    opentime: NotRequired[int | float | str]
    closetime: NotRequired[int | float | str]
    temperature: NotRequired[int | float | str]
    mode: NotRequired[int | float | str]


WeeklySchedule = dict[int, list[WeeklyTimer]]


class DailyTimer(TypedDict):
    """One writable daily timer slot."""

    effect: NotRequired[bool]
    openhour: NotRequired[int | float | str]
    openmin: NotRequired[int | float | str]
    closehour: NotRequired[int | float | str]
    closemin: NotRequired[int | float | str]
    temperature: NotRequired[int | float | str]
    mode: NotRequired[int | float | str]


class DailyTimerSchedule(TypedDict):
    """Writable daily timer programme."""

    amount: NotRequired[int | float | str]
    single_timer_on: NotRequired[bool]
    single_timer_off: NotRequired[bool]
    timers: NotRequired[list[DailyTimer]]


STATUS_SCHEDULE_MODE_INDEX = 56
STATUS_MAX_TEMP_UPPER_INDEX = 57
STATUS_MAX_TEMP_LOWER_INDEX = 58
STATUS_DISINFECT_TEMP_UPPER_INDEX = 59
STATUS_DISINFECT_TEMP_LOWER_INDEX = 60
STATUS_DISINFECT_TEMP_INDEX = 61
STATUS_DISINFECT_FLAGS_INDEX = 62
STATUS_DR_ENABLE_INDEX = 63
STATUS_DR_OPTION_INDEX = 64
STATUS_ELECTRIC_ROD_EXCEPTION_INDEX = 65
STATUS_CAPABILITY_FLAGS_INDEX = 66
STATUS_REMAINING_WATER_MAX_INDEX = 67
STATUS_FORCE_E_HEATING_INDEX = 68
STATUS_EXTENDED_MODE_FLAGS_INDEX = 52
STATUS_SUPPORT_HEAT_PUMP_INDEX = 53
STATUS_SUPPORT_SMART_INDEX = 54
STATUS_SUPPORT_NEGATIVE_INDEX = 55

B1_FIRST_TLV_LENGTH_INDEX = 5
B1_FUNCTION_FLAGS_TAG = 0x10
B1_NEW_VERSION_TAG = 0x11
B1_HOLIDAY_MAX_TAG = 0x12
B1_HOLIDAY_MIN_TAG = 0x13
B1_TIMER_STEP_TAG = 0x14
B1_AC_HEATER_SUPPORT_TAG = 0x15
B1_RESERVED_QUERY_TAG = 0x06
B1_HEAT_RECOVERY_TAG = 0x16
B1_HEAT_RECOVERY_ACTIVE = 0x02


class MessageCDBase(MessageRequest):
    """CD message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize CD message base."""
        super().__init__(
            device_type=DeviceType.CD,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageCDBase):
    """CD message query - normal status (queryType=0x01)."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize CD message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQueryWeekly(MessageCDBase):
    """CD message query - weekly schedule (queryType=0x02).

    Requests the full 7-day x 6-slot scheduled timer programme
    (effects + opentime + closetime + settemperature + modevalue per slot).
    The device responds with body_type=0x02.
    """

    def __init__(self, protocol_version: int) -> None:
        """Initialize CD message weekly schedule query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X02,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQueryDaily(MessageCDBase):
    """CD message query - daily timer (queryType=0x03).

    Requests the 6-slot daily timer programme
    (effect + openhour + openmin + closehour + closemin + settemperature + modevalue).
    The device responds with body_type=0x03.
    """

    def __init__(self, protocol_version: int) -> None:
        """Initialize CD message daily timer query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X03,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQueryB1(MessageCDBase):
    """Query CD extended capabilities and function flags."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize the official NetHome B1 capability query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.B1,
        )

    @property
    def _body(self) -> bytearray:
        body = bytearray(
            [
                0x08,
                B1_FUNCTION_FLAGS_TAG,
                0x00,
                B1_NEW_VERSION_TAG,
                0x00,
                B1_HOLIDAY_MAX_TAG,
                0x00,
                B1_HOLIDAY_MIN_TAG,
                0x00,
                B1_TIMER_STEP_TAG,
                0x00,
                B1_AC_HEATER_SUPPORT_TAG,
                0x00,
                B1_RESERVED_QUERY_TAG,
                0x00,
                B1_HEAT_RECOVERY_TAG,
                0x00,
            ],
        )
        crc_source = bytearray([BODY_TYPE_B1]) + body
        body.append(calculate(crc_source))
        return body


class MessageSet(MessageCDBase):
    """CD message set (controlType=0x01).

    RSJRAC07 / extended Lua (T_0000_CD_RSJRAC07) expects a **25-byte** control
    body (body_type + 24-byte payload). A shorter body faults the unit: target
    and max temperature become 0 until power-cycled or restored via the app.

    Layout (after MessageRequest prepends body_type at full[0]):
      full[1]  = 0x01 constant
      full[2]  = power
      full[3]  = mode (1 eco, 2 standard, 3 dual/compatibilizing, 4 smart, ...)
      full[4]  = target temperature (raw °C for new protocol)
      full[5]  = trValue (hysteresis; Lua range 2-6)
      full[6]  = openPTC (Lua forces 0 on normal sets)
      full[7]  = ptcTemp
      full[8]  = flags (vacation 0x10 / °F 0x80 / mute 0x08)
      full[9..20] = vacation days + date fields (0 for a plain set)
      full[21] = vacationTsValue
      full[22] = timer_type
      full[23] = **tsMax** (device max temperature; must not be 0)
      full[24] = dr_switch

    See https://github.com/midea-lan/midea-local/issues/468
    """

    DEFAULT_VACATION_DAYS = 100
    TR_VALUE_MIN = 2
    TR_VALUE_MAX = 6
    DEFAULT_TR_VALUE = 5
    DEFAULT_TS_MAX = 65

    def __init__(self, protocol_version: int) -> None:
        """Initialize CD message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X01,
        )
        self.power: bool = False
        self.target_temperature: float = 0
        self.aux_heating: bool = False
        self.fields: dict[Any, Any] = {}
        self.mode: int = 0
        # default to old protocol scaling unless explicitly disabled
        self.use_old_protocol: bool = True
        # vacation mode flag (bit 0x10 in bodyBytes[8])
        self.vacation_flag: bool = False
        # vacation remaining days (bodyBytes[9..10], big-endian)
        self.vacation_days: int = 0
        # fahrenheit mode (bit 0x80 in bodyBytes[8])
        self.fahrenheit: bool = False
        # vacation target temperature (full[21] / vacationTsValue)
        self.vacation_temperature: float = 0
        # device max temperature limit (full[23] / tsMax) — must be non-zero
        self.ts_max: int = 0
        self.schedule_mode: int = 0

    def read_field(self, field: str) -> int:
        """CD message set read field."""
        value = self.fields.get(field, 0)
        return int(value) if value else 0

    def _tr_value(self) -> int:
        """Return Tr hysteresis in the Lua-documented [2, 6] range."""
        tr = self.read_field("trValue")
        if tr < self.TR_VALUE_MIN or tr > self.TR_VALUE_MAX:
            return self.DEFAULT_TR_VALUE
        return tr

    def _ts_max_value(self) -> int:
        """Return tsMax; never 0 (firmware clamps setpoint when tsMax is 0)."""
        try:
            value = int(self.ts_max)
        except (TypeError, ValueError):
            value = 0
        if value <= 0:
            return self.DEFAULT_TS_MAX
        return value & 0xFF

    @property
    def _body(self) -> bytearray:
        power = 0x01 if self.power else 0x00
        mode = int(self.mode) & 0xFF
        target_temperature = (
            round(self.target_temperature * 2 + 30)
            if self.use_old_protocol
            else round(self.target_temperature)
        )
        # flags: vacation / fahrenheit / mute (preserved from echoed fields)
        byte8 = self.read_field("byte8") & 0x08
        if self.vacation_flag:
            byte8 |= 0x10
        if self.fahrenheit:
            byte8 |= 0x80

        if self.vacation_flag or self.vacation_days:
            vacation_high = (int(self.vacation_days) >> 8) & 0xFF
            vacation_low = int(self.vacation_days) & 0xFF
        else:
            vacation_high = 0
            vacation_low = 0

        vacation_ts = 0
        if (
            isinstance(self.vacation_temperature, int | float)
            and self.vacation_temperature > 0
        ):
            vacation_ts = int(self.vacation_temperature) & 0xFF

        # 24-byte payload; MessageRequest prepends body_type → 25-byte body
        return bytearray(
            [
                0x01,  # full[1] constant
                power,  # full[2]
                mode,  # full[3]
                int(target_temperature) & 0xFF,  # full[4]
                self._tr_value() & 0xFF,  # full[5]
                0x00,  # full[6] openPTC forced 0 (Lua normal set)
                self.read_field("ptcTemp") & 0xFF,  # full[7]
                byte8 & 0xFF,  # full[8]
                vacation_high,  # full[9]
                vacation_low,  # full[10]
                0,  # full[11]
                0,  # full[12]
                0,  # full[13]
                0,  # full[14]
                0,  # full[15]
                0,  # full[16]
                0,  # full[17]
                0,  # full[18]
                0,  # full[19]
                0,  # full[20]
                vacation_ts,  # full[21] vacationTsValue
                self.schedule_mode & 0xFF,  # full[22] schedule mode
                self._ts_max_value(),  # full[23] tsMax (must be non-zero)
                0x00,  # full[24] dr_switch
            ],
        )


class MessageSetSterilize(MessageCDBase):
    """CD message set sterilize (controlType=0x06).

    Controls the sterilization/disinfect function.
    Lua jsonToData controlType=0x06 layout:
      bodyBytes[0] = 0x06 (body_type, prepended by MessageRequest.body)
      bodyBytes[1] = 0x01 (constant, _body[0])
      bodyBytes[2] = sterilizeEffect  (0x80=ON, 0x00=OFF)
      bodyBytes[3] = autoSterilizeWeek
      bodyBytes[4] = autoSterilizeHour
      bodyBytes[5] = autoSterilizeMinute
      bodyBytes[6] = disinfectionTemperature (extended protocol only)

    The extended 7-byte payload is writable after the device reports extended
    protocol support. Legacy or unknown devices keep the 6-byte form and must
    not receive the appended disinfection temperature.
    """

    # Valid range for disinfection temperature (°C)
    DISINFECT_TEMP_MIN: float = 60.0
    DISINFECT_TEMP_MAX: float = 70.0
    AUTO_STERILIZE_WEEK_MIN: int = 0
    AUTO_STERILIZE_WEEK_MAX: int = 6
    AUTO_STERILIZE_HOUR_MIN: int = 0
    AUTO_STERILIZE_HOUR_MAX: int = 23
    AUTO_STERILIZE_MINUTE_MIN: int = 0
    AUTO_STERILIZE_MINUTE_MAX: int = 59
    DEFAULT_AUTO_STERILIZE_WEEK: int = 4
    DEFAULT_AUTO_STERILIZE_HOUR: int = 14
    DEFAULT_AUTO_STERILIZE_MINUTE: int = 5

    @staticmethod
    def _clamp_int(value: object, min_value: int, max_value: int) -> int:
        parsed: int
        if isinstance(value, int | float | str | bytes | bytearray):
            try:
                parsed = int(value)
            except ValueError:
                parsed = min_value
        else:
            parsed = min_value
        return max(min_value, min(max_value, parsed))

    @classmethod
    def clamp_week(cls, value: object) -> int:
        """Clamp auto sterilize weekday for writes."""
        return cls._clamp_int(
            value,
            cls.AUTO_STERILIZE_WEEK_MIN,
            cls.AUTO_STERILIZE_WEEK_MAX,
        )

    @classmethod
    def clamp_hour(cls, value: object) -> int:
        """Clamp auto sterilize hour for writes."""
        return cls._clamp_int(
            value,
            cls.AUTO_STERILIZE_HOUR_MIN,
            cls.AUTO_STERILIZE_HOUR_MAX,
        )

    @classmethod
    def clamp_minute(cls, value: object) -> int:
        """Clamp auto sterilize minute for writes."""
        return cls._clamp_int(
            value,
            cls.AUTO_STERILIZE_MINUTE_MIN,
            cls.AUTO_STERILIZE_MINUTE_MAX,
        )

    def __init__(self, protocol_version: int) -> None:
        """Initialize CD message set sterilize."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X06,
        )
        self.sterilize_on: bool = False
        self.week: int = 0
        self.hour: int = 0
        self.minute: int = 0
        # Appended only after the device reports extended protocol support.
        self.extended_body: bool = False
        self.disinfection_temperature: float | None = None

    @property
    def _body(self) -> bytearray:
        sterilize_effect = 0x80 if self.sterilize_on else 0x00
        body = bytearray(
            [
                0x01,  # bodyBytes[1] constant
                sterilize_effect,  # bodyBytes[2] sterilizeEffect
                self.clamp_week(self.week),  # bodyBytes[3] autoSterilizeWeek
                self.clamp_hour(self.hour),  # bodyBytes[4] autoSterilizeHour
                self.clamp_minute(self.minute),  # bodyBytes[5] autoSterilizeMinute
            ],
        )
        if self.extended_body:
            value = self.disinfection_temperature
            if not isinstance(value, int | float):
                value = self.DISINFECT_TEMP_MIN
            body.append(
                self._clamp_int(
                    value,
                    int(self.DISINFECT_TEMP_MIN),
                    int(self.DISINFECT_TEMP_MAX),
                ),
            )
        return body


class MessageSetMaintenance(MessageCDBase):
    """Set B0 function flags while preserving unrelated device flags."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize a NetHome-compatible B0 function control."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.B0,
        )
        self.ac_heater_priority = False
        self.high_temp_reminder = False
        self.maintenance_reminder = False
        self.reserved_flags = 0

    @property
    def _body(self) -> bytearray:
        flags = self.reserved_flags & 0x18
        flags |= 0x01 if self.ac_heater_priority else 0x00
        flags |= 0x02 if self.high_temp_reminder else 0x00
        flags |= 0x04 if self.maintenance_reminder else 0x00
        body = bytearray([0x01, B1_FUNCTION_FLAGS_TAG, 0x00, 0x01, flags])
        crc_source = bytearray([BODY_TYPE_B0]) + body
        body.append(calculate(crc_source))
        return body


class MessageSetWeekly(MessageCDBase):
    """CD weekly control message (controlType=0x07).

    Sends 7-day x 6-slot weekly schedule, plus day-0 high bits:
      - bit 0x40: maintenance reminder tag
      - bit 0x80: maintenance warning status (preserved)
    """

    def __init__(self, protocol_version: int) -> None:
        """Initialize CD message set weekly."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X07,
        )
        self.weekly_schedule: WeeklySchedule | None = None
        self.maintenance_reminder: bool = False
        self.maintenance_warn: bool = False

    @property
    def _body(self) -> bytearray:
        # bodyBytes[1] constant + bodyBytes[2..8] day effect bytes +
        # bodyBytes[9..176] 7x6 slot data (opentime, closetime, temperature, mode)
        body = bytearray([0x01] + [0x00] * 175)
        _effect_masks = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20]
        schedule = self.weekly_schedule or {}

        for day in range(7):
            slots = schedule.get(day, [])
            effects = 0
            for timer in range(6):
                slot = slots[timer] if timer < len(slots) else {}
                if slot.get("effect", False):
                    effects |= _effect_masks[timer]
                offset = 8 + day * 24 + timer * 4
                body[offset] = int(slot.get("opentime", 0)) & 0xFF
                body[offset + 1] = int(slot.get("closetime", 0)) & 0xFF
                body[offset + 2] = int(slot.get("temperature", 0)) & 0xFF
                body[offset + 3] = int(slot.get("mode", 0)) & 0xFF
            if day == 0:
                if self.maintenance_reminder:
                    effects |= 0x40
                if self.maintenance_warn:
                    effects |= 0x80
            body[1 + day] = effects

        return body


class MessageSetDaily(MessageCDBase):
    """Set the six-slot NetHome daily timer programme (control type 0x02)."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize a daily timer control."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X02,
        )
        self.daily_timer_schedule: DailyTimerSchedule | None = None

    @property
    def _body(self) -> bytearray:
        schedule = self.daily_timer_schedule or {}
        timers = schedule.get("timers", [])
        body = bytearray([0x01, int(schedule.get("amount", 0)) & 0xFF, 0x00])
        body.extend([0x00] * 36)
        effects = 0
        for index in range(6):
            timer = timers[index] if index < len(timers) else {}
            if timer.get("effect", False):
                effects |= 1 << index
            offset = 3 + index * 6
            body[offset] = int(timer.get("openhour", 0)) & 0xFF
            body[offset + 1] = int(timer.get("openmin", 0)) & 0xFF
            body[offset + 2] = int(timer.get("closehour", 0)) & 0xFF
            body[offset + 3] = int(timer.get("closemin", 0)) & 0xFF
            body[offset + 4] = int(timer.get("temperature", 0)) & 0xFF
            body[offset + 5] = int(timer.get("mode", 0)) & 0xFF
        if schedule.get("single_timer_on", False):
            effects |= 0x40
        if schedule.get("single_timer_off", False):
            effects |= 0x80
        body[2] = effects
        return body


class CDGeneralMessageBody(MessageBody):
    """CD message general body."""

    def __init__(self, body: bytearray) -> None:  # noqa: C901, PLR0915
        """Initialize CD message general body."""
        super().__init__(body)
        self.power = (body[2] & 0x01) > 0
        # Initialize mode to None (0x00) by default
        self.mode = 0x00
        # initialize disinfect to False by default (legacy bit7 is not used)
        self.disinfect = False
        # energyMode
        if (body[2] & 0x02) > 0:
            self.mode = 0x01
        # standardMode
        elif (body[2] & 0x04) > 0:
            self.mode = 0x02
        # compatibilizingMode
        elif (body[2] & 0x08) > 0:
            self.mode = 0x03
        # heatValue
        self.heat = body[2] & 0x10
        # dicaryonHeat
        self.dual_heat = body[2] & 0x20
        # eco
        self.eco = (body[2] & 0x40) > 0
        # tsValue (generic target)
        self.target_temperature = float(body[3])
        # washBoxTemp
        self.current_temperature = float(body[4])
        # boxTopTemp
        self.top_temperature = float(body[5])
        # boxBottomTemp
        self.bottom_temperature = float(body[6])
        # t3Value
        self.condenser_temperature = float(body[7])
        # t4Value
        self.outdoor_temperature = float(body[8])
        # compressorTopTemp
        self.compressor_temperature = float(body[9])
        # tsMaxValue
        self.max_temperature = float(body[10])
        # tsMinValue
        self.min_temperature = float(body[11])
        # errorCode
        self.error_code = body[20]
        # bottomElecHeat
        self.bottom_elec_heat = (body[27] & 0x01) > 0
        # topElecHeat
        self.top_elec_heat = (body[27] & 0x02) > 0
        # waterPump
        self.water_pump = (body[27] & 0x04) > 0
        # compressor
        self.compressor_status = (body[27] & 0x08) > 0
        # middleWind
        if (body[27] & 0x10) > 0:
            self.wind = "middle"
        # lowWind
        if (body[27] & 0x40) > 0:
            self.wind = "low"
        # highWind
        if (body[27] & 0x80) > 0:
            self.wind = "high"
        # fourWayValve
        self.four_way = (body[27] & 0x20) > 0
        # elecHeatSupport
        self.elec_heat = (body[28] & 0x01) > 0
        # order1Effect - 预约1是否生效 (reservation/schedule 1 active)
        self.order1_effect = (body[28] & 0x08) > 0
        # order2Effect - 预约2是否生效 (reservation/schedule 2 active)
        self.order2_effect = (body[28] & 0x10) > 0
        # smartMode - standard flag
        smart_flag = (body[28] & 0x20) > 0
        if smart_flag:
            self.mode = 0x04
        # backwaterEffect
        self.back_water = (body[28] & 0x40) > 0
        # sterilizeEffect: body[62] bit 0 (real-device status analysis shows
        # body[28] & 0x80 = 0x87 is constant across all messages regardless of
        # sterilize state and therefore cannot be the sterilize indicator).
        self.sterilize = (
            (body[STATUS_DISINFECT_FLAGS_INDEX] & 0x01) > 0
            if len(body) > STATUS_DISINFECT_FLAGS_INDEX
            else False
        )
        self.disinfect = self.sterilize
        self.typeinfo = body[29]
        # Conservative fallback: if no other mode flags and typeinfo==0x04,
        # treat as Smart
        if (
            not smart_flag and self.mode == 0x00 and self.typeinfo == 0x04  # noqa: PLR2004
        ):
            self.mode = 0x04
        self.support_heat_pump_mode = (
            body[STATUS_SUPPORT_HEAT_PUMP_INDEX] == 0x01
            if len(body) > STATUS_SUPPORT_HEAT_PUMP_INDEX
            else None
        )
        self.support_smart_mode = (
            body[STATUS_SUPPORT_SMART_INDEX] == 0x01
            if len(body) > STATUS_SUPPORT_SMART_INDEX
            else None
        )
        self.support_negative_temperature = (
            body[STATUS_SUPPORT_NEGATIVE_INDEX] == 0x01
            if len(body) > STATUS_SUPPORT_NEGATIVE_INDEX
            else None
        )
        extended_support_indices = (
            STATUS_SUPPORT_HEAT_PUMP_INDEX,
            STATUS_SUPPORT_SMART_INDEX,
            STATUS_SUPPORT_NEGATIVE_INDEX,
            STATUS_MAX_TEMP_UPPER_INDEX,
            STATUS_MAX_TEMP_LOWER_INDEX,
            STATUS_DISINFECT_TEMP_UPPER_INDEX,
            STATUS_DISINFECT_TEMP_LOWER_INDEX,
            STATUS_CAPABILITY_FLAGS_INDEX,
        )
        has_extended_support = any(
            len(body) > index and body[index] > 0 for index in extended_support_indices
        )
        extended_mode_flags = (
            body[STATUS_EXTENDED_MODE_FLAGS_INDEX]
            if has_extended_support and len(body) > STATUS_EXTENDED_MODE_FLAGS_INDEX
            else 0
        )
        self.holiday_mode = (extended_mode_flags & 0x01) > 0
        self.hybrid_motion_mode = (extended_mode_flags & 0x02) > 0
        if self.mode == 0x00:
            if (extended_mode_flags & 0x04) > 0:
                self.mode = 0x05
            elif (extended_mode_flags & 0x08) > 0:
                self.mode = 0x04
            elif (extended_mode_flags & 0x10) > 0:
                self.mode = 0x09
            elif (extended_mode_flags & 0x20) > 0:
                self.mode = 0x0A
        # hotWater
        # Gate on the actual index read (body[34]) rather than
        # OLD_BODY_LENGTH (29), which previously allowed bodies of length
        # 30-34 through and raised IndexError.
        self.water_level = body[34] if len(body) > 34 else None  # noqa: PLR2004
        # vacationMode - bit 0 of messageBytes[35] (body[35])
        self.vacation_mode = False
        self.vacation_days = 0
        if len(body) > NEW_BODY_LENGTH and (body[35] & 0x01) > 0:
            self.mode = 0x05
            self.vacation_mode = True
            # vacation days are stored in body[36:37] (big-endian)
            if len(body) > 37:  # noqa: PLR2004
                self.vacation_days = (body[36] << 8) | body[37]
        # smartGrid - bit 1 of messageBytes[35] (body[35])
        self.smart_grid = (
            ((body[35] & 0x02) > 0) if len(body) > NEW_BODY_LENGTH else False
        )
        # multiTerminal - bit 2 of messageBytes[35] (body[35])
        self.multi_terminal = (
            ((body[35] & 0x04) > 0) if len(body) > NEW_BODY_LENGTH else False
        )
        # fahrenheitEffect - bit 7 of messageBytes[35] (body[35])
        self.fahrenheit = (
            ((body[35] & 0x80) > 0) if len(body) > NEW_BODY_LENGTH else False
        )
        # Week timer effects from main status body[38-44]:
        # body[38] bits 0x01-0x20: week0 (Sunday) timers 1-6
        # body[39] bits 0x01-0x20: week1 (Monday) timers 1-6
        # body[40] bits 0x01-0x20: week2 (Tuesday) timers 1-6
        # body[41] bits 0x01-0x20: week3 (Wednesday) timers 1-6
        # body[42] bits 0x01-0x20: week4 (Thursday) timers 1-6
        # body[43] bits 0x01-0x20: week5 (Friday) timers 1-6
        # body[44] bits 0x01-0x20: week6 (Saturday) timers 1-6
        # Note: body[38] bits 0x40/0x80 are maintain_warn_tag/maintain_warn
        #       body[39] bits 0x40/0x80 are mute_effect/mute_status
        _effect_masks = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20]
        self.weekly_effects: dict | None = (
            {day: [(body[38 + day] & m) > 0 for m in _effect_masks] for day in range(7)}
            if len(body) > 44  # noqa: PLR2004
            else None
        )
        # maintain_warn_tag (messageBytes[38] bit 0x40) - requires body length > 38
        self.maintain_warn_tag = (
            ((body[38] & 0x40) > 0) if len(body) > 38 else False  # noqa: PLR2004
        )
        # Alias with official-app naming
        self.maintenance_reminder = self.maintain_warn_tag
        # maintain_warn (messageBytes[38] bit 0x80) - requires body length > 38
        self.maintain_warn = (
            ((body[38] & 0x80) > 0) if len(body) > 38 else False  # noqa: PLR2004
        )
        # mute_effect (messageBytes[39]) - requires body length > 39
        self.mute_effect = (
            ((body[39] & 0x40) > 0) if len(body) > 39 else False  # noqa: PLR2004
        )
        # mute_status (messageBytes[39]) - requires body length > 39
        self.mute_status = (
            ((body[39] & 0x80) > 0) if len(body) > 39 else False  # noqa: PLR2004
        )
        # autoSterilizeWeek (messageBytes[45]) - requires body length > 45.
        # Read exactly what the device reports; sanitize only when writing.
        raw_week = body[45] if len(body) > EXTENDED_BODY_LENGTH else None
        self.auto_sterilize_week: int | None = raw_week
        # autoSterilizeHour (messageBytes[46]) - requires body length > 46
        raw_hour = body[46] if len(body) > 46 else None  # noqa: PLR2004
        self.auto_sterilize_hour = raw_hour
        # autoSterilizeMinute (messageBytes[47]) - requires body length > 47
        raw_minute = body[47] if len(body) > 47 else None  # noqa: PLR2004
        self.auto_sterilize_minute = raw_minute
        # vacadaysStartYearValue (messageBytes[48]) - requires body length > 48
        self.vacation_start_year = (
            body[48] if len(body) > 48 else None  # noqa: PLR2004
        )
        # vacadaysStartMonthValue (messageBytes[49]) - requires body length > 49
        self.vacation_start_month = (
            body[49] if len(body) > 49 else None  # noqa: PLR2004
        )
        # vacadaysStartDayValue (messageBytes[50]) - requires body length > 50
        self.vacation_start_day = (
            body[50] if len(body) > 50 else None  # noqa: PLR2004
        )
        # vacationTsValue (messageBytes[51]) - read-only exposed diagnostic.
        self.vacation_temperature = (
            float(body[51]) if len(body) > 51 else None  # noqa: PLR2004
        )
        # Disinfection temperature: body[61] holds the sterilization setpoint in
        # direct °C (real-device analysis: 0x46=70, 0x41=65, 0x3c=60).
        # Stored regardless of whether sterilize is currently active so that the
        # set-point is preserved even when the function is turned off.
        self.disinfection_temperature: float | None = None
        if len(body) > STATUS_DISINFECT_TEMP_INDEX:
            raw_dt = float(body[STATUS_DISINFECT_TEMP_INDEX])
            if (
                MessageSetSterilize.DISINFECT_TEMP_MIN
                <= raw_dt
                <= MessageSetSterilize.DISINFECT_TEMP_MAX
            ):
                self.disinfection_temperature = raw_dt
            # Defensive fallback for malformed status frames observed from
            # thermostat UI toggles: body[61] can be out-of-range while body[45]
            # carries a valid celsius x2 temperature (120..140 even).
            elif (
                raw_week is not None
                and int(MessageSetSterilize.DISINFECT_TEMP_MIN * 2)
                <= raw_week
                <= int(MessageSetSterilize.DISINFECT_TEMP_MAX * 2)
                and raw_week % 2 == 0
            ):
                self.disinfection_temperature = raw_week / 2.0

        self.schedule_mode = (
            body[STATUS_SCHEDULE_MODE_INDEX]
            if len(body) > STATUS_SCHEDULE_MODE_INDEX
            else None
        )
        self.max_temperature_upper_limit = (
            float(body[STATUS_MAX_TEMP_UPPER_INDEX])
            if len(body) > STATUS_MAX_TEMP_UPPER_INDEX
            else None
        )
        self.max_temperature_lower_limit = (
            float(body[STATUS_MAX_TEMP_LOWER_INDEX])
            if len(body) > STATUS_MAX_TEMP_LOWER_INDEX
            else None
        )
        self.disinfection_temperature_upper_limit = (
            float(body[STATUS_DISINFECT_TEMP_UPPER_INDEX])
            if len(body) > STATUS_DISINFECT_TEMP_UPPER_INDEX
            else None
        )
        self.disinfection_temperature_lower_limit = (
            float(body[STATUS_DISINFECT_TEMP_LOWER_INDEX])
            if len(body) > STATUS_DISINFECT_TEMP_LOWER_INDEX
            else None
        )
        self.auto_disinfect = (
            (body[STATUS_DISINFECT_FLAGS_INDEX] & 0x02) > 0
            if len(body) > STATUS_DISINFECT_FLAGS_INDEX
            else None
        )
        self.dr_enable = (
            body[STATUS_DR_ENABLE_INDEX] > 0
            if len(body) > STATUS_DR_ENABLE_INDEX
            else None
        )
        self.dr_option = (
            body[STATUS_DR_OPTION_INDEX] if len(body) > STATUS_DR_OPTION_INDEX else None
        )
        self.electric_rod_exception = (
            (body[STATUS_ELECTRIC_ROD_EXCEPTION_INDEX] & 0x01) > 0
            if len(body) > STATUS_ELECTRIC_ROD_EXCEPTION_INDEX
            else None
        )
        capability_flags = (
            body[STATUS_CAPABILITY_FLAGS_INDEX]
            if len(body) > STATUS_CAPABILITY_FLAGS_INDEX
            else None
        )
        self.support_boost_mode = self._capability(capability_flags, 0x01)
        self.support_silent_mode = self._capability(capability_flags, 0x02)
        self.support_remaining_hot_water = self._capability(
            capability_flags,
            0x04,
        )
        self.support_electric_mode = self._capability(capability_flags, 0x08)
        self.support_auto_disinfect = self._capability(capability_flags, 0x10)
        self.support_force_e_heating = self._capability(capability_flags, 0x20)
        self.support_tou = self._capability(capability_flags, 0x40)
        self.remaining_hot_water_max = (
            body[STATUS_REMAINING_WATER_MAX_INDEX]
            if len(body) > STATUS_REMAINING_WATER_MAX_INDEX
            else None
        )
        self.force_e_heating_status = (
            body[STATUS_FORCE_E_HEATING_INDEX]
            if len(body) > STATUS_FORCE_E_HEATING_INDEX
            else None
        )

    @staticmethod
    def _capability(flags: int | None, mask: int) -> bool | None:
        """Decode a capability bit without inventing support on short frames."""
        return (flags & mask) > 0 if flags is not None else None


class CDB1MessageBody(MessageBody):
    """Parse the official B1 TLV capability and function response."""

    def __init__(self, body: bytearray) -> None:
        """Initialize a B1 response, ignoring malformed or failed TLVs."""
        super().__init__(body)
        index = B1_FIRST_TLV_LENGTH_INDEX
        while index < len(body):
            length = body[index]
            data_start = index + 1
            data_end = data_start + length
            if length == 0 or data_end > len(body):
                break
            result = body[index - 3]
            group = body[index - 2]
            tag = body[index - 1]
            if result == 0 and group == 0:
                self._set_tlv(tag, body[data_start:data_end])
            index += length + 4

    def _set_tlv(self, tag: int, data: bytearray) -> None:
        """Apply one successful B1 TLV."""
        value = data[0]
        if tag == B1_FUNCTION_FLAGS_TAG:
            self.ac_heater_priority = (value & 0x01) > 0
            self.high_temp_reminder = (value & 0x02) > 0
            self.maintenance_reminder = (value & 0x04) > 0
            self.b0_reserved_flags = value & 0x18
        elif tag == B1_NEW_VERSION_TAG:
            self.new_version_water_heater = value == 0x01
        elif tag == B1_HOLIDAY_MAX_TAG:
            self.holiday_max = value * 5
        elif tag == B1_HOLIDAY_MIN_TAG:
            self.holiday_min = value
        elif tag == B1_TIMER_STEP_TAG:
            self.timer_step_gap = value
        elif tag == B1_AC_HEATER_SUPPORT_TAG:
            self.support_ac_heater_priority = (value & 0x01) > 0
        elif tag == B1_HEAT_RECOVERY_TAG:
            self.support_heat_recovery = value != 0
            self.heat_recovery_status = value == B1_HEAT_RECOVERY_ACTIVE


class CDWeeklyScheduleBody(MessageBody):
    """CD message weekly schedule body (body_type=0x02, queryType=0x02).

    Contains the full 7-day x 6-slot timer programme.
    Layout (per Lua T_0000_CD_RSJRAC01_2023070401.lua):
      body[2..8] : effect bits for days 0-6 (6 timers per byte, bits 0x01-0x20)
      body[9..]  : slot data in order day0/slot1..slot6, day1/slot1..slot6, ...
                   each slot = 4 bytes: opentime, closetime, settemperature, modevalue

    weekly_schedule keys: day index 0 (Sunday) .. 6 (Saturday)
    Each day is a list of 6 dicts (timer slots 1-6) with fields:
      effect       : bool
      opentime     : int (raw byte, hour*4 + min//15 or similar device encoding)
      closetime    : int
      temperature  : int
      mode         : int (0x01=energy,0x02=standard,0x03=compatibilizing,0x04=smart)
    """

    def __init__(self, body: bytearray) -> None:
        """Initialize CD message weekly schedule body."""
        super().__init__(body)
        self.weekly_schedule: WeeklySchedule | None = None
        if len(body) > WEEKLY_SCHEDULE_BODY_LENGTH:
            _effect_masks = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20]
            schedule: WeeklySchedule = {}
            for day in range(7):
                slots: list[WeeklyTimer] = []
                effects_byte = body[2 + day]
                for timer in range(6):
                    offset = 9 + day * 24 + timer * 4
                    slots.append(
                        {
                            "effect": (effects_byte & _effect_masks[timer]) > 0,
                            "opentime": body[offset],
                            "closetime": body[offset + 1],
                            "temperature": body[offset + 2],
                            "mode": body[offset + 3],
                        },
                    )
                schedule[day] = slots
            self.weekly_schedule = schedule


class CDDailyTimerBody(MessageBody):
    """CD message daily timer body (body_type=0x03, queryType=0x03).

    Contains the 6-slot daily timer programme.
    Layout (per Lua T_0000_CD_RSJRAC01_2023070401.lua):
      body[2]  : timer_amount (number of active slots)
      body[3]  : effect bits + single-timer flags
                   bits 0x01-0x20 = timer 1-6 effects
                   bit  0x40      = single_timer_on
                   bit  0x80      = single_timer_off
      body[4+] : slot data, 6 bytes each
                   openhour, openmin, closehour, closemin, settemperature, modevalue

    daily_timer_schedule structure:
      {
        "amount"          : int,
        "single_timer_on" : bool,
        "single_timer_off": bool,
        "timers": [          # list of 6 slots (index 0 = timer 1)
          {
            "effect"     : bool,
            "openhour"   : int,
            "openmin"    : int,
            "closehour"  : int,
            "closemin"   : int,
            "temperature": int,
            "mode"       : int,
          },
          ...
        ]
      }
    """

    def __init__(self, body: bytearray) -> None:
        """Initialize CD message daily timer body."""
        super().__init__(body)
        self.daily_timer_schedule: DailyTimerSchedule | None = None
        if len(body) > DAILY_TIMER_BODY_LENGTH:
            _effect_masks = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20]
            timers: list[DailyTimer] = []
            for slot in range(6):
                base = 4 + slot * 6
                timers.append(
                    {
                        "effect": (body[3] & _effect_masks[slot]) > 0,
                        "openhour": body[base],
                        "openmin": body[base + 1],
                        "closehour": body[base + 2],
                        "closemin": body[base + 3],
                        "temperature": body[base + 4],
                        "mode": body[base + 5],
                    },
                )
            self.daily_timer_schedule = {
                "amount": body[2],
                "single_timer_on": (body[3] & 0x40) > 0,
                "single_timer_off": (body[3] & 0x80) > 0,
                "timers": timers,
            }


class CD01MessageBody(MessageBody):
    """CD message set 01 body (controlType=0x01 SET response echo)."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CD message set 01 body."""
        super().__init__(body)
        self.fields: dict[Any, Any] = {}
        self.power = (body[2] & 0x01) > 0
        self.mode = body[3]
        self.target_temperature = float(body[4])
        self.fields["trValue"] = body[5]
        self.fields["openPTC"] = body[6]
        self.fields["ptcTemp"] = body[7]
        self.fields["byte8"] = body[8]
        # vacation_mode: bit 0x10 of bodyBytes[8]
        self.vacation_mode = (body[8] & 0x10) > 0
        # vacation_days:
        # bodyBytes[9..10] big-endian when an extended body is echoed.
        if len(body) > 10:  # noqa: PLR2004
            self.vacation_days = (body[9] << 8) | body[10]
        else:
            self.vacation_days = 0


class CDSterilizeSetBody(MessageBody):
    """CD message set sterilize body (controlType=0x06 SET response echo).

    Parsed when the device echoes back the sterilize SET command.
    Layout (per Lua binToModel controlType=0x06):
      body[2] bit 0x80 = sterilizeEffect (ON/OFF)
      body[3]          = autoSterilizeWeek (weekday on some
                          firmwares; celsius x2 disinfection temperature on
                          others - e.g. 134 -> 67 C)
      body[4]          = autoSterilizeHour
      body[5]          = autoSterilizeMinute
    """

    def __init__(self, body: bytearray) -> None:
        """Initialize CD message set sterilize body."""
        super().__init__(body)
        sterilize_on = (body[2] & 0x80) > 0
        # Map to both sterilize and disinfect attributes (same underlying feature)
        self.sterilize = sterilize_on
        self.disinfect = sterilize_on
        raw_byte3 = body[3] if len(body) > 3 else None  # noqa: PLR2004
        raw_hour = body[4] if len(body) > 4 else None  # noqa: PLR2004
        raw_minute = body[5] if len(body) > 5 else None  # noqa: PLR2004
        self.auto_sterilize_week = raw_byte3
        self.auto_sterilize_hour = raw_hour
        self.auto_sterilize_minute = raw_minute
        self.disinfection_temperature: float | None = None
        # Extended NetHome payloads carry direct °C in body[6].
        if len(body) > 6:  # noqa: PLR2004
            extended_temperature = float(body[6])
            if (
                MessageSetSterilize.DISINFECT_TEMP_MIN
                <= extended_temperature
                <= MessageSetSterilize.DISINFECT_TEMP_MAX
            ):
                self.disinfection_temperature = extended_temperature
                return

        # body[3] is ambiguous: some legacy firmwares echo celsius x2 disinfection
        # temperature, others echo autoSterilizeWeek.
        #
        # Real devices can encode temperature 60°C as 120 (<=127), so "value
        # >127 means temperature" is incorrect. We treat body[3] as
        # temperature when it lies in the exact encoded app range [120, 140]
        # and is even (x2 encoding), otherwise as week.
        temp_raw_min = int(MessageSetSterilize.DISINFECT_TEMP_MIN * 2)
        temp_raw_max = int(MessageSetSterilize.DISINFECT_TEMP_MAX * 2)
        if (
            raw_byte3 is not None
            and temp_raw_min <= raw_byte3 <= temp_raw_max
            and raw_byte3 % 2 == 0
        ):
            # Temperature echo: decode celsius x2. Keep auto_sterilize_week raw.
            decoded = raw_byte3 / 2.0
            if (
                MessageSetSterilize.DISINFECT_TEMP_MIN
                <= decoded
                <= MessageSetSterilize.DISINFECT_TEMP_MAX
            ):
                self.disinfection_temperature = decoded


class MessageCDResponse(MessageResponse):
    """CD message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize CD message response."""
        super().__init__(bytearray(message))
        # parse query/notify response message
        if self.message_type in [MessageType.query, MessageType.notify2]:
            if self.body_type == BODY_TYPE_GENERAL:
                self.set_body(CDGeneralMessageBody(super().body))
            elif self.body_type == BODY_TYPE_WEEKLY:
                # weekly schedule query response (queryType=0x02)
                self.set_body(CDWeeklyScheduleBody(super().body))
            elif self.body_type == BODY_TYPE_DAILY:
                # daily timer query response (queryType=0x03)
                self.set_body(CDDailyTimerBody(super().body))
            elif self.body_type == BODY_TYPE_B1:
                self.set_body(CDB1MessageBody(super().body))
        elif self.message_type == MessageType.set:
            if self.body_type == BODY_TYPE_GENERAL:
                # controlType=0x01 SET response echo
                self.set_body(CD01MessageBody(super().body))
            elif self.body_type == BODY_TYPE_STERILIZE:
                # controlType=0x06 sterilize SET response echo
                self.set_body(CDSterilizeSetBody(super().body))
        self.set_attr()
