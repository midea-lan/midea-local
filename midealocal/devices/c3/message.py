"""Midea local C3 message."""

from enum import IntEnum
from functools import partial
from math import isfinite

from midealocal.const import DeviceType
from midealocal.message import (
    FunctionParser,
    IntParser,
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
    ValueParser,
)

BYTE_BITS = 8
ENERGY_SCALE = 100

# Native table protocol source (vendor Lua 0.0.27):
# https://github.com/wuwentao/midea-lua/blob/f47f06e59d96a82a784c949fbb86c7f31ff839aa/lua/0xC3/T_0000_C3_10004830_2025112601.lua
# The Lua filename identifies product 10004830, while the controller reports
# model 17100007. Keep the decoder model-scoped because this table layout is
# verified only for model 17100007.
QUINTUPLE_MODEL = "17100007"
BASIC_TABLE = 0x2010
ENERGY_TABLE = 0x2F12

# An X00 body has a ten-byte envelope: the body type inserted by the message
# framework, a two-byte table, four reserved bytes, a format byte, and two more
# reserved bytes. Format 0 is sequential; format 1 contains two-byte tags,
# one-byte lengths, and values. The reserved bytes are all 0xFF on the wire.
ENVELOPE_LENGTH = 10
FORMAT_OFFSET = 7
TLV_FORMAT = 1
TLV_HEADER_LENGTH = 3
INVALID_BYTE = 0xFF
INVALID_TEMPERATURE = 0x7FFF
TEMPERATURE_SCALE = 10
AUTO_MODE_TAG = 28
ERROR_CODE_TAG = 42
WATTS_PER_ENERGY_UNIT = 10
ENERGY_SIZES = (1, 4, 2, 2, 2) + (4,) * 31
MIN_ENERGY_LENGTH = ENVELOPE_LENGTH + sum(ENERGY_SIZES[:12])
QUINTUPLE_ENERGY_FIELDS = {
    2: "current_unit_capacity",
    3: "instant_renew_power0",
    4: "instant_power0",
    6: "total_produced_energy",
    9: "total_energy_consumption",
}
QUINTUPLE_ENERGY_ATTRIBUTES = frozenset(QUINTUPLE_ENERGY_FIELDS.values())
WATT_TAGS = frozenset((3, 4))


class BasicTag(IntEnum):
    """Writable fields in the vendor's 0x2010 table."""

    ZONE1_POWER = 0
    ZONE2_POWER = 1
    DHW_POWER = 2
    MODE = 3
    ZONE1_TEMPERATURE = 4
    ZONE2_TEMPERATURE = 5
    ROOM_TEMPERATURE = 6
    DHW_TEMPERATURE = 7
    ZONE1_CURVE = 8
    ZONE2_CURVE = 9
    TANK_BOOSTER = 10
    FAST_DHW = 11


TEMPERATURE_TAGS = frozenset(
    (
        BasicTag.ZONE1_TEMPERATURE,
        BasicTag.ZONE2_TEMPERATURE,
        BasicTag.ROOM_TEMPERATURE,
        BasicTag.DHW_TEMPERATURE,
    ),
)
WIRE_MODES = frozenset((0, 2, 3, 5))
MODE_FROM_WIRE = {0: 0, 2: 2, 3: 3, 5: 1}
MODE_TO_WIRE = {0: 0, 1: 5, 2: 2, 3: 3}

# Sizes of every entry, including the ASCII and reserved entries needed to
# locate trailing fields in sequential responses. Indexes are vendor tags.
BASIC_SIZES = (
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    5,
    12,
    4,
    2,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    2,
    1,
    1,
)
MIN_SEQUENTIAL_LENGTH = ENVELOPE_LENGTH + sum(BASIC_SIZES[:53])
BOOLEAN_FIELDS = {
    0: "zone1_power",
    1: "zone2_power",
    2: "dhw_power",
    8: "zone1_curve",
    9: "zone2_curve",
    10: "tbh",
    11: "fast_dhw",
    12: "remote_onoff",
    13: "silent_mode",
    14: "heat",
    15: "cool",
    16: "dhw",
    17: "double_zone",
    20: "room_thermal_support",
    21: "room_thermal_state",
    22: "time_set",
    24: "holiday_on",
    25: "eco_mode",
    44: "tbh_control",
    47: "sys_energy_ana_en",
    48: "hmi_energy_ana_set_en",
}
TEMPERATURE_FIELDS = {
    6: "room_target_temp",
    7: "dhw_target_temp",
    37: "room_temp_max",
    38: "room_temp_min",
    39: "dhw_temp_max",
    40: "dhw_temp_min",
    41: "tank_actual_temperature",
    52: "outdoor_temperature",
}
TEMPERATURE_LIMIT_FIELDS = frozenset(
    ("room_temp_max", "room_temp_min", "dhw_temp_max", "dhw_temp_min"),
)
TEMPERATURE_SENSOR_FIELDS = frozenset(
    ("tank_actual_temperature", "outdoor_temperature", "temp_t4"),
)
ARRAY_FIELDS = {
    "zone_target_temp": (4, 5),
    "zone_heating_temp_max": (29, 33),
    "zone_heating_temp_min": (30, 34),
    "zone_cooling_temp_max": (31, 35),
    "zone_cooling_temp_min": (32, 36),
}
ZONE_TEMP_TYPE_TAGS = (18, 19)
STATUS_TEMPERATURE_ATTRIBUTES = {
    4: ("zone1_temp_set", "idu_t1s1"),
    5: ("zone2_temp_set",),
    6: ("tas",),
    7: ("t5s",),
    52: ("temp_t4",),
}


def _envelope(table: int, format_code: int) -> bytearray:
    return bytearray(
        table.to_bytes(2, "big")
        + b"\xff\xff\xff\xff"
        + bytes((format_code, INVALID_BYTE, INVALID_BYTE)),
    )


class MessageQuery2010(MessageRequest):
    """Query basic status with the exact vendor query envelope."""

    def __init__(self, protocol_version: int = 0) -> None:
        """Initialize the model-specific status request."""
        super().__init__(
            DeviceType.C3,
            protocol_version,
            MessageType.query,
            ListTypes.X00,
        )

    @property
    def _body(self) -> bytearray:
        return _envelope(BASIC_TABLE, 0)


class MessageQuery2F12(MessageQuery2010):
    """Query the vendor energy table without changing any settings."""

    @property
    def _body(self) -> bytearray:
        return _envelope(ENERGY_TABLE, 0)


class MessageSet2010(MessageRequest):
    """Write only the supplied 0x2010 properties in TLV form."""

    # Sparse writes are intentional: replaying cached/default values can alter
    # another zone. The basic query and read-only tables were seen on hardware,
    # and a 49 C DHW target write was confirmed. Other controls follow the exact
    # vendor encoding but have not received broad hardware acceptance testing.

    def __init__(
        self,
        values: dict[BasicTag, bool | float | int],
        protocol_version: int = 0,
    ) -> None:
        """Validate and encode a sparse set of control properties."""
        super().__init__(
            DeviceType.C3,
            protocol_version,
            MessageType.set,
            ListTypes.X00,
        )
        if not values:
            raise ValueError("A C3 control request must contain a property")
        self._encoded = _envelope(BASIC_TABLE, TLV_FORMAT)
        for tag, value in sorted(values.items()):
            if tag not in BasicTag:
                raise ValueError("Unsupported C3 control property")
            if tag in TEMPERATURE_TAGS:
                temperature = float(value)
                if not isfinite(temperature):
                    raise ValueError("Invalid C3 target temperature")
                scaled = round(temperature * TEMPERATURE_SCALE)
                if not 0 <= scaled < INVALID_TEMPERATURE:
                    raise ValueError("Invalid C3 target temperature")
                data = scaled.to_bytes(2, "big")
            elif tag == BasicTag.MODE:
                if value not in WIRE_MODES:
                    raise ValueError("Unsupported C3 operating mode")
                data = bytes((int(value),))
            else:
                if not isinstance(value, bool):
                    raise ValueError(
                        "C3 power and curve controls require boolean values",
                    )
                data = bytes((int(value),))
            self._encoded.extend(
                int(tag).to_bytes(2, "big") + bytes((len(data),)) + data,
            )

    @property
    def _body(self) -> bytearray:
        return self._encoded


def _read_fields(
    body: bytearray,
    sizes: tuple[int, ...] = BASIC_SIZES,
    minimum_length: int = MIN_SEQUENTIAL_LENGTH,
) -> dict[int, tuple[int, int]]:
    """Locate complete table fields; reject malformed TLVs atomically."""
    if len(body) < ENVELOPE_LENGTH:
        return {}
    values = {}
    offset = ENVELOPE_LENGTH
    if body[FORMAT_OFFSET] == TLV_FORMAT:
        while offset < len(body):
            if offset + TLV_HEADER_LENGTH > len(body):
                return {}
            tag = IntParser(
                "tag", offset, length_in_bytes=2, first_upper=True
            ).get_value(body)
            size = body[offset + 2]
            offset += TLV_HEADER_LENGTH
            if offset + size > len(body):
                return {}
            if tag < len(sizes):
                if size != sizes[tag]:
                    return {}
                values[tag] = (offset, size)
            offset += size
    elif body[FORMAT_OFFSET] == 0:
        if len(body) < minimum_length:
            return {}
        for tag, size in enumerate(sizes):
            if offset + size > len(body):
                break
            values[tag] = (offset, size)
            offset += size
    return values


def _temperature(raw: bytes | bytearray) -> float | None:
    """Decode signed basic-table tenths, leaving invalid probes unavailable."""
    value = IntParser(
        "temperature", 0, length_in_bytes=len(raw), first_upper=True
    ).get_value(bytearray(raw))
    if value == INVALID_TEMPERATURE:
        return None
    if value & TEMPERATURE_SIGN_BIT:
        value -= SIGNED_TEMPERATURE_MODULUS
    return value / TEMPERATURE_SCALE


def _energy(raw: bytearray, *, watts: bool) -> float | None:
    """Apply the vendor scale while preserving unavailable energy fields."""
    value = int.from_bytes(raw, "big")
    if value == (1 << (len(raw) * BYTE_BITS)) - 1:
        return None
    return value * WATTS_PER_ENERGY_UNIT if watts else value / ENERGY_SCALE


def _on_off(raw: bytearray) -> bool | None:
    """Decode only the controller's confirmed boolean values."""
    return bool(raw[0]) if raw[0] in (0, 1) else None


def _mode(raw: bytearray) -> int | None:
    """Translate the vendor operating-mode byte."""
    return MODE_FROM_WIRE.get(raw[0])


def _actual_mode(raw: bytearray) -> int | None:
    """Translate the reported automatic operating mode."""
    return raw[0] + 1 if raw[0] in (1, 2) else None


def _error_code(raw: bytearray) -> int | None:
    """Preserve an explicitly unavailable controller error code."""
    return None if raw[0] == INVALID_BYTE else raw[0]


def _error_description(raw: bytearray) -> str | None:
    """Describe the raw error without assigning unverified fault meanings."""
    code = _error_code(raw)
    return (
        None
        if code is None
        else "No error"
        if code == 0
        else f"Unknown code (raw={code})"
    )


def _basic_arrays(body: bytearray) -> dict[str, dict[int, float | bool | None]]:
    """Decode only present array members, preserving explicit invalid limits."""
    fields = _read_fields(body)
    arrays: dict[str, dict[int, float | bool | None]] = {}
    for name, tags in ARRAY_FIELDS.items():
        changes: dict[int, float | bool | None] = {}
        for index, tag in enumerate(tags):
            if tag not in fields:
                continue
            offset, width = fields[tag]
            value = _temperature(body[offset : offset + width])
            if value is not None or name != "zone_target_temp":
                changes[index] = value
        if changes:
            arrays[name] = changes
    types: dict[int, float | bool | None] = {}
    for index, tag in enumerate(ZONE_TEMP_TYPE_TAGS):
        if tag in fields:
            offset, _ = fields[tag]
            raw = body[offset]
            types[index] = raw == 0 if raw in (0, 1) else None
    if types:
        arrays["zone_temp_type"] = types
    return arrays


class C3QuintupleEnergyBody(MessageBody):
    """Decode 0x2F12 energy using the vendor's 0.01 kW/kWh scale."""

    quintuple_energy: bool
    current_unit_capacity: float | None
    instant_renew_power0: float | None
    instant_power0: float | None
    total_produced_energy: float | None
    total_energy_consumption: float | None

    def __init__(self, body: bytearray) -> None:
        """Expose complete energy fields through the shared body parsers."""
        fields = _read_fields(body, ENERGY_SIZES, MIN_ENERGY_LENGTH)
        self.quintuple_energy = bool(fields)
        parsers: list[ValueParser] = []
        for tag, name in QUINTUPLE_ENERGY_FIELDS.items():
            if tag in fields:
                offset, width = fields[tag]
                parsers.append(
                    FunctionParser(
                        name,
                        offset,
                        partial(_energy, watts=tag in WATT_TAGS),
                        None,
                        length_in_bytes=width,
                    ),
                )
        super().__init__(body, parsers)


class C3QuintupleBasicBody(MessageBody):
    """Decode sequential status and sparse control acknowledgements."""

    quintuple_basic: bool
    quintuple_arrays: dict[str, dict[int, float | bool | None]]
    outdoor_temperature: float
    error_code: int | None
    error_code_description: str | None

    def __init__(self, body: bytearray) -> None:
        """Register only present fields, leaving absent targets untouched."""
        fields = _read_fields(body)
        self.quintuple_basic = bool(fields)
        parsers: list[ValueParser] = [
            FunctionParser(
                "quintuple_arrays", 0, _basic_arrays, {}, length_in_bytes=len(body)
            ),
        ]
        for tag, name in BOOLEAN_FIELDS.items():
            if tag in fields:
                offset, width = fields[tag]
                parsers.append(
                    FunctionParser(name, offset, _on_off, None, length_in_bytes=width)
                )
        for tag, name in TEMPERATURE_FIELDS.items():
            if tag in fields:
                offset, width = fields[tag]
                if (
                    body[offset : offset + width]
                    != INVALID_TEMPERATURE.to_bytes(width, "big")
                    or name in TEMPERATURE_LIMIT_FIELDS
                    or name in TEMPERATURE_SENSOR_FIELDS
                ):
                    parsers.append(
                        FunctionParser(
                            name, offset, _temperature, None, length_in_bytes=width
                        )
                    )
        for tag, name, decoder in (
            (BasicTag.MODE, "mode", _mode),
            (AUTO_MODE_TAG, "mode_auto", _actual_mode),
            (ERROR_CODE_TAG, "error_code", _error_code),
        ):
            if tag in fields:
                offset, width = fields[tag]
                parsers.append(
                    FunctionParser(name, offset, decoder, None, length_in_bytes=width)
                )
        if ERROR_CODE_TAG in fields:
            offset, width = fields[ERROR_CODE_TAG]
            parsers.append(
                FunctionParser(
                    "error_code_description",
                    offset,
                    _error_description,
                    None,
                    length_in_bytes=width,
                )
            )
        for tag, names in STATUS_TEMPERATURE_ATTRIBUTES.items():
            if tag not in fields:
                continue
            offset, width = fields[tag]
            parsers.extend(
                FunctionParser(name, offset, _temperature, None, length_in_bytes=width)
                for name in names
                if body[offset : offset + width]
                != INVALID_TEMPERATURE.to_bytes(width, "big")
                or name in TEMPERATURE_SENSOR_FIELDS
            )
        super().__init__(body, parsers)


TELEMETRY_TABLE = 0x2F10
SIGNED_TEMPERATURE_MODULUS = 0x10000
TEMPERATURE_SIGN_BIT = 0x8000
TEMPERATURE_VALUE_MASK = 0x7FFF
TELEMETRY_TEMPERATURES = {
    "outdoor_temperature": 15,
    "temp_tw_in": 19,
    "temp_tw_out": 21,
    "temp_t1": 27,
    "temp_tw2": 29,
    "temp_ta": 37,
}


class MessageQueryTelemetry(MessageQuery2010):
    """Query the compact operating telemetry table."""

    @property
    def _body(self) -> bytearray:
        return _envelope(TELEMETRY_TABLE, 0)


def _telemetry_temperature(raw: bytearray) -> float | None:
    """Decode compact temperature values while preserving unavailable probes."""
    value = int.from_bytes(raw, "big")
    if value in (INVALID_TEMPERATURE, 0xFFFF):
        return None
    return (
        -(value & TEMPERATURE_VALUE_MASK) if value & TEMPERATURE_SIGN_BIT else value
    ) / TEMPERATURE_SCALE


class C3NativeTelemetryBody(MessageBody):
    """Read complete temperature fields from Lua's compact table 0x2F10."""

    def __init__(self, body: bytearray) -> None:
        """Register complete optional fields instead of accepting parser defaults."""
        parsers: list[ValueParser] = []
        if len(body) >= ENVELOPE_LENGTH and body[FORMAT_OFFSET] == 0:
            for name, offset in TELEMETRY_TEMPERATURES.items():
                if len(body) >= offset + 2:
                    parsers.append(
                        FunctionParser(
                            name,
                            offset,
                            _telemetry_temperature,
                            None,
                            length_in_bytes=2,
                        )
                    )
        super().__init__(body, parsers)


TEMP_NEG_VALUE = 127
ECO_FUNCTION_STATE_MASK = 0x01
ECO_TIMER_STATE_MASK = 0x02


class C3SilentLevel(IntEnum):
    """C3 Silent Level."""

    OFF = 0x0
    SILENT = 0x1
    SUPER_SILENT = 0x3


class C3DeviceMode(IntEnum):
    """C3 Device Mode."""

    COOL = 2
    HEAT = 3


class MessageC3Base(MessageRequest):
    """C3 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize C3 message base."""
        super().__init__(
            device_type=DeviceType.C3,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageC3Base):
    """C3 message query."""

    def __init__(self, protocol_version: int, body_type: ListTypes) -> None:
        """Initialize C3 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([])


class MessageQueryBasic(MessageQuery):
    """C3 Message query basic."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query basic."""
        super().__init__(protocol_version, ListTypes.X01)


class MessageQuerySilence(MessageQuery):
    """C3 Message query silence."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X05)


class MessageQueryECO(MessageQuery):
    """C3 Message query ECO."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X07)


class MessageQueryInstall(MessageQuery):
    """C3 Message query INSTALL."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X08)


class MessageQueryDisinfect(MessageQuery):
    """C3 Message query Disinfect."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X09)


class MessageQueryUnitPara(MessageQuery):
    """C3 Message query UNITPARA."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X10)


class MessageQueryHMIPara(MessageQuery):
    """C3 Message query HMIPARA."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message query silence."""
        super().__init__(protocol_version, ListTypes.X0A)


class MessageSet(MessageC3Base):
    """C3 message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X01,
        )
        self.zone1_power = False
        self.zone2_power = False
        self.dhw_power = False
        self.mode = 0
        self.zone_target_temp = [25.0, 25.0]
        self.dhw_target_temp = 40.0
        self.room_target_temp = 25.0
        self.zone1_curve = False
        self.zone2_curve = False
        self.fast_dhw = False
        self.tbh = False

    @property
    def _body(self) -> bytearray:
        # Byte 1
        zone1_power = 0x01 if self.zone1_power else 0x00
        zone2_power = 0x02 if self.zone2_power else 0x00
        dhw_power = 0x04 if self.dhw_power else 0x00
        # Byte 7
        zone1_curve = 0x01 if self.zone1_curve else 0x00
        zone2_curve = 0x02 if self.zone2_curve else 0x00
        tbh = 0x04 if self.tbh else 0x00
        fast_dhw = 0x08 if self.fast_dhw else 0x00
        room_target_temp = int(self.room_target_temp * 2)
        zone1_target_temp = int(self.zone_target_temp[0])
        zone2_target_temp = int(self.zone_target_temp[1])
        dhw_target_temp = int(self.dhw_target_temp)
        return bytearray(
            [
                zone1_power | zone2_power | dhw_power,
                self.mode,
                zone1_target_temp,
                zone2_target_temp,
                dhw_target_temp,
                room_target_temp,
                zone1_curve | zone2_curve | tbh | fast_dhw,
            ],
        )


class MessageSetSilent(MessageC3Base):
    """C3 message set silent."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message set silent."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X05,
        )
        self.silent_mode = False
        self.silent_level = C3SilentLevel.OFF

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [
                self.silent_level if self.silent_mode else C3SilentLevel.OFF,
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


class MessageSetECO(MessageC3Base):
    """C3 message set eco."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message set eco."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X07,
        )
        self.eco_mode = False

    @property
    def _body(self) -> bytearray:
        eco_mode = 0x01 if self.eco_mode else 0

        return bytearray([eco_mode, 0x00, 0x00, 0x00, 0x00, 0x00])


class MessageSetDisinfect(MessageC3Base):
    """C3 message set Disinfect."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C3 message set eco."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X09,
        )
        self.disinfect = False

    @property
    def _body(self) -> bytearray:
        disinfect = 0x01 if self.disinfect else 0

        return bytearray([disinfect, 0x00, 0x00, 0x00])


class C3BasicBody(MessageBody):
    """C3 Basic message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 message body."""
        super().__init__(body)
        # BodyBytes 1
        self.zone1_power = body[data_offset + 0] & 0x01 > 0
        self.zone2_power = body[data_offset + 0] & 0x02 > 0
        self.dhw_power = body[data_offset + 0] & 0x04 > 0
        self.zone1_curve = body[data_offset + 0] & 0x08 > 0
        self.zone2_curve = body[data_offset + 0] & 0x10 > 0
        self.tbh = body[data_offset + 0] & 0x20 > 0
        self.fast_dhw = body[data_offset + 0] & 0x40 > 0
        self.remote_onoff = body[data_offset + 0] & 0x80 > 0
        # BodyBytes 2
        self.heat = body[data_offset + 1] & 0x01 > 0
        self.cool = body[data_offset + 1] & 0x02 > 0
        self.dhw = body[data_offset + 1] & 0x04 > 0
        self.double_zone = body[data_offset + 1] & 0x08 > 0
        self.zone_temp_type = [
            body[data_offset + 1] & 0x10 > 0,
            body[data_offset + 1] & 0x20 > 0,
        ]
        self.room_thermal_support = body[data_offset + 1] & 0x40 > 0
        self.room_thermal_state = body[data_offset + 1] & 0x80 > 0
        # BodyBytes 3
        self.time_set = body[data_offset + 2] & 0x01 > 0
        self.silent_mode = body[data_offset + 2] & 0x02 > 0
        self.holiday_on = body[data_offset + 2] & 0x04 > 0
        self.eco_mode = body[data_offset + 2] & 0x08 > 0
        self.zone_terminal_type = body[data_offset + 2]
        # BodyBytes 4
        self.mode = body[data_offset + 3]
        self.mode_auto = body[data_offset + 4]
        # zone1, zone2
        self.zone_target_temp = [
            float(body[data_offset + 5]),
            float(body[data_offset + 6]),
        ]
        self.dhw_target_temp = float(body[data_offset + 7])
        self.room_target_temp = float(body[data_offset + 8] / 2)
        # zone1, zone2
        self.zone_heating_temp_max = [
            float(body[data_offset + 9]),
            float(body[data_offset + 13]),
        ]
        self.zone_heating_temp_min = [
            float(body[data_offset + 10]),
            float(body[data_offset + 14]),
        ]
        self.zone_cooling_temp_max = [
            float(body[data_offset + 11]),
            float(body[data_offset + 15]),
        ]
        self.zone_cooling_temp_min = [
            float(body[data_offset + 12]),
            float(body[data_offset + 16]),
        ]
        self.room_temp_max = float(body[data_offset + 17] / 2)
        self.room_temp_min = float(body[data_offset + 18] / 2)
        self.dhw_temp_max = float(body[data_offset + 19])
        self.dhw_temp_min = float(body[data_offset + 20])
        self.tank_actual_temperature = float(body[data_offset + 21])
        self.error_code = body[data_offset + 22]
        self.tbh_control = body[data_offset + 23] & 0x80 > 0
        self.SysEnergyAnaEN = body[data_offset + 23] & 0x20 > 0
        self.HMIEnergyAnaSetEN = body[data_offset + 23] & 0x40 > 0


class C3EnergyBody(MessageBody):
    """C3 Energy MSG_TYPE_UP_POWER4 message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 notify1 message body."""
        super().__init__(body)
        status_byte = body[data_offset]
        # bit0
        self.status_heating = (status_byte & 0x01) > 0
        # bit1
        self.status_cool = (status_byte & 0x02) > 0
        # bit2
        self.status_dhw = (status_byte & 0x04) > 0
        # bit3
        self.status_tbh = (status_byte & 0x08) > 0
        # bit4
        self.status_ibh = (status_byte & 0x10) > 0
        # total_energy_consumption
        self.total_energy_consumption = (
            (body[data_offset + 1] << 24)
            + (body[data_offset + 2] << 16)
            + (body[data_offset + 3] << 8)
            + (body[data_offset + 4])
        )
        # total_produced_energy
        self.total_produced_energy = (
            (body[data_offset + 5] << 24)
            + (body[data_offset + 6] << 16)
            + (body[data_offset + 7] << 8)
            + (body[data_offset + 8])
        )
        base_value = body[data_offset + 9]
        self.outdoor_temperature = float(
            (base_value - 256) if base_value > TEMP_NEG_VALUE else base_value,
        )  # outdoor_temperature is t4
        self.zone1_temp_set = float(body[data_offset + 10])
        self.zone2_temp_set = float(body[data_offset + 11])
        self.t5s = body[data_offset + 12]
        self.tas = body[data_offset + 13]


class C3SilenceBody(MessageBody):
    """C3 Silence message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 query silence message body."""
        super().__init__(body)
        self.silent_mode = body[data_offset] & 0x1 > 0
        self.silent_level = C3SilentLevel(
            (body[data_offset] & 0x1) + ((body[data_offset] & 0x8) >> 2)
            if self.silent_mode
            else C3SilentLevel.OFF.value,
        ).name
        # Message protocol information:
        # silence_function_state: Byte 1, BIT 0
        # silence_timer1_state: Byte 1, BIT 1
        # silence_timer2_state: Byte 1, BIT 2
        # silence_function_level: Byte 1, BIT 3
        # silence_timer1_starthour: Byte 2
        # silence_timer1_startmin: Byte 3
        # silence_timer1_endhour: Byte 4
        # silence_timer1_endmin: Byte 5
        # silence_timer2_starthour: Byte 6
        # silence_timer2_startmin: Byte 7
        # silence_timer2_endhour: Byte 8
        # silence_timer2_endmin: Byte 9


class C3ECOBody(MessageBody):
    """C3 ECO message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 ECO message body."""
        super().__init__(body)
        self.eco_function_state = (
            len(body) > data_offset and body[data_offset] & ECO_FUNCTION_STATE_MASK > 0
        )
        self.eco_timer_state = (
            len(body) > data_offset and body[data_offset] & ECO_TIMER_STATE_MASK > 0
        )
        # same bit MessageSetECO writes; absent byte must not clear the Basic value
        if len(body) > data_offset:
            self.eco_mode = self.eco_function_state


class C3DisinfectBody(MessageBody):
    """C3 Disinfect message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 Disinfect message body."""
        super().__init__(body)
        self.disinfect = body[data_offset] & 0x01 > 0
        self.disinfect_run = body[data_offset] & 0x02 > 0
        self.disinfect_set_weekday = body[data_offset + 1]
        self.disinfect_start_hour = body[data_offset + 2]
        self.disinfect_start_minutes = body[data_offset + 3]


class C3UnitParaBody(MessageBody):
    """C3 UnitPara message body."""

    def __init__(self, body: bytearray, data_offset: int = 0) -> None:
        """Initialize C3 UnitPara message body."""
        super().__init__(body)
        self.comp_run_freq = body[data_offset]
        self.unit_mode_run = body[data_offset + 1]
        self.fan_speed = body[data_offset + 3] * 10
        self.fg_capacity_need = body[data_offset + 5]
        self.temp_t3 = body[data_offset + 6]
        self.temp_t4 = body[data_offset + 7]
        self.temp_tp = body[data_offset + 8]
        self.temp_tw_in = body[data_offset + 9]
        self.temp_tw_out = body[data_offset + 10]
        self.temp_tsolar = body[data_offset + 11]
        self.hydbox_subtype = body[data_offset + 12]
        self.fg_usb_info_connect = body[data_offset + 13]
        # self.usb_index_max  body[data_offset + 14]
        # self.odu_comp_current  body[data_offset + 16]
        self.odu_voltage = body[data_offset + 17] * 256 + body[data_offset + 18]
        self.exv_current = body[data_offset + 19] * 256 + body[data_offset + 20]
        self.odu_model = body[data_offset + 21]
        # self.unit_online_num  body[data_offset + 22]
        # self.current_code  body[data_offset + 23]
        self.temp_t1 = body[data_offset + 33]
        self.temp_tw2 = body[data_offset + 34]
        self.temp_t2 = body[data_offset + 35]
        self.temp_t2b = body[data_offset + 36]
        self.temp_t5 = body[data_offset + 37]
        self.temp_ta = body[data_offset + 38]
        self.temp_tb_t1 = body[data_offset + 39]
        self.temp_tb_t2 = body[data_offset + 40]
        self.hydrobox_capacity = body[data_offset + 41]
        self.pressure_high = body[data_offset + 42] * 256 + body[data_offset + 43]
        self.pressure_low = body[data_offset + 44] * 256 + body[data_offset + 45]
        self.temp_th = body[data_offset + 46]
        self.machine_type = body[data_offset + 47]
        self.odu_target_fre = body[data_offset + 48]
        self.dc_current = body[data_offset + 49]
        self.temp_tf = body[data_offset + 51]
        self.idu_t1s1 = body[data_offset + 52]
        self.idu_t1s2 = body[data_offset + 53]
        self.water_flower = body[data_offset + 54] * 256 + body[data_offset + 55]
        self.odu_plan_vol_lmt = body[data_offset + 56]
        self.current_unit_capacity = body[data_offset + 57]
        self.sphera_ahs_voltage = body[data_offset + 59]
        self.temp_t4a_ver = body[data_offset + 60]
        self.water_pressure = body[data_offset + 61] * 256 + body[data_offset + 62]
        self.room_rel_hum = body[data_offset + 63]
        self.pwm_pump_out = body[data_offset + 63]
        self.total_electricity0 = (
            (body[data_offset + 66] << 24)
            + (body[data_offset + 67] << 16)
            + (body[data_offset + 68] << 8)
            + (body[data_offset + 69])
        )
        self.total_thermal0 = (
            (body[data_offset + 70] << 24)
            + (body[data_offset + 71] << 16)
            + (body[data_offset + 72] << 8)
            + (body[data_offset + 73])
        )
        self.heat_elec_total_consum0 = (
            (body[data_offset + 74] << 24)
            + (body[data_offset + 75] << 16)
            + (body[data_offset + 76] << 8)
            + (body[data_offset + 77])
        )
        self.heat_elec_total_capacity0 = (
            (body[data_offset + 78] << 24)
            + (body[data_offset + 79] << 16)
            + (body[data_offset + 80] << 8)
            + (body[data_offset + 81])
        )
        self.instant_power0 = (body[data_offset + 82] << 8) + (body[data_offset + 83])
        self.instant_renew_power0 = (body[data_offset + 84] << 8) + (
            body[data_offset + 85]
        )
        self.total_renew_power0 = (body[data_offset + 84] << 8) + (
            body[data_offset + 85]
        )


class MessageC3Response(MessageResponse):
    """C3 message response."""

    zone1_power: bool | None
    zone2_power: bool | None
    dhw_power: bool | None
    mode: int | None
    dhw_target_temp: float | None
    room_target_temp: float | None
    tank_actual_temperature: float | None
    outdoor_temperature: float | None
    dhw_temp_min: float | None
    dhw_temp_max: float | None
    quintuple_arrays: dict[str, dict[int, float | bool | None]]
    quintuple_energy: bool

    def __init__(self, message: bytes, model: str | None = None) -> None:
        """Initialize C3 message response."""
        super().__init__(bytearray(message))
        body = super().body
        if model == QUINTUPLE_MODEL:
            if self.body_type == ListTypes.X00 and self.message_type in (
                MessageType.query,
                MessageType.set,
                MessageType.notify1,
            ):
                table = int.from_bytes(body[1:3], "big")
                if table == BASIC_TABLE:
                    self.set_body(C3QuintupleBasicBody(body))
                elif table == ENERGY_TABLE and self.message_type != MessageType.set:
                    self.set_body(C3QuintupleEnergyBody(body))
                elif table == TELEMETRY_TABLE:
                    self.set_body(C3NativeTelemetryBody(body))
            self.set_attr()
            return
        if (
            self.message_type
            in [MessageType.set, MessageType.notify1, MessageType.query]
            and self.body_type == ListTypes.X01
        ) or self.message_type == MessageType.notify2:
            self.set_body(C3BasicBody(super().body, data_offset=1))
        elif (
            self.message_type == MessageType.notify1 and self.body_type == ListTypes.X04
        ):
            self.set_body(C3EnergyBody(super().body, data_offset=1))
        elif self.message_type == MessageType.query and self.body_type == ListTypes.X05:
            self.set_body(C3SilenceBody(super().body, data_offset=1))
        elif self.body_type == ListTypes.X07:
            self.set_body(C3ECOBody(super().body, data_offset=1))
        elif self.body_type == ListTypes.X09:
            self.set_body(C3DisinfectBody(super().body, data_offset=1))
        elif self.body_type == ListTypes.X10:
            self.set_body(C3UnitParaBody(super().body, data_offset=1))
        self.set_attr()
