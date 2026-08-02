"""Midea local B8 message."""

from enum import IntEnum

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class B8WorkMode(IntEnum):
    """Midea B8 work mode."""

    CHARGE = 0x01
    WORK = 0x02
    STOP = 0x03
    PAUSE = 0x1B


class B8WorkStatus(IntEnum):
    """Midea B8 work status."""

    NONE = 0x00
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


class B8FunctionType(IntEnum):
    """Midea B8 function type."""

    NONE = 0x00
    DUST_BOX_CLEANING = 0x01
    WATER_TANK_CLEANING = 0x02


class B8ControlType(IntEnum):
    """Midea B8 control type."""

    NONE = 0x0
    MANUAL = 0x1
    AUTO = 0x2


class B8Moviment(IntEnum):
    """Midea B8 movement."""

    NONE = 0x0
    FORWARD = 0x1
    BACK = 0x2
    LEFT = 0x3
    RIGHT = 0x4


class B8CleanMode(IntEnum):
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


class B8FanLevel(IntEnum):
    """Midea B8 fan level."""

    OFF = 0x0
    SOFT = 0x1
    NORMAL = 0x2
    HIGH = 0x3
    LOW = 0x4


class B8WaterLevel(IntEnum):
    """Midea B8 water level."""

    OFF = 0x0
    LOW = 0x1
    NORMAL = 0x2
    HIGH = 0x3


class B8MopState(IntEnum):
    """Midea B8 mop state."""

    OFF = 0x0
    ON = 0x1
    LACK_WATER = 0x2


class B8Speed(IntEnum):
    """Midea B8 speed."""

    LOW = 0x1
    HIGH = 0x0


class B8ErrorType(IntEnum):
    """Midea B8 error type."""

    NO = 0x00
    CAN_FIX = 0x01
    REBOOT = 0x02
    WARNING = 0x03


class B8ErrorCanFixDescription(IntEnum):
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


class B8ErrorRebootDescription(IntEnum):
    """Midea B8 error reboot description."""

    NO = 0x00
    REBOOT_LASER_COMM_FAIL = 0x01
    REBOOT_ROBOT_COMM_FAIL = 0x02
    REBOOT_INNER_FAIL = 0x03


class B8ErrorWarningDescription(IntEnum):
    """Midea B8 error warning description."""

    NO = 0x00
    WARN_LOCATION_FAIL = 0x01
    WARN_LOW_BATTERY = 0x02
    WARN_FULL_DUST = 0x03
    WARN_LOW_WATER = 0x04


class B8StatusType(IntEnum):
    """B8 Status Type."""

    X01 = 0x01


class MessageB8Base(MessageRequest):
    """B8 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize B8 message base."""
        super().__init__(
            device_type=DeviceType.B8,
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
            body_type=ListTypes.X32,
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
            body_type=ListTypes.X22,
        )
        self.clean_mode = B8CleanMode.AUTO
        self.fan_level = B8FanLevel.NORMAL
        self.water_level = B8WaterLevel.LOW
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


class MessageSetCommand(MessageB8Base):
    """B8 message set command."""

    def __init__(
        self,
        protocol_version: int,
        work_mode: B8WorkMode,
    ) -> None:
        """Initialize B8 message set command."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X22,
        )
        self.work_mode = work_mode

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                self.work_mode,
                0x00,
                0x00,
            ],
        )


class MessageB8GenericBody(MessageBody):
    """B8 message generic body."""

    def __init__(self, body: bytearray, offset: int) -> None:
        """Initialize B8 message generic body."""
        super().__init__(body)
        try:
            self.work_status = B8WorkStatus(self.read_byte(body, 1 + offset))
        except ValueError:
            self.work_status = B8WorkStatus.NONE
        try:
            self.function_type = B8FunctionType(self.read_byte(body, 2 + offset))
        except ValueError:
            self.function_type = B8FunctionType.NONE
        try:
            self.control_type = B8ControlType(self.read_byte(body, 3 + offset))
        except ValueError:
            self.control_type = B8ControlType.NONE
        try:
            self.move_direction = B8Moviment(self.read_byte(body, 4 + offset))
        except ValueError:
            self.move_direction = B8Moviment.NONE
        try:
            self.clean_mode = B8CleanMode(self.read_byte(body, 5 + offset))
        except ValueError:
            self.clean_mode = B8CleanMode.NONE
        try:
            self.fan_level = B8FanLevel(self.read_byte(body, 6 + offset))
        except ValueError:
            self.fan_level = B8FanLevel.OFF
        self.area = self.read_byte(body, 7 + offset)
        try:
            self.water_level = B8WaterLevel(self.read_byte(body, 8 + offset))
        except ValueError:
            self.water_level = B8WaterLevel.OFF
        self.voice_volume = min(self.read_byte(body, 9 + offset), 100)
        self.have_reserve_task = self.read_byte(body, 10 + offset) != 0
        self.battery_percent = min(self.read_byte(body, 11 + offset), 100)
        self.work_time = self.read_byte(body, 12 + offset)

        status_byte = self.read_byte(body, 13 + offset)
        self.uv_switch = (status_byte & 0x01) > 0
        self.wifi_switch = (status_byte & 0x02) > 0
        self.voice_switch = (status_byte & 0x04) > 0
        self.command_source = (status_byte & 0x40) > 0
        self.device_error = (status_byte & 0x80) > 0

        try:
            self.error_type = B8ErrorType(self.read_byte(body, 14 + offset))
        except ValueError:
            self.error_type = B8ErrorType.NO

        try:
            self.mop = B8MopState(self.read_byte(body, 16 + offset))
        except ValueError:
            self.mop = B8MopState.LACK_WATER

        self.carpet_switch = self.read_byte(body, 17 + offset) != 0

        error_byte = self.read_byte(body, 18 + offset)
        self.laser_sensor_error = (error_byte & 0x01) > 0
        self.laser_sensor_shelter = (error_byte & 0x02) > 0
        self.board_communication_error = (error_byte & 0x04) > 0

        try:
            self.speed = B8Speed(self.read_byte(body, 19 + offset))
        except ValueError:
            self.speed = B8Speed.HIGH

        self.error_desc: (
            B8ErrorCanFixDescription
            | B8ErrorRebootDescription
            | B8ErrorWarningDescription
        ) = B8ErrorCanFixDescription.NO
        if self.error_type == B8ErrorType.CAN_FIX:
            self.error_desc = B8ErrorCanFixDescription(
                self.read_byte(body, 15 + offset),
            )
        elif self.error_type == B8ErrorType.REBOOT:
            self.error_desc = B8ErrorRebootDescription(
                self.read_byte(body, 15 + offset),
            )
        elif self.error_type == B8ErrorType.WARNING:
            self.error_desc = B8ErrorWarningDescription(
                self.read_byte(body, 15 + offset),
            )


class MessageB8WorkStatusBody(MessageB8GenericBody):
    """B8 message work status body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B8 message work status body."""
        super().__init__(body, 1)


class MessageB8NotifyBody(MessageB8GenericBody):
    """B8 message notify body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B8 message notify body."""
        super().__init__(body, 0)


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
            and body_type == ListTypes.X32
            and status_type == B8StatusType.X01
        ):
            return MessageB8WorkStatusBody(body)
        if message_type == MessageType.notify1 and body_type == ListTypes.X42:
            return MessageB8NotifyBody(body)
        return None
