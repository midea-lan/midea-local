"""Per-model water heater exceptions."""

from typing import Literal, TypedDict


class WaterHeaterExceptions(TypedDict, total=False):
    """Water heater defaults overridden for a specific model."""

    temperature_step: float
    precision_halves: bool
    lua_protocol: Literal["old", "new"]
    old_protocol: bool
    heating_power_multiplier: float


CD_EXCEPTIONS: dict[str, WaterHeaterExceptions] = {}
E2_EXCEPTIONS: dict[str, WaterHeaterExceptions] = {}
E3_EXCEPTIONS: dict[str, WaterHeaterExceptions] = {}
E6_EXCEPTIONS: dict[str, WaterHeaterExceptions] = {}
