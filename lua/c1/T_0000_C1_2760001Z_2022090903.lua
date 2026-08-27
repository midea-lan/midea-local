local bit = require "bit"
---- 电壁挂炉协议解析  yaohf1
---- local 方法必须要定义在调用的方法之前才可以使用，所以公共函数必须优先申明

local VALUE_VERSION = 2
local JSON = require "cjson"

---------------------------------------一些公共的函数-----------------------------
--------------sum校验
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
end

----------将指令字符串 AA00B60000000000000200 转 table数组
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

-- 十六进制 string 输出
local function string2hexstring(str)
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end

-- table 转 string
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end

-- 检查取值是否超过边界
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

-- 按逗号分割
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

-- 获取到A0值，判断新旧型号

local function parseDevFlag(value, tab)
    for k, v in ipairs(tab) do if v == value then return true; end end
    return false;
end

-------把业务逻辑json转化为byte数组
local function assembleByteFromJson(result, msgBytes)
    -- 美居将指令分为：查询03指令、控制02指令、状态上报04指令
    -- lua table 索引从 1 开始，因此协议里byte每位+1
    local query = result["query"]
    local control = result["control"]
    local status = nil
    local devInfoData = result["deviceinfo"]["deviceSubType"]

    if (result["status"]) then status = result["status"] end

    if (control) then
        msgBytes[10] = 0x02 -- 控制
        -- 开关机
        if (control["power"]) then
            if (control["power"] == "on" or control["power"] == 1) then
                msgBytes[11] = 0x01
                msgBytes[12] = 0x01
            elseif (control["power"] == "off" or control["power"] == 0) then
                msgBytes[11] = 0x02
                msgBytes[12] = 0x01
            end
        else
            -- 分段功能
            for i = 11, 17 do msgBytes[i] = 0x00 end
            msgBytes[11] = 0x14
            -- 供热方式
            if (control["hot_style"]) then
                msgBytes[12] = 0x02
                if (control["hot_style"] == 1) then
                    msgBytes[13] = bit.bor(msgBytes[13], 0x01)
                end
                if (control["hot_style"] == 2) then
                    msgBytes[13] = bit.bor(msgBytes[13], 0x02)
                end
            end
            -- 卫浴功能
            if (control["bash_mode"]) then
                msgBytes[12] = 0x03
                if (control["bash_target_temperature"]) then
                    msgBytes[13] = control["bash_target_temperature"]
                end
                if (control["bash_gap_temperature"]) then
                    msgBytes[14] = control["bash_gap_temperature"]
                end
                if (control["bash_mode"]) then
                    msgBytes[15] = control["bash_mode"]
                end
            end
            -- 采暖模式
            if (control["heating_mode"]) then
                msgBytes[12] = 0x04
                msgBytes[13] = control["heating_mode"]
                if (control["heating_target_temperature"]) then
                    msgBytes[14] = control["heating_target_temperature"]
                end
                if (control["last_time"]) then
                    msgBytes[15] = control["last_time"]
                end
                if (control["heating_gap_temperature"]) then
                    msgBytes[16] = control["heating_gap_temperature"]
                end
            end
            -- 蜂鸣器开关
            if (control["buzzer"]) then
                msgBytes[12] = 0x1e
                msgBytes[13] = control["buzzer"]
            end
        end
        -- 取消预约
        if (control["appoint_power"] and control["appoint_power"] == "off") then
            msgBytes[11] = 0x0A
            msgBytes[12] = 0x01
            msgBytes[13] = 0x04
            msgBytes[14] = 0x00
            msgBytes[15] = 0x00
            for i = 16, 30 do msgBytes[i] = 0x00 end
        end
        -- 预约，暂时没用
        if (control["appoint0"] ~= nil) then
            for i = 11, 20 do msgBytes[i] = 0x00 end
            local ap
            if (control["appoint0"] ~= nil) then
                msgBytes[11] = 0x05
                ap = Split(control["appoint0"], ",")
            end
            msgBytes[12] = 0x01
            for k, v in pairs(ap) do
                if (k == 1) then
                    if (tonumber(v) == 1) then
                        msgBytes[13] = 0xff
                    else
                        msgBytes[13] = 0x00
                    end
                else
                    msgBytes[k + 12] = tonumber(v)
                end
            end
        end
    elseif (query) then
        msgBytes[10] = 0x03 -- 查询
        if (query["query_type"] == "appoint_query") then
            msgBytes[11] = 0x02
        else
            msgBytes[11] = 0x01
        end
        msgBytes[12] = 0x01
    end
    return msgBytes
end

local function parseByteToJson(status, bodyBytes)
    -- 当前状态
    if ((bodyBytes[10] == 0x02 and bodyBytes[11] == 0x01) or
        (bodyBytes[10] == 0x02 and bodyBytes[11] == 0x02) or
        (bodyBytes[10] == 0x02 and bodyBytes[11] == 0x04) or
        (bodyBytes[10] == 0x02 and bodyBytes[11] == 0x14) or
        (bodyBytes[10] == 0x03 and bodyBytes[11] == 0x01) or
        (bodyBytes[10] == 0x04 and bodyBytes[11] == 0x01)) then

        -- 开/关机
        if (bodyBytes[13] and bit.band(bodyBytes[13], 0x01) == 0x01) then
            status["power"] = "on"
        else
            status["power"] = "off"
        end
        -- 待机中
        if (bodyBytes[13] and bit.band(bodyBytes[13], 0x02) == 0x02) then
            status["wait_power"] = "on"
        else
            status["wait_power"] = "off"
        end
        -- 加热中
        if (bodyBytes[13] and bit.band(bodyBytes[13], 0x04) == 0x04) then
            status["hot_power"] = "on"
        else
            status["hot_power"] = "off"
        end
        -- 保温中
        if (bodyBytes[13] and bit.band(bodyBytes[13], 0x08) == 0x08) then
            status["warm_power"] = "on"
        else
            status["warm_power"] = "off"
        end
        -- 防冻中
        if (bodyBytes[13] and bit.band(bodyBytes[13], 0x10) == 0x10) then
            status["cold_power"] = "on"
        else
            status["cold_power"] = "off"
        end
        -- 休眠中
        if (bodyBytes[13] and bit.band(bodyBytes[13], 0x20) == 0x20) then
            status["sleep_power"] = "on"
        else
            status["sleep_power"] = "off"
        end
        -- 预约中
        if (bodyBytes[13] and bit.band(bodyBytes[13], 0x40) == 0x40) then
            status["appoint_power"] = "on"
        else
            status["appoint_power"] = "off"
        end
        -- 故障代码1   优先级别从高到低：通信故障、进出水传感器故障、结冰故障、水泵故障、水压故障、超温故障
        -- status["error_code1"]=tonumber(bodyBytes[14])
        -- 故障代码2
        -- status["error_code2"]=tonumber(bodyBytes[15])

        if (bodyBytes[14] and bit.band(bodyBytes[14], 0x01) == 0x01) then
            status["error_code"] = "F0"
        elseif (bodyBytes[15] and bit.band(bodyBytes[15], 0x01) == 0x01) then
            status["error_code"] = "F2"
        elseif (bodyBytes[14] and bit.band(bodyBytes[14], 0x80) == 0x80) then
            status["error_code"] = "E8"
        elseif (bodyBytes[14] and bit.band(bodyBytes[14], 0x40) == 0x40) then
            status["error_code"] = "E7"
        elseif (bodyBytes[14] and bit.band(bodyBytes[14], 0x10) == 0x10) then
            status["error_code"] = "E3"
        elseif (bodyBytes[14] and bit.band(bodyBytes[14], 0x04) == 0x04) then
            status["error_code"] = "E1"
        else
            status["error_code"] = "normal"
        end

        -- 额定功率低字节
        status["rate_lower"] = tonumber(bodyBytes[16])
        -- 额定功率高字节
        status["rate_high"] = tonumber(bodyBytes[17])
        -- 进水温度
        status["in_temperature"] = tonumber(bodyBytes[18])
        -- 出水温度
        status["out_temperature"] = tonumber(bodyBytes[19])
        -- 卫浴温度
        status["bash_temperature"] = tonumber(bodyBytes[20])
        -- 卫浴目标温度
        status["bash_target_temperature"] = tonumber(bodyBytes[21])
        -- 卫浴模式
        status["bash_mode"] = tonumber(bodyBytes[22])

        -- 采暖实际温度
        status["heating_temperature"] = tonumber(bodyBytes[23])
        -- 采暖设置温度
        status["heating_target_temperature"] = tonumber(bodyBytes[24])
        -- 采暖模式
        status["heating_mode"] = tonumber(bodyBytes[25])
        -- 采暖回差温度设置
        status["heating_gap_temperature"] = tonumber(bodyBytes[26])

        -- 持续加热时间
        status["last_time"] = tonumber(bodyBytes[27])
        -- 实时功率（低位）
        status["cur_rate_lower"] = tonumber(bodyBytes[28])
        -- 实时功率（高位）
        status["cur_rate_high"] = tonumber(bodyBytes[29])
        -- 流量
        status["flow_volume"] = tonumber(bodyBytes[30])
        -- 供热方式
        status["hot_style"] = tonumber(bodyBytes[31])
        -- 卫浴功能
        status["bash_function"] = tonumber(bodyBytes[32])
        -- 蜂鸣器开关
        if (bodyBytes[33] and bit.band(bodyBytes[33], 0x01) == 0x01) then
            status["buzzer"] = "on"
        else
            status["buzzer"] = "off"
        end
        -- 水泵开关
        if (bodyBytes[33] and bit.band(bodyBytes[33], 0x02) == 0x02) then
            status["pump"] = "on"
        else
            status["pump"] = "off"
        end
        -- 三通阀执行模式
        if (bodyBytes[33] and bit.band(bodyBytes[33], 0x04) == 0x04) then
            status["three_way_mode"] = "bath"
        else
            status["three_way_mode"] = "heating"
        end

        -- 采暖器件类型
        if (bodyBytes[33] and bit.band(bodyBytes[33], 0x08) == 0x08) then
            status["heating_unit_type"] = "radiator"
        else
            status["heating_unit_type"] = "floor_heating"
        end

        -- 屏幕亮度
        if (bodyBytes[33]) then
            status["light_gear"] = bit.rshift(bodyBytes[33], 5)
        end

        -- 用户模式设置温度
        status["user_mode_target_temperature"] = tonumber(bodyBytes[34])
        -- 活动模式设置温度
        status["activity_mode_target_temperature"] = tonumber(bodyBytes[35])
        -- 睡眠模式设置温度
        status["sleep_mode_target_temperature"] = tonumber(bodyBytes[36])

        -- 预约状态
    elseif ((bodyBytes[10] == 0x02 and bodyBytes[11] == 0x05) or
        (bodyBytes[10] == 0x02 and bodyBytes[11] == 0x06) or
        (bodyBytes[10] == 0x02 and bodyBytes[11] == 0x07) or
        (bodyBytes[10] == 0x03 and bodyBytes[11] == 0x02)) then

        if (bit.band(bodyBytes[13], 0x01) == 0x01) then
            status["appoint0"] = "1,"
        else
            status["appoint0"] = "0,"
        end
        status["appoint0"] = status["appoint0"] .. tostring(bodyBytes[14]) ..
                                 "," .. tostring(bodyBytes[15]) .. "," ..
                                 tostring(bodyBytes[16]) .. "," ..
                                 tostring(bodyBytes[17])
    end

    status["version"] = VALUE_VERSION

    return status
end

--
-- * 1. jsonToData  和 dataToJson的参数格式一样如下：
-- {
--    "deviceinfo": {},
--   "control": {},
--    "query": {},
--    "status": {},
--    "msg": { ------------dataToJson读取该属性
--        "data": "112233445566"
--   }
-- }

------------------json转化为cmd二进制, 云端到设备端控制指令入口-------------------
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    result = JSON.decode(jsonCmdStr)
    if result == nil then return end

    local msgBytes = {0xAA, 0x00, 0xC1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    ---将业务json转化为对应的byte数组数据
    msgBytes = assembleByteFromJson(result, msgBytes)
    ---计算长度、checksum
    local len = #msgBytes
    msgBytes[2] = len
    msgBytes[len + 1] = makeSum(msgBytes, 2, len)
    -- table 转换成 string 之后返回
    local ret = table2string(msgBytes)
    ret = string2hexstring(ret)
    return ret
end

----------------------------二进制cmd转化为json,设备端到云端入口----------
-- 1. 先判断有没有status,有则先更新里面的全字段的值
-- 2. 没有，则由指令生成对应的部分状态的值

function dataToJson(cmdStr)
    if (not cmdStr) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    result = JSON.decode(cmdStr)
    if result == nil then return end

    local binData = result["msg"]["data"]
    -- local status = result["status"]

    local ret = {}
    ret["status"] = {}
    -- if (status) then
    --     ret["status"] = status
    -- end
    local bodyBytes = string2table(binData)
    ret["status"] = parseByteToJson(ret["status"], bodyBytes)
    local ret = JSON.encode(ret)
    return ret
end
