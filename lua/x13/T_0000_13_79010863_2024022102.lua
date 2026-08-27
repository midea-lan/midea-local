local bit = require "bit"
local JSON = require "cjson"
local BYTE_DEVICE_TYPE = 0x13
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local VALUE_UNKNOWN = "unknown"
local VALUE_INVALID = "invalid"
local dataType = 0
local cmdType = 0
local keytable = {}
keytable["KEY_VERSION"] = "version"
keytable["KEY_TOGGLE_POWER"] = "toggle_power"
keytable["KEY_LED_POWER"] = "led_power"
keytable["KEY_FAN_POWER"] = "fan_power"
keytable["KEY_EN_ANION"] = "en_anion"
keytable["KEY_ANION_POWER"] = "anion_power"
keytable["KEY_DISPLAY_OFF"] = "displap_off"
keytable["KEY_LED_SCENE_LIGHT"] = "led_scene_light"
keytable["KEY_FAN_SCENE"] = "fan_scene"
keytable["KEY_DELAY_LIGHT_OFF"] = "delay_light_off"
keytable["KEY_DELAY_FAN_OFF"] = "delay_fan_off"
keytable["KEY_CONST_TEMP_VALUE"] = "const_temperature_value"
keytable["KEY_COLOR_TEMPERATURE"] = "color_temperature"
keytable["KEY_BRIGHTNESS"] = "brightness"
keytable["KEY_ARROUND_DIR"] = "arround_dir"
keytable["KEY_FAN_SPEED"] = "fan_speed"
keytable["KEY_LAMP_TYPE"] = "lamp_type"
keytable["KEY_TEMPERATURE_MIN"] = "temperature_min"
keytable["KEY_TEMPERATURE_MAX"] = "temperature_max"
keytable["KEY_LED_ENABLE_TIMEING_1"] = "led_enable_timeing_1"
keytable["KEY_LED_ENABLE_TIMEING_2"] = "led_enable_timeing_2"
keytable["KEY_LED_ENABLE_TIMEING_3"] = "led_enable_timeing_3"
keytable["KEY_LED_ENABLE_TIMEING_4"] = "led_enable_timeing_4"
keytable["KEY_LED_ENABLE_TIMEING_5"] = "led_enable_timeing_5"
keytable["KEY_LED_ENABLE_TIMEING_6"] = "led_enable_timeing_6"
keytable["KEY_LED_ENABLE_TIMEING_7"] = "led_enable_timeing_7"
keytable["KEY_LED_ENABLE_TIMEING_8"] = "led_enable_timeing_8"
keytable["KEY_LED_ENABLE_TIMEING_9"] = "led_enable_timeing_9"
keytable["KEY_LED_ENABLE_TIMEING_10"] = "led_enable_timeing_10"
keytable["KEY_FAN_ENABLE_TIMEING_1"] = "fan_enable_timeing_1"
keytable["KEY_FAN_ENABLE_TIMEING_2"] = "fan_enable_timeing_2"
keytable["KEY_FAN_ENABLE_TIMEING_3"] = "fan_enable_timeing_3"
keytable["KEY_FAN_ENABLE_TIMEING_4"] = "fan_enable_timeing_4"
keytable["KEY_FAN_ENABLE_TIMEING_5"] = "fan_enable_timeing_5"
keytable["KEY_FAN_ENABLE_TIMEING_6"] = "fan_enable_timeing_6"
keytable["KEY_FAN_ENABLE_TIMEING_7"] = "fan_enable_timeing_7"
keytable["KEY_FAN_ENABLE_TIMEING_8"] = "fan_enable_timeing_8"
keytable["KEY_FAN_ENABLE_TIMEING_9"] = "fan_enable_timeing_9"
keytable["KEY_FAN_ENABLE_TIMEING_10"] = "fan_enable_timeing_10"
keytable["KEY_LED_TIME_ONOFF_1"] = "led_time_onoff_1"
keytable["KEY_LED_TIME_ONOFF_2"] = "led_time_onoff_2"
keytable["KEY_LED_TIME_ONOFF_3"] = "led_time_onoff_3"
keytable["KEY_LED_TIME_ONOFF_4"] = "led_time_onoff_4"
keytable["KEY_LED_TIME_ONOFF_5"] = "led_time_onoff_5"
keytable["KEY_LED_TIME_ONOFF_6"] = "led_time_onoff_6"
keytable["KEY_LED_TIME_ONOFF_7"] = "led_time_onoff_7"
keytable["KEY_LED_TIME_ONOFF_8"] = "led_time_onoff_8"
keytable["KEY_LED_TIME_ONOFF_9"] = "led_time_onoff_9"
keytable["KEY_LED_TIME_ONOFF_10"] = "led_time_onoff_10"
keytable["KEY_FAN_TIME_ONOFF_1"] = "fan_time_onoff_1"
keytable["KEY_FAN_TIME_ONOFF_2"] = "fan_time_onoff_2"
keytable["KEY_FAN_TIME_ONOFF_3"] = "fan_time_onoff_3"
keytable["KEY_FAN_TIME_ONOFF_4"] = "fan_time_onoff_4"
keytable["KEY_FAN_TIME_ONOFF_5"] = "fan_time_onoff_5"
keytable["KEY_FAN_TIME_ONOFF_6"] = "fan_time_onoff_6"
keytable["KEY_FAN_TIME_ONOFF_7"] = "fan_time_onoff_7"
keytable["KEY_FAN_TIME_ONOFF_8"] = "fan_time_onoff_8"
keytable["KEY_FAN_TIME_ONOFF_9"] = "fan_time_onoff_9"
keytable["KEY_FAN_TIME_ONOFF_10"] = "fan_time_onoff_10"
keytable["KEY_LED_CTRL_ONOFF_1"] = "led_ctrl_onoff_1"
keytable["KEY_LED_CTRL_ONOFF_2"] = "led_ctrl_onoff_2"
keytable["KEY_LED_CTRL_ONOFF_3"] = "led_ctrl_onoff_3"
keytable["KEY_LED_CTRL_ONOFF_4"] = "led_ctrl_onoff_4"
keytable["KEY_LED_CTRL_ONOFF_5"] = "led_ctrl_onoff_5"
keytable["KEY_LED_CTRL_ONOFF_6"] = "led_ctrl_onoff_6"
keytable["KEY_LED_CTRL_ONOFF_7"] = "led_ctrl_onoff_7"
keytable["KEY_LED_CTRL_ONOFF_8"] = "led_ctrl_onoff_8"
keytable["KEY_LED_CTRL_ONOFF_9"] = "led_ctrl_onoff_9"
keytable["KEY_LED_CTRL_ONOFF_10"] = "led_ctrl_onoff_10"
keytable["KEY_FAN_CTRL_ONOFF_1"] = "fan_ctrl_onoff_1"
keytable["KEY_FAN_CTRL_ONOFF_2"] = "fan_ctrl_onoff_2"
keytable["KEY_FAN_CTRL_ONOFF_3"] = "fan_ctrl_onoff_3"
keytable["KEY_FAN_CTRL_ONOFF_4"] = "fan_ctrl_onoff_4"
keytable["KEY_FAN_CTRL_ONOFF_5"] = "fan_ctrl_onoff_5"
keytable["KEY_FAN_CTRL_ONOFF_6"] = "fan_ctrl_onoff_6"
keytable["KEY_FAN_CTRL_ONOFF_7"] = "fan_ctrl_onoff_7"
keytable["KEY_FAN_CTRL_ONOFF_8"] = "fan_ctrl_onoff_8"
keytable["KEY_FAN_CTRL_ONOFF_9"] = "fan_ctrl_onoff_9"
keytable["KEY_FAN_CTRL_ONOFF_10"] = "fan_ctrl_onoff_10"
keytable["KEY_LED_MONDAY_ENDIS_1"] = "led_monday_endis_1"
keytable["KEY_LED_TUESDAY_ENDIS_1"] = "led_tuesday_endis_1"
keytable["KEY_LED_WEDNESDAY_ENDIS_1"] = "led_wednesday_endis_1"
keytable["KEY_LED_THURSDAY_ENDIS_1"] = "led_thursday_endis_1"
keytable["KEY_LED_FRIDAY_ENDIS_1"] = "led_friday_endis_1"
keytable["KEY_LED_SATURDAY_ENDIS_1"] = "led_saturday_endis_1"
keytable["KEY_LED_SUNDAY_ENDIS_1"] = "led_sunday_endis_1"
keytable["KEY_LED_MONDAY_ENDIS_2"] = "led_monday_endis_2"
keytable["KEY_LED_TUESDAY_ENDIS_2"] = "led_tuesday_endis_2"
keytable["KEY_LED_WEDNESDAY_ENDIS_2"] = "led_wednesday_endis_2"
keytable["KEY_LED_THURSDAY_ENDIS_2"] = "led_thursday_endis_2"
keytable["KEY_LED_FRIDAY_ENDIS_2"] = "led_friday_endis_2"
keytable["KEY_LED_SATURDAY_ENDIS_2"] = "led_saturday_endis_2"
keytable["KEY_LED_SUNDAY_ENDIS_2"] = "led_sunday_endis_2"
keytable["KEY_LED_MONDAY_ENDIS_3"] = "led_monday_endis_3"
keytable["KEY_LED_TUESDAY_ENDIS_3"] = "led_tuesday_endis_3"
keytable["KEY_LED_WEDNESDAY_ENDIS_3"] = "led_wednesday_endis_3"
keytable["KEY_LED_THURSDAY_ENDIS_3"] = "led_thursday_endis_3"
keytable["KEY_LED_FRIDAY_ENDIS_3"] = "led_friday_endis_3"
keytable["KEY_LED_SATURDAY_ENDIS_3"] = "led_saturday_endis_3"
keytable["KEY_LED_SUNDAY_ENDIS_3"] = "led_sunday_endis_3"
keytable["KEY_LED_MONDAY_ENDIS_4"] = "led_monday_endis_4"
keytable["KEY_LED_TUESDAY_ENDIS_4"] = "led_tuesday_endis_4"
keytable["KEY_LED_WEDNESDAY_ENDIS_4"] = "led_wednesday_endis_4"
keytable["KEY_LED_THURSDAY_ENDIS_4"] = "led_thursday_endis_4"
keytable["KEY_LED_FRIDAY_ENDIS_4"] = "led_friday_endis_4"
keytable["KEY_LED_SATURDAY_ENDIS_4"] = "led_saturday_endis_4"
keytable["KEY_LED_SUNDAY_ENDIS_4"] = "led_sunday_endis_4"
keytable["KEY_LED_MONDAY_ENDIS_5"] = "led_monday_endis_5"
keytable["KEY_LED_TUESDAY_ENDIS_5"] = "led_tuesday_endis_5"
keytable["KEY_LED_WEDNESDAY_ENDIS_5"] = "led_wednesday_endis_5"
keytable["KEY_LED_THURSDAY_ENDIS_5"] = "led_thursday_endis_5"
keytable["KEY_LED_FRIDAY_ENDIS_5"] = "led_friday_endis_5"
keytable["KEY_LED_SATURDAY_ENDIS_5"] = "led_saturday_endis_5"
keytable["KEY_LED_SUNDAY_ENDIS_5"] = "led_sunday_endis_5"
keytable["KEY_LED_MONDAY_ENDIS_6"] = "led_monday_endis_6"
keytable["KEY_LED_TUESDAY_ENDIS_6"] = "led_tuesday_endis_6"
keytable["KEY_LED_WEDNESDAY_ENDIS_6"] = "led_wednesday_endis_6"
keytable["KEY_LED_THURSDAY_ENDIS_6"] = "led_thursday_endis_6"
keytable["KEY_LED_FRIDAY_ENDIS_6"] = "led_friday_endis_6"
keytable["KEY_LED_SATURDAY_ENDIS_6"] = "led_saturday_endis_6"
keytable["KEY_LED_SUNDAY_ENDIS_6"] = "led_sunday_endis_6"
keytable["KEY_LED_MONDAY_ENDIS_7"] = "led_monday_endis_7"
keytable["KEY_LED_TUESDAY_ENDIS_7"] = "led_tuesday_endis_7"
keytable["KEY_LED_WEDNESDAY_ENDIS_7"] = "led_wednesday_endis_7"
keytable["KEY_LED_THURSDAY_ENDIS_7"] = "led_thursday_endis_7"
keytable["KEY_LED_FRIDAY_ENDIS_7"] = "led_friday_endis_7"
keytable["KEY_LED_SATURDAY_ENDIS_7"] = "led_saturday_endis_7"
keytable["KEY_LED_SUNDAY_ENDIS_7"] = "led_sunday_endis_7"
keytable["KEY_LED_MONDAY_ENDIS_8"] = "led_monday_endis_8"
keytable["KEY_LED_TUESDAY_ENDIS_8"] = "led_tuesday_endis_8"
keytable["KEY_LED_WEDNESDAY_ENDIS_8"] = "led_wednesday_endis_8"
keytable["KEY_LED_THURSDAY_ENDIS_8"] = "led_thursday_endis_8"
keytable["KEY_LED_FRIDAY_ENDIS_8"] = "led_friday_endis_8"
keytable["KEY_LED_SATURDAY_ENDIS_8"] = "led_saturday_endis_8"
keytable["KEY_LED_SUNDAY_ENDIS_8"] = "led_sunday_endis_8"
keytable["KEY_LED_MONDAY_ENDIS_9"] = "led_monday_endis_9"
keytable["KEY_LED_TUESDAY_ENDIS_9"] = "led_tuesday_endis_9"
keytable["KEY_LED_WEDNESDAY_ENDIS_9"] = "led_wednesday_endis_9"
keytable["KEY_LED_THURSDAY_ENDIS_9"] = "led_thursday_endis_9"
keytable["KEY_LED_FRIDAY_ENDIS_9"] = "led_friday_endis_9"
keytable["KEY_LED_SATURDAY_ENDIS_9"] = "led_saturday_endis_9"
keytable["KEY_LED_SUNDAY_ENDIS_9"] = "led_sunday_endis_9"
keytable["KEY_LED_MONDAY_ENDIS_10"] = "led_monday_endis_10"
keytable["KEY_LED_TUESDAY_ENDIS_10"] = "led_tuesday_endis_10"
keytable["KEY_LED_WEDNESDAY_ENDIS_10"] = "led_wednesday_endis_10"
keytable["KEY_LED_THURSDAY_ENDIS_10"] = "led_thursday_endis_10"
keytable["KEY_LED_FRIDAY_ENDIS_10"] = "led_friday_endis_10"
keytable["KEY_LED_SATURDAY_ENDIS_10"] = "led_saturday_endis_10"
keytable["KEY_LED_SUNDAY_ENDIS_10"] = "led_sunday_endis_10"
keytable["KEY_FAN_MONDAY_ENDIS_1"] = "fan_monday_endis_1"
keytable["KEY_FAN_TUESDAY_ENDIS_1"] = "fan_tuesday_endis_1"
keytable["KEY_FAN_WEDNESDAY_ENDIS_1"] = "fan_wednesday_endis_1"
keytable["KEY_FAN_THURSDAY_ENDIS_1"] = "fan_thursday_endis_1"
keytable["KEY_FAN_FRIDAY_ENDIS_1"] = "fan_friday_endis_1"
keytable["KEY_FAN_SATURDAY_ENDIS_1"] = "fan_saturday_endis_1"
keytable["KEY_FAN_SUNDAY_ENDIS_1"] = "fan_sunday_endis_1"
keytable["KEY_FAN_MONDAY_ENDIS_2"] = "fan_monday_endis_2"
keytable["KEY_FAN_TUESDAY_ENDIS_2"] = "fan_tuesday_endis_2"
keytable["KEY_FAN_WEDNESDAY_ENDIS_2"] = "fan_wednesday_endis_2"
keytable["KEY_FAN_THURSDAY_ENDIS_2"] = "fan_thursday_endis_2"
keytable["KEY_FAN_FRIDAY_ENDIS_2"] = "fan_friday_endis_2"
keytable["KEY_FAN_SATURDAY_ENDIS_2"] = "fan_saturday_endis_2"
keytable["KEY_FAN_SUNDAY_ENDIS_2"] = "fan_sunday_endis_2"
keytable["KEY_FAN_MONDAY_ENDIS_3"] = "fan_monday_endis_3"
keytable["KEY_FAN_TUESDAY_ENDIS_3"] = "fan_tuesday_endis_3"
keytable["KEY_FAN_WEDNESDAY_ENDIS_3"] = "fan_wednesday_endis_3"
keytable["KEY_FAN_THURSDAY_ENDIS_3"] = "fan_thursday_endis_3"
keytable["KEY_FAN_FRIDAY_ENDIS_3"] = "fan_friday_endis_3"
keytable["KEY_FAN_SATURDAY_ENDIS_3"] = "fan_saturday_endis_3"
keytable["KEY_FAN_SUNDAY_ENDIS_3"] = "fan_sunday_endis_3"
keytable["KEY_FAN_MONDAY_ENDIS_4"] = "fan_monday_endis_4"
keytable["KEY_FAN_TUESDAY_ENDIS_4"] = "fan_tuesday_endis_4"
keytable["KEY_FAN_WEDNESDAY_ENDIS_4"] = "fan_wednesday_endis_4"
keytable["KEY_FAN_THURSDAY_ENDIS_4"] = "fan_thursday_endis_4"
keytable["KEY_FAN_FRIDAY_ENDIS_4"] = "fan_friday_endis_4"
keytable["KEY_FAN_SATURDAY_ENDIS_4"] = "fan_saturday_endis_4"
keytable["KEY_FAN_SUNDAY_ENDIS_4"] = "fan_sunday_endis_4"
keytable["KEY_FAN_MONDAY_ENDIS_5"] = "fan_monday_endis_5"
keytable["KEY_FAN_TUESDAY_ENDIS_5"] = "fan_tuesday_endis_5"
keytable["KEY_FAN_WEDNESDAY_ENDIS_5"] = "fan_wednesday_endis_5"
keytable["KEY_FAN_THURSDAY_ENDIS_5"] = "fan_thursday_endis_5"
keytable["KEY_FAN_FRIDAY_ENDIS_5"] = "fan_friday_endis_5"
keytable["KEY_FAN_SATURDAY_ENDIS_5"] = "fan_saturday_endis_5"
keytable["KEY_FAN_SUNDAY_ENDIS_5"] = "fan_sunday_endis_5"
keytable["KEY_FAN_MONDAY_ENDIS_6"] = "fan_monday_endis_6"
keytable["KEY_FAN_TUESDAY_ENDIS_6"] = "fan_tuesday_endis_6"
keytable["KEY_FAN_WEDNESDAY_ENDIS_6"] = "fan_wednesday_endis_6"
keytable["KEY_FAN_THURSDAY_ENDIS_6"] = "fan_thursday_endis_6"
keytable["KEY_FAN_FRIDAY_ENDIS_6"] = "fan_friday_endis_6"
keytable["KEY_FAN_SATURDAY_ENDIS_6"] = "fan_saturday_endis_6"
keytable["KEY_FAN_SUNDAY_ENDIS_6"] = "fan_sunday_endis_6"
keytable["KEY_FAN_MONDAY_ENDIS_7"] = "fan_monday_endis_7"
keytable["KEY_FAN_TUESDAY_ENDIS_7"] = "fan_tuesday_endis_7"
keytable["KEY_FAN_WEDNESDAY_ENDIS_7"] = "fan_wednesday_endis_7"
keytable["KEY_FAN_THURSDAY_ENDIS_7"] = "fan_thursday_endis_7"
keytable["KEY_FAN_FRIDAY_ENDIS_7"] = "fan_friday_endis_7"
keytable["KEY_FAN_SATURDAY_ENDIS_7"] = "fan_saturday_endis_7"
keytable["KEY_FAN_SUNDAY_ENDIS_7"] = "fan_sunday_endis_7"
keytable["KEY_FAN_MONDAY_ENDIS_8"] = "fan_monday_endis_8"
keytable["KEY_FAN_TUESDAY_ENDIS_8"] = "fan_tuesday_endis_8"
keytable["KEY_FAN_WEDNESDAY_ENDIS_8"] = "fan_wednesday_endis_8"
keytable["KEY_FAN_THURSDAY_ENDIS_8"] = "fan_thursday_endis_8"
keytable["KEY_FAN_FRIDAY_ENDIS_8"] = "fan_friday_endis_8"
keytable["KEY_FAN_SATURDAY_ENDIS_8"] = "fan_saturday_endis_8"
keytable["KEY_FAN_SUNDAY_ENDIS_8"] = "fan_sunday_endis_8"
keytable["KEY_FAN_MONDAY_ENDIS_9"] = "fan_monday_endis_9"
keytable["KEY_FAN_TUESDAY_ENDIS_9"] = "fan_tuesday_endis_9"
keytable["KEY_FAN_WEDNESDAY_ENDIS_9"] = "fan_wednesday_endis_9"
keytable["KEY_FAN_THURSDAY_ENDIS_9"] = "fan_thursday_endis_9"
keytable["KEY_FAN_FRIDAY_ENDIS_9"] = "fan_friday_endis_9"
keytable["KEY_FAN_SATURDAY_ENDIS_9"] = "fan_saturday_endis_9"
keytable["KEY_FAN_SUNDAY_ENDIS_9"] = "fan_sunday_endis_9"
keytable["KEY_FAN_MONDAY_ENDIS_10"] = "fan_monday_endis_10"
keytable["KEY_FAN_TUESDAY_ENDIS_10"] = "fan_tuesday_endis_10"
keytable["KEY_FAN_WEDNESDAY_ENDIS_10"] = "fan_wednesday_endis_10"
keytable["KEY_FAN_THURSDAY_ENDIS_10"] = "fan_thursday_endis_10"
keytable["KEY_FAN_FRIDAY_ENDIS_10"] = "fan_friday_endis_10"
keytable["KEY_FAN_SATURDAY_ENDIS_10"] = "fan_saturday_endis_10"
keytable["KEY_FAN_SUNDAY_ENDIS_10"] = "fan_sunday_endis_10"
keytable["KEY_RESULT"] = "result"
local valuetable = {}
local lamptype = 0
local valresult = 0
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
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    resVal = 255 - resVal + 1
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
    msgBytes[2] = BYTE_DEVICE_TYPE
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
local function string2hexstring(str)
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
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
    valuetable["TOGGLELEDPOWER"] = 1
    valuetable["LEDPOWER"] = 0
    valuetable["FANPOWER"] = 0
    valuetable["ANION_POWER"] = 0
    valuetable["DISPLAY_OFF"] = 0
    valuetable["LEDSCENCELIGHT"] = 1
    valuetable["FANSCENEMODE"] = 1
    valuetable["COLORTEMPERATURE"] = 0
    valuetable["BRIGHTNESSVAL"] = 0
    valuetable["ARROUNDDIR"] = 0
    valuetable["FANSPEED"] = 0
    valuetable["CONSTTMEPVALUE"] = 26
    valuetable["DELAYLIGHTOFF"] = 0
    valuetable["DELAYFANOFF"] = 0
    valuetable["LED_TIME_OF_HOUR_1"] = 0
    valuetable["LED_TIME_OF_HOUR_2"] = 0
    valuetable["LED_TIME_OF_HOUR_3"] = 0
    valuetable["LED_TIME_OF_HOUR_4"] = 0
    valuetable["LED_TIME_OF_HOUR_5"] = 0
    valuetable["LED_TIME_OF_HOUR_6"] = 0
    valuetable["LED_TIME_OF_HOUR_7"] = 0
    valuetable["LED_TIME_OF_HOUR_8"] = 0
    valuetable["LED_TIME_OF_HOUR_9"] = 0
    valuetable["LED_TIME_OF_HOUR_10"] = 0
    valuetable["LED_TIME_OF_MINUTE_1"] = 0
    valuetable["LED_TIME_OF_MINUTE_2"] = 0
    valuetable["LED_TIME_OF_MINUTE_3"] = 0
    valuetable["LED_TIME_OF_MINUTE_4"] = 0
    valuetable["LED_TIME_OF_MINUTE_5"] = 0
    valuetable["LED_TIME_OF_MINUTE_6"] = 0
    valuetable["LED_TIME_OF_MINUTE_7"] = 0
    valuetable["LED_TIME_OF_MINUTE_8"] = 0
    valuetable["LED_TIME_OF_MINUTE_9"] = 0
    valuetable["LED_TIME_OF_MINUTE_10"] = 0
    valuetable["FAN_TIME_OF_HOUR_1"] = 0
    valuetable["FAN_TIME_OF_HOUR_2"] = 0
    valuetable["FAN_TIME_OF_HOUR_3"] = 0
    valuetable["FAN_TIME_OF_HOUR_4"] = 0
    valuetable["FAN_TIME_OF_HOUR_5"] = 0
    valuetable["FAN_TIME_OF_HOUR_6"] = 0
    valuetable["FAN_TIME_OF_HOUR_7"] = 0
    valuetable["FAN_TIME_OF_HOUR_8"] = 0
    valuetable["FAN_TIME_OF_HOUR_9"] = 0
    valuetable["FAN_TIME_OF_HOUR_10"] = 0
    valuetable["FAN_TIME_OF_MINUTE_1"] = 0
    valuetable["FAN_TIME_OF_MINUTE_2"] = 0
    valuetable["FAN_TIME_OF_MINUTE_3"] = 0
    valuetable["FAN_TIME_OF_MINUTE_4"] = 0
    valuetable["FAN_TIME_OF_MINUTE_5"] = 0
    valuetable["FAN_TIME_OF_MINUTE_6"] = 0
    valuetable["FAN_TIME_OF_MINUTE_7"] = 0
    valuetable["FAN_TIME_OF_MINUTE_8"] = 0
    valuetable["FAN_TIME_OF_MINUTE_9"] = 0
    valuetable["FAN_TIME_OF_MINUTE_10"] = 0
    valuetable["LED_ENABLE_TIMEING_1"] = 0
    valuetable["LED_ENABLE_TIMEING_2"] = 0
    valuetable["LED_ENABLE_TIMEING_3"] = 0
    valuetable["LED_ENABLE_TIMEING_4"] = 0
    valuetable["LED_ENABLE_TIMEING_5"] = 0
    valuetable["LED_ENABLE_TIMEING_6"] = 0
    valuetable["LED_ENABLE_TIMEING_7"] = 0
    valuetable["LED_ENABLE_TIMEING_8"] = 0
    valuetable["LED_ENABLE_TIMEING_9"] = 0
    valuetable["LED_ENABLE_TIMEING_10"] = 0
    valuetable["FAN_ENABLE_TIMEING_1"] = 0
    valuetable["FAN_ENABLE_TIMEING_2"] = 0
    valuetable["FAN_ENABLE_TIMEING_3"] = 0
    valuetable["FAN_ENABLE_TIMEING_4"] = 0
    valuetable["FAN_ENABLE_TIMEING_5"] = 0
    valuetable["FAN_ENABLE_TIMEING_6"] = 0
    valuetable["FAN_ENABLE_TIMEING_7"] = 0
    valuetable["FAN_ENABLE_TIMEING_8"] = 0
    valuetable["FAN_ENABLE_TIMEING_9"] = 0
    valuetable["FAN_ENABLE_TIMEING_10"] = 0
    valuetable["LED_CTRL_ONOFF_1"] = 0
    valuetable["LED_CTRL_ONOFF_2"] = 0
    valuetable["LED_CTRL_ONOFF_3"] = 0
    valuetable["LED_CTRL_ONOFF_4"] = 0
    valuetable["LED_CTRL_ONOFF_5"] = 0
    valuetable["LED_CTRL_ONOFF_6"] = 0
    valuetable["LED_CTRL_ONOFF_7"] = 0
    valuetable["LED_CTRL_ONOFF_8"] = 0
    valuetable["LED_CTRL_ONOFF_9"] = 0
    valuetable["LED_CTRL_ONOFF_10"] = 0
    valuetable["FAN_CTRL_ONOFF_1"] = 0
    valuetable["FAN_CTRL_ONOFF_2"] = 0
    valuetable["FAN_CTRL_ONOFF_3"] = 0
    valuetable["FAN_CTRL_ONOFF_4"] = 0
    valuetable["FAN_CTRL_ONOFF_5"] = 0
    valuetable["FAN_CTRL_ONOFF_6"] = 0
    valuetable["FAN_CTRL_ONOFF_7"] = 0
    valuetable["FAN_CTRL_ONOFF_8"] = 0
    valuetable["FAN_CTRL_ONOFF_9"] = 0
    valuetable["FAN_CTRL_ONOFF_10"] = 0
    valuetable["LED_WEEK_EN_DIS_1"] = 0
    valuetable["LED_WEEK_EN_DIS_2"] = 0
    valuetable["LED_WEEK_EN_DIS_3"] = 0
    valuetable["LED_WEEK_EN_DIS_4"] = 0
    valuetable["LED_WEEK_EN_DIS_5"] = 0
    valuetable["LED_WEEK_EN_DIS_6"] = 0
    valuetable["LED_WEEK_EN_DIS_7"] = 0
    valuetable["LED_WEEK_EN_DIS_8"] = 0
    valuetable["LED_WEEK_EN_DIS_9"] = 0
    valuetable["LED_WEEK_EN_DIS_10"] = 0
    valuetable["FAN_WEEK_EN_DIS_1"] = 0
    valuetable["FAN_WEEK_EN_DIS_2"] = 0
    valuetable["FAN_WEEK_EN_DIS_3"] = 0
    valuetable["FAN_WEEK_EN_DIS_4"] = 0
    valuetable["FAN_WEEK_EN_DIS_5"] = 0
    valuetable["FAN_WEEK_EN_DIS_6"] = 0
    valuetable["FAN_WEEK_EN_DIS_7"] = 0
    valuetable["FAN_WEEK_EN_DIS_8"] = 0
    valuetable["FAN_WEEK_EN_DIS_9"] = 0
    valuetable["FAN_WEEK_EN_DIS_10"] = 0
    valuetable["anion_enable"] = 0
    valuetable["TEMPERATURE_MIN"] = 0x0a8c
    valuetable["TEMPERATURE_MAX"] = 0x1964
end
local function updateGlobalPropertyValueByJson(luaTable)
    local temp = 0
    valueTableInitialization()
    if luaTable[keytable["KEY_TOGGLE_POWER"]] == "1" then
        valuetable["TOGGLELEDPOWER"] = 0x01
    end
    if luaTable[keytable["KEY_LED_POWER"]] == "on" then
        valuetable["LEDPOWER"] = 0x01
    elseif luaTable[keytable["KEY_LED_POWER"]] == "off" then
        valuetable["LEDPOWER"] = 0x00
    end
    if luaTable[keytable["KEY_FAN_POWER"]] == "on" then
        valuetable["FANPOWER"] = 0x01
    elseif luaTable[keytable["KEY_FAN_POWER"]] == "off" then
        valuetable["FANPOWER"] = 0x00
    end
    if luaTable[keytable["KEY_ANION_POWER"]] == "on" then
        valuetable["ANION_POWER"] = 0x01
    else
        valuetable["ANION_POWER"] = 0x00
    end
    if luaTable[keytable["KEY_DISPLAY_OFF"]] == "off" then
        valuetable["DISPLAY_OFF"] = 0x01
    else
        valuetable["DISPLAY_OFF"] = 0x00
    end
    if luaTable[keytable["KEY_LED_SCENE_LIGHT"]] == "work" then
        valuetable["LEDSCENCELIGHT"] = 0x02
    elseif luaTable[keytable["KEY_LED_SCENE_LIGHT"]] == "eating" then
        valuetable["LEDSCENCELIGHT"] = 0x03
    elseif luaTable[keytable["KEY_LED_SCENE_LIGHT"]] == "night" then
        valuetable["LEDSCENCELIGHT"] = 0x04
    elseif luaTable[keytable["KEY_LED_SCENE_LIGHT"]] == "film" then
        valuetable["LEDSCENCELIGHT"] = 0x05
    elseif luaTable[keytable["KEY_LED_SCENE_LIGHT"]] == "ledmanual" then
        valuetable["LEDSCENCELIGHT"] = 0x01
    end
    if luaTable[keytable["KEY_FAN_SCENE"]] == "breathing_wind" then
        valuetable["FANSCENEMODE"] = 0x02
    elseif luaTable[keytable["KEY_FAN_SCENE"]] == "const_temperature" then
        valuetable["FANSCENEMODE"] = 0x03
    elseif luaTable[keytable["KEY_FAN_SCENE"]] == "fanmanual" then
        valuetable["FANSCENEMODE"] = 0x01
    end
    if luaTable[keytable["KEY_CONST_TEMP_VALUE"]] ~= nil then
        valuetable["CONSTTMEPVALUE"] = string2Int(
                                           luaTable[keytable["KEY_CONST_TEMP_VALUE"]])
    end
    if luaTable[keytable["KEY_COLOR_TEMPERATURE"]] ~= nil then
        valuetable["COLORTEMPERATURE"] = string2Int(
                                             luaTable[keytable["KEY_COLOR_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_BRIGHTNESS"]] ~= nil then
        valuetable["BRIGHTNESSVAL"] = string2Int(
                                          luaTable[keytable["KEY_BRIGHTNESS"]])
    end
    if luaTable[keytable["KEY_DELAY_LIGHT_OFF"]] ~= nil then
        valuetable["DELAYLIGHTOFF"] = string2Int(
                                          luaTable[keytable["KEY_DELAY_LIGHT_OFF"]])
    end
    if luaTable[keytable["KEY_DELAY_FAN_OFF"]] ~= nil then
        valuetable["DELAYFANOFF"] = string2Int(
                                        luaTable[keytable["KEY_DELAY_FAN_OFF"]])
    end
    if luaTable[keytable["KEY_ARROUND_DIR"]] ~= nil then
        valuetable["ARROUNDDIR"] = string2Int(
                                       luaTable[keytable["KEY_ARROUND_DIR"]])
    end
    if luaTable[keytable["KEY_FAN_SPEED"]] ~= nil then
        valuetable["FANSPEED"] = string2Int(luaTable[keytable["KEY_FAN_SPEED"]])
    end
    if luaTable[keytable["KEY_EN_ANION"]] == "on" then
        valuetable["anion_enable"] = 0x80
    else
        valuetable["anion_enable"] = 0x00
    end
    if luaTable[keytable["KEY_TEMPERATURE_MIN"]] ~= nil then
        valuetable["TEMPERATURE_MIN"] = string2Int(
                                            luaTable[keytable["KEY_TEMPERATURE_MIN"]])
    end
    if luaTable[keytable["KEY_TEMPERATURE_MAX"]] ~= nil then
        valuetable["TEMPERATURE_MAX"] = string2Int(
                                            luaTable[keytable["KEY_TEMPERATURE_MAX"]])
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_1"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_1"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_1"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_1"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_1"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_1"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_1"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_1"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_1"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_1"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_1"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_1"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_1"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_1"]] == '1' then
            valuetable["LED_CTRL_ONOFF_1"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_1"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_1"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_1"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_1"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_1"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_1"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_1"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_1"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_1"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_2"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_2"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_2"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_2"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_2"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_2"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_2"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_2"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_2"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_2"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_2"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_2"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_2"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_2"]] == '1' then
            valuetable["LED_CTRL_ONOFF_2"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_2"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_2"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_2"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_2"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_2"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_2"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_2"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_2"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_2"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_3"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_3"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_3"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_3"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_3"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_3"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_3"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_3"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_3"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_3"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_3"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_3"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_3"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_3"]] == '1' then
            valuetable["LED_CTRL_ONOFF_3"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_3"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_3"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_3"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_3"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_3"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_3"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_3"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_3"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_3"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_4"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_4"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_4"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_4"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_4"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_4"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_4"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_4"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_4"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_4"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_4"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_4"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_4"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_4"]] == '1' then
            valuetable["LED_CTRL_ONOFF_4"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_4"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_4"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_4"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_4"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_4"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_4"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_4"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_4"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_4"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_5"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_5"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_5"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_5"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_5"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_5"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_5"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_5"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_5"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_5"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_5"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_5"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_5"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_5"]] == '1' then
            valuetable["LED_CTRL_ONOFF_5"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_5"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_5"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_5"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_5"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_5"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_5"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_5"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_5"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_5"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_6"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_6"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_6"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_6"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_6"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_6"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_6"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_6"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_6"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_6"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_6"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_6"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_6"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_6"]] == '1' then
            valuetable["LED_CTRL_ONOFF_6"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_6"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_6"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_6"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_6"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_6"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_6"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_6"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_6"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_6"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_7"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_7"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_7"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_7"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_7"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_7"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_7"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_7"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_7"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_7"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_7"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_7"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_7"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_7"]] == '1' then
            valuetable["LED_CTRL_ONOFF_7"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_7"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_7"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_7"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_7"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_7"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_7"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_7"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_7"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_7"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_8"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_8"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_8"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_8"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_8"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_8"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_8"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_8"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_8"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_8"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_8"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_8"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_8"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_8"]] == '1' then
            valuetable["LED_CTRL_ONOFF_8"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_8"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_8"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_8"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_8"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_8"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_8"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_8"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_8"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_8"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_9"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_9"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_9"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_9"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_9"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_9"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0x02)
        else
            valuetable["LED_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_9"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0x04)
        else
            valuetable["LED_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_9"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0x08)
        else
            valuetable["LED_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_9"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0x10)
        else
            valuetable["LED_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_9"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0x20)
        else
            valuetable["LED_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_9"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0x40)
        else
            valuetable["LED_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_9"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0x01)
        else
            valuetable["LED_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["LED_WEEK_EN_DIS_9"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_9"]] == '1' then
            valuetable["LED_CTRL_ONOFF_9"] = bit.bor(
                                                 valuetable["LED_CTRL_ONOFF_9"],
                                                 0x80)
        else
            valuetable["LED_CTRL_ONOFF_9"] = bit.band(
                                                 valuetable["LED_CTRL_ONOFF_9"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_9"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_9"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_9"] = bit.bor(
                                                     valuetable["LED_ENABLE_TIMEING_9"],
                                                     0x80)
        else
            valuetable["LED_ENABLE_TIMEING_9"] = bit.band(
                                                     valuetable["LED_ENABLE_TIMEING_9"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_TIME_ONOFF_10"]] ~= nil then
        valuetable["LED_TIME_OF_HOUR_10"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_10"]]),
                                  1, 2))
        valuetable["LED_TIME_OF_MINUTE_10"] =
            string2Int(string.sub((luaTable[keytable["KEY_LED_TIME_ONOFF_10"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_LED_MONDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_MONDAY_ENDIS_10"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0x02)
        else
            valuetable["LED_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0xfd)
        end
    end
    if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_TUESDAY_ENDIS_10"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0x04)
        else
            valuetable["LED_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0xfb)
        end
    end
    if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_WEDNESDAY_ENDIS_10"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0x08)
        else
            valuetable["LED_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0xf7)
        end
    end
    if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_THURSDAY_ENDIS_10"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0x10)
        else
            valuetable["LED_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0xef)
        end
    end
    if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_FRIDAY_ENDIS_10"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0x20)
        else
            valuetable["LED_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0xdf)
        end
    end
    if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_SATURDAY_ENDIS_10"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0x40)
        else
            valuetable["LED_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0xbf)
        end
    end
    if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_SUNDAY_ENDIS_10"]] == '1' then
            valuetable["LED_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0x01)
        else
            valuetable["LED_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["LED_WEEK_EN_DIS_10"],
                                                   0xfe)
        end
    end
    if luaTable[keytable["KEY_LED_CTRL_ONOFF_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_CTRL_ONOFF_10"]] == '1' then
            valuetable["LED_CTRL_ONOFF_10"] = bit.bor(
                                                  valuetable["LED_CTRL_ONOFF_10"],
                                                  0x80)
        else
            valuetable["LED_CTRL_ONOFF_10"] = bit.band(
                                                  valuetable["LED_CTRL_ONOFF_10"],
                                                  0x7f)
        end
    end
    if luaTable[keytable["KEY_LED_ENABLE_TIMEING_10"]] ~= nil then
        if luaTable[keytable["KEY_LED_ENABLE_TIMEING_10"]] == '1' then
            valuetable["LED_ENABLE_TIMEING_10"] = bit.bor(
                                                      valuetable["LED_ENABLE_TIMEING_10"],
                                                      0x80)
        else
            valuetable["LED_ENABLE_TIMEING_10"] = bit.band(
                                                      valuetable["LED_ENABLE_TIMEING_10"],
                                                      0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_1"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_1"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_1"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_1"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_1"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_1"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_1"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_1"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_1"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_1"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_1"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_1"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_1"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_1"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_1"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_1"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_1"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_1"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_1"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_1"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_1"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_1"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_1"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_1"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_1"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_2"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_2"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_2"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_2"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_2"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_2"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_2"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_2"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_2"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_2"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_2"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_2"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_2"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_2"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_2"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_2"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_2"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_2"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_2"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_2"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_2"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_2"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_2"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_2"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_2"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_3"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_3"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_3"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_3"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_3"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_3"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_3"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_3"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_3"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_3"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_3"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_3"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_3"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_3"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_3"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_3"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_3"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_3"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_3"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_3"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_3"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_3"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_3"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_3"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_3"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_4"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_4"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_4"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_4"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_4"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_4"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_4"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_4"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_4"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_4"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_4"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_4"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_4"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_4"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_4"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_4"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_4"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_4"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_4"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_4"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_4"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_4"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_4"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_4"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_4"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_5"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_5"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_5"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_5"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_5"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_5"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_5"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_5"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_5"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_5"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_5"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_5"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_5"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_5"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_5"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_5"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_5"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_5"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_5"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_5"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_5"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_5"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_5"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_5"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_5"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_6"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_6"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_6"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_6"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_6"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_6"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_6"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_6"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_6"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_6"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_6"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_6"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_6"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_6"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_6"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_6"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_6"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_6"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_6"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_6"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_6"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_6"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_6"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_6"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_6"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_7"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_7"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_7"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_7"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_7"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_7"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_7"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_7"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_7"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_7"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_7"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_7"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_7"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_7"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_7"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_7"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_7"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_7"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_7"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_7"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_7"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_7"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_7"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_7"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_7"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_8"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_8"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_8"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_8"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_8"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_8"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_8"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_8"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_8"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_8"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_8"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_8"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_8"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_8"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_8"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_8"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_8"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_8"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_8"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_8"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_8"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_8"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_8"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_8"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_8"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_9"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_9"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_9"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_9"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_9"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_9"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_9"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_9"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_9"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_9"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_9"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_9"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.bor(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_9"] = bit.band(
                                                  valuetable["FAN_WEEK_EN_DIS_9"],
                                                  0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_9"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_9"] = bit.bor(
                                                 valuetable["FAN_CTRL_ONOFF_9"],
                                                 0x80)
        else
            valuetable["FAN_CTRL_ONOFF_9"] = bit.band(
                                                 valuetable["FAN_CTRL_ONOFF_9"],
                                                 0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_9"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_9"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_9"] = bit.bor(
                                                     valuetable["FAN_ENABLE_TIMEING_9"],
                                                     0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_9"] = bit.band(
                                                     valuetable["FAN_ENABLE_TIMEING_9"],
                                                     0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_TIME_ONOFF_10"]] ~= nil then
        valuetable["FAN_TIME_OF_HOUR_10"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_10"]]),
                                  1, 2))
        valuetable["FAN_TIME_OF_MINUTE_10"] =
            string2Int(string.sub((luaTable[keytable["KEY_FAN_TIME_ONOFF_10"]]),
                                  3, 4))
    end
    if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_MONDAY_ENDIS_10"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0x02)
        else
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0xfd)
        end
    end
    if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_TUESDAY_ENDIS_10"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0x04)
        else
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0xfb)
        end
    end
    if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_WEDNESDAY_ENDIS_10"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0x08)
        else
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0xf7)
        end
    end
    if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_THURSDAY_ENDIS_10"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0x10)
        else
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0xef)
        end
    end
    if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_FRIDAY_ENDIS_10"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0x20)
        else
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0xdf)
        end
    end
    if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SATURDAY_ENDIS_10"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0x40)
        else
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0xbf)
        end
    end
    if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_SUNDAY_ENDIS_10"]] == '1' then
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.bor(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0x01)
        else
            valuetable["FAN_WEEK_EN_DIS_10"] = bit.band(
                                                   valuetable["FAN_WEEK_EN_DIS_10"],
                                                   0xfe)
        end
    end
    if luaTable[keytable["KEY_FAN_CTRL_ONOFF_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_CTRL_ONOFF_10"]] == '1' then
            valuetable["FAN_CTRL_ONOFF_10"] = bit.bor(
                                                  valuetable["FAN_CTRL_ONOFF_10"],
                                                  0x80)
        else
            valuetable["FAN_CTRL_ONOFF_10"] = bit.band(
                                                  valuetable["FAN_CTRL_ONOFF_10"],
                                                  0x7f)
        end
    end
    if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_10"]] ~= nil then
        if luaTable[keytable["KEY_FAN_ENABLE_TIMEING_10"]] == '1' then
            valuetable["FAN_ENABLE_TIMEING_10"] = bit.bor(
                                                      valuetable["FAN_ENABLE_TIMEING_10"],
                                                      0x80)
        else
            valuetable["FAN_ENABLE_TIMEING_10"] = bit.band(
                                                      valuetable["FAN_ENABLE_TIMEING_10"],
                                                      0x7f)
        end
    end
end
local function updateGlobalPropertyValueByByte(messageBytes)
    local tmp = 0
    valueTableInitialization()
    cmdType = messageBytes[0]
    if cmdType == 0x81 then valresult = messageBytes[1] end
    if cmdType == 0xb1 then valresult = messageBytes[1] end
    if cmdType == 0x82 then valresult = messageBytes[1] end
    if cmdType == 0xb2 then valresult = messageBytes[1] end
    if cmdType == 0x83 then valresult = messageBytes[1] end
    if cmdType == 0xb3 then valresult = messageBytes[1] end
    if cmdType == 0x84 then valresult = messageBytes[1] end
    if cmdType == 0xb4 then valresult = messageBytes[1] end
    if cmdType == 0x85 then valresult = messageBytes[1] end
    if cmdType == 0xb5 then valresult = messageBytes[1] end
    if cmdType == 0x86 then valresult = messageBytes[1] end
    if cmdType == 0xb6 then valresult = messageBytes[1] end
    if cmdType == 0x87 then valresult = messageBytes[1] end
    if cmdType == 0x92 then valresult = messageBytes[1] end
    if cmdType == 0xb7 then valresult = messageBytes[1] end
    if cmdType == 0x88 then valresult = messageBytes[1] end
    if cmdType == 0xb8 then valresult = messageBytes[1] end
    if cmdType == 0x89 then valresult = messageBytes[1] end
    if cmdType == 0xb9 then valresult = messageBytes[1] end
    if cmdType == 0x8a then valresult = messageBytes[1] end
    if cmdType == 0xba then valresult = messageBytes[1] end
    if cmdType == 0x8b then valresult = messageBytes[1] end
    if cmdType == 0xbb then valresult = messageBytes[1] end
    if cmdType == 0x8c then valresult = messageBytes[1] end
    if cmdType == 0xbc then valresult = messageBytes[1] end
    if cmdType == 0x8d then valresult = messageBytes[1] end
    if cmdType == 0xbd then valresult = messageBytes[1] end
    if cmdType == 0x8e then valresult = messageBytes[1] end
    if cmdType == 0xbe then valresult = messageBytes[1] end
    if cmdType == 0x8f then valresult = messageBytes[1] end
    if cmdType == 0xbf then valresult = messageBytes[1] end
    if cmdType == 0xa4 then
        valuetable["BRIGHTNESSVAL"] = messageBytes[1]
        valuetable["COLORTEMPERATURE"] = messageBytes[2]
        valuetable["LEDSCENCELIGHT"] = messageBytes[3]
        tmp = messageBytes[4]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["anion_enable"] = 0x80
        else
            valuetable["anion_enable"] = 0x00
        end
        if (bit.band(tmp, 0x01) == 0x01) then
            valuetable["ANION_POWER"] = 0x01
        else
            valuetable["ANION_POWER"] = 0x00
        end
        valuetable["LEDPOWER"] = messageBytes[5]
        valuetable["FANSPEED"] = messageBytes[6]
        valuetable["ARROUNDDIR"] = messageBytes[7]
        valuetable["FANSCENEMODE"] = messageBytes[8]
        valuetable["FANPOWER"] = messageBytes[10]
        valuetable["LED_TIME_OF_HOUR_1"] = messageBytes[11]
        valuetable["LED_TIME_OF_MINUTE_1"] = messageBytes[12]
        tmp = messageBytes[13]
        valuetable["LED_WEEK_EN_DIS_1"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_1"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_1"] = 0x00
        end
        tmp = messageBytes[14]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_1"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_1"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_2"] = messageBytes[15]
        valuetable["LED_TIME_OF_MINUTE_2"] = messageBytes[16]
        tmp = messageBytes[17]
        valuetable["LED_WEEK_EN_DIS_2"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_2"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_2"] = 0x00
        end
        tmp = messageBytes[18]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_2"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_2"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_3"] = messageBytes[19]
        valuetable["LED_TIME_OF_MINUTE_3"] = messageBytes[20]
        tmp = messageBytes[21]
        valuetable["LED_WEEK_EN_DIS_3"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_3"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_3"] = 0x00
        end
        tmp = messageBytes[22]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_3"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_3"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_4"] = messageBytes[23]
        valuetable["LED_TIME_OF_MINUTE_4"] = messageBytes[24]
        tmp = messageBytes[25]
        valuetable["LED_WEEK_EN_DIS_4"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_4"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_4"] = 0x00
        end
        tmp = messageBytes[26]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_4"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_4"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_5"] = messageBytes[27]
        valuetable["LED_TIME_OF_MINUTE_5"] = messageBytes[28]
        tmp = messageBytes[29]
        valuetable["LED_WEEK_EN_DIS_5"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_5"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_5"] = 0x00
        end
        tmp = messageBytes[30]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_5"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_5"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_6"] = messageBytes[31]
        valuetable["LED_TIME_OF_MINUTE_6"] = messageBytes[32]
        tmp = messageBytes[33]
        valuetable["LED_WEEK_EN_DIS_6"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_6"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_6"] = 0x00
        end
        tmp = messageBytes[34]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_6"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_6"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_7"] = messageBytes[35]
        valuetable["LED_TIME_OF_MINUTE_7"] = messageBytes[36]
        tmp = messageBytes[37]
        valuetable["LED_WEEK_EN_DIS_7"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_7"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_7"] = 0x00
        end
        tmp = messageBytes[38]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_7"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_7"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_8"] = messageBytes[39]
        valuetable["LED_TIME_OF_MINUTE_8"] = messageBytes[40]
        tmp = messageBytes[41]
        valuetable["LED_WEEK_EN_DIS_8"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_8"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_8"] = 0x00
        end
        tmp = messageBytes[42]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_8"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_8"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_9"] = messageBytes[43]
        valuetable["LED_TIME_OF_MINUTE_9"] = messageBytes[44]
        tmp = messageBytes[45]
        valuetable["LED_WEEK_EN_DIS_9"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_9"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_9"] = 0x00
        end
        tmp = messageBytes[46]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_9"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_9"] = 0
        end
        valuetable["LED_TIME_OF_HOUR_10"] = messageBytes[47]
        valuetable["LED_TIME_OF_MINUTE_10"] = messageBytes[48]
        tmp = messageBytes[49]
        valuetable["LED_WEEK_EN_DIS_10"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_CTRL_ONOFF_10"] = 0x80
        else
            valuetable["LED_CTRL_ONOFF_10"] = 0x00
        end
        tmp = messageBytes[50]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["LED_ENABLE_TIMEING_10"] = 0x80
        else
            valuetable["LED_ENABLE_TIMEING_10"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_1"] = messageBytes[51]
        valuetable["FAN_TIME_OF_MINUTE_1"] = messageBytes[52]
        tmp = messageBytes[53]
        valuetable["FAN_WEEK_EN_DIS_1"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_1"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_1"] = 0x00
        end
        tmp = messageBytes[54]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_1"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_1"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_2"] = messageBytes[55]
        valuetable["FAN_TIME_OF_MINUTE_2"] = messageBytes[56]
        tmp = messageBytes[57]
        valuetable["FAN_WEEK_EN_DIS_2"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_2"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_2"] = 0x00
        end
        tmp = messageBytes[58]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_2"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_2"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_3"] = messageBytes[59]
        valuetable["FAN_TIME_OF_MINUTE_3"] = messageBytes[60]
        tmp = messageBytes[61]
        valuetable["FAN_WEEK_EN_DIS_3"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_3"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_3"] = 0x00
        end
        tmp = messageBytes[62]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_3"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_3"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_4"] = messageBytes[63]
        valuetable["FAN_TIME_OF_MINUTE_4"] = messageBytes[64]
        tmp = messageBytes[65]
        valuetable["FAN_WEEK_EN_DIS_4"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_4"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_4"] = 0x00
        end
        tmp = messageBytes[66]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_4"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_4"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_5"] = messageBytes[67]
        valuetable["FAN_TIME_OF_MINUTE_5"] = messageBytes[68]
        tmp = messageBytes[69]
        valuetable["FAN_WEEK_EN_DIS_5"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_5"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_5"] = 0x00
        end
        tmp = messageBytes[70]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_5"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_5"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_6"] = messageBytes[71]
        valuetable["FAN_TIME_OF_MINUTE_6"] = messageBytes[72]
        tmp = messageBytes[73]
        valuetable["FAN_WEEK_EN_DIS_6"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_6"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_6"] = 0x00
        end
        tmp = messageBytes[74]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_6"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_6"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_7"] = messageBytes[75]
        valuetable["FAN_TIME_OF_MINUTE_7"] = messageBytes[76]
        tmp = messageBytes[77]
        valuetable["FAN_WEEK_EN_DIS_7"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_7"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_7"] = 0x00
        end
        tmp = messageBytes[78]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_7"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_7"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_8"] = messageBytes[79]
        valuetable["FAN_TIME_OF_MINUTE_8"] = messageBytes[80]
        tmp = messageBytes[81]
        valuetable["FAN_WEEK_EN_DIS_8"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_8"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_8"] = 0x00
        end
        tmp = messageBytes[82]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_8"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_8"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_9"] = messageBytes[83]
        valuetable["FAN_TIME_OF_MINUTE_9"] = messageBytes[84]
        tmp = messageBytes[85]
        valuetable["FAN_WEEK_EN_DIS_9"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_9"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_9"] = 0x00
        end
        tmp = messageBytes[86]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_9"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_9"] = 0
        end
        valuetable["FAN_TIME_OF_HOUR_10"] = messageBytes[87]
        valuetable["FAN_TIME_OF_MINUTE_10"] = messageBytes[88]
        tmp = messageBytes[89]
        valuetable["FAN_WEEK_EN_DIS_10"] = bit.band(tmp, 0x7f)
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_CTRL_ONOFF_10"] = 0x80
        else
            valuetable["FAN_CTRL_ONOFF_10"] = 0x00
        end
        tmp = messageBytes[90]
        if (bit.band(tmp, 0x80) == 0x80) then
            valuetable["FAN_ENABLE_TIMEING_10"] = 0x80
        else
            valuetable["FAN_ENABLE_TIMEING_10"] = 0
        end
        valuetable["TEMPERATURE_MIN"] = messageBytes[91] * 256 +
                                            messageBytes[92]
        valuetable["TEMPERATURE_MAX"] = messageBytes[93] * 256 +
                                            messageBytes[94]
        valuetable["DELAYLIGHTOFF"] = messageBytes[95] * 256 + messageBytes[96]
        valuetable["DELAYFANOFF"] = messageBytes[97] * 256 + messageBytes[98]
        valuetable["CONSTTMEPVALUE"] = messageBytes[99]
        valuetable["DISPLAY_OFF"] = messageBytes[100]
        lamptype = messageBytes[101]
        valresult = 1
    end
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[keytable["KEY_VERSION"]] = '3'
    if cmdType == 0xa4 then
        streams[keytable["KEY_BRIGHTNESS"]] =
            int2String(math.ceil(valuetable["BRIGHTNESSVAL"] / 2.55))
        streams[keytable["KEY_COLOR_TEMPERATURE"]] =
            int2String(math.ceil(valuetable["COLORTEMPERATURE"] / 2.55))
        streams[keytable["KEY_ARROUND_DIR"]] = int2String(
                                                   valuetable["ARROUNDDIR"])
        streams[keytable["KEY_FAN_SPEED"]] = int2String(valuetable["FANSPEED"])
        streams[keytable["KEY_DELAY_LIGHT_OFF"]] = int2String(
                                                       valuetable["DELAYLIGHTOFF"])
        streams[keytable["KEY_DELAY_FAN_OFF"]] = int2String(
                                                     valuetable["DELAYFANOFF"])
        streams[keytable["KEY_CONST_TEMP_VALUE"]] = int2String(
                                                        valuetable["CONSTTMEPVALUE"])
        if valuetable["TOGGLELEDPOWER"] == 0x01 then
            streams[keytable["KEY_TOGGLE_POWER"]] = "1"
        end
        if valuetable["LEDSCENCELIGHT"] == 0x02 then
            streams[keytable["KEY_LED_SCENE_LIGHT"]] = "work"
        elseif valuetable["LEDSCENCELIGHT"] == 0x03 then
            streams[keytable["KEY_LED_SCENE_LIGHT"]] = "eating"
        elseif valuetable["LEDSCENCELIGHT"] == 0x04 then
            streams[keytable["KEY_LED_SCENE_LIGHT"]] = "night"
        elseif valuetable["LEDSCENCELIGHT"] == 0x05 then
            streams[keytable["KEY_LED_SCENE_LIGHT"]] = "film"
        elseif valuetable["LEDSCENCELIGHT"] == 0x01 then
            streams[keytable["KEY_LED_SCENE_LIGHT"]] = "ledmanual"
        end
        if valuetable["FANSCENEMODE"] == 0x02 then
            streams[keytable["KEY_FAN_SCENE"]] = "breathing_wind"
        elseif valuetable["FANSCENEMODE"] == 0x03 then
            streams[keytable["KEY_FAN_SCENE"]] = "const_temperature"
        elseif valuetable["FANSCENEMODE"] == 0x01 then
            streams[keytable["KEY_FAN_SCENE"]] = "fanmanual"
        end
        if valuetable["LEDPOWER"] == 0x01 then
            streams[keytable["KEY_LED_POWER"]] = "on"
        elseif valuetable["LEDPOWER"] == 0x00 then
            streams[keytable["KEY_LED_POWER"]] = "off"
        end
        if valuetable["FANPOWER"] == 0x01 then
            streams[keytable["KEY_FAN_POWER"]] = "on"
        elseif valuetable["FANPOWER"] == 0x00 then
            streams[keytable["KEY_FAN_POWER"]] = "off"
        end
        if valuetable["ANION_POWER"] == 0x01 then
            streams[keytable["KEY_ANION_POWER"]] = "on"
        else
            streams[keytable["KEY_ANION_POWER"]] = "off"
        end
        if valuetable["DISPLAY_OFF"] == 0x01 then
            streams[keytable["KEY_DISPLAY_OFF"]] = "off"
        else
            streams[keytable["KEY_DISPLAY_OFF"]] = "on"
        end
        streams[keytable["KEY_LED_TIME_ONOFF_1"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_1"])
        streams[keytable["KEY_LED_TIME_ONOFF_1"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_1"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_1"])
        if valuetable["LED_CTRL_ONOFF_1"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_1"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_1"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_1"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_1"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_1"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_1"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_1"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_1"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_1"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_1"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_1"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_1"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_1"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_2"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_2"])
        streams[keytable["KEY_LED_TIME_ONOFF_2"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_2"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_2"])
        if valuetable["LED_CTRL_ONOFF_2"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_2"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_2"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_2"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_2"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_2"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_2"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_2"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_2"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_2"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_2"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_2"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_2"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_2"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_3"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_3"])
        streams[keytable["KEY_LED_TIME_ONOFF_3"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_3"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_3"])
        if valuetable["LED_CTRL_ONOFF_3"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_3"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_3"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_3"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_3"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_3"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_3"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_3"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_3"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_3"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_3"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_3"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_3"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_3"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_4"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_4"])
        streams[keytable["KEY_LED_TIME_ONOFF_4"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_4"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_4"])
        if valuetable["LED_CTRL_ONOFF_4"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_4"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_4"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_4"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_4"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_4"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_4"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_4"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_4"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_4"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_4"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_4"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_4"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_4"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_5"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_5"])
        streams[keytable["KEY_LED_TIME_ONOFF_5"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_5"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_5"])
        if valuetable["LED_CTRL_ONOFF_5"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_5"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_5"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_5"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_5"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_5"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_5"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_5"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_5"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_5"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_5"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_5"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_5"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_5"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_6"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_6"])
        streams[keytable["KEY_LED_TIME_ONOFF_6"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_6"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_6"])
        if valuetable["LED_CTRL_ONOFF_6"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_6"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_6"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_6"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_6"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_6"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_6"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_6"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_6"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_6"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_6"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_6"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_6"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_6"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_7"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_7"])
        streams[keytable["KEY_LED_TIME_ONOFF_7"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_7"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_7"])
        if valuetable["LED_CTRL_ONOFF_7"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_7"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_7"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_7"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_7"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_7"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_7"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_7"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_7"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_7"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_7"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_7"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_7"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_7"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_8"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_8"])
        streams[keytable["KEY_LED_TIME_ONOFF_8"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_8"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_8"])
        if valuetable["LED_CTRL_ONOFF_8"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_8"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_8"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_8"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_8"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_8"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_8"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_8"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_8"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_8"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_8"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_8"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_8"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_8"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_9"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_9"])
        streams[keytable["KEY_LED_TIME_ONOFF_9"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_9"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_9"])
        if valuetable["LED_CTRL_ONOFF_9"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_9"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_9"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_9"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_9"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_9"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_9"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_9"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_9"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_9"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_9"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_9"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_9"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_9"]] = '0'
        end
        streams[keytable["KEY_LED_TIME_ONOFF_10"]] =
            string.format("%02d", valuetable["LED_TIME_OF_HOUR_10"])
        streams[keytable["KEY_LED_TIME_ONOFF_10"]] =
            streams[keytable["KEY_LED_TIME_ONOFF_10"]] ..
                string.format("%02d", valuetable["LED_TIME_OF_MINUTE_10"])
        if valuetable["LED_CTRL_ONOFF_10"] == 0x80 then
            streams[keytable["KEY_LED_CTRL_ONOFF_10"]] = '1'
        else
            streams[keytable["KEY_LED_CTRL_ONOFF_10"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_10"], 0x02)) == 0x02 then
            streams[keytable["KEY_LED_MONDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_LED_MONDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_10"], 0x04)) == 0x04 then
            streams[keytable["KEY_LED_TUESDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_LED_TUESDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_10"], 0x08)) == 0x08 then
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_LED_WEDNESDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_10"], 0x10)) == 0x10 then
            streams[keytable["KEY_LED_THURSDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_LED_THURSDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_10"], 0x20)) == 0x20 then
            streams[keytable["KEY_LED_FRIDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_LED_FRIDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_10"], 0x40)) == 0x40 then
            streams[keytable["KEY_LED_SATURDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_LED_SATURDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["LED_WEEK_EN_DIS_10"], 0x01)) == 0x01 then
            streams[keytable["KEY_LED_SUNDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_LED_SUNDAY_ENDIS_10"]] = '0'
        end
        if valuetable["LED_ENABLE_TIMEING_10"] == 0x80 then
            streams[keytable["KEY_LED_ENABLE_TIMEING_10"]] = '1'
        else
            streams[keytable["KEY_LED_ENABLE_TIMEING_10"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_1"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_1"])
        streams[keytable["KEY_FAN_TIME_ONOFF_1"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_1"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_1"])
        if valuetable["FAN_CTRL_ONOFF_1"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_1"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_1"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_1"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_1"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_1"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_1"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_1"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_1"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_1"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_1"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_1"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_1"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_1"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_1"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_1"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_2"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_2"])
        streams[keytable["KEY_FAN_TIME_ONOFF_2"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_2"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_2"])
        if valuetable["FAN_CTRL_ONOFF_2"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_2"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_2"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_2"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_2"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_2"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_2"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_2"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_2"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_2"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_2"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_2"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_2"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_2"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_2"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_2"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_3"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_3"])
        streams[keytable["KEY_FAN_TIME_ONOFF_3"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_3"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_3"])
        if valuetable["FAN_CTRL_ONOFF_3"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_3"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_3"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_3"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_3"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_3"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_3"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_3"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_3"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_3"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_3"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_3"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_3"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_3"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_3"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_3"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_4"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_4"])
        streams[keytable["KEY_FAN_TIME_ONOFF_4"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_4"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_4"])
        if valuetable["FAN_CTRL_ONOFF_4"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_4"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_4"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_4"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_4"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_4"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_4"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_4"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_4"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_4"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_4"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_4"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_4"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_4"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_4"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_4"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_5"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_5"])
        streams[keytable["KEY_FAN_TIME_ONOFF_5"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_5"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_5"])
        if valuetable["FAN_CTRL_ONOFF_5"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_5"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_5"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_5"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_5"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_5"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_5"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_5"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_5"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_5"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_5"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_5"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_5"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_5"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_5"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_5"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_6"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_6"])
        streams[keytable["KEY_FAN_TIME_ONOFF_6"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_6"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_6"])
        if valuetable["FAN_CTRL_ONOFF_6"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_6"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_6"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_6"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_6"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_6"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_6"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_6"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_6"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_6"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_6"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_6"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_6"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_6"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_6"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_6"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_7"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_7"])
        streams[keytable["KEY_FAN_TIME_ONOFF_7"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_7"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_7"])
        if valuetable["FAN_CTRL_ONOFF_7"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_7"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_7"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_7"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_7"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_7"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_7"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_7"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_7"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_7"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_7"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_7"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_7"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_7"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_7"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_7"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_8"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_8"])
        streams[keytable["KEY_FAN_TIME_ONOFF_8"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_8"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_8"])
        if valuetable["FAN_CTRL_ONOFF_8"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_8"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_8"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_8"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_8"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_8"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_8"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_8"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_8"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_8"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_8"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_8"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_8"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_8"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_8"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_8"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_9"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_9"])
        streams[keytable["KEY_FAN_TIME_ONOFF_9"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_9"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_9"])
        if valuetable["FAN_CTRL_ONOFF_9"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_9"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_9"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_9"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_9"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_9"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_9"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_9"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_9"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_9"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_9"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_9"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_9"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_9"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_9"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_9"]] = '0'
        end
        streams[keytable["KEY_FAN_TIME_ONOFF_10"]] =
            string.format("%02d", valuetable["FAN_TIME_OF_HOUR_10"])
        streams[keytable["KEY_FAN_TIME_ONOFF_10"]] =
            streams[keytable["KEY_FAN_TIME_ONOFF_10"]] ..
                string.format("%02d", valuetable["FAN_TIME_OF_MINUTE_10"])
        if valuetable["FAN_CTRL_ONOFF_10"] == 0x80 then
            streams[keytable["KEY_FAN_CTRL_ONOFF_10"]] = '1'
        else
            streams[keytable["KEY_FAN_CTRL_ONOFF_10"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_10"], 0x02)) == 0x02 then
            streams[keytable["KEY_FAN_MONDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_FAN_MONDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_10"], 0x04)) == 0x04 then
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_FAN_TUESDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_10"], 0x08)) == 0x08 then
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_FAN_WEDNESDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_10"], 0x10)) == 0x10 then
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_FAN_THURSDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_10"], 0x20)) == 0x20 then
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_FAN_FRIDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_10"], 0x40)) == 0x40 then
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_FAN_SATURDAY_ENDIS_10"]] = '0'
        end
        if (bit.band(valuetable["FAN_WEEK_EN_DIS_10"], 0x01)) == 0x01 then
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_10"]] = '1'
        else
            streams[keytable["KEY_FAN_SUNDAY_ENDIS_10"]] = '0'
        end
        if valuetable["FAN_ENABLE_TIMEING_10"] == 0x80 then
            streams[keytable["KEY_FAN_ENABLE_TIMEING_10"]] = '1'
        else
            streams[keytable["KEY_FAN_ENABLE_TIMEING_10"]] = '0'
        end
        if valuetable["anion_enable"] == 0x80 then
            streams[keytable["KEY_EN_ANION"]] = "on"
        else
            streams[keytable["KEY_EN_ANION"]] = "off"
        end
        streams[keytable["KEY_TEMPERATURE_MIN"]] = int2String(
                                                       valuetable["TEMPERATURE_MIN"])
        streams[keytable["KEY_TEMPERATURE_MAX"]] = int2String(
                                                       valuetable["TEMPERATURE_MAX"])
        streams[keytable["KEY_RESULT"]] = "1"
        streams[keytable["KEY_LAMP_TYPE"]] = int2String(lamptype)
    else
        streams[keytable["KEY_RESULT"]] = int2String(valresult)
    end
    return streams
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        if (status) then end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyLength = 5
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        if control[keytable["KEY_TOGGLE_POWER"]] ~= nil then
            bodyBytes[0] = 0x00
            bodyBytes[1] = valuetable["TOGGLELEDPOWER"]
        end
        if control[keytable["KEY_LED_POWER"]] ~= nil then
            bodyBytes[0] = 0x01
            bodyBytes[1] = valuetable["LEDPOWER"]
        elseif control[keytable["KEY_LED_SCENE_LIGHT"]] ~= nil then
            bodyBytes[0] = 0x02
            bodyBytes[1] = valuetable["LEDSCENCELIGHT"]
        elseif control[keytable["KEY_COLOR_TEMPERATURE"]] ~= nil then
            bodyBytes[0] = 0x03
            bodyBytes[1] = math.ceil(valuetable["COLORTEMPERATURE"] * 2.55)
        elseif control[keytable["KEY_BRIGHTNESS"]] ~= nil then
            bodyBytes[0] = 0x04
            bodyBytes[1] = math.ceil(valuetable["BRIGHTNESSVAL"] * 2.55)
        elseif control[keytable["KEY_DELAY_LIGHT_OFF"]] ~= nil then
            bodyBytes[0] = 0x05
            bodyBytes[1] = valuetable["DELAYLIGHTOFF"]
        end
        if control[keytable["KEY_ANION_POWER"]] ~= nil then
            bodyBytes[0] = 0x11
            bodyBytes[1] = valuetable["ANION_POWER"]
        end
        if control[keytable["KEY_DISPLAY_OFF"]] == "off" then
            bodyBytes[0] = 0x12
            bodyBytes[1] = 1
        end
        if control[keytable["KEY_FAN_POWER"]] ~= nil then
            bodyBytes[0] = 0x31
            bodyBytes[1] = valuetable["FANPOWER"]
        elseif control[keytable["KEY_FAN_SCENE"]] ~= nil then
            bodyBytes[0] = 0x32
            bodyBytes[1] = valuetable["FANSCENEMODE"]
            bodyBytes[2] = valuetable["CONSTTMEPVALUE"]
        elseif control[keytable["KEY_ARROUND_DIR"]] ~= nil then
            bodyBytes[0] = 0x33
            bodyBytes[1] = valuetable["ARROUNDDIR"]
        elseif control[keytable["KEY_FAN_SPEED"]] ~= nil then
            bodyBytes[0] = 0x34
            bodyBytes[1] = valuetable["FANSPEED"]
        elseif control[keytable["KEY_DELAY_FAN_OFF"]] ~= nil then
            bodyBytes[0] = 0x35
            bodyBytes[1] = math.ceil(valuetable["DELAYFANOFF"] / 256)
            bodyBytes[2] = math.fmod(valuetable["DELAYFANOFF"] / 256)
        end
        if control[keytable["KEY_LED_TIME_ONOFF_1"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_1"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_1"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_1"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_1"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_1"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_1"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_1"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_1"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_1"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x06
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_1"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_1"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_1"] +
                                                        valuetable["LED_CTRL_ONOFF_1"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_1"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_2"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_2"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_2"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_2"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_2"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_2"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_2"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_2"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_2"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_2"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x07
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_2"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_2"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_2"] +
                                                        valuetable["LED_CTRL_ONOFF_2"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_2"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_3"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_3"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_3"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_3"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_3"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_3"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_3"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_3"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_3"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_3"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x08
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_3"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_3"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_3"] +
                                                        valuetable["LED_CTRL_ONOFF_3"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_3"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_4"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_4"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_4"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_4"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_4"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_4"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_4"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_4"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_4"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_4"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x09
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_4"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_4"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_4"] +
                                                        valuetable["LED_CTRL_ONOFF_4"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_4"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_5"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_5"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_5"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_5"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_5"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_5"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_5"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_5"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_5"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_5"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x0a
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_5"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_5"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_5"] +
                                                        valuetable["LED_CTRL_ONOFF_5"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_5"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_6"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_6"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_6"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_6"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_6"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_6"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_6"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_6"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_6"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_6"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x0b
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_6"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_6"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_6"] +
                                                        valuetable["LED_CTRL_ONOFF_6"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_6"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_7"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_7"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_7"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_7"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_7"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_7"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_7"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_7"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_7"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_7"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x0c
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_7"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_7"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_7"] +
                                                        valuetable["LED_CTRL_ONOFF_7"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_7"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_8"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_8"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_8"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_8"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_8"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_8"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_8"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_8"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_8"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_8"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x0d
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_8"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_8"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_8"] +
                                                        valuetable["LED_CTRL_ONOFF_8"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_8"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_9"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_9"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_9"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_9"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_9"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_9"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_9"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_9"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_9"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_9"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x0e
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_9"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_9"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_9"] +
                                                        valuetable["LED_CTRL_ONOFF_9"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_9"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_LED_TIME_ONOFF_10"]] ~= nil then
            if control[keytable["KEY_LED_CTRL_ONOFF_10"]] ~= nil then
                if control[keytable["KEY_LED_MONDAY_ENDIS_10"]] ~= nil then
                    if control[keytable["KEY_LED_WEDNESDAY_ENDIS_10"]] ~= nil then
                        if control[keytable["KEY_LED_TUESDAY_ENDIS_10"]] ~= nil then
                            if control[keytable["KEY_LED_THURSDAY_ENDIS_10"]] ~=
                                nil then
                                if control[keytable["KEY_LED_FRIDAY_ENDIS_10"]] ~=
                                    nil then
                                    if control[keytable["KEY_LED_SATURDAY_ENDIS_10"]] ~=
                                        nil then
                                        if control[keytable["KEY_LED_SUNDAY_ENDIS_10"]] ~=
                                            nil then
                                            if control[keytable["KEY_LED_ENABLE_TIMEING_10"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x0f
                                                bodyBytes[1] =
                                                    valuetable["LED_TIME_OF_HOUR_10"]
                                                bodyBytes[2] =
                                                    valuetable["LED_TIME_OF_MINUTE_10"]
                                                bodyBytes[3] =
                                                    valuetable["LED_WEEK_EN_DIS_10"] +
                                                        valuetable["LED_CTRL_ONOFF_10"]
                                                bodyBytes[4] =
                                                    valuetable["LED_ENABLE_TIMEING_10"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_1"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_1"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_1"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_1"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_1"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_1"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_1"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_1"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_1"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_1"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x36
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_1"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_1"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_1"] +
                                                        valuetable["FAN_CTRL_ONOFF_1"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_1"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_2"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_2"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_2"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_2"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_2"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_2"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_2"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_2"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_2"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_2"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x37
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_2"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_2"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_2"] +
                                                        valuetable["FAN_CTRL_ONOFF_2"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_2"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_3"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_3"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_3"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_3"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_3"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_3"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_3"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_3"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_3"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_3"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x38
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_3"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_3"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_3"] +
                                                        valuetable["FAN_CTRL_ONOFF_3"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_3"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_4"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_4"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_4"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_4"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_4"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_4"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_4"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_4"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_4"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_4"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x39
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_4"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_4"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_4"] +
                                                        valuetable["FAN_CTRL_ONOFF_4"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_4"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_5"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_5"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_5"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_5"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_5"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_5"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_5"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_5"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_5"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_5"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x3a
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_5"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_5"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_5"] +
                                                        valuetable["FAN_CTRL_ONOFF_5"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_5"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_6"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_6"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_6"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_6"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_6"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_6"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_6"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_6"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_6"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_6"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x3b
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_6"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_6"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_6"] +
                                                        valuetable["FAN_CTRL_ONOFF_6"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_6"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_7"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_7"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_7"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_7"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_7"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_7"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_7"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_7"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_7"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_7"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x3c
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_7"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_7"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_7"] +
                                                        valuetable["FAN_CTRL_ONOFF_7"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_7"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_8"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_8"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_8"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_8"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_8"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_8"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_8"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_8"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_8"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_8"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x3d
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_8"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_8"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_8"] +
                                                        valuetable["FAN_CTRL_ONOFF_8"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_8"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_9"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_9"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_9"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_9"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_9"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_9"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_9"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_9"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_9"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_9"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x3e
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_9"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_9"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_9"] +
                                                        valuetable["FAN_CTRL_ONOFF_9"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_9"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if control[keytable["KEY_FAN_TIME_ONOFF_10"]] ~= nil then
            if control[keytable["KEY_FAN_CTRL_ONOFF_10"]] ~= nil then
                if control[keytable["KEY_FAN_MONDAY_ENDIS_10"]] ~= nil then
                    if control[keytable["KEY_FAN_WEDNESDAY_ENDIS_10"]] ~= nil then
                        if control[keytable["KEY_FAN_TUESDAY_ENDIS_10"]] ~= nil then
                            if control[keytable["KEY_FAN_THURSDAY_ENDIS_10"]] ~=
                                nil then
                                if control[keytable["KEY_FAN_FRIDAY_ENDIS_10"]] ~=
                                    nil then
                                    if control[keytable["KEY_FAN_SATURDAY_ENDIS_10"]] ~=
                                        nil then
                                        if control[keytable["KEY_FAN_SUNDAY_ENDIS_10"]] ~=
                                            nil then
                                            if control[keytable["KEY_FAN_ENABLE_TIMEING_10"]] ~=
                                                nil then
                                                bodyBytes[0] = 0x3f
                                                bodyBytes[1] =
                                                    valuetable["FAN_TIME_OF_HOUR_10"]
                                                bodyBytes[2] =
                                                    valuetable["FAN_TIME_OF_MINUTE_10"]
                                                bodyBytes[3] =
                                                    valuetable["FAN_WEEK_EN_DIS_10"] +
                                                        valuetable["FAN_CTRL_ONOFF_10"]
                                                bodyBytes[4] =
                                                    valuetable["FAN_ENABLE_TIMEING_10"]
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        local bodyLength = 5
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0x24
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
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
    local status = json["status"]
    if (status) then updateGlobalPropertyValueByJson(status) end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10];
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end
