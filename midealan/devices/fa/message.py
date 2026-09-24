"""Midea local FA message."""

from midealan.const import DeviceType
from midealan.message import (
    ListTypes,
    MessageBit,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

MAX_FAN_SPEED = 26
MAX_V6_FAN_SPEED = 100
MIN_VALUE = 1
MAX_HUMIDITY = 100
MIN_TEMPERATURE = -40
MAX_TEMPERATURE = 50
MAX_ENCODED_TEMPERATURE = 91
SPECIAL_TEMPERATURE = 0x80
TEMPERATURE_OFFSET = 41
FA_MESSAGE_PROTOCOL = 5
FA_MESSAGE_PROTOCOL_V6 = 6
FA_MESSAGE_PROTOCOLS = frozenset({FA_MESSAGE_PROTOCOL, FA_MESSAGE_PROTOCOL_V6})
MAX_SWING_ANGLE = 1275
V6_DEFAULT_SWING_ANGLE = "default"
V6_DEFAULT_SWING_ANGLE_CODE = 0xFE
V6_INVALID_SWING_ANGLE_CODE = 0xFF
V6_MAX_NORMAL_SWING_ANGLE = V6_DEFAULT_SWING_ANGLE_CODE * 5 - 1
LEGACY_MODE_END_BIT = 4
NEW_PROTOCOL_MODE_END_BIT = 5

LEGACY_TILTING_ANGLE_GET_BYTE = 25
LEGACY_TILTING_ANGLE_SET_BYTE = 24
LEGACY_VOICE_SET_INDEX = 1
LEGACY_TEMPERATURE_SET_INDEX = 5
LEGACY_HUMIDITY_SET_INDEX = 6
LEGACY_HUMIDIFY_SET_INDEX = 8
LEGACY_BODY_FEELING_SCAN_SET_INDEX = 14
LEGACY_SCENE_SET_INDEX = 15
BODY_FEELING_SCAN_GET_BYTE = 15
SCENE_GET_BYTE = 16
LEGACY_HUMIDIFY_GET_BYTE = 9
LEGACY_DISPLAY_GET_BYTE = 19
LEGACY_DISPLAY_SET_BYTE = 18
LEGACY_WATERIONS_GET_BYTE = 34
LEGACY_WATERIONS_SET_BYTE = 33

NEW_PROTOCOL_BODY_LENGTH = 52
NEW_PROTOCOL_VERSION_BYTE = 23
NEW_PROTOCOL_TILTING_ANGLE_BYTE = 25
NEW_PROTOCOL_SWING_BYTE = 8
NEW_PROTOCOL_HUMIDIFY_BYTE = 9
NEW_PROTOCOL_DISPLAY_BYTE = 19
NEW_PROTOCOL_AUTO_POWER_OFF_BYTE = 24
NEW_PROTOCOL_WATERIONS_BYTE = 34
NEW_PROTOCOL_SWING_ANGLE_BYTE = 51
CB4_PROTOCOL_BODY_LENGTH = 54
CB4_PROTOCOL_INVALID_BODY_BYTES = (38, 45, 52, 53)

V6_PROTOCOL_BODY_LENGTH = 63
V6_PROTOCOL_SWING_BYTE = 35
V6_PROTOCOL_TILTING_ANGLE_BYTE = 25
V6_PROTOCOL_SWING_ANGLE_BYTE = 51
V6_PROTOCOL_INVALID_BODY_BYTES = (
    25,
    26,
    27,
    28,
    29,
    38,
    45,
    46,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    62,
)
V6_SWING_TYPE_DIY = 1
V6_SWING_TYPE_NORMAL = 2
V6_SWING_MODE_CODES = {
    1: 2,
    2: 2 << 2,
    6: (2 << 2) | 2,
    7: 1,
}
SWING_MODE_OFF = 0
SWING_MODE_OSCILLATION = 1
SWING_MODE_TILTING = 2
SWING_MODE_BOTH = 6
SWING_MODE_CUSTOM = 7

VOICE_CODES = {
    0x00: "invalid",
    0x01: "open_gps",
    0x02: "close_gps",
    0x04: "open_buzzer",
    0x05: "open_tip",
    0x08: "close_buzzer",
    0x0A: "mute",
}
HUMIDIFY_CODES = {
    0x00: "invalid",
    0x01: "off",
    0x02: "no_change",
    0x03: "1",
    0x04: "2",
    0x05: "3",
}
LEGACY_HUMIDIFY_CODES = {
    0x01: "off",
    0x02: "1",
    0x04: "2",
    0x05: "3",
}
SCENE_CODES = {
    0x00: "none",
    0x01: "old",
    0x02: "child",
    0x03: "read",
    0x04: "sleep",
    0x05: "ac",
}
FAValue = bool | float | int | str | None


def _read_byte(body: bytearray, index: int) -> int:
    """Read a body byte without failing on short responses."""
    return body[index] if len(body) > index else 0


def _get_bit(body: bytearray, byte_index: int, bit_index: int) -> int:
    """Read one bit from a possibly short body."""
    return (body[byte_index] >> bit_index) & 1 if len(body) > byte_index else 0


def _get_bits(
    body: bytearray,
    byte_index: int,
    start_index: int,
    end_index: int,
) -> int:
    """Read a bit range from a possibly short body."""
    if len(body) <= byte_index:
        return 0
    width = end_index - start_index + 1
    return (body[byte_index] >> start_index) & ((1 << width) - 1)


def _parse_temperature(value: int) -> float | int | None:
    """Decode a FA temperature byte."""
    if MIN_VALUE <= value <= MAX_ENCODED_TEMPERATURE:
        return float(value - TEMPERATURE_OFFSET)
    if value == SPECIAL_TEMPERATURE:
        return SPECIAL_TEMPERATURE
    return None


def _parse_range(value: int, minimum: int, maximum: int) -> int | None:
    """Return a value only when it is in the protocol-defined range."""
    return value if minimum <= value <= maximum else None


def _value_to_code(value: FAValue, values: dict[int, str]) -> int | None:
    """Convert a public value to a protocol enum code."""
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return value
    for key, item in values.items():
        if item == value:
            return key
    return None


class MessageFABase(MessageRequest):
    """FA message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes = ListTypes.X00,
    ) -> None:
        """Initialize the message with protocol version and message type."""
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
        """Return an empty body."""
        return bytearray()

    @property
    def _body(self) -> bytearray:
        return bytearray()


class MessageNewSet(MessageFABase):
    """FA protocol v5 set message from T_0000_FA_560000F3_2023011001.lua."""

    _protocol = FA_MESSAGE_PROTOCOL
    _body_length = NEW_PROTOCOL_BODY_LENGTH
    _protocol_version_byte = NEW_PROTOCOL_VERSION_BYTE
    _swing_byte = NEW_PROTOCOL_SWING_BYTE
    _tilting_angle_byte = NEW_PROTOCOL_TILTING_ANGLE_BYTE
    _swing_angle_byte = NEW_PROTOCOL_SWING_ANGLE_BYTE
    _invalid_body_bytes: tuple[int, ...] = ()
    _max_swing_angle = MAX_SWING_ANGLE
    _max_fan_speed = MAX_FAN_SPEED

    def __init__(self, protocol_version: int, subtype: int) -> None:
        """Initialize a protocol v5 set message."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
        )
        self._subtype = subtype
        self.power: bool | None = None
        self.voice: int | str | None = None
        self.child_lock: bool | None = None
        self.mode: int | None = None
        self.fan_speed: int | None = None
        self.target_temperature: float | int | None = None
        self.humidity: int | None = None
        self.oscillate: bool | None = None
        self.oscillation_angle: float | int | str | None = None
        self.oscillation_mode: int | str | None = None
        self.tilting_angle: float | int | str | None = None
        self.humidify: bool | int | None = None
        self.anophelifuge: bool | None = None
        self.anion: bool | None = None
        self.display_on_off: bool | None = None
        self.waterions: bool | None = None
        self.body_feeling_scan: bool | None = None
        self.scene: int | str | None = None
        self.auto_power_off: bool | None = None

    @property
    def _body(self) -> bytearray:  # noqa: C901
        """Build the payload after the body-type byte."""
        body = bytearray(self._body_length - 1)

        # These flags are "invalid" until the corresponding control is present.
        MessageBit.set_bit(body, 3, 7, 1)
        MessageBit.set_bit(body, 7, 7, 1)
        body[self._protocol_version_byte - 1] = self._protocol
        for byte in self._invalid_body_bytes:
            body[byte - 1] = 0xFF

        if self.power is not None:
            MessageBit.set_bit(body, 3, 0, int(self.power))
            MessageBit.set_bit(body, 3, 7, 0)
        if self.voice is not None:
            voice = _value_to_code(self.voice, VOICE_CODES)
            if voice is not None:
                body[1] = voice
        if self.child_lock is not None:
            MessageBit.set_bits(body, 2, 0, 1, 1 if self.child_lock else 2)
        if self.mode is not None:
            MessageBit.set_bits(body, 3, 1, 5, self.mode)
            MessageBit.set_bit(body, 3, 7, 0)
        if (
            self.fan_speed is not None
            and MIN_VALUE <= self.fan_speed <= self._max_fan_speed
        ):
            body[4] = self.fan_speed
        if self.target_temperature is not None:
            temperature = int(self.target_temperature)
            if temperature == SPECIAL_TEMPERATURE:
                body[5] = SPECIAL_TEMPERATURE
            elif MIN_TEMPERATURE <= temperature <= MAX_TEMPERATURE:
                body[5] = temperature + TEMPERATURE_OFFSET
        if self.humidity is not None and MIN_VALUE <= self.humidity <= MAX_HUMIDITY:
            body[6] = self.humidity
        if self.oscillate is not None:
            MessageBit.set_bit(body, self._swing_byte - 1, 7, 0)
            if self._protocol == FA_MESSAGE_PROTOCOL_V6 and self.oscillate:
                MessageBit.set_bits(body, self._swing_byte - 1, 0, 1, 2)
            if self.oscillate and self.oscillation_angle is None:
                body[self._swing_angle_byte - 1] = 0xFF
        if self.oscillation_mode is not None:
            mode = _value_to_code(self.oscillation_mode, SWING_DIRECTION_CODES)
            if mode is not None:
                if self._protocol == FA_MESSAGE_PROTOCOL_V6:
                    v6_mode = V6_SWING_MODE_CODES.get(mode)
                    if v6_mode is not None:
                        MessageBit.set_bits(
                            body,
                            self._swing_byte - 1,
                            0,
                            3,
                            v6_mode,
                        )
                        MessageBit.set_bit(body, self._swing_byte - 1, 7, 0)
                else:
                    MessageBit.set_bits(body, self._swing_byte - 1, 1, 3, mode)
                    MessageBit.set_bit(body, self._swing_byte - 1, 7, 0)
        if self.oscillation_angle is not None:
            angle = _new_angle_to_code(
                self.oscillation_angle,
                max_angle=self._max_swing_angle,
            )
            if angle is not None:
                body[self._swing_angle_byte - 1] = angle
                if self._protocol == FA_MESSAGE_PROTOCOL_V6 and (
                    self.oscillation_mode is None
                ):
                    MessageBit.set_bits(body, self._swing_byte - 1, 0, 1, 2)
                MessageBit.set_bit(body, self._swing_byte - 1, 7, 0)
        if self.tilting_angle is not None:
            angle = _new_angle_to_code(
                self.tilting_angle,
                max_angle=self._max_swing_angle,
            )
            if angle is not None:
                body[self._tilting_angle_byte - 1] = angle
                if self._protocol == FA_MESSAGE_PROTOCOL_V6 and (
                    self.oscillation_mode is None
                ):
                    MessageBit.set_bits(body, self._swing_byte - 1, 2, 3, 2)
                MessageBit.set_bit(body, self._swing_byte - 1, 7, 0)
        if self.humidify is not None:
            if isinstance(self.humidify, bool):
                humidify = 3 if self.humidify else 1
            else:
                humidify = self.humidify
            MessageBit.set_bits(body, 8, 4, 7, humidify)
        if self.anophelifuge is not None:
            MessageBit.set_bits(body, 8, 2, 3, 1 if self.anophelifuge else 2)
        if self.anion is not None:
            MessageBit.set_bits(body, 8, 0, 1, 1 if self.anion else 2)
        if self.body_feeling_scan is not None:
            body[14] = 1 if self.body_feeling_scan else 2
        if self.scene is not None:
            scene = _value_to_code(self.scene, SCENE_CODES)
            if scene is not None:
                body[15] = scene
        if self.auto_power_off is not None:
            MessageBit.set_bits(
                body,
                NEW_PROTOCOL_AUTO_POWER_OFF_BYTE - 1,
                6,
                7,
                1 if self.auto_power_off else 2,
            )
        if self.display_on_off is not None:
            MessageBit.set_bits(
                body,
                NEW_PROTOCOL_DISPLAY_BYTE - 1,
                6,
                7,
                1 if self.display_on_off else 2,
            )
        if self.waterions is not None:
            MessageBit.set_bits(
                body,
                NEW_PROTOCOL_WATERIONS_BYTE - 1,
                0,
                1,
                1 if self.waterions else 2,
            )
        return body


class MessageV6Set(MessageNewSet):
    """FA protocol v6 set message from T_0000_FA_56011CEC_2024072501.lua."""

    _protocol = FA_MESSAGE_PROTOCOL_V6
    _body_length = V6_PROTOCOL_BODY_LENGTH
    _swing_byte = V6_PROTOCOL_SWING_BYTE
    _tilting_angle_byte = V6_PROTOCOL_TILTING_ANGLE_BYTE
    _swing_angle_byte = V6_PROTOCOL_SWING_ANGLE_BYTE
    _invalid_body_bytes = V6_PROTOCOL_INVALID_BODY_BYTES
    _max_swing_angle = V6_MAX_NORMAL_SWING_ANGLE
    _max_fan_speed = MAX_V6_FAN_SPEED


class MessageCB4Set(MessageNewSet):
    """FA protocol v5 set message from T_0000_FA_56011CB4_2023081801.lua."""

    _body_length = CB4_PROTOCOL_BODY_LENGTH
    _invalid_body_bytes = CB4_PROTOCOL_INVALID_BODY_BYTES


class MessageSet(MessageFABase):
    """FA legacy set message from T_0000_FA_17.lua."""

    def __init__(self, protocol_version: int, subtype: int) -> None:
        """Initialize a legacy set message."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
        )
        self._subtype = subtype
        self.power: bool | None = None
        self.child_lock: bool | None = None
        self.voice: int | str | None = None
        self.mode: int | None = None
        self.mode_set_overrides: dict[int, int] = {}
        self.fan_speed: int | None = None
        self.target_temperature: float | int | None = None
        self.humidity: int | None = None
        self.oscillate: bool | None = None
        self.oscillation_angle: int | None = None
        self.oscillation_mode: int | None = None
        self.tilting_angle: int | None = None
        self.humidify: bool | None = None
        self.anophelifuge: bool | None = None
        self.anion: bool | None = None
        self.body_feeling_scan: bool | None = None
        self.scene: int | str | None = None
        self.waterions: bool | None = None
        self.display_on_off: bool | None = None

    @property
    def lock(self) -> bool | None:
        """Compatibility alias for the old FA message attribute."""
        return self.child_lock

    @lock.setter
    def lock(self, value: bool | None) -> None:
        self.child_lock = value

    @property
    def _body(self) -> bytearray:  # noqa: C901
        """Build the legacy FA payload after the body-type byte."""
        if 1 <= self._subtype <= ListTypes.X0A or self._subtype == ListTypes.A1:
            body = bytearray(18)
            if self._subtype != ListTypes.X0A:
                body[13] = 0xFF
        else:
            body = bytearray(49)
        body[3] = 0x80
        body[7] = 0x80

        if self.power is not None:
            body[3] = 1 if self.power else 0
        if self.child_lock is not None:
            body[2] = 1 if self.child_lock else 2
        if self.voice is not None:
            voice = _value_to_code(self.voice, VOICE_CODES)
            if voice is not None:
                body[LEGACY_VOICE_SET_INDEX] = voice
        if self.mode is not None:
            mode_override = self.mode_set_overrides.get(self.mode)
            body[3] = (
                mode_override
                if mode_override is not None
                else 1 | ((self.mode << 1) & 0x1E)
            )
        if self.fan_speed is not None and MIN_VALUE <= self.fan_speed <= MAX_FAN_SPEED:
            body[4] = self.fan_speed
        if self.target_temperature is not None:
            temperature = int(self.target_temperature)
            if MIN_TEMPERATURE <= temperature <= MAX_TEMPERATURE:
                body[LEGACY_TEMPERATURE_SET_INDEX] = temperature + TEMPERATURE_OFFSET
        if self.humidity is not None and MIN_VALUE <= self.humidity <= MAX_HUMIDITY:
            body[LEGACY_HUMIDITY_SET_INDEX] = self.humidity
        if self.oscillate is not None:
            body[7] = 1 if self.oscillate else 0
        if self.oscillation_angle is not None:
            body[7] = 1 | body[7] | ((self.oscillation_angle << 4) & 0x70)
        if self.oscillation_mode is not None:
            body[7] = 1 | body[7] | ((self.oscillation_mode << 1) & 0x0E)
        if self.tilting_angle is not None and len(body) > LEGACY_TILTING_ANGLE_SET_BYTE:
            body[LEGACY_TILTING_ANGLE_SET_BYTE] = self.tilting_angle
        if self.humidify is not None:
            body[8] = (body[8] & 0x0F) | (0x20 if self.humidify else 0x10)
        if self.anophelifuge is not None:
            body[LEGACY_HUMIDIFY_SET_INDEX] = (
                body[LEGACY_HUMIDIFY_SET_INDEX] & 0xF3
            ) | ((1 if self.anophelifuge else 2) << 2)
        if self.anion is not None:
            body[LEGACY_HUMIDIFY_SET_INDEX] = (
                body[LEGACY_HUMIDIFY_SET_INDEX] & 0xFC
            ) | (1 if self.anion else 2)
        if self.body_feeling_scan is not None:
            body[LEGACY_BODY_FEELING_SCAN_SET_INDEX] = (
                1 if self.body_feeling_scan else 2
            )
        if self.scene is not None:
            scene = _value_to_code(self.scene, SCENE_CODES)
            if scene is not None:
                body[LEGACY_SCENE_SET_INDEX] = scene
        if self.waterions is not None and len(body) > LEGACY_WATERIONS_SET_BYTE:
            body[LEGACY_WATERIONS_SET_BYTE] = (
                body[LEGACY_WATERIONS_SET_BYTE] & 0xFC
            ) | (1 if self.waterions else 2)
        if self.display_on_off is not None and len(body) > LEGACY_DISPLAY_SET_BYTE:
            body[LEGACY_DISPLAY_SET_BYTE] = (body[LEGACY_DISPLAY_SET_BYTE] & 0x3F) | (
                0x40 if self.display_on_off else 0x80
            )
        return body


SWING_DIRECTION_CODES = {
    0x00: "off",
    0x01: "oscillation",
    0x02: "tilting",
    0x03: "curve-w",
    0x04: "curve-8",
    0x05: "reserved",
    0x06: "both",
    0x07: "custom",
}
TILTING_ANGLE_CODES = {
    0x00: "off",
    0x01: "30",
    0x02: "60",
    0x03: "90",
    0x04: "120",
    0x05: "180",
    0x06: "360",
    0x07: "+60",
    0x08: "-60",
    0x09: "40",
}


def _v6_swing_axis_active(swing_type: int, angle: int) -> bool:
    """Return whether one v6 swing axis is active."""
    if swing_type == V6_SWING_TYPE_DIY:
        return True
    if angle in {0, V6_INVALID_SWING_ANGLE_CODE}:
        return False
    if angle == V6_DEFAULT_SWING_ANGLE_CODE:
        return True
    return swing_type == V6_SWING_TYPE_NORMAL


def _v6_swing_mode(
    lr_type: int,
    ud_type: int,
    lr_angle: int,
    ud_angle: int,
) -> int:
    """Map v6 horizontal and vertical swing states to the FA mode codes."""
    if V6_SWING_TYPE_DIY in (lr_type, ud_type):
        return SWING_MODE_CUSTOM
    lr_active = _v6_swing_axis_active(lr_type, lr_angle)
    ud_active = _v6_swing_axis_active(ud_type, ud_angle)
    if lr_active and ud_active:
        return SWING_MODE_BOTH
    if lr_active:
        return SWING_MODE_OSCILLATION
    if ud_active:
        return SWING_MODE_TILTING
    return SWING_MODE_OFF


def _new_angle_to_code(
    value: float | str,
    values: dict[int, str] | None = None,
    max_angle: int = MAX_SWING_ANGLE,
) -> int | None:
    """Convert a public angle to the v5 wire code."""
    if values is not None:
        return _value_to_code(value, values)
    if isinstance(value, str):
        if value == "off":
            return 0
        if value == V6_DEFAULT_SWING_ANGLE:
            return V6_DEFAULT_SWING_ANGLE_CODE
        try:
            value = float(value)
        except ValueError:
            return None
    if isinstance(value, (int, float)) and 0 <= value <= max_angle:
        return int(value // 5)
    return None


class FAGeneralMessageBody(MessageBody):
    """FA general status body for legacy and protocol v5/v6 devices."""

    def __init__(self, body: bytearray) -> None:
        """Initialize and decode the message body."""
        super().__init__(body)
        self.protocol_version = _read_byte(body, NEW_PROTOCOL_VERSION_BYTE)
        self.is_v6_protocol = (
            len(body) >= V6_PROTOCOL_BODY_LENGTH
            and self.protocol_version == FA_MESSAGE_PROTOCOL_V6
        )
        self.is_new_protocol = (
            len(body) >= NEW_PROTOCOL_BODY_LENGTH
            and self.protocol_version == FA_MESSAGE_PROTOCOL
        ) or self.is_v6_protocol
        self.error_code = _read_byte(body, 1)
        self.voice = _read_byte(body, 2)
        self.auto_power_off_flag = _get_bit(body, 3, 3)
        self.auto_power_off: bool | None = None
        self.body_feeling_scan: bool | None = None
        self.scene: str | None = None
        self.child_lock = (_read_byte(body, 3) & 0x03) == 0x01
        self.power = (_read_byte(body, 4) & 0x01) == 0x01
        self.mode = _get_bits(
            body,
            4,
            1,
            NEW_PROTOCOL_MODE_END_BIT if self.is_new_protocol else LEGACY_MODE_END_BIT,
        )
        self.fan_speed = (
            _parse_range(
                _read_byte(body, 5),
                MIN_VALUE,
                MAX_V6_FAN_SPEED if self.is_v6_protocol else MAX_FAN_SPEED,
            )
            or 0
        )
        self.target_temperature = _parse_temperature(_read_byte(body, 6))
        self.humidity = _parse_range(_read_byte(body, 7), MIN_VALUE, MAX_HUMIDITY)

        if self.is_new_protocol:
            swing_byte = (
                V6_PROTOCOL_SWING_BYTE
                if self.is_v6_protocol
                else NEW_PROTOCOL_SWING_BYTE
            )
            swing_angle_byte = (
                V6_PROTOCOL_SWING_ANGLE_BYTE
                if self.is_v6_protocol
                else NEW_PROTOCOL_SWING_ANGLE_BYTE
            )
            self.oscillation_angle = _read_byte(body, swing_angle_byte)
            self.tilting_angle = _read_byte(
                body,
                (
                    V6_PROTOCOL_TILTING_ANGLE_BYTE
                    if self.is_v6_protocol
                    else NEW_PROTOCOL_TILTING_ANGLE_BYTE
                ),
            )
            if self.is_v6_protocol:
                lr_type = _get_bits(body, swing_byte, 0, 1)
                ud_type = _get_bits(body, swing_byte, 2, 3)
                self.oscillation_mode = _v6_swing_mode(
                    lr_type,
                    ud_type,
                    self.oscillation_angle,
                    self.tilting_angle,
                )
                self.oscillate = _v6_swing_axis_active(
                    lr_type,
                    self.oscillation_angle,
                ) or _v6_swing_axis_active(ud_type, self.tilting_angle)
            else:
                self.oscillation_mode = _get_bits(
                    body,
                    swing_byte,
                    1,
                    3,
                )
                self.oscillate = self.oscillation_angle != 0
            humidify = _get_bits(
                body,
                NEW_PROTOCOL_HUMIDIFY_BYTE,
                4,
                7,
            )
            self.humidify = humidify in {3, 4, 5}
            self.humidify_mode = HUMIDIFY_CODES.get(
                humidify,
            )
            self.auto_power_off = (
                _get_bits(body, NEW_PROTOCOL_AUTO_POWER_OFF_BYTE, 6, 7) == 1
            )
            self.display_on_off = _get_bits(body, NEW_PROTOCOL_DISPLAY_BYTE, 6, 7) == 1
            self.waterions = _get_bits(body, NEW_PROTOCOL_WATERIONS_BYTE, 0, 1) == 1
        else:
            self.oscillate = _get_bit(body, 8, 0) > 0
            self.oscillation_angle = _get_bits(body, 8, 4, 6)
            self.oscillation_mode = _get_bits(body, 8, 1, 3)
            self.tilting_angle = (
                _read_byte(body, LEGACY_TILTING_ANGLE_GET_BYTE)
                if len(body) > LEGACY_TILTING_ANGLE_GET_BYTE
                else 0
            )
            self.humidify = (
                _get_bits(body, LEGACY_HUMIDIFY_GET_BYTE, 4, 7) in {2, 4, 5}
                if len(body) > LEGACY_HUMIDIFY_GET_BYTE
                else False
            )
            self.humidify_mode = LEGACY_HUMIDIFY_CODES.get(
                _get_bits(body, LEGACY_HUMIDIFY_GET_BYTE, 4, 7),
            )
            self.auto_power_off = None
            self.display_on_off = (
                _get_bits(body, LEGACY_DISPLAY_GET_BYTE, 6, 7) == 1
                if len(body) > LEGACY_DISPLAY_GET_BYTE
                else False
            )
            self.waterions = (
                _get_bits(body, LEGACY_WATERIONS_GET_BYTE, 0, 1) == 1
                if len(body) > LEGACY_WATERIONS_GET_BYTE
                else False
            )

        self.anophelifuge = (
            _get_bits(body, LEGACY_HUMIDIFY_GET_BYTE, 2, 3) == 1
            if len(body) > LEGACY_HUMIDIFY_GET_BYTE
            else False
        )
        self.anion = (
            _get_bits(body, LEGACY_HUMIDIFY_GET_BYTE, 0, 1) == 1
            if len(body) > LEGACY_HUMIDIFY_GET_BYTE
            else False
        )
        self.humidify_feedback = (
            _parse_range(_read_byte(body, 12), MIN_VALUE, MAX_HUMIDITY)
            if self.is_new_protocol
            else None
        )
        self.temperature_feedback = (
            _parse_temperature(_read_byte(body, 13)) if self.is_new_protocol else None
        )
        self.body_feeling_scan = (
            _read_byte(body, BODY_FEELING_SCAN_GET_BYTE) == 1
            if len(body) > BODY_FEELING_SCAN_GET_BYTE
            else None
        )
        self.scene = (
            SCENE_CODES.get(_read_byte(body, SCENE_GET_BYTE))
            if len(body) > SCENE_GET_BYTE
            else None
        )


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
