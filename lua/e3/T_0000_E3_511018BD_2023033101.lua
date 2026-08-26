local bit = require "bit"
local VALUE_VERSION = 24
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
local function isNewAgreement(deviceSubType)
    if (deviceSubType == 32 or deviceSubType == 33 or deviceSubType == 34 or
        deviceSubType == 35 or deviceSubType == 36 or deviceSubType == 37 or
        deviceSubType == 38 or deviceSubType == 39 or deviceSubType == 40 or
        deviceSubType == 43 or deviceSubType == 48 or deviceSubType == 49 or
        deviceSubType == 80) then return false end
    return true
end
local function oldCtrlAgreementJsonToCmd(json, cmd)
    cmd[11] = 0x04
    cmd[12] = 0x01
    cmd[13] = 0x00
    cmd[19] = 0x00
    if (json["cold_water"]) then
        if (json["cold_water"] == "on") then
            cmd[13] = setBit(cmd[13], 0, '1')
        elseif (json["cold_water"] == "off") then
            cmd[13] = setBit(cmd[13], 0, '0')
        end
    end
    if json["bathtub"] == "on" then
        cmd[13] = setBit(cmd[13], 3, '1')
    elseif json["bathtub"] == "off" then
        cmd[13] = setBit(cmd[13], 3, '0')
    end
    if json["bathtub_water_level"] ~= nil then
        local bathtubWaterLevel = getNumber(json["bathtub_water_level"])
        if (bathtubWaterLevel < 256 * 256) then
            cmd[18] = bathtubWaterLevel % 256
            cmd[17] = (bathtubWaterLevel - cmd[18]) / 256
        end
    end
    if json["ultraviolet"] == "on" then
        cmd[13] = setBit(cmd[13], 6, '1')
    elseif json["ultraviolet"] == "off" then
        cmd[13] = setBit(cmd[13], 6, '0')
    end
    if json["safe"] == "on" then
        cmd[14] = setBit(cmd[14], 3, '1')
    elseif json["safe"] == "off" then
        cmd[14] = setBit(cmd[14], 3, '0')
    end
    if json["cold_water_dot"] == "on" then
        cmd[14] = setBit(cmd[14], 4, '1')
    elseif json["cold_water_dot"] == "off" then
        cmd[14] = setBit(cmd[14], 4, '0')
    end
    if json["change_litre_switch"] == "on" then
        cmd[14] = setBit(cmd[14], 5, '1')
    elseif json["change_litre_switch"] == "off" then
        cmd[14] = setBit(cmd[14], 5, '0')
    end
    if (json["mode"]) then
        if json["mode"] == "shower" then
            cmd[13] = setBit(cmd[13], 1, '1')
        elseif json["mode"] == "kitchen" then
            cmd[13] = setBit(cmd[13], 2, '1')
        elseif json["mode"] == "thalposis" then
            cmd[13] = setBit(cmd[13], 4, '1')
        elseif json["mode"] == "intelligence" then
            cmd[13] = setBit(cmd[13], 5, '1')
        elseif json["mode"] == "eco" then
            cmd[19] = setBit(cmd[19], 1, '1')
        elseif json["mode"] == "unfreeze" then
            cmd[19] = setBit(cmd[19], 2, '1')
        elseif json["mode"] == "wash_bowl" then
            cmd[19] = setBit(cmd[19], 3, '1')
        elseif json["mode"] == "high_temperature" then
            cmd[19] = setBit(cmd[19], 4, '1')
        elseif json["mode"] == "baby" then
            cmd[19] = setBit(cmd[19], 5, '1')
        elseif json["mode"] == "adult" then
            cmd[19] = setBit(cmd[19], 6, '1')
        elseif json["mode"] == "old" then
            cmd[19] = setBit(cmd[19], 7, '1')
        end
    end
    if json["capacity"] ~= nil then
        local capacity = getNumber(json["capacity"])
        if capacity == 1 then
            cmd[14] = setBit(cmd[14], 0, '1')
        elseif capacity == 2 then
            cmd[14] = setBit(cmd[14], 1, '1')
        elseif capacity == 3 then
            cmd[14] = setBit(cmd[14], 2, '1')
        end
    end
    if json["temperature"] ~= nil then
        local temperature = getNumber(json["temperature"])
        if (temperature < 256 * 256) then
            cmd[16] = temperature % 256
            cmd[15] = (temperature - cmd[16]) / 256
        end
        cmd[13] = 0x00
        cmd[19] = 0x00
        cmd[13] = 0x02
    end
    return cmd
end
local function newCtrlAgreementJsonToCmd(json, cmd)
    cmd[11] = 0x14
    if (json["change_litre_switch"]) then
        cmd[12] = 0x07
        cmd[30] = 0x00
        if (json["change_litre_switch"] == "on") then
            cmd[13] = 0x01
        elseif (json["change_litre_switch"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["change_litre_switch_beep"]) then
        cmd[12] = 0x07
        cmd[30] = 0x01
        if (json["change_litre_switch_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["change_litre_switch_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["capacity"]) then
        cmd[12] = 0x05
        cmd[30] = 0x00
        if (json["capacity"] == 1) then
            cmd[13] = 0x01
        elseif (json["capacity"] == 2) then
            cmd[13] = 0x02
        elseif (json["capacity"] == 3) then
            cmd[13] = 0x04
        end
    end
    if (json["capacity_beep"]) then
        cmd[12] = 0x05
        cmd[30] = 0x01
        if (json["capacity_beep"] == 1) then
            cmd[13] = 0x01
        elseif (json["capacity_beep"] == 2) then
            cmd[13] = 0x02
        elseif (json["capacity_beep"] == 3) then
            cmd[13] = 0x04
        end
    end
    if (json["cold_water"]) then
        cmd[12] = 0x03
        cmd[30] = 0x00
        if (json["cold_water"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_beep"]) then
        cmd[12] = 0x03
        cmd[30] = 0x01
        if (json["cold_water_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_master"]) then
        cmd[12] = 0x12
        cmd[30] = 0x00
        if (json["cold_water_master"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_master"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_master_beep"]) then
        cmd[12] = 0x12
        cmd[30] = 0x01
        if (json["cold_water_master_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_master_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_conservation"]) then
        cmd[12] = 0x16
        cmd[30] = 0x00
        if (json["cold_water_conservation"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_conservation"] == "off") then
            cmd[13] = 0x00
            cmd[14] = json['cold_water_duration']
        end
    end
    if (json["cold_water_conservation_beep"]) then
        cmd[12] = 0x12
        cmd[30] = 0x01
        if (json["cold_water_conservatio_beepn"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_conservation_beep"] == "off") then
            cmd[13] = 0x00
            cmd[14] = json['cold_water_duration']
        end
    end
    if (json["cold_water_dot"]) then
        cmd[12] = 0x04
        cmd[30] = 0x00
        if (json["cold_water_dot"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_dot"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_dot_beep"]) then
        cmd[12] = 0x04
        cmd[30] = 0x01
        if (json["cold_water_dot_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_dot_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_ai"]) then
        cmd[12] = 0x0E
        cmd[30] = 0x00
        if (json["cold_water_ai"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_ai"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_ai_beep"]) then
        cmd[12] = 0x0E
        cmd[30] = 0x01
        if (json["cold_water_ai_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_ai_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_pressure"]) then
        cmd[12] = 0x0A
        cmd[30] = 0x00
        if (json["cold_water_pressure"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_pressure"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_pressure_beep"]) then
        cmd[12] = 0x0A
        cmd[30] = 0x01
        if (json["cold_water_pressure_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["cold_water_pressure_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_high_tem"]) then
        cmd[12] = 0x1B
        cmd[30] = 0x00
        if (json["cold_water_high_tem"] == "on") then
            cmd[13] = 0x01
            cmd[14] = json["cold_water_high_tem_num"]
        elseif (json["cold_water_high_tem"] == "off") then
            cmd[13] = 0x00
            cmd[14] = json["cold_water_high_tem_num"]
        end
    end
    if (json["cold_water_high_tem_beep"]) then
        cmd[12] = 0x1B
        cmd[30] = 0x01
        if (json["cold_water_high_tem_beep"] == "on") then
            cmd[13] = 0x01
            cmd[14] = json["cold_water_high_tem_num"]
        elseif (json["cold_water_high_tem_beep"] == "off") then
            cmd[13] = 0x00
            cmd[14] = json["cold_water_high_tem_num"]
        end
    end
    if (json["bubble"]) then
        cmd[12] = 0x10
        cmd[30] = 0x00
        if (json["bubble"] == 0) then
            cmd[13] = 0x00
        elseif (json["bubble"] == 1) then
            cmd[13] = 0x01
        elseif (json["bubble"] == 2) then
            cmd[13] = 0x02
        end
    end
    if (json["bubble_beep"]) then
        cmd[12] = 0x10
        cmd[30] = 0x01
        if (json["bubble_beep"] == 0) then
            cmd[13] = 0x00
        elseif (json["bubble_beep"] == 1) then
            cmd[13] = 0x01
        elseif (json["bubble_beep"] == 2) then
            cmd[13] = 0x02
        end
    end
    if (json["sterilization"]) then
        cmd[12] = 0x1A
        cmd[30] = 0x00
        if (json["sterilization"] == 0) then
            cmd[13] = 0x00
        elseif (json["sterilization"] == 1) then
            cmd[13] = 0x01
        elseif (json["sterilization"] == 2) then
            cmd[13] = 0x02
        end
    end
    if (json["sterilizatione_beep"]) then
        cmd[12] = 0x1A
        cmd[30] = 0x01
        if (json["sterilization_beep"] == 0) then
            cmd[13] = 0x00
        elseif (json["sterilization_beep"] == 1) then
            cmd[13] = 0x01
        elseif (json["sterilizatione_beep"] == 2) then
            cmd[13] = 0x02
        end
    end
    if (json["pipe_uv"]) then
        cmd[12] = 0x1D
        cmd[30] = 0x00
        if (json["pipe_uv"] == 'on') then
            cmd[13] = 0x01
        elseif (json["pipe_uv"] == 'off') then
            cmd[13] = 0x00
        end
    end
    if (json["pipe_uv_beep"]) then
        cmd[12] = 0x1D
        cmd[30] = 0x00
        if (json["pipe_uv_beep"] == 'on') then
            cmd[13] = 0x01
        elseif (json["pipe_uv_beep"] == 'off') then
            cmd[13] = 0x00
        end
    end
    if (json["bathtub"]) then
        cmd[12] = 0x09
        cmd[30] = 0x00
        cmd[14] = json["bathtub_water_level"]
        if (json["bathtub"] == "on") then
            cmd[13] = 0x01
        elseif (json["bathtub"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["bathtub_beep"]) then
        cmd[12] = 0x09
        cmd[30] = 0x01
        cmd[14] = json["bathtub_water_level"]
        if (json["bathtub_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["bathtub_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["bathtub_up"]) then
        cmd[12] = 0x17
        cmd[30] = 0x00
        if json["bathtub_water_level_up"] ~= nil then
            local bathtubWaterLevel = getNumber(json["bathtub_water_level_up"])
            if (bathtubWaterLevel < 256 * 256) then
                cmd[15] = bathtubWaterLevel % 256
                cmd[14] = (bathtubWaterLevel - cmd[15]) / 256
            end
        end
        if (json["bathtub_up"] == "on") then
            cmd[13] = 0x01
        elseif (json["bathtub_up"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["bathtub_up_beep"]) then
        cmd[12] = 0x14
        cmd[30] = 0x01
        if json["bathtub_water_level_up"] ~= nil then
            local bathtubWaterLevel = getNumber(json["bathtub_water_level_up"])
            if (bathtubWaterLevel < 256 * 256) then
                cmd[15] = bathtubWaterLevel % 256
                cmd[14] = (bathtubWaterLevel - cmd[15]) / 256
            end
        end
        if (json["bathtub_up_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["bathtub_up_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["person_mode_one"]) then
        cmd[12] = 0x0B
        cmd[30] = 0x00
        cmd[14] = json["person_tem_one"]
        if (json["person_mode_one"] == "on") then
            cmd[13] = 0x01
        elseif (json["person_mode_one"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["person_mode_one_beep"]) then
        cmd[12] = 0x0B
        cmd[30] = 0x01
        cmd[14] = json["person_tem_one"]
        if (json["person_mode_one_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["person_mode_one_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["person_mode_two"]) then
        cmd[12] = 0x0C
        cmd[30] = 0x00
        cmd[14] = json["person_tem_two"]
        if (json["person_mode_two"] == "on") then
            cmd[13] = 0x01
        elseif (json["person_mode_two"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["person_mode_two_beep"]) then
        cmd[12] = 0x0C
        cmd[30] = 0x01
        cmd[14] = json["person_tem_two"]
        if (json["person_mode_two_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["person_mode_two_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["person_mode_three"]) then
        cmd[12] = 0x0F
        cmd[30] = 0x00
        cmd[14] = json["person_tem_three"]
        if (json["person_mode_three"] == "on") then
            cmd[13] = 0x01
        elseif (json["person_mode_three"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["person_mode_three_beep"]) then
        cmd[12] = 0x0F
        cmd[30] = 0x01
        cmd[14] = json["person_tem_three"]
        if (json["person_mode_three_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["person_mode_three_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["gesture_function"]) then
        cmd[12] = 0x0D
        cmd[30] = 0x00
        cmd[14] = json["gesture_function_type"]
        if (json["gesture_function"] == "on") then
            cmd[13] = 0x01
        elseif (json["gesture_function"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["gesture_function_beep"]) then
        cmd[12] = 0x0D
        cmd[30] = 0x01
        cmd[14] = json["gesture_function_type"]
        if (json["gesture_function_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["gesture_function_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["safe"]) then
        cmd[12] = 0x06
        cmd[30] = 0x00
        if (json["safe"] == "on") then
            cmd[13] = 0x01
        elseif (json["safe"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["safe_beep"]) then
        cmd[12] = 0x06
        cmd[30] = 0x01
        if (json["safe_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["safe_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["appoint_switch"]) then
        cmd[12] = 0x11
        cmd[30] = 0x00
        if (json["appoint_switch"] == "on") then
            cmd[13] = 0x00
        elseif (json["appoint_switch"] == "off") then
            cmd[13] = 0x01
        end
    end
    if (json["appoint_switch_beep"]) then
        cmd[12] = 0x11
        cmd[30] = 0x01
        if (json["appoint_switch_beep"] == "on") then
            cmd[13] = 0x00
        elseif (json["appoint_switch_beep"] == "off") then
            cmd[13] = 0x01
        end
    end
    if (json["appoint_mode"]) then
        cmd[12] = 0x13
        cmd[30] = 0x00
        if (json["appoint_mode"] == "on") then
            cmd[13] = 0x01
        elseif (json["appoint_mode"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["appoint_mode_beep"]) then
        cmd[12] = 0x13
        cmd[30] = 0x01
        if (json["appoint_mode_beep"] == "on") then
            cmd[13] = 0x01
        elseif (json["appoint_mode_beep"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["appoint_master_switch"]) then
        cmd[12] = 0x14
        cmd[30] = 0x00
        if (json["appoint_master_switch"] == "on") then
            cmd[13] = 0x00
        elseif (json["appoint_master_switch"] == "off") then
            cmd[13] = 0x01
        end
    end
    if (json["appoint_master_switch_beep"]) then
        cmd[12] = 0x14
        cmd[30] = 0x01
        if (json["appoint_master_switch_beep"] == "on") then
            cmd[13] = 0x00
        elseif (json["appoint_master_switch_beep"] == "off") then
            cmd[13] = 0x01
        end
    end
    if (json["mode"]) then
        cmd[12] = 0x02
        cmd[30] = 0x00
        if (json["mode"] == "shower") then
            cmd[13] = 0x02
            cmd[14] = 0x00
        elseif (json["mode"] == "kitchen") then
            cmd[13] = 0x04
            cmd[14] = 0x00
        elseif (json["mode"] == "thalposis") then
            cmd[13] = 0x10
            cmd[14] = 0x00
        elseif (json["mode"] == "intel_temperature") then
            cmd[13] = 0x80
            cmd[14] = 0x00
        elseif (json["mode"] == "eco") then
            cmd[14] = 0x02
            cmd[13] = 0x00
        elseif (json["mode"] == "wash_bowl") then
            cmd[14] = 0x08
            cmd[13] = 0x00
        elseif (json["mode"] == "high_temperature") then
            cmd[14] = 0x10
            cmd[13] = 0x00
        elseif (json["mode"] == "baby") then
            cmd[14] = 0x20
            cmd[13] = 0x00
        elseif (json["mode"] == "adult") then
            cmd[14] = 0x40
            cmd[13] = 0x00
        elseif (json["mode"] == "old") then
            cmd[14] = 0x80
            cmd[13] = 0x00
        elseif (json["mode"] == "pet_wash") then
            cmd[13] = 0x00
            cmd[14] = 0x00
            cmd[15] = 0x01
        end
    end
    if (json["mode_beep"]) then
        cmd[12] = 0x02
        cmd[30] = 0x01
        if (json["mode_beep"] == "shower") then
            cmd[13] = 0x02
            cmd[14] = 0x00
        elseif (json["mode_beep"] == "kitchen") then
            cmd[13] = 0x04
            cmd[14] = 0x00
        elseif (json["mode_beep"] == "thalposis") then
            cmd[13] = 0x10
            cmd[14] = 0x00
        elseif (json["mode_beep"] == "intel_temperature") then
            cmd[13] = 0x80
            cmd[14] = 0x00
        elseif (json["mode_beep"] == "eco") then
            cmd[14] = 0x02
            cmd[13] = 0x00
        elseif (json["mode_beep"] == "wash_bowl") then
            cmd[14] = 0x08
            cmd[13] = 0x00
        elseif (json["mode_beep"] == "high_temperature") then
            cmd[14] = 0x10
            cmd[13] = 0x00
        elseif (json["mode_beep"] == "baby") then
            cmd[14] = 0x20
            cmd[13] = 0x00
        elseif (json["mode_beep"] == "adult") then
            cmd[14] = 0x40
            cmd[13] = 0x00
        elseif (json["mode_beep"] == "old") then
            cmd[14] = 0x80
            cmd[13] = 0x00
        elseif (json["mode_beep"] == "pet_wash") then
            cmd[13] = 0x00
            cmd[14] = 0x00
            cmd[15] = 0x01
        end
    end
    if (json["temperature"]) then
        cmd[12] = 0x08
        cmd[13] = json["temperature"]
        cmd[30] = 0x00
    end
    if (json["temperature_beep"]) then
        cmd[12] = 0x08
        cmd[13] = json["temperature_beep"]
        cmd[30] = 0x01
    end
    if (json["master_beep"]) then
        cmd[12] = 0x15
        if (json["master_beep"] == "on") then
            cmd[13] = 0x01
            cmd[30] = 0x01
        elseif (json["master_beep"] == "off") then
            cmd[13] = 0x00
            cmd[30] = 0x00
        end
    end
    if (json["filter_life"] == "on") then
        cmd[12] = 0x19
        cmd[13] = 0x01
        cmd[30] = 0x00
    end
    if (json["filter_life_beep"] == "on") then
        cmd[12] = 0x19
        cmd[13] = 0x01
        cmd[30] = 0x01
    end
    if (json["double_pressure"]) then
        cmd[12] = 0x1C
        cmd[30] = 0x00
        if (json["double_pressure"] == 0) then
            cmd[13] = 0x00
        elseif (json["double_pressure"] == 1) then
            cmd[13] = 0x01
        elseif (json["double_pressure"] == 2) then
            cmd[13] = 0x02
        elseif (json["double_pressure"] == 3) then
            cmd[13] = 0x03
        elseif (json["double_pressure"] == 4) then
            cmd[13] = 0x04
        end
    end
    if (json["double_pressure_beep"]) then
        cmd[12] = 0x1C
        cmd[30] = 0x01
        if (json["double_pressure_beep"] == 0) then
            cmd[13] = 0x00
        elseif (json["double_pressure_beep"] == 1) then
            cmd[13] = 0x01
        elseif (json["double_pressure_beep"] == 2) then
            cmd[13] = 0x02
        elseif (json["double_pressure_beep"] == 3) then
            cmd[13] = 0x03
        elseif (json["double_pressure_beep"] == 4) then
            cmd[13] = 0x04
        end
    end
    if (json["bathtub_curve"]) then
        cmd[12] = 0x1F
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["bathtub_curve"] == 0) then
            cmd[13] = 0x00
        elseif (json["bathtub_curve"] == 1) then
            cmd[13] = 0x01
        elseif (json["bathtub_curve"] == 2) then
            cmd[13] = 0x02
        elseif (json["bathtub_curve"] == 3) then
            cmd[13] = 0x03
        end
    end
    if (json["high_temp_lock"]) then
        cmd[12] = 0x1E
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["high_temp_lock"] == "on") then
            cmd[13] = 0x01
        elseif (json["high_temp_lock"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cloud_tem"]) then
        cmd[12] = 0x20
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["cloud_tem"] == "on") then
            cmd[13] = 0x01
        elseif (json["cloud_tem"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["cruise_antifreeze"]) then
        cmd[12] = 0x26
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["cruise_antifreeze"] == "on") then
            cmd[13] = 0x00
        elseif (json["cruise_antifreeze"] == "off") then
            cmd[13] = 0x01
        end
    end
    if (json["zero_temperature"]) then
        cmd[12] = 0x28
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["zero_temperature"] == "on") then
            cmd[13] = 0x01
        elseif (json["zero_temperature"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["ai_kitchen"]) then
        cmd[12] = 0x24
        cmd[13] = 0x03
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["ai_kitchen"] == "on") then
            cmd[18] = 0x01
        elseif (json["ai_kitchen"] == "off") then
            cmd[18] = 0x00
        end
    end
    if (json["ai_kitchen_aimode"]) then
        cmd[12] = 0x24
        cmd[13] = 0x00
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["ai_kitchen_aimode"] == "on") then
            cmd[14] = 0x01
        elseif (json["ai_kitchen_aimode"] == "off") then
            cmd[14] = 0x00
        end
    end
    if (json["ai_kitchen_diymode"]) then
        cmd[12] = 0x24
        cmd[13] = 0x00
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["ai_kitchen_diymode"] == "on") then
            cmd[15] = 0x01
        elseif (json["ai_kitchen_diymode"] == "off") then
            cmd[15] = 0x00
        end
    end
    if (json["voice_power"]) then
        cmd[12] = 0x23
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["voice_power"] == "on") then
            cmd[13] = 0x00
        elseif (json["voice_power"] == "off") then
            cmd[13] = 0x01
        end
    end
    if (json["volume"]) then
        cmd[12] = 0x23
        if (json["volume"] == 0) then
            cmd[14] = 0x00
        elseif (json["volume"] == 20) then
            cmd[14] = 0x14
        elseif (json["volume"] == 40) then
            cmd[14] = 0x28
        elseif (json["volume"] == 60) then
            cmd[14] = 0x3C
        elseif (json["volume"] == 80) then
            cmd[14] = 0x50
        elseif (json["volume"] == 100) then
            cmd[14] = 0x64
        end
    end
    if (json["lamp_control1_power"] and json["lamp_control2_power"] and
        json["lamp_control3_power"]) then
        cmd[12] = 0x21
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["lamp_control1_power"] == "on") then
            cmd[13] = setBit(cmd[13], 0, '1')
        end
        if (json["lamp_control2_power"] == "on") then
            cmd[13] = setBit(cmd[13], 1, '1')
        end
        if (json["lamp_control3_power"] == "on") then
            cmd[13] = setBit(cmd[13], 2, '1')
        end
    end
    if (json["spa_mode"]) then
        cmd[12] = 0x22
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["spa_mode"] == "on") then
            cmd[13] = 0x01
        elseif (json["spa_mode"] == "off") then
            cmd[13] = 0x00
        end
    end
    if (json["sos_power"] and json["warning_power"]) then
        cmd[12] = 0x27
        if (json['beep']) then
            cmd[30] = 0x01
        else
            cmd[30] = 0x00
        end
        if (json["sos_power"] == "on") then
            cmd[13] = setBit(cmd[13], 0, '1')
        else
            cmd[13] = setBit(cmd[13], 0, '0')
        end
        if (json["warning_power"] == "on") then
            cmd[13] = setBit(cmd[13], 1, '1')
        else
            cmd[13] = setBit(cmd[13], 1, '0')
        end
    end
    if (json['appoint_morning']) then
        cmd[11] = 0x0B
        cmd[12] = 0x00
        local appointMorning = Split(tostring(json['appoint_morning']), ',')
        for i, v in ipairs(appointMorning) do cmd[i + 12] = tonumber(v) end
    end
    if (json['appoint_afternoon']) then
        cmd[11] = 0x0C
        cmd[12] = 0x01
        local appointAfternoon = Split(tostring(json['appoint_afternoon']), ',')
        for i, v in ipairs(appointAfternoon) do cmd[i + 12] = tonumber(v) end
    end
    if (json['bath_head_btn']) then
        cmd[11] = 0x0D
        cmd[13] = 0x05
        cmd[14] = 0x03
        cmd[15] = 0x1E
        cmd[16] = 0x1E
        if (json["bath_head_btn"] == "on") then
            cmd[12] = 0x01
            cmd[30] = 0x00
        elseif (json["bath_head_btn"] == "off") then
            cmd[12] = 0x00
            cmd[30] = 0x00
        end
    end
    if (json['bath_head_btn_beep']) then
        cmd[11] = 0x0D
        cmd[13] = 0x05
        cmd[14] = 0x03
        cmd[15] = 0x1E
        cmd[16] = 0x1E
        if (json["bath_head_btn_beep"] == "on") then
            cmd[12] = 0x01
            cmd[30] = 0x01
        elseif (json["bath_head_btn_beep"] == "off") then
            cmd[12] = 0x00
            cmd[30] = 0x01
        end
    end
    if (json["recover_set"]) then
        cmd[11] = 0x08
        cmd[12] = 0x01
        cmd[13] = 0x00
    end
    if (json["parameter_set"]) then
        cmd[10] = 0x02
        cmd[11] = 0x08
        cmd[12] = 0x02
        cmd[13] = json["key_fa"]
        cmd[14] = json["key_ff"]
        cmd[15] = json["key_ph"]
        cmd[16] = json["key_fh"]
        cmd[17] = json["key_pl"]
        cmd[18] = json["key_fl"]
        cmd[19] = json["key_dh"]
        cmd[20] = json["key_fd"]
        cmd[21] = json["key_ch"]
        cmd[22] = json["key_fc"]
        cmd[23] = json["key_ca"]
        cmd[24] = json["key_ne"]
        cmd[25] = json["key_fp"]
        cmd[26] = json["key_hs"]
        cmd[27] = json["key_hb"]
        cmd[28] = json["key_he"]
        cmd[29] = json["key_hl"]
        cmd[30] = json["key_hu"]
    end
    return cmd
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
            cmd[30] = 0x00
            if (control["power"] == "on") then
                cmd[11] = 0x01
            elseif (control["power"] == "off") then
                cmd[11] = 0x02
            end
        elseif (control["power_beep"]) then
            cmd[12] = 0x01
            cmd[30] = 0x01
            if (control["power_beep"] == "on") then
                cmd[11] = 0x01
            elseif (control["power_beep"] == "off") then
                cmd[11] = 0x02
            end
        elseif (control['appoint_one']) then
            local appointJsonOne = Split(control['appoint_one'], ',')
            cmd[11] = 0x05
            cmd[12] = 0x01
            cmd[30] = 0x00
            cmd[13] = appointJsonOne[1]
            cmd[14] = appointJsonOne[2]
            cmd[15] = appointJsonOne[3]
            cmd[16] = appointJsonOne[4]
            cmd[17] = appointJsonOne[5]
            cmd[18] = appointJsonOne[6]
            cmd[19] = appointJsonOne[7]
        elseif (control['appoint_one_beep']) then
            local appointJsonOne = Split(control['appoint_one_beep'], ',')
            cmd[11] = 0x05
            cmd[12] = 0x01
            cmd[30] = 0x01
            cmd[13] = appointJsonOne[1]
            cmd[14] = appointJsonOne[2]
            cmd[15] = appointJsonOne[3]
            cmd[16] = appointJsonOne[4]
            cmd[17] = appointJsonOne[5]
            cmd[18] = appointJsonOne[6]
            cmd[19] = appointJsonOne[7]
        elseif (control['appoint_two']) then
            local appointJsonTwo = Split(control['appoint_two'], ',')
            cmd[11] = 0x06
            cmd[12] = 0x01
            cmd[30] = 0x00
            cmd[13] = appointJsonTwo[1]
            cmd[14] = appointJsonTwo[2]
            cmd[15] = appointJsonTwo[3]
            cmd[16] = appointJsonTwo[4]
            cmd[17] = appointJsonTwo[5]
            cmd[18] = appointJsonTwo[6]
            cmd[19] = appointJsonTwo[7]
        elseif (control['appoint_two_beep']) then
            local appointJsonTwo = Split(control['appoint_two_beep'], ',')
            cmd[11] = 0x06
            cmd[12] = 0x01
            cmd[30] = 0x01
            cmd[13] = appointJsonTwo[1]
            cmd[14] = appointJsonTwo[2]
            cmd[15] = appointJsonTwo[3]
            cmd[16] = appointJsonTwo[4]
            cmd[17] = appointJsonTwo[5]
            cmd[18] = appointJsonTwo[6]
            cmd[19] = appointJsonTwo[7]
        elseif (control['appoint_three']) then
            local appointJsonThree = Split(control['appoint_three'], ',')
            cmd[11] = 0x07
            cmd[12] = 0x01
            cmd[30] = 0x00
            cmd[13] = appointJsonThree[1]
            cmd[14] = appointJsonThree[2]
            cmd[15] = appointJsonThree[3]
            cmd[16] = appointJsonThree[4]
            cmd[17] = appointJsonThree[5]
            cmd[18] = appointJsonThree[6]
            cmd[19] = appointJsonThree[7]
        elseif (control['appoint_three_beep']) then
            local appointJsonThree = Split(control['appoint_three_beep'], ',')
            cmd[11] = 0x07
            cmd[12] = 0x01
            cmd[30] = 0x01
            cmd[13] = appointJsonThree[1]
            cmd[14] = appointJsonThree[2]
            cmd[15] = appointJsonThree[3]
            cmd[16] = appointJsonThree[4]
            cmd[17] = appointJsonThree[5]
            cmd[18] = appointJsonThree[6]
            cmd[19] = appointJsonThree[7]
        elseif (control['appoint_four']) then
            local appointJsonFour = Split(control['appoint_four'], ',')
            cmd[11] = 0x0A
            cmd[12] = 0x01
            cmd[30] = 0x00
            cmd[13] = appointJsonFour[1]
            cmd[14] = appointJsonFour[2]
            cmd[15] = appointJsonFour[3]
            cmd[16] = appointJsonFour[4]
            cmd[17] = appointJsonFour[5]
            cmd[18] = appointJsonFour[6]
            cmd[19] = appointJsonFour[7]
        elseif (control['appoint_four_beep']) then
            local appointJsonFour = Split(control['appoint_four_beep'], ',')
            cmd[11] = 0x0A
            cmd[12] = 0x01
            cmd[30] = 0x01
            cmd[13] = appointJsonFour[1]
            cmd[14] = appointJsonFour[2]
            cmd[15] = appointJsonFour[3]
            cmd[16] = appointJsonFour[4]
            cmd[17] = appointJsonFour[5]
            cmd[18] = appointJsonFour[6]
            cmd[19] = appointJsonFour[7]
        else
            if (isNewAgreement(deviceSubType)) then
                if (status) then
                    cmd = newCtrlAgreementJsonToCmd(status, cmd)
                end
                cmd = newCtrlAgreementJsonToCmd(control, cmd)
            else
                if (status) then
                    cmd = oldCtrlAgreementJsonToCmd(status, cmd)
                end
                cmd = oldCtrlAgreementJsonToCmd(control, cmd)
            end
        end
    elseif query then
        cmd[10] = 0x03
        cmd[11] = 0x01
        if (query["device_type"] == "controller") then
            cmd[12] = 0x11
        else
            cmd[12] = 0x01
        end
        if (query["query_type"] == "status") then
            cmd[11] = 0x01
        elseif (query["query_type"] == "predict") then
            cmd[11] = 0x02
        elseif (query["query_type"] == "predict_morning") then
            cmd[11] = 0x03
            cmd[12] = 0x00
        elseif (query["query_type"] == "predict_afternoon") then
            cmd[11] = 0x03
            cmd[12] = 0x01
        elseif (query["query_type"] == "mchine_parameters") then
            cmd[10] = 0x02
            cmd[11] = 0x08
            cmd[12] = 0x03
        elseif (query["query_type"] == "bath_head_parameters") then
            cmd[10] = 0x03
            cmd[11] = 0x05
            cmd[12] = 0x01
        end
    end
    return cmd
end
local function computeMode(bodyBytes)
    local gas_lift = 0;
    if (bit.band(bodyBytes[26], 0xFC) == 0) then
        gas_lift = 6;
    elseif (bit.band(bodyBytes[26], 0xFC) == 4) then
        gas_lift = 8;
    elseif (bit.band(bodyBytes[26], 0xFC) == 8) then
        gas_lift = 10;
    elseif (bit.band(bodyBytes[26], 0xFC) == 12) then
        gas_lift = 12;
    elseif (bit.band(bodyBytes[26], 0xFC) == 16) then
        gas_lift = 14;
    elseif (bit.band(bodyBytes[26], 0xFC) == 24) then
        gas_lift = 20;
    elseif (bit.band(bodyBytes[26], 0xFC) == 28) then
        gas_lift = 13;
    elseif (bit.band(bodyBytes[26], 0xFC) == 32) then
        gas_lift = 15;
    elseif (bit.band(bodyBytes[26], 0xFC) == 36) then
        gas_lift = 18;
    elseif (bit.band(bodyBytes[26], 0xFC) == 40) then
        gas_lift = 11;
    elseif (bit.band(bodyBytes[26], 0xFC) == 44) then
        gas_lift = 17;
    else
        gas_lift = 16;
    end
    return gas_lift;
end
local function isMoreInfoLength(infoLength)
    if (infoLength > 31) then return true end
    return false
end
local function cmdToJson(json, cmd)
    json["version"] = VALUE_VERSION
    local cmdLength = #cmd
    if (((cmd[10] == 0x04 and cmd[11] == 0x01) or
        (cmd[10] == 0x04 and cmd[11] == 0x00) or
        (cmd[10] == 0x03 and cmd[11] == 0x01) or
        (cmd[10] == 0x02 and cmd[11] == 0x01) or
        (cmd[10] == 0x02 and cmd[11] == 0x02) or
        (cmd[10] == 0x02 and cmd[11] == 0x14) or
        (cmd[10] == 0x02 and cmd[11] == 0x04)) and cmd[12] == 0x01) then
        json["device_type"] = "gasWaterHeate"
        json['out_water_tem'] = cmd[16]
        json['temperature'] = cmd[17]
        json['water_volume'] = cmd[18]
        json['bathtub_water_level'] = cmd[21] * 256 + cmd[20] * 1
        json['bathtub_water_level_up'] = cmd[23] * 256 + cmd[24] * 1
        json['zero_cold_tem'] = cmd[22]
        json['bath_out_volume'] = cmd[24] * 256 + cmd[23] * 1
        json['return_water_tem'] = cmd[25]
        json['change_litre'] = cmd[29]
        json['power_level'] = cmd[30]
        json['type_machine'] = cmd[26]
        if (isMoreInfoLength(cmdLength)) then
            json['person_tem_one'] = cmd[33]
            json['person_tem_two'] = cmd[34]
            json['person_tem_three'] = cmd[40]
            json['in_water_tem'] = cmd[37]
            json['cold_hold_duration'] = cmd[41]
            json['cold_conservation_duration'] = cmd[45]
            json['water_consumption'] = cmd[43] * 256 + cmd[44] * 1
        end
        json["change_litre"] = computeMode(cmd);
        if (isMoreInfoLength(cmdLength) and getBit(cmd[31], 1) == '1') then
            json["change_litre_switch"] = "on";
            if (getBit(cmd[13], 1) == '1') then
                json["change_litre"] = cmd[29];
            else
                json["change_litre"] = computeMode(cmd);
            end
        else
            json["change_litre_switch"] = "off";
            json["change_litre"] = computeMode(cmd);
        end
        if (getBit(cmd[15], 3) == '1') then
            json["capacity"] = 2
        elseif (getBit(cmd[15], 4) == '1') then
            json["capacity"] = 3
        else
            json["capacity"] = 1
        end
        if (getBit(cmd[13], 1) == '1') then
            if ((cmd[29] / computeMode(cmd)) > 1) then
                json['gas_lift_precent'] = 100;
            else
                json['gas_lift_precent'] = math.modf(
                                               (cmd[29] / computeMode(cmd)) *
                                                   100);
            end
        else
            json['gas_lift_precent'] = 0
        end
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
            json["cold_water"] = "on"
        else
            json["cold_water"] = "off"
        end
        if (isMoreInfoLength(cmdLength) and getBit(cmd[31], 7) == '1') then
            json["cold_water_master"] = "on"
        else
            json["cold_water_master"] = "off"
        end
        if (cmd[39] and getBit(cmd[39], 6) == '1') then
            json["cold_water_conservation"] = "on"
        else
            json["cold_water_conservation"] = "off"
        end
        if (isMoreInfoLength(cmdLength) and getBit(cmd[31], 0) == '1') then
            json["cold_water_dot"] = "on"
        else
            json["cold_water_dot"] = "off"
        end
        if (cmd[32] and getBit(cmd[32], 5) == '1') then
            json["cold_water_ai"] = "on"
        else
            json["cold_water_ai"] = "off"
        end
        if (isMoreInfoLength(cmdLength) and getBit(cmd[31], 2) == '1') then
            json["cold_water_pressure"] = "on"
        else
            json["cold_water_pressure"] = "off"
        end
        if (cmd[35] and getBit(cmd[35], 7) == '1') then
            json["bubble"] = 2
        elseif (cmd[35] and getBit(cmd[35], 6) == '1') then
            json["bubble"] = 1
        else
            json["bubble"] = 0
        end
        if (cmd[42] and bit.band(cmd[42], 0x07) == 4) then
            json["double_pressure"] = 4
        elseif (cmd[42] and bit.band(cmd[42], 0x07) == 3) then
            json["double_pressure"] = 3
        elseif (cmd[42] and bit.band(cmd[42], 0x07) == 2) then
            json["double_pressure"] = 2
        elseif (cmd[42] and bit.band(cmd[42], 0x07) == 1) then
            json["double_pressure"] = 1
        else
            json["double_pressure"] = 0
        end
        if (cmd[42] and getBit(cmd[42], 6) == '1') then
            json["sterilization"] = 2
        elseif (cmd[42] and getBit(cmd[42], 5) == '1') then
            json["sterilization"] = 1
        else
            json["sterilization"] = 0
        end
        if (cmd[42] and getBit(cmd[42], 7) == '1') then
            json["cold_water_high_tem"] = "on"
        else
            json["cold_water_high_tem"] = "off"
        end
        if (cmd[50] and bit.band(cmd[50], 0xFF) == 3) then
            json["bathtub_curve"] = 3
        elseif (cmd[50] and bit.band(cmd[50], 0x07) == 2) then
            json["bathtub_curve"] = 2
        elseif (cmd[50] and bit.band(cmd[50], 0x07) == 1) then
            json["bathtub_curve"] = 1
        elseif (cmd[50] and bit.band(cmd[50], 0x07) == 8) then
            json["bathtub_curve"] = 8
        else
            json["bathtub_curve"] = 0
        end
        if (cmd[32] and getBit(cmd[32], 7) == '1') then
            json["appoint_master_switch"] = "off"
        else
            json["appoint_master_switch"] = "on"
        end
        if (cmd[39] and getBit(cmd[39], 3) == '1') then
            json["appoint_mode"] = "on"
        else
            json["appoint_mode"] = "off"
        end
        if (getBit(cmd[13], 6) == '1') then
            json["bathtub"] = "on"
            json["bathtub_up"] = "on"
        else
            json["bathtub"] = "off"
            json["bathtub_up"] = "off"
        end
        if (cmd[42] and getBit(cmd[42], 4) == '1') then
            json["bathtub_over"] = "on"
        else
            json["bathtub_over"] = "off"
        end
        if (isMoreInfoLength(cmdLength) and getBit(cmd[31], 3) == '1') then
            json["person_mode_one"] = "on"
        else
            json["person_mode_one"] = "off"
        end
        if (isMoreInfoLength(cmdLength) and getBit(cmd[31], 4) == '1') then
            json["person_mode_two"] = "on"
        else
            json["person_mode_two"] = "off"
        end
        if (isMoreInfoLength(cmdLength) and getBit(cmd[31], 5) == '1') then
            json["person_mode_three"] = "on"
        else
            json["person_mode_three"] = "off"
        end
        if (cmd[35] and getBit(cmd[35], 4) == '1') then
            json["gesture_function"] = "on"
        else
            json["gesture_function"] = "off"
        end
        if (cmd[35] and getBit(cmd[35], 1) == '1') then
            json["gesture_function_type"] = 1
        elseif (cmd[35] and getBit(cmd[35], 2) == '1') then
            json["gesture_function_type"] = 2
        elseif (cmd[35] and getBit(cmd[35], 3) == '1') then
            json["gesture_function_type"] = 3
        elseif (cmd[35] and getBit(cmd[35], 5) == '1') then
            json["gesture_function_type"] = 4
        else
            json["gesture_function_type"] = 0
        end
        if (getBit(cmd[19], 3) == '1') then
            json["safe"] = "on"
        else
            json["safe"] = "off"
        end
        if (cmd[39] and getBit(cmd[39], 5) == '1') then
            json["bath_head_power"] = "on"
        else
            json["bath_head_power"] = "off"
        end
        if (getBit(cmd[13], 3) == '1') then
            json["mode"] = "shower"
        elseif (getBit(cmd[13], 4) == '1') then
            json["mode"] = "kitchen"
        elseif (getBit(cmd[13], 5) == '1') then
            json["mode"] = "thalposis"
        elseif (getBit(cmd[13], 7) == '1') then
            json["mode"] = "intelligence"
        elseif (getBit(cmd[27], 0) == '1') then
            json["mode"] = "eco"
        elseif (getBit(cmd[27], 1) == '1') then
            json["mode"] = "unfreeze"
        elseif (getBit(cmd[27], 2) == '1') then
            json["mode"] = "wash_bowl"
        elseif (getBit(cmd[27], 3) == '1') then
            json["mode"] = "high_temperature"
        elseif (getBit(cmd[27], 4) == '1') then
            json["mode"] = "baby"
        elseif (getBit(cmd[27], 5) == '1') then
            json["mode"] = "adult"
        elseif (getBit(cmd[27], 6) == '1') then
            json["mode"] = "old"
        elseif (getBit(cmd[49], 1) == '1') then
            json["mode"] = "pet_wash"
        elseif (getBit(cmd[27], 7) == '1') then
            json["mode"] = "intel_temperature"
        else
            json["mode"] = "invalid"
        end
        if (cmd[32] and getBit(cmd[32], 1) == '1') then
            json["zero_single"] = 1
        else
            json["zero_single"] = 0
        end
        if (cmd[32] and getBit(cmd[32], 2) == '1') then
            json["zero_timing"] = 1
        else
            json["zero_timing"] = 0
        end
        if (cmd[32] and getBit(cmd[32], 3) == '1') then
            json["zero_dot"] = 1
        else
            json["zero_dot"] = 0
        end
        if (cmd[39] and getBit(cmd[39], 4) == '1') then
            json["master_beep"] = "on"
        else
            json["master_beep"] = "off"
        end
        if (cmd[19] and getBit(cmd[19], 1) == '1') then
            json["pipe_uv"] = "on"
        else
            json["pipe_uv"] = "off"
        end
        if (cmd[32] and getBit(cmd[32], 6) == '1') then
            json["high_temp_lock"] = "on"
        else
            json["high_temp_lock"] = "off"
        end
        if (cmd[49] and getBit(cmd[49], 0) == '1') then
            json["cloud_tem"] = "on"
        else
            json["cloud_tem"] = "off"
        end
        if (cmd[54] and getBit(cmd[54], 0) == '1') then
            json["voice_power"] = "off"
        else
            json["voice_power"] = "on"
        end
        json["volume"] = cmd[55]
        if (cmd[61] and getBit(cmd[61], 0) == '1') then
            json["sos_power"] = "on"
        else
            json["sos_power"] = "off"
        end
        if (cmd[61] and getBit(cmd[61], 1) == '1') then
            json["warning_power"] = "on"
        else
            json["warning_power"] = "off"
        end
        if (cmd[61] and getBit(cmd[61], 2) == '1') then
            json["sos_state"] = "on"
        else
            json["sos_state"] = "off"
        end
        if (cmd[61] and getBit(cmd[61], 3) == '1') then
            json["sos_match_state"] = "on"
        else
            json["sos_match_state"] = "off"
        end
        if (cmd[51] and getBit(cmd[51], 0) == '0') then
            json["cruise_antifreeze"] = "on"
        else
            json["cruise_antifreeze"] = "off"
        end
        if (cmd[51] and getBit(cmd[51], 1) == '0') then
            json["cruise_antifreeze_error"] = "off"
        else
            json["cruise_antifreeze_error"] = "on"
        end
        if (cmd[51] and getBit(cmd[51], 2) == '1') then
            json["zero_temperature"] = "on"
        else
            json["zero_temperature"] = "off"
        end
        if (cmd[49] and getBit(cmd[49], 7) == '1') then
            json["ai_kitchen"] = "on"
        else
            json["ai_kitchen"] = "off"
        end
        if (cmd[49] and getBit(cmd[49], 3) == '1') then
            json["ai_kitchen_aimode"] = "on"
        else
            json["ai_kitchen_aimode"] = "off"
        end
        if (cmd[49] and getBit(cmd[49], 4) == '1') then
            json["ai_kitchen_diymode"] = "on"
        else
            json["ai_kitchen_diymode"] = "off"
        end
        if (getBit(cmd[14], 0) == '1') then
            json['error_code'] = 'E0'
        elseif (getBit(cmd[14], 1) == '1') then
            json['error_code'] = 'E1'
        elseif (getBit(cmd[14], 2) == '1') then
            json['error_code'] = 'E2'
        elseif (getBit(cmd[14], 3) == '1') then
            json['error_code'] = 'E3'
        elseif (getBit(cmd[14], 4) == '1') then
            json['error_code'] = 'E4'
        elseif (getBit(cmd[14], 5) == '1') then
            json['error_code'] = 'E5'
        elseif (getBit(cmd[14], 6) == '1') then
            json['error_code'] = 'E6'
        elseif (getBit(cmd[14], 7) == '1') then
            json['error_code'] = 'E8'
        elseif (getBit(cmd[15], 0) == '1') then
            json['error_code'] = 'EA'
        elseif (getBit(cmd[15], 1) == '1') then
            json['error_code'] = 'EE'
        elseif (cmd[38] and getBit(cmd[38], 0) == '1') then
            json['error_code'] = 'F2'
        elseif (cmd[38] and getBit(cmd[38], 1) == '1') then
            json['error_code'] = 'C0'
        elseif (cmd[38] and getBit(cmd[38], 2) == '1') then
            json['error_code'] = 'C1'
        elseif (cmd[38] and getBit(cmd[38], 3) == '1') then
            json['error_code'] = 'C2'
        elseif (cmd[38] and getBit(cmd[38], 4) == '1') then
            json['error_code'] = 'C3'
        elseif (cmd[38] and getBit(cmd[38], 5) == '1') then
            json['error_code'] = 'C4'
        elseif (cmd[38] and getBit(cmd[38], 6) == '1') then
            json['error_code'] = 'C5'
        elseif (cmd[38] and getBit(cmd[38], 7) == '1') then
            json['error_code'] = 'C6'
        elseif (cmd[39] and getBit(cmd[39], 0) == '1') then
            json['error_code'] = 'C7'
        elseif (cmd[39] and getBit(cmd[39], 1) == '1') then
            json['error_code'] = 'C8'
        elseif (cmd[39] and getBit(cmd[39], 2) == '1') then
            json['error_code'] = 'EH'
        elseif (cmd[39] and getBit(cmd[39], 7) == '1') then
            json['error_code'] = 'EF'
        elseif (cmd[39] and getBit(cmd[49], 2) == '1') then
            json['error_code'] = 'CE'
        else
            json['error_code'] = 'none'
        end
    end
    if (((cmd[10] == 0x04 and cmd[11] == 0x01) or
        (cmd[10] == 0x03 and cmd[11] == 0x01)) and cmd[12] == 0x11) then
        json["device_type"] = "controller"
        if (getBit(cmd[13], 0) == '1') then
            json["lamp_control1_ability"] = "on"
        else
            json["lamp_control1_ability"] = "off"
        end
        if (getBit(cmd[13], 1) == '1') then
            json["lamp_control1_power"] = "on"
        else
            json["lamp_control1_power"] = "off"
        end
        if (getBit(cmd[13], 2) == '1') then
            json["lamp_control2_ability"] = "on"
        else
            json["lamp_control2_ability"] = "off"
        end
        if (getBit(cmd[13], 3) == '1') then
            json["lamp_control2_power"] = "on"
        else
            json["lamp_control2_power"] = "off"
        end
        if (getBit(cmd[13], 4) == '1') then
            json["lamp_control3_ability"] = "on"
        else
            json["lamp_control3_ability"] = "off"
        end
        if (getBit(cmd[13], 5) == '1') then
            json["lamp_control3_power"] = "on"
        else
            json["lamp_control3_power"] = "off"
        end
        if (getBit(cmd[14], 0) == '1') then
            json["power"] = "on"
        else
            json["power"] = "off"
        end
        if (getBit(cmd[14], 1) == '1') then
            json["cold_water"] = "on"
        else
            json["cold_water"] = "off"
        end
        json['temperature'] = cmd[15]
    end
    if ((cmd[10] == 0x03 and cmd[11] == 0x02) or (cmd[10] == 0x02 and
        (cmd[11] == 0x05 or cmd[11] == 0x06 or cmd[11] == 0x07 or cmd[11] ==
            0x05 or cmd[11] == 0x0A))) then
        json['appoint_one'] = {
            cmd[13], cmd[14], cmd[15], cmd[16], cmd[17], cmd[18], cmd[19]
        }
        json['appoint_two'] = {
            cmd[20], cmd[21], cmd[22], cmd[23], cmd[24], cmd[25], cmd[26]
        }
        json['appoint_three'] = {
            cmd[27], cmd[28], cmd[29], cmd[30], cmd[31], cmd[32], cmd[33]
        }
        json['appoint_four'] = {
            cmd[34], cmd[35], cmd[36], cmd[37], cmd[38], cmd[39], cmd[40]
        }
    elseif ((cmd[10] == 0x03 and cmd[11] == 0x03 and cmd[12] == 0x00) or
        (cmd[10] == 0x02 and cmd[11] == 0x0B and cmd[12] == 0x00)) then
        json['appoint_morning'] = {
            cmd[13], cmd[14], cmd[15], cmd[16], cmd[17], cmd[18], cmd[19],
            cmd[20], cmd[21], cmd[22], cmd[23], cmd[24], cmd[25], cmd[26],
            cmd[27], cmd[28], cmd[29], cmd[30], cmd[31], cmd[32], cmd[33],
            cmd[34], cmd[35], cmd[36], cmd[37], cmd[38], cmd[39], cmd[40],
            cmd[41], cmd[42], cmd[43], cmd[44], cmd[45], cmd[46], cmd[47],
            cmd[48], cmd[49], cmd[50], cmd[51], cmd[52], cmd[53], cmd[54],
            cmd[55], cmd[56], cmd[57], cmd[58], cmd[59], cmd[60]
        }
    elseif ((cmd[10] == 0x03 and cmd[11] == 0x03 and cmd[12] == 0x01) or
        (cmd[10] == 0x02 and cmd[11] == 0x0C and cmd[12] == 0x01)) then
        json['appoint_afternoon'] = {
            cmd[13], cmd[14], cmd[15], cmd[16], cmd[17], cmd[18], cmd[19],
            cmd[20], cmd[21], cmd[22], cmd[23], cmd[24], cmd[25], cmd[26],
            cmd[27], cmd[28], cmd[29], cmd[30], cmd[31], cmd[32], cmd[33],
            cmd[34], cmd[35], cmd[36], cmd[37], cmd[38], cmd[39], cmd[40],
            cmd[41], cmd[42], cmd[43], cmd[44], cmd[45], cmd[46], cmd[47],
            cmd[48], cmd[49], cmd[50], cmd[51], cmd[52], cmd[53], cmd[54],
            cmd[55], cmd[56], cmd[57], cmd[58], cmd[59], cmd[60]
        }
    end
    if (cmd[10] == 0x02 and cmd[11] == 0x08) then
        json["key_fa"] = cmd[13]
        json["key_ff"] = cmd[14]
        json["key_ph"] = cmd[15]
        json["key_fh"] = cmd[16]
        json["key_pl"] = cmd[17]
        json["key_fl"] = cmd[18]
        json["key_dh"] = cmd[19]
        json["key_fd"] = cmd[20]
        json["key_ch"] = cmd[21]
        json["key_fc"] = cmd[22]
        json["key_ne"] = cmd[23]
        json["key_ca"] = cmd[24]
        json["key_fp"] = cmd[25]
        json["key_lf"] = cmd[26]
        json["key_hs"] = cmd[27]
        json["key_hb"] = cmd[28]
        json["key_he"] = cmd[29]
        json["key_hl"] = cmd[30]
        json["key_hu"] = cmd[31]
        json["key_ua"] = cmd[32]
        json["key_ub"] = cmd[33]
        json['params'] = {
            cmd[1], cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cmd[8],
            cmd[9], cmd[10], cmd[11], cmd[12], cmd[13], cmd[14], cmd[15],
            cmd[16], cmd[17], cmd[18], cmd[19], cmd[20], cmd[21], cmd[22],
            cmd[23], cmd[24], cmd[25], cmd[26], cmd[27], cmd[28], cmd[29],
            cmd[30], cmd[31], cmd[32], cmd[33], cmd[34], cmd[35], cmd[36],
            cmd[37], cmd[38]
        }
    end
    if ((cmd[10] == 0x03 and cmd[11] == 0x05) or
        (cmd[10] == 0x02 and cmd[11] == 0x0D)) then
        if (cmd[12] and cmd[12] == 0x01) then
            json["bath_head_btn"] = "on"
        else
            json["bath_head_btn"] = "off"
        end
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
