"""Midea local AC device."""

import json
import logging
import time
from dataclasses import dataclass
from enum import StrEnum
from typing import Any, ClassVar, Unpack, cast

from midealan.const import MAX_BYTE_VALUE, DeviceType
from midealan.device import MideaDevice, MideaDeviceInitKwargs
from midealan.message import ListTypes

from .message import (
    _B1_MAX_CAPABILITY_BATCHES,
    _B1_MAX_PROPERTIES_PER_BATCH,
    CapabilitiesAdditionalQuery,
    CapabilitiesQuery,
    CapabilityValue,
    GroupOneQuery,
    GroupSevenQuery,
    GroupTwoQuery,
    GroupZeroQuery,
    HumidityQuery,
    MessageACResponse,
    MessageSubProtocolSet,
    PowerQuery,
    PropertiesCapsQuery,
    PropertiesCapsQuery1,
    PropertiesDefaultQuery,
    PropertiesSet,
    StateQuery,
    StateSet,
    SubProtocolFreshAirSet,
    SubProtocolQuery,
    SubProtocolQuery10,
    SubProtocolQuery11,
    SubProtocolQuery30,
    ToggleDisplay,
    _PropertiesCapsQueryBase,
    format_property_tags,
)

_LOGGER = logging.getLogger(__name__)

ACQuery = (
    SubProtocolQuery
    | StateQuery
    | PropertiesDefaultQuery
    | PropertiesCapsQuery
    | PropertiesCapsQuery1
    | PowerQuery
    | HumidityQuery
    | GroupZeroQuery
    | GroupOneQuery
    | GroupTwoQuery
    | GroupSevenQuery
    | CapabilitiesQuery
    | CapabilitiesAdditionalQuery
)

# AC mode constants
DRY_MODE = 3

# Maps the reported mode value to the capabilities["temperature"] range key.
# auto=1, cool=2, dry=3, heat=4, fan=5; dry and fan reuse the cool range.
TEMPERATURE_LIMIT_MODE_KEYS = {1: "auto", 2: "cool", 3: "cool", 4: "heat", 5: "cool"}
# Fallback range key for an unknown mode (e.g. 0 when the unit is off).
TEMPERATURE_LIMIT_DEFAULT_KEY = "cool"


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
    degerming = "degerming"
    ieco = "ieco"
    pmv = "pmv"
    error_code = "error_code"
    # group 1: compressor and refrigerant circuit
    compressor_frequency = "compressor_frequency"
    target_compressor_frequency = "target_compressor_frequency"
    compressor_current = "compressor_current"
    compressor_voltage = "compressor_voltage"
    indoor_ambient_temperature = "indoor_ambient_temperature"  # T1
    indoor_coil_temperature = "indoor_coil_temperature"  # T2
    outdoor_coil_temperature = "outdoor_coil_temperature"  # T3
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
C0_TEMPERATURE_FIX_KEYS = frozenset(
    {
        ("220F4047", 8),  # midea_ac_lan#998
    },
)
C0_OUTDOOR_TEMPERATURE_PLACEHOLDERS = frozenset({0x20})
C0_INDOOR_TEMPERATURE_INDEX = 11
C0_OUTDOOR_TEMPERATURE_INDEX = 12
C0_TEMPERATURE_DECIMAL_INDEX = 15
C0_TEMPERATURE_DECIMAL_MIN_BODY_LENGTH = 20
C0_TEMPERATURE_DIVISOR = 2
C0_TEMPERATURE_DECIMAL_FACTOR = 0.1


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

    _rate_select_level5: ClassVar[dict[int, str]] = {
        1: "1",
        20: "20",
        40: "40",
        60: "60",
        80: "80",
        100: "100",
    }

    _rate_select_level2: ClassVar[dict[int, str]] = {
        50: "50",
        75: "75",
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
                DeviceAttributes.degerming: False,
                DeviceAttributes.ieco: False,
                DeviceAttributes.pmv: None,
                DeviceAttributes.error_code: 0,
                DeviceAttributes.compressor_frequency: None,
                DeviceAttributes.target_compressor_frequency: None,
                DeviceAttributes.compressor_current: None,
                DeviceAttributes.compressor_voltage: None,
                DeviceAttributes.indoor_ambient_temperature: None,
                DeviceAttributes.indoor_coil_temperature: None,
                DeviceAttributes.outdoor_coil_temperature: None,
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
        # Current iECO gear the device reports; echoed back when setting iECO.
        self._ieco_number: int = 1
        self._default_temperature_step: float = 0.5
        self._temperature_step: float = 0.5
        self._used_subprotocol: bool = self._model_capabilities.uses_bb_protocol
        self._bb_sn8_flag: bool = False
        self._bb_timer: bool = False
        # decoded B5 capability flags (accumulated across B5 frames). Values are
        # mostly booleans, but some are ints (e.g. rate_select level count) or a
        # nested per-mode setpoint-limit map (the "temperature" key).
        self._capabilities: dict[str, CapabilityValue] = {}
        # user-provided capability overrides from customize. Merged over the
        # B5-parsed values (see the capabilities property), so a user can force
        # a feature the B5 query missed, or disable one it reported in error.
        self._customize_capabilities: dict[str, CapabilityValue] = {}
        # B5 capability query control. Both queries run once, like the appliance
        # query: on success the flag is cleared so it is never re-sent (the reply
        # never changes); on timeout the device layer records it in
        # _unsupported_protocol so it is skipped too. The additional query is
        # only armed after the basic frame advertises a second frame.
        self._capability_query = True
        self._capability_addition_query = False
        self._support_capability = False
        self._support_capability_addition = False
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

    def _rate_select_map(self) -> dict[int, str]:
        """Return the rate_select value map for the device-reported level count.

        The electricity_capability reports a rate level count: 1 selects the
        2-gear map (50/75/100), 2 or 3 select the 5-gear map. Anything else
        (including 0/unsupported) yields an empty map so no options are offered.
        """
        _levels = cast("int", self.capabilities.get("rate_select", 0))
        if _levels in (2, 3):
            return MideaACDevice._rate_select_level5
        if _levels == 1:
            return MideaACDevice._rate_select_level2
        return {}

    @property
    def rate_selects(self) -> list[str]:
        """Midea AC device rate_select options."""
        return list(self._rate_select_map().values())

    def build_query(self) -> list[ACQuery]:
        """Midea AC device build query."""
        if self._used_subprotocol:
            # BB responses are independent status groups. Query each group with
            # its own identity so an unsupported response for one group does not
            # suppress later status groups.
            return [
                SubProtocolQuery10(self._message_protocol_version),
                SubProtocolQuery11(self._message_protocol_version),
                SubProtocolQuery30(self._message_protocol_version),
            ]

        # Split new-protocol queries into independent batches.
        default_query = PropertiesDefaultQuery(self._message_protocol_version)
        queries: list[ACQuery] = [
            StateQuery(self._message_protocol_version),
            default_query,
        ]
        _LOGGER.debug(
            "[%s] PropertiesDefaultQuery: %d properties [%s]",
            self._device_id,
            len(default_query.properties),
            format_property_tags(default_query.properties),
        )

        # Dynamically build capability-based properties queries
        # Collect all capability properties and split into batches
        all_caps_properties = _PropertiesCapsQueryBase.collect_capability_properties(
            self.capabilities,
        )

        if all_caps_properties:
            capacity = _B1_MAX_PROPERTIES_PER_BATCH * _B1_MAX_CAPABILITY_BATCHES
            num_batches = min(
                (len(all_caps_properties) + _B1_MAX_PROPERTIES_PER_BATCH - 1)
                // _B1_MAX_PROPERTIES_PER_BATCH,
                _B1_MAX_CAPABILITY_BATCHES,
            )

            # One class per dynamic batch, in order. Their count defines the
            # capacity (_B1_MAX_CAPABILITY_BATCHES); extend both lists together
            # to add headroom for future property tags.
            batch_classes = (PropertiesCapsQuery, PropertiesCapsQuery1)
            for index in range(num_batches):
                start = index * _B1_MAX_PROPERTIES_PER_BATCH
                subset = all_caps_properties[
                    start : start + _B1_MAX_PROPERTIES_PER_BATCH
                ]
                batch_query = batch_classes[index](
                    self._message_protocol_version,
                    properties_subset=subset,
                )
                queries.append(batch_query)
                _LOGGER.debug(
                    "[%s] %s: %d properties [%s]",
                    self._device_id,
                    type(batch_query).__name__,
                    len(batch_query.properties),
                    format_property_tags(batch_query.properties),
                )

            # Warn if the pool exceeds total capacity; excess tags are dropped.
            if len(all_caps_properties) > capacity:
                _LOGGER.warning(
                    "[%s] Capability properties exceed %d (found %d), "
                    "truncating to %d batches: dropped [%s]",
                    self._device_id,
                    capacity,
                    len(all_caps_properties),
                    _B1_MAX_CAPABILITY_BATCHES,
                    format_property_tags(all_caps_properties[capacity:]),
                )
        else:
            _LOGGER.debug(
                "[%s] No capability properties to query (default properties only)",
                self._device_id,
            )

        queries.extend(
            [
                PowerQuery(self._message_protocol_version),
                HumidityQuery(self._message_protocol_version),
                GroupZeroQuery(self._message_protocol_version),
                # Devices that do not answer a group query are detected during the
                # initial protocol check and the query is skipped from then on.
                GroupOneQuery(self._message_protocol_version),
                GroupTwoQuery(self._message_protocol_version),
                GroupSevenQuery(self._message_protocol_version),
                # Capability queries are not part of the recurring status cycle. They
                # run once at connect time via build_init_query() while the
                # _capability_query / _capability_addition_query flags are set.
            ],
        )

        return queries

    def build_init_query(self) -> list[ACQuery]:
        """Return the B5 capability probes that are still due.

        Both probes are one-shot. The basic query is armed at construction; the
        additional query is armed only after the basic reply advertises a second
        frame (see _update_capabilities). Each flag is cleared once its reply is
        parsed, so a fully-probed device returns an empty list and stops sending
        capability queries. The subprotocol (BB) devices do not use B5.
        """
        if self._used_subprotocol:
            return []
        queries: list[ACQuery] = []
        if self._capability_query:
            queries.append(CapabilitiesQuery(self._message_protocol_version))
        if self._capability_addition_query:
            queries.append(
                CapabilitiesAdditionalQuery(self._message_protocol_version),
            )
        return queries

    def reset_init_query(self) -> None:
        """Re-arm the B5 capability probes after a socket close.

        Mirrors the appliance-query re-arm: a reconnected device re-probes its
        capabilities from scratch rather than reusing the previous result. The
        additional probe stays disarmed until the fresh basic frame advertises a
        second frame again. Accumulated _capabilities are left in place so the
        HA integration keeps the last known set until the re-probe overwrites it.
        """
        self._capability_query = True
        self._capability_addition_query = False
        self._support_capability = False
        self._support_capability_addition = False

    def _fix_c0_temperature(self, message: MessageACResponse) -> None:
        """Correct C0 temperature encoding for verified model/subtype pairs."""
        if (
            self._model_key not in C0_TEMPERATURE_FIX_KEYS
            or message.body_type != ListTypes.C0
        ):
            return
        body = message.body
        if len(body) <= C0_OUTDOOR_TEMPERATURE_INDEX:
            return
        decimal = (
            body[C0_TEMPERATURE_DECIMAL_INDEX]
            if len(body) > C0_TEMPERATURE_DECIMAL_MIN_BODY_LENGTH
            else 0
        )
        indoor_temperature = body[C0_INDOOR_TEMPERATURE_INDEX]
        setattr(
            message,
            DeviceAttributes.indoor_temperature,
            (
                None
                if indoor_temperature == MAX_BYTE_VALUE
                else indoor_temperature / C0_TEMPERATURE_DIVISOR
                + (decimal & 0x0F) * C0_TEMPERATURE_DECIMAL_FACTOR
            ),
        )
        if body[C0_OUTDOOR_TEMPERATURE_INDEX] in C0_OUTDOOR_TEMPERATURE_PLACEHOLDERS:
            setattr(message, DeviceAttributes.outdoor_temperature, None)

    def process_message(self, msg: bytes) -> dict[str, Any]:  # noqa: C901
        """Midea AC device process message."""
        message = MessageACResponse(
            bytearray(msg),
            power_analysis_method=self._power_analysis_method,
            new_protocol_temperature=self._uses_new_protocol_temperature,
        )
        self._fix_c0_temperature(message)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = {}
        has_fresh_air = False
        body_type = getattr(message, "body_type", None)

        if getattr(message, "has_new_protocol_temperature", False):
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
                # rate_select
                elif attr == DeviceAttributes.rate_select:
                    self._attributes[attr] = self._rate_select_map().get(value)
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
        if hasattr(message, "ieco_number"):
            self._ieco_number = message.ieco_number
        if hasattr(message, "self_clean_active"):
            active = message.self_clean_active
            update_self_clean = True
            if self._pending_self_clean is not None:
                expected, set_at = self._pending_self_clean
                elapsed = time.monotonic() - set_at
                if active == expected or elapsed >= self._self_clean_pending_timeout:
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
        if hasattr(message, "degerming_active"):
            self._attributes[DeviceAttributes.degerming] = message.degerming_active
            new_status[DeviceAttributes.degerming.value] = message.degerming_active
        # Merge capabilities first so a B5 frame's temperature limits are in the
        # merged map before the setpoint limits are resolved from it.
        new_status.update(self._update_capabilities(message))
        new_status.update(self._refresh_temperature_limits())
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

    def _update_capabilities(self, message: MessageACResponse) -> dict[str, Any]:
        """Merge B5 capability flags and advance the capability query state.

        A B5 reply resolves the query it answered: the basic frame clears
        _capability_query (and arms the additional query when the device
        advertises a second frame), while the additional frame clears
        _capability_addition_query. Both are one-shot, so once cleared here the
        query is never re-sent.

        Returns a status update carrying the merged ``capabilities`` dict so the
        consumer (e.g. the HA integration, which reads ``device.capabilities``)
        is notified as soon as a frame is decoded, instead of holding the empty
        dict seen at initialization. Returns an empty dict for non-B5 messages.
        """
        if not hasattr(message, "capabilities"):
            return {}
        self._capabilities.update(message.capabilities)

        additional_pending = self._capability_addition_query
        if additional_pending:
            # This reply answers the additional (all_second_frame) query.
            self._support_capability_addition = True
            self._capability_addition_query = False
        else:
            # This reply answers the basic (all_first_frame) query.
            self._support_capability = True
            self._capability_query = False
            if getattr(message, "additional_capabilities", False):
                # Device advertises a second frame; arm the additional query so
                # the next refresh_status() prepends it.
                self._capability_addition_query = True

        _LOGGER.debug(
            "[%s] Capability state: support=%s support_addition=%s "
            "addition_pending=%s merged=%s",
            self.device_id,
            self._support_capability,
            self._support_capability_addition,
            self._capability_addition_query,
            self._capabilities,
        )
        # Publish the effective (merged) map so downstream consumers see the
        # customize overrides too; it is already a fresh dict per access.
        return {"capabilities": self.capabilities}

    @property
    def capabilities(self) -> dict[str, CapabilityValue]:
        """Return the effective capability flags for the device.

        This is the B5-parsed capability map overlaid with the user's customize
        overrides, so a customize entry wins over whatever the device reported
        (or failed to report).
        """
        return {**self._capabilities, **self._customize_capabilities}

    @property
    def supported_hvac_modes(self) -> list[str]:
        """Return list of supported HVAC modes for Home Assistant.

        Priority: customize > B5 capabilities > default full set.

        Maps device modes to HA climate entity modes:
        - off (always supported)
        - auto, cool, heat, dry, fan_only

        Returns:
            List of HA-compatible HVAC mode strings in canonical order.

        """
        # Priority 1: customize override (if "modes" explicitly set)
        if "modes" in self._customize_capabilities:
            modes = ["off"]
            customize_modes_raw = self._customize_capabilities["modes"]
            customize_modes = (
                customize_modes_raw if isinstance(customize_modes_raw, list) else []
            )
            mode_map = ["auto", "cool", "heat", "dry"]
            modes.extend(mode for mode in mode_map if mode in customize_modes)
            # fan_only: only if explicitly enabled in customize
            if self._customize_capabilities.get("fan_only"):
                modes.append("fan_only")
            return modes

        # Priority 2: B5 capabilities (if device reported B5 response)
        if "modes" in self._capabilities:
            modes = ["off"]
            device_modes_raw = self._capabilities.get("modes", [])
            device_modes = (
                device_modes_raw if isinstance(device_modes_raw, list) else []
            )
            mode_map = ["auto", "cool", "heat", "dry"]
            modes.extend(mode for mode in mode_map if mode in device_modes)
            # fan_only: only if explicitly enabled in customize
            if self._customize_capabilities.get("fan_only"):
                modes.append("fan_only")
            return modes

        # Priority 3: default full set (for devices without B5 support)
        modes = ["off", "auto", "cool", "heat", "dry"]
        # fan_only: only if explicitly enabled in customize
        if self._customize_capabilities.get("fan_only"):
            modes.append("fan_only")
        return modes

    @property
    def supported_fan_modes(self) -> list[str]:
        """Return list of supported fan modes for Home Assistant.

        Priority: customize > B5 capabilities > default full set.

        Maps device fan speeds to HA fan mode names in canonical order.
        Special case: if "custom" is in the list, return full set.

        Returns:
            List of HA-compatible fan mode strings.

        """
        fan_map = ["auto", "silent", "low", "medium", "high", "custom"]

        # Priority 1: customize override (if "fan_speeds" explicitly set)
        if "fan_speeds" in self._customize_capabilities:
            customize_speeds_raw = self._customize_capabilities["fan_speeds"]
            customize_speeds = (
                customize_speeds_raw if isinstance(customize_speeds_raw, list) else []
            )
            return [speed for speed in fan_map if speed in customize_speeds]

        # Priority 2: B5 capabilities (if device reported B5 response)
        if "fan_speeds" in self._capabilities:
            device_speeds_raw = self._capabilities.get("fan_speeds", [])
            device_speeds = (
                device_speeds_raw if isinstance(device_speeds_raw, list) else []
            )
            # If custom is in the list, return full set
            if "custom" in device_speeds:
                return fan_map
            return [speed for speed in fan_map if speed in device_speeds]

        # Priority 3: default full set (for devices without B5 support)
        return fan_map

    @property
    def supported_swing_modes(self) -> list[str]:
        """Return list of supported swing modes for Home Assistant.

        Priority: customize > B5 capabilities > default full set.

        Derives combined swing modes from device capabilities:
        - off (always supported - no swing)
        - vertical (if vertical in capabilities)
        - horizontal (if horizontal in capabilities)
        - both (if both vertical and horizontal supported)

        Returns:
            List of HA-compatible swing mode strings.

        """
        modes = ["off"]  # Always supported

        # Priority 1: customize override (if "swing_modes" explicitly set)
        if "swing_modes" in self._customize_capabilities:
            directions_raw = self._customize_capabilities["swing_modes"]
            directions = directions_raw if isinstance(directions_raw, list) else []
            has_vertical = "vertical" in directions
            has_horizontal = "horizontal" in directions
            if has_vertical:
                modes.append("vertical")
            if has_horizontal:
                modes.append("horizontal")
            if has_vertical and has_horizontal:
                modes.append("both")
            return modes

        # Priority 2: B5 capabilities (if device reported B5 response)
        if "swing_modes" in self._capabilities:
            directions_raw = self._capabilities.get("swing_modes", [])
            directions = directions_raw if isinstance(directions_raw, list) else []
            has_vertical = "vertical" in directions
            has_horizontal = "horizontal" in directions
            if has_vertical:
                modes.append("vertical")
            if has_horizontal:
                modes.append("horizontal")
            if has_vertical and has_horizontal:
                modes.append("both")
            return modes

        # Priority 3: default full set (for devices without B5 support)
        return ["off", "vertical", "horizontal", "both"]

    @property
    def supported_preset_modes(self) -> list[str]:
        """Return list of supported preset modes for Home Assistant.

        Priority: customize > B5 capabilities > default basic set.

        Default presets (always available):
        - none, comfort, eco, boost, sleep

        B5-only presets (only if reported by device):
        - ieco (if ieco in capabilities)

        Returns:
            List of HA-compatible preset mode strings.

        """
        # Priority 1: customize override
        # Check if customize has explicit preset feature flags
        has_customize_features = any(
            key in self._customize_capabilities
            for key in [
                "eco_mode",
                "ieco",
                "turbo_cool",
                "turbo_heat",
                "sleep_mode",
                "comfort_mode",
            ]
        )

        if has_customize_features:
            # Use merged capabilities (customize overrides B5)
            caps = {**self._capabilities, **self._customize_capabilities}
            presets = ["none"]
            if caps.get("comfort_mode", True):
                presets.append("comfort")
            if caps.get("eco_mode"):
                presets.append("eco")
            if caps.get("turbo_cool") or caps.get("turbo_heat"):
                presets.append("boost")
            if caps.get("sleep_mode", True):
                presets.append("sleep")
            if caps.get("ieco"):
                presets.append("ieco")
            return presets

        # Priority 2: B5 capabilities (if device reported B5 response)
        if self._capabilities:
            caps = self._capabilities
            # Check if we have modes (indicator of B5 support)
            if "modes" in caps:
                presets = ["none", "comfort"]  # always available
                if caps.get("eco_mode"):
                    presets.append("eco")
                if caps.get("turbo_cool") or caps.get("turbo_heat"):
                    presets.append("boost")
                presets.append("sleep")  # always available
                # B5-only presets
                if caps.get("ieco"):
                    presets.append("ieco")
                return presets

        # Priority 3: default basic set (for devices without B5 support)
        return ["none", "comfort", "eco", "boost", "sleep"]

    def _capability_temperature_limits(self) -> tuple[float, float] | None:
        """Return the capability setpoint limits for the current mode, if any.

        Reads the per-mode limits from the merged ``capabilities`` map (the
        nested ``temperature`` entry). An unknown mode (e.g. 0 when off) falls
        back to the cool range.
        """
        temperature = self.capabilities.get("temperature")
        if not isinstance(temperature, dict):
            return None
        mode = self._attributes[DeviceAttributes.mode]
        range_key = TEMPERATURE_LIMIT_MODE_KEYS.get(
            mode,
            TEMPERATURE_LIMIT_DEFAULT_KEY,
        )
        limits = temperature.get(range_key)
        if not isinstance(limits, dict):
            return None
        # Validate that both min and max keys exist before indexing
        if "min" not in limits or "max" not in limits:
            return None
        return (limits["min"], limits["max"])

    def _refresh_temperature_limits(self) -> dict[str, Any]:
        """Resolve min/max setpoint limits.

        Priority: customize option > capability response > None (the consumer
        then falls back to its own default range).
        """
        capability_limits = self._capability_temperature_limits()
        minimum = self._customize_min_temperature
        if minimum is None and capability_limits is not None:
            minimum = capability_limits[0]
        maximum = self._customize_max_temperature
        if maximum is None and capability_limits is not None:
            maximum = capability_limits[1]
        self._attributes[DeviceAttributes.min_temperature] = minimum
        self._attributes[DeviceAttributes.max_temperature] = maximum
        return {
            DeviceAttributes.min_temperature.value: minimum,
            DeviceAttributes.max_temperature.value: maximum,
        }

    def make_message_set(self) -> StateSet:
        """Midea AC device make message set."""
        message = StateSet(self._message_protocol_version)
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
    ) -> PropertiesSet:
        """Midea AC device make newprotocol message set."""
        message = PropertiesSet(self._message_protocol_version)

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
            rate_map = self._rate_select_map()
            message.rate_select = next(
                (key for key, val in rate_map.items() if val == str(value)),
                None,
            )
        # iECO on/off — echo the last reported gear number
        elif attr == DeviceAttributes.ieco:
            message.ieco = bool(value)
            message.ieco_number = self._ieco_number
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
    ) -> SubProtocolFreshAirSet:
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
        return SubProtocolFreshAirSet(
            self._message_protocol_version,
            power,
            speed,
            exhaust=exhaust,
        )

    def make_message_uniq_set(self) -> MessageSubProtocolSet | StateSet:
        """Midea AC device make message unique set."""
        message: MessageSubProtocolSet | StateSet
        if self._used_subprotocol:
            message = self.make_subprotocol_message_set()
        else:
            message = self.make_message_set()
        return message

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea AC device set attribute."""
        # if nat a sensor
        message: (
            ToggleDisplay
            | PropertiesSet
            | SubProtocolFreshAirSet
            | MessageSubProtocolSet
            | StateSet
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
            DeviceAttributes.indoor_ambient_temperature,
            DeviceAttributes.indoor_coil_temperature,
            DeviceAttributes.outdoor_coil_temperature,
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
                    message = ToggleDisplay(self._message_protocol_version)
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
                DeviceAttributes.ieco,
                DeviceAttributes.degerming,
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
                    if isinstance(message, StateSet):
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
                    # Optimistically reflect the commanded state in the cache so
                    # an immediate follow-up write (e.g. set_target_temperature,
                    # which serializes a full packet from make_message_uniq_set)
                    # is built from power=True and the new mode. Without this the
                    # follow-up reuses the stale last-confirmed power=False and
                    # turns the unit back off before the mode response arrives.
                    # https://github.com/midea-lan/midea-local/issues/495
                    self._attributes[DeviceAttributes.power] = True
                    self._attributes[DeviceAttributes.mode] = value
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
        message: MessageSubProtocolSet | StateSet = self.make_message_uniq_set()
        message.target_temperature = target_temperature
        if mode is not None:
            message.power = True
            message.mode = mode
        self.build_send(message)

    def set_swing(self, swing_vertical: bool, swing_horizontal: bool) -> None:
        """Midea AC device set swing."""
        message: MessageSubProtocolSet | StateSet = self.make_message_uniq_set()
        if isinstance(message, StateSet):
            message.swing_vertical = swing_vertical
            message.swing_horizontal = swing_horizontal
        self.build_send(message)

    def set_customize(self, customize: str) -> None:
        """Midea AC device set custommize."""
        self._temperature_step = self._default_temperature_step
        self._power_analysis_method = self._default_power_analysis_method
        self._customize_min_temperature = None
        self._customize_max_temperature = None
        self._customize_capabilities = {}
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
                # Capability overrides let a user force a feature the B5 query
                # missed (or disable one it wrongly reported). Values follow the
                # capabilities map: truthy enables the tag, falsy disables it.
                if params and isinstance(params.get("capabilities"), dict):
                    caps_input = params["capabilities"]
                    # Normalize capabilities: convert legacy dict format to array
                    normalized_caps: dict[str, Any] = {}
                    for key, value in caps_input.items():
                        if key in ("modes", "fan_speeds", "swing_modes"):
                            if isinstance(value, dict):
                                # Legacy dict format: {"heat": true, "cool": true}
                                # Convert to array: ["heat", "cool"]
                                normalized_caps[key] = [
                                    k for k, v in value.items() if v
                                ]
                            elif isinstance(value, list):
                                # New array format: ["heat", "cool"]
                                # Validate all elements are strings
                                if all(isinstance(item, str) for item in value):
                                    normalized_caps[key] = value
                                else:
                                    # Invalid array elements, skip with warning
                                    _LOGGER.warning(
                                        "[%s] Invalid capability array for %s: "
                                        "contains non-string elements",
                                        self.device_id,
                                        key,
                                    )
                                    continue
                            else:
                                # Invalid format, skip with warning
                                _LOGGER.warning(
                                    "[%s] Invalid capability format for %s: %s",
                                    self.device_id,
                                    key,
                                    type(value).__name__,
                                )
                                continue
                        else:
                            # Other capabilities remain as-is
                            normalized_caps[key] = value
                    self._customize_capabilities = normalized_caps
            except Exception:
                _LOGGER.exception("[%s] Set customize error", self.device_id)
            self.update_all({"temperature_step": self._temperature_step})
            self.update_all(self._refresh_temperature_limits())
        # Publish the merged capabilities map so downstream consumers (e.g., Home
        # Assistant) are notified whenever customize overrides change it.
        self.update_all({"capabilities": self.capabilities})


class MideaAppliance(MideaACDevice):
    """Midea AC appliance."""
