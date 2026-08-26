local bit = require "bit"
local JSON = require "cjson"
local bit = {datagBitLen = {}}
local gBitLen = 32
local isBitInit = false
local VALUE_VERSION = 21
local function bitInit()
    if isBitInit == false then
        for i = 0, gBitLen - 1 do
            bit.datagBitLen[i] = 2 ^ ((gBitLen - 1) - i)
        end
        isBitInit = true
    end
end
local function d2b(arg)
    local tr = {}
    for i = 0, gBitLen - 1 do
        if arg >= bit.datagBitLen[i] then
            tr[i] = 1
            arg = arg - bit.datagBitLen[i]
        else
            tr[i] = 0
        end
    end
    return tr
end
local function b2d(arg)
    local nr = 0
    for i = 0, gBitLen - 1 do
        if arg[i] == 1 then nr = nr + 2 ^ (gBitLen - 1 - i) end
    end
    return nr
end
local function xor(a, b)
    local op1 = d2b(a)
    local op2 = d2b(b)
    local r = {}
    for i = 0, gBitLen - 1 do
        if op1[i] == op2[i] then
            r[i] = 0
        else
            r[i] = 1
        end
    end
    return b2d(r)
end
local function _and(a, b)
    local op1 = d2b(a)
    local op2 = d2b(b)
    local r = {}
    for i = 0, gBitLen - 1 do
        if op1[i] == 1 and op2[i] == 1 then
            r[i] = 1
        else
            r[i] = 0
        end
    end
    return b2d(r)
end
local function _or(a, b)
    local op1 = d2b(a)
    local op2 = d2b(b)
    local r = {}
    for i = 0, gBitLen - 1 do
        if op1[i] == 1 or op2[i] == 1 then
            r[i] = 1
        else
            r[i] = 0
        end
    end
    return b2d(r)
end
local function _not(a)
    local op1 = d2b(a)
    local r = {}
    for i = 0, gBitLen - 1 do
        if op1[i] == 1 then
            r[i] = 0
        else
            r[i] = 1
        end
    end
    return b2d(r)
end
local function _rshift(a, n)
    local op1 = d2b(a)
    local r = d2b(0)
    if n < gBitLen and n > 0 then
        for i = 0, n - 1 do
            for i = 31, 1, -1 do op1[i] = op1[i - 1] end
            op1[0] = 0
        end
        r = op1
    else
        r = op1
    end
    return b2d(r)
end
local function _lshift(a, n)
    local op1 = d2b(a)
    local r = d2b(0)
    if n < gBitLen and n > 0 then
        for i = 0, n - 1 do
            for i = 0, 30 do op1[i] = op1[i + 1] end
            op1[gBitLen - 1] = 0
        end
        r = op1
    else
        r = op1
    end
    return b2d(r)
end
local function setByte(pBytes, pIndex, pValue)
    pBytes[pIndex] = _and(pValue, 0xFF);
    return pBytes;
end
local function getByte(pBytes, pIndex) return _and(pBytes[pIndex], 0xFF); end
local function _setBit(pByte, pIndex, pValue)
    pByte = _and(pByte, (0xFF - _lshift(0x01, pIndex)))
    pByte = _or(_lshift(_and(pValue, 0x01), pIndex), pByte);
    return pByte;
end
local function _getBit(pByte, pIndex) return _and(_rshift(pByte, pIndex), 0x01); end
local function getBit(pBytes, pIndex, pBitIndex)
    return _getBit(pBytes[pIndex], pBitIndex);
end
local function setBit(pBytes, pIndex, pBitIndex, pValue)
    pBytes[pIndex] = _setBit(pBytes[pIndex], pBitIndex, pValue);
    return pBytes;
end
local function _getBits(pByte, pStartIndex, pEndIndex)
    if pStartIndex > pEndIndex then
        return _getBits(pByte, pEndIndex, pStartIndex);
    end
    local tempVal = 0x00;
    for i = pStartIndex, pEndIndex do
        tempVal = _or(tempVal, _lshift(_getBit(pByte, i), (i - pStartIndex)));
    end
    return tempVal;
end
local function _setBits(pByte, pStartIndex, pEndIndex, pValue)
    if pStartIndex > pEndIndex then
        return _setBits(pByte, pEndIndex, pStartIndex, pValue);
    end
    for i = pStartIndex, pEndIndex do
        pByte = _setBit(pByte, i, _getBit(pValue, i - pStartIndex));
    end
    return pByte;
end
local function getBits(pBytes, pIndex, pBitStartIndex, pBitEndIndex)
    return _getBits(pBytes[pIndex], pBitStartIndex, pBitEndIndex);
end
local function setBits(pBytes, pIndex, pBitStartIndex, pBitEndIndex, pValue)
    pBytes[pIndex] = _setBits(pBytes[pIndex], pBitStartIndex, pBitEndIndex,
                              pValue);
    return pBytes;
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
        if resVal > 0xff then resVal = _and(resVal, 0xFF) end
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
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
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
local function quMo(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    local result = 0
    result = data % 10
    return result
end
local function quChu(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    local result = 0
    result = math.modf(data / 10)
    return result
end
local function initByteByStatus(status, byteArray)
    local numTemp = 0
    for key, value in pairs(status) do
        if key == "gear" then
            if type(value) == "number" then
                numTemp = value
            else
                numTemp = string2Int(value)
            end
            if numTemp >= 1 and numTemp <= 10 then
                byteArray[15] = numTemp
            end
        elseif key == "temperature" then
            if type(value) == "number" then
                numTemp = value
            else
                numTemp = string2Int(value)
            end
            if numTemp >= -40 and numTemp <= 50 then
                byteArray[16] = numTemp + 41
            elseif numTemp == 0x80 or numTemp == 87 then
                byteArray[16] = 0x80
            end
        elseif key == "timer_off_hour" then
            if type(value) == "number" then
                numTemp = value
            else
                numTemp = string2Int(value)
            end
            if numTemp >= 1 and numTemp <= 24 then
                setBits(byteArray, 20, 0, 4, numTemp)
            end
        elseif key == "timer_off_minute" then
            if type(value) == "number" then
                if value >= 1 and value <= 59 then
                    setBits(byteArray, 20, 5, 7, quChu(value))
                    setBits(byteArray, 24, 4, 7, quMo(value))
                elseif value == 0 then
                    byteArray[24] = 0
                end
            else
                numTemp = string2Int(value)
                if numTemp >= 1 and numTemp <= 59 then
                    setBits(byteArray, 20, 5, 7, quChu(numTemp))
                    setBits(byteArray, 24, 4, 7, quMo(numTemp))
                elseif numTemp == 0 then
                    byteArray[24] = 0
                end
            end
        end
    end
    return byteArray
end
function jsonToData(jsonCmd)
    bitInit()
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if deviceSubType == nil then
        deviceSubType = 0
    else
        if type(deviceSubType) == "string" then
            deviceSubType = tonumber(deviceSubType)
        end
    end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    local bodyLength
    if (query) then
        local guowangData = query["guowang"]
        if guowangData ~= nil then
            bodyLength = #string2table(guowangData) + 1
        else
            bodyLength = 0
        end
    elseif (control) then
        if deviceSubType > 0x00 and deviceSubType <= 0x05 then
            bodyLength = 20
        else
            bodyLength = 28
        end
    end
    local msgLength = bodyLength + 0x0A
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = 0xAA
    msgBytes[1] = bodyLength + 0x0A
    msgBytes[2] = 0xFB
    if (query) then
        msgBytes[9] = 0x03
        local guowangData = query["guowang"]
        if guowangData ~= nil then
            msgBytes[10] = 0x08
            local byteData = string2table(guowangData)
            for i = 1, #byteData do
                setByte(msgBytes, 10 + i, byteData[i])
            end
        end
    elseif (control) then
        msgBytes[9] = 0x02
        msgBytes[28] = 0xFF
        if deviceSubType == 3 or deviceSubType == 4 then
            msgBytes = initByteByStatus(status, msgBytes)
        end
        local numTemp = 0
        for key, value in pairs(control) do
            if key == "power" then
                if value == "on" then
                    setByte(msgBytes, 10, 1)
                elseif value == "off" then
                    setByte(msgBytes, 10, 2)
                end
            elseif key == "voice" then
                if value == "open_gps" then
                    msgBytes[12] = 1
                elseif value == "close_gps" then
                    msgBytes[12] = 2
                elseif value == "open_buzzer" then
                    msgBytes[12] = 4
                elseif value == "close_buzzer" then
                    msgBytes[12] = 8
                elseif value == "open_tip" then
                    msgBytes[12] = 5
                elseif value == "mute" then
                    msgBytes[12] = 10
                end
            elseif key == "mode" then
                if value == "intelligent" then
                    setBits(msgBytes, 14, 0, 7, 1)
                elseif value == "efficient" then
                    setBits(msgBytes, 14, 0, 7, 2)
                elseif value == "sleep" then
                    setBits(msgBytes, 14, 0, 7, 3)
                elseif value == "antifreezing" then
                    setBits(msgBytes, 14, 0, 7, 4)
                elseif value == "comfort" then
                    setBits(msgBytes, 14, 0, 7, 5)
                elseif value == "constant_temperature" then
                    setBits(msgBytes, 14, 0, 7, 6)
                elseif value == "normal" then
                    setBits(msgBytes, 14, 0, 7, 7)
                elseif value == "fast_hot" then
                    setBits(msgBytes, 14, 0, 7, 8)
                elseif value == "idle_mode" then
                    setBits(msgBytes, 14, 0, 7, 10)
                elseif value == "cold_air" then
                    setBits(msgBytes, 14, 0, 7, 11)
                elseif value == "hot_house" then
                    setBits(msgBytes, 14, 0, 7, 12)
                elseif value == "bath_mode" then
                    setBits(msgBytes, 14, 0, 7, 13)
                elseif value == "hot_feet" then
                    setBits(msgBytes, 14, 0, 7, 14)
                elseif value == "hot_dry" then
                    setBits(msgBytes, 14, 0, 7, 15)
                elseif value == "light" then
                    setBits(msgBytes, 14, 0, 7, 16)
                elseif value == "nature" then
                    setBits(msgBytes, 14, 0, 7, 17)
                end
            elseif key == "gear" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 10 then
                    msgBytes[15] = numTemp
                end
            elseif key == "temperature" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= -40 and numTemp <= 50 then
                    msgBytes[16] = numTemp + 41
                elseif numTemp == 0x80 or numTemp == 87 then
                    msgBytes[16] = 0x80
                end
            elseif key == "humidity" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 100 then
                    msgBytes[17] = numTemp
                end
            elseif key == "shake_type" then
                if value == "lr" then
                    setBits(msgBytes, 18, 2, 4, 1)
                elseif value == "ud" then
                    setBits(msgBytes, 18, 2, 4, 2)
                elseif value == "8" then
                    setBits(msgBytes, 18, 2, 4, 3)
                elseif value == "w" then
                    setBits(msgBytes, 18, 2, 4, 4)
                end
            elseif key == "shake_switch" then
                if value == "on" then
                    setBits(msgBytes, 18, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 18, 0, 1, 2)
                end
            elseif key == "shake_angle" then
                if value == "30" then
                    setBits(msgBytes, 18, 5, 7, 1)
                elseif value == "60" then
                    setBits(msgBytes, 18, 5, 7, 2)
                elseif value == "90" then
                    setBits(msgBytes, 18, 5, 7, 3)
                elseif value == "180" then
                    setBits(msgBytes, 18, 5, 7, 4)
                elseif value == "360" then
                    setBits(msgBytes, 18, 5, 7, 5)
                end
            elseif key == "humidification" then
                if value == "off" then
                    setBits(msgBytes, 19, 4, 7, 1)
                elseif value == "no_change" then
                    setBits(msgBytes, 19, 4, 7, 2)
                elseif value == "1" then
                    setBits(msgBytes, 19, 4, 7, 3)
                elseif value == "2" then
                    setBits(msgBytes, 19, 4, 7, 4)
                elseif value == "3" then
                    setBits(msgBytes, 19, 4, 7, 5)
                end
            elseif key == "anophelifuge" then
                if value == "on" then
                    setBits(msgBytes, 19, 2, 3, 1)
                elseif value == "off" then
                    setBits(msgBytes, 19, 2, 3, 2)
                end
            elseif key == "anion" then
                if value == "on" then
                    setBits(msgBytes, 19, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 19, 0, 1, 2)
                end
            elseif key == "timer_off_hour" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 24 then
                    setBits(msgBytes, 20, 0, 4, numTemp)
                end
            elseif key == "timer_off_minute" then
                if type(value) == "number" then
                    if value >= 1 and value <= 59 then
                        setBits(msgBytes, 20, 5, 7, quChu(value))
                        setBits(msgBytes, 24, 4, 7, quMo(value))
                    elseif value == 0 then
                        msgBytes[24] = 0
                    end
                else
                    if value == "clean" then
                        setBits(msgBytes, 20, 5, 7, 6)
                    else
                        numTemp = string2Int(value)
                        if numTemp >= 1 and numTemp <= 59 then
                            setBits(msgBytes, 20, 5, 7, quChu(numTemp))
                            setBits(msgBytes, 24, 4, 7, quMo(numTemp))
                        elseif numTemp == 0 then
                            msgBytes[24] = 0
                        end
                    end
                end
            elseif key == "timer_on_hour" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 24 then
                    setBits(msgBytes, 21, 0, 4, numTemp)
                end
            elseif key == "timer_on_minute" then
                if type(value) == "number" then
                    if value >= 1 and value <= 59 then
                        setBits(msgBytes, 21, 5, 7, quChu(value))
                        setBits(msgBytes, 24, 0, 3, quMo(value))
                    elseif value == 0 then
                        msgBytes[24] = 0
                    end
                else
                    if value == "clean" then
                        setBits(msgBytes, 21, 5, 7, 6)
                    else
                        numTemp = string2Int(value)
                        if numTemp >= 1 and numTemp <= 59 then
                            setBits(msgBytes, 21, 5, 7, quChu(numTemp))
                            setBits(msgBytes, 24, 0, 3, quMo(numTemp))
                        elseif numTemp == 0 then
                            msgBytes[24] = 0
                        end
                    end
                end
            elseif key == "lock" then
                if value == "on" then
                    msgBytes[28] = 1
                elseif value == "off" then
                    msgBytes[28] = 0
                else
                    msgBytes[28] = 0xFF
                end
            elseif key == "screen_close" then
                if value == "on" then
                    setBits(msgBytes, 29, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 29, 0, 1, 2)
                else
                    setBits(msgBytes, 29, 0, 1, 0)
                end
            elseif key == "waterions" then
                if value == "on" then
                    setBits(msgBytes, 29, 2, 3, 1)
                elseif value == "off" then
                    setBits(msgBytes, 29, 2, 3, 2)
                else
                    setBits(msgBytes, 29, 2, 3, 0)
                end
            elseif key == "fireLight" then
                if value == "off" then
                    setBits(msgBytes, 29, 4, 7, 1)
                elseif value == "1" then
                    setBits(msgBytes, 29, 4, 7, 2)
                elseif value == "2" then
                    setBits(msgBytes, 29, 4, 7, 3)
                elseif value == "3" then
                    setBits(msgBytes, 29, 4, 7, 4)
                elseif value == "4" then
                    setBits(msgBytes, 29, 4, 7, 5)
                else
                    setBits(msgBytes, 29, 4, 7, 0)
                end
            elseif key == "uvEnable" then
                if value == "on" then
                    setBits(msgBytes, 35, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 35, 0, 1, 2)
                else
                    setBits(msgBytes, 35, 0, 1, 0)
                end
            elseif key == "uvMinute" then
                local uvMinuteTemp = 0
                if type(value) == "number" then
                    uvMinuteTemp = value
                else
                    uvMinuteTemp = string2Int(value)
                end
                if uvMinuteTemp >= 1 and uvMinuteTemp <= 255 then
                    msgBytes[36] = uvMinuteTemp
                end
            elseif key == "hotDryMinute" then
                local hotDryMinuteTemp = 0
                if type(value) == "number" then
                    hotDryMinuteTemp = value
                else
                    hotDryMinuteTemp = string2Int(value)
                end
                if hotDryMinuteTemp >= 1 and hotDryMinuteTemp <= 255 then
                    msgBytes[37] = hotDryMinuteTemp
                end
            end
        end
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local infoM = {}
    for i = 1, msgLength + 1 do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonCmd)
    bitInit()
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if deviceSubType == nil then
        deviceSubType = 0
    else
        if type(deviceSubType) == "string" then
            deviceSubType = tonumber(deviceSubType)
        end
    end
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    info = string2table(binData)
    local dataType = info[10]
    if ((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04)) then
        return nil
    end
    local sub_cmd = getBits(info, 11, 2, 7)
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    local streams = {}
    if sub_cmd == 0 then
        streams["error_code"] = msgBytes[11]
        if msgBytes[12] == 1 then
            streams["voice"] = "open_gps"
        elseif msgBytes[12] == 2 then
            streams["voice"] = "close_gps"
        elseif msgBytes[12] == 4 then
            streams["voice"] = "open_buzzer"
        elseif msgBytes[12] == 5 then
            streams["voice"] = "open_tip"
        elseif msgBytes[12] == 8 then
            streams["voice"] = "close_buzzer"
        elseif msgBytes[12] == 10 then
            streams["voice"] = "mute"
        end
        local power = getBits(msgBytes, 10, 0, 1)
        if power == 0 or power == 2 then
            streams["power"] = "off"
        elseif power == 1 then
            streams["power"] = "on"
        end
        local mode = msgBytes[14]
        if mode == 0 then
            streams["mode"] = "invalid"
        elseif mode == 1 then
            streams["mode"] = "intelligent"
        elseif mode == 2 then
            streams["mode"] = "efficient"
        elseif mode == 3 then
            streams["mode"] = "sleep"
        elseif mode == 4 then
            streams["mode"] = "antifreezing"
        elseif mode == 5 then
            streams["mode"] = "comfort"
        elseif mode == 6 then
            streams["mode"] = "constant_temperature"
        elseif mode == 7 then
            streams["mode"] = "normal"
        elseif mode == 8 then
            streams["mode"] = "fast_hot"
        elseif mode == 10 then
            streams["mode"] = "idle_mode"
        elseif mode == 11 then
            streams["mode"] = "cold_air"
        elseif mode == 12 then
            streams["mode"] = "hot_house"
        elseif mode == 13 then
            streams["mode"] = "bath_mode"
        elseif mode == 14 then
            streams["mode"] = "hot_feet"
        elseif mode == 15 then
            streams["mode"] = "hot_dry"
        elseif mode == 16 then
            streams["mode"] = "light"
        elseif mode == 17 then
            streams["mode"] = "nature"
        end
        local gear = msgBytes[15]
        if gear >= 0 and gear <= 10 then streams["gear"] = gear end
        local temperature = msgBytes[16]
        if temperature >= 1 and temperature <= 91 then
            streams["temperature"] = temperature - 41
        elseif temperature == 87 or temperature == 0x80 then
            streams["temperature"] = 0x80
        end
        local humidity = msgBytes[17]
        if humidity >= 1 and humidity <= 100 then
            streams["humidity"] = humidity
        end
        local shake_switch = getBits(msgBytes, 18, 0, 1)
        if shake_switch == 1 then
            streams["shake_switch"] = "on"
        elseif shake_switch == 2 then
            streams["shake_switch"] = "off"
        elseif shake_switch == 0 then
            streams["shake_switch"] = "invalid"
        end
        local shake_type = getBits(msgBytes, 18, 2, 4)
        if shake_type == 1 then
            streams["shake_type"] = "lr"
        elseif shake_type == 2 then
            streams["shake_type"] = "ud"
        elseif shake_type == 3 then
            streams["shake_type"] = "8"
        elseif shake_type == 4 then
            streams["shake_type"] = "w"
        else
            streams["shake_type"] = "invalid"
        end
        local shake_angle = getBits(msgBytes, 18, 5, 7)
        if shake_angle == 1 then
            streams["shake_angle"] = "30"
        elseif shake_angle == 2 then
            streams["shake_angle"] = "60"
        elseif shake_angle == 3 then
            streams["shake_angle"] = "90"
        elseif shake_angle == 4 then
            streams["shake_angle"] = "180"
        elseif shake_angle == 5 then
            streams["shake_angle"] = "360"
        else
            streams["shake_angle"] = "invalid"
        end
        local humidification = getBits(msgBytes, 19, 4, 7)
        if humidification == 1 then
            streams["humidification"] = "off"
        elseif humidification == 2 then
            streams["humidification"] = "no_change"
        elseif humidification == 3 then
            streams["humidification"] = "1"
        elseif humidification == 4 then
            streams["humidification"] = "2"
        elseif humidification == 5 then
            streams["humidification"] = "3"
        end
        local anophelifuge = getBits(msgBytes, 19, 2, 3)
        if anophelifuge == 1 then
            streams["anophelifuge"] = "on"
        elseif anophelifuge == 2 then
            streams["anophelifuge"] = "off"
        end
        local anion = getBits(msgBytes, 19, 0, 1)
        if anion == 1 then
            streams["anion"] = "on"
        elseif anion == 2 then
            streams["anion"] = "off"
        end
        local timer_off_hour = getBits(msgBytes, 20, 0, 4)
        local timer_off_minute = getBits(msgBytes, 20, 5, 7) * 10 +
                                     getBits(msgBytes, 24, 4, 7)
        if timer_off_hour >= 0 and timer_off_hour <= 24 then
            streams["timer_off_hour"] = timer_off_hour
        end
        if timer_off_minute >= 0 and timer_off_minute <= 59 then
            streams["timer_off_minute"] = timer_off_minute
        end
        local timer_on_hour = getBits(msgBytes, 21, 0, 4)
        local timer_on_minute = getBits(msgBytes, 21, 5, 7) * 10 +
                                    getBits(msgBytes, 24, 0, 3)
        if timer_on_hour >= 0 and timer_on_hour <= 24 then
            streams["timer_on_hour"] = timer_on_hour
        end
        if timer_on_minute >= 0 and timer_on_minute <= 59 then
            streams["timer_on_minute"] = timer_on_minute
        end
        local humidify_feedback = msgBytes[22]
        if humidify_feedback >= 1 and humidify_feedback <= 100 then
            streams["cur_humidity"] = humidify_feedback
        end
        local temperature_feedback = msgBytes[23]
        streams["cur_temperature"] = temperature_feedback - 41
        if #info >= 30 then
            local lock = getBits(msgBytes, 28, 0, 1)
            if lock == 1 then
                streams["lock"] = "on"
            elseif lock == 0 then
                streams["lock"] = "off"
            end
        end
        if #info >= 31 then
            local screen_close = getBits(msgBytes, 29, 0, 1)
            if screen_close == 1 then
                streams["screen_close"] = "on"
            elseif screen_close == 2 then
                streams["screen_close"] = "off"
            end
            local waterions = getBits(msgBytes, 29, 2, 3)
            if waterions == 1 then
                streams["waterions"] = "on"
            elseif waterions == 2 then
                streams["waterions"] = "off"
            end
            local fireLight = getBits(msgBytes, 29, 4, 7)
            if fireLight == 1 then
                streams["fireLight"] = "off"
            elseif fireLight == 2 then
                streams["fireLight"] = "1"
            elseif fireLight == 3 then
                streams["fireLight"] = "2"
            elseif fireLight == 4 then
                streams["fireLight"] = "3"
            elseif fireLight == 5 then
                streams["fireLight"] = "4"
            end
        end
        if #info >= 33 then
            streams["power_statistics"] = msgBytes[31] * 256 + msgBytes[30]
        end
        if #info >= 34 then streams["protocol_version"] = msgBytes[32] end
        if #info >= 36 then
            streams["running_time"] = msgBytes[34] * 256 + msgBytes[33]
        end
        if #info >= 37 then
            local uvEnable = getBits(msgBytes, 35, 0, 1)
            if uvEnable == 1 then
                streams["uvEnable"] = "on"
            elseif uvEnable == 2 then
                streams["uvEnable"] = "off"
            end
            local uvMinute = msgBytes[36]
            if uvMinute >= 1 and uvMinute <= 255 then
                streams["uvMinute"] = uvMinute
            end
        end
        if #info >= 38 then
            local hotDryMinute = msgBytes[37]
            if hotDryMinute >= 1 and hotDryMinute <= 255 then
                streams["hotDryMinute"] = hotDryMinute
            end
        end
    end
    if sub_cmd == 1 then end
    if sub_cmd == 2 then streams["guowangData"] = string.sub(binData, 23, -3) end
    streams["version"] = VALUE_VERSION
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
