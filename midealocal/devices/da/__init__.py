"""Midea local DA device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack, cast

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
WASHING_DATA_PROGRAM_OFFSET = 1
WASHING_DATA_RINSE_WASH_OFFSET = 2
WASHING_DATA_SPEED_STRENGTH_OFFSET = 3
WASHING_DATA_DISPENSER_OFFSET = 5
WASHING_DATA_WASH_TIME_OFFSET = 6
WASHING_DATA_RINSE_DEHYDRATION_OFFSET = 7
WASHING_DATA_SOAK_TIME_OFFSET = 9
WASHING_DATA_NIBBLE_SHIFT = 4


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

    def _build_washing_data(self) -> bytearray:
        """Build washing data."""
        washing_data = bytearray(
            [WASHING_DATA_FILL] * WASHING_DATA_SIZE,
        )

        program = self.get_attribute(DeviceAttributes.program)
        if program is not None:
            washing_data[WASHING_DATA_PROGRAM_OFFSET] = self._program.index(
                str(program),
            )

        rinse_level = self.get_attribute(DeviceAttributes.rinse_level)
        wash_level = self.get_attribute(DeviceAttributes.wash_level)
        if rinse_level is not None and wash_level is not None:
            rinse_level_value = (
                MIN_TEMP if rinse_level == "none" else cast("int", rinse_level)
            )
            washing_data[WASHING_DATA_RINSE_WASH_OFFSET] = (
                rinse_level_value << WASHING_DATA_NIBBLE_SHIFT | cast("int", wash_level)
            )

        dehydration_speed = self.get_attribute(DeviceAttributes.dehydration_speed)
        wash_strength = self.get_attribute(DeviceAttributes.wash_strength)
        if dehydration_speed is not None and wash_strength is not None:
            speed = self._speed.index(str(dehydration_speed))
            strength = self._strength.index(str(wash_strength))
            washing_data[WASHING_DATA_SPEED_STRENGTH_OFFSET] = (
                speed << WASHING_DATA_NIBBLE_SHIFT | strength
            )

        softener = self.get_attribute(DeviceAttributes.softener)
        detergent = self.get_attribute(DeviceAttributes.detergent)
        if softener is not None and detergent is not None:
            softener_value = self._softener.index(str(softener))
            detergent_value = self._detergent.index(str(detergent))
            washing_data[WASHING_DATA_DISPENSER_OFFSET] = (
                softener_value << WASHING_DATA_NIBBLE_SHIFT | detergent_value
            )

        wash_time = self.get_attribute(DeviceAttributes.wash_time)
        if wash_time is not None:
            washing_data[WASHING_DATA_WASH_TIME_OFFSET] = cast("int", wash_time)

        dehydration_time = self.get_attribute(DeviceAttributes.dehydration_time)
        rinse_count = self.get_attribute(DeviceAttributes.rinse_count)
        if dehydration_time is not None and rinse_count is not None:
            washing_data[WASHING_DATA_RINSE_DEHYDRATION_OFFSET] = cast(
                "int",
                dehydration_time,
            ) << WASHING_DATA_NIBBLE_SHIFT | cast("int", rinse_count)

        soak_time = self.get_attribute(DeviceAttributes.soak_time)
        if soak_time is not None:
            washing_data[WASHING_DATA_SOAK_TIME_OFFSET] = cast("int", soak_time)

        return washing_data


class MideaAppliance(MideaDADevice):
    """Midea DA appliance."""
