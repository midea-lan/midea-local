local bit = require "bit"
local uptable = {}
uptable["VALUE_VERSION"] = 20
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
uptable["KEY_VERSION"] = "version"
uptable["KEY_WORK_STATUS"] = "work_status"
uptable["KEY_MODE"] = "mode"
uptable["KEY_LOCK"] = "lock"
uptable["KEY_LEFT_TIME"] = "left_time"
uptable["KEY_OPERATOR"] = "operator"
uptable["KEY_WASH_STAGE"] = "wash_stage"
uptable["KEY_ERROR_CODE"] = "error_code"
uptable["KEY_TEMPERATURE"] = "temperature"
uptable["KEY_WRONG_OPERATION"] = "wrong_operation"
uptable["KEY_SOFTWATER"] = "softwater"
uptable["KEY_BRIGHT"] = "bright"
uptable["KEY_AIRSWITCH"] = "airswitch"
uptable["KEY_AIR_STATUS"] = "air_status"
uptable["KEY_AIR_SET_HOUR"] = "air_set_hour"
uptable["KEY_AIR_LEFT_HOUR"] = "air_left_hour"
uptable["KEY_DOORSWITCH"] = "doorswitch"
uptable["KEY_BASKETSWITCH"] = "basketswitch"
uptable["KEY_DIY_TIMES"] = "diy_times"
uptable["KEY_DIY_MAIN_WASH"] = "diy_main_wash"
uptable["KEY_DIY_PIAO_WASH"] = "diy_piao_wash"
uptable["KEY_ORDER_SET_HOUR"] = "order_set_hour"
uptable["KEY_ORDER_SET_MIN"] = "order_set_min"
uptable["KEY_ORDER_LEFT_HOUR"] = "order_left_hour"
uptable["KEY_ORDER_LEFT_MIN"] = "order_left_min"
uptable["KEY_WORK_TIME"] = "work_time"
uptable["KEY_DEVICE_VERSION"] = "device_version"
uptable["KEY_ADDITIONAL"] = "additional"
uptable["KEY_WATER_LEVEL"] = "water_level"
uptable["KEY_WATER_STRONG_LEVEL"] = "water_strong_level"
uptable["KEY_DRYSWITCH"] = "dryswitch"
uptable["KEY_WATERSWITCH"] = "waterswitch"
uptable["KEY_SOFTWATER_LACK"] = "softwater_lack"
uptable["KEY_BRIGHT_LACK"] = "bright_lack"
uptable["KEY_DIY_FLAG"] = "diy_flag"
uptable["KEY_WATER_LACK"] = "water_lack"
uptable["KEY_MSG_TYPE"] = "msg_type"
uptable["KEY_UVSWITCH"] = "uvswitch"
uptable["KEY_DRY_STEP_SWITCH"] = "dry_step_switch"
uptable["KEY_HUMIDITY"] = "humidity"
uptable["KEY_DRY_SET_MIN"] = "dry_set_min"
uptable["KEY_CMD_CLOUD"] = "cmd_cloud"
uptable["KEY_OTA_VERSION"] = "ota_version"
uptable["KEY_APP_FLAG"] = "app_flag"
uptable["KEY_CLOUD_PROGRAM_ID"] = "cloud_program_id"
uptable["VALUE_ON"] = "on"
uptable["VALUE_OFF"] = "off"
uptable["VALUE_WORK_STATUS_POWER_ON"] = "power_on"
uptable["VALUE_WORK_STATUS_POWER_OFF"] = "power_off"
uptable["VALUE_WORK_STATUS_CANCEL"] = "cancel"
uptable["VALUE_WORK_STATUS_WORK"] = "work"
uptable["VALUE_WORK_STATUS_ORDER"] = "order"
uptable["VALUE_WORK_STATUS_CANCEL_ORDER"] = "cancel_order"
uptable["VALUE_WORK_STATUS_ERROR"] = "error"
uptable["VALUE_MODE_NEUTRAL_GEAR"] = "neutral_gear"
uptable["VALUE_MODE_AUTO_WASH"] = "auto_wash"
uptable["VALUE_MODE_STRONG_WASH"] = "strong_wash"
uptable["VALUE_MODE_STANDARD_WASH"] = "standard_wash"
uptable["VALUE_MODE_ECO_WASH"] = "eco_wash"
uptable["VALUE_MODE_GLASS_WASH"] = "glass_wash"
uptable["VALUE_MODE_HOUR_WASH"] = "hour_wash"
uptable["VALUE_MODE_FAST_WASH"] = "fast_wash"
uptable["VALUE_MODE_SOAK_WASH"] = "soak_wash"
uptable["VALUE_MODE_90MIN_WASH"] = "90min_wash"
uptable["VALUE_MODE_SELF_CLEAN"] = "self_clean"
uptable["VALUE_MODE_FRUIT_WASH"] = "fruit_wash"
uptable["VALUE_MODE_SELF_DEFINE"] = "self_define"
uptable["VALUE_MODE_GERM"] = "germ"
uptable["VALUE_MODE_BOWL_WASH"] = "bowl_wash"
uptable["VALUE_MODE_KILL_GERM"] = "kill_germ"
uptable["VALUE_MODE_SEA_FOOD_WASH"] = "seafood_wash"
uptable["VALUE_MODE_HOT_POT_WASH"] = "hotpot_wash"
uptable["VALUE_MODE_QUIET_NIGHT_WASH"] = "quietnight_wash"
uptable["VALUE_MODE_LESS_WASH"] = "less_wash"
uptable["VALUE_MODE_CLOUD_WASH"] = "cloud_wash"
uptable["VALUE_OPERATOR_START"] = "start"
uptable["VALUE_OPERATOR_PAUSE"] = "pause"
uptable["VALUE_UNKNOWN"] = "unknown"
uptable["VALUE_INVALID"] = "invalid"
uptable["BYTE_DEVICE_TYPE"] = 0xE1
uptable["BYTE_CONTROL_REQUEST"] = 0x02
uptable["BYTE_QUERY_REQUEST"] = 0x03
uptable["BYTE_PROTOCOL_HEAD"] = 0xAA
uptable["BYTE_PROTOCOL_LENGTH"] = 0x0A
uptable["BYTE_STATUS_POWER_ON"] = 0x01
uptable["BYTE_STATUS_POWER_OFF"] = 0x00
uptable["BYTE_STATUS_CANCEL"] = 0x01
uptable["BYTE_STATUS_WORK"] = 0x03
uptable["BYTE_STATUS_ORDER"] = 0x02
uptable["BYTE_STATUS_CANCEL_ORDER"] = 0x04
uptable["BYTE_MODE_NEUTRAL_GEAR"] = 0x00
uptable["BYTE_MODE_AUTO_WASH"] = 0x01
uptable["BYTE_MODE_STRONG_WASH"] = 0x02
uptable["BYTE_MODE_STANDARD_WASH"] = 0x03
uptable["BYTE_MODE_ECO_WASH"] = 0x04
uptable["BYTE_MODE_GLASS_WASH"] = 0x05
uptable["BYTE_MODE_HOUR_WASH"] = 0x06
uptable["BYTE_MODE_FAST_WASH"] = 0x07
uptable["BYTE_MODE_SOAK_WASH"] = 0x08
uptable["BYTE_MODE_90MIN_WASH"] = 0x09
uptable["BYTE_MODE_SELF_CLEAN"] = 0x0a
uptable["BYTE_MODE_FRUIT_WASH"] = 0x0b
uptable["BYTE_MODE_SELF_DEFINE"] = 0x0c
uptable["BYTE_MODE_GERM"] = 0x0D
uptable["BYTE_MODE_BOWL_WASH"] = 0x0e
uptable["BYTE_MODE_KILL_GERM"] = 0x0f
uptable["BYTE_MODE_SEA_FOOD_WASH"] = 0x10
uptable["BYTE_MODE_HOT_POT_WASH"] = 0x12
uptable["BYTE_MODE_QUIET_NIGHT_WASH"] = 0x13
uptable["BYTE_MODE_LESS_WASH"] = 0x14
uptable["BYTE_MODE_CLOUD_WASH"] = 0x19
local function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do msgBytes[i - 1] = byteData[i] end
    local bodyLength = msgLength - uptable["BYTE_PROTOCOL_LENGTH"] - 1
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]]
    end
    return bodyBytes
end
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if bodyLength == 0 then return nil end
    local msgLength = (bodyLength + uptable["BYTE_PROTOCOL_LENGTH"] + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = uptable["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = msgLength - 1
    msgBytes[2] = uptable["BYTE_DEVICE_TYPE"]
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do
        msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]] = bodyBytes[i]
    end
    msgBytes[msgLength - 1] = makeSum(msgBytes, 1, msgLength - 2)
    local msgBytesTemp = {}
    local length = #msgBytes + 1
    for i = 1, length do msgBytesTemp[i] = msgBytes[i - 1] end
    return msgBytesTemp
end
local function updateDataByJson(luaTable, bodyBytes)
    if luaTable[uptable["KEY_LOCK"]] ~= nil then
        bodyBytes[0] = 0x83
        if luaTable[uptable["KEY_LOCK"]] == uptable["VALUE_ON"] then
            bodyBytes[1] = 0x03
        elseif luaTable[uptable["KEY_LOCK"]] == uptable["VALUE_OFF"] then
            bodyBytes[1] = 0x04
        end
    elseif luaTable[uptable["KEY_OPERATOR"]] ~= nil and
        luaTable[uptable["KEY_OPERATOR"]] ~= "" then
        bodyBytes[0] = 0x83
        if luaTable[uptable["KEY_OPERATOR"]] == uptable["VALUE_OPERATOR_START"] then
            bodyBytes[1] = 0x01
        elseif luaTable[uptable["KEY_OPERATOR"]] ==
            uptable["VALUE_OPERATOR_PAUSE"] then
            bodyBytes[1] = 0x02
        end
    elseif luaTable[uptable["KEY_SOFTWATER"]] ~= nil then
        bodyBytes[0] = 0x80
        bodyBytes[1] = luaTable[uptable["KEY_SOFTWATER"]]
    elseif luaTable[uptable["KEY_BRIGHT"]] ~= nil then
        bodyBytes[0] = 0x84
        bodyBytes[1] = luaTable[uptable["KEY_BRIGHT"]]
    elseif luaTable[uptable["KEY_AIRSWITCH"]] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = luaTable[uptable["KEY_AIRSWITCH"]]
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = 0xff
        bodyBytes[8] = 0xff
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
    elseif luaTable[uptable["KEY_DRYSWITCH"]] ~= nil or
        luaTable[uptable["KEY_DRY_SET_MIN"]] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = 0xff
        bodyBytes[8] = 0xff
        if luaTable[uptable["KEY_DRYSWITCH"]] == nil then
            bodyBytes[9] = 0xff
        else
            bodyBytes[9] = luaTable[uptable["KEY_DRYSWITCH"]]
        end
        if luaTable[uptable["KEY_DRY_SET_MIN"]] == nil then
            bodyBytes[10] = 0xff
        else
            bodyBytes[10] = luaTable[uptable["KEY_DRY_SET_MIN"]]
        end
    elseif luaTable[uptable["KEY_WATERSWITCH"]] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = 0xff
        bodyBytes[8] = luaTable[uptable["KEY_WATERSWITCH"]]
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
    elseif luaTable[uptable["KEY_UVSWITCH"]] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = 0xff
        bodyBytes[7] = luaTable[uptable["KEY_UVSWITCH"]]
        bodyBytes[8] = 0xff
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
    elseif luaTable[uptable["KEY_DRY_STEP_SWITCH"]] ~= nil then
        bodyBytes[0] = 0x81
        bodyBytes[4] = 0xff
        bodyBytes[5] = 0xff
        bodyBytes[6] = luaTable[uptable["KEY_DRY_STEP_SWITCH"]]
        bodyBytes[7] = 0xff
        bodyBytes[8] = 0xff
        bodyBytes[9] = 0xff
        bodyBytes[10] = 0xff
    elseif luaTable[uptable["KEY_AIR_SET_HOUR"]] ~= nil then
        bodyBytes[0] = 0x86
        bodyBytes[1] = luaTable[uptable["KEY_AIR_SET_HOUR"]]
    elseif luaTable[uptable["KEY_DIY_TIMES"]] ~= nil then
        local diy_times, diy_main_wash, diy_piao_wash = 0x00
        diy_times = luaTable[uptable["KEY_DIY_TIMES"]]
        if (luaTable[uptable["KEY_DIY_MAIN_WASH"]] ~= nil) then
            diy_main_wash = luaTable[uptable["KEY_DIY_MAIN_WASH"]]
        end
        if (luaTable[uptable["KEY_DIY_PIAO_WASH"]] ~= nil) then
            diy_piao_wash = luaTable[uptable["KEY_DIY_PIAO_WASH"]]
        end
        bodyBytes[0] = 0x82
        bodyBytes[1] = diy_times
        bodyBytes[3] = diy_main_wash
        bodyBytes[5] = diy_piao_wash
    elseif luaTable[uptable["KEY_CMD_CLOUD"]] ~= nil then
        local array = split(luaTable[uptable["KEY_CMD_CLOUD"]], ",")
        for i = 1, #array do bodyBytes[i - 1] = tonumber(array[i], 16) end
    else
        local workStatus = 0x00
        if luaTable[uptable["KEY_WORK_STATUS"]] ==
            uptable["VALUE_WORK_STATUS_POWER_ON"] then
            workStatus = uptable["BYTE_STATUS_POWER_ON"]
        elseif luaTable[uptable["KEY_WORK_STATUS"]] ==
            uptable["VALUE_WORK_STATUS_POWER_OFF"] then
            workStatus = uptable["BYTE_STATUS_POWER_OFF"]
        elseif luaTable[uptable["KEY_WORK_STATUS"]] ==
            uptable["VALUE_WORK_STATUS_CANCEL"] then
            workStatus = uptable["BYTE_STATUS_CANCEL"]
        elseif luaTable[uptable["KEY_WORK_STATUS"]] ==
            uptable["VALUE_WORK_STATUS_WORK"] then
            workStatus = uptable["BYTE_STATUS_WORK"]
        elseif luaTable[uptable["KEY_WORK_STATUS"]] ==
            uptable["VALUE_WORK_STATUS_ORDER"] then
            workStatus = uptable["BYTE_STATUS_ORDER"]
        elseif luaTable[uptable["KEY_WORK_STATUS"]] ==
            uptable["VALUE_WORK_STATUS_CANCEL_ORDER"] then
            workStatus = uptable["BYTE_STATUS_CANCEL_ORDER"]
        end
        local mode = 0x00
        if luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_NEUTRAL_GEAR"] then
            mode = uptable["BYTE_MODE_NEUTRAL_GEAR"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_AUTO_WASH"] then
            mode = uptable["BYTE_MODE_AUTO_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] ==
            uptable["VALUE_MODE_STRONG_WASH"] then
            mode = uptable["BYTE_MODE_STRONG_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] ==
            uptable["VALUE_MODE_STANDARD_WASH"] then
            mode = uptable["BYTE_MODE_STANDARD_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_ECO_WASH"] then
            mode = uptable["BYTE_MODE_ECO_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_GLASS_WASH"] then
            mode = uptable["BYTE_MODE_GLASS_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_HOUR_WASH"] then
            mode = uptable["BYTE_MODE_HOUR_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_FAST_WASH"] then
            mode = uptable["BYTE_MODE_FAST_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_SOAK_WASH"] then
            mode = uptable["BYTE_MODE_SOAK_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_90MIN_WASH"] then
            mode = uptable["BYTE_MODE_90MIN_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_SELF_CLEAN"] then
            mode = uptable["BYTE_MODE_SELF_CLEAN"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_FRUIT_WASH"] then
            mode = uptable["BYTE_MODE_FRUIT_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] ==
            uptable["VALUE_MODE_SELF_DEFINE"] then
            mode = uptable["BYTE_MODE_SELF_DEFINE"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_GERM"] then
            mode = uptable["BYTE_MODE_GERM"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_BOWL_WASH"] then
            mode = uptable["BYTE_MODE_BOWL_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_KILL_GERM"] then
            mode = uptable["BYTE_MODE_KILL_GERM"]
        elseif luaTable[uptable["KEY_MODE"]] ==
            uptable["VALUE_MODE_SEA_FOOD_WASH"] then
            mode = uptable["BYTE_MODE_SEA_FOOD_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] ==
            uptable["VALUE_MODE_HOT_POT_WASH"] then
            mode = uptable["BYTE_MODE_HOT_POT_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] ==
            uptable["VALUE_MODE_QUIET_NIGHT_WASH"] then
            mode = uptable["BYTE_MODE_QUIET_NIGHT_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_LESS_WASH"] then
            mode = uptable["BYTE_MODE_LESS_WASH"]
        elseif luaTable[uptable["KEY_MODE"]] == uptable["VALUE_MODE_CLOUD_WASH"] then
            mode = uptable["BYTE_MODE_CLOUD_WASH"]
        else
            if workStatus == uptable["BYTE_STATUS_WORK"] then
                mode = uptable["BYTE_MODE_ECO_WASH"]
            end
        end
        local additional = 0x00
        if luaTable[uptable["KEY_ADDITIONAL"]] ~= nil then
            additional = luaTable[uptable["KEY_ADDITIONAL"]]
        end
        bodyBytes[0] = 0x08
        bodyBytes[1] = workStatus
        bodyBytes[2] = mode
        bodyBytes[3] = additional
        if (workStatus == 0x02) then
            local orderSetTime = 0x00
            if luaTable[uptable["KEY_ORDER_SET_HOUR"]] ~= nil and
                luaTable[uptable["KEY_ORDER_SET_MIN"]] ~= nil then
                orderSetTime = luaTable[uptable["KEY_ORDER_SET_HOUR"]] * 60 +
                                   luaTable[uptable["KEY_ORDER_SET_MIN"]]
            end
            bodyBytes[7] = math.modf(orderSetTime / 60)
            bodyBytes[8] = math.fmod(orderSetTime, 60)
        end
        if (mode == 0x0f) then
            if luaTable[uptable["KEY_WORK_TIME"]] ~= nil then
                bodyBytes[10] = luaTable[uptable["KEY_WORK_TIME"]]
            end
        end
        if luaTable[uptable["KEY_WATER_LEVEL"]] ~= nil then
            bodyBytes[11] = luaTable[uptable["KEY_WATER_LEVEL"]]
        end
        if luaTable[uptable["KEY_WATER_STRONG_LEVEL"]] ~= nil then
            bodyBytes[12] = luaTable[uptable["KEY_WATER_STRONG_LEVEL"]]
        end
    end
end
local function updateJsonByData(binData)
    local byteData = string2table(binData)
    local bodyBytes = extractBodyBytes(byteData)
    local retTable = {}
    local streams = {}
    streams[uptable["KEY_VERSION"]] = uptable["VALUE_VERSION"]
    streams["cmd"] = binData
    local dataType = byteData[10]
    streams[uptable["KEY_MSG_TYPE"]] = dataType
    if (dataType ~= 0x02 and dataType ~= 0x03 and dataType ~= 0x04) then
        retTable["status"] = streams
        return encodeTableToJson(retTable)
    end
    local workStatus = bodyBytes[1]
    if workStatus == uptable["BYTE_STATUS_POWER_OFF"] then
        streams[uptable["KEY_WORK_STATUS"]] =
            uptable["VALUE_WORK_STATUS_POWER_OFF"]
    elseif workStatus == uptable["BYTE_STATUS_CANCEL"] then
        streams[uptable["KEY_WORK_STATUS"]] =
            uptable["VALUE_WORK_STATUS_CANCEL"]
    elseif workStatus == uptable["BYTE_STATUS_WORK"] then
        streams[uptable["KEY_WORK_STATUS"]] = uptable["VALUE_WORK_STATUS_WORK"]
    elseif workStatus == uptable["BYTE_STATUS_ORDER"] then
        streams[uptable["KEY_WORK_STATUS"]] = uptable["VALUE_WORK_STATUS_ORDER"]
    elseif workStatus == 0x04 then
        streams[uptable["KEY_WORK_STATUS"]] = uptable["VALUE_WORK_STATUS_ERROR"]
    elseif workStatus == 0x05 then
        streams[uptable["KEY_WORK_STATUS"]] =
            uptable["VALUE_WORK_STATUS_SOFT_GEAR"]
    else
    end
    local mode = bodyBytes[2]
    if mode == uptable["BYTE_MODE_NEUTRAL_GEAR"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_NEUTRAL_GEAR"]
    elseif mode == uptable["BYTE_MODE_AUTO_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_AUTO_WASH"]
    elseif mode == uptable["BYTE_MODE_STRONG_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_STRONG_WASH"]
    elseif mode == uptable["BYTE_MODE_STANDARD_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_STANDARD_WASH"]
    elseif mode == uptable["BYTE_MODE_ECO_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_ECO_WASH"]
    elseif mode == uptable["BYTE_MODE_GLASS_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_GLASS_WASH"]
    elseif mode == uptable["BYTE_MODE_HOUR_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_HOUR_WASH"]
    elseif mode == uptable["BYTE_MODE_FAST_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_FAST_WASH"]
    elseif mode == uptable["BYTE_MODE_SOAK_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_SOAK_WASH"]
    elseif mode == uptable["BYTE_MODE_90MIN_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_90MIN_WASH"]
    elseif mode == uptable["BYTE_MODE_SELF_CLEAN"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_SELF_CLEAN"]
    elseif mode == uptable["BYTE_MODE_FRUIT_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_FRUIT_WASH"]
    elseif mode == uptable["BYTE_MODE_SELF_DEFINE"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_SELF_DEFINE"]
    elseif mode == uptable["BYTE_MODE_GERM"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_GERM"]
    elseif mode == uptable["BYTE_MODE_BOWL_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_BOWL_WASH"]
    elseif mode == uptable["BYTE_MODE_KILL_GERM"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_KILL_GERM"]
        if bodyBytes[29] ~= nil then
            streams[uptable["KEY_WORK_TIME"]] = bodyBytes[29]
        end
    elseif mode == uptable["BYTE_MODE_SEA_FOOD_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_SEA_FOOD_WASH"]
    elseif mode == uptable["BYTE_MODE_HOT_POT_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_HOT_POT_WASH"]
    elseif mode == uptable["BYTE_MODE_QUIET_NIGHT_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_QUIET_NIGHT_WASH"]
    elseif mode == uptable["BYTE_MODE_LESS_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_LESS_WASH"]
    elseif mode == uptable["BYTE_MODE_CLOUD_WASH"] then
        streams[uptable["KEY_MODE"]] = uptable["VALUE_MODE_CLOUD_WASH"]
    else
        streams[uptable["KEY_MODE"]] = uptable["VALUE_INVALID"]
    end
    local additional = bodyBytes[3]
    if (additional ~= 0) then streams["additional"] = additional end
    local lackbright = (bit_band(bodyBytes[5], 0x02) == 0x02)
    if lackbright then
        streams[uptable["KEY_BRIGHT_LACK"]] = 1
    else
        streams[uptable["KEY_BRIGHT_LACK"]] = 0
    end
    local lacksoftwater = (bit_band(bodyBytes[5], 0x04) == 0x04)
    if lacksoftwater then
        streams[uptable["KEY_SOFTWATER_LACK"]] = 1
    else
        streams[uptable["KEY_SOFTWATER_LACK"]] = 0
    end
    local diyflag = (bit_band(bodyBytes[4], 0x08) == 0x08)
    if diyflag then
        streams[uptable["KEY_DIY_FLAG"]] = 1
    else
        streams[uptable["KEY_DIY_FLAG"]] = 0
    end
    local lock = bit_band(bodyBytes[5], 0x10)
    if (lock == 0x10) then
        streams[uptable["KEY_LOCK"]] = uptable["VALUE_ON"]
    else
        streams[uptable["KEY_LOCK"]] = uptable["VALUE_OFF"]
    end
    local operator = bit_band(bodyBytes[5], 0x08)
    if operator == 0x08 then
        streams[uptable["KEY_OPERATOR"]] = uptable["VALUE_OPERATOR_START"]
    elseif workStatus == uptable["BYTE_STATUS_WORK"] then
        streams[uptable["KEY_OPERATOR"]] = uptable["VALUE_OPERATOR_PAUSE"]
    elseif workStatus == uptable["BYTE_STATUS_ORDER"] then
        streams[uptable["KEY_OPERATOR"]] = uptable["VALUE_OPERATOR_PAUSE"]
    else
        streams[uptable["KEY_OPERATOR"]] = ""
    end
    local leftTime = bodyBytes[6]
    if bodyBytes[32] ~= nil then
        local leftTimeHigh = bodyBytes[32]
        streams[uptable["KEY_LEFT_TIME"]] = leftTimeHigh * 256 + leftTime
    else
        streams[uptable["KEY_LEFT_TIME"]] = leftTime
    end
    local washStage = bodyBytes[9]
    streams[uptable["KEY_WASH_STAGE"]] = washStage
    local errorCode = bodyBytes[10]
    streams[uptable["KEY_ERROR_CODE"]] = errorCode
    local temperature = bodyBytes[11]
    streams[uptable["KEY_TEMPERATURE"]] = temperature
    local softwater = bodyBytes[13]
    streams[uptable["KEY_SOFTWATER"]] = softwater
    local wrongOperation = bodyBytes[16]
    streams[uptable["KEY_WRONG_OPERATION"]] = wrongOperation
    local airswitch = (bit_band(bodyBytes[5], 0x20) == 0x20)
    local airStatus = (bit_band(bodyBytes[5], 0x40) == 0x40)
    local airSetTime = bodyBytes[17]
    local airLeftTime = bodyBytes[18]
    if airswitch then
        streams[uptable["KEY_AIRSWITCH"]] = 1
    else
        streams[uptable["KEY_AIRSWITCH"]] = 0
    end
    if airStatus then
        streams[uptable["KEY_AIR_STATUS"]] = 1
    else
        streams[uptable["KEY_AIR_STATUS"]] = 0
    end
    streams[uptable["KEY_AIR_SET_HOUR"]] = airSetTime
    streams[uptable["KEY_AIR_LEFT_HOUR"]] = airLeftTime
    local doorswitch = (bit_band(bodyBytes[5], 0x01) == 0x01)
    if doorswitch then
        streams[uptable["KEY_DOORSWITCH"]] = 1
    else
        streams[uptable["KEY_DOORSWITCH"]] = 0
    end
    local dryswitch = (bit_band(bodyBytes[4], 0x10) == 0x10)
    local drystatus = (bit_band(bodyBytes[4], 0x20) == 0x20)
    if drystatus then
        streams[uptable["KEY_DRYSWITCH"]] = 2
    elseif dryswitch then
        streams[uptable["KEY_DRYSWITCH"]] = 1
    else
        streams[uptable["KEY_DRYSWITCH"]] = 0
    end
    local waterswitch = (bit_band(bodyBytes[4], 0x04) == 0x04)
    if waterswitch then
        streams[uptable["KEY_WATERSWITCH"]] = 1
    else
        streams[uptable["KEY_WATERSWITCH"]] = 0
    end
    if (workStatus == 0x02) then
        local orderSetTime = bodyBytes[19] * 60 + bodyBytes[20]
        local orderLeftTime = bodyBytes[7] * 60 + bodyBytes[8]
        streams[uptable["KEY_ORDER_SET_HOUR"]] = math.modf(orderSetTime / 60)
        streams[uptable["KEY_ORDER_SET_MIN"]] = math.fmod(orderSetTime, 60)
        streams[uptable["KEY_ORDER_LEFT_HOUR"]] = math.modf(orderLeftTime / 60)
        streams[uptable["KEY_ORDER_LEFT_MIN"]] = math.fmod(orderLeftTime, 60)
    else
        streams[uptable["KEY_DIY_TIMES"]] = bodyBytes[19]
        streams[uptable["KEY_DIY_MAIN_WASH"]] = bodyBytes[21]
        streams[uptable["KEY_DIY_PIAO_WASH"]] = bodyBytes[23]
    end
    if bodyBytes[24] ~= nil then
        streams[uptable["KEY_BRIGHT"]] = bodyBytes[24]
    end
    if bodyBytes[28] ~= nil then
        streams[uptable["KEY_DEVICE_VERSION"]] = bodyBytes[28]
    end
    if bodyBytes[31] ~= nil then
        streams[uptable["KEY_WATER_LEVEL"]] = bodyBytes[30]
        streams[uptable["KEY_WATER_STRONG_LEVEL"]] = bodyBytes[31]
    end
    local water_lack = (bit_band(bodyBytes[5], 0x80) == 0x80)
    if water_lack then
        streams[uptable["KEY_WATER_LACK"]] = 1
    else
        streams[uptable["KEY_WATER_LACK"]] = 0
    end
    local dry_step_switch = (bit_band(bodyBytes[4], 0x01) == 0x01)
    if dry_step_switch then
        streams[uptable["KEY_DRY_STEP_SWITCH"]] = 0
    else
        streams[uptable["KEY_DRY_STEP_SWITCH"]] = 1
    end
    local uvswitch = (bit_band(bodyBytes[4], 0x02) == 0x02)
    if uvswitch then
        streams[uptable["KEY_UVSWITCH"]] = 1
    else
        streams[uptable["KEY_UVSWITCH"]] = 0
    end
    if bodyBytes[33] ~= nil then
        streams[uptable["KEY_HUMIDITY"]] = bodyBytes[33]
    end
    if bodyBytes[34] ~= nil then
        streams[uptable["KEY_DRY_SET_MIN"]] = bodyBytes[34]
    end
    if bodyBytes[36] ~= nil then
        streams[uptable["KEY_OTA_VERSION"]] = bodyBytes[36]
    end
    if bodyBytes[38] ~= nil then
        streams[uptable["KEY_APP_FLAG"]] = bodyBytes[38]
    end
    if bodyBytes[39] ~= nil then
        streams[uptable["KEY_CLOUD_PROGRAM_ID"]] = bodyBytes[39]
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
        msgBytes = assembleUart(bodyBytes, uptable["BYTE_CONTROL_REQUEST"])
    elseif (query) then
        local bodyLength = 1
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        msgBytes = assembleUart(bodyBytes, uptable["BYTE_QUERY_REQUEST"])
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
