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
    """CD message query."""

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
        if (
            self.message_type in [MessageType.query, MessageType.notify2]
            and self.body_type == 0x01
        ):
            self.set_body(CDGeneralMessageBody(super().body))
        # parse set message with body_type 0x01
        elif self.message_type == MessageType.set and self.body_type == 0x01:
            self.set_body(CD01MessageBody(super().body))
        self.set_attr()
