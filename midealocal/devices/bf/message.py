"""Midea local BF message."""

from enum import IntEnum

from midealocal.const import MAX_BYTE_VALUE, DeviceType, ProtocolVersion
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

# Body type constants
BODY_TYPE_TOTAL_STATE = 0x01

# Byte offsets in MessageBFBody (body[0] is body_type, data starts at body[1])
OFFSET_EXECUTE = 1
OFFSET_CLOUDMENUID_HIGH = 2
OFFSET_CLOUDMENUID_MID = 3
OFFSET_CLOUDMENUID_LOW = 4
OFFSET_TOTALSTEP_STEPNUM = 5
OFFSET_FLAGS_B6 = 6
OFFSET_WORK_MODE_HIGH = 7
OFFSET_WORK_MODE_LOW = 8
OFFSET_HOUR_SET = 9
OFFSET_MINUTE_SET = 10
OFFSET_SECOND_SET = 11
OFFSET_FIRE_POWER = 12
OFFSET_TEMP_ABOVE_HIGH = 13
OFFSET_TEMP_ABOVE_LOW = 14
OFFSET_TEMP_UNDERSIDE_HIGH = 15
OFFSET_TEMP_UNDERSIDE_LOW = 16
OFFSET_PROBE_TEMP_HIGH = 17
OFFSET_PROBE_TEMP_LOW = 18
OFFSET_STEAM_QUANTITY = 19
OFFSET_WEIGHT_PEOPLE = 20
OFFSET_WORK_HOUR = 22
OFFSET_WORK_MINUTE = 23
OFFSET_WORK_SECOND = 24
OFFSET_CUR_TEMP_ABOVE_HIGH = 25
OFFSET_CUR_TEMP_ABOVE_LOW = 26
OFFSET_CUR_TEMP_UNDERSIDE_HIGH = 27
OFFSET_CUR_TEMP_UNDERSIDE_LOW = 28
OFFSET_CUR_PROBE_TEMP_HIGH = 29
OFFSET_CUR_PROBE_TEMP_LOW = 30
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

# Bit masks
BIT_PROBE = 0x02
BIT_TURNTABLE = 0x08
BIT_HOT_WIND = 0x20
BIT_CHILD_LOCK = 0x01
BIT_DOOR = 0x02
BIT_TANK_EJECTED = 0x04
BIT_WATER_SHORTAGE = 0x08
BIT_WATER_CHANGE = 0x10
BIT_PREHEAT = 0x20
BIT_ERROR_CODE = 0x80
BIT_FLIP_SIDE = 0x01
BIT_REACTION = 0x02
BIT_FURNACE_LIGHT = 0x04
BIT_HIGH_TEMP_LOCK = 0x08
BIT_HIGH_TEMP_WORK = 0x10
BIT_HIGH_TEMP = 0x20
BIT_PROBE_MODE = 0x40
BIT_CLEAN_SCALE = 0x40
BIT_OTA = 0x80
BIT_CLEAN_SINK_PONDING = 0x01
BIT_DISSIPATE_HEAT = 0x02

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
BYTE_RAMADAN_ON = 0x01
BYTE_RAMADAN_OFF = 0x00

# Weight conversion factor (device sends weight/10)
WEIGHT_DIVISOR = 10

# Time conversion factors
SECONDS_PER_HOUR = 3600
SECONDS_PER_MINUTE = 60


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
        return (0xFF, 0xFF)
    return WORK_MODE_MAP.get(mode, (0xFF, 0xFF))


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

    def __init__(self, protocol_version: int | ProtocolVersion) -> None:
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
        self.ramadan: bool | None = None
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
            return 0xFF
        try:
            return FirePower[name].value
        except KeyError:
            return 0xFF

    @staticmethod
    def _work_status_value(status: str | None) -> int:
        if status is None:
            return 0xFF
        try:
            return WorkStatus[status].value
        except KeyError:
            return 0xFF

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
            self.ramadan,
        ]
        if any(field is not None for field in not_work_mode_fields):
            self.body_type = ListTypes.X02  # notWorkModeControl
            return self._build_not_work_mode_control()
        # setControl: parameter adjustments during work
        self.body_type = ListTypes.X03  # setControl
        return self._build_set_control()

    def _build_not_work_mode_control(self) -> bytearray:
        """Build notWorkModeControl body content (body_type=0x02 added by framework)."""
        power_byte = self._bool_to_byte(
            self.power,
            BYTE_POWER_ON,
            BYTE_POWER_OFF,
        )
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
            self.screen_luminance if self.screen_luminance is not None else BYTE_FF
        )
        volume_byte = self.volume if self.volume is not None else BYTE_FF
        hot_wind_byte = self._bool_to_byte(
            self.hot_wind,
            BYTE_HOT_WIND_ON,
            BYTE_HOT_WIND_OFF,
        )
        ramadan_byte = self._bool_to_byte(
            self.ramadan,
            BYTE_RAMADAN_ON,
            BYTE_RAMADAN_OFF,
        )

        # Lua bodyBytes[1..17] (bodyBytes[0]=0x02 is body_type, added by framework)
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
                ramadan_byte,
                BYTE_FF,
            ],
        )

    @staticmethod
    def _bool_to_byte(value: bool | None, true_val: int, false_val: int) -> int:
        """Convert optional bool to byte value."""
        if value is True:
            return true_val
        if value is False:
            return false_val
        return BYTE_FF

    def _build_work_mode_control(self) -> bytearray:
        """Build workModeControl/singleCooking body content (body_type=0x01 added by framework)."""  # noqa: E501
        # b5 flags: bit0=pre_heat, bit1=probe, bit3=turntable, bit4=hot_wind
        b5 = 0
        if self.pre_heat is True:
            b5 |= 0x01
        if self.probe_temperature is not None:
            b5 |= 0x02
        if self.turntable is True:
            b5 |= 0x08
        if self.hot_wind is True:
            b5 |= 0x10

        mode_high, mode_low = work_mode_to_bytes(self.work_mode)

        work_hour = self.work_hour if self.work_hour is not None else 0x00
        work_minute = self.work_minute if self.work_minute is not None else 0x00
        work_second = self.work_second if self.work_second is not None else 0x00
        fire_power_byte = self._fire_power_value(self.fire_power)

        # Temperature bytes
        temp_high = temp_low = 0x00
        temp_above_high = temp_above_low = 0x00
        temp_underside_high = temp_underside_low = 0x00

        if self.temperature is not None:
            temp_high = self.temperature >> 8
            temp_low = self.temperature & 0xFF
            temp_above_high = temp_high
            temp_above_low = temp_low
            temp_underside_high = temp_high
            temp_underside_low = temp_low
        if self.temperature_above is not None:
            temp_above_high = self.temperature_above >> 8
            temp_above_low = self.temperature_above & 0xFF
        if self.temperature_underside is not None:
            temp_underside_high = self.temperature_underside >> 8
            temp_underside_low = self.temperature_underside & 0xFF

        # Probe temperature
        probe_high = probe_low = 0x00
        if self.probe_temperature is not None:
            probe_high = self.probe_temperature >> 8
            probe_low = self.probe_temperature & 0xFF

        # Steam quantity
        steam_byte = self.steam_quantity if self.steam_quantity is not None else BYTE_FF

        # Weight / people number
        if self.weight is not None:
            weight_byte = self.weight // WEIGHT_DIVISOR
        elif self.people_number is not None:
            weight_byte = self.people_number
        else:
            weight_byte = BYTE_FF

        # Lua bodyBytes[1..21] (bodyBytes[0]=0x01 is body_type, added by framework)
        return bytearray(
            [
                0x00,  # bodyBytes[1] reserved
                0x00,  # bodyBytes[2] reserved
                0x00,  # bodyBytes[3] reserved
                0x00,  # bodyBytes[4] reserved
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
            body.append(0x00)
            param_sum += 1
            body.append(self.steam_set)

        time_fields = [self.hour_set, self.minute_set, self.second_set]
        if any(f is not None for f in time_fields):
            body.append(0x01)
            body.append(self.hour_set if self.hour_set is not None else 0x00)
            body.append(self.minute_set if self.minute_set is not None else 0x00)
            body.append(self.second_set if self.second_set is not None else 0x00)
            param_sum += 1

        if self.fire_power_set is not None:
            body.append(0x02)
            param_sum += 1
            body.append(self._fire_power_value(self.fire_power_set))

        if self.temp_set is not None:
            temp_high = self.temp_set >> 8
            temp_low = self.temp_set & 0xFF
            body.append(0x03)
            body.append(0x00)
            body.append(temp_high)
            body.append(temp_low)
            param_sum += 1

        if self.probe_temp_set is not None:
            temp_high = self.probe_temp_set >> 8
            temp_low = self.probe_temp_set & 0xFF
            body.append(0x04)
            body.append(0x00)
            body.append(temp_high)
            body.append(temp_low)
            param_sum += 1

        if self.temp_above_set is not None:
            temp_high = self.temp_above_set >> 8
            temp_low = self.temp_above_set & 0xFF
            body.append(0x05)
            body.append(0x00)
            body.append(0x00)
            body.append(0x00)
            body.append(temp_high)
            body.append(temp_low)
            param_sum += 1

        if self.temp_underside_set is not None:
            temp_high = self.temp_underside_set >> 8
            temp_low = self.temp_underside_set & 0xFF
            body.append(0x05)
            body.append(0x00)
            body.append(0x00)
            body.append(0x01)
            body.append(temp_high)
            body.append(temp_low)
            param_sum += 1

        body[1] = param_sum
        return body


class MessageBFBody(MessageBody):
    """BF message body (totalState)."""

    def __init__(self, body: bytearray) -> None:
        """Initialize BF message body."""
        super().__init__(body)

        self._parse_execute_status(body)
        self._parse_cloudmenuid(body)
        self._parse_steps(body)
        self._parse_probe_turntable_flags(body)
        self._parse_work_mode(body)
        self._parse_time_settings(body)
        self._parse_fire_power(body)
        self._parse_temperatures(body)
        self._parse_steam_weight(body)
        self._parse_work_time(body)
        self._parse_current_temperatures(body)
        self._parse_status_and_power(body)
        self._parse_byte32_flags(body)
        self._parse_byte33_flags(body)
        self._parse_byte34_flags(body)
        self._parse_byte35_flags(body)
        self._parse_cbs_version(body)
        self._parse_byte56_flags(body)
        self._parse_byte58_flags(body)

    def _parse_execute_status(self, body: bytearray) -> None:
        """Parse execute status from body."""
        execute = self.read_byte(body, OFFSET_EXECUTE, 0)
        self.execute = {
            0x01: "status_nonsupport",
            0x02: "function_nonsupport",
            0x03: "param_range_error",
        }.get(execute, "ok")

    def _parse_cloudmenuid(self, body: bytearray) -> None:
        """Parse cloudmenuid from body."""
        self.cloudmenuid = (
            self.read_byte(body, OFFSET_CLOUDMENUID_HIGH, 0) << 16
            | self.read_byte(body, OFFSET_CLOUDMENUID_MID, 0) << 8
            | self.read_byte(body, OFFSET_CLOUDMENUID_LOW, 0)
        )

    def _parse_steps(self, body: bytearray) -> None:
        """Parse totalstep and stepnum from body."""
        b = self.read_byte(body, OFFSET_TOTALSTEP_STEPNUM, 0)
        self.totalstep = b >> 4
        self.stepnum = b & 0x0F

    def _parse_probe_turntable_flags(self, body: bytearray) -> None:
        """Parse probe and turntable flags from body."""
        b = self.read_byte(body, OFFSET_FLAGS_B6, 0)
        self.probe = bool(b & BIT_PROBE)
        self.turntable = bool(b & BIT_TURNTABLE)

    def _parse_work_mode(self, body: bytearray) -> None:
        """Parse work_mode from body."""
        self.work_mode = work_mode_to_name(
            self.read_byte(body, OFFSET_WORK_MODE_HIGH, BYTE_FF),
            self.read_byte(body, OFFSET_WORK_MODE_LOW, BYTE_FF),
        )

    def _parse_time_settings(self, body: bytearray) -> None:
        """Parse hour_set/minute_set/second_set from body."""
        self.hour_set = self._read_time_byte(body, OFFSET_HOUR_SET)
        self.minute_set = self._read_time_byte(body, OFFSET_MINUTE_SET)
        self.second_set = self._read_time_byte(body, OFFSET_SECOND_SET)

    def _read_time_byte(self, body: bytearray, offset: int) -> int:
        """Read a time byte, returning 0 if 0xFF."""
        if len(body) > offset and body[offset] != MAX_BYTE_VALUE:
            return body[offset]
        return 0

    def _parse_fire_power(self, body: bytearray) -> None:
        """Parse fire_power from body."""
        fp = self.read_byte(body, OFFSET_FIRE_POWER, BYTE_FF)
        try:
            self.fire_power = FirePower(fp).name
        except ValueError:
            self.fire_power = "unknown"

    def _parse_temperatures(self, body: bytearray) -> None:
        """Parse temperature settings from body."""
        self.temperature_above = self._read_word(
            body,
            OFFSET_TEMP_ABOVE_HIGH,
            OFFSET_TEMP_ABOVE_LOW,
        )
        self.temperature_underside = self._read_word(
            body,
            OFFSET_TEMP_UNDERSIDE_HIGH,
            OFFSET_TEMP_UNDERSIDE_LOW,
        )
        self.temperature = (
            self.temperature_above
            if self.temperature_above != 0
            else self.temperature_underside
        )
        self.probe_temperature = self._read_word(
            body,
            OFFSET_PROBE_TEMP_HIGH,
            OFFSET_PROBE_TEMP_LOW,
        )

    def _parse_steam_weight(self, body: bytearray) -> None:
        """Parse steam_quantity and weight/people_number from body."""
        sq = self.read_byte(body, OFFSET_STEAM_QUANTITY, BYTE_FF)
        self.steam_quantity = sq if sq != MAX_BYTE_VALUE else None
        b = self.read_byte(body, OFFSET_WEIGHT_PEOPLE, BYTE_FF)
        self.weight = b * WEIGHT_DIVISOR if b != MAX_BYTE_VALUE else None
        self.people_number = b if b != MAX_BYTE_VALUE else None

    def _parse_work_time(self, body: bytearray) -> None:
        """Parse work_hour/minute/second and compute time_remaining."""
        self.work_hour = self._read_time_byte(body, OFFSET_WORK_HOUR)
        self.work_minute = self._read_time_byte(body, OFFSET_WORK_MINUTE)
        self.work_second = self._read_time_byte(body, OFFSET_WORK_SECOND)
        self.time_remaining = (
            self.work_hour * SECONDS_PER_HOUR
            + self.work_minute * SECONDS_PER_MINUTE
            + self.work_second
        )

    def _parse_current_temperatures(self, body: bytearray) -> None:
        """Parse current temperatures from body."""
        self.cur_temperature_above = self._read_word(
            body,
            OFFSET_CUR_TEMP_ABOVE_HIGH,
            OFFSET_CUR_TEMP_ABOVE_LOW,
        )
        self.cur_temperature_underside = self._read_word(
            body,
            OFFSET_CUR_TEMP_UNDERSIDE_HIGH,
            OFFSET_CUR_TEMP_UNDERSIDE_LOW,
        )
        cur_temp = self.cur_temperature_above
        if cur_temp == 0:
            cur_temp = self.cur_temperature_underside
        self.current_temperature = cur_temp
        self.cur_probe_temperature = self._read_word(
            body,
            OFFSET_CUR_PROBE_TEMP_HIGH,
            OFFSET_CUR_PROBE_TEMP_LOW,
        )

    def _parse_status_and_power(self, body: bytearray) -> None:
        """Parse work_status and infer power state."""
        status_byte = self.read_byte(body, OFFSET_WORK_STATUS, 0)
        try:
            self.status = WorkStatus(status_byte).name
        except ValueError:
            self.status = "unknown"
        self.power = self.status != "save_power"

    def _parse_byte32_flags(self, body: bytearray) -> None:
        """Parse flags from body byte 32."""
        b = self.read_byte(body, OFFSET_FLAGS_B32, 0)
        self.child_lock = bool(b & BIT_CHILD_LOCK)
        self.door = bool(b & BIT_DOOR)
        self.tank_ejected = bool(b & BIT_TANK_EJECTED)
        self.water_shortage = bool(b & BIT_WATER_SHORTAGE)
        self.water_change_reminder = bool(b & BIT_WATER_CHANGE)
        self.error_code = bool(b & BIT_ERROR_CODE)
        self.pre_heat = bool(b & BIT_PREHEAT)

    def _parse_byte33_flags(self, body: bytearray) -> None:
        """Parse flags from body byte 33."""
        b = self.read_byte(body, OFFSET_FLAGS_B33, 0)
        self.flip_side = bool(b & BIT_FLIP_SIDE)
        self.reaction = bool(b & BIT_REACTION)
        self.furnace_light = bool(b & BIT_FURNACE_LIGHT)
        self.high_temperature_lock = (b & BIT_HIGH_TEMP_LOCK) == 0
        self.high_temperature_work = bool(b & BIT_HIGH_TEMP_WORK)
        self.high_temperature = bool(b & BIT_HIGH_TEMP)
        self.probe_mode = bool(b & BIT_PROBE_MODE)

    def _parse_byte34_flags(self, body: bytearray) -> None:
        """Parse ramadan flag from body byte 34."""
        b = self.read_byte(body, OFFSET_RAMADAN, 0)
        self.ramadan = bool(b & BIT_HOT_WIND)

    def _parse_byte35_flags(self, body: bytearray) -> None:
        """Parse hot_wind flag from body byte 35."""
        b = self.read_byte(body, OFFSET_HOT_WIND, 0)
        self.hot_wind = bool(b & BIT_HOT_WIND)

    def _parse_cbs_version(self, body: bytearray) -> None:
        """Parse cbs_version from body."""
        if len(body) > OFFSET_CBS_VERSION_PATCH:
            major = body[OFFSET_CBS_VERSION_MAJOR]
            minor = body[OFFSET_CBS_VERSION_MINOR]
            patch = body[OFFSET_CBS_VERSION_PATCH]
            self.cbs_version = f"V{major}.{minor}.{patch}"
        else:
            self.cbs_version = "V0.0.0"

    def _parse_byte56_flags(self, body: bytearray) -> None:
        """Parse clean_scale and ota flags from body byte 56."""
        b = self.read_byte(body, OFFSET_FLAGS_B56, 0)
        self.clean_scale = bool(b & BIT_CLEAN_SCALE)
        self.ota = bool(b & BIT_OTA)

    def _parse_byte58_flags(self, body: bytearray) -> None:
        """Parse clean_sink_ponding and dissipate_heat flags from body byte 58."""
        b = self.read_byte(body, OFFSET_FLAGS_B58, 0)
        self.clean_sink_ponding = bool(b & BIT_CLEAN_SINK_PONDING)
        self.dissipate_heat = bool(b & BIT_DISSIPATE_HEAT)

    def _read_word(self, body: bytearray, high_offset: int, low_offset: int) -> int:
        """Read a 16-bit word from two body bytes."""
        return self.read_byte(body, high_offset, 0) << 8 | self.read_byte(
            body,
            low_offset,
            0,
        )


class MessageBFResponse(MessageResponse):
    """BF message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize BF message response."""
        super().__init__(bytearray(message))
        if (
            self.message_type
            in [MessageType.set, MessageType.notify1, MessageType.query]
            and self.body_type == 0x01
        ):
            self.set_body(MessageBFBody(super().body))
        self.set_attr()
