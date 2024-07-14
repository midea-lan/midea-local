"""Midea local B8 message."""

from enum import IntEnum, StrEnum

from midealocal.message import (
    BodyType,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class WorkStatus(IntEnum):
    """Midea B8 work status."""

    CHARGE = 0x01
    WORK = 0x02
    STOP = 0x03
    CHARGING_ON_DOCK = 0x04
    RESERVE_TASK_FINISHED = 0x05
    CHARGE_FINISH = 0x06
    CHARGING_WITH_WIRE = 0x07
    PAUSE = 0x08
    UPDATING = 0x09
    SAVING_MAP = 0x0A
    ERROR = 0x0B
    SLEEP = 0x0C
    CHARGE_PAUSE = 0x0D
    RELOCATE = 0x0E
    ELECTROLYSED_WATER_MAKING = 0x0F
    DUST_COLLECTING = 0x10
    BACK_DUST_COLLECTING = 0x11
    SLEEP_IN_STATION = 0x12


class FunctionType(IntEnum):
    """Midea B8 function type."""

    DUST_BOX_CLEANING = 0x01
    WATER_TANK_CLEANING = 0x02


class ControlType(IntEnum):
    """Midea B8 control type."""

    NONE = 0x0
    MANUAL = 0x1
    AUTO = 0x2


class Moviment(IntEnum):
    """Midea B8 movement."""

    NONE = 0x0
    FORWARD = 0x1
    BACK = 0x2
    LEFT = 0x3
    RIGHT = 0x4


class CleanMode(IntEnum):
    """Midea B8 clean mode."""

    NONE = 0x00
    RANDOM = 0x01
    ARC = 0x02
    EDGE = 0x03
    EMPHASES = 0x04
    SCREW = 0x05
    BED = 0x06
    WIDE_SCREW = 0x07
    AUTO = 0x08
    AREA = 0x09
    ZONE_INDEX = 0x0A
    ZONE_RECT = 0x0B
    PATH = 0x0C


class FanLevel(IntEnum):
    """Midea B8 fan level."""

    OFF = 0x0
    SOFT = 0x1
    NORMAL = 0x2
    HIGH = 0x3
    LOW = 0x4


class WaterLevel(IntEnum):
    """Midea B8 water level."""

    OFF = 0x0
    LOW = 0x1
    NORMAL = 0x2
    HIGH = 0x3


class MopState(StrEnum):
    """Midea B8 mop state."""

    OFF = "off"
    ON = "on"
    LACK_WATER = "lack_water"


class Speed(StrEnum):
    """Midea B8 speed."""

    LOW = "low"
    HIGH = "high"


class ErrorType(IntEnum):
    """Midea B8 error type."""

    NO = 0x00
    CAN_FIX = 0x01
    REBOOT = 0x02
    WARNING = 0x03


class ErrorCanFixDescription(IntEnum):
    """Midea B8 error can fix description."""

    NO = 0x0
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
    FIX_START_IN_FORBID_AREA = 0x0E
    FIX_START_IN_STRONG_MAGNETIC = 0x0F
    FIX_LASER_SENSOR_BLOCKED = 0x10


class ErrorRebootDescription(IntEnum):
    """Midea B8 error reboot description."""

    NO = 0x00
    REBOOT_LASER_COMM_FAIL = 0x01
    REBOOT_ROBOT_COMM_FAIL = 0x02
    REBOOT_INNER_FAIL = 0x03


class ErrorWarningDescription(IntEnum):
    """Midea B8 error warning description."""

    NO = 0x00
    WARN_LOCATION_FAIL = 0x01
    WARN_LOW_BATTERY = 0x02
    WARN_FULL_DUST = 0x03
    WARN_LOW_WATER = 0x04


class StatusType(IntEnum):
    """B8 Status Type."""

    X01 = 0x01


class MessageB8Base(MessageRequest):
    """B8 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: int,
        body_type: int,
    ) -> None:
        """Initialize B8 message base."""
        super().__init__(
            device_type=0xB8,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageB8Base):
    """B8 message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize B8 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=BodyType.X32,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01])


class MessageSet(MessageB8Base):
    """B8 message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize B8 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=0x22,
        )
        self.clean_mode = CleanMode.AUTO
        self.fan_level = FanLevel.NORMAL
        self.water_level = WaterLevel.LOW
        self.voice_volume = 0
        self.zone_id = 0

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                0x02,
                0x02,
                self.clean_mode,
                self.fan_level,
                self.water_level,
                self.voice_volume,
                self.zone_id,
            ]
            + [0x00] * 7,
        )


class MessageB8WorkStatusBody(MessageBody):
    """B8 message work status body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B8 message work status body."""
        super().__init__(body)
        self.work_status = WorkStatus(body[2])
        self.function_type = FunctionType(body[3])
        self.control_type = ControlType(body[4])
        self.move_direction = Moviment(body[5])
        self.clean_mode = CleanMode(body[6])
        self.fan_level = FanLevel(body[7])
        self.area = body[8]
        self.water_level = WaterLevel(body[9])
        self.voice_volume = body[10]
        mop = body[17]
        if mop == 0:
            self.mop = MopState.OFF
        elif mop == 1:
            self.mop = MopState.ON
        else:
            self.mop = MopState.LACK_WATER
        self.carpet_switch = body[18] == 1
        self.speed = Speed.LOW if body[20] == 1 else Speed.HIGH
        self.have_reserve_task = body[11] != 0
        self.battery_percent = body[12]
        self.work_time = body[13]
        err_user_high = body[19]
        status_summary = body[14]
        self.error_type = ErrorType(body[15])
        self.uv_switch = status_summary & 0x01 > 0
        self.wifi_switch = status_summary & 0x02 > 0
        self.voice_switch = status_summary & 0x04 > 0
        self.command_source = status_summary & 0x40 > 0
        self.device_error = status_summary & 0x80 > 0
        self.board_communication_error = err_user_high & 0x4 > 0
        self.laser_sensor_shelter = err_user_high & 0x2 > 0
        self.laser_sensor_error = err_user_high & 0x1 > 0
        self.error_desc: (
            ErrorCanFixDescription
            | ErrorRebootDescription
            | ErrorWarningDescription
            | None
        ) = None
        if self.error_type == ErrorType.CAN_FIX:
            self.error_desc = ErrorCanFixDescription(body[16])
        elif self.error_type == ErrorType.REBOOT:
            self.error_desc = ErrorRebootDescription(body[16])
        elif self.error_type == ErrorType.WARNING:
            self.error_desc = ErrorWarningDescription(body[16])


class MessageB8Response(MessageResponse):
    """B8 message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize B8 message response."""
        super().__init__(bytearray(message))
        body = MessageB8Response.parse_body(
            MessageType(self.message_type),
            super().body,
        )
        if body is not None:
            self.set_body(body)
        self.set_attr()

    @staticmethod
    def parse_body(message_type: MessageType, body: bytearray) -> MessageBody | None:
        """Parse body."""
        body_type = body[0]
        status_type = body[1]
        if (
            message_type == MessageType.query
            and body_type == BodyType.X32
            and status_type == StatusType.X01
        ):
            return MessageB8WorkStatusBody(body)
        return None
