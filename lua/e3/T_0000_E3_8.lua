local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_COLD_WATER = 'cold_water'
local KEY_BATHTUB = 'bathtub'
local KEY_BATHTUB_WATER_LEVEL = 'bathtub_water_level'
local KEY_ULTRAVIOLET = 'ultraviolet'
local KEY_SAFE = 'safe'
local KEY_MODE = 'mode'
local KEY_CAPACITY = 'capacity'
local KEY_TEMPERATURE = 'temperature'
local KEY_CHANGE_LITRE = 'change_litre'
local KEY_ERROR_CODE = 'error_code'
local KEY_CHANGE_LITRE_SWITCH = 'change_litre_switch'
local KEY_COLD_WATER_DOT = 'cold_water_dot'

local VALUE_VERSION = 8
local VALUE_ON = 'on'
local VALUE_OFF = 'off'
local VALUE_MODE_SHOWER = 'shower'
local VALUE_MODE_KITCHEN = 'kitchen'
local VALUE_MODE_THALPOSIS = 'thalposis'
local VALUE_MODE_INTELLIGENCE = 'intelligence'
local VALUE_MODE_ECO = 'eco'
local VALUE_MODE_UNFREEZE = 'unfreeze'
local VALUE_MODE_WASH_BOWL = 'wash_bowl'
local VALUE_MODE_HIGH_TEMPERATURE = 'high_temperature'
local VALUE_MODE_BABY = 'baby'
local VALUE_MODE_ADULT = 'adult'
local VALUE_MODE_OLD = 'old'

local BYTE_DEVICE_TYPE = 0xE3
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local BYTE_COLD_WATER_ON = 0x01
local BYTE_COLD_WATER_OFF = 0xFE
local BYTE_BATHTUB_ON = 0x08
local BYTE_BATHTUB_OFF = 0xF7
local BYTE_ULTRAVIOLET_ON = 0x40
local BYTE_ULTRAVIOLET_OFF = 0xBF
local BYTE_SAFE_ON = 0x08
local BYTE_SAFE_OFF = 0xF7
local BYTE_COLD_WATER_DOT_ON = 0x10
local BYTE_COLD_WATER_DOT_OFF = 0xEF
local BYTE_CHANGE_LITRE_SWITCH_ON = 0x20
local BYTE_CHANGE_LITRE_SWITCH_OFF = 0xDF
local BYTE_MODE_SHOWER = 0x02
local BYTE_MODE_KITCHEN = 0x04
local BYTE_MODE_THALPOSIS = 0x10
local BYTE_MODE_INTELLIGENCE = 0x20
local BYTE_MODE_ECO = 0x02
local BYTE_MODE_UNFREEZE = 0x04
local BYTE_MODE_WASH_BOWL = 0x08
local BYTE_MODE_HIGH_TEMPERATURE = 0x10
local BYTE_MODE_BABY = 0x20
local BYTE_MODE_ADULT = 0x40
local BYTE_MODE_OLD = 0x80

local deviceSubType = 0
local power
local coldWater = 0
local bathtub
local bathtubWaterLevel = 0
local ultraviolet
local safe
local mode12
local mode18
local capacity = 0
local temperature = 0
local changeLitre
local byte13 = 0
local byte14 = 0
local byte18 = 0
local coldWaterDot = 0
local changeLitreSwitch = 0
local dataType = 0

function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_POWER] == VALUE_ON then
        power = BYTE_POWER_ON
    elseif luaTable[KEY_POWER] == VALUE_OFF then
        power = BYTE_POWER_OFF
    end
    if luaTable[KEY_COLD_WATER] == VALUE_ON then
        coldWater = BYTE_COLD_WATER_ON
    elseif luaTable[KEY_COLD_WATER] == VALUE_OFF then
        coldWater = BYTE_COLD_WATER_OFF
    end
    if luaTable[KEY_BATHTUB] == VALUE_ON then
        bathtub = BYTE_BATHTUB_ON
    elseif luaTable[KEY_BATHTUB] == VALUE_OFF then
        bathtub = BYTE_BATHTUB_OFF
    end
    if luaTable[KEY_BATHTUB_WATER_LEVEL] ~= nil then
        bathtubWaterLevel = luaTable[KEY_BATHTUB_WATER_LEVEL]
    end
    if luaTable[KEY_ULTRAVIOLET] == VALUE_ON then
        ultraviolet = BYTE_ULTRAVIOLET_ON
    elseif luaTable[KEY_ULTRAVIOLET] == VALUE_OFF then
        ultraviolet = BYTE_ULTRAVIOLET_OFF
    end
    if luaTable[KEY_SAFE] == VALUE_ON then
        safe = BYTE_SAFE_ON
    elseif luaTable[KEY_SAFE] == VALUE_OFF then
        safe = BYTE_SAFE_OFF
    end
    if luaTable[KEY_COLD_WATER_DOT] == VALUE_ON then
        coldWaterDot = BYTE_COLD_WATER_DOT_ON
    elseif luaTable[KEY_COLD_WATER_DOT] == VALUE_OFF then
        coldWaterDot = BYTE_COLD_WATER_DOT_OFF
    end
    if luaTable[KEY_CHANGE_LITRE_SWITCH] == VALUE_ON then
        changeLitreSwitch = BYTE_CHANGE_LITRE_SWITCH_ON
    elseif luaTable[KEY_CHANGE_LITRE_SWITCH] == VALUE_OFF then
        changeLitreSwitch = BYTE_CHANGE_LITRE_SWITCH_OFF
    end
    if luaTable[KEY_MODE] == VALUE_MODE_SHOWER then
        mode18 = nil
        mode12 = VALUE_MODE_SHOWER
    elseif luaTable[KEY_MODE] == VALUE_MODE_KITCHEN then
        mode18 = nil
        mode12 = VALUE_MODE_KITCHEN
    elseif luaTable[KEY_MODE] == VALUE_MODE_THALPOSIS then
        mode18 = nil
        mode12 = VALUE_MODE_THALPOSIS
    elseif luaTable[KEY_MODE] == VALUE_MODE_INTELLIGENCE then
        mode18 = nil
        mode12 = VALUE_MODE_INTELLIGENCE
    elseif luaTable[KEY_MODE] == VALUE_MODE_ECO then
        mode18 = VALUE_MODE_ECO
        mode12 = nil
    elseif luaTable[KEY_MODE] == VALUE_MODE_UNFREEZE then
        mode18 = VALUE_MODE_UNFREEZE
        mode12 = nil
    elseif luaTable[KEY_MODE] == VALUE_MODE_WASH_BOWL then
        mode18 = VALUE_MODE_WASH_BOWL
        mode12 = nil
    elseif luaTable[KEY_MODE] == VALUE_MODE_HIGH_TEMPERATURE then
        mode18 = VALUE_MODE_HIGH_TEMPERATURE
        mode12 = nil
    elseif luaTable[KEY_MODE] == VALUE_MODE_BABY then
        mode18 = VALUE_MODE_BABY
        mode12 = nil
    elseif luaTable[KEY_MODE] == VALUE_MODE_ADULT then
        mode18 = VALUE_MODE_ADULT
        mode12 = nil
    elseif luaTable[KEY_MODE] == VALUE_MODE_OLD then
        mode18 = VALUE_MODE_OLD
        mode12 = nil
    end
    if luaTable[KEY_CAPACITY] ~= nil then capacity = luaTable[KEY_CAPACITY] end
    if luaTable[KEY_TEMPERATURE] ~= nil then
        temperature = luaTable[KEY_TEMPERATURE]
    end
end

function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if ((dataType == 0x02 and messageBytes[0] == 0x01) or
        (dataType == 0x02 and messageBytes[0] == 0x02) or
        (dataType == 0x02 and messageBytes[0] == 0x04) or
        (dataType == 0x03 and messageBytes[0] == 0x01) or dataType == 0x04) then
        if bit.band(messageBytes[2], 0x01) == 0x01 then
            power = BYTE_POWER_ON
        else
            power = BYTE_POWER_OFF
        end
        if bit.band(messageBytes[2], 0x04) == 0x04 then
            coldWater = BYTE_COLD_WATER_ON
        else
            coldWater = BYTE_COLD_WATER_OFF
        end
        if bit.band(messageBytes[2], 0x40) == 0x40 then
            bathtub = BYTE_BATHTUB_ON
        else
            bathtub = BYTE_BATHTUB_OFF
        end
        bathtubWaterLevel = bit.lshift(messageBytes[9], 8) + messageBytes[10]
        if (bit.band(messageBytes[16], 0x80) == 0x80) then
            ultraviolet = BYTE_ULTRAVIOLET_ON
        else
            ultraviolet = BYTE_ULTRAVIOLET_OFF
        end
        if (bit.band(messageBytes[8], 0x08) == 0x08) then
            safe = BYTE_SAFE_ON
        else
            safe = BYTE_SAFE_OFF
        end
        if (#messageBytes >= 21) then
            if (bit.band(messageBytes[20], 0x01) == 0x01) then
                coldWaterDot = BYTE_COLD_WATER_DOT_ON
            else
                coldWaterDot = BYTE_COLD_WATER_DOT_OFF
            end
            if (bit.band(messageBytes[20], 0x02) == 0x02) then
                changeLitreSwitch = BYTE_CHANGE_LITRE_SWITCH_ON
            else
                changeLitreSwitch = BYTE_CHANGE_LITRE_SWITCH_OFF
            end
        end
        if bit.band(messageBytes[2], 0x08) == 0x08 then
            mode12 = VALUE_MODE_SHOWER
            mode18 = nil
        elseif bit.band(messageBytes[2], 0x10) == 0x10 then
            mode12 = VALUE_MODE_KITCHEN
            mode18 = nil
        elseif bit.band(messageBytes[2], 0x20) == 0x20 then
            mode12 = VALUE_MODE_THALPOSIS
            mode18 = nil
        elseif bit.band(messageBytes[2], 0x80) == 0x80 then
            mode12 = VALUE_MODE_INTELLIGENCE
            mode18 = nil
        end
        if bit.band(messageBytes[16], 0x01) == 0x01 then
            mode18 = VALUE_MODE_ECO
            mode12 = nil
        elseif bit.band(messageBytes[16], 0x02) == 0x02 then
            mode18 = VALUE_MODE_UNFREEZE
            mode12 = nil
        elseif bit.band(messageBytes[16], 0x04) == 0x04 then
            mode18 = VALUE_MODE_WASH_BOWL
            mode12 = nil
        elseif bit.band(messageBytes[16], 0x08) == 0x08 then
            mode18 = VALUE_MODE_HIGH_TEMPERATURE
            mode12 = nil
        elseif bit.band(messageBytes[16], 0x10) == 0x10 then
            mode18 = VALUE_MODE_BABY
            mode12 = nil
        elseif bit.band(messageBytes[16], 0x20) == 0x20 then
            mode18 = VALUE_MODE_ADULT
            mode12 = nil
        elseif bit.band(messageBytes[16], 0x40) == 0x40 then
            mode18 = VALUE_MODE_OLD
            mode12 = nil
        end
        if bit.band(messageBytes[4], 0x04) == 0x04 then
            capacity = 1
        elseif bit.band(messageBytes[4], 0x08) == 0x08 then
            capacity = 2
        elseif bit.band(messageBytes[4], 0x10) == 0x10 then
            capacity = 3
        end
        temperature = messageBytes[6]
        changeLitre = messageBytes[18]
        byte13 = messageBytes[13]
        byte14 = messageBytes[14]
        byte18 = messageBytes[18]
    end
end

function isMoreThan20Byte()
    if deviceSubType == '40' or deviceSubType == '49' then
        return 1
    else
        return 0
    end
end

function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (power == BYTE_POWER_ON) then
        streams[KEY_POWER] = VALUE_ON
    else
        streams[KEY_POWER] = VALUE_OFF
    end
    if (coldWater == BYTE_COLD_WATER_ON) then
        streams[KEY_COLD_WATER] = VALUE_ON
    else
        streams[KEY_COLD_WATER] = VALUE_OFF
    end
    if (bathtub == BYTE_BATHTUB_ON) then
        streams[KEY_BATHTUB] = VALUE_ON
    else
        streams[KEY_BATHTUB] = VALUE_OFF
    end
    if (ultraviolet == BYTE_ULTRAVIOLET_ON) then
        streams[KEY_ULTRAVIOLET] = VALUE_ON
    else
        streams[KEY_ULTRAVIOLET] = VALUE_OFF
    end
    if (safe == BYTE_SAFE_ON) then
        streams[KEY_SAFE] = VALUE_ON
    else
        streams[KEY_SAFE] = VALUE_OFF
    end
    if (coldWaterDot == BYTE_COLD_WATER_DOT_ON) then
        streams[KEY_COLD_WATER_DOT] = VALUE_ON
    else
        streams[KEY_COLD_WATER_DOT] = VALUE_OFF
    end
    if (changeLitreSwitch == BYTE_CHANGE_LITRE_SWITCH_ON) then
        streams[KEY_CHANGE_LITRE_SWITCH] = VALUE_ON
    else
        streams[KEY_CHANGE_LITRE_SWITCH] = VALUE_OFF
    end
    streams[KEY_BATHTUB_WATER_LEVEL] = bathtubWaterLevel
    if mode12 ~= nil then
        streams[KEY_MODE] = mode12
    elseif mode18 ~= nil then
        streams[KEY_MODE] = mode18
    end
    streams[KEY_CAPACITY] = capacity
    streams[KEY_TEMPERATURE] = temperature
    streams[KEY_CHANGE_LITRE] = changeLitre
    if (bit.band(byte13, 0x01) == 0x01) then
        streams[KEY_ERROR_CODE] = 'E0'
    elseif (bit.band(byte13, 0x02) == 0x02) then
        streams[KEY_ERROR_CODE] = 'E1'
    elseif (bit.band(byte13, 0x04) == 0x04) then
        streams[KEY_ERROR_CODE] = 'E2'
    elseif (bit.band(byte13, 0x08) == 0x08) then
        streams[KEY_ERROR_CODE] = 'E3'
    elseif (bit.band(byte13, 0x10) == 0x10) then
        streams[KEY_ERROR_CODE] = 'E4'
    elseif (bit.band(byte13, 0x20) == 0x20) then
        streams[KEY_ERROR_CODE] = 'E5'
    elseif (bit.band(byte13, 0x40) == 0x40) then
        streams[KEY_ERROR_CODE] = 'E6'
    elseif (bit.band(byte13, 0x80) == 0x80) then
        streams[KEY_ERROR_CODE] = 'E8'
    elseif (bit.band(byte14, 0x01) == 0x01) then
        streams[KEY_ERROR_CODE] = 'EA'
    elseif (bit.band(byte14, 0x02) == 0x02) then
        streams[KEY_ERROR_CODE] = 'EE'
    elseif (bit.band(byte18, 0x02) == 0x02) then
        streams[KEY_ERROR_CODE] = 'EF'
    elseif (bit.band(byte18, 0x04) == 0x04) then
        streams[KEY_ERROR_CODE] = 'ED'
    else
        streams[KEY_ERROR_CODE] = 'none'
    end
    if deviceSubType == '32' then streams[KEY_CAPACITY] = 'unknown' end
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    deviceSubType = json['deviceinfo']['deviceSubType']
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (control) then
        if (status) then updateGlobalPropertyValueByJson(status) end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyLength = 20
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0x00 end
        if control[KEY_POWER] ~= nil then
            if power == BYTE_POWER_ON then
                bodyBytes[0] = 0x01
            elseif power == BYTE_POWER_OFF then
                bodyBytes[0] = 0x02
            end
            bodyBytes[1] = 0x01
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        else
            bodyBytes[0] = 0x04
            bodyBytes[1] = 0x01
            local byte2 = 0
            if coldWater == BYTE_COLD_WATER_ON then
                byte2 = bit.bor(byte2, BYTE_COLD_WATER_ON)
            elseif coldWater == BYTE_COLD_WATER_OFF then
                byte2 = bit.band(byte2, BYTE_COLD_WATER_OFF)
            end
            if bathtub == BYTE_BATHTUB_ON then
                byte2 = bit.bor(byte2, BYTE_BATHTUB_ON)
            elseif bathtub == BYTE_BATHTUB_OFF then
                byte2 = bit.band(byte2, BYTE_BATHTUB_OFF)
            end
            if ultraviolet == BYTE_ULTRAVIOLET_ON then
                byte2 = bit.bor(byte2, BYTE_ULTRAVIOLET_ON)
            elseif ultraviolet == BYTE_ULTRAVIOLET_OFF then
                byte2 = bit.band(byte2, BYTE_ULTRAVIOLET_OFF)
            end
            if mode12 == VALUE_MODE_SHOWER then
                byte2 = bit.bor(byte2, BYTE_MODE_SHOWER)
            elseif mode12 == VALUE_MODE_KITCHEN then
                byte2 = bit.bor(byte2, BYTE_MODE_KITCHEN)
            elseif mode12 == VALUE_MODE_THALPOSIS then
                byte2 = bit.bor(byte2, BYTE_MODE_THALPOSIS)
            elseif mode12 == VALUE_MODE_INTELLIGENCE then
                byte2 = bit.bor(byte2, BYTE_MODE_INTELLIGENCE)
            end
            bodyBytes[2] = byte2
            local byte3 = 0
            if capacity == 1 then
                byte3 = bit.bor(byte3, 0x01)
            elseif capacity == 2 then
                byte3 = bit.bor(byte3, 0x02)
            elseif capacity == 3 then
                byte3 = bit.bor(byte3, 0x04)
            end
            if safe == BYTE_SAFE_ON then
                byte3 = bit.bor(byte3, BYTE_SAFE_ON)
            elseif safe == BYTE_SAFE_OFF then
                byte3 = bit.band(byte3, BYTE_SAFE_OFF)
            end
            if changeLitreSwitch == BYTE_CHANGE_LITRE_SWITCH_ON then
                byte3 = bit.bor(byte3, BYTE_CHANGE_LITRE_SWITCH_ON)
            elseif changeLitreSwitch == BYTE_CHANGE_LITRE_SWITCH_OFF then
                byte3 = bit.band(byte3, BYTE_CHANGE_LITRE_SWITCH_OFF)
            end
            if coldWaterDot == BYTE_COLD_WATER_DOT_ON then
                byte3 = bit.bor(byte3, BYTE_COLD_WATER_DOT_ON)
            elseif coldWaterDot == BYTE_COLD_WATER_DOT_OFF then
                byte3 = bit.band(byte3, BYTE_COLD_WATER_DOT_OFF)
            end
            bodyBytes[3] = byte3
            bodyBytes[4] = temperature
            bodyBytes[5] = temperature
            bodyBytes[6] = bit.rshift(bathtubWaterLevel, 8)
            bodyBytes[7] = bit.band(bathtubWaterLevel, 0xFF)
            local byte8 = 0
            if mode18 == VALUE_MODE_ECO then
                byte8 = bit.bor(byte8, BYTE_MODE_ECO)
            elseif mode18 == VALUE_MODE_UNFREEZE then
                byte8 = bit.bor(byte8, BYTE_MODE_UNFREEZE)
            elseif mode18 == VALUE_MODE_WASH_BOWL then
                byte8 = bit.bor(byte8, BYTE_MODE_WASH_BOWL)
            elseif mode18 == VALUE_MODE_HIGH_TEMPERATURE then
                byte8 = bit.bor(byte8, BYTE_MODE_HIGH_TEMPERATURE)
            elseif mode18 == VALUE_MODE_BABY then
                byte8 = bit.bor(byte8, BYTE_MODE_BABY)
            elseif mode18 == VALUE_MODE_ADULT then
                byte8 = bit.bor(byte8, BYTE_MODE_ADULT)
            elseif mode18 == VALUE_MODE_OLD then
                byte8 = bit.bor(byte8, BYTE_MODE_OLD)
            end
            bodyBytes[8] = byte8
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        end
    elseif (query) then
        local bodyLength = 20
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0x00 end
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
    deviceSubType = deviceinfo['deviceSubType']
    local binData = json['msg']['data']
    local status = json['status']
    if (status) then updateGlobalPropertyValueByJson(status) end
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
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[3] = 0xC4
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
