local bit = require "bit"
local JSON = require "cjson"
local bit = require "bit"
local VALUE_VERSION = 74
local VALUE_FLOAT_PRECISE_DECIMAL_NUM = 4
local uptable = {}
uptable["KEY_POWER"] = "power"
uptable["KEY_ANION"] = "anion"
uptable["KEY_MODE"] = "mode"
uptable["KEY_FAN_SPEED"] = "wind_speed"
uptable["KEY_BUZZER"] = "buzzer"
uptable["KEY_PM25"] = "pm25"
uptable["KEY_PM25_OUT"] = "pm25_out"
uptable["KEY_TVOC"] = "tvoc"
uptable["KEY_ASH_TVOC"] = "ash_tvoc"
uptable["KEY_SMELL_TVOC"] = "smell_tvoc"
uptable["KEY_ERROR_CODE"] = "error_code"
uptable["KEY_HCHO"] = "hcho"
uptable["KEY_HUMIDIFY_FEEDBACK"] = "humidify_feedback"
uptable["KEY_TEMPERATURE_FEEDBACK"] = "temperature_feedback"
uptable["KEY_SCHEDULE_CLOSE_SWITCHER"] = "power_off_timer"
uptable["KEY_SCHEDULE_CLOSE_TIME"] = "time"
uptable["KEY_SCHEDULE_OPEN_SWITCHER"] = "power_on_timer"
uptable["KEY_SCHEDULE_OPEN_TIME"] = "time_on"
uptable["KEY_BRIGHT"] = "bright"
uptable["KEY_LOCK"] = "lock"
uptable["KEY_WATERIONS"] = "waterions"
uptable["KEY_HOSTING"] = "hosting"
uptable["KEY_HOSTING_UPPER"] = "hosting_upper"
uptable["KEY_HOSTING_LOWER"] = "hosting_lower"
uptable["KEY_FILTER"] = "filter"
uptable["KEY_FIRST_FILTER_PERCENT"] = "first_filter_percent"
uptable["KEY_DEEP_FILTER_PERCENT"] = "deep_filter_percent"
uptable["KEY_FILTER_SET"] = "filter_set"
uptable["KEY_DETECT"] = "detect"
uptable["KEY_DETECT_MODE"] = "detect_mode"
uptable["KEY_FILTER_DEEP_ACC_TIME"] = "filter_deep_1_acc_time"
uptable["KEY_FILTER_DEEP2_ACC_TIME"] = "filter_deep_2_acc_time"
uptable["KEY_HUMIDIFY_MODE"] = "humidify_mode"
uptable["KEY_VOICE_TYPE"] = "voice_type"
uptable["KEY_VOICE_VOLUME"] = "voice_volume"
uptable["KEY_QUERY_TYPE"] = "query_type"
uptable["KEY_STERILIZE_ENABLE"] = "sterilize_enable"
uptable["KEY_STERILIZE_MINUTE"] = "sterilize_minute"
uptable["KEY_UV_ENABLE"] = "uv_enable"
uptable["KEY_LIGHT_ENABLE"] = "light_enable"
uptable["KEY_STORAGE_FEEDBACK"] = "storage_feedback"
uptable["KEY_CHARGE_FEEDBACK"] = "charge_feedback"
uptable["KEY_SET_HUMIDITY"] = "humidity"
uptable["VALUE_COMMON_ON"] = "on"
uptable["VALUE_COMMON_OFF"] = "off"
uptable["VALUE_COMMON_NONE"] = "none"
uptable["VALUE_COMMON_INVALID"] = "invalid"
uptable["VALUE_MODE_TAB"] =
    { "auto", "manual", "sleep", "fast", "smoke", "middle_wind", "air_dry", "pet", [0] = "none" }
uptable["VALUE_SUB_MODE_TAB"] = { "off", "dirty", "pet", "denoise", "inspection", [0] = "invalid" }
uptable["VALUE_FILTER_FIRST"] = "first"
uptable["VALUE_FILTER_DEEP"] = "deep"
uptable["VALUE_FILTERSET_DEEP"] = "deep"
uptable["VALUE_FILTERSET_HCHO"] = "hcho"
uptable["VALUE_DETECT_PM25_ON"] = "pm25_on"
uptable["VALUE_DETECT_PM25_OFF"] = "pm25_off"
uptable["VALUE_DETECT_HCHO_ON"] = "hcho_on"
uptable["VALUE_DETECT_HCHO_OFF"] = "hcho_off"
uptable["VALUE_LIGHT_ENABLE_HALF"] = "half"
uptable["VALUE_STORAGE_FEEDBACK_NONE"] = "none"
uptable["VALUE_STORAGE_FEEDBACK_NORMAL"] = "normal"
uptable["VALUE_STORAGE_FEEDBACK_PROTECT"] = "protect"
uptable["VALUE_CHARGE_FEEDBACK_NONE"] = "none"
uptable["VALUE_CHARGE_FEEDBACK_OFF"] = "off"
uptable["VALUE_CHARGE_FEEDBACK_STANDBY"] = "standby"
uptable["VALUE_CHARGE_FEEDBACK_RUN"] = "run"
uptable["VALUE_VOICE_VOLUME_TYPE_TAB"] = { "auto", "manual", "fixed", [0] = "invalid" }
uptable["VALUE_VOICE_TYPE_TAB"] = { "ms", "mr", "child", "beep", [0] = "invalid" }
uptable["VALUE_LIGHT_COLOR_TAB"] = { "off", "white", "yellow", [0] = "invalid" }
uptable["VALUE_PROPERTY_EXECUTE_TAB"] =
    { [0] = "success", [1] = "executing", [16] = "fail", [17] = "invalid", [18] = "value_error" }
uptable["BYTE_CONTROL_REQUEST"] = 0x02
uptable["BYTE_PROTOCOL_LENGTH"] = 0x0A
uptable["BYTE_POWER_ON"] = 0x01
uptable["BYTE_POWER_OFF"] = 0x00
uptable["BYTE_ANION_ON"] = 0x40
uptable["BYTE_ANION_OFF"] = 0x00
uptable["BYTE_BUZZER_ON"] = 0x40
uptable["BYTE_BUZZER_OFF"] = 0x00
uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON"] = 0x80
uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_OFF"] = 0x7F
uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_ON"] = 0x80
uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_OFF"] = 0x7F
uptable["BYTE_LOCK_ON"] = 0x80
uptable["BYTE_LOCK_OFF"] = 0x00
uptable["BYTE_WATERIONS_ON"] = 0x20
uptable["BYTE_WATERIONS_OFF"] = 0x00
uptable["BYTE_HOSTING_ON"] = 0x01
uptable["BYTE_HOSTING_OFF"] = 0x02
uptable["BYTE_DETECT_ON"] = 0x08
uptable["BYTE_DETECT_OFF"] = 0x00
uptable["BYTE_DETECT_PM25"] = 0x00
uptable["BYTE_DETECT_HCHO"] = 0x01
uptable["BYTE_FILTERSET_DEEP"] = 0x01
uptable["BYTE_FILTERSET_HCHO"] = 0x02
uptable["BYTE_STERILIZE_ENABLE_NONE"] = 0x00
uptable["BYTE_STERILIZE_ENABLE_ON"] = 0x01
uptable["BYTE_STERILIZE_ENABLE_OFF"] = 0x02
uptable["BYTE_UV_ENABLE_NONE"] = 0x00
uptable["BYTE_UV_ENABLE_ON"] = 0x01
uptable["BYTE_UV_ENABLE_OFF"] = 0x02
uptable["BYTE_LIGHT_ENABLE_NONE"] = 0x00
uptable["BYTE_LIGHT_ENABLE_ON"] = 0x01
uptable["BYTE_LIGHT_ENABLE_OFF"] = 0x02
uptable["BYTE_LIGHT_ENABLE_HALF"] = 0x03
uptable["BYTE_STORAGE_FEEDBACK_NONE"] = 0x00
uptable["BYTE_STORAGE_FEEDBACK_NORMAL"] = 0x01
uptable["BYTE_STORAGE_FEEDBACK_PROTECT"] = 0x02
uptable["BYTE_CHARGE_FEEDBACK_NONE"] = 0x00
uptable["BYTE_CHARGE_FEEDBACK_OFF"] = 0x01
uptable["BYTE_CHARGE_FEEDBACK_STANDBY"] = 0x02
uptable["BYTE_CHARGE_FEEDBACK_RUN"] = 0x03
local function initVariableTab()
    local variableTab = {}
    variableTab["queryProperty"] = false
    variableTab["power"] = 0
    variableTab["anion"] = 0
    variableTab["bright"] = 0
    variableTab["lock"] = 0
    variableTab["waterions"] = 0
    variableTab["mode"] = 0
    variableTab["fanSpeed"] = 0
    variableTab["pm25"] = 0
    variableTab["pm25_out"] = 0
    variableTab["tvoc"] = 0
    variableTab["ashTvoc"] = 0
    variableTab["smellTvoc"] = 0
    variableTab["errorCode"] = 0
    variableTab["buzzer"] = 0
    variableTab["detect"] = 0
    variableTab["hcho"] = 65535
    variableTab["hcho_level"] = 0
    variableTab["humidifyFeedback"] = 0
    variableTab["temperatureFeedback"] = nil
    variableTab["sterilizeEnable"] = 0
    variableTab["sterilizeMinute"] = 0
    variableTab["uvEnable"] = 0
    variableTab["lightEnable"] = 0
    variableTab["bodyFeelingEnable"] = 0
    variableTab["filterAirDry"] = 0
    variableTab["storageFeedback"] = 0
    variableTab["chargeFeedback"] = 0
    variableTab["voiceVolume"] = 0
    variableTab["detectMode"] = 0
    variableTab["first_filter_percent"] = 0
    variableTab["deep_filter_percent"] = 0
    variableTab["filterDeep1ACCTime"] = 0
    variableTab["scheduleCloseSwitcher"] = false
    variableTab["scheduleCloseTime"] = 0
    variableTab["scheduleOpenSwitcher"] = false
    variableTab["scheduleOpenTime"] = 0
    variableTab["humidifyMode"] = 0
    variableTab["scheduleTimeValidate"] = false
    variableTab["dataType"] = 0
    variableTab["filterFirst"] = false
    variableTab["filterDeep"] = false
    variableTab["filterSetDeep"] = false
    variableTab["filterSetHcho"] = false
    variableTab["pm1"] = 0xffff
    variableTab["pm10"] = 0xffff
    variableTab["deepFilterReplaceNotice"] = 0
    variableTab["vocValue"] = 0
    variableTab["removableWaterBoxFlag"] = 0
    variableTab["waterLack"] = 0
    variableTab["humidity"] = 0
    variableTab["subMode"] = 0
    variableTab["biasGear"] = 0
    return variableTab
end
local function checkBoundary(data, min, max)
    if not data then data = 0 end
    data = tonumber(data)
    if (data >= min) and (data <= max) then
        return data
    else
        if data < min then
            return min
        else
            return max
        end
    end
end
local function byteData2Long(byteData, start, byteCounts)
    local byteTab = { 1, 256, 65536, 16777216, 4294967296, 1099511627776, 281474976710656 }
    local result = 0
    local j = 1
    for i = start, start + byteCounts - 1 do
        result = result + byteData[i] * byteTab[j]
        j = j + 1
    end
    return result
end
local function table2string(cmd)
    local ret = ""
    for i = 1, #cmd do
        ret = ret .. string.char(cmd[i])
    end
    return ret
end
local function string2table(hexstr)
    local tb = {}
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
local function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then JSON = require "cjson" end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
end
local function decodeJsonToTable(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
    end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
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
local function getIndexFromValueTab(table, value, defaultIndex)
    for k, v in pairs(table) do
        if value == v then return k end
    end
    if defaultIndex then return defaultIndex end
    return nil
end
local function getValueFromValueTab(table, index, defaultValue)
    for k, v in pairs(table) do
        if index == k then return v end
    end
    if defaultValue then return defaultValue end
    return nil
end
local function extractBodyBytes(byteData)
    local bodyBytes = {}
    local bodyLength = #byteData - 11
    for i = 1, bodyLength do
        bodyBytes[i - 1] = byteData[i + 10]
    end
    return bodyBytes
end
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    local msgLength = (bodyLength + uptable["BYTE_PROTOCOL_LENGTH"] + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do
        msgBytes[i] = 0
    end
    msgBytes[0] = 0xAA
    msgBytes[1] = msgLength - 1
    msgBytes[2] = 0xFC
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do
        msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]] = bodyBytes[i]
    end
    msgBytes[msgLength - 1] = makeSum(msgBytes, 1, msgLength - 2)
    return msgBytes
end
local function noInvalidValueMerge(luaTable, variableTab)
    if luaTable[uptable["KEY_POWER"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["power"] = uptable["BYTE_POWER_ON"]
    elseif luaTable[uptable["KEY_POWER"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["power"] = uptable["BYTE_POWER_OFF"]
    end
    if luaTable[uptable["KEY_DETECT"]] == uptable["VALUE_DETECT_PM25_ON"] then
        variableTab["detect"] = uptable["BYTE_DETECT_ON"]
        variableTab["detectMode"] = uptable["BYTE_DETECT_PM25"]
    elseif luaTable[uptable["KEY_DETECT"]] == uptable["VALUE_DETECT_PM25_OFF"] then
        variableTab["detect"] = uptable["BYTE_DETECT_OFF"]
    elseif luaTable[uptable["KEY_DETECT"]] == uptable["VALUE_DETECT_HCHO_ON"] then
        variableTab["detect"] = uptable["BYTE_DETECT_ON"]
        variableTab["detectMode"] = uptable["BYTE_DETECT_HCHO"]
    elseif luaTable[uptable["KEY_DETECT"]] == uptable["VALUE_DETECT_HCHO_OFF"] then
        variableTab["detect"] = uptable["BYTE_DETECT_OFF"]
    end
    if luaTable[uptable["KEY_ANION"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["anion"] = uptable["BYTE_ANION_ON"]
    elseif luaTable[uptable["KEY_ANION"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["anion"] = uptable["BYTE_ANION_OFF"]
    end
    if luaTable[uptable["KEY_BRIGHT"]] ~= nil then variableTab["bright"] = luaTable[uptable["KEY_BRIGHT"]] end
    if luaTable[uptable["KEY_LOCK"]] == "on" then
        variableTab["lock"] = uptable["BYTE_LOCK_ON"]
    elseif luaTable[uptable["KEY_LOCK"]] == "off" then
        variableTab["lock"] = uptable["BYTE_LOCK_OFF"]
    end
    if luaTable[uptable["KEY_WATERIONS"]] == "on" then
        variableTab["waterions"] = uptable["BYTE_WATERIONS_ON"]
    elseif luaTable[uptable["KEY_WATERIONS"]] == "off" then
        variableTab["waterions"] = uptable["BYTE_WATERIONS_OFF"]
    end
    local openScheduleTime = false
    if luaTable[uptable["KEY_SCHEDULE_CLOSE_SWITCHER"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["scheduleCloseSwitcher"] = true
        openScheduleTime = true
    elseif luaTable[uptable["KEY_SCHEDULE_CLOSE_SWITCHER"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["scheduleCloseSwitcher"] = false
        openScheduleTime = true
    end
    if luaTable[uptable["KEY_SCHEDULE_CLOSE_TIME"]] ~= nil then
        variableTab["scheduleCloseTime"] = luaTable[uptable["KEY_SCHEDULE_CLOSE_TIME"]]
    end
    if luaTable[uptable["KEY_SCHEDULE_OPEN_SWITCHER"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["scheduleOpenSwitcher"] = true
        openScheduleTime = true
    elseif luaTable[uptable["KEY_SCHEDULE_OPEN_SWITCHER"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["scheduleOpenSwitcher"] = false
        openScheduleTime = true
    end
    if openScheduleTime then
        variableTab["scheduleTimeValidate"] = true
    else
        variableTab["scheduleTimeValidate"] = false
    end
    if luaTable[uptable["KEY_SCHEDULE_OPEN_TIME"]] ~= nil then
        variableTab["scheduleOpenTime"] = luaTable[uptable["KEY_SCHEDULE_OPEN_TIME"]]
    end
    if luaTable[uptable["KEY_BUZZER"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["buzzer"] = uptable["BYTE_BUZZER_ON"]
    elseif luaTable[uptable["KEY_BUZZER"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["buzzer"] = uptable["BYTE_BUZZER_OFF"]
    end
    if luaTable[uptable["KEY_HOSTING_UPPER"]] ~= nil then
        variableTab["hostingUpper"] = luaTable[uptable["KEY_HOSTING_UPPER"]]
    end
    if luaTable[uptable["KEY_HOSTING_LOWER"]] ~= nil then
        variableTab["hostingLower"] = luaTable[uptable["KEY_HOSTING_LOWER"]]
    end
    if luaTable[uptable["KEY_VOICE_VOLUME"]] ~= nil then
        variableTab["voiceVolume"] = luaTable[uptable["KEY_VOICE_VOLUME"]]
    end
    if luaTable[uptable["KEY_SET_HUMIDITY"]] ~= nil then
        variableTab["humidity"] = luaTable[uptable["KEY_SET_HUMIDITY"]]
    end
end
local function updateGlobalPropertyValueByJson(luaTable, variableTab)
    if luaTable[uptable["KEY_POWER"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["power"] = uptable["BYTE_POWER_ON"]
    elseif luaTable[uptable["KEY_POWER"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["power"] = uptable["BYTE_POWER_OFF"]
    end
    if luaTable[uptable["KEY_DETECT"]] == uptable["VALUE_DETECT_PM25_ON"] then
        variableTab["detect"] = uptable["BYTE_DETECT_ON"]
        variableTab["detectMode"] = uptable["BYTE_DETECT_PM25"]
    elseif luaTable[uptable["KEY_DETECT"]] == uptable["VALUE_DETECT_PM25_OFF"] then
        variableTab["detect"] = uptable["BYTE_DETECT_OFF"]
    elseif luaTable[uptable["KEY_DETECT"]] == uptable["VALUE_DETECT_HCHO_ON"] then
        variableTab["detect"] = uptable["BYTE_DETECT_ON"]
        variableTab["detectMode"] = uptable["BYTE_DETECT_HCHO"]
    elseif luaTable[uptable["KEY_DETECT"]] == uptable["VALUE_DETECT_HCHO_OFF"] then
        variableTab["detect"] = uptable["BYTE_DETECT_OFF"]
    end
    if luaTable[uptable["KEY_ANION"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["anion"] = uptable["BYTE_ANION_ON"]
    elseif luaTable[uptable["KEY_ANION"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["anion"] = uptable["BYTE_ANION_OFF"]
    end
    if luaTable[uptable["KEY_BRIGHT"]] ~= nil then variableTab["bright"] = luaTable[uptable["KEY_BRIGHT"]] end
    if luaTable[uptable["KEY_LOCK"]] == "on" then
        variableTab["lock"] = uptable["BYTE_LOCK_ON"]
    elseif luaTable[uptable["KEY_LOCK"]] == "off" then
        variableTab["lock"] = uptable["BYTE_LOCK_OFF"]
    end
    if luaTable[uptable["KEY_WATERIONS"]] == "on" then
        variableTab["waterions"] = uptable["BYTE_WATERIONS_ON"]
    elseif luaTable[uptable["KEY_WATERIONS"]] == "off" then
        variableTab["waterions"] = uptable["BYTE_WATERIONS_OFF"]
    end
    variableTab["mode"] = getIndexFromValueTab(uptable["VALUE_MODE_TAB"], luaTable[uptable["KEY_MODE"]], 0)
    variableTab["fanSpeed"] = checkBoundary(luaTable[uptable["KEY_FAN_SPEED"]], 0, 101)
    local openScheduleTime = false
    if luaTable[uptable["KEY_SCHEDULE_CLOSE_SWITCHER"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["scheduleCloseSwitcher"] = true
        openScheduleTime = true
    elseif luaTable[uptable["KEY_SCHEDULE_CLOSE_SWITCHER"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["scheduleCloseSwitcher"] = false
        openScheduleTime = true
    end
    if luaTable[uptable["KEY_SCHEDULE_CLOSE_TIME"]] ~= nil then
        variableTab["scheduleCloseTime"] = luaTable[uptable["KEY_SCHEDULE_CLOSE_TIME"]]
    end
    if luaTable[uptable["KEY_SCHEDULE_OPEN_SWITCHER"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["scheduleOpenSwitcher"] = true
        openScheduleTime = true
    elseif luaTable[uptable["KEY_SCHEDULE_OPEN_SWITCHER"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["scheduleOpenSwitcher"] = false
        openScheduleTime = true
    end
    if openScheduleTime then
        variableTab["scheduleTimeValidate"] = true
    else
        variableTab["scheduleTimeValidate"] = false
    end
    if luaTable[uptable["KEY_SCHEDULE_OPEN_TIME"]] ~= nil then
        variableTab["scheduleOpenTime"] = luaTable[uptable["KEY_SCHEDULE_OPEN_TIME"]]
    end
    if luaTable[uptable["KEY_BUZZER"]] == uptable["VALUE_COMMON_ON"] then
        variableTab["buzzer"] = uptable["BYTE_BUZZER_ON"]
    elseif luaTable[uptable["KEY_BUZZER"]] == uptable["VALUE_COMMON_OFF"] then
        variableTab["buzzer"] = uptable["BYTE_BUZZER_OFF"]
    end
    if luaTable[uptable["KEY_HOSTING"]] == "on" then
        variableTab["hosting"] = uptable["BYTE_HOSTING_ON"]
    elseif luaTable[uptable["KEY_HOSTING"]] == "off" then
        variableTab["hosting"] = uptable["BYTE_HOSTING_OFF"]
    end
    if luaTable[uptable["KEY_HOSTING_UPPER"]] ~= nil then
        variableTab["hostingUpper"] = luaTable[uptable["KEY_HOSTING_UPPER"]]
    end
    if luaTable[uptable["KEY_HOSTING_LOWER"]] ~= nil then
        variableTab["hostingLower"] = luaTable[uptable["KEY_HOSTING_LOWER"]]
    end
    if luaTable[uptable["KEY_FILTER"]] == uptable["VALUE_FILTER_FIRST"] then
        variableTab["filterFirst"] = true
    else
        variableTab["filterFirst"] = false
    end
    if luaTable[uptable["KEY_FILTER"]] == uptable["VALUE_FILTER_DEEP"] then
        variableTab["filterDeep"] = true
    else
        variableTab["filterDeep"] = false
    end
    if luaTable[uptable["KEY_FILTER_SET"]] == uptable["VALUE_FILTERSET_DEEP"] then
        variableTab["filterSetDeep"] = true
    else
        variableTab["filterSetDeep"] = false
    end
    if luaTable[uptable["KEY_FILTER_SET"]] == uptable["VALUE_FILTERSET_HCHO"] then
        variableTab["filterSetHcho"] = true
    else
        variableTab["filterSetHcho"] = false
    end
    if luaTable[uptable["KEY_VOICE_VOLUME"]] ~= nil then
        variableTab["voiceVolume"] = luaTable[uptable["KEY_VOICE_VOLUME"]]
    end
    if luaTable[uptable["KEY_STERILIZE_ENABLE"]] ~= nil then
        if luaTable[uptable["KEY_STERILIZE_ENABLE"]] == "on" then
            variableTab["sterilizeEnable"] = uptable["BYTE_STERILIZE_ENABLE_ON"]
        elseif luaTable[uptable["KEY_STERILIZE_ENABLE"]] == "off" then
            variableTab["sterilizeEnable"] = uptable["BYTE_STERILIZE_ENABLE_OFF"]
        end
    end
    if luaTable[uptable["KEY_STERILIZE_MINUTE"]] ~= nil then
        variableTab["sterilizeMinute"] = luaTable[uptable["KEY_STERILIZE_MINUTE"]]
    end
    if luaTable[uptable["KEY_UV_ENABLE"]] ~= nil then
        if luaTable[uptable["KEY_UV_ENABLE"]] == "on" then
            variableTab["uvEnable"] = uptable["BYTE_UV_ENABLE_ON"]
        elseif luaTable[uptable["KEY_UV_ENABLE"]] == "off" then
            variableTab["uvEnable"] = uptable["BYTE_UV_ENABLE_OFF"]
        end
    end
    if luaTable[uptable["KEY_LIGHT_ENABLE"]] ~= nil then
        if luaTable[uptable["KEY_LIGHT_ENABLE"]] == "on" then
            variableTab["lightEnable"] = uptable["BYTE_LIGHT_ENABLE_ON"]
        elseif luaTable[uptable["KEY_LIGHT_ENABLE"]] == "off" then
            variableTab["lightEnable"] = uptable["BYTE_LIGHT_ENABLE_OFF"]
        elseif luaTable[uptable["KEY_LIGHT_ENABLE"]] == "half" then
            variableTab["lightEnable"] = uptable["BYTE_LIGHT_ENABLE_HALF"]
        end
    end
    if luaTable["filter_air_dry"] ~= nil then
        if luaTable["filter_air_dry"] == "on" then
            variableTab["filterAirDry"] = 1
        elseif luaTable["filter_air_dry"] == "off" then
            variableTab["filterAirDry"] = 2
        end
    end
    if luaTable["sub_mode"] ~= nil then
        variableTab["subMode"] = getIndexFromValueTab(uptable["VALUE_SUB_MODE_TAB"], luaTable["sub_mode"], 0)
    end
    if luaTable["bias_gear"] ~= nil then variableTab["biasGear"] = luaTable["bias_gear"] end
    if luaTable["pure_rate_display"] ~= nil then
        if luaTable["pure_rate_display"] == "on" then
            variableTab["pureRateDisplay"] = 1
        elseif luaTable["pure_rate_display"] == "off" then
            variableTab["pureRateDisplay"] = 2
        end
    end
    if luaTable["light_color"] ~= nil then
        variableTab["lightColor"] = getIndexFromValueTab(uptable["VALUE_LIGHT_COLOR_TAB"], luaTable["light_color"], 0)
    else
        variableTab["lightColor"] = 0
    end
    if luaTable[uptable["KEY_SET_HUMIDITY"]] ~= nil then
        variableTab["humidity"] = luaTable[uptable["KEY_SET_HUMIDITY"]]
    end
end
local function updateGlobalPropertyValueByByte(messageBytes, variableTab)
    if #messageBytes == 0 then return nil end
    local subCommand = messageBytes[0]
    if variableTab["dataType"] == 0x04 and subCommand == 1 then return nil end
    if variableTab["dataType"] == 0x04 and subCommand == 0x54 then return end
    if variableTab["dataType"] == 0x02 or variableTab["dataType"] == 0x03 or variableTab["dataType"] == 0x04 then
        variableTab["queryProperty"] = false
        variableTab["power"] = bit.band(messageBytes[1], 0x01)
        variableTab["detect"] = bit.band(messageBytes[1], 0x08)
        variableTab["mode"] = bit.rshift(bit.band(messageBytes[2], 0xF0), 4)
        variableTab["fanSpeed"] = bit.band(messageBytes[3], 0x7F)
        if
            bit.band(messageBytes[5], uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON"])
            == uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON"]
        then
            variableTab["scheduleCloseSwitcher"] = true
        else
            variableTab["scheduleCloseSwitcher"] = false
        end
        local timingOffMul15 = bit.band(messageBytes[5], 0x7F)
        local timingOffLeft15 = bit.band(messageBytes[6], 0x0f)
        variableTab["scheduleCloseTime"] = timingOffMul15 * 15 + (15 - timingOffLeft15)
        if
            bit.band(messageBytes[4], uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_ON"])
            == uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_ON"]
        then
            variableTab["scheduleOpenSwitcher"] = true
        else
            variableTab["scheduleOpenSwitcher"] = false
        end
        local timingOnMul15 = bit.band(messageBytes[4], 0x7F)
        local timingOnLeft15 = bit.rshift(bit.band(messageBytes[6], 0xf0), 4)
        variableTab["scheduleOpenTime"] = timingOnMul15 * 15 + (15 - timingOnLeft15)
        variableTab["anion"] = bit.band(messageBytes[9], 0x40)
        variableTab["bright"] = bit.band(messageBytes[9], 0x07)
        local filterHigh = (messageBytes[11] * 4)
        local filterLow = bit.band(bit.rshift(messageBytes[12], 6), 0x03)
        variableTab["filterDeep1ACCTime"] = filterHigh + filterLow
        variableTab["ashTvoc"] = bit.band(messageBytes[12], 0x07)
        variableTab["smellTvoc"] = bit.band(bit.rshift(messageBytes[12], 3), 0x07)
        variableTab["pm25"] = messageBytes[14] * 256 + messageBytes[13]
        variableTab["tvoc"] = messageBytes[15]
        variableTab["humidifyFeedback"] = messageBytes[16]
        local temperature = messageBytes[17]
        if temperature ~= 0 then
            variableTab["temperatureFeedback"] = (temperature - 50) / 2
        else
            variableTab["temperatureFeedback"] = nil
        end
        variableTab["errorCode"] = messageBytes[21]
        variableTab["humidity"] = messageBytes[7]
        variableTab["humidifyMode"] = bit.band(bit.rshift(messageBytes[8], 4), 0x07)
        variableTab["lock"] = bit.band(messageBytes[8], 0x80)
        if bit.band(messageBytes[19], 0x40) == 0x40 then
            variableTab["waterions"] = uptable["BYTE_WATERIONS_ON"]
        else
            variableTab["waterions"] = uptable["BYTE_WATERIONS_OFF"]
        end
        if bit.band(messageBytes[19], 0x80) == 0x80 then
            variableTab["buzzer"] = uptable["BYTE_BUZZER_ON"]
        else
            variableTab["buzzer"] = uptable["BYTE_BUZZER_OFF"]
        end
        variableTab["voiceVolume"] = bit.band(messageBytes[22])
        variableTab["first_filter_percent"] = bit.band(messageBytes[23])
        variableTab["deep_filter_percent"] = bit.band(messageBytes[24])
        variableTab["pm25_out"] = (messageBytes[26] * 256) + messageBytes[25]
        variableTab["deepFilterReplaceNotice"] = bit.rshift(messageBytes[28], 7)
        variableTab["removableWaterBoxFlag"] = bit.band(bit.rshift(messageBytes[28], 4), 1)
        variableTab["waterLack"] = bit.band(bit.rshift(messageBytes[28], 5), 1)
        variableTab["detectMode"] = messageBytes[29]
        variableTab["pm10"] = messageBytes[32] * 256 + messageBytes[31]
        variableTab["hosting"] = bit.band(bit.rshift(messageBytes[34], 2), 0x03)
        variableTab["hostingUpper"] = messageBytes[35]
        variableTab["hostingLower"] = messageBytes[36]
        variableTab["hcho_level"] = bit.band(bit.rshift(messageBytes[34], 4), 0x07)
        variableTab["hcho"] = messageBytes[37] + messageBytes[38] * 256
        variableTab["sterilizeEnable"] = bit.band(messageBytes[40], 0x03)
        variableTab["sterilizeMinute"] = messageBytes[41]
        variableTab["uvEnable"] = bit.band(bit.rshift(messageBytes[40], 2), 0x03)
        variableTab["lightEnable"] = bit.band(bit.rshift(messageBytes[40], 4), 0x03)
        variableTab["storageFeedback"] = bit.band(bit.rshift(messageBytes[40], 6), 0x03)
        variableTab["chargeFeedback"] = bit.band(messageBytes[42], 0x03)
        variableTab["filterAirDry"] = bit.band(bit.rshift(messageBytes[42], 4), 0x03)
        variableTab["pureRateDisplay"] = bit.band(bit.rshift(messageBytes[42], 6), 0x03)
        variableTab["deepFilterACCTime"] = messageBytes[49] * 256 + messageBytes[48]
        variableTab["airDryLeftTime"] = messageBytes[50]
        local temp = messageBytes[51] + messageBytes[52] * 256
        if temp < 1001 then variableTab["purifyingRate"] = temp / 10 end
        variableTab["subMode"] = messageBytes[53]
        variableTab["biasGear"] = messageBytes[54]
        variableTab["batteryLevel"] = messageBytes[53]
        variableTab["pm1"] = messageBytes[62] * 256 + messageBytes[61]
        variableTab["lightColor"] = messageBytes[70]
        variableTab["vocValue"] = messageBytes[71] + messageBytes[72] * 256
        return 1
    end
end
local function assembleJsonByGlobalProperty(variableTab)
    local streams = {}
    streams["version"] = VALUE_VERSION
    if variableTab["queryProperty"] then
    else
        streams[uptable["KEY_POWER"]] = (variableTab["power"] == uptable["BYTE_POWER_ON"])
                and uptable["VALUE_COMMON_ON"]
            or uptable["VALUE_COMMON_OFF"]
        streams[uptable["KEY_DETECT"]] = (variableTab["detect"] == uptable["BYTE_DETECT_ON"])
                and uptable["VALUE_COMMON_ON"]
            or uptable["VALUE_COMMON_OFF"]
        streams[uptable["KEY_ANION"]] = (variableTab["anion"] == uptable["BYTE_ANION_ON"])
                and uptable["VALUE_COMMON_ON"]
            or uptable["VALUE_COMMON_OFF"]
        streams[uptable["KEY_BRIGHT"]] = variableTab["bright"]
        streams[uptable["KEY_LOCK"]] = (variableTab["lock"] == uptable["BYTE_LOCK_ON"]) and "on" or "off"
        streams[uptable["KEY_WATERIONS"]] = (variableTab["waterions"] == uptable["BYTE_WATERIONS_ON"]) and "on" or "off"
        streams[uptable["KEY_DETECT_MODE"]] = (variableTab["detectMode"] == uptable["BYTE_DETECT_PM25"]) and "pm25"
            or "hcho"
        streams[uptable["KEY_MODE"]] = getValueFromValueTab(uptable["VALUE_MODE_TAB"], variableTab["mode"], "none")
        streams[uptable["KEY_FAN_SPEED"]] = variableTab["fanSpeed"]
        streams[uptable["KEY_PM25"]] = variableTab["pm25"]
        streams[uptable["KEY_PM25_OUT"]] = variableTab["pm25_out"]
        streams[uptable["KEY_TVOC"]] = variableTab["tvoc"]
        streams[uptable["KEY_ASH_TVOC"]] = variableTab["ashTvoc"]
        streams[uptable["KEY_SMELL_TVOC"]] = variableTab["smellTvoc"]
        streams[uptable["KEY_ERROR_CODE"]] = variableTab["errorCode"]
        streams[uptable["KEY_HCHO"]] = variableTab["hcho"]
        streams["hcho_level"] = variableTab["hcho_level"]
        streams[uptable["KEY_HUMIDIFY_FEEDBACK"]] = variableTab["humidifyFeedback"]
        streams[uptable["KEY_BUZZER"]] = (variableTab["buzzer"] == uptable["BYTE_BUZZER_ON"])
                and uptable["VALUE_COMMON_ON"]
            or uptable["VALUE_COMMON_OFF"]
        streams[uptable["KEY_SCHEDULE_CLOSE_SWITCHER"]] = variableTab["scheduleCloseSwitcher"]
                and uptable["VALUE_COMMON_ON"]
            or uptable["VALUE_COMMON_OFF"]
        streams[uptable["KEY_SCHEDULE_CLOSE_TIME"]] = variableTab["scheduleCloseTime"]
        streams[uptable["KEY_FILTER_DEEP_ACC_TIME"]] = variableTab["filterDeep1ACCTime"]
        streams[uptable["KEY_SCHEDULE_OPEN_SWITCHER"]] = variableTab["scheduleOpenSwitcher"]
                and uptable["VALUE_COMMON_ON"]
            or uptable["VALUE_COMMON_OFF"]
        streams[uptable["KEY_SCHEDULE_OPEN_TIME"]] = variableTab["scheduleOpenTime"]
        if variableTab["hosting"] == uptable["BYTE_HOSTING_ON"] then
            streams[uptable["KEY_HOSTING"]] = uptable["VALUE_COMMON_ON"]
        elseif variableTab["hosting"] == uptable["BYTE_HOSTING_OFF"] then
            streams[uptable["KEY_HOSTING"]] = uptable["VALUE_COMMON_OFF"]
        end
        if variableTab["hostingUpper"] ~= nil then
            streams[uptable["KEY_HOSTING_UPPER"]] = variableTab["hostingUpper"]
        end
        if variableTab["hostingLower"] ~= nil then
            streams[uptable["KEY_HOSTING_LOWER"]] = variableTab["hostingLower"]
        end
        streams[uptable["KEY_FIRST_FILTER_PERCENT"]] = variableTab["first_filter_percent"]
        streams[uptable["KEY_DEEP_FILTER_PERCENT"]] = variableTab["deep_filter_percent"]
        streams[uptable["KEY_TEMPERATURE_FEEDBACK"]] = variableTab["temperatureFeedback"]
        if variableTab["sterilizeEnable"] == uptable["BYTE_STERILIZE_ENABLE_NONE"] then
            streams[uptable["KEY_STERILIZE_ENABLE"]] = uptable["VALUE_COMMON_NONE"]
        elseif variableTab["sterilizeEnable"] == uptable["BYTE_STERILIZE_ENABLE_ON"] then
            streams[uptable["KEY_STERILIZE_ENABLE"]] = uptable["VALUE_COMMON_ON"]
        elseif variableTab["sterilizeEnable"] == uptable["BYTE_STERILIZE_ENABLE_OFF"] then
            streams[uptable["KEY_STERILIZE_ENABLE"]] = uptable["VALUE_COMMON_OFF"]
        end
        if variableTab["sterilizeMinute"] ~= 0 then
            streams[uptable["KEY_STERILIZE_MINUTE"]] = uptable["sterilizeMinute"]
        end
        if variableTab["uvEnable"] == uptable["BYTE_UV_ENABLE_NONE"] then
            streams[uptable["KEY_UV_ENABLE"]] = uptable["VALUE_COMMON_NONE"]
        elseif variableTab["uvEnable"] == uptable["BYTE_UV_ENABLE_ON"] then
            streams[uptable["KEY_UV_ENABLE"]] = uptable["VALUE_COMMON_ON"]
        elseif variableTab["uvEnable"] == uptable["BYTE_UV_ENABLE_OFF"] then
            streams[uptable["KEY_UV_ENABLE"]] = uptable["VALUE_COMMON_OFF"]
        end
        if variableTab["lightEnable"] == uptable["BYTE_LIGHT_ENABLE_NONE"] then
            streams[uptable["KEY_LIGHT_ENABLE"]] = uptable["VALUE_COMMON_NONE"]
        elseif variableTab["lightEnable"] == uptable["BYTE_LIGHT_ENABLE_ON"] then
            streams[uptable["KEY_LIGHT_ENABLE"]] = uptable["VALUE_COMMON_ON"]
        elseif variableTab["lightEnable"] == uptable["BYTE_LIGHT_ENABLE_OFF"] then
            streams[uptable["KEY_LIGHT_ENABLE"]] = uptable["VALUE_COMMON_OFF"]
        elseif variableTab["lightEnable"] == uptable["BYTE_LIGHT_ENABLE_HALF"] then
            streams[uptable["KEY_LIGHT_ENABLE"]] = uptable["VALUE_LIGHT_ENABLE_HALF"]
        end
        if variableTab["filterAirDry"] == 0 then
            streams["filter_air_dry"] = uptable["VALUE_COMMON_NONE"]
        elseif variableTab["filterAirDry"] == 1 then
            streams["filter_air_dry"] = uptable["VALUE_COMMON_ON"]
        elseif variableTab["filterAirDry"] == 2 then
            streams["filter_air_dry"] = uptable["VALUE_COMMON_OFF"]
        end
        if variableTab["pureRateDisplay"] == 0 then
            streams["pure_rate_display"] = uptable["VALUE_COMMON_NONE"]
        elseif variableTab["pureRateDisplay"] == 1 then
            streams["pure_rate_display"] = uptable["VALUE_COMMON_ON"]
        elseif variableTab["pureRateDisplay"] == 2 then
            streams["pure_rate_display"] = uptable["VALUE_COMMON_OFF"]
        end
        if variableTab["storageFeedback"] == uptable["BYTE_STORAGE_FEEDBACK_NONE"] then
            streams[uptable["KEY_STORAGE_FEEDBACK"]] = uptable["VALUE_STORAGE_FEEDBACK_NONE"]
        elseif variableTab["storageFeedback"] == uptable["BYTE_STORAGE_FEEDBACK_NORMAL"] then
            streams[uptable["KEY_STORAGE_FEEDBACK"]] = uptable["VALUE_STORAGE_FEEDBACK_NORMAL"]
        elseif variableTab["storageFeedback"] == uptable["BYTE_STORAGE_FEEDBACK_PROTECT"] then
            streams[uptable["KEY_STORAGE_FEEDBACK"]] = uptable["VALUE_STORAGE_FEEDBACK_PROTECT"]
        end
        if variableTab["chargeFeedback"] == uptable["BYTE_CHARGE_FEEDBACK_NONE"] then
            streams[uptable["KEY_CHARGE_FEEDBACK"]] = uptable["VALUE_CHARGE_FEEDBACK_NONE"]
        elseif variableTab["chargeFeedback"] == uptable["BYTE_CHARGE_FEEDBACK_OFF"] then
            streams[uptable["KEY_CHARGE_FEEDBACK"]] = uptable["VALUE_CHARGE_FEEDBACK_OFF"]
        elseif variableTab["chargeFeedback"] == uptable["BYTE_CHARGE_FEEDBACK_STANDBY"] then
            streams[uptable["KEY_CHARGE_FEEDBACK"]] = uptable["VALUE_CHARGE_FEEDBACK_STANDBY"]
        elseif variableTab["chargeFeedback"] == uptable["BYTE_CHARGE_FEEDBACK_RUN"] then
            streams[uptable["KEY_CHARGE_FEEDBACK"]] = uptable["VALUE_CHARGE_FEEDBACK_RUN"]
        end
        if variableTab["deepFilterACCTime"] ~= nil then
            streams[uptable["KEY_FILTER_DEEP2_ACC_TIME"]] = variableTab["deepFilterACCTime"]
        end
        if variableTab["airDryLeftTime"] ~= nil then streams["air_dry_left_time"] = variableTab["airDryLeftTime"] end
        if variableTab["purifyingRate"] ~= nil then streams["purifying_rate"] = variableTab["purifyingRate"] end
        if variableTab["subMode"] ~= nil then
            streams["sub_mode"] = getValueFromValueTab(uptable["VALUE_SUB_MODE_TAB"], variableTab["subMode"], "invalid")
        end
        if variableTab["biasGear"] ~= nil then
            if variableTab["biasGear"] > 127 then
                streams["bias_gear"] = 128 - variableTab["biasGear"]
            else
                streams["bias_gear"] = variableTab["biasGear"]
            end
        end
        if variableTab["batteryLevel"] ~= nil then streams["battery_level"] = variableTab["batteryLevel"] end
        streams["pm1"] = variableTab["pm1"]
        streams["pm10"] = variableTab["pm10"]
        streams["deep_filter_replace"] = variableTab["deepFilterReplaceNotice"] == 1 and true or false
        streams["light_color"] =
            getValueFromValueTab(uptable["VALUE_LIGHT_COLOR_TAB"], variableTab["lightColor"], "invalid")
        streams["voc_value"] = variableTab["vocValue"]
        streams["removable_water_box"] = variableTab["removableWaterBoxFlag"] == 1 and true or false
        streams["water_lack"] = variableTab["waterLack"] == 1 and true or false
        streams[uptable["KEY_SET_HUMIDITY"]] = variableTab["humidity"]
    end
    return streams
end
local function makeCode(msgTx)
    local chk = 0
    local length = #msgTx
    for i = 2, length - 1 do
        chk = chk + msgTx[i]
    end
    msgTx[length] = (256 - chk % 256) % 256
    local strTx = ""
    for i = 1, #msgTx do
        strTx = strTx .. string.format("%02X", msgTx[i])
    end
    return strTx
end
local function propertiesSetting(control)
    local ok, result
    if control then
        local totalMsgLength, subCmd, propertiesNum, propertyCode, propertyValueLength
        local propertyValues = {}
        propertiesNum = 1
        if control.filter or control.filter_set then
            subCmd = 0xb0
            if control.filter then
                if control.filter == "first" then
                    propertyCode = 0x0402
                    propertyValueLength = 1
                elseif control.filter == "deep" then
                    propertyValueLength = 1
                    propertyCode = 0x0401
                end
                propertyValues[1] = 1
            elseif control.filter_set then
                propertyCode = 0x0501
                propertyValueLength = 1
                if control.filter_set == "deep" then
                    propertyValues[1] = 1
                elseif control.filter_set == "hcho" then
                    propertyValues[1] = 2
                else
                    propertyValues[1] = 3
                end
            end
        end
        if subCmd then
            totalMsgLength = 16 + propertyValueLength
            local msgTx = {
                0xAA,
                0x00,
                0xFC,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x02,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            }
            msgTx[2] = totalMsgLength - 1
            msgTx[11] = subCmd
            msgTx[12] = propertiesNum
            msgTx[13] = bit.band(propertyCode, 0xFF)
            msgTx[14] = bit.rshift(propertyCode, 8)
            msgTx[15] = propertyValueLength
            for i = 1, propertyValueLength do
                msgTx[15 + i] = propertyValues[i]
            end
            msgTx[totalMsgLength] = 0
            result = makeCode(msgTx)
            ok = true
        end
    end
    return ok, result
end
local function getQueryCmd(query)
    local msgTx = { 0xAA, 0x00, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xb1, 0x01, 0x00, 0x00, 0x00, 0x00 }
    local subCmd, propertyCode
    local totalMsgLength = 16
    for k, v in pairs(query) do
        if k == "query_type" then
        else
        end
    end
    if subCmd then
        msgTx[2] = totalMsgLength - 1
        msgTx[11] = subCmd
        msgTx[13] = bit.band(propertyCode, 0xFF)
        msgTx[14] = bit.rshift(propertyCode, 8)
        msgTx[15] = crc8_854(msgTx, 11, totalMsgLength - 1)
        msgTx[totalMsgLength] = 0
    else
        msgTx = {
            0xAA,
            0x20,
            0xFC,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x03,
            0x41,
            0x21,
            0x00,
            0xff,
            0x00,
            0x00,
            0x00,
            0x02,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
        }
        totalMsgLength = 33
        msgTx[2] = totalMsgLength - 1
        msgTx[11] = 0x41
        msgTx[12] = 0x21
        msgTx[14] = 0xff
        msgTx[18] = 2
        msgTx[totalMsgLength - 1] = crc8_854(msgTx, 11, totalMsgLength - 2)
    end
    return makeCode(msgTx)
end
function jsonToData(jsonCmdStr)
    if #jsonCmdStr == 0 then return nil end
    local msgBytes
    local bodyLength
    local bodyBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if control then
        local ok, result = propertiesSetting(control)
        if ok then return result end
        local variableTab = initVariableTab()
        if status then noInvalidValueMerge(status, variableTab) end
        if control then updateGlobalPropertyValueByJson(control, variableTab) end
        bodyLength = 30
        for i = 0, bodyLength - 1 do
            bodyBytes[i] = 0
        end
        bodyBytes[0] = 0x48
        bodyBytes[1] = bit.bor(bit.bor(variableTab["power"], 0x40), 0x02)
        if control.silence_ctrl ~= nil and control.silence_ctrl == "enable" then
            bodyBytes[1] = bit.bor(bodyBytes[1], 0x04)
        end
        bodyBytes[2] = bit.lshift(variableTab["mode"], 4)
        if variableTab["scheduleTimeValidate"] then
            bodyBytes[3] = bit.bor(variableTab["fanSpeed"], 0x80)
        else
            bodyBytes[3] = variableTab["fanSpeed"]
        end
        bodyBytes[1] = bit.bor(bodyBytes[1], variableTab["detect"])
        bodyBytes[14] = variableTab["detectMode"]
        local timingOffMul15 = math.floor(variableTab["scheduleCloseTime"] / 15)
        local timingOffLeft15 = 15 - variableTab["scheduleCloseTime"] % 15
        if variableTab["scheduleCloseSwitcher"] then
            bodyBytes[5] = bit.bor(uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON"], timingOffMul15)
            bodyBytes[6] = bit.bor(bodyBytes[6], timingOffLeft15)
        else
            bodyBytes[5] = uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_OFF"]
        end
        local timingOnMul15 = math.floor(variableTab["scheduleOpenTime"] / 15)
        local timingOnLeft15 = 15 - variableTab["scheduleOpenTime"] % 15
        if variableTab["scheduleOpenSwitcher"] then
            bodyBytes[4] = bit.bor(uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_ON"], timingOnMul15)
            bodyBytes[6] = bit.bor(bodyBytes[6], bit.lshift(timingOnLeft15, 4))
        else
            bodyBytes[4] = uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_OFF"]
        end
        bodyBytes[7] = bit.band(variableTab["humidity"], 0x7f)
        bodyBytes[8] = variableTab["lock"]
        bodyBytes[9] = bit.bor(variableTab["anion"], variableTab["bright"])
        bodyBytes[10] = bit.band(variableTab["humidifyMode"], 0x07)
        bodyBytes[10] = bit.bor(bodyBytes[10], variableTab["buzzer"])
        bodyBytes[10] = bit.bor(bodyBytes[10], variableTab["waterions"])
        bodyBytes[12] = variableTab["voiceVolume"]
        if variableTab["hosting"] then bodyBytes[15] = bit.lshift(variableTab["hosting"], 2) end
        if variableTab["pureRateDisplay"] then
            bodyBytes[15] = bit.bor(bodyBytes[15], bit.lshift(variableTab["pureRateDisplay"], 4))
        end
        if variableTab["hostingUpper"] then bodyBytes[16] = variableTab["hostingUpper"] end
        if variableTab["hostingLower"] then bodyBytes[17] = variableTab["hostingLower"] end
        bodyBytes[19] = variableTab["sterilizeEnable"]
        bodyBytes[20] = variableTab["sterilizeMinute"]
        bodyBytes[19] = bit.bor(bodyBytes[19], bit.lshift(variableTab["uvEnable"], 2))
        bodyBytes[19] = bit.bor(bodyBytes[19], bit.lshift(variableTab["lightEnable"], 4))
        bodyBytes[21] = bit.bor(bodyBytes[21], variableTab["filterAirDry"])
        bodyBytes[22] = variableTab["subMode"]
        if variableTab["biasGear"] < 0 then
            bodyBytes[23] = 0x80
            variableTab["biasGear"] = variableTab["biasGear"] * -1
        end
        bodyBytes[23] = bodyBytes[23] + variableTab["biasGear"]
        bodyBytes[27] = variableTab["lightColor"]
        math.randomseed(tostring(os.time() * #bodyBytes):reverse():sub(1, 7))
        bodyBytes[bodyLength - 2] = math.random(1, 254)
        bodyBytes[bodyLength - 1] = crc8_854(bodyBytes, 0, bodyLength - 2)
        msgBytes = assembleUart(bodyBytes, uptable["BYTE_CONTROL_REQUEST"])
    elseif query then
        return getQueryCmd(query)
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
local function decodeProperties(byteData)
    local subCmd = byteData[11]
    if subCmd ~= 0xb0 and subCmd ~= 0xb1 and subCmd ~= 0xb2 then return false, nil end
    local result = {}
    result.status = {}
    result.status.version = VALUE_VERSION
    local propertyCode
    propertyCode = byteData[13] + byteData[14] * 256
    result.status.result = uptable["VALUE_PROPERTY_EXECUTE_TAB"][byteData[15]]
    if subCmd == 0xb0 or subCmd == 0xb1 then
        if propertyCode == 0x0401 then
        elseif propertyCode == 0x0402 then
        elseif propertyCode == 0x0501 then
            result.status.filter_set = (byteData[17] == 1) and "deep" or "hcho"
        end
    elseif subCmd == 0xb2 then
        if propertyCode == 1 then
            result.status.voice_volume_control_type =
                getValueFromValueTab(uptable["VALUE_VOICE_VOLUME_TYPE_TAB"], byteData[17], "invalid")
            result.status.voice_volume = byteData[18]
            result.status.min_voice_volume = byteData[19]
            result.status.max_voice_volume = byteData[20]
            result.status.voice_type = uptable["VALUE_VOICE_TYPE_TAB"][byteData[21]]
            result.status.language = uptable["VALUE_LANGUAGE_TAB"][byteData[22]]
        elseif propertyCode == 3 then
        end
    end
    return true, encodeTableToJson(result)
end
function dataToJson(jsonStr)
    if not jsonStr then return nil end
    local json = decodeJsonToTable(jsonStr)
    local binData = json["msg"]["data"]
    local status = json["status"]
    local bodyBytes = {}
    local byteData = string2table(binData)
    local isProperties, result = decodeProperties(byteData)
    if isProperties then return result end
    local variableTab = initVariableTab()
    variableTab["dataType"] = byteData[10]
    bodyBytes = extractBodyBytes(byteData)
    local err, ret = pcall(updateGlobalPropertyValueByByte, bodyBytes, variableTab)
    local retTable = {}
    if ret ~= nil then
        retTable["status"] = assembleJsonByGlobalProperty(variableTab)
    else
        retTable["status"] = status
    end
    local ret = encodeTableToJson(retTable)
    return ret
end
