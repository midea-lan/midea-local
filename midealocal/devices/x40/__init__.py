import logging
import math
import sys
from typing import Any

from midealocal.device import MideaDevice

from .message import Message40Response, MessageQuery, MessageSet

if sys.version_info < (3, 12):
    from midealocal.backports.enum import StrEnum
else:
    from enum import StrEnum


_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    light = "light"
    fan_speed = "fan_speed"
    direction = "direction"
    ventilation = "ventilation"
    smelly_sensor = "smelly_sensor"
    current_temperature = "current_temperature"


class Midea40Device(MideaDevice):
    _directions = ["60", "70", "80", "90", "100", "Oscillate"]

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
        customize: str,
    ) -> None:
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
        if direction > 100 or direction < 60:
            result = 5
        else:
            result = math.floor((direction - 60 + 5) / 10)
        return result

    def build_query(self) -> list[MessageQuery]:
        return [MessageQuery(self._protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
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

    def set_attribute(self, attr: str, value: Any) -> None:
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
                message.direction = self._convert_to_midea_direction(value)
            elif attr == DeviceAttributes.ventilation and message.fan_speed == 2:
                message.fan_speed = 1
                message.ventilation = value
            else:
                setattr(message, str(attr), value)
            self.build_send(message)


class MideaAppliance(Midea40Device):
    pass
