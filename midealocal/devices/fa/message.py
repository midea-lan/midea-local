"""Midea local FA message."""

from midealocal.const import DeviceType
from midealocal.message import (
    ListTypes,
    MessageBody,
    MessageRequest,
    MessageResponse,
    MessageType,
)

MAX_FAN_SPEED = 26
TILTING_ANGLE_GET_BYTE = 25
TILTING_ANGLE_SET_BYTE = 24
HUMIDIFY_ON_VALUE = 2
HUMIDIFY_GET_BYTE = 9
DISPLAY_SET_BYTE = 18
DISPLAY_GET_BYTE = 19
WATERIONS_SET_BYTE = 33
WATERIONS_GET_BYTE = 34

# Fields below are shared by the T_0000_FA_17 (protocol 0) and
# T_0000_FA_560000F3_2023011001 (protocol 5) lua profiles at identical byte
# offsets; only the mode bit-width/table (see PROTOCOL_V5, MODE_V5_MASK) and
# the swing angle representation differ between the two and are handled
# separately.
PROTOCOL_GET_BYTE = 23
PROTOCOL_V5 = 5
MODE_V5_MASK = 0x3E
ERROR_CODE_GET_BYTE = 1
VOICE_BYTE = 2
ANION_ANOPHELIFUGE_BYTE = 9
BODY_FEELING_SCAN_BYTE = 15
SCENE_BYTE = 16
HUMIDIFY_FEEDBACK_GET_BYTE = 12
TEMPERATURE_FEEDBACK_GET_BYTE = 13
TARGET_TEMPERATURE_GET_BYTE = 6
TARGET_HUMIDITY_GET_BYTE = 7
TEMPERATURE_OFFSET = 41
TEMPERATURE_MIN = -40
TEMPERATURE_MAX = 50
HUMIDITY_MIN = 1
HUMIDITY_MAX = 100
TEMPERATURE_RAW_MIN = 1
TEMPERATURE_RAW_MAX = TEMPERATURE_MAX + TEMPERATURE_OFFSET
VOICE_SET_BYTE = 1
BODY_FEELING_SCAN_SET_BYTE = 14
SCENE_SET_BYTE = 15
TARGET_TEMPERATURE_SET_BYTE = 5
TARGET_HUMIDITY_SET_BYTE = 6
ANION_ANOPHELIFUGE_SET_BYTE = 8


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


class MessageSet(MessageFABase):
    """Message set."""

    def __init__(self, protocol_version: int, subtype: int) -> None:
        """Initialize the message with protocol version and subtype."""
        super().__init__(
            protocol_version=protocol_version,
            message_type=MessageType.set,
            body_type=ListTypes.X00,
        )
        self._subtype = subtype
        self.power: bool | None = None
        self.lock: bool | None = None
        self.mode: int | None = None
        self.fan_speed: int | None = None
        self.oscillate: bool | None = None
        self.oscillation_angle: int | None = None
        self.oscillation_mode: int | None = None
        self.tilting_angle: int | None = None
        self.humidify: bool | None = None
        self.waterions: bool | None = None
        self.display_on_off: bool | None = None
        self.mode_set_overrides: dict[int, int] | None = None
        self.fa_message_protocol: int | None = None
        self.voice: int | None = None
        self.scene: int | None = None
        self.anion: bool | None = None
        self.anophelifuge: bool | None = None
        self.body_feeling_scan: bool | None = None
        self.target_temperature: float | None = None
        self.target_humidity: float | None = None

    @property
    def _body(self) -> bytearray:  # noqa: C901
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
        if self.lock is not None:
            if self.lock:
                _body_return[2] = 1
            else:
                _body_return[2] = 2
        if self.mode is not None:
            if self.fa_message_protocol == PROTOCOL_V5:
                # Protocol 5 uses a 5-bit mode field with the raw table
                # index (1..20), unlike protocol 0's 4-bit "index + 1".
                _body_return[3] = 1 | ((self.mode << 1) & MODE_V5_MASK)
            else:
                override = (self.mode_set_overrides or {}).get(self.mode)
                _body_return[3] = (
                    override
                    if override is not None
                    else 1 | (((self.mode + 1) << 1) & 0x1E)
                )
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
        if self.humidify is not None:
            if self.humidify:
                _body_return[8] = (_body_return[8] & 0x0F) | 0x20
            else:
                _body_return[8] = (_body_return[8] & 0x0F) | 0x10
        if self.waterions is not None and len(_body_return) > WATERIONS_SET_BYTE:
            if self.waterions:
                _body_return[33] = (_body_return[33] & 0xFC) | 0x01
            else:
                _body_return[33] = (_body_return[33] & 0xFC) | 0x02
        if self.display_on_off is not None and len(_body_return) > DISPLAY_SET_BYTE:
            if self.display_on_off:
                _body_return[18] = (_body_return[18] & 0x3F) | 0x40
            else:
                _body_return[18] = (_body_return[18] & 0x3F) | 0x80
        if self.voice is not None and len(_body_return) > VOICE_SET_BYTE:
            _body_return[VOICE_SET_BYTE] = self.voice
        if (
            self.target_temperature is not None
            and len(_body_return) > TARGET_TEMPERATURE_SET_BYTE
            and TEMPERATURE_MIN <= self.target_temperature <= TEMPERATURE_MAX
        ):
            _body_return[TARGET_TEMPERATURE_SET_BYTE] = int(
                self.target_temperature + TEMPERATURE_OFFSET,
            )
        if (
            self.target_humidity is not None
            and len(_body_return) > TARGET_HUMIDITY_SET_BYTE
            and HUMIDITY_MIN <= self.target_humidity <= HUMIDITY_MAX
        ):
            _body_return[TARGET_HUMIDITY_SET_BYTE] = int(self.target_humidity)
        has_anion_or_anophelifuge = (
            self.anion is not None or self.anophelifuge is not None
        )
        if (
            has_anion_or_anophelifuge
            and len(_body_return) > ANION_ANOPHELIFUGE_SET_BYTE
        ):
            byte = _body_return[ANION_ANOPHELIFUGE_SET_BYTE]
            if self.anion is not None:
                byte = (byte & 0xFC) | (0x01 if self.anion else 0x02)
            if self.anophelifuge is not None:
                byte = (byte & 0xF3) | (0x04 if self.anophelifuge else 0x08)
            _body_return[ANION_ANOPHELIFUGE_SET_BYTE] = byte
        if (
            self.body_feeling_scan is not None
            and len(_body_return) > BODY_FEELING_SCAN_SET_BYTE
        ):
            _body_return[BODY_FEELING_SCAN_SET_BYTE] = (
                1 if self.body_feeling_scan else 2
            )
        if self.scene is not None and len(_body_return) > SCENE_SET_BYTE:
            _body_return[SCENE_SET_BYTE] = self.scene
        return _body_return


class FAGeneralMessageBody(MessageBody):
    """General message body."""

    def __init__(self, body: bytearray) -> None:
        """Initialize the message body."""
        super().__init__(body)
        lock = body[3] & 0x03
        if lock == 1:
            self.child_lock = True
        else:
            self.child_lock = False
        self.fa_message_protocol = (
            body[PROTOCOL_GET_BYTE] if len(body) > PROTOCOL_GET_BYTE else 0
        )
        self.power = (body[4] & 0x01) > 0
        if self.fa_message_protocol == PROTOCOL_V5:
            mode_v5 = (body[4] & MODE_V5_MASK) >> 1
            if mode_v5 > 0:
                self.mode = mode_v5
        else:
            mode = (body[4] & 0x1E) >> 1
            if mode > 0:
                self.mode = mode - 1
        fan_speed = body[5]
        if 1 <= fan_speed <= MAX_FAN_SPEED:
            self.fan_speed = fan_speed
        else:
            self.fan_speed = 0
        self.oscillate = (body[8] & 0x01) > 0
        self.oscillation_angle = (body[8] & 0x70) >> 4
        self.oscillation_mode = (body[8] & 0x0E) >> 1
        self.tilting_angle = body[25] if len(body) > TILTING_ANGLE_GET_BYTE else 0
        self.humidify = (
            ((body[9] & 0xF0) >> 4) == HUMIDIFY_ON_VALUE
            if len(body) > HUMIDIFY_GET_BYTE
            else False
        )
        self.waterions = (
            ((body[34] & 0x03) >> 0) == 1 if len(body) > WATERIONS_GET_BYTE else False
        )
        self.display_on_off = (
            ((body[19] & 0xC0) >> 6) == 1 if len(body) > DISPLAY_GET_BYTE else False
        )
        self.error_code = (
            body[ERROR_CODE_GET_BYTE] if len(body) > ERROR_CODE_GET_BYTE else 0
        )
        self.voice = body[VOICE_BYTE] if len(body) > VOICE_BYTE else 0
        if len(body) > ANION_ANOPHELIFUGE_BYTE:
            self.anion = (body[ANION_ANOPHELIFUGE_BYTE] & 0x03) == 0x01
            self.anophelifuge = ((body[ANION_ANOPHELIFUGE_BYTE] & 0x0C) >> 2) == 0x01
        else:
            self.anion = False
            self.anophelifuge = False
        self.body_feeling_scan = (
            body[BODY_FEELING_SCAN_BYTE] == 1
            if len(body) > BODY_FEELING_SCAN_BYTE
            else False
        )
        self.scene = body[SCENE_BYTE] if len(body) > SCENE_BYTE else 0
        humidify_feedback = (
            body[HUMIDIFY_FEEDBACK_GET_BYTE]
            if len(body) > HUMIDIFY_FEEDBACK_GET_BYTE
            else 0
        )
        self.humidify_feedback = (
            humidify_feedback
            if HUMIDITY_MIN <= humidify_feedback <= HUMIDITY_MAX
            else None
        )
        temperature_feedback = (
            body[TEMPERATURE_FEEDBACK_GET_BYTE]
            if len(body) > TEMPERATURE_FEEDBACK_GET_BYTE
            else 0
        )
        self.temperature_feedback = (
            temperature_feedback - TEMPERATURE_OFFSET
            if TEMPERATURE_RAW_MIN <= temperature_feedback <= TEMPERATURE_RAW_MAX
            else None
        )
        target_temperature = (
            body[TARGET_TEMPERATURE_GET_BYTE]
            if len(body) > TARGET_TEMPERATURE_GET_BYTE
            else 0
        )
        self.target_temperature = (
            target_temperature - TEMPERATURE_OFFSET
            if TEMPERATURE_RAW_MIN <= target_temperature <= TEMPERATURE_RAW_MAX
            else None
        )
        target_humidity = (
            body[TARGET_HUMIDITY_GET_BYTE]
            if len(body) > TARGET_HUMIDITY_GET_BYTE
            else 0
        )
        self.target_humidity = (
            target_humidity if HUMIDITY_MIN <= target_humidity <= HUMIDITY_MAX else None
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
