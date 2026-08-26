local bit = require "bit"
local uptable = {}
local JSON = require "cjson"
local bit = require("bit")
local VALUE_VERSION = 4
local KEY_VERSION = "version"
local function ENUM_WIND_SPEED_TAB(deviceSubType)
    if deviceSubType then
        if deviceSubType > 0 and deviceSubType < 6 then
            return {
                [0x7f] = "off",
                [1] = "lowest",
                [0x28] = "low",
                [0x3c] = "middle",
                [0x50] = "high",
                [0x66] = "auto"
            }
        end
    end
    return {
        [0x7f] = "off",
        [1] = "lowest",
        [0x27] = "low",
        [0x3b] = "middle",
        [0x50] = "high",
        [0x65] = "auto"
    }
end
local ENUM_MODE_TAB = {
    "manual",
    "auto",
    "continue",
    "parlour",
    "bedroom",
    "kitchen",
    "sleep",
    "moist_skin",
    [0] = "invalid"
}
local ENUM_BRIGHT_TAB = {[0] = "light", [6] = "dark", [7] = "exit"}
local ENUM_LIGHT_COLOR_TAB = {
    "off",
    "red",
    "green",
    "blue",
    "warm",
    [0] = "invalid"
}
uptable["BYTE_DEVICE_TYPE"] = 0xFD
uptable["BYTE_CONTROL_REQUEST"] = 0x02
uptable["BYTE_QUERY_REQUEST"] = 0x03
uptable["BYTE_PROTOCOL_HEAD"] = 0xAA
uptable["BYTE_PROTOCOL_LENGTH"] = 0x0A
uptable["BYTE_FANSPEED_LOW"] = 0x28
uptable["BYTE_FANSPEED_LOW_2"] = 0x27
uptable["BYTE_FANSPEED_MID"] = 0x3C
uptable["BYTE_FANSPEED_MID_2"] = 0x3B
uptable["BYTE_FANSPEED_HIGH"] = 0x50
uptable["BYTE_FANSPEED_AUTO"] = 0x66
uptable["BYTE_FANSPEED_AUTO_2"] = 0x65
uptable["BYTE_FANSPEED_OFF"] = 0x7F
uptable["BYTE_FANSPEED_LOWEST"] = 0x01
uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON"] = 0x80
uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_OFF"] = 0x7F
uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_ON"] = 0x80
uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_OFF"] = 0x7F
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
local function string2Int(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end
local function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = "0" end
    return data
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
local function getIndexFromValueTab(table, value, defaultIndex)
    for k, v in pairs(table) do if value == v then return k end end
    if defaultIndex then return defaultIndex end
    return nil
end
local function getValueFromValueTab(table, index, defaultValue)
    for k, v in pairs(table) do if index == k then return v end end
    if defaultValue then return defaultValue end
    return nil
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
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
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end
local function jsonToModel(jsonCmd, subType, modelResult)
    local s = jsonCmd
    if s.power then modelResult.powerValue = s.power == "on" and 1 or 0 end
    if s.wind_speed then
        modelResult.fanspeedValue = getIndexFromValueTab(
                                        ENUM_WIND_SPEED_TAB(subType),
                                        s.wind_speed, 0)
    end
    if s.humidity then modelResult.setHumidityValue = tonumber(s.humidity) end
    if s.humidity_mode then
        modelResult.humidityMode = getIndexFromValueTab(ENUM_MODE_TAB,
                                                        s.humidity_mode, 0)
    end
    if s.bright_led then
        modelResult.brightLED = getIndexFromValueTab(ENUM_BRIGHT_TAB,
                                                     s.bright_led, 0)
    end
    if s.display_on_off then
        modelResult.displayOnOffValue = s.display_on_off == "on" and 1 or
                                            s.display_on_off == "off" and 2 or 0
    end
    modelResult.setTimerFlag = false
    if s.power_off_timer then
        modelResult.scheduleCloseSwitcher =
            s.power_off_timer == "on" and true or false
        modelResult.setTimerFlag = true
    end
    if s.time_off then
        modelResult.scheduleCloseTime = tonumber(s.time_off)
        modelResult.setTimerFlag = true
    end
    if s.power_on_timer then
        modelResult.scheduleOpenSwitcher =
            s.power_on_timer == "on" and true or false
        modelResult.setTimerFlag = true
    end
    if s.time_on then
        modelResult.scheduleOpenTime = tonumber(s.time_on)
        modelResult.setTimerFlag = true
    end
    if s.disinfect_on_off then
        modelResult.disinfectOnOffValue =
            s.disinfect_on_off == "on" and 1 or s.disinfect_on_off == "off" and
                2 or 0
    end
    if s.netIons_on_off then
        modelResult.netIonsOnOffValue = s.netIons_on_off == "on" and 1 or 0
    end
    if s.airDry_on_off then
        modelResult.airDryOnOffValue = s.airDry_on_off == "on" and 1 or
                                           s.airDry_on_off == "off" and 2 or 0
    end
    if s.wind_gear then
        modelResult.windGearValue = getIndexFromValueTab(
                                        ENUM_WIND_SPEED_TAB(subType),
                                        s.wind_gear, 0)
    end
    if s.buzzer then modelResult.buzzerValue = s.buzzer == "on" and 1 or 0 end
    if s.light_color then
        modelResult.lightColorValue = getIndexFromValueTab(ENUM_LIGHT_COLOR_TAB,
                                                           s.light_color, 0)
    end
    return modelResult
end
local function jsonToModelByStatus(jsonCmd, subType)
    local modelResult = {}
    local s = jsonCmd
    modelResult.powerValue = s.power == "on" and 1 or 0
    modelResult.fanspeedValue = 0
    if (subType < 8 and subType ~= 0) then
        modelResult.fanspeedValue = getIndexFromValueTab(
                                        ENUM_WIND_SPEED_TAB(subType),
                                        s.wind_speed, 0x7f)
    end
    if s.humidity then modelResult.setHumidityValue = s.humidity end
    modelResult.humidityMode = 0
    if (subType < 8 and subType ~= 0) then
        modelResult.humidityMode = getIndexFromValueTab(ENUM_MODE_TAB,
                                                        s.humidity_mode, 0)
    end
    if s.bright_led then
        modelResult.brightLED = getIndexFromValueTab(ENUM_BRIGHT_TAB,
                                                     s.bright_led, 0)
    end
    if s.display_on_off then
        modelResult.displayOnOffValue = s.display_on_off == "on" and 1 or
                                            s.display_on_off == "off" and 2 or 0
    end
    if s.disinfect_on_off then
        modelResult.disinfectOnOffValue =
            s.disinfect_on_off == "on" and 1 or s.disinfect_on_off == "off" and
                2 or 0
    end
    if s.netIons_on_off then
        modelResult.netIonsOnOffValue = s.netIons_on_off == "on" and 1 or 0
    end
    if s.airDry_on_off then
        modelResult.airDryOnOffValue = s.airDry_on_off == "on" and 1 or
                                           s.airDry_on_off == "off" and 2 or 0
    end
    modelResult.windGearValue = 0
    uptable["windGearValue"] = 0
    if (subType < 8 and subType ~= 0) then
        modelResult.windGearValue = getIndexFromValueTab(
                                        ENUM_WIND_SPEED_TAB(subType),
                                        s.wind_gear, 0)
    end
    if s.buzzer then modelResult.buzzerValue = s.buzzer == "on" and 1 or 0 end
    return modelResult
end
local function binToModel(binData)
    local modelResult = {}
    if (#binData == 0) then return nil end
    local messageBytes = binData
    local sub_cmd = messageBytes[0]
    modelResult.powerValue = bit.band(messageBytes[1], 0x01)
    modelResult.addWaterFlag = bit.rshift(bit.band(messageBytes[1], 0x0C), 2)
    modelResult.lightColorValue = bit.band(messageBytes[2], 0x0F)
    modelResult.fanspeedValue = bit.band(messageBytes[3], 0x7F)
    modelResult.setHumidityValue = messageBytes[7]
    modelResult.currentHumidityValue = messageBytes[16]
    modelResult.currentTemperatureValue = (messageBytes[17] - 50) / 2
    modelResult.tankStatusValue = messageBytes[10]
    modelResult.buzzerValue = bit.band(messageBytes[19], 0x80) == 0x80 and 1 or
                                  0
    modelResult.errorCode = messageBytes[21]
    modelResult.brightLED = bit.band(messageBytes[9], 0x07)
    if (bit.band(messageBytes[5], 0x80) == 0x80) then
        modelResult.scheduleCloseSwitcher = true
    else
        modelResult.scheduleCloseSwitcher = false
    end
    local timingOffMul15 = bit.band(messageBytes[5], 0x7F)
    local timingOffLeft15 = bit.band(messageBytes[6], 0x0F)
    modelResult.scheduleCloseTime = timingOffMul15 * 15 + (15 - timingOffLeft15)
    if (bit.band(messageBytes[4], 0x80) == 0x80) then
        modelResult.scheduleOpenSwitcher = true
    else
        modelResult.scheduleOpenSwitcher = false
    end
    local timingOnMul15 = bit.band(messageBytes[4], 0x7F)
    local timingOnLeft15 = bit.rshift(bit.band(messageBytes[6], 0xf0), 4)
    modelResult.scheduleOpenTime = timingOnMul15 * 15 + (15 - timingOnLeft15)
    if #messageBytes >= 33 then
        modelResult.runningPercentValue = messageBytes[30]
    end
    modelResult.humidityMode = messageBytes[13]
    if #messageBytes >= 22 then
        modelResult.netIonsOnOffValue = bit.rshift(
                                            bit.band(messageBytes[19], 0x40), 6)
    end
    if #messageBytes >= 37 then
        modelResult.disinfectOnOffValue = bit.band(messageBytes[34], 0x03)
    end
    if #messageBytes >= 41 then modelResult.windGearValue = messageBytes[39] end
    if #messageBytes >= 44 then
        modelResult.airDryOnOffValue = bit.rshift(
                                           bit.band(messageBytes[42], 0x30), 4)
    end
    if #messageBytes >= 45 then
        modelResult.displayOnOffValue = bit.band(messageBytes[43], 0x03)
    end
    return modelResult
end
local function makeSetBTMacOrder(control)
    local msgBytes = {}
    local msgLength = 13 + control["btCount"] * 6
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = 0xAA
    msgBytes[1] = msgLength
    msgBytes[2] = 0xFD
    msgBytes[8] = 0;
    msgBytes[9] = 2;
    msgBytes[10] = 0x0c;
    msgBytes[11] = control["btCount"]
    local macs = control["btMacs"]
    local j = 0
    local k = 0
    for i = 1, msgBytes[11] do
        msgBytes[k + 17] = tonumber(string.sub(macs, j + 1, j + 2), 16)
        msgBytes[k + 16] = tonumber(string.sub(macs, j + 3, j + 4), 16)
        msgBytes[k + 15] = tonumber(string.sub(macs, j + 5, j + 6), 16)
        msgBytes[k + 14] = tonumber(string.sub(macs, j + 7, j + 8), 16)
        msgBytes[k + 13] = tonumber(string.sub(macs, j + 9, j + 10), 16)
        msgBytes[k + 12] = tonumber(string.sub(macs, j + 11, j + 12), 16)
        k = k + 6
        j = j + 13
    end
    msgBytes[msgLength - 1] = crc8_854(msgBytes, 10, msgLength - 2)
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local infoM = {}
    for i = 1, msgLength + 1 do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local infoM = {}
    local bodyBytes = {}
    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if deviceSubType == nil then
        deviceSubType = 0
    else
        if type(deviceSubType) == "string" then
            deviceSubType = tonumber(deviceSubType)
        end
    end
    if (deviceSubType > 5 or deviceSubType == 0) then
        uptable["BYTE_FANSPEED_MID"] = 0x3B
        uptable["BYTE_FANSPEED_LOW"] = 0x27
        uptable["BYTE_FANSPEED_AUTO"] = 0x65
    end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    local model = {}
    local bodyLength = 0
    local msgBytes = {}
    if (query) then
        if query["type"] ~= nil and query["type"] == "btMac" then
            bodyLength = 1
        else
            bodyLength = 21
        end
    elseif (control) then
        bodyLength = 26
    end
    local msgLength = bodyLength + uptable["BYTE_PROTOCOL_LENGTH"] + 1
    for i = 0, bodyLength do bodyBytes[i] = 0 end
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = uptable["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = bodyLength + uptable["BYTE_PROTOCOL_LENGTH"] + 1
    msgBytes[2] = uptable["BYTE_DEVICE_TYPE"]
    if (query) then
        msgBytes[9] = uptable["BYTE_QUERY_REQUEST"]
        if query["type"] ~= nil and query["type"] == "btMac" then
            bodyBytes[0] = 0x0C
            bodyBytes[bodyLength] = crc8_854(bodyBytes, 0, bodyLength - 1)
        else
            bodyBytes[0] = 0x41
            bodyBytes[1] = 0x81
            bodyBytes[3] = 0xFF
            bodyBytes[4] = 0x03
            bodyBytes[7] = 0x02
            math.randomseed(os.time())
            bodyBytes[20] = math.random(1, 254)
            bodyBytes[bodyLength] = crc8_854(bodyBytes, 0, bodyLength - 1)
        end
    elseif (control) then
        if control["setBtMacs"] ~= nil then
            return makeSetBTMacOrder(control)
        end
        if (status) then
            model = jsonToModelByStatus(status, deviceSubType)
        end
        if (control) then
            model = jsonToModel(control, deviceSubType, model)
        end
        bodyBytes[0] = 0x48
        if (model.powerValue ~= nil) then
            bodyBytes[1] = bit.bor(model.powerValue, 0x42)
        end
        if control.silence_ctrl ~= nil and control.silence_ctrl == "enable" then
            bodyBytes[1] = bit.bor(bodyBytes[1], 0x04)
        end
        if model.lightColorValue ~= nil then
            bodyBytes[2] = model.lightColorValue
        end
        if (model.fanspeedValue ~= nil) then
            bodyBytes[3] = model.fanspeedValue
        end
        if model.setTimerFlag == true then
            bodyBytes[3] = bit.bor(bodyBytes[3], 0x80)
            local timingOffValue = model.scheduleCloseTime ~= nil and
                                       model.scheduleCloseTime or 0
            local timingOffMul15 = math.floor(timingOffValue / 15)
            local timingOffLeft15 = 15 - (timingOffValue % 15)
            if model.scheduleCloseSwitcher == true then
                bodyBytes[5] = bit.bor(
                                   uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_ON"],
                                   timingOffMul15)
            else
                bodyBytes[5] = bit.bor(
                                   uptable["BYTE_SCHEDULE_CLOSE_TIME_SWITCHER_OFF"],
                                   timingOffMul15)
            end
            bodyBytes[6] = bit.bor(bodyBytes[6], timingOffLeft15)
            if timingOffValue == 1920 then
                bodyBytes[5] = 0x7F
                bodyBytes[6] = bit.band(bodyBytes[6], 0xF0)
            end
            local timingOnValue = model.scheduleOpenTime ~= nil and
                                      model.scheduleOpenTime or 0
            local timingOnMul15 = math.floor(timingOnValue / 15)
            local timingOnLeft15 = 15 - (timingOnValue % 15)
            if model.scheduleOpenSwitcher == true then
                bodyBytes[4] = bit.bor(
                                   uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_ON"],
                                   timingOnMul15)
            else
                bodyBytes[4] = bit.bor(
                                   uptable["BYTE_SCHEDULE_OPEN_TIME_SWITCHER_OFF"],
                                   timingOnMul15)
            end
            bodyBytes[6] = bit.bor(bodyBytes[6], bit.lshift(timingOnLeft15, 4))
            if timingOnValue == 1920 then
                bodyBytes[4] = 0x7F
                bodyBytes[6] = bit.band(bodyBytes[6], 0x0F)
            end
        end
        if (model.setHumidityValue ~= nil) then
            bodyBytes[7] = model.setHumidityValue
        end
        if (model["brightLED"] ~= nil) then
            bodyBytes[9] = model["brightLED"]
        end
        if (model["humidityMode"] ~= nil) then
            bodyBytes[11] = model["humidityMode"]
        end
        if (model["buzzerValue"] ~= nil) then
            bodyBytes[10] = bit.bor(bodyBytes[10],
                                    model["buzzerValue"] == 1 and 0x40 or 0)
        end
        if model["disinfectOnOffValue"] ~= nil then
            bodyBytes[15] = model["disinfectOnOffValue"]
        end
        if model.displayOnOffValue ~= nil then
            bodyBytes[15] = bit.lshift(model.displayOnOffValue, 6) +
                                bodyBytes[15]
        end
        if model["netIonsOnOffValue"] ~= nil then
            bodyBytes[10] = bit.bor(bodyBytes[10],
                                    bit.lshift(model["netIonsOnOffValue"], 5))
        end
        if model["airDryOnOffValue"] ~= nil then
            bodyBytes[21] = model["airDryOnOffValue"]
        end
        if model["windGearValue"] ~= nil then
            bodyBytes[18] = model["windGearValue"]
        end
        bodyBytes[bodyLength - 1] = math.random(1, 254)
        bodyBytes[bodyLength] = crc8_854(bodyBytes, 0, bodyLength - 1)
        msgBytes[9] = uptable["BYTE_CONTROL_REQUEST"]
    end
    for i = 0, bodyLength do
        msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]] = bodyBytes[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
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
    if deviceSubType == nil then
        deviceSubType = 0
    else
        if type(deviceSubType) == "string" then
            deviceSubType = tonumber(deviceSubType)
        end
    end
    uptable["BYTE_FANSPEED_LOW"] = 0x28
    uptable["BYTE_FANSPEED_MID"] = 0x3C
    uptable["BYTE_FANSPEED_AUTO"] = 0x66
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
    local sub_cmd = info[11]
    if sub_cmd == 0x01 then return nil end
    local streams = {}
    if sub_cmd == 0x0c then
        streams["btCount"] = info[12]
        local macs = ""
        local j = 25
        for i = 1, streams["btCount"] do
            macs = macs .. string.sub(binData, j + 10, j + 11) ..
                       string.sub(binData, j + 8, j + 9) ..
                       string.sub(binData, j + 6, j + 7) ..
                       string.sub(binData, j + 4, j + 5) ..
                       string.sub(binData, j + 2, j + 3) ..
                       string.sub(binData, j, j + 1)
            macs = macs .. ","
            j = j + 12
        end
        streams["btMacs"] = string.sub(macs, 1, #macs - 1)
        streams["version"] = VALUE_VERSION
        local retTable = {}
        retTable["status"] = streams
        local ret = encode(retTable)
        return ret
    end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - uptable["BYTE_PROTOCOL_LENGTH"] - 1
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]]
    end
    local model = binToModel(bodyBytes)
    streams[KEY_VERSION] = VALUE_VERSION
    streams.power = model.powerValue == 1 and "on" or "off"
    streams.add_water_flag = model.addWaterFlag == 1 and "true" or "false"
    streams.light_color = getValueFromValueTab(ENUM_LIGHT_COLOR_TAB,
                                               model.lightColorValue, "invalid")
    streams.wind_speed = getValueFromValueTab(
                             ENUM_WIND_SPEED_TAB(deviceSubType),
                             model.fanspeedValue, "invalid")
    streams.humidity = model.setHumidityValue
    streams.cur_humidity = model.currentHumidityValue
    streams.cur_temperature = model.currentTemperatureValue
    streams.tank_status = model.tankStatusValue
    streams.error_code = model.errorCode
    streams.bright_led = getValueFromValueTab(ENUM_BRIGHT_TAB, model.brightLED,
                                              "invalid")
    streams.humidity_mode = getValueFromValueTab(ENUM_MODE_TAB,
                                                 model.humidityMode, "invalid")
    streams.power_off_timer = model.scheduleCloseSwitcher == true and "on" or
                                  "off"
    streams.time_off = model.scheduleCloseTime
    streams.power_on_timer = model.scheduleOpenSwitcher == true and "on" or
                                 "off"
    streams.time_on = model.scheduleOpenTime
    streams.running_percent = model.runningPercentValue
    streams.disinfect_on_off = model.disinfectOnOffValue == 1 and "on" or
                                   model.disinfectOnOffValue == 2 and "off" or
                                   "invalid"
    streams.netIons_on_off = model.netIonsOnOffValue == 1 and "on" or "off"
    streams.airDry_on_off = model.airDryOnOffValue == 1 and "on" or
                                model.airDryOnOffValue == 2 and "off" or
                                "invalid"
    streams.wind_gear = getValueFromValueTab(ENUM_WIND_SPEED_TAB(deviceSubType),
                                             model.windGearValue, "invalid")
    streams.buzzer = model.buzzerValue == 1 and "on" or "off"
    if model.displayOnOffValue then
        streams.display_on_off = model.displayOnOffValue == 1 and "on" or
                                     model.displayOnOffValue == 2 and "off" or
                                     "invalid"
    end
    if #bodyBytes >= 49 then
        streams["air_dry_left_time"] = bodyBytes[40] + bodyBytes[41] * 256
        local sensorTemperature = (bit.band(bodyBytes[45], 0x7f) * 256 +
                                      bodyBytes[44]) / 10
        if bit.band(bodyBytes[45], 0x80) == 0x80 then
            sensorTemperature = sensorTemperature * -1
        end
        streams["sensorTemperature"] = sensorTemperature
        streams["sensorHumidify"] = bodyBytes[46]
        streams["sensorBattery"] = bodyBytes[47]
    end
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
