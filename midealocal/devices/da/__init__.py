"""Midea local DA device."""

import logging
from enum import StrEnum
from typing import Any, Unpack

from midealocal.const import DeviceType
from midealocal.device import (
    MideaDevice,
    MideaDeviceInitKwargs,
    list_translator,
    sentinel_translator,
)
from midealocal.exceptions import ValueWrongType

from .message import MessageDAResponse, MessagePower, MessageQuery, MessageStart

_LOGGER = logging.getLogger(__name__)

MIN_TEMP = 15


class DeviceAttributes(StrEnum):
    """Midea DA device attributes."""

    power = "power"
    start = "start"
    washing_data = "washing_data"
    program = "program"
    progress = "progress"
    time_remaining = "time_remaining"
    wash_time = "wash_time"
    soak_time = "soak_time"
    dehydration_time = "dehydration_time"
    dehydration_speed = "dehydration_speed"
    error_code = "error_code"
    rinse_count = "rinse_count"
    rinse_level = "rinse_level"
    wash_level = "wash_level"
    wash_strength = "wash_strength"
    softener = "softener"
    detergent = "detergent"


class MideaDADevice(MideaDevice):
    """Midea DA device."""

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea DA device."""
        super().__init__(
            device_type=DeviceType.DA,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.start: False,
                DeviceAttributes.error_code: None,
                DeviceAttributes.washing_data: bytearray([]),
                DeviceAttributes.program: None,
                DeviceAttributes.progress: "Unknown",
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.wash_time: None,
                DeviceAttributes.soak_time: None,
                DeviceAttributes.dehydration_time: None,
                DeviceAttributes.dehydration_speed: None,
                DeviceAttributes.rinse_count: None,
                DeviceAttributes.rinse_level: None,
                DeviceAttributes.wash_level: None,
                DeviceAttributes.wash_strength: None,
                DeviceAttributes.softener: None,
                DeviceAttributes.detergent: None,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea DA device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea DA device process message."""
        message = MessageDAResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        progress = ["idle", "spin", "rinse", "wash", "weight", "unknown", "dry", "soak"]
        program = [
            "standard",
            "fast",
            "blanket",
            "wool",
            "embathe",
            "memory",
            "child",
            "down_jacket",
            "stir",
            "mute",
            "bucket_self_clean",
            "air_dry",
        ]
        speed = ["none", "low", "medium", "high"]
        strength = ["none", "weak", "medium", "strong"]
        detergent = [
            "no",
            "less",
            "medium",
            "more",
            "4",
            "5",
            "6",
            "7",
            "8",
            "insufficient",
        ]
        softener = [
            "no",
            "intelligent",
            "programed",  # codespell:ignore
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "insufficient",
        ]
        return self.update_attributes_from_message(
            message,
            {
                DeviceAttributes.progress: list_translator(progress),
                DeviceAttributes.program: list_translator(program),
                DeviceAttributes.rinse_level: sentinel_translator(MIN_TEMP, "none"),
                DeviceAttributes.dehydration_speed: list_translator(speed),
                DeviceAttributes.detergent: list_translator(detergent),
                DeviceAttributes.softener: list_translator(softener),
                DeviceAttributes.wash_strength: list_translator(strength),
            },
        )

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea DA device set attribute."""
        if not isinstance(value, bool):
            raise ValueWrongType("[da] Expected bool")
        message: MessagePower | MessageStart | None = None
        if attr == DeviceAttributes.power:
            message = MessagePower(self._message_protocol_version)
            message.power = value
            self.build_send(message)
        elif attr == DeviceAttributes.start:
            message = MessageStart(self._message_protocol_version)
            message.start = value
            message.washing_data = self._attributes[DeviceAttributes.washing_data]
            self.build_send(message)


class MideaAppliance(MideaDADevice):
    """Midea DA appliance."""
