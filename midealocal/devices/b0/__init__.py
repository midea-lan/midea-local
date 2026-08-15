"""Midea local B0 device."""

import logging
from enum import StrEnum
from typing import TYPE_CHECKING, Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs, dict_translator
from midealocal.message import ListTypes

if TYPE_CHECKING:
    from collections.abc import Callable

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
        0x01: "cancel",
        0x02: "idle",
        0x03: "working",
        0x04: "finished",
        0x06: "order",
        0x07: "save_power",
        0x08: "heat",
        0x09: "three",
        0x0D: "reaction",
        0x66: "cloud",
        0xFF: "default",
    }

    _status31: ClassVar[dict[int, str]] = {
        0x01: "save_power",
        0x02: "idle",
        0x03: "working",
        0x04: "finished",
        0x05: "delay",
        0x06: "paused",
        0x07: "pause_cancel",
        0x08: "three",
        0xFF: "default",
    }

    _mode: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "microwave",
        0x02: "baking",
        0x03: "ferment",
        0x04: "unfreeze",
        0x05: "roast",
        0x06: "host_steam",
        0x07: "fast_steam",
        0x08: "fast_hot",
        0x09: "pure_steam",
        0x0A: "metal_sterilize",
        0x0B: "remove_odor",
        0x0C: "scale_clean",
        0x0D: "smart_clean",
        0x11: "smart_steam_fish",
        0x12: "rice",
        0x13: "steam_ribs",
        0x14: "code_to_hot",
        0x15: "wing",
        0x16: "kebab",
        0x18: "egg",
        0x19: "instant_noodle",
        0x1A: "vegetable",
        0x1B: "meat",
        0x1C: "tofu",
        0x1D: "chicken_soup",
        0x1E: "dumplings",
        0x1F: "porridge",
        0x20: "chicken_block",
        0x21: "pumpkin",
        0x22: "popcorn",
        0x23: "meat_eggplant",
        0x24: "bake_shrimp",
        0x25: "baby_milk",
        0x26: "baby_egg",
        0x27: "carrots",
        0x28: "baby_fruit",
        0x29: "snow_pear",
        0x2A: "papaya_milk",
        0x2B: "jujube_longan",
        0x2C: "lotus_seed",
        0x2D: "fast_soup",
        0x2E: "sirloin",
        0x2F: "coconut_sogo",
        0x30: "meat_tofu",
        0x31: "spicy_tofu",
        0x32: "sauted_meat",
        0x33: "steam_corn",
        0x34: "pearl_meat",
        0x35: "bun",
        0x36: "coix_bean",
        0x37: "bake_ribs",
        0x38: "sausage",
        0x39: "bake_cake",
        0x3A: "bake_cookies",
        0x3B: "sweet_potato",
        0x3C: "steam_seafood",
        0x3D: "fans_scallops",
        0x3E: "steam_bun",
        0x3F: "sauerkraut_fish",
        0x41: "warm",
        0x42: "pre_hot",
        0x43: "baking",
        0x44: "brittle",
        0x50: "frozen_food",
        0x51: "milk_coffee",
        0x52: "spicy_sausage",
        0x53: "bake_swing",
        0x54: "pure_steam_fish",
    }

    _mode31: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "microwave",
        0x40: "above_tube",
        0xA0: "unfreeze",
        0xA1: "time_unfreeze",
        0xC3: "remove_odor",
        0xE0: "auto",
        0xE2: "humidity_auto",
        0xFF: "default",
    }

    _fire_power31: ClassVar[dict[int, str]] = {
        0x01: "low",
        0x03: "medium_low",
        0x05: "medium",
        0x08: "medium_high",
        0x0A: "high",
        0xFF: "default",
    }

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize B0 Midea device."""
        super().__init__(
            device_type=DeviceType.B0,
            **kwargs,
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
        # B0Message31Body's byte layout is specific to model 0TG025JG,
        # subtype 2. On subtype 0 devices this response still arrives, but
        # decoding it with the wrong layout produces garbage that
        # immediately overwrites the good data just received via the X01
        # response a moment earlier. Ignore X31 entirely for subtype 0.
        if self._subtype == 0 and message.body_type == ListTypes.X31:
            return {}
        # model 0TG025JG, subtype 2, uses the *31 tables instead
        use_v31_tables = self._subtype > 0
        translators: dict[str, Callable[[Any], str | float | bool | None]] = {
            DeviceAttributes.status: dict_translator(
                MideaB0Device._status31 if use_v31_tables else MideaB0Device._status,
                default=None,
            ),
            DeviceAttributes.mode: dict_translator(
                MideaB0Device._mode31 if use_v31_tables else MideaB0Device._mode,
                default=None,
            ),
        }
        if use_v31_tables:
            translators[DeviceAttributes.fire_power] = dict_translator(
                MideaB0Device._fire_power31,
                default=None,
            )
        return self.update_attributes_from_message(message, translators)

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """B0 Midea device set attribute."""


class MideaAppliance(MideaB0Device):
    """B0 Midea appliance."""
