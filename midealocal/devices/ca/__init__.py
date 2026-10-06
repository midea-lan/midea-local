"""Midea local CA device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs
from midealocal.message import MessageQueryAppliance

from .message import (
    TOSHIBA_FRAME_HEADER,
    MessageCAResponse,
    MessageQuery,
    MessageToshibaCAResponse,
    MessageToshibaQuery,
)

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
    # Toshiba IoLIFE refrigerators (55 AA CC 33 frame)
    ice_door = "ice_door"
    vegetable_door = "vegetable_door"
    upper_freezer_door = "upper_freezer_door"
    ice_maker_status = "ice_maker_status"
    ice_making_mode = "ice_making_mode"
    power_saving_mode = "power_saving_mode"
    upper_freezer_mode = "upper_freezer_mode"
    chilled_room_mode = "chilled_room_mode"
    refrigerator_setting_level = "refrigerator_setting_level"
    freezer_setting_level = "freezer_setting_level"
    vegetable_sterilization = "vegetable_sterilization"
    ice_tray_cleaning = "ice_tray_cleaning"
    moisturizing = "moisturizing"
    precooling = "precooling"
    defrosting = "defrosting"
    estimated_power = "estimated_power"
    daily_energy = "daily_energy"
    error_code = "error_code"
    ambient_temperature = "ambient_temperature"
    refrigerator_high_temperature = "refrigerator_high_temperature"
    freezer_high_temperature = "freezer_high_temperature"
    auto_saving_status = "auto_saving_status"


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

    @classmethod
    def mode_options(cls) -> list[str]:
        """Return the distinct variable modes this device can report, in order."""
        return list(dict.fromkeys(cls._variable_mode.values()))

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea CA device."""
        super().__init__(
            device_type=DeviceType.CA,
            **kwargs,
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
                DeviceAttributes.ice_door: None,
                DeviceAttributes.vegetable_door: None,
                DeviceAttributes.upper_freezer_door: None,
                DeviceAttributes.ice_maker_status: None,
                DeviceAttributes.ice_making_mode: None,
                DeviceAttributes.power_saving_mode: None,
                DeviceAttributes.upper_freezer_mode: None,
                DeviceAttributes.chilled_room_mode: None,
                DeviceAttributes.refrigerator_setting_level: None,
                DeviceAttributes.freezer_setting_level: None,
                DeviceAttributes.vegetable_sterilization: None,
                DeviceAttributes.ice_tray_cleaning: None,
                DeviceAttributes.moisturizing: None,
                DeviceAttributes.precooling: None,
                DeviceAttributes.defrosting: None,
                DeviceAttributes.estimated_power: None,
                DeviceAttributes.daily_energy: None,
                DeviceAttributes.error_code: None,
                DeviceAttributes.ambient_temperature: None,
                DeviceAttributes.refrigerator_high_temperature: None,
                DeviceAttributes.freezer_high_temperature: None,
                DeviceAttributes.auto_saving_status: None,
            },
        )
        self._modes = [""]

    def build_query(self) -> list[MessageQuery | MessageToshibaQuery]:
        """Midea CA device build query.

        Toshiba IoLIFE refrigerators ignore the appliance query (0xA0) and the AA
        status query, and only answer a query in their own frame format. Add that
        query once the appliance query is known to be unanswered, so Midea
        refrigerators that answer it never receive the Toshiba frame.
        """
        queries: list[MessageQuery | MessageToshibaQuery] = [
            MessageQuery(self._message_protocol_version),
        ]
        if MessageQueryAppliance.__name__ in self._unsupported_protocol:
            queries.append(MessageToshibaQuery())
        return queries

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea CA device process message."""
        if msg.startswith(TOSHIBA_FRAME_HEADER):
            toshiba_message = MessageToshibaCAResponse(msg)
            _LOGGER.debug("[%s] Received: %s", self.device_id, toshiba_message)
            return self.update_attributes_from_message(toshiba_message)
        message = MessageCAResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            {
                DeviceAttributes.variable_mode: MideaCADevice._variable_mode.get,
                DeviceAttributes.humidity: MideaCADevice._humidity.get,
            },
        )

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea CA device set attribute."""


class MideaAppliance(MideaCADevice):
    """Midea CA appliance."""
