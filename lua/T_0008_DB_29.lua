local JSON = require "cjson"
local BYTE_PROTOCOL_LENGTH = 0x10
local dataType = 0x00
local subDataType = 0x00
local version = 29
local keyTable = {
    KEY_VERSION = "version",
    KEY_FUNCTION_TYPE = "function_type",
    KEY_COMMAND = "command",
    KEY_MODE = "mode",
    KEY_PROGRAM = "program",
    KEY_RESERVATION_HOUR = "reservation_hour",
    KEY_RESERVATION_MIN = "reservation_min",
    KEY_TIME_HOUR = "time_hour",
    KEY_TIME_MIN = "time_min",
    KEY_TIME_SEC = "time_sec",
    KEY_WASH_TIME = "wash_time",
    KEY_RINSE_POUR = "rinse_pour",
    KEY_DEHYDRATION_TIME = "dehydration_time",
    KEY_DRY = "dry",
    KEY_WASH_RISE = "wash_rinse",
    KEY_UFB = "ufb",
    KEY_TEMPERATURE = "temperature",
    KEY_LOCK = "lock",
    KEY_TUB_AUTO_CLEAN = "tub_auto_clean",
    KEY_BUZZER = "buzzer",
    KEY_RINSE_MODE = "rinse_mode",
    KEY_LOW_NOISE = "low_noise",
    KEY_ENERGY_SAVING = "energy_saving",
    KEY_HOT_WATER_FIFTEEN = "hot_water_fifteen",
    KEY_DRY_FINISH_ADJUST = "dry_finish_adjust",
    KEY_SPIN_ROTATE_ADJUST = "spin_rotate_adjust",
    KEY_FUNGUS_PROTECT = "fungus_protect",
    KEY_DRAIN_BUBBLE_PROTECT = "drain_bubble_protect",
    KEY_DEFAULT_DRY = "default_dry",
    KEY_PROCESS_INFO_WASH = "process_info_wash",
    KEY_PROCESS_INFO_RINSE = "process_info_rinse",
    KEY_PROCESS_INFO_SPIN = "process_info_spin",
    KEY_PROCESS_INFO_DRY = "process_info_dry",
    KEY_PROCESS_INFO_SOFT_KEEP = "process_info_soft_keep",
    KEY_PROCESS_DETAIL = "process_detail",
    KEY_ERROR = "error",
    KEY_MACHINE_STATUS = "machine_status",
    KEY_REMAIN_TIME = "remain_time",
    KEY_DOOR_OPEN = "door_open",
    KEY_REMAIN_TIME_ADJUST = "remain_time_adjust",
    KEY_DRAIN_FILTER_CLEAN = "drain_filter_clean",
    KEY_TUB_HIGH_HOT = "tub_high_hot",
    KEY_WATER_HIGH_TEMPERATURE = "water_high_temperature",
    KEY_TUB_WATER_EXIST = "tub_water_exist",
    KEY_OVER_CAPACITY = "over_capacity",
    KEY_DRAIN_FILTER_CARE = "drain_filter_care",
    KEY_DRY_FILTER_CLEAN = "dry_filter_clean",
    KEY_APP_COURSE_NUMBER = "app_course_number",
    KEY_RESERVATION_MODE = "reservation_mode",
    KEY_OPERATION_WASH_TIME = "operation_wash_time",
    KEY_OPERATION_WASH_RINSE_TIMES = "operation_wash_rinse_times",
    KEY_OPERATION_WASH_SPIN_TIME = "operation_wash_spin_time",
    KEY_OPERATION_WASH_DRYER_TIME = "operation_wash_dryer_time",
    KEY_OPERATION_WASH_DRYER_RINSE_TIMES = "operation_wash_dryer_rinse_times",
    KEY_OPERATION_WASH_DRYER_SPIN_TIME = "operation_wash_dryer_spin_time",
    KEY_OPERATION_WASH_DRYER_DRY_SET = "operation_wash_dryer_dry_set",
    KEY_OPERATION_DRYER_DRY_SET = "operation_dryer_dry_set",
    KEY_DETERGENT_REMAIN = "detergent_remain",
    KEY_DETERGENT_REMAIN_EXPLANATION = "detergent_remain_explanation",
    KEY_DETERGENT_SETTING = "detergent_setting",
    KEY_SOFTNER_REMAIN = "softner_remain",
    KEY_SOFTNER_REMAIN_EXPLANATION = "softner_remain_explanation",
    KEY_SOFTNER_SETTING = "softner_setting",
    KEY_DETERGENT_NAME = "detergent_name",
    KEY_SOFTNER_NAME = "softner_name",
    KEY_DETERGENT_MEASURE = "detergent_measure",
    KEY_SOFTNER_MEASURE = "softner_measure",
    KEY_BEGIN_PROCESS_WASH = "begin_process_wash",
    KEY_BEGIN_PROCESS_RINSE = "begin_process_rinse",
    KEY_BEGIN_PROCESS_SPIN = "begin_process_spin",
    KEY_BEGIN_PROCESS_DRY = "begin_process_dry",
    KEY_BEGIN_PROCESS_SOFT_KEEP = "begin_process_soft_keep",
    KEY_RESERVATION_TIME_EARLIEST_HOUR = "reservation_time_earliest_hour",
    KEY_RESERVATION_TIME_EARLIEST_MIN = "reservation_time_earliest_min",
    KEY_RESERVATION_TIME_LATEST_HOUR = "reservation_time_latest_hour",
    KEY_RESERVATION_TIME_LATEST_MIN = "reservation_time_latest_min"
}
local proTable = {
    functionType = 0x00,
    command = 0xff,
    mode = 0xff,
    program = 0xff,
    reservationHour = 0xff,
    reservationMin = 0xff,
    timeHour = 0xff,
    timeMin = 0xff,
    timeSec = 0xff,
    washTime = 0xff,
    rinsePour = 0xff,
    dehydrationTime = 0xff,
    dry = 0xff,
    washRinse = 0xff,
    ufb = 0x00,
    temperature = 0xff,
    lock = 0xff,
    tubAutoClean = 0xff,
    buzzer = 0xff,
    rinseMode = 0xff,
    lowNoise = 0xff,
    energySaving = 0xff,
    hotWaterFifteen = 0xff,
    dryFinishAdjust = nil,
    spinRotateAdjust = nil,
    fungusProtect = nil,
    drainBubbleProtect = nil,
    defaultDry = 0xff,
    processInfo = 0,
    processDetail = nil,
    errorCode = nil,
    error = nil,
    machineStatus = nil,
    remainTime = nil,
    doorOpen = nil,
    remainTimeAdjust = nil,
    drainFilterClean = nil,
    tubHighHot = nil,
    waterHighTemperature = nil,
    tubWaterExist = nil,
    overCapacity = nil,
    drainFilterCare = nil,
    dryFilterClean = nil,
    appCourseNumber = nil,
    reservationMode = nil,
    operationWashTime = nil,
    operationWashRinseTimes = nil,
    operationWashSpinTime = nil,
    operationWashDryerTime = nil,
    operationWashDryerRinseTimes = nil,
    operationWashDryerSpinTime = nil,
    operationWashDryerDrySet = nil,
    operationDryerDrySet = nil,
    detergentRemain = nil,
    detergentRemainExplanation = nil,
    detergentSetting = nil,
    softnerRemain = nil,
    softnerRemainExplanation = nil,
    softnerSetting = nil,
    detergentName = nil,
    softnerName = nil,
    detergentMeasure = nil,
    softnerMeasure = nil,
    beginProcess = 0,
    reservationTimeEarliestHour = nil,
    reservationTimeEarliestMin = nil,
    reservationTimeLatestHour = nil,
    reservationTimeLatestMin = nil,
    errorYear = nil,
    errorMonth = nil,
    errorDay = nil,
    errorHour = nil,
    errorMin = nil,
    firm = nil,
    machineName = nil,
    e2prom = nil,
    dryClothWeight = nil,
    wetClothWeight = nil,
    operationStartTimeHour = nil,
    operationStartTimeMin = nil,
    operationEndTimeHour = nil,
    operationEndTimeMin = nil,
    remainTimeHour = nil,
    remainTimeMin = nil,
    operationTimeHour = nil,
    operationTimeMin = nil,
    presenceDetergent = nil,
    courseConfirmNumber = 0,
    response_status = 0xff,
    wash_course_one_program = 0xff,
    wash_course_one_wash_time = 0xff,
    wash_course_one_rinse_pour = 0xff,
    wash_course_one_dehydration_time = 0xff,
    wash_course_one_dry = 0xff,
    wash_course_one_temperature = 0xff,
    wash_course_one_wash_rinse = 0xff,
    wash_course_one_ufb = 0xff,
    wash_course_one_base_program = 0xff,
    wash_course_two_program = 0xff,
    wash_course_two_wash_time = 0xff,
    wash_course_two_rinse_pour = 0xff,
    wash_course_two_dehydration_time = 0xff,
    wash_course_two_dry = 0xff,
    wash_course_two_temperature = 0xff,
    wash_course_two_wash_rinse = 0xff,
    wash_course_two_ufb = 0xff,
    wash_course_two_base_program = 0xff,
    wash_course_three_program = 0xff,
    wash_course_three_wash_time = 0xff,
    wash_course_three_rinse_pour = 0xff,
    wash_course_three_dehydration_time = 0xff,
    wash_course_three_dry = 0xff,
    wash_course_three_temperature = 0xff,
    wash_course_three_wash_rinse = 0xff,
    wash_course_three_ufb = 0xff,
    wash_course_three_base_program = 0xff,
    wash_dry_course_one_program = 0xff,
    wash_dry_course_one_wash_time = 0xff,
    wash_dry_course_one_rinse_pour = 0xff,
    wash_dry_course_one_dehydration_time = 0xff,
    wash_dry_course_one_dry = 0xff,
    wash_dry_course_one_temperature = 0xff,
    wash_dry_course_one_wash_rinse = 0xff,
    wash_dry_course_one_ufb = 0xff,
    wash_dry_course_one_base_program = 0xff,
    wash_dry_course_two_program = 0xff,
    wash_dry_course_two_wash_time = 0xff,
    wash_dry_course_two_rinse_pour = 0xff,
    wash_dry_course_two_dehydration_time = 0xff,
    wash_dry_course_two_dry = 0xff,
    wash_dry_course_two_temperature = 0xff,
    wash_dry_course_two_wash_rinse = 0xff,
    wash_dry_course_two_ufb = 0xff,
    wash_dry_course_two_base_program = 0xff,
    wash_dry_course_three_program = 0xff,
    wash_dry_course_three_wash_time = 0xff,
    wash_dry_course_three_rinse_pour = 0xff,
    wash_dry_course_three_dehydration_time = 0xff,
    wash_dry_course_three_dry = 0xff,
    wash_dry_course_three_temperature = 0xff,
    wash_dry_course_three_wash_rinse = 0xff,
    wash_dry_course_three_ufb = 0xff,
    wash_dry_course_three_base_program = 0xff,
    inventoryUsageType = 0xff,
    inventoryUsageAmount = 0xff,
    inventoryUsageAccumulatedAmount = 0xff
}
local function crc16_ccitt(tmpbuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        local i = 0
        crc = bit.bxor(crc, bit.lshift(tmpbuf[si], 8))
        for i = 0, 7 do
            if bit.band(crc, 0x8000) == 0x8000 then
                crc = bit.bxor(bit.lshift(crc, 1), 0x1021)
            else
                crc = bit.lshift(crc, 1)
            end
        end
    end
    return crc
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
function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end
local function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do msgBytes[i - 1] = byteData[i] end
    local bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 2
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    return bodyBytes
end
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 2)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = 0x55
    msgBytes[1] = 0xAA
    msgBytes[2] = 0xCC
    msgBytes[3] = 0x33
    local msgLen = msgLength - 4
    msgBytes[4] = bit.band(msgLen, 0xff)
    msgBytes[5] = bit.band(bit.rshift(msgLen, 8), 0xff)
    msgBytes[6] = 0x01
    msgBytes[7] = 0xDB
    msgBytes[14] = bit.band(type, 0xff)
    msgBytes[15] = bit.band(bit.rshift(type, 8), 0xff)
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    local crc16 = crc16_ccitt(msgBytes, 0, msgLength - 3)
    msgBytes[msgLength - 2] = bit.band(crc16, 0xff)
    msgBytes[msgLength - 1] = bit.band(bit.rshift(crc16, 8), 0xff)
    return msgBytes
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
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
local function string2Int(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end
local function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = "0" end
    return data
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
local function updatePropertyOfProgram(key, value)
    if value == "none" then
        proTable[key] = 0x00
    elseif value == "standard" then
        proTable[key] = 0x01
    elseif value == "tub_clean" then
        proTable[key] = 0x02
    elseif value == "fast" then
        proTable[key] = 0x03
    elseif value == "careful" then
        proTable[key] = 0x04
    elseif value == "sixty_wash" then
        proTable[key] = 0x05
    elseif value == "blanket" then
        proTable[key] = 0x06
    elseif value == "delicate" then
        proTable[key] = 0x07
    elseif value == "tub_clean_dry" then
        proTable[key] = 0x08
    elseif value == "memory" then
        proTable[key] = 0x09
    elseif value == "sterilization" then
        proTable[key] = 0x0A
    elseif value == "mute" then
        proTable[key] = 0x0B
    elseif value == "soft" then
        proTable[key] = 0x0C
    elseif value == "delicate_dryer" then
        proTable[key] = 0x0D
    elseif value == "soak" then
        proTable[key] = 0x0E
    elseif value == "odor_eliminating" then
        proTable[key] = 0x0F
    elseif value == "empty" then
        proTable[key] = 0x10
    elseif value == "degerm" then
        proTable[key] = 0x11
    elseif value == "auto_care" then
        proTable[key] = 0x12
    elseif value == "auto_twice_wash" then
        proTable[key] = 0x13
    elseif value == "prewash_plus" then
        proTable[key] = 0x14
    elseif value == "uv_wash_and_dry" then
        proTable[key] = 0x15
    elseif value == "uv_dry_with_rotation" then
        proTable[key] = 0x16
    elseif value == "uv_dry_without_rotation" then
        proTable[key] = 0x17
    elseif value == "forty_five_wash" then
        proTable[key] = 0x18
    elseif value == "fragrant_and_delicate" then
        proTable[key] = 0x1C
    elseif value == "tick_extermination" then
        proTable[key] = 0x1D
    elseif value == "pollen" then
        proTable[key] = 0x1E
    elseif value == "app_course_1" then
        proTable[key] = 0x21
    elseif value == "app_course_2" then
        proTable[key] = 0x22
    elseif value == "app_course_3" then
        proTable[key] = 0x23
    elseif value == "app_course" then
        proTable[key] = 0x24
    elseif value == "uv_wash" then
        proTable[key] = 0x25
    elseif value == "uv_without_rotation" then
        proTable[key] = 0x26
    elseif value == "uv_with_rotation" then
        proTable[key] = 0x27
    elseif value == "uv_deodorize_without_rotation" then
        proTable[key] = 0x28
    elseif value == "uv_deodorize_with_rotation" then
        proTable[key] = 0x29
    elseif value == "60_tub_clean" then
        proTable[key] = 0x30
    elseif value == "sheets" then
        proTable[key] = 0x51
    elseif value == "lace_curtain" then
        proTable[key] = 0x52
    elseif value == "towel" then
        proTable[key] = 0x53
    elseif value == "fleece" then
        proTable[key] = 0x54
    elseif value == "school_uniform_or_washable" then
        proTable[key] = 0x55
    elseif value == "slacks_skirt" then
        proTable[key] = 0x56
    elseif value == "jeans" then
        proTable[key] = 0x57
    elseif value == "cap" then
        proTable[key] = 0x58
    elseif value == "down_jacket" then
        proTable[key] = 0x59
    elseif value == "bet_putt" then
        proTable[key] = 0x5A
    elseif value == "functional_underwear" then
        proTable[key] = 0x5B
    elseif value == "reusable_bag" then
        proTable[key] = 0x5C
    elseif value == "duvet" then
        proTable[key] = 0x5D
    elseif value == "t_shirt_recovery" then
        proTable[key] = 0x5E
    elseif value == "sports_wear" then
        proTable[key] = 0x5F
    elseif value == "light_dirt" then
        proTable[key] = 0x81
    elseif value == "wash_thoroughly_and_rinse" then
        proTable[key] = 0x82
    elseif value == "quick_wash_and_dry" then
        proTable[key] = 0x83
    elseif value == "yellowing_off" then
        proTable[key] = 0x84
    elseif value == "disinfection_clothing" then
        proTable[key] = 0x85
    elseif value == "keep_water_temperature" then
        proTable[key] = 0x86
    elseif value == "prewash" then
        proTable[key] = 0x87
    elseif value == "super_concentrated_soak" then
        proTable[key] = 0x91
    elseif value == "no_rinse_and_delicate" then
        proTable[key] = 0x92
    elseif value == "t_shirt_recovery_pro" then
        proTable[key] = 0x93
    elseif value == "customize" then
        proTable[key] = 0xA0
    end
end
local function updatePropertyOfWashTime(key, value)
    if value ~= nil then
        local tmpTime = string2Int(value)
        if tmpTime == 1 * 60 then
            proTable[key] = 0x81
        elseif tmpTime == 2 * 60 then
            proTable[key] = 0x82
        elseif tmpTime == 3 * 60 then
            proTable[key] = 0x83
        elseif tmpTime == 4 * 60 then
            proTable[key] = 0x84
        elseif tmpTime == 5 * 60 then
            proTable[key] = 0x85
        elseif tmpTime == 6 * 60 then
            proTable[key] = 0x86
        elseif tmpTime == 7 * 60 then
            proTable[key] = 0x87
        elseif tmpTime == 8 * 60 then
            proTable[key] = 0x88
        elseif tmpTime == 9 * 60 then
            proTable[key] = 0x89
        elseif tmpTime == 10 * 60 then
            proTable[key] = 0x8A
        elseif tmpTime == 11 * 60 then
            proTable[key] = 0x8B
        elseif tmpTime == 12 * 60 then
            proTable[key] = 0x8C
        else
            proTable[key] = tmpTime
        end
    end
end
local function updatePropertyOfWashRise(key, value)
    if value == "none" then
        proTable[key] = 0x00
    elseif value == "wash" then
        proTable[key] = 0x01
    elseif value == "wash_to_rinse" then
        proTable[key] = 0x02
    elseif value == "rinse" then
        proTable[key] = 0x03
    end
end
local function updatePropertyOfUBF(key, value)
    if value == "on" then
        proTable[key] = 0x80
    elseif value == "off" then
        proTable[key] = 0x00
    end
end
local function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[keyTable.KEY_COMMAND] == "none" then
        proTable.command = 0x00
    elseif luaTable[keyTable.KEY_COMMAND] == "temporary_stop" then
        proTable.command = 0x01
    elseif luaTable[keyTable.KEY_COMMAND] == "reservation_fix" then
        proTable.command = 0x02
    elseif luaTable[keyTable.KEY_COMMAND] == "reservation_cancel" then
        proTable.command = 0x03
    elseif luaTable[keyTable.KEY_COMMAND] == "reservation_start" then
        proTable.command = 0x04
    elseif luaTable[keyTable.KEY_COMMAND] == "reservation_set" then
        proTable.command = 0x05
    elseif luaTable[keyTable.KEY_COMMAND] == "finish" then
        proTable.command = 0x06
    elseif luaTable[keyTable.KEY_COMMAND] == "auto_dispenser_setting_change" then
        proTable.command = 0x07
    end
    if luaTable[keyTable.KEY_MODE] == "none" then
        proTable.mode = 0x00
    elseif luaTable[keyTable.KEY_MODE] == "wash_dry" then
        proTable.mode = 0x01
    elseif luaTable[keyTable.KEY_MODE] == "wash" then
        proTable.mode = 0x02
    elseif luaTable[keyTable.KEY_MODE] == "dry" then
        proTable.mode = 0x03
    elseif luaTable[keyTable.KEY_MODE] == "clean_care" then
        proTable.mode = 0x04
    elseif luaTable[keyTable.KEY_MODE] == "care" then
        proTable.mode = 0x05
    end
    if luaTable[keyTable.KEY_PROGRAM] == "none" then
        proTable.program = 0x00
    elseif luaTable[keyTable.KEY_PROGRAM] == "standard" then
        proTable.program = 0x01
    elseif luaTable[keyTable.KEY_PROGRAM] == "tub_clean" then
        proTable.program = 0x02
    elseif luaTable[keyTable.KEY_PROGRAM] == "fast" then
        proTable.program = 0x03
    elseif luaTable[keyTable.KEY_PROGRAM] == "careful" then
        proTable.program = 0x04
    elseif luaTable[keyTable.KEY_PROGRAM] == "sixty_wash" then
        proTable.program = 0x05
    elseif luaTable[keyTable.KEY_PROGRAM] == "blanket" then
        proTable.program = 0x06
    elseif luaTable[keyTable.KEY_PROGRAM] == "delicate" then
        proTable.program = 0x07
    elseif luaTable[keyTable.KEY_PROGRAM] == "tub_clean_dry" then
        proTable.program = 0x08
    elseif luaTable[keyTable.KEY_PROGRAM] == "memory" then
        proTable.program = 0x09
    elseif luaTable[keyTable.KEY_PROGRAM] == "sterilization" then
        proTable.program = 0x0A
    elseif luaTable[keyTable.KEY_PROGRAM] == "mute" then
        proTable.program = 0x0B
    elseif luaTable[keyTable.KEY_PROGRAM] == "soft" then
        proTable.program = 0x0C
    elseif luaTable[keyTable.KEY_PROGRAM] == "delicate_dryer" then
        proTable.program = 0x0D
    elseif luaTable[keyTable.KEY_PROGRAM] == "soak" then
        proTable.program = 0x0E
    elseif luaTable[keyTable.KEY_PROGRAM] == "odor_eliminating" then
        proTable.program = 0x0F
    elseif luaTable[keyTable.KEY_PROGRAM] == "empty" then
        proTable.program = 0x10
    elseif luaTable[keyTable.KEY_PROGRAM] == "degerm" then
        proTable.program = 0x11
    elseif luaTable[keyTable.KEY_PROGRAM] == "auto_care" then
        proTable.program = 0x12
    elseif luaTable[keyTable.KEY_PROGRAM] == "auto_twice_wash" then
        proTable.program = 0x13
    elseif luaTable[keyTable.KEY_PROGRAM] == "prewash_plus" then
        proTable.program = 0x14
    elseif luaTable[keyTable.KEY_PROGRAM] == "uv_wash_and_dry" then
        proTable.program = 0x15
    elseif luaTable[keyTable.KEY_PROGRAM] == "uv_dry_with_rotation" then
        proTable.program = 0x16
    elseif luaTable[keyTable.KEY_PROGRAM] == "uv_dry_without_rotation" then
        proTable.program = 0x17
    elseif luaTable[keyTable.KEY_PROGRAM] == "forty_five_wash" then
        proTable.program = 0x18
    elseif luaTable[keyTable.KEY_PROGRAM] == "fragrant_and_delicate" then
        proTable.program = 0x1C
    elseif luaTable[keyTable.KEY_PROGRAM] == "tick_extermination" then
        proTable.program = 0x1D
    elseif luaTable[keyTable.KEY_PROGRAM] == "pollen" then
        proTable.program = 0x1E
    elseif luaTable[keyTable.KEY_PROGRAM] == "app_course_1" then
        proTable.program = 0x21
    elseif luaTable[keyTable.KEY_PROGRAM] == "app_course_2" then
        proTable.program = 0x22
    elseif luaTable[keyTable.KEY_PROGRAM] == "app_course_3" then
        proTable.program = 0x23
    elseif luaTable[keyTable.KEY_PROGRAM] == "app_course" then
        proTable.program = 0x24
    elseif luaTable[keyTable.KEY_PROGRAM] == "uv_wash" then
        proTable.program = 0x25
    elseif luaTable[keyTable.KEY_PROGRAM] == "uv_without_rotation" then
        proTable.program = 0x26
    elseif luaTable[keyTable.KEY_PROGRAM] == "uv_with_rotation" then
        proTable.program = 0x27
    elseif luaTable[keyTable.KEY_PROGRAM] == "uv_deodorize_without_rotation" then
        proTable.program = 0x28
    elseif luaTable[keyTable.KEY_PROGRAM] == "uv_deodorize_with_rotation" then
        proTable.program = 0x29
    elseif luaTable[keyTable.KEY_PROGRAM] == "60_tub_clean" then
        proTable.program = 0x30
    elseif luaTable[keyTable.KEY_PROGRAM] == "sheets" then
        proTable.program = 0x51
    elseif luaTable[keyTable.KEY_PROGRAM] == "lace_curtain" then
        proTable.program = 0x52
    elseif luaTable[keyTable.KEY_PROGRAM] == "towel" then
        proTable.program = 0x53
    elseif luaTable[keyTable.KEY_PROGRAM] == "fleece" then
        proTable.program = 0x54
    elseif luaTable[keyTable.KEY_PROGRAM] == "school_uniform_or_washable" then
        proTable.program = 0x55
    elseif luaTable[keyTable.KEY_PROGRAM] == "slacks_skirt" then
        proTable.program = 0x56
    elseif luaTable[keyTable.KEY_PROGRAM] == "jeans" then
        proTable.program = 0x57
    elseif luaTable[keyTable.KEY_PROGRAM] == "cap" then
        proTable.program = 0x58
    elseif luaTable[keyTable.KEY_PROGRAM] == "down_jacket" then
        proTable.program = 0x59
    elseif luaTable[keyTable.KEY_PROGRAM] == "bet_putt" then
        proTable.program = 0x5A
    elseif luaTable[keyTable.KEY_PROGRAM] == "functional_underwear" then
        proTable.program = 0x5B
    elseif luaTable[keyTable.KEY_PROGRAM] == "reusable_bag" then
        proTable.program = 0x5C
    elseif luaTable[keyTable.KEY_PROGRAM] == "duvet" then
        proTable.program = 0x5D
    elseif luaTable[keyTable.KEY_PROGRAM] == "t_shirt_recovery" then
        proTable.program = 0x5E
    elseif luaTable[keyTable.KEY_PROGRAM] == "sports_wear" then
        proTable.program = 0x5F
    elseif luaTable[keyTable.KEY_PROGRAM] == "light_dirt" then
        proTable.program = 0x81
    elseif luaTable[keyTable.KEY_PROGRAM] == "wash_thoroughly_and_rinse" then
        proTable.program = 0x82
    elseif luaTable[keyTable.KEY_PROGRAM] == "quick_wash_and_dry" then
        proTable.program = 0x83
    elseif luaTable[keyTable.KEY_PROGRAM] == "yellowing_off" then
        proTable.program = 0x84
    elseif luaTable[keyTable.KEY_PROGRAM] == "disinfection_clothing" then
        proTable.program = 0x85
    elseif luaTable[keyTable.KEY_PROGRAM] == "keep_water_temperature" then
        proTable.program = 0x86
    elseif luaTable[keyTable.KEY_PROGRAM] == "prewash" then
        proTable.program = 0x87
    elseif luaTable[keyTable.KEY_PROGRAM] == "super_concentrated_soak" then
        proTable.program = 0x91
    elseif luaTable[keyTable.KEY_PROGRAM] == "no_rinse_and_delicate" then
        proTable.program = 0x92
    elseif luaTable[keyTable.KEY_PROGRAM] == "t_shirt_recovery_pro" then
        proTable.program = 0x93
    elseif luaTable[keyTable.KEY_PROGRAM] == "customize" then
        proTable.program = 0xA0
    end
    if luaTable[keyTable.KEY_RESERVATION_HOUR] ~= nil then
        proTable.reservationHour = string2Int(
                                       luaTable[keyTable.KEY_RESERVATION_HOUR])
    end
    if luaTable[keyTable.KEY_RESERVATION_MIN] ~= nil then
        proTable.reservationMin = string2Int(
                                      luaTable[keyTable.KEY_RESERVATION_MIN])
    end
    if luaTable[keyTable.KEY_TIME_HOUR] ~= nil then
        proTable.timeHour = string2Int(luaTable[keyTable.KEY_TIME_HOUR])
    end
    if luaTable[keyTable.KEY_TIME_MIN] ~= nil then
        proTable.timeMin = string2Int(luaTable[keyTable.KEY_TIME_MIN])
    end
    if luaTable[keyTable.KEY_TIME_SEC] ~= nil then
        proTable.timeSec = string2Int(luaTable[keyTable.KEY_TIME_SEC])
    end
    if luaTable[keyTable.KEY_WASH_TIME] ~= nil then
        local tmpTime = string2Int(luaTable[keyTable.KEY_WASH_TIME])
        if tmpTime == 1 * 60 then
            proTable.washTime = 0x81
        elseif tmpTime == 2 * 60 then
            proTable.washTime = 0x82
        elseif tmpTime == 3 * 60 then
            proTable.washTime = 0x83
        elseif tmpTime == 4 * 60 then
            proTable.washTime = 0x84
        elseif tmpTime == 5 * 60 then
            proTable.washTime = 0x85
        elseif tmpTime == 6 * 60 then
            proTable.washTime = 0x86
        elseif tmpTime == 7 * 60 then
            proTable.washTime = 0x87
        elseif tmpTime == 8 * 60 then
            proTable.washTime = 0x88
        elseif tmpTime == 9 * 60 then
            proTable.washTime = 0x89
        elseif tmpTime == 10 * 60 then
            proTable.washTime = 0x8A
        elseif tmpTime == 11 * 60 then
            proTable.washTime = 0x8B
        elseif tmpTime == 12 * 60 then
            proTable.washTime = 0x8C
        else
            proTable.washTime = tmpTime
        end
    end
    if luaTable[keyTable.KEY_RINSE_POUR] ~= nil then
        proTable.rinsePour = string2Int(luaTable[keyTable.KEY_RINSE_POUR])
    end
    if luaTable[keyTable.KEY_DEHYDRATION_TIME] ~= nil then
        proTable.dehydrationTime = string2Int(
                                       luaTable[keyTable.KEY_DEHYDRATION_TIME])
    end
    if luaTable[keyTable.KEY_DRY] ~= nil then
        proTable.dry = string2Int(luaTable[keyTable.KEY_DRY])
    end
    if luaTable[keyTable.KEY_WASH_RISE] == "none" then
        proTable.washRinse = 0x00
    elseif luaTable[keyTable.KEY_WASH_RISE] == "wash" then
        proTable.washRinse = 0x01
    elseif luaTable[keyTable.KEY_WASH_RISE] == "wash_to_rinse" then
        proTable.washRinse = 0x02
    elseif luaTable[keyTable.KEY_WASH_RISE] == "rinse" then
        proTable.washRinse = 0x03
    elseif luaTable[keyTable.KEY_WASH_RISE] == "hidden" then
        proTable.washRinse = 0x07
    end
    if luaTable[keyTable.KEY_UFB] == "on" then
        proTable.ufb = 0x80
    elseif luaTable[keyTable.KEY_UFB] == "off" then
        proTable.ufb = 0x00
    end
    if luaTable[keyTable.KEY_TEMPERATURE] ~= nil then
        proTable.temperature = string2Int(luaTable[keyTable.KEY_TEMPERATURE])
    end
    if luaTable[keyTable.KEY_LOCK] == "on" then
        proTable.lock = 0x01
    elseif luaTable[keyTable.KEY_LOCK] == "off" then
        proTable.lock = 0x00
    end
    if luaTable[keyTable.KEY_TUB_AUTO_CLEAN] == "on" then
        proTable.tubAutoClean = 0x02
    elseif luaTable[keyTable.KEY_TUB_AUTO_CLEAN] == "off" then
        proTable.tubAutoClean = 0x00
    end
    if luaTable[keyTable.KEY_BUZZER] == "on" then
        proTable.buzzer = 0x04
    elseif luaTable[keyTable.KEY_BUZZER] == "off" then
        proTable.buzzer = 0x00
    end
    if luaTable[keyTable.KEY_RINSE_MODE] == "on" then
        proTable.rinseMode = 0x08
    elseif luaTable[keyTable.KEY_RINSE_MODE] == "off" then
        proTable.rinseMode = 0x00
    end
    if luaTable[keyTable.KEY_LOW_NOISE] == "on" then
        proTable.lowNoise = 0x10
    elseif luaTable[keyTable.KEY_LOW_NOISE] == "off" then
        proTable.lowNoise = 0x00
    end
    if luaTable[keyTable.KEY_ENERGY_SAVING] == "on" then
        proTable.energySaving = 0x20
    elseif luaTable[keyTable.KEY_ENERGY_SAVING] == "off" then
        proTable.energySaving = 0x00
    end
    if luaTable[keyTable.KEY_HOT_WATER_FIFTEEN] == "on" then
        proTable.hotWaterFifteen = 0x40
    elseif luaTable[keyTable.KEY_HOT_WATER_FIFTEEN] == "off" then
        proTable.hotWaterFifteen = 0x00
    end
    if luaTable[keyTable.KEY_DRY_FINISH_ADJUST] ~= nil then
        proTable.dryFinishAdjust = string2Int(
                                       luaTable[keyTable.KEY_DRY_FINISH_ADJUST])
    end
    if luaTable[keyTable.KEY_SPIN_ROTATE_ADJUST] ~= nil then
        proTable.spinRotateAdjust = string2Int(
                                        luaTable[keyTable.KEY_SPIN_ROTATE_ADJUST])
    end
    if luaTable[keyTable.KEY_FUNGUS_PROTECT] == "on" then
        proTable.fungusProtect = 0x20
    elseif luaTable[keyTable.KEY_FUNGUS_PROTECT] == "off" then
        proTable.fungusProtect = 0x00
    end
    if luaTable[keyTable.KEY_DRAIN_BUBBLE_PROTECT] == "on" then
        proTable.drainBubbleProtect = 0x40
    elseif luaTable[keyTable.KEY_DRAIN_BUBBLE_PROTECT] == "off" then
        proTable.drainBubbleProtect = 0x00
    end
    if luaTable[keyTable.KEY_DEFAULT_DRY] == "speed" then
        proTable.defaultDry = 0x01
    elseif luaTable[keyTable.KEY_DEFAULT_DRY] == "energy_saving" then
        proTable.defaultDry = 0x00
    elseif luaTable[keyTable.KEY_DEFAULT_DRY] == "power_saving" then
        proTable.defaultDry = 0x02
    end
    if luaTable[keyTable.KEY_DETERGENT_REMAIN_EXPLANATION] ~= nil then
        proTable.detergentRemainExplanation = string2Int(
                                                  luaTable[keyTable.KEY_DETERGENT_REMAIN_EXPLANATION])
    end
    if luaTable[keyTable.KEY_DETERGENT_SETTING] == "on" then
        proTable.detergentSetting = 0x01
    elseif luaTable[keyTable.KEY_DETERGENT_SETTING] == "off" then
        proTable.detergentSetting = 0x00
    end
    if luaTable[keyTable.KEY_SOFTNER_REMAIN_EXPLANATION] ~= nil then
        proTable.softnerRemainExplanation = string2Int(
                                                luaTable[keyTable.KEY_SOFTNER_REMAIN_EXPLANATION])
    end
    if luaTable[keyTable.KEY_SOFTNER_SETTING] == "on" then
        proTable.softnerSetting = 0x01
    elseif luaTable[keyTable.KEY_SOFTNER_SETTING] == "off" then
        proTable.softnerSetting = 0x00
    end
    if luaTable[keyTable.KEY_DETERGENT_NAME] ~= nil then
        proTable.detergentName = string2Int(
                                     luaTable[keyTable.KEY_DETERGENT_NAME])
    end
    if luaTable[keyTable.KEY_SOFTNER_NAME] ~= nil then
        proTable.softnerName = string2Int(luaTable[keyTable.KEY_SOFTNER_NAME])
    end
    if luaTable[keyTable.KEY_DETERGENT_MEASURE] ~= nil then
        proTable.detergentMeasure = string2Int(
                                        luaTable[keyTable.KEY_DETERGENT_MEASURE])
    end
    if luaTable[keyTable.KEY_SOFTNER_MEASURE] ~= nil then
        proTable.softnerMeasure = string2Int(
                                      luaTable[keyTable.KEY_SOFTNER_MEASURE])
    end
    if luaTable[keyTable.KEY_FUNCTION_TYPE] == "app_course_receive" then
        proTable.functionType = 0x10
    else
        proTable.functionType = 0x00
    end
    if luaTable["response_status"] ~= nil then
        proTable.response_status = string2Int(luaTable["response_status"])
    end
    updatePropertyOfProgram("wash_course_one_program",
                            luaTable["wash_course_one_program"])
    updatePropertyOfWashTime("wash_course_one_wash_time",
                             luaTable["wash_course_one_wash_time"])
    if luaTable["wash_course_one_rinse_pour"] ~= nil then
        proTable.wash_course_one_rinse_pour = string2Int(
                                                  luaTable["wash_course_one_rinse_pour"])
    end
    if luaTable["wash_course_one_dehydration_time"] ~= nil then
        proTable.wash_course_one_dehydration_time = string2Int(
                                                        luaTable["wash_course_one_dehydration_time"])
    end
    if luaTable["wash_course_one_dry"] ~= nil then
        proTable.wash_course_one_dry = string2Int(
                                           luaTable["wash_course_one_dry"])
    end
    if luaTable["wash_course_one_temperature"] ~= nil then
        proTable.wash_course_one_temperature = string2Int(
                                                   luaTable["wash_course_one_temperature"])
    end
    updatePropertyOfWashRise("wash_course_one_wash_rinse",
                             luaTable["wash_course_one_wash_rinse"])
    updatePropertyOfUBF("wash_course_one_ufb", luaTable["wash_course_one_ufb"])
    updatePropertyOfProgram("wash_course_one_base_program",
                            luaTable["wash_course_one_base_program"])
    updatePropertyOfProgram("wash_course_two_program",
                            luaTable["wash_course_two_program"])
    updatePropertyOfWashTime("wash_course_two_wash_time",
                             luaTable["wash_course_two_wash_time"])
    if luaTable["wash_course_two_rinse_pour"] ~= nil then
        proTable.wash_course_two_rinse_pour = string2Int(
                                                  luaTable["wash_course_two_rinse_pour"])
    end
    if luaTable["wash_course_two_dehydration_time"] ~= nil then
        proTable.wash_course_two_dehydration_time = string2Int(
                                                        luaTable["wash_course_two_dehydration_time"])
    end
    if luaTable["wash_course_two_dry"] ~= nil then
        proTable.wash_course_two_dry = string2Int(
                                           luaTable["wash_course_two_dry"])
    end
    if luaTable["wash_course_two_temperature"] ~= nil then
        proTable.wash_course_two_temperature = string2Int(
                                                   luaTable["wash_course_two_temperature"])
    end
    updatePropertyOfWashRise("wash_course_two_wash_rinse",
                             luaTable["wash_course_two_wash_rinse"])
    updatePropertyOfUBF("wash_course_two_ufb", luaTable["wash_course_two_ufb"])
    updatePropertyOfProgram("wash_course_two_base_program",
                            luaTable["wash_course_two_base_program"])
    updatePropertyOfProgram("wash_course_three_program",
                            luaTable["wash_course_three_program"])
    updatePropertyOfWashTime("wash_course_three_wash_time",
                             luaTable["wash_course_three_wash_time"])
    if luaTable["wash_course_three_rinse_pour"] ~= nil then
        proTable.wash_course_three_rinse_pour = string2Int(
                                                    luaTable["wash_course_three_rinse_pour"])
    end
    if luaTable["wash_course_three_dehydration_time"] ~= nil then
        proTable.wash_course_three_dehydration_time = string2Int(
                                                          luaTable["wash_course_three_dehydration_time"])
    end
    if luaTable["wash_course_three_dry"] ~= nil then
        proTable.wash_course_three_dry = string2Int(
                                             luaTable["wash_course_three_dry"])
    end
    if luaTable["wash_course_three_temperature"] ~= nil then
        proTable.wash_course_three_temperature = string2Int(
                                                     luaTable["wash_course_three_temperature"])
    end
    updatePropertyOfWashRise("wash_course_three_wash_rinse",
                             luaTable["wash_course_three_wash_rinse"])
    updatePropertyOfUBF("wash_course_three_ufb",
                        luaTable["wash_course_three_ufb"])
    updatePropertyOfProgram("wash_course_three_base_program",
                            luaTable["wash_course_three_base_program"])
    updatePropertyOfProgram("wash_dry_course_one_program",
                            luaTable["wash_dry_course_one_program"])
    updatePropertyOfWashTime("wash_dry_course_one_wash_time",
                             luaTable["wash_dry_course_one_wash_time"])
    if luaTable["wash_dry_course_one_rinse_pour"] ~= nil then
        proTable.wash_dry_course_one_rinse_pour = string2Int(
                                                      luaTable["wash_dry_course_one_rinse_pour"])
    end
    if luaTable["wash_dry_course_one_dehydration_time"] ~= nil then
        proTable.wash_dry_course_one_dehydration_time = string2Int(
                                                            luaTable["wash_dry_course_one_dehydration_time"])
    end
    if luaTable["wash_dry_course_one_dry"] ~= nil then
        proTable.wash_dry_course_one_dry = string2Int(
                                               luaTable["wash_dry_course_one_dry"])
    end
    if luaTable["wash_dry_course_one_temperature"] ~= nil then
        proTable.wash_dry_course_one_temperature = string2Int(
                                                       luaTable["wash_dry_course_one_temperature"])
    end
    updatePropertyOfWashRise("wash_dry_course_one_wash_rinse",
                             luaTable["wash_dry_course_one_wash_rinse"])
    updatePropertyOfUBF("wash_dry_course_one_ufb",
                        luaTable["wash_dry_course_one_ufb"])
    updatePropertyOfProgram("wash_dry_course_one_base_program",
                            luaTable["wash_dry_course_one_base_program"])
    updatePropertyOfProgram("wash_dry_course_two_program",
                            luaTable["wash_dry_course_two_program"])
    updatePropertyOfWashTime("wash_dry_course_two_wash_time",
                             luaTable["wash_dry_course_two_wash_time"])
    if luaTable["wash_dry_course_two_rinse_pour"] ~= nil then
        proTable.wash_dry_course_two_rinse_pour = string2Int(
                                                      luaTable["wash_dry_course_two_rinse_pour"])
    end
    if luaTable["wash_dry_course_two_dehydration_time"] ~= nil then
        proTable.wash_dry_course_two_dehydration_time = string2Int(
                                                            luaTable["wash_dry_course_two_dehydration_time"])
    end
    if luaTable["wash_dry_course_two_dry"] ~= nil then
        proTable.wash_dry_course_two_dry = string2Int(
                                               luaTable["wash_dry_course_two_dry"])
    end
    if luaTable["wash_dry_course_two_temperature"] ~= nil then
        proTable.wash_dry_course_two_temperature = string2Int(
                                                       luaTable["wash_dry_course_two_temperature"])
    end
    updatePropertyOfWashRise("wash_dry_course_two_wash_rinse",
                             luaTable["wash_dry_course_two_wash_rinse"])
    updatePropertyOfUBF("wash_dry_course_two_ufb",
                        luaTable["wash_dry_course_two_ufb"])
    updatePropertyOfProgram("wash_dry_course_two_base_program",
                            luaTable["wash_dry_course_two_base_program"])
    updatePropertyOfProgram("wash_dry_course_three_program",
                            luaTable["wash_dry_course_three_program"])
    updatePropertyOfWashTime("wash_dry_course_three_wash_time",
                             luaTable["wash_dry_course_three_wash_time"])
    if luaTable["wash_dry_course_three_rinse_pour"] ~= nil then
        proTable.wash_dry_course_three_rinse_pour = string2Int(
                                                        luaTable["wash_dry_course_three_rinse_pour"])
    end
    if luaTable["wash_dry_course_three_dehydration_time"] ~= nil then
        proTable.wash_dry_course_three_dehydration_time = string2Int(
                                                              luaTable["wash_dry_course_three_dehydration_time"])
    end
    if luaTable["wash_dry_course_three_dry"] ~= nil then
        proTable.wash_dry_course_three_dry = string2Int(
                                                 luaTable["wash_dry_course_three_dry"])
    end
    if luaTable["wash_dry_course_three_temperature"] ~= nil then
        proTable.wash_dry_course_three_temperature = string2Int(
                                                         luaTable["wash_dry_course_three_temperature"])
    end
    updatePropertyOfWashRise("wash_dry_course_three_wash_rinse",
                             luaTable["wash_dry_course_three_wash_rinse"])
    updatePropertyOfUBF("wash_dry_course_three_ufb",
                        luaTable["wash_dry_course_three_ufb"])
    updatePropertyOfProgram("wash_dry_course_three_base_program",
                            luaTable["wash_dry_course_three_base_program"])
end
local function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == 0x02) or (dataType == 0x03) then
        if messageBytes[0] == 0x00 then
            local temp
            proTable.command = messageBytes[1]
            proTable.mode = messageBytes[2]
            proTable.program = messageBytes[3]
            proTable.reservationMin = messageBytes[4]
            proTable.reservationHour = messageBytes[5]
            proTable.timeSec = messageBytes[6]
            proTable.timeMin = messageBytes[7]
            proTable.timeHour = messageBytes[8]
            proTable.washTime = messageBytes[9]
            proTable.rinsePour = messageBytes[10]
            proTable.dehydrationTime = messageBytes[11]
            proTable.dry = messageBytes[12]
            proTable.washRinse = bit.band(messageBytes[13], 0x07)
            proTable.ufb = bit.band(messageBytes[13], 0x80)
            proTable.temperature = messageBytes[14]
            proTable.lock = bit.band(messageBytes[15], 0x01)
            proTable.tubAutoClean = bit.band(messageBytes[15], 0x02)
            proTable.buzzer = bit.band(messageBytes[15], 0x04)
            proTable.rinseMode = bit.band(messageBytes[15], 0x08)
            proTable.lowNoise = bit.band(messageBytes[15], 0x10)
            proTable.energySaving = bit.band(messageBytes[15], 0x20)
            proTable.hotWaterFifteen = bit.band(messageBytes[15], 0x40)
            proTable.dryFinishAdjust = bit.band(messageBytes[16], 0x07)
            proTable.spinRotateAdjust = bit.band(
                                            bit.rshift(messageBytes[16], 3),
                                            0x03)
            proTable.fungusProtect = bit.band(messageBytes[16], 0x20)
            proTable.drainBubbleProtect = bit.band(messageBytes[16], 0x40)
            proTable.defaultDry = bit.band(messageBytes[17], 0x03)
            proTable.processInfo = messageBytes[18]
            proTable.processDetail = messageBytes[19]
            proTable.error = bit.lshift(messageBytes[21], 8) + messageBytes[20]
            proTable.machineStatus = messageBytes[22]
            proTable.remainTime =
                messageBytes[26] * 16777216 + messageBytes[25] * 65536 +
                    messageBytes[24] * 256 + messageBytes[23]
            proTable.doorOpen = bit.band(messageBytes[27], 0x01)
            proTable.remainTimeAdjust = bit.band(messageBytes[27], 0x02)
            proTable.drainFilterClean = bit.band(messageBytes[27], 0x04)
            proTable.tubHighHot = bit.band(messageBytes[27], 0x08)
            proTable.waterHighTemperature = bit.band(messageBytes[27], 0x10)
            proTable.tubWaterExist = bit.band(messageBytes[27], 0x20)
            proTable.overCapacity = bit.band(messageBytes[27], 0x40)
            proTable.drainFilterCare = bit.band(messageBytes[28], 0x01)
            proTable.dryFilterClean = bit.band(messageBytes[28], 0x02)
            proTable.appCourseNumber = bit.band(bit.rshift(messageBytes[28], 2),
                                                0x0f)
            proTable.reservationMode = messageBytes[29]
            proTable.operationWashTime = messageBytes[30]
            proTable.operationWashRinseTimes = messageBytes[31]
            proTable.operationWashSpinTime = messageBytes[32]
            proTable.operationWashDryerTime = messageBytes[33]
            proTable.operationWashDryerRinseTimes = messageBytes[34]
            proTable.operationWashDryerSpinTime = messageBytes[35]
            proTable.operationWashDryerDrySet = messageBytes[36]
            proTable.operationDryerDrySet = messageBytes[37]
            proTable.detergentRemain = bit.band(messageBytes[38], 0x0F)
            temp = bit.rshift(messageBytes[38], 4)
            proTable.detergentRemainExplanation = bit.band(temp, 0x07)
            proTable.detergentSetting = bit.rshift(messageBytes[38], 7)
            proTable.softnerRemain = bit.band(messageBytes[39], 0x0F)
            temp = bit.rshift(messageBytes[39], 4)
            proTable.softnerRemainExplanation = bit.band(temp, 0x07)
            proTable.softnerSetting = bit.rshift(messageBytes[39], 7)
            proTable.detergentName = messageBytes[40]
            proTable.softnerName = messageBytes[41]
            proTable.detergentMeasure = messageBytes[42]
            proTable.softnerMeasure = messageBytes[43]
            proTable.beginProcess = messageBytes[44]
            proTable.reservationTimeEarliestHour =
                bit.band(bit.rshift(messageBytes[45], 3), 0x1F)
            proTable.reservationTimeEarliestMin =
                bit.band(messageBytes[45], 0x07)
            proTable.reservationTimeLatestHour =
                bit.band(bit.rshift(messageBytes[46], 3), 0x1F)
            proTable.reservationTimeLatestMin = bit.band(messageBytes[46], 0x07)
        end
    end
    if (dataType == 0x03) or (dataType == 0x06) then
        if messageBytes[0] == 0xFE then
            proTable.errorCode = bit.lshift(messageBytes[2], 8) +
                                     messageBytes[1]
            proTable.errorMin = messageBytes[3]
            proTable.errorHour = messageBytes[4]
            proTable.errorDay = messageBytes[5]
            proTable.errorMonth = messageBytes[6]
            proTable.errorYear = bit.lshift(messageBytes[8], 8) +
                                     messageBytes[7]
            local firmTab = {}
            for i = 1, 7 do firmTab[i] = messageBytes[8 + i] end
            local firmTabStr = table2string(firmTab)
            proTable.firm = string2hexstring(firmTabStr)
            local mnTab = {}
            for i = 1, 18 do mnTab[i] = messageBytes[15 + i] end
            local mnTabStr = table2string(mnTab)
            proTable.machineName = string2hexstring(mnTabStr)
            local e2promTab = {}
            for i = 1, 1025 do e2promTab[i] = messageBytes[33 + i] end
            local e2promTabStr = table2string(e2promTab)
            proTable.e2prom = string2hexstring(e2promTabStr)
            proTable.reservationHour = messageBytes[1060]
            proTable.reservationMin = messageBytes[1061]
            proTable.dryClothWeight = messageBytes[1062]
            proTable.wetClothWeight = messageBytes[1063]
            proTable.operationStartTimeHour = messageBytes[1064]
            proTable.operationStartTimeMin = messageBytes[1065]
            proTable.operationEndTimeHour = messageBytes[1066]
            proTable.operationEndTimeMin = messageBytes[1067]
            proTable.remainTimeHour = messageBytes[1068]
            proTable.remainTimeMin = messageBytes[1069]
            proTable.operationTimeHour = messageBytes[1070]
            proTable.operationTimeMin = messageBytes[1071]
            proTable.presenceDetergent = messageBytes[1072]
        end
    end
    if (dataType == 0x04) then
        if messageBytes[0] == 0x00 then
            local temp
            proTable.command = messageBytes[1]
            proTable.mode = messageBytes[2]
            proTable.program = messageBytes[3]
            proTable.reservationMin = messageBytes[4]
            proTable.reservationHour = messageBytes[5]
            proTable.timeSec = messageBytes[6]
            proTable.timeMin = messageBytes[7]
            proTable.timeHour = messageBytes[8]
            proTable.washTime = messageBytes[9]
            proTable.rinsePour = messageBytes[10]
            proTable.dehydrationTime = messageBytes[11]
            proTable.dry = messageBytes[12]
            proTable.washRinse = bit.band(messageBytes[13], 0x07)
            proTable.ufb = bit.band(messageBytes[13], 0x80)
            proTable.temperature = messageBytes[14]
            proTable.lock = bit.band(messageBytes[15], 0x01)
            proTable.tubAutoClean = bit.band(messageBytes[15], 0x02)
            proTable.buzzer = bit.band(messageBytes[15], 0x04)
            proTable.rinseMode = bit.band(messageBytes[15], 0x08)
            proTable.lowNoise = bit.band(messageBytes[15], 0x10)
            proTable.energySaving = bit.band(messageBytes[15], 0x20)
            proTable.hotWaterFifteen = bit.band(messageBytes[15], 0x40)
            proTable.dryFinishAdjust = bit.band(messageBytes[16], 0x07)
            proTable.spinRotateAdjust = bit.band(
                                            bit.rshift(messageBytes[16], 3),
                                            0x03)
            proTable.fungusProtect = bit.band(messageBytes[16], 0x20)
            proTable.drainBubbleProtect = bit.band(messageBytes[16], 0x40)
            proTable.defaultDry = bit.band(messageBytes[17], 0x03)
            proTable.processInfo = messageBytes[18]
            proTable.processDetail = messageBytes[19]
            proTable.error = bit.lshift(messageBytes[21], 8) + messageBytes[20]
            proTable.machineStatus = messageBytes[22]
            proTable.remainTime =
                messageBytes[26] * 16777216 + messageBytes[25] * 65536 +
                    messageBytes[24] * 256 + messageBytes[23]
            proTable.doorOpen = bit.band(messageBytes[27], 0x01)
            proTable.remainTimeAdjust = bit.band(messageBytes[27], 0x02)
            proTable.drainFilterClean = bit.band(messageBytes[27], 0x04)
            proTable.tubHighHot = bit.band(messageBytes[27], 0x08)
            proTable.waterHighTemperature = bit.band(messageBytes[27], 0x10)
            proTable.tubWaterExist = bit.band(messageBytes[27], 0x20)
            proTable.overCapacity = bit.band(messageBytes[27], 0x40)
            proTable.drainFilterCare = bit.band(messageBytes[28], 0x01)
            proTable.dryFilterClean = bit.band(messageBytes[28], 0x02)
            proTable.appCourseNumber = bit.band(bit.rshift(messageBytes[28], 2),
                                                0x0f)
            proTable.reservationMode = messageBytes[29]
            proTable.operationWashTime = messageBytes[30]
            proTable.operationWashRinseTimes = messageBytes[31]
            proTable.operationWashSpinTime = messageBytes[32]
            proTable.operationWashDryerTime = messageBytes[33]
            proTable.operationWashDryerRinseTimes = messageBytes[34]
            proTable.operationWashDryerSpinTime = messageBytes[35]
            proTable.operationWashDryerDrySet = messageBytes[36]
            proTable.operationDryerDrySet = messageBytes[37]
            proTable.detergentRemain = bit.band(messageBytes[38], 0x0F)
            temp = bit.rshift(messageBytes[38], 4)
            proTable.detergentRemainExplanation = bit.band(temp, 0x07)
            proTable.detergentSetting = bit.rshift(messageBytes[38], 7)
            proTable.softnerRemain = bit.band(messageBytes[39], 0x0F)
            temp = bit.rshift(messageBytes[39], 4)
            proTable.softnerRemainExplanation = bit.band(temp, 0x07)
            proTable.softnerSetting = bit.rshift(messageBytes[39], 7)
            proTable.detergentName = messageBytes[40]
            proTable.softnerName = messageBytes[41]
            proTable.detergentMeasure = messageBytes[42]
            proTable.softnerMeasure = messageBytes[43]
            proTable.beginProcess = messageBytes[44]
            proTable.reservationTimeEarliestHour =
                bit.band(bit.rshift(messageBytes[45], 3), 0x1F)
            proTable.reservationTimeEarliestMin =
                bit.band(messageBytes[45], 0x07)
            proTable.reservationTimeLatestHour =
                bit.band(bit.rshift(messageBytes[46], 3), 0x1F)
            proTable.reservationTimeLatestMin = bit.band(messageBytes[46], 0x07)
        end
    end
    if (dataType == 0x06) then
        if messageBytes[0] == 0x20 then
            proTable.mode = messageBytes[1]
            proTable.program = messageBytes[2]
            proTable.washTime = messageBytes[3]
            proTable.rinsePour = messageBytes[4]
            proTable.dehydrationTime = messageBytes[5]
            proTable.dry = messageBytes[6]
            proTable.temperature = messageBytes[7]
            proTable.washRinse = bit.band(messageBytes[8], 0x07)
            proTable.ufb = bit.band(messageBytes[8], 0x80)
            proTable.courseConfirmNumber = messageBytes[9]
        end
    end
    if (dataType == 0x02) or (dataType == 0x04) or (dataType == 0x05) then
        if messageBytes[0] == 0x10 then
            proTable.response_status = messageBytes[1]
            proTable.wash_course_one_program = messageBytes[11]
            proTable.wash_course_one_wash_time = messageBytes[12]
            proTable.wash_course_one_rinse_pour = messageBytes[13]
            proTable.wash_course_one_dehydration_time = messageBytes[14]
            proTable.wash_course_one_dry = messageBytes[15]
            proTable.wash_course_one_temperature = messageBytes[16]
            proTable.wash_course_one_wash_rinse =
                bit.band(messageBytes[17], 0x07)
            proTable.wash_course_one_ufb = bit.band(messageBytes[17], 0x80)
            proTable.wash_course_one_base_program = messageBytes[18]
            proTable.wash_course_two_program = messageBytes[21]
            proTable.wash_course_two_wash_time = messageBytes[22]
            proTable.wash_course_two_rinse_pour = messageBytes[23]
            proTable.wash_course_two_dehydration_time = messageBytes[24]
            proTable.wash_course_two_dry = messageBytes[25]
            proTable.wash_course_two_temperature = messageBytes[26]
            proTable.wash_course_two_wash_rinse =
                bit.band(messageBytes[27], 0x07)
            proTable.wash_course_two_ufb = bit.band(messageBytes[27], 0x80)
            proTable.wash_course_two_base_program = messageBytes[28]
            proTable.wash_course_three_program = messageBytes[31]
            proTable.wash_course_three_wash_time = messageBytes[32]
            proTable.wash_course_three_rinse_pour = messageBytes[33]
            proTable.wash_course_three_dehydration_time = messageBytes[34]
            proTable.wash_course_three_dry = messageBytes[35]
            proTable.wash_course_three_temperature = messageBytes[36]
            proTable.wash_course_three_wash_rinse =
                bit.band(messageBytes[37], 0x07)
            proTable.wash_course_three_ufb = bit.band(messageBytes[37], 0x80)
            proTable.wash_course_three_base_program = messageBytes[38]
            proTable.wash_dry_course_one_program = messageBytes[41]
            proTable.wash_dry_course_one_wash_time = messageBytes[42]
            proTable.wash_dry_course_one_rinse_pour = messageBytes[43]
            proTable.wash_dry_course_one_dehydration_time = messageBytes[44]
            proTable.wash_dry_course_one_dry = messageBytes[45]
            proTable.wash_dry_course_one_temperature = messageBytes[46]
            proTable.wash_dry_course_one_wash_rinse =
                bit.band(messageBytes[47], 0x07)
            proTable.wash_dry_course_one_ufb = bit.band(messageBytes[47], 0x80)
            proTable.wash_dry_course_one_base_program = messageBytes[48]
            proTable.wash_dry_course_two_program = messageBytes[51]
            proTable.wash_dry_course_two_wash_time = messageBytes[52]
            proTable.wash_dry_course_two_rinse_pour = messageBytes[53]
            proTable.wash_dry_course_two_dehydration_time = messageBytes[54]
            proTable.wash_dry_course_two_dry = messageBytes[55]
            proTable.wash_dry_course_two_temperature = messageBytes[56]
            proTable.wash_dry_course_two_wash_rinse =
                bit.band(messageBytes[57], 0x07)
            proTable.wash_dry_course_two_ufb = bit.band(messageBytes[57], 0x80)
            proTable.wash_dry_course_two_base_program = messageBytes[58]
            proTable.wash_dry_course_three_program = messageBytes[61]
            proTable.wash_dry_course_three_wash_time = messageBytes[62]
            proTable.wash_dry_course_three_rinse_pour = messageBytes[63]
            proTable.wash_dry_course_three_dehydration_time = messageBytes[64]
            proTable.wash_dry_course_three_dry = messageBytes[65]
            proTable.wash_dry_course_three_temperature = messageBytes[66]
            proTable.wash_dry_course_three_wash_rinse = bit.band(
                                                            messageBytes[67],
                                                            0x07)
            proTable.wash_dry_course_three_ufb =
                bit.band(messageBytes[67], 0x80)
            proTable.wash_dry_course_three_base_program = messageBytes[68]
        end
    end
    if (dataType == 0x05) then
        if messageBytes[0] == 0x30 then
            proTable.inventoryUsageType = messageBytes[1]
            proTable.inventoryUsageAmount = messageBytes[2]
            proTable.inventoryUsageAccumulatedAmount = bit.lshift(
                                                           messageBytes[3], 8) +
                                                           messageBytes[4]
        end
    end
end
local function assembleMode(streams, key, value)
    if value == 0x00 then
        streams[key] = "none"
    elseif value == 0x01 then
        streams[key] = "wash_dry"
    elseif value == 0x02 then
        streams[key] = "wash"
    elseif value == 0x03 then
        streams[key] = "dry"
    elseif value == 0x04 then
        streams[key] = "clean_care"
    elseif value == 0x05 then
        streams[key] = "care"
    end
end
local function assembleProgram(streams, key, value)
    if value == 0x00 then
        streams[key] = "none"
    elseif value == 0x01 then
        streams[key] = "standard"
    elseif value == 0x02 then
        streams[key] = "tub_clean"
    elseif value == 0x03 then
        streams[key] = "fast"
    elseif value == 0x04 then
        streams[key] = "careful"
    elseif value == 0x05 then
        streams[key] = "sixty_wash"
    elseif value == 0x06 then
        streams[key] = "blanket"
    elseif value == 0x07 then
        streams[key] = "delicate"
    elseif value == 0x08 then
        streams[key] = "tub_clean_dry"
    elseif value == 0x09 then
        streams[key] = "memory"
    elseif value == 0x0A then
        streams[key] = "sterilization"
    elseif value == 0x0B then
        streams[key] = "mute"
    elseif value == 0x0C then
        streams[key] = "soft"
    elseif value == 0x0D then
        streams[key] = "delicate_dryer"
    elseif value == 0x0E then
        streams[key] = "soak"
    elseif value == 0x0F then
        streams[key] = "odor_eliminating"
    elseif value == 0x10 then
        streams[key] = "empty"
    elseif value == 0x11 then
        streams[key] = "degerm"
    elseif value == 0x12 then
        streams[key] = "auto_care"
    elseif value == 0x13 then
        streams[key] = "auto_twice_wash"
    elseif value == 0x14 then
        streams[key] = "prewash_plus"
    elseif value == 0x15 then
        streams[key] = "uv_wash_and_dry"
    elseif value == 0x16 then
        streams[key] = "uv_dry_with_rotation"
    elseif value == 0x17 then
        streams[key] = "uv_dry_without_rotation"
    elseif value == 0x18 then
        streams[key] = "forty_five_wash"
    elseif value == 0x1C then
        streams[key] = "fragrant_and_delicate"
    elseif value == 0x1D then
        streams[key] = "tick_extermination"
    elseif value == 0x1E then
        streams[key] = "pollen"
    elseif value == 0x21 then
        streams[key] = "app_course_1"
    elseif value == 0x22 then
        streams[key] = "app_course_2"
    elseif value == 0x23 then
        streams[key] = "app_course_3"
    elseif value == 0x24 then
        streams[key] = "app_course"
    elseif value == 0x25 then
        streams[key] = "uv_wash"
    elseif value == 0x26 then
        streams[key] = "uv_without_rotation"
    elseif value == 0x27 then
        streams[key] = "uv_with_rotation"
    elseif value == 0x28 then
        streams[key] = "uv_deodorize_without_rotation"
    elseif value == 0x29 then
        streams[key] = "uv_deodorize_with_rotation"
    elseif value == 0x30 then
        streams[key] = "60_tub_clean"
    elseif value == 0x51 then
        streams[key] = "sheets"
    elseif value == 0x52 then
        streams[key] = "lace_curtain"
    elseif value == 0x53 then
        streams[key] = "towel"
    elseif value == 0x54 then
        streams[key] = "fleece"
    elseif value == 0x55 then
        streams[key] = "school_uniform_or_washable"
    elseif value == 0x56 then
        streams[key] = "slacks_skirt"
    elseif value == 0x57 then
        streams[key] = "jeans"
    elseif value == 0x58 then
        streams[key] = "cap"
    elseif value == 0x59 then
        streams[key] = "down_jacket"
    elseif value == 0x5A then
        streams[key] = "bet_putt"
    elseif value == 0x5B then
        streams[key] = "functional_underwear"
    elseif value == 0x5C then
        streams[key] = "reusable_bag"
    elseif value == 0x5D then
        streams[key] = "duvet"
    elseif value == 0x5E then
        streams[key] = "t_shirt_recovery"
    elseif value == 0x5F then
        streams[key] = "sports_wear"
    elseif value == 0x81 then
        streams[key] = "light_dirt"
    elseif value == 0x82 then
        streams[key] = "wash_thoroughly_and_rinse"
    elseif value == 0x83 then
        streams[key] = "quick_wash_and_dry"
    elseif value == 0x84 then
        streams[key] = "yellowing_off"
    elseif value == 0x85 then
        streams[key] = "disinfection_clothing"
    elseif value == 0x86 then
        streams[key] = "keep_water_temperature"
    elseif value == 0x87 then
        streams[key] = "prewash"
    elseif value == 0x91 then
        streams[key] = "super_concentrated_soak"
    elseif value == 0x92 then
        streams[key] = "no_rinse_and_delicate"
    elseif value == 0x93 then
        streams[key] = "t_shirt_recovery_pro"
    elseif value == 0xA0 then
        streams[key] = "customize"
    end
end
local function assembleWashTime(streams, key, value)
    if value == 0x81 then
        streams[key] = 1 * 60
    elseif value == 0x82 then
        streams[key] = 2 * 60
    elseif value == 0x83 then
        streams[key] = 3 * 60
    elseif value == 0x84 then
        streams[key] = 4 * 60
    elseif value == 0x85 then
        streams[key] = 5 * 60
    elseif value == 0x86 then
        streams[key] = 6 * 60
    elseif value == 0x87 then
        streams[key] = 7 * 60
    elseif value == 0x88 then
        streams[key] = 8 * 60
    elseif value == 0x89 then
        streams[key] = 9 * 60
    elseif value == 0x8A then
        streams[key] = 10 * 60
    elseif value == 0x8B then
        streams[key] = 11 * 60
    elseif value == 0x8C then
        streams[key] = 12 * 60
    else
        streams[key] = value
    end
end
local function assembleWashRinse(streams, key, value)
    if value == 0x00 then
        streams[key] = "none"
    elseif value == 0x01 then
        streams[key] = "wash"
    elseif value == 0x02 then
        streams[key] = "wash_to_rinse"
    elseif value == 0x03 then
        streams[key] = "rinse"
    end
end
local function assembleUFB(streams, key, value)
    if value == 0x00 then
        streams[key] = "off"
    elseif value == 0x80 then
        streams[key] = "on"
    end
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[keyTable.KEY_VERSION] = version
    if (subDataType == 0x00) then
        streams[keyTable.KEY_FUNCTION_TYPE] = "base"
        if proTable.command == 0x01 then
            streams[keyTable.KEY_COMMAND] = "temporary_stop"
        elseif proTable.command == 0x02 then
            streams[keyTable.KEY_COMMAND] = "reservation_fix"
        elseif proTable.command == 0x03 then
            streams[keyTable.KEY_COMMAND] = "reservation_cancel"
        elseif proTable.command == 0x04 then
            streams[keyTable.KEY_COMMAND] = "reservation_start"
        elseif proTable.command == 0x05 then
            streams[keyTable.KEY_COMMAND] = "reservation_set"
        elseif proTable.command == 0x06 then
            streams[keyTable.KEY_COMMAND] = "finish"
        elseif proTable.command == 0x07 then
            streams[keyTable.KEY_COMMAND] = "auto_dispenser_setting_change"
        else
            streams[keyTable.KEY_COMMAND] = "none"
        end
        if proTable.mode == 0x00 then
            streams[keyTable.KEY_MODE] = "none"
        elseif proTable.mode == 0x01 then
            streams[keyTable.KEY_MODE] = "wash_dry"
        elseif proTable.mode == 0x02 then
            streams[keyTable.KEY_MODE] = "wash"
        elseif proTable.mode == 0x03 then
            streams[keyTable.KEY_MODE] = "dry"
        elseif proTable.mode == 0x04 then
            streams[keyTable.KEY_MODE] = "clean_care"
        elseif proTable.mode == 0x05 then
            streams[keyTable.KEY_MODE] = "care"
        end
        if proTable.program == 0x00 then
            streams[keyTable.KEY_PROGRAM] = "none"
        elseif proTable.program == 0x01 then
            streams[keyTable.KEY_PROGRAM] = "standard"
        elseif proTable.program == 0x02 then
            streams[keyTable.KEY_PROGRAM] = "tub_clean"
        elseif proTable.program == 0x03 then
            streams[keyTable.KEY_PROGRAM] = "fast"
        elseif proTable.program == 0x04 then
            streams[keyTable.KEY_PROGRAM] = "careful"
        elseif proTable.program == 0x05 then
            streams[keyTable.KEY_PROGRAM] = "sixty_wash"
        elseif proTable.program == 0x06 then
            streams[keyTable.KEY_PROGRAM] = "blanket"
        elseif proTable.program == 0x07 then
            streams[keyTable.KEY_PROGRAM] = "delicate"
        elseif proTable.program == 0x08 then
            streams[keyTable.KEY_PROGRAM] = "tub_clean_dry"
        elseif proTable.program == 0x09 then
            streams[keyTable.KEY_PROGRAM] = "memory"
        elseif proTable.program == 0x0A then
            streams[keyTable.KEY_PROGRAM] = "sterilization"
        elseif proTable.program == 0x0B then
            streams[keyTable.KEY_PROGRAM] = "mute"
        elseif proTable.program == 0x0C then
            streams[keyTable.KEY_PROGRAM] = "soft"
        elseif proTable.program == 0x0D then
            streams[keyTable.KEY_PROGRAM] = "delicate_dryer"
        elseif proTable.program == 0x0E then
            streams[keyTable.KEY_PROGRAM] = "soak"
        elseif proTable.program == 0x0F then
            streams[keyTable.KEY_PROGRAM] = "odor_eliminating"
        elseif proTable.program == 0x10 then
            streams[keyTable.KEY_PROGRAM] = "empty"
        elseif proTable.program == 0x11 then
            streams[keyTable.KEY_PROGRAM] = "degerm"
        elseif proTable.program == 0x12 then
            streams[keyTable.KEY_PROGRAM] = "auto_care"
        elseif proTable.program == 0x13 then
            streams[keyTable.KEY_PROGRAM] = "auto_twice_wash"
        elseif proTable.program == 0x14 then
            streams[keyTable.KEY_PROGRAM] = "prewash_plus"
        elseif proTable.program == 0x15 then
            streams[keyTable.KEY_PROGRAM] = "uv_wash_and_dry"
        elseif proTable.program == 0x16 then
            streams[keyTable.KEY_PROGRAM] = "uv_dry_with_rotation"
        elseif proTable.program == 0x17 then
            streams[keyTable.KEY_PROGRAM] = "uv_dry_without_rotation"
        elseif proTable.program == 0x18 then
            streams[keyTable.KEY_PROGRAM] = "forty_five_wash"
        elseif proTable.program == 0x1C then
            streams[keyTable.KEY_PROGRAM] = "fragrant_and_delicate"
        elseif proTable.program == 0x1D then
            streams[keyTable.KEY_PROGRAM] = "tick_extermination"
        elseif proTable.program == 0x1E then
            streams[keyTable.KEY_PROGRAM] = "pollen"
        elseif proTable.program == 0x21 then
            streams[keyTable.KEY_PROGRAM] = "app_course_1"
        elseif proTable.program == 0x22 then
            streams[keyTable.KEY_PROGRAM] = "app_course_2"
        elseif proTable.program == 0x23 then
            streams[keyTable.KEY_PROGRAM] = "app_course_3"
        elseif proTable.program == 0x24 then
            streams[keyTable.KEY_PROGRAM] = "app_course"
        elseif proTable.program == 0x25 then
            streams[keyTable.KEY_PROGRAM] = "uv_wash"
        elseif proTable.program == 0x26 then
            streams[keyTable.KEY_PROGRAM] = "uv_without_rotation"
        elseif proTable.program == 0x27 then
            streams[keyTable.KEY_PROGRAM] = "uv_with_rotation"
        elseif proTable.program == 0x28 then
            streams[keyTable.KEY_PROGRAM] = "uv_deodorize_without_rotation"
        elseif proTable.program == 0x29 then
            streams[keyTable.KEY_PROGRAM] = "uv_deodorize_with_rotation"
        elseif proTable.program == 0x30 then
            streams[keyTable.KEY_PROGRAM] = "60_tub_clean"
        elseif proTable.program == 0x51 then
            streams[keyTable.KEY_PROGRAM] = "sheets"
        elseif proTable.program == 0x52 then
            streams[keyTable.KEY_PROGRAM] = "lace_curtain"
        elseif proTable.program == 0x53 then
            streams[keyTable.KEY_PROGRAM] = "towel"
        elseif proTable.program == 0x54 then
            streams[keyTable.KEY_PROGRAM] = "fleece"
        elseif proTable.program == 0x55 then
            streams[keyTable.KEY_PROGRAM] = "school_uniform_or_washable"
        elseif proTable.program == 0x56 then
            streams[keyTable.KEY_PROGRAM] = "slacks_skirt"
        elseif proTable.program == 0x57 then
            streams[keyTable.KEY_PROGRAM] = "jeans"
        elseif proTable.program == 0x58 then
            streams[keyTable.KEY_PROGRAM] = "cap"
        elseif proTable.program == 0x59 then
            streams[keyTable.KEY_PROGRAM] = "down_jacket"
        elseif proTable.program == 0x5A then
            streams[keyTable.KEY_PROGRAM] = "bet_putt"
        elseif proTable.program == 0x5B then
            streams[keyTable.KEY_PROGRAM] = "functional_underwear"
        elseif proTable.program == 0x5C then
            streams[keyTable.KEY_PROGRAM] = "reusable_bag"
        elseif proTable.program == 0x5D then
            streams[keyTable.KEY_PROGRAM] = "duvet"
        elseif proTable.program == 0x5E then
            streams[keyTable.KEY_PROGRAM] = "t_shirt_recovery"
        elseif proTable.program == 0x5F then
            streams[keyTable.KEY_PROGRAM] = "sports_wear"
        elseif proTable.program == 0x81 then
            streams[keyTable.KEY_PROGRAM] = "light_dirt"
        elseif proTable.program == 0x82 then
            streams[keyTable.KEY_PROGRAM] = "wash_thoroughly_and_rinse"
        elseif proTable.program == 0x83 then
            streams[keyTable.KEY_PROGRAM] = "quick_wash_and_dry"
        elseif proTable.program == 0x84 then
            streams[keyTable.KEY_PROGRAM] = "yellowing_off"
        elseif proTable.program == 0x85 then
            streams[keyTable.KEY_PROGRAM] = "disinfection_clothing"
        elseif proTable.program == 0x86 then
            streams[keyTable.KEY_PROGRAM] = "keep_water_temperature"
        elseif proTable.program == 0x87 then
            streams[keyTable.KEY_PROGRAM] = "prewash"
        elseif proTable.program == 0x91 then
            streams[keyTable.KEY_PROGRAM] = "super_concentrated_soak"
        elseif proTable.program == 0x92 then
            streams[keyTable.KEY_PROGRAM] = "no_rinse_and_delicate"
        elseif proTable.program == 0x93 then
            streams[keyTable.KEY_PROGRAM] = "t_shirt_recovery_pro"
        elseif proTable.program == 0xA0 then
            streams[keyTable.KEY_PROGRAM] = "customize"
        end
        streams[keyTable.KEY_RESERVATION_HOUR] = proTable.reservationHour
        streams[keyTable.KEY_RESERVATION_MIN] = proTable.reservationMin
        streams[keyTable.KEY_TIME_HOUR] = proTable.timeHour
        streams[keyTable.KEY_TIME_MIN] = proTable.timeMin
        streams[keyTable.KEY_TIME_SEC] = proTable.timeSec
        if proTable.washTime == 0x81 then
            streams[keyTable.KEY_WASH_TIME] = 1 * 60
        elseif proTable.washTime == 0x82 then
            streams[keyTable.KEY_WASH_TIME] = 2 * 60
        elseif proTable.washTime == 0x83 then
            streams[keyTable.KEY_WASH_TIME] = 3 * 60
        elseif proTable.washTime == 0x84 then
            streams[keyTable.KEY_WASH_TIME] = 4 * 60
        elseif proTable.washTime == 0x85 then
            streams[keyTable.KEY_WASH_TIME] = 5 * 60
        elseif proTable.washTime == 0x86 then
            streams[keyTable.KEY_WASH_TIME] = 6 * 60
        elseif proTable.washTime == 0x87 then
            streams[keyTable.KEY_WASH_TIME] = 7 * 60
        elseif proTable.washTime == 0x88 then
            streams[keyTable.KEY_WASH_TIME] = 8 * 60
        elseif proTable.washTime == 0x89 then
            streams[keyTable.KEY_WASH_TIME] = 9 * 60
        elseif proTable.washTime == 0x8A then
            streams[keyTable.KEY_WASH_TIME] = 10 * 60
        elseif proTable.washTime == 0x8B then
            streams[keyTable.KEY_WASH_TIME] = 11 * 60
        elseif proTable.washTime == 0x8C then
            streams[keyTable.KEY_WASH_TIME] = 12 * 60
        else
            streams[keyTable.KEY_WASH_TIME] = proTable.washTime
        end
        streams[keyTable.KEY_RINSE_POUR] = proTable.rinsePour
        streams[keyTable.KEY_DEHYDRATION_TIME] = proTable.dehydrationTime
        streams[keyTable.KEY_DRY] = proTable.dry
        if proTable.washRinse == 0x00 then
            streams[keyTable.KEY_WASH_RISE] = "none"
        elseif proTable.washRinse == 0x01 then
            streams[keyTable.KEY_WASH_RISE] = "wash"
        elseif proTable.washRinse == 0x02 then
            streams[keyTable.KEY_WASH_RISE] = "wash_to_rinse"
        elseif proTable.washRinse == 0x03 then
            streams[keyTable.KEY_WASH_RISE] = "rinse"
        elseif proTable.washRinse == 0x07 then
            streams[keyTable.KEY_WASH_RISE] = "hidden"
        end
        if proTable.ufb == 0x00 then
            streams[keyTable.KEY_UFB] = "off"
        elseif proTable.ufb == 0x80 then
            streams[keyTable.KEY_UFB] = "on"
        end
        streams[keyTable.KEY_TEMPERATURE] = proTable.temperature
        if proTable.lock == 0x01 then
            streams[keyTable.KEY_LOCK] = "on"
        elseif proTable.lock == 0x00 then
            streams[keyTable.KEY_LOCK] = "off"
        end
        if proTable.tubAutoClean == 0x02 then
            streams[keyTable.KEY_TUB_AUTO_CLEAN] = "on"
        elseif proTable.tubAutoClean == 0x00 then
            streams[keyTable.KEY_TUB_AUTO_CLEAN] = "off"
        end
        if proTable.buzzer == 0x04 then
            streams[keyTable.KEY_BUZZER] = "on"
        elseif proTable.buzzer == 0x00 then
            streams[keyTable.KEY_BUZZER] = "off"
        end
        if proTable.rinseMode == 0x08 then
            streams[keyTable.KEY_RINSE_MODE] = "on"
        elseif proTable.rinseMode == 0x00 then
            streams[keyTable.KEY_RINSE_MODE] = "off"
        end
        if proTable.lowNoise == 0x10 then
            streams[keyTable.KEY_LOW_NOISE] = "on"
        elseif proTable.lowNoise == 0x00 then
            streams[keyTable.KEY_LOW_NOISE] = "off"
        end
        if proTable.energySaving == 0x20 then
            streams[keyTable.KEY_ENERGY_SAVING] = "on"
        elseif proTable.energySaving == 0x00 then
            streams[keyTable.KEY_ENERGY_SAVING] = "off"
        end
        if proTable.hotWaterFifteen == 0x40 then
            streams[keyTable.KEY_HOT_WATER_FIFTEEN] = "on"
        elseif proTable.hotWaterFifteen == 0x00 then
            streams[keyTable.KEY_HOT_WATER_FIFTEEN] = "off"
        end
        streams[keyTable.KEY_DRY_FINISH_ADJUST] = proTable.dryFinishAdjust
        streams[keyTable.KEY_SPIN_ROTATE_ADJUST] = proTable.spinRotateAdjust
        if proTable.fungusProtect == 0x20 then
            streams[keyTable.KEY_FUNGUS_PROTECT] = "on"
        elseif proTable.fungusProtect == 0x00 then
            streams[keyTable.KEY_FUNGUS_PROTECT] = "off"
        end
        if proTable.drainBubbleProtect == 0x40 then
            streams[keyTable.KEY_DRAIN_BUBBLE_PROTECT] = "on"
        elseif proTable.drainBubbleProtect == 0x00 then
            streams[keyTable.KEY_DRAIN_BUBBLE_PROTECT] = "off"
        end
        if proTable.defaultDry == 0x01 then
            streams[keyTable.KEY_DEFAULT_DRY] = "speed"
        elseif proTable.defaultDry == 0x00 then
            streams[keyTable.KEY_DEFAULT_DRY] = "energy_saving"
        elseif proTable.defaultDry == 0x02 then
            streams[keyTable.KEY_DEFAULT_DRY] = "power_saving"
        end
        if bit.band(proTable.processInfo, 0x02) == 0x02 then
            streams[keyTable.KEY_PROCESS_INFO_WASH] = "yes"
        else
            streams[keyTable.KEY_PROCESS_INFO_WASH] = "no"
        end
        if bit.band(proTable.processInfo, 0x04) == 0x04 then
            streams[keyTable.KEY_PROCESS_INFO_RINSE] = "yes"
        else
            streams[keyTable.KEY_PROCESS_INFO_RINSE] = "no"
        end
        if bit.band(proTable.processInfo, 0x08) == 0x08 then
            streams[keyTable.KEY_PROCESS_INFO_SPIN] = "yes"
        else
            streams[keyTable.KEY_PROCESS_INFO_SPIN] = "no"
        end
        if bit.band(proTable.processInfo, 0x10) == 0x10 then
            streams[keyTable.KEY_PROCESS_INFO_DRY] = "yes"
        else
            streams[keyTable.KEY_PROCESS_INFO_DRY] = "no"
        end
        if bit.band(proTable.processInfo, 0x20) == 0x20 then
            streams[keyTable.KEY_PROCESS_INFO_SOFT_KEEP] = "yes"
        else
            streams[keyTable.KEY_PROCESS_INFO_SOFT_KEEP] = "no"
        end
        streams[keyTable.KEY_PROCESS_DETAIL] = proTable.processDetail
        streams[keyTable.KEY_ERROR] = proTable.error
        if proTable.machineStatus == 0x00 then
            streams[keyTable.KEY_MACHINE_STATUS] = "power_off"
        elseif proTable.machineStatus == 0x01 then
            streams[keyTable.KEY_MACHINE_STATUS] = "power_on"
        elseif proTable.machineStatus == 0x02 then
            streams[keyTable.KEY_MACHINE_STATUS] = "running"
        elseif proTable.machineStatus == 0x03 then
            streams[keyTable.KEY_MACHINE_STATUS] = "pause"
        elseif proTable.machineStatus == 0x04 then
            streams[keyTable.KEY_MACHINE_STATUS] = "finish"
        elseif proTable.machineStatus == 0x50 then
            streams[keyTable.KEY_MACHINE_STATUS] = "pop_up"
        end
        streams[keyTable.KEY_REMAIN_TIME] = proTable.remainTime
        if (proTable.doorOpen == 0x01) then
            streams[keyTable.KEY_DOOR_OPEN] = 0x01
        else
            streams[keyTable.KEY_DOOR_OPEN] = 0x00
        end
        if (proTable.remainTimeAdjust == 0x02) then
            streams[keyTable.KEY_REMAIN_TIME_ADJUST] = 0x01
        else
            streams[keyTable.KEY_REMAIN_TIME_ADJUST] = 0x00
        end
        if (proTable.drainFilterClean == 0x04) then
            streams[keyTable.KEY_DRAIN_FILTER_CLEAN] = 0x01
        else
            streams[keyTable.KEY_DRAIN_FILTER_CLEAN] = 0x00
        end
        if (proTable.tubHighHot == 0x08) then
            streams[keyTable.KEY_TUB_HIGH_HOT] = 0x01
        else
            streams[keyTable.KEY_TUB_HIGH_HOT] = 0x00
        end
        if (proTable.waterHighTemperature == 0x10) then
            streams[keyTable.KEY_WATER_HIGH_TEMPERATURE] = 0x01
        else
            streams[keyTable.KEY_WATER_HIGH_TEMPERATURE] = 0x00
        end
        if (proTable.tubWaterExist == 0x20) then
            streams[keyTable.KEY_TUB_WATER_EXIST] = 0x01
        else
            streams[keyTable.KEY_TUB_WATER_EXIST] = 0x00
        end
        if (proTable.overCapacity == 0x40) then
            streams[keyTable.KEY_OVER_CAPACITY] = 0x01
        else
            streams[keyTable.KEY_OVER_CAPACITY] = 0x00
        end
        streams[keyTable.KEY_DRAIN_FILTER_CARE] = proTable.drainFilterCare
        if (proTable.dryFilterClean == 0x02) then
            streams[keyTable.KEY_DRY_FILTER_CLEAN] = 0x01
        else
            streams[keyTable.KEY_DRY_FILTER_CLEAN] = 0x00
        end
        streams[keyTable.KEY_APP_COURSE_NUMBER] = proTable.appCourseNumber
        streams[keyTable.KEY_RESERVATION_MODE] = proTable.reservationMode
        streams[keyTable.KEY_OPERATION_WASH_TIME] = proTable.operationWashTime
        streams[keyTable.KEY_OPERATION_WASH_RINSE_TIMES] =
            proTable.operationWashRinseTimes
        streams[keyTable.KEY_OPERATION_WASH_SPIN_TIME] =
            proTable.operationWashSpinTime
        streams[keyTable.KEY_OPERATION_WASH_DRYER_TIME] =
            proTable.operationWashDryerTime
        streams[keyTable.KEY_OPERATION_WASH_DRYER_RINSE_TIMES] =
            proTable.operationWashDryerRinseTimes
        streams[keyTable.KEY_OPERATION_WASH_DRYER_SPIN_TIME] =
            proTable.operationWashDryerSpinTime
        streams[keyTable.KEY_OPERATION_WASH_DRYER_DRY_SET] =
            proTable.operationWashDryerDrySet
        streams[keyTable.KEY_OPERATION_DRYER_DRY_SET] =
            proTable.operationDryerDrySet
        streams[keyTable.KEY_DETERGENT_REMAIN] = proTable.detergentRemain
        streams[keyTable.KEY_DETERGENT_REMAIN_EXPLANATION] =
            proTable.detergentRemainExplanation
        if (proTable.detergentSetting == 0x01) then
            streams[keyTable.KEY_DETERGENT_SETTING] = "on"
        else
            streams[keyTable.KEY_DETERGENT_SETTING] = "off"
        end
        streams[keyTable.KEY_SOFTNER_REMAIN] = proTable.softnerRemain
        streams[keyTable.KEY_SOFTNER_REMAIN_EXPLANATION] =
            proTable.softnerRemainExplanation
        if (proTable.softnerSetting == 0x01) then
            streams[keyTable.KEY_SOFTNER_SETTING] = "on"
        else
            streams[keyTable.KEY_SOFTNER_SETTING] = "off"
        end
        streams[keyTable.KEY_DETERGENT_NAME] = proTable.detergentName
        streams[keyTable.KEY_SOFTNER_NAME] = proTable.softnerName
        streams[keyTable.KEY_DETERGENT_MEASURE] = proTable.detergentMeasure
        streams[keyTable.KEY_SOFTNER_MEASURE] = proTable.softnerMeasure
        if bit.band(proTable.beginProcess, 0x02) == 0x02 then
            streams[keyTable.KEY_BEGIN_PROCESS_WASH] = "yes"
        else
            streams[keyTable.KEY_BEGIN_PROCESS_WASH] = "no"
        end
        if bit.band(proTable.beginProcess, 0x04) == 0x04 then
            streams[keyTable.KEY_BEGIN_PROCESS_RINSE] = "yes"
        else
            streams[keyTable.KEY_BEGIN_PROCESS_RINSE] = "no"
        end
        if bit.band(proTable.beginProcess, 0x08) == 0x08 then
            streams[keyTable.KEY_BEGIN_PROCESS_SPIN] = "yes"
        else
            streams[keyTable.KEY_BEGIN_PROCESS_SPIN] = "no"
        end
        if bit.band(proTable.beginProcess, 0x10) == 0x10 then
            streams[keyTable.KEY_BEGIN_PROCESS_DRY] = "yes"
        else
            streams[keyTable.KEY_BEGIN_PROCESS_DRY] = "no"
        end
        if bit.band(proTable.beginProcess, 0x20) == 0x20 then
            streams[keyTable.KEY_BEGIN_PROCESS_SOFT_KEEP] = "yes"
        else
            streams[keyTable.KEY_BEGIN_PROCESS_SOFT_KEEP] = "no"
        end
        streams[keyTable.KEY_RESERVATION_TIME_EARLIEST_HOUR] =
            proTable.reservationTimeEarliestHour
        streams[keyTable.KEY_RESERVATION_TIME_EARLIEST_MIN] =
            proTable.reservationTimeEarliestMin * 10
        streams[keyTable.KEY_RESERVATION_TIME_LATEST_HOUR] =
            proTable.reservationTimeLatestHour
        streams[keyTable.KEY_RESERVATION_TIME_LATEST_MIN] =
            proTable.reservationTimeLatestMin * 10
    elseif (subDataType == 0x20) then
        streams[keyTable.KEY_FUNCTION_TYPE] = "app_course_confirm"
        assembleMode(streams, "course_confirm_mode", proTable.mode)
        assembleProgram(streams, "course_confirm_program", proTable.program)
        assembleWashTime(streams, "course_confirm_wash_time", proTable.washTime)
        streams["course_confirm_rinse_pour"] = proTable.rinsePour
        streams["course_confirm_dehydration_time"] = proTable.dehydrationTime
        streams["course_confirm_dry"] = proTable.dry
        streams["course_confirm_temperature"] = proTable.temperature
        assembleWashRinse(streams, "course_confirm_wash_rinse",
                          proTable.washRinse)
        assembleUFB(streams, "course_confirm_ufb", proTable.ufb)
        streams["course_confirm_number"] = proTable.courseConfirmNumber
    elseif (subDataType == 0x10) then
        streams[keyTable.KEY_FUNCTION_TYPE] = "app_course_receive"
        assembleProgram(streams, "wash_course_one_program",
                        proTable.wash_course_one_program)
        assembleWashTime(streams, "wash_course_one_wash_time",
                         proTable.wash_course_one_wash_time)
        streams["wash_course_one_rinse_pour"] =
            proTable.wash_course_one_rinse_pour
        streams["wash_course_one_dehydration_time"] =
            proTable.wash_course_one_dehydration_time
        streams["wash_course_one_dry"] = proTable.wash_course_one_dry
        streams["wash_course_one_temperature"] =
            proTable.wash_course_one_temperature
        assembleWashRinse(streams, "wash_course_one_wash_rinse",
                          proTable.wash_course_one_wash_rinse)
        assembleUFB(streams, "wash_course_one_ufb", proTable.wash_course_one_ufb)
        assembleProgram(streams, "wash_course_one_base_program",
                        proTable.wash_course_one_base_program)
        assembleProgram(streams, "wash_course_two_program",
                        proTable.wash_course_two_program)
        assembleWashTime(streams, "wash_course_two_wash_time",
                         proTable.wash_course_two_wash_time)
        streams["wash_course_two_rinse_pour"] =
            proTable.wash_course_two_rinse_pour
        streams["wash_course_two_dehydration_time"] =
            proTable.wash_course_two_dehydration_time
        streams["wash_course_two_dry"] = proTable.wash_course_two_dry
        streams["wash_course_two_temperature"] =
            proTable.wash_course_two_temperature
        assembleWashRinse(streams, "wash_course_two_wash_rinse",
                          proTable.wash_course_two_wash_rinse)
        assembleUFB(streams, "wash_course_two_ufb", proTable.wash_course_two_ufb)
        assembleProgram(streams, "wash_course_two_base_program",
                        proTable.wash_course_two_base_program)
        assembleProgram(streams, "wash_course_three_program",
                        proTable.wash_course_three_program)
        assembleWashTime(streams, "wash_course_three_wash_time",
                         proTable.wash_course_three_wash_time)
        streams["wash_course_three_rinse_pour"] =
            proTable.wash_course_three_rinse_pour
        streams["wash_course_three_dehydration_time"] =
            proTable.wash_course_three_dehydration_time
        streams["wash_course_three_dry"] = proTable.wash_course_three_dry
        streams["wash_course_three_temperature"] =
            proTable.wash_course_three_temperature
        assembleWashRinse(streams, "wash_course_three_wash_rinse",
                          proTable.wash_course_three_wash_rinse)
        assembleUFB(streams, "wash_course_three_ufb",
                    proTable.wash_course_three_ufb)
        assembleProgram(streams, "wash_course_three_base_program",
                        proTable.wash_course_three_base_program)
        assembleProgram(streams, "wash_dry_course_one_program",
                        proTable.wash_dry_course_one_program)
        assembleWashTime(streams, "wash_dry_course_one_wash_time",
                         proTable.wash_dry_course_one_wash_time)
        streams["wash_dry_course_one_rinse_pour"] =
            proTable.wash_dry_course_one_rinse_pour
        streams["wash_dry_course_one_dehydration_time"] =
            proTable.wash_dry_course_one_dehydration_time
        streams["wash_dry_course_one_dry"] = proTable.wash_dry_course_one_dry
        streams["wash_dry_course_one_temperature"] =
            proTable.wash_dry_course_one_temperature
        assembleWashRinse(streams, "wash_dry_course_one_wash_rinse",
                          proTable.wash_dry_course_one_wash_rinse)
        assembleUFB(streams, "wash_dry_course_one_ufb",
                    proTable.wash_dry_course_one_ufb)
        assembleProgram(streams, "wash_dry_course_one_base_program",
                        proTable.wash_dry_course_one_base_program)
        assembleProgram(streams, "wash_dry_course_two_program",
                        proTable.wash_dry_course_two_program)
        assembleWashTime(streams, "wash_dry_course_two_wash_time",
                         proTable.wash_dry_course_two_wash_time)
        streams["wash_dry_course_two_rinse_pour"] =
            proTable.wash_dry_course_two_rinse_pour
        streams["wash_dry_course_two_dehydration_time"] =
            proTable.wash_dry_course_two_dehydration_time
        streams["wash_dry_course_two_dry"] = proTable.wash_dry_course_two_dry
        streams["wash_dry_course_two_temperature"] =
            proTable.wash_dry_course_two_temperature
        assembleWashRinse(streams, "wash_dry_course_two_wash_rinse",
                          proTable.wash_dry_course_two_wash_rinse)
        assembleUFB(streams, "wash_dry_course_two_ufb",
                    proTable.wash_dry_course_two_ufb)
        assembleProgram(streams, "wash_dry_course_two_base_program",
                        proTable.wash_dry_course_two_base_program)
        assembleProgram(streams, "wash_dry_course_three_program",
                        proTable.wash_dry_course_three_program)
        assembleWashTime(streams, "wash_dry_course_three_wash_time",
                         proTable.wash_dry_course_three_wash_time)
        streams["wash_dry_course_three_rinse_pour"] =
            proTable.wash_dry_course_three_rinse_pour
        streams["wash_dry_course_three_dehydration_time"] =
            proTable.wash_dry_course_three_dehydration_time
        streams["wash_dry_course_three_dry"] =
            proTable.wash_dry_course_three_dry
        streams["wash_dry_course_three_temperature"] =
            proTable.wash_dry_course_three_temperature
        assembleWashRinse(streams, "wash_dry_course_three_wash_rinse",
                          proTable.wash_dry_course_three_wash_rinse)
        assembleUFB(streams, "wash_dry_course_three_ufb",
                    proTable.wash_dry_course_three_ufb)
        assembleProgram(streams, "wash_dry_course_three_base_program",
                        proTable.wash_dry_course_three_base_program)
    elseif (subDataType == 0x30) then
        streams[keyTable.KEY_FUNCTION_TYPE] = "inventory_usage"
        if (proTable.inventoryUsageType == 0x02) then
            streams["inventory_usage_type"] = "softener"
        else
            streams["inventory_usage_type"] = "detergent"
        end
        streams["inventory_usage_amount"] = proTable.inventoryUsageAmount
        streams["inventory_usage_accumulated_amount"] =
            proTable.inventoryUsageAccumulatedAmount
    else
        streams[keyTable.KEY_FUNCTION_TYPE] = "exception"
        streams["error_code"] = proTable.errorCode
        streams["error_year"] = proTable.errorYear
        streams["error_month"] = proTable.errorMonth
        streams["error_day"] = proTable.errorDay
        streams["error_hour"] = proTable.errorHour
        streams["error_min"] = proTable.errorMin
        streams["firm"] = proTable.firm
        streams["machine_name"] = proTable.machineName
        streams["e2prom"] = proTable.e2prom
        streams["dry_cloth_weight"] = proTable.dryClothWeight
        streams["wet_cloth_weight"] = proTable.wetClothWeight
        streams["operation_start_time_hour"] = proTable.operationStartTimeHour
        streams["operation_start_time_min"] = proTable.operationStartTimeMin
        streams["operation_end_time_hour"] = proTable.operationEndTimeHour
        streams["operation_end_time_min"] = proTable.operationEndTimeMin
        streams["remain_time_hour"] = proTable.remainTimeHour
        streams["remain_time_min"] = proTable.remainTimeMin
        streams["operation_time_hour"] = proTable.operationTimeHour
        streams["operation_time_min"] = proTable.operationTimeMin
        streams["presence_detergent"] = proTable.presenceDetergent
    end
    return streams
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        if (status) then updateGlobalPropertyValueByJson(status) end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyBytes = {}
        if (proTable.functionType == 0x10) then
            local bodyLength = 71
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
            bodyBytes[0] = 0x10
            bodyBytes[1] = proTable.response_status
            bodyBytes[11] = proTable.wash_course_one_program
            bodyBytes[12] = proTable.wash_course_one_wash_time
            bodyBytes[13] = proTable.wash_course_one_rinse_pour
            bodyBytes[14] = proTable.wash_course_one_dehydration_time
            bodyBytes[15] = proTable.wash_course_one_dry
            bodyBytes[16] = proTable.wash_course_one_temperature
            bodyBytes[17] = bit.bor(proTable.wash_course_one_wash_rinse,
                                    proTable.wash_course_one_ufb)
            bodyBytes[18] = proTable.wash_course_one_base_program
            bodyBytes[21] = proTable.wash_course_two_program
            bodyBytes[22] = proTable.wash_course_two_wash_time
            bodyBytes[23] = proTable.wash_course_two_rinse_pour
            bodyBytes[24] = proTable.wash_course_two_dehydration_time
            bodyBytes[25] = proTable.wash_course_two_dry
            bodyBytes[26] = proTable.wash_course_two_temperature
            bodyBytes[27] = bit.bor(proTable.wash_course_two_wash_rinse,
                                    proTable.wash_course_two_ufb)
            bodyBytes[28] = proTable.wash_course_two_base_program
            bodyBytes[31] = proTable.wash_course_three_program
            bodyBytes[32] = proTable.wash_course_three_wash_time
            bodyBytes[33] = proTable.wash_course_three_rinse_pour
            bodyBytes[34] = proTable.wash_course_three_dehydration_time
            bodyBytes[35] = proTable.wash_course_three_dry
            bodyBytes[36] = proTable.wash_course_three_temperature
            bodyBytes[37] = bit.bor(proTable.wash_course_three_wash_rinse,
                                    proTable.wash_course_three_ufb)
            bodyBytes[38] = proTable.wash_course_three_base_program
            bodyBytes[41] = proTable.wash_dry_course_one_program
            bodyBytes[42] = proTable.wash_dry_course_one_wash_time
            bodyBytes[43] = proTable.wash_dry_course_one_rinse_pour
            bodyBytes[44] = proTable.wash_dry_course_one_dehydration_time
            bodyBytes[45] = proTable.wash_dry_course_one_dry
            bodyBytes[46] = proTable.wash_dry_course_one_temperature
            bodyBytes[47] = bit.bor(proTable.wash_dry_course_one_wash_rinse,
                                    proTable.wash_dry_course_one_ufb)
            bodyBytes[48] = proTable.wash_dry_course_one_base_program
            bodyBytes[51] = proTable.wash_dry_course_two_program
            bodyBytes[52] = proTable.wash_dry_course_two_wash_time
            bodyBytes[53] = proTable.wash_dry_course_two_rinse_pour
            bodyBytes[54] = proTable.wash_dry_course_two_dehydration_time
            bodyBytes[55] = proTable.wash_dry_course_two_dry
            bodyBytes[56] = proTable.wash_dry_course_two_temperature
            bodyBytes[57] = bit.bor(proTable.wash_dry_course_two_wash_rinse,
                                    proTable.wash_dry_course_two_ufb)
            bodyBytes[58] = proTable.wash_dry_course_two_base_program
            bodyBytes[61] = proTable.wash_dry_course_three_program
            bodyBytes[62] = proTable.wash_dry_course_three_wash_time
            bodyBytes[63] = proTable.wash_dry_course_three_rinse_pour
            bodyBytes[64] = proTable.wash_dry_course_three_dehydration_time
            bodyBytes[65] = proTable.wash_dry_course_three_dry
            bodyBytes[66] = proTable.wash_dry_course_three_temperature
            bodyBytes[67] = bit.bor(proTable.wash_dry_course_three_wash_rinse,
                                    proTable.wash_dry_course_three_ufb)
            bodyBytes[68] = proTable.wash_dry_course_three_base_program
        else
            local bodyLength = 47
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
            bodyBytes[0] = 0x00
            bodyBytes[1] = proTable.command
            bodyBytes[2] = proTable.mode
            bodyBytes[3] = proTable.program
            bodyBytes[4] = proTable.reservationMin
            bodyBytes[5] = proTable.reservationHour
            bodyBytes[6] = proTable.timeSec
            bodyBytes[7] = proTable.timeMin
            bodyBytes[8] = proTable.timeHour
            bodyBytes[9] = proTable.washTime
            bodyBytes[10] = proTable.rinsePour
            bodyBytes[11] = proTable.dehydrationTime
            bodyBytes[12] = proTable.dry
            bodyBytes[13] = bit.bor(proTable.washRinse, proTable.ufb)
            bodyBytes[14] = proTable.temperature
            local byte15 = 0x00
            if proTable.lock ~= 0xff then
                byte15 = bit.bor(byte15, proTable.lock)
            end
            if proTable.tubAutoClean ~= 0xff then
                byte15 = bit.bor(byte15, proTable.tubAutoClean)
            end
            if proTable.buzzer ~= 0xff then
                byte15 = bit.bor(byte15, proTable.buzzer)
            end
            if proTable.rinseMode ~= 0xff then
                byte15 = bit.bor(byte15, proTable.rinseMode)
            end
            if proTable.lowNoise ~= 0xff then
                byte15 = bit.bor(byte15, proTable.lowNoise)
            end
            if proTable.energySaving ~= 0xff then
                byte15 = bit.bor(byte15, proTable.energySaving)
            end
            if proTable.hotWaterFifteen ~= 0xff then
                byte15 = bit.bor(byte15, proTable.hotWaterFifteen)
            end
            bodyBytes[15] = byte15
            local byte16 = 0x00
            if proTable.dryFinishAdjust ~= nil then
                byte16 = bit.bor(byte16, proTable.dryFinishAdjust)
            end
            if proTable.spinRotateAdjust ~= nil then
                byte16 = bit.bor(byte16,
                                 bit.lshift(proTable.spinRotateAdjust, 3))
            end
            if proTable.fungusProtect ~= nil then
                byte16 = bit.bor(byte16, proTable.fungusProtect)
            end
            if proTable.drainBubbleProtect ~= nil then
                byte16 = bit.bor(byte16, proTable.drainBubbleProtect)
            end
            bodyBytes[16] = byte16
            bodyBytes[17] = proTable.defaultDry
            local byte38 = 0x00
            local temp
            if proTable.detergentSetting ~= nil then
                temp = bit.lshift(proTable.detergentSetting, 7)
                byte38 = bit.bor(byte38, temp)
            end
            if proTable.detergentRemainExplanation ~= nil then
                temp = bit.lshift(proTable.detergentRemainExplanation, 4)
                temp = bit.band(temp, 0x70)
                byte38 = bit.bor(byte38, temp)
            end
            bodyBytes[38] = byte38
            local byte39 = 0x00
            if proTable.softnerSetting ~= nil then
                temp = bit.lshift(proTable.softnerSetting, 7)
                byte39 = bit.bor(byte39, temp)
            end
            if proTable.softnerRemainExplanation ~= nil then
                temp = bit.lshift(proTable.softnerRemainExplanation, 4)
                temp = bit.band(temp, 0x70)
                byte39 = bit.bor(byte39, temp)
            end
            bodyBytes[39] = byte39
            bodyBytes[40] = proTable.detergentName
            bodyBytes[41] = proTable.softnerName
            bodyBytes[42] = proTable.detergentMeasure
            bodyBytes[43] = proTable.softnerMeasure
        end
        msgBytes = assembleUart(bodyBytes, 0x0002)
    elseif (query) then
        local bodyBytes = {}
        bodyBytes[0] = 0x00
        msgBytes = assembleUart(bodyBytes, 0x0003)
    end
    local infoM = {}
    local length = #msgBytes + 1
    for i = 1, length do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decodeJsonToTable(jsonStr)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    local binData = json["msg"]["data"]
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[15]
    subDataType = byteData[17]
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end
