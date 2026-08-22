"""Midea local A1 device message."""

from enum import IntEnum

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.crc8 import calculate
from midealocal.message import (
    BoolParser,
    FloatParser,
    IntParser,
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
    NewProtocolMessageBody,
)

MAX_MSG_SERIAL_NUM = 100
MIN_TARGET_HUMIDITY = 35
MIN_FAN_SPEED = 5


class NewProtocolTags(IntEnum):
    """New protocol tags."""

    light = 0x005B


class MessageA1Base(MessageRequest):
    """Message A1 Base."""

    _message_serial = 0

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize message A1 base."""
        super().__init__(
            device_type=DeviceType.A1,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )
        MessageA1Base._message_serial += 1
        if MessageA1Base._message_serial >= MAX_MSG_SERIAL_NUM:
            MessageA1Base._message_serial = 1
        self._message_id = MessageA1Base._message_serial

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError

    @property
    def body(self) -> bytearray:
        """Message A1 base body."""
        body = bytearray([self.body_type]) + self._body + bytearray([self._message_id])
        body.append(calculate(body))
        return body


class MessageQuery(MessageA1Base):
    """Message A1 query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize message A1 query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                0x81,
                0x00,
                0xFF,
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


class MessageNewProtocolQuery(MessageA1Base):
    """Message A1 new protocol query."""

    def __init__(self, protocol_version: ProtocolVersion) -> None:
        """Initialize message A1 new protocol query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.B1,
        )

    @property
    def _body(self) -> bytearray:
        query_params = [NewProtocolTags.light]
        _body = bytearray([len(query_params)])
        for param in query_params:
            _body.extend([param & 0xFF, param >> 8])
        return _body


class MessageSet(MessageA1Base):
    """Message A1 set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize message A1 set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X48,
        )
        self.power = False
        self.prompt_tone = False
        self.mode = 1
        self.fan_speed = 40
        self.child_lock = False
        self.target_humidity = 40
        self.swing = False
        self.anion = False
        self.pump = False
        self.pump_enable = False
        self.water_level_set = 50

    @property
    def _body(self) -> bytearray:
        # byte1, power, prompt_tone
        power = 0x01 if self.power else 0x00
        prompt_tone = 0x40 if self.prompt_tone else 0x00
        # byte2 mode
        mode = self.mode
        # byte3 fan_speed
        fan_speed = self.fan_speed
        # byte7 target_humidity
        target_humidity = self.target_humidity
        # byte8 child_lock
        child_lock = 0x80 if self.child_lock else 0x00
        # byte9 anion, pump, pump enable
        anion = 0x40 if self.anion else 0x00
        pump = 0x08 if self.pump else 0x00
        pump_enable = 0x10 if self.pump_enable else 0x00
        # byte10 swing
        swing = 0x08 if self.swing else 0x00
        # byte 13 water_level_set
        water_level_set = self.water_level_set
        return bytearray(
            [
                power | prompt_tone | 0x02,
                mode,
                fan_speed,
                0x00,
                0x00,
                0x00,
                target_humidity,
                child_lock,
                anion | pump | pump_enable,
                swing,
                0x00,
                0x00,
                water_level_set,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )


class MessageNewProtocolSet(MessageA1Base):
    """Message A1 new protocol set."""

    def __init__(self, protocol_version: ProtocolVersion) -> None:
        """Initialize message A1 new protocol set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.B0,
        )
        self.light: bool | None = None

    @property
    def _body(self) -> bytearray:
        pack_count = 0
        payload = bytearray([0x00])
        if self.light is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.light,
                    value=bytearray([0x01 if self.light else 0x00]),
                ),
            )
        payload[0] = pack_count
        return payload


class A1GeneralMessageBody(MessageBody):
    """A1 general message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize A1 general message body."""
        super().__init__(
            body,
            [
                BoolParser("power", 1, 0),
                IntParser("mode", 2, 0x0F, transform_func=lambda x: x & 0x0F),
                IntParser(
                    "fan_speed",
                    3,
                    0x7F,
                    transform_func=lambda x: (
                        (x & 0x7F) if (x & 0x7F) >= MIN_FAN_SPEED else 1
                    ),
                ),
                IntParser("target_humidity", 7, min_value=MIN_TARGET_HUMIDITY),
                BoolParser("child_lock", 8, 7),
                BoolParser("anion", 9, 6),
                BoolParser("pump", 9, 3),
                BoolParser("pump_enable", 9, 4),
                IntParser("tank", 10, 0x7F, transform_func=lambda x: x & 0x7F),
                IntParser("water_level_set", 15),
                IntParser("current_humidity", 16),
                FloatParser(
                    "current_temperature",
                    17,
                    transform_func=lambda x: (x - 50) / 2,
                ),
                BoolParser("swing", 19, 5),
                BoolParser("filter_cleaning_reminder", 9, 7),
            ],
        )


class A1NewProtocolMessageBody(NewProtocolMessageBody):
    """A1 new protocol message body."""

    def __init__(self, body: bytearray, bt: int) -> None:
        """Initialize A1 new protocol message body."""
        super().__init__(body, bt)
        params = self.parse()
        if NewProtocolTags.light in params:
            self.light = params[NewProtocolTags.light][0] > 0


class MessageA1Response(MessageResponse):
    """A1 message response."""

    def __init__(self, message: bytearray) -> None:
        """Initialize A1 message response."""
        super().__init__(message)
        if self.message_type in [
            MessageType.query,
            MessageType.set,
            MessageType.notify1,
        ]:
            if self.body_type in [ListTypes.B0, ListTypes.B1, ListTypes.B5]:
                self.set_body(A1NewProtocolMessageBody(super().body, self.body_type))
            else:
                self.set_body(A1GeneralMessageBody(super().body))
        elif (
            self.message_type == MessageType.notify2 and self.body_type == ListTypes.A0
        ):
            self.set_body(A1GeneralMessageBody(super().body))
        self.set_attr()
