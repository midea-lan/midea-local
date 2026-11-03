"""Per-model air purifier exceptions."""

from typing import TypedDict


class AirPurifierExceptions(TypedDict, total=False):
    """Air purifier defaults overridden for a specific model."""

    standby_detect: list[int]


FC_EXCEPTIONS: dict[str, AirPurifierExceptions] = {}
