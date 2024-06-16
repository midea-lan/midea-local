"""Midea local x40 device."""

import logging
import math
from enum import StrEnum
from typing import Any, ClassVar

from midealocal.device import MideaDevice

from .message import Message40Response, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)

DIRECTION_MIN_VALUE = 60
DIRECTION_MAX_VALUE = 100
VENTILATION_FAN_SPEED = 2


class DeviceAttributes(StrEnum):
    """Midea x40 device attributes."""

    light = "light"
    fan_speed = "fan_speed"
    direction = "direction"
    ventilation = "ventilation"
    smelly_sensor = "smelly_sensor"
    current_temperature = "current_temperature"


class Midea40Device(MideaDevice):
    """Midea x40 Device."""

    _directions: ClassVar[list[str]] = ["60", "70", "80", "90", "100", "Oscillate"]

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
        """Initialize Midea x40 Device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=0x40,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            protocol=protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.light: False,
                DeviceAttributes.fan_speed: 0,
                DeviceAttributes.direction: False,
                DeviceAttributes.ventilation: False,
                DeviceAttributes.smelly_sensor: False,
                DeviceAttributes.current_temperature: None,
            },
        )
        self._fields: dict[str, Any] = {}

    @property
    def directions(self) -> list[str]:
        """Midea x40 device directions."""
        return Midea40Device._directions

    @staticmethod
    def _convert_to_midea_direction(direction: str) -> int:
        if direction == "Oscillate":
            result = 0xFD
        else:
            result = (
                Midea40Device._directions.index(direction) * 10 + 60
                if direction in Midea40Device._directions
                else 0xFD
            )
        return result

    @staticmethod
    def _convert_from_midea_direction(direction: int) -> int:
        if direction > DIRECTION_MAX_VALUE or direction < DIRECTION_MIN_VALUE:
            result = 5
        else:
            result = math.floor((direction - 60 + 5) / 10)
        return result

    def build_query(self) -> list[MessageQuery]:
        """Midea x40 Device build query."""
        return [MessageQuery(self._protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea x40 Device process message."""
        message = Message40Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        self._fields = message.fields
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                if status == DeviceAttributes.direction:
                    self._attributes[status] = Midea40Device._directions[
                        self._convert_from_midea_direction(value)
                    ]
                else:
                    self._attributes[status] = value
                new_status[str(status)] = self._attributes[status]
        return new_status

    def set_attribute(self, attr: str, value: int | str | bool) -> None:
        """Midea x40 Device set attribute."""
        if attr in [
            DeviceAttributes.light,
            DeviceAttributes.fan_speed,
            DeviceAttributes.direction,
            DeviceAttributes.ventilation,
            DeviceAttributes.smelly_sensor,
        ]:
            message = MessageSet(self._protocol_version)
            message.fields = self._fields
            message.light = self._attributes[DeviceAttributes.light]
            message.ventilation = self._attributes[DeviceAttributes.ventilation]
            message.smelly_sensor = self._attributes[DeviceAttributes.smelly_sensor]
            message.fan_speed = self._attributes[DeviceAttributes.fan_speed]
            message.direction = self._convert_to_midea_direction(
                self._attributes[DeviceAttributes.direction],
            )
            if attr == DeviceAttributes.direction:
                message.direction = self._convert_to_midea_direction(str(value))
            elif (
                attr == DeviceAttributes.ventilation
                and message.fan_speed == VENTILATION_FAN_SPEED
            ):
                message.fan_speed = 1
                message.ventilation = bool(value)
            else:
                setattr(message, str(attr), value)
            self.build_send(message)


class MideaAppliance(Midea40Device):
    """Midea x40 appliance."""
