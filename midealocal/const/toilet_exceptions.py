"""Per-model toilet exceptions."""

from typing import TypedDict


class ToiletExceptions(TypedDict, total=False):
    """Toilet defaults overridden for a specific model."""

    max_dry_level: int
    max_water_temp_level: int
    max_seat_temp_level: int


C2_EXCEPTIONS: dict[str, ToiletExceptions] = {}
