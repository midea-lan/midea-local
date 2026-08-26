local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_MODE = 'work_mode'
local KEY_CODE_ID = 'code_id'
local KEY_POWER = 'power'
local KEY_TIME_RESERVE_FINISH = 'appoint_time'
local KEY_TIME_RESERVE_WORK = 'set_work_time'
local KEY_TIME_RESERVE_WARM = 'set_keep_warm_time'
local KEY_TEMPERATURE_RESERVE_WARM = 'set_keep_warm_temp'
local KEY_TEMPERATURE_RESERVE_HOT = 'set_work_temp'
local KEY_RESERVE_SPEED = 'speed'
local KEY_ERROR_CODE = 'error_code'
local KEY_WORK_STATUS = 'work_status'
local KEY_WORK_STEP = 'work_stage'
local KEY_STEP_STATUS = 'step_status'
local KEY_CUP_CAP_STATUS = 'lid_status'
local KEY_CUP_BODY_STATUS = 'cup_status'
local KEY_CUR_WORK_TIME = 'current_time'
local KEY_CUR_TEMPERATURE = 'current_temp'
local KEY_RESPONSE_TYPE = 'response_type'

local VALUE_VERSION = '2'
local VALUE_RESPONSE_SUCCESS = 'success'
local VALUE_RESPONSE_FAIL = 'fail'
local VALUE_HAVE_CUP = 'have_cup'
local VALUE_NO_CUP = 'no_cup'
local VALUE_DEFAULT = 'default'
local VALUE_HOT_CUP = 'hot_cup'
local VALUE_COLD_CUP = 'cold_cup'
local VALUE_ON = 'on'
local VALUE_OFF = 'off'
local VALUE_STANDBY = 'standby'
local VALUE_WAITING = 'waiting'
local VALUE_FABRICATION = 'fabrication'
local VALUE_COMPLETE = 'complete'
local VALUE_WARM = 'warm'
local VALUE_ABNORMITY = 'abnormity'
local VALUE_NO_DISPLAY = 'no_display'
local VALUE_FAST_HOT = 'fast_hot'
local VALUE_STIR = 'stir'
local VALUE_BOIL = 'boil'
local VALUE_EXTRACT = 'extract'
local VALUE_AROMA = 'aroma'

local BYTE_DEVICE_TYPE = 0xF1
local BYTE_MSG_TYPE_CONTROL = 0x02
local BYTE_MSG_TYPE_QUERY = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_HEAD_LENGTH = 0x0A
local BYTE_RESPONSE_SUCCESS = 0x01
local BYTE_RESPONSE_FAIL = 0x00
local BYTE_HAVE_CUP = 0x00
local BYTE_NO_CUP = 0x01
local BYTE_DEFAULT = 0x00
local BYTE_HOT_CUP = 0x01
local BYTE_COLD_CUP = 0x02
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00

local mode = 0
local codeID = 0
local power = 0
local timeReserveFinish = 0
local timeReserveWork = 0
local timeReserveWarm = 0
local temperatureReserveWarm = 0
local temperatureReserveHot = 0
local speedReserve = 0
local errorCode = 0
local workStatus = 0
local workStep = 0
local stepStatus = 0
local cupCapStatus = 0
local cupBodyStatus = 0
local curWorkTime = 0
local curTemperature = 0
local curWorkSpeed = 0
local responseType
local dataType = 0

function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams[KEY_MODE] ~= nil) then mode = string2Int(streams[KEY_MODE]) end
    if (streams[KEY_CODE_ID] ~= nil) then
        codeID = checkBoundary(streams[KEY_CODE_ID], 0, 255)
    end
    if (streams[KEY_POWER] == VALUE_ON) then
        power = BYTE_POWER_ON
    elseif (streams[KEY_POWER] == VALUE_OFF) then
        power = BYTE_POWER_OFF
    end
    if (streams[KEY_TIME_RESERVE_FINISH] ~= nil) then
        timeReserveFinish = checkBoundary(streams[KEY_TIME_RESERVE_FINISH], 0,
                                          65536)
    end
    if (streams[KEY_TIME_RESERVE_WORK] ~= nil) then
        timeReserveWork =
            checkBoundary(streams[KEY_TIME_RESERVE_WORK], 0, 65536)
    end
    if (streams[KEY_TIME_RESERVE_WARM] ~= nil) then
        timeReserveWarm = checkBoundary(streams[KEY_TIME_RESERVE_WARM], 0, 59)
    end
    if (streams[KEY_TEMPERATURE_RESERVE_WARM] ~= nil) then
        temperatureReserveWarm = string2Int(
                                     streams[KEY_TEMPERATURE_RESERVE_WARM])
    end
    if (streams[KEY_TEMPERATURE_RESERVE_HOT] ~= nil) then
        temperatureReserveHot = string2Int(streams[KEY_TEMPERATURE_RESERVE_HOT])
    end
    if (streams[KEY_RESERVE_SPEED] ~= nil) then
        curWorkSpeed = checkBoundary(streams[KEY_RESERVE_SPEED], 0, 8)
    end
end

function binToModel(binData)
    if (#binData < 11) then return nil end
    local messageBytes = binData
    if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04) then
        mode = messageBytes[4] + bit.lshift(messageBytes[5], 8) +
                   bit.lshift(messageBytes[6], 16) +
                   bit.lshift(messageBytes[7], 24)
        errorCode = messageBytes[8]
        responseType = messageBytes[9]
        workStatus = messageBytes[10]
        stepStatus = messageBytes[11]
        workStep = messageBytes[12]
        cupCapStatus = messageBytes[13]
        cupBodyStatus = messageBytes[14]
        curWorkTime = messageBytes[15] + bit.lshift(messageBytes[16], 8)
        curTemperature = messageBytes[17]
        curWorkSpeed = messageBytes[18]
        temperatureReserveHot = messageBytes[19]
        temperatureReserveWarm = messageBytes[20]
        timeReserveFinish = messageBytes[21] + bit.lshift(messageBytes[22], 8)
        timeReserveWork = messageBytes[23] + bit.lshift(messageBytes[24], 8)
        timeReserveWarm = messageBytes[25]
        codeID = messageBytes[26]
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
        for i = 0, 24 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0xAA
        bodyBytes[1] = 0x55
        bodyBytes[3] = 0x20
        bodyBytes[4] = bit.band(mode, 0xFF)
        bodyBytes[5] = bit.band(bit.rshift(mode, 8), 0xFF)
        bodyBytes[6] = bit.band(bit.rshift(mode, 16), 0xFF)
        bodyBytes[7] = bit.band(bit.rshift(mode, 24), 0xFF)
        bodyBytes[8] = codeID
        bodyBytes[9] = power
        bodyBytes[10] = bit.band(timeReserveFinish, 0xFF)
        bodyBytes[11] = bit.band(bit.rshift(timeReserveFinish, 8), 0xFF)
        bodyBytes[12] = bit.band(timeReserveWork, 0xFF)
        bodyBytes[13] = bit.band(bit.rshift(timeReserveWork, 8), 0xFF)
        bodyBytes[14] = timeReserveWarm
        bodyBytes[15] = temperatureReserveWarm
        bodyBytes[16] = temperatureReserveHot
        bodyBytes[17] = curWorkSpeed
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
        streams[KEY_MODE] = int2String(mode)
        streams[KEY_ERROR_CODE] = int2String(errorCode)
        if (responseType == BYTE_RESPONSE_SUCCESS) then
            streams[KEY_RESPONSE_TYPE] = VALUE_RESPONSE_SUCCESS
        elseif (responseType == BYTE_RESPONSE_FAIL) then
            streams[KEY_RESPONSE_TYPE] = VALUE_RESPONSE_FAIL
        end
        streams[KEY_WORK_STATUS] = int2String(workStatus)
        streams[KEY_STEP_STATUS] = int2String(stepStatus)
        streams[KEY_WORK_STEP] = int2String(workStep)
        if (cupCapStatus == BYTE_HAVE_CUP) then
            streams[KEY_CUP_CAP_STATUS] = VALUE_HAVE_CUP
        elseif (cupCapStatus == BYTE_NO_CUP) then
            streams[KEY_CUP_CAP_STATUS] = VALUE_NO_CUP
        end
        if (cupBodyStatus == BYTE_DEFAULT) then
            streams[KEY_CUP_BODY_STATUS] = VALUE_DEFAULT
        elseif (cupBodyStatus == BYTE_HOT_CUP) then
            streams[KEY_CUP_BODY_STATUS] = VALUE_HOT_CUP
        elseif (cupBodyStatus == BYTE_COLD_CUP) then
            streams[KEY_CUP_BODY_STATUS] = VALUE_COLD_CUP
        end
        streams[KEY_CUR_WORK_TIME] = int2String(curWorkTime)
        streams[KEY_CUR_TEMPERATURE] = int2String(curTemperature)
        streams[KEY_RESERVE_SPEED] = int2String(curWorkSpeed)
        streams[KEY_TEMPERATURE_RESERVE_HOT] = int2String(temperatureReserveHot)
        streams[KEY_TEMPERATURE_RESERVE_WARM] = int2String(
                                                    temperatureReserveWarm)
        streams[KEY_TIME_RESERVE_FINISH] = int2String(timeReserveFinish)
        streams[KEY_TIME_RESERVE_WORK] = int2String(timeReserveWork)
        streams[KEY_TIME_RESERVE_WARM] = int2String(timeReserveWarm)
        streams[KEY_CODE_ID] = int2String(codeID)
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
