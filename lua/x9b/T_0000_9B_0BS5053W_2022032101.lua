local JSON = require "cjson"
local VALUE_VERSION = 7
local BYTE_DEVICE_TYPE = 0x9B
local BYTE_PROTOCOL_YEAR_VERSION = 0x12
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_PROTOCOL_VERSION = 0x00
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03

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

local function decodeJsonToTable(jsonStr) return JSON.decode(jsonStr) end

local function encodeTableToJson(luaTable) return JSON.encode(luaTable) end

local function hexToTable(hex)
    local tb = {}
    local i = 1
    local j = 0
    for i = 1, #hex - 1, 2 do
        local doublebytestr = string.sub(hex, i, i + 1)
        tb[j] = doublebytestr
        j = j + 1
    end
    return tb
end

local function tableToString(tb)
    local ret = ""
    local i
    for i = 1, #tb do ret = ret .. string.char(tb[i]) end
    return ret
end

local function stringToHex(str)
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
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

local function workMode16(mode)
    local modeTable = {
        ["microwave"] = "0x010x00",
        ["microwave_double_tube"] = "0x030x00",
        ["microwave_hot_wind_tube_fan"] = "0x040x00",
        ["microwave_underside_tube_hot_wind_tube_fan"] = "0x050x00",
        ["microwave_double_tube_hot_wind_tube_fan"] = "0x060x00",
        ["microwave_steam"] = "0x070x00",
        ["unfreeze"] = "0x090x00",
        ["unfreeze_t"] = "0x0A0x00",
        ["pure_steam"] = "0x290x00",
        ["steam_above_tube"] = "0x2B0x00",
        ["steam_underside_tube"] = "0x2C0x00",
        ["steam_double_tube"] = "0x2D0x00",
        ["steam_hot_wind_tube_fan"] = "0x2E0x00",
        ["above_tube"] = "0x510x00",
        ["underside_tube"] = "0x520x00",
        ["double_tube"] = "0x530x00",
        ["hot_wind_tube_fan"] = "0x540x00",
        ["pure_preheat"] = "0x550x00",
        ["above_tube_hot_wind_tube_fan"] = "0x560x00",
        ["underside_tube_hot_wind_tube_fan"] = "0x570x00",
        ["zymosis"] = "0x580x00",
        ["double_tube_hot_wind_tube_fan"] = "0x590x00",
        ["above_tube_revolve"] = "0x5A0x00",
        ["underside_tube_revolve"] = "0x5B0x00",
        ["double_tube_revolve"] = "0x5C0x00",
        ["hot_wind_tube_fan_revolve"] = "0x5D0x00",
        ["warm"] = "0x5E0x00",
        ["double_tube_fan"] = "0x5F0x00",
        ["above_inside_tube_revolve"] = "0x600x00",
        ["above_inside_tube_fan"] = "0x610x00",
        ["above_inside_outside_tube_revolve"] = "0x620x00",
        ["above_inside_outside_tube_fan"] = "0x630x00",
        ["above_inside_underside_tube"] = "0x640x00",
        ["above_inside_underside_tube_fan"] = "0x650x00",
        ["above_inside_tube"] = "0x660x00",
        ["above_inside_outside_tube"] = "0x670x00",
        ["underside_tube_fan"] = "0x680x00",
        ["scale_clean"] = "0x790x00",
        ["clean"] = "0x7A0x00",
        ["remove_odor"] = "0x7B0x00",
        ["high_temperature_clean"] = "0x7C0x00",
        ["auto_menu"] = "0xA10x00",
        ["eco"] = "0xA20x00",
        ["above_tube_1"] = "0x510x01",
        ["above_tube_2"] = "0x510x02",
        ["above_tube_3"] = "0x510x03",
        ["underside_tube_1"] = "0x520x01",
        ["underside_tube_2"] = "0x520x02",
        ["double_tube_1"] = "0x530x01",
        ["double_tube_2"] = "0x530x02",
        ["double_tube_3"] = "0x530x03",
        ["double_tube_4"] = "0x530x04",
        ["hot_wind_tube_fan_1"] = "0x540x01",
        ["hot_wind_tube_fan_2"] = "0x540x02",
        ["hot_wind_tube_fan_3"] = "0x540x03",
        ["hot_wind_tube_fan_4"] = "0x540x04",
        ["double_tube_hot_wind_tube_fan_1"] = "0x590x01",
        ["double_tube_hot_wind_tube_fan_2"] = "0x590x02",
        ["double_tube_hot_wind_tube_fan_3"] = "0x590x03",
        ["double_tube_hot_wind_tube_fan_4"] = "0x590x04",
        ["double_tube_hot_wind_tube_fan_5"] = "0x590x05"
    }
    local value = modeTable[mode]
    if (value ~= nil) then
        return value
    else
        return "0xFF0xFF"
    end
end

local function workMode(hex, subHex)
    local modeTable = {
        ["0100"] = "microwave",
        ["0300"] = "microwave_double_tube",
        ["0400"] = "microwave_hot_wind_tube_fan",
        ["0500"] = "microwave_underside_tube_hot_wind_tube_fan",
        ["0600"] = "microwave_double_tube_hot_wind_tube_fan",
        ["0700"] = "microwave_steam",
        ["0900"] = "unfreeze",
        ["0A00"] = "unfreeze_t",
        ["2900"] = "pure_steam",
        ["2B00"] = "steam_above_tube",
        ["2C00"] = "steam_underside_tube",
        ["2D00"] = "steam_double_tube",
        ["2E00"] = "steam_hot_wind_tube_fan",
        ["5100"] = "above_tube",
        ["5200"] = "underside_tube",
        ["5300"] = "double_tube",
        ["5400"] = "hot_wind_tube_fan",
        ["5500"] = "pure_preheat",
        ["5600"] = "above_tube_hot_wind_tube_fan",
        ["5700"] = "underside_tube_hot_wind_tube_fan",
        ["5800"] = "zymosis",
        ["5900"] = "double_tube_hot_wind_tube_fan",
        ["5A00"] = "above_tube_revolve",
        ["5B00"] = "underside_tube_revolve",
        ["5C00"] = "double_tube_revolve",
        ["5D00"] = "hot_wind_tube_fan_revolve",
        ["5E00"] = "warm",
        ["5F00"] = "double_tube_fan",
        ["6000"] = "above_inside_tube_revolve",
        ["6100"] = "above_inside_tube_fan",
        ["6200"] = "above_inside_outside_tube_revolve",
        ["6300"] = "above_inside_outside_tube_fan",
        ["6400"] = "above_inside_underside_tube",
        ["6500"] = "above_inside_underside_tube_fan",
        ["6600"] = "above_inside_tube",
        ["6700"] = "above_inside_outside_tube",
        ["6800"] = "underside_tube_fan",
        ["7900"] = "scale_clean",
        ["7A00"] = "clean",
        ["7B00"] = "remove_odor",
        ["7C00"] = "high_temperature_clean",
        ["A100"] = "auto_menu",
        ["A200"] = "eco",
        ["5101"] = "above_tube_1",
        ["5102"] = "above_tube_2",
        ["5103"] = "above_tube_3",
        ["5201"] = "underside_tube_1",
        ["5202"] = "underside_tube_2",
        ["5301"] = "double_tube_1",
        ["5302"] = "double_tube_2",
        ["5303"] = "double_tube_3",
        ["5304"] = "double_tube_4",
        ["5401"] = "hot_wind_tube_fan_1",
        ["5402"] = "hot_wind_tube_fan_2",
        ["5403"] = "hot_wind_tube_fan_3",
        ["5404"] = "hot_wind_tube_fan_4",
        ["5901"] = "double_tube_hot_wind_tube_fan_1",
        ["5902"] = "double_tube_hot_wind_tube_fan_2",
        ["5903"] = "double_tube_hot_wind_tube_fan_3",
        ["5904"] = "double_tube_hot_wind_tube_fan_4",
        ["5905"] = "double_tube_hot_wind_tube_fan_5"
    }
    local value = modeTable[string.upper(hex) .. string.upper(subHex)]
    if (value ~= nil) then
        return value
    else
        return "ff"
    end
end

local function firePower16(firePower)
    local firePowerTable = {
        ["high_power"] = 0x0A,
        ["medium_high_power"] = 0x08,
        ["medium_power"] = 0x05,
        ["medium_low_power"] = 0x03,
        ["low_power"] = 0x01
    }
    if (firePowerTable[firePower] ~= nil) then
        return firePowerTable[firePower]
    else
        return 0xFF
    end
end

local function firePower(hex)
    local firePowerTable = {
        ["0A"] = "high_power",
        ["08"] = "medium_high_power",
        ["05"] = "medium_power",
        ["03"] = "medium_low_power",
        ["01"] = "low_power"
    }
    local value = firePowerTable[string.upper(hex)]
    if (value ~= nil) then
        return value
    else
        return "ff"
    end
end

local function workStatus16(status)
    local statusTable = {
        ["save_power"] = 0x01,
        ["standby"] = 0x02,
        ["work"] = 0x03,
        ["pause"] = 0x06
    }
    local value = statusTable[status]
    if (value ~= nil) then
        return value
    else
        return 0xFF
    end
end

local function workStatus(hex)
    local statusTable = {
        ["01"] = "save_power",
        ["02"] = "standby",
        ["03"] = "work",
        ["04"] = "work_finish",
        ["05"] = "order",
        ["06"] = "pause",
        ["07"] = "pause_c",
        ["08"] = "three",
        ["0A"] = "self_inspection",
        ["0B"] = "query_version",
        ["0C"] = "demo",
        ["0D"] = "ramadan",
        ["0E"] = "after_checking"
    }
    local value = statusTable[string.upper(hex)]
    if (value ~= nil) then
        return value
    else
        return "ff"
    end
end

local function workend16(action)
    local workendTable = {
        ["auto_next"] = 0x00,
        ["wait_next"] = 0x01,
        ["user_confirm_next"] = 0x02
    }
    local value = workendTable[action]
    if (value ~= nil) then
        return value
    else
        return 0x00
    end
end

local function powerStatus16(power)
    local powerTable = {["on"] = 0x11, ["off"] = 0x01}
    local value = powerTable[power]
    if (value ~= nil) then
        return value
    else
        return 0xFF
    end
end

local function singleCooking(control, bodyBytes)
    if (control["pre_heat"] == "on") then
        bodyBytes[5] = 0x01
    else
        bodyBytes[5] = 0x00
    end
    local workMode = workMode16(control["work_mode"])
    bodyBytes[6] = string.sub(workMode, 1, 4)
    bodyBytes[7] = string.sub(workMode, -4)
    if (control["work_hour"] ~= nil) then
        bodyBytes[8] = control["work_hour"]
    else
        bodyBytes[8] = 0xFF
    end
    if (control["work_minute"] ~= nil) then
        bodyBytes[9] = control["work_minute"]
    else
        bodyBytes[9] = 0xFF
    end
    if (control["work_second"] ~= nil) then
        bodyBytes[10] = control["work_second"]
    else
        bodyBytes[10] = 0xFF
    end
    local firePower = firePower16(control["fire_power"])
    if (firePower == nil) then
        bodyBytes[11] = 0xFF
    else
        bodyBytes[11] = firePower
    end
    local temperature = control["temperature"]
    if (temperature == nil) then
        bodyBytes[12] = 0xFF
        bodyBytes[13] = 0xFF
        bodyBytes[14] = 0xFF
        bodyBytes[15] = 0xFF
    else
        bodyBytes[12] = 0x00
        bodyBytes[13] = temperature
        bodyBytes[14] = 0x00
        bodyBytes[15] = temperature
    end
    local proboValue = control["probo_value"]
    if (proboValue == nil) then
        bodyBytes[16] = 0xFF
        bodyBytes[17] = 0xFF
    else
        bodyBytes[16] = 0x00
        bodyBytes[17] = proboValue
    end
    local steamQuantity = control["steam_quantity"]
    if (steamQuantity == nil) then
        bodyBytes[18] = 0xFF
    else
        bodyBytes[18] = steamQuantity
    end
    if (control["weight"] ~= nil) then
        bodyBytes[19] = control["weight"] / 10
    elseif (control["people_number"] ~= nil) then
        bodyBytes[19] = control["people_number"]
    else
        bodyBytes[19] = 0xFF
    end
    bodyBytes[20] = 0xFF
end

local function multistageCooking(cooking, bodyBytes)
    local n = cooking["stepnum"]
    if (cooking["pre_heat"] == "on") then
        bodyBytes[5 + (n - 1) * 16] = 0x01
    else
        bodyBytes[5 + (n - 1) * 16] = 0x00
    end
    local workMode = workMode16(cooking["work_mode"])
    bodyBytes[6 + (n - 1) * 16] = string.sub(workMode, 1, 4)
    bodyBytes[7 + (n - 1) * 16] = string.sub(workMode, -4)
    if (cooking["work_hour"] ~= nil) then
        bodyBytes[8 + (n - 1) * 16] = cooking["work_hour"]
    else
        bodyBytes[8 + (n - 1) * 16] = 0xFF
    end
    if (cooking["work_minute"] ~= nil) then
        bodyBytes[9 + (n - 1) * 16] = cooking["work_minute"]
    else
        bodyBytes[9 + (n - 1) * 16] = 0xFF
    end
    if (cooking["work_second"] ~= nil) then
        bodyBytes[10 + (n - 1) * 16] = cooking["work_second"]
    else
        bodyBytes[10 + (n - 1) * 16] = 0xFF
    end
    local firePower = firePower16(cooking["fire_power"])
    if (firePower == nil) then
        bodyBytes[11 + (n - 1) * 16] = 0xFF
    else
        bodyBytes[11 + (n - 1) * 16] = firePower
    end
    local temperature = cooking["temperature"]
    if (temperature == nil) then
        bodyBytes[12 + (n - 1) * 16] = 0xFF
        bodyBytes[13 + (n - 1) * 16] = 0xFF
        bodyBytes[14 + (n - 1) * 16] = 0xFF
        bodyBytes[15 + (n - 1) * 16] = 0xFF
    else
        bodyBytes[12 + (n - 1) * 16] = 0x00
        bodyBytes[13 + (n - 1) * 16] = temperature
        bodyBytes[14 + (n - 1) * 16] = 0x00
        bodyBytes[15 + (n - 1) * 16] = temperature
    end
    local proboValue = cooking["probo_value"]
    if (proboValue == nil) then
        bodyBytes[16 + (n - 1) * 16] = 0xFF
        bodyBytes[17 + (n - 1) * 16] = 0xFF
    else
        bodyBytes[16 + (n - 1) * 16] = 0x00
        bodyBytes[17 + (n - 1) * 16] = proboValue
    end
    local steamQuantity = cooking["steam_quantity"]
    if (steamQuantity == nil) then
        bodyBytes[18 + (n - 1) * 16] = 0xFF
    else
        bodyBytes[18 + (n - 1) * 16] = steamQuantity
    end
    if (cooking["weight"] ~= nil) then
        bodyBytes[19 + (n - 1) * 16] = cooking["weight"] / 10
    elseif (cooking["people_number"] ~= nil) then
        bodyBytes[19 + (n - 1) * 16] = cooking["people_number"]
    else
        bodyBytes[19 + (n - 1) * 16] = 0xFF
    end
    bodyBytes[20 + (n - 1) * 16] = workend16(cooking["workend"])
end

local function workModeControl(control, bodyBytes)
    bodyBytes[0] = 0x01
    local cloudmenuid = control["cloudmenuid"]
    if (cloudmenuid ~= nil) then
        local cloudmenuidn = tonumber(cloudmenuid)
        local cloudmenuidH = math.modf(cloudmenuidn / (16 ^ 4))
        local cloudmenuidTemp = math.fmod(cloudmenuidn, (16 ^ 4))
        local cloudmenuidM = math.modf(cloudmenuidTemp / (16 ^ 2))
        local cloudmenuidL = math.fmod(cloudmenuidTemp, (16 ^ 2))
        bodyBytes[1] = cloudmenuidH
        bodyBytes[2] = cloudmenuidM
        bodyBytes[3] = cloudmenuidL
    else
        bodyBytes[1] = 0x00
        bodyBytes[2] = 0x00
        bodyBytes[3] = 0x00
    end
    local totalstep
    if (control["totalstep"] == nil) then
        totalstep = 1
        bodyBytes[4] = 0x11
        singleCooking(control, bodyBytes)
    else
        totalstep = control["totalstep"]
        bodyBytes[4] = "0x" .. totalstep .. control["stepnum_start"]
        local cookingsStr = control["cookings"]
        local cookings = JSON.decode(cookingsStr)
        for key, value in pairs(cookings) do
            multistageCooking(value, bodyBytes)
        end
    end
end

local function notWorkModeControl(control, bodyBytes)
    bodyBytes[0] = 0x02
    if (control["work_status"] ~= nil) then
        bodyBytes[1] = workStatus16(control["work_status"])
    elseif (control["power"] ~= nil) then
        bodyBytes[1] = powerStatus16(control["power"])
    else
        bodyBytes[1] = 0xFF
    end
    if (control["lock"] == "off") then
        bodyBytes[2] = 0x00
    elseif (control["lock"] == "on") then
        bodyBytes[2] = 0x01
    else
        bodyBytes[2] = 0xFF
    end
    if (control["furnace_light"] == "off") then
        bodyBytes[3] = 0x00
    elseif (control["furnace_light"] == "on") then
        bodyBytes[3] = 0x01
    else
        bodyBytes[3] = 0xFF
    end
    if (control["camera"] == "off") then
        bodyBytes[4] = 0x00
    elseif (control["camera"] == "on") then
        bodyBytes[4] = 0x01
    else
        bodyBytes[4] = 0xFF
    end
    if (control["door"] == "close") then
        bodyBytes[5] = 0x00
    elseif (control["door"] == "open") then
        bodyBytes[5] = 0x01
    else
        bodyBytes[5] = 0xFF
    end
    bodyBytes[6] = 0xFF
    bodyBytes[7] = 0xFF
end

local function setControl(control, bodyBytes)
    bodyBytes[0] = 0x03
    bodyBytes[1] = 0x01
    local byteN = 2
    local paramSum = 0
    if (control["steam_set"] ~= nil) then
        byteN = byteN + 1
        bodyBytes[byteN] = 0x00
        byteN = byteN + 1
        paramSum = paramSum + 1
        bodyBytes[byteN] = tonumber(control["steam_set"])
    end
    if (control["hour_set"] ~= nil or control["minute_set"] ~= nil or
        control["second_set"] ~= nil) then
        byteN = byteN + 1
        bodyBytes[byteN] = 0x01
        if (control["hour_set"] ~= nil) then
            bodyBytes[byteN + 1] = tonumber(control["hour_set"])
        else
            bodyBytes[byteN + 1] = 0x00
        end
        if (control["minute_set"] ~= nil) then
            bodyBytes[byteN + 2] = tonumber(control["minute_set"])
        else
            bodyBytes[byteN + 2] = 0x00
        end
        if (control["second_set"] ~= nil) then
            bodyBytes[byteN + 3] = tonumber(control["second_set"])
        else
            bodyBytes[byteN + 3] = 0x00
        end
        paramSum = paramSum + 1
        byteN = byteN + 3
    end
    if (control["fire_power_set"] ~= nil) then
        byteN = byteN + 1
        bodyBytes[byteN] = 0x02
        byteN = byteN + 1
        paramSum = paramSum + 1
        bodyBytes[byteN] = firePower16(control["fire_power_set"])
    end
    if (control["temp_set"] ~= nil) then
        byteN = byteN + 1
        bodyBytes[byteN] = 0x03
        bodyBytes[byteN + 1] = 0x00
        bodyBytes[byteN + 2] = 0x00
        bodyBytes[byteN + 3] = tonumber(control["temp_set"])
        paramSum = paramSum + 1
    end
    bodyBytes[2] = paramSum
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)
    local query = json["query"]
    local control = json["control"]
    if (control) then
        local bodyBytes = {}
        if (control["work_mode"] ~= nil or control["cookings"] ~= nil) then
            workModeControl(control, bodyBytes)
        elseif (control["work_status"] ~= nil or control["lock"] ~= nil or
            control["furnace_light"] ~= nil or control["power"] ~= nil) then
            notWorkModeControl(control, bodyBytes)
        elseif (control["hour_set"] ~= nil or control["minute_set"] ~= nil or
            control["second_set"] ~= nil or control["temp_set"] ~= nil or
            control["steam_set"] ~= nil or control["fire_power_set"] ~= nil) then
            setControl(control, bodyBytes)
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        local bodyLength = 1
        local bodyBytes = {}
        bodyBytes[0] = 0x01
        for i = 1, bodyLength - 1 do bodyBytes[i] = 0x00 end
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
    end
    local infoM = {}
    local length = #msgBytes + 1
    for i = 1, length do infoM[i] = msgBytes[i - 1] end
    local ret = tableToString(infoM)
    return stringToHex(ret)
end

local function deviceToCloud(megBodys)
    local jsonTable = {}
    jsonTable["version"] = VALUE_VERSION
    if (megBodys[9] == "02" or megBodys[9] == "03" or megBodys[9] == "04") then
        jsonTable["execute"] = "ok"
        if (megBodys[11] == "01") then
            jsonTable["execute"] = "status_nonsupport"
        elseif (megBodys[11] == "02") then
            jsonTable["execute"] = "function_nonsupport"
        elseif (megBodys[11] == "03") then
            jsonTable["execute"] = "param_range_error"
        end
        jsonTable["cloudmenuid"] = tonumber(megBodys[12], 16) * (16 ^ 4) +
                                       tonumber(megBodys[13], 16) * (16 ^ 2) +
                                       tonumber(megBodys[14], 16)
        jsonTable["totalstep"] = math.modf(tonumber(megBodys[15], 16) / 16)
        jsonTable["stepnum"] = math.fmod(tonumber(megBodys[15], 16), 16)
        jsonTable["work_mode"] = workMode(megBodys[17], megBodys[18])
        if (megBodys[19] ~= "FF" and megBodys[19] ~= "ff") then
            jsonTable["hour_set"] = tonumber(megBodys[19], 16)
        end
        if (megBodys[20] ~= "FF" and megBodys[20] ~= "ff") then
            jsonTable["minute_set"] = tonumber(megBodys[20], 16)
        end
        if (megBodys[21] ~= "FF" and megBodys[21] ~= "ff") then
            jsonTable["second_set"] = tonumber(megBodys[21], 16)
        end
        jsonTable["fire_power"] = firePower(megBodys[22])
        if (megBodys[24] ~= "FF" and megBodys[24] ~= "ff") then
            jsonTable["temperature"] = tonumber(megBodys[24], 16)
        else
            jsonTable["temperature"] = "ff"
        end
        if (megBodys[29] ~= "FF" and megBodys[29] ~= "ff") then
            jsonTable["steam_quantity"] = tonumber(megBodys[29], 16)
        else
            jsonTable["steam_quantity"] = "ff"
        end
        if (megBodys[30] ~= "FF" and megBodys[30] ~= "ff") then
            jsonTable["weight"] = tonumber(megBodys[30], 16) * 10
            jsonTable["people_number"] = tonumber(megBodys[30], 16)
        else
            jsonTable["weight"] = "ff"
            jsonTable["people_number"] = "ff"
        end
        if (megBodys[32] ~= "FF" and megBodys[32] ~= "ff") then
            jsonTable["work_hour"] = tonumber(megBodys[32], 16)
        end
        if (megBodys[33] ~= "FF" and megBodys[33] ~= "ff") then
            jsonTable["work_minute"] = tonumber(megBodys[33], 16)
        end
        if (megBodys[34] ~= "FF" and megBodys[34] ~= "ff") then
            jsonTable["work_second"] = tonumber(megBodys[34], 16)
        end
        if (megBodys[36] ~= "FF" and megBodys[36] ~= "ff") then
            jsonTable["cur_temperature_above"] = tonumber(megBodys[36], 16)
        end
        if (megBodys[38] ~= "FF" and megBodys[38] ~= "ff") then
            jsonTable["cur_temperature_underside"] = tonumber(megBodys[38], 16)
        end
        jsonTable["work_status"] = workStatus(megBodys[41])
        local b42 = megBodys[42]
        local b43 = megBodys[43]
        local lock = getByteBit(b42, 0)
        local door = getByteBit(b42, 1)
        local water_box = getByteBit(b42, 2)
        local water_state = getByteBit(b42, 3)
        local change_water = getByteBit(b42, 4)
        local preheat = getByteBit(b42, 5)
        local preheat_end = getByteBit(b42, 6)
        local error_code = getByteBit(b42, 7)
        local flip_side = getByteBit(b43, 0)
        local reaction = getByteBit(b43, 1)
        local furnace_light = getByteBit(b43, 2)
        if (door == "1") then
            jsonTable["door_open"] = "on"
        elseif (door == "0") then
            jsonTable["door_open"] = "off"
        end
        if (lock == "1") then
            jsonTable["lock"] = "on"
        elseif (lock == "0") then
            jsonTable["lock"] = "off"
        end
        jsonTable["water_status"] = "normal"
        if (water_box == "1") then
            jsonTable["water_status"] = "lack_box"
        elseif (water_state == "1") then
            jsonTable["water_status"] = "lack_water"
        elseif (change_water == "1") then
            jsonTable["water_status"] = "change_water"
        end
        jsonTable["pre_heat"] = "off"
        if (preheat_end == "1") then
            jsonTable["pre_heat"] = "end"
        elseif (preheat == "1") then
            jsonTable["pre_heat"] = "work"
        end
        if (flip_side == "1") then
            jsonTable["flip_side"] = 1
        else
            jsonTable["flip_side"] = 0
        end
        if (error_code == "1") then
            jsonTable["error_code"] = 1
        else
            jsonTable["error_code"] = 0
        end
        if (reaction == "1") then
            jsonTable["reaction"] = 1
        else
            jsonTable["reaction"] = 0
        end
        if (furnace_light == "1") then
            jsonTable["furnace_light"] = "on"
        else
            jsonTable["furnace_light"] = "off"
        end
        local b57 = megBodys[57]
        local b58 = megBodys[58]
        local b59 = megBodys[59]
        jsonTable["cbs_version"] = "V0.0.0"
        if (b57 ~= nil and b58 ~= nil and b59 ~= nil) then
            local cbs_version = "V" .. tonumber(b57, 16) .. "." ..
                                    tonumber(b58, 16) .. "." ..
                                    tonumber(b59, 16)
            jsonTable["cbs_version"] = cbs_version
        end
        jsonTable["clean_scale"] = 0
        jsonTable["clean_sink_ponding"] = 0
        local b66 = megBodys[66]
        if (b66 ~= nil) then
            local clean_scale = getByteBit(b66, 6)
            if (clean_scale == "1") then jsonTable["clean_scale"] = 1 end
        end
        local b68 = megBodys[68]
        if (b68 ~= nil) then
            local clean_sink_ponding = getByteBit(b68, 0)
            if (clean_sink_ponding == "1") then
                jsonTable["clean_sink_ponding"] = 1
            end
        end
    end
    return jsonTable
end

function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decodeJsonToTable(jsonStr)
    local binData = json["msg"]["data"]
    local status = json["status"]
    local retTable = {}
    retTable["status"] = {}
    local bodyBytes = hexToTable(binData)
    retTable["status"] = deviceToCloud(bodyBytes)
    local ret = encodeTableToJson(retTable)
    return ret
end
