local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_MODE = 'mode'
local KEY_HEAT = 'heat'
local KEY_SAFE = 'safe'
local KEY_PROTECT = 'protect'
local KEY_SLEEP = 'sleep'
local KEY_TEMPERATURE = 'temperature'
local KEY_CURRENT_TEMPERATURE = 'cur_temperature'
local KEY_WATER_LEVEL = 'heat_water_level'
local KEY_ERROR_CODE = 'error_code'

local VALUE_VERSION = 9
local VALUE_FUNCTION_ON = 'on'
local VALUE_FUNCTION_OFF = 'off'
local VALUE_MODE_EPLUS = 'eplus'
local VALUE_MODE_FAST_WASH = 'fast_wash'
local VALUE_MODE_SUMMER = 'summer'
local VALUE_MODE_WINTER = 'winter'
local VALUE_MODE_EFFICIENT = 'efficient'
local VALUE_MODE_NIGHT = 'night'
local VALUE_MODE_ONE_PERSON = 'one_person'
local VALUE_MODE_TWO_PERSON = 'two_person'
local VALUE_MODE_THREE_PERSON = 'three_person '
local VALUE_MODE_OLD_MAN = 'old_man'
local VALUE_MODE_ADULT = 'adult'
local VALUE_MODE_CHILDREN = 'children'
local VALUE_MODE_CLOUD = 'cloud'
local VALUE_MODE_CUSTOM = 'custom'
local VALUE_MODE_WASH = 'wash'
local VALUE_MODE_SHOWER = 'shower'
local VALUE_MODE_BATH = 'bath'
local VALUE_MODE_MEMORY = 'memory'
local VALUE_MODE_STERILIZATION = 'sterilization'
local VALUE_MODE_NONE = 'none'
local VALUE_HEAT_WHOLE = 'whole'
local VALUE_HEAT_HALF = 'half'
local VALUE_HEAT_NONE = 'none'

local BYTE_DEVICE_TYPE = 0xE2
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERYL_REQUEST = 0x03
local BYTE_AUTO_REPORT = 0x04
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local BYTE_MODE_EPLUS = 0x01
local BYTE_MODE_FAST_WASH = 0x02
local BYTE_MODE_SUMMER = 0x04
local BYTE_MODE_WINTER = 0x08
local BYTE_MODE_EFFICIENT = 0x10
local BYTE_MODE_NIGHT = 0x20
local BYTE_MODE_ONE_PERSON = 0x01
local BYTE_MODE_TWO_PERSON = 0x02
local BYTE_MODE_THREE_PERSON = 0x04
local BYTE_MODE_OLD_MAN = 0x08
local BYTE_MODE_ADULT = 0x10
local BYTE_MODE_CHILDREN = 0x20
local BYTE_MODE_CLOUD = 0x40
local BYTE_MODE_CUSTOM = 0x80
local BYTE_MODE_WASH = 0x10
local BYTE_MODE_SHOWER = 0x20
local BYTE_MODE_BATH = 0x40
local BYTE_MODE_MEMORY = 0x80
local BYTE_HEAT_HALF = 0x01
local BYTE_HEAT_WHOLE = 0x02
local BYTE_HEAT_NONE = 0x00
local BYTE_SAFE_ON = 0x40
local BYTE_SAFE_OFF = 0x00
local BYTE_PROTECT_ON = 0x80
local BYTE_PROTECT_OFF = 0x00
local BYTE_CMD_POWER_ON = 0x01
local BYTE_CMD_POWER_OFF = 0x02
local BYTE_CMD_OTHER = 0x04

local powerValue
local temperatureValue
local modeValue1 = 0
local modeValue2 = 0
local modeValue3 = 0
local modeValue4 = 0
local heatValue
local protectValue
local safeValue
local sleepValue
local currentTemperatureValue
local heatWaterLevelValue
local errorCode
local cmdTypeValue
local endTimeHour = 0
local endTimeMinute = 0
local hotPower = 0
local warmPower = 0
local fastHotPower = 0

function jsonToModel(stateJson, controlJson)
    local oldState = stateJson
    local controlCmd = controlJson
    if (controlCmd[KEY_POWER] ~= nil) then
        if (controlCmd[KEY_POWER] == VALUE_FUNCTION_ON) then
            cmdTypeValue = BYTE_CMD_POWER_ON
        else
            cmdTypeValue = BYTE_CMD_POWER_OFF
        end
    else
        cmdTypeValue = BYTE_CMD_OTHER
        modeValue1 = 0
        modeValue2 = 0
        modeValue3 = 0
        modeValue4 = 0
        local modeStr = oldState[KEY_MODE]
        if (controlCmd[KEY_MODE] ~= nil) then
            modeStr = controlCmd[KEY_MODE]
        end
        if (modeStr == VALUE_MODE_EPLUS) then
            modeValue1 = BYTE_MODE_EPLUS
        elseif (modeStr == VALUE_MODE_FAST_WASH) then
            modeValue1 = BYTE_MODE_FAST_WASH
        elseif (modeStr == VALUE_MODE_SUMMER) then
            modeValue1 = BYTE_MODE_SUMMER
        elseif (modeStr == VALUE_MODE_WINTER) then
            modeValue1 = BYTE_MODE_WINTER
        elseif (modeStr == VALUE_MODE_EFFICIENT) then
            modeValue1 = BYTE_MODE_EFFICIENT
        elseif (modeStr == VALUE_MODE_NIGHT) then
            modeValue1 = BYTE_MODE_NIGHT
        elseif (modeStr == VALUE_MODE_ONE_PERSON) then
            modeValue2 = BYTE_MODE_ONE_PERSON
        elseif (modeStr == VALUE_MODE_TWO_PERSON) then
            modeValue2 = BYTE_MODE_TWO_PERSON
        elseif (modeStr == VALUE_MODE_THREE_PERSON) then
            modeValue2 = BYTE_MODE_THREE_PERSON
        elseif (modeStr == VALUE_MODE_OLD_MAN) then
            modeValue2 = BYTE_MODE_OLD_MAN
        elseif (modeStr == VALUE_MODE_ADULT) then
            modeValue2 = BYTE_MODE_ADULT
        elseif (modeStr == VALUE_MODE_CHILDREN) then
            modeValue2 = BYTE_MODE_CHILDREN
        elseif (modeStr == VALUE_MODE_CLOUD) then
            modeValue2 = BYTE_MODE_CLOUD
        elseif (modeStr == VALUE_MODE_CUSTOM) then
            modeValue2 = BYTE_MODE_CUSTOM
        elseif (modeStr == VALUE_MODE_WASH) then
            modeValue3 = BYTE_MODE_WASH
        elseif (modeStr == VALUE_MODE_SHOWER) then
            modeValue3 = BYTE_MODE_SHOWER
        elseif (modeStr == VALUE_MODE_BATH) then
            modeValue3 = BYTE_MODE_BATH
        elseif (modeStr == VALUE_MODE_MEMORY) then
            modeValue3 = BYTE_MODE_MEMORY
        elseif (modeStr == VALUE_MODE_STERILIZATION) then
            modeValue4 = 0x02
        end
        local temperatureStr = oldState[KEY_TEMPERATURE]
        if (controlCmd[KEY_TEMPERATURE] ~= nil) then
            temperatureStr = controlCmd[KEY_TEMPERATURE]
        end
        temperatureValue = checkBoundary(temperatureStr, 30, 75)
        local heatStr = oldState[KEY_HEAT]
        if (controlCmd[KEY_HEAT] ~= nil) then
            heatStr = controlCmd[KEY_HEAT]
        end
        if (heatStr == VALUE_HEAT_WHOLE) then
            heatValue = BYTE_HEAT_WHOLE
        elseif (heatStr == VALUE_HEAT_HALF) then
            heatValue = BYTE_HEAT_HALF
        else
            heatValue = BYTE_HEAT_NONE
        end
        local safeStr = oldState[KEY_SAFE]
        if (controlCmd[KEY_SAFE] ~= nil) then
            safeStr = controlCmd[KEY_SAFE]
        end
        if (safeStr == VALUE_FUNCTION_ON) then
            safeValue = 0x08
        else
            safeValue = 0x00
        end
        local protectStr = oldState[KEY_PROTECT]
        if (controlCmd[KEY_PROTECT] ~= nil) then
            protectStr = controlCmd[KEY_PROTECT]
        end
        if (protectStr == VALUE_FUNCTION_ON) then
            protectValue = 0x04
        else
            protectValue = 0x00
        end
        local sleepStr = oldState[KEY_SLEEP]
        if (controlCmd[KEY_SLEEP] ~= nil) then
            sleepStr = controlCmd[KEY_SLEEP]
        end
        if (sleepStr == VALUE_FUNCTION_ON) then
            sleepValue = 0x04
        else
            sleepValue = 0x00
        end
    end
end

function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = {}
    for i = 0, 23 do messageBytes[i] = 0 end
    for i = 0, #binData do messageBytes[i] = binData[i] end
    powerValue = bit.band(messageBytes[2], 0x01)
    modeValue4 = bit.band(messageBytes[2], 0x40)
    currentTemperatureValue = messageBytes[4]
    heatWaterLevelValue = messageBytes[5]
    modeValue1 = bit.band(messageBytes[7], 0xF3)
    heatValue = bit.band(messageBytes[7], 0x0C)
    modeValue2 = bit.band(messageBytes[8], 0x27)
    sleepValue = bit.band(messageBytes[8], 0x10)
    temperatureValue = messageBytes[11]
    protectValue = bit.band(messageBytes[22], 0x02)
    safeValue = bit.band(messageBytes[22], 0x04)
    modeValue3 = bit.band(messageBytes[23], 0x0F)
    errorCode = messageBytes[3]
    endTimeHour = messageBytes[9]
    endTimeMinute = messageBytes[10]
    hotPower = bit.band(messageBytes[2], 0x04)
    warmPower = bit.band(messageBytes[2], 0x08)
    fastHotPower = bit.band(messageBytes[2], 0x02)
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    local infoM = {}
    local bodyBytes = {}
    if (query) then
        bodyBytes[0] = 0x01
        bodyBytes[1] = 0x01
        infoM = getTotalMsg(bodyBytes, BYTE_QUERYL_REQUEST)
    elseif (control) then
        jsonToModel(status, control)
        if (control[KEY_POWER] ~= nil) then
            bodyBytes[0] = cmdTypeValue
            bodyBytes[1] = 0x01
            infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
        else
            for i = 0, 20 do bodyBytes[i] = 0 end
            if ((heatValue == BYTE_HEAT_HALF) and (deviceSubType == '23')) then
                print('Y')
                bodyBytes[2] = 0x10
                heatValue = 0x00
                modeValue3 = 0x00
            else
                bodyBytes[2] = modeValue1
            end
            bodyBytes[0] = cmdTypeValue
            bodyBytes[1] = 0x01
            bodyBytes[3] = modeValue2
            bodyBytes[4] = bit.bor(bit.bor(bit.bor(modeValue3, heatValue),
                safeValue), protectValue)
            bodyBytes[5] = temperatureValue
            bodyBytes[9] = bit.bor(modeValue4, sleepValue)
            infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
        end
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[9] = cType
    for i = 0, bodyLength do msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyData[i] end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
end

function dataToJson(jsonCmd)
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceinfo = json['deviceinfo']
    local deviceSubType = deviceinfo['deviceSubType']
    if (deviceSubType == 1) then end
    local binData = json['msg']['data']
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    local msgType = 0
    local msgSubType = 0
    info = string2table(binData)
    if (#info < 11) then return nil end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    msgType = msgBytes[9]
    msgSubType = msgBytes[10]
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then end
    if (((msgType == BYTE_CONTROL_REQUEST) and (msgSubType == 0x01)) or
            ((msgType == BYTE_CONTROL_REQUEST) and (msgSubType == 0x02)) or
            ((msgType == BYTE_CONTROL_REQUEST) and (msgSubType == 0x04)) or
            ((msgType == BYTE_QUERYL_REQUEST) and (msgSubType == 0x01)) or
            ((msgType == BYTE_AUTO_REPORT) and (msgSubType == 0x01))) then
        for i = 0, bodyLength do
            bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
        end
        binToModel(bodyBytes)
        local streams = {}
        streams[KEY_VERSION] = VALUE_VERSION
        if (powerValue == BYTE_POWER_ON) then
            streams[KEY_POWER] = VALUE_FUNCTION_ON
        elseif (powerValue == BYTE_POWER_OFF) then
            streams[KEY_POWER] = VALUE_FUNCTION_OFF
        end
        streams[KEY_TEMPERATURE] = temperatureValue
        streams[KEY_CURRENT_TEMPERATURE] = currentTemperatureValue
        streams[KEY_WATER_LEVEL] = heatWaterLevelValue
        streams['end_time_hour'] = endTimeHour
        streams['end_time_minute'] = endTimeMinute
        local modeStr = VALUE_MODE_NONE
        if (modeValue3 == 0x01) then
            modeStr = VALUE_MODE_WASH
        elseif (modeValue3 == 0x02) then
            modeStr = VALUE_MODE_SHOWER
        elseif (modeValue3 == 0x04) then
            modeStr = VALUE_MODE_BATH
        elseif (modeValue3 == 0x08) then
            modeStr = VALUE_MODE_MEMORY
        end
        if (modeValue2 == 0x01) then
            modeStr = VALUE_MODE_ONE_PERSON
        elseif (modeValue2 == 0x02) then
            modeStr = VALUE_MODE_TWO_PERSON
        elseif (modeValue2 == 0x03) then
            modeStr = VALUE_MODE_THREE_PERSON
        elseif (modeValue2 == 0x04) then
            modeStr = VALUE_MODE_OLD_MAN
        elseif (modeValue2 == 0x05) then
            modeStr = VALUE_MODE_ADULT
        elseif (modeValue2 == 0x06) then
            modeStr = VALUE_MODE_CHILDREN
        elseif (modeValue2 == 0x20) then
            modeStr = VALUE_MODE_CLOUD
        end
        if (modeValue1 == 0x01) then
            modeStr = VALUE_MODE_EPLUS
        elseif (modeValue1 == 0x02) then
            modeStr = VALUE_MODE_FAST_WASH
        elseif (modeValue1 == 0x10) then
            modeStr = VALUE_MODE_SUMMER
        elseif (modeValue1 == 0x20) then
            modeStr = VALUE_MODE_WINTER
        elseif (modeValue1 == 0x40) then
            modeStr = VALUE_MODE_EFFICIENT
        elseif (modeValue1 == 0x80) then
            modeStr = VALUE_MODE_NIGHT
        end
        if (modeValue4 == 0x40) then modeStr = VALUE_MODE_STERILIZATION end
        streams[KEY_MODE] = modeStr
        if (heatValue == 0x04) then
            streams[KEY_HEAT] = VALUE_HEAT_HALF
        elseif (heatValue == 0x08) then
            streams[KEY_HEAT] = VALUE_HEAT_WHOLE
        else
            streams[KEY_HEAT] = VALUE_HEAT_NONE
        end
        if (protectValue == BYTE_PROTECT_OFF) then
            streams[KEY_PROTECT] = VALUE_FUNCTION_OFF
        else
            streams[KEY_PROTECT] = VALUE_FUNCTION_ON
        end
        if (safeValue == BYTE_SAFE_OFF) then
            streams[KEY_SAFE] = VALUE_FUNCTION_OFF
        else
            streams[KEY_SAFE] = VALUE_FUNCTION_ON
        end
        if (sleepValue == 0x00) then
            streams[KEY_SLEEP] = VALUE_FUNCTION_OFF
        else
            streams[KEY_SLEEP] = VALUE_FUNCTION_ON
        end
        if (bit.band(errorCode, 0x01) == 0x01) then
            streams[KEY_ERROR_CODE] = 0x01
        elseif (bit.band(errorCode, 0x02) == 0x02) then
            streams[KEY_ERROR_CODE] = 0x02
        elseif (bit.band(errorCode, 0x04) == 0x04) then
            streams[KEY_ERROR_CODE] = 0x04
        elseif (bit.band(errorCode, 0x08) == 0x08) then
            streams[KEY_ERROR_CODE] = 0x08
        elseif (bit.band(errorCode, 0x10) == 0x10) then
            streams[KEY_ERROR_CODE] = 0x10
        elseif (bit.band(errorCode, 0x20) == 0x20) then
            streams[KEY_ERROR_CODE] = 0x20
        elseif (bit.band(errorCode, 0x40) == 0x40) then
            streams[KEY_ERROR_CODE] = 0x40
        elseif (bit.band(errorCode, 0x80) == 0x80) then
            streams[KEY_ERROR_CODE] = 0x80
        end
        if (hotPower == 0x00) then
            streams['hot_power'] = 'off'
        else
            streams['hot_power'] = 'on'
        end
        if (warmPower == 0x00) then
            streams['warm_power'] = 'off'
        else
            streams['warm_power'] = 'on'
        end
        if (fastHotPower == 0x00) then
            streams['fast_hot_power'] = 'off'
        else
            streams['fast_hot_power'] = 'on'
        end
        local retTable = {}
        retTable['status'] = streams
        local ret = encode(retTable)
        return ret
    end
end

function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == 'string' then k = string.format('%q', k) end
        local szSuffix = ''
        if type(v) == 'table' then szSuffix = '{' end
        local szPrefix = string.rep('    ', indent)
        formatting = szPrefix .. '[' .. k .. ']' .. ' = ' .. szSuffix
        if type(v) == 'table' then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix .. '},')
        else
            local szValue = ''
            if type(v) == 'string' then
                szValue = string.format('%q', v)
            else
                szValue = tostring(v)
            end
            print(formatting .. szValue .. ',')
        end
    end
end

function checkBoundary(data, min, max)
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

function table2string(cmd)
    local ret = ''
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end

function string2table(hexstr)
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

function string2hexstring(str)
    local ret = ''
    for i = 1, #str do ret = ret .. string.format('%02x', str:byte(i)) end
    return ret
end

function encode(cmd)
    local tb
    if JSON == nil then JSON = require 'cjson' end
    tb = JSON.encode(cmd)
    return tb
end

function decode(cmd)
    local tb
    if JSON == nil then JSON = require 'cjson' end
    tb = JSON.decode(cmd)
    return tb
end

function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    resVal = 255 - resVal + 1
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

function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end
