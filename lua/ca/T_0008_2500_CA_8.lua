local JSON = require "cjson"
local KEY_VERSION = "version"
local KEY_FUNCTION_TYPE = "function_type"
local KEY_CHILLED_CONST = "chilled_const"
local KEY_CHILLED_TEMP = "chilled_temp"
local KEY_POWER_SAVING_MODE = "power_saving_mode"
local KEY_COOLING = "cooling"
local KEY_CHILLING_ROOM_TEMP = "chilling_room_temp"
local KEY_FREEZING_ROOM_TEMP = "freezing_room_temp"
local KEY_ICE_MAKING = "ice_making"
local KEY_ICE_MAKING_STATUS = "ice_making_status"
local KEY_VEGETABLE_STERILIZATION = "vegetable_sterilization"
local KEY_ICE_TRAY_CLEANING = "ice_tray_cleaning"
local KEY_MASK_VEGETABLE_STERILIZATION = "mask_vegetable_sterilization"
local KEY_MASK_ICE_TRAY_CLEANING = "mask_ice_tray_cleaning"
local KEY_DEFROST_STATUS_MOISTURE = "defrost_status_moisture"
local KEY_DEFROST_STATUS_PRECOOL = "defrost_status_precool"
local KEY_DEFROST_STATUS_DEFROST = "defrost_status_defrost"
local KEY_INSTANTANEOUS_POWER = "instantaneous_power"
local KEY_DAILY_ENERGY = "daily_energy"
local KEY_COMPLETION_NOTICE_ONE = "completion_notice_one"
local KEY_ERROR_CODE = "error_code"
local KEY_OUT_ROOM_TEMP = "out_room_temp"
local KEY_TIMER = "timer"
local KEY_NIGHT_MODE = "night_mode"
local KEY_AUTO_DOOR_LEFT = "auto_door_left"
local KEY_AUTO_DOOR_RIGHT = "auto_door_right"
local KEY_LIGHT_BLUE_LED = "light_blue_led"
local KEY_MASK_NIGHT_MODE = "mask_night_mode"
local KEY_MASK_AUTO_DOOR_LEFT = "mask_auto_door_left"
local KEY_MASK_AUTO_DOOR_RIGHT = "mask_auto_door_right"
local KEY_MASK_LIGHT_BLUE_LED = "mask_light_blue_led"
local KEY_CEILING_LIGHT_NORMAL = "ceiling_light_normal"
local KEY_DOOR_LIGHT_NORMAL = "door_light_normal"
local KEY_CEILING_LIGHT_NIGHT = "ceiling_light_night"
local KEY_DOOR_LIGHT_NIGHT = "door_light_night"
local KEY_NIGHT_START_MIN = "night_start_min"
local KEY_NIGHT_START_HOUR = "night_start_hour"
local KEY_NIGHT_END_MIN = "night_end_min"
local KEY_NIGHT_END_HOUR = "night_end_hour"
local KEY_DOOR_LEFT_FOR_OPEN = "door_left_for_open"
local KEY_DOOR_LEFT_FOR_PRESSURE_HIGH = "door_left_for_pressure_high"
local KEY_DOOR_LEFT_FOR_PRESSURE_LOW = "door_left_for_pressure_low"
local KEY_DOOR_RIGHT_FOR_OPEN = "door_right_for_open"
local KEY_DOOR_RIGHT_FOR_PRESSURE_HIGH = "door_right_for_pressure_high"
local KEY_DOOR_RIGHT_FOR_PRESSURE_LOW = "door_right_for_pressure_low"
local KEY_CHILLED_LIGHT_NORMAL = "chilled_light_normal"
local KEY_VEGE_LIGHT_NORMAL = "vege_light_normal"
local KEY_CHILLED_LIGHT_NIGHT = "chilled_light_night"
local KEY_VEGE_LIGHT_NIGHT = "vege_light_night"
local KEY_WEEKLY_REMINDER = "weekly_reminder"
local KEY_WEEKLY_REMINDER_MIN = "weekly_reminder_min"
local KEY_WEEKLY_REMINDER_HOUR = "weekly_reminder_hour"
local KEY_SUNDAY_1 = "sunday_1"
local KEY_MONDAY_1 = "monday_1"
local KEY_TUESDAY_1 = "tuesday_1"
local KEY_WEDNESDAY_1 = "wednesday_1"
local KEY_THURSDAY_1 = "thursday_1"
local KEY_FRIDAY_1 = "friday_1"
local KEY_SATURDAY_1 = "saturday_1"
local KEY_SUNDAY_2 = "sunday_2"
local KEY_MONDAY_2 = "monday_2"
local KEY_TUESDAY_2 = "tuesday_2"
local KEY_WEDNESDAY_2 = "wednesday_2"
local KEY_THURSDAY_2 = "thursday_2"
local KEY_FRIDAY_2 = "friday_2"
local KEY_SATURDAY_2 = "saturday_2"
local KEY_INGREDIENT_EXPIRATION = "ingredient_expiration"
local KEY_CARE = "care"
local KEY_CLASSIFICATION = "classification"
local BYTE_PROTOCOL_LENGTH = 0x10
local dataType = 0x00
local propertyTable = {}
local function initializeData()
    propertyTable["chilledConst"] = 0
    propertyTable["chilledTemp"] = 0
    propertyTable["powerSavingMode"] = 0
    propertyTable["cooling"] = 0
    propertyTable["chillingRoomTemp"] = 0
    propertyTable["freezingRoomTemp"] = 0
    propertyTable["iceMaking"] = 0
    propertyTable["iceMakingStatus"] = 0
    propertyTable["vegetableSterilization"] = 0
    propertyTable["iceTrayCleaning"] = 0
    propertyTable["defrostStatus"] = 0
    propertyTable["chillingDoorStatus"] = 0
    propertyTable["freezingDoorStatus"] = 0
    propertyTable["iceDoorStatus"] = 0
    propertyTable["vegetableDoorStatus"] = 0
    propertyTable["freezingUpperDoorStatus"] = 0
    propertyTable["instantaneousPower"] = 0
    propertyTable["dailyEnergy"] = 0
    propertyTable["completionNoticeOne"] = 0
    propertyTable["notice"] = 0
    propertyTable["errorCode"] = 0
    propertyTable["functionType"] = 0
    propertyTable["errorMin"] = 0
    propertyTable["errorHour"] = 0
    propertyTable["errorDay"] = 0
    propertyTable["errorMonth"] = 0
    propertyTable["errorTimes"] = 0
    propertyTable["firmwareVersion"] = ""
    propertyTable["firmwareLog"] = ""
    propertyTable["freezingUpStatus"] = 0
    propertyTable["freezingDownStatus"] = 0
    propertyTable["chillingRoomTempThan12"] = 0
    propertyTable["freezingRoomTempThan10"] = 0
    propertyTable["has_data_one_hour"] = 0
    propertyTable["has_data_two_hours"] = 0
    propertyTable["status_current"] = 0
    propertyTable["status_one_hour"] = 0
    propertyTable["status_two_hours"] = 0
    propertyTable["r_avarage"] = 0
    propertyTable["r_avarage_one_hour"] = 0
    propertyTable["r_avarage_two_hours"] = 0
    propertyTable["f_avarage"] = 0
    propertyTable["f_avarage_one_hour"] = 0
    propertyTable["f_avarage_two_hours"] = 0
    propertyTable["pulldown_current"] = 0
    propertyTable["pulldown_one_hour"] = 0
    propertyTable["pulldown_two_hours"] = 0
    propertyTable["defrost_current"] = 0
    propertyTable["defrost_one_hour"] = 0
    propertyTable["defrost_two_hours"] = 0
    propertyTable["auto_status_set"] = {}
    propertyTable["query_cycle"] = 0
    propertyTable["nightMode"] = 0
    propertyTable["autoDoorLeft"] = 0
    propertyTable["autoDoorRight"] = 0
    propertyTable["lightBlueLed"] = 0
    propertyTable["maskNightMode"] = 0
    propertyTable["maskAutoDoorLeft"] = 0
    propertyTable["maskAutoDoorRight"] = 0
    propertyTable["maskLightBlueLed"] = 0
    propertyTable["ceilingLightNormal"] = 0
    propertyTable["doorLightNormal"] = 0
    propertyTable["chilledLightNormal"] = 0
    propertyTable["vegeLightNormal"] = 0
    propertyTable["ceilingLightNight"] = 0
    propertyTable["doorLightNight"] = 0
    propertyTable["chilledLightNight"] = 0
    propertyTable["vegeLightNight"] = 0
    propertyTable["nightStartMin"] = 0
    propertyTable["nightStartHour"] = 0
    propertyTable["nightEndMin"] = 0
    propertyTable["nightEndHour"] = 0
    propertyTable["doorLeftForOpen"] = 0
    propertyTable["doorLeftForPressureHigh"] = 0
    propertyTable["doorLeftForPressureLow"] = 0
    propertyTable["doorRightForOpen"] = 0
    propertyTable["doorRightForPressureHigh"] = 0
    propertyTable["doorRightForPressureLow"] = 0
    propertyTable["weeklyReminder"] = 0
    propertyTable["weeklyReminderMin"] = 0
    propertyTable["weeklyReminderHour"] = 0
    propertyTable["sunday_1"] = 0
    propertyTable["monday_1"] = 0
    propertyTable["tuesday_1"] = 0
    propertyTable["wednesday_1"] = 0
    propertyTable["thursday_1"] = 0
    propertyTable["friday_1"] = 0
    propertyTable["saturday_1"] = 0
    propertyTable["sunday_2"] = 0
    propertyTable["monday_2"] = 0
    propertyTable["tuesday_2"] = 0
    propertyTable["wednesday_2"] = 0
    propertyTable["thursday_2"] = 0
    propertyTable["friday_2"] = 0
    propertyTable["saturday_2"] = 0
    propertyTable["ingredientExpiration"] = 0
    propertyTable["care"] = 0xFE
    propertyTable["classification"] = 0
end
local function buma(ym)
    if bit.band(ym, 0x8000) == 0x8000 then
        local tmp = bit.band(bit.bnot(ym) + 1, 0xffff)
        return -tmp
    else
        return ym
    end
end
local function crc16_ccitt(tmpbuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        local i = 0
        crc = bit.bxor(crc, bit.lshift(tmpbuf[si], 8))
        for i = 0, 7 do
            if bit.band(crc, 0x8000) == 0x8000 then
                crc = bit.bxor(bit.lshift(crc, 1), 0x1021)
            else
                crc = bit.lshift(crc, 1)
            end
        end
    end
    return crc
end
local function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do
        msgBytes[i - 1] = byteData[i]
    end
    local bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 2
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    return bodyBytes
end
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 2)
    local msgBytes = {}
    for i = 0, msgLength - 1 do
        msgBytes[i] = 0
    end
    msgBytes[0] = 0x55
    msgBytes[1] = 0xAA
    msgBytes[2] = 0xCC
    msgBytes[3] = 0x33
    local msgLen = msgLength - 4
    msgBytes[4] = bit.band(msgLen, 0xff)
    msgBytes[5] = bit.band(bit.rshift(msgLen, 8), 0xff)
    msgBytes[6] = 0x01
    msgBytes[7] = 0xCA
    msgBytes[14] = bit.band(type, 0xff)
    msgBytes[15] = bit.band(bit.rshift(type, 8), 0xff)
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    local crc16 = crc16_ccitt(msgBytes, 0, msgLength - 3)
    msgBytes[msgLength - 2] = bit.band(crc16, 0xff)
    msgBytes[msgLength - 1] = bit.band(bit.rshift(crc16, 8), 0xff)
    return msgBytes
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    resVal = 255 - resVal + 1
    return resVal
end
local crc8_854_table = {
    0,
    94,
    188,
    226,
    97,
    63,
    221,
    131,
    194,
    156,
    126,
    32,
    163,
    253,
    31,
    65,
    157,
    195,
    33,
    127,
    252,
    162,
    64,
    30,
    95,
    1,
    227,
    189,
    62,
    96,
    130,
    220,
    35,
    125,
    159,
    193,
    66,
    28,
    254,
    160,
    225,
    191,
    93,
    3,
    128,
    222,
    60,
    98,
    190,
    224,
    2,
    92,
    223,
    129,
    99,
    61,
    124,
    34,
    192,
    158,
    29,
    67,
    161,
    255,
    70,
    24,
    250,
    164,
    39,
    121,
    155,
    197,
    132,
    218,
    56,
    102,
    229,
    187,
    89,
    7,
    219,
    133,
    103,
    57,
    186,
    228,
    6,
    88,
    25,
    71,
    165,
    251,
    120,
    38,
    196,
    154,
    101,
    59,
    217,
    135,
    4,
    90,
    184,
    230,
    167,
    249,
    27,
    69,
    198,
    152,
    122,
    36,
    248,
    166,
    68,
    26,
    153,
    199,
    37,
    123,
    58,
    100,
    134,
    216,
    91,
    5,
    231,
    185,
    140,
    210,
    48,
    110,
    237,
    179,
    81,
    15,
    78,
    16,
    242,
    172,
    47,
    113,
    147,
    205,
    17,
    79,
    173,
    243,
    112,
    46,
    204,
    146,
    211,
    141,
    111,
    49,
    178,
    236,
    14,
    80,
    175,
    241,
    19,
    77,
    206,
    144,
    114,
    44,
    109,
    51,
    209,
    143,
    12,
    82,
    176,
    238,
    50,
    108,
    142,
    208,
    83,
    13,
    239,
    177,
    240,
    174,
    76,
    18,
    145,
    207,
    45,
    115,
    202,
    148,
    118,
    40,
    171,
    245,
    23,
    73,
    8,
    86,
    180,
    234,
    105,
    55,
    213,
    139,
    87,
    9,
    235,
    181,
    54,
    104,
    138,
    212,
    149,
    203,
    41,
    119,
    244,
    170,
    72,
    22,
    233,
    183,
    85,
    11,
    136,
    214,
    52,
    106,
    43,
    117,
    151,
    201,
    74,
    20,
    246,
    168,
    116,
    42,
    200,
    150,
    21,
    75,
    169,
    247,
    182,
    232,
    10,
    84,
    215,
    137,
    107,
    53,
}
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end
local function decodeJsonToTable(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end
local function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then JSON = require "cjson" end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
end
local function string2Int(data)
    if not data then data = tonumber "0" end
    data = tonumber(data)
    if data == nil then data = 0 end
    return data
end
local function int2String(data)
    if not data then data = tostring(0) end
    data = tostring(data)
    if data == nil then data = "0" end
    return data
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
local function string2hexstring(str)
    local ret = ""
    for i = 1, #str do
        ret = ret .. string.format("%02x", str:byte(i))
    end
    return ret
end
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do
        ret = ret .. string.char(cmd[i])
    end
    return ret
end
local function hexToSignedInt(msb, lsb)
    if not lsb then lsb = 0 end
    if not msb then msb = 0 end
    local num = bit.lshift(msb, 8) + lsb
    if bit.band(msb, 0x80) == 0x80 then num = -bit.bnot(bit.bor(num - 1, 0xffff0000)) end
    return num
end
local function onOffToInteger1byte(theStringOnOff)
    local value
    if theStringOnOff == "on" then
        value = 0x01
    elseif theStringOnOff == "off" then
        value = 0x00
    else
        value = 0xFF
    end
    return value
end
local function onOffToMaskInteger1byte(theStringOnOff)
    local value
    if theStringOnOff == "on" then
        value = 0x00
    elseif theStringOnOff == "off" then
        value = 0x00
    else
        value = 0x01
    end
    return value
end
local function stringToInteger1byte(theString)
    local value
    if theString ~= nil then
        value = string2Int(theString)
    else
        value = 0xFF
    end
    return value
end
local function integerToOnOff(theInteger)
    local string
    if theInteger == 0x01 then
        string = "on"
    else
        string = "off"
    end
    return string
end
local function dedicatedToCare(theCare)
    local value
    if theCare ~= nil then
        value = theCare
    else
        value = 0xFE
    end
    return value
end
local function luaTableToPropertyTableForFunctionTypeCustomSetting(thePropertyTable, theLuaTable)
    thePropertyTable["nightMode"] = onOffToInteger1byte(theLuaTable[KEY_NIGHT_MODE])
    thePropertyTable["autoDoorLeft"] = onOffToInteger1byte(theLuaTable[KEY_AUTO_DOOR_LEFT])
    thePropertyTable["autoDoorRight"] = onOffToInteger1byte(theLuaTable[KEY_AUTO_DOOR_RIGHT])
    thePropertyTable["lightBlueLed"] = onOffToInteger1byte(theLuaTable[KEY_LIGHT_BLUE_LED])
    thePropertyTable["maskNightMode"] = onOffToInteger1byte(theLuaTable[KEY_MASK_NIGHT_MODE])
    thePropertyTable["maskAutoDoorLeft"] = onOffToInteger1byte(theLuaTable[KEY_MASK_AUTO_DOOR_LEFT])
    thePropertyTable["maskAutoDoorRight"] = onOffToInteger1byte(theLuaTable[KEY_MASK_AUTO_DOOR_RIGHT])
    thePropertyTable["maskLightBlueLed"] = onOffToInteger1byte(theLuaTable[KEY_MASK_LIGHT_BLUE_LED])
    thePropertyTable["ceilingLightNormal"] = stringToInteger1byte(theLuaTable[KEY_CEILING_LIGHT_NORMAL])
    thePropertyTable["doorLightNormal"] = stringToInteger1byte(theLuaTable[KEY_DOOR_LIGHT_NORMAL])
    thePropertyTable["chilledLightNormal"] = stringToInteger1byte(theLuaTable[KEY_CHILLED_LIGHT_NORMAL])
    thePropertyTable["vegeLightNormal"] = stringToInteger1byte(theLuaTable[KEY_VEGE_LIGHT_NORMAL])
    thePropertyTable["ceilingLightNight"] = stringToInteger1byte(theLuaTable[KEY_CEILING_LIGHT_NIGHT])
    thePropertyTable["chilledLightNight"] = stringToInteger1byte(theLuaTable[KEY_CHILLED_LIGHT_NIGHT])
    thePropertyTable["vegeLightNight"] = stringToInteger1byte(theLuaTable[KEY_VEGE_LIGHT_NIGHT])
    thePropertyTable["doorLightNight"] = stringToInteger1byte(theLuaTable[KEY_DOOR_LIGHT_NIGHT])
    thePropertyTable["nightStartMin"] = stringToInteger1byte(theLuaTable[KEY_NIGHT_START_MIN])
    thePropertyTable["nightStartHour"] = stringToInteger1byte(theLuaTable[KEY_NIGHT_START_HOUR])
    thePropertyTable["nightEndMin"] = stringToInteger1byte(theLuaTable[KEY_NIGHT_END_MIN])
    thePropertyTable["nightEndHour"] = stringToInteger1byte(theLuaTable[KEY_NIGHT_END_HOUR])
    thePropertyTable["doorLeftForOpen"] = stringToInteger1byte(theLuaTable[KEY_DOOR_LEFT_FOR_OPEN])
    thePropertyTable["doorLeftForPressureHigh"] = stringToInteger1byte(theLuaTable[KEY_DOOR_LEFT_FOR_PRESSURE_HIGH])
    thePropertyTable["doorLeftForPressureLow"] = stringToInteger1byte(theLuaTable[KEY_DOOR_LEFT_FOR_PRESSURE_LOW])
    thePropertyTable["doorRightForOpen"] = stringToInteger1byte(theLuaTable[KEY_DOOR_RIGHT_FOR_OPEN])
    thePropertyTable["doorRightForPressureHigh"] = stringToInteger1byte(theLuaTable[KEY_DOOR_RIGHT_FOR_PRESSURE_HIGH])
    thePropertyTable["doorRightForPressureLow"] = stringToInteger1byte(theLuaTable[KEY_DOOR_RIGHT_FOR_PRESSURE_LOW])
end
local function luaTableToPropertyTableForFunctionTypeWeeklyReminder(thePropertyTable, theLuaTable)
    thePropertyTable["weeklyReminder"] = onOffToInteger1byte(theLuaTable[KEY_WEEKLY_REMINDER])
    thePropertyTable["weeklyReminderMin"] = stringToInteger1byte(theLuaTable[KEY_WEEKLY_REMINDER_MIN])
    thePropertyTable["weeklyReminderHour"] = stringToInteger1byte(theLuaTable[KEY_WEEKLY_REMINDER_HOUR])
    thePropertyTable["sunday_1"] = stringToInteger1byte(theLuaTable[KEY_SUNDAY_1])
    thePropertyTable["monday_1"] = stringToInteger1byte(theLuaTable[KEY_MONDAY_1])
    thePropertyTable["tuesday_1"] = stringToInteger1byte(theLuaTable[KEY_TUESDAY_1])
    thePropertyTable["wednesday_1"] = stringToInteger1byte(theLuaTable[KEY_WEDNESDAY_1])
    thePropertyTable["thursday_1"] = stringToInteger1byte(theLuaTable[KEY_THURSDAY_1])
    thePropertyTable["friday_1"] = stringToInteger1byte(theLuaTable[KEY_FRIDAY_1])
    thePropertyTable["saturday_1"] = stringToInteger1byte(theLuaTable[KEY_SATURDAY_1])
    thePropertyTable["sunday_2"] = stringToInteger1byte(theLuaTable[KEY_SUNDAY_2])
    thePropertyTable["monday_2"] = stringToInteger1byte(theLuaTable[KEY_MONDAY_2])
    thePropertyTable["tuesday_2"] = stringToInteger1byte(theLuaTable[KEY_TUESDAY_2])
    thePropertyTable["wednesday_2"] = stringToInteger1byte(theLuaTable[KEY_WEDNESDAY_2])
    thePropertyTable["thursday_2"] = stringToInteger1byte(theLuaTable[KEY_THURSDAY_2])
    thePropertyTable["friday_2"] = stringToInteger1byte(theLuaTable[KEY_FRIDAY_2])
    thePropertyTable["saturday_2"] = stringToInteger1byte(theLuaTable[KEY_SATURDAY_2])
end
local function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_FUNCTION_TYPE] == "base" then
        propertyTable["functionType"] = 0x00
    elseif luaTable[KEY_FUNCTION_TYPE] == "auto_power_saving_set" then
        propertyTable["functionType"] = 0x09
    elseif luaTable[KEY_FUNCTION_TYPE] == "general_notice" then
        propertyTable["functionType"] = 0x23
    elseif luaTable[KEY_FUNCTION_TYPE] == "washing_machine_notice" then
        propertyTable["functionType"] = 0x30
    elseif luaTable[KEY_FUNCTION_TYPE] == "microwave_oven_notice" then
        propertyTable["functionType"] = 0x31
    elseif luaTable[KEY_FUNCTION_TYPE] == "rice_cooker_notice" then
        propertyTable["functionType"] = 0x32
    end
    if luaTable[KEY_CHILLED_CONST] == "normal" then
        propertyTable["chilledConst"] = 0x00
    elseif luaTable[KEY_CHILLED_CONST] == "power_low_temp" then
        propertyTable["chilledConst"] = 0x01
    elseif luaTable[KEY_CHILLED_CONST] == "deli_chilled" then
        propertyTable["chilledConst"] = 0x02
    else
        propertyTable["chilledConst"] = 0x0F
    end
    if luaTable[KEY_CHILLED_TEMP] == "not_set" then
        propertyTable["chilledTemp"] = 0x00
    elseif luaTable[KEY_CHILLED_TEMP] == "chilled" then
        propertyTable["chilledTemp"] = 0x01
    elseif luaTable[KEY_CHILLED_TEMP] == "thawing" then
        propertyTable["chilledTemp"] = 0x02
    else
        propertyTable["chilledTemp"] = 0xF0
    end
    if luaTable[KEY_POWER_SAVING_MODE] == "normal" then
        propertyTable["powerSavingMode"] = 0x00
    elseif luaTable[KEY_POWER_SAVING_MODE] == "power_saving_auto" then
        propertyTable["powerSavingMode"] = 0x01
    elseif luaTable[KEY_POWER_SAVING_MODE] == "power_saving_auto_plus" then
        propertyTable["powerSavingMode"] = 0x02
    elseif luaTable[KEY_POWER_SAVING_MODE] == "power_saving" then
        propertyTable["powerSavingMode"] = 0x03
    elseif luaTable[KEY_POWER_SAVING_MODE] == "low_power_cooling" then
        propertyTable["powerSavingMode"] = 0x04
    else
        propertyTable["powerSavingMode"] = 0xFF
    end
    if luaTable[KEY_COOLING] == "normal" then
        propertyTable["cooling"] = 0x00
    elseif luaTable[KEY_COOLING] == "quick_freezing" then
        propertyTable["cooling"] = 0x01
    elseif luaTable[KEY_COOLING] == "rough_heat_removal" then
        propertyTable["cooling"] = 0x06
    elseif luaTable[KEY_COOLING] == "cool_cooking" then
        propertyTable["cooling"] = 0x07
    elseif luaTable[KEY_COOLING] == "timer" then
        propertyTable["cooling"] = 0x08
    elseif luaTable[KEY_COOLING] == "frozen_rice" then
        propertyTable["cooling"] = 0x09
    else
        propertyTable["cooling"] = 0xFF
    end
    propertyTable["chillingRoomTemp"] = stringToInteger1byte(luaTable[KEY_CHILLING_ROOM_TEMP])
    propertyTable["freezingRoomTemp"] = stringToInteger1byte(luaTable[KEY_FREEZING_ROOM_TEMP])
    if luaTable[KEY_ICE_MAKING] == "normal" then
        propertyTable["iceMaking"] = 0x00
    elseif luaTable[KEY_ICE_MAKING] == "quick" then
        propertyTable["iceMaking"] = 0x01
    elseif luaTable[KEY_ICE_MAKING] == "off" then
        propertyTable["iceMaking"] = 0x02
    else
        propertyTable["iceMaking"] = 0x0f
    end
    propertyTable["vegetableSterilization"] = onOffToInteger1byte(luaTable[KEY_VEGETABLE_STERILIZATION])
    propertyTable["iceTrayCleaning"] = onOffToInteger1byte(luaTable[KEY_ICE_TRAY_CLEANING])
    propertyTable["maskVegetableSterilization"] = onOffToMaskInteger1byte(luaTable[KEY_VEGETABLE_STERILIZATION])
    propertyTable["maskIceTrayCleaning"] = onOffToMaskInteger1byte(luaTable[KEY_ICE_TRAY_CLEANING])
    if luaTable[KEY_DEFROST_STATUS_MOISTURE] == "on" then
        propertyTable["defrostStatus"] = bit.band(propertyTable["defrostStatus"], 0x01)
    else
        propertyTable["defrostStatus"] = bit.band(propertyTable["defrostStatus"], 0xFE)
    end
    if luaTable[KEY_DEFROST_STATUS_PRECOOL] == "on" then
        propertyTable["defrostStatus"] = bit.band(propertyTable["defrostStatus"], 0x02)
    else
        propertyTable["defrostStatus"] = bit.band(propertyTable["defrostStatus"], 0xFD)
    end
    if luaTable[KEY_DEFROST_STATUS_DEFROST] == "on" then
        propertyTable["defrostStatus"] = bit.band(propertyTable["defrostStatus"], 0x04)
    else
        propertyTable["defrostStatus"] = bit.band(propertyTable["defrostStatus"], 0xFB)
    end
    if luaTable["chilling_door_status"] == "on" then
        propertyTable["chillingDoorStatus"] = 0x01
    else
        propertyTable["chillingDoorStatus"] = 0x00
    end
    if luaTable["freezing_door_status"] == "on" then
        propertyTable["freezingDoorStatus"] = 0x01
    else
        propertyTable["freezingDoorStatus"] = 0x00
    end
    if luaTable["ice_door_status"] == "on" then
        propertyTable["iceDoorStatus"] = 0x01
    else
        propertyTable["iceDoorStatus"] = 0x00
    end
    if luaTable["vegetable_door_status"] == "on" then
        propertyTable["vegetableDoorStatus"] = 0x01
    else
        propertyTable["vegetableDoorStatus"] = 0x00
    end
    if luaTable["freezing_upper_door_status"] == "on" then
        propertyTable["freezingUpperDoorStatus"] = 0x01
    else
        propertyTable["freezingUpperDoorStatus"] = 0x00
    end
    if luaTable[KEY_TIMER] ~= nil then
        propertyTable["timer"] = string2Int(luaTable[KEY_TIMER])
    else
        propertyTable["timer"] = nil
    end
    if luaTable["auto_status_set"] ~= nil then
        for i = 1, 168 do
            if luaTable["auto_status_set"][i] == "normal" then
                propertyTable["auto_status_set"][i] = 0x00
            elseif luaTable["auto_status_set"][i] == "eco_auto" then
                propertyTable["auto_status_set"][i] = 0x01
            elseif luaTable["auto_status_set"][i] == "precool" then
                propertyTable["auto_status_set"][i] = 0x02
            else
                propertyTable["auto_status_set"][i] = 0xFF
            end
        end
    end
    luaTableToPropertyTableForFunctionTypeCustomSetting(propertyTable, luaTable)
    luaTableToPropertyTableForFunctionTypeWeeklyReminder(propertyTable, luaTable)
    propertyTable["ingredientExpiration"] = onOffToInteger1byte(luaTable[KEY_INGREDIENT_EXPIRATION])
    propertyTable["care"] = dedicatedToCare(luaTable[KEY_CARE])
    if luaTable[KEY_CLASSIFICATION] == "completion" then
        propertyTable["classification"] = 0x00
    elseif luaTable[KEY_CLASSIFICATION] == "notification" then
        propertyTable["classification"] = 0x01
    elseif luaTable[KEY_CLASSIFICATION] == "minor_failure" then
        propertyTable["classification"] = 0x02
    elseif luaTable[KEY_CLASSIFICATION] == "severe_failure" then
        propertyTable["classification"] = 0x03
    else
        propertyTable["classification"] = 0xFF
    end
    if luaTable[KEY_ERROR_CODE] ~= nil then propertyTable["errorCode"] = string2Int(luaTable[KEY_ERROR_CODE]) end
    propertyTable["nightMode"] = onOffToInteger1byte(luaTable[KEY_NIGHT_MODE])
    propertyTable["autoDoorLeft"] = onOffToInteger1byte(luaTable[KEY_AUTO_DOOR_LEFT])
    propertyTable["autoDoorRight"] = onOffToInteger1byte(luaTable[KEY_AUTO_DOOR_RIGHT])
    propertyTable["lightBlueLed"] = onOffToInteger1byte(luaTable[KEY_LIGHT_BLUE_LED])
    propertyTable["maskNightMode"] = onOffToMaskInteger1byte(luaTable[KEY_NIGHT_MODE])
    propertyTable["maskAutoDoorLeft"] = onOffToMaskInteger1byte(luaTable[KEY_AUTO_DOOR_LEFT])
    propertyTable["maskAutoDoorRight"] = onOffToMaskInteger1byte(luaTable[KEY_AUTO_DOOR_RIGHT])
    propertyTable["maskLightBlueLed"] = onOffToMaskInteger1byte(luaTable[KEY_LIGHT_BLUE_LED])
end
local function messageByteToPropertyTableForFunctionTypeBase(thePropertyTable, theMessageBytes)
    thePropertyTable["functionType"] = 0x00
    thePropertyTable["chilledConst"] = bit.band(theMessageBytes[1], 0x0f)
    thePropertyTable["chilledTemp"] = bit.rshift(bit.band(theMessageBytes[1], 0xf0), 4)
    thePropertyTable["powerSavingMode"] = theMessageBytes[3]
    thePropertyTable["cooling"] = theMessageBytes[4]
    thePropertyTable["chillingRoomTemp"] = theMessageBytes[5]
    thePropertyTable["freezingRoomTemp"] = theMessageBytes[6]
    thePropertyTable["iceMaking"] = bit.band(theMessageBytes[7], 0x0f)
    thePropertyTable["iceMakingStatus"] = bit.rshift(bit.band(theMessageBytes[7], 0xf0), 4)
    thePropertyTable["vegetableSterilization"] = bit.band(theMessageBytes[8], 0x01)
    thePropertyTable["iceTrayCleaning"] = bit.rshift(bit.band(theMessageBytes[8], 0x02), 1)
    thePropertyTable["maskVegetableSterilization"] = bit.rshift(bit.band(theMessageBytes[8], 0x10), 4)
    thePropertyTable["maskIceTrayCleaning"] = bit.rshift(bit.band(theMessageBytes[8], 0x20), 5)
    thePropertyTable["defrostStatus"] = theMessageBytes[10]
    thePropertyTable["chillingDoorStatus"] = bit.band(theMessageBytes[11], 0x01)
    thePropertyTable["freezingDoorStatus"] = bit.rshift(bit.band(theMessageBytes[11], 0x02), 1)
    thePropertyTable["iceDoorStatus"] = bit.rshift(bit.band(theMessageBytes[11], 0x04), 2)
    thePropertyTable["vegetableDoorStatus"] = bit.rshift(bit.band(theMessageBytes[11], 0x08), 3)
    thePropertyTable["freezingUpperDoorStatus"] = bit.rshift(bit.band(theMessageBytes[11], 0x10), 4)
    thePropertyTable["instantaneousPower"] = bit.lshift(theMessageBytes[12], 8) + theMessageBytes[13]
    thePropertyTable["dailyEnergy"] = bit.lshift(theMessageBytes[14], 8) + theMessageBytes[15]
    if (theMessageBytes[16] ~= nil) and (theMessageBytes[17] ~= nil) then
        if (theMessageBytes[16] ~= 0xFF) or (theMessageBytes[17] ~= 0xFF) then
            thePropertyTable["errorCode"] = bit.lshift(theMessageBytes[17], 8) + theMessageBytes[16]
        end
    end
    if (theMessageBytes[18] ~= nil) and (theMessageBytes[19] ~= nil) then
        thePropertyTable["outRoomTemp"] = bit.lshift(theMessageBytes[19], 8) + theMessageBytes[18]
    else
        thePropertyTable["outRoomTemp"] = nil
    end
    if theMessageBytes[20] ~= nil then
        thePropertyTable["timer"] = theMessageBytes[20]
    else
        thePropertyTable["timer"] = nil
    end
    thePropertyTable["nightMode"] = bit.band(theMessageBytes[21], 0x01)
    thePropertyTable["autoDoorLeft"] = bit.rshift(bit.band(theMessageBytes[21], 0x02), 1)
    thePropertyTable["autoDoorRight"] = bit.rshift(bit.band(theMessageBytes[21], 0x04), 2)
    thePropertyTable["lightBlueLed"] = bit.rshift(bit.band(theMessageBytes[21], 0x08), 3)
    thePropertyTable["maskNightMode"] = bit.rshift(bit.band(theMessageBytes[21], 0x10), 4)
    thePropertyTable["maskAutoDoorLeft"] = bit.rshift(bit.band(theMessageBytes[21], 0x20), 5)
    thePropertyTable["maskAutoDoorRight"] = bit.rshift(bit.band(theMessageBytes[21], 0x40), 6)
    thePropertyTable["maskLightBlueLed"] = bit.rshift(bit.band(theMessageBytes[21], 0x80), 7)
    thePropertyTable["ceilingLightNormal"] = theMessageBytes[22]
    thePropertyTable["doorLightNormal"] = theMessageBytes[23]
    thePropertyTable["chilledLightNormal"] = theMessageBytes[24]
    thePropertyTable["vegeLightNormal"] = theMessageBytes[25]
    thePropertyTable["ceilingLightNight"] = theMessageBytes[26]
    thePropertyTable["doorLightNight"] = theMessageBytes[27]
    thePropertyTable["chilledLightNight"] = theMessageBytes[28]
    thePropertyTable["vegeLightNight"] = theMessageBytes[29]
    thePropertyTable["nightStartMin"] = theMessageBytes[30]
    thePropertyTable["nightStartHour"] = theMessageBytes[31]
    thePropertyTable["nightEndMin"] = theMessageBytes[32]
    thePropertyTable["nightEndHour"] = theMessageBytes[33]
    thePropertyTable["doorLeftForOpen"] = theMessageBytes[34]
    thePropertyTable["doorLeftForPressureHigh"] = theMessageBytes[35]
    thePropertyTable["doorLeftForPressureLow"] = theMessageBytes[36]
    thePropertyTable["doorRightForOpen"] = theMessageBytes[37]
    thePropertyTable["doorRightForPressureHigh"] = theMessageBytes[38]
    thePropertyTable["doorRightForPressureLow"] = theMessageBytes[39]
    thePropertyTable["weeklyReminder"] = theMessageBytes[40]
    thePropertyTable["weeklyReminderMin"] = theMessageBytes[41]
    thePropertyTable["weeklyReminderHour"] = theMessageBytes[42]
    thePropertyTable["sunday_1"] = theMessageBytes[43]
    thePropertyTable["monday_1"] = theMessageBytes[44]
    thePropertyTable["tuesday_1"] = theMessageBytes[45]
    thePropertyTable["wednesday_1"] = theMessageBytes[46]
    thePropertyTable["thursday_1"] = theMessageBytes[47]
    thePropertyTable["friday_1"] = theMessageBytes[48]
    thePropertyTable["saturday_1"] = theMessageBytes[49]
    thePropertyTable["sunday_2"] = theMessageBytes[50]
    thePropertyTable["monday_2"] = theMessageBytes[51]
    thePropertyTable["tuesday_2"] = theMessageBytes[52]
    thePropertyTable["wednesday_2"] = theMessageBytes[53]
    thePropertyTable["thursday_2"] = theMessageBytes[54]
    thePropertyTable["friday_2"] = theMessageBytes[55]
    thePropertyTable["saturday_2"] = theMessageBytes[56]
end
local function messageByteToPropertyTableForFunctionTypeDoorInfo(thePropertyTable, theMessageBytes)
    thePropertyTable["functionType"] = 0x22
    thePropertyTable["chillingDoorStatus"] = bit.band(theMessageBytes[1], 0x01)
    thePropertyTable["vegetableDoorStatus"] = bit.rshift(bit.band(theMessageBytes[1], 0x02), 1)
    thePropertyTable["iceDoorStatus"] = bit.rshift(bit.band(theMessageBytes[1], 0x04), 2)
    thePropertyTable["freezingUpStatus"] = bit.rshift(bit.band(theMessageBytes[1], 0x08), 3)
    thePropertyTable["freezingDownStatus"] = bit.rshift(bit.band(theMessageBytes[1], 0x10), 4)
    thePropertyTable["chillingRoomTempThan12"] = bit.band(theMessageBytes[2], 0x01)
    thePropertyTable["freezingRoomTempThan10"] = bit.rshift(bit.band(theMessageBytes[2], 0x02), 1)
end
local function messageByteToPropertyTableForFunctionTypeException(thePropertyTable, theMessageBytes, theCategory)
    thePropertyTable["functionType"] = theCategory
    thePropertyTable["errorCode"] = theMessageBytes[2] * 256 + theMessageBytes[1]
    thePropertyTable["errorMin"] = theMessageBytes[3]
    thePropertyTable["errorHour"] = theMessageBytes[4]
    thePropertyTable["errorDay"] = theMessageBytes[5]
    thePropertyTable["errorMonth"] = theMessageBytes[6]
    thePropertyTable["errorTimes"] = bit.lshift(theMessageBytes[8], 8) + theMessageBytes[7]
    local fv = {}
    for i = 1, 7 do
        fv[i] = theMessageBytes[8 + i]
    end
    local fvstring = table2string(fv)
    local fvhexstring = string2hexstring(fvstring)
    thePropertyTable["firmwareVersion"] = fvhexstring
    local fl = {}
    for i = 1, 512 do
        fl[i] = theMessageBytes[15 + i]
    end
    local flstring = table2string(fl)
    local flhexstring = string2hexstring(flstring)
    thePropertyTable["firmwareLog"] = flhexstring
end
local function updateGlobalPropertyValueByByte(messageBytes)
    if #messageBytes == 0 then return nil end
    if dataType == 0x02 then
        if messageBytes[0] == 0x00 then
            messageByteToPropertyTableForFunctionTypeBase(propertyTable, messageBytes)
        elseif messageBytes[0] == 0x09 then
        elseif messageBytes[0] == 0x23 then
        elseif messageBytes[0] == 0x30 then
        elseif messageBytes[0] == 0x31 then
        elseif messageBytes[0] == 0x32 then
        end
    elseif dataType == 0x03 then
        if messageBytes[0] == 0x00 then
            messageByteToPropertyTableForFunctionTypeBase(propertyTable, messageBytes)
        elseif messageBytes[0] == 0xFE then
            messageByteToPropertyTableForFunctionTypeException(propertyTable, messageBytes, 0xFE)
        elseif messageBytes[0] == 0x21 then
            messageByteToPropertyTableForFunctionTypeException(propertyTable, messageBytes, 0x21)
        elseif messageBytes[0] == 0x22 then
            messageByteToPropertyTableForFunctionTypeDoorInfo(propertyTable, messageBytes)
        end
    elseif dataType == 0x04 then
        if messageBytes[0] == 0x00 then
            messageByteToPropertyTableForFunctionTypeBase(propertyTable, messageBytes)
        elseif messageBytes[0] == 0x05 then
            propertyTable["functionType"] = 0x05
            propertyTable["has_data_one_hour"] = bit.band(messageBytes[1], 0x01)
            propertyTable["has_data_two_hours"] = bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            propertyTable["status_current"] = messageBytes[2]
            propertyTable["status_one_hour"] = messageBytes[3]
            propertyTable["status_two_hours"] = messageBytes[4]
            propertyTable["r_avarage"] = hexToSignedInt(messageBytes[6], messageBytes[5])
            propertyTable["r_avarage_one_hour"] = hexToSignedInt(messageBytes[8], messageBytes[7])
            propertyTable["r_avarage_two_hours"] = hexToSignedInt(messageBytes[10], messageBytes[9])
            propertyTable["f_avarage"] = hexToSignedInt(messageBytes[12], messageBytes[11])
            propertyTable["f_avarage_one_hour"] = hexToSignedInt(messageBytes[14], messageBytes[13])
            propertyTable["f_avarage_two_hours"] = hexToSignedInt(messageBytes[16], messageBytes[15])
            propertyTable["pulldown_current"] = bit.band(messageBytes[17], 0x01)
            propertyTable["pulldown_one_hour"] = bit.rshift(bit.band(messageBytes[17], 0x02), 1)
            propertyTable["pulldown_two_hours"] = bit.rshift(bit.band(messageBytes[17], 0x04), 2)
            propertyTable["defrost_current"] = bit.rshift(bit.band(messageBytes[17], 0x08), 3)
            propertyTable["defrost_one_hour"] = bit.rshift(bit.band(messageBytes[17], 0x10), 4)
            propertyTable["defrost_two_hours"] = bit.rshift(bit.band(messageBytes[17], 0x20), 5)
        elseif messageBytes[0] == 0x22 then
            messageByteToPropertyTableForFunctionTypeDoorInfo(propertyTable, messageBytes)
        end
    elseif dataType == 0x05 then
        if messageBytes[0] == 0x20 then
            propertyTable["functionType"] = 0x20
            propertyTable["completionNoticeOne"] = messageBytes[1]
            propertyTable["notice"] = messageBytes[2]
        elseif messageBytes[0] == 0x09 then
            propertyTable["functionType"] = 0x09
            propertyTable["query_cycle"] = bit.lshift(messageBytes[2], 8) + messageBytes[1]
        end
    elseif dataType == 0x0A then
        if messageBytes[0] == 0xFE then
            messageByteToPropertyTableForFunctionTypeException(propertyTable, messageBytes, 0xFE)
        elseif messageBytes[0] == 0x21 then
            messageByteToPropertyTableForFunctionTypeException(propertyTable, messageBytes, 0x21)
        end
    end
end
local function propertyTableToStreamsForCustom(streams)
    streams[KEY_NIGHT_MODE] = integerToOnOff(propertyTable["nightMode"])
    streams[KEY_AUTO_DOOR_LEFT] = integerToOnOff(propertyTable["autoDoorLeft"])
    streams[KEY_AUTO_DOOR_RIGHT] = integerToOnOff(propertyTable["autoDoorRight"])
    streams[KEY_LIGHT_BLUE_LED] = integerToOnOff(propertyTable["lightBlueLed"])
    if propertyTable["maskNightMode"] == 0x00 then
        streams[KEY_MASK_NIGHT_MODE] = "on"
    elseif propertyTable["maskNightMode"] == 0x01 then
        streams[KEY_MASK_NIGHT_MODE] = "off"
    end
    if propertyTable["maskAutoDoorLeft"] == 0x00 then
        streams[KEY_MASK_AUTO_DOOR_LEFT] = "on"
    elseif propertyTable["maskAutoDoorLeft"] == 0x01 then
        streams[KEY_MASK_AUTO_DOOR_LEFT] = "off"
    end
    if propertyTable["maskAutoDoorRight"] == 0x00 then
        streams[KEY_MASK_AUTO_DOOR_RIGHT] = "on"
    elseif propertyTable["maskAutoDoorRight"] == 0x01 then
        streams[KEY_MASK_AUTO_DOOR_RIGHT] = "off"
    end
    if propertyTable["maskLightBlueLed"] == 0x00 then
        streams[KEY_MASK_LIGHT_BLUE_LED] = "on"
    elseif propertyTable["maskLightBlueLed"] == 0x01 then
        streams[KEY_MASK_LIGHT_BLUE_LED] = "off"
    end
    streams[KEY_CEILING_LIGHT_NORMAL] = int2String(propertyTable["ceilingLightNormal"])
    streams[KEY_DOOR_LIGHT_NORMAL] = int2String(propertyTable["doorLightNormal"])
    streams[KEY_CHILLED_LIGHT_NORMAL] = int2String(propertyTable["chilledLightNormal"])
    streams[KEY_VEGE_LIGHT_NORMAL] = int2String(propertyTable["vegeLightNormal"])
    streams[KEY_CEILING_LIGHT_NIGHT] = int2String(propertyTable["ceilingLightNight"])
    streams[KEY_DOOR_LIGHT_NIGHT] = int2String(propertyTable["doorLightNight"])
    streams[KEY_CHILLED_LIGHT_NIGHT] = int2String(propertyTable["chilledLightNight"])
    streams[KEY_VEGE_LIGHT_NIGHT] = int2String(propertyTable["vegeLightNight"])
    streams[KEY_NIGHT_START_MIN] = int2String(propertyTable["nightStartMin"])
    streams[KEY_NIGHT_START_HOUR] = int2String(propertyTable["nightStartHour"])
    streams[KEY_NIGHT_END_MIN] = int2String(propertyTable["nightEndMin"])
    streams[KEY_NIGHT_END_HOUR] = int2String(propertyTable["nightEndHour"])
    streams[KEY_DOOR_LEFT_FOR_OPEN] = int2String(propertyTable["doorLeftForOpen"])
    streams[KEY_DOOR_LEFT_FOR_PRESSURE_HIGH] = int2String(propertyTable["doorLeftForPressureHigh"])
    streams[KEY_DOOR_LEFT_FOR_PRESSURE_LOW] = int2String(propertyTable["doorLeftForPressureLow"])
    streams[KEY_DOOR_RIGHT_FOR_OPEN] = int2String(propertyTable["doorRightForOpen"])
    streams[KEY_DOOR_RIGHT_FOR_PRESSURE_HIGH] = int2String(propertyTable["doorRightForPressureHigh"])
    streams[KEY_DOOR_RIGHT_FOR_PRESSURE_LOW] = int2String(propertyTable["doorRightForPressureLow"])
end
local function propertyTableToStreamsForWeekly(streams)
    streams[KEY_WEEKLY_REMINDER] = integerToOnOff(propertyTable["weeklyReminder"])
    streams[KEY_WEEKLY_REMINDER_MIN] = int2String(propertyTable["weeklyReminderMin"])
    streams[KEY_WEEKLY_REMINDER_HOUR] = int2String(propertyTable["weeklyReminderHour"])
    streams[KEY_SUNDAY_1] = int2String(propertyTable["sunday_1"])
    streams[KEY_MONDAY_1] = int2String(propertyTable["monday_1"])
    streams[KEY_TUESDAY_1] = int2String(propertyTable["tuesday_1"])
    streams[KEY_WEDNESDAY_1] = int2String(propertyTable["wednesday_1"])
    streams[KEY_THURSDAY_1] = int2String(propertyTable["thursday_1"])
    streams[KEY_FRIDAY_1] = int2String(propertyTable["friday_1"])
    streams[KEY_SATURDAY_1] = int2String(propertyTable["saturday_1"])
    streams[KEY_SUNDAY_2] = int2String(propertyTable["sunday_2"])
    streams[KEY_MONDAY_2] = int2String(propertyTable["monday_2"])
    streams[KEY_TUESDAY_2] = int2String(propertyTable["tuesday_2"])
    streams[KEY_WEDNESDAY_2] = int2String(propertyTable["wednesday_2"])
    streams[KEY_THURSDAY_2] = int2String(propertyTable["thursday_2"])
    streams[KEY_FRIDAY_2] = int2String(propertyTable["friday_2"])
    streams[KEY_SATURDAY_2] = int2String(propertyTable["saturday_2"])
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = "8"
    if propertyTable["functionType"] == 0x00 then
        streams[KEY_FUNCTION_TYPE] = "base"
        if propertyTable["chilledConst"] == 0x00 then
            streams[KEY_CHILLED_CONST] = "normal"
        elseif propertyTable["chilledConst"] == 0x01 then
            streams[KEY_CHILLED_CONST] = "power_low_temp"
        elseif propertyTable["chilledConst"] == 0x02 then
            streams[KEY_CHILLED_CONST] = "deli_chilled"
        else
            streams[KEY_CHILLED_CONST] = "invalid"
        end
        if propertyTable["chilledTemp"] == 0x00 then
            streams[KEY_CHILLED_TEMP] = "not_set"
        elseif propertyTable["chilledTemp"] == 0x01 then
            streams[KEY_CHILLED_TEMP] = "chilled"
        elseif propertyTable["chilledTemp"] == 0x02 then
            streams[KEY_CHILLED_TEMP] = "thawing"
        else
            streams[KEY_CHILLED_TEMP] = "invalid"
        end
        if propertyTable["powerSavingMode"] == 0x00 then
            streams[KEY_POWER_SAVING_MODE] = "normal"
        elseif propertyTable["powerSavingMode"] == 0x01 then
            streams[KEY_POWER_SAVING_MODE] = "power_saving_auto"
        elseif propertyTable["powerSavingMode"] == 0x02 then
            streams[KEY_POWER_SAVING_MODE] = "power_saving_auto_plus"
        elseif propertyTable["powerSavingMode"] == 0x03 then
            streams[KEY_POWER_SAVING_MODE] = "power_saving"
        elseif propertyTable["powerSavingMode"] == 0x04 then
            streams[KEY_POWER_SAVING_MODE] = "low_power_cooling"
        else
            streams[KEY_POWER_SAVING_MODE] = "invalid"
        end
        if propertyTable["cooling"] == 0x00 then
            streams[KEY_COOLING] = "normal"
        elseif propertyTable["cooling"] == 0x01 then
            streams[KEY_COOLING] = "quick_freezing"
        elseif propertyTable["cooling"] == 0x06 then
            streams[KEY_COOLING] = "rough_heat_removal"
        elseif propertyTable["cooling"] == 0x07 then
            streams[KEY_COOLING] = "cool_cooking"
        elseif propertyTable["cooling"] == 0x08 then
            streams[KEY_COOLING] = "timer"
        elseif propertyTable["cooling"] == 0x09 then
            streams[KEY_COOLING] = "frozen_rice"
        else
            streams[KEY_COOLING] = "invalid"
        end
        streams[KEY_CHILLING_ROOM_TEMP] = int2String(propertyTable["chillingRoomTemp"])
        streams[KEY_FREEZING_ROOM_TEMP] = int2String(propertyTable["freezingRoomTemp"])
        if propertyTable["iceMaking"] == 0x00 then
            streams[KEY_ICE_MAKING] = "normal"
        elseif propertyTable["iceMaking"] == 0x01 then
            streams[KEY_ICE_MAKING] = "quick"
        elseif propertyTable["iceMaking"] == 0x02 then
            streams[KEY_ICE_MAKING] = "off"
        else
            streams[KEY_ICE_MAKING] = "invalid"
        end
        if propertyTable["iceMakingStatus"] == 0x00 then
            streams[KEY_ICE_MAKING_STATUS] = "running"
        elseif propertyTable["iceMakingStatus"] == 0x01 then
            streams[KEY_ICE_MAKING_STATUS] = "water_shortage"
        elseif propertyTable["iceMakingStatus"] == 0x02 then
            streams[KEY_ICE_MAKING_STATUS] = "ice_full"
        elseif propertyTable["iceMakingStatus"] == 0x03 then
            streams[KEY_ICE_MAKING_STATUS] = "stop"
        end
        if propertyTable["vegetableSterilization"] == 0x01 then
            streams[KEY_VEGETABLE_STERILIZATION] = "on"
        elseif propertyTable["vegetableSterilization"] == 0x00 then
            streams[KEY_VEGETABLE_STERILIZATION] = "off"
        end
        if propertyTable["iceTrayCleaning"] == 0x01 then
            streams[KEY_ICE_TRAY_CLEANING] = "on"
        elseif propertyTable["iceTrayCleaning"] == 0x00 then
            streams[KEY_ICE_TRAY_CLEANING] = "off"
        end
        if propertyTable["maskVegetableSterilization"] == 0x00 then
            streams[KEY_MASK_VEGETABLE_STERILIZATION] = "on"
        elseif propertyTable["maskVegetableSterilization"] == 0x01 then
            streams[KEY_MASK_VEGETABLE_STERILIZATION] = "off"
        end
        if propertyTable["maskIceTrayCleaning"] == 0x00 then
            streams[KEY_MASK_ICE_TRAY_CLEANING] = "on"
        elseif propertyTable["maskIceTrayCleaning"] == 0x01 then
            streams[KEY_MASK_ICE_TRAY_CLEANING] = "off"
        end
        if bit.band(propertyTable["defrostStatus"], 0x01) == 0x01 then
            streams[KEY_DEFROST_STATUS_MOISTURE] = "on"
        else
            streams[KEY_DEFROST_STATUS_MOISTURE] = "off"
        end
        if bit.band(propertyTable["defrostStatus"], 0x02) == 0x02 then
            streams[KEY_DEFROST_STATUS_PRECOOL] = "on"
        else
            streams[KEY_DEFROST_STATUS_PRECOOL] = "off"
        end
        if bit.band(propertyTable["defrostStatus"], 0x04) == 0x04 then
            streams[KEY_DEFROST_STATUS_DEFROST] = "on"
        else
            streams[KEY_DEFROST_STATUS_DEFROST] = "off"
        end
        streams["chilling_door_status"] = integerToOnOff(propertyTable["chillingDoorStatus"])
        streams["freezing_door_status"] = integerToOnOff(propertyTable["freezingDoorStatus"])
        streams["ice_door_status"] = integerToOnOff(propertyTable["iceDoorStatus"])
        streams["vegetable_door_status"] = integerToOnOff(propertyTable["vegetableDoorStatus"])
        streams["freezing_upper_door_status"] = integerToOnOff(propertyTable["freezingUpperDoorStatus"])
        streams[KEY_INSTANTANEOUS_POWER] = int2String(propertyTable["instantaneousPower"])
        streams[KEY_DAILY_ENERGY] = int2String(propertyTable["dailyEnergy"])
        streams[KEY_ERROR_CODE] = int2String(propertyTable["errorCode"])
        if propertyTable["outRoomTemp"] ~= nil then
            streams[KEY_OUT_ROOM_TEMP] = int2String(buma(propertyTable["outRoomTemp"]) / 10)
        end
        if propertyTable["timer"] ~= nil then streams[KEY_TIMER] = int2String(propertyTable["timer"]) end
        propertyTableToStreamsForCustom(streams)
        propertyTableToStreamsForWeekly(streams)
    elseif propertyTable["functionType"] == 0x05 then
        streams[KEY_FUNCTION_TYPE] = "auto_power_saving_info"
        streams["has_data_one_hour"] = integerToOnOff(propertyTable["has_data_one_hour"])
        streams["has_data_two_hours"] = integerToOnOff(propertyTable["has_data_two_hours"])
        if propertyTable["status_current"] == 0x00 then
            streams["status_current"] = "normal"
        elseif propertyTable["status_current"] == 0x01 then
            streams["status_current"] = "eco_auto"
        elseif propertyTable["status_current"] == 0x02 then
            streams["status_current"] = "precool"
        elseif propertyTable["status_current"] == 0x03 then
            streams["status_current"] = "auto_saving_off"
        else
            streams["status_current"] = "invalid"
        end
        if propertyTable["has_data_one_hour"] == 0x01 then
            if propertyTable["status_one_hour"] == 0x00 then
                streams["status_one_hour"] = "normal"
            elseif propertyTable["status_one_hour"] == 0x01 then
                streams["status_one_hour"] = "eco_auto"
            elseif propertyTable["status_one_hour"] == 0x02 then
                streams["status_one_hour"] = "precool"
            elseif propertyTable["status_one_hour"] == 0x03 then
                streams["status_one_hour"] = "auto_saving_off"
            else
                streams["status_one_hour"] = "invalid"
            end
        else
            streams["status_one_hour"] = "invalid"
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            if propertyTable["status_two_hours"] == 0x00 then
                streams["status_two_hours"] = "normal"
            elseif propertyTable["status_two_hours"] == 0x01 then
                streams["status_two_hours"] = "eco_auto"
            elseif propertyTable["status_two_hours"] == 0x02 then
                streams["status_two_hours"] = "precool"
            elseif propertyTable["status_two_hours"] == 0x03 then
                streams["status_two_hours"] = "auto_saving_off"
            else
                streams["status_two_hours"] = "invalid"
            end
        else
            streams["status_two_hours"] = "invalid"
        end
        streams["r_avarage"] = int2String(propertyTable["r_avarage"])
        if propertyTable["has_data_one_hour"] == 0x01 then
            streams["r_avarage_one_hour"] = int2String(propertyTable["r_avarage_one_hour"])
        else
            streams["r_avarage_one_hour"] = int2String(0x7FFF)
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            streams["r_avarage_two_hours"] = int2String(propertyTable["r_avarage_two_hours"])
        else
            streams["r_avarage_two_hours"] = int2String(0x7FFF)
        end
        streams["f_avarage"] = int2String(propertyTable["f_avarage"])
        if propertyTable["has_data_one_hour"] == 0x01 then
            streams["f_avarage_one_hour"] = int2String(propertyTable["f_avarage_one_hour"])
        else
            streams["f_avarage_one_hour"] = int2String(0x7FFF)
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            streams["f_avarage_two_hours"] = int2String(propertyTable["f_avarage_two_hours"])
        else
            streams["f_avarage_two_hours"] = int2String(0x7FFF)
        end
        streams["pulldown_current"] = integerToOnOff(propertyTable["pulldown_current"])
        if propertyTable["has_data_one_hour"] == 0x01 then
            streams["pulldown_one_hour"] = integerToOnOff(propertyTable["pulldown_one_hour"])
            streams["defrost_one_hour"] = integerToOnOff(propertyTable["defrost_one_hour"])
        else
            streams["pulldown_one_hour"] = "invalid"
            streams["defrost_one_hour"] = "invalid"
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            streams["pulldown_two_hours"] = integerToOnOff(propertyTable["pulldown_two_hours"])
            streams["defrost_two_hours"] = integerToOnOff(propertyTable["defrost_two_hours"])
        else
            streams["pulldown_two_hours"] = "invalid"
            streams["defrost_two_hours"] = "invalid"
        end
        streams["defrost_current"] = integerToOnOff(propertyTable["defrost_current"])
    elseif propertyTable["functionType"] == 0x09 then
        streams[KEY_FUNCTION_TYPE] = "auto_power_saving_set"
        streams["query_cycle"] = int2String(propertyTable["query_cycle"])
    elseif propertyTable["functionType"] == 0x21 then
        streams[KEY_FUNCTION_TYPE] = "periodic"
        streams[KEY_ERROR_CODE] = int2String(propertyTable["errorCode"])
        streams["error_min"] = int2String(propertyTable["errorMin"])
        streams["error_hour"] = int2String(propertyTable["errorHour"])
        streams["error_day"] = int2String(propertyTable["errorDay"])
        streams["error_month"] = int2String(propertyTable["errorMonth"])
        streams["error_times"] = int2String(propertyTable["errorTimes"])
        streams["firmware_version"] = propertyTable["firmwareVersion"]
        streams["firmware_log"] = propertyTable["firmwareLog"]
    elseif propertyTable["functionType"] == 0x20 then
        streams[KEY_FUNCTION_TYPE] = "complete_notice"
        if bit.band(propertyTable["completionNoticeOne"], 0x80) == 0x80 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "ice_making_normal"
        elseif bit.band(propertyTable["notice"], 0x01) == 0x01 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "out_of_water"
        elseif bit.band(propertyTable["completionNoticeOne"], 0x01) == 0x01 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "quick_freezing"
        elseif bit.band(propertyTable["notice"], 0x02) == 0x02 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "rough_heat_removal"
        elseif bit.band(propertyTable["notice"], 0x04) == 0x04 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "cool_cooking"
        elseif bit.band(propertyTable["notice"], 0x08) == 0x08 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "timer"
        elseif bit.band(propertyTable["completionNoticeOne"], 0x02) == 0x02 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "vegetables"
        elseif bit.band(propertyTable["completionNoticeOne"], 0x04) == 0x04 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "vegetables_drying"
        elseif bit.band(propertyTable["completionNoticeOne"], 0x08) == 0x08 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "hot_things"
        elseif bit.band(propertyTable["completionNoticeOne"], 0x10) == 0x10 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "thawing"
        elseif bit.band(propertyTable["completionNoticeOne"], 0x20) == 0x20 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "thawing_thirty"
        elseif bit.band(propertyTable["completionNoticeOne"], 0x40) == 0x40 then
            streams[KEY_COMPLETION_NOTICE_ONE] = "ice_making"
        else
            streams[KEY_COMPLETION_NOTICE_ONE] = "invalid"
        end
    elseif propertyTable["functionType"] == 0xFE then
        streams[KEY_FUNCTION_TYPE] = "exception"
        streams[KEY_ERROR_CODE] = int2String(propertyTable["errorCode"])
        streams["error_min"] = int2String(propertyTable["errorMin"])
        streams["error_hour"] = int2String(propertyTable["errorHour"])
        streams["error_day"] = int2String(propertyTable["errorDay"])
        streams["error_month"] = int2String(propertyTable["errorMonth"])
        streams["error_times"] = int2String(propertyTable["errorTimes"])
        streams["firmware_version"] = propertyTable["firmwareVersion"]
        streams["firmware_log"] = propertyTable["firmwareLog"]
    elseif propertyTable["functionType"] == 0x22 then
        streams[KEY_FUNCTION_TYPE] = "door_info"
        streams["chilling_door_status"] = integerToOnOff(propertyTable["chillingDoorStatus"])
        streams["vegetable_door_status"] = integerToOnOff(propertyTable["vegetableDoorStatus"])
        streams["ice_door_status"] = integerToOnOff(propertyTable["iceDoorStatus"])
        streams["freezing_up_door_status"] = integerToOnOff(propertyTable["freezingUpStatus"])
        streams["freezing_down_door_status"] = integerToOnOff(propertyTable["freezingDownStatus"])
        streams["chilling_room_temp12"] = int2String(propertyTable["chillingRoomTempThan12"])
        streams["freezing_room_temp10"] = int2String(propertyTable["freezingRoomTempThan10"])
    end
    return streams
end
function jsonToData(jsonCmdStr)
    if #jsonCmdStr == 0 then return nil end
    initializeData()
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    local query = json["query"]
    local control = json["control"]
    if control then
        updateGlobalPropertyValueByJson(control)
        local bodyBytes = {}
        if propertyTable["functionType"] == 0x00 then
            local bodyLength = 63
            for i = 0, bodyLength - 1 do
                bodyBytes[i] = 0xFF
            end
            bodyBytes[0] = 0x00
            local data1 = 0
            if (propertyTable["chilledConst"] == 0x0F) and (propertyTable["chilledTemp"] == 0xF0) then
                data1 = 0xFF
            else
                data1 = bit.bor(bit.lshift(propertyTable["chilledConst"], 0), data1)
                if propertyTable["chilledTemp"] == 0xF0 then
                    data1 = bit.bor(0xF0, data1)
                else
                    data1 = bit.bor(bit.lshift(propertyTable["chilledTemp"], 4), data1)
                end
            end
            bodyBytes[1] = data1
            print(propertyTable["chilledConst"])
            print(propertyTable["chilledTemp"])
            print(data1)
            bodyBytes[2] = 0xFF
            bodyBytes[3] = propertyTable["powerSavingMode"]
            bodyBytes[4] = propertyTable["cooling"]
            bodyBytes[5] = propertyTable["chillingRoomTemp"]
            bodyBytes[6] = propertyTable["freezingRoomTemp"]
            bodyBytes[7] = propertyTable["iceMaking"]
            local data8 = 0xCC
            if (propertyTable["vegetableSterilization"] == 0xFF) and (propertyTable["iceTrayCleaning"] == 0xFF) then
                data8 = 0xFF
            else
                if propertyTable["vegetableSterilization"] == 0xFF then
                    data8 = bit.bor(bit.lshift(0x01, 4), data8)
                else
                    data8 = bit.bor(bit.lshift(propertyTable["vegetableSterilization"], 0), data8)
                    data8 = bit.bor(bit.lshift(propertyTable["maskVegetableSterilization"], 4), data8)
                end
                if propertyTable["iceTrayCleaning"] == 0xFF then
                    data8 = bit.bor(bit.lshift(0x01, 5), data8)
                else
                    data8 = bit.bor(bit.lshift(propertyTable["iceTrayCleaning"], 1), data8)
                    data8 = bit.bor(bit.lshift(propertyTable["maskIceTrayCleaning"], 5), data8)
                end
            end
            bodyBytes[8] = data8
            if propertyTable["timer"] ~= nil then bodyBytes[20] = propertyTable["timer"] end
            local data21 = 0
            if
                (propertyTable["nightMode"] == 0xFF)
                and (propertyTable["autoDoorLeft"] == 0xFF)
                and (propertyTable["autoDoorRight"] == 0xFF)
                and (propertyTable["lightBlueLed"] == 0xFF)
            then
                data21 = 0xFF
            else
                if propertyTable["nightMode"] == 0xFF then
                    data21 = bit.bor(bit.lshift(0x01, 4), data21)
                else
                    data21 = bit.bor(bit.lshift(propertyTable["nightMode"], 0), data21)
                    data21 = bit.bor(bit.lshift(propertyTable["maskNightMode"], 4), data21)
                end
                if propertyTable["autoDoorLeft"] == 0xFF then
                    data21 = bit.bor(bit.lshift(0x01, 5), data21)
                else
                    data21 = bit.bor(bit.lshift(propertyTable["autoDoorLeft"], 1), data21)
                    data21 = bit.bor(bit.lshift(propertyTable["maskAutoDoorLeft"], 5), data21)
                end
                if propertyTable["autoDoorRight"] == 0xFF then
                    data21 = bit.bor(bit.lshift(0x01, 6), data21)
                else
                    data21 = bit.bor(bit.lshift(propertyTable["autoDoorRight"], 2), data21)
                    data21 = bit.bor(bit.lshift(propertyTable["maskAutoDoorRight"], 6), data21)
                end
                if propertyTable["lightBlueLed"] == 0xFF then
                    data21 = bit.bor(bit.lshift(0x01, 7), data21)
                else
                    data21 = bit.bor(bit.lshift(propertyTable["lightBlueLed"], 3), data21)
                    data21 = bit.bor(bit.lshift(propertyTable["maskLightBlueLed"], 7), data21)
                end
            end
            bodyBytes[21] = data21
            bodyBytes[22] = propertyTable["ceilingLightNormal"]
            bodyBytes[23] = propertyTable["doorLightNormal"]
            bodyBytes[24] = propertyTable["chilledLightNormal"]
            bodyBytes[25] = propertyTable["vegeLightNormal"]
            bodyBytes[26] = propertyTable["ceilingLightNight"]
            bodyBytes[27] = propertyTable["doorLightNight"]
            bodyBytes[28] = propertyTable["chilledLightNight"]
            bodyBytes[29] = propertyTable["vegeLightNight"]
            bodyBytes[30] = propertyTable["nightStartMin"]
            bodyBytes[31] = propertyTable["nightStartHour"]
            bodyBytes[32] = propertyTable["nightEndMin"]
            bodyBytes[33] = propertyTable["nightEndHour"]
            bodyBytes[34] = propertyTable["doorLeftForOpen"]
            bodyBytes[35] = propertyTable["doorLeftForPressureHigh"]
            bodyBytes[36] = propertyTable["doorLeftForPressureLow"]
            bodyBytes[37] = propertyTable["doorRightForOpen"]
            bodyBytes[38] = propertyTable["doorRightForPressureHigh"]
            bodyBytes[39] = propertyTable["doorRightForPressureLow"]
            bodyBytes[40] = propertyTable["weeklyReminder"]
            bodyBytes[41] = propertyTable["weeklyReminderMin"]
            bodyBytes[42] = propertyTable["weeklyReminderHour"]
            bodyBytes[43] = propertyTable["sunday_1"]
            bodyBytes[44] = propertyTable["monday_1"]
            bodyBytes[45] = propertyTable["tuesday_1"]
            bodyBytes[46] = propertyTable["wednesday_1"]
            bodyBytes[47] = propertyTable["thursday_1"]
            bodyBytes[48] = propertyTable["friday_1"]
            bodyBytes[49] = propertyTable["saturday_1"]
            bodyBytes[50] = propertyTable["sunday_2"]
            bodyBytes[51] = propertyTable["monday_2"]
            bodyBytes[52] = propertyTable["tuesday_2"]
            bodyBytes[53] = propertyTable["wednesday_2"]
            bodyBytes[54] = propertyTable["thursday_2"]
            bodyBytes[55] = propertyTable["friday_2"]
            bodyBytes[56] = propertyTable["saturday_2"]
            bodyBytes[57] = 0xFF
            bodyBytes[58] = 0xFF
            bodyBytes[59] = 0xFF
            bodyBytes[60] = 0xFF
            bodyBytes[61] = 0xFF
            bodyBytes[62] = 0xFF
        elseif propertyTable["functionType"] == 0x09 then
            bodyBytes[0] = 0x09
            bodyBytes[1] = 0x8F
            bodyBytes[2] = 0x00
            for i = 1, 168 do
                bodyBytes[i + 2] = propertyTable["auto_status_set"][i]
            end
        elseif propertyTable["functionType"] == 0x23 then
            bodyBytes[0] = 0x23
            local data1 = 0
            if propertyTable["ingredientExpiration"] == 0xFF then
                data1 = 0xFF
            else
                if propertyTable["ingredientExpiration"] ~= 0xFF then
                    data1 = bit.bor(bit.lshift(propertyTable["ingredientExpiration"], 0), data1)
                end
            end
            bodyBytes[1] = data1
            if propertyTable["care"] ~= 0xFE then
                bodyBytes[2] = propertyTable["care"]
            else
            end
        elseif
            (propertyTable["functionType"] == 0x30)
            or (propertyTable["functionType"] == 0x31)
            or (propertyTable["functionType"] == 0x32)
        then
            bodyBytes[0] = propertyTable["functionType"]
            bodyBytes[1] = propertyTable["classification"]
            bodyBytes[2] = bit.band(propertyTable["errorCode"], 0xFF)
            bodyBytes[3] = bit.band(bit.rshift(propertyTable["errorCode"], 8), 0xFF)
        end
        msgBytes = assembleUart(bodyBytes, 0x0002)
    elseif query then
        local bodyBytes = {}
        bodyBytes[0] = 0x00
        msgBytes = assembleUart(bodyBytes, 0x0003)
    end
    local infoM = {}
    local length = #msgBytes + 1
    for i = 1, length do
        infoM[i] = msgBytes[i - 1]
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonStr)
    if not jsonStr then return nil end
    initializeData()
    local json = decodeJsonToTable(jsonStr)
    local binData = json["msg"]["data"]
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[15]
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end
