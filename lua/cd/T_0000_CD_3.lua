local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_MODE = 'mode'
local KEY_ERROR_CODE = 'error_code'
local VALUE_VERSION = '3'
local VALUE_FUNCTION_ON = 'on'
local VALUE_FUNCTION_OFF = 'off'

local BYTE_DEVICE_TYPE = 0xCD
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERYL_REQUEST = 0x03
local BYTE_AUTO_REPORT = 0x05
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00

local powerValue = 0
local modeValue = 0
local energyMode = 0
local standardMode = 0
local compatibilizingMode = 0
local heatValue = 0
local dicaryonHeat = 0
local eco = 0
local tsValue = 0
local washBoxTemp = 0
local boxTopTemp = 0
local boxBottomTemp = 0
local t3Value = 0
local t4Value = 0
local compressorTopTemp = 0
local tsMaxValue = 0
local tsMinValue = 0
local timer1OpenHour = 0
local timer1OpenMin = 0
local timer1CloseHour = 0
local timer1CloseMin = 0
local timer2OpenHour = 0
local timer2OpenMin = 0
local timer2CloseHour = 0
local timer2CloseMin = 0
local errorCode = 0
local order1Temp = 0
local order1TimeHour = 0
local order1TimeMin = 0
local order2Temp = 0
local order2TimeHour = 0
local order2TimeMin = 0
local bottomElecHeat = 0
local topElecHeat = 0
local waterPump = 0
local compressor = 0
local middleWind = 0
local fourWayValve = 0
local lowWind = 0
local highWind = 0
local timer1Effect = 0
local timer2Effect = 0
local order1Effect = 0
local order2Effect = 0
local smartEffect = 0
local backwaterEffect = 0
local sterilizeEffect = 0
local typeInfo = 0
local dataType = 0
local controlType = 0
local trValue = 0
local openPTC = 0
local ptcTemp = 0
local refrigerantRecycling = 0
local defrost = 0
local mute = 0
local openPTCTemp = 0

function jsonToModel(controlJson)
    local controlCmd = controlJson
    if controlCmd[KEY_POWER] ~= nil then
        if controlCmd[KEY_POWER] == VALUE_FUNCTION_ON then
            powerValue = BYTE_POWER_ON
        else
            powerValue = BYTE_POWER_OFF
        end
    end
    if controlCmd[KEY_MODE] ~= nil then
        if controlCmd[KEY_MODE] == 'energy' then
            modeValue = 0x01
        elseif controlCmd[KEY_MODE] == 'standard' then
            modeValue = 0x02
        elseif controlCmd[KEY_MODE] == 'compatibilizing' then
            modeValue = 0x03
        end
    end
    if controlCmd['set_temperature'] ~= nil then
        tsValue = string2Int(controlCmd['set_temperature'])
        tsValue = tsValue * 2 + 30
    end
    if controlCmd['tr_temperature'] ~= nil then
        trValue = string2Int(controlCmd['tr_temperature'])
        trValue = checkBoundary(trValue, 2, 6)
    end
    if controlCmd['open_ptc'] ~= nil then
        if controlCmd['open_ptc'] == '0' then
            openPTC = 0x00
        elseif controlCmd['open_ptc'] == '1' then
            openPTC = 0x01
        elseif controlCmd['open_ptc'] == '2' then
            openPTC = 0x02
        end
    end
    if controlCmd['ptc_temperature'] ~= nil then
        ptcTemp = string2Int(controlCmd['ptc_temperature'])
    end
    if controlCmd['water_pump'] ~= nil then
        if controlCmd['water_pump'] == VALUE_FUNCTION_ON then
            waterPump = BYTE_POWER_ON
        elseif controlCmd['water_pump'] == VALUE_FUNCTION_OFF then
            waterPump = BYTE_POWER_OFF
        end
    end
    if controlCmd['refrigerant_recycling'] ~= nil then
        if controlCmd['refrigerant_recycling'] == VALUE_FUNCTION_ON then
            refrigerantRecycling = BYTE_POWER_ON
        elseif controlCmd['refrigerant_recycling'] == VALUE_FUNCTION_OFF then
            refrigerantRecycling = BYTE_POWER_OFF
        end
    end
    if controlCmd['defrost'] ~= nil then
        if controlCmd['defrost'] == VALUE_FUNCTION_ON then
            defrost = BYTE_POWER_ON
        elseif controlCmd['defrost'] == VALUE_FUNCTION_OFF then
            defrost = BYTE_POWER_OFF
        end
    end
    if controlCmd['mute'] ~= nil then
        if controlCmd['mute'] == VALUE_FUNCTION_ON then
            mute = BYTE_POWER_ON
        elseif controlCmd['mute'] == VALUE_FUNCTION_OFF then
            mute = BYTE_POWER_OFF
        end
    end
    if controlCmd['open_ptc_temperature'] ~= nil then
        if controlCmd['open_ptc_temperature'] == VALUE_FUNCTION_ON then
            openPTCTemp = BYTE_POWER_ON
        elseif controlCmd['open_ptc_temperature'] == VALUE_FUNCTION_OFF then
            openPTCTemp = BYTE_POWER_OFF
        end
    end
end

function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = {}
    for i = 0, 29 do messageBytes[i] = 0 end
    for i = 0, #binData do messageBytes[i] = binData[i] end
    if (dataType == 0x03 or dataType == 0x05) then
        powerValue = bit.band(messageBytes[2], 0x01)
        energyMode = bit.rshift(bit.band(messageBytes[2], 0x02), 1)
        standardMode = bit.rshift(bit.band(messageBytes[2], 0x04), 2)
        compatibilizingMode = bit.rshift(bit.band(messageBytes[2], 0x08), 3)
        heatValue = bit.rshift(bit.band(messageBytes[2], 0x10), 4)
        dicaryonHeat = bit.rshift(bit.band(messageBytes[2], 0x20), 5)
        eco = bit.rshift(bit.band(messageBytes[2], 0x40), 6)
        tsValue = messageBytes[3]
        washBoxTemp = messageBytes[4]
        boxTopTemp = messageBytes[5]
        boxBottomTemp = messageBytes[6]
        t3Value = messageBytes[7]
        t4Value = messageBytes[8]
        compressorTopTemp = messageBytes[9]
        tsMaxValue = messageBytes[10]
        tsMinValue = messageBytes[11]
        timer1OpenHour = messageBytes[12]
        timer1OpenMin = messageBytes[13]
        timer1CloseHour = messageBytes[14]
        timer1CloseMin = messageBytes[15]
        timer2OpenHour = messageBytes[16]
        timer2OpenMin = messageBytes[17]
        timer2CloseHour = messageBytes[18]
        timer2CloseMin = messageBytes[19]
        errorCode = messageBytes[20]
        order1Temp = messageBytes[21]
        order1TimeHour = messageBytes[22]
        order1TimeMin = messageBytes[23]
        order2Temp = messageBytes[24]
        order2TimeHour = messageBytes[25]
        order2TimeMin = messageBytes[26]
        bottomElecHeat = bit.band(messageBytes[27], 0x01)
        topElecHeat = bit.rshift(bit.band(messageBytes[27], 0x02), 1)
        waterPump = bit.rshift(bit.band(messageBytes[27], 0x04), 2)
        compressor = bit.rshift(bit.band(messageBytes[27], 0x08), 3)
        middleWind = bit.rshift(bit.band(messageBytes[27], 0x10), 4)
        fourWayValve = bit.rshift(bit.band(messageBytes[27], 0x20), 5)
        lowWind = bit.rshift(bit.band(messageBytes[27], 0x40), 6)
        highWind = bit.rshift(bit.band(messageBytes[27], 0x80), 7)
        timer1Effect = bit.rshift(bit.band(messageBytes[28], 0x02), 1)
        timer2Effect = bit.rshift(bit.band(messageBytes[28], 0x04), 2)
        order1Effect = bit.rshift(bit.band(messageBytes[28], 0x08), 3)
        order2Effect = bit.rshift(bit.band(messageBytes[28], 0x10), 4)
        smartEffect = bit.rshift(bit.band(messageBytes[28], 0x20), 5)
        backwaterEffect = bit.rshift(bit.band(messageBytes[28], 0x40), 6)
        sterilizeEffect = bit.rshift(bit.band(messageBytes[28], 0x80), 7)
        typeInfo = messageBytes[29]
    elseif dataType == 0x02 then
        controlType = messageBytes[0]
        if controlType == 0x01 then
            powerValue = messageBytes[2]
            modeValue = messageBytes[3]
            tsValue = messageBytes[4]
            trValue = messageBytes[5]
            openPTC = messageBytes[6]
            ptcTemp = messageBytes[7]
            waterPump = bit.band(messageBytes[8], 0x01)
            refrigerantRecycling =
                bit.rshift(bit.band(messageBytes[8], 0x02), 1)
            defrost = bit.rshift(bit.band(messageBytes[8], 0x04), 2)
            mute = bit.rshift(bit.band(messageBytes[8], 0x08), 3)
            openPTCTemp = bit.rshift(bit.band(messageBytes[8], 0x02), 6)
        end
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    local infoM = {}
    local bodyBytes = {}
    if (query) then
        bodyBytes[0] = 0x01
        bodyBytes[1] = 0x01
        infoM = getTotalMsg(bodyBytes, BYTE_QUERYL_REQUEST)
    elseif (control) then
        if (status) then jsonToModel(status) end
        if (control) then jsonToModel(control) end
        for i = 0, 8 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0x01
        bodyBytes[1] = 0x01
        bodyBytes[2] = powerValue
        if control[KEY_MODE] ~= nil then
            bodyBytes[3] = modeValue
        else
            if (status['energy_mode'] ~= nil and status['energy_mode'] ==
                VALUE_FUNCTION_ON) or energyMode == BYTE_POWER_ON then
                bodyBytes[3] = 0x01
            elseif (status['standard_mode'] ~= nil and status['standard_mode'] ==
                VALUE_FUNCTION_ON) or standardMode == BYTE_POWER_ON then
                bodyBytes[3] = 0x02
            elseif (status['compatibilizing_mode'] ~= nil and
                status['compatibilizing_mode'] == VALUE_FUNCTION_ON) or
                compatibilizingMode == BYTE_POWER_ON then
                bodyBytes[3] = 0x03
            else
                bodyBytes[3] = modeValue
            end
        end
        bodyBytes[4] = tsValue
        bodyBytes[5] = trValue
        bodyBytes[6] = openPTC
        bodyBytes[7] = ptcTemp
        bodyBytes[8] = bit.bor(bit.bor(bit.bor(bit.bor(waterPump,
                                                       refrigerantRecycling),
                                               defrost), mute), openPTCTemp)
        infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[9] = cType
    for i = 0, bodyLength do msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyData[i] end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
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
    local msgSubType = 0
    info = string2table(binData)
    if (#info < 11) then return nil end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    dataType = msgBytes[9]
    msgSubType = msgBytes[10]
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then end
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    binToModel(bodyBytes)
    if (((dataType == BYTE_AUTO_REPORT) and (msgSubType == 0x01)) or
        (dataType == BYTE_QUERYL_REQUEST)) then
        if (powerValue == BYTE_POWER_ON) then
            streams[KEY_POWER] = VALUE_FUNCTION_ON
        elseif (powerValue == BYTE_POWER_OFF) then
            streams[KEY_POWER] = VALUE_FUNCTION_OFF
        end
        if (energyMode == BYTE_POWER_ON) then
            streams['energy_mode'] = VALUE_FUNCTION_ON
        elseif (energyMode == BYTE_POWER_OFF) then
            streams['energy_mode'] = VALUE_FUNCTION_OFF
        end
        if (standardMode == BYTE_POWER_ON) then
            streams['standard_mode'] = VALUE_FUNCTION_ON
        elseif (standardMode == BYTE_POWER_OFF) then
            streams['standard_mode'] = VALUE_FUNCTION_OFF
        end
        if (compatibilizingMode == BYTE_POWER_ON) then
            streams['compatibilizing_mode'] = VALUE_FUNCTION_ON
        elseif (compatibilizingMode == BYTE_POWER_OFF) then
            streams['compatibilizing_mode'] = VALUE_FUNCTION_OFF
        end
        if (heatValue == BYTE_POWER_ON) then
            streams['high_heat'] = VALUE_FUNCTION_ON
        elseif (compatibilizingMode == BYTE_POWER_OFF) then
            streams['high_heat'] = VALUE_FUNCTION_OFF
        end
        if (dicaryonHeat == BYTE_POWER_ON) then
            streams['dicaryon_heat'] = VALUE_FUNCTION_ON
        elseif (dicaryonHeat == BYTE_POWER_OFF) then
            streams['dicaryon_heat'] = VALUE_FUNCTION_OFF
        end
        if (eco == BYTE_POWER_ON) then
            streams['eco'] = VALUE_FUNCTION_ON
        elseif (eco == BYTE_POWER_OFF) then
            streams['eco'] = VALUE_FUNCTION_OFF
        end
        streams['set_temperature'] = int2String(math.modf((tsValue - 30) / 2))
        streams['water_box_temperature'] = int2String(
                                               math.modf((washBoxTemp - 30) / 2))
        streams['water_box_top_temperature'] =
            int2String(math.modf((boxTopTemp - 30) / 2))
        streams['water_box_bottom_temperature'] =
            int2String(math.modf((boxBottomTemp - 30) / 2))
        streams['condensator_temperature'] =
            int2String(math.modf((t3Value - 30) / 2))
        streams['outdoor_temperature'] = int2String(
                                             math.modf((t4Value - 30) / 2))
        streams['compressor_top_temperature'] =
            int2String(math.modf((compressorTopTemp - 30) / 2))
        streams['set_temperature_max'] =
            int2String(math.modf((tsMaxValue - 30) / 2))
        streams['set_temperature_min'] =
            int2String(math.modf((tsMinValue - 30) / 2))
        streams[KEY_ERROR_CODE] = int2String(errorCode)
        if (bottomElecHeat == BYTE_POWER_ON) then
            streams['bottom_elec_heat'] = VALUE_FUNCTION_ON
        elseif (bottomElecHeat == BYTE_POWER_OFF) then
            streams['bottom_elec_heat'] = VALUE_FUNCTION_OFF
        end
        if (topElecHeat == BYTE_POWER_ON) then
            streams['top_elec_heat'] = VALUE_FUNCTION_ON
        elseif (topElecHeat == BYTE_POWER_OFF) then
            streams['top_elec_heat'] = VALUE_FUNCTION_OFF
        end
        if (waterPump == BYTE_POWER_ON) then
            streams['water_pump'] = VALUE_FUNCTION_ON
        elseif (waterPump == BYTE_POWER_OFF) then
            streams['water_pump'] = VALUE_FUNCTION_OFF
        end
        if (compressor == BYTE_POWER_ON) then
            streams['compressor'] = VALUE_FUNCTION_ON
        elseif (compressor == BYTE_POWER_OFF) then
            streams['compressor'] = VALUE_FUNCTION_OFF
        end
        if (middleWind == BYTE_POWER_ON) then
            streams['middle_wind'] = VALUE_FUNCTION_ON
        elseif (middleWind == BYTE_POWER_OFF) then
            streams['middle_wind'] = VALUE_FUNCTION_OFF
        end
        if (fourWayValve == BYTE_POWER_ON) then
            streams['four_way_valve'] = VALUE_FUNCTION_ON
        elseif (fourWayValve == BYTE_POWER_OFF) then
            streams['four_way_valve'] = VALUE_FUNCTION_OFF
        end
        if (lowWind == BYTE_POWER_ON) then
            streams['low_wind'] = VALUE_FUNCTION_ON
        elseif (lowWind == BYTE_POWER_OFF) then
            streams['low_wind'] = VALUE_FUNCTION_OFF
        end
        if (highWind == BYTE_POWER_ON) then
            streams['high_wind'] = VALUE_FUNCTION_ON
        elseif (highWind == BYTE_POWER_OFF) then
            streams['high_wind'] = VALUE_FUNCTION_OFF
        end
        streams['type_info'] = int2String(typeInfo)
    elseif ((dataType == BYTE_CONTROL_REQUEST) and (msgSubType == 0x01)) then
        if (powerValue == BYTE_POWER_ON) then
            streams[KEY_POWER] = VALUE_FUNCTION_ON
        elseif (powerValue == BYTE_POWER_OFF) then
            streams[KEY_POWER] = VALUE_FUNCTION_OFF
        end
        if modeValue == 0x01 then
            streams[KEY_MODE] = 'energy'
        elseif modeValue == 0x02 then
            streams[KEY_MODE] = 'standard'
        elseif modeValue == 0x03 then
            streams[KEY_MODE] = 'compatibilizing'
        end
        streams['tr_temperature'] = int2String(math.modf(trValue))
        streams['open_ptc'] = int2String(openPTC)
        streams['ptc_temperature'] = int2String(math.modf(ptcTemp))
        if (refrigerantRecycling == BYTE_POWER_ON) then
            streams['refrigerant_recycling'] = VALUE_FUNCTION_ON
        elseif (refrigerantRecycling == BYTE_POWER_OFF) then
            streams['refrigerant_recycling'] = VALUE_FUNCTION_OFF
        end
        if (defrost == BYTE_POWER_ON) then
            streams['defrost'] = VALUE_FUNCTION_ON
        elseif (defrost == BYTE_POWER_OFF) then
            streams['defrost'] = VALUE_FUNCTION_OFF
        end
        if (mute == BYTE_POWER_ON) then
            streams['mute'] = VALUE_FUNCTION_ON
        elseif (mute == BYTE_POWER_OFF) then
            streams['mute'] = VALUE_FUNCTION_OFF
        end
        if (openPTCTemp == BYTE_POWER_ON) then
            streams['open_ptc_temperature'] = VALUE_FUNCTION_ON
        elseif (openPTCTemp == BYTE_POWER_OFF) then
            streams['open_ptc_temperature'] = VALUE_FUNCTION_OFF
        end
        streams['set_temperature'] = int2String(math.modf((tsValue - 30) / 2))
        if (waterPump == BYTE_POWER_ON) then
            streams['water_pump'] = VALUE_FUNCTION_ON
        elseif (waterPump == BYTE_POWER_OFF) then
            streams['water_pump'] = VALUE_FUNCTION_OFF
        end
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
