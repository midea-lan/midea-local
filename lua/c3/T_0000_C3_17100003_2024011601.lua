local bit = require "bit"
-- 协议解析文件描述，根据实际情况修正
-- author : nixj8
--        : laojr1
-- email  : laojr1@midea.com
-- date   : 2023/5/20
-- 0xC3   : 120L Controller
-- 修改记录
-- 2023-05-16 创建修改记录
-- 2023-05-20 dataToJson 不再返回全部字段
-- 2023-05-22 jsonToData 强制更新关联值
-- 2023-05-26 更新模式的 key_map
-- 2023-05-29 更新 mode 的取值范围
-- 2023-06-03 更新只读温度类型
-- 2023-06-08 基本参数增加 t4
-- 2023-06-09 基本参数增加 error_code_str
-- 2023-06-10 增加 writable 属性，限制 jsonToData 修改只读属性的点位
-- 2023-06-12 基本参数增加 error_new_code
-- 2023-06-13 修改0x10部分数据类型
-- 2023-06-16 限制时间设置范围
-- 2023-06-19 限制安装参数功率设置范围/限制时间设置范围/增加外出休假温度点位
-- 2023-06-20 增加config_code
-- 2023-06-25 修改热量&电量类型/用error_code_str覆盖error_code/修改部分映射类型值
-- 2023-06-26 直流母线电流/直流母线电压处理类型
-- 2023-06-26 更新能源数据
-- 2023-07-12 更新末端类型
-- 2023-07-18 能耗分析数据处理更新
-- 2023-09-12 标记上传命令类型，标记点位所属类型
-- 2023-09-19 加入新点位
-- 2023-09-26 静音模式加入强劲/Level_3
-- 2023-10-10 更新主动上报
-- 2023-10-12 更新虚拟值
-- 2023-11-07 增加同步安装参数
-- 2023-11-09 增加区域2自定义曲线
-- 2023-11-10 增加内机/外机版本日期
-- 2023-11-21 增加unitModeRun/reserved1521-1524
-- 2023-11-22 0405的backup放到01查询，更新0405等
-- 2023-11-27 更新杀菌点位 disinfect_valid/disinfect_control
-- 2023-12-08 更新0x30配置参数范围信息命令
-- 2023-12-11 安装设定参数，增加区域末端类型设置
-- 2023-12-14 参数范围设定，增加支持区域2制冷/PumpO控制/T1SCLMIN
-- 2023-12-21 参数范围设定，增加支持T9i/T9o/Exc2/Exv3，增加版本补丁字符串
-- 2023-12-26 处理异常报文
-- 2023-12-29 处理控制异常
-- 2024-01-16 安装设定参数，t1SCLmin

-- 必须要引入的库

local test = 0
local lua_version = {0, 0, 144}

if test >= 2 then
    -- package.cpath = '/usr/lib/x86_64-linux-gnu/lua/5.4/?.so;'
    bit = require "bit"
end
local JSON = require "cjson"
local function io_debug(data) if test >= 3 then io.write(data) end end

local function io_msg(data)
    if test >= 2 then
        local layout_num = 1
        local pad = ''
        for i = 10, 1, -1 do
            if nil ~= debug.getinfo(i) and nil ~= debug.getinfo(i).name then
                layout_num = i
                break
            end
        end
        for i = 1, layout_num - 1 do pad = pad .. '  ' end

        if string.sub(data, -string.len('\n')) ~= '\n' then
            io.write(pad .. '  ' .. data)
            return
        end
        if layout_num >= 2 then
            io.write(pad .. debug.getinfo(2).name .. ' ' .. data)
        else
            io.write(pad .. data)
        end
    end
end

local function io_err(data) if test >= 1 then io.write(data) end end

-- 协议相关常量，请勿修改

-- 控制请求
local BYTE_CONTROL_REQUEST = 0x02
-- 查询请求
local BYTE_QUERY_REQUEST = 0x03
-- 协议头
local BYTE_PROTOCOL_HEAD = 0xAA
-- 协议头长度
local BYTE_PROTOCOL_LENGTH = 0x0A

-- 公共属性值，预定义的值，请勿修改
-- 属性值为未知值时，使用此值。
local VALUE_UNKNOWN = "unknown"
-- 属性值为无效值时，使用此值。
local VALUE_INVALID = "invalid"

-- 协议相关变量,此部分根据实际需要修改，但是local变量的个数不能超过60个，若超过，请使用table封装变量。

-- 数据返回类型，02:控制返回, 03:查询返回, 04:主动上报, 05:主动上报(需要响应), 06:设备异常事件上报。
-- 子命令（若有）

-- nixj8 add
local language = {supported = "CH,EN", current = "CH"}

-- nixj8 add done

-- 公共的函数，请勿随意修改。

-- 从电控协议(byteData)中提取消息体(body)，返回的消息体数组索引从0开始。
local function extractBodyBytes(byteData)
    local msgLength = #byteData
    local msgBytes = {}
    local bodyBytes = {}
    for i = 1, msgLength do msgBytes[i - 1] = byteData[i] end
    -- 去掉消息头和校验码就剩下消息体
    local bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    -- 获取消息体 body 部分
    for i = 0, bodyLength - 1 do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    return bodyBytes
end

-- 计算校验和
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
end

-- 1.将bodyBytes组装上电控协议头(10字节)和尾部校验码(1字节)。
-- 2.传入的 bodyBytes 为索引从0开始。
-- 3.返回的 table 索引也从0开始。
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if bodyLength == 0 then return nil end

    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}

    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    -- 构造消息部分
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = 0x13
    msgBytes[9] = type

    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end

    msgBytes[msgLength - 1] = makeSum(msgBytes, 1, msgLength - 2)
    return msgBytes
end

-- CRC码表
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

-- CRC校验码
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0

    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end

    return crc
end

-- 将json字符串转换为LUA中的table
local function decodeJsonToTable(cmd)
    local tb

    if JSON == nil then JSON = require "cjson" end

    tb = JSON.decode(cmd)

    return tb
end

-- 将LUA中的table转换为json字符串
local function encodeTableToJson(luaTable)
    local jsonStr

    if JSON == nil then JSON = require "cjson" end

    jsonStr = JSON.encode(luaTable)

    return jsonStr
end

-- 将十六进制string字符串转成LUA中的table
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

-- 将table转成字符串
local function table2string(cmd)
    local ret = ""
    local i

    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end

    return ret
end

-- 将字符串转成十六进制字符串输出
local function string2hexstring(str)
    local ret = ""

    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end

    return ret
end

-- 检查data的值是否超过边界
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

-- 将String转int
local function string2Int(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end

-- 将int转String
local function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = "0" end
    return data
end

-- 打印table表
local function print_lua_table(lua_table, indent)
    indent = indent or 0

    for k, v in pairs(lua_table) do
        if type(k) == "string" then k = string.format("%q", k) end

        local szSuffix = ""

        if type(v) == "table" then szSuffix = "{" end

        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix .. "[" .. k .. "]" .. " = " .. szSuffix

        if type(v) == "table" then
            io_msg(formatting)

            print_lua_table(v, indent + 1)

            io_msg(szPrefix .. "},")
        else
            local szValue = ""

            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end

            io_msg(formatting .. szValue .. ",")
        end
    end
end

-- 根据电控协议不同，需要改变的函数

-- nixj8 add
local key_maps = {
    -- 消息体子命令类型0x01 ：基本控制/查询 回复 /基本上报 命令
    {
        idx = 0,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_power_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 1,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_power_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 2,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_power_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 3,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "run_mode_set",
        value_map = {
            [1] = "off",
            [2] = "wind",
            [3] = "cool",
            [4] = "heat",
            [5] = "force_cool",
            [6] = "auto",
            [7] = "humi",
            [117] = "on",
            [118] = "dehumi",
            [256] = "invalid"
        },
        writable = true
    }, {
        idx = 4,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_temp_set",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 5,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_temp_set",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 6,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "room_temp_set",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 7,
        from = "controller",
        changed = 0,
        value = {50},
        size = 1,
        path = "dhw_temp_set",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 8,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_curve_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 9,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_curve_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 10,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "forcetbh_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 11,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fastdhw_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 12,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "remote_onoff",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 13,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "silence_set_state",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 14,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "heat_enable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 15,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "cool_enable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 16,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_enable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 17,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "double_zone_enable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 18,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_temp_type",
        value_map = {
            [1] = "water_temperature_type",
            [2] = "room_temperature_type"
        }
    }, {
        idx = 19,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_temp_type",
        value_map = {
            [1] = "water_temperature_type",
            [2] = "room_temperature_type"
        }
    }, {
        idx = 20,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "room_thermalen_state",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 21,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "room_thermalmode_state",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 22,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "time_set_state",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 23,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "silence_on_state",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 24,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holiday_on_state",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 25,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "eco_on_state",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 26,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_terminal_type",
        value_map = {[1] = "fan_coil", [2] = "radiatior", [3] = "floor_heat"}
    }, {
        idx = 27,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_terminal_type",
        value_map = {[1] = "fan_coil", [2] = "radiatior", [3] = "floor_heat"}
    }, {
        idx = 28,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "runmode_under_auto",
        value_map = {
            [1] = "normal",
            [2] = "cool",
            [3] = "heat",
            [256] = "invalid"
        }
    }, {
        idx = 29,
        from = "controller",
        changed = 0,
        value = {65},
        size = 1,
        path = "zone1_heat_max_set_temp",
        value_type = "int8_t"
    }, {
        idx = 30,
        from = "controller",
        changed = 0,
        value = {35},
        size = 1,
        path = "zone1_heat_min_set_temp",
        value_type = "int8_t"
    }, {
        idx = 31,
        from = "controller",
        changed = 0,
        value = {65},
        size = 1,
        path = "zone1_cool_max_set_temp",
        value_type = "int8_t"
    }, {
        idx = 32,
        from = "controller",
        changed = 0,
        value = {35},
        size = 1,
        path = "zone1_cool_min_set_temp",
        value_type = "int8_t"
    }, {
        idx = 33,
        from = "controller",
        changed = 0,
        value = {65},
        size = 1,
        path = "zone2_heat_max_set_temp",
        value_type = "int8_t"
    }, {
        idx = 34,
        from = "controller",
        changed = 0,
        value = {35},
        size = 1,
        path = "zone2_heat_min_set_temp",
        value_type = "int8_t"
    }, {
        idx = 35,
        from = "controller",
        changed = 0,
        value = {65},
        size = 1,
        path = "zone2_cool_max_set_temp",
        value_type = "int8_t"
    }, {
        idx = 36,
        from = "controller",
        changed = 0,
        value = {35},
        size = 1,
        path = "zone2_cool_min_set_temp",
        value_type = "int8_t"
    }, {
        idx = 37,
        from = "controller",
        changed = 0,
        value = {60},
        size = 1,
        path = "room_max_set_temp",
        value_type = "uint8_t_double"
    }, {
        idx = 38,
        from = "controller",
        changed = 0,
        value = {34},
        size = 1,
        path = "room_min_set_temp",
        value_type = "uint8_t_double"
    }, {
        idx = 39,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_max_set_temp",
        value_type = "int8_t"
    }, {
        idx = 40,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_min_set_temp",
        value_type = "int8_t"
    }, {
        idx = 41,
        from = "idu",
        changed = 0,
        value = {25},
        size = 1,
        path = "tank_actual_temp",
        value_type = "temp"
    }, {
        idx = 42,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "error_code",
        value_type = "uint8_t"
    }, {
        idx = 43,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "protocol_newfunction_en",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 44,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "boostertbh_en",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 45,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_curve_type",
        value_type = "curve_type",
        writable = true
    }, {
        idx = 46,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_curve_type",
        value_type = "curve_type",
        writable = true
    }, {
        idx = 47,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "SysEnergyAnaEN",
        value_map = {[1] = 'off', [2] = "on"}
    }, {
        idx = 48,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "HMIEnergyAnaSetEN",
        value_map = {[1] = 'off', [2] = "on"}
    }, {
        idx = 49,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4",
        value_type = "temp"
    }, {
        idx = 50,
        from = "controller",
        changed = 0,
        value = {1},
        size = 12,
        path = "error_code_str",
        value_type = "chars"
    }, {
        idx = 51,
        from = "controller",
        changed = 0,
        value = {1},
        size = 5,
        path = "error_new_code",
        value_type = "chars"
    }, {
        idx = 52,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "config_code",
        value_type = "uint32_t"
    }, {
        idx = 53,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_cool_curve_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 54,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_heat_curve_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 55,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_cool_curve_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 56,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_heat_curve_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 57,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holiday_on_type",
        value_type = "uint8_t"
    }, {
        idx = 58,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "year",
        value_type = "uint8_t"
    }, {
        idx = 59,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "month",
        value_type = "uint8_t"
    }, {
        idx = 60,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "day",
        value_type = "uint8_t"
    }, {
        idx = 61,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hour",
        value_type = "uint8_t"
    }, {
        idx = 62,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "minute",
        value_type = "uint8_t"
    }, {
        idx = 63,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "backupSensorRemainTime",
        value_type = "uint16_t"
    }, {
        idx = 64,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "backupSensorState",
        value_type = "uint8_t"
    }, {
        idx = 65,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "backupSensorOverAccuracy",
        value_type = "uint8_t"
    }, {
        idx = 66,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved66",
        value_type = "uint8_t"
    }, {
        idx = 67,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved67",
        value_type = "uint8_t"
    }, {
        idx = 68,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved68",
        value_type = "uint8_t"
    }, {
        idx = 69,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved69",
        value_type = "uint8_t"
    }, -- 消息命令类型0x02 ：日定时控制/查询 回复命令
    -- 区域1日定时控制/查询 回复命令
    {
        idx = 70,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "daytimer_timer1en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 71,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "daytimer_timer1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 72,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "daytimer_timer1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 73,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "daytimer_timer1_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 74,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "daytimer_timer1_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 75,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "daytimer_timer2en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 76,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "daytimer_timer2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 77,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "daytimer_timer2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 78,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "daytimer_timer2_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 79,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "daytimer_timer2_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 80,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "daytimer_timer3en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 81,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "daytimer_timer3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 82,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "daytimer_timer3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 83,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "daytimer_timer3_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 84,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "daytimer_timer3_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 85,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "daytimer_timer4en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 86,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "daytimer_timer4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 87,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "daytimer_timer4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 88,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "daytimer_timer4_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 89,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "daytimer_timer4_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 90,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "daytimer_timer5en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 91,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "daytimer_timer5_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 92,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "daytimer_timer5_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 93,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "daytimer_timer5_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 94,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "daytimer_timer5_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 95,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "daytimer_timer6en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 96,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "daytimer_timer6_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 97,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "daytimer_timer6_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 98,
        from = "controller",
        changed = 0,
        value = {6},
        size = 1,
        path = "daytimer_timer6_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 99,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "daytimer_timer6_openmin",
        value_type = "min_10s",
        writable = true
    }, -- 区域2日定时控制/查询 回复命令
    {
        idx = 100,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2daytimer_timer1en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 101,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2daytimer_timer1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 102,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2daytimer_timer1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 103,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2daytimer_timer1_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 104,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2daytimer_timer1_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 105,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2daytimer_timer2en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 106,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2daytimer_timer2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 107,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2daytimer_timer2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 108,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone2daytimer_timer2_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 109,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2daytimer_timer2_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 110,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2daytimer_timer3en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 111,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2daytimer_timer3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 112,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2daytimer_timer3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 113,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone2daytimer_timer3_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 114,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2daytimer_timer3_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 115,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2daytimer_timer4en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 116,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2daytimer_timer4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 117,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2daytimer_timer4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 118,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2daytimer_timer4_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 119,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2daytimer_timer4_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 120,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2daytimer_timer5en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 121,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2daytimer_timer5_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 122,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2daytimer_timer5_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 123,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "zone2daytimer_timer5_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 124,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2daytimer_timer5_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 125,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2daytimer_timer6en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 126,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2daytimer_timer6_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 127,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2daytimer_timer6_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 128,
        from = "controller",
        changed = 0,
        value = {6},
        size = 1,
        path = "zone2daytimer_timer6_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 129,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2daytimer_timer6_openmin",
        value_type = "min_10s",
        writable = true
    }, -- DHW日定时控制/查询 回复命令
    {
        idx = 130,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer1en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 131,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer1_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 132,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwdaytimer_timer1_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 133,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer1_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 134,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwdaytimer_timer1_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 135,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer2en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 136,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer2_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 137,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwdaytimer_timer2_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 138,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "dhwdaytimer_timer2_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 139,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwdaytimer_timer2_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 140,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer3en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 141,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer3_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 142,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwdaytimer_timer3_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 143,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "dhwdaytimer_timer3_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 144,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwdaytimer_timer3_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 145,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer4en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 146,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer4_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 147,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwdaytimer_timer4_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 148,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "dhwdaytimer_timer4_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 149,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwdaytimer_timer4_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 150,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer5en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 151,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer5_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 152,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwdaytimer_timer5_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 153,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "dhwdaytimer_timer5_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 154,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwdaytimer_timer5_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 155,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer6en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 156,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwdaytimer_timer6_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 157,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwdaytimer_timer6_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 158,
        from = "controller",
        changed = 0,
        value = {6},
        size = 1,
        path = "dhwdaytimer_timer6_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 159,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwdaytimer_timer6_openmin",
        value_type = "min_10s",
        writable = true
    }, -- 消息命令类型0x83: 周定时查询
    {
        idx = 160,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_status",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 161,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "dhw_weeklytimer_schedule_num",
        value_type = "uint8_t"
    }, {
        idx = 162,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 163,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 164,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 165,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 166,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_status",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 167,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_num",
        value_type = "uint8_t"
    }, {
        idx = 168,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 169,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 170,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 171,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 172,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_status",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 173,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_num",
        value_type = "uint8_t"
    }, {
        idx = 174,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 175,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 176,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 177,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_status",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 178,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved178",
        value_type = "int8_t"
    }, {
        idx = 179,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved179",
        value_type = "int8_t"
    }, {
        idx = 180,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved180",
        value_type = "int8_t"
    }, {
        idx = 181,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved181",
        value_type = "int8_t"
    }, {
        idx = 182,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved182",
        value_type = "int8_t"
    }, {
        idx = 183,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved183",
        value_type = "int8_t"
    }, {
        idx = 184,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved184",
        value_type = "int8_t"
    }, {
        idx = 185,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved185",
        value_type = "int8_t"
    }, {
        idx = 186,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved186",
        value_type = "int8_t"
    }, {
        idx = 187,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved187",
        value_type = "int8_t"
    }, {
        idx = 188,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved188",
        value_type = "int8_t"
    }, {
        idx = 189,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved189",
        value_type = "int8_t"
    }, -- 消息体子命令类型 0x8301~0x8304
    -- dhw日程1
    {
        idx = 190,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 191,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 192,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_1_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 193,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_1_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 194,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 195,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 196,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 197,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_2_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 198,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_2_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 199,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 200,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 201,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 202,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_3_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 203,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_3_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 204,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 205,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 206,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 207,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_4_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 208,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_4_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 209,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 210,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_1_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 211,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved211",
        value_type = "int8_t"
    }, {
        idx = 212,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved212",
        value_type = "int8_t"
    }, {
        idx = 213,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved213",
        value_type = "int8_t"
    }, {
        idx = 214,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved214",
        value_type = "int8_t"
    }, {
        idx = 215,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved215",
        value_type = "int8_t"
    }, {
        idx = 216,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved216",
        value_type = "int8_t"
    }, {
        idx = 217,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved217",
        value_type = "int8_t"
    }, {
        idx = 218,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved218",
        value_type = "int8_t"
    }, {
        idx = 219,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved219",
        value_type = "int8_t"
    }, -- dhw日程2
    {
        idx = 220,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 221,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 222,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_1_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 223,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_1_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 224,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 225,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 226,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 227,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_2_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 228,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_2_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 229,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 230,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 231,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 232,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_3_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 233,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_3_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 234,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 235,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 236,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 237,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_4_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 238,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_4_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 239,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 240,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_2_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 241,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved241",
        value_type = "int8_t"
    }, {
        idx = 242,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved242",
        value_type = "int8_t"
    }, {
        idx = 243,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved243",
        value_type = "int8_t"
    }, {
        idx = 244,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved244",
        value_type = "int8_t"
    }, {
        idx = 245,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved245",
        value_type = "int8_t"
    }, {
        idx = 246,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved246",
        value_type = "int8_t"
    }, {
        idx = 247,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved247",
        value_type = "int8_t"
    }, {
        idx = 248,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved248",
        value_type = "int8_t"
    }, {
        idx = 249,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved249",
        value_type = "int8_t"
    }, -- dhw日程3
    {
        idx = 250,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 251,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 252,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_1_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 253,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_1_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 254,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 255,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 256,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 257,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_2_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 258,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_2_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 259,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 260,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 261,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 262,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_3_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 263,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_3_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 264,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 265,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 266,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 267,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_4_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 268,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_4_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 269,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 270,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_3_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 271,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved271",
        value_type = "int8_t"
    }, {
        idx = 272,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved272",
        value_type = "int8_t"
    }, {
        idx = 273,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved273",
        value_type = "int8_t"
    }, {
        idx = 274,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved274",
        value_type = "int8_t"
    }, {
        idx = 275,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved275",
        value_type = "int8_t"
    }, {
        idx = 276,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved276",
        value_type = "int8_t"
    }, {
        idx = 277,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved277",
        value_type = "int8_t"
    }, {
        idx = 278,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved278",
        value_type = "int8_t"
    }, {
        idx = 279,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved279",
        value_type = "int8_t"
    }, -- dhw日程4
    {
        idx = 280,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 281,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 282,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_1_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 283,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_1_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 284,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 285,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 286,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 287,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_2_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 288,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_2_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 289,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 290,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 291,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 292,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_3_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 293,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_3_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 294,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 295,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 296,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 297,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_4_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 298,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_4_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 299,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 300,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhw_weeklytimer_schedule_4_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 301,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved301",
        value_type = "int8_t"
    }, {
        idx = 302,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved302",
        value_type = "int8_t"
    }, {
        idx = 303,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved303",
        value_type = "int8_t"
    }, {
        idx = 304,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved304",
        value_type = "int8_t"
    }, {
        idx = 305,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved305",
        value_type = "int8_t"
    }, {
        idx = 306,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved306",
        value_type = "int8_t"
    }, {
        idx = 307,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved307",
        value_type = "int8_t"
    }, {
        idx = 308,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved308",
        value_type = "int8_t"
    }, {
        idx = 309,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved309",
        value_type = "int8_t"
    }, -- 消息体子命令类型 0x8311~0x8314
    -- 区域1日程1
    {
        idx = 310,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 311,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 312,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 313,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 314,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 315,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 316,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 317,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 318,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 319,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 320,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 321,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 322,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 323,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 324,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 325,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 326,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 327,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 328,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 329,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 330,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_1_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 331,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved331",
        value_type = "int8_t"
    }, {
        idx = 332,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved332",
        value_type = "int8_t"
    }, {
        idx = 333,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved333",
        value_type = "int8_t"
    }, {
        idx = 334,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved334",
        value_type = "int8_t"
    }, {
        idx = 335,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved335",
        value_type = "int8_t"
    }, {
        idx = 336,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved336",
        value_type = "int8_t"
    }, {
        idx = 337,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved337",
        value_type = "int8_t"
    }, {
        idx = 338,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved338",
        value_type = "int8_t"
    }, {
        idx = 339,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved339",
        value_type = "int8_t"
    }, -- 区域1日程2
    {
        idx = 340,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 341,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 342,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 343,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 344,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 345,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 346,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 347,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 348,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 349,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 350,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 351,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 352,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 353,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 354,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 355,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 356,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 357,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 358,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 359,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 360,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_2_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 361,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved361",
        value_type = "int8_t"
    }, {
        idx = 362,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved362",
        value_type = "int8_t"
    }, {
        idx = 363,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved363",
        value_type = "int8_t"
    }, {
        idx = 364,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved364",
        value_type = "int8_t"
    }, {
        idx = 365,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved365",
        value_type = "int8_t"
    }, {
        idx = 366,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved366",
        value_type = "int8_t"
    }, {
        idx = 367,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved367",
        value_type = "int8_t"
    }, {
        idx = 368,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved368",
        value_type = "int8_t"
    }, {
        idx = 369,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved369",
        value_type = "int8_t"
    }, -- 区域1日程3
    {
        idx = 370,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 371,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 372,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 373,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 374,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_1_starthour",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 375,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_1_startmin",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 376,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 377,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 378,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 379,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_2_starthour",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 380,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_2_startmin",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 381,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 382,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 383,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 384,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_3_starthour",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 385,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_3_startmin",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 386,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 387,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 388,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 389,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_4_starthour",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 390,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_3_timer_4_startmin",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 391,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved391",
        value_type = "int8_t"
    }, {
        idx = 392,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved392",
        value_type = "int8_t"
    }, {
        idx = 393,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved393",
        value_type = "int8_t"
    }, {
        idx = 394,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved394",
        value_type = "int8_t"
    }, {
        idx = 395,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved395",
        value_type = "int8_t"
    }, {
        idx = 396,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved396",
        value_type = "int8_t"
    }, {
        idx = 397,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved397",
        value_type = "int8_t"
    }, {
        idx = 398,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved398",
        value_type = "int8_t"
    }, {
        idx = 399,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved399",
        value_type = "int8_t"
    }, -- 区域1日程4
    {
        idx = 400,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 401,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 402,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 403,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 404,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 405,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 406,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 407,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 408,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 409,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 410,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 411,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 412,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 413,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 414,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 415,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 416,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 417,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 418,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 419,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 420,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone1_weeklytimer_schedule_4_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 421,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved421",
        value_type = "int8_t"
    }, {
        idx = 422,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved422",
        value_type = "int8_t"
    }, {
        idx = 423,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved423",
        value_type = "int8_t"
    }, {
        idx = 424,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved424",
        value_type = "int8_t"
    }, {
        idx = 425,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved425",
        value_type = "int8_t"
    }, {
        idx = 426,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved426",
        value_type = "int8_t"
    }, {
        idx = 427,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved427",
        value_type = "int8_t"
    }, {
        idx = 428,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved428",
        value_type = "int8_t"
    }, {
        idx = 429,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved429",
        value_type = "int8_t"
    }, -- 消息体子命令类型 0x8321~0x8324
    -- 区域2日程1
    {
        idx = 430,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 431,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 432,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 433,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 434,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 435,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 436,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 437,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 438,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 439,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 440,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 441,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 442,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 443,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 444,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 445,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 446,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 447,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 448,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 449,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 450,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_1_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 451,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved451",
        value_type = "int8_t"
    }, {
        idx = 452,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved452",
        value_type = "int8_t"
    }, {
        idx = 453,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved453",
        value_type = "int8_t"
    }, {
        idx = 454,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved454",
        value_type = "int8_t"
    }, {
        idx = 455,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved455",
        value_type = "int8_t"
    }, {
        idx = 456,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved456",
        value_type = "int8_t"
    }, {
        idx = 457,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved457",
        value_type = "int8_t"
    }, {
        idx = 458,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved458",
        value_type = "int8_t"
    }, {
        idx = 459,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved459",
        value_type = "int8_t"
    }, -- 区域2日程2
    {
        idx = 460,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 461,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 462,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 463,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 464,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 465,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 466,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 467,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 468,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 469,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 470,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 471,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 472,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 473,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 474,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 475,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 476,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 477,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 478,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 479,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 480,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_2_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 481,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved481",
        value_type = "int8_t"
    }, {
        idx = 482,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved482",
        value_type = "int8_t"
    }, {
        idx = 483,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved483",
        value_type = "int8_t"
    }, {
        idx = 484,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved484",
        value_type = "int8_t"
    }, {
        idx = 485,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved485",
        value_type = "int8_t"
    }, {
        idx = 486,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved486",
        value_type = "int8_t"
    }, {
        idx = 487,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved487",
        value_type = "int8_t"
    }, {
        idx = 488,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved488",
        value_type = "int8_t"
    }, {
        idx = 489,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved489",
        value_type = "int8_t"
    }, -- 区域2日程3
    {
        idx = 490,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 491,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 492,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 493,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 494,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 495,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 496,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 497,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 498,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 499,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 500,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 501,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 502,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 503,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 504,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 505,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 506,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 507,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 508,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 509,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 510,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_3_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 511,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved511",
        value_type = "int8_t"
    }, {
        idx = 512,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved512",
        value_type = "int8_t"
    }, {
        idx = 513,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved513",
        value_type = "int8_t"
    }, {
        idx = 514,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved514",
        value_type = "int8_t"
    }, {
        idx = 515,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved515",
        value_type = "int8_t"
    }, {
        idx = 516,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved516",
        value_type = "int8_t"
    }, {
        idx = 517,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved517",
        value_type = "int8_t"
    }, {
        idx = 518,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved518",
        value_type = "int8_t"
    }, {
        idx = 519,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved519",
        value_type = "int8_t"
    }, -- 区域2日程4
    {
        idx = 520,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_weekday",
        value_type = "week",
        writable = true
    }, {
        idx = 521,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_1_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 522,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 523,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 524,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 525,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 526,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_2_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 527,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 528,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 529,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 530,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 531,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_3_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 532,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 533,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 534,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_3_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 535,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_3_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 536,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_4_en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 537,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 538,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 539,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_4_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 540,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2_weeklytimer_schedule_4_timer_4_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 541,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved541",
        value_type = "int8_t"
    }, {
        idx = 542,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved542",
        value_type = "int8_t"
    }, {
        idx = 543,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved543",
        value_type = "int8_t"
    }, {
        idx = 544,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved544",
        value_type = "int8_t"
    }, {
        idx = 545,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved545",
        value_type = "int8_t"
    }, {
        idx = 546,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved546",
        value_type = "int8_t"
    }, {
        idx = 547,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved547",
        value_type = "int8_t"
    }, {
        idx = 548,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved548",
        value_type = "int8_t"
    }, {
        idx = 549,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved549",
        value_type = "int8_t"
    },

    -- 消息体子命令类型0x04 ：外出休假控制/查询 回复命令
    {
        idx = 550,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 551,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_heat_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 552,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_dhw_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 553,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_disinfect_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 554,
        from = "controller",
        changed = 0,
        value = {99},
        size = 1,
        path = "holidayaway_startyear",
        value_type = "year",
        writable = true
    }, {
        idx = 555,
        from = "controller",
        changed = 0,
        value = {12},
        size = 1,
        path = "holidayaway_startmonth",
        value_type = "month",
        writable = true
    }, {
        idx = 556,
        from = "controller",
        changed = 0,
        value = {31},
        size = 1,
        path = "holidayaway_startdate",
        value_type = "date",
        writable = true
    }, {
        idx = 557,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_endyear",
        value_type = "year",
        writable = true
    }, {
        idx = 558,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_endmonth",
        value_type = "month",
        writable = true
    }, {
        idx = 559,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_enddate",
        value_type = "date",
        writable = true
    }, {
        idx = 560,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_heat_temp",
        value_type = "uint8_t",
        writable = true,
        min = 20,
        max = 25
    }, {
        idx = 561,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayaway_dhw_temp",
        value_type = "uint8_t",
        writable = true,
        min = 20,
        max = 25
    }, {
        idx = 562,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved562",
        value_type = "uint8_t"
    }, {
        idx = 563,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved563",
        value_type = "uint8_t"
    }, {
        idx = 564,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved564",
        value_type = "uint8_t"
    }, {
        idx = 565,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved565",
        value_type = "uint8_t"
    }, {
        idx = 566,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved566",
        value_type = "uint8_t"
    }, {
        idx = 567,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved567",
        value_type = "uint8_t"
    }, {
        idx = 568,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved568",
        value_type = "uint8_t"
    }, {
        idx = 569,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved569",
        value_type = "uint8_t"
    }, -- 消息体子命令类型0x05 ：静音控制/查询 回复命令
    {
        idx = 570,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "silence_function_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 571,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "silence_function_level",
        value_map = {[1] = "level_1", [2] = "level_2", [3] = "level_3"},
        writable = true
    }, {
        idx = 572,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "silence_timer1_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 573,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "silence_timer1_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 574,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "silence_timer1_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 575,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "silence_timer1_endhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 576,
        from = "controller",
        changed = 0,
        value = {59},
        size = 1,
        path = "silence_timer1_endmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 577,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "silence_timer2_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 578,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "silence_timer2_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 579,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "silence_timer2_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 580,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "silence_timer2_endhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 581,
        from = "controller",
        changed = 0,
        value = {59},
        size = 1,
        path = "silence_timer2_endmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 582,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved582",
        value_type = "uint8_t"
    }, {
        idx = 583,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved583",
        value_type = "uint8_t"
    }, {
        idx = 584,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved584",
        value_type = "uint8_t"
    }, {
        idx = 585,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved585",
        value_type = "uint8_t"
    }, {
        idx = 586,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved586",
        value_type = "uint8_t"
    }, {
        idx = 587,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved587",
        value_type = "uint8_t"
    }, {
        idx = 588,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved588",
        value_type = "uint8_t"
    }, {
        idx = 589,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved589",
        value_type = "uint8_t"
    },

    -- 消息体子命令类型0x06 ：在家休假控制/查询 回复命令
    {
        idx = 590,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayhome_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 591,
        from = "controller",
        changed = 0,
        value = {22},
        size = 1,
        path = "holidayhome_startyear",
        value_type = "year",
        writable = true
    }, {
        idx = 592,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayhome_startmonth",
        value_type = "month",
        writable = true
    }, {
        idx = 593,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayhome_startdate",
        value_type = "date",
        writable = true
    }, {
        idx = 594,
        from = "controller",
        changed = 0,
        value = {23},
        size = 1,
        path = "holidayhome_endyear",
        value_type = "year",
        writable = true
    }, {
        idx = 595,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayhome_endmonth",
        value_type = "month",
        writable = true
    }, {
        idx = 596,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holidayhome_enddate",
        value_type = "date",
        writable = true
    }, {
        idx = 597,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved597",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 598,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved598",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 599,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved599",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 600,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holhometimer_timer1en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 601,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holhometimer_timer2en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 602,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holhometimer_timer3en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 603,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holhometimer_timer4en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 604,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holhometimer_timer5en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 605,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holhometimer_timer6en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 606,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "holhometimer_timer1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 607,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "holhometimer_timer1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 608,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "holhometimer_timer1_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 609,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "holhometimer_timer1_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 610,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "holhometimer_timer2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 611,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "holhometimer_timer2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 612,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "holhometimer_timer2_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 613,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "holhometimer_timer2_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 614,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "holhometimer_timer3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 615,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "holhometimer_timer3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 616,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "holhometimer_timer3_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 617,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "holhometimer_timer3_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 618,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "holhometimer_timer4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 619,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "holhometimer_timer4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 620,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "holhometimer_timer4_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 621,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "holhometimer_timer4_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 622,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "holhometimer_timer5_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 623,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "holhometimer_timer5_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 624,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "holhometimer_timer5_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 625,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "holhometimer_timer5_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 626,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "holhometimer_timer6_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 627,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "holhometimer_timer6_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 628,
        from = "controller",
        changed = 0,
        value = {6},
        size = 1,
        path = "holhometimer_timer6_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 629,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "holhometimer_timer6_openmin",
        value_type = "min_10s",
        writable = true
    }, -- 在家休假区域2定时信息
    {
        idx = 630,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2holhometimer_timer1en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 631,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2holhometimer_timer2en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 632,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2holhometimer_timer3en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 633,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2holhometimer_timer4en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 634,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2holhometimer_timer5en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 635,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2holhometimer_timer6en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 636,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2holhometimer_timer1_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 637,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2holhometimer_timer1_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 638,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2holhometimer_timer1_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 639,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2holhometimer_timer1_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 640,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2holhometimer_timer2_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 641,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2holhometimer_timer2_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 642,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "zone2holhometimer_timer2_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 643,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2holhometimer_timer2_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 644,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2holhometimer_timer3_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 645,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2holhometimer_timer3_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 646,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "zone2holhometimer_timer3_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 647,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2holhometimer_timer3_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 648,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2holhometimer_timer4_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 649,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2holhometimer_timer4_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 650,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2holhometimer_timer4_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 651,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2holhometimer_timer4_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 652,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2holhometimer_timer5_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 653,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2holhometimer_timer5_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 654,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "zone2holhometimer_timer5_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 655,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2holhometimer_timer5_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 656,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "zone2holhometimer_timer6_mode",
        value_map = {[1] = "off", [3] = "cool", [4] = "heat"},
        writable = true
    }, {
        idx = 657,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "zone2holhometimer_timer6_temp",
        value_type = "uint8_t_double",
        writable = true
    }, {
        idx = 658,
        from = "controller",
        changed = 0,
        value = {6},
        size = 1,
        path = "zone2holhometimer_timer6_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 659,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "zone2holhometimer_timer6_openmin",
        value_type = "min_10s",
        writable = true
    }, -- dhw休假区域2定时信息
    {
        idx = 660,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer1en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 661,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer2en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 662,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer3en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 663,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer4en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 664,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer5en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 665,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer6en",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 666,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer1_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 667,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwholhometimer_timer1_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 668,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer1_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 669,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwholhometimer_timer1_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 670,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer2_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 671,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwholhometimer_timer2_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 672,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "dhwholhometimer_timer2_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 673,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwholhometimer_timer2_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 674,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer3_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 675,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwholhometimer_timer3_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 676,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "dhwholhometimer_timer3_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 677,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwholhometimer_timer3_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 678,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer4_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 679,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwholhometimer_timer4_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 680,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "dhwholhometimer_timer4_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 681,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwholhometimer_timer4_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 682,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer5_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 683,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwholhometimer_timer5_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 684,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "dhwholhometimer_timer5_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 685,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwholhometimer_timer5_openmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 686,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwholhometimer_timer6_mode",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 687,
        from = "controller",
        changed = 0,
        value = {25},
        size = 1,
        path = "dhwholhometimer_timer6_temp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 688,
        from = "controller",
        changed = 0,
        value = {6},
        size = 1,
        path = "dhwholhometimer_timer6_openhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 689,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "dhwholhometimer_timer6_openmin",
        value_type = "min_10s",
        writable = true
    }, -- 消息命令类型0xFE ：测试控制/查询 回复命令
    {
        idx = 690,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "cmd_flag",
        value_type = "uint16_t"
    }, {
        idx = 691,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "timer_callback",
        value_type = "uint16_t"
    }, {
        idx = 692,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "send_ready_count",
        value_type = "uint32_t"
    }, {
        idx = 693,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "wait_response_count",
        value_type = "uint32_t"
    }, {
        idx = 694,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "send_ok_count",
        value_type = "uint32_t"
    }, {
        idx = 695,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved695",
        value_type = "uint8_t"
    }, {
        idx = 696,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved696",
        value_type = "uint8_t"
    }, {
        idx = 697,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved697",
        value_type = "uint8_t"
    }, {
        idx = 698,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved698",
        value_type = "uint8_t"
    }, {
        idx = 699,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved699",
        value_type = "uint8_t"
    }, -- 消息命令类型0x07 ：ECO控制/查询 回复命令
    {
        idx = 700,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "eco_function_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 701,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "eco_timer_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 702,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "eco_timer_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 703,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "eco_timer_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 704,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "eco_timer_endhour",
        value_type = "hour",
        writable = true
    }, {
        idx = 705,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "eco_timer_endmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 706,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "eco_curve_type",
        value_type = "eco_curve_type",
        writable = true
    }, {
        idx = 707,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved707",
        value_type = "uint8_t"
    }, {
        idx = 708,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved708",
        value_type = "uint8_t"
    }, {
        idx = 709,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved709",
        value_type = "uint8_t"
    }, -- 消命令类型0x08 ：安装设定参数 控制/查询 回复命令
    {
        idx = 710,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwEnable",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 711,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "boostertbhEn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 712,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "disinfectEnable",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 713,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwPumpEnable",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 714,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwPriorityTime",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 715,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwPumpDIEnable",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 716,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "coolEnable",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 717,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgZone1CoolTempHigh",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 718,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "heatEnable",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 719,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgZone1HeatTempHigh",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 720,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "pumpiSliModeEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 721,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "roomSensorEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 722,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "roomTherEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 723,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "roomTherSetModeEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 724,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dualroomThermostatEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 725,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgdhwPriorEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 726,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "acsEnable ",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 727,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dhwHeaterAhsEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 728,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempPcbEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 729,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tbt2ProbeEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 730,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "pipeExceed10m",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 731,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "solarCn18En",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 732,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgOwnSolarEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 733,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgInputDhwHeater",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 734,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "smartgridEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 735,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1bProbeEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 736,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgZone2CoolTempHigh",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 737,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgZone2HeatTempHigh",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 738,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "doubleZoneEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 739,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgTaProbeIdu",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 740,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tbt1ProbeEn",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 741,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgIbhInTank",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 742,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dT5On",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 743,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dT1S5",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 744,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tIntervaDhw",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 745,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4Dhwmax",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 746,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4Dhwmin",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 747,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tTBHdelay",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 748,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dT5STBHoff",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 749,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4TBHon",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 750,
        from = "controller",
        changed = 0,
        value = {0xff},
        size = 1,
        path = "t5sDI",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 751,
        from = "controller",
        changed = 0,
        value = {0xff},
        size = 2,
        path = "tDImax",
        value_type = "uint16_t",
        writable = true
    }, {
        idx = 752,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tDIhightemp",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 753,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tIntervalC",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 754,
        from = "controller",
        changed = 0,
        value = {8},
        size = 1,
        path = "dT1SC",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 755,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dTSC",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 756,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4Cmax",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 757,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4Cmin",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 758,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tIntervalH",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 759,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dT1SH",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 760,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dTSH",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 761,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4Hmax",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 762,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4Hmin",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 763,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4IBHon",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 764,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dT1IBHon",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 765,
        from = "controller",
        changed = 0,
        value = {8},
        size = 1,
        path = "tIBHdelay",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 766,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tIBH12delay",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 767,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4AHSon",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 768,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dT1AHSon",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 769,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dT1AHSoff",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 770,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tAHSdelay",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 771,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "tDHWHPmax",
        value_type = "uint16_t",
        writable = true
    }, {
        idx = 772,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "tDHWHPrestrict",
        value_type = "uint16_t",
        writable = true
    }, {
        idx = 773,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4autocmin",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 774,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4autohmax",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 775,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1sHolHeat",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 776,
        from = "controller",
        changed = 0,
        value = {8},
        size = 1,
        path = "t5SHolDhw",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 777,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "perStart",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 778,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "timeAdjust",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 779,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dTbt2",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 780,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "powerIbh1",
        value_type = "power_10",
        writable = true
    }, {
        idx = 781,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "powerIbh2",
        value_type = "power_10",
        writable = true
    }, {
        idx = 782,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "powerTbh",
        value_type = "power_10",
        writable = true
    }, {
        idx = 783,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "ecoHeatT1s",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 784,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "ecoHeatTs",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 785,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tDryup",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 786,
        from = "controller",
        changed = 0,
        value = {8},
        size = 1,
        path = "tDrypeak",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 787,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tdrydown",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 788,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempDrypeak",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 789,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "timePreheatFloor",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 790,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1SPreheatFloor",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 791,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1SetC1",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 792,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1SetC2",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 793,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4C1",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 794,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4C2",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 795,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1SetH1",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 796,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1SetH2",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 797,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4H1",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 798,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4H2",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 799,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "typeVolLmt",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 800,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "timeT4FreshC",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 801,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "timeT4FreshH",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 802,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tPumpiDelay",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 803,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "deltaTsloar",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 804,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "solarFunction",
        value_map = {[1] = "0", [2] = "1", [3] = "2"},
        writable = true
    }, {
        idx = 805,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "enSwitchPDC",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 806,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "gasCost",
        value_type = "uint16_t_100",
        writable = true
    }, {
        idx = 807,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "eleCost",
        value_type = "uint16_t_100",
        writable = true
    }, {
        idx = 808,
        from = "controller",
        changed = 0,
        value = {8},
        size = 1,
        path = "ahsSetTempMax",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 809,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "ahsSetTempMin",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 810,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "ahsSetTempMaxVolt",
        value_type = "uint16_t",
        writable = true
    }, {
        idx = 811,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "ahsSetTempMinVolt",
        value_type = "uint16_t",
        writable = true
    }, {
        idx = 812,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t2AntiSVRun",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 813,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "dftPortFuncEn",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 814,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1AntiPump",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 815,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "t2AntiPumpRun",
        value_type = "uint16_t",
        writable = true
    }, {
        idx = 816,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1AntiLockSV",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 817,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tbhEnFunc",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 818,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "ibhEnFunc",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 819,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "ahsEnFunc",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 820,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "ahsPumpiControl",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 821,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "modeSetPri",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 822,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "pumpType",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 823,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "pumpiSilentOutput",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 824,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "timeReportSet",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 825,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "backupSensorVaild",
        value_type = "uint8_t"
    }, {
        idx = 826,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "backupSensorEnabe",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 827,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "backupSensorTime",
        value_type = "uint16_t",
        writable = true
    }, {
        idx = 828,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "energyCorrection",
        value_type = "int16_t",
        writable = true
    }, {
        idx = 829,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "c2FaultResotre",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 830,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "flashSNCode",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 831,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "syncInstallParams",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 832,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2T1SetC1",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 833,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2T1SetC2",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 834,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2T4C1",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 835,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2T4C2",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 836,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2T1SetH1",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 837,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2T1SetH2",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 838,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2T4H1",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 839,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2T4H2",
        value_type = "int8_t",
        writable = true
    }, {
        idx = 840,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1CEmission",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 841,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1HEmission",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 842,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2CEmission",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 843,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2HEmission",
        value_type = "uint8_t",
        writable = true
    }, {
        idx = 844,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1SCLmin",
        value_type = "int8_t"
    }, {
        idx = 845,
        from = "controller",
        changed = 0,
        value = {1},
        size = 0,
        path = "reserved845",
        value_type = "uint8_t"
    }, {
        idx = 846,
        from = "controller",
        changed = 0,
        value = {1},
        size = 0,
        path = "reserved846",
        value_type = "uint8_t"
    }, {
        idx = 847,
        from = "controller",
        changed = 0,
        value = {1},
        size = 0,
        path = "reserved847",
        value_type = "uint8_t"
    }, {
        idx = 848,
        from = "controller",
        changed = 0,
        value = {1},
        size = 0,
        path = "reserved848",
        value_type = "uint8_t"
    }, {
        idx = 849,
        from = "controller",
        changed = 0,
        value = {1},
        size = 0,
        path = "reserved849",
        value_type = "uint8_t"
    }, -- 消息命令类型0x09 ：杀菌 控制/查询 回复命令
    {
        idx = 850,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "disinfect_function_state",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 851,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "disinfect_run_state",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 852,
        from = "controller",
        changed = 0,
        value = {63},
        size = 1,
        path = "disinfect_setweekday",
        value_type = "weekday",
        writable = true
    }, {
        idx = 853,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "disinfect_starthour",
        value_type = "hour",
        writable = true
    }, {
        idx = 854,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "disinfect_startmin",
        value_type = "min_10s",
        writable = true
    }, {
        idx = 855,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "disinfect_valid",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 856,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "disinfect_control",
        value_map = {[1] = "off", [2] = "on"},
        writable = true
    }, {
        idx = 857,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved857",
        value_type = "uint8_t"
    }, {
        idx = 858,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved858",
        value_type = "uint8_t"
    }, {
        idx = 859,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved859",
        value_type = "uint8_t"
    }, -- 主动上报子类型0x03/0x04 ：能量消耗上报
    {
        idx = 860,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "powercons_version",
        value_map = {[1] = "3", [2] = "4"}
    }, {
        idx = 861,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 862,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 863,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 864,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 865,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 866,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "issmartgrid0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 867,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "ishighprices0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 868,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isbottomprices0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 869,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "t4",
        value_type = "temp"
    }, {
        idx = 870,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "t5s",
        value_type = "uint8_t"
    }, {
        idx = 871,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "tas",
        value_type = "tas"
    }, {
        idx = 872,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "newt1s1",
        value_type = "uint8_t"
    }, {
        idx = 873,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "newt1s2",
        value_type = "uint8_t"
    }, {
        idx = 874,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "onlinenum",
        value_type = "uint8_t"
    }, {
        idx = 875,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone1_temp_set",
        value_type = "uint8_t"
    }, {
        idx = 876,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2_temp_set",
        value_type = "uint8_t"
    }, {
        idx = 877,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity0",
        value_type = "uint32_t_100"
    }, {
        idx = 878,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal0",
        value_type = "uint32_t_100"
    }, {
        idx = 879,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "power_ibh1",
        value_type = "power_10"
    }, {
        idx = 880,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "power_ibh2",
        value_type = "power_10"
    }, {
        idx = 881,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "power_tbh",
        value_type = "power_10"
    }, {
        idx = 882,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage0",
        value_type = "uint8_t"
    }, {
        idx = 883,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run0",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 884,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved884",
        value_type = "uint16_t"
    }, {
        idx = 885,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved885",
        value_type = "uint16_t"
    }, {
        idx = 886,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved886",
        value_type = "uint16_t"
    }, {
        idx = 887,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved887",
        value_type = "uint16_t"
    }, {
        idx = 888,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved888",
        value_type = "uint16_t"
    }, {
        idx = 889,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved889",
        value_type = "uint16_t"
    }, {
        idx = 890,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved890",
        value_type = "uint16_t"
    }, {
        idx = 891,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved891",
        value_type = "uint8_t"
    }, {
        idx = 892,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved892",
        value_type = "uint8_t"
    }, {
        idx = 893,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved893",
        value_type = "uint8_t"
    }, {
        idx = 894,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved894",
        value_type = "uint8_t"
    }, {
        idx = 895,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved895",
        value_type = "uint8_t"
    }, {
        idx = 896,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved896",
        value_type = "uint8_t"
    }, {
        idx = 897,
        from = "idu",
        changed = 0,
        value = {8},
        size = 1,
        path = "reserved897",
        value_type = "uint8_t"
    }, {
        idx = 898,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved898",
        value_type = "uint8_t"
    }, {
        idx = 899,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved899",
        value_type = "uint8_t"
    }, -- 并联从机i(1-15)状态信息 0x11
    {
        idx = 900,
        from = "idu",
        changed = 0,
        value = {100000000},
        size = 4,
        path = "totalelectricity1",
        value_type = "uint32_t"
    }, {
        idx = 901,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal1",
        value_type = "uint32_t"
    }, {
        idx = 902,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage1",
        value_type = "uint8_t"
    }, {
        idx = 903,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline1",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 904,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun1",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 905,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun1",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 906,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun1",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 907,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun1",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 908,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun1",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 909,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run1",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x12
    {
        idx = 910,
        from = "idu",
        changed = 0,
        value = {0x8fffffff},
        size = 4,
        path = "totalelectricity2",
        value_type = "uint32_t"
    }, {
        idx = 911,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal2",
        value_type = "uint32_t"
    }, {
        idx = 912,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage2",
        value_type = "uint8_t"
    }, {
        idx = 913,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline2",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 914,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun2",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 915,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun2",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 916,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun2",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 917,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun2",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 918,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun2",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 919,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run2",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x13
    {
        idx = 920,
        from = "idu",
        changed = 0,
        value = {0xffff},
        size = 4,
        path = "totalelectricity3",
        value_type = "uint32_t"
    }, {
        idx = 921,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal3",
        value_type = "uint32_t"
    }, {
        idx = 922,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage3",
        value_type = "uint8_t"
    }, {
        idx = 923,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline3",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 924,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun3",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 925,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun3",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 926,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun3",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 927,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun3",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 928,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun3",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 929,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run3",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x14
    {
        idx = 930,
        from = "idu",
        changed = 0,
        value = {65535},
        size = 4,
        path = "totalelectricity4",
        value_type = "uint32_t"
    }, {
        idx = 931,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal4",
        value_type = "uint32_t"
    }, {
        idx = 932,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage4",
        value_type = "uint8_t"
    }, {
        idx = 933,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline4",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 934,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun4",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 935,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun4",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 936,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun4",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 937,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun4",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 938,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun4",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 939,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run4",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x15
    {
        idx = 940,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity5",
        value_type = "uint32_t"
    }, {
        idx = 941,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal5",
        value_type = "uint32_t"
    }, {
        idx = 942,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage5",
        value_type = "uint8_t"
    }, {
        idx = 943,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline5",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 944,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun5",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 945,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun5",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 946,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun5",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 947,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun5",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 948,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun5",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 949,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run5",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x16
    {
        idx = 950,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity6",
        value_type = "uint32_t"
    }, {
        idx = 951,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal6",
        value_type = "uint32_t"
    }, {
        idx = 952,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage6",
        value_type = "uint8_t"
    }, {
        idx = 953,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline6",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 954,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun6",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 955,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun6",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 956,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun6",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 957,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun6",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 958,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun6",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 959,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run6",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x17
    {
        idx = 960,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity7",
        value_type = "uint32_t"
    }, {
        idx = 961,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal7",
        value_type = "uint32_t"
    }, {
        idx = 962,
        from = "idu",
        changed = 0,
        value = {8},
        size = 1,
        path = "voltage7",
        value_type = "uint8_t"
    }, {
        idx = 963,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline7",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 964,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun7",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 965,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun7",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 966,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun7",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 967,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun7",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 968,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun7",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 969,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run7",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x18
    {
        idx = 970,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity8",
        value_type = "uint32_t"
    }, {
        idx = 971,
        from = "idu",
        changed = 0,
        value = {8},
        size = 4,
        path = "totalthermal8",
        value_type = "uint32_t"
    }, {
        idx = 972,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage8",
        value_type = "uint8_t"
    }, {
        idx = 973,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline8",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 974,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun8",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 975,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun8",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 976,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun8",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 977,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun8",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 978,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun8",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 979,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run8",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x19
    {
        idx = 980,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity9",
        value_type = "uint32_t"
    }, {
        idx = 981,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal9",
        value_type = "uint32_t"
    }, {
        idx = 982,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage9",
        value_type = "uint8_t"
    }, {
        idx = 983,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline9",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 984,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun9",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 985,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun9",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 986,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun9",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 987,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun9",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 988,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun9",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 989,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run9",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x1A
    {
        idx = 990,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity10",
        value_type = "uint32_t"
    }, {
        idx = 991,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal10",
        value_type = "uint32_t"
    }, {
        idx = 992,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage10",
        value_type = "uint8_t"
    }, {
        idx = 993,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline10",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 994,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun10",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 995,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun10",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 996,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun10",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 997,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun10",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 998,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun10",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 999,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run10",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x1B
    {
        idx = 1000,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity11",
        value_type = "uint32_t"
    }, {
        idx = 1001,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal11",
        value_type = "uint32_t"
    }, {
        idx = 1002,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage11",
        value_type = "uint8_t"
    }, {
        idx = 1003,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline11",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1004,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun11",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1005,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun11",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1006,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun11",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1007,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun11",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1008,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun11",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1009,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run11",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x1C
    {
        idx = 1010,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity12",
        value_type = "uint32_t"
    }, {
        idx = 1011,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal12",
        value_type = "uint32_t"
    }, {
        idx = 1012,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage12",
        value_type = "uint8_t"
    }, {
        idx = 1013,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline12",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1014,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun12",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1015,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun12",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1016,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun12",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1017,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun12",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1018,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun12",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1019,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run12",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x1D
    {
        idx = 1020,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity13",
        value_type = "uint32_t"
    }, {
        idx = 1021,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal13",
        value_type = "uint32_t"
    }, {
        idx = 1022,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage13",
        value_type = "uint8_t"
    }, {
        idx = 1023,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline13",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1024,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun13",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1025,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun13",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1026,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun13",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1027,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun13",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1028,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun13",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1029,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run13",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x1E
    {
        idx = 1030,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity14",
        value_type = "uint32_t"
    }, {
        idx = 1031,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal14",
        value_type = "uint32_t"
    }, {
        idx = 1032,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "voltage14",
        value_type = "uint8_t"
    }, {
        idx = 1033,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline14",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1034,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun14",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1035,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun14",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1036,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun14",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1037,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun14",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1038,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun14",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1039,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run14",
        value_map = {[1] = "off", [2] = "on"}
    }, -- 并联从机i(1-15)状态信息 0x1F
    {
        idx = 1040,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity15",
        value_type = "uint32_t"
    }, {
        idx = 1041,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal15",
        value_type = "uint32_t"
    }, {
        idx = 1042,
        from = "idu",
        changed = 0,
        value = {8},
        size = 1,
        path = "voltage15",
        value_type = "uint8_t"
    }, {
        idx = 1043,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isonline15",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1044,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isheatrun15",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1045,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iscoolrun15",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1046,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isdhwrun15",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1047,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibhrun15",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1048,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "istbhrun15",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1049,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "isibh2run15",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1050,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1050",
        value_type = "uint8_t"
    }, {
        idx = 1051,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1051",
        value_type = "uint8_t"
    }, {
        idx = 1052,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1052",
        value_type = "uint8_t"
    }, {
        idx = 1053,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1053",
        value_type = "uint8_t"
    }, {
        idx = 1054,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1054",
        value_type = "uint8_t"
    }, {
        idx = 1055,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1055",
        value_type = "uint8_t"
    }, {
        idx = 1056,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1056",
        value_type = "uint8_t"
    }, {
        idx = 1057,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1057",
        value_type = "uint8_t"
    }, {
        idx = 1058,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1058",
        value_type = "uint8_t"
    }, {
        idx = 1059,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1059",
        value_type = "uint8_t"
    }, {
        idx = 1060,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1060",
        value_type = "uint8_t"
    }, {
        idx = 1061,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1061",
        value_type = "uint8_t"
    }, {
        idx = 1062,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1062",
        value_type = "uint8_t"
    }, {
        idx = 1063,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1063",
        value_type = "uint8_t"
    }, {
        idx = 1064,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1064",
        value_type = "uint8_t"
    }, {
        idx = 1065,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1065",
        value_type = "uint8_t"
    }, {
        idx = 1066,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1066",
        value_type = "uint8_t"
    }, {
        idx = 1067,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1067",
        value_type = "uint8_t"
    }, {
        idx = 1068,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1068",
        value_type = "uint8_t"
    }, {
        idx = 1069,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1069",
        value_type = "uint8_t"
    }, {
        idx = 1070,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1070",
        value_type = "uint8_t"
    }, {
        idx = 1071,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1071",
        value_type = "uint8_t"
    }, {
        idx = 1072,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1072",
        value_type = "uint8_t"
    }, {
        idx = 1073,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1073",
        value_type = "uint8_t"
    }, {
        idx = 1074,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1074",
        value_type = "uint8_t"
    }, {
        idx = 1075,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1075",
        value_type = "uint8_t"
    }, {
        idx = 1076,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1076",
        value_type = "uint8_t"
    }, {
        idx = 1077,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1077",
        value_type = "uint8_t"
    }, {
        idx = 1078,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1078",
        value_type = "uint8_t"
    }, {
        idx = 1079,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1079",
        value_type = "uint8_t"
    }, -- 消息体子命令类型0x10 ：主机运行参数查询 回复
    {
        idx = 1080,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "compRunFreq",
        value_type = "uint8_t"
    }, {
        idx = 1081,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "unitModeRun",
        value_map = {[1] = "invalid", [2] = "auto", [3] = "cool", [4] = "heat"}
    }, {
        idx = 1082,
        from = "odu",
        changed = 0,
        value = {2},
        size = 1,
        path = "fanSpeed",
        value_type = "uint8_t_1/10"
    }, {
        idx = 1083,
        from = "idu",
        changed = 0,
        value = {2},
        size = 1,
        path = "machVersion",
        value_type = "uint8_t"
    }, {
        idx = 1084,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgCapacityNeed",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1085,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT3",
        value_type = "temp"
    }, {
        idx = 1086,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT4",
        value_type = "temp"
    }, {
        idx = 1087,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTp",
        value_type = "temp"
    }, {
        idx = 1088,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTwin",
        value_type = "temp"
    }, {
        idx = 1089,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTwout",
        value_type = "temp"
    }, {
        idx = 1090,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTsolar",
        value_type = "temp"
    }, {
        idx = 1091,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "hydboxSubtype",
        value_type = "uint8_t"
    }, {
        idx = 1092,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgUSBInfoConnect",
        value_type = "uint8_t"
    }, {
        idx = 1093,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "usbIndexMax",
        value_type = "uint8_t"
    }, {
        idx = 1094,
        from = "idu",
        changed = 0,
        value = {0},
        size = 1,
        path = "p6ErrCode",
        value_type = "uint8_t"
    }, {
        idx = 1095,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduCompCurrent",
        value_type = "uint8_t"
    }, {
        idx = 1096,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "oduVoltage",
        value_type = "uint16_t"
    }, {
        idx = 1097,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "exvCurrent",
        value_type = "uint16_t_1/8"
    }, {
        idx = 1098,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduModel",
        value_type = "uint8_t"
    }, {
        idx = 1099,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "unitonlineNum",
        value_type = "uint8_t"
    }, {
        idx = 1100,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "currentCode",
        value_type = "uint8_t"
    }, {
        idx = 1101,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "u8Code1",
        value_type = "uint8_t"
    }, {
        idx = 1102,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "u8Code2",
        value_type = "uint8_t"
    }, {
        idx = 1103,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "u8Code3",
        value_type = "uint8_t"
    }, {
        idx = 1104,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgReqParaSet",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1105,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgReqVerAsk",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1106,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgReqSNAsk",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1107,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgUnitLockSignal",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1108,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgEVUSignal",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1109,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgSGSignal",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1110,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgTankAntiFreeze",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1111,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgSolarInput",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1112,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgRoomTherCoolRun",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1113,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgRoomTherHeatRun",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1114,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgOutDoorTestMode",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1115,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgRemoteOnOff",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1116,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgBackOil",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1117,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgAntiFreezeRun",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1118,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgDefrost",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1119,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgIsSlaveUnit",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1120,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgTBHEnable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1121,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgAHSIsOwn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1122,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgCapTestEnable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1123,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgT1BSensorEnable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1124,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgAHSDHWMode",
        value_type = "uint8_t"
    }, {
        idx = 1125,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgIBH1Enable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1126,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgT1SensorEnable",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1127,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgEdgeVersionType",
        value_type = "uint8_t"
    }, {
        idx = 1128,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgFactReqTherHeatOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1129,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgDHWRun",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1130,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgHeatRun",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1131,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgCoolRun",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1132,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgFactReqTherCoolOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1133,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgFactReqSolarOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1134,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgFactoryRun",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1135,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgDefValveOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1136,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgAHSValveOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1137,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgRunValveOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1138,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgAlmValveOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1139,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgPumpSolarOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1140,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgHeat4ValveOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1141,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgSV3Output",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1142,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgMixedPumpValveOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1143,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgPumpDHWOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1144,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgPumpOOn",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1145,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgSV2On",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1146,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgSV1On",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1147,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgPumpIOutput",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1148,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgTBHOutput",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1149,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgIBH2Output",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1150,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fgIBH1Output",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1151,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT1",
        value_type = "temp"
    }, {
        idx = 1152,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTw2",
        value_type = "temp"
    }, {
        idx = 1153,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT2",
        value_type = "temp"
    }, {
        idx = 1154,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT2b",
        value_type = "temp"
    }, {
        idx = 1155,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT5",
        value_type = "temp"
    }, {
        idx = 1156,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTa",
        value_type = "temp"
    }, {
        idx = 1157,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTbt1",
        value_type = "temp"
    }, {
        idx = 1158,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTbt2",
        value_type = "temp"
    }, {
        idx = 1159,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "hydroboxCapacity",
        value_type = "uint8_t"
    }, {
        idx = 1160,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "pressureHigh",
        value_type = "uint16_t"
    }, {
        idx = 1161,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "pressureLow",
        value_type = "uint16_t"
    }, {
        idx = 1162,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTh",
        value_type = "temp"
    }, {
        idx = 1163,
        from = "idu",
        changed = 0,
        value = {2},
        size = 1,
        path = "machineType",
        value_type = "uint8_t"
    }, {
        idx = 1164,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduTargetFre",
        value_type = "uint8_t"
    }, {
        idx = 1165,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "dcCurrent",
        value_type = "uint8_t_10"
    }, {
        idx = 1166,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "dcVoltage",
        value_type = "uint8_t_1/10"
    }, {
        idx = 1167,
        from = "idu",
        changed = 0,
        value = {8},
        size = 1,
        path = "tempTf",
        value_type = "temp"
    }, {
        idx = 1168,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduT1s1",
        value_type = "uint8_t"
    }, {
        idx = 1169,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduT1s2",
        value_type = "uint8_t"
    }, {
        idx = 1170,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "waterFlow",
        value_type = "uint16_t_100"
    }, {
        idx = 1171,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduPlanVolLmt",
        value_type = "uint8_t"
    }, {
        idx = 1172,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "currentUnitCapacity",
        value_type = "uint16_t_100"
    }, {
        idx = 1173,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "spheraAHSVoltage",
        value_type = "uint8_t"
    }, {
        idx = 1174,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT4Aver",
        value_type = "int8_t"
    }, {
        idx = 1175,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "waterPressure",
        value_type = "uint16_t"
    }, {
        idx = 1176,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "roomRelHum",
        value_type = "uint16_t"
    }, {
        idx = 1177,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "pwmPumpOut",
        value_type = "uint8_t"
    }, {
        idx = 1178,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity0",
        value_type = "uint32_t_100"
    }, {
        idx = 1179,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal0",
        value_type = "uint32_t_100"
    }, {
        idx = 1180,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "heatElecTotConsum0",
        value_type = "uint32_t_100"
    }, {
        idx = 1181,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "heatTotCapacity0",
        value_type = "uint32_t_100"
    }, {
        idx = 1182,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "instantPower0",
        value_type = "uint16_t_100"
    }, {
        idx = 1183,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "instantRenewPower0",
        value_type = "uint16_t_100"
    }, {
        idx = 1184,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalRenewPower0",
        value_type = "uint32_t_100"
    }, {
        idx = 1185,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduVersionNum",
        value_type = "uint8_t"
    }, {
        idx = 1186,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduVersionNum",
        value_type = "uint8_t"
    }, {
        idx = 1187,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode0",
        value_type = "chars",
        writable = true
    }, {
        idx = 1188,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode1",
        value_type = "chars",
        writable = true
    }, {
        idx = 1189,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode2",
        value_type = "chars",
        writable = true
    }, {
        idx = 1190,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode3",
        value_type = "chars",
        writable = true
    }, {
        idx = 1191,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode4",
        value_type = "chars",
        writable = true
    }, {
        idx = 1192,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode5",
        value_type = "chars",
        writable = true
    }, {
        idx = 1193,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode6",
        value_type = "chars",
        writable = true
    }, {
        idx = 1194,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode7",
        value_type = "chars",
        writable = true
    }, {
        idx = 1195,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode8",
        value_type = "chars",
        writable = true
    }, {
        idx = 1196,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode9",
        value_type = "chars",
        writable = true
    }, {
        idx = 1197,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode10",
        value_type = "chars",
        writable = true
    }, {
        idx = 1198,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode11",
        value_type = "chars",
        writable = true
    }, {
        idx = 1199,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode12",
        value_type = "chars",
        writable = true
    }, {
        idx = 1200,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode13",
        value_type = "chars",
        writable = true
    }, {
        idx = 1201,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode14",
        value_type = "chars",
        writable = true
    }, {
        idx = 1202,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode15",
        value_type = "chars",
        writable = true
    }, {
        idx = 1203,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode16",
        value_type = "chars",
        writable = true
    }, {
        idx = 1204,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode17",
        value_type = "chars",
        writable = true
    }, {
        idx = 1205,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode18",
        value_type = "chars",
        writable = true
    }, {
        idx = 1206,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode19",
        value_type = "chars",
        writable = true
    }, {
        idx = 1207,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode20",
        value_type = "chars",
        writable = true
    }, {
        idx = 1208,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode21",
        value_type = "chars",
        writable = true
    }, {
        idx = 1209,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode22",
        value_type = "chars",
        writable = true
    }, {
        idx = 1210,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode23",
        value_type = "chars",
        writable = true
    }, {
        idx = 1211,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode24",
        value_type = "chars",
        writable = true
    }, {
        idx = 1212,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode25",
        value_type = "chars",
        writable = true
    }, {
        idx = 1213,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode26",
        value_type = "chars",
        writable = true
    }, {
        idx = 1214,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode27",
        value_type = "chars",
        writable = true
    }, {
        idx = 1215,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode28",
        value_type = "chars",
        writable = true
    }, {
        idx = 1216,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode29",
        value_type = "chars",
        writable = true
    }, {
        idx = 1217,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode30",
        value_type = "chars",
        writable = true
    }, {
        idx = 1218,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduSNCode31",
        value_type = "chars",
        writable = true
    }, {
        idx = 1219,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode0",
        value_type = "chars",
        writable = true
    }, {
        idx = 1220,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode1",
        value_type = "chars",
        writable = true
    }, {
        idx = 1221,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode2",
        value_type = "chars",
        writable = true
    }, {
        idx = 1222,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode3",
        value_type = "chars",
        writable = true
    }, {
        idx = 1223,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode4",
        value_type = "chars",
        writable = true
    }, {
        idx = 1224,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode5",
        value_type = "chars",
        writable = true
    }, {
        idx = 1225,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode6",
        value_type = "chars",
        writable = true
    }, {
        idx = 1226,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode7",
        value_type = "chars",
        writable = true
    }, {
        idx = 1227,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode8",
        value_type = "chars",
        writable = true
    }, {
        idx = 1228,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode9",
        value_type = "chars",
        writable = true
    }, {
        idx = 1229,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode10",
        value_type = "chars",
        writable = true
    }, {
        idx = 1230,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode11",
        value_type = "chars",
        writable = true
    }, {
        idx = 1231,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode12",
        value_type = "chars",
        writable = true
    }, {
        idx = 1232,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode13",
        value_type = "chars",
        writable = true
    }, {
        idx = 1233,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode14",
        value_type = "chars",
        writable = true
    }, {
        idx = 1234,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode15",
        value_type = "chars",
        writable = true
    }, {
        idx = 1235,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode16",
        value_type = "chars",
        writable = true
    }, {
        idx = 1236,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode17",
        value_type = "chars",
        writable = true
    }, {
        idx = 1237,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode18",
        value_type = "chars",
        writable = true
    }, {
        idx = 1238,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode19",
        value_type = "chars",
        writable = true
    }, {
        idx = 1239,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode20",
        value_type = "chars",
        writable = true
    }, {
        idx = 1240,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode21",
        value_type = "chars",
        writable = true
    }, {
        idx = 1241,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode22",
        value_type = "chars",
        writable = true
    }, {
        idx = 1242,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode23",
        value_type = "chars",
        writable = true
    }, {
        idx = 1243,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode24",
        value_type = "chars",
        writable = true
    }, {
        idx = 1244,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode25",
        value_type = "chars",
        writable = true
    }, {
        idx = 1245,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode26",
        value_type = "chars",
        writable = true
    }, {
        idx = 1246,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode27",
        value_type = "chars",
        writable = true
    }, {
        idx = 1247,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode28",
        value_type = "chars",
        writable = true
    }, {
        idx = 1248,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode29",
        value_type = "chars",
        writable = true
    }, {
        idx = 1249,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode30",
        value_type = "chars",
        writable = true
    }, {
        idx = 1250,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduSNCode31",
        value_type = "chars",
        writable = true
    }, {
        idx = 1251,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode0",
        value_type = "chars"
    }, {
        idx = 1252,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode1",
        value_type = "chars"
    }, {
        idx = 1253,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode2",
        value_type = "chars"
    }, {
        idx = 1254,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode3",
        value_type = "chars"
    }, {
        idx = 1255,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode4",
        value_type = "chars"
    }, {
        idx = 1256,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode5",
        value_type = "chars"
    }, {
        idx = 1257,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode6",
        value_type = "chars"
    }, {
        idx = 1258,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode7",
        value_type = "chars"
    }, {
        idx = 1259,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode8",
        value_type = "chars"
    }, {
        idx = 1260,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode9",
        value_type = "chars"
    }, {
        idx = 1261,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode10",
        value_type = "chars"
    }, {
        idx = 1262,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode11",
        value_type = "chars"
    }, {
        idx = 1263,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode12",
        value_type = "chars"
    }, {
        idx = 1264,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode13",
        value_type = "chars"
    }, {
        idx = 1265,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode14",
        value_type = "chars"
    }, {
        idx = 1266,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode15",
        value_type = "chars"
    }, {
        idx = 1267,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode16",
        value_type = "chars"
    }, {
        idx = 1268,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode17",
        value_type = "chars"
    }, {
        idx = 1269,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode18",
        value_type = "chars"
    }, {
        idx = 1270,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode19",
        value_type = "chars"
    }, {
        idx = 1271,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode20",
        value_type = "chars"
    }, {
        idx = 1272,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode21",
        value_type = "chars"
    }, {
        idx = 1273,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode22",
        value_type = "chars"
    }, {
        idx = 1274,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode23",
        value_type = "chars"
    }, {
        idx = 1275,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode24",
        value_type = "chars"
    }, {
        idx = 1276,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode25",
        value_type = "chars"
    }, {
        idx = 1277,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode26",
        value_type = "chars"
    }, {
        idx = 1278,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode27",
        value_type = "chars"
    }, {
        idx = 1279,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode28",
        value_type = "chars"
    }, {
        idx = 1280,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode29",
        value_type = "chars"
    }, {
        idx = 1281,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode30",
        value_type = "chars"
    }, {
        idx = 1282,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "hmiSNCode31",
        value_type = "chars"
    }, {
        idx = 1283,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "oduVersionDate",
        value_type = "uint16_t"
    }, {
        idx = 1284,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "iduVersionDate",
        value_type = "uint16_t"
    }, {
        idx = 1285,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT9i",
        value_type = "temp"
    }, {
        idx = 1286,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT9o",
        value_type = "temp"
    }, {
        idx = 1287,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "exv2Current",
        value_type = "uint16_t"
    }, {
        idx = 1288,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "exv3Current",
        value_type = "uint16_t"
    }, {
        idx = 1289,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved1289",
        value_type = "uint16_t"
    }, -- 消息体子命令类型0x0A ：线控器参数查询 回复
    {
        idx = 1290,
        from = "controller",
        changed = 0,
        value = {1, 0, 60},
        size = 3,
        path = "hmiVersionNum",
        value_type = "version"
    }, {
        idx = 1291,
        from = "controller",
        changed = 0,
        value = {300},
        size = 2,
        path = "compRunCurTime0",
        value_type = "uint16_t"
    }, {
        idx = 1292,
        from = "controller",
        changed = 0,
        value = {65535},
        size = 2,
        path = "compRunTotalTime0",
        value_type = "uint16_t"
    }, {
        idx = 1293,
        from = "controller",
        changed = 0,
        value = {65534},
        size = 2,
        path = "fanRunTotalTime0",
        value_type = "uint16_t"
    }, {
        idx = 1294,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "pumpiRunTotalTime0",
        value_type = "uint16_t"
    }, {
        idx = 1295,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "ibh1RunTotalTime0",
        value_type = "uint16_t"
    }, {
        idx = 1296,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "ibh2RunTotalTime0",
        value_type = "uint16_t"
    }, {
        idx = 1297,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "tbhRunTotalTime0",
        value_type = "uint16_t"
    }, {
        idx = 1298,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "ahsRunTotalTime0",
        value_type = "uint16_t"
    }, {
        idx = 1299,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "arrayServiceTel0",
        value_type = "chars"
    }, {
        idx = 1300,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "arrayServiceTel1",
        value_type = "chars"
    }, {
        idx = 1301,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "arrayServiceTel2",
        value_type = "chars"
    }, {
        idx = 1302,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "arrayServiceTel3",
        value_type = "chars"
    }, {
        idx = 1303,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "arrayServiceTel4",
        value_type = "chars"
    }, {
        idx = 1304,
        from = "controller",
        changed = 0,
        value = {6},
        size = 1,
        path = "arrayServiceTel5",
        value_type = "chars"
    }, {
        idx = 1305,
        from = "controller",
        changed = 0,
        value = {7},
        size = 1,
        path = "arrayServiceTel6",
        value_type = "chars"
    }, {
        idx = 1306,
        from = "controller",
        changed = 0,
        value = {8},
        size = 1,
        path = "arrayServiceTel7",
        value_type = "chars"
    }, {
        idx = 1307,
        from = "controller",
        changed = 0,
        value = {9},
        size = 1,
        path = "arrayServiceTel8",
        value_type = "chars"
    }, {
        idx = 1308,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "arrayServiceTel9",
        value_type = "chars"
    }, {
        idx = 1309,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "arrayServiceTel10",
        value_type = "chars"
    }, {
        idx = 1310,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "arrayServiceTel11",
        value_type = "chars"
    }, {
        idx = 1311,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "arrayServiceTel12",
        value_type = "chars"
    }, {
        idx = 1312,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "arrayServiceTel13",
        value_type = "chars"
    }, {
        idx = 1313,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "arrayServiceTel14",
        value_type = "chars"
    }, {
        idx = 1314,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "ArrayServiceCel0",
        value_type = "chars"
    }, {
        idx = 1315,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "ArrayServiceCel1",
        value_type = "chars"
    }, {
        idx = 1316,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "ArrayServiceCel2",
        value_type = "chars"
    }, {
        idx = 1317,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "ArrayServiceCel3",
        value_type = "chars"
    }, {
        idx = 1318,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "ArrayServiceCel4",
        value_type = "chars"
    }, {
        idx = 1319,
        from = "controller",
        changed = 0,
        value = {6},
        size = 1,
        path = "ArrayServiceCel5",
        value_type = "chars"
    }, {
        idx = 1320,
        from = "controller",
        changed = 0,
        value = {7},
        size = 1,
        path = "ArrayServiceCel6",
        value_type = "chars"
    }, {
        idx = 1321,
        from = "controller",
        changed = 0,
        value = {8},
        size = 1,
        path = "ArrayServiceCel7",
        value_type = "chars"
    }, {
        idx = 1322,
        from = "controller",
        changed = 0,
        value = {9},
        size = 1,
        path = "ArrayServiceCel8",
        value_type = "chars"
    }, {
        idx = 1323,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "ArrayServiceCel9",
        value_type = "chars"
    }, {
        idx = 1324,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "ArrayServiceCel10",
        value_type = "chars"
    }, {
        idx = 1325,
        from = "controller",
        changed = 0,
        value = {2},
        size = 1,
        path = "ArrayServiceCel11",
        value_type = "chars"
    }, {
        idx = 1326,
        from = "controller",
        changed = 0,
        value = {3},
        size = 1,
        path = "ArrayServiceCel12",
        value_type = "chars"
    }, {
        idx = 1327,
        from = "controller",
        changed = 0,
        value = {4},
        size = 1,
        path = "ArrayServiceCel13",
        value_type = "chars"
    }, {
        idx = 1328,
        from = "controller",
        changed = 0,
        value = {5},
        size = 1,
        path = "ArrayServiceCel14",
        value_type = "chars"
    }, {
        idx = 1329,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "u8warnTotal",
        value_type = "uint8_t"
    }, {
        idx = 1330,
        from = "controller",
        changed = 0,
        value = {1},
        size = 5,
        path = "codeErrProt1",
        value_type = "chars"
    }, {
        idx = 1331,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "warnAddress1",
        value_type = "uint8_t"
    }, {
        idx = 1332,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnHour1",
        value_type = "hour"
    }, {
        idx = 1333,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMin1",
        value_type = "min"
    }, {
        idx = 1334,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnYear1",
        value_type = "year"
    }, {
        idx = 1335,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMonth1",
        value_type = "month"
    }, {
        idx = 1336,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnDate1",
        value_type = "date"
    }, {
        idx = 1337,
        from = "controller",
        changed = 0,
        value = {1},
        size = 5,
        path = "codeErrProt2",
        value_type = "chars"
    }, {
        idx = 1338,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "warnAddress2",
        value_type = "uint8_t"
    }, {
        idx = 1339,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnHour2",
        value_type = "hour"
    }, {
        idx = 1340,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMin2",
        value_type = "min"
    }, {
        idx = 1341,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnYear2",
        value_type = "year"
    }, {
        idx = 1342,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMonth2",
        value_type = "month"
    }, {
        idx = 1343,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnDate2",
        value_type = "date"
    }, {
        idx = 1344,
        from = "controller",
        changed = 0,
        value = {1},
        size = 5,
        path = "codeErrProt3",
        value_type = "chars"
    }, {
        idx = 1345,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "warnAddress3",
        value_type = "uint8_t"
    }, {
        idx = 1346,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnHour3",
        value_type = "hour"
    }, {
        idx = 1347,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMin3",
        value_type = "min"
    }, {
        idx = 1348,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnYear3",
        value_type = "year"
    }, {
        idx = 1349,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMonth3",
        value_type = "month"
    }, {
        idx = 1350,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnDate3",
        value_type = "date"
    }, {
        idx = 1351,
        from = "controller",
        changed = 0,
        value = {1},
        size = 5,
        path = "codeErrProt4",
        value_type = "chars"
    }, {
        idx = 1352,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "warnAddress4",
        value_type = "uint8_t"
    }, {
        idx = 1353,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnHour4",
        value_type = "hour"
    }, {
        idx = 1354,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMin4",
        value_type = "min"
    }, {
        idx = 1355,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnYear4",
        value_type = "year"
    }, {
        idx = 1356,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMonth4",
        value_type = "month"
    }, {
        idx = 1357,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnDate4",
        value_type = "date"
    }, {
        idx = 1358,
        from = "controller",
        changed = 0,
        value = {1},
        size = 5,
        path = "codeErrProt5",
        value_type = "chars"
    }, {
        idx = 1359,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "warnAddress5",
        value_type = "uint8_t"
    }, {
        idx = 1360,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnHour5",
        value_type = "hour"
    }, {
        idx = 1361,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMin5",
        value_type = "min"
    }, {
        idx = 1362,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnYear5",
        value_type = "year"
    }, {
        idx = 1363,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMonth5",
        value_type = "month"
    }, {
        idx = 1364,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnDate5",
        value_type = "date"
    }, {
        idx = 1365,
        from = "controller",
        changed = 0,
        value = {1},
        size = 5,
        path = "codeErrProt6",
        value_type = "chars"
    }, {
        idx = 1366,
        from = "controller",
        changed = 0,
        value = {0},
        size = 1,
        path = "warnAddress6",
        value_type = "uint8_t"
    }, {
        idx = 1367,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnHour6",
        value_type = "hour"
    }, {
        idx = 1368,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMin6",
        value_type = "min"
    }, {
        idx = 1369,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnYear6",
        value_type = "year"
    }, {
        idx = 1370,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnMonth6",
        value_type = "month"
    }, {
        idx = 1371,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "warnDate6",
        value_type = "date"
    }, {
        idx = 1372,
        from = "controller",
        changed = 0,
        value = {1},
        size = 12,
        path = "codeErrStr1",
        value_type = "chars"
    }, {
        idx = 1373,
        from = "controller",
        changed = 0,
        value = {1},
        size = 12,
        path = "codeErrStr2",
        value_type = "chars"
    }, {
        idx = 1374,
        from = "controller",
        changed = 0,
        value = {1},
        size = 12,
        path = "codeErrStr3",
        value_type = "chars"
    }, {
        idx = 1375,
        from = "controller",
        changed = 0,
        value = {1},
        size = 12,
        path = "codeErrStr4",
        value_type = "chars"
    }, {
        idx = 1376,
        from = "controller",
        changed = 0,
        value = {1},
        size = 12,
        path = "codeErrStr5",
        value_type = "chars"
    }, {
        idx = 1377,
        from = "controller",
        changed = 0,
        value = {1},
        size = 12,
        path = "codeErrStr6",
        value_type = "chars"
    }, {
        idx = 1378,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "_hmiVersionNum_patch",
        value_type = "uint8_t"
    }, {
        idx = 1379,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "_hmiVersionNum_patch2",
        value_type = "uint32_t"
    }, ---- 0x04-主动上报 消息体子命令类型0x05  命令
    {
        idx = 1380,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "compRunFreq",
        value_type = "uint8_t"
    }, {
        idx = 1381,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "fanSpeed",
        value_type = "uint8_t_1/10"
    }, {
        idx = 1382,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT3",
        value_type = "temp"
    }, {
        idx = 1383,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT4",
        value_type = "temp"
    }, {
        idx = 1384,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTp",
        value_type = "temp"
    }, {
        idx = 1385,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTwin",
        value_type = "temp"
    }, {
        idx = 1386,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTwout",
        value_type = "temp"
    }, {
        idx = 1387,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduCompCurrent",
        value_type = "uint8_t"
    }, {
        idx = 1388,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "oduVoltage",
        value_type = "uint16_t"
    }, {
        idx = 1389,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT1",
        value_type = "temp"
    }, {
        idx = 1390,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTw2",
        value_type = "temp"
    }, {
        idx = 1391,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT2",
        value_type = "temp"
    }, {
        idx = 1392,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT2b",
        value_type = "temp"
    }, {
        idx = 1393,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempT5",
        value_type = "temp"
    }, {
        idx = 1394,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTa",
        value_type = "temp"
    }, {
        idx = 1395,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "pressureHigh",
        value_type = "uint16_t"
    }, {
        idx = 1396,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "pressureLow",
        value_type = "uint16_t"
    }, {
        idx = 1397,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTh",
        value_type = "temp"
    }, {
        idx = 1398,
        from = "odu",
        changed = 0,
        value = {1},
        size = 1,
        path = "oduTargetFre",
        value_type = "uint8_t"
    }, {
        idx = 1399,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "tempTf",
        value_type = "temp"
    }, {
        idx = 1400,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduT1s1",
        value_type = "uint8_t"
    }, {
        idx = 1401,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "iduT1s2",
        value_type = "uint8_t"
    }, {
        idx = 1402,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "waterFlow",
        value_type = "uint16_t_100"
    }, {
        idx = 1403,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "currentUnitCapacity",
        value_type = "uint16_t_100"
    }, {
        idx = 1404,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "waterPressure",
        value_type = "uint16_t"
    }, {
        idx = 1405,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "roomRelHum",
        value_type = "uint16_t"
    }, {
        idx = 1406,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalelectricity0",
        value_type = "uint32_t_100"
    }, {
        idx = 1407,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalthermal0",
        value_type = "uint32_t_100"
    }, {
        idx = 1408,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "heatElecTotConsum0",
        value_type = "uint32_t_100"
    }, {
        idx = 1409,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "heatTotCapacity0",
        value_type = "uint32_t_100"
    }, {
        idx = 1410,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "instantPower0",
        value_type = "uint32_t_100"
    }, {
        idx = 1411,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "instantRenewPower0",
        value_type = "uint32_t_100"
    }, {
        idx = 1412,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "totalRenewPower0",
        value_type = "uint32_t_100"
    }, {
        idx = 1413,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "compRunTotalTime0",
        value_type = "uint16_t"
    }, {
        idx = 1414,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "pwmPumpOut",
        value_type = "uint8_t"
    }, {
        idx = 1415,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "run_mode_set",
        value_map = {
            [1] = "off",
            [2] = "wind",
            [3] = "cool",
            [4] = "heat",
            [5] = "force_cool",
            [6] = "auto",
            [7] = "humi",
            [117] = "on",
            [118] = "dehumi",
            [256] = "invalid"
        }
    }, {
        idx = 1416,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "SysInstantHPCapacity",
        value_type = "uint16_t"
    }, {
        idx = 1417,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "SysInstantRenewPower",
        value_type = "uint16_t"
    }, {
        idx = 1418,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "SysInstantPower",
        value_type = "uint16_t"
    }, {
        idx = 1419,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysInstantCopEER",
        value_type = "uint32_t"
    }, {
        idx = 1420,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysTotalHPCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1421,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysTotalRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1422,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysTotalPowerConsum",
        value_type = "uint32_t"
    }, {
        idx = 1423,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysTotalCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1424,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "SysEnergyAnaEN",
        value_type = "uint8_t"
    }, {
        idx = 1425,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "HMIEnergyAnaSetEN",
        value_type = "uint8_t"
    }, {
        idx = 1426,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatInsHPCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1427,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatInsRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1428,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatInsPower",
        value_type = "uint32_t"
    }, {
        idx = 1429,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatInsCopEER",
        value_type = "uint32_t"
    }, {
        idx = 1430,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1431,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1432,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1433,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1434,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolInsHPCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1435,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolInsRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1436,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolInsPower",
        value_type = "uint32_t"
    }, {
        idx = 1437,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolInsCopEER",
        value_type = "uint32_t"
    }, {
        idx = 1438,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1439,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1440,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1441,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1442,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwInsHPCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1443,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwInsRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1444,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwInsPower",
        value_type = "uint32_t"
    }, {
        idx = 1445,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwInsCopEER",
        value_type = "uint32_t"
    }, {
        idx = 1446,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1447,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1448,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1449,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1450,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatDayCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1451,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatDayRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1452,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatDayElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1453,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatDayCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1454,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatWeekCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1455,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatWeekRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1456,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatWeekElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1457,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatWeekCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1458,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatMonthCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1459,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatMonthRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1460,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatMonthElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1461,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatMonthCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1462,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatYearCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1463,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatYearRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1464,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatYearElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1465,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysHeatYearCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1466,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolDayCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1467,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolDayRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1468,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolDayElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1469,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolDayCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1470,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolWeekCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1471,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolWeekRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1472,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolWeekElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1473,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolWeekCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1474,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolMonthCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1475,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolMonthRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1476,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolMonthElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1477,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolMonthCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1478,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolYearCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1479,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolYearRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1480,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolYearElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1481,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysCoolYearCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1482,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwDayCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1483,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwDayRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1484,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwDayElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1485,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwDayCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1486,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwWeekCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1487,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwWeekRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1488,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwWeekElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1489,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwWeekCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1490,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwMonthCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1491,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwMonthRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1492,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwMonthElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1493,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwMonthCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1494,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwYearCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1495,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwYearRenewPower",
        value_type = "uint32_t"
    }, {
        idx = 1496,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwYearElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1497,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysDhwYearCOPEER",
        value_type = "uint32_t"
    }, {
        idx = 1498,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysTotalHeatCapacity",
        value_type = "uint32_t"
    }, {
        idx = 1499,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysTotalHeatElecConsum",
        value_type = "uint32_t"
    }, {
        idx = 1500,
        from = "controller",
        changed = 0,
        value = {1, 0, 60},
        size = 3,
        path = "hmiVersionNum",
        value_type = "version"
    }, {
        idx = 1501,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "_hmiVersionNum_patch",
        value_type = "uint8_t"
    }, {
        idx = 1502,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "SysPrecision",
        value_type = "uint8_t"
    }, {
        idx = 1503,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "SysEnergyMethod",
        value_type = "uint8_t"
    }, {
        idx = 1504,
        from = "idu",
        changed = 0,
        value = {1},
        size = 4,
        path = "SysTotalPowerConsum2",
        value_type = "uint32_t"
    }, {
        idx = 1505,
        from = "odu",
        changed = 0,
        value = {1},
        size = 2,
        path = "TempTl",
        value_type = "int16_t"
    }, {
        idx = 1506,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "P1_calc",
        value_type = "int16_t_1/10"
    }, {
        idx = 1507,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "P2_calc",
        value_type = "int16_t_1/10"
    }, {
        idx = 1508,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "Tp_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1509,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "Th_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1510,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "T3_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1511,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "TL_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1512,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "T4_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1513,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "T2b_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1514,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "T2_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1515,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "Tw_in_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1516,
        from = "idu",
        changed = 0,
        value = {1},
        size = 2,
        path = "Tw_out_calc",
        value_type = "int16_t_10"
    }, {
        idx = 1517,
        from = "controller",
        changed = 0,
        value = {1},
        size = 2,
        path = "reserved1517",
        value_type = "uint16_t"
    }, {
        idx = 1518,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1518",
        value_type = "uint8_t"
    }, {
        idx = 1519,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "unitModeRun",
        value_map = {[1] = "invalid", [2] = "auto", [3] = "cool", [4] = "heat"}
    }, {
        idx = 1520,
        from = "controller",
        changed = 0,
        value = {1},
        size = 4,
        path = "_hmiVersionNum_patch2",
        value_type = "uint32_t"
    }, {
        idx = 1521,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1521",
        value_type = "uint8_t"
    }, {
        idx = 1522,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1522",
        value_type = "uint8_t"
    }, {
        idx = 1523,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1523",
        value_type = "uint8_t"
    }, {
        idx = 1524,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1524",
        value_type = "uint8_t"
    }, {
        idx = 1525,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1525",
        value_type = "uint8_t"
    }, {
        idx = 1526,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1526",
        value_type = "uint8_t"
    }, {
        idx = 1527,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1527",
        value_type = "uint8_t"
    }, {
        idx = 1528,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1528",
        value_type = "uint8_t"
    }, {
        idx = 1529,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1529",
        value_type = "uint8_t"
    }, {
        idx = 1530,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1530",
        value_type = "uint8_t"
    }, {
        idx = 1531,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1531",
        value_type = "uint8_t"
    }, {
        idx = 1532,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1532",
        value_type = "uint8_t"
    }, {
        idx = 1533,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1533",
        value_type = "uint8_t"
    }, {
        idx = 1534,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1534",
        value_type = "uint8_t"
    }, {
        idx = 1535,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1535",
        value_type = "uint8_t"
    }, {
        idx = 1536,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1536",
        value_type = "uint8_t"
    }, {
        idx = 1537,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1537",
        value_type = "uint8_t"
    }, {
        idx = 1538,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1538",
        value_type = "uint8_t"
    }, {
        idx = 1539,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1539",
        value_type = "uint8_t"
    }, {
        idx = 1540,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1540",
        value_type = "uint8_t"
    }, {
        idx = 1541,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1541",
        value_type = "uint8_t"
    }, {
        idx = 1542,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1542",
        value_type = "uint8_t"
    }, {
        idx = 1543,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1543",
        value_type = "uint8_t"
    }, {
        idx = 1544,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1544",
        value_type = "uint8_t"
    }, {
        idx = 1545,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1545",
        value_type = "uint8_t"
    }, {
        idx = 1546,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1546",
        value_type = "uint8_t"
    }, {
        idx = 1547,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1547",
        value_type = "uint8_t"
    }, {
        idx = 1548,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1548",
        value_type = "uint8_t"
    }, {
        idx = 1549,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1549",
        value_type = "uint8_t"
    }, {
        idx = 1550,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1550",
        value_type = "uint8_t"
    }, {
        idx = 1551,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1551",
        value_type = "uint8_t"
    }, {
        idx = 1552,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1552",
        value_type = "uint8_t"
    }, {
        idx = 1553,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1553",
        value_type = "uint8_t"
    }, {
        idx = 1554,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1554",
        value_type = "uint8_t"
    }, {
        idx = 1555,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1555",
        value_type = "uint8_t"
    }, {
        idx = 1556,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1556",
        value_type = "uint8_t"
    }, {
        idx = 1557,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1557",
        value_type = "uint8_t"
    }, {
        idx = 1558,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1558",
        value_type = "uint8_t"
    }, {
        idx = 1559,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1559",
        value_type = "uint8_t"
    }, {
        idx = 1560,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1560",
        value_type = "uint8_t"
    }, {
        idx = 1561,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1561",
        value_type = "uint8_t"
    }, {
        idx = 1562,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1562",
        value_type = "uint8_t"
    }, {
        idx = 1563,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1563",
        value_type = "uint8_t"
    }, {
        idx = 1564,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1564",
        value_type = "uint8_t"
    }, {
        idx = 1565,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1565",
        value_type = "uint8_t"
    }, {
        idx = 1566,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1566",
        value_type = "uint8_t"
    }, {
        idx = 1567,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1567",
        value_type = "uint8_t"
    }, {
        idx = 1568,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1568",
        value_type = "uint8_t"
    }, {
        idx = 1569,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1569",
        value_type = "uint8_t"
    }, {
        idx = 1570,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1570",
        value_type = "uint8_t"
    }, {
        idx = 1571,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1571",
        value_type = "uint8_t"
    }, {
        idx = 1572,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1572",
        value_type = "uint8_t"
    }, {
        idx = 1573,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1573",
        value_type = "uint8_t"
    }, {
        idx = 1574,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1574",
        value_type = "uint8_t"
    }, {
        idx = 1575,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1575",
        value_type = "uint8_t"
    }, {
        idx = 1576,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1576",
        value_type = "uint8_t"
    }, {
        idx = 1577,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1577",
        value_type = "uint8_t"
    }, {
        idx = 1578,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1578",
        value_type = "uint8_t"
    }, {
        idx = 1579,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1579",
        value_type = "uint8_t"
    }, -- 0x30-查询配置参数范围  命令
    {
        idx = 1580,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "t1SClimitExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1581,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "ACSExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1582,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "HMISetIBHExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1583,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "HMISetAHSExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1584,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "HMISetTBHExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1585,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "pumpiSilentModeExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1586,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "pPipeLengthExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1587,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "energyCorrectionExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1588,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "backupSenserExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1589,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "energyMeterExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1590,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "boostExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1591,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "pumpOExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1592,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "modeSetPriExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1593,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "AHSPumpExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1594,
        from = "idu",
        changed = 0,
        value = {1},
        size = 1,
        path = "zone2CoolExist",
        value_map = {[1] = "off", [2] = "on"}
    }, {
        idx = 1595,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1595",
        value_type = "uint8_t"
    }, {
        idx = 1596,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1596",
        value_type = "uint8_t"
    }, {
        idx = 1597,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1597",
        value_type = "uint8_t"
    }, {
        idx = 1598,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1598",
        value_type = "uint8_t"
    }, {
        idx = 1599,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1599",
        value_type = "uint8_t"
    }, {
        idx = 1600,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1600",
        value_type = "uint8_t"
    }, {
        idx = 1601,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1601",
        value_type = "uint8_t"
    }, {
        idx = 1602,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1602",
        value_type = "uint8_t"
    }, {
        idx = 1603,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1603",
        value_type = "uint8_t"
    }, {
        idx = 1604,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1604",
        value_type = "uint8_t"
    }, {
        idx = 1605,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1605",
        value_type = "uint8_t"
    }, {
        idx = 1606,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1606",
        value_type = "uint8_t"
    }, {
        idx = 1607,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1607",
        value_type = "uint8_t"
    }, {
        idx = 1608,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1608",
        value_type = "uint8_t"
    }, {
        idx = 1609,
        from = "controller",
        changed = 0,
        value = {1},
        size = 1,
        path = "reserved1609",
        value_type = "uint8_t"
    }

}

local array_f_to_c = {
    [-13] = 0,
    -- -25
    [-12] = 1,
    -- -24.5
    [-11] = 2,
    -- -24
    [-10] = 3,
    -- -23.5
    [-9] = 4,
    -- -23
    [-9] = 5,
    -- -22.5
    [-8] = 6,
    -- -22
    [-7] = 7,
    -- -21.5
    [-6] = 8,
    -- -21
    [-5] = 9,
    -- -20.5
    [-4] = 10,
    -- -20
    [-3] = 11,
    -- -19.5
    [-2] = 12,
    -- -19
    [-2] = 13,
    -- -18.5
    [-1] = 14,
    -- -18
    [0] = 15,
    -- -17.5
    [1] = 16,
    -- -17
    [2] = 17,
    -- -16.5
    [3] = 18,
    -- -16
    [4] = 19,
    -- -15.5
    [5] = 20,
    -- -15
    [6] = 21,
    -- -14.5
    [7] = 22,
    -- -14
    [8] = 23,
    -- -13.5
    [9] = 24,
    -- -13
    [10] = 25,
    -- -12.5
    [10] = 26,
    -- -12
    [11] = 27,
    -- -11.5
    [12] = 28,
    -- -11
    [13] = 29,
    -- -10.5
    [14] = 30,
    -- -10
    [15] = 31,
    -- -9.5
    [16] = 32,
    -- -9
    [17] = 33,
    -- -8.5
    [18] = 34,
    -- -8
    [19] = 35,
    -- -7.5
    [19] = 36,
    -- -7
    [20] = 37,
    -- -6.5
    [21] = 38,
    -- -6
    [22] = 39,
    -- -5.5
    [23] = 40,
    -- -5
    [24] = 41,
    -- -4.5
    [25] = 42,
    -- -4
    [26] = 43,
    -- -3.5
    [27] = 44,
    -- -3
    [28] = 45,
    -- -2.5
    [28] = 46,
    -- -2
    [29] = 47,
    -- -1.5
    [30] = 48,
    -- -1
    [31] = 49,
    -- -0.5
    [32] = 50,
    -- 0
    [33] = 51,
    -- 0.5
    [34] = 52,
    -- 1
    [35] = 53,
    -- 1.5
    [36] = 54,
    -- 2
    [37] = 55,
    -- 2.5
    [37] = 56,
    -- 3
    [38] = 57,
    -- 3.5
    [39] = 58,
    -- 4
    [40] = 59,
    -- 4.5
    [41] = 60,
    -- 5
    [42] = 61,
    -- 5.5
    [43] = 62,
    -- 6
    [44] = 63,
    -- 6.5
    [45] = 64,
    -- 7
    [46] = 65,
    -- 7.5
    [46] = 66,
    -- 8
    [47] = 67,
    -- 8.5
    [48] = 68,
    -- 9
    [49] = 69,
    -- 9.5
    [50] = 70,
    -- 10
    [51] = 71,
    -- 10.5
    [52] = 72,
    -- 11
    [53] = 73,
    -- 11.5
    [54] = 74,
    -- 12
    [55] = 75,
    -- 12.5
    [55] = 76,
    -- 13
    [56] = 77,
    -- 13.5
    [57] = 78,
    -- 14
    [58] = 79,
    -- 14.5
    [59] = 80,
    -- 15
    [60] = 81,
    -- 15.5
    [61] = 82,
    -- 16
    [62] = 83,
    -- 16.5
    [62] = 84,
    -- 17
    [63] = 85,
    -- 17.5
    [64] = 86,
    -- 18
    [65] = 87,
    -- 18.5
    [66] = 88,
    -- 19
    [67] = 89,
    -- 19.5
    [68] = 90,
    -- 20
    [69] = 91,
    -- 20.5
    [70] = 92,
    -- 21
    [71] = 93,
    -- 21.5
    [72] = 94,
    -- 22
    [73] = 95,
    -- 22.5
    [73] = 96,
    -- 23
    [74] = 97,
    -- 23.5
    [75] = 98,
    -- 24
    [76] = 99,
    -- 24.5
    [77] = 100,
    -- 25
    [78] = 101,
    -- 25.5
    [79] = 102,
    -- 26
    [80] = 103,
    -- 26.5
    [81] = 104,
    -- 27
    [82] = 105,
    -- 27.5
    [82] = 106,
    -- 28
    [83] = 107,
    -- 28.5
    [84] = 108,
    -- 29
    [85] = 109,
    -- 29.5
    [86] = 110,
    -- 30
    [87] = 111,
    -- 30.5
    [88] = 112,
    -- 31
    [89] = 113,
    -- 31.5
    [90] = 114,
    -- 32
    [91] = 115,
    -- 32.5
    [91] = 116,
    -- 33
    [92] = 117,
    -- 33.5
    [93] = 118,
    -- 34
    [94] = 119,
    -- 34.5
    [95] = 120,
    -- 35
    [96] = 121,
    -- 35.5
    [97] = 122,
    -- 36
    [98] = 123,
    -- 36.5
    [99] = 124,
    -- 37
    [100] = 125,
    -- 37.5
    [100] = 126,
    -- 38
    [101] = 127,
    -- 38.5
    [102] = 128,
    -- 39
    [103] = 129,
    -- 39.5
    [104] = 130,
    -- 40
    [105] = 131,
    -- 40.5
    [106] = 132,
    -- 41
    [107] = 133,
    -- 41.5
    [108] = 134,
    -- 42
    [109] = 135,
    -- 42.5
    [109] = 136,
    -- 43
    [110] = 137,
    -- 43.5
    [111] = 138,
    -- 44
    [112] = 139,
    -- 44.5
    [113] = 140,
    -- 45
    [114] = 141,
    -- 45.5
    [115] = 142,
    -- 46
    [116] = 143,
    -- 46.5
    [117] = 144,
    -- 47
    [118] = 145,
    -- 47.5
    [118] = 146,
    -- 48
    [119] = 147,
    -- 48.5
    [120] = 148,
    -- 49
    [121] = 149,
    -- 49.5
    [122] = 150,
    -- 50
    [123] = 151,
    -- 50.5
    [124] = 152,
    -- 51
    [125] = 153,
    -- 51.5
    [126] = 154,
    -- 52
    [127] = 155,
    -- 52.5
    [127] = 156,
    -- 53
    [128] = 157,
    -- 53.5
    [129] = 158,
    -- 54
    [130] = 159,
    -- 54.5
    [131] = 160,
    -- 55
    [132] = 161,
    -- 55.5
    [133] = 162,
    -- 56
    [134] = 163,
    -- 56.5
    [135] = 164,
    -- 57
    [136] = 165,
    -- 57.5
    [136] = 166,
    -- 58
    [137] = 167,
    -- 58.5
    [138] = 168,
    -- 59
    [139] = 169,
    -- 59.5
    [140] = 170,
    -- 60
    [141] = 171,
    -- 60.5
    [142] = 172,
    -- 61
    [143] = 173,
    -- 61.5
    [144] = 174,
    -- 62
    [145] = 175,
    -- 62.5
    [145] = 176,
    -- 63
    [146] = 177,
    -- 63.5
    [147] = 178,
    -- 64
    [148] = 179,
    -- 64.5
    [149] = 180,
    -- 65
    [150] = 181,
    -- 65.5
    [151] = 182,
    -- 66
    [152] = 183,
    -- 66.5
    [153] = 184,
    -- 67
    [154] = 185,
    -- 67.5
    [154] = 186,
    -- 68
    [155] = 187,
    -- 68.5
    [156] = 188,
    -- 69
    [157] = 189,
    -- 69.5
    [158] = 190,
    -- 70
    [159] = 191,
    -- 70.5
    [160] = 192,
    -- 71
    [161] = 193,
    -- 71.5
    [162] = 194,
    -- 72
    [163] = 195,
    -- 72.5
    [163] = 196,
    -- 73
    [164] = 197,
    -- 73.5
    [165] = 198,
    -- 74
    [166] = 199,
    -- 74.5
    [167] = 200,
    -- 75
    [168] = 201,
    -- 75.5
    [169] = 202,
    -- 76
    [170] = 203,
    -- 76.5
    [171] = 204,
    -- 77
    [172] = 205,
    -- 77.5
    [172] = 206,
    -- 78
    [173] = 207,
    -- 78.5
    [174] = 208,
    -- 79
    [175] = 209,
    -- 79.5
    [176] = 210
    -- 80
}
local array_c_to_f = {
    -13, -12, -11, -10, -9, -9, -8, -7, -6, -5, -4, -3, -2, -2, -1, 0, 1, 2, 3,
    4, 5, 6, 7, 8, 9, 10, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 37, 38,
    39, 40, 41, 42, 43, 44, 45, 46, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 55,
    56, 57, 58, 59, 60, 61, 62, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
    73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 82, 83, 84, 85, 86, 87, 88, 89, 90,
    91, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 100, 101, 102, 103, 104, 105,
    106, 107, 108, 109, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 118,
    119, 120, 121, 122, 123, 124, 125, 126, 127, 127, 128, 129, 130, 131, 132,
    133, 134, 135, 136, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 145,
    146, 147, 148, 149, 150, 151, 152, 153, 154, 154, 155, 156, 157, 158, 159,
    160, 161, 162, 163, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 172,
    173, 174, 175, 176
}

local function convert_f_to_c_encode(f) return array_f_to_c[tonumber(f)] + 30 end

local function convert_c_to_f(c) return array_c_to_f[c - 30 + 1] end

local function check_temp_is_c() return key_maps[2].value[1] == 1 end

local function decode_temp(t)
    -- io_debug('\ndecode_temp:' .. tostring(t) .. '\n')
    if check_temp_is_c() then
        return (t - 80) / 2
    else
        return convert_c_to_f(t)
    end
end

local function encode_temp(t)
    io_debug('\nencode_temp:' .. tostring(t) .. '\n')
    if check_temp_is_c() then
        local t_encode = (t * 2) + 80
        io_debug('\nis c\n')
        return t_encode
    else
        io_debug('\nis f\n')
        return convert_f_to_c_encode(t)
    end
end

local function c_10s_to_f_float(c_10s)
    io_debug('aaa' .. c_10s)
    return convert_c_to_f(tonumber(string.format("%d", c_10s / 5) + 80))
end

local function FGUtilStringSplit(str, split_char)
    -------------------------------------------------------
    -- 参数:待分割的字符串,分割字符
    -- 返回:子串表.(含有空串)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end

    return sub_str_tab;
end

local function string_split(path, pattern)
    return pairs(FGUtilStringSplit(path, pattern))
end

-- nixj8 add done

-- 接口方法，json转二进制，可传入原状态，此方法不能使用local修饰

local function match_path(path, json_table)
    local value = json_table
    for i, k in string_split(path, "/") do
        io_debug(k .. " ")
        value = value[k]
        if value == nil then return 0, value end
    end
    return 1, value
end

local function general_bin_section_with_key_map(key_map)
    local value_section = ""
    local get_all_value = 0
    for i, name in pairs(key_map.value_map) do
        if get_all_value == 1 then break end
        io_debug("    key:[" .. i .. '] ' .. name .. ' : ')
        for k, j in ipairs(key_map.value, ",") do
            io_debug(i .. "<->" .. j)
            if i == j then
                io_debug('* ')
                value_section = value_section .. string.char(i - 1)
                if key_map.size == 1 then get_all_value = 1 end
            else
                io_debug('  ')
            end
        end
        io_debug('\n')
    end
    io_debug('[' .. tostring(#value_section) .. ']' ..
                 string2hexstring(value_section) .. '\n')
    return #value_section, value_section
end

local weekday = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'}
local function general_bin_section_without_key_map(key_map)
    local value_section = ""
    local value_section_len = 0
    local value = key_map.value
    if key_map.value_type == "version" then
        -- do nothing
    elseif key_map.value_type == "uint16_t" or key_map.value_type == "int16_t" or
        key_map.value_type == "int16_t_10" or key_map.value_type ==
        "int16_t_1/10" or key_map.value_type == "uint16_t_100" or
        key_map.value_type == "temp_10s" then
        value_section_len = 2
        value_section = table2string(string2table(
                                         string.format("%04x", value[1])))
        io_debug('uint16_t :' .. value_section .. '\n')
    elseif key_map.value_type == "chars" then
        value_section_len = key_map.size
        for i = 1, value_section_len do
            value_section = value_section .. string.char(value[i])
        end
    elseif key_map.value_type == "uint32_t" or key_map.value_type ==
        "uint32_t_100" then
        value_section_len = 4
        value_section = table2string(string2table(
                                         string.format("%08x", value[1])))
        io_debug('uint32_t : ' .. value_section .. '\n')
    elseif key_map.value_type == "temp" then
        io_debug('temp ' .. table2string(value))
        value_section = string.char(value[1])
        value_section_len = 1
    elseif key_map.value_type == "weekday" then
        io_debug('weekday' .. table2string(value))
        value_section = string.char(value[1])
        value_section_len = 1
    else
        value_section = string.char(tonumber(value[1]))
        io_debug((value_section))
        value_section_len = 1
    end
    io_debug('[' .. tostring(#value_section) .. ']' ..
                 string2hexstring(value_section) .. '\n')
    return value_section_len, value_section
end

local function update_data_with_key_map_by_json(key_map, value)
    local new_value = {}
    local get_all_value = 0
    for i, name in pairs(key_map.value_map) do
        if get_all_value == 1 then break end
        io_debug("    key:[" .. i .. '] ' .. name .. ' : ')
        for k, j in string_split(value, ",") do
            io_debug(name .. "<->" .. j)
            if name == j then
                io_debug('* ')
                table.insert(new_value, i)
                if key_map.size == 1 then get_all_value = 1 end
            else
                io_debug('  ')
            end
        end
        io_debug('\n')
    end
    return new_value
end

local function update_data_without_key_map_by_json(key_map, value)
    local new_value = {}
    if key_map.value_type == "version" then
        io_debug('update version:' .. value)
        -- table.insert(new_value, )
    elseif key_map.value_type == "temp_10s" then

    elseif key_map.value_type == "uint8_t" then
        temp = tonumber(value)
        if key_map.max ~= nil and temp > key_map.max then
            temp = key_map.max
        elseif key_map.min ~= nil and temp < key_map.min then
            temp = key_map.min
        end
        table.insert(new_value, temp)
    elseif key_map.value_type == "uint16_t" then
        table.insert(new_value, tonumber(value))
    elseif key_map.value_type == "uint16_t_100" then
        io_debug('get uint16_t_100\n')
        table.insert(new_value, tonumber(value) * 100)
    elseif key_map.value_type == "int16_t_10" then
        io_debug('get int16_t_10\n')
        value = (tonumber(value) * 10)
        -- if string.sub(value, 1, 1) == '-' then
        if value < 0 then
            io_debug('\n get -\n')
            io_msg(value)
            value = bit.bnot(value)
            table.insert(new_value, bit.bxor(value, 0xFFFF))
        else
            io_debug('\n not get -\n')
            table.insert(new_value, value)
        end
    elseif key_map.value_type == "int16_t_1/10" then
        io_debug('get int16_t_1/10\n')
        value = (tonumber(value) / 10)
        -- if string.sub(value, 1, 1) == '-' then
        if value < 0 then
            io_debug('\n get -\n')
            io_msg(value)
            value = bit.bnot(value)
            table.insert(new_value, bit.bxor(value, 0xFFFF))
        else
            io_debug('\n not get -\n')
            table.insert(new_value, value)
        end
    elseif key_map.value_type == "chars" then
        io_debug('chars :' .. value .. '\n')
        for i = 1, #value do
            table.insert(new_value, string2Int(value, i))
        end
        for i = #value + 1, key_map.size do table.insert(new_value, 0) end
    elseif key_map.value_type == "uint32_t" then
        table.insert(new_value, tonumber(value))
    elseif key_map.value_type == "uint32_t_100" then
        table.insert(new_value, tonumber(value) * 100)
    elseif key_map.value_type == "temp" then
        if value == "invalid" then return new_value end
        local tmp = tonumber(value)
        io_debug('temp ' .. tmp)
        if (tmp < 0) then tmp = 256 + tmp end
        table.insert(new_value, tmp)
    elseif key_map.value_type == "weekday" then
        local weekbit = 0
        for i, day in string_split(value, ',') do
            for j, wday in pairs(weekday) do
                if day == wday then
                    io_msg('pair:' .. tostring(j - 1) .. ' -> ' .. day .. '\n')
                    weekbit = bit.bxor(weekbit, bit.lshift(1, j - 1))
                    break
                end
            end
        end
        table.insert(new_value, weekbit)
    elseif key_map.value_type == "int16_t" then
        io_debug('get int16_t\n')
        value = (tonumber(value))
        -- if string.sub(value, 1, 1) == '-' then
        if value < 0 then
            io_debug('\n get -\n')
            io_msg(value)
            value = bit.bnot(value)
            table.insert(new_value, bit.bxor(value, 0xFFFF))
        else
            io_debug('\n not get -\n')
            table.insert(new_value, value)
        end
    elseif key_map.value_type == "int8_t" then
        io_debug('get int8_t\n')
        value = (tonumber(value))
        -- if string.sub(value, 1, 1) == '-' then
        if value < 0 then
            io_debug('\n get -\n')
            io_msg(value)
            value = bit.bnot(value)
            table.insert(new_value, bit.bxor(value, 0xFF))
        else
            io_debug('\n not get -\n')
            table.insert(new_value, value)
        end
    elseif key_map.value_type == "uint8_t_double" then
        io_debug('get uint8_t_double\n')
        table.insert(new_value, (tonumber(value)) * 2)
    elseif key_map.value_type == "year" then
        year = tonumber(value)
        if (year > 99) then year = 99 end
        table.insert(new_value, year)
    elseif key_map.value_type == "month" then
        io_debug('get month\n')
        month = tonumber(value)
        if (month == 0) then month = 1 end
        if (month > 12) then month = 12 end
        table.insert(new_value, month)
    elseif key_map.value_type == "date" then
        io_debug('get date\n')
        date = tonumber(value)
        if (date == 0) then date = 1 end
        if (date > 31) then date = 31 end
        table.insert(new_value, date)
    elseif key_map.value_type == "hour" then
        hour = tonumber(value)
        if (hour > 23) then hour = 23 end
        table.insert(new_value, hour)
    elseif key_map.value_type == "min" then
        min = tonumber(value)
        if (min > 59) then min = 59 end
        table.insert(new_value, min)
    elseif key_map.value_type == "min_10s" then
        min_10s = tonumber(value)
        if (min_10s > 59) then min_10s = 59 end
        min_10s = min_10s - (min_10s % 10)
        table.insert(new_value, min_10s)
    elseif key_map.value_type == "curve_type" then
        curve_type = tonumber(value)
        if (curve_type == 0) then curve_type = 1 end
        if (curve_type > 9) then curve_type = 9 end
        table.insert(new_value, curve_type)
    elseif key_map.value_type == "eco_curve_type" then
        eco_curve_type = tonumber(value)
        if (eco_curve_type == 0) then eco_curve_type = 1 end
        if (eco_curve_type > 8) then eco_curve_type = 8 end
        table.insert(new_value, eco_curve_type)
    elseif key_map.value_type == 'power_10' then
        io_debug('get power_10\n')
        temp = (tonumber(value)) * 10
        temp = temp - (temp % 5)
        if (temp > 200) then temp = 200 end
        table.insert(new_value, temp)
    else
        table.insert(new_value, tonumber(value))
    end
    return new_value
end

local function print_table(title, new_value)
    io_debug(title)
    for i, v in pairs(new_value) do io_debug(v .. ' ') end
    io_debug('\n')
end

function table.equal(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

local function update_data_by_json_single(key_map, json)
    local value = json
    local get_key_path = 1

    if (key_map.upload ~= nil) then return '' end

    get_key_path, value = match_path(key_map.path, value)
    io_debug("\n")
    if 0 == get_key_path then return '' end

    local new_value = {}
    if key_map.value_map then
        new_value = update_data_with_key_map_by_json(key_map, value)
    else
        new_value = update_data_without_key_map_by_json(key_map, value)
    end

    if #new_value > 0 then
        print_table('    -> new_value:', new_value)
        key_map.value = new_value
        key_map.changed = 1
    end
end

local function update_data_in_normal_type(data, key_map)
    -- for i, v in pairs(key_map.value_map) do
    --    io_msg(v)
    -- end
    -- local ret       = ""
    local new_value = {}
    local first = 0
    if type(data) == "string" then
        -- from binData
        for d in string.gmatch(data, "%w+") do
            -- io_debug('d ' .. d .. ' ')
            -- if first == 1 then
            --    ret = ret .. ','
            -- end
            local data_index = string2Int(d) + 1
            for k, v in pairs(key_map.value_map) do
                if k == data_index then
                    -- ret = ret .. key_map.value_map[data_index]
                    table.insert(new_value, data_index)
                    first = 1
                    break
                end
            end
        end
        -- io_debug('\n')
    end
    return new_value
end

local function get_json_in_normal(data, key_map)
    local ret_json = ""
    -- local new_value = {}
    local first = 0
    if type(data) == "table" then
        -- from key_maps
        for i, d in pairs(data) do
            -- print(d)
            if first == 1 then ret_json = ret_json .. ',' end
            -- io_msg(d)
            ret_json = ret_json .. key_map.value_map[d]
            -- table.insert(new_value, d)
            first = 1
        end
    end
    return ret_json
end

local function update_data_in_spec_type(data, key_map)
    -- local ret       = ""
    -- io_debug('update data in spec_type')
    local new_value = {}
    if type(data) == "string" then
        -- from binData
        if key_map.value_type == nil or key_map.value_type == "uint8_t" or
            key_map.value_type == "uint8_t_10" or key_map.value_type ==
            "uint8_t_1/10" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "temp" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "version" then
            -- io_debug(' update_version:' .. data)
            for i, v in string_split(data, ',') do
                if string2Int(v) ~= 0xFF then
                    table.insert(new_value, string2Int(v))
                end
            end
            if #new_value < 3 then new_value = {} end
        elseif key_map.value_type == 'hex' then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == 'chars' then
            io_debug('**chars:' .. data)
            for i, v in string_split(data, ',') do
                if string2Int(v) ~= 0xFF then
                    table.insert(new_value, string2Int(v))
                end
            end
        elseif key_map.value_type == 'uint16_t' or key_map.value_type ==
            'int16_t_10' or key_map.value_type == 'int16_t' or
            key_map.value_type == 'int16_t_1/10' or key_map.value_type ==
            "temp_10s" or key_map.value_type == "uint16_t_100" or
            key_map.value_type == "uint16_t_1/8" then
            -- io_debug('uint16_t or temp_10s[' .. #data .. ']' .. data .. '\n')
            if key_map.size == 2 then
                local new_data = 0
                local data_table = FGUtilStringSplit(data, ',')
                io_debug(string.format('uint16_t value: %x %x', data_table[1],
                                       data_table[2]))
                new_data = bit.lshift(data_table[1], 8) + data_table[2]
                table.insert(new_value, new_data)
            end
        elseif key_map.value_type == 'uint32_t' or key_map.value_type ==
            'uint32_t_100' then
            local new_data = 0
            local data_table = FGUtilStringSplit(data, ',')
            if #data_table == 4 then
                io_debug(string.format('uint32_t value: %x %x %x %x',
                                       data_table[1], data_table[2],
                                       data_table[3], data_table[4]))
                new_data = bit.lshift(data_table[1], 24) +
                               bit.lshift(data_table[2], 16) +
                               bit.lshift(data_table[3], 8) + data_table[4]
                table.insert(new_value, new_data)
            end
        elseif key_map.value_type == 'weekday' then
            io_debug(data)
            local new_data = 0
            local data_table = FGUtilStringSplit(data, ',')
            print_lua_table(data_table)
            if #data_table == 2 then
                new_data = bit.lshift(data_table[1], 8) + data_table[2]
                table.insert(new_value, new_data)
            else
                table.insert(new_value, string2Int(data))
            end
        elseif key_map.value_type == "int8_t" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "year" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "month" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "date" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "hour" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "min" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "week" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "min_10s" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "uint8_t_double" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "tas" then
            table.insert(new_value, (string2Int(data)) / 2)
        elseif key_map.value_type == "curve_type" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "eco_curve_type" then
            table.insert(new_value, string2Int(data))
        elseif key_map.value_type == "power_10" then
            table.insert(new_value, string2Int(data))
        end
    end

    return new_value
end

local function get_weekday_by_bits(data)
    local ret = ""
    for i = 1, 7 do
        if 0 ~= bit.band(bit.lshift(1, i - 1), data) then
            -- io_debug("get bit " .. tostring(i))
            ret = ret .. weekday[i] .. ","
        end
    end
    return ret
end

local function get_json_in_spec_type(data, key_map)
    local ret = ""
    if type(data) == "table" then
        -- from key_maps
        if key_map.value_type == nil or key_map.value_type == 'uint16_t' or
            key_map.value_type == 'uint32_t' then
            if key_map.value_type == nil and data[1] == 0xFF then
                ret = "invalid"
            elseif key_map.value_type == 'uint16_t' and data[1] == 0xFFFF then
                ret = "invalid"
            elseif key_map.value_type == 'uint32_t' and data[1] == 0xFFFFFFFF then
            else
                ret = tostring((data[1]))
            end
        elseif key_map.value_type == 'temp_10s' then
            if data[1] == 0xFFFF then
                ret = "invalid"
            else
                -- if check_temp_is_c() then
                if bit.rshift(data[1], 15) == 1 then
                    ret = string.format('-%.1f',
                                        (bit.band(data[1], 0x7FFF) / 10))
                else
                    ret = string.format('%.1f', (data[1] / 10))
                end
                -- else
                --    ret = string.format('%.1f', (c_10s_to_f_float(data[1])))
                -- end
            end
        elseif key_map.value_type == 'chars' then
            -- io_debug('****chars:' .. #data)
            -- ret = string.format("%c.%d.%02d", data[1], data[2], data[3])
            for d, v in ipairs(data) do
                ret = ret .. string.format('%c', v)
            end
        elseif key_map.value_type == "hex" then
            ret = string.format("0x%X", data[1])
        elseif key_map.value_type == "version" then
            -- io_debug('    version:' .. data)
            ret = string.format("%d.%d.%02d", data[1], data[2], data[3])
        elseif key_map.value_type == "temp" then
            if data[1] == 0x7F then
                -- ret = "-"
                ret = tostring(data[1])
            else
                tmp = data[1]
                tmp = tmp + 60
                if tmp >= 0x80 then tmp = tmp - 256 end
                ret = tostring(tmp)
            end
        elseif key_map.value_type == "weekday" then
            ret = get_weekday_by_bits(data[1])
        elseif key_map.value_type == 'uint8_t' then
            ret = tostring(data[1])
        elseif key_map.value_type == 'int8_t' then
            if bit.rshift(data[1], 7) == 1 then
                ret = string.format('-%d', bit.band(
                                        bit.bnot(bit.band(data[1], 0x7F)), 0x7F) +
                                        1)
            else
                ret = string.format('%d', data[1])
            end
        elseif key_map.value_type == 'int16_t' then
            if bit.rshift(data[1], 15) == 1 then
                ret = string.format('-%d', bit.band(
                                        bit.bnot(bit.band(data[1], 0x7FFF)),
                                        0x7FFF) + 1)
            else
                ret = string.format('%d', data[1])
            end
        elseif key_map.value_type == 'int16_t_10' then
            if bit.rshift(data[1], 15) == 1 then
                ret = string.format('-%.1f', (bit.band(
                                        bit.bnot(bit.band(data[1], 0x7FFF)),
                                        0x7FFF) + 1) / 10)
            else
                ret = string.format('%.1f', data[1] / 10)
            end
        elseif key_map.value_type == "int16_t_1/10" then
            if bit.rshift(data[1], 15) == 1 then
                ret = string.format('-%d', (bit.band(
                                        bit.bnot(bit.band(data[1], 0x7FFF)),
                                        0x7FFF) + 1) * 10)
            else
                ret = string.format('%d', data[1] * 10)
            end
        elseif key_map.value_type == 'year' then
            ret = tostring(data[1])
        elseif key_map.value_type == 'month' then
            ret = tostring(data[1])
        elseif key_map.value_type == 'date' then
            ret = tostring(data[1])
        elseif key_map.value_type == 'hour' then
            ret = tostring(data[1])
        elseif key_map.value_type == 'min' then
            ret = tostring(data[1])
        elseif key_map.value_type == 'week' then
            ret = tostring(data[1])
        elseif key_map.value_type == 'uint8_t_double' then
            ret = tostring(data[1] / 2)
        elseif key_map.value_type == 'uint16_t_100' then
            ret = tostring(data[1] / 100)
        elseif key_map.value_type == 'uint32_t_100' then
            ret = tostring(data[1] / 100)
        elseif key_map.value_type == 'uint16_t_1/8' then
            ret = tostring(data[1] * 8)
        elseif key_map.value_type == 'uint8_t_1/10' then
            ret = tostring(data[1] * 10)
        elseif key_map.value_type == 'uint8_t_10' then
            ret = tostring(data[1] / 10)
        elseif key_map.value_type == 'power_10' then
            ret = tostring(data[1] / 10)
        else
            ret = tostring((data[1]))
        end
    end

    return ret
end

local function update_data_by_bin(key_map, data)
    local new_value = {}
    if key_map.upload ~= nil then key_map = key_maps[key_map.upload + 1] end
    if key_map.value_map ~= nil then
        new_value = update_data_in_normal_type(data, key_map)
    else
        new_value = update_data_in_spec_type(data, key_map)
    end
    if #new_value > 0 then
        key_map.value = new_value
        key_map.changed = 1
    end
end

local function get_json_by_keymap(key_map, data)
    -- io_msg('key_map path:' .. key_map.path)
    local ret_json = ""
    -- local key_map = key_maps[idx + 1]
    local new_value = {}
    if key_map.value_map ~= nil then
        ret_json = get_json_in_normal(data, key_map)
    else
        ret_json = get_json_in_spec_type(data, key_map)
    end
    -- io_debug('    ret_json:' .. ret_json .. '\n')
    return ret_json
end

local function parse_section(section)
    io_msg('    ' .. string2hexstring(table2string(section)) .. ": ")
    io_debug('\n')
    -- for j, val2 in pairs(section) do
    --    io_debug(j .. ':' .. val2 .. ', ')
    -- end

    local idx = bit.lshift(section[1], 8) + section[2]
    local size = section[3]
    local data = table.concat(section, ',', 4)
    io_debug('idx:' .. idx .. ',')
    io_debug('size:' .. size .. ',')
    io_debug('data:' .. data .. '  ')
    if size == "0" or size == 0 then return nil end

    local key_map = nil

    for i, km in pairs(key_maps) do
        if tonumber(idx) == km.idx then
            io_debug('match : ' .. km.path .. '  ')
            -- io_msg('match :' .. km.path .. '\n')
            key_map = km
            break
        end
    end

    if key_map == nil then
        io_msg('can\'t match key_map idx, return')
        return nil
    end

    update_data_by_bin(key_map, data)
end

local function parse_data_bin_branch(idx_start, idx_end, len, binTable, idx)
    io_debug(string.format('  branch: %d -> %d [%d]\n', idx_start, idx_end, len))
    local pos = idx
    -- io_msg(pos)
    for i = idx_start, idx_end do
        local key_map = key_maps[i + 1]
        io_debug(string.format('    %d [%d] ', i, key_map.size))
        update_data_by_bin(key_map, table.concat(binTable, ',', pos,
                                                 pos + key_map.size - 1))
        for j = 1, key_map.size do
            io_debug(string.format(' %02x', tonumber(binTable[pos])))
            pos = pos + 1
        end
        key_map.changed = 1
        io_debug(string.format('\n'))
    end
end

local function parse_data_bin(binData)
    io_msg('\n')
    local conf_list = {}
    local section = {}
    io_debug(string.format('get bin:%d\n', #binData))
    io_msg(binData .. '\n')
    local binTable = string2table(binData)

    for i, value in pairs(binTable) do
        if binTable[i + 1] == 0xFE and #section == 0 then
            -- io_msg(i)
            local idx_start = bit.lshift(binTable[i + 2], 8) + binTable[i + 3]
            local idx_end = bit.lshift(binTable[i + 4], 8) + binTable[i + 5]
            local len = bit.lshift(binTable[i + 6], 8) + binTable[i + 7]
            parse_data_bin_branch(idx_start, idx_end, len, binTable, i + 8)
            break
        elseif binTable[i] == 0xFF and binTable[i + 1] == 0xFF and
            binTable[i + 5] == 0xFF then
            break
        elseif value == 0xFF and #section > 0 and section[3] + 3 == #section then
            -- print_lua_table(section)
            table.insert(conf_list, section)
            section = {}
        else
            table.insert(section, value)
        end
    end
    io_debug('\n')

    io_msg('all sections[' .. #conf_list .. "]\n")

    -- local json_data = {}
    for i, value in pairs(conf_list) do
        -- parse_section(value, json_data)
        parse_section(value)
    end

    -- return json_data
end

local function parse_data_bin_respond(binData)

    local binTable = string2table(binData)
    local table_size = #binTable
    if table_size < 5 then return end

    local begin = 1
    for i = 1, table_size, 1 do
        if table_size - i < 5 then break end
        if i == begin then
            local idx_start = bit.lshift(binTable[begin], 8) +
                                  binTable[begin + 1]
            local idx_end = idx_start
            parse_data_bin_branch(idx_start, idx_end, 1, binTable, begin + 3)
            begin = begin + binTable[begin + 2] + 4
        end
    end
end

local function key_map_convert_to_json(json_data, key_map)
    local idx = key_map.idx
    local size = key_map.size
    local data = key_map.value

    -- io_debug('  ' .. 'idx(' .. type(idx) .. '):' .. idx .. ',')
    -- io_debug('size(' .. type(size) .. '):' .. size .. ',')
    -- if type(data) == "string" then
    --    io_debug('data(' .. type(data) .. '):' .. data .. ',')
    -- else
    --    if type(data) == "table" then
    --        io_debug('data(' .. type(data) .. '):' .. int2String(#data) .. ',')
    --    else
    --        io_debug('data(' .. type(data) .. '):' .. ',')
    --    end
    -- end

    -- local key_map = key_maps[idx + 1]
    local json_data_p = json_data
    local last_value = ""
    for i, value in string_split(key_map.path, "/") do
        -- io_debug(' ' .. value .. " ")
        if last_value == "" then
            last_value = value
        else
            if json_data_p[last_value] ~= nil then
                json_data_p = json_data_p[last_value]
            else
                json_data_p[last_value] = {}
                json_data_p = json_data_p[last_value]
            end
            last_value = value
        end
    end
    -- io_debug("\n")
    json_data_p[last_value] = get_json_by_keymap(key_map, data)

    return json_data
end

local function get_all_json_table(key_maps)
    -- io_msg('\n')
    local json_data = {}
    local json_data2 = {}
    for idx, key_map in pairs(key_maps) do
        -- io_debug('    ' .. idx)
        if key_map.changed == 1 then
            key_map_convert_to_json(json_data, key_map)
            json_data2[key_map.path] = key_map.from
            key_map.changed = 0
        end
    end

    return json_data, json_data2
end

local function general_bin_section_single(key_map)
    local binData = ""
    local value_section = ""
    local value_section_len = 0
    binData = binData .. string.char(bit.rshift(key_map.idx, 8)) ..
                  string.char(bit.band(key_map.idx, 0x00FF))
    io_debug("\n")
    local new_value = {}
    if key_map.value_map then
        value_section_len, value_section =
            general_bin_section_with_key_map(key_map)
    else
        value_section_len, value_section =
            general_bin_section_without_key_map(key_map)
    end

    binData = binData .. string.char(value_section_len) .. value_section ..
                  string.char(0xFF)

    return binData
end

local function general_all_bin()
    -- print_lua_table(json)
    local binData = ""
    for idx in pairs(key_maps) do
        io_debug(idx .. ": [")
        binData = binData .. general_bin_section_single(key_maps[idx])
    end

    return binData
end

local function general_all_changed_bin()
    -- print_lua_table(json)
    local binData = ""
    for idx in pairs(key_maps) do
        io_debug(idx .. ": [")
        if key_maps[idx].changed == 1 then
            key_maps[idx].changed = 0
            binData = binData .. general_bin_section_single(key_maps[idx])
        end
    end

    return binData
end

local function update_data_by_json(json)
    -- print_lua_table(json)
    io_msg('\n')

    local binData = ""
    for idx in pairs(key_maps) do
        if key_maps[idx].writable == true then
            io_debug(idx .. ": [")
            -- local value = json[key_maps[idx].path][key_maps[idx].key]
            local json_temp = json
            update_data_by_json_single(key_maps[idx], json_temp)
            -- binData         = binData .. update_data_by_json_single(key_maps[idx], json_temp)
        end
    end

    return binData
end

local function get_query_cmd(json)
    io_debug('get query\n')
    local query_cmd = 0xFF
    local query_index1 = 0xFF
    local query_index2 = 0xFF
    local query_index3 = 0xFF
    local query_type = json["query_type"]

    if query_type ~= nil then
        local query = string2table(string.format("%02x", tonumber(query_type)))
        local len = #query
        if (len >= 1) then
            query_index1 = query[1]
            query_index2 = query[1]
            query_index3 = query[1]
        end
        if (len >= 2) then query_index2 = query[2] end
        if (len >= 3) then query_index3 = query[3] end
    end
    local binData = string.char(query_cmd) .. string.char(query_cmd) ..
                        string.char(query_index1) .. string.char(query_index2) ..
                        string.char(query_index3) .. string.char(query_cmd)
    return string2hexstring(binData)
end

function jsonToData(jsonCmdStr)
    io_msg('\n')
    if (#jsonCmdStr == 0) then
        io_err("no json")
        return nil
    end

    -- for wlc
    --     get     ------      return
    --     query                status
    --     params               status

    local json = decodeJsonToTable(jsonCmdStr)

    -- print_lua_table(json)

    local filed = 'result'
    if json["query"] ~= nil then
        return get_query_cmd(json["query"])
    elseif json['control'] ~= nil then
        filed = 'control'
    elseif json['params'] ~= nil then
        filed = 'params'
    elseif json['result'] ~= nil then
        filed = 'result'
    elseif json['status'] ~= nil then
        filed = 'status'
    end

    io_msg(filed .. '\n')

    update_data_by_json(json[filed])
    local binData = general_all_changed_bin()
    -- io_msg(':get bin ' .. string2hexstring(binData) .. '\n')
    return string2hexstring(binData)
end

local function show_key_maps_value(key_maps)
    io_msg('\n  show_key_maps_value \n')
    -- io_msg('\n')
    for idx, key_map in pairs(key_maps) do
        -- io_debug('    ' .. tostring(idx) .. ' [' .. key_map.size .. ']: ')
        io_msg(string.format("  %2d [%d]:", tostring(key_map.idx), key_map.size))
        io_debug(key_map.path .. '   { ')
        for i, v in pairs(key_map.value) do io_debug(v .. ' ') end
        io_debug('} : ')
        io_debug(get_json_by_keymap(key_map, key_map.value))
        -- for idx, v in pairs(key_map.value) do
        --    io_debug(tostring(v))
        --    io_debug(get_json_by_keymap(key_map, v))
        --    if key_map.value_map ~= nil then
        --        io_debug(' [' .. (key_map.value_map[v] .. ']' .. ', '))
        --    elseif key_map.value_type == 'temp' then
        --        io_debug(' -> ' .. tostring(decode_temp(v)) .. ', ')
        --    end
        -- end
        io_debug('\n')
    end
end

local function get_table_len(data)
    -- body
    local cnt = 0
    for i in pairs(data) do cnt = i end
    return cnt
end

local function check_lua_header(binData)
    local data = string2table(binData)
    local len = get_table_len(data)
    if len < 10 then
        io_err('format error\n')
        return 0
    end
    io_msg(string.format('check_lua_header: %X %X %X %X\n', data[1], data[2],
                         data[3], data[10]))
    io_msg(string.format('sum: %X\n', data[len]))
    io_msg(string.format('sum: %X\n', makeSum(data, 2, len - 1)))
    if data[1] ~= BYTE_PROTOCOL_HEAD or data[3] ~= 0xC3 -- or data[len-1] ~= 0xFF
    -- or data[10] ~= BYTE_CONTROL_REQUEST
    or data[len] ~= makeSum(data, 2, len - 1) then
        io_err('format error\n')
        return 0
    end
    return 1
end

local function check_hmiversion(hmiversion, dest)
    local hmiversion_major, hmiversion_minor, hmiversion_patch = string.match(
                                                                     hmiversion,
                                                                     "(%d+).(%d+).(%d+)")
    local dest_major, dest_minor, dest_patch = string.match(dest,
                                                            "(%d+).(%d+).(%d+)")
    if hmiversion_major >= dest_major and hmiversion_minor >= dest_minor and
        hmiversion_patch >= dest_patch then return true end
    return false
end

local function patch_hmiversion(json_data, cmd_type)

    local hmiVersionNum = json_data['status']['hmiVersionNum']
    local _hmiVersionNum_patch = json_data['status']['_hmiVersionNum_patch']
    local _hmiVersionNum_patch2 = json_data['status']['_hmiVersionNum_patch2']

    if _hmiVersionNum_patch ~= nil then
        if hmiVersionNum ~= nil then
            local v1, v2, v3 = string.match(hmiVersionNum, "(%d+).(%d+).(%d+)")
            if _hmiVersionNum_patch2 ~= nil then
                json_data['status']['hmiVersionNum'] = string.format(
                                                           "%d.%d.%d.%02d|[%d]",
                                                           v1,
                                                           _hmiVersionNum_patch,
                                                           v2, v3,
                                                           _hmiVersionNum_patch2)
            else
                json_data['status']['hmiVersionNum'] = string.format(
                                                           "%d.%d.%d.%02d", v1,
                                                           _hmiVersionNum_patch,
                                                           v2, v3)
            end
        end
    end
end

-- 接口方法，二进制转json，此方法不能使用local修饰
function dataToJson(jsonStr)
    io_msg('\n')
    if (not jsonStr) then
        io_err('no json str')
        return ''
    end

    local json_data = {}
    json_data['status'] = {}
    json_data['from'] = {}
    json_data['status']['version'] = string.format("%d.%d.%d", lua_version[1],
                                                   lua_version[2],
                                                   lua_version[3])

    local json = decodeJsonToTable(jsonStr)

    -- 根据设备子类型来处理协议差异
    -- local deviceinfo = json["deviceinfo"]
    -- local deviceSubType = deviceinfo["deviceSubType"]
    -- if (deviceSubType == 1) then
    -- end

    -- 解析十六进制数据
    local binData = json["msg"]["data"]

    local cmd_type = {0xFF, 0xFF}
    local dataLen = 0
    local bodyLen = 1

    if check_lua_header(binData) == 1 then
        local data = string2table(binData)
        cmd_type[1] = data[10]
        cmd_type[2] = data[11]
        -- 查询/上报
        if cmd_type[1] == 0x03 or cmd_type[1] == 0x04 then
            bodyLen = bit.lshift(data[17], 8) + data[18]
            dataLen = #data - 20
        end
        binData = string.sub(binData, 21)
    end

    -- 处理控制应答
    if cmd_type[1] == 0x02 then
        parse_data_bin_respond(binData)
        -- 查询/上报
    elseif cmd_type[1] == 0x03 or cmd_type[1] == 0x04 then
        if dataLen ~= bodyLen then return encodeTableToJson(json_data) end
        parse_data_bin(binData)
        -- 其他
    else
        return encodeTableToJson(json_data)
    end

    -- show_key_maps_value(key_maps)

    json_data['status'], json_data['from'] = get_all_json_table(key_maps)
    json_data['status']['version'] = string.format("%d.%d.%d", lua_version[1],
                                                   lua_version[2],
                                                   lua_version[3])

    if json_data['status']['error_code_str'] ~= nil and
        json_data['status']['error_code_str'] ~= '/' then
        json_data['status']['error_code'] =
            json_data['status']['error_code_str']
    end

    patch_hmiversion(json_data, cmd_type)

    if cmd_type[1] ~= 0xFF then
        json_data['cmd_type'] = string.format("%d", cmd_type[1])
        json_data['sub_type'] = string.format("0x%X", cmd_type[2])
    end

    -- 处理控制应答
    if cmd_type[1] == 0x04 then
        json_data['msg_up_type'] = string.format("%X", cmd_type[2])
    end

    return encodeTableToJson(json_data)
end
