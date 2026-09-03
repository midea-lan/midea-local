"""Midea local FB device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack, override

from midealocal.base_classes import MideaClimateDevice, MideaHVACMode
from midealocal.const import DeviceType
from midealocal.device import MideaDeviceInitKwargs

from .message import MessageFBResponse, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea FB device attributes."""

    power = "power"
    mode = "mode"
    heating_level = "heating_level"
    target_temperature = "target_temperature"
    current_temperature = "current_temperature"
    child_lock = "child_lock"


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

    _modes: ClassVar[dict[int, str]] = {
        0x01: "auto",
        0x02: "eco",
        0x03: "sleep",
        0x04: "anti_freezing",
        0x05: "comfort",
        0x06: "constant_temperature",
        0x07: "normal",
        0x08: "fast_heating",
        0x10: "standby",
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
                DeviceAttributes.child_lock: False,
            },
        )

    @property
    @override
    def device_hvac_modes(self) -> set[MideaHVACMode]:
        """Midea FB device HVAC modes."""
        return set(MideaFBDevice._device_hvac_modes)

    @override
    def device_hvac_mode(self, zone: int | None = None) -> MideaHVACMode | None:
        """Midea FB device HVAC mode."""
        power = self._attributes[DeviceAttributes.power]
        if not isinstance(power, bool):
            return None
        return DeviceHVACMode.HEAT if power else DeviceHVACMode.OFF

    @override
    def set_device_hvac_mode(
        self,
        hvac_mode: MideaHVACMode,
        zone: int | None = None,
    ) -> None:
        """Midea FB device set HVAC mode."""
        if hvac_mode not in self.device_hvac_modes:
            msg = f"[fb] Unsupported hvac mode: {hvac_mode}"
            raise ValueError(msg)
        self.set_attribute(
            attr=DeviceAttributes.power,
            value=hvac_mode != DeviceHVACMode.OFF,
        )

    @property
    def modes(self) -> list[str]:
        """Midea FB device modes."""
        return list(MideaFBDevice._modes.values())

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

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea FB device set attribute."""
        if attr == DeviceAttributes.mode:
            message = MessageSet(self._message_protocol_version, self.subtype)
            if value in MideaFBDevice._modes.values():
                message.mode = list(MideaFBDevice._modes.keys())[
                    list(MideaFBDevice._modes.values()).index(str(value))
                ]
        else:
            message = MessageSet(self._message_protocol_version, self.subtype)
            setattr(message, str(attr), value)
        self.build_send(message)

    @override
    def set_device_target_temperature(
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
