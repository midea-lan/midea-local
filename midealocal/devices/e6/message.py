"""Midea local E6 message."""

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)


class MessageE6Base(MessageRequest):
    """E6 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
    ) -> None:
        """Initialize E6 message base."""
        super().__init__(
            device_type=DeviceType.E6,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=ListTypes.X00,
        )

    @property
    def body(self) -> bytearray:
        """E6 message base body."""
        return self._body

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageE6Base):
    """E6 message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize E6 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x01, 0x01] + [0] * 28)


class MessageSet(MessageE6Base):
    """E6 message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize E6 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
        )
        self.main_power: bool | None = None
        self.heating_temperature: float | None = None
        self.bathing_temperature: float | None = None
        self.heating_power: bool | None = None
        self.heating_modes: str | None = None
        self.cold_water_single: bool | None = None
        self.cold_water_dot: bool | None = None

    @property
    def _body(self) -> bytearray:
        body: list[int] = []
        if self.main_power is not None:
            main_power = 0x01 if self.main_power else 0x02
            body = [main_power, 0x01]
        elif self.heating_temperature is not None:
            body = [0x04, 0x13, int(self.heating_temperature)]
        elif self.bathing_temperature is not None:
            body = [0x04, 0x12, int(self.bathing_temperature)]
        elif self.heating_power is not None:
            heating_power = 0x01 if self.heating_power else 0x02
            body = [0x04, 0x01, heating_power]
        elif self.cold_water_single is not None:
            cold_water_single = 0x01 if self.cold_water_single else 0x00
            body = [0x04, 0x1A, cold_water_single]
        elif self.cold_water_dot is not None:
            cold_water_dot = 0x01 if self.cold_water_dot else 0x00
            body = [0x04, 0x1B, cold_water_dot]
        elif self.heating_modes is not None:
            if self.heating_modes == "normal_mode":
                body = [0x04, 0x02, 0x01]
            if self.heating_modes == "out_mode":
                body = [0x04, 0x02, 0x02]
            if self.heating_modes == "home_mode":
                body = [0x04, 0x02, 0x04]
            if self.heating_modes == "sleep_mode":
                body = [0x04, 0x02, 0x08]
        body_len = len(body)
        return bytearray(body + [0] * (30 - body_len))


class E6GeneralMessageBody(MessageBody):
    """E6 message general body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize E6 message general body."""
        super().__init__(body)
        self.main_power = (body[2] & 0x04) > 0
        self.heating_working = (body[2] & 0x10) > 0
        self.bathing_working = (body[2] & 0x20) > 0
        self.heating_power = (body[4] & 0x01) > 0
        self.min_temperature = [float(body[16]), float(body[11])]
        self.max_temperature = [float(body[15]), float(body[10])]
        self.heating_temperature = float(body[17])
        self.bathing_temperature = float(body[12])
        self.heating_leaving_temperature = float(body[14])
        self.bathing_leaving_temperature = float(body[8])
        self.cold_water_single = (body[25] & 0x01) > 0
        self.cold_water_dot = (body[25] & 0x02) > 0
        self.heating_modes = (
            "out_mode"
            if (body[4] & 0x08)
            else "normal_mode"
            if (body[4] & 0x04)
            else "home_mode"
            if (body[4] & 0x10)
            else "sleep_mode"
            if (body[4] & 0x20)
            else "normal_mode"
        )


class MessageE6Response(MessageResponse):
    """E6 message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize E6 message response."""
        super().__init__(bytearray(message))
        self.set_body(E6GeneralMessageBody(super().body))
        self.set_attr()
