local JSON = require "cjson"
local VALUE_VERSION = 2
local no_schedule_order_time = 0
local JSON_KEY_TAB = {
    KEY_VERSION = "version",
    KEY_WORK_STATUS = "work_status",
    KEY_MODE = "mode",
    KEY_CMD_CODE = "cmd_code",
    KEY_MOUTHFEEL = "mouthfeel",
    KEY_RICE_TYPE = "rice_type",
    KEY_ERROR_CODE = "error_code",
    KEY_ORDER_TIME_HOUR = "order_time_hour",
    KEY_ORDER_TIME_MIN = "order_time_min",
    KEY_LEFT_TIME_HOUR = "left_time_hour",
    KEY_LEFT_TIME_MIN = "left_time_min",
    KEY_WARM_TIME_HOUR = "warm_time_hour",
    KEY_WARM_TIME_MIN = "warm_time_min",
    KEY_VOLTAGE = "voltage",
    KEY_INDOOR_TEMPERATURE = "indoor_temperature",
    KEY_TOP_TEMPERATURE = "top_temperature",
    KEY_BOTTOM_TEMPERATURE = "bottom_temperature",
    KEY_WORK_STAGE = "work_stage",
    KEY_WORK_FLAG = "work_flag",
    KEY_RICE_LEVEL = "rice_level",
    KEY_CONTROL_SRC = "control_src"
}

local VALUE_WORK_STATUS_KEEP_WARM = "keep_warm"
local VALUE_WORK_STATUS_SCHEDULE = "schedule"
local VALUE_BYTE_COOKING = "cooking"
local VALUE_BYTE_CANCEL = "cancel"
local VALUE_BYTE_AWAKENING_RICE = "awakening_rice"
local VALUE_WORK_MODE_TAB = {
    "reserve",
    "cook_rice",
    "fast_cook_rice",
    "standard_cook_rice",
    "gruel",
    "cook_congee",
    "stew_soup",
    "stewing",
    "heat_rice",
    "make_cake",
    "yoghourt",
    "soup_rice",
    "coarse_rice",
    "five_ceeals_rice",
    "eight_treasures_rice",
    "crispy_rice",
    "shelled_rice",
    "eight_treasures_congee",
    "infant_congee",
    "older_rice",
    "rice_soup",
    "rice_paste",
    "egg_custard",
    "warm_milk",
    "hot_spring_egg",
    "millet_congee",
    "firewood_rice",
    "few_rice",
    "red_potato",
    "corn",
    "quick_freeze_bun",
    "steam_ribs",
    "steam_egg",
    "coarse_congee",
    "steep_rice",
    "appetizing_congee",
    "corn_congee",
    "sprout_rice",
    "luscious_rice",
    "luscious_boiled",
    "fast_rice",
    "fast_boil",
    "bean_rice_congee",
    "fast_congee",
    "baby_congee",
    "cook_soup",
    "congee_coup",
    "steam_corn",
    "steam_red_potato",
    "boil_congee",
    "delicious_steam",
    "boil_egg",
    "rice_wine",
    "fruit_vegetable_paste",
    "vegetable_porridge",
    "pork_porridge",
    "fragrant_rice",
    "assorte_rice",
    "steame_fish",
    "baby_rice",
    "essence_rice",
    "fragrant_dense_congee",
    "one_two_cook",
    "original_steame",
    "hot_fast_rice",
    "online_celebrity_rice",
    "sushi_rice",
    "stone_bowl_rice",
    "no_water_treat",
    "keep_fresh",
    "low_sugar_rice",
    "black_buckwheat_rice",
    "resveratrol_rice",
    "yellow_wheat_rice",
    "green_buckwheat_rice",
    "roughage_rice",
    "millet_mixed_rice",
    "iron_pan_rice",
    "olla_pan_rice",
    "vegetable_rice",
    "baby_side",
    "regimen_congee",
    "earthen_pot_congee",
    "regimen_soup",
    "pottery_jar_soup",
    "canton_soup",
    "nutrition_stew",
    "northeast_stew",
    "uncap_boil",
    "trichromatic_coarse_grain",
    "four_color_vegetables",
    "egg",
    "chop",
    [192] = "clean",
    [198] = "keep_warm",
    [199] = "diy",
    [0] = "smart"
}
local VALUE_MOUTHFEEL_TAB = {"soft", "middle", "hard", [0] = "none"}
local VALUE_RICE_TYPE_TAB = {
    "northeast",
    "longrain",
    "fragrant",
    "five",
    [0] = "none"
}

local BYTE_DEVICE_TYPE = 0xEA
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_STATUS_KEEP_WARM = 0x03
local BYTE_SCHEDULE = 0x01
local BYTE_COOKING = 0x02
local BYTE_CANCEL = 0x00
local BYTE_AWAKENING_RICE = 0X04
local BYTE_MOUTHFEEL_NONE = 0x00
local BYTE_MOUTHFEEL_SOFT = 0x01
local BYTE_MOUTHFEEL_MIDDLE = 0x02
local BYTE_MOUTHFEEL_HARD = 0x03
local BYTE_RICE_TYPE_NONE = 0x00
local BYTE_RICE_TYPE_NORTHEAST = 0x01
local BYTE_RICE_TYPE_LONGRAIN = 0x02
local BYTE_RICE_TYPE_FRAGRANT = 0x03
local BYTE_RICE_TYPE_FIVE = 0x04

local workstatus = 0
local mode = 0
local mouthFeel = 0
local riceType = 0
local errorCode = 0
local orderHour = 0
local orderMin = 0
local leftHour = 0
local leftMin = 0
local warmHour = 0
local warmMin = 0
local voltage = 0
local indoorTemperature = 0
local topTemperature = 0
local bottomTemperature = 0
local workStage = 0
local workFlag = 0
local riceLevel = 0
local stepExpectTime = 0
local stepActualTime = 0
local init_order_time_hour = 0
local init_order_time_min = 0
local init_work_time_hour = 0
local init_work_time_min = 0
local pressure_state = 0
local control_src = 0
local dataType = 0

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

local function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = "0" end
    return data
end

local function string2Int(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end

local function tableMerge(tDest, tSrc)
    if tSrc.left_time_hour == nil then tSrc.left_time_hour = 0 end
    if tSrc.left_time_min == nil then tSrc.left_time_min = 0 end
    for k, v in pairs(tSrc) do tDest[k] = v end
end

local function splitStrByChar(str, sepChar)
    local splitList = {}
    local pattern = '[^' .. sepChar .. ']+'
    string.gsub(str, pattern, function(w) table.insert(splitList, w) end)
    return splitList
end

local function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do msgBytes[i - 1] = byteData[i] end
    local bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    return bodyBytes
end

local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
end

local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if #bodyBytes == 0 then return nil end
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[8] = 0x01
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    msgBytes[msgLength - 1] = makeSum(msgBytes, 1, msgLength - 2)
    return msgBytes
end

local function decode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end

local function encode(luaTable)
    local jsonStr
    if JSON == nil then JSON = require "cjson" end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
end

local function getPropertyStringByInteger(numberValue, tab)
    local workModeValue = tab[numberValue]
    if workModeValue == nil then workModeValue = int2String(numberValue) end
    return workModeValue
end

local function getPropertyIntegerByString(StringValue, tab)
    for key, value in pairs(tab) do
        if value == StringValue then return key end
    end
    return string2Int(StringValue)
end

local function getNoScheduleTime()
    if have_clock == true then
        return 255
    else
        return 0
    end
end

local function jsonToModel(luaTable)
    if (luaTable[JSON_KEY_TAB.KEY_WORK_STATUS] ~= nil) then
        if luaTable[JSON_KEY_TAB.KEY_WORK_STATUS] == VALUE_WORK_STATUS_KEEP_WARM then
            workstatus = BYTE_STATUS_KEEP_WARM
        elseif luaTable[JSON_KEY_TAB.KEY_WORK_STATUS] ==
            VALUE_WORK_STATUS_SCHEDULE then
            workstatus = BYTE_SCHEDULE
        elseif luaTable[JSON_KEY_TAB.KEY_WORK_STATUS] == VALUE_BYTE_COOKING then
            workstatus = BYTE_COOKING
        elseif luaTable[JSON_KEY_TAB.KEY_WORK_STATUS] == VALUE_BYTE_CANCEL then
            workstatus = BYTE_CANCEL
        elseif luaTable[JSON_KEY_TAB.KEY_WORK_STATUS] ==
            VALUE_BYTE_AWAKENING_RICE then
            workstatus = BYTE_AWAKENING_RICE
        else
            workstatus = string2Int(luaTable[JSON_KEY_TAB.KEY_WORK_STATUS])
        end
    end
    if (luaTable[JSON_KEY_TAB.KEY_CONTROL_SRC] ~= nil) then
        control_src = string2Int(luaTable[JSON_KEY_TAB.KEY_CONTROL_SRC])
    end
    if (luaTable[JSON_KEY_TAB.KEY_MODE] ~= nil) then
        mode = getPropertyIntegerByString(luaTable[JSON_KEY_TAB.KEY_MODE],
                                          VALUE_WORK_MODE_TAB)
    end
    if (luaTable[JSON_KEY_TAB.KEY_MOUTHFEEL] ~= nil) then
        mouthFeel = getPropertyIntegerByString(
                        luaTable[JSON_KEY_TAB.KEY_MOUTHFEEL],
                        VALUE_MOUTHFEEL_TAB)
    end
    if (luaTable[JSON_KEY_TAB.KEY_RICE_TYPE] ~= nil) then
        riceType = getPropertyIntegerByString(
                       luaTable[JSON_KEY_TAB.KEY_RICE_TYPE], VALUE_RICE_TYPE_TAB)
    end
    if luaTable[JSON_KEY_TAB.KEY_ORDER_TIME_HOUR] ~= nil then
        orderHour = string2Int(luaTable[JSON_KEY_TAB.KEY_ORDER_TIME_HOUR])
    else
        orderHour = 0
    end
    if luaTable[JSON_KEY_TAB.KEY_ORDER_TIME_MIN] ~= nil then
        orderMin = string2Int(luaTable[JSON_KEY_TAB.KEY_ORDER_TIME_MIN])
    else
        orderMin = 0
    end
    if luaTable[JSON_KEY_TAB.KEY_LEFT_TIME_HOUR] ~= nil then
        leftHour = string2Int(luaTable[JSON_KEY_TAB.KEY_LEFT_TIME_HOUR])
    else
        leftHour = 0
    end
    if luaTable[JSON_KEY_TAB.KEY_LEFT_TIME_MIN] ~= nil then
        leftMin = string2Int(luaTable[JSON_KEY_TAB.KEY_LEFT_TIME_MIN])
    else
        leftMin = 0
    end
end

local function binToModel(messageBytes)
    if (#messageBytes == 0) then return nil end
    if ((dataType == 0x02 and messageBytes[3] == 0x02) or
        (dataType == 0x03 and messageBytes[3] == 0x03) or
        (dataType == 0x04 and messageBytes[3] == 0x04)) then
        control_src = messageBytes[2]
        mode = messageBytes[4] + bit.lshift(messageBytes[5], 8)
        workstatus = messageBytes[8]
        errorCode = messageBytes[9]
        orderHour = messageBytes[10]
        orderMin = messageBytes[11]
        leftHour = messageBytes[12]
        leftMin = messageBytes[13]
        warmHour = messageBytes[22]
        warmMin = messageBytes[23]
        mouthFeel = messageBytes[14]
        riceType = messageBytes[15] + bit.lshift(messageBytes[16], 8)
        voltage = messageBytes[24] + bit.lshift(messageBytes[25], 8)
        indoorTemperature = messageBytes[26]
        topTemperature = messageBytes[20]
        bottomTemperature = messageBytes[21]
        workStage = messageBytes[19]
        workFlag = messageBytes[18]
        riceLevel = messageBytes[17]
        init_order_time_hour = messageBytes[27]
        init_order_time_min = messageBytes[28]
        init_work_time_hour = messageBytes[29]
        init_work_time_min = messageBytes[30]
        pressure_state = messageBytes[31]
        return 1
    end
end

local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[JSON_KEY_TAB.KEY_VERSION] = VALUE_VERSION
    if (workstatus == BYTE_STATUS_KEEP_WARM) then
        streams[JSON_KEY_TAB.KEY_WORK_STATUS] = VALUE_WORK_STATUS_KEEP_WARM
    elseif (workstatus == BYTE_SCHEDULE) then
        streams[JSON_KEY_TAB.KEY_WORK_STATUS] = VALUE_WORK_STATUS_SCHEDULE
    elseif workstatus == BYTE_COOKING then
        streams[JSON_KEY_TAB.KEY_WORK_STATUS] = VALUE_BYTE_COOKING
    elseif workstatus == BYTE_CANCEL then
        streams[JSON_KEY_TAB.KEY_WORK_STATUS] = VALUE_BYTE_CANCEL
    elseif workstatus == BYTE_AWAKENING_RICE then
        streams[JSON_KEY_TAB.KEY_WORK_STATUS] = VALUE_BYTE_AWAKENING_RICE
    else
        streams[JSON_KEY_TAB.KEY_WORK_STATUS] = int2String(workstatus)
    end
    streams[JSON_KEY_TAB.KEY_CONTROL_SRC] = int2String(control_src)
    streams[JSON_KEY_TAB.KEY_MODE] = getPropertyStringByInteger(mode,
                                                                VALUE_WORK_MODE_TAB)
    streams[JSON_KEY_TAB.KEY_CMD_CODE] = int2String(mode)
    streams[JSON_KEY_TAB.KEY_MOUTHFEEL] =
        getPropertyStringByInteger(mouthFeel, VALUE_MOUTHFEEL_TAB)
    streams[JSON_KEY_TAB.KEY_RICE_TYPE] =
        getPropertyStringByInteger(riceType, VALUE_RICE_TYPE_TAB)
    streams[JSON_KEY_TAB.KEY_ERROR_CODE] = errorCode
    streams[JSON_KEY_TAB.KEY_ORDER_TIME_HOUR] = orderHour
    streams[JSON_KEY_TAB.KEY_ORDER_TIME_MIN] = orderMin
    streams[JSON_KEY_TAB.KEY_LEFT_TIME_HOUR] = leftHour
    streams[JSON_KEY_TAB.KEY_LEFT_TIME_MIN] = leftMin
    streams[JSON_KEY_TAB.KEY_WARM_TIME_HOUR] = warmHour
    streams[JSON_KEY_TAB.KEY_WARM_TIME_MIN] = warmMin
    streams[JSON_KEY_TAB.KEY_VOLTAGE] = voltage
    streams[JSON_KEY_TAB.KEY_INDOOR_TEMPERATURE] = indoorTemperature
    streams[JSON_KEY_TAB.KEY_TOP_TEMPERATURE] = topTemperature
    streams[JSON_KEY_TAB.KEY_BOTTOM_TEMPERATURE] = bottomTemperature
    streams[JSON_KEY_TAB.KEY_WORK_STAGE] = workStage
    streams[JSON_KEY_TAB.KEY_RICE_LEVEL] = riceLevel
    streams[JSON_KEY_TAB.KEY_WORK_FLAG] = workFlag
    streams["cuisine_end"] = bit.band(bit.rshift(workFlag, 7), 0x01)
    streams["show_time"] = bit.band(bit.rshift(workFlag, 6), 0x01)
    streams["dry_braised"] = bit.band(bit.rshift(workFlag, 5), 0x01)
    streams["mat_rice"] = bit.band(bit.rshift(workFlag, 4), 0x01)
    streams["hot_cuisine"] = bit.band(bit.rshift(workFlag, 3), 0x01)
    streams["flank_hot"] = bit.band(bit.rshift(workFlag, 2), 0x01)
    streams["top_hot"] = bit.band(bit.rshift(workFlag, 1), 0x01)
    streams["bottom_hot"] = bit.band(workFlag, 0x01)
    if (stepExpectTime <= 1) then
        streams["step_expect_time"] = 1
    else
        streams["step_expect_time"] = stepExpectTime
    end
    streams["step_actual_time"] = stepActualTime
    streams["init_order_time_hour"] = init_order_time_hour
    streams["init_order_time_min"] = init_order_time_min
    streams["init_work_time_hour"] = init_work_time_hour
    streams["init_work_time_min"] = init_work_time_min
    if (pressure_state ~= nil) then
        if (pressure_state == 0) then
            streams["pressure_state"] = "inexistence"
        elseif (pressure_state == 1) then
            streams["pressure_state"] = "existence"
        else
            streams["pressure_state"] = int2String(pressure_state)
        end
    end
    return streams
end

local function getDiyCmd(control)
    local flag = 0
    local msgTx
    if control[JSON_KEY_TAB.KEY_MODE] == "diy" then
        msgTx = {
            0xAA, 0x78, 0xEA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0xAA,
            0x55, 0x01, 0x05, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        }
        if control[JSON_KEY_TAB.KEY_WORK_STATUS] == VALUE_BYTE_COOKING then
            msgTx[19] = 2
            msgTx[20] = no_schedule_order_time
            msgTx[21] = no_schedule_order_time
        elseif control[JSON_KEY_TAB.KEY_WORK_STATUS] ==
            VALUE_WORK_STATUS_SCHEDULE then
            msgTx[19] = 1
            msgTx[20] = string2Int(control[JSON_KEY_TAB.KEY_ORDER_TIME_HOUR])
            msgTx[21] = string2Int(control[JSON_KEY_TAB.KEY_ORDER_TIME_MIN])
        end
        if (control[JSON_KEY_TAB.KEY_MOUTHFEEL] ~= nil) then
            msgTx[24] = getPropertyIntegerByString(
                            control[JSON_KEY_TAB.KEY_MOUTHFEEL],
                            VALUE_MOUTHFEEL_TAB)
        end
        if (control[JSON_KEY_TAB.KEY_RICE_TYPE] ~= nil) then
            riceType = getPropertyIntegerByString(
                           control[JSON_KEY_TAB.KEY_RICE_TYPE],
                           VALUE_RICE_TYPE_TAB)
            msgTx[25] = bit.band(riceType, 0xFF)
            msgTx[26] = bit.band(bit.rshift(riceType, 8), 0xFF)
        end
        local steps = splitStrByChar(control["diy_params"], "|")
        msgTx[27] = #steps
        local totalWorkTime = 0
        local j = 30
        for i = 1, #steps do
            local param = splitStrByChar(steps[i], ",")
            totalWorkTime = totalWorkTime + string2Int(param[1])
            msgTx[j + 1] = math.floor(string2Int(param[1]) / 60)
            msgTx[j + 2] = string2Int(param[1]) % 60
            msgTx[j + 3] = string2Int(param[2])
            msgTx[j + 4] = string2Int(param[3])
            j = j + 10
        end
        msgTx[22] = math.floor(string2Int(totalWorkTime) / 60)
        msgTx[23] = string2Int(totalWorkTime) % 60
        local msgLength = #msgTx
        msgTx[msgLength] = makeSum(msgTx, 2, msgLength - 1)
        return 1, string2hexstring(table2string(msgTx))
    end
    return flag
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decode(jsonCmdStr)
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        if (status) then
            tableMerge(status, control)
            control = status
        end
        jsonToModel(control)
        local flag, diyCmd = getDiyCmd(control)
        if flag == 1 then return diyCmd end
        local bodyLength = 16
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0xAA
        bodyBytes[1] = 0x55
        bodyBytes[2] = control_src
        bodyBytes[3] = 0x02
        bodyBytes[4] = bit.band(mode, 0xFF)
        bodyBytes[5] = bit.band(bit.rshift(mode, 8), 0xFF)
        bodyBytes[8] = workstatus
        if workstatus == BYTE_COOKING then
            orderHour = no_schedule_order_time
            orderMin = no_schedule_order_time
        end
        bodyBytes[9] = orderHour
        bodyBytes[10] = orderMin
        bodyBytes[11] = leftHour
        bodyBytes[12] = leftMin
        bodyBytes[13] = mouthFeel
        bodyBytes[14] = bit.band(riceType, 0xFF)
        bodyBytes[15] = bit.band(bit.rshift(riceType, 8), 0xFF)
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        local infoM = {}
        local length = #msgBytes + 1
        for i = 1, length do infoM[i] = msgBytes[i - 1] end
        local ret = table2string(infoM)
        ret = string2hexstring(ret)
        return ret
    elseif (query) then
        return "AA0FEA00000000000103AA5501030000"
    end
end

function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decode(jsonStr)
    local binData = json["msg"]["data"]
    local status = json["status"]
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10];
    bodyBytes = extractBodyBytes(byteData)
    local ret = binToModel(bodyBytes)
    local retTable = {}
    if ret == nil then
        if status == nil then
            retTable["status"] = {}
            retTable["status"][JSON_KEY_TAB.KEY_VERSION] = VALUE_VERSION
        else
            jsonToModel(status)
            retTable["status"] = assembleJsonByGlobalProperty()
        end
    else
        retTable["status"] = assembleJsonByGlobalProperty()
    end
    local ret = encode(retTable)
    return ret
end
