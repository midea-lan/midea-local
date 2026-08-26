local bit = require "bit"
local JSON = require "cjson"
local _bit = require "bit"
local bit = {datagBitLen = {}}
local gBitLen = 32
local isBitInit = false
local VALUE_VERSION = 17
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
    if pBytes[pIndex] then return _getBit(pBytes[pIndex], pBitIndex); end
    return nil
end
local function setBit(pBytes, pIndex, pBitIndex, pValue)
    if pBytes[pIndex] then
        pBytes[pIndex] = _setBit(pBytes[pIndex], pBitIndex, pValue);
    end
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
    if pBytes[pIndex] then
        return _getBits(pBytes[pIndex], pBitStartIndex, pBitEndIndex);
    end
    return nil
end
local function setBits(pBytes, pIndex, pBitStartIndex, pBitEndIndex, pValue)
    if pBytes[pIndex] then
        pBytes[pIndex] = _setBits(pBytes[pIndex], pBitStartIndex, pBitEndIndex,
                                  pValue);
    end
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
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = _bit.bnot(resVal) + 1
    resVal = _bit.band(resVal, 0x00FF)
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
function jsonToData(jsonCmd)
    bitInit()
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if type(deviceSubType) == "string" then
        deviceSubType = tonumber(deviceSubType)
    end
    local query = json["query"]
    local control = json["control"]
    local bodyLength
    if (query) then
        bodyLength = 0
    elseif (control) then
        if deviceSubType == 0xA1 then
            bodyLength = 19
        else
            if deviceSubType <= 0x0A then
                bodyLength = 19
            else
                bodyLength = 50
            end
        end
    end
    local msgLength = bodyLength + 0x0A
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = 0xAA
    msgBytes[1] = bodyLength + 0x0A
    msgBytes[2] = 0xFA
    if (query) then
        msgBytes[9] = 0x03
    elseif (control) then
        msgBytes[9] = 0x02
        setBit(msgBytes, 14, 7, 1)
        setBit(msgBytes, 18, 7, 1)
        if deviceSubType == 0xA1 then
            msgBytes[24] = 0xFF
        else
            if deviceSubType < 0x0A then msgBytes[24] = 0xFF end
        end
        local numTemp = 0
        for key, value in pairs(control) do
            if key == "power" then
                if value == "on" then
                    setBit(msgBytes, 14, 0, 1)
                    setBit(msgBytes, 14, 7, 0)
                elseif value == "off" then
                    setBit(msgBytes, 14, 0, 0)
                    setBit(msgBytes, 14, 7, 0)
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
            elseif key == "lock" then
                if value == "on" then
                    setBits(msgBytes, 13, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 13, 0, 1, 2)
                end
            elseif key == "mode" then
                if value == "normal" then
                    setBits(msgBytes, 14, 1, 4, 1)
                elseif value == "natural" then
                    setBits(msgBytes, 14, 1, 4, 2)
                elseif value == "sleep" then
                    setBits(msgBytes, 14, 1, 4, 3)
                elseif value == "comfort" then
                    setBits(msgBytes, 14, 1, 4, 4)
                elseif value == "mute" then
                    setBits(msgBytes, 14, 1, 4, 5)
                elseif value == "baby" then
                    setBits(msgBytes, 14, 1, 4, 6)
                elseif value == "feel" then
                    setBits(msgBytes, 14, 1, 4, 7)
                elseif value == "storm" then
                    setBits(msgBytes, 14, 1, 4, 8)
                elseif value == "strong" then
                    setBits(msgBytes, 14, 1, 4, 9)
                elseif value == "soft" then
                    setBits(msgBytes, 14, 1, 4, 10)
                elseif value == "customize" then
                    setBits(msgBytes, 14, 1, 4, 11)
                end
            elseif key == "gear" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 26 then
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
            elseif key == "swing" then
                if value == "on" then
                    setBit(msgBytes, 18, 0, 1)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "off" then
                    setBit(msgBytes, 18, 0, 0)
                    setBit(msgBytes, 18, 7, 0)
                end
            elseif key == "swing_angle" then
                if value == "30" then
                    setBits(msgBytes, 18, 4, 6, 1)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "60" then
                    setBits(msgBytes, 18, 4, 6, 2)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "90" then
                    setBits(msgBytes, 18, 4, 6, 3)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "120" then
                    setBits(msgBytes, 18, 4, 6, 4)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "180" then
                    setBits(msgBytes, 18, 4, 6, 5)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "360" then
                    setBits(msgBytes, 18, 4, 6, 6)
                    setBit(msgBytes, 18, 7, 0)
                end
            elseif key == "swing_direction" then
                if value == "lr" then
                    setBits(msgBytes, 18, 1, 3, 1)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "ud" then
                    setBits(msgBytes, 18, 1, 3, 2)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "w" then
                    setBits(msgBytes, 18, 1, 3, 3)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "8" then
                    setBits(msgBytes, 18, 1, 3, 4)
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "udlr" then
                    setBits(msgBytes, 18, 1, 3, 6)
                    setBit(msgBytes, 18, 7, 0)
                end
            elseif key == "humidify" then
                if value == "off" then
                    setBits(msgBytes, 19, 4, 7, 1)
                elseif value == "1" then
                    setBits(msgBytes, 19, 4, 7, 2)
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
            elseif key == "body_feeling_scan" then
                if value == "on" then
                    msgBytes[25] = 1
                elseif value == "off" then
                    msgBytes[25] = 2
                end
            elseif key == "scene" then
                if value == "old" then
                    msgBytes[26] = 1
                elseif value == "child" then
                    msgBytes[26] = 2
                elseif value == "read" then
                    msgBytes[26] = 3
                elseif value == "sleep" then
                    msgBytes[26] = 4
                elseif value == "ac" then
                    msgBytes[26] = 5
                end
            elseif key == "sleep_sensor" then
                if value == "sleep" then
                    msgBytes[27] = 1
                elseif value == "wake" then
                    msgBytes[27] = 2
                elseif value == "leave" then
                    msgBytes[27] = 3
                end
            elseif key == "spin_switch" then
                if value == "on" then
                    setBits(msgBytes, 29, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 29, 0, 1, 2)
                end
            elseif key == "air_dry_switch" then
                if value == "on" then
                    setBits(msgBytes, 29, 2, 3, 1)
                elseif value == "off" then
                    setBits(msgBytes, 29, 2, 3, 2)
                end
            elseif key == "temp_wind_switch" then
                if value == "on" then
                    setBits(msgBytes, 29, 4, 5, 1)
                elseif value == "off" then
                    setBits(msgBytes, 29, 4, 5, 2)
                end
            elseif key == "display_on_off" then
                if value == "on" then
                    setBits(msgBytes, 29, 6, 7, 1)
                elseif value == "off" then
                    setBits(msgBytes, 29, 6, 7, 2)
                end
            elseif key == "breath_light" then
                if value == "on" then
                    setBits(msgBytes, 34, 2, 3, 1)
                elseif value == "off" then
                    setBits(msgBytes, 34, 2, 3, 2)
                end
            elseif key == "ud_swing_angle" then
                if value == "30" then
                    msgBytes[35] = 1
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "60" then
                    msgBytes[35] = 2
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "90" then
                    msgBytes[35] = 3
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "120" then
                    msgBytes[35] = 4
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "180" then
                    msgBytes[35] = 5
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "360" then
                    msgBytes[35] = 6
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "+60" then
                    msgBytes[35] = 7
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "-60" then
                    msgBytes[35] = 8
                    setBit(msgBytes, 18, 7, 0)
                elseif value == "40" then
                    msgBytes[35] = 9
                    setBit(msgBytes, 18, 7, 0)
                end
            elseif key == "lr_diy_down_percent" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 100 then
                    msgBytes[36] = numTemp
                end
            elseif key == "lr_diy_up_percent" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 100 then
                    msgBytes[37] = numTemp
                end
            elseif key == "ud_diy_down_percent" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 100 then
                    msgBytes[38] = numTemp
                end
            elseif key == "ud_diy_up_percent" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 100 then
                    msgBytes[39] = numTemp
                end
            elseif key == "real_gear" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 0 and numTemp <= 26 then
                    msgBytes[40] = numTemp
                end
            elseif key == "back_gear" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 26 then
                    msgBytes[41] = numTemp
                end
            elseif key == "dust_life_time" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 0 and numTemp <= 255 then
                    msgBytes[42] = numTemp
                end
            elseif key == "filter_life_time" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 0 and numTemp <= 255 then
                    msgBytes[43] = numTemp
                end
            elseif key == "waterions" then
                if value == "on" then
                    setBits(msgBytes, 44, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 44, 0, 1, 2)
                end
            elseif key == "filter_reset" then
                if value == "on" then
                    setBit(msgBytes, 44, 6, 1)
                elseif value == "off" then
                    setBit(msgBytes, 44, 6, 0)
                end
            elseif key == "dust_reset" then
                if value == "on" then
                    setBit(msgBytes, 44, 7, 1)
                elseif value == "off" then
                    setBit(msgBytes, 44, 7, 0)
                end
            elseif key == "lr_diy_swing" then
                if value == "on" then
                    setBits(msgBytes, 45, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 45, 0, 1, 2)
                end
            elseif key == "ud_diy_swing" then
                if value == "on" then
                    setBits(msgBytes, 45, 2, 3, 1)
                elseif value == "off" then
                    setBits(msgBytes, 45, 2, 3, 2)
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
    if (not jsonCmd) then
        return encode({["status"] = {["version"] = VALUE_VERSION}})
    end
    local json = decode(jsonCmd)
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    info = string2table(binData)
    local dataType = info[10]
    if ((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04)) then
        return encode({["status"] = {["version"] = VALUE_VERSION}})
    end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    local streams = {}
    if #msgBytes == 10 then
        return encode({["status"] = {["version"] = VALUE_VERSION}})
    end
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
    local lock = getBits(msgBytes, 13, 0, 1)
    if lock == 1 then
        streams["lock"] = "on"
    elseif lock == 2 then
        streams["lock"] = "off"
    end
    local power = getBit(msgBytes, 14, 0)
    if power == 0 then
        streams["power"] = "off"
    elseif power == 1 then
        streams["power"] = "on"
    end
    local mode = getBits(msgBytes, 14, 1, 4)
    if mode == 1 then
        streams["mode"] = "normal"
    elseif mode == 2 then
        streams["mode"] = "natural"
    elseif mode == 3 then
        streams["mode"] = "sleep"
    elseif mode == 4 then
        streams["mode"] = "comfort"
    elseif mode == 5 then
        streams["mode"] = "mute"
    elseif mode == 6 then
        streams["mode"] = "baby"
    elseif mode == 7 then
        streams["mode"] = "feel"
    elseif mode == 8 then
        streams["mode"] = "storm"
    elseif mode == 9 then
        streams["mode"] = "strong"
    elseif mode == 10 then
        streams["mode"] = "soft"
    elseif mode == 11 then
        streams["mode"] = "customize"
    end
    local gear = msgBytes[15]
    if gear >= 1 and gear <= 26 then streams["gear"] = gear end
    local temperature = msgBytes[16]
    if temperature >= 1 and temperature <= 91 then
        streams["temperature"] = temperature - 41
    end
    local humidity = msgBytes[17]
    if humidity >= 1 and humidity <= 100 then streams["humidity"] = humidity end
    local swing = getBit(msgBytes, 18, 0)
    local swing_angle = getBits(msgBytes, 18, 4, 6)
    local swing_direction = getBits(msgBytes, 18, 1, 3)
    if swing == 0 then
        streams["swing"] = "off"
    elseif swing == 1 then
        streams["swing"] = "on"
    end
    if swing_angle == 1 then
        streams["swing_angle"] = "30"
    elseif swing_angle == 2 then
        streams["swing_angle"] = "60"
    elseif swing_angle == 3 then
        streams["swing_angle"] = "90"
    elseif swing_angle == 4 then
        streams["swing_angle"] = "120"
    elseif swing_angle == 5 then
        streams["swing_angle"] = "180"
    elseif swing_angle == 6 then
        streams["swing_angle"] = "360"
    elseif swing_angle == 0 then
        streams["swing_angle"] = "unknown"
    end
    if swing_direction == 1 then
        streams["swing_direction"] = "lr"
    elseif swing_direction == 2 then
        streams["swing_direction"] = "ud"
    elseif swing_direction == 3 then
        streams["swing_direction"] = "w"
    elseif swing_direction == 4 then
        streams["swing_direction"] = "8"
    elseif swing_direction == 6 then
        streams["swing_direction"] = "udlr"
    elseif swing_direction == 0 then
        streams["swing_direction"] = "unknown"
    end
    local humidify = getBits(msgBytes, 19, 4, 7)
    if humidify == 1 then
        streams["humidify"] = "off"
    elseif humidify == 2 then
        streams["humidify"] = "1"
    elseif humidify == 4 then
        streams["humidify"] = "2"
    elseif humidify == 5 then
        streams["humidify"] = "3"
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
        streams["humidify_feedback"] = humidify_feedback
    end
    local temperature_feedback = msgBytes[23]
    if temperature_feedback >= 1 and temperature_feedback <= 91 then
        streams["temperature_feedback"] = temperature_feedback - 41
    end
    local body_feeling_scan = msgBytes[25]
    if body_feeling_scan == 1 then
        streams["body_feeling_scan"] = "on"
    elseif body_feeling_scan == 2 then
        streams["body_feeling_scan"] = "off"
    end
    local scene = msgBytes[26]
    if scene == 0 then
        streams["scene"] = "none"
    elseif scene == 1 then
        streams["scene"] = "old"
    elseif scene == 2 then
        streams["scene"] = "child"
    elseif scene == 3 then
        streams["scene"] = "read"
    elseif scene == 4 then
        streams["scene"] = "sleep"
    elseif scene == 5 then
        streams["scene"] = "ac"
    end
    local sleep_sensor = msgBytes[27]
    if sleep_sensor == 0 then
        streams["sleep_sensor"] = "none"
    elseif sleep_sensor == 1 then
        streams["sleep_sensor"] = "sleep"
    elseif sleep_sensor == 2 then
        streams["sleep_sensor"] = "wake"
    elseif sleep_sensor == 3 then
        streams["sleep_sensor"] = "leave"
    end
    if (#msgBytes) > 29 then
        local spin_switch = getBits(msgBytes, 29, 0, 1)
        if spin_switch == 1 then
            streams["spin_switch"] = "on"
        elseif spin_switch == 2 then
            streams["spin_switch"] = "off"
        end
        local air_dry_switch = getBits(msgBytes, 29, 2, 3)
        if air_dry_switch == 1 then
            streams["air_dry_switch"] = "on"
        elseif air_dry_switch == 2 then
            streams["air_dry_switch"] = "off"
        end
        local temp_wind_switch = getBits(msgBytes, 29, 4, 5)
        if temp_wind_switch == 1 then
            streams["temp_wind_switch"] = "on"
        elseif temp_wind_switch == 2 then
            streams["temp_wind_switch"] = "off"
        end
        local display_on_off = getBits(msgBytes, 29, 6, 7)
        if display_on_off == 1 then
            streams["display_on_off"] = "on"
        elseif display_on_off == 2 then
            streams["display_on_off"] = "off"
        end
    end
    if (#msgBytes) > 34 then
        local water_feedback = getBits(msgBytes, 34, 0, 1)
        if water_feedback == 1 then
            streams["water_feedback"] = "shortage"
        elseif water_feedback == 2 then
            streams["water_feedback"] = "full"
        elseif water_feedback == 0 then
            streams["water_feedback"] = "invalid"
        end
        local breath_light = getBits(msgBytes, 34, 2, 3)
        if breath_light == 1 then
            streams["breath_light"] = "on"
        elseif breath_light == 2 then
            streams["breath_light"] = "off"
        end
    end
    if (#msgBytes) > 35 then
        local ud_swing_angle = msgBytes[35]
        if ud_swing_angle == 1 then
            streams["ud_swing_angle"] = "30"
        elseif ud_swing_angle == 2 then
            streams["ud_swing_angle"] = "60"
        elseif ud_swing_angle == 3 then
            streams["ud_swing_angle"] = "90"
        elseif ud_swing_angle == 4 then
            streams["ud_swing_angle"] = "120"
        elseif ud_swing_angle == 5 then
            streams["ud_swing_angle"] = "180"
        elseif ud_swing_angle == 6 then
            streams["ud_swing_angle"] = "360"
        elseif ud_swing_angle == 7 then
            streams["ud_swing_angle"] = "+60"
        elseif ud_swing_angle == 8 then
            streams["ud_swing_angle"] = "-60"
        elseif ud_swing_angle == 9 then
            streams["ud_swing_angle"] = "40"
        elseif ud_swing_angle == 0 then
            streams["ud_swing_angle"] = "unknown"
        end
    end
    if (#msgBytes) > 36 then
        local lr_diy_down_percent = msgBytes[36]
        if lr_diy_down_percent ~= nil and lr_diy_down_percent >= 0 and
            lr_diy_down_percent <= 100 then
            streams["lr_diy_down_percent"] = lr_diy_down_percent
        end
    end
    if (#msgBytes) > 37 then
        local lr_diy_up_percent = msgBytes[37]
        if lr_diy_up_percent ~= nil and lr_diy_up_percent >= 0 and
            lr_diy_up_percent <= 100 then
            streams["lr_diy_up_percent"] = lr_diy_up_percent
        end
    end
    if (#msgBytes) > 38 then
        local ud_diy_down_percent = msgBytes[38]
        if ud_diy_down_percent ~= nil and ud_diy_down_percent >= 0 and
            ud_diy_down_percent <= 100 then
            streams["ud_diy_down_percent"] = ud_diy_down_percent
        end
    end
    if (#msgBytes) > 39 then
        local ud_diy_up_percent = msgBytes[39]
        if ud_diy_up_percent ~= nil and ud_diy_up_percent >= 0 and
            ud_diy_up_percent <= 100 then
            streams["ud_diy_up_percent"] = ud_diy_up_percent
        end
    end
    if (#msgBytes) > 40 then
        local real_gear = msgBytes[40]
        if real_gear ~= nil and real_gear >= 0 and real_gear <= 26 then
            streams["real_gear"] = real_gear
        end
    end
    if (#msgBytes) > 41 then
        local back_gear = msgBytes[41]
        if back_gear ~= nil and back_gear >= 1 and back_gear <= 26 then
            streams["back_gear"] = back_gear
        end
    end
    if (#msgBytes) > 42 then
        local dust_life_time = msgBytes[42]
        if dust_life_time ~= nil and dust_life_time >= 0 and dust_life_time <=
            255 then streams["dust_life_time"] = dust_life_time end
    end
    if (#msgBytes) > 43 then
        local filter_life_time = msgBytes[43]
        if filter_life_time ~= nil and filter_life_time >= 0 and
            filter_life_time <= 255 then
            streams["filter_life_time"] = filter_life_time
        end
    end
    if (#msgBytes) > 44 then
        local waterions = getBits(msgBytes, 44, 0, 1)
        if waterions == 1 then
            streams["waterions"] = "on"
        elseif waterions == 2 then
            streams["waterions"] = "off"
        end
        local filter_replace_info = getBits(msgBytes, 44, 2, 3)
        if filter_replace_info == 1 then
            streams["filter_replace_info"] = "on"
        elseif filter_replace_info == 2 then
            streams["filter_replace_info"] = "off"
        end
        local dust_info = getBits(msgBytes, 44, 4, 5)
        if dust_info == 1 then
            streams["dust_info"] = "on"
        elseif dust_info == 2 then
            streams["dust_info"] = "off"
        end
        local filter_reset = getBit(msgBytes, 44, 6)
        if filter_reset == 1 then
            streams["filter_reset"] = "on"
        elseif filter_reset == 0 then
            streams["filter_reset"] = "off"
        end
        local dust_reset = getBit(msgBytes, 44, 7)
        if dust_reset == 1 then
            streams["dust_reset"] = "on"
        elseif dust_reset == 0 then
            streams["dust_reset"] = "off"
        end
    end
    if (#msgBytes) > 45 then
        local lr_diy_swing = getBits(msgBytes, 45, 0, 1)
        if lr_diy_swing == 1 then
            streams["lr_diy_swing"] = "on"
        elseif lr_diy_swing == 2 then
            streams["lr_diy_swing"] = "off"
        end
        local ud_diy_swing = getBits(msgBytes, 45, 2, 3)
        if ud_diy_swing == 1 then
            streams["ud_diy_swing"] = "on"
        elseif ud_diy_swing == 2 then
            streams["ud_diy_swing"] = "off"
        end
    end
    streams["version"] = VALUE_VERSION
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
