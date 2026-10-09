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
# hot_wind is intentionally excluded: per lua's jsonToData, a standalone
# hot_wind write must route via notWorkModeControl, not workModeControl.
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
            attributes={
                DeviceAttributes.door: False,
                DeviceAttributes.status: None,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.tank_ejected: False,
                DeviceAttributes.water_change_reminder: False,
                DeviceAttributes.water_shortage: False,
                DeviceAttributes.work_mode: None,
                DeviceAttributes.fire_power: None,
                DeviceAttributes.pre_heat: False,
                DeviceAttributes.turntable: False,
                DeviceAttributes.hot_wind: False,
                DeviceAttributes.temperature: None,
                DeviceAttributes.temperature_above: None,
                DeviceAttributes.temperature_underside: None,
                DeviceAttributes.probe_temperature: None,
                DeviceAttributes.cur_temperature_above: None,
                DeviceAttributes.cur_temperature_underside: None,
                DeviceAttributes.cur_probe_temperature: None,
                DeviceAttributes.steam_quantity: None,
                DeviceAttributes.weight: None,
                DeviceAttributes.people_number: None,
                DeviceAttributes.hour_set: None,
                DeviceAttributes.minute_set: None,
                DeviceAttributes.second_set: None,
                DeviceAttributes.child_lock: False,
                DeviceAttributes.furnace_light: False,
                DeviceAttributes.flip_side: False,
                DeviceAttributes.reaction: False,
                DeviceAttributes.high_temperature_lock: False,
                DeviceAttributes.high_temperature_work: False,
                DeviceAttributes.high_temperature: False,
                DeviceAttributes.probe_mode: False,
                DeviceAttributes.probe: False,
                DeviceAttributes.error_code: False,
                DeviceAttributes.ramadan: False,
                DeviceAttributes.totalstep: None,
                DeviceAttributes.stepnum: None,
                DeviceAttributes.cloudmenuid: None,
                DeviceAttributes.clean_scale: False,
                DeviceAttributes.clean_sink_ponding: False,
                DeviceAttributes.dissipate_heat: False,
                DeviceAttributes.cbs_version: None,
                DeviceAttributes.ota: False,
                DeviceAttributes.execute: None,
                DeviceAttributes.power: False,
                DeviceAttributes.screen_luminance: None,
                DeviceAttributes.volume: None,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea BF device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea BF device process message."""
        message = MessageBFResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        # message layer already resolves work_status into a string name
        # (see MessageBFBody._parse_status_and_power), so no translator needed.
        return self.update_attributes_from_message(message)

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
        # A probe target sets the probe bit in workModeControl, so only carry it
        # when a probe is actually in use.
        if self._attributes[DeviceAttributes.probe]:
            message.probe_temperature = self._attributes[
                DeviceAttributes.probe_temperature
            ]
        message.steam_quantity = self._attributes[DeviceAttributes.steam_quantity]
        message.weight = self._attributes[DeviceAttributes.weight]
        message.people_number = self._attributes[DeviceAttributes.people_number]
        message.turntable = self._attributes[DeviceAttributes.turntable]
        message.pre_heat = self._attributes[DeviceAttributes.pre_heat]
        # Preserves an active hot_wind in the b5 flags of a workModeControl
        # command built for another attribute; standalone hot_wind writes never
        # reach here (see _WORK_MODE_SETTABLE_ATTRS). Only "on" is carried: b5
        # has no "off" encoding, and a non-None hot_wind alone would route the
        # message to notWorkModeControl.
        if self._attributes[DeviceAttributes.hot_wind]:
            message.hot_wind = True
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
