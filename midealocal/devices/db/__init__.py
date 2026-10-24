"""Midea local DB device."""

import logging
from collections.abc import Mapping
from dataclasses import dataclass, field
from enum import StrEnum
from types import MappingProxyType
from typing import Any, ClassVar, Unpack

from midealocal.const import DeviceType
from midealocal.device import MideaDevice, MideaDeviceInitKwargs, dict_translator
from midealocal.exceptions import ValueWrongType

from .message import (
    CONTROL_DEHYDRATION_SPEED_OFFSET,
    CONTROL_DEHYDRATION_TIME_OFFSET,
    CONTROL_DETERGENT_OFFSET,
    CONTROL_DRYER_OFFSET,
    CONTROL_OPTIONS_OFFSET,
    CONTROL_PROGRAM_OFFSET,
    CONTROL_TEMPERATURE_OFFSET,
    CONTROL_WASH_TIME_OFFSET,
    CONTROL_WATER_LEVEL_OFFSET,
    DRYER_UNCHANGED_SOAK_COUNT,
    FAST_CLEAN_WASH_BIT,
    STEAM_WASH_BIT,
    MessageDBResponse,
    MessagePower,
    MessageQuery,
    MessageSet,
    MessageStart,
)

_LOGGER = logging.getLogger(__name__)


WASHING_DATA_SIZE = 13
WASHING_DATA_FILL = 0xFF
PARAMETER_BYTE_MAX = WASHING_DATA_FILL - 1
DOSAGE_LEVEL_MAX = 5
MIXED_WASH_TIME_LEVEL_MAX = 4


class DeviceAttributes(StrEnum):
    """Midea DB device attributes."""

    power = "power"
    start = "start"
    status = "status"
    mode = "mode"
    program = "program"
    water_level = "water_level"
    temperature = "temperature"
    dehydration_speed = "dehydration_speed"
    wash_time = "wash_time"
    wash_time_value = "wash_time_value"
    dehydration_time = "dehydration_time"
    dehydration_time_value = "dehydration_time_value"
    detergent = "detergent"
    softener = "softener"
    progress = "progress"
    time_remaining = "time_remaining"
    stains = "stains"
    dirty_degree = "dirty_degree"
    dryer = "dryer"
    steam_wash = "steam_wash"
    fast_clean_wash = "fast_clean_wash"


@dataclass(frozen=True)
class DBParameterSpec:
    """Encoding and validation for one byte in a parameter control payload."""

    offset: int
    mapping: Mapping[int, str] | None = None
    maximum: int = PARAMETER_BYTE_MAX
    bit: int | None = None
    unchanged_bits: int = 0
    maximum_by_program: Mapping[str, int] = field(
        default_factory=lambda: MappingProxyType({}),
    )

    def encode(self, value: bool | float | str, program: str = "") -> int:
        """Reject invalid types, unknown enum values and unchanged sentinels."""
        if self.bit is not None:
            if not isinstance(value, bool):
                raise ValueWrongType("[db] Expected bool")
            return int(value) << self.bit
        if self.mapping is not None:
            if not isinstance(value, str):
                raise ValueWrongType("[db] Expected str")
            encoded = next(
                (code for code, name in self.mapping.items() if name == value),
                None,
            )
            if encoded is None or encoded == WASHING_DATA_FILL:
                raise ValueWrongType(f"[db] Unsupported parameter value: {value}")
            return encoded
        if isinstance(value, bool) or not isinstance(value, int):
            raise ValueWrongType("[db] Expected int")
        maximum = self.maximum_by_program.get(program, self.maximum)
        if not 0 <= value <= maximum:
            raise ValueWrongType(f"[db] Expected value between 0 and {maximum}")
        return value


@dataclass(frozen=True)
class DBModelProfile:
    """Protocol program codes and writable parameter rules for a DB variant."""

    programs: Mapping[int, str]
    parameters: Mapping[DeviceAttributes, DBParameterSpec] = field(
        default_factory=lambda: MappingProxyType({}),
    )

    @property
    def writable_attributes(self) -> frozenset[DeviceAttributes]:
        """Derive writable attributes from the configured parameter rules."""
        return frozenset(self.parameters)


class MideaDBDevice(MideaDevice):
    """Midea DB device."""

    _status: ClassVar[dict[int, str]] = {
        0: "idle",
        1: "standby",
        2: "start",
        3: "pause",
        4: "end",
        5: "fault",
        6: "delay",
    }

    _mode: ClassVar[dict[int, str]] = {
        0: "normal",
        1: "factory_test",
        2: "service",
        3: "normal_continus",
    }

    _dehydration_speed: ClassVar[dict[int, str]] = {
        0x00: "0",
        0x01: "400",
        0x02: "600",
        0x03: "800",
        0x04: "1000",
        0x05: "1200",
        0x06: "1400",
        0x07: "1600",
        0x08: "1300",
        0xFF: "default",
    }

    _water_level: ClassVar[dict[int, str]] = {
        0x01: "low",
        0x02: "mid",
        0x03: "high",
        0x04: "4",
        0x05: "auto",
        0xFF: "default",
    }

    _program: ClassVar[dict[int, str]] = {
        0x00: "cotton",
        0x01: "eco",
        0x02: "fast_wash",
        0x03: "mixed_wash",
        0x04: "fiber",
        0x05: "wool",
        0x06: "enzyme",
        0x07: "ssp",
        0x08: "sport_clothes",
        0x09: "single_dehytration",
        0x0A: "rinsing_dehydration",
        0x0B: "big",
        0x0C: "baby_clothes",
        0x0D: "outdoor",
        0x0E: "air_wash",
        0x0F: "down_jacket",
        0x10: "color",
        0x11: "intelligent",
        0x12: "quick_wash",
        0x13: "kids",
        0x14: "water_cotton",
        0x15: "single_drying",
        0x16: "single_drying",
        0x17: "fast_wash_30",
        0x18: "fast_wash_60",
        0x19: "water_intelligent",
        0x1A: "water_steep",
        0x1B: "water_fast_wash_30",
        0x1C: "shirt",
        0x1D: "steep",
        0x1E: "new_water_cotton",
        0x1F: "water_mixed_wash",
        0x20: "water_fiber",
        0x21: "water_kids",
        0x22: "water_underwear",
        0x23: "specialist",
        0x24: "water_eco",
        0x25: "wash_drying_60",
        0x26: "self_wash_5",
        0x27: "fast_wash_min",
        0x28: "mixed_wash_min",
        0x29: "dehydration_min",
        0x2A: "self_wash_min",
        0x2B: "baby_clothes_min",
        0x2C: "prevent_allergy",
        0x2D: "cold_wash",
        0x2E: "soft_wash",
        0x2F: "remove_mite_wash",
        0x30: "water_intense_wash",
        0x31: "fast_dry",
        0x32: "water_outdoor",
        0x33: "spring_autumn_wash",
        0x34: "summer_wash",
        0x35: "winter_wash",
        0x36: "jean",
        0x37: "new_clothes_wash",
        0x38: "silk",
        0x39: "insight_wash",
        0x3A: "fitness_clothes",
        0x3B: "mink",
        0x3C: "fresh_air",
        0x3D: "bucket_dry",
        0x3E: "jacket",
        0x3F: "bath_towel",
        0x40: "night_fresh_wash",
        0x50: "water_fiber",
        0x51: "diy0",
        0x52: "diy2",
        0x60: "heart_wash",
        0x61: "water_cold_wash",
        0x62: "water_prevent_allergy",
        0x63: "water_remove_mite_wash",
        0x64: "water_ssp",
        0x65: "silk_wash",
        0x66: "standard",
        0x67: "green_wool",
        0x68: "cook_wash",
        0x69: "fresh_remove_wrinkle",
        0x6A: "steam_sterilize_wash",
        0x6B: "aromatherapy",
        0x6C: "eco_40_60",
        0x6D: "steam_care",
        0x6E: "allergy_care",
        0x70: "sterilize_wash",
        0x80: "wash_and_dry",
        0x82: "time_dry",
        0x73: "bulky",
        0xFE: "love",
        0xFF: "default",
    }

    # Lua downloaded for model 38131408 / subtype 13146 matches
    # lua/db/T_0000_DB_33.lua. Preserve the legacy table for other models.
    _program_38131408: ClassVar[dict[int, str]] = {
        **_program,
        0x0D: "underwear",
        0x0E: "outdoor",
        0x15: "air_wash",
        0x50: "diy0",
        0x51: "diy1",
    }

    _temperature: ClassVar[dict[int, str]] = {
        0x01: "0",
        0x02: "20",
        0x03: "30",
        0x04: "40",
        0x05: "60",
        0x06: "95",
        0x07: "70",
        0xFF: "default",
    }

    _default_profile: ClassVar[DBModelProfile] = DBModelProfile(
        programs=MappingProxyType(_program),
    )
    # Panel selections captured on 38131408 / 13146 (2026-10-29).
    # Code 11 is 180 minutes; codes 2 and 8-10 are not exposed on this model.
    _dryer_38131408: ClassVar[Mapping[int, str]] = MappingProxyType(
        {
            0: "off",
            1: "auto",
            3: "low_temperature",
            4: "30",
            5: "60",
            6: "90",
            7: "120",
            11: "180",
        }
    )
    # DB_33 jsonToData supports partial updates. Time fields are level codes;
    # actual minutes depend on the program/options and come from *_time_value.
    # Mixed-wash levels 0-4 were captured on this model; other programs retain
    # the protocol byte range until their bounds are known.
    # Model 38131408 has no automatic softener dispenser (owner confirmed).
    _profile_38131408: ClassVar[DBModelProfile] = DBModelProfile(
        programs=MappingProxyType(_program_38131408),
        parameters=MappingProxyType(
            {
                DeviceAttributes.program: DBParameterSpec(
                    CONTROL_PROGRAM_OFFSET,
                    MappingProxyType(_program_38131408),
                ),
                DeviceAttributes.temperature: DBParameterSpec(
                    CONTROL_TEMPERATURE_OFFSET,
                    MappingProxyType(_temperature),
                ),
                DeviceAttributes.water_level: DBParameterSpec(
                    CONTROL_WATER_LEVEL_OFFSET,
                    MappingProxyType(_water_level),
                ),
                DeviceAttributes.dehydration_speed: DBParameterSpec(
                    CONTROL_DEHYDRATION_SPEED_OFFSET,
                    MappingProxyType(_dehydration_speed),
                ),
                DeviceAttributes.wash_time: DBParameterSpec(
                    CONTROL_WASH_TIME_OFFSET,
                    maximum_by_program=MappingProxyType(
                        {"mixed_wash": MIXED_WASH_TIME_LEVEL_MAX}
                    ),
                ),
                DeviceAttributes.dehydration_time: DBParameterSpec(
                    CONTROL_DEHYDRATION_TIME_OFFSET,
                    maximum_by_program=MappingProxyType(
                        {"mixed_wash": MIXED_WASH_TIME_LEVEL_MAX}
                    ),
                ),
                DeviceAttributes.detergent: DBParameterSpec(
                    CONTROL_DETERGENT_OFFSET,
                    maximum=DOSAGE_LEVEL_MAX,
                ),
                DeviceAttributes.dryer: DBParameterSpec(
                    CONTROL_DRYER_OFFSET,
                    _dryer_38131408,
                    unchanged_bits=DRYER_UNCHANGED_SOAK_COUNT,
                ),
                DeviceAttributes.steam_wash: DBParameterSpec(
                    CONTROL_OPTIONS_OFFSET,
                    bit=STEAM_WASH_BIT,
                ),
                DeviceAttributes.fast_clean_wash: DBParameterSpec(
                    CONTROL_OPTIONS_OFFSET,
                    bit=FAST_CLEAN_WASH_BIT,
                ),
            },
        ),
    )
    _model_profiles: ClassVar[dict[tuple[str, int], DBModelProfile]] = {
        ("38131408", 13146): _profile_38131408,
        # CLI LAN discovery has the model but passes subtype=0.
        ("38131408", 0): _profile_38131408,
    }

    _progress: ClassVar[list[str]] = [
        "idle",
        "spin",
        "rinse",
        "wash",
        "pre_wash",
        "dry",
        "weight",
        "hi_speed_spin",
        "unknown",
    ]

    @classmethod
    def mode_options(cls) -> list[str]:
        """Return the distinct modes this device can report, in order."""
        return list(cls._mode.values())

    def __init__(
        self,
        *,
        customize: str,  # noqa: ARG002
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        """Initialize Midea DB device."""
        super().__init__(
            device_type=DeviceType.DB,
            **kwargs,
            attributes={
                DeviceAttributes.power: False,
                DeviceAttributes.start: False,
                DeviceAttributes.status: "idle",
                DeviceAttributes.mode: "normal",
                DeviceAttributes.program: "default",
                DeviceAttributes.water_level: "default",
                DeviceAttributes.temperature: "default",
                DeviceAttributes.dehydration_speed: "default",
                DeviceAttributes.wash_time: None,
                DeviceAttributes.dehydration_time: None,
                DeviceAttributes.detergent: None,
                DeviceAttributes.softener: None,
                DeviceAttributes.progress: "unknown",
                DeviceAttributes.stains: None,
                DeviceAttributes.time_remaining: None,
                DeviceAttributes.wash_time_value: None,
                DeviceAttributes.dehydration_time_value: None,
                DeviceAttributes.dirty_degree: None,
            },
        )

        self._model_profile = self._model_profiles.get(
            (self.model, self.subtype),
            self._default_profile,
        )
        self._attributes.update(
            dict.fromkeys(
                self._model_profile.parameters.keys() - self._attributes.keys(),
            )
        )
        self._control_options: int | None = None

    def build_query(self) -> list[MessageQuery]:
        """Midea DB device build query."""
        return [MessageQuery(self._message_protocol_version)]

    def process_message(self, msg: bytes) -> dict[str, Any]:
        """Midea DB device process message."""
        message = MessageDBResponse(msg)
        self._control_options = getattr(message, "control_options", None)
        _LOGGER.debug("[%s] Received: %s", self.device_id, message)
        return self.update_attributes_from_message(
            message,
            {
                DeviceAttributes.mode: dict_translator(MideaDBDevice._mode),
                DeviceAttributes.status: dict_translator(MideaDBDevice._status),
                DeviceAttributes.dehydration_speed: dict_translator(
                    MideaDBDevice._dehydration_speed,
                ),
                DeviceAttributes.water_level: dict_translator(
                    MideaDBDevice._water_level,
                ),
                DeviceAttributes.program: dict_translator(self._model_profile.programs),
                DeviceAttributes.temperature: dict_translator(
                    MideaDBDevice._temperature,
                ),
                DeviceAttributes.progress: MideaDBDevice._progress.__getitem__,
                **{
                    attr: dict_translator(spec.mapping)
                    for attr, spec in self._model_profile.parameters.items()
                    if spec.mapping is not None
                },
            },
        )

    def set_attribute(self, attr: str, value: bool | float | str) -> None:
        """Midea DB device set attribute."""
        if attr in self._model_profile.parameters:
            spec = self._model_profile.parameters[DeviceAttributes(attr)]
            encoded = spec.encode(
                value, str(self.get_attribute(DeviceAttributes.program))
            )
            if spec.bit is not None:
                if self._control_options is None:
                    raise ValueWrongType(
                        "[db] Read current options before changing a switch"
                    )
                encoded |= self._control_options & ~(1 << spec.bit)
            parameters = MessageSet(
                self._message_protocol_version,
                {spec.offset: encoded | spec.unchanged_bits},
            )
            # Any parameter change may alter dependent options. Await a new
            # response before attempting another shared-byte update.
            self._control_options = None
            self.build_send(parameters)
            return
        if not isinstance(value, bool):
            raise ValueWrongType("[db] Expected bool")
        message: MessagePower | MessageStart | None = None
        if attr == DeviceAttributes.power:
            message = MessagePower(self._message_protocol_version)
            message.power = value
            self._control_options = None
            self.build_send(message)
        elif attr == DeviceAttributes.start:
            message = MessageStart(self._message_protocol_version)
            message.start = value
            message.washing_data = self._build_washing_data()
            self._control_options = None
            self.build_send(message)

    def _get_key_from_value(
        self,
        value: str,
        mapping: Mapping[int, str],
        default: int = WASHING_DATA_FILL,
    ) -> int:
        """Get the key from the value in the mapping."""
        for key, val in mapping.items():
            if val == value:
                return key
        return default

    def _build_washing_data(self) -> bytearray:
        """Build washing data."""
        washing_data = bytearray(
            [WASHING_DATA_FILL] * WASHING_DATA_SIZE,
        )

        washing_data[0] = self._get_key_from_value(
            str(self.get_attribute(DeviceAttributes.mode)),
            self._mode,
        )

        washing_data[1] = self._get_key_from_value(
            str(self.get_attribute(DeviceAttributes.program)),
            self._model_profile.programs,
        )

        washing_data[2] = self._get_key_from_value(
            str(self.get_attribute(DeviceAttributes.water_level)),
            self._water_level,
        )

        washing_data[4] = self._get_key_from_value(
            str(self.get_attribute(DeviceAttributes.temperature)),
            self._temperature,
        )

        washing_data[5] = self._get_key_from_value(
            str(self.get_attribute(DeviceAttributes.dehydration_speed)),
            self._dehydration_speed,
        )

        if isinstance(wash_time := self.get_attribute(DeviceAttributes.wash_time), int):
            washing_data[6] = wash_time

        if isinstance(
            dehydration_time := self.get_attribute(DeviceAttributes.dehydration_time),
            int,
        ):
            washing_data[7] = dehydration_time

        if isinstance(detergent := self.get_attribute(DeviceAttributes.detergent), int):
            washing_data[8] = detergent

        if isinstance(softener := self.get_attribute(DeviceAttributes.softener), int):
            washing_data[9] = softener

        return washing_data


class MideaAppliance(MideaDBDevice):
    """Midea DB appliance."""
