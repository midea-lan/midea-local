"""Midea local B0 device."""

import logging
from enum import StrEnum
from typing import ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import (
    MessageB0Response,
    MessageQuery00,
    MessageQuery01,
    MessageQuery31,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea B0 device attributes."""

    door = "door"
    status = "status"
    time_remaining = "time_remaining"
    current_temperature = "current_temperature"
    tank_ejected = "tank_ejected"
    water_change_reminder = "water_change_reminder"
    water_shortage = "water_shortage"
    mode = "mode"
    fire_power = "fire_power"
    child_lock = "child_lock"


class MideaB0Device(MideaDevice):
    """B0 Midea device."""

    _status: ClassVar[dict[int, str]] = {
        0x01: "Cancel",
        0x02: "Working",
        0x03: "Pause",
        0x04: "Finished",
        0x06: "Order",
        0x07: "Save Power",
        0x08: "Heat",
        0x09: "Three",
        0x0D: "Reaction",
        0x66: "Cloud",
        0xFF: "Default",
    }

    _status31: ClassVar[dict[int, str]] = {
        0x01: "Save Power",
        0x02: "Idle",
        0x03: "Working",
        0x04: "Finished",
        0x05: "Delay",
        0x06: "Paused",
        0x07: "Pause Cancel",
        0x08: "Three",
        0xFF: "Default",
    }

    _mode: ClassVar[dict[int, str]] = {
        0x00: "None",
        0x01: "Microwave",
        0x02: "Baking",
        0x03: "Ferment",
        0x04: "Unfreeze",
        0x05: "Roast",
        0x06: "Host Steam",
        0x07: "Fast Steam",
        0x08: "Fast Hot",
        0x09: "Pure Steam",
        0x0A: "Metal Sterilize",
        0x0B: "Remove Odor",
        0x0C: "Scale Clean",
        0x0D: "Smart Clean",
        0x11: "Smart Steam Fish",
        0x12: "Rice",
        0x13: "Steam Ribs",
        0x14: "Code to Hot",
        0x15: "Wing",
        0x16: "Kebab",
        0x18: "Egg",
        0x19: "Instant Noodle",
        0x1A: "Vegetable",
        0x1B: "Meat",
        0x1C: "Tofu",
        0x1D: "Chicken Soup",
        0x1E: "Dumplings",
        0x1F: "Porridge",
        0x20: "Chicken Block",
        0x21: "Pumpkin",
        0x22: "Popcorn",
        0x23: "Meat Eggplant",
        0x24: "Bake Shrimp",
        0x25: "Baby Milk",
        0x26: "Baby Egg",
        0x27: "Carrots",
        0x28: "Baby Fruit",
        0x29: "Snow Pear",
        0x2A: "Papaya Milk",
        0x2B: "Jujube Longan",
        0x2C: "Lotus Seed",
        0x2D: "Fast Soup",
        0x2E: "Sirloin",
        0x2F: "Coconut Sogo",
        0x30: "Meat Tofu",
        0x31: "Spicy Tofu",
        0x32: "Sauted Meat",
        0x33: "Steam Corn",
        0x34: "Pearl Meat",
        0x35: "Bun",
        0x36: "Coix Bean",
        0x37: "Bake Ribs",
        0x38: "Sausage",
        0x39: "Bake Cake",
        0x3A: "Bake Cookies",
        0x3B: "Sweet Potato",
        0x3C: "Steam Seafood",
        0x3D: "Fans Scallops",
        0x3E: "Steam Bun",
        0x3F: "Sauerkraut Fish",
        0x41: "Warm",
        0x42: "Pre Hot",
        0x43: "Baking",
        0x44: "Brittle",
        0x50: "Frozen Food",
        0x51: "Milk Coffee",
        0x52: "Spicy Sausage",
        0x53: "Bake Swing",
        0x54: "Pure Steam Fish",
    }

    _mode31: ClassVar[dict[int, str]] = {
        0x00: "None",
        0x01: "Microwave",
        0x40: "Above Tube",
        0xA0: "Unfreeze",
        0xC3: "Remove Odor",
        0xE0: "Auto",
        0xE2: "Humidit Auto",
        0xFF: "Default",
    }

    _fire_power31: ClassVar[dict[int, str]] = {
        0x01: "Low",
        0x03: "Medium Low",
        0x05: "Medium",
        0x08: "Midium High",
        0x0A: "High",
        0xFF: "Default",
    }

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
        """Initialize B0 Midea device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.B0,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.door: False,
                DeviceAttributes.status: None,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.tank_ejected: False,
                DeviceAttributes.water_change_reminder: False,
                DeviceAttributes.water_shortage: False,
                DeviceAttributes.mode: None,
                DeviceAttributes.fire_power: None,
                DeviceAttributes.child_lock: False,
            },
        )

    def build_query(self) -> list[MessageQuery00 | MessageQuery01 | MessageQuery31]:
        """B0 Midea device build query."""
        return [
            MessageQuery00(self._message_protocol_version),
            MessageQuery01(self._message_protocol_version),
            MessageQuery31(self._message_protocol_version),
        ]

    def process_message(self, msg: bytes) -> dict:
        """B0 Midea device process message."""
        message = MessageB0Response(bytearray(msg))
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        for attr in self._attributes:
            if hasattr(message, str(attr)):
                value = getattr(message, str(attr))
                # status
                if attr == DeviceAttributes.status:
                    # model 0TG025JG, subtype 2
                    if self._subtype > 0:
                        self._attributes[attr] = MideaB0Device._status31.get(value)
                    else:
                        self._attributes[attr] = MideaB0Device._status.get(value)
                # mode
                elif attr == DeviceAttributes.mode:
                    # model 0TG025JG, subtype 2
                    if self._subtype > 0:
                        self._attributes[attr] = MideaB0Device._mode31.get(value)
                    else:
                        self._attributes[attr] = MideaB0Device._mode.get(value)
                # fire_power
                elif attr == DeviceAttributes.fire_power:
                    # model 0TG025JG, subtype 2
                    if self._subtype > 0:
                        self._attributes[attr] = MideaB0Device._fire_power31.get(value)
                    else:
                        self._attributes[attr] = value
                else:
                    self._attributes[attr] = value
                new_status[str(attr)] = self._attributes[attr]
        return new_status

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """B0 Midea device set attribute."""


class MideaAppliance(MideaB0Device):
    """B0 Midea appliance."""
