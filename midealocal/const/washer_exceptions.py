"""Per-model washer exceptions."""

from typing import TypedDict


class WasherExceptions(TypedDict, total=False):
    """Washer protocol defaults overridden for verified model subtypes."""

    subtypes: tuple[int, ...]
    programs: dict[int, str]
    writable_attributes: tuple[str, ...]
    mappings: dict[str, dict[int, str]]
    maximums: dict[str, int]
    maximums_by_program: dict[str, dict[str, int]]


DB_EXCEPTIONS: dict[str, WasherExceptions] = {
    # Model-specific Lua matches lua/db/T_0000_DB_33.lua.
    "38131408": {
        # CLI LAN discovery has the model but passes subtype=0.
        "subtypes": (13146, 0),
        "programs": {
            0x0D: "underwear",
            0x0E: "outdoor",
            0x15: "air_wash",
            0x50: "diy0",
            0x51: "diy1",
        },
        # The owner confirmed this model has no automatic softener dispenser.
        "writable_attributes": (
            "program",
            "temperature",
            "water_level",
            "dehydration_speed",
            "wash_time",
            "dehydration_time",
            "detergent",
            "dryer",
            "steam_wash",
            "fast_clean_wash",
        ),
        "mappings": {
            # Panel selections captured on subtype 13146 (2026-10-29).
            # Code 11 is 180 minutes; codes 2 and 8-10 are not exposed.
            "dryer": {
                0: "off",
                1: "auto",
                3: "low_temperature",
                4: "30",
                5: "60",
                6: "90",
                7: "120",
                11: "180",
            },
        },
        "maximums": {"detergent": 5},
        # Standby captures verified mixed-wash levels 0-4. Actual minutes
        # depend on program/options and are reported in *_time_value.
        "maximums_by_program": {
            "wash_time": {"mixed_wash": 4},
            "dehydration_time": {"mixed_wash": 4},
        },
    },
}
