local JSON = require "cjson"
local KEY_VERSION = "version"
local KEY_POWER = "power"
local KEY_FANSPEED = "wind_speed"
local KEY_SET_HUMIDITY = "humidity"
local KEY_TANK_STATUS = "tank_status"
local KEY_CUR_HUMIDITY = "cur_humidity"
local KEY_ERROR_CODE = "error_code"

local VALUE_VERSION = 6
local VALUE_ON = "on"
local VALUE_OFF = "off"
local VALUE_FANSPEED_HIGH = "high"
local VALUE_FANSPEED_MID = "middle"
local VALUE_FANSPEED_LOW = "low"
local VALUE_FANSPEED_AUTO = "auto"

local BYTE_DEVICE_TYPE = 0xFD
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local BYTE_FANSPEED_HIGH = 0x50
local BYTE_FANSPEED_MID = 0x3C
local BYTE_FANSPEED_LOW = 0x28
local BYTE_FANSPEED_AUTO = 0x66
local BYTE_BUZZER_ON = 0x40
local BYTE_BUZZER_OFF = 0x00

local powerValue = 0
local setHumidityValue = 0
local fanspeedValue = 0
local currentHumidityValue = 0
local tankStatusValue = 0
local errorCode = 0

function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams[KEY_POWER] == VALUE_ON) then
        powerValue = BYTE_POWER_ON
    elseif (streams[KEY_POWER] == VALUE_OFF) then
        powerValue = BYTE_POWER_OFF
    end
    if (streams[KEY_FANSPEED] == VALUE_FANSPEED_HIGH) then
        fanspeedValue = BYTE_FANSPEED_HIGH
    elseif (streams[KEY_FANSPEED] == VALUE_FANSPEED_MID) then
        fanspeedValue = BYTE_FANSPEED_MID
    elseif (streams[KEY_FANSPEED] == VALUE_FANSPEED_LOW) then
        fanspeedValue = BYTE_FANSPEED_LOW
    elseif (streams[KEY_FANSPEED] == VALUE_FANSPEED_AUTO) then
        fanspeedValue = BYTE_FANSPEED_AUTO
    end
    if (streams[KEY_SET_HUMIDITY] ~= nil) then
        setHumidityValue = checkBoundary(streams[KEY_SET_HUMIDITY], 1, 100)
    end
end

function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = binData
    powerValue = bit.band(messageBytes[1], 0x01)
    fanspeedValue = messageBytes[3]
    setHumidityValue = messageBytes[7]
    currentHumidityValue = messageBytes[16]
    tankStatusValue = messageBytes[10]
    errorCode = messageBytes[21]
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    local bodyLength = 0
    if (query) then
        bodyLength = 21
    elseif (control) then
        bodyLength = 23
    end
    local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    local bodyBytes = {}
    for i = 0, bodyLength do bodyBytes[i] = 0 end
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    if (query) then
        bodyBytes[0] = 0x41
        bodyBytes[1] = 0x81
        bodyBytes[3] = 0xFF
        bodyBytes[4] = 0x03
        bodyBytes[7] = 0x02
        math.randomseed(os.time())
        bodyBytes[20] = math.random(0, 100)
        bodyBytes[bodyLength] = crc8_854(bodyBytes, 0, bodyLength - 1)
        msgBytes[9] = BYTE_QUERY_REQUEST
    elseif (control) then
        if (status) then jsonToModel(status) end
        if (control) then jsonToModel(control) end
        bodyBytes[0] = 0x48
        if (powerValue ~= nil) then
            bodyBytes[1] = bit.bor(powerValue, BYTE_BUZZER_ON)
        end
        if (fanspeedValue ~= nil) then bodyBytes[3] = fanspeedValue end
        if (setHumidityValue ~= nil) then bodyBytes[7] = setHumidityValue end
        bodyBytes[22] = math.random(0, 100)
        bodyBytes[bodyLength] = crc8_854(bodyBytes, 0, bodyLength - 1)
        msgBytes[9] = BYTE_CONTROL_REQUEST
    end
    for i = 0, bodyLength do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
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
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    local dataType = info[10]
    if ((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04)) then
        return nil
    end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    binToModel(bodyBytes)
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (powerValue == BYTE_POWER_ON) then
        streams[KEY_POWER] = VALUE_ON
    elseif (powerValue == BYTE_POWER_OFF) then
        streams[KEY_POWER] = VALUE_OFF
    end
    if (fanspeedValue == BYTE_FANSPEED_HIGH) then
        streams[KEY_FANSPEED] = VALUE_FANSPEED_HIGH
    elseif (fanspeedValue == BYTE_FANSPEED_MID) then
        streams[KEY_FANSPEED] = VALUE_FANSPEED_MID
    elseif (fanspeedValue == BYTE_FANSPEED_LOW) then
        streams[KEY_FANSPEED] = VALUE_FANSPEED_LOW
    elseif (fanspeedValue >= BYTE_FANSPEED_AUTO) then
        streams[KEY_FANSPEED] = VALUE_FANSPEED_AUTO
    end
    streams[KEY_SET_HUMIDITY] = setHumidityValue
    streams[KEY_CUR_HUMIDITY] = currentHumidityValue
    streams[KEY_TANK_STATUS] = tankStatusValue
    streams[KEY_ERROR_CODE] = errorCode
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
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
    local ret = ""
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
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end

function encode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.encode(cmd)
    return tb
end

function decode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
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
