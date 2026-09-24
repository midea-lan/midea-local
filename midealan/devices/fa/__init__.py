"""Midea local FA device."""

import json
import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealan.const import DeviceType
from midealan.device import MideaDevice, MideaDeviceInitKwargs
from midealan.message import MessageType

from .message import (
    FA_MESSAGE_PROTOCOL,
    FA_MESSAGE_PROTOCOL_V6,
    FA_MESSAGE_PROTOCOLS,
    HUMIDIFY_CODES,
    MAX_FAN_SPEED,
    MAX_V6_FAN_SPEED,
    SCENE_CODES,
    SWING_DIRECTION_CODES,
    TILTING_ANGLE_CODES,
    V6_DEFAULT_SWING_ANGLE,
    V6_DEFAULT_SWING_ANGLE_CODE,
    V6_INVALID_SWING_ANGLE_CODE,
    V6_MAX_NORMAL_SWING_ANGLE,
    FAValue,
    MessageCB4Set,
    MessageFAResponse,
    MessageNewSet,
    MessageQuery,
    MessageSet,
    MessageV6Set,
    _new_angle_to_code,
)

_LOGGER = logging.getLogger(__name__)
DEFAULT_NEW_SWING_ANGLE = 1275
INVALID_MODE_CODE = 0
MAX_LEGACY_SWING_MODE = 6
MODE_NEW_PROTOCOL_MODELS = {
    "560000F3": FA_MESSAGE_PROTOCOL,
    "56011CB4": FA_MESSAGE_PROTOCOL,
    "56011CEC": FA_MESSAGE_PROTOCOL_V6,
}
MODE_ECOLOGY_MODELS = {"56011CB4", "56011CEC"}
MODE_OFFICIAL_V6_MODELS = {"56011CEC"}
# Model 56000211 reports raw mode 4 with the additional power-mode bit set.
MODE_LEGACY_SET_OVERRIDES = {
    "56000211": {0x04: 0x29},
}
NEW_SWING_ANGLE_STEP = 5


def _status_code(value: FAValue) -> int:
    """Convert a decoded protocol value to an integer code."""
    return int(value) if isinstance(value, (bool, float, int)) else 0


class DeviceAttributes(StrEnum):
    """Midea FA device attributes."""

    power = "power"
    child_lock = "child_lock"
    mode = "mode"
    fan_speed = "fan_speed"
    oscillate = "oscillate"
    oscillation_angle = "oscillation_angle"
    tilting_angle = "tilting_angle"
    oscillation_mode = "oscillation_mode"
    humidify = "humidify"
    waterions = "waterions"
    display_on_off = "display_on_off"
    voice = "voice"
    error_code = "error_code"
    scene = "scene"
    auto_power_off = "auto_power_off"
    target_temperature = "target_temperature"
    humidity = "humidity"
    humidify_mode = "humidify_mode"
    anophelifuge = "anophelifuge"
    anion = "anion"
    humidify_feedback = "humidify_feedback"
    temperature_feedback = "temperature_feedback"
    body_feeling_scan = "body_feeling_scan"


class MideaFADevice(MideaDevice):
    """Midea FA device."""

    _oscillation_angles: ClassVar[dict[int, str]] = {
        0x00: "off",
        0x01: "30",
        0x02: "60",
        0x03: "90",
        0x04: "120",
        0x05: "180",
        0x06: "360",
    }
    _tilting_angles: ClassVar[dict[int, str]] = TILTING_ANGLE_CODES
    _oscillation_modes: ClassVar[dict[int, str]] = {
        key: value
        for key, value in SWING_DIRECTION_CODES.items()
        if key <= MAX_LEGACY_SWING_MODE
    }
    _new_oscillation_modes: ClassVar[dict[int, str]] = SWING_DIRECTION_CODES
    _legacy_modes: ClassVar[dict[int, str]] = {
        0x00: "invalid",
        0x01: "normal",
        0x02: "natural",
        0x03: "sleep",
        0x04: "comfort",
        0x05: "mute",
        0x06: "baby",
        0x07: "feel",
        0x08: "storm",
        0x09: "strong",
        0x0A: "soft",
        0x0B: "customize",
    }
    _new_modes: ClassVar[dict[int, str]] = {
        **_legacy_modes,
        0x0C: "warm",
        0x0D: "smart",
        0x0E: "ionic",
        0x0F: "ai_smart",
        0x10: "double_area",
        0x11: "purified_wind",
        0x12: "sleeping_wind",
        0x13: "purify_only",
        0x14: "self_selection",
    }
    _ecology_modes: ClassVar[dict[int, str]] = {
        **_new_modes,
        0x15: "ecology",
    }
    _official_v6_modes: ClassVar[dict[int, str]] = {
        0x14: "self_selection",
        0x12: "sleeping_wind",
        0x15: "ecology",
    }
    _voice: ClassVar[dict[int, str]] = {
        0x00: "invalid",
        0x01: "open_gps",
        0x02: "close_gps",
        0x04: "open_buzzer",
        0x05: "open_tip",
        0x08: "close_buzzer",
        0x0A: "mute",
    }
    _humidify: ClassVar[dict[int, str]] = HUMIDIFY_CODES
    _scene: ClassVar[dict[int, str]] = SCENE_CODES

    def __init__(
        self,
        *,
        customize: str,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea FA device."""
        super().__init__(
            device_type=DeviceType.FA,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.child_lock: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.fan_speed: 0,
                DeviceAttributes.oscillate: False,
                DeviceAttributes.oscillation_angle: None,
                DeviceAttributes.tilting_angle: None,
                DeviceAttributes.humidify: False,
                DeviceAttributes.waterions: False,
                DeviceAttributes.display_on_off: False,
                DeviceAttributes.oscillation_mode: None,
                DeviceAttributes.voice: None,
                DeviceAttributes.error_code: None,
                DeviceAttributes.scene: None,
                DeviceAttributes.auto_power_off: None,
                DeviceAttributes.target_temperature: None,
                DeviceAttributes.humidity: None,
                DeviceAttributes.humidify_mode: None,
                DeviceAttributes.anophelifuge: None,
                DeviceAttributes.anion: None,
                DeviceAttributes.humidify_feedback: None,
                DeviceAttributes.temperature_feedback: None,
                DeviceAttributes.body_feeling_scan: None,
            },
        )
        self._default_speed_count = 3
        self._speed_count: int = self._default_speed_count
        self.fa_protocol = 0
        self.set_customize(customize)

    @property
    def speed_count(self) -> int:
        """Return the device speed count."""
        return self._speed_count

    @property
    def max_speed_count(self) -> int:
        """Return the maximum fan speed supported by the active FA protocol."""
        return (
            MAX_V6_FAN_SPEED
            if self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6
            else MAX_FAN_SPEED
        )

    @property
    def oscillation_angles(self) -> list[str]:
        """Return the list of supported horizontal swing angles."""
        if self._effective_fa_protocol in FA_MESSAGE_PROTOCOLS:
            return self._new_angle_options()
        return list(self._oscillation_angles.values())

    @property
    def tilting_angles(self) -> list[str]:
        """Return the list of supported vertical swing angles."""
        if self._effective_fa_protocol in FA_MESSAGE_PROTOCOLS:
            return self._new_angle_options()
        return list(self._tilting_angles.values())

    @property
    def oscillation_modes(self) -> list[str]:
        """Return the list of supported oscillation modes."""
        if self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6:
            return ["off", "oscillation", "tilting", "both", "custom"]
        if self._effective_fa_protocol == FA_MESSAGE_PROTOCOL:
            return list(self._new_oscillation_modes.values())
        return list(self._oscillation_modes.values())

    @property
    def preset_modes(self) -> list[str]:
        """Return a list of preset modes."""
        return [
            mode
            for code, mode in self._preset_mode_codes.items()
            if code != INVALID_MODE_CODE
        ]

    @property
    def _mode_codes(self) -> dict[int, str]:
        """Return the mode map for the detected FA protocol and model."""
        if (
            self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6
            or self.model in MODE_ECOLOGY_MODELS
        ):
            return self._ecology_modes
        if self._effective_fa_protocol in FA_MESSAGE_PROTOCOLS:
            return self._new_modes
        return self._legacy_modes

    @property
    def _preset_mode_codes(self) -> dict[int, str]:
        """Return the selectable mode map for the detected FA protocol and model."""
        if (
            self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6
            and self.model in MODE_OFFICIAL_V6_MODELS
        ):
            return self._official_v6_modes
        return self._mode_codes

    @property
    def _effective_fa_protocol(self) -> int:
        """Return the response protocol or a model-derived protocol hint."""
        return (
            self.fa_protocol
            if self.fa_protocol in FA_MESSAGE_PROTOCOLS
            else MODE_NEW_PROTOCOL_MODELS.get(self.model, 0)
        )

    def _new_angle_options(self) -> list[str]:
        """Return angle options for protocol v5/v6 select entities."""
        max_angle = (
            V6_MAX_NORMAL_SWING_ANGLE
            if self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6
            else DEFAULT_NEW_SWING_ANGLE
        )
        options = [
            "off",
            *(
                str(angle)
                for angle in range(
                    NEW_SWING_ANGLE_STEP,
                    max_angle + 1,
                    NEW_SWING_ANGLE_STEP,
                )
            ),
        ]
        if self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6:
            options.append(V6_DEFAULT_SWING_ANGLE)
        return options

    def _new_status_angle_value(self, code: int) -> str | None:
        """Convert a protocol v5/v6 angle code to a public option value."""
        if self.fa_protocol == FA_MESSAGE_PROTOCOL_V6:
            if code == V6_DEFAULT_SWING_ANGLE_CODE:
                return V6_DEFAULT_SWING_ANGLE
            if code == V6_INVALID_SWING_ANGLE_CODE:
                return None
        if code == 0:
            return "off"
        return str(code * NEW_SWING_ANGLE_STEP)

    def _mode_code(self, value: str) -> int | None:
        """Return the protocol mode code for a public mode value."""
        for key, item in self._preset_mode_codes.items():
            if key != INVALID_MODE_CODE and item == value:
                return key
        return None

    def build_query(self) -> list[MessageQuery]:
        """Build the FA query."""
        return [MessageQuery(self._message_protocol_version)]

    def _set_status_value(
        self,
        attr: DeviceAttributes,
        value: FAValue,
    ) -> FAValue:
        """Convert a decoded wire value to the public FA attribute value."""
        result = value
        if attr == DeviceAttributes.oscillation_angle:
            if self.fa_protocol in FA_MESSAGE_PROTOCOLS:
                result = self._new_status_angle_value(_status_code(value))
            else:
                result = self._oscillation_angles.get(_status_code(value))
        elif attr == DeviceAttributes.tilting_angle:
            if self.fa_protocol in FA_MESSAGE_PROTOCOLS:
                result = self._new_status_angle_value(_status_code(value))
            else:
                result = self._tilting_angles.get(_status_code(value))
        elif attr == DeviceAttributes.oscillation_mode:
            modes = (
                self._new_oscillation_modes
                if self.fa_protocol in FA_MESSAGE_PROTOCOLS
                else self._oscillation_modes
            )
            result = modes.get(_status_code(value))
        elif attr == DeviceAttributes.mode:
            code = _status_code(value)
            result = None if code == INVALID_MODE_CODE else self._mode_codes.get(code)
        elif attr == DeviceAttributes.voice:
            result = (
                value
                if isinstance(value, str)
                else self._voice.get(_status_code(value))
            )
        elif attr == DeviceAttributes.scene:
            result = (
                value
                if isinstance(value, str)
                else self._scene.get(_status_code(value))
            )
        return result

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Process an FA response."""
        message = MessageFAResponse(msg)
        if message.message_type not in {
            MessageType.query,
            MessageType.set,
            MessageType.notify1,
        }:
            return {}
        if getattr(message, "is_new_protocol", False):
            self.fa_protocol = getattr(message, "protocol_version", 0)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status: dict[str, Any] = {}
        for attr in self._attributes:
            if not hasattr(message, str(attr)):
                continue
            value = getattr(message, str(attr))
            value = self._set_status_value(attr, value)
            if attr == DeviceAttributes.power:
                self._attributes[attr] = value
                if not value:
                    self._attributes[DeviceAttributes.fan_speed] = 0
            elif (
                attr == DeviceAttributes.fan_speed
                and not self._attributes[DeviceAttributes.power]
            ):
                self._attributes[attr] = 0
            else:
                self._attributes[attr] = value
            new_status[str(attr)] = self._attributes[attr]
        return new_status

    def _legacy_angle_code(self, value: str, values: dict[int, str]) -> int | None:
        """Convert a legacy public angle to its protocol code."""
        for key, item in values.items():
            if item == value:
                return key
        return None

    def _legacy_angle_or_default(
        self,
        value: FAValue,
        values: dict[int, str],
    ) -> int:
        """Use 90 degrees when a legacy angle is unset or Off."""
        if value in {None, "", "off"}:
            value = "90"
        return self._legacy_angle_code(str(value), values) or 0

    def _set_oscillation_mode(self, message: MessageSet, value: str) -> None:
        """Build a legacy oscillation-mode command."""
        if value == "off" or not value:
            message.oscillate = False
            return
        message.oscillate = True
        message.oscillation_mode = self._legacy_angle_code(
            value,
            self._oscillation_modes,
        )
        if value == "oscillation":
            message.oscillation_angle = self._legacy_angle_or_default(
                self._attributes[DeviceAttributes.oscillation_angle],
                self._oscillation_angles,
            )
        elif value == "tilting":
            message.tilting_angle = self._legacy_angle_or_default(
                self._attributes[DeviceAttributes.tilting_angle],
                self._tilting_angles,
            )
        else:
            message.oscillation_angle = self._legacy_angle_or_default(
                self._attributes[DeviceAttributes.oscillation_angle],
                self._oscillation_angles,
            )
            message.tilting_angle = self._legacy_angle_or_default(
                self._attributes[DeviceAttributes.tilting_angle],
                self._tilting_angles,
            )

    def _set_oscillation_angle(self, message: MessageSet, value: str) -> None:
        """Build a legacy horizontal-angle command."""
        if value == "off" or not value:
            tilting = self._attributes[DeviceAttributes.tilting_angle]
            if tilting in {None, "off"}:
                message.oscillate = False
            else:
                message.oscillate = True
                message.oscillation_mode = 2
                message.tilting_angle = self._legacy_angle_code(
                    str(tilting),
                    self._tilting_angles,
                )
            return
        message.oscillation_angle = self._legacy_angle_code(
            value,
            self._oscillation_angles,
        )
        message.oscillate = True
        tilting = self._attributes[DeviceAttributes.tilting_angle]
        if tilting in {None, "off"}:
            message.oscillation_mode = 1
        elif self._attributes[DeviceAttributes.oscillation_mode] == "tilting":
            message.oscillation_mode = 6
            message.tilting_angle = self._legacy_angle_code(
                str(tilting),
                self._tilting_angles,
            )

    def _set_tilting_angle(self, message: MessageSet, value: str) -> None:
        """Build a legacy vertical-angle command."""
        if value == "off" or not value:
            oscillation = self._attributes[DeviceAttributes.oscillation_angle]
            if oscillation in {None, "off"}:
                message.oscillate = False
            else:
                message.oscillate = True
                message.oscillation_mode = 1
                message.oscillation_angle = self._legacy_angle_code(
                    str(oscillation),
                    self._oscillation_angles,
                )
            return
        message.tilting_angle = self._legacy_angle_code(value, self._tilting_angles)
        message.oscillate = True
        oscillation = self._attributes[DeviceAttributes.oscillation_angle]
        if oscillation in {None, "off"}:
            message.oscillation_mode = 2
        elif self._attributes[DeviceAttributes.oscillation_mode] == "oscillation":
            message.oscillation_mode = 6
            message.oscillation_angle = self._legacy_angle_code(
                str(oscillation),
                self._oscillation_angles,
            )

    def set_oscillation(
        self,
        attr: str,
        value: bool | float | str,
    ) -> MessageSet | None:
        """Build a legacy oscillation command."""
        message: MessageSet | None = None
        if self._attributes[attr] == value:
            return None
        if attr == DeviceAttributes.oscillate:
            message = MessageSet(self._message_protocol_version, self.subtype)
            message.oscillate = bool(value)
            if value:
                message.oscillation_angle = 3
                message.oscillation_mode = 1
        elif attr == DeviceAttributes.oscillation_mode and (
            value in self._oscillation_modes.values() or not value
        ):
            message = MessageSet(self._message_protocol_version, self.subtype)
            self._set_oscillation_mode(message, str(value))
        elif attr == DeviceAttributes.oscillation_angle and (
            value in self._oscillation_angles.values() or not value
        ):
            message = MessageSet(self._message_protocol_version, self.subtype)
            self._set_oscillation_angle(message, str(value))
        elif attr == DeviceAttributes.tilting_angle and (
            value in self._tilting_angles.values() or not value
        ):
            message = MessageSet(self._message_protocol_version, self.subtype)
            self._set_tilting_angle(message, str(value))
        return message

    def set_new_oscillation(
        self,
        attr: str,
        value: bool | float | str,
    ) -> MessageNewSet | MessageV6Set | None:
        """Build a protocol v5/v6 oscillation command."""
        if self._attributes[attr] == value:
            return None
        message = self._new_message()
        valid = True
        is_v6 = self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6
        current_mode = self._attributes[DeviceAttributes.oscillation_mode]
        if attr == DeviceAttributes.oscillate:
            message.oscillate = bool(value)
            if value:
                message.oscillation_angle = (
                    V6_DEFAULT_SWING_ANGLE
                    if self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6
                    else DEFAULT_NEW_SWING_ANGLE
                )
                message.oscillation_mode = "oscillation"
            else:
                message.oscillation_angle = 0
                message.oscillation_mode = "oscillation"
        elif attr == DeviceAttributes.oscillation_mode:
            if value in {"off", "", None}:
                message.oscillate = False
                message.oscillation_angle = 0
                message.oscillation_mode = "oscillation"
            elif value in self._new_oscillation_modes.values() and (
                not is_v6 or value not in {"curve-w", "curve-8", "reserved"}
            ):
                message.oscillation_mode = str(value)
                message.oscillate = True
                default_angle = (
                    V6_DEFAULT_SWING_ANGLE if is_v6 else DEFAULT_NEW_SWING_ANGLE
                )
                current_angle = self._attributes[DeviceAttributes.oscillation_angle]
                current_tilting = self._attributes[DeviceAttributes.tilting_angle]
                if value != "tilting":
                    message.oscillation_angle = (
                        current_angle
                        if self._is_active_angle(current_angle)
                        else default_angle
                    )
                if value in {"tilting", "both"}:
                    message.tilting_angle = (
                        current_tilting
                        if self._is_active_angle(current_tilting)
                        else default_angle
                    )
            else:
                valid = False
        elif attr == DeviceAttributes.oscillation_angle:
            if value in {"off", "", None}:
                message.oscillate = False
                message.oscillation_angle = 0
                message.oscillation_mode = "oscillation"
            else:
                valid = (
                    _new_angle_to_code(
                        value,
                        max_angle=(
                            V6_MAX_NORMAL_SWING_ANGLE
                            if is_v6
                            else DEFAULT_NEW_SWING_ANGLE
                        ),
                    )
                    is not None
                )
                if valid:
                    message.oscillate = True
                    message.oscillation_angle = value
                    current_tilting = self._attributes[DeviceAttributes.tilting_angle]
                    if current_mode == "both" and self._is_active_angle(
                        current_tilting,
                    ):
                        message.oscillation_mode = "both"
                        message.tilting_angle = current_tilting
                    else:
                        message.oscillation_mode = "oscillation"
        elif attr == DeviceAttributes.tilting_angle:
            if value in {"off", "", None}:
                message.tilting_angle = 0
                horizontal = self._attributes[DeviceAttributes.oscillation_angle]
                if self._is_active_angle(horizontal):
                    message.oscillate = True
                    message.oscillation_mode = "oscillation"
                    message.oscillation_angle = horizontal
                else:
                    message.oscillate = False
                    message.oscillation_mode = "tilting"
            else:
                valid = (
                    _new_angle_to_code(
                        value,
                        max_angle=(
                            V6_MAX_NORMAL_SWING_ANGLE
                            if is_v6
                            else DEFAULT_NEW_SWING_ANGLE
                        ),
                    )
                    is not None
                )
                if valid:
                    message.oscillate = True
                    message.tilting_angle = value
                    current_horizontal = self._attributes[
                        DeviceAttributes.oscillation_angle
                    ]
                    if current_mode == "both" and self._is_active_angle(
                        current_horizontal,
                    ):
                        message.oscillation_mode = "both"
                        message.oscillation_angle = current_horizontal
                    else:
                        message.oscillation_mode = "tilting"
        else:
            valid = False
        return message if valid else None

    @staticmethod
    def _is_active_angle(value: FAValue) -> bool:
        """Return whether a public swing angle represents an active axis."""
        if isinstance(value, str):
            if value == V6_DEFAULT_SWING_ANGLE:
                return True
            try:
                return float(value) > 0
            except ValueError:
                return False
        return (
            isinstance(value, (int, float))
            and not isinstance(value, bool)
            and value > 0
        )

    def _new_message(self) -> MessageNewSet | MessageCB4Set | MessageV6Set:
        """Create a protocol v5/v6 set message."""
        message_type = (
            MessageV6Set
            if self._effective_fa_protocol == FA_MESSAGE_PROTOCOL_V6
            else MessageCB4Set
            if self.model == "56011CB4"
            else MessageNewSet
        )
        return message_type(self._message_protocol_version, self.subtype)

    def _legacy_message(self) -> MessageSet:
        """Create a legacy set message."""
        message = MessageSet(self._message_protocol_version, self.subtype)
        message.mode_set_overrides = MODE_LEGACY_SET_OVERRIDES.get(self.model, {})
        return message

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Set an FA device attribute."""
        if attr in {
            DeviceAttributes.oscillate,
            DeviceAttributes.oscillation_mode,
            DeviceAttributes.oscillation_angle,
            DeviceAttributes.tilting_angle,
        }:
            message = (
                self.set_new_oscillation(attr, value)
                if self._effective_fa_protocol in FA_MESSAGE_PROTOCOLS
                else self.set_oscillation(attr, value)
            )
        elif (
            attr == DeviceAttributes.fan_speed
            and int(value) > 0
            and not self._attributes[DeviceAttributes.power]
        ):
            message = (
                self._new_message()
                if self._effective_fa_protocol
                else self._legacy_message()
            )
            message.fan_speed = int(value)
            message.power = True
        elif attr == DeviceAttributes.mode:
            message = None
            mode = self._mode_code(str(value))
            if mode is not None:
                message = (
                    self._new_message()
                    if self._effective_fa_protocol
                    else self._legacy_message()
                )
                message.mode = mode
                message.power = True
        elif attr == DeviceAttributes.fan_speed and int(value) == 0:
            message = None
        else:
            message = (
                self._new_message()
                if self._effective_fa_protocol
                else self._legacy_message()
            )
            setattr(message, str(attr), value)
        if message is not None:
            self.build_send(message)

    def turn_on(self, fan_speed: int | None = None, mode: str | None = None) -> None:
        """Turn on the device."""
        message = (
            self._new_message()
            if self._effective_fa_protocol
            else self._legacy_message()
        )
        message.power = True
        if fan_speed is not None:
            message.fan_speed = fan_speed
        mode_code = self._mode_code(str(mode))
        if mode_code is not None:
            message.mode = mode_code
        self.build_send(message)

    def set_customize(self, customize: str) -> None:
        """Set device customization."""
        self._speed_count = self._default_speed_count
        if customize:
            try:
                params = json.loads(customize)
                speed_count = params.get("speed_count") if params else None
                if (
                    isinstance(speed_count, int)
                    and not isinstance(speed_count, bool)
                    and 1 <= speed_count <= self.max_speed_count
                ):
                    self._speed_count = speed_count
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
        self.update_all({"speed_count": self._speed_count})


class MideaAppliance(MideaFADevice):
    """Midea appliance device."""
