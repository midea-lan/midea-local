local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_MODE = 'mode'
local KEY_GEAR = 'gear'
local KEY_HUMIDITY = 'humidity'
local KEY_HUMIDITY_MODE = 'humidity_mode'
local KEY_TEMPERATURE = 'temperature'
local KEY_CUR_HUMIDITY = 'cur_humidity'
local KEY_CUR_TEMPERATURE = 'cur_temperature'
local KEY_LOCK = 'lock'

local VALUE_VERSION = 3
local VALUE_FUNCTION_ON = 'on'
local VALUE_FUNCTION_OFF = 'off'
local VALUE_FUNCTION_INVALID = 'invalid'
local VALUE_MODE_INTELLIGENT = 'intelligent'
local VALUE_MODE_EFFICIENT = 'efficient'
local VALUE_MODE_SLEEP = 'sleep'
local VALUE_MODE_ANTI_FREEZING = 'antifreezing'
local VALUE_MODE_COMFORT = 'comfort'
local VALUE_MODE_CONSTANT_TEMPERATURE = 'constant_temperature'
local VALUE_MODE_NORMAL = 'normal'
local VALUE_MODE_FAST_HOT = 'fast_hot'
local VALUE_MODE_CUSTOM = 'custom'
local VALUE_MODE_CLOSE = 'close'
local VALUE_MODE_CONST = 'const'
local VALUE_MODE_ONE = 'one'
local VALUE_MODE_TWO = 'two'
local VALUE_MODE_THREE = 'three'

local BYTE_DEVICE_TYPE = 0xFB
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERYL_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x02
local BYTE_LOCK_OFF = 0x00
local BYTE_LOCK_ON = 0x01
local BYTE_LOCK_INVALID = 0xFF
local BYTE_MODE_INVALID = 0x00
local BYTE_MODE_INTELLIGENT = 0x01
local BYTE_MODE_EFFICIENT = 0x02
local BYTE_MODE_SLEEP = 0x03
local BYTE_MODE_ANTI_FREEZING = 0x04
local BYTE_MODE_COMFORT = 0x05
local BYTE_MODE_CONSTANT_TEMPERATURE = 0x06
local BYTE_MODE_NORMAL = 0x07
local BYTE_MODE_FAST_HOT = 0x08
local BYTE_MODE_CUSTOM = 0x09
local BYTE_MODE_HUMIDITY_INVALID = 0x00
local BYTE_MODE_HUMIDITY_CLOSE = 0x10
local BYTE_MODE_HUMIDITY_CONST = 0x20
local BYTE_MODE_HUMIDITY_ONE = 0x30
local BYTE_MODE_HUMIDITY_TWO = 0x40
local BYTE_MODE_HUMIDITY_THREE = 0x50

local powerValue
local modeValue
local gearValue
local temperatureValue
local humidityValue
local humidityModeValue
local lockValue
local curTemperatureValue
local curHumidityValue

function jsonToModel(stateJson, controlJson)
    local oldState = stateJson
    local controlCmd = controlJson
    local temValue = oldState[KEY_POWER]
    if (controlCmd[KEY_POWER] ~= nil) then temValue = controlCmd[KEY_POWER] end
    if (temValue == VALUE_FUNCTION_ON) then
        powerValue = BYTE_POWER_ON
    elseif (temValue == VALUE_FUNCTION_OFF) then
        powerValue = BYTE_POWER_OFF
    end
    temValue = oldState[KEY_GEAR]
    if (controlCmd[KEY_GEAR] ~= nil) then temValue = controlCmd[KEY_GEAR] end
    if (temValue == VALUE_FUNCTION_INVALID) then
        gearValue = 0x00
    else
        gearValue = checkBoundary(temValue, 0, 10)
    end
    temValue = oldState[KEY_TEMPERATURE]
    if (controlCmd[KEY_TEMPERATURE] ~= nil) then
        temValue = controlCmd[KEY_TEMPERATURE]
    end
    if (temValue == VALUE_FUNCTION_INVALID) then
        temperatureValue = 0x00
    else
        temperatureValue = checkBoundary(temValue, -40, 50)
    end
    temValue = oldState[KEY_HUMIDITY]
    if (controlCmd[KEY_HUMIDITY] ~= nil) then
        temValue = controlCmd[KEY_HUMIDITY]
    end
    if (temValue == VALUE_FUNCTION_INVALID) then
        humidityValue = 0x00
    else
        humidityValue = checkBoundary(temValue, 1, 100)
    end
    temValue = oldState[KEY_MODE]
    if (controlCmd[KEY_MODE] ~= nil) then temValue = controlCmd[KEY_MODE] end
    if (temValue == VALUE_MODE_INTELLIGENT) then
        modeValue = BYTE_MODE_INTELLIGENT
    elseif (temValue == VALUE_MODE_EFFICIENT) then
        modeValue = BYTE_MODE_EFFICIENT
    elseif (temValue == VALUE_MODE_SLEEP) then
        modeValue = BYTE_MODE_SLEEP
    elseif (temValue == VALUE_MODE_ANTI_FREEZING) then
        modeValue = BYTE_MODE_ANTI_FREEZING
    elseif (temValue == VALUE_MODE_COMFORT) then
        modeValue = BYTE_MODE_COMFORT
    elseif (temValue == VALUE_MODE_CONSTANT_TEMPERATURE) then
        modeValue = BYTE_MODE_CONSTANT_TEMPERATURE
    elseif (temValue == VALUE_MODE_NORMAL) then
        modeValue = BYTE_MODE_NORMAL
    elseif (temValue == VALUE_MODE_FAST_HOT) then
        modeValue = BYTE_MODE_FAST_HOT
    elseif (temValue == VALUE_MODE_CUSTOM) then
        modeValue = BYTE_MODE_CUSTOM
    else
        modeValue = BYTE_MODE_INVALID
    end
    temValue = oldState[KEY_HUMIDITY_MODE]
    if (controlCmd[KEY_HUMIDITY_MODE] ~= nil) then
        temValue = controlCmd[KEY_HUMIDITY_MODE]
    end
    if (temValue == VALUE_MODE_CLOSE) then
        humidityModeValue = BYTE_MODE_HUMIDITY_CLOSE
    elseif (temValue == VALUE_MODE_CONST) then
        humidityModeValue = BYTE_MODE_HUMIDITY_CONST
    elseif (temValue == VALUE_MODE_ONE) then
        humidityModeValue = BYTE_MODE_HUMIDITY_ONE
    elseif (temValue == VALUE_MODE_TWO) then
        humidityModeValue = BYTE_MODE_HUMIDITY_TWO
    elseif (temValue == VALUE_MODE_THREE) then
        humidityModeValue = BYTE_MODE_HUMIDITY_THREE
    else
        humidityModeValue = BYTE_MODE_HUMIDITY_INVALID
    end
    local temValue = oldState[KEY_LOCK]
    if (controlCmd[KEY_LOCK] ~= nil) then temValue = controlCmd[KEY_LOCK] end
    if (temValue == VALUE_FUNCTION_ON) then
        lockValue = BYTE_LOCK_ON
    elseif (temValue == VALUE_FUNCTION_OFF) then
        lockValue = BYTE_LOCK_OFF
    elseif (temValue == VALUE_FUNCTION_INVALID) then
        lockValue = BYTE_LOCK_INVALID
    end
end

function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = binData
    powerValue = messageBytes[0]
    modeValue = messageBytes[4]
    gearValue = messageBytes[5]
    temperatureValue = messageBytes[6] - 41
    humidityValue = messageBytes[7]
    humidityModeValue = bit.band(messageBytes[9], 0xF0)
    curHumidityValue = messageBytes[12]
    curTemperatureValue = messageBytes[13] - 41
    lockValue = messageBytes[18]
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    local bodyLength = 0
    if (query) then
        bodyLength = 0
    elseif (control) then
        bodyLength = 19
    end
    local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    local bodyBytes = {}
    for i = 0, bodyLength do bodyBytes[i] = 0 end
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    if (query) then
        msgBytes[9] = BYTE_QUERYL_REQUEST
    elseif (control) then
        if (control and status) then jsonToModel(status, control) end
        bodyBytes[0] = powerValue
        bodyBytes[4] = modeValue
        bodyBytes[5] = gearValue
        bodyBytes[6] = temperatureValue + 41
        bodyBytes[7] = humidityValue
        bodyBytes[9] = humidityModeValue
        bodyBytes[18] = lockValue
        msgBytes[9] = BYTE_CONTROL_REQUEST
    end
    for i = 0, bodyLength do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local infoM = {}
    for i = 1, msgLength + 1 do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
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
    info = string2table(binData)
    local dataType = info[10]
    if ((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04)) then
        return nil
    end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then end
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    binToModel(bodyBytes)
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (powerValue == BYTE_POWER_ON) then
        streams[KEY_POWER] = VALUE_FUNCTION_ON
    else
        streams[KEY_POWER] = VALUE_FUNCTION_OFF
    end
    if (lockValue == BYTE_LOCK_ON) then
        streams[KEY_LOCK] = VALUE_FUNCTION_ON
    elseif (lockValue == BYTE_LOCK_OFF) then
        streams[KEY_LOCK] = VALUE_FUNCTION_OFF
    else
        streams[KEY_LOCK] = VALUE_FUNCTION_INVALID
    end
    if (gearValue == 0) then
        streams[KEY_GEAR] = VALUE_FUNCTION_INVALID
    else
        streams[KEY_GEAR] = gearValue
    end
    if (modeValue == BYTE_MODE_INTELLIGENT) then
        streams[KEY_MODE] = VALUE_MODE_INTELLIGENT
    elseif (modeValue == BYTE_MODE_EFFICIENT) then
        streams[KEY_MODE] = VALUE_MODE_EFFICIENT
    elseif (modeValue == BYTE_MODE_SLEEP) then
        streams[KEY_MODE] = VALUE_MODE_SLEEP
    elseif (modeValue == BYTE_MODE_ANTI_FREEZING) then
        streams[KEY_MODE] = VALUE_MODE_ANTI_FREEZING
    elseif (modeValue == BYTE_MODE_COMFORT) then
        streams[KEY_MODE] = VALUE_MODE_COMFORT
    elseif (modeValue == BYTE_MODE_CONSTANT_TEMPERATURE) then
        streams[KEY_MODE] = VALUE_MODE_CONSTANT_TEMPERATURE
    elseif (modeValue == BYTE_MODE_NORMAL) then
        streams[KEY_MODE] = VALUE_MODE_NORMAL
    elseif (modeValue == BYTE_MODE_FAST_HOT) then
        streams[KEY_MODE] = VALUE_MODE_FAST_HOT
    elseif (modeValue == BYTE_MODE_CUSTOM) then
        streams[KEY_MODE] = VALUE_MODE_CUSTOM
    else
        streams[KEY_MODE] = VALUE_FUNCTION_INVALID
    end
    if (humidityModeValue == BYTE_MODE_HUMIDITY_CLOSE) then
        streams[KEY_HUMIDITY_MODE] = VALUE_MODE_CLOSE
    elseif (humidityModeValue == BYTE_MODE_HUMIDITY_CONST) then
        streams[KEY_HUMIDITY_MODE] = VALUE_MODE_CONST
    elseif (humidityModeValue == BYTE_MODE_HUMIDITY_ONE) then
        streams[KEY_HUMIDITY_MODE] = VALUE_MODE_ONE
    elseif (humidityModeValue == BYTE_MODE_HUMIDITY_TWO) then
        streams[KEY_HUMIDITY_MODE] = VALUE_MODE_TWO
    elseif (humidityModeValue == BYTE_MODE_HUMIDITY_THREE) then
        streams[KEY_HUMIDITY_MODE] = VALUE_MODE_THREE
    else
        streams[KEY_HUMIDITY_MODE] = VALUE_FUNCTION_INVALID
    end
    if (temperatureValue == 0) then
        streams[KEY_TEMPERATURE] = VALUE_FUNCTION_INVALID
    else
        streams[KEY_TEMPERATURE] = temperatureValue
    end
    if (humidityValue == 0) then
        streams[KEY_HUMIDITY] = VALUE_FUNCTION_INVALID
    else
        streams[KEY_HUMIDITY] = humidityValue
    end
    if (curTemperatureValue == 0) then
        streams[KEY_CUR_TEMPERATURE] = VALUE_FUNCTION_INVALID
    else
        streams[KEY_CUR_TEMPERATURE] = curTemperatureValue
    end
    if (curHumidityValue == 0) then
        streams[KEY_CUR_HUMIDITY] = VALUE_FUNCTION_INVALID
    else
        streams[KEY_CUR_HUMIDITY] = curHumidityValue
    end
    local retTable = {}
    retTable['status'] = streams
    local ret = encode(retTable)
    return ret
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
