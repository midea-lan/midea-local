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
    heat = "heat"
    dual_heat = "dual_heat"
    elec_heat = "elec_heat"
    top_elec_heat = "top_elec_heat"
    bottom_elec_heat = "bottom_elec_heat"
    water_pump = "water_pump"
    four_way = "four_way"
    back_water = "back_water"
    sterilize = "sterilize"
    disinfect = "disinfect"
    top_temperature = "top_temperature"
    bottom_temperature = "bottom_temperature"
    wind = "wind"
    smart_grid = "smart_grid"
    multi_terminal = "multi_terminal"
    mute_effect = "mute_effect"
    mute_status = "mute_status"
    error_code = "error_code"
    typeinfo = "typeinfo"
    vacation_mode = "vacation_mode"
    vacation_days = "vacation_days"


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
                DeviceAttributes.mode: None,
                DeviceAttributes.max_temperature: 65.0,
                DeviceAttributes.min_temperature: 35.0,
                DeviceAttributes.target_temperature: 40.0,
                DeviceAttributes.current_temperature: None,
                DeviceAttributes.outdoor_temperature: None,
                DeviceAttributes.condenser_temperature: None,
                DeviceAttributes.compressor_temperature: None,
                DeviceAttributes.compressor_status: None,
                DeviceAttributes.water_level: None,
                DeviceAttributes.fahrenheit: False,
                DeviceAttributes.heat: None,
                DeviceAttributes.dual_heat: None,
                DeviceAttributes.elec_heat: None,
                DeviceAttributes.top_elec_heat: None,
                DeviceAttributes.bottom_elec_heat: None,
                DeviceAttributes.water_pump: None,
                DeviceAttributes.four_way: None,
                DeviceAttributes.back_water: None,
                DeviceAttributes.sterilize: None,
                DeviceAttributes.disinfect: None,
                DeviceAttributes.top_temperature: None,
                DeviceAttributes.bottom_temperature: None,
                DeviceAttributes.wind: None,
                DeviceAttributes.smart_grid: None,
                DeviceAttributes.multi_terminal: None,
                DeviceAttributes.mute_effect: None,
                DeviceAttributes.mute_status: None,
                DeviceAttributes.error_code: None,
                DeviceAttributes.typeinfo: None,
                DeviceAttributes.vacation_mode: False,
                DeviceAttributes.vacation_days: 0,
            },
        )
        self._fields: dict[Any, Any] = {}
        self._temperature_step: float | None = None
        self._default_temperature_step: float = 1.0
        # customize lua_protocol
        self._default_lua_protocol = LuaProtocol.auto
        self._lua_protocol = self._default_lua_protocol
        # fahrenheit or celsius switch, default is celsius, update with message
        self._fahrenheit: bool = False
        self.set_customize(customize)

    def _value_to_temperature(
        self,
        value: float,
        force_fahrenheit: bool,
        force_old: bool,
    ) -> float:
        # fahrenheit to celsius
        if self._fahrenheit or force_fahrenheit:
            return self.fahrenheit_to_celsius(value, True if force_fahrenheit else None)
        # celsius
        # old protocol
        if self._lua_protocol == LuaProtocol.old or force_old:
            return round((value - 30.0) / 2)
        # new protocol
        return value

    def _temperature_to_value(self, value: float) -> float:
        # celsius to fahrenheit
        if self._fahrenheit:
            return self.celsius_to_fahrenheit(value)
        # celsius
        # old protocol
        if self._lua_protocol == LuaProtocol.old:
            return round(value * 2 + 30.0)
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
                check_device = self.subtype == CDSubType.T186 or self.model in {
                    "RSJRAC01",
                    "RSJRAC06",
                    "RSJRAC07",
                }
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
                raw_value = getattr(message, str(attr))
                # parse modes
                if attr == DeviceAttributes.mode:
                    self._attributes[attr] = MideaCDDevice._modes.get(
                        raw_value,
                        raw_value,
                    )
                    new_status[str(attr)] = self._attributes[attr]
                    continue
                # process temperature family
                if attr in [
                    DeviceAttributes.max_temperature,
                    DeviceAttributes.min_temperature,
                    DeviceAttributes.target_temperature,
                    DeviceAttributes.current_temperature,
                    DeviceAttributes.outdoor_temperature,
                    DeviceAttributes.condenser_temperature,
                    DeviceAttributes.compressor_temperature,
                ]:
                    is_outdoor_temp = attr == DeviceAttributes.outdoor_temperature
                    is_current_temp = attr == DeviceAttributes.current_temperature
                    parsed = self._value_to_temperature(
                        raw_value,
                        force_fahrenheit=(
                            self.model in ["RSJRAC06", "RSJRAC07"] and is_outdoor_temp
                        ),
                        force_old=(
                            self.model in ["RSJRAC06", "RSJRAC07"] and is_current_temp
                        ),
                    )
                    # Defensive: ignore invalid zeros for min/max/target/current
                    # at startup
                    if attr in [
                        DeviceAttributes.max_temperature,
                        DeviceAttributes.min_temperature,
                        DeviceAttributes.target_temperature,
                        DeviceAttributes.current_temperature,
                    ]:
                        try:
                            pv = float(parsed) if parsed is not None else None
                        except Exception:  # noqa: BLE001
                            pv = None
                        if pv is None or pv <= 0:
                            # preserve existing non-zero value
                            existing = self._attributes.get(attr)
                            if isinstance(existing, int | float) and existing > 0:
                                new_status[str(attr)] = existing
                                continue
                    self._attributes[attr] = parsed
                    new_status[str(attr)] = self._attributes[attr]
                    continue
                # non-temperature attributes
                self._attributes[attr] = raw_value
                new_status[str(attr)] = self._attributes[attr]
        return new_status

    def set_attribute(self, attr: str, value: str | float | bool) -> None:
        """Midea CD device set attribute."""
        if attr in [
            DeviceAttributes.mode,
            DeviceAttributes.power,
            DeviceAttributes.target_temperature,
            DeviceAttributes.vacation_mode,
        ]:
            message = MessageSet(self._message_protocol_version)
            message.fields = dict(self._fields) if self._fields else {}
            # align temperature encoding with lua protocol selection
            message.use_old_protocol = self._lua_protocol == LuaProtocol.old

            # Get safe current values
            current_power = self._attributes.get(DeviceAttributes.power, False)
            current_temp = self._attributes.get(
                DeviceAttributes.target_temperature,
            )
            current_mode = self._attributes.get(DeviceAttributes.mode)

            # Initialize message with current device state
            message.power = current_power

            # Ensure temperature is valid (not None/0)
            if isinstance(current_temp, int | float) and current_temp > 0:
                message.target_temperature = float(current_temp)
            else:
                # Fallback to min_temperature or safe default
                min_temp = self._attributes.get(
                    DeviceAttributes.min_temperature,
                    35.0,
                )
                if isinstance(min_temp, int | float) and min_temp > 0:
                    message.target_temperature = float(min_temp)
                else:
                    message.target_temperature = 40.0

            # Handle mode - safely get current mode, default to 0x00 if None
            if current_mode is None or current_mode == "None":
                message.mode = 0x00
            else:
                mode_key = MideaCDDevice.get_dict_key_by_value(
                    "_modes",
                    str(current_mode),
                )
                message.mode = mode_key if mode_key is not None else 0x00

            # Update based on attribute being set
            if attr == DeviceAttributes.mode:
                # get mode key from mode value
                mode_key = MideaCDDevice.get_dict_key_by_value(
                    "_modes",
                    str(value),
                )
                if mode_key is None:
                    _LOGGER.warning(
                        "[%s] Invalid mode value: %s, not sending command",
                        self.device_id,
                        value,
                    )
                    return  # Don't send invalid mode
                message.mode = mode_key

            elif attr == DeviceAttributes.power:
                message.power = bool(value)

            elif attr == DeviceAttributes.target_temperature:
                message.target_temperature = float(value)

            elif attr == DeviceAttributes.vacation_mode:
                # Vacation mode setting
                if bool(value):  # Enable vacation mode
                    message.mode = 0x05
                elif current_mode is None or current_mode == "None":
                    # Disable vacation mode - revert to previous mode
                    message.mode = 0x00
                else:
                    mode_key = MideaCDDevice.get_dict_key_by_value(
                        "_modes",
                        str(current_mode),
                    )
                    message.mode = mode_key if mode_key is not None else 0x00

            # persist fields for subsequent calls
            self._fields = dict(message.fields)
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
