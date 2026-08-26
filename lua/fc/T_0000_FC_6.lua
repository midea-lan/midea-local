local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_ANION = 'anion'
local KEY_MODE = 'mode'
local KEY_FAN_SPEED = 'wind_speed'
local KEY_BUZZER = 'buzzer'
local KEY_PM25 = 'pm25'
local KEY_TVOC = 'tvoc'
local KEY_ASH_TVOC = 'ash_tvoc'
local KEY_SMELL_TVOC = 'smell_tvoc'
local KEY_ERROR_CODE = 'error_code'
local KEY_SCHEDULE_CLOSE_SWITCHER = 'power_off_timer'
local KEY_SCHEDULE_CLOSE_TIME = 'time'

local VALUE_VERSION = 6
local VALUE_POWER_ON = 'on'
local VALUE_POWER_OFF = 'off'
local VALUE_ANION_ON = 'on'
local VALUE_ANION_OFF = 'off'
local VALUE_SCHEDULE_CLOSE_SWITCHER_ON = 'on'
local VALUE_SCHEDULE_CLOSE_SWITCHER_OFF = 'off'
local VALUE_MODE_AUTO = 'auto'
local VALUE_MODE_MANUAL = 'manual'
local VALUE_MODE_SLEEP = 'sleep'
local VALUE_FAN_SPEED_AUTO = 'auto'
local VALUE_FAN_SPEED_FIXED = 'fixed'
local VALUE_FAN_SPEED_HIGH = 'high'
local VALUE_FAN_SPEED_MID = 'middle'
local VALUE_FAN_SPEED_LOW = 'low'
local VALUE_FAN_SPEED_MUTE = 'mute'
local VALUE_BUZZER_ON = 'on'
local VALUE_BUZZER_OFF = 'off'

local BYTE_DEVICE_TYPE = 0xFC
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local BYTE_ANION_ON = 0x40
local BYTE_ANION_OFF = 0x00
local BYTE_MODE_AUTO = 0x10
local BYTE_MODE_MANUAL = 0x20
local BYTE_MODE_SLEEP = 0x30
local BYTE_BUZZER_ON = 0x40
local BYTE_BUZZER_OFF = 0x00
local BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON = 0x80
local BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_OFF = 0x7F

local power
local anion
local mode
local fanSpeed
local pm25 = 0
local tvoc = 0
local ashTvoc = 0
local smellTvoc = 0
local errorCode = 0
local buzzer
local scheduleCloseSwitcher = false
local scheduleCloseTime = 0
local humidifyMode = 0
local scheduleTimeValidate = true
local dataType = 0
local hasUart = true

function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_POWER] == VALUE_POWER_ON then
        power = BYTE_POWER_ON
    elseif luaTable[KEY_POWER] == VALUE_ANION_OFF then
        power = BYTE_POWER_OFF
    end
    if luaTable[KEY_ANION] == VALUE_ANION_ON then
        anion = BYTE_ANION_ON
    elseif luaTable[KEY_ANION] == VALUE_ANION_OFF then
        anion = BYTE_ANION_OFF
    end
    if luaTable[KEY_MODE] == VALUE_MODE_AUTO then
        mode = BYTE_MODE_AUTO
    elseif luaTable[KEY_MODE] == VALUE_MODE_MANUAL then
        mode = BYTE_MODE_MANUAL
    elseif luaTable[KEY_MODE] == VALUE_MODE_SLEEP then
        mode = BYTE_MODE_SLEEP
    end
    fanSpeed = checkBoundary(luaTable[KEY_FAN_SPEED], 0, 101)
    if luaTable[KEY_SCHEDULE_CLOSE_SWITCHER] == VALUE_SCHEDULE_CLOSE_SWITCHER_ON then
        scheduleCloseSwitcher = true
    elseif luaTable[KEY_SCHEDULE_CLOSE_SWITCHER] ==
        VALUE_SCHEDULE_CLOSE_SWITCHER_OFF then
        scheduleCloseSwitcher = false
    end
    if luaTable[KEY_SCHEDULE_CLOSE_TIME] ~= nil then
        scheduleCloseTime = luaTable[KEY_SCHEDULE_CLOSE_TIME]
    end
    if luaTable[KEY_BUZZER] == VALUE_BUZZER_ON then
        buzzer = BYTE_BUZZER_ON
    elseif luaTable[KEY_BUZZER] == VALUE_BUZZER_OFF then
        buzzer = BYTE_BUZZER_OFF
    end
    if (luaTable['humidify_mode'] ~= nil) then
        if luaTable['humidify_mode'] == 'none' then
            humidifyMode = 0x00
        elseif luaTable['humidify_mode'] == 'manual' then
            humidifyMode = 0x01
        elseif luaTable['humidify_mode'] == 'auto' then
            humidifyMode = 0x02
        elseif luaTable['humidify_mode'] == 'continu' then
            humidifyMode = 0x03
        end
    end
end

function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == 0x02 or dataType == 0x03) then
        power = bit.band(messageBytes[1], 0x01)
        mode = bit.band(messageBytes[2], 0xF0)
        fanSpeed = bit.band(messageBytes[3], 0x7F)
        if (bit.band(messageBytes[5], BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON) ==
            BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON) then
            scheduleCloseSwitcher = true
        else
            scheduleCloseSwitcher = false
        end
        local hour = bit.rshift(bit.band(messageBytes[5], 0x7F), 2)
        local stepMintues = bit.band(messageBytes[5], 0x03)
        local min = 15 - bit.band(messageBytes[6], 0x0f)
        scheduleCloseTime = hour * 60 + stepMintues * 15 + min
        humidifyMode = bit.band(messageBytes[8], 0x70)
        anion = bit.band(messageBytes[9], 0x40)
        ashTvoc = bit.band(messageBytes[12], 0x07)
        smellTvoc = bit.band(bit.rshift(messageBytes[12], 3), 0x07)
        local pm25High
        local pm25Low
        if (messageBytes[14] * 256) >= 0 then
            pm25High = (messageBytes[14] * 256)
        else
            pm25High = ((messageBytes[14] * 256) + 256)
        end
        if messageBytes[13] > 0 then
            pm25Low = messageBytes[13]
        else
            pm25Low = messageBytes[13] + 256
        end
        pm25 = pm25High + pm25Low
        tvoc = messageBytes[15]
        errorCode = messageBytes[21]
    end
end

function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (power == BYTE_POWER_ON) then
        streams[KEY_POWER] = VALUE_POWER_ON
    elseif (power == BYTE_POWER_OFF) then
        streams[KEY_POWER] = VALUE_POWER_OFF
    end
    if (anion == BYTE_ANION_ON) then
        streams[KEY_ANION] = VALUE_ANION_ON
    elseif (anion == BYTE_ANION_OFF) then
        streams[KEY_ANION] = VALUE_ANION_OFF
    end
    if (mode == BYTE_MODE_AUTO) then
        streams[KEY_MODE] = VALUE_MODE_AUTO
    elseif (mode == BYTE_MODE_MANUAL) then
        streams[KEY_MODE] = VALUE_MODE_MANUAL
    elseif (mode == BYTE_MODE_SLEEP) then
        streams[KEY_MODE] = VALUE_MODE_SLEEP
    end
    streams[KEY_FAN_SPEED] = fanSpeed
    streams[KEY_PM25] = pm25
    streams[KEY_TVOC] = tvoc
    streams[KEY_ASH_TVOC] = ashTvoc
    streams[KEY_SMELL_TVOC] = smellTvoc
    streams[KEY_ERROR_CODE] = errorCode
    if buzzer == BYTE_BUZZER_ON then
        streams[KEY_BUZZER] = VALUE_BUZZER_ON
    else
        streams[KEY_BUZZER] = VALUE_BUZZER_OFF
    end
    if scheduleCloseSwitcher then
        streams[KEY_SCHEDULE_CLOSE_SWITCHER] = VALUE_SCHEDULE_CLOSE_SWITCHER_ON
    else
        streams[KEY_SCHEDULE_CLOSE_SWITCHER] = VALUE_SCHEDULE_CLOSE_SWITCHER_OFF
    end
    streams[KEY_SCHEDULE_CLOSE_TIME] = scheduleCloseTime
    if (humidifyMode ~= nil) then
        if humidifyMode == 0x00 then
            streams['humidify_mode'] = 'none'
        elseif humidifyMode == 0x01 then
            streams['humidify_mode'] = 'manual'
        elseif humidifyMode == 0x02 then
            streams['humidify_mode'] = 'auto'
        elseif humidifyMode == 0x03 then
            streams['humidify_mode'] = 'continu'
        end
    end
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local bodyLength = 22
    local bodyBytes = {}
    for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (control) then
        if (status) then updateGlobalPropertyValueByJson(status) end
        if (control) then updateGlobalPropertyValueByJson(control) end
        bodyBytes[0] = 0x48
        bodyBytes[1] = bit.bor(bit.bor(power, buzzer), 0x02)
        bodyBytes[2] = mode
        if scheduleTimeValidate then
            bodyBytes[3] = bit.bor(fanSpeed, 0x80)
        else
            bodyBytes[3] = fanSpeed
        end
        local timeHour = math.floor(scheduleCloseTime / 60)
        local stepMintues = math.floor((scheduleCloseTime % 60) / 15)
        if scheduleCloseSwitcher then
            bodyBytes[5] = bit.bor(
                               bit.bor(BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON,
                                       bit.lshift(timeHour, 2)), stepMintues)
        else
            bodyBytes[5] = bit.bor(bit.bor(
                                       BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_OFF,
                                       bit.lshift(timeHour, 2)), stepMintues)
        end
        local mintues = math.floor((scheduleCloseTime % 60) % 15)
        bodyBytes[6] = bit.bor(0xF0, (15 - mintues))
        bodyBytes[9] = anion
        bodyBytes[10] = bit.band(humidifyMode, 0x07)
        math.randomseed(tostring(os.time()):reverse():sub(2, 7))
        bodyBytes[bodyLength - 2] = math.random(1, 254)
        bodyBytes[bodyLength - 1] = crc8_854(bodyBytes, 0, bodyLength - 2)
        if hasUart then
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        else
            msgBytes = bodyBytes
        end
    elseif (query) then
        bodyBytes[0] = 0x41
        bodyBytes[1] = 0x81
        bodyBytes[3] = 0xFF
        bodyBytes[4] = 0x03
        bodyBytes[7] = 0x02
        math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        bodyBytes[bodyLength - 2] = math.random(1, 254)
        bodyBytes[bodyLength - 1] = crc8_854(bodyBytes, 0, bodyLength - 2)
        if hasUart then
            msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
        else
            msgBytes = bodyBytes
        end
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
    local status = json['status']
    if (status) then updateGlobalPropertyValueByJson(status) end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10]
    if hasUart then
        bodyBytes = extractBodyBytes(byteData)
    else
        local bodyLength = #byteData
        for i = 1, #byteData do bodyBytes[i - 1] = byteData[i] end
        local crcRes = crc8_854(bodyBytes, 0, bodyLength - 2)
        if (crcRes ~= bodyBytes[bodyLength - 1]) then return nil end
    end
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
    if #bodyBytes == 0 then return nil end
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
