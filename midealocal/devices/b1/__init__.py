"""Midea local B1 device."""

import logging
from enum import StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs
from midealocal.message import ListTypes

from .message import (
    X31_SUBTYPE,
    MessageB1Response,
    MessageQuery,
    MessageQueryX01,
    MessageQueryX31,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea local B1 device attribute."""

    door = "door"
    status = "status"
    mode = "mode"
    program = "program"
    time_remaining = "time_remaining"
    current_temperature = "current_temperature"
    target_temperature = "target_temperature"
    tank_ejected = "tank_ejected"
    water_change_reminder = "water_change_reminder"
    water_shortage = "water_shortage"


class MideaB1Device(MideaDevice):
    """Midea B1 device.

    The 0TVN50R6 programme names come from
    ``lua/b1/T_0000_B1_0TVN50R6_LATEST.lua``. Subtype 5 programme names
    come from ``lua/b1/T_0000_B1_4.lua``; its ``stero_baking`` spelling
    is normalised to ``stereo_baking``.
    """

    _status: ClassVar[dict[int, str]] = {
        0x01: "standby",
        0x02: "idle",
        0x03: "working",
        0x04: "finished",
        0x05: "delay",
        0x06: "paused",
    }

    _programs_711001f5: ClassVar[dict[tuple[int, int], str]] = {
        (83, 1): "conventional",
        (84, 1): "convection",
        (95, 0): "conventional_fan",
        (102, 0): "radiant_heat",
        (99, 0): "double_grill_fan",
        (103, 0): "double_grill",
        (87, 0): "pizza",
        (82, 1): "bottom_heat",
        (162, 0): "eco",
        (94, 0): "keep_warm",
        (164, 0): "defrost",
        (88, 0): "fermentation",
        (83, 9): "aqua_clean",
        (95, 1): "air_baking",
    }

    _programs_0tvn50r6: ClassVar[dict[int, str]] = {
        0x01: "microwave",
        0x02: "brittle",
        0x20: "pure_steam",
        0x21: "hot_steam",
        0x40: "above_tube",
        0x41: "hot_wind_bake",
        0x42: "underside_tube_hot_wind_bake",
        0x44: "cube_baking",
        0x46: "core_baking",
        0x47: "total_baking",
        0x49: "underside_tube",
        0x4C: "double_tube",
        0x4E: "revolve_bake",
        0x51: "double_upside_tube_fan",
        0x52: "double_tube_fan",
        0x70: "fast_baking",
        0x90: "fast_steam",
        0xA0: "unfreeze",
        0xA1: "unfreeze_t",
        0xB0: "zymosis",
        0xC0: "smart_clean",
        0xC1: "scale_clean",
        0xC2: "metal_sterilize",
        0xC3: "remove_odor",
        0xC4: "dry",
        0xD0: "warm",
        0xE0: "auto_menu",
    }

    _programs_subtype5: ClassVar[dict[int, str]] = {
        0xD0: "keep_warm",
        0x44: "stereo_baking",
        0x47: "whole_baking",
        0x4C: "up_down_baking",
        0xA1: "unfreeze",
        0x41: "hot_air_convection",
        0x4D: "power_saving",
        0x46: "center_baking",
        0x4E: "rotary_baking",
        0xB0: "fermentation",
        0xC4: "stoving",
        0x49: "down_baking",
        0xB1: "pizza",
        0x51: "up_infrared_fan",
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
                DeviceAttributes.mode: None,
                DeviceAttributes.program: None,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.target_temperature: None,
                DeviceAttributes.tank_ejected: False,
                DeviceAttributes.water_change_reminder: False,
                DeviceAttributes.water_shortage: False,
            },
        )

    def build_query(self) -> list[MessageQuery | MessageQueryX01 | MessageQueryX31]:
        """Midea B1 device build query.

        Some B1 devices report the X00 ``MessageQuery`` as an unsupported
        protocol and never respond to it, leaving the device with no
        working query at all. X01 is included as a fallback - see
        ``MessageQueryX01``/``B1Message01Body``.

        Model 0TVN50R6 and subtype 5 use the X31 queries documented in
        their Lua files, with different request body lengths.
        """
        if self.model == "0TVN50R6" or self._subtype == X31_SUBTYPE:
            return [
                MessageQueryX31(
                    self._message_protocol_version,
                    padded=self.model == "0TVN50R6",
                ),
            ]
        return [
            MessageQuery(self._message_protocol_version),
            MessageQueryX01(self._message_protocol_version),
        ]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea B1 device process message."""
        message = MessageB1Response(msg, model=self.model, subtype=self._subtype)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        updates = self.update_attributes_from_message(
            message,
            {DeviceAttributes.status: MideaB1Device._status.get},
        )

        mode = getattr(message, "mode", None)
        variant = getattr(message, "program_variant", None)
        if isinstance(mode, int):
            program = None
            if (
                message.body_type == ListTypes.X01
                and self.model == "711001F5"
                and self._subtype == 0
                and isinstance(variant, int)
            ):
                program = self._programs_711001f5.get((mode, variant))
            elif message.body_type == ListTypes.X31:
                if self.model == "0TVN50R6":
                    program = self._programs_0tvn50r6.get(mode)
                elif self._subtype == X31_SUBTYPE:
                    program = self._programs_subtype5.get(mode)
            self._attributes[DeviceAttributes.program] = program
            updates[DeviceAttributes.program.value] = program

        return updates

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea B1 device set attribute."""


class MideaAppliance(MideaB1Device):
    """Midea B1 appliance."""
