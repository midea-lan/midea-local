"""Midea local AC device."""

import json
import logging
import time
from dataclasses import dataclass
from enum import StrEnum
from typing import Any, ClassVar, Unpack, cast

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs
from midealocal.message import ListTypes

from .message import (
    MessageACResponse,
    MessageCapabilitiesAdditionalQuery,
    MessageCapabilitiesQuery,
    MessageGeneralSet,
    MessageGroupOneQuery,
    MessageGroupSevenQuery,
    MessageGroupTwoQuery,
    MessageGroupZeroQuery,
    MessageHumidityQuery,
    MessageNewProtocolQuery,
    MessageNewProtocolSelfCleanQuery,
    MessageNewProtocolSet,
    MessagePowerQuery,
    MessageQuery,
    MessageSubProtocolFreshAirSet,
    MessageSubProtocolQuery,
    MessageSubProtocolQuery10,
    MessageSubProtocolQuery11,
    MessageSubProtocolQuery30,
    MessageSubProtocolSet,
    MessageToggleDisplay,
)

_LOGGER = logging.getLogger(__name__)

ACQuery = (
    MessageSubProtocolQuery
    | MessageQuery
    | MessageNewProtocolQuery
    | MessagePowerQuery
    | MessageHumidityQuery
    | MessageGroupZeroQuery
    | MessageGroupOneQuery
    | MessageGroupTwoQuery
    | MessageGroupSevenQuery
    | MessageCapabilitiesQuery
    | MessageCapabilitiesAdditionalQuery
)

# AC mode constants
DRY_MODE = 3


class DeviceAttributes(StrEnum):
    """Midea AC device attributes."""

    prompt_tone = "prompt_tone"
    power = "power"
    mode = "mode"
    target_temperature = "target_temperature"
    min_temperature = "min_temperature"
    max_temperature = "max_temperature"
    fan_speed = "fan_speed"
    swing_vertical = "swing_vertical"
    swing_horizontal = "swing_horizontal"
    boost_mode = "boost_mode"
    power_saving = "power_saving"
    smart_eye = "smart_eye"
    dry = "dry"
    eco_mode = "eco_mode"
    aux_heating = "aux_heating"
    sleep_mode = "sleep_mode"
    natural_wind = "natural_wind"
    temp_fahrenheit = "temp_fahrenheit"
    screen_display = "screen_display"
    screen_display_alternate = "screen_display_alternate"
    full_dust = "full_dust"
    frost_protect = "frost_protect"
    comfort_mode = "comfort_mode"
    indoor_temperature = "indoor_temperature"
    outdoor_temperature = "outdoor_temperature"
    indirect_wind = "indirect_wind"
    indoor_humidity = "indoor_humidity"
    breezeless = "breezeless"
    fresh_air_power = "fresh_air_power"
    fresh_air_fan_speed = "fresh_air_fan_speed"
    fresh_air_mode = "fresh_air_mode"
    fresh_air_1 = "fresh_air_1"
    fresh_air_2 = "fresh_air_2"
    fresh_air_exhaust_power = "fresh_air_exhaust_power"
    fresh_air_exhaust_speed = "fresh_air_exhaust_speed"
    fresh_air_exhaust_mode = "fresh_air_exhaust_mode"
    total_energy_consumption = "total_energy_consumption"
    total_operating_consumption = "total_operating_consumption"
    current_energy_consumption = "current_energy_consumption"
    realtime_power = "realtime_power"
    electrify_time = "electrify_time"
    total_operating_time = "total_operating_time"
    current_operating_time = "current_operating_time"
    wind_lr_angle = "wind_lr_angle"
    wind_ud_angle = "wind_ud_angle"
    rate_select = "rate_select"
    out_silent = "out_silent"
    anion = "anion"
    sound = "sound"
    self_clean = "self_clean"
    pmv = "pmv"
    error_code = "error_code"
    # group 1: compressor and refrigerant circuit
    compressor_frequency = "compressor_frequency"
    target_compressor_frequency = "target_compressor_frequency"
    compressor_current = "compressor_current"
    compressor_voltage = "compressor_voltage"
    indoor_coil_temperature = "indoor_coil_temperature"  # T1
    evaporator_temperature = "evaporator_temperature"  # T2
    condenser_temperature = "condenser_temperature"  # T3
    outdoor_ambient_temperature = "outdoor_ambient_temperature"  # T4
    discharge_pipe_temperature = "discharge_pipe_temperature"  # TP
    # group 2: indoor fan and condensate pump
    indoor_fan_speed = "indoor_fan_speed"
    target_indoor_fan_speed = "target_indoor_fan_speed"
    water_pump_running = "water_pump_running"
    # group 7: real time compressor power
    compressor_power = "compressor_power"


BB_FRESH_AIR_DEFAULT_SPEED = 60
# The BB exhaust preset map has no "medium" (60) entry; use the first
# advertised non-silent exhaust mode when a power-on command has no prior speed.
BB_FRESH_AIR_EXHAUST_DEFAULT_SPEED = 80


@dataclass(frozen=True)
class ACModelCapabilities:
    """Capabilities verified for an exact AC model and subtype."""

    attributes: frozenset[DeviceAttributes] = frozenset()
    uses_bb_protocol: bool = False
    has_bb_fresh_air: bool = False


DEFAULT_AC_MODEL_CAPABILITIES = ACModelCapabilities()
# These BB fields use model-specific offsets and command payloads observed on
# exact model/subtype pairs. Keep unrelated devices hidden from attributes and
# commands whose bytes may have a different meaning on other firmware.
AC_MODEL_CAPABILITIES = {
    ("23096633", 1): ACModelCapabilities(
        attributes=frozenset(
            {
                DeviceAttributes.fresh_air_exhaust_power,
                DeviceAttributes.fresh_air_exhaust_speed,
                DeviceAttributes.fresh_air_exhaust_mode,
            },
        ),
        uses_bb_protocol=True,
        has_bb_fresh_air=True,
    ),
}

# The 0x7e new-protocol temperature payload layout is verified only for model
# 22013279, whose C0 temperature fields are stale. Model 22251759 / subtype
# 32773 has a useful C0 outdoor temperature; accepting its 0x7e response would
# replace that value with None and then suppress subsequent C0 temperatures.
# https://github.com/wuwentao/midea_ac_lan/issues/893
NEW_PROTOCOL_TEMPERATURE_MODELS = frozenset({"22013279"})

STALE_C0_TEMPERATURE_ATTRIBUTES = (
    DeviceAttributes.target_temperature,
    DeviceAttributes.indoor_temperature,
    DeviceAttributes.outdoor_temperature,
)


class MideaACDevice(MideaDevice):
    """Midea AC device."""

    _fresh_air_fan_speeds: ClassVar[dict[int, str]] = {
        0: "off",
        20: "silent",
        40: "low",
        60: "medium",
        80: "high",
        100: "full",
    }

    _bb_fresh_air_fan_speeds: ClassVar[dict[int, str]] = {
        0: "off",
        40: "low",
        60: "medium",
        80: "high",
        100: "full",
    }

    _bb_fresh_air_exhaust_speeds: ClassVar[dict[int, str]] = {
        0: "off",
        20: "silent",
        80: "high",
        100: "full",
    }

    _wind_lr_angles: ClassVar[dict[int, str]] = {
        0: "off",
        1: "left",
        25: "left-mid",
        50: "middle",
        75: "right-mid",
        100: "right",
    }

    _wind_ud_angles: ClassVar[dict[int, str]] = {
        0: "off",
        1: "up",
        25: "up-mid",
        50: "middle",
        75: "down-mid",
        100: "down",
    }

    _rate_selects: ClassVar[dict[int, str]] = {
        1: "1",
        20: "20",
        40: "40",
        60: "60",
        80: "80",
        100: "100",
    }

    def __init__(
        self,
        *,
        customize: str,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea AC device."""
        super().__init__(
            device_type=DeviceType.AC,
            **kwargs,
            attributes={
                DeviceAttributes.prompt_tone: True,
                DeviceAttributes.power: False,
                DeviceAttributes.mode: 0,
                DeviceAttributes.target_temperature: 24.0,
                DeviceAttributes.min_temperature: None,
                DeviceAttributes.max_temperature: None,
                DeviceAttributes.fan_speed: 102,
                DeviceAttributes.swing_vertical: False,
                DeviceAttributes.swing_horizontal: False,
                DeviceAttributes.smart_eye: False,
                DeviceAttributes.dry: False,
                DeviceAttributes.aux_heating: False,
                DeviceAttributes.boost_mode: False,
                DeviceAttributes.power_saving: False,
                DeviceAttributes.sleep_mode: False,
                DeviceAttributes.frost_protect: False,
                DeviceAttributes.comfort_mode: False,
                DeviceAttributes.eco_mode: False,
                DeviceAttributes.natural_wind: False,
                DeviceAttributes.temp_fahrenheit: False,
                DeviceAttributes.screen_display: False,
                DeviceAttributes.screen_display_alternate: False,
                DeviceAttributes.full_dust: False,
                DeviceAttributes.indoor_temperature: None,
                DeviceAttributes.outdoor_temperature: None,
                DeviceAttributes.indirect_wind: False,
                DeviceAttributes.indoor_humidity: None,
                DeviceAttributes.breezeless: False,
                DeviceAttributes.total_energy_consumption: None,
                DeviceAttributes.total_operating_consumption: None,
                DeviceAttributes.current_energy_consumption: None,
                DeviceAttributes.realtime_power: None,
                DeviceAttributes.electrify_time: None,
                DeviceAttributes.total_operating_time: None,
                DeviceAttributes.current_operating_time: None,
                DeviceAttributes.fresh_air_power: False,
                DeviceAttributes.fresh_air_fan_speed: 0,
                DeviceAttributes.fresh_air_mode: None,
                DeviceAttributes.fresh_air_1: None,
                DeviceAttributes.fresh_air_2: None,
                DeviceAttributes.wind_lr_angle: None,
                DeviceAttributes.wind_ud_angle: None,
                DeviceAttributes.rate_select: None,
                DeviceAttributes.out_silent: False,
                DeviceAttributes.anion: False,
                DeviceAttributes.sound: True,
                DeviceAttributes.self_clean: False,
                DeviceAttributes.pmv: None,
                DeviceAttributes.error_code: 0,
                DeviceAttributes.compressor_frequency: None,
                DeviceAttributes.target_compressor_frequency: None,
                DeviceAttributes.compressor_current: None,
                DeviceAttributes.compressor_voltage: None,
                DeviceAttributes.indoor_coil_temperature: None,
                DeviceAttributes.evaporator_temperature: None,
                DeviceAttributes.condenser_temperature: None,
                DeviceAttributes.outdoor_ambient_temperature: None,
                DeviceAttributes.discharge_pipe_temperature: None,
                DeviceAttributes.indoor_fan_speed: None,
                DeviceAttributes.target_indoor_fan_speed: None,
                DeviceAttributes.water_pump_running: None,
                DeviceAttributes.compressor_power: None,
            },
        )
        self._model_key = (str(self.model), int(self.subtype))
        self._model_capabilities = AC_MODEL_CAPABILITIES.get(
            self._model_key,
            DEFAULT_AC_MODEL_CAPABILITIES,
        )
        self._attributes.update(
            dict.fromkeys(self._model_capabilities.attributes),
        )
        self._fresh_air_version: DeviceAttributes | None = None
        self._pending_self_clean: tuple[bool, float] | None = None
        self._default_temperature_step: float = 0.5
        self._temperature_step: float = 0.5
        self._used_subprotocol: bool = self._model_capabilities.uses_bb_protocol
        self._bb_sn8_flag: bool = False
        self._bb_timer: bool = False
        # per-mode setpoint limits from the B5 capability, keyed by mode value
        self._temperature_limits: dict[int, tuple[float, float]] | None = None
        # decoded B5 capability flags (accumulated across B5 frames)
        self._capabilities: dict[str, bool] = {}
        # manual setpoint limits from customize (highest priority)
        self._customize_min_temperature: float | None = None
        self._customize_max_temperature: float | None = None
        self._power_analysis_method: int = 1
        self._default_power_analysis_method: int = 1
        # 0x7e temperature decoding is restricted to verified models.
        self._uses_new_protocol_temperature = (
            str(self.model) in NEW_PROTOCOL_TEMPERATURE_MODELS
        )
        # Once 0x7e-derived temperatures are seen, ignore stale C0 temperature
        # fields to avoid brief UI flicker caused by query ordering.
        self._prefer_new_protocol_temperature: bool = False
        self.set_customize(customize)

    @property
    def temperature_step(self) -> float | None:
        """Midea AC device temperature step."""
        return self._temperature_step

    @property
    def fresh_air_fan_speeds(self) -> list[str]:
        """Midea AC device fresh air fan speeds."""
        if self._model_capabilities.has_bb_fresh_air:
            return list(MideaACDevice._bb_fresh_air_fan_speeds.values())
        return list(MideaACDevice._fresh_air_fan_speeds.values())

    @property
    def fresh_air_exhaust_fan_speeds(self) -> list[str]:
        """Midea AC device fresh-air exhaust fan speeds."""
        if self._model_capabilities.has_bb_fresh_air:
            return list(MideaACDevice._bb_fresh_air_exhaust_speeds.values())
        return []

    @property
    def wind_lr_angles(self) -> list[str]:
        """Midea AC device wind_lr_angle."""
        return list(MideaACDevice._wind_lr_angles.values())

    @property
    def wind_ud_angles(self) -> list[str]:
        """Midea AC device wind_ud_angle."""
        return list(MideaACDevice._wind_ud_angles.values())

    @property
    def rate_selects(self) -> list[str]:
        """Midea AC device rate_select options."""
        return list(MideaACDevice._rate_selects.values())

    def build_query(self) -> list[ACQuery]:
        """Midea AC device build query."""
        if self._used_subprotocol:
            # BB responses are independent status groups. Query each group with
            # its own identity so an unsupported response for one group does not
            # suppress later status groups.
            return [
                MessageSubProtocolQuery10(self._message_protocol_version),
                MessageSubProtocolQuery11(self._message_protocol_version),
                MessageSubProtocolQuery30(self._message_protocol_version),
            ]
        queries: list[ACQuery] = [
            MessageQuery(self._message_protocol_version),
            MessageNewProtocolQuery(self._message_protocol_version),
            # Queried on its own so an empty response for the combined
            # new-protocol query does not suppress the self-clean state.
            MessageNewProtocolSelfCleanQuery(self._message_protocol_version),
            MessagePowerQuery(self._message_protocol_version),
            MessageHumidityQuery(self._message_protocol_version),
            MessageGroupZeroQuery(self._message_protocol_version),
            # Devices that do not answer a group query are detected during the
            # initial protocol check and the query is skipped from then on.
            MessageGroupOneQuery(self._message_protocol_version),
            MessageGroupTwoQuery(self._message_protocol_version),
            MessageGroupSevenQuery(self._message_protocol_version),
            MessageCapabilitiesQuery(self._message_protocol_version),
            MessageCapabilitiesAdditionalQuery(self._message_protocol_version),
        ]
        return queries

    def process_message(self, msg: bytes) -> dict[str, Any]:  # noqa: C901
        """Midea AC device process message."""
        message = MessageACResponse(
            bytearray(msg),
            self._power_analysis_method,
            self._uses_new_protocol_temperature,
        )
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        has_fresh_air = False
        body_type = getattr(message, "body_type", None)

        if getattr(message, "has_subtype8_temperature", False):
            self._prefer_new_protocol_temperature = True

        is_stale_c0_temperature = (
            self._prefer_new_protocol_temperature and body_type == ListTypes.C0
        )

        if hasattr(message, "used_subprotocol"):
            self._used_subprotocol = True
            if hasattr(message, "sn8_flag"):
                self._bb_sn8_flag = message.sn8_flag
            if hasattr(message, "timer"):
                self._bb_timer = message.timer
        if self._model_capabilities.has_bb_fresh_air and hasattr(
            message,
            "bb_fresh_air_power",
        ):
            response_attributes = vars(message)
            fresh_air_power = cast("bool", response_attributes["bb_fresh_air_power"])
            fresh_air_speed = cast(
                "int",
                response_attributes["bb_fresh_air_fan_speed"],
            )
            exhaust_power = cast(
                "bool",
                response_attributes["bb_fresh_air_exhaust_power"],
            )
            exhaust_speed = cast(
                "int",
                response_attributes["bb_fresh_air_exhaust_speed"],
            )
            fresh_air_status = {
                DeviceAttributes.fresh_air_power: fresh_air_power,
                DeviceAttributes.fresh_air_fan_speed: fresh_air_speed,
                DeviceAttributes.fresh_air_mode: self._fresh_air_mode(
                    fresh_air_power,
                    fresh_air_speed,
                    MideaACDevice._bb_fresh_air_fan_speeds,
                ),
                DeviceAttributes.fresh_air_exhaust_power: exhaust_power,
                DeviceAttributes.fresh_air_exhaust_speed: exhaust_speed,
                DeviceAttributes.fresh_air_exhaust_mode: self._fresh_air_mode(
                    exhaust_power,
                    exhaust_speed,
                    MideaACDevice._bb_fresh_air_exhaust_speeds,
                ),
            }
            self._attributes.update(fresh_air_status)
            new_status.update(
                {str(key): value for key, value in fresh_air_status.items()},
            )
        for attr in self._attributes:
            if hasattr(message, str(attr)):
                if is_stale_c0_temperature and attr in STALE_C0_TEMPERATURE_ATTRIBUTES:
                    continue
                value = getattr(message, str(attr))
                if attr == DeviceAttributes.fresh_air_power:
                    has_fresh_air = True
                # wind_lr_angle
                if attr == DeviceAttributes.wind_lr_angle:
                    self._attributes[attr] = MideaACDevice._wind_lr_angles.get(value)
                # wind_ud_angle
                elif attr == DeviceAttributes.wind_ud_angle:
                    self._attributes[attr] = MideaACDevice._wind_ud_angles.get(value)
                elif attr == DeviceAttributes.rate_select:
                    self._attributes[attr] = MideaACDevice._rate_selects.get(value)
                else:
                    self._attributes[attr] = value
                new_status[str(attr)] = self._attributes[attr]
        if has_fresh_air:
            if self._attributes[DeviceAttributes.fresh_air_power]:
                for k, v in MideaACDevice._fresh_air_fan_speeds.items():
                    if self._attributes[DeviceAttributes.fresh_air_fan_speed] < k:
                        break
                    self._attributes[DeviceAttributes.fresh_air_mode] = v
            else:
                self._attributes[DeviceAttributes.fresh_air_mode] = "off"
            new_status[DeviceAttributes.fresh_air_mode.value] = self._attributes[
                DeviceAttributes.fresh_air_mode
            ]
        if not self._attributes[DeviceAttributes.power] or (
            DeviceAttributes.swing_vertical in new_status
            and self._attributes[DeviceAttributes.swing_vertical]
        ):
            self._attributes[DeviceAttributes.indirect_wind] = False
            new_status[DeviceAttributes.indirect_wind.value] = False
        if not self._attributes[DeviceAttributes.power]:
            self._attributes[DeviceAttributes.screen_display] = False
            new_status[DeviceAttributes.screen_display.value] = False
        if self._attributes[DeviceAttributes.fresh_air_1] is not None:
            self._fresh_air_version = DeviceAttributes.fresh_air_1
        elif self._attributes[DeviceAttributes.fresh_air_2] is not None:
            self._fresh_air_version = DeviceAttributes.fresh_air_2
        if hasattr(message, "self_clean_active"):
            active = message.self_clean_active
            update_self_clean = True
            if self._pending_self_clean is not None:
                expected, set_at = self._pending_self_clean
                elapsed = time.monotonic() - set_at
                if active == expected or elapsed > self._self_clean_pending_timeout:
                    self._pending_self_clean = None
                else:
                    _LOGGER.debug(
                        "[%s] Ignoring stale self-clean status %s while awaiting %s",
                        self.device_id,
                        active,
                        expected,
                    )
                    update_self_clean = False
            if update_self_clean:
                self._attributes[DeviceAttributes.self_clean] = active
                new_status[DeviceAttributes.self_clean.value] = active
        new_status.update(self._refresh_temperature_limits(message))
        self._update_capabilities(message)
        return new_status

    @staticmethod
    def _fresh_air_mode(
        power: bool,
        speed: int,
        presets: dict[int, str],
    ) -> str:
        """Return the fresh-air preset represented by a reported speed."""
        if not power:
            return "off"
        mode = "off"
        for threshold, name in presets.items():
            if speed < threshold:
                break
            mode = name
        return mode

    @property
    def _self_clean_pending_timeout(self) -> int:
        """Return the stale-status window for a pending self-clean command."""
        return (
            self._refresh_interval
            if self._refresh_interval > 0
            else self._default_refresh_interval
        )

    def _update_capabilities(self, message: MessageACResponse) -> None:
        """Accumulate decoded B5 capability flags from a B5 response."""
        if hasattr(message, "capabilities"):
            self._capabilities.update(message.capabilities)

    @property
    def capabilities(self) -> dict[str, bool]:
        """Return the decoded B5 capability flags reported by the device."""
        return self._capabilities

    def _b5_temperature_limits(self) -> tuple[float, float] | None:
        """Return the B5 setpoint limits for the current mode, if any.

        An unknown mode (e.g. 0 when off) falls back to the cool range.
        """
        if self._temperature_limits is None:
            return None
        mode = self._attributes[DeviceAttributes.mode]
        return self._temperature_limits.get(mode, self._temperature_limits[2])

    def _refresh_temperature_limits(
        self,
        message: MessageACResponse | None = None,
    ) -> dict[str, Any]:
        """Resolve min/max setpoint limits.

        Priority: customize option > B5 capability > None (the consumer then
        falls back to its own default range).
        """
        if message is not None and hasattr(message, "temperature_limits"):
            self._temperature_limits = message.temperature_limits
        b5 = self._b5_temperature_limits()
        minimum = self._customize_min_temperature
        if minimum is None and b5 is not None:
            minimum = b5[0]
        maximum = self._customize_max_temperature
        if maximum is None and b5 is not None:
            maximum = b5[1]
        self._attributes[DeviceAttributes.min_temperature] = minimum
        self._attributes[DeviceAttributes.max_temperature] = maximum
        return {
            DeviceAttributes.min_temperature.value: minimum,
            DeviceAttributes.max_temperature.value: maximum,
        }

    def make_message_set(self) -> MessageGeneralSet:
        """Midea AC device make message set."""
        message = MessageGeneralSet(self._message_protocol_version)
        message.power = self._attributes[DeviceAttributes.power]
        message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]
        message.mode = self._attributes[DeviceAttributes.mode]
        message.target_temperature = self._attributes[
            DeviceAttributes.target_temperature
        ]
        message.fan_speed = self._attributes[DeviceAttributes.fan_speed]
        message.swing_vertical = self._attributes[DeviceAttributes.swing_vertical]
        message.swing_horizontal = self._attributes[DeviceAttributes.swing_horizontal]
        message.boost_mode = self._attributes[DeviceAttributes.boost_mode]
        message.power_saving = self._attributes[DeviceAttributes.power_saving]
        message.smart_eye = self._attributes[DeviceAttributes.smart_eye]
        message.dry = self._attributes[DeviceAttributes.dry]
        message.eco_mode = self._attributes[DeviceAttributes.eco_mode]
        message.aux_heating = self._attributes[DeviceAttributes.aux_heating]
        message.sleep_mode = self._attributes[DeviceAttributes.sleep_mode]
        message.natural_wind = self._attributes[DeviceAttributes.natural_wind]
        message.temp_fahrenheit = self._attributes[DeviceAttributes.temp_fahrenheit]
        message.frost_protect = self._attributes[DeviceAttributes.frost_protect]
        message.comfort_mode = self._attributes[DeviceAttributes.comfort_mode]
        message.anion = self._attributes[DeviceAttributes.anion]
        return message

    def make_newprotocol_message_set(
        self,
        attr: str,
        value: bool | float | str,
    ) -> MessageNewProtocolSet:
        """Midea AC device make newprotocol message set."""
        message = MessageNewProtocolSet(self._message_protocol_version)

        # wind_lr_angle
        if attr == DeviceAttributes.wind_lr_angle:
            message.wind_lr_angle = MideaACDevice.get_dict_key_by_value(
                "_wind_lr_angles",
                str(value),
            )
        # wind_ud_angle
        elif attr == DeviceAttributes.wind_ud_angle:
            message.wind_ud_angle = MideaACDevice.get_dict_key_by_value(
                "_wind_ud_angles",
                str(value),
            )
        # fresh_air_power
        elif attr == DeviceAttributes.fresh_air_power:
            if self._fresh_air_version is not None:
                setattr(
                    message,
                    str(self._fresh_air_version),
                    [value, self._attributes[DeviceAttributes.fresh_air_fan_speed]],
                )
        # fresh_air_mode
        elif attr == DeviceAttributes.fresh_air_mode:
            if value in MideaACDevice._fresh_air_fan_speeds.values():
                speed = list(MideaACDevice._fresh_air_fan_speeds.keys())[
                    list(MideaACDevice._fresh_air_fan_speeds.values()).index(
                        str(value),
                    )
                ]
                fresh_air = (
                    [True, speed]
                    if speed > 0
                    else [
                        False,
                        self._attributes[DeviceAttributes.fresh_air_fan_speed],
                    ]
                )
                setattr(message, str(self._fresh_air_version), fresh_air)
            elif not value:
                setattr(
                    message,
                    str(self._fresh_air_version),
                    [False, self._attributes[DeviceAttributes.fresh_air_fan_speed]],
                )
        # fresh_air_fan_speed
        elif attr == DeviceAttributes.fresh_air_fan_speed:
            if self._fresh_air_version is not None:
                fresh_air = (
                    [True, int(value)]
                    if int(value) > 0
                    else [
                        False,
                        self._attributes[DeviceAttributes.fresh_air_fan_speed],
                    ]
                )
                setattr(message, str(self._fresh_air_version), fresh_air)
        # rate_select
        elif attr == DeviceAttributes.rate_select:
            message.rate_select = MideaACDevice.get_dict_key_by_value(
                "_rate_selects",
                str(value),
            )
        # indirect_wind, screen_display_alternate, breezeless
        else:
            setattr(message, str(attr), value)
        # read current prompt_tone for current set action
        message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]

        return message

    def make_subprotocol_message_set(self) -> MessageSubProtocolSet:
        """Midea AC device make subprotocol message set."""
        message = MessageSubProtocolSet(self._message_protocol_version)
        message.power = self._attributes[DeviceAttributes.power]
        message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]
        message.aux_heating = self._attributes[DeviceAttributes.aux_heating]
        message.mode = self._attributes[DeviceAttributes.mode]
        message.target_temperature = self._attributes[
            DeviceAttributes.target_temperature
        ]
        message.fan_speed = self._attributes[DeviceAttributes.fan_speed]
        message.boost_mode = self._attributes[DeviceAttributes.boost_mode]
        message.dry = self._attributes[DeviceAttributes.dry]
        message.eco_mode = self._attributes[DeviceAttributes.eco_mode]
        message.sleep_mode = self._attributes[DeviceAttributes.sleep_mode]
        message.sn8_flag = self._bb_sn8_flag
        message.timer = self._bb_timer
        return message

    def make_subprotocol_fresh_air_set(
        self,
        attr: str,
        value: bool | float | str,
    ) -> MessageSubProtocolFreshAirSet:
        """Build a BB fresh-air intake or exhaust single-control command."""
        exhaust = attr in {
            DeviceAttributes.fresh_air_exhaust_power,
            DeviceAttributes.fresh_air_exhaust_speed,
            DeviceAttributes.fresh_air_exhaust_mode,
        }
        power_attribute = (
            DeviceAttributes.fresh_air_exhaust_power
            if exhaust
            else DeviceAttributes.fresh_air_power
        )
        speed_attribute = (
            DeviceAttributes.fresh_air_exhaust_speed
            if exhaust
            else DeviceAttributes.fresh_air_fan_speed
        )
        mode_attribute = (
            DeviceAttributes.fresh_air_exhaust_mode
            if exhaust
            else DeviceAttributes.fresh_air_mode
        )
        current_speed = int(
            self._attributes[speed_attribute]
            or (
                # Intake can safely fall back to "medium"; exhaust must use a
                # speed present in _bb_fresh_air_exhaust_speeds.
                BB_FRESH_AIR_EXHAUST_DEFAULT_SPEED
                if exhaust
                else BB_FRESH_AIR_DEFAULT_SPEED
            ),
        )
        power = bool(self._attributes[power_attribute])
        speed = current_speed
        if attr == power_attribute:
            power = bool(value)
        elif attr == speed_attribute:
            requested_speed = max(0, min(int(value), 100))
            power = requested_speed > 0
            speed = requested_speed or current_speed
        elif attr == mode_attribute:
            requested_speed = self.get_dict_key_by_value(
                "_bb_fresh_air_exhaust_speeds"
                if exhaust
                else "_bb_fresh_air_fan_speeds",
                str(value),
            )
            if requested_speed is not None:
                power = requested_speed > 0
                speed = requested_speed or current_speed
        return MessageSubProtocolFreshAirSet(
            self._message_protocol_version,
            power,
            speed,
            exhaust=exhaust,
        )

    def make_message_uniq_set(self) -> MessageSubProtocolSet | MessageGeneralSet:
        """Midea AC device make message unique set."""
        message: MessageSubProtocolSet | MessageGeneralSet
        if self._used_subprotocol:
            message = self.make_subprotocol_message_set()
        else:
            message = self.make_message_set()
        return message

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea AC device set attribute."""
        # if nat a sensor
        message: (
            MessageToggleDisplay
            | MessageNewProtocolSet
            | MessageSubProtocolFreshAirSet
            | MessageSubProtocolSet
            | MessageGeneralSet
            | None
        ) = None
        optimistic_self_clean: bool | None = None
        if attr not in [
            DeviceAttributes.indoor_temperature,
            DeviceAttributes.outdoor_temperature,
            DeviceAttributes.indoor_humidity,
            DeviceAttributes.full_dust,
            DeviceAttributes.total_energy_consumption,
            DeviceAttributes.current_energy_consumption,
            DeviceAttributes.realtime_power,
            DeviceAttributes.compressor_frequency,
            DeviceAttributes.target_compressor_frequency,
            DeviceAttributes.compressor_current,
            DeviceAttributes.compressor_voltage,
            DeviceAttributes.indoor_coil_temperature,
            DeviceAttributes.evaporator_temperature,
            DeviceAttributes.condenser_temperature,
            DeviceAttributes.outdoor_ambient_temperature,
            DeviceAttributes.discharge_pipe_temperature,
            DeviceAttributes.indoor_fan_speed,
            DeviceAttributes.target_indoor_fan_speed,
            DeviceAttributes.water_pump_running,
            DeviceAttributes.compressor_power,
        ]:
            if attr == DeviceAttributes.prompt_tone:
                self._attributes[DeviceAttributes.prompt_tone] = value
                self.update_all({DeviceAttributes.prompt_tone.value: value})
            elif attr == DeviceAttributes.screen_display:
                # The AC firmware only exposes a toggle command for the
                # display, so make the switch idempotent: toggle only when the
                # requested state differs from the last reported state.
                # Otherwise repeated turn_on/turn_off service calls alternate
                # the physical display instead of setting an absolute state.
                # https://github.com/wuwentao/midea_ac_lan/issues/623
                if bool(value) != bool(
                    self._attributes[DeviceAttributes.screen_display],
                ):
                    message = MessageToggleDisplay(self._message_protocol_version)
                    message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]
            elif self._model_capabilities.has_bb_fresh_air and attr in {
                DeviceAttributes.fresh_air_power,
                DeviceAttributes.fresh_air_fan_speed,
                DeviceAttributes.fresh_air_mode,
                DeviceAttributes.fresh_air_exhaust_power,
                DeviceAttributes.fresh_air_exhaust_speed,
                DeviceAttributes.fresh_air_exhaust_mode,
            }:
                message = self.make_subprotocol_fresh_air_set(attr, value)
            elif attr in [
                DeviceAttributes.indirect_wind,
                DeviceAttributes.breezeless,
                DeviceAttributes.screen_display_alternate,
                DeviceAttributes.fresh_air_power,
                DeviceAttributes.fresh_air_fan_speed,
                DeviceAttributes.fresh_air_mode,
                DeviceAttributes.wind_lr_angle,
                DeviceAttributes.wind_ud_angle,
                DeviceAttributes.rate_select,
                DeviceAttributes.out_silent,
                DeviceAttributes.sound,
                DeviceAttributes.self_clean,
            ]:
                message = self.make_newprotocol_message_set(attr=attr, value=value)
                if attr == DeviceAttributes.self_clean:
                    optimistic_self_clean = bool(value)
            elif attr == DeviceAttributes.power_saving and self._used_subprotocol:
                _LOGGER.debug(
                    "[%s] Power saving is unsupported by the AC subprotocol",
                    self.device_id,
                )
            elif attr in self._attributes:
                message = self.make_message_uniq_set()
                if attr in [
                    DeviceAttributes.boost_mode,
                    DeviceAttributes.power_saving,
                    DeviceAttributes.sleep_mode,
                    DeviceAttributes.frost_protect,
                    DeviceAttributes.comfort_mode,
                    DeviceAttributes.eco_mode,
                ]:
                    message.boost_mode = False
                    if isinstance(message, MessageGeneralSet):
                        message.power_saving = False
                    message.sleep_mode = False
                    message.eco_mode = False
                    if not isinstance(message, MessageSubProtocolSet):
                        message.comfort_mode = False
                        message.frost_protect = False
                setattr(message, str(attr), value)
                if attr == DeviceAttributes.mode:
                    setattr(message, str(DeviceAttributes.power.value), True)
                    # Reset dry flag when changing mode to avoid conflicts
                    # The dry flag (byte 9, bit 0x04) can block mode changes
                    # when transitioning from DRY mode to other modes
                    message.dry = False
                    # Force fan_speed to AUTO when leaving DRY mode
                    if self._attributes[DeviceAttributes.mode] == DRY_MODE:
                        message.fan_speed = 102
        if message is not None:
            self.build_send(message)
            if optimistic_self_clean is not None:
                self._pending_self_clean = (optimistic_self_clean, time.monotonic())
                self._attributes[DeviceAttributes.self_clean] = optimistic_self_clean
                self.update_all(
                    {DeviceAttributes.self_clean.value: optimistic_self_clean},
                )

    def set_target_temperature(
        self,
        target_temperature: float,
        mode: int | None,
        zone: int | None = None,  # noqa: ARG002
    ) -> None:
        """Midea AC device set target temperature."""
        message: MessageSubProtocolSet | MessageGeneralSet = (
            self.make_message_uniq_set()
        )
        message.target_temperature = target_temperature
        if mode is not None:
            message.power = True
            message.mode = mode
        self.build_send(message)

    def set_swing(self, swing_vertical: bool, swing_horizontal: bool) -> None:
        """Midea AC device set swing."""
        message: MessageSubProtocolSet | MessageGeneralSet = (
            self.make_message_uniq_set()
        )
        if isinstance(message, MessageGeneralSet):
            message.swing_vertical = swing_vertical
            message.swing_horizontal = swing_horizontal
        self.build_send(message)

    def set_customize(self, customize: str) -> None:
        """Midea AC device set custommize."""
        self._temperature_step = self._default_temperature_step
        self._power_analysis_method = self._default_power_analysis_method
        self._customize_min_temperature = None
        self._customize_max_temperature = None
        if customize and len(customize) > 0:
            try:
                params = json.loads(customize)
                if params and "temperature_step" in params:
                    self._temperature_step = params.get("temperature_step")
                if params and "power_analysis_method" in params:
                    self._power_analysis_method = params.get("power_analysis_method")
                if params and "min_temperature" in params:
                    self._customize_min_temperature = params.get("min_temperature")
                if params and "max_temperature" in params:
                    self._customize_max_temperature = params.get("max_temperature")
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
            self.update_all({"temperature_step": self._temperature_step})
            self.update_all(self._refresh_temperature_limits())


class MideaAppliance(MideaACDevice):
    """Midea AC appliance."""
