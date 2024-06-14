import json
import logging
import sys
from typing import Any, ClassVar

from .message import MessageCDResponse, MessageQuery, MessageSet

if sys.version_info < (3, 12):
    from midealocal.backports.enum import StrEnum
else:
    from enum import StrEnum


from midealocal.device import MideaDevice

_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    power = "power"
    mode = "mode"
    max_temperature = "max_temperature"
    min_temperature = "min_temperature"
    target_temperature = "target_temperature"
    current_temperature = "current_temperature"
    outdoor_temperature = "outdoor_temperature"
    condenser_temperature = "condenser_temperature"
    compressor_temperature = "compressor_temperature"
    compressor_status = "compressor_status"


class MideaCDDevice(MideaDevice):
    _modes: ClassVar[list[str]] = ["Energy-save", "Standard", "Dual", "Smart"]

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
            device_type=0xCD,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            protocol=protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.mode: None,
                DeviceAttributes.max_temperature: 65,
                DeviceAttributes.min_temperature: 35,
                DeviceAttributes.target_temperature: 40,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.outdoor_temperature: None,
                DeviceAttributes.condenser_temperature: None,
                DeviceAttributes.compressor_temperature: None,
                DeviceAttributes.compressor_status: None,
            },
        )
        self._fields: dict[Any, Any] = {}
        self._temperature_step: float | None = None
        self._default_temperature_step = 1
        self.set_customize(customize)

    @property
    def temperature_step(self) -> float | None:
        return self._temperature_step

    @property
    def preset_modes(self) -> list[str]:
        return MideaCDDevice._modes

    def build_query(self) -> list[MessageQuery]:
        return [MessageQuery(self._protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        message = MessageCDResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        if hasattr(message, "fields"):
            self._fields = message.fields
        for status in self._attributes:
            if hasattr(message, str(status)):
                value = getattr(message, str(status))
                if status == DeviceAttributes.mode:
                    self._attributes[status] = MideaCDDevice._modes[value]
                else:
                    self._attributes[status] = value
                new_status[str(status)] = self._attributes[status]
        return new_status

    def set_attribute(self, attr: str, value: Any) -> None:
        if attr in [
            DeviceAttributes.mode,
            DeviceAttributes.power,
            DeviceAttributes.target_temperature,
        ]:
            message = MessageSet(self._protocol_version)
            message.fields = self._fields
            message.mode = MideaCDDevice._modes.index(
                self._attributes[DeviceAttributes.mode],
            )
            message.power = self._attributes[DeviceAttributes.power]
            message.target_temperature = self._attributes[
                DeviceAttributes.target_temperature
            ]
            if attr == DeviceAttributes.mode:
                if value in MideaCDDevice._modes:
                    setattr(message, str(attr), MideaCDDevice._modes.index(value))
            else:
                setattr(message, str(attr), value)
            self.build_send(message)

    def set_customize(self, customize: str) -> None:
        self._temperature_step = self._default_temperature_step
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "temperature_step" in params:
                    self._temperature_step = params.get("temperature_step")
            except Exception as e:
                _LOGGER.error("[%s] Set customize error: %s", self.device_id, repr(e))
            self.update_all({"temperature_step": self._temperature_step})


class MideaAppliance(MideaCDDevice):
    pass
