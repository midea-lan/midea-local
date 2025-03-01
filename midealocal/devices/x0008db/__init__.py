"""Midea local DB device."""

import json
import logging
from enum import StrEnum
from typing import Any

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice
from midealocal.devices.x0008db.lua_converter import LuaConverter
from midealocal.exceptions import ValueWrongType
from .message import MessageQuery

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea DB device attributes."""

    machine_status = "machine_status"
    mode = "mode"
    door_open = "door_open"
    detergent_remain = "detergent_remain"
    softner_remain = "softner_remain"
    program = "program"
    dry_filter_clean = "dry_filter_clean"
    drain_filter_clean = "drain_filter_clean"
    over_capacity = "over_capacity"
    fungus_protect = "fungus_protect"
    remain_time = "remain_time"

class MideaDBDevice(MideaDevice):
    """Midea DB device."""

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
                DeviceAttributes.machine_status: "power_off", # power_off | power_on | running | pause | finish | pop_up
                DeviceAttributes.mode: "none", # none | wash_dry | wash | dry | clean_care | care
                DeviceAttributes.door_open: 0, # 0: closed, 1: open
                DeviceAttributes.detergent_remain: None,
                DeviceAttributes.softner_remain: None,
                DeviceAttributes.program: "none", # none | standard | tub_clean | fast | careful | sixty_wash | blanket | delicate | tub_clean_dry | memory | sterilization | mute | soft | delicate_dryer | wool | quick_dry | quick_dry_delicate | quick_dry_blanket | quick_dry_delicate_blanket | quick_dry_sterilization | quick_dry_mute | quick_dry_soft | quick_dry_delicate | quick_dry_blanket_delicate | quick_dry_sterilization_blanket | quick_dry_sterilization_blanket_delicate
                DeviceAttributes.dry_filter_clean: 0, # 0: clean, 1: dirty
                DeviceAttributes.drain_filter_clean: 0, # 0: clean, 1: dirty
                DeviceAttributes.over_capacity: 0, # 0: normal, 1: over capacity
                DeviceAttributes.fungus_protect: "off", # off | on
                DeviceAttributes.remain_time: 0,
            },
        )
        self._appliance_query = False

    def build_query(self) -> list[MessageQuery]:
        """Midea DB device build query."""
        return [MessageQuery()]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea DB device process message."""
        raw_data = bytearray(msg).hex()
        _LOGGER.debug("[%s] Received raw data: %s", self.device_id, raw_data)
        lua = LuaConverter()
        json_string = lua.data_to_json(raw_data)
        message = json.loads(json_string)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        data = message.get("status", {})
        new_status = {}

        for field in self._attributes:
            field_str = str(field)
            if field_str in data:
                self._attributes[field] = data[field]
                new_status[field] = self._attributes[field]
            else:
                _LOGGER.warning("[%s] Field %s not found in data", self.device_id, field)
                _LOGGER.debug("[%s] Available data fields: %s", self.device_id, list(data.keys()))

        return new_status

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea DB device set attribute."""
        # not supported yet

class MideaAppliance(MideaDBDevice):
    """Midea DB appliance."""
