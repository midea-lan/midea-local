"""Midea local CA device."""

import logging
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs

from .message import (
    DeviceAttributes,
    MessageCAResponse,
    MessageQuery,
    MessageQueryToshiba,
)

_LOGGER = logging.getLogger(__name__)

TOSHIBA_MANUFACTURER_CODE = "0008"


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
                DeviceAttributes.mode: None,
                DeviceAttributes.ice_mode: None,
                DeviceAttributes.ice_status: None,
                DeviceAttributes.ice_door: None,
            },
        )
        self._modes = [""]

    def build_query(self) -> list[MessageQuery | MessageQueryToshiba]:
        """Midea CA device build query."""
        if self.manufacturer_code == TOSHIBA_MANUFACTURER_CODE:
            return [MessageQueryToshiba(self._message_protocol_version)]
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea CA device process message."""
        message = MessageCAResponse(message=msg, model=self.model)
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
