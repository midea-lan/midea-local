"""Midea local C1 device."""

import json
import logging
from enum import StrEnum
from typing import Any, Unpack

from midealan.const import DeviceType
from midealan.device import MideaDevice, MideaDeviceInitKwargs
from midealan.exceptions import ValueWrongType

from .message import (
    C1_HEATING_MODE_NAMES,
    HEATING_MODE_USER,
    MessageC1Response,
    MessagePower,
    MessageQuery,
    MessageSetHeating,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea C1 device attributes."""

    power = "power"
    standby = "standby"
    heating = "heating"
    warm_power = "warm_power"
    cold_power = "cold_power"
    sleep_power = "sleep_power"
    fault = "fault"
    error_code = "error_code"
    return_temperature = "return_temperature"
    current_temperature = "current_temperature"
    heating_temperature = "heating_temperature"
    heating_target_temperature = "heating_target_temperature"
    heating_gap_temperature = "heating_gap_temperature"
    heating_mode = "heating_mode"
    user_mode_target_temperature = "user_mode_target_temperature"
    activity_mode_target_temperature = "activity_mode_target_temperature"
    sleep_mode_target_temperature = "sleep_mode_target_temperature"
    last_time = "last_time"
    flow_volume = "flow_volume"
    pump_on = "pump_on"
    three_way_mode = "three_way_mode"
    heating_unit_type = "heating_unit_type"
    status = "status"


class MideaC1Device(MideaDevice):
    """Midea C1 device."""

    def __init__(
        self,
        *,
        customize: str,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea C1 device."""
        super().__init__(
            device_type=DeviceType.C1,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.standby: False,
                DeviceAttributes.heating: False,
                DeviceAttributes.warm_power: False,
                DeviceAttributes.cold_power: False,
                DeviceAttributes.sleep_power: False,
                DeviceAttributes.fault: False,
                DeviceAttributes.error_code: "normal",
                DeviceAttributes.return_temperature: None,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.heating_temperature: None,
                DeviceAttributes.heating_target_temperature: None,
                DeviceAttributes.heating_gap_temperature: None,
                DeviceAttributes.heating_mode: "unknown",
                DeviceAttributes.user_mode_target_temperature: None,
                DeviceAttributes.activity_mode_target_temperature: None,
                DeviceAttributes.sleep_mode_target_temperature: None,
                DeviceAttributes.last_time: 0,
                DeviceAttributes.flow_volume: 0,
                DeviceAttributes.pump_on: False,
                DeviceAttributes.three_way_mode: "heating",
                DeviceAttributes.heating_unit_type: "floor_heating",
                DeviceAttributes.status: "off",
            },
        )
        self._default_temperature_step: float = 1.0
        self._temperature_step: float = self._default_temperature_step
        self.set_customize(customize)

    @property
    def temperature_step(self) -> float | None:
        """Midea C1 device temperature step (for UI / customize)."""
        return self._temperature_step

    @property
    def heating_modes(self) -> list[str]:
        """Midea C1 space-heating mode names (Lua mode codes 1-3)."""
        return list(C1_HEATING_MODE_NAMES.values())

    def build_query(self) -> list[MessageQuery]:
        """Midea C1 device build query."""
        return [MessageQuery(self._message_protocol_version)]

    @staticmethod
    def _derive_status(power: bool, heating: bool, fault: bool) -> str:
        """Map power/heating/fault bits to a single status string."""
        if fault:
            return "fault"
        if not power:
            return "off"
        if heating:
            return "running"
        return "idle"

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea C1 device process message."""
        message = MessageC1Response(msg)
        self._message_protocol_version = message.protocol_version
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status: dict[str, Any] = {}
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                self._attributes[status] = value
                new_status[str(status)] = value
        status = self._derive_status(
            bool(self._attributes[DeviceAttributes.power]),
            bool(self._attributes[DeviceAttributes.heating]),
            bool(self._attributes[DeviceAttributes.fault]),
        )
        self._attributes[DeviceAttributes.status] = status
        new_status[str(DeviceAttributes.status)] = status
        return new_status

    @staticmethod
    def _heating_mode_code(mode_name: str) -> int:
        for code, name in C1_HEATING_MODE_NAMES.items():
            if name == mode_name:
                return code
        return HEATING_MODE_USER

    def set_heating_target_temperature(
        self,
        target_temperature: float,
        heating_mode: int | None = None,
    ) -> None:
        """Set space-heating target; Lua segment 0x14 / 0x04."""
        message = MessageSetHeating(self._message_protocol_version)
        mode_code = (
            heating_mode
            if heating_mode is not None
            else self._heating_mode_code(
                str(self._attributes[DeviceAttributes.heating_mode]),
            )
        )
        message.heating_mode = mode_code
        message.target_temperature = target_temperature
        message.last_time = 0
        gap = self._attributes[DeviceAttributes.heating_gap_temperature]
        if isinstance(gap, int | float):
            message.gap_temperature = int(gap)
        else:
            message.gap_temperature = 0
        self.build_send(message)

    def set_attribute(self, attr: str, value: bool | str | float) -> None:
        """Midea C1 device set attribute."""
        if attr == DeviceAttributes.power:
            if not isinstance(value, bool):
                raise ValueWrongType("[c1] Expected bool")
            message = MessagePower(self._message_protocol_version)
            message.power = value
            self.build_send(message)
        elif attr == DeviceAttributes.heating_target_temperature and isinstance(
            value,
            int | float,
        ):
            self.set_heating_target_temperature(float(value))
        elif attr == DeviceAttributes.heating_mode and isinstance(value, str):
            target = self._attributes.get(DeviceAttributes.heating_target_temperature)
            if isinstance(target, int | float):
                self.set_heating_target_temperature(
                    float(target),
                    heating_mode=self._heating_mode_code(value),
                )

    def set_customize(self, customize: str) -> None:
        """Midea C1 device set customize (JSON, same style as other appliances)."""
        self._temperature_step = self._default_temperature_step
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "temperature_step" in params:
                    step = params.get("temperature_step")
                    if (
                        isinstance(step, int | float)
                        and not isinstance(step, bool)
                        and float(step) == self._default_temperature_step
                    ):
                        self._temperature_step = float(step)
                    else:
                        _LOGGER.error(
                            "[%s] Unsupported temperature_step for C1: %s",
                            self.device_id,
                            step,
                        )
                if params and "refresh_interval" in params:
                    interval = params.get("refresh_interval")
                    if isinstance(interval, int | float):
                        self.set_refresh_interval(int(interval))
                    else:
                        _LOGGER.error(
                            "[%s] Invalid type for refresh_interval: %s",
                            self.device_id,
                            interval,
                        )
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
        self.update_all(
            {
                "temperature_step": self._temperature_step,
                "refresh_interval": self._refresh_interval,
            },
        )


class MideaAppliance(MideaC1Device):
    """Midea C1 appliance."""
