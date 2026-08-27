local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_LIGHT = 'light'
local KEY_GEAR = 'gear'
local KEY_MINUTES = 'minutes'
local KEY_ERROR_CODE = 'error_code'
local KEY_INTELLIGENT = 'intelligent'
local VALUE_VERSION = 4
local VALUE_ON = 'on'
local VALUE_OFF = 'off'
local BYTE_DEVICE_TYPE = 0xB6
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local BYTE_LIGHT_ON = 0x80
local BYTE_LIGHT_OFF = 0x00
local BYTE_INTELLIGENT_ON = 0x01
local BYTE_INTELLIGENT_OFF = 0x00
local power
local light
local gear
local minutes
local errorcode
local intelligent
local dataType = 0

function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_POWER] == VALUE_ON then
        power = BYTE_POWER_ON
    elseif luaTable[KEY_POWER] == VALUE_OFF then
        power = BYTE_POWER_OFF
    end
    if luaTable[KEY_LIGHT] == VALUE_ON then
        light = BYTE_LIGHT_ON
    elseif luaTable[KEY_LIGHT] == VALUE_OFF then
        light = BYTE_LIGHT_OFF
    end
    if luaTable[KEY_INTELLIGENT] == VALUE_ON then
        intelligent = BYTE_INTELLIGENT_ON
    elseif luaTable[KEY_INTELLIGENT] == VALUE_OFF then
        intelligent = BYTE_INTELLIGENT_OFF
    end
    if luaTable[KEY_GEAR] ~= nil then
        gear = luaTable[KEY_GEAR]
    end
end

function updateGlobalPropertyValueByByte(messageBytes)
    if #messageBytes >= 8 then
        intelligent = messageBytes[0]
        power = bit.band(messageBytes[3], 0x0F)
        light = bit.band(messageBytes[4], 0x80)
        minutes = bit.lshift(messageBytes[6], 8) + messageBytes[5]
        gear = messageBytes[7]
        errorcode = messageBytes[8]
    end
end

function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (intelligent == BYTE_INTELLIGENT_ON) then
        streams[KEY_INTELLIGENT] = VALUE_ON
    elseif (intelligent == BYTE_INTELLIGENT_OFF) then
        streams[KEY_INTELLIGENT] = VALUE_OFF
    end
    if (power == BYTE_POWER_ON) then
        streams[KEY_POWER] = VALUE_ON
    elseif (power == BYTE_POWER_OFF) then
        streams[KEY_POWER] = VALUE_OFF
    end
    if light == BYTE_LIGHT_ON then
        streams[KEY_LIGHT] = VALUE_ON
    elseif light == BYTE_LIGHT_OFF then
        streams[KEY_LIGHT] = VALUE_OFF
    end
    streams[KEY_ERROR_CODE] = errorcode
    streams[KEY_MINUTES] = minutes
    streams[KEY_GEAR] = gear
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then
        return nil
    end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then
    end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (control) then
        if (status) then
            updateGlobalPropertyValueByJson(status)
        end
        if (control) then
            updateGlobalPropertyValueByJson(control)
        end
        local bodyLength = 8
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do
            bodyBytes[i] = 0
        end
        bodyBytes[0] = intelligent
        bodyBytes[3] = power
        bodyBytes[4] = bit.band(bit.bor(light, 0x0F), 0x8F)
        bodyBytes[7] = gear
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        local bodyLength = 1
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do
            bodyBytes[i] = 0
        end
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
    end
    local infoM = {}
    local length = #msgBytes + 1
    for i = 1, length do
        infoM[i] = msgBytes[i - 1]
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function dataToJson(jsonStr)
    if (not jsonStr) then
        return nil
    end
    local json = decodeJsonToTable(jsonStr)
    local deviceinfo = json['deviceinfo']
    local deviceSubType = deviceinfo['deviceSubType']
    if (deviceSubType == 1) then
    end
    local binData = json['msg']['data']
    local status = json['status']
    if (status) then
        updateGlobalPropertyValueByJson(status)
    end
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
    for i = 1, msgLength do
        msgBytes[i - 1] = byteData[i]
    end
    local bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    return bodyBytes
end

function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if bodyLength == 0 then
        return nil
    end
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do
        msgBytes[i] = 0
    end
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

function decodeJsonToTable(cmd)
    local tb
    if JSON == nil then
        JSON = require 'cjson'
    end
    tb = JSON.decode(cmd)
    return tb
end

function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then
        JSON = require 'cjson'
    end
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
    for i = 1, #str do
        ret = ret .. string.format('%02x', str:byte(i))
    end
    return ret
end

function table2string(cmd)
    local ret = ''
    local i
    for i = 1, #cmd do
        ret = ret .. string.char(cmd[i])
    end
    return ret
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
