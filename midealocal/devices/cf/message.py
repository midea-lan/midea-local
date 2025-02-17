"""Midea local CF message."""

from enum import IntEnum

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class CFMode(IntEnum):
    """CF Mode."""

    OFF = 0
    AUTO = 1
    COOL = 2
    HEAT = 3


class MessageCFBase(MessageRequest):
    """CF message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize CF message base."""
        super().__init__(
            device_type=DeviceType.CF,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageCFBase):
    """CF message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize CF message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageSet(MessageCFBase):
    """CF message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize CF message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X01,
        )
        self.power = False
        self.mode = 0  # 1 自动 2 制冷 3 制热
        self.target_temperature: float | None = None
        self.aux_heating: bool | None = None

    @property
    def _body(self) -> bytearray:
        power = 0x01 if self.power else 0x00
        mode = self.mode
        target_temperature = (
            0xFF
            if self.target_temperature is None
            else (int(self.target_temperature) & 0xFF)
        )
        aux_heating = (
            0xFF if self.aux_heating is None else (0x01 if self.aux_heating else 0x00)
        )
        return bytearray([power, mode, target_temperature, aux_heating])


class CFMessageBody(MessageBody):
    """CF message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize CF message body."""
        super().__init__(body)
        self.power = (body[data_offset + 0] & 0x01) > 0  # power_state
        self.aux_heating = (body[data_offset + 0] & 0x02) > 0  # pre_heat
        self.silent = (body[data_offset + 0] & 0x04) > 0  # silence_set_state
        self.heat = (body[data_offset + 1] & 0x01) > 0  # heat_enable
        self.cool = (body[data_offset + 1] & 0x02) > 0  # cool_enable
        self.temp_type = (body[data_offset + 1] & 0x04) > 0  # temp_type
        self.room_temp_ctrl = (body[data_offset + 1] & 0x08) > 0  # room_temp_ctrl
        self.room_temp_set = (body[data_offset + 1] & 0x10) > 0  # room_temp_set
        self.comp = (body[data_offset + 2] & 0x01) > 0  # comp_state
        self.warn = (body[data_offset + 2] & 0x10) > 0  # warn_state
        self.defrost = (body[data_offset + 2] & 0x20) > 0  # defrost_state
        self.freeze = (body[data_offset + 2] & 0x40) > 0  # freeze_state
        self.holiday = (body[data_offset + 2] & 0x80) > 0  # holiday_state
        self.mode = body[data_offset + 3]  # run_mode
        self.target_temperature = body[data_offset + 4]  # temp_set
        self.current_temperature = body[data_offset + 5]  # cur_temp
        if self.mode == CFMode.COOL:
            self.max_temperature = body[data_offset + 8]
            self.min_temperature = body[data_offset + 9]
        elif self.mode == CFMode.HEAT:
            self.max_temperature = body[data_offset + 6]
            self.min_temperature = body[data_offset + 7]
        else:
            self.max_temperature = body[data_offset + 6]
            self.min_temperature = body[data_offset + 9]


class MessageCFResponse(MessageResponse):
    """CF message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize CF message body."""
        super().__init__(bytearray(message))
        if (
            self.message_type in [MessageType.query, MessageType.set]
            and self.body_type == ListTypes.X01
        ):
            self.set_body(CFMessageBody(super().body, data_offset=1))
        elif self.message_type in [MessageType.notify1, MessageType.notify2]:
            self.set_body(CFMessageBody(super().body, data_offset=0))
        self.set_attr()
