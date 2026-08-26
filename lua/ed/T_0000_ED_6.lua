local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_WASH = 'wash'
local KEY_FILTER = 'filter'
local KEY_HEAT = 'heat'
local KEY_HEAT_STATUS = 'heat_status'
local KEY_COOL = 'cool'
local KEY_COOL_STATUS = 'cool_status'
local KEY_LOCK = 'lock'
local KEY_UV_STERILIZE = 'uv_sterilize'
local KEY_HEAT_TEMPERATURE = 'heat_temperature'
local KEY_COOL_TEMPERATURE = 'cool_temperature'
local KEY_DRAINAGE = 'drainage'
local KEY_FILTER_1 = 'filter_1'
local KEY_FILTER_2 = 'filter_2'
local KEY_FILTER_3 = 'filter_3'
local KEY_FILTER_4 = 'filter_4'
local KEY_FILTER_5 = 'filter_5'
local KEY_ERROR_CODE = 'error_code'
local KEY_LACK_WATER = 'lack_water'
local KEY_LIFE_1 = 'life_1'
local KEY_LIFE_2 = 'life_2'
local KEY_LIFE_3 = 'life_3'
local KEY_LIFE_4 = 'life_4'
local KEY_LIFE_5 = 'life_5'
local KEY_IN_TSD = 'in_tsd'
local KEY_OUT_TSD = 'out_tsd'
local KEY_WATER_LITRE = 'water_litre'

local VALUE_VERSION = 6
local VALUE_ON = 'on'
local VALUE_OFF = 'off'

local BYTE_DEVICE_TYPE = 0xED
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_WASH_ON = 0x80
local BYTE_WASH_OFF = 0x7F

local filter1
local filter2
local filter3
local filter4
local filter5
local life1
local life2
local life3
local life4
local life5
local errorCode
local byte12 = 0
local byte13 = 0
local byte14 = 0
local byte15 = 0
local byte22 = 0
local byte25 = 0
local heatTemp = 0
local coolTemp = 0
local inTSD = 0
local outTSD = 0
local waterLitre = 0
local dataType = 0

function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_WASH] == VALUE_ON then
        byte12 = bit.bor(byte12, BYTE_WASH_ON)
    elseif luaTable[KEY_WASH] == VALUE_OFF then
        byte12 = bit.band(byte12, BYTE_WASH_OFF)
    end
    if luaTable[KEY_HEAT] == VALUE_ON then
        byte12 = bit.bor(byte12, 0x01)
    elseif luaTable[KEY_HEAT] == VALUE_OFF then
        byte12 = bit.band(byte12, 0xFE)
    end
    if luaTable[KEY_COOL] == VALUE_ON then
        byte12 = bit.bor(byte12, 0x02)
    elseif luaTable[KEY_COOL] == VALUE_OFF then
        byte12 = bit.band(byte12, 0xFD)
    end
    if luaTable[KEY_LOCK] == VALUE_ON then
        byte22 = bit.bor(byte22, 0x02)
    elseif luaTable[KEY_LOCK] == VALUE_OFF then
        byte22 = bit.band(byte22, 0xFD)
    end
    if luaTable[KEY_HEAT_TEMPERATURE] ~= nil then
        coolTemp = luaTable[KEY_HEAT_TEMPERATURE]
    end
    if luaTable[KEY_COOL_TEMPERATURE] ~= nil then
        coolTemp = luaTable[KEY_COOL_TEMPERATURE]
    end
end

function updateGlobalPropertyValueByByte(messageBytes)
    if ((dataType == 0x03 and messageBytes[0] == 0x01) or
        (dataType == 0x02 and messageBytes[0] == 0x01) or
        (dataType == 0x02 and messageBytes[0] == 0x02) or
        (dataType == 0x02 and messageBytes[0] == 0x04)) then
        byte12 = messageBytes[2]
        byte13 = messageBytes[3]
        byte14 = messageBytes[4]
        byte15 = messageBytes[5]
        waterLitre = bit.lshift(messageBytes[8], 8) + messageBytes[7]
        heatTemp = messageBytes[10]
        coolTemp = messageBytes[11]
        byte25 = messageBytes[15]
        filter1 = bit.lshift(messageBytes[26], 8) + messageBytes[25]
        filter2 = bit.lshift(messageBytes[28], 8) + messageBytes[27]
        filter3 = bit.lshift(messageBytes[30], 8) + messageBytes[29]
        filter4 = bit.lshift(messageBytes[32], 8) + messageBytes[31]
        filter5 = bit.lshift(messageBytes[34], 8) + messageBytes[33]
        life1 = messageBytes[16]
        life2 = messageBytes[17]
        life3 = messageBytes[18]
        life4 = messageBytes[19]
        life5 = messageBytes[20]
        errorCode = messageBytes[13]
        inTSD = bit.lshift(messageBytes[37], 8) + messageBytes[36]
        outTSD = bit.lshift(messageBytes[39], 8) + messageBytes[38]
    end
end

function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (bit.band(byte12, 0x01) == 0x01) then
        streams[KEY_POWER] = VALUE_ON
    else
        streams[KEY_POWER] = VALUE_OFF
    end
    if (bit.band(byte12, 0x02) == 0x02) then
        streams[KEY_HEAT] = VALUE_ON
    else
        streams[KEY_HEAT] = VALUE_OFF
    end
    if (bit.band(byte12, 0x04) == 0x04) then
        streams[KEY_HEAT_STATUS] = VALUE_ON
    else
        streams[KEY_HEAT_STATUS] = VALUE_OFF
    end
    if (bit.band(byte12, 0x08) == 0x08) then
        streams[KEY_COOL] = VALUE_ON
    else
        streams[KEY_COOL] = VALUE_OFF
    end
    if (bit.band(byte12, 0x10) == 0x10) then
        streams[KEY_COOL_STATUS] = VALUE_ON
    else
        streams[KEY_COOL_STATUS] = VALUE_OFF
    end
    if (bit.band(byte13, 0x20) == 0x20) then
        streams[KEY_FILTER] = VALUE_ON
    else
        streams[KEY_FILTER] = VALUE_OFF
    end
    if (bit.band(byte13, 0x40) == 0x40) then
        streams[KEY_WASH] = VALUE_ON
    else
        streams[KEY_WASH] = VALUE_OFF
    end
    if (bit.band(byte25, 0x04) == 0x04) then
        streams[KEY_LOCK] = VALUE_ON
    else
        streams[KEY_LOCK] = VALUE_OFF
    end
    streams[KEY_HEAT_TEMPERATURE] = heatTemp
    streams[KEY_COOL_TEMPERATURE] = coolTemp
    streams[KEY_FILTER_1] = filter1
    streams[KEY_FILTER_2] = filter2
    streams[KEY_FILTER_3] = filter3
    streams[KEY_FILTER_4] = filter4
    streams[KEY_FILTER_5] = filter5
    streams[KEY_LIFE_1] = life1
    streams[KEY_LIFE_2] = life2
    streams[KEY_LIFE_3] = life3
    streams[KEY_LIFE_4] = life4
    streams[KEY_LIFE_5] = life5
    streams[KEY_IN_TSD] = inTSD
    streams[KEY_OUT_TSD] = outTSD
    streams[KEY_WATER_LITRE] = waterLitre
    if (bit.band(byte14, 0x20) == 0x20) then
        streams[KEY_LACK_WATER] = VALUE_ON
    else
        streams[KEY_LACK_WATER] = VALUE_OFF
    end
    if (bit.band(byte14, 0x40) == 0x40) then
        streams[KEY_DRAINAGE] = VALUE_ON
    else
        streams[KEY_DRAINAGE] = VALUE_OFF
    end
    if (bit.band(byte15, 0x20) == 0x20) then
        streams[KEY_UV_STERILIZE] = VALUE_ON
    else
        streams[KEY_UV_STERILIZE] = VALUE_OFF
    end
    streams[KEY_ERROR_CODE] = errorCode
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (control) then
        byte12 = 0
        byte22 = 0
        if (status) then updateGlobalPropertyValueByJson(status) end
        if (control) then updateGlobalPropertyValueByJson(control) end
        if control[KEY_POWER] ~= nil then
            local bodyLength = 2
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
            if control[KEY_POWER] == VALUE_ON then
                bodyBytes[0] = 0x01
            elseif control[KEY_POWER] == VALUE_OFF then
                bodyBytes[0] = 0x02
            end
            bodyBytes[1] = 0x01
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        else
            local bodyLength = 16
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0x04
            bodyBytes[1] = 0x01
            bodyBytes[2] = byte12
            bodyBytes[12] = byte22
            bodyBytes[6] = heatTemp
            bodyBytes[7] = coolTemp
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        end
    elseif (query) then
        local bodyLength = 2
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0x01
        bodyBytes[1] = 0x01
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
    end
    local infoM = {}
    local length = #msgBytes + 1
    for i = 1, length do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decodeJsonToTable(jsonStr)
    local deviceinfo = json['deviceinfo']
    local deviceSubType = deviceinfo['deviceSubType']
    if (deviceSubType == 1) then end
    local binData = json['msg']['data']
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10]
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable['status'] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end

function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do msgBytes[i - 1] = byteData[i] end
    local bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    return bodyBytes
end

function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if bodyLength == 0 then return nil end
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    msgBytes[msgLength - 1] = makeSum(msgBytes, 1, msgLength - 2)
    return msgBytes
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

function decodeJsonToTable(cmd)
    local tb
    if JSON == nil then JSON = require 'cjson' end
    tb = JSON.decode(cmd)
    return tb
end

function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then JSON = require 'cjson' end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
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

function table2string(cmd)
    local ret = ''
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
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
