"""Per-model humidifier exceptions."""

from typing import TypedDict


class HumidifierExceptions(TypedDict, total=False):
    """Humidifier defaults overridden for a specific model."""

    modes: dict[int, str]
    speeds: dict[int, str]


A1_EXCEPTIONS: dict[str, HumidifierExceptions] = {}
