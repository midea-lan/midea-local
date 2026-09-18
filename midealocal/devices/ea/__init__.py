"""Midea local EA device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.base_classes.rice_cooker import MideaRiceCookerDevice
from midealocal.const import DeviceType
from midealocal.device import MideaDeviceInitKwargs, list_translator

from .message import MessageEAResponse, MessageQuery

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea EA device attributes."""

    cooking = "cooking"
    keep_warm = "keep_warm"
    mode = "mode"
    time_remaining = "time_remaining"
    keep_warm_time = "keep_warm_time"
    top_temperature = "top_temperature"
    bottom_temperature = "bottom_temperature"
    progress = "progress"


class MideaEADevice(MideaRiceCookerDevice):
    """Midea EA device."""

    _progress: ClassVar[list[str]] = ["idle", "delay", "cooking", "keep_warm"]

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea EA device."""
        super().__init__(
            device_type=DeviceType.EA,
            **kwargs,
            attributes={
                DeviceAttributes.cooking: False,
                DeviceAttributes.keep_warm: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.top_temperature: None,
                DeviceAttributes.bottom_temperature: None,
                DeviceAttributes.keep_warm_time: None,
                DeviceAttributes.progress: "unknown",
            },
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea EA device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea EA device process message."""
        message = MessageEAResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            {
                DeviceAttributes.progress: list_translator(
                    MideaEADevice._progress,
                    default="unknown",
                ),
                DeviceAttributes.mode: list_translator(
                    MideaEADevice._mode_list,
                    default="cloud",
                ),
            },
        )

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea EA device set attribute."""


class MideaAppliance(MideaEADevice):
    """Midea EA appliance."""
