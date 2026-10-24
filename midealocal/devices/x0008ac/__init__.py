"""Midea local x0008ac device (Toshiba IoLife AC)."""

from __future__ import annotations

import json
import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs

from .message import MessageQuery, MessageSet, parse_ac_response

_LOGGER = logging.getLogger(__name__)

# Property IDs used in set commands
_PROP_POWER = 0x0001
_PROP_MODE = 0x0002
_PROP_TARGET_TEMP = 0x0003
_PROP_FAN_SPEED = 0x0006
_PROP_SWING_UD = 0x0008
_PROP_SWING_LR = 0x0009
_PROP_DEFLECTOR_ANGLE = 0x000A
_PROP_ECO = 0x000D
_PROP_PURIFIER = 0x000E
_PROP_SCREEN_DISPLAY = 0x0017
_PROP_BREEZELESS = 0x0018
_PROP_BREEZELESS_DIRECTION = 0x0070
_PROP_BUZZER = 0x001A
_PROP_CLEAN = 0x0046  # 2-byte [clean_manual, self_clean]; both sent together
_PROP_ENERGY_SAVE = 0x0050
_PROP_DEHUMIDIFY = 0x0051
_PROP_COMFORT_AIRFLOW = 0x0055

# Setpoint range of the 0x0003 property, in degrees Celsius.
# Mode 3 is dry. Entering it resumes whichever dehumidify sub-mode was last used,
# so default to the recommended one rather than, say, clothes-drying.
_MODE_DRY = 3

# Dry sub-modes of property 0x0051.
_DEHUMIDIFY_WEAK = 1
_DEHUMIDIFY_STRONG = 2
_DEHUMIDIFY_RECOMMENDED = 4
_DEFAULT_DEHUMIDIFY = _DEHUMIDIFY_RECOMMENDED

# The unit drives the fan itself in dry mode, so the fan speed cannot be set
# there. Present the sub-mode as the fan setting instead, mapping each onto the
# speed a consumer will render as the matching name.
_DRY_FAN_SPEEDS: dict[int, int] = {
    _DEHUMIDIFY_WEAK: 40,  # low
    _DEHUMIDIFY_STRONG: 80,  # high
    _DEHUMIDIFY_RECOMMENDED: 102,  # auto
}

# Upper bounds used to fold a requested fan speed into one of those sub-modes:
# silent and low become weak, medium becomes recommended (and reads back as
# auto), high and full become strong.
_FAN_LOW_MAX = 40
_FAN_MEDIUM_MAX = 60
_FAN_FULL_MAX = 100


def _dry_fan_to_dehumidify(speed: int) -> int:
    """Fold a requested fan speed onto the nearest dry sub-mode."""
    if speed <= _FAN_LOW_MAX:
        return _DEHUMIDIFY_WEAK
    if speed <= _FAN_MEDIUM_MAX:
        return _DEHUMIDIFY_RECOMMENDED
    if speed <= _FAN_FULL_MAX:
        return _DEHUMIDIFY_STRONG
    return _DEHUMIDIFY_RECOMMENDED


_MIN_TARGET_TEMPERATURE = 16.0
_MAX_TARGET_TEMPERATURE = 32.0

# 0x0017 is a 0-100 backlight brightness, but consumers drive it as a plain
# on/off switch, so map the two switch states onto the extremes.
_SCREEN_DISPLAY_ON = 100

# Upper bound the firmware accepts for a deflector angle.
_MAX_WIND_ANGLE = 100


class DeviceAttributes(StrEnum):
    """Midea x0008ac device attributes."""

    power = "power"
    mode = "mode"
    target_temperature = "target_temperature"
    min_temperature = "min_temperature"
    max_temperature = "max_temperature"
    fan_speed = "fan_speed"
    swing_vertical = "swing_vertical"
    swing_horizontal = "swing_horizontal"
    wind_ud_angle = "wind_ud_angle"
    wind_lr_angle = "wind_lr_angle"
    indoor_temperature = "indoor_temperature"
    outdoor_temperature = "outdoor_temperature"
    indoor_humidity = "indoor_humidity"
    eco_mode = "eco_mode"
    anion = "anion"
    dry = "dry"
    dehumidify = "dehumidify"
    energy_save = "energy_save"
    comfort_mode = "comfort_mode"
    screen_display = "screen_display"
    breezeless = "breezeless"
    breezeless_direction = "breezeless_direction"
    self_clean = "self_clean"
    clean_manual = "clean_manual"
    cleaning = "cleaning"
    full_dust = "full_dust"
    error_code = "error_code"
    prompt_tone = "prompt_tone"


# Deflector positions of property 0x000A. The protocol accepts any value in
# 0-100, but the device only ever reports these steps, so they are named the
# same way as the generic AC device names its wind angles.
# 0xF0 is what the device reports when it is placing the deflector itself
# (auto mode); it is read-only here until a write of it is device-tested.
_WIND_ANGLE_AUTO = 0xF0


# Attributes whose value is a plain 0/1 flag, keyed by property ID.
_BOOL_PROPS: dict[str, int] = {
    DeviceAttributes.power: _PROP_POWER,
    DeviceAttributes.eco_mode: _PROP_ECO,
    DeviceAttributes.anion: _PROP_PURIFIER,
    DeviceAttributes.energy_save: _PROP_ENERGY_SAVE,
    DeviceAttributes.comfort_mode: _PROP_COMFORT_AIRFLOW,
}

# Attributes written as a single raw byte, keyed by property ID.
# `mode` is deliberately absent: it needs the power flag alongside it, so it is
# written by _set_mode instead.
_BYTE_PROPS: dict[str, int] = {
    DeviceAttributes.fan_speed: _PROP_FAN_SPEED,
    DeviceAttributes.swing_vertical: _PROP_SWING_UD,
    DeviceAttributes.swing_horizontal: _PROP_SWING_LR,
    DeviceAttributes.dehumidify: _PROP_DEHUMIDIFY,
    DeviceAttributes.breezeless: _PROP_BREEZELESS,
}

# Read-only attributes: silently ignored rather than warned about, so a
# consumer that writes every attribute back does not spam the log.
_READ_ONLY_ATTRIBUTES = (
    DeviceAttributes.indoor_temperature,
    DeviceAttributes.outdoor_temperature,
    DeviceAttributes.indoor_humidity,
    DeviceAttributes.min_temperature,
    DeviceAttributes.max_temperature,
    DeviceAttributes.full_dust,
    DeviceAttributes.error_code,
    DeviceAttributes.cleaning,
)


def _angle_to_raw(angles: dict[int, str], value: bool | float | str) -> int | None:
    """Resolve a deflector position name (or a raw 0-100 value) to its byte."""
    for raw, name in angles.items():
        if name == value:
            return raw
    try:
        raw_value = int(float(value))
    except (TypeError, ValueError):
        return None
    return raw_value if 0 <= raw_value <= _MAX_WIND_ANGLE else None


def _encode_named(
    prop: int,
    names: dict[int, str],
    value: bool | float | str,
) -> tuple[int, bytearray] | None:
    """Encode a value given as one of a property's named options."""
    for raw, name in names.items():
        if name == value:
            return prop, bytearray([raw])
    return None


def _encode_param(attr: str, value: bool | float | str) -> tuple[int, bytearray] | None:
    """Return the (property ID, payload) for a single attribute write."""
    if attr in _BOOL_PROPS:
        return _BOOL_PROPS[attr], bytearray([1 if value else 0])
    if attr in _BYTE_PROPS:
        return _BYTE_PROPS[attr], bytearray([int(value)])
    if attr == DeviceAttributes.target_temperature:
        return _PROP_TARGET_TEMP, bytearray([round(float(value) * 2)])
    if attr == DeviceAttributes.screen_display:
        # Accept a brightness as-is; a plain switch value becomes 0 or 100.
        brightness = (
            _SCREEN_DISPLAY_ON
            if value is True
            else 0
            if value is False
            else int(float(value))
        )
        return _PROP_SCREEN_DISPLAY, bytearray([brightness])
    return None


class MideaX0008ACDevice(MideaDevice):
    """Toshiba IoLife AC device (model 00000008, type 0xAC)."""

    def __init__(
        self,
        *,
        customize: str,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Toshiba IoLife AC device."""
        super().__init__(
            device_type=DeviceType.AC,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.target_temperature: 22.0,
                DeviceAttributes.min_temperature: _MIN_TARGET_TEMPERATURE,
                DeviceAttributes.max_temperature: _MAX_TARGET_TEMPERATURE,
                DeviceAttributes.fan_speed: 0,
                DeviceAttributes.swing_vertical: 0,
                DeviceAttributes.swing_horizontal: 0,
                DeviceAttributes.wind_ud_angle: None,
                DeviceAttributes.wind_lr_angle: None,
                DeviceAttributes.indoor_temperature: None,
                DeviceAttributes.outdoor_temperature: None,
                DeviceAttributes.indoor_humidity: None,
                DeviceAttributes.eco_mode: False,
                DeviceAttributes.anion: False,
                DeviceAttributes.dry: False,
                DeviceAttributes.dehumidify: 0,
                DeviceAttributes.energy_save: False,
                DeviceAttributes.comfort_mode: False,
                DeviceAttributes.screen_display: 0,
                DeviceAttributes.breezeless: 0,
                DeviceAttributes.breezeless_direction: None,
                DeviceAttributes.self_clean: False,
                DeviceAttributes.cleaning: False,
                DeviceAttributes.clean_manual: False,
                DeviceAttributes.full_dust: False,
                DeviceAttributes.error_code: 0,
                DeviceAttributes.prompt_tone: True,
            },
            **kwargs,
        )
        # The Toshiba firmware never answers MessageQueryAppliance, so skip it
        # rather than spending a failed query on every connect. device.py would
        # otherwise disable it itself after the first timeout.
        self._appliance_query = False
        self._default_temperature_step: float = 0.5
        self._temperature_step: float = 0.5
        self.set_customize(customize)

    def build_query(self) -> list[MessageQuery]:
        """Build query message list."""
        return [MessageQuery()]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Parse incoming Toshiba IoLife frame and update attributes."""
        _LOGGER.debug("[%s] Received: %s", self.device_id, bytearray(msg).hex())
        parsed = parse_ac_response(msg)
        if parsed is None:
            _LOGGER.debug("[%s] Unrecognised frame, ignoring", self.device_id)
            return {}
        new_status = self.update_attributes_from_message(
            parsed,
            {
                # .get leaves an unlisted raw value as None -- notably 0xF0,
                # which the device reports while positioning the deflector
                # itself, and which is deliberately not a selectable option.
                DeviceAttributes.wind_ud_angle: MideaX0008ACDevice._wind_ud_angles.get,
                DeviceAttributes.wind_lr_angle: MideaX0008ACDevice._wind_lr_angles.get,
                DeviceAttributes.breezeless_direction: (
                    MideaX0008ACDevice._breezeless_directions.get
                ),
            },
        )
        self._report_dry_sub_mode_as_fan(new_status)
        _LOGGER.debug("[%s] Updated: %s", self.device_id, new_status)
        return new_status

    def _set_special_attribute(self, attr: str, value: bool | float | str) -> bool:
        """Handle attributes that need more than a single property write."""
        if attr == DeviceAttributes.prompt_tone:
            # Local-only flag: the protocol has no prompt-tone state to read
            # back, so mirror it to consumers immediately.
            self._attributes[DeviceAttributes.prompt_tone] = bool(value)
            self.update_all({DeviceAttributes.prompt_tone.value: bool(value)})
        elif attr in (DeviceAttributes.wind_ud_angle, DeviceAttributes.wind_lr_angle):
            self._set_wind_angle(attr, value)
        elif attr == DeviceAttributes.mode:
            self._set_mode(int(value))
        elif (
            attr == DeviceAttributes.fan_speed
            and self._attributes[DeviceAttributes.mode] == _MODE_DRY
        ):
            # The fan speed is not settable in dry mode; steer the sub-mode instead.
            self.set_attribute(
                DeviceAttributes.dehumidify,
                _dry_fan_to_dehumidify(int(value)),
            )
        elif attr in (DeviceAttributes.self_clean, DeviceAttributes.clean_manual):
            self._set_clean(attr, bool(value))
        else:
            return False
        return True

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Send a property set command for a single attribute."""
        if self._set_special_attribute(attr, value) or attr in _READ_ONLY_ATTRIBUTES:
            return
        # breezeless_direction is named from a class map, so it is encoded here
        # rather than in the module-level _encode_param.
        param = (
            _encode_named(
                _PROP_BREEZELESS_DIRECTION,
                self._breezeless_directions,
                value,
            )
            if attr == DeviceAttributes.breezeless_direction
            else _encode_param(attr, value)
        )
        if param is None:
            _LOGGER.warning(
                "[%s] set_attribute: unsupported attr %s",
                self.device_id,
                attr,
            )
            return
        cmd = MessageSet()
        if not self._attributes[DeviceAttributes.prompt_tone]:
            cmd.set_param(_PROP_BUZZER, bytearray([0]))
        cmd.set_param(*param)
        self.build_send(cmd)

    def _current_angle(self, attr: str, angles: dict[int, str]) -> int:
        """Return one axis' raw angle, for resending alongside the other."""
        for raw, name in angles.items():
            if name == self._attributes[attr]:
                return raw
        return _WIND_ANGLE_AUTO

    def _set_wind_angle(self, attr: str, value: bool | float | str) -> None:
        """Write property 0x0A, which carries both deflector axes at once."""
        vertical = attr == DeviceAttributes.wind_ud_angle
        angles = self._wind_ud_angles if vertical else self._wind_lr_angles
        angle = _angle_to_raw(angles, value)
        if angle is None:
            _LOGGER.warning(
                "[%s] set_attribute: bad %s value %s",
                self.device_id,
                attr,
                value,
            )
            return
        # The firmware ignores the whole property unless both axes carry a real
        # value, so resend the other axis at its current position.
        other = (
            self._current_angle(
                DeviceAttributes.wind_lr_angle,
                self._wind_lr_angles,
            )
            if vertical
            else self._current_angle(
                DeviceAttributes.wind_ud_angle,
                self._wind_ud_angles,
            )
        )
        payload = bytearray([angle, other] if vertical else [other, angle])
        cmd = MessageSet()
        if not self._attributes[DeviceAttributes.prompt_tone]:
            cmd.set_param(_PROP_BUZZER, bytearray([0]))
        cmd.set_param(_PROP_DEFLECTOR_ANGLE, payload)
        self.build_send(cmd)

    def _report_dry_sub_mode_as_fan(self, new_status: dict[str, Any]) -> None:
        """In dry mode, report the dehumidify sub-mode as the fan speed.

        Clothes-drying has no fan equivalent, so it is left showing whatever the
        unit reports.
        """
        if self._attributes[DeviceAttributes.mode] != _MODE_DRY:
            return
        speed = _DRY_FAN_SPEEDS.get(self._attributes[DeviceAttributes.dehumidify])
        if speed is None:
            return
        self._attributes[DeviceAttributes.fan_speed] = speed
        new_status[str(DeviceAttributes.fan_speed)] = speed

    def _set_mode(self, mode: int) -> None:
        """Switch operating mode, powering the unit on as consumers expect.

        Writing the mode property on its own leaves a powered-off unit off, so
        selecting an hvac mode in Home Assistant would appear to do nothing: the
        mode lands, the unit stays off, and the card falls back to showing "off".
        Every hvac mode other than off means "run in this mode", so send the power
        flag with it.
        """
        cmd = MessageSet()
        if not self._attributes[DeviceAttributes.prompt_tone]:
            cmd.set_param(_PROP_BUZZER, bytearray([0]))
        cmd.set_param(_PROP_POWER, bytearray([1]))
        cmd.set_param(_PROP_MODE, bytearray([mode]))
        if mode == _MODE_DRY and self._attributes[DeviceAttributes.mode] != _MODE_DRY:
            # Only on the way *into* dry, so a sub-mode chosen while already in dry
            # is left alone.
            cmd.set_param(_PROP_DEHUMIDIFY, bytearray([_DEFAULT_DEHUMIDIFY]))
        self.build_send(cmd)

    def _set_clean(self, attr: str, value: bool) -> None:
        """Write property 0x46, which carries both clean flags in one payload."""
        attrs = self._attributes
        flags = {
            DeviceAttributes.clean_manual: bool(attrs[DeviceAttributes.clean_manual]),
            DeviceAttributes.self_clean: bool(attrs[DeviceAttributes.self_clean]),
        }
        flags[attr] = value  # type: ignore[index]
        cmd = MessageSet()
        if not attrs[DeviceAttributes.prompt_tone]:
            cmd.set_param(_PROP_BUZZER, bytearray([0]))
        cmd.set_param(
            _PROP_CLEAN,
            bytearray(
                [
                    int(flags[DeviceAttributes.clean_manual]),
                    int(flags[DeviceAttributes.self_clean]),
                ],
            ),
        )
        self.build_send(cmd)
        # The device offers no readback: 0x46 reads [0x00, 0xFF] in every state,
        # and the C0 status bit reports only a cycle in progress (`cleaning`).
        # Mirror the write so the switch does not spring back to off.
        attrs[attr] = value
        self.update_all({str(attr): value})

    # Deflector positions of property 0x000A. The protocol accepts any value in
    # 0-100, but the device only reports these steps, named as the generic AC
    # device names them.
    _wind_ud_angles: ClassVar[dict[int, str]] = {
        0: "off",
        1: "up",
        25: "up_mid",
        50: "middle",
        75: "down_mid",
        100: "down",
    }

    _wind_lr_angles: ClassVar[dict[int, str]] = {
        0: "off",
        1: "left",
        25: "left_mid",
        50: "middle",
        75: "right_mid",
        100: "right",
    }

    # Deflection directions of the breezeless airflow, property 0x0070. The
    # on/off at 0x18 clamps to 1 on this model; the direction lives here.
    _breezeless_directions: ClassVar[dict[int, str]] = {
        0: "off",
        1: "full",
        2: "left",
        3: "right",
    }

    @property
    def wind_ud_angles(self) -> list[str]:
        """Selectable vertical deflector positions."""
        return list(MideaX0008ACDevice._wind_ud_angles.values())

    @property
    def wind_lr_angles(self) -> list[str]:
        """Selectable horizontal deflector positions."""
        return list(MideaX0008ACDevice._wind_lr_angles.values())

    @property
    def breezeless_directions(self) -> list[str]:
        """Selectable breezeless deflection directions."""
        return list(MideaX0008ACDevice._breezeless_directions.values())

    @property
    def capabilities(self) -> dict[str, bool]:
        """Report decoded capability flags, as the generic AC device does.

        The IoLife protocol has no capability query -- there is no B5 equivalent
        -- so nothing is known and this stays empty. Consumers read it with a
        permissive default (``capabilities.get("cool_mode", True)``), so an empty
        mapping means "assume the device supports it", which is correct here:
        every mode in the protocol's own enum works. Reporting flags explicitly
        would be worse, because a consumer that reads a flag we do not set
        without a default would then treat a working feature as unsupported.
        """
        return {}

    @property
    def temperature_step(self) -> float | None:
        """Target temperature step: half-degree, per the 0x0003 property encoding."""
        return self._temperature_step

    def set_customize(self, customize: str) -> None:
        """Apply the customize options this device understands."""
        self._temperature_step = self._default_temperature_step
        if not customize:
            return
        try:
            params = json.loads(customize)
        except ValueError:
            _LOGGER.exception("[%s] Set customize error", self.device_id)
            return
        if isinstance(params, dict) and "temperature_step" in params:
            self._temperature_step = float(params["temperature_step"])
        self.update_all({"temperature_step": self._temperature_step})

    def set_target_temperature(
        self,
        target_temperature: float,
        mode: int | None,
        zone: int | None = None,  # noqa: ARG002
    ) -> None:
        """Set target temperature, and power+mode together if mode is given."""
        cmd = MessageSet()
        if not self._attributes[DeviceAttributes.prompt_tone]:
            cmd.set_param(_PROP_BUZZER, bytearray([0]))
        cmd.set_param(_PROP_TARGET_TEMP, bytearray([round(target_temperature * 2)]))
        if mode is not None:
            cmd.set_param(_PROP_POWER, bytearray([1]))
            cmd.set_param(_PROP_MODE, bytearray([mode]))
        self.build_send(cmd)

    def set_swing(self, swing_vertical: bool, swing_horizontal: bool) -> None:
        """Set vertical and horizontal swing together."""
        cmd = MessageSet()
        if not self._attributes[DeviceAttributes.prompt_tone]:
            cmd.set_param(_PROP_BUZZER, bytearray([0]))
        cmd.set_param(_PROP_SWING_UD, bytearray([1 if swing_vertical else 0]))
        cmd.set_param(_PROP_SWING_LR, bytearray([1 if swing_horizontal else 0]))
        self.build_send(cmd)


class MideaAppliance(MideaX0008ACDevice):
    """Midea x0008ac appliance."""
