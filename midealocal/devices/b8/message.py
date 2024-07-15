"""Midea local B8 message."""

from midealocal.devices.b8.const import (
    B8CleanMode,
    B8ControlType,
    B8ErrorCanFixDescription,
    B8ErrorRebootDescription,
    B8ErrorType,
    B8ErrorWarningDescription,
    B8FanLevel,
    B8FunctionType,
    B8MopState,
    B8Moviment,
    B8Speed,
    B8StatusType,
    B8WaterLevel,
    B8WorkStatus,
)
from midealocal.message import (
    BodyType,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


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


class MessageB8WorkStatusBody(MessageBody):
    """B8 message work status body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B8 message work status body."""
        super().__init__(body)
        self.work_status = B8WorkStatus(body[2])
        self.function_type = B8FunctionType(body[3])
        self.control_type = B8ControlType(body[4])
        self.move_direction = B8Moviment(body[5])
        self.clean_mode = B8CleanMode(body[6])
        self.fan_level = B8FanLevel(body[7])
        self.area = body[8]
        self.water_level = B8WaterLevel(body[9])
        self.voice_volume = body[10]
        mop = body[17]
        if mop == 0:
            self.mop = B8MopState.OFF
        elif mop == 1:
            self.mop = B8MopState.ON
        else:
            self.mop = B8MopState.LACK_WATER
        self.carpet_switch = body[18] == 1
        self.speed = B8Speed.LOW if body[20] == 1 else B8Speed.HIGH
        self.have_reserve_task = body[11] != 0
        self.battery_percent = body[12]
        self.work_time = body[13]
        err_user_high = body[19]
        status_summary = body[14]
        self.error_type = B8ErrorType(body[15])
        self.uv_switch = status_summary & 0x01 > 0
        self.wifi_switch = status_summary & 0x02 > 0
        self.voice_switch = status_summary & 0x04 > 0
        self.command_source = status_summary & 0x40 > 0
        self.device_error = status_summary & 0x80 > 0
        self.board_communication_error = err_user_high & 0x4 > 0
        self.laser_sensor_shelter = err_user_high & 0x2 > 0
        self.laser_sensor_error = err_user_high & 0x1 > 0
        self.error_desc: (
            B8ErrorCanFixDescription
            | B8ErrorRebootDescription
            | B8ErrorWarningDescription
            | None
        ) = None
        if self.error_type == B8ErrorType.CAN_FIX:
            self.error_desc = B8ErrorCanFixDescription(body[16])
        elif self.error_type == B8ErrorType.REBOOT:
            self.error_desc = B8ErrorRebootDescription(body[16])
        elif self.error_type == B8ErrorType.WARNING:
            self.error_desc = B8ErrorWarningDescription(body[16])


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
            and status_type == B8StatusType.X01
        ):
            return MessageB8WorkStatusBody(body)
        return None
