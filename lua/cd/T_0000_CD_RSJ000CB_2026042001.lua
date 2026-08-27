local JSON = require"cjson"
local KEY_VERSION = "version"
local KEY_POWER = "power"
local KEY_MODE = "mode"
local KEY_ERROR_CODE = "error_code"
local VALUE_VERSION = "8"
local VALUE_FUNCTION_ON = "on"
local VALUE_FUNCTION_OFF = "off"
local BYTE_DEVICE_TYPE = 205
local BYTE_CONTROL_REQUEST = 2
local BYTE_QUERYL_REQUEST = 3
local BYTE_AUTO_REPORT = 5
local BYTE_CONTROL_REQUEST_ONE = 1
local BYTE_CONTROL_REQUEST_TWO = 2
local BYTE_CONTROL_REQUEST_THREE = 3
local BYTE_CONTROL_REQUEST_FOUR = 4
local BYTE_CONTROL_REQUEST_FIVE = 5
local BYTE_CONTROL_REQUEST_SIX = 6
local BYTE_CONTROL_REQUEST_SEVEN = 7
local BYTE_QUERYL_REQUEST_ONE = 1
local BYTE_QUERYL_REQUEST_TWO = 2
local BYTE_QUERYL_REQUEST_THREE = 3
local BYTE_PROTOCOL_HEAD = 170
local BYTE_PROTOCOL_LENGTH = 10
local BYTE_POWER_ON = 1
local BYTE_POWER_OFF = 0
local myTable = {["powerValue" ] = 0,["modeValue"] = 0,["energyMode"] = 0,["standardMode"] = 0,["compatibilizingMode"] = 0,["vacationMode"] = 0,["vacadaysValue"] = 0,["vacadaysStartYearValue"] = 0,["vacadaysStartMonthValue"] = 0,["vacadaysStartDayValue"] = 0,["vacationTsValue"] = 0,["heatValue"] = 0,["dicaryonHeat"] = 0,["eco"] = 0,["smartGrid"] = 0,["multiTerminal"] = 0,["tsValue"] = 0,["washBoxTemp"] = 0,["boxTopTemp"] = 0,["boxBottomTemp"] = 0,["t3Value"] = 0,["t4Value"] = 0,["compressorTopTemp"] = 0,["tsMaxValue"] = 0,["tsMinValue"] = 0,["timer1OpenHour"] = 0,["timer1OpenMin"] = 0,["timer1CloseHour"] = 0,["timer1CloseMin"] = 0,["timer2OpenHour"] = 0,["timer2OpenMin"] = 0,["timer2CloseHour"] = 0,["timer2CloseMin"] = 0,["timer3OpenHour"] = 0,["timer3OpenMin"] = 0,["timer3CloseHour"] = 0,["timer3CloseMin"] = 0,["timer4OpenHour"] = 0,["timer4OpenMin"] = 0,["timer4CloseHour"] = 0,["timer4CloseMin"] = 0,["timer5OpenHour"] = 0,["timer5OpenMin"] = 0,["timer5CloseHour"] = 0,["timer5CloseMin"] = 0,["timer6OpenHour"] = 0,["timer6OpenMin"] = 0,["timer6CloseHour"] = 0,["timer6CloseMin"] = 0,["timer1SetTemperature"] = 0,["timer1ModeValue"] = 0,["timer2SetTemperature"] = 0,["timer2ModeValue"] = 0,["timer3SetTemperature"] = 0,["timer3ModeValue"] = 0,["timer4SetTemperature"] = 0,["timer4ModeValue"] = 0,["timer5SetTemperature"] = 0,["timer5ModeValue"] = 0,["timer6SetTemperature"] = 0,["timer6ModeValue"] = 0,["week0timer1SetTemperature"] = 0,["week0timer1ModeValue"] = 0,["week0timer2SetTemperature"] = 0,["week0timer2ModeValue"] = 0,["week0timer3SetTemperature"] = 0,["week0timer3ModeValue"] = 0,["week0timer4SetTemperature"] = 0,["week0timer4ModeValue"] = 0,["week0timer5SetTemperature"] = 0,["week0timer5ModeValue"] = 0,["week0timer6SetTemperature"] = 0,["week0timer6ModeValue"] = 0,["week1timer1SetTemperature"] = 0,["week1timer1ModeValue"] = 0,["week1timer2SetTemperature"] = 0,["week1timer2ModeValue"] = 0,["week1timer3SetTemperature"] = 0,["week1timer3ModeValue"] = 0,["week1timer4SetTemperature"] = 0,["week1timer4ModeValue"] = 0,["week1timer5SetTemperature"] = 0,["week1timer5ModeValue"] = 0,["week1timer6SetTemperature"] = 0,["week1timer6ModeValue"] = 0,["week2timer1SetTemperature"] = 0,["week2timer1ModeValue"] = 0,["week2timer2SetTemperature"] = 0,["week2timer2ModeValue"] = 0,["week2timer3SetTemperature"] = 0,["week2timer3ModeValue"] = 0,["week2timer4SetTemperature"] = 0,["week2timer4ModeValue"] = 0,["week2timer5SetTemperature"] = 0,["week2timer5ModeValue"] = 0,["week2timer6SetTemperature"] = 0,["week2timer6ModeValue"] = 0,["week3timer1SetTemperature"] = 0,["week3timer1ModeValue"] = 0,["week3timer2SetTemperature"] = 0,["week3timer2ModeValue"] = 0,["week3timer3SetTemperature"] = 0,["week3timer3ModeValue"] = 0,["week3timer4SetTemperature"] = 0,["week3timer4ModeValue"] = 0,["week3timer5SetTemperature"] = 0,["week3timer5ModeValue"] = 0,["week3timer6SetTemperature"] = 0,["week3timer6ModeValue"] = 0,["week4timer1SetTemperature"] = 0,["week4timer1ModeValue"] = 0,["week4timer2SetTemperature"] = 0,["week4timer2ModeValue"] = 0,["week4timer3SetTemperature"] = 0,["week4timer3ModeValue"] = 0,["week4timer4SetTemperature"] = 0,["week4timer4ModeValue"] = 0,["week4timer5SetTemperature"] = 0,["week4timer5ModeValue"] = 0,["week4timer6SetTemperature"] = 0,["week4timer6ModeValue"] = 0,["week5timer1SetTemperature"] = 0,["week5timer1ModeValue"] = 0,["week5timer2SetTemperature"] = 0,["week5timer2ModeValue"] = 0,["week5timer3SetTemperature"] = 0,["week5timer3ModeValue"] = 0,["week5timer4SetTemperature"] = 0,["week5timer4ModeValue"] = 0,["week5timer5SetTemperature"] = 0,["week5timer5ModeValue"] = 0,["week5timer6SetTemperature"] = 0,["week5timer6ModeValue"] = 0,["week6timer1SetTemperature"] = 0,["week6timer1ModeValue"] = 0,["week6timer2SetTemperature"] = 0,["week6timer2ModeValue"] = 0,["week6timer3SetTemperature"] = 0,["week6timer3ModeValue"] = 0,["week6timer4SetTemperature"] = 0,["week6timer4ModeValue"] = 0,["week6timer5SetTemperature"] = 0,["week6timer5ModeValue"] = 0,["week6timer6SetTemperature"] = 0,["week6timer6ModeValue"] = 0,["week0timer1OpenTime"] = 0,["week0timer1CloseTime"] = 0,["week0timer2OpenTime"] = 0,["week0timer2CloseTime"] = 0,["week0timer3OpenTime"] = 0,["week0timer3CloseTime"] = 0,["week0timer4OpenTime"] = 0,["week0timer4CloseTime"] = 0,["week0timer5OpenTime"] = 0,["week0timer5CloseTime"] = 0,["week0timer6OpenTime"] = 0,["week0timer6CloseTime"] = 0,["week1timer1OpenTime"] = 0,["week1timer1CloseTime"] = 0,["week1timer2OpenTime"] = 0,["week1timer2CloseTime"] = 0,["week1timer3OpenTime"] = 0,["week1timer3CloseTime"] = 0,["week1timer4OpenTime"] = 0,["week1timer4CloseTime"] = 0,["week1timer5OpenTime"] = 0,["week1timer5CloseTime"] = 0,["week1timer6OpenTime"] = 0,["week1timer6CloseTime"] = 0,["week2timer1OpenTime"] = 0,["week2timer1CloseTime"] = 0,["week2timer2OpenTime"] = 0,["week2timer2CloseTime"] = 0,["week2timer3OpenTime"] = 0,["week2timer3CloseTime"] = 0,["week2timer4OpenTime"] = 0,["week2timer4CloseTime"] = 0,["week2timer5OpenTime"] = 0,["week2timer5CloseTime"] = 0,["week2timer6OpenTime"] = 0,["week2timer6CloseTime"] = 0,["week3timer1OpenTime"] = 0,["week3timer1CloseTime"] = 0,["week3timer2OpenTime"] = 0,["week3timer2CloseTime"] = 0,["week3timer3OpenTime"] = 0,["week3timer3CloseTime"] = 0,["week3timer4OpenTime"] = 0,["week3timer4CloseTime"] = 0,["week3timer5OpenTime"] = 0,["week3timer5CloseTime"] = 0,["week3timer6OpenTime"] = 0,["week3timer6CloseTime"] = 0,["week4timer1OpenTime"] = 0,["week4timer1CloseTime"] = 0,["week4timer2OpenTime"] = 0,["week4timer2CloseTime"] = 0,["week4timer3OpenTime"] = 0,["week4timer3CloseTime"] = 0,["week4timer4OpenTime"] = 0,["week4timer4CloseTime"] = 0,["week4timer5OpenTime"] = 0,["week4timer5CloseTime"] = 0,["week4timer6OpenTime"] = 0,["week4timer6CloseTime"] = 0,["week5timer1OpenTime"] = 0,["week5timer1CloseTime"] = 0,["week5timer2OpenTime"] = 0,["week5timer2CloseTime"] = 0,["week5timer3OpenTime"] = 0,["week5timer3CloseTime"] = 0,["week5timer4OpenTime"] = 0,["week5timer4CloseTime"] = 0,["week5timer5OpenTime"] = 0,["week5timer5CloseTime"] = 0,["week5timer6OpenTime"] = 0,["week5timer6CloseTime"] = 0,["week6timer1OpenTime"] = 0,["week6timer1CloseTime"] = 0,["week6timer2OpenTime"] = 0,["week6timer2CloseTime"] = 0,["week6timer3OpenTime"] = 0,["week6timer3CloseTime"] = 0,["week6timer4OpenTime"] = 0,["week6timer4CloseTime"] = 0,["week6timer5OpenTime"] = 0,["week6timer5CloseTime"] = 0,["week6timer6OpenTime"] = 0,["week6timer6CloseTime"] = 0,["errorCode"] = 0,["order1Temp" ] = 0,["order1TimeHour"] = 0,["order1TimeMin"] = 0,["order2Temp"] = 0,["order2TimeHour"] = 0,["order2TimeMin"] = 0,["bottomElecHeat" ] = 0,["topElecHeat"] = 0,["waterPump"] = 0,["compressor"] = 0,["middleWind"] = 0,["fourWayValve"] = 0,["lowWind"] = 0,["highWind"] = 0,["week0timer1Effect"] = 0,["week0timer2Effect"] = 0,["week0timer3Effect"] = 0,["week0timer4Effect"] = 0,["week0timer5Effect"] = 0,["week0timer6Effect"] = 0,["week1timer1Effect"] = 0,["week1timer2Effect"] = 0,["week1timer3Effect"] = 0,["week1timer4Effect"] = 0,["week1timer5Effect"] = 0,["week1timer6Effect"] = 0,["week2timer1Effect"] = 0,["week2timer2Effect"] = 0,["week2timer3Effect"] = 0,["week2timer4Effect"] = 0,["week2timer5Effect"] = 0,["week2timer6Effect"] = 0,["week3timer1Effect"] = 0,["week3timer2Effect"] = 0,["week3timer3Effect"] = 0,["week3timer4Effect"] = 0,["week3timer5Effect"] = 0,["week3timer6Effect"] = 0,["week4timer1Effect"] = 0,["week4timer2Effect"] = 0,["week4timer3Effect"] = 0,["week4timer4Effect"] = 0,["week4timer5Effect"] = 0,["week4timer6Effect"] = 0,["week5timer1Effect"] = 0,["week5timer2Effect"] = 0,["week5timer3Effect"] = 0,["week5timer4Effect"] = 0,["week5timer5Effect"] = 0,["week5timer6Effect"] = 0,["week6timer1Effect"] = 0,["week6timer2Effect"] = 0,["week6timer3Effect"] = 0,["week6timer4Effect"] = 0,["week6timer5Effect"] = 0,["week6timer6Effect"] = 0,["timer1Effect"] = 0,["timer2Effect"] = 0,["timer3Effect"] = 0,["timer4Effect"] = 0,["timer5Effect"] = 0,["timer6Effect"] = 0,["order1Effect"] = 0,["order2Effect"] = 0,["smartMode"] = 0,["backwaterEffect"] = 0,["sterilizeEffect"] = 0,["typeInfo"] = 0,["order1StopTimeHour"] = 0,["order1StopTimeMin"] = 0,["order2StopTimeHour"] = 0,["order2StopTimeMin"] = 0,["dataType"] = 0,["controlType"] = 0,["queryType"] = 0,["trValue"] = 0,["openPTC"] = 0,["ptcTemp"] = 0,["refrigerantRecycling"] = 0,["defrost"] = 0,["mute"] = 0,["openPTCTemp"] = 0,["hotWater"] = 0,["elecHeatSupport"] = 0,["dateYearValue"] = 0,["dateMonthValue"] = 0,["dateDayValue"] = 0,["dateWeekValue"] = 0,["dateHourValue"] = 0,["dateMinuteValue"] = 0,["autoSterilizeWeek"] = 0,["autoSterilizeHour"] = 0,["autoSterilizeMinute"] = 0,["fahrenheitEffect"] = 0,}
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
	if (not data) then
		data = 0
	end
	data = tonumber(data)
	if (data == nil) then
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
local function string2Int(data)
	if (not data) then
		data = tonumber("0")
	end
	data = tonumber(data)
	if (data == nil) then
		data = 0
	end
	return data
end
local function int2String(data)
	if (not data) then
		data = tostring(0)
	end
	data = tostring(data)
	if (data == nil) then
		data = "0"
	end
	return data
end
local function table2string(cmd)
	local ret = ""
	local i
	for i = 1, # cmd do
		ret = ret .. string.char(cmd[i])
	end
	return ret
end
local function string2table(hexstr)
	local tb = {}
	local i = 1
	local j = 1
	for i = 1, # hexstr - 1, 2 do
		local doublebytestr = string.sub(hexstr, i, i + 1)
		tb[j] = tonumber(doublebytestr, 16)
		j = j + 1
	end
	return tb
end
local function string2hexstring(str)
	local ret = ""
	for i = 1, # str do
		ret = ret .. string.format("%02x", str:byte(i))
	end
	return ret
end
local function encode(cmd)
	local tb
	if JSON == nil then
		JSON = require"cjson"
	end
	tb = JSON.encode(cmd)
	return tb
end
local function decode(cmd)
	local tb
	if JSON == nil then
		JSON = require"cjson"
	end
	tb = JSON.decode(cmd)
	return tb
end
local function makeSum(tmpbuf, start_pos, end_pos)
	local resVal = 0
	for si = start_pos, end_pos do
		resVal = resVal + tmpbuf[si]
	end
	resVal = bit.bnot(resVal) + 1
	resVal = bit.band(resVal, 255)
	return resVal
end
local crc8_854_table = {0,94,188,226,97,63,221,131,194,156,126,32,163,253,31,65,157,195,33,127,252,162,64,30,95,1,227,189,62,96,130,220,35,125,159,193,66,28,254,160,225,191,93,3,128,222,60,98,190,224,2,92,223,129,99,61,124,34,192,158,29,67,161,255,70,24,250,164,39,121,155,197,132,218,56,102,229,187,89,7,219,133,103,57,186,228,6,88,25,71,165,251,120,38,196,154,101,59,217,135,4,90,184,230,167,249,27,69,198,152,122,36,248,166,68,26,153,199,37,123,58,100,134,216,91,5,231,185,140,210,48,110,237,179,81,15,78,16,242,172,47,113,147,205,17,79,173,243,112,46,204,146,211,141,111,49,178,236,14,80,175,241,19,77,206,144,114,44,109,51,209,143,12,82,176,238,50,108,142,208,83,13,239,177,240,174,76,18,145,207,45,115,202,148,118,40,171,245,23,73,8,86,180,234,105,55,213,139,87,9,235,181,54,104,138,212,149,203,41,119,244,170,72,22,233,183,85,11,136,214,52,106,43,117,151,201,74,20,246,168,116,42,200,150,21,75,169,247,182,232,10,84,215,137,107,53}
local function crc8_854(dataBuf, start_pos, end_pos)
	local crc = 0
	for si = start_pos, end_pos do
		crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 255) + 1]
	end
	return crc
end
local function string2Int(data)
	if (not data) then
		data = tonumber("0")
	end
	data = tonumber(data)
	if (data == nil) then
		data = 0
	end
	return data
end
local function int2String(data)
	if (not data) then
		data = tostring(0)
	end
	data = tostring(data)
	if (data == nil) then
		data = "0"
	end
	return data
end
local function getTotalMsg(bodyData, cType)
	local bodyLength = # bodyData
	local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
	local msgBytes = {}
	for i = 0, msgLength do
		msgBytes[i] = 0
	end
	msgBytes[0] = BYTE_PROTOCOL_HEAD
	msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
	msgBytes[2] = BYTE_DEVICE_TYPE
	msgBytes[9] = cType
	for i = 0, bodyLength do
		msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyData[i]
	end
	msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
	local msgFinal = {}
	for i = 1, msgLength + 1 do
		msgFinal[i] = msgBytes[i - 1]
	end
	return msgFinal
end
local function jsonToModel(controlJson)
	local controlCmd = controlJson
	myTable["controlType"] = 1;
	if (controlCmd["control_type"] ~= nil) then
		myTable["controlType"] = string2Int(controlCmd["control_type"])
	end
	if (myTable["controlType"] == 1) then
		if controlCmd[KEY_POWER] ~= nil then
			if controlCmd[KEY_POWER] == VALUE_FUNCTION_ON then
				myTable["powerValue"] = BYTE_POWER_ON
			else
				myTable["powerValue"] = BYTE_POWER_OFF
			end
		end
		if controlCmd[KEY_MODE] ~= nil then
			if controlCmd[KEY_MODE] == "energy" then
				myTable["modeValue"] = 1
			elseif controlCmd[KEY_MODE] == "standard" then
				myTable["modeValue"] = 2
			elseif controlCmd[KEY_MODE] == "compatibilizing" then
				myTable["modeValue"] = 3
			elseif controlCmd[KEY_MODE] == "smart" then
				myTable["modeValue"] = 4
			end
		end
		if controlCmd["set_temperature"] ~= nil then
			myTable["tsValue"] = string2Int(controlCmd["set_temperature"])
			myTable["tsValue"] = myTable["tsValue"]
		end
		if controlCmd["tr_temperature"] ~= nil then
			myTable["trValue"] = string2Int(controlCmd["tr_temperature"])
			myTable["trValue"] = checkBoundary(myTable["trValue"], 2, 6)
		end
		if controlCmd["open_ptc"] ~= nil then
			if controlCmd["open_ptc"] == "0" then
				myTable["openPTC"] = 0
			elseif controlCmd["open_ptc"] == "1" then
				myTable["openPTC"] = 1
			elseif controlCmd["open_ptc"] == "2" then
				myTable["openPTC"] = 2
			end
		end
		if controlCmd["ptc_temperature"] ~= nil then
			myTable["ptcTemp"] = string2Int(controlCmd["ptc_temperature"])
		end
		if controlCmd["water_pump"] ~= nil then
			if controlCmd["water_pump"] == VALUE_FUNCTION_ON then
				myTable["waterPump"] = BYTE_POWER_ON
			elseif controlCmd["water_pump"] == VALUE_FUNCTION_OFF then
				myTable["waterPump"] = BYTE_POWER_OFF
			end
		end
		if controlCmd["refrigerant_recycling"] ~= nil then
			if controlCmd["refrigerant_recycling"] == VALUE_FUNCTION_ON then
				myTable["refrigerantRecycling"] = BYTE_POWER_ON
			elseif controlCmd["refrigerant_recycling"] == VALUE_FUNCTION_OFF then
				myTable["refrigerantRecycling"] = BYTE_POWER_OFF
			end
		end
		if controlCmd["defrost"] ~= nil then
			if controlCmd["defrost"] == VALUE_FUNCTION_ON then
				myTable["defrost"] = BYTE_POWER_ON
			elseif controlCmd["defrost"] == VALUE_FUNCTION_OFF then
				myTable["defrost"] = BYTE_POWER_OFF
			end
		end
		if controlCmd["mute"] ~= nil then
			if controlCmd["mute"] == VALUE_FUNCTION_ON then
				myTable["mute"] = BYTE_POWER_ON
			elseif controlCmd["mute"] == VALUE_FUNCTION_OFF then
				myTable["mute"] = BYTE_POWER_OFF
			end
		end
		if controlCmd["vacation"] ~= nil then
			if controlCmd["vacation"] == VALUE_FUNCTION_ON then
				myTable["vacationMode"] = 16
			elseif controlCmd["vacation"] == VALUE_FUNCTION_OFF then
				myTable["vacationMode"] = 0
			end
		end
		if controlCmd["fahrenheit_effect"] ~= nil then
			if controlCmd["fahrenheit_effect"] == VALUE_FUNCTION_ON then
				myTable["fahrenheitEffect"] = 128
			elseif controlCmd["fahrenheit_effect"] == VALUE_FUNCTION_OFF then
				myTable["fahrenheitEffect"] = 0
			end
		end
		if controlCmd["open_ptc_temperature"] ~= nil then
			if controlCmd["open_ptc_temperature"] == VALUE_FUNCTION_ON then
				myTable["openPTCTemp"] = BYTE_POWER_ON
			elseif controlCmd["open_ptc_temperature"] == VALUE_FUNCTION_OFF then
				myTable["openPTCTemp"] = BYTE_POWER_OFF
			end
		end
		if controlCmd["set_vacationdays"] ~= nil then
			myTable["vacadaysValue"] = string2Int(controlCmd["set_vacationdays"])
		end
		if controlCmd["set_vacation_start_year"] ~= nil then
			myTable["vacadaysStartYearValue"] = string2Int(controlCmd["set_vacation_start_year"])
		end
		if controlCmd["set_vacation_start_month"] ~= nil then
			myTable["vacadaysStartMonthValue"] = string2Int(controlCmd["set_vacation_start_month"])
		end
		if controlCmd["set_vacation_start_day"] ~= nil then
			myTable["vacadaysStartDayValue"] = string2Int(controlCmd["set_vacation_start_day"])
		end
		if controlCmd["set_vacation_temperature"] ~= nil then
			myTable["vacationTsValue"] = string2Int(controlCmd["set_vacation_temperature"])
		end
		if controlCmd["date_year"] ~= nil then
			myTable["dateYearValue"] = string2Int(controlCmd["date_year"])
		end
		if controlCmd["date_month"] ~= nil then
			myTable["dateMonthValue"] = string2Int(controlCmd["date_month"])
		end
		if controlCmd["date_day"] ~= nil then
			myTable["dateDayValue"] = string2Int(controlCmd["date_day"])
		end
		if controlCmd["date_week"] ~= nil then
			myTable["dateWeekValue"] = string2Int(controlCmd["date_week"])
		end
		if controlCmd["date_hour"] ~= nil then
			myTable["dateHourValue"] = string2Int(controlCmd["date_hour"])
		end
		if controlCmd["date_minute"] ~= nil then
			myTable["dateMinuteValue"] = string2Int(controlCmd["date_minute"])
		end
	elseif (myTable["controlType"] == 2) then
		if controlCmd["timer1_effect"] ~= nil then
			if controlCmd["timer1_effect"] == VALUE_FUNCTION_ON then
				myTable["timer1Effect"] = 1
			elseif controlCmd["timer1_effect"] == VALUE_FUNCTION_OFF then
				myTable["timer1Effect"] = 0
			end
		end
		if controlCmd["timer2_effect"] ~= nil then
			if controlCmd["timer2_effect"] == VALUE_FUNCTION_ON then
				myTable["timer2Effect"] = 2
			elseif controlCmd["timer2_effect"] == VALUE_FUNCTION_OFF then
				myTable["timer2Effect"] = 0
			end
		end
		if controlCmd["timer3_effect"] ~= nil then
			if controlCmd["timer3_effect"] == VALUE_FUNCTION_ON then
				myTable["timer3Effect"] = 4
			elseif controlCmd["timer3_effect"] == VALUE_FUNCTION_OFF then
				myTable["timer3Effect"] = 0
			end
		end
		if controlCmd["timer4_effect"] ~= nil then
			if controlCmd["timer4_effect"] == VALUE_FUNCTION_ON then
				myTable["timer4Effect"] = 8
			elseif controlCmd["timer4_effect"] == VALUE_FUNCTION_OFF then
				myTable["timer4Effect"] = 0
			end
		end
		if controlCmd["timer5_effect"] ~= nil then
			if controlCmd["timer5_effect"] == VALUE_FUNCTION_ON then
				myTable["timer5Effect"] = 16
			elseif controlCmd["timer5_effect"] == VALUE_FUNCTION_OFF then
				myTable["timer5Effect"] = 0
			end
		end
		if controlCmd["timer6_effect"] ~= nil then
			if controlCmd["timer6_effect"] == VALUE_FUNCTION_ON then
				myTable["timer6Effect"] = 32
			elseif controlCmd["timer6_effect"] == VALUE_FUNCTION_OFF then
				myTable["timer6Effect"] = 0
			end
		end
		if controlCmd["timer1_openHour"] ~= nil then
			myTable["timer1OpenHour"] = string2Int(controlCmd["timer1_openHour"])
		end
		if controlCmd["timer1_openhour"] ~= nil then
			myTable["timer1OpenHour"] = string2Int(controlCmd["timer1_openhour"])
		end
		if controlCmd["timer1_openMin"] ~= nil then
			myTable["timer1OpenMin"] = string2Int(controlCmd["timer1_openMin"])
		end
		if controlCmd["timer1_openmin"] ~= nil then
			myTable["timer1OpenMin"] = string2Int(controlCmd["timer1_openmin"])
		end
		if controlCmd["timer1_closeHour"] ~= nil then
			myTable["timer1CloseHour"] = string2Int(controlCmd["timer1_closeHour"])
		end
		if controlCmd["timer1_closehour"] ~= nil then
			myTable["timer1CloseHour"] = string2Int(controlCmd["timer1_closehour"])
		end
		if controlCmd["timer1_closeMin"] ~= nil then
			myTable["timer1CloseMin"] = string2Int(controlCmd["timer1_closeMin"])
		end
		if controlCmd["timer1_closemin"] ~= nil then
			myTable["timer1CloseMin"] = string2Int(controlCmd["timer1_closemin"])
		end
		if controlCmd["timer1_set_temperature"] ~= nil then
			myTable["timer1SetTemperature"] = string2Int(controlCmd["timer1_set_temperature"])
		end
		if controlCmd["timer2_openHour"] ~= nil then
			myTable["timer2OpenHour"] = string2Int(controlCmd["timer2_openHour"])
		end
		if controlCmd["timer2_openhour"] ~= nil then
			myTable["timer2OpenHour"] = string2Int(controlCmd["timer2_openhour"])
		end
		if controlCmd["timer2_openMin"] ~= nil then
			myTable["timer2OpenMin"] = string2Int(controlCmd["timer2_openMin"])
		end
		if controlCmd["timer2_openmin"] ~= nil then
			myTable["timer2OpenMin"] = string2Int(controlCmd["timer2_openmin"])
		end
		if controlCmd["timer2_closeHour"] ~= nil then
			myTable["timer2CloseHour"] = string2Int(controlCmd["timer2_closeHour"])
		end
		if controlCmd["timer2_closehour"] ~= nil then
			myTable["timer2CloseHour"] = string2Int(controlCmd["timer2_closehour"])
		end
		if controlCmd["timer2_closeMin"] ~= nil then
			myTable["timer2CloseMin"] = string2Int(controlCmd["timer2_closeMin"])
		end
		if controlCmd["timer2_closemin"] ~= nil then
			myTable["timer2CloseMin"] = string2Int(controlCmd["timer2_closemin"])
		end
		if controlCmd["timer2_set_temperature"] ~= nil then
			myTable["timer2SetTemperature"] = string2Int(controlCmd["timer2_set_temperature"])
		end
		if controlCmd["timer3_openhour"] ~= nil then
			myTable["timer3OpenHour"] = string2Int(controlCmd["timer3_openhour"])
		end
		if controlCmd["timer3_openmin"] ~= nil then
			myTable["timer3OpenMin"] = string2Int(controlCmd["timer3_openmin"])
		end
		if controlCmd["timer3_closehour"] ~= nil then
			myTable["timer3CloseHour"] = string2Int(controlCmd["timer3_closehour"])
		end
		if controlCmd["timer3_closemin"] ~= nil then
			myTable["timer3CloseMin"] = string2Int(controlCmd["timer3_closemin"])
		end
		if controlCmd["timer3_set_temperature"] ~= nil then
			myTable["timer3SetTemperature"] = string2Int(controlCmd["timer3_set_temperature"])
		end
		if controlCmd["timer4_openhour"] ~= nil then
			myTable["timer4OpenHour"] = string2Int(controlCmd["timer4_openhour"])
		end
		if controlCmd["timer4_openmin"] ~= nil then
			myTable["timer4OpenMin"] = string2Int(controlCmd["timer4_openmin"])
		end
		if controlCmd["timer4_closehour"] ~= nil then
			myTable["timer4CloseHour"] = string2Int(controlCmd["timer4_closehour"])
		end
		if controlCmd["timer4_closemin"] ~= nil then
			myTable["timer4CloseMin"] = string2Int(controlCmd["timer4_closemin"])
		end
		if controlCmd["timer4_set_temperature"] ~= nil then
			myTable["timer4SetTemperature"] = string2Int(controlCmd["timer4_set_temperature"])
		end
		if controlCmd["timer5_openhour"] ~= nil then
			myTable["timer5OpenHour"] = string2Int(controlCmd["timer5_openhour"])
		end
		if controlCmd["timer5_openmin"] ~= nil then
			myTable["timer5OpenMin"] = string2Int(controlCmd["timer5_openmin"])
		end
		if controlCmd["timer5_closehour"] ~= nil then
			myTable["timer5CloseHour"] = string2Int(controlCmd["timer5_closehour"])
		end
		if controlCmd["timer5_closemin"] ~= nil then
			myTable["timer5CloseMin"] = string2Int(controlCmd["timer5_closemin"])
		end
		if controlCmd["timer5_set_temperature"] ~= nil then
			myTable["timer5SetTemperature"] = string2Int(controlCmd["timer5_set_temperature"])
		end
		if controlCmd["timer6_openhour"] ~= nil then
			myTable["timer6OpenHour"] = string2Int(controlCmd["timer6_openhour"])
		end
		if controlCmd["timer6_openmin"] ~= nil then
			myTable["timer6OpenMin"] = string2Int(controlCmd["timer6_openmin"])
		end
		if controlCmd["timer6_closehour"] ~= nil then
			myTable["timer6CloseHour"] = string2Int(controlCmd["timer6_closehour"])
		end
		if controlCmd["timer6_closemin"] ~= nil then
			myTable["timer6CloseMin"] = string2Int(controlCmd["timer6_closemin"])
		end
		if controlCmd["timer6_set_temperature"] ~= nil then
			myTable["timer6SetTemperature"] = string2Int(controlCmd["timer6_set_temperature"])
		end
		if controlCmd["timer1_modevalue"] ~= nil then
			if controlCmd["timer1_modevalue"] == "energy" then
				myTable["timer1ModeValue"] = 1
			elseif controlCmd["timer1_modevalue"] == "standard" then
				myTable["timer1ModeValue"] = 2
			elseif controlCmd["timer1_modevalue"] == "compatibilizing" then
				myTable["timer1ModeValue"] = 3
			elseif controlCmd["timer1_modevalue"] == "smart" then
				myTable["timer1ModeValue"] = 4
			end
		end
		if controlCmd["timer2_modevalue"] ~= nil then
			if controlCmd["timer2_modevalue"] == "energy" then
				myTable["timer2ModeValue"] = 1
			elseif controlCmd["timer2_modevalue"] == "standard" then
				myTable["timer2ModeValue"] = 2
			elseif controlCmd["timer2_modevalue"] == "compatibilizing" then
				myTable["timer2ModeValue"] = 3
			elseif controlCmd["timer2_modevalue"] == "smart" then
				myTable["timer2ModeValue"] = 4
			end
		end
		if controlCmd["timer3_modevalue"] ~= nil then
			if controlCmd["timer3_modevalue"] == "energy" then
				myTable["timer3ModeValue"] = 1
			elseif controlCmd["timer3_modevalue"] == "standard" then
				myTable["timer3ModeValue"] = 2
			elseif controlCmd["timer3_modevalue"] == "compatibilizing" then
				myTable["timer3ModeValue"] = 3
			elseif controlCmd["timer3_modevalue"] == "smart" then
				myTable["timer3ModeValue"] = 4
			end
		end
		if controlCmd["timer4_modevalue"] ~= nil then
			if controlCmd["timer4_modevalue"] == "energy" then
				myTable["timer4ModeValue"] = 1
			elseif controlCmd["timer4_modevalue"] == "standard" then
				myTable["timer4ModeValue"] = 2
			elseif controlCmd["timer4_modevalue"] == "compatibilizing" then
				myTable["timer4ModeValue"] = 3
			elseif controlCmd["timer4_modevalue"] == "smart" then
				myTable["timer4ModeValue"] = 4
			end
		end
		if controlCmd["timer5_modevalue"] ~= nil then
			if controlCmd["timer5_modevalue"] == "energy" then
				myTable["timer5ModeValue"] = 1
			elseif controlCmd["timer5_modevalue"] == "standard" then
				myTable["timer5ModeValue"] = 2
			elseif controlCmd["timer5_modevalue"] == "compatibilizing" then
				myTable["timer5ModeValue"] = 3
			elseif controlCmd["timer5_modevalue"] == "smart" then
				myTable["timer5ModeValue"] = 4
			end
		end
		if controlCmd["timer6_modevalue"] ~= nil then
			if controlCmd["timer6_modevalue"] == "energy" then
				myTable["timer6ModeValue"] = 1
			elseif controlCmd["timer6_modevalue"] == "standard" then
				myTable["timer6ModeValue"] = 2
			elseif controlCmd["timer6_modevalue"] == "compatibilizing" then
				myTable["timer6ModeValue"] = 3
			elseif controlCmd["timer6_modevalue"] == "smart" then
				myTable["timer6ModeValue"] = 4
			end
		end
	elseif (myTable["controlType"] == 3) then
		if controlCmd["order1_effect"] ~= nil then
			if controlCmd["order1_effect"] == VALUE_FUNCTION_ON then
				myTable["order1Effect"] = 1
			elseif controlCmd["order1_effect"] == VALUE_FUNCTION_OFF then
				myTable["order1Effect"] = 0
			end
		end
		if controlCmd["order2_effect"] ~= nil then
			if controlCmd["order2_effect"] == VALUE_FUNCTION_ON then
				myTable["order2Effect"] = 1
			elseif controlCmd["order2_effect"] == VALUE_FUNCTION_OFF then
				myTable["order2Effect"] = 0
			end
		end
		if controlCmd["order1_timeHour"] ~= nil then
			myTable["order1TimeHour"] = string2Int(controlCmd["order1_timeHour"])
		end
		if controlCmd["order1_timehour"] ~= nil then
			myTable["order1TimeHour"] = string2Int(controlCmd["order1_timehour"])
		end
		if controlCmd["order1_timeMin"] ~= nil then
			myTable["order1TimeMin"] = string2Int(controlCmd["order1_timeMin"])
		end
		if controlCmd["order1_timemin"] ~= nil then
			myTable["order1TimeMin"] = string2Int(controlCmd["order1_timemin"])
		end
		if controlCmd["order1_stoptimeHour"] ~= nil then
			myTable["order1StopTimeHour"] = string2Int(controlCmd["order1_stoptimeHour"])
		end
		if controlCmd["order1_stoptimehour"] ~= nil then
			myTable["order1StopTimeHour"] = string2Int(controlCmd["order1_stoptimehour"])
		end
		if controlCmd["order1_stoptimeMin"] ~= nil then
			myTable["order1StopTimeMin"] = string2Int(controlCmd["order1_stoptimeMin"])
		end
		if controlCmd["order1_stoptimemin"] ~= nil then
			myTable["order1StopTimeMin"] = string2Int(controlCmd["order1_stoptimemin"])
		end
		if controlCmd["order2_timeHour"] ~= nil then
			myTable["order2TimeHour"] = string2Int(controlCmd["order2_timeHour"])
		end
		if controlCmd["order2_timehour"] ~= nil then
			myTable["order2TimeHour"] = string2Int(controlCmd["order2_timehour"])
		end
		if controlCmd["order2_timeMin"] ~= nil then
			myTable["order2TimeMin"] = string2Int(controlCmd["order2_timeMin"])
		end
		if controlCmd["order2_timemin"] ~= nil then
			myTable["order2TimeMin"] = string2Int(controlCmd["order2_timemin"])
		end
		if controlCmd["order2_stoptimeHour"] ~= nil then
			myTable["order2StopTimeHour"] = string2Int(controlCmd["order2_stoptimeHour"])
		end
		if controlCmd["order2_stoptimehour"] ~= nil then
			myTable["order2StopTimeHour"] = string2Int(controlCmd["order2_stoptimehour"])
		end
		if controlCmd["order2_stoptimeMin"] ~= nil then
			myTable["order2StopTimeMin"] = string2Int(controlCmd["order2_stoptimeMin"])
		end
		if controlCmd["order2_stoptimemin"] ~= nil then
			myTable["order2StopTimeMin"] = string2Int(controlCmd["order2_stoptimemin"])
		end
		if controlCmd["order1_temp"] ~= nil then
			myTable["order1Temp"] = string2Int(controlCmd["order1_temp"])
		end
		if controlCmd["order2_temp"] ~= nil then
			myTable["order2Temp"] = string2Int(controlCmd["order2_temp"])
		end
	elseif (myTable["controlType"] == 5) then
		if controlCmd["backwater_effect"] ~= nil then
			if controlCmd["backwater_effect"] == VALUE_FUNCTION_ON then
				myTable["backwaterEffect"] = BYTE_POWER_ON
			elseif controlCmd["backwater_effect"] == VALUE_FUNCTION_OFF then
				myTable["backwaterEffect"] = BYTE_POWER_OFF
			end
		end
	elseif (myTable["controlType"] == 6) then
		if controlCmd["sterilize_effect"] ~= nil then
			if controlCmd["sterilize_effect"] == VALUE_FUNCTION_ON then
				myTable["sterilizeEffect"] = 128
			elseif controlCmd["sterilize_effect"] == VALUE_FUNCTION_OFF then
				myTable["sterilizeEffect"] = BYTE_POWER_OFF
			end
			if controlCmd["auto_sterilize_week"] ~= nil then
				myTable["autoSterilizeWeek"] = string2Int(controlCmd["auto_sterilize_week"])
			end
			if controlCmd["auto_sterilize_hour"] ~= nil then
				myTable["autoSterilizeHour"] = string2Int(controlCmd["auto_sterilize_hour"])
			end
			if controlCmd["auto_sterilize_minute"] ~= nil then
				myTable["autoSterilizeMinute"] = string2Int(controlCmd["auto_sterilize_minute"])
			end
		end
	elseif (myTable["controlType"] == 7) then
		if controlCmd["week0timer1_effect"] ~= nil then
			if controlCmd["week0timer1_effect"] == VALUE_FUNCTION_ON then
				myTable["week0timer1Effect"] = 1
			elseif controlCmd["week0timer1_effect"] == VALUE_FUNCTION_OFF then
				myTable["week0timer1Effect"] = 0
			end
		end
		if controlCmd["week0timer2_effect"] ~= nil then
			if controlCmd["week0timer2_effect"] == VALUE_FUNCTION_ON then
				myTable["week0timer2Effect"] = 2
			elseif controlCmd["week0timer2_effect"] == VALUE_FUNCTION_OFF then
				myTable["week0timer2Effect"] = 0
			end
		end
		if controlCmd["week0timer3_effect"] ~= nil then
			if controlCmd["week0timer3_effect"] == VALUE_FUNCTION_ON then
				myTable["week0timer3Effect"] = 4
			elseif controlCmd["week0timer3_effect"] == VALUE_FUNCTION_OFF then
				myTable["week0timer3Effect"] = 0
			end
		end
		if controlCmd["week0timer4_effect"] ~= nil then
			if controlCmd["week0timer4_effect"] == VALUE_FUNCTION_ON then
				myTable["week0timer4Effect"] = 8
			elseif controlCmd["week0timer4_effect"] == VALUE_FUNCTION_OFF then
				myTable["week0timer4Effect"] = 0
			end
		end
		if controlCmd["week0timer5_effect"] ~= nil then
			if controlCmd["week0timer5_effect"] == VALUE_FUNCTION_ON then
				myTable["week0timer5Effect"] = 16
			elseif controlCmd["week0timer5_effect"] == VALUE_FUNCTION_OFF then
				myTable["week0timer5Effect"] = 0
			end
		end
		if controlCmd["week0timer6_effect"] ~= nil then
			if controlCmd["week0timer6_effect"] == VALUE_FUNCTION_ON then
				myTable["week0timer6Effect"] = 32
			elseif controlCmd["week0timer6_effect"] == VALUE_FUNCTION_OFF then
				myTable["week0timer6Effect"] = 0
			end
		end
		if controlCmd["week1timer1_effect"] ~= nil then
			if controlCmd["week1timer1_effect"] == VALUE_FUNCTION_ON then
				myTable["week1timer1Effect"] = 1
			elseif controlCmd["week1timer1_effect"] == VALUE_FUNCTION_OFF then
				myTable["week1timer1Effect"] = 0
			end
		end
		if controlCmd["week1timer2_effect"] ~= nil then
			if controlCmd["week1timer2_effect"] == VALUE_FUNCTION_ON then
				myTable["week1timer2Effect"] = 2
			elseif controlCmd["week1timer2_effect"] == VALUE_FUNCTION_OFF then
				myTable["week1timer2Effect"] = 0
			end
		end
		if controlCmd["week1timer3_effect"] ~= nil then
			if controlCmd["week1timer3_effect"] == VALUE_FUNCTION_ON then
				myTable["week1timer3Effect"] = 4
			elseif controlCmd["week1timer3_effect"] == VALUE_FUNCTION_OFF then
				myTable["week1timer3Effect"] = 0
			end
		end
		if controlCmd["week1timer4_effect"] ~= nil then
			if controlCmd["week1timer4_effect"] == VALUE_FUNCTION_ON then
				myTable["week1timer4Effect"] = 8
			elseif controlCmd["week1timer4_effect"] == VALUE_FUNCTION_OFF then
				myTable["week1timer4Effect"] = 0
			end
		end
		if controlCmd["week1timer5_effect"] ~= nil then
			if controlCmd["week1timer5_effect"] == VALUE_FUNCTION_ON then
				myTable["week1timer5Effect"] = 16
			elseif controlCmd["week1timer5_effect"] == VALUE_FUNCTION_OFF then
				myTable["week1timer5Effect"] = 0
			end
		end
		if controlCmd["week1timer6_effect"] ~= nil then
			if controlCmd["week1timer6_effect"] == VALUE_FUNCTION_ON then
				myTable["week1timer6Effect"] = 32
			elseif controlCmd["week1timer6_effect"] == VALUE_FUNCTION_OFF then
				myTable["week1timer6Effect"] = 0
			end
		end
		if controlCmd["week2timer1_effect"] ~= nil then
			if controlCmd["week2timer1_effect"] == VALUE_FUNCTION_ON then
				myTable["week2timer1Effect"] = 1
			elseif controlCmd["week2timer1_effect"] == VALUE_FUNCTION_OFF then
				myTable["week2timer1Effect"] = 0
			end
		end
		if controlCmd["week2timer2_effect"] ~= nil then
			if controlCmd["week2timer2_effect"] == VALUE_FUNCTION_ON then
				myTable["week2timer2Effect"] = 2
			elseif controlCmd["week2timer2_effect"] == VALUE_FUNCTION_OFF then
				myTable["week2timer2Effect"] = 0
			end
		end
		if controlCmd["week2timer3_effect"] ~= nil then
			if controlCmd["week2timer3_effect"] == VALUE_FUNCTION_ON then
				myTable["week2timer3Effect"] = 4
			elseif controlCmd["week2timer3_effect"] == VALUE_FUNCTION_OFF then
				myTable["week2timer3Effect"] = 0
			end
		end
		if controlCmd["week2timer4_effect"] ~= nil then
			if controlCmd["week2timer4_effect"] == VALUE_FUNCTION_ON then
				myTable["week2timer4Effect"] = 8
			elseif controlCmd["week2timer4_effect"] == VALUE_FUNCTION_OFF then
				myTable["week2timer4Effect"] = 0
			end
		end
		if controlCmd["week2timer5_effect"] ~= nil then
			if controlCmd["week2timer5_effect"] == VALUE_FUNCTION_ON then
				myTable["week2timer5Effect"] = 16
			elseif controlCmd["week2timer5_effect"] == VALUE_FUNCTION_OFF then
				myTable["week2timer5Effect"] = 0
			end
		end
		if controlCmd["week2timer6_effect"] ~= nil then
			if controlCmd["week2timer6_effect"] == VALUE_FUNCTION_ON then
				myTable["week2timer6Effect"] = 32
			elseif controlCmd["week2timer6_effect"] == VALUE_FUNCTION_OFF then
				myTable["week2timer6Effect"] = 0
			end
		end
		if controlCmd["week3timer1_effect"] ~= nil then
			if controlCmd["week3timer1_effect"] == VALUE_FUNCTION_ON then
				myTable["week3timer1Effect"] = 1
			elseif controlCmd["week3timer1_effect"] == VALUE_FUNCTION_OFF then
				myTable["week3timer1Effect"] = 0
			end
		end
		if controlCmd["week3timer2_effect"] ~= nil then
			if controlCmd["week3timer2_effect"] == VALUE_FUNCTION_ON then
				myTable["week3timer2Effect"] = 2
			elseif controlCmd["week3timer2_effect"] == VALUE_FUNCTION_OFF then
				myTable["week3timer2Effect"] = 0
			end
		end
		if controlCmd["week3timer3_effect"] ~= nil then
			if controlCmd["week3timer3_effect"] == VALUE_FUNCTION_ON then
				myTable["week3timer3Effect"] = 4
			elseif controlCmd["week3timer3_effect"] == VALUE_FUNCTION_OFF then
				myTable["week3timer3Effect"] = 0
			end
		end
		if controlCmd["week3timer4_effect"] ~= nil then
			if controlCmd["week3timer4_effect"] == VALUE_FUNCTION_ON then
				myTable["week3timer4Effect"] = 8
			elseif controlCmd["week3timer4_effect"] == VALUE_FUNCTION_OFF then
				myTable["week3timer4Effect"] = 0
			end
		end
		if controlCmd["week3timer5_effect"] ~= nil then
			if controlCmd["week3timer5_effect"] == VALUE_FUNCTION_ON then
				myTable["week3timer5Effect"] = 16
			elseif controlCmd["week3timer5_effect"] == VALUE_FUNCTION_OFF then
				myTable["week3timer5Effect"] = 0
			end
		end
		if controlCmd["week3timer6_effect"] ~= nil then
			if controlCmd["week3timer6_effect"] == VALUE_FUNCTION_ON then
				myTable["week3timer6Effect"] = 32
			elseif controlCmd["week3timer6_effect"] == VALUE_FUNCTION_OFF then
				myTable["week3timer6Effect"] = 0
			end
		end
		if controlCmd["week4timer1_effect"] ~= nil then
			if controlCmd["week4timer1_effect"] == VALUE_FUNCTION_ON then
				myTable["week4timer1Effect"] = 1
			elseif controlCmd["week4timer1_effect"] == VALUE_FUNCTION_OFF then
				myTable["week4timer1Effect"] = 0
			end
		end
		if controlCmd["week4timer2_effect"] ~= nil then
			if controlCmd["week4timer2_effect"] == VALUE_FUNCTION_ON then
				myTable["week4timer2Effect"] = 2
			elseif controlCmd["week4timer2_effect"] == VALUE_FUNCTION_OFF then
				myTable["week4timer2Effect"] = 0
			end
		end
		if controlCmd["week4timer3_effect"] ~= nil then
			if controlCmd["week4timer3_effect"] == VALUE_FUNCTION_ON then
				myTable["week4timer3Effect"] = 4
			elseif controlCmd["week4timer3_effect"] == VALUE_FUNCTION_OFF then
				myTable["week4timer3Effect"] = 0
			end
		end
		if controlCmd["week4timer4_effect"] ~= nil then
			if controlCmd["week4timer4_effect"] == VALUE_FUNCTION_ON then
				myTable["week4timer4Effect"] = 8
			elseif controlCmd["week4timer4_effect"] == VALUE_FUNCTION_OFF then
				myTable["week4timer4Effect"] = 0
			end
		end
		if controlCmd["week4timer5_effect"] ~= nil then
			if controlCmd["week4timer5_effect"] == VALUE_FUNCTION_ON then
				myTable["week4timer5Effect"] = 16
			elseif controlCmd["week4timer5_effect"] == VALUE_FUNCTION_OFF then
				myTable["week4timer5Effect"] = 0
			end
		end
		if controlCmd["week4timer6_effect"] ~= nil then
			if controlCmd["week4timer6_effect"] == VALUE_FUNCTION_ON then
				myTable["week4timer6Effect"] = 32
			elseif controlCmd["week4timer6_effect"] == VALUE_FUNCTION_OFF then
				myTable["week4timer6Effect"] = 0
			end
		end
		if controlCmd["week5timer1_effect"] ~= nil then
			if controlCmd["week5timer1_effect"] == VALUE_FUNCTION_ON then
				myTable["week5timer1Effect"] = 1
			elseif controlCmd["week5timer1_effect"] == VALUE_FUNCTION_OFF then
				myTable["week5timer1Effect"] = 0
			end
		end
		if controlCmd["week5timer2_effect"] ~= nil then
			if controlCmd["week5timer2_effect"] == VALUE_FUNCTION_ON then
				myTable["week5timer2Effect"] = 2
			elseif controlCmd["week5timer2_effect"] == VALUE_FUNCTION_OFF then
				myTable["week5timer2Effect"] = 0
			end
		end
		if controlCmd["week5timer3_effect"] ~= nil then
			if controlCmd["week5timer3_effect"] == VALUE_FUNCTION_ON then
				myTable["week5timer3Effect"] = 4
			elseif controlCmd["week5timer3_effect"] == VALUE_FUNCTION_OFF then
				myTable["week5timer3Effect"] = 0
			end
		end
		if controlCmd["week5timer4_effect"] ~= nil then
			if controlCmd["week5timer4_effect"] == VALUE_FUNCTION_ON then
				myTable["week5timer4Effect"] = 8
			elseif controlCmd["week5timer4_effect"] == VALUE_FUNCTION_OFF then
				myTable["week5timer4Effect"] = 0
			end
		end
		if controlCmd["week5timer5_effect"] ~= nil then
			if controlCmd["week5timer5_effect"] == VALUE_FUNCTION_ON then
				myTable["week5timer5Effect"] = 16
			elseif controlCmd["week5timer5_effect"] == VALUE_FUNCTION_OFF then
				myTable["week5timer5Effect"] = 0
			end
		end
		if controlCmd["week5timer6_effect"] ~= nil then
			if controlCmd["week5timer6_effect"] == VALUE_FUNCTION_ON then
				myTable["week5timer6Effect"] = 32
			elseif controlCmd["week5timer6_effect"] == VALUE_FUNCTION_OFF then
				myTable["week5timer6Effect"] = 0
			end
		end
		if controlCmd["week6timer1_effect"] ~= nil then
			if controlCmd["week6timer1_effect"] == VALUE_FUNCTION_ON then
				myTable["week6timer1Effect"] = 1
			elseif controlCmd["week6timer1_effect"] == VALUE_FUNCTION_OFF then
				myTable["week6timer1Effect"] = 0
			end
		end
		if controlCmd["week6timer2_effect"] ~= nil then
			if controlCmd["week6timer2_effect"] == VALUE_FUNCTION_ON then
				myTable["week6timer2Effect"] = 2
			elseif controlCmd["week6timer2_effect"] == VALUE_FUNCTION_OFF then
				myTable["week6timer2Effect"] = 0
			end
		end
		if controlCmd["week6timer3_effect"] ~= nil then
			if controlCmd["week6timer3_effect"] == VALUE_FUNCTION_ON then
				myTable["week6timer3Effect"] = 4
			elseif controlCmd["week6timer3_effect"] == VALUE_FUNCTION_OFF then
				myTable["week6timer3Effect"] = 0
			end
		end
		if controlCmd["week6timer4_effect"] ~= nil then
			if controlCmd["week6timer4_effect"] == VALUE_FUNCTION_ON then
				myTable["week6timer4Effect"] = 8
			elseif controlCmd["week6timer4_effect"] == VALUE_FUNCTION_OFF then
				myTable["week6timer4Effect"] = 0
			end
		end
		if controlCmd["week6timer5_effect"] ~= nil then
			if controlCmd["week6timer5_effect"] == VALUE_FUNCTION_ON then
				myTable["week6timer5Effect"] = 16
			elseif controlCmd["week6timer5_effect"] == VALUE_FUNCTION_OFF then
				myTable["week6timer5Effect"] = 0
			end
		end
		if controlCmd["week6timer6_effect"] ~= nil then
			if controlCmd["week6timer6_effect"] == VALUE_FUNCTION_ON then
				myTable["week6timer6Effect"] = 32
			elseif controlCmd["week6timer6_effect"] == VALUE_FUNCTION_OFF then
				myTable["week6timer6Effect"] = 0
			end
		end
		if controlCmd["week0timer1_opentime"] ~= nil then
			myTable["week0timer1OpenTime"] = string2Int(controlCmd["week0timer1_opentime"])
		end
		if controlCmd["week0timer1_closetime"] ~= nil then
			myTable["week0timer1CloseTime"] = string2Int(controlCmd["week0timer1_closetime"])
		end
		if controlCmd["week0timer1_set_temperature"] ~= nil then
			myTable["week0timer1SetTemperature"] = string2Int(controlCmd["week0timer1_set_temperature"])
		end
		if controlCmd["week0timer2_opentime"] ~= nil then
			myTable["week0timer2OpenTime"] = string2Int(controlCmd["week0timer2_opentime"])
		end
		if controlCmd["week0timer2_closetime"] ~= nil then
			myTable["week0timer2CloseTime"] = string2Int(controlCmd["week0timer2_closetime"])
		end
		if controlCmd["week0timer2_set_temperature"] ~= nil then
			myTable["week0timer2SetTemperature"] = string2Int(controlCmd["week0timer2_set_temperature"])
		end
		if controlCmd["week0timer3_opentime"] ~= nil then
			myTable["week0timer3OpenTime"] = string2Int(controlCmd["week0timer3_opentime"])
		end
		if controlCmd["week0timer3_closetime"] ~= nil then
			myTable["week0timer3CloseTime"] = string2Int(controlCmd["week0timer3_closetime"])
		end
		if controlCmd["week0timer3_set_temperature"] ~= nil then
			myTable["week0timer3SetTemperature"] = string2Int(controlCmd["week0timer3_set_temperature"])
		end
		if controlCmd["week0timer4_opentime"] ~= nil then
			myTable["week0timer4OpenTime"] = string2Int(controlCmd["week0timer4_opentime"])
		end
		if controlCmd["week0timer4_closetime"] ~= nil then
			myTable["week0timer4CloseTime"] = string2Int(controlCmd["week0timer4_closetime"])
		end
		if controlCmd["week0timer4_set_temperature"] ~= nil then
			myTable["week0timer4SetTemperature"] = string2Int(controlCmd["week0timer4_set_temperature"])
		end
		if controlCmd["week0timer5_opentime"] ~= nil then
			myTable["week0timer5OpenTime"] = string2Int(controlCmd["week0timer5_opentime"])
		end
		if controlCmd["week0timer5_closetime"] ~= nil then
			myTable["week0timer5CloseTime"] = string2Int(controlCmd["week0timer5_closetime"])
		end
		if controlCmd["week0timer5_set_temperature"] ~= nil then
			myTable["week0timer5SetTemperature"] = string2Int(controlCmd["week0timer5_set_temperature"])
		end
		if controlCmd["week0timer6_opentime"] ~= nil then
			myTable["week0timer6OpenTime"] = string2Int(controlCmd["week0timer6_opentime"])
		end
		if controlCmd["week0timer6_closetime"] ~= nil then
			myTable["week0timer6CloseTime"] = string2Int(controlCmd["week0timer6_closetime"])
		end
		if controlCmd["week0timer6_set_temperature"] ~= nil then
			myTable["week0timer6SetTemperature"] = string2Int(controlCmd["week0timer6_set_temperature"])
		end
		if controlCmd["week1timer1_opentime"] ~= nil then
			myTable["week1timer1OpenTime"] = string2Int(controlCmd["week1timer1_opentime"])
		end
		if controlCmd["week1timer1_closetime"] ~= nil then
			myTable["week1timer1CloseTime"] = string2Int(controlCmd["week1timer1_closetime"])
		end
		if controlCmd["week1timer1_set_temperature"] ~= nil then
			myTable["week1timer1SetTemperature"] = string2Int(controlCmd["week1timer1_set_temperature"])
		end
		if controlCmd["week1timer2_opentime"] ~= nil then
			myTable["week1timer2OpenTime"] = string2Int(controlCmd["week1timer2_opentime"])
		end
		if controlCmd["week1timer2_closetime"] ~= nil then
			myTable["week1timer2CloseTime"] = string2Int(controlCmd["week1timer2_closetime"])
		end
		if controlCmd["week1timer2_set_temperature"] ~= nil then
			myTable["week1timer2SetTemperature"] = string2Int(controlCmd["week1timer2_set_temperature"])
		end
		if controlCmd["week1timer3_opentime"] ~= nil then
			myTable["week1timer3OpenTime"] = string2Int(controlCmd["week1timer3_opentime"])
		end
		if controlCmd["week1timer3_closetime"] ~= nil then
			myTable["week1timer3CloseTime"] = string2Int(controlCmd["week1timer3_closetime"])
		end
		if controlCmd["week1timer3_set_temperature"] ~= nil then
			myTable["week1timer3SetTemperature"] = string2Int(controlCmd["week1timer3_set_temperature"])
		end
		if controlCmd["week1timer4_opentime"] ~= nil then
			myTable["week1timer4OpenTime"] = string2Int(controlCmd["week1timer4_opentime"])
		end
		if controlCmd["week1timer4_closetime"] ~= nil then
			myTable["week1timer4CloseTime"] = string2Int(controlCmd["week1timer4_closetime"])
		end
		if controlCmd["week1timer4_set_temperature"] ~= nil then
			myTable["week1timer4SetTemperature"] = string2Int(controlCmd["week1timer4_set_temperature"])
		end
		if controlCmd["week1timer5_opentime"] ~= nil then
			myTable["week1timer5OpenTime"] = string2Int(controlCmd["week1timer5_opentime"])
		end
		if controlCmd["week1timer5_closetime"] ~= nil then
			myTable["week1timer5CloseTime"] = string2Int(controlCmd["week1timer5_closetime"])
		end
		if controlCmd["week1timer5_set_temperature"] ~= nil then
			myTable["week1timer5SetTemperature"] = string2Int(controlCmd["week1timer5_set_temperature"])
		end
		if controlCmd["week1timer6_opentime"] ~= nil then
			myTable["week1timer6OpenTime"] = string2Int(controlCmd["week1timer6_opentime"])
		end
		if controlCmd["week1timer6_closetime"] ~= nil then
			myTable["week1timer6CloseTime"] = string2Int(controlCmd["week1timer6_closetime"])
		end
		if controlCmd["week1timer6_set_temperature"] ~= nil then
			myTable["week1timer6SetTemperature"] = string2Int(controlCmd["week1timer6_set_temperature"])
		end
		if controlCmd["week2timer1_opentime"] ~= nil then
			myTable["week2timer1OpenTime"] = string2Int(controlCmd["week2timer1_opentime"])
		end
		if controlCmd["week2timer1_closetime"] ~= nil then
			myTable["week2timer1CloseTime"] = string2Int(controlCmd["week2timer1_closetime"])
		end
		if controlCmd["week2timer1_set_temperature"] ~= nil then
			myTable["week2timer1SetTemperature"] = string2Int(controlCmd["week2timer1_set_temperature"])
		end
		if controlCmd["week2timer2_opentime"] ~= nil then
			myTable["week2timer2OpenTime"] = string2Int(controlCmd["week2timer2_opentime"])
		end
		if controlCmd["week2timer2_closetime"] ~= nil then
			myTable["week2timer2CloseTime"] = string2Int(controlCmd["week2timer2_closetime"])
		end
		if controlCmd["week2timer2_set_temperature"] ~= nil then
			myTable["week2timer2SetTemperature"] = string2Int(controlCmd["week2timer2_set_temperature"])
		end
		if controlCmd["week2timer3_opentime"] ~= nil then
			myTable["week2timer3OpenTime"] = string2Int(controlCmd["week2timer3_opentime"])
		end
		if controlCmd["week2timer3_closetime"] ~= nil then
			myTable["week2timer3CloseTime"] = string2Int(controlCmd["week2timer3_closetime"])
		end
		if controlCmd["week2timer3_set_temperature"] ~= nil then
			myTable["week2timer3SetTemperature"] = string2Int(controlCmd["week2timer3_set_temperature"])
		end
		if controlCmd["week2timer4_opentime"] ~= nil then
			myTable["week2timer4OpenTime"] = string2Int(controlCmd["week2timer4_opentime"])
		end
		if controlCmd["week2timer4_closetime"] ~= nil then
			myTable["week2timer4CloseTime"] = string2Int(controlCmd["week2timer4_closetime"])
		end
		if controlCmd["week2timer4_set_temperature"] ~= nil then
			myTable["week2timer4SetTemperature"] = string2Int(controlCmd["week2timer4_set_temperature"])
		end
		if controlCmd["week2timer5_opentime"] ~= nil then
			myTable["week2timer5OpenTime"] = string2Int(controlCmd["week2timer5_opentime"])
		end
		if controlCmd["week2timer5_closetime"] ~= nil then
			myTable["week2timer5CloseTime"] = string2Int(controlCmd["week2timer5_closetime"])
		end
		if controlCmd["week2timer5_set_temperature"] ~= nil then
			myTable["week2timer5SetTemperature"] = string2Int(controlCmd["week2timer5_set_temperature"])
		end
		if controlCmd["week2timer6_opentime"] ~= nil then
			myTable["week2timer6OpenTime"] = string2Int(controlCmd["week2timer6_opentime"])
		end
		if controlCmd["week2timer6_closetime"] ~= nil then
			myTable["week2timer6CloseTime"] = string2Int(controlCmd["week2timer6_closetime"])
		end
		if controlCmd["week2timer6_set_temperature"] ~= nil then
			myTable["week2timer6SetTemperature"] = string2Int(controlCmd["week2timer6_set_temperature"])
		end
		if controlCmd["week3timer1_opentime"] ~= nil then
			myTable["week3timer1OpenTime"] = string2Int(controlCmd["week3timer1_opentime"])
		end
		if controlCmd["week3timer1_closetime"] ~= nil then
			myTable["week3timer1CloseTime"] = string2Int(controlCmd["week3timer1_closetime"])
		end
		if controlCmd["week3timer1_set_temperature"] ~= nil then
			myTable["week3timer1SetTemperature"] = string2Int(controlCmd["week3timer1_set_temperature"])
		end
		if controlCmd["week3timer2_opentime"] ~= nil then
			myTable["week3timer2OpenTime"] = string2Int(controlCmd["week3timer2_opentime"])
		end
		if controlCmd["week3timer2_closetime"] ~= nil then
			myTable["week3timer2CloseTime"] = string2Int(controlCmd["week3timer2_closetime"])
		end
		if controlCmd["week3timer2_set_temperature"] ~= nil then
			myTable["week3timer2SetTemperature"] = string2Int(controlCmd["week3timer2_set_temperature"])
		end
		if controlCmd["week3timer3_opentime"] ~= nil then
			myTable["week3timer3OpenTime"] = string2Int(controlCmd["week3timer3_opentime"])
		end
		if controlCmd["week3timer3_closetime"] ~= nil then
			myTable["week3timer3CloseTime"] = string2Int(controlCmd["week3timer3_closetime"])
		end
		if controlCmd["week3timer3_set_temperature"] ~= nil then
			myTable["week3timer3SetTemperature"] = string2Int(controlCmd["week3timer3_set_temperature"])
		end
		if controlCmd["week3timer4_opentime"] ~= nil then
			myTable["week3timer4OpenTime"] = string2Int(controlCmd["week3timer4_opentime"])
		end
		if controlCmd["week3timer4_closetime"] ~= nil then
			myTable["week3timer4CloseTime"] = string2Int(controlCmd["week3timer4_closetime"])
		end
		if controlCmd["week3timer4_set_temperature"] ~= nil then
			myTable["week3timer4SetTemperature"] = string2Int(controlCmd["week3timer4_set_temperature"])
		end
		if controlCmd["week3timer5_opentime"] ~= nil then
			myTable["week3timer5OpenTime"] = string2Int(controlCmd["week3timer5_opentime"])
		end
		if controlCmd["week3timer5_closetime"] ~= nil then
			myTable["week3timer5CloseTime"] = string2Int(controlCmd["week3timer5_closetime"])
		end
		if controlCmd["week3timer5_set_temperature"] ~= nil then
			myTable["week3timer5SetTemperature"] = string2Int(controlCmd["week3timer5_set_temperature"])
		end
		if controlCmd["week3timer6_opentime"] ~= nil then
			myTable["week3timer6OpenTime"] = string2Int(controlCmd["week3timer6_opentime"])
		end
		if controlCmd["week3timer6_closetime"] ~= nil then
			myTable["week3timer6CloseTime"] = string2Int(controlCmd["week3timer6_closetime"])
		end
		if controlCmd["week3timer6_set_temperature"] ~= nil then
			myTable["week3timer6SetTemperature"] = string2Int(controlCmd["week3timer6_set_temperature"])
		end
		if controlCmd["week4timer1_opentime"] ~= nil then
			myTable["week4timer1OpenTime"] = string2Int(controlCmd["week4timer1_opentime"])
		end
		if controlCmd["week4timer1_closetime"] ~= nil then
			myTable["week4timer1CloseTime"] = string2Int(controlCmd["week4timer1_closetime"])
		end
		if controlCmd["week4timer1_set_temperature"] ~= nil then
			myTable["week4timer1SetTemperature"] = string2Int(controlCmd["week4timer1_set_temperature"])
		end
		if controlCmd["week4timer2_opentime"] ~= nil then
			myTable["week4timer2OpenTime"] = string2Int(controlCmd["week4timer2_opentime"])
		end
		if controlCmd["week4timer2_closetime"] ~= nil then
			myTable["week4timer2CloseTime"] = string2Int(controlCmd["week4timer2_closetime"])
		end
		if controlCmd["week4timer2_set_temperature"] ~= nil then
			myTable["week4timer2SetTemperature"] = string2Int(controlCmd["week4timer2_set_temperature"])
		end
		if controlCmd["week4timer3_opentime"] ~= nil then
			myTable["week4timer3OpenTime"] = string2Int(controlCmd["week4timer3_opentime"])
		end
		if controlCmd["week4timer3_closetime"] ~= nil then
			myTable["week4timer3CloseTime"] = string2Int(controlCmd["week4timer3_closetime"])
		end
		if controlCmd["week4timer3_set_temperature"] ~= nil then
			myTable["week4timer3SetTemperature"] = string2Int(controlCmd["week4timer3_set_temperature"])
		end
		if controlCmd["week4timer4_opentime"] ~= nil then
			myTable["week4timer4OpenTime"] = string2Int(controlCmd["week4timer4_opentime"])
		end
		if controlCmd["week4timer4_closetime"] ~= nil then
			myTable["week4timer4CloseTime"] = string2Int(controlCmd["week4timer4_closetime"])
		end
		if controlCmd["week4timer4_set_temperature"] ~= nil then
			myTable["week4timer4SetTemperature"] = string2Int(controlCmd["week4timer4_set_temperature"])
		end
		if controlCmd["week4timer5_opentime"] ~= nil then
			myTable["week4timer5OpenTime"] = string2Int(controlCmd["week4timer5_opentime"])
		end
		if controlCmd["week4timer5_closetime"] ~= nil then
			myTable["week4timer5CloseTime"] = string2Int(controlCmd["week4timer5_closetime"])
		end
		if controlCmd["week4timer5_set_temperature"] ~= nil then
			myTable["week4timer5SetTemperature"] = string2Int(controlCmd["week4timer5_set_temperature"])
		end
		if controlCmd["week4timer6_opentime"] ~= nil then
			myTable["week4timer6OpenTime"] = string2Int(controlCmd["week4timer6_opentime"])
		end
		if controlCmd["week4timer6_closetime"] ~= nil then
			myTable["week4timer6CloseTime"] = string2Int(controlCmd["week4timer6_closetime"])
		end
		if controlCmd["week4timer6_set_temperature"] ~= nil then
			myTable["week4timer6SetTemperature"] = string2Int(controlCmd["week4timer6_set_temperature"])
		end
		if controlCmd["week5timer1_opentime"] ~= nil then
			myTable["week5timer1OpenTime"] = string2Int(controlCmd["week5timer1_opentime"])
		end
		if controlCmd["week5timer1_closetime"] ~= nil then
			myTable["week5timer1CloseTime"] = string2Int(controlCmd["week5timer1_closetime"])
		end
		if controlCmd["week5timer1_set_temperature"] ~= nil then
			myTable["week5timer1SetTemperature"] = string2Int(controlCmd["week5timer1_set_temperature"])
		end
		if controlCmd["week5timer2_opentime"] ~= nil then
			myTable["week5timer2OpenTime"] = string2Int(controlCmd["week5timer2_opentime"])
		end
		if controlCmd["week5timer2_closetime"] ~= nil then
			myTable["week5timer2CloseTime"] = string2Int(controlCmd["week5timer2_closetime"])
		end
		if controlCmd["week5timer2_set_temperature"] ~= nil then
			myTable["week5timer2SetTemperature"] = string2Int(controlCmd["week5timer2_set_temperature"])
		end
		if controlCmd["week5timer3_opentime"] ~= nil then
			myTable["week5timer3OpenTime"] = string2Int(controlCmd["week5timer3_opentime"])
		end
		if controlCmd["week5timer3_closetime"] ~= nil then
			myTable["week5timer3CloseTime"] = string2Int(controlCmd["week5timer3_closetime"])
		end
		if controlCmd["week5timer3_set_temperature"] ~= nil then
			myTable["week5timer3SetTemperature"] = string2Int(controlCmd["week5timer3_set_temperature"])
		end
		if controlCmd["week5timer4_opentime"] ~= nil then
			myTable["week5timer4OpenTime"] = string2Int(controlCmd["week5timer4_opentime"])
		end
		if controlCmd["week5timer4_closetime"] ~= nil then
			myTable["week5timer4CloseTime"] = string2Int(controlCmd["week5timer4_closetime"])
		end
		if controlCmd["week5timer4_set_temperature"] ~= nil then
			myTable["week5timer4SetTemperature"] = string2Int(controlCmd["week5timer4_set_temperature"])
		end
		if controlCmd["week5timer5_opentime"] ~= nil then
			myTable["week5timer5OpenTime"] = string2Int(controlCmd["week5timer5_opentime"])
		end
		if controlCmd["week5timer5_closetime"] ~= nil then
			myTable["week5timer5CloseTime"] = string2Int(controlCmd["week5timer5_closetime"])
		end
		if controlCmd["week5timer5_set_temperature"] ~= nil then
			myTable["week5timer5SetTemperature"] = string2Int(controlCmd["week5timer5_set_temperature"])
		end
		if controlCmd["week5timer6_opentime"] ~= nil then
			myTable["week5timer6OpenTime"] = string2Int(controlCmd["week5timer6_opentime"])
		end
		if controlCmd["week5timer6_closetime"] ~= nil then
			myTable["week5timer6CloseTime"] = string2Int(controlCmd["week5timer6_closetime"])
		end
		if controlCmd["week5timer6_set_temperature"] ~= nil then
			myTable["week5timer6SetTemperature"] = string2Int(controlCmd["week5timer6_set_temperature"])
		end
		if controlCmd["week6timer1_opentime"] ~= nil then
			myTable["week6timer1OpenTime"] = string2Int(controlCmd["week6timer1_opentime"])
		end
		if controlCmd["week6timer1_closetime"] ~= nil then
			myTable["week6timer1CloseTime"] = string2Int(controlCmd["week6timer1_closetime"])
		end
		if controlCmd["week6timer1_set_temperature"] ~= nil then
			myTable["week6timer1SetTemperature"] = string2Int(controlCmd["week6timer1_set_temperature"])
		end
		if controlCmd["week6timer2_opentime"] ~= nil then
			myTable["week6timer2OpenTime"] = string2Int(controlCmd["week6timer2_opentime"])
		end
		if controlCmd["week6timer2_closetime"] ~= nil then
			myTable["week6timer2CloseTime"] = string2Int(controlCmd["week6timer2_closetime"])
		end
		if controlCmd["week6timer2_set_temperature"] ~= nil then
			myTable["week6timer2SetTemperature"] = string2Int(controlCmd["week6timer2_set_temperature"])
		end
		if controlCmd["week6timer3_opentime"] ~= nil then
			myTable["week6timer3OpenTime"] = string2Int(controlCmd["week6timer3_opentime"])
		end
		if controlCmd["week6timer3_closetime"] ~= nil then
			myTable["week6timer3CloseTime"] = string2Int(controlCmd["week6timer3_closetime"])
		end
		if controlCmd["week6timer3_set_temperature"] ~= nil then
			myTable["week6timer3SetTemperature"] = string2Int(controlCmd["week6timer3_set_temperature"])
		end
		if controlCmd["week6timer4_opentime"] ~= nil then
			myTable["week6timer4OpenTime"] = string2Int(controlCmd["week6timer4_opentime"])
		end
		if controlCmd["week6timer4_closetime"] ~= nil then
			myTable["week6timer4CloseTime"] = string2Int(controlCmd["week6timer4_closetime"])
		end
		if controlCmd["week6timer4_set_temperature"] ~= nil then
			myTable["week6timer4SetTemperature"] = string2Int(controlCmd["week6timer4_set_temperature"])
		end
		if controlCmd["week6timer5_opentime"] ~= nil then
			myTable["week6timer5OpenTime"] = string2Int(controlCmd["week6timer5_opentime"])
		end
		if controlCmd["week6timer5_closetime"] ~= nil then
			myTable["week6timer5CloseTime"] = string2Int(controlCmd["week6timer5_closetime"])
		end
		if controlCmd["week6timer5_set_temperature"] ~= nil then
			myTable["week6timer5SetTemperature"] = string2Int(controlCmd["week6timer5_set_temperature"])
		end
		if controlCmd["week6timer6_opentime"] ~= nil then
			myTable["week6timer6OpenTime"] = string2Int(controlCmd["week6timer6_opentime"])
		end
		if controlCmd["week6timer6_closetime"] ~= nil then
			myTable["week6timer6CloseTime"] = string2Int(controlCmd["week6timer6_closetime"])
		end
		if controlCmd["week6timer6_set_temperature"] ~= nil then
			myTable["week6timer6SetTemperature"] = string2Int(controlCmd["week6timer6_set_temperature"])
		end
		if controlCmd["week0timer1_modevalue"] ~= nil then
			if controlCmd["week0timer1_modevalue"] == "energy" then
				myTable["week0timer1ModeValue"] = 1
			elseif controlCmd["week0timer1_modevalue"] == "standard" then
				myTable["week0timer1ModeValue"] = 2
			elseif controlCmd["week0timer1_modevalue"] == "compatibilizing" then
				myTable["week0timer1ModeValue"] = 3
			elseif controlCmd["week0timer1_modevalue"] == "smart" then
				myTable["week0timer1ModeValue"] = 4
			end
		end
		if controlCmd["week0timer2_modevalue"] ~= nil then
			if controlCmd["week0timer2_modevalue"] == "energy" then
				myTable["week0timer2ModeValue"] = 1
			elseif controlCmd["week0timer2_modevalue"] == "standard" then
				myTable["week0timer2ModeValue"] = 2
			elseif controlCmd["week0timer2_modevalue"] == "compatibilizing" then
				myTable["week0timer2ModeValue"] = 3
			elseif controlCmd["week0timer2_modevalue"] == "smart" then
				myTable["week0timer2ModeValue"] = 4
			end
		end
		if controlCmd["week0timer3_modevalue"] ~= nil then
			if controlCmd["week0timer3_modevalue"] == "energy" then
				myTable["week0timer3ModeValue"] = 1
			elseif controlCmd["week0timer3_modevalue"] == "standard" then
				myTable["week0timer3ModeValue"] = 2
			elseif controlCmd["week0timer3_modevalue"] == "compatibilizing" then
				myTable["week0timer3ModeValue"] = 3
			elseif controlCmd["week0timer3_modevalue"] == "smart" then
				myTable["week0timer3ModeValue"] = 4
			end
		end
		if controlCmd["week0timer4_modevalue"] ~= nil then
			if controlCmd["week0timer4_modevalue"] == "energy" then
				myTable["week0timer4ModeValue"] = 1
			elseif controlCmd["week0timer4_modevalue"] == "standard" then
				myTable["week0timer4ModeValue"] = 2
			elseif controlCmd["week0timer4_modevalue"] == "compatibilizing" then
				myTable["week0timer4ModeValue"] = 3
			elseif controlCmd["week0timer4_modevalue"] == "smart" then
				myTable["week0timer4ModeValue"] = 4
			end
		end
		if controlCmd["week0timer5_modevalue"] ~= nil then
			if controlCmd["week0timer5_modevalue"] == "energy" then
				myTable["week0timer5ModeValue"] = 1
			elseif controlCmd["week0timer5_modevalue"] == "standard" then
				myTable["week0timer5ModeValue"] = 2
			elseif controlCmd["week0timer5_modevalue"] == "compatibilizing" then
				myTable["week0timer5ModeValue"] = 3
			elseif controlCmd["week0timer5_modevalue"] == "smart" then
				myTable["week0timer6ModeValue"] = 4
			end
		end
		if controlCmd["week0timer6_modevalue"] ~= nil then
			if controlCmd["week0timer6_modevalue"] == "energy" then
				myTable["week0timer6ModeValue"] = 1
			elseif controlCmd["week0timer6_modevalue"] == "standard" then
				myTable["week0timer6ModeValue"] = 2
			elseif controlCmd["week0timer6_modevalue"] == "compatibilizing" then
				myTable["week0timer6ModeValue"] = 3
			elseif controlCmd["week0timer6_modevalue"] == "smart" then
				myTable["week0timer6ModeValue"] = 4
			end
		end
		if controlCmd["week1timer1_modevalue"] ~= nil then
			if controlCmd["week1timer1_modevalue"] == "energy" then
				myTable["week1timer1ModeValue"] = 1
			elseif controlCmd["week1timer1_modevalue"] == "standard" then
				myTable["week1timer1ModeValue"] = 2
			elseif controlCmd["week1timer1_modevalue"] == "compatibilizing" then
				myTable["week1timer1ModeValue"] = 3
			elseif controlCmd["week1timer1_modevalue"] == "smart" then
				myTable["week1timer1ModeValue"] = 4
			end
		end
		if controlCmd["week1timer2_modevalue"] ~= nil then
			if controlCmd["week1timer2_modevalue"] == "energy" then
				myTable["week1timer2ModeValue"] = 1
			elseif controlCmd["week1timer2_modevalue"] == "standard" then
				myTable["week1timer2ModeValue"] = 2
			elseif controlCmd["week1timer2_modevalue"] == "compatibilizing" then
				myTable["week1timer2ModeValue"] = 3
			elseif controlCmd["week1timer2_modevalue"] == "smart" then
				myTable["week1timer2ModeValue"] = 4
			end
		end
		if controlCmd["week1timer3_modevalue"] ~= nil then
			if controlCmd["week1timer3_modevalue"] == "energy" then
				myTable["week1timer3ModeValue"] = 1
			elseif controlCmd["week1timer3_modevalue"] == "standard" then
				myTable["week1timer3ModeValue"] = 2
			elseif controlCmd["week1timer3_modevalue"] == "compatibilizing" then
				myTable["week1timer3ModeValue"] = 3
			elseif controlCmd["week1timer3_modevalue"] == "smart" then
				myTable["week1timer3ModeValue"] = 4
			end
		end
		if controlCmd["week1timer4_modevalue"] ~= nil then
			if controlCmd["week1timer4_modevalue"] == "energy" then
				myTable["week1timer4ModeValue"] = 1
			elseif controlCmd["week1timer4_modevalue"] == "standard" then
				myTable["week1timer4ModeValue"] = 2
			elseif controlCmd["week1timer4_modevalue"] == "compatibilizing" then
				myTable["week1timer4ModeValue"] = 3
			elseif controlCmd["week1timer4_modevalue"] == "smart" then
				myTable["week1timer4ModeValue"] = 4
			end
		end
		if controlCmd["week1timer5_modevalue"] ~= nil then
			if controlCmd["week1timer5_modevalue"] == "energy" then
				myTable["week1timer5ModeValue"] = 1
			elseif controlCmd["week1timer5_modevalue"] == "standard" then
				myTable["week1timer5ModeValue"] = 2
			elseif controlCmd["week1timer5_modevalue"] == "compatibilizing" then
				myTable["week1timer5ModeValue"] = 3
			elseif controlCmd["week1timer5_modevalue"] == "smart" then
				myTable["week1timer6ModeValue"] = 4
			end
		end
		if controlCmd["week1timer6_modevalue"] ~= nil then
			if controlCmd["week1timer6_modevalue"] == "energy" then
				myTable["week1timer6ModeValue"] = 1
			elseif controlCmd["week1timer6_modevalue"] == "standard" then
				myTable["week1timer6ModeValue"] = 2
			elseif controlCmd["week1timer6_modevalue"] == "compatibilizing" then
				myTable["week1timer6ModeValue"] = 3
			elseif controlCmd["week1timer6_modevalue"] == "smart" then
				myTable["week1timer6ModeValue"] = 4
			end
		end
		if controlCmd["week2timer1_modevalue"] ~= nil then
			if controlCmd["week2timer1_modevalue"] == "energy" then
				myTable["week2timer1ModeValue"] = 1
			elseif controlCmd["week2timer1_modevalue"] == "standard" then
				myTable["week2timer1ModeValue"] = 2
			elseif controlCmd["week2timer1_modevalue"] == "compatibilizing" then
				myTable["week2timer1ModeValue"] = 3
			elseif controlCmd["week2timer1_modevalue"] == "smart" then
				myTable["week2timer1ModeValue"] = 4
			end
		end
		if controlCmd["week2timer2_modevalue"] ~= nil then
			if controlCmd["week2timer2_modevalue"] == "energy" then
				myTable["week2timer2ModeValue"] = 1
			elseif controlCmd["week2timer2_modevalue"] == "standard" then
				myTable["week2timer2ModeValue"] = 2
			elseif controlCmd["week2timer2_modevalue"] == "compatibilizing" then
				myTable["week2timer2ModeValue"] = 3
			elseif controlCmd["week2timer2_modevalue"] == "smart" then
				myTable["week2timer2ModeValue"] = 4
			end
		end
		if controlCmd["week2timer3_modevalue"] ~= nil then
			if controlCmd["week2timer3_modevalue"] == "energy" then
				myTable["week2timer3ModeValue"] = 1
			elseif controlCmd["week2timer3_modevalue"] == "standard" then
				myTable["week2timer3ModeValue"] = 2
			elseif controlCmd["week2timer3_modevalue"] == "compatibilizing" then
				myTable["week2timer3ModeValue"] = 3
			elseif controlCmd["week2timer3_modevalue"] == "smart" then
				myTable["week2timer3ModeValue"] = 4
			end
		end
		if controlCmd["week2timer4_modevalue"] ~= nil then
			if controlCmd["week2timer4_modevalue"] == "energy" then
				myTable["week2timer4ModeValue"] = 1
			elseif controlCmd["week2timer4_modevalue"] == "standard" then
				myTable["week2timer4ModeValue"] = 2
			elseif controlCmd["week2timer4_modevalue"] == "compatibilizing" then
				myTable["week2timer4ModeValue"] = 3
			elseif controlCmd["week2timer4_modevalue"] == "smart" then
				myTable["week2timer4ModeValue"] = 4
			end
		end
		if controlCmd["week2timer5_modevalue"] ~= nil then
			if controlCmd["week2timer5_modevalue"] == "energy" then
				myTable["week2timer5ModeValue"] = 1
			elseif controlCmd["week2timer5_modevalue"] == "standard" then
				myTable["week2timer5ModeValue"] = 2
			elseif controlCmd["week2timer5_modevalue"] == "compatibilizing" then
				myTable["week2timer5ModeValue"] = 3
			elseif controlCmd["week2timer5_modevalue"] == "smart" then
				myTable["week2timer6ModeValue"] = 4
			end
		end
		if controlCmd["week2timer6_modevalue"] ~= nil then
			if controlCmd["week2timer6_modevalue"] == "energy" then
				myTable["week2timer6ModeValue"] = 1
			elseif controlCmd["week2timer6_modevalue"] == "standard" then
				myTable["week2timer6ModeValue"] = 2
			elseif controlCmd["week2timer6_modevalue"] == "compatibilizing" then
				myTable["week2timer6ModeValue"] = 3
			elseif controlCmd["week2timer6_modevalue"] == "smart" then
				myTable["week2timer6ModeValue"] = 4
			end
		end
		if controlCmd["week3timer1_modevalue"] ~= nil then
			if controlCmd["week3timer1_modevalue"] == "energy" then
				myTable["week3timer1ModeValue"] = 1
			elseif controlCmd["week3timer1_modevalue"] == "standard" then
				myTable["week3timer1ModeValue"] = 2
			elseif controlCmd["week3timer1_modevalue"] == "compatibilizing" then
				myTable["week3timer1ModeValue"] = 3
			elseif controlCmd["week3timer1_modevalue"] == "smart" then
				myTable["week3timer1ModeValue"] = 4
			end
		end
		if controlCmd["week3timer2_modevalue"] ~= nil then
			if controlCmd["week3timer2_modevalue"] == "energy" then
				myTable["week3timer2ModeValue"] = 1
			elseif controlCmd["week3timer2_modevalue"] == "standard" then
				myTable["week3timer2ModeValue"] = 2
			elseif controlCmd["week3timer2_modevalue"] == "compatibilizing" then
				myTable["week3timer2ModeValue"] = 3
			elseif controlCmd["week3timer2_modevalue"] == "smart" then
				myTable["week3timer2ModeValue"] = 4
			end
		end
		if controlCmd["week3timer3_modevalue"] ~= nil then
			if controlCmd["week3timer3_modevalue"] == "energy" then
				myTable["week3timer3ModeValue"] = 1
			elseif controlCmd["week3timer3_modevalue"] == "standard" then
				myTable["week3timer3ModeValue"] = 2
			elseif controlCmd["week3timer3_modevalue"] == "compatibilizing" then
				myTable["week3timer3ModeValue"] = 3
			elseif controlCmd["week3timer3_modevalue"] == "smart" then
				myTable["week3timer3ModeValue"] = 4
			end
		end
		if controlCmd["week3timer4_modevalue"] ~= nil then
			if controlCmd["week3timer4_modevalue"] == "energy" then
				myTable["week3timer4ModeValue"] = 1
			elseif controlCmd["week3timer4_modevalue"] == "standard" then
				myTable["week3timer4ModeValue"] = 2
			elseif controlCmd["week3timer4_modevalue"] == "compatibilizing" then
				myTable["week3timer4ModeValue"] = 3
			elseif controlCmd["week3timer4_modevalue"] == "smart" then
				myTable["week3timer4ModeValue"] = 4
			end
		end
		if controlCmd["week3timer5_modevalue"] ~= nil then
			if controlCmd["week3timer5_modevalue"] == "energy" then
				myTable["week3timer5ModeValue"] = 1
			elseif controlCmd["week3timer5_modevalue"] == "standard" then
				myTable["week3timer5ModeValue"] = 2
			elseif controlCmd["week3timer5_modevalue"] == "compatibilizing" then
				myTable["week3timer5ModeValue"] = 3
			elseif controlCmd["week3timer5_modevalue"] == "smart" then
				myTable["week3timer6ModeValue"] = 4
			end
		end
		if controlCmd["week3timer6_modevalue"] ~= nil then
			if controlCmd["week3timer6_modevalue"] == "energy" then
				myTable["week3timer6ModeValue"] = 1
			elseif controlCmd["week3timer6_modevalue"] == "standard" then
				myTable["week3timer6ModeValue"] = 2
			elseif controlCmd["week3timer6_modevalue"] == "compatibilizing" then
				myTable["week3timer6ModeValue"] = 3
			elseif controlCmd["week3timer6_modevalue"] == "smart" then
				myTable["week3timer6ModeValue"] = 4
			end
		end
		if controlCmd["week4timer1_modevalue"] ~= nil then
			if controlCmd["week4timer1_modevalue"] == "energy" then
				myTable["week4timer1ModeValue"] = 1
			elseif controlCmd["week4timer1_modevalue"] == "standard" then
				myTable["week4timer1ModeValue"] = 2
			elseif controlCmd["week4timer1_modevalue"] == "compatibilizing" then
				myTable["week4timer1ModeValue"] = 3
			elseif controlCmd["week4timer1_modevalue"] == "smart" then
				myTable["week4timer1ModeValue"] = 4
			end
		end
		if controlCmd["week4timer2_modevalue"] ~= nil then
			if controlCmd["week4timer2_modevalue"] == "energy" then
				myTable["week4timer2ModeValue"] = 1
			elseif controlCmd["week4timer2_modevalue"] == "standard" then
				myTable["week4timer2ModeValue"] = 2
			elseif controlCmd["week4timer2_modevalue"] == "compatibilizing" then
				myTable["week4timer2ModeValue"] = 3
			elseif controlCmd["week4timer2_modevalue"] == "smart" then
				myTable["week4timer2ModeValue"] = 4
			end
		end
		if controlCmd["week4timer3_modevalue"] ~= nil then
			if controlCmd["week4timer3_modevalue"] == "energy" then
				myTable["week4timer3ModeValue"] = 1
			elseif controlCmd["week4timer3_modevalue"] == "standard" then
				myTable["week4timer3ModeValue"] = 2
			elseif controlCmd["week4timer3_modevalue"] == "compatibilizing" then
				myTable["week4timer3ModeValue"] = 3
			elseif controlCmd["week4timer3_modevalue"] == "smart" then
				myTable["week4timer3ModeValue"] = 4
			end
		end
		if controlCmd["week4timer4_modevalue"] ~= nil then
			if controlCmd["week4timer4_modevalue"] == "energy" then
				myTable["week4timer4ModeValue"] = 1
			elseif controlCmd["week4timer4_modevalue"] == "standard" then
				myTable["week4timer4ModeValue"] = 2
			elseif controlCmd["week4timer4_modevalue"] == "compatibilizing" then
				myTable["week4timer4ModeValue"] = 3
			elseif controlCmd["week4timer4_modevalue"] == "smart" then
				myTable["week4timer4ModeValue"] = 4
			end
		end
		if controlCmd["week4timer5_modevalue"] ~= nil then
			if controlCmd["week4timer5_modevalue"] == "energy" then
				myTable["week4timer5ModeValue"] = 1
			elseif controlCmd["week4timer5_modevalue"] == "standard" then
				myTable["week4timer5ModeValue"] = 2
			elseif controlCmd["week4timer5_modevalue"] == "compatibilizing" then
				myTable["week4timer5ModeValue"] = 3
			elseif controlCmd["week4timer5_modevalue"] == "smart" then
				myTable["week4timer6ModeValue"] = 4
			end
		end
		if controlCmd["week4timer6_modevalue"] ~= nil then
			if controlCmd["week4timer6_modevalue"] == "energy" then
				myTable["week4timer6ModeValue"] = 1
			elseif controlCmd["week4timer6_modevalue"] == "standard" then
				myTable["week4timer6ModeValue"] = 2
			elseif controlCmd["week4timer6_modevalue"] == "compatibilizing" then
				myTable["week4timer6ModeValue"] = 3
			elseif controlCmd["week4timer6_modevalue"] == "smart" then
				myTable["week4timer6ModeValue"] = 4
			end
		end
		if controlCmd["week5timer1_modevalue"] ~= nil then
			if controlCmd["week5timer1_modevalue"] == "energy" then
				myTable["week5timer1ModeValue"] = 1
			elseif controlCmd["week5timer1_modevalue"] == "standard" then
				myTable["week5timer1ModeValue"] = 2
			elseif controlCmd["week5timer1_modevalue"] == "compatibilizing" then
				myTable["week5timer1ModeValue"] = 3
			elseif controlCmd["week5timer1_modevalue"] == "smart" then
				myTable["week5timer1ModeValue"] = 4
			end
		end
		if controlCmd["week5timer2_modevalue"] ~= nil then
			if controlCmd["week5timer2_modevalue"] == "energy" then
				myTable["week5timer2ModeValue"] = 1
			elseif controlCmd["week5timer2_modevalue"] == "standard" then
				myTable["week5timer2ModeValue"] = 2
			elseif controlCmd["week5timer2_modevalue"] == "compatibilizing" then
				myTable["week5timer2ModeValue"] = 3
			elseif controlCmd["week5timer2_modevalue"] == "smart" then
				myTable["week5timer2ModeValue"] = 4
			end
		end
		if controlCmd["week5timer3_modevalue"] ~= nil then
			if controlCmd["week5timer3_modevalue"] == "energy" then
				myTable["week5timer3ModeValue"] = 1
			elseif controlCmd["week5timer3_modevalue"] == "standard" then
				myTable["week5timer3ModeValue"] = 2
			elseif controlCmd["week5timer3_modevalue"] == "compatibilizing" then
				myTable["week5timer3ModeValue"] = 3
			elseif controlCmd["week5timer3_modevalue"] == "smart" then
				myTable["week5timer3ModeValue"] = 4
			end
		end
		if controlCmd["week5timer4_modevalue"] ~= nil then
			if controlCmd["week5timer4_modevalue"] == "energy" then
				myTable["week5timer4ModeValue"] = 1
			elseif controlCmd["week5timer4_modevalue"] == "standard" then
				myTable["week5timer4ModeValue"] = 2
			elseif controlCmd["week5timer4_modevalue"] == "compatibilizing" then
				myTable["week5timer4ModeValue"] = 3
			elseif controlCmd["week5timer4_modevalue"] == "smart" then
				myTable["week5timer4ModeValue"] = 4
			end
		end
		if controlCmd["week5timer5_modevalue"] ~= nil then
			if controlCmd["week5timer5_modevalue"] == "energy" then
				myTable["week5timer5ModeValue"] = 1
			elseif controlCmd["week5timer5_modevalue"] == "standard" then
				myTable["week5timer5ModeValue"] = 2
			elseif controlCmd["week5timer5_modevalue"] == "compatibilizing" then
				myTable["week5timer5ModeValue"] = 3
			elseif controlCmd["week5timer5_modevalue"] == "smart" then
				myTable["week5timer6ModeValue"] = 4
			end
		end
		if controlCmd["week5timer6_modevalue"] ~= nil then
			if controlCmd["week5timer6_modevalue"] == "energy" then
				myTable["week5timer6ModeValue"] = 1
			elseif controlCmd["week5timer6_modevalue"] == "standard" then
				myTable["week5timer6ModeValue"] = 2
			elseif controlCmd["week5timer6_modevalue"] == "compatibilizing" then
				myTable["week5timer6ModeValue"] = 3
			elseif controlCmd["week5timer6_modevalue"] == "smart" then
				myTable["week5timer6ModeValue"] = 4
			end
		end
		if controlCmd["week6timer1_modevalue"] ~= nil then
			if controlCmd["week6timer1_modevalue"] == "energy" then
				myTable["week6timer1ModeValue"] = 1
			elseif controlCmd["week6timer1_modevalue"] == "standard" then
				myTable["week6timer1ModeValue"] = 2
			elseif controlCmd["week6timer1_modevalue"] == "compatibilizing" then
				myTable["week6timer1ModeValue"] = 3
			elseif controlCmd["week6timer1_modevalue"] == "smart" then
				myTable["week6timer1ModeValue"] = 4
			end
		end
		if controlCmd["week6timer2_modevalue"] ~= nil then
			if controlCmd["week6timer2_modevalue"] == "energy" then
				myTable["week6timer2ModeValue"] = 1
			elseif controlCmd["week6timer2_modevalue"] == "standard" then
				myTable["week6timer2ModeValue"] = 2
			elseif controlCmd["week6timer2_modevalue"] == "compatibilizing" then
				myTable["week6timer2ModeValue"] = 3
			elseif controlCmd["week6timer2_modevalue"] == "smart" then
				myTable["week6timer2ModeValue"] = 4
			end
		end
		if controlCmd["week6timer3_modevalue"] ~= nil then
			if controlCmd["week6timer3_modevalue"] == "energy" then
				myTable["week6timer3ModeValue"] = 1
			elseif controlCmd["week6timer3_modevalue"] == "standard" then
				myTable["week6timer3ModeValue"] = 2
			elseif controlCmd["week6timer3_modevalue"] == "compatibilizing" then
				myTable["week6timer3ModeValue"] = 3
			elseif controlCmd["week6timer3_modevalue"] == "smart" then
				myTable["week6timer3ModeValue"] = 4
			end
		end
		if controlCmd["week6timer4_modevalue"] ~= nil then
			if controlCmd["week6timer4_modevalue"] == "energy" then
				myTable["week6timer4ModeValue"] = 1
			elseif controlCmd["week6timer4_modevalue"] == "standard" then
				myTable["week6timer4ModeValue"] = 2
			elseif controlCmd["week6timer4_modevalue"] == "compatibilizing" then
				myTable["week6timer4ModeValue"] = 3
			elseif controlCmd["week6timer4_modevalue"] == "smart" then
				myTable["week6timer4ModeValue"] = 4
			end
		end
		if controlCmd["week6timer5_modevalue"] ~= nil then
			if controlCmd["week6timer5_modevalue"] == "energy" then
				myTable["week6timer5ModeValue"] = 1
			elseif controlCmd["week6timer5_modevalue"] == "standard" then
				myTable["week6timer5ModeValue"] = 2
			elseif controlCmd["week6timer5_modevalue"] == "compatibilizing" then
				myTable["week6timer5ModeValue"] = 3
			elseif controlCmd["week6timer5_modevalue"] == "smart" then
				myTable["week6timer6ModeValue"] = 4
			end
		end
		if controlCmd["week6timer6_modevalue"] ~= nil then
			if controlCmd["week6timer6_modevalue"] == "energy" then
				myTable["week6timer6ModeValue"] = 1
			elseif controlCmd["week6timer6_modevalue"] == "standard" then
				myTable["week6timer6ModeValue"] = 2
			elseif controlCmd["week6timer6_modevalue"] == "compatibilizing" then
				myTable["week6timer6ModeValue"] = 3
			elseif controlCmd["week6timer6_modevalue"] == "smart" then
				myTable["week6timer6ModeValue"] = 4
			end
		end
	end
end
local function binToModel(binData)
	if (# binData == 0) then
		return nil
	end
	local messageBytes = {}
	for i = 0, 176 do
		messageBytes[i] = 0
	end
	for i = 0, # binData do
		messageBytes[i] = binData[i]
	end
	if (myTable["dataType"] == 3 or myTable["dataType"] == 5) then
		myTable["queryType"] = messageBytes[0]
		if myTable["queryType"] == 1 then
			myTable["powerValue"] = bit.band(messageBytes[2], 1)
			myTable["energyMode"] = bit.band(messageBytes[2], 2)
			myTable["standardMode"] = bit.band(messageBytes[2], 4)
			myTable["compatibilizingMode"] = bit.band(messageBytes[2], 8)
			if (myTable["energyMode"] == 2) then
				myTable["energyMode"] = 1
				myTable["modeValue"] = 1
			elseif (myTable["standardMode"] == 4) then
				myTable["standardMode"] = 1
				myTable["modeValue"] = 2
			elseif (myTable["compatibilizingMode"] == 8) then
				myTable["compatibilizingMode"] = 1
				myTable["modeValue"] = 3
			end
			myTable["heatValue"] = bit.band(messageBytes[2], 16)
			myTable["dicaryonHeat"] = bit.band(messageBytes[2], 32)
			myTable["eco"] = bit.band(messageBytes[2], 64)
			myTable["tsValue"] = messageBytes[3]
			myTable["washBoxTemp"] = messageBytes[4]
			myTable["boxTopTemp"] = messageBytes[5]
			myTable["boxBottomTemp"] = messageBytes[6]
			myTable["t3Value"] = messageBytes[7]
			myTable["t4Value"] = messageBytes[8]
			myTable["compressorTopTemp"] = messageBytes[9]
			myTable["tsMaxValue"] = messageBytes[10]
			myTable["tsMinValue"] = messageBytes[11]
			myTable["timer1OpenHour"] = messageBytes[12]
			myTable["timer1OpenMin"] = messageBytes[13]
			myTable["timer1CloseHour"] = messageBytes[14]
			myTable["timer1CloseMin"] = messageBytes[15]
			myTable["timer2OpenHour"] = messageBytes[16]
			myTable["timer2OpenMin"] = messageBytes[17]
			myTable["timer2CloseHour"] = messageBytes[18]
			myTable["timer2CloseMin"] = messageBytes[19]
			myTable["errorCode"] = messageBytes[20]
			myTable["order1Temp"] = messageBytes[21]
			myTable["order1TimeHour"] = messageBytes[22]
			myTable["order1TimeMin"] = messageBytes[23]
			myTable["order2Temp"] = messageBytes[24]
			myTable["order2TimeHour"] = messageBytes[25]
			myTable["order2TimeMin"] = messageBytes[26]
			myTable["bottomElecHeat"] = bit.band(messageBytes[27], 1)
			myTable["topElecHeat"] = bit.band(messageBytes[27], 2)
			myTable["waterPump"] = bit.band(messageBytes[27], 4)
			myTable["compressor"] = bit.band(messageBytes[27], 8)
			myTable["middleWind"] = bit.band(messageBytes[27], 16)
			myTable["fourWayValve"] = bit.band(messageBytes[27], 32)
			myTable["lowWind"] = bit.band(messageBytes[27], 64)
			myTable["highWind"] = bit.band(messageBytes[27], 128)
			myTable["elecHeatSupport"] = bit.band(messageBytes[28], 1)
			myTable["order1Effect"] = bit.band(messageBytes[28], 8)
			myTable["order2Effect"] = bit.band(messageBytes[28], 16)
			myTable["smartMode"] = bit.band(messageBytes[28], 32)
			myTable["backwaterEffect"] = bit.band(messageBytes[28], 64)
			myTable["sterilizeEffect"] = bit.band(messageBytes[28], 128)
			myTable["typeInfo"] = messageBytes[29]
			myTable["order1StopTimeHour"] = messageBytes[30]
			myTable["order1StopTimeMin"] = messageBytes[31]
			myTable["order2StopTimeHour"] = messageBytes[32]
			myTable["order2StopTimeMin"] = messageBytes[33]
			myTable["hotWater"] = messageBytes[34]
			myTable["vacationMode"] = bit.band(messageBytes[35], 1)
			if myTable["vacationMode"] == 1 then
				myTable["vacationMode"] = 16
			end
			myTable["smartGrid"] = bit.band(messageBytes[35], 2)
			myTable["multiTerminal"] = bit.band(messageBytes[35], 4)
			myTable["fahrenheitEffect"] = bit.band(messageBytes[35], 128)
			myTable["vacadaysValue"] = messageBytes[36] * 256 + messageBytes[37]
			myTable["week0timer1Effect"] = bit.band(messageBytes[38], 1)
			myTable["week0timer2Effect"] = bit.band(messageBytes[38], 2)
			myTable["week0timer3Effect"] = bit.band(messageBytes[38], 4)
			myTable["week0timer4Effect"] = bit.band(messageBytes[38], 8)
			myTable["week0timer5Effect"] = bit.band(messageBytes[38], 16)
			myTable["week0timer6Effect"] = bit.band(messageBytes[38], 32)
			myTable["week1timer1Effect"] = bit.band(messageBytes[39], 1)
			myTable["week1timer2Effect"] = bit.band(messageBytes[39], 2)
			myTable["week1timer3Effect"] = bit.band(messageBytes[39], 4)
			myTable["week1timer4Effect"] = bit.band(messageBytes[39], 8)
			myTable["week1timer5Effect"] = bit.band(messageBytes[39], 16)
			myTable["week1timer6Effect"] = bit.band(messageBytes[39], 32)
			myTable["week2timer1Effect"] = bit.band(messageBytes[40], 1)
			myTable["week2timer2Effect"] = bit.band(messageBytes[40], 2)
			myTable["week2timer3Effect"] = bit.band(messageBytes[40], 4)
			myTable["week2timer4Effect"] = bit.band(messageBytes[40], 8)
			myTable["week2timer5Effect"] = bit.band(messageBytes[40], 16)
			myTable["week2timer6Effect"] = bit.band(messageBytes[40], 32)
			myTable["week3timer1Effect"] = bit.band(messageBytes[41], 1)
			myTable["week3timer2Effect"] = bit.band(messageBytes[41], 2)
			myTable["week3timer3Effect"] = bit.band(messageBytes[41], 4)
			myTable["week3timer4Effect"] = bit.band(messageBytes[41], 8)
			myTable["week3timer5Effect"] = bit.band(messageBytes[41], 16)
			myTable["week3timer6Effect"] = bit.band(messageBytes[41], 32)
			myTable["week4timer1Effect"] = bit.band(messageBytes[42], 1)
			myTable["week4timer2Effect"] = bit.band(messageBytes[42], 2)
			myTable["week4timer3Effect"] = bit.band(messageBytes[42], 4)
			myTable["week4timer4Effect"] = bit.band(messageBytes[42], 8)
			myTable["week4timer5Effect"] = bit.band(messageBytes[42], 16)
			myTable["week4timer6Effect"] = bit.band(messageBytes[42], 32)
			myTable["week5timer1Effect"] = bit.band(messageBytes[43], 1)
			myTable["week5timer2Effect"] = bit.band(messageBytes[43], 2)
			myTable["week5timer3Effect"] = bit.band(messageBytes[43], 4)
			myTable["week5timer4Effect"] = bit.band(messageBytes[43], 8)
			myTable["week5timer5Effect"] = bit.band(messageBytes[43], 16)
			myTable["week5timer6Effect"] = bit.band(messageBytes[43], 32)
			myTable["week6timer1Effect"] = bit.band(messageBytes[44], 1)
			myTable["week6timer2Effect"] = bit.band(messageBytes[44], 2)
			myTable["week6timer3Effect"] = bit.band(messageBytes[44], 4)
			myTable["week6timer4Effect"] = bit.band(messageBytes[44], 8)
			myTable["week6timer5Effect"] = bit.band(messageBytes[44], 16)
			myTable["week6timer6Effect"] = bit.band(messageBytes[44], 32)
			myTable["autoSterilizeWeek"] = messageBytes[45]
			myTable["autoSterilizeHour"] = messageBytes[46]
			myTable["autoSterilizeMinute"] = messageBytes[47]
			myTable["vacadaysStartYearValue"] = messageBytes[48]
			myTable["vacadaysStartMonthValue"] = messageBytes[49]
			myTable["vacadaysStartDayValue"] = messageBytes[50]
			myTable["vacationTsValue"] = messageBytes[51]
		elseif (myTable["queryType"] == 2) then
			myTable["week0timer1Effect"] = bit.band(messageBytes[2], 1)
			myTable["week0timer2Effect"] = bit.band(messageBytes[2], 2)
			myTable["week0timer3Effect"] = bit.band(messageBytes[2], 4)
			myTable["week0timer4Effect"] = bit.band(messageBytes[2], 8)
			myTable["week0timer5Effect"] = bit.band(messageBytes[2], 16)
			myTable["week0timer6Effect"] = bit.band(messageBytes[2], 32)
			myTable["week1timer1Effect"] = bit.band(messageBytes[3], 1)
			myTable["week1timer2Effect"] = bit.band(messageBytes[3], 2)
			myTable["week1timer3Effect"] = bit.band(messageBytes[3], 4)
			myTable["week1timer4Effect"] = bit.band(messageBytes[3], 8)
			myTable["week1timer5Effect"] = bit.band(messageBytes[3], 16)
			myTable["week1timer6Effect"] = bit.band(messageBytes[3], 32)
			myTable["week2timer1Effect"] = bit.band(messageBytes[4], 1)
			myTable["week2timer2Effect"] = bit.band(messageBytes[4], 2)
			myTable["week2timer3Effect"] = bit.band(messageBytes[4], 4)
			myTable["week2timer4Effect"] = bit.band(messageBytes[4], 8)
			myTable["week2timer5Effect"] = bit.band(messageBytes[4], 16)
			myTable["week2timer6Effect"] = bit.band(messageBytes[4], 32)
			myTable["week3timer1Effect"] = bit.band(messageBytes[5], 1)
			myTable["week3timer2Effect"] = bit.band(messageBytes[5], 2)
			myTable["week3timer3Effect"] = bit.band(messageBytes[5], 4)
			myTable["week3timer4Effect"] = bit.band(messageBytes[5], 8)
			myTable["week3timer5Effect"] = bit.band(messageBytes[5], 16)
			myTable["week3timer6Effect"] = bit.band(messageBytes[5], 32)
			myTable["week4timer1Effect"] = bit.band(messageBytes[6], 1)
			myTable["week4timer2Effect"] = bit.band(messageBytes[6], 2)
			myTable["week4timer3Effect"] = bit.band(messageBytes[6], 4)
			myTable["week4timer4Effect"] = bit.band(messageBytes[6], 8)
			myTable["week4timer5Effect"] = bit.band(messageBytes[6], 16)
			myTable["week4timer6Effect"] = bit.band(messageBytes[6], 32)
			myTable["week5timer1Effect"] = bit.band(messageBytes[7], 1)
			myTable["week5timer2Effect"] = bit.band(messageBytes[7], 2)
			myTable["week5timer3Effect"] = bit.band(messageBytes[7], 4)
			myTable["week5timer4Effect"] = bit.band(messageBytes[7], 8)
			myTable["week5timer5Effect"] = bit.band(messageBytes[7], 16)
			myTable["week5timer6Effect"] = bit.band(messageBytes[7], 32)
			myTable["week6timer1Effect"] = bit.band(messageBytes[8], 1)
			myTable["week6timer2Effect"] = bit.band(messageBytes[8], 2)
			myTable["week6timer3Effect"] = bit.band(messageBytes[8], 4)
			myTable["week6timer4Effect"] = bit.band(messageBytes[8], 8)
			myTable["week6timer5Effect"] = bit.band(messageBytes[8], 16)
			myTable["week6timer6Effect"] = bit.band(messageBytes[8], 32)
			myTable["week0timer1OpenTime"] = messageBytes[9]
			myTable["week0timer1CloseTime"] = messageBytes[10]
			myTable["week0timer1SetTemperature"] = messageBytes[11]
			myTable["week0timer1ModeValue"] = messageBytes[12]
			myTable["week0timer2OpenTime"] = messageBytes[13]
			myTable["week0timer2CloseTime"] = messageBytes[14]
			myTable["week0timer2SetTemperature"] = messageBytes[15]
			myTable["week0timer2ModeValue"] = messageBytes[16]
			myTable["week0timer3OpenTime"] = messageBytes[17]
			myTable["week0timer3CloseTime"] = messageBytes[18]
			myTable["week0timer3SetTemperature"] = messageBytes[19]
			myTable["week0timer3ModeValue"] = messageBytes[20]
			myTable["week0timer4OpenTime"] = messageBytes[21]
			myTable["week0timer4CloseTime"] = messageBytes[22]
			myTable["week0timer4SetTemperature"] = messageBytes[23]
			myTable["week0timer4ModeValue"] = messageBytes[24]
			myTable["week0timer5OpenTime"] = messageBytes[25]
			myTable["week0timer5CloseTime"] = messageBytes[26]
			myTable["week0timer5SetTemperature"] = messageBytes[27]
			myTable["week0timer5ModeValue"] = messageBytes[28]
			myTable["week0timer6OpenTime"] = messageBytes[29]
			myTable["week0timer6CloseTime"] = messageBytes[30]
			myTable["week0timer6SetTemperature"] = messageBytes[31]
			myTable["week0timer6ModeValue"] = messageBytes[32]
			myTable["week1timer1OpenTime"] = messageBytes[33]
			myTable["week1timer1CloseTime"] = messageBytes[34]
			myTable["week1timer1SetTemperature"] = messageBytes[35]
			myTable["week1timer1ModeValue"] = messageBytes[36]
			myTable["week1timer2OpenTime"] = messageBytes[37]
			myTable["week1timer2CloseTime"] = messageBytes[38]
			myTable["week1timer2SetTemperature"] = messageBytes[39]
			myTable["week1timer2ModeValue"] = messageBytes[40]
			myTable["week1timer3OpenTime"] = messageBytes[41]
			myTable["week1timer3CloseTime"] = messageBytes[42]
			myTable["week1timer3SetTemperature"] = messageBytes[43]
			myTable["week1timer3ModeValue"] = messageBytes[44]
			myTable["week1timer4OpenTime"] = messageBytes[45]
			myTable["week1timer4CloseTime"] = messageBytes[46]
			myTable["week1timer4SetTemperature"] = messageBytes[47]
			myTable["week1timer4ModeValue"] = messageBytes[48]
			myTable["week1timer5OpenTime"] = messageBytes[49]
			myTable["week1timer5CloseTime"] = messageBytes[50]
			myTable["week1timer5SetTemperature"] = messageBytes[51]
			myTable["week1timer5ModeValue"] = messageBytes[52]
			myTable["week1timer6OpenTime"] = messageBytes[53]
			myTable["week1timer6CloseTime"] = messageBytes[54]
			myTable["week1timer6SetTemperature"] = messageBytes[55]
			myTable["week1timer6ModeValue"] = messageBytes[56]
			myTable["week2timer1OpenTime"] = messageBytes[57]
			myTable["week2timer1CloseTime"] = messageBytes[58]
			myTable["week2timer1SetTemperature"] = messageBytes[59]
			myTable["week2timer1ModeValue"] = messageBytes[60]
			myTable["week2timer2OpenTime"] = messageBytes[61]
			myTable["week2timer2CloseTime"] = messageBytes[62]
			myTable["week2timer2SetTemperature"] = messageBytes[63]
			myTable["week2timer2ModeValue"] = messageBytes[64]
			myTable["week2timer3OpenTime"] = messageBytes[65]
			myTable["week2timer3CloseTime"] = messageBytes[66]
			myTable["week2timer3SetTemperature"] = messageBytes[67]
			myTable["week2timer3ModeValue"] = messageBytes[68]
			myTable["week2timer4OpenTime"] = messageBytes[69]
			myTable["week2timer4CloseTime"] = messageBytes[70]
			myTable["week2timer4SetTemperature"] = messageBytes[71]
			myTable["week2timer4ModeValue"] = messageBytes[72]
			myTable["week2timer5OpenTime"] = messageBytes[73]
			myTable["week2timer5CloseTime"] = messageBytes[74]
			myTable["week2timer5SetTemperature"] = messageBytes[75]
			myTable["week2timer5ModeValue"] = messageBytes[76]
			myTable["week2timer6OpenTime"] = messageBytes[77]
			myTable["week2timer6CloseTime"] = messageBytes[78]
			myTable["week2timer6SetTemperature"] = messageBytes[79]
			myTable["week2timer6ModeValue"] = messageBytes[80]
			myTable["week3timer1OpenTime"] = messageBytes[81]
			myTable["week3timer1CloseTime"] = messageBytes[82]
			myTable["week3timer1SetTemperature"] = messageBytes[83]
			myTable["week3timer1ModeValue"] = messageBytes[84]
			myTable["week3timer2OpenTime"] = messageBytes[85]
			myTable["week3timer2CloseTime"] = messageBytes[86]
			myTable["week3timer2SetTemperature"] = messageBytes[87]
			myTable["week3timer2ModeValue"] = messageBytes[88]
			myTable["week3timer3OpenTime"] = messageBytes[89]
			myTable["week3timer3CloseTime"] = messageBytes[90]
			myTable["week3timer3SetTemperature"] = messageBytes[91]
			myTable["week3timer3ModeValue"] = messageBytes[92]
			myTable["week3timer4OpenTime"] = messageBytes[93]
			myTable["week3timer4CloseTime"] = messageBytes[94]
			myTable["week3timer4SetTemperature"] = messageBytes[95]
			myTable["week3timer4ModeValue"] = messageBytes[96]
			myTable["week3timer5OpenTime"] = messageBytes[97]
			myTable["week3timer5CloseTime"] = messageBytes[98]
			myTable["week3timer5SetTemperature"] = messageBytes[99]
			myTable["week3timer5ModeValue"] = messageBytes[100]
			myTable["week3timer6OpenTime"] = messageBytes[101]
			myTable["week3timer6CloseTime"] = messageBytes[102]
			myTable["week3timer6SetTemperature"] = messageBytes[103]
			myTable["week3timer6ModeValue"] = messageBytes[104]
			myTable["week4timer1OpenTime"] = messageBytes[105]
			myTable["week4timer1CloseTime"] = messageBytes[106]
			myTable["week4timer1SetTemperature"] = messageBytes[107]
			myTable["week4timer1ModeValue"] = messageBytes[108]
			myTable["week4timer2OpenTime"] = messageBytes[109]
			myTable["week4timer2CloseTime"] = messageBytes[110]
			myTable["week4timer2SetTemperature"] = messageBytes[111]
			myTable["week4timer2ModeValue"] = messageBytes[112]
			myTable["week4timer3OpenTime"] = messageBytes[113]
			myTable["week4timer3CloseTime"] = messageBytes[114]
			myTable["week4timer3SetTemperature"] = messageBytes[115]
			myTable["week4timer3ModeValue"] = messageBytes[116]
			myTable["week4timer4OpenTime"] = messageBytes[117]
			myTable["week4timer4CloseTime"] = messageBytes[118]
			myTable["week4timer4SetTemperature"] = messageBytes[119]
			myTable["week4timer4ModeValue"] = messageBytes[120]
			myTable["week4timer5OpenTime"] = messageBytes[121]
			myTable["week4timer5CloseTime"] = messageBytes[122]
			myTable["week4timer5SetTemperature"] = messageBytes[123]
			myTable["week4timer5ModeValue"] = messageBytes[124]
			myTable["week4timer6OpenTime"] = messageBytes[125]
			myTable["week4timer6CloseTime"] = messageBytes[126]
			myTable["week4timer6SetTemperature"] = messageBytes[127]
			myTable["week4timer6ModeValue"] = messageBytes[128]
			myTable["week5timer1OpenTime"] = messageBytes[129]
			myTable["week5timer1CloseTime"] = messageBytes[130]
			myTable["week5timer1SetTemperature"] = messageBytes[131]
			myTable["week5timer1ModeValue"] = messageBytes[132]
			myTable["week5timer2OpenTime"] = messageBytes[133]
			myTable["week5timer2CloseTime"] = messageBytes[134]
			myTable["week5timer2SetTemperature"] = messageBytes[135]
			myTable["week5timer2ModeValue"] = messageBytes[136]
			myTable["week5timer3OpenTime"] = messageBytes[137]
			myTable["week5timer3CloseTime"] = messageBytes[138]
			myTable["week5timer3SetTemperature"] = messageBytes[139]
			myTable["week5timer3ModeValue"] = messageBytes[140]
			myTable["week5timer4OpenTime"] = messageBytes[141]
			myTable["week5timer4CloseTime"] = messageBytes[142]
			myTable["week5timer4SetTemperature"] = messageBytes[143]
			myTable["week5timer4ModeValue"] = messageBytes[144]
			myTable["week5timer5OpenTime"] = messageBytes[145]
			myTable["week5timer5CloseTime"] = messageBytes[146]
			myTable["week5timer5SetTemperature"] = messageBytes[147]
			myTable["week5timer5ModeValue"] = messageBytes[148]
			myTable["week5timer6OpenTime"] = messageBytes[149]
			myTable["week5timer6CloseTime"] = messageBytes[150]
			myTable["week5timer6SetTemperature"] = messageBytes[151]
			myTable["week5timer6ModeValue"] = messageBytes[152]
			myTable["week6timer1OpenTime"] = messageBytes[153]
			myTable["week6timer1CloseTime"] = messageBytes[154]
			myTable["week6timer1SetTemperature"] = messageBytes[155]
			myTable["week6timer1ModeValue"] = messageBytes[156]
			myTable["week6timer2OpenTime"] = messageBytes[157]
			myTable["week6timer2CloseTime"] = messageBytes[158]
			myTable["week6timer2SetTemperature"] = messageBytes[159]
			myTable["week6timer2ModeValue"] = messageBytes[160]
			myTable["week6timer3OpenTime"] = messageBytes[161]
			myTable["week6timer3CloseTime"] = messageBytes[162]
			myTable["week6timer3SetTemperature"] = messageBytes[163]
			myTable["week6timer3ModeValue"] = messageBytes[164]
			myTable["week6timer4OpenTime"] = messageBytes[165]
			myTable["week6timer4CloseTime"] = messageBytes[166]
			myTable["week6timer4SetTemperature"] = messageBytes[167]
			myTable["week6timer4ModeValue"] = messageBytes[168]
			myTable["week6timer5OpenTime"] = messageBytes[169]
			myTable["week6timer5CloseTime"] = messageBytes[170]
			myTable["week6timer5SetTemperature"] = messageBytes[171]
			myTable["week6timer5ModeValue"] = messageBytes[172]
			myTable["week6timer6OpenTime"] = messageBytes[173]
			myTable["week6timer6CloseTime"] = messageBytes[174]
			myTable["week6timer6SetTemperature"] = messageBytes[175]
			myTable["week6timer6ModeValue"] = messageBytes[176]
		elseif (myTable["queryType"] == 3) then
			myTable["timer1Effect"] = bit.band(messageBytes[3], 1)
			myTable["timer2Effect"] = bit.band(messageBytes[3], 2)
			myTable["timer3Effect"] = bit.band(messageBytes[3], 4)
			myTable["timer4Effect"] = bit.band(messageBytes[3], 8)
			myTable["timer5Effect"] = bit.band(messageBytes[3], 16)
			myTable["timer6Effect"] = bit.band(messageBytes[3], 32)
			myTable["timer1OpenHour"] = messageBytes[4]
			myTable["timer1OpenMin"] = messageBytes[5]
			myTable["timer1CloseHour"] = messageBytes[6]
			myTable["timer1CloseMin"] = messageBytes[7]
			myTable["timer1SetTemperature"] = messageBytes[8]
			myTable["timer1ModeValue"] = messageBytes[9]
			myTable["timer2OpenHour"] = messageBytes[10]
			myTable["timer2OpenMin"] = messageBytes[11]
			myTable["timer2CloseHour"] = messageBytes[12]
			myTable["timer2CloseMin"] = messageBytes[13]
			myTable["timer2SetTemperature"] = messageBytes[14]
			myTable["timer2ModeValue"] = messageBytes[15]
			myTable["timer3OpenHour"] = messageBytes[16]
			myTable["timer3OpenMin"] = messageBytes[17]
			myTable["timer3CloseHour"] = messageBytes[18]
			myTable["timer3CloseMin"] = messageBytes[19]
			myTable["timer3SetTemperature"] = messageBytes[20]
			myTable["timer3ModeValue"] = messageBytes[21]
			myTable["timer4OpenHour"] = messageBytes[22]
			myTable["timer4OpenMin"] = messageBytes[23]
			myTable["timer4CloseHour"] = messageBytes[24]
			myTable["timer4CloseMin"] = messageBytes[25]
			myTable["timer4SetTemperature"] = messageBytes[26]
			myTable["timer4ModeValue"] = messageBytes[27]
			myTable["timer5OpenHour"] = messageBytes[28]
			myTable["timer5OpenMin"] = messageBytes[29]
			myTable["timer5CloseHour"] = messageBytes[30]
			myTable["timer5CloseMin"] = messageBytes[31]
			myTable["timer5SetTemperature"] = messageBytes[32]
			myTable["timer5ModeValue"] = messageBytes[33]
			myTable["timer6OpenHour"] = messageBytes[34]
			myTable["timer6OpenMin"] = messageBytes[35]
			myTable["timer6CloseHour"] = messageBytes[36]
			myTable["timer6CloseMin"] = messageBytes[37]
			myTable["timer6SetTemperature"] = messageBytes[38]
			myTable["timer6ModeValue"] = messageBytes[39]
		end
	elseif myTable["dataType"] == 2 then
		myTable["controlType"] = messageBytes[0]
		if myTable["controlType"] == 1 then
			myTable["powerValue"] = messageBytes[2]
			myTable["modeValue"] = messageBytes[3]
			myTable["tsValue"] = messageBytes[4]
			myTable["trValue"] = messageBytes[5]
			myTable["openPTC"] = messageBytes[6]
			myTable["ptcTemp"] = messageBytes[7]
			myTable["waterPump"] = bit.band(messageBytes[8], 1)
			myTable["refrigerantRecycling"] = bit.band(messageBytes[8], 2)
			myTable["defrost"] = bit.band(messageBytes[8], 4)
			myTable["mute"] = bit.band(messageBytes[8], 8)
			myTable["vacationMode"] = bit.band(messageBytes[8], 16)
			myTable["openPTCTemp"] = bit.band(messageBytes[8], 64)
			myTable["fahrenheitEffect"] = bit.band(messageBytes[8], 128)
			myTable["vacadaysValue"] = messageBytes[9] * 256 + messageBytes[10]
			myTable["vacadaysStartYearValue"] = messageBytes[11]
			myTable["vacadaysStartMonthValue"] = messageBytes[12]
			myTable["vacadaysStartDayValue"] = messageBytes[13]
			myTable["vacationTsValue"] = messageBytes[14]
		elseif (myTable["controlType"] == 2) then
			myTable["timer1Effect"] = bit.band(messageBytes[3], 1)
			myTable["timer2Effect"] = bit.band(messageBytes[3], 2)
			myTable["timer3Effect"] = bit.band(messageBytes[3], 4)
			myTable["timer4Effect"] = bit.band(messageBytes[3], 8)
			myTable["timer5Effect"] = bit.band(messageBytes[3], 16)
			myTable["timer6Effect"] = bit.band(messageBytes[3], 32)
			myTable["timer1OpenHour"] = messageBytes[4]
			myTable["timer1OpenMin"] = messageBytes[5]
			myTable["timer1CloseHour"] = messageBytes[6]
			myTable["timer1CloseMin"] = messageBytes[7]
			myTable["timer1SetTemperature"] = messageBytes[8]
			myTable["timer1ModeValue"] = messageBytes[9]
			myTable["timer2OpenHour"] = messageBytes[10]
			myTable["timer2OpenMin"] = messageBytes[11]
			myTable["timer2CloseHour"] = messageBytes[12]
			myTable["timer2CloseMin"] = messageBytes[13]
			myTable["timer2SetTemperature"] = messageBytes[14]
			myTable["timer2ModeValue"] = messageBytes[15]
			myTable["timer3OpenHour"] = messageBytes[16]
			myTable["timer3OpenMin"] = messageBytes[17]
			myTable["timer3CloseHour"] = messageBytes[18]
			myTable["timer3CloseMin"] = messageBytes[19]
			myTable["timer3SetTemperature"] = messageBytes[20]
			myTable["timer3ModeValue"] = messageBytes[21]
			myTable["timer4OpenHour"] = messageBytes[22]
			myTable["timer4OpenMin"] = messageBytes[23]
			myTable["timer4CloseHour"] = messageBytes[24]
			myTable["timer4CloseMin"] = messageBytes[25]
			myTable["timer4SetTemperature"] = messageBytes[26]
			myTable["timer4ModeValue"] = messageBytes[27]
			myTable["timer5OpenHour"] = messageBytes[28]
			myTable["timer5OpenMin"] = messageBytes[29]
			myTable["timer5CloseHour"] = messageBytes[30]
			myTable["timer5CloseMin"] = messageBytes[31]
			myTable["timer5SetTemperature"] = messageBytes[32]
			myTable["timer5ModeValue"] = messageBytes[33]
			myTable["timer6OpenHour"] = messageBytes[34]
			myTable["timer6OpenMin"] = messageBytes[35]
			myTable["timer6CloseHour"] = messageBytes[36]
			myTable["timer6CloseMin"] = messageBytes[37]
			myTable["timer6SetTemperature"] = messageBytes[38]
			myTable["timer6ModeValue"] = messageBytes[39]
		elseif (myTable["controlType"] == 3) then
			myTable["order1Effect"] = messageBytes[2]
			myTable["order1Temp"] = messageBytes[3]
			myTable["order1TimeHour"] = messageBytes[4]
			myTable["order1TimeMin"] = messageBytes[5]
			myTable["order2Effect"] = messageBytes[6]
			myTable["order2Temp"] = messageBytes[7]
			myTable["order2TimeHour"] = messageBytes[8]
			myTable["order2TimeMin"] = messageBytes[9]
			myTable["order1StopTimeHour"] = messageBytes[10]
			myTable["order1StopTimeMin"] = messageBytes[11]
			myTable["order2StopTimeHour"] = messageBytes[12]
			myTable["order2StopTimeMin"] = messageBytes[13]
		elseif (myTable["controlType"] == 5) then
			myTable["backwaterEffect"] = messageBytes[2]
		elseif (myTable["controlType"] == 6) then
			myTable["sterilizeEffect"] = bit.band(messageBytes[2], 128)
			myTable["autoSterilizeWeek"] = messageBytes[3]
			myTable["autoSterilizeHour"] = messageBytes[4]
			myTable["autoSterilizeMinute"] = messageBytes[5]
		elseif (myTable["controlType"] == 7) then
			myTable["week0timer1Effect"] = bit.band(messageBytes[2], 1)
			myTable["week0timer2Effect"] = bit.band(messageBytes[2], 2)
			myTable["week0timer3Effect"] = bit.band(messageBytes[2], 4)
			myTable["week0timer4Effect"] = bit.band(messageBytes[2], 8)
			myTable["week0timer5Effect"] = bit.band(messageBytes[2], 16)
			myTable["week0timer6Effect"] = bit.band(messageBytes[2], 32)
			myTable["week1timer1Effect"] = bit.band(messageBytes[3], 1)
			myTable["week1timer2Effect"] = bit.band(messageBytes[3], 2)
			myTable["week1timer3Effect"] = bit.band(messageBytes[3], 4)
			myTable["week1timer4Effect"] = bit.band(messageBytes[3], 8)
			myTable["week1timer5Effect"] = bit.band(messageBytes[3], 16)
			myTable["week1timer6Effect"] = bit.band(messageBytes[3], 32)
			myTable["week2timer1Effect"] = bit.band(messageBytes[4], 1)
			myTable["week2timer2Effect"] = bit.band(messageBytes[4], 2)
			myTable["week2timer3Effect"] = bit.band(messageBytes[4], 4)
			myTable["week2timer4Effect"] = bit.band(messageBytes[4], 8)
			myTable["week2timer5Effect"] = bit.band(messageBytes[4], 16)
			myTable["week2timer6Effect"] = bit.band(messageBytes[4], 32)
			myTable["week3timer1Effect"] = bit.band(messageBytes[5], 1)
			myTable["week3timer2Effect"] = bit.band(messageBytes[5], 2)
			myTable["week3timer3Effect"] = bit.band(messageBytes[5], 4)
			myTable["week3timer4Effect"] = bit.band(messageBytes[5], 8)
			myTable["week3timer5Effect"] = bit.band(messageBytes[5], 16)
			myTable["week3timer6Effect"] = bit.band(messageBytes[5], 32)
			myTable["week4timer1Effect"] = bit.band(messageBytes[6], 1)
			myTable["week4timer2Effect"] = bit.band(messageBytes[6], 2)
			myTable["week4timer3Effect"] = bit.band(messageBytes[6], 4)
			myTable["week4timer4Effect"] = bit.band(messageBytes[6], 8)
			myTable["week4timer5Effect"] = bit.band(messageBytes[6], 16)
			myTable["week4timer6Effect"] = bit.band(messageBytes[6], 32)
			myTable["week5timer1Effect"] = bit.band(messageBytes[7], 1)
			myTable["week5timer2Effect"] = bit.band(messageBytes[7], 2)
			myTable["week5timer3Effect"] = bit.band(messageBytes[7], 4)
			myTable["week5timer4Effect"] = bit.band(messageBytes[7], 8)
			myTable["week5timer5Effect"] = bit.band(messageBytes[7], 16)
			myTable["week5timer6Effect"] = bit.band(messageBytes[7], 32)
			myTable["week6timer1Effect"] = bit.band(messageBytes[8], 1)
			myTable["week6timer2Effect"] = bit.band(messageBytes[8], 2)
			myTable["week6timer3Effect"] = bit.band(messageBytes[8], 4)
			myTable["week6timer4Effect"] = bit.band(messageBytes[8], 8)
			myTable["week6timer5Effect"] = bit.band(messageBytes[8], 16)
			myTable["week6timer6Effect"] = bit.band(messageBytes[8], 32)
			myTable["week0timer1OpenTime"] = messageBytes[9]
			myTable["week0timer1CloseTime"] = messageBytes[10]
			myTable["week0timer1SetTemperature"] = messageBytes[11]
			myTable["week0timer1ModeValue"] = messageBytes[12]
			myTable["week0timer2OpenTime"] = messageBytes[13]
			myTable["week0timer2CloseTime"] = messageBytes[14]
			myTable["week0timer2SetTemperature"] = messageBytes[15]
			myTable["week0timer2ModeValue"] = messageBytes[16]
			myTable["week0timer3OpenTime"] = messageBytes[17]
			myTable["week0timer3CloseTime"] = messageBytes[18]
			myTable["week0timer3SetTemperature"] = messageBytes[19]
			myTable["week0timer3ModeValue"] = messageBytes[20]
			myTable["week0timer4OpenTime"] = messageBytes[21]
			myTable["week0timer4CloseTime"] = messageBytes[22]
			myTable["week0timer4SetTemperature"] = messageBytes[23]
			myTable["week0timer4ModeValue"] = messageBytes[24]
			myTable["week0timer5OpenTime"] = messageBytes[25]
			myTable["week0timer5CloseTime"] = messageBytes[26]
			myTable["week0timer5SetTemperature"] = messageBytes[27]
			myTable["week0timer5ModeValue"] = messageBytes[28]
			myTable["week0timer6OpenTime"] = messageBytes[29]
			myTable["week0timer6CloseTime"] = messageBytes[30]
			myTable["week0timer6SetTemperature"] = messageBytes[31]
			myTable["week0timer6ModeValue"] = messageBytes[32]
			myTable["week1timer1OpenTime"] = messageBytes[33]
			myTable["week1timer1CloseTime"] = messageBytes[34]
			myTable["week1timer1SetTemperature"] = messageBytes[35]
			myTable["week1timer1ModeValue"] = messageBytes[36]
			myTable["week1timer2OpenTime"] = messageBytes[37]
			myTable["week1timer2CloseTime"] = messageBytes[38]
			myTable["week1timer2SetTemperature"] = messageBytes[39]
			myTable["week1timer2ModeValue"] = messageBytes[40]
			myTable["week1timer3OpenTime"] = messageBytes[41]
			myTable["week1timer3CloseTime"] = messageBytes[42]
			myTable["week1timer3SetTemperature"] = messageBytes[43]
			myTable["week1timer3ModeValue"] = messageBytes[44]
			myTable["week1timer4OpenTime"] = messageBytes[45]
			myTable["week1timer4CloseTime"] = messageBytes[46]
			myTable["week1timer4SetTemperature"] = messageBytes[47]
			myTable["week1timer4ModeValue"] = messageBytes[48]
			myTable["week1timer5OpenTime"] = messageBytes[49]
			myTable["week1timer5CloseTime"] = messageBytes[50]
			myTable["week1timer5SetTemperature"] = messageBytes[51]
			myTable["week1timer5ModeValue"] = messageBytes[52]
			myTable["week1timer6OpenTime"] = messageBytes[53]
			myTable["week1timer6CloseTime"] = messageBytes[54]
			myTable["week1timer6SetTemperature"] = messageBytes[55]
			myTable["week1timer6ModeValue"] = messageBytes[56]
			myTable["week2timer1OpenTime"] = messageBytes[57]
			myTable["week2timer1CloseTime"] = messageBytes[58]
			myTable["week2timer1SetTemperature"] = messageBytes[59]
			myTable["week2timer1ModeValue"] = messageBytes[60]
			myTable["week2timer2OpenTime"] = messageBytes[61]
			myTable["week2timer2CloseTime"] = messageBytes[62]
			myTable["week2timer2SetTemperature"] = messageBytes[63]
			myTable["week2timer2ModeValue"] = messageBytes[64]
			myTable["week2timer3OpenTime"] = messageBytes[65]
			myTable["week2timer3CloseTime"] = messageBytes[66]
			myTable["week2timer3SetTemperature"] = messageBytes[67]
			myTable["week2timer3ModeValue"] = messageBytes[68]
			myTable["week2timer4OpenTime"] = messageBytes[69]
			myTable["week2timer4CloseTime"] = messageBytes[70]
			myTable["week2timer4SetTemperature"] = messageBytes[71]
			myTable["week2timer4ModeValue"] = messageBytes[72]
			myTable["week2timer5OpenTime"] = messageBytes[73]
			myTable["week2timer5CloseTime"] = messageBytes[74]
			myTable["week2timer5SetTemperature"] = messageBytes[75]
			myTable["week2timer5ModeValue"] = messageBytes[76]
			myTable["week2timer6OpenTime"] = messageBytes[77]
			myTable["week2timer6CloseTime"] = messageBytes[78]
			myTable["week2timer6SetTemperature"] = messageBytes[79]
			myTable["week2timer6ModeValue"] = messageBytes[80]
			myTable["week3timer1OpenTime"] = messageBytes[81]
			myTable["week3timer1CloseTime"] = messageBytes[82]
			myTable["week3timer1SetTemperature"] = messageBytes[83]
			myTable["week3timer1ModeValue"] = messageBytes[84]
			myTable["week3timer2OpenTime"] = messageBytes[85]
			myTable["week3timer2CloseTime"] = messageBytes[86]
			myTable["week3timer2SetTemperature"] = messageBytes[87]
			myTable["week3timer2ModeValue"] = messageBytes[88]
			myTable["week3timer3OpenTime"] = messageBytes[89]
			myTable["week3timer3CloseTime"] = messageBytes[90]
			myTable["week3timer3SetTemperature"] = messageBytes[91]
			myTable["week3timer3ModeValue"] = messageBytes[92]
			myTable["week3timer4OpenTime"] = messageBytes[93]
			myTable["week3timer4CloseTime"] = messageBytes[94]
			myTable["week3timer4SetTemperature"] = messageBytes[95]
			myTable["week3timer4ModeValue"] = messageBytes[96]
			myTable["week3timer5OpenTime"] = messageBytes[97]
			myTable["week3timer5CloseTime"] = messageBytes[98]
			myTable["week3timer5SetTemperature"] = messageBytes[99]
			myTable["week3timer5ModeValue"] = messageBytes[100]
			myTable["week3timer6OpenTime"] = messageBytes[101]
			myTable["week3timer6CloseTime"] = messageBytes[102]
			myTable["week3timer6SetTemperature"] = messageBytes[103]
			myTable["week3timer6ModeValue"] = messageBytes[104]
			myTable["week4timer1OpenTime"] = messageBytes[105]
			myTable["week4timer1CloseTime"] = messageBytes[106]
			myTable["week4timer1SetTemperature"] = messageBytes[107]
			myTable["week4timer1ModeValue"] = messageBytes[108]
			myTable["week4timer2OpenTime"] = messageBytes[109]
			myTable["week4timer2CloseTime"] = messageBytes[110]
			myTable["week4timer2SetTemperature"] = messageBytes[111]
			myTable["week4timer2ModeValue"] = messageBytes[112]
			myTable["week4timer3OpenTime"] = messageBytes[113]
			myTable["week4timer3CloseTime"] = messageBytes[114]
			myTable["week4timer3SetTemperature"] = messageBytes[115]
			myTable["week4timer3ModeValue"] = messageBytes[116]
			myTable["week4timer4OpenTime"] = messageBytes[117]
			myTable["week4timer4CloseTime"] = messageBytes[118]
			myTable["week4timer4SetTemperature"] = messageBytes[119]
			myTable["week4timer4ModeValue"] = messageBytes[120]
			myTable["week4timer5OpenTime"] = messageBytes[121]
			myTable["week4timer5CloseTime"] = messageBytes[122]
			myTable["week4timer5SetTemperature"] = messageBytes[123]
			myTable["week4timer5ModeValue"] = messageBytes[124]
			myTable["week4timer6OpenTime"] = messageBytes[125]
			myTable["week4timer6CloseTime"] = messageBytes[126]
			myTable["week4timer6SetTemperature"] = messageBytes[127]
			myTable["week4timer6ModeValue"] = messageBytes[128]
			myTable["week5timer1OpenTime"] = messageBytes[129]
			myTable["week5timer1CloseTime"] = messageBytes[130]
			myTable["week5timer1SetTemperature"] = messageBytes[131]
			myTable["week5timer1ModeValue"] = messageBytes[132]
			myTable["week5timer2OpenTime"] = messageBytes[133]
			myTable["week5timer2CloseTime"] = messageBytes[134]
			myTable["week5timer2SetTemperature"] = messageBytes[135]
			myTable["week5timer2ModeValue"] = messageBytes[136]
			myTable["week5timer3OpenTime"] = messageBytes[137]
			myTable["week5timer3CloseTime"] = messageBytes[138]
			myTable["week5timer3SetTemperature"] = messageBytes[139]
			myTable["week5timer3ModeValue"] = messageBytes[140]
			myTable["week5timer4OpenTime"] = messageBytes[141]
			myTable["week5timer4CloseTime"] = messageBytes[142]
			myTable["week5timer4SetTemperature"] = messageBytes[143]
			myTable["week5timer4ModeValue"] = messageBytes[144]
			myTable["week5timer5OpenTime"] = messageBytes[145]
			myTable["week5timer5CloseTime"] = messageBytes[146]
			myTable["week5timer5SetTemperature"] = messageBytes[147]
			myTable["week5timer5ModeValue"] = messageBytes[148]
			myTable["week5timer6OpenTime"] = messageBytes[149]
			myTable["week5timer6CloseTime"] = messageBytes[150]
			myTable["week5timer6SetTemperature"] = messageBytes[151]
			myTable["week5timer6ModeValue"] = messageBytes[152]
			myTable["week6timer1OpenTime"] = messageBytes[153]
			myTable["week6timer1CloseTime"] = messageBytes[154]
			myTable["week6timer1SetTemperature"] = messageBytes[155]
			myTable["week6timer1ModeValue"] = messageBytes[156]
			myTable["week6timer2OpenTime"] = messageBytes[157]
			myTable["week6timer2CloseTime"] = messageBytes[158]
			myTable["week6timer2SetTemperature"] = messageBytes[159]
			myTable["week6timer2ModeValue"] = messageBytes[160]
			myTable["week6timer3OpenTime"] = messageBytes[161]
			myTable["week6timer3CloseTime"] = messageBytes[162]
			myTable["week6timer3SetTemperature"] = messageBytes[163]
			myTable["week6timer3ModeValue"] = messageBytes[164]
			myTable["week6timer4OpenTime"] = messageBytes[165]
			myTable["week6timer4CloseTime"] = messageBytes[166]
			myTable["week6timer4SetTemperature"] = messageBytes[167]
			myTable["week6timer4ModeValue"] = messageBytes[168]
			myTable["week6timer5OpenTime"] = messageBytes[169]
			myTable["week6timer5CloseTime"] = messageBytes[170]
			myTable["week6timer5SetTemperature"] = messageBytes[171]
			myTable["week6timer5ModeValue"] = messageBytes[172]
			myTable["week6timer6OpenTime"] = messageBytes[173]
			myTable["week6timer6CloseTime"] = messageBytes[174]
			myTable["week6timer6SetTemperature"] = messageBytes[175]
			myTable["week6timer6ModeValue"] = messageBytes[176]
		end
	end
end
function jsonToData(jsonCmd)
	if (# jsonCmd == 0) then
		return nil
	end
	local json = decode(jsonCmd)
	local deviceSubType = json["deviceinfo"]["deviceSubType"]
	if (deviceSubType == 1) then
	end
	local query = json["query"]
	local control = json["control"]
	local status = json["status"]
	local infoM = {}
	local bodyBytes = {}
	if (query) then
		if (query["query_type"] ~= nil) then
			if (string2Int(query["query_type"]) == 1) then
				bodyBytes[0] = 1
			elseif (string2Int(query["query_type"]) == 2) then
				bodyBytes[0] = 2
			elseif (string2Int(query["query_type"]) == 3) then
				bodyBytes[0] = 3
			end
		else
			bodyBytes[0] = 1
		end
		bodyBytes[1] = 1
		infoM = getTotalMsg(bodyBytes, BYTE_QUERYL_REQUEST)
	elseif (control) then
		if (status) then
			jsonToModel(status)
		end
		if (control) then
			jsonToModel(control)
		end
		if (myTable["controlType"] == 1) then
			for i = 0, 21 do
				bodyBytes[i] = 0
			end
			bodyBytes[0] = 1
			bodyBytes[1] = 1
			bodyBytes[2] = myTable["powerValue"]
			if control[KEY_MODE] ~= nil then
				bodyBytes[3] = myTable["modeValue"]
			else
				if (status["energy_mode"] ~= nil and status["energy_mode"] == VALUE_FUNCTION_ON) or myTable["energyMode"] == BYTE_POWER_ON then
					bodyBytes[3] = 1
				elseif (status["standard_mode"] ~= nil and status["standard_mode"] == VALUE_FUNCTION_ON) or myTable["standardMode"] == BYTE_POWER_ON then
					bodyBytes[3] = 2
				elseif (status["compatibilizing_mode"] ~= nil and status["compatibilizing_mode"] == VALUE_FUNCTION_ON) or myTable["compatibilizingMode"] == BYTE_POWER_ON then
					bodyBytes[3] = 3
				elseif (status["smart_mode"] ~= nil and status["smart_mode"] == VALUE_FUNCTION_ON) or myTable["smartMode"] == BYTE_POWER_ON then
					bodyBytes[3] = 4
				else
					bodyBytes[3] = myTable["modeValue"]
				end
			end
			bodyBytes[4] = myTable["tsValue"]
			bodyBytes[5] = myTable["trValue"]
			bodyBytes[6] = myTable["openPTC"]
			bodyBytes[7] = myTable["ptcTemp"]
			bodyBytes[8] = bit.bor(bit.band(myTable["vacationMode"], 16), bit.band(myTable["fahrenheitEffect"], 128))
			bodyBytes[9] = int2String(math.modf(myTable["vacadaysValue"] / 256))
			bodyBytes[10] = int2String(math.modf(myTable["vacadaysValue"] % 256))
			bodyBytes[11] = int2String(math.modf(myTable["dateYearValue"] / 100))
			bodyBytes[12] = int2String(math.modf(myTable["dateYearValue"] % 100))
			bodyBytes[13] = myTable["dateMonthValue"]
			bodyBytes[14] = myTable["dateDayValue"]
			bodyBytes[15] = myTable["dateWeekValue"]
			bodyBytes[16] = myTable["dateHourValue"]
			bodyBytes[17] = myTable["dateMinuteValue"]
			bodyBytes[18] = myTable["vacadaysStartYearValue"]
			bodyBytes[19] = myTable["vacadaysStartMonthValue"]
			bodyBytes[20] = myTable["vacadaysStartDayValue"]
			bodyBytes[21] = myTable["vacationTsValue"]
			infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
		elseif (myTable["controlType"] == 2) then
			for i = 0, 39 do
				bodyBytes[i] = 0
			end
			bodyBytes[0] = 2
			bodyBytes[1] = 1
			bodyBytes[2] = 6
			bodyBytes[3] = bit.bor(bit.band(myTable["timer1Effect"], 1), bit.band(myTable["timer2Effect"], 2), bit.band(myTable["timer3Effect"], 4), bit.band(myTable["timer4Effect"], 8), bit.band(myTable["timer5Effect"], 16), bit.band(myTable["timer6Effect"], 32))
			bodyBytes[4] = myTable["timer1OpenHour"];
			bodyBytes[5] = myTable["timer1OpenMin"];
			bodyBytes[6] = myTable["timer1CloseHour"];
			bodyBytes[7] = myTable["timer1CloseMin"];
			bodyBytes[8] = myTable["timer1SetTemperature"];
			bodyBytes[9] = myTable["timer1ModeValue"];
			bodyBytes[10] = myTable["timer2OpenHour"];
			bodyBytes[11] = myTable["timer2OpenMin"];
			bodyBytes[12] = myTable["timer2CloseHour"];
			bodyBytes[13] = myTable["timer2CloseMin"];
			bodyBytes[14] = myTable["timer2SetTemperature"];
			bodyBytes[15] = myTable["timer2ModeValue"];
			bodyBytes[16] = myTable["timer3OpenHour"];
			bodyBytes[17] = myTable["timer3OpenMin"];
			bodyBytes[18] = myTable["timer3CloseHour"];
			bodyBytes[19] = myTable["timer3CloseMin"];
			bodyBytes[20] = myTable["timer3SetTemperature"];
			bodyBytes[21] = myTable["timer3ModeValue"];
			bodyBytes[22] = myTable["timer4OpenHour"];
			bodyBytes[23] = myTable["timer4OpenMin"];
			bodyBytes[24] = myTable["timer4CloseHour"];
			bodyBytes[25] = myTable["timer4CloseMin"];
			bodyBytes[26] = myTable["timer4SetTemperature"];
			bodyBytes[27] = myTable["timer4ModeValue"];
			bodyBytes[28] = myTable["timer5OpenHour"];
			bodyBytes[29] = myTable["timer5OpenMin"];
			bodyBytes[30] = myTable["timer5CloseHour"];
			bodyBytes[31] = myTable["timer5CloseMin"];
			bodyBytes[32] = myTable["timer5SetTemperature"];
			bodyBytes[33] = myTable["timer5ModeValue"];
			bodyBytes[34] = myTable["timer6OpenHour"];
			bodyBytes[35] = myTable["timer6OpenMin"];
			bodyBytes[36] = myTable["timer6CloseHour"];
			bodyBytes[37] = myTable["timer6CloseMin"];
			bodyBytes[38] = myTable["timer6SetTemperature"];
			bodyBytes[39] = myTable["timer6ModeValue"];
			infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
		elseif (myTable["controlType"] == 3) then
			for i = 0, 13 do
				bodyBytes[i] = 0
			end
			bodyBytes[0] = 3
			bodyBytes[1] = 1
			bodyBytes[2] = myTable["order1Effect"]
			bodyBytes[3] = int2String(myTable["order1Temp"])
			bodyBytes[4] = myTable["order1TimeHour"]
			bodyBytes[5] = myTable["order1TimeMin"]
			bodyBytes[6] = myTable["order2Effect"]
			bodyBytes[7] = int2String(myTable["order2Temp"])
			bodyBytes[8] = myTable["order2TimeHour"]
			bodyBytes[9] = myTable["order2TimeMin"]
			bodyBytes[10] = myTable["order1StopTimeHour"]
			bodyBytes[11] = myTable["order1StopTimeMin"]
			bodyBytes[12] = myTable["order2StopTimeHour"]
			bodyBytes[13] = myTable["order2StopTimeMin"]
			infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
		elseif (myTable["controlType"] == 5) then
			for i = 0, 2 do
				bodyBytes[i] = 0
			end
			bodyBytes[0] = 5
			bodyBytes[1] = 1
			bodyBytes[2] = myTable["backwaterEffect"]
			infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
		elseif (myTable["controlType"] == 6) then
			for i = 0, 2 do
				bodyBytes[i] = 0
			end
			bodyBytes[0] = 6
			bodyBytes[1] = 1
			bodyBytes[2] = myTable["sterilizeEffect"]
			bodyBytes[3] = myTable["autoSterilizeWeek"]
			bodyBytes[4] = myTable["autoSterilizeHour"]
			bodyBytes[5] = myTable["autoSterilizeMinute"]
			infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
		elseif (myTable["controlType"] == 7) then
			for i = 0, 176 do
				bodyBytes[i] = 0
			end
			bodyBytes[0] = 7
			bodyBytes[1] = 1
			bodyBytes[2] = bit.bor(bit.band(myTable["week0timer1Effect"], 1), bit.band(myTable["week0timer2Effect"], 2), bit.band(myTable["week0timer3Effect"], 4), bit.band(myTable["week0timer4Effect"], 8), bit.band(myTable["week0timer5Effect"], 16), bit.band(myTable["week0timer6Effect"], 32))
			bodyBytes[3] = bit.bor(bit.band(myTable["week1timer1Effect"], 1), bit.band(myTable["week1timer2Effect"], 2), bit.band(myTable["week1timer3Effect"], 4), bit.band(myTable["week1timer4Effect"], 8), bit.band(myTable["week1timer5Effect"], 16), bit.band(myTable["week1timer6Effect"], 32))
			bodyBytes[4] = bit.bor(bit.band(myTable["week2timer1Effect"], 1), bit.band(myTable["week2timer2Effect"], 2), bit.band(myTable["week2timer3Effect"], 4), bit.band(myTable["week2timer4Effect"], 8), bit.band(myTable["week2timer5Effect"], 16), bit.band(myTable["week2timer6Effect"], 32))
			bodyBytes[5] = bit.bor(bit.band(myTable["week3timer1Effect"], 1), bit.band(myTable["week3timer2Effect"], 2), bit.band(myTable["week3timer3Effect"], 4), bit.band(myTable["week3timer4Effect"], 8), bit.band(myTable["week3timer5Effect"], 16), bit.band(myTable["week3timer6Effect"], 32))
			bodyBytes[6] = bit.bor(bit.band(myTable["week4timer1Effect"], 1), bit.band(myTable["week4timer2Effect"], 2), bit.band(myTable["week4timer3Effect"], 4), bit.band(myTable["week4timer4Effect"], 8), bit.band(myTable["week4timer5Effect"], 16), bit.band(myTable["week4timer6Effect"], 32))
			bodyBytes[7] = bit.bor(bit.band(myTable["week5timer1Effect"], 1), bit.band(myTable["week5timer2Effect"], 2), bit.band(myTable["week5timer3Effect"], 4), bit.band(myTable["week5timer4Effect"], 8), bit.band(myTable["week5timer5Effect"], 16), bit.band(myTable["week5timer6Effect"], 32))
			bodyBytes[8] = bit.bor(bit.band(myTable["week6timer1Effect"], 1), bit.band(myTable["week6timer2Effect"], 2), bit.band(myTable["week6timer3Effect"], 4), bit.band(myTable["week6timer4Effect"], 8), bit.band(myTable["week6timer5Effect"], 16), bit.band(myTable["week6timer6Effect"], 32))
			bodyBytes[9] = myTable["week0timer1OpenTime"]
			bodyBytes[10] = myTable["week0timer1CloseTime"]
			bodyBytes[11] = myTable["week0timer1SetTemperature"]
			bodyBytes[12] = myTable["week0timer1ModeValue"]
			bodyBytes[13] = myTable["week0timer2OpenTime"]
			bodyBytes[14] = myTable["week0timer2CloseTime"]
			bodyBytes[15] = myTable["week0timer2SetTemperature"]
			bodyBytes[16] = myTable["week0timer2ModeValue"]
			bodyBytes[17] = myTable["week0timer3OpenTime"]
			bodyBytes[18] = myTable["week0timer3CloseTime"]
			bodyBytes[19] = myTable["week0timer3SetTemperature"]
			bodyBytes[20] = myTable["week0timer3ModeValue"]
			bodyBytes[21] = myTable["week0timer4OpenTime"]
			bodyBytes[22] = myTable["week0timer4CloseTime"]
			bodyBytes[23] = myTable["week0timer4SetTemperature"]
			bodyBytes[24] = myTable["week0timer4ModeValue"]
			bodyBytes[25] = myTable["week0timer5OpenTime"]
			bodyBytes[26] = myTable["week0timer5CloseTime"]
			bodyBytes[27] = myTable["week0timer5SetTemperature"]
			bodyBytes[28] = myTable["week0timer5ModeValue"]
			bodyBytes[29] = myTable["week0timer6OpenTime"]
			bodyBytes[30] = myTable["week0timer6CloseTime"]
			bodyBytes[31] = myTable["week0timer6SetTemperature"]
			bodyBytes[32] = myTable["week0timer6ModeValue"]
			bodyBytes[33] = myTable["week1timer1OpenTime"]
			bodyBytes[34] = myTable["week1timer1CloseTime"]
			bodyBytes[35] = myTable["week1timer1SetTemperature"]
			bodyBytes[36] = myTable["week1timer1ModeValue"]
			bodyBytes[37] = myTable["week1timer2OpenTime"]
			bodyBytes[38] = myTable["week1timer2CloseTime"]
			bodyBytes[39] = myTable["week1timer2SetTemperature"]
			bodyBytes[40] = myTable["week1timer2ModeValue"]
			bodyBytes[41] = myTable["week1timer3OpenTime"]
			bodyBytes[42] = myTable["week1timer3CloseTime"]
			bodyBytes[43] = myTable["week1timer3SetTemperature"]
			bodyBytes[44] = myTable["week1timer3ModeValue"]
			bodyBytes[45] = myTable["week1timer4OpenTime"]
			bodyBytes[46] = myTable["week1timer4CloseTime"]
			bodyBytes[47] = myTable["week1timer4SetTemperature"]
			bodyBytes[48] = myTable["week1timer4ModeValue"]
			bodyBytes[49] = myTable["week1timer5OpenTime"]
			bodyBytes[50] = myTable["week1timer5CloseTime"]
			bodyBytes[51] = myTable["week1timer5SetTemperature"]
			bodyBytes[52] = myTable["week1timer5ModeValue"]
			bodyBytes[53] = myTable["week1timer6OpenTime"]
			bodyBytes[54] = myTable["week1timer6CloseTime"]
			bodyBytes[55] = myTable["week1timer6SetTemperature"]
			bodyBytes[56] = myTable["week1timer6ModeValue"]
			bodyBytes[57] = myTable["week2timer1OpenTime"]
			bodyBytes[58] = myTable["week2timer1CloseTime"]
			bodyBytes[59] = myTable["week2timer1SetTemperature"]
			bodyBytes[60] = myTable["week2timer1ModeValue"]
			bodyBytes[61] = myTable["week2timer2OpenTime"]
			bodyBytes[62] = myTable["week2timer2CloseTime"]
			bodyBytes[63] = myTable["week2timer2SetTemperature"]
			bodyBytes[64] = myTable["week2timer2ModeValue"]
			bodyBytes[65] = myTable["week2timer3OpenTime"]
			bodyBytes[66] = myTable["week2timer3CloseTime"]
			bodyBytes[67] = myTable["week2timer3SetTemperature"]
			bodyBytes[68] = myTable["week2timer3ModeValue"]
			bodyBytes[69] = myTable["week2timer4OpenTime"]
			bodyBytes[70] = myTable["week2timer4CloseTime"]
			bodyBytes[71] = myTable["week2timer4SetTemperature"]
			bodyBytes[72] = myTable["week2timer4ModeValue"]
			bodyBytes[73] = myTable["week2timer5OpenTime"]
			bodyBytes[74] = myTable["week2timer5CloseTime"]
			bodyBytes[75] = myTable["week2timer5SetTemperature"]
			bodyBytes[76] = myTable["week2timer5ModeValue"]
			bodyBytes[77] = myTable["week2timer6OpenTime"]
			bodyBytes[78] = myTable["week2timer6CloseTime"]
			bodyBytes[79] = myTable["week2timer6SetTemperature"]
			bodyBytes[80] = myTable["week2timer6ModeValue"]
			bodyBytes[81] = myTable["week3timer1OpenTime"]
			bodyBytes[82] = myTable["week3timer1CloseTime"]
			bodyBytes[83] = myTable["week3timer1SetTemperature"]
			bodyBytes[84] = myTable["week3timer1ModeValue"]
			bodyBytes[85] = myTable["week3timer2OpenTime"]
			bodyBytes[86] = myTable["week3timer2CloseTime"]
			bodyBytes[87] = myTable["week3timer2SetTemperature"]
			bodyBytes[88] = myTable["week3timer2ModeValue"]
			bodyBytes[89] = myTable["week3timer3OpenTime"]
			bodyBytes[90] = myTable["week3timer3CloseTime"]
			bodyBytes[91] = myTable["week3timer3SetTemperature"]
			bodyBytes[92] = myTable["week3timer3ModeValue"]
			bodyBytes[93] = myTable["week3timer4OpenTime"]
			bodyBytes[94] = myTable["week3timer4CloseTime"]
			bodyBytes[95] = myTable["week3timer4SetTemperature"]
			bodyBytes[96] = myTable["week3timer4ModeValue"]
			bodyBytes[97] = myTable["week3timer5OpenTime"]
			bodyBytes[98] = myTable["week3timer5CloseTime"]
			bodyBytes[99] = myTable["week3timer5SetTemperature"]
			bodyBytes[100] = myTable["week3timer5ModeValue"]
			bodyBytes[101] = myTable["week3timer6OpenTime"]
			bodyBytes[102] = myTable["week3timer6CloseTime"]
			bodyBytes[103] = myTable["week3timer6SetTemperature"]
			bodyBytes[104] = myTable["week3timer6ModeValue"]
			bodyBytes[105] = myTable["week4timer1OpenTime"]
			bodyBytes[106] = myTable["week4timer1CloseTime"]
			bodyBytes[107] = myTable["week4timer1SetTemperature"]
			bodyBytes[108] = myTable["week4timer1ModeValue"]
			bodyBytes[109] = myTable["week4timer2OpenTime"]
			bodyBytes[110] = myTable["week4timer2CloseTime"]
			bodyBytes[111] = myTable["week4timer2SetTemperature"]
			bodyBytes[112] = myTable["week4timer2ModeValue"]
			bodyBytes[113] = myTable["week4timer3OpenTime"]
			bodyBytes[114] = myTable["week4timer3CloseTime"]
			bodyBytes[115] = myTable["week4timer3SetTemperature"]
			bodyBytes[116] = myTable["week4timer3ModeValue"]
			bodyBytes[117] = myTable["week4timer4OpenTime"]
			bodyBytes[118] = myTable["week4timer4CloseTime"]
			bodyBytes[119] = myTable["week4timer4SetTemperature"]
			bodyBytes[120] = myTable["week4timer4ModeValue"]
			bodyBytes[121] = myTable["week4timer5OpenTime"]
			bodyBytes[122] = myTable["week4timer5CloseTime"]
			bodyBytes[123] = myTable["week4timer5SetTemperature"]
			bodyBytes[124] = myTable["week4timer5ModeValue"]
			bodyBytes[125] = myTable["week4timer6OpenTime"]
			bodyBytes[126] = myTable["week4timer6CloseTime"]
			bodyBytes[127] = myTable["week4timer6SetTemperature"]
			bodyBytes[128] = myTable["week4timer6ModeValue"]
			bodyBytes[129] = myTable["week5timer1OpenTime"]
			bodyBytes[130] = myTable["week5timer1CloseTime"]
			bodyBytes[131] = myTable["week5timer1SetTemperature"]
			bodyBytes[132] = myTable["week5timer1ModeValue"]
			bodyBytes[133] = myTable["week5timer2OpenTime"]
			bodyBytes[134] = myTable["week5timer2CloseTime"]
			bodyBytes[135] = myTable["week5timer2SetTemperature"]
			bodyBytes[136] = myTable["week5timer2ModeValue"]
			bodyBytes[137] = myTable["week5timer3OpenTime"]
			bodyBytes[138] = myTable["week5timer3CloseTime"]
			bodyBytes[139] = myTable["week5timer3SetTemperature"]
			bodyBytes[140] = myTable["week5timer3ModeValue"]
			bodyBytes[141] = myTable["week5timer4OpenTime"]
			bodyBytes[142] = myTable["week5timer4CloseTime"]
			bodyBytes[143] = myTable["week5timer4SetTemperature"]
			bodyBytes[144] = myTable["week5timer4ModeValue"]
			bodyBytes[145] = myTable["week5timer5OpenTime"]
			bodyBytes[146] = myTable["week5timer5CloseTime"]
			bodyBytes[147] = myTable["week5timer5SetTemperature"]
			bodyBytes[148] = myTable["week5timer5ModeValue"]
			bodyBytes[149] = myTable["week5timer6OpenTime"]
			bodyBytes[150] = myTable["week5timer6CloseTime"]
			bodyBytes[151] = myTable["week5timer6SetTemperature"]
			bodyBytes[152] = myTable["week5timer6ModeValue"]
			bodyBytes[153] = myTable["week6timer1OpenTime"]
			bodyBytes[154] = myTable["week6timer1CloseTime"]
			bodyBytes[155] = myTable["week6timer1SetTemperature"]
			bodyBytes[156] = myTable["week6timer1ModeValue"]
			bodyBytes[157] = myTable["week6timer2OpenTime"]
			bodyBytes[158] = myTable["week6timer2CloseTime"]
			bodyBytes[159] = myTable["week6timer2SetTemperature"]
			bodyBytes[160] = myTable["week6timer2ModeValue"]
			bodyBytes[161] = myTable["week6timer3OpenTime"]
			bodyBytes[162] = myTable["week6timer3CloseTime"]
			bodyBytes[163] = myTable["week6timer3SetTemperature"]
			bodyBytes[164] = myTable["week6timer3ModeValue"]
			bodyBytes[165] = myTable["week6timer4OpenTime"]
			bodyBytes[166] = myTable["week6timer4CloseTime"]
			bodyBytes[167] = myTable["week6timer4SetTemperature"]
			bodyBytes[168] = myTable["week6timer4ModeValue"]
			bodyBytes[169] = myTable["week6timer5OpenTime"]
			bodyBytes[170] = myTable["week6timer5CloseTime"]
			bodyBytes[171] = myTable["week6timer5SetTemperature"]
			bodyBytes[172] = myTable["week6timer5ModeValue"]
			bodyBytes[173] = myTable["week6timer6OpenTime"]
			bodyBytes[174] = myTable["week6timer6CloseTime"]
			bodyBytes[175] = myTable["week6timer6SetTemperature"]
			bodyBytes[176] = myTable["week6timer6ModeValue"]
			infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
		end
	end
	local ret = table2string(infoM)
	ret = string2hexstring(ret)
	return ret
end
function dataToJson(jsonCmd)
	if (not jsonCmd) then
		return nil
	end
	local json = decode(jsonCmd)
	local deviceinfo = json["deviceinfo"]
	local deviceSubType = deviceinfo["deviceSubType"]
	if (deviceSubType == 1) then
	end
	local binData = json["msg"]["data"]
	local info = {}
	local msgBytes = {}
	local bodyBytes = {}
	local msgLength = 0
	local bodyLength = 0
	local msgSubType = 0
	info = string2table(binData)
	if (# info < 11) then
		return nil
	end
	for i = 1, # info do
		msgBytes[i - 1] = info[i]
	end
	msgLength = msgBytes[1]
	bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
	myTable["dataType"] = msgBytes[9]
	msgSubType = msgBytes[10]
	local sumRes = makeSum(msgBytes, 1, msgLength - 1)
	if (sumRes ~= msgBytes[msgLength]) then
	end
	local streams = {}
	streams[KEY_VERSION] = VALUE_VERSION
	for i = 0, bodyLength do
		bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
	end
	binToModel(bodyBytes)
	if (((myTable["dataType"] == BYTE_AUTO_REPORT) and (msgSubType == 1)) or ((myTable["dataType"] == BYTE_QUERYL_REQUEST) and (msgSubType == 1))) then
		if (myTable["powerValue"] == BYTE_POWER_ON) then
			streams[KEY_POWER] = VALUE_FUNCTION_ON
		elseif (myTable["powerValue"] == BYTE_POWER_OFF) then
			streams[KEY_POWER] = VALUE_FUNCTION_OFF
		end
		if (myTable["energyMode"] == BYTE_POWER_ON) then
			streams["energy_mode"] = VALUE_FUNCTION_ON
			streams[KEY_MODE] = "energy"
		elseif (myTable["energyMode"] == BYTE_POWER_OFF) then
			streams["energy_mode"] = VALUE_FUNCTION_OFF
		end
		if (myTable["standardMode"] == BYTE_POWER_ON) then
			streams["standard_mode"] = VALUE_FUNCTION_ON
			streams[KEY_MODE] = "standard"
		elseif (myTable["standardMode"] == BYTE_POWER_OFF) then
			streams["standard_mode"] = VALUE_FUNCTION_OFF
		end
		if (myTable["compatibilizingMode"] == BYTE_POWER_ON) then
			streams["compatibilizing_mode"] = VALUE_FUNCTION_ON
			streams[KEY_MODE] = "compatibilizing"
		elseif (myTable["compatibilizingMode"] == BYTE_POWER_OFF) then
			streams["compatibilizing_mode"] = VALUE_FUNCTION_OFF
		end
		if (myTable["heatValue"] == BYTE_POWER_ON) then
			streams["high_heat"] = VALUE_FUNCTION_ON
		elseif (myTable["heatValue"] == BYTE_POWER_OFF) then
			streams["high_heat"] = VALUE_FUNCTION_OFF
		end
		if (myTable["dicaryonHeat"] == BYTE_POWER_ON) then
			streams["dicaryon_heat"] = VALUE_FUNCTION_ON
		elseif (myTable["dicaryonHeat"] == BYTE_POWER_OFF) then
			streams["dicaryon_heat"] = VALUE_FUNCTION_OFF
		end
		if (myTable["eco"] == BYTE_POWER_ON) then
			streams["eco"] = VALUE_FUNCTION_ON
		elseif (myTable["eco"] == BYTE_POWER_OFF) then
			streams["eco"] = VALUE_FUNCTION_OFF
		end
		if (myTable["vacationMode"] == 16) then
			streams["vacation"] = VALUE_FUNCTION_ON
		elseif (myTable["vacationMode"] == 0) then
			streams["vacation"] = VALUE_FUNCTION_OFF
		end
		if (myTable["fahrenheitEffect"] == 128) then
			streams["fahrenheit_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["fahrenheitEffect"] == 0) then
			streams["fahrenheit_effect"] = VALUE_FUNCTION_OFF
		end
		streams["set_temperature"] = int2String(myTable["tsValue"])
		streams["water_box_temperature"] = int2String(myTable["washBoxTemp"])
		streams["water_box_top_temperature"] = int2String(myTable["boxTopTemp"])
		streams["water_box_bottom_temperature"] = int2String(myTable["boxBottomTemp"])
		streams["condensator_temperature"] = int2String(myTable["t3Value"])
		streams["outdoor_temperature"] = int2String(myTable["t4Value"])
		streams["compressor_top_temperature"] = int2String(myTable["compressorTopTemp"])
		streams["set_temperature_max"] = int2String(myTable["tsMaxValue"])
		streams["set_temperature_min"] = int2String(myTable["tsMinValue"])
		streams[KEY_ERROR_CODE] = int2String(myTable["errorCode"])
		streams["set_vacationdays"] = int2String(myTable["vacadaysValue"])
		streams["set_vacation_start_year"] = int2String(myTable["vacadaysStartYearValue"])
		streams["set_vacation_start_month"] = int2String(myTable["vacadaysStartMonthValue"])
		streams["set_vacation_start_day"] = int2String(myTable["vacadaysStartDayValue"])
		streams["set_vacation_temperature"] = int2String(myTable["vacationTsValue"])
		if (myTable["smartGrid"] == 2) then
			streams["smart_grid"] = VALUE_FUNCTION_ON
		elseif (myTable["smartGrid"] == BYTE_POWER_OFF) then
			streams["smart_grid"] = VALUE_FUNCTION_OFF
		end
		if (myTable["multiTerminal"] == 4) then
			streams["multi_terminal"] = VALUE_FUNCTION_ON
		elseif (myTable["multiTerminal"] == BYTE_POWER_OFF) then
			streams["multi_terminal"] = VALUE_FUNCTION_OFF
		end
		if (myTable["bottomElecHeat"] == BYTE_POWER_ON) then
			streams["bottom_elec_heat"] = VALUE_FUNCTION_ON
		elseif (myTable["bottomElecHeat"] == BYTE_POWER_OFF) then
			streams["bottom_elec_heat"] = VALUE_FUNCTION_OFF
		end
		if (myTable["topElecHeat"] == BYTE_POWER_ON) then
			streams["top_elec_heat"] = VALUE_FUNCTION_ON
		elseif (myTable["topElecHeat"] == BYTE_POWER_OFF) then
			streams["top_elec_heat"] = VALUE_FUNCTION_OFF
		end
		if (myTable["waterPump"] == BYTE_POWER_ON) then
			streams["water_pump"] = VALUE_FUNCTION_ON
		elseif (myTable["waterPump"] == BYTE_POWER_OFF) then
			streams["water_pump"] = VALUE_FUNCTION_OFF
		end
		if (myTable["compressor"] == BYTE_POWER_ON) then
			streams["compressor"] = VALUE_FUNCTION_ON
		elseif (myTable["compressor"] == BYTE_POWER_OFF) then
			streams["compressor"] = VALUE_FUNCTION_OFF
		end
		if (myTable["middleWind"] == BYTE_POWER_ON) then
			streams["middle_wind"] = VALUE_FUNCTION_ON
		elseif (myTable["middleWind"] == BYTE_POWER_OFF) then
			streams["middle_wind"] = VALUE_FUNCTION_OFF
		end
		if (myTable["fourWayValve"] == BYTE_POWER_ON) then
			streams["four_way_valve"] = VALUE_FUNCTION_ON
		elseif (myTable["fourWayValve"] == BYTE_POWER_OFF) then
			streams["four_way_valve"] = VALUE_FUNCTION_OFF
		end
		if (myTable["lowWind"] == BYTE_POWER_ON) then
			streams["low_wind"] = VALUE_FUNCTION_ON
		elseif (myTable["lowWind"] == BYTE_POWER_OFF) then
			streams["low_wind"] = VALUE_FUNCTION_OFF
		end
		if (myTable["highWind"] == BYTE_POWER_ON) then
			streams["high_wind"] = VALUE_FUNCTION_ON
		elseif (myTable["highWind"] == BYTE_POWER_OFF) then
			streams["high_wind"] = VALUE_FUNCTION_OFF
		end
		streams["type_info"] = int2String(myTable["typeInfo"])
		if (myTable["smartMode"] == BYTE_POWER_ON) then
			streams["smart_mode"] = VALUE_FUNCTION_ON
		elseif (myTable["smartMode"] == BYTE_POWER_OFF) then
			streams["smart_mode"] = VALUE_FUNCTION_OFF
		end
		if (myTable["backwaterEffect"] == BYTE_POWER_ON) then
			streams["backwater_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["backwaterEffect"] == BYTE_POWER_OFF) then
			streams["backwater_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["sterilizeEffect"] == 128) then
			streams["sterilize_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["sterilizeEffect"] == BYTE_POWER_OFF) then
			streams["sterilize_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["order1Effect"] == BYTE_POWER_ON) then
			streams["order1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["order1Effect"] == BYTE_POWER_OFF) then
			streams["order1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["order2Effect"] == BYTE_POWER_ON) then
			streams["order2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["order2Effect"] == BYTE_POWER_OFF) then
			streams["order2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer1Effect"] == 1) then
			streams["week0timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer1Effect"] == 0) then
			streams["week0timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer2Effect"] == 2) then
			streams["week0timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer2Effect"] == BYTE_POWER_OFF) then
			streams["week0timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer3Effect"] == 4) then
			streams["week0timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer3Effect"] == BYTE_POWER_OFF) then
			streams["week0timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer4Effect"] == 128) then
			streams["week0timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer4Effect"] == BYTE_POWER_OFF) then
			streams["week0timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer5Effect"] == 16) then
			streams["week0timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer5Effect"] == BYTE_POWER_OFF) then
			streams["week0timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer6Effect"] == 32) then
			streams["week0timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer6Effect"] == BYTE_POWER_OFF) then
			streams["week0timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer1Effect"] == 1) then
			streams["week1timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer1Effect"] == BYTE_POWER_OFF) then
			streams["week1timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer2Effect"] == 2) then
			streams["week1timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer2Effect"] == BYTE_POWER_OFF) then
			streams["week1timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer3Effect"] == 4) then
			streams["week1timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer3Effect"] == BYTE_POWER_OFF) then
			streams["week1timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer4Effect"] == 8) then
			streams["week1timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer4Effect"] == BYTE_POWER_OFF) then
			streams["week1timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer5Effect"] == 16) then
			streams["week1timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer5Effect"] == BYTE_POWER_OFF) then
			streams["week1timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer6Effect"] == 32) then
			streams["week1timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer6Effect"] == BYTE_POWER_OFF) then
			streams["week1timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer1Effect"] == 1) then
			streams["week2timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer1Effect"] == BYTE_POWER_OFF) then
			streams["week2timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer2Effect"] == 2) then
			streams["week2timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer2Effect"] == BYTE_POWER_OFF) then
			streams["week2timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer3Effect"] == 4) then
			streams["week2timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer3Effect"] == BYTE_POWER_OFF) then
			streams["week2timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer4Effect"] == 8) then
			streams["week2timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer4Effect"] == BYTE_POWER_OFF) then
			streams["week2timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer5Effect"] == 16) then
			streams["week2timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer5Effect"] == BYTE_POWER_OFF) then
			streams["week2timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer6Effect"] == 32) then
			streams["week2timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer6Effect"] == BYTE_POWER_OFF) then
			streams["week2timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer1Effect"] == 1) then
			streams["week3timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer1Effect"] == BYTE_POWER_OFF) then
			streams["week3timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer2Effect"] == 2) then
			streams["week3timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer2Effect"] == BYTE_POWER_OFF) then
			streams["week3timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer3Effect"] == 4) then
			streams["week3timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer3Effect"] == BYTE_POWER_OFF) then
			streams["week3timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer4Effect"] == 8) then
			streams["week3timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer4Effect"] == BYTE_POWER_OFF) then
			streams["week3timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer5Effect"] == 16) then
			streams["week3timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer5Effect"] == BYTE_POWER_OFF) then
			streams["week3timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer6Effect"] == 32) then
			streams["week3timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer6Effect"] == BYTE_POWER_OFF) then
			streams["week3timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer1Effect"] == 1) then
			streams["week4timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer1Effect"] == BYTE_POWER_OFF) then
			streams["week4timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer2Effect"] == 2) then
			streams["week4timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer2Effect"] == BYTE_POWER_OFF) then
			streams["week4timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer3Effect"] == 4) then
			streams["week4timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer3Effect"] == BYTE_POWER_OFF) then
			streams["week4timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer4Effect"] == 8) then
			streams["week4timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer4Effect"] == BYTE_POWER_OFF) then
			streams["week4timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer5Effect"] == 16) then
			streams["week4timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer5Effect"] == BYTE_POWER_OFF) then
			streams["week4timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer6Effect"] == 32) then
			streams["week4timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer6Effect"] == BYTE_POWER_OFF) then
			streams["week4timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer1Effect"] == 1) then
			streams["week5timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer1Effect"] == BYTE_POWER_OFF) then
			streams["week5timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer2Effect"] == 2) then
			streams["week5timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer2Effect"] == BYTE_POWER_OFF) then
			streams["week5timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer3Effect"] == 4) then
			streams["week5timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer3Effect"] == BYTE_POWER_OFF) then
			streams["week5timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer4Effect"] == 8) then
			streams["week5timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer4Effect"] == BYTE_POWER_OFF) then
			streams["week5timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer5Effect"] == 16) then
			streams["week5timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer5Effect"] == BYTE_POWER_OFF) then
			streams["week5timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer6Effect"] == 32) then
			streams["week5timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer6Effect"] == BYTE_POWER_OFF) then
			streams["week5timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer1Effect"] == 1) then
			streams["week6timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer1Effect"] == BYTE_POWER_OFF) then
			streams["week6timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer2Effect"] == 2) then
			streams["week6timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer2Effect"] == BYTE_POWER_OFF) then
			streams["week6timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer3Effect"] == 4) then
			streams["week6timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer3Effect"] == BYTE_POWER_OFF) then
			streams["week6timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer4Effect"] == 8) then
			streams["week6timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer4Effect"] == BYTE_POWER_OFF) then
			streams["week6timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer5Effect"] == 16) then
			streams["week6timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer5Effect"] == BYTE_POWER_OFF) then
			streams["week6timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer6Effect"] == 32) then
			streams["week6timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer6Effect"] == BYTE_POWER_OFF) then
			streams["week6timer6_effect"] = VALUE_FUNCTION_OFF
		end
		streams["timer1_openHour"] = int2String(myTable["timer1OpenHour"])
		streams["timer1_openhour"] = int2String(myTable["timer1OpenHour"])
		streams["timer1_openMin"] = int2String(myTable["timer1OpenMin"])
		streams["timer1_openmin"] = int2String(myTable["timer1OpenMin"])
		streams["timer1_closeHour"] = int2String(myTable["timer1CloseHour"])
		streams["timer1_closehour"] = int2String(myTable["timer1CloseHour"])
		streams["timer1_closeMin"] = int2String(myTable["timer1CloseMin"])
		streams["timer1_closemin"] = int2String(myTable["timer1CloseMin"])
		streams["timer2_openHour"] = int2String(myTable["timer2OpenHour"])
		streams["timer2_openhour"] = int2String(myTable["timer2OpenHour"])
		streams["timer2_openMin"] = int2String(myTable["timer2OpenMin"])
		streams["timer2_openmin"] = int2String(myTable["timer2OpenMin"])
		streams["timer2_closeHour"] = int2String(myTable["timer2CloseHour"])
		streams["timer2_closehour"] = int2String(myTable["timer2CloseHour"])
		streams["timer2_closeMin"] = int2String(myTable["timer2CloseMin"])
		streams["timer2_closemin"] = int2String(myTable["timer2CloseMin"])
		streams["order1_temp"] = int2String(myTable["order1Temp"])
		streams["order1_timeHour"] = int2String(myTable["order1TimeHour"])
		streams["order1_timehour"] = int2String(myTable["order1TimeHour"])
		streams["order1_timeMin"] = int2String(myTable["order1TimeMin"])
		streams["order1_timemin"] = int2String(myTable["order1TimeMin"])
		streams["order1_stoptimeHour"] = int2String(myTable["order1StopTimeHour"])
		streams["order1_stoptimehour"] = int2String(myTable["order1StopTimeHour"])
		streams["order1_stoptimeMin"] = int2String(myTable["order1StopTimeMin"])
		streams["order1_stoptimemin"] = int2String(myTable["order1StopTimeMin"])
		streams["order2_temp"] = int2String(myTable["order2Temp"])
		streams["order2_timeHour"] = int2String(myTable["order2TimeHour"])
		streams["order2_timehour"] = int2String(myTable["order2TimeHour"])
		streams["order2_timeMin"] = int2String(myTable["order2TimeMin"])
		streams["order2_timemin"] = int2String(myTable["order2TimeMin"])
		streams["order2_stoptimeHour"] = int2String(myTable["order2StopTimeHour"])
		streams["order2_stoptimehour"] = int2String(myTable["order2StopTimeHour"])
		streams["order2_stoptimeMin"] = int2String(myTable["order2StopTimeMin"])
		streams["order2_stoptimemin"] = int2String(myTable["order2StopTimeMin"])
		streams["hotwater_level"] = int2String(myTable["hotWater"])
		streams["elec_heat_support"] = int2String(myTable["elecHeatSupport"])
		streams["auto_sterilize_week"] = int2String(myTable["autoSterilizeWeek"])
		streams["auto_sterilize_hour"] = int2String(myTable["autoSterilizeHour"])
		streams["auto_sterilize_minute"] = int2String(myTable["autoSterilizeMinute"])
	elseif (((myTable["dataType"] == BYTE_AUTO_REPORT) and (msgSubType == 2)) or ((myTable["dataType"] == BYTE_QUERYL_REQUEST) and (msgSubType == 2))) then
		if (myTable["week0timer1Effect"] == 1) then
			streams["week0timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer1Effect"] == BYTE_POWER_OFF) then
			streams["week0timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer2Effect"] == 2) then
			streams["week0timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer2Effect"] == BYTE_POWER_OFF) then
			streams["week0timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer3Effect"] == 4) then
			streams["week0timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer3Effect"] == BYTE_POWER_OFF) then
			streams["week0timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer4Effect"] == 8) then
			streams["week0timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer4Effect"] == BYTE_POWER_OFF) then
			streams["week0timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer5Effect"] == 16) then
			streams["week0timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer5Effect"] == BYTE_POWER_OFF) then
			streams["week0timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer6Effect"] == 32) then
			streams["week0timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer6Effect"] == BYTE_POWER_OFF) then
			streams["week0timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer1Effect"] == 1) then
			streams["week1timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer1Effect"] == BYTE_POWER_OFF) then
			streams["week1timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer2Effect"] == 2) then
			streams["week1timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer2Effect"] == BYTE_POWER_OFF) then
			streams["week1timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer3Effect"] == 4) then
			streams["week1timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer3Effect"] == BYTE_POWER_OFF) then
			streams["week1timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer4Effect"] == 8) then
			streams["week1timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer4Effect"] == BYTE_POWER_OFF) then
			streams["week1timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer5Effect"] == 16) then
			streams["week1timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer5Effect"] == BYTE_POWER_OFF) then
			streams["week1timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer6Effect"] == 32) then
			streams["week1timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer6Effect"] == BYTE_POWER_OFF) then
			streams["week1timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer1Effect"] == 1) then
			streams["week2timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer1Effect"] == BYTE_POWER_OFF) then
			streams["week2timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer2Effect"] == 2) then
			streams["week2timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer2Effect"] == BYTE_POWER_OFF) then
			streams["week2timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer3Effect"] == 4) then
			streams["week2timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer3Effect"] == BYTE_POWER_OFF) then
			streams["week2timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer4Effect"] == 8) then
			streams["week2timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer4Effect"] == BYTE_POWER_OFF) then
			streams["week2timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer5Effect"] == 16) then
			streams["week2timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer5Effect"] == BYTE_POWER_OFF) then
			streams["week2timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer6Effect"] == 32) then
			streams["week2timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer6Effect"] == BYTE_POWER_OFF) then
			streams["week2timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer1Effect"] == 1) then
			streams["week3timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer1Effect"] == BYTE_POWER_OFF) then
			streams["week3timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer2Effect"] == 2) then
			streams["week3timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer2Effect"] == BYTE_POWER_OFF) then
			streams["week3timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer3Effect"] == 4) then
			streams["week3timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer3Effect"] == BYTE_POWER_OFF) then
			streams["week3timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer4Effect"] == 8) then
			streams["week3timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer4Effect"] == BYTE_POWER_OFF) then
			streams["week3timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer5Effect"] == 16) then
			streams["week3timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer5Effect"] == BYTE_POWER_OFF) then
			streams["week3timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer6Effect"] == 32) then
			streams["week3timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer6Effect"] == BYTE_POWER_OFF) then
			streams["week3timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer1Effect"] == 1) then
			streams["week4timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer1Effect"] == BYTE_POWER_OFF) then
			streams["week4timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer2Effect"] == 2) then
			streams["week4timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer2Effect"] == BYTE_POWER_OFF) then
			streams["week4timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer3Effect"] == 4) then
			streams["week4timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer3Effect"] == BYTE_POWER_OFF) then
			streams["week4timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer4Effect"] == 8) then
			streams["week4timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer4Effect"] == BYTE_POWER_OFF) then
			streams["week4timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer5Effect"] == 16) then
			streams["week4timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer5Effect"] == BYTE_POWER_OFF) then
			streams["week4timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer6Effect"] == 32) then
			streams["week4timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer6Effect"] == BYTE_POWER_OFF) then
			streams["week4timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer1Effect"] == 1) then
			streams["week5timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer1Effect"] == BYTE_POWER_OFF) then
			streams["week5timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer2Effect"] == 2) then
			streams["week5timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer2Effect"] == BYTE_POWER_OFF) then
			streams["week5timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer3Effect"] == 4) then
			streams["week5timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer3Effect"] == BYTE_POWER_OFF) then
			streams["week5timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer4Effect"] == 8) then
			streams["week5timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer4Effect"] == BYTE_POWER_OFF) then
			streams["week5timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer5Effect"] == 16) then
			streams["week5timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer5Effect"] == BYTE_POWER_OFF) then
			streams["week5timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer6Effect"] == 32) then
			streams["week5timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer6Effect"] == BYTE_POWER_OFF) then
			streams["week5timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer1Effect"] == 1) then
			streams["week6timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer1Effect"] == BYTE_POWER_OFF) then
			streams["week6timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer2Effect"] == 2) then
			streams["week6timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer2Effect"] == BYTE_POWER_OFF) then
			streams["week6timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer3Effect"] == 4) then
			streams["week6timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer3Effect"] == BYTE_POWER_OFF) then
			streams["week6timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer4Effect"] == 8) then
			streams["week6timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer4Effect"] == BYTE_POWER_OFF) then
			streams["week6timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer5Effect"] == 16) then
			streams["week6timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer5Effect"] == BYTE_POWER_OFF) then
			streams["week6timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer6Effect"] == 32) then
			streams["week6timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer6Effect"] == BYTE_POWER_OFF) then
			streams["week6timer6_effect"] = VALUE_FUNCTION_OFF
		end
		streams["week0timer1_opentime"] = int2String(myTable["week0timer1OpenTime"])
		streams["week0timer1_closetime"] = int2String(myTable["week0timer1CloseTime"])
		streams["week0timer1_set_temperature"] = int2String(myTable["week0timer1SetTemperature"])
		streams["week0timer2_opentime"] = int2String(myTable["week0timer2OpenTime"])
		streams["week0timer2_closetime"] = int2String(myTable["week0timer2CloseTime"])
		streams["week0timer2_set_temperature"] = int2String(myTable["week0timer2SetTemperature"])
		streams["week0timer3_opentime"] = int2String(myTable["week0timer3OpenTime"])
		streams["week0timer3_closetime"] = int2String(myTable["week0timer3CloseTime"])
		streams["week0timer3_set_temperature"] = int2String(myTable["week0timer3SetTemperature"])
		streams["week0timer4_opentime"] = int2String(myTable["week0timer4OpenTime"])
		streams["week0timer4_closetime"] = int2String(myTable["week0timer4CloseTime"])
		streams["week0timer4_set_temperature"] = int2String(myTable["week0timer4SetTemperature"])
		streams["week0timer5_opentime"] = int2String(myTable["week0timer5OpenTime"])
		streams["week0timer5_closetime"] = int2String(myTable["week0timer5CloseTime"])
		streams["week0timer5_set_temperature"] = int2String(myTable["week0timer5SetTemperature"])
		streams["week0timer6_opentime"] = int2String(myTable["week0timer6OpenTime"])
		streams["week0timer6_closetime"] = int2String(myTable["week0timer6CloseTime"])
		streams["week0timer6_set_temperature"] = int2String(myTable["week0timer6SetTemperature"])
		streams["week1timer1_opentime"] = int2String(myTable["week1timer1OpenTime"])
		streams["week1timer1_closetime"] = int2String(myTable["week1timer1CloseTime"])
		streams["week1timer1_set_temperature"] = int2String(myTable["week1timer1SetTemperature"])
		streams["week1timer2_opentime"] = int2String(myTable["week1timer2OpenTime"])
		streams["week1timer2_closetime"] = int2String(myTable["week1timer2CloseTime"])
		streams["week1timer2_set_temperature"] = int2String(myTable["week1timer2SetTemperature"])
		streams["week1timer3_opentime"] = int2String(myTable["week1timer3OpenTime"])
		streams["week1timer3_closetime"] = int2String(myTable["week1timer3CloseTime"])
		streams["week1timer3_set_temperature"] = int2String(myTable["week1timer3SetTemperature"])
		streams["week1timer4_opentime"] = int2String(myTable["week1timer4OpenTime"])
		streams["week1timer4_closetime"] = int2String(myTable["week1timer4CloseTime"])
		streams["week1timer4_set_temperature"] = int2String(myTable["week1timer4SetTemperature"])
		streams["week1timer5_opentime"] = int2String(myTable["week1timer5OpenTime"])
		streams["week1timer5_closetime"] = int2String(myTable["week1timer5CloseTime"])
		streams["week1timer5_set_temperature"] = int2String(myTable["week1timer5SetTemperature"])
		streams["week1timer6_opentime"] = int2String(myTable["week1timer6OpenTime"])
		streams["week1timer6_closetime"] = int2String(myTable["week1timer6CloseTime"])
		streams["week1timer6_set_temperature"] = int2String(myTable["week1timer6SetTemperature"])
		streams["week2timer1_opentime"] = int2String(myTable["week2timer1OpenTime"])
		streams["week2timer1_closetime"] = int2String(myTable["week2timer1CloseTime"])
		streams["week2timer1_set_temperature"] = int2String(myTable["week2timer1SetTemperature"])
		streams["week2timer2_opentime"] = int2String(myTable["week2timer2OpenTime"])
		streams["week2timer2_closetime"] = int2String(myTable["week2timer2CloseTime"])
		streams["week2timer2_set_temperature"] = int2String(myTable["week2timer2SetTemperature"])
		streams["week2timer3_opentime"] = int2String(myTable["week2timer3OpenTime"])
		streams["week2timer3_closetime"] = int2String(myTable["week2timer3CloseTime"])
		streams["week2timer3_set_temperature"] = int2String(myTable["week2timer3SetTemperature"])
		streams["week2timer4_opentime"] = int2String(myTable["week2timer4OpenTime"])
		streams["week2timer4_closetime"] = int2String(myTable["week2timer4CloseTime"])
		streams["week2timer4_set_temperature"] = int2String(myTable["week2timer4SetTemperature"])
		streams["week2timer5_opentime"] = int2String(myTable["week2timer5OpenTime"])
		streams["week2timer5_closetime"] = int2String(myTable["week2timer5CloseTime"])
		streams["week2timer5_set_temperature"] = int2String(myTable["week2timer5SetTemperature"])
		streams["week2timer6_opentime"] = int2String(myTable["week2timer6OpenTime"])
		streams["week2timer6_closetime"] = int2String(myTable["week2timer6CloseTime"])
		streams["week2timer6_set_temperature"] = int2String(myTable["week2timer6SetTemperature"])
		streams["week3timer1_opentime"] = int2String(myTable["week3timer1OpenTime"])
		streams["week3timer1_closetime"] = int2String(myTable["week3timer1CloseTime"])
		streams["week3timer1_set_temperature"] = int2String(myTable["week3timer1SetTemperature"])
		streams["week3timer2_opentime"] = int2String(myTable["week3timer2OpenTime"])
		streams["week3timer2_closetime"] = int2String(myTable["week3timer2CloseTime"])
		streams["week3timer2_set_temperature"] = int2String(myTable["week3timer2SetTemperature"])
		streams["week3timer3_opentime"] = int2String(myTable["week3timer3OpenTime"])
		streams["week3timer3_closetime"] = int2String(myTable["week3timer3CloseTime"])
		streams["week3timer3_set_temperature"] = int2String(myTable["week3timer3SetTemperature"])
		streams["week3timer4_opentime"] = int2String(myTable["week3timer4OpenTime"])
		streams["week3timer4_closetime"] = int2String(myTable["week3timer4CloseTime"])
		streams["week3timer4_set_temperature"] = int2String(myTable["week3timer4SetTemperature"])
		streams["week3timer5_opentime"] = int2String(myTable["week3timer5OpenTime"])
		streams["week3timer5_closetime"] = int2String(myTable["week3timer5CloseTime"])
		streams["week3timer5_set_temperature"] = int2String(myTable["week3timer5SetTemperature"])
		streams["week3timer6_opentime"] = int2String(myTable["week3timer6OpenTime"])
		streams["week3timer6_closetime"] = int2String(myTable["week3timer6CloseTime"])
		streams["week3timer6_set_temperature"] = int2String(myTable["week3timer6SetTemperature"])
		streams["week4timer1_opentime"] = int2String(myTable["week4timer1OpenTime"])
		streams["week4timer1_closetime"] = int2String(myTable["week4timer1CloseTime"])
		streams["week4timer1_set_temperature"] = int2String(myTable["week4timer1SetTemperature"])
		streams["week4timer2_opentime"] = int2String(myTable["week4timer2OpenTime"])
		streams["week4timer2_closetime"] = int2String(myTable["week4timer2CloseTime"])
		streams["week4timer2_set_temperature"] = int2String(myTable["week4timer2SetTemperature"])
		streams["week4timer3_opentime"] = int2String(myTable["week4timer3OpenTime"])
		streams["week4timer3_closetime"] = int2String(myTable["week4timer3CloseTime"])
		streams["week4timer3_set_temperature"] = int2String(myTable["week4timer3SetTemperature"])
		streams["week4timer4_opentime"] = int2String(myTable["week4timer4OpenTime"])
		streams["week4timer4_closetime"] = int2String(myTable["week4timer4CloseTime"])
		streams["week4timer4_set_temperature"] = int2String(myTable["week4timer4SetTemperature"])
		streams["week4timer5_opentime"] = int2String(myTable["week4timer5OpenTime"])
		streams["week4timer5_closetime"] = int2String(myTable["week4timer5CloseTime"])
		streams["week4timer5_set_temperature"] = int2String(myTable["week4timer5SetTemperature"])
		streams["week4timer6_opentime"] = int2String(myTable["week4timer6OpenTime"])
		streams["week4timer6_closetime"] = int2String(myTable["week4timer6CloseTime"])
		streams["week4timer6_set_temperature"] = int2String(myTable["week4timer6SetTemperature"])
		streams["week5timer1_opentime"] = int2String(myTable["week5timer1OpenTime"])
		streams["week5timer1_closetime"] = int2String(myTable["week5timer1CloseTime"])
		streams["week5timer1_set_temperature"] = int2String(myTable["week5timer1SetTemperature"])
		streams["week5timer2_opentime"] = int2String(myTable["week5timer2OpenTime"])
		streams["week5timer2_closetime"] = int2String(myTable["week5timer2CloseTime"])
		streams["week5timer2_set_temperature"] = int2String(myTable["week5timer2SetTemperature"])
		streams["week5timer3_opentime"] = int2String(myTable["week5timer3OpenTime"])
		streams["week5timer3_closetime"] = int2String(myTable["week5timer3CloseTime"])
		streams["week5timer3_set_temperature"] = int2String(myTable["week5timer3SetTemperature"])
		streams["week5timer4_opentime"] = int2String(myTable["week5timer4OpenTime"])
		streams["week5timer4_closetime"] = int2String(myTable["week5timer4CloseTime"])
		streams["week5timer4_set_temperature"] = int2String(myTable["week5timer4SetTemperature"])
		streams["week5timer5_opentime"] = int2String(myTable["week5timer5OpenTime"])
		streams["week5timer5_closetime"] = int2String(myTable["week5timer5CloseTime"])
		streams["week5timer5_set_temperature"] = int2String(myTable["week5timer5SetTemperature"])
		streams["week5timer6_opentime"] = int2String(myTable["week5timer6OpenTime"])
		streams["week5timer6_closetime"] = int2String(myTable["week5timer6CloseTime"])
		streams["week5timer6_set_temperature"] = int2String(myTable["week5timer6SetTemperature"])
		streams["week6timer1_opentime"] = int2String(myTable["week6timer1OpenTime"])
		streams["week6timer1_closetime"] = int2String(myTable["week6timer1CloseTime"])
		streams["week6timer1_set_temperature"] = int2String(myTable["week6timer1SetTemperature"])
		streams["week6timer2_opentime"] = int2String(myTable["week6timer2OpenTime"])
		streams["week6timer2_closetime"] = int2String(myTable["week6timer2CloseTime"])
		streams["week6timer2_set_temperature"] = int2String(myTable["week6timer2SetTemperature"])
		streams["week6timer3_opentime"] = int2String(myTable["week6timer3OpenTime"])
		streams["week6timer3_closetime"] = int2String(myTable["week6timer3CloseTime"])
		streams["week6timer3_set_temperature"] = int2String(myTable["week6timer3SetTemperature"])
		streams["week6timer4_opentime"] = int2String(myTable["week6timer4OpenTime"])
		streams["week6timer4_closetime"] = int2String(myTable["week6timer4CloseTime"])
		streams["week6timer4_set_temperature"] = int2String(myTable["week6timer4SetTemperature"])
		streams["week6timer5_opentime"] = int2String(myTable["week6timer5OpenTime"])
		streams["week6timer5_closetime"] = int2String(myTable["week6timer5CloseTime"])
		streams["week6timer5_set_temperature"] = int2String(myTable["week6timer5SetTemperature"])
		streams["week6timer6_opentime"] = int2String(myTable["week6timer6OpenTime"])
		streams["week6timer6_closetime"] = int2String(myTable["week6timer6CloseTime"])
		streams["week6timer6_set_temperature"] = int2String(myTable["week6timer6SetTemperature"])
		if (myTable["week0timer1ModeValue"] == 1) then
			streams["week0timer1_modevalue"] = "energy"
		elseif (myTable["week0timer1ModeValue"] == 2) then
			streams["week0timer1_modevalue"] = "standard"
		elseif (myTable["week0timer1ModeValue"] == 3) then
			streams["week0timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer1ModeValue"] == 4) then
			streams["week0timer1_modevalue"] = "smart"
		end
		if (myTable["week0timer2ModeValue"] == 1) then
			streams["week0timer2_modevalue"] = "energy"
		elseif (myTable["week0timer2ModeValue"] == 2) then
			streams["week0timer2_modevalue"] = "standard"
		elseif (myTable["week0timer2ModeValue"] == 3) then
			streams["week0timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer2ModeValue"] == 4) then
			streams["week0timer2_modevalue"] = "smart"
		end
		if (myTable["week0timer3ModeValue"] == 1) then
			streams["week0timer3_modevalue"] = "energy"
		elseif (myTable["week0timer3ModeValue"] == 2) then
			streams["week0timer3_modevalue"] = "standard"
		elseif (myTable["week0timer3ModeValue"] == 3) then
			streams["week0timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer3ModeValue"] == 4) then
			streams["week0timer3_modevalue"] = "smart"
		end
		if (myTable["week0timer4ModeValue"] == 1) then
			streams["week0timer4_modevalue"] = "energy"
		elseif (myTable["week0timer4ModeValue"] == 2) then
			streams["week0timer4_modevalue"] = "standard"
		elseif (myTable["week0timer4ModeValue"] == 3) then
			streams["week0timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer4ModeValue"] == 4) then
			streams["week0timer4_modevalue"] = "smart"
		end
		if (myTable["week0timer5ModeValue"] == 1) then
			streams["week0timer5_modevalue"] = "energy"
		elseif (myTable["week0timer5ModeValue"] == 2) then
			streams["week0timer5_modevalue"] = "standard"
		elseif (myTable["week0timer5ModeValue"] == 3) then
			streams["week0timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer5ModeValue"] == 4) then
			streams["week0timer5_modevalue"] = "smart"
		end
		if (myTable["week0timer6ModeValue"] == 1) then
			streams["week0timer6_modevalue"] = "energy"
		elseif (myTable["week0timer6ModeValue"] == 2) then
			streams["week0timer6_modevalue"] = "standard"
		elseif (myTable["week0timer6ModeValue"] == 3) then
			streams["week0timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer6ModeValue"] == 4) then
			streams["week0timer6_modevalue"] = "smart"
		end
		if (myTable["week1timer1ModeValue"] == 1) then
			streams["week1timer1_modevalue"] = "energy"
		elseif (myTable["week1timer1ModeValue"] == 2) then
			streams["week1timer1_modevalue"] = "standard"
		elseif (myTable["week1timer1ModeValue"] == 3) then
			streams["week1timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer1ModeValue"] == 4) then
			streams["week1timer1_modevalue"] = "smart"
		end
		if (myTable["week1timer2ModeValue"] == 1) then
			streams["week1timer2_modevalue"] = "energy"
		elseif (myTable["week1timer2ModeValue"] == 2) then
			streams["week1timer2_modevalue"] = "standard"
		elseif (myTable["week1timer2ModeValue"] == 3) then
			streams["week1timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer2ModeValue"] == 4) then
			streams["week1timer2_modevalue"] = "smart"
		end
		if (myTable["week1timer3ModeValue"] == 1) then
			streams["week1timer3_modevalue"] = "energy"
		elseif (myTable["week1timer3ModeValue"] == 2) then
			streams["week1timer3_modevalue"] = "standard"
		elseif (myTable["week1timer3ModeValue"] == 3) then
			streams["week1timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer3ModeValue"] == 4) then
			streams["week1timer3_modevalue"] = "smart"
		end
		if (myTable["week1timer4ModeValue"] == 1) then
			streams["week1timer4_modevalue"] = "energy"
		elseif (myTable["week1timer4ModeValue"] == 2) then
			streams["week1timer4_modevalue"] = "standard"
		elseif (myTable["week1timer4ModeValue"] == 3) then
			streams["week1timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer4ModeValue"] == 4) then
			streams["week1timer4_modevalue"] = "smart"
		end
		if (myTable["week1timer5ModeValue"] == 1) then
			streams["week1timer5_modevalue"] = "energy"
		elseif (myTable["week1timer5ModeValue"] == 2) then
			streams["week1timer5_modevalue"] = "standard"
		elseif (myTable["week1timer5ModeValue"] == 3) then
			streams["week1timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer5ModeValue"] == 4) then
			streams["week1timer5_modevalue"] = "smart"
		end
		if (myTable["week1timer6ModeValue"] == 1) then
			streams["week1timer6_modevalue"] = "energy"
		elseif (myTable["week1timer6ModeValue"] == 2) then
			streams["week1timer6_modevalue"] = "standard"
		elseif (myTable["week1timer6ModeValue"] == 3) then
			streams["week1timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer6ModeValue"] == 4) then
			streams["week1timer6_modevalue"] = "smart"
		end
		if (myTable["week2timer1ModeValue"] == 1) then
			streams["week2timer1_modevalue"] = "energy"
		elseif (myTable["week2timer1ModeValue"] == 2) then
			streams["week2timer1_modevalue"] = "standard"
		elseif (myTable["week2timer1ModeValue"] == 3) then
			streams["week2timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer1ModeValue"] == 4) then
			streams["week2timer1_modevalue"] = "smart"
		end
		if (myTable["week2timer2ModeValue"] == 1) then
			streams["week2timer2_modevalue"] = "energy"
		elseif (myTable["week2timer2ModeValue"] == 2) then
			streams["week2timer2_modevalue"] = "standard"
		elseif (myTable["week2timer2ModeValue"] == 3) then
			streams["week2timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer2ModeValue"] == 4) then
			streams["week2timer2_modevalue"] = "smart"
		end
		if (myTable["week2timer3ModeValue"] == 1) then
			streams["week2timer3_modevalue"] = "energy"
		elseif (myTable["week2timer3ModeValue"] == 2) then
			streams["week2timer3_modevalue"] = "standard"
		elseif (myTable["week2timer3ModeValue"] == 3) then
			streams["week2timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer3ModeValue"] == 4) then
			streams["week2timer3_modevalue"] = "smart"
		end
		if (myTable["week2timer4ModeValue"] == 1) then
			streams["week2timer4_modevalue"] = "energy"
		elseif (myTable["week2timer4ModeValue"] == 2) then
			streams["week2timer4_modevalue"] = "standard"
		elseif (myTable["week2timer4ModeValue"] == 3) then
			streams["week2timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer4ModeValue"] == 4) then
			streams["week2timer4_modevalue"] = "smart"
		end
		if (myTable["week2timer5ModeValue"] == 1) then
			streams["week2timer5_modevalue"] = "energy"
		elseif (myTable["week2timer5ModeValue"] == 2) then
			streams["week2timer5_modevalue"] = "standard"
		elseif (myTable["week2timer5ModeValue"] == 3) then
			streams["week2timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer5ModeValue"] == 4) then
			streams["week2timer5_modevalue"] = "smart"
		end
		if (myTable["week2timer6ModeValue"] == 1) then
			streams["week2timer6_modevalue"] = "energy"
		elseif (myTable["week2timer6ModeValue"] == 2) then
			streams["week2timer6_modevalue"] = "standard"
		elseif (myTable["week2timer6ModeValue"] == 3) then
			streams["week2timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer6ModeValue"] == 4) then
			streams["week2timer6_modevalue"] = "smart"
		end
		if (myTable["week3timer1ModeValue"] == 1) then
			streams["week3timer1_modevalue"] = "energy"
		elseif (myTable["week3timer1ModeValue"] == 2) then
			streams["week3timer1_modevalue"] = "standard"
		elseif (myTable["week3timer1ModeValue"] == 3) then
			streams["week3timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer1ModeValue"] == 4) then
			streams["week3timer1_modevalue"] = "smart"
		end
		if (myTable["week3timer2ModeValue"] == 1) then
			streams["week3timer2_modevalue"] = "energy"
		elseif (myTable["week3timer2ModeValue"] == 2) then
			streams["week3timer2_modevalue"] = "standard"
		elseif (myTable["week3timer2ModeValue"] == 3) then
			streams["week3timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer2ModeValue"] == 4) then
			streams["week3timer2_modevalue"] = "smart"
		end
		if (myTable["week3timer3ModeValue"] == 1) then
			streams["week3timer3_modevalue"] = "energy"
		elseif (myTable["week3timer3ModeValue"] == 2) then
			streams["week3timer3_modevalue"] = "standard"
		elseif (myTable["week3timer3ModeValue"] == 3) then
			streams["week3timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer3ModeValue"] == 4) then
			streams["week3timer3_modevalue"] = "smart"
		end
		if (myTable["week3timer4ModeValue"] == 1) then
			streams["week3timer4_modevalue"] = "energy"
		elseif (myTable["week3timer4ModeValue"] == 2) then
			streams["week3timer4_modevalue"] = "standard"
		elseif (myTable["week3timer4ModeValue"] == 3) then
			streams["week3timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer4ModeValue"] == 4) then
			streams["week3timer4_modevalue"] = "smart"
		end
		if (myTable["week3timer5ModeValue"] == 1) then
			streams["week3timer5_modevalue"] = "energy"
		elseif (myTable["week3timer5ModeValue"] == 2) then
			streams["week3timer5_modevalue"] = "standard"
		elseif (myTable["week3timer5ModeValue"] == 3) then
			streams["week3timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer5ModeValue"] == 4) then
			streams["week3timer5_modevalue"] = "smart"
		end
		if (myTable["week3timer6ModeValue"] == 1) then
			streams["week3timer6_modevalue"] = "energy"
		elseif (myTable["week3timer6ModeValue"] == 2) then
			streams["week3timer6_modevalue"] = "standard"
		elseif (myTable["week3timer6ModeValue"] == 3) then
			streams["week3timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer6ModeValue"] == 4) then
			streams["week3timer6_modevalue"] = "smart"
		end
		if (myTable["week4timer1ModeValue"] == 1) then
			streams["week4timer1_modevalue"] = "energy"
		elseif (myTable["week4timer1ModeValue"] == 2) then
			streams["week4timer1_modevalue"] = "standard"
		elseif (myTable["week4timer1ModeValue"] == 3) then
			streams["week4timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer1ModeValue"] == 4) then
			streams["week4timer1_modevalue"] = "smart"
		end
		if (myTable["week4timer2ModeValue"] == 1) then
			streams["week4timer2_modevalue"] = "energy"
		elseif (myTable["week4timer2ModeValue"] == 2) then
			streams["week4timer2_modevalue"] = "standard"
		elseif (myTable["week4timer2ModeValue"] == 3) then
			streams["week4timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer2ModeValue"] == 4) then
			streams["week4timer2_modevalue"] = "smart"
		end
		if (myTable["week4timer3ModeValue"] == 1) then
			streams["week4timer3_modevalue"] = "energy"
		elseif (myTable["week4timer3ModeValue"] == 2) then
			streams["week4timer3_modevalue"] = "standard"
		elseif (myTable["week4timer3ModeValue"] == 3) then
			streams["week4timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer3ModeValue"] == 4) then
			streams["week4timer3_modevalue"] = "smart"
		end
		if (myTable["week4timer4ModeValue"] == 1) then
			streams["week4timer4_modevalue"] = "energy"
		elseif (myTable["week4timer4ModeValue"] == 2) then
			streams["week4timer4_modevalue"] = "standard"
		elseif (myTable["week4timer4ModeValue"] == 3) then
			streams["week4timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer4ModeValue"] == 4) then
			streams["week4timer4_modevalue"] = "smart"
		end
		if (myTable["week4timer5ModeValue"] == 1) then
			streams["week4timer5_modevalue"] = "energy"
		elseif (myTable["week4timer5ModeValue"] == 2) then
			streams["week4timer5_modevalue"] = "standard"
		elseif (myTable["week4timer5ModeValue"] == 3) then
			streams["week4timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer5ModeValue"] == 4) then
			streams["week4timer5_modevalue"] = "smart"
		end
		if (myTable["week4timer6ModeValue"] == 1) then
			streams["week4timer6_modevalue"] = "energy"
		elseif (myTable["week4timer6ModeValue"] == 2) then
			streams["week4timer6_modevalue"] = "standard"
		elseif (myTable["week4timer6ModeValue"] == 3) then
			streams["week4timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer6ModeValue"] == 4) then
			streams["week4timer6_modevalue"] = "smart"
		end
		if (myTable["week5timer1ModeValue"] == 1) then
			streams["week5timer1_modevalue"] = "energy"
		elseif (myTable["week5timer1ModeValue"] == 2) then
			streams["week5timer1_modevalue"] = "standard"
		elseif (myTable["week5timer1ModeValue"] == 3) then
			streams["week5timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer1ModeValue"] == 4) then
			streams["week5timer1_modevalue"] = "smart"
		end
		if (myTable["week5timer2ModeValue"] == 1) then
			streams["week5timer2_modevalue"] = "energy"
		elseif (myTable["week5timer2ModeValue"] == 2) then
			streams["week5timer2_modevalue"] = "standard"
		elseif (myTable["week5timer2ModeValue"] == 3) then
			streams["week5timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer2ModeValue"] == 4) then
			streams["week5timer2_modevalue"] = "smart"
		end
		if (myTable["week5timer3ModeValue"] == 1) then
			streams["week5timer3_modevalue"] = "energy"
		elseif (myTable["week5timer3ModeValue"] == 2) then
			streams["week5timer3_modevalue"] = "standard"
		elseif (myTable["week5timer3ModeValue"] == 3) then
			streams["week5timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer3ModeValue"] == 4) then
			streams["week5timer3_modevalue"] = "smart"
		end
		if (myTable["week5timer4ModeValue"] == 1) then
			streams["week5timer4_modevalue"] = "energy"
		elseif (myTable["week5timer4ModeValue"] == 2) then
			streams["week5timer4_modevalue"] = "standard"
		elseif (myTable["week5timer4ModeValue"] == 3) then
			streams["week5timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer4ModeValue"] == 4) then
			streams["week5timer4_modevalue"] = "smart"
		end
		if (myTable["week5timer5ModeValue"] == 1) then
			streams["week5timer5_modevalue"] = "energy"
		elseif (myTable["week5timer5ModeValue"] == 2) then
			streams["week5timer5_modevalue"] = "standard"
		elseif (myTable["week5timer5ModeValue"] == 3) then
			streams["week5timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer5ModeValue"] == 4) then
			streams["week5timer5_modevalue"] = "smart"
		end
		if (myTable["week5timer6ModeValue"] == 1) then
			streams["week5timer6_modevalue"] = "energy"
		elseif (myTable["week5timer6ModeValue"] == 2) then
			streams["week5timer6_modevalue"] = "standard"
		elseif (myTable["week5timer6ModeValue"] == 3) then
			streams["week5timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer6ModeValue"] == 4) then
			streams["week5timer6_modevalue"] = "smart"
		end
		if (myTable["week6timer1ModeValue"] == 1) then
			streams["week6timer1_modevalue"] = "energy"
		elseif (myTable["week6timer1ModeValue"] == 2) then
			streams["week6timer1_modevalue"] = "standard"
		elseif (myTable["week6timer1ModeValue"] == 3) then
			streams["week6timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer1ModeValue"] == 4) then
			streams["week6timer1_modevalue"] = "smart"
		end
		if (myTable["week6timer2ModeValue"] == 1) then
			streams["week6timer2_modevalue"] = "energy"
		elseif (myTable["week6timer2ModeValue"] == 2) then
			streams["week6timer2_modevalue"] = "standard"
		elseif (myTable["week6timer2ModeValue"] == 3) then
			streams["week6timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer2ModeValue"] == 4) then
			streams["week6timer2_modevalue"] = "smart"
		end
		if (myTable["week6timer3ModeValue"] == 1) then
			streams["week6timer3_modevalue"] = "energy"
		elseif (myTable["week6timer3ModeValue"] == 2) then
			streams["week6timer3_modevalue"] = "standard"
		elseif (myTable["week6timer3ModeValue"] == 3) then
			streams["week6timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer3ModeValue"] == 4) then
			streams["week6timer3_modevalue"] = "smart"
		end
		if (myTable["week6timer4ModeValue"] == 1) then
			streams["week6timer4_modevalue"] = "energy"
		elseif (myTable["week6timer4ModeValue"] == 2) then
			streams["week6timer4_modevalue"] = "standard"
		elseif (myTable["week6timer4ModeValue"] == 3) then
			streams["week6timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer4ModeValue"] == 4) then
			streams["week6timer4_modevalue"] = "smart"
		end
		if (myTable["week6timer5ModeValue"] == 1) then
			streams["week6timer5_modevalue"] = "energy"
		elseif (myTable["week6timer5ModeValue"] == 2) then
			streams["week6timer5_modevalue"] = "standard"
		elseif (myTable["week6timer5ModeValue"] == 3) then
			streams["week6timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer5ModeValue"] == 4) then
			streams["week6timer5_modevalue"] = "smart"
		end
		if (myTable["week6timer6ModeValue"] == 1) then
			streams["week6timer6_modevalue"] = "energy"
		elseif (myTable["week6timer6ModeValue"] == 2) then
			streams["week6timer6_modevalue"] = "standard"
		elseif (myTable["week6timer6ModeValue"] == 3) then
			streams["week6timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer6ModeValue"] == 4) then
			streams["week6timer6_modevalue"] = "smart"
		end
	elseif (((myTable["dataType"] == BYTE_AUTO_REPORT) and (msgSubType == 3)) or ((myTable["dataType"] == BYTE_QUERYL_REQUEST) and (msgSubType == 3))) then
		if (myTable["timer1Effect"] == 1) then
			streams["timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer1Effect"] == BYTE_POWER_OFF) then
			streams["timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer2Effect"] == 2) then
			streams["timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer2Effect"] == BYTE_POWER_OFF) then
			streams["timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer3Effect"] == 4) then
			streams["timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer3Effect"] == BYTE_POWER_OFF) then
			streams["timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer4Effect"] == 8) then
			streams["timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer4Effect"] == BYTE_POWER_OFF) then
			streams["timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer5Effect"] == 16) then
			streams["timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer5Effect"] == BYTE_POWER_OFF) then
			streams["timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer6Effect"] == 32) then
			streams["timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer6Effect"] == BYTE_POWER_OFF) then
			streams["timer6_effect"] = VALUE_FUNCTION_OFF
		end
		streams["timer1_openhour"] = int2String(myTable["timer1OpenHour"])
		streams["timer1_openmin"] = int2String(myTable["timer1OpenMin"])
		streams["timer1_closehour"] = int2String(myTable["timer1CloseHour"])
		streams["timer1_closemin"] = int2String(myTable["timer1CloseMin"])
		streams["timer1_set_temperature"] = int2String(myTable["timer1SetTemperature"])
		streams["timer2_openhour"] = int2String(myTable["timer2OpenHour"])
		streams["timer2_openmin"] = int2String(myTable["timer2OpenMin"])
		streams["timer2_closehour"] = int2String(myTable["timer2CloseHour"])
		streams["timer2_closemin"] = int2String(myTable["timer2CloseMin"])
		streams["timer2_set_temperature"] = int2String(myTable["timer2SetTemperature"])
		streams["timer3_openhour"] = int2String(myTable["timer3OpenHour"])
		streams["timer3_openmin"] = int2String(myTable["timer3OpenMin"])
		streams["timer3_closehour"] = int2String(myTable["timer3CloseHour"])
		streams["timer3_closemin"] = int2String(myTable["timer3CloseMin"])
		streams["timer3_set_temperature"] = int2String(myTable["timer3SetTemperature"])
		streams["timer4_openhour"] = int2String(myTable["timer4OpenHour"])
		streams["timer4_openmin"] = int2String(myTable["timer4OpenMin"])
		streams["timer4_closehour"] = int2String(myTable["timer4CloseHour"])
		streams["timer4_closemin"] = int2String(myTable["timer4CloseMin"])
		streams["timer4_set_temperature"] = int2String(myTable["timer4SetTemperature"])
		streams["timer5_openhour"] = int2String(myTable["timer5OpenHour"])
		streams["timer5_openmin"] = int2String(myTable["timer5OpenMin"])
		streams["timer5_closehour"] = int2String(myTable["timer5CloseHour"])
		streams["timer5_closemin"] = int2String(myTable["timer5CloseMin"])
		streams["timer5_set_temperature"] = int2String(myTable["timer5SetTemperature"])
		streams["timer6_openhour"] = int2String(myTable["timer6OpenHour"])
		streams["timer6_openmin"] = int2String(myTable["timer6OpenMin"])
		streams["timer6_closehour"] = int2String(myTable["timer6CloseHour"])
		streams["timer6_closemin"] = int2String(myTable["timer6CloseMin"])
		streams["timer6_set_temperature"] = int2String(myTable["timer6SetTemperature"])
		if (myTable["timer1ModeValue"] == 1) then
			streams["timer1_modevalue"] = "energy"
		elseif (myTable["timer1ModeValue"] == 2) then
			streams["timer1_modevalue"] = "standard"
		elseif (myTable["timer1ModeValue"] == 3) then
			streams["timer1_modevalue"] = "compatibilizing"
		elseif (myTable["timer1ModeValue"] == 4) then
			streams["timer1_modevalue"] = "smart"
		end
		if (myTable["timer2ModeValue"] == 1) then
			streams["timer2_modevalue"] = "energy"
		elseif (myTable["timer2ModeValue"] == 2) then
			streams["timer2_modevalue"] = "standard"
		elseif (myTable["timer2ModeValue"] == 3) then
			streams["timer2_modevalue"] = "compatibilizing"
		elseif (myTable["timer2ModeValue"] == 4) then
			streams["timer2_modevalue"] = "smart"
		end
		if (myTable["timer3ModeValue"] == 1) then
			streams["timer3_modevalue"] = "energy"
		elseif (myTable["timer3ModeValue"] == 2) then
			streams["timer3_modevalue"] = "standard"
		elseif (myTable["timer3ModeValue"] == 3) then
			streams["timer3_modevalue"] = "compatibilizing"
		elseif (myTable["timer3ModeValue"] == 4) then
			streams["timer3_modevalue"] = "smart"
		end
		if (myTable["timer4ModeValue"] == 1) then
			streams["timer4_modevalue"] = "energy"
		elseif (myTable["timer4ModeValue"] == 2) then
			streams["timer4_modevalue"] = "standard"
		elseif (myTable["timer4ModeValue"] == 3) then
			streams["timer4_modevalue"] = "compatibilizing"
		elseif (myTable["timer4ModeValue"] == 4) then
			streams["timer4_modevalue"] = "smart"
		end
		if (myTable["timer5ModeValue"] == 1) then
			streams["timer5_modevalue"] = "energy"
		elseif (myTable["timer5ModeValue"] == 2) then
			streams["timer5_modevalue"] = "standard"
		elseif (myTable["timer5ModeValue"] == 3) then
			streams["timer5_modevalue"] = "compatibilizing"
		elseif (myTable["timer5ModeValue"] == 4) then
			streams["timer5_modevalue"] = "smart"
		end
		if (myTable["timer6ModeValue"] == 1) then
			streams["timer6_modevalue"] = "energy"
		elseif (myTable["timer6ModeValue"] == 2) then
			streams["timer6_modevalue"] = "standard"
		elseif (myTable["timer6ModeValue"] == 3) then
			streams["timer6_modevalue"] = "compatibilizing"
		elseif (myTable["timer6ModeValue"] == 4) then
			streams["timer6_modevalue"] = "smart"
		end
	elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 1)) then
		if (myTable["powerValue"] == BYTE_POWER_ON) then
			streams[KEY_POWER] = VALUE_FUNCTION_ON
		elseif (myTable["powerValue"] == BYTE_POWER_OFF) then
			streams[KEY_POWER] = VALUE_FUNCTION_OFF
		end
		if myTable["modeValue"] == 1 then
			streams[KEY_MODE] = "energy"
		elseif myTable["modeValue"] == 2 then
			streams[KEY_MODE] = "standard"
		elseif myTable["modeValue"] == 3 then
			streams[KEY_MODE] = "compatibilizing"
		elseif myTable["modeValue"] == 4 then
			streams[KEY_MODE] = "smart"
		end
		streams["tr_temperature"] = int2String(math.modf(myTable["trValue"]))
		streams["open_ptc"] = int2String(myTable["openPTC"])
		streams["ptc_temperature"] = int2String(math.modf(myTable["ptcTemp"]))
		if (myTable["mute"] == BYTE_POWER_ON) then
			streams["mute"] = VALUE_FUNCTION_ON
		elseif (myTable["mute"] == BYTE_POWER_OFF) then
			streams["mute"] = VALUE_FUNCTION_OFF
		end
		if (myTable["openPTCTemp"] == BYTE_POWER_ON) then
			streams["open_ptc_temperature"] = VALUE_FUNCTION_ON
		elseif (myTable["openPTCTemp"] == BYTE_POWER_OFF) then
			streams["open_ptc_temperature"] = VALUE_FUNCTION_OFF
		end
		if (myTable["vacationMode"] == 16) then
			streams["vacation"] = VALUE_FUNCTION_ON
		elseif (myTable["vacationMode"] == 0) then
			streams["vacation"] = VALUE_FUNCTION_OFF
		end
		if (myTable["fahrenheitEffect"] == 128) then
			streams["fahrenheit_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["fahrenheitEffect"] == 0) then
			streams["fahrenheit_effect"] = VALUE_FUNCTION_OFF
		end
		streams["set_vacationdays"] = int2String(myTable["vacadaysValue"])
		streams["set_temperature"] = int2String(myTable["tsValue"])
		streams["set_vacation_start_year"] = int2String(myTable["vacadaysStartYearValue"])
		streams["set_vacation_start_month"] = int2String(myTable["vacadaysStartMonthValue"])
		streams["set_vacation_start_day"] = int2String(myTable["vacadaysStartDayValue"])
		streams["set_vacation_temperature"] = int2String(myTable["vacationTsValue"])
	elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 2)) then
		if (myTable["timer1Effect"] == 1) then
			streams["timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer1Effect"] == BYTE_POWER_OFF) then
			streams["timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer2Effect"] == 2) then
			streams["timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer2Effect"] == BYTE_POWER_OFF) then
			streams["timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer3Effect"] == 4) then
			streams["timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer3Effect"] == BYTE_POWER_OFF) then
			streams["timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer4Effect"] == 8) then
			streams["timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer4Effect"] == BYTE_POWER_OFF) then
			streams["timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer5Effect"] == 16) then
			streams["timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer5Effect"] == BYTE_POWER_OFF) then
			streams["timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["timer6Effect"] == 32) then
			streams["timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["timer6Effect"] == BYTE_POWER_OFF) then
			streams["timer6_effect"] = VALUE_FUNCTION_OFF
		end
		streams["timer1_openhour"] = int2String(myTable["timer1OpenHour"])
		streams["timer1_openmin"] = int2String(myTable["timer1OpenMin"])
		streams["timer1_closehour"] = int2String(myTable["timer1CloseHour"])
		streams["timer1_closemin"] = int2String(myTable["timer1CloseMin"])
		streams["timer1_set_temperature"] = int2String(myTable["timer1SetTemperature"])
		streams["timer2_openhour"] = int2String(myTable["timer2OpenHour"])
		streams["timer2_openmin"] = int2String(myTable["timer2OpenMin"])
		streams["timer2_closehour"] = int2String(myTable["timer2CloseHour"])
		streams["timer2_closemin"] = int2String(myTable["timer2CloseMin"])
		streams["timer2_set_temperature"] = int2String(myTable["timer2SetTemperature"])
		streams["timer3_openhour"] = int2String(myTable["timer3OpenHour"])
		streams["timer3_openmin"] = int2String(myTable["timer3OpenMin"])
		streams["timer3_closehour"] = int2String(myTable["timer3CloseHour"])
		streams["timer3_closemin"] = int2String(myTable["timer3CloseMin"])
		streams["timer3_set_temperature"] = int2String(myTable["timer3SetTemperature"])
		streams["timer4_openhour"] = int2String(myTable["timer4OpenHour"])
		streams["timer4_openmin"] = int2String(myTable["timer4OpenMin"])
		streams["timer4_closehour"] = int2String(myTable["timer4CloseHour"])
		streams["timer4_closemin"] = int2String(myTable["timer4CloseMin"])
		streams["timer4_set_temperature"] = int2String(myTable["timer4SetTemperature"])
		streams["timer5_openhour"] = int2String(myTable["timer5OpenHour"])
		streams["timer5_openmin"] = int2String(myTable["timer5OpenMin"])
		streams["timer5_closehour"] = int2String(myTable["timer5CloseHour"])
		streams["timer5_closemin"] = int2String(myTable["timer5CloseMin"])
		streams["timer5_set_temperature"] = int2String(myTable["timer5SetTemperature"])
		streams["timer6_openhour"] = int2String(myTable["timer6OpenHour"])
		streams["timer6_openmin"] = int2String(myTable["timer6OpenMin"])
		streams["timer6_closehour"] = int2String(myTable["timer6CloseHour"])
		streams["timer6_closemin"] = int2String(myTable["timer6CloseMin"])
		streams["timer6_set_temperature"] = int2String(myTable["timer6SetTemperature"])
		if (myTable["timer1ModeValue"] == 1) then
			streams["timer1_modevalue"] = "energy"
		elseif (myTable["timer1ModeValue"] == 2) then
			streams["timer1_modevalue"] = "standard"
		elseif (myTable["timer1ModeValue"] == 3) then
			streams["timer1_modevalue"] = "compatibilizing"
		elseif (myTable["timer1ModeValue"] == 4) then
			streams["timer1_modevalue"] = "smart"
		end
		if (myTable["timer2ModeValue"] == 1) then
			streams["timer2_modevalue"] = "energy"
		elseif (myTable["timer2ModeValue"] == 2) then
			streams["timer2_modevalue"] = "standard"
		elseif (myTable["timer2ModeValue"] == 3) then
			streams["timer2_modevalue"] = "compatibilizing"
		elseif (myTable["timer2ModeValue"] == 4) then
			streams["timer2_modevalue"] = "smart"
		end
		if (myTable["timer3ModeValue"] == 1) then
			streams["timer3_modevalue"] = "energy"
		elseif (myTable["timer3ModeValue"] == 2) then
			streams["timer3_modevalue"] = "standard"
		elseif (myTable["timer3ModeValue"] == 3) then
			streams["timer3_modevalue"] = "compatibilizing"
		elseif (myTable["timer3ModeValue"] == 4) then
			streams["timer3_modevalue"] = "smart"
		end
		if (myTable["timer4ModeValue"] == 1) then
			streams["timer4_modevalue"] = "energy"
		elseif (myTable["timer4ModeValue"] == 2) then
			streams["timer4_modevalue"] = "standard"
		elseif (myTable["timer4ModeValue"] == 3) then
			streams["timer4_modevalue"] = "compatibilizing"
		elseif (myTable["timer4ModeValue"] == 4) then
			streams["timer4_modevalue"] = "smart"
		end
		if (myTable["timer5ModeValue"] == 1) then
			streams["timer5_modevalue"] = "energy"
		elseif (myTable["timer5ModeValue"] == 2) then
			streams["timer5_modevalue"] = "standard"
		elseif (myTable["timer5ModeValue"] == 3) then
			streams["timer5_modevalue"] = "compatibilizing"
		elseif (myTable["timer5ModeValue"] == 4) then
			streams["timer5_modevalue"] = "smart"
		end
		if (myTable["timer6ModeValue"] == 1) then
			streams["timer6_modevalue"] = "energy"
		elseif (myTable["timer6ModeValue"] == 2) then
			streams["timer6_modevalue"] = "standard"
		elseif (myTable["timer6ModeValue"] == 3) then
			streams["timer6_modevalue"] = "compatibilizing"
		elseif (myTable["timer6ModeValue"] == 4) then
			streams["timer6_modevalue"] = "smart"
		end
	elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 3)) then
		if (myTable["order1Effect"] == BYTE_POWER_ON) then
			streams["order1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["order1Effect"] == BYTE_POWER_OFF) then
			streams["order1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["order2Effect"] == BYTE_POWER_ON) then
			streams["order2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["order2Effect"] == BYTE_POWER_OFF) then
			streams["order2_effect"] = VALUE_FUNCTION_OFF
		end
		streams["order1_temp"] = int2String(myTable["order1Temp"])
		streams["order1_timeHour"] = int2String(myTable["order1TimeHour"])
		streams["order1_timehour"] = int2String(myTable["order1TimeHour"])
		streams["order1_timeMin"] = int2String(myTable["order1TimeMin"])
		streams["order1_timemin"] = int2String(myTable["order1TimeMin"])
		streams["order2_temp"] = int2String(myTable["order2Temp"])
		streams["order2_timeHour"] = int2String(myTable["order2TimeHour"])
		streams["order2_timehour"] = int2String(myTable["order2TimeHour"])
		streams["order2_timeMin"] = int2String(myTable["order2TimeMin"])
		streams["order2_timemin"] = int2String(myTable["order2TimeMin"])
		streams["order1_stoptimeHour"] = int2String(myTable["order1StopTimeHour"])
		streams["order1_stoptimehour"] = int2String(myTable["order1StopTimeHour"])
		streams["order1_stoptimeMin"] = int2String(myTable["order1StopTimeMin"])
		streams["order1_stoptimemin"] = int2String(myTable["order1StopTimeMin"])
		streams["order2_stoptimeHour"] = int2String(myTable["order2StopTimeHour"])
		streams["order2_stoptimehour"] = int2String(myTable["order2StopTimeHour"])
		streams["order2_stoptimeMin"] = int2String(myTable["order2StopTimeMin"])
		streams["order2_stoptimemin"] = int2String(myTable["order2StopTimeMin"])
	elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 5)) then
		if (myTable["backwaterEffect"] == BYTE_POWER_ON) then
			streams["backwater_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["backwaterEffect"] == BYTE_POWER_OFF) then
			streams["backwater_effect"] = VALUE_FUNCTION_OFF
		end
	elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 6)) then
		if (myTable["sterilizeEffect"] == 128) then
			streams["sterilize_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["sterilizeEffect"] == BYTE_POWER_OFF) then
			streams["sterilize_effect"] = VALUE_FUNCTION_OFF
		end
		streams["auto_sterilize_week"] = int2String(myTable["autoSterilizeWeek"])
		streams["auto_sterilize_hour"] = int2String(myTable["autoSterilizeHour"])
		streams["auto_sterilize_minute"] = int2String(myTable["autoSterilizeMinute"])
	elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 7)) then
		if (myTable["week0timer1Effect"] == 1) then
			streams["week0timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer1Effect"] == BYTE_POWER_OFF) then
			streams["week0timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer2Effect"] == 2) then
			streams["week0timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer2Effect"] == BYTE_POWER_OFF) then
			streams["week0timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer3Effect"] == 4) then
			streams["week0timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer3Effect"] == BYTE_POWER_OFF) then
			streams["week0timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer4Effect"] == 8) then
			streams["week0timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer4Effect"] == BYTE_POWER_OFF) then
			streams["week0timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer5Effect"] == 16) then
			streams["week0timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer5Effect"] == BYTE_POWER_OFF) then
			streams["week0timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week0timer6Effect"] == 32) then
			streams["week0timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week0timer6Effect"] == BYTE_POWER_OFF) then
			streams["week0timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer1Effect"] == 1) then
			streams["week1timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer1Effect"] == BYTE_POWER_OFF) then
			streams["week1timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer2Effect"] == 2) then
			streams["week1timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer2Effect"] == BYTE_POWER_OFF) then
			streams["week1timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer3Effect"] == 4) then
			streams["week1timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer3Effect"] == BYTE_POWER_OFF) then
			streams["week1timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer4Effect"] == 8) then
			streams["week1timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer4Effect"] == BYTE_POWER_OFF) then
			streams["week1timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer5Effect"] == 16) then
			streams["week1timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer5Effect"] == BYTE_POWER_OFF) then
			streams["week1timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week1timer6Effect"] == 32) then
			streams["week1timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week1timer6Effect"] == BYTE_POWER_OFF) then
			streams["week1timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer1Effect"] == 1) then
			streams["week2timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer1Effect"] == BYTE_POWER_OFF) then
			streams["week2timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer2Effect"] == 2) then
			streams["week2timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer2Effect"] == BYTE_POWER_OFF) then
			streams["week2timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer3Effect"] == 4) then
			streams["week2timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer3Effect"] == BYTE_POWER_OFF) then
			streams["week2timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer4Effect"] == 8) then
			streams["week2timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer4Effect"] == BYTE_POWER_OFF) then
			streams["week2timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer5Effect"] == 16) then
			streams["week2timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer5Effect"] == BYTE_POWER_OFF) then
			streams["week2timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week2timer6Effect"] == 32) then
			streams["week2timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week2timer6Effect"] == BYTE_POWER_OFF) then
			streams["week2timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer1Effect"] == 1) then
			streams["week3timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer1Effect"] == BYTE_POWER_OFF) then
			streams["week3timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer2Effect"] == 2) then
			streams["week3timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer2Effect"] == BYTE_POWER_OFF) then
			streams["week3timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer3Effect"] == 4) then
			streams["week3timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer3Effect"] == BYTE_POWER_OFF) then
			streams["week3timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer4Effect"] == 8) then
			streams["week3timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer4Effect"] == BYTE_POWER_OFF) then
			streams["week3timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer5Effect"] == 16) then
			streams["week3timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer5Effect"] == BYTE_POWER_OFF) then
			streams["week3timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week3timer6Effect"] == 32) then
			streams["week3timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week3timer6Effect"] == BYTE_POWER_OFF) then
			streams["week3timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer1Effect"] == 1) then
			streams["week4timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer1Effect"] == BYTE_POWER_OFF) then
			streams["week4timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer2Effect"] == 2) then
			streams["week4timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer2Effect"] == BYTE_POWER_OFF) then
			streams["week4timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer3Effect"] == 4) then
			streams["week4timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer3Effect"] == BYTE_POWER_OFF) then
			streams["week4timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer4Effect"] == 8) then
			streams["week4timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer4Effect"] == BYTE_POWER_OFF) then
			streams["week4timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer5Effect"] == 16) then
			streams["week4timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer5Effect"] == BYTE_POWER_OFF) then
			streams["week4timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week4timer6Effect"] == 32) then
			streams["week4timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week4timer6Effect"] == BYTE_POWER_OFF) then
			streams["week4timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer1Effect"] == 1) then
			streams["week5timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer1Effect"] == BYTE_POWER_OFF) then
			streams["week5timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer2Effect"] == 2) then
			streams["week5timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer2Effect"] == BYTE_POWER_OFF) then
			streams["week5timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer3Effect"] == 4) then
			streams["week5timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer3Effect"] == BYTE_POWER_OFF) then
			streams["week5timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer4Effect"] == 8) then
			streams["week5timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer4Effect"] == BYTE_POWER_OFF) then
			streams["week5timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer5Effect"] == 16) then
			streams["week5timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer5Effect"] == BYTE_POWER_OFF) then
			streams["week5timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week5timer6Effect"] == 32) then
			streams["week5timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week5timer6Effect"] == BYTE_POWER_OFF) then
			streams["week5timer6_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer1Effect"] == 1) then
			streams["week6timer1_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer1Effect"] == BYTE_POWER_OFF) then
			streams["week6timer1_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer2Effect"] == 2) then
			streams["week6timer2_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer2Effect"] == BYTE_POWER_OFF) then
			streams["week6timer2_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer3Effect"] == 4) then
			streams["week6timer3_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer3Effect"] == BYTE_POWER_OFF) then
			streams["week6timer3_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer4Effect"] == 8) then
			streams["week6timer4_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer4Effect"] == BYTE_POWER_OFF) then
			streams["week6timer4_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer5Effect"] == 16) then
			streams["week6timer5_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer5Effect"] == BYTE_POWER_OFF) then
			streams["week6timer5_effect"] = VALUE_FUNCTION_OFF
		end
		if (myTable["week6timer6Effect"] == 32) then
			streams["week6timer6_effect"] = VALUE_FUNCTION_ON
		elseif (myTable["week6timer6Effect"] == BYTE_POWER_OFF) then
			streams["week6timer6_effect"] = VALUE_FUNCTION_OFF
		end
		streams["week0timer1_opentime"] = int2String(myTable["week0timer1OpenTime"])
		streams["week0timer1_closetime"] = int2String(myTable["week0timer1CloseTime"])
		streams["week0timer1_set_temperature"] = int2String(myTable["week0timer1SetTemperature"])
		streams["week0timer2_opentime"] = int2String(myTable["week0timer2OpenTime"])
		streams["week0timer2_closetime"] = int2String(myTable["week0timer2CloseTime"])
		streams["week0timer2_set_temperature"] = int2String(myTable["week0timer2SetTemperature"])
		streams["week0timer3_opentime"] = int2String(myTable["week0timer3OpenTime"])
		streams["week0timer3_closetime"] = int2String(myTable["week0timer3CloseTime"])
		streams["week0timer3_set_temperature"] = int2String(myTable["week0timer3SetTemperature"])
		streams["week0timer4_opentime"] = int2String(myTable["week0timer4OpenTime"])
		streams["week0timer4_closetime"] = int2String(myTable["week0timer4CloseTime"])
		streams["week0timer4_set_temperature"] = int2String(myTable["week0timer4SetTemperature"])
		streams["week0timer5_opentime"] = int2String(myTable["week0timer5OpenTime"])
		streams["week0timer5_closetime"] = int2String(myTable["week0timer5CloseTime"])
		streams["week0timer5_set_temperature"] = int2String(myTable["week0timer5SetTemperature"])
		streams["week0timer6_opentime"] = int2String(myTable["week0timer6OpenTime"])
		streams["week0timer6_closetime"] = int2String(myTable["week0timer6CloseTime"])
		streams["week0timer6_set_temperature"] = int2String(myTable["week0timer6SetTemperature"])
		streams["week1timer1_opentime"] = int2String(myTable["week1timer1OpenTime"])
		streams["week1timer1_closetime"] = int2String(myTable["week1timer1CloseTime"])
		streams["week1timer1_set_temperature"] = int2String(myTable["week1timer1SetTemperature"])
		streams["week1timer2_opentime"] = int2String(myTable["week1timer2OpenTime"])
		streams["week1timer2_closetime"] = int2String(myTable["week1timer2CloseTime"])
		streams["week1timer2_set_temperature"] = int2String(myTable["week1timer2SetTemperature"])
		streams["week1timer3_opentime"] = int2String(myTable["week1timer3OpenTime"])
		streams["week1timer3_closetime"] = int2String(myTable["week1timer3CloseTime"])
		streams["week1timer3_set_temperature"] = int2String(myTable["week1timer3SetTemperature"])
		streams["week1timer4_opentime"] = int2String(myTable["week1timer4OpenTime"])
		streams["week1timer4_closetime"] = int2String(myTable["week1timer4CloseTime"])
		streams["week1timer4_set_temperature"] = int2String(myTable["week1timer4SetTemperature"])
		streams["week1timer5_opentime"] = int2String(myTable["week1timer5OpenTime"])
		streams["week1timer5_closetime"] = int2String(myTable["week1timer5CloseTime"])
		streams["week1timer5_set_temperature"] = int2String(myTable["week1timer5SetTemperature"])
		streams["week1timer6_opentime"] = int2String(myTable["week1timer6OpenTime"])
		streams["week1timer6_closetime"] = int2String(myTable["week1timer6CloseTime"])
		streams["week1timer6_set_temperature"] = int2String(myTable["week1timer6SetTemperature"])
		streams["week2timer1_opentime"] = int2String(myTable["week2timer1OpenTime"])
		streams["week2timer1_closetime"] = int2String(myTable["week2timer1CloseTime"])
		streams["week2timer1_set_temperature"] = int2String(myTable["week2timer1SetTemperature"])
		streams["week2timer2_opentime"] = int2String(myTable["week2timer2OpenTime"])
		streams["week2timer2_closetime"] = int2String(myTable["week2timer2CloseTime"])
		streams["week2timer2_set_temperature"] = int2String(myTable["week2timer2SetTemperature"])
		streams["week2timer3_opentime"] = int2String(myTable["week2timer3OpenTime"])
		streams["week2timer3_closetime"] = int2String(myTable["week2timer3CloseTime"])
		streams["week2timer3_set_temperature"] = int2String(myTable["week2timer3SetTemperature"])
		streams["week2timer4_opentime"] = int2String(myTable["week2timer4OpenTime"])
		streams["week2timer4_closetime"] = int2String(myTable["week2timer4CloseTime"])
		streams["week2timer4_set_temperature"] = int2String(myTable["week2timer4SetTemperature"])
		streams["week2timer5_opentime"] = int2String(myTable["week2timer5OpenTime"])
		streams["week2timer5_closetime"] = int2String(myTable["week2timer5CloseTime"])
		streams["week2timer5_set_temperature"] = int2String(myTable["week2timer5SetTemperature"])
		streams["week2timer6_opentime"] = int2String(myTable["week2timer6OpenTime"])
		streams["week2timer6_closetime"] = int2String(myTable["week2timer6CloseTime"])
		streams["week2timer6_set_temperature"] = int2String(myTable["week2timer6SetTemperature"])
		streams["week3timer1_opentime"] = int2String(myTable["week3timer1OpenTime"])
		streams["week3timer1_closetime"] = int2String(myTable["week3timer1CloseTime"])
		streams["week3timer1_set_temperature"] = int2String(myTable["week3timer1SetTemperature"])
		streams["week3timer2_opentime"] = int2String(myTable["week3timer2OpenTime"])
		streams["week3timer2_closetime"] = int2String(myTable["week3timer2CloseTime"])
		streams["week3timer2_set_temperature"] = int2String(myTable["week3timer2SetTemperature"])
		streams["week3timer3_opentime"] = int2String(myTable["week3timer3OpenTime"])
		streams["week3timer3_closetime"] = int2String(myTable["week3timer3CloseTime"])
		streams["week3timer3_set_temperature"] = int2String(myTable["week3timer3SetTemperature"])
		streams["week3timer4_opentime"] = int2String(myTable["week3timer4OpenTime"])
		streams["week3timer4_closetime"] = int2String(myTable["week3timer4CloseTime"])
		streams["week3timer4_set_temperature"] = int2String(myTable["week3timer4SetTemperature"])
		streams["week3timer5_opentime"] = int2String(myTable["week3timer5OpenTime"])
		streams["week3timer5_closetime"] = int2String(myTable["week3timer5CloseTime"])
		streams["week3timer5_set_temperature"] = int2String(myTable["week3timer5SetTemperature"])
		streams["week3timer6_opentime"] = int2String(myTable["week3timer6OpenTime"])
		streams["week3timer6_closetime"] = int2String(myTable["week3timer6CloseTime"])
		streams["week3timer6_set_temperature"] = int2String(myTable["week3timer6SetTemperature"])
		streams["week4timer1_opentime"] = int2String(myTable["week4timer1OpenTime"])
		streams["week4timer1_closetime"] = int2String(myTable["week4timer1CloseTime"])
		streams["week4timer1_set_temperature"] = int2String(myTable["week4timer1SetTemperature"])
		streams["week4timer2_opentime"] = int2String(myTable["week4timer2OpenTime"])
		streams["week4timer2_closetime"] = int2String(myTable["week4timer2CloseTime"])
		streams["week4timer2_set_temperature"] = int2String(myTable["week4timer2SetTemperature"])
		streams["week4timer3_opentime"] = int2String(myTable["week4timer3OpenTime"])
		streams["week4timer3_closetime"] = int2String(myTable["week4timer3CloseTime"])
		streams["week4timer3_set_temperature"] = int2String(myTable["week4timer3SetTemperature"])
		streams["week4timer4_opentime"] = int2String(myTable["week4timer4OpenTime"])
		streams["week4timer4_closetime"] = int2String(myTable["week4timer4CloseTime"])
		streams["week4timer4_set_temperature"] = int2String(myTable["week4timer4SetTemperature"])
		streams["week4timer5_opentime"] = int2String(myTable["week4timer5OpenTime"])
		streams["week4timer5_closetime"] = int2String(myTable["week4timer5CloseTime"])
		streams["week4timer5_set_temperature"] = int2String(myTable["week4timer5SetTemperature"])
		streams["week4timer6_opentime"] = int2String(myTable["week4timer6OpenTime"])
		streams["week4timer6_closetime"] = int2String(myTable["week4timer6CloseTime"])
		streams["week4timer6_set_temperature"] = int2String(myTable["week4timer6SetTemperature"])
		streams["week5timer1_opentime"] = int2String(myTable["week5timer1OpenTime"])
		streams["week5timer1_closetime"] = int2String(myTable["week5timer1CloseTime"])
		streams["week5timer1_set_temperature"] = int2String(myTable["week5timer1SetTemperature"])
		streams["week5timer2_opentime"] = int2String(myTable["week5timer2OpenTime"])
		streams["week5timer2_closetime"] = int2String(myTable["week5timer2CloseTime"])
		streams["week5timer2_set_temperature"] = int2String(myTable["week5timer2SetTemperature"])
		streams["week5timer3_opentime"] = int2String(myTable["week5timer3OpenTime"])
		streams["week5timer3_closetime"] = int2String(myTable["week5timer3CloseTime"])
		streams["week5timer3_set_temperature"] = int2String(myTable["week5timer3SetTemperature"])
		streams["week5timer4_opentime"] = int2String(myTable["week5timer4OpenTime"])
		streams["week5timer4_closetime"] = int2String(myTable["week5timer4CloseTime"])
		streams["week5timer4_set_temperature"] = int2String(myTable["week5timer4SetTemperature"])
		streams["week5timer5_opentime"] = int2String(myTable["week5timer5OpenTime"])
		streams["week5timer5_closetime"] = int2String(myTable["week5timer5CloseTime"])
		streams["week5timer5_set_temperature"] = int2String(myTable["week5timer5SetTemperature"])
		streams["week5timer6_opentime"] = int2String(myTable["week5timer6OpenTime"])
		streams["week5timer6_closetime"] = int2String(myTable["week5timer6CloseTime"])
		streams["week5timer6_set_temperature"] = int2String(myTable["week5timer6SetTemperature"])
		streams["week6timer1_opentime"] = int2String(myTable["week6timer1OpenTime"])
		streams["week6timer1_closetime"] = int2String(myTable["week6timer1CloseTime"])
		streams["week6timer1_set_temperature"] = int2String(myTable["week6timer1SetTemperature"])
		streams["week6timer2_opentime"] = int2String(myTable["week6timer2OpenTime"])
		streams["week6timer2_closetime"] = int2String(myTable["week6timer2CloseTime"])
		streams["week6timer2_set_temperature"] = int2String(myTable["week6timer2SetTemperature"])
		streams["week6timer3_opentime"] = int2String(myTable["week6timer3OpenTime"])
		streams["week6timer3_closetime"] = int2String(myTable["week6timer3CloseTime"])
		streams["week6timer3_set_temperature"] = int2String(myTable["week6timer3SetTemperature"])
		streams["week6timer4_opentime"] = int2String(myTable["week6timer4OpenTime"])
		streams["week6timer4_closetime"] = int2String(myTable["week6timer4CloseTime"])
		streams["week6timer4_set_temperature"] = int2String(myTable["week6timer4SetTemperature"])
		streams["week6timer5_opentime"] = int2String(myTable["week6timer5OpenTime"])
		streams["week6timer5_closetime"] = int2String(myTable["week6timer5CloseTime"])
		streams["week6timer5_set_temperature"] = int2String(myTable["week6timer5SetTemperature"])
		streams["week6timer6_opentime"] = int2String(myTable["week6timer6OpenTime"])
		streams["week6timer6_closetime"] = int2String(myTable["week6timer6CloseTime"])
		streams["week6timer6_set_temperature"] = int2String(myTable["week6timer6SetTemperature"])
		if (myTable["week0timer1ModeValue"] == 1) then
			streams["week0timer1_modevalue"] = "energy"
		elseif (myTable["week0timer1ModeValue"] == 2) then
			streams["week0timer1_modevalue"] = "standard"
		elseif (myTable["week0timer1ModeValue"] == 3) then
			streams["week0timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer1ModeValue"] == 4) then
			streams["week0timer1_modevalue"] = "smart"
		end
		if (myTable["week0timer2ModeValue"] == 1) then
			streams["week0timer2_modevalue"] = "energy"
		elseif (myTable["week0timer2ModeValue"] == 2) then
			streams["week0timer2_modevalue"] = "standard"
		elseif (myTable["week0timer2ModeValue"] == 3) then
			streams["week0timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer2ModeValue"] == 4) then
			streams["week0timer2_modevalue"] = "smart"
		end
		if (myTable["week0timer3ModeValue"] == 1) then
			streams["week0timer3_modevalue"] = "energy"
		elseif (myTable["week0timer3ModeValue"] == 2) then
			streams["week0timer3_modevalue"] = "standard"
		elseif (myTable["week0timer3ModeValue"] == 3) then
			streams["week0timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer3ModeValue"] == 4) then
			streams["week0timer3_modevalue"] = "smart"
		end
		if (myTable["week0timer4ModeValue"] == 1) then
			streams["week0timer4_modevalue"] = "energy"
		elseif (myTable["week0timer4ModeValue"] == 2) then
			streams["week0timer4_modevalue"] = "standard"
		elseif (myTable["week0timer4ModeValue"] == 3) then
			streams["week0timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer4ModeValue"] == 4) then
			streams["week0timer4_modevalue"] = "smart"
		end
		if (myTable["week0timer5ModeValue"] == 1) then
			streams["week0timer5_modevalue"] = "energy"
		elseif (myTable["week0timer5ModeValue"] == 2) then
			streams["week0timer5_modevalue"] = "standard"
		elseif (myTable["week0timer5ModeValue"] == 3) then
			streams["week0timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer5ModeValue"] == 4) then
			streams["week0timer5_modevalue"] = "smart"
		end
		if (myTable["week0timer6ModeValue"] == 1) then
			streams["week0timer6_modevalue"] = "energy"
		elseif (myTable["week0timer6ModeValue"] == 2) then
			streams["week0timer6_modevalue"] = "standard"
		elseif (myTable["week0timer6ModeValue"] == 3) then
			streams["week0timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week0timer6ModeValue"] == 4) then
			streams["week0timer6_modevalue"] = "smart"
		end
		if (myTable["week1timer1ModeValue"] == 1) then
			streams["week1timer1_modevalue"] = "energy"
		elseif (myTable["week1timer1ModeValue"] == 2) then
			streams["week1timer1_modevalue"] = "standard"
		elseif (myTable["week1timer1ModeValue"] == 3) then
			streams["week1timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer1ModeValue"] == 4) then
			streams["week1timer1_modevalue"] = "smart"
		end
		if (myTable["week1timer2ModeValue"] == 1) then
			streams["week1timer2_modevalue"] = "energy"
		elseif (myTable["week1timer2ModeValue"] == 2) then
			streams["week1timer2_modevalue"] = "standard"
		elseif (myTable["week1timer2ModeValue"] == 3) then
			streams["week1timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer2ModeValue"] == 4) then
			streams["week1timer2_modevalue"] = "smart"
		end
		if (myTable["week1timer3ModeValue"] == 1) then
			streams["week1timer3_modevalue"] = "energy"
		elseif (myTable["week1timer3ModeValue"] == 2) then
			streams["week1timer3_modevalue"] = "standard"
		elseif (myTable["week1timer3ModeValue"] == 3) then
			streams["week1timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer3ModeValue"] == 4) then
			streams["week1timer3_modevalue"] = "smart"
		end
		if (myTable["week1timer4ModeValue"] == 1) then
			streams["week1timer4_modevalue"] = "energy"
		elseif (myTable["week1timer4ModeValue"] == 2) then
			streams["week1timer4_modevalue"] = "standard"
		elseif (myTable["week1timer4ModeValue"] == 3) then
			streams["week1timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer4ModeValue"] == 4) then
			streams["week1timer4_modevalue"] = "smart"
		end
		if (myTable["week1timer5ModeValue"] == 1) then
			streams["week1timer5_modevalue"] = "energy"
		elseif (myTable["week1timer5ModeValue"] == 2) then
			streams["week1timer5_modevalue"] = "standard"
		elseif (myTable["week1timer5ModeValue"] == 3) then
			streams["week1timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer5ModeValue"] == 4) then
			streams["week1timer5_modevalue"] = "smart"
		end
		if (myTable["week1timer6ModeValue"] == 1) then
			streams["week1timer6_modevalue"] = "energy"
		elseif (myTable["week1timer6ModeValue"] == 2) then
			streams["week1timer6_modevalue"] = "standard"
		elseif (myTable["week1timer6ModeValue"] == 3) then
			streams["week1timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week1timer6ModeValue"] == 4) then
			streams["week1timer6_modevalue"] = "smart"
		end
		if (myTable["week2timer1ModeValue"] == 1) then
			streams["week2timer1_modevalue"] = "energy"
		elseif (myTable["week2timer1ModeValue"] == 2) then
			streams["week2timer1_modevalue"] = "standard"
		elseif (myTable["week2timer1ModeValue"] == 3) then
			streams["week2timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer1ModeValue"] == 4) then
			streams["week2timer1_modevalue"] = "smart"
		end
		if (myTable["week2timer2ModeValue"] == 1) then
			streams["week2timer2_modevalue"] = "energy"
		elseif (myTable["week2timer2ModeValue"] == 2) then
			streams["week2timer2_modevalue"] = "standard"
		elseif (myTable["week2timer2ModeValue"] == 3) then
			streams["week2timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer2ModeValue"] == 4) then
			streams["week2timer2_modevalue"] = "smart"
		end
		if (myTable["week2timer3ModeValue"] == 1) then
			streams["week2timer3_modevalue"] = "energy"
		elseif (myTable["week2timer3ModeValue"] == 2) then
			streams["week2timer3_modevalue"] = "standard"
		elseif (myTable["week2timer3ModeValue"] == 3) then
			streams["week2timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer3ModeValue"] == 4) then
			streams["week2timer3_modevalue"] = "smart"
		end
		if (myTable["week2timer4ModeValue"] == 1) then
			streams["week2timer4_modevalue"] = "energy"
		elseif (myTable["week2timer4ModeValue"] == 2) then
			streams["week2timer4_modevalue"] = "standard"
		elseif (myTable["week2timer4ModeValue"] == 3) then
			streams["week2timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer4ModeValue"] == 4) then
			streams["week2timer4_modevalue"] = "smart"
		end
		if (myTable["week2timer5ModeValue"] == 1) then
			streams["week2timer5_modevalue"] = "energy"
		elseif (myTable["week2timer5ModeValue"] == 2) then
			streams["week2timer5_modevalue"] = "standard"
		elseif (myTable["week2timer5ModeValue"] == 3) then
			streams["week2timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer5ModeValue"] == 4) then
			streams["week2timer5_modevalue"] = "smart"
		end
		if (myTable["week2timer6ModeValue"] == 1) then
			streams["week2timer6_modevalue"] = "energy"
		elseif (myTable["week2timer6ModeValue"] == 2) then
			streams["week2timer6_modevalue"] = "standard"
		elseif (myTable["week2timer6ModeValue"] == 3) then
			streams["week2timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week2timer6ModeValue"] == 4) then
			streams["week2timer6_modevalue"] = "smart"
		end
		if (myTable["week3timer1ModeValue"] == 1) then
			streams["week3timer1_modevalue"] = "energy"
		elseif (myTable["week3timer1ModeValue"] == 2) then
			streams["week3timer1_modevalue"] = "standard"
		elseif (myTable["week3timer1ModeValue"] == 3) then
			streams["week3timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer1ModeValue"] == 4) then
			streams["week3timer1_modevalue"] = "smart"
		end
		if (myTable["week3timer2ModeValue"] == 1) then
			streams["week3timer2_modevalue"] = "energy"
		elseif (myTable["week3timer2ModeValue"] == 2) then
			streams["week3timer2_modevalue"] = "standard"
		elseif (myTable["week3timer2ModeValue"] == 3) then
			streams["week3timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer2ModeValue"] == 4) then
			streams["week3timer2_modevalue"] = "smart"
		end
		if (myTable["week3timer3ModeValue"] == 1) then
			streams["week3timer3_modevalue"] = "energy"
		elseif (myTable["week3timer3ModeValue"] == 2) then
			streams["week3timer3_modevalue"] = "standard"
		elseif (myTable["week3timer3ModeValue"] == 3) then
			streams["week3timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer3ModeValue"] == 4) then
			streams["week3timer3_modevalue"] = "smart"
		end
		if (myTable["week3timer4ModeValue"] == 1) then
			streams["week3timer4_modevalue"] = "energy"
		elseif (myTable["week3timer4ModeValue"] == 2) then
			streams["week3timer4_modevalue"] = "standard"
		elseif (myTable["week3timer4ModeValue"] == 3) then
			streams["week3timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer4ModeValue"] == 4) then
			streams["week3timer4_modevalue"] = "smart"
		end
		if (myTable["week3timer5ModeValue"] == 1) then
			streams["week3timer5_modevalue"] = "energy"
		elseif (myTable["week3timer5ModeValue"] == 2) then
			streams["week3timer5_modevalue"] = "standard"
		elseif (myTable["week3timer5ModeValue"] == 3) then
			streams["week3timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer5ModeValue"] == 4) then
			streams["week3timer5_modevalue"] = "smart"
		end
		if (myTable["week3timer6ModeValue"] == 1) then
			streams["week3timer6_modevalue"] = "energy"
		elseif (myTable["week3timer6ModeValue"] == 2) then
			streams["week3timer6_modevalue"] = "standard"
		elseif (myTable["week3timer6ModeValue"] == 3) then
			streams["week3timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week3timer6ModeValue"] == 4) then
			streams["week3timer6_modevalue"] = "smart"
		end
		if (myTable["week4timer1ModeValue"] == 1) then
			streams["week4timer1_modevalue"] = "energy"
		elseif (myTable["week4timer1ModeValue"] == 2) then
			streams["week4timer1_modevalue"] = "standard"
		elseif (myTable["week4timer1ModeValue"] == 3) then
			streams["week4timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer1ModeValue"] == 4) then
			streams["week4timer1_modevalue"] = "smart"
		end
		if (myTable["week4timer2ModeValue"] == 1) then
			streams["week4timer2_modevalue"] = "energy"
		elseif (myTable["week4timer2ModeValue"] == 2) then
			streams["week4timer2_modevalue"] = "standard"
		elseif (myTable["week4timer2ModeValue"] == 3) then
			streams["week4timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer2ModeValue"] == 4) then
			streams["week4timer2_modevalue"] = "smart"
		end
		if (myTable["week4timer3ModeValue"] == 1) then
			streams["week4timer3_modevalue"] = "energy"
		elseif (myTable["week4timer3ModeValue"] == 2) then
			streams["week4timer3_modevalue"] = "standard"
		elseif (myTable["week4timer3ModeValue"] == 3) then
			streams["week4timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer3ModeValue"] == 4) then
			streams["week4timer3_modevalue"] = "smart"
		end
		if (myTable["week4timer4ModeValue"] == 1) then
			streams["week4timer4_modevalue"] = "energy"
		elseif (myTable["week4timer4ModeValue"] == 2) then
			streams["week4timer4_modevalue"] = "standard"
		elseif (myTable["week4timer4ModeValue"] == 3) then
			streams["week4timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer4ModeValue"] == 4) then
			streams["week4timer4_modevalue"] = "smart"
		end
		if (myTable["week4timer5ModeValue"] == 1) then
			streams["week4timer5_modevalue"] = "energy"
		elseif (myTable["week4timer5ModeValue"] == 2) then
			streams["week4timer5_modevalue"] = "standard"
		elseif (myTable["week4timer5ModeValue"] == 3) then
			streams["week4timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer5ModeValue"] == 4) then
			streams["week4timer5_modevalue"] = "smart"
		end
		if (myTable["week4timer6ModeValue"] == 1) then
			streams["week4timer6_modevalue"] = "energy"
		elseif (myTable["week4timer6ModeValue"] == 2) then
			streams["week4timer6_modevalue"] = "standard"
		elseif (myTable["week4timer6ModeValue"] == 3) then
			streams["week4timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week4timer6ModeValue"] == 4) then
			streams["week4timer6_modevalue"] = "smart"
		end
		if (myTable["week5timer1ModeValue"] == 1) then
			streams["week5timer1_modevalue"] = "energy"
		elseif (myTable["week5timer1ModeValue"] == 2) then
			streams["week5timer1_modevalue"] = "standard"
		elseif (myTable["week5timer1ModeValue"] == 3) then
			streams["week5timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer1ModeValue"] == 4) then
			streams["week5timer1_modevalue"] = "smart"
		end
		if (myTable["week5timer2ModeValue"] == 1) then
			streams["week5timer2_modevalue"] = "energy"
		elseif (myTable["week5timer2ModeValue"] == 2) then
			streams["week5timer2_modevalue"] = "standard"
		elseif (myTable["week5timer2ModeValue"] == 3) then
			streams["week5timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer2ModeValue"] == 4) then
			streams["week5timer2_modevalue"] = "smart"
		end
		if (myTable["week5timer3ModeValue"] == 1) then
			streams["week5timer3_modevalue"] = "energy"
		elseif (myTable["week5timer3ModeValue"] == 2) then
			streams["week5timer3_modevalue"] = "standard"
		elseif (myTable["week5timer3ModeValue"] == 3) then
			streams["week5timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer3ModeValue"] == 4) then
			streams["week5timer3_modevalue"] = "smart"
		end
		if (myTable["week5timer4ModeValue"] == 1) then
			streams["week5timer4_modevalue"] = "energy"
		elseif (myTable["week5timer4ModeValue"] == 2) then
			streams["week5timer4_modevalue"] = "standard"
		elseif (myTable["week5timer4ModeValue"] == 3) then
			streams["week5timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer4ModeValue"] == 4) then
			streams["week5timer4_modevalue"] = "smart"
		end
		if (myTable["week5timer5ModeValue"] == 1) then
			streams["week5timer5_modevalue"] = "energy"
		elseif (myTable["week5timer5ModeValue"] == 2) then
			streams["week5timer5_modevalue"] = "standard"
		elseif (myTable["week5timer5ModeValue"] == 3) then
			streams["week5timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer5ModeValue"] == 4) then
			streams["week5timer5_modevalue"] = "smart"
		end
		if (myTable["week5timer6ModeValue"] == 1) then
			streams["week5timer6_modevalue"] = "energy"
		elseif (myTable["week5timer6ModeValue"] == 2) then
			streams["week5timer6_modevalue"] = "standard"
		elseif (myTable["week5timer6ModeValue"] == 3) then
			streams["week5timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week5timer6ModeValue"] == 4) then
			streams["week5timer6_modevalue"] = "smart"
		end
		if (myTable["week6timer1ModeValue"] == 1) then
			streams["week6timer1_modevalue"] = "energy"
		elseif (myTable["week6timer1ModeValue"] == 2) then
			streams["week6timer1_modevalue"] = "standard"
		elseif (myTable["week6timer1ModeValue"] == 3) then
			streams["week6timer1_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer1ModeValue"] == 4) then
			streams["week6timer1_modevalue"] = "smart"
		end
		if (myTable["week6timer2ModeValue"] == 1) then
			streams["week6timer2_modevalue"] = "energy"
		elseif (myTable["week6timer2ModeValue"] == 2) then
			streams["week6timer2_modevalue"] = "standard"
		elseif (myTable["week6timer2ModeValue"] == 3) then
			streams["week6timer2_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer2ModeValue"] == 4) then
			streams["week6timer2_modevalue"] = "smart"
		end
		if (myTable["week6timer3ModeValue"] == 1) then
			streams["week6timer3_modevalue"] = "energy"
		elseif (myTable["week6timer3ModeValue"] == 2) then
			streams["week6timer3_modevalue"] = "standard"
		elseif (myTable["week6timer3ModeValue"] == 3) then
			streams["week6timer3_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer3ModeValue"] == 4) then
			streams["week6timer3_modevalue"] = "smart"
		end
		if (myTable["week6timer4ModeValue"] == 1) then
			streams["week6timer4_modevalue"] = "energy"
		elseif (myTable["week6timer4ModeValue"] == 2) then
			streams["week6timer4_modevalue"] = "standard"
		elseif (myTable["week6timer4ModeValue"] == 3) then
			streams["week6timer4_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer4ModeValue"] == 4) then
			streams["week6timer4_modevalue"] = "smart"
		end
		if (myTable["week6timer5ModeValue"] == 1) then
			streams["week6timer5_modevalue"] = "energy"
		elseif (myTable["week6timer5ModeValue"] == 2) then
			streams["week6timer5_modevalue"] = "standard"
		elseif (myTable["week6timer5ModeValue"] == 3) then
			streams["week6timer5_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer5ModeValue"] == 4) then
			streams["week6timer5_modevalue"] = "smart"
		end
		if (myTable["week6timer6ModeValue"] == 1) then
			streams["week6timer6_modevalue"] = "energy"
		elseif (myTable["week6timer6ModeValue"] == 2) then
			streams["week6timer6_modevalue"] = "standard"
		elseif (myTable["week6timer6ModeValue"] == 3) then
			streams["week6timer6_modevalue"] = "compatibilizing"
		elseif (myTable["week6timer6ModeValue"] == 4) then
			streams["week6timer6_modevalue"] = "smart"
		end
	end
	local retTable = {}
	retTable["status"] = streams
	local ret = encode(retTable)
	return ret
end
