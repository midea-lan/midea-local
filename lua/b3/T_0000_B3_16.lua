local bit = require "bit"
local VALUE_VERSION = 16
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
    if (control["power"] and control["power"] == "on") then
        msgBytes[12] = 0x01
        msgBytes[17] = 0x01
        msgBytes[23] = 0x01
    elseif (control["power"] and control["power"] == "off") then
        msgBytes[12] = 0x00
        msgBytes[17] = 0x00
        msgBytes[23] = 0x00
    end
    if (control["lock"] and control["lock"] == "locked") then
        msgBytes[22] = 0x01
    elseif (control["lock"] and control["lock"] == "unlock") then
        msgBytes[22] = 0x00
    end
    if (control["upstair_work_status"] == "power_on") then
        msgBytes[12] = 0x01
    elseif (control["upstair_work_status"] == "power_off") then
        msgBytes[12] = 0x00
    end
    if (control["downstair_work_status"] == "power_on") then
        msgBytes[17] = 0x01
    elseif (control["downstair_work_status"] == "power_off") then
        msgBytes[17] = 0x00
    end
    if (control["middlestair_work_status"] == "power_on") then
        msgBytes[23] = 0x01
    elseif (control["middlestair_work_status"] == "power_off") then
        msgBytes[23] = 0x00
    end
    if (control["upstair_mode"] ~= nil) then
        msgBytes[13] = tonumber(control["upstair_mode"])
        msgBytes[12] = 0x02
    end
    if (control["upstair_temp"] ~= nil) then
        msgBytes[14] = tonumber(control["upstair_temp"])
    end
    if (control["downstair_mode"] ~= nil) then
        msgBytes[18] = tonumber(control["downstair_mode"])
        msgBytes[17] = 0x02
    end
    if (control["downstair_temp"] ~= nil) then
        msgBytes[19] = tonumber(control["downstair_temp"])
    end
    if (control["middlestair_mode"] ~= nil) then
        msgBytes[24] = tonumber(control["middlestair_mode"])
        msgBytes[23] = 0x02
    end
    if (control["middlestair_temp"] ~= nil) then
        msgBytes[25] = tonumber(control["middlestair_temp"])
    end
    if (control["upstair_hour"] ~= nil) then
        msgBytes[28] = tonumber(control["upstair_hour"])
    end
    if (control["upstair_min"] ~= nil) then
        msgBytes[15] = tonumber(control["upstair_min"])
    end
    if (control["upstair_sec"] ~= nil) then
        msgBytes[16] = tonumber(control["upstair_sec"])
    end
    if (control["middlestair_hour"] ~= nil) then
        msgBytes[29] = tonumber(control["middlestair_hour"])
    end
    if (control["middlestair_min"] ~= nil) then
        msgBytes[26] = tonumber(control["middlestair_min"])
    end
    if (control["middlestair_sec"] ~= nil) then
        msgBytes[27] = tonumber(control["middlestair_sec"])
    end
    if (control["downstair_hour"] ~= nil) then
        msgBytes[30] = tonumber(control["downstair_hour"])
    end
    if (control["downstair_min"] ~= nil) then
        msgBytes[20] = tonumber(control["downstair_min"])
    end
    if (control["downstair_sec"] ~= nil) then
        msgBytes[21] = tonumber(control["downstair_sec"])
    end
    return msgBytes
end
local function assembleByteFromOrderJson(control, msgBytes)
    msgBytes[10] = 0x02
    msgBytes[11] = 0x24
    msgBytes[12] = 0x02
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
    if (control['order_hour'] ~= nil) then
        msgBytes[13] = tonumber(control['order_hour'])
    end
    if (control['order_min'] ~= nil) then
        msgBytes[14] = tonumber(control['order_min'])
    end
    if (control["upstair_mode"] ~= nil) then
        msgBytes[17] = tonumber(control["upstair_mode"])
        msgBytes[16] = 0x03
    end
    if (control["upstair_temp"] ~= nil) then
        msgBytes[18] = tonumber(control["upstair_temp"])
    end
    if (control["downstair_mode"] ~= nil) then
        msgBytes[22] = tonumber(control["downstair_mode"])
        msgBytes[21] = 0x03
    end
    if (control["downstair_temp"] ~= nil) then
        msgBytes[23] = tonumber(control["downstair_temp"])
    end
    if (control["middlestair_mode"] ~= nil) then
        msgBytes[27] = tonumber(control["middlestair_mode"])
        msgBytes[26] = 0x03
    end
    if (control["middlestair_temp"] ~= nil) then
        msgBytes[28] = tonumber(control["middlestair_temp"])
    end
    return msgBytes
end
local function assembleByteFromJson(result, msgBytes)
    local query = result["query"]
    local control = result["control"]
    if (control) then
        result = control
        if (result["is_order"]) then
            if (result["is_order"] == "close") then
            else
                msgBytes = assembleByteFromOrderJson(result, msgBytes);
            end
        else
            msgBytes = assembleByteFromControlJson(result, msgBytes);
        end
    elseif (query) then
        msgBytes[10] = 0x03
        if (query["query_code"] ~= nil and query["query_code"] == "error_query") then
            msgBytes[11] = 0x32
        else
            msgBytes[11] = 0x31
        end
    end
    return msgBytes
end
local function parseByteToJson(status, bodyBytes)
    if ((bodyBytes[10] == 0x03 and bodyBytes[11] == 0x31) or
        (bodyBytes[10] == 0x04 and bodyBytes[11] == 0x41)) then
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
        end
        if (bodyBytes[13] ~= nil and bodyBytes[13] ~= 0xFF) then
            status["upstair_mode"] = tonumber(bodyBytes[13])
        end
        if (tonumber(bodyBytes[14]) ~= 0xFF) then
            status["upstair_temp"] = tonumber(bodyBytes[14])
        end
        if (bodyBytes[34] ~= nil and tonumber(bodyBytes[33]) ~= 0xFF) then
            status["upstair_hour"] = tonumber(bodyBytes[33])
        end
        if (tonumber(bodyBytes[15]) ~= 0xFF) then
            status["upstair_min"] = tonumber(bodyBytes[15])
        end
        if (tonumber(bodyBytes[16]) ~= 0xFF) then
            status["upstair_sec"] = tonumber(bodyBytes[16])
        end
        if (bodyBytes[17] == 0x00) then
            status["downstair_work_status"] = "power_off"
        elseif (bodyBytes[17] == 0x01) then
            status["downstair_work_status"] = "power_on"
        elseif (bodyBytes[17] == 0x02) then
            status["downstair_work_status"] = "working"
        elseif (bodyBytes[17] == 0x03) then
            status["downstair_work_status"] = "order"
        elseif (bodyBytes[17] == 0x04) then
            status["downstair_work_status"] = "finish"
        end
        if (bodyBytes[18] ~= nil and bodyBytes[18] ~= 0xFF) then
            status["downstair_mode"] = tonumber(bodyBytes[18])
        end
        if (tonumber(bodyBytes[19]) ~= 0xFF) then
            status["downstair_temp"] = tonumber(bodyBytes[19])
        end
        if (bodyBytes[35] ~= nil and tonumber(bodyBytes[35]) ~= 0xFF) then
            status["downstair_hour"] = tonumber(bodyBytes[35])
        end
        if (tonumber(bodyBytes[20]) ~= 0xFF) then
            status["downstair_min"] = tonumber(bodyBytes[20])
        end
        if (tonumber(bodyBytes[21]) ~= 0xFF) then
            status["downstair_sec"] = tonumber(bodyBytes[21])
        end
        if (bodyBytes[28] == 0x00) then
            status["middlestair_work_status"] = "power_off"
        elseif (bodyBytes[28] == 0x01) then
            status["middlestair_work_status"] = "power_on"
        elseif (bodyBytes[28] == 0x02) then
            status["middlestair_work_status"] = "working"
        elseif (bodyBytes[28] == 0x03) then
            status["middlestair_work_status"] = "order"
        elseif (bodyBytes[28] == 0x04) then
            status["middlestair_work_status"] = "finish"
        end
        if (bodyBytes[29] ~= nil and bodyBytes[29] ~= 0xFF) then
            status["middlestair_mode"] = tonumber(bodyBytes[29])
        end
        if (tonumber(bodyBytes[30]) ~= 0xFF) then
            status["middlestair_temp"] = tonumber(bodyBytes[30])
        end
        if (bodyBytes[35] ~= nil and tonumber(bodyBytes[34]) ~= 0xFF) then
            status["middlestair_hour"] = tonumber(bodyBytes[34])
        end
        if (tonumber(bodyBytes[31]) ~= 0xFF) then
            status["middlestair_min"] = tonumber(bodyBytes[31])
        end
        if (tonumber(bodyBytes[32]) ~= 0xFF) then
            status["middlestair_sec"] = tonumber(bodyBytes[32])
        end
        if bit_band(bodyBytes[22], 0x80) == 0x80 then
            status["is_error"] = true
        else
            status["is_error"] = false
        end
        if bit_band(bodyBytes[22], 0x10) == 0x10 then
            status["door_middlestair"] = "open"
        else
            status["door_middlestair"] = "close"
        end
        if bit_band(bodyBytes[22], 0x08) == 0x08 then
            status["uv_disinfect"] = "open"
        else
            status["uv_disinfect"] = "close"
        end
        if bit_band(bodyBytes[22], 0x04) == 0x04 then
            status["door_upstair"] = "open"
        else
            status["door_upstair"] = "close"
        end
        if bit_band(bodyBytes[22], 0x02) == 0x02 then
            status["door_downstair"] = "open"
        else
            status["door_downstair"] = "close"
        end
        if bit_band(bodyBytes[22], 0x01) == 0x01 then
            status["lock"] = "locked"
        else
            status["lock"] = "unlock"
        end
        if (tonumber(bodyBytes[24]) ~= 0xFF) then
            status["order_hour"] = tonumber(bodyBytes[24])
        end
        if (tonumber(bodyBytes[25]) ~= 0xFF) then
            status["order_min"] = tonumber(bodyBytes[25])
        end
        if (tonumber(bodyBytes[26]) ~= 0xFF) then
            status["order_sec"] = tonumber(bodyBytes[26])
        end
        if bit_band(bodyBytes[27], 0x01) == 0x01 then
            status["downstair_ispreheat"] = "preheat"
        else
            status["downstair_ispreheat"] = "unpreheat"
        end
        if bit_band(bodyBytes[27], 0x02) == 0x02 then
            status["upstair_ispreheat"] = "preheat"
        else
            status["upstair_ispreheat"] = "unpreheat"
        end
        if bit_band(bodyBytes[27], 0x04) == 0x04 then
            status["downstair_iscooling"] = "cooling"
        else
            status["downstair_iscooling"] = "uncooling"
        end
        if bit_band(bodyBytes[27], 0x08) == 0x08 then
            status["upstair_iscooling"] = "cooling"
        else
            status["upstair_iscooling"] = "uncooling"
        end
        if bit_band(bodyBytes[27], 0x10) == 0x10 then
            status["middlestair_ispreheat"] = "preheat"
        else
            status["middlestair_ispreheat"] = "unpreheat"
        end
        if bit_band(bodyBytes[27], 0x20) == 0x20 then
            status["middlestair_iscooling"] = "cooling"
        else
            status["middlestair_iscooling"] = "uncooling"
        end
    elseif (bodyBytes[10] == 0x02 and bodyBytes[11] == 0x21) then
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
        end
        if (bodyBytes[13] ~= nil and bodyBytes[13] ~= 0xFF) then
            status["upstair_mode"] = tonumber(bodyBytes[13])
        end
        if (tonumber(bodyBytes[14]) ~= 0xFF) then
            status["upstair_temp"] = tonumber(bodyBytes[14])
        end
        if (bodyBytes[30] ~= nil and tonumber(bodyBytes[28]) ~= 0xFF) then
            status["upstair_hour"] = tonumber(bodyBytes[28])
        end
        if (tonumber(bodyBytes[15]) ~= 0xFF) then
            status["upstair_min"] = tonumber(bodyBytes[15])
        end
        if (tonumber(bodyBytes[16]) ~= 0xFF) then
            status["upstair_sec"] = tonumber(bodyBytes[16])
        end
        if (bodyBytes[17] == 0x00) then
            status["downstair_work_status"] = "power_off"
        elseif (bodyBytes[17] == 0x01) then
            status["downstair_work_status"] = "power_on"
        elseif (bodyBytes[17] == 0x02) then
            status["downstair_work_status"] = "working"
        elseif (bodyBytes[17] == 0x03) then
            status["downstair_work_status"] = "order"
        elseif (bodyBytes[17] == 0x04) then
            status["downstair_work_status"] = "finish"
        end
        if (bodyBytes[18] ~= nil and bodyBytes[18] ~= 0xFF) then
            status["downstair_mode"] = tonumber(bodyBytes[18])
        end
        if (tonumber(bodyBytes[19]) ~= 0xFF) then
            status["downstair_temp"] = tonumber(bodyBytes[19])
        end
        if (bodyBytes[30] ~= nil and tonumber(bodyBytes[30]) ~= 0xFF) then
            status["downstair_hour"] = tonumber(bodyBytes[30])
        end
        if (tonumber(bodyBytes[20]) ~= 0xFF) then
            status["downstair_min"] = tonumber(bodyBytes[20])
        end
        if (tonumber(bodyBytes[21]) ~= 0xFF) then
            status["downstair_sec"] = tonumber(bodyBytes[21])
        end
        if (bodyBytes[22] == 0x00) then
            status["lock"] = "unlock"
        elseif (bodyBytes[22] == 0x01) then
            status["lock"] = "locked"
        elseif (bodyBytes[22] == 0x10) then
            status["uv_disinfect"] = "open"
        elseif (bodyBytes[22] == 0x11) then
            status["uv_disinfect"] = "close"
        end
        if (bodyBytes[23] == 0x00) then
            status["middlestair_work_status"] = "power_off"
        elseif (bodyBytes[23] == 0x01) then
            status["middlestair_work_status"] = "power_on"
        elseif (bodyBytes[23] == 0x02) then
            status["middlestair_work_status"] = "working"
        elseif (bodyBytes[23] == 0x03) then
            status["middlestair_work_status"] = "order"
        elseif (bodyBytes[23] == 0x04) then
            status["middlestair_work_status"] = "finish"
        end
        if (bodyBytes[24] ~= nil and bodyBytes[24] ~= 0xFF) then
            status["middlestair_mode"] = tonumber(bodyBytes[24])
        end
        if (tonumber(bodyBytes[25]) ~= 0xFF) then
            status["middlestair_temp"] = tonumber(bodyBytes[25])
        end
        if (bodyBytes[30] ~= nil and tonumber(bodyBytes[29]) ~= 0xFF) then
            status["middlestair_hour"] = tonumber(bodyBytes[29])
        end
        if (tonumber(bodyBytes[26]) ~= 0xFF) then
            status["middlestair_min"] = tonumber(bodyBytes[26])
        end
        if (tonumber(bodyBytes[27]) ~= 0xFF) then
            status["middlestair_sec"] = tonumber(bodyBytes[27])
        end
    elseif (bodyBytes[10] == 0x02 and bodyBytes[11] == 0x24) then
        if (bodyBytes[13] ~= 0xFF) then
            status["order_hour"] = tonumber(bodyBytes[13])
        end
        if (bodyBytes[14] ~= 0xFF) then
            status["order_min"] = tonumber(bodyBytes[14])
        end
        if (bodyBytes[15] ~= 0xFF) then
            status["order_sec"] = tonumber(bodyBytes[15])
        end
        if (bodyBytes[16] == 0x00) then
            status["upstair_work_status"] = "power_off"
        elseif (bodyBytes[16] == 0x01) then
            status["upstair_work_status"] = "power_on"
        elseif (bodyBytes[16] == 0x02) then
            status["upstair_work_status"] = "working"
        elseif (bodyBytes[16] == 0x03) then
            status["upstair_work_status"] = "order"
        end
        if (bodyBytes[17] ~= nil and bodyBytes[17] ~= 0xFF) then
            status["upstair_mode"] = tonumber(bodyBytes[17])
        end
        if (bodyBytes[18] ~= 0xFF) then
            status["upstair_temp"] = tonumber(bodyBytes[18])
        end
        if (bodyBytes[19] ~= 0xFF) then
            status["upstair_min"] = tonumber(bodyBytes[19])
        end
        if (bodyBytes[20] ~= 0xFF) then
            status["upstair_sec"] = tonumber(bodyBytes[20])
        end
        if (bodyBytes[21] == 0x00) then
            status["downstair_work_status"] = "power_off"
        elseif (bodyBytes[21] == 0x01) then
            status["downstair_work_status"] = "power_on"
        elseif (bodyBytes[21] == 0x02) then
            status["downstair_work_status"] = "working"
        elseif (bodyBytes[21] == 0x03) then
            status["downstair_work_status"] = "order"
        end
        if (bodyBytes[22] ~= nil and bodyBytes[22] ~= 0xFF) then
            status["downstair_mode"] = tonumber(bodyBytes[22])
        end
        if (bodyBytes[23] ~= 0xFF) then
            status["downstair_temp"] = tonumber(bodyBytes[23])
        end
        if (bodyBytes[24] ~= 0xFF) then
            status["downstair_min"] = tonumber(bodyBytes[24])
        end
        if (bodyBytes[25] ~= 0xFF) then
            status["downstair_sec"] = tonumber(bodyBytes[25])
        end
        if (bodyBytes[26] == 0x00) then
            status["middlestair_work_status"] = "power_off"
        elseif (bodyBytes[26] == 0x01) then
            status["middlestair_work_status"] = "power_on"
        elseif (bodyBytes[26] == 0x02) then
            status["middlestair_work_status"] = "working"
        elseif (bodyBytes[26] == 0x03) then
            status["middlestair_work_status"] = "order"
        end
        if (bodyBytes[27] ~= nil and bodyBytes[27] ~= 0xFF) then
            status["middlestair_mode"] = tonumber(bodyBytes[27])
        end
        if (bodyBytes[28] ~= 0xFF) then
            status["middlestair_temp"] = tonumber(bodyBytes[28])
        end
        if (bodyBytes[29] ~= 0xFF) then
            status["middlestair_min"] = tonumber(bodyBytes[29])
        end
        if (bodyBytes[30] ~= 0xFF) then
            status["middlestair_sec"] = tonumber(bodyBytes[30])
        end
    elseif (bodyBytes[10] == 0x04 and bodyBytes[11] == 0x0A) then
        status["error_code"] = "no_error"
        if (bodyBytes[12] ~= 0x00 and bodyBytes[12] ~= 0xFF) then
            status["error_up_temp_sensor"] = 0x01
            status["error_code"] = "error"
        else
            status["error_up_temp_sensor"] = 0x00
        end
        if (bodyBytes[13] ~= 0x00 and bodyBytes[13] ~= 0xFF) then
            status["error_down_temp_sensor"] = 0x01
            status["error_code"] = "error"
        else
            status["error_down_temp_sensor"] = 0x00
        end
        if (bodyBytes[14] ~= 0x00 and bodyBytes[14] ~= 0xFF) then
            status["error_up_heater"] = 0x01
            status["error_code"] = "error"
        else
            status["error_up_heater"] = 0x00
        end
        if (bodyBytes[15] ~= 0x00 and bodyBytes[15] ~= 0xFF) then
            status["error_down_heater"] = 0x01
            status["error_code"] = "error"
        else
            status["error_down_heater"] = 0x00
        end
        if (bodyBytes[16] ~= 0x00 and bodyBytes[16] ~= 0xFF) then
            status["error_temp_controller"] = 0x01
            status["error_code"] = "error"
        else
            status["error_temp_controller"] = 0x00
        end
        status['error_door_state_up'] = 0x00
        status['error_door_state_down'] = 0x00
        status['error_door_state_middle'] = 0x00
        if (bodyBytes[17] ~= 0x00 and bodyBytes[17] ~= 0xFF) then
            if (bodyBytes[18] ~= 0x00 and bodyBytes[18] ~= 0xFF) then
                if (bodyBytes[18]) == 0x01 then
                    status["error_door_state_up"] = 0x01
                    status["error_code"] = "error"
                elseif (bodyBytes[18]) == 0x02 then
                    status["error_door_state_down"] = 0x01
                    status["error_code"] = "error"
                elseif (bodyBytes[18]) == 0x04 then
                    status["error_door_state_middle"] = 0x01
                    status["error_code"] = "error"
                elseif (bodyBytes[18]) == 0x03 then
                    status['error_door_state_up'] = 0x01
                    status['error_door_state_down'] = 0x01
                    status['error_door_state_middle'] = 0x01
                    status["error_code"] = "error"
                end
            end
        end
        if (bodyBytes[19] ~= 0x00 and bodyBytes[19] ~= 0xFF) then
            status["error_middle_temp_sensor"] = 0x01
            status["error_code"] = "error"
        else
            status["error_middle_temp_sensor"] = 0x00
        end
        if (bodyBytes[20] ~= 0x00 and bodyBytes[20] ~= 0xFF) then
            status["error_middle_heater"] = 0x01
            status["error_code"] = "error"
        else
            status["error_middle_heater"] = 0x00
        end
    elseif (bodyBytes[10] == 0x03 and bodyBytes[11] == 0x32) then
        if (bodyBytes[12] == 0x01) then
            status["error_code"] = "error"
            if (bodyBytes[13] == 0x01 or bodyBytes[13] == 0x02) then
                status["error_up_temp_sensor"] = 0x01
            else
                status["error_middle_heater"] = 0x00
            end
            if (bodyBytes[14] == 0x01 or bodyBytes[14] == 0x02) then
                status["error_down_temp_sensor"] = 0x01
            else
                status["error_down_temp_sensor"] = 0x00
            end
            if (bodyBytes[15] == 0x01 or bodyBytes[15] == 0x02) then
                status["error_up_heater"] = 0x01
            else
                status["error_up_heater"] = 0x00
            end
            if (bodyBytes[16] == 0x01 or bodyBytes[16] == 0x02) then
                status["error_down_heater"] = 0x01
            else
                status["error_down_heater"] = 0x00
            end
            if (bodyBytes[17] == 0x01 or bodyBytes[17] == 0x02) then
                status["error_middle_temp_sensor"] = 0x01
            else
                status["error_middle_temp_sensor"] = 0x00
            end
            if (bodyBytes[18] == 0x01 or bodyBytes[18] == 0x02) then
                status["error_middle_heater"] = 0x01
            else
                status["error_middle_heater"] = 0x00
            end
        end
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
