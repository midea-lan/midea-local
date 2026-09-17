"""Midea local FB device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack, override

from midealocal.base_classes.climate import (
    MideaClimateDevice,
    MideaHVACMode,
    MideaPreset,
)
from midealocal.const import DeviceType
from midealocal.device import MideaDeviceInitKwargs

from .message import MessageFBResponse, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)

# FB units do not report a settable range; these are the fixed protocol bounds.
FB_MIN_TARGET_TEMPERATURE = 5.0
FB_MAX_TARGET_TEMPERATURE = 35.0


class DeviceAttributes(StrEnum):
    """Midea FB device attributes."""

    power = "power"
    mode = "mode"
    heating_level = "heating_level"
    target_temperature = "target_temperature"
    current_temperature = "current_temperature"
    target_humidity = "target_humidity"
    current_humidity = "current_humidity"
    humidity_mode = "humidity_mode"
    child_lock = "child_lock"


class DeviceHumidityMode(StrEnum):
    """Midea FB device humidity mode."""

    CLOSE = "close"
    CONST = "const"
    ONE = "one"
    TWO = "two"
    THREE = "three"


class DeviceHVACMode(MideaHVACMode):
    """Midea FB device HVAC mode."""

    OFF = 0
    HEAT = 1


class MideaFBDevice(MideaClimateDevice):
    """Midea FB device."""

    # Generic HVAC mode names; FB only distinguishes power on/off.
    _device_hvac_modes: ClassVar[list[DeviceHVACMode]] = [
        DeviceHVACMode.OFF,
        DeviceHVACMode.HEAT,
    ]

    _modes: ClassVar[dict[int, MideaPreset]] = {
        0x01: MideaPreset.AUTO,
        0x02: MideaPreset.ECO,
        0x03: MideaPreset.SLEEP,
        0x04: MideaPreset.ANTI_FREEZING,
        0x05: MideaPreset.COMFORT,
        0x06: MideaPreset.CONSTANT_TEMPERATURE,
        0x07: MideaPreset.NORMAL,
        0x08: MideaPreset.FAST_HEATING,
        0x10: MideaPreset.STANDBY,
    }

    _humidity_modes: ClassVar[dict[int, DeviceHumidityMode]] = {
        0x10: DeviceHumidityMode.CLOSE,
        0x20: DeviceHumidityMode.CONST,
        0x30: DeviceHumidityMode.ONE,
        0x40: DeviceHumidityMode.TWO,
        0x50: DeviceHumidityMode.THREE,
    }

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea FB device."""
        super().__init__(
            device_type=DeviceType.FB,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.mode: None,
                DeviceAttributes.heating_level: 0,
                DeviceAttributes.target_temperature: None,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.target_humidity: None,
                DeviceAttributes.current_humidity: None,
                DeviceAttributes.child_lock: False,
            },
        )

    @property
    @override
    def hvac_modes(self) -> set[MideaHVACMode]:
        """Midea FB device HVAC modes."""
        return set(MideaFBDevice._device_hvac_modes)

    @override
    def hvac_mode(self, zone: int | None = None) -> MideaHVACMode | None:
        """Midea FB device HVAC mode."""
        power = self._attributes[DeviceAttributes.power]
        if not isinstance(power, bool):
            return None
        return DeviceHVACMode.HEAT if power else DeviceHVACMode.OFF

    @override
    def set_hvac_mode(
        self,
        hvac_mode: MideaHVACMode,
        zone: int | None = None,
    ) -> None:
        """Midea FB device set HVAC mode."""
        if hvac_mode not in self.hvac_modes:
            msg = f"[fb] Unsupported hvac mode: {hvac_mode}"
            raise ValueError(msg)
        self.set_attribute(
            attr=DeviceAttributes.power,
            value=hvac_mode != DeviceHVACMode.OFF,
        )

    @property
    def modes(self) -> list[MideaPreset]:
        """Midea FB device modes."""
        return list(MideaFBDevice._modes.values())

    @override
    def min_temperature(self, zone: int | None = None) -> float:
        """Midea FB device minimum target temperature."""
        return FB_MIN_TARGET_TEMPERATURE

    @override
    def max_temperature(self, zone: int | None = None) -> float:
        """Midea FB device maximum target temperature."""
        return FB_MAX_TARGET_TEMPERATURE

    @property
    @override
    def preset_modes(self) -> list[MideaPreset]:
        """Midea FB device preset modes (its named heating modes)."""
        return self.modes

    @property
    @override
    def preset_mode(self) -> MideaPreset | None:
        """Midea FB device current preset mode."""
        mode = self._attributes[DeviceAttributes.mode]
        return mode if isinstance(mode, MideaPreset) else None

    @override
    def set_preset_mode(self, preset_mode: str) -> None:
        """Midea FB device set preset mode."""
        if preset_mode not in self.preset_modes:
            msg = f"[fb] Unsupported preset mode: {preset_mode}"
            raise ValueError(msg)
        self.set_attribute(attr=DeviceAttributes.mode, value=preset_mode)

    @override
    def target_temperature(self, zone: int | None = None) -> float | None:
        """Midea FB device target temperature."""
        value = self._attributes.get(DeviceAttributes.target_temperature, None)
        if not isinstance(value, (int, float)):
            return None
        return float(value)

    @override
    def current_temperature(self) -> float | None:
        """Midea FB device current temperature."""
        value = self._attributes.get(DeviceAttributes.current_temperature, None)
        if not isinstance(value, (int, float)):
            return None
        return float(value)

    @override
    def current_humidity(self) -> float | None:
        """Midea FB device current humidity."""
        value = self._attributes.get(DeviceAttributes.current_humidity, None)
        if not isinstance(value, (int, float)):
            return None
        return float(value)

    @override
    def turn_on(self, zone: int | None = None) -> None:
        """Midea FB device turn on."""
        self.set_attribute(attr=DeviceAttributes.power, value=True)

    @override
    def turn_off(self, zone: int | None = None) -> None:
        """Midea FB device turn off."""
        self.set_attribute(attr=DeviceAttributes.power, value=False)

    def build_query(self) -> list[MessageQuery]:
        """Midea FB device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea FB device process message."""
        message = MessageFBResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            {DeviceAttributes.mode: MideaFBDevice._modes.get},
        )

    def _build_set_message(self) -> MessageSet:
        """Midea FB device build set message."""
        message = MessageSet(self._message_protocol_version, self.subtype)
        for attr in [
            DeviceAttributes.power,
            DeviceAttributes.mode,
            DeviceAttributes.heating_level,
            DeviceAttributes.target_temperature,
            DeviceAttributes.target_humidity,
            DeviceAttributes.humidity_mode,
            DeviceAttributes.child_lock,
        ]:
            value = self._attributes.get(attr, None)
            if value is not None:
                setattr(message, str(attr), value)
        return message

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea FB device set attribute."""
        message = self._build_set_message()
        if attr == DeviceAttributes.mode:
            if value not in MideaFBDevice._modes.values():
                msg = f"[fb] Unsupported mode: {value}"
                raise ValueError(msg)
            if value in MideaFBDevice._modes.values():
                message.mode = list(MideaFBDevice._modes.keys())[
                    list(MideaFBDevice._modes.values()).index(MideaPreset(str(value)))
                ]
        elif attr == DeviceAttributes.humidity_mode:
            if value not in MideaFBDevice._humidity_modes.values():
                msg = f"[fb] Unsupported humidity mode: {value}"
                raise ValueError(msg)

            if value in MideaFBDevice._humidity_modes.values():
                message.humidity_mode = list(MideaFBDevice._humidity_modes.keys())[
                    list(MideaFBDevice._humidity_modes.values()).index(
                        DeviceHumidityMode(str(value)),
                    )
                ]
        else:
            message = MessageSet(self._message_protocol_version, self.subtype)
            setattr(message, str(attr), value)
        self.build_send(message)

    @override
    def set_target_temperature(
        self,
        target_temperature: float,
        hvac_mode: MideaHVACMode | None,
        zone: int | None = None,
    ) -> None:
        """Midea FB device set target temperature."""
        message = MessageSet(self._message_protocol_version, self.subtype)
        setattr(message, DeviceAttributes.target_temperature, target_temperature)
        if hvac_mode is not None and hvac_mode != DeviceHVACMode.OFF:
            message.power = True
        self.build_send(message)


class MideaAppliance(MideaFBDevice):
    """Midea FB appliance."""
