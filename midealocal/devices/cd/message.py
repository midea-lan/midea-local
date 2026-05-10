"""Midea local CD message."""

from typing import Any

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

OLD_BODY_LENGTH = 29  # T_0000_CD_3.lua body length 29
NEW_BODY_LENGTH = 35  # T_0000_CD_000K86A2_3 body length 34
EXTENDED_BODY_LENGTH = 45  # T_0000_CD_RSJRAC01_2023070401.lua extended body (auto_sterilize)

# Weekly schedule body: 7 days x 6 slots x 4 fields starting at body[9]
# body[9..176]: slot layout is {opentime, closetime, settemperature, modevalue}
WEEKLY_SCHEDULE_BODY_LENGTH = 176
# Daily timer body: 6 slots x 6 fields starting at body[4] (2 control bytes + effects byte)
DAILY_TIMER_BODY_LENGTH = 39


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
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x02, 0x01])


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
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x03, 0x01])


class MessageSet(MessageCDBase):
    """CD message set (controlType=0x01).

    Builds a 22-byte body matching the Lua jsonToData controlType=0x01 layout:
      bodyBytes[0]     = 0x01 (body_type, prepended by MessageRequest.body)
      bodyBytes[1]     = 0x01 (constant, _body[0])
      bodyBytes[2]     = powerValue
      bodyBytes[3]     = modeValue  (0x01-0x04; vacation is NOT a mode value here)
      bodyBytes[4]     = tsValue    (target temperature, encoded per protocol)
      bodyBytes[5]     = trValue
      bodyBytes[6]     = openPTC
      bodyBytes[7]     = ptcTemp
      bodyBytes[8]     = flags: bit 0x10=vacationMode, bit 0x80=fahrenheit, bit 0x08=mute
                         (built from scratch per Lua L5621-5623; other bits are NOT sent)
      bodyBytes[9..10] = vacadaysValue high/low (vacation remaining days, big-endian)
      bodyBytes[11..17]= date/time fields (sent as 0)
      bodyBytes[18..20]= vacation start year/month/day (sent as 0)
      bodyBytes[21]    = vacationTsValue (vacation target temperature, raw)
    """

    DEFAULT_VACATION_DAYS = 100

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
        # vacation target temperature (bodyBytes[21], raw device value)
        self.vacation_temperature: float = 0

    def read_field(self, field: str) -> int:
        """CD message set read field."""
        value = self.fields.get(field, 0)
        return int(value) if value else 0

    @property
    def _body(self) -> bytearray:
        power = 0x01 if self.power else 0x00
        mode = self.mode
        # new protocol sends raw value, old protocol doubles and adds offset
        target_temperature = (
            round(self.target_temperature * 2 + 30)
            if self.use_old_protocol
            else round(self.target_temperature)
        )
        # Build byte8 from scratch per Lua L5621-5623:
        #   only vacationMode (0x10), fahrenheitEffect (0x80), mute (0x08)
        # All other bits (waterPump, defrost, openPTCTemp, etc.) are NOT sent,
        # matching the Lua app behaviour which also leaves them out.
        byte8 = 0
        if self.vacation_flag:
            byte8 |= 0x10
        if self.fahrenheit:
            byte8 |= 0x80
        byte8 |= self.read_field("byte8") & 0x08  # preserve mute bit only
        vacation_high = (self.vacation_days >> 8) & 0xFF
        vacation_low = self.vacation_days & 0xFF
        return bytearray(
            [
                0x01,  # bodyBytes[1] constant
                power,  # bodyBytes[2] powerValue
                mode,  # bodyBytes[3] modeValue (0x01-0x04)
                int(target_temperature),  # bodyBytes[4] tsValue
                self.read_field("trValue"),  # bodyBytes[5]
                self.read_field("openPTC"),  # bodyBytes[6]
                self.read_field("ptcTemp"),  # bodyBytes[7]
                byte8,  # bodyBytes[8] flags (vacation|fahrenheit|mute only)
                vacation_high,  # bodyBytes[9] vacadaysValue high
                vacation_low,  # bodyBytes[10] vacadaysValue low
                0,  # bodyBytes[11] dateYearValue high
                0,  # bodyBytes[12] dateYearValue low
                0,  # bodyBytes[13] dateMonthValue
                0,  # bodyBytes[14] dateDayValue
                0,  # bodyBytes[15] dateWeekValue
                0,  # bodyBytes[16] dateHourValue
                0,  # bodyBytes[17] dateMinuteValue
                0,  # bodyBytes[18] vacadaysStartYearValue
                0,  # bodyBytes[19] vacadaysStartMonthValue
                0,  # bodyBytes[20] vacadaysStartDayValue
                int(self.vacation_temperature),  # bodyBytes[21] vacationTsValue
            ],
        )


class MessageSetSterilize(MessageCDBase):
    """CD message set sterilize (controlType=0x06).

    Controls the sterilization/disinfect function.
    Lua jsonToData controlType=0x06 layout:
      bodyBytes[0] = 0x06 (body_type, prepended by MessageRequest.body)
      bodyBytes[1] = 0x01 (constant, _body[0])
      bodyBytes[2] = sterilizeEffect  (0x80=ON, 0x00=OFF)
      bodyBytes[3] = autoSterilizeWeek OR disinfection temperature (°C×2)
      bodyBytes[4] = autoSterilizeHour
      bodyBytes[5] = autoSterilizeMinute

    bodyBytes[3] is dual-use depending on firmware:
    - Some firmwares treat it as a weekday value/bitmap (autoSterilizeWeek).
    - Others treat it as a disinfection-temperature setpoint encoded as °C×2
      (e.g. 67 °C → 134).

    When ``disinfection_temperature`` is set, bodyBytes[3] is encoded as
    ``int(disinfection_temperature * 2)``; otherwise the ``week`` bitmap is sent.

    Note: the device echoes back the disinfection temperature (°C×2) in bodyBytes[3]
    of the SET response.  That echo is decoded by ``CDSterilizeSetBody``.
    """

    # Valid range for disinfection temperature (°C)
    DISINFECT_TEMP_MIN: float = 60.0
    DISINFECT_TEMP_MAX: float = 70.0

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
        # When set, overrides week in bodyBytes[3] with the celsius×2 encoding.
        self.disinfection_temperature: float | None = None

    @property
    def _body(self) -> bytearray:
        sterilize_effect = 0x80 if self.sterilize_on else 0x00
        # Use celsius×2 encoding when an explicit disinfection temperature is given;
        # fall back to the autoSterilizeWeek bitmap otherwise.
        if self.disinfection_temperature is not None:
            byte3 = int(self.disinfection_temperature * 2)
        else:
            byte3 = self.week
        return bytearray(
            [
                0x01,  # bodyBytes[1] constant
                sterilize_effect,  # bodyBytes[2] sterilizeEffect
                byte3,  # bodyBytes[3] disinfection temp (°C×2) or weekday bitmap
                self.hour,  # bodyBytes[4] autoSterilizeHour
                self.minute,  # bodyBytes[5] autoSterilizeMinute
            ],
        )


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
        self.weekly_schedule: dict[int, list[dict[str, Any]]] | None = None
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


class CDGeneralMessageBody(MessageBody):
    """CD message general body."""

    def __init__(self, body: bytearray) -> None:
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
        self.sterilize = (body[62] & 0x01) > 0 if len(body) > 62 else False  # noqa: PLR2004
        self.disinfect = self.sterilize
        self.typeinfo = body[29]
        # Conservative fallback: if no other mode flags and typeinfo==0x04,
        # treat as Smart
        if (
            not smart_flag and self.mode == 0x00 and self.typeinfo == 0x04  # noqa: PLR2004
        ):
            self.mode = 0x04
        # hotWater
        self.water_level = body[34] if len(body) > OLD_BODY_LENGTH else None
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
            {
                day: [(body[38 + day] & m) > 0 for m in _effect_masks]
                for day in range(7)
            }
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
        # autoSterilizeWeek (messageBytes[45]) - requires body length > 45
        self.auto_sterilize_week = (
            body[45] if len(body) > EXTENDED_BODY_LENGTH else None
        )
        # autoSterilizeHour (messageBytes[46]) - requires body length > 46
        self.auto_sterilize_hour = (
            body[46] if len(body) > 46 else None  # noqa: PLR2004
        )
        # autoSterilizeMinute (messageBytes[47]) - requires body length > 47
        self.auto_sterilize_minute = (
            body[47] if len(body) > 47 else None  # noqa: PLR2004
        )
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
        # vacationTsValue (messageBytes[51]) - requires body length > 51
        self.vacation_temperature = (
            float(body[51]) if len(body) > 51 else None  # noqa: PLR2004
        )
        # Disinfection temperature: body[61] holds the sterilization setpoint in
        # direct °C (real-device analysis: 0x46=70, 0x41=65, 0x3c=60).
        # Stored regardless of whether sterilize is currently active so that the
        # set-point is preserved even when the function is turned off.
        self.disinfection_temperature: float | None = None
        if len(body) > 61:  # noqa: PLR2004
            raw_dt = float(body[61])
            if (
                MessageSetSterilize.DISINFECT_TEMP_MIN
                <= raw_dt
                <= MessageSetSterilize.DISINFECT_TEMP_MAX
            ):
                self.disinfection_temperature = raw_dt


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
        self.weekly_schedule: dict | None = None
        if len(body) > WEEKLY_SCHEDULE_BODY_LENGTH:
            _effect_masks = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20]
            schedule: dict = {}
            for day in range(7):
                slots = []
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
        self.daily_timer_schedule: dict | None = None
        if len(body) > DAILY_TIMER_BODY_LENGTH:
            _effect_masks = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20]
            timers = []
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
        # vacation_days: bodyBytes[9..10] big-endian (present when extended body is echoed)
        if len(body) > 10:  # noqa: PLR2004
            self.vacation_days = (body[9] << 8) | body[10]
        else:
            self.vacation_days = 0


class CDSterilizeSetBody(MessageBody):
    """CD message set sterilize body (controlType=0x06 SET response echo).

    Parsed when the device echoes back the sterilize SET command.
    Layout (per Lua binToModel controlType=0x06):
      body[2] bit 0x80 = sterilizeEffect (ON/OFF)
      body[3]          = autoSterilizeWeek (week-schedule bitmap on some
                          firmwares; celsius×2 disinfection temperature on
                          others – e.g. 134 → 67 °C)
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
        self.auto_sterilize_hour = body[4] if len(body) > 4 else None  # noqa: PLR2004
        self.auto_sterilize_minute = body[5] if len(body) > 5 else None  # noqa: PLR2004
        # body[3] is ambiguous: some firmwares echo celsius×2 disinfection
        # temperature, others echo autoSterilizeWeek.
        #
        # Real devices can encode temperature 60°C as 120 (<=127), so "value
        # >127 means temperature" is incorrect. We treat body[3] as
        # temperature when it lies in the exact encoded app range [120, 140]
        # and is even (x2 encoding), otherwise as week.
        self.disinfection_temperature: float | None = None
        temp_raw_min = int(MessageSetSterilize.DISINFECT_TEMP_MIN * 2)
        temp_raw_max = int(MessageSetSterilize.DISINFECT_TEMP_MAX * 2)
        if (
            raw_byte3 is not None
            and temp_raw_min <= raw_byte3 <= temp_raw_max
            and raw_byte3 % 2 == 0
        ):
            # Temperature echo: decode celsius×2. Do NOT overwrite week.
            self.auto_sterilize_week: int | None = None
            decoded = raw_byte3 / 2.0
            if (
                MessageSetSterilize.DISINFECT_TEMP_MIN
                <= decoded
                <= MessageSetSterilize.DISINFECT_TEMP_MAX
            ):
                self.disinfection_temperature = decoded
        else:
            # Not an encoded temperature: treat as autoSterilizeWeek payload.
            self.auto_sterilize_week = raw_byte3


class MessageCDResponse(MessageResponse):
    """CD message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize CD message response."""
        super().__init__(bytearray(message))
        # parse query/notify response message
        if self.message_type in [MessageType.query, MessageType.notify2]:
            if self.body_type == 0x01:
                self.set_body(CDGeneralMessageBody(super().body))
            elif self.body_type == 0x02:
                # weekly schedule query response (queryType=0x02)
                self.set_body(CDWeeklyScheduleBody(super().body))
            elif self.body_type == 0x03:
                # daily timer query response (queryType=0x03)
                self.set_body(CDDailyTimerBody(super().body))
        elif self.message_type == MessageType.set:
            if self.body_type == 0x01:
                # controlType=0x01 SET response echo
                self.set_body(CD01MessageBody(super().body))
            elif self.body_type == 0x06:
                # controlType=0x06 sterilize SET response echo
                self.set_body(CDSterilizeSetBody(super().body))
        self.set_attr()
