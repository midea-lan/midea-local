import logging
import sys
from typing import Any

from .message import MessageCFResponse, MessageQuery, MessageSet

if sys.version_info < (3, 12):
    from midealocal.backports.enum import StrEnum
else:
    from enum import StrEnum

from midealocal.device import MideaDevice

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    power = "power"
    mode = "mode"
    target_temperature = "target_temperature"
    aux_heating = "aux_heating"
    current_temperature = "current_temperature"
    max_temperature = "max_temperature"
    min_temperature = "min_temperature"


class MideaCFDevice(MideaDevice):
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
            device_type=0xCF,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            protocol=protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.target_temperature: None,
                DeviceAttributes.aux_heating: False,
                DeviceAttributes.current_temperature: 0,
                DeviceAttributes.max_temperature: 55,
                DeviceAttributes.min_temperature: 5,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        return [MessageQuery(self._protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        message = MessageCFResponse(msg)
        _LOGGER.debug(f"[{self.device_id}] Received: {message}")
        new_status = {}
        for status in self._attributes.keys():
            if hasattr(message, str(status)):
                self._attributes[status] = getattr(message, str(status))
                new_status[str(status)] = getattr(message, str(status))
        return new_status

    def set_target_temperature(self, target_temperature: int, mode: int) -> None:
        message = MessageSet(self._protocol_version)
        message.power = True
        message.mode = self._attributes[DeviceAttributes.mode]
        message.target_temperature = target_temperature
        if mode is not None:
            message.mode = mode
        self.build_send(message)

    def set_attribute(self, attr: str, value: Any) -> None:
        message = MessageSet(self._protocol_version)
        message.power = True
        message.mode = self._attributes[DeviceAttributes.mode]
        if attr == DeviceAttributes.power:
            message.power = value
        elif attr == DeviceAttributes.mode:
            message.power = True
            message.mode = value
        elif attr == DeviceAttributes.target_temperature:
            message.target_temperature = value
        elif attr == DeviceAttributes.aux_heating:
            message.aux_heating = value
        self.build_send(message)


class MideaAppliance(MideaCFDevice):
    pass
