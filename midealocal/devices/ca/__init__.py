"""Midea local CA device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import MessageCAResponse, MessageQuery

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea CA device attributes."""

    mode = "mode"
    energy_consumption = "energy_consumption"
    refrigerator_actual_temp = "refrigerator_actual_temp"
    freezer_actual_temp = "freezer_actual_temp"
    flex_zone_actual_temp = "flex_zone_actual_temp"
    right_flex_zone_actual_temp = "right_flex_zone_actual_temp"
    refrigerator_setting_temp = "refrigerator_setting_temp"
    freezer_setting_temp = "freezer_setting_temp"
    flex_zone_setting_temp = "flex_zone_setting_temp"
    right_flex_zone_setting_temp = "right_flex_zone_setting_temp"
    refrigerator_door_overtime = "refrigerator_door_overtime"
    freezer_door_overtime = "freezer_door_overtime"
    bar_door_overtime = "bar_door_overtime"
    flex_zone_door_overtime = "flex_zone_door_overtime"
    refrigerator_door = "refrigerator_door"
    freezer_door = "freezer_door"
    bar_door = "bar_door"
    flex_zone_door = "flex_zone_door"
    microcrystal_fresh = "microcrystal_fresh"
    electronic_smell = "electronic_smell"
    humidity = "humidity"
    variable_mode = "variable_mode"


class MideaCADevice(MideaDevice):
    """Midea CA device."""

    _variable_mode: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "soft_freezing",
        0x02: "zero_fresh",
        0x03: "cold_drink",
        0x04: "fresh_product",
        0x05: "partial_freezing",
        0x06: "dry_zone",
        0x07: "freeze_warm",
        0x08: "partial_freezing",
    }

    _humidity: ClassVar[dict[int, str]] = {
        0x10: "high",
        0x20: "low",
    }

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
        customize: str,  # noqa: ARG002
    ) -> None:
        """Initialize Midea CA device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.CA,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.energy_consumption: None,
                DeviceAttributes.refrigerator_actual_temp: None,
                DeviceAttributes.freezer_actual_temp: None,
                DeviceAttributes.flex_zone_actual_temp: None,
                DeviceAttributes.right_flex_zone_actual_temp: None,
                DeviceAttributes.refrigerator_setting_temp: None,
                DeviceAttributes.freezer_setting_temp: None,
                DeviceAttributes.flex_zone_setting_temp: None,
                DeviceAttributes.right_flex_zone_setting_temp: None,
                DeviceAttributes.refrigerator_door_overtime: False,
                DeviceAttributes.freezer_door_overtime: False,
                DeviceAttributes.bar_door_overtime: False,
                DeviceAttributes.flex_zone_door_overtime: False,
                DeviceAttributes.refrigerator_door: False,
                DeviceAttributes.freezer_door: False,
                DeviceAttributes.bar_door: False,
                DeviceAttributes.flex_zone_door: False,
                DeviceAttributes.microcrystal_fresh: False,
                DeviceAttributes.electronic_smell: False,
                DeviceAttributes.humidity: None,
                DeviceAttributes.variable_mode: None,
            },
        )
        self._modes = [""]

    def build_query(self) -> list[MessageQuery]:
        """Midea CA device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea CA device process message."""
        message = MessageCAResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        for attr in self._attributes:
            if hasattr(message, str(attr)):
                value = getattr(message, str(attr))
                # variable_mode
                if attr == DeviceAttributes.variable_mode:
                    self._attributes[attr] = MideaCADevice._variable_mode.get(value)
                # humidity
                elif attr == DeviceAttributes.humidity:
                    self._attributes[attr] = MideaCADevice._humidity.get(value)
                else:
                    self._attributes[attr] = value
                new_status[str(attr)] = getattr(message, str(attr))
        return new_status

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea CA device set attribute."""


class MideaAppliance(MideaCADevice):
    """Midea CA appliance."""
