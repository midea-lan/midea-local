"""Per-model climate exceptions."""

from typing import TypedDict


class ClimateExceptions(TypedDict, total=False):
    """Climate defaults overridden for a specific model."""

    temperature_step: float
    min_temperature: float
    max_temperature: float
    power_analysis_method: int


AC_EXCEPTIONS: dict[str, ClimateExceptions] = {
    "00000Q18": {"temperature_step": 1.0},
}
