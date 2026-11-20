"""Midea local C3 device."""

import logging
from enum import StrEnum
from math import isfinite
from typing import Any, ClassVar, Unpack, cast, override

from midealocal.base_classes.climate import (
    TEMPERATURE_STEP_HALF,
    MideaClimateDevice,
    MideaHVACMode,
)
from midealocal.const import DeviceType
from midealocal.const.climate_exceptions import C3_EXCEPTIONS
from midealocal.device import MideaDeviceInitKwargs

from .message import (
    MODE_TO_WIRE,
    QUINTUPLE_MODEL,
    BasicTag,
    C3DeviceMode,
    C3SilentLevel,
    MessageC3Response,
    MessageQuery,
    MessageQuery2F12,
    MessageQuery2010,
    MessageQueryBasic,
    MessageQueryDisinfect,
    MessageQueryECO,
    MessageQuerySilence,
    MessageQueryTelemetry,
    MessageQueryUnitPara,
    MessageSet,
    MessageSet2010,
    MessageSetDisinfect,
    MessageSetECO,
    MessageSetSilent,
)

_LOGGER = logging.getLogger(__name__)

# Fallback target temperature bounds for a zone whose range is not (yet) reported.
DEFAULT_ZONE_MIN_TARGET_TEMPERATURE = 5.0
DEFAULT_ZONE_MAX_TARGET_TEMPERATURE = 60.0


class DeviceAttributes(StrEnum):
    """Midea C3 device attributes."""

    zone1_power = "zone1_power"
    zone2_power = "zone2_power"
    dhw_power = "dhw_power"
    zone1_curve = "zone1_curve"
    zone2_curve = "zone2_curve"
    disinfect = "disinfect"
    fast_dhw = "fast_dhw"
    zone_temp_type = "zone_temp_type"
    zone1_room_temp_mode = "zone1_room_temp_mode"
    zone2_room_temp_mode = "zone2_room_temp_mode"
    zone1_water_temp_mode = "zone1_water_temp_mode"
    zone2_water_temp_mode = "zone2_water_temp_mode"
    mode = "mode"
    mode_auto = "mode_auto"
    zone_target_temp = "zone_target_temp"
    dhw_target_temp = "dhw_target_temp"
    room_target_temp = "room_target_temp"
    zone_heating_temp_max = "zone_heating_temp_max"
    zone_heating_temp_min = "zone_heating_temp_min"
    zone_cooling_temp_max = "zone_cooling_temp_max"
    zone_cooling_temp_min = "zone_cooling_temp_min"
    tank_actual_temperature = "tank_actual_temperature"
    room_temp_max = "room_temp_max"
    room_temp_min = "room_temp_min"
    dhw_temp_max = "dhw_temp_max"
    dhw_temp_min = "dhw_temp_min"
    target_temperature = "target_temperature"
    temperature_max = "temperature_max"
    temperature_min = "temperature_min"
    status_heating = "status_heating"
    status_dhw = "status_dhw"
    status_tbh = "status_tbh"
    status_ibh = "status_ibh"
    total_energy_consumption = "total_energy_consumption"
    total_produced_energy = "total_produced_energy"
    outdoor_temperature = "outdoor_temperature"
    temp_tw_in = "temp_tw_in"
    temp_tw_out = "temp_tw_out"
    instant_power0 = "instant_power0"
    silent_mode = "silent_mode"
    silent_level = "silent_level"
    eco_mode = "eco_mode"
    tbh = "tbh"
    error_code = "error_code"
    double_zone = "double_zone"
    temp_t1 = "temp_t1"
    temp_tw2 = "temp_tw2"
    temp_ta = "temp_ta"
    current_unit_capacity = "current_unit_capacity"
    instant_renew_power0 = "instant_renew_power0"


class DeviceHVACMode(MideaHVACMode):
    """Midea C3 HVAC Mode."""

    OFF = 0
    AUTO = 1
    COOL = 2
    HEAT = 3


class MideaC3Device(MideaClimateDevice):
    """Midea C3 device."""

    _silent_modes: ClassVar[list[str]] = [
        C3SilentLevel.OFF.name.lower(),
        C3SilentLevel.SILENT.name.lower(),
        C3SilentLevel.SUPER_SILENT.name.lower(),
    ]

    # Generic HVAC mode names, ordered to match the protocol's mode index.
    _device_hvac_modes: ClassVar[set[MideaHVACMode]] = {
        DeviceHVACMode.OFF,
        DeviceHVACMode.AUTO,
        DeviceHVACMode.COOL,
        DeviceHVACMode.HEAT,
    }

    # C3 has two independently powered zones sharing one device connection;
    # mode is shared, but power (and hence hvac_mode) is per-zone.
    _power_attributes: ClassVar[tuple[DeviceAttributes, DeviceAttributes]] = (
        DeviceAttributes.zone1_power,
        DeviceAttributes.zone2_power,
    )

    def __init__(
        self,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea C3 device."""
        super().__init__(
            device_type=DeviceType.C3,
            **kwargs,
            attributes={
                DeviceAttributes.zone1_power: False,
                DeviceAttributes.zone2_power: False,
                DeviceAttributes.dhw_power: False,
                DeviceAttributes.zone1_curve: False,
                DeviceAttributes.zone2_curve: False,
                DeviceAttributes.disinfect: False,
                DeviceAttributes.fast_dhw: False,
                DeviceAttributes.zone_temp_type: [False, False],
                DeviceAttributes.zone1_room_temp_mode: False,
                DeviceAttributes.zone2_room_temp_mode: False,
                DeviceAttributes.zone1_water_temp_mode: False,
                DeviceAttributes.zone2_water_temp_mode: False,
                DeviceAttributes.silent_mode: False,
                DeviceAttributes.silent_level: C3SilentLevel.OFF.name.lower(),
                DeviceAttributes.eco_mode: False,
                DeviceAttributes.tbh: False,
                DeviceAttributes.mode: 1,
                DeviceAttributes.mode_auto: 1,
                DeviceAttributes.zone_target_temp: [25.0, 25.0],
                DeviceAttributes.dhw_target_temp: 25.0,
                DeviceAttributes.room_target_temp: 30.0,
                DeviceAttributes.zone_heating_temp_max: [55.0, 55.0],
                DeviceAttributes.zone_heating_temp_min: [25.0, 25.0],
                DeviceAttributes.zone_cooling_temp_max: [25.0, 25.0],
                DeviceAttributes.zone_cooling_temp_min: [5.0, 5.0],
                DeviceAttributes.room_temp_max: 60.0,
                DeviceAttributes.room_temp_min: 34.0,
                DeviceAttributes.dhw_temp_max: 60.0,
                DeviceAttributes.dhw_temp_min: 20.0,
                DeviceAttributes.tank_actual_temperature: None,
                DeviceAttributes.target_temperature: [25.0, 25.0],
                DeviceAttributes.temperature_max: [0.0, 0.0],
                DeviceAttributes.temperature_min: [0.0, 0.0],
                DeviceAttributes.total_energy_consumption: None,
                DeviceAttributes.status_heating: None,
                DeviceAttributes.status_dhw: None,
                DeviceAttributes.status_tbh: None,
                DeviceAttributes.status_ibh: None,
                DeviceAttributes.total_produced_energy: None,
                DeviceAttributes.outdoor_temperature: None,
                DeviceAttributes.temp_tw_in: None,
                DeviceAttributes.temp_tw_out: None,
                DeviceAttributes.instant_power0: None,
                DeviceAttributes.error_code: 0,
            },
        )
        self._quintuple_protocol = str(self.model) == QUINTUPLE_MODEL
        self._quintuple_ready = False
        if self._quintuple_protocol:
            for attribute in DeviceAttributes:
                self._attributes.setdefault(attribute, None)
            # These use separate native tables, outside this basic-control port.
            for attribute in (
                DeviceAttributes.silent_mode,
                DeviceAttributes.silent_level,
                DeviceAttributes.eco_mode,
                DeviceAttributes.disinfect,
            ):
                self._attributes.pop(attribute, None)
            for attribute in (
                DeviceAttributes.room_target_temp,
                DeviceAttributes.room_temp_min,
                DeviceAttributes.room_temp_max,
                DeviceAttributes.dhw_temp_min,
                DeviceAttributes.dhw_temp_max,
                DeviceAttributes.dhw_target_temp,
                DeviceAttributes.mode,
                DeviceAttributes.mode_auto,
            ):
                self._attributes[attribute] = None
            for attribute in (
                DeviceAttributes.zone_temp_type,
                DeviceAttributes.zone_target_temp,
                DeviceAttributes.zone_heating_temp_min,
                DeviceAttributes.zone_heating_temp_max,
                DeviceAttributes.zone_cooling_temp_min,
                DeviceAttributes.zone_cooling_temp_max,
                DeviceAttributes.target_temperature,
                DeviceAttributes.temperature_min,
                DeviceAttributes.temperature_max,
            ):
                self._attributes[attribute] = [None, None]
        self._temperature_step: float = C3_EXCEPTIONS.get(str(self.model), {}).get(
            "temperature_step",
            TEMPERATURE_STEP_HALF,
        )
        self._settable_attributes.extend(
            [
                DeviceAttributes.zone1_power,
                DeviceAttributes.zone2_power,
                DeviceAttributes.dhw_power,
                DeviceAttributes.zone1_curve,
                DeviceAttributes.zone2_curve,
                DeviceAttributes.tbh,
                DeviceAttributes.fast_dhw,
                DeviceAttributes.dhw_target_temp,
                DeviceAttributes.eco_mode,
                DeviceAttributes.disinfect,
                DeviceAttributes.silent_mode,
                DeviceAttributes.silent_level,
            ]
        )

    @property
    @override
    def hvac_modes(self) -> set[MideaHVACMode]:
        """Midea C3 device HVAC modes."""
        return MideaC3Device._device_hvac_modes

    @override
    def hvac_mode(self, zone: int | None = None) -> MideaHVACMode | None:
        """Midea C3 device HVAC mode."""
        if zone is None:
            raise ValueError("[C3] Parameter `zone` must be set")
        if zone not in range(len(MideaC3Device._power_attributes)):
            raise ValueError(
                "[C3] Parameter `zone` must be between 0 "
                f"and {len(MideaC3Device._power_attributes) - 1}",
            )
        power = self._attributes[MideaC3Device._power_attributes[zone]]
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
        """Midea C3 device set HVAC mode."""
        if zone is None:
            raise ValueError("[C3] Parameter `zone` must be set")
        if zone not in range(len(MideaC3Device._power_attributes)):
            raise ValueError(
                "[C3] Parameter `zone` must be between 0 "
                f"and {len(MideaC3Device._power_attributes) - 1}",
            )
        if hvac_mode == DeviceHVACMode.OFF:
            self.set_attribute(attr=MideaC3Device._power_attributes[zone], value=False)
            return
        if hvac_mode not in self.hvac_modes:
            msg = f"[C3] Unsupported hvac mode: {hvac_mode}"
            raise ValueError(msg)
        self._set_mode(zone, hvac_mode)

    @property
    def temperature_step(self) -> float:
        """Midea C3 device temperature step."""
        return self._temperature_step

    def _require_zone(self, zone: int | None) -> int:
        """Validate and return a zone index (C3 has one range per zone)."""
        if zone is None:
            raise ValueError("[C3] Parameter `zone` must be set")
        if zone not in range(len(MideaC3Device._power_attributes)):
            raise ValueError(
                "[C3] Parameter `zone` must be between 0 "
                f"and {len(MideaC3Device._power_attributes) - 1}",
            )
        return zone

    def _zone_temperature_bound(
        self,
        attr: DeviceAttributes,
        fallback: float,
        zone: int | None,
    ) -> float:
        """Return ``attr``'s value for ``zone``, or ``fallback`` if unusable.

        The device reports one entry per zone; a list shorter than two
        entries, or a zone stuck at ``0.0``, means the range was not reported.
        """
        index = self._require_zone(zone)
        values = self._attributes[attr]
        if not isinstance(values, list) or len(values) < len(
            MideaC3Device._power_attributes,
        ):
            return fallback
        value = values[index]
        return float(value) if value is not None and value != 0.0 else fallback

    @override
    def min_temperature(self, zone: int | None = None) -> float:
        """Midea C3 device minimum target temperature for a zone."""
        return self._zone_temperature_bound(
            DeviceAttributes.temperature_min,
            DEFAULT_ZONE_MIN_TARGET_TEMPERATURE,
            zone,
        )

    @override
    def max_temperature(self, zone: int | None = None) -> float:
        """Midea C3 device maximum target temperature for a zone."""
        return self._zone_temperature_bound(
            DeviceAttributes.temperature_max,
            DEFAULT_ZONE_MAX_TARGET_TEMPERATURE,
            zone,
        )

    @property
    def silent_modes(self) -> list[str]:
        """Midea C3 device silent modes."""
        return MideaC3Device._silent_modes

    def build_query(self) -> list[MessageQuery | MessageQuery2010]:
        """Midea C3 device build query."""
        if self._quintuple_protocol:
            return [
                MessageQuery2010(self._message_protocol_version),
                MessageQuery2F12(self._message_protocol_version),
                MessageQueryTelemetry(self._message_protocol_version),
            ]
        return [
            MessageQueryBasic(self._message_protocol_version),
            MessageQueryDisinfect(self._message_protocol_version),
            MessageQuerySilence(self._message_protocol_version),
            MessageQueryECO(self._message_protocol_version),
            MessageQueryUnitPara(self._message_protocol_version),
        ]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea C3 device process message."""
        message = MessageC3Response(msg, model=str(self.model))
        if self._quintuple_protocol:
            self._merge_quintuple_status(message)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        new_status = self.update_attributes_from_message(message)
        if self._quintuple_protocol:
            if getattr(message, "quintuple_basic", False):
                zones = (
                    (0, 1) if self._attributes[DeviceAttributes.double_zone] else (0,)
                )
                self._quintuple_ready = all(
                    self._valid_quintuple_limits(*self._quintuple_limits(zone))
                    for zone in zones
                )
            if new_status:
                self._refresh_quintuple_targets(new_status)
            return new_status
        if "zone_temp_type" in new_status:
            for zone in [0, 1]:
                if self._attributes[DeviceAttributes.zone_temp_type][
                    zone
                ]:  # Water temp mode
                    self._attributes[DeviceAttributes.target_temperature][zone] = (
                        self._attributes[DeviceAttributes.zone_target_temp][zone]
                    )
                    if (
                        self._attributes[DeviceAttributes.mode_auto]
                        == C3DeviceMode.COOL
                    ):  # cooling mode
                        self._attributes[DeviceAttributes.temperature_max][zone] = (
                            self._attributes[DeviceAttributes.zone_cooling_temp_max][
                                zone
                            ]
                        )
                        self._attributes[DeviceAttributes.temperature_min][zone] = (
                            self._attributes[DeviceAttributes.zone_cooling_temp_min][
                                zone
                            ]
                        )
                    elif (
                        self._attributes[DeviceAttributes.mode] == C3DeviceMode.HEAT
                    ):  # heating mode
                        self._attributes[DeviceAttributes.temperature_max][zone] = (
                            self._attributes[DeviceAttributes.zone_heating_temp_max][
                                zone
                            ]
                        )
                        self._attributes[DeviceAttributes.temperature_min][zone] = (
                            self._attributes[DeviceAttributes.zone_heating_temp_min][
                                zone
                            ]
                        )
                else:  # Room temp mode
                    self._attributes[DeviceAttributes.target_temperature][zone] = (
                        self._attributes[DeviceAttributes.room_target_temp]
                    )
                    self._attributes[DeviceAttributes.temperature_max][zone] = (
                        self._attributes[DeviceAttributes.room_temp_max]
                    )
                    self._attributes[DeviceAttributes.temperature_min][zone] = (
                        self._attributes[DeviceAttributes.room_temp_min]
                    )
            if self._attributes[DeviceAttributes.zone1_power]:
                if self._attributes[DeviceAttributes.zone_temp_type][0]:
                    self._attributes[DeviceAttributes.zone1_water_temp_mode] = True
                    self._attributes[DeviceAttributes.zone1_room_temp_mode] = False
                else:
                    self._attributes[DeviceAttributes.zone1_water_temp_mode] = False
                    self._attributes[DeviceAttributes.zone1_room_temp_mode] = True
            else:
                self._attributes[DeviceAttributes.zone1_water_temp_mode] = False
                self._attributes[DeviceAttributes.zone1_room_temp_mode] = False
            if self._attributes[DeviceAttributes.zone2_power]:
                if self._attributes[DeviceAttributes.zone_temp_type][1]:
                    self._attributes[DeviceAttributes.zone2_water_temp_mode] = True
                    self._attributes[DeviceAttributes.zone2_room_temp_mode] = False
                else:
                    self._attributes[DeviceAttributes.zone2_water_temp_mode] = False
                    self._attributes[DeviceAttributes.zone2_room_temp_mode] = True
            else:
                self._attributes[DeviceAttributes.zone2_water_temp_mode] = False
                self._attributes[DeviceAttributes.zone2_room_temp_mode] = False
            new_status[DeviceAttributes.zone1_water_temp_mode.value] = self._attributes[
                DeviceAttributes.zone1_water_temp_mode
            ]
            new_status[DeviceAttributes.zone2_water_temp_mode.value] = self._attributes[
                DeviceAttributes.zone2_water_temp_mode
            ]
            new_status[DeviceAttributes.zone1_room_temp_mode.value] = self._attributes[
                DeviceAttributes.zone1_room_temp_mode
            ]
            new_status[DeviceAttributes.zone2_room_temp_mode.value] = self._attributes[
                DeviceAttributes.zone2_room_temp_mode
            ]

        return new_status

    def _merge_quintuple_status(self, message: MessageC3Response) -> None:
        """Retain untouched array members when the controller acknowledges one TLV."""
        arrays = getattr(message, "quintuple_arrays", {})
        for name, changes in arrays.items():
            merged = list(self._attributes[DeviceAttributes(name)])
            for index, value in changes.items():
                merged[index] = value
            setattr(message, name, merged)

    @staticmethod
    def _valid_quintuple_limits(lower: float | None, upper: float | None) -> bool:
        """Only finite, ordered controller limits may authorize a temperature write."""
        return (
            lower is not None
            and upper is not None
            and isfinite(lower)
            and isfinite(upper)
            and lower <= upper
        )

    def _quintuple_limits(
        self,
        zone: int,
        mode: int | None = None,
    ) -> tuple[float | None, float | None]:
        """Select reported limits for the zone and requested operating mode."""
        attributes = self._attributes
        water = attributes[DeviceAttributes.zone_temp_type][zone]
        if mode is None or mode == 0:
            mode = attributes[DeviceAttributes.mode]
        actual_mode = attributes[DeviceAttributes.mode_auto] if mode == 1 else mode
        if water is None or actual_mode not in (0, 2, 3):
            return None, None
        if not water:
            return (
                attributes[DeviceAttributes.room_temp_min],
                attributes[DeviceAttributes.room_temp_max],
            )
        cooling = actual_mode == C3DeviceMode.COOL
        return (
            attributes[
                DeviceAttributes.zone_cooling_temp_min
                if cooling
                else DeviceAttributes.zone_heating_temp_min
            ][zone],
            attributes[
                DeviceAttributes.zone_cooling_temp_max
                if cooling
                else DeviceAttributes.zone_heating_temp_max
            ][zone],
        )

    def _refresh_quintuple_targets(self, status: dict[str, Any]) -> None:
        """Recompute HA targets after both full replies and sparse acknowledgements."""
        attributes = self._attributes
        for zone in (0, 1):
            water = attributes[DeviceAttributes.zone_temp_type][zone]
            target = (
                None
                if water is None
                else attributes[DeviceAttributes.zone_target_temp][zone]
                if water
                else attributes[DeviceAttributes.room_target_temp]
            )
            lower, upper = self._quintuple_limits(zone)
            for attr, value in (
                (DeviceAttributes.target_temperature, target),
                (DeviceAttributes.temperature_min, lower),
                (DeviceAttributes.temperature_max, upper),
            ):
                attributes[attr][zone] = value
                status[attr.value] = attributes[attr]
            power_attr = (
                DeviceAttributes.zone1_power
                if zone == 0
                else DeviceAttributes.zone2_power
            )
            water_attr = (
                DeviceAttributes.zone1_water_temp_mode
                if zone == 0
                else DeviceAttributes.zone2_water_temp_mode
            )
            room_attr = (
                DeviceAttributes.zone1_room_temp_mode
                if zone == 0
                else DeviceAttributes.zone2_room_temp_mode
            )
            for attr, value in (
                (water_attr, bool(attributes[power_attr] and water)),
                (room_attr, bool(attributes[power_attr] and not water)),
            ):
                attributes[attr] = value
                status[attr.value] = value

    def _send_quintuple(self, values: dict[BasicTag, bool | float | int]) -> None:
        """Send a sparse control only after receiving this controller's status."""
        # Readiness also requires valid controller-reported limits for every
        # configured zone. Never authorize a write from constructor defaults.
        if not self._quintuple_ready:
            raise ValueError(
                "Wait for first 0x2010 status before controlling this heat pump",
            )
        self.build_send(MessageSet2010(values, self._message_protocol_version))

    def _set_quintuple_attribute(self, attr: str, value: bool | float | str) -> None:
        """Route native controls without falling back to legacy packets."""
        tags: dict[str, BasicTag] = {
            DeviceAttributes.zone1_power: BasicTag.ZONE1_POWER,
            DeviceAttributes.zone2_power: BasicTag.ZONE2_POWER,
            DeviceAttributes.dhw_power: BasicTag.DHW_POWER,
            DeviceAttributes.zone1_curve: BasicTag.ZONE1_CURVE,
            DeviceAttributes.zone2_curve: BasicTag.ZONE2_CURVE,
            DeviceAttributes.tbh: BasicTag.TANK_BOOSTER,
            DeviceAttributes.fast_dhw: BasicTag.FAST_DHW,
            DeviceAttributes.dhw_target_temp: BasicTag.DHW_TEMPERATURE,
        }
        if attr not in tags:
            raise ValueError(
                f"Control {attr} is not implemented for C3 model {QUINTUPLE_MODEL}",
            )
        if attr in (DeviceAttributes.zone2_power, DeviceAttributes.zone2_curve):
            self._check_quintuple_zone(1)
        if attr == DeviceAttributes.dhw_target_temp:
            temperature = float(value)
            lower = self._attributes[DeviceAttributes.dhw_temp_min]
            upper = self._attributes[DeviceAttributes.dhw_temp_max]
            if not self._valid_quintuple_limits(lower, upper) or not (
                lower <= temperature <= upper
            ):
                raise ValueError(
                    "DHW temperature is outside the controller's reported limits",
                )
            self._send_quintuple({tags[attr]: temperature})
        else:
            if not isinstance(value, bool):
                raise ValueError("Power and curve controls require a boolean")
            self._send_quintuple({tags[attr]: value})

    def _check_quintuple_zone(self, zone: int) -> None:
        """Reject nonexistent zones rather than writing to unsupported hardware."""
        if zone not in (0, 1):
            raise ValueError("Invalid C3 zone")
        if zone == 1 and not self._attributes[DeviceAttributes.double_zone]:
            raise ValueError("Zone 2 is not enabled on this controller")

    def make_message_set(self) -> MessageSet:
        """Midea C3 device make message set."""
        message = MessageSet(self._message_protocol_version)
        message.zone1_power = self._attributes[DeviceAttributes.zone1_power]
        message.zone2_power = self._attributes[DeviceAttributes.zone2_power]
        message.dhw_power = self._attributes[DeviceAttributes.dhw_power]
        message.mode = self._attributes[DeviceAttributes.mode]
        message.zone_target_temp = self._attributes[DeviceAttributes.zone_target_temp]
        message.dhw_target_temp = self._attributes[DeviceAttributes.dhw_target_temp]
        message.room_target_temp = self._attributes[DeviceAttributes.room_target_temp]
        message.zone1_curve = self._attributes[DeviceAttributes.zone1_curve]
        message.zone2_curve = self._attributes[DeviceAttributes.zone2_curve]
        message.tbh = self._attributes[DeviceAttributes.tbh]
        message.fast_dhw = self._attributes[DeviceAttributes.fast_dhw]
        return message

    @override
    def _set_attribute(self, attr: str, value: bool | float | str) -> bool:
        """Midea C3 device set attribute."""
        if self._quintuple_protocol:
            self._set_quintuple_attribute(attr, value)
            return
        message: (
            MessageSet | MessageSetECO | MessageSetSilent | MessageSetDisinfect | None
        ) = None
        if attr in [
            DeviceAttributes.zone1_power,
            DeviceAttributes.zone2_power,
            DeviceAttributes.dhw_power,
            DeviceAttributes.zone1_curve,
            DeviceAttributes.zone2_curve,
            DeviceAttributes.tbh,
            DeviceAttributes.fast_dhw,
            DeviceAttributes.dhw_target_temp,
        ]:
            message = self.make_message_set()
            setattr(message, str(attr), value)
        elif attr == DeviceAttributes.eco_mode:
            message = MessageSetECO(self._message_protocol_version)
            setattr(message, str(attr), value)
        elif attr == DeviceAttributes.disinfect:
            message = MessageSetDisinfect(self._message_protocol_version)
            setattr(message, str(attr), value)
        elif attr == DeviceAttributes.silent_mode.value and isinstance(value, bool):
            message = MessageSetSilent(self._message_protocol_version)
            message.silent_mode = value
            message.silent_level = (
                C3SilentLevel.SILENT
                if value
                and self._attributes[DeviceAttributes.silent_level]
                == C3SilentLevel.OFF.name.lower()
                else C3SilentLevel[
                    self._attributes[DeviceAttributes.silent_level].upper()
                ]
            )
        elif attr == DeviceAttributes.silent_level.value and isinstance(value, str):
            message = MessageSetSilent(self._message_protocol_version)
            normalized_value = value.upper()
            message.silent_level = C3SilentLevel[normalized_value]
            message.silent_mode = normalized_value != C3SilentLevel.OFF.name
        if message is not None:
            self.build_send(message)
            return True
        return False

    def _set_mode(self, zone: int, mode: int) -> None:
        """Midea C3 device set mode."""
        if self._quintuple_protocol:
            self._check_quintuple_zone(zone)
            if mode not in MODE_TO_WIRE:
                raise ValueError("Invalid C3 operating mode")
            power = BasicTag.ZONE1_POWER if zone == 0 else BasicTag.ZONE2_POWER
            values: dict[BasicTag, bool | float | int] = {power: mode != 0}
            if mode:
                values[BasicTag.MODE] = MODE_TO_WIRE[mode]
            self._send_quintuple(values)
            return
        message = self.make_message_set()
        if zone == 0:
            message.zone1_power = True
        else:
            message.zone2_power = True
        message.mode = mode
        self.build_send(message)

    @override
    def set_target_temperature(
        self,
        target_temperature: float,
        hvac_mode: MideaHVACMode | None,
        zone: int | None = None,
    ) -> None:
        """Midea C3 device set target temperature."""
        if zone is None:
            raise ValueError("[C3] Parameter `zone` must be set")
        if zone not in range(len(MideaC3Device._power_attributes)):
            raise ValueError(
                "[C3] Parameter `zone` must be between 0 "
                f"and {len(MideaC3Device._power_attributes) - 1}",
            )

        if self._quintuple_protocol:
            self._check_quintuple_zone(zone)
            if not self._quintuple_ready:
                raise ValueError(
                    "Wait for first 0x2010 status before controlling this heat pump",
                )
            if hvac_mode is not None and hvac_mode not in MODE_TO_WIRE:
                raise ValueError("Invalid C3 operating mode")
            lower, upper = self._quintuple_limits(zone, hvac_mode)
            if (
                lower is None
                or upper is None
                or not self._valid_quintuple_limits(lower, upper)
                or not lower <= target_temperature <= upper
            ):
                raise ValueError(
                    "Temperature is outside the controller's reported limits",
                )
            tag = (
                BasicTag.ZONE1_TEMPERATURE if zone == 0 else BasicTag.ZONE2_TEMPERATURE
            )
            values: dict[BasicTag, bool | float | int] = {tag: target_temperature}
            if not self._attributes[DeviceAttributes.zone_temp_type][zone]:
                values[BasicTag.ROOM_TEMPERATURE] = target_temperature
            if hvac_mode is not None:
                power = BasicTag.ZONE1_POWER if zone == 0 else BasicTag.ZONE2_POWER
                values[power] = hvac_mode != 0
                if hvac_mode:
                    values[BasicTag.MODE] = MODE_TO_WIRE[hvac_mode]
            self._send_quintuple(values)
            return

        message = self.make_message_set()
        round_temp = (
            round(target_temperature / self.temperature_step) * self.temperature_step
        )
        if self._attributes[DeviceAttributes.zone_temp_type][zone]:
            message.zone_target_temp[zone] = round_temp
        else:
            message.room_target_temp = round_temp
        if hvac_mode is not None:
            if zone == 0:
                message.zone1_power = hvac_mode != 0
            else:
                message.zone2_power = hvac_mode != 0
            message.mode = hvac_mode
        self.build_send(message)

    @override
    def target_temperature(self, zone: int | None = None) -> float | None:
        """Midea C3 device target temperature."""
        target_temperature: list[float] | None = self._attributes.get(
            DeviceAttributes.target_temperature,
            None,
        )
        if (
            not isinstance(target_temperature, list)
            or zone is None
            or zone not in range(len(target_temperature))
        ):
            return None
        return (
            None
            if target_temperature[zone] is None
            else float(target_temperature[zone])
        )

    @override
    def current_humidity(self) -> float | None:
        """Midea C3 device current humidity."""
        return None

    @override
    def current_temperature(self) -> float | None:
        """Midea C3 device current temperature."""
        return cast("float | None", self._attributes[DeviceAttributes.temp_tw_out])

    @override
    def turn_on(self, zone: int | None = None) -> None:
        """Midea C3 device turn on."""
        if zone is None:
            raise ValueError("[C3] Parameter `zone` must be set")
        if zone not in range(len(MideaC3Device._power_attributes)):
            raise ValueError(
                "[C3] Parameter `zone` must be between 0 "
                f"and {len(MideaC3Device._power_attributes) - 1}",
            )
        self.set_attribute(
            attr=MideaC3Device._power_attributes[zone],
            value=True,
        )

    @override
    def turn_off(self, zone: int | None = None) -> None:
        """Midea C3 device turn off."""
        if zone is None:
            raise ValueError("[C3] Parameter `zone` must be set")
        if zone not in range(len(MideaC3Device._power_attributes)):
            raise ValueError(
                "[C3] Parameter `zone` must be between 0 "
                f"and {len(MideaC3Device._power_attributes) - 1}",
            )
        self.set_attribute(
            attr=MideaC3Device._power_attributes[zone],
            value=False,
        )


class MideaAppliance(MideaC3Device):
    """Midea C3 appliance."""
