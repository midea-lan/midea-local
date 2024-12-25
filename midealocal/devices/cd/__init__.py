"""Midea local CD device."""

import json
import logging
from enum import IntEnum, StrEnum
from typing import Any, ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import MessageCDResponse, MessageQuery, MessageSet

_LOGGER = logging.getLogger(__name__)


class CDSubType(IntEnum):
    """CD Device sub type."""

    T186 = 186


class LuaProtocol(StrEnum):
    """Lua protocol."""

    auto = "auto"  # default is auto
    old = "old"  # true
    new = "new"  # false


class DeviceAttributes(StrEnum):
    """Midea CD device attributes."""

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
    water_level = "water_level"
    fahrenheit = "fahrenheit"


class MideaCDDevice(MideaDevice):
    """Midea CD device."""

    _modes: ClassVar[dict[int, str]] = {
        0x00: "None",
        0x01: "Energy-save",
        0x02: "Standard",
        0x03: "Dual",
        0x04: "Smart",
        0x05: "Vacation",
    }

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
        customize: str,
    ) -> None:
        """Initialize Midea CD device."""
        super().__init__(
            name=name,
            device_id=device_id,
            device_type=DeviceType.CD,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.max_temperature: 65,
                DeviceAttributes.min_temperature: 35,
                DeviceAttributes.target_temperature: 40,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.outdoor_temperature: None,
                DeviceAttributes.condenser_temperature: None,
                DeviceAttributes.compressor_temperature: None,
                DeviceAttributes.compressor_status: None,
                DeviceAttributes.water_level: None,
                DeviceAttributes.fahrenheit: False,
            },
        )
        self._fields: dict[Any, Any] = {}
        self._temperature_step: float | None = None
        self._default_temperature_step = 1
        # customize lua_protocol
        self._default_lua_protocol = LuaProtocol.auto
        self._lua_protocol = self._default_lua_protocol
        # fahrenheit or celsius switch, default is celsius, update with message
        self._fahrenheit: bool = False
        self.set_customize(customize)

    def _value_to_temperature(self, value: float) -> float:
        # fahrenheit to celsius
        if self._fahrenheit:
            return (value - 32) * 5.0 / 9.0
        # celsius
        # old protocol
        if self._lua_protocol == LuaProtocol.old:
            return round((value - 30) / 2)
        # new protocol
        return value

    def _temperature_to_value(self, value: float) -> float:
        # fahrenheit to celsius
        if self._fahrenheit:
            return value * 9.0 / 5.0 + 32
        # celsius
        # old protocol
        if self._lua_protocol == LuaProtocol.old:
            return round(value * 2 + 30)
        # new protocol
        return value

    def _normalize_lua_protocol(self, value: str | bool | int) -> LuaProtocol:
        # current only have str
        if isinstance(value, str):
            return_value = LuaProtocol(value)
            # auto mode, use subtype to set value as old or new
            if return_value == LuaProtocol.auto:
                # new protocol, [subtype0, model RSJRAC01] [subtype186, model RSJ000CB]
                # old protocol. current subtype is unknown, to be done.
                check_device = (
                    self.subtype == CDSubType.T186 or self.model == "RSJRAC01",
                )
                return_value = LuaProtocol.new if check_device else LuaProtocol.old
        if isinstance(value, bool | int):
            return_value = LuaProtocol.new if value else LuaProtocol.old
        return return_value

    @property
    def temperature_step(self) -> float | None:
        """Midea CD device temperature step."""
        return self._temperature_step

    @property
    def preset_modes(self) -> list[str]:
        """Midea CD device preset modes."""
        return list(MideaCDDevice._modes.values())

    def build_query(self) -> list[MessageQuery]:
        """Midea CD device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea CD device process message."""
        message = MessageCDResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        if hasattr(message, "fields"):
            self._fields = message.fields
        # parse fahrenheit switch for temperature value
        if hasattr(message, DeviceAttributes.fahrenheit):
            self._fahrenheit = getattr(message, DeviceAttributes.fahrenheit)
        for attr in self._attributes:
            if hasattr(message, str(attr)):
                value = getattr(message, str(attr))
                # parse modes
                if attr == DeviceAttributes.mode:
                    self._attributes[attr] = MideaCDDevice._modes.get(value, value)
                # process temperature
                elif attr in [
                    DeviceAttributes.max_temperature,
                    DeviceAttributes.min_temperature,
                    DeviceAttributes.target_temperature,
                    DeviceAttributes.current_temperature,
                    DeviceAttributes.outdoor_temperature,
                    DeviceAttributes.condenser_temperature,
                    DeviceAttributes.compressor_temperature,
                ]:
                    self._attributes[attr] = self._value_to_temperature(value)
                else:
                    self._attributes[attr] = value
                new_status[str(attr)] = self._attributes[attr]
        return new_status

    def set_attribute(self, attr: str, value: str | float | bool) -> None:
        """Midea CD device set attribute."""
        if attr in [
            DeviceAttributes.mode,
            DeviceAttributes.power,
            DeviceAttributes.target_temperature,
        ]:
            message = MessageSet(self._message_protocol_version)
            message.fields = self._fields
            message.mode = self._attributes[DeviceAttributes.mode]
            message.power = self._attributes[DeviceAttributes.power]
            message.target_temperature = self._attributes[
                DeviceAttributes.target_temperature
            ]
            # process modes value to str
            if attr == DeviceAttributes.mode:
                value = int(value)
                setattr(message, str(attr), MideaCDDevice._modes.get(value, value))
            # process target temperature to data value
            elif attr == DeviceAttributes.target_temperature:
                setattr(message, str(attr), self._temperature_to_value(float(value)))
            else:
                setattr(message, str(attr), value)
            self.build_send(message)

    def set_customize(self, customize: str) -> None:
        """Midea CD device set customize."""
        self._temperature_step = self._default_temperature_step
        self._lua_protocol = self._default_lua_protocol
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "temperature_step" in params:
                    self._temperature_step = params.get("temperature_step")
                if params and "lua_protocol" in params:
                    self._lua_protocol = self._normalize_lua_protocol(
                        params["lua_protocol"],
                    )
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
            self.update_all(
                {
                    "temperature_step": self._temperature_step,
                    "lua_protocol": self._lua_protocol,
                },
            )


class MideaAppliance(MideaCDDevice):
    """Midea CD appliance."""
