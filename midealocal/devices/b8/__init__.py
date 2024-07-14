"""Midea local B8 device."""

import logging
from enum import IntEnum, StrEnum
from typing import Any

from midealocal.device import MideaDevice

from .message import (
    CleanMode,
    ControlType,
    ErrorType,
    MessageB8Response,
    MessageQuery,
    MopState,
    Moviment,
)

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    """Midea B8 device attributes."""

    WORK_STATUS = "work_status"
    FUNCTION_TYPE = "function_type"
    CONTROL_TYPE = "control_type"
    MOVE_DIRECTION = "move_direction"
    CLEAN_MODE = "clean_mode"
    FAN_LEVEL = "fan_level"
    AREA = "area"
    WATER_LEVEL = "water_level"
    VOICE_VOLUME = "voice_volume"
    MOP = "mop"
    CARPET_SWITCH = "carpet_switch"
    SPEED = "speed"
    HAVE_RESERVE_TASK = "have_reserve_task"
    BATTERY_PERCENT = "battery_percent"
    WORK_TIME = "work_time"
    UV_SWITCH = "uv_switch"
    WIFI_SWITCH = "wifi_switch"
    VOICE_SWITCH = "voice_switch"
    COMMAND_SOURCE = "command_source"
    ERROR_TYPE = "error_type"
    ERROR_DESC = "error_desc"
    DEVICE_ERROR = "device_error"
    BOARD_COMMUNICATION_ERROR = "board_communication_error"
    LASER_SENSOR_SHELTER = "laser_sensor_shelter"
    LASER_SENSOR_ERROR = "laser_sensor_error"


class MideaB8Device(MideaDevice):
    """Midea B8 device."""

    def __init__(
        self,
        name: str,
        device_id: int,
        ip_address: str,
        port: int,
        token: str,
        key: str,
        protocol: int,
        model: str,
        subtype: int,
        customize: str,  # noqa: ARG002
    ) -> None:
        """Initialize Midea B8 device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=0xB8,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            protocol=protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.WORK_STATUS: None,
                DeviceAttributes.FUNCTION_TYPE: None,
                DeviceAttributes.CONTROL_TYPE: ControlType.NONE,
                DeviceAttributes.MOVE_DIRECTION: Moviment.NONE,
                DeviceAttributes.CLEAN_MODE: CleanMode.NONE,
                DeviceAttributes.FAN_LEVEL: None,
                DeviceAttributes.AREA: None,
                DeviceAttributes.WATER_LEVEL: None,
                DeviceAttributes.VOICE_VOLUME: 0,
                DeviceAttributes.MOP: MopState.OFF,
                DeviceAttributes.CARPET_SWITCH: False,
                DeviceAttributes.SPEED: None,
                DeviceAttributes.HAVE_RESERVE_TASK: False,
                DeviceAttributes.BATTERY_PERCENT: 0,
                DeviceAttributes.WORK_TIME: 0,
                DeviceAttributes.UV_SWITCH: False,
                DeviceAttributes.WIFI_SWITCH: False,
                DeviceAttributes.VOICE_SWITCH: False,
                DeviceAttributes.COMMAND_SOURCE: False,
                DeviceAttributes.ERROR_TYPE: ErrorType.NO,
                DeviceAttributes.ERROR_DESC: None,
                DeviceAttributes.DEVICE_ERROR: False,
                DeviceAttributes.BOARD_COMMUNICATION_ERROR: False,
                DeviceAttributes.LASER_SENSOR_SHELTER: False,
                DeviceAttributes.LASER_SENSOR_ERROR: False,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        """Midea B8 device build query."""
        return [MessageQuery(self._protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea B8 device process message."""
        message = MessageB8Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                if isinstance(value, IntEnum):  # lowercase name for IntEnums
                    value = value.name.lower()
                self._attributes[status] = value
                new_status[str(status)] = self._attributes[status]
        return new_status

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea B8 device set attribute."""


class MideaAppliance(MideaB8Device):
    """Midea B8 appliance."""
