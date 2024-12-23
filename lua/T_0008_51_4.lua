local JSON = require "cjson"
local KEY_FUNCTION_TYPE = "function_type"
local KEY_VERSION = "version"
local KEY_TIME_YEAR = "time_year"
local KEY_TIME_MONTH = "time_month"
local KEY_TIME_DAY = "time_day"
local KEY_TIME_HOUR = "time_hour"
local KEY_TIME_MIN = "time_min"
local KEY_TEMPERATURE = "temperature"
local KEY_LIGHT = "light"
local KEY_BATTERY_STATUS = "battery_status"
local KEY_SHOOT = "shoot"
local KEY_MODE_PERIODICAL = "mode_periodical"
local KEY_MODE_REQUEST = "mode_request"
local KEY_MODE_AUTO = "mode_auto"
local KEY_MODE_DIRECT = "mode_direct"
local KEY_TIME_ONE_HOUR = "time_one_hour"
local KEY_TIME_ONE_MIN = "time_one_min"
local KEY_TIME_TWO_HOUR = "time_two_hour"
local KEY_TIME_TWO_MIN = "time_two_min"
local KEY_ERROR_CODE = "error_code"
local BYTE_PROTOCOL_LENGTH = 0x10
local dataType = 0x00
local version = "4"
local functionType = 0x00
local timeYear = 0x00
local timeMonth = 0x00
local timeDay = 0x00
local timeHour = 0x00
local timeMin = 0x00
local temperature = 0x00
local light = 0x00
local batteryStatus = 0xFF
local shoot = 0x00
local mode = 0x00
local timeOneHour = 0x00
local timeOneMin = 0x00
local timeTwoHour = 0x00
local timeTwoMin = 0x00
local errorCode = 0x00
function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_FUNCTION_TYPE] == "base" then
        functionType = 0x00
    elseif luaTable[KEY_FUNCTION_TYPE] == "photo" then
        functionType = 0x01
    elseif luaTable[KEY_FUNCTION_TYPE] == "photo_mode" then
        functionType = 0x02
    end
    if luaTable[KEY_TIME_YEAR] ~= nil then
        timeYear = string2Int(luaTable[KEY_TIME_YEAR])
    end
    if luaTable[KEY_TIME_MONTH] ~= nil then
        timeMonth = string2Int(luaTable[KEY_TIME_MONTH])
    end
    if luaTable[KEY_TIME_DAY] ~= nil then
        timeDay = string2Int(luaTable[KEY_TIME_DAY])
    end
    if luaTable[KEY_TIME_HOUR] ~= nil then
        timeHour = string2Int(luaTable[KEY_TIME_HOUR])
    end
    if luaTable[KEY_TIME_MIN] ~= nil then
        timeMin = string2Int(luaTable[KEY_TIME_MIN])
    end
    if luaTable[KEY_TEMPERATURE] ~= nil then
        temperature = string2Int(luaTable[KEY_TEMPERATURE])
    else
        temperature = 0xffff
    end
    if luaTable[KEY_LIGHT] ~= nil then
        light = string2Int(luaTable[KEY_LIGHT])
    else
        light = 0xffff
    end
    if luaTable[KEY_SHOOT] == "on" then
        shoot = bit.band(shoot, 0x01)
    else
        shoot = bit.band(shoot, 0xFE)
    end
    if luaTable[KEY_MODE_PERIODICAL] == "on" then
        mode = bit.band(mode, 0x01)
    else
        mode = bit.band(mode, 0xFE)
    end
    if luaTable[KEY_MODE_REQUEST] == "on" then
        mode = bit.band(mode, 0x02)
    else
        mode = bit.band(mode, 0xFD)
    end
    if luaTable[KEY_MODE_AUTO] == "on" then
        mode = bit.band(mode, 0x04)
    else
        mode = bit.band(mode, 0xFB)
    end
    if luaTable[KEY_MODE_AUTO] == "on" then
        mode = bit.band(mode, 0x08)
    else
        mode = bit.band(mode, 0xF7)
    end
    if luaTable[KEY_TIME_ONE_HOUR] ~= nil then
        timeOneHour = string2Int(luaTable[KEY_TIME_ONE_HOUR])
    else
        timeOneHour = 0xff
    end
    if luaTable[KEY_TIME_ONE_MIN] ~= nil then
        timeOneMin = string2Int(luaTable[KEY_TIME_ONE_MIN])
    else
        timeOneMin = 0xff
    end
    if luaTable[KEY_TIME_TWO_HOUR] ~= nil then
        timeTwoHour = string2Int(luaTable[KEY_TIME_TWO_HOUR])
    else
        timeTwoHour = 0xff
    end
    if luaTable[KEY_TIME_TWO_MIN] ~= nil then
        timeTwoMin = string2Int(luaTable[KEY_TIME_TWO_MIN])
    else
        timeTwoMin = 0xff
    end
end
function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == 0x02) then
        if messageBytes[0] == 0x00 then
            functionType = 0x00
            timeMin = messageBytes[1]
            timeHour = messageBytes[2]
            timeDay = messageBytes[3]
            timeMonth = messageBytes[4]
            timeYear = bit.lshift(messageBytes[6], 8) + messageBytes[5]
            temperature = bit.lshift(messageBytes[8], 8) + messageBytes[7]
            light = bit.lshift(messageBytes[10], 8) + messageBytes[9]
            batteryStatus = messageBytes[11]
        end
        if messageBytes[0] == 0x01 then functionType = 0x01 end
        if messageBytes[0] == 0x02 then
            functionType = 0x02
            shoot = bit.band(messageBytes[1], 0x01)
            mode = messageBytes[2]
            timeOneHour = messageBytes[3]
            timeOneMin = messageBytes[4]
            timeTwoHour = messageBytes[5]
            timeTwoMin = messageBytes[6]
        end
    end
    if (dataType == 0x03) then
        if messageBytes[0] == 0x00 then
            functionType = 0x00
            timeMin = messageBytes[1]
            timeHour = messageBytes[2]
            timeDay = messageBytes[3]
            timeMonth = messageBytes[4]
            timeYear = bit.lshift(messageBytes[6], 8) + messageBytes[5]
            temperature = bit.lshift(messageBytes[8], 8) + messageBytes[7]
            light = bit.lshift(messageBytes[10], 8) + messageBytes[9]
            batteryStatus = messageBytes[11]
        end
        if messageBytes[0] == 0x01 then functionType = 0x01 end
        if messageBytes[0] == 0x02 then
            functionType = 0x02
            shoot = bit.band(messageBytes[1], 0x01)
            mode = messageBytes[2]
            timeOneHour = messageBytes[3]
            timeOneMin = messageBytes[4]
            timeTwoHour = messageBytes[5]
            timeTwoMin = messageBytes[6]
        end
    end
    if (dataType == 0x04) then
        if messageBytes[0] == 0x00 then
            functionType = 0x00
            timeMin = messageBytes[1]
            timeHour = messageBytes[2]
            timeDay = messageBytes[3]
            timeMonth = messageBytes[4]
            timeYear = bit.lshift(messageBytes[6], 8) + messageBytes[5]
            temperature = bit.lshift(messageBytes[8], 8) + messageBytes[7]
            light = bit.lshift(messageBytes[10], 8) + messageBytes[9]
            batteryStatus = messageBytes[11]
        end
        if messageBytes[0] == 0x01 then functionType = 0x01 end
        if messageBytes[0] == 0x02 then
            functionType = 0x02
            shoot = bit.band(messageBytes[1], 0x01)
            mode = messageBytes[2]
        end
        if messageBytes[0] == 0xFE then
            functionType = 0xFE
            errorCode = bit.lshift(messageBytes[2], 8) + messageBytes[1]
        end
    end
    if (dataType == 0x06) then
        if messageBytes[0] == 0xFE then
            functionType = 0xFE
            errorCode = bit.lshift(messageBytes[2], 8) + messageBytes[1]
        end
    end
end
function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = version
    if functionType == 0x00 then
        streams[KEY_FUNCTION_TYPE] = "base"
        streams[KEY_TIME_MIN] = int2String(timeMin)
        streams[KEY_TIME_HOUR] = int2String(timeHour)
        streams[KEY_TIME_DAY] = int2String(timeDay)
        streams[KEY_TIME_MONTH] = int2String(timeMonth)
        streams[KEY_TIME_YEAR] = int2String(timeYear)
        streams[KEY_TEMPERATURE] = int2String(temperature)
        streams[KEY_BATTERY_STATUS] = int2String(temperature)
        if (batteryStatus == 0x01) then
            streams[KEY_BATTERY_STATUS] = "normal"
        elseif (batteryStatus == 0x02) then
            streams[KEY_BATTERY_STATUS] = "low"
        elseif (batteryStatus == 0x04) then
            streams[KEY_BATTERY_STATUS] = "replace"
        elseif (batteryStatus == 0x08) then
            streams[KEY_BATTERY_STATUS] = "high"
        elseif (batteryStatus == 0x10) then
            streams[KEY_BATTERY_STATUS] = "high_exception"
        elseif (batteryStatus == 0x20) then
            streams[KEY_BATTERY_STATUS] = "low_exception"
        end
    elseif functionType == 0x01 then
        streams[KEY_FUNCTION_TYPE] = "photo"
    elseif functionType == 0x02 then
        streams[KEY_FUNCTION_TYPE] = "photo_mode"
        if (shoot == 0x01) then
            streams[KEY_SHOOT] = "on"
        else
            streams[KEY_SHOOT] = "off"
        end
        if (bit.band(mode, 0x01) == 0x01) then
            streams[KEY_MODE_PERIODICAL] = "on"
        else
            streams[KEY_MODE_PERIODICAL] = "off"
        end
        if (bit.band(mode, 0x02) == 0x02) then
            streams[KEY_MODE_REQUEST] = "on"
        else
            streams[KEY_MODE_REQUEST] = "off"
        end
        if (bit.band(mode, 0x04) == 0x04) then
            streams[KEY_MODE_AUTO] = "on"
        else
            streams[KEY_MODE_AUTO] = "off"
        end
        if (bit.band(mode, 0x08) == 0x08) then
            streams[KEY_MODE_DIRECT] = "on"
        else
            streams[KEY_MODE_DIRECT] = "off"
        end
        streams[KEY_TIME_ONE_HOUR] = int2String(timeOneHour)
        streams[KEY_TIME_ONE_MIN] = int2String(timeOneMin)
        streams[KEY_TIME_TWO_HOUR] = int2String(timeTwoHour)
        streams[KEY_TIME_TWO_MIN] = int2String(timeTwoMin)
    elseif functionType == 0xFE then
        streams[KEY_FUNCTION_TYPE] = "exception"
        streams[KEY_ERROR_CODE] = int2String(errorCode)
    end
    return streams
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        if (status) then end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyBytes = {}
        if functionType == 0x00 then
            local bodyLength = 12
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
            bodyBytes[0] = 0x00
            bodyBytes[1] = timeMin
            bodyBytes[2] = timeHour
            bodyBytes[3] = timeDay
            bodyBytes[4] = timeMonth
            bodyBytes[5] = bit.band(timeYear, 0xFF)
            bodyBytes[6] = bit.band(bit.rshift(timeYear, 8), 0xFF)
        end
        if functionType == 0x01 then
            local bodyLength = 18
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0x00 end
            bodyBytes[0] = 0x01
        end
        if functionType == 0x02 then
            bodyBytes[0] = 0x02
            bodyBytes[1] = shoot
            bodyBytes[2] = mode
            bodyBytes[3] = timeOneHour
            bodyBytes[4] = timeOneMin
            bodyBytes[5] = timeTwoHour
            bodyBytes[6] = timeTwoMin
        end
        msgBytes = assembleUart(bodyBytes, 0x0002)
    elseif (query) then
        local bodyBytes = {}
        bodyBytes[0] = functionType
        msgBytes = assembleUart(bodyBytes, 0x0003)
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
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local status = json["status"]
    if (status) then updateGlobalPropertyValueByJson(status) end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[15];
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end
function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do msgBytes[i - 1] = byteData[i] end
    local bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 2
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    return bodyBytes
end
function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 2)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = 0x55
    msgBytes[1] = 0xAA
    msgBytes[2] = 0xCC
    msgBytes[3] = 0x33
    local msgLen = msgLength - 4
    msgBytes[4] = bit.band(msgLen, 0xff)
    msgBytes[5] = bit.band(bit.rshift(msgLen, 8), 0xff)
    msgBytes[6] = 0x01
    msgBytes[7] = 0x51
    msgBytes[14] = bit.band(type, 0xff)
    msgBytes[15] = bit.band(bit.rshift(type, 8), 0xff)
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    local crc16 = crc16_ccitt(msgBytes, 0, msgLength - 3)
    msgBytes[msgLength - 2] = bit.band(crc16, 0xff)
    msgBytes[msgLength - 1] = bit.band(bit.rshift(crc16, 8), 0xff)
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
function crc16_ccitt(tmpbuf, start_pos, end_pos)
    local crc = 0;
    for si = start_pos, end_pos do
        local i = 0
        crc = bit.bxor(crc, bit.lshift(tmpbuf[si], 8))
        for i = 0, 7 do
            if bit.band(crc, 0x8000) == 0x8000 then
                crc = bit.bxor(bit.lshift(crc, 1), 0x1021);
            else
                crc = bit.lshift(crc, 1)
            end
        end
    end
    return crc;
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
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end
function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then JSON = require "cjson" end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
end
function string2Int(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end
function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = "0" end
    return data
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
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end
function table2string(cmd)
    local ret = ""
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
