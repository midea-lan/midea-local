local bit = require "bit"
---
--- 吸尘器协议解析(M7Pro欧洲) 7500001H
--- author  : junZhou
--- email   : zhoujun46@midea.com
--- date    : 2021-5-6
--- copy from: 75000464

-- 全局
-- local debug = false

local function dLog(str)
    -- if debug then
    --    print(str)
    -- end
end

local SN8 = "7500001H"

-- 此子类型的 版本号
local VERSION = 1

-- 协议头及长度
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_DEVICE_TYPE = 0xB8

-- 控制模式
local CONTROL_TYPE_CODE = {
    none = 0x00, -- 不控制
    manual = 0x01, -- 手动模式
    auto = 0x02 -- 自动模式
}

-- 手动控制方向
local MOVEMENT_CODE = {
    none = 0x00, --	 无方向(手动工作暂停)
    forward = 0x01, --	 上/前
    back = 0x02, --	 下/后
    left = 0x03, --	 左
    right = 0x04 --	 右
}

-- 清扫类型
local CLEAN_MODE_CODE = {
    none = 0x00, --	 不控制
    random = 0x01, --	 随机
    arc = 0x02, --	 弓型
    edge = 0x03, --	 沿边
    emphases = 0x04, --	 重点
    screw = 0x05, --	 螺旋
    bed = 0x06, --	 床底清扫
    wide_screw = 0x07, --	 宽阔地方螺旋
    auto = 0x08, --	 自动清扫
    area = 0x09, --	 区域清
    zone_index = 0x0a, --    分区清扫(索引)
    zone_rect = 0x0b, --    划区清扫(手绘矩形区域)
    path = 0x0c --    轨迹清扫
}

-- 风机设置
local FAN_LEVEL_CODE = {
    off = 0x00, --	关闭
    soft = 0x01, --	轻柔
    normal = 0x02, --	正常(默认)
    high = 0x03, --	强力
    low = 0x04 --   安静
}

-- 水箱设置
local WATER_LEVEL_CODE = {
    off = 0x00, --	关闭
    low = 0x01, --	慢速（默认）
    normal = 0x02, --	中速
    high = 0x03 --	快速
}

-- 指定位置工作内容
local WORK_CONTENT_CODE = {
    charge = 0x01,
    auto = 0x02,
    stop = 0x03,
    screw = 0x04
}

-- 语音控制
local SPEAK_LEVEL_CODE = {
    none = 0x00, --	无语音（默认关闭）
    off = 0x01, --	关闭
    low = 0x02, --	小声
    normal = 0x03, --	中声
    high = 0x04 --	大声
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
    fix_start_in_forbid_area = 0x0E,
    fix_start_in_strong_magnetic = 0x0F,
    fix_laser_sensor_blocked = 0x10
}

local ERROR_REBOOT_DESC = {
    no = 0x00,
    reboot_laser_comm_fail = 0x01,
    reboot_robot_comm_fail = 0x02,
    reboot_inner_fail = 0x03
}

local ERROR_WARN_DESC_OF_A0A3 = {
    no = 0x00,
    warn_location_fail = 0x01,
    warn_low_battery = 0x02,
    warn_full_dust = 0x03,
    warn_low_water = 0x04
}

local JSON = require("cjson")

-- 返回 bin(byte) 的 第 pos(0-7) 位， 是否为 1.
local function bitAt(bin, ops)
    local tgt = bit.lshift(1, ops)
    if bit.band(bin, tgt) == tgt then
        return true
    else
        return false
    end
end

-- 返回初始化后的数组，下标从0开始， 初始化值为0
local function initMessageArray(len)
    local arr = {}
    for i = 0, len - 1 do arr[i] = 0 end
    -- 初始化消息头部信息
    arr[0] = BYTE_PROTOCOL_HEAD
    arr[1] = len
    arr[2] = BYTE_DEVICE_TYPE
    return arr
end

-- 校验json的 deviceinfo 信息
local function checkValidJson(j)
    local rst = true
    return rst
end

-- sum校验
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

-- 添加sum校验，并转换消息体为16进制输出
local function addSumAndConvertMsgToHexString(msg, len)
    msg[len] = makeSum(msg, len - 1)
    local bin = ""
    for i = 0, len do bin = bin .. string.format("%02x", msg[i]) end
    return bin
end

-- 转换一周内的七天("1234567") 到一个byte
local function convertWeekdayToByte(weekday)
    dLog("预约日期转换 input : " .. weekday)
    local rst = 0x0
    for i = 1, 7 do
        p, _ = string.find(weekday, tostring(i))
        if p ~= nil and p > 0 then
            rst = bit.bxor(rst, bit.lshift(0x01, i - 1))
        end
    end

    -- 高位给一， 周期性预约
    rst = bit.bxor(rst, bit.lshift(0x01, 7))

    dLog("预约日期转换 output: " .. rst)
    return rst
end

-- 转换yyyyMMdd 成 y-1900, m, d
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

-- 转换"HHmmss" 成 时， 分， 秒
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

-- 从JSON中拿出指定的有符号参数， 返回两个 byte
local function getDoubleBytesFromJson(json, key)
    local x = tonumber(json[key] or "0")
    local lowX = bit.band(x, 0xFF)
    local highX = bit.band(bit.rshift(x, 8), 0xFF)
    return lowX, highX
end

-- 处理手动控制扫地机方向json
local function handleMovementJson(json)
    local move = json["move_direction"] or "none"
    if move == "stop" then move = "none" end

    -- 电控消息总长 20 (不包含最后的校验位)
    local msgLen = 27
    local msg = initMessageArray(msgLen)
    print(msg[20])
    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x02
    msg[13] = 0x01
    msg[14] = MOVEMENT_CODE[move]

    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 处理清扫模式json
local function handleWorkModeJson(json)
    -- 进入具体设置模式
    local cleanMode = json["work_mode"] or "auto"
    local fanLevel = json["fan_level"] or "normal"
    local waterLevel = json["water_level"] or "low"
    local speakLevel = json["speak_level"] or "none"
    local zoneId = json["zone_id"] or "0"

    -- 电控消息总长 20 (不包含最后的校验位)
    local msgLen = 27
    local msg = initMessageArray(msgLen)

    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x02
    msg[13] = 0x02
    msg[15] = CLEAN_MODE_CODE[cleanMode]
    msg[16] = FAN_LEVEL_CODE[fanLevel]
    msg[18] = WATER_LEVEL_CODE[waterLevel]
    msg[19] = SPEAK_LEVEL_CODE[speakLevel]
    msg[20] = tonumber(zoneId) or 0x00
    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 指定位置工作
local function handleWorkAtPoint(json)
    -- 电控消息总长 17 (不包含最后的校验位)
    local msgLen = 17
    local msg = initMessageArray(msgLen)

    local workContent = json["work_content"] or "stop"
    local lowX, highX = getDoubleBytesFromJson(json, "start_x")
    local lowY, highY = getDoubleBytesFromJson(json, "start_y")
    print(lowX, highX)
    print(lowY, highY)

    -- 消息体
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

-- 处理充电、暂停json
local function handleChargeStopJson(json)

    local workMode = json["work_status"]

    -- 电控消息总长 13 (不包含最后的校验位)
    local msgLen = 13
    local msg = initMessageArray(msgLen)

    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22

    if workMode == "charge" then
        msg[11] = 0x01
    elseif workMode == "stop" then
        msg[11] = 0x03
    elseif workMode == "pause" then
        msg[11] = 0x1B
    end

    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 处理勿扰模式json
local function handleDisturbJson(json)
    local value = json["disturb_switch"] or "off"
    local startTime = json["disturb_start_time"]
    local endTime = json["disturb_end_time"]

    -- 电控消息总长 (不包含最后的校验位)
    local msgLen = 17
    local msg = initMessageArray(msgLen)

    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x06

    if value == "on" then
        msg[12] = 0x01

        if #startTime ~= 5 or #endTime ~= 5 then return nil end

        local startHour = string.sub(startTime, 1, 2)
        local startMin = string.sub(startTime, 4, 5)

        local endHour = string.sub(endTime, 1, 2)
        local endMin = string.sub(endTime, 4, 5)

        msg[13] = tonumber(startHour) or 0
        msg[14] = tonumber(startMin) or 0
        msg[15] = tonumber(endHour) or 0
        msg[16] = tonumber(endMin) or 0
    end

    return addSumAndConvertMsgToHexString(msg, msgLen)

end

-- 控制音量
local function handleVoiceVolumeJson(json)
    local value = tonumber(json["voice_level"]) or 50
    if value < 1 then
        value = 1
    elseif value > 100 then
        value = 100
    end

    -- 电控消息总长 (不包含最后的校验位)
    local msgLen = 13
    local msg = initMessageArray(msgLen)

    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x0a
    msg[12] = value
    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 处理添加预约功能(taskId相同，意味着更新)
local function handleReserveCreateJson(d)
    local cnt = 1

    -- 电控消息总长 (不包含最后的校验位)
    local msgLen = 13 + 12
    local msg = initMessageArray(msgLen)

    msg[9] = 0x02
    msg[10] = 0x24
    msg[11] = 0x01 -- 云端预约
    msg[12] = 0x01 -- 设置预约

    local pos = 13

    -- string
    local weekdays = d["reserve_weekdays"] or ""
    local startDate = d["reserve_start_date"] or ""
    local startTime = d["reserve_start_time"] or ""
    local taskMinutes = d["reserve_task_minutes"] or "60"
    local cleanMode = d["reserve_work_mode"] or "arc"
    local fanLevel = d["reserve_fan_level"] or "normal"
    local waterLevel = d["reserve_water_level"] or "low"
    local taskId = d["reserve_task_id"]

    -- int
    local weekdayByte = convertWeekdayToByte(weekdays)
    local year, month, day = convertYmdToBytes(startDate)
    local hour, min, sec = convertTimeToBytes(startTime)
    local taskMin = tonumber(taskMinutes) or 0
    if taskMin < 0 or taskMin > 120 then taskMin = 0 end
    cleanMode = CLEAN_MODE_CODE[cleanMode]
    fanLevel = FAN_LEVEL_CODE[fanLevel]
    waterLevel = WATER_LEVEL_CODE[waterLevel]
    taskId = tonumber(taskId) or i

    -- set value
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

-- 处理更新一条预约状态
local function handleReserveUpdateJson(action, taskId)
    if action == nil or taskId == nil then return nil end

    local tid = tonumber(taskId)

    if tid == nil then return nil end

    if tid < 1 or tid > 8 then return nil end

    local msgLen = 25
    local msg = initMessageArray(msgLen)

    msg[9] = 0x02
    msg[10] = 0x24
    msg[11] = 0x01 -- 云端预约
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

-- 处理预约功能
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

-- 处理重置功能
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

    -- 电控消息总长 (不包含最后的校验位)
    local msgLen = 14
    local msg = initMessageArray(msgLen)

    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x07
    msg[12] = partsReset
    msg[13] = factoryReset
    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 处理OTA升级
local function handleOTAJson(json)

    -- 电控消息总长 14 (不包含最后的校验位)
    local msgLen = 13
    local msg = initMessageArray(msgLen)
    local target = json["ota_target"] or "both"

    -- 消息体
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

-- sub type
local function handleSubTypeJson(json)
    -- 电控消息总长 (不包含最后的校验位)
    local msgLen = 30
    local msg = initMessageArray(msgLen)

    -- 消息体
    msg[9] = 0xA0
    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 更新指令通道
local function handleCommandChannel(json)
    -- 电控消息总长 13 (不包含最后的校验位)
    local msgLen = 13
    local msg = initMessageArray(msgLen)

    local channelType = json["channel_type"] or "wan"

    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x08
    msg[12] = channelType == "lan" and 0x01 or 0x02

    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 开关量设置
local function handleSwitchJson(json)
    -- 电控消息总长 (不包含最后的校验位)
    local msgLen = 15
    local msg = initMessageArray(msgLen)

    local fanLevel = json["fan_level"] or "normal"
    local waterLevel = json["water_level"] or "low"

    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x04
    msg[12] = FAN_LEVEL_CODE[fanLevel]
    msg[14] = WATER_LEVEL_CODE[waterLevel]
    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 虚拟墙指令参数
local function handleVirtualWallParamJson(json)
    -- 电控消息总长 22 (不包含最后的校验位)
    local msgLen = 22
    local msg = initMessageArray(msgLen)

    local status = json["work_status"] or ""
    local total = json["param_index_total"] or "1"
    local curr = json["param_index_curr"] or "1"
    local start_x_low, start_x_high = getDoubleBytesFromJson(json, "start_x")
    local start_y_low, start_y_high = getDoubleBytesFromJson(json, "start_y")
    local end_x_low, end_x_high = getDoubleBytesFromJson(json, "end_x")
    local end_y_low, end_y_high = getDoubleBytesFromJson(json, "end_y")

    -- 消息体
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

-- 轨迹清扫指令参数
local function handlePathCleanParam(json)
    -- 电控消息总长 (不包含最后的校验位)
    local msgLen = 18
    local msg = initMessageArray(msgLen)

    local total = json["param_index_total"] or "0"
    local curr = json["param_index_curr"] or "0"
    local start_x_low, start_x_high = getDoubleBytesFromJson(json, "start_x")
    local start_y_low, start_y_high = getDoubleBytesFromJson(json, "start_y")

    -- 消息体
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

--  重点清扫指令
local function handleEmphasesCleanParam(json)
    -- 电控消息总长 22 (不包含最后的校验位)
    local msgLen = 16
    local msg = initMessageArray(msgLen)

    local start_x_low, start_x_high = getDoubleBytesFromJson(json, "start_x")
    local start_y_low, start_y_high = getDoubleBytesFromJson(json, "start_y")

    -- 消息体
    msg[9] = 0x02
    msg[10] = 0x22
    msg[11] = 0x0e
    msg[12] = start_x_low
    msg[13] = start_x_high
    msg[14] = start_y_low
    msg[15] = start_y_high

    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 处理control json
local function handleControlJson(json)
    local workStatus = json["work_status"] or "none"
    local movement = json["move_direction"] or "none"

    if workStatus == "work" then
        -- 手动控制方向
        if movement ~= nil and movement ~= "none" then
            return handleMovementJson(json)
        else
            -- 清扫模式选择
            return handleWorkModeJson(json)
        end
    elseif workStatus == "work_at_point" then
        -- 指定位置工作
        return handleWorkAtPoint(json)
    elseif workStatus == "command_channel" then
        -- 更新指令通道
        return handleCommandChannel(json)
    elseif workStatus == "reserve" then
        -- 预约
        return handleReserveJson(json)
    elseif workStatus == "charge" or workStatus == "stop" or workStatus ==
        "pause" then
        -- 充电、暂停,暂停自动清扫， 继续自动清扫
        return handleChargeStopJson(json)
    elseif workStatus == "disturb" then
        -- 勿扰
        return handleDisturbJson(json)
    elseif workStatus == "voice" then
        -- 音量控制
        return handleVoiceVolumeJson(json)
    elseif workStatus == "reset" then
        -- 重置
        return handleResetJson(json)
    elseif workStatus == "ota" then
        -- OTA
        return handleOTAJson(json)
    elseif workStatus == "sub" then
        -- deviceSubType
        return handleSubTypeJson(json)
    elseif workStatus == "switch" then
        -- switch
        return handleSwitchJson(json)
    elseif workStatus == "virtual_wall_param" or workStatus ==
        "zone_clean_param" then
        -- 虚拟墙指令参数 or 划区清扫指令参数
        return handleVirtualWallParamJson(json)
    elseif workStatus == "path_clean_param" then
        -- 轨迹清扫指令参数
        return handlePathCleanParam(json)
    elseif workStatus == "emphases_clean_param" then
        -- 重点清扫指令
        return handleEmphasesCleanParam(json)
    end

    return nil
end

-- 处理query json
local function handleQueryJson(json)
    local value = json["query_type"] or "work"

    -- 电控消息总长 (不包含最后的校验位)
    local msgLen = 12
    local msg = initMessageArray(msgLen)

    -- 消息体
    msg[9] = 0x03

    if value == "work" then
        msg[10] = 0x32
        msg[11] = 0x01
    elseif value == "control" then
        msg[10] = 0x32
        msg[11] = 0x02
    elseif value == "abnormal" then
        msg[10] = 0x32
        msg[11] = 0x03
    elseif value == "error" then
        msg[10] = 0x32
        msg[11] = 0x04
    elseif value == "disturb" then
        msg[10] = 0x32
        msg[11] = 0x05
    elseif value == "reserve" then
        msg[10] = 0x34
        msg[11] = 0x01
    elseif value == "parts" then
        msg[10] = 0x35
        msg[11] = 0x01
    elseif value == "time" then
        msg[10] = 0x35
        msg[11] = 0x02
    elseif value == "zone" then
        msg[10] = 0x35
        msg[11] = 0x03
    elseif value == "find" then
        msg[10] = 0x35
        msg[11] = 0x07
    end

    return addSumAndConvertMsgToHexString(msg, msgLen)
end

-- 由json转换成电控指令
-- 优先查看 control 节点， 然后查看 query 节点
function jsonToData(jsonStr)
    if #jsonStr == 0 then return nil end

    local j = JSON.decode(jsonStr)

    if checkValidJson(j) == false then return nil end

    if j["control"] ~= nil then
        return handleControlJson(j["control"])
    elseif j["query"] ~= nil then
        return handleQueryJson(j["query"])
    end

    return nil
end

-------------------------------------------------------------------
-- 下面是data 转 json 的代码
-------------------------------------------------------------------
-- 工作状态
local WORK_STATUS_CODE = {
    charge = 0x01, -- 回充中
    work = 0x02, -- 工作中
    stop = 0x03, -- 停止/待机
    charging_on_dock = 0x04, -- 充电中（回充座）
    reserve_task_finished = 0x05, -- 预约任务完成（未使用）
    charge_finish = 0x06, -- 充电完成
    charging_with_wire = 0x07, -- 直流充电中(接线)
    pause = 0x08, -- 暂停
    updating = 0x09, -- 升级中（未使用）
    saving_map = 0x0A, -- 地图保存中（未使用）
    error = 0x0B, -- 报错状态
    sleep = 0x0C, -- 休眠状态
    charge_pause = 0x0D, -- 暂停回充
    relocate = 0x0E, -- 重定位中
    electrolysed_water_making = 0x0F, -- 电解水制作中
    dust_collecting = 0x10, -- 集尘中
    back_dust_collecting = 0x11, -- 回去集尘中
    sleep_in_station = 0x12 -- 站内休眠
}

-- 功能分类
local FUNCTION_TYPE_CODE = {
    dust_box_cleaning = 0x01, -- 尘盒清扫
    water_tank_cleaning = 0x02 -- 水箱清扫
}

-- 0A 指令上报内容
-- byte11 红外传感器提示信息 (低位)
local ERR_0A_INFRA_RED_LOW_CODE = {
    none = 0x07,
    none = 0x06,
    failure_infra_red_low_right_back_fall = 0x05, -- 右后跌落
    failure_infra_red_low_left_back_fall = 0x04, -- 左后跌落
    failure_infra_red_low_right_hanging = 0x03, -- 右轮悬空
    failure_infra_red_low_left_hanging = 0x02, -- 左轮悬空
    failure_infra_red_low_right_collision = 0x01, -- 右边碰撞
    failure_infra_red_low_left_collision = 0x00, -- 左边碰撞
    failure_infra_red_low_center_collision = 0x08 -- 左边碰撞和右边碰撞都发生时： 中间碰撞
}
-- byte12 红外传感器提示信息 (高位)
local ERR_0A_INFRA_RED_HIGH_CODE = {
    failure_infra_red_high_left_front_obstacle = 0x07, -- 左前有障碍物
    failure_infra_red_high_right_front_obstacle = 0x06, -- 右前有障碍物
    failure_infra_red_high_front_obstacle = 0x05, -- 前方有障碍物
    failure_infra_red_high_left_obstacle = 0x04, -- 左边有障碍物
    failure_infra_red_high_right_obstacle = 0x03, -- 右边有障碍物
    failure_infra_red_high_right_fall = 0x02, -- 右边跌落
    failure_infra_red_high_front_fall = 0x01, -- 前边跌落
    failure_infra_red_high_left_fall = 0x00 -- 左边跌落
}
-- byte13 故障信息 (低位)
local ERR_0A_FAILURE_LOW_CODE = {
    failure_low_no_dust_box = 0x07, -- 灰尘盒标识 1=没有灰尘盒
    failure_low_dust_box_full = 0x06, -- 尘盒满标识 1=已满
    failure_low_water_tank_overload = 0x05, -- 水箱电机电流过载  1=已过载
    failure_low_fan = 0x04, -- 风扇标识 1=风扇故障
    failure_low_right_side_brush = 0x03, -- 右边刷标识 1=右边刷故障
    failure_low_left_side_brush = 0x02, -- 左边刷标识 1=左边刷故障
    failure_low_right_wheel_overload = 0x01, -- 右轮过载标识 1=右轮过载
    failure_low_left_wheel_overload = 0x00 -- 左轮过载标识 1=左轮过载

}
-- byte14 故障信息 (中位)
local ERR_0A_FAILURE_MID_CODE = {
    failure_mid_front_collision_switch = 0x07, -- 碰撞标识 1=前边碰撞开关故障
    failure_mid_roll_brush = 0x06, -- 滚刷标识 1=滚刷故障
    failure_mid_right_back_fall_sensor = 0x05, -- 跌落标识 1=右后跌落S故障
    failure_mid_left_back_fall_sensor = 0x04, -- 跌落标识 1=左后跌落S故障
    failure_mid_right_back_hanging_sensor = 0x03, -- 悬空标识 1=右轮悬空S故障
    failure_mid_left_back_hanging_sensor = 0x02, -- 悬空标识 1=左轮悬空S故障
    failure_mid_right_collision_switch = 0x01, -- 碰撞标识 1=右边碰撞开关故障
    failure_mid_left_collision_switch = 0x00 -- 碰撞标识 1=左边碰撞开关故障
}

-- byte15 故障信息 (高位)
local ERR_0A_FAILURE_HIGH_CODE = {
    failure_high_left_front_infra_red = 0x07, -- 障碍标识 1=左前红外故障
    failure_high_right_front_infra_red = 0x06, -- 障碍标识 1=右前红外故障
    failure_high_front_infra_red = 0x05, -- 障碍标识 1=前方红外故障
    failure_high_left_infra_red = 0x04, -- 障碍标识 1=左边红外故障
    failure_high_right_infra_red = 0x03, -- 障碍标识 1=右边红外故障
    failure_high_right_drop_sensor = 0x02, -- 跌落标识 1=右边跌落S故障
    failure_high_front_drop_sensor = 0x01, -- 跌落标识 1=前边跌落S故障
    failure_high_left_drop_sensor = 0x00 -- 跌落标识 1=左边跌落S故障
}

-- byte16 用户提示低位
local ERR_0A_USER_LOW_CODE = {
    failure_user_low_no_dust_box = 0x07, -- 安装尘盒标识  1=未安装
    failure_user_low_dust_box_full = 0x06, -- 尘盒满标识位 1=尘盒满
    failure_user_low_no_water_tank = 0x05, --  水箱标识 1=未安装
    failure_user_low_water_tank_error = 0x04, -- 水泵标识 1=水泵故障
    failure_user_low_no_water = 0x03, -- 水箱缺水标识位 1=缺水
    failure_user_low_charging_switch_off = 0x02, -- 充电电源开关标识 1=未打开
    failure_user_low_charge_error = 0x01, -- 充电故障标识 1=故障
    failure_user_low_network_failed = 0x00 -- 配网故障标识 1=配网失败
}
-- byte17 用户提示中位
local ERR_0A_USER_MID_CODE = {
    none = 0x07,
    none = 0x06,
    failure_user_mid_board_communication_error = 0x05, -- 底板与导航板通信异常故障 1=故障
    failure_user_mid_laser_sensor_shelter = 0x04, -- 激光传感器被遮挡标识 1=故障
    failure_user_mid_laser_sensor_error = 0x03, -- 激光传感器故障标识 1=故障
    failure_user_mid_low_battery = 0x02, -- 电量不足标识 1=故障
    failure_user_mid_camera_error = 0x01, -- 摄像头故障标识 1=故障
    failure_user_mid_vacuum_engine_overload = 0x00 -- 吸尘电机故障标识  1=过载
}

-- 状态摘要低位 byte 24
local STATUS_SUMMARY_LOW_CODE = {
    status_summary_uv_switch = 0x00, -- UV灯标识位 1=UV灯打开 0=UV灯关闭
    status_summary_wifi_switch = 0x01, -- WIFI灯标识 1=关 0=灯开
    status_summary_voice_switch = 0x02, -- 语音开关  1=打开 0=关闭
    none = 0x03,
    none = 0x04,
    none = 0x05,
    status_summary_command_source = 0x06, --  指令上下行标识  1=指令由电控触发04 0=其它如APP触发
    status_summary_device_error = 0x07 --  设备故障位标识  1=有故障 0=无故障
}

-- byte25 用户提示低位
local ERR_USER_LOW_CODE = {
    user_low_no_dust_box = 0x07, -- 安装尘盒标识  1=未安装
    user_low_dust_box_full = 0x06, -- 尘盒满标识位 1=尘盒满
    none = 0x05,
    user_low_firmware_can_upgrade = 0x04, -- 电控板升级标识 1=可以升级
    user_low_no_water = 0x03, -- 水箱缺水标识位 1=缺水
    user_low_charging_switch_off = 0x02, -- 充电电源开关标识 1=未打开
    user_low_f_b_plate_stuck = 0x01, -- 卡住标识 1=前后挡板卡住
    user_low_l_r_wheel_hang = 0x00 -- 悬空标识 1=左右轮悬空
}
-- byte26 用户提示中位
local ERR_USER_MID_CODE = {
    none = 0x07,
    user_mid_roll_brush_overload = 0x06, -- 滚刷故障标识     1=过载
    user_mid_right_side_brush_overload = 0x05, -- 右边刷故障标识   1=过载
    user_mid_left_side_brush_overload = 0x04, -- 左边刷故障标识   1=过载
    user_mid_vacuum_engine_overload = 0x03, -- 吸尘电机故障标识 1=过载
    user_mid_right_wheel_overload = 0x02, -- 右轮过载标识     1=过载
    user_mid_left_wheel_overload = 0x01, -- 左轮过载标识     1=过载
    user_mid_drop = 0x00 -- 跌落标识         1=跌落
}

-- byte29 用户提示高位
local ERR_USER_HIGH_CODE = {
    none = 0x07,
    none = 0x06,
    none = 0x05,
    none = 0x04,
    none = 0x03,
    user_high_board_communication_error = 0x02, -- 主板与导航板通信异常故障标识 1=故障
    user_high_laser_sensor_shelter = 0x01, -- 激光传感器被遮挡标识  1=故障
    user_high_laser_sensor_error = 0x00 -- 激光传感器故障标识    1=故障
}

-- 根据数值， 返回对应的字符串
local function getCodeStr(dict, value)
    for k, v in pairs(dict) do if v == value then return k end end
    return nil
end

-- 根据一个字节转换成一周的天数
local function convertWorkdaysFromByte(weekdayByte)
    local rst = ""
    for i = 1, 7 do
        if bit.band(weekdayByte, bit.lshift(0x01, i - 1)) > 0 then
            rst = rst .. tostring(i)
        end
    end
    return rst
end

-- 转换电控指令字符串，成为一个数组
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
    -- return JSON.encode(table)
end

-- 翻译 02 22
local function decodeWorkBin(bin)
    local workMode = bin[11]
    local controlMode = bin[13]
    local moveDirection = bin[14]
    local cleanMode = bin[15]
    local fanLevel = bin[16]
    local waterLevel = bin[18]
    local speakLevel = bin[19]
    local zoneId = bin[20]
    local control = {}

    -- 0x02 工作
    if workMode == 0x02 then
        control["work_status"] = "work"
        -- 自动清扫模式
        if controlMode == 0x02 then
            control["work_mode"] = getCodeStr(CLEAN_MODE_CODE, cleanMode)
        elseif controlMode == 0x01 then
            -- 手动控制方向
            control["move_direction"] = getCodeStr(MOVEMENT_CODE, moveDirection)
        end
        control["fan_level"] = getCodeStr(FAN_LEVEL_CODE, fanLevel)
        control["water_level"] = getCodeStr(WATER_LEVEL_CODE, waterLevel)
        control["speak_level"] = getCodeStr(SPEAK_LEVEL_CODE, speakLevel)
        control["zone_id"] = tostring(zoneId)
    end

    return wrapTableToJson("status", control)
end

-- 翻译回充/停止
local function decodeChargeStopBin(bin)
    local workMode = bin[11]

    local control = {}
    if workMode == 0x01 then
        control["work_status"] = "charge"
    elseif workMode == 0x03 then
        control["work_status"] = "stop"
    elseif workMode == 0x1B then
        control["work_status"] = "pause"
    end

    return wrapTableToJson("control", control)
end

-- 翻译 开关量设置
local function decodeSwitchBin(bin)
    local workMode = bin[11]
    local fan = bin[12]
    local area = bin[13]
    local water = bin[14]

    local control = {}
    if workMode == 0x04 then control["work_status"] = "switch" end

    control["fan_level"] = getCodeStr(FAN_LEVEL_CODE, fan)
    control["area"] = tostring(area)
    control["water_level"] = getCodeStr(WATER_LEVEL_CODE, water)

    return wrapTableToJson("control", control)
end

-- 翻译勿扰
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

-- 翻译预约
local function decodeReserveBin(bin)
    local action = bin[12]

    -- 计算预约条数
    local msgLen = bin[1]
    local reserveCnt = (msgLen - 13) / 12

    -- 删除/设置/恢复 时，有且只有一只Task
    local firstTaskId = bin[24]

    local control = {}
    control["work_status"] = "reserve"

    if action == 0x01 then
        -- 设置预约
        control["action"] = "set"
        local data = {}
        -- 开始遍历每一条预约信息
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
        -- 删除预约
        control["action"] = "delete"
        control["task_id"] = firstTaskId
    elseif action == 0x05 then
        -- 设置预约不可用
        control["action"] = "off"
        control["task_id"] = firstTaskId
    elseif action == 0x06 then
        -- 恢复预约可用
        control["action"] = "on"
        control["task_id"] = firstTaskId
    end

    return wrapTableToJson("control", control)
end

-- 翻译音量控制
local function decodeVoiceVolumeBin(bin)
    local action = bin[12]
    local control = {}
    control["work_status"] = "voice"
    control["value_level"] = tostring(action)
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

-- 翻译控制命令 0x02
local function decodeControlData(bin)
    local msgSubType = bin[10]
    local workMode = bin[11]

    -- 22
    if msgSubType == 0x22 then
        if workMode == 0x02 then
            return decodeWorkBin(bin)
        elseif workMode == 0x01 or workMode == 0x03 then
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
        elseif workMode == 0x0a then
            return decodeVoiceVolumeBin(bin)
        elseif workMode == 0x1B then
            return decodeChargeStopBin(bin)
        elseif workMode == 0x1C then
            return decodeChargeStopBin(bin)
        end
    elseif msgSubType == 0x24 then
        return decodeReserveBin(bin)
    end

    return bin
end

-- 工作参数类查询
local function decodeQueryWorkStatusBin(bin)
    local workStatus = bin[12]
    local functionType = bin[13]
    local controlType = bin[14]
    local movement = bin[15]
    local cleanMode = bin[16]
    local fanLevel = bin[17]
    local area = bin[18]
    local waterLevel = bin[19]
    local voiceVolume = bin[20]
    local reserveWeekday = bin[21]
    local batteryRatio = bin[22]
    local workMin = bin[23]
    local statusSummary = bin[24]

    local errUserLow = bin[25] or 0
    local errUserMid = bin[26] or 0

    local mop = bin[27] or 0
    local carpet_switch = bin[28] or 0
    local errUserHigh = bin[29] or 0
    local speed = bin[30] or 1

    local query = {}
    query["query_type"] = "work"

    if controlType == nil then return wrapTableToJson("status", query) end

    query["error_type"] = getCodeStr(ERROR_TYPE_OF_A0A3, errUserLow)
    query["error_desc"] = "no"

    if errUserLow == 0x01 then
        query["error_desc"] = getCodeStr(ERROR_FIX_DESC_OF_A0A3, errUserMid)
    elseif errUserLow == 0x02 then
        query["error_desc"] = getCodeStr(ERROR_REBOOT_DESC, errUserMid)
    elseif errUserLow == 0x03 then
        query["error_desc"] = getCodeStr(ERROR_WARN_DESC_OF_A0A3, errUserMid)
    end

    for i = 0, 7 do
        local name = getCodeStr(STATUS_SUMMARY_LOW_CODE, i)
        if name ~= nil and name ~= "none" then
            query[name] = bitAt(statusSummary, i) == true and "yes" or "no"
        end
        -- 故障用户提示高位
        name = getCodeStr(ERR_USER_HIGH_CODE, i)
        if name ~= nil and name ~= "none" then
            query[name] = bitAt(errUserHigh, i) == true and "yes" or "no"
        end
    end

    query["work_status"] = getCodeStr(WORK_STATUS_CODE, workStatus)
    query["function_type"] = getCodeStr(FUNCTION_TYPE_CODE, functionType)
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

    query["carpet_switch"] = carpet_switch == 0x01 and "yes" or "no"
    query["speed"] = speed == 0x01 and "low" or "high"

    if reserveWeekday == 0 then
        query["have_reserve_task"] = "0"
    else
        query["have_reserve_task"] = "1"
    end

    query["battery_percent"] = tostring(batteryRatio)
    query["work_time"] = tostring(workMin)
    return wrapTableToJson("status", query)
end

-- 翻译查询勿扰命令
local function decodeQueryDisturbBin(bin)
    local setStatus = bin[12] or 0
    local startHour = bin[13] or 0
    local startMin = bin[14] or 0
    local endHour = bin[15] or 0
    local endMin = bin[16] or 0

    -- 解析查询语句
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

-- 翻译预约查询
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

local function decodeQueryCommand(bin)
    local a = bin[10] or 0x00
    local b = bin[11] or 0x00
    local c = "work"
    local q = {}
    if a == 0x32 then
        if b == 0x01 then
            c = "work"
        elseif b == 0x02 then
            c = "control"
        elseif b == 0x03 then
            c = "abnormal"
        elseif b == 0x04 then
            c = "error"
        elseif b == 0x05 then
            c = "disturb"
        end
    elseif a == 0x34 then
        if b == 0x01 then c = "reserve" end
    elseif a == 0x35 then
        if b == 0x01 then
            c = "parts"
        elseif b == 0x02 then
            c = "time"
        elseif b == 0x03 then
            c = "zone"
        end
    end

    q["query"] = c
    return wrapTableToJson("status", q)
end

-- 异常查询结果
local function decodeQueryAbnormalBin(bin)
    local q = {}
    q["query"] = "abnormal"
    local temp = bin[12]
    local humidity = bin[13]
    local time = bin[14]
    local restMinLow = bin[15]
    local restMinHigh = bin[16]
    local restMin = bit.lshift(restMinHigh, 8) + restMinLow
    q["temperature"] = tostring(temp)
    q["humidity"] = tostring(humidity)
    q["work_time"] = tostring(time)
    q["rest_time"] = tostring(restMin)
    return wrapTableToJson("status", q)
end

-- 翻译查询命令 0x03
local function decodeQueryData(bin)
    local msgSubType = bin[10]
    local statusType = bin[11]

    if #bin == 0x0C then return decodeQueryCommand(bin) end

    -- 工作参数类查询
    if msgSubType == 0x32 then
        if statusType == 0x01 then
            return decodeQueryWorkStatusBin(bin)
        elseif statusType == 0x03 then
            -- 异常查询结果
            return decodeQueryAbnormalBin(bin)
        elseif statusType == 0x05 then
            return decodeQueryDisturbBin(bin)
        end
    elseif msgSubType == 0x34 then
        -- 预约查询
        if statusType == 0x01 then return decodeQueryObserverBin(bin) end
    elseif msgSubType == 0x35 then
        return decodeQueryParts(bin)
    end
    return ""
end

-- 主动上报翻译
local function decode0442Report(bin)
    -- 部分上报
    local workStatus = bin[11]
    local functionType = bin[12]
    local controlType = bin[13]
    local movement = bin[14]
    local cleanMode = bin[15]
    local fanLevel = bin[16]
    local area = bin[17]
    local waterLevel = bin[18]
    local voiceVolume = bin[19]
    local reserveWeekday = bin[20]
    local batteryRatio = bin[21]
    local workMin = bin[22]
    local statusSummary = bin[23]
    local errUserLow = bin[24]
    local errUserMid = bin[25]
    local mop = bin[26] or 0
    local carpet_switch = bin[27] or 0
    local speed = bin[28] or 1

    local query = {}
    for i = 0, 7 do
        -- 状态摘要低位
        local name = getCodeStr(STATUS_SUMMARY_LOW_CODE, i)
        if name ~= nil and name ~= "none" then
            query[name] = bitAt(statusSummary, i) == true and "yes" or "no"
        end
        -- 故障用户提示低位
        name = getCodeStr(ERR_USER_LOW_CODE, i)
        if name ~= nil and name ~= "none" then
            query[name] = bitAt(errUserLow, i) == true and "yes" or "no"
        end
        -- 故障用户提示中位
        name = getCodeStr(ERR_USER_MID_CODE, i)
        if name ~= nil and name ~= "none" then
            query[name] = bitAt(errUserMid, i) == true and "yes" or "no"
        end
    end

    query["work_status"] = getCodeStr(WORK_STATUS_CODE, workStatus)
    query["function_type"] = getCodeStr(FUNCTION_TYPE_CODE, functionType)
    query["control_type"] = getCodeStr(CONTROL_TYPE_CODE, controlType)
    query["move_direction"] = getCodeStr(MOVEMENT_CODE, movement)
    query["work_mode"] = getCodeStr(CLEAN_MODE_CODE, cleanMode)
    query["fan_level"] = getCodeStr(FAN_LEVEL_CODE, fanLevel)
    query["area"] = tostring(area)
    query["water_level"] = getCodeStr(WATER_LEVEL_CODE, waterLevel)
    query["voice_level"] = tostring(voiceVolume)
    if reserveWeekday == 0 then
        query["have_reserve_task"] = "0"
    else
        query["have_reserve_task"] = "1"
    end
    query["battery_percent"] = tostring(batteryRatio)
    query["work_time"] = tostring(workMin)
    query["mop"] = mop == 0x1 and "yes" or "no"
    query["carpet_switch"] = carpet_switch == 0x01 and "yes" or "no"
    query["speed"] = speed == 0x01 and "low" or "high"

    return wrapTableToJson("status", query)
end

local function decode0452Report(bin)
    local query = {}
    local event = bin[11]
    -- 0452 : 清扫事件
    -- 0x01 = 预约清扫启动
    query["schedule_clean_start"] = event == 0x01 and "yes" or "no"
    -- 0x02 = 预约清扫完成
    query["schedule_clean_end"] = event == 0x02 and "yes" or "no"
    -- 0x03 = 断点续扫启动
    query["power_continue_clean"] = event == 0x03 and "yes" or "no"
    -- 0x04 = 断点续扫完成
    query["power_continue_end"] = event == 0x04 and "yes" or "no"
    -- 0x05 = 重定位失败，无法清扫
    query["location_fail_not_start"] = event == 0x05 and "yes" or "no"
    -- 0x06 = 重定位失败，无法到达目标点
    query["location_fail_not_target"] = event == 0x06 and "yes" or "no"

    return wrapTableToJson("status", query)
end

-- 翻译运行状态命令 0x04
local function decodeRunStatusData(bin)
    local msgSubType = bin[10]
    if msgSubType == 0x42 then
        return decode0442Report(bin)
    elseif msgSubType == 0x52 then
        return decode0452Report(bin)
    end
    return nil
end

-- 翻译累计数据 0x06
local function decodeSumData(bin)
    local msgSubType = bin[10]
    local sumType = bin[11]

    -- 寿命数据上报
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

    -- 单次清扫数据
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

-- 翻译M7故障上报
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

-- 翻译 故障信息上报
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

        -- 故障上报类型
        for i = 0, 7 do
            -- byte11 红外传感器提示信息 (低位)
            local name = getCodeStr(ERR_0A_INFRA_RED_LOW_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(infra_red_low, i) == true and "yes" or "no"
            end

            -- byte12 红外传感器提示信息 (高位)
            name = getCodeStr(ERR_0A_INFRA_RED_HIGH_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(infra_red_high, i) == true and "yes" or "no"
            end

            -- byte13 故障信息 (低位)
            name = getCodeStr(ERR_0A_FAILURE_LOW_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(failure_low, i) == true and "yes" or "no"
            end

            -- byte14 故障信息 (中位)
            name = getCodeStr(ERR_0A_FAILURE_MID_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(failure_mid, i) == true and "yes" or "no"
            end

            -- byte15 故障信息 (高位)
            name = getCodeStr(ERR_0A_FAILURE_HIGH_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(failure_high, i) == true and "yes" or "no"
            end

            -- byte16 用户提示低位
            name = getCodeStr(ERR_0A_USER_LOW_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(user_info_low, i) == true and "yes" or "no"
            end

            -- byte17 用户提示中位
            name = getCodeStr(ERR_0A_USER_MID_CODE, i)
            if name ~= nil and name ~= "none" then
                query[name] = bitAt(user_info_mid, i) == true and "yes" or "no"
            end

        end

        -- 左边碰撞和右边碰撞都发生时， 显示为 中间碰撞
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

-- 校验bin的长度参数和 sum 参数
local function checkBinSum(bin)
    local msgLen = bin[1]

    -- 校验实际长度 : #bin 不会统计 bin[0] 的数量
    if msgLen ~= #bin then
        dLog("msgLen no valid")
        return false
    end

    -- 校验开头 0xAA
    if bin[0] ~= 0xaa then rst = false end
    -- 校验品类 0xB8
    if bin[2] ~= 0xb8 then rst = false end

    -- 校验 sum
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

-- 电控指令转json
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
