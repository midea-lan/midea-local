"""Midea local B1 device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs

from .message import MessageB1Response, MessageQuery, MessageQueryX01

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea local B1 device attribute."""

    door = "door"
    status = "status"
    time_remaining = "time_remaining"
    current_temperature = "current_temperature"
    tank_ejected = "tank_ejected"
    water_change_reminder = "water_change_reminder"
    water_shortage = "water_shortage"


class MideaB1Device(MideaDevice):
    """Midea B1 device."""

    _status: ClassVar[dict[int, str]] = {
        0x01: "Standby",
        0x02: "Idle",
        0x03: "Working",
        0x04: "Finished",
        0x05: "Delay",
        0x06: "Paused",
    }

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea B1 device."""
        super().__init__(
            device_type=DeviceType.B1,
            **kwargs,
            attributes={
                DeviceAttributes.door: False,
                DeviceAttributes.status: None,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.tank_ejected: False,
                DeviceAttributes.water_change_reminder: False,
                DeviceAttributes.water_shortage: False,
            },
        )

    def build_query(self) -> list[MessageQuery | MessageQueryX01]:
        """Midea B1 device build query.

        Some B1 devices report the X00 ``MessageQuery`` as an unsupported
        protocol and never respond to it, leaving the device with no
        working query at all. X01 is included as a fallback - see
        ``MessageQueryX01``/``B1Message01Body``.
        """
        return [
            MessageQuery(self._message_protocol_version),
            MessageQueryX01(self._message_protocol_version),
        ]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea B1 device process message."""
        message = MessageB1Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            {DeviceAttributes.status: MideaB1Device._status.get},
        )

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea B1 device set attribute."""


class MideaAppliance(MideaB1Device):
    """Midea B1 appliance."""
