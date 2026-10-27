"""Per-model fan exceptions."""

from typing import TypedDict


class FanExceptions(TypedDict, total=False):
    """Fan defaults overridden for a specific model."""

    speed_count: int
    speeds: dict[int, str]
    default_speed: int
    mode_set_overrides: dict[int, int]


B6_EXCEPTIONS: dict[str, FanExceptions] = {}
CE_EXCEPTIONS: dict[str, FanExceptions] = {}
FA_EXCEPTIONS: dict[str, FanExceptions] = {}
