"""Midea local CD device."""

import json
import logging
from enum import IntEnum, StrEnum
from typing import Any, ClassVar

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from .message import (
    MessageCDResponse,
    MessageQuery,
    MessageQueryDaily,
    MessageQueryWeekly,
    MessageSet,
    MessageSetSterilize,
)

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
    disinfection_temperature = "disinfection_temperature"
    top_temperature = "top_temperature"
    bottom_temperature = "bottom_temperature"
    wind = "wind"
    eco = "eco"
    smart_grid = "smart_grid"
    multi_terminal = "multi_terminal"
    mute_effect = "mute_effect"
    mute_status = "mute_status"
    maintain_warn_tag = "maintain_warn_tag"
    maintain_warn = "maintain_warn"
    error_code = "error_code"
    typeinfo = "typeinfo"
    vacation_mode = "vacation_mode"
    vacation_days = "vacation_days"
    vacation_temperature = "vacation_temperature"
    vacation_start_year = "vacation_start_year"
    vacation_start_month = "vacation_start_month"
    vacation_start_day = "vacation_start_day"
    order1_effect = "order1_effect"
    order2_effect = "order2_effect"
    auto_sterilize_week = "auto_sterilize_week"
    auto_sterilize_hour = "auto_sterilize_hour"
    auto_sterilize_minute = "auto_sterilize_minute"
    weekly_effects = "weekly_effects"
    weekly_schedule = "weekly_schedule"
    daily_timer_schedule = "daily_timer_schedule"


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
                DeviceAttributes.disinfection_temperature: None,
                DeviceAttributes.top_temperature: None,
                DeviceAttributes.bottom_temperature: None,
                DeviceAttributes.wind: None,
                DeviceAttributes.eco: None,
                DeviceAttributes.smart_grid: None,
                DeviceAttributes.multi_terminal: None,
                DeviceAttributes.mute_effect: None,
                DeviceAttributes.mute_status: None,
                DeviceAttributes.maintain_warn_tag: None,
                DeviceAttributes.maintain_warn: None,
                DeviceAttributes.error_code: None,
                DeviceAttributes.typeinfo: None,
                DeviceAttributes.vacation_mode: False,
                DeviceAttributes.vacation_days: 0,
                DeviceAttributes.vacation_temperature: None,
                DeviceAttributes.vacation_start_year: None,
                DeviceAttributes.vacation_start_month: None,
                DeviceAttributes.vacation_start_day: None,
                DeviceAttributes.order1_effect: None,
                DeviceAttributes.order2_effect: None,
                DeviceAttributes.auto_sterilize_week: None,
                DeviceAttributes.auto_sterilize_hour: None,
                DeviceAttributes.auto_sterilize_minute: None,
                DeviceAttributes.weekly_effects: None,
                DeviceAttributes.weekly_schedule: None,
                DeviceAttributes.daily_timer_schedule: None,
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
            # auto mode, use model to set value as old or new
            if return_value == LuaProtocol.auto:
                # new protocol: models RSJRAC01, RSJRAC06, RSJRAC07
                # old protocol: RSJ18RD2 (subtype 186) confirmed via real-device messages
                # (raw body[3]=148 decodes to 59°C only with old protocol: (148-30)/2=59)
                # Note: subtype 186 was previously (incorrectly) mapped to new protocol
                # based on an unverified assumption about model RSJ000CB; removed as
                # subtype alone cannot distinguish models with different protocol versions.
                check_device = self.model in {
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
        return [
            MessageQuery(self._message_protocol_version),
            MessageQueryWeekly(self._message_protocol_version),
            MessageQueryDaily(self._message_protocol_version),
        ]

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
                    mode_str = MideaCDDevice._modes.get(raw_value)
                    if mode_str is not None:
                        # Only update when the value is a recognised mode key
                        # to prevent transient unrecognised values (e.g. 8)
                        # from the SET-echo corrupting the displayed mode.
                        self._attributes[attr] = mode_str
                        new_status[str(attr)] = mode_str
                    # else: skip – mode will be corrected by the next status
                    #       notification from the device.
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
                # disinfection_temperature is already decoded (°C) by the
                # message body class; no protocol conversion needed.  Skip
                # None values so that a previous valid reading is preserved
                # (e.g. when sterilize is turned off the echo body sends an
                # out-of-range value and the message class sets None).
                if attr == DeviceAttributes.disinfection_temperature:
                    if raw_value is not None:
                        self._attributes[attr] = raw_value
                        new_status[str(attr)] = raw_value
                    continue
                # non-temperature attributes
                self._attributes[attr] = raw_value
                new_status[str(attr)] = self._attributes[attr]
        return new_status

    def set_attribute(self, attr: str, value: str | float | bool) -> None:
        """Midea CD device set attribute."""
        # --- Disinfect (sterilize): controlType=0x06, independent message ---
        if attr in [DeviceAttributes.disinfect, DeviceAttributes.disinfection_temperature]:
            message = MessageSetSterilize(self._message_protocol_version)
            # Determine sterilize on/off state
            if attr == DeviceAttributes.disinfect:
                message.sterilize_on = bool(value)
            else:
                # Setting temperature only; preserve current disinfect state
                message.sterilize_on = bool(
                    self._attributes.get(DeviceAttributes.disinfect),
                )
            # Carry stored disinfection temperature (or default) into the command
            stored_dt = self._attributes.get(DeviceAttributes.disinfection_temperature)
            if attr == DeviceAttributes.disinfection_temperature:
                # Use the new value, clamped to the valid range
                message.disinfection_temperature = max(
                    MessageSetSterilize.DISINFECT_TEMP_MIN,
                    min(MessageSetSterilize.DISINFECT_TEMP_MAX, float(value)),
                )
            elif isinstance(stored_dt, int | float):
                message.disinfection_temperature = float(stored_dt)
            else:
                message.disinfection_temperature = MessageSetSterilize.DISINFECT_TEMP_DEFAULT
            message.week = int(
                self._attributes.get(DeviceAttributes.auto_sterilize_week) or 0,
            )
            message.hour = int(
                self._attributes.get(DeviceAttributes.auto_sterilize_hour) or 0,
            )
            message.minute = int(
                self._attributes.get(DeviceAttributes.auto_sterilize_minute) or 0,
            )
            self.build_send(message)
            return

        # --- Power / mode / temperature / vacation: controlType=0x01 ---
        if attr in [
            DeviceAttributes.mode,
            DeviceAttributes.power,
            DeviceAttributes.target_temperature,
            DeviceAttributes.vacation_mode,
            DeviceAttributes.vacation_days,
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

            # Handle mode - safely get current mode, default to 0x00 if None.
            # Note: when vacation is active the stored mode is "Vacation" (0x05)
            # which is NOT a valid modeValue for the device.  We handle that
            # explicitly in the vacation branches below.
            if current_mode is None or current_mode == "None":
                message.mode = 0x00
            elif current_mode == "Vacation":
                # Don't send 0x05 as modeValue – the device doesn't support it.
                # Fall back to 0x00 (no explicit operating mode).
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
                if bool(value):
                    # Enable vacation: set byte8 bit 0x10 + vacation days
                    message.vacation_flag = True
                    current_days = self._attributes.get(DeviceAttributes.vacation_days)
                    message.vacation_days = (
                        int(current_days)
                        if isinstance(current_days, int | float) and current_days > 0
                        else MessageSet.DEFAULT_VACATION_DAYS
                    )
                else:
                    # Disable vacation: clear byte8 bit 0x10.
                    # Send Energy-save (0x01) as the exit mode so the device
                    # has a valid non-vacation mode to transition to.  Sending
                    # 0x00 ("no mode") is ignored by some firmware versions and
                    # leaves the device in vacation mode.
                    message.vacation_flag = False
                    message.vacation_days = 0
                    message.mode = 0x01

            elif attr == DeviceAttributes.vacation_days:
                # Set vacation days (1-360) and (re)enable vacation mode
                days = max(1, min(360, int(value)))
                message.vacation_flag = True
                message.vacation_days = days

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
        # Always resolve auto to old/new based on device model
        if self._lua_protocol == LuaProtocol.auto:
            self._lua_protocol = self._normalize_lua_protocol(LuaProtocol.auto)
        self.update_all(
            {
                "temperature_step": self._temperature_step,
                "lua_protocol": self._lua_protocol,
            },
        )


class MideaAppliance(MideaCDDevice):
    """Midea CD appliance."""
