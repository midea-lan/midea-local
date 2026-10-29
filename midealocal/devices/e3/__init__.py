"""Midea local E3 device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.const.water_heater_exceptions import E3_EXCEPTIONS
from midealocal.device import (
    MideaDevice,
    MideaDeviceInitKwargs,
    precision_halves_translator,
)

from .message import (
    MessageE3Response,
    MessageNewProtocolSet,
    MessagePower,
    MessageQuery,
    MessageSet,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea E3 device attributes."""

    power = "power"
    burning_state = "burning_state"
    zero_cold_water = "zero_cold_water"
    protection = "protection"
    zero_cold_pulse = "zero_cold_pulse"
    smart_volume = "smart_volume"
    current_temperature = "current_temperature"
    target_temperature = "target_temperature"
    temperature_min = "temperature_min"
    temperature_max = "temperature_max"


class MideaE3Device(MideaDevice):
    """Midea E3 device."""

    _old_subtypes: ClassVar[list[int]] = [32, 33, 34, 35, 36, 37, 40, 43, 48, 49, 80]

    def __init__(
        self,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea E3 device."""
        super().__init__(
            device_type=DeviceType.E3,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.burning_state: False,
                DeviceAttributes.zero_cold_water: False,
                DeviceAttributes.protection: False,
                DeviceAttributes.zero_cold_pulse: False,
                DeviceAttributes.smart_volume: False,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.target_temperature: 40.0,
                DeviceAttributes.temperature_min: 35.0,
                DeviceAttributes.temperature_max: 65.0,
            },
        )
        exceptions = E3_EXCEPTIONS.get(str(self.model), {})
        self._precision_halves: bool = exceptions.get("precision_halves", False)
        # target_temperature step
        self._temperature_step: float = exceptions.get("temperature_step", 1.0)

    @property
    def precision_halves(self) -> bool | None:
        """Midea E3 device precision halves."""
        return self._precision_halves

    @property
    def temperature_step(self) -> float | None:
        """Midea E3 device target temperature step."""
        return self._temperature_step

    def build_query(self) -> list[MessageQuery]:
        """Midea E3 device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea E3 device process message."""
        message = MessageE3Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            dict.fromkeys(
                [
                    DeviceAttributes.current_temperature,
                    DeviceAttributes.target_temperature,
                ],
                precision_halves_translator(self._precision_halves),
            ),
        )

    def make_message_set(self) -> MessageSet:
        """Midea E3 device make message set."""
        message = MessageSet(self._message_protocol_version)
        message.zero_cold_water = self._attributes[DeviceAttributes.zero_cold_water]
        message.protection = self._attributes[DeviceAttributes.protection]
        message.zero_cold_pulse = self._attributes[DeviceAttributes.zero_cold_pulse]
        message.smart_volume = self._attributes[DeviceAttributes.smart_volume]
        message.target_temperature = self._attributes[
            DeviceAttributes.target_temperature
        ]
        return message

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea E3 device set attribute."""
        message: MessagePower | MessageSet | MessageNewProtocolSet | None = None
        if attr not in [
            DeviceAttributes.burning_state,
            DeviceAttributes.current_temperature,
            DeviceAttributes.protection,
        ]:
            if self._precision_halves and attr == DeviceAttributes.target_temperature:
                value = value * 2
            if attr == DeviceAttributes.power:
                message = MessagePower(self._message_protocol_version)
                message.power = bool(value)
            elif self.subtype in MideaE3Device._old_subtypes:
                message = self.make_message_set()
                setattr(message, str(attr), value)
            else:
                message = MessageNewProtocolSet(self._message_protocol_version)
                message.key = str(attr)
                message.value = value
            self.build_send(message)


class MideaAppliance(MideaE3Device):
    """Midea E3 appliance."""
