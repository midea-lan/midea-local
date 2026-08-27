local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_CONTROL_CMD_CODE = 'control_cmd_code'
local KEY_VOLUME = 'volume'
local KEY_COLOR = 'color'
local KEY_DOSING = 'dosing'
local KEY_WORK_STATUS = 'work_status'
local KEY_TIME_CUISINE_MIN = 'time_cuisine_min'
local KEY_TIME_CUISINE_HR = 'time_cuisine_hr'
local KEY_TIME_RESERVE_MIN = 'time_reserve_min'
local KEY_TIME_RESERVE_HR = 'time_reserve_hr'
local KEY_BAKE_TEMPERATURE = 'bake_temperature'
local KEY_QUERY_CMD_CODE = 'query_cmd_code'
local KEY_BOTTOM_TEMPERATURE = 'bottom_temperature'
local KEY_TIME_WORK_MIN = 'time_work_min'
local KEY_TIME_WORK_HR = 'time_work_hr'
local KEY_TIME_WARM_MIN = 'time_warm_min'
local KEY_TIME_WARM_HR = 'time_warm_hr'
local KEY_ERROR_CODE = 'error_code'
local KEY_RESPONSE = 'response'
local KEY_WORK_STAGE = 'work_stage'

local VALUE_VERSION = '3'
local VALUE_BREAD = 'bread'
local VALUE_MILK = 'milk'
local VALUE_NOODLE = 'noodle'
local VALUE_BAKE = 'bake'
local VALUE_NO = 'no'
local VALUE_500 = '500'
local VALUE_750 = '750'
local VALUE_1000 = '1000'
local VALUE_TINT = 'tint'
local VALUE_MIDDLE = 'middle'
local VALUE_DARK = 'dark'
local VALUE_YEAST = 'yeast'
local VALUE_FRUI = 'fruit'
local VALUE_YEAST_AND_FRUIT = 'yeast_and_fruit'
local VALUE_STANDBY = 'standby'
local VALUE_START = 'start'
local VALUE_SUSPEND = 'suspend'
local VALUE_RESERVE = 'reserve'
local VALUE_WARM = 'warm'
local VALUE_QUERY_ERROR = 'query_error'
local VALUE_QUERY_INFO = 'query_info'
local VALUE_QUERY_STATUS = 'query_status'
local VALUE_RESPONSE_NORMAL = 'response_normal'
local VALUE_RESPONSE_ERROR_E2 = 'response_error_e2'

local BYTE_DEVICE_TYPE = 0xE9
local BYTE_MSG_TYPE_CONTROL = 0x02
local BYTE_MSG_TYPE_QUERY = 0x03
local BYTE_TASK_TYPE_SETTING = 0x02
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_HEAD_LENGTH = 0x0A
local BYTE_PACKAGE_LENGTH_CONTROL = 0x1D
local BYTE_PACKAGE_LENGTH_QUERY = 0x13
local BYTE_BODY_LENGTH_CONTROL = 0x13
local BYTE_BODY_LENGTH_QUERY = 0x09
local BYTE_CONTROL_CMD_CODE_BREAD = 0x04
local BYTE_CONTROL_CMD_CODE_MILK = 0x0E
local BYTE_CONTROL_CMD_CODE_NOODLE = 0x10
local BYTE_CONTROL_CMD_CODE_BAKE = 0x13
local BYTE_CONTROL_CMD_CODE_HIGH = 0x00
local BYTE_QUERY_CMD_CODE_ERROR = 0x50
local BYTE_QUERY_CMD_CODE_INFO = 0x51
local BYTE_QUERY_CMD_CODE_STATUS = 0x52
local BYTE_QUERY_CMD_CODE_LOW = 0xC3
local BYTE_VOLUME_NO = 0x00
local BYTE_VOLUME_500 = 0x01
local BYTE_VOLUME_750 = 0x02
local BYTE_VOLUME_1000 = 0x03
local BYTE_COLOR_NO = 0x00
local BYTE_COLOR_TINT = 0x01
local BYTE_COLOR_MIDDLE = 0x02
local BYTE_COLOR_DARK = 0x03
local BYTE_DOSING_NO = 0x00
local BYTE_DOSING_YEAST = 0x01
local BYTE_DOSING_FRUIT = 0x02
local BYTE_DOSING_YEAST_AND_FRUIT = 0x03
local BYTE_STATUS_STANDBY = 0x00
local BYTE_STATUS_START = 0x01
local BYTE_STATUS_SUSPEND = 0x02
local BYTE_STATUS_RESERVE = 0x03
local BYTE_STATUS_WARM = 0x04
local BYTE_RESPONSE_NORMAL = 0x01
local BYTE_RESPONSE_ERROR_E2 = 0x0A

local cmdControlCode = 0
local cmdQueryCodeHigh = 0
local cmdQueryCodeLow = 0
local workStatus = 0
local volume = 0
local color = 0
local dosing = 0
local timeCuisineMin = 0
local timeCuisineHr = 0
local timeReserveMin = 0
local timeReserveHr = 0
local bakeTemperature = 0
local responseType
local bottonTemperature
local timeWorkMin = 0
local timeWorkHr = 0
local timeWarmMin = 0
local timeWarmHr = 0
local errorCode = 0
local workStage = 0
local dataType = 0

function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams[KEY_CONTROL_CMD_CODE] ~= nil) then
        cmdControlCode = string2Int(streams[KEY_CONTROL_CMD_CODE])
    end
    if (streams[KEY_QUERY_CMD_CODE] == VALUE_QUERY_ERROR) then
        cmdQueryCodeHigh = BYTE_QUERY_CMD_CODE_ERROR
        cmdQueryCodeLow = BYTE_QUERY_CMD_CODE_LOW
    elseif (streams[KEY_QUERY_CMD_CODE] == VALUE_QUERY_INFO) then
        cmdQueryCodeHigh = BYTE_QUERY_CMD_CODE_INFO
        cmdQueryCodeLow = BYTE_QUERY_CMD_CODE_LOW
    elseif (streams[KEY_QUERY_CMD_CODE] == VALUE_QUERY_STATUS) then
        cmdQueryCodeHigh = BYTE_QUERY_CMD_CODE_STATUS
        cmdQueryCodeLow = BYTE_QUERY_CMD_CODE_LOW
    end
    if (streams[KEY_WORK_STATUS] ~= nil) then
        workStatus = string2Int(streams[KEY_WORK_STATUS])
    end
    if (streams[KEY_VOLUME] ~= nil) then
        volume = string2Int(streams[KEY_VOLUME])
    end
    if (streams[KEY_COLOR] ~= nil) then
        color = string2Int(streams[KEY_COLOR])
    end
    if (streams[KEY_DOSING] ~= nil) then
        dosing = string2Int(streams[KEY_DOSING])
    end
    if (streams[KEY_TIME_CUISINE_MIN] ~= nil) then
        timeCuisineMin = checkBoundary(streams[KEY_TIME_CUISINE_MIN], 0, 59)
    end
    if (streams[KEY_TIME_CUISINE_HR] ~= nil) then
        timeCuisineHr = checkBoundary(streams[KEY_TIME_CUISINE_HR], 0, 23)
    end
    if (streams[KEY_TIME_RESERVE_MIN] ~= nil) then
        timeReserveMin = checkBoundary(streams[KEY_TIME_RESERVE_MIN], 0, 59)
    end
    if (streams[KEY_TIME_RESERVE_HR] ~= nil) then
        timeReserveHr = checkBoundary(streams[KEY_TIME_RESERVE_HR], 0, 23)
    end
    if (streams[KEY_BAKE_TEMPERATURE] ~= nil) then
        bakeTemperature = checkBoundary(streams[KEY_BAKE_TEMPERATURE], 0, 255)
    end
end

function binToModel(binData)
    if (#binData < 11) then return nil end
    local messageBytes = binData
    if (dataType == 0x02 or dataType == 0x04) then
        cmdControlCode = messageBytes[6] + bit.lshift(messageBytes[7], 8)
        responseType = messageBytes[8]
        volume = messageBytes[9]
        color = messageBytes[10]
        dosing = messageBytes[11]
        workStatus = messageBytes[12]
        workStage = messageBytes[13]
        bottonTemperature = messageBytes[14]
        timeReserveMin = messageBytes[15]
        timeReserveHr = messageBytes[16]
        timeWorkMin = messageBytes[17]
        timeWorkHr = messageBytes[18]
        timeWarmMin = messageBytes[19]
        timeWarmHr = messageBytes[20]
        errorCode = messageBytes[21]
    elseif (dataType == 0x03) then
        cmdQueryCodeLow = messageBytes[6]
        cmdQueryCodeHigh = messageBytes[7]
        if (cmdQueryCodeLow == 0x50) then
            responseType = messageBytes[8]
            errorCode = messageBytes[9]
        elseif (cmdQueryCodeLow == 0x51) then
            responseType = messageBytes[8]
            productVolume = messageBytes[15]
        elseif (cmdQueryCodeLow == 0x52) then
            cmdControlCode = messageBytes[8] + bit.lshift(messageBytes[9], 8)
            responseType = messageBytes[10]
            volume = messageBytes[11]
            color = messageBytes[12]
            dosing = messageBytes[13]
            workStatus = messageBytes[14]
            workStage = messageBytes[15]
            bottonTemperature = messageBytes[16]
            timeReserveMin = messageBytes[17]
            timeReserveHr = messageBytes[18]
            timeWorkMin = messageBytes[19]
            timeWarmHr = messageBytes[20]
            timeWarmMin = messageBytes[21]
            timeWarmHr = messageBytes[22]
            errorCode = messageBytes[23]
        end
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
        for i = 0, 8 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0xAA
        bodyBytes[1] = 0x55
        bodyBytes[2] = 0x04
        bodyBytes[4] = BYTE_BODY_LENGTH_QUERY
        bodyBytes[5] = BYTE_TASK_TYPE_SETTING
        bodyBytes[6] = 0x52
        bodyBytes[7] = 0xC3
        bodyBytes[8] = makeSum(bodyBytes, 0, 7)
        infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_QUERY)
    elseif (control) then
        if (status) then jsonToModel(status) end
        if (control) then jsonToModel(control) end
        for i = 0, 18 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0xAA
        bodyBytes[1] = 0x55
        bodyBytes[2] = 0x04
        bodyBytes[4] = BYTE_BODY_LENGTH_CONTROL
        bodyBytes[5] = BYTE_TASK_TYPE_SETTING
        bodyBytes[6] = bit.band(cmdControlCode, 0xFF)
        bodyBytes[7] = bit.band(bit.rshift(cmdControlCode, 8), 0xFF)
        bodyBytes[8] = volume
        bodyBytes[9] = color
        bodyBytes[10] = dosing
        bodyBytes[11] = workStatus
        bodyBytes[12] = timeCuisineMin
        bodyBytes[13] = timeCuisineHr
        bodyBytes[14] = timeReserveMin
        bodyBytes[15] = timeReserveHr
        bodyBytes[16] = bakeTemperature
        bodyBytes[18] = makeSum(bodyBytes, 0, 17)
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
    if (dataType == 0x02 or dataType == 0x04) then
        streams[KEY_CONTROL_CMD_CODE] = int2String(cmdControlCode)
        if (responseType == BYTE_RESPONSE_NORMAL) then
            streams[KEY_RESPONSE] = VALUE_RESPONSE_NORMAL
        elseif (responseType == BYTE_RESPONSE_ERROR_E2) then
            streams[KEY_RESPONSE] = VALUE_RESPONSE_ERROR_E2
        end
        streams[KEY_VOLUME] = int2String(volume)
        streams[KEY_COLOR] = int2String(color)
        streams[KEY_DOSING] = int2String(dosing)
        streams[KEY_WORK_STATUS] = int2String(workStatus)
        streams[KEY_WORK_STAGE] = int2String(workStage)
        streams[KEY_BOTTOM_TEMPERATURE] = int2String(bottonTemperature)
        streams[KEY_TIME_RESERVE_MIN] = int2String(timeReserveMin)
        streams[KEY_TIME_RESERVE_HR] = int2String(timeReserveHr)
        streams[KEY_TIME_WORK_MIN] = int2String(timeWorkMin)
        streams[KEY_TIME_WORK_HR] = int2String(timeWorkHr)
        streams[KEY_TIME_WARM_MIN] = int2String(timeWarmkMin)
        streams[KEY_TIME_WARM_HR] = int2String(timeWarmkHr)
        streams[KEY_ERROR_CODE] = int2String(errorCode)
    elseif (dataType == 0x03) then
        if (cmdQueryCodeLow == 0x50) then
            if (responseType == BYTE_RESPONSE_NORMAL) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_NORMAL
            elseif (responseType == BYTE_RESPONSE_ERROR_E2) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_ERROR_E2
            end
            streams[KEY_ERROR_CODE] = int2String(errorCode)
        elseif (cmdQueryCodeLow == 0x52) then
            streams[KEY_CONTROL_CMD_CODE] = int2String(cmdControlCode)
            if (responseType == BYTE_RESPONSE_NORMAL) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_NORMAL
            elseif (responseType == BYTE_RESPONSE_ERROR_E2) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_ERROR_E2
            end
            streams[KEY_VOLUME] = int2String(volume)
            streams[KEY_COLOR] = int2String(color)
            streams[KEY_DOSING] = int2String(dosing)
            streams[KEY_WORK_STATUS] = int2String(workStatus)
            streams[KEY_WORK_STAGE] = int2String(workStage)
            streams[KEY_BOTTOM_TEMPERATURE] = int2String(bottonTemperature)
            streams[KEY_TIME_RESERVE_MIN] = int2String(timeReserveMin)
            streams[KEY_TIME_RESERVE_HR] = int2String(timeReserveHr)
            streams[KEY_TIME_WORK_MIN] = int2String(timeWorkMin)
            streams[KEY_TIME_WORK_HR] = int2String(timeWorkHr)
            streams[KEY_TIME_WARM_MIN] = int2String(timeWarmkMin)
            streams[KEY_TIME_WARM_HR] = int2String(timeWarmkHr)
            streams[KEY_ERROR_CODE] = int2String(errorCode)
        end
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
