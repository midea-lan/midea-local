"""Midea local AC device."""

import logging
import time
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any, ClassVar, Unpack, cast, override

from midealocal.base_classes.climate import (
    DEFAULT_MAX_TARGET_TEMPERATURE,
    DEFAULT_MIN_TARGET_TEMPERATURE,
    TEMPERATURE_STEP_HALF,
    MideaClimateDevice,
    MideaFanMode,
    MideaHVACMode,
    MideaPreset,
    MideaSwingMode,
)
from midealocal.const import MANUFACTURER_CODE_TOSHIBA, DeviceType
from midealocal.const.climate_exceptions import AC_EXCEPTIONS
from midealocal.device import SKIP_ATTRIBUTE, MideaDeviceInitKwargs
from midealocal.message import ListTypes

from .message import (
    TOSHIBA_PROTOCOL_VERSION,
    ACFanSpeed,
    ACSwingMode,
    DeviceAttributes,
    MessageACResponse,
    MessageCapabilitiesAdditionalQuery,
    MessageCapabilitiesQuery,
    MessageGeneralSet,
    MessageGroupOneQuery,
    MessageGroupSevenQuery,
    MessageGroupThreeQuery,
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
    MessageSubProtocolResetFilter,
    MessageSubProtocolSet,
    MessageToggleDisplay,
    MessageToshibaSet,
    ToshibaPropertyTags,
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
    | MessageGroupThreeQuery
    | MessageGroupTwoQuery
    | MessageGroupSevenQuery
    | MessageCapabilitiesQuery
    | MessageCapabilitiesAdditionalQuery
)

# AC mode constants
DRY_MODE = 3


class DeviceHVACMode(MideaHVACMode):
    """Midea AC HVAC modes."""

    OFF = 0
    AUTO = 1
    COOL = 2
    DRY = 3
    HEAT = 4
    FAN_ONLY = 5


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

# Toshiba IoLife units (manufacturer code 0008) speak their own property
# protocol; see ToshibaPropertyTags. The attributes it can report or set:
TOSHIBA_ATTRIBUTES = frozenset(
    {
        DeviceAttributes.prompt_tone,
        DeviceAttributes.power,
        DeviceAttributes.mode,
        DeviceAttributes.target_temperature,
        DeviceAttributes.min_temperature,
        DeviceAttributes.max_temperature,
        DeviceAttributes.fan_speed,
        DeviceAttributes.swing_vertical,
        DeviceAttributes.swing_horizontal,
        DeviceAttributes.wind_ud_angle,
        DeviceAttributes.wind_lr_angle,
        DeviceAttributes.indoor_temperature,
        DeviceAttributes.outdoor_temperature,
        DeviceAttributes.indoor_humidity,
        DeviceAttributes.eco_mode,
        DeviceAttributes.anion,
        DeviceAttributes.dry,
        DeviceAttributes.comfort_mode,
        DeviceAttributes.screen_display,
        DeviceAttributes.breezeless,
        DeviceAttributes.self_clean,
        DeviceAttributes.full_dust,
        DeviceAttributes.error_code,
    },
)
TOSHIBA_EXTRA_ATTRIBUTES: Mapping[DeviceAttributes, Any] = {
    DeviceAttributes.breezeless_direction: None,
    DeviceAttributes.clean_manual: False,
    DeviceAttributes.cleaning: False,
    DeviceAttributes.dehumidify: 0,
    DeviceAttributes.energy_save: False,
}
# Read-only attributes are ignored rather than warned about, so a consumer that
# writes every attribute back does not spam the log.
TOSHIBA_READ_ONLY_ATTRIBUTES = frozenset(
    {
        DeviceAttributes.indoor_temperature,
        DeviceAttributes.outdoor_temperature,
        DeviceAttributes.indoor_humidity,
        DeviceAttributes.min_temperature,
        DeviceAttributes.max_temperature,
        DeviceAttributes.full_dust,
        DeviceAttributes.error_code,
        DeviceAttributes.cleaning,
    },
)
# The protocol has no capability query, so report what every IoLife unit has;
# MideaACDevice.attributes hides capability-gated attributes not listed here.
TOSHIBA_CAPABILITIES: Mapping[str, bool] = {
    "anion": True,
    "display_control": True,
    "humidity": True,
    "swing_horizontal_angle": True,
    "swing_vertical_angle": True,
}
# Setpoint range of the target_temperature property, in degrees Celsius.
TOSHIBA_MIN_TARGET_TEMPERATURE = 16.0
TOSHIBA_MAX_TARGET_TEMPERATURE = 32.0
# Attributes written as a 0/1 flag or as a single raw byte.
TOSHIBA_BOOL_PROPERTIES: Mapping[str, ToshibaPropertyTags] = {
    DeviceAttributes.power: ToshibaPropertyTags.power,
    DeviceAttributes.eco_mode: ToshibaPropertyTags.eco_mode,
    DeviceAttributes.anion: ToshibaPropertyTags.anion,
    DeviceAttributes.energy_save: ToshibaPropertyTags.energy_save,
    DeviceAttributes.comfort_mode: ToshibaPropertyTags.comfort_mode,
}
TOSHIBA_BYTE_PROPERTIES: Mapping[str, ToshibaPropertyTags] = {
    DeviceAttributes.fan_speed: ToshibaPropertyTags.fan_speed,
    DeviceAttributes.swing_vertical: ToshibaPropertyTags.swing_vertical,
    DeviceAttributes.swing_horizontal: ToshibaPropertyTags.swing_horizontal,
    DeviceAttributes.dehumidify: ToshibaPropertyTags.dehumidify,
    DeviceAttributes.breezeless: ToshibaPropertyTags.breezeless,
}
# screen_display is a 0-100 backlight brightness, driven as an on/off switch.
TOSHIBA_SCREEN_DISPLAY_ON = 100
# Upper bound the firmware accepts for a deflector angle.
TOSHIBA_MAX_WIND_ANGLE = 100
# Deflection directions of the breezeless airflow; breezeless is its on/off.
TOSHIBA_BREEZELESS_DIRECTIONS: Mapping[int, str] = {
    0: "off",
    1: "full",
    2: "left",
    3: "right",
}
# Dry sub-modes of the dehumidify property.
TOSHIBA_DEHUMIDIFY_WEAK = 1
TOSHIBA_DEHUMIDIFY_STRONG = 2
TOSHIBA_DEHUMIDIFY_RECOMMENDED = 4
# The unit drives the fan itself in dry mode, so the sub-mode stands in for the
# fan setting there, each reported as the speed a consumer shows by that name.
TOSHIBA_DRY_FAN_SPEEDS: Mapping[int, ACFanSpeed] = {
    TOSHIBA_DEHUMIDIFY_WEAK: ACFanSpeed.LOW,
    TOSHIBA_DEHUMIDIFY_STRONG: ACFanSpeed.HIGH,
    TOSHIBA_DEHUMIDIFY_RECOMMENDED: ACFanSpeed.AUTO,
}


def _toshiba_dry_fan_to_dehumidify(speed: int) -> int:
    """Fold a requested fan speed onto the nearest dry sub-mode.

    Silent and low become weak, medium (and auto) recommended, high and full
    strong.
    """
    if speed <= ACFanSpeed.LOW:
        return TOSHIBA_DEHUMIDIFY_WEAK
    if speed <= ACFanSpeed.MEDIUM or speed > ACFanSpeed.FULL:
        return TOSHIBA_DEHUMIDIFY_RECOMMENDED
    return TOSHIBA_DEHUMIDIFY_STRONG


def _toshiba_wind_angle(
    angles: Mapping[int, str],
    value: bool | float | str,
) -> int | None:
    """Resolve a deflector position name (or a raw 0-100 value) to its byte."""
    for raw, name in angles.items():
        if name == value:
            return raw
    try:
        raw_value = int(float(value))
    except (TypeError, ValueError):
        return None
    return raw_value if 0 <= raw_value <= TOSHIBA_MAX_WIND_ANGLE else None


def _toshiba_params(
    attr: str,
    value: bool | float | str,
) -> dict[ToshibaPropertyTags, bytearray] | None:
    """Return the property write for a single-property attribute, if any."""
    if attr in TOSHIBA_BOOL_PROPERTIES:
        return {TOSHIBA_BOOL_PROPERTIES[attr]: bytearray([1 if value else 0])}
    if attr in TOSHIBA_BYTE_PROPERTIES:
        return {TOSHIBA_BYTE_PROPERTIES[attr]: bytearray([int(value)])}
    if attr == DeviceAttributes.target_temperature:
        return {
            ToshibaPropertyTags.target_temperature: bytearray(
                [round(float(value) * 2)],
            ),
        }
    if attr == DeviceAttributes.screen_display:
        # Accept a brightness as-is; a plain switch value becomes 0 or 100.
        brightness = (
            int(float(value))
            if not isinstance(value, bool)
            else TOSHIBA_SCREEN_DISPLAY_ON * value
        )
        return {ToshibaPropertyTags.screen_display: bytearray([brightness])}
    if attr == DeviceAttributes.breezeless_direction:
        for raw, name in TOSHIBA_BREEZELESS_DIRECTIONS.items():
            if name == value:
                return {ToshibaPropertyTags.breezeless_direction: bytearray([raw])}
    return None


class MideaACDevice(MideaClimateDevice):
    """Midea AC device."""

    _capabilities_attr: ClassVar[dict[str, DeviceAttributes]] = {
        "anion": DeviceAttributes.anion,
        "rate_select": DeviceAttributes.rate_select,
        "sound": DeviceAttributes.sound,
        "display_control": DeviceAttributes.screen_display,
        "humidity": DeviceAttributes.indoor_humidity,
        "swing_horizontal_angle": DeviceAttributes.wind_lr_angle,
        "swing_vertical_angle": DeviceAttributes.wind_ud_angle,
    }

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
        25: "left_mid",
        50: "middle",
        75: "right_mid",
        100: "right",
    }

    _wind_ud_angles: ClassVar[dict[int, str]] = {
        0: "off",
        1: "up",
        25: "up_mid",
        50: "middle",
        75: "down_mid",
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

    # Devices whose B5 b5_electricity capability sets RATE_SELECT_2_LEVEL_BIT
    # only support two gears, not the full five-gear table above.
    _rate_selects_2_level: ClassVar[dict[int, str]] = {
        50: "50",
        75: "75",
        100: "100",
    }

    # Generic HVAC mode names, ordered to match the protocol's mode index.
    # Fixed and never filtered: hvac_mode()/set_hvac_mode() index into this
    # to convert to/from the wire's mode int, which is unaffected by which
    # modes the B5 capability response says this unit actually supports.
    _all_hvac_modes: ClassVar[list[DeviceHVACMode]] = [
        DeviceHVACMode.OFF,
        DeviceHVACMode.AUTO,
        DeviceHVACMode.COOL,
        DeviceHVACMode.DRY,
        DeviceHVACMode.HEAT,
        DeviceHVACMode.FAN_ONLY,
    ]

    # Bucket boundaries for the get-side threshold scan: each pair is the
    # next-lower set-point's value paired with the bucket name above it.
    _fan_speed_thresholds: ClassVar[tuple[tuple[int, ACFanSpeed], ...]] = (
        (ACFanSpeed.FULL, ACFanSpeed.AUTO),
        (ACFanSpeed.HIGH, ACFanSpeed.FULL),
        (ACFanSpeed.MEDIUM, ACFanSpeed.HIGH),
        (ACFanSpeed.LOW, ACFanSpeed.MEDIUM),
        (ACFanSpeed.SILENT, ACFanSpeed.LOW),
    )

    # BB (sub-protocol) devices: MessageSubProtocolSet doesn't serialize
    # comfort_mode/frost_protect, so comfort/away are excluded for them below.
    _all_preset_attributes: ClassVar[dict[MideaPreset, str]] = {
        MideaPreset.COMFORT: DeviceAttributes.comfort_mode,
        MideaPreset.ECO: DeviceAttributes.eco_mode,
        MideaPreset.BOOST: DeviceAttributes.boost_mode,
        MideaPreset.SLEEP: DeviceAttributes.sleep_mode,
        MideaPreset.AWAY: DeviceAttributes.frost_protect,
    }
    _bb_unsupported_presets: ClassVar[frozenset[MideaPreset]] = frozenset(
        {MideaPreset.COMFORT, MideaPreset.AWAY},
    )
    _toshiba_preset_attributes: ClassVar[dict[MideaPreset, str]] = {
        MideaPreset.COMFORT: DeviceAttributes.comfort_mode,
        MideaPreset.ECO: DeviceAttributes.eco_mode,
    }

    _swing_modes: ClassVar[dict[ACSwingMode, tuple[bool, bool]]] = {
        ACSwingMode.OFF: (False, False),
        ACSwingMode.VERTICAL: (True, False),
        ACSwingMode.HORIZONTAL: (False, True),
        ACSwingMode.BOTH: (True, True),
    }

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
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
                DeviceAttributes.indoor_ambient_temperature: None,
                DeviceAttributes.indoor_coil_temperature: None,
                DeviceAttributes.outdoor_coil_temperature: None,
                DeviceAttributes.outdoor_ambient_temperature: None,
                DeviceAttributes.discharge_pipe_temperature: None,
                DeviceAttributes.indoor_fan_speed: None,
                DeviceAttributes.target_indoor_fan_speed: None,
                DeviceAttributes.water_pump_running: None,
                DeviceAttributes.outdoor_fan_speed: None,
                DeviceAttributes.compressor_power: None,
            },
        )
        self._is_filter_reset_supported = True
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
        exceptions = AC_EXCEPTIONS.get(str(self.model), {})
        self._temperature_step: float = exceptions.get(
            "temperature_step",
            TEMPERATURE_STEP_HALF,
        )
        self._used_subprotocol: bool = self._model_capabilities.uses_bb_protocol
        self._bb_sn8_flag: bool = False
        self._bb_timer: bool = False
        # per-mode setpoint limits from the B5 capability, keyed by mode value
        self._temperature_limits: dict[int, tuple[float, float]] | None = None
        # decoded B5 capability flags (accumulated across B5 frames)
        self._capabilities: dict[str, bool] = {}
        self._attributes[DeviceAttributes.min_temperature] = exceptions.get(
            "min_temperature",
        )
        self._attributes[DeviceAttributes.max_temperature] = exceptions.get(
            "max_temperature",
        )
        self._power_analysis_method: int = exceptions.get("power_analysis_method", 1)
        # 0x7e temperature decoding is restricted to verified models.
        self._uses_new_protocol_temperature = (
            str(self.model) in NEW_PROTOCOL_TEMPERATURE_MODELS
        )
        # Once 0x7e-derived temperatures are seen, ignore stale C0 temperature
        # fields to avoid brief UI flicker caused by query ordering.
        self._prefer_new_protocol_temperature: bool = False
        self._is_toshiba = self.manufacturer_code == MANUFACTURER_CODE_TOSHIBA
        if self._is_toshiba:
            self._init_toshiba()

    def _init_toshiba(self) -> None:
        """Narrow the device to what a Toshiba IoLife unit supports."""
        # The Toshiba firmware never answers MessageQueryAppliance, so skip it
        # rather than spending a failed query on every connect.
        self._appliance_query = False
        self._is_filter_reset_supported = False
        self._attributes = {
            attr: value
            for attr, value in self._attributes.items()
            if attr in TOSHIBA_ATTRIBUTES
        }
        self._attributes.update(TOSHIBA_EXTRA_ATTRIBUTES)
        self._capabilities = dict(TOSHIBA_CAPABILITIES)
        # Raw deflector angles as last reported or written. The attributes hold
        # names, which cannot represent auto (0xF0) or an angle between steps.
        self._toshiba_wind_angles: dict[DeviceAttributes, int] = {}
        if self._attributes[DeviceAttributes.min_temperature] is None:
            self._attributes[DeviceAttributes.min_temperature] = (
                TOSHIBA_MIN_TARGET_TEMPERATURE
            )
        if self._attributes[DeviceAttributes.max_temperature] is None:
            self._attributes[DeviceAttributes.max_temperature] = (
                TOSHIBA_MAX_TARGET_TEMPERATURE
            )

    @property
    @override
    def _preset_attributes(self) -> Mapping[MideaPreset, str]:
        """Presets supported by this unit.

        BB (sub-protocol) devices drop comfort/away: MessageSubProtocolSet
        doesn't serialize comfort_mode/frost_protect, so those commands
        would have no effect.
        """
        if self._is_toshiba:
            return MideaACDevice._toshiba_preset_attributes
        if self._used_subprotocol:
            return {
                preset: attr
                for preset, attr in MideaACDevice._all_preset_attributes.items()
                if preset not in MideaACDevice._bb_unsupported_presets
            }
        return MideaACDevice._all_preset_attributes

    @property
    @override
    def hvac_modes(self) -> set[MideaHVACMode]:
        """Midea AC device HVAC modes, filtered by the device's B5 capabilities.

        "off"/"fan_only" have no matching capability key (the B5 response
        never reports one named "off_mode"/"fan_only_mode"), so they fall
        through to the default and are always kept.
        """
        modes: set[MideaHVACMode] = set()
        for mode in MideaACDevice._all_hvac_modes:
            if self._capabilities.get(f"{mode.name.lower()}_mode", True):
                modes.add(mode)
        return modes

    @override
    def reset_filter(self) -> None:
        """Reset filter timer."""
        if self._is_toshiba:
            return
        messages: list[
            MessageGeneralSet | MessageSubProtocolResetFilter | MessageNewProtocolSet
        ] = []
        if self._used_subprotocol:
            messages.append(
                MessageSubProtocolResetFilter(self._message_protocol_version),
            )
        else:
            message: MessageGeneralSet | MessageNewProtocolSet = self.make_message_set()
            message.reset_filter = True
            messages.append(message)
            message = MessageNewProtocolSet(self._message_protocol_version)
            message.reset_filter = True
            messages.append(message)

        for m in messages:
            self.build_send(m)

    @override
    def hvac_mode(self, zone: int | None = None) -> MideaHVACMode | None:
        """Midea AC device HVAC mode."""
        power = self._attributes[DeviceAttributes.power]
        if not isinstance(power, bool):
            return None
        if not power:
            return DeviceHVACMode.OFF
        mode = self._attributes[DeviceAttributes.mode]
        try:
            return (
                DeviceHVACMode(mode)
                if DeviceHVACMode(mode) != DeviceHVACMode.OFF
                else None
            )
        except ValueError:
            return None

    @override
    def set_hvac_mode(
        self,
        hvac_mode: MideaHVACMode,
        zone: int | None = None,
    ) -> None:
        """Midea AC device set HVAC mode."""
        if hvac_mode == DeviceHVACMode.OFF:
            self.set_attribute(attr=DeviceAttributes.power, value=False)
            return
        if hvac_mode not in self.hvac_modes:
            msg = f"[ac] Unsupported hvac mode: {hvac_mode}"
            raise ValueError(msg)
        self.set_attribute(
            attr=DeviceAttributes.mode,
            value=hvac_mode,
        )

    @property
    @override
    def fan_modes(self) -> list[MideaFanMode]:
        """Midea AC device fan modes."""
        return [*ACFanSpeed]

    @property
    @override
    def fan_mode(self) -> MideaFanMode | None:
        """Midea AC device fan mode."""
        fan_speed = self._attributes[DeviceAttributes.fan_speed]
        if not isinstance(fan_speed, int):
            return None
        for threshold, fan_mode in MideaACDevice._fan_speed_thresholds:
            if fan_speed > threshold:
                return fan_mode
        return ACFanSpeed.SILENT

    @override
    def set_fan_mode(self, fan_mode: MideaFanMode) -> None:
        """Midea AC device set fan mode."""
        try:
            value = ACFanSpeed[fan_mode.name.upper()]
        except KeyError as err:
            msg = f"[ac] Unsupported fan mode: {fan_mode}"
            raise ValueError(msg) from err
        self.set_attribute(attr=DeviceAttributes.fan_speed, value=int(value))

    @property
    @override
    def swing_modes(self) -> list[MideaSwingMode]:
        """Midea AC device swing modes.

        The BB subprotocol (MessageSubProtocolSet) has no swing fields at
        all, so swing is not advertised for devices using it.
        """
        if self._used_subprotocol:
            return []
        return list(MideaACDevice._swing_modes.keys())

    @property
    @override
    def swing_mode(self) -> MideaSwingMode | None:
        """Midea AC device swing mode."""
        if self._used_subprotocol:
            return None
        # bool() coercion guarantees a (bool, bool) pair, and _swing_modes
        # covers all four, so this always matches.
        vertical = bool(self._attributes[DeviceAttributes.swing_vertical])
        horizontal = bool(self._attributes[DeviceAttributes.swing_horizontal])
        return next(
            name
            for name, pair in MideaACDevice._swing_modes.items()
            if pair == (vertical, horizontal)
        )

    @override
    def set_swing_mode(self, swing_mode: MideaSwingMode) -> None:
        """Midea AC device set swing mode."""
        try:
            mode = ACSwingMode(swing_mode)
        except ValueError:
            mode = None
        if mode is None or self._used_subprotocol:
            msg = f"[ac] Unsupported swing mode: {swing_mode}"
            raise ValueError(msg)
        swing_vertical, swing_horizontal = MideaACDevice._swing_modes[mode]
        self._set_swing(
            swing_vertical=swing_vertical,
            swing_horizontal=swing_horizontal,
        )

    @property
    def temperature_step(self) -> float:
        """Midea AC device temperature step."""
        return self._temperature_step

    @override
    def target_temperature(self, zone: int | None = None) -> float | None:
        """Midea AC device target temperature."""
        return cast(
            "float | None",
            self._attributes.get(DeviceAttributes.target_temperature, None),
        )

    @override
    def current_temperature(self) -> float | None:
        """Midea AC device current temperature."""
        return cast(
            "float | None",
            self._attributes.get(DeviceAttributes.indoor_temperature, None),
        )

    @override
    def current_humidity(self) -> float | None:
        """Midea AC device current humidity."""
        return cast(
            "float | None",
            self._attributes.get(DeviceAttributes.indoor_humidity, None),
        )

    @override
    def turn_on(self, zone: int | None = None) -> None:
        """Midea AC device turn on."""
        self.set_attribute(attr=DeviceAttributes.power, value=True)

    @override
    def turn_off(self, zone: int | None = None) -> None:
        """Midea AC device turn off."""
        self.set_attribute(attr=DeviceAttributes.power, value=False)

    @override
    def min_temperature(self, zone: int | None = None) -> float:
        """Midea AC device minimum target temperature."""
        value = self._attributes[DeviceAttributes.min_temperature]
        if isinstance(value, (int, float)):
            return float(value)
        return DEFAULT_MIN_TARGET_TEMPERATURE

    @override
    def max_temperature(self, zone: int | None = None) -> float:
        """Midea AC device maximum target temperature."""
        value = self._attributes[DeviceAttributes.max_temperature]
        if isinstance(value, (int, float)):
            return float(value)
        return DEFAULT_MAX_TARGET_TEMPERATURE

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
    def breezeless_directions(self) -> list[str]:
        """Selectable breezeless directions (Toshiba IoLife units only)."""
        if not self._is_toshiba:
            return []
        return list(TOSHIBA_BREEZELESS_DIRECTIONS.values())

    def _active_rate_selects(self) -> dict[int, str]:
        """Midea AC device rate_select gear map for the reported gear count.

        The b5_electricity byte sets ``rate_select_2_level``/
        ``rate_select_5_level`` as independent bits; a device can advertise
        both. The 2-gear map only applies when 2-level is advertised and
        5-level is not -- any 5-level support means the device accepts the
        full gear table.
        """
        if self._capabilities.get(
            "rate_select_2_level",
        ) and not self._capabilities.get("rate_select_5_level"):
            return MideaACDevice._rate_selects_2_level
        return MideaACDevice._rate_selects

    @property
    def rate_selects(self) -> list[str]:
        """Midea AC device rate_select options."""
        return list(self._active_rate_selects().values())

    def build_query(self) -> list[ACQuery]:
        """Midea AC device build query."""
        if self._is_toshiba:
            return [MessageQuery(TOSHIBA_PROTOCOL_VERSION, header_type=ListTypes.X55)]
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
            MessageNewProtocolQuery(
                self._message_protocol_version,
                supports_rate_select=self._capabilities.get("rate_select", False),
            ),
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
            MessageGroupThreeQuery(self._message_protocol_version),
            MessageGroupSevenQuery(self._message_protocol_version),
            MessageCapabilitiesQuery(self._message_protocol_version),
            MessageCapabilitiesAdditionalQuery(self._message_protocol_version),
        ]
        return queries

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea AC device process message."""
        message = MessageACResponse(
            bytearray(msg),
            self._power_analysis_method,
            self._uses_new_protocol_temperature,
        )
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        if self._is_toshiba:
            return self._process_toshiba_message(message)
        new_status: dict[str, Any] = {}
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

        def _translate_fresh_air_power(value: bool) -> bool:
            nonlocal has_fresh_air
            has_fresh_air = True
            return value

        def _skip_if_stale_temperature(value: Any) -> Any:  # noqa: ANN401
            return SKIP_ATTRIBUTE if is_stale_c0_temperature else value

        new_status.update(
            self.update_attributes_from_message(
                message,
                {
                    **dict.fromkeys(
                        STALE_C0_TEMPERATURE_ATTRIBUTES,
                        _skip_if_stale_temperature,
                    ),
                    DeviceAttributes.fresh_air_power: _translate_fresh_air_power,
                    DeviceAttributes.wind_lr_angle: MideaACDevice._wind_lr_angles.get,
                    DeviceAttributes.wind_ud_angle: MideaACDevice._wind_ud_angles.get,
                    DeviceAttributes.rate_select: self._active_rate_selects().get,
                },
            ),
        )
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
        new_status.update(self._refresh_self_clean_status(message))
        new_status.update(self._refresh_temperature_limits(message))
        new_status.update(self._update_capabilities(message))
        return new_status

    def _process_toshiba_message(self, message: MessageACResponse) -> dict[str, Any]:
        """Apply a Toshiba IoLife status frame."""
        for attr in (DeviceAttributes.wind_ud_angle, DeviceAttributes.wind_lr_angle):
            if (angle := getattr(message, attr.value, None)) is not None:
                self._toshiba_wind_angles[attr] = angle
        new_status = self.update_attributes_from_message(
            message,
            {
                # .get leaves an unlisted raw value as None -- notably the auto
                # position, which is deliberately not a selectable option.
                DeviceAttributes.wind_lr_angle: MideaACDevice._wind_lr_angles.get,
                DeviceAttributes.wind_ud_angle: MideaACDevice._wind_ud_angles.get,
                DeviceAttributes.breezeless_direction: (
                    TOSHIBA_BREEZELESS_DIRECTIONS.get
                ),
            },
        )
        # In dry mode, report the dehumidify sub-mode as the fan speed. Clothes
        # drying has no fan equivalent, so it shows whatever the unit reports.
        if self._attributes[DeviceAttributes.mode] == DRY_MODE and (
            speed := TOSHIBA_DRY_FAN_SPEEDS.get(
                self._attributes[DeviceAttributes.dehumidify],
            )
        ):
            self._attributes[DeviceAttributes.fan_speed] = int(speed)
            new_status[DeviceAttributes.fan_speed.value] = int(speed)
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
    @override
    def attributes(self) -> dict[str, Any]:
        """Attributes."""
        ret = super().attributes
        for cap in MideaACDevice._capabilities_attr:
            if not self._capabilities.get(cap, False):
                ret.pop(MideaACDevice._capabilities_attr[cap], None)
        return ret

    @property
    def _self_clean_pending_timeout(self) -> int:
        """Return the stale-status window for a pending self-clean command."""
        return (
            self._refresh_interval
            if self._refresh_interval > 0
            else self._default_refresh_interval
        )

    def _update_capabilities(self, message: MessageACResponse) -> dict[str, Any]:
        """Accumulate decoded B5 capability flags from a B5 response.

        Returns a status delta so a capability-only frame (no DeviceAttributes
        changed) still reaches update_all(); callers that derive state from
        `capabilities` would otherwise never be notified of the change.
        """
        if not hasattr(message, "capabilities"):
            return {}
        new_capabilities = message.capabilities
        if all(
            self._capabilities.get(key) == value
            for key, value in new_capabilities.items()
        ):
            return {}
        self._capabilities.update(new_capabilities)

        return {"capabilities": dict(self._capabilities)}

    def _refresh_self_clean_status(self, message: MessageACResponse) -> dict[str, Any]:
        """Apply a reported self-clean status, ignoring stale readings.

        A command that sets self-clean can take a moment to take effect. While
        `_pending_self_clean` is set, a status that still contradicts the
        command is presumed stale (a report queued before the command was
        processed) and is ignored until either a matching status arrives or
        the pending window elapses.
        """
        if not hasattr(message, "self_clean_active"):
            return {}
        active = message.self_clean_active
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
                return {}
        self._attributes[DeviceAttributes.self_clean] = active
        return {DeviceAttributes.self_clean.value: active}

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

        Priority: model exception > B5 capability > None (the consumer then
        falls back to its own default range).
        """
        if message is not None and hasattr(message, "temperature_limits"):
            self._temperature_limits = message.temperature_limits
        b5 = self._b5_temperature_limits()
        exceptions = AC_EXCEPTIONS.get(str(self.model), {})
        minimum = exceptions.get("min_temperature", b5[0] if b5 else None)
        maximum = exceptions.get("max_temperature", b5[1] if b5 else None)
        self._attributes[DeviceAttributes.min_temperature] = minimum
        self._attributes[DeviceAttributes.max_temperature] = maximum
        return {
            DeviceAttributes.min_temperature.value: minimum,
            DeviceAttributes.max_temperature.value: maximum,
        }

    def make_message_set(self) -> MessageGeneralSet:
        """Midea AC device make message set."""
        message = MessageGeneralSet(self._message_protocol_version)
        message.power = self._attributes.get(DeviceAttributes.power, False)
        message.prompt_tone = self._attributes.get(DeviceAttributes.prompt_tone, True)
        message.mode = self._attributes.get(DeviceAttributes.mode, 0)
        message.target_temperature = self._attributes.get(
            DeviceAttributes.target_temperature,
            20.0,
        )
        message.fan_speed = self._attributes.get(DeviceAttributes.fan_speed, 102)
        message.swing_vertical = self._attributes.get(
            DeviceAttributes.swing_vertical,
            False,
        )
        message.swing_horizontal = self._attributes.get(
            DeviceAttributes.swing_horizontal,
            False,
        )
        message.boost_mode = self._attributes.get(DeviceAttributes.boost_mode, False)
        message.power_saving = self._attributes.get(
            DeviceAttributes.power_saving,
            False,
        )
        message.smart_eye = self._attributes.get(DeviceAttributes.smart_eye, False)
        message.dry = self._attributes.get(DeviceAttributes.dry, False)
        message.aux_heating = self._attributes.get(DeviceAttributes.aux_heating, False)
        message.eco_mode = self._attributes.get(DeviceAttributes.eco_mode, False)
        message.temp_fahrenheit = self._attributes.get(
            DeviceAttributes.temp_fahrenheit,
            False,
        )
        message.sleep_mode = self._attributes.get(DeviceAttributes.sleep_mode, False)
        message.natural_wind = self._attributes.get(
            DeviceAttributes.natural_wind,
            False,
        )
        message.frost_protect = self._attributes.get(
            DeviceAttributes.frost_protect,
            False,
        )
        message.comfort_mode = self._attributes.get(
            DeviceAttributes.comfort_mode,
            False,
        )
        message.anion = self._attributes.get(DeviceAttributes.anion, False)
        return message

    def _make_newprotocol_message_set(
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
            message.rate_select = next(
                (
                    gear
                    for gear, name in self._active_rate_selects().items()
                    if name == str(value)
                ),
                None,
            )
        # indirect_wind, screen_display_alternate, breezeless
        else:
            setattr(message, str(attr), value)
        # read current prompt_tone for current set action
        message.prompt_tone = self._attributes[DeviceAttributes.prompt_tone]

        return message

    def _make_subprotocol_message_set(self) -> MessageSubProtocolSet:
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

    def _make_subprotocol_fresh_air_set(
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

    def _make_message_uniq_set(self) -> MessageSubProtocolSet | MessageGeneralSet:
        """Midea AC device make message unique set."""
        message: MessageSubProtocolSet | MessageGeneralSet
        if self._used_subprotocol:
            message = self._make_subprotocol_message_set()
        else:
            message = self.make_message_set()
        return message

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea AC device set attribute."""
        if self._is_toshiba:
            self._set_toshiba_attribute(attr, value)
            return
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
            DeviceAttributes.indoor_ambient_temperature,
            DeviceAttributes.indoor_coil_temperature,
            DeviceAttributes.outdoor_coil_temperature,
            DeviceAttributes.outdoor_ambient_temperature,
            DeviceAttributes.discharge_pipe_temperature,
            DeviceAttributes.indoor_fan_speed,
            DeviceAttributes.target_indoor_fan_speed,
            DeviceAttributes.water_pump_running,
            DeviceAttributes.outdoor_fan_speed,
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
                message = self._make_subprotocol_fresh_air_set(attr, value)
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
                message = self._make_newprotocol_message_set(attr=attr, value=value)
                if attr == DeviceAttributes.self_clean:
                    optimistic_self_clean = bool(value)
            elif attr == DeviceAttributes.power_saving and self._used_subprotocol:
                _LOGGER.debug(
                    "[%s] Power saving is unsupported by the AC subprotocol",
                    self.device_id,
                )
            elif attr in self._attributes:
                message = self._make_message_uniq_set()
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

    @override
    def set_target_temperature(
        self,
        target_temperature: float,
        hvac_mode: MideaHVACMode | None,
        zone: int | None = None,
    ) -> None:
        """Midea AC device set target temperature."""
        if self._is_toshiba:
            params = {
                ToshibaPropertyTags.target_temperature: bytearray(
                    [round(target_temperature * 2)],
                ),
            }
            if hvac_mode == DeviceHVACMode.OFF:
                params[ToshibaPropertyTags.power] = bytearray([0])
            elif hvac_mode is not None:
                params[ToshibaPropertyTags.power] = bytearray([1])
                params[ToshibaPropertyTags.mode] = bytearray([hvac_mode])
            self._send_toshiba(params)
            return
        message: MessageSubProtocolSet | MessageGeneralSet = (
            self._make_message_uniq_set()
        )
        message.target_temperature = (
            round(target_temperature / self.temperature_step) * self.temperature_step
        )
        if hvac_mode is not None:
            message.power = hvac_mode != DeviceHVACMode.OFF
            message.mode = hvac_mode
        self.build_send(message)

    def _set_swing(self, swing_vertical: bool, swing_horizontal: bool) -> None:
        """Midea AC device set swing."""
        if self._is_toshiba:
            self._send_toshiba(
                {
                    ToshibaPropertyTags.swing_vertical: bytearray([swing_vertical]),
                    ToshibaPropertyTags.swing_horizontal: bytearray(
                        [swing_horizontal],
                    ),
                },
            )
            return
        message: MessageSubProtocolSet | MessageGeneralSet = (
            self._make_message_uniq_set()
        )
        if isinstance(message, MessageGeneralSet):
            message.swing_vertical = swing_vertical
            message.swing_horizontal = swing_horizontal
        self.build_send(message)

    def _send_toshiba(self, params: Mapping[ToshibaPropertyTags, bytearray]) -> None:
        """Send Toshiba IoLife property writes, muted unless prompt_tone is on."""
        message = MessageToshibaSet(TOSHIBA_PROTOCOL_VERSION)
        if not self._attributes[DeviceAttributes.prompt_tone]:
            message.set_param(ToshibaPropertyTags.buzzer, bytearray([0]))
        for tag, value in params.items():
            message.set_param(tag, value)
        self.build_send(message)

    def _set_toshiba_attribute(self, attr: str, value: bool | float | str) -> None:
        """Toshiba IoLife set attribute."""
        if attr == DeviceAttributes.prompt_tone:
            # Local-only flag: the protocol has no prompt-tone state to read
            # back, so mirror it to consumers immediately.
            self._attributes[DeviceAttributes.prompt_tone] = bool(value)
            self.update_all({DeviceAttributes.prompt_tone.value: bool(value)})
        elif attr in (DeviceAttributes.wind_ud_angle, DeviceAttributes.wind_lr_angle):
            self._set_toshiba_wind_angle(attr, value)
        elif attr == DeviceAttributes.mode:
            self._set_toshiba_mode(int(value))
        elif (
            attr == DeviceAttributes.fan_speed
            and self._attributes[DeviceAttributes.mode] == DRY_MODE
        ):
            # The fan speed is not settable in dry mode; steer the sub-mode instead.
            self._set_toshiba_attribute(
                DeviceAttributes.dehumidify,
                _toshiba_dry_fan_to_dehumidify(int(value)),
            )
        elif attr in (DeviceAttributes.self_clean, DeviceAttributes.clean_manual):
            self._set_toshiba_clean(attr, bool(value))
        elif (params := _toshiba_params(attr, value)) is not None:
            self._send_toshiba(params)
        elif attr not in TOSHIBA_READ_ONLY_ATTRIBUTES:
            _LOGGER.warning(
                "[%s] set_attribute: unsupported attr %s",
                self.device_id,
                attr,
            )

    def _set_toshiba_wind_angle(self, attr: str, value: bool | float | str) -> None:
        """Write the deflector property, which carries both axes at once."""
        vertical = attr == DeviceAttributes.wind_ud_angle
        angles = (
            MideaACDevice._wind_ud_angles if vertical else MideaACDevice._wind_lr_angles
        )
        angle = _toshiba_wind_angle(angles, value)
        other_attr = (
            DeviceAttributes.wind_lr_angle
            if vertical
            else DeviceAttributes.wind_ud_angle
        )
        # The firmware ignores the whole property when either axis is the 0xFF
        # keep-as-is marker (device-tested), so resend the other axis as it is.
        other = self._toshiba_wind_angles.get(other_attr)
        if angle is None or other is None:
            _LOGGER.warning(
                "[%s] set_attribute: cannot set %s to %s (other axis unknown: %s)",
                self.device_id,
                attr,
                value,
                other is None,
            )
            return
        self._send_toshiba(
            {
                ToshibaPropertyTags.wind_angle: bytearray(
                    [angle, other] if vertical else [other, angle],
                ),
            },
        )
        # Remember the write so a second write before the next status resends
        # this axis at its new position rather than its old one.
        self._toshiba_wind_angles[DeviceAttributes(attr)] = angle

    def _set_toshiba_mode(self, mode: int) -> None:
        """Switch operating mode, powering the unit on as consumers expect.

        Writing the mode on its own leaves a powered-off unit off, so selecting
        an HVAC mode would appear to do nothing; send the power flag with it.
        """
        params = {
            ToshibaPropertyTags.power: bytearray([1]),
            ToshibaPropertyTags.mode: bytearray([mode]),
        }
        if mode == DRY_MODE and self._attributes[DeviceAttributes.mode] != DRY_MODE:
            # Entering dry resumes whichever sub-mode was last used, so start
            # from the recommended one rather than, say, clothes drying. Only on
            # the way in, so a sub-mode chosen while in dry is left alone.
            params[ToshibaPropertyTags.dehumidify] = bytearray(
                [TOSHIBA_DEHUMIDIFY_RECOMMENDED],
            )
        self._send_toshiba(params)

    def _set_toshiba_clean(self, attr: str, value: bool) -> None:
        """Write the clean property, which carries both clean flags at once."""
        flags = {
            DeviceAttributes.clean_manual: bool(
                self._attributes[DeviceAttributes.clean_manual],
            ),
            DeviceAttributes.self_clean: bool(
                self._attributes[DeviceAttributes.self_clean],
            ),
        }
        flags[DeviceAttributes(attr)] = value
        self._send_toshiba(
            {
                ToshibaPropertyTags.clean: bytearray(
                    [
                        flags[DeviceAttributes.clean_manual],
                        flags[DeviceAttributes.self_clean],
                    ],
                ),
            },
        )
        # The unit has no readback for this property, and the status bit only
        # reports a cycle in progress (cleaning). Mirror the write so the switch
        # does not spring back to off.
        self._attributes[attr] = value
        self.update_all({str(attr): value})


class MideaAppliance(MideaACDevice):
    """Midea AC appliance."""
