"""Midea local x13 device."""

from midealocal.message import (
    BodyType,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

MAX_EFFECT = 5


class Message13Base(MessageRequest):
    """X13 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: int,
        body_type: int,
    ) -> None:
        """Initialize X13 message base."""
        super().__init__(
            device_type=0x13,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(Message13Base):
    """X13 message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize X13 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=0x24,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x00, 0x00, 0x00, 0x00])


class MessageSet(Message13Base):
    """X13 message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize X13 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=0x00,
        )
        self.brightness: int | None = None
        self.color_temperature: int | None = None
        self.effect: int | None = None
        self.power: bool | None = None

    @property
    def _body(self) -> bytearray:
        body_byte = 0x00
        if self.power is not None:
            self.body_type = 0x01
            body_byte = 0x01 if self.power else 0x00
        elif self.effect is not None and self.effect in range(1, 6):
            self.body_type = 0x02
            body_byte = self.effect + 1
        elif self.color_temperature is not None:
            self.body_type = 0x03
            body_byte = self.color_temperature
        elif self.brightness is not None:
            self.body_type = 0x04
            body_byte = self.brightness
        return bytearray([body_byte, 0x00, 0x00, 0x00])


class MessageMainLightBody(MessageBody):
    """X13 message main light body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize X13 message main light body."""
        super().__init__(body)
        self.brightness = self.read_byte(body, 1)
        self.color_temperature = self.read_byte(body, 2)
        self.effect = self.read_byte(body, 3) - 1
        if self.effect > MAX_EFFECT:
            self.effect = 1
        self.power = self.read_byte(body, 8) > 0


class MessageMainLightResponseBody(MessageBody):
    """X13 message main light response body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize X13 message main light response body."""
        super().__init__(body)
        self.control_success: bool = body[1] > 0


class Message13Response(MessageResponse):
    """X13 message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize X13 message response."""
        super().__init__(bytearray(message))
        if self.body_type == BodyType.A4:
            self.set_body(MessageMainLightBody(super().body))
        elif self.message_type == MessageType.set and self.body_type > BodyType.X80:
            self.set_body(MessageMainLightResponseBody(super().body))
        self.control_success: bool
        self.set_attr()
