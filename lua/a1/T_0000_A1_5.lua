local bit                    = require "bit"
local JSON                   = require "cjson"
local KEY_VERSION            = "version"
local KEY_POWER              = "power"
local KEY_WIND_SPEED         = "wind_speed"
local KEY_MODE               = "mode"
local KEY_ANION              = "anion"
local KEY_HUMIDITY           = "humidity"
local KEY_TANK_STATUS        = "tank_status"
local KEY_CURRENT_HUMIDITY   = "cur_humidity"
local VALUE_VERSION          = 4
local VALUE_POWER_ON         = "on"
local VALUE_POWER_OFF        = "off"
local VALUE_MODE_INVALID     = "invalid"
local VALUE_MODE_SET         = "set"
local VALUE_MODE_CONTINUITY  = "continuity"
local VALUE_MODE_AUTO        = "auto"
local VALUE_MODE_DRY_CLOTHES = "dry_clothes"
local VALUE_MODE_DRY_SHOES   = "dry_shoes"
local BYTE_DEVICE_TYPE       = 0xA1
local BYTE_CONTROL_REQUEST   = 0x02
local BYTE_QUERY_REQUEST     = 0x03
local BYTE_PROTOCOL_HEAD     = 0xAA
local BYTE_PROTOCOL_LENGTH   = 0x0A
local BYTE_POWER_ON          = 0x01
local BYTE_POWER_OFF         = 0x00
local BYTE_MODE_INVALID      = 0x00
local BYTE_MODE_SET          = 0x01
local BYTE_MODE_CONTINUITY   = 0x02
local BYTE_MODE_AUTO         = 0x03
local BYTE_MODE_DRY_CLOTH    = 0x04
local BYTE_MODE_DRY_SHOES    = 0x05
local BYTE_ANION_ON          = 0x40
local BYTE_ANION_OFF         = 0x00
local BYTE_BUZZER_ON         = 0x40
local BYTE_BUZZER_OFF        = 0x00
local powerValue
local modeValue
local windSpeedValue
local anionValue
local humidityValue
local curHumidityValue
local tankStatusValue
local function checkBoundary(data, min, max)
    if (not data) then data = 0 end
    data = tonumber(data)
    if ((data >= min) and (data <= max)) then return data else if (data < min) then return min else return max end end
end
local function jsonToModel(stateJson, controlJson)
    local oldState = stateJson
    local controlCmd = controlJson
    local temValue = oldState[KEY_POWER]
    if (controlCmd[KEY_POWER] ~= nil) then temValue = controlCmd[KEY_POWER] end
    if (temValue == VALUE_POWER_ON) then powerValue = BYTE_POWER_ON else powerValue = BYTE_POWER_OFF end
    temValue = oldState[KEY_ANION]
    if (controlCmd[KEY_ANION] ~= nil) then temValue = controlCmd[KEY_ANION] end
    if (temValue == VALUE_POWER_ON) then anionValue = BYTE_ANION_ON else anionValue = BYTE_ANION_OFF end
    temValue = oldState[KEY_WIND_SPEED]
    if (controlCmd[KEY_WIND_SPEED] ~= nil) then temValue = controlCmd[KEY_WIND_SPEED] end
    windSpeedValue = checkBoundary(temValue, 1, 102)
    temValue = oldState[KEY_HUMIDITY]
    if (controlCmd[KEY_HUMIDITY] ~= nil) then temValue = controlCmd[KEY_HUMIDITY] end
    humidityValue = checkBoundary(temValue, 0, 99)
    temValue = oldState[KEY_MODE]
    if (controlCmd[KEY_MODE] ~= nil) then temValue = controlCmd[KEY_MODE] end
    if (temValue == VALUE_MODE_SET) then modeValue = BYTE_MODE_SET elseif (temValue == VALUE_MODE_CONTINUITY) then modeValue =
        BYTE_MODE_CONTINUITY elseif (temValue == VALUE_MODE_AUTO) then modeValue = BYTE_MODE_AUTO elseif (temValue == VALUE_MODE_DRY_CLOTHES) then modeValue =
        BYTE_MODE_DRY_CLOTH elseif (temValue == VALUE_MODE_DRY_SHOES) then modeValue = BYTE_MODE_DRY_SHOES end
end
local function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = binData
    powerValue = bit.band(messageBytes[1], 0x01)
    modeValue = bit.band(messageBytes[2], 0x0F)
    anionValue = bit.band(messageBytes[9], 0x40)
    windSpeedValue = messageBytes[3]
    humidityValue = messageBytes[7]
    if (humidityValue < 35) then humidityValue = 35 end
    curHumidityValue = messageBytes[16]
    tankStatusValue = messageBytes[10]
end
local function print_lua_table(lua_table, indent)
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
            if type(v) == "string" then szValue = string.format("%q", v) else szValue = tostring(v) end
            print(formatting .. szValue .. ",")
        end
    end
end
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end
local function string2table(hexstr)
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
local function string2hexstring(str)
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end
local function encode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.encode(cmd)
    return tb
end
local function decode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    resVal = 255 - resVal + 1
    return resVal
end
local crc8_854_table = { 0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65, 157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220, 35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98, 190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255, 70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7, 219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154, 101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36, 248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185, 140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205, 17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80, 175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238, 50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115, 202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139, 87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22, 233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168, 116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53 }
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1] end
    return crc
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
    if ((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04)) then return nil end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then return nil end
    for i = 0, bodyLength do bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH] end
    local crcRes = crc8_854(bodyBytes, 0, bodyLength - 1)
    if (crcRes ~= bodyBytes[bodyLength]) then return nil end
    binToModel(bodyBytes)
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (powerValue == BYTE_POWER_ON) then streams[KEY_POWER] = VALUE_POWER_ON elseif (powerValue == BYTE_POWER_OFF) then streams[KEY_POWER] =
        VALUE_POWER_OFF end
    if (anionValue == BYTE_ANION_ON) then streams[KEY_ANION] = VALUE_POWER_ON elseif (anionValue == BYTE_ANION_OFF) then streams[KEY_ANION] =
        VALUE_POWER_OFF end
    if (modeValue == BYTE_MODE_SET) then streams[KEY_MODE] = VALUE_MODE_SET elseif (modeValue == BYTE_MODE_CONTINUITY) then streams[KEY_MODE] =
        VALUE_MODE_CONTINUITY elseif (modeValue == BYTE_MODE_AUTO) then streams[KEY_MODE] = VALUE_MODE_AUTO elseif (modeValue == BYTE_MODE_DRY_CLOTH) then streams[KEY_MODE] =
        VALUE_MODE_DRY_CLOTHES elseif (modeValue == BYTE_MODE_DRY_SHOES) then streams[KEY_MODE] = VALUE_MODE_DRY_SHOES end
    streams[KEY_WIND_SPEED] = windSpeedValue
    streams[KEY_HUMIDITY] = humidityValue
    streams[KEY_CURRENT_HUMIDITY] = curHumidityValue
    streams[KEY_TANK_STATUS] = tankStatusValue
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
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
    if (query) then bodyLength = 21 elseif (control) then bodyLength = 22 end
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
        math.randomseed(os.time())
        bodyBytes[20] = math.random(0, 100)
        bodyBytes[bodyLength] = crc8_854(bodyBytes, 0, bodyLength - 1)
        msgBytes[9] = BYTE_QUERY_REQUEST
    elseif (control) then
        if (control and status) then jsonToModel(status, control) end
        bodyBytes[0] = 0x48
        bodyBytes[1] = bit.bor(powerValue, BYTE_BUZZER_ON)
        bodyBytes[2] = modeValue
        bodyBytes[3] = windSpeedValue
        bodyBytes[7] = humidityValue
        bodyBytes[9] = anionValue
        bodyBytes[21] = math.random(0, 100)
        bodyBytes[bodyLength] = crc8_854(bodyBytes, 0, bodyLength - 1)
        msgBytes[9] = BYTE_CONTROL_REQUEST
    end
    for i = 0, bodyLength do msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i] end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local infoM = {}
    for i = 1, msgLength + 1 do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
