"""Midea local E6 device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from typing_extensions import deprecated

from midealocal.const import DeviceType
from midealocal.const.water_heater_exceptions import E6_EXCEPTIONS
from midealocal.device import MideaDevice, MideaDeviceInitKwargs

from .message import MessageE6Response, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea E6 device attributes."""

    main_power = "main_power"
    heating_power = "heating_power"
    heating_working = "heating_working"
    bathing_working = "bathing_working"
    temperature_min = "temperature_min"
    temperature_max = "temperature_max"
    heating_temperature = "heating_temperature"
    bathing_temperature = "bathing_temperature"
    heating_leaving_temperature = "heating_leaving_temperature"
    bathing_leaving_temperature = "bathing_leaving_temperature"
    cold_water_single = "cold_water_single"
    cold_water_dot = "cold_water_dot"
    heating_modes = "heating_modes"


class MideaE6Device(MideaDevice):
    """Midea E6 device."""

    _preset_modes: ClassVar[list[str]] = [
        "normal",
        "out",
        "home",
        "sleep",
    ]

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea E6 device."""
        super().__init__(
            device_type=DeviceType.E6,
            **kwargs,
            attributes={
                DeviceAttributes.main_power: False,
                DeviceAttributes.heating_power: True,
                DeviceAttributes.heating_working: None,
                DeviceAttributes.bathing_working: None,
                DeviceAttributes.temperature_min: [30.0, 35.0],
                DeviceAttributes.temperature_max: [80.0, 60.0],
                DeviceAttributes.heating_temperature: 50.0,
                DeviceAttributes.bathing_temperature: 40.0,
                DeviceAttributes.heating_leaving_temperature: None,
                DeviceAttributes.bathing_leaving_temperature: None,
                DeviceAttributes.cold_water_single: None,
                DeviceAttributes.cold_water_dot: None,
                DeviceAttributes.heating_modes: None,
            },
        )
        # target_temperature step
        self._temperature_step: float | None = E6_EXCEPTIONS.get(
            str(self.model),
            {},
        ).get("temperature_step")

    @property
    def temperature_step(self) -> float | None:
        """Midea E6 device temperature step."""
        return self._temperature_step

    def build_query(self) -> list[MessageQuery]:
        """Midea E6 device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea E6 device process message."""
        message = MessageE6Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(message)

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea E6 device set attribute."""
        if attr in [
            DeviceAttributes.main_power,
            DeviceAttributes.heating_power,
            DeviceAttributes.heating_temperature,
            DeviceAttributes.bathing_temperature,
            DeviceAttributes.heating_modes,
            DeviceAttributes.cold_water_single,
            DeviceAttributes.cold_water_dot,
        ]:
            message = MessageSet(self._message_protocol_version)
            setattr(message, str(attr), value)
            self.build_send(message)

    @property
    @deprecated("Use preset_modes instead.")
    def heating_modes(self) -> list[str]:
        """Return available heating modes."""
        return self.preset_modes

    @property
    def preset_modes(self) -> list[str]:
        """Midea E6 preset modes."""
        return self._preset_modes


class MideaAppliance(MideaE6Device):
    """Midea E6 appliance."""
