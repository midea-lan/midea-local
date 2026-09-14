"""Midea local EC device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.base_classes.rice_cooker import MideaRiceCookerDevice
from midealocal.const import DeviceType
from midealocal.device import MideaDeviceInitKwargs, list_translator

from .message import MessageECResponse, MessageQuery

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea EC device attributes."""

    cooking = "cooking"
    mode = "mode"
    time_remaining = "time_remaining"
    keep_warm_time = "keep_warm_time"
    top_temperature = "top_temperature"
    bottom_temperature = "bottom_temperature"
    progress = "progress"
    with_pressure = "with_pressure"


class MideaECDevice(MideaRiceCookerDevice):
    """Midea EC device."""

    _mode_list: ClassVar[list[str]] = [
        *MideaRiceCookerDevice._mode_list,  # noqa: SLF001
        "diy",
    ]
    _progress: ClassVar[list[str]] = [
        "idle",
        "cooking",
        "delay",
        "keep_warm",
        "lid_open",
        "relieving",
        "keep_pressure",
        "relieving",
        "cooking",
        "relieving",
        "lid_open",
    ]

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea EC device."""
        super().__init__(
            device_type=DeviceType.EC,
            **kwargs,
            attributes={
                DeviceAttributes.cooking: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.top_temperature: None,
                DeviceAttributes.bottom_temperature: None,
                DeviceAttributes.keep_warm_time: None,
                DeviceAttributes.progress: "unknown",
                DeviceAttributes.with_pressure: None,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea EC device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea EC device process merge."""
        message = MessageECResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            {
                DeviceAttributes.progress: list_translator(
                    MideaECDevice._progress,
                    default="unknown",
                ),
                DeviceAttributes.mode: list_translator(
                    MideaECDevice._mode_list,
                    default="cloud",
                ),
            },
        )

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea EC device set attribute."""


class MideaAppliance(MideaECDevice):
    """Midea EC appliance."""
