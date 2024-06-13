import json
import logging
import sys
from typing import Any

from .message import (
    MessageE2Response,
    MessageNewProtocolSet,
    MessagePower,
    MessageQuery,
    MessageSet,
)

if sys.version_info < (3, 12):
    from midealocal.backports.enum import StrEnum
else:
    from enum import StrEnum

from midealocal.device import MideaDevice


class OldProtocol(StrEnum):
    auto = "auto"
    true = "true"
    false = "false"


_LOGGER = logging.getLogger(__name__)


class DeviceAttributes(StrEnum):
    power = "power"
    heating = "heating"
    keep_warm = "keep_warm"
    protection = "protection"
    current_temperature = "current_temperature"
    target_temperature = "target_temperature"
    whole_tank_heating = "whole_tank_heating"
    variable_heating = "variable_heating"
    heating_time_remaining = "heating_time_remaining"
    water_consumption = "water_consumption"
    heating_power = "heating_power"


class MideaE2Device(MideaDevice):
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
            device_type=0xE2,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            protocol=protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.heating: False,
                DeviceAttributes.keep_warm: False,
                DeviceAttributes.protection: False,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.target_temperature: 40,
                DeviceAttributes.whole_tank_heating: False,
                DeviceAttributes.variable_heating: False,
                DeviceAttributes.heating_time_remaining: 0,
                DeviceAttributes.water_consumption: None,
                DeviceAttributes.heating_power: None,
            },
        )
        self._default_old_protocol = OldProtocol.auto
        self._old_protocol = self._default_old_protocol
        self.set_customize(customize)

    def _normalize_old_protocol(self, value: Any) -> OldProtocol:
        try:
            if isinstance(value, str):
                return_value = OldProtocol(value)
                if return_value == OldProtocol.auto:
                    result = (
                        self.subtype <= 82
                        or self.subtype == 85
                        or self.subtype == 36353
                    )
                    return_value = OldProtocol.true if result else OldProtocol.false
            elif isinstance(value, bool | int):
                return_value = OldProtocol.true if value else OldProtocol.false
            else:
                raise ValueError("Invalid value for old_protocol")
            return return_value
        except ValueError as e:
            _LOGGER.error(f"Invalid old_protocol value: {value}, error: {e}")
            return self._default_old_protocol

    def build_query(self) -> list[MessageQuery]:
        return [MessageQuery(self._protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        message = MessageE2Response(msg)
        _LOGGER.debug(f"[{self.device_id}] Received: {message}")
        new_status = {}
        for status in self._attributes.keys():
            if hasattr(message, str(status)):
                self._attributes[status] = getattr(message, str(status))
                new_status[str(status)] = getattr(message, str(status))
        return new_status

    def make_message_set(self) -> MessageSet:
        message = MessageSet(self._protocol_version)
        message.protection = self._attributes[DeviceAttributes.protection]
        message.whole_tank_heating = self._attributes[
            DeviceAttributes.whole_tank_heating
        ]
        message.target_temperature = self._attributes[
            DeviceAttributes.target_temperature
        ]
        message.variable_heating = self._attributes[DeviceAttributes.variable_heating]
        return message

    def set_attribute(self, attr: str, value: Any) -> None:
        message: MessagePower | MessageSet | MessageNewProtocolSet | None = None
        if attr not in [
            DeviceAttributes.heating,
            DeviceAttributes.keep_warm,
            DeviceAttributes.current_temperature,
        ]:
            old_protocol = self._normalize_old_protocol(self._old_protocol)
            if attr == DeviceAttributes.power:
                message = MessagePower(self._protocol_version)
                message.power = value
            elif old_protocol == OldProtocol.true:
                message = self.make_message_set()
                setattr(message, str(attr), value)
            else:
                message = MessageNewProtocolSet(self._protocol_version)
                setattr(message, str(attr), value)
            self.build_send(message)

    def set_customize(self, customize: str) -> None:
        self._old_protocol = self._default_old_protocol
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "old_protocol" in params:
                    self._old_protocol = self._normalize_old_protocol(
                        params["old_protocol"],
                    )
            except Exception as e:
                _LOGGER.error(f"[{self.device_id}] Set customize error: {e!r}")
            self.update_all({"old_protocol": self._old_protocol})


class MideaAppliance(MideaE2Device):
    pass
