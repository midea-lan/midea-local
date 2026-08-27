local JSON = require "cjson"
local version = 5

local queryTable = {
    [1] = 0xAA,
    [2] = 0x0B,
    [3] = 0xDC,
    [4] = 0xD7,
    [5] = 0x00,
    [6] = 0x00,
    [7] = 0x00,
    [8] = 0x00,
    [9] = 0x00,
    [10] = 0x03,
    [11] = 0x03,
    [12] = 0x3C
}

local controlMapping = {
    ["power"] = {["on"] = 0x01, ["off"] = 0x00},
    ["control_status"] = {["start"] = 0x01, ["pause"] = 0x00},
    ["program"] = {
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
        ["quick_dry_30"] = 0x15,
        ["towel"] = 0x16,
        ["intelligent_dry"] = 0x17,
        ["steam_care"] = 0x18,
        ["big"] = 0x19,
        ["fixed_time_dry"] = 0x1a,
        ["night_dry"] = 0x1b,
        ["bracket_dry"] = 0x1c,
        ["western_trouser"] = 0x1d,
        ["dehumidification"] = 0x1e,
        ["smart_dry"] = 0x1f,
        ["four_piece_suit"] = 0x20,
        ["warm_clothes"] = 0x21,
        ["quick_dry_20"] = 0x22,
        ["steam_sterilize"] = 0x23,
        ["enzyme"] = 0x24,
        ["big_60"] = 0x25,
        ["steam_no_iron"] = 0x26,
        ["air_wash"] = 0x27,
        ["bed_clothes"] = 0x28,
        ["little_fast_dry"] = 0x29,
        ["small_piece_dry"] = 0x2a,
        ["big_dry"] = 0x2b,
        ["wool_nurse"] = 0x2c,
        ["sun_quilt"] = 0x2d,
        ["fresh_remove_smell"] = 0x2e,
        ["bucket_self_clean"] = 0x2f,
        ["silk"] = 0x30,
        ["sterilize"] = 0x31
    }
}

local reportMapping = {
    [12] = {["name"] = "power", ["value"] = {[0] = "off", [1] = "on"}},
    [13] = {
        ["name"] = "running_status",
        ["value"] = {
            [1] = "standby",
            [2] = "start",
            [3] = "pause",
            [4] = "end",
            [5] = "prevent_wrinkle_end",
            [6] = "delay_choosing",
            [7] = "fault",
            [8] = "delay",
            [9] = "delay_pause"
        }
    },
    [15] = {
        ["name"] = "program",
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
            [21] = "quick_dry_30",
            [22] = "towel",
            [23] = "intelligent_dry",
            [24] = "steam_care",
            [25] = "big",
            [26] = "fixed_time_dry",
            [27] = "night_dry",
            [28] = "bracket_dry",
            [29] = "western_trouser",
            [30] = "dehumidification",
            [31] = "smart_dry",
            [32] = "four_piece_suit",
            [33] = "warm_clothes",
            [34] = "quick_dry_20",
            [35] = "steam_sterilize",
            [36] = "enzyme",
            [37] = "big_60",
            [38] = "steam_no_iron",
            [39] = "air_wash",
            [40] = "bed_clothes",
            [41] = "little_fast_dry",
            [42] = "small_piece_dry",
            [43] = "big_dry",
            [44] = "wool_nurse",
            [45] = "sun_quilt",
            [46] = "fresh_remove_smell",
            [47] = "bucket_self_clean",
            [48] = "silk",
            [49] = "sterilize"
        }
    },
    [16] = {["name"] = "dry_time", ["length"] = 2},
    [20] = {["name"] = "intensity"},
    [21] = {["name"] = "dryness_level"},
    [22] = {["name"] = "dry_temp"},
    [23] = {
        [0x03] = {["name"] = "appointment", ["rshift"] = 0},
        [0x0c] = {["name"] = "prevent_wrinkle_switch", ["rshift"] = 2},
        [0x30] = {["name"] = "baby_lock", ["rshift"] = 4},
        [0xc0] = {["name"] = "light", ["rshift"] = 6}
    },
    [24] = {
        [0x03] = {["name"] = "remind_sound", ["rshift"] = 0},
        [0x0c] = {["name"] = "sterilize", ["rshift"] = 2},
        [0x30] = {["name"] = "steam_switch", ["rshift"] = 4},
        [0xc0] = {["name"] = "damp_dry_signal", ["rshift"] = 6}
    },
    [25] = {["name"] = "appointment_time", ["length"] = 2},
    [27] = {["name"] = "progress"},
    [28] = {["name"] = "remain_time", ["length"] = 2},
    [30] = {
        [0x03] = {["name"] = "eco_dry_switch", ["rshift"] = 0},
        [0x0c] = {["name"] = "bucket_clean_switch", ["rshift"] = 2}
    },
    [32] = {["name"] = "project_no", ["length"] = 2},
    [35] = {["name"] = "error_code"},
    [36] = {["name"] = "door_warn"},
    [37] = {
        [0xf0] = {["name"] = "steam", ["rshift"] = 4},
        [0x0f] = {["name"] = "prevent_wrinkle", ["rshift"] = 0}
    },
    [38] = {["name"] = "ai_switch"},
    [39] = {["name"] = "material"},
    [40] = {["name"] = "water_box"}
}

local commandSpec = {
    power = {offset = 88, bits = 8},
    control_status = {offset = 96, bits = 8},
    program = {offset = 112, bits = 8},
    dry_time = {offset = 120, bits = 16},
    intensity = {offset = 152, bits = 8},
    dryness_level = {offset = 160, bits = 8},
    dry_temp = {offset = 168, bits = 8},
    light = {offset = 176, bits = 2},
    baby_lock = {offset = 178, bits = 2},
    prevent_wrinkle_switch = {offset = 180, bits = 2},
    appointment = {offset = 182, bits = 2},
    damp_dry_signal = {offset = 184, bits = 2},
    steam_switch = {offset = 186, bits = 2},
    sterilize = {offset = 188, bits = 2},
    remind_sound = {offset = 190, bits = 2},
    appointment_time = {offset = 192, bits = 16},
    ai_switch = {offset = 234, bits = 2},
    bucket_clean_switch = {offset = 236, bits = 2},
    eco_dry_switch = {offset = 238, bits = 2},
    steam = {offset = 240, bits = 4},
    prevent_wrinkle = {offset = 244, bits = 4},
    material = {offset = 248, bits = 8}
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
    for i = 2, #controlTable - 1 do checksum = checksum + controlTable[i]; end
    return bit.band((bit.bnot(checksum) + 1), 0x00FF);
end

local function string2table(hexstr)
    local tb = {}
    local i = 1
    local j = 1
    for i = 1, #hexstr - 1, 2 do
        local doublebytestr = string.sub(hexstr, i, i + 1)
        tb[j] = tonumber(doublebytestr, 16)
        j = j + 1
    end
    return tb
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    local query = json["query"]
    local control = json["control"]
    local tmpTable = {}
    if (control) then
        local controlTable = {
            [1] = 0xAA,
            [2] = 0x20,
            [3] = 0xDC,
            [4] = 0x00,
            [5] = 0x00,
            [6] = 0x00,
            [7] = 0x00,
            [8] = 0x00,
            [9] = 0x00,
            [10] = 0x02,
            [11] = 0x02,
            [12] = 0xFF,
            [13] = 0xFF,
            [14] = 0xFF,
            [15] = 0xFF,
            [16] = 0xFF,
            [17] = 0xFF,
            [18] = 0xFF,
            [19] = 0xFF,
            [20] = 0xFF,
            [21] = 0xFF,
            [22] = 0xFF,
            [23] = 0xFF,
            [24] = 0xFF,
            [25] = 0xFF,
            [26] = 0xFF,
            [27] = 0xFF,
            [28] = 0xFF,
            [29] = 0xFF,
            [30] = 0xFF,
            [31] = 0xFF,
            [32] = 0xFF,
            [33] = 0x00
        }
        local bits2Config = {
            [0] = {[0] = 0x3F, [1] = 0x7F, [3] = 0xFF},
            [2] = {[0] = 0xCF, [1] = 0xDF, [3] = 0xFF},
            [4] = {[0] = 0xF3, [1] = 0xF7, [3] = 0xFF},
            [6] = {[0] = 0xFC, [1] = 0xFD, [3] = 0xFF}
        }
        local bits4Config = {[0] = 0x0F, [4] = 0xF0}
        for k in pairs(control) do
            if (commandSpec[k].bits == 8) then
                local tableOffset = commandSpec[k].offset / 8 + 1
                if (controlMapping[k]) then
                    controlTable[tableOffset] = controlMapping[k][control[k]]
                else
                    controlTable[tableOffset] = control[k]
                end
            elseif (commandSpec[k].bits == 16) then
                local tableOffset = commandSpec[k].offset / 8 + 1
                controlTable[tableOffset] = bit.band(control[k], 0xFF)
                controlTable[tableOffset + 1] = bit.rshift(
                                                    bit.band(control[k], 0xFF00),
                                                    8)
            elseif (commandSpec[k].bits == 2) then
                local tableOffset = math.floor(commandSpec[k].offset / 8) + 1
                controlTable[tableOffset] =
                    bit.band(controlTable[tableOffset],
                             bits2Config[commandSpec[k].offset % 8][control[k]])
            elseif (commandSpec[k].bits == 4) then
                local tableOffset = math.floor(commandSpec[k].offset / 8) + 1
                controlTable[tableOffset] =
                    bit.band(controlTable[tableOffset],
                             bit.bor(bits4Config[commandSpec[k].offset % 8],
                                     bit.lshift(control[k],
                                                4 - commandSpec[k].offset % 8)))
            end
        end
        controlTable[#controlTable] = checkSum(controlTable);
        tmpTable = controlTable
    elseif (query) then
        tmpTable = queryTable
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
    local binData = string.lower(json["msg"]["data"])
    local reportType = string.sub(binData, 19, 22)
    local byteData = string2table(binData)
    local dataTable = {}
    if (reportType == '0404' or reportType == '0303' or reportType == '0202') then
        for k, v in pairs(byteData) do
            if (reportMapping[k] and reportMapping[k]["value"]) then
                dataTable[reportMapping[k]["name"]] =
                    reportMapping[k]["value"][v]
            elseif (reportMapping[k] and reportMapping[k]["length"] == 2) then
                dataTable[reportMapping[k]["name"]] =
                    tonumber(string.format("%d",
                                           "0x" ..
                                               string.format("%02x",
                                                             byteData[k + 1]) ..
                                               string.format("%02x", byteData[k])))
            elseif (reportMapping[k] and reportMapping[k]["name"]) then
                dataTable[reportMapping[k]["name"]] = v
            elseif (reportMapping[k]) then
                local bitsTable = reportMapping[k]
                for key in pairs(bitsTable) do
                    dataTable[bitsTable[key]["name"]] =
                        bit.rshift(bit.band(v, key), bitsTable[key]["rshift"])
                end
            end
        end
        dataTable["version"] = version
        local result = {}
        result["status"] = dataTable
        return encodeTableToJson(result)
    end
end
