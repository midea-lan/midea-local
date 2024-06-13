import logging
import sys
from typing import Any

from .message import MessageE6Response, MessageQuery, MessageSet

if sys.version_info < (3, 12):
    from midealocal.backports.enum import StrEnum
else:
    from enum import StrEnum

from midealocal.device import MideaDevice

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    main_power = "main_power"
    heating_power = "heating_power"
    heating_working = "heating_working"
    bathing_working = "bathing_working"
    min_temperature = "temperature_min"
    max_temperature = "temperature_max"
    heating_temperature = "heating_temperature"
    bathing_temperature = "bathing_temperature"
    heating_leaving_temperature = "heating_leaving_temperature"
    bathing_leaving_temperature = "bathing_leaving_temperature"


class MideaE6Device(MideaDevice):
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
            device_type=0xE6,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            protocol=protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.main_power: False,
                DeviceAttributes.heating_power: True,
                DeviceAttributes.heating_working: None,
                DeviceAttributes.bathing_working: None,
                DeviceAttributes.min_temperature: [30, 35],
                DeviceAttributes.max_temperature: [80, 60],
                DeviceAttributes.heating_temperature: 50,
                DeviceAttributes.bathing_temperature: 40,
                DeviceAttributes.heating_leaving_temperature: None,
                DeviceAttributes.bathing_leaving_temperature: None,
            },
        )

    def build_query(self) -> list[MessageQuery]:
        return [MessageQuery(self._protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        message = MessageE6Response(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        for status in self._attributes.keys():
            if hasattr(message, str(status)):
                self._attributes[status] = getattr(message, str(status))
                new_status[str(status)] = self._attributes[status]
        return new_status

    def set_attribute(self, attr: str, value: Any) -> None:
        if attr in [
            DeviceAttributes.main_power,
            DeviceAttributes.heating_power,
            DeviceAttributes.heating_temperature,
            DeviceAttributes.bathing_temperature,
        ]:
            message = MessageSet(self._protocol_version)
            setattr(message, str(attr), value)
            self.build_send(message)


class MideaAppliance(MideaE6Device):
    pass
