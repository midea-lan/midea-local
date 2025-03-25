"""Midea local E6 device."""

import json
import logging
from enum import StrEnum
from typing import Any, ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import MessageE6Response, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea E6 device attributes."""

    main_power = "main_power"
    heating_power = "heating_power"
    heating_working = "heating_working"
    bathing_working = "bathing_working"
    min_temperature = "temperature_min"
    max_temperature = "temperature_max"
    heating_temperature = "heating_temperature"
    bathing_temperature = "bathing_temperature"
    heating_leaving_temperature = "heating_leaving_temperature"
    bathing_leaving_temperature = "bathing_leaving_temperature"
    cold_water_single = "cold_water_single"
    cold_water_dot = "cold_water_dot"
    heating_modes = "heating_modes"


class MideaE6Device(MideaDevice):
    """Midea E6 device."""

    _heating_modes: ClassVar[list[str]] = [
        "normal_mode",
        "out_mode",
        "home_mode",
        "sleep_mode",
    ]

    def __init__(
        self,
        name: str,
        device_id: int,
        ip_address: str,
        port: int,
        token: str,
        key: str,
        device_protocol: ProtocolVersion,
        model: str,
        subtype: int,
        customize: str,
    ) -> None:
        """Initialize Midea E6 device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.E6,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.main_power: False,
                DeviceAttributes.heating_power: True,
                DeviceAttributes.heating_working: None,
                DeviceAttributes.bathing_working: None,
                DeviceAttributes.min_temperature: [30.0, 35.0],
                DeviceAttributes.max_temperature: [80.0, 60.0],
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
        self._temperature_step: float | None = None
        self._default_temperature_step = 1
        self.set_customize(customize)

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
        new_status = {}
        for status in self._attributes:
            if hasattr(message, str(status)):
                self._attributes[status] = getattr(message, str(status))
                new_status[str(status)] = self._attributes[status]
        return new_status

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
    def heating_modes(self) -> list[str]:
        """Return available heating modes."""
        return self._heating_modes

    def set_customize(self, customize: str) -> None:
        """Midea E2 device set customize."""
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "temperature_step" in params:
                    self._temperature_step = params.get("temperature_step")
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
            self.update_all(
                {
                    "temperature_step": self._temperature_step,
                },
            )


class MideaAppliance(MideaE6Device):
    """Midea E6 appliance."""
