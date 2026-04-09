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
    """CD message set."""

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
        return bytearray(
            [
                0x01,  # byte1
                power,  # byte2
                mode,  # byte3
                int(target_temperature),  # byte4
                self.read_field("trValue"),  # byte5
                self.read_field("openPTC"),  # byte6
                self.read_field("ptcTemp"),  # byte7
                self.read_field("byte8"),  # byte8 (flags)
            ],
        )


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
        # sterilizeEffect
        self.sterilize = (body[28] & 0x80) > 0
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
        # Disinfection set temperature (distinct from generic target)
        # Some firmwares encode disinfection setpoint near the tail with
        # marker 0x3c followed by Celsius value.
        self.disinfection_set_temperature: float | None = None
        disinfect_marker = 0x3C
        min_temp = 25
        max_temp = 90
        try:
            tail_flag_index = None
            # Search backwards for marker 0x3c followed by a plausible
            # Celsius value (25..90)
            for i in range(len(body) - 2, max(len(body) - 10, 0), -1):
                if body[i] == disinfect_marker:
                    val = body[i + 1]
                    if min_temp <= val <= max_temp:
                        self.disinfection_set_temperature = float(val)
                        # tail flag appears at i+2 in provided samples
                        # (0x01 on, 0x00 off)
                        if i + 2 < len(body):
                            tail_flag_index = i + 2
                        break
            # Use tail flag to set disinfect when present
            if tail_flag_index is not None:
                tail_flag = body[tail_flag_index]
                if tail_flag in (0x00, 0x01):
                    self.disinfect = tail_flag == 0x01
        except (IndexError, ValueError):
            # Be conservative: leave None on any parsing issue
            self.disinfection_set_temperature = None


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
    """CD message set 01 body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CD message set 01 body."""
        super().__init__(body)
        self.fields = {}
        self.power = (body[2] & 0x01) > 0
        self.mode = body[3]
        self.target_temperature = float(body[4])
        self.fields["trValue"] = body[5]
        self.fields["openPTC"] = body[6]
        self.fields["ptcTemp"] = body[7]
        self.fields["byte8"] = body[8]


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
        # parse set message with body_type 0x01
        elif self.message_type == MessageType.set and self.body_type == 0x01:
            self.set_body(CD01MessageBody(super().body))
        self.set_attr()
