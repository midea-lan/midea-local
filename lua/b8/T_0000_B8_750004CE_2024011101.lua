local bit = require "bit"
local JSON = require("cjson")
local bit = require("bit")
local function dLog(str) end
local SN8 = "750004CE"
local VERSION = 1
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_DEVICE_TYPE = 0xB8
local CONTROL_TYPE_CODE = {none = 0x00, manual = 0x01, auto = 0x02}
local MOVEMENT_CODE = {
    none = 0x00,
    forward = 0x01,
    back = 0x02,
    left = 0x03,
    right = 0x04,
    forward_left = 0x05,
    forward_right = 0x06,
    back_left = 0x07,
    back_right = 0x08
}
local CLEAN_MODE_CODE = {
    none = 0x00,
    auto = 0x08,
    area = 0x09,
    zone_index = 0x0a,
    zone_rect = 0x0b,
    target_point = 0x0d
}
local FAN_LEVEL_CODE = {soft = 0x04, normal = 0x01, high = 0x02, super = 0x03}
local WATER_LEVEL_CODE = {low = 0x01, normal = 0x02, high = 0x03}
local WORK_CONTENT_CODE = {
    charge = 0x01,
    auto = 0x02,
    stop = 0x03,
    screw = 0x04
}
local SPEAK_LEVEL_CODE = {
    none = 0x00,
    off = 0x01,
    low = 0x02,
    normal = 0x03,
    high = 0x04
}
local SIMPLE_FUNCTION_CODE = {child_lock = 0x01}
local STATION_FUNCTION_CODE = {
    mop_clean = 0x01,
    dust_collect = 0x02,
    mop_clean_and_dust_collect = 0x03,
    drain = 0x04
}
local ERROR_TYPE_OF_A0A3 = {
    no = 0x00,
    can_fix = 0x01,
    reboot = 0x02,
    warning = 0x03
}
local ERROR_FIX_DESC_OF_A0A3 = {
    no = 0x0,
    fix_dust = 0x01,
    fix_wheel_hang = 0x02,
    fix_wheel_overload = 0x03,
    fix_side_brush_overload = 0x04,
    fix_roll_brush_overload = 0x05,
    fix_dust_engine = 0x06,
    fix_front_panel = 0x07,
    fix_radar_mask = 0x08,
    fix_drop_sensor = 0x09,
    fix_low_battery = 0x0A,
    fix_abnormal_posture = 0x0B,
    fix_laser_sensor = 0x0C,
    fix_edge_sensor = 0x0D,
    fix_start_in_forbid_area_1 = 0x0E,
    fix_start_in_strong_magnetic = 0x0F,
    fix_laser_sensor_blocked = 0x10,
    fix_mopping_board_dropped = 0x11,
    fix_slipping_and_jamming = 0x12,
    fix_multiple_recharge_attempts = 0x13,
    fix_vibration_drag_overload = 0x14,
    fix_wipe_disk_overload = 0x15,
    fix_water_tank_miss = 0x16,
    fix_wipe_disk_chip_fault = 0x17,
    fix_temperature_too_high = 0x18,
    fix_hair_cut_failed = 0x20,
    fix_mop_drop_out = 0x40,
    fix_rotate_time_out = 0x41,
    fix_no_base_station_in_map = 0x42,
    fix_in_forbid_area_or_no_back_route = 0x43,
    fix_max_retry_times_exceeded = 0x44,
    fix_auto_fix_radar_high_temperature_failed = 0x45,
    fix_reach_destination_failed = 0x50,
    fix_physical_collision_plate_occurred = 0x51,
    fix_start_in_forbid_virtual_area = 0x52,
    fix_wheel_suspension = 0x53,
    fix_out_station_failed = 0x54,
    fix_escape_environment_failed = 0x55,
    fix_inner_communication_timeout = 0x57,
    fix_use_sweep_and_mop_on_carpet = 0x58,
    fix_start_in_virtual_wall = 0x59,
    fix_start_in_forbid_area = 0x5a,
    fix_start_in_forbid_water_area = 0x5b,
    fix_start_in_forbid_area_2 = 0x5c,
    fix_trapped_in_small_area = 0x5d,
    fix_whole_house_clean_with_wrong_partition = 0x5e,
    fix_radar_data_blocked = 0xa0
}
local ERROR_REBOOT_DESC = {
    no = 0x00,
    reboot_laser_comm_fail = 0x01,
    reboot_robot_comm_fail = 0x02
}
local ERROR_WARN_DESC_OF_A0A3 = {
    no = 0x00,
    warn_location_fail = 0x01,
    warn_low_battery = 0x02,
    warn_full_dust = 0x03,
    warn_low_water = 0x04,
    warn_multiple_docking_fail = 0x05,
    warn_down_sensor_blocked = 0x06,
    warn_abnormal_battery_temperature = 0x07,
    warn_rag_lifting = 0x08,
    warn_dust_collection_interrupt = 0x09,
    warn_dust_blockage = 0x0A,
    warn_upper_cover_open = 0x0B,
    warn_dust_bag_not_installed = 0x0C,
    warn_dust_bag_full = 0x0D,
    warn_reach_location_fail = 0x20,
    warn_cache_fail = 0x21,
    warn_start_mop_in_carpet = 0x22,
    warn_start_in_virtual_wall = 0x23,
    warn_start_in_forbid_area = 0x24,
    warn_start_in_forbid_water_area = 0x25,
    warn_comm_disconnect = 0x64,
    warn_machine_miss = 0x65,
    warn_vacuum_water_inject_fail = 0x66,
    warn_sewage_box_full = 0x67,
    warn_sewage_box_miss = 0x68,
    warn_water_box_miss = 0x69,
    warn_lack_of_water = 0x6A,
    warn_close_power_fail = 0x6B,
    warn_heat_module_fail = 0x6C,
    warn_fan_fail = 0x6D,
    warn_station_water_inject_fail = 0x6E,
    warn_station_water_box_full = 0x6F,
    warn_vacuum_water_box_full = 0x70,
    warn_vacuum_water_box_miss = 0x71,
    warn_vacuum_mop_miss = 0x72,
    warn_water_supply_and_drainage_improper_install = 0x75,
    warn_base_station_water_level_failed_1 = 0x76,
    warn_slop_tank_exception = 0x77,
    warn_base_station_filter_net_improper_install = 0x78,
    warn_dust_box_full = 0x79,
    warn_dust_box_cover_not_closed = 0x80,
    warn_dust_bag_not_installed_2 = 0x81,
    warn_cleaning_liquid_lack = 0x83,
    warn_water_level_sensor_failed = 0x86,
    warn_strong_liquid_lack = 0x87,
    warn_base_station_water_level_failed = 0x88,
    warn_washer_base_station_communication_failed = 0xcc
}
local function bitAt(bin, ops)
    local tgt = bit.lshift(1, ops)
    if bit.band(bin, tgt) == tgt then
        return true
    else
        return false
    end
end
local function initMessageArray(len)
    local arr = {}
    for i = 0, len - 1 do arr[i] = 0 end
    arr[0] = BYTE_PROTOCOL_HEAD
    arr[1] = len
    arr[2] = BYTE_DEVICE_TYPE
    return arr
end
local function checkValidJson(j)
    local rst = true
    return rst
end
local function makeSum(tmpBuf, endPos)
    local resVal = 0
    for i = 1, endPos do
        resVal = resVal + tmpBuf[i]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    if resVal == 0 then return 0 end
    resVal = 255 - resVal + 1
    return resVal
end
local function addSumAndConvertMsgToHexString(msg, len)
    msg[len] = makeSum(msg, len - 1)
    local bin = ""
    for i = 0, len do bin = bin .. string.format("%02x", msg[i]) end
    return bin
end
local function convertWeekdayToByte(weekday)
    dLog("预约日期转换 input : " .. weekday)
    local rst = 0x0
    for i = 1, 7 do
        p, _ = string.find(weekday, tostring(i))
        if p ~= nil and p > 0 then
            rst = bit.bxor(rst, bit.lshift(0x01, i - 1))
        end
    end
    rst = bit.bxor(rst, bit.lshift(0x01, 7))
    dLog("预约日期转换 output: " .. rst)
    return rst
end
local function convertYmdToBytes(ymd)
    dLog("预约年月日转换 input : " .. ymd)
    if #ymd ~= 8 then return 0, 0, 0 end
    local y = string.sub(ymd, 1, 4)
    local m = string.sub(ymd, 5, 6)
    local d = string.sub(ymd, 7, 8)
    y = (tonumber(y) or 1900) - 1900
    m = tonumber(m) or 0
    d = tonumber(d) or 0
    if y < 0 or y > 255 then y = 0 end
    if m < 1 or m > 12 then m = 1 end
    if d < 1 or d > 31 then d = 1 end
    dLog("预约年月日转换output : " .. y .. ":" .. m .. ":" .. d)
    return y, m, d
end
local function convertTimeToBytes(time)
    dLog("预约时间转换 input: " .. time)
    if #time ~= 6 then return 0, 0, 0 end
    local h = string.sub(time, 1, 2)
    local m = string.sub(time, 3, 4)
    local s = string.sub(time, 5, 6)
    h = tonumber(h) or 0
    m = tonumber(m) or 0
    s = tonumber(s) or 0
    if h < 0 or h > 23 then h = 0 end
    if m < 0 or m > 59 then m = 0 end
    if s < 0 or s > 59 then s = 0 end
    dLog("预约时间转换output: " .. h .. ":" .. m .. ":" .. s)
    return h, m, s
end
local function getDoubleBytesFromJson(json, key)
    local x = tonumber(json[key] or "0")
    local lowX = bit.band(x, 0xFF)
    local highX = bit.band(bit.rshift(x, 8), 0xFF)
    return lowX, highX
end
local function handleMovementJson(json)
    local move = json["move_direction"] or "none"
    if move == "stop" then move = "none" end
    local msgLen = 27
    local msg = initMessageArray(msgLen)
    print(msg[20])
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x02
    msg[13] = 0x01
    msg[14] = MOVEMENT_CODE[move]
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleWorkMode(workModeSetting)
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x58
    local workMode = workModeSetting["work_mode"]
    if workMode == "sweep_and_mop" then
        msg[13] = 0x00
    elseif workMode == "sweep" then
        msg[13] = 0x01
    elseif workMode == "mop" then
        msg[13] = 0x02
    elseif workMode == "sweep_then_mop" then
        msg[13] = 0x03
    end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleFanSetting(json)
    local fanSetting = json["fan_setting"]
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x50
    msg[13] = FAN_LEVEL_CODE[fanSetting["level"]]
    if "voice" == json["source"] then msg[11] = 0x11 end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleWaterTankSetting(json)
    local waterTankSetting = json["water_tank_setting"]
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x51
    msg[13] = WATER_LEVEL_CODE[waterTankSetting["level"]]
    if "voice" == json["source"] then msg[11] = 0x11 end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleMopCleanSetting(mopCleanSetting)
    local msgLen = 18
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x59
    if mopCleanSetting["mode_type"] == "common" then
        msg[13] = 0x00
        local cleanLevel = mopCleanSetting["clean_level"]
        if cleanLevel == "fast" then
            msg[14] = 0x0f
            msg[15] = 0x02
            msg[16] = 0x0f
            msg[17] = 0x02
        elseif cleanLevel == "normal" then
            msg[14] = 0x0c
            msg[15] = 0x03
            msg[16] = 0x0c
            msg[17] = 0x03
        else
            msg[14] = 0x0a
            msg[15] = 0x04
            msg[16] = 0x0a
            msg[17] = 0x04
        end
    end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleDustCollectionSetting(dustCollectionSetting)
    local msgLen = 15
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x56
    if dustCollectionSetting["mode_type"] == "count" then
        msg[13] = 0x01
    else
        msg[13] = 0x02
    end
    msg[14] = dustCollectionSetting["value"]
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleWorkAtPoint(json)
    local msgLen = 17
    local msg = initMessageArray(msgLen)
    local workContent = json["work_content"] or "stop"
    local lowX, highX = getDoubleBytesFromJson(json, "start_x")
    local lowY, highY = getDoubleBytesFromJson(json, "start_y")
    print(lowX, highX)
    print(lowY, highY)
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x05
    msg[12] = WORK_CONTENT_CODE[workContent]
    msg[13] = lowX
    msg[14] = highX
    msg[15] = lowY
    msg[16] = highY
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local TASK_CONTROL_CODE = {
    charge = 0x01,
    charge_pause = 0x02,
    charge_continue = 0x03,
    work = 0x04,
    auto_clean = 0x04,
    auto_clean_pause = 0x05,
    pause = 0x05,
    auto_clean_continue = 0x06,
    stop = 0x07,
    video_cruise_start = 0x08,
    video_cruise_pause = 0x09,
    quickly_mapping = 0x0A
}
local function isTaskControlWorkStatus(workStatus)
    for k, _ in pairs(TASK_CONTROL_CODE) do
        if k == workStatus then return true end
    end
    return false
end
local function handleTaskStatusControlJson(json)
    local workStatus = json["work_status"]
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x01
    if "voice" == json["source"] then msg[11] = 0x11 end
    for k, v in pairs(TASK_CONTROL_CODE) do
        if k == workStatus then msg[13] = v end
    end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleDisturbJson(json)
    local value = json["disturb_switch"] or "off"
    local startTime = json["disturb_start_time"]
    local endTime = json["disturb_end_time"]
    local msgLen = 18
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xaa
    msg[11] = 0x01
    msg[12] = 0x92
    if "voice" == json["source"] then msg[11] = 0x11 end
    if value == "on" then
        msg[13] = 0x01
        if #startTime ~= 5 or #endTime ~= 5 then return nil end
        local startHour = string.sub(startTime, 1, 2)
        local startMin = string.sub(startTime, 4, 5)
        local endHour = string.sub(endTime, 1, 2)
        local endMin = string.sub(endTime, 4, 5)
        msg[14] = tonumber(startHour) or 0
        msg[15] = tonumber(startMin) or 0
        msg[16] = tonumber(endHour) or 0
        msg[17] = tonumber(endMin) or 0
    else
        msg[13] = 0x00
    end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleVoiceVolumeJson(json)
    local value = tonumber(json["voice_level"]) or 50
    if value < 1 then
        value = 1
    elseif value > 100 then
        value = 100
    end
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xaa
    msg[11] = 0x01
    msg[12] = 0x93
    msg[13] = value
    if "voice" == json["source"] then msg[11] = 0x11 end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleReserveCreateJson(d)
    local cnt = 1
    local msgLen = 13 + 12
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0x24
    msg[11] = 0x01
    msg[12] = 0x01
    local pos = 13
    local weekdays = d["reserve_weekdays"] or ""
    local startDate = d["reserve_start_date"] or ""
    local startTime = d["reserve_start_time"] or ""
    local taskMinutes = d["reserve_task_minutes"] or "60"
    local cleanMode = d["reserve_work_mode"] or "arc"
    local fanLevel = d["reserve_fan_level"] or "normal"
    local waterLevel = d["reserve_water_level"] or "low"
    local taskId = d["reserve_task_id"]
    local weekdayByte = convertWeekdayToByte(weekdays)
    local year, month, day = convertYmdToBytes(startDate)
    local hour, min, sec = convertTimeToBytes(startTime)
    local taskMin = tonumber(taskMinutes) or 0
    if taskMin < 0 or taskMin > 120 then taskMin = 0 end
    cleanMode = CLEAN_MODE_CODE[cleanMode]
    fanLevel = FAN_LEVEL_CODE[fanLevel]
    waterLevel = WATER_LEVEL_CODE[waterLevel]
    taskId = tonumber(taskId) or i
    msg[pos] = weekdayByte
    msg[pos + 1] = year
    msg[pos + 2] = month
    msg[pos + 3] = day
    msg[pos + 4] = hour
    msg[pos + 5] = min
    msg[pos + 6] = sec
    msg[pos + 7] = taskMin
    msg[pos + 8] = cleanMode
    msg[pos + 9] = fanLevel
    msg[pos + 10] = waterLevel
    msg[pos + 11] = taskId
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleReserveUpdateJson(action, taskId)
    if action == nil or taskId == nil then return nil end
    local tid = tonumber(taskId)
    if tid == nil then return nil end
    if tid < 1 or tid > 8 then return nil end
    local msgLen = 25
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0x24
    msg[11] = 0x01
    if action == "delete" then
        msg[12] = 0x02
    elseif action == "on" then
        msg[12] = 0x06
    elseif action == "off" then
        msg[12] = 0x05
    end
    msg[24] = taskId
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleReserveJson(json)
    local action = json["reserve_action"] or ""
    local taskId = json["reserve_task_id"]
    if action == "set" then
        return handleReserveCreateJson(json)
    elseif action == "delete" or action == "on" or action == "off" then
        return handleReserveUpdateJson(action, taskId)
    end
    return nil
end
local function handleResetJson(json)
    local value = json["reset_type"] or ""
    local partsReset = 0x00
    local factoryReset = 0x00
    if value == "factory_restore" then
        factoryReset = 0x01
    elseif value == "side_brush" then
        partsReset = bit.lshift(1, 0)
    elseif value == "filter_net" then
        partsReset = bit.lshift(1, 1)
    elseif value == "roll_brush" then
        partsReset = bit.lshift(1, 2)
    end
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x07
    msg[12] = partsReset
    msg[13] = factoryReset
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleOTAJson(json)
    local msgLen = 13
    local msg = initMessageArray(msgLen)
    local target = json["ota_target"] or "both"
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x09
    if target == "firmware" then
        msg[12] = 0x01
    elseif target == "module" then
        msg[12] = 0x02
    else
        msg[12] = 0x03
    end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleSubTypeJson(json)
    local msgLen = 30
    local msg = initMessageArray(msgLen)
    msg[9] = 0xA0
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleCommandChannel(json)
    local msgLen = 13
    local msg = initMessageArray(msgLen)
    local channelType = json["channel_type"] or "wan"
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x08
    msg[12] = channelType == "lan" and 0x01 or 0x02
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleSwitchJson(json)
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    local fanLevel = json["fan_level"] or "normal"
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x50
    msg[13] = FAN_LEVEL_CODE[fanLevel]
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleVirtualWallParamJson(json)
    local msgLen = 22
    local msg = initMessageArray(msgLen)
    local status = json["work_status"] or ""
    local total = json["param_index_total"] or "1"
    local curr = json["param_index_curr"] or "1"
    local start_x_low, start_x_high = getDoubleBytesFromJson(json, "start_x")
    local start_y_low, start_y_high = getDoubleBytesFromJson(json, "start_y")
    local end_x_low, end_x_high = getDoubleBytesFromJson(json, "end_x")
    local end_y_low, end_y_high = getDoubleBytesFromJson(json, "end_y")
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = status == "virtual_wall_param" and 0x0b or 0x0c
    msg[12] = tonumber(total) or 1
    msg[13] = tonumber(curr) or 1
    msg[14] = start_x_low
    msg[15] = start_x_high
    msg[16] = start_y_low
    msg[17] = start_y_high
    msg[18] = end_x_low
    msg[19] = end_x_high
    msg[20] = end_y_low
    msg[21] = end_y_high
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handlePathCleanParam(json)
    local msgLen = 18
    local msg = initMessageArray(msgLen)
    local total = json["param_index_total"] or "0"
    local curr = json["param_index_curr"] or "0"
    local start_x_low, start_x_high = getDoubleBytesFromJson(json, "start_x")
    local start_y_low, start_y_high = getDoubleBytesFromJson(json, "start_y")
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x0d
    msg[12] = tonumber(total) or 0
    msg[13] = tonumber(curr) or 0
    msg[14] = start_x_low
    msg[15] = start_x_high
    msg[16] = start_y_low
    msg[17] = start_y_high
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleEmphasesCleanParam(json)
    local msgLen = 16
    local msg = initMessageArray(msgLen)
    local start_x_low, start_x_high = getDoubleBytesFromJson(json, "start_x")
    local start_y_low, start_y_high = getDoubleBytesFromJson(json, "start_y")
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x0e
    msg[12] = start_x_low
    msg[13] = start_x_high
    msg[14] = start_y_low
    msg[15] = start_y_high
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleRestartParam(json)
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    local value = json["restart_module"] or "whole"
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0xA0
    msg[13] = value == "navi" and 0x01 or 0x02
    if "voice" == json["source"] then msg[11] = 0x11 end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleSimpleFunctionSwitchParam(json)
    local msgLen = 15
    local msg = initMessageArray(msgLen)
    local function_type = json["function_type"]
    local switch = json["function_switch"] or "off"
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x9C
    if "voice" == json["source"] then msg[11] = 0x11 end
    for k, v in pairs(SIMPLE_FUNCTION_CODE) do
        if k == function_type then
            msg[13] = v
            msg[14] = switch == "on" and 0x01 or 0x00
            return addSumAndConvertMsgToHexString(msg, msgLen)
        end
    end
    return nil
end
local function handleStationFunctionParam(json)
    local msgLen = 15
    local msg = initMessageArray(msgLen)
    local function_type = json["function_type"]
    local switch = json["switch"] or "off"
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x5A
    if "voice" == json["source"] then msg[11] = 0x11 end
    for k, v in pairs(STATION_FUNCTION_CODE) do
        if function_type == k then
            msg[13] = v
            msg[14] = switch == "on" and 0x01 or 0x00
            return addSumAndConvertMsgToHexString(msg, msgLen)
        end
    end
    return nil
end
local function handleStartMappingParam(json)
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x29
    msg[13] = 0x00
    if "voice" == json["source"] then msg[11] = 0x11 end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleStationCleanParam(json)
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    local switch = json["switch"] or "off"
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x5B
    msg[13] = switch == "on" and 0x01 or 0x00
    if "voice" == json["source"] then msg[11] = 0x11 end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleDryMopParam(json)
    local msgLen = 14
    local msg = initMessageArray(msgLen)
    local switch = json["switch"] or "off"
    msg[9] = 0x02
    msg[10] = 0xAA
    msg[11] = 0x01
    msg[12] = 0x5C
    msg[13] = switch == "on" and 0x01 or 0x00
    if "voice" == json["source"] then msg[11] = 0x11 end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
local function handleControlJson(json)
    local workModeSetting = json["work_mode_setting"] or "none"
    if workModeSetting ~= nil and workModeSetting ~= "none" then
        return handleWorkMode(workModeSetting)
    end
    local fanSetting = json["fan_setting"] or "none"
    if fanSetting ~= nil and fanSetting ~= "none" then
        return handleFanSetting(json)
    end
    local waterTankSetting = json["water_tank_setting"] or "none"
    if waterTankSetting ~= nil and waterTankSetting ~= "none" then
        return handleWaterTankSetting(json)
    end
    local mopCleanSetting = json["mop_clean_setting"] or "none"
    if mopCleanSetting ~= nil and mopCleanSetting ~= "none" then
        return handleMopCleanSetting(mopCleanSetting)
    end
    local dustCollectionSetting = json["dust_collection_setting"] or "none"
    if dustCollectionSetting ~= nil and dustCollectionSetting ~= "none" then
        return handleDustCollectionSetting(dustCollectionSetting)
    end
    local workStatus = json["work_status"] or "none"
    local movement = json["move_direction"] or "none"
    if workStatus == "work" and movement ~= nil and movement ~= "none" then
        return handleMovementJson(json)
    elseif workStatus == "work_at_point" then
        return handleWorkAtPoint(json)
    elseif workStatus == "command_channel" then
        return handleCommandChannel(json)
    elseif workStatus == "reserve" then
        return handleReserveJson(json)
    elseif isTaskControlWorkStatus(workStatus) then
        return handleTaskStatusControlJson(json)
    elseif workStatus == "disturb" then
        return handleDisturbJson(json)
    elseif workStatus == "voice" then
        return handleVoiceVolumeJson(json)
    elseif workStatus == "reset" then
        return handleResetJson(json)
    elseif workStatus == "ota" then
        return handleOTAJson(json)
    elseif workStatus == "sub" then
        return handleSubTypeJson(json)
    elseif workStatus == "switch" then
        return handleSwitchJson(json)
    elseif workStatus == "virtual_wall_param" or workStatus ==
        "zone_clean_param" then
        return handleVirtualWallParamJson(json)
    elseif workStatus == "path_clean_param" then
        return handlePathCleanParam(json)
    elseif workStatus == "emphases_clean_param" then
        return handleEmphasesCleanParam(json)
    elseif workStatus == "restart" then
        return handleRestartParam(json)
    elseif workStatus == "simple_function_switch" then
        return handleSimpleFunctionSwitchParam(json)
    elseif workStatus == "station_function" then
        return handleStationFunctionParam(json)
    elseif workStatus == "start_mapping" then
        return handleStartMappingParam(json)
    elseif workStatus == "station_clean" then
        return handleStationCleanParam(json)
    elseif workStatus == "dry_mop" then
        return handleDryMopParam(json)
    end
    return nil
end
local function handleQueryJson(json)
    local value = json["query_type"] or "work"
    local msgLen = 13
    local msg = initMessageArray(msgLen)
    msg[9] = 0x03
    msg[10] = 0xAA
    msg[11] = 0x01
    if value == "work" then
        msg[12] = 0x01
    elseif value == "control" then
        msg[12] = 0x50
    elseif value == "abnormal" then
        msg[12] = 0x51
    elseif value == "error" then
        msg[12] = 0x04
    elseif value == "disturb" then
        msg[12] = 0x90
    elseif value == "reserve" then
        msg[12] = 0x02
    elseif value == "parts" then
        msg[12] = 0x55
    elseif value == "time" then
        msg[12] = 0x56
    elseif value == "zone" then
        msg[12] = 0x21
    elseif value == "find" then
        msg[12] = 0x57
    elseif value == "work_mode" then
        msg[12] = 0xa5
    elseif value == "mop_clean_setting" then
        msg[12] = 0x93
    elseif value == "mop_dry_mode" then
        msg[12] = 0x94
    end
    return addSumAndConvertMsgToHexString(msg, msgLen)
end
function jsonToData(jsonStr)
    if #jsonStr == 0 then return nil end
    local jsonData = JSON.decode(jsonStr)
    if checkValidJson(jsonData) == false then return nil end
    if jsonData["control"] ~= nil then
        return handleControlJson(jsonData["control"])
    elseif jsonData["query"] ~= nil then
        return handleQueryJson(jsonData["query"])
    end
    return nil
end
local WORK_STATUS_CODE = {
    charging = 0x01,
    charging_on_dock = 0x02,
    charge_pause = 0x03,
    charge_finish = 0x04,
    work = 0x05,
    clean_pause = 0x06,
    stop = 0x07,
    updating = 0x08,
    error = 0x09,
    sleep = 0x0A,
    relocate = 0x0B,
    map_searching = 0x0C,
    clean_mop = 0x0D,
    back_clean_mop = 0x0E,
    clean_mop_pause = 0x0F,
    manual_control = 0x11,
    on_base = 0x12,
    video_cruise = 0x13,
    video_cruise_pause = 0x14,
    map_searching_pause = 0x15
}
local SWEEP_MOP_MODE_CODE = {
    sweep_and_mop = 0x00,
    sweep = 0x01,
    mop = 0x02,
    sweep_then_mop = 0x03
}
local SUB_WORK_STATUS_CODE = {
    free = 0x00,
    charging = 0x01,
    inject_water = 0x02,
    clean_mop = 0x03,
    dry_mop = 0x04,
    hot_dry_mop = 0x05,
    water_station_error = 0x06,
    charge_finish = 0x07,
    erp_mode = 0x08,
    auto_clean = 0x09,
    dust_collect = 0x0A,
    cut_hair = 0x0B
}
local SUB_SLEEPING_STATUS_CODE = {
    default_sleeping = 0x30,
    pause_sleeping = 0x31,
    standing_sleeping = 0x32,
    charge_pause_sleeping = 0x33,
    return_station_pause_sleeping = 0x34,
    cruise_pause_sleeping = 0x35
}
local SUB_RELOCATE_REASON_CODE = {
    default = 0x50,
    first_start = 0x51,
    wheel_lift = 0x52,
    milemeter_data_change = 0x53,
    imu_data_change = 0x54,
    no_map = 0x55,
    coming_out_during_relocate = 0x56,
    map_change = 0x57,
    manual_control = 0x58,
    position_out_of_map = 0x59
}
local FUNCTION_TYPE_CODE = {
    dust_box_cleaning = 0x01,
    water_tank_cleaning = 0x02,
    relocate_default = 0x03,
    relocate_in_progress = 0x04,
    relocate_success = 0x05,
    relocate_fail = 0x06
}
local ERR_0A_INFRA_RED_LOW_CODE = {
    none = 0x07,
    none = 0x06,
    failure_infra_red_low_right_back_fall = 0x05,
    failure_infra_red_low_left_back_fall = 0x04,
    failure_infra_red_low_right_hanging = 0x03,
    failure_infra_red_low_left_hanging = 0x02,
    failure_infra_red_low_right_collision = 0x01,
    failure_infra_red_low_left_collision = 0x00,
    failure_infra_red_low_center_collision = 0x08
}
local ERR_0A_INFRA_RED_HIGH_CODE = {
    failure_infra_red_high_left_front_obstacle = 0x07,
    failure_infra_red_high_right_front_obstacle = 0x06,
    failure_infra_red_high_front_obstacle = 0x05,
    failure_infra_red_high_left_obstacle = 0x04,
    failure_infra_red_high_right_obstacle = 0x03,
    failure_infra_red_high_right_fall = 0x02,
    failure_infra_red_high_front_fall = 0x01,
    failure_infra_red_high_left_fall = 0x00
}
local ERR_0A_FAILURE_LOW_CODE = {
    failure_low_no_dust_box = 0x07,
    failure_low_dust_box_full = 0x06,
    failure_low_water_tank_overload = 0x05,
    failure_low_fan = 0x04,
    failure_low_right_side_brush = 0x03,
    failure_low_left_side_brush = 0x02,
    failure_low_right_wheel_overload = 0x01,
    failure_low_left_wheel_overload = 0x00
}
local ERR_0A_FAILURE_MID_CODE = {
    failure_mid_front_collision_switch = 0x07,
    failure_mid_roll_brush = 0x06,
    failure_mid_right_back_fall_sensor = 0x05,
    failure_mid_left_back_fall_sensor = 0x04,
    failure_mid_right_back_hanging_sensor = 0x03,
    failure_mid_left_back_hanging_sensor = 0x02,
    failure_mid_right_collision_switch = 0x01,
    failure_mid_left_collision_switch = 0x00
}
local ERR_0A_FAILURE_HIGH_CODE = {
    failure_high_left_front_infra_red = 0x07,
    failure_high_right_front_infra_red = 0x06,
    failure_high_front_infra_red = 0x05,
    failure_high_left_infra_red = 0x04,
    failure_high_right_infra_red = 0x03,
    failure_high_right_drop_sensor = 0x02,
    failure_high_front_drop_sensor = 0x01,
    failure_high_left_drop_sensor = 0x00
}
local ERR_0A_USER_LOW_CODE = {
    failure_user_low_no_dust_box = 0x07,
    failure_user_low_dust_box_full = 0x06,
    failure_user_low_no_water_tank = 0x05,
    failure_user_low_water_tank_error = 0x04,
    failure_user_low_no_water = 0x03,
    failure_user_low_charging_switch_off = 0x02,
    failure_user_low_charge_error = 0x01,
    failure_user_low_network_failed = 0x00
}
local ERR_0A_USER_MID_CODE = {
    none = 0x07,
    none = 0x06,
    failure_user_mid_board_communication_error = 0x05,
    failure_user_mid_laser_sensor_shelter = 0x04,
    failure_user_mid_laser_sensor_error = 0x03,
    failure_user_mid_low_battery = 0x02,
    failure_user_mid_camera_error = 0x01,
    failure_user_mid_vacuum_engine_overload = 0x00
}
local STATUS_SUMMARY_LOW_CODE = {
    status_summary_uv_switch = 0x00,
    status_summary_wifi_switch = 0x01,
    status_summary_voice_switch = 0x02,
    none = 0x03,
    none = 0x04,
    none = 0x05,
    status_summary_command_source = 0x06,
    status_summary_device_error = 0x07
}
local ERR_USER_LOW_CODE = {
    user_low_no_dust_box = 0x07,
    user_low_dust_box_full = 0x06,
    none = 0x05,
    user_low_firmware_can_upgrade = 0x04,
    user_low_no_water = 0x03,
    user_low_charging_switch_off = 0x02,
    user_low_f_b_plate_stuck = 0x01,
    user_low_l_r_wheel_hang = 0x00
}
local ERR_USER_MID_CODE = {
    none = 0x07,
    user_mid_roll_brush_overload = 0x06,
    user_mid_right_side_brush_overload = 0x05,
    user_mid_left_side_brush_overload = 0x04,
    user_mid_vacuum_engine_overload = 0x03,
    user_mid_right_wheel_overload = 0x02,
    user_mid_left_wheel_overload = 0x01,
    user_mid_drop = 0x00
}
local ERR_USER_HIGH_CODE = {
    none = 0x07,
    none = 0x06,
    none = 0x05,
    none = 0x04,
    none = 0x03,
    user_high_board_communication_error = 0x02,
    user_high_laser_sensor_shelter = 0x01,
    user_high_laser_sensor_error = 0x00
}
local function getCodeStr(dict, value)
    for k, v in pairs(dict) do if v == value then return k end end
    return nil
end
local function convertWorkdaysFromByte(weekdayByte)
    local rst = ""
    for i = 1, 7 do
        if bit.band(weekdayByte, bit.lshift(0x01, i - 1)) > 0 then
            rst = rst .. tostring(i)
        end
    end
    return rst
end
local function convertStringToInt(data)
    local strCnt = #data
    local byteCnt = strCnt / 2
    local rst = {}
    rst[0] = 0xaa
    for i = 1, byteCnt - 1 do
        local currStr = string.sub(data, i * 2 + 1, i * 2 + 2)
        local value = tonumber(currStr, 16) or 0
        rst[i] = value
    end
    return rst
end
local function wrapTableToJson(_, table)
    local out = {}
    table["version"] = VERSION
    table["SN8"] = SN8
    out["status"] = table
    return JSON.encode(out)
end
local function decodeWorkBin(bin)
    local workMode = bin[11]
    local controlMode = bin[13]
    local moveDirection = bin[14]
    local cleanMode = bin[15]
    local fanLevel = bin[16]
    local waterLevel = bin[18]
    local speakLevel = bin[19]
    local zoneId = bin[20]
    local zoneCount = bin[21]
    local control = {}
    if workMode == 0x02 then
        control["work_status"] = "work"
        if controlMode == 0x02 then
            control["work_mode"] = getCodeStr(CLEAN_MODE_CODE, cleanMode)
        elseif controlMode == 0x01 then
            control["move_direction"] = getCodeStr(MOVEMENT_CODE, moveDirection)
        end
        control["fan_level"] = getCodeStr(FAN_LEVEL_CODE, fanLevel)
        control["water_level"] = getCodeStr(WATER_LEVEL_CODE, waterLevel)
        control["speak_level"] = getCodeStr(SPEAK_LEVEL_CODE, speakLevel)
        control["zone_id"] = tostring(zoneId)
        control["zone_count"] = tostring(zoneCount)
    end
    return wrapTableToJson("status", control)
end
local function decodeChargeStopBin(bin)
    local workStatus = bin[13]
    local control = {}
    if workStatus == 0x01 then
        control["work_status"] = "charge"
    elseif workStatus == 0x03 then
        control["work_status"] = "stop"
    elseif workStatus == 0x1B then
        control["work_status"] = "pause"
    end
    return wrapTableToJson("control", control)
end
local function decodeWorkModeSettingBin(bin)
    local result = bin[13]
    local control = {}
    if result == 0x00 then
        control["setting_result"] = "success"
    else
        control["setting_result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeWaterTankSettingBin(bin)
    local result = bin[13]
    local control = {}
    if result == 0x00 then
        control["setting_result"] = "success"
    else
        control["setting_result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeFanSettingBin(bin)
    local result = bin[13]
    local control = {}
    if result == 0x00 then
        control["setting_result"] = "success"
    else
        control["setting_result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeDustCollectSettingBin(bin)
    local result = bin[13]
    local control = {}
    if result == 0x00 then
        control["setting_result"] = "success"
    else
        control["setting_result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeSwitchBin(bin)
    local workStatus = bin[11]
    local fan = bin[12]
    local area = bin[13]
    local water = bin[14]
    local control = {}
    if workStatus == 0x04 then control["work_status"] = "switch" end
    control["fan_level"] = getCodeStr(FAN_LEVEL_CODE, fan)
    control["area"] = tostring(area)
    control["water_level"] = getCodeStr(WATER_LEVEL_CODE, water)
    return wrapTableToJson("control", control)
end
local function decodeDisturbBin(bin)
    local value = bin[12]
    local startHour = bin[13]
    local startMin = bin[14]
    local endHour = bin[15]
    local endMin = bin[16]
    local startTime = string.format("%02d:%02d", startHour, startMin)
    local endTime = string.format("%02d:%02d", endHour, endMin)
    local control = {}
    control["work_status"] = "disturb"
    if value == 0x01 then
        control["value"] = "on"
        control["start_time"] = startTime
        control["end_time"] = endTime
    else
        control["value"] = "off"
    end
    return wrapTableToJson("control", control)
end
local function decodeReserveBin(bin)
    local action = bin[12]
    local msgLen = bin[1]
    local reserveCnt = (msgLen - 13) / 12
    local firstTaskId = bin[24]
    local control = {}
    control["work_status"] = "reserve"
    if action == 0x01 then
        control["action"] = "set"
        local data = {}
        for reserveIndex = 0, reserveCnt - 1 do
            local outIdx = reserveIndex + 1
            data[outIdx] = {}
            local pos = 13 + reserveIndex * 12
            local weekdayByte = bin[pos]
            local hour = bin[pos + 4]
            local min = bin[pos + 5]
            local sec = bin[pos + 6]
            local taskMin = bin[pos + 7]
            local cleanMode = bin[pos + 8]
            local fanLevel = bin[pos + 9]
            local waterLevel = bin[pos + 10]
            local taskId = bin[pos + 11]
            local switch = bin[pos + 12]
            if msgLen == pos + 12 then switch = 0 end
            data[outIdx]["reserve_weekdays"] =
                convertWorkdaysFromByte(weekdayByte)
            data[outIdx]["reserve_start_time"] =
                string.format("%02d%02d%02d", hour, min, sec)
            data[outIdx]["reserve_task_minutes"] = tostring(taskMin)
            data[outIdx]["reserve_work_mode"] =
                getCodeStr(CLEAN_MODE_CODE, cleanMode)
            data[outIdx]["reserve_fan_level"] =
                getCodeStr(FAN_LEVEL_CODE, fanLevel)
            data[outIdx]["reserve_water_level"] =
                getCodeStr(WATER_LEVEL_CODE, waterLevel)
            data[outIdx]["reserve_task_id"] = tostring(taskId)
            data[outIdx]["reserve_switch"] = switch == 0 and "on" or "off"
        end
        control["data"] = data
    elseif action == 0x02 then
        control["action"] = "delete"
        control["task_id"] = firstTaskId
    elseif action == 0x05 then
        control["action"] = "off"
        control["task_id"] = firstTaskId
    elseif action == 0x06 then
        control["action"] = "on"
        control["task_id"] = firstTaskId
    end
    return wrapTableToJson("control", control)
end
local function decodeVoiceVolumeBin(bin)
    local action = bin[13]
    local control = {}
    control["work_status"] = "voice"
    control["value_level"] = tostring(action)
    return wrapTableToJson("control", control)
end
local function decodeMappingBin(bin)
    local result = bin[13]
    local control = {}
    control["work_status"] = "start_mapping"
    if result == 0x00 then
        control["result"] = "success"
    elseif result == 0x01 then
        control["result"] = "device_not_supported"
    elseif result == 0x02 then
        control["result"] = "map_is_full"
    else
        control["result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeResetBin(bin)
    local parts = bin[12]
    local factoryReset = bin[13]
    local control = {}
    control["work_status"] = "reset"
    if factoryReset == 0x01 then
        control["reset_type"] = "factory_restore"
    elseif parts == bit.lshift(1, 0) then
        control["reset_type"] = "side_brush"
    elseif parts == bit.lshift(1, 1) then
        control["reset_type"] = "filter_net"
    elseif parts == bit.lshift(1, 2) then
        control["reset_type"] = "roll_brush"
    end
    return wrapTableToJson("control", control)
end
local function decodeOTABin(bin)
    local control = {}
    local target = bin[12]
    control["work_status"] = "ota"
    if target == 0x01 then
        control["ota_target"] = "firmware"
    elseif target == 0x02 then
        control["ota_target"] = "module"
    else
        control["ota_target"] = "both"
    end
    return wrapTableToJson("control", control)
end
local function decodeChannelBin(bin)
    local control = {}
    control["work_status"] = "command_channel"
    local channelType = bin[12]
    local result = bin[13]
    control["channel_type"] = channelType == 0x01 and "lan" or "wan"
    control["channel_set_result"] = result == 0 and "succeed" or "failed"
    return wrapTableToJson("control", control)
end
local function decodeMopCleanSettingBin(bin)
    local modeType = bin[13]
    local query = {}
    query["query_type"] = "mop_clean_setting"
    if modeType == 0x00 then
        query["mode_type"] = "common"
        local cleanLevel = bin[15];
        if cleanLevel == 0x02 then
            query["clean_level"] = "fast"
        elseif cleanLevel == 0x03 then
            query["clean_level"] = "normal"
        else
            query["clean_level"] = "deep"
        end
    end
    return wrapTableToJson("query", query)
end
local function decodeStationFunctionBin(bin)
    local result = bin[13]
    local control = {}
    control["work_status"] = "station_function"
    if result == 0x00 then
        control["result"] = "success"
    else
        control["result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeStationCleanBin(bin)
    local result = bin[13]
    local control = {}
    control["work_status"] = "station_self_clean"
    if result == 0x00 then
        control["result"] = "success"
    else
        control["result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeDryMopBin(bin)
    local result = bin[13]
    local control = {}
    control["work_status"] = "mop_dry"
    if result == 0x00 then
        control["result"] = "success"
    else
        control["result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeDisturbSwitchBin(bin)
    local result = bin[13]
    local control = {}
    control["work_status"] = "disturb"
    if result == 0x00 then
        control["result"] = "success"
    else
        control["result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeSimpleFunctionSwitchBin(bin)
    local result = bin[13]
    local control = {}
    control["work_status"] = "simple_function_switch"
    if result == 0x00 then
        control["result"] = "success"
    else
        control["result"] = "fail"
    end
    return wrapTableToJson("control", control)
end
local function decodeRestartBin(bin)
    local result = bin[13]
    local control = {}
    control["work_status"] = "restart"
    if result == 0x00 then
        control["result"] = "success"
    else
        control["result"] = "only_navi"
    end
    return wrapTableToJson("control", control)
end
local function decodeMopDryModeBin(bin)
    local modeType = bin[13]
    local query = {}
    query["query_type"] = "mop_dry_mode"
    if modeType == 0x00 or modeType == 0x04 then
        query["mode_type"] = "dry_mop"
    elseif modeType == 0x01 or modeType == 0x02 then
        query["mode_type"] = "hot_dry_mop"
    end
    return wrapTableToJson("query", query)
end
local function decodeControlData(bin)
    local msgSubType = bin[10]
    local workMode = bin[12]
    if msgSubType == 0xAA then
        if workMode == 0x04 then
            return decodeWorkBin(bin)
        elseif workMode == 0x01 or workMode == 0x07 or workMode == 0x1B or
            workMode == 0x1C then
            return decodeChargeStopBin(bin)
        elseif workMode == 0x04 then
            return decodeSwitchBin(bin)
        elseif workMode == 0x06 then
            return decodeDisturbBin(bin)
        elseif workMode == 0x07 then
            return decodeResetBin(bin)
        elseif workMode == 0x08 then
            return decodeChannelBin(bin)
        elseif workMode == 0x09 then
            return decodeOTABin(bin)
        elseif workMode == 0x29 then
            return decodeMappingBin(bin)
        elseif workMode == 0x50 then
            return decodeFanSettingBin(bin)
        elseif workMode == 0x51 then
            return decodeWaterTankSettingBin(bin)
        elseif workMode == 0x56 then
            return decodeDustCollectSettingBin(bin)
        elseif workMode == 0x58 then
            return decodeWorkModeSettingBin(bin)
        elseif workMode == 0x59 then
            return decodeMopCleanSettingBin(bin)
        elseif workMode == 0x5a then
            return decodeStationFunctionBin(bin)
        elseif workMode == 0x5b then
            return decodeStationCleanBin(bin)
        elseif workMode == 0x5c then
            return decodeDryMopBin(bin)
        elseif workMode == 0x92 then
            return decodeDisturbSwitchBin(bin)
        elseif workMode == 0x9c then
            return decodeSimpleFunctionSwitchBin(bin)
        elseif workMode == 0x93 then
            return decodeVoiceVolumeBin(bin)
        elseif workMode == 0xa0 then
            return decodeRestartBin(bin)
        end
    elseif msgSubType == 0x24 then
        return decodeReserveBin(bin)
    end
    return bin
end
local function byte2bin(n)
    local t = {}
    for i = 7, 0, -1 do
        t[#t + 1] = math.floor(n / 2 ^ i)
        n = n % 2 ^ i
    end
    return table.concat(t)
end
local function decodeQueryWorkStatusBin(bin)
    local workStatus = bin[13]
    local reservedField = bin[14]
    local controlType = bin[15]
    local movement = bin[16]
    local cleanMode = bin[17]
    local fanLevel = bin[18]
    local area = bin[19]
    local waterLevel = bin[20]
    local voiceVolume = bin[21]
    local isReserve = bin[22]
    local batteryRatio = bin[23]
    local workMin = bin[24]
    local robotType_error = bin[25]
    local errorType = bin[26]
    local errorContent = bin[27]
    local mopMonitor = bin[28]
    local carpetMonitor = bin[29]
    local partitionInfo = bin[30]
    local cleanType = bin[31]
    local workContent = bin[32]
    local meticulousMop = bin[33]
    local shake = bin[34]
    local waterSwitch = bin[35]
    local waterStatus = bin[36]
    local lifter = bin[37]
    local dustCount = bin[38]
    local dustCleanCount = bin[39]
    local chargeDockType = bin[40]
    local dustTime = bin[41]
    local dustStatus = bin[42]
    local waterStationStatus = byte2bin(bin[43])
    local sweepAndMop = bin[44]
    local waterStationError = bin[45]
    local subWorkStatus = bin[46]
    local plannerStatus = bin[47]
    local sweepThenMopModeProgress = bin[48]
    local switchStatus = byte2bin(bin[60])
    local query = {}
    query["query_type"] = "work"
    if controlType == nil then return wrapTableToJson("status", query) end
    query["error_type"] = getCodeStr(ERROR_TYPE_OF_A0A3, errorType)
    query["error_desc"] = "no"
    if errorType == 0x01 then
        query["error_desc"] = getCodeStr(ERROR_FIX_DESC_OF_A0A3, errorContent)
    elseif errorType == 0x02 then
        query["error_desc"] = getCodeStr(ERROR_REBOOT_DESC, errorContent)
    elseif errorType == 0x03 then
        query["error_desc"] = getCodeStr(ERROR_WARN_DESC_OF_A0A3, errorContent)
    end
    query["station_error_desc"] = "no"
    if workStatus == 0x12 then
        query["station_error_desc"] = getCodeStr(ERROR_WARN_DESC_OF_A0A3,
                                                 waterStationError)
    end
    query["work_status"] = getCodeStr(WORK_STATUS_CODE, workStatus)
    if workStatus == 0x12 then
        query["sub_work_status"] = getCodeStr(SUB_WORK_STATUS_CODE,
                                              subWorkStatus)
    elseif workStatus == 0x0A then
        query["sub_work_status"] = getCodeStr(SUB_SLEEPING_STATUS_CODE,
                                              subWorkStatus)
    elseif workStatus == 0x0B then
        query["sub_work_status"] = getCodeStr(SUB_RELOCATE_REASON_CODE,
                                              subWorkStatus)
    end
    query["function_type"] = getCodeStr(FUNCTION_TYPE_CODE, functionType)
    query["control_type"] = getCodeStr(CONTROL_TYPE_CODE, controlType)
    query["move_direction"] = getCodeStr(MOVEMENT_CODE, movement)
    query["work_mode"] = getCodeStr(CLEAN_MODE_CODE, cleanMode)
    query["fan_level"] = getCodeStr(FAN_LEVEL_CODE, fanLevel)
    query["area"] = tostring(bit.band(workContent, 0x0f) * 255 + area)
    query["water_level"] = getCodeStr(WATER_LEVEL_CODE, waterLevel)
    query["voice_level"] = tostring(voiceVolume)
    query["mop"] = mop == 0x1 and "yes" or "no"
    if mop == 0x00 then
        query["mop"] = "no"
    elseif mop == 0x01 then
        query["mop"] = "yes"
    else
        query["mop"] = "lack_water"
    end
    query["carpet_switch"] = carpet_switch == 0x01 and "yes" or "no"
    if reserveWeekday == 0 then
        query["have_reserve_task"] = "0"
    else
        query["have_reserve_task"] = "1"
    end
    query["battery_percent"] = tostring(batteryRatio)
    query["work_time"] = tostring(bit.band(bit.rshift(workContent, 4), 0x0f) *
                                      255 + workMin)
    query["dust_count"] = tostring(dustCount)
    query["planner_status"] = tostring(plannerStatus)
    query["sweep_then_mop_mode_progress"] = tostring(sweepThenMopModeProgress)
    query["switch_status"] = switchStatus
    query["water_station_status"] = waterStationStatus
    return wrapTableToJson("status", query)
end
local function decodeQuerySweepMopModeBin(bin)
    local sweepMopMode = bin[13]
    local query = {}
    query["query_type"] = "work_mode"
    query["work_mode"] = getCodeStr(SWEEP_MOP_MODE_CODE, sweepMopMode)
    return wrapTableToJson("query", query)
end
local function decodeQueryDisturbBin(bin)
    local setStatus = bin[12] or 0
    local startHour = bin[13] or 0
    local startMin = bin[14] or 0
    local endHour = bin[15] or 0
    local endMin = bin[16] or 0
    if bin[1] == 12 then
        local query = {}
        query["query"] = "disturb"
        return wrapTableToJson("query", query)
    end
    local query = {}
    query["query_type"] = "disturb"
    if setStatus == 0x00 then
        query["set_status"] = "off"
    else
        query["set_status"] = "on"
        query["start_time"] = string.format("%02d:%02d", startHour, startMin)
        query["end_time"] = string.format("%02d:%02d", endHour, endMin)
    end
    return wrapTableToJson("status", query)
end
local function decodeQueryObserverBin(bin)
    if bin[1] == 0x0c then
        local query = {}
        query["query"] = "reserve"
        return wrapTableToJson("query", query)
    end
    local reserveCnt = (bin[01] - 13) / 9
    local query = {}
    query["query_type"] = "reserve"
    local data = {}
    if reserveCnt > 0 then
        for i = 0, reserveCnt - 1 do
            local pos = 13 + 9 * i
            local weekdayByte = bin[pos]
            local hour = bin[pos + 1]
            local min = bin[pos + 2]
            local taskMin = bin[pos + 3]
            local cleanMode = bin[pos + 4]
            local fanLevel = bin[pos + 5]
            local waterLevel = bin[pos + 6]
            local taskId = bin[pos + 7]
            local isOpen = bin[pos + 8]
            data[i + 1] = {}
            data[i + 1]["weekdays"] = convertWorkdaysFromByte(weekdayByte)
            data[i + 1]["start_time"] = string.format("%02d%02d", hour, min)
            data[i + 1]["task_minutes"] = tostring(taskMin)
            data[i + 1]["work_mode"] = getCodeStr(CLEAN_MODE_CODE, cleanMode)
            data[i + 1]["fan_level"] = getCodeStr(FAN_LEVEL_CODE, fanLevel)
            data[i + 1]["water_level"] =
                getCodeStr(WATER_LEVEL_CODE, waterLevel)
            data[i + 1]["task_id"] = tostring(taskId)
            data[i + 1]["open_status"] = isOpen == 0x00 and "on" or "off"
        end
    end
    query["data"] = data
    return wrapTableToJson("status", query)
end
local function decodeQueryParts(bin)
    if bin[1] == 0x0c then
        local query = {}
        query["query"] = "parts"
        return wrapTableToJson("query", query)
    end
    local sideBrushRestTime = bit.lshift(bin[14], 8) + bin[13]
    local sideBrushLifeTime = bit.lshift(bin[16], 8) + bin[15]
    local filterNetRestTime = bit.lshift(bin[18], 8) + bin[17]
    local filterNetLifeTime = bit.lshift(bin[20], 8) + bin[19]
    local rollBrushRestTime = bit.lshift(bin[22], 8) + bin[21]
    local rollBrushLifeTime = bit.lshift(bin[24], 8) + bin[23]
    local query = {}
    query["side_brush_rest_time"] = tostring(sideBrushRestTime)
    query["side_brush_life_time"] = tostring(sideBrushLifeTime)
    query["filt_brNet_rest_time"] = tostring(filterNetRestTime)
    query["filt_brNet_life_time"] = tostring(filterNetLifeTime)
    query["roll_brush_rest_time"] = tostring(rollBrushRestTime)
    query["roll_brush_life_time"] = tostring(rollBrushLifeTime)
    return wrapTableToJson("status", query)
end
local function decodeQueryCommand(bin)
    local msgSubType = bin[10]
    local version = bin[11]
    if msgSubType ~= 0xaa or version ~= 0x01 then return nil end
    local query = {}
    local queryTypeCode = bin[12]
    if queryTypeCode == 0xa5 then
        query["query_type"] = "work_mode"
    elseif queryTypeCode == 0x01 then
        query["query_type"] = "work"
    elseif queryTypeCode == 0x93 then
        query["query_type"] = "mop_clean_setting"
    end
    return wrapTableToJson("query", query)
end
local function decodeQueryAbnormalBin(bin)
    local q = {}
    q["query"] = "abnormal"
    local temp = bin[13]
    local humidity = bin[14]
    local time = bin[15]
    local restMinLow = bin[16]
    local restMinHigh = bin[17]
    local restMin = bit.lshift(restMinHigh, 8) + restMinLow
    q["temperature"] = tostring(temp)
    q["humidity"] = tostring(humidity)
    q["work_time"] = tostring(time)
    q["rest_time"] = tostring(restMin)
    return wrapTableToJson("status", q)
end
local function decodeQueryData(bin)
    local queryType = bin[12]
    if #bin == 0x0C then return decodeQueryCommand(bin) end
    if queryType == 0x01 then
        return decodeQueryWorkStatusBin(bin)
    elseif queryType == 0x51 then
        return decodeQueryAbnormalBin(bin)
    elseif queryType == 0x90 then
        return decodeQueryDisturbBin(bin)
    elseif queryType == 0x02 then
        return decodeQueryObserverBin(bin)
    elseif queryType == 0x55 then
        return decodeQueryParts(bin)
    elseif queryType == 0xa5 then
        return decodeQuerySweepMopModeBin(bin)
    elseif queryType == 0x93 then
        return decodeMopCleanSettingBin(bin)
    elseif queryType == 0x94 then
        return decodeMopDryModeBin(bin)
    end
    return ""
end
local function decode0401Report(bin)
    local workStatus = bin[13]
    local startOrStop_type = bin[14]
    local controlType = bin[15]
    local movement = bin[16]
    local cleanMode = bin[17]
    local fanLevel = bin[18]
    local area = bin[19]
    local waterLevel = bin[20]
    local voiceVolume = bin[21]
    local reserveWeekday = bin[22]
    local batteryRatio = bin[23]
    local workMin = bin[24]
    local robotTypeError = bin[25]
    local errorType = bin[26]
    local errorContent = bin[27]
    local mop = bin[28]
    local carpetSwitch = bin[29]
    local partitionInfo = bin[30]
    local cleanType = bin[31]
    local workContent = bin[32]
    local meticulousMop = bin[33]
    local shake = bin[34]
    local waterSwitch = bin[35]
    local waterStatus = bin[36]
    local lifter = bin[37]
    local dustCount = bin[38]
    local dustCleanCount = bin[39]
    local chargeDockType = bin[40]
    local dustTime = bin[41]
    local dustStatus = bin[42]
    local waterStationStatus = byte2bin(bin[43])
    local sweepMopMode = bin[44]
    local waterSupplyError = bin[45]
    local subWorkStatus = bin[46]
    local plannerStatus = bin[47]
    local switchStatus = byte2bin(bin[60])
    local query = {}
    if controlType == nil then return wrapTableToJson("status", query) end
    query["error_type"] = getCodeStr(ERROR_TYPE_OF_A0A3, errorType)
    query["error_desc"] = "no"
    if errorType == 0x01 then
        query["error_desc"] = getCodeStr(ERROR_FIX_DESC_OF_A0A3, errorContent)
    elseif errorType == 0x02 then
        query["error_desc"] = getCodeStr(ERROR_REBOOT_DESC, errorContent)
    elseif errorType == 0x03 then
        query["error_desc"] = getCodeStr(ERROR_WARN_DESC_OF_A0A3, errorContent)
    end
    query["station_error_desc"] = "no"
    if workStatus == 0x12 and subWorkStatus == 0x06 then
        query["station_error_desc"] = getCodeStr(ERROR_WARN_DESC_OF_A0A3,
                                                 waterSupplyError)
    end
    query["work_status"] = getCodeStr(WORK_STATUS_CODE, workStatus)
    if workStatus == 0x12 then
        query["sub_work_status"] = getCodeStr(SUB_WORK_STATUS_CODE,
                                              subWorkStatus)
    elseif workStatus == 0x0A then
        query["sub_work_status"] = getCodeStr(SUB_SLEEPING_STATUS_CODE,
                                              subWorkStatus)
    elseif workStatus == 0x0B then
        query["sub_work_status"] = getCodeStr(SUB_RELOCATE_REASON_CODE,
                                              subWorkStatus)
    end
    query["control_type"] = getCodeStr(CONTROL_TYPE_CODE, controlType)
    query["move_direction"] = getCodeStr(MOVEMENT_CODE, movement)
    query["work_mode"] = getCodeStr(CLEAN_MODE_CODE, cleanMode)
    query["fan_level"] = getCodeStr(FAN_LEVEL_CODE, fanLevel)
    query["area"] = tostring(area)
    query["water_level"] = getCodeStr(WATER_LEVEL_CODE, waterLevel)
    query["voice_level"] = tostring(voiceVolume)
    query["mop"] = mop == 0x1 and "yes" or "no"
    if mop == 0x00 then
        query["mop"] = "no"
    elseif mop == 0x01 then
        query["mop"] = "yes"
    else
        query["mop"] = "lack_water"
    end
    query["carpet_switch"] = carpetSwitch == 0x01 and "yes" or "no"
    if reserveWeekday == 0 then
        query["have_reserve_task"] = "0"
    else
        query["have_reserve_task"] = "1"
    end
    query["sweep_mop_mode"] = getCodeStr(SWEEP_MOP_MODE_CODE, sweepMopMode)
    query["battery_percent"] = tostring(batteryRatio)
    query["work_time"] = tostring(workMin)
    query["planner_status"] = tostring(plannerStatus)
    query["switch_status"] = switchStatus
    query["water_station_status"] = waterStationStatus
    return wrapTableToJson("status", query)
end
local function decode0452Report(bin)
    local query = {}
    local event = bin[11]
    query["schedule_clean_start"] = event == 0x01 and "yes" or "no"
    query["schedule_clean_end"] = event == 0x02 and "yes" or "no"
    query["power_continue_clean"] = event == 0x03 and "yes" or "no"
    query["power_continue_end"] = event == 0x04 and "yes" or "no"
    query["location_fail_not_start"] = event == 0x05 and "yes" or "no"
    query["location_fail_not_target"] = event == 0x06 and "yes" or "no"
    return wrapTableToJson("status", query)
end
local function decodeRunStatusData(bin)
    local msgSubType = bin[12]
    if msgSubType == 0x01 then
        return decode0401Report(bin)
    elseif msgSubType == 0x52 then
        return decode0452Report(bin)
    end
    return nil
end
local function decodeSumData(bin)
    local msgSubType = bin[10]
    local sumType = bin[11]
    if msgSubType == 0x66 and sumType == 0x01 then
        local sideBrushRestTime = bit.lshift(bin[13], 8) + bin[12]
        local sideBrushLifeTime = bit.lshift(bin[15], 8) + bin[14]
        local filterNetRestTime = bit.lshift(bin[17], 8) + bin[16]
        local filterNetLifeTime = bit.lshift(bin[19], 8) + bin[18]
        local rollBrushRestTime = bit.lshift(bin[21], 8) + bin[20]
        local rollBrushLifeTime = bit.lshift(bin[23], 8) + bin[22]
        local query = {}
        query["side_brush_rest_time"] = tostring(sideBrushRestTime)
        query["side_brush_life_time"] = tostring(sideBrushLifeTime)
        query["filt_brNet_rest_time"] = tostring(filterNetRestTime)
        query["filt_brNet_life_time"] = tostring(filterNetLifeTime)
        query["roll_brush_rest_time"] = tostring(rollBrushRestTime)
        query["roll_brush_life_time"] = tostring(rollBrushLifeTime)
        return wrapTableToJson("status", query)
    end
    if msgSubType == 0x66 and sumType == 0x03 then
        local area = bin[12]
        local workMin = bin[13]
        local cleanMode = bin[14]
        local query = {}
        query["area"] = tostring(area)
        query["work_mode"] = getCodeStr(CLEAN_MODE_CODE, cleanMode)
        query["work_time"] = tostring(workMin)
        return wrapTableToJson("status", query)
    end
    return nil
end
local function decodeA0A3Report(bin)
    local error_type = bin[11] or 0
    local error_desc = bin[12] or 0
    local query = {}
    query["error_type"] = getCodeStr(ERROR_TYPE_OF_A0A3, error_type)
    query["error_desc"] = "no"
    if error_type == 0x01 then
        query["error_desc"] = getCodeStr(ERROR_FIX_DESC_OF_A0A3, error_desc)
    end
    if error_type == 0x02 then
        query["error_desc"] = getCodeStr(ERROR_REBOOT_DESC, error_desc)
    end
    if error_type == 0x03 then
        query["error_desc"] = getCodeStr(ERROR_WARN_DESC_OF_A0A3, error_desc)
    end
    return wrapTableToJson("status", query)
end
local function decodeErrorReport(bin)
    local msgSubType = bin[10]
    if msgSubType == 0xA3 then return decodeA0A3Report(bin) end
    local infra_red_low = bin[11] or 0
    local infra_red_high = bin[12] or 0
    local failure_low = bin[13] or 0
    local failure_mid = bin[14] or 0
    local failure_high = bin[15] or 0
    local user_info_low = bin[16] or 0
    local user_info_mid = bin[17] or 0
    local query = {}
    if msgSubType == 0xA1 then
        for i = 0, 7 do
            local name = getCodeStr(ERR_0A_INFRA_RED_LOW_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(infra_red_low, i) == true and "yes" or "no"
            end
            name = getCodeStr(ERR_0A_INFRA_RED_HIGH_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(infra_red_high, i) == true and "yes" or "no"
            end
            name = getCodeStr(ERR_0A_FAILURE_LOW_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(failure_low, i) == true and "yes" or "no"
            end
            name = getCodeStr(ERR_0A_FAILURE_MID_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(failure_mid, i) == true and "yes" or "no"
            end
            name = getCodeStr(ERR_0A_FAILURE_HIGH_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(failure_high, i) == true and "yes" or "no"
            end
            name = getCodeStr(ERR_0A_USER_LOW_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(user_info_low, i) == true and "yes" or "no"
            end
            name = getCodeStr(ERR_0A_USER_MID_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(user_info_mid, i) == true and "yes" or "no"
            end
        end
        if bitAt(infra_red_low, 0) and bitAt(infra_red_low, 1) then
            query["failure_infra_red_low_right_collision"] = "no"
            query["failure_infra_red_low_left_collision"] = "no"
            query["failure_infra_red_low_center_collision"] = "yes"
        end
    end
    return wrapTableToJson("status", query)
end
local function checkJsonData(j)
    local msg = j["msg"]
    if not msg then return false end
    local data = msg["data"]
    if not data then return false end
    return rst
end
local function checkBinSum(bin)
    local msgLen = bin[1]
    if msgLen ~= #bin then
        dLog("msgLen no valid")
        return false
    end
    if bin[0] ~= 0xaa then rst = false end
    if bin[2] ~= 0xb8 then rst = false end
    local realSum = makeSum(bin, #bin - 1)
    if bin[msgLen] ~= realSum then
        dLog("check sum valid")
        return false
    end
    return true
end
local function decodeOTAData(bin)
    local j = {}
    j["work_status"] = "ota"
    local target = bin[12]
    local method = bin[13]
    j["ota_target"] = target == 0x01 and "firmware" or "module"
    j["ota_method"] = method == 0x00 and "silent" or "force"
    return wrapTableToJson("status", j)
end
function dataToJson(jsonStr)
    if #jsonStr == 0 then return nil end
    local j = JSON.decode(jsonStr)
    if checkValidJson(j) == false then return nil end
    local data = j["msg"]["data"]
    data = string.gsub(data, ",", "")
    local bin = convertStringToInt(data)
    if checkBinSum(bin) == false or checkJsonData(bin) then return nil end
    local msgType = bin[9]
    if msgType == 0x02 then
        return decodeControlData(bin)
    elseif msgType == 0x03 then
        return decodeQueryData(bin)
    elseif msgType == 0x04 then
        return decodeRunStatusData(bin)
    elseif msgType == 0x06 then
        return decodeSumData(bin)
    elseif msgType == 0x09 then
        return decodeOTAData(bin)
    elseif msgType == 0x0A then
        return decodeErrorReport(bin)
    end
    return nil
end
