local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_CMD_CODE = 'cmd_code'
local KEY_WORK_STATUS = 'work_status'
local KEY_TASTE = 'taste'
local KEY_PRESSURE = 'pressure'
local KEY_RICE_TYPE = 'rice_type'
local KEY_FIRE_LEVEL = 'fire_level'
local KEY_TEMPERATURE = 'temperature'
local KEY_TIME_RESERVE_HR = 'time_reserve_hr'
local KEY_TIME_RESERVE_MIN = 'time_reserve_min'
local KEY_TIME_WORK_HR = 'time_work_hr'
local KEY_TIME_WORK_MIN = 'time_work_min'
local KEY_TIME_PRESSURIZE_HR = 'time_pressurize_hr'
local KEY_TIME_PRESSURIZE_MIN = 'time_pressurize_min'
local KEY_TIME_RESERVE_SETTING_HR = 'time_reserve_setting_hr'
local KEY_TIME_RESERVE_SETTING_MIN = 'time_reserve_setting_min'
local KEY_TIME_BUBBLE = 'time_bubble'
local KEY_SHOW_TYPE = 'show_type'
local KEY_ERROR_CODE = 'error_code'
local KEY_TIME_WARM_HR = 'time_warm_hr'
local KEY_TIME_WARM_MIN = 'time_warm_min'
local KEY_TEMPERATURE_TOP = 'temperature_top'
local KEY_TEMPERATURE_BOTTOM = 'temperature_bottom'
local KEY_WORK_FLAG = 'work_flag'
local KEY_TIME_WORK_SETTING_HR = 'time_work_setting_hr'
local KEY_TIME_WORK_SETTING_MIN = 'time_work_setting_min'
local KEY_OPEN_CAP = 'open_cap'
local KEY_WATER_CHECK = 'water_check'
local KEY_ZERO_PRESS = 'zero_press'
local KEY_INSIDE_POT_STATUS = 'inside_pot_status'
local KEY_BALANCE_STATUS = 'balance_status'
local KEY_BOIL_STATUS = 'boil_status'
local KEY_PAUSE_OPEN_CAP = 'pause_open_cap'
local KEY_PRESS_SWITCH = 'press_switch'

local VALUE_VERSION = '4'
local deviceSubType = '0'
local BYTE_DEVICE_TYPE = 0xEC
local BYTE_MSG_TYPE_CONTROL = 0x02
local BYTE_MSG_TYPE_QUERY = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_HEAD_LENGTH = 0x0A

local cmdCode
local workStatus
local errorCode = 0
local timeReserveMin = 0
local timeReserveHr = 0
local timeWorkMin = 0
local timeWorkHr = 0
local timePressurizeHr = 0
local timePressurizeMin = 0
local timeWarmHr = 0
local timeWarmMin = 0
local taste = 0
local pressure = 0
local fireLevel = 0
local riceType = 0
local temperatureTop = 0
local temperatureBottom = 0
local workFlag
local timeReserveSettingMin = 0
local timeReserveSettingHr = 0
local timeWorkSettingMin = 0
local timeWorkSettingHr = 0
local temperature = 0
local timeBubble = 0
local openCap = 0
local waterCheck = 0
local zeroPress = 0
local insidePotStatus = 0
local balanceStatus = 0
local boilStatus = 0
local pauseOpenCap = 0
local pressSwitch = 0
local showType = 0
local dataType = 0

local function getSoftVersion()
    if deviceSubType == '14' or deviceSubType == '1' or deviceSubType == '7' then
        return 0
    else
        return 1
    end
end

local function jsonToModel(jsonCmd)
    local streams = jsonCmd
    cmdCode = string2Int(streams[KEY_CMD_CODE])
    if (streams[KEY_WORK_STATUS] ~= nil) then
        workStatus = checkBoundary(streams[KEY_WORK_STATUS], 0, 255)
    end
    if (streams[KEY_TASTE] ~= nil) then
        taste = checkBoundary(streams[KEY_TASTE], 0, 255)
    end
    if (streams[KEY_PRESSURE] ~= nil) then
        pressure = checkBoundary(streams[KEY_PRESSURE], 0, 255)
    end
    if (streams[KEY_TIME_RESERVE_HR] ~= nil) then
        timeReserveHr = checkBoundary(streams[KEY_TIME_RESERVE_HR], 0, 255)
    end
    if (streams[KEY_TIME_RESERVE_MIN] ~= nil) then
        timeReserveMin = checkBoundary(streams[KEY_TIME_RESERVE_MIN], 0, 255)
    end
    if (streams[KEY_TIME_WORK_HR] ~= nil) then
        timeWorkHr = checkBoundary(streams[KEY_TIME_WORK_HR], 0, 255)
    end
    if (streams[KEY_TIME_WORK_MIN] ~= nil) then
        timeWorkMin = checkBoundary(streams[KEY_TIME_WORK_MIN], 0, 255)
    end
    if (streams[KEY_TIME_RESERVE_SETTING_HR] ~= nil) then
        timeReserveSettingHr = checkBoundary(
                                   streams[KEY_TIME_RESERVE_SETTING_HR], 0, 255)
    end
    if (streams[KEY_TIME_RESERVE_SETTING_MIN] ~= nil) then
        timeReserveSettingMin = checkBoundary(
                                    streams[KEY_TIME_RESERVE_SETTING_MIN], 0,
                                    255)
    end
    if (streams[KEY_TIME_BUBBLE] ~= nil) then
        timeBubble = checkBoundary(streams[KEY_TIME_BUBBLE], 0, 255)
    end
    if (streams[KEY_SHOW_TYPE] ~= nil) then
        showType = checkBoundary(streams[KEY_SHOW_TYPE], 0, 255)
    end
    if (streams[KEY_RICE_TYPE] ~= nil) then
        riceType = string2Int(streams[KEY_RICE_TYPE])
    end
end

local function binToModel(binData)
    if (#binData < 11) then return nil end
    local messageBytes = binData
    if getSoftVersion() == 0 then
        if (dataType == 0x03 and messageBytes[5] == 0x3D) then
            cmdCode = messageBytes[6] + bit.lshift(messageBytes[7], 8)
            taste = messageBytes[9]
            pressure = messageBytes[10]
            fireLevel = messageBytes[11]
            riceType = messageBytes[12] + bit.lshift(messageBytes[13], 8)
            workStatus = messageBytes[14]
            workFlag = messageBytes[16]
            temperatureTop = messageBytes[18]
            temperatureBottom = messageBytes[19]
            timeReserveHr = messageBytes[20]
            timeReserveMin = messageBytes[21]
            timeWarmHr = messageBytes[26]
            timeWarmMin = messageBytes[27]
            timeWorkHr = messageBytes[28]
            timeWorkMin = messageBytes[29]
            errorCode = messageBytes[33]
        end
        if (dataType == 0x02 and messageBytes[5] == 0x16) or
            (dataType == 0x04 and messageBytes[5] == 0x3D) then
            cmdCode = messageBytes[6] + bit.lshift(messageBytes[7], 8)
            taste = messageBytes[9]
            pressure = messageBytes[10]
            fireLevel = messageBytes[11]
            riceType = messageBytes[12] + bit.lshift(messageBytes[13], 8)
            workStatus = messageBytes[14]
            workFlag = messageBytes[16]
            temperatureTop = messageBytes[18]
            temperatureBottom = messageBytes[19]
            timeReserveHr = messageBytes[20]
            timeReserveMin = messageBytes[21]
            timeWarmHr = messageBytes[26]
            timeWarmMin = messageBytes[27]
            timeWorkHr = messageBytes[28]
            timeWorkMin = messageBytes[29]
            errorCode = messageBytes[30]
        end
    else
        if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04) then
            cmdCode = messageBytes[4] + bit.lshift(messageBytes[5], 8) +
                          bit.lshift(messageBytes[6], 16) +
                          bit.lshift(messageBytes[7], 24)
            workStatus = messageBytes[8]
            errorCode = messageBytes[9]
            timeReserveHr = messageBytes[10]
            timeReserveMin = messageBytes[11]
            timeWorkHr = messageBytes[12]
            timeWorkMin = messageBytes[13]
            timePressurizeHr = messageBytes[14]
            timePressurizeMin = messageBytes[15]
            timeWarmHr = messageBytes[16]
            timeWarmMin = messageBytes[17]
            taste = messageBytes[18]
            pressure = messageBytes[19]
            fireLevel = messageBytes[20]
            temperatureTop = messageBytes[21]
            temperatureBottom = messageBytes[22]
            workFlag = messageBytes[23]
            openCap = bit.band(messageBytes[23], 0x01)
            waterCheck = bit.rshift(bit.band(messageBytes[23], 0x02), 1)
            zeroPress = bit.rshift(bit.band(messageBytes[23], 0x04), 2)
            insidePotStatus = bit.rshift(bit.band(messageBytes[23], 0x08), 3)
            balanceStatus = bit.rshift(bit.band(messageBytes[23], 0x10), 4)
            boilStatus = bit.rshift(bit.band(messageBytes[23], 0x20), 5)
            pauseOpenCap = bit.rshift(bit.band(messageBytes[23], 0x40), 6)
            pressSwitch = bit.rshift(bit.band(messageBytes[23], 0x80), 7)
            timeReserveSettingHr = messageBytes[24]
            timeReserveSettingMin = messageBytes[25]
            timeWorkSettingHr = messageBytes[26]
            timeWorkSettingMin = messageBytes[27]
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
    if getSoftVersion() == 0 then
        if (query) then
            for i = 0, 21 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x03
            bodyBytes[4] = 0x16
            bodyBytes[5] = 0x03
            bodyBytes[6] = 0x55
            bodyBytes[7] = 0xc3
            bodyBytes[21] = makeSum(bodyBytes, 0, 20)
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_QUERY)
        elseif (control) then
            if (status) then jsonToModel(status) end
            if (control) then jsonToModel(control) end
            for i = 0, 24 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x03
            bodyBytes[4] = 0x19
            bodyBytes[5] = 0x02
            bodyBytes[6] = bit.band(cmdCode, 0xFF)
            bodyBytes[7] = bit.band(bit.rshift(cmdCode, 8), 0xFF)
            bodyBytes[8] = taste
            bodyBytes[9] = pressure
            bodyBytes[10] = fireLevel
            bodyBytes[11] = bit.band(riceType, 0xFF)
            bodyBytes[12] = bit.band(bit.rshift(riceType, 8), 0xFF)
            bodyBytes[13] = workStatus
            bodyBytes[16] = timeReserveHr
            bodyBytes[17] = timeReserveMin
            bodyBytes[18] = timeWorkHr
            bodyBytes[19] = timeWorkMin
            bodyBytes[24] = makeSum(bodyBytes, 0, 23)
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_CONTROL)
        end
    else
        if (query) then
            for i = 0, 9 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[3] = BYTE_MSG_TYPE_QUERY
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_QUERY)
        elseif (control) then
            if (status) then jsonToModel(status) end
            if (control) then jsonToModel(control) end
            for i = 0, 23 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[3] = BYTE_MSG_TYPE_CONTROL
            bodyBytes[4] = bit.band(cmdCode, 0xFF)
            bodyBytes[5] = bit.band(bit.rshift(cmdCode, 8), 0xFF)
            bodyBytes[6] = bit.band(bit.rshift(cmdCode, 16), 0xFF)
            bodyBytes[7] = bit.band(bit.rshift(cmdCode, 24), 0xFF)
            bodyBytes[8] = workStatus
            bodyBytes[9] = taste
            bodyBytes[10] = pressure
            bodyBytes[13] = timeReserveHr
            bodyBytes[14] = timeReserveMin
            bodyBytes[15] = timeWorkHr
            bodyBytes[16] = timeWorkMin
            bodyBytes[19] = timeReserveSettingHr
            bodyBytes[20] = timeReserveSettingMin
            bodyBytes[21] = timeBubble
            bodyBytes[22] = showType
            infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_CONTROL)
        end
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    if getSoftVersion() == 0 then
        msgBytes[8] = 0x00
    else
        msgBytes[8] = 0x01
    end
    msgBytes[9] = cType
    for i = 0, bodyLength do
        msgBytes[i + BYTE_PROTOCOL_HEAD_LENGTH] = bodyData[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
end

function dataToJson(jsonCmd)
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    deviceSubType = json['deviceinfo']['deviceSubType']
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
    if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04) then
        streams[KEY_CMD_CODE] = int2String(cmdCode)
        streams[KEY_WORK_STATUS] = int2String(workStatus)
        if (workStatus == 3) then streams[KEY_CMD_CODE] = '20017' end
        streams[KEY_ERROR_CODE] = int2String(errorCode)
        streams[KEY_TIME_RESERVE_HR] = int2String(timeReserveHr)
        streams[KEY_TIME_RESERVE_MIN] = int2String(timeReserveMin)
        streams[KEY_TIME_WORK_HR] = int2String(timeWorkHr)
        streams[KEY_TIME_WORK_MIN] = int2String(timeWorkMin)
        streams[KEY_TIME_PRESSURIZE_HR] = int2String(timePressurizeHr)
        streams[KEY_TIME_PRESSURIZE_MIN] = int2String(timePressurizeMin)
        streams[KEY_TIME_WARM_HR] = int2String(timeWarmHr)
        streams[KEY_TIME_WARM_MIN] = int2String(timeWarmMin)
        streams[KEY_TASTE] = int2String(taste)
        streams[KEY_PRESSURE] = int2String(pressure)
        streams[KEY_FIRE_LEVEL] = int2String(fireLevel)
        streams[KEY_TEMPERATURE_TOP] = int2String(temperatureTop)
        streams[KEY_TEMPERATURE_BOTTOM] = int2String(temperatureBottom)
        streams[KEY_WORK_FLAG] = int2String(workFlag)
        streams[KEY_OPEN_CAP] = int2String(openCap)
        streams[KEY_WATER_CHECK] = int2String(waterCheck)
        streams[KEY_ZERO_PRESS] = int2String(zeroPress)
        streams[KEY_INSIDE_POT_STATUS] = int2String(insidePotStatus)
        streams[KEY_BALANCE_STATUS] = int2String(balanceStatus)
        streams[KEY_BOIL_STATUS] = int2String(boilStatus)
        streams[KEY_PAUSE_OPEN_CAP] = int2String(pauseOpenCap)
        streams[KEY_PRESS_SWITCH] = int2String(pressSwitch)
        streams[KEY_TIME_RESERVE_SETTING_HR] = int2String(timeReserveSettingHr)
        streams[KEY_TIME_RESERVE_SETTING_MIN] =
            int2String(timeReserveSettingMin)
        streams[KEY_TIME_WORK_SETTING_HR] = int2String(timeWorkSettingHr)
        streams[KEY_TIME_WORK_SETTING_MIN] = int2String(timeWorkSettingMin)
        streams[KEY_RICE_TYPE] = int2String(riceType)
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
