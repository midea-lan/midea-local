"""Midea local CF device."""

import logging
import math
from enum import StrEnum
from typing import Any, ClassVar, Unpack, override

from midealocal.base_classes import MideaClimateDevice, MideaHVACMode
from midealocal.const import DeviceType
from midealocal.device import MideaDeviceInitKwargs
from midealocal.exceptions import ValueWrongType

from .message import MessageCFResponse, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea CF device attributes."""

    power = "power"
    mode = "mode"
    target_temperature = "target_temperature"
    aux_heating = "aux_heating"
    current_temperature = "current_temperature"
    max_temperature = "max_temperature"
    min_temperature = "min_temperature"
    defrost = "defrost"
    freeze = "freeze"


class DeviceHVACMode(MideaHVACMode):
    """Midea CF device HVAC mode."""

    OFF = 0
    AUTO = 1
    COOL = 2
    HEAT = 3


class MideaCFDevice(MideaClimateDevice):
    """Midea CF device."""

    # Generic HVAC mode names, ordered to match the protocol's mode index.
    _device_hvac_modes: ClassVar[set[MideaHVACMode]] = {
        DeviceHVACMode.OFF,
        DeviceHVACMode.AUTO,
        DeviceHVACMode.COOL,
        DeviceHVACMode.HEAT,
    }

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea CF device."""
        super().__init__(
            device_type=DeviceType.CF,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.defrost: False,
                DeviceAttributes.freeze: False,
                DeviceAttributes.target_temperature: None,
                DeviceAttributes.aux_heating: False,
                DeviceAttributes.current_temperature: 0,
                DeviceAttributes.max_temperature: 55,
                DeviceAttributes.min_temperature: 5,
            },
        )

    @property
    @override
    def device_hvac_modes(self) -> set[MideaHVACMode]:
        """Midea CF device HVAC modes."""
        return MideaCFDevice._device_hvac_modes

    @override
    def device_hvac_mode(self, zone: int | None = None) -> MideaHVACMode | None:
        """Midea CF device HVAC mode."""
        power = self._attributes[DeviceAttributes.power]
        if not isinstance(power, bool):
            return None
        if not power:
            return DeviceHVACMode.OFF
        mode = self._attributes[DeviceAttributes.mode]
        try:
            return (
                DeviceHVACMode(mode)
                if DeviceHVACMode(mode) != DeviceHVACMode.OFF
                else None
            )
        except ValueError:
            return None

    @override
    def set_device_hvac_mode(
        self,
        hvac_mode: MideaHVACMode,
        zone: int | None = None,
    ) -> None:
        """Midea CF device set HVAC mode.

        Every mode-change message must carry a target_temperature, so this
        supplies the current one (or the device's minimum as a fallback)
        rather than sending mode alone via set_attribute.
        """
        if hvac_mode == DeviceHVACMode.OFF:
            self.set_attribute(attr=DeviceAttributes.power, value=False)
            return
        if hvac_mode not in self.device_hvac_modes:
            msg = f"[cf] Unsupported hvac mode: {hvac_mode}"
            raise ValueError(msg)
        target_temperature = self._attributes[DeviceAttributes.target_temperature]
        if target_temperature is None:
            target_temperature = self._attributes[DeviceAttributes.min_temperature]
        self.set_device_target_temperature(
            target_temperature=target_temperature,
            hvac_mode=hvac_mode,
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea CF device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea CF device process message."""
        message = MessageCFResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(message)

    @override
    def set_device_target_temperature(
        self,
        target_temperature: float,
        hvac_mode: MideaHVACMode | None,
        zone: int | None = None,
    ) -> None:
        """Midea CF device set target temperature."""
        message = MessageSet(self._message_protocol_version)
        message.power = True
        message.mode = self._attributes[DeviceAttributes.mode]
        message.target_temperature = target_temperature
        if hvac_mode is not None:
            message.mode = hvac_mode
        self.build_send(message)

    @staticmethod
    def _parse_float(value: bool | float | str, expected: str) -> float:
        if isinstance(value, bool):
            raise ValueWrongType(f"[cf] Expected {expected}")
        try:
            number = float(value)
        except (TypeError, ValueError) as err:
            raise ValueWrongType(f"[cf] Expected {expected}") from err
        if not math.isfinite(number):
            raise ValueWrongType(f"[cf] Expected {expected}")
        return number

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea CF device set attribute."""
        message = MessageSet(self._message_protocol_version)
        message.power = True
        message.mode = self._attributes[DeviceAttributes.mode]
        if attr in (DeviceAttributes.power, DeviceAttributes.aux_heating):
            if not isinstance(value, bool):
                raise ValueWrongType("[cf] Expected bool")
            setattr(message, attr, value)
        elif attr == DeviceAttributes.mode:
            mode_value = self._parse_float(value, "int")
            if not mode_value.is_integer():
                raise ValueWrongType("[cf] Expected int")
            message.mode = int(mode_value)
        elif attr == DeviceAttributes.target_temperature:
            message.target_temperature = self._parse_float(value, "float")
        else:
            raise ValueError(f"[cf] Unsupported attribute: {attr}")
        self.build_send(message)


class MideaAppliance(MideaCFDevice):
    """Midea CF appliance."""
