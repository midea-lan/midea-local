from ...message import (
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class MessageCFBase(MessageRequest):
    def __init__(
        self, protocol_version: int, message_type: int, body_type: int
    ) -> None:
        super().__init__(
            device_type=0xCF,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageCFBase):
    def __init__(self, protocol_version: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=0x01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageSet(MessageCFBase):
    def __init__(self, protocol_version: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=0x01,
        )
        self.power = False
        self.mode = 0  # 1 自动 2 制冷 3 制热
        self.target_temperature: int | None = None
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
    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        super().__init__(body)
        self.power = (body[data_offset + 0] & 0x01) > 0
        self.aux_heating = (body[data_offset + 0] & 0x02) > 0
        self.silent = (body[data_offset + 0] & 0x04) > 0
        self.mode = body[data_offset + 3]
        self.target_temperature = body[data_offset + 4]
        self.current_temperature = body[data_offset + 5]
        if self.mode == 2:
            self.max_temperature = body[data_offset + 8]
            self.min_temperature = body[data_offset + 9]
        elif self.mode == 3:
            self.max_temperature = body[data_offset + 6]
            self.min_temperature = body[data_offset + 7]
        else:
            self.max_temperature = body[data_offset + 6]
            self.min_temperature = body[data_offset + 9]


class MessageCFResponse(MessageResponse):
    def __init__(self, message: bytes) -> None:
        super().__init__(bytearray(message))
        if (
            self.message_type in [MessageType.query, MessageType.set]
            and self.body_type == 0x01
        ):
            self.set_body(CFMessageBody(super().body, data_offset=1))
        elif self.message_type in [MessageType.notify1, MessageType.notify2]:
            self.set_body(CFMessageBody(super().body, data_offset=0))
        self.set_attr()
