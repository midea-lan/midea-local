local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_WORK_STATUS = 'work_status'
local KEY_WORK_MODE = 'work_mode'
local KEY_WORK_HOUR = 'work_hour'
local KEY_WORK_MINUTE = 'work_minute'
local KEY_LOCK = 'lock'
local KEY_TEMPERATURE = 'temperature'
local KEY_DOOR_STATE = 'door_state'
local KEY_BOX_STATE = 'box_state'
local KEY_WATER_STATE = 'water_state'

local VALUE_VERSION = 3
local VALUE_INVALID = 'invalid'
local VALUE_STATUS_STANDBY = 'standby'
local VALUE_STATUS_WORK = 'work'
local VALUE_STATUS_PAUSE = 'pause'
local VALUE_STATUS_SAVE_POWER = 'save_power'
local VALUE_STATUS_SAVE_RESERVATION = 'reservation'
local VALUE_STATUS_NONE = 'none'
local VALUE_STATUS_WORK_FINISH = 'work_finish'
local VALUE_MODE_FISH = 'fish'
local VALUE_MODE_MEAT = 'meat'
local VALUE_MODE_EGG = 'egg'
local VALUE_MODE_SEA_FOOD = 'seafood'
local VALUE_MODE_GRAIN = 'grain'
local VALUE_MODE_RICE = 'rice'
local VALUE_MODE_VEGETABLE = 'vegetable'
local VALUE_MODE_CHOP = 'chop'
local VALUE_MODE_UNFREEZE = 'unfreeze'
local VALUE_MODE_KEEP_WARM = 'keep_warm'
local VALUE_MODE_STEAM_CLEAN = 'steam_clean'
local VALUE_MODE_COMMON = 'common'
local VALUE_MODE_ZYMOSIS = 'zymosis'
local VALUE_MODE_HEAT = 'heat'
local VALUE_MODE_FURRING_CLEAN = 'furring_clean'
local VALUE_MODE_DISINFECT = 'disinfect'
local VALUE_FUNCTION_ON = 'on'
local VALUE_FUNCTION_OFF = 'off'
local VALUE_STATE_EMPTY = 'empty'
local VALUE_STATE_FULL = 'full'
local VALUE_STATE_IN = 'in'
local VALUE_STATE_OUT = 'out'
local VALUE_STATE_OPEN = 'open'
local VALUE_STATE_CLOSE = 'close'

local BYTE_DEVICE_TYPE = 0xB2
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_TEMPERATURE_DEFAULT = 100
local BYTE_HOUR_DEFAULT = 0
local BYTE_MINUTE_DEFAULT = 30
local BYTE_STANDBY = 0x01
local BYTE_WORK = 0x02
local BYTE_PAUSE = 0x03
local BYTE_NONE = 0xFF
local BYTE_RESERVATION = 0x06
local BYTE_SAVE_POWER = 0x07
local BYTE_FINISH = 0x04
local BYTE_MODE_FISH = 0x03
local BYTE_MODE_MEAT = 0x04
local BYTE_MODE_EGG = 0x05
local BYTE_MODE_SEAFOOD = 0x06
local BYTE_MODE_GRAIN = 0x09
local BYTE_MODE_RICE = 0x0a
local BYTE_MODE_VEGETABLE = 0x71
local BYTE_MODE_CHOP = 0x72
local BYTE_MODE_UNFREEZE = 0x01
local BYTE_MODE_KEEP_WARM = 0x02
local BYTE_MODE_KEEP_STEAM_CLEAN = 0x07
local BYTE_MODE_COMMON = 0x08
local BYTE_MODE_ZYMOSIS = 0x0D
local BYTE_MODE_HEAT = 0x0E
local BYTE_MODE_FURRING_CLEAN = 0x0F
local BYTE_MODE_DISINFECT = 0x10
local BYTE_LOCK_ON = 0x01
local BYTE_LOCK_OFF = 0x00
local BYTE_RECIPES_FINISH = 0x66

local workStatusValue
local workModeValue
local workHourValue = 0
local workMinuteValue = 0
local temperatureValue = -1
local lockValue
local boxStateValue
local doorStateVale
local waterStateValue

function jsonToModel(stateJson, controlJson)
    local oldState = stateJson
    local controlCmd = controlJson
    local temValue = oldState[KEY_LOCK]
    if (controlCmd[KEY_LOCK] ~= nil) then temValue = controlCmd[KEY_LOCK] end
    if (temValue == VALUE_FUNCTION_ON) then
        lockValue = BYTE_LOCK_ON
    else
        lockValue = BYTE_LOCK_OFF
    end
    local temValue = oldState[KEY_TEMPERATURE]
    if (controlCmd[KEY_TEMPERATURE] ~= nil) then
        temValue = controlCmd[KEY_TEMPERATURE]
    end
    temperatureValue = checkBoundary(controlCmd[KEY_TEMPERATURE], 50, 100)
    temValue = oldState[KEY_WORK_HOUR]
    if (controlCmd[KEY_WORK_HOUR] ~= nil) then
        temValue = controlCmd[KEY_WORK_HOUR]
    end
    workHourValue = checkBoundary(controlCmd[KEY_WORK_HOUR], 0, 9)
    temValue = oldState[KEY_WORK_MINUTE]
    if (controlCmd[KEY_WORK_MINUTE] ~= nil) then
        temValue = controlCmd[KEY_WORK_MINUTE]
    end
    workMinuteValue = checkBoundary(controlCmd[KEY_WORK_MINUTE], 0, 59)
    temValue = oldState[KEY_WORK_MODE]
    if (controlCmd[KEY_WORK_MODE] ~= nil) then
        temValue = controlCmd[KEY_WORK_MODE]
    end
    if (temValue == VALUE_MODE_FISH) then
        workModeValue = BYTE_MODE_FISH
    elseif (temValue == VALUE_MODE_MEAT) then
        workModeValue = BYTE_MODE_MEAT
    elseif (temValue == VALUE_MODE_EGG) then
        workModeValue = BYTE_MODE_EGG
    elseif (temValue == VALUE_MODE_SEA_FOOD) then
        workModeValue = BYTE_MODE_SEAFOOD
    elseif (temValue == VALUE_MODE_GRAIN) then
        workModeValue = BYTE_MODE_GRAIN
    elseif (temValue == VALUE_MODE_RICE) then
        workModeValue = BYTE_MODE_RICE
    elseif (temValue == VALUE_MODE_VEGETABLE) then
        workModeValue = BYTE_MODE_VEGETABLE
    elseif (temValue == VALUE_MODE_CHOP) then
        workModeValue = BYTE_MODE_CHOP
    elseif (temValue == VALUE_MODE_UNFREEZE) then
        workModeValue = BYTE_MODE_UNFREEZE
    elseif (temValue == VALUE_MODE_KEEP_WARM) then
        workModeValue = BYTE_MODE_KEEP_WARM
    elseif (temValue == VALUE_MODE_STEAM_CLEAN) then
        workModeValue = BYTE_MODE_KEEP_STEAM_CLEAN
    elseif (temValue == VALUE_MODE_COMMON) then
        workModeValue = BYTE_MODE_COMMON
    elseif (temValue == VALUE_MODE_ZYMOSIS) then
        workModeValue = BYTE_MODE_ZYMOSIS
    elseif (temValue == VALUE_MODE_HEAT) then
        workModeValue = BYTE_MODE_HEAT
    elseif (temValue == VALUE_MODE_FURRING_CLEAN) then
        workModeValue = BYTE_MODE_FURRING_CLEAN
    elseif (temValue == VALUE_MODE_DISINFECT) then
        workModeValue = BYTE_MODE_DISINFECT
    else
        workModeValue = BYTE_MODE_COMMON
    end
    local temValue = oldState[KEY_WORK_STATUS]
    if (controlCmd[KEY_WORK_STATUS] ~= nil) then
        temValue = controlCmd[KEY_WORK_STATUS]
    end
    if (temValue == VALUE_STATUS_STANDBY) then
        workStatusValue = BYTE_STANDBY
    elseif (temValue == VALUE_STATUS_WORK) then
        workStatusValue = BYTE_WORK
    elseif (temValue == VALUE_STATUS_PAUSE) then
        workStatusValue = BYTE_PAUSE
    elseif (temValue == VALUE_STATUS_SAVE_POWER) then
        workStatusValue = BYTE_SAVE_POWER
    elseif (temValue == VALUE_STATUS_SAVE_RESERVATION) then
        workStatusValue = BYTE_RESERVATION
    elseif (temValue == VALUE_STATUS_NONE) then
        workStatusValue = BYTE_NONE
    else
        workStatusValue = BYTE_STANDBY
    end
    if ((workHourValue == 0) and (workMinuteValue == 0)) then
        workMinuteValue = BYTE_MINUTE_DEFAULT
    end
end

function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = binData
    workStatusValue = messageBytes[0]
    workModeValue = messageBytes[1]
    workHourValue = messageBytes[2]
    workMinuteValue = messageBytes[3]
    temperatureValue = messageBytes[4]
    boxStateValue = bit.band(messageBytes[6], 0x01)
    waterStateValue = bit.band(messageBytes[6], 0x02)
    doorStateVale = bit.band(messageBytes[6], 0x07)
    lockValue = messageBytes[16]
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
        bodyLength = 15
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
        msgBytes[9] = BYTE_QUERY_REQUEST
    elseif (control) then
        if (control and status) then jsonToModel(status, control) end
        bodyBytes[0] = workStatusValue
        bodyBytes[1] = workModeValue
        bodyBytes[2] = workHourValue
        bodyBytes[3] = workMinuteValue
        bodyBytes[4] = temperatureValue
        bodyBytes[14] = lockValue
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
    if (workStatusValue == BYTE_STANDBY) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_STANDBY
    elseif (workStatusValue == BYTE_WORK) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_WORK
    elseif (workStatusValue == BYTE_PAUSE) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_PAUSE
    elseif (workStatusValue == BYTE_NONE) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_NONE
    elseif (workStatusValue == BYTE_RESERVATION) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_SAVE_RESERVATION
    elseif (workStatusValue == BYTE_SAVE_POWER) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_SAVE_POWER
    elseif (workStatusValue == BYTE_FINISH) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_WORK_FINISH
    else
        streams[KEY_WORK_STATUS] = VALUE_INVALID
    end
    if (workModeValue == BYTE_MODE_FISH) then
        streams[KEY_WORK_MODE] = VALUE_MODE_FISH
    elseif (workModeValue == BYTE_MODE_MEAT) then
        streams[KEY_WORK_MODE] = VALUE_MODE_MEAT
    elseif (workModeValue == BYTE_MODE_EGG) then
        streams[KEY_WORK_MODE] = VALUE_MODE_EGG
    elseif (workModeValue == BYTE_MODE_SEAFOOD) then
        streams[KEY_WORK_MODE] = VALUE_MODE_SEA_FOOD
    elseif (workModeValue == BYTE_MODE_GRAIN) then
        streams[KEY_WORK_MODE] = VALUE_MODE_GRAIN
    elseif (workModeValue == BYTE_MODE_RICE) then
        streams[KEY_WORK_MODE] = VALUE_MODE_RICE
    elseif (workModeValue == BYTE_MODE_VEGETABLE) then
        streams[KEY_WORK_MODE] = VALUE_MODE_VEGETABLE
    elseif (workModeValue == BYTE_MODE_CHOP) then
        streams[KEY_WORK_MODE] = VALUE_MODE_CHOP
    elseif (workModeValue == BYTE_MODE_UNFREEZE) then
        streams[KEY_WORK_MODE] = VALUE_MODE_UNFREEZE
    elseif (workModeValue == BYTE_MODE_KEEP_WARM) then
        streams[KEY_WORK_MODE] = VALUE_MODE_KEEP_WARM
    elseif (workModeValue == BYTE_MODE_KEEP_STEAM_CLEAN) then
        streams[KEY_WORK_MODE] = VALUE_MODE_STEAM_CLEAN
    elseif (workModeValue == BYTE_MODE_COMMON) then
        streams[KEY_WORK_MODE] = VALUE_MODE_COMMON
    elseif (workModeValue == BYTE_MODE_ZYMOSIS) then
        streams[KEY_WORK_MODE] = VALUE_MODE_ZYMOSIS
    elseif (workModeValue == BYTE_MODE_HEAT) then
        streams[KEY_WORK_MODE] = VALUE_MODE_HEAT
    elseif (workModeValue == BYTE_MODE_FURRING_CLEAN) then
        streams[KEY_WORK_MODE] = VALUE_MODE_FURRING_CLEAN
    elseif (workModeValue == BYTE_MODE_DISINFECT) then
        streams[KEY_WORK_MODE] = VALUE_MODE_DISINFECT
    else
        streams[KEY_WORK_MODE] = VALUE_INVALID
    end
    if (doorStateVale == 0x00) then
        streams[KEY_DOOR_STATE] = VALUE_STATE_CLOSE
    else
        streams[KEY_DOOR_STATE] = VALUE_STATE_OPEN
    end
    if (waterStateValue == 0x00) then
        streams[KEY_WATER_STATE] = VALUE_STATE_FULL
    else
        streams[KEY_WATER_STATE] = VALUE_STATE_EMPTY
    end
    if (boxStateValue == 0x00) then
        streams[KEY_BOX_STATE] = VALUE_STATE_IN
    else
        streams[KEY_BOX_STATE] = VALUE_STATE_OUT
    end
    if (lockValue == BYTE_LOCK_ON) then
        streams[KEY_LOCK] = VALUE_FUNCTION_ON
    else
        streams[KEY_LOCK] = VALUE_FUNCTION_OFF
    end
    streams[KEY_WORK_HOUR] = workHourValue
    streams[KEY_WORK_MINUTE] = workMinuteValue
    streams[KEY_TEMPERATURE] = temperatureValue
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
