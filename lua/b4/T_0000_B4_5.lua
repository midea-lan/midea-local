local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_WORK_STATUS = 'work_status'
local KEY_WORK_MODE = 'work_mode'
local KEY_WORK_HOUR = 'work_hour'
local KEY_WORK_MINUTE = 'work_minute'
local KEY_WORK_SECOND = 'work_second'
local KEY_TEMPERATURE = 'temperature'
local KEY_TUBE_TEMPERATURE = 'underside_tube_temperature'
local KEY_CUR_TEMPERATURE_ABOVE = 'cur_temperature_above'
local KEY_CUR_TEMPERATURE_UNDERSIDE = 'cur_temperature_underside'
local KEY_LOCK = 'lock'
local KEY_ERROR_CODE = 'error_code'
local VALUE_VERSION = 5
local VALUE_INVALID = 'invalid'
local VALUE_STANDBY = 'standby'
local VALUE_WORK = 'work'
local VALUE_SAVE_POWER = 'save_power'
local VALUE_PREHEAT = 'preheat'
local VALUE_PREHEATING = 'preheating'
local VALUE_PREHEAT_FINISH = 'preheat_finish'
local VALUE_WORK_FINISH = 'work_finish'
local VALUE_RECIPES_FINISH = 'recipes_finish'
local VALUE_ON = 'on'
local VALUE_OFF = 'off'

local BYTE_DEVICE_TYPE = 0xB4
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_TEMPERATURE_DEFAULT = 180
local BYTE_TEMPERATURE_ZYMOSIS = 38
local BYTE_HOUR_DEFAULT = 0
local BYTE_MINUTE_DEFAULT = 30
local BYTE_STATUS_STANDBY = 0x01
local BYTE_STATUS_WORK = 0x02
local BYTE_STATUS_SAVE_POWER = 0x07
local BYTE_STATUS_PREHEAT = 0x08
local BYTE_STATUS_PREHEATING = 0x08
local BYTE_STATUS_PREHEAT_FINISH = 0x88
local BYTE_STATUS_FINISH = 0x11
local BYTE_STATUS_RECIPES_FINISH = 0x66
local BYTE_STATUS_LOCK_ON = 0x05
local BYTE_STATUS_LOCK_OFF = 0x0A

local workStatusValue
local workModeValue
local workHourValue = 0
local workMinuteValue = 0
local workSecond = 0
local temperatureValue = -1
local undersideTubeTempValue
local curTemperatureAboveValue
local curTemperatureUndersideValue
local lock
local errorCode
local dataType = 0
local deviceSubType = 0
local deviceSN8 = '00000000'

local function getSoftVersion()
    if (deviceSN8 == '08T7428E' or deviceSN8 == '0T7L421F') then
        return 2
    else
        return 1
    end
end
local function jsonToModel(stateJson, controlJson)
    local oldState = stateJson
    local controlCmd = controlJson
    if getSoftVersion() == 2 then
        local temValue = oldState[KEY_TEMPERATURE]
        if (controlCmd[KEY_TEMPERATURE] ~= nil) then
            temValue = controlCmd[KEY_TEMPERATURE]
        end
        temperatureValue = checkBoundary(temValue, 70, 230)
        temValue = oldState[KEY_TUBE_TEMPERATURE]
        if (controlCmd[KEY_TUBE_TEMPERATURE] ~= nil) then
            temValue = controlCmd[KEY_TUBE_TEMPERATURE]
        end
        undersideTubeTempValue = checkBoundary(temValue, 70, 230)
        temValue = oldState[KEY_WORK_HOUR]
        if (controlCmd[KEY_WORK_HOUR] ~= nil) then
            temValue = controlCmd[KEY_WORK_HOUR]
        end
        workHourValue = checkBoundary(temValue, 0, 9)
        temValue = oldState[KEY_WORK_MINUTE]
        if (controlCmd[KEY_WORK_MINUTE] ~= nil) then
            temValue = controlCmd[KEY_WORK_MINUTE]
        end
        workMinuteValue = checkBoundary(temValue, 0, 59)
        temValue = oldState[KEY_WORK_SECOND]
        if (controlCmd[KEY_WORK_SECOND] ~= nil) then
            temValue = controlCmd[KEY_WORK_SECOND]
        end
        workSecond = checkBoundary(temValue, 0, 59)
        temValue = oldState[KEY_WORK_MODE]
        if (controlCmd[KEY_WORK_MODE] ~= nil) then
            temValue = controlCmd[KEY_WORK_MODE]
        end
        if (temValue == 'double_tube') then
            workModeValue = 0x4C
        elseif (temValue == 'above_tube') then
            workModeValue = 0x40
        elseif (temValue == 'revolve_bake') then
            workModeValue = 0x4E
        elseif (temValue == 'hot_wind_bake') then
            workModeValue = 0x43
        elseif (temValue == 'zymosis') then
            workModeValue = 0xB0
        elseif (temValue == 'underside_tube') then
            workModeValue = 0x49
        elseif (temValue == 'none') then
            workModeValue = 0x00
        else
            workModeValue = string2Int(temValue)
        end
        temValue = oldState[KEY_WORK_STATUS]
        if (controlCmd[KEY_WORK_STATUS] ~= nil) then
            temValue = controlCmd[KEY_WORK_STATUS]
        end
        if (temValue == 'standby') then
            workStatusValue = 0x02
        elseif (temValue == 'work') then
            workStatusValue = 0x03
        elseif (temValue == 'save_power') then
            workStatusValue = 0x01
        elseif (temValue == 'work_finish') then
            workStatusValue = 0x04
        else
            workStatusValue = string2Int(temValue)
        end
        temValue = oldState[KEY_LOCK]
        if (controlCmd[KEY_LOCK] ~= nil) then
            temValue = controlCmd[KEY_LOCK]
            if (temValue == 'on') then
                lock = 0x01
            elseif (temValue == 'off') then
                lock = 0x00
            end
        end
    else
        local temValue = oldState[KEY_TEMPERATURE]
        if (controlCmd[KEY_TEMPERATURE] ~= nil) then
            temValue = controlCmd[KEY_TEMPERATURE]
        end
        temperatureValue = checkBoundary(temValue, 70, 230)
        temValue = oldState[KEY_TUBE_TEMPERATURE]
        if (controlCmd[KEY_TUBE_TEMPERATURE] ~= nil) then
            temValue = controlCmd[KEY_TUBE_TEMPERATURE]
        end
        undersideTubeTempValue = checkBoundary(temValue, 70, 230)
        temValue = oldState[KEY_WORK_HOUR]
        if (controlCmd[KEY_WORK_HOUR] ~= nil) then
            temValue = controlCmd[KEY_WORK_HOUR]
        end
        workHourValue = checkBoundary(temValue, 0, 9)
        temValue = oldState[KEY_WORK_MINUTE]
        if (controlCmd[KEY_WORK_MINUTE] ~= nil) then
            temValue = controlCmd[KEY_WORK_MINUTE]
        end
        workMinuteValue = checkBoundary(temValue, 0, 59)
        temValue = oldState[KEY_WORK_SECOND]
        if (controlCmd[KEY_WORK_SECOND] ~= nil) then
            temValue = controlCmd[KEY_WORK_SECOND]
        end
        workSecond = checkBoundary(temValue, 0, 59)
        temValue = oldState[KEY_WORK_MODE]
        if (controlCmd[KEY_WORK_MODE] ~= nil) then
            temValue = controlCmd[KEY_WORK_MODE]
        end
        if (temValue == 'double_tube') then
            workModeValue = 0x01
        elseif (temValue == 'above_tube') then
            workModeValue = 0x05
        elseif (temValue == 'revolve_bake') then
            workModeValue = 0x07
        elseif (temValue == 'hot_wind_bake') then
            workModeValue = 0x08
        elseif (temValue == 'zymosis') then
            workModeValue = 0x09
            temperatureValue = BYTE_TEMPERATURE_ZYMOSIS
        elseif (temValue == 'underside_tube') then
            workModeValue = 0x0A
        elseif (temValue == 'temperature_differ') then
            workModeValue = 0x0B
        elseif (temValue == 'none') then
            workModeValue = 0x00
        else
            workModeValue = string2Int(temValue)
        end
        temValue = oldState[KEY_WORK_STATUS]
        if (controlCmd[KEY_WORK_STATUS] ~= nil) then
            temValue = controlCmd[KEY_WORK_STATUS]
        end
        if (temValue == VALUE_STANDBY) then
            workStatusValue = BYTE_STATUS_STANDBY
        elseif (temValue == VALUE_WORK) then
            workStatusValue = BYTE_STATUS_WORK
        elseif (temValue == VALUE_SAVE_POWER) then
            workStatusValue = BYTE_STATUS_SAVE_POWER
        elseif (temValue == VALUE_PREHEAT) then
            workStatusValue = BYTE_STATUS_PREHEAT
        elseif (temValue == 'lock_on') then
            workStatusValue = BYTE_STATUS_LOCK_ON
        elseif (temValue == 'lock_off') then
            workStatusValue = BYTE_STATUS_LOCK_OFF
        end
        temValue = oldState[KEY_LOCK]
        if (controlCmd[KEY_LOCK] ~= nil) then
            temValue = controlCmd[KEY_LOCK]
            if (temValue == VALUE_ON) then
                workStatusValue = BYTE_STATUS_LOCK_ON
            elseif (temValue == VALUE_OFF) then
                workStatusValue = BYTE_STATUS_LOCK_OFF
            end
        end
        if ((workHourValue == 0) and (workMinuteValue == 0)) then
            workMinuteValue = BYTE_MINUTE_DEFAULT
        end
    end
end
local function binToModel(binData)
    if (#binData == 0) then
        return nil
    end
    local messageBytes = binData
    if getSoftVersion() == 2 then
        if dataType == 0x02 and messageBytes[0] == 0x22 then
            if messageBytes[1] == 0x02 then
                workStatusValue = messageBytes[2]
                lock = messageBytes[3]
            elseif
            messageBytes[1] == 0x01 or messageBytes[1] == 0x03 or messageBytes[1] == 0x04 or messageBytes[1] == 0x05
            then
                workHourValue = messageBytes[7]
                workMinuteValue = messageBytes[8]
                workSecond = messageBytes[9]
                workModeValue = messageBytes[10]
                temperatureValue = messageBytes[11] * 256 + messageBytes[12]
                undersideTubeTempValue = messageBytes[13] * 256 + messageBytes[14]
            end
            errorCode = 0
        end
        if dataType == 0x03 and messageBytes[0] == 0x31 then
            workStatusValue = messageBytes[1]
            workHourValue = messageBytes[6]
            workMinuteValue = messageBytes[7]
            workSecond = messageBytes[8]
            workModeValue = messageBytes[9]
            curTemperatureAboveValue = messageBytes[10] * 256 + messageBytes[11]
            curTemperatureUndersideValue = messageBytes[12] * 256 + messageBytes[13]
            temperatureValue = messageBytes[18] * 256 + messageBytes[19]
            undersideTubeTempValue = messageBytes[20] * 256 + messageBytes[20]
            errorCode = 0
        end
    else
        workStatusValue = messageBytes[0]
        workModeValue = messageBytes[1]
        workHourValue = messageBytes[2]
        workMinuteValue = messageBytes[3]
        temperatureValue = messageBytes[4]
        curTemperatureAboveValue = messageBytes[8]
        curTemperatureUndersideValue = messageBytes[9]
        workSecond = messageBytes[12]
        undersideTubeTempValue = messageBytes[13]
        errorCode = messageBytes[5]
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then
        return nil
    end
    local json = decode(jsonCmd)
    deviceSubType = json['deviceinfo']['deviceSubType']
    local deviceSN = json['deviceinfo']['deviceSN']
    if deviceSN ~= nil then
        deviceSN8 = string.sub(deviceSN, 10, 17)
    end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    local bodyLength = 0
    if (query) then
        bodyLength = 0
    elseif (control) then
        if getSoftVersion() == 2 then
            bodyLength = 31
        else
            bodyLength = 13
        end
    end
    local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    local bodyBytes = {}
    for i = 0, bodyLength do
        if getSoftVersion() == 2 then
            bodyBytes[i] = 0xff
        else
            bodyBytes[i] = 0
        end
    end
    local msgBytes = {}
    for i = 0, msgLength do
        msgBytes[i] = 0
    end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    if (query) then
        msgBytes[9] = BYTE_QUERY_REQUEST
    elseif (control) then
        if (control and status) then
            jsonToModel(status, control)
        end
        if getSoftVersion() == 2 then
            if control[KEY_WORK_STATUS] ~= nil or control[KEY_LOCK] ~= nil then
                bodyBytes[0] = 0x22
                bodyBytes[1] = 0x02
                if control[KEY_WORK_STATUS] ~= nil then
                    bodyBytes[2] = workStatusValue
                end
                if control[KEY_LOCK] ~= nil then
                    bodyBytes[3] = workModeValue
                end
            else
                bodyBytes[0] = 0x22
                bodyBytes[1] = 0x04
                bodyBytes[7] = workHourValue
                bodyBytes[8] = workMinuteValue
                bodyBytes[9] = workSecond
                bodyBytes[10] = workModeValue
                bodyBytes[11] = bit.lshift(temperatureValue, 8)
                bodyBytes[12] = bit.band(temperatureValue, 0xff)
                bodyBytes[13] = bit.lshift(undersideTubeTempValue, 8)
                bodyBytes[14] = bit.band(undersideTubeTempValue, 0xff)
            end
        else
            bodyBytes[0] = workStatusValue
            bodyBytes[1] = workModeValue
            bodyBytes[2] = workHourValue
            bodyBytes[3] = workMinuteValue
            bodyBytes[4] = temperatureValue
            bodyBytes[5] = 0x11
            bodyBytes[6] = undersideTubeTempValue
            bodyBytes[9] = workSecond
        end
        msgBytes[9] = BYTE_CONTROL_REQUEST
    end
    for i = 0, bodyLength do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local infoM = {}
    for i = 1, msgLength + 1 do
        infoM[i] = msgBytes[i - 1]
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
    local deviceinfo = json['deviceinfo']
    deviceSubType = deviceinfo['deviceSubType']
    local deviceSN = json['deviceinfo']['deviceSN']
    if deviceSN ~= nil then
        deviceSN8 = string.sub(deviceSN, 10, 17)
    end
    local binData = json['msg']['data']
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[10]
    if ((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04)) then
        return nil
    end
    for i = 1, #info do
        msgBytes[i - 1] = info[i]
    end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then
    end
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    binToModel(bodyBytes)
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if getSoftVersion() == 2 then
        if (lock == 0x00) then
            streams[KEY_LOCK] = VALUE_OFF
        elseif (lock == 0x01) then
            streams[KEY_LOCK] = VALUE_ON
        end
        if (workStatusValue == 0x01) then
            streams[KEY_WORK_STATUS] = 'save_power'
        elseif (workStatusValue == 0x02) then
            streams[KEY_WORK_STATUS] = 'standby'
        elseif (workStatusValue == 0x03) then
            streams[KEY_WORK_STATUS] = 'work'
        elseif (workStatusValue == 0x04) then
            streams[KEY_WORK_STATUS] = 'work_finish'
        else
            streams[KEY_WORK_STATUS] = int2String(workStatusValue)
        end
        if (workModeValue == 0x4C) then
            streams[KEY_WORK_MODE] = 'double_tube'
        elseif (workModeValue == 0x40) then
            streams[KEY_WORK_MODE] = 'above_tube'
        elseif (workModeValue == 0x4E) then
            streams[KEY_WORK_MODE] = 'revolve_bake'
        elseif (workModeValue == 0x43) then
            streams[KEY_WORK_MODE] = 'hot_wind_bake'
        elseif (workModeValue == 0xB0) then
            streams[KEY_WORK_MODE] = 'zymosis'
        elseif (workModeValue == 0x49) then
            streams[KEY_WORK_MODE] = 'underside_tube'
        elseif (workModeValue == 0x00) then
            streams[KEY_WORK_MODE] = 'none'
        else
            streams[KEY_WORK_MODE] = int2String(workModeValue)
        end
        streams[KEY_WORK_HOUR] = workHourValue
        streams[KEY_WORK_MINUTE] = workMinuteValue
        streams[KEY_WORK_SECOND] = workSecond
        streams[KEY_TEMPERATURE] = temperatureValue
        streams[KEY_TUBE_TEMPERATURE] = undersideTubeTempValue
        streams[KEY_CUR_TEMPERATURE_ABOVE] = curTemperatureAboveValue
        streams[KEY_CUR_TEMPERATURE_UNDERSIDE] = curTemperatureUndersideValue
        streams[KEY_ERROR_CODE] = errorCode
    else
        if (workStatusValue == BYTE_STATUS_LOCK_ON) then
            streams[KEY_LOCK] = VALUE_ON
        else
            streams[KEY_LOCK] = VALUE_OFF
        end
        if (workStatusValue == BYTE_STATUS_STANDBY) then
            streams[KEY_WORK_STATUS] = VALUE_STANDBY
        elseif (workStatusValue == BYTE_STATUS_WORK) then
            streams[KEY_WORK_STATUS] = VALUE_WORK
        elseif (workStatusValue == BYTE_STATUS_SAVE_POWER) then
            streams[KEY_WORK_STATUS] = VALUE_SAVE_POWER
        elseif (workStatusValue == BYTE_STATUS_LOCK_ON) then
            streams[KEY_WORK_STATUS] = 'lock_on'
        elseif (workStatusValue == BYTE_STATUS_LOCK_OFF) then
            streams[KEY_WORK_STATUS] = 'lock_off'
        elseif (workStatusValue == BYTE_STATUS_PREHEATING) then
            streams[KEY_WORK_STATUS] = VALUE_PREHEATING
        elseif (workStatusValue == BYTE_STATUS_PREHEAT_FINISH) then
            streams[KEY_WORK_STATUS] = VALUE_PREHEAT_FINISH
        elseif (workStatusValue == BYTE_STATUS_FINISH) then
            streams[KEY_WORK_STATUS] = VALUE_WORK_FINISH
        elseif (workStatusValue == BYTE_STATUS_RECIPES_FINISH) then
            streams[KEY_WORK_STATUS] = VALUE_RECIPES_FINISH
        else
            streams[KEY_WORK_STATUS] = VALUE_INVALID
        end
        if (workModeValue == 0x06) then
            streams[KEY_WORK_MODE] = 'double_tube'
        elseif (workModeValue == 0x05) then
            streams[KEY_WORK_MODE] = 'above_tube'
        elseif (workModeValue == 0x07) then
            streams[KEY_WORK_MODE] = 'revolve_bake'
        elseif (workModeValue == 0x08) then
            streams[KEY_WORK_MODE] = 'hot_wind_bake'
        elseif (workModeValue == 0x09) then
            streams[KEY_WORK_MODE] = 'zymosis'
        elseif (workModeValue == 0x0A) then
            streams[KEY_WORK_MODE] = 'underside_tube'
        elseif (workModeValue == 0x0B) then
            streams[KEY_WORK_MODE] = 'temperature_differ'
        elseif (workModeValue == 0x00) then
            streams[KEY_WORK_MODE] = 'none'
        else
            streams[KEY_WORK_MODE] = int2String(workModeValue)
        end
        streams[KEY_WORK_HOUR] = workHourValue
        streams[KEY_WORK_MINUTE] = workMinuteValue
        streams[KEY_WORK_SECOND] = workSecond
        streams[KEY_TEMPERATURE] = temperatureValue
        streams[KEY_TUBE_TEMPERATURE] = undersideTubeTempValue
        streams[KEY_CUR_TEMPERATURE_ABOVE] = curTemperatureAboveValue
        streams[KEY_CUR_TEMPERATURE_UNDERSIDE] = curTemperatureUndersideValue
        streams[KEY_ERROR_CODE] = errorCode
    end
    local retTable = {}
    retTable['status'] = streams
    local ret = encode(retTable)
    return ret
end

function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == 'string' then
            k = string.format('%q', k)
        end
        local szSuffix = ''
        if type(v) == 'table' then
            szSuffix = '{'
        end
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

function table2string(cmd)
    local ret = ''
    local i
    for i = 1, #cmd do
        ret = ret .. string.char(cmd[i])
    end
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
    for i = 1, #str do
        ret = ret .. string.format('%02x', str:byte(i))
    end
    return ret
end

function encode(cmd)
    local tb
    if JSON == nil then
        JSON = require 'cjson'
    end
    tb = JSON.encode(cmd)
    return tb
end

function decode(cmd)
    local tb
    if JSON == nil then
        JSON = require 'cjson'
    end
    tb = JSON.decode(cmd)
    return tb
end

function makeSum(tmpbuf, start_pos, end_pos)
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

local crc8_854_table = { 0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65, 157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220, 35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98, 190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255, 70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7, 219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154, 101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36, 248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185, 140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205, 17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80, 175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238, 50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115, 202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139, 87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22, 233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168, 116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53 }

function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end

function string2Int(data)
    if (not data) then
        data = tonumber('0')
    end
    data = tonumber(data)
    if (data == nil) then
        data = 0
    end
    return data
end

function int2String(data)
    if (not data) then
        data = tostring(0)
    end
    data = tostring(data)
    if (data == nil) then
        data = '0'
    end
    return data
end
