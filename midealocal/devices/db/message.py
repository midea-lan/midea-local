"""Midea local DB message."""

from collections.abc import Mapping

from midealocal.const import DeviceType
from midealocal.message import (
    FunctionParser,
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

CONTROL_DATA_SIZE = 21
CONTROL_DATA_FILL = 0xFF
CONTROL_PROGRAM_OFFSET = 3
CONTROL_WATER_LEVEL_OFFSET = 4
CONTROL_DRYER_OFFSET = 5
CONTROL_TEMPERATURE_OFFSET = 6
CONTROL_DEHYDRATION_SPEED_OFFSET = 7
CONTROL_WASH_TIME_OFFSET = 8
CONTROL_DEHYDRATION_TIME_OFFSET = 9
CONTROL_DETERGENT_OFFSET = 10
CONTROL_SOFTENER_OFFSET = 11
CONTROL_OPTIONS_OFFSET = 15
DRYER_MASK = 0x0F
DRYER_UNCHANGED_SOAK_COUNT = 0xF0
STEAM_WASH_BIT = 4
FAST_CLEAN_WASH_BIT = 5
OPTIONS_COMMON_MASK = 0x3F
CONTROL_SOAK_BIT = 6


class MessageDBBase(MessageRequest):
    """DB message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize DB message base."""
        super().__init__(
            device_type=DeviceType.DB,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageDBBase):
    """DB message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize DB message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X03,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessagePower(MessageDBBase):
    """DB message power."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize DB message power."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X02,
        )
        self.power = False

    @property
    def _body(self) -> bytearray:
        power = 0x01 if self.power else 0x00
        return bytearray(
            [
                power,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
                0xFF,
            ],
        )


class MessageSet(MessageDBBase):
    """Update wash parameters without changing power or work status."""

    def __init__(
        self,
        protocol_version: int,
        parameters: Mapping[int, int] | None = None,
    ) -> None:
        """Initialize DB parameter control."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X02,
        )
        self.parameters = dict(parameters) if parameters is not None else {}

    @property
    def _body(self) -> bytearray:
        # lua/db/T_0000_DB_33.lua jsonToData: 22-byte control body;
        # omitted power/control_status and unchanged parameters stay 0xFF.
        body = bytearray([CONTROL_DATA_FILL] * CONTROL_DATA_SIZE)
        for offset, value in self.parameters.items():
            body[offset] = value
        return body


class MessageStart(MessageDBBase):
    """DB message start."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize DB message start."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X02,
        )
        self.start = False
        self.washing_data = bytearray([])

    @property
    def _body(self) -> bytearray:
        if self.start:  # Pause
            return bytearray([0xFF, 0x01]) + self.washing_data
        # Pause
        return bytearray([0xFF, 0x00])


class DBGeneralMessageBody(MessageBody):
    """DB message general body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize DB message general body."""
        # DB_33: response byte 25 bits 0-5 map to control byte 16;
        # soak comes from response byte 29 bit 0, not byte 25 bit 6.
        super().__init__(
            body,
            [
                FunctionParser[int | None](
                    "dryer",
                    6,
                    lambda data: data[0] & DRYER_MASK,
                    None,
                ),
                FunctionParser[bool | None](
                    "steam_wash",
                    25,
                    lambda data: bool(data[0] & (1 << STEAM_WASH_BIT)),
                    None,
                ),
                FunctionParser[bool | None](
                    "fast_clean_wash",
                    25,
                    lambda data: bool(data[0] & (1 << FAST_CLEAN_WASH_BIT)),
                    None,
                ),
                FunctionParser[int | None](
                    "control_options",
                    25,
                    lambda data: (
                        (data[0] & OPTIONS_COMMON_MASK)
                        | ((data[4] & 0x01) << CONTROL_SOAK_BIT)
                    ),
                    None,
                    length_in_bytes=5,
                ),
            ],
        )
        self.power = body[1] > 0
        self.start = body[2] in [2, 6]
        self.status = body[2]
        self.mode = body[3]
        self.program = body[4]
        self.water_level = body[5]
        self.temperature = body[7]
        self.dehydration_speed = body[8]
        self.wash_time = body[9]
        self.dehydration_time = body[10]
        self.detergent = body[11]
        self.softener = body[12]
        self.progress = 0
        # progress
        for i in range(7):
            if (body[16] & (1 << i)) > 0:
                self.progress = i + 1
                break
        self.stains = body[26]
        self.wash_time_value = body[27]
        self.dehydration_time_value = body[28]
        self.dirty_degree = body[30]
        self.time_remaining: float | None = None
        if self.power:
            self.time_remaining = body[17] + (body[18] << 8)


class MessageDBResponse(MessageResponse):
    """DB message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize DB message response."""
        super().__init__(bytearray(message))
        if self.message_type in [MessageType.query, MessageType.set] or (
            self.message_type == MessageType.notify1 and self.body_type == ListTypes.X04
        ):
            self.set_body(DBGeneralMessageBody(super().body))
        self.set_attr()
