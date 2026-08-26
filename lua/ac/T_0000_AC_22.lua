local JSON = require "cjson"
local KEY_VERSION = "version"
local KEY_POWER = "power"
local KEY_PURIFIER = "purifier"
local KEY_MODE = "mode"
local KEY_TEMPERATURE = "temperature"
local KEY_FANSPEED = "wind_speed"
local KEY_SWING_LR = "wind_swing_lr"
local KEY_SWING_UD = "wind_swing_ud"
local KEY_TIME_ON = "power_on_timer"
local KEY_TIME_OFF = "power_off_timer"
local KEY_CLOSE_TIME = "power_off_time_value"
local KEY_OPEN_TIME = "power_on_time_value"
local KEY_ECO = "eco"
local KEY_DRY = "dry"
local KEY_PTC = "ptc"
local KEY_ERROR_CODE = "error_code"
local KEY_BUZZER = "buzzer"

local VALUE_VERSION = 22
local VALUE_FUNCTION_ON = "on"
local VALUE_FUNCTION_OFF = "off"
local VALUE_MODE_HEAT = "heat"
local VALUE_MODE_COOL = "cool"
local VALUE_MODE_AUTO = "auto"
local VALUE_MODE_DRY = "dry"
local VALUE_MODE_FAN = "fan"
local VALUE_INDOOR_TEMPERATURE = "indoor_temperature"
local VALUE_OUTDOOR_TEMPERATURE = "outdoor_temperature"
local VALUE_RUN_STATE = "runstate"
local VALUE_RUNNING = "running"
local VALUE_STOP = "stopped"

local deviceSubType = 0
local deviceSN8 = "00000000"

local BYTE_DEVICE_TYPE = 0xAC
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERYL_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local BYTE_MODE_AUTO = 0x20
local BYTE_MODE_COOL = 0x40
local BYTE_MODE_DRY = 0x60
local BYTE_MODE_HEAT = 0x80
local BYTE_MODE_FAN = 0xA0
local BYTE_FANSPEED_AUTO = 0x66
local BYTE_FANSPEED_HIGH = 0x50
local BYTE_FANSPEED_MID = 0x3C
local BYTE_FANSPEED_LOW = 0x28
local BYTE_FANSPEED_MUTE = 0x14
local BYTE_PURIFIER_ON = 0x20
local BYTE_PURIFIER_OFF = 0x00
local BYTE_ECO_ON = 0x80
local BYTE_ECO_OFF = 0x00
local BYTE_SWING_LR_ON = 0x03
local BYTE_SWING_LR_OFF = 0x00
local BYTE_SWING_UD_ON = 0x0C
local BYTE_SWING_UD_OFF = 0x00
local BYTE_DRY_ON = 0x04
local BYTE_DRY_OFF = 0x00
local BYTE_BUZZER_ON = 0x40
local BYTE_BUZZER_OFF = 0x00
local BYTE_CONTROL_CMD = 0x40
local BYTE_TIMER_METHOD_REL = 0x00
local BYTE_TIMER_METHOD_ABS = 0x01
local BYTE_TIMER_METHOD_DISABLE = 0x7F
local BYTE_CLIENT_MODE_MOBILE = 0x02
local BYTE_TIMER_SWITCH_ON = 0x80
local BYTE_TIMER_SWITCH_OFF = 0x00
local BYTE_CLOSE_TIMER_SWITCH_ON = 0x80
local BYTE_CLOSE_TIMER_SWITCH_OFF = 0x7F
local BYTE_START_TIMER_SWITCH_ON = 0x80
local BYTE_START_TIMER_SWITCH_OFF = 0x7F
local BYTE_PTC_ON = 0x08
local BYTE_PTC_OFF = 0x00
local BYTE_STRONG_WIND_ON = 0x20
local BYTE_STRONG_WIND_OFF = 0x00
local BYTE_SLEEP_ON = 0x03
local BYTE_SLEEP_OFF = 0x00

local powerValue = 0
local modeValue = 0
local temperatureValue = 0
local fanspeedValue = 0
local closeTimerSwitch = 0
local openTimerSwitch = 0
local closeHour = 0
local closeStepMintues = 0
local closeMin = 0
local closeTime = 0
local openHour = 0
local openStepMintues = 0
local openMin = 0
local openTime = 0
local strongWindValue = 0
local comfortableSleepValue = 0
local PTCValue = 0
local purifierValue = 0
local ecoValue = 0
local dryValue = 0
local swingLRValue = 0
local swingUDValue = 0
local indoorTemperatureValue = 255
local outdoorTemperatureValue = 255
local errorCode = 0
local smallTemperature = 0
local buzzerValue = 0x40
local kickQuilt = 0
local preventCold = 0
local dataType = 0

function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams[KEY_POWER] == VALUE_FUNCTION_ON) then
        powerValue = BYTE_POWER_ON
        openTimerSwitch = BYTE_START_TIMER_SWITCH_OFF
        closeTimerSwitch = BYTE_CLOSE_TIMER_SWITCH_OFF
        PTCValue = BYTE_PTC_ON
        fanspeedValue = BYTE_FANSPEED_AUTO
    elseif (streams[KEY_POWER] == VALUE_FUNCTION_OFF) then
        powerValue = BYTE_POWER_OFF
        openTimerSwitch = BYTE_START_TIMER_SWITCH_OFF
        closeTimerSwitch = BYTE_CLOSE_TIMER_SWITCH_OFF
        PTCValue = BYTE_PTC_ON
        fanspeedValue = BYTE_FANSPEED_AUTO
    end
    if (streams[KEY_BUZZER] == VALUE_FUNCTION_ON) then
        buzzerValue = BYTE_BUZZER_ON
    elseif (streams[KEY_BUZZER] == VALUE_FUNCTION_OFF) then
        buzzerValue = BYTE_BUZZER_OFF
    end
    if (streams[KEY_PURIFIER] == VALUE_FUNCTION_ON) then
        purifierValue = BYTE_PURIFIER_ON
    elseif (streams[KEY_PURIFIER] == VALUE_FUNCTION_OFF) then
        purifierValue = BYTE_PURIFIER_OFF
    end
    if (streams[KEY_ECO] == VALUE_FUNCTION_ON) then
        ecoValue = BYTE_ECO_ON
    elseif (streams[KEY_ECO] == VALUE_FUNCTION_OFF) then
        ecoValue = BYTE_ECO_OFF
    end
    if (streams[KEY_DRY] == VALUE_FUNCTION_ON) then
        dryValue = BYTE_DRY_ON
    elseif (streams[KEY_DRY] == VALUE_FUNCTION_OFF) then
        dryValue = BYTE_DRY_OFF
    end
    if (streams[KEY_MODE] == VALUE_MODE_HEAT) then
        modeValue = BYTE_MODE_HEAT
        PTCValue = BYTE_PTC_ON
    elseif (streams[KEY_MODE] == VALUE_MODE_COOL) then
        modeValue = BYTE_MODE_COOL
    elseif (streams[KEY_MODE] == VALUE_MODE_AUTO) then
        modeValue = BYTE_MODE_AUTO
        PTCValue = BYTE_PTC_ON
    elseif (streams[KEY_MODE] == VALUE_MODE_DRY) then
        modeValue = BYTE_MODE_DRY
    elseif (streams[KEY_MODE] == VALUE_MODE_FAN) then
        modeValue = BYTE_MODE_FAN
    end
    if (streams[KEY_FANSPEED] ~= nil) then
        fanspeedValue = checkBoundary(streams[KEY_FANSPEED], 1, 102)
    end
    if (streams[KEY_SWING_UD] == VALUE_FUNCTION_ON) then
        swingUDValue = BYTE_SWING_UD_ON
    elseif (streams[KEY_SWING_UD] == VALUE_FUNCTION_OFF) then
        swingUDValue = BYTE_SWING_UD_OFF
    end
    if (streams[KEY_SWING_LR] == VALUE_FUNCTION_ON) then
        swingLRValue = BYTE_SWING_LR_ON
    elseif (streams[KEY_SWING_LR] == VALUE_FUNCTION_OFF) then
        swingLRValue = BYTE_SWING_LR_OFF
    end
    if (streams[KEY_TIME_ON] == VALUE_FUNCTION_ON) then
        openTimerSwitch = BYTE_START_TIMER_SWITCH_ON
    elseif (streams[KEY_TIME_ON] == VALUE_FUNCTION_OFF) then
        openTimerSwitch = BYTE_START_TIMER_SWITCH_OFF
    end
    if (streams[KEY_TIME_OFF] == VALUE_FUNCTION_ON) then
        closeTimerSwitch = BYTE_CLOSE_TIMER_SWITCH_ON
    elseif (streams[KEY_TIME_OFF] == VALUE_FUNCTION_OFF) then
        closeTimerSwitch = BYTE_CLOSE_TIMER_SWITCH_OFF
    end
    if (streams[KEY_CLOSE_TIME] ~= nil) then
        closeTime = streams[KEY_CLOSE_TIME]
    end
    if (streams[KEY_OPEN_TIME] ~= nil) then openTime = streams[KEY_OPEN_TIME] end
    if (streams[KEY_PTC] == VALUE_FUNCTION_ON) then
        PTCValue = BYTE_PTC_ON
    elseif (streams[KEY_PTC] == VALUE_FUNCTION_OFF) then
        PTCValue = BYTE_PTC_OFF
    end
    if (streams[KEY_TEMPERATURE] ~= nil) then
        temperatureValue = checkBoundary(streams[KEY_TEMPERATURE], 17, 30)
    end
    if (streams["small_temperature"] ~= nil) then
        smallTemperature = checkBoundary(streams["small_temperature"], 0, 0.5)
        if (smallTemperature == 0.5) then
            smallTemperature = 0x01
        else
            smallTemperature = 0x00
        end
    end
end

function binToModel(binData)
    if (#binData < 21) then return nil end
    local messageBytes = binData
    if ((dataType == 0x02 and messageBytes[0] == 0xC0) or
        (dataType == 0x03 and messageBytes[0] == 0xC0) or
        (dataType == 0x05 and messageBytes[0] == 0xA0)) then
        powerValue = bit.band(messageBytes[1], 0x01)
        modeValue = bit.band(messageBytes[2], 0xE0)
        if (dataType == 0x05) then
            if deviceSN8 == "11447" or deviceSN8 == "11451" or deviceSN8 ==
                "11453" or deviceSN8 == "11455" or deviceSN8 == "11457" or
                deviceSN8 == "11459" or deviceSN8 == "11525" or deviceSN8 ==
                "11527" or deviceSN8 == "11533" or deviceSN8 == "11535" then
                temperatureValue =
                    bit.rshift(bit.band(messageBytes[1], 0x7C), 2) + 0x0C
                smallTemperature =
                    bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            else
                temperatureValue =
                    bit.rshift(bit.band(messageBytes[1], 0x3E), 1) + 0x0C
                smallTemperature =
                    bit.rshift(bit.band(messageBytes[1], 0x40), 6)
            end
        else
            temperatureValue = bit.band(messageBytes[2], 0x0F) + 0x10
            smallTemperature = bit.rshift(bit.band(messageBytes[2], 0x10), 4)
        end
        fanspeedValue = bit.band(messageBytes[3], 0x7F)
        if (bit.band(messageBytes[4], BYTE_START_TIMER_SWITCH_ON) ==
            BYTE_START_TIMER_SWITCH_ON) then
            openTimerSwitch = BYTE_START_TIMER_SWITCH_ON
        else
            openTimerSwitch = BYTE_START_TIMER_SWITCH_OFF
        end
        if (bit.band(messageBytes[5], BYTE_CLOSE_TIMER_SWITCH_ON) ==
            BYTE_CLOSE_TIMER_SWITCH_ON) then
            closeTimerSwitch = BYTE_CLOSE_TIMER_SWITCH_ON
        else
            closeTimerSwitch = BYTE_CLOSE_TIMER_SWITCH_OFF
        end
        closeHour = bit.rshift(bit.band(messageBytes[5], 0x7F), 2)
        closeStepMintues = bit.band(messageBytes[5], 0x03)
        closeMin = 15 - bit.band(messageBytes[6], 0x0f)
        closeTime = closeHour * 60 + closeStepMintues * 15 + closeMin
        openHour = bit.rshift(bit.band(messageBytes[4], 0x7F), 2)
        openStepMintues = bit.band(messageBytes[4], 0x03)
        openMin = 15 - bit.rshift(bit.band(messageBytes[6], 0xf0), 4)
        openTime = openHour * 60 + openStepMintues * 15 + openMin
        strongWindValue = bit.band(messageBytes[8], 0x20)
        comfortableSleepValue = bit.band(messageBytes[8], 0x03)
        PTCValue = bit.band(messageBytes[9], 0x18)
        purifierValue = bit.band(messageBytes[9], 0x20)
        ecoValue = bit.lshift(bit.band(messageBytes[9], 0x10), 3)
        dryValue = bit.band(messageBytes[9], 0x04)
        swingLRValue = bit.band(messageBytes[7], 0x03)
        swingUDValue = bit.band(messageBytes[7], 0x0C)
        if (dataType == 0x02 or dataType == 0x03) then
            if ((messageBytes[11] ~= 0) and (messageBytes[11] ~= 0xFF)) then
                indoorTemperatureValue = (messageBytes[11] - 50) / 2
            end
            if ((messageBytes[12] ~= 0) and (messageBytes[12] ~= 0xFF)) then
                outdoorTemperatureValue = (messageBytes[12] - 50) / 2
            end
        end
        errorCode = messageBytes[16]
        kickQuilt = bit.rshift(bit.band(messageBytes[10], 0x04), 2)
        preventCold = bit.rshift(bit.band(messageBytes[10], 0x08), 3)
    end
    if ((dataType == 0x04 and messageBytes[0] == 0xA1)) then
        if (messageBytes[13] ~= 0x00 and messageBytes[13] ~= 0xff) then
            indoorTemperatureValue = (messageBytes[13] - 50) / 2
        end
        if (messageBytes[14] ~= 0x00 and messageBytes[14] ~= 0xff) then
            outdoorTemperatureValue = (messageBytes[14] - 50) / 2
        end
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local infoM = {}
    local bodyBytes = {}
    local json = decode(jsonCmd)
    deviceSubType = json["deviceinfo"]["deviceSubType"]
    local deviceSN = json["deviceinfo"]["deviceSN"]
    if deviceSN ~= nil then deviceSN8 = string.sub(deviceSN, 13, 17) end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (query) then
        for i = 0, 21 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0x41
        bodyBytes[1] = 0x81
        bodyBytes[3] = 0xFF
        math.randomseed(tostring(os.time()):reverse():sub(2, 7))
        bodyBytes[20] = math.random(1, 254)
        bodyBytes[21] = crc8_854(bodyBytes, 0, 20)
        infoM = getTotalMsg(bodyBytes, BYTE_QUERYL_REQUEST)
    elseif (control) then
        if (status) then jsonToModel(status) end
        if (control) then jsonToModel(control) end
        for i = 0, 25 do bodyBytes[i] = 0 end
        bodyBytes[0] = BYTE_CONTROL_CMD
        bodyBytes[1] = bit.bor(bit.bor(powerValue, BYTE_CLIENT_MODE_MOBILE),
                               bit.bor(BYTE_TIMER_METHOD_REL, buzzerValue))
        bodyBytes[2] = bit.bor(
                           bit.bor(bit.band(modeValue, 0xE0),
                                   bit.band(0x0F, (temperatureValue - 0x10))),
                           bit.band(smallTemperature, 0x10))
        bodyBytes[3] = bit.bor(fanspeedValue, BYTE_TIMER_SWITCH_ON)
        if (closeTime == nil) then closeTime = 0 end
        closeHour = math.floor(closeTime / 60)
        closeStepMintues = math.floor((closeTime % 60) / 15)
        closeMin = math.floor(((closeTime % 60) % 15))
        if (openTime == nil) then openTime = 0 end
        openHour = math.floor(openTime / 60)
        openStepMintues = math.floor((openTime % 60) / 15)
        openMin = math.floor(((openTime % 60) % 15))
        if (openTimerSwitch == BYTE_START_TIMER_SWITCH_ON) then
            bodyBytes[4] = bit.bor(bit.bor(openTimerSwitch,
                                           bit.lshift(openHour, 2)),
                                   openStepMintues)
        elseif (openTimerSwitch == BYTE_START_TIMER_SWITCH_OFF) then
            bodyBytes[4] = 0x7F
        end
        if (closeTimerSwitch == BYTE_CLOSE_TIMER_SWITCH_ON) then
            bodyBytes[5] = bit.bor(bit.bor(closeTimerSwitch,
                                           bit.lshift(closeHour, 2)),
                                   closeStepMintues)
        elseif (closeTimerSwitch == BYTE_CLOSE_TIMER_SWITCH_OFF) then
            bodyBytes[5] = 0x7F
        end
        bodyBytes[6] = bit.bor(bit.lshift((15 - openMin), 4), (15 - closeMin))
        bodyBytes[7] = bit.bor(bit.bor(swingLRValue, swingUDValue), 0x30)
        bodyBytes[8] = bit.bor(strongWindValue, comfortableSleepValue)
        bodyBytes[9] = bit.bor(bit.bor(purifierValue, ecoValue),
                               bit.bor(dryValue, PTCValue))
        math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        bodyBytes[24] = math.random(1, 254)
        bodyBytes[25] = crc8_854(bodyBytes, 0, 24)
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
    local deviceinfo = json["deviceinfo"]
    deviceSubType = deviceinfo["deviceSubType"]
    local deviceSN = json["deviceinfo"]["deviceSN"]
    if deviceSN ~= nil then deviceSN8 = string.sub(deviceSN, 13, 17) end
    local status = json["status"]
    if (status) then jsonToModel(status) end
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[10];
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
        streams[KEY_POWER] = VALUE_FUNCTION_ON
    elseif (powerValue == BYTE_POWER_OFF) then
        streams[KEY_POWER] = VALUE_FUNCTION_OFF
    end
    if (modeValue == BYTE_MODE_HEAT) then
        streams[KEY_MODE] = VALUE_MODE_HEAT
    elseif (modeValue == BYTE_MODE_COOL) then
        streams[KEY_MODE] = VALUE_MODE_COOL
    elseif (modeValue == BYTE_MODE_AUTO) then
        streams[KEY_MODE] = VALUE_MODE_AUTO
    elseif (modeValue == BYTE_MODE_DRY) then
        streams[KEY_MODE] = VALUE_MODE_DRY
    elseif (modeValue == BYTE_MODE_FAN) then
        streams[KEY_MODE] = VALUE_MODE_FAN
    end
    if (purifierValue == BYTE_PURIFIER_ON) then
        streams[KEY_PURIFIER] = VALUE_FUNCTION_ON
    elseif (purifierValue == BYTE_PURIFIER_OFF) then
        streams[KEY_PURIFIER] = VALUE_FUNCTION_OFF
    end
    if (ecoValue == BYTE_ECO_ON) then
        streams[KEY_ECO] = VALUE_FUNCTION_ON
    elseif (ecoValue == BYTE_ECO_OFF) then
        streams[KEY_ECO] = VALUE_FUNCTION_OFF
    end
    if (dryValue == BYTE_DRY_ON) and
        ((modeValue == BYTE_MODE_COOL) or (modeValue == BYTE_MODE_DRY)) then
        streams[KEY_DRY] = VALUE_FUNCTION_ON
    else
        streams[KEY_DRY] = VALUE_FUNCTION_OFF
    end
    streams[KEY_FANSPEED] = fanspeedValue
    streams[VALUE_OUTDOOR_TEMPERATURE] = outdoorTemperatureValue
    streams[VALUE_INDOOR_TEMPERATURE] = indoorTemperatureValue
    if (swingUDValue == BYTE_SWING_UD_ON) then
        streams[KEY_SWING_UD] = VALUE_FUNCTION_ON
    elseif (swingUDValue == BYTE_SWING_UD_OFF) then
        streams[KEY_SWING_UD] = VALUE_FUNCTION_OFF
    end
    if (swingLRValue == BYTE_SWING_LR_ON) then
        streams[KEY_SWING_LR] = VALUE_FUNCTION_ON
    elseif (swingLRValue == BYTE_SWING_LR_OFF) then
        streams[KEY_SWING_LR] = VALUE_FUNCTION_OFF
    end
    if (PTCValue == BYTE_PTC_ON) and
        ((modeValue == BYTE_MODE_AUTO) or (modeValue == BYTE_MODE_HEAT)) then
        streams[KEY_PTC] = VALUE_FUNCTION_ON
    elseif (PTCValue == BYTE_PTC_OFF) then
        streams[KEY_PTC] = VALUE_FUNCTION_OFF
    end
    if (openTimerSwitch == BYTE_START_TIMER_SWITCH_ON) then
        streams[KEY_TIME_ON] = VALUE_FUNCTION_ON
    elseif (openTimerSwitch == BYTE_START_TIMER_SWITCH_OFF) then
        streams[KEY_TIME_ON] = VALUE_FUNCTION_OFF
    end
    if (closeTimerSwitch == BYTE_CLOSE_TIMER_SWITCH_ON) then
        streams[KEY_TIME_OFF] = VALUE_FUNCTION_ON
    elseif (closeTimerSwitch == BYTE_CLOSE_TIMER_SWITCH_OFF) then
        streams[KEY_TIME_OFF] = VALUE_FUNCTION_OFF
    end
    if (closeTimerSwitch == BYTE_CLOSE_TIMER_SWITCH_OFF) then
        streams[KEY_CLOSE_TIME] = 0
    else
        streams[KEY_CLOSE_TIME] = closeTime
    end
    if (openTimerSwitch == BYTE_START_TIMER_SWITCH_OFF) then
        streams[KEY_OPEN_TIME] = 0
    else
        streams[KEY_OPEN_TIME] = openTime
    end
    streams[KEY_TEMPERATURE] = temperatureValue
    if (smallTemperature == 0x01) then
        streams["small_temperature"] = 0.5
    else
        streams["small_temperature"] = 0
    end
    streams[KEY_ERROR_CODE] = errorCode
    if (kickQuilt == 0x00) then
        streams["kick_quilt"] = "off"
    elseif (kickQuilt == 0x01) then
        streams["kick_quilt"] = "on"
    end
    if (preventCold == 0x00) then
        streams["prevent_cold"] = "off"
    elseif (preventCold == 0x01) then
        streams["prevent_cold"] = "on"
    end
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
