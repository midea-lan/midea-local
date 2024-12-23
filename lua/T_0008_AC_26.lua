local JSON = require "cjson"
local keyT = {}
keyT["KEY_VERSION"] = "version"
keyT["KEY_POWER"] = "power"
keyT["KEY_PURIFIER"] = "purifier"
keyT["KEY_MODE"] = "mode"
keyT["KEY_MODE_REAL"] = "mode_real"
keyT["KEY_TEMPERATURE"] = "temperature"
keyT["KEY_HUMIDITY"] = "humidity"
keyT["KEY_HUMIDITY_NOW"] = "indoor_humidity"
keyT["KEY_FANSPEED"] = "wind_speed"
keyT["KEY_FANSPEED_REAL"] = "wind_speed_real"
keyT["KEY_SWING_LR"] = "wind_swing_lr"
keyT["KEY_SWING_UD"] = "wind_swing_ud"
keyT["KEY_DEFLECTOR_ANGLE_LR"] = "wind_deflector_angle_lr"
keyT["KEY_DEFLECTOR_ANGLE_UD"] = "wind_deflector_angle_ud"
keyT["KEY_TIME_ON"] = "power_on_timer"
keyT["KEY_TIME_OFF"] = "power_off_timer"
keyT["KEY_CLOSE_TIME"] = "power_off_time_value"
keyT["KEY_OPEN_TIME"] = "power_on_time_value"
keyT["KEY_TIME_ON_SPECIFIC"] = "power_on_timer_specific"
keyT["KEY_TIME_OFF_SPECIFIC"] = "power_off_timer_specific"
keyT["KEY_CLOSE_TIME_SPECIFIC"] = "power_off_time_value_specific"
keyT["KEY_OPEN_TIME_SPECIFIC"] = "power_on_time_value_specific"
keyT["KEY_ECO"] = "eco"
keyT["KEY_DRY"] = "dry"
keyT["KEY_ERROR_CODE"] = "error_code"
keyT["KEY_ERROR_QUERY_CODE"] = "error_code_query"
keyT["KEY_BUZZER"] = "buzzer"
keyT["KEY_SCREEN_DISPLAY"] = "screen_display"
keyT["KEY_NO_WIND_SENSE"] = "no_wind_sense"
keyT["KEY_FILTER_RESET"] = "filter_reset"
keyT["KEY_FILTER_FULL"] = "filter_full"
keyT["KEY_COOL_HOT_SENSE"] = "cool_hot_sense"
keyT["KEY_COOL_HOT_SENSE_VALUE"] = "cool_hot_sense_value"
keyT["KEY_COOL_HOT_SENSE_TIME"] = "cool_hot_sense_time"
keyT["KEY_NOBODY_ENERGY_SAVE"] = "nobody_energy_save"
keyT["KEY_NOBODY_ENERGY_SAVE_IN_TIME"] = "nobody_energy_save_in_time"
keyT["KEY_NOBODY_ENERGY_SAVE_OUT_TIME"] = "nobody_energy_save_out_time"
keyT["KEY_NOBODY_ENERGY_SAVE_LOW_TIME"] = "nobody_energy_save_low_time"
keyT["KEY_NOBODY_ENERGY_SAVE_POWER_OFF"] = "nobody_energy_save_power_off"
keyT["KEY_WIND_STRAIGHT"] = "wind_straight"
keyT["KEY_WIND_AVOID"] = "wind_avoid"
keyT["KEY_MODE_QUERY"] = "mode_query"
keyT["KEY_CLEAN_AUTO"] = "clean_auto"
keyT["KEY_CLEAN_MANUAL"] = "clean_manual"
keyT["KEY_HIGH_TEMP_MONITOR"] = "high_temperature_monitor"
keyT["KEY_HIGH_TEMP_MONITOR_STATUS"] = "high_temperature_monitor_status"
keyT["KEY_RATE_SELECT"] = "rate_select"
keyT["KEY_ENERGY_SAVE"] = "energy_save"
keyT["KEY_DEHUMIDIFY"] = "dehumidify"
keyT["KEY_TIMER_DAILY"] = "timer_daily"
keyT["KEY_TIMER_REMOTER"] = "timer_remoter"
keyT["KEY_COMFORT_AIRFLOW"] = "comfort_airflow"
keyT["KEY_FUNCTION_TYPE"] = "function_type"
local keyV = {}
keyV["VALUE_VERSION"] = 25
keyV["VALUE_FUNCTION_ON"] = "on"
keyV["VALUE_FUNCTION_OFF"] = "off"
keyV["VALUE_MODE_HEAT"] = "heat"
keyV["VALUE_MODE_COOL"] = "cool"
keyV["VALUE_MODE_AUTO"] = "auto"
keyV["VALUE_MODE_DRY"] = "dry"
keyV["VALUE_MODE_FAN"] = "fan"
keyV["VALUE_MODE_SMART_DRY"] = "smart_dry"
keyV["VALUE_INDOOR_TEMPERATURE"] = "indoor_temperature"
keyV["VALUE_OUTDOOR_TEMPERATURE"] = "outdoor_temperature"
keyV["VALUE_RUN_STATE"] = "runstate"
keyV["VALUE_RUNNING"] = "running"
keyV["VALUE_STOP"] = "stopped"
local deviceSubType = 0
local deviceSN8 = "00000000"
local keyB = {}
keyB["BYTE_DEVICE_TYPE"] = 0xAC
keyB["BYTE_CONTROL_REQUEST"] = 0x02
keyB["BYTE_QUERYL_REQUEST"] = 0x03
keyB["BYTE_PROTOCOL_HEAD"] = 0xAA
keyB["BYTE_PROTOCOL_LENGTH"] = 0x10
keyB["BYTE_POWER_ON"] = 0x01
keyB["BYTE_POWER_OFF"] = 0x00
keyB["BYTE_COMMON_ON"] = 0x01
keyB["BYTE_COMMON_OFF"] = 0x00
keyB["BYTE_MODE_AUTO"] = 0x01
keyB["BYTE_MODE_COOL"] = 0x02
keyB["BYTE_MODE_DRY"] = 0x03
keyB["BYTE_MODE_HEAT"] = 0x04
keyB["BYTE_MODE_FAN"] = 0x05
keyB["BYTE_MODE_SMART_DRY"] = 0x06
keyB["BYTE_FANSPEED_AUTO"] = 0x00
keyB["BYTE_FANSPEED_HIGH"] = 0x50
keyB["BYTE_FANSPEED_MID"] = 0x3C
keyB["BYTE_FANSPEED_LOW"] = 0x14
keyB["BYTE_FANSPEED_MUTE"] = 0x01
keyB["BYTE_TIMER_METHOD_REL"] = 0x00
keyB["BYTE_TIMER_METHOD_ABS"] = 0x01
keyB["BYTE_TIMER_METHOD_DISABLE"] = 0x7F
keyB["BYTE_CLIENT_MODE_MOBILE"] = 0x02
keyB["BYTE_TIMER_SWITCH_ON"] = 0x80
keyB["BYTE_TIMER_SWITCH_OFF"] = 0x00
keyB["BYTE_STRONG_WIND_ON"] = 0x20
keyB["BYTE_STRONG_WIND_OFF"] = 0x00
keyB["BYTE_SLEEP_ON"] = 0x03
keyB["BYTE_SLEEP_OFF"] = 0x00
keyB["BYTE_COMFORT_POWER_SAVE_ON"] = 0x01
keyB["BYTE_COMFORT_POWER_SAVE_OFF"] = 0x00
keyB["BYTE_CLOSE_TIMER_SWITCH_ON"] = 0x80
keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"] = 0x7F
keyB["BYTE_START_TIMER_SWITCH_ON"] = 0x80
keyB["BYTE_START_TIMER_SWITCH_OFF"] = 0x7F
keyB["BYTE_CONTROL_PROPERTY_CMD"] = 0xB0
keyB["BYTE_QUERY_PROPERTY_CMD"] = 0xB1
local keyP = {}
keyP["powerValue"] = nil
keyP["modeValue"] = nil
keyP["modeRealValue"] = nil
keyP["temperature"] = nil
keyP["smallTemperature"] = nil
keyP["indoorTemperatureValue"] = nil
keyP["outdoorTemperatureValue"] = nil
keyP["fanspeedValue"] = nil
keyP["fanspeedRealValue"] = nil
keyP["closeTimerSwitch"] = nil
keyP["openTimerSwitch"] = nil
keyP["closeTime"] = nil
keyP["openTime"] = nil
keyP["closeTimerSwitchSpecific"] = nil
keyP["openTimerSwitchSpecific"] = nil
keyP["closeTimeSpecific"] = nil
keyP["openTimeSpecific"] = nil
keyP["purifierValue"] = nil
keyP["ecoValue"] = nil
keyP["dryValue"] = nil
keyP["swingLRValue"] = nil
keyP["swingUDValue"] = nil
keyP["windDeflectorAngleLrValue"] = nil
keyP["windDeflectorAngleUdValue"] = nil
keyP["humidityValue"] = nil
keyP["humidityNowValue"] = nil
keyP["screenDisplayValue"] = nil
keyP["noWindSenseValue"] = nil
keyP["coolHot"] = nil
keyP["coolHotValue"] = nil
keyP["coolHotTimeValue"] = nil
keyP["nobodyEnergySaveValue"] = nil
keyP["nobodyEnergySaveInTimeValue"] = nil
keyP["nobodyEnergySaveOutTimeValue"] = nil
keyP["nobodyEnergySaveLowTimeValue"] = nil
keyP["nobodyEnergySavePowerOffValue"] = nil
keyP["windStraightValue"] = nil
keyP["windAvoidValue"] = nil
keyP["filterReset"] = nil
keyP["filterSecondValue"] = nil
keyP["filterMinuteValue"] = nil
keyP["filterHourValue"] = nil
keyP["filterFullValue"] = nil
keyP["modeQueryValue"] = nil
keyP["cleanAutoValue"] = nil
keyP["cleanManualValue"] = nil
keyP["highMonitorValue"] = nil
keyP["highMonitorStatusValue"] = nil
keyP["rateSelectValue"] = nil
keyP["energySaveValue"] = nil
keyP["dehumidifyValue"] = nil
keyP["timerDailyValue"] = nil
keyP["timerRemoteValue"] = nil
keyP["comfortAirflowValue"] = nil
keyP["functionTypeValue"] = nil
keyP["dashHeatingValue"] = nil
keyP["ai_study_control"] = nil
keyP["ai_study"] = nil
keyP["ai_study_temperature"] = nil
keyP["timer_expired"] = nil
keyP["timer_setting"] = nil
keyP["new_no_wind_sense"] = nil
keyP["wind_radar"] = nil
keyP["area"] = nil
keyP["way_out"] = nil
keyP["quick_mode"] = nil
keyP["change_air"] = nil
keyP["air_monitor_status"] = nil
keyP["air_monitor_switch"] = nil
keyP["radar_status"] = nil
keyP["defrost"] = nil
keyP["radar_area_a_1"] = nil
keyP["radar_area_a_2"] = nil
keyP["radar_area_a_3"] = nil
keyP["radar_area_b_1"] = nil
keyP["radar_area_b_2"] = nil
keyP["radar_area_b_3"] = nil
keyP["radar_area_c_1"] = nil
keyP["radar_area_c_2"] = nil
keyP["radar_area_c_3"] = nil
keyP["timer_do_self_clean"] = nil
local buzzerValue = nil
local errorCode = nil
local errorReportCode = {}
local dataType = 0
local propertyNumber = 0
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
local function checkBoundary(data, min, max)
    if (not data) then data = 0 end
    data = tonumber(data)
    if (data == nil) then data = 0 end
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
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
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
local function encode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.encode(cmd)
    return tb
end
local function decode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
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
local function crc16_ccitt(tmpbuf, start_pos, end_pos)
    local crc = 0;
    for si = start_pos, end_pos do
        local i = 0
        crc = bit.bxor(crc, bit.lshift(tmpbuf[si], 8))
        for i = 0, 7 do
            if bit.band(crc, 0x8000) == 0x8000 then
                crc = bit.bxor(bit.lshift(crc, 1), 0x1021);
            else
                crc = bit.lshift(crc, 1)
            end
        end
    end
    return crc;
end
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end
local function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams[keyT["KEY_POWER"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_POWER"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["powerValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_POWER"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["powerValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_BUZZER"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_BUZZER"]] == keyV["VALUE_FUNCTION_ON"]) then
            buzzerValue = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_BUZZER"]] == keyV["VALUE_FUNCTION_OFF"]) then
            buzzerValue = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_PURIFIER"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_PURIFIER"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["purifierValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_PURIFIER"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["purifierValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_ECO"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_ECO"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["ecoValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_ECO"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["ecoValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_DRY"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_DRY"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["dryValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_DRY"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["dryValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_MODE"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_HEAT"]) then
            keyP["modeValue"] = keyB["BYTE_MODE_HEAT"]
        elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_COOL"]) then
            keyP["modeValue"] = keyB["BYTE_MODE_COOL"]
        elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_AUTO"]) then
            keyP["modeValue"] = keyB["BYTE_MODE_AUTO"]
        elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_DRY"]) then
            keyP["modeValue"] = keyB["BYTE_MODE_DRY"]
        elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_FAN"]) then
            keyP["modeValue"] = keyB["BYTE_MODE_FAN"]
        elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_SMART_DRY"]) then
            keyP["modeValue"] = keyB["BYTE_MODE_SMART_DRY"]
        end
    end
    if (streams[keyT["KEY_FANSPEED"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["fanspeedValue"] = checkBoundary(streams[keyT["KEY_FANSPEED"]], 0,
                                              102)
    end
    if (streams[keyT["KEY_FANSPEED_REAL"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["fanspeedRealValue"] = checkBoundary(
                                        streams[keyT["KEY_FANSPEED_REAL"]], 0,
                                        102)
    end
    if (streams[keyT["KEY_SWING_UD"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["swingUDValue"] =
            checkBoundary(streams[keyT["KEY_SWING_UD"]], 0, 3)
    end
    if (streams[keyT["KEY_SWING_LR"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["swingLRValue"] =
            checkBoundary(streams[keyT["KEY_SWING_LR"]], 0, 3)
    end
    if (streams[keyT["KEY_TIME_ON"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["openTimerSwitch"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["openTimerSwitch"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_TIME_OFF"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["closeTimerSwitch"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["closeTimerSwitch"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_CLOSE_TIME"]] ~= nil) then
        keyP["closeTime"] = streams[keyT["KEY_CLOSE_TIME"]]
    end
    if (streams[keyT["KEY_OPEN_TIME"]] ~= nil) then
        keyP["openTime"] = streams[keyT["KEY_OPEN_TIME"]]
    end
    if (streams[keyT["KEY_TIME_ON_SPECIFIC"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_TIME_ON_SPECIFIC"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["openTimerSwitchSpecific"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_TIME_ON_SPECIFIC"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["openTimerSwitchSpecific"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_TIME_OFF_SPECIFIC"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_TIME_OFF_SPECIFIC"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["closeTimerSwitchSpecific"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_TIME_OFF_SPECIFIC"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["closeTimerSwitchSpecific"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_CLOSE_TIME_SPECIFIC"]] ~= nil) then
        keyP["closeTimeSpecific"] = streams[keyT["KEY_CLOSE_TIME_SPECIFIC"]]
    end
    if (streams[keyT["KEY_OPEN_TIME_SPECIFIC"]] ~= nil) then
        keyP["openTimeSpecific"] = streams[keyT["KEY_OPEN_TIME_SPECIFIC"]]
    end
    if (streams[keyT["KEY_TEMPERATURE"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["temperature"] = checkBoundary(streams[keyT["KEY_TEMPERATURE"]],
                                            16, 32)
    end
    if (streams["small_temperature"] ~= nil) then
        keyP["smallTemperature"] = checkBoundary(streams["small_temperature"],
                                                 0, 0.5)
    end
    if (streams[keyT["KEY_FILTER_RESET"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["filterReset"] = checkBoundary(streams[keyT["KEY_FILTER_RESET"]],
                                            0, 1)
    end
    if ((streams[keyT["KEY_DEFLECTOR_ANGLE_LR"]] ~= nil) and
        (streams[keyT["KEY_DEFLECTOR_ANGLE_UD"]] == nil)) then
        propertyNumber = propertyNumber + 1
        keyP["windDeflectorAngleLrValue"] = checkBoundary(
                                                streams[keyT["KEY_DEFLECTOR_ANGLE_LR"]],
                                                0, 100)
    end
    if ((streams[keyT["KEY_DEFLECTOR_ANGLE_UD"]] ~= nil) and
        (streams[keyT["KEY_DEFLECTOR_ANGLE_LR"]] == nil)) then
        propertyNumber = propertyNumber + 1
        keyP["windDeflectorAngleUdValue"] = checkBoundary(
                                                streams[keyT["KEY_DEFLECTOR_ANGLE_UD"]],
                                                0, 100)
    end
    if ((streams[keyT["KEY_DEFLECTOR_ANGLE_LR"]] ~= nil) and
        (streams[keyT["KEY_DEFLECTOR_ANGLE_UD"]] ~= nil)) then
        propertyNumber = propertyNumber + 1
        keyP["windDeflectorAngleLrValue"] = checkBoundary(
                                                streams[keyT["KEY_DEFLECTOR_ANGLE_LR"]],
                                                0, 100)
        keyP["windDeflectorAngleUdValue"] = checkBoundary(
                                                streams[keyT["KEY_DEFLECTOR_ANGLE_UD"]],
                                                0, 100)
    end
    if (streams[keyT["KEY_HUMIDITY"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["humidityValue"] = checkBoundary(streams[keyT["KEY_HUMIDITY"]], 0,
                                              100)
    end
    if (streams[keyT["KEY_SCREEN_DISPLAY"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["screenDisplayValue"] = checkBoundary(
                                         streams[keyT["KEY_SCREEN_DISPLAY"]], 0,
                                         100)
    end
    if (streams[keyT["KEY_NO_WIND_SENSE"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["noWindSenseValue"] = checkBoundary(
                                       streams[keyT["KEY_NO_WIND_SENSE"]], 0, 5)
    end
    if (streams[keyT["KEY_COOL_HOT_SENSE"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_COOL_HOT_SENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["coolHot"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_COOL_HOT_SENSE"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["coolHot"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if ((streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] ~= nil) and
        (streams[keyT["KEY_NOBODY_ENERGY_SAVE_IN_TIME"]] ~= nil) and
        (streams[keyT["KEY_NOBODY_ENERGY_SAVE_OUT_TIME"]] ~= nil) and
        (streams[keyT["KEY_NOBODY_ENERGY_SAVE_LOW_TIME"]] ~= nil) and
        (streams[keyT["KEY_NOBODY_ENERGY_SAVE_POWER_OFF"]] ~= nil)) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["nobodyEnergySaveValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["nobodyEnergySaveValue"] = keyB["BYTE_COMMON_OFF"]
        end
        keyP["nobodyEnergySaveInTimeValue"] =
            streams[keyT["KEY_NOBODY_ENERGY_SAVE_IN_TIME"]]
        keyP["nobodyEnergySaveOutTimeValue"] =
            streams[keyT["KEY_NOBODY_ENERGY_SAVE_OUT_TIME"]]
        keyP["nobodyEnergySaveLowTimeValue"] = checkBoundary(
                                                   streams[keyT["KEY_NOBODY_ENERGY_SAVE_LOW_TIME"]],
                                                   0, 65535)
        keyP["nobodyEnergySavePowerOffValue"] = checkBoundary(
                                                    streams[keyT["KEY_NOBODY_ENERGY_SAVE_POWER_OFF"]],
                                                    0, 1)
    end
    if (streams[keyT["KEY_WIND_STRAIGHT"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_WIND_STRAIGHT"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["windStraightValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_WIND_STRAIGHT"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["windStraightValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_WIND_AVOID"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_WIND_AVOID"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["windAvoidValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_WIND_AVOID"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["windAvoidValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if ((streams[keyT["KEY_CLEAN_AUTO"]] ~= nil) and
        (streams[keyT["KEY_CLEAN_MANUAL"]] ~= nil)) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_CLEAN_AUTO"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["cleanAutoValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_CLEAN_AUTO"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["cleanAutoValue"] = keyB["BYTE_COMMON_OFF"]
        end
        if (streams[keyT["KEY_CLEAN_MANUAL"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["cleanManualValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_CLEAN_MANUAL"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["cleanManualValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_HIGH_TEMP_MONITOR"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_HIGH_TEMP_MONITOR"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["highMonitorValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_HIGH_TEMP_MONITOR"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["highMonitorValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_RATE_SELECT"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["rateSelectValue"] = checkBoundary(
                                      streams[keyT["KEY_RATE_SELECT"]], 1, 100)
    end
    if (streams[keyT["KEY_ENERGY_SAVE"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_ENERGY_SAVE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["energySaveValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_ENERGY_SAVE"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["energySaveValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_DEHUMIDIFY"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["dehumidifyValue"] = checkBoundary(streams[keyT["KEY_DEHUMIDIFY"]],
                                                0, 4)
    end
    if (streams[keyT["KEY_TIMER_DAILY"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_TIMER_DAILY"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["timerDailyValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_TIMER_DAILY"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["timerDailyValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams[keyT["KEY_COMFORT_AIRFLOW"]] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams[keyT["KEY_COMFORT_AIRFLOW"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["comfortAirflowValue"] = keyB["BYTE_COMMON_ON"]
        elseif (streams[keyT["KEY_COMFORT_AIRFLOW"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["comfortAirflowValue"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams["ai_study_control"] ~= nil) then
        propertyNumber = propertyNumber + 1
        if (streams["ai_study_control"] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["ai_study_control"] = keyB["BYTE_COMMON_ON"]
        elseif (streams["ai_study_control"] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["ai_study_control"] = keyB["BYTE_COMMON_OFF"]
        end
    end
    if (streams["ai_study_temperature"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["ai_study_temperature"] = streams["ai_study_temperature"]
    end
    if (streams["timer_expired"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["timer_expired"] = streams["timer_expired"]
    end
    if (streams["timer_setting"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["timer_setting"] = streams["timer_setting"]
    end
    if (streams["new_no_wind_sense"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["new_no_wind_sense"] = streams["new_no_wind_sense"]
    end
    if (streams["wind_radar"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["wind_radar"] = streams["wind_radar"]
    end
    if (streams["way_out"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["way_out"] = streams["way_out"]
    end
    if (streams["area"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["area"] = streams["area"]
    end
    if (streams["quick_mode"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["quick_mode"] = streams["quick_mode"]
    end
    if (streams["change_air"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["change_air"] = streams["change_air"]
    end
    if (streams["timer_do_self_clean"] ~= nil) then
        propertyNumber = propertyNumber + 1
        keyP["timer_do_self_clean"] = streams["timer_do_self_clean"]
    end
end
local function binToModel(binData)
    local messageBytes = binData
    if ((dataType == 0x02 and messageBytes[0] == 0xC0) or
        (dataType == 0x03 and messageBytes[0] == 0xC0) or
        (dataType == 0x05 and messageBytes[0] == 0xD0)) then
        if (#binData < 21) then return nil end
        keyP["functionTypeValue"] = "base"
        keyP["powerValue"] = bit.band(messageBytes[1], 0x01)
        keyP["modeValue"] = bit.rshift(bit.band(messageBytes[2], 0xF0), 4)
        keyP["modeRealValue"] = bit.band(messageBytes[2], 0x0F)
        keyP["temperature"], keyP["smallTemperature"] = math.modf(bit.band(
                                                                      messageBytes[4],
                                                                      0x7F) / 2)
        keyP["fanspeedValue"] = bit.band(messageBytes[3], 0x7F)
        if (bit.band(messageBytes[5], keyB["BYTE_START_TIMER_SWITCH_ON"]) ==
            keyB["BYTE_START_TIMER_SWITCH_ON"]) then
            keyP["openTimerSwitch"] = keyB["BYTE_COMMON_ON"]
        else
            keyP["openTimerSwitch"] = keyB["BYTE_COMMON_OFF"]
        end
        if (bit.band(messageBytes[7], keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) ==
            keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
            keyP["closeTimerSwitch"] = keyB["BYTE_COMMON_ON"]
        else
            keyP["closeTimerSwitch"] = keyB["BYTE_COMMON_OFF"]
        end
        keyP["closeTime"] = bit.band(messageBytes[7], 0x7F) * 60 +
                                messageBytes[8]
        keyP["openTime"] = bit.band(messageBytes[5], 0x7F) * 60 +
                               messageBytes[6]
        keyP["humidityValue"] = messageBytes[9]
        keyP["humidityNowValue"] = messageBytes[10]
        keyP["swingLRValue"] = bit.band(messageBytes[11], 0x0F)
        keyP["swingUDValue"] = bit.rshift(bit.band(messageBytes[11], 0xF0), 4)
        keyP["rateSelectValue"] = messageBytes[12]
        if (dataType == 0x02 or dataType == 0x03 or dataType == 0x05) then
            if (messageBytes[13] ~= 0xFF) then
                keyP["indoorTemperatureValue"] =
                    (messageBytes[13] - 50) / 2 + 0.1 *
                        bit.band(messageBytes[15], 0x0F);
            else
                keyP["indoorTemperatureValue"] = -100
            end
            if (messageBytes[14] ~= 0xFF) then
                keyP["outdoorTemperatureValue"] =
                    (messageBytes[14] - 50) / 2 + 0.1 *
                        bit.rshift(bit.band(messageBytes[15], 0xF0), 4)
            else
                keyP["outdoorTemperatureValue"] = -100
            end
        end
        keyP["ecoValue"] = bit.band(messageBytes[16], 0x01)
        keyP["purifierValue"] = bit.rshift(bit.band(messageBytes[16], 0x02), 1)
        keyP["dryValue"] = bit.rshift(bit.band(messageBytes[16], 0x04), 2)
        keyP["coolHot"] = bit.rshift(bit.band(messageBytes[16], 0x08), 3)
        keyP["cleanManualValue"] = bit.rshift(bit.band(messageBytes[16], 0x10),
                                              4)
        keyP["cleanAutoValue"] = bit.rshift(bit.band(messageBytes[16], 0x20), 5)
        keyP["ai_study_control"] = bit.rshift(bit.band(messageBytes[16], 0x40),
                                              6)
        keyP["highMonitorValue"] = bit.rshift(bit.band(messageBytes[17], 0x10),
                                              4)
        keyP["highMonitorStatusValue"] = bit.band(messageBytes[17], 0x0F)
        keyP["filterFullValue"] =
            bit.rshift(bit.band(messageBytes[17], 0x20), 5)
        keyP["noWindSenseValue"] = bit.band(messageBytes[18], 0x0F)
        keyP["windDeflectorAngleUdValue"] = messageBytes[19]
        keyP["windDeflectorAngleLrValue"] = messageBytes[20]
        keyP["energySaveValue"] = bit.band(messageBytes[21], 0x01)
        keyP["dehumidifyValue"] =
            bit.rshift(bit.band(messageBytes[21], 0x0E), 1)
        keyP["comfortAirflowValue"] = bit.rshift(
                                          bit.band(messageBytes[21], 0x10), 4)
        keyP["dashHeatingValue"] = bit.rshift(bit.band(messageBytes[21], 0x20),
                                              5)
        keyP["timerDailyValue"] =
            bit.rshift(bit.band(messageBytes[21], 0x40), 6)
        keyP["timerRemoteValue"] = bit.rshift(bit.band(messageBytes[21], 0x80),
                                              7)
        if (#binData > 25) then errorCode = messageBytes[23] end
        if (#binData > 26) then
            keyP["quick_mode"] = bit.band(messageBytes[24], 0x01)
            keyP["air_monitor_status"] = bit.rshift(
                                             bit.band(messageBytes[24], 0x06), 1)
            keyP["air_monitor_switch"] = bit.rshift(
                                             bit.band(messageBytes[24], 0x08), 3)
            keyP["new_no_wind_sense"] = bit.rshift(
                                            bit.band(messageBytes[24], 0x30), 4)
            keyP["area"] = bit.rshift(bit.band(messageBytes[24], 0xC0), 6)
            keyP["radar_area_c_3"] = bit.band(messageBytes[25], 0x01)
            keyP["radar_status"] = bit.rshift(bit.band(messageBytes[25], 0x02),
                                              1)
            keyP["wind_radar"] = bit.rshift(bit.band(messageBytes[25], 0x0C), 2)
            keyP["defrost"] = bit.rshift(bit.band(messageBytes[25], 0x10), 4)
            keyP["way_out"] = bit.rshift(bit.band(messageBytes[25], 0x20), 5)
            keyP["radar_area_a_1"] = bit.band(messageBytes[26], 0x01)
            keyP["radar_area_a_2"] = bit.rshift(
                                         bit.band(messageBytes[26], 0x02), 1)
            keyP["radar_area_a_3"] = bit.rshift(
                                         bit.band(messageBytes[26], 0x04), 2)
            keyP["radar_area_b_1"] = bit.rshift(
                                         bit.band(messageBytes[26], 0x08), 3)
            keyP["radar_area_b_2"] = bit.rshift(
                                         bit.band(messageBytes[26], 0x10), 4)
            keyP["radar_area_b_3"] = bit.rshift(
                                         bit.band(messageBytes[26], 0x20), 5)
            keyP["radar_area_c_1"] = bit.rshift(
                                         bit.band(messageBytes[26], 0x40), 6)
            keyP["radar_area_c_2"] = bit.rshift(
                                         bit.band(messageBytes[26], 0x80), 7)
        end
    end
    if ((dataType == 0x04 and messageBytes[0] == 0xA1)) then
        if (#binData > 25) then errorCode = messageBytes[23] end
    end
    if ((dataType == 0x04 and messageBytes[0] == 0xA1)) then
        if (messageBytes[13] ~= 0x00 and messageBytes[13] ~= 0xff) then
            keyP["indoorTemperatureValue"] = (messageBytes[13] - 50) / 2
            smallIndoorTemperatureValue = bit.band(messageBytes[18], 0xF);
        end
        if (messageBytes[14] ~= 0x00 and messageBytes[14] ~= 0xff) then
            keyP["outdoorTemperatureValue"] = (messageBytes[14] - 50) / 2
            smallOutdoorTemperatureValue = bit.rshift(messageBytes[18], 4);
        end
    end
    if ((dataType == 0x02 and messageBytes[0] == 0xB0)) then
        if (#binData < 8) then return nil end
        propertyNumber = messageBytes[1]
        local cursor = 2
        for i = 1, propertyNumber do
            if (messageBytes[cursor + 0] == 0x01 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["powerValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x02 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["modeValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x03 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["temperature"], keyP["smallTemperature"] = math.modf(
                                                                    messageBytes[cursor +
                                                                        4] / 2)
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x04 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["indoorTemperatureValue"] =
                    messageBytes[cursor + 4] + 0.1 * messageBytes[cursor + 5]
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x05 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["outdoorTemperatureValue"] =
                    messageBytes[cursor + 4] + 0.1 * messageBytes[cursor + 5]
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x06 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["fanspeedValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x07 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["fanspeedRealValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x08 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["swingUDValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x09 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["swingLRValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x0A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["windDeflectorAngleUdValue"] = messageBytes[cursor + 4]
                keyP["windDeflectorAngleLrValue"] = messageBytes[cursor + 5]
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x0B and messageBytes[cursor + 1] ==
                0x00) then
                keyP["openTimerSwitch"] = messageBytes[cursor + 4]
                keyP["openTime"] = messageBytes[cursor + 5] * 60 +
                                       messageBytes[cursor + 6]
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x0C and messageBytes[cursor + 1] ==
                0x00) then
                keyP["closeTimerSwitch"] = messageBytes[cursor + 4]
                keyP["closeTime"] = messageBytes[cursor + 5] * 60 +
                                        messageBytes[cursor + 6]
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x53 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["openTimerSwitchSpecific"] = messageBytes[cursor + 4]
                keyP["openTimeSpecific"] =
                    messageBytes[cursor + 5] * 60 + messageBytes[cursor + 6]
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x54 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["closeTimerSwitchSpecific"] = messageBytes[cursor + 4]
                keyP["closeTimeSpecific"] =
                    messageBytes[cursor + 5] * 60 + messageBytes[cursor + 6]
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x0D and messageBytes[cursor + 1] ==
                0x00) then
                keyP["ecoValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x0E and messageBytes[cursor + 1] ==
                0x00) then
                keyP["purifierValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x10 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["dryValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x14 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["humidityValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x15 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["humidityNowValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x17 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["screenDisplayValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x18 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["noWindSenseValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x1A and messageBytes[cursor + 1] ==
                0x00) then
                buzzerValue = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x21 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["coolHot"] = messageBytes[cursor + 4]
                cursor = cursor + 12
            end
            if (messageBytes[cursor + 0] == 0x30 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["nobodyEnergySaveValue"] = messageBytes[cursor + 4]
                keyP["nobodyEnergySaveInTimeValue"] = messageBytes[cursor + 5]
                keyP["nobodyEnergySaveLowTimeValue"] =
                    messageBytes[cursor + 7] * 100 + messageBytes[cursor + 6]
                keyP["nobodyEnergySavePowerOffValue"] = messageBytes[cursor + 8]
                keyP["nobodyEnergySaveOutTimeValue"] = messageBytes[cursor + 9]
                cursor = cursor + 10
            end
            if (messageBytes[cursor + 0] == 0x32 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["windStraightValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x33 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["windAvoidValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x3D and messageBytes[cursor + 1] ==
                0x00) then
                keyP["filterReset"] = 0
                keyP["filterSecondValue"] = messageBytes[cursor + 4]
                keyP["filterMinuteValue"] = messageBytes[cursor + 5]
                keyP["filterHourValue"] =
                    messageBytes[cursor + 7] * 100 + messageBytes[cursor + 6]
                keyP["filterFullValue"] = messageBytes[cursor + 8]
                cursor = cursor + 9
            end
            if (messageBytes[cursor + 0] == 0x3F and messageBytes[cursor + 1] ==
                0x00) then
                local errorNum = 0
                errorNum = messageBytes[cursor + 4]
                if (errorNum > 0) then
                    for i = 0, errorNum do
                        errorReportCode[i] = 0
                    end
                    for i = 0, errorNum do
                        errorReportCode[i] = messageBytes[cursor + 4 + i]
                    end
                    cursor = cursor + 5 + errorNum
                else
                    cursor = cursor + 5
                end
            end
            if (messageBytes[cursor + 0] == 0x41 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["modeQueryValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x46 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["cleanAutoValue"] = messageBytes[cursor + 4]
                if (messageBytes[cursor + 4] == 0xFF) then
                    keyP["cleanAutoValue"] = 0
                end
                keyP["cleanManualValue"] = messageBytes[cursor + 5]
                if (messageBytes[cursor + 5] == 0xFF) then
                    keyP["cleanManualValue"] = 0
                end
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x47 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["highMonitorValue"] = messageBytes[cursor + 4]
                keyP["highMonitorStatusValue"] = messageBytes[cursor + 5]
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x48 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["rateSelectValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x50 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["energySaveValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x51 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["dehumidifyValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x52 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["timerDailyValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x55 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["comfortAirflowValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x22 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["ai_study_control"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x23 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["ai_study_temperature"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x60 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["timer_expired"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x61 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["timer_setting"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x70 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["new_no_wind_sense"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x71 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_radar"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x72 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["area"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x73 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["way_out"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x74 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["quick_mode"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x75 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["change_air"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
        end
    end
    if ((dataType == 0x05 and messageBytes[0] == 0xB5)) then
        if (#binData < 8) then return nil end
        propertyNumber = messageBytes[1]
        keyP["functionTypeValue"] = "notify"
        local cursor = 2
        for i = 1, propertyNumber do
            if (messageBytes[cursor + 0] == 0x01 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["powerValue"] = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x02 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["modeValue"] = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x03 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["temperature"], keyP["smallTemperature"] = math.modf(
                                                                    messageBytes[cursor +
                                                                        3] / 2)
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x3F and messageBytes[cursor + 1] ==
                0x00) then
                errorCode = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x47 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["highMonitorValue"] = messageBytes[cursor + 3]
                keyP["highMonitorStatusValue"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x70 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["new_no_wind_sense"] = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x71 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_radar"] = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x72 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["area"] = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x73 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["way_out"] = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x74 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["quick_mode"] = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x75 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["change_air"] = messageBytes[cursor + 3]
                cursor = cursor + 4
            end
        end
    end
end
local function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData + 1
    local msgLength = bodyLength + keyB["BYTE_PROTOCOL_LENGTH"] + 2
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = 0x55
    msgBytes[1] = 0xAA
    msgBytes[2] = 0xCC
    msgBytes[3] = 0x33
    local msgLen = msgLength - 4
    msgBytes[4] = bit.band(msgLen, 0xff)
    msgBytes[5] = bit.band(bit.rshift(msgLen, 8), 0xff)
    msgBytes[6] = 0x01
    msgBytes[7] = 0xAC
    msgBytes[14] = bit.band(cType, 0xff)
    msgBytes[15] = bit.band(bit.rshift(cType, 8), 0xff)
    for i = 0, bodyLength - 1 do
        msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]] = bodyData[i]
    end
    local crc16 = crc16_ccitt(msgBytes, 0, msgLength - 3)
    msgBytes[msgLength - 2] = bit.band(crc16, 0xff)
    msgBytes[msgLength - 1] = bit.band(bit.rshift(crc16, 8), 0xff)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
end
function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local infoM = {}
    local bodyBytes = {}
    local json = decode(jsonCmd)
    deviceSubType = json["deviceinfo"]["deviceSubType"]
    local deviceSN = json["deviceinfo"]["deviceSN"]
    if deviceSN ~= nil then deviceSN8 = string.sub(deviceSN, 13, 17) end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (query) then
        local queryType = nil
        if (type(query) == "table") then queryType = query["query_type"] end
        if (queryType == nil) then
            for i = 0, 21 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0x41
            bodyBytes[1] = 0x81
            bodyBytes[3] = 0xFF
            math.randomseed(os.time())
            math.random()
            bodyBytes[20] = math.random(1, 254)
            bodyBytes[21] = crc8_854(bodyBytes, 0, 20)
            infoM = getTotalMsg(bodyBytes, keyB["BYTE_QUERYL_REQUEST"])
        else
            bodyBytes[0] = 0xB1
            local propertyNum = 0
            if (queryType == "power") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x01
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "purifier") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x0E
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "mode") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x02
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "temperature") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x03
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "buzzer") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x1A
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "wind_speed") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x06
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "wind_speed_real") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x07
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "wind_swing_lr") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x09
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "wind_deflector") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x0A
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "wind_swing_ud") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x08
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "power_on_timer") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x0B
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "power_off_timer") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x0C
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "power_on_timer_specific") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x53
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "power_off_timer_specific") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x54
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "indoor_temperature") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x04
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "outdoor_temperature") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x05
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "eco") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x0D
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "humidity") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x14
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "indoor_humidity") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x15
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "screen_display") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x17
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "no_wind_sense") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x18
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "dry") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x10
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "filter") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x3D
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "cool_hot_sense") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x21
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "nobody_energy_save") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x30
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "wind_straight") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x32
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "wind_avoid") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x33
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "error_code_query") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x3F
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "mode_query") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x41
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "clean") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x46
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "high_temperature_monitor") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x47
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "rate_select") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x48
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "ai_study_control") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x22
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "ai_study_temperature") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x23
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "timer_expired") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x60
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "timer_setting") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x61
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "timer_setting") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x61
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "new_no_wind_sense") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x70
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "wind_radar") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x71
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "area") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x72
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "way_out") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x73
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "quick_mode") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x74
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            if (queryType == "change_air") then
                bodyBytes[1 + propertyNum * 2 + 1] = 0x75
                bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                propertyNum = propertyNum + 1
            end
            bodyBytes[1] = propertyNum
            math.randomseed(os.time())
            math.random()
            bodyBytes[1 + propertyNum * 2 + 1] = math.random(1, 254)
            bodyBytes[1 + propertyNum * 2 + 2] =
                crc8_854(bodyBytes, 0, 1 + propertyNum * 2 + 1)
            infoM = getTotalMsg(bodyBytes, keyB["BYTE_QUERYL_REQUEST"])
        end
    elseif (control) then
        if (control) then jsonToModel(control) end
        if (propertyNumber == 0) then
            return
        else
            bodyBytes[0] = keyB["BYTE_CONTROL_PROPERTY_CMD"]
            bodyBytes[1] = propertyNumber
            local cursor = 2
            if (keyP["timer_expired"] ~= nil) then
                bodyBytes[cursor + 0] = 0x60
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["timer_expired"]
                cursor = cursor + 4
            end
            if (keyP["timer_setting"] ~= nil) then
                bodyBytes[cursor + 0] = 0x61
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["timer_setting"]
                cursor = cursor + 4
            end
            if (keyP["powerValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x01
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["powerValue"]
                cursor = cursor + 4
            end
            if (keyP["modeValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x02
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["modeValue"]
                cursor = cursor + 4
            end
            if (keyP["temperature"] ~= nil) then
                bodyBytes[cursor + 0] = 0x03
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["temperature"] * 2
                if (keyP["smallTemperature"] ~= nil) then
                    bodyBytes[cursor + 3] =
                        (keyP["temperature"] + keyP["smallTemperature"]) * 2
                end
                cursor = cursor + 4
            end
            if (keyP["indoorTemperatureValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x04
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["indoorTemperatureValue"]
                cursor = cursor + 4
            end
            if (keyP["outdoorTemperatureValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x05
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["outdoorTemperatureValue"]
                cursor = cursor + 4
            end
            if (keyP["fanspeedValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x06
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["fanspeedValue"]
                cursor = cursor + 4
            end
            if (keyP["fanspeedRealValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x07
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["fanspeedRealValue"]
                cursor = cursor + 4
            end
            if (keyP["closeTimerSwitch"] ~= nil) then
                bodyBytes[cursor + 0] = 0x0C
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["closeTimerSwitch"]
                if (math.ceil(keyP["closeTime"] / 60) == keyP["closeTime"] / 60) then
                    bodyBytes[cursor + 4] = math.ceil(keyP["closeTime"] / 60)
                else
                    bodyBytes[cursor + 4] =
                        math.ceil(keyP["closeTime"] / 60) - 1
                end
                bodyBytes[cursor + 5] = keyP["closeTime"] % 60
                cursor = cursor + 6
            end
            if (keyP["openTimerSwitch"] ~= nil) then
                bodyBytes[cursor + 0] = 0x0B
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["openTimerSwitch"]
                if (math.ceil(keyP["openTime"] / 60) == keyP["openTime"] / 60) then
                    bodyBytes[cursor + 4] = math.ceil(keyP["openTime"] / 60)
                else
                    bodyBytes[cursor + 4] = math.ceil(keyP["openTime"] / 60) - 1
                end
                bodyBytes[cursor + 5] = keyP["openTime"] % 60
                cursor = cursor + 6
            end
            if (keyP["closeTimerSwitchSpecific"] ~= nil) then
                bodyBytes[cursor + 0] = 0x54
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["closeTimerSwitchSpecific"]
                if (math.ceil(keyP["closeTimeSpecific"] / 60) ==
                    keyP["closeTimeSpecific"] / 60) then
                    bodyBytes[cursor + 4] = math.ceil(
                                                keyP["closeTimeSpecific"] / 60)
                else
                    bodyBytes[cursor + 4] = math.ceil(
                                                keyP["closeTimeSpecific"] / 60) -
                                                1
                end
                bodyBytes[cursor + 5] = keyP["closeTimeSpecific"] % 60
                cursor = cursor + 6
            end
            if (keyP["openTimerSwitchSpecific"] ~= nil) then
                bodyBytes[cursor + 0] = 0x53
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["openTimerSwitchSpecific"]
                if (math.ceil(keyP["openTimeSpecific"] / 60) ==
                    keyP["openTimeSpecific"] / 60) then
                    bodyBytes[cursor + 4] = math.ceil(
                                                keyP["openTimeSpecific"] / 60)
                else
                    bodyBytes[cursor + 4] = math.ceil(
                                                keyP["openTimeSpecific"] / 60) -
                                                1
                end
                bodyBytes[cursor + 5] = keyP["openTimeSpecific"] % 60
                cursor = cursor + 6
            end
            if (keyP["purifierValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x0E
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["purifierValue"]
                cursor = cursor + 4
            end
            if (keyP["ecoValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x0D
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["ecoValue"]
                cursor = cursor + 4
            end
            if (keyP["dryValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x10
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["dryValue"]
                cursor = cursor + 4
            end
            if (keyP["swingLRValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x09
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["swingLRValue"]
                cursor = cursor + 4
            end
            if (keyP["swingUDValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x08
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["swingUDValue"]
                cursor = cursor + 4
            end
            if ((keyP["windDeflectorAngleUdValue"] ~= nil) or
                (keyP["windDeflectorAngleLrValue"]) ~= nil) then
                bodyBytes[cursor + 0] = 0x0A
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = 0xFF
                bodyBytes[cursor + 4] = 0xFF
                if (keyP["windDeflectorAngleUdValue"] ~= nil) then
                    bodyBytes[cursor + 3] = keyP["windDeflectorAngleUdValue"]
                end
                if (keyP["windDeflectorAngleLrValue"] ~= nil) then
                    bodyBytes[cursor + 4] = keyP["windDeflectorAngleLrValue"]
                end
                cursor = cursor + 5
            end
            if (keyP["humidityValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x14
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["humidityValue"]
                cursor = cursor + 4
            end
            if (keyP["humidityNowValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x15
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["humidityNowValue"]
                cursor = cursor + 4
            end
            if (keyP["screenDisplayValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x17
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["screenDisplayValue"]
                cursor = cursor + 4
            end
            if (keyP["noWindSenseValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x18
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["noWindSenseValue"]
                cursor = cursor + 4
            end
            if (buzzerValue ~= nil) then
                bodyBytes[cursor + 0] = 0x1A
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = buzzerValue
                cursor = cursor + 4
            end
            if (keyP["coolHot"] ~= nil) then
                bodyBytes[cursor + 0] = 0x21
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x08
                bodyBytes[cursor + 3] = keyP["coolHot"]
                bodyBytes[cursor + 4] = 0x00
                bodyBytes[cursor + 5] = 0x00
                bodyBytes[cursor + 6] = 0x00
                bodyBytes[cursor + 7] = 0x00
                bodyBytes[cursor + 8] = 0x00
                bodyBytes[cursor + 9] = 0x00
                bodyBytes[cursor + 10] = 0x00
                cursor = cursor + 11
            end
            if (keyP["nobodyEnergySaveValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x30
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x06
                bodyBytes[cursor + 3] = keyP["nobodyEnergySaveValue"]
                bodyBytes[cursor + 4] = keyP["nobodyEnergySaveInTimeValue"]
                bodyBytes[cursor + 5] = keyP["nobodyEnergySaveLowTimeValue"] %
                                            100
                bodyBytes[cursor + 6] = keyP["nobodyEnergySaveLowTimeValue"] /
                                            100
                bodyBytes[cursor + 7] = keyP["nobodyEnergySavePowerOffValue"]
                bodyBytes[cursor + 8] = keyP["nobodyEnergySaveOutTimeValue"]
                cursor = cursor + 9
            end
            if (keyP["windStraightValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x32
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["windStraightValue"]
                cursor = cursor + 4
            end
            if (keyP["windAvoidValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x33
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["windAvoidValue"]
                cursor = cursor + 4
            end
            if (keyP["filterReset"] ~= nil) then
                bodyBytes[cursor + 0] = 0x3D
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x05
                bodyBytes[cursor + 3] = 0x00
                bodyBytes[cursor + 4] = 0x00
                bodyBytes[cursor + 5] = 0x00
                bodyBytes[cursor + 6] = 0x00
                bodyBytes[cursor + 7] = 0x00
                cursor = cursor + 8
            end
            if (keyP["cleanAutoValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x46
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = keyP["cleanManualValue"]
                bodyBytes[cursor + 4] = keyP["cleanAutoValue"]
                cursor = cursor + 5
            end
            if (keyP["highMonitorValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x47
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = keyP["highMonitorValue"]
                bodyBytes[cursor + 4] = 0x00
                cursor = cursor + 5
            end
            if (keyP["rateSelectValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x48
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["rateSelectValue"]
                cursor = cursor + 4
            end
            if (keyP["energySaveValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x50
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["energySaveValue"]
                cursor = cursor + 4
            end
            if (keyP["dehumidifyValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x51
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["dehumidifyValue"]
                cursor = cursor + 4
            end
            if (keyP["timerDailyValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x52
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["timerDailyValue"]
                cursor = cursor + 4
            end
            if (keyP["comfortAirflowValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x55
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["comfortAirflowValue"]
                cursor = cursor + 4
            end
            if (keyP["ai_study_control"] ~= nil) then
                bodyBytes[cursor + 0] = 0x22
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["ai_study_control"]
                cursor = cursor + 4
            end
            if (keyP["ai_study_temperature"] ~= nil) then
                bodyBytes[cursor + 0] = 0x23
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["ai_study_temperature"]
                cursor = cursor + 4
            end
            if (keyP["new_no_wind_sense"] ~= nil) then
                bodyBytes[cursor + 0] = 0x70
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["new_no_wind_sense"]
                cursor = cursor + 4
            end
            if (keyP["wind_radar"] ~= nil) then
                bodyBytes[cursor + 0] = 0x71
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["wind_radar"]
                cursor = cursor + 4
            end
            if (keyP["area"] ~= nil) then
                bodyBytes[cursor + 0] = 0x72
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["area"]
                cursor = cursor + 4
            end
            if (keyP["way_out"] ~= nil) then
                bodyBytes[cursor + 0] = 0x73
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["way_out"]
                cursor = cursor + 4
            end
            if (keyP["quick_mode"] ~= nil) then
                bodyBytes[cursor + 0] = 0x74
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["quick_mode"]
                cursor = cursor + 4
            end
            if (keyP["change_air"] ~= nil) then
                bodyBytes[cursor + 0] = 0x75
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["change_air"]
                cursor = cursor + 4
            end
            if (keyP["timer_do_self_clean"] ~= nil) then
                bodyBytes[cursor + 0] = 0x77
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["timer_do_self_clean"]
                cursor = cursor + 4
            end
            math.randomseed(os.time())
            math.random()
            bodyBytes[cursor] = math.random(1, 254)
            bodyBytes[cursor + 1] = crc8_854(bodyBytes, 0, cursor)
        end
        infoM = getTotalMsg(bodyBytes, keyB["BYTE_CONTROL_REQUEST"])
    end
    propertyNumber = 0
    keyP["powerValue"] = nil
    keyP["modeValue"] = nil
    keyP["temperature"] = nil
    keyP["smallTemperature"] = nil
    keyP["indoorTemperatureValue"] = nil
    keyP["outdoorTemperatureValue"] = nil
    keyP["fanspeedValue"] = nil
    keyP["fanspeedRealValue"] = nil
    keyP["closeTimerSwitch"] = nil
    keyP["openTimerSwitch"] = nil
    keyP["closeTime"] = nil
    keyP["openTime"] = nil
    keyP["purifierValue"] = nil
    keyP["ecoValue"] = nil
    keyP["dryValue"] = nil
    keyP["swingLRValue"] = nil
    keyP["swingUDValue"] = nil
    keyP["windDeflectorAngleUdValue"] = nil
    keyP["windDeflectorAngleLrValue"] = nil
    keyP["humidityValue"] = nil
    keyP["humidityNowValue"] = nil
    keyP["screenDisplayValue"] = nil
    keyP["noWindSenseValue"] = nil
    keyP["coolHot"] = nil
    keyP["coolHotValue"] = nil
    keyP["coolHotTimeValue"] = nil
    keyP["nobodyEnergySaveValue"] = nil
    keyP["nobodyEnergySaveInTimeValue"] = nil
    keyP["nobodyEnergySaveOutTimeValue"] = nil
    keyP["nobodyEnergySaveLowTimeValue"] = nil
    keyP["nobodyEnergySavePowerOffValue"] = nil
    keyP["windStraightValue"] = nil
    keyP["windAvoidValue"] = nil
    keyP["filterReset"] = nil
    keyP["filterSecondValue"] = nil
    keyP["filterMinuteValue"] = nil
    keyP["filterHourValue"] = nil
    keyP["filterFullValue"] = nil
    errorCode = nil
    errorReportCode = {}
    keyP["modeQueryValue"] = nil
    keyP["cleanAutoValue"] = nil
    keyP["cleanManualValue"] = nil
    keyP["highMonitorValue"] = nil
    keyP["highMonitorStatusValue"] = nil
    keyP["rateSelectValue"] = nil
    keyP["energySaveValue"] = nil
    keyP["dehumidifyValue"] = nil
    keyP["timerDailyValue"] = nil
    keyP["timerRemoteValue"] = nil
    keyP["dashHeatingValue"] = nil
    keyP["comfortAirflowValue"] = nil
    keyP["closeTimerSwitchSpecific"] = nil
    keyP["openTimerSwitchSpecific"] = nil
    keyP["closeTimeSpecific"] = nil
    keyP["openTimeSpecific"] = nil
    keyP["ai_study_control"] = nil
    keyP["ai_study"] = nil
    keyP["ai_study_temperature"] = nil
    keyP["timer_expired"] = nil
    keyP["timer_setting"] = nil
    keyP["new_no_wind_sense"] = nil
    keyP["wind_radar"] = nil
    keyP["area"] = nil
    keyP["way_out"] = nil
    keyP["quick_mode"] = nil
    keyP["change_air"] = nil
    buzzerValue = nil
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonCmd)
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceinfo = json["deviceinfo"]
    deviceSubType = deviceinfo["deviceSubType"]
    local deviceSN = json["deviceinfo"]["deviceSN"]
    if deviceSN ~= nil then deviceSN8 = string.sub(deviceSN, 13, 17) end
    local status = json["status"]
    if (status) then jsonToModel(status) end
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[15];
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - keyB["BYTE_PROTOCOL_LENGTH"] - 2
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]]
    end
    binToModel(bodyBytes)
    local streams = {}
    streams[keyT["KEY_VERSION"]] = keyV["VALUE_VERSION"]
    if (keyP["powerValue"] ~= nil) then
        if (keyP["powerValue"] == keyB["BYTE_POWER_ON"]) then
            streams[keyT["KEY_POWER"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["powerValue"] == keyB["BYTE_POWER_OFF"]) then
            streams[keyT["KEY_POWER"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["modeValue"] ~= nil) then
        if (keyP["modeValue"] == keyB["BYTE_MODE_HEAT"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_HEAT"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_COOL"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_COOL"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_AUTO"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_AUTO"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_DRY"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_DRY"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_FAN"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_FAN"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_SMART_DRY"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_SMART_DRY"]
        end
    end
    if (keyP["modeRealValue"] ~= nil) then
        if (keyP["modeRealValue"] == keyB["BYTE_MODE_HEAT"]) then
            streams[keyT["KEY_MODE_REAL"]] = keyV["VALUE_MODE_HEAT"]
        elseif (keyP["modeRealValue"] == keyB["BYTE_MODE_COOL"]) then
            streams[keyT["KEY_MODE_REAL"]] = keyV["VALUE_MODE_COOL"]
        elseif (keyP["modeRealValue"] == keyB["BYTE_MODE_AUTO"]) then
            streams[keyT["KEY_MODE_REAL"]] = keyV["VALUE_MODE_AUTO"]
        elseif (keyP["modeRealValue"] == keyB["BYTE_MODE_DRY"]) then
            streams[keyT["KEY_MODE_REAL"]] = keyV["VALUE_MODE_DRY"]
        elseif (keyP["modeRealValue"] == keyB["BYTE_MODE_FAN"]) then
            streams[keyT["KEY_MODE_REAL"]] = keyV["VALUE_MODE_FAN"]
        elseif (keyP["modeRealValue"] == keyB["BYTE_MODE_SMART_DRY"]) then
            streams[keyT["KEY_MODE_REAL"]] = keyV["VALUE_MODE_SMART_DRY"]
        end
    end
    if (keyP["purifierValue"] ~= nil) then
        if (keyP["purifierValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_PURIFIER"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["purifierValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_PURIFIER"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["ecoValue"] ~= nil) then
        if (keyP["ecoValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_ECO"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["ecoValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_ECO"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["dryValue"] ~= nil) then
        if (keyP["dryValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_DRY"]] = keyV["VALUE_FUNCTION_ON"]
        else
            streams[keyT["KEY_DRY"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["fanspeedValue"] ~= nil) then
        streams[keyT["KEY_FANSPEED"]] = keyP["fanspeedValue"]
    end
    if (keyP["outdoorTemperatureValue"] ~= nil) then
        streams[keyV["VALUE_OUTDOOR_TEMPERATURE"]] =
            keyP["outdoorTemperatureValue"]
    end
    if (keyP["indoorTemperatureValue"] ~= nil) then
        streams[keyV["VALUE_INDOOR_TEMPERATURE"]] =
            keyP["indoorTemperatureValue"]
    end
    if (keyP["swingUDValue"] ~= nil) then
        streams[keyT["KEY_SWING_UD"]] = keyP["swingUDValue"]
    end
    if (keyP["swingLRValue"] ~= nil) then
        streams[keyT["KEY_SWING_LR"]] = keyP["swingLRValue"]
    end
    if (keyP["openTimerSwitch"] ~= nil) then
        if (keyP["openTimerSwitch"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_TIME_ON"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["openTimerSwitch"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_TIME_ON"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["closeTimerSwitch"] ~= nil) then
        if (keyP["closeTimerSwitch"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_TIME_OFF"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["closeTimerSwitch"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_TIME_OFF"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if ((keyP["closeTimerSwitch"] ~= nil) and (keyP["closeTime"] ~= nil)) then
        if (keyP["closeTimerSwitch"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_CLOSE_TIME"]] = 0
        else
            streams[keyT["KEY_CLOSE_TIME"]] = keyP["closeTime"]
        end
    end
    if ((keyP["openTimerSwitch"] ~= nil) and (keyP["openTime"] ~= nil)) then
        if (keyP["openTimerSwitch"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_OPEN_TIME"]] = 0
        else
            streams[keyT["KEY_OPEN_TIME"]] = keyP["openTime"]
        end
    end
    if (keyP["openTimerSwitchSpecific"] ~= nil) then
        if (keyP["openTimerSwitchSpecific"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_TIME_ON_SPECIFIC"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["openTimerSwitchSpecific"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_TIME_ON_SPECIFIC"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["closeTimerSwitchSpecific"] ~= nil) then
        if (keyP["closeTimerSwitchSpecific"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_TIME_OFF_SPECIFIC"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["closeTimerSwitchSpecific"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_TIME_OFF_SPECIFIC"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if ((keyP["closeTimerSwitchSpecific"] ~= nil) and
        (keyP["closeTimeSpecific"] ~= nil)) then
        if (keyP["closeTimerSwitchSpecific"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_CLOSE_TIME_SPECIFIC"]] = 0
        else
            streams[keyT["KEY_CLOSE_TIME_SPECIFIC"]] = keyP["closeTimeSpecific"]
        end
    end
    if ((keyP["openTimerSwitchSpecific"] ~= nil) and
        (keyP["openTimeSpecific"] ~= nil)) then
        if (keyP["openTimerSwitchSpecific"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_OPEN_TIME_SPECIFIC"]] = 0
        else
            streams[keyT["KEY_OPEN_TIME_SPECIFIC"]] = keyP["openTimeSpecific"]
        end
    end
    if (keyP["temperature"] ~= nil) then
        streams[keyT["KEY_TEMPERATURE"]] = keyP["temperature"]
    end
    if (keyP["smallTemperature"] ~= nil) then
        streams["small_temperature"] = keyP["smallTemperature"]
    end
    if (keyP["humidityValue"] ~= nil) then
        streams[keyT["KEY_HUMIDITY"]] = keyP["humidityValue"]
    end
    if (keyP["humidityNowValue"] ~= nil) then
        streams[keyT["KEY_HUMIDITY_NOW"]] = keyP["humidityNowValue"]
    end
    if (errorCode ~= nil) then streams[keyT["KEY_ERROR_CODE"]] = errorCode end
    if (#errorReportCode >= 1) then
        streams[keyT["KEY_ERROR_QUERY_CODE"]] = errorReportCode
    end
    if (keyP["windDeflectorAngleUdValue"] ~= nil) then
        streams[keyT["KEY_DEFLECTOR_ANGLE_UD"]] =
            keyP["windDeflectorAngleUdValue"]
    end
    if (keyP["windDeflectorAngleLrValue"] ~= nil) then
        streams[keyT["KEY_DEFLECTOR_ANGLE_LR"]] =
            keyP["windDeflectorAngleLrValue"]
    end
    if (keyP["screenDisplayValue"] ~= nil) then
        streams[keyT["KEY_SCREEN_DISPLAY"]] = keyP["screenDisplayValue"]
    end
    if (keyP["noWindSenseValue"] ~= nil) then
        streams[keyT["KEY_NO_WIND_SENSE"]] = keyP["noWindSenseValue"]
    end
    if (keyP["coolHot"] ~= nil) then
        if (keyP["coolHot"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_COOL_HOT_SENSE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["coolHot"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_COOL_HOT_SENSE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if ((keyP["nobodyEnergySaveValue"] ~= nil) and
        (keyP["nobodyEnergySaveInTimeValue"] ~= nil) and
        (keyP["nobodyEnergySaveOutTimeValue"] ~= nil) and
        (keyP["nobodyEnergySaveLowTimeValue"] ~= nil) and
        (keyP["nobodyEnergySavePowerOffValue"] ~= nil)) then
        if (keyP["nobodyEnergySaveValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["nobodyEnergySaveValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        streams[keyT["KEY_NOBODY_ENERGY_SAVE_IN_TIME"]] =
            keyP["nobodyEnergySaveInTimeValue"]
        streams[keyT["KEY_NOBODY_ENERGY_SAVE_OUT_TIME"]] =
            keyP["nobodyEnergySaveOutTimeValue"]
        streams[keyT["KEY_NOBODY_ENERGY_SAVE_LOW_TIME"]] =
            keyP["nobodyEnergySaveLowTimeValue"]
        streams[keyT["KEY_NOBODY_ENERGY_SAVE_POWER_OFF"]] =
            keyP["nobodyEnergySavePowerOffValue"]
    end
    if (keyP["windStraightValue"] ~= nil) then
        if (keyP["windStraightValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WIND_STRAIGHT"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["windStraightValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WIND_STRAIGHT"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["windAvoidValue"] ~= nil) then
        if (keyP["windAvoidValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WIND_AVOID"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["windAvoidValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WIND_AVOID"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["modeQueryValue"] ~= nil) then
        streams[keyT["KEY_MODE_QUERY"]] = keyP["modeQueryValue"]
    end
    if ((keyP["cleanAutoValue"] ~= nil) and (keyP["cleanManualValue"] ~= nil)) then
        if (keyP["cleanAutoValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_CLEAN_AUTO"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["cleanAutoValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_CLEAN_AUTO"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["cleanManualValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_CLEAN_MANUAL"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["cleanManualValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_CLEAN_MANUAL"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["highMonitorValue"] ~= nil) then
        if (keyP["highMonitorValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_HIGH_TEMP_MONITOR"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["highMonitorValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_HIGH_TEMP_MONITOR"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["highMonitorStatusValue"] ~= nil) then
        streams[keyT["KEY_HIGH_TEMP_MONITOR_STATUS"]] =
            keyP["highMonitorStatusValue"]
    end
    if (keyP["rateSelectValue"] ~= nil) then
        streams[keyT["KEY_RATE_SELECT"]] = keyP["rateSelectValue"]
    end
    if (keyP["filterFullValue"] ~= nil) then
        streams[keyT["KEY_FILTER_FULL"]] = keyP["filterFullValue"]
    end
    if (keyP["energySaveValue"] ~= nil) then
        if (keyP["energySaveValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_ENERGY_SAVE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["energySaveValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_ENERGY_SAVE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["dehumidifyValue"] ~= nil) then
        streams[keyT["KEY_DEHUMIDIFY"]] = keyP["dehumidifyValue"]
    end
    if (keyP["timerDailyValue"] ~= nil) then
        if (keyP["timerDailyValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_TIMER_DAILY"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["timerDailyValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_TIMER_DAILY"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["timerRemoteValue"] ~= nil) then
        if (keyP["timerRemoteValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_TIMER_REMOTER"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["timerRemoteValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_TIMER_REMOTER"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["comfortAirflowValue"] ~= nil) then
        if (keyP["comfortAirflowValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_COMFORT_AIRFLOW"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["comfortAirflowValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_COMFORT_AIRFLOW"]] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["dashHeatingValue"] ~= nil) then
        if (keyP["dashHeatingValue"] == keyB["BYTE_COMMON_ON"]) then
            streams["dash_heating"] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["dashHeatingValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams["dash_heating"] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["functionTypeValue"] ~= nil) then
        streams[keyT["KEY_FUNCTION_TYPE"]] = keyP["functionTypeValue"]
    end
    if (keyP["ai_study_control"] ~= nil) then
        if (keyP["ai_study_control"] == keyB["BYTE_COMMON_ON"]) then
            streams["ai_study_control"] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["ai_study_control"] == keyB["BYTE_COMMON_OFF"]) then
            streams["ai_study_control"] = keyV["VALUE_FUNCTION_OFF"]
        end
    end
    if (keyP["ai_study_temperature"] ~= nil) then
        streams["ai_study_temperature"] = keyP["ai_study_temperature"]
    end
    if (keyP["timer_expired"] ~= nil) then
        streams["timer_expired"] = keyP["timer_expired"]
    end
    if (keyP["timer_setting"] ~= nil) then
        streams["timer_setting"] = keyP["timer_setting"]
    end
    if (keyP["ai_study"] ~= nil) then streams["ai_study"] = keyP["ai_study"] end
    if (keyP["new_no_wind_sense"] ~= nil) then
        streams["new_no_wind_sense"] = keyP["new_no_wind_sense"]
    end
    if (keyP["wind_radar"] ~= nil) then
        streams["wind_radar"] = keyP["wind_radar"]
    end
    if (keyP["area"] ~= nil) then streams["area"] = keyP["area"] end
    if (keyP["way_out"] ~= nil) then streams["way_out"] = keyP["way_out"] end
    if (keyP["quick_mode"] ~= nil) then
        streams["quick_mode"] = keyP["quick_mode"]
    end
    if (keyP["change_air"] ~= nil) then
        streams["change_air"] = keyP["change_air"]
    end
    if (keyP["air_monitor_status"] ~= nil) then
        streams["air_monitor_status"] = keyP["air_monitor_status"]
    end
    if (keyP["air_monitor_switch"] ~= nil) then
        streams["air_monitor_switch"] = keyP["air_monitor_switch"]
    end
    if (keyP["radar_status"] ~= nil) then
        streams["radar_status"] = keyP["radar_status"]
    end
    if (keyP["defrost"] ~= nil) then streams["defrost"] = keyP["defrost"] end
    if (keyP["radar_area_a_1"] ~= nil) then
        streams["radar_area_a_1"] = keyP["radar_area_a_1"]
    end
    if (keyP["radar_area_a_2"] ~= nil) then
        streams["radar_area_a_2"] = keyP["radar_area_a_2"]
    end
    if (keyP["radar_area_a_3"] ~= nil) then
        streams["radar_area_a_3"] = keyP["radar_area_a_3"]
    end
    if (keyP["radar_area_b_1"] ~= nil) then
        streams["radar_area_b_1"] = keyP["radar_area_b_1"]
    end
    if (keyP["radar_area_b_2"] ~= nil) then
        streams["radar_area_b_2"] = keyP["radar_area_b_2"]
    end
    if (keyP["radar_area_b_3"] ~= nil) then
        streams["radar_area_b_3"] = keyP["radar_area_b_3"]
    end
    if (keyP["radar_area_c_1"] ~= nil) then
        streams["radar_area_c_1"] = keyP["radar_area_c_1"]
    end
    if (keyP["radar_area_c_2"] ~= nil) then
        streams["radar_area_c_2"] = keyP["radar_area_c_2"]
    end
    if (keyP["radar_area_c_3"] ~= nil) then
        streams["radar_area_c_3"] = keyP["radar_area_c_3"]
    end
    propertyNumber = 0
    keyP["powerValue"] = nil
    keyP["modeValue"] = nil
    keyP["temperature"] = nil
    keyP["smallTemperature"] = nil
    keyP["indoorTemperatureValue"] = nil
    keyP["outdoorTemperatureValue"] = nil
    keyP["fanspeedValue"] = nil
    keyP["fanspeedRealValue"] = nil
    keyP["closeTimerSwitch"] = nil
    keyP["openTimerSwitch"] = nil
    keyP["closeTime"] = nil
    keyP["openTime"] = nil
    keyP["purifierValue"] = nil
    keyP["ecoValue"] = nil
    keyP["dryValue"] = nil
    keyP["swingLRValue"] = nil
    keyP["swingUDValue"] = nil
    keyP["windDeflectorAngleUdValue"] = nil
    keyP["windDeflectorAngleLrValue"] = nil
    keyP["humidityValue"] = nil
    keyP["humidityNowValue"] = nil
    keyP["screenDisplayValue"] = nil
    keyP["noWindSenseValue"] = nil
    keyP["coolHot"] = nil
    keyP["coolHotValue"] = nil
    keyP["coolHotTimeValue"] = nil
    keyP["nobodyEnergySaveValue"] = nil
    keyP["nobodyEnergySaveInTimeValue"] = nil
    keyP["nobodyEnergySaveOutTimeValue"] = nil
    keyP["nobodyEnergySaveLowTimeValue"] = nil
    keyP["nobodyEnergySavePowerOffValue"] = nil
    keyP["windStraightValue"] = nil
    keyP["windAvoidValue"] = nil
    keyP["filterReset"] = nil
    keyP["filterSecondValue"] = nil
    keyP["filterMinuteValue"] = nil
    keyP["filterHourValue"] = nil
    keyP["filterFullValue"] = nil
    errorCode = nil
    errorReportCode = {}
    keyP["modeQueryValue"] = nil
    keyP["cleanAutoValue"] = nil
    keyP["cleanManualValue"] = nil
    keyP["highMonitorValue"] = nil
    keyP["highMonitorStatusValue"] = nil
    keyP["rateSelectValue"] = nil
    keyP["energySaveValue"] = nil
    keyP["dehumidifyValue"] = nil
    keyP["timerDailyValue"] = nil
    keyP["timerRemoteValue"] = nil
    keyP["comfortAirflowValue"] = nil
    keyP["dashHeatingValue"] = nil
    keyP["closeTimerSwitchSpecific"] = nil
    keyP["openTimerSwitchSpecific"] = nil
    keyP["closeTimeSpecific"] = nil
    keyP["openTimeSpecific"] = nil
    keyP["ai_study_control"] = nil
    keyP["ai_study"] = nil
    keyP["ai_study_temperature"] = nil
    keyP["timer_expired"] = nil
    keyP["timer_setting"] = nil
    keyP["new_no_wind_sense"] = nil
    keyP["wind_radar"] = nil
    keyP["area"] = nil
    keyP["way_out"] = nil
    keyP["quick_mode"] = nil
    keyP["change_air"] = nil
    keyP["air_monitor_status"] = nil
    keyP["air_monitor_switch"] = nil
    keyP["radar_status"] = nil
    keyP["defrost"] = nil
    keyP["radar_area_a_1"] = nil
    keyP["radar_area_a_2"] = nil
    keyP["radar_area_a_3"] = nil
    keyP["radar_area_b_1"] = nil
    keyP["radar_area_b_2"] = nil
    keyP["radar_area_b_3"] = nil
    keyP["radar_area_c_1"] = nil
    keyP["radar_area_c_2"] = nil
    keyP["radar_area_c_3"] = nil
    buzzerValue = nil
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
