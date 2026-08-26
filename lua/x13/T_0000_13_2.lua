local JSON = require "cjson"
local BYTE_DEVICE_TYPE = 0x13
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A

local VALUE_UNKNOWN = "unknown"
local VALUE_INVALID = "invalid"
local dataType = 0
local cmdType = 0

local KEY_VERSION = "version"
local KEY_POWER = "power"
local KEY_SCENE_LIGHT = "scene_light"
local KEY_COLOR_TEMPERATURE = "color_temperature"
local KEY_BRIGHTNESS = "brightness"
local KEY_DELAY_LIGHT_OFF = "delay_light_off"
local KEY_LIFE_COLOR_TEMPERATURE = "life_color_temperature"
local KEY_LIFE_BRIGHTNESS = "life_brightness"
local KEY_READ_COLOR_TEMPERATURE = "read_color_temperature"
local KEY_READ_BRIGHTNESS = "read_brightness"
local KEY_MILD_COLOR_TEMPERATURE = "mild_color_temperature"
local KEY_MILD_BRIGHTNESS = "mild_brightness"
local KEY_FILM_COLOR_TEMPERATURE = "film_color_temperature"
local KEY_FILM_BRIGHTNESS = "film_brightness"
local KEY_LIGHT_COLOR_TEMPERATURE = "light_color_temperature"
local KEY_LIGHT_BRIGHTNESS = "light_brightness"
local KEY_RESULT = "result"

local powerValue = 0
local sceneLight = 0
local colorTemperature = 0
local brightness = 0
local delayLightOff = 0
local lifeColorTemperature = 0
local lifeBrightness = 0
local readColorTemperature = 0
local readBrightness = 0
local mildColorTemperature = 0
local mildBrightness = 0
local filmColorTemperature = 0
local filmBrightness = 0
local lightColorTemperature = 0
local lightBrightness = 0
local colorRed = 0
local colorGreen = 0
local colorBlue = 0
local result = 0

function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_POWER] == "on" then
        powerValue = 0x01
    elseif luaTable[KEY_POWER] == "off" then
        powerValue = 0x00
    end
    if luaTable[KEY_SCENE_LIGHT] == "life" then
        sceneLight = 0x02
    elseif luaTable[KEY_SCENE_LIGHT] == "read" then
        sceneLight = 0x03
    elseif luaTable[KEY_SCENE_LIGHT] == "mild" then
        sceneLight = 0x04
    elseif luaTable[KEY_SCENE_LIGHT] == "film" then
        sceneLight = 0x05
    elseif luaTable[KEY_SCENE_LIGHT] == "light" then
        sceneLight = 0x06
    end
    if luaTable[KEY_COLOR_TEMPERATURE] ~= nil then
        colorTemperature = string2Int(luaTable[KEY_COLOR_TEMPERATURE])
    end
    if luaTable[KEY_BRIGHTNESS] ~= nil then
        brightness = string2Int(luaTable[KEY_BRIGHTNESS])
    end
    if luaTable[KEY_DELAY_LIGHT_OFF] ~= nil then
        delayLightOff = string2Int(luaTable[KEY_DELAY_LIGHT_OFF])
    end
    if luaTable[KEY_LIFE_COLOR_TEMPERATURE] ~= nil then
        lifeColorTemperature = string2Int(luaTable[KEY_LIFE_COLOR_TEMPERATURE])
    end
    if luaTable[KEY_LIFE_BRIGHTNESS] ~= nil then
        lifeBrightness = string2Int(luaTable[KEY_LIFE_BRIGHTNESS])
    end
    if luaTable[KEY_READ_COLOR_TEMPERATURE] ~= nil then
        readColorTemperature = string2Int(luaTable[KEY_READ_COLOR_TEMPERATURE])
    end
    if luaTable[KEY_READ_BRIGHTNESS] ~= nil then
        readBrightness = string2Int(luaTable[KEY_READ_BRIGHTNESS])
    end
    if luaTable[KEY_MILD_COLOR_TEMPERATURE] ~= nil then
        mildColorTemperature = string2Int(luaTable[KEY_MILD_COLOR_TEMPERATURE])
    end
    if luaTable[KEY_MILD_BRIGHTNESS] ~= nil then
        mildBrightness = string2Int(luaTable[KEY_MILD_BRIGHTNESS])
    end
    if luaTable[KEY_FILM_COLOR_TEMPERATURE] ~= nil then
        filmColorTemperature = string2Int(luaTable[KEY_FILM_COLOR_TEMPERATURE])
    end
    if luaTable[KEY_FILM_BRIGHTNESS] ~= nil then
        filmBrightness = string2Int(luaTable[KEY_FILM_BRIGHTNESS])
    end
    if luaTable[KEY_LIGHT_COLOR_TEMPERATURE] ~= nil then
        lightColorTemperature =
            string2Int(luaTable[KEY_LIGHT_COLOR_TEMPERATURE])
    end
    if luaTable[KEY_LIGHT_BRIGHTNESS] ~= nil then
        lightBrightness = string2Int(luaTable[KEY_LIGHT_BRIGHTNESS])
    end
end

function updateGlobalPropertyValueByByte(messageBytes)
    cmdType = messageBytes[0]
    if cmdType == 0x81 then result = messageBytes[1] end
    if cmdType == 0x82 then result = messageBytes[1] end
    if cmdType == 0x83 then result = messageBytes[1] end
    if cmdType == 0x84 then result = messageBytes[1] end
    if cmdType == 0x85 then result = messageBytes[1] end
    if cmdType == 0xa4 then
        brightness = messageBytes[1]
        colorTemperature = messageBytes[2]
        sceneLight = messageBytes[3]
        delayLightOff = messageBytes[4]
        colorRed = messageBytes[5]
        colorGreen = messageBytes[6]
        colorBlue = messageBytes[7]
        powerValue = messageBytes[8]
        lifeBrightness = messageBytes[9]
        lifeColorTemperature = messageBytes[10]
        readBrightness = messageBytes[11]
        readColorTemperature = messageBytes[12]
        mildBrightness = messageBytes[13]
        mildColorTemperature = messageBytes[14]
        filmBrightness = messageBytes[15]
        filmColorTemperature = messageBytes[16]
        lightBrightness = messageBytes[17]
        lightColorTemperature = messageBytes[18]
    end
    if cmdType == 0x86 then result = messageBytes[1] end
    if cmdType == 0x87 then result = messageBytes[1] end
    if cmdType == 0x88 then result = messageBytes[1] end
    if cmdType == 0x89 then result = messageBytes[1] end
    if cmdType == 0x8a then result = messageBytes[1] end
end

function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = "2"
    if cmdType == 0xa4 then
        streams[KEY_BRIGHTNESS] = int2String(brightness)
        streams[KEY_COLOR_TEMPERATURE] = int2String(colorTemperature)
        if sceneLight == 0x02 then
            streams[KEY_SCENE_LIGHT] = "life"
        elseif sceneLight == 0x03 then
            streams[KEY_SCENE_LIGHT] = "read"
        elseif sceneLight == 0x04 then
            streams[KEY_SCENE_LIGHT] = "mild"
        elseif sceneLight == 0x05 then
            streams[KEY_SCENE_LIGHT] = "film"
        elseif sceneLight == 0x06 then
            streams[KEY_SCENE_LIGHT] = "light"
        elseif sceneLight == 0x01 then
            streams[KEY_SCENE_LIGHT] = "manual"
        end
        streams[KEY_DELAY_LIGHT_OFF] = int2String(delayLightOff)
        streams["color_red"] = int2String(colorRed)
        streams["color_green"] = int2String(colorGreen)
        streams["color_blue"] = int2String(colorBlue)
        if powerValue == 0x01 then
            streams[KEY_POWER] = "on"
        elseif powerValue == 0x00 then
            streams[KEY_POWER] = "off"
        end
        streams[KEY_LIFE_BRIGHTNESS] = int2String(lifeBrightness)
        streams[KEY_LIFE_COLOR_TEMPERATURE] = int2String(lifeColorTemperature)
        streams[KEY_READ_BRIGHTNESS] = int2String(readBrightness)
        streams[KEY_READ_COLOR_TEMPERATURE] = int2String(readColorTemperature)
        streams[KEY_MILD_BRIGHTNESS] = int2String(mildBrightness)
        streams[KEY_MILD_COLOR_TEMPERATURE] = int2String(mildColorTemperature)
        streams[KEY_FILM_BRIGHTNESS] = int2String(filmBrightness)
        streams[KEY_FILM_COLOR_TEMPERATURE] = int2String(filmColorTemperature)
        streams[KEY_LIGHT_BRIGHTNESS] = int2String(lightBrightness)
        streams[KEY_LIGHT_COLOR_TEMPERATURE] = int2String(lightColorTemperature)
        streams[KEY_RESULT] = "1"
    else
        streams[KEY_RESULT] = int2String(result)
    end
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        if (status) then end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyLength = 5
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        if control[KEY_POWER] ~= nil then
            bodyBytes[0] = 0x01
            bodyBytes[1] = powerValue
        elseif control[KEY_SCENE_LIGHT] ~= nil then
            bodyBytes[0] = 0x02
            bodyBytes[1] = sceneLight
        elseif control[KEY_COLOR_TEMPERATURE] ~= nil then
            bodyBytes[0] = 0x03
            bodyBytes[1] = colorTemperature
        elseif control[KEY_BRIGHTNESS] ~= nil then
            bodyBytes[0] = 0x04
            bodyBytes[1] = brightness
        elseif control[KEY_DELAY_LIGHT_OFF] ~= nil then
            bodyBytes[0] = 0x05
            bodyBytes[1] = delayLightOff
        elseif control[KEY_LIFE_COLOR_TEMPERATURE] ~= nil and
            control[KEY_LIFE_BRIGHTNESS] ~= nil then
            bodyBytes[0] = 0x06
            bodyBytes[1] = lifeBrightness
            bodyBytes[2] = lifeColorTemperature
        elseif control[KEY_READ_COLOR_TEMPERATURE] ~= nil and
            control[KEY_READ_BRIGHTNESS] ~= nil then
            bodyBytes[0] = 0x07
            bodyBytes[1] = readBrightness
            bodyBytes[2] = readColorTemperature
        elseif control[KEY_MILD_COLOR_TEMPERATURE] ~= nil and
            control[KEY_MILD_BRIGHTNESS] ~= nil then
            bodyBytes[0] = 0x08
            bodyBytes[1] = mildBrightness
            bodyBytes[2] = mildColorTemperature
        elseif control[KEY_FILM_COLOR_TEMPERATURE] ~= nil and
            control[KEY_FILM_BRIGHTNESS] ~= nil then
            bodyBytes[0] = 0x09
            bodyBytes[1] = filmBrightness
            bodyBytes[2] = filmColorTemperature
        elseif control[KEY_LIGHT_COLOR_TEMPERATURE] ~= nil and
            control[KEY_LIGHT_BRIGHTNESS] ~= nil then
            bodyBytes[0] = 0x0A
            bodyBytes[1] = lightBrightness
            bodyBytes[2] = lightColorTemperature
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        local bodyLength = 5
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0x24
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
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local status = json["status"]
    if (status) then end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10];
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

function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then k = string.format("%q", k) end
        local szSuffix = ""
        if type(v) == "table" then szSuffix = "{" end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix .. "[" .. k .. "]" .. " = " .. szSuffix
        if type(v) == "table" then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix .. "},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting .. szValue .. ",")
        end
    end
end
