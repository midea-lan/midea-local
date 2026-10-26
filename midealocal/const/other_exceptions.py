"""Per-model exceptions for devices not tied to a single platform."""

from typing import TypedDict


class OtherExceptions(TypedDict, total=False):
    """Defaults overridden for a specific model."""

    max_dry_level: int
    max_water_temp_level: int
    max_seat_temp_level: int
    standby_detect: list[int]


C2_EXCEPTIONS: dict[str, OtherExceptions] = {}
FC_EXCEPTIONS: dict[str, OtherExceptions] = {}
