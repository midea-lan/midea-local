local bit = require "bit"
local JSON = require "cjson"
local version = 15
local dcControlMapping = {
    ["dc_power"] = {
        ["type"] = 0x01,
        ["length"] = 1,
        ["value"] = {["on"] = 1, ["off"] = 0}
    },
    ["dc_control_status"] = {
        ["type"] = 0x02,
        ["length"] = 1,
        ["value"] = {["start"] = 1, ["pause"] = 0}
    },
    ["dc_program"] = {
        ["type"] = 0x04,
        ["length"] = 1,
        ["value"] = {
            ["cotton"] = 0x00,
            ["fiber"] = 0x01,
            ["mixed_wash"] = 0x02,
            ["jean"] = 0x03,
            ["bedsheet"] = 0x04,
            ["outdoor"] = 0x05,
            ["down_jacket"] = 0x06,
            ["plush"] = 0x07,
            ["wool"] = 0x08,
            ["dehumidify"] = 0x09,
            ["cold_air_fresh_air"] = 0x0a,
            ["hot_air_dry"] = 0x0b,
            ["sport_clothes"] = 0x0c,
            ["underwear"] = 0x0d,
            ["baby_clothes"] = 0x0e,
            ["shirt"] = 0x0f,
            ["standard"] = 0x10,
            ["quick_dry"] = 0x11,
            ["fresh_air"] = 0x12,
            ["low_temp_dry"] = 0x13,
            ["eco_dry"] = 0x14,
            ["intelligent_dry"] = 0x17,
            ["steam_care"] = 0x18,
            ["big"] = 0x19,
            ["fixed_time_dry"] = 0x1a,
            ["night_dry"] = 0x1b,
            ["bracket_dry"] = 0x1c,
            ["western_trouser"] = 0x1d,
            ["dehumidification"] = 0x1e,
            ["silk"] = 0x1f,
            ["air_wash"] = 0x25
        }
    },
    ["dc_dry_time"] = {["type"] = 0x05, ["length"] = 2},
    ["dc_intensity"] = {["type"] = 0x07, ["length"] = 1},
    ["dc_light"] = {["type"] = 0x08, ["length"] = 1},
    ["dc_baby_lock"] = {["type"] = 0x09, ["length"] = 1},
    ["dc_appointment"] = {["type"] = 0x0B, ["length"] = 1},
    ["dc_sterilize"] = {["type"] = 0x0D, ["length"] = 1},
    ["dc_remind_sound"] = {["type"] = 0x0E, ["length"] = 1},
    ["dc_position"] = {["type"] = 0x0F, ["length"] = 1},
    ["dc_appointment_time"] = {["type"] = 0x10, ["length"] = 2},
    ["dc_steam"] = {["type"] = 0x11, ["length"] = 1},
    ["dc_prevent_wrinkle"] = {["type"] = 0x12, ["length"] = 1}
}
local dbControlMapping = {
    ["db_power"] = {
        ["type"] = 0x01,
        ["length"] = 1,
        ["value"] = {["on"] = 1, ["off"] = 0}
    },
    ["db_control_status"] = {
        ["type"] = 0x02,
        ["length"] = 1,
        ["value"] = {["start"] = 1, ["pause"] = 0}
    },
    ["db_program"] = {
        ["type"] = 0x04,
        ["length"] = 1,
        ["value"] = {
            ["cotton"] = 0x00,
            ["eco"] = 0x01,
            ["fast_wash"] = 0x02,
            ["mixed_wash"] = 0x03,
            ["wool"] = 0x05,
            ["ssp"] = 0x07,
            ["sport_clothes"] = 0x08,
            ["single_dehytration"] = 0x09,
            ["rinsing_dehydration"] = 0x0A,
            ["big"] = 0x0B,
            ["baby_clothes"] = 0x0C,
            ["down_jacket"] = 0x0F,
            ["color"] = 0x10,
            ["intelligent"] = 0x11,
            ["quick_wash"] = 0x12,
            ["shirt"] = 0x1C,
            ["fiber"] = 0x04,
            ["enzyme"] = 0x06,
            ["underwear"] = 0x0D,
            ["outdoor"] = 0x0E,
            ["air_wash"] = 0x15,
            ["single_drying"] = 0x16,
            ["steep"] = 0x1D,
            ["kids"] = 0x13,
            ["water_baby_clothes"] = 0x14,
            ["fast_wash_30"] = 0x17,
            ["water_shirt"] = 0x18,
            ["water_mixed_wash"] = 0x1F,
            ["water_fiber"] = 0x20,
            ["water_kids"] = 0x21,
            ["water_underwear"] = 0x22,
            ["specialist"] = 0x23,
            ["love"] = 0xFE,
            ["water_intelligent"] = 0x19,
            ["water_steep"] = 0x1A,
            ["water_fast_wash_30"] = 0x1B,
            ["new_water_cotton"] = 0x1E,
            ["water_eco"] = 0x24,
            ["wash_drying_60"] = 0x25,
            ["self_wash_5"] = 0x26,
            ["fast_wash_min"] = 0x27,
            ["mixed_wash_min"] = 0x28,
            ["dehydration_min"] = 0x29,
            ["self_wash_min"] = 0x2A,
            ["baby_clothes_min"] = 0x2B,
            ["silk_wash"] = 0x65,
            ["prevent_allergy"] = 0x2C,
            ["cold_wash"] = 0x2D,
            ["soft_wash"] = 0x2E,
            ["remove_mite_wash"] = 0x2F,
            ["water_intense_wash"] = 0x30,
            ["fast_dry"] = 0x31,
            ["water_outdoor"] = 0x32,
            ["spring_autumn_wash"] = 0x33,
            ["summer_wash"] = 0x34,
            ["winter_wash"] = 0x35,
            ["jean"] = 0x36,
            ["new_clothes_wash"] = 0x37,
            ["silk"] = 0x38,
            ["insight_wash"] = 0x39,
            ["fitness_clothes"] = 0x3A,
            ["mink"] = 0x3B,
            ["fresh_air"] = 0x3C,
            ["bucket_dry"] = 0x3D,
            ["jacket"] = 0x3E,
            ["bath_towel"] = 0x3F,
            ["night_fresh_wash"] = 0x40,
            ["heart_wash"] = 0x60,
            ["water_cold_wash"] = 0x61,
            ["water_prevent_allergy"] = 0x62,
            ["water_remove_mite_wash"] = 0x63,
            ["water_ssp"] = 0x64,
            ["standard"] = 0x66,
            ["green_wool"] = 0x67,
            ["cook_wash"] = 0x68,
            ["fresh_remove_wrinkle"] = 0x69,
            ["steam_sterilize_wash"] = 0x6A,
            ["sterilize_wash"] = 0x70
        }
    },
    ["db_water_level"] = {["type"] = 0x05, ["length"] = 1},
    ["db_dry"] = {["type"] = 0x06, ["length"] = 1},
    ["db_rinse_count"] = {["type"] = 0x07, ["length"] = 1},
    ["db_temperature"] = {["type"] = 0x08, ["length"] = 1},
    ["db_dehydration_speed"] = {["type"] = 0x09, ["length"] = 1},
    ["db_wash_time"] = {["type"] = 0x0A, ["length"] = 1},
    ["db_detergent"] = {["type"] = 0x0B, ["length"] = 1},
    ["db_softener"] = {["type"] = 0x0C, ["length"] = 1},
    ["db_appointment_time"] = {["type"] = 0x0D, ["length"] = 2},
    ["db_memory"] = {["type"] = 0x0E, ["length"] = 1},
    ["db_appointment"] = {["type"] = 0x0F, ["length"] = 1},
    ["db_spray_wash"] = {["type"] = 0x10, ["length"] = 1},
    ["db_speedy_wash"] = {["type"] = 0x11, ["length"] = 1},
    ["db_nightly_wash"] = {["type"] = 0x12, ["length"] = 1},
    ["db_baby_lock"] = {["type"] = 0x13, ["length"] = 1},
    ["db_light"] = {["type"] = 0x14, ["length"] = 1},
    ["db_easy_ironing"] = {["type"] = 0x15, ["length"] = 1},
    ["db_appointment_wash"] = {["type"] = 0x16, ["length"] = 1},
    ["db_super_clean_wash"] = {["type"] = 0x17, ["length"] = 1},
    ["db_intelligent_wash"] = {["type"] = 0x18, ["length"] = 1},
    ["db_strong_wash"] = {["type"] = 0x19, ["length"] = 1},
    ["db_steam_wash"] = {["type"] = 0x1A, ["length"] = 1},
    ["db_fast_clean_wash"] = {["type"] = 0x1B, ["length"] = 1},
    ["db_disinfectant"] = {["type"] = 0x1C, ["length"] = 1},
    ["db_stains_wash"] = {["type"] = 0x1D, ["length"] = 1},
    ["db_sterilize"] = {["type"] = 0x1E, ["length"] = 1},
    ["db_soak_wash"] = {["type"] = 0x1F, ["length"] = 1},
    ["db_water_quality_link"] = {["type"] = 0x22, ["length"] = 1},
    ["db_dehydration_time"] = {["type"] = 0x27, ["length"] = 1},
    ["db_position"] = {["type"] = 0x2A, ["length"] = 1},
    ["db_location"] = {["type"] = 0x32, ["length"] = 1},
    ["db_material"] = {["type"] = 0x36, ["length"] = 1},
    ["db_ai"] = {["type"] = 0x3A, ["length"] = 1}
}
local daControlMapping = {
    ["da_power"] = {
        ["type"] = 0x01,
        ["length"] = 1,
        ["value"] = {["on"] = 1, ["off"] = 0}
    },
    ["da_control_status"] = {
        ["type"] = 0x02,
        ["length"] = 1,
        ["value"] = {["start"] = 1, ["pause"] = 0}
    },
    ["da_program"] = {
        ["type"] = 0x04,
        ["length"] = 1,
        ["value"] = {
            ["standard"] = 0x00,
            ["fast"] = 0x01,
            ["blanket"] = 0x02,
            ["wool"] = 0x03,
            ["embathe"] = 0x04,
            ["memory"] = 0x05,
            ["child"] = 0x06,
            ["strong_wash"] = 0x07,
            ["down_jacket"] = 0x08,
            ["stir"] = 0x09,
            ["mute"] = 0x0A,
            ["bucket_self_clean"] = 0x0B,
            ["air_dry"] = 0x0C,
            ["cycle"] = 0x0D,
            ["remain_water"] = 0x10,
            ["summer"] = 0x11,
            ["big"] = 0x12,
            ["home"] = 0x13,
            ["cowboy"] = 0x14,
            ["soft"] = 0x15,
            ["hand_wash"] = 0x16,
            ["water_flow"] = 0x17,
            ["fog"] = 0x18,
            ["bucket_dry"] = 0x19,
            ["fast_clean_wash"] = 0x1A,
            ["dehydration"] = 0x1B,
            ["under_wear"] = 0x1C,
            ["rinse_dehydration"] = 0x1D,
            ["one_minute_self_clean"] = 0x1E,
            ["degerm"] = 0x1F,
            ["in_15"] = 0x20,
            ["in_25"] = 0x21,
            ["love_baby"] = 0x22,
            ["outdoor"] = 0x23,
            ["silk"] = 0x24,
            ["shirt"] = 0x25,
            ["cook_wash"] = 0x26,
            ["towel"] = 0x27
        }
    },
    ["da_water_level"] = {["type"] = 0x05, ["length"] = 1},
    ["da_rinse_level"] = {["type"] = 0x06, ["length"] = 1},
    ["da_wash_strength"] = {["type"] = 0x07, ["length"] = 1},
    ["da_dehydration_speed"] = {["type"] = 0x08, ["length"] = 1},
    ["da_detergent"] = {["type"] = 0x09, ["length"] = 1},
    ["da_softener"] = {["type"] = 0x0A, ["length"] = 1},
    ["da_wash_time"] = {["type"] = 0x0B, ["length"] = 1},
    ["da_rinse_count"] = {["type"] = 0x0C, ["length"] = 1},
    ["da_dehydration_time"] = {["type"] = 0x0D, ["length"] = 1},
    ["da_soak_waterlevel"] = {["type"] = 0x0E, ["length"] = 1},
    ["da_soak_time"] = {["type"] = 0x0F, ["length"] = 1},
    ["da_appointment_time"] = {["type"] = 0x10, ["length"] = 2},
    ["da_baby_lock"] = {["type"] = 0x11, ["length"] = 1},
    ["da_light"] = {["type"] = 0x12, ["length"] = 1},
    ["da_offcenter_wash"] = {["type"] = 0x13, ["length"] = 1},
    ["da_fcs"] = {["type"] = 0x14, ["length"] = 1},
    ["da_auto_weighting"] = {["type"] = 0x15, ["length"] = 1},
    ["da_appointment_status"] = {["type"] = 0x16, ["length"] = 1},
    ["da_intense_wash"] = {["type"] = 0x17, ["length"] = 1},
    ["da_air_dry"] = {["type"] = 0x18, ["length"] = 1},
    ["da_keep_water"] = {["type"] = 0x19, ["length"] = 1},
    ["da_wash_pump"] = {["type"] = 0x1A, ["length"] = 1},
    ["da_rinse_pump"] = {["type"] = 0x1B, ["length"] = 1},
    ["da_automatic_door"] = {["type"] = 0x1C, ["length"] = 1},
    ["da_temperature"] = {["type"] = 0x20, ["length"] = 1},
    ["da_position"] = {["type"] = 0x22, ["length"] = 1}
}
local dcQueryTable = {
    [1] = 0xAA,
    [2] = 0x0B,
    [3] = 0xD9,
    [4] = 0xD0,
    [5] = 0x00,
    [6] = 0x00,
    [7] = 0x00,
    [8] = 0x00,
    [9] = 0x00,
    [10] = 0x03,
    [11] = 0xDC,
    [12] = 0x6D
}
local dbQueryTable = {
    [1] = 0xAA,
    [2] = 0x0B,
    [3] = 0xD9,
    [4] = 0xD0,
    [5] = 0x00,
    [6] = 0x00,
    [7] = 0x00,
    [8] = 0x00,
    [9] = 0x00,
    [10] = 0x03,
    [11] = 0xDB,
    [12] = 0x6E
}
local upDBQueryTable = {
    [1] = 0xAA,
    [2] = 0x0E,
    [3] = 0xD9,
    [4] = 0xD0,
    [5] = 0x00,
    [6] = 0x00,
    [7] = 0x00,
    [8] = 0x00,
    [9] = 0x00,
    [10] = 0x03,
    [11] = 0xDB,
    [12] = 0x32,
    [13] = 0x01,
    [14] = 0x01,
    [15] = 0x37
}
local downDBQueryTable = {
    [1] = 0xAA,
    [2] = 0x0E,
    [3] = 0xD9,
    [4] = 0xD0,
    [5] = 0x00,
    [6] = 0x00,
    [7] = 0x00,
    [8] = 0x00,
    [9] = 0x00,
    [10] = 0x03,
    [11] = 0xDB,
    [12] = 0x32,
    [13] = 0x01,
    [14] = 0x02,
    [15] = 0x36
}
local daQueryTable = {
    [1] = 0xAA,
    [2] = 0x0B,
    [3] = 0xD9,
    [4] = 0xD0,
    [5] = 0x00,
    [6] = 0x00,
    [7] = 0x00,
    [8] = 0x00,
    [9] = 0x00,
    [10] = 0x03,
    [11] = 0xDA,
    [12] = 0x6F
}
local dcReportMapping = {
    [1] = {["name"] = "dc_power", ["value"] = {[0] = "off", [1] = "on"}},
    [4] = {
        ["name"] = "dc_program",
        ["value"] = {
            [0] = "cotton",
            [1] = "fiber",
            [2] = "mixed_wash",
            [3] = "jean",
            [4] = "bedsheet",
            [5] = "outdoor",
            [6] = "down_jacket",
            [7] = "plush",
            [8] = "wool",
            [9] = "dehumidify",
            [10] = "cold_air_fresh_air",
            [11] = "hot_air_dry",
            [12] = "sport_clothes",
            [13] = "underwear",
            [14] = "baby_clothes",
            [15] = "shirt",
            [16] = "standard",
            [17] = "quick_dry",
            [18] = "fresh_air",
            [19] = "low_temp_dry",
            [20] = "eco_dry",
            [23] = "intelligent_dry",
            [24] = "steam_care",
            [25] = "big",
            [26] = "fixed_time_dry",
            [27] = "night_dry",
            [28] = "bracket_dry",
            [29] = "western_trouser",
            [30] = "dehumidification",
            [31] = "silk",
            [37] = "air_wash"
        }
    },
    [5] = {["name"] = "dc_dry_time"},
    [7] = {["name"] = "dc_intensity"},
    [8] = {["name"] = "dc_light"},
    [9] = {["name"] = "dc_baby_lock"},
    [11] = {["name"] = "dc_appointment"},
    [13] = {["name"] = "dc_sterilize"},
    [14] = {["name"] = "dc_remind_sound"},
    [15] = {["name"] = "dc_position"},
    [16] = {["name"] = "dc_appointment_time"},
    [17] = {["name"] = "dc_steam"},
    [18] = {["name"] = "dc_prevent_wrinkle"},
    [19] = {
        ["name"] = "dc_running_status",
        ["value"] = {
            [1] = "standby",
            [2] = "start",
            [3] = "pause",
            [4] = "end",
            [5] = "fault",
            [6] = "delay",
            [8] = "delay"
        }
    },
    [20] = {["name"] = "dc_error_code"},
    [21] = {
        ["name"] = "dc_dry_status",
        ["value"] = {
            [1] = "heating",
            [2] = "ironing",
            [4] = "cooling",
            [8] = "ending",
            [16] = "preventwrinkling",
            [32] = "sterilizing",
            [64] = "steamironing"
        }
    },
    [22] = {["name"] = "dc_remain_time"},
    [43] = {["name"] = "dc_project_no"},
    [44] = {["name"] = "dc_water_consumption"},
    [45] = {["name"] = "dc_power_consumption"},
    [46] = {["name"] = "dc_appointment_end_time"},
    [50] = {["name"] = "dc_location"}
}
local dbReportMapping = {
    [1] = {["name"] = "db_power", ["value"] = {[0] = "off", [1] = "on"}},
    [4] = {
        ["name"] = "db_program",
        ["value"] = {
            [0] = "cotton",
            [1] = "eco",
            [2] = "fast_wash",
            [3] = "mixed_wash",
            [5] = "wool",
            [7] = "ssp",
            [8] = "sport_clothes",
            [9] = "single_dehytration",
            [10] = "rinsing_dehydration",
            [11] = "big",
            [12] = "baby_clothes",
            [15] = "down_jacket",
            [16] = "color",
            [17] = "intelligent",
            [18] = "quick_wash",
            [28] = "shirt",
            [4] = "fiber",
            [6] = "enzyme",
            [13] = "underwear",
            [14] = "outdoor",
            [21] = "air_wash",
            [22] = "single_drying",
            [29] = "steep",
            [19] = "kids",
            [20] = "water_baby_clothes",
            [23] = "fast_wash_30",
            [24] = "water_shirt",
            [31] = "water_mixed_wash",
            [32] = "water_fiber",
            [33] = "water_kids",
            [34] = "water_underwear",
            [35] = "specialist",
            [254] = "love",
            [25] = "water_intelligent",
            [26] = "water_steep",
            [27] = "water_fast_wash_30",
            [30] = "new_water_cotton",
            [36] = "water_eco",
            [37] = "wash_drying_60",
            [38] = "self_wash_5",
            [39] = "fast_wash_min",
            [40] = "mixed_wash_min",
            [41] = "dehydration_min",
            [42] = "self_wash_min",
            [43] = "baby_clothes_min",
            [101] = "silk_wash",
            [44] = "prevent_allergy",
            [45] = "cold_wash",
            [46] = "soft_wash",
            [47] = "remove_mite_wash",
            [48] = "water_intense_wash",
            [49] = "fast_dry",
            [50] = "water_outdoor",
            [51] = "spring_autumn_wash",
            [52] = "summer_wash",
            [53] = "winter_wash",
            [54] = "jean",
            [55] = "new_clothes_wash",
            [56] = "silk",
            [57] = "insight_wash",
            [58] = "fitness_clothes",
            [59] = "mink",
            [60] = "fresh_air",
            [61] = "bucket_dry",
            [62] = "jacket",
            [63] = "bath_towel",
            [64] = "night_fresh_wash",
            [96] = "heart_wash",
            [97] = "water_cold_wash",
            [98] = "water_prevent_allergy",
            [99] = "water_remove_mite_wash",
            [100] = "water_ssp",
            [102] = "standard",
            [103] = "green_wool",
            [104] = "cook_wash",
            [105] = "fresh_remove_wrinkle",
            [106] = "steam_sterilize_wash",
            [112] = "sterilize_wash"
        }
    },
    [5] = {["name"] = "db_water_level"},
    [6] = {["name"] = "db_dry"},
    [7] = {["name"] = "db_rinse_count"},
    [8] = {["name"] = "db_temperature"},
    [9] = {["name"] = "db_dehydration_speed"},
    [10] = {["name"] = "db_wash_time"},
    [11] = {["name"] = "db_detergent"},
    [12] = {["name"] = "db_softener"},
    [13] = {["name"] = "db_appointment_time"},
    [14] = {["name"] = "db_memory"},
    [15] = {["name"] = "db_appointment"},
    [16] = {["name"] = "db_spray_wash"},
    [17] = {["name"] = "db_speedy_wash"},
    [18] = {["name"] = "db_nightly_wash"},
    [19] = {["name"] = "db_baby_lock"},
    [20] = {["name"] = "db_light"},
    [21] = {["name"] = "db_easy_ironing"},
    [22] = {["name"] = "db_appointment_wash"},
    [23] = {["name"] = "db_super_clean_wash"},
    [24] = {["name"] = "db_intelligent_wash"},
    [25] = {["name"] = "db_strong_wash"},
    [26] = {["name"] = "db_steam_wash"},
    [27] = {["name"] = "db_fast_clean_wash"},
    [28] = {["name"] = "db_disinfectant"},
    [29] = {["name"] = "db_stains_wash"},
    [30] = {["name"] = "db_sterilize"},
    [31] = {["name"] = "db_soak_wash"},
    [32] = {["name"] = "db_detergent_increment"},
    [33] = {["name"] = "db_softener_increment"},
    [34] = {["name"] = "db_water_quality_link"},
    [35] = {["name"] = "db_remain_time"},
    [36] = {
        ["name"] = "db_running_status",
        ["value"] = {
            [0] = "off",
            [1] = "standby",
            [2] = "start",
            [3] = "pause",
            [4] = "end",
            [5] = "fault",
            [6] = "delay"
        }
    },
    [37] = {["name"] = "db_progress"},
    [38] = {["name"] = "db_error_code"},
    [39] = {["name"] = "db_dehydration_time"},
    [40] = {["name"] = "db_set_dewater_time"},
    [41] = {["name"] = "db_set_wash_time"},
    [42] = {["name"] = "db_position"},
    [43] = {["name"] = "db_project_no"},
    [44] = {["name"] = "db_water_consumption"},
    [45] = {["name"] = "db_power_consumption"},
    [46] = {["name"] = "db_clean_notification"},
    [47] = {["name"] = "db_softener_needed"},
    [48] = {["name"] = "db_detergent_needed"},
    [50] = {["name"] = "db_location"},
    [51] = {["name"] = "db_water_radar_rinse"},
    [52] = {["name"] = "db_water_radar_wash_time"},
    [53] = {["name"] = "db_appointment_end_time"},
    [54] = {["name"] = "db_material"},
    [58] = {["name"] = "db_ai"}
}
local daReportMapping = {
    [1] = {["name"] = "da_power", ["value"] = {[0] = "off", [1] = "on"}},
    [4] = {
        ["name"] = "da_program",
        ["value"] = {
            [0] = "standard",
            [1] = "fast",
            [2] = "blanket",
            [3] = "wool",
            [4] = "embathe",
            [5] = "memory",
            [6] = "child",
            [7] = "strong_wash",
            [8] = "down_jacket",
            [9] = "stir",
            [10] = "mute",
            [11] = "bucket_self_clean",
            [12] = "air_dry",
            [13] = "cycle",
            [16] = "remain_water",
            [17] = "summer",
            [18] = "big",
            [19] = "home",
            [20] = "cowboy",
            [21] = "soft",
            [22] = "hand_wash",
            [23] = "water_flow",
            [24] = "fog",
            [25] = "bucket_dry",
            [26] = "fast_clean_wash",
            [27] = "dehydration",
            [28] = "under_wear",
            [29] = "rinse_dehydration",
            [30] = "one_minute_self_clean",
            [31] = "degerm",
            [32] = "in_15",
            [33] = "in_25",
            [34] = "love_baby",
            [35] = "outdoor",
            [36] = "silk",
            [37] = "shirt",
            [38] = "cook_wash",
            [39] = "towel"
        }
    },
    [5] = {["name"] = "da_water_level"},
    [6] = {["name"] = "da_rinse_level"},
    [7] = {["name"] = "da_wash_strength"},
    [8] = {["name"] = "da_dehydration_speed"},
    [9] = {["name"] = "da_detergent"},
    [10] = {["name"] = "da_softener"},
    [11] = {["name"] = "da_wash_time"},
    [12] = {["name"] = "da_rinse_count"},
    [13] = {["name"] = "da_dehydration_time"},
    [14] = {["name"] = "da_soak_waterlevel"},
    [15] = {["name"] = "da_soak_time"},
    [16] = {["name"] = "da_appointment_time"},
    [17] = {["name"] = "da_baby_lock"},
    [18] = {["name"] = "da_light"},
    [19] = {["name"] = "da_offcenter_wash"},
    [20] = {["name"] = "da_fcs"},
    [21] = {["name"] = "da_auto_weighting"},
    [22] = {["name"] = "da_appointment_status"},
    [23] = {["name"] = "da_intense_wash"},
    [24] = {["name"] = "da_air_dry"},
    [25] = {["name"] = "da_keep_water"},
    [26] = {["name"] = "da_wash_pump"},
    [27] = {["name"] = "da_rinse_pump"},
    [28] = {["name"] = "da_automatic_door"},
    [29] = {["name"] = "da_remain_time"},
    [30] = {
        ["name"] = "da_running_status",
        ["value"] = {
            [1] = "standby",
            [2] = "start",
            [3] = "pause",
            [4] = "end",
            [5] = "fault",
            [6] = "delay"
        }
    },
    [31] = {["name"] = "da_error_code"},
    [32] = {["name"] = "da_temperature"},
    [33] = {["name"] = "da_progress"},
    [34] = {["name"] = "da_position"},
    [43] = {["name"] = "da_project_no"},
    [44] = {["name"] = "da_water_consumption"},
    [45] = {["name"] = "da_power_consumption"},
    [46] = {["name"] = "da_clean_notification"},
    [47] = {["name"] = "da_softener_needed"},
    [48] = {["name"] = "da_detergent_needed"},
    [50] = {["name"] = "da_location"}
}
local commandSpec = {
    power = {offset = 88, bits = 8},
    control_status = {offset = 96, bits = 8},
    program = {offset = 112, bits = 8}
}
local function decodeJsonToTable(cmd)
    local tb
    tb = JSON.decode(cmd)
    return tb
end
local function encodeTableToJson(luaTable)
    local jsonStr
    jsonStr = JSON.encode(luaTable)
    return jsonStr
end
local function checkSum(controlTable)
    local checksum = 0;
    for i = 2, #controlTable do checksum = checksum + controlTable[i]; end
    return bit.band((bit.bnot(checksum) + 1), 0x00FF);
end
local function hextonumber(hexstr) return tonumber(hexstr, 16) end
local function hexstrtotable(hexstr, reportMapping, reportType, bucketType)
    local tb = {}
    local i = 23
    while (i <= #hexstr - 2) do
        local dataType = hextonumber(string.sub(hexstr, i, i + 1))
        local length = hextonumber(string.sub(hexstr, i + 2, i + 3))
        if (length == 1) then
            if (reportMapping[dataType]) then
                local value = hextonumber(string.sub(hexstr, i + 4, i + 5))
                if (reportMapping[dataType]["value"]) then
                    tb[reportMapping[dataType]["name"]] =
                        reportMapping[dataType]["value"][value]
                else
                    if (reportMapping[dataType]["name"] == "da_error_code" or
                        reportMapping[dataType]["name"] == "db_error_code" or
                        reportMapping[dataType]["name"] == "dc_error_code") then
                        tb[reportMapping[dataType]["name"]] = string.format(
                                                                  "%x", value)
                    else
                        tb[reportMapping[dataType]["name"]] = value
                    end
                end
            end
        elseif (length == 2) then
            if (reportMapping[dataType]) then
                local value = hextonumber(
                                  string.sub(hexstr, i + 6, i + 7) ..
                                      string.sub(hexstr, i + 4, i + 5))
                if (reportMapping[dataType]["value"]) then
                    tb[reportMapping[dataType]["name"]] =
                        reportMapping[dataType]["value"][value]
                else
                    tb[reportMapping[dataType]["name"]] = value
                end
            end
        elseif (length == 3) then
            if (reportMapping[dataType]) then
                local value
                if (reportMapping[dataType]["name"] == "da_water_consumption" or
                    reportMapping[dataType]["name"] == "da_power_consumption" or
                    reportMapping[dataType]["name"] == "db_water_consumption" or
                    reportMapping[dataType]["name"] == "db_power_consumption" or
                    reportMapping[dataType]["name"] == "dc_water_consumption" or
                    reportMapping[dataType]["name"] == "dc_power_consumption") then
                    value = hextonumber(string.sub(hexstr, i + 8, i + 9) ..
                                            string.sub(hexstr, i + 6, i + 7) ..
                                            string.sub(hexstr, i + 4, i + 5))
                elseif (reportMapping[dataType]["name"] ==
                    "db_appointment_end_time" or reportMapping[dataType]["name"] ==
                    "dc_appointment_end_time") then
                    local todayOrTomorrow =
                        hextonumber(string.sub(hexstr, i + 8, i + 9))
                    value = hextonumber(string.sub(hexstr, i + 6, i + 7) ..
                                            string.sub(hexstr, i + 4, i + 5))
                    if (todayOrTomorrow == 1) then
                        value = value + 1440
                    end
                else
                    value = hextonumber(string.sub(hexstr, i + 6, i + 7) ..
                                            string.sub(hexstr, i + 4, i + 5))
                end
                tb[reportMapping[dataType]["name"]] = value
            end
        end
        i = i + 4 + length * 2
    end
    tb["version"] = version
    tb["bucket"] = bucketType
    tb["data_type"] = reportType
    local result = {}
    result["status"] = tb
    return encodeTableToJson(result)
end
local function jsontotable(control, controlMapping)
    local header = {
        [1] = 0xAA,
        [2] = 0xFF,
        [3] = 0xD9,
        [4] = 0x00,
        [5] = 0x00,
        [6] = 0x00,
        [7] = 0x00,
        [8] = 0x00,
        [9] = 0x00,
        [10] = 0x02,
        [11] = 0x02
    }
    local offset = 12
    for k in pairs(control) do
        if (k ~= "bucket") then
            header[offset] = controlMapping[k]["type"]
            header[offset + 1] = controlMapping[k]["length"]
            if (header[offset + 1] == 1) then
                if (controlMapping[k]["value"]) then
                    header[offset + 2] = controlMapping[k]["value"][control[k]]
                else
                    header[offset + 2] = control[k]
                end
            elseif (header[offset + 1] == 2) then
                header[offset + 2] = bit.band(control[k], 0x00FF)
                header[offset + 3] = bit.rshift(bit.band(control[k], 0xFF00), 8)
            end
            offset = offset + 1 + controlMapping[k]["length"] + 1
        end
    end
    header[2] = #header
    header[11] = tonumber(control["bucket"], 16)
    header[#header + 1] = checkSum(header)
    return header
end
local function updateArg(tempTable, argsTable, controlMapping)
    for k in pairs(argsTable) do
        if (controlMapping[k]) then tempTable[k] = argsTable[k] end
    end
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    local tmpTable = {}
    if (control) then
        local tab = {}
        if (control["bucket"] == 'da') then
            updateArg(tab, control, daControlMapping)
            tab["bucket"] = "da"
            tmpTable = jsontotable(tab, daControlMapping)
        elseif (control["bucket"] == 'db') then
            updateArg(tab, control, dbControlMapping)
            tab["bucket"] = "db"
            tmpTable = jsontotable(tab, dbControlMapping)
        elseif (control["bucket"] == 'dc') then
            updateArg(tab, control, dcControlMapping)
            tab["bucket"] = "dc"
            tmpTable = jsontotable(tab, dcControlMapping)
        else
            return nil
        end
    elseif (query) then
        if (query["query_type"] == 'da') then
            tmpTable = daQueryTable
        elseif (query["query_type"] == 'db') then
            local UP_BUCKET = 1
            local DOWN_BUCKET = 2
            if (query["db_location"] == UP_BUCKET) then
                tmpTable = upDBQueryTable
            elseif (query["db_location"] == DOWN_BUCKET) then
                tmpTable = downDBQueryTable
            else
                tmpTable = dbQueryTable
            end
        elseif (query["query_type"] == 'dc') then
            tmpTable = dcQueryTable
        else
            tmpTable = dbQueryTable
        end
    end
    local hex = '';
    for key = 1, #tmpTable, 1 do
        hex = hex .. string.format("%02x", tmpTable[key]);
    end
    return hex
end
function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decodeJsonToTable(jsonStr)
    local binData = json["msg"]["data"]
    local reportType = string.lower(string.sub(binData, 19, 22))
    if (reportType == '02da' or reportType == '03da' or reportType == '04da') then
        return hexstrtotable(binData, daReportMapping, reportType, 'da')
    elseif (reportType == '02db' or reportType == '03db' or reportType == '04db') then
        return hexstrtotable(binData, dbReportMapping, reportType, 'db')
    elseif (reportType == '02dc' or reportType == '03dc' or reportType == '04dc') then
        return hexstrtotable(binData, dcReportMapping, reportType, 'dc')
    else
        return hexstrtotable(binData, dbReportMapping, reportType, 'db')
    end
end
