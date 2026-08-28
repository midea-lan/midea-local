----空调协议解析
----author: tody.yang
----email ：jun6.yang@midea.com
----date  : 2017/6/30

--CA机型，04,05上报的温度 要按小数位在BIT1解释
--正常机型, 04,05上报的温度 要按小数位在BIT6解释

local JSON = require "cjson"
local bit = require("bit")

-----------------JSON相关key值变量-----------------
local keyT = {}

--版本号
keyT["KEY_VERSION"] = "version"
--电源
keyT["KEY_POWER"] = "power"
--净化
keyT["KEY_PURIFIER"] = "purifier"
--模式
keyT["KEY_MODE"] = "mode"
--温度
keyT["KEY_TEMPERATURE"] = "temperature"
--风速
keyT["KEY_FANSPEED"] = "wind_speed"
--上左右扫风
keyT["KEY_SWING_LR_UPPER"] = "wind_swing_lr_upper"
--下左右扫风
keyT["KEY_SWING_LR_UNDER"] = "wind_swing_lr_under"
--上下扫风
keyT["KEY_SWING_UD"] = "wind_swing_ud"
--定时开
keyT["KEY_TIME_ON"] = "power_on_timer"
--定时关
keyT["KEY_TIME_OFF"] = "power_off_timer"
--定时关时间
keyT["KEY_CLOSE_TIME"] = "power_off_time_value"
--定时开时间
keyT["KEY_OPEN_TIME"] = "power_on_time_value"
--ECO
keyT["KEY_ECO"] = "eco"
--干燥
keyT["KEY_DRY"] = "dry"
--电辅热
keyT["KEY_PTC"] = "ptc"
--本次开机运行时间
keyT["KEY_CURRENT_WORK_TIME"] = "current_work_time"
--错误码
keyT["KEY_ERROR_CODE"] = "error_code"
--按键（蜂鸣）
keyT["KEY_BUZZER"] = "buzzer"
--防过冷(快速降温，缓慢回温)
keyT["KEY_PREVENT_SUPER_COOL"] = "prevent_super_cool"
--防直吹
keyT["KEY_PREVENT_STRAIGHT_WIND"] = "prevent_straight_wind"
--自动防直吹
keyT["KEY_AUTO_PREVENT_STRAIGHT_WIND"] = "auto_prevent_straight_wind"
--自清洁
keyT["KEY_SELF_CLEAN"] = "self_clean"
--风吹人
keyT["KEY_WIND_STRAIGHT"] = "wind_straight"
--风吹人
keyT["KEY_WIND_AVOID"] = "wind_avoid"
--智慧风
keyT["KEY_INTELLIGENT_WIND"] = "intelligent_wind"
--无风感
keyT["KEY_NO_WIND_SENSE"] = "no_wind_sense"
--儿童放冷风
keyT["KEY_CHILD_PREVENT_COLD_WIND"] = "child_prevent_cold_wind"
--强劲
keyT["KEY_STRONG_WIND"] = "strong_wind"
--舒省
keyT["KEY_COMFORT_POWER_SAVE"] = "comfort_power_save"
--屏显
keyT["KEY_SCREEN_DISPLAY"] = "screen_display"
--小天使
keyT["KEY_LITTLE_ANGLE"] = "little_angel"
--冷热感
keyT["KEY_COOL_HOT_SENSE"] = "cool_hot_sense"
--柔风感(FA机型)
keyT["KEY_GENTLE_WIND_SENSE"] = "gentle_wind_sense"
--安防
keyT["KEY_SECURITY"] = "security"

----------------JSON相关value值变量----------------
local keyV = {}
--版本号
keyV["VALUE_VERSION"] = 7
--功能开
keyV["VALUE_FUNCTION_ON"] = "on"
--功能关
keyV["VALUE_FUNCTION_OFF"] = "off"
--制热
keyV["VALUE_MODE_HEAT"] = "heat"
--制冷
keyV["VALUE_MODE_COOL"] = "cool"
--自动
keyV["VALUE_MODE_AUTO"] = "auto"
--干燥
keyV["VALUE_MODE_DRY"] = "dry"
--送风
keyV["VALUE_MODE_FAN"] = "fan"
--室内温度
keyV["VALUE_INDOOR_TEMPERATURE"] = "indoor_temperature"
--室外温度
keyV["VALUE_OUTDOOR_TEMPERATURE"] = "outdoor_temperature"
--运行状态
keyV["VALUE_RUN_STATE"] = "runstate"
--运行
keyV["VALUE_RUNNING"] = "running"
--停止
keyV["VALUE_STOP"] = "stopped"

local deviceSubType=0
local deviceSN8="00000000"
-----------------二进制相关属性变量----------------
local keyB = {}
--设备
keyB["BYTE_DEVICE_TYPE"] = 0xAC
--控制请求
keyB["BYTE_CONTROL_REQUEST"] = 0x02
--查询请求
keyB["BYTE_QUERYL_REQUEST"] = 0x03
--协议头
keyB["BYTE_PROTOCOL_HEAD"] = 0xAA
--协议头长度
keyB["BYTE_PROTOCOL_LENGTH"] = 0x0A
--电源开
keyB["BYTE_POWER_ON"] = 0x01
--电源关
keyB["BYTE_POWER_OFF"] = 0x00

--自动模式
keyB["BYTE_MODE_AUTO"] = 0x20
--制冷模式
keyB["BYTE_MODE_COOL"] = 0x40
--抽湿模式
keyB["BYTE_MODE_DRY"] = 0x60
--制热模式
keyB["BYTE_MODE_HEAT"] = 0x80
--送风模式
keyB["BYTE_MODE_FAN"] = 0xA0

--自动风
keyB["BYTE_FANSPEED_AUTO"] = 0x66
--高风
keyB["BYTE_FANSPEED_HIGH"] = 0x50
--中风
keyB["BYTE_FANSPEED_MID"] = 0x3C
--低风
keyB["BYTE_FANSPEED_LOW"] = 0x28
--微风
keyB["BYTE_FANSPEED_MUTE"] = 0x14
--净化开
keyB["BYTE_PURIFIER_ON"] = 0x20
--净化关
keyB["BYTE_PURIFIER_OFF"] = 0x00
--经济（ECO）开
keyB["BYTE_ECO_ON"] = 0x80
--经济（ECO）关
keyB["BYTE_ECO_OFF"] = 0x00
--上左右扫风开
keyB["BYTE_SWING_LR_UPPER_ON"] = 0x03
--上左右扫风关
keyB["BYTE_SWING_LR_UPPER_OFF"] = 0x00
--下左右扫风开
keyB["BYTE_SWING_LR_UNDER_ON"] = 0x80
--下左右扫风关
keyB["BYTE_SWING_LR_UNDER_OFF"] = 0x00
--下左右扫风功能开
keyB["BYTE_SWING_LR_UNDER_ENABLE"] = 0x80
--下左右扫风功能关
keyB["BYTE_SWING_LR_UNDER_DISENABLE"] = 0x00
--上下扫风开
keyB["BYTE_SWING_UD_ON"] = 0x0C
--上下扫风关
keyB["BYTE_SWING_UD_OFF"] = 0x00
--干燥开
keyB["BYTE_DRY_ON"] = 0x04
--干燥关
keyB["BYTE_DRY_OFF"] = 0x00
--buzzer（蜂鸣）开
keyB["BYTE_BUZZER_ON"] = 0x40
--buzzer（蜂鸣）关
keyB["BYTE_BUZZER_OFF"] = 0x00
--设备控制命令
keyB["BYTE_CONTROL_CMD"] = 0x40
--定时方式(相对)
keyB["BYTE_TIMER_METHOD_REL"] = 0x00
--定时方式(相对)
keyB["BYTE_TIMER_METHOD_ABS"] = 0x01
--定时方式(禁用)
keyB["BYTE_TIMER_METHOD_DISABLE"] = 0x7F
--移动终端控制
keyB["BYTE_CLIENT_MODE_MOBILE"] = 0x02
--移动端定时开
keyB["BYTE_TIMER_SWITCH_ON"] = 0x80
--移动端定时关
keyB["BYTE_TIMER_SWITCH_OFF"] = 0x00
--定时关(开)
keyB["BYTE_CLOSE_TIMER_SWITCH_ON"] = 0x80
--定时关(关)
keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"] = 0x7F
--定时开(开)
keyB["BYTE_START_TIMER_SWITCH_ON"] = 0x80
--定时开(关)
keyB["BYTE_START_TIMER_SWITCH_OFF"] = 0x7F
--PTC（电辅热）开
keyB["BYTE_PTC_ON"] = 0x08
--PTC（电辅热）关
keyB["BYTE_PTC_OFF"] = 0x00
--强劲风开
keyB["BYTE_STRONG_WIND_ON"] = 0x20
--强劲风关
keyB["BYTE_STRONG_WIND_OFF"] = 0x00
--舒睡开
keyB["BYTE_SLEEP_ON"] = 0x03
--舒睡关
keyB["BYTE_SLEEP_OFF"] = 0x00
--舒省开
keyB["BYTE_COMFORT_POWER_SAVE_ON"] = 0x01
--舒省关
keyB["BYTE_COMFORT_POWER_SAVE_OFF"] = 0x00

--设备控制命令
keyB["BYTE_CONTROL_PROPERTY_CMD"] = 0xB0

-------------------定义属性变量--------------------
local keyP = {}
keyP["powerValue"] = 0
keyP["modeValue"] = 0
keyP["temperature"] = 0
keyP["smallTemperature"] = 0
keyP["indoorTemperatureValue"] = 255
keyP["smallIndoorTemperatureValue"] = 0
keyP["outdoorTemperatureValue"] = 255
keyP["smallOutdoorTemperatureValue"] = 0
keyP["fanspeedValue"] = 0
keyP["closeTimerSwitch"] = 0
keyP["openTimerSwitch"] = 0
keyP["closeHour"] = 0
keyP["closeStepMintues"] = 0
keyP["closeMin"] = 0
keyP["closeTime"] = 0
keyP["openHour"] = 0
keyP["openStepMintues"] = 0
keyP["openMin"] = 0
keyP["openTime"] = 0
keyP["strongWindValue"] = 0
keyP["comfortableSleepValue"] = 0
keyP["PTCValue"] = 0
keyP["purifierValue"] = 0
keyP["ecoValue"] = 0
keyP["dryValue"] = 0
keyP["swingLRValueUpper"] = 0
keyP["swingLRValueUnder"] = 0
keyP["swingLRUnderSwitch"] = 0
keyP["swingUDValue"] = 0
keyP["currentWorkTime"] = 0
--美居之前就是默认开的
keyP["buzzerValue"] = 0x40
keyP["errorCode"] = 0
--是否踢被子
keyP["kickQuilt"]= 0
--防着凉
keyP["preventCold"] = 0
--舒省
keyP["comfortPowerSave"] = 0
--消息返回类型(查询返回，控制返回，主动上报)
local dataType = 0

--新协议，变长属性解析协议
keyP["propertyNumber"] = 0
keyP["prevent_super_cool"] = nil
keyP["prevent_straight_wind"] = nil
keyP["auto_prevent_straight_wind"] = nil
keyP["self_clean"] = nil
keyP["wind_straight"] = nil
keyP["wind_avoid"] = nil
keyP["intelligent_wind"] = nil
keyP["no_wind_sense"] = nil
keyP["child_prevent_cold_wind"] = nil
keyP["little_angel"] = nil
keyP["cool_hot_sense"] = nil
keyP["gentle_wind_sense"] = nil
keyP["security"] = nil


--无风感当前状态
local noWindSencePre = nil
---------------公共的函数 begin---------------
--打印 table 表
local function  print_lua_table(lua_table, indent)
    indent = indent or 0

    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end

        local szSuffix = ""

        if type(v) == "table" then
            szSuffix = "{"
        end

        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix.."["..k.."]".." = "..szSuffix

        if type(v) == "table" then
            print(formatting)

            print_lua_table(v, indent + 1)

            print(szPrefix.."},")
        else
            local szValue = ""

            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end

            print(formatting..szValue..",")
        end
    end
end

--检查取值是否超过边界
local function  checkBoundary(data, min, max)
    if (not data) then
        data = 0
    end

    data = tonumber(data)

    if(data == nil) then
        data = 0
    end

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

--table 转 string
local function  table2string(cmd)
    local ret = ""
    local i

    for i = 1, #cmd do
        ret = ret..string.char(cmd[i])
    end

    return ret
end

--十六进制 string 转 table
local function  string2table(hexstr)
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

--十六进制 string 输出
local function  string2hexstring(str)
    local ret = ""

    for i = 1, #str do
        ret = ret .. string.format("%02x", str:byte(i))
    end

    return ret
end

--table 转 json
local function  encode(cmd)
    local tb

    if JSON == nil then
        JSON = require "cjson"
    end

    tb = JSON.encode(cmd)

    return tb
end

--json 转 table
local function  decode(cmd)
    local tb

    if JSON == nil then
        JSON = require "cjson"
    end

    tb = JSON.decode(cmd)

    return tb
end

--sum校验
local function  makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0

    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]

        if resVal > 0xff then
            resVal = bit.band(resVal, 0xff)
        end
    end

    resVal = bit.band(255 - resVal + 1, 0xff)

    return resVal
end

--CRC表
local crc8_854_table =
{
    0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65,
    157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220,
    35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98,
    190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255,
    70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7,
    219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154,
    101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36,
    248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185,
    140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205,
    17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80,
    175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238,
    50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115,
    202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139,
    87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22,
    233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168,
    116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53
}

--CRC校验
local function  crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0

    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end

    return crc
end

---------------公共的函数 end---------------


-----------根据电控协议不同，需要改变的函数-------------
--根据 json 修改属性变量
local function  JsonToModel(jsonCmd)
    local streams = jsonCmd

    --蜂鸣，定时方式，遥控器端来源，电源
    if (streams[keyT["KEY_POWER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["powerValue"] = keyB["BYTE_POWER_ON"]
		keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_OFF"]
		keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
		keyP["PTCValue"] = keyB["BYTE_PTC_ON"]
		keyP["fanspeedValue"] = keyB["BYTE_FANSPEED_AUTO"]
    elseif (streams[keyT["KEY_POWER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["powerValue"] = keyB["BYTE_POWER_OFF"]
		keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_OFF"]
		keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
		keyP["PTCValue"] = keyB["BYTE_PTC_ON"]
		keyP["fanspeedValue"] = keyB["BYTE_FANSPEED_AUTO"]
    end

	--按键（按键有无用于决定空调器蜂鸣器是否发出声音）
	if (streams[keyT["KEY_BUZZER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["buzzerValue"] = keyB["BYTE_BUZZER_ON"]
    elseif (streams[keyT["KEY_BUZZER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["buzzerValue"] = keyB["BYTE_BUZZER_OFF"]
    end

    --净化
    if (streams[keyT["KEY_PURIFIER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["purifierValue"] = keyB["BYTE_PURIFIER_ON"]
    elseif (streams[keyT["KEY_PURIFIER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["purifierValue"] = keyB["BYTE_PURIFIER_OFF"]
    end

    --ECO
    if (streams[keyT["KEY_ECO"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["ecoValue"] = keyB["BYTE_ECO_ON"]
    elseif (streams[keyT["KEY_ECO"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["ecoValue"] = keyB["BYTE_ECO_OFF"]
    end

    --干燥
    if (streams[keyT["KEY_DRY"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["dryValue"] = keyB["BYTE_DRY_ON"]
    elseif (streams[keyT["KEY_DRY"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["dryValue"] = keyB["BYTE_DRY_OFF"]
    end

    --模式和温度
    if (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_HEAT"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_HEAT"]
		keyP["PTCValue"] = keyB["BYTE_PTC_ON"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_COOL"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_COOL"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_AUTO"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_AUTO"]
		keyP["PTCValue"] = keyB["BYTE_PTC_ON"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_DRY"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_DRY"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_FAN"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_FAN"]
    end

    --风速
    if (streams[keyT["KEY_FANSPEED"]] ~= nil) then
		keyP["fanspeedValue"] = checkBoundary(streams[keyT["KEY_FANSPEED"]], 1, 102)
    end

    --上下扫风
    if (streams[keyT["KEY_SWING_UD"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingUDValue"] = keyB["BYTE_SWING_UD_ON"]
    elseif (streams[keyT["KEY_SWING_UD"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingUDValue"] = keyB["BYTE_SWING_UD_OFF"]
    end

    --上左右扫风
    if (streams[keyT["KEY_SWING_LR_UPPER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingLRValueUpper"] = keyB["BYTE_SWING_LR_UPPER_ON"]
    elseif (streams[keyT["KEY_SWING_LR_UPPER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingLRValueUpper"] = keyB["BYTE_SWING_LR_UPPER_OFF"]
    end
    --下左右扫风
    keyP["swingLRUnderSwitch"] = keyB["BYTE_SWING_LR_UNDER_ENABLE"]
    if (streams[keyT["KEY_SWING_LR_UNDER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingLRValueUnder"] = keyB["BYTE_SWING_LR_UNDER_ON"]
    elseif (streams[keyT["KEY_SWING_LR_UNDER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingLRValueUnder"] = keyB["BYTE_SWING_LR_UNDER_OFF"]
    end

    --定时开
    if (streams[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_ON"]
    elseif (streams[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_OFF"]
    end

    --定时关
    if (streams[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]
    elseif (streams[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
    end

    --定时关机时间
    if (streams[keyT["KEY_CLOSE_TIME"]] ~= nil) then
        keyP["closeTime"] = streams[keyT["KEY_CLOSE_TIME"]]
    end

    --定时开机时间
    if (streams[keyT["KEY_OPEN_TIME"]] ~= nil) then
		keyP["openTime"] = streams[keyT["KEY_OPEN_TIME"]]
    end

    --电辅热
    if (streams[keyT["KEY_PTC"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["PTCValue"] = keyB["BYTE_PTC_ON"]
    elseif (streams[keyT["KEY_PTC"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["PTCValue"] = keyB["BYTE_PTC_OFF"]
    end

    --强劲
    if (streams[keyT["KEY_STRONG_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["strongWindValue"] = keyB["BYTE_STRONG_WIND_ON"]
    elseif (streams[keyT["KEY_STRONG_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["strongWindValue"] = keyB["BYTE_STRONG_WIND_OFF"]
    end

    --温度
    if (streams[keyT["KEY_TEMPERATURE"]] ~= nil) then
        keyP["temperature"] = checkBoundary(streams[keyT["KEY_TEMPERATURE"]], 17, 30)
    end

	--温度小数位(0/0.5)
	if(streams["small_temperature"] ~= nil) then
		keyP["smallTemperature"] = checkBoundary(streams["small_temperature"], 0, 0.5)
		if(keyP["smallTemperature"] == 0.5) then
			keyP["smallTemperature"] = 0x01
		else
			keyP["smallTemperature"] = 0x00
		end
	end

	--舒省
    if (streams[keyT["KEY_COMFORT_POWER_SAVE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["comfortPowerSave"] = keyB["BYTE_COMFORT_POWER_SAVE_ON"]
    elseif (streams[keyT["KEY_COMFORT_POWER_SAVE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["comfortPowerSave"] = keyB["BYTE_COMFORT_POWER_SAVE_OFF"]
    end

	--防过冷(快速降温，缓慢回温)
    if (streams[keyT["KEY_PREVENT_SUPER_COOL"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_PREVENT_SUPER_COOL"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["prevent_super_cool"] = 0x01
		elseif (streams[keyT["KEY_PREVENT_SUPER_COOL"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["prevent_super_cool"] = 0x00
		end
	end

	--防直吹
    if (streams[keyT["KEY_PREVENT_STRAIGHT_WIND"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		keyP["prevent_straight_wind"] = checkBoundary(streams[keyT["KEY_PREVENT_STRAIGHT_WIND"]], 0, 2)
	end

	--自动防直吹
    if (streams[keyT["KEY_AUTO_PREVENT_STRAIGHT_WIND"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_AUTO_PREVENT_STRAIGHT_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["auto_prevent_straight_wind"] = 0x01
		elseif (streams[keyT["KEY_AUTO_PREVENT_STRAIGHT_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["auto_prevent_straight_wind"] = 0x00
		end
	end

	--自清洁
    if (streams[keyT["KEY_SELF_CLEAN"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_SELF_CLEAN"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["self_clean"] = 0x01
		elseif (streams[keyT["KEY_SELF_CLEAN"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["self_clean"] = 0x00
		end
	end

	--风吹人
    if (streams[keyT["KEY_WIND_STRAIGHT"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_WIND_STRAIGHT"]] == keyV["VALUE_FUNCTION_ON"]) then
			keyP["wind_straight"] = 0x01
		elseif (streams[keyT["KEY_WIND_STRAIGHT"]] == keyV["VALUE_FUNCTION_OFF"]) then
			keyP["wind_straight"] = 0x00
		end
	end

	--风避人
    if (streams[keyT["KEY_WIND_AVOID"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_WIND_AVOID"]] == keyV["VALUE_FUNCTION_ON"]) then
			keyP["wind_avoid"] = 0x01
		elseif (streams[keyT["KEY_WIND_AVOID"]] == keyV["VALUE_FUNCTION_OFF"]) then
			keyP["wind_avoid"] = 0x00
		end
	end

	--智慧风
    if (streams[keyT["KEY_INTELLIGENT_WIND"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_INTELLIGENT_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["intelligent_wind"] = 0x01
		elseif (streams[keyT["KEY_INTELLIGENT_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["intelligent_wind"] = 0x00
		end
	end

	--无风感
    if (streams[keyT["KEY_NO_WIND_SENSE"]] ~= nil) then
		if (deviceSN8 == "12035") then
			keyP["propertyNumber"] = keyP["propertyNumber"] + 1
			keyP["no_wind_sense"] = checkBoundary(streams[keyT["KEY_NO_WIND_SENSE"]], 0, 5)
		else
			if (noWindSencePre == nil) then
				noWindSencePre = checkBoundary(streams[keyT["KEY_NO_WIND_SENSE"]], 0, 5)
				keyP["propertyNumber"] = keyP["propertyNumber"] + 1
				keyP["no_wind_sense"] = checkBoundary(streams[keyT["KEY_NO_WIND_SENSE"]], 0, 5)
			else
				keyP["no_wind_sense"] = checkBoundary(streams[keyT["KEY_NO_WIND_SENSE"]], 0, 5)
				if (noWindSencePre == 2) then
					if (streams[keyT["KEY_NO_WIND_SENSE"]] == 3) then
						keyP["no_wind_sense"] = 1
					end
				end
				if (noWindSencePre == 3) then
					if (streams[keyT["KEY_NO_WIND_SENSE"]] == 2) then
						keyP["no_wind_sense"] = 1
					end
				end
				if (noWindSencePre == 1) then
					if (streams[keyT["KEY_NO_WIND_SENSE"]] == 5) then
						keyP["no_wind_sense"] = 2
					end
				end
				if (noWindSencePre == 1) then
					if (streams[keyT["KEY_NO_WIND_SENSE"]] == 4) then
						keyP["no_wind_sense"] = 3
					end
				end
				if (noWindSencePre == 2) then
					if (streams[keyT["KEY_NO_WIND_SENSE"]] == 4) then
						keyP["no_wind_sense"] = 0
					end
				end
				if (noWindSencePre == 3) then
					if (streams[keyT["KEY_NO_WIND_SENSE"]] == 5) then
						keyP["no_wind_sense"] = 0
					end
				end
			end
		end
	end

	--儿童防冷风
    if (streams[keyT["KEY_CHILD_PREVENT_COLD_WIND"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_CHILD_PREVENT_COLD_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["child_prevent_cold_wind"] = 0x01
		elseif (streams[keyT["KEY_CHILD_PREVENT_COLD_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["child_prevent_cold_wind"] = 0x00
		end
	end

	--小天使
    if (streams[keyT["KEY_LITTLE_ANGLE"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_LITTLE_ANGLE"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["little_angel"] = 0x01
		elseif (streams[keyT["KEY_LITTLE_ANGLE"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["little_angel"] = 0x00
		end
	end

	--冷热感
    if (streams[keyT["KEY_COOL_HOT_SENSE"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_COOL_HOT_SENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["cool_hot_sense"] = 0x01
		elseif (streams[keyT["KEY_COOL_HOT_SENSE"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["cool_hot_sense"] = 0x00
		end
	end

	--柔风感
    if (streams[keyT["KEY_GENTLE_WIND_SENSE"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_GENTLE_WIND_SENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
		keyP["gentle_wind_sense"] = 0x03
		elseif (streams[keyT["KEY_GENTLE_WIND_SENSE"]] == keyV["VALUE_FUNCTION_OFF"]) then
		keyP["gentle_wind_sense"] = 0x01
		end
	end

	--安防
	if (streams[keyT["KEY_SECURITY"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_SECURITY"]] == keyV["VALUE_FUNCTION_ON"]) then
			keyP["security"] = 0x01
		elseif (streams[keyT["KEY_SECURITY"]] == keyV["VALUE_FUNCTION_OFF"]) then
			keyP["security"] = 0x00
		end
	end

	--屏显
	if (streams[keyT["KEY_SCREEN_DISPLAY"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		if (streams[keyT["KEY_SCREEN_DISPLAY"]] == keyV["VALUE_FUNCTION_ON"]) then
			keyP["screen_display"] = 0x64
		elseif (streams[keyT["KEY_SCREEN_DISPLAY"]] == keyV["VALUE_FUNCTION_OFF"]) then
			keyP["screen_display"] = 0x00
		end
	end
end

--根据 bin 修改属性变量
local function  binToModel(binData)

    local messageBytes = binData

    if ((dataType==0x02 and messageBytes[0] == 0xC0)or (dataType==0x03 and messageBytes[0] == 0xC0) or (dataType==0x05 and messageBytes[0] == 0xA0)) then
		if(#binData < 21) then
			return nil
		end
		keyP["powerValue"] = bit.band(messageBytes[1], 0x01)
        keyP["modeValue"] = bit.band(messageBytes[2], 0xE0)

        if(dataType == 0x05) then
            --CA机型 11447、11451、11453、11455、11457、11459、11525、11527、11533、11535
            if deviceSN8=="11447" or deviceSN8=="11451" or deviceSN8=="11453" or deviceSN8=="11455" or deviceSN8=="11457" or deviceSN8=="11459" or deviceSN8=="11525" or deviceSN8=="11527" or deviceSN8=="11533" or deviceSN8=="11535" then
                keyP["temperature"] = bit.rshift(bit.band(messageBytes[1], 0x7C), 2) + 0x0C
                keyP["smallTemperature"] = bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            else
                keyP["temperature"] = bit.rshift(bit.band(messageBytes[1], 0x3E), 1) + 0x0C
                keyP["smallTemperature"] = bit.rshift(bit.band(messageBytes[1], 0x40), 6)
            end
        else
            keyP["temperature"] = bit.band(messageBytes[2], 0x0F) + 0x10
			keyP["smallTemperature"] = bit.rshift(bit.band(messageBytes[2], 0x10),4)
        end

        keyP["fanspeedValue"] = bit.band(messageBytes[3], 0x7F)

        if (bit.band(messageBytes[4], keyB["BYTE_START_TIMER_SWITCH_ON"]) == keyB["BYTE_START_TIMER_SWITCH_ON"]) then
            keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_ON"]
        else
           keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_OFF"]
        end

        if (bit.band(messageBytes[5], keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) == keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
            keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]
        else
            keyP["closeTimerSwitch"] = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
        end

        keyP["closeHour"] = bit.rshift(bit.band(messageBytes[5], 0x7F), 2)

        keyP["closeStepMintues"] = bit.band(messageBytes[5], 0x03)

        keyP["closeMin"] = 15 - bit.band(messageBytes[6], 0x0f)

        keyP["closeTime"] = keyP["closeHour"] * 60 + keyP["closeStepMintues"] * 15 + keyP["closeMin"]

        keyP["openHour"] = bit.rshift(bit.band(messageBytes[4], 0x7F), 2)

        keyP["openStepMintues"] = bit.band(messageBytes[4], 0x03)

        keyP["openMin"] = 15 - bit.rshift(bit.band(messageBytes[6], 0xf0),4)

        keyP["openTime"] = keyP["openHour"] * 60 + keyP["openStepMintues"] * 15 + keyP["openMin"]

        keyP["strongWindValue"] = bit.band(messageBytes[8], 0x20)

        keyP["comfortableSleepValue"] = bit.band(messageBytes[8], 0x03)

        keyP["PTCValue"] = bit.band(messageBytes[9], 0x18)

        keyP["purifierValue"] = bit.band(messageBytes[9], 0x20)

        keyP["ecoValue"] = bit.lshift(bit.band(messageBytes[9], 0x10), 3)

        keyP["dryValue"] = bit.band(messageBytes[9], 0x04)

        keyP["swingLRValueUpper"] = bit.band(messageBytes[7], 0x03)
        keyP["swingLRUnderSwitch"] = bit.band(messageBytes[19], 0x80)
        keyP["swingLRValueUnder"] = bit.band(messageBytes[20], 0x80)

        keyP["swingUDValue"] = bit.band(messageBytes[7], 0x0C)

        if(dataType == 0x02 or dataType == 0x03) then
            if ((messageBytes[11] ~= 0) and (messageBytes[11] ~= 0xFF)) then
                keyP["indoorTemperatureValue"] = (messageBytes[11] - 50) / 2
                keyP["smallIndoorTemperatureValue"]=bit.band(messageBytes[15],0xF);
            end

            if ((messageBytes[12] ~= 0) and (messageBytes[12] ~= 0xFF)) then
                keyP["outdoorTemperatureValue"]  = (messageBytes[12] - 50) / 2
                keyP["smallOutdoorTemperatureValue"]=bit.rshift(messageBytes[15],4);
            end
        end

        keyP["errorCode"]=messageBytes[16]

		--是否踢被子
		keyP["kickQuilt"] = bit.rshift(bit.band(messageBytes[10], 0x04),2)

		--防着凉
		keyP["preventCold"] = bit.rshift(bit.band(messageBytes[10], 0x08),3)

		--舒省
		if(#binData >= 22) then
			keyP["comfortPowerSave"] = bit.band(messageBytes[22], 0x01)
		end
    end
    if ((dataType==0x04 and messageBytes[0] == 0xA1)) then
        --本次开机运行时间
		keyP["currentWorkTime"] = bit.bor((bit.band(bit.lshift(messageBytes[9],8), 0xFF00)),(bit.band(messageBytes[10], 0x00FF))) * 60 * 24 + messageBytes[11] * 60 + messageBytes[12]

		--计算方式由空调事业部黑继伟提供
        if (messageBytes[13]~=0x00 and messageBytes[13]~=0xff) then
            keyP["indoorTemperatureValue"] = (messageBytes[13]-50)/2
            keyP["smallIndoorTemperatureValue"]=bit.band(messageBytes[18],0xF);
        end
        if (messageBytes[14]~=0x00 and messageBytes[14]~=0xff) then
            keyP["outdoorTemperatureValue"]  = (messageBytes[14]-50)/2
            keyP["smallOutdoorTemperatureValue"]=bit.rshift(messageBytes[18],4);
        end
    end

    if ((dataType==0x02 and messageBytes[0] == 0xB0) or (dataType==0x03 and messageBytes[0] == 0xB1)) then
        --新协议，变长属性协议
		if(#binData < 8) then
			return nil
		end
		keyP["propertyNumber"] = messageBytes[1]
		local cursor = 2
        for i = 1,  keyP["propertyNumber"] do
			if (messageBytes[cursor + 0] == 0x46 and messageBytes[cursor + 1] == 0x00) then
				keyP["prevent_super_cool"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x49 and messageBytes[cursor + 1] == 0x00) then
				keyP["prevent_straight_wind"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x26 and messageBytes[cursor + 1] == 0x02) then
				keyP["auto_prevent_straight_wind"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x39 and messageBytes[cursor + 1] == 0x00) then
				keyP["self_clean"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x32 and messageBytes[cursor + 1] == 0x00) then
				keyP["wind_straight"] = messageBytes[cursor + 4]
				if (deviceSN8 == "50939" or deviceSN8 == "51001" or deviceSN8 == "Z1304") then
					if (messageBytes[cursor + 4] == 2) then
						keyP["wind_avoid"] = 1
					end
				end
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x33 and messageBytes[cursor + 1] == 0x00) then
				if (deviceSN8 == "50939" or deviceSN8 == "51001" or deviceSN8 == "Z1304") then
					keyP["intelligent_wind"] = messageBytes[cursor + 4]
				else
					keyP["wind_avoid"] = messageBytes[cursor + 4]
				end
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x34 and messageBytes[cursor + 1] == 0x00) then
				keyP["intelligent_wind"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x3A and messageBytes[cursor + 1] == 0x00) then
				keyP["child_prevent_cold_wind"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x17 and messageBytes[cursor + 1] == 0x00) then
				keyP["screen_display"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x18 and messageBytes[cursor + 1] == 0x00) then
				keyP["no_wind_sense"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x1B and messageBytes[cursor + 1] == 0x02) then
				keyP["little_angel"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x21 and messageBytes[cursor + 1] == 0x00) then
				keyP["cool_hot_sense"] = messageBytes[cursor + 4]
				cursor = cursor + 12
			end
			if (messageBytes[cursor + 0] == 0x29 and messageBytes[cursor + 1] == 0x00) then
				keyP["security"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x43 and messageBytes[cursor + 1] == 0x00) then
				if (messageBytes[cursor + 4] == 0x01) then
					keyP["gentle_wind_sense"] = 0x01
					keyP["prevent_straight_wind"] = 0x01
					keyP["no_wind_sense"] = 0x00
				end
				if (messageBytes[cursor + 4] == 0x02) then
					keyP["prevent_straight_wind"] = 0x02
				end
				if (messageBytes[cursor + 4] == 0x03) then
					keyP["gentle_wind_sense"] = 0x03
				end
				if (messageBytes[cursor + 4] == 0x04) then
					keyP["no_wind_sense"] = 0x01
				end
				cursor = cursor + 5
			end
        end
    end
end

local function  getTotalMsg(bodyData,cType)
    local bodyLength = #bodyData

    local msgLength = bodyLength + keyB["BYTE_PROTOCOL_LENGTH"] + 1

    local msgBytes = {}

    for i = 0, msgLength do
        msgBytes[i] = 0
    end

    --构造消息部分
    msgBytes[0] = keyB["BYTE_PROTOCOL_HEAD"]

    msgBytes[1] = bodyLength + keyB["BYTE_PROTOCOL_LENGTH"] + 1

    msgBytes[2] = keyB["BYTE_DEVICE_TYPE"]

    if (keyP["propertyNumber"] > 0) then
		msgBytes[8] = 0x02
	end
    msgBytes[9] = cType

    -- body
    for i = 0, bodyLength do
        msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]] = bodyData[i]
    end

    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)

    local msgFinal = {}

    for i = 1, msgLength + 1  do
        msgFinal[i] = msgBytes[i - 1]
    end
    return msgFinal
end

--json转二进制，可传入原状态
function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then
        return nil
    end

    local infoM = {}
    local bodyBytes = {}

    local json = decode(jsonCmd)
    deviceSubType = json["deviceinfo"]["deviceSubType"]
    local deviceSN=json["deviceinfo"]["deviceSN"]
    if deviceSN~=nil then
        deviceSN8=string.sub(deviceSN,13,17)
    end

    local query = json["query"]
    local control = json["control"]
    local status = json["status"]

    --当前是查询指令，构造固定的二进制即可
    if (query) then
        --构造消息 body 部分
		local queryType = nil
		if (type(query) == "table") then
			queryType = query["query_type"]
		end
		if (queryType == nil) then
			for i = 0, 21 do
				bodyBytes[i] = 0
			end

			bodyBytes[0] = 0x41

			bodyBytes[1] = 0x81

			bodyBytes[3] = 0xFF

			math.randomseed(tostring(os.time()*#bodyBytes):reverse():sub(1, 7))
			math.random()
			bodyBytes[20] = math.random(1, 254)

			bodyBytes[21] = crc8_854(bodyBytes, 0, 20)

			infoM = getTotalMsg(bodyBytes,keyB["BYTE_QUERYL_REQUEST"])
		elseif (queryType == "power"
				or queryType == "purifier"
				or queryType == "mode"
				or queryType == "temperature"
				or queryType == "small_temperature"
				or queryType == "buzzer"
				or queryType == "wind_swing_lr"
				or queryType == "wind_swing_ud"
				or queryType == "wind_speed"
				or queryType == "power_on_timer"
				or queryType == "power_off_timer"
				or queryType == "power_on_time_value"
				or queryType == "power_off_time_value"
				or queryType == "indoor_temperature"
				or queryType == "outdoor_temperature"
				or queryType == "eco"
				or queryType == "kick_quilt"
				or queryType == "prevent_cold"
				or queryType == "dry"
				or queryType == "ptc"
				or queryType == "screen_display"
				or queryType == "strong_wind"
				or queryType == "current_work_time"
				or queryType == "comfort_power_save"
				) then
			for i = 0, 21 do
				bodyBytes[i] = 0
			end

			bodyBytes[0] = 0x41

			bodyBytes[1] = 0x81

			bodyBytes[3] = 0xFF

			math.randomseed(tostring(os.time()*#bodyBytes):reverse():sub(1, 7))
			math.random()
			bodyBytes[20] = math.random(1, 254)

			bodyBytes[21] = crc8_854(bodyBytes, 0, 20)

			infoM = getTotalMsg(bodyBytes,keyB["BYTE_QUERYL_REQUEST"])

		else
			bodyBytes[0] = 0xB1

			local propertyNum = 0
			if (queryType == "no_wind_sense") then
				if (deviceSN8 == "12035") then
				bodyBytes[1 + propertyNum * 2 + 1] = 0x43
				else
					bodyBytes[1 + propertyNum * 2 + 1] = 0x18
				end
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
			if (queryType == "self_clean") then
				bodyBytes[1 + propertyNum * 2 + 1] = 0x39
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

			bodyBytes[1] = propertyNum

			math.randomseed(tostring(os.time()*#bodyBytes):reverse():sub(1, 7))
			math.random()
			bodyBytes[1 + propertyNum * 2 + 1] = math.random(1, 254)

			bodyBytes[1 + propertyNum * 2 + 2] = crc8_854(bodyBytes, 0, 1 + propertyNum * 2 + 1)

			infoM = getTotalMsg(bodyBytes,keyB["BYTE_QUERYL_REQUEST"])
		end
    elseif (control) then
        --先将原始状态转换为属性
        if (status) then
            JsonToModel(status)
        end
        --将用户控制 json 转换为属性
        if (control) then
			local retStr = "aa23ac0000000000000341c100ff02ff020200000000000000000000000000000003c95c"
			if((control[keyT["KEY_SCREEN_DISPLAY"]] ~= nil) and (deviceSN8 ~= "12035") and (deviceSN8 ~= "50939") and (deviceSN8 ~= "51001") and (deviceSN8 ~= "Z1304")) then
				return retStr
			end
            JsonToModel(control)
        end

        --构造消息 body 部分
        if (keyP["propertyNumber"] == 0) then
		--常规协议
		for i = 0, 25 do
            bodyBytes[i] = 0
        end

        bodyBytes[0] = keyB["BYTE_CONTROL_CMD"]
		if(keyP["buzzerValue"] ~= nil) then
			bodyBytes[1] = bit.bor(bit.bor(keyP["powerValue"], keyB["BYTE_CLIENT_MODE_MOBILE"]), bit.bor(keyB["BYTE_TIMER_METHOD_REL"], keyP["buzzerValue"]))
		else
			bodyBytes[1] = bit.bor(bit.bor(keyP["powerValue"], keyB["BYTE_CLIENT_MODE_MOBILE"]),bit.bor(keyB["BYTE_TIMER_METHOD_REL"],0x40))
		end

        --bodyBytes[2] = bit.bor(bit.band(keyP["modeValue"], 0xE0), bit.band(0x0F, (keyP["temperature"] - 0x10)))

		bodyBytes[2] = bit.bor(bit.bor(bit.band(keyP["modeValue"], 0xE0), bit.band(0x0F, (keyP["temperature"] - 0x10))),bit.lshift(bit.band(keyP["smallTemperature"], 0x01),4))

        bodyBytes[3] = bit.bor(keyP["fanspeedValue"], keyB["BYTE_TIMER_SWITCH_ON"])

        if (keyP["closeTime"] == nil) then
            keyP["closeTime"] = 0
        end

        keyP["closeHour"] = math.floor(keyP["closeTime"] / 60)

        keyP["closeStepMintues"] = math.floor((keyP["closeTime"] % 60) / 15)

        keyP["closeMin"] = math.floor(((keyP["closeTime"] % 60) % 15))

        if (keyP["openTime"] == nil) then
            keyP["openTime"] = 0
        end

        keyP["openHour"] = math.floor(keyP["openTime"] / 60)

        keyP["openStepMintues"] = math.floor((keyP["openTime"] % 60) / 15)

        keyP["openMin"] = math.floor(((keyP["openTime"] % 60) % 15))

        if (keyP["openTimerSwitch"] == keyB["BYTE_START_TIMER_SWITCH_ON"]) then
            bodyBytes[4] = bit.bor(bit.bor(keyP["openTimerSwitch"], bit.lshift(keyP["openHour"], 2)), keyP["openStepMintues"])
        elseif (keyP["openTimerSwitch"] == keyB["BYTE_START_TIMER_SWITCH_OFF"] ) then
            bodyBytes[4] = 0x7F
        end

        if (keyP["closeTimerSwitch"] == keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
            bodyBytes[5] = bit.bor(bit.bor(keyP["closeTimerSwitch"], bit.lshift(keyP["closeHour"], 2)), keyP["closeStepMintues"])
        elseif (keyP["closeTimerSwitch"] == keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
            bodyBytes[5] = 0x7F
        end

        bodyBytes[6] = bit.bor(bit.lshift((15 - keyP["openMin"]), 4), (15 - keyP["closeMin"]))

        bodyBytes[7] = bit.bor(bit.bor(keyP["swingLRValueUpper"], keyP["swingUDValue"]), 0x30)

        bodyBytes[8] = bit.bor(keyP["strongWindValue"], keyP["comfortableSleepValue"])

        bodyBytes[9] = bit.bor(bit.bor(keyP["purifierValue"], keyP["ecoValue"]), bit.bor(keyP["dryValue"], keyP["PTCValue"]))
	if (control["ptc"] ~= nil) then
		bodyBytes[9] = bit.bor(bodyBytes[9], 0x10)
	end
        bodyBytes[19] = bit.bor(keyP["swingLRUnderSwitch"], bodyBytes[19])
        bodyBytes[20] = bit.bor(keyP["swingLRValueUnder"], bodyBytes[20])
        if (keyP["comfortPowerSave"] == keyB["BYTE_COMFORT_POWER_SAVE_ON"]) then
            bodyBytes[22] = 0x01
        elseif (keyP["comfortPowerSave"] == keyB["BYTE_COMFORT_POWER_SAVE_OFF"] ) then
            bodyBytes[22] = 0x00
        end

		math.randomseed(tostring(os.time()*#bodyBytes):reverse():sub(1, 7))
        math.random()
        bodyBytes[24] = math.random(1, 254)

        bodyBytes[25] = crc8_854(bodyBytes, 0, 24)

		else
			--新协议，属性变长协议
			bodyBytes[0] = keyB["BYTE_CONTROL_PROPERTY_CMD"]
			bodyBytes[1] = keyP["propertyNumber"]
			local cursor = 2
			if(keyP["prevent_super_cool"] ~= nil) then
				bodyBytes[cursor + 0] = 0x46
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["prevent_super_cool"]
				cursor = cursor + 4
			end
			if(keyP["prevent_straight_wind"] ~= nil) then
				--FA100特殊处理
				if (deviceSN8 == "12035") then
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
					bodyBytes[cursor + 0] = 0x49
					bodyBytes[cursor + 1] = 0x00
					bodyBytes[cursor + 2] = 0x01
					bodyBytes[cursor + 3] = keyP["prevent_straight_wind"]
					cursor = cursor + 4
				end
			end
			if(keyP["auto_prevent_straight_wind"] ~= nil) then
				bodyBytes[cursor + 0] = 0x26
				bodyBytes[cursor + 1] = 0x02
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["auto_prevent_straight_wind"]
				cursor = cursor + 4
			end
			if(keyP["self_clean"] ~= nil) then
				bodyBytes[cursor + 0] = 0x39
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["self_clean"]
				cursor = cursor + 4
			end
			if(keyP["wind_straight"] ~= nil) then
				bodyBytes[cursor + 0] = 0x32
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["wind_straight"]
				cursor = cursor + 4
			end
			if(keyP["wind_avoid"] ~= nil) then
				bodyBytes[cursor + 0] = 0x33
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["wind_avoid"]
				if ((deviceSN8 == "50939") or (deviceSN8 == "51001") or (deviceSN8 == "Z1304")) then
					bodyBytes[cursor + 0] = 0x32
					if ( keyP["wind_avoid"] == 1) then
						bodyBytes[cursor + 3] = 0x02
					end
				end
				cursor = cursor + 4
			end
			if(keyP["intelligent_wind"] ~= nil) then
				bodyBytes[cursor + 0] = 0x34
				if ((deviceSN8 == "50939") or (deviceSN8 == "51001") or (deviceSN8 == "Z1304")) then
					bodyBytes[cursor + 0] = 0x33
				end
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["intelligent_wind"]
				cursor = cursor + 4
			end
			if(keyP["no_wind_sense"] ~= nil) then
				--FA100特殊处理
				if (deviceSN8 == "12035") then
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
				else
					bodyBytes[cursor + 0] = 0x18
					bodyBytes[cursor + 1] = 0x00
					bodyBytes[cursor + 2] = 0x01
					bodyBytes[cursor + 3] = keyP["no_wind_sense"]
					cursor = cursor + 4
				end
			end
			if(keyP["child_prevent_cold_wind"] ~= nil) then
				bodyBytes[cursor + 0] = 0x3A
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["child_prevent_cold_wind"]
				cursor = cursor + 4
			end
			if(keyP["little_angel"] ~= nil) then
				bodyBytes[cursor + 0] = 0x1B
				bodyBytes[cursor + 1] = 0x02
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["little_angel"]
				cursor = cursor + 4
			end
			if(keyP["cool_hot_sense"] ~= nil) then
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
			if(keyP["gentle_wind_sense"] ~= nil) then
				bodyBytes[cursor + 0] = 0x43
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["gentle_wind_sense"]
				cursor = cursor + 4
			end
			if(keyP["security"] ~= nil) then
				bodyBytes[cursor + 0] = 0x29
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["security"]
				cursor = cursor + 4
			end
			if(keyP["screen_display"] ~= nil) then
				bodyBytes[cursor + 0] = 0x17
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["screen_display"]
				cursor = cursor + 4
			end
			if(keyP["buzzerValue"] ~= nil) then
				bodyBytes[cursor + 0] = 0x1A
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = 0x00
				if(keyP["buzzerValue"] == 0x40) then
				bodyBytes[cursor + 3] = 0x01
				end
				cursor = cursor + 4
				bodyBytes[1] = keyP["propertyNumber"] + 1
			end
	        math.randomseed(tostring(os.time()*#bodyBytes):reverse():sub(1, 7))
			math.random()
			bodyBytes[cursor] = math.random(1, 254)

			bodyBytes[cursor + 1] = crc8_854(bodyBytes, 0, cursor)
		end
        --构造消息部分
        infoM = getTotalMsg(bodyBytes,keyB["BYTE_CONTROL_REQUEST"])
    end
	keyP["propertyNumber"] = 0
	keyP["prevent_super_cool"] = nil
	keyP["prevent_straight_wind"] = nil
	keyP["auto_prevent_straight_wind"] = nil
	keyP["wind_straight"] = nil
	keyP["wind_avoid"] = nil
	keyP["intelligent_wind"] = nil
	keyP["self_clean"] = nil
	keyP["no_wind_sense"] = nil
	keyP["child_prevent_cold_wind"] = nil
	keyP["little_angel"] = nil
	keyP["cool_hot_sense"] = nil
	keyP["gentle_wind_sense"] = nil
	keyP["prevent_straight_wind_fa"] = nil
	keyP["security"] = nil
	keyP["screen_display"] = nil
	keyP["buzzerValue"] = nil
	noWindSencePre = nil

    --table 转换成 string 之后返回
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
	return ret
end


--二进制转json
function dataToJson(jsonCmd)
    if (not jsonCmd) then
        return nil
    end

    local json = decode(jsonCmd)
    local deviceinfo = json["deviceinfo"]
    deviceSubType = deviceinfo["deviceSubType"]
    local deviceSN=json["deviceinfo"]["deviceSN"]
    if deviceSN~=nil then
        deviceSN8=string.sub(deviceSN,13,17)
    end

    local status = json["status"]
    if (status) then
        JsonToModel(status)
    end

    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0

    info = string2table(binData)

    dataType=info[10];

    for i = 1, #info do
        msgBytes[i - 1] = info[i]
    end

    msgLength = msgBytes[1]
    bodyLength = msgLength - keyB["BYTE_PROTOCOL_LENGTH"] - 1

    --获取 body 部分
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]]
    end

    --将二进制状态解析为属性值
    binToModel(bodyBytes)

    --将属性值转换为最终 table
    local streams = {}

    --版本
    streams[keyT["KEY_VERSION"]] = keyV["VALUE_VERSION"]

    if (keyP["propertyNumber"] == 0) then
    --处理常规协议

	--电源
    if (keyP["powerValue"] == keyB["BYTE_POWER_ON"]) then
        streams[keyT["KEY_POWER"]] = keyV["VALUE_FUNCTION_ON"]
    elseif (keyP["powerValue"] == keyB["BYTE_POWER_OFF"]) then
        streams[keyT["KEY_POWER"]] = keyV["VALUE_FUNCTION_OFF"]
    end

    --模式
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
    end

    --净化
    if (keyP["purifierValue"] == keyB["BYTE_PURIFIER_ON"]) then
        streams[keyT["KEY_PURIFIER"]] = keyV["VALUE_FUNCTION_ON"]
    elseif (keyP["purifierValue"] == keyB["BYTE_PURIFIER_OFF"]) then
        streams[keyT["KEY_PURIFIER"]] = keyV["VALUE_FUNCTION_OFF"]
    end

    --ECO
    if (keyP["ecoValue"] == keyB["BYTE_ECO_ON"]) then
        streams[keyT["KEY_ECO"]] = keyV["VALUE_FUNCTION_ON"]
    elseif (keyP["ecoValue"] == keyB["BYTE_ECO_OFF"]) then
        streams[keyT["KEY_ECO"]] = keyV["VALUE_FUNCTION_OFF"]
    end

    --干燥
    if (keyP["dryValue"] == keyB["BYTE_DRY_ON"]) and ((keyP["modeValue"] == keyB["BYTE_MODE_COOL"]) or (keyP["modeValue"] == keyB["BYTE_MODE_DRY"])) then
        streams[keyT["KEY_DRY"]] = keyV["VALUE_FUNCTION_ON"]
    else
        streams[keyT["KEY_DRY"]] = keyV["VALUE_FUNCTION_OFF"]
    end

    --风速
    streams[keyT["KEY_FANSPEED"]] = keyP["fanspeedValue"]

    --室外温度
    streams[keyV["VALUE_OUTDOOR_TEMPERATURE"]] = keyP["outdoorTemperatureValue"] +keyP["smallOutdoorTemperatureValue"]/10

    --室内温度
    streams[keyV["VALUE_INDOOR_TEMPERATURE"]] = keyP["indoorTemperatureValue"]+keyP["smallIndoorTemperatureValue"]/10

    --上下扫风
    if (keyP["swingUDValue"] == keyB["BYTE_SWING_UD_ON"]) then
        streams[keyT["KEY_SWING_UD"]] = keyV["VALUE_FUNCTION_ON"]
    elseif (keyP["swingUDValue"] == keyB["BYTE_SWING_UD_OFF"]) then
        streams[keyT["KEY_SWING_UD"]] = keyV["VALUE_FUNCTION_OFF"]
    end

    --上左右扫风
    if (keyP["swingLRValueUpper"] == keyB["BYTE_SWING_LR_UPPER_ON"]) then
        streams[keyT["KEY_SWING_LR_UPPER"]] = keyV["VALUE_FUNCTION_ON"]
    elseif (keyP["swingLRValueUpper"] == keyB["BYTE_SWING_LR_UPPER_OFF"]) then
        streams[keyT["KEY_SWING_LR_UPPER"]] = keyV["VALUE_FUNCTION_OFF"]
    end
    --下左右扫风
    if (keyP["swingLRUnderSwitch"] == keyB["BYTE_SWING_LR_UNDER_ENABLE"]) then
	if (keyP["swingLRValueUnder"] == keyB["BYTE_SWING_LR_UNDER_ON"]) then
		streams[keyT["KEY_SWING_LR_UNDER"]] = keyV["VALUE_FUNCTION_ON"]
	elseif (keyP["swingLRValueUnder"] == keyB["BYTE_SWING_LR_UNDER_OFF"]) then
		streams[keyT["KEY_SWING_LR_UNDER"]] = keyV["VALUE_FUNCTION_OFF"]
	end
    else
	streams[keyT["KEY_SWING_LR_UNDER"]] = streams[keyT["KEY_SWING_LR_UPPER"]]
    end
    --电辅热
    if (keyP["PTCValue"] == keyB["BYTE_PTC_ON"]) and ((keyP["modeValue"] == keyB["BYTE_MODE_AUTO"]) or (keyP["modeValue"] == keyB["BYTE_MODE_HEAT"])) then
        streams[keyT["KEY_PTC"]] = keyV["VALUE_FUNCTION_ON"]
    elseif (keyP["PTCValue"] == keyB["BYTE_PTC_OFF"]) then
			streams[keyT["KEY_PTC"]] = keyV["VALUE_FUNCTION_OFF"]
		end

		--定时开
		if (keyP["openTimerSwitch"] == keyB["BYTE_START_TIMER_SWITCH_ON"]) then
			streams[keyT["KEY_TIME_ON"]] = keyV["VALUE_FUNCTION_ON"]
		elseif (keyP["openTimerSwitch"] == keyB["BYTE_START_TIMER_SWITCH_OFF"]) then
				streams[keyT["KEY_TIME_ON"]] = keyV["VALUE_FUNCTION_OFF"]
		end

		--定时关
		if (keyP["closeTimerSwitch"] == keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
			streams[keyT["KEY_TIME_OFF"]] = keyV["VALUE_FUNCTION_ON"]
		elseif (keyP["closeTimerSwitch"] == keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
			streams[keyT["KEY_TIME_OFF"]] = keyV["VALUE_FUNCTION_OFF"]
    end

    --定时关机时间
    if (keyP["closeTimerSwitch"] == keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
        streams[keyT["KEY_CLOSE_TIME"]] = 0
    else
        streams[keyT["KEY_CLOSE_TIME"]] = keyP["closeTime"]
    end

    --定时开机时间
    if (keyP["openTimerSwitch"] == keyB["BYTE_START_TIMER_SWITCH_OFF"]) then
        streams[keyT["KEY_OPEN_TIME"]] = 0
    else
        streams[keyT["KEY_OPEN_TIME"]] = keyP["openTime"]
    end

    --本次开机运行时间
    streams[keyT["KEY_CURRENT_WORK_TIME"]] = keyP["currentWorkTime"]

	--强劲
    if (keyP["strongWindValue"] == keyB["BYTE_STRONG_WIND_ON"]) then
        streams[keyT["KEY_STRONG_WIND"]] = keyV["VALUE_FUNCTION_ON"]
    elseif (keyP["strongWindValue"] == keyB["BYTE_STRONG_WIND_OFF"]) then
        streams[keyT["KEY_STRONG_WIND"]] = keyV["VALUE_FUNCTION_OFF"]
    end

	--温度
    streams[keyT["KEY_TEMPERATURE"] ]= keyP["temperature"]

	--温度小数位
	if(keyP["smallTemperature"] == 0x01) then
		streams["small_temperature"] = 0.5
	else
		streams["small_temperature"] = 0
	end


    streams[keyT["KEY_ERROR_CODE"]]=keyP["errorCode"]

	--是否踢被子
	if(keyP["kickQuilt"] == 0x00) then
		streams["kick_quilt"] = "off"
	elseif(keyP["kickQuilt"] == 0x01) then
		streams["kick_quilt"] = "on"
	end

	--舒省
	if(keyP["comfortPowerSave"] == 0x00) then
		streams["comfort_power_save"] = "off"
	elseif(keyP["comfortPowerSave"] == 0x01) then
		streams["comfort_power_save"] = "on"
	end

	--无风感
	if(keyP["no_wind_sense"] ~= nil) then
		streams["no_wind_sense"] = keyP["no_wind_sense"]
	end


	--防着凉
	if(keyP["preventCold"] == 0x00) then
		streams["prevent_cold"] = "off"
	elseif(keyP["preventCold"] == 0x01) then
		streams["prevent_cold"] = "on"
	end

	else
		--新协议，变长属性控制协议
		if(keyP["prevent_super_cool"] ~= nil) then
			if(keyP["prevent_super_cool"] == 0x00) then
				streams["prevent_super_cool"] = "off"
			elseif(keyP["prevent_super_cool"] == 0x01) then
				streams["prevent_super_cool"] = "on"
			end
		end
		if(keyP["prevent_straight_wind"] ~= nil) then
			streams["prevent_straight_wind"] = keyP["prevent_straight_wind"]
		end
		if(keyP["auto_prevent_straight_wind"] ~= nil) then
			if(keyP["auto_prevent_straight_wind"] == 0x00) then
				streams["auto_prevent_straight_wind"] = "off"
			elseif(keyP["auto_prevent_straight_wind"] == 0x01) then
				streams["auto_prevent_straight_wind"] = "on"
			end
		end
		if(keyP["self_clean"] ~= nil) then
			if(keyP["self_clean"] == 0x00) then
				streams["self_clean"] = "off"
			elseif(keyP["self_clean"] == 0x01) then
				streams["self_clean"] = "on"
			end
		end
		if(keyP["wind_straight"] ~= nil) then
			if(keyP["wind_straight"] == 0x00) then
				streams["wind_straight"] = "off"
			elseif(keyP["wind_straight"] == 0x01) then
				streams["wind_straight"] = "on"
			end
		end
		if(keyP["wind_avoid"] ~= nil) then
			if(keyP["wind_avoid"] == 0x00) then
				streams["wind_avoid"] = "off"
			elseif(keyP["wind_avoid"] == 0x01) then
				streams["wind_avoid"] = "on"
			end
		end
		if(keyP["intelligent_wind"] ~= nil) then
			if(keyP["intelligent_wind"] == 0x00) then
				streams["intelligent_wind"] = "off"
			elseif(keyP["intelligent_wind"] == 0x01) then
				streams["intelligent_wind"] = "on"
			end
		end
		if(keyP["child_prevent_cold_wind"] ~= nil) then
			if(keyP["child_prevent_cold_wind"] == 0x00) then
				streams["child_prevent_cold_wind"] = "off"
			elseif(keyP["child_prevent_cold_wind"] == 0x01) then
				streams["child_prevent_cold_wind"] = "on"
			end
		end
		if(keyP["no_wind_sense"] ~= nil) then
			streams["no_wind_sense"] = keyP["no_wind_sense"]
		end
		if(keyP["little_angel"] ~= nil) then
			if(keyP["little_angel"] == 0x00) then
				streams["little_angel"] = "off"
			elseif(keyP["little_angel"] == 0x01) then
				streams["little_angel"] = "on"
			end
		end
		if(keyP["cool_hot_sense"] ~= nil) then
			if(keyP["cool_hot_sense"] == 0x00) then
				streams["cool_hot_sense"] = "off"
			elseif(keyP["cool_hot_sense"] == 0x01) then
				streams["cool_hot_sense"] = "on"
			end
		end
		if(keyP["gentle_wind_sense"] ~= nil) then
			if(keyP["gentle_wind_sense"] == 0x01) then
				streams["gentle_wind_sense"] = "off"
			elseif(keyP["gentle_wind_sense"] == 0x03) then
				streams["gentle_wind_sense"] = "on"
			end
		end
		if(keyP["screen_display"] ~= nil) then
			if(keyP["screen_display"] == 0x64) then
				streams["screen_display"] = "on"
			elseif(keyP["screen_display"] == 0x00) then
				streams["screen_display"] = "off"
			end
		end
		if(keyP["security"] ~= nil) then
			if(keyP["security"] == 0x00) then
			streams["security"] = "off"
			elseif(keyP["security"] == 0x01) then
			streams["security"] = "on"
			end
		end
	end
	keyP["propertyNumber"] = 0
	keyP["prevent_super_cool"] = nil
	keyP["prevent_straight_wind"] = nil
	keyP["auto_prevent_straight_wind"] = nil
	keyP["wind_straight"] = nil
	keyP["wind_avoid"] = nil
	keyP["intelligent_wind"] = nil
	keyP["self_clean"] = nil
	keyP["no_wind_sense"] = nil
	keyP["child_prevent_cold_wind"] = nil
	keyP["little_angel"] = nil
	keyP["cool_hot_sense"] = nil
	keyP["gentle_wind_sense"] = nil
	keyP["screen_display"] = nil
	keyP["security"] = nil

	local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
