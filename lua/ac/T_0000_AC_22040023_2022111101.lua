local bit = require "bit"
local JSON = require "cjson"
local keyT = {}
keyT["KEY_VERSION"] = "version"
keyT["KEY_POWER"] = "power"
keyT["KEY_PURIFIER"] = "purifier"
keyT["KEY_MODE"] = "mode"
keyT["KEY_SMART_DRY"] = "smart_dry_value"
keyT["KEY_TEMPERATURE"] = "temperature"
keyT["KEY_FANSPEED"] = "wind_speed"
keyT["KEY_SWING_LR"] = "wind_swing_lr"
keyT["KEY_SWING_UD"] = "wind_swing_ud"
keyT["KEY_SWING_LR_UNDER"] = "wind_swing_lr_under"
keyT["KEY_TIME_ON"] = "power_on_timer"
keyT["KEY_TIME_OFF"] = "power_off_timer"
keyT["KEY_CLOSE_TIME"] = "power_off_time_value"
keyT["KEY_OPEN_TIME"] = "power_on_time_value"
keyT["KEY_ECO"] = "eco"
keyT["KEY_DRY"] = "dry"
keyT["KEY_PTC"] = "ptc"
keyT["KEY_CURRENT_WORK_TIME"] = "current_work_time"
keyT["KEY_ERROR_CODE"] = "error_code"
keyT["KEY_BUZZER"] = "buzzer"
keyT["KEY_PREVENT_SUPER_COOL"] = "prevent_super_cool"
keyT["KEY_PREVENT_COLD"] = "prevent_cold"
keyT["KEY_PREVENT_STRAIGHT_WIND"] = "prevent_straight_wind"
keyT["KEY_AUTO_PREVENT_STRAIGHT_WIND"] = "auto_prevent_straight_wind"
keyT["KEY_SELF_CLEAN"] = "self_clean"
keyT["KEY_WIND_STRAIGHT"] = "wind_straight"
keyT["KEY_WIND_AVOID"] = "wind_avoid"
keyT["KEY_INTELLIGENT_WIND"] = "intelligent_wind"
keyT["KEY_NO_WIND_SENSE"] = "no_wind_sense"
keyT["KEY_FN_NO_WIND_SENSE"] = "fn_no_wind_sense"
keyT["KEY_CHILD_PREVENT_COLD_WIND"] = "child_prevent_cold_wind"
keyT["KEY_STRONG_WIND"] = "strong_wind"
keyT["KEY_COMFORT_POWER_SAVE"] = "comfort_power_save"
keyT["KEY_SCREEN_DISPLAY"] = "screen_display"
keyT["KEY_SCREEN_DISPLAY_NOW"] = "screen_display_now"
keyT["KEY_LITTLE_ANGLE"] = "little_angel"
keyT["KEY_COOL_HOT_SENSE"] = "cool_hot_sense"
keyT["KEY_GENTLE_WIND_SENSE"] = "gentle_wind_sense"
keyT["KEY_SECURITY"] = "security"
keyT["KEY_EVEN_WIND"] = "even_wind"
keyT["KEY_SINGLE_TUYERE"] = "single_tuyere"
keyT["KEY_EXTREME_WIND"] = "extreme_wind"
keyT["KEY_VOICE_CONTROL"] = "voice_control"
keyT["KEY_COMFORT_SLEEP"] = "comfort_sleep"
keyT["KEY_COMFORT_SLEEP_CURVE"] = "comfort_sleep_curve"
keyT["KEY_PRE_COOL_HOT"] = "pre_cool_hot"
keyT["KEY_NATURAL_WIND"] = "natural_wind"
keyT["KEY_PMV"] = "pmv"
keyT["KEY_WATER_WASHING"] = "water_washing"
keyT["KEY_FRESH_AIR"] = "fresh_air"
keyT["KEY_YB_WIND_AVOID"] = "yb_wind_avoid"
keyT["KEY_FA_PREVENT_STRAIGHT_WIND"] = "fa_prevent_straight_wind"
keyT["KEY_PARENT_CONTROL"] = "parent_control"
keyT["KEY_NOBODY_ENERGY_SAVE"] = "nobody_energy_save"
keyT["KEY_WIND_SWING_UD_ANGLE"] = "wind_swing_ud_angle"
keyT["KEY_WIND_SWING_LR_ANGLE"] = "wind_swing_lr_angle"
keyT["KEY_FILTER_VALUE"] = "filter_value"
keyT["KEY_FILTER_LEVEL"] = "filter_level"
keyT["KEY_PREVENT_STRAIGHT_WIND_LR"] = "prevent_straight_wind_lr"
keyT["KEY_PM25_VALUE"] = "pm25_value"
keyT["KEY_WATER_PUMP"] = "water_pump"
keyT["KEY_INTENLLIGENT_CONTROL"] = "intelligent_control"
keyT["KEY_VOLUME_CONTROL"] = "volume_control"
keyT["KEY_VOICE_CONTROL_NEW"] = "voice_control_new"
keyT["KEY_FACE_REGISTER"] = "face_register"
keyT["KEY_COOL_TEMP_UP"] = "cool_temp_up"
keyT["KEY_COOL_TEMP_DOWN"] = "cool_temp_down"
keyT["KEY_AUTO_TEMP_UP"] = "auto_temp_up"
keyT["KEY_AUTO_TEMP_DOWN"] = "auto_temp_down"
keyT["KEY_HEAT_TEMP_UP"] = "heat_temp_up"
keyT["KEY_HEAT_TEMP_DOWN"] = "heat_temp_down"
keyT["KEY_POWER_SAVING"] = "power_saving"
keyT["KEY_POWER_LOCK"] = "power_lock"
keyT["KEY_PTC_LOCK"] = "ptc_lock"
keyT["KEY_OFFLINE_OPERATING_TIME"] = "offline_operating_time"
keyT["KEY_REMOTE_CONTROL_LOCK"] = "remote_control_lock"
keyT["KEY_OPERATING_TIME"] = "operating_time"
keyT["KEY_FRESH_FILTER_TIME_TOTAL"] = "fresh_filter_time_total"
keyT["KEY_FRESH_FILTER_TIME_USE"] = "fresh_filter_time_use"
keyT["KEY_FRESH_FILTER_TIMEOUT"] = "fresh_filter_timeout"
keyT["KEY_FRESH_FILTER_RESET"] = "fresh_filter_reset"
keyT["KEY_INDOOR_HUMIDITY"] = "indoor_humidity"
keyT["KEY_DEGERMING"] = "degerming"
keyT["KEY_WIND_AROUND"] = "wind_around"
keyT["KEY_WIND_TOP"] = "wind_top"
keyT["KEY_CHILD_LOCK"] = "child_lock"
keyT["KEY_PTC_DEFAULT_RULE"] = "ptc_default_rule"
local keyV = {}
keyV["VALUE_VERSION"] = 98
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
keyB["BYTE_PROTOCOL_LENGTH"] = 0x0A
keyB["BYTE_POWER_ON"] = 0x01
keyB["BYTE_POWER_OFF"] = 0x00
keyB["BYTE_MODE_AUTO"] = 0x20
keyB["BYTE_MODE_COOL"] = 0x40
keyB["BYTE_MODE_DRY"] = 0x60
keyB["BYTE_MODE_HEAT"] = 0x80
keyB["BYTE_MODE_FAN"] = 0xA0
keyB["BYTE_MODE_SMART_DRY"] = 0xC0
keyB["BYTE_FANSPEED_AUTO"] = 0x66
keyB["BYTE_FANSPEED_HIGH"] = 0x50
keyB["BYTE_FANSPEED_MID"] = 0x3C
keyB["BYTE_FANSPEED_LOW"] = 0x28
keyB["BYTE_FANSPEED_MUTE"] = 0x14
keyB["BYTE_PURIFIER_ON"] = 0x20
keyB["BYTE_PURIFIER_OFF"] = 0x00
keyB["BYTE_ECO_ON"] = 0x80
keyB["BYTE_ECO_OFF"] = 0x00
keyB["BYTE_SWING_LR_ON"] = 0x03
keyB["BYTE_SWING_LR_OFF"] = 0x00
keyB["BYTE_SWING_LR_UNDER_ON"] = 0x80
keyB["BYTE_SWING_LR_UNDER_OFF"] = 0x00
keyB["BYTE_SWING_LR_UNDER_ENABLE"] = 0x80
keyB["BYTE_SWING_LR_UNDER_DISABLE"] = 0x00
keyB["BYTE_SWING_UD_ON"] = 0x0C
keyB["BYTE_SWING_UD_OFF"] = 0x00
keyB["BYTE_DRY_ON"] = 0x04
keyB["BYTE_DRY_OFF"] = 0x00
keyB["BYTE_BUZZER_ON"] = 0x40
keyB["BYTE_BUZZER_OFF"] = 0x00
keyB["BYTE_CONTROL_CMD"] = 0x40
keyB["BYTE_TIMER_METHOD_REL"] = 0x00
keyB["BYTE_TIMER_METHOD_ABS"] = 0x01
keyB["BYTE_TIMER_METHOD_DISABLE"] = 0x7F
keyB["BYTE_CLIENT_MODE_MOBILE"] = 0x02
keyB["BYTE_TIMER_SWITCH_ON"] = 0x80
keyB["BYTE_TIMER_SWITCH_OFF"] = 0x00
keyB["BYTE_CLOSE_TIMER_SWITCH_ON"] = 0x80
keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"] = 0x7F
keyB["BYTE_START_TIMER_SWITCH_ON"] = 0x80
keyB["BYTE_START_TIMER_SWITCH_OFF"] = 0x7F
keyB["BYTE_PTC_ON"] = 0x08
keyB["BYTE_PTC_OFF"] = 0x00
keyB["BYTE_STRONG_WIND_ON"] = 0x20
keyB["BYTE_STRONG_WIND_OFF"] = 0x00
keyB["BYTE_SLEEP_ON"] = 0x03
keyB["BYTE_SLEEP_OFF"] = 0x00
keyB["BYTE_COMFORT_POWER_SAVE_ON"] = 0x01
keyB["BYTE_COMFORT_POWER_SAVE_OFF"] = 0x00
keyB["BYTE_EVEN_WIND_ON"] = 0x01
keyB["BYTE_EVEN_WIND_OFF"] = 0x00
keyB["BYTE_SINGLE_TUYERE_ON"] = 0x01
keyB["BYTE_SINGLE_TUYERE_OFF"] = 0x00
keyB["BYTE_EXTREME_WIND_ON"] = 0x01
keyB["BYTE_EXTREME_WIND_OFF"] = 0x00
keyB["BYTE_VOICE_CONTROL_ON"] = 0x03
keyB["BYTE_VOICE_CONTROL_OFF"] = 0x00
keyB["BYTE_NATURAL_WIND_ON"] = 0x40
keyB["BYTE_NATURAL_WIND_OFF"] = 0x00
keyB["BYTE_CONTROL_PROPERTY_CMD"] = 0xB0
local keyP = {}
local dataType = 0
local comfortByte = nil
local function init_keyP()
    keyP["is_query"] = nil
    keyP["timerSignal"] = 0
    keyP["powerValue"] = nil
    keyP["modeValue"] = nil
    keyP["smartDryValue"] = nil
    keyP["temperature"] = nil
    keyP["smallTemperature"] = nil
    keyP["indoorTemperatureValue"] = nil
    keyP["smallIndoorTemperatureValue"] = nil
    keyP["outdoorTemperatureValue"] = nil
    keyP["smallOutdoorTemperatureValue"] = nil
    keyP["fanspeedValue"] = nil
    keyP["closeTimerSwitch"] = nil
    keyP["openTimerSwitch"] = nil
    keyP["closeHour"] = nil
    keyP["closeStepMintues"] = nil
    keyP["closeMin"] = nil
    keyP["closeTime"] = nil
    keyP["openHour"] = nil
    keyP["openStepMintues"] = nil
    keyP["openMin"] = nil
    keyP["openTime"] = nil
    keyP["strongWindValue"] = nil
    keyP["comfortableSleepValue"] = nil
    keyP["comfortableSleepSwitch"] = nil
    keyP["comfortableSleepTime"] = nil
    keyP["comfort_sleep_curve"] = nil
    keyP["PTCValue"] = nil
    keyP["purifierValue"] = nil
    keyP["ecoValue"] = nil
    keyP["dryValue"] = nil
    keyP["swingLRValue"] = nil
    keyP["swingUDValue"] = nil
    keyP["swingLRValueUnder"] = nil
    keyP["swingLRUnderSwitch"] = 0
    keyP["currentWorkTime"] = nil
    keyP["PTCForceValue"] = 0
    keyP["screenDisplayNowValue"] = nil
    keyP["buzzerValue"] = 0x40
    keyP["errorCode"] = 0
    keyP["kickQuilt"] = nil
    keyP["preventCold"] = nil
    keyP["comfortPowerSave"] = nil
    keyP["naturalWind"] = nil
    keyP["pmv"] = nil
    keyP["fresh_filter_time_total"] = nil
    keyP["fresh_filter_time_use"] = nil
    keyP["fresh_filter_timeout"] = nil
    keyP["fresh_filter_reset"] = nil
    keyP["propertyNumber"] = 0
    keyP["prevent_super_cool"] = nil
    keyP["prevent_straight_wind"] = nil
    keyP["auto_prevent_straight_wind"] = nil
    keyP["self_clean"] = nil
    keyP["wind_straight"] = nil
    keyP["wind_avoid"] = nil
    keyP["yb_wind_avoid"] = nil
    keyP["intelligent_wind"] = nil
    keyP["no_wind_sense"] = nil
    keyP["child_prevent_cold_wind"] = nil
    keyP["little_angel"] = nil
    keyP["cool_hot_sense"] = nil
    keyP["gentle_wind_sense"] = nil
    keyP["security"] = nil
    keyP["even_wind"] = nil
    keyP["single_tuyere"] = nil
    keyP["extreme_wind"] = nil
    keyP["extreme_wind_level"] = nil
    keyP["voice_control"] = nil
    keyP["pre_cool_hot"] = nil
    keyP["water_washing"] = nil
    keyP["fresh_air"] = nil
    keyP["no_wind_sense_level"] = nil
    keyP["fn_no_wind_sense"] = nil
    keyP["fa_prevent_straight_wind"] = nil
    keyP["parent_control"] = nil
    keyP["parent_control_temp_up"] = nil
    keyP["parent_control_temp_down"] = nil
    keyP["nobody_energy_save"] = nil
    keyP["filter_value"] = nil
    keyP["filter_level"] = nil
    keyP["prevent_straight_wind_lr"] = nil
    keyP["pm25_value"] = nil
    keyP["water_pump"] = nil
    keyP["intelligent_control"] = nil
    keyP["wind_swing_ud_angle"] = nil
    keyP["wind_swing_lr_angle"] = nil
    keyP["volume_control"] = nil
    keyP["voice_control_new"] = nil
    keyP["face_register"] = nil
    keyP["cool_temp_up"] = nil
    keyP["cool_temp_down"] = nil
    keyP["auto_temp_up"] = nil
    keyP["auto_temp_down"] = nil
    keyP["heat_temp_up"] = nil
    keyP["heat_temp_down"] = nil
    keyP["power_saving"] = nil
    keyP["remote_control_lock"] = nil
    keyP["remote_control_lock_control"] = nil
    keyP["indoor_humidity"] = nil
    keyP["degerming"] = nil
    keyP["wind_around"] = nil
    keyP["wind_around_ud"] = nil
    keyP["wind_top"] = nil
    keyP["light"] = nil
    keyP["child_lock"] = nil
    keyP["electrify_time_day"] = nil
    keyP["electrify_time_hour"] = nil
    keyP["electrify_time_min"] = nil
    keyP["electrify_time_second"] = nil
    keyP["total_operating_time_day"] = nil
    keyP["total_operating_time_hour"] = nil
    keyP["total_operating_time_min"] = nil
    keyP["total_operating_time_second"] = nil
    keyP["current_operating_time_day"] = nil
    keyP["current_operating_time_hour"] = nil
    keyP["current_operating_time_min"] = nil
    keyP["current_operating_time_second"] = nil
    keyP["total_power_consumption"] = nil
    keyP["total_operating_consumption"] = nil
    keyP["current_operating_consumption"] = nil
    keyP["current_time_power"] = nil
    keyP["analysis_value"] = nil
    keyP["filter_replace_time"] = nil
    keyP["dust_full_time"] = nil
    keyP["buzzer_all"] = nil
    keyP["self_remove_odor_phase"] = nil
    keyP["has_self_remove_odor_phase"] = nil
    keyP["high_temp_remove_odor_alone"] = nil
    keyP["has_high_temp_remove_odor_alone"] = nil
    keyP["power_lock"] = nil
    keyP["ptc_lock"] = nil
    keyP["offline_operating_time"] = nil
    keyP["ozone"] = nil
    keyP["fault_tag"] = nil
    keyP["soft_warm"] = nil
    keyP["fresh_air_parm"] = nil
    keyP["rewarming_dry"] = nil
    keyP["arom"] = nil
    keyP["arom_old"] = nil
    keyP["arom_fan_speed"] = nil
    keyP["arom_time_clean"] = nil
    keyP["arom_time"] = nil
    keyP["arom_time_total"] = nil
    keyP["new_mode_power"] = nil
    keyP["new_mode"] = nil
    keyP["new_temperature"] = nil
    keyP["new_wind_speed"] = nil
    keyP["uvc_remove_odor"] = nil
    keyP["uvc_power_off"] = nil
    keyP["main_horizontal_guide_strip_1"] = nil
    keyP["main_horizontal_guide_strip_2"] = nil
    keyP["main_horizontal_guide_strip_3"] = nil
    keyP["main_horizontal_guide_strip_4"] = nil
    keyP["has_guide_strip"] = nil
    keyP["has_no_wind_sense"] = nil
    keyP["has_arom"] = nil
    keyP["light_sensitive"] = nil
    keyP["t2_temp"] = nil
    keyP["wind_swing_lr_left"] = nil
    keyP["wind_swing_lr_right"] = nil
    keyP["wind_swing_ud_left"] = nil
    keyP["wind_swing_ud_right"] = nil
    keyP["ptc_default_rule"] = nil
    keyP["wind_swing_ud_angle_up"] = nil
    keyP["wind_swing_ud_angle_down"] = nil
    keyP["app_control_remember_ud"] = nil
    keyP["wind_swing_ud_angle_switch"] = nil
    keyP["wind_swing_lr_angle_up"] = nil
    keyP["wind_swing_lr_angle_down"] = nil
    keyP["app_control_remember_lr"] = nil
    keyP["wind_swing_lr_angle_switch"] = nil
    keyP["auto_prevent_cold_wind"] = nil
    keyP["has_wind_swing_ud_angle_diy"] = nil
    keyP["has_wind_swing_lr_angle_diy"] = nil
    keyP["prepare_food"] = nil
    keyP["prepare_food_temp"] = nil
    keyP["prepare_food_fan_speed"] = nil
    keyP["quick_fry"] = nil
    keyP["quick_fry_temp"] = nil
    keyP["quick_fry_fan_speed"] = nil
    keyP["cool_power_saving"] = nil
    keyP["jet_cool"] = nil
    keyP["light_sensitive"] = nil
    keyP["has_light_sensitive"] = nil
    keyP["ptc_default_rule"] = nil
    keyP["has_ptc_default_rule"] = nil
    keyP["ilinkId"] = nil
    keyP["ticket"] = nil
end
init_keyP()
local propertyPre = nil
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
local function table2string2(cmd)
    local ret = ""
    local i
    for i = 0, #cmd - 1 do ret = ret .. string.char(cmd[i]) end
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
local function numstring2table(hexstr)
    local tb = {}
    local i = 1
    local j = 1
    for i = 1, #hexstr - 1, 2 do
        local doublebytestr = string.sub(hexstr, i, i + 1)
        tb[j] = doublebytestr
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
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    resVal = bit.band(255 - resVal + 1, 0xff)
    return resVal
end
local function splitStrByChar(str, sepChar)
    local splitList = {}
    local pattern = '[^' .. sepChar .. ']+'
    string.gsub(str, pattern, function(w) table.insert(splitList, w) end)
    return splitList
end
local function values(t)
    local i = 0
    return function()
        i = i + 1;
        return t[i]
    end
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
local function bcd2Int(bcd)
    return (bit.band(0x0F, bit.rshift(bcd, 4))) * 10 + bit.band(0x0F, bcd)
end
local function setDefaultValue()
    if (keyP["powerValue"] == nil) then
        keyP["powerValue"] = keyB["BYTE_POWER_ON"]
    end
    if (keyP["modeValue"] == nil) then
        keyP["modeValue"] = keyB["BYTE_MODE_AUTO"]
    end
    if (keyP["smartDryValue"] == nil) then keyP["smartDryValue"] = 50 end
    if (keyP["temperature"] == nil) then keyP["temperature"] = 26 end
    if (keyP["smallTemperature"] == nil) then keyP["smallTemperature"] = 0 end
    if (keyP["fanspeedValue"] == nil) then keyP["fanspeedValue"] = 102 end
    if (keyP["closeTimerSwitch"] == nil) then
        keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
    end
    if (keyP["openTimerSwitch"] == nil) then
        keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_OFF"]
    end
    if (keyP["strongWindValue"] == nil) then
        keyP["strongWindValue"] = keyB["BYTE_STRONG_WIND_OFF"]
    end
    if (keyP["comfortableSleepValue"] == nil) then
        keyP["comfortableSleepValue"] = keyB["BYTE_SLEEP_OFF"]
    end
    if (keyP["comfortableSleepSwitch"] == nil) then
        keyP["comfortableSleepSwitch"] = 0x00
    end
    if (keyP["comfortableSleepTime"] == nil) then
        keyP["comfortableSleepTime"] = 0x00
    end
    if (keyP["PTCValue"] == nil) then keyP["PTCValue"] = keyB["BYTE_PTC_OFF"] end
    if (keyP["purifierValue"] == nil) then
        keyP["purifierValue"] = keyB["BYTE_PURIFIER_OFF"]
    end
    if (keyP["ecoValue"] == nil) then keyP["ecoValue"] = keyB["BYTE_ECO_OFF"] end
    if (keyP["dryValue"] == nil) then keyP["dryValue"] = keyB["BYTE_DRY_OFF"] end
    if (keyP["swingLRValue"] == nil) then
        keyP["swingLRValue"] = keyB["BYTE_SWING_LR_OFF"]
    end
    if (keyP["swingUDValue"] == nil) then
        keyP["swingUDValue"] = keyB["BYTE_SWING_UD_OFF"]
    end
    if (keyP["comfortPowerSave"] == nil) then
        keyP["comfortPowerSave"] = keyB["BYTE_COMFORT_POWER_SAVE_OFF"]
    end
    if (keyP["preventCold"] == nil) then keyP["preventCold"] = 0x00 end
    if (keyP["power_saving"] == nil) then keyP["power_saving"] = 0x00 end
end
local function jsonToModel(jsonCmd, jsonType)
    local streams = jsonCmd
    if (streams[keyT["KEY_POWER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["powerValue"] = keyB["BYTE_POWER_ON"]
    elseif (streams[keyT["KEY_POWER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["powerValue"] = keyB["BYTE_POWER_OFF"]
    end
    if (streams[keyT["KEY_BUZZER"]] == "VALUE_FUNCTION_ON") then
        keyP["buzzerValue"] = keyB["BYTE_BUZZER_ON"]
    elseif (streams[keyT["KEY_BUZZER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["buzzerValue"] = keyB["BYTE_BUZZER_OFF"]
    end
    if (streams["ptc_force"] ~= nil) then
        if (streams["ptc_force"] == "on") then
            keyP["PTCForceValue"] = 1
        else
            keyP["PTCForceValue"] = 0
        end
    end
    if (streams[keyT["KEY_PURIFIER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["purifierValue"] = keyB["BYTE_PURIFIER_ON"]
    elseif (streams[keyT["KEY_PURIFIER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["purifierValue"] = keyB["BYTE_PURIFIER_OFF"]
    end
    if (streams[keyT["KEY_ECO"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["ecoValue"] = keyB["BYTE_ECO_ON"]
    elseif (streams[keyT["KEY_ECO"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["ecoValue"] = keyB["BYTE_ECO_OFF"]
    end
    if (streams[keyT["KEY_DRY"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["dryValue"] = keyB["BYTE_DRY_ON"]
    elseif (streams[keyT["KEY_DRY"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["dryValue"] = keyB["BYTE_DRY_OFF"]
    end
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
    if (streams[keyT["KEY_SMART_DRY"]] ~= nil) then
        keyP["smartDryValue"] = checkBoundary(streams[keyT["KEY_SMART_DRY"]],
                                              30, 101)
    end
    if (streams[keyT["KEY_NATURAL_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["naturalWind"] = keyB["BYTE_NATURAL_WIND_ON"]
    elseif (streams[keyT["KEY_NATURAL_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["naturalWind"] = keyB["BYTE_NATURAL_WIND_OFF"]
    end
    if (streams[keyT["KEY_PMV"]] ~= nil) then
        keyP["pmv"] = checkBoundary(streams[keyT["KEY_PMV"]], -3.5, 3)
    end
    if (streams[keyT["KEY_FANSPEED"]] ~= nil) then
        keyP["fanspeedValue"] = checkBoundary(streams[keyT["KEY_FANSPEED"]], 1,
                                              102)
    end
    if (streams[keyT["KEY_SWING_UD"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingUDValue"] = keyB["BYTE_SWING_UD_ON"]
    elseif (streams[keyT["KEY_SWING_UD"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingUDValue"] = keyB["BYTE_SWING_UD_OFF"]
    end
    if (streams[keyT["KEY_SWING_LR"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingLRValue"] = keyB["BYTE_SWING_LR_ON"]
    elseif (streams[keyT["KEY_SWING_LR"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingLRValue"] = keyB["BYTE_SWING_LR_OFF"]
    end
    if (jsonType == "control" and streams["wind_swing_lr_left"] ==
        keyV["VALUE_FUNCTION_ON"]) then
        keyP["wind_swing_lr_left"] = 0x02
    elseif (jsonType == "control" and streams["wind_swing_lr_left"] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["wind_swing_lr_left"] = 0x00
    end
    if (jsonType == "control" and streams["wind_swing_lr_left"] ==
        keyV["VALUE_FUNCTION_ON"]) then
        keyP["wind_swing_lr_left"] = 0x01
    elseif (jsonType == "control" and streams["wind_swing_lr_left"] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["wind_swing_lr_left"] = 0x00
    end
    if (streams[keyT["KEY_SWING_LR_UNDER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingLRUnderSwitch"] = keyB["BYTE_SWING_LR_UNDER_ENABLE"]
        keyP["swingLRValueUnder"] = keyB["BYTE_SWING_LR_UNDER_ON"]
    elseif (streams[keyT["KEY_SWING_LR_UNDER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingLRUnderSwitch"] = keyB["BYTE_SWING_LR_UNDER_ENABLE"]
        keyP["swingLRValueUnder"] = keyB["BYTE_SWING_LR_UNDER_OFF"]
    end
    if (streams[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_ON"]
        if (jsonType == "control") then keyP["timerSignal"] = 1 end
    elseif (streams[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_OFF"]
        if (jsonType == "control") then keyP["timerSignal"] = 1 end
    end
    if (streams[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]
        if (jsonType == "control") then keyP["timerSignal"] = 1 end
    elseif (streams[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
        if (jsonType == "control") then keyP["timerSignal"] = 1 end
    end
    if (streams[keyT["KEY_CLOSE_TIME"]] ~= nil) then
        keyP["closeTime"] = streams[keyT["KEY_CLOSE_TIME"]]
    end
    if (streams[keyT["KEY_OPEN_TIME"]] ~= nil) then
        keyP["openTime"] = streams[keyT["KEY_OPEN_TIME"]]
    end
    if (streams[keyT["KEY_COMFORT_SLEEP"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["comfortableSleepValue"] = keyB["BYTE_SLEEP_ON"]
        keyP["comfortableSleepSwitch"] = 0x40
        keyP["comfortableSleepTime"] = 0x0A
    elseif (streams[keyT["KEY_COMFORT_SLEEP"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["comfortableSleepValue"] = keyB["BYTE_SLEEP_OFF"]
        keyP["comfortableSleepSwitch"] = 0x00
        keyP["comfortableSleepTime"] = 0x00
    end
    if (streams[keyT["KEY_COMFORT_SLEEP_CURVE"]] ~= nil) then
        streams[keyT["KEY_COMFORT_SLEEP_CURVE"]] = string.gsub(
                                                       streams[keyT["KEY_COMFORT_SLEEP_CURVE"]],
                                                       ",", "")
        comfortByte = numstring2table(streams[keyT["KEY_COMFORT_SLEEP_CURVE"]])
    end
    if (streams[keyT["KEY_PTC"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["PTCValue"] = keyB["BYTE_PTC_ON"]
    elseif (streams[keyT["KEY_PTC"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["PTCValue"] = keyB["BYTE_PTC_OFF"]
    end
    if (streams[keyT["KEY_STRONG_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["strongWindValue"] = keyB["BYTE_STRONG_WIND_ON"]
    elseif (streams[keyT["KEY_STRONG_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["strongWindValue"] = keyB["BYTE_STRONG_WIND_OFF"]
    end
    if (streams[keyT["KEY_TEMPERATURE"]] ~= nil) then
        keyP["temperature"] = checkBoundary(streams[keyT["KEY_TEMPERATURE"]],
                                            16, 30)
    end
    if (streams["small_temperature"] ~= nil) then
        keyP["smallTemperature"] = checkBoundary(streams["small_temperature"],
                                                 0, 0.5)
        if (keyP["smallTemperature"] == 0.5) then
            keyP["smallTemperature"] = 0x01
        else
            keyP["smallTemperature"] = 0x00
        end
    end
    if (streams[keyT["KEY_COMFORT_POWER_SAVE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["comfortPowerSave"] = keyB["BYTE_COMFORT_POWER_SAVE_ON"]
    elseif (streams[keyT["KEY_COMFORT_POWER_SAVE"]] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["comfortPowerSave"] = keyB["BYTE_COMFORT_POWER_SAVE_OFF"]
    end
    if (jsonType == "control" and streams[keyT["KEY_PREVENT_SUPER_COOL"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_PREVENT_SUPER_COOL"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["prevent_super_cool"] = 0x01
        elseif (streams[keyT["KEY_PREVENT_SUPER_COOL"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["prevent_super_cool"] = 0x00
        end
    end
    if (streams[keyT["KEY_PREVENT_COLD"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["preventCold"] = 0x01
    elseif (streams[keyT["KEY_PREVENT_COLD"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["preventCold"] = 0x00
    end
    if (jsonType == "control" and streams[keyT["KEY_PREVENT_STRAIGHT_WIND"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["prevent_straight_wind"] = checkBoundary(
                                            streams[keyT["KEY_PREVENT_STRAIGHT_WIND"]],
                                            0, 3)
    end
    if (jsonType == "control" and streams[keyT["KEY_FA_PREVENT_STRAIGHT_WIND"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["fa_prevent_straight_wind"] = checkBoundary(
                                               streams[keyT["KEY_FA_PREVENT_STRAIGHT_WIND"]],
                                               0, 2)
    end
    if (jsonType == "control" and
        streams[keyT["KEY_AUTO_PREVENT_STRAIGHT_WIND"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_AUTO_PREVENT_STRAIGHT_WIND"]] ==
            keyV["VALUE_FUNCTION_ON"]) then
            keyP["auto_prevent_straight_wind"] = 0x01
        elseif (streams[keyT["KEY_AUTO_PREVENT_STRAIGHT_WIND"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["auto_prevent_straight_wind"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_SELF_CLEAN"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_SELF_CLEAN"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["self_clean"] = 0x01
        elseif (streams[keyT["KEY_SELF_CLEAN"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["self_clean"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_WIND_STRAIGHT"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_WIND_STRAIGHT"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["wind_straight"] = 0x01
        elseif (streams[keyT["KEY_WIND_STRAIGHT"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["wind_straight"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_WIND_AVOID"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_WIND_AVOID"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["wind_avoid"] = 0x01
        elseif (streams[keyT["KEY_WIND_AVOID"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["wind_avoid"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_YB_WIND_AVOID"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_YB_WIND_AVOID"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["yb_wind_avoid"] = 0x02
        elseif (streams[keyT["KEY_YB_WIND_AVOID"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["yb_wind_avoid"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_INTELLIGENT_WIND"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_INTELLIGENT_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["intelligent_wind"] = 0x01
        elseif (streams[keyT["KEY_INTELLIGENT_WIND"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["intelligent_wind"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_NO_WIND_SENSE"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["no_wind_sense"] = checkBoundary(
                                    streams[keyT["KEY_NO_WIND_SENSE"]], 0, 5)
    end
    if (jsonType == "control" and streams[keyT["KEY_FN_NO_WIND_SENSE"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_FN_NO_WIND_SENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["fn_no_wind_sense"] = 0x01
        elseif (streams[keyT["KEY_FN_NO_WIND_SENSE"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["fn_no_wind_sense"] = 0x00
        end
    end
    if (streams["no_wind_sense_level"] ~= nil) then
        keyP["no_wind_sense_level"] = streams["no_wind_sense_level"]
    end
    if (jsonType == "control" and streams[keyT["KEY_CHILD_PREVENT_COLD_WIND"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_CHILD_PREVENT_COLD_WIND"]] ==
            keyV["VALUE_FUNCTION_ON"]) then
            keyP["child_prevent_cold_wind"] = 0x01
        elseif (streams[keyT["KEY_CHILD_PREVENT_COLD_WIND"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["child_prevent_cold_wind"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_LITTLE_ANGLE"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_LITTLE_ANGLE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["little_angel"] = 0x01
        elseif (streams[keyT["KEY_LITTLE_ANGLE"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["little_angel"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_COOL_HOT_SENSE"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_COOL_HOT_SENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["cool_hot_sense"] = 0x01
        elseif (streams[keyT["KEY_COOL_HOT_SENSE"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["cool_hot_sense"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_GENTLE_WIND_SENSE"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_GENTLE_WIND_SENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["gentle_wind_sense"] = 0x03
        elseif (streams[keyT["KEY_GENTLE_WIND_SENSE"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["gentle_wind_sense"] = 0x01
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_SECURITY"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_SECURITY"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["security"] = 0x01
        elseif (streams[keyT["KEY_SECURITY"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["security"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_EVEN_WIND"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_EVEN_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["even_wind"] = 0x01
        elseif (streams[keyT["KEY_EVEN_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["even_wind"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_SINGLE_TUYERE"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_SINGLE_TUYERE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["single_tuyere"] = 0x01
        elseif (streams[keyT["KEY_SINGLE_TUYERE"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["single_tuyere"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_EXTREME_WIND"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_EXTREME_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["extreme_wind"] = 0x01
        elseif (streams[keyT["KEY_EXTREME_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["extreme_wind"] = 0x00
        end
    end
    if (streams["extreme_wind_level"] ~= nil) then
        keyP["extreme_wind_level"] = streams["extreme_wind_level"]
    end
    if (jsonType == "control" and streams[keyT["KEY_VOICE_CONTROL"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_VOICE_CONTROL"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["voice_control"] = 0x03
        elseif (streams[keyT["KEY_VOICE_CONTROL"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["voice_control"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_PRE_COOL_HOT"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_PRE_COOL_HOT"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["pre_cool_hot"] = 0x01
        elseif (streams[keyT["KEY_PRE_COOL_HOT"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["pre_cool_hot"] = 0x00
        end
    end
    if (jsonType == "control" and streams["ptc_default_rule"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["ptc_default_rule"] = streams["ptc_default_rule"]
    end
    if (jsonType == "control" and streams[keyT["KEY_WATER_WASHING"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_WATER_WASHING"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["water_washing"] = 0x01
        elseif (streams[keyT["KEY_WATER_WASHING"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["water_washing"] = 0x00
        end
    end
    if (streams["water_washing_manual"] ~= nil) then
        keyP["water_washing_manual"] = streams["water_washing_manual"]
        keyP["water_washing_time"] = streams["water_washing_time"]
        keyP["water_washing_stage"] = streams["water_washing_stage"]
    end
    if (jsonType == "control" and streams[keyT["KEY_FRESH_AIR"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_FRESH_AIR"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["fresh_air"] = 0x01
        elseif (streams[keyT["KEY_FRESH_AIR"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["fresh_air"] = 0x00
        end
    end
    if (streams["fresh_air_fan_speed"] ~= nil) then
        keyP["fresh_air_fan_speed"] = streams["fresh_air_fan_speed"]
        keyP["fresh_air_temp"] = streams["fresh_air_temp"]
    end
    if (jsonType == "control" and streams[keyT["KEY_PARENT_CONTROL"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_PARENT_CONTROL"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["parent_control"] = 0x01
        elseif (streams[keyT["KEY_PARENT_CONTROL"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["parent_control"] = 0x00
        end
    end
    if (streams["parent_control_temp_up"] ~= nil or
        keyP["parent_control_temp_down"] ~= nil) then
        keyP["parent_control_temp_up"] = streams["parent_control_temp_up"]
        keyP["parent_control_temp_down"] = streams["parent_control_temp_down"]
    end
    if (jsonType == "control" and streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["nobody_energy_save"] = 0x01
        elseif (streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["nobody_energy_save"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_PREVENT_STRAIGHT_WIND_LR"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["prevent_straight_wind_lr"] = checkBoundary(
                                               streams[keyT["KEY_PREVENT_STRAIGHT_WIND_LR"]],
                                               0, 3)
    end
    if (jsonType == "control" and streams[keyT["KEY_PM25_VALUE"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["pm25_value"] = streams[keyT["KEY_PM25_VALUE"]]
    end
    if (jsonType == "control" and streams[keyT["KEY_WATER_PUMP"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_WATER_PUMP"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["water_pump"] = 0x01
        elseif (streams[keyT["KEY_WATER_PUMP"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["water_pump"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_WIND_SWING_UD_ANGLE"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["wind_swing_ud_angle"] = streams["wind_swing_ud_angle"]
    end
    if (jsonType == "control" and streams[keyT["KEY_WIND_SWING_LR_ANGLE"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["wind_swing_lr_angle"] = streams["wind_swing_lr_angle"]
    end
    if (jsonType == "control" and streams[keyT["KEY_INTENLLIGENT_CONTROL"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_INTENLLIGENT_CONTROL"]] ==
            keyV["VALUE_FUNCTION_ON"]) then
            keyP["intelligent_control"] = 0x01
        elseif (streams[keyT["KEY_INTENLLIGENT_CONTROL"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["intelligent_control"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_VOLUME_CONTROL"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["volume_control"] = checkBoundary(
                                     streams[keyT["KEY_VOLUME_CONTROL"]], 0, 100)
    end
    if (jsonType == "control" and streams[keyT["KEY_VOICE_CONTROL_NEW"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["voice_control_new"] = checkBoundary(
                                        streams[keyT["KEY_VOICE_CONTROL_NEW"]],
                                        0, 3)
    end
    if (jsonType == "control" and
        (streams["wind_swing_ud_angle_up"] ~= nil or
            streams["wind_swing_ud_angle_down"] ~= nil or
            streams["app_control_remember_ud"] ~= nil)) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["wind_swing_ud_angle_switch"] = 1
    end
    if (streams["wind_swing_ud_angle_up"] ~= nil) then
        keyP["wind_swing_ud_angle_up"] = streams["wind_swing_ud_angle_up"]
    end
    if (streams["wind_swing_ud_angle_down"] ~= nil) then
        keyP["wind_swing_ud_angle_down"] = streams["wind_swing_ud_angle_down"]
    end
    if (streams["app_control_remember_ud"] ~= nil) then
        keyP["app_control_remember_ud"] = streams["app_control_remember_ud"]
    end
    if (jsonType == "control" and
        (streams["wind_swing_lr_angle_up"] ~= nil or
            streams["wind_swing_lr_angle_down"] ~= nil or
            streams["app_control_remember_lr"] ~= nil)) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["wind_swing_lr_angle_switch"] = 1
    end
    if (streams["wind_swing_lr_angle_up"] ~= nil) then
        keyP["wind_swing_lr_angle_up"] = streams["wind_swing_lr_angle_up"]
    end
    if (streams["wind_swing_lr_angle_down"] ~= nil) then
        keyP["wind_swing_lr_angle_down"] = streams["wind_swing_lr_angle_down"]
    end
    if (streams["app_control_remember_lr"] ~= nil) then
        keyP["app_control_remember_lr"] = streams["app_control_remember_lr"]
    end
    if (jsonType == "control" and streams["auto_prevent_cold_wind"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["auto_prevent_cold_wind"] = streams["auto_prevent_cold_wind"]
    end
    if (jsonType == "control" and
        (streams[keyT["KEY_AUTO_TEMP_UP"]] ~= nil or
            streams[keyT["KEY_AUTO_TEMP_DOWN"]] ~= nil or
            streams[keyT["KEY_COOL_TEMP_UP"]] ~= nil or
            streams[keyT["KEY_COOL_TEMP_DOWN"]] ~= nil or
            streams[keyT["KEY_HEAT_TEMP_UP"]] ~= nil or
            streams[keyT["KEY_HEAT_TEMP_DOWN"]] ~= nil)) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
    end
    if (streams["cool_temp_up"] ~= nil) then
        keyP["cool_temp_up"] = streams["cool_temp_up"]
    end
    if (streams["cool_temp_down"] ~= nil) then
        keyP["cool_temp_down"] = streams["cool_temp_down"]
    end
    if (streams["auto_temp_up"] ~= nil) then
        keyP["auto_temp_up"] = streams["auto_temp_up"]
    end
    if (streams["auto_temp_down"] ~= nil) then
        keyP["auto_temp_down"] = streams["auto_temp_down"]
    end
    if (streams["heat_temp_up"] ~= nil) then
        keyP["heat_temp_up"] = streams["heat_temp_up"]
    end
    if (streams["heat_temp_down"] ~= nil) then
        keyP["heat_temp_down"] = streams["heat_temp_down"]
    end
    if (streams[keyT["KEY_POWER_SAVING"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["power_saving"] = 0x08
    elseif (streams[keyT["KEY_POWER_SAVING"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["power_saving"] = 0x00
    end
    if (jsonType == "control" and streams[keyT["KEY_POWER_LOCK"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_POWER_LOCK"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["power_lock"] = 0x01
        elseif (streams[keyT["KEY_POWER_LOCK"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["power_lock"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_PTC_LOCK"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_PTC_LOCK"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["ptc_lock"] = 0x01
        elseif (streams[keyT["KEY_PTC_LOCK"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["ptc_lock"] = 0x00
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_OFFLINE_OPERATING_TIME"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["offline_operating_time"] = streams["offline_operating_time"]
    end
    if (jsonType == "control" and streams[keyT["KEY_REMOTE_CONTROL_LOCK"]] ~=
        nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["remote_control_lock"] = streams["remote_control_lock"]
        keyP["remote_control_lock_control"] =
            streams["remote_control_lock_control"]
    end
    if (jsonType == "control" and streams[keyT["KEY_OPERATING_TIME"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["operating_time"] = streams["operating_time"]
    end
    if (streams[keyT["KEY_FRESH_FILTER_RESET"]] ~= nil) then
        if (streams[keyT["KEY_FRESH_FILTER_RESET"]] == 0x01) then
            keyP["fresh_filter_reset"] = 0x80
        end
    end
    if (jsonType == "control" and streams[keyT["KEY_DEGERMING"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_DEGERMING"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["degerming"] = 0x01
        elseif (streams[keyT["KEY_DEGERMING"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["degerming"] = 0x00
        end
    end
    if (jsonType == "control" and streams["light"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["light"] = checkBoundary(streams["light"], 0, 100)
    end
    if (jsonType == "control" and streams[keyT["KEY_WIND_AROUND"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_WIND_AROUND"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["wind_around"] = 0x01
        elseif (streams[keyT["KEY_WIND_AROUND"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["wind_around"] = 0x00
        end
    end
    if (streams["wind_around_ud"] ~= nil) then
        keyP["wind_around_ud"] = streams["wind_around_ud"]
    end
    if (jsonType == "control" and streams[keyT["KEY_WIND_TOP"]] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams[keyT["KEY_WIND_TOP"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["wind_top"] = 0x01
        elseif (streams[keyT["KEY_WIND_TOP"]] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["wind_top"] = 0x00
        end
    end
    if (jsonType == "control" and streams["child_lock"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["child_lock"] = streams["child_lock"]
    end
    if (jsonType == "control" and streams["ilinkId"] ~= nil) then
        keyP["ilinkId"] = streams["ilinkId"]
    end
    if (jsonType == "control" and streams["ticket"] ~= nil) then
        keyP["ticket"] = streams["ticket"]
    end
    if (jsonType == "control" and streams["buzzer_all"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["buzzer_all"] = streams["buzzer_all"]
    end
    if (jsonType == "control" and streams["self_remove_odor_phase"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["self_remove_odor_phase"] = streams["self_remove_odor_phase"]
    end
    if (jsonType == "control" and streams["high_temp_remove_odor_alone"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["high_temp_remove_odor_alone"] =
            streams["high_temp_remove_odor_alone"]
    end
    if (jsonType == "control" and streams["ozone"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["ozone"] = streams["ozone"]
    end
    if (jsonType == "control" and streams["soft_warm"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["soft_warm"] = streams["soft_warm"]
    end
    if (jsonType == "control" and streams["fresh_air_parm"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["fresh_air_parm"] = streams["fresh_air_parm"]
    end
    if (jsonType == "control" and streams["rewarming_dry"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["rewarming_dry"] = streams["rewarming_dry"]
    end
    if (jsonType == "control" and streams["arom"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["arom"] = streams["arom"]
    end
    if (streams["arom_fan_speed"] ~= nil) then
        keyP["arom_fan_speed"] = streams["arom_fan_speed"]
    end
    if (streams["arom_time"] ~= nil) then
        keyP["arom_time"] = streams["arom_time"]
    end
    if (streams["arom_time_clean"] ~= nil) then
        keyP["arom_time_clean"] = streams["arom_time_clean"]
    end
    if (streams["arom_time_total"] ~= nil) then
        keyP["arom_time_total"] = streams["arom_time_total"]
    end
    if (jsonType == "control" and streams["new_mode_power"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["new_mode_power"] = streams["new_mode_power"]
    end
    if (jsonType == "control" and streams["new_mode"] ~= nil) then
        if (streams["new_mode"] == "auto") then
            keyP["new_mode"] = 1
        elseif (streams["new_mode"] == "cool") then
            keyP["new_mode"] = 2
        elseif (streams["new_mode"] == "dry") then
            keyP["new_mode"] = 3
        elseif (streams["new_mode"] == "heat") then
            keyP["new_mode"] = 4
        elseif (streams["new_mode"] == "fan") then
            keyP["new_mode"] = 5
        else
            keyP["new_mode"] = 0
        end
    end
    if (jsonType == "control" and streams["new_temperature"] ~= nil) then
        keyP["new_temperature"] = streams["new_temperature"] * 2
    end
    if (jsonType == "control" and streams["new_wind_speed"] ~= nil) then
        keyP["new_wind_speed"] = streams["new_wind_speed"]
    end
    if (jsonType == "control" and
        (streams["uvc_remove_odor"] ~= nil or streams["uvc_power_off"] ~= nil)) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
    end
    if (streams["uvc_remove_odor"] ~= nil) then
        keyP["uvc_remove_odor"] = streams["uvc_remove_odor"]
    end
    if (streams["uvc_power_off"] ~= nil) then
        keyP["uvc_power_off"] = streams["uvc_power_off"]
    end
    if (streams["main_horizontal_guide_strip_1"] ~= nil) then
        keyP["main_horizontal_guide_strip_1"] =
            streams["main_horizontal_guide_strip_1"]
    end
    if (streams["main_horizontal_guide_strip_2"] ~= nil) then
        keyP["main_horizontal_guide_strip_2"] =
            streams["main_horizontal_guide_strip_2"]
    end
    if (streams["main_horizontal_guide_strip_3"] ~= nil) then
        keyP["main_horizontal_guide_strip_3"] =
            streams["main_horizontal_guide_strip_3"]
    end
    if (streams["main_horizontal_guide_strip_4"] ~= nil) then
        keyP["main_horizontal_guide_strip_4"] =
            streams["main_horizontal_guide_strip_4"]
    end
    if (jsonType == "control" and
        (streams["main_horizontal_guide_strip_1"] ~= nil or
            streams["main_horizontal_guide_strip_2"] ~= nil or
            streams["main_horizontal_guide_strip_3"] ~= nil or
            streams["main_horizontal_guide_strip_4"] ~= nil)) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["main_strip_control"] = 1
    end
    if (jsonType == "control" and streams["light_sensitive"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["light_sensitive"] = streams["light_sensitive"]
    end
    if (jsonType == "control" and streams["prepare_food"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["prepare_food"] = streams["prepare_food"]
    end
    if (streams["prepare_food_temp"] ~= nil) then
        keyP["prepare_food_temp"] = streams["prepare_food_temp"]
    end
    if (streams["prepare_food_fan_speed"] ~= nil) then
        keyP["prepare_food_fan_speed"] = streams["prepare_food_fan_speed"]
    end
    if (jsonType == "control" and streams["quick_fry"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["quick_fry"] = streams["quick_fry"]
    end
    if (streams["quick_fry_temp"] ~= nil) then
        keyP["quick_fry_temp"] = streams["quick_fry_temp"]
    end
    if (streams["quick_fry_fan_speed"] ~= nil) then
        keyP["quick_fry_fan_speed"] = streams["quick_fry_fan_speed"]
    end
    if (jsonType == "control" and streams["cool_power_saving"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        keyP["cool_power_saving"] = streams["cool_power_saving"]
    end
    if (jsonType == "control" and streams["jet_cool"] ~= nil) then
        keyP["propertyNumber"] = keyP["propertyNumber"] + 1
        if (streams["jet_cool"] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["jet_cool"] = 0x01
        elseif (streams["jet_cool"] == keyV["VALUE_FUNCTION_OFF"]) then
            keyP["jet_cool"] = 0x00
        end
    end
    if (jsonType == "status") then keyP["propertyNumber"] = 0 end
end
local function binToModel(binData, deviceSN8)
    local messageBytes = binData
    keyP["analysis_value"] = nil
    if ((dataType == 0x02 and messageBytes[0] == 0xC0) or
        (dataType == 0x03 and messageBytes[0] == 0xC0) or
        (dataType == 0x05 and messageBytes[0] == 0xA0)) then
        if (#binData < 21) then return nil end
        keyP["analysis_value"] =
            "power,mode,temperature,wind_speed,power_on_timer,smart_dry_value,power_off_timer,power_off_time_value,power_on_time_value,ptc,eco,dry,wind_swing_lr,wind_swing_lr_under,wind_swing_ud,kick_quilt,prevent_cold,small_temperature,purifier,dust_full_time,power_saving,fault_tag"
        keyP["powerValue"] = bit.band(messageBytes[1], 0x01)
        keyP["modeValue"] = bit.band(messageBytes[2], 0xE0)
        keyP["fault_tag"] = bit.rshift(bit.band(messageBytes[1], 0x80), 7)
        if (keyP["modeValue"] == keyB["BYTE_MODE_SMART_DRY"]) then
            if (dataType == 0x05) then
                keyP["smartDryValue"] = bit.band(messageBytes[13], 0x7F)
            else
                keyP["smartDryValue"] = bit.band(messageBytes[19], 0x7F)
            end
        end
        if (dataType == 0x05 and messageBytes[0] == 0xA0) then
            keyP["is_query"] = 0
        end
        if (dataType == 0x05) then
            if deviceSN8 == "11447" or deviceSN8 == "11451" or deviceSN8 ==
                "11453" or deviceSN8 == "11455" or deviceSN8 == "11457" or
                deviceSN8 == "11459" or deviceSN8 == "11525" or deviceSN8 ==
                "11527" or deviceSN8 == "11533" or deviceSN8 == "11535" then
                keyP["temperature"] = bit.rshift(
                                          bit.band(messageBytes[1], 0x7C), 2) +
                                          0x0C
                keyP["smallTemperature"] = bit.rshift(
                                               bit.band(messageBytes[1], 0x02),
                                               1)
            else
                keyP["temperature"] = bit.rshift(
                                          bit.band(messageBytes[1], 0x3E), 1) +
                                          0x0C
                keyP["smallTemperature"] = bit.rshift(
                                               bit.band(messageBytes[1], 0x40),
                                               6)
            end
        else
            keyP["temperature"] = bit.band(messageBytes[2], 0x0F) + 0x10
            keyP["smallTemperature"] = bit.rshift(
                                           bit.band(messageBytes[2], 0x10), 4)
        end
        keyP["fanspeedValue"] = bit.band(messageBytes[3], 0x7F)
        if (bit.band(messageBytes[4], keyB["BYTE_START_TIMER_SWITCH_ON"]) ==
            keyB["BYTE_START_TIMER_SWITCH_ON"]) then
            keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_ON"]
        else
            keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_OFF"]
        end
        if (bit.band(messageBytes[5], keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) ==
            keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
            keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]
        else
            keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
        end
        keyP["closeHour"] = bit.rshift(bit.band(messageBytes[5], 0x7F), 2)
        keyP["closeStepMintues"] = bit.band(messageBytes[5], 0x03)
        keyP["closeMin"] = 15 - bit.band(messageBytes[6], 0x0f)
        keyP["closeTime"] = keyP["closeHour"] * 60 + keyP["closeStepMintues"] *
                                15 + keyP["closeMin"]
        keyP["openHour"] = bit.rshift(bit.band(messageBytes[4], 0x7F), 2)
        keyP["openStepMintues"] = bit.band(messageBytes[4], 0x03)
        keyP["openMin"] = 15 - bit.rshift(bit.band(messageBytes[6], 0xf0), 4)
        keyP["openTime"] =
            keyP["openHour"] * 60 + keyP["openStepMintues"] * 15 +
                keyP["openMin"]
        keyP["strongWindValue"] = bit.band(messageBytes[8], 0x20)
        keyP["power_saving"] = bit.band(messageBytes[8], 0x08)
        keyP["comfortableSleepValue"] = bit.band(messageBytes[8], 0x03)
        keyP["comfortableSleepSwitch"] = bit.band(messageBytes[9], 0x40)
        if (dataType == 0x05) then
            keyP["comfortableSleepSwitch"] = bit.band(messageBytes[14], 0x01)
            keyP["naturalWind"] = bit.band(messageBytes[10], 0x40)
            keyP["screenDisplayNowValue"] = bit.band(messageBytes[11], 0x07)
            keyP["pmv"] =
                bit.rshift(bit.band(messageBytes[11], 0xF0), 4) * 0.5 - 3.5
            keyP["swingLRValueUnder"] = bit.band(messageBytes[9], 0x40)
        else
            keyP["comfortableSleepSwitch"] = bit.band(messageBytes[9], 0x40)
            keyP["naturalWind"] = bit.band(messageBytes[9], 0x02)
            keyP["screenDisplayNowValue"] =
                bit.rshift(bit.band(messageBytes[14], 0x70), 4)
            keyP["pmv"] = bit.band(messageBytes[14], 0x0f) * 0.5 - 3.5
            keyP["swingLRValueUnder"] = bit.band(messageBytes[20], 0x80)
        end
        keyP["PTCValue"] = bit.band(messageBytes[9], 0x08)
        keyP["purifierValue"] = bit.band(messageBytes[9], 0x20)
        keyP["ecoValue"] = bit.lshift(bit.band(messageBytes[9], 0x10), 3)
        keyP["dryValue"] = bit.band(messageBytes[9], 0x04)
        keyP["swingLRValue"] = bit.band(messageBytes[7], 0x03)
        keyP["swingUDValue"] = bit.band(messageBytes[7], 0x0C)
        keyP["swingLRUnderSwitch"] = bit.band(messageBytes[19], 0x80)
        if (dataType == 0x02 or dataType == 0x03) then
            if ((messageBytes[11] ~= 0) and (messageBytes[11] ~= 0xFF)) then
                keyP["indoorTemperatureValue"] = (messageBytes[11] - 50) / 2
                keyP["smallIndoorTemperatureValue"] =
                    bit.band(messageBytes[15], 0xF);
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. ",indoor_temperature"
            end
            if ((messageBytes[12] ~= 0) and (messageBytes[12] ~= 0xFF)) then
                keyP["outdoorTemperatureValue"] = (messageBytes[12] - 50) / 2
                keyP["smallOutdoorTemperatureValue"] = bit.rshift(
                                                           messageBytes[15], 4);
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. ",outdoor_temperature"
            end
        end
        keyP["errorCode"] = messageBytes[16]
        if (dataType == 0x02 or dataType == 0x03) then
            keyP["dust_full_time"] = bit.rshift(
                                         bit.band(messageBytes[13], 0x20), 5)
        end
        keyP["kickQuilt"] = bit.rshift(bit.band(messageBytes[10], 0x04), 2)
        if (dataType == 0x05) then
            keyP["preventCold"] =
                bit.rshift(bit.band(messageBytes[10], 0x08), 3)
        else
            keyP["preventCold"] =
                bit.rshift(bit.band(messageBytes[10], 0x20), 5)
        end
        if (dataType == 0x05) then
            local temp = bit.rshift(bit.band(messageBytes[12], 0x3E), 1)
            if (temp > 0 and temp <= 25) then
                keyP["temperature"] = temp + 12
            end
        else
            local temp = bit.band(messageBytes[13], 0x1F)
            if (temp > 0 and temp <= 25) then
                keyP["temperature"] = temp + 12
            end
        end
        if (dataType == 0x05) then
            keyP["arom_old"] = bit.rshift(bit.band(messageBytes[21], 0x80), 7)
            keyP["analysis_value"] = keyP["analysis_value"] .. ",arom_old"
        end
        if (messageBytes[0] == 0xA0) then
            keyP["comfortPowerSave"] = bit.band(messageBytes[14], 0x01)
            keyP["analysis_value"] = keyP["analysis_value"] ..
                                         ",comfort_power_save"
        else
            if (#binData >= 24) then
                keyP["comfortPowerSave"] = bit.band(messageBytes[22], 0x01)
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. ",comfort_power_save"
            end
        end
        if (#binData >= 29) then
            keyP["fresh_filter_time_total"] =
                messageBytes[25] * 256 + messageBytes[24]
            keyP["fresh_filter_time_use"] =
                messageBytes[27] * 256 + messageBytes[26]
            keyP["fresh_filter_timeout"] = bit.rshift(
                                               bit.band(messageBytes[13], 0x40),
                                               6)
            keyP["analysis_value"] = keyP["analysis_value"] ..
                                         ",fresh_filter_time_total,fresh_filter_time_use,fresh_filter_timeout"
        end
        if (dataType == 0x05) then
            keyP["fresh_filter_time_use"] =
                messageBytes[16] * 256 + messageBytes[15]
            keyP["analysis_value"] = keyP["analysis_value"] ..
                                         ",fresh_filter_time_use"
        end
    end
    if ((dataType == 0x04 and messageBytes[0] == 0xA1)) then
        keyP["is_query"] = 0
        keyP["currentWorkTime"] = bit.bor((bit.band(
                                              bit.lshift(messageBytes[9], 8),
                                              0xFF00)),
                                          (bit.band(messageBytes[10], 0x00FF))) *
                                      60 * 24 + messageBytes[11] * 60 +
                                      messageBytes[12]
        keyP["analysis_value"] = "current_work_time"
        if (messageBytes[13] ~= 0x00 and messageBytes[13] ~= 0xff) then
            keyP["indoorTemperatureValue"] = (messageBytes[13] - 50) / 2
            keyP["smallIndoorTemperatureValue"] =
                bit.band(messageBytes[18], 0xF);
            keyP["analysis_value"] = keyP["analysis_value"] ..
                                         ",indoor_temperature"
        end
        if (messageBytes[14] ~= 0x00 and messageBytes[14] ~= 0xff) then
            keyP["outdoorTemperatureValue"] = (messageBytes[14] - 50) / 2
            keyP["smallOutdoorTemperatureValue"] =
                bit.rshift(messageBytes[18], 4);
            keyP["analysis_value"] = keyP["analysis_value"] ..
                                         ",outdoor_temperature"
        end
    end
    if (messageBytes[0] == 0xC1) then
        if (messageBytes[3] == 0x40) then
            keyP["analysis_value"] =
                "electrify_time_day,electrify_time_day,electrify_time_hour,electrify_time_min,electrify_time_second,total_operating_time_day,total_operating_time_hour,total_operating_time_min,total_operating_time_second,current_operating_time_day,current_operating_time_hour,current_operating_time_min,current_operating_time_second"
            keyP["electrify_time_day"] =
                bit.bor(messageBytes[5], bit.bor(bit.lshift(messageBytes[4], 8)))
            keyP["electrify_time_hour"] = messageBytes[6]
            keyP["electrify_time_min"] = messageBytes[7]
            keyP["electrify_time_second"] = messageBytes[8]
            keyP["total_operating_time_day"] =
                bit.bor(messageBytes[10],
                        bit.bor(bit.lshift(messageBytes[9], 8)))
            keyP["total_operating_time_hour"] = messageBytes[11]
            keyP["total_operating_time_min"] = messageBytes[12]
            keyP["total_operating_time_second"] = messageBytes[13]
            keyP["current_operating_time_day"] =
                bit.bor(messageBytes[15],
                        bit.bor(bit.lshift(messageBytes[14], 8)))
            keyP["current_operating_time_hour"] = messageBytes[16]
            keyP["current_operating_time_min"] = messageBytes[17]
            keyP["current_operating_time_second"] = messageBytes[18]
        end
        if (messageBytes[3] == 0x44) then
            keyP["analysis_value"] =
                "total_power_consumption,total_operating_consumption,current_operating_consumption,current_time_power"
            keyP["total_power_consumption"] =
                bcd2Int(messageBytes[4]) * 10000 + bcd2Int(messageBytes[5]) *
                    100 + bcd2Int(messageBytes[6]) + bcd2Int(messageBytes[7]) /
                    100
            keyP["total_operating_consumption"] =
                bcd2Int(messageBytes[8]) * 10000 + bcd2Int(messageBytes[9]) *
                    100 + bcd2Int(messageBytes[10]) + bcd2Int(messageBytes[11]) /
                    100
            keyP["current_operating_consumption"] =
                bcd2Int(messageBytes[12]) * 10000 + bcd2Int(messageBytes[13]) *
                    100 + bcd2Int(messageBytes[14]) + bcd2Int(messageBytes[15]) /
                    100
            keyP["current_time_power"] =
                bcd2Int(messageBytes[16]) + bcd2Int(messageBytes[17]) / 100 +
                    bcd2Int(messageBytes[18]) / 10000
        end
        if (messageBytes[3] == 0x41) then
            keyP["t2_temp"] = (messageBytes[11] - 30) / 2
        end
    end
    if (dataType == 0x05 and messageBytes[0] == 0xB5) then
        if (#binData < 7) then return nil end
        keyP["propertyNumber"] = messageBytes[1]
        keyP["analysis_value"] = ""
        local cursor = 2
        for i = 1, keyP["propertyNumber"] do
            if (messageBytes[cursor + 0] == 0x49 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["prevent_super_cool"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "prevent_super_cool,"
                cursor = cursor + 8
            end
            if (messageBytes[cursor + 0] == 0x42 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["prevent_straight_wind"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "prevent_straight_wind,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x26 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["auto_prevent_straight_wind"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "auto_prevent_straight_wind,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x11 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["ptc_default_rule"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "ptc_default_rule,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x39 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["self_clean"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "self_clean,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x32 and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 3] == 0x01) then
                    keyP["wind_straight"] = 0x01
                    keyP["analysis_value"] =
                        keyP["analysis_value"] .. "wind_straight,"
                end
                if (messageBytes[cursor + 3] == 0x02) then
                    keyP["wind_avoid"] = 0x01
                    keyP["yb_wind_avoid"] = 0x02
                    keyP["analysis_value"] =
                        keyP["analysis_value"] .. "wind_avoid,yb_wind_avoid,"
                end
                if (messageBytes[cursor + 3] == 0x00) then
                    keyP["wind_straight"] = 0x00
                    keyP["wind_avoid"] = 0x00
                    keyP["yb_wind_avoid"] = 0x00
                    keyP["analysis_value"] =
                        keyP["analysis_value"] ..
                            "wind_straight,wind_avoid,yb_wind_avoid,"
                end
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x33 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_avoid"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "wind_avoid,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x34 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["intelligent_wind"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "intelligent_wind,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x3A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["child_prevent_cold_wind"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "child_prevent_cold_wind,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x18 and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 3] == 0x02) then
                    keyP["fn_no_wind_sense"] = messageBytes[cursor + 3]
                    keyP["no_wind_sense_level"] = messageBytes[cursor + 4]
                    keyP["analysis_value"] =
                        keyP["analysis_value"] ..
                            "fn_no_wind_sense,no_wind_sense_level,"
                    cursor = cursor + 5
                else
                    keyP["no_wind_sense"] = messageBytes[cursor + 3]
                    keyP["analysis_value"] =
                        keyP["analysis_value"] .. "no_wind_sense,"
                    cursor = cursor + 4
                end
            end
            if (messageBytes[cursor + 0] == 0x1B and messageBytes[cursor + 1] ==
                0x02) then
                keyP["little_angel"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "little_angel,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x21 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["cool_hot_sense"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "cool_hot_sense,"
                cursor = cursor + 11
            end
            if (messageBytes[cursor + 0] == 0x29 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["security"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "security,"
                if (messageBytes[cursor + 3] == 2) then
                    keyP["security"] = 0
                end
                if (messageBytes[cursor + 3] == 3) then
                    keyP["security"] = 1
                end
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x4E and messageBytes[cursor + 1] ==
                0x00) then
                keyP["even_wind"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "even_wind,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x4F and messageBytes[cursor + 1] ==
                0x00) then
                keyP["single_tuyere"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "single_tuyere,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x4C and messageBytes[cursor + 1] ==
                0x00) then
                keyP["extreme_wind"] = messageBytes[cursor + 3]
                keyP["extreme_wind_level"] = messageBytes[cursor + 4]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "extreme_wind,extreme_wind_level,"
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x20 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["voice_control"] = messageBytes[cursor + 3]
                keyP["voice_control_new"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "voice_control,voice_control_new,"
                cursor = cursor + 23
            end
            if (messageBytes[cursor + 0] == 0x01 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["pre_cool_hot"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "pre_cool_hot,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x4A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["water_washing_manual"] = messageBytes[cursor + 3]
                keyP["water_washing"] = messageBytes[cursor + 4]
                keyP["water_washing_time"] = messageBytes[cursor + 5]
                keyP["water_washing_stage"] = messageBytes[cursor + 6]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "water_washing_manual,water_washing,water_washing_time,water_washing_stage,"
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x4B and messageBytes[cursor + 1] ==
                0x00) then
                keyP["fresh_air"] = messageBytes[cursor + 3]
                keyP["fresh_air_fan_speed"] = messageBytes[cursor + 4]
                keyP["fresh_air_temp"] = messageBytes[cursor + 5]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "fresh_air,fresh_air_fan_speed,fresh_air_temp,"
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x51 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["parent_control"] = messageBytes[cursor + 3]
                keyP["parent_control_temp_up"] = messageBytes[cursor + 4]
                keyP["parent_control_temp_down"] = messageBytes[cursor + 5]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "parent_control,parent_control_temp_up,parent_control_temp_down,"
                cursor = cursor + 8
            end
            if (messageBytes[cursor + 0] == 0x43 and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 3] == 0x01 or messageBytes[cursor + 3] ==
                    0x00) then
                    keyP["gentle_wind_sense"] = 0x01
                    keyP["fa_prevent_straight_wind"] = 0x01
                    keyP["analysis_value"] =
                        keyP["analysis_value"] ..
                            "gentle_wind_sense,fa_prevent_straight_wind,"
                end
                if (messageBytes[cursor + 3] == 0x02) then
                    keyP["gentle_wind_sense"] = 0x01
                    keyP["fa_prevent_straight_wind"] = 0x02
                    keyP["analysis_value"] =
                        keyP["analysis_value"] ..
                            "gentle_wind_sense,fa_prevent_straight_wind,"
                end
                if (messageBytes[cursor + 3] == 0x03) then
                    keyP["gentle_wind_sense"] = 0x03
                    keyP["analysis_value"] =
                        keyP["analysis_value"] .. "gentle_wind_sense,"
                end
                if (messageBytes[cursor + 3] == 0x04) then
                    keyP["gentle_wind_sense"] = 0x01
                    keyP["analysis_value"] =
                        keyP["analysis_value"] .. "gentle_wind_sense,"
                end
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x30 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["nobody_energy_save"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "nobody_energy_save,"
                cursor = cursor + 9
            end
            if (messageBytes[cursor + 0] == 0x09 and messageBytes[cursor + 1] ==
                0x04) then
                keyP["filter_level"] = messageBytes[cursor + 4]
                keyP["filter_value"] = messageBytes[cursor + 13]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "filter_level,filter_value,"
                cursor = cursor + 16
            end
            if (messageBytes[cursor + 0] == 0x58 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["prevent_straight_wind_lr"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "prevent_straight_wind_lr,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x0B and messageBytes[cursor + 1] ==
                0x02) then
                keyP["pm25_value"] = messageBytes[cursor + 5] * 256 +
                                         messageBytes[cursor + 4]
                keyP["analysis_value"] = keyP["analysis_value"] .. "pm25_value,"
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x50 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["water_pump"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "water_pump,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x31 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["intelligent_control"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "intelligent_control,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x24 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["volume_control"] = messageBytes[cursor + 4]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "volume_control,"
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x09 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_swing_ud_angle"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "wind_swing_ud_angle,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x0A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_swing_lr_angle"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "wind_swing_lr_angle,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x44 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["face_register"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "face_register,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x5A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["degerming"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "degerming,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x5B and messageBytes[cursor + 1] ==
                0x00) then
                keyP["light"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "light,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x61 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_top"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "wind_top,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x59 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_around"] = messageBytes[cursor + 3]
                keyP["wind_around_ud"] = messageBytes[cursor + 4]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "wind_around,wind_around_ud,"
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x1A and messageBytes[cursor + 1] ==
                0x00) then cursor = cursor + 4 end
            if (messageBytes[cursor + 0] == 0x25 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["cool_temp_down"] = messageBytes[cursor + 3]
                keyP["cool_temp_up"] = messageBytes[cursor + 4]
                keyP["auto_temp_down"] = messageBytes[cursor + 5]
                keyP["auto_temp_up"] = messageBytes[cursor + 6]
                keyP["heat_temp_down"] = messageBytes[cursor + 7]
                keyP["heat_temp_up"] = messageBytes[cursor + 8]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "cool_temp_down,cool_temp_up,auto_temp_down,auto_temp_up,heat_temp_down,heat_temp_up,"
                cursor = cursor + 10
            end
            if (messageBytes[cursor + 0] == 0x79 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_swing_ud_angle_up"] = messageBytes[cursor + 3]
                keyP["wind_swing_ud_angle_down"] = messageBytes[cursor + 4]
                keyP["app_control_remember_ud"] = messageBytes[cursor + 5]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "wind_swing_ud_angle_up,wind_swing_ud_angle_down,app_control_remember_ud,"
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x7A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_swing_lr_angle_up"] = messageBytes[cursor + 3]
                keyP["wind_swing_lr_angle_down"] = messageBytes[cursor + 4]
                keyP["app_control_remember_lr"] = messageBytes[cursor + 5]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "wind_swing_lr_angle_up,wind_swing_lr_angle_down,app_control_remember_lr,"
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x78 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["auto_prevent_cold_wind"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "auto_prevent_cold_wind,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x27 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["power_lock"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "power_lock,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x29 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["ptc_lock"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "ptc_lock,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x2B and messageBytes[cursor + 1] ==
                0x02) then
                keyP["offline_operating_time"] = bit.bor(bit.lshift(
                                                             messageBytes[cursor +
                                                                 4], 8),
                                                         messageBytes[cursor + 3])
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "offline_operating_time,"
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x28 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["operating_time"] =
                    bit.bor(messageBytes[cursor + 3],
                            bit.bor(bit.lshift(messageBytes[cursor + 4], 8),
                                    bit.lshift(messageBytes[cursor + 5], 16)))
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "operating_time,"
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x15 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["indoor_humidity"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "indoor_humidity,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x5C and messageBytes[cursor + 1] ==
                0x00) then
                keyP["child_lock"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "child_lock,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x2C and messageBytes[cursor + 1] ==
                0x02) then
                keyP["buzzer_all"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "buzzer_all,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x5D and messageBytes[cursor + 1] ==
                0x00) then
                keyP["self_remove_odor_phase"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "self_remove_odor_phase,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x5E and messageBytes[cursor + 1] ==
                0x00) then
                keyP["high_temp_remove_odor_alone"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "high_temp_remove_odor_alone,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x5F and messageBytes[cursor + 1] ==
                0x00) then
                keyP["ozone"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "ozone,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x63 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["soft_warm"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "soft_warm,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x50 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["fresh_air_parm"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "fresh_air_parm,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x68 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["rewarming_dry"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "rewarming_dry,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x69 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["arom"] = messageBytes[cursor + 3]
                keyP["arom_fan_speed"] = messageBytes[cursor + 4]
                keyP["arom_time_clean"] = messageBytes[cursor + 5]
                keyP["arom_time"] = bit.bor(
                                        bit.lshift(messageBytes[cursor + 7], 8),
                                        messageBytes[cursor + 6])
                keyP["arom_time_total"] = bit.bor(bit.lshift(
                                                      messageBytes[cursor + 9],
                                                      8),
                                                  messageBytes[cursor + 8])
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "arom,arom_fan_speed,arom_time_clean,arom_time,arom_time_total,"
                cursor = cursor + 10
            end
            if (messageBytes[cursor + 0] == 0x30 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["main_horizontal_guide_strip_1"] = messageBytes[cursor + 3]
                keyP["main_horizontal_guide_strip_2"] = messageBytes[cursor + 4]
                keyP["main_horizontal_guide_strip_3"] = messageBytes[cursor + 5]
                keyP["main_horizontal_guide_strip_4"] = messageBytes[cursor + 6]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "main_horizontal_guide_strip_1,main_horizontal_guide_strip_2,main_horizontal_guide_strip_3,main_horizontal_guide_strip_4,"
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x6F and messageBytes[cursor + 1] ==
                0x00) then
                keyP["uvc_remove_odor"] = messageBytes[cursor + 3]
                keyP["uvc_power_off"] = messageBytes[cursor + 4]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "uvc_remove_odor,uvc_power_off,"
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x08 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["light_sensitive"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "light_sensitive,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x54 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["prepare_food"] = messageBytes[cursor + 3]
                keyP["prepare_food_temp"] = messageBytes[cursor + 3]
                keyP["prepare_food_fan_speed"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "prepare_food,prepare_food_temp,prepare_food_fan_speed,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x55 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["quick_fry"] = messageBytes[cursor + 3]
                keyP["quick_fry_temp"] = messageBytes[cursor + 4]
                keyP["quick_fry_fan_speed"] = messageBytes[cursor + 5]
                keyP["analysis_value"] =
                    keyP["analysis_value"] ..
                        "quick_fry,quick_fry_temp,quick_fry_fan_speed,"
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x89 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["cool_power_saving"] = messageBytes[cursor + 3]
                keyP["analysis_value"] =
                    keyP["analysis_value"] .. "cool_power_saving,"
                cursor = cursor + 4
            end
            if (messageBytes[cursor + 0] == 0x67 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["jet_cool"] = messageBytes[cursor + 3]
                keyP["analysis_value"] = keyP["analysis_value"] .. "jet_cool,"
                cursor = cursor + 4
            end
        end
        if (#keyP["analysis_value"] > 1) then
            keyP["analysis_value"] = string.sub(keyP["analysis_value"], 1, -2)
        end
    end
    if ((dataType == 0x02 and messageBytes[0] == 0xB0) or
        (dataType == 0x03 and messageBytes[0] == 0xB1)) then
        if (#binData < 8) then return nil end
        keyP["propertyNumber"] = messageBytes[1]
        local cursor = 2
        for i = 1, keyP["propertyNumber"] do
            if (messageBytes[cursor + 0] == 0x49 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["prevent_super_cool"] = messageBytes[cursor + 4]
                cursor = cursor + 9
            end
            if (messageBytes[cursor + 0] == 0x42 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["prevent_straight_wind"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x26 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["auto_prevent_straight_wind"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x39 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["self_clean"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x32 and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 4] == 0x01) then
                    keyP["wind_straight"] = 0x01
                end
                if (messageBytes[cursor + 4] == 0x02) then
                    keyP["wind_avoid"] = 0x01
                    keyP["yb_wind_avoid"] = 0x02
                end
                if (messageBytes[cursor + 4] == 0x00) then
                    keyP["wind_straight"] = 0x00
                    keyP["wind_avoid"] = 0x00
                    keyP["yb_wind_avoid"] = 0x00
                end
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x33 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_avoid"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x34 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["intelligent_wind"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x3A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["child_prevent_cold_wind"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x18 and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_no_wind_sense"] = 0
                else
                    keyP["has_no_wind_sense"] = 1
                end
                if (messageBytes[cursor + 3] == 0x02) then
                    keyP["fn_no_wind_sense"] = messageBytes[cursor + 4]
                    keyP["no_wind_sense_level"] = messageBytes[cursor + 5]
                    cursor = cursor + 6
                else
                    keyP["no_wind_sense"] = messageBytes[cursor + 4]
                    cursor = cursor + 5
                end
            end
            if (messageBytes[cursor + 0] == 0x1B and messageBytes[cursor + 1] ==
                0x02) then
                keyP["little_angel"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x21 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["cool_hot_sense"] = messageBytes[cursor + 4]
                cursor = cursor + 12
            end
            if (messageBytes[cursor + 0] == 0x29 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["security"] = messageBytes[cursor + 4]
                if (messageBytes[cursor + 4] == 2) then
                    keyP["security"] = 0
                end
                if (messageBytes[cursor + 4] == 3) then
                    keyP["security"] = 1
                end
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x4E and messageBytes[cursor + 1] ==
                0x00) then
                keyP["even_wind"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x4F and messageBytes[cursor + 1] ==
                0x00) then
                keyP["single_tuyere"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x4C and messageBytes[cursor + 1] ==
                0x00) then
                keyP["extreme_wind"] = messageBytes[cursor + 4]
                keyP["extreme_wind_level"] = messageBytes[cursor + 5]
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x20 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["voice_control"] = messageBytes[cursor + 4]
                keyP["voice_control_new"] = messageBytes[cursor + 4]
                cursor = cursor + 24
            end
            if (messageBytes[cursor + 0] == 0x01 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["pre_cool_hot"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x4A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["water_washing_manual"] = messageBytes[cursor + 4]
                keyP["water_washing"] = messageBytes[cursor + 5]
                keyP["water_washing_time"] = messageBytes[cursor + 6]
                keyP["water_washing_stage"] = messageBytes[cursor + 7]
                cursor = cursor + 8
            end
            if (messageBytes[cursor + 0] == 0x4B and messageBytes[cursor + 1] ==
                0x00) then
                keyP["fresh_air"] = messageBytes[cursor + 4]
                keyP["fresh_air_fan_speed"] = messageBytes[cursor + 5]
                keyP["fresh_air_temp"] = messageBytes[cursor + 6]
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x51 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["parent_control"] = messageBytes[cursor + 4]
                keyP["parent_control_temp_up"] = messageBytes[cursor + 5]
                keyP["parent_control_temp_down"] = messageBytes[cursor + 6]
                cursor = cursor + 9
            end
            if (messageBytes[cursor + 0] == 0x43 and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 4] == 0x01 or messageBytes[cursor + 4] ==
                    0x00) then
                    keyP["gentle_wind_sense"] = 0x01
                    keyP["fa_prevent_straight_wind"] = 0x01
                end
                if (messageBytes[cursor + 4] == 0x02) then
                    keyP["gentle_wind_sense"] = 0x01
                    keyP["fa_prevent_straight_wind"] = 0x02
                end
                if (messageBytes[cursor + 4] == 0x03) then
                    keyP["gentle_wind_sense"] = 0x03
                end
                if (messageBytes[cursor + 4] == 0x04) then
                    keyP["gentle_wind_sense"] = 0x01
                end
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x30 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["nobody_energy_save"] = messageBytes[cursor + 4]
                cursor = cursor + 10
            end
            if (messageBytes[cursor + 0] == 0x09 and messageBytes[cursor + 1] ==
                0x04) then
                keyP["filter_level"] = messageBytes[cursor + 5]
                keyP["filter_value"] = messageBytes[cursor + 14]
                cursor = cursor + 17
            end
            if (messageBytes[cursor + 0] == 0x58 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["prevent_straight_wind_lr"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x0B and messageBytes[cursor + 1] ==
                0x02) then
                keyP["pm25_value"] = messageBytes[cursor + 6] * 256 +
                                         messageBytes[cursor + 5]
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x50 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["water_pump"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x31 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["intelligent_control"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x24 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["volume_control"] = messageBytes[cursor + 5]
                cursor = cursor + 8
            end
            if (messageBytes[cursor + 0] == 0x09 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_swing_ud_angle"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x0A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_swing_lr_angle"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x44 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["face_register"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x5A and messageBytes[cursor + 1] ==
                0x00) then
                keyP["degerming"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x5B and messageBytes[cursor + 1] ==
                0x00) then
                keyP["light"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x61 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_top"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x59 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["wind_around"] = messageBytes[cursor + 4]
                keyP["wind_around_ud"] = messageBytes[cursor + 5]
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x1A and messageBytes[cursor + 1] ==
                0x00) then cursor = cursor + 5 end
            if (messageBytes[cursor + 0] == 0x79 and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_wind_swing_ud_angle_diy"] = 0
                    cursor = cursor + 4
                else
                    keyP["has_wind_swing_ud_angle_diy"] = 1
                    keyP["wind_swing_ud_angle_up"] = messageBytes[cursor + 4]
                    keyP["wind_swing_ud_angle_down"] = messageBytes[cursor + 5]
                    keyP["app_control_remember_ud"] = messageBytes[cursor + 6]
                    cursor = cursor + 7
                end
            end
            if (messageBytes[cursor + 0] == 0x7A and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_wind_swing_lr_angle_diy"] = 0
                    cursor = cursor + 4
                else
                    keyP["has_wind_swing_lr_angle_diy"] = 1
                    keyP["wind_swing_lr_angle_up"] = messageBytes[cursor + 4]
                    keyP["wind_swing_lr_angle_down"] = messageBytes[cursor + 5]
                    keyP["app_control_remember_lr"] = messageBytes[cursor + 6]
                    cursor = cursor + 7
                end
            end
            if (messageBytes[cursor + 0] == 0x78 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["auto_prevent_cold_wind"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x25 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["cool_temp_down"] = messageBytes[cursor + 4]
                keyP["cool_temp_up"] = messageBytes[cursor + 5]
                keyP["auto_temp_down"] = messageBytes[cursor + 6]
                keyP["auto_temp_up"] = messageBytes[cursor + 7]
                keyP["heat_temp_down"] = messageBytes[cursor + 8]
                keyP["heat_temp_up"] = messageBytes[cursor + 9]
                cursor = cursor + 11
            end
            if (messageBytes[cursor + 0] == 0x27 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["power_lock"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x29 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["ptc_lock"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x2B and messageBytes[cursor + 1] ==
                0x02) then
                keyP["offline_operating_time"] = bit.bor(bit.lshift(
                                                             messageBytes[cursor +
                                                                 5], 8),
                                                         messageBytes[cursor + 4])
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x28 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["operating_time"] =
                    bit.bor(messageBytes[cursor + 4],
                            bit.bor(bit.lshift(messageBytes[cursor + 5], 8),
                                    bit.lshift(messageBytes[cursor + 6], 16)))
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x15 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["indoor_humidity"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x5C and messageBytes[cursor + 1] ==
                0x00) then
                keyP["child_lock"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x2C and messageBytes[cursor + 1] ==
                0x02) then
                keyP["buzzer_all"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x5D and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_self_remove_odor_phase"] = 0
                    cursor = cursor + 4
                else
                    keyP["has_self_remove_odor_phase"] = 1
                    keyP["self_remove_odor_phase"] = messageBytes[cursor + 4]
                    cursor = cursor + 5
                end
            end
            if (messageBytes[cursor + 0] == 0x5E and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_high_temp_remove_odor_alone"] = 0
                    cursor = cursor + 4
                else
                    keyP["has_high_temp_remove_odor_alone"] = 1
                    keyP["high_temp_remove_odor_alone"] =
                        messageBytes[cursor + 4]
                    cursor = cursor + 5
                end
            end
            if (messageBytes[cursor + 0] == 0x5F and messageBytes[cursor + 1] ==
                0x00) then
                keyP["ozone"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x63 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["soft_warm"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x50 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["fresh_air_parm"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x68 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["rewarming_dry"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x69 and messageBytes[cursor + 1] ==
                0x00) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_arom"] = 0
                    cursor = cursor + 4
                else
                    keyP["has_arom"] = 1
                    keyP["arom"] = messageBytes[cursor + 4]
                    keyP["arom_fan_speed"] = messageBytes[cursor + 5]
                    keyP["arom_time_clean"] = messageBytes[cursor + 6]
                    keyP["arom_time"] = bit.bor(bit.lshift(
                                                    messageBytes[cursor + 8], 8),
                                                messageBytes[cursor + 7])
                    keyP["arom_time_total"] = bit.bor(bit.lshift(
                                                          messageBytes[cursor +
                                                              10], 8),
                                                      messageBytes[cursor + 9])
                    cursor = cursor + 11
                end
            end
            if (messageBytes[cursor + 0] == 0x01 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["new_mode_power"] = messageBytes[cursor + 4]
                keyP["new_mode"] = messageBytes[cursor + 5]
                keyP["new_temperature"] = messageBytes[cursor + 6] / 2
                keyP["new_wind_speed"] = messageBytes[cursor + 7]
                cursor = cursor + 8
            end
            if (messageBytes[cursor + 0] == 0x30 and messageBytes[cursor + 1] ==
                0x02) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_guide_strip"] = 0
                    cursor = cursor + 4
                else
                    keyP["has_guide_strip"] = 1
                    keyP["main_horizontal_guide_strip_1"] =
                        messageBytes[cursor + 4]
                    keyP["main_horizontal_guide_strip_2"] =
                        messageBytes[cursor + 5]
                    keyP["main_horizontal_guide_strip_3"] =
                        messageBytes[cursor + 6]
                    keyP["main_horizontal_guide_strip_4"] =
                        messageBytes[cursor + 7]
                    cursor = cursor + 8
                end
            end
            if (messageBytes[cursor + 0] == 0x6F and messageBytes[cursor + 1] ==
                0x00) then
                keyP["uvc_remove_odor"] = messageBytes[cursor + 4]
                keyP["uvc_power_off"] = messageBytes[cursor + 5]
                cursor = cursor + 6
            end
            if (messageBytes[cursor + 0] == 0x54 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["prepare_food"] = messageBytes[cursor + 4]
                keyP["prepare_food_temp"] = messageBytes[cursor + 5]
                keyP["prepare_food_fan_speed"] = messageBytes[cursor + 6]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x55 and messageBytes[cursor + 1] ==
                0x02) then
                keyP["quick_fry"] = messageBytes[cursor + 4]
                keyP["quick_fry_temp"] = messageBytes[cursor + 5]
                keyP["quick_fry_fan_speed"] = messageBytes[cursor + 6]
                cursor = cursor + 7
            end
            if (messageBytes[cursor + 0] == 0x89 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["cool_power_saving"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x67 and messageBytes[cursor + 1] ==
                0x00) then
                keyP["jet_cool"] = messageBytes[cursor + 4]
                cursor = cursor + 5
            end
            if (messageBytes[cursor + 0] == 0x08 and messageBytes[cursor + 1] ==
                0x02) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_light_sensitive"] = 0
                    cursor = cursor + 4
                else
                    keyP["has_light_sensitive"] = 1
                    keyP["light_sensitive"] = messageBytes[cursor + 4]
                    cursor = cursor + 5
                end
            end
            if (messageBytes[cursor + 0] == 0x11 and messageBytes[cursor + 1] ==
                0x02) then
                if (messageBytes[cursor + 2] == 0x11 or messageBytes[cursor + 2] ==
                    0x10 or messageBytes[cursor + 3] == 0x00) then
                    keyP["has_ptc_default_rule"] = 0
                    cursor = cursor + 4
                else
                    keyP["has_ptc_default_rule"] = 1
                    keyP["ptc_default_rule"] = messageBytes[cursor + 4]
                    cursor = cursor + 5
                end
            end
        end
    end
end
local function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + keyB["BYTE_PROTOCOL_LENGTH"] + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = keyB["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = bodyLength + keyB["BYTE_PROTOCOL_LENGTH"] + 1
    msgBytes[2] = keyB["BYTE_DEVICE_TYPE"]
    if (keyP["propertyNumber"] > 0) then msgBytes[8] = 0x02 end
    msgBytes[9] = cType
    for i = 0, bodyLength do
        msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]] = bodyData[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
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
            math.randomseed(tostring(os.time() * #bodyBytes):reverse():sub(1, 7))
            math.random()
            bodyBytes[20] = math.random(1, 254)
            bodyBytes[21] = crc8_854(bodyBytes, 0, 20)
            infoM = getTotalMsg(bodyBytes, keyB["BYTE_QUERYL_REQUEST"])
        elseif (queryType == "power" or queryType == "purifier" or queryType ==
            "mode" or queryType == "temperature" or queryType ==
            "small_temperature" or queryType == "buzzer" or queryType ==
            "wind_swing_lr" or queryType == "wind_swing_lr_under" or queryType ==
            "wind_swing_ud" or queryType == "wind_speed" or queryType ==
            "power_on_timer" or queryType == "power_off_timer" or queryType ==
            "power_on_time_value" or queryType == "power_off_time_value" or
            queryType == "indoor_temperature" or queryType ==
            "outdoor_temperature" or queryType == "eco" or queryType ==
            "kick_quilt" or queryType == "prevent_cold" or queryType == "dry" or
            queryType == "ptc" or queryType == "screen_display" or queryType ==
            "screen_display_now" or queryType == "strong_wind" or queryType ==
            "current_work_time" or queryType == "comfort_power_save" or
            queryType == "comfort_sleep" or queryType == "natural_wind" or
            queryType == "power_saving" or queryType ==
            "fresh_filter_time_total" or queryType == "fresh_filter_time_use" or
            queryType == "fresh_filter_timeout") then
            for i = 0, 21 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0x41
            bodyBytes[1] = 0x81
            bodyBytes[3] = 0xFF
            math.randomseed(tostring(os.time() * #bodyBytes):reverse():sub(1, 7))
            math.random()
            bodyBytes[20] = math.random(1, 254)
            bodyBytes[21] = crc8_854(bodyBytes, 0, 20)
            infoM = getTotalMsg(bodyBytes, keyB["BYTE_QUERYL_REQUEST"])
        elseif (queryType == "group_data_zero" or queryType == "group_data_four" or
            queryType == "group_data_one") then
            for i = 0, 21 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0x41
            bodyBytes[1] = 0x21
            bodyBytes[2] = 0x01
            if (queryType == "group_data_zero") then
                bodyBytes[3] = 0x40
            end
            if (queryType == "group_data_four") then
                bodyBytes[3] = 0x44
            end
            if (queryType == "group_data_four") then
                bodyBytes[3] = 0x41
            end
            math.randomseed(tostring(os.time() * #bodyBytes):reverse():sub(1, 7))
            math.random()
            bodyBytes[20] = math.random(1, 254)
            bodyBytes[21] = crc8_854(bodyBytes, 0, 20)
            infoM = getTotalMsg(bodyBytes, keyB["BYTE_QUERYL_REQUEST"])
        else
            bodyBytes[0] = 0xB1
            local propertyNum = 0
            local queryList = {}
            if (string.match(queryType, ",") == ",") then
                queryList = splitStrByChar(queryType, ",")
            else
                table.insert(queryList, queryType)
            end
            for v in values(queryList) do
                queryType = v
                if (queryType == "no_wind_sense") then
                    if (deviceSN8 == "12035" or deviceSN8 == "12037" or
                        deviceSN8 == "Z1312" or deviceSN8 == "Z1262" or
                        deviceSN8 == "12179" or deviceSN8 == "Z1261") then
                        bodyBytes[1 + propertyNum * 2 + 1] = 0x43
                    else
                        bodyBytes[1 + propertyNum * 2 + 1] = 0x18
                    end
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "fn_no_wind_sense") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x18
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "cool_hot_sense") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x21
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "ptc_default_rule") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x11
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "nobody_energy_save") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x30
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "self_clean") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x39
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "child_prevent_cold_wind") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x3A
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
                if (queryType == "prevent_straight_wind") then
                    if (deviceSN8 == "12035" or deviceSN8 == "12037" or
                        deviceSN8 == "Z1312" or deviceSN8 == "Z1262" or
                        deviceSN8 == "12179" or deviceSN8 == "Z1261") then
                        bodyBytes[1 + propertyNum * 2 + 1] = 0x43
                    else
                        bodyBytes[1 + propertyNum * 2 + 1] = 0x42
                    end
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "gentle_wind_sense") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x43
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "fa_prevent_straight_wind") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x43
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "prevent_super_cool") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x49
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
                if (queryType == "intelligent_wind") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x34
                    if (deviceSN8 == "50939" or deviceSN8 == "51001" or
                        deviceSN8 == "Z1304" or deviceSN8 == "Z1259" or
                        deviceSN8 == "Z2272") then
                        bodyBytes[1 + propertyNum * 2 + 1] = 0x33
                    end
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "wind_straight" or queryType == "yb_wind_avoid") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x32
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "wind_avoid") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x33
                    if (deviceSN8 == "50939" or deviceSN8 == "51001" or
                        deviceSN8 == "Z1304" or deviceSN8 == "Z1259" or
                        deviceSN8 == "Z2272") then
                        bodyBytes[1 + propertyNum * 2 + 1] = 0x32
                    end
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "auto_prevent_straight_wind") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x26
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "security") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x29
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "even_wind") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x4E
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "single_tuyere") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x4F
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "extreme_wind") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x4C
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "voice_control") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x20
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "pre_cool_hot") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x01
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "water_washing") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x4A
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "fresh_air") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x4B
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "parent_control") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x51
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "filter_value") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x09
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x04
                    propertyNum = propertyNum + 1
                end
                if (queryType == "wind_swing_ud_angle") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x09
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "wind_swing_lr_angle") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x0A
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "prevent_straight_wind_lr") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x58
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "pm25_value") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x0B
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "water_pump") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x50
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "intelligent_control") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x31
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "volume_control") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x24
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "voice_control_new") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x20
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "face_register") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x44
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "cool_temp_down" or queryType == "cool_temp_up" or
                    queryType == "auto_temp_down" or queryType == "auto_temp_up" or
                    queryType == "heat_temp_down" or queryType == "heat_temp_up") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x25
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "wind_swing_ud_angle_up" or queryType ==
                    "wind_swing_ud_angle_down" or queryType ==
                    "app_control_remember_ud") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x79
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "wind_swing_lr_angle_up" or queryType ==
                    "wind_swing_lr_angle_down" or queryType ==
                    "app_control_remember_lr") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x7A
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "auto_prevent_cold_wind") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x78
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "remote_control_lock") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x27
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "operating_time") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x28
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "indoor_humidity") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x15
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "degerming") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x5A
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "light") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x5B
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "wind_around") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x59
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "wind_top") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x61
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "child_lock") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x5C
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "buzzer_all") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x2C
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "self_remove_odor_phase") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x5D
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "high_temp_remove_odor_alone") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x5E
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "power_lock") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x27
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "ptc_lock") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x29
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "offline_operating_time") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x2B
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "ozone") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x5F
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "soft_warm") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x63
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "fresh_air_parm") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x50
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "rewarming_dry") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x68
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "arom") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x69
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "new_mode_power") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x01
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "uvc_remove_odor") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x6F
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "light_sensitive") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x08
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "main_horizontal_guide_strip_1" or queryType ==
                    "main_horizontal_guide_strip_2" or queryType ==
                    "main_horizontal_guide_strip_3" or queryType ==
                    "main_horizontal_guide_strip_4") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x30
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "prepare_food") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x54
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "quick_fry") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x55
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x02
                    propertyNum = propertyNum + 1
                end
                if (queryType == "cool_power_saving") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x89
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
                if (queryType == "jet_cool") then
                    bodyBytes[1 + propertyNum * 2 + 1] = 0x67
                    bodyBytes[1 + propertyNum * 2 + 2] = 0x00
                    propertyNum = propertyNum + 1
                end
            end
            bodyBytes[1] = propertyNum
            math.randomseed(tostring(os.time() * #bodyBytes):reverse():sub(1, 7))
            math.random()
            bodyBytes[1 + propertyNum * 2 + 1] = math.random(1, 254)
            bodyBytes[1 + propertyNum * 2 + 2] =
                crc8_854(bodyBytes, 0, 1 + propertyNum * 2 + 1)
            infoM = getTotalMsg(bodyBytes, keyB["BYTE_QUERYL_REQUEST"])
        end
    elseif (control) then
        if (status) then jsonToModel(status, "status") end
        if (control) then
            if (control[keyT["KEY_SCREEN_DISPLAY"]] ~= nil) then
                for i = 0, 24 do bodyBytes[i] = 0 end
                bodyBytes[0] = 0x41
                bodyBytes[1] = 0xC1
                if (control[keyT["KEY_BUZZER"]] ~= nil and
                    control[keyT["KEY_BUZZER"]] == "off") then
                    bodyBytes[1] = 0x81
                end
                bodyBytes[3] = 0xFF
                bodyBytes[4] = 0x02
                bodyBytes[5] = 0xFF
                bodyBytes[6] = 0x02
                bodyBytes[7] = 0x02
                math.randomseed(tostring(os.time() * #bodyBytes):reverse():sub(
                                    1, 7))
                math.random()
                bodyBytes[23] = math.random(1, 254)
                bodyBytes[24] = crc8_854(bodyBytes, 0, 23)
                infoM = getTotalMsg(bodyBytes, keyB["BYTE_QUERYL_REQUEST"])
                local ret = table2string(infoM)
                ret = string2hexstring(ret)
                return ret
            end
            if (control["ilinkId"] ~= nil and control["ticket"] ~= nil) then
                local short_length = 4 + #control["ilinkId"] +
                                         #control["ticket"]
                local length = short_length + 12
                local count = 0
                for i = 0, length + 1 do bodyBytes[i] = 0 end
                bodyBytes[0] = 0xAA
                bodyBytes[1] = length
                bodyBytes[2] = 0xAC
                bodyBytes[3] = 0x00
                bodyBytes[8] = 0x02
                bodyBytes[9] = 0x91
                bodyBytes[10] = 0xAC
                bodyBytes[11] = 0x0B
                bodyBytes[12] = short_length
                bodyBytes[14] = #control["ilinkId"]
                bodyBytes[15] = #control["ticket"]
                for i = 0, #control["ilinkId"] - 1 do
                    bodyBytes[16 + i] = string.byte(string.sub(
                                                        control["ilinkId"],
                                                        i + 1, i + 1))
                    count = count + 1
                end
                for i = 0, #control["ticket"] - 1 do
                    bodyBytes[16 + count + i] =
                        string.byte(string.sub(control["ticket"], i + 1, i + 1))
                end
                bodyBytes[length] = makeSum(bodyBytes, 1, length - 1)
                local ret = table2string2(bodyBytes)
                ret = string2hexstring(ret)
                return ret
            end
            jsonToModel(control, "control")
        end
        if (keyP["propertyNumber"] == 0) then
            for i = 0, 25 do bodyBytes[i] = 0 end
            setDefaultValue()
            bodyBytes[0] = keyB["BYTE_CONTROL_CMD"]
            bodyBytes[1] = bit.bor(bit.bor(keyP["powerValue"],
                                           keyB["BYTE_CLIENT_MODE_MOBILE"]),
                                   bit.bor(keyB["BYTE_TIMER_METHOD_REL"],
                                           keyP["buzzerValue"]))
            bodyBytes[2] = bit.bor(bit.bor(bit.band(keyP["modeValue"], 0xE0),
                                           bit.band(0x0F, (keyP["temperature"] -
                                                        0x10))), bit.lshift(
                                       bit.band(keyP["smallTemperature"], 0x01),
                                       4))
            bodyBytes[3] = keyP["fanspeedValue"]
            if (keyP["timerSignal"] == 1) then
                bodyBytes[3] = bit.bor(bodyBytes[3],
                                       keyB["BYTE_TIMER_SWITCH_ON"])
            end
            if (keyP["closeTime"] == nil) then keyP["closeTime"] = 0 end
            keyP["closeHour"] = math.floor(keyP["closeTime"] / 60)
            keyP["closeStepMintues"] = math.floor((keyP["closeTime"] % 60) / 15)
            keyP["closeMin"] = math.floor(((keyP["closeTime"] % 60) % 15))
            if (keyP["openTime"] == nil) then keyP["openTime"] = 0 end
            keyP["openHour"] = math.floor(keyP["openTime"] / 60)
            keyP["openStepMintues"] = math.floor((keyP["openTime"] % 60) / 15)
            keyP["openMin"] = math.floor(((keyP["openTime"] % 60) % 15))
            if (keyP["openTimerSwitch"] == keyB["BYTE_START_TIMER_SWITCH_ON"]) then
                bodyBytes[4] = bit.bor(bit.bor(keyP["openTimerSwitch"],
                                               bit.lshift(keyP["openHour"], 2)),
                                       keyP["openStepMintues"])
            elseif (keyP["openTimerSwitch"] ==
                keyB["BYTE_START_TIMER_SWITCH_OFF"]) then
                bodyBytes[4] = 0x7F
            end
            if (keyP["closeTimerSwitch"] == keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
                bodyBytes[5] = bit.bor(bit.bor(keyP["closeTimerSwitch"],
                                               bit.lshift(keyP["closeHour"], 2)),
                                       keyP["closeStepMintues"])
            elseif (keyP["closeTimerSwitch"] ==
                keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
                bodyBytes[5] = 0x7F
            end
            bodyBytes[6] = bit.bor(bit.lshift((15 - keyP["openMin"]), 4),
                                   (15 - keyP["closeMin"]))
            bodyBytes[7] = bit.bor(bit.bor(keyP["swingLRValue"],
                                           keyP["swingUDValue"]), 0x30)
            bodyBytes[8] = bit.bor(bit.bor(keyP["strongWindValue"],
                                           keyP["comfortableSleepValue"]),
                                   keyP["power_saving"])
            bodyBytes[9] = bit.bor(bit.bor(
                                       bit.bor(keyP["purifierValue"],
                                               keyP["ecoValue"]), bit.bor(
                                           keyP["dryValue"], keyP["PTCValue"])),
                                   keyP["comfortableSleepSwitch"])
            if ((keyP["PTCForceValue"] ~= nil) and (keyP["PTCForceValue"] == 1)) then
                bodyBytes[9] = bit.bor(bodyBytes[9], 0x10)
            end
            bodyBytes[10] = bit.lshift(bit.band(keyP["preventCold"], 0x01), 3)
            if (keyP["fresh_filter_reset"] ~= nil) then
                bodyBytes[10] = bit.bor(keyP["fresh_filter_reset"],
                                        bodyBytes[10])
            end
            if (keyP["comfortableSleepValue"] == keyB["BYTE_SLEEP_ON"] and
                comfortByte == nil) then
                if (keyP["modeValue"] == keyB["BYTE_MODE_HEAT"]) then
                    firstHourTemp = checkBoundary(keyP["temperature"] - 1, 17,
                                                  30)
                    otherHourTemp = checkBoundary(keyP["temperature"] - 2, 17,
                                                  30)
                else
                    firstHourTemp = checkBoundary(keyP["temperature"] + 1, 17,
                                                  30)
                    otherHourTemp = checkBoundary(keyP["temperature"] + 2, 17,
                                                  30)
                end
                bodyBytes[11] = bit.bor(firstHourTemp - 17,
                                        bit.lshift((otherHourTemp - 17), 4))
                bodyBytes[12] = bit.bor(otherHourTemp - 17,
                                        bit.lshift((otherHourTemp - 17), 4))
                bodyBytes[13] = bit.bor(otherHourTemp - 17,
                                        bit.lshift((otherHourTemp - 17), 4))
                bodyBytes[14] = bit.bor(otherHourTemp - 17,
                                        bit.lshift((otherHourTemp - 17), 4))
                bodyBytes[15] = bit.bor(otherHourTemp - 17,
                                        bit.lshift((otherHourTemp - 17), 4))
                if (keyP["smallTemperature"] ~= 0) then
                    bodyBytes[16] = 0xFF
                    bodyBytes[17] = bit.bor(keyP["comfortableSleepTime"], 0x30)
                else
                    bodyBytes[17] = keyP["comfortableSleepTime"]
                end
            elseif (keyP["comfortableSleepValue"] == keyB["BYTE_SLEEP_ON"] and
                comfortByte ~= nil) then
                bodyBytes[11] = bit.bor(checkBoundary(comfortByte[1], 17, 30) -
                                            17, bit.lshift(
                                            (checkBoundary(comfortByte[2], 17,
                                                           30) - 17), 4))
                bodyBytes[12] = bit.bor(checkBoundary(comfortByte[3], 17, 30) -
                                            17, bit.lshift(
                                            (checkBoundary(comfortByte[4], 17,
                                                           30) - 17), 4))
                bodyBytes[13] = bit.bor(checkBoundary(comfortByte[5], 17, 30) -
                                            17,
                                        bit.lshift((comfortByte[6] - 17), 4))
                bodyBytes[14] = bit.bor(checkBoundary(comfortByte[7], 17, 30) -
                                            17,
                                        bit.lshift((comfortByte[8] - 17), 4))
                bodyBytes[15] = bit.bor(checkBoundary(comfortByte[9], 17, 30) -
                                            17,
                                        bit.lshift((comfortByte[10] - 17), 4))
                if (keyP["smallTemperature"] ~= 0) then
                    bodyBytes[16] = 0xFF
                    bodyBytes[17] = bit.bor(keyP["comfortableSleepTime"], 0x30)
                else
                    bodyBytes[17] = keyP["comfortableSleepTime"]
                end
            end
            if (keyP["pmv"] ~= nil) then
                local pmvValue = (keyP["pmv"] + 3.5) * 2
                bodyBytes[17] = bit.bor(bit.lshift(bit.band(pmvValue, 0x08), 4),
                                        bodyBytes[17])
                bodyBytes[18] = bit.bor(bit.lshift(bit.band(pmvValue, 0x07), 5),
                                        bodyBytes[18])
            end
            if (keyP["naturalWind"] ~= nil) then
                bodyBytes[17] = bit.bor(keyP["naturalWind"], bodyBytes[17])
            end
            if (keyP["temperature"] < 17 or keyP["temperature"] > 30) then
                bodyBytes[18] = bit.bor(bit.band(0x1F,
                                                 (keyP["temperature"] - 12)),
                                        bodyBytes[18])
            end
            if (keyP["modeValue"] == keyB["BYTE_MODE_SMART_DRY"] and
                keyP["smartDryValue"] ~= nil) then
                bodyBytes[19] = bit.bor(bit.band(0x7F, keyP["smartDryValue"]),
                                        bodyBytes[19])
            end
            bodyBytes[19] = bit.bor(keyP["swingLRUnderSwitch"], bodyBytes[19])
            bodyBytes[20] = bit.bor(keyP["swingLRValueUnder"], bodyBytes[20])
            if (keyP["comfortPowerSave"] == keyB["BYTE_COMFORT_POWER_SAVE_ON"]) then
                bodyBytes[22] = 0x01
            elseif (keyP["comfortPowerSave"] ==
                keyB["BYTE_COMFORT_POWER_SAVE_OFF"]) then
                bodyBytes[22] = 0x00
            end
            math.randomseed(tostring(os.time() * #bodyBytes):reverse():sub(1, 7))
            math.random()
            bodyBytes[24] = math.random(1, 254)
            bodyBytes[25] = crc8_854(bodyBytes, 0, 24)
        else
            bodyBytes[0] = keyB["BYTE_CONTROL_PROPERTY_CMD"]
            bodyBytes[1] = keyP["propertyNumber"]
            local cursor = 2
            if (keyP["prevent_super_cool"] ~= nil) then
                bodyBytes[cursor + 0] = 0x49
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x05
                bodyBytes[cursor + 3] = keyP["prevent_super_cool"]
                bodyBytes[cursor + 4] = 0xFF
                bodyBytes[cursor + 5] = 0xFF
                bodyBytes[cursor + 6] = 0xFF
                bodyBytes[cursor + 7] = 0xFF
                cursor = cursor + 8
            end
            if (keyP["prevent_straight_wind"] ~= nil) then
                if (deviceSN8 == "12035" or deviceSN8 == "12037" or deviceSN8 ==
                    "Z1312" or deviceSN8 == "Z1262" or deviceSN8 == "12179" or
                    deviceSN8 == "Z1261") then
                    bodyBytes[cursor + 0] = 0x43
                    bodyBytes[cursor + 1] = 0x00
                    bodyBytes[cursor + 2] = 0x01
                    bodyBytes[cursor + 3] = 0x00
                    if (keyP["prevent_straight_wind"] == 2) then
                        bodyBytes[cursor + 3] = 0x02
                    elseif (keyP["prevent_straight_wind"] == 1) then
                        bodyBytes[cursor + 3] = 0x01
                    end
                    cursor = cursor + 4
                else
                    bodyBytes[cursor + 0] = 0x42
                    bodyBytes[cursor + 1] = 0x00
                    bodyBytes[cursor + 2] = 0x01
                    bodyBytes[cursor + 3] = keyP["prevent_straight_wind"]
                    cursor = cursor + 4
                end
            end
            if (keyP["fa_prevent_straight_wind"] ~= nil) then
                bodyBytes[cursor + 0] = 0x43
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = 0x00
                if (keyP["fa_prevent_straight_wind"] == 2) then
                    bodyBytes[cursor + 3] = 0x02
                elseif (keyP["fa_prevent_straight_wind"] == 1) then
                    bodyBytes[cursor + 3] = 0x01
                end
                cursor = cursor + 4
            end
            if (keyP["auto_prevent_straight_wind"] ~= nil) then
                bodyBytes[cursor + 0] = 0x26
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["auto_prevent_straight_wind"]
                cursor = cursor + 4
            end
            if (keyP["ptc_default_rule"] ~= nil) then
                bodyBytes[cursor + 0] = 0x11
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["ptc_default_rule"]
                cursor = cursor + 4
            end
            if (keyP["self_clean"] ~= nil) then
                bodyBytes[cursor + 0] = 0x39
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["self_clean"]
                cursor = cursor + 4
            end
            if (keyP["wind_straight"] ~= nil) then
                bodyBytes[cursor + 0] = 0x32
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["wind_straight"]
                cursor = cursor + 4
            end
            if (keyP["yb_wind_avoid"] ~= nil) then
                bodyBytes[cursor + 0] = 0x32
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["yb_wind_avoid"]
                cursor = cursor + 4
            end
            if (keyP["wind_avoid"] ~= nil) then
                if (deviceSN8 == "50939" or deviceSN8 == "51001" or deviceSN8 ==
                    "Z1304" or deviceSN8 == "Z1259" or deviceSN8 == "Z2272") then
                    bodyBytes[cursor + 0] = 0x32
                    bodyBytes[cursor + 1] = 0x00
                    bodyBytes[cursor + 2] = 0x01
                    if (keyP["wind_avoid"] == 0x01) then
                        bodyBytes[cursor + 3] = 0x02
                    else
                        bodyBytes[cursor + 3] = 0x00
                    end
                    cursor = cursor + 4
                else
                    bodyBytes[cursor + 0] = 0x33
                    bodyBytes[cursor + 1] = 0x00
                    bodyBytes[cursor + 2] = 0x01
                    bodyBytes[cursor + 3] = keyP["wind_avoid"]
                    cursor = cursor + 4
                end
            end
            if (keyP["intelligent_wind"] ~= nil) then
                bodyBytes[cursor + 0] = 0x34
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["intelligent_wind"]
                cursor = cursor + 4
            end
            if (keyP["no_wind_sense"] ~= nil) then
                if (deviceSN8 == "12035" or deviceSN8 == "12037" or deviceSN8 ==
                    "Z1312" or deviceSN8 == "Z1262" or deviceSN8 == "12179" or
                    deviceSN8 == "Z1261") then
                    bodyBytes[cursor + 0] = 0x43
                    bodyBytes[cursor + 1] = 0x00
                    bodyBytes[cursor + 2] = 0x01
                    bodyBytes[cursor + 3] = 0x00
                    if (keyP["no_wind_sense"] == 1) then
                        bodyBytes[cursor + 3] = 0x04
                    elseif (keyP["no_wind_sense"] == 0) then
                        bodyBytes[cursor + 3] = 0x01
                    end
                    cursor = cursor + 4
                elseif (deviceSN8 == "51023") then
                    bodyBytes[cursor + 0] = 0x18
                    bodyBytes[cursor + 1] = 0x00
                    bodyBytes[cursor + 2] = 0x02
                    bodyBytes[cursor + 3] = keyP["no_wind_sense"]
                    bodyBytes[cursor + 4] = keyP["no_wind_sense_level"]
                    cursor = cursor + 5
                else
                    bodyBytes[cursor + 0] = 0x18
                    bodyBytes[cursor + 1] = 0x00
                    bodyBytes[cursor + 2] = 0x01
                    bodyBytes[cursor + 3] = keyP["no_wind_sense"]
                    cursor = cursor + 4
                end
            end
            if (keyP["fn_no_wind_sense"] ~= nil) then
                bodyBytes[cursor + 0] = 0x18
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = keyP["fn_no_wind_sense"]
                if (keyP["no_wind_sense_level"] ~= nil) then
                    bodyBytes[cursor + 4] = keyP["no_wind_sense_level"]
                else
                    bodyBytes[cursor + 4] = 10
                end
                cursor = cursor + 5
            end
            if (keyP["child_prevent_cold_wind"] ~= nil) then
                bodyBytes[cursor + 0] = 0x3A
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["child_prevent_cold_wind"]
                cursor = cursor + 4
            end
            if (keyP["little_angel"] ~= nil) then
                bodyBytes[cursor + 0] = 0x1B
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["little_angel"]
                cursor = cursor + 4
            end
            if (keyP["cool_hot_sense"] ~= nil) then
                bodyBytes[cursor + 0] = 0x21
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x08
                bodyBytes[cursor + 3] = keyP["cool_hot_sense"]
                bodyBytes[cursor + 4] = 0x00
                bodyBytes[cursor + 5] = 0x00
                bodyBytes[cursor + 6] = 0x00
                bodyBytes[cursor + 7] = 0x00
                bodyBytes[cursor + 8] = 0x00
                bodyBytes[cursor + 9] = 0x00
                bodyBytes[cursor + 10] = 0x00
                cursor = cursor + 11
            end
            if (keyP["gentle_wind_sense"] ~= nil) then
                bodyBytes[cursor + 0] = 0x43
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["gentle_wind_sense"]
                cursor = cursor + 4
            end
            if (keyP["even_wind"] ~= nil) then
                bodyBytes[cursor + 0] = 0x4E
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["even_wind"]
                cursor = cursor + 4
            end
            if (keyP["single_tuyere"] ~= nil) then
                bodyBytes[cursor + 0] = 0x4F
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["single_tuyere"]
                cursor = cursor + 4
            end
            if (keyP["extreme_wind"] ~= nil) then
                bodyBytes[cursor + 0] = 0x4C
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = keyP["extreme_wind"]
                bodyBytes[cursor + 4] = 0x01
                cursor = cursor + 5
            end
            if (keyP["security"] ~= nil) then
                bodyBytes[cursor + 0] = 0x29
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["security"]
                cursor = cursor + 4
            end
            if (keyP["voice_control"] ~= nil) then
                bodyBytes[cursor + 0] = 0x20
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x09
                bodyBytes[cursor + 3] = keyP["voice_control"]
                bodyBytes[cursor + 4] = 0xFF
                bodyBytes[cursor + 5] = 0xFF
                bodyBytes[cursor + 6] = 0xFF
                bodyBytes[cursor + 7] = 0xFF
                bodyBytes[cursor + 8] = 0xFF
                bodyBytes[cursor + 9] = 0xFF
                bodyBytes[cursor + 10] = 0xFF
                bodyBytes[cursor + 11] = 0xFF
                cursor = cursor + 12
            end
            if (keyP["pre_cool_hot"] ~= nil) then
                bodyBytes[cursor + 0] = 0x01
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["pre_cool_hot"]
                cursor = cursor + 4
            end
            if (keyP["water_washing"] ~= nil) then
                bodyBytes[cursor + 0] = 0x4A
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x04
                bodyBytes[cursor + 3] = keyP["water_washing_manual"]
                bodyBytes[cursor + 4] = keyP["water_washing"]
                bodyBytes[cursor + 5] = keyP["water_washing_time"]
                bodyBytes[cursor + 6] = 0xFF
                cursor = cursor + 7
            end
            if (keyP["fresh_air"] ~= nil) then
                bodyBytes[cursor + 0] = 0x4B
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["fresh_air"]
                bodyBytes[cursor + 4] = keyP["fresh_air_fan_speed"]
                bodyBytes[cursor + 5] = 0xFF
                cursor = cursor + 6
            end
            if (keyP["parent_control"] ~= nil) then
                bodyBytes[cursor + 0] = 0x51
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x05
                bodyBytes[cursor + 3] = keyP["parent_control"]
                bodyBytes[cursor + 4] = keyP["parent_control_temp_up"]
                bodyBytes[cursor + 5] = keyP["parent_control_temp_down"]
                bodyBytes[cursor + 6] = 0xFF
                bodyBytes[cursor + 7] = 0xFF
                cursor = cursor + 8
            end
            if (keyP["buzzerValue"] ~= nil) then
                bodyBytes[cursor + 0] = 0x1A
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = 0x00
                if (keyP["buzzerValue"] == 0x40) then
                    bodyBytes[cursor + 3] = 0x01
                end
                cursor = cursor + 4
                bodyBytes[1] = keyP["propertyNumber"] + 1
            end
            if (keyP["wind_swing_ud_angle"] ~= nil) then
                bodyBytes[cursor + 0] = 0x09
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["wind_swing_ud_angle"]
                cursor = cursor + 4
            end
            if (keyP["wind_swing_lr_angle"] ~= nil) then
                bodyBytes[cursor + 0] = 0x0A
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["wind_swing_lr_angle"]
                cursor = cursor + 4
            end
            if (keyP["nobody_energy_save"] ~= nil) then
                bodyBytes[cursor + 0] = 0x30
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x06
                bodyBytes[cursor + 3] = keyP["nobody_energy_save"]
                bodyBytes[cursor + 4] = 0x00
                bodyBytes[cursor + 5] = 0x00
                bodyBytes[cursor + 6] = 0x00
                bodyBytes[cursor + 7] = 0x00
                bodyBytes[cursor + 8] = 0x00
                cursor = cursor + 9
                bodyBytes[1] = keyP["propertyNumber"] + 1
            end
            if (keyP["prevent_straight_wind_lr"] ~= nil) then
                bodyBytes[cursor + 0] = 0x58
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["prevent_straight_wind_lr"]
                cursor = cursor + 4
                bodyBytes[1] = keyP["propertyNumber"] + 1
            end
            if (keyP["water_pump"] ~= nil) then
                bodyBytes[cursor + 0] = 0x50
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["water_pump"]
                cursor = cursor + 4
                bodyBytes[1] = keyP["propertyNumber"] + 1
            end
            if (keyP["intelligent_control"] ~= nil) then
                bodyBytes[cursor + 0] = 0x31
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["intelligent_control"]
                cursor = cursor + 4
                bodyBytes[1] = keyP["propertyNumber"] + 1
            end
            if (keyP["volume_control"] ~= nil) then
                bodyBytes[cursor + 0] = 0x24
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x04
                bodyBytes[cursor + 3] = 0x02
                bodyBytes[cursor + 4] = keyP["volume_control"]
                bodyBytes[cursor + 5] = 0xFF
                bodyBytes[cursor + 6] = 0xFF
                cursor = cursor + 7
                bodyBytes[1] = keyP["propertyNumber"] + 1
            end
            if (keyP["voice_control_new"] ~= nil) then
                bodyBytes[cursor + 0] = 0x20
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x14
                bodyBytes[cursor + 3] = keyP["voice_control_new"]
                bodyBytes[cursor + 4] = 0xFF
                bodyBytes[cursor + 5] = 0xFF
                bodyBytes[cursor + 6] = 0xFF
                bodyBytes[cursor + 7] = 0xFF
                bodyBytes[cursor + 8] = 0xFF
                bodyBytes[cursor + 9] = 0xFF
                bodyBytes[cursor + 10] = 0xFF
                bodyBytes[cursor + 11] = 0xFF
                bodyBytes[cursor + 12] = 0xFF
                bodyBytes[cursor + 13] = 0xFF
                bodyBytes[cursor + 14] = 0xFF
                bodyBytes[cursor + 15] = 0xFF
                bodyBytes[cursor + 16] = 0xFF
                bodyBytes[cursor + 17] = 0xFF
                bodyBytes[cursor + 18] = 0xFF
                bodyBytes[cursor + 19] = 0xFF
                bodyBytes[cursor + 20] = 0xFF
                bodyBytes[cursor + 21] = 0xFF
                bodyBytes[cursor + 22] = 0xFF
                cursor = cursor + 23
            end
            if (keyP["wind_swing_ud_angle_switch"] ~= nil) then
                bodyBytes[cursor + 0] = 0x79
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["wind_swing_ud_angle_up"]
                bodyBytes[cursor + 4] = keyP["wind_swing_ud_angle_down"]
                bodyBytes[cursor + 5] = keyP["app_control_remember_ud"]
                cursor = cursor + 6
            end
            if (keyP["wind_swing_lr_angle_switch"] ~= nil) then
                bodyBytes[cursor + 0] = 0x7A
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["wind_swing_lr_angle_up"]
                bodyBytes[cursor + 4] = keyP["wind_swing_lr_angle_down"]
                bodyBytes[cursor + 5] = keyP["app_control_remember_lr"]
                cursor = cursor + 6
            end
            if (keyP["cool_temp_down"] ~= nil or keyP["cool_temp_up"] ~= nil or
                keyP["auto_temp_down"] ~= nil or keyP["auto_temp_up"] ~= nil or
                keyP["heat_temp_down"] ~= nil or keyP["heat_temp_up"] ~= nil) then
                bodyBytes[cursor + 0] = 0x25
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x07
                bodyBytes[cursor + 3] = keyP["cool_temp_down"]
                bodyBytes[cursor + 4] = keyP["cool_temp_up"]
                bodyBytes[cursor + 5] = keyP["auto_temp_down"]
                bodyBytes[cursor + 6] = keyP["auto_temp_up"]
                bodyBytes[cursor + 7] = keyP["heat_temp_down"]
                bodyBytes[cursor + 8] = keyP["heat_temp_up"]
                bodyBytes[cursor + 9] = 0x00
                cursor = cursor + 10
            end
            if (keyP["remote_control_lock"] ~= nil) then
                bodyBytes[cursor + 0] = 0x27
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = keyP["remote_control_lock"]
                bodyBytes[cursor + 4] = keyP["remote_control_lock_control"]
                cursor = cursor + 5
            end
            if (keyP["auto_prevent_cold_wind"] ~= nil) then
                bodyBytes[cursor + 0] = 0x78
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["auto_prevent_cold_wind"]
                cursor = cursor + 4
            end
            if (keyP["operating_time"] ~= nil) then
                bodyBytes[cursor + 0] = 0x28
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = bit.band(keyP["operating_time"], 0xff)
                bodyBytes[cursor + 4] = bit.band(bit.rshift(
                                                     keyP["operating_time"], 8),
                                                 0xff)
                bodyBytes[cursor + 5] = bit.band(bit.rshift(
                                                     keyP["operating_time"], 16),
                                                 0xff)
                cursor = cursor + 6
            end
            if (keyP["degerming"] ~= nil) then
                bodyBytes[cursor + 0] = 0x5A
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["degerming"]
                cursor = cursor + 4
                bodyBytes[1] = keyP["propertyNumber"] + 1
            end
            if (keyP["light"] ~= nil) then
                bodyBytes[cursor + 0] = 0x5B
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["light"]
                cursor = cursor + 4
            end
            if (keyP["wind_top"] ~= nil) then
                bodyBytes[cursor + 0] = 0x61
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["wind_top"]
                cursor = cursor + 4
            end
            if (keyP["child_lock"] ~= nil) then
                bodyBytes[cursor + 0] = 0x5C
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["child_lock"]
                cursor = cursor + 4
            end
            if (keyP["buzzer_all"] ~= nil) then
                bodyBytes[cursor + 0] = 0x2C
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["buzzer_all"]
                cursor = cursor + 4
            end
            if (keyP["wind_around"] ~= nil) then
                bodyBytes[cursor + 0] = 0x59
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = keyP["wind_around"]
                bodyBytes[cursor + 4] = 0
                if (keyP["wind_around_ud"] ~= nil) then
                    bodyBytes[cursor + 4] = keyP["wind_around_ud"]
                end
                cursor = cursor + 5
            end
            if (keyP["self_remove_odor_phase"] ~= nil) then
                bodyBytes[cursor + 0] = 0x5D
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["self_remove_odor_phase"]
                cursor = cursor + 4
            end
            if (keyP["high_temp_remove_odor_alone"] ~= nil) then
                bodyBytes[cursor + 0] = 0x5E
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["high_temp_remove_odor_alone"]
                cursor = cursor + 4
            end
            if (keyP["power_lock"] ~= nil) then
                bodyBytes[cursor + 0] = 0x27
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["power_lock"]
                cursor = cursor + 4
            end
            if (keyP["ptc_lock"] ~= nil) then
                bodyBytes[cursor + 0] = 0x29
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["ptc_lock"]
                cursor = cursor + 4
            end
            if (keyP["offline_operating_time"] ~= nil) then
                bodyBytes[cursor + 0] = 0x2B
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = bit.band(keyP["offline_operating_time"],
                                                 0xff)
                bodyBytes[cursor + 4] = bit.band(bit.rshift(
                                                     keyP["offline_operating_time"],
                                                     8), 0xff)
                cursor = cursor + 5
            end
            if (keyP["ozone"] ~= nil) then
                bodyBytes[cursor + 0] = 0x5F
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["ozone"]
                cursor = cursor + 4
            end
            if (keyP["soft_warm"] ~= nil) then
                bodyBytes[cursor + 0] = 0x63
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["soft_warm"]
                cursor = cursor + 4
            end
            if (keyP["fresh_air_parm"] ~= nil) then
                bodyBytes[cursor + 0] = 0x50
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["fresh_air_parm"]
                cursor = cursor + 4
            end
            if (keyP["rewarming_dry"] ~= nil) then
                bodyBytes[cursor + 0] = 0x68
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["rewarming_dry"]
                cursor = cursor + 4
            end
            if (keyP["arom"] ~= nil) then
                bodyBytes[cursor + 0] = 0x69
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x07
                bodyBytes[cursor + 3] = keyP["arom"]
                bodyBytes[cursor + 4] = keyP["arom_fan_speed"]
                bodyBytes[cursor + 5] = keyP["arom_time_clean"]
                bodyBytes[cursor + 6] = bit.band(keyP["arom_time"], 0xff)
                bodyBytes[cursor + 7] = bit.band(
                                            bit.rshift(keyP["arom_time"], 8),
                                            0xff)
                bodyBytes[cursor + 8] = bit.band(keyP["arom_time_total"], 0xff)
                bodyBytes[cursor + 9] = bit.band(bit.rshift(
                                                     keyP["arom_time_total"], 8),
                                                 0xff)
                cursor = cursor + 10
            end
            if (keyP["new_mode_power"] ~= nil) then
                bodyBytes[cursor + 0] = 0x01
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x04
                bodyBytes[cursor + 3] = keyP["new_mode_power"]
                bodyBytes[cursor + 4] = keyP["new_mode"]
                bodyBytes[cursor + 5] = keyP["new_temperature"]
                bodyBytes[cursor + 6] = keyP["new_wind_speed"]
                cursor = cursor + 7
            end
            if (keyP["uvc_remove_odor"] ~= nil) then
                bodyBytes[cursor + 0] = 0x6F
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x02
                bodyBytes[cursor + 3] = keyP["uvc_remove_odor"]
                bodyBytes[cursor + 4] = keyP["uvc_power_off"]
                cursor = cursor + 5
            end
            if (keyP["main_strip_control"] ~= nil) then
                bodyBytes[cursor + 0] = 0x30
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x04
                bodyBytes[cursor + 3] = keyP["main_horizontal_guide_strip_1"]
                bodyBytes[cursor + 4] = keyP["main_horizontal_guide_strip_2"]
                bodyBytes[cursor + 5] = keyP["main_horizontal_guide_strip_3"]
                bodyBytes[cursor + 6] = keyP["main_horizontal_guide_strip_4"]
                cursor = cursor + 7
            end
            if (keyP["light_sensitive"] ~= nil) then
                bodyBytes[cursor + 0] = 0x08
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["light_sensitive"]
                cursor = cursor + 4
            end
            if (keyP["prepare_food"] ~= nil) then
                bodyBytes[cursor + 0] = 0x54
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["prepare_food"]
                bodyBytes[cursor + 3] = keyP["prepare_food_temp"]
                bodyBytes[cursor + 3] = keyP["prepare_food_fan_speed"]
                cursor = cursor + 6
            end
            if (keyP["quick_fry"] ~= nil) then
                bodyBytes[cursor + 0] = 0x55
                bodyBytes[cursor + 1] = 0x02
                bodyBytes[cursor + 2] = 0x03
                bodyBytes[cursor + 3] = keyP["quick_fry"]
                bodyBytes[cursor + 4] = keyP["quick_fry_temp"]
                bodyBytes[cursor + 5] = keyP["quick_fry_fan_speed"]
                cursor = cursor + 6
            end
            if (keyP["cool_power_saving"] ~= nil) then
                bodyBytes[cursor + 0] = 0x89
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["cool_power_saving"]
                cursor = cursor + 4
            end
            if (keyP["jet_cool"] ~= nil) then
                bodyBytes[cursor + 0] = 0x67
                bodyBytes[cursor + 1] = 0x00
                bodyBytes[cursor + 2] = 0x01
                bodyBytes[cursor + 3] = keyP["jet_cool"]
                cursor = cursor + 4
            end
            math.randomseed(tostring(os.time() * #bodyBytes):reverse():sub(1, 7))
            math.random()
            bodyBytes[cursor] = math.random(1, 254)
            bodyBytes[cursor + 1] = crc8_854(bodyBytes, 0, cursor)
        end
        infoM = getTotalMsg(bodyBytes, keyB["BYTE_CONTROL_REQUEST"])
    end
    keyP["propertyNumber"] = 0
    keyP["prevent_super_cool"] = nil
    keyP["prevent_straight_wind"] = nil
    keyP["auto_prevent_straight_wind"] = nil
    keyP["wind_straight"] = nil
    keyP["wind_avoid"] = nil
    keyP["yb_wind_avoid"] = nil
    keyP["intelligent_wind"] = nil
    keyP["self_clean"] = nil
    keyP["no_wind_sense"] = nil
    keyP["no_wind_sense_level"] = nil
    keyP["fn_no_wind_sense"] = nil
    keyP["child_prevent_cold_wind"] = nil
    keyP["little_angel"] = nil
    keyP["cool_hot_sense"] = nil
    keyP["gentle_wind_sense"] = nil
    keyP["security"] = nil
    keyP["even_wind"] = nil
    keyP["single_tuyere"] = nil
    keyP["extreme_wind"] = nil
    keyP["extreme_wind_level"] = nil
    keyP["voice_control"] = nil
    keyP["pre_cool_hot"] = nil
    keyP["water_washing"] = nil
    keyP["fresh_air"] = nil
    keyP["fa_prevent_straight_wind"] = nil
    keyP["parent_control"] = nil
    keyP["parent_control_temp_up"] = nil
    keyP["parent_control_temp_down"] = nil
    keyP["nobody_energy_save"] = nil
    keyP["filter_value"] = nil
    keyP["filter_level"] = nil
    keyP["prevent_straight_wind_lr"] = nil
    keyP["pm25_value"] = nil
    keyP["water_pump"] = nil
    keyP["intelligent_control"] = nil
    keyP["wind_swing_ud_angle"] = nil
    keyP["wind_swing_lr_angle"] = nil
    keyP["volume_control"] = nil
    keyP["voice_control_new"] = nil
    keyP["face_register"] = nil
    keyP["cool_temp_up"] = nil
    keyP["cool_temp_down"] = nil
    keyP["auto_temp_up"] = nil
    keyP["auto_temp_down"] = nil
    keyP["heat_temp_up"] = nil
    keyP["heat_temp_down"] = nil
    keyP["remote_control_lock"] = nil
    keyP["remote_control_lock_control"] = nil
    keyP["operating_time"] = nil
    keyP["indoor_humidity"] = nil
    keyP["degerming"] = nil
    keyP["wind_top"] = nil
    keyP["wind_around"] = nil
    keyP["wind_around_ud"] = nil
    keyP["child_lock"] = nil
    keyP["buzzer_all"] = nil
    keyP["self_remove_odor_phase"] = nil
    keyP["high_temp_remove_odor_alone"] = nil
    keyP["power_lock"] = nil
    keyP["ptc_lock"] = nil
    keyP["offline_operating_time"] = nil
    keyP["ozone"] = nil
    keyP["soft_warm"] = nil
    keyP["fresh_air_parm"] = nil
    keyP["rewarming_dry"] = nil
    keyP["new_mode_power"] = nil
    keyP["new_mode"] = nil
    keyP["new_temperature"] = nil
    keyP["new_wind_speed"] = nil
    keyP["uvc_remove_odor"] = nil
    keyP["uvc_power_off"] = nil
    keyP["ptc_default_rule"] = nil
    keyP["wind_swing_ud_angle_up"] = nil
    keyP["wind_swing_ud_angle_down"] = nil
    keyP["app_control_remember_ud"] = nil
    keyP["wind_swing_lr_angle_up"] = nil
    keyP["wind_swing_lr_angle_down"] = nil
    keyP["app_control_remember_lr"] = nil
    keyP["auto_prevent_cold_wind"] = nil
    keyP["prepare_food"] = nil
    keyP["quick_fry"] = nil
    keyP["quick_fry_temp"] = nil
    keyP["quick_fry_fan_speed"] = nil
    keyP["cool_power_saving"] = nil
    keyP["jet_cool"] = nil
    keyP["has_ptc_default_rule"] = nil
    keyP["has_light_sensitive"] = nil
    propertyPre = nil
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonCmd)
    init_keyP()
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceinfo = json["deviceinfo"]
    deviceSubType = deviceinfo["deviceSubType"]
    local deviceSN = json["deviceinfo"]["deviceSN"]
    if deviceSN ~= nil then deviceSN8 = string.sub(deviceSN, 13, 17) end
    local status = json["status"]
    if (status) then jsonToModel(status, "status") end
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[10];
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - keyB["BYTE_PROTOCOL_LENGTH"] - 1
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]]
    end
    binToModel(bodyBytes, deviceSN8)
    local streams = {}
    streams[keyT["KEY_VERSION"]] = keyV["VALUE_VERSION"]
    if (keyP["propertyNumber"] == 0) then
        if (keyP["powerValue"] ~= nil) then
            if (keyP["powerValue"] == keyB["BYTE_POWER_ON"]) then
                streams[keyT["KEY_POWER"]] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["powerValue"] == keyB["BYTE_POWER_OFF"]) then
                streams[keyT["KEY_POWER"]] = keyV["VALUE_FUNCTION_OFF"]
            else
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
                if (keyP["smartDryValue"] ~= nil and keyP["smartDryValue"] >= 30 and
                    keyP["smartDryValue"] <= 101) then
                    streams[keyT["KEY_SMART_DRY"]] = keyP["smartDryValue"]
                end
            end
        end
        if (keyP["purifierValue"] ~= nil) then
            if (keyP["purifierValue"] == keyB["BYTE_PURIFIER_ON"]) then
                streams[keyT["KEY_PURIFIER"]] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["purifierValue"] == keyB["BYTE_PURIFIER_OFF"]) then
                streams[keyT["KEY_PURIFIER"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["ecoValue"] ~= nil) then
            if (keyP["ecoValue"] == keyB["BYTE_ECO_ON"]) then
                streams[keyT["KEY_ECO"]] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["ecoValue"] == keyB["BYTE_ECO_OFF"]) then
                streams[keyT["KEY_ECO"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if ((keyP["dryValue"] ~= nil) and (keyP["modeValue"] ~= nil)) then
            if (keyP["dryValue"] == keyB["BYTE_DRY_ON"]) then
                streams[keyT["KEY_DRY"]] = keyV["VALUE_FUNCTION_ON"]
            else
                streams[keyT["KEY_DRY"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["fanspeedValue"] ~= nil) then
            streams[keyT["KEY_FANSPEED"]] = keyP["fanspeedValue"]
        end
        if ((keyP["outdoorTemperatureValue"] ~= nil) and
            (keyP["smallOutdoorTemperatureValue"] ~= nil)) then
            local t1, t2 = math.modf(keyP["outdoorTemperatureValue"])
            if (keyP["outdoorTemperatureValue"] < 0) then
                streams[keyV["VALUE_OUTDOOR_TEMPERATURE"]] = t1 -
                                                                 keyP["smallOutdoorTemperatureValue"] /
                                                                 10
            else
                streams[keyV["VALUE_OUTDOOR_TEMPERATURE"]] = t1 +
                                                                 keyP["smallOutdoorTemperatureValue"] /
                                                                 10
            end
        end
        if ((keyP["indoorTemperatureValue"] ~= nil) and
            (keyP["smallIndoorTemperatureValue"] ~= nil)) then
            local t1, t2 = math.modf(keyP["indoorTemperatureValue"])
            if (keyP["indoorTemperatureValue"] < 0) then
                streams[keyV["VALUE_INDOOR_TEMPERATURE"]] = t1 -
                                                                keyP["smallIndoorTemperatureValue"] /
                                                                10
            else
                streams[keyV["VALUE_INDOOR_TEMPERATURE"]] = t1 +
                                                                keyP["smallIndoorTemperatureValue"] /
                                                                10
            end
        end
        if (keyP["swingUDValue"] ~= nil) then
            if (keyP["swingUDValue"] == keyB["BYTE_SWING_UD_ON"]) then
                streams[keyT["KEY_SWING_UD"]] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["swingUDValue"] == keyB["BYTE_SWING_UD_OFF"]) then
                streams[keyT["KEY_SWING_UD"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["swingLRValue"] ~= nil) then
            if (keyP["swingLRValue"] == keyB["BYTE_SWING_LR_ON"]) then
                streams[keyT["KEY_SWING_LR"]] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["swingLRValue"] == keyB["BYTE_SWING_LR_OFF"]) then
                streams[keyT["KEY_SWING_LR"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["swingLRValueUnder"] == keyB["BYTE_SWING_LR_UNDER_ON"] or
            keyP["swingLRValueUnder"] == 0x40) then
            streams[keyT["KEY_SWING_LR_UNDER"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["swingLRValueUnder"] == keyB["BYTE_SWING_LR_UNDER_OFF"]) then
            streams[keyT["KEY_SWING_LR_UNDER"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if ((keyP["PTCValue"] ~= nil) and (keyP["modeValue"] ~= nil)) then
            if (keyP["PTCValue"] == keyB["BYTE_PTC_ON"]) then
                streams[keyT["KEY_PTC"]] = keyV["VALUE_FUNCTION_ON"]
            else
                streams[keyT["KEY_PTC"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["openTimerSwitch"] ~= nil) then
            if (keyP["openTimerSwitch"] == keyB["BYTE_START_TIMER_SWITCH_ON"]) then
                streams[keyT["KEY_TIME_ON"]] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["openTimerSwitch"] ==
                keyB["BYTE_START_TIMER_SWITCH_OFF"]) then
                streams[keyT["KEY_TIME_ON"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["closeTimerSwitch"] ~= nil) then
            if (keyP["closeTimerSwitch"] == keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
                streams[keyT["KEY_TIME_OFF"]] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["closeTimerSwitch"] ==
                keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
                streams[keyT["KEY_TIME_OFF"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["closeTimerSwitch"] ~= nil) then
            if (keyP["closeTimerSwitch"] == keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
                streams[keyT["KEY_CLOSE_TIME"]] = 0
            else
                streams[keyT["KEY_CLOSE_TIME"]] = keyP["closeTime"]
            end
        end
        if (keyP["openTimerSwitch"] ~= nil) then
            if (keyP["openTimerSwitch"] == keyB["BYTE_START_TIMER_SWITCH_OFF"]) then
                streams[keyT["KEY_OPEN_TIME"]] = 0
            else
                streams[keyT["KEY_OPEN_TIME"]] = keyP["openTime"]
            end
        end
        if (keyP["currentWorkTime"] ~= nil) then
            streams[keyT["KEY_CURRENT_WORK_TIME"]] = keyP["currentWorkTime"]
        end
        if (keyP["strongWindValue"] ~= nil) then
            if (keyP["strongWindValue"] == keyB["BYTE_STRONG_WIND_ON"]) then
                streams[keyT["KEY_STRONG_WIND"]] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["strongWindValue"] == keyB["BYTE_STRONG_WIND_OFF"]) then
                streams[keyT["KEY_STRONG_WIND"]] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["power_saving"] ~= nil) then
            if (keyP["power_saving"] == 0x08) then
                streams["power_saving"] = keyV["VALUE_FUNCTION_ON"]
            elseif (keyP["power_saving"] == 0x00) then
                streams["power_saving"] = keyV["VALUE_FUNCTION_OFF"]
            end
        end
        if (keyP["temperature"] ~= nil) then
            streams[keyT["KEY_TEMPERATURE"]] = keyP["temperature"]
        end
        if (keyP["smallTemperature"] ~= nil) then
            if (keyP["smallTemperature"] == 0x01) then
                streams["small_temperature"] = 0.5
            else
                streams["small_temperature"] = 0
            end
        end
        streams[keyT["KEY_ERROR_CODE"]] = keyP["errorCode"]
        if (keyP["kickQuilt"] ~= nil) then
            if (keyP["kickQuilt"] == 0x00) then
                streams["kick_quilt"] = "off"
            elseif (keyP["kickQuilt"] == 0x01) then
                streams["kick_quilt"] = "on"
            end
        end
        if (keyP["comfortPowerSave"] ~= nil) then
            if (keyP["comfortPowerSave"] == 0x00) then
                streams["comfort_power_save"] = "off"
            elseif (keyP["comfortPowerSave"] == 0x01) then
                streams["comfort_power_save"] = "on"
            end
        end
        if (keyP["no_wind_sense"] ~= nil) then
            streams["no_wind_sense"] = keyP["no_wind_sense"]
        end
        if (keyP["fn_no_wind_sense"] ~= nil) then
            if (keyP["fn_no_wind_sense"] == 0x00) then
                streams["fn_no_wind_sense"] = "off"
            elseif (keyP["fn_no_wind_sense"] == 0x01) then
                streams["fn_no_wind_sense"] = "on"
            end
        end
        if (keyP["no_wind_sense_level"] ~= nil) then
            streams["no_wind_sense_level"] = keyP["no_wind_sense_level"]
        end
        if (keyP["preventCold"] ~= nil) then
            if (keyP["preventCold"] == 0x00) then
                streams["prevent_cold"] = "off"
            elseif (keyP["preventCold"] == 0x01) then
                streams["prevent_cold"] = "on"
            end
        end
        if (keyP["comfortableSleepValue"] ~= nil) then
            if (keyP["comfortableSleepValue"] == 0x00) then
                streams["comfort_sleep"] = "off"
            elseif (keyP["comfortableSleepValue"] == 0x03) then
                streams["comfort_sleep"] = "on"
            end
        end
        if (keyP["screenDisplayNowValue"] ~= nil) then
            if (keyP["screenDisplayNowValue"] == 0x07) then
                streams["screen_display_now"] = "off"
            else
                streams["screen_display_now"] = "on"
            end
        end
        if (keyP["naturalWind"] ~= nil) then
            if (keyP["naturalWind"] == 0x02 or keyP["naturalWind"] == 0x40) then
                streams["natural_wind"] = "on"
            elseif (keyP["naturalWind"] == 0x00) then
                streams["natural_wind"] = "off"
            end
        end
        if (keyP["pmv"] ~= nil) then streams["pmv"] = keyP["pmv"] end
        if (keyP["fresh_filter_time_total"] ~= nil) then
            streams["fresh_filter_time_total"] = keyP["fresh_filter_time_total"]
        end
        if (keyP["fresh_filter_time_use"] ~= nil) then
            streams["fresh_filter_time_use"] = keyP["fresh_filter_time_use"]
        end
        if (keyP["fresh_filter_timeout"] ~= nil) then
            streams["fresh_filter_timeout"] = keyP["fresh_filter_timeout"]
        end
        if (keyP["electrify_time_day"] ~= nil) then
            streams["electrify_time_day"] = keyP["electrify_time_day"]
        end
        if (keyP["electrify_time_hour"] ~= nil) then
            streams["electrify_time_hour"] = keyP["electrify_time_hour"]
        end
        if (keyP["electrify_time_min"] ~= nil) then
            streams["electrify_time_min"] = keyP["electrify_time_min"]
        end
        if (keyP["electrify_time_second"] ~= nil) then
            streams["electrify_time_second"] = keyP["electrify_time_second"]
        end
        if (keyP["total_operating_time_day"] ~= nil) then
            streams["total_operating_time_day"] =
                keyP["total_operating_time_day"]
        end
        if (keyP["total_operating_time_hour"] ~= nil) then
            streams["total_operating_time_hour"] =
                keyP["total_operating_time_hour"]
        end
        if (keyP["total_operating_time_min"] ~= nil) then
            streams["total_operating_time_min"] =
                keyP["total_operating_time_min"]
        end
        if (keyP["total_operating_time_second"] ~= nil) then
            streams["total_operating_time_second"] =
                keyP["total_operating_time_second"]
        end
        if (keyP["current_operating_time_day"] ~= nil) then
            streams["current_operating_time_day"] =
                keyP["current_operating_time_day"]
        end
        if (keyP["current_operating_time_hour"] ~= nil) then
            streams["current_operating_time_hour"] =
                keyP["current_operating_time_hour"]
        end
        if (keyP["current_operating_time_min"] ~= nil) then
            streams["current_operating_time_min"] =
                keyP["current_operating_time_min"]
        end
        if (keyP["current_operating_time_second"] ~= nil) then
            streams["current_operating_time_second"] =
                keyP["current_operating_time_second"]
        end
        if (keyP["total_power_consumption"] ~= nil) then
            streams["total_power_consumption"] = keyP["total_power_consumption"]
        end
        if (keyP["total_operating_consumption"] ~= nil) then
            streams["total_operating_consumption"] =
                keyP["total_operating_consumption"]
        end
        if (keyP["current_operating_consumption"] ~= nil) then
            streams["current_operating_consumption"] =
                keyP["current_operating_consumption"]
        end
        if (keyP["current_time_power"] ~= nil) then
            streams["current_time_power"] = keyP["current_time_power"]
        end
        if (keyP["analysis_value"] ~= nil) then
            streams["analysis_value"] = keyP["analysis_value"]
        end
        if (keyP["t2_temp"] ~= nil) then
            streams["t2_temp"] = keyP["t2_temp"]
        end
        if (keyP["dust_full_time"] ~= nil) then
            streams["dust_full_time"] = keyP["dust_full_time"]
        end
        if (keyP["fault_tag"] ~= nil) then
            streams["fault_tag"] = keyP["fault_tag"]
        end
        if (keyP["arom_old"] ~= nil) then
            streams["arom_old"] = keyP["arom_old"]
        end
    else
        if (keyP["prevent_super_cool"] ~= nil) then
            if (keyP["prevent_super_cool"] == 0x00) then
                streams["prevent_super_cool"] = "off"
            elseif (keyP["prevent_super_cool"] == 0x01) then
                streams["prevent_super_cool"] = "on"
            end
        end
        if (keyP["prevent_straight_wind"] ~= nil) then
            streams["prevent_straight_wind"] = keyP["prevent_straight_wind"]
        end
        if (keyP["fa_prevent_straight_wind"] ~= nil) then
            streams["fa_prevent_straight_wind"] =
                keyP["fa_prevent_straight_wind"]
        end
        if (keyP["auto_prevent_straight_wind"] ~= nil) then
            if (keyP["auto_prevent_straight_wind"] == 0x00) then
                streams["auto_prevent_straight_wind"] = "off"
            elseif (keyP["auto_prevent_straight_wind"] == 0x01) then
                streams["auto_prevent_straight_wind"] = "on"
            end
        end
        if (keyP["self_clean"] ~= nil) then
            if (keyP["self_clean"] == 0x00) then
                streams["self_clean"] = "off"
            elseif (keyP["self_clean"] == 0x01) then
                streams["self_clean"] = "on"
            end
        end
        if (keyP["wind_straight"] ~= nil) then
            if (keyP["wind_straight"] == 0x00) then
                streams["wind_straight"] = "off"
            elseif (keyP["wind_straight"] == 0x01) then
                streams["wind_straight"] = "on"
            end
        end
        if (keyP["yb_wind_avoid"] ~= nil) then
            if (keyP["yb_wind_avoid"] == 0x00) then
                streams["yb_wind_avoid"] = "off"
            elseif (keyP["yb_wind_avoid"] == 0x02) then
                streams["yb_wind_avoid"] = "on"
            end
        end
        if (keyP["wind_avoid"] ~= nil) then
            if (keyP["wind_avoid"] == 0x00) then
                streams["wind_avoid"] = "off"
            elseif (keyP["wind_avoid"] == 0x01 or keyP["wind_avoid"] == 0x02) then
                streams["wind_avoid"] = "on"
            end
        end
        if (keyP["intelligent_wind"] ~= nil) then
            if (keyP["intelligent_wind"] == 0x00) then
                streams["intelligent_wind"] = "off"
            elseif (keyP["intelligent_wind"] == 0x01) then
                streams["intelligent_wind"] = "on"
            end
        end
        if (keyP["child_prevent_cold_wind"] ~= nil) then
            if (keyP["child_prevent_cold_wind"] == 0x00) then
                streams["child_prevent_cold_wind"] = "off"
            elseif (keyP["child_prevent_cold_wind"] == 0x01) then
                streams["child_prevent_cold_wind"] = "on"
            end
        end
        if (keyP["no_wind_sense"] ~= nil) then
            streams["no_wind_sense"] = keyP["no_wind_sense"]
        end
        if (keyP["fn_no_wind_sense"] ~= nil) then
            if (keyP["fn_no_wind_sense"] == 0x00) then
                streams["fn_no_wind_sense"] = "off"
            elseif (keyP["fn_no_wind_sense"] == 0x01) then
                streams["fn_no_wind_sense"] = "on"
            end
        end
        if (keyP["no_wind_sense_level"] ~= nil) then
            streams["no_wind_sense_level"] = keyP["no_wind_sense_level"]
        end
        if (keyP["little_angel"] ~= nil) then
            if (keyP["little_angel"] == 0x00) then
                streams["little_angel"] = "off"
            elseif (keyP["little_angel"] == 0x01) then
                streams["little_angel"] = "on"
            end
        end
        if (keyP["ptc_default_rule"] ~= nil) then
            streams["ptc_default_rule"] = keyP["ptc_default_rule"]
        end
        if (keyP["cool_hot_sense"] ~= nil) then
            if (keyP["cool_hot_sense"] == 0x00) then
                streams["cool_hot_sense"] = "off"
            elseif (keyP["cool_hot_sense"] == 0x01) then
                streams["cool_hot_sense"] = "on"
            end
        end
        if (keyP["gentle_wind_sense"] ~= nil) then
            if (keyP["gentle_wind_sense"] == 0x01) then
                streams["gentle_wind_sense"] = "off"
            elseif (keyP["gentle_wind_sense"] == 0x03) then
                streams["gentle_wind_sense"] = "on"
            end
        end
        if (keyP["security"] ~= nil) then
            if (keyP["security"] == 0x00) then
                streams["security"] = "off"
            elseif (keyP["security"] == 0x01) then
                streams["security"] = "on"
            end
        end
        if (keyP["even_wind"] ~= nil) then
            if (keyP["even_wind"] == 0x00) then
                streams["even_wind"] = "off"
            elseif (keyP["even_wind"] == 0x01) then
                streams["even_wind"] = "on"
            end
        end
        if (keyP["single_tuyere"] ~= nil) then
            if (keyP["single_tuyere"] == 0x00) then
                streams["single_tuyere"] = "off"
            elseif (keyP["single_tuyere"] == 0x01) then
                streams["single_tuyere"] = "on"
            end
        end
        if (keyP["extreme_wind"] ~= nil) then
            if (keyP["extreme_wind"] == 0x00) then
                streams["extreme_wind"] = "off"
            elseif (keyP["extreme_wind"] == 0x01) then
                streams["extreme_wind"] = "on"
            end
            streams["extreme_wind_level"] = keyP["extreme_wind_level"]
        end
        if (keyP["degerming"] ~= nil) then
            if (keyP["degerming"] == 0x00) then
                streams["degerming"] = "off"
            elseif (keyP["degerming"] == 0x01) then
                streams["degerming"] = "on"
                streams["power"] = "on"
            end
        end
        if (keyP["light"] ~= nil) then streams["light"] = keyP["light"] end
        if (keyP["wind_top"] ~= nil) then
            if (keyP["wind_top"] == 0x00) then
                streams["wind_top"] = "off"
            elseif (keyP["wind_top"] == 0x01) then
                streams["wind_top"] = "on"
            end
        end
        if (keyP["wind_around"] ~= nil) then
            if (keyP["wind_around"] == 0x00) then
                streams["wind_around"] = "off"
            elseif (keyP["wind_around"] == 0x01) then
                streams["wind_around"] = "on"
            end
        end
        if (keyP["wind_around_ud"] ~= nil) then
            streams["wind_around_ud"] = keyP["wind_around_ud"]
        end
        if (keyP["wind_swing_lr_angle"] ~= nil) then
            streams["wind_swing_lr_angle"] = keyP["wind_swing_lr_angle"]
        end
        if (keyP["wind_swing_ud_angle"] ~= nil) then
            streams["wind_swing_ud_angle"] = keyP["wind_swing_ud_angle"]
        end
        if (keyP["voice_control"] ~= nil) then
            if (keyP["voice_control"] == 0x00) then
                streams["voice_control"] = "off"
            elseif (keyP["voice_control"] == 0x03) then
                streams["voice_control"] = "on"
            end
        end
        if (keyP["pre_cool_hot"] ~= nil) then
            if (keyP["pre_cool_hot"] == 0x00) then
                streams["pre_cool_hot"] = "off"
            elseif (keyP["pre_cool_hot"] == 0x01) then
                streams["pre_cool_hot"] = "on"
            end
        end
        if (keyP["water_washing"] ~= nil) then
            if (keyP["water_washing"] == 0x01) then
                streams["water_washing"] = "on"
            elseif (keyP["water_washing"] == 0x00) then
                streams["water_washing"] = "off"
            end
            streams["water_washing_manual"] = keyP["water_washing_manual"]
            streams["water_washing_time"] = keyP["water_washing_time"]
            streams["water_washing_stage"] = keyP["water_washing_stage"]
        end
        if (keyP["fresh_air"] ~= nil) then
            if (keyP["fresh_air"] == 0x00) then
                streams["fresh_air"] = "off"
            elseif (keyP["fresh_air"] == 0x01) then
                streams["fresh_air"] = "on"
            end
            streams["fresh_air_fan_speed"] = keyP["fresh_air_fan_speed"]
            streams["fresh_air_temp"] = keyP["fresh_air_temp"]
        end
        if (keyP["parent_control"] ~= nil) then
            if (keyP["parent_control"] == 0x00) then
                streams["parent_control"] = "off"
            elseif (keyP["parent_control"] == 0x01) then
                streams["parent_control"] = "on"
            end
            streams["parent_control_temp_up"] = keyP["parent_control_temp_up"]
            streams["parent_control_temp_down"] =
                keyP["parent_control_temp_down"]
        end
        if (keyP["nobody_energy_save"] ~= nil) then
            if (keyP["nobody_energy_save"] == 0x00) then
                streams["nobody_energy_save"] = "off"
            elseif (keyP["nobody_energy_save"] == 0x01) then
                streams["nobody_energy_save"] = "on"
            end
        end
        if (keyP["filter_value"] ~= nil) then
            streams["filter_value"] = keyP["filter_value"]
            streams["filter_level"] = keyP["filter_level"]
        end
        if (keyP["prevent_straight_wind_lr"] ~= nil) then
            streams["prevent_straight_wind_lr"] =
                keyP["prevent_straight_wind_lr"]
        end
        if (keyP["pm25_value"] ~= nil) then
            streams["pm25_value"] = keyP["pm25_value"]
        end
        if (keyP["water_pump"] ~= nil) then
            if (keyP["water_pump"] == 0x00) then
                streams["water_pump"] = "off"
            elseif (keyP["water_pump"] == 0x01) then
                streams["water_pump"] = "on"
            end
        end
        if (keyP["intelligent_control"] ~= nil) then
            if (keyP["intelligent_control"] == 0x00) then
                streams["intelligent_control"] = "off"
            elseif (keyP["intelligent_control"] == 0x01) then
                streams["intelligent_control"] = "on"
            end
        end
        if (keyP["volume_control"] ~= nil) then
            streams["volume_control"] = keyP["volume_control"]
        end
        if (keyP["voice_control_new"] ~= nil) then
            streams["voice_control_new"] = keyP["voice_control_new"]
        end
        if (keyP["face_register"] ~= nil) then
            streams["face_register"] = keyP["face_register"]
        end
        if (keyP["wind_swing_ud_angle_up"] ~= nil) then
            streams["wind_swing_ud_angle_up"] = keyP["wind_swing_ud_angle_up"]
        end
        if (keyP["wind_swing_ud_angle_down"] ~= nil) then
            streams["wind_swing_ud_angle_down"] =
                keyP["wind_swing_ud_angle_down"]
        end
        if (keyP["app_control_remember_ud"] ~= nil) then
            streams["app_control_remember_ud"] = keyP["app_control_remember_ud"]
        end
        if (keyP["wind_swing_lr_angle_up"] ~= nil) then
            streams["wind_swing_lr_angle_up"] = keyP["wind_swing_lr_angle_up"]
        end
        if (keyP["wind_swing_lr_angle_down"] ~= nil) then
            streams["wind_swing_lr_angle_down"] =
                keyP["wind_swing_lr_angle_down"]
        end
        if (keyP["app_control_remember_lr"] ~= nil) then
            streams["app_control_remember_lr"] = keyP["app_control_remember_lr"]
        end
        if (keyP["auto_prevent_cold_wind"] ~= nil) then
            streams["auto_prevent_cold_wind"] = keyP["auto_prevent_cold_wind"]
        end
        if (keyP["cool_temp_up"] ~= nil) then
            streams["cool_temp_up"] = keyP["cool_temp_up"]
        end
        if (keyP["cool_temp_down"] ~= nil) then
            streams["cool_temp_down"] = keyP["cool_temp_down"]
        end
        if (keyP["auto_temp_up"] ~= nil) then
            streams["auto_temp_up"] = keyP["auto_temp_up"]
        end
        if (keyP["auto_temp_down"] ~= nil) then
            streams["auto_temp_down"] = keyP["auto_temp_down"]
        end
        if (keyP["heat_temp_up"] ~= nil) then
            streams["heat_temp_up"] = keyP["heat_temp_up"]
        end
        if (keyP["heat_temp_down"] ~= nil) then
            streams["heat_temp_down"] = keyP["heat_temp_down"]
        end
        if (keyP["remote_control_lock"] ~= nil) then
            streams["remote_control_lock"] = keyP["remote_control_lock"]
        end
        if (keyP["remote_control_lock_control"] ~= nil) then
            streams["remote_control_lock_control"] =
                keyP["remote_control_lock_control"]
        end
        if (keyP["operating_time"] ~= nil) then
            streams["operating_time"] = keyP["operating_time"]
        end
        if (keyP["indoor_humidity"] ~= nil) then
            streams["indoor_humidity"] = keyP["indoor_humidity"]
        end
        if (keyP["child_lock"] ~= nil) then
            streams["child_lock"] = keyP["child_lock"]
        end
        if (keyP["is_query"] ~= nil) then
            streams["is_query"] = keyP["is_query"]
        end
        if (keyP["analysis_value"] ~= nil) then
            streams["analysis_value"] = keyP["analysis_value"]
        end
        if (keyP["buzzer_all"] ~= nil) then
            streams["buzzer_all"] = keyP["buzzer_all"]
        end
        if (keyP["self_remove_odor_phase"] ~= nil) then
            streams["self_remove_odor_phase"] = keyP["self_remove_odor_phase"]
        end
        if (keyP["has_self_remove_odor_phase"] ~= nil) then
            streams["has_self_remove_odor_phase"] =
                keyP["has_self_remove_odor_phase"]
        end
        if (keyP["high_temp_remove_odor_alone"] ~= nil) then
            streams["high_temp_remove_odor_alone"] =
                keyP["high_temp_remove_odor_alone"]
        end
        if (keyP["has_high_temp_remove_odor_alone"] ~= nil) then
            streams["has_high_temp_remove_odor_alone"] =
                keyP["has_high_temp_remove_odor_alone"]
        end
        if (keyP["power_lock"] ~= nil) then
            if (keyP["power_lock"] == 0x00) then
                streams["power_lock"] = "off"
            elseif (keyP["power_lock"] == 0x01) then
                streams["power_lock"] = "on"
            end
        end
        if (keyP["ptc_lock"] ~= nil) then
            if (keyP["ptc_lock"] == 0x00) then
                streams["ptc_lock"] = "off"
            elseif (keyP["ptc_lock"] == 0x01) then
                streams["ptc_lock"] = "on"
            end
        end
        if (keyP["offline_operating_time"] ~= nil) then
            streams["offline_operating_time"] = keyP["offline_operating_time"]
        end
        if (keyP["ozone"] ~= nil) then streams["ozone"] = keyP["ozone"] end
        if (keyP["soft_warm"] ~= nil) then
            streams["soft_warm"] = keyP["soft_warm"]
        end
        if (keyP["fresh_air_parm"] ~= nil) then
            streams["fresh_air_parm"] = keyP["fresh_air_parm"]
        end
        if (keyP["rewarming_dry"] ~= nil) then
            streams["rewarming_dry"] = keyP["rewarming_dry"]
        end
        if (keyP["arom"] ~= nil) then streams["arom"] = keyP["arom"] end
        if (keyP["arom_fan_speed"] ~= nil) then
            streams["arom_fan_speed"] = keyP["arom_fan_speed"]
        end
        if (keyP["arom_time_clean"] ~= nil) then
            streams["arom_time_clean"] = keyP["arom_time_clean"]
        end
        if (keyP["arom_time"] ~= nil) then
            streams["arom_time"] = keyP["arom_time"]
        end
        if (keyP["arom_time_total"] ~= nil) then
            streams["arom_time_total"] = keyP["arom_time_total"]
        end
        if (keyP["new_mode_power"] ~= nil) then
            streams["new_mode_power"] = keyP["new_mode_power"]
        end
        if (keyP["new_temperature"] ~= nil) then
            streams["new_temperature"] = keyP["new_temperature"]
        end
        if (keyP["new_wind_speed"] ~= nil) then
            streams["new_wind_speed"] = keyP["new_wind_speed"]
        end
        if (keyP["new_mode"] ~= nil) then
            if (keyP["new_mode"] == 1) then
                streams["new_mode"] = "auto"
            elseif (keyP["new_mode"] == 2) then
                streams["new_mode"] = "cool"
            elseif (keyP["new_mode"] == 3) then
                streams["new_mode"] = "dry"
            elseif (keyP["new_mode"] == 4) then
                streams["new_mode"] = "heat"
            elseif (keyP["new_mode"] == 5) then
                streams["new_mode"] = "fan"
            end
        end
        if (keyP["uvc_remove_odor"] ~= nil) then
            streams["uvc_remove_odor"] = keyP["uvc_remove_odor"]
        end
        if (keyP["uvc_power_off"] ~= nil) then
            streams["uvc_power_off"] = keyP["uvc_power_off"]
        end
        if (keyP["main_horizontal_guide_strip_1"] ~= nil) then
            streams["main_horizontal_guide_strip_1"] =
                keyP["main_horizontal_guide_strip_1"]
        end
        if (keyP["main_horizontal_guide_strip_2"] ~= nil) then
            streams["main_horizontal_guide_strip_2"] =
                keyP["main_horizontal_guide_strip_2"]
        end
        if (keyP["main_horizontal_guide_strip_3"] ~= nil) then
            streams["main_horizontal_guide_strip_3"] =
                keyP["main_horizontal_guide_strip_3"]
        end
        if (keyP["main_horizontal_guide_strip_4"] ~= nil) then
            streams["main_horizontal_guide_strip_4"] =
                keyP["main_horizontal_guide_strip_4"]
        end
        if (keyP["has_guide_strip"] ~= nil) then
            streams["has_guide_strip"] = keyP["has_guide_strip"]
        end
        if (keyP["has_no_wind_sense"] ~= nil) then
            streams["has_no_wind_sense"] = keyP["has_no_wind_sense"]
        end
        if (keyP["light_sensitive"] ~= nil) then
            streams["light_sensitive"] = keyP["light_sensitive"]
        end
        if (keyP["has_arom"] ~= nil) then
            streams["has_arom"] = keyP["has_arom"]
        end
        if (keyP["has_wind_swing_ud_angle_diy"] ~= nil) then
            streams["has_wind_swing_ud_angle_diy"] =
                keyP["has_wind_swing_ud_angle_diy"]
        end
        if (keyP["has_wind_swing_lr_angle_diy"] ~= nil) then
            streams["has_wind_swing_lr_angle_diy"] =
                keyP["has_wind_swing_lr_angle_diy"]
        end
        if (keyP["prepare_food"] ~= nil) then
            streams["prepare_food"] = keyP["prepare_food"]
        end
        if (keyP["prepare_food_temp"] ~= nil) then
            streams["prepare_food_temp"] = keyP["prepare_food_temp"]
        end
        if (keyP["prepare_food_fan_speed"] ~= nil) then
            streams["prepare_food_fan_speed"] = keyP["prepare_food_fan_speed"]
        end
        if (keyP["quick_fry"] ~= nil) then
            streams["quick_fry"] = keyP["quick_fry"]
        end
        if (keyP["quick_fry_temp"] ~= nil) then
            streams["quick_fry_temp"] = keyP["quick_fry_temp"]
        end
        if (keyP["quick_fry_fan_speed"] ~= nil) then
            streams["quick_fry_fan_speed"] = keyP["quick_fry_fan_speed"]
        end
        if (keyP["cool_power_saving"] ~= nil) then
            streams["cool_power_saving"] = keyP["cool_power_saving"]
        end
        if (keyP["jet_cool"] ~= nil) then
            if (keyP["jet_cool"] == 0x00) then
                streams["jet_cool"] = "off"
            elseif (keyP["jet_cool"] == 0x01) then
                streams["jet_cool"] = "on"
            end
        end
        if (keyP["has_ptc_default_rule"] ~= nil) then
            streams["has_ptc_default_rule"] = keyP["has_ptc_default_rule"]
        end
        if (keyP["has_light_sensitive"] ~= nil) then
            streams["has_light_sensitive"] = keyP["has_light_sensitive"]
        end
    end
    keyP["propertyNumber"] = 0
    keyP["prevent_super_cool"] = nil
    keyP["prevent_straight_wind"] = nil
    keyP["auto_prevent_straight_wind"] = nil
    keyP["wind_straight"] = nil
    keyP["wind_avoid"] = nil
    keyP["yb_wind_avoid"] = nil
    keyP["intelligent_wind"] = nil
    keyP["self_clean"] = nil
    keyP["no_wind_sense"] = nil
    keyP["no_wind_sense_level"] = nil
    keyP["fn_no_wind_sense"] = nil
    keyP["child_prevent_cold_wind"] = nil
    keyP["little_angel"] = nil
    keyP["cool_hot_sense"] = nil
    keyP["gentle_wind_sense"] = nil
    keyP["prevent_straight_wind_fa"] = nil
    keyP["no_wind_sense_fa"] = nil
    keyP["security"] = nil
    keyP["even_wind"] = nil
    keyP["single_tuyere"] = nil
    keyP["extreme_wind"] = nil
    keyP["extreme_wind_level"] = nil
    keyP["voice_control"] = nil
    keyP["pre_cool_hot"] = nil
    keyP["water_washing"] = nil
    keyP["fresh_air"] = nil
    keyP["fa_prevent_straight_wind"] = nil
    keyP["parent_control"] = nil
    keyP["parent_control_temp_up"] = nil
    keyP["parent_control_temp_down"] = nil
    keyP["nobody_energy_save"] = nil
    keyP["filter_value"] = nil
    keyP["filter_level"] = nil
    keyP["prevent_straight_wind_lr"] = nil
    keyP["pm25_value"] = nil
    keyP["water_pump"] = nil
    keyP["intelligent_control"] = nil
    keyP["volume_control"] = nil
    keyP["voice_control_new"] = nil
    keyP["wind_swing_ud_angle"] = nil
    keyP["wind_swing_lr_angle"] = nil
    keyP["face_register"] = nil
    keyP["cool_temp_up"] = nil
    keyP["cool_temp_down"] = nil
    keyP["auto_temp_up"] = nil
    keyP["auto_temp_down"] = nil
    keyP["heat_temp_up"] = nil
    keyP["heat_temp_down"] = nil
    keyP["remote_control_lock"] = nil
    keyP["remote_control_lock_control"] = nil
    keyP["operating_time"] = nil
    keyP["indoor_humidity"] = nil
    keyP["degerming"] = nil
    keyP["light"] = nil
    keyP["wind_top"] = nil
    keyP["wind_around"] = nil
    keyP["wind_around_ud"] = nil
    keyP["child_lock"] = nil
    keyP["is_query"] = nil
    keyP["analysis_value"] = nil
    keyP["filter_replace_time"] = nil
    keyP["dust_full_time"] = nil
    keyP["buzzer_all"] = nil
    keyP["self_remove_odor_phase"] = nil
    keyP["high_temp_remove_odor_alone"] = nil
    keyP["power_lock"] = nil
    keyP["ptc_lock"] = nil
    keyP["offline_operating_time"] = nil
    keyP["ozone"] = nil
    keyP["fault_tag"] = nil
    keyP["soft_warm"] = nil
    keyP["fresh_air_parm"] = nil
    keyP["rewarming_dry"] = nil
    keyP["ptc_default_rule"] = nil
    keyP["wind_swing_ud_angle_up"] = nil
    keyP["wind_swing_ud_angle_down"] = nil
    keyP["app_control_remember_ud"] = nil
    keyP["wind_swing_lr_angle_up"] = nil
    keyP["wind_swing_lr_angle_down"] = nil
    keyP["app_control_remember_lr"] = nil
    keyP["auto_prevent_cold_wind"] = nil
    keyP["arom"] = nil
    keyP["arom_old"] = nil
    keyP["arom_fan_speed"] = nil
    keyP["arom_time_clean"] = nil
    keyP["arom_time"] = nil
    keyP["arom_time_total"] = nil
    keyP["new_mode_power"] = nil
    keyP["new_mode"] = nil
    keyP["new_temperature"] = nil
    keyP["new_wind_speed"] = nil
    keyP["uvc_remove_odor"] = nil
    keyP["uvc_power_off"] = nil
    keyP["main_horizontal_guide_strip_1"] = nil
    keyP["main_horizontal_guide_strip_2"] = nil
    keyP["main_horizontal_guide_strip_3"] = nil
    keyP["main_horizontal_guide_strip_4"] = nil
    keyP["has_guide_strip"] = nil
    keyP["has_no_wind_sense"] = nil
    keyP["light_sensitive"] = nil
    keyP["has_arom"] = nil
    keyP["t2_temp"] = nil
    keyP["has_wind_swing_ud_angle_diy"] = nil
    keyP["has_wind_swing_lr_angle_diy"] = nil
    keyP["has_self_remove_odor_phase"] = nil
    keyP["has_high_temp_remove_odor_alone"] = nil
    keyP["prepare_food"] = nil
    keyP["prepare_food_temp"] = nil
    keyP["prepare_food_fan_speed"] = nil
    keyP["quick_fry"] = nil
    keyP["quick_fry_temp"] = nil
    keyP["quick_fry_fan_speed"] = nil
    keyP["cool_power_saving"] = nil
    keyP["jet_cool"] = nil
    keyP["has_ptc_default_rule"] = nil
    keyP["has_light_sensitive"] = nil
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
