local VALUE_VERSION = 11
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
        deviceSubType == 40 or deviceSubType == 43 or deviceSubType == 48 or
        deviceSubType == 49 or deviceSubType == 80) then return false end
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
        if (json["change_litre_switch"] == "on") then
            cmd[12] = 0x07
            cmd[13] = 0x01
        elseif (json["change_litre_switch"] == "off") then
            cmd[12] = 0x07
            cmd[13] = 0x00
        end
    end
    if (json["capacity"]) then
        if (json["capacity"] == 1) then
            cmd[12] = 0x05
            cmd[13] = 0x01
        elseif (json["capacity"] == 2) then
            cmd[12] = 0x05
            cmd[13] = 0x02
        elseif (json["capacity"] == 3) then
            cmd[12] = 0x05
            cmd[13] = 0x04
        end
    end
    if (json["cold_water"]) then
        if (json["cold_water"] == "on") then
            cmd[12] = 0x03
            cmd[13] = 0x01
        elseif (json["cold_water"] == "off") then
            cmd[12] = 0x03
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_master"]) then
        if (json["cold_water_master"] == "on") then
            cmd[12] = 0x12
            cmd[13] = 0x01
        elseif (json["cold_water_master"] == "off") then
            cmd[12] = 0x12
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_dot"]) then
        if (json["cold_water_dot"] == "on") then
            cmd[12] = 0x04
            cmd[13] = 0x01
        elseif (json["cold_water_dot"] == "off") then
            cmd[12] = 0x04
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_ai"]) then
        if (json["cold_water_ai"] == "on") then
            cmd[12] = 0x0E
            cmd[13] = 0x01
        elseif (json["cold_water_ai"] == "off") then
            cmd[12] = 0x0E
            cmd[13] = 0x00
        end
    end
    if (json["cold_water_pressure"]) then
        if (json["cold_water_pressure"] == "on") then
            cmd[12] = 0x0A
            cmd[13] = 0x01
        elseif (json["cold_water_pressure"] == "off") then
            cmd[12] = 0x0A
            cmd[13] = 0x00
        end
    end
    if (json["bubble"]) then
        if (json["bubble"] == "on") then
            cmd[12] = 0x10
            cmd[13] = 0x01
        elseif (json["bubble"] == "off") then
            cmd[12] = 0x10
            cmd[13] = 0x00
        end
    end
    if (json["bathtub"]) then
        if (json["bathtub"] == "on") then
            cmd[12] = 0x09
            cmd[13] = 0x01
            cmd[14] = json["bathtub_water_level"]
        elseif (json["bathtub"] == "off") then
            cmd[12] = 0x09
            cmd[13] = 0x00
            cmd[14] = json["bathtub_water_level"]
        end
    end
    if (json["person_mode_one"]) then
        if (json["person_mode_one"] == "on") then
            cmd[12] = 0x0B
            cmd[13] = 0x01
            cmd[14] = json["person_tem_one"]
        elseif (json["person_mode_one"] == "off") then
            cmd[12] = 0x0B
            cmd[13] = 0x00
            cmd[14] = json["person_tem_one"]
        end
    end
    if (json["person_mode_two"]) then
        if (json["person_mode_two"] == "on") then
            cmd[12] = 0x0C
            cmd[13] = 0x01
            cmd[14] = json["person_tem_two"]
        elseif (json["person_mode_two"] == "off") then
            cmd[12] = 0x0C
            cmd[13] = 0x00
            cmd[14] = json["person_tem_two"]
        end
    end
    if (json["person_mode_three"]) then
        if (json["person_mode_three"] == "on") then
            cmd[12] = 0x0F
            cmd[13] = 0x01
            cmd[14] = json["person_tem_three"]
        elseif (json["person_mode_three"] == "off") then
            cmd[12] = 0x0F
            cmd[13] = 0x00
            cmd[14] = json["person_tem_three"]
        end
    end
    if (json["gesture_function"]) then
        if (json["gesture_function"] == "on") then
            cmd[12] = 0x0D
            cmd[13] = 0x01
            cmd[14] = json["gesture_function_type"]
        elseif (json["gesture_function"] == "off") then
            cmd[12] = 0x0D
            cmd[13] = 0x00
            cmd[14] = json["gesture_function_type"]
        end
    end
    if (json["safe"]) then
        if (json["safe"] == "on") then
            cmd[12] = 0x06
            cmd[13] = 0x01
        elseif (json["safe"] == "off") then
            cmd[12] = 0x06
            cmd[13] = 0x00
        end
    end
    if (json["appoint_switch"]) then
        if (json["appoint_switch"] == "on") then
            cmd[12] = 0x11
            cmd[13] = 0x00
        elseif (json["appoint_switch"] == "off") then
            cmd[12] = 0x11
            cmd[13] = 0x01
        end
    end
    if (json["mode"]) then
        cmd[12] = 0x02
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
        end
    end
    if (json["temperature"]) then
        cmd[12] = 0x08
        cmd[13] = json["temperature"]
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
            if (control["power"] == "on") then
                cmd[11] = 0x01
            elseif (control["power"] == "off") then
                cmd[11] = 0x02
            end
        elseif (control['appoint_one']) then
            local appointJsonOne = Split(control['appoint_one'], ',')
            cmd[11] = 0x05
            cmd[12] = 0x01
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
        cmd[12] = 0x01
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
    if (infoLength >= 31) then return true end
    return false
end

local function cmdToJson(json, cmd)
    json["version"] = VALUE_VERSION
    local cmdLength = #cmd
    if ((cmd[10] == 0x04 and cmd[11] == 0x01) or
        (cmd[10] == 0x04 and cmd[11] == 0x00) or
        (cmd[10] == 0x03 and cmd[11] == 0x01) or
        (cmd[10] == 0x02 and cmd[11] == 0x01) or
        (cmd[10] == 0x02 and cmd[11] == 0x02) or
        (cmd[10] == 0x02 and cmd[11] == 0x14) or
        (cmd[10] == 0x02 and cmd[11] == 0x04)) then
        json['out_water_tem'] = cmd[16]
        json['temperature'] = cmd[17]
        json['water_volume'] = cmd[18]
        json['bathtub_water_level'] = cmd[21] * 256 + cmd[20] * 1
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
        end
        json["change_litre"] = computeMode(cmd);
        if (getBit(cmd[31], 1) == '1') then
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
        if (getBit(cmd[31], 7) == '1') then
            json["cold_water_master"] = "on"
        else
            json["cold_water_master"] = "off"
        end
        if (getBit(cmd[31], 0) == '1') then
            json["cold_water_dot"] = "on"
        else
            json["cold_water_dot"] = "off"
        end
        if (getBit(cmd[32], 5) == '1' and isMoreInfoLength(cmdLength)) then
            json["cold_water_ai"] = "on"
        else
            json["cold_water_ai"] = "off"
        end
        if (getBit(cmd[31], 2) == '1') then
            json["cold_water_pressure"] = "on"
        else
            json["cold_water_pressure"] = "off"
        end
        if (getBit(cmd[32], 6) == '1' and isMoreInfoLength(cmdLength)) then
            json["bubble"] = "on"
        else
            json["bubble"] = "off"
        end
        if (getBit(cmd[32], 7) == '1' and isMoreInfoLength(cmdLength)) then
            json["appoint_switch"] = "off"
        else
            json["appoint_switch"] = "on"
        end
        if (getBit(cmd[13], 6) == '1') then
            json["bathtub"] = "on"
        else
            json["bathtub"] = "off"
        end
        if (getBit(cmd[31], 3) == '1') then
            json["person_mode_one"] = "on"
        else
            json["person_mode_one"] = "off"
        end
        if (getBit(cmd[31], 4) == '1') then
            json["person_mode_two"] = "on"
        else
            json["person_mode_two"] = "off"
        end
        if (getBit(cmd[31], 5) == '1') then
            json["person_mode_three"] = "on"
        else
            json["person_mode_three"] = "off"
        end
        if (getBit(cmd[35], 4) == '1' and isMoreInfoLength(cmdLength)) then
            json["gesture_function"] = "on"
        else
            json["gesture_function"] = "off"
        end
        if (getBit(cmd[35], 1) == '1' and isMoreInfoLength(cmdLength)) then
            json["gesture_function_type"] = 1
        elseif (getBit(cmd[35], 2) == '1' and isMoreInfoLength(cmdLength)) then
            json["gesture_function_type"] = 2
        elseif (getBit(cmd[35], 3) == '1' and isMoreInfoLength(cmdLength)) then
            json["gesture_function_type"] = 3
        elseif (getBit(cmd[35], 5) == '1' and isMoreInfoLength(cmdLength)) then
            json["gesture_function_type"] = 4
        else
            json["gesture_function_type"] = 0
        end
        if (getBit(cmd[19], 3) == '1' and isMoreInfoLength(cmdLength)) then
            json["safe"] = "on"
        else
            json["safe"] = "off"
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
        elseif (getBit(cmd[27], 7) == '1') then
            json["mode"] = "intel_temperature"
        else
            json["mode"] = "invalid"
        end
        if (getBit(cmd[32], 1) == '1' and isMoreInfoLength(cmdLength)) then
            json["zero_single"] = 1
        else
            json["zero_single"] = 0
        end
        if (getBit(cmd[32], 2) == '1' and isMoreInfoLength(cmdLength)) then
            json["zero_timing"] = 1
        else
            json["zero_timing"] = 0
        end
        if (getBit(cmd[32], 3) == '1' and isMoreInfoLength(cmdLength)) then
            json["zero_dot"] = 1
        else
            json["zero_dot"] = 0
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
        elseif (getBit(cmd[38], 0) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'F2'
        elseif (getBit(cmd[38], 1) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C0'
        elseif (getBit(cmd[38], 2) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C1'
        elseif (getBit(cmd[38], 3) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C2'
        elseif (getBit(cmd[38], 4) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C3'
        elseif (getBit(cmd[38], 5) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C4'
        elseif (getBit(cmd[38], 6) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C5'
        elseif (getBit(cmd[38], 7) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C6'
        elseif (getBit(cmd[39], 0) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C7'
        elseif (getBit(cmd[39], 1) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'C8'
        elseif (getBit(cmd[39], 2) == '1' and isMoreInfoLength(cmdLength)) then
            json['error_code'] = 'EH'
        else
            json['error_code'] = 'none'
        end
    end
    if (isMoreInfoLength(cmdLength)) then
        print(cmd[10] == 0x03)
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
