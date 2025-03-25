"""Midea local AD message."""

from midealocal.const import DeviceType
from midealocal.crc8 import calculate
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

MAX_MSG_SERIAL_NUM = 254


class MessageADBase(MessageRequest):
    """AD message base."""

    _message_serial = 0

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize AD message base."""
        super().__init__(
            device_type=DeviceType.AD,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )
        MessageADBase._message_serial += 1
        if MessageADBase._message_serial >= MAX_MSG_SERIAL_NUM:
            MessageADBase._message_serial = 1
        self._message_id = MessageADBase._message_serial

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError

    @property
    def body(self) -> bytearray:
        """AD message base body."""
        body = bytearray([self.body_type]) + self._body + bytearray([self._message_id])
        body.append(calculate(body))
        return body


class Message21Query(MessageADBase):
    """AD X21 message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AD X21 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X21,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                0x01,
            ],
        )


class Message31Query(MessageADBase):
    """AD X31 message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AD X31 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X31,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                0x01,
            ],
        )


class X31MessageBody(MessageBody):
    """AD X31 message general body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AD X31 message general body."""
        super().__init__(body)
        self.screen_status = body[2] > 0 if body[2] != ListTypes.FF else None
        self.led_status = body[3] > 0 if body[3] != ListTypes.FF else None
        self.arofene_link = body[4] > 0 if body[4] != ListTypes.FF else None
        self.header_exist = body[5] > 0 if body[5] != ListTypes.FF else None
        self.radar_exist = body[6] > 0 if body[6] != ListTypes.FF else None
        self.header_led_status = body[7] > 0 if body[7] != ListTypes.FF else None
        self.temperature_raw = (
            (body[8] << 8) + body[9] if body[8] != ListTypes.FF else None
        )
        self.humidity_raw = (
            (body[10] << 8) + body[11] if body[10] != ListTypes.FF else None
        )
        self.temperature_compensate = (
            (body[12] << 8) + body[13] if body[1] > ListTypes.X0D else None
        )
        self.humidity_compensate = (
            (body[14] << 8) + body[15] if body[1] > ListTypes.X0D else None
        )


class X21MessageBody(MessageBody):
    """AD X21 message general body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AD X21 message general body."""
        super().__init__(body)
        self.portable_sense = body[2] > 0
        self.night_mode = body[3] > 0
        self.screen_extinction_timeout = body[4] if (body[4] != ListTypes.FF) else None


class ADNotifyMessageBody(MessageBody):
    """AD message notify body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AD message notify body."""
        super().__init__(body)
        if body[1] == 0x01:
            self.temperature = (
                ((((body[3] << 8) + body[4]) - 65535) - 1) / 100
                if body[3] >= ListTypes.X80  # >= 128
                else ((body[3] << 8) + body[4]) / 100
            )
            self.humidity = (
                ((body[5] << 8) + body[6]) / 100 if body[5] != ListTypes.FF else None
            )
            self.tvoc = ((body[7] << 8) + body[8]) if body[7] != ListTypes.FF else None
            self.pm25 = ((body[9] << 8) + body[10]) if body[9] != ListTypes.FF else None
            self.co2 = (
                ((body[11] << 8) + body[12]) if body[11] != ListTypes.FF else None
            )
            self.hcho = (
                ((body[13] << 8) + body[14]) / 0.1 if body[13] != ListTypes.FF else None
            )
            self.arofene_link = (
                ((body[16] & 0x01) > 0) if body[16] != ListTypes.FF else None
            )
            self.radar_exist = (
                ((body[16] & 0x02) > 0) if body[16] != ListTypes.FF else None
            )
        elif body[1] == ListTypes.X04:
            if body[3] == ListTypes.X01:
                self.presets_function = body[4] == 0x01
            elif body[3] == ListTypes.X02:
                self.fall_asleep_status = body[4] == 0x01


class MessageADResponse(MessageResponse):
    """AD message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize AD message response."""
        super().__init__(bytearray(message))

        if self._body_type == ListTypes.X11:
            self.set_body(ADNotifyMessageBody(super().body))
        elif self._body_type == ListTypes.X21:
            self.set_body(X21MessageBody(super().body))
        elif self._body_type == ListTypes.X31:
            self.set_body(X31MessageBody(super().body))
        self.set_attr()
