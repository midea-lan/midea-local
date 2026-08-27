"""Midea local E8 device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs

from .message import MessageE8Response, MessageQuery

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea E8 device."""

    status = "status"
    time_remaining = "time_remaining"
    keep_warm_remaining = "keep_warm_remaining"
    working_time = "working_time"
    target_temperature = "target_temperature"
    current_temperature = "current_temperature"
    finished = "finished"
    water_shortage = "water_shortage"


class MideaE8Device(MideaDevice):
    """Midea E8 device."""

    _status: ClassVar[dict[int, str]] = {
        0x00: "standby",
        0x01: "delay",
        0x02: "working",
        0x03: "paused",
        0x04: "keep_warming",
        0xFF: "error",
    }

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea E8 device."""
        super().__init__(
            device_type=DeviceType.E8,
            **kwargs,
            attributes={
                DeviceAttributes.status: None,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.keep_warm_remaining: None,
                DeviceAttributes.working_time: None,
                DeviceAttributes.target_temperature: None,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.finished: None,
                DeviceAttributes.water_shortage: None,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea E8 device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea E8 device process message."""
        message = MessageE8Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            {DeviceAttributes.status: MideaE8Device._status.get},
        )

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea E8 device set attribute."""


class MideaAppliance(MideaE8Device):
    """Midea E8 appliance."""
