"""Midea local x0008ac messages."""

from __future__ import annotations

from typing import TYPE_CHECKING

from midealocal.const import DeviceType
from midealocal.crc8 import calculate as crc8_854

if TYPE_CHECKING:
    from collections.abc import Callable
from midealocal.message import (
    BoolParser,
    FloatParser,
    IntParser,
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageType,
    NewProtocolMessageBody,
)

# Toshiba IoLife frame layout
_FRAME_HEADER_LEN = 16
_FRAME_MAGIC = bytes([0x55, 0xAA, 0xCC, 0x33])
_MSG_TYPE_QUERY = 0x0003
_MSG_TYPE_SET = 0x0002
_DEVICE_BYTE = 0xAC

# Query body layout (independent of C0 response constants)
_QUERY_BODY_LEN = 22
_QUERY_CMD = 0x41
_QUERY_SUBCMD = 0x81
_QUERY_MASK_ALL = 0xFF
_QUERY_SEQ_BYTE = 20
_QUERY_CRC_BYTE = 21

# Nibble masks, shared by the byte fields that pack two values.
_LOW_NIBBLE = 0x0F
_HIGH_NIBBLE = 0xF0
_NIBBLE_SHIFT = 4


def _high_nibble(value: int) -> int:
    """Return the high nibble of a byte (or of an already-masked value)."""
    return value >> _NIBBLE_SHIFT


# C0 body byte positions
_C0_BODY_MIN_LEN = 22
_C0_POWER_BYTE = 1
_C0_MODE_BYTE = 2
_C0_FAN_BYTE = 3
_C0_TEMP_BYTE = 4
_C0_HUMIDITY_NOW_BYTE = 10
_C0_SWING_BYTE = 11
_C0_INDOOR_RAW_BYTE = 13
_C0_OUTDOOR_RAW_BYTE = 14
_C0_DECIMAL_BYTE = 15
_C0_FLAGS1_BYTE = 16
_C0_FLAGS2_BYTE = 17
_C0_FLAGS3_BYTE = 18
_C0_DEFLECT_UD_BYTE = 19
_C0_DEFLECT_LR_BYTE = 20
_C0_FLAGS4_BYTE = 21
_C0_DEHUMIDIFY_MASK = 0x0E
_C0_DEHUMIDIFY_SHIFT = 1
_C0_ERROR_BYTE = 23
_C0_NEW_BREEZELESS_BYTE = 24
_C0_NEW_BREEZELESS_MASK = 0x30
_C0_NEW_BREEZELESS_SHIFT = 4

# A1 body byte positions
_A1_INDOOR_RAW_BYTE = 13
_A1_OUTDOOR_RAW_BYTE = 14
_A1_DECIMAL_BYTE = 18

# Body type bytes
_BODY_TYPE_C0 = 0xC0
_BODY_TYPE_D0 = 0xD0
_BODY_TYPE_A1 = 0xA1
_BODY_TYPE_B0 = 0xB0
_BODY_TYPE_B5 = 0xB5

# B0/B5 property IDs
_PROP_POWER = 0x0001
_PROP_MODE = 0x0002
_PROP_TARGET_TEMP = 0x0003
_PROP_INDOOR_TEMP = 0x0004
_PROP_OUTDOOR_TEMP = 0x0005
_PROP_FAN_SPEED = 0x0006
_PROP_SWING_UD = 0x0008
_PROP_SWING_LR = 0x0009
_PROP_DEFLECTOR_ANGLE = 0x000A  # 2-byte [ud_angle, lr_angle]; 0xFF = keep current
_PROP_ECO = 0x000D
_PROP_PURIFIER = 0x000E
_PROP_DRY = 0x0010
_PROP_INDOOR_HUMIDITY = 0x0015
_PROP_SCREEN_DISPLAY = 0x0017
_PROP_BREEZELESS = 0x0018
_PROP_NEW_BREEZELESS = 0x0070  # breezeless direction; 0x18 is its on/off
_PROP_WIND_STRAIGHT = 0x0032
_PROP_WIND_AVOID = 0x0033
_PROP_ENERGY_SAVE = 0x0050
_PROP_DEHUMIDIFY = 0x0051
_PROP_COMFORT_AIRFLOW = 0x0055

# Temperature property: 2 bytes [integer, decimal]
_TEMP_PROP_LEN = 2

# Deflector property: 2 bytes [ud_angle, lr_angle]
_DEFLECTOR_PROP_LEN = 2

# Temperature raw-value sentinels
_TEMP_INVALID_LOW = 0x00
_TEMP_INVALID_HIGH = 0xFF
_TEMP_OFFSET = 50

# Scalar property maps: prop_id → (attribute_name, value_converter)
_B0_SCALAR_PROPS: dict[int, tuple[str, Callable[[int], bool | int]]] = {
    _PROP_POWER: ("power", bool),
    _PROP_MODE: ("mode", int),
    _PROP_FAN_SPEED: ("fan_speed", int),
    _PROP_SWING_UD: ("swing_vertical", int),
    _PROP_SWING_LR: ("swing_horizontal", int),
    _PROP_ECO: ("eco_mode", bool),
    _PROP_PURIFIER: ("anion", bool),
    _PROP_DRY: ("dry", bool),
    _PROP_INDOOR_HUMIDITY: ("indoor_humidity", int),
    _PROP_SCREEN_DISPLAY: ("screen_display", int),
    _PROP_BREEZELESS: ("breezeless", int),
    _PROP_NEW_BREEZELESS: ("breezeless_direction", int),
    _PROP_ENERGY_SAVE: ("energy_save", bool),
    _PROP_DEHUMIDIFY: ("dehumidify", int),
    _PROP_COMFORT_AIRFLOW: ("comfort_mode", bool),
}

_B5_SCALAR_PROPS: dict[int, tuple[str, Callable[[int], bool | int]]] = {
    _PROP_POWER: ("power", bool),
    _PROP_MODE: ("mode", int),
    _PROP_FAN_SPEED: ("fan_speed", int),
    _PROP_SWING_UD: ("swing_vertical", int),
    _PROP_SWING_LR: ("swing_horizontal", int),
    _PROP_ECO: ("eco_mode", bool),
    _PROP_PURIFIER: ("anion", bool),
    _PROP_DRY: ("dry", bool),
    _PROP_ENERGY_SAVE: ("energy_save", bool),
    _PROP_COMFORT_AIRFLOW: ("comfort_mode", bool),
}

# Sequence counter — wraps 1..254 like standard AC
_MAX_SEQ = 254
_seq: int = 0


def _next_seq() -> int:
    global _seq  # noqa: PLW0603
    _seq = (_seq % _MAX_SEQ) + 1
    return _seq


def _crc16_ccitt(data: list[int], start: int, end_inclusive: int) -> int:
    crc = 0
    for i in range(start, end_inclusive + 1):
        crc ^= data[i] << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021 if crc & 0x8000 else crc << 1) & 0xFFFF
    return crc


def _assemble_frame(body: list[int], msg_type: int) -> list[int]:
    """Build a Toshiba IoLife frame with device byte 0xAC."""
    total = _FRAME_HEADER_LEN + len(body) + 2
    msg_len = total - 4
    frame: list[int] = [
        0x55,
        0xAA,
        0xCC,
        0x33,
        msg_len & 0xFF,
        (msg_len >> 8) & 0xFF,
        0x01,
        _DEVICE_BYTE,
        0,
        0,
        0,
        0,
        0,
        0,
        msg_type & 0xFF,
        (msg_type >> 8) & 0xFF,
        *body,
    ]
    crc = _crc16_ccitt(frame, 0, total - 3)
    frame.append(crc & 0xFF)
    frame.append((crc >> 8) & 0xFF)
    return frame


def _parse_frame(frame: bytes) -> tuple[int, bytearray]:
    """Return (data_type, body) from a Toshiba IoLife frame."""
    if len(frame) < _FRAME_HEADER_LEN + 2:
        msg = f"Frame too short: {len(frame)}"
        raise ValueError(msg)
    if bytes(frame[:4]) != _FRAME_MAGIC:
        msg = f"Bad frame magic: {bytes(frame[:4]).hex()}"
        raise ValueError(msg)
    expected_crc = _crc16_ccitt(list(frame), 0, len(frame) - 3)
    actual_crc = frame[-2] | (frame[-1] << 8)
    if expected_crc != actual_crc:
        msg = f"CRC mismatch: expected {expected_crc:#06x}, got {actual_crc:#06x}"
        raise ValueError(msg)
    data_type = frame[14]
    body = bytearray(frame[_FRAME_HEADER_LEN:-2])
    return data_type, body


def _decode_temp(raw: int, decimal_nibble: int) -> float | None:
    """Decode a raw temperature byte to °C, or None if the value is invalid."""
    if raw in (_TEMP_INVALID_LOW, _TEMP_INVALID_HIGH):
        return None
    return (raw - _TEMP_OFFSET) / 2.0 + 0.1 * decimal_nibble


def _apply_deflector_prop(
    obj: object,
    params: dict[int, bytearray],
) -> None:
    """Set both wind angles on obj from a B0/B5 deflector property (0x0A)."""
    data = params.get(_PROP_DEFLECTOR_ANGLE)
    if data is not None and len(data) >= _DEFLECTOR_PROP_LEN:
        obj.wind_ud_angle = data[0]  # type: ignore[attr-defined]
        obj.wind_lr_angle = data[1]  # type: ignore[attr-defined]


def _apply_temp_props(
    obj: object,
    params: dict[int, bytearray],
) -> None:
    """Set indoor_temperature and outdoor_temperature on obj from B0/B5 params."""
    for prop_id, attr in (
        (_PROP_INDOOR_TEMP, "indoor_temperature"),
        (_PROP_OUTDOOR_TEMP, "outdoor_temperature"),
    ):
        if prop_id in params and len(params[prop_id]) >= _TEMP_PROP_LEN:
            data = params[prop_id]
            setattr(obj, attr, data[0] + 0.1 * data[1])


class ToshibaIolifeC0Body(MessageBody):
    """Toshiba IoLife AC C0/D0 classic status body.

    The fields below are set by the parser list in __init__; they are declared
    here so callers (and mypy) can see the shape of a parsed body.
    """

    power: bool
    mode: int
    fan_speed: int
    target_temperature: float
    indoor_humidity: int
    swing_horizontal: int
    swing_vertical: int
    eco_mode: bool
    anion: bool
    dry: bool
    clean_manual: bool
    cleaning: bool
    full_dust: bool
    breezeless: int
    breezeless_direction: int
    wind_ud_angle: int
    wind_lr_angle: int
    energy_save: bool
    dehumidify: int
    comfort_mode: bool
    error_code: int

    def __init__(self, body: bytearray) -> None:
        """Parse a C0/D0 body."""
        super().__init__(
            body,
            [
                BoolParser("power", _C0_POWER_BYTE, 0),
                IntParser(
                    "mode",
                    _C0_MODE_BYTE,
                    byte_mask=_HIGH_NIBBLE,
                    transform_func=_high_nibble,
                ),
                IntParser("fan_speed", _C0_FAN_BYTE, byte_mask=0x7F),
                FloatParser(
                    "target_temperature",
                    _C0_TEMP_BYTE,
                    byte_mask=0x7F,
                    transform_func=lambda raw: raw / 2,
                ),
                IntParser("indoor_humidity", _C0_HUMIDITY_NOW_BYTE),
                IntParser(
                    "swing_horizontal",
                    _C0_SWING_BYTE,
                    byte_mask=_LOW_NIBBLE,
                ),
                IntParser(
                    "swing_vertical",
                    _C0_SWING_BYTE,
                    byte_mask=_HIGH_NIBBLE,
                    transform_func=_high_nibble,
                ),
                BoolParser("eco_mode", _C0_FLAGS1_BYTE, 0),
                BoolParser("anion", _C0_FLAGS1_BYTE, 1),
                BoolParser("dry", _C0_FLAGS1_BYTE, 2),
                BoolParser("clean_manual", _C0_FLAGS1_BYTE, 4),
                BoolParser("cleaning", _C0_FLAGS1_BYTE, 5),
                BoolParser("full_dust", _C0_FLAGS2_BYTE, 5),
                # Lua T_0008_AC_29 line 730: no_wind_sense is the low nibble of
                # byte 18. Byte 24 bits 4-5 are a different property, the
                # breezeless deflection direction (new_no_wind_sense, 0x70).
                IntParser("breezeless", _C0_FLAGS3_BYTE, byte_mask=_LOW_NIBBLE),
                IntParser(
                    "breezeless_direction",
                    _C0_NEW_BREEZELESS_BYTE,
                    byte_mask=_C0_NEW_BREEZELESS_MASK,
                    transform_func=lambda raw: raw >> _C0_NEW_BREEZELESS_SHIFT,
                ),
                IntParser("wind_ud_angle", _C0_DEFLECT_UD_BYTE),
                IntParser("wind_lr_angle", _C0_DEFLECT_LR_BYTE),
                BoolParser("energy_save", _C0_FLAGS4_BYTE, 0),
                IntParser(
                    "dehumidify",
                    _C0_FLAGS4_BYTE,
                    byte_mask=_C0_DEHUMIDIFY_MASK,
                    transform_func=lambda raw: raw >> _C0_DEHUMIDIFY_SHIFT,
                ),
                BoolParser("comfort_mode", _C0_FLAGS4_BYTE, 4),
                IntParser("error_code", _C0_ERROR_BYTE),
            ],
        )
        # Hand-written: each temperature takes its integer part from one byte and
        # its decimal from a nibble of byte 15, which no single parser can span.
        decimal = self.read_byte(body, _C0_DECIMAL_BYTE)
        self.indoor_temperature = _decode_temp(
            body[_C0_INDOOR_RAW_BYTE],
            decimal & _LOW_NIBBLE,
        )
        self.outdoor_temperature = _decode_temp(
            body[_C0_OUTDOOR_RAW_BYTE],
            _high_nibble(decimal),
        )


class ToshibaIolifeA1Body(MessageBody):
    """Toshiba IoLife AC A1 temperature notification body.

    Both temperatures split their integer part and decimal nibble across
    non-adjacent bytes, so they are decoded by hand rather than by a parser.
    """

    indoor_temperature: float | None
    outdoor_temperature: float | None

    def __init__(self, body: bytearray) -> None:
        """Parse an A1 temperature notification body."""
        super().__init__(body)
        decimal = self.read_byte(body, _A1_DECIMAL_BYTE)
        indoor_raw = self.read_byte(body, _A1_INDOOR_RAW_BYTE, _TEMP_INVALID_LOW)
        outdoor_raw = self.read_byte(body, _A1_OUTDOOR_RAW_BYTE, _TEMP_INVALID_LOW)
        self.indoor_temperature = _decode_temp(indoor_raw, decimal & _LOW_NIBBLE)
        self.outdoor_temperature = _decode_temp(outdoor_raw, _high_nibble(decimal))


class _ToshibaIolifePropsBody(NewProtocolMessageBody):
    """Declares the properties B0/B5 bodies may set from the scalar prop tables.

    These are bare annotations, not assignments, so an attribute only exists once
    the corresponding property is actually present in the frame. The device relies
    on hasattr() to tell which attributes a given frame carried.
    """

    power: bool
    mode: int
    target_temperature: float
    fan_speed: int
    swing_vertical: int
    swing_horizontal: int
    eco_mode: bool
    anion: bool
    dry: bool
    indoor_humidity: int
    indoor_temperature: float
    outdoor_temperature: float
    screen_display: int
    breezeless: int
    breezeless_direction: int
    wind_ud_angle: int
    wind_lr_angle: int
    energy_save: bool
    dehumidify: int
    comfort_mode: bool


class ToshibaIolifeB0Body(_ToshibaIolifePropsBody):
    """Toshiba IoLife AC B0 property response (FIVE pack)."""

    def __init__(self, body: bytearray) -> None:
        """Parse a B0 property response body."""
        super().__init__(body, ListTypes.B0)
        params = self.parse()
        for prop_id, (attr, convert) in _B0_SCALAR_PROPS.items():
            if prop_id in params:
                setattr(self, attr, convert(params[prop_id][0]))
        if _PROP_TARGET_TEMP in params:
            self.target_temperature = params[_PROP_TARGET_TEMP][0] / 2.0
        _apply_deflector_prop(self, params)
        _apply_temp_props(self, params)


class ToshibaIolifeB5Body(_ToshibaIolifePropsBody):
    """Toshiba IoLife AC B5 property notification (FOUR pack)."""

    def __init__(self, body: bytearray) -> None:
        """Parse a B5 property notification body."""
        super().__init__(body, ListTypes.B5)
        params = self.parse()
        for prop_id, (attr, convert) in _B5_SCALAR_PROPS.items():
            if prop_id in params:
                setattr(self, attr, convert(params[prop_id][0]))
        if _PROP_TARGET_TEMP in params:
            self.target_temperature = params[_PROP_TARGET_TEMP][0] / 2.0
        _apply_deflector_prop(self, params)
        _apply_temp_props(self, params)


class MessageQuery(MessageRequest):
    """Toshiba IoLife AC classic query (0x41 body, cType 0x0003)."""

    def __init__(self) -> None:
        """Initialize AC query message."""
        super().__init__(
            device_type=DeviceType.AC,
            protocol_version=0,
            message_type=MessageType.query,
            body_type=ListTypes.X00,
        )

    @property
    def header(self) -> bytearray:
        """Return empty header — Toshiba frame is built in serialize()."""
        return bytearray([])

    @property
    def _body(self) -> bytearray:
        """Return empty body placeholder."""
        return bytearray([])

    def serialize(self) -> bytearray:
        """Serialize to a Toshiba IoLife query frame."""
        body = [0] * _QUERY_BODY_LEN
        body[0] = _QUERY_CMD
        body[1] = _QUERY_SUBCMD
        body[3] = _QUERY_MASK_ALL
        body[_QUERY_SEQ_BYTE] = _next_seq()
        body[_QUERY_CRC_BYTE] = crc8_854(bytearray(body[: _QUERY_SEQ_BYTE + 1]))
        return bytearray(_assemble_frame(body, _MSG_TYPE_QUERY))


class MessageSet(MessageRequest):
    """Toshiba IoLife AC property set command (B0 body, cType 0x0002)."""

    def __init__(self) -> None:
        """Initialize AC set message."""
        super().__init__(
            device_type=DeviceType.AC,
            protocol_version=0,
            message_type=MessageType.set,
            body_type=ListTypes.X00,
        )
        self._params: dict[int, bytearray] = {}

    def set_param(self, param_id: int, value: bytearray) -> None:
        """Add a property ID / value pair to the command."""
        self._params[param_id] = value

    @property
    def header(self) -> bytearray:
        """Return empty header — Toshiba frame is built in serialize()."""
        return bytearray([])

    @property
    def _body(self) -> bytearray:
        """Return empty body placeholder."""
        return bytearray([])

    def serialize(self) -> bytearray:
        """Serialize to a Toshiba IoLife set frame."""
        entries = bytearray()
        for param_id, value in self._params.items():
            entries += NewProtocolMessageBody.pack(param_id, value, pack_len=4)
        body = [_BODY_TYPE_B0, len(self._params), *entries]
        body.append(_next_seq())
        body.append(crc8_854(bytearray(body)))
        return bytearray(_assemble_frame(body, _MSG_TYPE_SET))


AcBody = (
    ToshibaIolifeC0Body
    | ToshibaIolifeA1Body
    | ToshibaIolifeB0Body
    | ToshibaIolifeB5Body
)

_BODY_PARSERS: dict[int, type[AcBody]] = {
    _BODY_TYPE_C0: ToshibaIolifeC0Body,
    _BODY_TYPE_D0: ToshibaIolifeC0Body,
    _BODY_TYPE_A1: ToshibaIolifeA1Body,
    _BODY_TYPE_B0: ToshibaIolifeB0Body,
    _BODY_TYPE_B5: ToshibaIolifeB5Body,
}


def parse_ac_response(frame: bytes) -> AcBody | None:
    """Dispatch a Toshiba IoLife AC frame to the appropriate body parser."""
    try:
        _data_type, body = _parse_frame(frame)
    except (ValueError, IndexError):
        return None
    if not body:
        return None
    body_type = body[0]
    if body_type in (_BODY_TYPE_C0, _BODY_TYPE_D0) and len(body) < _C0_BODY_MIN_LEN:
        return None
    parser = _BODY_PARSERS.get(body_type)
    if parser is None:
        return None
    return parser(body)
