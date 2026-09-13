"""Midea local FA device."""

import json
import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import (
    MideaDevice,
    MideaDeviceInitKwargs,
    dict_translator,
    list_translator,
)

from .message import PROTOCOL_V5, MessageFAResponse, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)

MIN_MODE_SET_OVERRIDE = 0x00
MAX_MODE_SET_OVERRIDE = 0xFF


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
    error_code = "error_code"
    voice = "voice"
    scene = "scene"
    anion = "anion"
    anophelifuge = "anophelifuge"
    body_feeling_scan = "body_feeling_scan"
    humidify_feedback = "humidify_feedback"
    temperature_feedback = "temperature_feedback"
    target_temperature = "target_temperature"
    target_humidity = "target_humidity"


class MideaFADevice(MideaDevice):
    """Midea FA device."""

    _oscillation_angles: ClassVar[list[str]] = [
        "off",
        "30",
        "60",
        "90",
        "120",
        "180",
        "360",
    ]
    _tilting_angles: ClassVar[list[str]] = [
        "off",
        "30",
        "60",
        "90",
        "120",
        "180",
        "360",
        "plus_60",
        "minus_60",
        "40",
    ]
    _oscillation_modes: ClassVar[list[str]] = [
        "off",
        "oscillation",
        "tilting",
        "curve_w",
        "curve_8",
        "reserved",
        "both",
    ]
    _modes: ClassVar[list[str]] = [
        "none",
        "natural",
        "sleep",
        "comfort",
        "silent",
        "baby",
        "induction",
        "circulation",
        "strong",
        "soft",
        "customize",
        "warm",
        "smart",
    ]
    # Protocol 5 (T_0000_FA_560000F3_2023011001.lua) reports mode as a raw
    # 1..20 index in a 5-bit field, unlike protocol 0's 4-bit "index + 1".
    _modes_v5: ClassVar[dict[int, str]] = {
        1: "normal",
        2: "natural",
        3: "sleep",
        4: "comfort",
        5: "mute",
        6: "baby",
        7: "feel",
        8: "storm",
        9: "strong",
        10: "soft",
        11: "customize",
        12: "warm",
        13: "smart",
        14: "ionic",
        15: "ai_smart",
        16: "double_area",
        17: "purified_wind",
        18: "sleeping_wind",
        19: "purify_only",
        20: "self_selection",
    }
    _voice: ClassVar[dict[int, str]] = {
        0x01: "open_gps",
        0x02: "close_gps",
        0x04: "open_buzzer",
        0x05: "open_tips",
        0x08: "close_buzzer",
        0x0A: "mute",
    }
    _scene: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "old",
        0x02: "child",
        0x03: "read",
        0x04: "sleep",
        0x05: "ac",
    }

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
                DeviceAttributes.error_code: None,
                DeviceAttributes.voice: None,
                DeviceAttributes.scene: None,
                DeviceAttributes.anion: False,
                DeviceAttributes.anophelifuge: False,
                DeviceAttributes.body_feeling_scan: False,
                DeviceAttributes.humidify_feedback: None,
                DeviceAttributes.temperature_feedback: None,
                DeviceAttributes.target_temperature: None,
                DeviceAttributes.target_humidity: None,
            },
        )
        self._default_speed_count = 3
        self._speed_count: int = self._default_speed_count
        self._mode_set_overrides: dict[int, int] = {}
        self._fa_protocol: int = 0
        self.set_customize(customize)

    @property
    def speed_count(self) -> int:
        """Return the speed count of the device."""
        return self._speed_count

    @property
    def oscillation_angles(self) -> list[str]:
        """Return the list of possible oscillation angles."""
        return MideaFADevice._oscillation_angles

    @property
    def tilting_angles(self) -> list[str]:
        """Return the list of possible tilting angles."""
        return MideaFADevice._tilting_angles

    @property
    def oscillation_modes(self) -> list[str]:
        """Return a list of available oscillation modes."""
        return MideaFADevice._oscillation_modes

    @property
    def preset_modes(self) -> list[str]:
        """Return a list of preset modes."""
        if self._fa_protocol == PROTOCOL_V5:
            return list(MideaFADevice._modes_v5.values())
        return self._modes

    def build_query(self) -> list[MessageQuery]:
        """Midea FA device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def _new_set_message(self) -> MessageSet:
        """Build a MessageSet carrying the last-seen protocol version.

        Needed so `_body` can pick the matching mode encoding (protocol 5's
        5-bit raw table index vs protocol 0's 4-bit "index + 1").
        """
        message = MessageSet(self._message_protocol_version, self.subtype)
        message.fa_message_protocol = self._fa_protocol
        return message

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea FA device process message."""
        message = MessageFAResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        self._fa_protocol = getattr(message, "fa_message_protocol", 0)

        forced_fan_speed_reset = False

        def _translate_power(value: bool) -> bool:
            # Powering off forces fan_speed to 0, even when this particular
            # message doesn't carry a fan_speed field of its own.
            nonlocal forced_fan_speed_reset
            if not value:
                self._attributes[DeviceAttributes.fan_speed] = 0
                forced_fan_speed_reset = True
            return value

        def _translate_fan_speed(value: int) -> int:
            return 0 if not self._attributes[DeviceAttributes.power] else value

        def _translate_mode(value: int) -> str | None:
            if self._fa_protocol == PROTOCOL_V5:
                return MideaFADevice._modes_v5.get(value)
            return list_translator(MideaFADevice._modes)(value)

        new_status = self.update_attributes_from_message(
            message,
            {
                DeviceAttributes.oscillation_angle: list_translator(
                    MideaFADevice._oscillation_angles,
                ),
                DeviceAttributes.tilting_angle: list_translator(
                    MideaFADevice._tilting_angles,
                ),
                DeviceAttributes.oscillation_mode: list_translator(
                    MideaFADevice._oscillation_modes,
                ),
                DeviceAttributes.mode: _translate_mode,
                DeviceAttributes.power: _translate_power,
                DeviceAttributes.fan_speed: _translate_fan_speed,
                DeviceAttributes.voice: dict_translator(MideaFADevice._voice),
                DeviceAttributes.scene: dict_translator(MideaFADevice._scene),
            },
        )
        if forced_fan_speed_reset:
            new_status[DeviceAttributes.fan_speed.value] = 0
        return new_status

    def _set_oscillation_mode(self, message: MessageSet, value: str) -> None:
        if value == "off" or not value:
            message.oscillate = False
        else:
            message.oscillate = True
            message.oscillation_mode = MideaFADevice._oscillation_modes.index(
                value,
            )
            if value == "oscillation":
                if self._attributes[DeviceAttributes.oscillation_angle] == "off":
                    message.oscillation_angle = 3  # 90
                else:
                    message.oscillation_angle = MideaFADevice._oscillation_angles.index(
                        self._attributes[DeviceAttributes.oscillation_angle],
                    )
            elif value == "tilting":
                if self._attributes[DeviceAttributes.tilting_angle] == "off":
                    message.tilting_angle = 3  # 90
                else:
                    message.tilting_angle = MideaFADevice._tilting_angles.index(
                        self._attributes[DeviceAttributes.tilting_angle],
                    )
            else:
                if self._attributes[DeviceAttributes.oscillation_angle] == "off":
                    message.oscillation_angle = 3  # 90
                else:
                    message.oscillation_angle = MideaFADevice._oscillation_angles.index(
                        self._attributes[DeviceAttributes.oscillation_angle],
                    )
                if self._attributes[DeviceAttributes.tilting_angle] == "off":
                    message.tilting_angle = 3  # 90
                else:
                    message.tilting_angle = MideaFADevice._tilting_angles.index(
                        self._attributes[DeviceAttributes.tilting_angle],
                    )

    def _set_oscillation_angle(self, message: MessageSet, value: str) -> None:
        if value == "off" or not value:
            if self._attributes[DeviceAttributes.tilting_angle] == "off":
                message.oscillate = False
            else:
                message.oscillate = True
                message.oscillation_mode = 2
                message.tilting_angle = MideaFADevice._tilting_angles.index(
                    self._attributes[DeviceAttributes.tilting_angle],
                )
        else:
            message.oscillation_angle = MideaFADevice._oscillation_angles.index(
                value,
            )
            message.oscillate = True
            if self._attributes[DeviceAttributes.tilting_angle] == "off":
                message.oscillation_mode = 1
            elif self._attributes[DeviceAttributes.oscillation_mode] == "tilting":
                message.oscillation_mode = 6
                message.tilting_angle = MideaFADevice._tilting_angles.index(
                    self._attributes[DeviceAttributes.tilting_angle],
                )

    def _set_tilting_angle(self, message: MessageSet, value: str) -> None:
        if value == "off" or not value:
            if self._attributes[DeviceAttributes.oscillation_angle] == "off":
                message.oscillate = False
            else:
                message.oscillate = True
                message.oscillation_mode = 1
                message.oscillation_angle = MideaFADevice._oscillation_angles.index(
                    self._attributes[DeviceAttributes.oscillation_angle],
                )
        else:
            message.tilting_angle = MideaFADevice._tilting_angles.index(value)
            message.oscillate = True
            if self._attributes[DeviceAttributes.oscillation_angle] == "off":
                message.oscillation_mode = 2
            elif self._attributes[DeviceAttributes.oscillation_mode] == "oscillation":
                message.oscillation_mode = 6
                message.oscillation_angle = MideaFADevice._oscillation_angles.index(
                    self._attributes[DeviceAttributes.oscillation_angle],
                )

    def set_oscillation(
        self,
        attr: str,
        value: bool | float | str,
    ) -> MessageSet | None:
        """Set oscillation mode."""
        message: MessageSet | None = None
        if self._attributes[attr] != value:
            if attr == DeviceAttributes.oscillate:
                message = self._new_set_message()
                message.oscillate = bool(value)
                if value:
                    message.oscillation_angle = 3  # 90
                    message.oscillation_mode = 1  # Oscillation
            elif attr == DeviceAttributes.oscillation_mode and (
                value in MideaFADevice._oscillation_modes or not value
            ):
                message = self._new_set_message()
                self._set_oscillation_mode(message, str(value))
            elif attr == DeviceAttributes.oscillation_angle and (
                value in MideaFADevice._oscillation_angles or not value
            ):
                message = self._new_set_message()
                self._set_oscillation_angle(message, str(value))
            elif attr == DeviceAttributes.tilting_angle and (
                value in MideaFADevice._tilting_angles or not value
            ):
                message = self._new_set_message()
                self._set_tilting_angle(message, str(value))
        return message

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Set attribute."""
        message = None
        if attr in [
            DeviceAttributes.oscillate,
            DeviceAttributes.oscillation_mode,
            DeviceAttributes.oscillation_angle,
            DeviceAttributes.tilting_angle,
        ]:
            message = self.set_oscillation(attr, value)
        elif (
            attr == DeviceAttributes.fan_speed
            and int(value) > 0
            and not self._attributes[DeviceAttributes.power]
        ):
            message = self._new_set_message()
            message.fan_speed = int(value)
            message.power = True
        elif attr == DeviceAttributes.mode:
            mode_value = self._mode_index(str(value))
            if mode_value is not None:
                message = self._new_set_message()
                message.mode = mode_value
                message.mode_set_overrides = self._mode_set_overrides
        elif attr == DeviceAttributes.voice:
            voice_value = self._reverse_lookup(MideaFADevice._voice, str(value))
            if voice_value is not None:
                message = self._new_set_message()
                message.voice = voice_value
        elif attr == DeviceAttributes.scene:
            scene_value = self._reverse_lookup(MideaFADevice._scene, str(value))
            if scene_value is not None:
                message = self._new_set_message()
                message.scene = scene_value
        elif not (attr == DeviceAttributes.fan_speed and value == 0):
            message = self._new_set_message()
            setattr(message, str(attr), value)
        if message is not None:
            self.build_send(message)

    def turn_on(self, fan_speed: int | None = None, mode: str | None = None) -> None:
        """Turn on the device."""
        message = self._new_set_message()
        message.power = True
        if fan_speed is not None:
            message.fan_speed = fan_speed
        if mode is not None:
            mode_value = self._mode_index(mode)
            if mode_value is not None:
                message.mode = mode_value
                message.mode_set_overrides = self._mode_set_overrides
        self.build_send(message)

    def _mode_index(self, value: str) -> int | None:
        """Return the raw mode value to send for `value`, or None if unknown."""
        if self._fa_protocol == PROTOCOL_V5:
            return self._reverse_lookup(MideaFADevice._modes_v5, value)
        if value in MideaFADevice._modes:
            return MideaFADevice._modes.index(value)
        return None

    @staticmethod
    def _reverse_lookup(mapping: dict[int, str], value: str) -> int | None:
        """Return the raw key whose mapped name matches `value`, or None."""
        for raw, name in mapping.items():
            if name == value:
                return raw
        return None

    def _parse_mode_set_overrides(
        self,
        overrides: dict[str, Any],
    ) -> dict[int, int]:
        """Return the {mode index: body[3]} table, or {} if a value is not a byte.

        Each value is written straight into the set body, so anything `int()`
        would silently reshape into a byte - a fraction, a bool, a number
        outside 0..255 - is rejected here rather than sent as some other byte
        or raised on the bytearray assignment, losing the command.
        """
        parsed: dict[int, int] = {}
        rejected: dict[str, Any] = {}
        for key, value in overrides.items():
            if isinstance(value, bool) or (
                isinstance(value, float) and not value.is_integer()
            ):
                rejected[key] = value
                continue
            converted = int(value)
            if not MIN_MODE_SET_OVERRIDE <= converted <= MAX_MODE_SET_OVERRIDE:
                rejected[key] = value
                continue
            parsed[int(key)] = converted
        if rejected:
            _LOGGER.error(
                "[%s] mode_set_overrides values must be whole numbers in 0..255, "
                "ignoring the table: %s",
                self.device_id,
                rejected,
            )
            return {}
        return parsed

    def set_customize(self, customize: str) -> None:
        """Set customize."""
        self._speed_count = self._default_speed_count
        self._mode_set_overrides = {}
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "speed_count" in params:
                    self._speed_count = params.get("speed_count")
                if params and "mode_set_overrides" in params:
                    self._mode_set_overrides = self._parse_mode_set_overrides(
                        params.get("mode_set_overrides"),
                    )
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
            self.update_all({"speed_count": self._speed_count})


class MideaAppliance(MideaFADevice):
    """Midea appliance device."""
