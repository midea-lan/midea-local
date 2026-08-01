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

    def __init__(self, protocol_version: ProtocolVersion) -> None:
        """Initialize BF message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X02,
        )
        self.power: bool | None = None
        self.child_lock: bool | None = None

    @property
    def _body(self) -> bytearray:
        power = 0xFF if self.power is None else 0x11 if self.power else 0x01
        child_lock = (
            0xFF if self.child_lock is None else 0x01 if self.child_lock else 0x00
        )
        return bytearray([power, child_lock] + [0xFF] * 7)


class MessageBFBody(MessageBody):
    """BF message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize BF message body."""
        super().__init__(body)
        self.status = body[31]
        self.time_remaining = (
            (0 if body[22] == MAX_BYTE_VALUE else body[22]) * 3600
            + (0 if body[23] == MAX_BYTE_VALUE else body[23]) * 60
            + (0 if body[24] == MAX_BYTE_VALUE else body[24])
        )
        cur_temperature = body[25] * 256 + body[26]
        if cur_temperature == 0:
            cur_temperature = body[27] * 256 + body[28]
        self.current_temperature = cur_temperature
        self.child_lock = (body[32] & 0x01) > 0
        self.door = (body[32] & 0x02) > 0
        self.tank_ejected = (body[32] & 0x04) > 0
        self.water_state = (body[32] & 0x08) > 0
        self.water_change_reminder = (body[32] & 0x10) > 0


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
