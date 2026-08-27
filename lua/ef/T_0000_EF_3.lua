local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_CMD_CODE = 'cmd_code'
local KEY_TEMPERATURE_SETTING = 'temperature_setting'
local KEY_RESERVE = 'reserve'
local KEY_WARM = 'warm'
local KEY_DRINK_STYLE = 'drink_style'
local KEY_TIME_WARM_HR = 'time_warm_hr'
local KEY_TIME_WARM_MIN = 'time_warm_min'
local KEY_TIME_RESERVE_HR = 'time_reserve_hr'
local KEY_TIME_RESERVE_MIN = 'time_reserve_min'
local KEY_CMD_ID = 'cmd_id'
local KEY_WORK_STATUS = 'work_status'
local KEY_ERROR_CODE = 'error_code'
local KEY_RESPONSE_TYPE = 'response_type'
local KEY_WORK_STEP = 'work_step'
local KEY_PROCESS_STATUS = 'process_status'
local KEY_TIME_WORK_HR = 'time_work_hr'
local KEY_TIME_WORK_MIN = 'time_work_min'
local KEY_TIME_MAX = 'time_max'
local KEY_TEMPERATURE_CURRENT = 'temperature_current'

local VALUE_VERSION = '3'
local VALUE_RESERVE = 'reserve'
local VALUE_WORK = 'work'
local VALUE_WARM = 'warm'
local VALUE_ON = 'on'
local VALUE_OFF = 'off'
local VALUE_WARM_DRINK = 'warm_drink'
local VALUE_HOT_DRINK = 'hot_drink'
local VALUE_NO = 'no'
local VALUE_FRICTION = 'friction'
local VALUE_BOIL = 'boil'
local VALUE_EMULSIFY = 'emulsify'
local VALUE_PITHY = 'pithy'
local VALUE_ALCOHOLIZE = 'alcoholize'
local VALUE_RESPONSE_NORMAL = 'response_normal'
local VALUE_RESPONSE_ERROR = 'response_error'

local BYTE_DEVICE_TYPE = 0xEF
local BYTE_MSG_TYPE_CONTROL = 0x02
local BYTE_MSG_TYPE_QUERY = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_HEAD_LENGTH = 0x0A
local BYTE_WORK_STATUS_RESERVE = 0x01
local BYTE_WORK_STATUS_WORK = 0x02
local BYTE_WORK_STATUS_WARM = 0x03
local BYTE_RESERVE_ON = 0x01
local BYTE_RESERVE_OFF = 0x00
local BYTE_WARM_ON = 0x02
local BYTE_WARM_OFF = 0x00
local BYTE_WARM_DRINK = 0x04
local BYTE_HOT_DRINK = 0x00
local BYTE_NO_PROCESS_STATUS = 0x00
local BYTE_FRICTION = 0x01
local BYTE_BOIL = 0x02
local BYTE_EMULSIFY = 0x03
local BYTE_PITHY = 0x04
local BYTE_ALCOHOLIZE = 0x05
local BYTE_RESPONSE_NORMAL = 0x01
local BYTE_RESPONSE_ERROR = 0x00

local cmdCode
local workStatus
local errorCode = 0
local responseType = 0
local cmdID = 0
local reserve
local warm
local drinkStyle
local workStep = 0
local processStatus
local timeWorkHr = 0
local timeWorkMin = 0
local timeMax = 0
local temperatureSetting = 0
local temperatureCurrent = 0
local timeReserveMin = 0
local timeReserveHr = 0
local timeWarmHr = 0
local timeWarmMin = 0
local dataType = 0

function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams[KEY_CMD_CODE] ~= nil) then
        cmdCode = string2Int(streams[KEY_CMD_CODE])
    end
    if (streams[KEY_CMD_ID] ~= nil) then
        cmdID = checkBoundary(streams[KEY_CMD_ID], 0, 255)
    end
    reserve = string2Int(streams[KEY_RESERVE])
    warm = string2Int(streams[KEY_WARM])
    drinkStyle = string2Int(streams[KEY_DRINK_STYLE])
    if (streams[KEY_TIME_RESERVE_HR] ~= nil) then
        timeReserveHr = checkBoundary(streams[KEY_TIME_RESERVE_HR], 0, 23)
    end
    if (streams[KEY_TIME_RESERVE_MIN] ~= nil) then
        timeReserveMin = checkBoundary(streams[KEY_TIME_RESERVE_MIN], 0, 59)
    end
    if (streams[KEY_TIME_WARM_HR] ~= nil) then
        timeWarmHr = checkBoundary(streams[KEY_TIME_WARM_HR], 0, 23)
    end
    if (streams[KEY_TIME_WARM_MIN] ~= nil) then
        timeWarmMin = checkBoundary(streams[KEY_TIME_WARM_MIN], 0, 59)
    end
    if (streams[KEY_TEMPERATURE_SETTING] ~= nil) then
        temperatureSetting = checkBoundary(streams[KEY_TEMPERATURE_SETTING], 0,
                                           98)
    end
end

function binToModel(binData)
    if (#binData < 11) then return nil end
    local messageBytes = binData
    if (dataType == 0x03 or dataType == 0x04 or dataType == 0x02) then
        cmdCode = bit.lshift(messageBytes[5], 8) + messageBytes[4]
        workStatus = messageBytes[8]
        errorCode = messageBytes[9]
        responseType = messageBytes[10]
        cmdID = messageBytes[11]
        reserve = bit.band(messageBytes[12], 0x01)
        warm = bit.band(messageBytes[12], 0x02)
        drinkStyle = bit.band(messageBytes[12], 0x04)
        workStep = messageBytes[13]
        processStatus = messageBytes[14]
        timeWorkHr = messageBytes[15]
        timeWorkMin = messageBytes[16]
        timeMax = messageBytes[17]
        temperatureSetting = messageBytes[18]
        temperatureCurrent = messageBytes[19]
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local infoM = {}
    local bodyBytes = {}
    local json = decode(jsonCmd)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (query) then
        for i = 0, 7 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0xAA
        bodyBytes[1] = 0x55
        bodyBytes[3] = 0x31
        infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_QUERY)
    elseif (control) then
        if (status) then jsonToModel(status) end
        if (control) then jsonToModel(control) end
        for i = 0, 19 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0xAA
        bodyBytes[1] = 0x55
        bodyBytes[3] = 0x20
        bodyBytes[4] = bit.band(cmdCode, 0xFF)
        bodyBytes[5] = bit.band(bit.rshift(cmdCode, 8), 0xFF)
        bodyBytes[8] = cmdID
        bodyBytes[9] = bit.bor(bit.bor(warm, reserve), drinkStyle)
        bodyBytes[10] = timeReserveHr
        bodyBytes[11] = timeReserveMin
        bodyBytes[12] = timeWarmHr
        bodyBytes[13] = timeWarmMin
        bodyBytes[14] = temperatureSetting
        infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_CONTROL)
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[9] = cType
    for i = 0, bodyLength do
        msgBytes[i + BYTE_PROTOCOL_HEAD_LENGTH] = bodyData[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
end

function dataToJson(jsonCmd)
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceinfo = json['deviceinfo']
    local deviceSubType = deviceinfo['deviceSubtype']
    if (deviceSubType == 1) then end
    local status = json['status']
    if (status) then jsonToModel(status) end
    local binData = json['msg']['data']
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[10]
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_HEAD_LENGTH - 1
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_HEAD_LENGTH]
    end
    binToModel(bodyBytes)
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04) then
        streams[KEY_CMD_CODE] = int2String(cmdCode)
        streams[KEY_WORK_STATUS] = int2String(workStatus)
        streams[KEY_ERROR_CODE] = errorCode
        if (responseType == BYTE_RESPONSE_NORMAL) then
            streams[KEY_RESPONSE_TYPE] = VALUE_RESPONSE_NORMAL
        elseif (responseType == BYTE_RESPONSE_ERROR) then
            streams[KEY_RESPONSE_TYPE] = VALUE_RESPONSE_ERROR
        end
        streams[KEY_CMD_ID] = int2String(cmdID)
        streams[KEY_RESERVE] = int2String(reserve)
        streams[KEY_WARM] = int2String(warm)
        streams[KEY_DRINK_STYLE] = int2String(drinkStyle)
        streams[KEY_WORK_STEP] = int2String(workStep)
        streams[KEY_PROCESS_STATUS] = int2String(processStatus)
        streams[KEY_TIME_WORK_HR] = int2String(timeWorkHr)
        streams[KEY_TIME_WORK_MIN] = int2String(timeWorkMin)
        streams[KEY_TIME_MAX] = int2String(timeMax)
        streams[KEY_TEMPERATURE_SETTING] = int2String(temperatureSetting)
        streams[KEY_TEMPERATURE_CURRENT] = int2String(temperatureCurrent)
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

function string2Int(data)
    if (not data) then data = tonumber('0') end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end

function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = '0' end
    return data
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
