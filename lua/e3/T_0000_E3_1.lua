local bit = require "bit"
local VALUE_VERSION = 1
local JSON = require "cjson"
local function getBit(oneByte, bitIndex)
    if oneByte ~= nil then
        local bitBandList = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80}
        if bitIndex >= 0 and bitIndex <= 7 then
            if bit.band(oneByte, bitBandList[bitIndex + 1]) ==
                bitBandList[bitIndex + 1] then
                return '1'
            else
                return '0'
            end
        end
    end
    return '2'
end
local function setBit(oneByte, bitIndex, value)
    if oneByte ~= nil then
        local bitBorList = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80}
        local bitBandList = {0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F}
        if bitIndex >= 0 and bitIndex <= 7 then
            if value == '1' then
                oneByte = bit.bor(oneByte, bitBorList[bitIndex + 1])
            elseif value == '0' then
                oneByte = bit.band(oneByte, bitBandList[bitIndex + 1])
            end
        end
    end
    return oneByte
end
local function getNumber(x)
    local t = type(x)
    local rs = x
    if (t == "number") then
    elseif (t == "string") then
        rs = tonumber(x) or x
    end
    return rs
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
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
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end
local function Split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator,
                                           nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex,
                                                  string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex,
                                              nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end
local function getError(bodyBytes)
    local error_code = 'none'
    if (bit.band(bodyBytes, 0xFF) == 0x01) then
        error_code = 'E0'
    elseif (bit.band(bodyBytes, 0xFF) == 0x02) then
        error_code = 'E1'
    elseif (bit.band(bodyBytes, 0xFF) == 0x03) then
        error_code = 'E2'
    elseif (bit.band(bodyBytes, 0xFF) == 0x04) then
        error_code = 'E3'
    elseif (bit.band(bodyBytes, 0xFF) == 0x05) then
        error_code = 'E4'
    elseif (bit.band(bodyBytes, 0xFF) == 0x06) then
        error_code = 'E5'
    elseif (bit.band(bodyBytes, 0xFF) == 0x07) then
        error_code = 'E6'
    elseif (bit.band(bodyBytes, 0xFF) == 0x08) then
        error_code = 'E8'
    elseif (bit.band(bodyBytes, 0xFF) == 0x09) then
        error_code = 'EA'
    elseif (bit.band(bodyBytes, 0xFF) == 0x0A) then
        error_code = 'EE'
    elseif (bit.band(bodyBytes, 0xFF) == 0x12) then
        error_code = 'F2'
    elseif (bit.band(bodyBytes, 0xFF) == 0x13) then
        error_code = 'C0'
    elseif (bit.band(bodyBytes, 0xFF) == 0x14) then
        error_code = 'C1'
    elseif (bit.band(bodyBytes, 0xFF) == 0x15) then
        error_code = 'C2'
    elseif (bit.band(bodyBytes, 0xFF) == 0x16) then
        error_code = 'C3'
    elseif (bit.band(bodyBytes, 0xFF) == 0x17) then
        error_code = 'C4'
    elseif (bit.band(bodyBytes, 0xFF) == 0x18) then
        error_code = 'C5'
    elseif (bit.band(bodyBytes, 0xFF) == 0x28) then
        error_code = 'A0'
    elseif (bit.band(bodyBytes, 0xFF) == 0x29) then
        error_code = 'A1'
    elseif (bit.band(bodyBytes, 0xFF) == 0x2A) then
        error_code = 'A2'
    elseif (bit.band(bodyBytes, 0xFF) == 0x2B) then
        error_code = 'A3'
    elseif (bit.band(bodyBytes, 0xFF) == 0x2C) then
        error_code = 'A4'
    elseif (bit.band(bodyBytes, 0xFF) == 0x2D) then
        error_code = 'A5'
    else
        error_code = 'none'
    end
    return error_code;
end
local function jsonToCmd(json, cmd)
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    local deviceSubType = getNumber(json["deviceinfo"]["deviceSubType"])
    if (control) then
        cmd[10] = 0x02
        if (control["power"]) then
            cmd[12] = 0x01
            if (control["power"] == "on") then
                cmd[11] = 0x01
            elseif (control["power"] == "off") then
                cmd[11] = 0x02
            end
        else
            cmd[11] = 0x04
            if (control["mode"]) then
                cmd[12] = 0x01
                if (control["mode"] == "shower") then
                    cmd[13] = 0x00
                elseif (control["mode"] == "kitchen") then
                    cmd[13] = 0x01
                elseif (control["mode"] == "baby") then
                    cmd[13] = 0x02
                elseif (control["mode"] == "max") then
                    cmd[13] = 0x03
                end
            end
            if (control["temperature"]) then
                cmd[12] = 0x02
                cmd[13] = control["temperature"]
            end
            if (control["person_mode_one"]) then
                if (control["person_mode_one"] == "on") then
                    cmd[12] = 0x03
                    cmd[13] = 0x01
                    cmd[14] = control["person_tem_one"]
                elseif (control["person_mode_one"] == "off") then
                    cmd[12] = 0x03
                    cmd[13] = 0x00
                    cmd[14] = control["person_tem_one"]
                end
            end
            if (control["person_mode_two"]) then
                if (control["person_mode_two"] == "on") then
                    cmd[12] = 0x04
                    cmd[13] = 0x01
                    cmd[14] = control["person_tem_two"]
                elseif (control["person_mode_two"] == "off") then
                    cmd[12] = 0x04
                    cmd[13] = 0x00
                    cmd[14] = control["person_tem_two"]
                end
            end
            if (control["person_mode_three"]) then
                if (control["person_mode_three"] == "on") then
                    cmd[12] = 0x06
                    cmd[13] = 0x01
                    cmd[14] = control["person_tem_three"]
                elseif (control["person_mode_three"] == "off") then
                    cmd[12] = 0x06
                    cmd[13] = 0x00
                    cmd[14] = control["person_tem_three"]
                end
            end
            if (control["cloud_intelligence"]) then
                if (control["cloud_intelligence"] == "on") then
                    cmd[12] = 0x05
                    cmd[13] = 0x01
                    cmd[14] = control["cloud_intelligence_tem"]
                elseif (control["cloud_intelligence"] == "off") then
                    cmd[12] = 0x05
                    cmd[13] = 0x00
                    cmd[14] = control["cloud_intelligence_tem"]
                end
            end
            if (control["tem_unit"]) then
                cmd[11] = 0x14
                cmd[12] = 0x20
                cmd[13] = control["tem_unit"]
            end
            if (control["fire_delayed"]) then
                cmd[11] = 0x14
                cmd[12] = 0x21
                cmd[13] = control["fire_delayed"]
            end
            if (control["recover_set"]) then
                cmd[11] = 0x14
                cmd[12] = 0x22
                cmd[13] = 0x00
            end
            if (control["parameter_set"]) then
                cmd[11] = 0x14
                cmd[12] = 0x23
                cmd[13] = control["type_machine"]
                cmd[14] = control["air_supply"]
                cmd[15] = control["load_heat"]
                cmd[16] = control["fan_heat"]
                cmd[17] = control["load_least"]
                cmd[18] = control["fan_least"]
                cmd[19] = control["dian_load"]
                cmd[20] = control["dian_speed"]
                cmd[21] = control["load_least_min"]
                cmd[22] = control["fire_load"]
                cmd[23] = control["fire_fan"]
                cmd[24] = control["fire_delayed"]
                cmd[25] = control["sea_level"]
            end
        end
    elseif query then
        cmd[10] = 0x03
        cmd[12] = 0x01
        cmd[11] = 0x01
        if (query["query_type"] == "status") then
            cmd[11] = 0x01
        elseif (query["query_type"] == "mchine_parameters") then
            cmd[11] = 0x02
        elseif (query["query_type"] == "mchine_run_data") then
            cmd[11] = 0x03
        end
    end
    return cmd
end
local function cmdToJson(json, cmd)
    json["version"] = VALUE_VERSION
    local cmdLength = #cmd
    if ((cmd[10] == 0x03 and cmd[11] == 0x01) or
        (cmd[10] == 0x02 and cmd[11] == 0x04) or
        (cmd[10] == 0x02 and cmd[11] == 0x01) or
        (cmd[10] == 0x02 and cmd[11] == 0x02) or
        (cmd[10] == 0x04 and cmd[11] == 0x00)) then
        json['in_water_tem'] = cmd[15]
        json['out_water_tem'] = cmd[16]
        json['environment_tem'] = cmd[17]
        json['temperature'] = cmd[18]
        json['water_volume'] = cmd[20] * 256 + cmd[19] * 1
        json['fire_capacity'] = cmd[22]
        json['person_tem_one'] = cmd[24]
        json['person_tem_two'] = cmd[25]
        json['person_tem_three'] = cmd[26]
        json["wind_speed"] = cmd[28] * 256 + cmd[27] * 1
        json['lowest_temp'] = cmd[29]
        json['hightest_temp'] = cmd[30]
        if (getBit(cmd[13], 0) == '1') then
            json["power"] = "on"
        else
            json["power"] = "off"
        end
        if (getBit(cmd[13], 1) == '1') then
            json["feedback"] = "on"
        else
            json["feedback"] = "off"
        end
        if (getBit(cmd[13], 2) == '1') then
            json["fan"] = "on"
        else
            json["fan"] = "off"
        end
        if (bit.band(cmd[23], 0xFF) == 0x03) then
            json["person_mode_one"] = "on"
        else
            json["person_mode_one"] = "off"
        end
        if (bit.band(cmd[23], 0xFF) == 0x04) then
            json["person_mode_two"] = "on"
        else
            json["person_mode_two"] = "off"
        end
        if (bit.band(cmd[23], 0xFF) == 0x06) then
            json["person_mode_three"] = "on"
        else
            json["person_mode_three"] = "off"
        end
        if (bit.band(cmd[23], 0xFF) == 0x05) then
            json["cloud_intelligence"] = "on"
        else
            json["cloud_intelligence"] = "off"
        end
        if (bit.band(cmd[23], 0xFF) == 0x01) then
            json["mode"] = "kitchen"
        elseif (bit.band(cmd[23], 0xFF) == 0x02) then
            json["mode"] = "baby"
        elseif (bit.band(cmd[23], 0xFF) == 0x07) then
            json["mode"] = "max"
        else
            json["mode"] = "shower"
        end
        json['error_code'] = getError(cmd[14])
    elseif ((cmd[10] == 0x02 and cmd[11] == 0x14) or
        (cmd[10] == 0x03 and cmd[11] == 0x02)) then
        json['type_machine'] = cmd[14]
        json['air_supply'] = cmd[15]
        json['load_heat'] = cmd[16]
        json['fan_heat'] = cmd[17]
        json['load_least'] = cmd[18]
        json['fan_least'] = cmd[19]
        json['dian_load'] = cmd[20]
        json['dian_speed'] = cmd[21]
        json['load_least_min'] = cmd[22]
        json['fire_load'] = cmd[23]
        json['fire_fan'] = cmd[24]
        json['fire_delayed'] = cmd[25]
        json['sea_level'] = cmd[26]
        if (getBit(cmd[13], 0) == '1') then
            json["tem_unit"] = 1
        else
            json["tem_unit"] = 0
        end
    elseif (cmd[10] == 0x03 and cmd[11] == 0x03) then
        json["control_version"] = cmd[15]
        json["one_error"] = getError(cmd[16])
        json["two_error"] = getError(cmd[17])
        json["three_error"] = getError(cmd[18])
        json["four_error"] = getError(cmd[19])
        json["five_error"] = getError(cmd[20])
        json["six_error"] = getError(cmd[21])
        json["seven_error"] = getError(cmd[22])
        json["eight_error"] = getError(cmd[23])
        json["nine_error"] = getError(cmd[24])
        json["ten_error"] = getError(cmd[25])
        json["fire_time_amount"] = getNumber(cmd[26]) * 10000 +
                                       getNumber(cmd[27]) * 100 +
                                       getNumber(cmd[28])
        json["fire_duration_amount"] = getNumber(cmd[29]) * 10000 +
                                           getNumber(cmd[30]) * 100 +
                                           getNumber(cmd[31])
    end
    return json
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    if JSON == nil then JSON = require "cjson" end
    local json = JSON.decode(jsonCmdStr)
    if json == nil then return end
    local cmd = {
        0xAA, 0x1E, 0xE3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x14, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    }
    cmd = jsonToCmd(json, cmd)
    local len = #cmd
    cmd[2] = len
    cmd[len + 1] = makeSum(cmd, 2, len)
    local ret = table2string(cmd)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    json = JSON.decode(jsonStr)
    if json == nil then return end
    local binData = json["msg"]["data"]
    local status = json["status"]
    local rs = {}
    rs["status"] = {}
    if (status) then rs["status"] = status end
    local cmd = string2table(binData)
    rs["status"] = cmdToJson(rs["status"], cmd)
    local ret = JSON.encode(rs)
    return ret
end
