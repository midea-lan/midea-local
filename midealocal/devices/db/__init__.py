"""Midea local DB device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice
from midealocal.exceptions import ValueWrongType

from .message import MessageDBResponse, MessagePower, MessageQuery, MessageStart

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea DB device attributes."""

    power = "power"
    start = "start"
    status = "status"
    mode = "mode"
    program = "program"
    water_level = "water_level"
    temperature = "temperature"
    dehydration_speed = "dehydration_speed"
    wash_time = "wash_time"
    wash_time_value = "wash_time_value"
    dehydration_time = "dehydration_time"
    dehydration_time_value = "dehydration_time_value"
    detergent = "detergent"
    softener = "softener"
    washing_data = "washing_data"
    progress = "progress"
    time_remaining = "time_remaining"
    stains = "stains"
    dirty_degree = "dirty_degree"


class MideaDBDevice(MideaDevice):
    """Midea DB device."""

    _status: ClassVar[dict[int, str]] = {
        0: "idle",
        1: "standby",
        2: "start",
        3: "pause",
        4: "end",
        5: "fault",
        6: "delay",
    }

    _mode: ClassVar[dict[int, str]] = {
        0: "normal",
        1: "factory_test",
        2: "service",
        3: "normal_continus",
    }

    _dehydration_speed: ClassVar[dict[int, str]] = {
        0x00: "0",
        0x01: "400",
        0x02: "600",
        0x03: "800",
        0x04: "1000",
        0x05: "1200",
        0x06: "1400",
        0x07: "1600",
        0x08: "1300",
        0xFF: "default",
    }

    _water_level: ClassVar[dict[int, str]] = {
        0x01: "Low",
        0x02: "Mid",
        0x03: "High",
        0x04: "4",
        0x05: "Auto",
        0xFF: "default",
    }

    _program: ClassVar[dict[int, str]] = {
        0x00: "cotton",
        0x01: "eco",
        0x02: "fast_wash",
        0x03: "mixed_wash",
        0x04: "fiber",
        0x05: "wool",
        0x06: "enzyme",
        0x07: "ssp",
        0x08: "sport_clothes",
        0x09: "single_dehytration",
        0x0A: "rinsing_dehydration",
        0x0B: "big",
        0x0C: "baby_clothes",
        0x0D: "outdoor",
        0x0E: "air_wash",
        0x0F: "down_jacket",
        0x10: "color",
        0x11: "intelligent",
        0x12: "quick_wash",
        0x13: "kids",
        0x14: "water_cotton",
        0x15: "single_drying",
        0x16: "single_drying",
        0x17: "fast_wash_30",
        0x18: "fast_wash_60",
        0x19: "water_intelligent",
        0x1A: "water_steep",
        0x1B: "water_fast_wash_30",
        0x1C: "shirt",
        0x1D: "steep",
        0x1E: "new_water_cotton",
        0x1F: "water_mixed_wash",
        0x20: "water_fiber",
        0x21: "water_kids",
        0x22: "water_underwear",
        0x23: "specialist",
        0x24: "water_eco",
        0x25: "wash_drying_60",
        0x26: "self_wash_5",
        0x27: "fast_wash_min",
        0x28: "mixed_wash_min",
        0x29: "dehydration_min",
        0x2A: "self_wash_min",
        0x2B: "baby_clothes_min",
        0x2C: "prevent_allergy",
        0x2D: "cold_wash",
        0x2E: "soft_wash",
        0x2F: "remove_mite_wash",
        0x30: "water_intense_wash",
        0x31: "fast_dry",
        0x32: "water_outdoor",
        0x33: "spring_autumn_wash",
        0x34: "summer_wash",
        0x35: "winter_wash",
        0x36: "jean",
        0x37: "new_clothes_wash",
        0x38: "silk",
        0x39: "insight_wash",
        0x3A: "fitness_clothes",
        0x3B: "mink",
        0x3C: "fresh_air",
        0x3D: "bucket_dry",
        0x3E: "jacket",
        0x3F: "bath_towel",
        0x40: "night_fresh_wash",
        0x50: "water_fiber",
        0x51: "diy0",
        0x52: "diy2",
        0x60: "heart_wash",
        0x61: "water_cold_wash",
        0x62: "water_prevent_allergy",
        0x63: "water_remove_mite_wash",
        0x64: "water_ssp",
        0x65: "silk_wash",
        0x66: "standard",
        0x67: "green_wool",
        0x68: "cook_wash",
        0x69: "fresh_remove_wrinkle",
        0x6A: "steam_sterilize_wash",
        0x6B: "aromatherapy",
        0x70: "sterilize_wash",
        0xFE: "love",
        0xFF: "default",
    }

    _temperature: ClassVar[dict[int, str]] = {
        0x01: "0",
        0x02: "20",
        0x03: "30",
        0x04: "40",
        0x05: "60",
        0x06: "95",
        0x07: "70",
        0xFF: "default",
    }

    _progress: ClassVar[list[str]] = [
        "Idle",
        "Spin",
        "Rinse",
        "Wash",
        "Pre-wash",
        "Dry",
        "Weight",
        "Hi-speed Spin",
        "Unknown",
    ]

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
        """Initialize Midea DB device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.DB,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.start: False,
                DeviceAttributes.status: None,
                DeviceAttributes.mode: None,
                DeviceAttributes.program: None,
                DeviceAttributes.water_level: None,
                DeviceAttributes.temperature: None,
                DeviceAttributes.dehydration_speed: None,
                DeviceAttributes.wash_time: None,
                DeviceAttributes.dehydration_time: None,
                DeviceAttributes.detergent: None,
                DeviceAttributes.softener: None,
                DeviceAttributes.washing_data: bytearray([]),
                DeviceAttributes.progress: None,
                DeviceAttributes.stains: None,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.wash_time_value: None,
                DeviceAttributes.dehydration_time_value: None,
                DeviceAttributes.dirty_degree: None,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea DB device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea DB device process message."""
        message = MessageDBResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}

        for attr in self._attributes:
            if hasattr(message, str(attr)):
                value = getattr(message, str(attr))
                # parse mode
                if attr == DeviceAttributes.mode:
                    self._attributes[DeviceAttributes.mode] = MideaDBDevice._mode.get(
                        value,
                        value,
                    )
                # parse status
                elif attr == DeviceAttributes.status:
                    self._attributes[DeviceAttributes.status] = (
                        MideaDBDevice._status.get(value, value)
                    )
                # parse dehydration_speed
                elif attr == DeviceAttributes.dehydration_speed:
                    self._attributes[DeviceAttributes.dehydration_speed] = (
                        MideaDBDevice._dehydration_speed.get(value, value)
                    )
                # parse water_level
                elif attr == DeviceAttributes.water_level:
                    self._attributes[DeviceAttributes.water_level] = (
                        MideaDBDevice._water_level.get(value, value)
                    )
                # parse program
                elif attr == DeviceAttributes.program:
                    self._attributes[DeviceAttributes.program] = (
                        MideaDBDevice._program.get(value, value)
                    )
                # parse temperature
                elif attr == DeviceAttributes.temperature:
                    self._attributes[DeviceAttributes.temperature] = (
                        MideaDBDevice._temperature.get(value, value)
                    )
                # parse progress
                elif attr == DeviceAttributes.progress:
                    self._attributes[attr] = MideaDBDevice._progress[value]
                else:
                    self._attributes[attr] = value
                new_status[str(attr)] = self._attributes[attr]
        return new_status

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea DB device set attribute."""
        if not isinstance(value, bool):
            raise ValueWrongType("[db] Expected bool")
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


class MideaAppliance(MideaDBDevice):
    """Midea DB appliance."""
