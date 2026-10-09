"""Midea local BF message."""

from enum import IntEnum

from midealocal.const import MAX_BYTE_VALUE, DeviceType
from midealocal.message import (
    BoolParser,
    IntParser,
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
    TimeParser,
    WordParser,
)

# Body type constants
BODY_TYPE_TOTAL_STATE = 0x01

# workModeControl bodyBytes[4]: totalstep/stepnum nibble. This library only
# builds single-step cooking commands (Lua's singleCooking, not multistageCooking).
TOTALSTEP_SINGLE_STEP = 0x11

# Byte offsets in MessageBFBody (body[0] is body_type, data starts at body[1])
OFFSET_EXECUTE = 1
OFFSET_CLOUDMENUID = 2  # 3 bytes, big-endian
OFFSET_TOTALSTEP_STEPNUM = 5
OFFSET_FLAGS_B6 = 6
OFFSET_WORK_MODE_HIGH = 7
OFFSET_WORK_MODE_LOW = 8
OFFSET_HOUR_SET = 9
OFFSET_MINUTE_SET = 10
OFFSET_SECOND_SET = 11
OFFSET_FIRE_POWER = 12
OFFSET_TEMP_ABOVE = 13  # 16-bit words below are big-endian
OFFSET_TEMP_UNDERSIDE = 15
OFFSET_PROBE_TEMP = 17
OFFSET_STEAM_QUANTITY = 19
OFFSET_WEIGHT_PEOPLE = 20
OFFSET_WORK_HOUR = 22
OFFSET_WORK_MINUTE = 23
OFFSET_WORK_SECOND = 24
OFFSET_CUR_TEMP_ABOVE = 25
OFFSET_CUR_TEMP_UNDERSIDE = 27
OFFSET_CUR_PROBE_TEMP = 29
OFFSET_WORK_STATUS = 31
OFFSET_FLAGS_B32 = 32
OFFSET_FLAGS_B33 = 33
OFFSET_RAMADAN = 34
OFFSET_HOT_WIND = 35
OFFSET_CBS_VERSION_MAJOR = 47
OFFSET_CBS_VERSION_MINOR = 48
OFFSET_CBS_VERSION_PATCH = 49
OFFSET_FLAGS_B56 = 56
OFFSET_FLAGS_B58 = 58

# Bit masks (response parsing, byte 32)
BIT_PREHEAT = 0x20
BIT_PREHEAT_END = 0x40

# Bit masks (workModeControl set body, byte b5)
BIT_SET_PRE_HEAT = 0x01
BIT_SET_PROBE = 0x02
BIT_SET_TURNTABLE = 0x08
BIT_SET_HOT_WIND = 0x10

# setControl parameter IDs
PARAM_ID_STEAM = 0x00
PARAM_ID_TIME = 0x01
PARAM_ID_FIRE_POWER = 0x02
PARAM_ID_TEMP = 0x03
PARAM_ID_PROBE_TEMP = 0x04
PARAM_ID_TEMP_ABOVE_UNDERSIDE = 0x05

# setControl temp_above/underside sub-index
SUBINDEX_ABOVE = 0x00
SUBINDEX_UNDERSIDE = 0x01

# Special byte values
BYTE_FF = 0xFF
BYTE_POWER_ON = 0x11
BYTE_POWER_OFF = 0x01
BYTE_LOCK_ON = 0x01
BYTE_LOCK_OFF = 0x00
BYTE_LIGHT_ON = 0x01
BYTE_LIGHT_OFF = 0x00
BYTE_DOOR_OPEN = 0x01
BYTE_DOOR_CLOSE = 0x00
BYTE_HOT_WIND_ON = 0x01
BYTE_HOT_WIND_OFF = 0x00

# Weight conversion factor (device sends weight/10)
WEIGHT_DIVISOR = 10

# Time conversion factors
MINUTES_PER_HOUR = 60


class WorkStatus(IntEnum):
    """BF work status."""

    save_power = 0x01
    standby = 0x02
    work = 0x03
    work_finish = 0x04
    order = 0x05
    pause = 0x06
    pause_c = 0x07
    three = 0x08
    wait_to_start = 0x10
    self_inspection = 0x0A
    query_version = 0x0B
    demo = 0x0C
    after_checking = 0x0E


class FirePower(IntEnum):
    """BF fire power."""

    fire_power_0 = 0x00
    fire_power_1 = 0x01
    fire_power_2 = 0x02
    fire_power_3 = 0x03
    fire_power_4 = 0x04
    fire_power_5 = 0x05
    fire_power_6 = 0x06
    fire_power_7 = 0x07
    fire_power_8 = 0x08
    fire_power_9 = 0x09
    fire_power_10 = 0x0A


# Work mode name <-> (high_byte, low_byte) mapping (from Lua workMode16/workMode)
WORK_MODE_MAP: dict[str, tuple[int, int]] = {
    "microwave": (0x01, 0x00),
    "microwave_1": (0x01, 0x01),
    "microwave_2": (0x01, 0x02),
    "microwave_3": (0x01, 0x03),
    "microwave_4": (0x01, 0x04),
    "microwave_5": (0x01, 0x05),
    "microwave_steam_above_tube": (0x02, 0x00),
    "microwave_double_tube": (0x03, 0x00),
    "microwave_hot_wind_tube_fan": (0x04, 0x00),
    "microwave_underside_tube_hot_wind_tube_fan": (0x05, 0x00),
    "microwave_double_tube_hot_wind_tube_fan": (0x06, 0x00),
    "microwave_steam": (0x07, 0x00),
    "microwave_steam_1": (0x07, 0x01),
    "unfreeze": (0x09, 0x00),
    "unfreeze_1": (0x09, 0x01),
    "unfreeze_2": (0x09, 0x02),
    "unfreeze_3": (0x09, 0x03),
    "unfreeze_t": (0x0A, 0x00),
    "microwave_above_tube": (0x0B, 0x00),
    "microwave_above_tube_1": (0x0B, 0x01),
    "microwave_above_tube_2": (0x0B, 0x02),
    "microwave_above_tube_fan": (0x0C, 0x00),
    "fast_unfreeze": (0x0D, 0x00),
    "fresh_unfreeze": (0x0E, 0x00),
    "microwave_zymosis": (0x0F, 0x00),
    "pure_steam": (0x29, 0x00),
    "pure_steam_1": (0x29, 0x01),
    "pure_steam_2": (0x29, 0x02),
    "pure_steam_3": (0x29, 0x03),
    "pure_steam_4": (0x29, 0x04),
    "pure_steam_5": (0x29, 0x05),
    "pure_steam_6": (0x29, 0x06),
    "pure_steam_7": (0x29, 0x07),
    "pure_steam_8": (0x29, 0x08),
    "pure_steam_9": (0x29, 0x09),
    "steam_above_tube": (0x2B, 0x00),
    "steam_underside_tube": (0x2C, 0x00),
    "steam_double_tube": (0x2D, 0x00),
    "steam_hot_wind_tube_fan": (0x2E, 0x00),
    "steam_hot_wind_tube_fan_1": (0x2E, 0x01),
    "steam_hot_wind_tube_fan_2": (0x2E, 0x02),
    "steam_hot_wind_tube": (0x2F, 0x00),
    "steam_double_tube_fan": (0x30, 0x00),
    "steam_above_inside_outside_tube_fan": (0x31, 0x00),
    "steam_above_inside_tube_fan": (0x32, 0x00),
    "above_tube": (0x51, 0x00),
    "underside_tube": (0x52, 0x00),
    "double_tube": (0x53, 0x00),
    "hot_wind_tube_fan": (0x54, 0x00),
    "pure_preheat": (0x55, 0x00),
    "above_tube_hot_wind_tube_fan": (0x56, 0x00),
    "underside_tube_hot_wind_tube_fan": (0x57, 0x00),
    "zymosis": (0x58, 0x00),
    "double_tube_hot_wind_tube_fan": (0x59, 0x00),
    "above_tube_revolve": (0x5A, 0x00),
    "underside_tube_revolve": (0x5B, 0x00),
    "double_tube_revolve": (0x5C, 0x00),
    "hot_wind_tube_fan_revolve": (0x5D, 0x00),
    "warm": (0x5E, 0x00),
    "double_tube_fan": (0x5F, 0x00),
    "double_tube_fan_1": (0x5F, 0x01),
    "double_tube_fan_2": (0x5F, 0x02),
    "double_tube_fan_3": (0x5F, 0x03),
    "above_inside_tube_revolve": (0x60, 0x00),
    "above_inside_tube_fan": (0x61, 0x00),
    "above_inside_outside_tube_revolve": (0x62, 0x00),
    "above_inside_outside_tube_fan": (0x63, 0x00),
    "above_inside_underside_tube": (0x64, 0x00),
    "above_inside_underside_tube_1": (0x64, 0x01),
    "above_inside_underside_tube_fan": (0x65, 0x00),
    "above_inside_underside_tube_fan_1": (0x65, 0x01),
    "above_inside_tube": (0x66, 0x00),
    "above_inside_outside_tube": (0x67, 0x00),
    "underside_tube_fan": (0x68, 0x00),
    "above_tube_fan": (0x69, 0x00),
    "above_tube_fan_1": (0x69, 0x01),
    "above_tube_fan_2": (0x69, 0x02),
    "scale_clean": (0x79, 0x00),
    "clean": (0x7A, 0x00),
    "remove_odor": (0x7B, 0x00),
    "remove_odor_2": (0x7B, 0x02),
    "high_temperature_clean": (0x7C, 0x00),
    "dining_utensils_clean": (0x7D, 0x00),
    "auto_menu": (0xA1, 0x00),
    "eco": (0xA2, 0x00),
    "above_tube_1": (0x51, 0x01),
    "above_tube_2": (0x51, 0x02),
    "above_tube_3": (0x51, 0x03),
    "underside_tube_1": (0x52, 0x01),
    "underside_tube_2": (0x52, 0x02),
    "double_tube_1": (0x53, 0x01),
    "double_tube_2": (0x53, 0x02),
    "double_tube_3": (0x53, 0x03),
    "double_tube_4": (0x53, 0x04),
    "double_tube_5": (0x53, 0x05),
    "double_tube_6": (0x53, 0x06),
    "hot_wind_tube_fan_1": (0x54, 0x01),
    "hot_wind_tube_fan_2": (0x54, 0x02),
    "hot_wind_tube_fan_3": (0x54, 0x03),
    "hot_wind_tube_fan_4": (0x54, 0x04),
    "hot_wind_tube_fan_5": (0x54, 0x05),
    "double_tube_hot_wind_tube_fan_1": (0x59, 0x01),
    "double_tube_hot_wind_tube_fan_2": (0x59, 0x02),
    "double_tube_hot_wind_tube_fan_3": (0x59, 0x03),
    "double_tube_hot_wind_tube_fan_4": (0x59, 0x04),
    "double_tube_hot_wind_tube_fan_5": (0x59, 0x05),
}

# Reverse map: (high, low) -> name
WORK_MODE_REVERSE: dict[tuple[int, int], str] = {v: k for k, v in WORK_MODE_MAP.items()}


def work_mode_to_bytes(mode: str | None) -> tuple[int, int]:
    """Convert work mode name to (high, low) bytes."""
    if mode is None:
        return (BYTE_FF, BYTE_FF)
    return WORK_MODE_MAP.get(mode, (BYTE_FF, BYTE_FF))


def work_mode_to_name(high: int, low: int) -> str:
    """Convert (high, low) bytes to work mode name."""
    return WORK_MODE_REVERSE.get((high, low), "unknown")


class MessageBFBase(MessageRequest):
    """BF message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize BF message base."""
        super().__init__(
            device_type=DeviceType.BF,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageBFBase):
    """BF message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize BF message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageSet(MessageBFBase):
    """BF message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize BF message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X02,
        )
        # Non-work mode controls (notWorkModeControl in Lua)
        self.power: bool | None = None
        self.work_status: str | None = None  # save_power/standby/work/pause
        self.child_lock: bool | None = None
        self.furnace_light: bool | None = None
        self.door: bool | None = None  # True=open, False=close
        self.screen_luminance: int | None = None
        self.volume: int | None = None
        self.hot_wind: bool | None = None
        # Work mode controls (workModeControl/singleCooking in Lua)
        self.work_mode: str | None = None
        self.work_hour: int | None = None
        self.work_minute: int | None = None
        self.work_second: int | None = None
        self.fire_power: str | None = None
        self.temperature: int | None = None
        self.temperature_above: int | None = None
        self.temperature_underside: int | None = None
        self.probe_temperature: int | None = None
        self.steam_quantity: int | None = None
        self.weight: int | None = None
        self.people_number: int | None = None
        self.pre_heat: bool | None = None
        self.turntable: bool | None = None
        # Set controls (setControl in Lua) - runtime parameter adjustments
        self.steam_set: int | None = None
        self.hour_set: int | None = None
        self.minute_set: int | None = None
        self.second_set: int | None = None
        self.fire_power_set: str | None = None
        self.temp_set: int | None = None
        self.probe_temp_set: int | None = None
        self.temp_above_set: int | None = None
        self.temp_underside_set: int | None = None

    @staticmethod
    def _fire_power_value(name: str | None) -> int:
        if name is None:
            return BYTE_FF
        try:
            return FirePower[name].value
        except KeyError:
            return BYTE_FF

    @staticmethod
    def _work_status_value(status: str | None) -> int:
        if status is None:
            return BYTE_FF
        try:
            return WorkStatus[status].value
        except KeyError:
            return BYTE_FF

    @property
    def body(self) -> bytearray:
        """Message body. Override to set body_type from control type."""
        content = self._body  # determines and sets self.body_type
        body = bytearray([])
        if self.body_type is not None:
            body.append(self.body_type)
        if content is not None:
            body.extend(content)
        return body

    @property
    def _body(self) -> bytearray:
        """Determine which control group to use based on set fields.

        Priority: work_mode > notWorkMode fields > setControl fields.
        body_type is dynamically set to match Lua's bodyBytes[0] control type.
        """
        if self.work_mode is not None:
            self.body_type = ListTypes.X01  # workModeControl
            return self._build_work_mode_control()
        not_work_mode_fields = [
            self.work_status,
            self.power,
            self.furnace_light,
            self.child_lock,
            self.door,
            self.hot_wind,
            self.screen_luminance,
            self.volume,
        ]
        if any(field is not None for field in not_work_mode_fields):
            self.body_type = ListTypes.X02  # notWorkModeControl
            return self._build_not_work_mode_control()
        # setControl: parameter adjustments during work
        set_control_fields = [
            self.steam_set,
            self.hour_set,
            self.minute_set,
            self.second_set,
            self.fire_power_set,
            self.temp_set,
            self.probe_temp_set,
            self.temp_above_set,
            self.temp_underside_set,
        ]
        if any(field is not None for field in set_control_fields):
            self.body_type = ListTypes.X03  # setControl
            return self._build_set_control()
        msg = "MessageSet has no control fields set"
        raise ValueError(msg)

    def _build_not_work_mode_control(self) -> bytearray:
        """Build notWorkModeControl body content (body_type=0x02 added by framework)."""
        power_byte = self._bool_to_byte(
            self.power,
            BYTE_POWER_ON,
            BYTE_POWER_OFF,
        )
        # work_status takes priority over power: when both are set, only work_status
        # byte is written (Lua writes statusByte = workStatus or powerByte).
        status_byte = (
            self._work_status_value(self.work_status)
            if self.work_status is not None
            else power_byte
        )
        lock_byte = self._bool_to_byte(
            self.child_lock,
            BYTE_LOCK_ON,
            BYTE_LOCK_OFF,
        )
        light_byte = self._bool_to_byte(
            self.furnace_light,
            BYTE_LIGHT_ON,
            BYTE_LIGHT_OFF,
        )
        door_byte = self._bool_to_byte(
            self.door,
            BYTE_DOOR_OPEN,
            BYTE_DOOR_CLOSE,
        )
        screen_byte = (
            self.screen_luminance & BYTE_FF
            if self.screen_luminance is not None
            else BYTE_FF
        )
        volume_byte = self.volume & BYTE_FF if self.volume is not None else BYTE_FF
        hot_wind_byte = self._bool_to_byte(
            self.hot_wind,
            BYTE_HOT_WIND_ON,
            BYTE_HOT_WIND_OFF,
        )
        # Lua bodyBytes[1..17] (bodyBytes[0]=0x02 is body_type, added by framework).
        # bodyBytes[16] is water_box in Lua's notWorkModeControl, not ramadan
        # (ramadan has no set path there; it's a read-only totalState flag).
        # water_box isn't exposed as a settable attribute yet, so it stays 0xFF.
        return bytearray(
            [
                status_byte,
                lock_byte,
                light_byte,
                BYTE_FF,
                door_byte,
                BYTE_FF,
                BYTE_FF,
                screen_byte,
                volume_byte,
                BYTE_FF,
                BYTE_FF,
                hot_wind_byte,
                BYTE_FF,
                BYTE_FF,
                BYTE_FF,
                BYTE_FF,
                BYTE_FF,
            ],
        )

    @staticmethod
    def _bool_to_byte(value: bool | None, true_val: int, false_val: int) -> int:
        """Convert optional bool to byte value."""
        if value is None:
            return BYTE_FF
        return {True: true_val, False: false_val}[value]

    def _build_work_mode_control(self) -> bytearray:
        """Build workModeControl/singleCooking body content (body_type=0x01 added by framework)."""  # noqa: E501
        # b5 flags: bit0=pre_heat, bit1=probe, bit3=turntable, bit4=hot_wind
        b5 = (
            (BIT_SET_PRE_HEAT if self.pre_heat is True else 0)
            | (BIT_SET_PROBE if self.probe_temperature is not None else 0)
            | (BIT_SET_TURNTABLE if self.turntable is True else 0)
            | (BIT_SET_HOT_WIND if self.hot_wind is True else 0)
        )

        mode_high, mode_low = work_mode_to_bytes(self.work_mode)

        work_hour = self.work_hour or 0x00
        work_minute = self.work_minute or 0x00
        work_second = self.work_second or 0x00
        fire_power_byte = self._fire_power_value(self.fire_power)

        # Temperature bytes
        temp_high = temp_low = 0x00
        temp_above_high = temp_above_low = 0x00
        temp_underside_high = temp_underside_low = 0x00

        if self.temperature is not None:
            temp_high = (self.temperature >> 8) & BYTE_FF
            temp_low = self.temperature & BYTE_FF
            temp_above_high = temp_high
            temp_above_low = temp_low
            temp_underside_high = temp_high
            temp_underside_low = temp_low
        if self.temperature_above is not None:
            temp_above_high = (self.temperature_above >> 8) & BYTE_FF
            temp_above_low = self.temperature_above & BYTE_FF
        if self.temperature_underside is not None:
            temp_underside_high = (self.temperature_underside >> 8) & BYTE_FF
            temp_underside_low = self.temperature_underside & BYTE_FF

        # Probe temperature
        probe_high = probe_low = 0x00
        if self.probe_temperature is not None:
            probe_high = (self.probe_temperature >> 8) & BYTE_FF
            probe_low = self.probe_temperature & BYTE_FF

        # Steam quantity
        steam_byte = self.steam_quantity if self.steam_quantity is not None else BYTE_FF

        # Weight / people number
        if self.weight is not None:
            weight_byte = (self.weight // WEIGHT_DIVISOR) & BYTE_FF
        elif self.people_number is not None:
            weight_byte = self.people_number & BYTE_FF
        else:
            weight_byte = BYTE_FF

        # Lua bodyBytes[1..21] (bodyBytes[0]=0x01 is body_type, added by framework)
        return bytearray(
            [
                0x00,  # bodyBytes[1] cloudmenuid high (unset)
                0x00,  # bodyBytes[2] cloudmenuid mid (unset)
                0x00,  # bodyBytes[3] cloudmenuid low (unset)
                TOTALSTEP_SINGLE_STEP,  # bodyBytes[4] totalstep=1, stepnum=1
                b5,  # bodyBytes[5] flags
                mode_high,  # bodyBytes[6] work mode high
                mode_low,  # bodyBytes[7] work mode low
                work_hour,  # bodyBytes[8]
                work_minute,  # bodyBytes[9]
                work_second,  # bodyBytes[10]
                fire_power_byte,  # bodyBytes[11]
                temp_above_high,  # bodyBytes[12]
                temp_above_low,  # bodyBytes[13]
                temp_underside_high,  # bodyBytes[14]
                temp_underside_low,  # bodyBytes[15]
                probe_high,  # bodyBytes[16]
                probe_low,  # bodyBytes[17]
                steam_byte,  # bodyBytes[18]
                weight_byte,  # bodyBytes[19]
                BYTE_FF,  # bodyBytes[20]
                0x00,  # bodyBytes[21]
            ],
        )

    def _build_set_control(self) -> bytearray:
        """Build setControl body content (body_type=0x03 added by framework)."""
        body = bytearray([0x01, 0x00])  # 0x01, paramSum placeholder
        param_sum = 0

        if self.steam_set is not None:
            body.append(PARAM_ID_STEAM)
            param_sum += 1
            body.append(self.steam_set & BYTE_FF)

        time_fields = [self.hour_set, self.minute_set, self.second_set]
        if any(f is not None for f in time_fields):
            body.append(PARAM_ID_TIME)
            body.extend(
                [
                    self.hour_set or 0x00,
                    self.minute_set or 0x00,
                    self.second_set or 0x00,
                ],
            )
            param_sum += 1

        if self.fire_power_set is not None:
            body.append(PARAM_ID_FIRE_POWER)
            param_sum += 1
            body.append(self._fire_power_value(self.fire_power_set))

        if self.temp_set is not None:
            temp_high = (self.temp_set >> 8) & BYTE_FF
            temp_low = self.temp_set & BYTE_FF
            body.append(PARAM_ID_TEMP)
            body.append(0x00)
            body.append(temp_high)
            body.append(temp_low)
            param_sum += 1

        if self.probe_temp_set is not None:
            temp_high = (self.probe_temp_set >> 8) & BYTE_FF
            temp_low = self.probe_temp_set & BYTE_FF
            body.append(PARAM_ID_PROBE_TEMP)
            body.append(0x00)
            body.append(temp_high)
            body.append(temp_low)
            param_sum += 1

        if self.temp_above_set is not None:
            temp_high = (self.temp_above_set >> 8) & BYTE_FF
            temp_low = self.temp_above_set & BYTE_FF
            body.append(PARAM_ID_TEMP_ABOVE_UNDERSIDE)
            body.append(0x00)
            body.append(0x00)
            body.append(SUBINDEX_ABOVE)
            body.append(temp_high)
            body.append(temp_low)
            param_sum += 1

        if self.temp_underside_set is not None:
            temp_high = (self.temp_underside_set >> 8) & BYTE_FF
            temp_low = self.temp_underside_set & BYTE_FF
            body.append(PARAM_ID_TEMP_ABOVE_UNDERSIDE)
            body.append(0x00)
            body.append(0x00)
            body.append(SUBINDEX_UNDERSIDE)
            body.append(temp_high)
            body.append(temp_low)
            param_sum += 1

        body[1] = param_sum
        return body


class MessageBFBody(MessageBody):
    """BF message body (totalState)."""

    # Set by parse_all, read below to derive combined values
    temperature_above: int
    temperature_underside: int
    work_hour: int
    work_minute: int
    cur_temperature_above: int
    cur_temperature_underside: int

    def __init__(self, body: bytearray) -> None:
        """Initialize BF message body."""
        super().__init__(
            body,
            [
                IntParser(
                    "cloudmenuid",
                    OFFSET_CLOUDMENUID,
                    max_value=0xFFFFFF,
                    length_in_bytes=3,
                    first_upper=True,
                ),
                IntParser(
                    "totalstep",
                    OFFSET_TOTALSTEP_STEPNUM,
                    transform_func=lambda x: x >> 4,
                ),
                IntParser("stepnum", OFFSET_TOTALSTEP_STEPNUM, byte_mask=0x0F),
                BoolParser("probe", OFFSET_FLAGS_B6, 1),
                BoolParser("turntable", OFFSET_FLAGS_B6, 3),
                TimeParser("hour_set", OFFSET_HOUR_SET),
                TimeParser("minute_set", OFFSET_MINUTE_SET),
                TimeParser("second_set", OFFSET_SECOND_SET),
                WordParser("temperature_above", OFFSET_TEMP_ABOVE),
                WordParser("temperature_underside", OFFSET_TEMP_UNDERSIDE),
                WordParser("probe_temperature", OFFSET_PROBE_TEMP),
                TimeParser("work_hour", OFFSET_WORK_HOUR),
                TimeParser("work_minute", OFFSET_WORK_MINUTE),
                TimeParser("work_second", OFFSET_WORK_SECOND),
                WordParser("cur_temperature_above", OFFSET_CUR_TEMP_ABOVE),
                WordParser("cur_temperature_underside", OFFSET_CUR_TEMP_UNDERSIDE),
                WordParser("cur_probe_temperature", OFFSET_CUR_PROBE_TEMP),
                BoolParser("child_lock", OFFSET_FLAGS_B32, 0),
                BoolParser("door", OFFSET_FLAGS_B32, 1),
                BoolParser("tank_ejected", OFFSET_FLAGS_B32, 2),
                BoolParser("water_shortage", OFFSET_FLAGS_B32, 3),
                BoolParser("water_change_reminder", OFFSET_FLAGS_B32, 4),
                BoolParser("error_code", OFFSET_FLAGS_B32, 7),
                BoolParser("flip_side", OFFSET_FLAGS_B33, 0),
                BoolParser("reaction", OFFSET_FLAGS_B33, 1),
                BoolParser("furnace_light", OFFSET_FLAGS_B33, 2),
                # Bit cleared means locked
                BoolParser(
                    "high_temperature_lock",
                    OFFSET_FLAGS_B33,
                    3,
                    true_value=0,
                    false_value=1,
                ),
                BoolParser("high_temperature_work", OFFSET_FLAGS_B33, 4),
                BoolParser("high_temperature", OFFSET_FLAGS_B33, 5),
                BoolParser("probe_mode", OFFSET_FLAGS_B33, 6),
                BoolParser("ramadan", OFFSET_RAMADAN, 5),
                BoolParser("hot_wind", OFFSET_HOT_WIND, 5),
                BoolParser("clean_scale", OFFSET_FLAGS_B56, 6),
                BoolParser("ota", OFFSET_FLAGS_B56, 7),
                BoolParser("clean_sink_ponding", OFFSET_FLAGS_B58, 0),
                BoolParser("dissipate_heat", OFFSET_FLAGS_B58, 1),
            ],
        )

        self._parse_execute_status(body)
        self._parse_work_mode(body)
        self._parse_fire_power(body)
        self._parse_steam_weight(body)
        self._parse_status_and_power(body)
        self._parse_pre_heat(body)
        self._parse_cbs_version(body)
        self.temperature = self.temperature_above or self.temperature_underside
        # Minutes, like b0/b1; seconds are dropped, same as Lua's totalState.
        self.time_remaining = self.work_hour * MINUTES_PER_HOUR + self.work_minute
        self.current_temperature = (
            self.cur_temperature_above or self.cur_temperature_underside
        )

    def _parse_execute_status(self, body: bytearray) -> None:
        """Parse execute status from body."""
        execute = self.read_byte(body, OFFSET_EXECUTE, 0)
        self.execute = {
            0x00: "ok",
            0x01: "status_nonsupport",
            0x02: "function_nonsupport",
            0x03: "param_range_error",
        }.get(execute, "unknown")

    def _parse_work_mode(self, body: bytearray) -> None:
        """Parse work_mode from body."""
        self.work_mode = work_mode_to_name(
            self.read_byte(body, OFFSET_WORK_MODE_HIGH, BYTE_FF),
            self.read_byte(body, OFFSET_WORK_MODE_LOW, BYTE_FF),
        )

    def _parse_fire_power(self, body: bytearray) -> None:
        """Parse fire_power from body."""
        fp = self.read_byte(body, OFFSET_FIRE_POWER, BYTE_FF)
        try:
            self.fire_power = FirePower(fp).name
        except ValueError:
            self.fire_power = "unknown"

    def _parse_steam_weight(self, body: bytearray) -> None:
        """Parse steam_quantity and weight/people_number from body."""
        sq = self.read_byte(body, OFFSET_STEAM_QUANTITY, BYTE_FF)
        self.steam_quantity = sq if sq != MAX_BYTE_VALUE else None
        b = self.read_byte(body, OFFSET_WEIGHT_PEOPLE, BYTE_FF)
        self.weight = b * WEIGHT_DIVISOR if b != MAX_BYTE_VALUE else None
        self.people_number = b if b != MAX_BYTE_VALUE else None

    def _parse_status_and_power(self, body: bytearray) -> None:
        """Parse work_status and infer power state."""
        status_byte = self.read_byte(body, OFFSET_WORK_STATUS, 0)
        try:
            self.status = WorkStatus(status_byte).name
        except ValueError:
            self.status = "unknown"
        # save_power means device is off; unknown status cannot be trusted as on
        self.power = self.status not in ("save_power", "unknown")

    def _parse_pre_heat(self, body: bytearray) -> None:
        """Parse pre_heat from body byte 32.

        Lua distinguishes preheat "work" (bit5) from "end" (bit6); both are
        reported here as pre_heat=True since DeviceAttributes.pre_heat is boolean.
        """
        b = self.read_byte(body, OFFSET_FLAGS_B32, 0)
        self.pre_heat = bool(b & (BIT_PREHEAT | BIT_PREHEAT_END))

    def _parse_cbs_version(self, body: bytearray) -> None:
        """Parse cbs_version from body."""
        if len(body) > OFFSET_CBS_VERSION_PATCH:
            major = body[OFFSET_CBS_VERSION_MAJOR]
            minor = body[OFFSET_CBS_VERSION_MINOR]
            patch = body[OFFSET_CBS_VERSION_PATCH]
            self.cbs_version = f"V{major}.{minor}.{patch}"
        else:
            self.cbs_version = "V0.0.0"


class MessageBFResponse(MessageResponse):
    """BF message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize BF message response."""
        super().__init__(bytearray(message))
        if (
            self.message_type
            in [MessageType.set, MessageType.notify1, MessageType.query]
            and self.body_type == BODY_TYPE_TOTAL_STATE
        ):
            self.set_body(MessageBFBody(super().body))
        self.set_attr()
