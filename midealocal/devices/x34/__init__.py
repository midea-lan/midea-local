"""Midea local x35 device."""

import logging
from enum import StrEnum
from typing import Any, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs, list_translator
from midealocal.exceptions import ValueWrongType

from .message import (
    Message34Response,
    MessageLock,
    MessagePower,
    MessageQuery,
    MessageStorage,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea x34 device attributes."""

    power = "power"
    status = "status"
    mode = "mode"
    additional = "additional"
    door = "door"
    rinse_aid = "rinse_aid"
    salt = "salt"
    child_lock = "child_lock"
    uv = "uv"
    dry = "dry"
    dry_status = "dry_status"
    storage = "storage"
    storage_status = "storage_status"
    time_remaining = "time_remaining"
    progress = "progress"
    storage_remaining = "storage_remaining"
    temperature = "temperature"
    humidity = "humidity"
    waterswitch = "waterswitch"
    water_lack = "water_lack"
    error_code = "error_code"
    softwater = "softwater"
    wrong_operation = "wrong_operation"
    bright = "bright"


class Midea34Device(MideaDevice):
    """Midea x34 device."""

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea x34 device."""
        super().__init__(
            device_type=DeviceType.X34,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.status: None,
                DeviceAttributes.mode: 0,
                DeviceAttributes.additional: 0,
                DeviceAttributes.uv: False,
                DeviceAttributes.dry: False,
                DeviceAttributes.dry_status: False,
                DeviceAttributes.door: False,
                DeviceAttributes.rinse_aid: False,
                DeviceAttributes.salt: False,
                DeviceAttributes.child_lock: False,
                DeviceAttributes.storage: False,
                DeviceAttributes.storage_status: False,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.progress: None,
                DeviceAttributes.storage_remaining: None,
                DeviceAttributes.temperature: None,
                DeviceAttributes.humidity: None,
                DeviceAttributes.waterswitch: False,
                DeviceAttributes.water_lack: False,
                DeviceAttributes.error_code: None,
                DeviceAttributes.softwater: 0,
                DeviceAttributes.wrong_operation: None,
                DeviceAttributes.bright: 0,
            },
        )
        self._modes = {
            0x0: "neutral_gear",  # BYTE_MODE_NEUTRAL_GEAR
            0x1: "auto",  # BYTE_MODE_AUTO_WASH
            0x2: "heavy",  # BYTE_MODE_STRONG_WASH
            0x3: "normal",  # BYTE_MODE_STANDARD_WASH
            0x4: "energy_saving",  # BYTE_MODE_ECO_WASH
            0x5: "delicate",  # BYTE_MODE_GLASS_WASH
            0x6: "hour",  # BYTE_MODE_HOUR_WASH
            0x7: "quick",  # BYTE_MODE_FAST_WASH
            0x8: "rinse",  # BYTE_MODE_SOAK_WASH
            0x9: "90min",  # BYTE_MODE_90MIN_WASH
            0xA: "self_clean",  # BYTE_MODE_SELF_CLEAN
            0xB: "fruit_wash",  # BYTE_MODE_FRUIT_WASH
            0xC: "self_define",  # BYTE_MODE_SELF_DEFINE
            0xD: "germ",  # BYTE_MODE_GERM ???
            0xE: "bowl_wash",  # BYTE_MODE_BOWL_WASH
            0xF: "kill_germ",  # BYTE_MODE_KILL_GERM
            0x10: "sea_food_wash",  # BYTE_MODE_SEA_FOOD_WASH
            0x12: "hot_pot_wash",  # BYTE_MODE_HOT_POT_WASH
            0x13: "quiet",  # BYTE_MODE_QUIET_NIGHT_WASH
            0x14: "less_wash",  # BYTE_MODE_LESS_WASH
            0x16: "oil_net_wash",  # BYTE_MODE_OIL_NET_WASH
            0x19: "cloud_wash",  # BYTE_MODE_CLOUD_WASH
        }
        self._status = ["off", "idle", "delay", "running", "error"]
        self._progress = ["idle", "pre_wash", "wash", "rinse", "dry", "complete"]

    def build_query(self) -> list[MessageQuery]:
        """Midea x34 device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea x34 device process message."""
        message = Message34Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            {
                DeviceAttributes.status: list_translator(self._status),
                DeviceAttributes.progress: list_translator(self._progress),
                DeviceAttributes.mode: self._modes.get,
            },
        )

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea x34 device set attribute."""
        if not isinstance(value, bool):
            raise ValueWrongType("[x34] Expected bool")
        message: MessagePower | MessageLock | MessageStorage | None = None
        if attr == DeviceAttributes.power:
            message = MessagePower(self._message_protocol_version)
            message.power = value
            self.build_send(message)
        elif attr == DeviceAttributes.child_lock:
            message = MessageLock(self._message_protocol_version)
            message.lock = value
            self.build_send(message)
        elif attr == DeviceAttributes.storage:
            message = MessageStorage(self._message_protocol_version)
            message.storage = value
            self.build_send(message)


class MideaAppliance(Midea34Device):
    """Midea x34 appliance."""
