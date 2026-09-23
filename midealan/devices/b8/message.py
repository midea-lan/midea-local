"""Midea local B8 message."""

from enum import IntEnum

from midealan.const import DeviceType
from midealan.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class B8StatusType(IntEnum):
    """B8 Status Type."""

    X01 = 0x01
    X05 = 0x05


WORK_MODE_WORK = 0x02
CONTROL_TYPE_MANUAL = 0x01
CONTROL_TYPE_AUTO = 0x02
MOVE_DIRECTION_NONE = 0x00
CLEAN_MODE_AUTO = 0x08
FAN_LEVEL_NORMAL = 0x02
WATER_LEVEL_LOW = 0x01
SPEAK_LEVEL_NONE = 0x00
DEFAULT_ZONE_ID = 0


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

    def __init__(
        self,
        protocol_version: int,
        body_type: ListTypes = ListTypes.X32,
        status_type: B8StatusType = B8StatusType.X01,
    ) -> None:
        """Initialize B8 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )
        self.status_type = status_type

    @property
    def _body(self) -> bytearray:
        return bytearray([self.status_type])


class MessageSet(MessageB8Base):
    """B8 message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize B8 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X22,
        )
        self.clean_mode = CLEAN_MODE_AUTO
        self.fan_level = FAN_LEVEL_NORMAL
        self.water_level = WATER_LEVEL_LOW
        self.speak_level = SPEAK_LEVEL_NONE
        self.zone_id = DEFAULT_ZONE_ID

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                0x02,
                0x00,
                CONTROL_TYPE_AUTO,
                MOVE_DIRECTION_NONE,
                self.clean_mode,
                self.fan_level,
                0x00,
                self.water_level,
                self.speak_level,
                self.zone_id,
            ]
            + [0x00] * 6,
        )


class MessageSetCommand(MessageB8Base):
    """B8 message set command."""

    def __init__(
        self,
        protocol_version: int,
        work_mode: int,
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
            ],
        )


class MessageSetMovement(MessageB8Base):
    """B8 message set movement."""

    def __init__(
        self,
        protocol_version: int,
        move_direction: int,
    ) -> None:
        """Initialize B8 message set movement."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X22,
        )
        self.move_direction = move_direction

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                WORK_MODE_WORK,
                0x00,
                CONTROL_TYPE_MANUAL,
                self.move_direction,
            ]
            + [0x00] * 12,
        )


class MessageSetVoiceVolume(MessageB8Base):
    """B8 message set voice volume."""

    def __init__(self, protocol_version: int, voice_volume: int) -> None:
        """Initialize B8 message set voice volume."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X22,
        )
        self.voice_volume = min(max(voice_volume, 0), 100)

    @property
    def _body(self) -> bytearray:
        return bytearray([0x0A, self.voice_volume])


class MessageB8GenericBody(MessageBody):
    """B8 message generic body."""

    def __init__(self, body: bytearray, offset: int, parse_high_error: bool) -> None:
        """Initialize B8 message generic body."""
        super().__init__(body)
        self.work_status = self.read_byte(body, 1 + offset)
        self.function_type = self.read_byte(body, 2 + offset)
        self.control_type = self.read_byte(body, 3 + offset)
        self.move_direction = self.read_byte(body, 4 + offset)
        self.clean_mode = self.read_byte(body, 5 + offset)
        self.fan_level = self.read_byte(body, 6 + offset)
        self.area = self.read_byte(body, 7 + offset)
        self.water_level = self.read_byte(body, 8 + offset)
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

        self.error_type = self.read_byte(body, 14 + offset)
        self.mop = self.read_byte(body, 16 + offset)

        self.carpet_switch = self.read_byte(body, 17 + offset) != 0

        if parse_high_error:
            error_byte = self.read_byte(body, 18 + offset)
            self.laser_sensor_error = (error_byte & 0x01) > 0
            self.laser_sensor_shelter = (error_byte & 0x02) > 0
            self.board_communication_error = (error_byte & 0x04) > 0
            speed_byte = self.read_byte(body, 19 + offset)
        else:
            speed_byte = self.read_byte(body, 18 + offset)

        self.speed = speed_byte
        self.error_desc = self.read_byte(body, 15 + offset)


class MessageB8WorkStatusBody(MessageB8GenericBody):
    """B8 message work status body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B8 message work status body."""
        super().__init__(body, 1, True)


class MessageB8NotifyBody(MessageB8GenericBody):
    """B8 message notify body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B8 message notify body."""
        super().__init__(body, 0, False)


class MessageB8DisturbBody(MessageBody):
    """B8 message disturb body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B8 message disturb body."""
        super().__init__(body)
        self.disturb_switch = self.read_byte(body, 2) != 0
        self.disturb_start_time = (
            f"{self.read_byte(body, 3):02d}:{self.read_byte(body, 4):02d}"
        )
        self.disturb_end_time = (
            f"{self.read_byte(body, 5):02d}:{self.read_byte(body, 6):02d}"
        )


class MessageB8PartsBody(MessageBody):
    """B8 message parts body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B8 message parts body."""
        super().__init__(body)
        self.side_brush_rest_time = self.read_byte(body, 3) << 8 | self.read_byte(
            body,
            2,
        )
        self.side_brush_life_time = self.read_byte(body, 5) << 8 | self.read_byte(
            body,
            4,
        )
        self.filter_net_rest_time = self.read_byte(body, 7) << 8 | self.read_byte(
            body,
            6,
        )
        self.filter_net_life_time = self.read_byte(body, 9) << 8 | self.read_byte(
            body,
            8,
        )
        self.roll_brush_rest_time = self.read_byte(body, 11) << 8 | self.read_byte(
            body,
            10,
        )
        self.roll_brush_life_time = self.read_byte(body, 13) << 8 | self.read_byte(
            body,
            12,
        )


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
        if (
            message_type == MessageType.query
            and body_type == ListTypes.X32
            and status_type == B8StatusType.X05
        ):
            return MessageB8DisturbBody(body)
        if (
            message_type == MessageType.query
            and body_type == ListTypes.X35
            and status_type == B8StatusType.X01
        ):
            return MessageB8PartsBody(body)
        if message_type == MessageType.notify1 and body_type == ListTypes.X42:
            return MessageB8NotifyBody(body)
        return None
