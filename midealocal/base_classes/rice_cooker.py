"""Shared rice cooker classes for Midea devices."""

from typing import ClassVar

from midealocal.device import MideaDevice


class MideaRiceCookerDevice(MideaDevice):
    """Base class for rice-cooker Midea devices (ea, ec).

    Holds the mode-name table common to every rice cooker. A device with
    extra protocol-specific modes overrides ``_mode_list`` by extending
    this one rather than retyping it.
    """

    _mode_list: ClassVar[list[str]] = (
        [
            "smart",
            "reserve",
            "cook_rice",
            "fast_cook_rice",
            "standard_cook_rice",
            "gruel",
            "cook_congee",
            "stew_soup",
            "stewing",
            "heat_rice",
            "make_cake",
            "yoghourt",
            "soup_rice",
            "coarse_rice",
            "five_ceeals_rice",
            "eight_treasures_rice",
            "crispy_rice",
            "shelled_rice",
            "eight_treasures_congee",
            "infant_congee",
            "older_rice",
            "rice_soup",
            "rice_paste",
            "egg_custard",
            "warm_milk",
            "hot_spring_egg",
            "millet_congee",
            "firewood_rice",
            "few_rice",
            "red_potato",
            "corn",
            "quick_freeze_bun",
            "steam_ribs",
            "steam_egg",
            "coarse_congee",
            "steep_rice",
            "appetizing_congee",
            "corn_congee",
            "sprout_rice",
            "luscious_rice",
            "luscious_boiled",
            "fast_rice",
            "fast_boil",
            "bean_rice_congee",
            "fast_congee",
            "baby_congee",
            "cook_soup",
            "congee_coup",
            "steam_corn",
            "steam_red_potato",
            "boil_congee",
            "delicious_steam",
            "boil_egg",
            "rice_wine",
            "fruit_vegetable_paste",
            "vegetable_porridge",
            "pork_porridge",
            "fragrant_rice",
            "assorte_rice",
            "steame_fish",
            "baby_rice",
            "essence_rice",
            "fragrant_dense_congee",
            "one_two_cook",
            "original_steame",
            "hot_fast_rice",
            "online_celebrity_rice",
            "sushi_rice",
            "stone_bowl_rice",
            "no_water_treat",
            "keep_fresh",
            "low_sugar_rice",
            "black_buckwheat_rice",
            "resveratrol_rice",
            "yellow_wheat_rice",
            "green_buckwheat_rice",
            "roughage_rice",
            "millet_mixed_rice",
            "iron_pan_rice",
            "olla_pan_rice",
            "vegetable_rice",
            "baby_side",
            "regimen_congee",
            "earthen_pot_congee",
            "regimen_soup",
            "pottery_jar_soup",
            "canton_soup",
            "nutrition_stew",
            "northeast_stew",
            "uncap_boil",
            "trichromatic_coarse_grain",
            "four_color_vegetables",
            "egg",
            "chop",
        ]
        + ["unknown"] * 98
        + ["clean"]
        + ["unknown"] * 5
        + ["keep_warm"]
    )

    @classmethod
    def mode_options(cls) -> list[str]:
        """Return the distinct cooking modes this device can report, in order."""
        return [mode for mode in cls._mode_list if mode != "unknown"]
