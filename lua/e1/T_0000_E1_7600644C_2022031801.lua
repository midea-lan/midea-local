local bit = require "bit"
local uptable = {}
uptable["VALUE_VERSION"] = 28
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
        crc = crc8_854_table[bit_band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
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
local function table2hex(cmd)
    local ret = ""
    for i = 1, #cmd do ret = ret .. string.format("%02x", cmd[i]) end
    return ret
end
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end
local function split(szFullString, szSeparator)
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
local function checkBoundary(data, min, max)
    if (not data) then data = 0 end
    data = tonumber(data)
    if ((data >= min) and (data <= max)) then
        return data
    else
        if (data < min) then
            return min
        else
            return max
        end
    end
end
local function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then k = string.format("%q", k) end
        local szSuffix = ""
        if type(v) == "table" then szSuffix = "{" end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix .. "[" .. k .. "]" .. " = " .. szSuffix
        if type(v) == "table" then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix .. "},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting .. szValue .. ",")
        end
    end
end
local function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do msgBytes[i - 1] = byteData[i] end
    local bodyLength = msgLength - 0x0A - 1
    for i = 0, bodyLength - 1 do bodyBytes[i] = msgBytes[i + 0x0A] end
    return bodyBytes
end
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if bodyLength == 0 then return nil end
    local msgLength = (bodyLength + 0x0A + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = 0xAA
    msgBytes[1] = msgLength - 1
    msgBytes[2] = 0xE1
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do msgBytes[i + 0x0A] = bodyBytes[i] end
    msgBytes[msgLength - 1] = makeSum(msgBytes, 1, msgLength - 2)
    local msgBytesTemp = {}
    local length = #msgBytes + 1
    for i = 1, length do msgBytesTemp[i] = msgBytes[i - 1] end
    return msgBytesTemp
end
local function updateDataByJson(luaTable, bodyBytes)
    if luaTable["lock"] ~= nil then
        bodyBytes[0] = 0x83
        if luaTable["lock"] == "on" then
            bodyBytes[1] = 0x03
        elseif luaTable["lock"] == "off" then
            bodyBytes[1] = 0x04
        end
    elseif luaTable["operator"] ~= nil and luaTable["operator"] ~= "" then
        bodyBytes[0] = 0x83
        if luaTable["operator"] == "start" then
            bodyBytes[1] = 0x01
        elseif luaTable["operator"] == "pause" then
            bodyBytes[1] = 0x02
        end
    elseif luaTable["softwater"] ~= nil then
        bodyBytes[0] = 0x80
        bodyBytes[1] = luaTable["softwater"]
    elseif luaTable["bright"] ~= nil then
        bodyBytes[0] = 0x84
        bodyBytes[1] = luaTable["bright"]
    elseif luaTable["airswitch"] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = luaTable["airswitch"]
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = 0xff
        bodyBytes[8] = 0xff
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
        bodyBytes[11] = 0xff
    elseif luaTable["dryswitch"] ~= nil or luaTable["dry_set_min"] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = 0xff
        bodyBytes[8] = 0xff
        if luaTable["dryswitch"] == nil then
            bodyBytes[9] = 0xff
        else
            bodyBytes[9] = luaTable["dryswitch"]
        end
        if luaTable["dry_set_min"] == nil then
            bodyBytes[10] = 0xff
        else
            bodyBytes[10] = luaTable["dry_set_min"]
        end
        bodyBytes[11] = 0xff
    elseif luaTable["waterswitch"] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = 0xff
        bodyBytes[8] = luaTable["waterswitch"]
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
        bodyBytes[11] = 0xff
    elseif luaTable["uvswitch"] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = luaTable["uvswitch"]
        bodyBytes[8] = 0xff
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
        bodyBytes[11] = 0xff
    elseif luaTable["dry_step_switch"] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = luaTable["dry_step_switch"]
        bodyBytes[7] = 0xff
        bodyBytes[8] = 0xff
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
        bodyBytes[11] = 0xff
    elseif luaTable["auto_throw"] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = 0xff
        bodyBytes[8] = 0xff
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
        bodyBytes[11] = luaTable["auto_throw"]
    elseif luaTable["air_set_hour"] ~= nil then
        bodyBytes[0] = 0x86
        bodyBytes[1] = luaTable["air_set_hour"]
    elseif luaTable["diy_times"] ~= nil then
        local diy_times, diy_main_wash, diy_piao_wash = 0x00
        diy_times = luaTable["diy_times"]
        if (luaTable["diy_main_wash"] ~= nil) then
            diy_main_wash = luaTable["diy_main_wash"]
        end
        if (luaTable["diy_piao_wash"] ~= nil) then
            diy_piao_wash = luaTable["diy_piao_wash"]
        end
        bodyBytes[0] = 0x82
        bodyBytes[1] = diy_times
        bodyBytes[3] = diy_main_wash
        bodyBytes[5] = diy_piao_wash
    elseif luaTable["cmd_cloud"] ~= nil then
        local array = split(luaTable["cmd_cloud"], ",")
        for i = 1, #array do bodyBytes[i - 1] = tonumber(array[i], 16) end
    elseif luaTable["firmware_actiontype"] ~= nil then
        bodyBytes[0] = 0x91
        bodyBytes[1] = luaTable["firmware_actiontype"]
    elseif luaTable["common_down_type"] ~= nil then
        bodyBytes[0] = 0x90
        bodyBytes[1] = luaTable["common_down_type"]
        if luaTable["common_down_type"] == 2 then
            if luaTable["voice_inside_volumn"] ~= nil then
                bodyBytes[11] = luaTable["voice_inside_volumn"]
            end
            if luaTable["voice_inside_mic_on"] ~= nil then
                bodyBytes[12] = luaTable["voice_inside_mic_on"]
            end
        end
    else
        local workStatus = 0x00
        if luaTable["work_status"] == "power_on" then
            workStatus = 0x01
        elseif luaTable["work_status"] == "power_off" then
            workStatus = 0x00
        elseif luaTable["work_status"] == "cancel" then
            workStatus = 0x01
        elseif luaTable["work_status"] == "work" then
            workStatus = 0x03
        elseif luaTable["work_status"] == "order" then
            workStatus = 0x02
        elseif luaTable["work_status"] == "cancel_order" then
            workStatus = 0x04
        end
        local mode = 0x00
        if luaTable["mode"] == "neutral_gear" then
            mode = 0x00
        elseif luaTable["mode"] == "auto_wash" then
            mode = 0x01
        elseif luaTable["mode"] == "strong_wash" then
            mode = 0x02
        elseif luaTable["mode"] == "standard_wash" then
            mode = 0x03
        elseif luaTable["mode"] == "eco_wash" then
            mode = 0x04
        elseif luaTable["mode"] == "glass_wash" then
            mode = 0x05
        elseif luaTable["mode"] == "hour_wash" then
            mode = 0x06
        elseif luaTable["mode"] == "fast_wash" then
            mode = 0x07
        elseif luaTable["mode"] == "soak_wash" then
            mode = 0x08
        elseif luaTable["mode"] == "90min_wash" then
            mode = 0x09
        elseif luaTable["mode"] == "self_clean" then
            mode = 0x0a
        elseif luaTable["mode"] == "fruit_wash" then
            mode = 0x0b
        elseif luaTable["mode"] == "self_define" then
            mode = 0x0c
        elseif luaTable["mode"] == "germ" then
            mode = 0x0D
        elseif luaTable["mode"] == "bowl_wash" then
            mode = 0x0e
        elseif luaTable["mode"] == "kill_germ" then
            mode = 0x0f
        elseif luaTable["mode"] == "seafood_wash" then
            mode = 0x10
        elseif luaTable["mode"] == "hotpot_wash" then
            mode = 0x12
        elseif luaTable["mode"] == "quietnight_wash" then
            mode = 0x13
        elseif luaTable["mode"] == "less_wash" then
            mode = 0x14
        elseif luaTable["mode"] == "max_rapid_wash" then
            mode = 0x15
        elseif luaTable["mode"] == "oilnet_wash" then
            mode = 0x16
        elseif luaTable["mode"] == "cloud_wash" then
            mode = 0x19
        else
            if workStatus == 0x03 then mode = 0x04 end
        end
        local additional = 0x00
        if luaTable["additional"] ~= nil then
            additional = luaTable["additional"]
        end
        local wash_region = 0x00
        if luaTable["wash_region"] ~= nil then
            wash_region = luaTable["wash_region"]
        end
        local door_auto_open = 0x00
        if luaTable["door_auto_open"] ~= nil then
            door_auto_open = luaTable["door_auto_open"]
        end
        if luaTable["auto_throw"] ~= nil then
            if luaTable["auto_throw"] == 1 then
                bodyBytes[5] = 0x40
            else
                bodyBytes[5] = 0x00
            end
        end
        bodyBytes[0] = 0x08
        bodyBytes[1] = workStatus
        bodyBytes[2] = mode
        bodyBytes[3] = additional
        bodyBytes[4] = wash_region
        bodyBytes[13] = door_auto_open
        if (workStatus == 0x02) then
            local orderSetTime = 0x00
            if luaTable["order_set_hour"] ~= nil and luaTable["order_set_min"] ~=
                nil then
                orderSetTime = luaTable["order_set_hour"] * 60 +
                                   luaTable["order_set_min"]
            end
            bodyBytes[7] = math.modf(orderSetTime / 60)
            bodyBytes[8] = math.fmod(orderSetTime, 60)
        end
        if (mode == 0x0f) then
            if luaTable["work_time"] ~= nil then
                bodyBytes[10] = luaTable["work_time"]
            end
        end
        if luaTable["water_level"] ~= nil then
            bodyBytes[11] = luaTable["water_level"]
        end
        if luaTable["water_strong_level"] ~= nil then
            bodyBytes[12] = luaTable["water_strong_level"]
        end
    end
end
local function updateJsonByData(binData)
    local byteData = string2table(binData)
    local bodyBytes = extractBodyBytes(byteData)
    local retTable = {}
    local streams = {}
    streams["version"] = uptable["VALUE_VERSION"]
    streams["cmd"] = binData
    local dataType = byteData[10]
    streams["msg_type"] = dataType
    if (dataType ~= 0x02 and dataType ~= 0x03 and dataType ~= 0x04) then
        retTable["status"] = streams
        return encodeTableToJson(retTable)
    end
    if byteData[11] == 0x01 then
        retTable["status"] = streams
        return encodeTableToJson(retTable)
    end
    local subDataType = byteData[11]
    streams["sub_msg_type"] = subDataType
    local workStatus = bodyBytes[1]
    if workStatus == 0x00 then
        streams["work_status"] = "power_off"
    elseif workStatus == 0x01 then
        streams["work_status"] = "cancel"
    elseif workStatus == 0x03 then
        streams["work_status"] = "work"
    elseif workStatus == 0x02 then
        streams["work_status"] = "order"
    elseif workStatus == 0x04 then
        streams["work_status"] = "error"
    elseif workStatus == 0x05 then
        streams["work_status"] = uptable["VALUE_WORK_STATUS_SOFT_GEAR"]
    else
    end
    local mode = bodyBytes[2]
    if mode == 0x00 then
        streams["mode"] = "neutral_gear"
    elseif mode == 0x01 then
        streams["mode"] = "auto_wash"
    elseif mode == 0x02 then
        streams["mode"] = "strong_wash"
    elseif mode == 0x03 then
        streams["mode"] = "standard_wash"
    elseif mode == 0x04 then
        streams["mode"] = "eco_wash"
    elseif mode == 0x05 then
        streams["mode"] = "glass_wash"
    elseif mode == 0x06 then
        streams["mode"] = "hour_wash"
    elseif mode == 0x07 then
        streams["mode"] = "fast_wash"
    elseif mode == 0x08 then
        streams["mode"] = "soak_wash"
    elseif mode == 0x09 then
        streams["mode"] = "90min_wash"
    elseif mode == 0x0a then
        streams["mode"] = "self_clean"
    elseif mode == 0x0b then
        streams["mode"] = "fruit_wash"
    elseif mode == 0x0c then
        streams["mode"] = "self_define"
    elseif mode == 0x0D then
        streams["mode"] = "germ"
    elseif mode == 0x0e then
        streams["mode"] = "bowl_wash"
    elseif mode == 0x0f then
        streams["mode"] = "kill_germ"
        if bodyBytes[29] ~= nil then streams["work_time"] = bodyBytes[29] end
    elseif mode == 0x10 then
        streams["mode"] = "seafood_wash"
    elseif mode == 0x12 then
        streams["mode"] = "hotpot_wash"
    elseif mode == 0x13 then
        streams["mode"] = "quietnight_wash"
    elseif mode == 0x14 then
        streams["mode"] = "less_wash"
    elseif mode == 0x15 then
        streams["mode"] = "max_rapid_wash"
    elseif mode == 0x16 then
        streams["mode"] = "oilnet_wash"
    elseif mode == 0x19 then
        streams["mode"] = "cloud_wash"
    else
        streams["mode"] = "invalid"
    end
    local additional = bodyBytes[3]
    if (additional ~= nil) then streams["additional"] = additional end
    local lackbright = (bit_band(bodyBytes[5], 0x02) == 0x02)
    if lackbright then
        streams["bright_lack"] = 1
    else
        streams["bright_lack"] = 0
    end
    local lacksoftwater = (bit_band(bodyBytes[5], 0x04) == 0x04)
    if lacksoftwater then
        streams["softwater_lack"] = 1
    else
        streams["softwater_lack"] = 0
    end
    local diyflag = (bit_band(bodyBytes[4], 0x08) == 0x08)
    if diyflag then
        streams["diy_flag"] = 1
    else
        streams["diy_flag"] = 0
    end
    local doorautoflag = (bit_band(bodyBytes[4], 0x40) == 0x40)
    if doorautoflag then
        streams["door_auto_open"] = 1
    else
        streams["door_auto_open"] = 0
    end
    local lock = bit_band(bodyBytes[5], 0x10)
    if (lock == 0x10) then
        streams["lock"] = "on"
    else
        streams["lock"] = "off"
    end
    local operator = bit_band(bodyBytes[5], 0x08)
    if operator == 0x08 then
        streams["operator"] = "start"
    elseif workStatus == 0x03 then
        streams["operator"] = "pause"
    elseif workStatus == 0x02 then
        streams["operator"] = "pause"
    else
        streams["operator"] = ""
    end
    local leftTime = bodyBytes[6]
    if bodyBytes[32] ~= nil then
        local leftTimeHigh = bodyBytes[32]
        streams["left_time"] = leftTimeHigh * 256 + leftTime
    else
        streams["left_time"] = leftTime
    end
    local washStage = bodyBytes[9]
    streams["wash_stage"] = washStage
    local errorCode = bodyBytes[10]
    streams["error_code"] = errorCode
    local temperature = bodyBytes[11]
    streams["temperature"] = temperature
    local softwater = bodyBytes[13]
    streams["softwater"] = softwater
    local wrongOperation = bodyBytes[16]
    streams["wrong_operation"] = wrongOperation
    local airswitch = (bit_band(bodyBytes[5], 0x20) == 0x20)
    local airStatus = (bit_band(bodyBytes[5], 0x40) == 0x40)
    local airSetTime = bodyBytes[17]
    local airLeftTime = bodyBytes[18]
    if airswitch then
        streams["airswitch"] = 1
    else
        streams["airswitch"] = 0
    end
    if airStatus then
        streams["air_status"] = 1
    else
        streams["air_status"] = 0
    end
    streams["air_set_hour"] = airSetTime
    streams["air_left_hour"] = airLeftTime
    local doorswitch = (bit_band(bodyBytes[5], 0x01) == 0x01)
    if doorswitch then
        streams["doorswitch"] = 1
    else
        streams["doorswitch"] = 0
    end
    local dryswitch = (bit_band(bodyBytes[4], 0x10) == 0x10)
    local drystatus = (bit_band(bodyBytes[4], 0x20) == 0x20)
    if drystatus then
        streams["dryswitch"] = 2
    elseif dryswitch then
        streams["dryswitch"] = 1
    else
        streams["dryswitch"] = 0
    end
    local waterswitch = (bit_band(bodyBytes[4], 0x04) == 0x04)
    if waterswitch then
        streams["waterswitch"] = 1
    else
        streams["waterswitch"] = 0
    end
    if (workStatus == 0x02) then
        local orderSetTime = bodyBytes[19] * 60 + bodyBytes[20]
        local orderLeftTime = bodyBytes[7] * 60 + bodyBytes[8]
        streams["order_set_hour"] = math.modf(orderSetTime / 60)
        streams["order_set_min"] = math.fmod(orderSetTime, 60)
        streams["order_left_hour"] = math.modf(orderLeftTime / 60)
        streams["order_left_min"] = math.fmod(orderLeftTime, 60)
    else
        streams["diy_times"] = bodyBytes[19]
        streams["diy_main_wash"] = bodyBytes[21]
        streams["diy_piao_wash"] = bodyBytes[23]
    end
    if bodyBytes[24] ~= nil then streams["bright"] = bodyBytes[24] end
    if bodyBytes[28] ~= nil then streams["device_version"] = bodyBytes[28] end
    if bodyBytes[31] ~= nil then
        streams["water_level"] = bodyBytes[30]
        streams["water_strong_level"] = bodyBytes[31]
    end
    local water_lack = (bit_band(bodyBytes[5], 0x80) == 0x80)
    if water_lack then
        streams["water_lack"] = 1
    else
        streams["water_lack"] = 0
    end
    local dry_step_switch = (bit_band(bodyBytes[4], 0x01) == 0x01)
    if dry_step_switch then
        streams["dry_step_switch"] = 0
    else
        streams["dry_step_switch"] = 1
    end
    local uvswitch = (bit_band(bodyBytes[4], 0x02) == 0x02)
    if uvswitch then
        streams["uvswitch"] = 1
    else
        streams["uvswitch"] = 0
    end
    if bodyBytes[33] ~= nil then streams["humidity"] = bodyBytes[33] end
    if bodyBytes[34] ~= nil then streams["dry_set_min"] = bodyBytes[34] end
    if bodyBytes[35] ~= nil then streams["wash_region"] = bodyBytes[35] end
    if bodyBytes[36] ~= nil then streams["ota_version"] = bodyBytes[36] end
    if bodyBytes[37] ~= nil then
        if bodyBytes[37] == 0x04 then
            streams["auto_throw"] = 1
            streams["throw_percent"] = 100
        elseif bodyBytes[37] == 0x0c then
            streams["auto_throw"] = 1
            streams["throw_percent"] = 0
        else
            streams["auto_throw"] = 0
        end
    end
    if bodyBytes[38] ~= nil then streams["app_flag"] = bodyBytes[38] end
    if bodyBytes[39] ~= nil then streams["cloud_program_id"] = bodyBytes[39] end
    if bodyBytes[46] ~= nil and bodyBytes[47] ~= nil then
        local cruVersionHigh = string.format("%u", bodyBytes[46]);
        if (#cruVersionHigh == 1) then
            cruVersionHigh = "0" .. cruVersionHigh;
        else
            cruVersionHigh = string.sub(cruVersionHigh, 1, 1) .. "." ..
                                 string.sub(cruVersionHigh, 2, 2)
        end
        local curVersionLow = string.format("%u", bodyBytes[47]);
        if (#curVersionLow == 1) then
            curVersionLow = "0" .. curVersionLow;
        end
        streams["cur_firmware_version"] = cruVersionHigh .. "." .. curVersionLow;
    end
    if bodyBytes[48] ~= nil and bodyBytes[49] ~= nil then
        local upgradeVersionHigh = string.format("%u", bodyBytes[48]);
        if (#upgradeVersionHigh == 1) then
            upgradeVersionHigh = "0" .. upgradeVersionHigh;
        else
            upgradeVersionHigh = string.sub(upgradeVersionHigh, 1, 1) .. "." ..
                                     string.sub(upgradeVersionHigh, 2, 2)
        end
        local upgradeVersionLow = string.format("%u", bodyBytes[49]);
        if (#upgradeVersionLow == 1) then
            upgradeVersionLow = "0" .. upgradeVersionLow;
        end
        streams["upgrade_firmware_version"] =
            upgradeVersionHigh .. "." .. upgradeVersionLow;
    end
    if bodyBytes[50] ~= nil then streams["firmware_state"] = bodyBytes[50]; end
    if bodyBytes[51] ~= nil then
        streams["firmware_upgrade_progress"] = bodyBytes[51];
    end
    if bodyBytes[52] ~= nil then
        streams["voice_inside_volumn"] = bodyBytes[52];
    end
    if bodyBytes[53] ~= nil then
        streams["voice_inside_mic_on"] = bodyBytes[53];
    end
    retTable["status"] = streams
    return encodeTableToJson(retTable)
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local json = decodeJsonToTable(jsonCmdStr)
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    local msgBytes = {}
    if (control) then
        local bodyLength = 38
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        updateDataByJson(control, bodyBytes)
        msgBytes = assembleUart(bodyBytes, 0x02)
    elseif (query) then
        local bodyLength = 1
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        msgBytes = assembleUart(bodyBytes, 0x03)
    end
    return table2hex(msgBytes)
end
function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decodeJsonToTable(jsonStr)
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local ret = updateJsonByData(binData)
    return ret
end
