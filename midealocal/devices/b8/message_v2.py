"""Midea local B8 second-generation ("v2") protocol messages.

Newer B8 robot vacuums (Midea cloud plugin SN8 ``750004CE``, models with a
base/wash station) speak a different wire protocol than the one in
``message.py`` (SN8 ``7500001H``):

* control/query/report frames use body-type ``0xAA`` followed by a version
  byte ``0x01`` and a type selector, instead of body-type ``0x22``/``0x32``;
* the work-status table is renumbered (``pause`` is ``clean_pause = 0x06``
  here, ``0x08`` in v1, and the start/stop/pause *command* still uses the
  legacy ``0x1B`` on its own channel);
* start/stop/charge/pause go through a task-control channel
  (``02 AA 01 01 <code>``) and each setting (fan, water, voice ...) is its
  own ``02 AA 01 <selector> <value>`` frame;
* ``sleep``/``relocate``/``on_base`` work states carry a sub-status byte.

This module is a faithful port of ``lua/b8/T_0000_B8_750004CE_2024011101.lua``
(``decode0401Report`` for field offsets -- ``decodeQueryWorkStatusBin`` in the
same plugin is visibly buggy). It is selected per device in ``__init__.py``
via ``_V2_SUBTYPES``.
"""

from enum import IntEnum

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

from .message import B8ControlType, B8ErrorType, B8MopState


class B8V2WorkStatus(IntEnum):
    """Midea B8 v2 work status."""

    NONE = 0x00
    CHARGING = 0x01
    CHARGING_ON_DOCK = 0x02
    CHARGE_PAUSE = 0x03
    CHARGE_FINISH = 0x04
    WORK = 0x05
    CLEAN_PAUSE = 0x06
    STOP = 0x07
    UPDATING = 0x08
    ERROR = 0x09
    SLEEP = 0x0A
    RELOCATE = 0x0B
    MAP_SEARCHING = 0x0C
    CLEAN_MOP = 0x0D
    BACK_CLEAN_MOP = 0x0E
    CLEAN_MOP_PAUSE = 0x0F
    MANUAL_CONTROL = 0x11
    ON_BASE = 0x12
    VIDEO_CRUISE = 0x13
    VIDEO_CRUISE_PAUSE = 0x14
    MAP_SEARCHING_PAUSE = 0x15


class B8V2SubWorkStatus(IntEnum):
    """Midea B8 v2 sub work status (reported while ``ON_BASE``)."""

    FREE = 0x00
    CHARGING = 0x01
    INJECT_WATER = 0x02
    CLEAN_MOP = 0x03
    DRY_MOP = 0x04
    HOT_DRY_MOP = 0x05
    WATER_STATION_ERROR = 0x06
    CHARGE_FINISH = 0x07
    ERP_MODE = 0x08
    AUTO_CLEAN = 0x09
    DUST_COLLECT = 0x0A
    CUT_HAIR = 0x0B


class B8V2SleepingStatus(IntEnum):
    """Midea B8 v2 sub work status (reported while ``SLEEP``)."""

    DEFAULT_SLEEPING = 0x30
    PAUSE_SLEEPING = 0x31
    STANDING_SLEEPING = 0x32
    CHARGE_PAUSE_SLEEPING = 0x33
    RETURN_STATION_PAUSE_SLEEPING = 0x34
    CRUISE_PAUSE_SLEEPING = 0x35


class B8V2RelocateReason(IntEnum):
    """Midea B8 v2 sub work status (reported while ``RELOCATE``)."""

    DEFAULT = 0x50
    FIRST_START = 0x51
    WHEEL_LIFT = 0x52
    MILEMETER_DATA_CHANGE = 0x53
    IMU_DATA_CHANGE = 0x54
    NO_MAP = 0x55
    COMING_OUT_DURING_RELOCATE = 0x56
    MAP_CHANGE = 0x57
    MANUAL_CONTROL = 0x58
    POSITION_OUT_OF_MAP = 0x59


class B8V2Moviment(IntEnum):
    """Midea B8 v2 movement."""

    NONE = 0x00
    FORWARD = 0x01
    BACK = 0x02
    LEFT = 0x03
    RIGHT = 0x04
    FORWARD_LEFT = 0x05
    FORWARD_RIGHT = 0x06
    BACK_LEFT = 0x07
    BACK_RIGHT = 0x08


class B8V2CleanMode(IntEnum):
    """Midea B8 v2 clean mode."""

    NONE = 0x00
    AUTO = 0x08
    AREA = 0x09
    ZONE_INDEX = 0x0A
    ZONE_RECT = 0x0B
    TARGET_POINT = 0x0D


class B8V2FanLevel(IntEnum):
    """Midea B8 v2 fan level."""

    NORMAL = 0x01
    HIGH = 0x02
    SUPER = 0x03
    SOFT = 0x04


class B8V2WaterLevel(IntEnum):
    """Midea B8 v2 water level."""

    LOW = 0x01
    NORMAL = 0x02
    HIGH = 0x03


class B8V2SpeakLevel(IntEnum):
    """Midea B8 v2 voice level."""

    NONE = 0x00
    OFF = 0x01
    LOW = 0x02
    NORMAL = 0x03
    HIGH = 0x04


class B8V2SweepMopMode(IntEnum):
    """Midea B8 v2 sweep/mop mode."""

    SWEEP_AND_MOP = 0x00
    SWEEP = 0x01
    MOP = 0x02
    SWEEP_THEN_MOP = 0x03


class B8V2FunctionType(IntEnum):
    """Midea B8 v2 function type."""

    NONE = 0x00
    DUST_BOX_CLEANING = 0x01
    WATER_TANK_CLEANING = 0x02
    RELOCATE_DEFAULT = 0x03
    RELOCATE_IN_PROGRESS = 0x04
    RELOCATE_SUCCESS = 0x05
    RELOCATE_FAIL = 0x06


class B8V2TaskControl(IntEnum):
    """Midea B8 v2 task-control command (``02 AA 01 01 <code>``)."""

    CHARGE = 0x01
    CHARGE_PAUSE = 0x02
    CHARGE_CONTINUE = 0x03
    WORK = 0x04
    PAUSE = 0x05
    CONTINUE = 0x06
    STOP = 0x07
    VIDEO_CRUISE_START = 0x08
    VIDEO_CRUISE_PAUSE = 0x09
    QUICKLY_MAPPING = 0x0A


class B8V2ConfigType(IntEnum):
    """Midea B8 v2 per-setting selector byte (``02 AA 01 <selector> <value>``)."""

    FAN = 0x50
    WATER = 0x51
    VOICE = 0x93


class B8V2QueryType(IntEnum):
    """Midea B8 v2 query selector byte (``03 AA 01 <selector>``)."""

    WORK = 0x01


class B8V2ErrorFixDescription(IntEnum):
    """Midea B8 v2 fixable-error description."""

    NO = 0x00
    FIX_DUST = 0x01
    FIX_WHEEL_HANG = 0x02
    FIX_WHEEL_OVERLOAD = 0x03
    FIX_SIDE_BRUSH_OVERLOAD = 0x04
    FIX_ROLL_BRUSH_OVERLOAD = 0x05
    FIX_DUST_ENGINE = 0x06
    FIX_FRONT_PANEL = 0x07
    FIX_RADAR_MASK = 0x08
    FIX_DROP_SENSOR = 0x09
    FIX_LOW_BATTERY = 0x0A
    FIX_ABNORMAL_POSTURE = 0x0B
    FIX_LASER_SENSOR = 0x0C
    FIX_EDGE_SENSOR = 0x0D
    FIX_START_IN_FORBID_AREA_1 = 0x0E
    FIX_START_IN_STRONG_MAGNETIC = 0x0F
    FIX_LASER_SENSOR_BLOCKED = 0x10
    FIX_MOPPING_BOARD_DROPPED = 0x11
    FIX_SLIPPING_AND_JAMMING = 0x12
    FIX_MULTIPLE_RECHARGE_ATTEMPTS = 0x13
    FIX_VIBRATION_DRAG_OVERLOAD = 0x14
    FIX_WIPE_DISK_OVERLOAD = 0x15
    FIX_WATER_TANK_MISS = 0x16
    FIX_WIPE_DISK_CHIP_FAULT = 0x17
    FIX_TEMPERATURE_TOO_HIGH = 0x18
    FIX_HAIR_CUT_FAILED = 0x20
    FIX_MOP_DROP_OUT = 0x40
    FIX_ROTATE_TIME_OUT = 0x41
    FIX_NO_BASE_STATION_IN_MAP = 0x42
    FIX_IN_FORBID_AREA_OR_NO_BACK_ROUTE = 0x43
    FIX_MAX_RETRY_TIMES_EXCEEDED = 0x44
    FIX_AUTO_FIX_RADAR_HIGH_TEMPERATURE_FAILED = 0x45
    FIX_REACH_DESTINATION_FAILED = 0x50
    FIX_PHYSICAL_COLLISION_PLATE_OCCURRED = 0x51
    FIX_START_IN_FORBID_VIRTUAL_AREA = 0x52
    FIX_WHEEL_SUSPENSION = 0x53
    FIX_OUT_STATION_FAILED = 0x54
    FIX_ESCAPE_ENVIRONMENT_FAILED = 0x55
    FIX_INNER_COMMUNICATION_TIMEOUT = 0x57
    FIX_USE_SWEEP_AND_MOP_ON_CARPET = 0x58
    FIX_START_IN_VIRTUAL_WALL = 0x59
    FIX_START_IN_FORBID_AREA = 0x5A
    FIX_START_IN_FORBID_WATER_AREA = 0x5B
    FIX_START_IN_FORBID_AREA_2 = 0x5C
    FIX_TRAPPED_IN_SMALL_AREA = 0x5D
    FIX_WHOLE_HOUSE_CLEAN_WITH_WRONG_PARTITION = 0x5E
    FIX_RADAR_DATA_BLOCKED = 0xA0


class B8V2ErrorRebootDescription(IntEnum):
    """Midea B8 v2 reboot-error description."""

    NO = 0x00
    REBOOT_LASER_COMM_FAIL = 0x01
    REBOOT_ROBOT_COMM_FAIL = 0x02


class B8V2ErrorWarningDescription(IntEnum):
    """Midea B8 v2 warning-error description."""

    NO = 0x00
    WARN_LOCATION_FAIL = 0x01
    WARN_LOW_BATTERY = 0x02
    WARN_FULL_DUST = 0x03
    WARN_LOW_WATER = 0x04
    WARN_MULTIPLE_DOCKING_FAIL = 0x05
    WARN_DOWN_SENSOR_BLOCKED = 0x06
    WARN_ABNORMAL_BATTERY_TEMPERATURE = 0x07
    WARN_RAG_LIFTING = 0x08
    WARN_DUST_COLLECTION_INTERRUPT = 0x09
    WARN_DUST_BLOCKAGE = 0x0A
    WARN_UPPER_COVER_OPEN = 0x0B
    WARN_DUST_BAG_NOT_INSTALLED = 0x0C
    WARN_DUST_BAG_FULL = 0x0D
    WARN_REACH_LOCATION_FAIL = 0x20
    WARN_CACHE_FAIL = 0x21
    WARN_START_MOP_IN_CARPET = 0x22
    WARN_START_IN_VIRTUAL_WALL = 0x23
    WARN_START_IN_FORBID_AREA = 0x24
    WARN_START_IN_FORBID_WATER_AREA = 0x25
    WARN_COMM_DISCONNECT = 0x64
    WARN_MACHINE_MISS = 0x65
    WARN_VACUUM_WATER_INJECT_FAIL = 0x66
    WARN_SEWAGE_BOX_FULL = 0x67
    WARN_SEWAGE_BOX_MISS = 0x68
    WARN_WATER_BOX_MISS = 0x69
    WARN_LACK_OF_WATER = 0x6A
    WARN_CLOSE_POWER_FAIL = 0x6B
    WARN_HEAT_MODULE_FAIL = 0x6C
    WARN_FAN_FAIL = 0x6D
    WARN_STATION_WATER_INJECT_FAIL = 0x6E
    WARN_STATION_WATER_BOX_FULL = 0x6F
    WARN_VACUUM_WATER_BOX_FULL = 0x70
    WARN_VACUUM_WATER_BOX_MISS = 0x71
    WARN_VACUUM_MOP_MISS = 0x72
    WARN_WATER_SUPPLY_AND_DRAINAGE_IMPROPER_INSTALL = 0x75
    WARN_BASE_STATION_WATER_LEVEL_FAILED_1 = 0x76
    WARN_SLOP_TANK_EXCEPTION = 0x77
    WARN_BASE_STATION_FILTER_NET_IMPROPER_INSTALL = 0x78
    WARN_DUST_BOX_FULL = 0x79
    WARN_DUST_BOX_COVER_NOT_CLOSED = 0x80
    WARN_DUST_BAG_NOT_INSTALLED_2 = 0x81
    WARN_CLEANING_LIQUID_LACK = 0x83
    WARN_WATER_LEVEL_SENSOR_FAILED = 0x86
    WARN_STRONG_LIQUID_LACK = 0x87
    WARN_BASE_STATION_WATER_LEVEL_FAILED = 0x88
    WARN_WASHER_BASE_STATION_COMMUNICATION_FAILED = 0xCC


B8V2ErrorDescription = (
    B8V2ErrorFixDescription | B8V2ErrorRebootDescription | B8V2ErrorWarningDescription
)


class MessageB8V2Base(MessageRequest):
    """B8 v2 message base (body-type ``0xAA``)."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
    ) -> None:
        """Initialize B8 v2 message base."""
        super().__init__(
            device_type=DeviceType.B8,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=ListTypes.AA,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageV2Query(MessageB8V2Base):
    """B8 v2 status query (``03 AA 01 <query_type>``)."""

    def __init__(
        self,
        protocol_version: int,
        query_type: B8V2QueryType = B8V2QueryType.WORK,
    ) -> None:
        """Initialize B8 v2 query."""
        super().__init__(protocol_version, MessageType.query)
        self.query_type = query_type

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01, self.query_type])


class MessageV2SetCommand(MessageB8V2Base):
    """B8 v2 task-control command (``02 AA 01 01 <task_control>``)."""

    def __init__(
        self,
        protocol_version: int,
        task_control: B8V2TaskControl,
    ) -> None:
        """Initialize B8 v2 task-control command."""
        super().__init__(protocol_version, MessageType.set)
        self.task_control = task_control

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01, 0x01, self.task_control])


class MessageV2SetConfig(MessageB8V2Base):
    """B8 v2 per-setting command (``02 AA 01 <config_type> <value>``)."""

    def __init__(
        self,
        protocol_version: int,
        config_type: B8V2ConfigType,
        value: int,
    ) -> None:
        """Initialize B8 v2 per-setting command."""
        super().__init__(protocol_version, MessageType.set)
        self.config_type = config_type
        self.value = value

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01, self.config_type, self.value])


# Body byte offsets, counted from ``body[0]`` == frame byte 10 (body-type 0xAA).
# body[1] = version 0x01, body[2] = query/report selector 0x01, data from body[3].
_SELECTOR = 2
_MIN_BODY_LEN = _SELECTOR + 1
_WORK_STATUS = 3
_CONTROL_TYPE = 5
_MOVE_DIRECTION = 6
_CLEAN_MODE = 7
_FAN_LEVEL = 8
_AREA = 9
_WATER_LEVEL = 10
_VOICE_VOLUME = 11
_HAVE_RESERVE_TASK = 12
_BATTERY_PERCENT = 13
_WORK_TIME = 14
_ERROR_TYPE = 16
_ERROR_DESC = 17
_MOP = 18
_CARPET_SWITCH = 19
_SWEEP_MOP_MODE = 34
_SUB_WORK_STATUS = 36
_STATUS_SUMMARY = 50


_SUB_WORK_STATUS_ENUM: dict[B8V2WorkStatus, type[IntEnum]] = {
    B8V2WorkStatus.ON_BASE: B8V2SubWorkStatus,
    B8V2WorkStatus.SLEEP: B8V2SleepingStatus,
    B8V2WorkStatus.RELOCATE: B8V2RelocateReason,
}


def _enum_or_zero[T: IntEnum](enum_cls: type[T], raw: int) -> T:
    """Return ``enum_cls(raw)`` or the enum's ``0`` member on an unknown value."""
    try:
        return enum_cls(raw)
    except ValueError:
        return enum_cls(0)


class MessageB8V2Body(MessageBody):
    """B8 v2 work-status body (query reply ``03 AA 01 01`` / report ``04 .. 01``)."""

    def __init__(self, body: bytearray) -> None:
        """Parse a B8 v2 work-status body."""
        super().__init__(body)
        try:
            self.work_status = B8V2WorkStatus(self.read_byte(body, _WORK_STATUS))
        except ValueError:
            self.work_status = B8V2WorkStatus.NONE
        try:
            self.control_type = B8ControlType(self.read_byte(body, _CONTROL_TYPE))
        except ValueError:
            self.control_type = B8ControlType.NONE
        try:
            self.move_direction = B8V2Moviment(self.read_byte(body, _MOVE_DIRECTION))
        except ValueError:
            self.move_direction = B8V2Moviment.NONE
        try:
            self.clean_mode = B8V2CleanMode(self.read_byte(body, _CLEAN_MODE))
        except ValueError:
            self.clean_mode = B8V2CleanMode.NONE
        try:
            self.fan_level = B8V2FanLevel(self.read_byte(body, _FAN_LEVEL))
        except ValueError:
            self.fan_level = B8V2FanLevel.NORMAL
        self.area = self.read_byte(body, _AREA)
        try:
            self.water_level = B8V2WaterLevel(self.read_byte(body, _WATER_LEVEL))
        except ValueError:
            self.water_level = B8V2WaterLevel.LOW
        self.voice_volume = min(self.read_byte(body, _VOICE_VOLUME), 100)
        self.have_reserve_task = self.read_byte(body, _HAVE_RESERVE_TASK) != 0
        self.battery_percent = min(self.read_byte(body, _BATTERY_PERCENT), 100)
        self.work_time = self.read_byte(body, _WORK_TIME)

        try:
            self.error_type = B8ErrorType(self.read_byte(body, _ERROR_TYPE))
        except ValueError:
            self.error_type = B8ErrorType.NO
        self.error_desc: B8V2ErrorDescription = self._parse_error_desc(
            self.read_byte(body, _ERROR_DESC),
        )

        try:
            self.mop = B8MopState(self.read_byte(body, _MOP))
        except ValueError:
            self.mop = B8MopState.LACK_WATER
        self.carpet_switch = self.read_byte(body, _CARPET_SWITCH) != 0
        try:
            self.sweep_mop_mode = B8V2SweepMopMode(
                self.read_byte(body, _SWEEP_MOP_MODE),
            )
        except ValueError:
            self.sweep_mop_mode = B8V2SweepMopMode.SWEEP_AND_MOP
        self.sub_work_status = self._parse_sub_work_status(
            self.read_byte(body, _SUB_WORK_STATUS),
        )

        status_byte = self.read_byte(body, _STATUS_SUMMARY)
        self.uv_switch = (status_byte & 0x01) > 0
        self.wifi_switch = (status_byte & 0x02) > 0
        self.voice_switch = (status_byte & 0x04) > 0
        self.command_source = (status_byte & 0x40) > 0
        self.device_error = (status_byte & 0x80) > 0

    def _parse_error_desc(self, raw: int) -> B8V2ErrorDescription:
        table: dict[B8ErrorType, type[B8V2ErrorDescription]] = {
            B8ErrorType.CAN_FIX: B8V2ErrorFixDescription,
            B8ErrorType.REBOOT: B8V2ErrorRebootDescription,
            B8ErrorType.WARNING: B8V2ErrorWarningDescription,
        }
        enum_cls = table.get(self.error_type)
        if enum_cls is None:
            return B8V2ErrorFixDescription.NO
        return _enum_or_zero(enum_cls, raw)

    def _parse_sub_work_status(self, raw: int) -> str:
        enum_cls = _SUB_WORK_STATUS_ENUM.get(self.work_status)
        if enum_cls is None:
            return "none"
        try:
            return enum_cls(raw).name.lower()
        except ValueError:
            return "none"


class MessageB8V2Response(MessageResponse):
    """B8 v2 message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize B8 v2 message response."""
        super().__init__(bytearray(message))
        body = MessageB8V2Response.parse_body(
            MessageType(self.message_type),
            super().body,
        )
        if body is not None:
            self.set_body(body)
            self.set_attr()

    @staticmethod
    def parse_body(message_type: MessageType, body: bytearray) -> MessageBody | None:
        """Parse body."""
        if len(body) < _MIN_BODY_LEN or body[0] != ListTypes.AA:
            return None
        selector = body[_SELECTOR]
        if (message_type == MessageType.query and selector == B8V2QueryType.WORK) or (
            message_type == MessageType.notify1 and selector == 0x01
        ):
            return MessageB8V2Body(body)
        return None
