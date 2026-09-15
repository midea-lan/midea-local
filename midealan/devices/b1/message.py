"""Midea local B1 message."""

from midealan.const import MAX_BYTE_VALUE, DeviceType
from midealan.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

X01_MODE_OFFSET = 7
X01_TARGET_TEMPERATURE_OFFSET = 14
X01_STATUS_OFFSET = 31
X01_FLAGS_OFFSET = 32
X01_MIN_BODY_LENGTH = X01_FLAGS_OFFSET + 1
X01_TIME_REMAINING_HOURS_OFFSET = 22
X01_TIME_REMAINING_MINUTES_OFFSET = 23
X01_TIME_REMAINING_SECONDS_OFFSET = 24
X01_TEMPERATURE_HIGH_OFFSET = 25
X01_TEMPERATURE_LOW_OFFSET = 26
X01_TEMPERATURE_FALLBACK_HIGH_OFFSET = 27
X01_TEMPERATURE_FALLBACK_LOW_OFFSET = 28


class MessageB1Base(MessageRequest):
    """B1 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize B1 message base."""
        super().__init__(
            device_type=DeviceType.B1,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageB1Base):
    """B1 message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize B1 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageQueryX01(MessageB1Base):
    """B1 message query, X01 body variant.

    Some B1 devices report ``MessageQuery`` (the X00 body) as an
    unsupported protocol and never respond to it at all, leaving the
    device with no working query (the B0 device has this same X00-query
    problem on some models, with X01/X31 fallbacks that work instead).
    This is the equivalent X01 fallback for B1, confirmed against a real
    subtype-zero electric oven to return a response decodable with the
    same byte layout as B0's X01 body (see ``B1Message01Body``).
    """

    def __init__(self, protocol_version: int) -> None:
        """Initialize B1 message query X01."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class B1MessageBody(MessageBody):
    """B1 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize B1 message body."""
        super().__init__(body)
        self.door = (body[16] & 0x02) > 0
        self.status = body[1]
        self.time_remaining = (
            (0 if body[6] == MAX_BYTE_VALUE else body[6]) * 3600
            + (0 if body[7] == MAX_BYTE_VALUE else body[7]) * 60
            + (0 if body[8] == MAX_BYTE_VALUE else body[8])
        )
        self.current_temperature = body[19]
        self.tank_ejected = (body[16] & 0x04) > 0
        self.water_shortage = (body[16] & 0x08) > 0
        self.water_change_reminder = (body[16] & 0x10) > 0


class B1Message01Body(MessageBody):
    """B1 message 01 body.

    Layout confirmed against a real subtype-zero electric oven (model
    711001CJ): identical byte offsets to B0's ``B0Message01Body``, which
    makes sense given the shared appliance-family protocol. The door bit
    is confirmed correct: a physical test that opened the oven door for
    real showed ``door=True`` (open) with no inversion needed - everything
    else (status, time_remaining, temperature, tank/water flags) produced
    sane values matching the device's known idle state.

    ``mode`` and ``target_temperature`` were added from a physical test on
    the same oven, driving the appliance through a full session with a
    pause after every action so each frame maps to exactly one action:

    * switch on with top+bottom heat at 180 degrees - byte 7 goes 0 -> 83,
      byte 14 goes 0 -> 180;
    * change the setpoint to 220 degrees - byte 14 goes 180 -> 220, and
      byte 7 does not move;
    * switch to convection - byte 7 goes 83 -> 84 and byte 14 goes
      220 -> 160 in the same frame, because each programme carries its own
      default temperature;
    * switch off - both go to 0.

    Scrolling the programme dial afterwards produced further codes
    (82, 87, 88, 94, 95, 99, 102, 103, 162, 164), each with its own
    default setpoint, so byte 7 is a programme number rather than a
    bit field. The codes are reported as-is: this is one appliance, and
    guessing a name table from a single model would be worse than
    passing the number through.
    """

    def __init__(self, body: bytearray) -> None:
        """Initialize B1 message 01 body."""
        super().__init__(body)
        if len(body) >= X01_MIN_BODY_LENGTH:
            self.door = (body[X01_FLAGS_OFFSET] & 0x02) > 0
            self.status = body[X01_STATUS_OFFSET]
            self.time_remaining = (
                (
                    0
                    if body[X01_TIME_REMAINING_HOURS_OFFSET] == MAX_BYTE_VALUE
                    else body[X01_TIME_REMAINING_HOURS_OFFSET]
                )
                * 3600
                + (
                    0
                    if body[X01_TIME_REMAINING_MINUTES_OFFSET] == MAX_BYTE_VALUE
                    else body[X01_TIME_REMAINING_MINUTES_OFFSET]
                )
                * 60
                + (
                    0
                    if body[X01_TIME_REMAINING_SECONDS_OFFSET] == MAX_BYTE_VALUE
                    else body[X01_TIME_REMAINING_SECONDS_OFFSET]
                )
            )
            self.current_temperature = (body[X01_TEMPERATURE_HIGH_OFFSET] << 8) + body[
                X01_TEMPERATURE_LOW_OFFSET
            ]
            if self.current_temperature == 0:
                self.current_temperature = (
                    body[X01_TEMPERATURE_FALLBACK_HIGH_OFFSET] << 8
                ) + body[X01_TEMPERATURE_FALLBACK_LOW_OFFSET]
            self.tank_ejected = (body[X01_FLAGS_OFFSET] & 0x04) > 0
            self.water_shortage = (body[X01_FLAGS_OFFSET] & 0x08) > 0
            self.water_change_reminder = (body[X01_FLAGS_OFFSET] & 0x10) > 0
            self.mode = body[X01_MODE_OFFSET]
            self.target_temperature = body[X01_TARGET_TEMPERATURE_OFFSET]


class MessageB1Response(MessageResponse):
    """B1 message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize B1 message response."""
        super().__init__(bytearray(message))
        if self.message_type in [MessageType.notify1, MessageType.query]:
            if self.body_type == ListTypes.X01:
                self.set_body(B1Message01Body(super().body))
            else:
                self.set_body(B1MessageBody(super().body))
        self.set_attr()
