"""Midea local ED message."""

from enum import IntEnum

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

TEA_BAR_SUBTYPE = 395
TEA_BAR_CURRENT_TEMPERATURE_OFFSET = 3
TEA_BAR_TARGET_TEMPERATURE_OFFSET = 10
TEA_BAR_HEATING_FLAG_OFFSET = 49
TEA_BAR_STATUS_FLAG_OFFSET = 51
TEA_BAR_KEEP_WARM_TIME_OFFSET = 33
TEA_BAR_KEEP_WARM_REMAINING_LOW_OFFSET = 34
TEA_BAR_KEEP_WARM_REMAINING_HIGH_OFFSET = 35
TEA_BAR_KEEP_WARM_FLAG_OFFSET = 48
TEA_BAR_COOLING_STATUS_OFFSET = 50
TEA_BAR_HEATING_FLAG = 0x01
TEA_BAR_KEEP_WARM_FLAG = 0x01
TEA_BAR_SLEEP_FLAG = 0x80
TEA_BAR_STATUS_LACK_WATER_FLAG = 0x02
TEA_BAR_STATUS_HEATING_FLAG = 0x04
TEA_BAR_STATUS_HOT_WATER_FLAG = 0x40
TEA_BAR_STATUS_STANDBY_FLAG = 0x80
TEA_BAR_STATUS_DISPENSING_MASK = 0x50
TEA_BAR_ERROR_OFFSET = 52


class Attributes(IntEnum):
    """Attributes."""

    CHILD_LOCK = 0x000
    LIFE = 0x10
    TDS = 0x013
    WATER_CONSUMPTION = 0x011
    # Soft water machine attributes for FF body
    VELOCITY = 0x020
    SOFT_AVAILABLE = 0x021
    LEFT_SALT = 0x022
    LEAK_WATER_PROTECTION_VALUE = 0x023
    REMAINING_DAYS = 0x024
    WATER_HARDNESS = 0x025
    FLUSHING_DAYS = 0x026
    TIMING_REGENERATION = 0x027
    REGENERATION_LEFT_SECONDS = 0x028
    USE_DAYS = 0x029
    SALT_SETTING = 0x030
    SOFT_AVAILABLE_BIG = 0x031
    WATER_CONSUMPTION_BIG = 0x032
    WATER_CONSUMPTION_AVERAGE = 0x033
    SOFTEN_SWITCH = 0x040
    CL_STERILIZATION_SWITCH = 0x041
    LEAK_WATER_PROTECTION_SWITCH = 0x042
    LEAK_WATER_STATUS = 0x043
    WATER_WAY_SWITCH = 0x044
    RSJ_STAND_BY = 0x045
    REGENERATION_SWITCH = 0x047
    ERROR = 0x048


class NewSetTags(IntEnum):
    """New set tags."""

    power = 0x0100
    lock = 0x0201
    # Soft water machine new set tags (matching Lua setbytes commands)
    # pack() generates [param&0xFF, param>>8, value, add&0xFF, add>>8]
    # which maps to setbytes(item1, item2, item3, item4, item5)
    # so param = (item2 << 8) | item1
    water_hardness = 0x0100  # setbytes(0x00, 0x01, ...)
    flushing_days = 0x0101  # setbytes(0x01, 0x01, ...)
    timing_regeneration = 0x0102  # setbytes(0x02, 0x01, ...)
    regeneration = 0x0103  # setbytes(0x03, 0x01, ...)
    salt_setting = 0x0104  # setbytes(0x04, 0x01, ...)
    soften = 0x0108  # setbytes(0x08, 0x01, ...)
    cl_sterilization = 0x0109  # setbytes(0x09, 0x01, ...)
    leak_water_protection = 0x010A  # setbytes(0x0A, 0x01, ...)
    water_way = 0x0200  # setbytes(0x00, 0x02, ...)
    tea_bar_target_temperature = 0x0401
    tea_bar_heat_start = 0x0405
    tea_bar_keep_warm = 0x0408
    tea_bar_sleep = 0x0104  # Intentional alias: same wire tag as salt_setting.
    tea_bar_cooling = 0x0500


class EDNewSetParamPack:
    """ED new set parameter pack."""

    @staticmethod
    def pack(param: int, value: int, addition: int = 0) -> bytearray:
        """Pack parameter."""
        # Ensure int type for bitwise operations (callers may pass float from HA)
        param = int(param)
        value = int(value)
        addition = int(addition)
        return bytearray(
            [param & 0xFF, param >> 8, value, addition & 0xFF, addition >> 8],
        )


class MessageEDBase(MessageRequest):
    """ED message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes = ListTypes.X00,
    ) -> None:
        """Initialize ED message base."""
        super().__init__(
            device_type=DeviceType.ED,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageEDBase):
    """ED message query."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X00,
    ) -> None:
        """Initialize ED message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQuery01(MessageEDBase):
    """ED message query01."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X01,
    ) -> None:
        """Initialize ED message query01."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQuery03(MessageEDBase):
    """ED message query03."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X03,
    ) -> None:
        """Initialize ED message query03."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQuery04(MessageEDBase):
    """ED message query04."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X04,
    ) -> None:
        """Initialize ED message query04."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQuery05(MessageEDBase):
    """ED message query05."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X05,
    ) -> None:
        """Initialize ED message query05."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQuery06(MessageEDBase):
    """ED message query06."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X06,
    ) -> None:
        """Initialize ED message query06."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQuery07(MessageEDBase):
    """ED message query07."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X07,
    ) -> None:
        """Initialize ED message query07."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQuery09(MessageEDBase):
    """ED message query09 (soft water machine)."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X09,
    ) -> None:
        """Initialize ED message query09."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageQueryFF(MessageEDBase):
    """ED message queryFF."""

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.FF,
    ) -> None:
        """Initialize ED message queryFF."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageNewSet(MessageEDBase):
    """ED message new set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize ED message new set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X15,
        )
        self.power: bool | None = None
        self.lock: bool | None = None
        # Soft water machine controls
        self.water_hardness: int | None = None
        self.flushing_days: int | None = None
        self.timing_regeneration_hour: int | None = None
        self.timing_regeneration_min: int | None = None
        self.regeneration: bool | None = None
        self.salt_setting: int | None = None
        self.soften: bool | None = None
        self.cl_sterilization: bool | None = None
        self.leak_water_protection: bool | None = None
        self.leak_water_protection_value: int | None = None
        self.water_way: bool | None = None
        # Tea bar controls from the official ED Lua encoder.
        self.target_temperature: int | None = None
        self.heating: bool | None = None
        self.keep_warm: bool | None = None
        self.keep_warm_time: int | None = None
        self.sleep: bool | None = None
        self.cooling: bool | None = None

    @property
    def _body(self) -> bytearray:
        pack_count = 0
        payload = bytearray([0x01, 0x00])
        if self.power is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.power,
                    value=0x01 if self.power else 0x00,
                ),
            )
        if self.lock is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.lock,
                    value=0x01 if self.lock else 0x00,
                ),
            )
        # Soft water machine controls
        if self.water_hardness is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.water_hardness,
                    value=0x00,
                    addition=self.water_hardness,
                ),
            )
        if self.flushing_days is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.flushing_days,
                    value=0x00,
                    addition=self.flushing_days,
                ),
            )
        if (
            self.timing_regeneration_hour is not None
            or self.timing_regeneration_min is not None
        ):
            pack_count += 1
            # Lua setbytes(0x02, 0x01, 0x00, hour, min): addition = (min << 8) | hour
            hour = (
                self.timing_regeneration_hour
                if self.timing_regeneration_hour is not None
                else 0
            )
            minute = (
                self.timing_regeneration_min
                if self.timing_regeneration_min is not None
                else 0
            )
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.timing_regeneration,
                    value=0x00,
                    addition=(minute << 8) | hour,
                ),
            )
        if self.regeneration is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.regeneration,
                    value=0x01 if self.regeneration else 0x00,
                ),
            )
        if self.salt_setting is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.salt_setting,
                    value=0x00,
                    addition=self.salt_setting,
                ),
            )
        if self.soften is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.soften,
                    value=0x01 if self.soften else 0x00,
                ),
            )
        if self.cl_sterilization is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.cl_sterilization,
                    value=0x01 if self.cl_sterilization else 0x00,
                ),
            )
        if self.leak_water_protection is not None:
            pack_count += 1
            addition = (
                self.leak_water_protection_value // 10
                if self.leak_water_protection_value is not None
                else 0
            )
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.leak_water_protection,
                    value=0x01 if self.leak_water_protection else 0x00,
                    addition=addition,
                ),
            )
        if self.water_way is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.water_way,
                    value=0x01 if self.water_way else 0x00,
                ),
            )
        if self.target_temperature is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.tea_bar_target_temperature,
                    value=self.target_temperature,
                    addition=0x0A,
                ),
            )
        if self.heating is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.tea_bar_heat_start,
                    value=0x01 if self.heating else 0x00,
                ),
            )
        if self.keep_warm is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.tea_bar_keep_warm,
                    value=0x01 if self.keep_warm else 0x00,
                    addition=self.keep_warm_time or 0,
                ),
            )
        if self.sleep is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.tea_bar_sleep,
                    value=0x01 if self.sleep else 0x00,
                ),
            )
        if self.cooling is not None:
            pack_count += 1
            payload.extend(
                EDNewSetParamPack.pack(
                    param=NewSetTags.tea_bar_cooling,
                    value=0x01 if self.cooling else 0x00,
                ),
            )
        payload[1] = pack_count
        return payload


class MessageOldSet(MessageEDBase):
    """ED message old set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize ED message old set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
        )

    @property
    def body(self) -> bytearray:
        """ED message old set body."""
        return bytearray([])

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class EDMessageBody01(MessageBody):
    """ED message body 01."""

    def __init__(self, body: bytearray) -> None:
        """Initialize ED message body 01."""
        super().__init__(body)
        self.power = (body[2] & 0x01) > 0
        self.water_consumption = body[7] + (body[8] << 8)
        self.in_tds = body[36] + (body[37] << 8)
        self.out_tds = body[38] + (body[39] << 8)
        self.child_lock = body[15] > 0
        self.filter1 = round((body[25] + (body[26] << 8)) / 24)
        self.filter2 = round((body[27] + (body[28] << 8)) / 24)
        self.filter3 = round((body[29] + (body[30] << 8)) / 24)
        self.life1 = body[16]
        self.life2 = body[17]
        self.life3 = body[18]


class EDMessageBody03(MessageBody):
    """ED message body 03."""

    def __init__(self, body: bytearray) -> None:
        """Initialize ED message body 03."""
        super().__init__(body)
        self.power = (body[51] & 0x01) > 0
        self.child_lock = (body[51] & 0x08) > 0
        self.water_consumption = body[20] + (body[21] << 8)
        self.life1 = body[22]
        self.life2 = body[23]
        self.life3 = body[24]
        self.in_tds = body[27] + (body[28] << 8)
        self.out_tds = body[29] + (body[30] << 8)


class EDMessageBody05(MessageBody):
    """ED message body 05."""

    def __init__(self, body: bytearray) -> None:
        """Initialize ED message body 05."""
        super().__init__(body)
        self.power = (body[51] & 0x01) > 0
        self.child_lock = (body[51] & 0x08) > 0
        self.water_consumption = body[20] + (body[21] << 8)


class EDMessageBody06(MessageBody):
    """ED message body 06."""

    def __init__(self, body: bytearray, subtype: int = 0) -> None:
        """Initialize ED message body 06."""
        super().__init__(body)
        self.power = (body[51] & 0x01) > 0
        self.child_lock = (body[51] & 0x08) > 0
        self.water_consumption = body[25] + (body[26] << 8)
        if subtype == TEA_BAR_SUBTYPE:
            self.current_temperature = body[TEA_BAR_CURRENT_TEMPERATURE_OFFSET]
            self.target_temperature = body[TEA_BAR_TARGET_TEMPERATURE_OFFSET] or None
            self.heating = (
                body[TEA_BAR_HEATING_FLAG_OFFSET] == TEA_BAR_HEATING_FLAG
                and body[TEA_BAR_STATUS_FLAG_OFFSET] & TEA_BAR_STATUS_HEATING_FLAG > 0
            )
            self.dispensing = (
                body[TEA_BAR_STATUS_FLAG_OFFSET] & TEA_BAR_STATUS_DISPENSING_MASK
                == TEA_BAR_STATUS_DISPENSING_MASK
            )
            self.keep_warm = (
                body[TEA_BAR_KEEP_WARM_FLAG_OFFSET] & TEA_BAR_KEEP_WARM_FLAG > 0
            )
            self.sleep = body[TEA_BAR_KEEP_WARM_FLAG_OFFSET] & TEA_BAR_SLEEP_FLAG > 0
            self.screen_display = not self.sleep
            self.cooling = body[TEA_BAR_COOLING_STATUS_OFFSET] != 0
            self.lack_water = (
                body[TEA_BAR_STATUS_FLAG_OFFSET] & TEA_BAR_STATUS_LACK_WATER_FLAG > 0
            )
            self.standby = (
                body[TEA_BAR_STATUS_FLAG_OFFSET] & TEA_BAR_STATUS_STANDBY_FLAG > 0
            )
            self.hot_water_dispensing = (
                body[TEA_BAR_STATUS_FLAG_OFFSET] & TEA_BAR_STATUS_HOT_WATER_FLAG > 0
            )
            self.fault_code = body[TEA_BAR_ERROR_OFFSET]
            self.fault = self.fault_code != 0
            raw_keep_warm_time = body[TEA_BAR_KEEP_WARM_TIME_OFFSET]
            self.keep_warm_time = raw_keep_warm_time / 2 if raw_keep_warm_time else None
            self.keep_warm_remaining = body[TEA_BAR_KEEP_WARM_REMAINING_LOW_OFFSET] + (
                body[TEA_BAR_KEEP_WARM_REMAINING_HIGH_OFFSET] << 8
            )


class EDMessageBody07(MessageBody):
    """ED message body 07."""

    def __init__(self, body: bytearray) -> None:
        """Initialize ED message body 07."""
        super().__init__(body)
        self.water_consumption = (body[21] << 8) + body[20]
        self.power = (body[51] & 0x01) > 0
        self.child_lock = (body[51] & 0x08) > 0


class EDMessageBody09(MessageBody):
    """ED message body 09 (soft water machine)."""

    # Byte offsets in body (after protocol header removal)
    # Based on Lua T_0000_ED_6360000A_2023080201.formatted.lua
    OFFSET_VELOCITY = 2
    OFFSET_SOFT_AVAILABLE = 3  # 2-byte: byte3+byte4 (little-endian)
    OFFSET_WATER_CONSUMPTION = 5  # 2-byte: byte5+byte6 (little-endian)
    OFFSET_LEFT_SALT = 7
    OFFSET_LEAK_WATER_PROTECTION_VALUE = 8
    OFFSET_REMAINING_DAYS = 9  # 2-byte: byte9+byte10 (little-endian)
    OFFSET_WATER_HARDNESS = 11  # 2-byte: byte11+byte12 (little-endian)
    OFFSET_FLUSHING_DAYS = 13
    OFFSET_TIMING_REGENERATION_HOUR = 14
    OFFSET_TIMING_REGENERATION_MIN = 15
    OFFSET_REGENERATION_LEFT_SECONDS = 16  # 2-byte: byte16+byte17 (little-endian)
    OFFSET_USE_DAYS = 18  # 2-byte: byte18+byte19 (little-endian)
    OFFSET_SALT_SETTING = 20
    OFFSET_SOFT_AVAILABLE_BIG = 21  # 4-byte: byte31-byte34 (little-endian)
    OFFSET_WATER_CONSUMPTION_BIG = 25  # 4-byte: byte35-byte38 (little-endian)
    OFFSET_WATER_CONSUMPTION_AVERAGE = 33  # 2-byte: byte43+byte44 (little-endian)
    OFFSET_SWITCH_BYTE = 51  # byte61 in Lua = body[51] (byte flags)
    OFFSET_ERROR = 52  # byte62 in Lua = body[52]

    @staticmethod
    def _read_u16(body: bytearray, offset: int) -> int:
        """Read 2-byte little-endian unsigned int at offset."""
        return body[offset] + (body[offset + 1] << 8)

    @staticmethod
    def _read_u32(body: bytearray, offset: int) -> int:
        """Read 4-byte little-endian unsigned int at offset."""
        return (
            body[offset]
            + (body[offset + 1] << 8)
            + (body[offset + 2] << 16)
            + (body[offset + 3] << 24)
        )

    def __init__(self, body: bytearray) -> None:
        """Initialize ED message body 09 (soft water machine)."""
        super().__init__(body)
        self.velocity = body[self.OFFSET_VELOCITY]
        self.soft_available = self._read_u16(body, self.OFFSET_SOFT_AVAILABLE)
        self.water_consumption = self._read_u16(body, self.OFFSET_WATER_CONSUMPTION)
        self.left_salt = body[self.OFFSET_LEFT_SALT]
        self.leak_water_protection_value = (
            body[self.OFFSET_LEAK_WATER_PROTECTION_VALUE] * 10
        )
        self.remaining_days = self._read_u16(body, self.OFFSET_REMAINING_DAYS)
        self.water_hardness = self._read_u16(body, self.OFFSET_WATER_HARDNESS)
        self.flushing_days = body[self.OFFSET_FLUSHING_DAYS]
        self.timing_regeneration_hour = body[self.OFFSET_TIMING_REGENERATION_HOUR]
        self.timing_regeneration_min = body[self.OFFSET_TIMING_REGENERATION_MIN]
        self.regeneration_left_seconds = self._read_u16(
            body,
            self.OFFSET_REGENERATION_LEFT_SECONDS,
        )
        self.use_days = self._read_u16(body, self.OFFSET_USE_DAYS)
        self.salt_setting = body[self.OFFSET_SALT_SETTING]
        self.soft_available_big = self._read_u32(
            body,
            self.OFFSET_SOFT_AVAILABLE_BIG,
        )
        self.water_consumption_big = (
            self._read_u32(body, self.OFFSET_WATER_CONSUMPTION_BIG) / 100
        )
        self.water_consumption_average = self._read_u16(
            body,
            self.OFFSET_WATER_CONSUMPTION_AVERAGE,
        )
        # Switch byte flags (byte61 in Lua mapping)
        switch_byte = body[self.OFFSET_SWITCH_BYTE]
        self.soften = (switch_byte & 0x01) > 0
        self.cl_sterilization = (switch_byte & 0x02) > 0
        self.leak_water_protection = (switch_byte & 0x04) > 0
        self.leak_water = (switch_byte & 0x08) > 0
        self.water_way = (switch_byte & 0x10) > 0
        self.rsj_stand_by = (switch_byte & 0x20) > 0
        self.regeneration = (switch_byte & 0x80) > 0
        self.error = body[self.OFFSET_ERROR]


class EDMessageBodyFF(MessageBody):
    """ED message body FF."""

    def __init__(self, body: bytearray) -> None:
        """Initialize ED message body FF."""
        super().__init__(body)
        data_offset = 2
        while True:
            length = (body[data_offset + 2] >> 4) + 2
            attr = ((body[data_offset + 2] % 16) << 8) + body[data_offset + 1]
            if attr == Attributes.CHILD_LOCK:
                self.child_lock = (body[data_offset + 5] & 0x01) > 0
                self.power = (body[data_offset + 6] & 0x01) > 0
            elif attr == Attributes.WATER_CONSUMPTION:
                self.water_consumption = (
                    float(
                        body[data_offset + 3]
                        + (body[data_offset + 4] << 8)
                        + (body[data_offset + 5] << 16)
                        + (body[data_offset + 6] << 24),
                    )
                    / 1000
                )
            elif attr == Attributes.TDS:
                self.in_tds = body[data_offset + 3] + (body[data_offset + 4] << 8)
                self.out_tds = body[data_offset + 5] + (body[data_offset + 6] << 8)
            elif attr == Attributes.LIFE:
                self.life1 = body[data_offset + 3]
                self.life2 = body[data_offset + 4]
                self.life3 = body[data_offset + 5]
            # fix index out of range error
            if data_offset + length + 6 > len(body):
                break
            data_offset += length


class MessageEDResponse(MessageResponse):
    """ED message response."""

    def __init__(self, message: bytes, subtype: int = 0) -> None:
        """Initialize ED message response."""
        super().__init__(bytearray(message))
        if self._message_type in [
            MessageType.set,
            MessageType.query,
            MessageType.notify1,
        ]:
            self.device_class = self._body_type
            if self._body_type in [ListTypes.X00, ListTypes.FF]:
                self.set_body(EDMessageBodyFF(super().body))
            elif self._body_type == ListTypes.X15 and subtype == TEA_BAR_SUBTYPE:
                # Subtype 395 can return either a full body-06 style status
                # acknowledgement or a short X15 acknowledgement. Only convert
                # the full status form because EDMessageBody06 reads body[52].
                status_body = bytearray(super().body)
                if len(status_body) > TEA_BAR_ERROR_OFFSET:
                    status_body[0] = ListTypes.X06
                    self.set_body(EDMessageBody06(status_body, subtype))
            elif self.body_type == ListTypes.X01:
                self.set_body(EDMessageBody01(super().body))
            elif self.body_type in [ListTypes.X03, ListTypes.X04]:
                self.set_body(EDMessageBody03(super().body))
            elif self.body_type == ListTypes.X05:
                self.set_body(EDMessageBody05(super().body))
            elif self.body_type == ListTypes.X06:
                self.set_body(EDMessageBody06(super().body, subtype))
            elif self.body_type == ListTypes.X07:
                self.set_body(EDMessageBody07(super().body))
            elif self.body_type == ListTypes.X09:
                self.set_body(EDMessageBody09(super().body))
        self.set_attr()
