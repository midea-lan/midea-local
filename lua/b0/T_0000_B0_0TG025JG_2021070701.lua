local bit = require "bit"
local JSON = require "cjson"
local BYTE_DEVICE_TYPE = 0xB0
local BYTE_PROTOCOL_VERSION = 0x03
local BYTE_PROTOCOL_YEAR_VERSION = 0x01
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local VALUE_VERSION = 7
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
        ["remove_odor"] = 0xC3,
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
        ["start"] = 0x02,
        ["work"] = 0x03,
        ["pause"] = 0x06
    }
    if (statusTable[status] ~= nil) then
        return statusTable[status]
    else
        return 0xFF
    end
end
local function powerStatus16(power)
    local powerTable = {["on"] = 0x02, ["off"] = 0x01}
    if (powerTable[power] ~= nil) then
        return powerTable[power]
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
        ["low_power"] = 0x01
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
    elseif (meg == "08") then
        power_type = "medium_high_power"
    elseif (meg == "05") then
        power_type = "medium_power"
    elseif (meg == "03") then
        power_type = "medium_low_power"
    elseif (meg == "01") then
        power_type = "low_power"
    else
        power_type = "ff"
    end
    return power_type
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
local function singleCooking(control, bodyBytes)
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
    if (temperature == nil) then temperature = control["temperature_gear"] end
    if (temperature == nil) then
        bodyBytes[11] = 0x00
        bodyBytes[12] = 0x00
        bodyBytes[13] = 0x00
        bodyBytes[14] = 0x00
    else
        local temperatureH = math.modf(temperature / (16 ^ 2))
        local temperatureL = math.fmod(temperature, (16 ^ 2))
        bodyBytes[11] = temperatureH
        bodyBytes[12] = temperatureL
        bodyBytes[13] = temperatureH
        bodyBytes[14] = temperatureL
    end
    local firePower = firePower16(control["fire_power"])
    if (firePower == nil) then
        bodyBytes[15] = 0xFF
    else
        bodyBytes[15] = firePower
    end
    if (control["weight"] ~= nil) then
        bodyBytes[16] = control["weight"] / 10
    elseif (control["people_number"] ~= nil) then
        bodyBytes[16] = control["people_number"]
    elseif (control["steam_quantity"] ~= nil) then
        bodyBytes[16] = control["steam_quantity"]
    else
        bodyBytes[16] = 0xFF
    end
    bodyBytes[17] = 0xFF
    if (control["probe_temperature"] == nil) then
        bodyBytes[18] = 0x00
    else
        bodyBytes[18] = control["probe_temperature"]
    end
end
local function multistageCooking(cooking, bodyBytes)
    local n = cooking["stepnum"]
    if (cooking["pre_heat"] == "on") then bodyBytes[6] = 0x01 end
    if (cooking["work_hour"] ~= nil) then
        bodyBytes[7 + (n - 1) * 12] = cooking["work_hour"]
    else
        bodyBytes[7 + (n - 1) * 12] = 0x00
    end
    if (cooking["work_minute"] ~= nil) then
        bodyBytes[8 + (n - 1) * 12] = cooking["work_minute"]
    else
        bodyBytes[8 + (n - 1) * 12] = 0x00
    end
    if (cooking["work_second"] ~= nil) then
        bodyBytes[9 + (n - 1) * 12] = cooking["work_second"]
    else
        bodyBytes[9 + (n - 1) * 12] = 0x00
    end
    bodyBytes[10 + (n - 1) * 12] = workMode16(cooking["work_mode"])
    local temperature = cooking["temperature"]
    if (temperature == nil) then temperature = cooking["temperature_gear"] end
    if (temperature == nil) then
        bodyBytes[11 + (n - 1) * 12] = 0x00
        bodyBytes[12 + (n - 1) * 12] = 0x00
        bodyBytes[13 + (n - 1) * 12] = 0x00
        bodyBytes[14 + (n - 1) * 12] = 0x00
    else
        local temperatureH = math.modf(temperature / (16 ^ 2))
        local temperatureL = math.fmod(temperature, (16 ^ 2))
        bodyBytes[11 + (n - 1) * 12] = temperatureH
        bodyBytes[12 + (n - 1) * 12] = temperatureL
        bodyBytes[13 + (n - 1) * 12] = temperatureH
        bodyBytes[14 + (n - 1) * 12] = temperatureL
    end
    local firePower = firePower16(cooking["fire_power"])
    if (firePower == nil) then
        bodyBytes[15 + (n - 1) * 12] = 0xFF
    else
        bodyBytes[15 + (n - 1) * 12] = firePower
    end
    if (cooking["weight"] ~= nil) then
        bodyBytes[16 + (n - 1) * 12] = cooking["weight"] / 10
    elseif (cooking["people_number"] ~= nil) then
        bodyBytes[16 + (n - 1) * 12] = cooking["people_number"]
    elseif (cooking["steam_quantity"] ~= nil) then
        bodyBytes[16 + (n - 1) * 12] = cooking["steam_quantity"]
    else
        bodyBytes[16 + (n - 1) * 12] = 0xFF
    end
    bodyBytes[17 + (n - 1) * 12] = workend16(cooking["workend"])
    if (cooking["probe_temperature"] == nil) then
        bodyBytes[18 + (n - 1) * 12] = 0x00
    else
        bodyBytes[18 + (n - 1) * 12] = cooking["probe_temperature"]
    end
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
    else
        bodyBytes[2] = 0x00
        bodyBytes[3] = 0x00
        bodyBytes[4] = 0x00
        bodyBytes[5] = 0x11
    end
    if (control["pre_heat"] == "on") then
        bodyBytes[6] = 0x01
    else
        bodyBytes[6] = 0x00
    end
    local totalstep
    if (control["totalstep"] == nil) then
        totalstep = 1
        bodyBytes[5] = 0x11
        singleCooking(control, bodyBytes)
    else
        totalstep = control["totalstep"]
        bodyBytes[5] = "0x" .. totalstep .. control["stepnum_start"]
        local cookingsStr = control["cookings"]
        local cookings = JSON.decode(cookingsStr)
        for key, value in pairs(cookings) do
            multistageCooking(value, bodyBytes)
        end
    end
end
local function notWorkModeControl(control, bodyBytes)
    bodyBytes[0] = 0x22
    bodyBytes[1] = 0x02
    if (control["work_status"] ~= nil) then
        bodyBytes[2] = workStatus16(control["work_status"])
    elseif (control["power"] ~= nil) then
        bodyBytes[2] = powerStatus16(control["power"])
    else
        bodyBytes[2] = 0xff
    end
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
        if (control["work_mode"] ~= nil or control["cookings"] ~= nil) then
            workModeControl(control, bodyBytes)
        elseif (control["work_status"] ~= nil or control["lock"] ~= nil or
            control["furnace_light"] ~= nil or control["power"] ~= nil) then
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
        bodyBytes[0] = 0x31
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
    elseif (meg == "40") then
        modetype = "above_tube"
    elseif (meg == "A0" or meg == "a0") then
        modetype = "unfreeze"
    elseif (meg == "C3" or meg == "c3") then
        modetype = "remove_odor"
    elseif (meg == "E0" or meg == "e0") then
        modetype = "auto_menu"
    elseif (meg == "E2" or meg == "e2") then
        modetype = "humidit_auto_menu"
    else
        modetype = "ff"
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
    if (megBodys[9] == "03" or megBodys[9] == "04") then
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
        else
            jsonTable["work_status"] = "ff"
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
        jsonTable["work_mode"] = getModeType(megBodys[19])
        if (megBodys[21] ~= "FF" and megBodys[21] ~= "ff") then
            jsonTable["cur_temperature_above"] = tonumber(megBodys[21], 16)
        end
        if (megBodys[23] ~= "FF" and megBodys[23] ~= "ff") then
            jsonTable["cur_temperature_underside"] = tonumber(megBodys[23], 16)
        end
        jsonTable["fire_power"] = getFirePowerType(megBodys[24])
        if (megBodys[25] ~= "FF" and megBodys[25] ~= "ff") then
            jsonTable["weight"] = tonumber(megBodys[25], 16) * 10
            jsonTable["people_number"] = tonumber(megBodys[25], 16)
        else
            jsonTable["weight"] = "ff"
            jsonTable["people_number"] = "ff"
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
        local change_water = getByteBit(b26, 4)
        local preheat = getByteBit(b26, 5)
        local preheat_end = getByteBit(b26, 6)
        local error_code = getByteBit(b26, 7)
        local flip_side = getByteBit(b27, 0)
        local reaction = getByteBit(b27, 1)
        local furnace_light = getByteBit(b27, 2)
        local probe = getByteBit(b27, 6)
        if (water_box == "1") then
            jsonTable["tips_code"] = 6
        elseif (water_state == "1") then
            jsonTable["tips_code"] = 2
        elseif (change_water == "1") then
            jsonTable["tips_code"] = 7
        elseif (preheat_end == "1") then
            jsonTable["tips_code"] = 9
        elseif (preheat == "1") then
            jsonTable["tips_code"] = 8
        elseif (flip_side == "1") then
            jsonTable["tips_code"] = 4
        else
            jsonTable["tips_code"] = 0
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
        elseif (furnace_light == "0") then
            jsonTable["furnace_light"] = "off"
        end
        if (probe == "1") then
            jsonTable["probe"] = 1
        elseif (probe == "0") then
            jsonTable["probe"] = 0
        end
        jsonTable["temperature"] = 0
        if (megBodys[29] ~= "FF" and megBodys[29] ~= "ff") then
            local temperature_above = tonumber(megBodys[29], 16)
            if (temperature_above ~= 0) then
                jsonTable["temperature"] = temperature_above
            end
        end
        if (megBodys[31] ~= "FF" and megBodys[31] ~= "ff") then
            local temperature_underside = tonumber(megBodys[31], 16)
            if (temperature_underside ~= 0) then
                jsonTable["temperature"] = temperature_underside
            end
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
            jsonTable["hour_set"] = "ff"
            jsonTable["minute_set"] = "ff"
            jsonTable["second_set"] = "ff"
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
    local bodyBytes = string2table(binData)
    retTable["status"] = cloudToDevice(bodyBytes)
    local ret = encodeTableToJson(retTable)
    return ret
end
