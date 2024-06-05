from ...message import (
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class MessageDBBase(MessageRequest):
    def __init__(
        self, protocol_version: int, message_type: int, body_type: int
    ) -> None:
        super().__init__(
            device_type=0xDB,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageDBBase):
    def __init__(self, protocol_version: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=0x03,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessagePower(MessageDBBase):
    def __init__(self, protocol_version: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=0x02,
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


class MessageStart(MessageDBBase):
    def __init__(self, protocol_version: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=0x02,
        )
        self.start = False
        self.washing_data = bytearray([])

    @property
    def _body(self) -> bytearray:
        if self.start:  # Pause
            return bytearray([0xFF, 0x01]) + self.washing_data
        else:
            # Pause
            return bytearray([0xFF, 0x00])


class DBGeneralMessageBody(MessageBody):
    def __init__(self, body: bytearray) -> None:
        super().__init__(body)
        self.power = body[1] > 0
        self.start = True if body[2] in [2, 6] else False
        self.washing_data = body[3:16]
        self.progress = 0
        self.time_remaining: float | None = None
        for i in range(7):
            if (body[16] & (1 << i)) > 0:
                self.progress = i + 1
                break
        if self.power:
            self.time_remaining = body[17] + (body[18] << 8)


class MessageDBResponse(MessageResponse):
    def __init__(self, message: bytes) -> None:
        super().__init__(bytearray(message))
        if self.message_type in [MessageType.query, MessageType.set] or (
            self.message_type == MessageType.notify1 and self.body_type == 0x04
        ):
            self.set_body(DBGeneralMessageBody(super().body))
        self.set_attr()
