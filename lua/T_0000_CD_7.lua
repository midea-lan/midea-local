local bit = require "bit"
local JSON = require "cjson"
local KEY_VERSION = "version"
local KEY_POWER = "power"
local KEY_MODE = "mode"
local KEY_ERROR_CODE = "error_code"
local VALUE_VERSION = "7"
local VALUE_FUNCTION_ON = "on"
local VALUE_FUNCTION_OFF = "off"
local BYTE_DEVICE_TYPE = 0xCD
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERYL_REQUEST = 0x03
local BYTE_AUTO_REPORT = 0x05
local BYTE_CONTROL_REQUEST_ONE = 0x01
local BYTE_CONTROL_REQUEST_TWO = 0x02
local BYTE_CONTROL_REQUEST_THREE = 0x03
local BYTE_CONTROL_REQUEST_FOUR = 0x04
local BYTE_CONTROL_REQUEST_FIVE = 0x05
local BYTE_CONTROL_REQUEST_SIX = 0x06
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local myTable = { ["powerValue"] = 0, ["modeValue"] = 0, ["energyMode"] = 0, ["standardMode"] = 0, ["compatibilizingMode"] = 0, ["heatValue"] = 0, ["dicaryonHeat"] = 0, ["eco"] = 0, ["tsValue"] = 0, ["washBoxTemp"] = 0, ["boxTopTemp"] = 0, ["boxBottomTemp"] = 0, ["t3Value"] = 0, ["t4Value"] = 0, ["compressorTopTemp"] = 0, ["tsMaxValue"] = 0, ["tsMinValue"] = 0, ["timer1OpenHour"] = 0, ["timer1OpenMin"] = 0, ["timer1CloseHour"] = 0, ["timer1CloseMin"] = 0, ["timer2OpenHour"] = 0, ["timer2OpenMin"] = 0, ["timer2CloseHour"] = 0, ["timer2CloseMin"] = 0, ["errorCode"] = 0, ["order1Temp"] = 0, ["order1TimeHour"] = 0, ["order1TimeMin"] = 0, ["order2Temp"] = 0, ["order2TimeHour"] = 0, ["order2TimeMin"] = 0, ["bottomElecHeat"] = 0, ["topElecHeat"] = 0, ["waterPump"] = 0, ["compressor"] = 0, ["middleWind"] = 0, ["fourWayValve"] = 0, ["lowWind"] = 0, ["highWind"] = 0, ["timer1Effect"] = 0, ["timer2Effect"] = 0, ["order1Effect"] = 0, ["order2Effect"] = 0, ["smartEffect"] = 0, ["backwaterEffect"] = 0, ["sterilizeEffect"] = 0, ["typeInfo"] = 0, ["dataType"] = 0, ["controlType"] = 0, ["trValue"] = 0, ["openPTC"] = 0, ["ptcTemp"] = 0, ["refrigerantRecycling"] = 0, ["defrost"] = 0, ["mute"] = 0, ["openPTCTemp"] = 0 }
local function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
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
local function checkBoundary(data, min, max)
    if (not data) then
        data = 0
    end
    data = tonumber(data)
    if (data == nil) then
        data = 0
    end
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
local function string2Int(data)
    if (not data) then
        data = tonumber("0")
    end
    data = tonumber(data)
    if (data == nil) then
        data = 0
    end
    return data
end
local function int2String(data)
    if (not data) then
        data = tostring(0)
    end
    data = tostring(data)
    if (data == nil) then
        data = "0"
    end
    return data
end
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do
        ret = ret .. string.char(cmd[i])
    end
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
    for i = 1, #str do
        ret = ret .. string.format("%02x", str:byte(i))
    end
    return ret
end
local function encode(cmd)
    local tb
    if JSON == nil then
        JSON = require "cjson"
    end
    tb = JSON.encode(cmd)
    return tb
end
local function decode(cmd)
    local tb
    if JSON == nil then
        JSON = require "cjson"
    end
    tb = JSON.decode(cmd)
    return tb
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then
            resVal = bit.band(resVal, 0xff)
        end
    end
    resVal = 255 - resVal + 1
    return resVal
end
local crc8_854_table = { 0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65, 157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220, 35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98, 190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255, 70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7, 219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154, 101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36, 248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185, 140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205, 17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80, 175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238, 50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115, 202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139, 87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22, 233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168, 116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53 }
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end
local function string2Int(data)
    if (not data) then
        data = tonumber("0")
    end
    data = tonumber(data)
    if (data == nil) then
        data = 0
    end
    return data
end
local function int2String(data)
    if (not data) then
        data = tostring(0)
    end
    data = tostring(data)
    if (data == nil) then
        data = "0"
    end
    return data
end
local function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    local msgBytes = {}
    for i = 0, msgLength do
        msgBytes[i] = 0
    end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[9] = cType
    for i = 0, bodyLength do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyData[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do
        msgFinal[i] = msgBytes[i - 1]
    end
    return msgFinal
end
local function jsonToModel(controlJson)
    local controlCmd = controlJson
    myTable["controlType"] = 0x01;
    if (controlCmd["control_type"] ~= nil) then
        myTable["controlType"] = string2Int(controlCmd["control_type"])
    end
    if (myTable["controlType"] == 0x01) then
        if controlCmd[KEY_POWER] ~= nil then
            if controlCmd[KEY_POWER] == VALUE_FUNCTION_ON then
                myTable["powerValue"] = BYTE_POWER_ON
            else
                myTable["powerValue"] = BYTE_POWER_OFF
            end
        end
        if controlCmd[KEY_MODE] ~= nil then
            if controlCmd[KEY_MODE] == "energy" then
                myTable["modeValue"] = 0x01
            elseif controlCmd[KEY_MODE] == "standard" then
                myTable["modeValue"] = 0x02
            elseif controlCmd[KEY_MODE] == "compatibilizing" then
                myTable["modeValue"] = 0x03
            end
        end
        if controlCmd["set_temperature"] ~= nil then
            myTable["tsValue"] = string2Int(controlCmd["set_temperature"])
            myTable["tsValue"] = myTable["tsValue"] * 2 + 30
        end
        if controlCmd["tr_temperature"] ~= nil then
            myTable["trValue"] = string2Int(controlCmd["tr_temperature"])
            myTable["trValue"] = checkBoundary(myTable["trValue"], 2, 6)
        end
        if controlCmd["open_ptc"] ~= nil then
            if controlCmd["open_ptc"] == "0" then
                myTable["openPTC"] = 0x00
            elseif controlCmd["open_ptc"] == "1" then
                myTable["openPTC"] = 0x01
            elseif controlCmd["open_ptc"] == "2" then
                myTable["openPTC"] = 0x02
            end
        end
        if controlCmd["ptc_temperature"] ~= nil then
            myTable["ptcTemp"] = string2Int(controlCmd["ptc_temperature"])
        end
        if controlCmd["water_pump"] ~= nil then
            if controlCmd["water_pump"] == VALUE_FUNCTION_ON then
                myTable["waterPump"] = BYTE_POWER_ON
            elseif controlCmd["water_pump"] == VALUE_FUNCTION_OFF then
                myTable["waterPump"] = BYTE_POWER_OFF
            end
        end
        if controlCmd["refrigerant_recycling"] ~= nil then
            if controlCmd["refrigerant_recycling"] == VALUE_FUNCTION_ON then
                myTable["refrigerantRecycling"] = BYTE_POWER_ON
            elseif controlCmd["refrigerant_recycling"] == VALUE_FUNCTION_OFF then
                myTable["refrigerantRecycling"] = BYTE_POWER_OFF
            end
        end
        if controlCmd["defrost"] ~= nil then
            if controlCmd["defrost"] == VALUE_FUNCTION_ON then
                myTable["defrost"] = BYTE_POWER_ON
            elseif controlCmd["defrost"] == VALUE_FUNCTION_OFF then
                myTable["defrost"] = BYTE_POWER_OFF
            end
        end
        if controlCmd["mute"] ~= nil then
            if controlCmd["mute"] == VALUE_FUNCTION_ON then
                myTable["mute"] = BYTE_POWER_ON
            elseif controlCmd["mute"] == VALUE_FUNCTION_OFF then
                myTable["mute"] = BYTE_POWER_OFF
            end
        end
        if controlCmd["open_ptc_temperature"] ~= nil then
            if controlCmd["open_ptc_temperature"] == VALUE_FUNCTION_ON then
                myTable["openPTCTemp"] = BYTE_POWER_ON
            elseif controlCmd["open_ptc_temperature"] == VALUE_FUNCTION_OFF then
                myTable["openPTCTemp"] = BYTE_POWER_OFF
            end
        end
    elseif (myTable["controlType"] == 0x02) then
        if controlCmd["timer1_effect"] ~= nil then
            if controlCmd["timer1_effect"] == VALUE_FUNCTION_ON then
                myTable["timer1Effect"] = 0x01
            elseif controlCmd["timer1_effect"] == VALUE_FUNCTION_OFF then
                myTable["timer1Effect"] = 0
            end
        end
        if controlCmd["timer2_effect"] ~= nil then
            if controlCmd["timer2_effect"] == VALUE_FUNCTION_ON then
                myTable["timer2Effect"] = 0x02
            elseif controlCmd["timer2_effect"] == VALUE_FUNCTION_OFF then
                myTable["timer2Effect"] = 0
            end
        end
        if controlCmd["timer1_openHour"] ~= nil then
            myTable["timer1OpenHour"] = string2Int(controlCmd["timer1_openHour"])
        end
        if controlCmd["timer1_openMin"] ~= nil then
            myTable["timer1OpenMin"] = string2Int(controlCmd["timer1_openMin"])
        end
        if controlCmd["timer1_closeHour"] ~= nil then
            myTable["timer1CloseHour"] = string2Int(controlCmd["timer1_closeHour"])
        end
        if controlCmd["timer1_closeMin"] ~= nil then
            myTable["timer1CloseMin"] = string2Int(controlCmd["timer1_closeMin"])
        end
        if controlCmd["timer2_openHour"] ~= nil then
            myTable["timer2OpenHour"] = string2Int(controlCmd["timer2_openHour"])
        end
        if controlCmd["timer2_openMin"] ~= nil then
            myTable["timer2OpenMin"] = string2Int(controlCmd["timer2_openMin"])
        end
        if controlCmd["timer2_closeHour"] ~= nil then
            myTable["timer2CloseHour"] = string2Int(controlCmd["timer2_closeHour"])
        end
        if controlCmd["timer2_closeMin"] ~= nil then
            myTable["timer2CloseMin"] = string2Int(controlCmd["timer2_closeMin"])
        end
    elseif (myTable["controlType"] == 0x03) then
        if controlCmd["order1_effect"] ~= nil then
            if controlCmd["order1_effect"] == VALUE_FUNCTION_ON then
                myTable["order1Effect"] = 0x01
            elseif controlCmd["order1_effect"] == VALUE_FUNCTION_OFF then
                myTable["order1Effect"] = 0
            end
        end
        if controlCmd["order2_effect"] ~= nil then
            if controlCmd["order2_effect"] == VALUE_FUNCTION_ON then
                myTable["order2Effect"] = 0x01
            elseif controlCmd["order2_effect"] == VALUE_FUNCTION_OFF then
                myTable["order2Effect"] = 0
            end
        end
        if controlCmd["order1_timeHour"] ~= nil then
            myTable["order1TimeHour"] = string2Int(controlCmd["order1_timeHour"])
        end
        if controlCmd["order1_timeMin"] ~= nil then
            myTable["order1TimeMin"] = string2Int(controlCmd["order1_timeMin"])
        end
        if controlCmd["order2_timeHour"] ~= nil then
            myTable["order2TimeHour"] = string2Int(controlCmd["order2_timeHour"])
        end
        if controlCmd["order2_timeMin"] ~= nil then
            myTable["order2TimeMin"] = string2Int(controlCmd["order2_timeMin"])
        end
        if controlCmd["order1_temp"] ~= nil then
            myTable["order1Temp"] = string2Int(controlCmd["order1_temp"])
        end
        if controlCmd["order2_temp"] ~= nil then
            myTable["order2Temp"] = string2Int(controlCmd["order2_temp"])
        end
    elseif (myTable["controlType"] == 0x04) then
        if controlCmd["smart_effect"] ~= nil then
            if controlCmd["smart_effect"] == VALUE_FUNCTION_ON then
                myTable["smartEffect"] = BYTE_POWER_ON
            elseif controlCmd["smart_effect"] == VALUE_FUNCTION_OFF then
                myTable["smartEffect"] = BYTE_POWER_OFF
            end
        end
    elseif (myTable["controlType"] == 0x05) then
        if controlCmd["backwater_effect"] ~= nil then
            if controlCmd["backwater_effect"] == VALUE_FUNCTION_ON then
                myTable["backwaterEffect"] = BYTE_POWER_ON
            elseif controlCmd["backwater_effect"] == VALUE_FUNCTION_OFF then
                myTable["backwaterEffect"] = BYTE_POWER_OFF
            end
        end
    elseif (myTable["controlType"] == 0x06) then
        if controlCmd["sterilize_effect"] ~= nil then
            if controlCmd["sterilize_effect"] == VALUE_FUNCTION_ON then
                myTable["sterilizeEffect"] = BYTE_POWER_ON
            elseif controlCmd["sterilize_effect"] == VALUE_FUNCTION_OFF then
                myTable["sterilizeEffect"] = BYTE_POWER_OFF
            end
        end
    end
end
local function binToModel(binData)
    if (#binData == 0) then
        return nil
    end
    local messageBytes = {}
    for i = 0, 29 do
        messageBytes[i] = 0
    end
    for i = 0, #binData do
        messageBytes[i] = binData[i]
    end
    if (myTable["dataType"] == 0x03 or myTable["dataType"] == 0x05) then
        myTable["powerValue"] = bit.band(messageBytes[2], 0x01)
        myTable["energyMode"] = bit.rshift(bit.band(messageBytes[2], 0x02), 1)
        myTable["standardMode"] = bit.rshift(bit.band(messageBytes[2], 0x04), 2)
        myTable["compatibilizingMode"] = bit.rshift(bit.band(messageBytes[2], 0x08), 3)
        myTable["heatValue"] = bit.rshift(bit.band(messageBytes[2], 0x10), 4)
        myTable["dicaryonHeat"] = bit.rshift(bit.band(messageBytes[2], 0x20), 5)
        myTable["eco"] = bit.rshift(bit.band(messageBytes[2], 0x40), 6)
        myTable["tsValue"] = messageBytes[3]
        myTable["washBoxTemp"] = messageBytes[4]
        myTable["boxTopTemp"] = messageBytes[5]
        myTable["boxBottomTemp"] = messageBytes[6]
        myTable["t3Value"] = messageBytes[7]
        myTable["t4Value"] = messageBytes[8]
        myTable["compressorTopTemp"] = messageBytes[9]
        myTable["tsMaxValue"] = messageBytes[10]
        myTable["tsMinValue"] = messageBytes[11]
        myTable["timer1OpenHour"] = messageBytes[12]
        myTable["timer1OpenMin"] = messageBytes[13]
        myTable["timer1CloseHour"] = messageBytes[14]
        myTable["timer1CloseMin"] = messageBytes[15]
        myTable["timer2OpenHour"] = messageBytes[16]
        myTable["timer2OpenMin"] = messageBytes[17]
        myTable["timer2CloseHour"] = messageBytes[18]
        myTable["timer2CloseMin"] = messageBytes[19]
        myTable["errorCode"] = messageBytes[20]
        myTable["order1Temp"] = messageBytes[21]
        myTable["order1TimeHour"] = messageBytes[22]
        myTable["order1TimeMin"] = messageBytes[23]
        myTable["order2Temp"] = messageBytes[24]
        myTable["order2TimeHour"] = messageBytes[25]
        myTable["order2TimeMin"] = messageBytes[26]
        myTable["bottomElecHeat"] = bit.band(messageBytes[27], 0x01)
        myTable["topElecHeat"] = bit.rshift(bit.band(messageBytes[27], 0x02), 1)
        myTable["waterPump"] = bit.rshift(bit.band(messageBytes[27], 0x04), 2)
        myTable["compressor"] = bit.rshift(bit.band(messageBytes[27], 0x08), 3)
        myTable["middleWind"] = bit.rshift(bit.band(messageBytes[27], 0x10), 4)
        myTable["fourWayValve"] = bit.rshift(bit.band(messageBytes[27], 0x20), 5)
        myTable["lowWind"] = bit.rshift(bit.band(messageBytes[27], 0x40), 6)
        myTable["highWind"] = bit.rshift(bit.band(messageBytes[27], 0x80), 7)
        myTable["timer1Effect"] = bit.rshift(bit.band(messageBytes[28], 0x02), 1)
        myTable["timer2Effect"] = bit.rshift(bit.band(messageBytes[28], 0x04), 2)
        myTable["order1Effect"] = bit.rshift(bit.band(messageBytes[28], 0x08), 3)
        myTable["order2Effect"] = bit.rshift(bit.band(messageBytes[28], 0x10), 4)
        myTable["smartEffect"] = bit.rshift(bit.band(messageBytes[28], 0x20), 5)
        myTable["backwaterEffect"] = bit.rshift(bit.band(messageBytes[28], 0x40), 6)
        myTable["sterilizeEffect"] = bit.rshift(bit.band(messageBytes[28], 0x80), 7)
        myTable["typeInfo"] = messageBytes[29]
    elseif myTable["dataType"] == 0x02 then
        myTable["controlType"] = messageBytes[0]
        if myTable["controlType"] == 0x01 then
            myTable["powerValue"] = messageBytes[2]
            myTable["modeValue"] = messageBytes[3]
            myTable["tsValue"] = messageBytes[4]
            myTable["trValue"] = messageBytes[5]
            myTable["openPTC"] = messageBytes[6]
            myTable["ptcTemp"] = messageBytes[7]
            myTable["waterPump"] = bit.band(messageBytes[8], 0x01)
            myTable["refrigerantRecycling"] = bit.rshift(bit.band(messageBytes[8], 0x02), 1)
            myTable["defrost"] = bit.rshift(bit.band(messageBytes[8], 0x04), 2)
            myTable["mute"] = bit.rshift(bit.band(messageBytes[8], 0x08), 3)
            myTable["openPTCTemp"] = bit.rshift(bit.band(messageBytes[8], 0x02), 6)
        elseif (myTable["controlType"] == 0x02) then
            myTable["timer1Effect"] = bit.band(messageBytes[3], 0x01)
            myTable["timer2Effect"] = bit.rshift(bit.band(messageBytes[3], 0x02), 1)
            myTable["timer1OpenHour"] = messageBytes[4]
            myTable["timer1OpenMin"] = messageBytes[5]
            myTable["timer1CloseHour"] = messageBytes[6]
            myTable["timer1CloseMin"] = messageBytes[7]
            myTable["timer2OpenHour"] = messageBytes[9]
            myTable["timer2OpenMin"] = messageBytes[10]
            myTable["timer2CloseHour"] = messageBytes[11]
            myTable["timer2CloseMin"] = messageBytes[12]
        elseif (myTable["controlType"] == 0x03) then
            myTable["order1Effect"] = messageBytes[2]
            myTable["order1Temp"] = messageBytes[3]
            myTable["order1TimeHour"] = messageBytes[4]
            myTable["order1TimeMin"] = messageBytes[5]
            myTable["order2Effect"] = messageBytes[6]
            myTable["order2Temp"] = messageBytes[7]
            myTable["order2TimeHour"] = messageBytes[8]
            myTable["order2TimeMin"] = messageBytes[9]
        elseif (myTable["controlType"] == 0x04) then
            myTable["smartEffect"] = messageBytes[2]
        elseif (myTable["controlType"] == 0x05) then
            myTable["backwaterEffect"] = messageBytes[2]
        elseif (myTable["controlType"] == 0x06) then
            myTable["sterilizeEffect"] = messageBytes[2]
        end
    end
end
function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then
        return nil
    end
    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then
    end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    local infoM = {}
    local bodyBytes = {}
    if (query) then
        bodyBytes[0] = 0x01
        bodyBytes[1] = 0x01
        infoM = getTotalMsg(bodyBytes, BYTE_QUERYL_REQUEST)
    elseif (control) then
        if (status) then
            jsonToModel(status)
        end
        if (control) then
            jsonToModel(control)
        end
        if (myTable["controlType"] == 0x01) then
            for i = 0, 8 do
                bodyBytes[i] = 0
            end
            bodyBytes[0] = 0x01
            bodyBytes[1] = 0x01
            bodyBytes[2] = myTable["powerValue"]
            if control[KEY_MODE] ~= nil then
                bodyBytes[3] = myTable["modeValue"]
            else
                if (status["energy_mode"] ~= nil and status["energy_mode"] == VALUE_FUNCTION_ON) or myTable["energyMode"] == BYTE_POWER_ON then
                    bodyBytes[3] = 0x01
                elseif (status["standard_mode"] ~= nil and status["standard_mode"] == VALUE_FUNCTION_ON) or myTable["standardMode"] == BYTE_POWER_ON then
                    bodyBytes[3] = 0x02
                elseif (status["compatibilizing_mode"] ~= nil and status["compatibilizing_mode"] == VALUE_FUNCTION_ON) or myTable["compatibilizingMode"] == BYTE_POWER_ON then
                    bodyBytes[3] = 0x03
                else
                    bodyBytes[3] = myTable["modeValue"]
                end
            end
            bodyBytes[4] = myTable["tsValue"]
            bodyBytes[5] = myTable["trValue"]
            bodyBytes[6] = myTable["openPTC"]
            bodyBytes[7] = myTable["ptcTemp"]
            bodyBytes[8] = bit.bor(bit.bor(bit.bor(bit.bor(myTable["waterPump"], myTable["refrigerantRecycling"]), myTable["defrost"]), myTable["mute"]), myTable["openPTCTemp"])
            infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
        elseif (myTable["controlType"] == 0x02) then
            for i = 0, 23 do
                bodyBytes[i] = 0
            end
            bodyBytes[0] = 0x02
            bodyBytes[1] = 0x01
            bodyBytes[2] = 0x02
            bodyBytes[3] = bit.bor(myTable["timer1Effect"], myTable["timer2Effect"], 0, 0)
            bodyBytes[4] = myTable["timer1OpenHour"];
            bodyBytes[5] = myTable["timer1OpenMin"];
            bodyBytes[6] = myTable["timer1CloseHour"];
            bodyBytes[7] = myTable["timer1CloseMin"];
            bodyBytes[8] = 45;
            bodyBytes[9] = myTable["timer2OpenHour"];
            bodyBytes[10] = myTable["timer2OpenMin"];
            bodyBytes[11] = myTable["timer2CloseHour"];
            bodyBytes[12] = myTable["timer2CloseMin"];
            bodyBytes[13] = 45;
            for i = 14, 23 do
                bodyBytes[i] = 0
            end
            infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
        elseif (myTable["controlType"] == 0x03) then
            for i = 0, 9 do
                bodyBytes[i] = 0
            end
            bodyBytes[0] = 0x03
            bodyBytes[1] = 0x01
            bodyBytes[2] = myTable["order1Effect"]
            bodyBytes[3] = int2String(math.modf((myTable["order1Temp"] * 2) + 30))
            bodyBytes[4] = myTable["order1TimeHour"]
            bodyBytes[5] = myTable["order1TimeMin"]
            bodyBytes[6] = myTable["order2Effect"]
            bodyBytes[7] = int2String(math.modf((myTable["order2Temp"] * 2) + 30))
            bodyBytes[8] = myTable["order2TimeHour"]
            bodyBytes[9] = myTable["order2TimeMin"]
            infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
        elseif (myTable["controlType"] == 0x04) then
            for i = 0, 2 do
                bodyBytes[i] = 0
            end
            bodyBytes[0] = 0x04
            bodyBytes[1] = 0x01
            bodyBytes[2] = myTable["smartEffect"]
            infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
        elseif (myTable["controlType"] == 0x05) then
            for i = 0, 2 do
                bodyBytes[i] = 0
            end
            bodyBytes[0] = 0x05
            bodyBytes[1] = 0x01
            bodyBytes[2] = myTable["backwaterEffect"]
            infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
        elseif (myTable["controlType"] == 0x06) then
            for i = 0, 2 do
                bodyBytes[i] = 0
            end
            bodyBytes[0] = 0x06
            bodyBytes[1] = 0x01
            bodyBytes[2] = myTable["sterilizeEffect"]
            infoM = getTotalMsg(bodyBytes, BYTE_CONTROL_REQUEST)
        end
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonCmd)
    if (not jsonCmd) then
        return nil
    end
    local json = decode(jsonCmd)
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then
    end
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    local msgSubType = 0
    info = string2table(binData)
    if (#info < 11) then
        return nil
    end
    for i = 1, #info do
        msgBytes[i - 1] = info[i]
    end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    myTable["dataType"] = msgBytes[9]
    msgSubType = msgBytes[10]
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then
    end
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    binToModel(bodyBytes)
    if (((myTable["dataType"] == BYTE_AUTO_REPORT) and (msgSubType == 0x01)) or (myTable["dataType"] == BYTE_QUERYL_REQUEST)) then
        if (myTable["powerValue"] == BYTE_POWER_ON) then
            streams[KEY_POWER] = VALUE_FUNCTION_ON
        elseif (myTable["powerValue"] == BYTE_POWER_OFF) then
            streams[KEY_POWER] = VALUE_FUNCTION_OFF
        end
        if (myTable["energyMode"] == BYTE_POWER_ON) then
            streams["energy_mode"] = VALUE_FUNCTION_ON
        elseif (myTable["energyMode"] == BYTE_POWER_OFF) then
            streams["energy_mode"] = VALUE_FUNCTION_OFF
        end
        if (myTable["standardMode"] == BYTE_POWER_ON) then
            streams["standard_mode"] = VALUE_FUNCTION_ON
        elseif (myTable["standardMode"] == BYTE_POWER_OFF) then
            streams["standard_mode"] = VALUE_FUNCTION_OFF
        end
        if (myTable["compatibilizingMode"] == BYTE_POWER_ON) then
            streams["compatibilizing_mode"] = VALUE_FUNCTION_ON
        elseif (myTable["compatibilizingMode"] == BYTE_POWER_OFF) then
            streams["compatibilizing_mode"] = VALUE_FUNCTION_OFF
        end
        if (myTable["heatValue"] == BYTE_POWER_ON) then
            streams["high_heat"] = VALUE_FUNCTION_ON
        elseif (myTable["heatValue"] == BYTE_POWER_OFF) then
            streams["high_heat"] = VALUE_FUNCTION_OFF
        end
        if (myTable["dicaryonHeat"] == BYTE_POWER_ON) then
            streams["dicaryon_heat"] = VALUE_FUNCTION_ON
        elseif (myTable["dicaryonHeat"] == BYTE_POWER_OFF) then
            streams["dicaryon_heat"] = VALUE_FUNCTION_OFF
        end
        if (myTable["eco"] == BYTE_POWER_ON) then
            streams["eco"] = VALUE_FUNCTION_ON
        elseif (myTable["eco"] == BYTE_POWER_OFF) then
            streams["eco"] = VALUE_FUNCTION_OFF
        end
        streams["set_temperature"] = int2String(math.modf((myTable["tsValue"] - 30) / 2))
        streams["water_box_temperature"] = int2String(math.modf((myTable["washBoxTemp"] - 30) / 2))
        streams["water_box_top_temperature"] = int2String(math.modf((myTable["boxTopTemp"] - 30) / 2))
        streams["water_box_bottom_temperature"] = int2String(math.modf((myTable["boxBottomTemp"] - 30) / 2))
        streams["condensator_temperature"] = int2String(math.modf((myTable["t3Value"] - 30) / 2))
        streams["outdoor_temperature"] = int2String(math.modf((myTable["t4Value"] - 30) / 2))
        streams["compressor_top_temperature"] = int2String(math.modf((myTable["compressorTopTemp"] - 30) / 2))
        streams["set_temperature_max"] = int2String(math.modf((myTable["tsMaxValue"] - 30) / 2))
        streams["set_temperature_min"] = int2String(math.modf((myTable["tsMinValue"] - 30) / 2))
        streams[KEY_ERROR_CODE] = int2String(myTable["errorCode"])
        if (myTable["bottomElecHeat"] == BYTE_POWER_ON) then
            streams["bottom_elec_heat"] = VALUE_FUNCTION_ON
        elseif (myTable["bottomElecHeat"] == BYTE_POWER_OFF) then
            streams["bottom_elec_heat"] = VALUE_FUNCTION_OFF
        end
        if (myTable["topElecHeat"] == BYTE_POWER_ON) then
            streams["top_elec_heat"] = VALUE_FUNCTION_ON
        elseif (myTable["topElecHeat"] == BYTE_POWER_OFF) then
            streams["top_elec_heat"] = VALUE_FUNCTION_OFF
        end
        if (myTable["waterPump"] == BYTE_POWER_ON) then
            streams["water_pump"] = VALUE_FUNCTION_ON
        elseif (myTable["waterPump"] == BYTE_POWER_OFF) then
            streams["water_pump"] = VALUE_FUNCTION_OFF
        end
        if (myTable["compressor"] == BYTE_POWER_ON) then
            streams["compressor"] = VALUE_FUNCTION_ON
        elseif (myTable["compressor"] == BYTE_POWER_OFF) then
            streams["compressor"] = VALUE_FUNCTION_OFF
        end
        if (myTable["middleWind"] == BYTE_POWER_ON) then
            streams["middle_wind"] = VALUE_FUNCTION_ON
        elseif (myTable["middleWind"] == BYTE_POWER_OFF) then
            streams["middle_wind"] = VALUE_FUNCTION_OFF
        end
        if (myTable["fourWayValve"] == BYTE_POWER_ON) then
            streams["four_way_valve"] = VALUE_FUNCTION_ON
        elseif (myTable["fourWayValve"] == BYTE_POWER_OFF) then
            streams["four_way_valve"] = VALUE_FUNCTION_OFF
        end
        if (myTable["lowWind"] == BYTE_POWER_ON) then
            streams["low_wind"] = VALUE_FUNCTION_ON
        elseif (myTable["lowWind"] == BYTE_POWER_OFF) then
            streams["low_wind"] = VALUE_FUNCTION_OFF
        end
        if (myTable["highWind"] == BYTE_POWER_ON) then
            streams["high_wind"] = VALUE_FUNCTION_ON
        elseif (myTable["highWind"] == BYTE_POWER_OFF) then
            streams["high_wind"] = VALUE_FUNCTION_OFF
        end
        streams["type_info"] = int2String(myTable["typeInfo"])
        if (myTable["smartEffect"] == BYTE_POWER_ON) then
            streams["smart_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["smartEffect"] == BYTE_POWER_OFF) then
            streams["smart_effect"] = VALUE_FUNCTION_OFF
        end
        if (myTable["backwaterEffect"] == BYTE_POWER_ON) then
            streams["backwater_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["backwaterEffect"] == BYTE_POWER_OFF) then
            streams["backwater_effect"] = VALUE_FUNCTION_OFF
        end
        if (myTable["sterilizeEffect"] == BYTE_POWER_ON) then
            streams["sterilize_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["sterilizeEffect"] == BYTE_POWER_OFF) then
            streams["sterilize_effect"] = VALUE_FUNCTION_OFF
        end
        if (myTable["timer1Effect"] == BYTE_POWER_ON) then
            streams["timer1_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["timer1Effect"] == BYTE_POWER_OFF) then
            streams["timer1_effect"] = VALUE_FUNCTION_OFF
        end
        if (myTable["timer2Effect"] == BYTE_POWER_ON) then
            streams["timer2_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["timer2Effect"] == BYTE_POWER_OFF) then
            streams["timer2_effect"] = VALUE_FUNCTION_OFF
        end
        if (myTable["order1Effect"] == BYTE_POWER_ON) then
            streams["order1_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["order1Effect"] == BYTE_POWER_OFF) then
            streams["order1_effect"] = VALUE_FUNCTION_OFF
        end
        if (myTable["order2Effect"] == BYTE_POWER_ON) then
            streams["order2_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["order2Effect"] == BYTE_POWER_OFF) then
            streams["order2_effect"] = VALUE_FUNCTION_OFF
        end
        streams["timer1_openHour"] = int2String(myTable["timer1OpenHour"])
        streams["timer1_openMin"] = int2String(myTable["timer1OpenMin"])
        streams["timer1_closeHour"] = int2String(myTable["timer1CloseHour"])
        streams["timer1_closeMin"] = int2String(myTable["timer1CloseMin"])
        streams["timer2_openHour"] = int2String(myTable["timer2OpenHour"])
        streams["timer2_openMin"] = int2String(myTable["timer2OpenMin"])
        streams["timer2_closeHour"] = int2String(myTable["timer2CloseHour"])
        streams["timer2_closeMin"] = int2String(myTable["timer2CloseMin"])
        streams["order1_temp"] = int2String(math.modf((myTable["order1Temp"] - 30) / 2))
        streams["order1_timeHour"] = int2String(myTable["order1TimeHour"])
        streams["order1_timeMin"] = int2String(myTable["order1TimeMin"])
        streams["order2_temp"] = int2String(math.modf((myTable["order2Temp"] - 30) / 2))
        streams["order2_timeHour"] = int2String(myTable["order2TimeHour"])
        streams["order2_timeMin"] = int2String(myTable["order2TimeMin"])
    elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 0x01)) then
        if (myTable["powerValue"] == BYTE_POWER_ON) then
            streams[KEY_POWER] = VALUE_FUNCTION_ON
        elseif (myTable["powerValue"] == BYTE_POWER_OFF) then
            streams[KEY_POWER] = VALUE_FUNCTION_OFF
        end
        if myTable["modeValue"] == 0x01 then
            streams[KEY_MODE] = "energy"
        elseif myTable["modeValue"] == 0x02 then
            streams[KEY_MODE] = "standard"
        elseif myTable["modeValue"] == 0x03 then
            streams[KEY_MODE] = "compatibilizing"
        end
        streams["tr_temperature"] = int2String(math.modf(myTable["trValue"]))
        streams["open_ptc"] = int2String(myTable["openPTC"])
        streams["ptc_temperature"] = int2String(math.modf(myTable["ptcTemp"]))
        if (myTable["mute"] == BYTE_POWER_ON) then
            streams["mute"] = VALUE_FUNCTION_ON
        elseif (myTable["mute"] == BYTE_POWER_OFF) then
            streams["mute"] = VALUE_FUNCTION_OFF
        end
        if (myTable["openPTCTemp"] == BYTE_POWER_ON) then
            streams["open_ptc_temperature"] = VALUE_FUNCTION_ON
        elseif (myTable["openPTCTemp"] == BYTE_POWER_OFF) then
            streams["open_ptc_temperature"] = VALUE_FUNCTION_OFF
        end
        streams["set_temperature"] = int2String(math.modf((myTable["tsValue"] - 30) / 2))
    elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 0x02)) then
        if (myTable["timer1Effect"] == BYTE_POWER_ON) then
            streams["timer1_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["timer1Effect"] == BYTE_POWER_OFF) then
            streams["timer1_effect"] = VALUE_FUNCTION_OFF
        end
        if (myTable["timer2Effect"] == BYTE_POWER_ON) then
            streams["timer2_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["timer2Effect"] == BYTE_POWER_OFF) then
            streams["timer2_effect"] = VALUE_FUNCTION_OFF
        end
        streams["timer1_openHour"] = int2String(myTable["timer1OpenHour"])
        streams["timer1_openMin"] = int2String(myTable["timer1OpenMin"])
        streams["timer1_closeHour"] = int2String(myTable["timer1CloseHour"])
        streams["timer1_closeMin"] = int2String(myTable["timer1CloseMin"])
        streams["timer2_openHour"] = int2String(myTable["timer2OpenHour"])
        streams["timer2_openMin"] = int2String(myTable["timer2OpenMin"])
        streams["timer2_closeHour"] = int2String(myTable["timer2CloseHour"])
        streams["timer2_closeMin"] = int2String(myTable["timer2CloseMin"])
    elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 0x03)) then
        if (myTable["order1Effect"] == BYTE_POWER_ON) then
            streams["order1_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["order1Effect"] == BYTE_POWER_OFF) then
            streams["order1_effect"] = VALUE_FUNCTION_OFF
        end
        if (myTable["order2Effect"] == BYTE_POWER_ON) then
            streams["order2_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["order2Effect"] == BYTE_POWER_OFF) then
            streams["order2_effect"] = VALUE_FUNCTION_OFF
        end
        streams["order1_temp"] = int2String(math.modf((myTable["order1Temp"] - 30) / 2))
        streams["order1_timeHour"] = int2String(myTable["order1TimeHour"])
        streams["order1_timeMin"] = int2String(myTable["order1TimeMin"])
        streams["order2_temp"] = int2String(math.modf((myTable["order2Temp"] - 30) / 2))
        streams["order2_timeHour"] = int2String(myTable["order2TimeHour"])
        streams["order2_timeMin"] = int2String(myTable["order2TimeMin"])
    elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 0x04)) then
        if (myTable["smartEffect"] == BYTE_POWER_ON) then
            streams["smart_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["smartEffect"] == BYTE_POWER_OFF) then
            streams["smart_effect"] = VALUE_FUNCTION_OFF
        end
    elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 0x05)) then
        if (myTable["backwaterEffect"] == BYTE_POWER_ON) then
            streams["backwater_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["backwaterEffect"] == BYTE_POWER_OFF) then
            streams["backwater_effect"] = VALUE_FUNCTION_OFF
        end
    elseif ((myTable["dataType"] == BYTE_CONTROL_REQUEST) and (msgSubType == 0x06)) then
        if (myTable["sterilizeEffect"] == BYTE_POWER_ON) then
            streams["sterilize_effect"] = VALUE_FUNCTION_ON
        elseif (myTable["sterilizeEffect"] == BYTE_POWER_OFF) then
            streams["sterilize_effect"] = VALUE_FUNCTION_OFF
        end
    end
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
