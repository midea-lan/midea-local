"""Midea local C1 message.

Protocol layout follows Meiju Lua T_0000_C1_2760001Z (electric wall-hung boiler):
- Query: type 0x03, body 0x01 0x01 (status)
- Power set: type 0x02, body 0x01/0x02 + 0x01
- Segmented control: body 0x14; sub 0x04 heat (2760001Z profile)
"""

from midealan.const import MAX_BYTE_VALUE, DeviceType
from midealan.message import (
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

LONG_STATUS_MIN_LEN = 26

POWER_BIT = 0
STANDBY_BIT = 1
HEATING_BIT = 2
WARM_POWER_BIT = 3
COLD_POWER_BIT = 4
SLEEP_POWER_BIT = 5

ERR_F0_BIT = 0x01
ERR_F2_BIT = 0x01
ERR_E8_BIT = 0x80
ERR_E7_BIT = 0x40
ERR_E3_BIT = 0x10
ERR_E1_BIT = 0x04

PUMP_ON_BIT = 1
THREE_WAY_ALT_BIT = 2
RADIATOR_BIT = 3

QUERY_PAYLOAD = 0x01
POWER_PAYLOAD = 0x01
HEATING_SEGMENT_SUBTYPE = ListTypes.X04

HEATING_MODE_USER = 1
HEATING_MODE_ACTIVITY = 2
HEATING_MODE_SLEEP = 3
DEFAULT_TARGET_TEMPERATURE = 40.0

SET_LONG_BODY_TYPES = (ListTypes.X01, ListTypes.X02, ListTypes.X04, ListTypes.X14)
NOTIFY_LONG_BODY_TYPES = (ListTypes.X00, ListTypes.X01)

C1_HEATING_MODE_NAMES: dict[int, str] = {
    HEATING_MODE_USER: "user",
    HEATING_MODE_ACTIVITY: "activity",
    HEATING_MODE_SLEEP: "sleep",
}


def _error_code_from_raw(primary: int, secondary: int) -> str:  # noqa: PLR0911
    """Map Lua error bits (primary | secondary) to an error_code string."""
    if primary & ERR_F0_BIT:
        return "F0"
    if secondary & ERR_F2_BIT:
        return "F2"
    if primary & ERR_E8_BIT:
        return "E8"
    if primary & ERR_E7_BIT:
        return "E7"
    if primary & ERR_E3_BIT:
        return "E3"
    if primary & ERR_E1_BIT:
        return "E1"
    return "normal"


def c1_error_code(body: bytearray) -> str:
    """Return Lua-style error_code from body[3] and body[4] (priority order)."""
    primary = MessageBody.read_byte(body, ERROR_PRIMARY_BYTE)
    secondary = MessageBody.read_byte(body, ERROR_SECONDARY_BYTE)
    return _error_code_from_raw(primary, secondary)


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
    """C1 segmented set: space heating (Lua 0x14 / heating_target_temperature)."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize C1 heating segment set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X14,
        )
        self.heating_mode: int = HEATING_MODE_USER
        self.target_temperature: float = DEFAULT_TARGET_TEMPERATURE
        self.last_time: int = 0
        self.gap_temperature: int = 0

    @property
    def _body(self) -> bytearray:
        temp = round(self.target_temperature) & MAX_BYTE_VALUE
        return bytearray(
            [
                HEATING_SEGMENT_SUBTYPE,
                self.heating_mode & MAX_BYTE_VALUE,
                temp,
                self.last_time & MAX_BYTE_VALUE,
                self.gap_temperature & MAX_BYTE_VALUE,
            ],
        )


class C1GeneralMessageBody(MessageBody):
    """C1 long status body (Lua parseByteToJson main branch)."""

    power: bool
    standby: bool
    heating: bool
    warm_power: bool
    cold_power: bool
    sleep_power: bool
    error_code: str
    fault: bool
    return_temperature: float
    current_temperature: float
    heating_temperature: float
    heating_target_temperature: float
    heating_mode: str
    heating_gap_temperature: float
    last_time: int
    flow_volume: int
    pump_on: bool
    three_way_mode: str
    heating_unit_type: str
    user_mode_target_temperature: float
    activity_mode_target_temperature: float
    sleep_mode_target_temperature: float

    def __init__(self, body: bytearray) -> None:
        """Initialize C1 message general body."""
        super().__init__(body)
        flags = MessageBody.read_byte(body, FLAGS_BYTE)
        self.power = (flags & (1 << POWER_BIT)) != 0
        self.standby = (flags & (1 << STANDBY_BIT)) != 0
        self.heating = (flags & (1 << HEATING_BIT)) != 0
        self.warm_power = (flags & (1 << WARM_POWER_BIT)) != 0
        self.cold_power = (flags & (1 << COLD_POWER_BIT)) != 0
        self.sleep_power = (flags & (1 << SLEEP_POWER_BIT)) != 0
        self.error_code = c1_error_code(body)
        self.fault = self.error_code != "normal"
        self.return_temperature = float(MessageBody.read_byte(body, RETURN_TEMP_BYTE))
        self.current_temperature = float(MessageBody.read_byte(body, CURRENT_TEMP_BYTE))
        self.heating_temperature = float(
            MessageBody.read_byte(body, HEATING_TEMP_BYTE),
        )
        self.heating_target_temperature = float(
            MessageBody.read_byte(body, HEATING_TARGET_TEMP_BYTE),
        )
        mode_byte = MessageBody.read_byte(body, HEATING_MODE_BYTE)
        self.heating_mode = C1_HEATING_MODE_NAMES.get(mode_byte, "unknown")
        self.heating_gap_temperature = float(
            MessageBody.read_byte(body, HEATING_GAP_TEMP_BYTE),
        )
        self.last_time = MessageBody.read_byte(body, LAST_TIME_BYTE)
        self.flow_volume = MessageBody.read_byte(body, FLOW_VOLUME_BYTE)
        aux = MessageBody.read_byte(body, PACKED_AUX_BYTE)
        self.pump_on = (aux & (1 << PUMP_ON_BIT)) != 0
        self.three_way_mode = "bath" if (aux & (1 << THREE_WAY_ALT_BIT)) else "heating"
        self.heating_unit_type = (
            "radiator" if (aux & (1 << RADIATOR_BIT)) else "floor_heating"
        )
        self.user_mode_target_temperature = float(
            MessageBody.read_byte(body, USER_MODE_TARGET_BYTE),
        )
        self.activity_mode_target_temperature = float(
            MessageBody.read_byte(body, ACTIVITY_MODE_TARGET_BYTE),
        )
        self.sleep_mode_target_temperature = float(
            MessageBody.read_byte(body, SLEEP_MODE_TARGET_BYTE),
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
