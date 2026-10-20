"""Midea AC message."""

import logging
from collections.abc import Callable, Mapping
from enum import IntEnum, StrEnum
from types import MappingProxyType

from midealocal.base_classes.climate import MideaFanMode, MideaSwingMode
from midealocal.const import MAX_BYTE_VALUE, DeviceType
from midealocal.crc8 import calculate
from midealocal.message import (
    BoolParser,
    FloatParser,
    FunctionParser,
    IntParser,
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
    NewProtocolMessageBody,
)

_LOGGER = logging.getLogger(__name__)

A1_MIN_BODY_LENGTH = 18

BB_AC_MODES = [0, 3, 1, 2, 4, 5]
BB_MIN_BODY_LENGTH = 21
BB_FRESH_AIR_SWITCH_INDEX = 45
BB_FRESH_AIR_INTAKE_STATUS_MASK = 0x01
BB_FRESH_AIR_EXHAUST_STATUS_MASK = 0x02
BB_FRESH_AIR_INTAKE_SPEED_INDEX = 46
BB_FRESH_AIR_EXHAUST_SPEED_INDEX = 47
BB_COMPRESSOR_TARGET_FREQUENCY_INDEX = 10
BB_COMPRESSOR_FREQUENCY_INDEX = 11
BB_BASIC_FAN_SPEED_INDEX = 7
BB_INDOOR_TEMPERATURE_HIGH_INDEX = 8
BB_INDOOR_HUMIDITY_INDEX = 30
BB_SN8_FLAG_INDEX = 80
BB_OUTDOOR_TEMPERATURE_HIGH_INDEX = 6
BX_FILTER_STATUS_LENGTH = 5
CONFORT_MODE_MIN_LENGTH = 16
CONFORT_MODE_MIN_LENGTH2 = 23
SMART_DRY_MIN_LENGTH = 20
SWING_LR_MIN_LENGTH = 21
FRESH_AIR_C0_MIN_LENGTH = 29
ECO_MODE_MIN_SUBPROTOCOL_LENGTH = 27
FRESH_AIR_LENGTH = 2
FROST_PROTECT_MIN_LENGTH = 22
INDIRECT_WIND_VALUE = 0x02
MAX_MSG_SERIAL_NUM = 254
OUT_SILENT_VALUE = 0x03
POWER_SAVING_VALUE = 0x08
SCREEN_DISPLAY_BYTE_CHECK = 0x07
SUB_PROTOCOL_BODY_TEMP_CHECK = 0x80
TEMP_DECIMAL_MIN_BODY_LENGTH = 20
TIMER_MIN_SUBPROTOCOL_LENGTH = 27
XBB_SN8_BYTE_FLAG = 0x31
XC1_SUBBODY_TYPE_03 = 0x03
XC1_SUBBODY_TYPE_40 = 0x40
XC1_SUBBODY_TYPE_41 = 0x41
XC1_SUBBODY_TYPE_42 = 0x42
XC1_SUBBODY_TYPE_43 = 0x43
XC1_SUBBODY_TYPE_44 = 0x44
XC1_SUBBODY_TYPE_45 = 0x45
XC1_SUBBODY_TYPE_47 = 0x47
XC1_SUBBODY_TYPE_INDEX = 3
XC1_HUMIDITY_INDEX = 4
XC1_CONSUMPTION_MIN_LENGTH = 19
XC1_OPERATING_TIME_MIN_LENGTH = 19

# Group data query: the third payload byte selects the group, 0x40 | group number.
XC1_GROUP_QUERY_BASE = 0x40
XC1_GROUP_THREE_SPEED_OFFSET = 10
# Minimum body length required to parse each group data response.
XC1_GROUP_ONE_MIN_LENGTH = 15
XC1_GROUP_TWO_MIN_LENGTH = 9
XC1_GROUP_SEVEN_MIN_LENGTH = 12
# Refrigerant circuit temperatures are reported as half degrees with an offset:
# T1/T2 (indoor ambient / indoor coil) use 30, T3/T4 (outdoor coil / ambient) use 50.
TEMP_INDOOR_OFFSET = 30
XC1_TEMP_OUTDOOR_OFFSET = 50
TEMP_DIVISOR = 2
# Indoor fan speed is reported in units of 8 RPM.
XC1_FAN_SPEED_FACTOR = 8
# Bit 4 of group 2 byte 8 indicates the condensate water pump is running.
XC1_WATER_PUMP_MASK = 0x10

BB_FRESH_AIR_CONTROL_BODY_LENGTH = 96
BB_FRESH_AIR_CONTROL_CURSOR = 15
BB_FRESH_AIR_INTAKE_SWITCH_MASK = 0x04
BB_FRESH_AIR_EXHAUST_SWITCH_MASK = 0x08
BB_FRESH_AIR_INTAKE_CONTROL_SPEED_INDEX = 55
BB_FRESH_AIR_EXHAUST_CONTROL_SPEED_INDEX = 56
BB_FRESH_AIR_SPEED_FLAG = 0x80

# Model 22013279 reports temperatures in this new-protocol tag because its
# standard C0 temperature fields are stale.
NEW_PROTOCOL_TEMPERATURE_TAG = 0x7E
NEW_PROTOCOL_TEMPERATURE_MIN_LENGTH = 41
NEW_PROTOCOL_SETPOINT_OFFSET = 11.5
NEW_PROTOCOL_SETPOINT_MASK = 0x3F
NEW_PROTOCOL_SETPOINT_HALF_DEGREE_BIT = 0x40
NEW_PROTOCOL_MIN_VALID_TEMPERATURE = 10
NEW_PROTOCOL_MAX_VALID_TEMPERATURE = 40
NEW_PROTOCOL_LEGACY_SETPOINT_BYTE = 3
NEW_PROTOCOL_INDOOR_TEMPERATURE_BYTE = 40
NEW_PROTOCOL_INDOOR_TEMPERATURE_DECIMAL_BYTE = 41

# B5 capability value semantics (reverse-engineered; see _parse_capabilities).
# The raw byte of each capability is not a 0/1 flag; each has its own value set.
B5_HEAT_MODE_VALUES = frozenset({1, 2, 4, 6, 7, 9, 10, 11, 12, 13})
B5_NO_COOL_MODE_VALUES = frozenset({2, 10, 12})
B5_DRY_MODE_VALUES = frozenset({0, 1, 5, 6, 9, 11, 13})
B5_AUTO_MODE_VALUES = frozenset({0, 1, 2, 7, 8, 9, 13})
B5_SWING_HORIZONTAL_VALUES = frozenset({1, 3})
B5_LOW_VALUE_MAX = 2  # value < 2 -> vertical swing / cool turbo available
B5_FAN_LOW_HIGH_VALUES = frozenset({3, 4, 5, 6, 7, 9})
B5_FAN_MEDIUM_VALUES = frozenset({5, 6, 7})
B5_FAN_AUTO_VALUES = frozenset({4, 5, 6, 9})
B5_FAN_SILENT_VALUES = frozenset({6, 9})
B5_FAN_CUSTOM_VALUE = 1
B5_ECO_VALUES = frozenset({1, 2})
B5_ANION_ON_VALUE = 1
B5_TURBO_HEAT_VALUES = frozenset({1, 3})
B5_DISPLAY_VALUES = frozenset({1, 2, 100})
B5_ELECTRICITY_UNSUPPORTED_VALUE = 0  # 0 = unsupported; nonzero = rate level count
B5_ENERGY_STATS_VALUES = frozenset({2, 3, 4, 5})
B5_ENERGY_SETTING_VALUES = frozenset({3, 5})
B5_ENERGY_BCD_VALUES = frozenset({2, 3})
RATE_SELECT_2_LEVEL_BIT = 0x1
RATE_SELECT_5_LEVEL_BIT = 0x2
B5_HUMIDITY_SUPPORTED_MASK = 0x3

# Indoor humidity is a percentage (1..100). 0x00 (not reported) and 0xFF
# (sensor absent or faulted) are placeholders, not real readings.
INVALID_INDOOR_HUMIDITY = frozenset({0, MAX_BYTE_VALUE})


def parse_indoor_humidity(raw: int) -> int | None:
    """Return the indoor humidity byte, or None for the invalid placeholders."""
    return None if raw in INVALID_INDOOR_HUMIDITY else raw


class DeviceAttributes(StrEnum):
    """Midea AC device attributes."""

    prompt_tone = "prompt_tone"
    power = "power"
    mode = "mode"
    target_temperature = "target_temperature"
    min_temperature = "min_temperature"
    max_temperature = "max_temperature"
    fan_speed = "fan_speed"
    swing_vertical = "swing_vertical"
    swing_horizontal = "swing_horizontal"
    boost_mode = "boost_mode"
    power_saving = "power_saving"
    smart_eye = "smart_eye"
    dry = "dry"
    eco_mode = "eco_mode"
    aux_heating = "aux_heating"
    sleep_mode = "sleep_mode"
    natural_wind = "natural_wind"
    temp_fahrenheit = "temp_fahrenheit"
    screen_display = "screen_display"
    screen_display_alternate = "screen_display_alternate"
    full_dust = "full_dust"
    frost_protect = "frost_protect"
    comfort_mode = "comfort_mode"
    indoor_temperature = "indoor_temperature"
    outdoor_temperature = "outdoor_temperature"
    indirect_wind = "indirect_wind"
    indoor_humidity = "indoor_humidity"
    breezeless = "breezeless"
    fresh_air_power = "fresh_air_power"
    fresh_air_fan_speed = "fresh_air_fan_speed"
    fresh_air_mode = "fresh_air_mode"
    fresh_air_1 = "fresh_air_1"
    fresh_air_2 = "fresh_air_2"
    fresh_air_exhaust_power = "fresh_air_exhaust_power"
    fresh_air_exhaust_speed = "fresh_air_exhaust_speed"
    fresh_air_exhaust_mode = "fresh_air_exhaust_mode"
    total_energy_consumption = "total_energy_consumption"
    total_operating_consumption = "total_operating_consumption"
    current_energy_consumption = "current_energy_consumption"
    realtime_power = "realtime_power"
    electrify_time = "electrify_time"
    total_operating_time = "total_operating_time"
    current_operating_time = "current_operating_time"
    wind_lr_angle = "wind_lr_angle"
    wind_ud_angle = "wind_ud_angle"
    rate_select = "rate_select"
    out_silent = "out_silent"
    anion = "anion"
    sound = "sound"
    self_clean = "self_clean"
    pmv = "pmv"
    error_code = "error_code"
    # group 1: compressor and refrigerant circuit
    compressor_frequency = "compressor_frequency"
    target_compressor_frequency = "target_compressor_frequency"
    compressor_current = "compressor_current"
    compressor_voltage = "compressor_voltage"
    indoor_ambient_temperature = "indoor_ambient_temperature"  # T1
    indoor_coil_temperature = "indoor_coil_temperature"  # T2
    outdoor_coil_temperature = "outdoor_coil_temperature"  # T3
    outdoor_ambient_temperature = "outdoor_ambient_temperature"  # T4
    discharge_pipe_temperature = "discharge_pipe_temperature"  # TP
    # group 2: indoor fan and condensate pump
    indoor_fan_speed = "indoor_fan_speed"
    target_indoor_fan_speed = "target_indoor_fan_speed"
    water_pump_running = "water_pump_running"
    # group 3: outdoor fan
    outdoor_fan_speed = "outdoor_fan_speed"
    # group 7: real time compressor power
    compressor_power = "compressor_power"


class ACFanSpeed(MideaFanMode):
    """AC fan speed set-points.

    fan_speed is reported as a 0-127 percentage-like value; a device only
    ever commands one of these six set-points, but reported values are
    bucketed by threshold (against the next-lower set-point) to tolerate
    slightly-off readings from hardware.
    """

    SILENT = 20
    LOW = 40
    MEDIUM = 60
    HIGH = 80
    FULL = 100
    AUTO = 102


class ACSwingMode(MideaSwingMode):
    """AC swing mode names.

    A StrEnum (not IntEnum, unlike ACFanSpeed): its members compare equal to
    plain strings, which is required since Home Assistant's climate contract
    checks membership with bare strings (e.g. "off" in device.swing_modes).
    """

    OFF = "off"
    VERTICAL = "vertical"
    HORIZONTAL = "horizontal"
    BOTH = "both"


class PowerFormats(IntEnum):
    """AC Power/Energy analysis formats."""

    # unless stated, consumption / energy is 0.01 kWh, and power in 0.1 W resolution
    BCD = 1
    BINARY = 2  # binary with energy in 0.1 kWh resolution
    MIXED = 3  # mixed/INT (byte = 0-99)
    BINARY1 = 12  # binary
    BCD_ENERGY_BINARY_POWER = 101


class NewProtocolTags(IntEnum):
    """New protocol tags in query and response."""

    arom = 0x0069
    auto_prevent_straight_wind = 0x0226
    b5_anion = 0x021E
    b5_eco = 0x0212
    b5_electricity = 0x0216
    b5_fahrenheit = 0x0222
    b5_filter_check = 0x0221
    b5_filter_remind = 0x0217
    b5_humidity = 0x021F
    b5_mode = 0x0214
    b5_ptc = 0x0219
    b5_screen_display = 0x0224
    b5_sound = 0x022C
    b5_strong_wind = 0x021A
    b5_temperature = 0x0225
    b5_wind_speed = 0x0210
    b5_wind_swing = 0x0215
    breezeless = 0x0018  # queryType == "fn_no_wind_sense"
    buzzer_all = 0x022C
    child_lock = 0x005C
    child_prevent_cold_wind = 0x003A
    cool_hot_sense = 0x0021
    degerming = 0x005A
    dust_full_time_reset = 0x00B8
    error_code_query = 0x003F
    even_wind = 0x004E
    extreme_wind = 0x004C
    face_register = 0x0044
    filter_level = 0x0409
    filter_status = 0x003D
    fresh_air_1 = 0x0233
    fresh_air_2 = 0x004B  # queryType == "fresh_air"
    fresh_air_parm = 0x0250
    fresh_filter_reset = 0x0085
    gentle_wind_sense = 0x0043
    high_temp_remove_odor_alone = 0x005E
    high_temperature_monitor = 0x0047
    indirect_wind = 0x0042  # prevent_straight_wind
    indoor_humidity = 0x0015  # queryType == "indoor_humidity"
    intelligent_control = 0x0031
    intelligent_wind = 0x0034
    light = 0x005B
    little_angel = 0x021B
    mode_query = 0x0041
    nobody_energy_save = 0x0030
    offline_operating_time = 0x022B
    operating_time = 0x0228
    out_silent = 0x00CD
    ozone = 0x005F
    parent_control = 0x0051
    pm25_value = 0x020B
    pre_cool_hot = 0x0201
    prevent_straight_wind_lr = 0x0058
    prevent_super_cool = 0x0049
    prompt_tone = 0x001A  # buzzerValue
    ptc_lock = 0x0229
    rate_select = 0x0048
    remote_control_lock = 0x0227  # power_lock?
    rewarming_dry = 0x0068
    screen_display = 0x0017
    security = 0x0029
    # Live self-clean status. Reported in B0 (set echo) and B1 (query) bodies.
    # The same tag in a B5 capability body only advertises support, not state.
    self_clean = 0x0039
    self_remove_odor_phase = 0x005D
    single_tuyere = 0x004F
    soft_warm = 0x0063
    voice_control = 0x0020
    volume_control = 0x0024
    water_pump = 0x0050
    water_washing = 0x004A
    wind_around = 0x0059
    wind_avoid = 0x0033
    wind_lr_angle = 0x000A
    wind_straight = 0x0032
    wind_top = 0x0061
    wind_ud_angle = 0x0009
    wet_film_reset = 0x00CC


class MessageACBase(MessageRequest):
    """AC message base."""

    _message_serial = 0

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize AC message base."""
        super().__init__(
            device_type=DeviceType.AC,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )
        MessageACBase._message_serial += 1
        if MessageACBase._message_serial >= MAX_MSG_SERIAL_NUM:
            MessageACBase._message_serial = 1
        self._message_id = MessageACBase._message_serial

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError

    @property
    def body(self) -> bytearray:
        """AC message base body."""
        body = bytearray([self.body_type]) + self._body + bytearray([self._message_id])
        body.append(calculate(body))
        return body


class MessageA0Query(MessageACBase):
    """AC message query(queryType == "a0_query")."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.A0,
        )

    @property
    def _body(self) -> bytearray:
        """Head 0x41 + query_body + _message_id + crc."""
        query_body = bytearray(1)
        query_body[0] = 0xA7
        return query_body


class MessageA0LongQuery(MessageACBase):
    """AC message query(queryType == "a0_query_long")."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.A0,
        )

    @property
    def _body(self) -> bytearray:
        """Head 0x41 + query_body + _message_id + crc."""
        return bytearray(19)


class MessageQuery(MessageACBase):
    """AC message query(queryType == nil)."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )

    @property
    def _body(self) -> bytearray:
        """Head 0x41 + query_body + _message_id + crc."""
        query_body = bytearray(19)
        query_body[0] = 0x81
        query_body[2] = 0xFF
        return query_body


class MessageCapabilitiesQuery(MessageACBase):
    """AC message capabilities query(queryType == "all_first_frame")."""

    def __init__(
        self,
        protocol_version: int,
        additional_capabilities: bool = False,
    ) -> None:
        """Initialize AC message capabilities query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.B5,
        )
        self._additional_capabilities = additional_capabilities

    @property
    def _body(self) -> bytearray:
        if self._additional_capabilities:
            return bytearray([0x01, 0x01, 0x01])
        return bytearray([0x01, 0x00])


class MessageCapabilitiesAdditionalQuery(MessageCapabilitiesQuery):
    """AC message capabilities additional query(queryType == "all_second_frame")."""

    def __init__(
        self,
        protocol_version: int,
    ) -> None:
        """Initialize AC message capabilities additional query."""
        super().__init__(
            protocol_version=protocol_version,
            additional_capabilities=True,  # Always set to True for this class
        )


class MessageGroupDataQuery(MessageACBase):
    """AC message group data query(queryType == "group_data_<group>")."""

    _group = 0

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message group data query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray(
            [0x21, 0x01, XC1_GROUP_QUERY_BASE | self._group, 0x00, 0x01],
        )

    @property
    def body(self) -> bytearray:
        """AC message group data query body."""
        body = bytearray([self.body_type]) + self._body
        body.append(calculate(body))
        return body


class MessageGroupZeroQuery(MessageGroupDataQuery):
    """AC message power query(queryType == "group_data_zero")."""

    _group = 0


class MessageGroupOneQuery(MessageGroupDataQuery):
    """AC message compressor query(queryType == "group_data_one")."""

    _group = 1


class MessageGroupTwoQuery(MessageGroupDataQuery):
    """AC message indoor fan query(queryType == "group_data_two")."""

    _group = 2


class MessageGroupThreeQuery(MessageGroupDataQuery):
    """AC message outdoor fan query(queryType == "group_data_three")."""

    _group = 3


class MessagePowerQuery(MessageGroupDataQuery):
    """AC message power query(queryType == "group_data_four")."""

    _group = 4


class MessageHumidityQuery(MessageGroupDataQuery):
    """AC message query indoor humidity(queryType == "group_data_five")."""

    _group = 5


class MessageGroupSevenQuery(MessageGroupDataQuery):
    """AC message compressor power query(queryType == "group_data_seven")."""

    _group = 7


class MessageToggleDisplay(MessageACBase):
    """AC message toggle display."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message toggle display."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )
        self.prompt_tone = False

    @property
    def _body(self) -> bytearray:
        prompt_tone = 0x40 if self.prompt_tone else 0
        return bytearray(
            [
                0x02 | prompt_tone,
                0x00,
                0xFF,
                0x02,
                0x00,
                0x02,
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


class MessageNewProtocolQuery(MessageACBase):
    """AC message new protocol query."""

    # error_code_query is deliberately not queried by default: on some B1
    # devices, including it makes both this query and CapabilitiesQuery get
    # recorded as unsupported protocol, breaking status refresh entirely.
    _query_params: tuple[int, ...] = (
        NewProtocolTags.indirect_wind,
        NewProtocolTags.breezeless,
        NewProtocolTags.indoor_humidity,
        NewProtocolTags.screen_display,
        NewProtocolTags.fresh_air_1,
        NewProtocolTags.fresh_air_2,
        NewProtocolTags.wind_lr_angle,
        NewProtocolTags.wind_ud_angle,
        NewProtocolTags.out_silent,
        NewProtocolTags.buzzer_all,
    )

    def __init__(
        self,
        protocol_version: int,
        *,
        supports_rate_select: bool = False,
    ) -> None:
        """Initialize AC message new protocol query.

        `supports_rate_select` gates the rate_select (0x0048) query param on
        the device having advertised it via the B5 b5_electricity capability
        (tag 0x0216). Devices that don't report it never answer the query, so
        it's left out until support is confirmed.
        """
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.B1,
        )
        self._supports_rate_select = supports_rate_select

    @property
    def _body(self) -> bytearray:

        params = list(self._query_params)
        if self._supports_rate_select:
            params.append(NewProtocolTags.rate_select)

        _body = bytearray([len(params)])
        for param in params:
            _body.extend([param & 0xFF, param >> 8])
        return _body


class MessageNewProtocolSelfCleanQuery(MessageNewProtocolQuery):
    """AC message new protocol self-clean query.

    A device answers with an empty parameter list when a query carries a tag it
    does not support, which suppresses every other tag in the same request. The
    self-clean state is therefore asked for as an independent status group.
    """

    _query_params = (NewProtocolTags.self_clean,)


class MessageSubProtocol(MessageACBase):
    """AC message sub protocol."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        subprotocol_query_type: int,
    ) -> None:
        """Initialize AC message sub protocol."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=ListTypes.AA,
        )
        self._subprotocol_query_type = subprotocol_query_type

    @property
    def _subprotocol_body(self) -> bytes | bytearray:
        return bytes([])

    @property
    def body(self) -> bytearray:
        """AC message sub protocol body."""
        body = bytearray([self.body_type]) + self._body
        body.append(calculate(body))
        body.extend(self.checksum(body, self._checksum_type))
        return body

    @property
    def _body(self) -> bytearray:
        _subprotocol_body = self._subprotocol_body
        _body = bytearray(
            [
                6 + 2 + len(_subprotocol_body),
                0x00,
                0xFF,
                0xFF,
                self._subprotocol_query_type,
            ],
        )
        _body.extend(_subprotocol_body)
        return _body


class MessageSubProtocolQuery(MessageSubProtocol):
    """AC message sub protocol query."""

    def __init__(
        self,
        protocol_version: int,
        subprotocol_query_type: int,
    ) -> None:
        """Initialize AC message sub protocol query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            subprotocol_query_type=subprotocol_query_type,
        )


class MessageSubProtocolQuery10(MessageSubProtocolQuery):
    """AC sub protocol indoor status query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize the indoor status query."""
        super().__init__(protocol_version, ListTypes.X10)


class MessageSubProtocolQuery11(MessageSubProtocolQuery):
    """AC sub protocol basic status query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize the basic status query."""
        super().__init__(protocol_version, ListTypes.X11)


class MessageSubProtocolQuery30(MessageSubProtocolQuery):
    """AC sub protocol outdoor status query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize the outdoor status query."""
        super().__init__(protocol_version, ListTypes.X30)


class MessageSubProtocolSet(MessageSubProtocol):
    """AC message sub protocol set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message sub protocol set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            subprotocol_query_type=0x20,
        )
        self.power = False
        self.mode = 0
        self.target_temperature = 20.0
        self.fan_speed = 102
        self.boost_mode = False
        self.aux_heating = False
        self.dry = False
        self.eco_mode = False
        self.sleep_mode = False
        self.sn8_flag = False
        self.timer = False
        self.prompt_tone = False

    @property
    def _subprotocol_body(self) -> bytearray:
        power = 0x01 if self.power else 0
        dry = 0x10 if self.power and self.dry else 0
        boost_mode = 0x20 if self.boost_mode else 0
        aux_heating = 0x40 if self.aux_heating else 0x80
        sleep_mode = 0x80 if self.sleep_mode else 0
        try:
            mode = 0 if self.mode == 0 else BB_AC_MODES[self.mode] - 1
        except IndexError:
            mode = 2  # set Auto if invalid mode
        target_temperature = int(self.target_temperature * 2 + 30)
        water_model_temperature_set = int((self.target_temperature - 1) * 2 + 50)
        fan_speed = int(self.fan_speed)
        eco = 0x40 if self.eco_mode else 0

        prompt_tone = 0x01 if self.prompt_tone else 0
        timer = 0x04 if (self.sn8_flag and self.timer) else 0
        return bytearray(
            [
                0x02 | boost_mode | power | dry,
                aux_heating,
                sleep_mode,
                0x00,
                0x00,
                mode,
                target_temperature,
                fan_speed,
                0x32,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x01,
                0x01,
                0x00,
                0x01,
                water_model_temperature_set,
                prompt_tone,
                target_temperature,
                0x32,
                0x66,
                0x00,
                eco | timer,
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
                0x08,
            ],
        )


class MessageSubProtocolFreshAirSet(MessageSubProtocol):
    """AC BB C0/02 single-control fresh-air command."""

    def __init__(
        self,
        protocol_version: int,
        power: bool,
        speed: int,
        *,
        exhaust: bool = False,
    ) -> None:
        """Initialize a fresh-air intake or exhaust command."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            subprotocol_query_type=ListTypes.C0,
        )
        self.power = power
        self.speed = max(1, min(speed, 100))
        self.exhaust = exhaust

    @property
    def _subprotocol_body(self) -> bytearray:
        body = bytearray(BB_FRESH_AIR_CONTROL_BODY_LENGTH)
        # BB fresh-air controls are sparse C0/02 payloads. The switch bytes are
        # relative to the control cursor; speed bytes are offsets in that block.
        body[1] = 0x01
        body[2] = 0x01
        body[11] = 0x01
        body[12] = ListTypes.C0
        body[13] = 0x02
        body[14] = 0x54
        switch_mask = (
            BB_FRESH_AIR_EXHAUST_SWITCH_MASK
            if self.exhaust
            else BB_FRESH_AIR_INTAKE_SWITCH_MASK
        )
        speed_index = (
            BB_FRESH_AIR_EXHAUST_CONTROL_SPEED_INDEX
            if self.exhaust
            else BB_FRESH_AIR_INTAKE_CONTROL_SPEED_INDEX
        )
        body[BB_FRESH_AIR_CONTROL_CURSOR + 6] = switch_mask
        body[BB_FRESH_AIR_CONTROL_CURSOR + 7] = switch_mask if self.power else 0
        body[BB_FRESH_AIR_CONTROL_CURSOR + speed_index] = (
            BB_FRESH_AIR_SPEED_FLAG | self.speed
        )
        body[-1] = (-sum(body[12:-1])) & MAX_BYTE_VALUE
        return body


class MessageSubProtocolResetFilter(MessageSubProtocol):
    """AC message reset filter."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message reset filter."""
        super().__init__(
            protocol_version,
            message_type=MessageType.set,
            subprotocol_query_type=ListTypes.AB,
        )

    @property
    def _subprotocol_body(self) -> bytearray:
        return bytearray([0x40 | 0x80, 0x01])


class MessageGeneralSet(MessageACBase):
    """AC message general set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message general set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X40,
        )
        self.power = False
        self.prompt_tone = True
        self.mode = 0
        self.target_temperature = 20.0
        self.fan_speed = 102
        self.swing_vertical = False
        self.swing_horizontal = False
        self.boost_mode = False
        self.power_saving = False
        self.smart_eye = False
        self.dry = False
        self.aux_heating = False
        self.eco_mode = False
        self.temp_fahrenheit = False
        self.sleep_mode = False
        self.natural_wind = False
        self.frost_protect = False
        self.comfort_mode = False
        self.anion = False
        self.reset_filter = False

    @property
    def _body(self) -> bytearray:
        # Byte1, Power, prompt_tone
        power = 0x01 if self.power else 0
        prompt_tone = 0x40 if self.prompt_tone else 0
        # Byte2, mode target_temperature
        mode = (self.mode << 5) & 0xE0
        target_temperature = (int(self.target_temperature) & 0xF) | (
            0x10 if round(self.target_temperature * 2) % 2 != 0 else 0
        )
        # Byte 3, fan_speed
        fan_speed = int(self.fan_speed) & 0x7F
        # Byte 7, swing_mode
        swing_mode = (
            0x30
            | (0x0C if self.swing_vertical else 0)
            | (0x03 if self.swing_horizontal else 0)
        )
        # Byte 8, turbo, power saving
        boost_mode = 0x20 if self.boost_mode else 0
        power_saving = POWER_SAVING_VALUE if self.power_saving else 0
        # Byte 9 aux_heating eco_mode
        smart_eye = 0x01 if self.smart_eye else 0
        dry = 0x04 if self.dry else 0
        aux_heating = 0x08 if self.aux_heating else 0
        eco_mode = 0x80 if self.eco_mode else 0
        anion = 0x20 if self.anion else 0
        # Byte 10 temp_fahrenheit
        temp_fahrenheit = 0x04 if self.temp_fahrenheit else 0
        sleep_mode = 0x01 if self.sleep_mode else 0
        boost_mode_1 = 0x02 if self.boost_mode else 0
        common_filter_reset = 0x80 if self.reset_filter else 0
        # Byte 17 natural_wind
        natural_wind = 0x40 if self.natural_wind else 0
        # Byte 21 frost_protect
        frost_protect = 0x80 if self.frost_protect else 0
        # Byte 22 comfort_mode
        comfort_mode = 0x01 if self.comfort_mode else 0
        fresh_filter_reset = 0x08 if self.reset_filter else 0

        return bytearray(
            [
                power | prompt_tone,
                mode | target_temperature,
                fan_speed,
                0x00,
                0x00,
                0x00,
                swing_mode,
                boost_mode | power_saving,
                smart_eye | dry | aux_heating | eco_mode | anion,
                temp_fahrenheit | sleep_mode | boost_mode_1 | common_filter_reset,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                natural_wind,
                0x00,
                0x00,
                0x00,
                frost_protect,
                comfort_mode | fresh_filter_reset,
            ],
        )


class MessageNewProtocolSet(MessageACBase):
    """AC message new protocol set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message new protocol set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.B0,
        )
        self.indirect_wind: bytes | None = None
        self.prompt_tone: bytes | None = None
        self.breezeless: bytes | None = None
        self.screen_display_alternate: bytes | None = None
        self.fresh_air_1: bytes | None = None
        self.fresh_air_2: bytes | None = None
        self.wind_lr_angle: bytes | None = None
        self.wind_ud_angle: bytes | None = None
        self.rate_select: int | None = None
        self.out_silent: bool | None = None
        self.sound: bool | None = None
        self.self_clean: bool | None = None
        self.reset_filter: bool = False

    @property
    def _body(self) -> bytearray:
        pack_count = 0
        payload = bytearray([0x00])
        if self.breezeless is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.breezeless,
                    value=bytearray([0x01 if self.breezeless else 0x00]),
                ),
            )
        if self.indirect_wind is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.indirect_wind,
                    value=bytearray([0x02 if self.indirect_wind else 0x01]),
                ),
            )
        if self.prompt_tone is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.prompt_tone,
                    value=bytearray([0x01 if self.prompt_tone else 0x00]),
                ),
            )
        if self.screen_display_alternate is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.screen_display,
                    value=bytearray([0x64 if self.screen_display_alternate else 0x00]),
                ),
            )
        if self.fresh_air_1 is not None and len(self.fresh_air_1) == FRESH_AIR_LENGTH:
            pack_count += 1
            fresh_air_power = 2 if next(iter(self.fresh_air_1)) > 0 else 1
            fresh_air_fan_speed = list(self.fresh_air_1)[1]
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.fresh_air_1,
                    value=bytearray(
                        [
                            fresh_air_power,
                            fresh_air_fan_speed,
                            0x00,
                            0x00,
                            0x00,
                            0x00,
                            0x00,
                            0x00,
                            0x00,
                            0x00,
                        ],
                    ),
                ),
            )
        if self.fresh_air_2 is not None and len(self.fresh_air_2) == FRESH_AIR_LENGTH:
            pack_count += 1
            fresh_air_power = 1 if next(iter(self.fresh_air_2)) > 0 else 0
            fresh_air_fan_speed = list(self.fresh_air_2)[1]
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.fresh_air_2,
                    value=bytearray([fresh_air_power, fresh_air_fan_speed, 0xFF]),
                ),
            )
        if self.wind_lr_angle is not None:
            pack_count += 1
            wind_lr_angle = int(self.wind_lr_angle)
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.wind_lr_angle,
                    value=bytearray([wind_lr_angle if wind_lr_angle else 0x00]),
                ),
            )
        if self.wind_ud_angle is not None:
            pack_count += 1
            wind_ud_angle = int(self.wind_ud_angle)
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.wind_ud_angle,
                    value=bytearray([wind_ud_angle if wind_ud_angle else 0x00]),
                ),
            )
        if self.out_silent is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.out_silent,
                    # Device requires 0x03 to activate, 0x00 to deactivate
                    # Sending 0x01 results in an error from the firmware
                    value=bytearray([OUT_SILENT_VALUE if self.out_silent else 0x00]),
                ),
            )
        if self.sound is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.buzzer_all,
                    value=bytearray([0x01 if self.sound else 0x00]),
                ),
            )
        if self.self_clean is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.self_clean,
                    value=bytearray([0x01 if self.self_clean else 0x00]),
                ),
            )
        if self.rate_select is not None:
            pack_count += 1
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.rate_select,
                    value=bytearray([int(self.rate_select)]),
                ),
            )
        if self.reset_filter:
            pack_count += 4
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.dust_full_time_reset,
                    value=bytearray([0x1]),
                ),
            )
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.filter_status,
                    value=bytearray([0x0] * 5),
                ),
            )
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.fresh_filter_reset,
                    value=bytearray([0x1]),
                ),
            )
            payload.extend(
                NewProtocolMessageBody.pack(
                    param=NewProtocolTags.wet_film_reset,
                    value=bytearray([0x1]),
                ),
            )
        payload[0] = pack_count
        return payload


class XA0MessageBody(MessageBody):
    """AC A0 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC A0 message body."""
        super().__init__(
            body,
            parser_list=[
                BoolParser(DeviceAttributes.power, 1, bit=0),
                FloatParser(
                    DeviceAttributes.target_temperature,
                    1,
                    first_upper=False,
                    transform_func=lambda value: (
                        ((int(value) & 0x3E) >> 1)
                        - 4
                        + 16.0
                        + (0.5 if int(value) & 0x40 > 0 else 0.0)
                    ),
                ),
                IntParser(
                    DeviceAttributes.mode,
                    2,
                    byte_mask=0xE0,
                    transform_func=lambda value: value >> 5,
                ),
                IntParser(DeviceAttributes.fan_speed, 3, byte_mask=0x7F),
                BoolParser(DeviceAttributes.swing_vertical, 7, byte_mask=0x0C),
                BoolParser(DeviceAttributes.swing_horizontal, 7, byte_mask=0x03),
                BoolParser(DeviceAttributes.power_saving, 8, bit=3),
                IntParser("comfort_sleep", 8, byte_mask=0x03),
                IntParser("comfort_sleep_switch", 14, byte_mask=0x01),
                FloatParser(
                    DeviceAttributes.pmv,
                    11,
                    first_upper=False,
                    byte_mask=0xF0,
                    transform_func=lambda value: (int(value) >> 4) * 0.5 - 3.5,
                ),
                BoolParser(DeviceAttributes.smart_eye, 9, bit=0),
                BoolParser(DeviceAttributes.dry, 9, bit=2),
                BoolParser(DeviceAttributes.aux_heating, 9, bit=3),
                IntParser("purifier", 9, byte_mask=0x20),
                BoolParser(DeviceAttributes.anion, 9, bit=5),
                BoolParser(DeviceAttributes.eco_mode, 9, bit=4),
                BoolParser(DeviceAttributes.sleep_mode, 10, bit=0),
                BoolParser(DeviceAttributes.natural_wind, 10, bit=6),
                BoolParser("smart_dry", 13, byte_mask=0x7F),
                IntParser(
                    "kick_quilt",
                    10,
                    byte_mask=0x04,
                    transform_func=lambda value: value >> 2,
                ),
                IntParser(
                    "prevent_cold",
                    10,
                    byte_mask=0x08,
                    transform_func=lambda value: value >> 3,
                ),
                BoolParser(DeviceAttributes.full_dust, 13, bit=5),
                BoolParser(DeviceAttributes.frost_protect, 21, bit=7),
                IntParser("swing_lr_value", 9, byte_mask=0x40),
                BoolParser(DeviceAttributes.comfort_mode, 14, bit=0),
                IntParser("swing_lr_switch", 19, byte_mask=0x80),
                IntParser(
                    "fresh_filter_time_total",
                    24,
                    length_in_bytes=2,
                ),
                IntParser(
                    "fresh_filter_time_use",
                    15,
                    length_in_bytes=2,
                ),
                IntParser(
                    "fresh_filter_timeout",
                    13,
                    byte_mask=0x40,
                    transform_func=lambda value: value >> 6,
                ),
                BoolParser(
                    DeviceAttributes.screen_display,
                    14,
                    byte_mask=0x70,
                ),
                IntParser(
                    DeviceAttributes.boost_mode,
                    8,
                    length_in_bytes=3,
                    byte_mask=0x200002,
                    transform_func=bool,
                ),
            ],
        )


class XMessageBody(MessageBody):
    """AC A1/C0 message body - common functions."""

    @staticmethod
    def parse_temperature(integer: int, decimal: int) -> float | None:
        """Decode special signed integer with BCD decimal temperature format."""
        if integer == MAX_BYTE_VALUE:
            return None
        temp_integer = (integer - 50) / 2
        if decimal == 0:
            return temp_integer
        if temp_integer < 0:
            return int(temp_integer) - decimal * 0.1
        return int(temp_integer) + decimal * 0.1


class XA1MessageBody(XMessageBody):
    """AC A1 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC A1 message body."""
        self.indoor_temperature_int = 0
        self.indoor_temperature_decimal = 0
        self.outdoor_temperature_int = 0
        self.outdoor_temperature_decimal = 0
        super().__init__(
            body,
            [
                IntParser(
                    "current_work_time",
                    9,
                    length_in_bytes=4,
                    transform_func=lambda x: (
                        (((x >> 16) & 0xFFFF) * 60 * 24)
                        + (((x >> 8) & 0xFF) * 60)
                        + (x & 0xFF)
                    ),
                ),
                IntParser("indoor_temperature_decimal", 18, byte_mask=0x0F),
                IntParser("indoor_temperature_int", 13),
                IntParser(
                    "outdoor_temperature_decimal",
                    18,
                    byte_mask=0xF0,
                    transform_func=lambda x: x >> 4,
                ),
                IntParser("outdoor_temperature_int", 14),
                IntParser("indoor_humidity", 17),
            ],
        )

        self.indoor_temperature = self.parse_temperature(
            self.indoor_temperature_int,
            self.indoor_temperature_decimal,
        )
        self.outdoor_temperature = self.parse_temperature(
            self.outdoor_temperature_int,
            self.outdoor_temperature_decimal,
        )


class XBXMessageBody(NewProtocolMessageBody):
    """AC BX message body. body[0] b0/b1, body[1] propertyNumber, cursor 2."""

    def __init__(
        self,
        body: bytearray,
        bt: int,
        new_protocol_temperature: bool = False,
    ) -> None:
        """Initialize AC BX message body."""
        super().__init__(body, bt)

        params = self.parse()
        if NewProtocolTags.indirect_wind in params:
            self.indirect_wind = (
                params[NewProtocolTags.indirect_wind][0] == INDIRECT_WIND_VALUE
            )
        if NewProtocolTags.indoor_humidity in params:
            self.indoor_humidity = parse_indoor_humidity(
                params[NewProtocolTags.indoor_humidity][0],
            )
        if NewProtocolTags.breezeless in params:
            self.breezeless = params[NewProtocolTags.breezeless][0] == 1
        if NewProtocolTags.screen_display in params:
            self.screen_display_alternate = (
                params[NewProtocolTags.screen_display][0] > 0
            )
            self.screen_display_new = True
        if NewProtocolTags.fresh_air_1 in params:
            self.fresh_air_1 = True
            data = params[NewProtocolTags.fresh_air_1]
            self.fresh_air_power = data[0] == INDIRECT_WIND_VALUE
            self.fresh_air_fan_speed = data[1]
        if NewProtocolTags.fresh_air_2 in params:
            self.fresh_air_2 = True
            data = params[NewProtocolTags.fresh_air_2]
            self.fresh_air_power = data[0] > 0
            self.fresh_air_fan_speed = data[1]
        if NewProtocolTags.wind_lr_angle in params:
            self.wind_lr_angle = params[NewProtocolTags.wind_lr_angle][0]
        if NewProtocolTags.wind_ud_angle in params:
            self.wind_ud_angle = params[NewProtocolTags.wind_ud_angle][0]
        if NewProtocolTags.rate_select in params:
            self.rate_select = params[NewProtocolTags.rate_select][0]
        if NewProtocolTags.out_silent in params:
            self.out_silent = params[NewProtocolTags.out_silent][0] == OUT_SILENT_VALUE
        if NewProtocolTags.buzzer_all in params:
            self.sound = params[NewProtocolTags.buzzer_all][0] > 0
        if NewProtocolTags.error_code_query in params:
            self.error_code = params[NewProtocolTags.error_code_query][0]
        if (
            NewProtocolTags.filter_status in params
            and len(params[NewProtocolTags.filter_status]) == BX_FILTER_STATUS_LENGTH
        ):
            self.full_dust = (
                params[NewProtocolTags.filter_status][BX_FILTER_STATUS_LENGTH - 1] > 0
            )
        if NewProtocolTags.self_clean in params and bt != ListTypes.B5:
            # A B5 body carries this tag as a capability flag (always 1 when the
            # model supports self-clean), so only B0/B1 bodies report live state.
            self.self_clean_active: bool = params[NewProtocolTags.self_clean][0] > 0
        if (
            new_protocol_temperature
            and NEW_PROTOCOL_TEMPERATURE_TAG in params
            and self._parse_new_protocol_temperatures(
                params[NEW_PROTOCOL_TEMPERATURE_TAG],
            )
        ):
            self.has_new_protocol_temperature = True

    def _parse_new_protocol_temperatures(self, data: bytearray) -> bool:
        """Decode setpoint and indoor temperature for model 22013279.

        Its standard C0 temperature fields are stale; temperatures are reported
        in this new-protocol tag instead. Synced captures show the setpoint in
        byte 1:
        - low 6 bits encode 0.5C steps with a +11.5C offset
        - bit 0x40 adds an extra +0.5C

        Only call this for model 22013279. For other models, this tag is not
        known to supersede C0; accepting it would latch B1 values and discard
        C0 temperatures, including any outdoor reading.
        """
        if len(data) <= NEW_PROTOCOL_TEMPERATURE_MIN_LENGTH:
            return False
        raw_setpoint = data[1]
        target_temperature = (
            NEW_PROTOCOL_SETPOINT_OFFSET
            + (raw_setpoint & NEW_PROTOCOL_SETPOINT_MASK) / 2
        )
        if raw_setpoint & NEW_PROTOCOL_SETPOINT_HALF_DEGREE_BIT:
            target_temperature += 0.5
        if not (
            NEW_PROTOCOL_MIN_VALID_TEMPERATURE
            <= target_temperature
            <= NEW_PROTOCOL_MAX_VALID_TEMPERATURE
        ):
            # Fallback for payload variants where the legacy byte-3 mapping
            # is still active.
            fallback_target = (data[NEW_PROTOCOL_LEGACY_SETPOINT_BYTE] - 50) / 2
            if (
                NEW_PROTOCOL_MIN_VALID_TEMPERATURE
                <= fallback_target
                <= NEW_PROTOCOL_MAX_VALID_TEMPERATURE
            ):
                target_temperature = fallback_target
            else:
                return False
        indoor_temperature = round(
            (data[NEW_PROTOCOL_INDOOR_TEMPERATURE_BYTE] - 50) / 2
            + data[NEW_PROTOCOL_INDOOR_TEMPERATURE_DECIMAL_BYTE] * 0.1,
            1,
        )
        if not (
            NEW_PROTOCOL_MIN_VALID_TEMPERATURE
            <= indoor_temperature
            <= NEW_PROTOCOL_MAX_VALID_TEMPERATURE
        ):
            return False
        self.target_temperature = target_temperature
        self.indoor_temperature = indoor_temperature
        # Outdoor temperature isn't available locally on this model (the app
        # shows a cloud/weather value); avoid the bogus C0-derived value.
        self.outdoor_temperature = None
        return True


class XB5MessageBody(NewProtocolMessageBody):
    """AC B5 message body. body[0] b5, body[1] propertyNumber, cursor 2."""

    def __init__(self, body: bytearray, bt: int) -> None:
        """Initialize AC BX message body."""
        super().__init__(body, bt)

        params = self.parse()
        # parse b5 protocol, github issue https://github.com/wuwentao/midea_ac_lan/issues/673
        if NewProtocolTags.b5_mode in params:
            self.b5_mode = params[NewProtocolTags.b5_mode][0]
        if NewProtocolTags.b5_anion in params:
            self.b5_anion = params[NewProtocolTags.b5_anion][0]
        if NewProtocolTags.b5_filter_remind in params:
            self.b5_filter_remind = params[NewProtocolTags.b5_filter_remind][0]
        if NewProtocolTags.b5_strong_wind in params:
            self.b5_strong_wind = params[NewProtocolTags.b5_strong_wind][0]
        if NewProtocolTags.b5_wind_speed in params:
            self.b5_wind_speed = params[NewProtocolTags.b5_wind_speed][0]
        if NewProtocolTags.b5_temperature in params:
            self.b5_temperature0 = params[NewProtocolTags.b5_temperature][0]
            self.b5_temperature1 = params[NewProtocolTags.b5_temperature][1]
            self.b5_temperature2 = params[NewProtocolTags.b5_temperature][2]
            self.b5_temperature3 = params[NewProtocolTags.b5_temperature][3]
            self.b5_temperature4 = params[NewProtocolTags.b5_temperature][4]
            self.b5_temperature5 = params[NewProtocolTags.b5_temperature][5]
            self.b5_temperature6 = params[NewProtocolTags.b5_temperature][6]
            # per-mode setpoint limits in 0.5 C units. the six raw bytes are
            # cool then auto then heat, each a min then a max, plus a flag byte.
            # keyed by mode value: auto is 1, cool 2, dry 3, heat 4, fan 5
            # (dry and fan reuse the cool range).
            cool = (self.b5_temperature0 / 2, self.b5_temperature1 / 2)
            auto = (self.b5_temperature2 / 2, self.b5_temperature3 / 2)
            heat = (self.b5_temperature4 / 2, self.b5_temperature5 / 2)
            self.temperature_limits = {1: auto, 2: cool, 3: cool, 4: heat, 5: cool}
        if NewProtocolTags.b5_screen_display in params:
            self.b5_screen_display = params[NewProtocolTags.b5_screen_display][0]
        if NewProtocolTags.b5_sound in params:
            self.b5_sound = params[NewProtocolTags.b5_sound][0]
        if NewProtocolTags.b5_humidity in params:
            self.b5_humidity = params[NewProtocolTags.b5_humidity][0]
        self._parse_capabilities(params)

    def _parse_capabilities(self, params: dict[int, bytearray]) -> None:
        """Decode B5 capability values into feature flags.

        The raw byte of each capability is not a simple 0/1 flag; each one has
        its own value semantics (reverse-engineered, matching the msmart
        project). Only capabilities actually reported are added.
        """
        caps: dict[str, bool] = {}
        caps["fan_low"] = True
        caps["fan_medium"] = True
        caps["fan_high"] = True
        caps["fan_auto"] = True
        if NewProtocolTags.b5_mode in params:
            value = params[NewProtocolTags.b5_mode][0]
            caps["heat_mode"] = value in B5_HEAT_MODE_VALUES
            caps["cool_mode"] = value not in B5_NO_COOL_MODE_VALUES
            caps["dry_mode"] = value in B5_DRY_MODE_VALUES
            caps["auto_mode"] = value in B5_AUTO_MODE_VALUES
        if NewProtocolTags.b5_wind_swing in params:
            value = params[NewProtocolTags.b5_wind_swing][0]
            caps["swing_horizontal"] = value in B5_SWING_HORIZONTAL_VALUES
            caps["swing_vertical"] = value < B5_LOW_VALUE_MAX
        if NewProtocolTags.wind_lr_angle in params:
            value = params[NewProtocolTags.wind_lr_angle][0]
            caps["swing_horizontal_angle"] = value == 1
        if NewProtocolTags.wind_ud_angle in params:
            value = params[NewProtocolTags.wind_ud_angle][0]
            caps["swing_vertical_angle"] = value == 1
        if NewProtocolTags.b5_wind_speed in params:
            value = params[NewProtocolTags.b5_wind_speed][0]
            fan_custom = value == B5_FAN_CUSTOM_VALUE
            caps["fan_silent"] = fan_custom or value in B5_FAN_SILENT_VALUES
            caps["fan_low"] = fan_custom or value in B5_FAN_LOW_HIGH_VALUES
            caps["fan_medium"] = fan_custom or value in B5_FAN_MEDIUM_VALUES
            caps["fan_high"] = fan_custom or value in B5_FAN_LOW_HIGH_VALUES
            caps["fan_auto"] = fan_custom or value in B5_FAN_AUTO_VALUES
            caps["fan_custom"] = fan_custom
        if NewProtocolTags.b5_eco in params:
            caps["eco"] = params[NewProtocolTags.b5_eco][0] in B5_ECO_VALUES
        if NewProtocolTags.b5_anion in params:
            caps["anion"] = params[NewProtocolTags.b5_anion][0] == B5_ANION_ON_VALUE
        if NewProtocolTags.b5_strong_wind in params:
            value = params[NewProtocolTags.b5_strong_wind][0]
            caps["turbo_cool"] = value < B5_LOW_VALUE_MAX
            caps["turbo_heat"] = value in B5_TURBO_HEAT_VALUES
        if NewProtocolTags.b5_screen_display in params:
            value = params[NewProtocolTags.b5_screen_display][0]
            caps["display_control"] = value in B5_DISPLAY_VALUES
        if NewProtocolTags.b5_electricity in params:
            value = params[NewProtocolTags.b5_electricity][0]
            caps["energy_stats"] = value in B5_ENERGY_STATS_VALUES
            caps["energy_setting"] = value in B5_ENERGY_SETTING_VALUES
            caps["energy_bcd"] = value in B5_ENERGY_BCD_VALUES
        if NewProtocolTags.rate_select in params:
            value = params[NewProtocolTags.rate_select][0]
            caps["rate_select"] = value > 0
            caps["rate_select_2_level"] = value & RATE_SELECT_2_LEVEL_BIT > 0
            caps["rate_select_5_level"] = value & RATE_SELECT_5_LEVEL_BIT > 0
        if NewProtocolTags.b5_sound in params:
            value = params[NewProtocolTags.buzzer_all][0]
            caps["sound"] = value == 1
        if NewProtocolTags.b5_humidity in params:
            value = params[NewProtocolTags.b5_humidity][0]
            caps["humidity"] = value & B5_HUMIDITY_SUPPORTED_MASK > 0
        self.capabilities = caps


class XC0MessageBody(XMessageBody):
    """AC C0 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC C0 message body."""
        self.indoor_temperature_int = 0
        self.indoor_temperature_decimal = 0
        self.outdoor_temperature_int = 0
        self.outdoor_temperature_decimal = 0
        super().__init__(
            body,
            [
                BoolParser(DeviceAttributes.power, 1, 0),
                IntParser(
                    DeviceAttributes.mode,
                    byte=2,
                    byte_mask=0xE0,
                    transform_func=lambda value: value >> 5,
                ),
                FloatParser(
                    DeviceAttributes.target_temperature,
                    byte=2,
                    byte_mask=0x1F,
                    transform_func=lambda x: (
                        (int(x) & 0x0F) + 16.0 + (0.5 if int(x) & 0x10 > 0 else 0.0)
                    ),
                ),
                IntParser(
                    DeviceAttributes.fan_speed,
                    byte=3,
                    byte_mask=0x7F,
                ),
                BoolParser(
                    DeviceAttributes.swing_vertical,
                    byte=7,
                    byte_mask=0x0C,
                ),
                BoolParser(
                    DeviceAttributes.swing_horizontal,
                    byte=7,
                    byte_mask=0x03,
                ),
                IntParser(
                    DeviceAttributes.boost_mode,
                    byte=8,
                    length_in_bytes=3,
                    byte_mask=0x200002,
                    transform_func=bool,
                ),
                BoolParser(
                    DeviceAttributes.power_saving,
                    byte=8,
                    bit=3,
                ),
                IntParser("comfort_sleep", byte=8, byte_mask=0x03),
                BoolParser("comfort_sleep_switch", byte=9, bit=2),
                FloatParser(
                    DeviceAttributes.pmv,
                    byte=14,
                    byte_mask=0x0F,
                    transform_func=lambda x: x * 0.5 - 3.5,
                ),
                BoolParser(
                    DeviceAttributes.smart_eye,
                    byte=8,
                    byte_mask=0x40,
                    true_value=0x40,
                ),
                BoolParser(
                    DeviceAttributes.natural_wind,
                    byte=9,
                    byte_mask=0x02,
                    true_value=0x02,
                ),
                BoolParser(
                    DeviceAttributes.dry,
                    byte=9,
                    byte_mask=0x04,
                    true_value=0x04,
                ),
                BoolParser(
                    DeviceAttributes.eco_mode,
                    byte=9,
                    byte_mask=0x10,
                    true_value=0x10,
                ),
                BoolParser(
                    DeviceAttributes.aux_heating,
                    byte=9,
                    byte_mask=0x08,
                    true_value=0x08,
                ),
                BoolParser(
                    DeviceAttributes.anion,
                    byte=9,
                    byte_mask=0x20,
                    true_value=0x20,
                ),
                BoolParser(
                    DeviceAttributes.temp_fahrenheit,
                    byte=10,
                    byte_mask=0x04,
                    true_value=0x04,
                ),
                BoolParser(DeviceAttributes.sleep_mode, byte=10, byte_mask=0x01),
                IntParser("indoor_temperature_decimal", 15, byte_mask=0x0F),
                IntParser("indoor_temperature_int", 11),
                IntParser(
                    "outdoor_temperature_decimal",
                    15,
                    byte_mask=0xF0,
                    transform_func=lambda x: x >> 4,
                ),
                IntParser("outdoor_temperature_int", 12),
                BoolParser("kick_quilt", byte=10, byte_mask=0x04, true_value=0x04),
                BoolParser("prevent_cold", byte=10, byte_mask=0x20, true_value=0x20),
                BoolParser(
                    DeviceAttributes.full_dust,
                    byte=13,
                    byte_mask=0x20,
                    true_value=0x20,
                ),
                BoolParser(
                    DeviceAttributes.screen_display,
                    byte=14,
                    byte_mask=0x70,
                    false_value=0x70,
                ),
                BoolParser(
                    DeviceAttributes.frost_protect,
                    byte=21,
                    byte_mask=0x80,
                    true_value=0x80,
                ),
                BoolParser(DeviceAttributes.comfort_mode, byte=22, byte_mask=0x01),
                BoolParser("smart_dry", byte=19, byte_mask=0x7F),
                BoolParser("swing_lr_switch", byte=19, byte_mask=0x80, true_value=0x80),
                BoolParser("swing_lr_value", byte=20, byte_mask=0x80, true_value=0x80),
                IntParser("fresh_filter_time_total", byte=24, length_in_bytes=2),
                IntParser("fresh_filter_time_use", byte=26, length_in_bytes=2),
                BoolParser(
                    "fresh_filter_timeout",
                    byte=13,
                    byte_mask=0x40,
                    true_value=0x40,
                ),
            ],
        )
        self.indoor_temperature = self.parse_temperature(
            self.indoor_temperature_int,
            self.indoor_temperature_decimal,
        )
        self.outdoor_temperature = self.parse_temperature(
            self.outdoor_temperature_int,
            self.outdoor_temperature_decimal,
        )


class XC140MessageBody(MessageBody):
    """AC C1 Subprotocol 40 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC C1 Subprotocol 40 message body."""
        self.electrify_time_day = 0
        self.electrify_time_hour = 0
        self.electrify_time_min = 0
        self.electrify_time_second = 0
        self.total_operating_time_day = 0
        self.total_operating_time_hour = 0
        self.total_operating_time_min = 0
        self.total_operating_time_second = 0
        self.current_operating_time_day = 0
        self.current_operating_time_hour = 0
        self.current_operating_time_min = 0
        self.current_operating_time_second = 0
        super().__init__(
            body,
            [
                IntParser(
                    "electrify_time_day",
                    byte=0,
                    length_in_bytes=2,
                    first_upper=True,
                ),
                IntParser("electrify_time_hour", byte=2),
                IntParser("electrify_time_min", byte=3),
                IntParser("electrify_time_second", byte=4),
                IntParser(
                    "total_operating_time_day",
                    byte=5,
                    length_in_bytes=2,
                    first_upper=True,
                ),
                IntParser("total_operating_time_hour", byte=7),
                IntParser("total_operating_time_min", byte=8),
                IntParser("total_operating_time_second", byte=9),
                IntParser(
                    "current_operating_time_day",
                    byte=10,
                    length_in_bytes=2,
                    first_upper=True,
                ),
                IntParser("current_operating_time_hour", byte=12),
                IntParser("current_operating_time_min", byte=13),
                IntParser("current_operating_time_second", byte=14),
            ],
        )

        # summary
        self.electrify_time = (
            (self.electrify_time_day * 24)
            + self.electrify_time_hour
            + (self.electrify_time_min / 60)
            + (self.electrify_time_second / 3600)
        )

        self.total_operating_time = (
            (self.total_operating_time_day * 24)
            + self.total_operating_time_hour
            + (self.total_operating_time_min / 60)
            + (self.total_operating_time_second / 3600)
        )

        self.current_operating_time = (
            (self.current_operating_time_day * 24)
            + self.current_operating_time_hour
            + (self.current_operating_time_min / 60)
            + (self.current_operating_time_second / 3600)
        )


class XC141MessageBody(MessageBody):
    """AC C1 Subprotocol 41 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC C1 Subprotocol 41 message body."""
        super().__init__(
            body,
            [
                IntParser(DeviceAttributes.compressor_frequency, byte=0),
                IntParser(DeviceAttributes.target_compressor_frequency, byte=1),
                IntParser(DeviceAttributes.compressor_current, byte=3),
                IntParser(DeviceAttributes.compressor_voltage, byte=4),
                FloatParser(
                    DeviceAttributes.indoor_ambient_temperature,
                    byte=6,
                    transform_func=lambda x: (x - TEMP_INDOOR_OFFSET) / TEMP_DIVISOR,
                ),
                FloatParser(
                    DeviceAttributes.indoor_coil_temperature,
                    byte=7,
                    transform_func=lambda x: (x - TEMP_INDOOR_OFFSET) / TEMP_DIVISOR,
                ),
                FloatParser(
                    DeviceAttributes.outdoor_coil_temperature,
                    byte=8,
                    transform_func=lambda x: (
                        (x - XC1_TEMP_OUTDOOR_OFFSET) / TEMP_DIVISOR
                    ),
                ),
                FloatParser(
                    DeviceAttributes.outdoor_ambient_temperature,
                    byte=9,
                    transform_func=lambda x: (
                        (x - XC1_TEMP_OUTDOOR_OFFSET) / TEMP_DIVISOR
                    ),
                ),
                IntParser(DeviceAttributes.discharge_pipe_temperature, byte=10),
            ],
        )


class XC142MessageBody(MessageBody):
    """AC C1 Subprotocol 42 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC C1 Subprotocol 42 message body."""
        super().__init__(
            body,
            [
                IntParser(
                    DeviceAttributes.target_indoor_fan_speed,
                    byte=0,
                    transform_func=lambda x: x * XC1_FAN_SPEED_FACTOR,
                ),
                IntParser(
                    DeviceAttributes.indoor_fan_speed,
                    byte=1,
                    transform_func=lambda x: x * XC1_FAN_SPEED_FACTOR,
                ),
                BoolParser(
                    DeviceAttributes.water_pump_running,
                    byte=4,
                    byte_mask=0x10,
                    true_value=0x10,
                ),
            ],
        )


class XC143MessageBody(MessageBody):
    """AC C1 Subprotocol 43 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC C1 Subprotocol 43 message body."""
        super().__init__(
            body,
            [
                IntParser(
                    DeviceAttributes.outdoor_fan_speed,
                    byte=6,
                    transform_func=lambda x: x * XC1_FAN_SPEED_FACTOR,
                ),
            ],
        )


class XC144MessageBody(MessageBody):
    """AC C1 Subprotocol 44 message body."""

    def __init__(self, body: bytearray, analysis_method: int = 3) -> None:
        """Initialize AC C1 Subprotocol 44 message body."""

        def parse_consumption(data: bytearray) -> float:
            return self.parse_consumption(analysis_method, data)

        def parse_power(data: bytearray) -> float:
            return self.parse_power(analysis_method, data)

        super().__init__(
            body,
            [
                FunctionParser[float](
                    DeviceAttributes.total_energy_consumption,
                    byte=0,
                    parse_function=parse_consumption,
                    default_value=0.0,
                    length_in_bytes=4,
                ),
                FunctionParser[float](
                    DeviceAttributes.total_operating_consumption,
                    byte=4,
                    parse_function=parse_consumption,
                    default_value=0.0,
                    length_in_bytes=4,
                ),
                FunctionParser[float](
                    DeviceAttributes.current_energy_consumption,
                    byte=8,
                    parse_function=parse_consumption,
                    default_value=0.0,
                    length_in_bytes=4,
                ),
                FunctionParser[float](
                    DeviceAttributes.realtime_power,
                    byte=12,
                    parse_function=parse_power,
                    default_value=0.0,
                    length_in_bytes=3,
                ),
            ],
        )

    power_analysis_methods: Mapping[int, Callable[[int, int], int]] = MappingProxyType(
        {
            PowerFormats.BCD: lambda byte, value: (
                (byte >> 4) * 10 + (byte & 0x0F) + value * 100
            ),
            PowerFormats.BINARY: lambda byte, value: byte + (value << 8),
            PowerFormats.MIXED: lambda byte, value: byte + value * 100,
        },
    )

    @classmethod
    def parse_value(cls, analysis_method: int, databytes: bytearray) -> float:
        """AC C1 message body parse value."""
        if analysis_method not in PowerFormats._value2member_map_:
            return 0.0  # unknown method
        analysis_function = cls.power_analysis_methods[analysis_method % 10]
        value = 0
        for byte in databytes:
            value = analysis_function(byte, value)
        return float(value)

    @classmethod
    def parse_power(cls, analysis_method: int, databytes: bytearray) -> float:
        """AC C1 message body parse power."""
        if analysis_method == PowerFormats.BCD_ENERGY_BINARY_POWER:
            return cls.parse_value(PowerFormats.BINARY, databytes) / 10
        return cls.parse_value(analysis_method, databytes) / 10

    @classmethod
    def parse_consumption(cls, analysis_method: int, databytes: bytearray) -> float:
        """AC C1 message body parse consumption."""
        if analysis_method == PowerFormats.BCD_ENERGY_BINARY_POWER:
            return cls.parse_value(PowerFormats.BCD, databytes) / 100
        # LSB = 0.01 kWh, except for default binary format = 0.1 kWh
        divisor = 10 if analysis_method == PowerFormats.BINARY else 100
        return cls.parse_value(analysis_method, databytes) / divisor


class XC145MessageBody(MessageBody):
    """AC C1 Subprotocol 45 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC C1 Subprotocol 45 message body."""
        self.indoor_humidity: int | None = 0
        super().__init__(
            body,
            [
                IntParser(
                    DeviceAttributes.indoor_humidity,
                    byte=0,
                ),
            ],
        )
        self.indoor_humidity = parse_indoor_humidity(self.indoor_humidity)


class XC147MessageBody(MessageBody):
    """AC C1 Subprotocol 47 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC C1 Subprotocol 47 message body."""
        super().__init__(
            body,
            [
                IntParser(
                    DeviceAttributes.compressor_power,
                    byte=6,
                    length_in_bytes=2,
                ),
            ],
        )


class XC1MessageBody(MessageBody):
    """AC C1 message body."""

    def __init__(self, body: bytearray, analysis_method: int = 3) -> None:
        """Initialize AC C1 message body."""
        self.subprotocol_type = 0
        super().__init__(body, [IntParser("subprotocol_type", byte=3)])
        subprotocol_body: MessageBody | None = None

        if self.subprotocol_type == ListTypes.X44:
            subprotocol_body = XC144MessageBody(
                body[4:],
                analysis_method=analysis_method,
            )
        elif self.subprotocol_type == ListTypes.X41:
            subprotocol_body = XC141MessageBody(body[4:])
        elif self.subprotocol_type == ListTypes.X42:
            subprotocol_body = XC142MessageBody(body[4:])
        elif self.subprotocol_type in (ListTypes.X03, ListTypes.X43):
            subprotocol_body = XC143MessageBody(body[4:])
        elif self.subprotocol_type == ListTypes.X47:
            subprotocol_body = XC147MessageBody(body[4:])
        elif self.subprotocol_type == ListTypes.X40:
            subprotocol_body = XC140MessageBody(body[4:])
        elif self.subprotocol_type == ListTypes.X45:
            subprotocol_body = XC145MessageBody(body[4:])

        if subprotocol_body is not None:
            for key in vars(subprotocol_body):
                if key != "data":
                    value = getattr(subprotocol_body, key, None)
                    setattr(self, key, value)


class XBB11MessageBody(MessageBody):
    """AC BB Subprotocol 11 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC BB Subprotocol 11 message body."""
        super().__init__(
            body,
            [
                BoolParser(
                    DeviceAttributes.power,
                    byte=0,
                    byte_mask=0x01,
                ),
                BoolParser(
                    DeviceAttributes.dry,
                    byte=0,
                    byte_mask=0x10,
                    true_value=0x10,
                ),
                BoolParser(
                    DeviceAttributes.boost_mode,
                    byte=0,
                    byte_mask=0x20,
                    true_value=0x20,
                ),
                BoolParser(
                    DeviceAttributes.aux_heating,
                    byte=1,
                    byte_mask=0x40,
                    true_value=0x40,
                ),
                BoolParser(
                    DeviceAttributes.sleep_mode,
                    byte=2,
                    byte_mask=0x80,
                    true_value=0x80,
                ),
                IntParser(
                    DeviceAttributes.mode,
                    byte=5,
                    transform_func=lambda x: (
                        BB_AC_MODES.index(x + 1) if x + 1 in BB_AC_MODES else 0
                    ),
                ),
                FloatParser(
                    DeviceAttributes.target_temperature,
                    byte=6,
                    transform_func=lambda x: (x - TEMP_INDOOR_OFFSET) / TEMP_DIVISOR,
                ),
                IntParser(DeviceAttributes.fan_speed, byte=7),
                BoolParser("timer", byte=25, byte_mask=0x04, true_value=0x04),
                BoolParser(
                    DeviceAttributes.eco_mode,
                    byte=25,
                    byte_mask=0x40,
                    true_value=0x40,
                ),
                BoolParser("bb_fresh_air_power", byte=45, byte_mask=0x01),
                BoolParser(
                    "bb_fresh_air_exhaust_power",
                    byte=45,
                    byte_mask=0x02,
                    true_value=0x02,
                ),
                IntParser("bb_fresh_air_fan_speed", byte=46),
                IntParser("bb_fresh_air_exhaust_speed", byte=47),
            ],
        )


class XBB10MessageBody(MessageBody):
    """AC BB Subprotocol 10 message body."""

    def __init__(self, body: bytearray, parse_temp: Callable[[int], float]) -> None:
        """Initialize AC BB Subprotocol 10 message body."""
        super().__init__(
            body,
            [
                FloatParser(
                    DeviceAttributes.indoor_temperature,
                    byte=7,
                    length_in_bytes=2,
                    first_upper=False,
                    transform_func=lambda x: parse_temp(int(x)),
                ),
                IntParser(DeviceAttributes.indoor_humidity, byte=30),
                BoolParser(
                    "sn8_flag",
                    byte=80,
                    true_value=XBB_SN8_BYTE_FLAG,
                    default_value=False,
                ),
            ],
        )


class XBB30MessageBody(MessageBody):
    """AC BB Subprotocol 30 message body."""

    def __init__(self, body: bytearray, parse_temp: Callable[[int], float]) -> None:
        """Initialize AC BB Subprotocol 30 message body."""
        super().__init__(
            body,
            [
                FloatParser(
                    DeviceAttributes.outdoor_temperature,
                    byte=5,
                    length_in_bytes=2,
                    first_upper=False,
                    transform_func=lambda x: parse_temp(int(x)),
                ),
                IntParser(DeviceAttributes.target_compressor_frequency, byte=10),
                IntParser(DeviceAttributes.compressor_frequency, byte=11),
            ],
        )


class XBBMessageBody(MessageBody):
    """AC BB message body."""

    def __init__(self, body: bytearray) -> None:
        """Initializ AC BB message body."""

        def _parse_temp(value: int) -> float:
            if (value & 0x8000) > 0:
                return value / 100
            return (0 - (~(value) + 1) & 0xFFFF) / 100

        self.subprotocol_type = 0
        super().__init__(body, [IntParser("subprotocol_type", byte=5)])
        data = body[6:]
        subprotocol_body: MessageBody | None = None

        if self.subprotocol_type in (ListTypes.X11, ListTypes.X20):
            subprotocol_body = XBB11MessageBody(data)
        elif self.subprotocol_type == ListTypes.X10:
            subprotocol_body = XBB10MessageBody(data, _parse_temp)
        elif self.subprotocol_type == ListTypes.X12:
            pass
        elif self.subprotocol_type == ListTypes.X30:
            subprotocol_body = XBB30MessageBody(data, _parse_temp)
        elif self.subprotocol_type in (ListTypes.X13, ListTypes.X21):
            pass

        if subprotocol_body is not None:
            for key in vars(subprotocol_body):
                if key != "data":
                    value = getattr(subprotocol_body, key, None)
                    setattr(self, key, value)


class MessageACResponse(MessageResponse):
    """AC message response."""

    def __init__(
        self,
        message: bytearray,
        power_analysis_method: int = 3,
        new_protocol_temperature: bool = False,
    ) -> None:
        """Initialize AC message response."""
        super().__init__(message)
        # dataType 0x05 and messageBytes[0] 0xA0
        if self.message_type == MessageType.notify2 and self.body_type == ListTypes.A0:
            self.set_body(XA0MessageBody(super().body))
        # dataType 0x04 and messageBytes[0] 0xA1
        elif (
            self.message_type == MessageType.notify1
            and self.body_type == ListTypes.A1
            and len(super().body) >= A1_MIN_BODY_LENGTH
        ):
            self.set_body(XA1MessageBody(super().body))
        elif (
            self.message_type == MessageType.notify1 and self.body_type == ListTypes.A1
        ):
            _LOGGER.debug(
                "Skipping notify1 A1 body too short to parse (%d < %d bytes): %s",
                len(super().body),
                A1_MIN_BODY_LENGTH,
                super().body.hex(),
            )
        # parse MessageCapabilitiesQuery/MessageCapabilitiesAdditionalQuery response
        # dataType 0x03 and messageBytes[0] 0xB5
        elif self.message_type == MessageType.query and self.body_type == ListTypes.B5:
            self.set_body(XB5MessageBody(super().body, self.body_type))
        # dataType 0x05 and messageBytes[0] 0xB5
        # dataType 0x02 and messageBytes[0] 0xB0 (set result Unidentified protocol)
        # dataType 0x03 and messageBytes[0] 0xB1
        elif self.message_type in [
            MessageType.query,
            MessageType.set,
            MessageType.notify2,
        ] and self.body_type in [ListTypes.B0, ListTypes.B1, ListTypes.B5]:
            self.set_body(
                XBXMessageBody(super().body, self.body_type, new_protocol_temperature),
            )
        # dataType 0x02 and messageBytes[0] 0xC0
        # dataType 0x03 and messageBytes[0] 0xC0
        elif (
            self.message_type in [MessageType.query, MessageType.set]
            and self.body_type == ListTypes.C0
        ):
            self.set_body(XC0MessageBody(super().body))
        # messageBytes[0] 0xC1
        elif self.message_type == MessageType.query and self.body_type == ListTypes.C1:
            self.set_body(XC1MessageBody(super().body, power_analysis_method))
        elif (
            self.message_type
            in [MessageType.set, MessageType.query, MessageType.notify2]
            and self.body_type == ListTypes.BB
            and len(super().body) >= BB_MIN_BODY_LENGTH
        ):
            self.used_subprotocol = True
            self.set_body(XBBMessageBody(super().body))

        self.set_attr()
