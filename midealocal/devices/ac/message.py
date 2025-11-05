"""Midea AC message."""

import logging
from collections.abc import Callable, Mapping
from enum import IntEnum
from types import MappingProxyType

from midealocal.const import MAX_BYTE_VALUE, DeviceType
from midealocal.crc8 import calculate
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
    NewProtocolMessageBody,
)

_LOGGER = logging.getLogger(__name__)

BB_AC_MODES = [0, 3, 1, 2, 4, 5]
BB_MIN_BODY_LENGTH = 21
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
SCREEN_DISPLAY_BYTE_CHECK = 0x07
SUB_PROTOCOL_BODY_TEMP_CHECK = 0x80
TEMP_DECIMAL_MIN_BODY_LENGTH = 20
TIMER_MIN_SUBPROTOCOL_LENGTH = 27
XBB_SN8_BYTE_FLAG = 0x31
XC1_SUBBODY_TYPE_44 = 0x44
XC1_SUBBODY_TYPE_40 = 0x40
XC1_SUBBODY_TYPE_45 = 0x45


class PowerFormats(IntEnum):
    """AC Power/Energy analysis formats."""

    # unless stated, consumption / energy is 0.01 kWh, and power in 0.1 W resolution
    BCD = 1
    BINARY = 2  # binary with energy in 0.1 kWh resolution
    MIXED = 3  # mixed/INT (byte = 0-99)
    BINARY1 = 12  # binary


class NewProtocolQuery(IntEnum):
    """New protocol tags in query."""

    error_code_query = 0x003F
    mode_query = 0x0041
    high_temperature_monitor = 0x0047
    rate_select = 0x0048


class NewProtocolTags(IntEnum):
    """New protocol tags in query and response."""

    indoor_humidity = 0x0015  # queryType == "indoor_humidity"
    screen_display = 0x0017
    breezeless = 0x0018  # queryType == "fn_no_wind_sense"
    prompt_tone = 0x001A  # buzzerValue
    indirect_wind = 0x0042  # prevent_straight_wind
    fresh_air_1 = 0x0233
    fresh_air_2 = 0x004B  # queryType == "fresh_air"
    prevent_super_cool = 0x0049
    auto_prevent_straight_wind = 0x0226
    self_clean = 0x0039  # self_clean query can't return response
    wind_straight = 0x0032
    wind_avoid = 0x0033
    intelligent_wind = 0x0034
    child_prevent_cold_wind = 0x003A
    little_angel = 0x021B
    cool_hot_sense = 0x0021
    even_wind = 0x004E
    security = 0x0029
    voice_control = 0x0020
    single_tuyere = 0x004F
    extreme_wind = 0x004C
    pre_cool_hot = 0x0201
    water_washing = 0x004A
    gentle_wind_sense = 0x0043
    parent_control = 0x0051
    nobody_energy_save = 0x0030
    filter_level = 0x0409
    prevent_straight_wind_lr = 0x0058
    pm25_value = 0x020B
    water_pump = 0x0050
    intelligent_control = 0x0031
    volume_control = 0x0024
    wind_ud_angle = 0x0009
    wind_lr_angle = 0x000A
    face_register = 0x0044
    degerming = 0x005A
    light = 0x005B
    wind_top = 0x0061
    wind_around = 0x0059
    remote_control_lock = 0x0227  # power_lock?
    ptc_lock = 0x0229
    offline_operating_time = 0x022B
    operating_time = 0x0228
    child_lock = 0x005C
    buzzer_all = 0x022C
    self_remove_odor_phase = 0x005D
    high_temp_remove_odor_alone = 0x005E
    ozone = 0x005F
    soft_warm = 0x0063
    fresh_air_parm = 0x0250
    rewarming_dry = 0x0068
    arom = 0x0069
    # b5 device
    b5_mode = 0x0214
    b5_strong_wind = 0x021A
    b5_wind_speed = 0x0210
    b5_humidity = 0x021F
    b5_temperature = 0x0225
    b5_eco = 0x0212
    b5_filter_remind = 0x0217
    b5_filter_check = 0x0221
    b5_fahrenheit = 0x0222
    b5_electricity = 0x0216
    b5_ptc = 0x0219
    b5_wind_swing = 0x0215
    b5_screen_display = 0x0224
    b5_anion = 0x021E
    b5_sound = 0x022C


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


class MessageGroupZeroQuery(MessageACBase):
    """AC message power query(queryType == "group_data_zero")."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message power query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x21, 0x01, 0x40, 0x00, 0x01])

    @property
    def body(self) -> bytearray:
        """AC message power query body."""
        body = bytearray([self.body_type]) + self._body
        body.append(calculate(body))
        return body


class MessagePowerQuery(MessageACBase):
    """AC message power query(queryType == "group_data_four")."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message power query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x21, 0x01, 0x44, 0x00, 0x01])

    @property
    def body(self) -> bytearray:
        """AC message power query body."""
        body = bytearray([self.body_type]) + self._body
        body.append(calculate(body))
        return body


class MessageHumidityQuery(MessageACBase):
    """AC message query indoor humidity(queryType == "group_data_five")."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message power query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X41,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x21, 0x01, 0x45, 0x00, 0x01])

    @property
    def body(self) -> bytearray:
        """AC message power query body."""
        body = bytearray([self.body_type]) + self._body
        body.append(calculate(body))
        return body


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

    def __init__(self, protocol_version: int) -> None:
        """Initialize AC message new protocol query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.B1,
        )

    @property
    def _body(self) -> bytearray:
        query_params = [
            NewProtocolTags.indirect_wind,
            NewProtocolTags.breezeless,
            NewProtocolTags.indoor_humidity,
            NewProtocolTags.screen_display,
            NewProtocolTags.fresh_air_1,
            NewProtocolTags.fresh_air_2,
            NewProtocolTags.wind_lr_angle,
            NewProtocolTags.wind_ud_angle,
        ]

        _body = bytearray([len(query_params)])
        for param in query_params:
            _body.extend([param & 0xFF, param >> 8])
        return _body


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
    def _subprotocol_body(self) -> bytes:
        return bytes([])

    @property
    def body(self) -> bytearray:
        """AC message sub protocol body."""
        body = bytearray([self.body_type]) + self._body
        body.append(calculate(body))
        body.append(self.checksum(body))
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
    def _subprotocol_body(self) -> bytes:
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
        self.smart_eye = False
        self.dry = False
        self.aux_heating = False
        self.eco_mode = False
        self.temp_fahrenheit = False
        self.sleep_mode = False
        self.natural_wind = False
        self.frost_protect = False
        self.comfort_mode = False

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
        # Byte 8, turbo
        boost_mode = 0x20 if self.boost_mode else 0
        # Byte 9 aux_heating eco_mode
        smart_eye = 0x01 if self.smart_eye else 0
        dry = 0x04 if self.dry else 0
        aux_heating = 0x08 if self.aux_heating else 0
        eco_mode = 0x80 if self.eco_mode else 0
        # Byte 10 temp_fahrenheit
        temp_fahrenheit = 0x04 if self.temp_fahrenheit else 0
        sleep_mode = 0x01 if self.sleep_mode else 0
        boost_mode_1 = 0x02 if self.boost_mode else 0
        # Byte 17 natural_wind
        natural_wind = 0x40 if self.natural_wind else 0
        # Byte 21 frost_protect
        frost_protect = 0x80 if self.frost_protect else 0
        # Byte 22 comfort_mode
        comfort_mode = 0x01 if self.comfort_mode else 0

        return bytearray(
            [
                power | prompt_tone,
                mode | target_temperature,
                fan_speed,
                0x00,
                0x00,
                0x00,
                swing_mode,
                boost_mode,
                smart_eye | dry | aux_heating | eco_mode,
                temp_fahrenheit | sleep_mode | boost_mode_1,
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
                comfort_mode,
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
        payload[0] = pack_count
        return payload


class XA0MessageBody(MessageBody):
    """AC A0 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC A0 message body."""
        super().__init__(body)
        self.power = (body[1] & 0x1) > 0  # powerValue
        # temperature & smallTemperature
        self.target_temperature = (
            ((body[1] & 0x3E) >> 1) - 4 + 16.0 + (0.5 if body[1] & 0x40 > 0 else 0.0)
        )
        self.mode = (body[2] & 0xE0) >> 5  # modeValue
        self.fan_speed = body[3] & 0x7F  # fanspeedValue
        self.swing_vertical = (body[7] & 0xC) > 0  # swingLRValue
        self.swing_horizontal = (body[7] & 0x3) > 0  # swingUDValue
        # strongWindValue
        self.boost_mode = ((body[8] & 0x20) > 0) or ((body[10] & 0x2) > 0)
        self.power_saving = body[8] & 0x08  # power_saving
        self.comfort_sleep = body[8] & 0x03  # comfortableSleepValue
        self.comfort_sleep_switch = body[14] & 0x01  # comfortableSleepSwitch
        self.pmv = ((body[11] & 0xF0) >> 4) * 0.5 - 3.5  # pmv
        # screenDisplayNowValue
        self.screen_display = (
            (body[14] >> 4 & 0x7) != SCREEN_DISPLAY_BYTE_CHECK
        ) and self.power
        self.smart_eye = (body[9] & 0x01) > 0
        self.dry = (body[9] & 0x04) > 0  # dryValue
        self.aux_heating = (body[9] & 0x08) > 0  # PTCValue
        self.purifier = body[9] & 0x20  # purifierValue
        self.eco_mode = (body[9] & 0x10) > 0  # ecoValue
        self.sleep_mode = (body[10] & 0x01) > 0
        self.natural_wind = (body[10] & 0x40) > 0  # naturalWind
        self.smart_dry = body[13] & 0x7F  # smartDryValue
        self.kick_quilt = (body[10] & 0x04) >> 2  # kickQuilt
        self.prevent_cold = (body[10] & 0x08) >> 3  # preventCold
        self.full_dust = ((body[13] & 0x20) >> 5) > 0  # dust_full_time
        # comfortPowerSave
        self.comfort_mode = (
            (body[14] & 0x1) > 0 if len(body) > CONFORT_MODE_MIN_LENGTH else False
        )
        # smartDryValue
        self.smart_dry = (body[13] & 0x7F) > 0
        # swingLRUnderSwitch
        self.swing_lr_switch = (
            body[19] & 0x80 if len(body) >= SWING_LR_MIN_LENGTH else 0
        )
        # swingLRValueUnder
        self.swing_lr_value = body[9] & 0x40
        # arom
        self.frost_protect = (
            ((body[21] & 0x80) >> 7) > 0
            if len(body) >= FROST_PROTECT_MIN_LENGTH
            else False
        )
        if len(body) >= FRESH_AIR_C0_MIN_LENGTH:
            self.fresh_filter_time_total = body[25] * 256 + body[24]
            self.fresh_filter_time_use = body[16] * 256 + body[15]
            self.fresh_filter_timeout = (body[13] & 0x40) >> 6


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
        super().__init__(body)
        # currentWorkTime
        self.current_work_time = (
            (((body[9] << 8) & 0xFF00) | (body[10] & 0x00FF)) * 60 * 24
            + body[11] * 60
            + body[12]
        )
        decimal = body[18] if len(body) > TEMP_DECIMAL_MIN_BODY_LENGTH else 0
        self.indoor_temperature = self.parse_temperature(body[13], decimal & 0x0F)
        self.outdoor_temperature = self.parse_temperature(body[14], decimal >> 4)
        self.indoor_humidity = body[17] if body[17] != 0 else None


class XBXMessageBody(NewProtocolMessageBody):
    """AC BX message body. body[0] b0/b1, body[1] propertyNumber, cursor 2."""

    def __init__(self, body: bytearray, bt: int) -> None:
        """Initialize AC BX message body."""
        super().__init__(body, bt)

        params = self.parse()
        if NewProtocolTags.indirect_wind in params:
            self.indirect_wind = (
                params[NewProtocolTags.indirect_wind][0] == INDIRECT_WIND_VALUE
            )
        if NewProtocolTags.indoor_humidity in params:
            indoor_humidity = params[NewProtocolTags.indoor_humidity][0]
            self.indoor_humidity = indoor_humidity if indoor_humidity != 0 else None
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
        if NewProtocolTags.b5_screen_display in params:
            self.b5_screen_display = params[NewProtocolTags.b5_screen_display][0]
        if NewProtocolTags.b5_sound in params:
            self.b5_sound = params[NewProtocolTags.b5_sound][0]
        if NewProtocolTags.b5_humidity in params:
            self.b5_humidity = params[NewProtocolTags.b5_humidity][0]


class XC0MessageBody(XMessageBody):
    """AC C0 message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize AC C0 message body."""
        super().__init__(body)
        self.power = (body[1] & 0x1) > 0  # powerValue
        self.mode = (body[2] & 0xE0) >> 5  # modeValue
        self.target_temperature = (
            (body[2] & 0x0F) + 16.0 + (0.5 if body[0x02] & 0x10 > 0 else 0.0)
        )  # temperature + smallTemperature
        self.fan_speed = body[3] & 0x7F  # fanspeedValue
        self.swing_vertical = (body[7] & 0x0C) > 0  # swingUDValue
        self.swing_horizontal = (body[7] & 0x03) > 0  # swingLRValue
        # strongWindValue
        self.boost_mode = ((body[8] & 0x20) > 0) or ((body[10] & 0x2) > 0)
        self.power_saving = body[8] & 0x08  # power_saving
        self.comfort_sleep = body[8] & 0x03  # comfortableSleepValue
        self.comfort_sleep_switch = body[9] & 0x40  # comfortableSleepSwitch
        self.pmv = (body[14] & 0x0F) * 0.5 - 3.5  # pmv
        self.smart_eye = (body[8] & 0x40) > 0
        self.natural_wind = (body[9] & 0x2) > 0  # naturalWind
        self.dry = (body[9] & 0x4) > 0  # dryValue
        self.eco_mode = (body[9] & 0x10) > 0  # ecoValue
        self.aux_heating = (body[9] & 0x08) > 0  # PTCValue
        self.purifier = body[9] & 0x20  # purifierValue
        self.temp_fahrenheit = (body[10] & 0x04) > 0
        self.sleep_mode = (body[10] & 0x01) > 0
        decimal = body[15] if len(body) > TEMP_DECIMAL_MIN_BODY_LENGTH else 0
        self.indoor_temperature = self.parse_temperature(body[11], decimal & 0x0F)
        self.outdoor_temperature = self.parse_temperature(body[12], decimal >> 4)
        self.kick_quilt = (body[10] & 0x04) >> 2  # kickQuilt
        self.prevent_cold = (body[10] & 0x20) >> 5  # preventCold
        self.full_dust = ((body[13] & 0x20) >> 5) > 0  # dust_full_time
        # screenDisplayNowValue
        self.screen_display = (
            (body[14] >> 4 & 0x7) != SCREEN_DISPLAY_BYTE_CHECK
        ) and self.power
        # arom
        self.frost_protect = (
            (body[21] & 0x80) > 0 if len(body) >= FROST_PROTECT_MIN_LENGTH else False
        )
        # comfortPowerSave
        self.comfort_mode = (
            (body[22] & 0x1) > 0 if len(body) >= CONFORT_MODE_MIN_LENGTH2 else False
        )
        # smartDryValue
        self.smart_dry = (
            (body[19] & 0x7F) > 0 if len(body) >= SMART_DRY_MIN_LENGTH else False
        )
        # swingLRUnderSwitch
        self.swing_lr_switch = (
            body[19] & 0x80 if len(body) >= SWING_LR_MIN_LENGTH else 0
        )
        # swingLRValueUnder
        self.swing_lr_value = body[20] & 0x80 if len(body) >= SWING_LR_MIN_LENGTH else 0
        if len(body) >= FRESH_AIR_C0_MIN_LENGTH:
            self.fresh_filter_time_total = body[25] * 256 + body[24]
            self.fresh_filter_time_use = body[27] * 256 + body[26]
            self.fresh_filter_timeout = (body[13] & 0x40) >> 6


class XC1MessageBody(MessageBody):
    """AC C1 message body."""

    def __init__(self, body: bytearray, analysis_method: int = 3) -> None:
        """Initialize AC C1 message body."""
        super().__init__(body)
        if body[3] == XC1_SUBBODY_TYPE_44:

            def parse_consumption(data: bytearray) -> float:
                return self.parse_consumption(analysis_method, data)

            # total_power_consumption
            self.total_energy_consumption = parse_consumption(body[4:8])
            # total_operating_consumption
            self.total_operating_consumption = parse_consumption(body[8:12])
            # current_operating_consumption
            self.current_energy_consumption = parse_consumption(body[12:16])
            # current_time_power
            self.realtime_power = self.parse_power(analysis_method, body[16:19])
        elif body[3] == XC1_SUBBODY_TYPE_40:
            self.electrify_time_day = body[5] | (body[4] << 8)
            self.electrify_time_hour = body[6]
            self.electrify_time_min = body[7]
            self.electrify_time_second = body[8]
            # summary
            self.electrify_time = (
                (self.electrify_time_day * 24)
                + self.electrify_time_hour
                + (self.electrify_time_min / 60)
                + (self.electrify_time_second / 3600)
            )
            self.total_operating_time_day = body[10] | (body[9] << 8)
            self.total_operating_time_hour = body[11]
            self.total_operating_time_min = body[12]
            self.total_operating_time_second = body[13]
            # summary
            self.total_operating_time = (
                (self.total_operating_time_day * 24)
                + self.total_operating_time_hour
                + (self.total_operating_time_min / 60)
                + (self.total_operating_time_second / 3600)
            )
            self.current_operating_time_day = body[15] | (body[14] << 8)
            self.current_operating_time_hour = body[16]
            self.current_operating_time_min = body[17]
            self.current_operating_time_second = body[18]
            # summary
            self.current_operating_time = (
                (self.current_operating_time_day * 24)
                + self.current_operating_time_hour
                + (self.current_operating_time_min / 60)
                + (self.current_operating_time_second / 3600)
            )
        elif body[3] == XC1_SUBBODY_TYPE_45:
            # indoor humidity, it should be the same value as XBB/XA1 message
            self.indoor_humidity = body[4] if body[4] != 0 else None

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
        return cls.parse_value(analysis_method, databytes) / 10

    @classmethod
    def parse_consumption(cls, analysis_method: int, databytes: bytearray) -> float:
        """AC C1 message body parse consumption."""
        # LSB = 0.01 kWh, except for default binary format = 0.1 kWh
        divisor = 10 if analysis_method == PowerFormats.BINARY else 100
        return cls.parse_value(analysis_method, databytes) / divisor


class XBBMessageBody(MessageBody):
    """AC BB message body."""

    def __init__(self, body: bytearray) -> None:
        """Initializ AC BB message body."""
        super().__init__(body)
        subprotocol_head = body[:6]
        subprotocol_body = body[6:]
        data_type = subprotocol_head[-1]
        subprotocol_body_len = len(subprotocol_body)
        if data_type in (ListTypes.X11, ListTypes.X20):
            self.power = (subprotocol_body[0] & 0x1) > 0
            self.dry = (subprotocol_body[0] & 0x10) > 0
            self.boost_mode = (subprotocol_body[0] & 0x20) > 0
            self.aux_heating = (subprotocol_body[1] & 0x40) > 0
            self.sleep_mode = (subprotocol_body[2] & 0x80) > 0
            try:
                self.mode = BB_AC_MODES.index(subprotocol_body[5] + 1)
            except ValueError:
                self.mode = 0
            self.target_temperature = (subprotocol_body[6] - 30) / 2
            self.fan_speed = subprotocol_body[7]
            self.timer = (
                (subprotocol_body[25] & 0x04) > 0
                if subprotocol_body_len > TIMER_MIN_SUBPROTOCOL_LENGTH
                else False
            )
            self.eco_mode = (
                (subprotocol_body[25] & 0x40) > 0
                if subprotocol_body_len > ECO_MODE_MIN_SUBPROTOCOL_LENGTH
                else False
            )
        elif data_type == ListTypes.X10:
            if subprotocol_body[8] & 0x80 == SUB_PROTOCOL_BODY_TEMP_CHECK:
                self.indoor_temperature = (
                    0 - (~(subprotocol_body[7] + subprotocol_body[8] * 256) + 1)
                    & 0xFFFF
                ) / 100
            else:
                self.indoor_temperature = (
                    subprotocol_body[7] + subprotocol_body[8] * 256
                ) / 100
            self.indoor_humidity = (
                subprotocol_body[30] if subprotocol_body[30] != 0 else None
            )
            self.sn8_flag = subprotocol_body[80] == XBB_SN8_BYTE_FLAG
        elif data_type == ListTypes.X12:
            pass
        elif data_type == ListTypes.X30:
            if subprotocol_body[6] & 0x80 == SUB_PROTOCOL_BODY_TEMP_CHECK:
                self.outdoor_temperature = (
                    0 - (~(subprotocol_body[5] + subprotocol_body[6] * 256) + 1)
                    & 0xFFFF
                ) / 100
            else:
                self.outdoor_temperature = (
                    subprotocol_body[5] + subprotocol_body[6] * 256
                ) / 100
        elif data_type in (ListTypes.X13, ListTypes.X21):
            pass


class MessageACResponse(MessageResponse):
    """AC message response."""

    def __init__(self, message: bytearray, power_analysis_method: int = 3) -> None:
        """Initialize AC message response."""
        super().__init__(message)
        # dataType 0x05 and messageBytes[0] 0xA0
        if self.message_type == MessageType.notify2 and self.body_type == ListTypes.A0:
            self.set_body(XA0MessageBody(super().body))
        # dataType 0x04 and messageBytes[0] 0xA1
        elif (
            self.message_type == MessageType.notify1 and self.body_type == ListTypes.A1
        ):
            self.set_body(XA1MessageBody(super().body))
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
            self.set_body(XBXMessageBody(super().body, self.body_type))
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
