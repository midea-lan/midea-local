"""Midea local CC message."""

from enum import IntEnum

from midealocal.const import DeviceType
from midealocal.crc8 import calculate
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

# body[1] format byte that flags the newer VRF panel (171PNL01 / 171PANEL) layout
FE_FORMAT_BYTE = 0xFE
# plausibility upper bound (Celsius) for a decoded 0xFE indoor temperature
MAX_VALID_INDOOR_TEMP = 60
# vertical louver angle value meaning "auto / oscillating"
FE_SWING_AUTO = 0x06


class CCHeatStatus(IntEnum):
    """CC Heat Status."""

    X10 = 1
    X20 = 2


class MessageCCBase(MessageRequest):
    """CC message base."""

    def __init__(
        self,
        protocol_version: int,
        message_type: MessageType,
        body_type: ListTypes,
    ) -> None:
        """Initialize CC message base."""
        super().__init__(
            device_type=DeviceType.CC,
            protocol_version=protocol_version,
            message_type=message_type,
            body_type=body_type,
        )

    @property
    def _body(self) -> bytearray:
        raise NotImplementedError


class MessageQuery(MessageCCBase):
    """CC message query."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize CC message query."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.query,
            body_type=ListTypes.X01,
        )

    @property
    def _body(self) -> bytearray:
        return bytearray([0x00] * 23)


class MessageSet(MessageCCBase):
    """CC message set."""

    def __init__(self, protocol_version: int) -> None:
        """Initialize CC message set."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.C3,
        )
        self.power = False
        self.mode = 4
        self.fan_speed = 0x80
        self.target_temperature: float = 26
        self.eco_mode = False
        self.sleep_mode = False
        self.night_light = False
        self.ventilation = False
        self.aux_heat_status = 0
        self.auto_aux_heat_running = False
        self.swing = False

    @property
    def _body(self) -> bytearray:
        # Byte1, Power Mode
        power = 0x80 if self.power else 0
        mode = 1 << (self.mode - 1)
        # Byte2 fan_speed
        fan_speed = self.fan_speed
        # Byte3 Integer of target_temperature
        temperature_integer = int(self.target_temperature) & 0xFF
        # Byte6 eco_mode ventilation aux_heating
        eco_mode = 0x01 if self.eco_mode else 0
        if self.aux_heat_status == CCHeatStatus.X10:
            aux_heating = 0x10
        elif self.aux_heat_status == CCHeatStatus.X20:
            aux_heating = 0x20
        else:
            aux_heating = 0
        swing = 0x04 if self.swing else 0
        ventilation = 0x08 if self.ventilation else 0
        # Byte8 sleep_mode night_light
        sleep_mode = 0x10 if self.sleep_mode else 0
        night_light = 0x08 if self.night_light else 0
        # Byte11 Dot of target_temperature
        temperature_dot = (
            int((self.target_temperature - temperature_integer) * 10) & 0xFF
        )
        return bytearray(
            [
                power | mode,
                fan_speed,
                temperature_integer,
                # timer
                0x00,
                0x00,
                eco_mode | ventilation | swing | aux_heating,
                # non-stepless fan speed
                0xFF,
                sleep_mode | night_light,
                0x00,
                0x00,
                temperature_dot,
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


class CCControlId(IntEnum):
    """Control ids for the 0xFE VRF panel key-value control protocol."""

    POWER = 0x0000
    TARGET_TEMPERATURE = 0x0003
    MODE = 0x0012
    FAN_SPEED = 0x0015
    SWING = 0x001C
    ECO = 0x0028
    SLEEP = 0x002C


class MessageFEControl(MessageRequest):
    """CC control message for 0xFE VRF panel controllers.

    These devices ignore the legacy C3 ``MessageSet`` command and instead use a
    key-value (TLV) control frame: for every control a 2-byte big-endian id, a
    1-byte length, the value bytes and a 0xFF separator, followed by an
    incrementing message id and a CRC8. The frame layout was reverse-engineered
    by the msmart-ng project (https://github.com/mill1000/midea-ac-py, MIT).
    """

    _message_id = 0

    def __init__(
        self,
        protocol_version: int,
        controls: list[tuple[CCControlId, int]],
    ) -> None:
        """Initialize CC 0xFE control message."""
        super().__init__(
            device_type=DeviceType.CC,
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X01,
        )
        self._controls = controls

    def _next_message_id(self) -> int:
        MessageFEControl._message_id = (MessageFEControl._message_id + 1) & 0xFF
        return MessageFEControl._message_id

    @property
    def body(self) -> bytearray:
        """Build the full control frame body (no body_type prefix)."""
        payload = bytearray()
        for control_id, value in self._controls:
            payload += int(control_id).to_bytes(2, "big")
            payload.append(1)
            payload.append(value & 0xFF)
            payload.append(0xFF)
        payload.append(self._next_message_id())
        payload.append(calculate(payload))
        return payload

    @property
    def _body(self) -> bytearray:
        return bytearray()


# 0xFE-format operational_mode (body[31]) -> internal mode index used by the
# legacy decoder / HA climate (1=fan_only, 2=dry, 3=heat, 4=cool, 5=auto).
FE_MODE_TO_INDEX = {0x01: 1, 0x06: 2, 0x03: 3, 0x02: 4, 0x05: 5}

# internal mode index -> 0xFE operational_mode value (inverse of FE_MODE_TO_INDEX)
INDEX_TO_FE_MODE = {1: 0x01, 2: 0x06, 3: 0x03, 4: 0x02, 5: 0x05}


class CCGeneralMessageBody(MessageBody):
    """CC message general body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize CC message general body."""
        super().__init__(body)
        # Newer VRF panel controllers (e.g. 171PNL01 / 171PANEL) answer the X01
        # query with a different payload layout, flagged by the 0xFE format byte
        # at body[1]. The legacy layout (below) decodes those bytes incorrectly
        # (indoor_temperature becomes -20, mode is stuck on auto, power is always
        # on). The 0xFE byte positions used here were reverse-engineered by the
        # msmart-ng project (https://github.com/mill1000/midea-ac-py, MIT).
        self.is_fe_format = len(body) > 1 and body[1] == FE_FORMAT_BYTE
        if self.is_fe_format:
            self._parse_fe_body(body)
        else:
            self._parse_legacy_body(body)

    def _parse_legacy_body(self, body: bytearray) -> None:
        """Decode the original (pre-0xFE) CC payload layout."""
        self.power = (body[1] & 0x80) > 0
        mode: float = body[1] & 0x1F
        self.mode = 0
        while mode >= 1:
            mode /= 2
            self.mode += 1
        self.fan_speed = body[2]
        self.target_temperature = body[3] + body[19] / 10
        self.indoor_temperature: float | None = (body[4] - 40) / 2
        self.eco_mode = (body[13] & 0x01) > 0
        self.sleep_mode = (body[14] & 0x10) > 0
        self.night_light = (body[14] & 0x08) > 0
        self.ventilation = (body[13] & 0x08) > 0
        self.aux_heat_status = (body[14] & 0x60) >> 5
        self.auto_aux_heat_running = (body[13] & 0x02) > 0
        self.fan_speed_level = (body[13] & 0x40) > 0
        self.temperature_precision = 1 if (body[14] & 0x80) > 0 else 0.5
        self.swing = (body[13] & 0x04) > 0
        self.temp_fahrenheit = (body[20] & 0x80) > 0

    def _parse_fe_body(self, body: bytearray) -> None:
        """Decode the 0xFE VRF panel payload layout (171PNL01 / 171PANEL)."""
        self.power = bool(body[8])
        self.target_temperature = (body[11] / 2) - 40
        # indoor temperature is a 16-bit big-endian value in 0.1 degree units
        indoor = (body[12] << 8 | body[13]) / 10
        self.indoor_temperature = indoor if 0 < indoor < MAX_VALID_INDOOR_TEMP else None
        self.mode = FE_MODE_TO_INDEX.get(body[31], 5)
        # fan speed is reported as 1-7 (+8=auto), mapped to names by the device
        self.fan_speed = body[34]
        self.eco_mode = bool(body[56])
        self.sleep_mode = bool(body[60])
        # vertical louver angle: 0x06 == auto (oscillating)
        self.swing = body[41] == FE_SWING_AUTO
        self.temp_fahrenheit = bool(body[21])
        # attributes not present in the 0xFE payload -> safe defaults
        self.night_light = False
        self.ventilation = False
        self.aux_heat_status = 0
        self.auto_aux_heat_running = False
        self.fan_speed_level = False
        self.temperature_precision = 0.5


class MessageCCResponse(MessageResponse):
    """CC message response."""

    def __init__(self, message: bytes) -> None:
        """Initialize CC message response."""
        super().__init__(bytearray(message))
        if (
            (self.message_type == MessageType.query and self.body_type == ListTypes.X01)
            or (
                self.message_type in [MessageType.notify1, MessageType.notify2]
                and self.body_type == ListTypes.X01
            )
            or (self.message_type == MessageType.set and self.body_type == ListTypes.C3)
        ):
            self.set_body(CCGeneralMessageBody(super().body))
        self.set_attr()
