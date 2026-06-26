"""Midea local FA message."""

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBit,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

MAX_FAN_SPEED = 26
MAX_TEMPERATURE = 91.0
MIN_DEFAULT = 1
MAX_HUMIDITY = 100
SWING_ANGLE_GET_BYTE = 51
TILTING_ANGLE_SET_BYTE = 24
FA_MESSAGE_PROTOCOL = 5
TEMPERATURE_MIN = -40
TEMPERATURE_MAX = 50


def _parse_temperature(temperature: float) -> float:
    """Process temperature value."""
    return (
        (temperature - 41.0)
        if (temperature >= 1.0 and temperature <= MAX_TEMPERATURE)
        else 0.0
    )


def _check_range(value: int, min_value: int = 1, max_value: int = 100) -> int:
    """Check value range."""
    return value if (value >= min_value and value <= max_value) else 0


class MessageFABase(MessageRequest):
    """FA message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes = ListTypes.X00,
    ) -> None:
        """Initialize the message with protocol version, message type, and body type."""
        super().__init__(
            device_type=DeviceType.FA,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageFABase):
    """Message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize the message with protocol version."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
        )

    @property
    def body(self) -> bytearray:
        """Return an empty bytearray."""
        return bytearray([])

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageNewSet(MessageFABase):
    """Message set(T_0000_FA_560000F3_2023011001.lua)."""

    def __init__(self, protocol_version: int, subtype: int) -> None:
        """Initialize the message with protocol version and subtype."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X00,
        )
        self._subtype = subtype
        self.power: bool | None = None
        self.child_lock: bool | None = None
        self.mode: int | None = None
        self.fan_speed: int | None = None
        self.oscillate: bool | None = None
        self.oscillation_angle: int | None = None
        self.oscillation_mode: int | None = None
        self.tilting_angle: int | None = None
        self.target_temperature: float | None = None
        self.target_humidity: int | None = None

    @property
    def _body(self) -> bytearray:
        # default is 0
        _body_return = bytearray(53)
        # set power/oscillate default value
        MessageBit.set_bit(_body_return, 3, 7, 1)
        MessageBit.set_bit(_body_return, 7, 7, 1)
        # set protocol_version
        _body_return[22] = FA_MESSAGE_PROTOCOL
        # set power
        if self.power is not None:
            MessageBit.set_bit(_body_return, 3, 0, int(self.power))
            MessageBit.set_bit(_body_return, 3, 7, 1)
        # set child_lock
        if self.child_lock is not None:
            if self.child_lock:
                MessageBit.set_bits(_body_return, 2, 0, 1, 1)
            else:
                MessageBit.set_bits(_body_return, 2, 7, 1, 2)
        # set mode, value should be dict key
        if self.mode is not None:
            MessageBit.set_bits(_body_return, 3, 1, 5, self.mode)
        # set gear
        if (
            self.fan_speed is not None
            and MIN_DEFAULT <= self.fan_speed <= MAX_FAN_SPEED
        ):
            _body_return[4] = self.fan_speed
        # set temperature
        if (
            self.target_temperature is not None
            and TEMPERATURE_MIN <= int(self.target_temperature) <= TEMPERATURE_MAX
        ):
            _body_return[5] = int(self.target_temperature)
        # set humidity
        if (
            self.target_humidity is not None
            and MIN_DEFAULT <= int(self.target_humidity) <= MAX_HUMIDITY
        ):
            _body_return[6] = int(self.target_humidity)
        if self.oscillate is not None:
            MessageBit.set_bit(_body_return, 7, 7, int(self.oscillate))
        if self.oscillation_mode is not None:
            MessageBit.set_bits(_body_return, 7, 1, 3, int(self.oscillation_mode))
            MessageBit.set_bit(_body_return, 7, 7, 0)
        if self.oscillation_angle is not None:
            _body_return[50] = (
                self.oscillation_angle // 5 if self.oscillation_angle else 0
            )
        if (
            self.tilting_angle is not None
            and len(_body_return) > TILTING_ANGLE_SET_BYTE
        ):
            _body_return[24] = self.tilting_angle
        return _body_return


class MessageSet(MessageFABase):
    """Message set(T_0000_FA_17.lua)."""

    def __init__(self, protocol_version: int, subtype: int) -> None:
        """Initialize the message with protocol version and subtype."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X00,
        )
        self._subtype = subtype
        self.power: bool | None = None
        self.child_lock: bool | None = None
        self.mode: int | None = None
        self.fan_speed: int | None = None
        self.oscillate: bool | None = None
        self.oscillation_angle: int | None = None
        self.oscillation_mode: int | None = None
        self.tilting_angle: int | None = None

    @property
    def _body(self) -> bytearray:
        if 1 <= self._subtype <= ListTypes.X0A or self._subtype == ListTypes.A1:
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
            if self._subtype != ListTypes.X0A:
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
        if self.child_lock is not None:
            if self.child_lock:
                _body_return[2] = 1
            else:
                _body_return[2] = 2
        if self.mode is not None:
            _body_return[3] = 1 | (((self.mode + 1) << 1) & 0x1E)
        if self.fan_speed is not None and 1 <= self.fan_speed <= MAX_FAN_SPEED:
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
        if (
            self.tilting_angle is not None
            and len(_body_return) > TILTING_ANGLE_SET_BYTE
        ):
            _body_return[24] = self.tilting_angle
        return _body_return


class FAGeneralMessageBody(MessageBody):
    """General message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize the message body."""
        super().__init__(body)
        # use message length to check old and new protocol, can be change if error exist
        # 1. v3 device with FA protocol v5, body[23] == 0x05  # protocol_version
        # 2. v3 device with protocol v5, body length should 52 or 54
        # 3. v2 device with old FA protocol, body length should less than 23
        # parse 1, get protocol version v5 with message length 24
        self.fa_message_protocol = body[23] if len(body) > TILTING_ANGLE_SET_BYTE else 0
        self.error_code = body[1]
        self.voice = body[2]
        self.auto_power_off = MessageBit.get_bit(body, 3, 3)
        self.child_lock = body[3] & 0x03 == 0x01
        self.power = body[4] & 0x01 == 0x01
        self.mode = MessageBit.get_bits(body, 4, 1, 5)
        self.fan_speed = _check_range(body[5], MIN_DEFAULT, MAX_FAN_SPEED)  # gear
        self.target_temerature = _parse_temperature(body[6])
        self.target_humidity = float(_check_range(body[7], MIN_DEFAULT, MAX_HUMIDITY))
        # new protocol v5
        if self.fa_message_protocol == FA_MESSAGE_PROTOCOL:
            # phase 2, v3 device with protocol v5, body length should 52 or 54
            self.oscillation_angle = (
                body[51] if len(body) > SWING_ANGLE_GET_BYTE else 0
            )  # swing_angle
            self.oscillation_mode = MessageBit.get_bits(
                body,
                8,
                1,
                3,
            )  # swing_direction
            # get swing/oscillate result based on oscillation_angle value
            self.oscillate = bool(self.oscillation_angle)  # swing
        # old protocol, keep origin result
        else:
            self.oscillate = (body[8] & 0x01) > 0  # swing
            self.oscillation_angle = (body[8] & 0x70) >> 4  # swing_angle
            self.oscillation_mode = (body[8] & 0x0E) >> 1  # swing_direction
        # ud_swing_angle
        self.tilting_angle = body[25] if self.fa_message_protocol else None
        # humidity
        self.humidify = MessageBit.get_bits(body, 9, 4, 7)
        # anophelifuge
        self.anophelifuge = MessageBit.get_bits(body, 9, 2, 3) == 0x01
        # anion
        self.anion = body[9] & 0x03 == 0x01
        # humidify_feedback
        self.humidify_feedback = (
            _check_range(body[12], MIN_DEFAULT, MAX_HUMIDITY)
            if self.fa_message_protocol
            else None
        )
        # temperature_feedback
        self.temperature_feedback = (
            _parse_temperature(body[13]) if self.fa_message_protocol else None
        )
        # body_feeling_scan
        self.body_feeling_scan = (
            (body[15] == 0x01) if self.fa_message_protocol else None
        )
        self.scene = body[16] if self.fa_message_protocol else None


class MessageFAResponse(MessageResponse):
    """FA response message."""

    def __init__(self, message: bytes) -> None:
        """Initialize the message."""
        super().__init__(bytearray(message))
        if self.message_type in [
            MessageType.query,
            MessageType.set,
            MessageType.notify1,
        ]:
            self.set_body(FAGeneralMessageBody(super().body))
        self.set_attr()
