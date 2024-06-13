from midealocal.message import (
    NONE_VALUE,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class MessageFABase(MessageRequest):
    def __init__(
        self,
        protocol_version: int,
        message_type: int,
        body_type: int = NONE_VALUE,
    ) -> None:
        super().__init__(
            device_type=0xFA,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageFABase):
    def __init__(self, protocol_version: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
        )

    @property
    def body(self) -> bytearray:
        return bytearray([])

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageSet(MessageFABase):
    def __init__(self, protocol_version: int, subtype: int) -> None:
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=0x00,
        )
        self._subtype = subtype
        self.power: bool | None = None
        self.lock: bool | None = None
        self.mode: int | None = None
        self.fan_speed: int | None = None
        self.oscillate: bool | None = None
        self.oscillation_angle: int | None = None
        self.oscillation_mode: int | None = None
        self.tilting_angle: int | None = None

    @property
    def _body(self) -> bytearray:
        if 1 <= self._subtype <= 10 or self._subtype == 161:
            _body_return = bytearray(
                [
                    0x00,
                    0x00,
                    0x00,
                    0x80,
                    0x00,
                    0x00,
                    0x00,
                    0x80,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                ],
            )
            if self._subtype != 10:
                _body_return[13] = 0xFF
        else:
            _body_return = bytearray(
                [
                    0x00,
                    0x00,
                    0x00,
                    0x80,
                    0x00,
                    0x00,
                    0x00,
                    0x80,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                    0x00,
                ],
            )
        if self.power is not None:
            if self.power:
                _body_return[3] = 1
            else:
                _body_return[3] = 0
        if self.lock is not None:
            if self.lock:
                _body_return[2] = 1
            else:
                _body_return[2] = 2
        if self.mode is not None:
            _body_return[3] = 1 | (((self.mode + 1) << 1) & 0x1E)
        if self.fan_speed is not None and 1 <= self.fan_speed <= 26:
            _body_return[4] = self.fan_speed
        if self.oscillate is not None:
            if self.oscillate:
                _body_return[7] = 1
            else:
                _body_return[7] = 0
        if self.oscillation_angle is not None:
            _body_return[7] = (
                1 | _body_return[7] | ((self.oscillation_angle << 4) & 0x70)
            )
        if self.oscillation_mode is not None:
            _body_return[7] = (
                1 | _body_return[7] | ((self.oscillation_mode << 1) & 0x0E)
            )
        if self.tilting_angle is not None and len(_body_return) > 24:
            _body_return[24] = self.tilting_angle
        return _body_return


class FAGeneralMessageBody(MessageBody):
    def __init__(self, body: bytearray) -> None:
        super().__init__(body)
        lock = body[3] & 0x03
        if lock == 1:
            self.child_lock = True
        else:
            self.child_lock = False
        self.power = (body[4] & 0x01) > 0
        mode = (body[4] & 0x1E) >> 1
        if mode > 0:
            self.mode = mode - 1
        fan_speed = body[5]
        if 1 <= fan_speed <= 26:
            self.fan_speed = fan_speed
        else:
            self.fan_speed = 0
        self.oscillate = (body[8] & 0x01) > 0
        self.oscillation_angle = (body[8] & 0x70) >> 4
        self.oscillation_mode = (body[8] & 0x0E) >> 1
        self.tilting_angle = body[25] if len(body) > 25 else 0


class MessageFAResponse(MessageResponse):
    def __init__(self, message: bytes) -> None:
        super().__init__(bytearray(message))
        if self.message_type in [
            MessageType.query,
            MessageType.set,
            MessageType.notify1,
        ]:
            self.set_body(FAGeneralMessageBody(super().body))
        self.set_attr()
