"""Midea local BF device."""

import logging
from enum import StrEnum
from typing import Any, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs

from .message import (
    MessageBFResponse,
    MessageQuery,
    MessageSet,
)

_LOGGER = logging.getLogger(__name__)

_MISSING = object()


class DeviceAttributes(StrEnum):
    """Midea BF device attributes."""

    # Basic status
    door = "door"
    status = "status"
    time_remaining = "time_remaining"
    current_temperature = "current_temperature"
    tank_ejected = "tank_ejected"
    water_change_reminder = "water_change_reminder"
    water_shortage = "water_shortage"
    # Work mode and cooking params
    work_mode = "work_mode"
    fire_power = "fire_power"
    pre_heat = "pre_heat"
    turntable = "turntable"
    hot_wind = "hot_wind"
    # Temperature settings
    temperature = "temperature"
    temperature_above = "temperature_above"
    temperature_underside = "temperature_underside"
    probe_temperature = "probe_temperature"
    # Current temperatures
    cur_temperature_above = "cur_temperature_above"
    cur_temperature_underside = "cur_temperature_underside"
    cur_probe_temperature = "cur_probe_temperature"
    # Cooking params
    steam_quantity = "steam_quantity"
    weight = "weight"
    people_number = "people_number"
    # Time settings
    hour_set = "hour_set"
    minute_set = "minute_set"
    second_set = "second_set"
    # Status flags
    child_lock = "child_lock"
    furnace_light = "furnace_light"
    flip_side = "flip_side"
    reaction = "reaction"
    high_temperature_lock = "high_temperature_lock"
    high_temperature_work = "high_temperature_work"
    high_temperature = "high_temperature"
    probe_mode = "probe_mode"
    probe = "probe"
    error_code = "error_code"
    ramadan = "ramadan"
    # Multi-stage cooking
    totalstep = "totalstep"
    stepnum = "stepnum"
    cloudmenuid = "cloudmenuid"
    # Maintenance
    clean_scale = "clean_scale"
    clean_sink_ponding = "clean_sink_ponding"
    dissipate_heat = "dissipate_heat"
    cbs_version = "cbs_version"
    ota = "ota"
    # Execute status
    execute = "execute"
    # Controls (not reported by device, for HA entity mapping)
    power = "power"
    screen_luminance = "screen_luminance"
    volume = "volume"


# Attributes that can be directly set on MessageSet (same name on device and message)
_SETTABLE_ATTRS: frozenset[DeviceAttributes] = frozenset(
    {
        DeviceAttributes.power,
        DeviceAttributes.child_lock,
        DeviceAttributes.furnace_light,
        DeviceAttributes.hot_wind,
        DeviceAttributes.door,
        DeviceAttributes.screen_luminance,
        DeviceAttributes.volume,
        DeviceAttributes.ramadan,
        DeviceAttributes.work_mode,
        DeviceAttributes.fire_power,
        DeviceAttributes.temperature,
        DeviceAttributes.temperature_above,
        DeviceAttributes.temperature_underside,
        DeviceAttributes.probe_temperature,
        DeviceAttributes.steam_quantity,
        DeviceAttributes.weight,
        DeviceAttributes.people_number,
        DeviceAttributes.turntable,
        DeviceAttributes.pre_heat,
        DeviceAttributes.hour_set,
        DeviceAttributes.minute_set,
        DeviceAttributes.second_set,
    },
)

# Work-mode-related attributes that need current work_mode context to serialize
# correctly via workModeControl instead of an empty setControl body.
_WORK_MODE_SETTABLE_ATTRS: frozenset[DeviceAttributes] = frozenset(
    {
        DeviceAttributes.work_mode,
        DeviceAttributes.fire_power,
        DeviceAttributes.temperature,
        DeviceAttributes.temperature_above,
        DeviceAttributes.temperature_underside,
        DeviceAttributes.probe_temperature,
        DeviceAttributes.steam_quantity,
        DeviceAttributes.weight,
        DeviceAttributes.people_number,
        DeviceAttributes.turntable,
        DeviceAttributes.pre_heat,
        DeviceAttributes.hot_wind,
    },
)


class MideaBFDevice(MideaDevice):
    """Midea BF device."""

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea BF device."""
        super().__init__(
            device_type=DeviceType.BF,
            **kwargs,
            attributes=dict.fromkeys(DeviceAttributes, None),
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea BF device build query."""
        return [
            MessageQuery(self._message_protocol_version)
        ]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea BF device process message."""
        message = MessageBFResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status: dict[str, Any] = {}
        for status in self._attributes:
            value = getattr(message, str(status), _MISSING)
            if value is not _MISSING:
                self._attributes[status] = value
                new_status[str(status)] = value
        return new_status

    def make_message_set(self) -> MessageSet:
        """Create a MessageSet pre-populated with current work-mode attributes.

        Ensures that adjusting a single work-mode parameter (e.g. fire_power)
        carries the active work_mode so the message routes to workModeControl
        rather than producing an empty setControl command.
        """
        message = MessageSet(self._message_protocol_version)
        message.work_mode = self._attributes[DeviceAttributes.work_mode]
        message.fire_power = self._attributes[DeviceAttributes.fire_power]
        message.temperature = self._attributes[DeviceAttributes.temperature]
        message.temperature_above = self._attributes[DeviceAttributes.temperature_above]
        message.temperature_underside = self._attributes[
            DeviceAttributes.temperature_underside
        ]
        message.probe_temperature = self._attributes[DeviceAttributes.probe_temperature]
        message.steam_quantity = self._attributes[DeviceAttributes.steam_quantity]
        message.weight = self._attributes[DeviceAttributes.weight]
        message.people_number = self._attributes[DeviceAttributes.people_number]
        message.turntable = self._attributes[DeviceAttributes.turntable]
        message.pre_heat = self._attributes[DeviceAttributes.pre_heat]
        message.hot_wind = self._attributes[DeviceAttributes.hot_wind]
        return message

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea BF device set attribute."""
        # status on device maps to work_status on message
        if attr == DeviceAttributes.status:
            if not isinstance(value, str):
                _LOGGER.warning(
                    "[%s] Invalid status value: %r (expected str)",
                    self.device_id,
                    value,
                )
                return
            message = MessageSet(self._message_protocol_version)
            message.work_status = value
            self.build_send(message)
            return

        if attr not in _SETTABLE_ATTRS:
            _LOGGER.warning("[%s] Unsupported attribute: %s", self.device_id, attr)
            return

        # Work-mode-related attributes need the current work_mode context so the
        # MessageSet routes to workModeControl instead of an empty setControl.
        if attr in _WORK_MODE_SETTABLE_ATTRS:
            message = self.make_message_set()
        else:
            message = MessageSet(self._message_protocol_version)
        setattr(message, attr, value)
        self.build_send(message)


class MideaAppliance(MideaBFDevice):
    """Midea BF appliance."""
