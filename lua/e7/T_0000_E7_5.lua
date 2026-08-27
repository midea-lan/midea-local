local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_FUNCTION_NO = 'function_no'
local KEY_WORK_STATUS = 'work_status'
local KEY_TIME_RESERVE_MIN = 'time_reserve_min'
local KEY_TIME_RESERVE_HR = 'time_reserve_hr'
local KEY_FIRE_LEVEL = 'fire_level'
local KEY_DEFINITE_TIME_HR = 'definite_time_hr'
local KEY_DEFINITE_TIME_MIN = 'definite_time_min'
local KEY_RESPONSE = 'response'
local KEY_TIME_RUNNING_HR = 'time_running_hr'
local KEY_TIME_RUNNING_MIN = 'time_running_min'
local KEY_TIME_SURPLUS_HR = 'time_surplus_hr'
local KEY_TIME_SURPLUS_MIN = 'time_surplus_min'
local KEY_ERROR_CODE = 'error_code'
local KEY_WORK_STAGE = 'work_stage'

local VALUE_VERSION = '5'
local VALUE_STANDBY = 'standby'
local VALUE_START = 'start'
local VALUE_RESERVE = 'reserve'
local VALUE_WARM = 'warm'
local VALUE_SUSPEND = 'suspend'
local VALUE_POWER_OFF = 'off'
local VALUE_RESPONSE_NORMAL = 'response_normal'
local VALUE_RESPONSE_ERROR = 'response_error'

local BYTE_DEVICE_TYPE = 0xE7
local BYTE_MSG_TYPE_CONTROL = 0x02
local BYTE_MSG_TYPE_QUERY = 0x03
local BYTE_ATTRIBUTE_TYPE_FROM_MCU = 0x81
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_HEAD_LENGTH = 0x0A
local BYTE_PACKAGE_LENGTH_CONTROL = 0x1A
local BYTE_PACKAGE_LENGTH_QUERY = 0x18
local BYTE_RESPONSE_NORMAL = 0x01
local BYTE_RESPONSE_ERROR = 0x00
local BYTE_STATUS_STANDBY = 0x00
local BYTE_STATUS_START = 0x01
local BYTE_STATUS_RESERVE = 0x02
local BYTE_STATUS_WARM = 0x03
local BYTE_STATUS_SUSPEND = 0x04
local BYTE_STATUS_POWER_OFF = 0x05

local cmdCodeHigh
local cmdCodeLow
local functionNo
local workStatus
local timeReserveMin = 0
local timeReserveHr = 0
local fireLevel = 0
local definiteTimeHr = 0
local definiteTimeMin = 0
local responseType
local timeRunningMin = 0
local timeRunningHr = 0
local timeSurplusMin = 0
local timeSurplusHr = 0
local errorCode = 0
local workStage = 0
local dataType = 0
local deviceSubType = '0'

local function getSoftVersion()
    if deviceSubType == '6' then
        return 1
    elseif deviceSubType == '10' then
        return 3
    elseif deviceSubType == '8' or deviceSubType == '9' then
        return 4
    else
        return 0
    end
end

local function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[8] = getSoftVersion()
    msgBytes[9] = cType
    for i = 0, bodyLength do
        msgBytes[i + BYTE_PROTOCOL_HEAD_LENGTH] = bodyData[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
end

local function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams[KEY_FUNCTION_NO] ~= nil) then
        functionNo = string2Int(streams[KEY_FUNCTION_NO])
    end
    if (streams[KEY_WORK_STATUS] ~= nil) then
        workStatus = string2Int(streams[KEY_WORK_STATUS])
    end
    if (streams[KEY_TIME_RESERVE_MIN] ~= nil) then
        timeReserveMin = checkBoundary(streams[KEY_TIME_RESERVE_MIN], 0, 59)
    end
    if (streams[KEY_TIME_RESERVE_HR] ~= nil) then
        timeReserveHr = checkBoundary(streams[KEY_TIME_RESERVE_HR], 0, 23)
    end
    if (streams[KEY_FIRE_LEVEL] ~= nil) then
        fireLevel = checkBoundary(streams[KEY_FIRE_LEVEL], 0, 21)
    end
    if (streams[KEY_DEFINITE_TIME_MIN] ~= nil) then
        definiteTimeMin = checkBoundary(streams[KEY_DEFINITE_TIME_MIN], 0, 59)
    end
    if (streams[KEY_DEFINITE_TIME_HR] ~= nil) then
        definiteTimeHr = checkBoundary(streams[KEY_DEFINITE_TIME_HR], 0, 23)
    end
end

local function binToModel(binData)
    if (#binData < 11) then return nil end
    local messageBytes = binData
    if getSoftVersion() == 1 then
        if (dataType == 0x02 or dataType == 0x03) then
            cmdCodeLow = messageBytes[7]
            cmdCodeHigh = messageBytes[8]
            responseType = messageBytes[9]
            workStatus = messageBytes[10]
            functionNo = bit.lshift(messageBytes[11], 8) + messageBytes[12]
            timeRunningHr = messageBytes[13]
            timeRunningMin = messageBytes[14]
            timeSurplusHr = messageBytes[15]
            timeSurplusMin = messageBytes[16]
            timeReserveHr = messageBytes[17]
            timeReserveMin = messageBytes[18]
            fireLevel = messageBytes[19]
            definiteTimeHr = messageBytes[20]
            definiteTimeMin = messageBytes[21]
            workStage = messageBytes[22]
            errorCode = messageBytes[23]
        elseif (dataType == 0x04) then
            cmdCodeLow = messageBytes[7]
            cmdCodeHigh = messageBytes[8]
            if (cmdCodeLow == 0x14 and cmdCodeHigh == 0x27) then
                workStatus = messageBytes[10]
                functionNo = bit.lshift(messageBytes[11], 8) + messageBytes[12]
                timeRunningHr = messageBytes[13]
                timeRunningMin = messageBytes[14]
                timeSurplusHr = messageBytes[15]
                timeSurplusMin = messageBytes[16]
                timeReserveHr = messageBytes[17]
                timeReserveMin = messageBytes[18]
                fireLevel = messageBytes[19]
                definiteTimeHr = messageBytes[20]
                definiteTimeMin = messageBytes[21]
                workStage = messageBytes[22]
                errorCode = messageBytes[23]
            elseif (cmdCodeLow == 0x16 and cmdCodeHigh == 0x27) then
                errorCode = messageBytes[10]
            end
        end
    elseif getSoftVersion() == 3 then
        if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04 or dataType ==
            0x06) then
            cmdCodeLow = messageBytes[7]
            cmdCodeHigh = messageBytes[8]
            responseType = messageBytes[9]
            workStatus = messageBytes[10]
            functionNo = bit.lshift(messageBytes[11], 24) +
                             bit.lshift(messageBytes[12], 16) +
                             bit.lshift(messageBytes[13], 8) + messageBytes[14]
            timeRunningHr = messageBytes[15]
            timeRunningMin = messageBytes[16]
            timeSurplusHr = messageBytes[17]
            timeSurplusMin = messageBytes[18]
            timeReserveHr = messageBytes[19]
            timeReserveMin = messageBytes[20]
            fireLevel = messageBytes[21]
            definiteTimeHr = messageBytes[22]
            definiteTimeMin = messageBytes[23]
            workStage = messageBytes[24]
            errorCode = messageBytes[25]
        end
    elseif getSoftVersion() == 4 then
        cmdCodeLow = messageBytes[7]
        cmdCodeHigh = messageBytes[8]
        if (dataType == 0x02 or dataType == 0x03) then
            responseType = messageBytes[9]
            workStatus = messageBytes[10]
            functionNo = bit.lshift(messageBytes[11], 24) +
                             bit.lshift(messageBytes[12], 16) +
                             bit.lshift(messageBytes[13], 8) + messageBytes[14]
            timeRunningHr = messageBytes[15]
            timeRunningMin = messageBytes[16]
            timeSurplusHr = messageBytes[17]
            timeSurplusMin = messageBytes[18]
            timeReserveHr = messageBytes[19]
            timeReserveMin = messageBytes[20]
            fireLevel = messageBytes[21]
            definiteTimeHr = messageBytes[22]
            definiteTimeMin = messageBytes[23]
            workStage = messageBytes[24]
            errorCode = messageBytes[25]
        end
        if (dataType == 0x04) and (cmdCodeLow == 0x14) and (cmdCodeHigh == 0x27) then
            responseType = messageBytes[9]
            workStatus = messageBytes[10]
            functionNo = bit.lshift(messageBytes[11], 24) +
                             bit.lshift(messageBytes[12], 16) +
                             bit.lshift(messageBytes[13], 8) + messageBytes[14]
            timeRunningHr = messageBytes[15]
            timeRunningMin = messageBytes[16]
            timeSurplusHr = messageBytes[17]
            timeSurplusMin = messageBytes[18]
            timeReserveHr = messageBytes[19]
            timeReserveMin = messageBytes[20]
            fireLevel = messageBytes[21]
            definiteTimeHr = messageBytes[22]
            definiteTimeMin = messageBytes[23]
            workStage = messageBytes[24]
            errorCode = messageBytes[25]
        end
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local infoM = {}
    local bodyBytes = {}
    local json = decode(jsonCmd)
    deviceSubType = json['deviceinfo']['deviceSubType']
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if getSoftVersion() == 1 then
        if (query) then
            for i = 0, 14 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x02
            bodyBytes[4] = 0x0F
            bodyBytes[5] = 0x82
            bodyBytes[6] = 0xA0
            bodyBytes[7] = 0x53
            bodyBytes[8] = 0xC3
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_QUERY)
        elseif (control) then
            if (status) then jsonToModel(status) end
            if (control) then jsonToModel(control) end
            for i = 0, 16 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x02
            bodyBytes[4] = 0x11
            bodyBytes[5] = 0x82
            bodyBytes[6] = 0xA0
            bodyBytes[7] = 0x11
            bodyBytes[8] = 0x27
            bodyBytes[9] = bit.band(bit.rshift(functionNo, 8), 0xFF)
            bodyBytes[10] = bit.band(functionNo, 0xFF)
            bodyBytes[11] = workStatus
            bodyBytes[12] = timeReserveHr
            bodyBytes[13] = timeReserveMin
            bodyBytes[14] = fireLevel
            bodyBytes[15] = definiteTimeHr
            bodyBytes[16] = definiteTimeMin
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_CONTROL)
        end
    elseif getSoftVersion() == 3 then
        if (query) then
            for i = 0, 14 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x02
            bodyBytes[4] = 0x0F
            bodyBytes[5] = 0x82
            bodyBytes[6] = 0xA0
            bodyBytes[7] = 0x53
            bodyBytes[8] = 0xC3
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_QUERY)
        elseif (control) then
            if (status) then jsonToModel(status) end
            if (control) then jsonToModel(control) end
            for i = 0, 16 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x02
            bodyBytes[4] = 0x13
            bodyBytes[5] = 0x82
            bodyBytes[6] = 0xA0
            bodyBytes[7] = bit.band(10001, 0xFF)
            bodyBytes[8] = bit.band(bit.rshift(10001, 8), 0xFF)
            bodyBytes[9] = bit.band(bit.rshift(functionNo, 24), 0xFF)
            bodyBytes[10] = bit.band(bit.rshift(functionNo, 16), 0xFF)
            bodyBytes[11] = bit.band(bit.rshift(functionNo, 8), 0xFF)
            bodyBytes[12] = bit.band(functionNo, 0xFF)
            bodyBytes[13] = workStatus
            bodyBytes[14] = timeReserveHr
            bodyBytes[15] = timeReserveMin
            bodyBytes[16] = fireLevel
            bodyBytes[17] = definiteTimeHr
            bodyBytes[18] = definiteTimeMin
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_CONTROL)
        end
    elseif getSoftVersion() == 4 then
        if (query) then
            for i = 0, 14 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x02
            bodyBytes[4] = 0x0F
            bodyBytes[5] = 0x82
            bodyBytes[6] = 0xA0
            bodyBytes[7] = 0x53
            bodyBytes[8] = 0xC3
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_QUERY)
        elseif (control) then
            if (status) then jsonToModel(status) end
            if (control) then jsonToModel(control) end
            for i = 0, 16 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x02
            bodyBytes[4] = 0x13
            bodyBytes[5] = 0x82
            bodyBytes[6] = 0xA0
            bodyBytes[7] = bit.band(10001, 0xFF)
            bodyBytes[8] = bit.band(bit.rshift(10001, 8), 0xFF)
            bodyBytes[9] = bit.band(bit.rshift(functionNo, 24), 0xFF)
            bodyBytes[10] = bit.band(bit.rshift(functionNo, 16), 0xFF)
            bodyBytes[11] = bit.band(bit.rshift(functionNo, 8), 0xFF)
            bodyBytes[12] = bit.band(functionNo, 0xFF)
            bodyBytes[13] = workStatus
            bodyBytes[14] = timeReserveHr
            bodyBytes[15] = timeReserveMin
            bodyBytes[16] = fireLevel
            bodyBytes[17] = definiteTimeHr
            bodyBytes[18] = definiteTimeMin
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_CONTROL)
        end
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function dataToJson(jsonCmd)
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceinfo = json['deviceinfo']
    deviceSubType = deviceinfo['deviceSubType']
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
    if getSoftVersion() == 1 then
        if (dataType == 0x02 or dataType == 0x03) then
            if (responseType == BYTE_RESPONSE_NORMAL) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_NORMAL
            elseif (responseType == BYTE_RESPONSE_ERROR) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_ERROR
            end
            streams[KEY_WORK_STATUS] = int2String(workStatus)
            streams[KEY_FUNCTION_NO] = int2String(functionNo)
            streams[KEY_TIME_RUNNING_HR] = int2String(timeRunningHr)
            streams[KEY_TIME_RUNNING_MIN] = int2String(timeRunningMin)
            streams[KEY_TIME_SURPLUS_HR] = int2String(timeSurplusHr)
            streams[KEY_TIME_SURPLUS_MIN] = int2String(timeSurplusMin)
            streams[KEY_TIME_RESERVE_HR] = int2String(timeReserveHr)
            streams[KEY_TIME_RESERVE_MIN] = int2String(timeReserveMin)
            streams[KEY_FIRE_LEVEL] = int2String(fireLevel)
            streams[KEY_DEFINITE_TIME_HR] = int2String(definiteTimeHr)
            streams[KEY_DEFINITE_TIME_MIN] = int2String(definiteTimeMin)
            streams[KEY_WORK_STAGE] = int2String(workStage)
            streams[KEY_ERROR_CODE] = int2String(errorCode)
        elseif (dataType == 0x04) then
            if (cmdCodeHigh == 0x27 and cmdCodeLow == 0x16) then
                streams[KEY_ERROR_CODE] = int2String(errorCode)
            elseif (cmdCodeHigh == 0x27 and cmdCodeLow == 0x14) then
                streams[KEY_WORK_STATUS] = int2String(workStatus)
                streams[KEY_FUNCTION_NO] = int2String(functionNo)
                streams[KEY_TIME_RUNNING_HR] = int2String(timeRunningHr)
                streams[KEY_TIME_RUNNING_MIN] = int2String(timeRunningMin)
                streams[KEY_TIME_SURPLUS_HR] = int2String(timeSurplusHr)
                streams[KEY_TIME_SURPLUS_MIN] = int2String(timeSurplusMin)
                streams[KEY_TIME_RESERVE_HR] = int2String(timeReserveHr)
                streams[KEY_TIME_RESERVE_MIN] = int2String(timeReserveMin)
                streams[KEY_FIRE_LEVEL] = int2String(fireLevel)
                streams[KEY_DEFINITE_TIME_HR] = int2String(definiteTimeHr)
                streams[KEY_DEFINITE_TIME_MIN] = int2String(definiteTimeMin)
                streams[KEY_WORK_STAGE] = int2String(workStage)
                streams[KEY_ERROR_CODE] = int2String(errorCode)
            end
        end
    elseif getSoftVersion() == 3 then
        if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04 or dataType ==
            0x06) then
            if (responseType == BYTE_RESPONSE_NORMAL) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_NORMAL
            elseif (responseType == BYTE_RESPONSE_ERROR) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_ERROR
            end
            streams[KEY_WORK_STATUS] = int2String(workStatus)
            streams[KEY_FUNCTION_NO] = int2String(functionNo)
            streams[KEY_TIME_RUNNING_HR] = int2String(timeRunningHr)
            streams[KEY_TIME_RUNNING_MIN] = int2String(timeRunningMin)
            streams[KEY_TIME_SURPLUS_HR] = int2String(timeSurplusHr)
            streams[KEY_TIME_SURPLUS_MIN] = int2String(timeSurplusMin)
            streams[KEY_TIME_RESERVE_HR] = int2String(timeReserveHr)
            streams[KEY_TIME_RESERVE_MIN] = int2String(timeReserveMin)
            streams[KEY_FIRE_LEVEL] = int2String(fireLevel)
            streams[KEY_DEFINITE_TIME_HR] = int2String(definiteTimeHr)
            streams[KEY_DEFINITE_TIME_MIN] = int2String(definiteTimeMin)
            streams[KEY_WORK_STAGE] = int2String(workStage)
            streams[KEY_ERROR_CODE] = int2String(errorCode)
        end
    elseif getSoftVersion() == 4 then
        if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04 or dataType ==
            0x06) then
            if (responseType == BYTE_RESPONSE_NORMAL) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_NORMAL
            elseif (responseType == BYTE_RESPONSE_ERROR) then
                streams[KEY_RESPONSE] = VALUE_RESPONSE_ERROR
            end
            streams[KEY_WORK_STATUS] = int2String(workStatus)
            streams[KEY_FUNCTION_NO] = int2String(functionNo)
            streams[KEY_TIME_RUNNING_HR] = int2String(timeRunningHr)
            streams[KEY_TIME_RUNNING_MIN] = int2String(timeRunningMin)
            streams[KEY_TIME_SURPLUS_HR] = int2String(timeSurplusHr)
            streams[KEY_TIME_SURPLUS_MIN] = int2String(timeSurplusMin)
            streams[KEY_TIME_RESERVE_HR] = int2String(timeReserveHr)
            streams[KEY_TIME_RESERVE_MIN] = int2String(timeReserveMin)
            streams[KEY_FIRE_LEVEL] = int2String(fireLevel)
            streams[KEY_DEFINITE_TIME_HR] = int2String(definiteTimeHr)
            streams[KEY_DEFINITE_TIME_MIN] = int2String(definiteTimeMin)
            streams[KEY_WORK_STAGE] = int2String(workStage)
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
