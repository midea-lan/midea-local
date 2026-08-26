local bit = require "bit"
local VALUE_VERSION = 17
local JSON = require "cjson"
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
local function assembleByteFromControlJson(control, msgBytes)
    msgBytes[10] = 0x02
    msgBytes[11] = 0x21
    msgBytes[12] = 0xFF
    msgBytes[13] = 0xFF
    msgBytes[14] = 0xFF
    msgBytes[15] = 0xFF
    msgBytes[16] = 0xFF
    msgBytes[17] = 0xFF
    msgBytes[18] = 0xFF
    msgBytes[19] = 0xFF
    msgBytes[20] = 0xFF
    msgBytes[21] = 0xFF
    msgBytes[22] = 0xFF
    msgBytes[23] = 0xFF
    msgBytes[24] = 0xFF
    msgBytes[25] = 0xFF
    msgBytes[26] = 0xFF
    msgBytes[27] = 0xFF
    msgBytes[28] = 0xFF
    msgBytes[29] = 0xFF
    msgBytes[30] = 0xFF
    msgBytes[31] = 0xFF
    msgBytes[32] = 0xFF
    msgBytes[33] = 0xFF
    msgBytes[34] = 0xFF
    msgBytes[35] = 0xFF
    msgBytes[36] = 0xFF
    msgBytes[37] = 0xFF
    msgBytes[38] = 0xFF
    msgBytes[39] = 0xFF
    if (control["power"] and control["power"] == "on") then
        msgBytes[12] = 0x01
        msgBytes[21] = 0x01
        msgBytes[31] = 0x01
    elseif (control["power"] and control["power"] == "off") then
        msgBytes[12] = 0x00
        msgBytes[21] = 0x00
        msgBytes[31] = 0x00
    end
    if (control["lock"] and control["lock"] == "locked") then
        msgBytes[30] = 0x01
    elseif (control["lock"] and control["lock"] == "unlock") then
        msgBytes[30] = 0x00
    end
    if (control["upstair_work_status"] == "power_on") then
        msgBytes[12] = 0x01
    elseif (control["upstair_work_status"] == "power_off") then
        msgBytes[12] = 0x00
    elseif (control["upstair_work_status"] == "work") then
        msgBytes[12] = 0x02
    elseif (control["upstair_work_status"] == "order") then
        msgBytes[12] = 0x03
    end
    if (control["downstair_work_status"] == "power_on") then
        msgBytes[21] = 0x01
    elseif (control["downstair_work_status"] == "power_off") then
        msgBytes[21] = 0x00
    elseif (control["downstair_work_status"] == "work") then
        msgBytes[21] = 0x02
    elseif (control["downstair_work_status"] == "order") then
        msgBytes[21] = 0x03
    end
    if (control["middlestair_work_status"] == "power_on") then
        msgBytes[31] = 0x01
    elseif (control["middlestair_work_status"] == "power_off") then
        msgBytes[31] = 0x00
    elseif (control["middlestair_work_status"] == "work") then
        msgBytes[31] = 0x02
    elseif (control["middlestair_work_status"] == "order") then
        msgBytes[31] = 0x03
    end
    if (control["upstair_mode"] ~= nil) then
        msgBytes[13] = tonumber(control["upstair_mode"])
    end
    if (control["upstair_temp"] ~= nil) then
        msgBytes[14] = tonumber(control["upstair_temp"])
    end
    if (control["downstair_mode"] ~= nil) then
        msgBytes[22] = tonumber(control["downstair_mode"])
    end
    if (control["downstair_temp"] ~= nil) then
        msgBytes[23] = tonumber(control["downstair_temp"])
    end
    if (control["middlestair_mode"] ~= nil) then
        msgBytes[32] = tonumber(control["middlestair_mode"])
    end
    if (control["middlestair_temp"] ~= nil) then
        msgBytes[33] = tonumber(control["middlestair_temp"])
    end
    if (control["upstair_hour"] ~= nil) then
        msgBytes[15] = tonumber(control["upstair_hour"])
    end
    if (control["upstair_min"] ~= nil) then
        msgBytes[16] = tonumber(control["upstair_min"])
    end
    if (control["upstair_sec"] ~= nil) then
        msgBytes[17] = tonumber(control["upstair_sec"])
    end
    if (control["upstair_order_hour"] ~= nil) then
        msgBytes[18] = tonumber(control["upstair_order_hour"])
    end
    if (control["upstair_order_min"] ~= nil) then
        msgBytes[19] = tonumber(control["upstair_order_min"])
    end
    if (control["upstair_order_sec"] ~= nil) then
        msgBytes[20] = tonumber(control["upstair_order_sec"])
    end
    if (control["downstair_hour"] ~= nil) then
        msgBytes[24] = tonumber(control["downstair_hour"])
    end
    if (control["downstair_min"] ~= nil) then
        msgBytes[25] = tonumber(control["downstair_min"])
    end
    if (control["downstair_sec"] ~= nil) then
        msgBytes[26] = tonumber(control["downstair_sec"])
    end
    if (control["downstair_order_hour"] ~= nil) then
        msgBytes[27] = tonumber(control["downstair_order_hour"])
    end
    if (control["downstair_order_min"] ~= nil) then
        msgBytes[28] = tonumber(control["downstair_order_min"])
    end
    if (control["downstair_order_sec"] ~= nil) then
        msgBytes[29] = tonumber(control["downstair_order_sec"])
    end
    if (control["middlestair_hour"] ~= nil) then
        msgBytes[34] = tonumber(control["middlestair_hour"])
    end
    if (control["middlestair_min"] ~= nil) then
        msgBytes[35] = tonumber(control["middlestair_min"])
    end
    if (control["middlestair_sec"] ~= nil) then
        msgBytes[36] = tonumber(control["middlestair_sec"])
    end
    if (control["middlestair_order_hour"] ~= nil) then
        msgBytes[37] = tonumber(control["middlestair_order_hour"])
    end
    if (control["middlestair_order_min"] ~= nil) then
        msgBytes[38] = tonumber(control["middlestair_order_min"])
    end
    if (control["middlestair_order_sec"] ~= nil) then
        msgBytes[39] = tonumber(control["middlestair_order_sec"])
    end
    return msgBytes
end
local function assembleByteFromJson(result, msgBytes)
    local query = result["query"]
    local control = result["control"]
    if (control) then
        msgBytes = assembleByteFromControlJson(control, msgBytes);
    elseif (query) then
        msgBytes[10] = 0x03
        msgBytes[11] = 0x31
    end
    return msgBytes
end
local function parseByteToJson(status, bodyBytes)
    if (bodyBytes[12] == 0x00) then
        status["upstair_work_status"] = "power_off"
    elseif (bodyBytes[12] == 0x01) then
        status["upstair_work_status"] = "power_on"
    elseif (bodyBytes[12] == 0x02) then
        status["upstair_work_status"] = "working"
    elseif (bodyBytes[12] == 0x03) then
        status["upstair_work_status"] = "order"
    elseif (bodyBytes[12] == 0x04) then
        status["upstair_work_status"] = "finish"
    elseif (bodyBytes[12] == 0x05) then
        status["upstair_work_status"] = "error"
    end
    if (bodyBytes[13] ~= nil and bodyBytes[13] ~= 0xFF) then
        status["upstair_mode"] = tonumber(bodyBytes[13])
    end
    if (tonumber(bodyBytes[14]) ~= 0xFF) then
        status["upstair_temp"] = tonumber(bodyBytes[14])
    end
    if (bodyBytes[15] ~= nil and tonumber(bodyBytes[15]) ~= 0xFF) then
        status["upstair_hour"] = tonumber(bodyBytes[15])
    end
    if (tonumber(bodyBytes[16]) ~= 0xFF) then
        status["upstair_min"] = tonumber(bodyBytes[16])
    end
    if (tonumber(bodyBytes[17]) ~= 0xFF) then
        status["upstair_sec"] = tonumber(bodyBytes[17])
    end
    if (bodyBytes[18] ~= nil and tonumber(bodyBytes[18]) ~= 0xFF) then
        status["upstair_order_hour"] = tonumber(bodyBytes[18])
    end
    if (tonumber(bodyBytes[19]) ~= 0xFF) then
        status["upstair_order_min"] = tonumber(bodyBytes[19])
    end
    if (tonumber(bodyBytes[20]) ~= 0xFF) then
        status["upstair_order_sec"] = tonumber(bodyBytes[20])
    end
    if (bodyBytes[21] == 0x00) then
        status["downstair_work_status"] = "power_off"
    elseif (bodyBytes[21] == 0x01) then
        status["downstair_work_status"] = "power_on"
    elseif (bodyBytes[21] == 0x02) then
        status["downstair_work_status"] = "working"
    elseif (bodyBytes[21] == 0x03) then
        status["downstair_work_status"] = "order"
    elseif (bodyBytes[21] == 0x04) then
        status["downstair_work_status"] = "finish"
    elseif (bodyBytes[21] == 0x05) then
        status["downstair_work_status"] = "error"
    end
    if (bodyBytes[22] ~= nil and bodyBytes[22] ~= 0xFF) then
        status["downstair_mode"] = tonumber(bodyBytes[22])
    end
    if (tonumber(bodyBytes[23]) ~= 0xFF) then
        status["downstair_temp"] = tonumber(bodyBytes[23])
    end
    if (bodyBytes[24] ~= nil and tonumber(bodyBytes[24]) ~= 0xFF) then
        status["downstair_hour"] = tonumber(bodyBytes[24])
    end
    if (tonumber(bodyBytes[25]) ~= 0xFF) then
        status["downstair_min"] = tonumber(bodyBytes[25])
    end
    if (tonumber(bodyBytes[26]) ~= 0xFF) then
        status["downstair_sec"] = tonumber(bodyBytes[26])
    end
    if (bodyBytes[27] ~= nil and tonumber(bodyBytes[27]) ~= 0xFF) then
        status["downstair_order_hour"] = tonumber(bodyBytes[27])
    end
    if (tonumber(bodyBytes[28]) ~= 0xFF) then
        status["downstair_order_min"] = tonumber(bodyBytes[28])
    end
    if (tonumber(bodyBytes[29]) ~= 0xFF) then
        status["downstair_order_sec"] = tonumber(bodyBytes[29])
    end
    if (bodyBytes[30] == 0x00) then
        status["middlestair_work_status"] = "power_off"
    elseif (bodyBytes[30] == 0x01) then
        status["middlestair_work_status"] = "power_on"
    elseif (bodyBytes[30] == 0x02) then
        status["middlestair_work_status"] = "working"
    elseif (bodyBytes[30] == 0x03) then
        status["middlestair_work_status"] = "order"
    elseif (bodyBytes[30] == 0x04) then
        status["middlestair_work_status"] = "finish"
    elseif (bodyBytes[30] == 0x05) then
        status["middlestair_work_status"] = "error"
    end
    if (bodyBytes[31] ~= nil and bodyBytes[31] ~= 0xFF) then
        status["middlestair_mode"] = tonumber(bodyBytes[31])
    end
    if (tonumber(bodyBytes[32]) ~= 0xFF) then
        status["middlestair_temp"] = tonumber(bodyBytes[32])
    end
    if (bodyBytes[33] ~= nil and tonumber(bodyBytes[33]) ~= 0xFF) then
        status["middlestair_hour"] = tonumber(bodyBytes[33])
    end
    if (tonumber(bodyBytes[34]) ~= 0xFF) then
        status["middlestair_min"] = tonumber(bodyBytes[34])
    end
    if (tonumber(bodyBytes[35]) ~= 0xFF) then
        status["middlestair_sec"] = tonumber(bodyBytes[35])
    end
    if (bodyBytes[36] ~= nil and tonumber(bodyBytes[36]) ~= 0xFF) then
        status["middlestair_order_hour"] = tonumber(bodyBytes[36])
    end
    if (tonumber(bodyBytes[37]) ~= 0xFF) then
        status["middlestair_order_min"] = tonumber(bodyBytes[37])
    end
    if (tonumber(bodyBytes[38]) ~= 0xFF) then
        status["middlestair_order_sec"] = tonumber(bodyBytes[38])
    end
    if (tonumber(bodyBytes[39]) ~= 0xFF) then
        status["soft_version"] = tonumber(bodyBytes[39])
    end
    if (tonumber(bodyBytes[40]) ~= 0xFF) then
        status["cloud_async_result"] = tonumber(bodyBytes[40])
    end
    if bit_band(bodyBytes[41], 0x08) == 0x08 then
        status["door_middlestair"] = "open"
    else
        status["door_middlestair"] = "close"
    end
    if bit_band(bodyBytes[41], 0x04) == 0x04 then
        status["door_upstair"] = "open"
    else
        status["door_upstair"] = "close"
    end
    if bit_band(bodyBytes[41], 0x02) == 0x02 then
        status["door_downstair"] = "open"
    else
        status["door_downstair"] = "close"
    end
    if bit_band(bodyBytes[41], 0x01) == 0x01 then
        status["lock"] = "locked"
    else
        status["lock"] = "unlock"
    end
    if bit_band(bodyBytes[42], 0x01) == 0x01 then
        status["downstair_ispreheat"] = "preheat"
    else
        status["downstair_ispreheat"] = "unpreheat"
    end
    if bit_band(bodyBytes[42], 0x02) == 0x02 then
        status["upstair_ispreheat"] = "preheat"
    else
        status["upstair_ispreheat"] = "unpreheat"
    end
    if bit_band(bodyBytes[42], 0x04) == 0x04 then
        status["downstair_iscooling"] = "cooling"
    else
        status["downstair_iscooling"] = "uncooling"
    end
    if bit_band(bodyBytes[42], 0x08) == 0x08 then
        status["upstair_iscooling"] = "cooling"
    else
        status["upstair_iscooling"] = "uncooling"
    end
    if bit_band(bodyBytes[42], 0x10) == 0x10 then
        status["middlestair_ispreheat"] = "preheat"
    else
        status["middlestair_ispreheat"] = "unpreheat"
    end
    if bit_band(bodyBytes[42], 0x20) == 0x20 then
        status["middlestair_iscooling"] = "cooling"
    else
        status["middlestair_iscooling"] = "uncooling"
    end
    if bit_band(bodyBytes[43], 0x01) == 0x01 then
        status["error_up_temp_sensor"] = 1
    else
        status["error_up_temp_sensor"] = 0
    end
    if bit_band(bodyBytes[43], 0x02) == 0x02 then
        status["error_middle_temp_sensor"] = 1
    else
        status["error_middle_temp_sensor"] = 0
    end
    if bit_band(bodyBytes[43], 0x04) == 0x04 then
        status["error_down_temp_sensor"] = 1
    else
        status["error_down_temp_sensor"] = 0
    end
    if bit_band(bodyBytes[44], 0x01) == 0x01 then
        status["error_up_heater"] = 1
    else
        status["error_up_heater"] = 0
    end
    if bit_band(bodyBytes[44], 0x02) == 0x02 then
        status["error_middle_heater"] = 1
    else
        status["error_middle_heater"] = 0
    end
    if bit_band(bodyBytes[44], 0x04) == 0x04 then
        status["error_down_heater"] = 1
    else
        status["error_down_heater"] = 0
    end
    if (tonumber(bodyBytes[45]) ~= 0xFF) then
        status["error_temp_controller"] = tonumber(bodyBytes[45])
    end
    status["version"] = VALUE_VERSION
    return status
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    result = JSON.decode(jsonCmdStr)
    if result == nil then return end
    local msgBytes = {0xAA, 0x00, 0xB3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    msgBytes = assembleByteFromJson(result, msgBytes)
    local len = #msgBytes
    msgBytes[2] = len
    msgBytes[len + 1] = makeSum(msgBytes, 2, len)
    local ret = table2string(msgBytes)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(cmdStr)
    if (not cmdStr) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    result = JSON.decode(cmdStr)
    if result == nil then return end
    local binData = result["msg"]["data"]
    local status = result["status"]
    local ret = {}
    ret["status"] = {}
    if (status) then ret["status"] = status end
    local bodyBytes = string2table(binData)
    ret["status"] = parseByteToJson(ret["status"], bodyBytes)
    local ret = JSON.encode(ret)
    return ret
end
