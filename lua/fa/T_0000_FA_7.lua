local JSON = require 'cjson'
local powerValue
local modeValue
local gearValue
local swingAngleValue
local swingValue
local swingDirectionValue
local errorCode = 0
local dataType
local voiceValue = 0
local lockValue = 0
local sleepSensor = 0
local scene = 0
local bodyFeelingScan = 0
local tempFeedback = 0
local humFeedback = 0
local anion = 0
local anophelifuge = 0
local humidification = 0
local humidity = 0
local temperature = 0
local timerOffHour = 0
local timerOffMinuteTen = 0
local timerOffMinuteBit = 0
local timerOnHour = 0
local timerOnMinuteTen = 0
local timerOnMinuteBit = 0

function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams['power'] == 'on') then
        powerValue = 0x01
    elseif (streams['power'] == 'off') then
        powerValue = 0x00
    end
    if (streams['swing'] == 'on') then
        swingValue = 0x01
        swingAngleValue = 0x03
    elseif (streams['swing'] == 'off') then
        swingValue = 0x00
    end
    if (streams['mode'] == 'normal') then
        modeValue = 0x01
    elseif (streams['mode'] == 'natural') then
        modeValue = 0x02
    elseif (streams['mode'] == 'sleep') then
        modeValue = 0x03
    elseif (streams['mode'] == 'mute') then
        modeValue = 0x05
    elseif (streams['mode'] == 'baby') then
        modeValue = 0x06
    elseif (streams['mode'] == 'comfort') then
        modeValue = 0x04
    elseif (streams['mode'] == 'feel') then
        modeValue = 0x07
    end
    if (streams['swing_angle'] == 'unknown') then
        swingAngleValue = 0x00
    elseif (streams['swing_angle'] == '30') then
        swingAngleValue = 0x01
    elseif (streams['swing_angle'] == '60') then
        swingAngleValue = 0x02
    elseif (streams['swing_angle'] == '90') then
        swingAngleValue = 0x03
    elseif (streams['swing_angle'] == '120') then
        swingAngleValue = 0x04
    end
    if (streams['swing_direction '] == 'unknown') then
        swingDirectionValue = 0x00
    elseif (streams['swing_direction '] == 'up') then
        swingDirectionValue = 0x02
    elseif (streams['swing_direction '] == 'lr') then
        swingDirectionValue = 0x01
    elseif (streams['swing_direction '] == 'w') then
        swingDirectionValue = 0x03
    elseif (streams['swing_direction '] == '8') then
        swingDirectionValue = 0x04
    end
    if (streams['gear'] ~= nil) then
        gearValue = checkBoundary(streams['gear'], 1, 26)
    end
    if streams['voice'] ~= nil then
        if streams['voice'] == 'invalid' then
            voiceValue = 0x00
        elseif streams['voice'] == 'open_gps' then
            voiceValue = 0x01
        elseif streams['voice'] == 'close_gps' then
            voiceValue = 0x02
        elseif streams['voice'] == 'open_buzzer' then
            voiceValue = 0x04
        elseif streams['voice'] == 'close_buzzer' then
            voiceValue = 0x08
        elseif streams['voice'] == 'open_tip' then
            voiceValue = 0x05
        elseif streams['voice'] == 'mute' then
            voiceValue = 0x0A
        end
    end
    if streams['lock'] ~= nil then
        if streams['lock'] == 'invalid' then
            lockValue = 0x00
        elseif streams['lock'] == 'on' then
            lockValue = 0x01
        elseif streams['lock'] == 'off' then
            lockValue = 0x02
        end
    end
    if streams['scene'] ~= nil then
        if streams['scene'] == 'none' then
            scene = 0x00
        elseif streams['scene'] == 'old' then
            scene = 0x01
        elseif streams['scene'] == 'child' then
            scene = 0x02
        elseif streams['scene'] == 'read' then
            scene = 0x03
        elseif streams['scene'] == 'sleep' then
            scene = 0x04
        elseif streams['scene'] == 'ac' then
            scene = 0x05
        elseif streams['scene'] == 'invalid' then
            scene = 0xFF
        end
    end
    if streams['body_feeling_scan'] ~= nil then
        if streams['body_feeling_scan'] == 'off' then
            bodyFeelingScan = 0x00
        elseif streams['body_feeling_scan'] == 'on' then
            bodyFeelingScan = 0x01
        elseif streams['body_feeling_scan'] == 'invalid' then
            bodyFeelingScan = 0xFF
        end
    end
    if streams['anion'] ~= nil then
        if streams['anion'] == 'invalid' then
            anion = 0x00
        elseif streams['anion'] == 'on' then
            anion = 0x01
        elseif streams['anion'] == 'off' then
            anion = 0x02
        end
    end
    if streams['anophelifuge'] ~= nil then
        if streams['anophelifuge'] == 'invalid' then
            anophelifuge = 0x00
        elseif streams['anophelifuge'] == 'on' then
            anophelifuge = 0x01
        elseif streams['anophelifuge'] == 'off' then
            anophelifuge = 0x02
        end
    end
    if streams['humidification'] ~= nil then
        if streams['humidification'] == 'invalid' then
            humidification = 0x00
        elseif streams['humidification'] == 'off' then
            humidification = 0x01
        elseif streams['humidification'] == 'no_change' then
            humidification = 0x02
        elseif streams['humidification'] == '1' then
            humidification = 0x03
        elseif streams['humidification'] == '2' then
            humidification = 0x04
        elseif streams['humidification'] == '3' then
            humidification = 0x05
        end
    end
    if streams['humidity'] ~= nil then
        if streams['humidity'] == 'invalid' then
            humidity = 0x00
        else
            humidity = checkBoundary(streams['humidity'], 1, 100)
        end
    end
    if streams['temperature'] ~= nil then
        if streams['temperature'] == 'invalid' then
            temperature = 0x00
        else
            temperature = checkBoundary(streams['temperature'], -40, 50)
        end
    end
    if streams['timer_off_hour'] ~= nil then
        timerOffHour = checkBoundary(string2Int(streams['timer_off_hour']), 0,
                                     24)
    end
    if streams['timer_off_minute'] ~= nil then
        if streams['timer_off_minute'] == 'clean' then
            timerOffMinuteTen = 0x06
            timerOffMinuteBit = 0x00
        else
            timerOffMinuteTen = math.modf(
                                    checkBoundary(string2Int(
                                                      streams['timer_off_minute']),
                                                  0, 24) / 10)
            timerOffMinuteBit = checkBoundary(string2Int(
                                                  streams['timer_off_minute']),
                                              0, 24) % 10
        end
    end
    if streams['timer_on_hour'] ~= nil then
        timerOnHour = checkBoundary(string2Int(streams['timer_on_hour']), 0, 24)
    end
    if streams['timer_on_minute'] ~= nil then
        if streams['timer_on_minute'] == 'clean' then
            timerOnMinuteTen = 0x06
            timerOnMinuteBit = 0x00
        else
            timerOnMinuteTen = math.modf(
                                   checkBoundary(string2Int(
                                                     streams['timer_off_minute']),
                                                 0, 24) / 10)
            timerOnMinuteBit = checkBoundary(string2Int(
                                                 streams['timer_on_minute']), 0,
                                             24) % 10
        end
    end
end

function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = binData
    powerValue = bit.band(messageBytes[4], 0x01)
    modeValue = bit.rshift(bit.band(messageBytes[4], 0x0E), 1)
    gearValue = messageBytes[5]
    swingValue = bit.band(messageBytes[8], 0x01)
    swingDirectionValue = bit.rshift(bit.band(messageBytes[8], 0x0E), 1)
    swingAngleValue = bit.rshift(bit.band(messageBytes[8], 0x70), 4)
    errorCode = messageBytes[1]
    voiceValue = messageBytes[2]
    lockValue = messageBytes[3]
    sleepSensor = messageBytes[17]
    scene = messageBytes[16]
    bodyFeelingScan = messageBytes[15]
    tempFeedback = messageBytes[13]
    humFeedback = messageBytes[12]
    anion = bit.band(messageBytes[9], 0x03)
    anophelifuge = bit.rshift(bit.band(messageBytes[9], 0x0C), 2)
    humidification = bit.rshift(bit.band(messageBytes[9], 0xF0), 4)
    humidity = messageBytes[7]
    temperature = messageBytes[6]
    timerOffHour = bit.band(messageBytes[10], 0x01F)
    timerOffMinuteTen = bit.rshift(bit.band(messageBytes[10], 0xE0), 5)
    timerOffMinuteBit = bit.rshift(bit.band(messageBytes[14], 0xF0), 4)
    timerOnHour = bit.band(messageBytes[11], 0x1F)
    timerOnMinuteTen = bit.rshift(bit.band(messageBytes[11], 0xE0), 5)
    timerOnMinuteBit = bit.band(messageBytes[14], 0x0F)
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    local bodyLength
    if (query) then
        bodyLength = 0
    elseif (control) then
        bodyLength = 19
    end
    local msgLength = bodyLength + 0x0A + 1
    local bodyBytes = {}
    for i = 0, bodyLength do bodyBytes[i] = 0 end
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = 0xAA
    msgBytes[1] = bodyLength + 0x0A + 1
    msgBytes[2] = 0xFA
    if (query) then
        bodyBytes[0] = 0x00
        msgBytes[9] = 0x03
    elseif (control) then
        if (status) then jsonToModel(status) end
        local oldPower = powerValue
        if (control) then jsonToModel(control) end
        local newPower = powerValue
        local havePower = false
        local haveMode = false
        local haveGear = false
        local haveSwing = false
        local haveSwingAngle = false
        local haveSwingDirection = false
        local haveVoice = false
        local haveLock = false
        local haveScene = false
        local haveScan = false
        local haveAnion = false
        local haveAnophelifuge = false
        local haveAddHumi = false
        local haveHumi = false
        local haveTemp = false
        local haveOffMin = false
        local haveOffHour = false
        local haveOnMin = false
        local haveOnHour = false
        for key, value in pairs(control) do
            if key == 'power' then havePower = true end
            if key == 'mode' then haveMode = true end
            if key == 'swing' then haveSwing = true end
            if key == 'swing_angle' then haveSwingAngle = true end
            if key == 'swing_direction' then
                haveSwingDirection = true
            end
            if key == 'gear' then haveGear = true end
            if key == 'voice' then haveVoice = true end
            if key == 'lock' then haveLock = true end
            if key == 'scene' then haveScene = true end
            if key == 'body_feeling_scan' then haveScan = true end
            if key == 'anion' then haveAnion = true end
            if key == 'anophelifuge' then haveAnophelifuge = true end
            if key == 'humidification' then haveAddHumi = true end
            if key == 'humidity' then haveHumi = true end
            if key == 'temperature' then haveTemp = true end
            if key == 'timer_off_minute' then haveOffMin = true end
            if key == 'timer_off_hour' then haveOffHour = true end
            if key == 'timer_on_minute' then haveOnMin = true end
            if key == 'timer_on_hour' then haveOnHour = true end
        end
        local modeTemp = 0x00
        if haveMode == true then
            modeTemp = modeValue
        else
            modeTemp = 0x00
        end
        bodyBytes[4] = bit.bor(bit.lshift(modeTemp, 1), powerValue)
        if (havePower == false) or (newPower == oldPower) then
            bodyBytes[4] = bit.bor(0x80, bodyBytes[4])
        end
        if (modeValue == 0x01 or modeValue == 0x03) then
            if haveGear == true then
                bodyBytes[5] = gearValue
            else
                bodyBytes[5] = 0x00
            end
        else
            bodyBytes[5] = 0x00
        end
        if haveSwingAngle == false then swingAngleValue = 0x00 end
        if haveSwingDirection == false then swingDirectionValue = 0x00 end
        bodyBytes[8] = bit.bor(bit.bor(bit.lshift(swingAngleValue, 4),
                                       swingValue),
                               bit.lshift(swingDirectionValue, 1))
        if (haveSwing == false) and (haveSwingAngle == false) and
            (haveSwingDirection == false) then
            bodyBytes[8] = bit.bor(0x80, bodyBytes[8])
        end
        if haveVoice == true then
            bodyBytes[2] = voiceValue
        else
            bodyBytes[2] = 0x00
        end
        if haveLock == true then
            bodyBytes[3] = lockValue
        else
            bodyBytes[3] = 0x00
        end
        if haveScene == true then
            bodyBytes[16] = scene
        else
            bodyBytes[16] = 0x00
        end
        if haveScan == true then
            bodyBytes[15] = bodyFeelingScan
        else
            bodyBytes[15] = 0x00
        end
        if haveAnion == false then anion = 0x00 end
        if haveAnophelifuge == false then anophelifuge = 0x00 end
        if haveAddHumi == false then humidification = 0x00 end
        bodyBytes[9] = bit.bxor(bit.bxor(anion, bit.lshift(anophelifuge, 2)),
                                bit.lshift(humidification, 4))
        if haveHumi == true then
            bodyBytes[7] = humidity
        else
            bodyBytes[7] = 0x00
        end
        if haveTemp == true then
            bodyBytes[6] = temperature + 41
        else
            bodyBytes[6] = 0x00
        end
        if haveOffHour == false then timerOffHour = 0x00 end
        if haveOffMin == false then
            timerOffMinuteTen = 0x00
            timerOffMinuteBit = 0x00
        end
        if haveOnHour == false then timerOnHour = 0x00 end
        if haveOnMin == false then
            timerOnMinuteTen = 0x00
            timerOnMinuteBit = 0x00
        end
        bodyBytes[10] = bit.bxor(timerOffHour, bit.lshift(timerOffMinuteTen, 5))
        bodyBytes[11] = bit.bxor(timerOnHour, bit.lshift(timerOnMinuteTen, 5))
        bodyBytes[14] = bit.bxor(timerOnMinuteBit,
                                 bit.lshift(timerOffMinuteBit, 4))
        msgBytes[9] = 0x02
    end
    for i = 0, bodyLength do msgBytes[i + 0x0A] = bodyBytes[i] end
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
    local deviceinfo = json['deviceinfo']
    local deviceSubType = deviceinfo['deviceSubType']
    if (deviceSubType == 1) then end
    local binData = json['msg']['data']
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[10]
    if ((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04)) then
        return nil
    end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - 0x0A - 1
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then end
    for i = 0, bodyLength do bodyBytes[i] = msgBytes[i + 0x0A] end
    binToModel(bodyBytes)
    local streams = {}
    streams['version'] = 7
    if (powerValue == 0x01) then
        streams['power'] = 'on'
    elseif (powerValue == 0x00) then
        streams['power'] = 'off'
    end
    if (swingValue == 0x01) then
        streams['swing'] = 'on'
    elseif (swingValue == 0x00) then
        streams['swing'] = 'off'
    end
    if (modeValue == 0x01) then
        streams['mode'] = 'normal'
    elseif (modeValue == 0x02) then
        streams['mode'] = 'natural'
    elseif (modeValue == 0x03) then
        streams['mode'] = 'sleep'
    elseif (modeValue == 0x05) then
        streams['mode'] = 'mute'
    elseif (modeValue == 0x04) then
        streams['mode'] = 'comfort'
    elseif (modeValue == 0x06) then
        streams['mode'] = 'baby'
    elseif (modeValue == 0x07) then
        streams['mode'] = 'feel'
    end
    if (swingAngleValue == 0x00) then
        streams['swing_angle'] = 'unknown'
    elseif (swingAngleValue == 0x01) then
        streams['swing_angle'] = '30'
    elseif (swingAngleValue == 0x02) then
        streams['swing_angle'] = '60'
    elseif (swingAngleValue == 0x03) then
        streams['swing_angle'] = '90'
    elseif (swingAngleValue == 0x04) then
        streams['swing_angle'] = '120'
    elseif (swingAngleValue == 0x05) then
        streams['swing_angle'] = '180'
    elseif (swingAngleValue == 0x06) then
        streams['swing_angle'] = '360'
    end
    if (swingDirectionValue == 0x00) then
        streams['swing_direction '] = 'unknown'
    elseif (swingDirectionValue == 0x02) then
        streams['swing_direction '] = 'up'
    elseif (swingDirectionValue == 0x01) then
        streams['swing_direction '] = 'lr'
    elseif (swingDirectionValue == 0x03) then
        streams['swing_direction '] = 'w'
    elseif (swingDirectionValue == 0x04) then
        streams['swing_direction '] = '8'
    end
    streams['gear'] = gearValue
    streams['error_code'] = errorCode
    if voiceValue == 0x00 then
        streams['voice'] = 'invalid'
    elseif voiceValue == 0x01 then
        streams['voice'] = 'open_gps'
    elseif voiceValue == 0x02 then
        streams['voice'] = 'close_gps'
    elseif voiceValue == 0x04 then
        streams['voice'] = 'open_buzzer'
    elseif voiceValue == 0x08 then
        streams['voice'] = 'close_buzzer'
    elseif voiceValue == 0x05 then
        streams['voice'] = 'open_tip'
    elseif voiceValue == 0x0A then
        streams['voice'] = 'mute'
    end
    if lockValue == 0x00 then
        streams['lock'] = 'invalid'
    elseif lockValue == 0x01 then
        streams['lock'] = 'on'
    elseif lockValue == 0x02 then
        streams['lock'] = 'off'
    end
    if sleepSensor == 0x00 then
        streams['sleep_sensor'] = 'none'
    elseif sleepSensor == 0x01 then
        streams['sleep_sensor'] = 'sleep'
    elseif sleepSensor == 0x02 then
        streams['sleep_sensor'] = 'wake'
    elseif sleepSensor == 0x03 then
        streams['sleep_sensor'] = 'leave'
    elseif sleepSensor == 0xFF then
        streams['sleep_sensor'] = 'invalid'
    end
    if scene == 0x00 then
        streams['scene'] = 'none'
    elseif scene == 0x01 then
        streams['scene'] = 'old'
    elseif scene == 0x02 then
        streams['scene'] = 'child'
    elseif scene == 0x03 then
        streams['scene'] = 'read'
    elseif scene == 0x04 then
        streams['scene'] = 'sleep'
    elseif scene == 0x05 then
        streams['scene'] = 'ac'
    elseif scene == 0xFF then
        streams['scene'] = 'invalid'
    end
    if bodyFeelingScan == 0x00 then
        streams['body_feeling_scan'] = 'off'
    elseif bodyFeelingScan == 0x01 then
        streams['body_feeling_scan'] = 'on'
    elseif bodyFeelingScan == 0xFF then
        streams['body_feeling_scan'] = 'invalid'
    end
    if tempFeedback == 0x00 then
        streams['temperature_feedback'] = 'invalid'
    else
        streams['temperature_feedback'] = int2String(tempFeedback)
    end
    if humFeedback == 0x00 then
        streams['humidify_feedback'] = 'invalid'
    else
        streams['humidify_feedback'] = int2String(humFeedback - 41)
    end
    if anion == 0x00 then
        streams['anion'] = 'invalid'
    elseif anion == 0x01 then
        streams['anion'] = 'on'
    elseif anion == 0x02 then
        streams['anion'] = 'off'
    end
    if anophelifuge == 0x00 then
        streams['anophelifuge'] = 'invalid'
    elseif anophelifuge == 0x01 then
        streams['anophelifuge'] = 'on'
    elseif anophelifuge == 0x02 then
        streams['anophelifuge'] = 'off'
    end
    if humidification == 0x00 then
        streams['humidification'] = 'invalid'
    elseif humidification == 0x01 then
        streams['humidification'] = 'off'
    elseif humidification == 0x02 then
        streams['humidification'] = 'no_change'
    elseif humidification == 0x03 then
        streams['humidification'] = '1'
    elseif humidification == 0x04 then
        streams['humidification'] = '2'
    elseif humidification == 0x05 then
        streams['humidification'] = '3'
    end
    if humidity == 0x00 then
        streams['humidity'] = 'invalid'
    else
        streams['humidity'] = int2String(humidity)
    end
    if temperature == 0x00 then
        streams['temperature'] = 'invalid'
    else
        streams['temperature'] = int2String(humidity - 41)
    end
    streams['timer_off_hour'] = int2String(timerOffHour)
    if timerOffMinuteTen == 0x06 or timerOffMinuteTen == 0x07 then
        streams['timer_off_minute'] = 'clean'
    else
        streams['timer_off_minute'] = timerOffMinuteTen + timerOffMinuteBit
    end
    streams['timer_on_hour'] = int2String(timerOnHour)
    if timerOnMinuteTen == 0x06 or timerOnMinuteTen == 0x07 then
        streams['timer_on_minute'] = 'clean'
    else
        streams['timer_on_minute'] = timerOnMinuteTen + timerOnMinuteBit
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

function quMo(data)
    if (not data) then data = tonumber('0') end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    local result = 0
    result = data % 10
    return result
end

function quChu(data)
    if (not data) then data = tonumber('0') end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    local result = 0
    result = math.modf(data / 10)
    return result
end
