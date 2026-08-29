"""Midea local CD device."""

import json
import logging
from collections.abc import Callable
from enum import IntEnum, StrEnum
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import (
    SKIP_ATTRIBUTE,
    MideaDevice,
    MideaDeviceInitKwargs,
    sentinel_translator,
)

from .message import (
    MessageCDBase,
    MessageCDResponse,
    MessageQuery,
    MessageQueryB1,
    MessageQueryDaily,
    MessageQueryWeekly,
    MessageSet,
    MessageSetDaily,
    MessageSetMaintenance,
    MessageSetSterilize,
    MessageSetWeekly,
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
    auto_disinfect = "auto_disinfect"
    schedule_mode = "schedule_mode"
    max_temperature_upper_limit = "max_temperature_upper_limit"
    max_temperature_lower_limit = "max_temperature_lower_limit"
    disinfection_temperature_upper_limit = "disinfection_temperature_upper_limit"
    disinfection_temperature_lower_limit = "disinfection_temperature_lower_limit"
    top_temperature = "top_temperature"
    bottom_temperature = "bottom_temperature"
    wind = "wind"
    eco = "eco"
    smart_grid = "smart_grid"
    multi_terminal = "multi_terminal"
    mute_effect = "mute_effect"
    mute_status = "mute_status"
    maintenance_reminder = "maintenance_reminder"
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
    dr_enable = "dr_enable"
    dr_option = "dr_option"
    electric_rod_exception = "electric_rod_exception"
    support_boost_mode = "support_boost_mode"
    support_silent_mode = "support_silent_mode"
    support_remaining_hot_water = "support_remaining_hot_water"
    support_electric_mode = "support_electric_mode"
    support_auto_disinfect = "support_auto_disinfect"
    support_force_e_heating = "support_force_e_heating"
    support_tou = "support_tou"
    remaining_hot_water_max = "remaining_hot_water_max"
    force_e_heating_status = "force_e_heating_status"
    ac_heater_priority = "ac_heater_priority"
    high_temp_reminder = "high_temp_reminder"
    b0_reserved_flags = "b0_reserved_flags"
    new_version_water_heater = "new_version_water_heater"
    holiday_max = "holiday_max"
    holiday_min = "holiday_min"
    timer_step_gap = "timer_step_gap"
    support_ac_heater_priority = "support_ac_heater_priority"
    support_heat_recovery = "support_heat_recovery"
    heat_recovery_status = "heat_recovery_status"
    holiday_mode = "holiday_mode"
    hybrid_motion_mode = "hybrid_motion_mode"
    support_heat_pump_mode = "support_heat_pump_mode"
    support_smart_mode = "support_smart_mode"
    support_negative_temperature = "support_negative_temperature"


class MideaCDDevice(MideaDevice):
    """Midea CD device."""

    _modes: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "energy_save",
        0x02: "standard",
        0x03: "dual",
        0x04: "smart",
        0x05: "vacation",
    }
    _vacation_mode_key: ClassVar[int] = 0x05
    _extended_modes: ClassVar[dict[int, str]] = {
        0x00: "none",
        0x01: "energy_save",
        0x02: "hybrid",
        0x03: "e_heater",
        0x04: "smart",
        0x05: "heat_pump",
        0x09: "boost",
        0x0A: "silent",
    }
    # models that report over the new (raw °C) Lua protocol
    _new_protocol_models: ClassVar[frozenset[str]] = frozenset(
        {"RSJRAC01", "RSJRAC06", "RSJRAC07", "2530001N"},
    )
    # new-protocol models whose outdoor/current temps still need the old
    # fahrenheit/°C decoding quirk (RSJRAC01 does not need this)
    _forced_temperature_models: ClassVar[frozenset[str]] = frozenset(
        {"RSJRAC06", "RSJRAC07", "2530001N"},
    )

    def __init__(
        self,
        *,
        customize: str,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea CD device."""
        super().__init__(
            device_type=DeviceType.CD,
            **kwargs,
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
                DeviceAttributes.auto_disinfect: None,
                DeviceAttributes.schedule_mode: None,
                DeviceAttributes.max_temperature_upper_limit: None,
                DeviceAttributes.max_temperature_lower_limit: None,
                DeviceAttributes.disinfection_temperature_upper_limit: None,
                DeviceAttributes.disinfection_temperature_lower_limit: None,
                DeviceAttributes.top_temperature: None,
                DeviceAttributes.bottom_temperature: None,
                DeviceAttributes.wind: None,
                DeviceAttributes.eco: None,
                DeviceAttributes.smart_grid: None,
                DeviceAttributes.multi_terminal: None,
                DeviceAttributes.mute_effect: None,
                DeviceAttributes.mute_status: None,
                DeviceAttributes.maintenance_reminder: None,
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
                DeviceAttributes.dr_enable: None,
                DeviceAttributes.dr_option: None,
                DeviceAttributes.electric_rod_exception: None,
                DeviceAttributes.support_boost_mode: None,
                DeviceAttributes.support_silent_mode: None,
                DeviceAttributes.support_remaining_hot_water: None,
                DeviceAttributes.support_electric_mode: None,
                DeviceAttributes.support_auto_disinfect: None,
                DeviceAttributes.support_force_e_heating: None,
                DeviceAttributes.support_tou: None,
                DeviceAttributes.remaining_hot_water_max: None,
                DeviceAttributes.force_e_heating_status: None,
                DeviceAttributes.ac_heater_priority: None,
                DeviceAttributes.high_temp_reminder: None,
                DeviceAttributes.b0_reserved_flags: None,
                DeviceAttributes.new_version_water_heater: None,
                DeviceAttributes.holiday_max: None,
                DeviceAttributes.holiday_min: None,
                DeviceAttributes.timer_step_gap: None,
                DeviceAttributes.support_ac_heater_priority: None,
                DeviceAttributes.support_heat_recovery: None,
                DeviceAttributes.heat_recovery_status: None,
                DeviceAttributes.holiday_mode: None,
                DeviceAttributes.hybrid_motion_mode: None,
                DeviceAttributes.support_heat_pump_mode: None,
                DeviceAttributes.support_smart_mode: None,
                DeviceAttributes.support_negative_temperature: None,
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
                # old protocol: RSJ18RD2 (subtype 186), confirmed by
                # real-device messages. Raw body[3]=148 decodes to 59C
                # only with old protocol: (148-30)/2=59.
                # subtype 186 was previously mapped to new protocol from
                # an unverified RSJ000CB assumption; subtype alone cannot
                # distinguish models with different protocol versions.
                check_device = self.model in self._new_protocol_models
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
        """Midea CD selectable preset modes."""
        modes = self._mode_map()
        selectable = ["energy_save", "hybrid", "e_heater", "smart"]
        if self._attributes.get(DeviceAttributes.support_heat_pump_mode):
            selectable.append("heat_pump")
        if self._attributes.get(DeviceAttributes.support_boost_mode):
            selectable.append("boost")
        if self._attributes.get(DeviceAttributes.support_silent_mode):
            selectable.append("silent")
        if not self._is_extended_water_heater():
            return [
                mode for key, mode in modes.items() if key != self._vacation_mode_key
            ]
        return [mode for mode in selectable if mode in modes.values()]

    def _is_extended_water_heater(self, message: object | None = None) -> bool:
        """Detect extended CD support from reported protocol fields."""
        source = message if message is not None else self._attributes

        def _value(attribute: DeviceAttributes) -> Any:  # noqa: ANN401
            if isinstance(source, dict):
                return source.get(attribute)
            return getattr(source, attribute, None)

        if _value(DeviceAttributes.new_version_water_heater) is True or isinstance(
            _value(DeviceAttributes.b0_reserved_flags),
            int,
        ):
            return True
        limits = (
            DeviceAttributes.max_temperature_upper_limit,
            DeviceAttributes.max_temperature_lower_limit,
            DeviceAttributes.disinfection_temperature_upper_limit,
            DeviceAttributes.disinfection_temperature_lower_limit,
        )
        if any(
            isinstance(_value(attribute), int | float) and _value(attribute) > 0
            for attribute in limits
        ):
            return True
        capabilities = (
            DeviceAttributes.support_boost_mode,
            DeviceAttributes.support_silent_mode,
            DeviceAttributes.support_remaining_hot_water,
            DeviceAttributes.support_electric_mode,
            DeviceAttributes.support_auto_disinfect,
            DeviceAttributes.support_force_e_heating,
            DeviceAttributes.support_tou,
        )
        return any(isinstance(_value(attribute), bool) for attribute in capabilities)

    def _mode_map(self, message: object | None = None) -> dict[int, str]:
        """Select the mode map from capabilities reported by the device."""
        return (
            self._extended_modes
            if self._is_extended_water_heater(message)
            else self._modes
        )

    def _make_mode_translator(self, message: object) -> Callable[[int], Any]:
        """Build a mode translator using the capabilities in this response."""

        def _translate(value: int) -> Any:  # noqa: ANN401
            if self._is_extended_water_heater(message) and getattr(
                message,
                DeviceAttributes.vacation_mode,
                False,
            ):
                return self._modes[self._vacation_mode_key]
            return self._mode_map(message).get(value, SKIP_ATTRIBUTE)

        return _translate

    def build_query(self) -> list[MessageCDBase]:
        """Midea CD device build query."""
        queries: list[MessageCDBase] = [
            MessageQuery(self._message_protocol_version),
            MessageQueryWeekly(self._message_protocol_version),
            MessageQueryDaily(self._message_protocol_version),
        ]
        if self._is_extended_water_heater():
            queries.append(MessageQueryB1(self._message_protocol_version))
        return queries

    def _make_temperature_translator(
        self,
        attr: DeviceAttributes,
    ) -> Callable[[float], Any]:
        """Build a translator for one of the seven temperature-family attrs."""
        force_fahrenheit = (
            self.model in self._forced_temperature_models
            and attr == DeviceAttributes.outdoor_temperature
        )
        force_old = (
            self.model in self._forced_temperature_models
            and attr == DeviceAttributes.current_temperature
        )
        is_bounded = attr in {
            DeviceAttributes.max_temperature,
            DeviceAttributes.min_temperature,
            DeviceAttributes.target_temperature,
            DeviceAttributes.current_temperature,
        }

        def _translate(raw_value: float) -> Any:  # noqa: ANN401
            parsed = self._value_to_temperature(
                raw_value,
                force_fahrenheit=force_fahrenheit,
                force_old=force_old,
            )
            if not is_bounded:
                return parsed
            # Defensive: ignore invalid zeros for min/max/target/current at
            # startup, preserving any existing non-zero value instead.
            try:
                pv = float(parsed) if parsed is not None else None
            except Exception:  # noqa: BLE001
                pv = None
            if pv is None or pv <= 0:
                existing = self._attributes.get(attr)
                if isinstance(existing, int | float) and existing > 0:
                    # keep the existing valid reading, drop the invalid one
                    return existing
                # no valid existing reading either: store the invalid/zero
                # value anyway, same as the non-bounded temperature attrs
            return parsed

        return _translate

    @staticmethod
    def _translate_sterilize_time(clamp: Callable[[int], int]) -> Callable[[Any], Any]:
        """Build a translator that keeps only plausible schedule time values.

        SET echoes may omit these fields, and status frames can carry
        impossible values in these positions; never expose those as HA state
        because later SET calls reuse the stored attributes.
        """

        def _translate(value: Any) -> Any:  # noqa: ANN401
            if value is None:
                return SKIP_ATTRIBUTE
            value = int(value)
            return value if value == clamp(value) else None

        return _translate

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea CD device process message."""
        message = MessageCDResponse(msg)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        if hasattr(message, "fields"):
            self._fields = message.fields
        # parse fahrenheit switch for temperature value
        if hasattr(message, DeviceAttributes.fahrenheit):
            self._fahrenheit = getattr(message, DeviceAttributes.fahrenheit)

        temperature_attrs = [
            DeviceAttributes.max_temperature,
            DeviceAttributes.min_temperature,
            DeviceAttributes.target_temperature,
            DeviceAttributes.current_temperature,
            DeviceAttributes.outdoor_temperature,
            DeviceAttributes.condenser_temperature,
            DeviceAttributes.compressor_temperature,
        ]
        new_status = self.update_attributes_from_message(
            message,
            {
                # Only update mode on a recognised mode key, to prevent
                # transient unrecognised values (e.g. 8) from a SET-echo
                # corrupting the displayed mode; the next status notification
                # will correct it.
                DeviceAttributes.mode: self._make_mode_translator(message),
                **{
                    attr: self._make_temperature_translator(attr)
                    for attr in temperature_attrs
                },
                # disinfection_temperature is already decoded (°C) by the
                # message body class; no protocol conversion needed. Skip
                # None values so a previous valid reading is preserved (e.g.
                # when sterilize is off the echo body sends an out-of-range
                # value and the message class sets None).
                DeviceAttributes.disinfection_temperature: sentinel_translator(
                    None,
                    SKIP_ATTRIBUTE,
                ),
                # B1 responses contain a subset of TLVs. Attributes omitted
                # from a response must preserve their last valid value.
                DeviceAttributes.maintenance_reminder: sentinel_translator(
                    None,
                    SKIP_ATTRIBUTE,
                ),
                DeviceAttributes.auto_sterilize_week: self._translate_sterilize_time(
                    MessageSetSterilize.clamp_week,
                ),
                DeviceAttributes.auto_sterilize_hour: self._translate_sterilize_time(
                    MessageSetSterilize.clamp_hour,
                ),
                DeviceAttributes.auto_sterilize_minute: self._translate_sterilize_time(
                    MessageSetSterilize.clamp_minute,
                ),
            },
        )
        # Extended heaters report the stable maintenance state through the
        # canonical 0x40/B1 flag; their legacy 0x80 bit can flap independently.
        # Mirror the canonical value so existing HA entity IDs remain stable.
        maintenance_reminder = new_status.get(
            str(DeviceAttributes.maintenance_reminder),
        )
        if isinstance(maintenance_reminder, bool) and self._is_extended_water_heater(
            message,
        ):
            self._attributes[DeviceAttributes.maintain_warn] = maintenance_reminder
            new_status[str(DeviceAttributes.maintain_warn)] = maintenance_reminder
        return new_status

    def _set_maintenance_reminder(self, value: bool) -> None:
        """Send the dedicated B0 maintenance flag without changing other flags."""
        reserved = self._attributes.get(DeviceAttributes.b0_reserved_flags)
        if not self._is_extended_water_heater() or not isinstance(reserved, int):
            _LOGGER.warning(
                "[%s] maintenance write postponed until B1 flags are known",
                self.device_id,
            )
            return
        message = MessageSetMaintenance(self._message_protocol_version)
        message.ac_heater_priority = bool(
            self._attributes.get(DeviceAttributes.ac_heater_priority, False),
        )
        message.high_temp_reminder = bool(
            self._attributes.get(DeviceAttributes.high_temp_reminder, False),
        )
        message.maintenance_reminder = value
        message.reserved_flags = reserved
        self.build_send(message)

    def _set_disinfection(
        self,
        attr: str,
        value: bool | float | str,
    ) -> None:
        """Send the extended seven-byte disinfection payload."""
        if not self._is_extended_water_heater():
            _LOGGER.warning(
                "[%s] extended disinfection write requires reported CD support",
                self.device_id,
            )
            return
        message = MessageSetSterilize(self._message_protocol_version)
        message.extended_body = True
        message.sterilize_on = (
            bool(value)
            if attr in {DeviceAttributes.disinfect, DeviceAttributes.sterilize}
            else bool(self._attributes.get(DeviceAttributes.disinfect, False))
        )
        message.week = MessageSetSterilize.clamp_week(
            self._attributes.get(DeviceAttributes.auto_sterilize_week),
        )
        message.hour = MessageSetSterilize.clamp_hour(
            self._attributes.get(DeviceAttributes.auto_sterilize_hour),
        )
        message.minute = MessageSetSterilize.clamp_minute(
            self._attributes.get(DeviceAttributes.auto_sterilize_minute),
        )
        temperature = (
            value
            if attr == DeviceAttributes.disinfection_temperature
            else self._attributes.get(DeviceAttributes.disinfection_temperature)
        )
        if not isinstance(temperature, int | float):
            temperature = MessageSetSterilize.DISINFECT_TEMP_MIN
        lower = self._attributes.get(
            DeviceAttributes.disinfection_temperature_lower_limit,
        )
        upper = self._attributes.get(
            DeviceAttributes.disinfection_temperature_upper_limit,
        )
        minimum = int(lower) if isinstance(lower, int | float) else 60
        maximum = int(upper) if isinstance(upper, int | float) else 70
        message.disinfection_temperature = float(
            max(minimum, min(maximum, float(temperature))),
        )
        self.build_send(message)

    @staticmethod
    def _has_valid_timer_data(attr: str, value: dict[Any, Any]) -> bool:
        """Return whether a schedule contains safe timer collections."""
        timer_groups = (
            [value.get(day, []) for day in range(7)]
            if attr == DeviceAttributes.weekly_schedule
            else [value.get("timers", [])]
        )
        return all(
            isinstance(timers, list)
            and all(isinstance(timer, dict) for timer in timers)
            for timers in timer_groups
        )

    def set_attribute(  # noqa: C901, PLR0911
        self,
        attr: str,
        value: bool | float | str | dict[Any, Any],
    ) -> None:
        """Midea CD device set attribute."""
        if attr in [
            DeviceAttributes.maintenance_reminder,
            DeviceAttributes.maintain_warn_tag,
        ]:
            if isinstance(value, dict):
                _LOGGER.warning("[%s] %s requires a scalar value", self.device_id, attr)
                return
            self._set_maintenance_reminder(bool(value))
            return

        if attr in [
            DeviceAttributes.disinfect,
            DeviceAttributes.sterilize,
            DeviceAttributes.disinfection_temperature,
        ]:
            if isinstance(value, dict):
                _LOGGER.warning("[%s] %s requires a scalar value", self.device_id, attr)
                return
            self._set_disinfection(attr, value)
            return

        if attr in [
            DeviceAttributes.weekly_schedule,
            DeviceAttributes.daily_timer_schedule,
        ]:
            if not self._is_extended_water_heater() or not isinstance(value, dict):
                _LOGGER.warning(
                    "[%s] %s write requires reported CD support and a mapping",
                    self.device_id,
                    attr,
                )
                return
            if not self._has_valid_timer_data(attr, value):
                _LOGGER.warning("[%s] %s has invalid timer data", self.device_id, attr)
                return
            if attr == DeviceAttributes.weekly_schedule:
                weekly = MessageSetWeekly(self._message_protocol_version)
                weekly.weekly_schedule = value
                self.build_send(weekly)
            else:
                daily = MessageSetDaily(self._message_protocol_version)
                daily.daily_timer_schedule = value
                self.build_send(daily)
            return

        if isinstance(value, dict):
            _LOGGER.warning(
                "[%s] %s requires a scalar value",
                self.device_id,
                attr,
            )
            return

        # Power, mode, temperature, max_temperature, and vacation use controlType=0x01.
        if attr in [
            DeviceAttributes.mode,
            DeviceAttributes.power,
            DeviceAttributes.target_temperature,
            DeviceAttributes.vacation_mode,
            DeviceAttributes.vacation_days,
            DeviceAttributes.max_temperature,
            DeviceAttributes.schedule_mode,
        ]:
            if (
                attr
                in {
                    DeviceAttributes.max_temperature,
                    DeviceAttributes.schedule_mode,
                }
                and not self._is_extended_water_heater()
            ):
                _LOGGER.warning(
                    "[%s] %s write requires reported CD support",
                    self.device_id,
                    attr,
                )
                return
            message = MessageSet(self._message_protocol_version)
            message.fields = dict(self._fields) if self._fields else {}
            # align temperature encoding with lua protocol selection
            message.use_old_protocol = self._lua_protocol == LuaProtocol.old
            schedule_mode = self._attributes.get(DeviceAttributes.schedule_mode)
            message.schedule_mode = (
                int(schedule_mode) if isinstance(schedule_mode, int | float) else 0
            )

            # Get safe current values
            current_power = self._attributes.get(DeviceAttributes.power, False)
            current_temp = self._attributes.get(
                DeviceAttributes.target_temperature,
            )
            current_mode = self._attributes.get(DeviceAttributes.mode)

            # Initialize message with current device state
            message.power = current_power

            # Fahrenheit mode flag (bodyBytes[8] bit 0x80)
            message.fahrenheit = bool(
                self._attributes.get(DeviceAttributes.fahrenheit, False),
            )

            # full[21] vacationTsValue — not max temperature.
            # full[23] tsMax — must be the device max (issue #468); 0 clamps SP.
            if attr in (
                DeviceAttributes.target_temperature,
                DeviceAttributes.mode,
                DeviceAttributes.power,
            ):
                # Plain control: leave vacationTs at 0 (Lua default).
                message.vacation_temperature = 0.0
            else:
                vac_temp = self._attributes.get(DeviceAttributes.vacation_temperature)
                message.vacation_temperature = (
                    float(vac_temp)
                    if isinstance(vac_temp, int | float) and vac_temp > 0
                    else 0.0
                )
            mx = self._attributes.get(DeviceAttributes.max_temperature)
            try:
                message.ts_max = (
                    int(mx) if isinstance(mx, int | float) and mx > 0 else 0
                )
            except (TypeError, ValueError):
                message.ts_max = 0

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
            if current_mode is None or current_mode == "none":
                message.mode = 0x00
            elif current_mode == "vacation":
                # Do not send 0x05 as modeValue; the device does not support it.
                # Fall back to 0x00 (no explicit operating mode).
                message.mode = 0x00
            else:
                mode_key = next(
                    (
                        key
                        for key, name in self._mode_map().items()
                        if name == str(current_mode)
                    ),
                    None,
                )
                message.mode = mode_key if mode_key is not None else 0x00

            # Update based on attribute being set
            if attr == DeviceAttributes.mode:
                # get mode key from mode value
                if value == self._modes[self._vacation_mode_key]:
                    _LOGGER.warning(
                        "[%s] Vacation mode cannot be selected directly; "
                        "use vacation_days/vacation_mode instead",
                        self.device_id,
                    )
                    return
                mode_key = next(
                    (
                        key
                        for key, name in self._mode_map().items()
                        if name == str(value)
                    ),
                    None,
                )
                if mode_key is None:
                    _LOGGER.warning(
                        "[%s] Invalid mode value: %s, not sending command",
                        self.device_id,
                        value,
                    )
                    return  # Don't send invalid mode
                message.mode = mode_key
                # None has no on-device meaning distinct from Off; selecting
                # it powers the unit off, selecting any other mode powers it
                # back on.
                message.power = mode_key != 0x00

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

            elif attr == DeviceAttributes.max_temperature:
                lower = self._attributes.get(
                    DeviceAttributes.max_temperature_lower_limit,
                )
                upper = self._attributes.get(
                    DeviceAttributes.max_temperature_upper_limit,
                )
                minimum = int(lower) if isinstance(lower, int | float) else 35
                maximum = int(upper) if isinstance(upper, int | float) else 70
                message.ts_max = max(minimum, min(maximum, int(float(value))))
                if message.target_temperature > message.ts_max:
                    message.target_temperature = float(message.ts_max)

            elif attr == DeviceAttributes.schedule_mode:
                message.schedule_mode = max(0, min(2, int(value)))

            # persist only safe fields; SET echoes often return openPTC=1 / bad Tr
            self._fields = self._sanitize_set_fields(message.fields)
            # Avoid replaying SET-echo junk into the next control frame
            message.fields = dict(self._fields)
            self.build_send(message)

    @staticmethod
    def _sanitize_set_fields(fields: dict[Any, Any]) -> dict[Any, Any]:
        """Strip SET-echo junk so it is not replayed into the next frame.

        Drops openPTC/ptcTemp/byte8 (openPTC is forced 0 by MessageSet) and
        removes an out-of-range trValue so only a valid Tr survives.
        """
        clean = dict(fields)
        for key in ("openPTC", "ptcTemp", "byte8"):
            clean.pop(key, None)
        tr = clean.get("trValue")
        try:
            tr_i = int(tr) if tr is not None else 0
        except (TypeError, ValueError):
            tr_i = 0
        if tr_i < MessageSet.TR_VALUE_MIN or tr_i > MessageSet.TR_VALUE_MAX:
            clean.pop("trValue", None)
        return {k: v for k, v in clean.items() if k == "trValue"}

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
