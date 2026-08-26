local bit = require "bit"
local JSON = require "cjson"
local BYTE_DEVICE_TYPE = 0xB0
local BYTE_PROTOCOL_VERSION = 0x03
local BYTE_PROTOCOL_YEAR_VERSION = 0x01
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local VALUE_VERSION = 6
local function makeSum(tmpbuf, msgLenByteNumber)
    local resVal = 0
    for si = 1, (msgLenByteNumber - 1) do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal)
    resVal = bit.band(resVal, 0x000000FF)
    resVal = resVal + 1
    resVal = math.fmod(resVal, 256)
    return resVal
end
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if bodyLength == 0 then return nil end
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[7] = BYTE_PROTOCOL_VERSION
    msgBytes[8] = BYTE_PROTOCOL_YEAR_VERSION
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    msgBytes[msgLength - 1] = makeSum(msgBytes, msgLength - 1)
    return msgBytes
end
local function decodeJsonToTable(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end
local function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then JSON = require "cjson" end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
end
local function string2table(hexstr)
    local tb = {}
    local i = 1
    local j = 0
    for i = 1, #hexstr - 1, 2 do
        local doublebytestr = string.sub(hexstr, i, i + 1)
        tb[j] = doublebytestr
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
local function workMode16(mode)
    local modeTable = {
        ["above_tube"] = 0x40,
        ["microwave"] = 0x01,
        ["unfreeze"] = 0xA0,
        ["unfreeze_t"] = 0xA1,
        ["auto_menu"] = 0xE0,
        ["humidit_auto_menu"] = 0xE2
    }
    if (modeTable[mode] ~= nil) then
        return modeTable[mode]
    else
        return 0xFF
    end
end
local function workStatus16(status)
    local statusTable = {
        ["save_power"] = 0x01,
        ["standby"] = 0x02,
        ["work"] = 0x03,
        ["pause"] = 0x06,
        ["open"] = 0x06,
        ["start"] = 0x11
    }
    if (statusTable[status] ~= nil) then
        return statusTable[status]
    else
        return 0xFF
    end
end
local function firePower16(firePower)
    local firePowerTable = {
        ["high_power"] = 0x0A,
        ["medium_high_power"] = 0x08,
        ["medium_power"] = 0x05,
        ["medium_low_power"] = 0x03,
        ["low_power"] = 0x01,
        ["0"] = 0x00,
        ["1"] = 0x01,
        ["2"] = 0x02,
        ["3"] = 0x03,
        ["4"] = 0x04,
        ["5"] = 0x05,
        ["6"] = 0x06,
        ["7"] = 0x07,
        ["8"] = 0x08,
        ["9"] = 0x09,
        ["10"] = 0x0A,
        ["fire_power_0"] = 0x00,
        ["fire_power_2"] = 0x02,
        ["fire_power_4"] = 0x04,
        ["fire_power_6"] = 0x06,
        ["fire_power_7"] = 0x07,
        ["fire_power_9"] = 0x09
    }
    if (firePowerTable[firePower] ~= nil) then
        return firePowerTable[firePower]
    else
        return 0xFF
    end
end
local function getFirePowerType(meg)
    local power_type
    if (meg == "0A" or meg == "0a") then
        power_type = "high_power"
    elseif (meg == "09") then
        power_type = "fire_power_9"
    elseif (meg == "08") then
        power_type = "medium_high_power"
    elseif (meg == "07") then
        power_type = "fire_power_7"
    elseif (meg == "06") then
        power_type = "fire_power_6"
    elseif (meg == "05") then
        power_type = "medium_power"
    elseif (meg == "04") then
        power_type = "fire_power_4"
    elseif (meg == "03") then
        power_type = "medium_low_power"
    elseif (meg == "02") then
        power_type = "fire_power_2"
    elseif (meg == "01") then
        power_type = "low_power"
    elseif (meg == "00") then
        power_type = "fire_power_0"
    end
    return power_type
end
local function workModeControl(control, bodyBytes)
    bodyBytes[0] = 0x22
    bodyBytes[1] = 0x01
    local cloudmenuid = control["cloudmenuid"]
    if cloudmenuid ~= nil then
        local cloudmenuidn = tonumber(cloudmenuid)
        local cloundMenuIdNHH = math.modf(cloudmenuidn / (16 ^ 4))
        local cloundMenuIdNHHLeft = math.fmod(cloudmenuidn, (16 ^ 4))
        local cloundMenuIdNH = math.modf(cloundMenuIdNHHLeft / (16 ^ 2))
        local cloundMenuIdNL = math.fmod(cloundMenuIdNHHLeft, (16 ^ 2))
        bodyBytes[2] = cloundMenuIdNHH
        bodyBytes[3] = cloundMenuIdNH
        bodyBytes[4] = cloundMenuIdNL
        if control["totalstep"] ~= nil then
            bodyBytes[5] = control["totalstep"]
        else
            bodyBytes[5] = 0x11
        end
    else
        bodyBytes[2] = 0x00
        bodyBytes[3] = 0x00
        bodyBytes[4] = 0x00
        bodyBytes[5] = 0x11
    end
    if (control["pre_heat"] == "on") then
        bodyBytes[6] = bit.bor(0x08, 1)
    else
        bodyBytes[6] = 0x08
    end
    if (control["work_hour"] ~= nil) then
        bodyBytes[7] = control["work_hour"]
    else
        bodyBytes[7] = 0x00
    end
    if (control["work_minute"] ~= nil) then
        bodyBytes[8] = control["work_minute"]
    else
        bodyBytes[8] = 0x00
    end
    if (control["work_second"] ~= nil) then
        bodyBytes[9] = control["work_second"]
    else
        bodyBytes[9] = 0x00
    end
    bodyBytes[10] = workMode16(control["work_mode"])
    local temperature = control["temperature"]
    if (temperature ~= nil) then
        bodyBytes[11] = 0x00
        bodyBytes[12] = temperature
        bodyBytes[13] = 0x00
        bodyBytes[14] = temperature
    else
        bodyBytes[11] = 0x00
        bodyBytes[12] = 0x00
        bodyBytes[13] = 0x00
        bodyBytes[14] = 0x00
    end
    bodyBytes[15] = firePower16(control["fire_power"])
    if (control["weight"] ~= nil) then
        bodyBytes[16] = control["weight"]
    elseif (control["people_number"] ~= nil) then
        bodyBytes[16] = control["people_number"]
    else
        bodyBytes[16] = 0xff
    end
    if (control["workend"] == nil) then
        bodyBytes[17] = 0xff
    else
        bodyBytes[17] = control["workend"]
    end
    if (control["probo_value"] == nil) then
        bodyBytes[18] = 0x00
    else
        bodyBytes[18] = control["probo_value"]
    end
end
local function notWorkModeControl(control, bodyBytes)
    bodyBytes[0] = 0x22
    bodyBytes[1] = 0x02
    bodyBytes[2] = workStatus16(control["work_status"])
    if (control["lock"] == "off") then
        bodyBytes[3] = 0x00
    elseif (control["lock"] == "on") then
        bodyBytes[3] = 0x01
    else
        bodyBytes[3] = 0xff
    end
    if (control["furnace_light"] == "off") then
        bodyBytes[4] = 0x00
    elseif (control["furnace_light"] == "on") then
        bodyBytes[4] = 0x01
    else
        bodyBytes[4] = 0xff
    end
    if (control["camera"] == "off") then
        bodyBytes[5] = 0x00
    elseif (control["camera"] == "on") then
        bodyBytes[5] = 0x01
    else
        bodyBytes[5] = 0xff
    end
    if (control["door"] == "close") then
        bodyBytes[6] = 0x00
    elseif (control["door"] == "open") then
        bodyBytes[6] = 0x01
    else
        bodyBytes[6] = 0xff
    end
end
local function incControl(control, bodyBytes)
    bodyBytes[0] = 0x22
    bodyBytes[1] = 0x03
    bodyBytes[2] = 0xff
    bodyBytes[3] = 0xff
    bodyBytes[4] = 0xff
    bodyBytes[5] = 0xff
    bodyBytes[6] = 0xff
    if (control["hour_inc"] ~= nil) then
        bodyBytes[7] = tonumber(control["hour_inc"])
    else
        bodyBytes[7] = 0xff
    end
    if (control["minute_inc"] ~= nil) then
        bodyBytes[8] = tonumber(control["minute_inc"])
    else
        bodyBytes[8] = 0xff
    end
    if (control["second_inc"] ~= nil) then
        bodyBytes[9] = tonumber(control["second_inc"])
    else
        bodyBytes[9] = 0xff
    end
    bodyBytes[10] = 0xff
    bodyBytes[11] = 0xff
    if (control["temp_inc"] ~= nil) then
        bodyBytes[12] = tonumber(control["temp_inc"])
    else
        bodyBytes[12] = 0xff
    end
    bodyBytes[13] = 0xff
    bodyBytes[14] = 0xff
    bodyBytes[15] = 0xff
    bodyBytes[16] = 0xff
    bodyBytes[17] = 0xff
    bodyBytes[18] = 0xff
end
local function redControl(control, bodyBytes)
    bodyBytes[0] = 0x22
    bodyBytes[1] = 0x05
    bodyBytes[2] = 0xff
    bodyBytes[3] = 0xff
    bodyBytes[4] = 0xff
    bodyBytes[5] = 0xff
    bodyBytes[6] = 0xff
    if (control["hour_red"] ~= nil) then
        bodyBytes[7] = tonumber(control["hour_red"])
    else
        bodyBytes[7] = 0xff
    end
    if (control["minute_red"] ~= nil) then
        bodyBytes[8] = tonumber(control["minute_red"])
    else
        bodyBytes[8] = 0xff
    end
    if (control["second_red"] ~= nil) then
        bodyBytes[9] = tonumber(control["second_red"])
    else
        bodyBytes[9] = 0xff
    end
    bodyBytes[10] = 0xff
    bodyBytes[11] = 0xff
    if (control["temp_red"] ~= nil) then
        bodyBytes[12] = tonumber(control["temp_red"])
    else
        bodyBytes[12] = 0xff
    end
    bodyBytes[13] = 0xff
    bodyBytes[14] = 0xff
    bodyBytes[15] = 0xff
    bodyBytes[16] = 0xff
    bodyBytes[17] = 0xff
    bodyBytes[18] = 0xff
end
local function setControl(control, bodyBytes)
    bodyBytes[0] = 0x22
    bodyBytes[1] = 0x04
    bodyBytes[2] = 0xff
    bodyBytes[3] = 0xff
    bodyBytes[4] = 0xff
    bodyBytes[5] = 0xff
    bodyBytes[6] = 0xff
    if (control["hour_set"] ~= nil or control["minute_set"] ~= nil or
        control["second_set"] ~= nil) then
        if (control["hour_set"] ~= nil) then
            bodyBytes[7] = tonumber(control["hour_set"])
        else
            bodyBytes[7] = 0x00
        end
        if (control["minute_set"] ~= nil) then
            bodyBytes[8] = tonumber(control["minute_set"])
        else
            bodyBytes[8] = 0x00
        end
        if (control["second_set"] ~= nil) then
            bodyBytes[9] = tonumber(control["second_set"])
        else
            bodyBytes[9] = 0x00
        end
    else
        bodyBytes[7] = 0xff
        bodyBytes[8] = 0xff
        bodyBytes[9] = 0xff
    end
    bodyBytes[10] = 0xff
    if (control["temp_set"] ~= nil) then
        bodyBytes[11] = 0x00
        bodyBytes[12] = tonumber(control["temp_set"])
    else
        bodyBytes[11] = 0xff
        bodyBytes[12] = 0xff
    end
    bodyBytes[13] = 0xff
    bodyBytes[14] = 0xff
    if (control["fire_power_set"] ~= nil) then
        bodyBytes[15] = firePower16(control["fire_power_set"])
    else
        bodyBytes[15] = 0xff
    end
    if (control["steam_set"] ~= nil) then
        bodyBytes[16] = tonumber(control["steam_set"])
    else
        bodyBytes[16] = 0xff
    end
    bodyBytes[17] = 0xff
    bodyBytes[18] = 0xff
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        local bodyBytes = {}
        if (control["work_mode"] ~= nil) then
            workModeControl(control, bodyBytes)
        elseif (control["work_status"] ~= nil or control["lock"] ~= nil or
            control["furnace_light"] ~= nil) then
            notWorkModeControl(control, bodyBytes)
        elseif (control["hour_inc"] ~= nil or control["minute_inc"] ~= nil or
            control["second_inc"] ~= nil or control["temp_inc"] ~= nil) then
            incControl(control, bodyBytes)
        elseif (control["hour_red"] ~= nil or control["minute_red"] ~= nil or
            control["second_red"] ~= nil or control["temp_red"] ~= nil) then
            redControl(control, bodyBytes)
        elseif (control["hour_set"] ~= nil or control["minute_set"] ~= nil or
            control["second_set"] ~= nil or control["temp_set"] ~= nil or
            control["steam_set"] ~= nil or control["fire_power_set"] ~= nil) then
            setControl(control, bodyBytes)
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        local bodyLength = 1
        local bodyBytes = {}
        if (query["query_type"] == "31") then
            bodyBytes[0] = 0x31
        elseif (query["query_type"] == "32") then
            bodyBytes[0] = 0x32
        elseif (query["query_type"] == "33") then
            bodyBytes[0] = 0x33
        elseif (query["query_type"] == "34") then
            bodyBytes[0] = 0x34
        elseif (query["query_type"] == "35") then
            bodyBytes[0] = 0x35
        else
            bodyBytes[0] = 0x31
        end
        for i = 1, bodyLength - 1 do bodyBytes[i] = 0x00 end
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
    end
    local infoM = {}
    local length = #msgBytes + 1
    for i = 1, length do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
local function getModeType(meg)
    local modetype
    if (meg == "01") then
        modetype = "microwave"
    elseif (meg == "02") then
        modetype = "brittle"
    elseif (meg == "20") then
        modetype = "pure_steam"
    elseif (meg == "21") then
        modetype = "hot_steam"
    elseif (meg == "40") then
        modetype = "above_tube"
    elseif (meg == "41") then
        modetype = "hot_wind_bake"
    elseif (meg == "42") then
        modetype = "underside_tube_hot_wind_bake"
    elseif (meg == "44") then
        modetype = "cube_baking"
    elseif (meg == "46") then
        modetype = "core_baking"
    elseif (meg == "47") then
        modetype = "total_baking"
    elseif (meg == "49") then
        modetype = "underside_tube"
    elseif (meg == "4C" or meg == "4c") then
        modetype = "double_tube"
    elseif (meg == "4E" or meg == "4e") then
        modetype = "revolve_bake"
    elseif (meg == "51") then
        modetype = "double_upside_tube_fan"
    elseif (meg == "52") then
        modetype = "double_tube_fan"
    elseif (meg == "70") then
        modetype = "fast_baking"
    elseif (meg == "90") then
        modetype = "fast_steam"
    elseif (meg == "A0" or meg == "a0") then
        modetype = "unfreeze"
    elseif (meg == "A1" or meg == "a1") then
        modetype = "unfreeze_t"
    elseif (meg == "B0" or meg == "b0") then
        modetype = "zymosis"
    elseif (meg == "C0" or meg == "c0") then
        modetype = "smart_clean"
    elseif (meg == "C1" or meg == "c1") then
        modetype = "scale_clean"
    elseif (meg == "C2" or meg == "c2") then
        modetype = "metal_sterilize"
    elseif (meg == "C3" or meg == "c3") then
        modetype = "remove_odor"
    elseif (meg == "C4" or meg == "c4") then
        modetype = "dry"
    elseif (meg == "C6" or meg == "c6") then
        modetype = "clean"
    elseif (meg == "D0" or meg == "d0") then
        modetype = "warm"
    elseif (meg == "E0" or meg == "e0") then
        modetype = "auto_menu"
    elseif (meg == "E2" or meg == "e2") then
        modetype = "humidit_auto_menu"
    end
    return modetype
end
local function getByteBit(bytes, bitIndex)
    local bytes_high = tonumber(string.sub(bytes, 1, 1), 16)
    local bytes_low = tonumber(string.sub(bytes, 2, 2), 16)
    if bitIndex > 3 and bitIndex < 8 then
        if bitIndex == 7 then
            if bit.band(bytes_high, 8) == 8 then return '1' end
        elseif bitIndex == 6 then
            if bit.band(bytes_high, 4) == 4 then return '1' end
        elseif bitIndex == 5 then
            if bit.band(bytes_high, 2) == 2 then return '1' end
        elseif bitIndex == 4 then
            if bit.band(bytes_high, 1) == 1 then return '1' end
        end
        return '0'
    elseif bitIndex >= 0 and bitIndex <= 3 then
        if bitIndex == 3 then
            if bit.band(bytes_low, 8) == 8 then return '1' end
        elseif bitIndex == 2 then
            if bit.band(bytes_low, 4) == 4 then return '1' end
        elseif bitIndex == 1 then
            if bit.band(bytes_low, 2) == 2 then return '1' end
        elseif bitIndex == 0 then
            if bit.band(bytes_low, 1) == 1 then return '1' end
        end
        return '0'
    end
    return '2'
end
local function cloudToDevice(megBodys)
    local jsonTable = {}
    jsonTable["version"] = VALUE_VERSION
    if (megBodys[9] == "02") then
        if (megBodys[10] == "22") then
            if (megBodys[11] == "01") then
                jsonTable["cloudmenuid"] =
                    tonumber(megBodys[12], 16) * (16 ^ 4) +
                        tonumber(megBodys[13], 16) * (16 ^ 2) +
                        tonumber(megBodys[14], 16)
                jsonTable["totalstep"] = math.modf(
                                             tonumber(megBodys[15], 16) / 16)
                jsonTable["stepnum"] = math.fmod(tonumber(megBodys[15], 16), 16)
                if tonumber(megBodys[16], 16) == "0" then
                    jsonTable["pre_heat"] = "off"
                elseif tonumber(megBodys[16], 16) == "1" then
                    jsonTable["pre_heat"] = "on"
                end
                jsonTable["work_hour"] = tonumber(megBodys[17], 16)
                jsonTable["work_minute"] = tonumber(megBodys[18], 16)
                jsonTable["work_second"] = tonumber(megBodys[19], 16)
                jsonTable["work_mode"] = getModeType(megBodys[20])
                jsonTable["temperature"] = tonumber(megBodys[22], 16)
                if (megBodys[25] ~= "FF" and megBodys[25] ~= "ff" and
                    megBodys[25] ~= "00") then
                    jsonTable["fire_power"] = getFirePowerType(megBodys[25])
                end
                if (megBodys[26] ~= "FF" and megBodys[26] ~= "ff") then
                    jsonTable["weight"] = tonumber(megBodys[26], 16)
                end
                if (megBodys[27] ~= "FF" and megBodys[27] ~= "ff") then
                    jsonTable["workend"] = tonumber(megBodys[27], 16)
                end
                if (megBodys[28] ~= "FF" and megBodys[28] ~= "ff") then
                    jsonTable["probo_value"] = tonumber(megBodys[28], 16)
                end
            elseif (megBodys[11] == "02") then
                if (megBodys[12] == "01") then
                    jsonTable["work_status"] = "save_power"
                elseif (megBodys[12] == "02") then
                    jsonTable["work_status"] = "standby"
                elseif (megBodys[12] == "03") then
                    jsonTable["work_status"] = "work"
                elseif (megBodys[12] == "06") then
                    jsonTable["work_status"] = "pause"
                end
                if (megBodys[13] == "00") then
                    jsonTable["lock"] = "off"
                elseif (megBodys[13] == "01") then
                    jsonTable["lock"] = "on"
                end
                if (megBodys[14] == "00") then
                    jsonTable["furnace_light"] = "off"
                elseif (megBodys[14] == "01") then
                    jsonTable["furnace_light"] = "on"
                end
            elseif (megBodys[11] == "03") then
                if (megBodys[18] ~= "FF" or megBodys[18] ~= "ff") then
                    jsonTable["minutes_inc"] = tonumber(megBodys[18], 16)
                end
                if (megBodys[19] ~= "ff" or megBodys[19] ~= "FF") then
                    jsonTable["second_inc"] = tonumber(megBodys[19], 16)
                end
            elseif (megBodys[11] == "FE" or megBodys[11] == "fe") then
                jsonTable["fail_resp_reason"] = tonumber(megBodys[13], 16)
            end
        elseif (megBodys[10] == "23") then
            jsonTable["year"] = tonumber(megBodys[11], 16) + 2000
            jsonTable["month"] = tonumber(megBodys[12], 16)
            jsonTable["day"] = tonumber(megBodys[13], 16)
            jsonTable["work_hour"] = tonumber(megBodys[14], 16)
            jsonTable["work_minute"] = tonumber(megBodys[15], 16)
            jsonTable["work_second"] = tonumber(megBodys[16], 16)
            jsonTable["week"] = tonumber(megBodys[17], 16)
        elseif (megBodys[10] == "24") then
            jsonTable["reservation"] = tonumber(megBodys[11], 16)
            jsonTable["pre_hour"] = tonumber(megBodys[12], 16)
            jsonTable["pre_minutes"] = tonumber(megBodys[13], 16)
            jsonTable["pre_second"] = tonumber(megBodys[14], 16)
            jsonTable["cloudmenuid"] = tonumber(megBodys[15], 16) * (16 ^ 4) +
                                           tonumber(megBodys[16], 16) * (16 ^ 2) +
                                           tonumber(megBodys[17], 16)
            jsonTable["totalstep"] = math.modf(tonumber(megBodys[18], 16) / 16)
            jsonTable["stepnum"] = math.fmod(tonumber(megBodys[18], 16), 16)
            if (megBodys[19] ~= "FF" and megBodys[19] ~= "ff") then
                if tonumber(megBodys[19], 16) == "0" then
                    jsonTable["pre_heat"] = "off"
                elseif tonumber(megBodys[19], 16) == "1" then
                    jsonTable["pre_heat"] = "on"
                end
            end
            if (megBodys[20] ~= "FF" and megBodys[20] ~= "ff") then
                jsonTable["work_hour"] = tonumber(megBodys[20], 16)
            end
            if (megBodys[21] ~= "FF" and megBodys[21] ~= "ff") then
                jsonTable["work_minute"] = tonumber(megBodys[21], 16)
            end
            if (megBodys[22] ~= "FF" and megBodys[22] ~= "ff") then
                jsonTable["work_second"] = tonumber(megBodys[22], 16)
            end
            if (megBodys[23] ~= "FF" and megBodys[23] ~= "ff") then
                jsonTable["work_mode"] = getModeType(megBodys[23])
            end
            if (megBodys[25] ~= "FF" and megBodys[25] ~= "ff") then
                jsonTable["temperature"] = getModeType(megBodys[25])
            end
            if (megBodys[27] ~= "FF" and megBodys[27] ~= "ff") then
                jsonTable["temperature"] = getModeType(megBodys[27])
            end
            if (megBodys[28] ~= "FF" and megBodys[28] ~= "ff" and megBodys[28] ~=
                "00") then
                jsonTable["fire_power"] = getFirePowerType(megBodys[28])
            end
            if (megBodys[29] ~= "FF" and megBodys[29] ~= "ff") then
                jsonTable["weight"] = tonumber(megBodys[29], 16)
            end
            if (megBodys[30] ~= "FF" and megBodys[30] ~= "ff") then
                jsonTable["workend"] = tonumber(megBodys[30], 16)
            end
            if (megBodys[31] ~= "FF" and megBodys[31] ~= "ff") then
                jsonTable["probo_value"] = tonumber(megBodys[31], 16)
            end
        elseif (megBodys[10] == 0x26) then
            jsonTable["page_choose"] = tonumber(megBodys[11], 16)
        elseif (megBodys[10] == 0x29) then
            jsonTable["receipe_set_value"] = tonumber(megBodys[11], 16)
        end
    elseif (megBodys[9] == "03" or megBodys[9] == "04") then
        if (megBodys[11] == "01") then
            jsonTable["work_status"] = "save_power"
        elseif (megBodys[11] == "02") then
            jsonTable["work_status"] = "standby"
        elseif (megBodys[11] == "03") then
            jsonTable["work_status"] = "work"
        elseif (megBodys[11] == "04") then
            jsonTable["work_status"] = "work_finish"
        elseif (megBodys[11] == "05") then
            jsonTable["work_status"] = "order"
        elseif (megBodys[11] == "06") then
            jsonTable["work_status"] = "pause"
        elseif (megBodys[11] == "07") then
            jsonTable["work_status"] = "pause_c"
        elseif (megBodys[11] == "08") then
            jsonTable["work_status"] = "three"
        end
        jsonTable["cloudmenuid"] = tonumber(megBodys[12], 16) * (16 ^ 4) +
                                       tonumber(megBodys[13], 16) * (16 ^ 2) +
                                       tonumber(megBodys[14], 16)
        jsonTable["totalstep"] = math.modf(tonumber(megBodys[15], 16) / 16)
        jsonTable["stepnum"] = math.fmod(tonumber(megBodys[15], 16), 16)
        if (megBodys[16] ~= "FF" and megBodys[16] ~= "ff") then
            jsonTable["work_hour"] = tonumber(megBodys[16], 16)
        end
        if (megBodys[17] ~= "FF" and megBodys[17] ~= "ff") then
            jsonTable["work_minute"] = tonumber(megBodys[17], 16)
        end
        if (megBodys[18] ~= "FF" and megBodys[18] ~= "ff") then
            jsonTable["work_second"] = tonumber(megBodys[18], 16)
        end
        if (megBodys[19] ~= "FF" and megBodys[19] ~= "ff") then
            jsonTable["work_mode"] = getModeType(megBodys[19])
        end
        if (megBodys[21] ~= "FF" and megBodys[21] ~= "ff") then
            jsonTable["cur_temperature_above"] = tonumber(megBodys[21], 16)
        end
        if (megBodys[23] ~= "FF" and megBodys[23] ~= "ff") then
            jsonTable["cur_temperature_underside"] = tonumber(megBodys[23], 16)
        end
        if (megBodys[24] ~= "FF" and megBodys[24] ~= "ff" and megBodys[24] ~=
            "00") then
            jsonTable["fire_power"] = getFirePowerType(megBodys[24])
        end
        if (megBodys[25] ~= "FF" and megBodys[25] ~= "ff") then
            jsonTable["weight"] = tonumber(megBodys[25], 16)
            jsonTable["people_number"] = tonumber(megBodys[25], 16)
        end
        local b26 = megBodys[26]
        local b27 = megBodys[27]
        local lock = getByteBit(b26, 0)
        if (lock == "1") then
            jsonTable["lock"] = "on"
        elseif (lock == "0") then
            jsonTable["lock"] = "off"
        end
        local door = getByteBit(b26, 1)
        if (door == "1") then
            jsonTable["door_open"] = "on"
        elseif (door == "0") then
            jsonTable["door_open"] = "off"
        end
        local water_box = getByteBit(b26, 2)
        local water_state = getByteBit(b26, 3)
        local changewater = getByteBit(b26, 4)
        local preheat = getByteBit(b26, 5)
        local preheatvalue = getByteBit(b26, 6)
        local error_code = getByteBit(b26, 7)
        local fanmian = getByteBit(b27, 0)
        local ganying = getByteBit(b27, 1)
        local ludeng = getByteBit(b27, 2)
        local tanzhen = getByteBit(b27, 6)
        if (water_box == "1") then
            jsonTable["tips_code"] = 6
        elseif (water_state == "1") then
            jsonTable["tips_code"] = 2
        elseif (changewater == "1") then
            jsonTable["tips_code"] = 7
        elseif (preheatvalue == "1") then
            jsonTable["tips_code"] = 9
        elseif (preheat == "1") then
            jsonTable["tips_code"] = 8
        elseif (fanmian == "1") then
            jsonTable["tips_code"] = 4
        else
            jsonTable["tips_code"] = 0
        end
        if (error_code == "1") then
            jsonTable["error_code"] = 1
        else
            jsonTable["error_code"] = 0
        end
        if (ganying == "1") then
            jsonTable["reaction"] = 1
        else
            jsonTable["reaction"] = 0
        end
        if (ludeng == "1") then
            jsonTable["furnace_light"] = "on"
        elseif (ludeng == "0") then
            jsonTable["furnace_light"] = "off"
        end
        if (tanzhen == "1") then
            jsonTable["probo_on"] = 1
        elseif (tanzhen == "0") then
            jsonTable["probo_on"] = 0
        end
        if (megBodys[29] ~= "FF" and megBodys[29] ~= "ff") then
            jsonTable["temperature"] = tonumber(megBodys[29], 16)
        end
        if (megBodys[38] ~= nil and megBodys[39] ~= nil and megBodys[40] ~= nil) then
            if (megBodys[38] ~= "FF" and megBodys[38] ~= "ff") then
                jsonTable["hour_set"] = tonumber(megBodys[38], 16)
            end
            if (megBodys[39] ~= "FF" and megBodys[39] ~= "ff") then
                jsonTable["minute_set"] = tonumber(megBodys[39], 16)
            end
            if (megBodys[40] ~= "FF" and megBodys[40] ~= "ff") then
                jsonTable["second_set"] = tonumber(megBodys[40], 16)
            end
        else
            jsonTable["hour_set"] = 0
            jsonTable["minute_set"] = 0
            jsonTable["second_set"] = 0
        end
    end
    return jsonTable
end
function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decodeJsonToTable(jsonStr)
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local status = json["status"]
    local retTable = {}
    retTable["status"] = {}
    local bodyBytes = string2table(binData)
    retTable["status"] = cloudToDevice(bodyBytes)
    local ret = encodeTableToJson(retTable)
    return ret
end
