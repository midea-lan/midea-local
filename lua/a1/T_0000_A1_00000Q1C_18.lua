----除湿机协议解析
----author: tong.li
----date  : 2017/7/13


local JSON = require "cjson"

-----------------JSON相关key值变量-----------------
local keyT = {}
--版本号
keyT["KEY_VERSION"]="version"
--电源
keyT["KEY_POWER"] = "power"
--风速
keyT["KEY_WIND_SPEED"] = "wind_speed"
--模式
keyT["KEY_MODE"] = "mode"
--湿度
keyT["KEY_HUMIDITY"] = "humidity"
--水箱状态（只读）
keyT["KEY_TANK_STATUS"] = "tank_status"
--当前湿度（只读）
keyT["KEY_CURRENT_HUMIDITY"] = "cur_humidity"
--定时开
keyT["KEY_TIME_ON"] = "power_on_timer"
--定时关
keyT["KEY_TIME_OFF"] = "power_off_timer"
--定时关时间
keyT["KEY_CLOSE_TIME"] = "power_off_time_value"
--定时开时间
keyT["KEY_OPEN_TIME"] = "power_on_time_value"
--水满档位
keyT["KEY_WATER_FULL_LEVEL"] = "water_full_level"
--水满时间
keyT["KEY_WATER_FULL_TIME"] = "water_full_time"
--负离子
keyT["KEY_ANION"] = "anion"
--滤网
keyT["KEY_FILTER_VALUE"] = "filter_value"
--水泵
keyT["KEY_WATER_PUMP"] = "water_pump"
--水泵有效
keyT["KEY_WATER_PUMP_ENABLE"] = "water_pump_enable"
--灯光
keyT["KEY_LIGHT"] = "light"
--净化
keyT["KEY_PURIFIER"] = "purifier"

----------------JSON相关value值变量----------------
local keyV = {}
--版本号
keyV["VALUE_VERSION"] = 18
--功能开
keyV["VALUE_FUNCTION_ON"] = "on"
--功能关
keyV["VALUE_FUNCTION_OFF"] = "off"
--无效
keyV["VALUE_MODE_INVALID"] = "invalid"
--设定除湿
keyV["VALUE_MODE_SET"] = "set"
--智能除湿
keyV["VALUE_MODE_AUTO"] = "auto"
--连续除湿
keyV["VALUE_MODE_CONTINUITY"] = "continuity"
--干衣除湿
keyV["VALUE_MODE_DRY_CLOTHES"] = "dry_clothes"
--干鞋模式
keyV["VALUE_MODE_DRY_SHOES"] = "dry_shoes"
--送风模式
keyV["VALUE_MODE_FAN"] = "fan"
--ECO模式
keyV["VALUE_MODE_ECO"] = "eco"

-----------------二进制相关属性变量----------------
local keyB = {}
--设备
keyB["BYTE_DEVICE_TYPE"]                = 0xA1
--控制请求
keyB["BYTE_CONTROL_REQUEST"]     = 0x02
--查询请求
keyB["BYTE_QUERY_REQUEST"] = 0x03
--协议头
keyB["BYTE_PROTOCOL_HEAD"]                 = 0xAA
--协议头长度
keyB["BYTE_PROTOCOL_LENGTH"]               = 0x0A
--电源开
keyB["BYTE_POWER_ON"]                   = 0x01
--电源关
keyB["BYTE_POWER_OFF"]                  = 0x00
--无效模式
keyB["BYTE_MODE_INVALID"]               = 0x00
--设置模式
keyB["BYTE_MODE_SET"]              = 0x01
--连续除湿模式
keyB["BYTE_MODE_CONTINUITY"]            = 0x02
--自动除湿模式
keyB["BYTE_MODE_AUTO"]                  = 0x03
--干衣模式
keyB["BYTE_MODE_DRY_CLOTH"]                = 0x04
--干鞋模式
keyB["BYTE_MODE_DRY_SHOES"]                = 0x05
--送风模式
keyB["BYTE_MODE_FAN"]                = 0x08
--ECO模式
keyB["BYTE_MODE_ECO"]                = 0x09
--蜂鸣器开
keyB["BYTE_BUZZER_ON"]                  = 0x40
--蜂鸣器关
keyB["BYTE_BUZZER_OFF"]                 = 0x00
--定时关(开)
keyB["BYTE_CLOSE_TIMER_SWITCH_ON"] = 0x80
--定时关(关)
keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"] = 0x7F
--定时开(开)
keyB["BYTE_START_TIMER_SWITCH_ON"] = 0x80
--定时开(关)
keyB["BYTE_START_TIMER_SWITCH_OFF"] = 0x7F
--负离子开
keyB["BYTE_ANION_ON"]                   = 0x40
--负离子关
keyB["BYTE_ANION_OFF"]                  = 0x00


-------------------定义属性变量--------------------
local keyP = {}
local dataType = 0

--水箱状态
keyP["tankStatusValue"] = 0
keyP["closeTimerSwitch"] = 0
keyP["openTimerSwitch"] = 0
keyP["closeTime"] = 0
keyP["openTime"] = 0
keyP["swingUDValue"] = 0
keyP["waterLevelValue"] = 0
keyP["waterTimeValue"] = 0
keyP["filterValue"] = 0
keyP["waterPumpValue"] = 0
keyP["waterPumpEnableValue"] = 0
keyP["isB5query"] = 0
keyP["filter_flag"] = 0
keyP["lightValue"] = 0
--净化
keyP["purifier"] = 0

local function init_keyP()
	keyP["b5_auto_dry"] = nil
	keyP["b5_dry_clothes_mode"] = nil
	keyP["b5_anion"] = nil
	keyP["b5_filter_value"] = nil
	keyP["b5_water_full_level"] = nil
	keyP["b5_water_pump"] = nil
	keyP["b5_wind_speed"] = nil
	keyP["b5_light"] = nil
	keyP["b5_mode"] = nil
	keyP["b5_wind_swing_ud"] = nil
	keyP["b5_purifier"] = nil
	keyP["b5_eco"] = nil
	keyP["b5_self_clean"] = nil
	keyP["b5_sound"] = nil
	keyP["filter_flag"] = 0
	keyP["propertyNumber"] = 0
	keyP["self_clean"] = nil
	keyP["light"] = nil
	keyP["sound"] = nil
	--电源
	keyP["powerValue"] = nil
	--模式
	keyP["modeValue"] = nil
	--负离子
	keyP["anionValue"] = nil
	--风速
	keyP["windSpeedValue"] = nil
	--湿度
	keyP["humidityValue"] = nil
	--当前湿度
	keyP["curHumidityValue"] = nil
	--故障代码
	keyP["errorCodeValue"] = nil

	--自清洁
	keyP["self_clean"] = nil
	keyP["tankStatusValue"] = nil
	keyP["closeTimerSwitch"] = nil
	keyP["openTimerSwitch"] = nil
	keyP["closeTime"] = nil
	keyP["openTime"] = nil
	keyP["swingUDValue"] = nil
	keyP["waterLevelValue"] = nil
	keyP["waterTimeValue"] = nil
	keyP["filterValue"] = nil
	keyP["waterPumpValue"] = nil
	keyP["waterPumpEnableValue"] = nil
	keyP["lightValue"] = nil
	--净化
	keyP["purifier"] = nil
end

init_keyP()

--检查取值是否超过边界
local function checkBoundary(data, min, max)
    if (not data) then
        data = 0
    end

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


-----------根据电控协议不同，需要改变的函数-------------
--根据 json 修改属性变量
local function jsonToModel(stateJson,controlJson)
    local oldState = stateJson
    local controlCmd = controlJson

    --电源
    local temValue = oldState[keyT["KEY_POWER"]]
    if (controlCmd[keyT["KEY_POWER"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_POWER"]]
    end

    if(temValue == keyV["VALUE_FUNCTION_ON"]) then
        keyP["powerValue"] = keyB["BYTE_POWER_ON"]
		keyP["openTimerSwitch"]  = keyB["BYTE_START_TIMER_SWITCH_OFF"]
		keyP["closeTimerSwitch"]  = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
    else
        keyP["powerValue"] = keyB["BYTE_POWER_OFF"]
		keyP["openTimerSwitch"]  = keyB["BYTE_START_TIMER_SWITCH_OFF"]
		keyP["closeTimerSwitch"]  = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
    end

	--风速
    temValue = oldState[keyT["KEY_WIND_SPEED"]]
    if (controlCmd[keyT["KEY_WIND_SPEED"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_WIND_SPEED"]]
    end
    keyP["windSpeedValue"] = checkBoundary(temValue, 1, 102)

    --湿度
    temValue = oldState[keyT["KEY_HUMIDITY"]]
    if (controlCmd[keyT["KEY_HUMIDITY"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_HUMIDITY"]]
    end
    keyP["humidityValue"]  = checkBoundary(temValue, 0, 99)
	--银离子
    temValue = oldState[keyT["KEY_ANION"]]
    if (controlCmd[keyT["KEY_ANION"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_ANION"]]
    end

    if(temValue == keyV["VALUE_FUNCTION_ON"]) then
        keyP["anionValue"]  = keyB["BYTE_ANION_ON"]
    else
        keyP["anionValue"]  = keyB["BYTE_ANION_OFF"]
    end
    --模式
    temValue = oldState[keyT["KEY_MODE"]]
    if (controlCmd[keyT["KEY_MODE"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_MODE"]]
    end
	--DG3下发自动除湿时，实际电控组包为设定除湿
    if (temValue == keyV["VALUE_MODE_SET"]) then
        keyP["modeValue"]  = keyB["BYTE_MODE_SET"]
	elseif (temValue == keyV["VALUE_MODE_AUTO"]) then
        keyP["modeValue"]  = keyB["BYTE_MODE_AUTO"]
    elseif (temValue == keyV["VALUE_MODE_CONTINUITY"]) then
        keyP["modeValue"]  = keyB["BYTE_MODE_CONTINUITY"]
    elseif (temValue == keyV["VALUE_MODE_DRY_CLOTHES"]) then
        keyP["modeValue"]  = keyB["BYTE_MODE_DRY_CLOTH"]
		--keyP["windSpeedValue"]  = 80
    elseif (temValue == keyV["VALUE_MODE_DRY_SHOES"]) then
        keyP["modeValue"]  = keyB["BYTE_MODE_DRY_SHOES"]
		--keyP["windSpeedValue"]  = 80
	elseif (temValue == keyV["VALUE_MODE_FAN"]) then
        keyP["modeValue"]  = keyB["BYTE_MODE_FAN"]
	elseif (temValue == keyV["VALUE_MODE_ECO"]) then
        keyP["modeValue"]  = keyB["BYTE_MODE_ECO"]
    end

    --上下扫风
    keyP["swingUDValue"]  = oldState["wind_swing_ud"]
	if(oldState["wind_swing_ud"] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingUDValue"]  = 0x01
	elseif (oldState["wind_swing_ud"] == keyV["VALUE_FUNCTION_OFF"])  then
        keyP["swingUDValue"]  = 0x00
	end
    if (controlCmd["wind_swing_ud"] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingUDValue"]  = 0x01
    elseif (controlCmd["wind_swing_ud"] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingUDValue"]  = 0x00
    end

	--定时开
    if (oldState[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["openTimerSwitch"] = keyB["BYTE_START_TIMER_SWITCH_ON"]
    elseif (oldState[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["openTimerSwitch"]   = keyB["BYTE_START_TIMER_SWITCH_OFF"]
    end
    if (controlCmd[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["openTimerSwitch"]   = keyB["BYTE_START_TIMER_SWITCH_ON"]
    elseif (controlCmd[keyT["KEY_TIME_ON"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["openTimerSwitch"]   = keyB["BYTE_START_TIMER_SWITCH_OFF"]
    end

    --定时关
    if (oldState[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["closeTimerSwitch"]   = keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]
    elseif (oldState[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["closeTimerSwitch"]   = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
    end
    if (controlCmd[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["closeTimerSwitch"]   = keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]
    elseif (controlCmd[keyT["KEY_TIME_OFF"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["closeTimerSwitch"]   = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
    end

    --定时关机时间
	keyP["closeTime"]  =oldState[keyT["KEY_CLOSE_TIME"]]
    if (controlCmd[keyT["KEY_CLOSE_TIME"]] ~= nil) then
        keyP["closeTime"]   = controlCmd[keyT["KEY_CLOSE_TIME"]]
    end

    --定时开机时间
	keyP["openTime"]  =oldState[keyT["KEY_OPEN_TIME"]]
    if (controlCmd[keyT["KEY_OPEN_TIME"]] ~= nil) then
		keyP["openTime"]   = controlCmd[keyT["KEY_OPEN_TIME"]]
    end
	--水满档位
	keyP["waterLevelValue"]  =oldState[keyT["KEY_WATER_FULL_LEVEL"]]
    if (controlCmd[keyT["KEY_WATER_FULL_LEVEL"]] ~= nil) then
		keyP["waterLevelValue"]   = controlCmd[keyT["KEY_WATER_FULL_LEVEL"]]
    end
	--水满时间
	keyP["waterTimeValue"]  =oldState[keyT["KEY_WATER_FULL_TIME"]]
    if (controlCmd[keyT["KEY_WATER_FULL_TIME"]] ~= nil) then
		keyP["waterTimeValue"]   = controlCmd[keyT["KEY_WATER_FULL_TIME"]]
    end
	--滤网
    temValue = oldState[keyT["KEY_FILTER_VALUE"]]
    if (controlCmd[keyT["KEY_FILTER_VALUE"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_FILTER_VALUE"]]
		keyP["filter_flag"] = 1
    end

    if(temValue == keyV["VALUE_FUNCTION_ON"]) then
        keyP["filterValue"]   = 0x80
    else
        keyP["filterValue"]   = 0x00
    end
	--水泵
    temValue = oldState[keyT["KEY_WATER_PUMP"]]
    if (controlCmd[keyT["KEY_WATER_PUMP"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_WATER_PUMP"]]
    end

    if(temValue == keyV["VALUE_FUNCTION_ON"]) then
        keyP["waterPumpValue"]   = 0x08
    else
        keyP["waterPumpValue"]   = 0x00
    end
	--滤网
    temValue = oldState[keyT["KEY_WATER_PUMP_ENABLE"]]
    if (controlCmd[keyT["KEY_WATER_PUMP_ENABLE"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_WATER_PUMP_ENABLE"]]
    end
	--灯光
    if (controlCmd[keyT["KEY_LIGHT"]] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		keyP["light"] = controlCmd[keyT["KEY_LIGHT"]]
    end

	--自清洁
    if (controlCmd["self_clean"] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		keyP["self_clean"] = controlCmd["self_clean"]
    end

	--声音
	if (controlCmd["sound"] ~= nil) then
		keyP["propertyNumber"] = keyP["propertyNumber"] + 1
		keyP["sound"] = controlCmd["sound"]
    end

    if(temValue == keyV["VALUE_FUNCTION_ON"]) then
        keyP["waterPumpEnableValue"] = 0x10
    else
        keyP["waterPumpEnableValue"] = 0x00
    end
	--净化
    temValue = oldState[keyT["KEY_PURIFIER"]]
    if (controlCmd[keyT["KEY_PURIFIER"]] ~= nil) then
        temValue = controlCmd[keyT["KEY_PURIFIER"]]
    end

    if(temValue == keyV["VALUE_FUNCTION_ON"]) then
        keyP["purifier"]   = 0x01
    else
        keyP["purifier"]   = 0x00
    end
end

--根据 bin 修改属性变量
local function binToModel(binData)
    if (#binData == 0) then
		print("3333333")
        return nil
    end

    local messageBytes = binData

    if (dataType == 0x03 and messageBytes[0] == 0xB5) then
		keyP["propertyNumber"] = messageBytes[1]
		local cursor = 2
        for i = 1,  keyP["propertyNumber"] do
			if (messageBytes[cursor + 0] == 0x20 and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_dry_clothes_mode"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x1F and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_auto_dry"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x10 and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_wind_speed"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x1E and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_anion"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x17 and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_filter_value"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x1D and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_water_pump"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x2D and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_water_full_level"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x14 and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_mode"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x24 and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_light"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x15 and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_wind_swing_ud"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x54 and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_purifier"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x12 and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_eco"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x39 and messageBytes[cursor + 1] == 0x00) then
				keyP["b5_self_clean"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x2C and messageBytes[cursor + 1] == 0x02) then
				keyP["b5_sound"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
		end
	elseif(dataType == 0x05 and messageBytes[0] == 0xB5)then
		keyP["propertyNumber"] = messageBytes[1]
		local cursor = 2
		for i = 1,  keyP["propertyNumber"] do
			if (messageBytes[cursor + 0] == 0x39 and messageBytes[cursor + 1] == 0x00) then
				keyP["self_clean"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x2C and messageBytes[cursor + 1] == 0x02) then
				keyP["sound"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
			if (messageBytes[cursor + 0] == 0x5B and messageBytes[cursor + 1] == 0x00) then
				keyP["light"] = messageBytes[cursor + 3]
				cursor = cursor + 4
			end
		end
	elseif(messageBytes[0] == 0xB1 or messageBytes[0] == 0xB0) then
		keyP["propertyNumber"] = messageBytes[1]
		local cursor = 2
		for i = 1,  keyP["propertyNumber"] do
			if (messageBytes[cursor + 0] == 0x5B and messageBytes[cursor + 1] == 0x00) then
				keyP["light"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x39 and messageBytes[cursor + 1] == 0x00) then
				keyP["self_clean"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
			if (messageBytes[cursor + 0] == 0x2C and messageBytes[cursor + 1] == 0x02) then
				keyP["sound"] = messageBytes[cursor + 4]
				cursor = cursor + 5
			end
		end

	else
		keyP["powerValue"] = bit.band(messageBytes[1], 0x01)
		keyP["modeValue"]  = bit.band(messageBytes[2], 0x0F)
		keyP["windSpeedValue"]  =bit.band(messageBytes[3], 0x7F)
		keyP["anionValue"]  = bit.band(messageBytes[9], 0x40)
		keyP["filterValue"]   = bit.band(messageBytes[9], 0x80)
		keyP["waterPumpValue"]   = bit.rshift(bit.band(messageBytes[9], 0x08), 3)
		keyP["waterPumpEnableValue"] = bit.rshift(bit.band(messageBytes[9], 0x10), 4)

		if (bit.band(messageBytes[4], keyB["BYTE_START_TIMER_SWITCH_ON"]) == keyB["BYTE_START_TIMER_SWITCH_ON"]) then
			keyP["openTimerSwitch"]   = keyB["BYTE_START_TIMER_SWITCH_ON"]
		else
		   keyP["openTimerSwitch"]   = keyB["BYTE_START_TIMER_SWITCH_OFF"]
		end
		if (bit.band(messageBytes[5], keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) == keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
			keyP["closeTimerSwitch"]   = keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]
		else
			keyP["closeTimerSwitch"]   = keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]
		end
		local closeHour = bit.rshift(bit.band(messageBytes[5], 0x7F), 2)
		local closeStepMintues = bit.band(messageBytes[5], 0x03)
		local closeMin = 15 - bit.band(messageBytes[6], 0x0f)
		keyP["closeTime"]   = closeHour * 60 + closeStepMintues * 15 + closeMin
		local openHour = bit.rshift(bit.band(messageBytes[4], 0x7F), 2)
		local openStepMintues = bit.band(messageBytes[4], 0x03)
		local openMin = 15 - bit.rshift(bit.band(messageBytes[6], 0xf0),4)
		keyP["openTime"]   = openHour * 60 + openStepMintues * 15 + openMin

		keyP["humidityValue"]  = messageBytes[7]
		if (keyP["humidityValue"]  < 35) then
		keyP["humidityValue"]  = 35
		end
		keyP["waterTimeValue"]   = bit.bor(bit.lshift(messageBytes[14],8),messageBytes[13])
		keyP["waterLevelValue"]   = messageBytes[15]
		keyP["curHumidityValue"]  = messageBytes[16]
		keyP["tankStatusValue"]  = messageBytes[10]
		keyP["swingUDValue"]   = bit.rshift(bit.band(messageBytes[19], 0x20), 5)
		keyP["errorCodeValue"] = messageBytes[21]
		if(#binData >= 23) then
			keyP["purifier"] = bit.band(messageBytes[23], 0x01)
		end
	end


end


---------------公共的函数---------------
--打印 table 表
local function print_lua_table(lua_table, indent)
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


--table 转 string
local function table2string(cmd)
    local ret = ""
    local i

    for i = 1, #cmd do
        ret = ret..string.char(cmd[i])
    end

    return ret
end

--十六进制 string 转 table
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

--十六进制 string 输出
local function string2hexstring(str)
    local ret = ""

    for i = 1, #str do
        ret = ret .. string.format("%02x", str:byte(i))
    end

    return ret
end

--table 转 json
local function encode(cmd)
    local tb

    if JSON == nil then
        JSON = require "cjson"
    end

    tb = JSON.encode(cmd)

    return tb
end

--json 转 table
local function decode(cmd)
    local tb

    if JSON == nil then
        JSON = require "cjson"
    end

    tb = JSON.decode(cmd)

    return tb
end

local function splitStrByChar(str,sepChar)
	local splitList = {}
	local pattern = '[^'..sepChar..']+'
		string.gsub(str, pattern, function(w) table.insert(splitList, w) end )
	return splitList
end

local function values (t)
	local i = 0
	return function() i = i + 1; return t[i] end
end

--sum校验
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0

    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]

        if resVal > 0xff then
            resVal = bit.band(resVal, 0xff)
        end
    end

    resVal = 255 - resVal + 1

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
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0

    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end

    return crc
end


--二进制转json
function dataToJson(jsonCmd)
	init_keyP()
    if (not jsonCmd) then
		print("444444")
        return nil
    end

    local json = decode(jsonCmd)
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]


    --根据设备子类型来处理协议差异
    if (deviceSubType == 1) then

    end

    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0

    info = string2table(binData)

    dataType=info[10]
    if((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04) and (dataType ~= 0x05))then
        return nil
    end

    for i = 1, #info do
        msgBytes[i - 1] = info[i]
    end

    msgLength = msgBytes[1]
    bodyLength = msgLength - keyB["BYTE_PROTOCOL_LENGTH"] - 1

	--streams["b5_next_frame"] = info[msgLength - 2]

    --检验 sum 判断消息格式是否正确
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then
        return nil
    end

    --获取 body 部分
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]]
    end

    --检验 crc 判断消息格式是否正确
    local crcRes = crc8_854(bodyBytes, 0, bodyLength - 1)
    if (crcRes ~= bodyBytes[bodyLength]) then
        return nil
    end

    --将二进制状态解析为属性值
    binToModel(bodyBytes)

    --将属性值转换为最终 table
    local streams = {}

    --版本
    streams[keyT["KEY_VERSION"]]=keyV["VALUE_VERSION"]
    streams["sub_type"]=2

	 if (keyP["propertyNumber"] == 0) then
    --处理常规协议
		--电源
		if (keyP["powerValue"] == keyB["BYTE_POWER_ON"]) then
			streams[keyT["KEY_POWER"]] = keyV["VALUE_FUNCTION_ON"]
		elseif (keyP["powerValue"] == keyB["BYTE_POWER_OFF"]) then
			streams[keyT["KEY_POWER"]] = keyV["VALUE_FUNCTION_OFF"]
		end

		--模式
		if (keyP["modeValue"]  == keyB["BYTE_MODE_SET"]) then
			streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_SET"]
		elseif (keyP["modeValue"]  == keyB["BYTE_MODE_AUTO"]) then
			streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_AUTO"]
		elseif (keyP["modeValue"]  == keyB["BYTE_MODE_CONTINUITY"]) then
			streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_CONTINUITY"]
		elseif (keyP["modeValue"]  == keyB["BYTE_MODE_DRY_CLOTH"]) then
			streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_DRY_CLOTHES"]
		elseif (keyP["modeValue"]  == keyB["BYTE_MODE_DRY_SHOES"]) then
			streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_DRY_SHOES"]
		elseif (keyP["modeValue"] == keyB["BYTE_MODE_FAN"]) then
			streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_FAN"]
		elseif (keyP["modeValue"] == keyB["BYTE_MODE_ECO"]) then
			streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_ECO"]
		end

		--档位
		streams[keyT["KEY_WIND_SPEED"]] = keyP["windSpeedValue"]
		streams[keyT["KEY_HUMIDITY"]] = keyP["humidityValue"]
		streams[keyT["KEY_CURRENT_HUMIDITY"]] = keyP["curHumidityValue"]
		streams[keyT["KEY_TANK_STATUS"]] = keyP["tankStatusValue"]

		--上下扫风
		if (keyP["swingUDValue"]   == 0x01) then
			streams["wind_swing_ud"] = keyV["VALUE_FUNCTION_ON"]
		elseif (keyP["swingUDValue"]   == 0x00) then
			streams["wind_swing_ud"] = keyV["VALUE_FUNCTION_OFF"]
		end

		--定时开
		if (keyP["openTimerSwitch"]   == keyB["BYTE_START_TIMER_SWITCH_ON"]) then
			streams[keyT["KEY_TIME_ON"]] = keyV["VALUE_FUNCTION_ON"]
		elseif (keyP["openTimerSwitch"]   == keyB["BYTE_START_TIMER_SWITCH_OFF"]) then
			streams[keyT["KEY_TIME_ON"]] = keyV["VALUE_FUNCTION_OFF"]
		end

		--定时关
		if (keyP["closeTimerSwitch"]   == keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
			streams[keyT["KEY_TIME_OFF"]] = keyV["VALUE_FUNCTION_ON"]
		elseif (keyP["closeTimerSwitch"]   == keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
			streams[keyT["KEY_TIME_OFF"]] = keyV["VALUE_FUNCTION_OFF"]
		end

		--定时关机时间
		if (keyP["closeTimerSwitch"]   == keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
			streams[keyT["KEY_CLOSE_TIME"]] = 0
		else
			streams[keyT["KEY_CLOSE_TIME"]] = keyP["closeTime"]
		end

		--定时开机时间
		if (keyP["openTimerSwitch"]   == keyB["BYTE_START_TIMER_SWITCH_OFF"]) then
			streams[keyT["KEY_OPEN_TIME"]] = 0
		else
			streams[keyT["KEY_OPEN_TIME"]] = keyP["openTime"]
		end
		--银离子
		if (keyP["anionValue"]  == keyB["BYTE_ANION_ON"]) then
			streams[keyT["KEY_ANION"]] = keyV["VALUE_FUNCTION_ON"]
		elseif (keyP["anionValue"]  == keyB["BYTE_ANION_OFF"]) then
			streams[keyT["KEY_ANION"]] = keyV["VALUE_FUNCTION_OFF"]
		end
		--滤网
		if (keyP["filterValue"]   == 0x80) then
			streams[keyT["KEY_FILTER_VALUE"]] = keyV["VALUE_FUNCTION_ON"]
		elseif (keyP["filterValue"]   == 0x00) then
			streams[keyT["KEY_FILTER_VALUE"]] = keyV["VALUE_FUNCTION_OFF"]
		end
		--水泵
		streams[keyT["KEY_WATER_PUMP"]] = keyP["waterPumpValue"]
		if(keyP["waterPumpValue"]   == 0x08 or keyP["waterPumpValue"]   == 0x01) then
			streams[keyT["KEY_WATER_PUMP"]] = 1
		else
			streams[keyT["KEY_WATER_PUMP"]] = 0
		end
		--净化
		streams[keyT["KEY_PURIFIER"]] = keyP["purifier"]
		if(keyP["purifier"]   == 0x01) then
			streams[keyT["KEY_PURIFIER"]] = "on"
		else
			streams[keyT["KEY_PURIFIER"]] = "off"
		end
		--水泵有效
		streams[keyT["KEY_WATER_PUMP_ENABLE"]] = keyP["waterPumpEnableValue"]
		if(keyP["waterPumpEnableValue"] == 0x10 or keyP["waterPumpEnableValue"] == 0x01) then
			streams[keyT["KEY_WATER_PUMP_ENABLE"]] = 1
		else
			streams[keyT["KEY_WATER_PUMP_ENABLE"]] = 0
		end
		--水满档位
		streams[keyT["KEY_WATER_FULL_LEVEL"]] = keyP["waterLevelValue"]
		--水满时间
		streams[keyT["KEY_WATER_FULL_TIME"]] = keyP["waterTimeValue"]
		if(keyP["errorCodeValue"] ~= nil) then
			streams["error_code"] = keyP["errorCodeValue"]
		end
	else
		if(keyP["b5_dry_clothes_mode"] ~= nil) then
			streams["b5_dry_clothes_mode"] = keyP["b5_dry_clothes_mode"]
		end
		if(keyP["b5_auto_dry"] ~= nil) then
			streams["b5_auto_dry"] = keyP["b5_auto_dry"]
		end
		if(keyP["b5_wind_speed"] ~= nil) then
			streams["b5_wind_speed"] = keyP["b5_wind_speed"]
		end
		if(keyP["b5_anion"] ~= nil) then
			streams["b5_anion"] = keyP["b5_anion"]
		end
		if(keyP["b5_filter_value"] ~= nil) then
			streams["b5_filter_value"] = keyP["b5_filter_value"]
		end
		if(keyP["b5_water_pump"] ~= nil) then
			streams["b5_water_pump"] = keyP["b5_water_pump"]
		end
		if(keyP["b5_water_full_level"] ~= nil) then
			streams["b5_water_full_level"] = keyP["b5_water_full_level"]
		end
		if(keyP["light"] ~= nil) then
			streams["light"] = keyP["light"]
		end
		if(keyP["b5_light"] ~= nil) then
			streams["b5_light"] = keyP["b5_light"]
		end
		if(keyP["b5_mode"] ~= nil) then
			streams["b5_mode"] = keyP["b5_mode"]
		end
		if(keyP["b5_wind_swing_ud"] ~= nil) then
			streams["b5_wind_swing_ud"] = keyP["b5_wind_swing_ud"]
		end
		if(keyP["b5_purifier"] ~= nil) then
			streams["b5_purifier"] = keyP["b5_purifier"]
		end
		if(keyP["b5_eco"] ~= nil) then
			streams["b5_eco"] = keyP["b5_eco"]
		end
		if(keyP["self_clean"] ~= nil) then
			streams["self_clean"] = keyP["self_clean"]
		end
		if(keyP["b5_self_clean"] ~= nil) then
			streams["b5_self_clean"] = keyP["b5_self_clean"]
		end
		if(keyP["sound"] ~= nil) then
			streams["sound"] = keyP["sound"]
		end
		if(keyP["b5_sound"] ~= nil) then
			streams["b5_sound"] = keyP["b5_sound"]
		end
	end

    local retTable = {}
    retTable["status"] = streams

    local ret = encode(retTable)
    return ret
end


--json转二进制，可传入原状态
function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then
		print("222222")
        return nil
    end

    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]

    --根据设备子类型来处理协议差异
    if (deviceSubType == 1) then

    end

    local query = json["query"]
    local control = json["control"]
    local status = json["status"]

    local bodyLength = 0
	local b5BodyLength = 0

	local bodyBytes = {}
	local b5Body = {}

    --当前是查询指令，构造固定的二进制即可
    if (query) then
        --构造消息 body 部分
		local queryType = nil
        if (type(query) == "table") then
            queryType = query["query_type"]
        end
		if (queryType == "all_first_frame") then
			keyP["isB5query"] = 1
			b5BodyLength = 15
			for i = 0, b5BodyLength - 1 do
				b5Body[i] = 0
			end
            b5Body[1] = 0xaa
            b5Body[2] = 0x0e
            b5Body[3] = 0xa1
            b5Body[4] = 0x00
            b5Body[5] = 0x00
            b5Body[6] = 0x00
            b5Body[7] = 0x00
            b5Body[8] = 0x00
            b5Body[9] = 0x03
            b5Body[10] = 0x03
            b5Body[11] = 0xb5
            b5Body[12] = 0x01
            b5Body[13] = 0x11
            b5Body[14] = 0x8e
            b5Body[15] = 0xf6
        elseif (queryType == "all_second_frame") then
			keyP["isB5query"] = 1
			b5BodyLength = 16
			for i = 0, b5BodyLength do
				b5Body[i] = 0
			end
            b5Body[1] = 0xaa
            b5Body[2] = 0x0f
            b5Body[3] = 0xa1
            b5Body[4] = 0x00
            b5Body[5] = 0x00
            b5Body[6] = 0x00
            b5Body[7] = 0x00
            b5Body[8] = 0x00
            b5Body[9] = 0x03
            b5Body[10] = 0x03
            b5Body[11] = 0xb5
            b5Body[12] = 0x01
            b5Body[13] = 0x01
            b5Body[14] = 0x01
            b5Body[15] = 0x21
            --b5Body[16] = 0x66
			b5Body[15] = crc8_854(b5Body, 0, 15)
		elseif(queryType == nil) then
			for i = 0, 21 do
                bodyBytes[i] = 0
            end
			bodyBytes[0] = 0x41
			bodyBytes[1] = 0x81
			bodyBytes[3] = 0xFF

			math.randomseed(os.time())
			bodyBytes[20] = math.random(0, 100)
			bodyBytes[21] = crc8_854(bodyBytes, 0, 20)


		else
			bodyBytes[0] = 0xB1
            local propertyNum = 0

			local queryList = {}
            if (string.match(queryType,",")==",") then
				queryList  = splitStrByChar(queryType,",")
			else
				table.insert(queryList, queryType)
			end
			for v in values(queryList) do
				queryType = v
				if (queryType == "light") then
					bodyBytes[1 + propertyNum * 2 + 1] = 0x5B
					bodyBytes[1 + propertyNum * 2 + 2] = 0x00
					propertyNum = propertyNum + 1
				end
				if (queryType == "self_clean") then
					bodyBytes[1 + propertyNum * 2 + 1] = 0x39
					bodyBytes[1 + propertyNum * 2 + 2] = 0x00
					propertyNum = propertyNum + 1
				end
				if (queryType == "sound") then
					bodyBytes[1 + propertyNum * 2 + 1] = 0x2C
					bodyBytes[1 + propertyNum * 2 + 2] = 0x02
					propertyNum = propertyNum + 1
				end
			end
			bodyBytes[1] = propertyNum
			bodyBytes[1 + propertyNum * 2 + 1] = math.random(0, 100)
			bodyBytes[1 + propertyNum * 2 + 2] = crc8_854(bodyBytes, 0, 1 + propertyNum * 2 + 1)
		end

    --当前是控制指令
    elseif (control) then
		keyP["light"] = nil
		keyP["self_clean"] = nil
		keyP["sound"] = nil
		keyP["propertyNumber"] = 0
        --先将原始状态转换为属性
        if (control and status) then
            jsonToModel(status,control)
        end
		if(keyP["propertyNumber"] > 0) then
			bodyBytes[0] = 0xB0
			bodyBytes[1] = keyP["propertyNumber"]
			local cursor = 2
			if(keyP["light"] ~= nil) then
				bodyBytes[cursor + 0] = 0x5B
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["light"]
				cursor = cursor + 4
			end
			if(keyP["self_clean"] ~= nil) then
				bodyBytes[cursor + 0] = 0x39
				bodyBytes[cursor + 1] = 0x00
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["self_clean"]
				cursor = cursor + 4
			end
			if(keyP["sound"] ~= nil) then
				bodyBytes[cursor + 0] = 0x2C
				bodyBytes[cursor + 1] = 0x02
				bodyBytes[cursor + 2] = 0x01
				bodyBytes[cursor + 3] = keyP["sound"]
				cursor = cursor + 4
			end

			bodyBytes[cursor] = math.random(0, 100)
			bodyBytes[cursor + 1] = crc8_854(bodyBytes, 0, cursor)

		else
			--构造消息 body 部分
			for i = 0, 22 do
				bodyBytes[i] = 0
			end
			bodyBytes[0] = 0x48
			bodyBytes[1] = bit.bor(keyP["powerValue"], keyB["BYTE_BUZZER_ON"])
			bodyBytes[1] = bit.bor(bodyBytes[1], 0x02)
			bodyBytes[2] = keyP["modeValue"]
			bodyBytes[3] = keyP["windSpeedValue"]
			if(keyP["filter_flag"] == 0) then
				keyP["filterValue"]   = 0x00
			end
			bodyBytes[9] = bit.bor(bit.bor(bit.bor(keyP["anionValue"] ,keyP["filterValue"]  ),keyP["waterPumpValue"]  ),keyP["waterPumpEnableValue"])
			if (keyP["closeTime"]   == nil) then
				keyP["closeTime"]   = 0
			end
			local closeHour = math.floor(keyP["closeTime"]   / 60)
			local closeStepMintues = math.floor((keyP["closeTime"]   % 60) / 15)
			local closeMin = math.floor(((keyP["closeTime"]   % 60) % 15))
			if (keyP["openTime"]   == nil) then
				keyP["openTime"]   = 0
			end
			local openHour = math.floor(keyP["openTime"]   / 60)
			local openStepMintues = math.floor((keyP["openTime"]   % 60) / 15)
			local openMin = math.floor(((keyP["openTime"]   % 60) % 15))
			if (keyP["openTimerSwitch"]   == keyB["BYTE_START_TIMER_SWITCH_ON"]) then
				bodyBytes[4] = bit.bor(bit.bor(keyP["openTimerSwitch"]  , bit.lshift(openHour, 2)), openStepMintues)
				bodyBytes[6] = bit.bor(bodyBytes[6], bit.lshift((15 - openMin), 4))
				bodyBytes[3] = bit.bor(bodyBytes[3], 0x80)
			elseif (keyP["openTimerSwitch"]   == keyB["BYTE_START_TIMER_SWITCH_OFF"] ) then
				bodyBytes[4] = 0x7F
				bodyBytes[3] = bit.bor(bodyBytes[3], 0x80)
			end
			if (keyP["closeTimerSwitch"]   == keyB["BYTE_CLOSE_TIMER_SWITCH_ON"]) then
				bodyBytes[5] = bit.bor(bit.bor(keyP["closeTimerSwitch"]  , bit.lshift(closeHour, 2)), closeStepMintues)
				bodyBytes[6] = bit.bor(bodyBytes[6], (15 - closeMin))
				bodyBytes[3] = bit.bor(bodyBytes[3], 0x80)
			elseif (keyP["closeTimerSwitch"]   == keyB["BYTE_CLOSE_TIMER_SWITCH_OFF"]) then
				bodyBytes[5] = 0x7F
				bodyBytes[3] = bit.bor(bodyBytes[3], 0x80)
			end
			--bodyBytes[6] = bit.bor(bit.lshift((15 - openMin), 4), (15 - closeMin))

			bodyBytes[7] = keyP["humidityValue"]
			bodyBytes[10] = bit.bor(bit.lshift(keyP["swingUDValue"]  ,3), bodyBytes[10])
			bodyBytes[13] = keyP["waterLevelValue"]
			bodyBytes[14] = keyP["purifier"]
			bodyBytes[21] = math.random(0, 100)
			bodyBytes[22] = crc8_854(bodyBytes, 0, 21)
		end

    end


    --lua table 索引从 1 开始，因此此处要重新转换一次
    --local bodyBytes = {}
	local infoM = {}

    --for i = 1, msgLength + 1  do
        --bodyBytes[i] = msgBytes[i - 1]
    --end
	if(keyP["isB5query"] == 0) then
		bodyLength = #bodyBytes
		local msgLength = bodyLength + keyB["BYTE_PROTOCOL_LENGTH"] + 1
		local msgBytes = {}
		for i = 0, msgLength do
			msgBytes[i] = 0
		end
		--构造消息部分
		msgBytes[0] = keyB["BYTE_PROTOCOL_HEAD"]
		msgBytes[1] = bodyLength + keyB["BYTE_PROTOCOL_LENGTH"] + 1
		msgBytes[2] = keyB["BYTE_DEVICE_TYPE"]
		if(query)then
			msgBytes[9] = 0x03
		elseif(control) then
			msgBytes[9] = 0x02
		end

		for i = 0, bodyLength do
				msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]] = bodyBytes[i]
		end

		msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
		for i = 1, msgLength + 1  do
			infoM[i] = msgBytes[i - 1]
		end
	else
		for i = 1, b5BodyLength + 1  do
			infoM[i] = b5Body[i]
		end
		keyP["isB5query"] = 0
	end
    --table 转换成 string 之后返回
    --local ret = table2string(bodyBytes)
	local ret = table2string(infoM)
    ret = string2hexstring(ret)

    return ret
end
