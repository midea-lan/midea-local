local bit = require "bit"
local JSON = require "cjson"
local _bit = require "bit"
local protocol_version = 6
local VALUE_VERSION = 2
local modeTab = {
    "normal",
    "natural",
    "sleep",
    "comfort",
    "mute",
    "baby",
    "feel",
    "storm",
    "strong",
    "soft",
    "customize",
    "warm",
    "smart",
    "ionic",
    "ai_smart",
    "double_area",
    "purified_wind",
    "sleeping_wind",
    "purify_only",
    "self_selection",
    "ecology",
    [0] = "invalid"
}
local humidifyTab = {"off", "no_change", "1", "2", "3", [0] = "invalid"}
local swingDirectionTab = {
    "lr",
    "ud",
    "w",
    "8",
    "invalid",
    "udlr",
    "custom",
    [0] = "invalid"
}
local voiceTab = {
    "open_gps",
    "close_gps",
    "invalid",
    "open_buzzer",
    "open_tip",
    [8] = "close_buzzer",
    [10] = "mute"
}
local bit = {datagBitLen = {}}
local gBitLen = 32
local isBitInit = false
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
local function getIndexFromValueTab(table, value, defaultIndex)
    for k, v in pairs(table) do if value == v then return k end end
    if defaultIndex then return defaultIndex end
    return nil
end
local function getValueFromValueTab(table, index, defaultValue)
    local result = table[index]
    if result == nil then result = defaultValue end
    return result
end
local function makeSetBTMacOrder(control)
    local msgBytes = {}
    local msgLength = 12 + control["btCount"] * 6
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = 0xAA
    msgBytes[1] = msgLength
    msgBytes[2] = 0xFA
    msgBytes[8] = 2;
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
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local infoM = {}
    for i = 1, msgLength + 1 do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
local function processSwing(msgBytes, control)
    local lrSwitch = control.lr_shake_switch
    if lrSwitch ~= nil then
        local diyOn, lrAngle, lDiyAngle, rDiyAngle
        if lrSwitch == "off" then
            diyOn = 2
            lrAngle = 0
        elseif lrSwitch == "default" then
            diyOn = 2
            lrAngle = 0xfe
        elseif lrSwitch == "normal" then
            diyOn = 2
            if control.lr_angle ~= nil then
                lrAngle = math.floor(tonumber(control.lr_angle) / 5)
            else
                lrAngle = 0xff
            end
        elseif lrSwitch == "diy" then
            diyOn = 1
            lDiyAngle = control.lr_diy_angle_down ~= nil and
                            control.lr_diy_angle_down or 0
            rDiyAngle = control.lr_diy_angle_up ~= nil and
                            control.lr_diy_angle_up or 0
        end
        setBits(msgBytes, 45, 0, 1, diyOn)
        if diyOn == 2 then
            msgBytes[61] = lrAngle
            msgBytes[36] = 0xff
            msgBytes[37] = 0xff
            msgBytes[38] = 0xff
            msgBytes[39] = 0xff
        elseif diyOn == 1 then
            msgBytes[61] = 0xff
            msgBytes[36] = lDiyAngle % 256
            msgBytes[37] = (lDiyAngle - msgBytes[36]) / 256
            msgBytes[38] = rDiyAngle % 256
            msgBytes[39] = (rDiyAngle - msgBytes[38]) / 256
        end
    else
        setBits(msgBytes, 45, 2, 3, 0)
        msgBytes[61] = 0xff
        msgBytes[36] = 0xff
        msgBytes[37] = 0xff
        msgBytes[38] = 0xff
        msgBytes[39] = 0xff
    end
    local udSwitch = control.ud_shake_switch
    if udSwitch ~= nil then
        local udType, udAngle, dDiyAngle, uDiyAngle
        if udSwitch == "off" then
            udType = 2
            udAngle = 0
        elseif udSwitch == "default" then
            udType = 2
            udAngle = 0xfe
        elseif udSwitch == "normal" then
            udType = 2
            if control.ud_angle ~= nil then
                udAngle = math.floor(tonumber(control.ud_angle) / 5)
            else
                udAngle = 0xff
            end
        elseif udSwitch == "diy" then
            udType = 1
            dDiyAngle = control.ud_diy_angle_down ~= nil and
                            control.ud_diy_angle_down or 0
            uDiyAngle = control.ud_diy_angle_up ~= nil and
                            control.ud_diy_angle_up or 0
        end
        setBits(msgBytes, 45, 2, 3, udType)
        if udType == 2 then
            msgBytes[35] = udAngle
            msgBytes[64] = 0xff
            msgBytes[65] = 0xff
            msgBytes[66] = 0xff
            msgBytes[67] = 0xff
        elseif udType == 1 then
            msgBytes[35] = 0xff
            msgBytes[64] = uDiyAngle % 256
            msgBytes[65] = (uDiyAngle - msgBytes[64]) / 256
            msgBytes[66] = dDiyAngle % 256
            msgBytes[67] = (dDiyAngle - msgBytes[66]) / 256
        end
    else
        setBits(msgBytes, 45, 2, 3, 0)
        msgBytes[35] = 0xff
        msgBytes[64] = 0xff
        msgBytes[65] = 0xff
        msgBytes[66] = 0xff
        msgBytes[67] = 0xff
    end
end
function jsonToData(jsonCmd)
    bitInit()
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local query = json["query"]
    local control = json["control"]
    local bodyLength
    if (query) then
        if query["type"] ~= nil and query["type"] == "btMac" then
            return "aa0bfa000000000000030cec"
        end
        bodyLength = 0
    elseif (control) then
        if control["setBtMacs"] ~= nil then
            return makeSetBTMacOrder(control)
        end
        bodyLength = 63
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
        msgBytes[35] = 0xff
        msgBytes[36] = 0xff
        msgBytes[37] = 0xff
        msgBytes[38] = 0xff
        msgBytes[39] = 0xff
        msgBytes[48] = 0xff
        msgBytes[55] = 0xff
        msgBytes[56] = 0xff
        for k = 61, 72 do msgBytes[k] = 0xff end
        setBit(msgBytes, 14, 7, 1)
        setBit(msgBytes, 18, 7, 1)
        local numTemp = 0
        msgBytes[33] = protocol_version
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
                msgBytes[12] = getIndexFromValueTab(voiceTab, value, 0)
            elseif key == "lock" then
                if value == "on" then
                    setBits(msgBytes, 13, 0, 1, 1)
                elseif value == "off" then
                    setBits(msgBytes, 13, 0, 1, 2)
                end
            elseif key == "silence_ctrl" then
                if value == "enable" then
                    setBit(msgBytes, 13, 2, 1)
                elseif value == "disable" then
                    setBit(msgBytes, 13, 2, 0)
                end
            elseif key == "mode" then
                local modeValue = getIndexFromValueTab(modeTab, value, 0)
                setBits(msgBytes, 14, 1, 5, modeValue)
            elseif key == "gear" then
                if type(value) == "number" then
                    numTemp = value
                else
                    numTemp = string2Int(value)
                end
                if numTemp >= 1 and numTemp <= 100 then
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
                elseif numTemp == 0x80 then
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
            elseif key == "humidify" then
                local humidifyValue =
                    getIndexFromValueTab(humidifyTab, value, 0);
                setBits(msgBytes, 19, 4, 7, humidifyValue)
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
                elseif value == "on1" then
                    setBits(msgBytes, 29, 6, 7, 3)
                end
            elseif key == "breath_light" then
                if value == "on" then
                    setBits(msgBytes, 34, 2, 3, 1)
                elseif value == "off" then
                    setBits(msgBytes, 34, 2, 3, 2)
                end
            elseif key == "electrolytic_water" then
                if value == "on" then
                    setBits(msgBytes, 34, 4, 5, 1)
                elseif value == "off" then
                    setBits(msgBytes, 34, 4, 5, 2)
                end
            elseif key == "auto_power_off" then
                if value == "on" then
                    setBits(msgBytes, 34, 6, 7, 1)
                elseif value == "off" then
                    setBits(msgBytes, 34, 6, 7, 2)
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
            elseif key == "charge" then
                if value == "on" then
                    setBits(msgBytes, 45, 4, 5, 1)
                elseif value == "off" then
                    setBits(msgBytes, 45, 4, 5, 2)
                end
            elseif key == "windSpeedPercent" and value < 101 then
                msgBytes[48] = value
            elseif key == "target_angle" then
                msgBytes[55] = tonumber(value) % 256
                msgBytes[56] = (tonumber(value) - msgBytes[55]) / 256
            elseif key == "area1_time" then
                msgBytes[57] = value
            elseif key == "area2_time" then
                msgBytes[58] = value
            elseif key == "area1_gear" then
                msgBytes[59] = value
            elseif key == "area2_gear" then
                msgBytes[60] = value
            elseif key == "ud_target_angle" then
                msgBytes[68] = tonumber(value) % 256
                msgBytes[69] = (tonumber(value) - msgBytes[68]) / 256
            elseif key == "ambient_lighting" then
                msgBytes[72] = tonumber(value)
            end
        end
        processSwing(msgBytes, control)
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local infoM = {}
    for i = 1, msgLength + 1 do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
local function processSwingToJson(msgBytes, streams)
    local lrTypeValue = getBits(msgBytes, 45, 0, 1)
    local lrAngleValue = msgBytes[61]
    if lrTypeValue == 2 or lrTypeValue == 0 then
        if lrAngleValue == 0 then
            streams.lr_shake_switch = "off"
        elseif lrAngleValue == 0xfe then
            streams.lr_shake_switch = "default"
        elseif lrAngleValue == 0xff then
            streams.lr_shake_switch = "invalid"
        else
            streams.lr_shake_switch = "normal"
            streams.lr_angle = lrAngleValue * 5
        end
    elseif lrTypeValue == 1 then
        streams.lr_shake_switch = "diy"
    else
        streams.lr_shake_switch = "invalid"
    end
    streams.lr_diy_angle_down = msgBytes[36] + msgBytes[37] * 256
    streams.lr_diy_angle_up = msgBytes[38] + msgBytes[39] * 256
    local udTypeValue = getBits(msgBytes, 45, 2, 3)
    local udAngleValue = msgBytes[35]
    if udTypeValue ~= 1 then
        if udAngleValue == 0 then
            streams.ud_shake_switch = "off"
        elseif udAngleValue == 0xfe then
            streams.ud_shake_switch = "default"
        elseif udAngleValue == 0xff then
            streams.ud_shake_switch = "invalid"
        else
            streams.ud_shake_switch = "normal"
            streams.ud_angle = udAngleValue * 5
        end
    else
        streams.ud_shake_switch = "diy"
    end
    streams.ud_diy_angle_down = msgBytes[66] + msgBytes[67] * 256
    streams.ud_diy_angle_up = msgBytes[64] + msgBytes[65] * 256
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
    local sub_cmd = info[11]
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    local streams = {}
    if sub_cmd == 0 then
        if #msgBytes == 10 then
            return encode({["status"] = {["version"] = VALUE_VERSION}})
        end
        streams["protocol_version"] = msgBytes[33]
        streams["error_code"] = msgBytes[11]
        streams["voice"] = getValueFromValueTab(voiceTab, msgBytes[12],
                                                "invalid")
        local lock = getBits(msgBytes, 13, 0, 1)
        if lock == 1 then
            streams["lock"] = "on"
        elseif lock == 2 then
            streams["lock"] = "off"
        end
        local propertyTemp = getBit(msgBytes, 13, 3)
        streams["auto_power_off_flag"] = propertyTemp
        local power = getBit(msgBytes, 14, 0)
        if power == 0 then
            streams["power"] = "off"
        elseif power == 1 then
            streams["power"] = "on"
        end
        local mode = getBits(msgBytes, 14, 1, 5)
        streams["mode"] = modeTab[mode]
        local gear = msgBytes[15]
        if gear >= 1 and gear <= 100 then streams["gear"] = gear end
        local temperature = msgBytes[16]
        if temperature >= 1 and temperature <= 91 then
            streams["temperature"] = temperature - 41
        elseif temperature == 0x80 then
            streams["temperature"] = 0x80
        end
        local humidity = msgBytes[17]
        if humidity >= 1 and humidity <= 100 then
            streams["humidity"] = humidity
        end
        local humidifyValue = getBits(msgBytes, 19, 4, 7)
        streams["humidify"] = humidifyTab[humidifyValue]
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
        if (#msgBytes) > 29 then
            propertyTemp = getBits(msgBytes, 29, 0, 1)
            if propertyTemp == 1 then
                streams["spin_switch"] = "on"
            elseif propertyTemp == 2 then
                streams["spin_switch"] = "off"
            end
            propertyTemp = getBits(msgBytes, 29, 2, 3)
            if propertyTemp == 1 then
                streams["air_dry_switch"] = "on"
            elseif propertyTemp == 2 then
                streams["air_dry_switch"] = "off"
            end
            propertyTemp = getBits(msgBytes, 29, 4, 5)
            if propertyTemp == 1 then
                streams["temp_wind_switch"] = "on"
            elseif propertyTemp == 2 then
                streams["temp_wind_switch"] = "off"
            end
            propertyTemp = getBits(msgBytes, 29, 6, 7)
            if propertyTemp == 1 then
                streams["display_on_off"] = "on"
            elseif propertyTemp == 2 then
                streams["display_on_off"] = "off"
            elseif propertyTemp == 3 then
                streams["display_on_off"] = "on1"
            end
        end
        if (#msgBytes) > 34 then
            propertyTemp = getBits(msgBytes, 34, 0, 1)
            if propertyTemp == 1 then
                streams["water_feedback"] = "shortage"
            elseif propertyTemp == 2 then
                streams["water_feedback"] = "full"
            elseif propertyTemp == 0 then
                streams["water_feedback"] = "invalid"
            end
            propertyTemp = getBits(msgBytes, 34, 2, 3)
            if propertyTemp == 1 then
                streams["breath_light"] = "on"
            elseif propertyTemp == 2 then
                streams["breath_light"] = "off"
            end
            propertyTemp = getBits(msgBytes, 34, 4, 5)
            if propertyTemp == 1 then
                streams["electrolytic_water"] = "on"
            elseif propertyTemp == 2 then
                streams["electrolytic_water"] = "off"
            end
            propertyTemp = getBits(msgBytes, 34, 6, 7)
            if propertyTemp == 1 then
                streams["auto_power_off"] = "on"
            elseif propertyTemp == 2 then
                streams["auto_power_off"] = "off"
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
            else
                streams["waterions"] = "invalid"
            end
            local filter_replace_info = getBits(msgBytes, 44, 2, 3)
            if filter_replace_info == 1 then
                streams["filter_replace_info"] = "on"
            elseif filter_replace_info == 2 then
                streams["filter_replace_info"] = "off"
            else
                streams["filter_replace_info"] = "invalid"
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
            local charge = getBits(msgBytes, 45, 4, 5)
            if charge == 1 then
                streams["charge"] = "on"
            elseif charge == 2 then
                streams["charge"] = "off"
            end
            local charge_feedback = getBits(msgBytes, 45, 6, 7)
            if charge_feedback == 1 then
                streams["charge_feedback"] = "off"
            elseif charge_feedback == 2 then
                streams["charge_feedback"] = "standby"
            elseif charge_feedback == 3 then
                streams["charge_feedback"] = "run"
            end
        end
        if #msgBytes > 46 then
            local battery_status_value = getBits(msgBytes, 46, 0, 2)
            if battery_status_value == 1 then
                streams["battery_status"] = "charging"
            elseif battery_status_value == 2 then
                streams["battery_status"] = "normal"
            else
                streams["battery_status"] = "invalid"
            end
            local battery_level = getBits(msgBytes, 46, 3, 7)
            if battery_level < 6 then
                streams["battery_level"] = battery_level
            end
        end
        if #msgBytes > 47 and msgBytes[47] < 6 then
            streams["pm25"] = msgBytes[47]
        end
        if #msgBytes > 52 then
            if msgBytes[48] > 100 then
                streams["windSpeedPercent"] = 255
            else
                streams["windSpeedPercent"] = msgBytes[48]
            end
            local sensorTemperature = (getBits(msgBytes, 50, 0, 6) * 256 +
                                          msgBytes[49]) / 10
            if getBit(msgBytes, 50, 7) == 1 then
                sensorTemperature = sensorTemperature * -1
            end
            streams["sensorTemperature"] = sensorTemperature
            streams["sensorHumidify"] = msgBytes[51]
            streams["sensorBattery"] = msgBytes[52]
        end
        if #msgBytes > 54 then
            if msgBytes[53] ~= 0xff and msgBytes[54] ~= 0xff then
                streams["pm25_value"] = msgBytes[53] + msgBytes[54] * 256
            end
        end
        if #msgBytes > 60 then
            streams["target_angle"] = msgBytes[55] + msgBytes[56] * 256
            streams["current_angle"] = msgBytes[62] + msgBytes[63] * 256
            streams["area1_time"] = msgBytes[57]
            streams["area2_time"] = msgBytes[58]
            streams["area1_gear"] = msgBytes[59]
            streams["area2_gear"] = msgBytes[60]
            streams["ud_target_angle"] = msgBytes[68] + msgBytes[69] * 256
            streams["ud_current_angle"] = msgBytes[70] + msgBytes[71] * 256
            streams["ambient_lighting"] = msgBytes[72]
        end
        processSwingToJson(msgBytes, streams)
    elseif sub_cmd == 12 then
        streams["btCount"] = msgBytes[11]
        local macs = ""
        local j = 25
        for i = 1, msgBytes[11] do
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
    end
    streams["version"] = VALUE_VERSION
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
