local bit = require "bit"
local VALUE_VERSION = 5
local JSON = require "cjson"
local VALUE_ON = "on"
local VALUE_OFF = "off"
local function bit_band(a, b)
    local cloud_bl = true
    local ret
    if (cloud_bl) then
        ret = bit.band(a, b)
    else
        ret = bit32.band(a, b)
    end
    return ret
end
local function getBit(oneByte, bitIndex)
    if bitIndex > 3 and bitIndex < 8 then
        if bitIndex == 7 then
            if bit_band(oneByte, 0x80) == 0x80 then return '1' end
        elseif bitIndex == 6 then
            if bit_band(oneByte, 0x40) == 0x40 then return '1' end
        elseif bitIndex == 5 then
            if bit_band(oneByte, 0x20) == 0x20 then return '1' end
        elseif bitIndex == 4 then
            if bit_band(oneByte, 0x10) == 0x10 then return '1' end
        end
        return '0'
    elseif bitIndex >= 0 and bitIndex <= 3 then
        if bitIndex == 3 then
            if bit_band(oneByte, 0x08) == 0x08 then return '1' end
        elseif bitIndex == 2 then
            if bit_band(oneByte, 0x04) == 0x04 then return '1' end
        elseif bitIndex == 1 then
            if bit_band(oneByte, 0x02) == 0x02 then return '1' end
        elseif bitIndex == 0 then
            if bit_band(oneByte, 0x01) == 0x01 then return '1' end
        end
        return '0'
    end
    return '2'
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
local function jsonToCmd(json, cmd)
    local query = json["query"]
    local ctrl = json["control"]
    if (ctrl) then
        cmd[10] = 0x02
        cmd[11] = 0x22
        if (ctrl["gear_inc"] or ctrl["volume_inc"]) then
            cmd[12] = 0x02
            if (ctrl["gear_inc"]) then
                cmd[13] = 0x00
                local inc = getNumber(ctrl["gear_inc"]);
                if (inc < 0x00) then inc = inc + 0xFF + 0x01 end
                cmd[14] = inc
            end
            if (ctrl["volume_inc"]) then
                local inc = getNumber(ctrl["volume_inc"]);
                if (inc < 0x00) then inc = inc + 0xFF + 0x01 end
                cmd[13] = inc
                cmd[14] = 0x00
            end
        else
            cmd[12] = 0x01
            cmd[13] = 0xff
            cmd[14] = 0xff
            cmd[15] = 0xff
            cmd[16] = 0xff
            cmd[17] = 0xff
            cmd[18] = 0xff
            cmd[19] = 0xff
            cmd[20] = 0xff
            if (ctrl["light"]) then
                if (ctrl["light"] == VALUE_ON) then
                    cmd[13] = 0x1a
                    if (ctrl["lightness"]) then
                        local lightness = getNumber(ctrl["lightness"])
                        if (lightness ~= 0x00) then
                            cmd[13] = lightness * 10
                        end
                    end
                elseif (ctrl["light"] == VALUE_OFF) then
                    cmd[13] = 0x00
                end
            end
            if (ctrl["power"]) then
                if (ctrl["power"] == VALUE_ON) then
                    cmd[14] = 0x02
                    cmd[15] = 0x02
                elseif (ctrl["power"] == VALUE_OFF) then
                    cmd[14] = 0x03
                elseif (ctrl["power"] == "delay_off") then
                    cmd[14] = 0x00
                end
            end
            if (ctrl["gear"]) then
                local gear = getNumber(ctrl["gear"])
                if (gear ~= 0x00) then
                    cmd[14] = 0x02
                    cmd[15] = gear
                else
                    cmd[14] = 0x03
                end
            end
            if (ctrl["ir"]) then
                if (ctrl["ir"] == VALUE_ON) then
                    cmd[16] = 0x03
                elseif (ctrl["ir"] == VALUE_OFF) then
                    cmd[16] = 0x02
                end
            end
            if (ctrl["speak"]) then
                if (ctrl["speak"] == VALUE_ON) then
                    cmd[16] = 0x05
                elseif (ctrl["speak"] == VALUE_OFF) then
                    cmd[16] = 0x04
                end
            end
            if (ctrl["gesture"]) then
                if (ctrl["gesture"] == VALUE_ON) then
                    cmd[16] = 0x07
                elseif (ctrl["gesture"] == VALUE_OFF) then
                    cmd[16] = 0x06
                end
            end
            if (ctrl["linkage"]) then
                if (ctrl["linkage"] == VALUE_ON) then
                    cmd[16] = 0x09
                elseif (ctrl["linkage"] == VALUE_OFF) then
                    cmd[16] = 0x08
                end
            end
            if (ctrl["smoke_detector"]) then
                if (ctrl["smoke_detector"] == VALUE_ON) then
                    cmd[16] = 0x0B
                elseif (ctrl["smoke_detector"] == VALUE_OFF) then
                    cmd[16] = 0x0A
                end
            end
            if (ctrl["steaming"]) then
                if (ctrl["steaming"] == VALUE_ON) then
                    cmd[14] = 0x04
                elseif (ctrl["steaming"] == VALUE_OFF) then
                    cmd[14] = 0x05
                end
            end
            if (ctrl["one_key_start"] == VALUE_ON) then
                cmd[14] = 0x06
                cmd[15] = 0x02
            end
            if (ctrl["aidry"]) then
                if (ctrl["aidry"] == VALUE_ON) then
                    cmd[14] = 0x02
                    cmd[15] = 0x15
                elseif (ctrl["aidry"] == VALUE_OFF) then
                    cmd[14] = 0x03
                end
            end
        end
    elseif (query) then
        cmd[10] = 0x03
        if (query['tips']) then
            cmd[11] = 0x32
            cmd[12] = 0x01
        else
            cmd[11] = 0x31
        end
    end
    return cmd
end
local function queryAllCmdToJson(json, cmd)
    if (cmd[12] ~= 0xff) then
        if (cmd[12] == 0x00) then
            json["light"] = VALUE_OFF
        else
            json["light"] = VALUE_ON
            json["lightness"] = cmd[12] / 10
        end
    end
    json["work_status"] = cmd[13]
    if (cmd[13] ~= 0xFF) then
        if (cmd[13] == 0x00 or cmd[13] == 0x01) then
            json["power"] = VALUE_OFF
            json["work_status_desc"] = "power_off"
        elseif (cmd[13] == 0x02 or cmd[13] == 0x06 or cmd[13] == 0x07 or cmd[13] ==
            0x14 or cmd[13] == 0x15 or cmd[13] == 0x16) then
            json["power"] = VALUE_ON
            json["work_status_desc"] = "working"
            if (cmd[13] == 0x06) then
                json["work_status_desc"] = 'hotclean'
            elseif (cmd[13] == 0x07) then
                json["work_status_desc"] = 'clean'
            elseif (cmd[13] == 0x14 or cmd[13] == 0x15 or cmd[13] == 0x16) then
                json["gear"] = cmd[13]
                json["gear_detail"] = cmd[14]
            end
        elseif (cmd[13] == 0x03) then
            json["power"] = "delay_off"
            json["work_status_desc"] = "power_off_delay"
            json["power_delay"] = 0x03
        elseif (cmd[13] == 0x0a) then
            json["power"] = VALUE_OFF
            json["work_status_desc"] = "power_off"
            json["is_error"] = "1"
        end
    end
    if (json["gear"] == nil and cmd[14] ~= 0xff) then json["gear"] = cmd[14] end
    json["oilcup_position"] = getBit(cmd[16], 1)
    json["hotclean_tips"] = getBit(cmd[16], 2)
    json["is_error"] = getBit(cmd[16], 7)
    if (getBit(cmd[24], 0) == "0") then
        json["ir"] = VALUE_OFF
    elseif (getBit(cmd[24], 0) == "1") then
        json["ir"] = VALUE_ON
    end
    if (getBit(cmd[24], 1) == "0") then
        json["speak"] = VALUE_OFF
    elseif (getBit(cmd[24], 1) == "1") then
        json["speak"] = VALUE_ON
    end
    if (getBit(cmd[24], 2) == "0") then
        json["gesture"] = VALUE_OFF
    elseif (getBit(cmd[24], 2) == "1") then
        json["gesture"] = VALUE_ON
    end
    if (getBit(cmd[24], 3) == "0") then
        json["linkage"] = VALUE_OFF
    elseif (getBit(cmd[24], 3) == "1") then
        json["linkage"] = VALUE_ON
    end
    if (getBit(cmd[24], 4) == "0") then
        json["smoke_detector"] = VALUE_OFF
    elseif (getBit(cmd[24], 4) == "1") then
        json["smoke_detector"] = VALUE_ON
    end
    if (cmd[28] and cmd[28] ~= 0) then
        json["error_code"] = cmd[28]
    else
        json["error_code"] = 0
    end
    if (cmd[13] == 0x06 and cmd[32] and cmd[32] ~= 0xff) then
        json["hotclean_minutes"] = cmd[32]
    end
    if (cmd[13] == 0x16 and cmd[34] + cmd[35] ~= 0) then
        json["wind_pressure"] = cmd[34] * 256 + cmd[35]
    end
    return json
end
local function queryErrorCmdToJson(json, cmd)
    if (getBit(cmd[13], 2) == "1") then json["error_type"] = "sensor_error" end
    if (getBit(cmd[14], 0) == "1") then json["error_type"] = "hotclean_error" end
    if (getBit(cmd[14], 1) == "1") then json["error_type"] = "split_error" end
    if (cmd[15] ~= 0 or cmd[16] ~= 0) then
        json["error_type"] = "inverter_error"
    end
    return json
end
local function cmdToJson(json, cmd)
    json["version"] = VALUE_VERSION
    json["error_type"] = ""
    json["ctrl_fail"] = ""
    json["ctrl_fail_reason"] = ""
    if (cmd[10] == 0x02) then
        if (cmd[11] == 0x22) then
            if (cmd[12] == 0x01) then
                if (cmd[13] ~= 0xff) then
                    if (cmd[13] == 0x00) then
                        json["light"] = VALUE_OFF
                    else
                        json["light"] = VALUE_ON
                        json["lightness"] = cmd[13] / 10
                    end
                end
                if (cmd[14] ~= 0xFF) then
                    if (cmd[14] == 0x03 or cmd[14] == 0x01 or cmd[14] == 0x05) then
                        json["power"] = VALUE_OFF
                        json["work_status_desc"] = "power_off"
                        json["work_status"] = 0x01
                    elseif (cmd[14] == 0x02) then
                        json["power"] = VALUE_ON
                        json["work_status_desc"] = "working"
                        json["work_status"] = 0x02
                    elseif (cmd[14] == 0x00) then
                        json["power"] = "delay_off"
                        json["work_status_desc"] = "power_off_delay"
                        json["power_delay"] = 0x03
                        json["work_status"] = 0x03
                    elseif (cmd[14] == 0x04) then
                        json["power"] = VALUE_ON
                        json["work_status_desc"] = 'hotclean'
                        json["work_status"] = 0x06
                    end
                end
                if (cmd[15] ~= 0xff) then json["gear"] = cmd[15] end
                if (cmd[16] ~= 0xFF) then
                    if (cmd[16] == 0x02) then
                        json["ir"] = VALUE_OFF
                    elseif (cmd[16] == 0x03) then
                        json["ir"] = VALUE_ON
                    end
                    if (cmd[16] == 0x04) then
                        json["speak"] = VALUE_OFF
                    elseif (cmd[16] == 0x05) then
                        json["speak"] = VALUE_ON
                    end
                    if (cmd[16] == 0x06) then
                        json["gesture"] = VALUE_OFF
                    elseif (cmd[16] == 0x07) then
                        json["gesture"] = VALUE_ON
                    end
                    if (cmd[16] == 0x08) then
                        json["linkage"] = VALUE_OFF
                    elseif (cmd[16] == 0x09) then
                        json["linkage"] = VALUE_ON
                    end
                    if (cmd[16] == 0x0A) then
                        json["smoke_detector"] = VALUE_OFF
                    elseif (cmd[16] == 0x0B) then
                        json["smoke_detector"] = VALUE_ON
                    end
                end
            elseif (cmd[12] == 0x02) then
                if (cmd[13] ~= 0x00) then
                    if (cmd[13] >= 128) then
                        cmd[13] = cmd[13] - 0xff - 0x01
                    end
                    json["volume_inc"] = cmd[13]
                end
                if (cmd[14] ~= 0x00) then
                    if (cmd[14] >= 128) then
                        cmd[14] = cmd[14] - 0xff - 0x01
                    end
                    json["gear_inc"] = cmd[14]
                end
            elseif (cmd[12] == 0xFE) then
                json["ctrl_fail"] = "1"
                if (cmd[14] ~= 0x00) then
                    json["ctrl_fail_reason"] = cmd[14]
                end
            end
        end
    elseif (cmd[10] == 0x03) then
        if (cmd[11] == 0x31) then
            json = queryAllCmdToJson(json, cmd)
        elseif (cmd[11] == 0x32 and cmd[12] == 0x01) then
            json = queryErrorCmdToJson(json, cmd)
        end
    elseif (cmd[10] == 0x04) then
        if (cmd[11] == 0x41) then
            json = queryAllCmdToJson(json, cmd)
        elseif (cmd[11] == 0x0A and cmd[12] == 0xA1) then
            json = queryErrorCmdToJson(json, cmd)
        elseif (cmd[11] == 0x0A and cmd[12] == 0xA2) then
            json["oilcup_position"] = getBit(cmd[13], 1)
            json["hotclean_tips"] = getBit(cmd[13], 2)
        end
    elseif (cmd[10] == 0x0A and cmd[11] == 0xA1) then
        if (getBit(cmd[12], 2) == "1") then
            json["error_type"] = "sensor_error"
        end
        if (getBit(cmd[13], 0) == "1") then
            json["error_type"] = "hotclean_error"
        end
        if (getBit(cmd[13], 1) == "1") then
            json["error_type"] = "split_error"
        end
        if (cmd[14] ~= 0 or cmd[15] ~= 0) then
            json["error_type"] = "inverter_error"
        end
    end
    return json
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
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    result = JSON.decode(jsonCmdStr)
    if result == nil then return end
    local msgBytes = {0xAA, 0x00, 0xB6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    msgBytes = jsonToCmd(result, msgBytes)
    local len = #msgBytes
    msgBytes[2] = len
    msgBytes[len + 1] = makeSum(msgBytes, 2, len)
    local ret = table2string(msgBytes)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    result = JSON.decode(jsonStr)
    if result == nil then return end
    local binData = result["msg"]["data"]
    local ret = {}
    ret["status"] = {}
    local bodyBytes = string2table(binData)
    ret["status"] = cmdToJson(ret["status"], bodyBytes)
    local ret = JSON.encode(ret)
    return ret
end
