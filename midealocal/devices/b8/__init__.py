"""Midea local B8 device."""

import logging
from enum import IntEnum
from typing import Any

from midealocal.device import MideaDevice
from midealocal.devices.b8.const import (
    B8CleanMode,
    B8ControlType,
    B8DeviceAttributes,
    B8ErrorType,
    B8FanLevel,
    B8MopState,
    B8Moviment,
    B8WaterLevel,
)
from midealocal.devices.b8.message import (
    MessageB8Response,
    MessageQuery,
    MessageSet,
)

_LOGGER = logging.getLogger(__name__)


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
                B8DeviceAttributes.WORK_STATUS: None,
                B8DeviceAttributes.FUNCTION_TYPE: None,
                B8DeviceAttributes.CONTROL_TYPE: B8ControlType.NONE,
                B8DeviceAttributes.MOVE_DIRECTION: B8Moviment.NONE,
                B8DeviceAttributes.CLEAN_MODE: B8CleanMode.NONE,
                B8DeviceAttributes.FAN_LEVEL: B8FanLevel.OFF,
                B8DeviceAttributes.AREA: None,
                B8DeviceAttributes.WATER_LEVEL: B8WaterLevel.OFF,
                B8DeviceAttributes.VOICE_VOLUME: 0,
                B8DeviceAttributes.MOP: B8MopState.OFF,
                B8DeviceAttributes.CARPET_SWITCH: False,
                B8DeviceAttributes.SPEED: None,
                B8DeviceAttributes.HAVE_RESERVE_TASK: False,
                B8DeviceAttributes.BATTERY_PERCENT: 0,
                B8DeviceAttributes.WORK_TIME: 0,
                B8DeviceAttributes.UV_SWITCH: False,
                B8DeviceAttributes.WIFI_SWITCH: False,
                B8DeviceAttributes.VOICE_SWITCH: False,
                B8DeviceAttributes.COMMAND_SOURCE: False,
                B8DeviceAttributes.ERROR_TYPE: B8ErrorType.NO,
                B8DeviceAttributes.ERROR_DESC: None,
                B8DeviceAttributes.DEVICE_ERROR: False,
                B8DeviceAttributes.BOARD_COMMUNICATION_ERROR: False,
                B8DeviceAttributes.LASER_SENSOR_SHELTER: False,
                B8DeviceAttributes.LASER_SENSOR_ERROR: False,
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

    def _gen_set_msg_default_values(self) -> MessageSet:
        msg = MessageSet(self._protocol_version)
        msg.clean_mode = self.attributes[B8DeviceAttributes.CLEAN_MODE]
        msg.fan_level = self.attributes[B8DeviceAttributes.FAN_LEVEL]
        msg.water_level = self.attributes[B8DeviceAttributes.WATER_LEVEL]
        msg.voice_volume = self.attributes[B8DeviceAttributes.VOICE_VOLUME]
        return msg

    def set_attribute(self, attr: str, value: bool | int | str) -> None:
        """Midea B8 device set attribute."""
        msg = self._gen_set_msg_default_values()
        if attr == B8DeviceAttributes.CLEAN_MODE:
            msg.clean_mode = B8CleanMode[str(value).upper()]
        elif attr == B8DeviceAttributes.FAN_LEVEL:
            msg.fan_level = B8FanLevel[str(value).upper()]
        elif attr == B8DeviceAttributes.WATER_LEVEL:
            msg.water_level = B8WaterLevel[str(value).upper()]
        elif attr == B8DeviceAttributes.VOICE_VOLUME:
            msg.voice_volume = int(value)

        if msg is not None:
            self.build_send(msg)


class MideaAppliance(MideaB8Device):
    """Midea B8 appliance."""
