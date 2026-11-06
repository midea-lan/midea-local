"""Native tables for C3 model 17100007, based on vendor Lua 0.0.27.

Ported from wuwentao/midea-lan#261. Other C3 models retain their legacy codec.
"""

from enum import IntEnum
from math import isfinite

from midealocal.const import DeviceType
from midealocal.message import (
    IntParser,
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageType,
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
) -> dict[int, bytes]:
    """Decode one table and reject malformed TLVs without partial results."""
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
                values[tag] = bytes(body[offset : offset + size])
            offset += size
    elif body[FORMAT_OFFSET] == 0:
        if len(body) < minimum_length:
            return {}
        for tag, size in enumerate(sizes):
            if offset + size > len(body):
                break
            values[tag] = bytes(body[offset : offset + size])
            offset += size
    return values


def _temperature(raw: bytes) -> float | None:
    """Decode signed basic-table tenths, leaving invalid probes unavailable."""
    value = IntParser(
        "temperature", 0, length_in_bytes=len(raw), first_upper=True
    ).get_value(bytearray(raw))
    if value == INVALID_TEMPERATURE:
        return None
    if value & TEMPERATURE_SIGN_BIT:
        value -= SIGNED_TEMPERATURE_MODULUS
    return value / TEMPERATURE_SCALE


class C3QuintupleEnergyBody(MessageBody):
    """Decode 0x2F12 energy using the vendor's 0.01 kW/kWh scale."""

    # These are controller-reported values. Their reset periods and inclusion
    # of standby, circulation, or auxiliary loads are not established, so they
    # must not be treated as billing-grade whole-appliance measurements.
    # Tags 3 and 4 retain watts for the existing instant-power attributes;
    # energy counters use kWh and other table powers use kW.

    quintuple_energy: bool
    current_unit_capacity: float | None
    instant_renew_power0: float | None
    instant_power0: float | None
    total_produced_energy: float | None
    total_energy_consumption: float | None

    def __init__(self, body: bytearray) -> None:
        """Expose complete energy fields from sequential or TLV packets."""
        super().__init__(body)
        values = _read_fields(body, ENERGY_SIZES, MIN_ENERGY_LENGTH)
        self.quintuple_energy = bool(values)
        for tag, name in QUINTUPLE_ENERGY_FIELDS.items():
            if tag in values:
                raw = values[tag]
                value = IntParser(
                    "value", 0, length_in_bytes=len(raw), first_upper=True
                ).get_value(bytearray(raw))
                invalid = (1 << (len(raw) * BYTE_BITS)) - 1
                scaled = (
                    value * WATTS_PER_ENERGY_UNIT
                    if tag in WATT_TAGS
                    else value / ENERGY_SCALE
                )
                setattr(self, name, None if value == invalid else scaled)


class C3QuintupleBasicBody(MessageBody):
    """Decode sequential status and sparse control acknowledgements."""

    quintuple_basic: bool
    quintuple_arrays: dict[str, dict[int, float | bool | None]]
    outdoor_temperature: float

    def __init__(self, body: bytearray) -> None:
        """Expose valid fields, retaining absent array members in the device."""
        super().__init__(body)
        values = _read_fields(body)
        self.quintuple_basic = bool(values)
        self.quintuple_arrays = {}
        for tag, name in BOOLEAN_FIELDS.items():
            if tag in values:
                raw = values[tag][0]
                setattr(self, name, bool(raw) if raw in (0, 1) else None)
        for tag, name in TEMPERATURE_FIELDS.items():
            if tag in values and (
                (value := _temperature(values[tag])) is not None
                or name in TEMPERATURE_LIMIT_FIELDS
                or name in TEMPERATURE_SENSOR_FIELDS
            ):
                setattr(self, name, value)
        for name, tags in ARRAY_FIELDS.items():
            changes: dict[int, float | bool | None] = {
                index: value
                for index, tag in enumerate(tags)
                if tag in values
                and (
                    (value := _temperature(values[tag])) is not None
                    or name != "zone_target_temp"
                )
            }
            if changes:
                self.quintuple_arrays[name] = changes
        types: dict[int, float | bool | None] = {
            index: values[tag][0] == 0 if values[tag][0] in (0, 1) else None
            for index, tag in enumerate(ZONE_TEMP_TYPE_TAGS)
            if tag in values
        }
        if types:
            self.quintuple_arrays["zone_temp_type"] = types
        if BasicTag.MODE in values:
            self.mode = MODE_FROM_WIRE.get(values[BasicTag.MODE][0])
        if AUTO_MODE_TAG in values:
            self.mode_auto = (
                values[AUTO_MODE_TAG][0] + 1
                if values[AUTO_MODE_TAG][0] in (1, 2)
                else None
            )
        if ERROR_CODE_TAG in values:
            error_code = values[ERROR_CODE_TAG][0]
            self.error_code = None if error_code == INVALID_BYTE else error_code
            self.error_code_description = (
                None
                if error_code == INVALID_BYTE
                else "No error"
                if error_code == 0
                else f"Unknown code (raw={error_code})"
            )
        for tag, names in STATUS_TEMPERATURE_ATTRIBUTES.items():
            if tag not in values:
                continue
            value = _temperature(values[tag])
            for name in names:
                if value is not None or name in TEMPERATURE_SENSOR_FIELDS:
                    setattr(self, name, value)


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


class C3NativeTelemetryBody(MessageBody):
    """Read complete temperature fields from Lua's compact table 0x2F10."""

    def __init__(self, body: bytearray) -> None:
        """Decode signed-magnitude temperatures without fabricating missing fields."""
        super().__init__(body)
        if len(body) < ENVELOPE_LENGTH or body[FORMAT_OFFSET] != 0:
            return
        for name, offset in TELEMETRY_TEMPERATURES.items():
            if len(body) < offset + 2:
                continue
            raw = IntParser(
                name, offset, length_in_bytes=2, first_upper=True
            ).get_value(body)
            value = (
                None
                if raw in (INVALID_TEMPERATURE, 0xFFFF)
                else (
                    -(raw & TEMPERATURE_VALUE_MASK)
                    if raw & TEMPERATURE_SIGN_BIT
                    else raw
                )
                / TEMPERATURE_SCALE
            )
            setattr(self, name, value)
