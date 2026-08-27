local uptable = {}
local JSON = require 'cjson'
local KEY_VERSION = 'version'

uptable['KEY_POWER'] = 'power'
uptable['KEY_STAGE1'] = 'stage_1'
uptable['KEY_STAGE2'] = 'stage_2'
uptable['KEY_STAGE3'] = 'stage_3'
uptable['KEY_STAGE_1_time'] = 'stage_1_time'
uptable['KEY_STAGE_2_time'] = 'stage_2_time'
uptable['KEY_STAGE_3_time'] = 'stage_3_time'
uptable['KEY_CURRENT_STAGE'] = 'current_stage'
uptable['KEY_CURRENT_FUNCTION'] = 'current_function'
uptable['KEY_CURRENT_STAGE_TIME'] = 'current_stage_time'
uptable['KEY_STAGE_ALL_TIME'] = 'stage_all_time'
uptable['KEY_ERROR_CODE'] = 'error_code'
uptable['VALUE_VERSION'] = 2
uptable['VALUE_FUNCTION_ON'] = 'on'
uptable['VALUE_FUNCTION_OFF'] = 'off'
uptable['VALUE_STAGE_LOW'] = 'low'
uptable['VALUE_STAGE_HIHG'] = 'high'
uptable['VALUE_STAGE_WARM'] = 'warm'
uptable['VALUE_UNKNOW'] = '0'
uptable['BYTE_DEVICE_TYPE'] = 0xE8
uptable['BYTE_CONTROL_REQUEST'] = 0x02
uptable['BYTE_QUERY_REQUEST'] = 0x03
uptable['BYTE_REPORT_REQUEST'] = 0x04
uptable['BYTE_PROTOCOL_HEAD'] = 0xAA
uptable['BYTE_PROTOCOL_LENGTH'] = 0x0A
uptable['BYTE_POWER_ON'] = 0x01
uptable['BYTE_POWER_OFF'] = 0x00
uptable['BYTE_STAGE_LOW'] = 0x01
uptable['BYTE_STAGE_HIHG'] = 0x02
uptable['BYTE_STAGE_WARM'] = 0x03
uptable['BYTE_MESSAGE_BODY_DOCK_1'] = 0xAA
uptable['BYTE_MESSAGE_BODY_DOCK_2'] = 0x55
uptable['BYTE_CONTROL_BODY_LENGTH'] = 0x12
uptable['BYTE_QUERY_BODY_LENGTH'] = 0x08
uptable['BYTE_COMMOND_DOWN'] = 0x02
uptable['BYTE_COMMOND_UP'] = 0x16
uptable['BYTE_QUERY_PREFIX'] = 0xC3
uptable['BYTE_QUERY_STATUS'] = 0x52

local powerValue = 0
local stage1Value = 0
local stage2Value = 0
local stage3Value = 0
local stage1TimeValue = 0
local stage2TimeValue = 0
local stage3TimeValue = 0
local currentStage = 0
local currentFunction = 0
local currentStageTime = 0
local stageAllTime = 0
local defaultWarmTime = 240
local defaultHighAndLowTime = 360
local errorCode = 0
local dataType = 0

function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams[uptable['KEY_POWER']] == uptable['VALUE_FUNCTION_ON']) then
        powerValue = uptable['BYTE_POWER_ON']
    elseif (streams[uptable['KEY_POWER']] == uptable['VALUE_FUNCTION_OFF']) then
        powerValue = uptable['BYTE_POWER_OFF']
    end
    if (streams[uptable['KEY_STAGE1']] == uptable['VALUE_STAGE_LOW']) then
        stage1Value = uptable['BYTE_STAGE_LOW']
    elseif (streams[uptable['KEY_STAGE1']] == uptable['VALUE_STAGE_HIHG']) then
        stage1Value = uptable['BYTE_STAGE_HIHG']
    elseif (streams[uptable['KEY_STAGE1']] == uptable['VALUE_STAGE_WARM']) then
        stage1Value = uptable['BYTE_STAGE_WARM']
    end
    if (streams[uptable['KEY_STAGE2']] == uptable['VALUE_STAGE_LOW']) then
        stage2Value = uptable['BYTE_STAGE_LOW']
    elseif (streams[uptable['KEY_STAGE2']] == uptable['VALUE_STAGE_HIHG']) then
        stage2Value = uptable['BYTE_STAGE_HIHG']
    elseif (streams[uptable['KEY_STAGE2']] == uptable['VALUE_STAGE_WARM']) then
        stage2Value = uptable['BYTE_STAGE_WARM']
    end
    if (streams[uptable['KEY_STAGE3']] == uptable['VALUE_STAGE_LOW']) then
        stage3Value = uptable['BYTE_STAGE_LOW']
    elseif (streams[uptable['KEY_STAGE3']] == uptable['VALUE_STAGE_HIHG']) then
        stage3Value = uptable['BYTE_STAGE_HIHG']
    elseif (streams[uptable['KEY_STAGE3']] == uptable['VALUE_STAGE_WARM']) then
        stage3Value = uptable['BYTE_STAGE_WARM']
    end
    if (streams[uptable['KEY_STAGE_1_time']] ~= nil) then
        if (stage1Value == uptable['BYTE_STAGE_WARM']) then
            stage1TimeValue = checkBoundary(
                                  streams[uptable['KEY_STAGE_1_time']], 30, 240)
        elseif ((stage1Value == uptable['BYTE_STAGE_LOW']) or
            (stage1Value == uptable['BYTE_STAGE_HIHG'])) then
            stage1TimeValue = checkBoundary(
                                  streams[uptable['KEY_STAGE_1_time']], 30, 600)
        end
    else
        if (stage1Value == uptable['BYTE_STAGE_WARM']) then
            stage1TimeValue = defaultWarmTime
        elseif ((stage1Value == uptable['BYTE_STAGE_LOW']) or
            (stage1Value == uptable['BYTE_STAGE_HIHG'])) then
            stage1TimeValue = defaultHighAndLowTime
        end
    end
    if (streams[uptable['KEY_STAGE_2_time']] ~= nil) then
        if (stage2Value == uptable['BYTE_STAGE_WARM']) then
            stage2TimeValue = checkBoundary(
                                  streams[uptable['KEY_STAGE_2_time']], 30, 240)
        elseif ((stage2Value == uptable['BYTE_STAGE_LOW']) or
            (stage2Value == uptable['BYTE_STAGE_HIHG'])) then
            stage2TimeValue = checkBoundary(
                                  streams[uptable['KEY_STAGE_2_time']], 30, 600)
        end
    else
        if (stage2Value == uptable['BYTE_STAGE_WARM']) then
            stage2TimeValue = defaultWarmTime
        elseif ((stage2Value == uptable['BYTE_STAGE_LOW']) or
            (stage2Value == uptable['BYTE_STAGE_HIHG'])) then
            stage2TimeValue = defaultHighAndLowTime
        end
    end
    if (streams[uptable['KEY_STAGE_3_time']] ~= nil) then
        if (stage3Value == uptable['BYTE_STAGE_WARM']) then
            stage3TimeValue = checkBoundary(
                                  streams[uptable['KEY_STAGE_3_time']], 30, 240)
        elseif ((stage3Value == uptable['BYTE_STAGE_LOW']) or
            (stage3Value == uptable['BYTE_STAGE_HIHG'])) then
            stage3TimeValue = checkBoundary(
                                  streams[uptable['KEY_STAGE_3_time']], 30, 600)
        end
    else
        if (stage3Value == uptable['BYTE_STAGE_WARM']) then
            stage3TimeValue = defaultWarmTime
        elseif ((stage3Value == uptable['BYTE_STAGE_LOW']) or
            (stage3Value == uptable['BYTE_STAGE_HIHG'])) then
            stage3TimeValue = defaultHighAndLowTime
        end
    end
end

function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = binData
    powerValue = messageBytes[8]
    stage1Value = messageBytes[9]
    stage1TimeValue = messageBytes[11] * 60 + messageBytes[10]
    stage2Value = messageBytes[12]
    stage2TimeValue = messageBytes[14] * 60 + messageBytes[13]
    stage3Value = messageBytes[15]
    stage3TimeValue = messageBytes[17] * 60 + messageBytes[16]
    stageAllTime = messageBytes[19] * 60 + messageBytes[18]
    if messageBytes[7] ~= 0x01 then errorCode = messageBytes[7] end
end

function binToModel4Query(binData)
    if (#binData == 0) then return nil end
    local messageBytes = binData
    powerValue = messageBytes[10]
    stage1Value = messageBytes[11]
    stage2Value = messageBytes[12]
    stage3Value = messageBytes[13]
    currentStage = messageBytes[14]
    currentFunction = messageBytes[15]
    currentStageTime = messageBytes[17] * 60 + messageBytes[16]
    stageAllTime = messageBytes[19] * 60 + messageBytes[18]
    if messageBytes[9] ~= 0x01 then errorCode = messageBytes[9] end
end

function binToModel4Report(binData)
    if (#binData == 0) then return nil end
    local messageBytes = binData
    powerValue = messageBytes[8]
    stage1Value = messageBytes[9]
    stage2Value = messageBytes[10]
    stage3Value = messageBytes[11]
    currentStage = messageBytes[12]
    currentFunction = messageBytes[13]
    currentStageTime = messageBytes[15] * 60 + messageBytes[14]
    stageAllTime = messageBytes[17] * 60 + messageBytes[16]
    if messageBytes[7] ~= 0x01 then errorCode = messageBytes[9] end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    local bodyLength
    if (query) then
        bodyLength = uptable['BYTE_QUERY_BODY_LENGTH'] - 1
    elseif (control) then
        bodyLength = uptable['BYTE_CONTROL_BODY_LENGTH'] - 1
    end
    local msgLength = bodyLength + uptable['BYTE_PROTOCOL_LENGTH'] + 1
    local bodyBytes = {}
    for i = 0, bodyLength do bodyBytes[i] = 0 end
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = uptable['BYTE_PROTOCOL_HEAD']
    msgBytes[1] = bodyLength + uptable['BYTE_PROTOCOL_LENGTH'] + 1
    msgBytes[2] = uptable['BYTE_DEVICE_TYPE']
    if (query) then
        bodyBytes[0] = uptable['BYTE_MESSAGE_BODY_DOCK_1']
        bodyBytes[1] = uptable['BYTE_MESSAGE_BODY_DOCK_2']
        bodyBytes[3] = uptable['BYTE_QUERY_BODY_LENGTH']
        bodyBytes[4] = uptable['BYTE_COMMOND_DOWN']
        bodyBytes[6] = uptable['BYTE_QUERY_PREFIX']
        bodyBytes[5] = uptable['BYTE_QUERY_STATUS']
        bodyBytes[bodyLength] = makeSum(bodyBytes, 0, bodyLength - 1)
        msgBytes[9] = uptable['BYTE_QUERY_REQUEST']
    elseif (control) then
        if (status) then jsonToModel(status) end
        local oldPower = powerValue
        if (control) then jsonToModel(control) end
        local newPower = powerValue
        bodyBytes[7] = powerValue
        bodyBytes[8] = stage1Value
        bodyBytes[9] = math.floor(stage1TimeValue % 60)
        bodyBytes[10] = math.floor(stage1TimeValue / 60)
        bodyBytes[11] = stage2Value
        bodyBytes[12] = math.floor(stage2TimeValue % 60)
        bodyBytes[13] = math.floor(stage2TimeValue / 60)
        bodyBytes[14] = stage3Value
        bodyBytes[15] = math.floor(stage3TimeValue % 60)
        bodyBytes[16] = math.floor(stage3TimeValue / 60)
        bodyBytes[0] = uptable['BYTE_MESSAGE_BODY_DOCK_1']
        bodyBytes[1] = uptable['BYTE_MESSAGE_BODY_DOCK_2']
        bodyBytes[3] = uptable['BYTE_CONTROL_BODY_LENGTH']
        bodyBytes[4] = uptable['BYTE_COMMOND_DOWN']
        bodyBytes[bodyLength] = makeSum(bodyBytes, 0, bodyLength - 1)
        msgBytes[9] = uptable['BYTE_CONTROL_REQUEST']
    end
    for i = 0, bodyLength do
        msgBytes[i + uptable['BYTE_PROTOCOL_LENGTH']] = bodyBytes[i]
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
    dataType = info[10]
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - uptable['BYTE_PROTOCOL_LENGTH'] - 1
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then end
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + uptable['BYTE_PROTOCOL_LENGTH']]
    end
    if dataType == 0x02 then
        binToModel(bodyBytes)
    elseif dataType == 0x03 then
        binToModel4Query(bodyBytes)
    elseif dataType == 0x04 then
        binToModel4Report(bodyBytes)
    end
    local streams = {}
    streams[KEY_VERSION] = uptable['VALUE_VERSION']
    if (powerValue == uptable['BYTE_POWER_ON']) then
        streams[uptable['KEY_POWER']] = uptable['VALUE_FUNCTION_ON']
    elseif (powerValue == uptable['BYTE_POWER_OFF']) then
        streams[uptable['KEY_POWER']] = uptable['VALUE_FUNCTION_OFF']
    else
        streams[uptable['KEY_POWER']] = uptable['VALUE_UNKNOW']
    end
    if (stage1Value == uptable['BYTE_STAGE_LOW']) then
        streams[uptable['KEY_STAGE1']] = uptable['VALUE_STAGE_LOW']
    elseif (stage1Value == uptable['BYTE_STAGE_HIHG']) then
        streams[uptable['KEY_STAGE1']] = uptable['VALUE_STAGE_HIHG']
    elseif (stage1Value == uptable['BYTE_STAGE_WARM']) then
        streams[uptable['KEY_STAGE1']] = uptable['VALUE_STAGE_WARM']
    else
        streams[uptable['KEY_STAGE1']] = uptable['VALUE_UNKNOW']
    end
    if (stage2Value == uptable['BYTE_STAGE_LOW']) then
        streams[uptable['KEY_STAGE2']] = uptable['VALUE_STAGE_LOW']
    elseif (stage2Value == uptable['BYTE_STAGE_HIHG']) then
        streams[uptable['KEY_STAGE2']] = uptable['VALUE_STAGE_HIHG']
    elseif (stage2Value == uptable['BYTE_STAGE_WARM']) then
        streams[uptable['KEY_STAGE2']] = uptable['VALUE_STAGE_WARM']
    else
        streams[uptable['KEY_STAGE2']] = uptable['VALUE_UNKNOW']
    end
    if (stage3Value == uptable['BYTE_STAGE_LOW']) then
        streams[uptable['KEY_STAGE3']] = uptable['VALUE_STAGE_LOW']
    elseif (stage3Value == uptable['BYTE_STAGE_HIHG']) then
        streams[uptable['KEY_STAGE3']] = uptable['VALUE_STAGE_HIHG']
    elseif (stage3Value == uptable['BYTE_STAGE_WARM']) then
        streams[uptable['KEY_STAGE3']] = uptable['VALUE_STAGE_WARM']
    else
        streams[uptable['KEY_STAGE3']] = uptable['VALUE_UNKNOW']
    end
    streams[uptable['KEY_STAGE_1_time']] = tostring(stage1TimeValue)
    streams[uptable['KEY_STAGE_2_time']] = tostring(stage2TimeValue)
    streams[uptable['KEY_STAGE_3_time']] = tostring(stage3TimeValue)
    streams[uptable['KEY_CURRENT_STAGE']] = tostring(currentStage)
    streams[uptable['KEY_CURRENT_STAGE_TIME']] = tostring(currentStageTime)
    streams[uptable['KEY_STAGE_ALL_TIME']] = tostring(stageAllTime)
    if (currentFunction == uptable['BYTE_STAGE_LOW']) then
        streams[uptable['KEY_CURRENT_FUNCTION']] = uptable['VALUE_STAGE_LOW']
    elseif (currentFunction == uptable['BYTE_STAGE_HIHG']) then
        streams[uptable['KEY_CURRENT_FUNCTION']] = uptable['VALUE_STAGE_HIHG']
    elseif (currentFunction == uptable['BYTE_STAGE_WARM']) then
        streams[uptable['KEY_CURRENT_FUNCTION']] = uptable['VALUE_STAGE_WARM']
    else
        streams[uptable['KEY_CURRENT_FUNCTION']] = uptable['VALUE_UNKNOW']
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
