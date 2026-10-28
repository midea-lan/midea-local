"""Per-model light exceptions."""

from typing import TypedDict


class LightExceptions(TypedDict, total=False):
    """Light defaults overridden for a specific model."""

    color_temp_range_kelvin: list[int]


X13_EXCEPTIONS: dict[str, LightExceptions] = {}
