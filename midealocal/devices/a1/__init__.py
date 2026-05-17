"""Midea local A1 device."""

import json
import logging
from enum import StrEnum
from typing import Any, ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import MessageA1Response, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Device A1 attributes."""

    power = "power"
    prompt_tone = "prompt_tone"
    child_lock = "child_lock"
    mode = "mode"
    fan_speed = "fan_speed"
    swing = "swing"
    target_humidity = "target_humidity"
    anion = "anion"
    tank = "tank"
    water_level_set = "water_level_set"
    tank_full = "tank_full"
    current_humidity = "current_humidity"
    current_temperature = "current_temperature"
    filter_cleaning_reminder = "filter_cleaning_reminder"


class MideaA1Device(MideaDevice):
    """Midea A1 Device."""

    _default_modes: ClassVar[dict[int, str]] = {
        1: "Manual",
        2: "Continuous",
        3: "Auto",
        4: "Clothes-Dry",
        5: "Shoes-Dry",
    }
    _default_speeds: ClassVar[dict[int, str]] = {
        1: "Lowest",
        40: "Low",
        60: "Medium",
        80: "High",
        102: "Auto",
        127: "Off",
    }
    _water_level_sets: ClassVar[list[str]] = ["25", "50", "75", "100"]

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
        """Initialize Midea A1 device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.A1,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.prompt_tone: True,
                DeviceAttributes.child_lock: False,
                DeviceAttributes.mode: None,
                DeviceAttributes.fan_speed: "Medium",
                DeviceAttributes.swing: False,
                DeviceAttributes.target_humidity: 35,
                DeviceAttributes.anion: False,
                DeviceAttributes.tank: 0,
                DeviceAttributes.water_level_set: 50,
                DeviceAttributes.tank_full: None,
                DeviceAttributes.current_humidity: None,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.filter_cleaning_reminder: False,
            },
        )
        self._speeds = self._default_speeds
        self._modes = self._default_modes
        self.set_customize(customize)

    @property
    def modes(self) -> list[str]:
        """Midea A1 device modes."""
        return list(self._modes.values())

    @property
    def fan_speeds(self) -> list[str]:
        """Midea A1 device fan speeds."""
        return list(self._speeds.values())

    @property
    def water_level_sets(self) -> list[str]:
        """Midea A1 device water level options."""
        return MideaA1Device._water_level_sets

    def build_query(self) -> list[MessageQuery]:
        """Midea A1 device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea A1 device process message."""
        message = MessageA1Response(bytearray(msg))
        self._message_protocol_version = message.protocol_version
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                if status == DeviceAttributes.mode:
                    if value in self._modes:
                        self._attributes[status] = self._modes.get(value)
                    else:
                        self._attributes[status] = None
                elif status == DeviceAttributes.fan_speed:
                    if value in self._speeds:
                        self._attributes[status] = self._speeds.get(value)
                    else:
                        self._attributes[status] = None
                elif status == DeviceAttributes.water_level_set:
                    self._attributes[status] = str(value)
                else:
                    self._attributes[status] = value
                tank_full = self._attributes[DeviceAttributes.tank_full]
                tank = self._attributes[DeviceAttributes.tank]
                water_level = int(self._attributes[DeviceAttributes.water_level_set])
                tank_full_calculated = tank >= water_level if bool(tank) else False
                _LOGGER.debug(
                    "Device - tank: %s, tank_full: %s, \
                                     water_level: %s, tank_full_calculated: %s",
                    tank,
                    tank_full,
                    water_level,
                    tank_full_calculated,
                )
                if tank_full is None or tank_full != tank_full_calculated:
                    self._attributes[DeviceAttributes.tank_full] = tank_full_calculated
                    new_status[str(DeviceAttributes.tank_full)] = tank_full_calculated
                new_status[str(status)] = self._attributes[status]
                _LOGGER.debug(
                    "Device after - new_status: %s, tank_full: %s",
                    new_status,
                    self._attributes[DeviceAttributes.tank_full],
                )
        return new_status

    def make_message_set(self) -> MessageSet:
        """Midea A1 device make message set."""
        message = MessageSet(self._message_protocol_version)
        message.power = self._attributes[DeviceAttributes.power]
        message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]
        message.child_lock = self._attributes[DeviceAttributes.child_lock]
        if self._attributes[DeviceAttributes.mode] in self._modes.values():
            message.mode = {v: k for k, v in self._modes.items()}[
                self._attributes[DeviceAttributes.mode]
            ]
        else:
            message.mode = 1
        if self._attributes[DeviceAttributes.fan_speed] in self._speeds.values():
            message.fan_speed = {v: k for k, v in self._speeds.items()}[
                self._attributes[DeviceAttributes.fan_speed]
            ]
        else:
            message.fan_speed = 40
        message.target_humidity = self._attributes[DeviceAttributes.target_humidity]
        message.swing = self._attributes[DeviceAttributes.swing]
        message.anion = self._attributes[DeviceAttributes.anion]
        message.water_level_set = int(
            self._attributes[DeviceAttributes.water_level_set],
        )
        return message

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea A1 device set attribute."""
        if attr == DeviceAttributes.prompt_tone:
            self._attributes[DeviceAttributes.prompt_tone] = value
            self.update_all({DeviceAttributes.prompt_tone.value: value})
        else:
            message = self.make_message_set()
            if attr == DeviceAttributes.mode:
                if value in self._modes.values():
                    message.mode = {v: k for k, v in self._modes.items()}[str(value)]
            elif attr == DeviceAttributes.fan_speed:
                if value in self._speeds.values():
                    message.fan_speed = {v: k for k, v in self._speeds.items()}[
                        str(value)
                    ]
            elif attr == DeviceAttributes.water_level_set:
                if value in MideaA1Device._water_level_sets:
                    message.water_level_set = int(value)
            else:
                setattr(message, str(attr), value)
            self.build_send(message)

    def set_customize(self, customize: str) -> None:
        """Midea A1 Device set customize."""
        self._speeds = self._default_speeds
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params:
                    to_update = {}
                    if "speeds" in params:
                        self._speeds = {}
                        speeds = {}
                        for k, v in params.get("speeds").items():
                            speeds[int(k)] = v
                        keys = sorted(speeds.keys())
                        for k in keys:
                            self._speeds[k] = speeds[k]
                        to_update["speeds"] = self._speeds
                    if "modes" in params:
                        self._modes = {}
                        modes = {}
                        for k, v in params.get("modes").items():
                            modes[int(k)] = v
                        keys = sorted(modes.keys())
                        for k in keys:
                            self._modes[k] = modes[k]
                        to_update["modes"] = self._modes
                    if to_update:
                        self.update_all(to_update)
            except Exception:
                _LOGGER.exception(
                    "[%s] Set customize error - %s",
                    self.device_id,
                    customize,
                )


class MideaAppliance(MideaA1Device):
    """Midea A1 Appliance."""
