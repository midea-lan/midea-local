local bit = require "bit"
local JSON = require "cjson"
require "bit"
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_REPORT_NACK = 0x04
local BYTE_REPORT_ACK = 0x05
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_PRODUCT_TYPE = 0x26
local VALUE_UNKNOWN = "unknown"
local VALUE_INVALID = "invalid"
local dataType = 0
local cmdType = 0
local keytable = {}
keytable["KEY_VERSION"] = "version"
keytable["KEY_SUB_PACKET_TYPE"] = "subpacket_type"
keytable["KEY_NEED_ACK"] = "need_ack"
keytable["KEY_RESULT"] = "result"
keytable["KEY_HARDWARE_VERSION"] = "hardware_version"
keytable["KEY_SOFTWARE_VERSION"] = "software_version"
keytable["KEY_LIGHT_MODE"] = "light_mode"
keytable["KEY_MAIN_LIGHT_BRIGHTNESS"] = "main_light_brightness"
keytable["KEY_NIGHT_LIGHT_BRIGHTNESS"] = "night_light_brightness"
keytable["KEY_RADAR_INDUCTION_ENABLE"] = "radar_induction_enable"
keytable["KEY_RADAR_INDUCTION_CLOSING_TIME"] = "radar_induction_closing_time"
keytable["KEY_LIGHT_INTENSITY_THRESHOLD"] = "light_intensity_threshold"
keytable["KEY_RADAR_SENSITIVITY"] = "radar_sensitivity"
keytable["KEY_MODE"] = "mode"
keytable["KEY_MODE_ENABLE"] = "mode_enable"
keytable["KEY_MODE_CLOSE"] = "mode_close"
keytable["KEY_HEATING_TEMPERATURE"] = "heating_temperature"
keytable["KEY_HEATING_SPEED"] = "heating_speed"
keytable["KEY_HEATING_DIRECTION"] = "heating_direction"
keytable["KEY_BATH_HEATING_TIME"] = "bath_heating_time"
keytable["KEY_BATH_TEMPERATURE"] = "bath_temperature"
keytable["KEY_BATH_SPEED"] = "bath_speed"
keytable["KEY_BATH_DIRECTION"] = "bath_direction"
keytable["KEY_SOFT_WIND_HEATING_TIME"] = "soft_wind_heating_time"
keytable["KEY_SOFT_WIND_TEMPERATURE"] = "soft_wind_temperature"
keytable["KEY_SOFT_WIND_SPEED"] = "soft_wind_speed"
keytable["KEY_SOFT_WIND_DIRECTION"] = "soft_wind_direction"
keytable["KEY_VENTILATION_SPEED"] = "ventilation_speed"
keytable["KEY_VENTILATION_DIRECTION"] = "ventilation_direction"
keytable["KEY_DRYING_TIME"] = "drying_time"
keytable["KEY_DRYING_TEMPERATURE"] = "drying_temperature"
keytable["KEY_DRYING_SPEED"] = "drying_speed"
keytable["KEY_DRYING_DIRECTION"] = "drying_direction"
keytable["KEY_BLOWING_SPEED"] = "blowing_speed"
keytable["KEY_BLOWING_DIRECTION"] = "blowing_direction"
keytable["KEY_DELAY_ENABLE"] = "delay_enable"
keytable["KEY_DELAY_TIME"] = "delay_time"
keytable["KEY_WINDLESS_ENABLE"] = "windless_enable"
keytable["KEY_ANION_ENABLE"] = "anion_enable"
keytable["KEY_SMELLY_ENABLE"] = "smelly_enable"
keytable["KEY_SMELLY_TRIGGER"] = "smelly_trigger"
keytable["KEY_SMELLY_THRESHOLD"] = "smelly_threshold"
keytable["KEY_TIMING1_ENABLE"] = "timing1_enable"
keytable["KEY_TIMING1_FUNCTION"] = "timing1_function"
keytable["KEY_TIMING1_DATE_REPEAT"] = "timing1_date_repeat"
keytable["KEY_TIMING1_OPENINT_TIME"] = "timing1_opening_time"
keytable["KEY_TIMING1_CLOSING_TIME"] = "timing1_closing_time"
keytable["KEY_TIMING2_ENABLE"] = "timing2_enable"
keytable["KEY_TIMING2_FUNCTION"] = "timing2_function"
keytable["KEY_TIMING2_DATE_REPEAT"] = "timing2_date_repeat"
keytable["KEY_TIMING2_OPENINT_TIME"] = "timing2_opening_time"
keytable["KEY_TIMING2_CLOSING_TIME"] = "timing2_closing_time"
keytable["KEY_TIMING3_ENABLE"] = "timing3_enable"
keytable["KEY_TIMING3_FUNCTION"] = "timing3_function"
keytable["KEY_TIMING3_DATE_REPEAT"] = "timing3_date_repeat"
keytable["KEY_TIMING3_OPENINT_TIME"] = "timing3_opening_time"
keytable["KEY_TIMING3_CLOSING_TIME"] = "timing3_closing_time"
keytable["KEY_TIMING4_ENABLE"] = "timing4_enable"
keytable["KEY_TIMING4_FUNCTION"] = "timing4_function"
keytable["KEY_TIMING4_DATE_REPEAT"] = "timing4_date_repeat"
keytable["KEY_TIMING4_OPENINT_TIME"] = "timing4_opening_time"
keytable["KEY_TIMING4_CLOSING_TIME"] = "timing4_closing_time"
keytable["KEY_TIMING5_ENABLE"] = "timing5_enable"
keytable["KEY_TIMING5_FUNCTION"] = "timing5_function"
keytable["KEY_TIMING5_DATE_REPEAT"] = "timing5_date_repeat"
keytable["KEY_TIMING5_OPENINT_TIME"] = "timing5_opening_time"
keytable["KEY_TIMING5_CLOSING_TIME"] = "timing5_closing_time"
keytable["KEY_CLEAN_FILTER"] = "clean_filter"
keytable["KEY_CURRENT_LIGHT_INTENSITY"] = "current_light_intensity"
keytable["KEY_CURRENT_RADAR_STATUS"] = "current_radar_status"
keytable["KEY_CURRENT_TEMPERATURE"] = "current_temperature"
keytable["KEY_FILTER_STATUS"] = "filter_status"
keytable["KEY_REMOTE_LOW_POWER"] = "remote_low_power"
keytable["KEY_REMOTE_POWER"] = "remote_power"
keytable["KEY_SMELLY_LEVEL"] = "smelly_level"
keytable["KEY_CURRENT_HUMIDITY"] = "current_humidity"
keytable["KEY_DEHUMIDITY_TRIGGER"] = "dehumidity_trigger"
keytable["KEY_AUTO_DEHUMIDIFICATION"] = "auto_dehumidification"
keytable["KEY_DEHUMIDITY_THRESHOLD"] = "dehumidity_threshold"
keytable["KEY_DEHUMIDITY_TIME"] = "dehumidity_time"
keytable["KEY_DEHUMIDITY_INTERVAL_TIME"] = "dehumidity_interval_time"
keytable["KEY_DEHUMIDITY_DIRECTION"] = "dehumidity_direction"
keytable["KEY_WIFI_LED_ENABLE"] = "wifi_led_enable"
keytable["KEY_FUNCTION_LED_ENABLE"] = "function_led_enable"
keytable["KEY_DIGIT_LED_ENABLE"] = "digit_led_enable"
local valuetable = {}
local VALUE_VERSION = "12"
local VALUE_SUCCESS = "success"
local VALUE_FAIL = "fail"
local VALUE_FUNCTION_ON = "on"
local VALUE_FUNCTION_OFF = "off"
local VALUE_FUNCTION_SETTING = "function_setting"
local VALUE_TIMING_SETTING = "timing_setting"
local VALUE_FUNCTION_QUERY = "function_query"
local VALUE_TIMING_QUERY = "timing_query"
local VALUE_VERSION_QUERY = "version_query"
local VALUE_FUNCTION_REPORT = "function_report"
local VALUE_TIMING_REPORT = "timing_report"
local VALUE_VERSION_REPORT = "version_report"
local VALUE_FUNCTION_MAIN_LIGHT = "main_light"
local VALUE_FUNCTION_NIGHT_LIGHT = "night_light"
local VALUE_FUNCTION_HEATING_HIGHT = "strong_heating"
local VALUE_FUNCTION_HEATING_LOW = "weak_heating"
local VALUE_FUNCTION_HEATING = "heating"
local VALUE_FUNCTION_BATH = "bath"
local VALUE_FUNCTION_SOFT_WIND = "soft_wind"
local VALUE_FUNCTION_VENTILATION = "ventilation"
local VALUE_FUNCTION_MORNING_VENTILATION = "morning_ventilation"
local VALUE_FUNCTION_DRYING = "drying"
local VALUE_FUNCTION_BLOWING = "blowing"
local VALUE_FUNCTION_DRYING_SAFE_POWER = "drying_safe_power"
local VALUE_FUNCTION_DRYING_FAST = "drying_fast"
local VALUE_FUNCTION_CLOSE_ALL = "close_all"
local function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do msgBytes[i - 1] = byteData[i] end
    local bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    return bodyBytes
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
end
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if bodyLength == 0 then return nil end
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_PRODUCT_TYPE
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    msgBytes[msgLength - 1] = makeSum(msgBytes, 1, msgLength - 2)
    return msgBytes
end
local crc8_854_table = {
    0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65, 157,
    195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220, 35, 125,
    159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98, 190, 224, 2,
    92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255, 70, 24, 250, 164,
    39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7, 219, 133, 103, 57,
    186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154, 101, 59, 217, 135, 4,
    90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36, 248, 166, 68, 26, 153,
    199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185, 140, 210, 48, 110, 237,
    179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205, 17, 79, 173, 243, 112, 46,
    204, 146, 211, 141, 111, 49, 178, 236, 14, 80, 175, 241, 19, 77, 206, 144,
    114, 44, 109, 51, 209, 143, 12, 82, 176, 238, 50, 108, 142, 208, 83, 13,
    239, 177, 240, 174, 76, 18, 145, 207, 45, 115, 202, 148, 118, 40, 171, 245,
    23, 73, 8, 86, 180, 234, 105, 55, 213, 139, 87, 9, 235, 181, 54, 104, 138,
    212, 149, 203, 41, 119, 244, 170, 72, 22, 233, 183, 85, 11, 136, 214, 52,
    106, 43, 117, 151, 201, 74, 20, 246, 168, 116, 42, 200, 150, 21, 75, 169,
    247, 182, 232, 10, 84, 215, 137, 107, 53
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
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end
local function string2hexstring(str)
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end
local function checkBoundary(data, min, max)
    if (not data) then data = 0 end
    data = tonumber(data)
    if ((data >= min) and (data <= max)) then
        return data
    else
        if (data < min) then
            return min
        else
            return max
        end
    end
end
local function string2Int(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end
local function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = "0" end
    return data
end
local function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then k = string.format("%q", k) end
        local szSuffix = ""
        if type(v) == "table" then szSuffix = "{" end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix .. "[" .. k .. "]" .. " = " .. szSuffix
        if type(v) == "table" then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix .. "},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting .. szValue .. ",")
        end
    end
end
local function valueTableInitialization()
    valuetable["MAIN_LIGHT_ENABLE"] = 0xFF
    valuetable["MAIN_LIGHT_BRIGHTNESS"] = 0xFF
    valuetable["NIGHT_LIGHT_ENABLE"] = 0xFF
    valuetable["NIGHT_LIGHT_BRIGHTNESS"] = 0xFF
    valuetable["RADAR_INDUCTION_ENABLE"] = 0xFF
    valuetable["RADAR_INDUCTION_CLOSING_TIME"] = 0xFF
    valuetable["LIGHT_INTENSITY_THRESHOLD"] = 0xFF
    valuetable["RADAR_SENSITIVITY"] = 0xFF
    valuetable["HEATING_ENABLE"] = 0xFF
    valuetable["HEATING_TEMPERATURE"] = 0xFF
    valuetable["HEATING_SPEED"] = 0xFF
    valuetable["HEATING_DIRECTION"] = 0xFF
    valuetable["BATH_ENABLE"] = 0xFF
    valuetable["BATH_HEATING_TIME"] = 0xFF
    valuetable["BATH_TEMPERATURE"] = 0xFF
    valuetable["BATH_SPEED"] = 0xFF
    valuetable["BATH_DIRECTION"] = 0xFF
    valuetable["SOFT_WIND_ENABLE"] = 0xFF
    valuetable["SOFT_WIND_HEATING_TIME"] = 0xFF
    valuetable["SOFT_WIND_TEMPERATURE"] = 0xFF
    valuetable["SOFT_WIND_SPEED"] = 0xFF
    valuetable["SOFT_WIND_DIRECTION"] = 0xFF
    valuetable["VENTILATION_ENABLE"] = 0xFF
    valuetable["MORNING_VENTILATION_ENABLE"] = 0xFF
    valuetable["VENTILATION_SPEED"] = 0xFF
    valuetable["VENTILATION_DIRECTION"] = 0xFF
    valuetable["DRYING_ENABLE"] = 0xFF
    valuetable["DRYING_TIME"] = 0xFF
    valuetable["DRYING_TEMPERATURE"] = 0xFF
    valuetable["DRYING_SPEED"] = 0xFF
    valuetable["DRYING_DIRECTION"] = 0xFF
    valuetable["BLOWING_ENABLE"] = 0xFF
    valuetable["BLOWING_SPEED"] = 0xFF
    valuetable["BLOWING_DIRECTION"] = 0xFF
    valuetable["DELAY_ENABLE"] = 0xFF
    valuetable["DELAY_TIME"] = 0xFF
    valuetable["WINDLESS_ENABLE"] = 0xFF
    valuetable["ANION_ENABLE"] = 0xFF
    valuetable["SMELLY_ENABLE"] = 0xFF
    valuetable["SMELLY_THRESHOLD"] = 0xFF
    valuetable["TIMING1_ENABLE"] = 0xFF
    valuetable["TIMING1_FUNCTION"] = 0xFF
    valuetable["TIMING1_DATE_REPEAT"] = 0xFF
    valuetable["TIMING1_OPENINT_TIME_HOUR"] = 0xFF
    valuetable["TIMING1_OPENINT_TIME_MIN"] = 0xFF
    valuetable["TIMING1_CLOSING_TIME_HOUR"] = 0xFF
    valuetable["TIMING1_CLOSING_TIME_MIN"] = 0xFF
    valuetable["TIMING2_ENABLE"] = 0xFF
    valuetable["TIMING2_FUNCTION"] = 0xFF
    valuetable["TIMING2_DATE_REPEAT"] = 0xFF
    valuetable["TIMING2_OPENINT_TIME_HOUR"] = 0xFF
    valuetable["TIMING2_OPENINT_TIME_MIN"] = 0xFF
    valuetable["TIMING2_CLOSING_TIME_HOUR"] = 0xFF
    valuetable["TIMING2_CLOSING_TIME_MIN"] = 0xFF
    valuetable["TIMING3_ENABLE"] = 0xFF
    valuetable["TIMING3_FUNCTION"] = 0xFF
    valuetable["TIMING3_DATE_REPEAT"] = 0xFF
    valuetable["TIMING3_OPENINT_TIME_HOUR"] = 0xFF
    valuetable["TIMING3_OPENINT_TIME_MIN"] = 0xFF
    valuetable["TIMING3_CLOSING_TIME_HOUR"] = 0xFF
    valuetable["TIMING3_CLOSING_TIME_MIN"] = 0xFF
    valuetable["TIMING4_ENABLE"] = 0xFF
    valuetable["TIMING4_FUNCTION"] = 0xFF
    valuetable["TIMING4_DATE_REPEAT"] = 0xFF
    valuetable["TIMING4_OPENINT_TIME_HOUR"] = 0xFF
    valuetable["TIMING4_OPENINT_TIME_MIN"] = 0xFF
    valuetable["TIMING4_CLOSING_TIME_HOUR"] = 0xFF
    valuetable["TIMING4_CLOSING_TIME_MIN"] = 0xFF
    valuetable["TIMING5_ENABLE"] = 0xFF
    valuetable["TIMING5_FUNCTION"] = 0xFF
    valuetable["TIMING5_DATE_REPEAT"] = 0xFF
    valuetable["TIMING5_OPENINT_TIME_HOUR"] = 0xFF
    valuetable["TIMING5_OPENINT_TIME_MIN"] = 0xFF
    valuetable["TIMING5_CLOSING_TIME_HOUR"] = 0xFF
    valuetable["TIMING5_CLOSING_TIME_MIN"] = 0xFF
    valuetable["CLEAN_FILTER"] = 0xFF
    valuetable["CURRENT_LIGHT_INTENSITY"] = 0xFF
    valuetable["CURRENT_RADAR_STATUS"] = 0xFF
    valuetable["CURRENT_TEMPERATURE"] = 0xFF
    valuetable["FILTER_STATUS"] = 0xFF
    valuetable["REMOTE_LOW_POWER"] = 0xFF
    valuetable["REMOTE_POWER"] = 0xFF
    valuetable["SMELLY_LEVEL"] = 0xFF
    valuetable["CURRENT_HUMIDITY"] = 0xFF
    valuetable["AUTO_DEHUMIDIFICATION"] = 0xFF
    valuetable["DEHUMIDITY_THRESHOLD"] = 0xFF
    valuetable["DEHUMIDITY_TIME"] = 0xFF
    valuetable["DEHUMIDITY_INTERVAL_TIME"] = 0xFF
    valuetable["DEHUMIDITY_DIRECTION"] = 0xFF
    valuetable["WIFI_LED_ENABLE"] = 0xFF
    valuetable["FUNCTION_LED_ENABLE"] = 0xFF
    valuetable["DIGIT_LED_ENABLE"] = 0xFF
    valuetable["HARDWARE_VERSION"] = ""
    valuetable["SOFTWARE_VERSION"] = ""
end
local function updateGlobalPropertyValueByJson(luaTable)
    valueTableInitialization()
    if (luaTable[keytable["KEY_SUB_PACKET_TYPE"]] == nil or
        luaTable[keytable["KEY_SUB_PACKET_TYPE"]] == "" or
        luaTable[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_FUNCTION_SETTING or
        luaTable[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_FUNCTION_QUERY) then
        cmdType = 0x01
    elseif (luaTable[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_TIMING_SETTING or
        luaTable[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_TIMING_QUERY) then
        cmdType = 0x02
    end
    if (luaTable[keytable["KEY_LIGHT_MODE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_LIGHT_MODE"]],
                        VALUE_FUNCTION_MAIN_LIGHT) ~= nil) then
            valuetable["MAIN_LIGHT_ENABLE"] = 0x01
        else
            valuetable["MAIN_LIGHT_ENABLE"] = 0x00
        end
    end
    if luaTable[keytable["KEY_MAIN_LIGHT_BRIGHTNESS"]] ~= nil then
        valuetable["MAIN_LIGHT_BRIGHTNESS"] = string2Int(
                                                  luaTable[keytable["KEY_MAIN_LIGHT_BRIGHTNESS"]])
    end
    if (luaTable[keytable["KEY_LIGHT_MODE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_LIGHT_MODE"]],
                        VALUE_FUNCTION_NIGHT_LIGHT) ~= nil) then
            valuetable["NIGHT_LIGHT_ENABLE"] = 0x01
        else
            valuetable["NIGHT_LIGHT_ENABLE"] = 0x00
        end
    end
    if luaTable[keytable["KEY_NIGHT_LIGHT_BRIGHTNESS"]] ~= nil then
        valuetable["NIGHT_LIGHT_BRIGHTNESS"] = string2Int(
                                                   luaTable[keytable["KEY_NIGHT_LIGHT_BRIGHTNESS"]])
    end
    if (luaTable[keytable["KEY_RADAR_INDUCTION_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["RADAR_INDUCTION_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_RADAR_INDUCTION_ENABLE"]] ==
        VALUE_FUNCTION_OFF) then
        valuetable["RADAR_INDUCTION_ENABLE"] = 0x00
    end
    if luaTable[keytable["KEY_RADAR_INDUCTION_CLOSING_TIME"]] ~= nil then
        valuetable["RADAR_INDUCTION_CLOSING_TIME"] = string2Int(
                                                         luaTable[keytable["KEY_RADAR_INDUCTION_CLOSING_TIME"]])
    end
    if (luaTable[keytable["KEY_MODE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE"]], VALUE_FUNCTION_HEATING) ~=
            nil) then
            valuetable["HEATING_ENABLE"] = 0x01
        else
            valuetable["HEATING_ENABLE"] = 0x00
        end
    end
    if (luaTable[keytable["KEY_MODE_ENABLE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_ENABLE"]],
                        VALUE_FUNCTION_HEATING) ~= nil) then
            valuetable["HEATING_ENABLE"] = 0x01
        end
    end
    if (luaTable[keytable["KEY_MODE_CLOSE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_CLOSE"]],
                        VALUE_FUNCTION_HEATING) ~= nil) then
            valuetable["HEATING_ENABLE"] = 0x00
        end
    end
    if luaTable[keytable["KEY_HEATING_TEMPERATURE"]] ~= nil then
        valuetable["HEATING_TEMPERATURE"] = string2Int(
                                                luaTable[keytable["KEY_HEATING_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_HEATING_SPEED"]] ~= nil then
        valuetable["HEATING_SPEED"] = string2Int(
                                          luaTable[keytable["KEY_HEATING_SPEED"]])
    end
    if luaTable[keytable["KEY_HEATING_DIRECTION"]] ~= nil then
        valuetable["HEATING_DIRECTION"] = string2Int(
                                              luaTable[keytable["KEY_HEATING_DIRECTION"]])
    end
    if (luaTable[keytable["KEY_MODE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE"]], VALUE_FUNCTION_BATH) ~=
            nil) then
            valuetable["BATH_ENABLE"] = 0x01
        else
            valuetable["BATH_ENABLE"] = 0x00
        end
    end
    if (luaTable[keytable["KEY_MODE_ENABLE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_ENABLE"]],
                        VALUE_FUNCTION_BATH) ~= nil) then
            valuetable["BATH_ENABLE"] = 0x01
        end
    end
    if (luaTable[keytable["KEY_MODE_CLOSE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_CLOSE"]],
                        VALUE_FUNCTION_BATH) ~= nil) then
            valuetable["BATH_ENABLE"] = 0x00
        end
    end
    if luaTable[keytable["KEY_BATH_HEATING_TIME"]] ~= nil then
        valuetable["BATH_HEATING_TIME"] = string2Int(
                                              luaTable[keytable["KEY_BATH_HEATING_TIME"]])
    end
    if luaTable[keytable["KEY_BATH_TEMPERATURE"]] ~= nil then
        valuetable["BATH_TEMPERATURE"] = string2Int(
                                             luaTable[keytable["KEY_BATH_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_BATH_SPEED"]] ~= nil then
        valuetable["BATH_SPEED"] = string2Int(
                                       luaTable[keytable["KEY_BATH_SPEED"]])
    end
    if luaTable[keytable["KEY_BATH_DIRECTION"]] ~= nil then
        valuetable["BATH_DIRECTION"] = string2Int(
                                           luaTable[keytable["KEY_BATH_DIRECTION"]])
    end
    if (luaTable[keytable["KEY_MODE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE"]], VALUE_FUNCTION_SOFT_WIND) ~=
            nil) then
            valuetable["SOFT_WIND_ENABLE"] = 0x01
        else
            valuetable["SOFT_WIND_ENABLE"] = 0x00
        end
    end
    if (luaTable[keytable["KEY_MODE_ENABLE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_ENABLE"]],
                        VALUE_FUNCTION_SOFT_WIND) ~= nil) then
            valuetable["SOFT_WIND_ENABLE"] = 0x01
        end
    end
    if (luaTable[keytable["KEY_MODE_CLOSE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_CLOSE"]],
                        VALUE_FUNCTION_SOFT_WIND) ~= nil) then
            valuetable["SOFT_WIND_ENABLE"] = 0x00
        end
    end
    if luaTable[keytable["KEY_SOFT_WIND_HEATING_TIME"]] ~= nil then
        valuetable["SOFT_WIND_HEATING_TIME"] = string2Int(
                                                   luaTable[keytable["KEY_SOFT_WIND_HEATING_TIME"]])
    end
    if luaTable[keytable["KEY_SOFT_WIND_TEMPERATURE"]] ~= nil then
        valuetable["SOFT_WIND_TEMPERATURE"] = string2Int(
                                                  luaTable[keytable["KEY_SOFT_WIND_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_SOFT_WIND_SPEED"]] ~= nil then
        valuetable["SOFT_WIND_SPEED"] = string2Int(
                                            luaTable[keytable["KEY_SOFT_WIND_SPEED"]])
    end
    if luaTable[keytable["KEY_SOFT_WIND_DIRECTION"]] ~= nil then
        valuetable["SOFT_WIND_DIRECTION"] = string2Int(
                                                luaTable[keytable["KEY_SOFT_WIND_DIRECTION"]])
    end
    if (luaTable[keytable["KEY_MODE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE"]],
                        VALUE_FUNCTION_VENTILATION) ~= nil) then
            valuetable["VENTILATION_ENABLE"] = 0x01
        else
            valuetable["VENTILATION_ENABLE"] = 0x00
        end
    end
    if (luaTable[keytable["KEY_MODE_ENABLE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_ENABLE"]],
                        VALUE_FUNCTION_VENTILATION) ~= nil) then
            valuetable["VENTILATION_ENABLE"] = 0x01
        end
    end
    if (luaTable[keytable["KEY_MODE_CLOSE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_CLOSE"]],
                        VALUE_FUNCTION_VENTILATION) ~= nil) then
            valuetable["VENTILATION_ENABLE"] = 0x00
        end
    end
    if luaTable[keytable["KEY_VENTILATION_SPEED"]] ~= nil then
        valuetable["VENTILATION_SPEED"] = string2Int(
                                              luaTable[keytable["KEY_VENTILATION_SPEED"]])
    end
    if luaTable[keytable["KEY_VENTILATION_DIRECTION"]] ~= nil then
        valuetable["VENTILATION_DIRECTION"] = string2Int(
                                                  luaTable[keytable["KEY_VENTILATION_DIRECTION"]])
    end
    if (luaTable[keytable["KEY_MODE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE"]], VALUE_FUNCTION_DRYING) ~=
            nil) then
            valuetable["DRYING_ENABLE"] = 0x01
        else
            valuetable["DRYING_ENABLE"] = 0x00
        end
    end
    if (luaTable[keytable["KEY_MODE_ENABLE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_ENABLE"]],
                        VALUE_FUNCTION_DRYING) ~= nil) then
            valuetable["DRYING_ENABLE"] = 0x01
        end
    end
    if (luaTable[keytable["KEY_MODE_CLOSE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_CLOSE"]],
                        VALUE_FUNCTION_DRYING) ~= nil) then
            valuetable["DRYING_ENABLE"] = 0x00
        end
    end
    if luaTable[keytable["KEY_DRYING_TIME"]] ~= nil then
        valuetable["DRYING_TIME"] = string2Int(
                                        luaTable[keytable["KEY_DRYING_TIME"]])
    end
    if luaTable[keytable["KEY_DRYING_TEMPERATURE"]] ~= nil then
        valuetable["DRYING_TEMPERATURE"] = string2Int(
                                               luaTable[keytable["KEY_DRYING_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_DRYING_SPEED"]] ~= nil then
        valuetable["DRYING_SPEED"] = string2Int(
                                         luaTable[keytable["KEY_DRYING_SPEED"]])
    end
    if luaTable[keytable["KEY_DRYING_DIRECTION"]] ~= nil then
        valuetable["DRYING_DIRECTION"] = string2Int(
                                             luaTable[keytable["KEY_DRYING_DIRECTION"]])
    end
    if (luaTable[keytable["KEY_MODE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE"]], VALUE_FUNCTION_BLOWING) ~=
            nil) then
            valuetable["BLOWING_ENABLE"] = 0x01
        else
            valuetable["BLOWING_ENABLE"] = 0x00
        end
    end
    if (luaTable[keytable["KEY_MODE_ENABLE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_ENABLE"]],
                        VALUE_FUNCTION_BLOWING) ~= nil) then
            valuetable["BLOWING_ENABLE"] = 0x01
        end
    end
    if (luaTable[keytable["KEY_MODE_CLOSE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_CLOSE"]],
                        VALUE_FUNCTION_BLOWING) ~= nil) then
            valuetable["BLOWING_ENABLE"] = 0x00
        end
    end
    if luaTable[keytable["KEY_BLOWING_SPEED"]] ~= nil then
        valuetable["BLOWING_SPEED"] = string2Int(
                                          luaTable[keytable["KEY_BLOWING_SPEED"]])
    end
    if luaTable[keytable["KEY_BLOWING_DIRECTION"]] ~= nil then
        valuetable["BLOWING_DIRECTION"] = string2Int(
                                              luaTable[keytable["KEY_BLOWING_DIRECTION"]])
    end
    if (luaTable[keytable["KEY_MODE_CLOSE"]] ~= nil) then
        if (string.find(luaTable[keytable["KEY_MODE_CLOSE"]],
                        VALUE_FUNCTION_CLOSE_ALL) ~= nil) then
            valuetable["HEATING_ENABLE"] = 0x00
            valuetable["BATH_ENABLE"] = 0x00
            valuetable["SOFT_WIND_ENABLE"] = 0x00
            valuetable["VENTILATION_ENABLE"] = 0x00
            valuetable["DRYING_ENABLE"] = 0x00
            valuetable["BLOWING_ENABLE"] = 0x00
        end
    end
    if (luaTable[keytable["KEY_DELAY_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["DELAY_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_DELAY_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["DELAY_ENABLE"] = 0x00
    end
    if luaTable[keytable["KEY_DELAY_TIME"]] ~= nil then
        valuetable["DELAY_TIME"] = string2Int(
                                       luaTable[keytable["KEY_DELAY_TIME"]])
    end
    if (luaTable[keytable["KEY_WINDLESS_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["WINDLESS_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_WINDLESS_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["WINDLESS_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_ANION_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["ANION_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_ANION_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["ANION_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_SMELLY_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["SMELLY_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_SMELLY_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["SMELLY_ENABLE"] = 0x00
    end
    if luaTable[keytable["KEY_SMELLY_THRESHOLD"]] ~= nil then
        valuetable["SMELLY_THRESHOLD"] = string2Int(
                                             luaTable[keytable["KEY_SMELLY_THRESHOLD"]])
    end
    if (luaTable[keytable["KEY_AUTO_DEHUMIDIFICATION"]] == VALUE_FUNCTION_ON) then
        valuetable["AUTO_DEHUMIDIFICATION"] = 0x01
    elseif (luaTable[keytable["KEY_AUTO_DEHUMIDIFICATION"]] ==
        VALUE_FUNCTION_OFF) then
        valuetable["AUTO_DEHUMIDIFICATION"] = 0x00
    end
    if luaTable[keytable["KEY_DEHUMIDITY_THRESHOLD"]] ~= nil then
        valuetable["DEHUMIDITY_THRESHOLD"] = string2Int(
                                                 luaTable[keytable["KEY_DEHUMIDITY_THRESHOLD"]])
    end
    if luaTable[keytable["KEY_DEHUMIDITY_TIME"]] ~= nil then
        valuetable["DEHUMIDITY_TIME"] = string2Int(
                                            luaTable[keytable["KEY_DEHUMIDITY_TIME"]])
    end
    if luaTable[keytable["KEY_DEHUMIDITY_INTERVAL_TIME"]] ~= nil then
        valuetable["DEHUMIDITY_INTERVAL_TIME"] = string2Int(
                                                     luaTable[keytable["KEY_DEHUMIDITY_INTERVAL_TIME"]])
    end
    if luaTable[keytable["KEY_DEHUMIDITY_DIRECTION"]] ~= nil then
        valuetable["DEHUMIDITY_DIRECTION"] = string2Int(
                                                 luaTable[keytable["KEY_DEHUMIDITY_DIRECTION"]])
    end
    if (luaTable[keytable["KEY_WIFI_LED_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["WIFI_LED_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_WIFI_LED_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["WIFI_LED_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_FUNCTION_LED_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["FUNCTION_LED_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_FUNCTION_LED_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["FUNCTION_LED_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_DIGIT_LED_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["DIGIT_LED_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_DIGIT_LED_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["DIGIT_LED_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_TIMING1_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["TIMING1_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING1_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["TIMING1_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_TIMING1_FUNCTION"]] == VALUE_FUNCTION_MAIN_LIGHT) then
        valuetable["TIMING1_FUNCTION"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING1_FUNCTION"]] ==
        VALUE_FUNCTION_NIGHT_LIGHT) then
        valuetable["TIMING1_FUNCTION"] = 0x02
    elseif (luaTable[keytable["KEY_TIMING1_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_HIGHT) then
        valuetable["TIMING1_FUNCTION"] = 0x03
    elseif (luaTable[keytable["KEY_TIMING1_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_LOW) then
        valuetable["TIMING1_FUNCTION"] = 0x04
    elseif (luaTable[keytable["KEY_TIMING1_FUNCTION"]] == VALUE_FUNCTION_BATH) then
        valuetable["TIMING1_FUNCTION"] = 0x05
    elseif (luaTable[keytable["KEY_TIMING1_FUNCTION"]] ==
        VALUE_FUNCTION_VENTILATION) then
        valuetable["TIMING1_FUNCTION"] = 0x06
    elseif (luaTable[keytable["KEY_TIMING1_FUNCTION"]] == VALUE_FUNCTION_BLOWING) then
        valuetable["TIMING1_FUNCTION"] = 0x07
    elseif (luaTable[keytable["KEY_TIMING1_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_SAFE_POWER) then
        valuetable["TIMING1_FUNCTION"] = 0x08
    elseif (luaTable[keytable["KEY_TIMING1_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_FAST) then
        valuetable["TIMING1_FUNCTION"] = 0x09
    end
    if luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]] ~= nil then
        valuetable["TIMING1_DATE_REPEAT"] = 0x00
        if (string.find(luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]], 'sunday') ~=
            nil) then
            valuetable["TIMING1_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING1_DATE_REPEAT"],
                                                    0x01)
        end
        if (string.find(luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]], 'monday') ~=
            nil) then
            valuetable["TIMING1_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING1_DATE_REPEAT"],
                                                    0x02)
        end
        if (string.find(luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]],
                        'thursday') ~= nil) then
            valuetable["TIMING1_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING1_DATE_REPEAT"],
                                                    0x04)
        end
        if (string.find(luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]],
                        'wednesday') ~= nil) then
            valuetable["TIMING1_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING1_DATE_REPEAT"],
                                                    0x08)
        end
        if (string.find(luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]], 'tuesday') ~=
            nil) then
            valuetable["TIMING1_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING1_DATE_REPEAT"],
                                                    0x10)
        end
        if (string.find(luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]], 'friday') ~=
            nil) then
            valuetable["TIMING1_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING1_DATE_REPEAT"],
                                                    0x20)
        end
        if (string.find(luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]],
                        'saturday') ~= nil) then
            valuetable["TIMING1_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING1_DATE_REPEAT"],
                                                    0x40)
        end
        if (string.find(luaTable[keytable["KEY_TIMING1_DATE_REPEAT"]], 'once') ~=
            nil) then
            valuetable["TIMING1_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING1_DATE_REPEAT"],
                                                    0x80)
        end
    end
    if luaTable[keytable["KEY_TIMING1_OPENINT_TIME"]] ~= nil then
        valuetable["TIMING1_OPENINT_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING1_OPENINT_TIME"]], 1, 2))
        valuetable["TIMING1_OPENINT_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING1_OPENINT_TIME"]], 4, 5))
    end
    if luaTable[keytable["KEY_TIMING1_CLOSING_TIME"]] ~= nil then
        valuetable["TIMING1_CLOSING_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING1_CLOSING_TIME"]], 1, 2))
        valuetable["TIMING1_CLOSING_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING1_CLOSING_TIME"]], 4, 5))
    end
    if (luaTable[keytable["KEY_TIMING2_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["TIMING2_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING2_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["TIMING2_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_TIMING2_FUNCTION"]] == VALUE_FUNCTION_MAIN_LIGHT) then
        valuetable["TIMING2_FUNCTION"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING2_FUNCTION"]] ==
        VALUE_FUNCTION_NIGHT_LIGHT) then
        valuetable["TIMING2_FUNCTION"] = 0x02
    elseif (luaTable[keytable["KEY_TIMING2_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_HIGHT) then
        valuetable["TIMING2_FUNCTION"] = 0x03
    elseif (luaTable[keytable["KEY_TIMING2_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_LOW) then
        valuetable["TIMING2_FUNCTION"] = 0x04
    elseif (luaTable[keytable["KEY_TIMING2_FUNCTION"]] == VALUE_FUNCTION_BATH) then
        valuetable["TIMING2_FUNCTION"] = 0x05
    elseif (luaTable[keytable["KEY_TIMING2_FUNCTION"]] ==
        VALUE_FUNCTION_VENTILATION) then
        valuetable["TIMING2_FUNCTION"] = 0x06
    elseif (luaTable[keytable["KEY_TIMING2_FUNCTION"]] == VALUE_FUNCTION_BLOWING) then
        valuetable["TIMING2_FUNCTION"] = 0x07
    elseif (luaTable[keytable["KEY_TIMING2_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_SAFE_POWER) then
        valuetable["TIMING2_FUNCTION"] = 0x08
    elseif (luaTable[keytable["KEY_TIMING2_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_FAST) then
        valuetable["TIMING2_FUNCTION"] = 0x09
    end
    if luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]] ~= nil then
        valuetable["TIMING2_DATE_REPEAT"] = 0x00
        if (string.find(luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]], 'sunday') ~=
            nil) then
            valuetable["TIMING2_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING2_DATE_REPEAT"],
                                                    0x01)
        end
        if (string.find(luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]], 'monday') ~=
            nil) then
            valuetable["TIMING2_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING2_DATE_REPEAT"],
                                                    0x02)
        end
        if (string.find(luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]],
                        'thursday') ~= nil) then
            valuetable["TIMING2_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING2_DATE_REPEAT"],
                                                    0x04)
        end
        if (string.find(luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]],
                        'wednesday') ~= nil) then
            valuetable["TIMING2_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING2_DATE_REPEAT"],
                                                    0x08)
        end
        if (string.find(luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]], 'tuesday') ~=
            nil) then
            valuetable["TIMING2_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING2_DATE_REPEAT"],
                                                    0x10)
        end
        if (string.find(luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]], 'friday') ~=
            nil) then
            valuetable["TIMING2_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING2_DATE_REPEAT"],
                                                    0x20)
        end
        if (string.find(luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]],
                        'saturday') ~= nil) then
            valuetable["TIMING2_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING2_DATE_REPEAT"],
                                                    0x40)
        end
        if (string.find(luaTable[keytable["KEY_TIMING2_DATE_REPEAT"]], 'once') ~=
            nil) then
            valuetable["TIMING2_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING2_DATE_REPEAT"],
                                                    0x80)
        end
    end
    if luaTable[keytable["KEY_TIMING2_OPENINT_TIME"]] ~= nil then
        valuetable["TIMING2_OPENINT_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING2_OPENINT_TIME"]], 1, 2))
        valuetable["TIMING2_OPENINT_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING2_OPENINT_TIME"]], 4, 5))
    end
    if luaTable[keytable["KEY_TIMING2_CLOSING_TIME"]] ~= nil then
        valuetable["TIMING2_CLOSING_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING2_CLOSING_TIME"]], 1, 2))
        valuetable["TIMING2_CLOSING_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING2_CLOSING_TIME"]], 4, 5))
    end
    if (luaTable[keytable["KEY_TIMING3_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["TIMING3_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING3_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["TIMING3_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_TIMING3_FUNCTION"]] == VALUE_FUNCTION_MAIN_LIGHT) then
        valuetable["TIMING3_FUNCTION"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING3_FUNCTION"]] ==
        VALUE_FUNCTION_NIGHT_LIGHT) then
        valuetable["TIMING3_FUNCTION"] = 0x02
    elseif (luaTable[keytable["KEY_TIMING3_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_HIGHT) then
        valuetable["TIMING3_FUNCTION"] = 0x03
    elseif (luaTable[keytable["KEY_TIMING3_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_LOW) then
        valuetable["TIMING3_FUNCTION"] = 0x04
    elseif (luaTable[keytable["KEY_TIMING3_FUNCTION"]] == VALUE_FUNCTION_BATH) then
        valuetable["TIMING3_FUNCTION"] = 0x05
    elseif (luaTable[keytable["KEY_TIMING3_FUNCTION"]] ==
        VALUE_FUNCTION_VENTILATION) then
        valuetable["TIMING3_FUNCTION"] = 0x06
    elseif (luaTable[keytable["KEY_TIMING3_FUNCTION"]] == VALUE_FUNCTION_BLOWING) then
        valuetable["TIMING3_FUNCTION"] = 0x07
    elseif (luaTable[keytable["KEY_TIMING3_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_SAFE_POWER) then
        valuetable["TIMING3_FUNCTION"] = 0x08
    elseif (luaTable[keytable["KEY_TIMING3_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_FAST) then
        valuetable["TIMING3_FUNCTION"] = 0x09
    end
    if luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]] ~= nil then
        valuetable["TIMING3_DATE_REPEAT"] = 0x00
        if (string.find(luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]], 'sunday') ~=
            nil) then
            valuetable["TIMING3_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING3_DATE_REPEAT"],
                                                    0x01)
        end
        if (string.find(luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]], 'monday') ~=
            nil) then
            valuetable["TIMING3_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING3_DATE_REPEAT"],
                                                    0x02)
        end
        if (string.find(luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]],
                        'thursday') ~= nil) then
            valuetable["TIMING3_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING3_DATE_REPEAT"],
                                                    0x04)
        end
        if (string.find(luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]],
                        'wednesday') ~= nil) then
            valuetable["TIMING3_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING3_DATE_REPEAT"],
                                                    0x08)
        end
        if (string.find(luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]], 'tuesday') ~=
            nil) then
            valuetable["TIMING3_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING3_DATE_REPEAT"],
                                                    0x10)
        end
        if (string.find(luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]], 'friday') ~=
            nil) then
            valuetable["TIMING3_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING3_DATE_REPEAT"],
                                                    0x20)
        end
        if (string.find(luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]],
                        'saturday') ~= nil) then
            valuetable["TIMING3_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING3_DATE_REPEAT"],
                                                    0x40)
        end
        if (string.find(luaTable[keytable["KEY_TIMING3_DATE_REPEAT"]], 'once') ~=
            nil) then
            valuetable["TIMING3_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING3_DATE_REPEAT"],
                                                    0x80)
        end
    end
    if luaTable[keytable["KEY_TIMING3_OPENINT_TIME"]] ~= nil then
        valuetable["TIMING3_OPENINT_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING3_OPENINT_TIME"]], 1, 2))
        valuetable["TIMING3_OPENINT_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING3_OPENINT_TIME"]], 4, 5))
    end
    if luaTable[keytable["KEY_TIMING3_CLOSING_TIME"]] ~= nil then
        valuetable["TIMING3_CLOSING_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING3_CLOSING_TIME"]], 1, 2))
        valuetable["TIMING3_CLOSING_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING3_CLOSING_TIME"]], 4, 5))
    end
    if (luaTable[keytable["KEY_TIMING4_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["TIMING4_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING4_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["TIMING4_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_TIMING4_FUNCTION"]] == VALUE_FUNCTION_MAIN_LIGHT) then
        valuetable["TIMING4_FUNCTION"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING4_FUNCTION"]] ==
        VALUE_FUNCTION_NIGHT_LIGHT) then
        valuetable["TIMING4_FUNCTION"] = 0x02
    elseif (luaTable[keytable["KEY_TIMING4_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_HIGHT) then
        valuetable["TIMING4_FUNCTION"] = 0x03
    elseif (luaTable[keytable["KEY_TIMING4_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_LOW) then
        valuetable["TIMING4_FUNCTION"] = 0x04
    elseif (luaTable[keytable["KEY_TIMING4_FUNCTION"]] == VALUE_FUNCTION_BATH) then
        valuetable["TIMING4_FUNCTION"] = 0x05
    elseif (luaTable[keytable["KEY_TIMING4_FUNCTION"]] ==
        VALUE_FUNCTION_VENTILATION) then
        valuetable["TIMING4_FUNCTION"] = 0x06
    elseif (luaTable[keytable["KEY_TIMING4_FUNCTION"]] == VALUE_FUNCTION_BLOWING) then
        valuetable["TIMING4_FUNCTION"] = 0x07
    elseif (luaTable[keytable["KEY_TIMING4_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_SAFE_POWER) then
        valuetable["TIMING4_FUNCTION"] = 0x08
    elseif (luaTable[keytable["KEY_TIMING4_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_FAST) then
        valuetable["TIMING4_FUNCTION"] = 0x09
    end
    if luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]] ~= nil then
        valuetable["TIMING4_DATE_REPEAT"] = 0x00
        if (string.find(luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]], 'sunday') ~=
            nil) then
            valuetable["TIMING4_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING4_DATE_REPEAT"],
                                                    0x01)
        end
        if (string.find(luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]], 'monday') ~=
            nil) then
            valuetable["TIMING4_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING4_DATE_REPEAT"],
                                                    0x02)
        end
        if (string.find(luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]],
                        'thursday') ~= nil) then
            valuetable["TIMING4_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING4_DATE_REPEAT"],
                                                    0x04)
        end
        if (string.find(luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]],
                        'wednesday') ~= nil) then
            valuetable["TIMING4_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING4_DATE_REPEAT"],
                                                    0x08)
        end
        if (string.find(luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]], 'tuesday') ~=
            nil) then
            valuetable["TIMING4_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING4_DATE_REPEAT"],
                                                    0x10)
        end
        if (string.find(luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]], 'friday') ~=
            nil) then
            valuetable["TIMING4_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING4_DATE_REPEAT"],
                                                    0x20)
        end
        if (string.find(luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]],
                        'saturday') ~= nil) then
            valuetable["TIMING4_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING4_DATE_REPEAT"],
                                                    0x40)
        end
        if (string.find(luaTable[keytable["KEY_TIMING4_DATE_REPEAT"]], 'once') ~=
            nil) then
            valuetable["TIMING4_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING4_DATE_REPEAT"],
                                                    0x80)
        end
    end
    if luaTable[keytable["KEY_TIMING4_OPENINT_TIME"]] ~= nil then
        valuetable["TIMING4_OPENINT_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING4_OPENINT_TIME"]], 1, 2))
        valuetable["TIMING4_OPENINT_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING4_OPENINT_TIME"]], 4, 5))
    end
    if luaTable[keytable["KEY_TIMING4_CLOSING_TIME"]] ~= nil then
        valuetable["TIMING4_CLOSING_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING4_CLOSING_TIME"]], 1, 2))
        valuetable["TIMING4_CLOSING_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING4_CLOSING_TIME"]], 4, 5))
    end
    if (luaTable[keytable["KEY_TIMING5_ENABLE"]] == VALUE_FUNCTION_ON) then
        valuetable["TIMING5_ENABLE"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING5_ENABLE"]] == VALUE_FUNCTION_OFF) then
        valuetable["TIMING5_ENABLE"] = 0x00
    end
    if (luaTable[keytable["KEY_TIMING5_FUNCTION"]] == VALUE_FUNCTION_MAIN_LIGHT) then
        valuetable["TIMING5_FUNCTION"] = 0x01
    elseif (luaTable[keytable["KEY_TIMING5_FUNCTION"]] ==
        VALUE_FUNCTION_NIGHT_LIGHT) then
        valuetable["TIMING5_FUNCTION"] = 0x02
    elseif (luaTable[keytable["KEY_TIMING5_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_HIGHT) then
        valuetable["TIMING5_FUNCTION"] = 0x03
    elseif (luaTable[keytable["KEY_TIMING5_FUNCTION"]] ==
        VALUE_FUNCTION_HEATING_LOW) then
        valuetable["TIMING5_FUNCTION"] = 0x04
    elseif (luaTable[keytable["KEY_TIMING5_FUNCTION"]] == VALUE_FUNCTION_BATH) then
        valuetable["TIMING5_FUNCTION"] = 0x05
    elseif (luaTable[keytable["KEY_TIMING5_FUNCTION"]] ==
        VALUE_FUNCTION_VENTILATION) then
        valuetable["TIMING5_FUNCTION"] = 0x06
    elseif (luaTable[keytable["KEY_TIMING5_FUNCTION"]] == VALUE_FUNCTION_BLOWING) then
        valuetable["TIMING5_FUNCTION"] = 0x07
    elseif (luaTable[keytable["KEY_TIMING5_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_SAFE_POWER) then
        valuetable["TIMING5_FUNCTION"] = 0x08
    elseif (luaTable[keytable["KEY_TIMING5_FUNCTION"]] ==
        VALUE_FUNCTION_DRYING_FAST) then
        valuetable["TIMING5_FUNCTION"] = 0x09
    end
    if luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]] ~= nil then
        valuetable["TIMING5_DATE_REPEAT"] = 0x00
        if (string.find(luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]], 'sunday') ~=
            nil) then
            valuetable["TIMING5_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING5_DATE_REPEAT"],
                                                    0x01)
        end
        if (string.find(luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]], 'monday') ~=
            nil) then
            valuetable["TIMING5_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING5_DATE_REPEAT"],
                                                    0x02)
        end
        if (string.find(luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]],
                        'thursday') ~= nil) then
            valuetable["TIMING5_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING5_DATE_REPEAT"],
                                                    0x04)
        end
        if (string.find(luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]],
                        'wednesday') ~= nil) then
            valuetable["TIMING5_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING5_DATE_REPEAT"],
                                                    0x08)
        end
        if (string.find(luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]], 'tuesday') ~=
            nil) then
            valuetable["TIMING5_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING5_DATE_REPEAT"],
                                                    0x10)
        end
        if (string.find(luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]], 'friday') ~=
            nil) then
            valuetable["TIMING5_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING5_DATE_REPEAT"],
                                                    0x20)
        end
        if (string.find(luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]],
                        'saturday') ~= nil) then
            valuetable["TIMING5_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING5_DATE_REPEAT"],
                                                    0x40)
        end
        if (string.find(luaTable[keytable["KEY_TIMING5_DATE_REPEAT"]], 'once') ~=
            nil) then
            valuetable["TIMING5_DATE_REPEAT"] = bit.bor(
                                                    valuetable["TIMING5_DATE_REPEAT"],
                                                    0x80)
        end
    end
    if luaTable[keytable["KEY_TIMING5_OPENINT_TIME"]] ~= nil then
        valuetable["TIMING5_OPENINT_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING5_OPENINT_TIME"]], 1, 2))
        valuetable["TIMING5_OPENINT_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING5_OPENINT_TIME"]], 4, 5))
    end
    if luaTable[keytable["KEY_TIMING5_CLOSING_TIME"]] ~= nil then
        valuetable["TIMING5_CLOSING_TIME_HOUR"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING5_CLOSING_TIME"]], 1, 2))
        valuetable["TIMING5_CLOSING_TIME_MIN"] =
            string2Int(string.sub(
                           luaTable[keytable["KEY_TIMING5_CLOSING_TIME"]], 4, 5))
    end
end
local function updateGlobalPropertyValueByByte(messageBytes)
    local hard_version_len
    local soft_version_len
    valueTableInitialization()
    if (messageBytes[0] ~= nil) then cmdType = messageBytes[0] end
    if (cmdType == 0x01) then
        if (messageBytes[1] ~= nil) then
            valuetable["MAIN_LIGHT_ENABLE"] = messageBytes[1]
        end
        if (messageBytes[2] ~= nil) then
            valuetable["MAIN_LIGHT_BRIGHTNESS"] = messageBytes[2]
        end
        if (messageBytes[3] ~= nil) then
            valuetable["NIGHT_LIGHT_ENABLE"] = messageBytes[3]
        end
        if (messageBytes[4] ~= nil) then
            valuetable["NIGHT_LIGHT_BRIGHTNESS"] = messageBytes[4]
        end
        if (messageBytes[5] ~= nil) then
            valuetable["RADAR_INDUCTION_ENABLE"] = messageBytes[5]
        end
        if (messageBytes[6] ~= nil) then
            valuetable["RADAR_INDUCTION_CLOSING_TIME"] = messageBytes[6]
        end
        if (messageBytes[7] ~= nil) then
            valuetable["LIGHT_INTENSITY_THRESHOLD"] = messageBytes[7]
        end
        if (messageBytes[8] ~= nil) then
            valuetable["RADAR_SENSITIVITY"] = messageBytes[8]
        end
        if (messageBytes[9] ~= nil) then
            valuetable["HEATING_ENABLE"] = messageBytes[9]
        end
        if (messageBytes[10] ~= nil) then
            valuetable["HEATING_TEMPERATURE"] = messageBytes[10]
        end
        if (messageBytes[11] ~= nil) then
            valuetable["HEATING_SPEED"] = messageBytes[11]
        end
        if (messageBytes[12] ~= nil) then
            valuetable["HEATING_DIRECTION"] = messageBytes[12]
        end
        if (messageBytes[13] ~= nil) then
            valuetable["BATH_ENABLE"] = messageBytes[13]
        end
        if (messageBytes[14] ~= nil) then
            valuetable["BATH_HEATING_TIME"] = messageBytes[14]
        end
        if (messageBytes[15] ~= nil) then
            valuetable["BATH_TEMPERATURE"] = messageBytes[15]
        end
        if (messageBytes[16] ~= nil) then
            valuetable["BATH_SPEED"] = messageBytes[16]
        end
        if (messageBytes[17] ~= nil) then
            valuetable["BATH_DIRECTION"] = messageBytes[17]
        end
        if (messageBytes[18] ~= nil) then
            valuetable["VENTILATION_ENABLE"] = messageBytes[18]
        end
        if (messageBytes[19] ~= nil) then
            valuetable["VENTILATION_SPEED"] = messageBytes[19]
        end
        if (messageBytes[20] ~= nil) then
            valuetable["VENTILATION_DIRECTION"] = messageBytes[20]
        end
        if (messageBytes[21] ~= nil) then
            valuetable["DRYING_ENABLE"] = messageBytes[21]
        end
        if (messageBytes[22] ~= nil) then
            valuetable["DRYING_TIME"] = messageBytes[22]
        end
        if (messageBytes[23] ~= nil) then
            valuetable["DRYING_TEMPERATURE"] = messageBytes[23]
        end
        if (messageBytes[24] ~= nil) then
            valuetable["DRYING_SPEED"] = messageBytes[24]
        end
        if (messageBytes[25] ~= nil) then
            valuetable["DRYING_DIRECTION"] = messageBytes[25]
        end
        if (messageBytes[26] ~= nil) then
            valuetable["BLOWING_ENABLE"] = messageBytes[26]
        end
        if (messageBytes[27] ~= nil) then
            valuetable["BLOWING_SPEED"] = messageBytes[27]
        end
        if (messageBytes[28] ~= nil) then
            valuetable["BLOWING_DIRECTION"] = messageBytes[28]
        end
        if (messageBytes[29] ~= nil) then
            valuetable["DELAY_ENABLE"] = messageBytes[29]
        end
        if (messageBytes[30] ~= nil) then
            valuetable["DELAY_TIME"] = messageBytes[30]
        end
        if (messageBytes[31] ~= nil) then
            valuetable["CURRENT_HUMIDITY"] = messageBytes[31]
        end
        if (messageBytes[32] ~= nil) then
            valuetable["CURRENT_RADAR_STATUS"] = messageBytes[32]
        end
        if (messageBytes[33] ~= nil) then
            valuetable["CURRENT_TEMPERATURE"] = messageBytes[33]
        end
        if (messageBytes[34] ~= nil) then
            valuetable["FILTER_STATUS"] = messageBytes[34]
        end
        if (messageBytes[35] ~= nil) then
            valuetable["REMOTE_LOW_POWER"] = messageBytes[35]
        end
        if (messageBytes[36] ~= nil) then
            valuetable["REMOTE_POWER"] = messageBytes[36]
        end
        if (messageBytes[37] ~= nil) then
            valuetable["SMELLY_LEVEL"] = messageBytes[37]
        end
        if (messageBytes[38] ~= nil) then
            valuetable["SOFT_WIND_ENABLE"] = messageBytes[38]
        end
        if (messageBytes[39] ~= nil) then
            valuetable["SOFT_WIND_HEATING_TIME"] = messageBytes[39]
        end
        if (messageBytes[40] ~= nil) then
            valuetable["SOFT_WIND_TEMPERATURE"] = messageBytes[40]
        end
        if (messageBytes[41] ~= nil) then
            valuetable["SOFT_WIND_SPEED"] = messageBytes[41]
        end
        if (messageBytes[42] ~= nil) then
            valuetable["SOFT_WIND_DIRECTION"] = messageBytes[42]
        end
        if (messageBytes[43] ~= nil) then
            valuetable["WINDLESS_ENABLE"] = messageBytes[43]
        end
        if (messageBytes[44] ~= nil) then
            valuetable["ANION_ENABLE"] = messageBytes[44]
        end
        if (messageBytes[45] ~= nil) then
            valuetable["SMELLY_ENABLE"] = messageBytes[45]
        end
        if (messageBytes[46] ~= nil) then
            valuetable["SMELLY_THRESHOLD"] = messageBytes[46]
        end
        if (messageBytes[47] ~= nil) then
            valuetable["AUTO_DEHUMIDIFICATION"] = messageBytes[47]
        end
        if (messageBytes[48] ~= nil) then
            valuetable["DEHUMIDITY_THRESHOLD"] = messageBytes[48]
        end
        if (messageBytes[49] ~= nil) then
            valuetable["DEHUMIDITY_TIME"] = messageBytes[49]
        end
        if (messageBytes[50] ~= nil) then
            valuetable["DEHUMIDITY_INTERVAL_TIME"] = messageBytes[50]
        end
        if (messageBytes[51] ~= nil) then
            valuetable["DEHUMIDITY_DIRECTION"] = messageBytes[51]
        end
        if (messageBytes[52] ~= nil) then
            valuetable["WIFI_LED_ENABLE"] = bit.band(messageBytes[52], 0x03)
            valuetable["FUNCTION_LED_ENABLE"] =
                bit.band(bit.rshift(messageBytes[52], 2), 0x03)
            valuetable["DIGIT_LED_ENABLE"] =
                bit.band(bit.rshift(messageBytes[52], 4), 0x03)
        end
    elseif (cmdType == 0x02) then
        if (messageBytes[1] ~= nil) then
            valuetable["TIMING1_ENABLE"] = messageBytes[1]
        end
        if (messageBytes[2] ~= nil) then
            valuetable["TIMING1_FUNCTION"] = messageBytes[2]
        end
        if (messageBytes[3] ~= nil) then
            valuetable["TIMING1_DATE_REPEAT"] = messageBytes[3]
        end
        if (messageBytes[4] ~= nil) then
            valuetable["TIMING1_OPENINT_TIME_HOUR"] = messageBytes[4]
            valuetable["TIMING1_OPENINT_TIME_MIN"] = messageBytes[5]
        end
        if (messageBytes[6] ~= nil) then
            valuetable["TIMING1_CLOSING_TIME_HOUR"] = messageBytes[6]
            valuetable["TIMING1_CLOSING_TIME_MIN"] = messageBytes[7]
        end
        if (messageBytes[8] ~= nil) then
            valuetable["TIMING2_ENABLE"] = messageBytes[8]
        end
        if (messageBytes[9] ~= nil) then
            valuetable["TIMING2_FUNCTION"] = messageBytes[9]
        end
        if (messageBytes[10] ~= nil) then
            valuetable["TIMING2_DATE_REPEAT"] = messageBytes[10]
        end
        if (messageBytes[11] ~= nil) then
            valuetable["TIMING2_OPENINT_TIME_HOUR"] = messageBytes[11]
            valuetable["TIMING2_OPENINT_TIME_MIN"] = messageBytes[12]
        end
        if (messageBytes[13] ~= nil) then
            valuetable["TIMING2_CLOSING_TIME_HOUR"] = messageBytes[13]
            valuetable["TIMING2_CLOSING_TIME_MIN"] = messageBytes[14]
        end
        if (messageBytes[15] ~= nil) then
            valuetable["TIMING3_ENABLE"] = messageBytes[15]
        end
        if (messageBytes[16] ~= nil) then
            valuetable["TIMING3_FUNCTION"] = messageBytes[16]
        end
        if (messageBytes[17] ~= nil) then
            valuetable["TIMING3_DATE_REPEAT"] = messageBytes[17]
        end
        if (messageBytes[18] ~= nil) then
            valuetable["TIMING3_OPENINT_TIME_HOUR"] = messageBytes[18]
            valuetable["TIMING3_OPENINT_TIME_MIN"] = messageBytes[19]
        end
        if (messageBytes[20] ~= nil) then
            valuetable["TIMING3_CLOSING_TIME_HOUR"] = messageBytes[20]
            valuetable["TIMING3_CLOSING_TIME_MIN"] = messageBytes[21]
        end
        if (messageBytes[22] ~= nil) then
            valuetable["TIMING4_ENABLE"] = messageBytes[22]
        end
        if (messageBytes[23] ~= nil) then
            valuetable["TIMING4_FUNCTION"] = messageBytes[23]
        end
        if (messageBytes[24] ~= nil) then
            valuetable["TIMING4_DATE_REPEAT"] = messageBytes[24]
        end
        if (messageBytes[25] ~= nil) then
            valuetable["TIMING4_OPENINT_TIME_HOUR"] = messageBytes[25]
            valuetable["TIMING4_OPENINT_TIME_MIN"] = messageBytes[26]
        end
        if (messageBytes[27] ~= nil) then
            valuetable["TIMING4_CLOSING_TIME_HOUR"] = messageBytes[27]
            valuetable["TIMING4_CLOSING_TIME_MIN"] = messageBytes[28]
        end
        if (messageBytes[29] ~= nil) then
            valuetable["TIMING5_ENABLE"] = messageBytes[29]
        end
        if (messageBytes[30] ~= nil) then
            valuetable["TIMING5_FUNCTION"] = messageBytes[30]
        end
        if (messageBytes[31] ~= nil) then
            valuetable["TIMING5_DATE_REPEAT"] = messageBytes[31]
        end
        if (messageBytes[32] ~= nil) then
            valuetable["TIMING5_OPENINT_TIME_HOUR"] = messageBytes[32]
            valuetable["TIMING5_OPENINT_TIME_MIN"] = messageBytes[33]
        end
        if (messageBytes[34] ~= nil) then
            valuetable["TIMING5_CLOSING_TIME_HOUR"] = messageBytes[34]
            valuetable["TIMING5_CLOSING_TIME_MIN"] = messageBytes[35]
        end
    elseif (cmdType == 0x03) then
        hard_version_len = messageBytes[1]
        if (hard_version_len ~= nil) then
            for i = 0, hard_version_len - 1 do
                valuetable["HARDWARE_VERSION"] =
                    valuetable["HARDWARE_VERSION"] ..
                        string.char(messageBytes[i + 2])
            end
        end
        soft_version_len = messageBytes[hard_version_len + 2]
        if (soft_version_len ~= nil) then
            for i = 0, soft_version_len - 1 do
                valuetable["SOFTWARE_VERSION"] =
                    valuetable["SOFTWARE_VERSION"] ..
                        string.char(messageBytes[i + 3 + hard_version_len])
            end
        end
    end
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[keytable["KEY_VERSION"]] = VALUE_VERSION
    if (dataType == BYTE_CONTROL_REQUEST) then
        if (cmdType == 0x02) then
            streams[keytable["KEY_SUB_PACKET_TYPE"]] = VALUE_TIMING_SETTING
        end
    elseif (dataType == BYTE_QUERY_REQUEST) then
        if (cmdType == 0x01) then
            streams[keytable["KEY_SUB_PACKET_TYPE"]] = VALUE_FUNCTION_QUERY
        elseif (cmdType == 0x02) then
            streams[keytable["KEY_SUB_PACKET_TYPE"]] = VALUE_TIMING_QUERY
        elseif (cmdType == 0x03) then
            streams[keytable["KEY_SUB_PACKET_TYPE"]] = VALUE_VERSION_QUERY
        end
    elseif ((dataType == BYTE_REPORT_NACK) or (dataType == BYTE_REPORT_ACK)) then
        if (cmdType == 0x01) then
            streams[keytable["KEY_SUB_PACKET_TYPE"]] = VALUE_FUNCTION_REPORT
        elseif (cmdType == 0x02) then
            streams[keytable["KEY_SUB_PACKET_TYPE"]] = VALUE_TIMING_REPORT
        elseif (cmdType == 0x03) then
            streams[keytable["KEY_SUB_PACKET_TYPE"]] = VALUE_VERSION_REPORT
        end
    end
    if ((valuetable["MAIN_LIGHT_ENABLE"] ~= 0xFF) or
        (valuetable["NIGHT_LIGHT_ENABLE"] ~= 0xFF)) then
        streams[keytable["KEY_LIGHT_MODE"]] = ""
        if (valuetable["MAIN_LIGHT_ENABLE"] == 0x01) then
            streams[keytable["KEY_LIGHT_MODE"]] =
                streams[keytable["KEY_LIGHT_MODE"]] .. VALUE_FUNCTION_MAIN_LIGHT
            streams[keytable["KEY_LIGHT_MODE"]] =
                streams[keytable["KEY_LIGHT_MODE"]] .. ","
        end
        if (valuetable["NIGHT_LIGHT_ENABLE"] == 0x01) then
            streams[keytable["KEY_LIGHT_MODE"]] =
                streams[keytable["KEY_LIGHT_MODE"]] ..
                    VALUE_FUNCTION_NIGHT_LIGHT
            streams[keytable["KEY_LIGHT_MODE"]] =
                streams[keytable["KEY_LIGHT_MODE"]] .. ","
        end
        if (streams[keytable["KEY_LIGHT_MODE"]] == "") then
            streams[keytable["KEY_LIGHT_MODE"]] = VALUE_FUNCTION_CLOSE_ALL
        else
            streams[keytable["KEY_LIGHT_MODE"]] = string.sub(
                                                      streams[keytable["KEY_LIGHT_MODE"]],
                                                      1, -2)
        end
    end
    if (valuetable["MAIN_LIGHT_BRIGHTNESS"] ~= 0xFF) then
        streams[keytable["KEY_MAIN_LIGHT_BRIGHTNESS"]] = int2String(
                                                             valuetable["MAIN_LIGHT_BRIGHTNESS"])
    end
    if (valuetable["NIGHT_LIGHT_BRIGHTNESS"] ~= 0xFF) then
        streams[keytable["KEY_NIGHT_LIGHT_BRIGHTNESS"]] = int2String(
                                                              valuetable["NIGHT_LIGHT_BRIGHTNESS"])
    end
    if (valuetable["RADAR_INDUCTION_ENABLE"] == 0x00) then
        streams[keytable["KEY_RADAR_INDUCTION_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["RADAR_INDUCTION_ENABLE"] == 0x01) then
        streams[keytable["KEY_RADAR_INDUCTION_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["RADAR_INDUCTION_CLOSING_TIME"] ~= 0xFF) then
        streams[keytable["KEY_RADAR_INDUCTION_CLOSING_TIME"]] = int2String(
                                                                    valuetable["RADAR_INDUCTION_CLOSING_TIME"])
    end
    if (valuetable["LIGHT_INTENSITY_THRESHOLD"] ~= 0xFF) then
        streams[keytable["KEY_LIGHT_INTENSITY_THRESHOLD"]] = int2String(
                                                                 valuetable["LIGHT_INTENSITY_THRESHOLD"])
    end
    if (valuetable["RADAR_SENSITIVITY"] ~= 0xFF) then
        streams[keytable["KEY_RADAR_SENSITIVITY"]] = int2String(
                                                         valuetable["RADAR_SENSITIVITY"])
    end
    if ((valuetable["HEATING_ENABLE"] ~= 0xFF) or
        (valuetable["BATH_ENABLE"] ~= 0xFF) or
        (valuetable["VENTILATION_ENABLE"] ~= 0xFF) or
        (valuetable["MORNING_VENTILATION_ENABLE"] ~= 0xFF) or
        (valuetable["DRYING_ENABLE"] ~= 0xFF) or
        (valuetable["BLOWING_ENABLE"] ~= 0xFF) or
        (valuetable["SOFT_WIND_ENABLE"] ~= 0xFF)) then
        streams[keytable["KEY_MODE"]] = ""
        if (valuetable["HEATING_ENABLE"] == 0x01) then
            streams[keytable["KEY_MODE"]] =
                streams[keytable["KEY_MODE"]] .. VALUE_FUNCTION_HEATING
            streams[keytable["KEY_MODE"]] = streams[keytable["KEY_MODE"]] .. ","
        end
        if (valuetable["BATH_ENABLE"] == 0x01) then
            streams[keytable["KEY_MODE"]] =
                streams[keytable["KEY_MODE"]] .. VALUE_FUNCTION_BATH
            streams[keytable["KEY_MODE"]] = streams[keytable["KEY_MODE"]] .. ","
        end
        if (valuetable["VENTILATION_ENABLE"] == 0x01) then
            streams[keytable["KEY_MODE"]] =
                streams[keytable["KEY_MODE"]] .. VALUE_FUNCTION_VENTILATION
            streams[keytable["KEY_MODE"]] = streams[keytable["KEY_MODE"]] .. ","
        end
        if (valuetable["VENTILATION_ENABLE"] == 0x02) then
            streams[keytable["KEY_MODE"]] =
                streams[keytable["KEY_MODE"]] ..
                    VALUE_FUNCTION_MORNING_VENTILATION
            streams[keytable["KEY_MODE"]] = streams[keytable["KEY_MODE"]] .. ","
        end
        if (valuetable["DRYING_ENABLE"] == 0x01) then
            streams[keytable["KEY_MODE"]] =
                streams[keytable["KEY_MODE"]] .. VALUE_FUNCTION_DRYING
            streams[keytable["KEY_MODE"]] = streams[keytable["KEY_MODE"]] .. ","
        end
        if (valuetable["BLOWING_ENABLE"] == 0x01) then
            streams[keytable["KEY_MODE"]] =
                streams[keytable["KEY_MODE"]] .. VALUE_FUNCTION_BLOWING
            streams[keytable["KEY_MODE"]] = streams[keytable["KEY_MODE"]] .. ","
        end
        if (valuetable["SOFT_WIND_ENABLE"] == 0x01) then
            streams[keytable["KEY_MODE"]] =
                streams[keytable["KEY_MODE"]] .. VALUE_FUNCTION_SOFT_WIND
            streams[keytable["KEY_MODE"]] = streams[keytable["KEY_MODE"]] .. ","
        end
        if (streams[keytable["KEY_MODE"]] == "") then
            streams[keytable["KEY_MODE"]] = VALUE_FUNCTION_CLOSE_ALL
        else
            streams[keytable["KEY_MODE"]] = string.sub(
                                                streams[keytable["KEY_MODE"]],
                                                1, -2)
        end
    end
    if (valuetable["HEATING_TEMPERATURE"] ~= 0xFF) then
        streams[keytable["KEY_HEATING_TEMPERATURE"]] = int2String(
                                                           valuetable["HEATING_TEMPERATURE"])
    end
    if (valuetable["HEATING_SPEED"] ~= 0xFF) then
        streams[keytable["KEY_HEATING_SPEED"]] = int2String(
                                                     valuetable["HEATING_SPEED"])
    end
    if (valuetable["HEATING_DIRECTION"] ~= 0xFF) then
        streams[keytable["KEY_HEATING_DIRECTION"]] = int2String(
                                                         valuetable["HEATING_DIRECTION"])
    end
    if (valuetable["BATH_HEATING_TIME"] ~= 0xFF) then
        streams[keytable["KEY_BATH_HEATING_TIME"]] = int2String(
                                                         valuetable["BATH_HEATING_TIME"])
    end
    if (valuetable["BATH_TEMPERATURE"] ~= 0xFF) then
        streams[keytable["KEY_BATH_TEMPERATURE"]] = int2String(
                                                        valuetable["BATH_TEMPERATURE"])
    end
    if (valuetable["BATH_SPEED"] ~= 0xFF) then
        streams[keytable["KEY_BATH_SPEED"]] = int2String(
                                                  valuetable["BATH_SPEED"])
    end
    if (valuetable["BATH_DIRECTION"] ~= 0xFF) then
        streams[keytable["KEY_BATH_DIRECTION"]] = int2String(
                                                      valuetable["BATH_DIRECTION"])
    end
    if (valuetable["SOFT_WIND_HEATING_TIME"] ~= 0xFF) then
        streams[keytable["KEY_SOFT_WIND_HEATING_TIME"]] = int2String(
                                                              valuetable["SOFT_WIND_HEATING_TIME"])
    end
    if (valuetable["SOFT_WIND_TEMPERATURE"] ~= 0xFF) then
        streams[keytable["KEY_SOFT_WIND_TEMPERATURE"]] = int2String(
                                                             valuetable["SOFT_WIND_TEMPERATURE"])
    end
    if (valuetable["SOFT_WIND_SPEED"] ~= 0xFF) then
        streams[keytable["KEY_SOFT_WIND_SPEED"]] = int2String(
                                                       valuetable["SOFT_WIND_SPEED"])
    end
    if (valuetable["SOFT_WIND_DIRECTION"] ~= 0xFF) then
        streams[keytable["KEY_SOFT_WIND_DIRECTION"]] = int2String(
                                                           valuetable["SOFT_WIND_DIRECTION"])
    end
    if (valuetable["VENTILATION_SPEED"] ~= 0xFF) then
        streams[keytable["KEY_VENTILATION_SPEED"]] = int2String(
                                                         valuetable["VENTILATION_SPEED"])
    end
    if (valuetable["VENTILATION_DIRECTION"] ~= 0xFF) then
        streams[keytable["KEY_VENTILATION_DIRECTION"]] = int2String(
                                                             valuetable["VENTILATION_DIRECTION"])
    end
    if (valuetable["DRYING_TIME"] ~= 0xFF) then
        streams[keytable["KEY_DRYING_TIME"]] = int2String(
                                                   valuetable["DRYING_TIME"])
    end
    if (valuetable["DRYING_TEMPERATURE"] ~= 0xFF) then
        streams[keytable["KEY_DRYING_TEMPERATURE"]] = int2String(
                                                          valuetable["DRYING_TEMPERATURE"])
    end
    if (valuetable["DRYING_SPEED"] ~= 0xFF) then
        streams[keytable["KEY_DRYING_SPEED"]] = int2String(
                                                    valuetable["DRYING_SPEED"])
    end
    if (valuetable["DRYING_DIRECTION"] ~= 0xFF) then
        streams[keytable["KEY_DRYING_DIRECTION"]] = int2String(
                                                        valuetable["DRYING_DIRECTION"])
    end
    if (valuetable["BLOWING_SPEED"] ~= 0xFF) then
        streams[keytable["KEY_BLOWING_SPEED"]] = int2String(
                                                     valuetable["BLOWING_SPEED"])
    end
    if (valuetable["BLOWING_DIRECTION"] ~= 0xFF) then
        streams[keytable["KEY_BLOWING_DIRECTION"]] = int2String(
                                                         valuetable["BLOWING_DIRECTION"])
    end
    if (valuetable["DELAY_ENABLE"] == 0x00) then
        streams[keytable["KEY_DELAY_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["DELAY_ENABLE"] == 0x01) then
        streams[keytable["KEY_DELAY_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["DELAY_TIME"] ~= 0xFF) then
        streams[keytable["KEY_DELAY_TIME"]] = int2String(
                                                  valuetable["DELAY_TIME"])
    end
    if (valuetable["WINDLESS_ENABLE"] == 0x00) then
        streams[keytable["KEY_WINDLESS_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["WINDLESS_ENABLE"] == 0x01) then
        streams[keytable["KEY_WINDLESS_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["ANION_ENABLE"] == 0x00) then
        streams[keytable["KEY_ANION_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["ANION_ENABLE"] == 0x01) then
        streams[keytable["KEY_ANION_ENABLE"]] = VALUE_FUNCTION_ON
    end
    streams[keytable["KEY_SMELLY_TRIGGER"]] = VALUE_FUNCTION_OFF
    if (valuetable["SMELLY_ENABLE"] == 0x00) then
        streams[keytable["KEY_SMELLY_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["SMELLY_ENABLE"] == 0x01) then
        streams[keytable["KEY_SMELLY_ENABLE"]] = VALUE_FUNCTION_ON
    elseif (valuetable["SMELLY_ENABLE"] == 0x02) then
        streams[keytable["KEY_SMELLY_ENABLE"]] = VALUE_FUNCTION_ON
        streams[keytable["KEY_SMELLY_TRIGGER"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["SMELLY_THRESHOLD"] ~= 0xFF) then
        streams[keytable["KEY_SMELLY_THRESHOLD"]] = int2String(
                                                        valuetable["SMELLY_THRESHOLD"])
    end
    if (valuetable["CURRENT_HUMIDITY"] ~= 0xFF) then
        streams[keytable["KEY_CURRENT_HUMIDITY"]] = int2String(
                                                        valuetable["CURRENT_HUMIDITY"])
    end
    if (valuetable["CURRENT_RADAR_STATUS"] ~= 0xFF) then
        streams[keytable["KEY_CURRENT_RADAR_STATUS"]] = int2String(
                                                            valuetable["CURRENT_RADAR_STATUS"])
    end
    if (valuetable["CURRENT_TEMPERATURE"] == 0xAA) then
        valuetable["CURRENT_TEMPERATURE"] = -9;
    end
    if (valuetable["CURRENT_TEMPERATURE"] ~= 0xFF) then
        if (valuetable["CURRENT_TEMPERATURE"] <= 127) then
            streams[keytable["KEY_CURRENT_TEMPERATURE"]] = int2String(
                                                               valuetable["CURRENT_TEMPERATURE"])
        else
            streams[keytable["KEY_CURRENT_TEMPERATURE"]] =
                string.format("-%d",
                              0xFF + 1 - valuetable["CURRENT_TEMPERATURE"])
        end
    end
    if (valuetable["FILTER_STATUS"] == 0x00) then
        streams[keytable["KEY_FILTER_STATUS"]] = "no"
    elseif (valuetable["FILTER_STATUS"] == 0x01) then
        streams[keytable["KEY_FILTER_STATUS"]] = "yes"
    end
    if (valuetable["REMOTE_LOW_POWER"] == 0x00) then
        streams[keytable["KEY_REMOTE_LOW_POWER"]] = "no"
    elseif (valuetable["REMOTE_LOW_POWER"] == 0x01) then
        streams[keytable["KEY_REMOTE_LOW_POWER"]] = "yes"
    end
    if (valuetable["REMOTE_POWER"] ~= 0xFF) then
        streams[keytable["KEY_REMOTE_POWER"]] = int2String(
                                                    valuetable["REMOTE_POWER"])
    end
    if (valuetable["SMELLY_LEVEL"] ~= 0xFF) then
        streams[keytable["KEY_SMELLY_LEVEL"]] = int2String(
                                                    valuetable["SMELLY_LEVEL"])
    end
    streams[keytable["KEY_DEHUMIDITY_TRIGGER"]] = VALUE_FUNCTION_OFF
    if (valuetable["AUTO_DEHUMIDIFICATION"] == 0x00) then
        streams[keytable["KEY_AUTO_DEHUMIDIFICATION"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["AUTO_DEHUMIDIFICATION"] == 0x01) then
        streams[keytable["KEY_AUTO_DEHUMIDIFICATION"]] = VALUE_FUNCTION_ON
    elseif (valuetable["AUTO_DEHUMIDIFICATION"] == 0x02) then
        streams[keytable["KEY_AUTO_DEHUMIDIFICATION"]] = VALUE_FUNCTION_ON
        streams[keytable["KEY_DEHUMIDITY_TRIGGER"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["DEHUMIDITY_THRESHOLD"] ~= 0xFF) then
        streams[keytable["KEY_DEHUMIDITY_THRESHOLD"]] = int2String(
                                                            valuetable["DEHUMIDITY_THRESHOLD"])
    end
    if (valuetable["DEHUMIDITY_TIME"] ~= 0xFF) then
        streams[keytable["KEY_DEHUMIDITY_TIME"]] = int2String(
                                                       valuetable["DEHUMIDITY_TIME"])
    end
    if (valuetable["DEHUMIDITY_INTERVAL_TIME"] ~= 0xFF) then
        streams[keytable["KEY_DEHUMIDITY_INTERVAL_TIME"]] = int2String(
                                                                valuetable["DEHUMIDITY_INTERVAL_TIME"])
    end
    if (valuetable["WIFI_LED_ENABLE"] == 0x00) then
        streams[keytable["KEY_WIFI_LED_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["WIFI_LED_ENABLE"] == 0x01) then
        streams[keytable["KEY_WIFI_LED_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["FUNCTION_LED_ENABLE"] == 0x00) then
        streams[keytable["KEY_FUNCTION_LED_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["FUNCTION_LED_ENABLE"] == 0x01) then
        streams[keytable["KEY_FUNCTION_LED_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["DIGIT_LED_ENABLE"] == 0x00) then
        streams[keytable["KEY_DIGIT_LED_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["DIGIT_LED_ENABLE"] == 0x01) then
        streams[keytable["KEY_DIGIT_LED_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["TIMING1_ENABLE"] == 0x00) then
        streams[keytable["KEY_TIMING1_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["TIMING1_ENABLE"] == 0x01) then
        streams[keytable["KEY_TIMING1_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["TIMING1_FUNCTION"] == 0x01) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] = VALUE_FUNCTION_MAIN_LIGHT
    elseif (valuetable["TIMING1_FUNCTION"] == 0x02) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] = VALUE_FUNCTION_NIGHT_LIGHT
    elseif (valuetable["TIMING1_FUNCTION"] == 0x03) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] = VALUE_FUNCTION_HEATING_HIGHT
    elseif (valuetable["TIMING1_FUNCTION"] == 0x04) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] = VALUE_FUNCTION_HEATING_LOW
    elseif (valuetable["TIMING1_FUNCTION"] == 0x05) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] = VALUE_FUNCTION_BATH
    elseif (valuetable["TIMING1_FUNCTION"] == 0x06) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] = VALUE_FUNCTION_VENTILATION
    elseif (valuetable["TIMING1_FUNCTION"] == 0x07) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] = VALUE_FUNCTION_BLOWING
    elseif (valuetable["TIMING1_FUNCTION"] == 0x08) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] =
            VALUE_FUNCTION_DRYING_SAFE_POWER
    elseif (valuetable["TIMING1_FUNCTION"] == 0x09) then
        streams[keytable["KEY_TIMING1_FUNCTION"]] = VALUE_FUNCTION_DRYING_FAST
    end
    if (valuetable["TIMING1_DATE_REPEAT"] ~= 0xFF) then
        streams[keytable["KEY_TIMING1_DATE_REPEAT"]] = ""
        if (bit.band(valuetable["TIMING1_DATE_REPEAT"], 0x80) ~= 0) then
            streams[keytable["KEY_TIMING1_DATE_REPEAT"]] = "once"
        else
            if (bit.band(valuetable["TIMING1_DATE_REPEAT"], 0x01) ~= 0) then
                streams[keytable["KEY_TIMING1_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING1_DATE_REPEAT"]] .. "sunday,"
            end
            if (bit.band(valuetable["TIMING1_DATE_REPEAT"], 0x02) ~= 0) then
                streams[keytable["KEY_TIMING1_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING1_DATE_REPEAT"]] .. "monday,"
            end
            if (bit.band(valuetable["TIMING1_DATE_REPEAT"], 0x04) ~= 0) then
                streams[keytable["KEY_TIMING1_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING1_DATE_REPEAT"]] .. "tuesday,"
            end
            if (bit.band(valuetable["TIMING1_DATE_REPEAT"], 0x08) ~= 0) then
                streams[keytable["KEY_TIMING1_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING1_DATE_REPEAT"]] .. "wednesday,"
            end
            if (bit.band(valuetable["TIMING1_DATE_REPEAT"], 0x10) ~= 0) then
                streams[keytable["KEY_TIMING1_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING1_DATE_REPEAT"]] .. "thursday,"
            end
            if (bit.band(valuetable["TIMING1_DATE_REPEAT"], 0x20) ~= 0) then
                streams[keytable["KEY_TIMING1_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING1_DATE_REPEAT"]] .. "friday,"
            end
            if (bit.band(valuetable["TIMING1_DATE_REPEAT"], 0x40) ~= 0) then
                streams[keytable["KEY_TIMING1_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING1_DATE_REPEAT"]] .. "saturday,"
            end
            streams[keytable["KEY_TIMING1_DATE_REPEAT"]] = string.sub(
                                                               streams[keytable["KEY_TIMING1_DATE_REPEAT"]],
                                                               1, -2)
        end
    end
    if (valuetable["TIMING1_OPENINT_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING1_OPENINT_TIME"]] =
            string.format("%02d", valuetable["TIMING1_OPENINT_TIME_HOUR"])
        streams[keytable["KEY_TIMING1_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING1_OPENINT_TIME"]] .. ":"
        streams[keytable["KEY_TIMING1_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING1_OPENINT_TIME"]] ..
                string.format("%02d", valuetable["TIMING1_OPENINT_TIME_MIN"])
    end
    if (valuetable["TIMING1_CLOSING_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING1_CLOSING_TIME"]] =
            string.format("%02d", valuetable["TIMING1_CLOSING_TIME_HOUR"])
        streams[keytable["KEY_TIMING1_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING1_CLOSING_TIME"]] .. ":"
        streams[keytable["KEY_TIMING1_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING1_CLOSING_TIME"]] ..
                string.format("%02d", valuetable["TIMING1_CLOSING_TIME_MIN"])
    end
    if (valuetable["TIMING2_ENABLE"] == 0x00) then
        streams[keytable["KEY_TIMING2_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["TIMING2_ENABLE"] == 0x01) then
        streams[keytable["KEY_TIMING2_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["TIMING2_FUNCTION"] == 0x01) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] = VALUE_FUNCTION_MAIN_LIGHT
    elseif (valuetable["TIMING2_FUNCTION"] == 0x02) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] = VALUE_FUNCTION_NIGHT_LIGHT
    elseif (valuetable["TIMING2_FUNCTION"] == 0x03) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] = VALUE_FUNCTION_HEATING_HIGHT
    elseif (valuetable["TIMING2_FUNCTION"] == 0x04) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] = VALUE_FUNCTION_HEATING_LOW
    elseif (valuetable["TIMING2_FUNCTION"] == 0x05) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] = VALUE_FUNCTION_BATH
    elseif (valuetable["TIMING2_FUNCTION"] == 0x06) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] = VALUE_FUNCTION_VENTILATION
    elseif (valuetable["TIMING2_FUNCTION"] == 0x07) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] = VALUE_FUNCTION_BLOWING
    elseif (valuetable["TIMING2_FUNCTION"] == 0x08) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] =
            VALUE_FUNCTION_DRYING_SAFE_POWER
    elseif (valuetable["TIMING2_FUNCTION"] == 0x09) then
        streams[keytable["KEY_TIMING2_FUNCTION"]] = VALUE_FUNCTION_DRYING_FAST
    end
    if (valuetable["TIMING2_DATE_REPEAT"] ~= 0xFF) then
        streams[keytable["KEY_TIMING2_DATE_REPEAT"]] = ""
        if (bit.band(valuetable["TIMING2_DATE_REPEAT"], 0x80) ~= 0) then
            streams[keytable["KEY_TIMING2_DATE_REPEAT"]] = "once"
        else
            if (bit.band(valuetable["TIMING2_DATE_REPEAT"], 0x01) ~= 0) then
                streams[keytable["KEY_TIMING2_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING2_DATE_REPEAT"]] .. "sunday,"
            end
            if (bit.band(valuetable["TIMING2_DATE_REPEAT"], 0x02) ~= 0) then
                streams[keytable["KEY_TIMING2_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING2_DATE_REPEAT"]] .. "monday,"
            end
            if (bit.band(valuetable["TIMING2_DATE_REPEAT"], 0x04) ~= 0) then
                streams[keytable["KEY_TIMING2_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING2_DATE_REPEAT"]] .. "tuesday,"
            end
            if (bit.band(valuetable["TIMING2_DATE_REPEAT"], 0x08) ~= 0) then
                streams[keytable["KEY_TIMING2_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING2_DATE_REPEAT"]] .. "wednesday,"
            end
            if (bit.band(valuetable["TIMING2_DATE_REPEAT"], 0x10) ~= 0) then
                streams[keytable["KEY_TIMING2_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING2_DATE_REPEAT"]] .. "thursday,"
            end
            if (bit.band(valuetable["TIMING2_DATE_REPEAT"], 0x20) ~= 0) then
                streams[keytable["KEY_TIMING2_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING2_DATE_REPEAT"]] .. "friday,"
            end
            if (bit.band(valuetable["TIMING2_DATE_REPEAT"], 0x40) ~= 0) then
                streams[keytable["KEY_TIMING2_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING2_DATE_REPEAT"]] .. "saturday,"
            end
            streams[keytable["KEY_TIMING2_DATE_REPEAT"]] = string.sub(
                                                               streams[keytable["KEY_TIMING2_DATE_REPEAT"]],
                                                               1, -2)
        end
    end
    if (valuetable["TIMING2_OPENINT_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING2_OPENINT_TIME"]] =
            string.format("%02d", valuetable["TIMING2_OPENINT_TIME_HOUR"])
        streams[keytable["KEY_TIMING2_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING2_OPENINT_TIME"]] .. ":"
        streams[keytable["KEY_TIMING2_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING2_OPENINT_TIME"]] ..
                string.format("%02d", valuetable["TIMING2_OPENINT_TIME_MIN"])
    end
    if (valuetable["TIMING2_CLOSING_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING2_CLOSING_TIME"]] =
            string.format("%02d", valuetable["TIMING2_CLOSING_TIME_HOUR"])
        streams[keytable["KEY_TIMING2_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING2_CLOSING_TIME"]] .. ":"
        streams[keytable["KEY_TIMING2_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING2_CLOSING_TIME"]] ..
                string.format("%02d", valuetable["TIMING2_CLOSING_TIME_MIN"])
    end
    if (valuetable["TIMING3_ENABLE"] == 0x00) then
        streams[keytable["KEY_TIMING3_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["TIMING3_ENABLE"] == 0x01) then
        streams[keytable["KEY_TIMING3_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["TIMING3_FUNCTION"] == 0x01) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] = VALUE_FUNCTION_MAIN_LIGHT
    elseif (valuetable["TIMING3_FUNCTION"] == 0x02) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] = VALUE_FUNCTION_NIGHT_LIGHT
    elseif (valuetable["TIMING3_FUNCTION"] == 0x03) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] = VALUE_FUNCTION_HEATING_HIGHT
    elseif (valuetable["TIMING3_FUNCTION"] == 0x04) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] = VALUE_FUNCTION_HEATING_LOW
    elseif (valuetable["TIMING3_FUNCTION"] == 0x05) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] = VALUE_FUNCTION_BATH
    elseif (valuetable["TIMING3_FUNCTION"] == 0x06) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] = VALUE_FUNCTION_VENTILATION
    elseif (valuetable["TIMING3_FUNCTION"] == 0x07) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] = VALUE_FUNCTION_BLOWING
    elseif (valuetable["TIMING3_FUNCTION"] == 0x08) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] =
            VALUE_FUNCTION_DRYING_SAFE_POWER
    elseif (valuetable["TIMING3_FUNCTION"] == 0x09) then
        streams[keytable["KEY_TIMING3_FUNCTION"]] = VALUE_FUNCTION_DRYING_FAST
    end
    if (valuetable["TIMING3_DATE_REPEAT"] ~= 0xFF) then
        streams[keytable["KEY_TIMING3_DATE_REPEAT"]] = ""
        if (bit.band(valuetable["TIMING3_DATE_REPEAT"], 0x80) ~= 0) then
            streams[keytable["KEY_TIMING3_DATE_REPEAT"]] = "once"
        else
            if (bit.band(valuetable["TIMING3_DATE_REPEAT"], 0x01) ~= 0) then
                streams[keytable["KEY_TIMING3_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING3_DATE_REPEAT"]] .. "sunday,"
            end
            if (bit.band(valuetable["TIMING3_DATE_REPEAT"], 0x02) ~= 0) then
                streams[keytable["KEY_TIMING3_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING3_DATE_REPEAT"]] .. "monday,"
            end
            if (bit.band(valuetable["TIMING3_DATE_REPEAT"], 0x04) ~= 0) then
                streams[keytable["KEY_TIMING3_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING3_DATE_REPEAT"]] .. "tuesday,"
            end
            if (bit.band(valuetable["TIMING3_DATE_REPEAT"], 0x08) ~= 0) then
                streams[keytable["KEY_TIMING3_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING3_DATE_REPEAT"]] .. "wednesday,"
            end
            if (bit.band(valuetable["TIMING3_DATE_REPEAT"], 0x10) ~= 0) then
                streams[keytable["KEY_TIMING3_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING3_DATE_REPEAT"]] .. "thursday,"
            end
            if (bit.band(valuetable["TIMING3_DATE_REPEAT"], 0x20) ~= 0) then
                streams[keytable["KEY_TIMING3_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING3_DATE_REPEAT"]] .. "friday,"
            end
            if (bit.band(valuetable["TIMING3_DATE_REPEAT"], 0x40) ~= 0) then
                streams[keytable["KEY_TIMING3_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING3_DATE_REPEAT"]] .. "saturday,"
            end
            streams[keytable["KEY_TIMING3_DATE_REPEAT"]] = string.sub(
                                                               streams[keytable["KEY_TIMING3_DATE_REPEAT"]],
                                                               1, -2)
        end
    end
    if (valuetable["TIMING3_OPENINT_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING3_OPENINT_TIME"]] =
            string.format("%02d", valuetable["TIMING3_OPENINT_TIME_HOUR"])
        streams[keytable["KEY_TIMING3_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING3_OPENINT_TIME"]] .. ":"
        streams[keytable["KEY_TIMING3_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING3_OPENINT_TIME"]] ..
                string.format("%02d", valuetable["TIMING3_OPENINT_TIME_MIN"])
    end
    if (valuetable["TIMING3_CLOSING_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING3_CLOSING_TIME"]] =
            string.format("%02d", valuetable["TIMING3_CLOSING_TIME_HOUR"])
        streams[keytable["KEY_TIMING3_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING3_CLOSING_TIME"]] .. ":"
        streams[keytable["KEY_TIMING3_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING3_CLOSING_TIME"]] ..
                string.format("%02d", valuetable["TIMING3_CLOSING_TIME_MIN"])
    end
    if (valuetable["TIMING4_ENABLE"] == 0x00) then
        streams[keytable["KEY_TIMING4_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["TIMING4_ENABLE"] == 0x01) then
        streams[keytable["KEY_TIMING4_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["TIMING4_FUNCTION"] == 0x01) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] = VALUE_FUNCTION_MAIN_LIGHT
    elseif (valuetable["TIMING4_FUNCTION"] == 0x02) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] = VALUE_FUNCTION_NIGHT_LIGHT
    elseif (valuetable["TIMING4_FUNCTION"] == 0x03) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] = VALUE_FUNCTION_HEATING_HIGHT
    elseif (valuetable["TIMING4_FUNCTION"] == 0x04) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] = VALUE_FUNCTION_HEATING_LOW
    elseif (valuetable["TIMING4_FUNCTION"] == 0x05) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] = VALUE_FUNCTION_BATH
    elseif (valuetable["TIMING4_FUNCTION"] == 0x06) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] = VALUE_FUNCTION_VENTILATION
    elseif (valuetable["TIMING4_FUNCTION"] == 0x07) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] = VALUE_FUNCTION_BLOWING
    elseif (valuetable["TIMING4_FUNCTION"] == 0x08) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] =
            VALUE_FUNCTION_DRYING_SAFE_POWER
    elseif (valuetable["TIMING4_FUNCTION"] == 0x09) then
        streams[keytable["KEY_TIMING4_FUNCTION"]] = VALUE_FUNCTION_DRYING_FAST
    end
    if (valuetable["TIMING4_DATE_REPEAT"] ~= 0xFF) then
        streams[keytable["KEY_TIMING4_DATE_REPEAT"]] = ""
        if (bit.band(valuetable["TIMING4_DATE_REPEAT"], 0x80) ~= 0) then
            streams[keytable["KEY_TIMING4_DATE_REPEAT"]] = "once"
        else
            if (bit.band(valuetable["TIMING4_DATE_REPEAT"], 0x01) ~= 0) then
                streams[keytable["KEY_TIMING4_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING4_DATE_REPEAT"]] .. "sunday,"
            end
            if (bit.band(valuetable["TIMING4_DATE_REPEAT"], 0x02) ~= 0) then
                streams[keytable["KEY_TIMING4_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING4_DATE_REPEAT"]] .. "monday,"
            end
            if (bit.band(valuetable["TIMING4_DATE_REPEAT"], 0x04) ~= 0) then
                streams[keytable["KEY_TIMING4_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING4_DATE_REPEAT"]] .. "tuesday,"
            end
            if (bit.band(valuetable["TIMING4_DATE_REPEAT"], 0x08) ~= 0) then
                streams[keytable["KEY_TIMING4_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING4_DATE_REPEAT"]] .. "wednesday,"
            end
            if (bit.band(valuetable["TIMING4_DATE_REPEAT"], 0x10) ~= 0) then
                streams[keytable["KEY_TIMING4_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING4_DATE_REPEAT"]] .. "thursday,"
            end
            if (bit.band(valuetable["TIMING4_DATE_REPEAT"], 0x20) ~= 0) then
                streams[keytable["KEY_TIMING4_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING4_DATE_REPEAT"]] .. "friday,"
            end
            if (bit.band(valuetable["TIMING4_DATE_REPEAT"], 0x40) ~= 0) then
                streams[keytable["KEY_TIMING4_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING4_DATE_REPEAT"]] .. "saturday,"
            end
            streams[keytable["KEY_TIMING4_DATE_REPEAT"]] = string.sub(
                                                               streams[keytable["KEY_TIMING4_DATE_REPEAT"]],
                                                               1, -2)
        end
    end
    if (valuetable["TIMING4_OPENINT_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING4_OPENINT_TIME"]] =
            string.format("%02d", valuetable["TIMING4_OPENINT_TIME_HOUR"])
        streams[keytable["KEY_TIMING4_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING4_OPENINT_TIME"]] .. ":"
        streams[keytable["KEY_TIMING4_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING4_OPENINT_TIME"]] ..
                string.format("%02d", valuetable["TIMING4_OPENINT_TIME_MIN"])
    end
    if (valuetable["TIMING4_CLOSING_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING4_CLOSING_TIME"]] =
            string.format("%02d", valuetable["TIMING4_CLOSING_TIME_HOUR"])
        streams[keytable["KEY_TIMING4_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING4_CLOSING_TIME"]] .. ":"
        streams[keytable["KEY_TIMING4_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING4_CLOSING_TIME"]] ..
                string.format("%02d", valuetable["TIMING4_CLOSING_TIME_MIN"])
    end
    if (valuetable["TIMING5_ENABLE"] == 0x00) then
        streams[keytable["KEY_TIMING5_ENABLE"]] = VALUE_FUNCTION_OFF
    elseif (valuetable["TIMING5_ENABLE"] == 0x01) then
        streams[keytable["KEY_TIMING5_ENABLE"]] = VALUE_FUNCTION_ON
    end
    if (valuetable["TIMING5_FUNCTION"] == 0x01) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] = VALUE_FUNCTION_MAIN_LIGHT
    elseif (valuetable["TIMING5_FUNCTION"] == 0x02) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] = VALUE_FUNCTION_NIGHT_LIGHT
    elseif (valuetable["TIMING5_FUNCTION"] == 0x03) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] = VALUE_FUNCTION_HEATING_HIGHT
    elseif (valuetable["TIMING5_FUNCTION"] == 0x04) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] = VALUE_FUNCTION_HEATING_LOW
    elseif (valuetable["TIMING5_FUNCTION"] == 0x05) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] = VALUE_FUNCTION_BATH
    elseif (valuetable["TIMING5_FUNCTION"] == 0x06) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] = VALUE_FUNCTION_VENTILATION
    elseif (valuetable["TIMING5_FUNCTION"] == 0x07) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] = VALUE_FUNCTION_BLOWING
    elseif (valuetable["TIMING5_FUNCTION"] == 0x08) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] =
            VALUE_FUNCTION_DRYING_SAFE_POWER
    elseif (valuetable["TIMING5_FUNCTION"] == 0x09) then
        streams[keytable["KEY_TIMING5_FUNCTION"]] = VALUE_FUNCTION_DRYING_FAST
    end
    if (valuetable["TIMING5_DATE_REPEAT"] ~= 0xFF) then
        streams[keytable["KEY_TIMING5_DATE_REPEAT"]] = ""
        if (bit.band(valuetable["TIMING5_DATE_REPEAT"], 0x80) ~= 0) then
            streams[keytable["KEY_TIMING5_DATE_REPEAT"]] = "once"
        else
            if (bit.band(valuetable["TIMING5_DATE_REPEAT"], 0x01) ~= 0) then
                streams[keytable["KEY_TIMING5_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING5_DATE_REPEAT"]] .. "sunday,"
            end
            if (bit.band(valuetable["TIMING5_DATE_REPEAT"], 0x02) ~= 0) then
                streams[keytable["KEY_TIMING5_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING5_DATE_REPEAT"]] .. "monday,"
            end
            if (bit.band(valuetable["TIMING5_DATE_REPEAT"], 0x04) ~= 0) then
                streams[keytable["KEY_TIMING5_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING5_DATE_REPEAT"]] .. "tuesday,"
            end
            if (bit.band(valuetable["TIMING5_DATE_REPEAT"], 0x08) ~= 0) then
                streams[keytable["KEY_TIMING5_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING5_DATE_REPEAT"]] .. "wednesday,"
            end
            if (bit.band(valuetable["TIMING5_DATE_REPEAT"], 0x10) ~= 0) then
                streams[keytable["KEY_TIMING5_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING5_DATE_REPEAT"]] .. "thursday,"
            end
            if (bit.band(valuetable["TIMING5_DATE_REPEAT"], 0x20) ~= 0) then
                streams[keytable["KEY_TIMING5_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING5_DATE_REPEAT"]] .. "friday,"
            end
            if (bit.band(valuetable["TIMING5_DATE_REPEAT"], 0x40) ~= 0) then
                streams[keytable["KEY_TIMING5_DATE_REPEAT"]] =
                    streams[keytable["KEY_TIMING5_DATE_REPEAT"]] .. "saturday,"
            end
            streams[keytable["KEY_TIMING5_DATE_REPEAT"]] = string.sub(
                                                               streams[keytable["KEY_TIMING5_DATE_REPEAT"]],
                                                               1, -2)
        end
    end
    if (valuetable["TIMING5_OPENINT_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING5_OPENINT_TIME"]] =
            string.format("%02d", valuetable["TIMING5_OPENINT_TIME_HOUR"])
        streams[keytable["KEY_TIMING5_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING5_OPENINT_TIME"]] .. ":"
        streams[keytable["KEY_TIMING5_OPENINT_TIME"]] =
            streams[keytable["KEY_TIMING5_OPENINT_TIME"]] ..
                string.format("%02d", valuetable["TIMING5_OPENINT_TIME_MIN"])
    end
    if (valuetable["TIMING5_CLOSING_TIME_HOUR"] ~= 0xFF) then
        streams[keytable["KEY_TIMING5_CLOSING_TIME"]] =
            string.format("%02d", valuetable["TIMING5_CLOSING_TIME_HOUR"])
        streams[keytable["KEY_TIMING5_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING5_CLOSING_TIME"]] .. ":"
        streams[keytable["KEY_TIMING5_CLOSING_TIME"]] =
            streams[keytable["KEY_TIMING5_CLOSING_TIME"]] ..
                string.format("%02d", valuetable["TIMING5_CLOSING_TIME_MIN"])
    end
    if (valuetable["HARDWARE_VERSION"] ~= "") then
        streams[keytable["KEY_HARDWARE_VERSION"]] =
            valuetable["HARDWARE_VERSION"]
    end
    if (valuetable["SOFTWARE_VERSION"] ~= "") then
        streams[keytable["KEY_SOFTWARE_VERSION"]] =
            valuetable["SOFTWARE_VERSION"]
    end
    return streams
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local bodyBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        updateGlobalPropertyValueByJson(control)
        if (cmdType == 0x01) then
            for i = 0, 48 do bodyBytes[i] = 0xFF; end
            bodyBytes[0] = 0x01
            bodyBytes[1] = valuetable["MAIN_LIGHT_ENABLE"]
            bodyBytes[2] = valuetable["MAIN_LIGHT_BRIGHTNESS"]
            bodyBytes[3] = valuetable["NIGHT_LIGHT_ENABLE"]
            bodyBytes[4] = valuetable["NIGHT_LIGHT_BRIGHTNESS"]
            bodyBytes[5] = valuetable["RADAR_INDUCTION_ENABLE"]
            bodyBytes[6] = valuetable["RADAR_INDUCTION_CLOSING_TIME"]
            bodyBytes[7] = valuetable["LIGHT_INTENSITY_THRESHOLD"]
            bodyBytes[8] = valuetable["RADAR_SENSITIVITY"]
            bodyBytes[9] = valuetable["HEATING_ENABLE"]
            bodyBytes[10] = valuetable["HEATING_TEMPERATURE"]
            bodyBytes[11] = valuetable["HEATING_SPEED"]
            bodyBytes[12] = valuetable["HEATING_DIRECTION"]
            bodyBytes[13] = valuetable["BATH_ENABLE"]
            bodyBytes[14] = valuetable["BATH_HEATING_TIME"]
            bodyBytes[15] = valuetable["BATH_TEMPERATURE"]
            bodyBytes[16] = valuetable["BATH_SPEED"]
            bodyBytes[17] = valuetable["BATH_DIRECTION"]
            bodyBytes[18] = valuetable["VENTILATION_ENABLE"]
            bodyBytes[19] = valuetable["VENTILATION_SPEED"]
            bodyBytes[20] = valuetable["VENTILATION_DIRECTION"]
            bodyBytes[21] = valuetable["DRYING_ENABLE"]
            bodyBytes[22] = valuetable["DRYING_TIME"]
            bodyBytes[23] = valuetable["DRYING_TEMPERATURE"]
            bodyBytes[24] = valuetable["DRYING_SPEED"]
            bodyBytes[25] = valuetable["DRYING_DIRECTION"]
            bodyBytes[26] = valuetable["BLOWING_ENABLE"]
            bodyBytes[27] = valuetable["BLOWING_SPEED"]
            bodyBytes[28] = valuetable["BLOWING_DIRECTION"]
            bodyBytes[29] = valuetable["DELAY_ENABLE"]
            bodyBytes[30] = valuetable["DELAY_TIME"]
            bodyBytes[31] = valuetable["SOFT_WIND_ENABLE"]
            bodyBytes[32] = valuetable["SOFT_WIND_HEATING_TIME"]
            bodyBytes[33] = valuetable["SOFT_WIND_TEMPERATURE"]
            bodyBytes[34] = valuetable["SOFT_WIND_SPEED"]
            bodyBytes[35] = valuetable["SOFT_WIND_DIRECTION"]
            bodyBytes[36] = valuetable["WINDLESS_ENABLE"]
            bodyBytes[37] = valuetable["ANION_ENABLE"]
            bodyBytes[38] = valuetable["SMELLY_ENABLE"]
            bodyBytes[39] = valuetable["SMELLY_THRESHOLD"]
            bodyBytes[40] = 0xFF
            bodyBytes[41] = 0xFF
            bodyBytes[42] = 0xFF
            bodyBytes[43] = valuetable["AUTO_DEHUMIDIFICATION"]
            bodyBytes[44] = valuetable["DEHUMIDITY_THRESHOLD"]
            bodyBytes[45] = valuetable["DEHUMIDITY_TIME"]
            bodyBytes[46] = valuetable["DEHUMIDITY_INTERVAL_TIME"]
            bodyBytes[47] = valuetable["DEHUMIDITY_DIRECTION"]
            bodyBytes[48] = 0xFF
            if (valuetable["WIFI_LED_ENABLE"] == 0x00) then
                bodyBytes[48] = bit.band(bodyBytes[48], 0xFC)
            elseif (valuetable["WIFI_LED_ENABLE"] == 0x01) then
                bodyBytes[48] = bit.band(bodyBytes[48], 0xFD)
            end
            if (valuetable["FUNCTION_LED_ENABLE"] == 0x00) then
                bodyBytes[48] = bit.band(bodyBytes[48], 0xF3)
            elseif (valuetable["FUNCTION_LED_ENABLE"] == 0x01) then
                bodyBytes[48] = bit.band(bodyBytes[48], 0xF7)
            end
            if (valuetable["DIGIT_LED_ENABLE"] == 0x00) then
                bodyBytes[48] = bit.band(bodyBytes[48], 0xCF)
            elseif (valuetable["DIGIT_LED_ENABLE"] == 0x01) then
                bodyBytes[48] = bit.band(bodyBytes[48], 0xDF)
            end
        elseif (cmdType == 0x02) then
            for i = 0, 35 do bodyBytes[i] = 0x00; end
            bodyBytes[0] = 0x02
            bodyBytes[1] = valuetable["TIMING1_ENABLE"]
            bodyBytes[2] = valuetable["TIMING1_FUNCTION"]
            bodyBytes[3] = valuetable["TIMING1_DATE_REPEAT"]
            bodyBytes[4] = valuetable["TIMING1_OPENINT_TIME_HOUR"]
            bodyBytes[5] = valuetable["TIMING1_OPENINT_TIME_MIN"]
            bodyBytes[6] = valuetable["TIMING1_CLOSING_TIME_HOUR"]
            bodyBytes[7] = valuetable["TIMING1_CLOSING_TIME_MIN"]
            bodyBytes[8] = valuetable["TIMING2_ENABLE"]
            bodyBytes[9] = valuetable["TIMING2_FUNCTION"]
            bodyBytes[10] = valuetable["TIMING2_DATE_REPEAT"]
            bodyBytes[11] = valuetable["TIMING2_OPENINT_TIME_HOUR"]
            bodyBytes[12] = valuetable["TIMING2_OPENINT_TIME_MIN"]
            bodyBytes[13] = valuetable["TIMING2_CLOSING_TIME_HOUR"]
            bodyBytes[14] = valuetable["TIMING2_CLOSING_TIME_MIN"]
            bodyBytes[15] = valuetable["TIMING3_ENABLE"]
            bodyBytes[16] = valuetable["TIMING3_FUNCTION"]
            bodyBytes[17] = valuetable["TIMING3_DATE_REPEAT"]
            bodyBytes[18] = valuetable["TIMING3_OPENINT_TIME_HOUR"]
            bodyBytes[19] = valuetable["TIMING3_OPENINT_TIME_MIN"]
            bodyBytes[20] = valuetable["TIMING3_CLOSING_TIME_HOUR"]
            bodyBytes[21] = valuetable["TIMING3_CLOSING_TIME_MIN"]
            bodyBytes[22] = valuetable["TIMING4_ENABLE"]
            bodyBytes[23] = valuetable["TIMING4_FUNCTION"]
            bodyBytes[24] = valuetable["TIMING4_DATE_REPEAT"]
            bodyBytes[25] = valuetable["TIMING4_OPENINT_TIME_HOUR"]
            bodyBytes[26] = valuetable["TIMING4_OPENINT_TIME_MIN"]
            bodyBytes[27] = valuetable["TIMING4_CLOSING_TIME_HOUR"]
            bodyBytes[28] = valuetable["TIMING4_CLOSING_TIME_MIN"]
            bodyBytes[29] = valuetable["TIMING5_ENABLE"]
            bodyBytes[30] = valuetable["TIMING5_FUNCTION"]
            bodyBytes[31] = valuetable["TIMING5_DATE_REPEAT"]
            bodyBytes[31] = valuetable["TIMING5_OPENINT_TIME_HOUR"]
            bodyBytes[33] = valuetable["TIMING5_OPENINT_TIME_MIN"]
            bodyBytes[34] = valuetable["TIMING5_CLOSING_TIME_HOUR"]
            bodyBytes[35] = valuetable["TIMING5_CLOSING_TIME_MIN"]
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        bodyBytes[0] = 0x01
        if (query[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_TIMING_QUERY) then
            bodyBytes[0] = 0x02
        elseif (query[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_VERSION_QUERY) then
            bodyBytes[0] = 0x03
        end
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
    elseif (status) then
        if (status[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_FUNCTION_REPORT) then
            bodyBytes[0] = 0x01
        elseif (status[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_TIMING_REPORT) then
            bodyBytes[0] = 0x02
        elseif (status[keytable["KEY_SUB_PACKET_TYPE"]] == VALUE_VERSION_REPORT) then
            bodyBytes[0] = 0x03
        end
        if (status[keytable["KEY_RESULT"]] ~= VALUE_SUCCESS) then
            bodyBytes[1] = 0x01
        end
        msgBytes = assembleUart(bodyBytes, BYTE_REPORT_ACK)
    end
    local infoM = {}
    local length = #msgBytes + 1
    for i = 1, length do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decodeJsonToTable(jsonStr)
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10]
    cmdType = byteData[11]
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end
