"""Midea local DA device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

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
WASHING_DATA_SIZE = 12
WASHING_DATA_FILL = 0xFF


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

    _progress: ClassVar[list[str]] = [
        "idle",
        "spin",
        "rinse",
        "wash",
        "weight",
        "unknown",
        "dry",
        "soak",
    ]
    _program: ClassVar[list[str]] = [
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
    _speed: ClassVar[list[str]] = ["none", "low", "medium", "high"]
    _strength: ClassVar[list[str]] = ["none", "weak", "medium", "strong"]
    _detergent: ClassVar[list[str]] = [
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
    _softener: ClassVar[list[str]] = [
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
                DeviceAttributes.program: None,
                DeviceAttributes.progress: "unknown",
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

        return self.update_attributes_from_message(
            message,
            {
                DeviceAttributes.progress: list_translator(self._progress),
                DeviceAttributes.program: list_translator(self._program),
                DeviceAttributes.rinse_level: sentinel_translator(MIN_TEMP, "none"),
                DeviceAttributes.dehydration_speed: list_translator(self._speed),
                DeviceAttributes.detergent: list_translator(self._detergent),
                DeviceAttributes.softener: list_translator(self._softener),
                DeviceAttributes.wash_strength: list_translator(self._strength),
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
            message.washing_data = self._build_washing_data()
            self.build_send(message)

    def _get_index_from_value(
        self,
        value: str,
        values: list[str],
        default: int = WASHING_DATA_FILL,
    ) -> int:
        """Get the key from the value in the mapping."""
        if value in values:
            return values.index(value)
        return default

    def _build_washing_data(self) -> bytearray:
        """Build washing data."""
        washing_data = bytearray(
            [WASHING_DATA_FILL] * WASHING_DATA_SIZE,
        )

        if isinstance(program := self.get_attribute(DeviceAttributes.program), str):
            washing_data[1] = self._get_index_from_value(
                program,
                self._program,
            )

        rinse_level_value = 0xF
        wash_level_value = 0xF
        if isinstance(
            rinse_level := self.get_attribute(DeviceAttributes.rinse_level),
            int,
        ):
            rinse_level_value = rinse_level & 0x0F

        if isinstance(
            wash_level := self.get_attribute(DeviceAttributes.wash_level),
            int,
        ):
            wash_level_value = wash_level & 0x0F

        washing_data[2] = rinse_level_value << 4 | wash_level_value

        speed = 0xF
        strength = 0xF
        if isinstance(
            dehydration_speed := self.get_attribute(DeviceAttributes.dehydration_speed),
            str,
        ):
            speed = self._get_index_from_value(dehydration_speed, self._speed) & 0x0F

        if isinstance(
            wash_strength := self.get_attribute(DeviceAttributes.wash_strength),
            str,
        ):
            strength = self._get_index_from_value(wash_strength, self._strength) & 0x0F

        washing_data[3] = (speed << 4) & 0xF0 | strength

        softener_value = 0xF
        detergent_value = 0xF
        if isinstance(softener := self.get_attribute(DeviceAttributes.softener), str):
            softener_value = self._get_index_from_value(softener, self._softener) & 0x0F
        if isinstance(detergent := self.get_attribute(DeviceAttributes.detergent), str):
            detergent_value = (
                self._get_index_from_value(detergent, self._detergent) & 0x0F
            )

        washing_data[5] = (softener_value << 4) & 0xF0 | detergent_value

        if isinstance(wash_time := self.get_attribute(DeviceAttributes.wash_time), int):
            washing_data[6] = wash_time

        dehydration_time_value = 0xF
        rinse_count_value = 0xF
        if isinstance(
            dehydration_time := self.get_attribute(DeviceAttributes.dehydration_time),
            int,
        ):
            dehydration_time_value = dehydration_time & 0x0F
        if isinstance(
            rinse_count := self.get_attribute(DeviceAttributes.rinse_count),
            int,
        ):
            rinse_count_value = rinse_count & 0x0F
        washing_data[7] = (dehydration_time_value << 4) & 0xF0 | rinse_count_value

        if isinstance(soak_time := self.get_attribute(DeviceAttributes.soak_time), int):
            washing_data[9] = soak_time

        return washing_data


class MideaAppliance(MideaDADevice):
    """Midea DA appliance."""
