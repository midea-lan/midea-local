"""Midea local C1 message.

Protocol layout follows Meiju Lua T_0000_C1_2760001Z (electric wall-hung boiler):
- Query: type 0x03, body 0x01 0x01 (status)
- Power set: type 0x02, body 0x01/0x02 + 0x01
- Segmented control: body 0x14; sub 0x04 heat (no hot_style segment for this model)
"""

from enum import IntEnum, IntFlag
from typing import Self

from midealocal.const import MAX_BYTE_VALUE, DeviceType
from midealocal.message import (
    BodyParser,
    BoolParser,
    FloatParser,
    IntEnumParser,
    IntFlagParser,
    IntParser,
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

# Status body offsets (Python body[n] = Lua bodyBytes[n + 11]).
FLAGS_BYTE = 2
ERROR_PRIMARY_BYTE = 3
ERROR_SECONDARY_BYTE = 4
RETURN_TEMP_BYTE = 7
CURRENT_TEMP_BYTE = 8
HEATING_TEMP_BYTE = 12
HEATING_TARGET_TEMP_BYTE = 13
HEATING_MODE_BYTE = 14
HEATING_GAP_TEMP_BYTE = 15
LAST_TIME_BYTE = 16
FLOW_VOLUME_BYTE = 19
PACKED_AUX_BYTE = 22
USER_MODE_TARGET_BYTE = 23
ACTIVITY_MODE_TARGET_BYTE = 24
SLEEP_MODE_TARGET_BYTE = 25

# Minimum body length for long status (profile temps at body[23:26]).
LONG_STATUS_MIN_LEN = 26

# Flag bits in FLAGS_BYTE (LSB = bit 0).
POWER_BIT = 0
STANDBY_BIT = 1
HEATING_BIT = 2
WARM_POWER_BIT = 3
COLD_POWER_BIT = 4
SLEEP_POWER_BIT = 5

PRIMARY_F0_MASK = 0x01
PRIMARY_E1_MASK = 0x04
PRIMARY_E3_MASK = 0x10
PRIMARY_E7_MASK = 0x40
PRIMARY_E8_MASK = 0x80
SECONDARY_F2_MASK = 0x01

# Packed aux bits in PACKED_AUX_BYTE.
PUMP_ON_BIT = 1
THREE_WAY_ALT_BIT = 2
RADIATOR_BIT = 3

QUERY_PAYLOAD = 0x01
POWER_PAYLOAD = 0x01
HEATING_SEGMENT_SUBTYPE = ListTypes.X04

DEFAULT_TARGET_TEMPERATURE = 40.0

SET_LONG_BODY_TYPES = (ListTypes.X01, ListTypes.X02, ListTypes.X04, ListTypes.X14)
NOTIFY_LONG_BODY_TYPES = (ListTypes.X00, ListTypes.X01)


class C1HeatingMode(IntEnum):
    """Space-heating mode (Lua mode codes 1-3)."""

    UNKNOWN = 0
    USER = 1
    ACTIVITY = 2
    SLEEP = 3

    @classmethod
    def from_lua_name(cls, name: str) -> Self:
        """Resolve a Lua mode name to a protocol code, defaulting to USER."""
        for mode in cls:
            if mode is not cls.UNKNOWN and mode.name.lower() == name:
                return mode
        return cls.USER

    @classmethod
    def protocol_codes(cls) -> tuple[Self, ...]:
        """Modes exposed for set/heating_modes (Lua codes 1-3)."""
        return (cls.USER, cls.ACTIVITY, cls.SLEEP)

    def to_protocol_code(self) -> int:
        """Wire byte for this mode; UNKNOWN maps to USER."""
        return int(C1HeatingMode.USER if self is C1HeatingMode.UNKNOWN else self)


class C1ThreeWayMode(IntEnum):
    """Three-way valve mode (packed aux bit THREE_WAY_ALT_BIT)."""

    HEATING = 0
    ALTERNATE = 1


class C1HeatingUnitType(IntEnum):
    """Heating terminal type (packed aux bit RADIATOR_BIT)."""

    FLOOR_HEATING = 0
    RADIATOR = 1


class C1ErrorCode(IntFlag):
    """Active C1 fault bits (Lua bodyBytes[14] and bodyBytes[15])."""

    NONE = 0
    F0 = 1 << 0
    F2 = 1 << 1
    E8 = 1 << 2
    E7 = 1 << 3
    E3 = 1 << 4
    E1 = 1 << 5


def c1_error_flags_from_raw(raw_value: int) -> C1ErrorCode:
    """Map packed error bytes (primary | secondary<<8) to active fault flags."""
    primary = raw_value & MAX_BYTE_VALUE
    secondary = (raw_value >> 8) & MAX_BYTE_VALUE
    flags = C1ErrorCode.NONE
    if primary & PRIMARY_F0_MASK:
        flags |= C1ErrorCode.F0
    if secondary & SECONDARY_F2_MASK:
        flags |= C1ErrorCode.F2
    if primary & PRIMARY_E8_MASK:
        flags |= C1ErrorCode.E8
    if primary & PRIMARY_E7_MASK:
        flags |= C1ErrorCode.E7
    if primary & PRIMARY_E3_MASK:
        flags |= C1ErrorCode.E3
    if primary & PRIMARY_E1_MASK:
        flags |= C1ErrorCode.E1
    return flags


def c1_fault_from_raw(raw_value: int) -> bool:
    """Return whether packed error bytes indicate any active fault."""
    return bool(c1_error_flags_from_raw(raw_value))


class C1BitIntEnumParser(BodyParser[IntEnum]):
    """Map a single bit to one of two IntEnum members."""

    def __init__(
        self,
        name: str,
        byte: int,
        bit: int,
        *,
        when_set: IntEnum,
        when_clear: IntEnum,
    ) -> None:
        """Initialize bit-to-enum parser."""
        super().__init__(name, byte, bit)
        self._when_set = when_set
        self._when_clear = when_clear

    def _parse(self, raw_value: int) -> IntEnum:
        """Return when_set if the bit is 1, otherwise when_clear."""
        return self._when_set if raw_value else self._when_clear


def c1_error_code(body: bytearray) -> C1ErrorCode:
    """Return active C1 error flags from body[3] and body[4]."""
    return IntFlagParser(
        "error_code",
        ERROR_PRIMARY_BYTE,
        decode=c1_error_flags_from_raw,
        length_in_bytes=2,
        first_upper=False,
    ).get_value(body)


def c1_long_status_applies(message_type: MessageType, body_type: int) -> bool:
    """Return whether the Lua long-status parse branch applies."""
    bt = int(body_type)
    return (
        (message_type == MessageType.set and bt in SET_LONG_BODY_TYPES)
        or (message_type == MessageType.query and bt == ListTypes.X01)
        or (message_type == MessageType.notify1 and bt in NOTIFY_LONG_BODY_TYPES)
    )


class MessageC1Base(MessageRequest):
    """C1 message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize C1 message base."""
        super().__init__(
            device_type=DeviceType.C1,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageC1Base):
    """C1 message query (full status)."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C1 message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([QUERY_PAYLOAD])


class MessagePower(MessageC1Base):
    """C1 message power."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C1 message power."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X02,
        )
        self.power = False

    @property
    def _body(self) -> bytearray:
        if self.power:
            self.body_type = ListTypes.X01
        else:
            self.body_type = ListTypes.X02
        return bytearray([POWER_PAYLOAD])


class MessageSetHeating(MessageC1Base):
    """C1 segmented set: space heating (Lua 0x14, heating_target_temperature)."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C1 heating segment set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X14,
        )
        self.heating_mode: C1HeatingMode | int = C1HeatingMode.USER
        self.target_temperature: float = DEFAULT_TARGET_TEMPERATURE
        self.last_time: int = 0
        self.gap_temperature: int = 0

    @property
    def _body(self) -> bytearray:
        temp = round(self.target_temperature) & MAX_BYTE_VALUE
        return bytearray(
            [
                HEATING_SEGMENT_SUBTYPE,
                int(self.heating_mode) & MAX_BYTE_VALUE,
                temp,
                self.last_time & MAX_BYTE_VALUE,
                self.gap_temperature & MAX_BYTE_VALUE,
            ],
        )


class C1GeneralMessageBody(MessageBody):
    """C1 long status body (Lua parseByteToJson main branch).

    Lua bodyBytes index n maps to Python body[n - 11] when aligned to frame.
    """

    power: bool
    standby: bool
    heating: bool
    warm_power: bool
    cold_power: bool
    sleep_power: bool
    error_code: C1ErrorCode
    fault: bool
    return_temperature: float
    current_temperature: float
    heating_temperature: float
    heating_target_temperature: float
    heating_mode: C1HeatingMode
    heating_gap_temperature: float
    last_time: int
    flow_volume: int
    pump_on: bool
    three_way_mode: C1ThreeWayMode
    heating_unit_type: C1HeatingUnitType
    user_mode_target_temperature: float
    activity_mode_target_temperature: float
    sleep_mode_target_temperature: float

    def __init__(self, body: bytearray) -> None:
        """Initialize C1 message general body."""
        super().__init__(
            body,
            [
                BoolParser("power", FLAGS_BYTE, POWER_BIT, default_value=False),
                BoolParser("standby", FLAGS_BYTE, STANDBY_BIT, default_value=False),
                BoolParser("heating", FLAGS_BYTE, HEATING_BIT, default_value=False),
                BoolParser(
                    "warm_power",
                    FLAGS_BYTE,
                    WARM_POWER_BIT,
                    default_value=False,
                ),
                BoolParser(
                    "cold_power",
                    FLAGS_BYTE,
                    COLD_POWER_BIT,
                    default_value=False,
                ),
                BoolParser(
                    "sleep_power",
                    FLAGS_BYTE,
                    SLEEP_POWER_BIT,
                    default_value=False,
                ),
                IntFlagParser(
                    "error_code",
                    ERROR_PRIMARY_BYTE,
                    decode=c1_error_flags_from_raw,
                    length_in_bytes=2,
                    first_upper=False,
                ),
                BoolParser(
                    "fault",
                    ERROR_PRIMARY_BYTE,
                    decode=c1_fault_from_raw,
                    length_in_bytes=2,
                    first_upper=False,
                    default_value=False,
                ),
                FloatParser("return_temperature", RETURN_TEMP_BYTE),
                FloatParser("current_temperature", CURRENT_TEMP_BYTE),
                FloatParser("heating_temperature", HEATING_TEMP_BYTE),
                FloatParser("heating_target_temperature", HEATING_TARGET_TEMP_BYTE),
                IntEnumParser(
                    "heating_mode",
                    HEATING_MODE_BYTE,
                    enum_class=C1HeatingMode,
                    default_value=C1HeatingMode.UNKNOWN,
                ),
                FloatParser("heating_gap_temperature", HEATING_GAP_TEMP_BYTE),
                IntParser("last_time", LAST_TIME_BYTE),
                IntParser("flow_volume", FLOW_VOLUME_BYTE),
                BoolParser(
                    "pump_on",
                    PACKED_AUX_BYTE,
                    PUMP_ON_BIT,
                    default_value=False,
                ),
                C1BitIntEnumParser(
                    "three_way_mode",
                    PACKED_AUX_BYTE,
                    THREE_WAY_ALT_BIT,
                    when_set=C1ThreeWayMode.ALTERNATE,
                    when_clear=C1ThreeWayMode.HEATING,
                ),
                IntEnumParser(
                    "heating_unit_type",
                    PACKED_AUX_BYTE,
                    C1HeatingUnitType,
                    RADIATOR_BIT,
                ),
                FloatParser("user_mode_target_temperature", USER_MODE_TARGET_BYTE),
                FloatParser(
                    "activity_mode_target_temperature",
                    ACTIVITY_MODE_TARGET_BYTE,
                ),
                FloatParser("sleep_mode_target_temperature", SLEEP_MODE_TARGET_BYTE),
            ],
        )


class MessageC1Response(MessageResponse):
    """C1 message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize C1 message response."""
        super().__init__(bytearray(message))
        raw = super().body
        bt = int(self.body_type)
        long_ok = (
            c1_long_status_applies(self.message_type, bt)
            and len(raw) >= LONG_STATUS_MIN_LEN
        )
        if long_ok:
            self.set_body(C1GeneralMessageBody(raw))
        self.set_attr()
