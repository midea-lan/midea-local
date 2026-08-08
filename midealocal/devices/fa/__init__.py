"""Midea local FA device."""

import json
import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs, list_translator

from .message import MessageFAResponse, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


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


class MideaFADevice(MideaDevice):
    """Midea FA device."""

    _oscillation_angles: ClassVar[list[str]] = [
        "Off",
        "30",
        "60",
        "90",
        "120",
        "180",
        "360",
    ]
    _tilting_angles: ClassVar[list[str]] = [
        "Off",
        "30",
        "60",
        "90",
        "120",
        "180",
        "360",
        "+60",
        "-60",
        "40",
    ]
    _oscillation_modes: ClassVar[list[str]] = [
        "Off",
        "Oscillation",
        "Tilting",
        "Curve-W",
        "Curve-8",
        "Reserved",
        "Both",
    ]
    _modes: ClassVar[list[str]] = [
        "Normal",
        "Natural",
        "Sleep",
        "Comfort",
        "Silent",
        "Baby",
        "Induction",
        "Circulation",
        "Strong",
        "Soft",
        "Customize",
        "Warm",
        "Smart",
    ]

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
            },
        )
        self._default_speed_count = 3
        self._speed_count: int = self._default_speed_count
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
        return self._modes

    def build_query(self) -> list[MessageQuery]:
        """Midea FA device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea FA device process message."""
        message = MessageFAResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)

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
                DeviceAttributes.mode: list_translator(MideaFADevice._modes),
                DeviceAttributes.power: _translate_power,
                DeviceAttributes.fan_speed: _translate_fan_speed,
            },
        )
        if forced_fan_speed_reset:
            new_status[DeviceAttributes.fan_speed.value] = 0
        return new_status

    def _set_oscillation_mode(self, message: MessageSet, value: str) -> None:
        if value == "Off" or not value:
            message.oscillate = False
        else:
            message.oscillate = True
            message.oscillation_mode = MideaFADevice._oscillation_modes.index(
                value,
            )
            if value == "Oscillation":
                if self._attributes[DeviceAttributes.oscillation_angle] == "Off":
                    message.oscillation_angle = 3  # 90
                else:
                    message.oscillation_angle = MideaFADevice._oscillation_angles.index(
                        self._attributes[DeviceAttributes.oscillation_angle],
                    )
            elif value == "Tilting":
                if self._attributes[DeviceAttributes.tilting_angle] == "Off":
                    message.tilting_angle = 3  # 90
                else:
                    message.tilting_angle = MideaFADevice._tilting_angles.index(
                        self._attributes[DeviceAttributes.tilting_angle],
                    )
            else:
                if self._attributes[DeviceAttributes.oscillation_angle] == "Off":
                    message.oscillation_angle = 3  # 90
                else:
                    message.oscillation_angle = MideaFADevice._oscillation_angles.index(
                        self._attributes[DeviceAttributes.oscillation_angle],
                    )
                if self._attributes[DeviceAttributes.tilting_angle] == "Off":
                    message.tilting_angle = 3  # 90
                else:
                    message.tilting_angle = MideaFADevice._tilting_angles.index(
                        self._attributes[DeviceAttributes.tilting_angle],
                    )

    def _set_oscillation_angle(self, message: MessageSet, value: str) -> None:
        if value == "Off" or not value:
            if self._attributes[DeviceAttributes.tilting_angle] == "Off":
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
            if self._attributes[DeviceAttributes.tilting_angle] == "Off":
                message.oscillation_mode = 1
            elif self._attributes[DeviceAttributes.oscillation_mode] == "Tilting":
                message.oscillation_mode = 6
                message.tilting_angle = MideaFADevice._tilting_angles.index(
                    self._attributes[DeviceAttributes.tilting_angle],
                )

    def _set_tilting_angle(self, message: MessageSet, value: str) -> None:
        if value == "Off" or not value:
            if self._attributes[DeviceAttributes.oscillation_angle] == "Off":
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
            if self._attributes[DeviceAttributes.oscillation_angle] == "Off":
                message.oscillation_mode = 2
            elif self._attributes[DeviceAttributes.oscillation_mode] == "Oscillation":
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
                message = MessageSet(self._message_protocol_version, self.subtype)
                message.oscillate = bool(value)
                if value:
                    message.oscillation_angle = 3  # 90
                    message.oscillation_mode = 1  # Oscillation
            elif attr == DeviceAttributes.oscillation_mode and (
                value in MideaFADevice._oscillation_modes or not value
            ):
                message = MessageSet(self._message_protocol_version, self.subtype)
                self._set_oscillation_mode(message, str(value))
            elif attr == DeviceAttributes.oscillation_angle and (
                value in MideaFADevice._oscillation_angles or not value
            ):
                message = MessageSet(self._message_protocol_version, self.subtype)
                self._set_oscillation_angle(message, str(value))
            elif attr == DeviceAttributes.tilting_angle and (
                value in MideaFADevice._tilting_angles or not value
            ):
                message = MessageSet(self._message_protocol_version, self.subtype)
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
            message = MessageSet(self._message_protocol_version, self.subtype)
            message.fan_speed = int(value)
            message.power = True
        elif attr == DeviceAttributes.mode:
            if value in MideaFADevice._modes:
                message = MessageSet(self._message_protocol_version, self.subtype)
                message.mode = MideaFADevice._modes.index(str(value))
        elif not (attr == DeviceAttributes.fan_speed and value == 0):
            message = MessageSet(self._message_protocol_version, self.subtype)
            setattr(message, str(attr), value)
        if message is not None:
            self.build_send(message)

    def turn_on(self, fan_speed: int | None = None, mode: str | None = None) -> None:
        """Turn on the device."""
        message = MessageSet(self._message_protocol_version, self.subtype)
        message.power = True
        if fan_speed is not None:
            message.fan_speed = fan_speed
        if mode is not None and mode in MideaFADevice._modes:
            message.mode = MideaFADevice._modes.index(mode)
        self.build_send(message)

    def set_customize(self, customize: str) -> None:
        """Set customize."""
        self._speed_count = self._default_speed_count
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "speed_count" in params:
                    self._speed_count = params.get("speed_count")
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
            self.update_all({"speed_count": self._speed_count})


class MideaAppliance(MideaFADevice):
    """Midea appliance device."""
