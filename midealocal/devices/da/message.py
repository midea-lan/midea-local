from midealocal.message import (
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class MessageDABase(MessageRequest):
    def __init__(
        self,
        protocol_version: int,
        message_type: int,
        body_type: int,
    ) -> None:
        super().__init__(
            device_type=0xDA,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageDABase):
    def __init__(self, protocol_version: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=0x03,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessagePower(MessageDABase):
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
        return bytearray([power, 0xFF])


class MessageStart(MessageDABase):
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
        if self.start:
            return bytearray([0xFF, 0x01]) + self.washing_data
        else:
            # Stop
            return bytearray([0xFF, 0x00])


class DAGeneralMessageBody(MessageBody):
    def __init__(self, body: bytearray) -> None:
        super().__init__(body)
        self.power = body[1] > 0
        self.start = True if body[2] in [2, 6] else False
        self.error_code = body[24]
        self.program = body[4]
        self.wash_time = body[9]
        self.soak_time = body[12]
        self.dehydration_time = (body[10] & 0xF0) >> 4
        self.dehydration_speed = (body[6] & 0xF0) >> 4
        self.rinse_count = body[10] & 0xF
        self.rinse_level = (body[5] & 0xF0) >> 4
        self.wash_level = body[5] & 0xF
        self.wash_strength = body[6] & 0xF
        self.softener = (body[8] & 0xF0) >> 4
        self.detergent = body[8] & 0x0F
        self.washing_data = body[3:15]
        self.progress = 0
        self.time_remaining: int | None = None
        for i in range(1, 7):
            if (body[16] & (1 << i)) > 0:
                self.progress = i
                break
        if self.power:
            self.time_remaining = body[17] + body[18] * 60


class MessageDAResponse(MessageResponse):
    def __init__(self, message: bytes) -> None:
        super().__init__(bytearray(message))
        if self.message_type in [MessageType.query, MessageType.set] or (
            self.message_type == MessageType.notify1 and self.body_type == 0x04
        ):
            self.set_body(DAGeneralMessageBody(super().body))
        self.set_attr()
