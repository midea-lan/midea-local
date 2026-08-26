local bit = require "bit"
local JSON = require "cjson"
local KEY_VERSION = "version"
local VALUE_VERSION = 69
local VALUE_ON = "on"
local VALUE_OFF = "off"
local BYTE_DEVICE_TYPE = 0xED
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_WASH_ON = 0x80
local BYTE_WASH_OFF = 0x7F
local dataType = 0
local byteCount = 2
local function decodeJsonToTable(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
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
    if bodyLength == 0 then return nil end
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
    end
    msgBytes[msgLength - 1] = makeSum(msgBytes, 1, msgLength - 2)
    return msgBytes
end
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end
local function string2hexstring(str)
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
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
local function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then JSON = require "cjson" end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
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
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
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
local function setbytes(item1, item2, item3, item4, item5, bytes)
    local len = #bytes
    bytes[len + 1] = item1
    bytes[len + 2] = item2
    bytes[len + 3] = item3
    bytes[len + 4] = item4
    bytes[len + 5] = item5
    bytes[2] = bytes[2] + 1
end
local function set_tembytes(item1, item2, item3, item4, item5, bytes)
    local len = #bytes
    bytes[len + 1] = item1
    bytes[len + 2] = item2
    if item3 >= 0 then
        bytes[len + 3] = item3
    else
        bytes[len + 3] = 255 + item3 + 1
    end
    bytes[len + 4] = item4
    bytes[len + 5] = item5
    bytes[2] = bytes[2] + 1
end
local function set_calibration(item1, item2, item3, item4, item5, bytes)
    local len = #bytes
    bytes[len + 1] = item1
    bytes[len + 2] = item2
    bytes[len + 3] = item3
    if item4 >= 0 then
        bytes[len + 4] = item4
    else
        bytes[len + 4] = 255 + item4 + 1
    end
    bytes[len + 5] = item5
    bytes[2] = bytes[2] + 1
end
local function statusJudge(streams, bytes)
    local leng = bit.rshift(bytes[byteCount + 2], 4) + 2
    local attr = bit.lshift(bytes[byteCount + 2] % 16, 8) + bytes[byteCount + 1]
    if attr == 0x000 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['filter'] = VALUE_ON
        else
            streams['filter'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['wash_enable'] = VALUE_ON
        else
            streams['wash_enable'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x04) == 0x04) then
            streams['wash'] = VALUE_ON
        else
            streams['wash'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x08) == 0x08) then
            streams['standby_status'] = 1
        else
            streams['standby_status'] = 0
        end
        if (bit.band(bytes[byteCount + 3], 0x10) == 0x10) then
            streams['bubble'] = VALUE_ON
        else
            streams['bubble'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x20) == 0x20) then
            streams['bubble_status'] = VALUE_ON
        else
            streams['bubble_status'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x40) == 0x40) then
            streams['save_mode'] = VALUE_ON
        else
            streams['save_mode'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x80) == 0x80) then
            streams['cloud_wash'] = VALUE_ON
        else
            streams['cloud_wash'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x01) == 0x01) then
            streams['cool'] = VALUE_ON
        else
            streams['cool'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x02) == 0x02) then
            streams['heat'] = VALUE_ON
        else
            streams['heat'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x04) == 0x04) then
            streams['uv_led'] = VALUE_ON
        else
            streams['uv_led'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x08) == 0x08) then
            streams['germicidal'] = VALUE_ON
        else
            streams['germicidal'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x10) == 0x10) then
            streams['set_germicidal_countdown'] = VALUE_ON
        else
            streams['set_germicidal_countdown'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x20) == 0x20) then
            streams['heat_status'] = VALUE_ON
        else
            streams['heat_status'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x40) == 0x40) then
            streams['set_result'] = VALUE_ON
        else
            streams['set_result'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x80) == 0x80) then
            streams['gesture'] = VALUE_ON
        else
            streams['gesture'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x01) == 0x01) then
            streams['lock'] = VALUE_ON
        else
            streams['lock'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x02) == 0x02) then
            streams['out_water'] = VALUE_ON
        else
            streams['out_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x04) == 0x04) then
            streams['lack_water'] = VALUE_ON
        else
            streams['lack_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x08) == 0x08) then
            streams['full'] = VALUE_ON
        else
            streams['full'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x10) == 0x10) then
            streams['waste_water'] = VALUE_ON
        else
            streams['waste_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x20) == 0x20) then
            streams['drainage'] = VALUE_ON
        else
            streams['drainage'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x40) == 0x40) then
            streams['out_hot_water'] = VALUE_ON
        else
            streams['out_hot_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x80) == 0x80) then
            streams['infrared_outlet'] = VALUE_ON
        else
            streams['infrared_outlet'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x01) == 0x01) then
            streams['power'] = VALUE_ON
        else
            streams['power'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x02) == 0x02) then
            streams['sleep'] = VALUE_ON
        else
            streams['sleep'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x04) == 0x04) then
            streams['vacation'] = VALUE_ON
        else
            streams['vacation'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x08) == 0x08) then
            streams['season'] = 1
        else
            streams['season'] = 0
        end
        if (bit.band(bytes[byteCount + 6], 0x10) == 0x10) then
            streams['domestic_outlet'] = VALUE_ON
        else
            streams['domestic_outlet'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x20) == 0x20) then
            streams['backflow'] = VALUE_ON
        else
            streams['backflow'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x40) == 0x40) then
            streams['mixed_water'] = VALUE_ON
        else
            streams['mixed_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x80) == 0x80) then
            streams['filter_self_cleaning'] = VALUE_ON
        else
            streams['filter_self_cleaning'] = VALUE_OFF
        end
    elseif attr == 0x001 then
        streams['error'] = bytes[byteCount + 3]
    elseif attr == 0x002 then
        streams['v_version'] = bytes[byteCount + 3]
        streams['e_version'] = bytes[byteCount + 4]
        streams['k_version'] = bytes[byteCount + 5]
        streams['w_version'] = bytes[byteCount + 6]
    elseif attr == 0x003 then
        streams['current_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x004 then
        streams['coffee_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x005 then
        streams['honey_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x006 then
        streams['milk_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x007 then
        streams['red_tea_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x008 then
        streams['black_tea_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x009 then
        streams['green_tea_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x00A then
        streams['yellow_tea_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x00B then
        streams['tea_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x00C then
        streams['medlar_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x00D then
        streams['cool_target_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x00E then
        streams['heat_time'] = bytes[byteCount + 3]
    elseif attr == 0x00F then
        streams['heat_tea'] = bytes[byteCount + 3]
    elseif attr == 0x010 then
        streams['life_1'] = bytes[byteCount + 3]
        streams['life_2'] = bytes[byteCount + 4]
        streams['life_3'] = bytes[byteCount + 5]
        streams['life_4'] = bytes[byteCount + 6]
        streams['life_5'] = bytes[byteCount + 7]
    elseif attr == 0x011 then
        streams['water_consumption'] = bit.lshift(bytes[byteCount + 6], 24) +
                                           bit.lshift(bytes[byteCount + 5], 16) +
                                           bit.lshift(bytes[byteCount + 4], 8) +
                                           bytes[byteCount + 3]
        streams['water_consumption_ml'] = bytes[byteCount + 5]
    elseif attr == 0x012 then
        streams['hot_water_consumption'] =
            bit.lshift(bytes[byteCount + 6], 24) +
                bit.lshift(bytes[byteCount + 5], 16) +
                bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
        streams['hot_water_consumption_ml'] = bytes[byteCount + 5]
    elseif attr == 0x013 then
        streams['in_tds'] = bit.lshift(bytes[byteCount + 4], 8) +
                                bytes[byteCount + 3]
        streams['out_tds'] = bit.lshift(bytes[byteCount + 6], 8) +
                                 bytes[byteCount + 5]
    elseif attr == 0x014 then
        streams['countdown_filter_1'] = bytes[byteCount + 3]
        streams['countdown_filter_2'] = bytes[byteCount + 4]
        streams['countdown_filter_3'] = bytes[byteCount + 5]
        streams['countdown_filter_4'] = bytes[byteCount + 6]
        streams['countdown_filter_5'] = bytes[byteCount + 7]
    elseif attr == 0x015 then
        streams['air_filter'] = bytes[byteCount + 3]
    elseif attr == 0x016 then
        streams['maxlife_1'] = bytes[byteCount + 3]
        streams['maxlife_2'] = bytes[byteCount + 4]
        streams['maxlife_3'] = bytes[byteCount + 5]
        streams['maxlife_4'] = bytes[byteCount + 6]
        streams['maxlife_5'] = bytes[byteCount + 7]
    elseif attr == 0x017 then
        streams['lifetype_1'] = bytes[byteCount + 3]
        streams['lifetype_2'] = bytes[byteCount + 4]
        streams['lifetype_3'] = bytes[byteCount + 5]
        streams['lifetype_4'] = bytes[byteCount + 6]
        streams['lifetype_5'] = bytes[byteCount + 7]
    elseif attr == 0x020 then
        streams['water_kind'] = bytes[byteCount + 3]
        streams['heat_start'] = bytes[byteCount + 4]
        streams['ice_gall_status'] = bytes[byteCount + 5]
    elseif attr == 0x021 then
        streams['custom_temperature_1'] = bytes[byteCount + 3]
        streams['custom_temperature_2'] = bytes[byteCount + 4]
        streams['custom_temperature_3'] = bytes[byteCount + 5]
        streams['custom_temperature_4'] = bytes[byteCount + 6]
        streams['custom_temperature_5'] = bytes[byteCount + 7]
    elseif attr == 0x022 then
        streams['custom_temperature_6'] = bytes[byteCount + 3]
        streams['custom_temperature_7'] = bytes[byteCount + 4]
        streams['custom_temperature_8'] = bytes[byteCount + 5]
        streams['custom_temperature_9'] = bytes[byteCount + 6]
        streams['custom_temperature_10'] = bytes[byteCount + 7]
    elseif attr == 0x023 then
        streams['quantify_1'] = bytes[byteCount + 3]
        streams['quantify_2'] = bytes[byteCount + 4]
        streams['quantify_3'] = bytes[byteCount + 5]
        streams['quantify_4'] = bytes[byteCount + 6]
        streams['quantify_5'] = bytes[byteCount + 7]
        streams['cur_quantify'] = bytes[byteCount + 8]
    elseif attr == 0x024 then
        streams['quantify_sec'] = bit.lshift(bytes[byteCount + 4], 8) +
                                      bytes[byteCount + 3]
        streams['cur_quantify_sec'] = bit.lshift(bytes[byteCount + 6], 8) +
                                          bytes[byteCount + 5]
    elseif attr == 0x025 then
        if bytes[byteCount + 3] == 0x01 then
            streams['keep_warm'] = VALUE_ON
            streams['keep_warm_2'] = VALUE_OFF
        elseif bytes[byteCount + 3] == 0x02 then
            streams['keep_warm'] = VALUE_OFF
            streams['keep_warm_2'] = VALUE_ON
        else
            streams['keep_warm'] = VALUE_OFF
            streams['keep_warm_2'] = VALUE_OFF
        end
        streams['keep_warm_time'] = bytes[byteCount + 4]
        streams['warm_left_time'] = bit.lshift(bytes[byteCount + 6], 8) +
                                        bytes[byteCount + 5]
    elseif attr == 0x026 then
        streams['special_status'] = bytes[byteCount + 3]
        streams['germicidal_countdown'] = bytes[byteCount + 4]
        streams['set_germicidal_countdown_days'] = bytes[byteCount + 5]
        streams['germicidal_left_time'] = bytes[byteCount + 6]
    elseif attr == 0x027 then
        streams['rfid_quantify'] = bit.lshift(bytes[byteCount + 4], 8) +
                                       bytes[byteCount + 3]
    elseif attr == 0x028 then
        streams['rfid_temp'] = bytes[byteCount + 3]
    elseif attr == 0x029 then
        streams['rfid_kind'] = bytes[byteCount + 3]
    elseif attr == 0x030 then
        streams['rfid_id6'] = bytes[byteCount + 3]
        streams['rfid_id5'] = bytes[byteCount + 4]
        streams['rfid_id4'] = bytes[byteCount + 5]
        streams['rfid_id3'] = bytes[byteCount + 6]
        streams['rfid_id2'] = bytes[byteCount + 7]
        streams['rfid_id1'] = bytes[byteCount + 8]
        streams['rfid_id0'] = bytes[byteCount + 9]
    elseif attr == 0x031 then
        streams['rfid_role'] = bytes[byteCount + 3]
    elseif attr == 0x032 then
        streams['set_tea_washing'] = bytes[byteCount + 3]
    elseif attr == 0x033 then
        streams['brew_status'] = bytes[byteCount + 3]
    elseif attr == 0x034 then
        streams['tea_washing_time'] = bytes[byteCount + 3]
    elseif attr == 0x035 then
        streams['tea_washing_quantify'] = bytes[byteCount + 3]
    elseif attr == 0x036 then
        streams['screenout_time'] = bit.lshift(bytes[byteCount + 4], 8) +
                                        bytes[byteCount + 3]
    elseif attr == 0x037 then
        streams['effluent_ml'] = bit.lshift(bytes[byteCount + 4], 8) +
                                     bytes[byteCount + 3]
        streams['outlet_stop'] = bytes[byteCount + 5]
    elseif attr == 0x038 then
        streams['quantify_21'] = bit.lshift(bytes[byteCount + 4], 8) +
                                     bytes[byteCount + 3]
        streams['quantify_22'] = bit.lshift(bytes[byteCount + 6], 8) +
                                     bytes[byteCount + 5]
        streams['quantify_23'] = bit.lshift(bytes[byteCount + 8], 8) +
                                     bytes[byteCount + 7]
        streams['quantify_24'] = bit.lshift(bytes[byteCount + 10], 8) +
                                     bytes[byteCount + 9]
        streams['quantify_25'] = bit.lshift(bytes[byteCount + 12], 8) +
                                     bytes[byteCount + 11]
    elseif attr == 0x039 then
        streams['quantify_tds_1'] = bytes[byteCount + 3]
        streams['quantify_tds_2'] = bytes[byteCount + 4]
        streams['quantify_tds_3'] = bytes[byteCount + 5]
        streams['quantify_tds_4'] = bytes[byteCount + 6]
        streams['quantify_tds_5'] = bytes[byteCount + 7]
    elseif attr == 0x03A then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['plateau_power'] = VALUE_ON
        else
            streams['plateau_power'] = VALUE_OFF
        end
        streams['plateau_boiling_point'] = bytes[byteCount + 4]
        streams['plateau_pressure'] = bit.lshift(bytes[byteCount + 6], 8) +
                                          bytes[byteCount + 5]
    elseif attr == 0x03B then
        streams['hot_pot_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x03C then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['antifreeze'] = VALUE_ON
        else
            streams['antifreeze'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x04) == 0x04) then
            streams['high_float_type'] = VALUE_OFF
        else
            streams['high_float_type'] = VALUE_ON
        end
        if (bit.band(bytes[byteCount + 3], 0x40) == 0x40) then
            streams['no_obsolete_water'] = VALUE_ON
        else
            streams['no_obsolete_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x80) == 0x80) then
            streams['voice_power'] = VALUE_ON
        else
            streams['voice_power'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x01) == 0x01) then
            streams['leak_water_protect'] = VALUE_ON
        else
            streams['leak_water_protect'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x02) == 0x02) then
            streams['buzzer'] = VALUE_ON
        else
            streams['buzzer'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x08) == 0x08) then
            streams['smart_no_obsolete_water'] = VALUE_ON
        else
            streams['smart_no_obsolete_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x20) == 0x20) then
            streams['leaking_protect_status'] = VALUE_ON
        else
            streams['leaking_protect_status'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x40) == 0x40) then
            streams['gesture_disable_high_temperature'] = VALUE_ON
        else
            streams['gesture_disable_high_temperature'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 4], 0x80) == 0x80) then
            streams['filter_wash'] = VALUE_ON
        else
            streams['filter_wash'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x20) == 0x20) then
            streams['extreme_mode'] = VALUE_ON
        else
            streams['extreme_mode'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x40) == 0x40) then
            streams['installed_heating_module'] = VALUE_ON
        else
            streams['installed_heating_module'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x80) == 0x80) then
            streams['auto_fill_water'] = VALUE_ON
        else
            streams['auto_fill_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x01) == 0x01) then
            streams['autoclean_ctrl'] = VALUE_ON
        else
            streams['autoclean_ctrl'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x02) == 0x02) then
            streams['autoclean'] = VALUE_ON
        else
            streams['autoclean'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x04) == 0x04) then
            streams['autoclean_remind'] = VALUE_ON
        else
            streams['autoclean_remind'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x08) == 0x08) then
            streams['quantify_calibration'] = VALUE_ON
        else
            streams['quantify_calibration'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x10) == 0x10) then
            streams['voice_conversation_power'] = VALUE_ON
        else
            streams['voice_conversation_power'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x20) == 0x20) then
            streams['reheating'] = VALUE_ON
        else
            streams['reheating'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x40) == 0x40) then
            streams['stew_heat_status'] = VALUE_ON
        else
            streams['stew_heat_status'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 6], 0x80) == 0x80) then
            streams['auto_continue'] = VALUE_ON
        else
            streams['auto_continue'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 7], 0x01) == 0x01) then
            streams['ice'] = VALUE_ON
        else
            streams['ice'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 7], 0x02) == 0x02) then
            streams['out_ice'] = VALUE_ON
        else
            streams['out_ice'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 7], 0x20) == 0x20) then
            streams['ice_status'] = VALUE_ON
        else
            streams['ice_status'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 7], 0x40) == 0x40) then
            streams['hydration_status'] = VALUE_ON
        else
            streams['hydration_status'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 7], 0x80) == 0x80) then
            streams['antifreeze_status'] = VALUE_ON
        else
            streams['antifreeze_status'] = VALUE_OFF
        end
    elseif attr == 0x03E then
        streams['leaking_protect_time'] = bytes[byteCount + 3]
    elseif attr == 0x03F then
        streams['first_custom_out_water_mode'] = bytes[byteCount + 3]
        streams['first_custom_out_water_ml'] =
            bit.lshift(bytes[byteCount + 5], 8) + bytes[byteCount + 4]
    elseif attr == 0x040 then
        streams['voice_volume'] = bytes[byteCount + 3]
    elseif attr == 0x041 then
        streams['voice_type'] = bytes[byteCount + 3]
    elseif attr == 0x042 then
        streams['autoclean_remind_cycle'] = bytes[byteCount + 3]
        streams['autoclean_remind_cycle_remainder'] = bytes[byteCount + 4]
    elseif attr == 0x043 then
        streams['autoclean_time'] = bytes[byteCount + 3]
        streams['autoclean_time_remainder'] = bytes[byteCount + 4]
    elseif attr == 0x044 then
        streams['quantify_6'] = bytes[byteCount + 3]
        streams['quantify_7'] = bytes[byteCount + 4]
        streams['quantify_8'] = bytes[byteCount + 5]
        streams['quantify_9'] = bytes[byteCount + 6]
        streams['quantify_10'] = bytes[byteCount + 7]
    elseif attr == 0x045 then
        streams['filter_wash_time'] = bytes[byteCount + 3]
        streams['filter_wash_num'] = bytes[byteCount + 4]
    elseif attr == 0x046 then
        if (tonumber(bytes[byteCount + 3]) > 127) then
            streams['quantify_calibration_percent'] = bytes[byteCount + 3] - 256
        else
            streams['quantify_calibration_percent'] = bytes[byteCount + 3]
        end
    elseif attr == 0x047 then
        streams['gesture_mode'] = bytes[byteCount + 3]
    elseif attr == 0x048 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['human_sensing_switch'] = VALUE_ON
        else
            streams['human_sensing_switch'] = VALUE_OFF
        end
        streams['human_sensing_distance'] =
            bit.lshift(bytes[byteCount + 5], 8) + bytes[byteCount + 4]
    elseif attr == 0x049 then
        streams['tank_detection_mode'] = bytes[byteCount + 3]
    elseif attr == 0x04A then
        streams['single_keep_warm_time'] = bytes[byteCount + 3]
    elseif attr == 0x04B then
        streams['single_keep_warm_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x04C then
        streams['single_stew_time'] = bit.lshift(bytes[byteCount + 4], 8) +
                                          bytes[byteCount + 3]
    elseif attr == 0x04D then
        streams['single_stew_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x04E then
        streams['stew_time_1'] = bit.lshift(bytes[byteCount + 4], 8) +
                                     bytes[byteCount + 3]
        streams['stew_time_2'] = bit.lshift(bytes[byteCount + 6], 8) +
                                     bytes[byteCount + 5]
        streams['stew_time_3'] = bit.lshift(bytes[byteCount + 8], 8) +
                                     bytes[byteCount + 7]
        streams['stew_time_4'] = bit.lshift(bytes[byteCount + 10], 8) +
                                     bytes[byteCount + 9]
        streams['stew_time_5'] = bit.lshift(bytes[byteCount + 12], 8) +
                                     bytes[byteCount + 11]
    elseif attr == 0x04F then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['boil_pot_connection'] = VALUE_OFF
        else
            streams['boil_pot_connection'] = VALUE_ON
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['stew_pot_connection'] = VALUE_OFF
        else
            streams['stew_pot_connection'] = VALUE_ON
        end
    elseif attr == 0x050 then
        streams['gesture_quantify'] = bit.lshift(bytes[byteCount + 4], 8) +
                                          bytes[byteCount + 3]
    elseif attr == 0x051 then
        streams['night_light'] = bit.lshift(bytes[byteCount + 4], 8) +
                                     bytes[byteCount + 3]
    elseif attr == 0x052 then
        streams['hydration_setting'] = bytes[byteCount + 3]
    elseif attr == 0x053 then
        streams['counterfeiting_detection_1'] = bytes[byteCount + 3]
    elseif attr == 0x054 then
        streams['counterfeiting_detection_2'] = bytes[byteCount + 3]
    elseif attr == 0x055 then
        streams['counterfeiting_detection_3'] = bytes[byteCount + 3]
    elseif attr == 0x056 then
        streams['counterfeiting_detection_4'] = bytes[byteCount + 3]
    elseif attr == 0x057 then
        streams['counterfeiting_detection_5'] = bytes[byteCount + 3]
    elseif attr == 0x058 then
        streams['counterfeiting_detection_fail_type'] = bytes[byteCount + 3]
    elseif attr == 0x059 then
        streams['screen_brightness'] = bytes[byteCount + 3]
    elseif attr == 0x05A then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['auto_stop_switch'] = VALUE_ON
        else
            streams['auto_stop_switch'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['auto_stop_fail'] = VALUE_ON
        else
            streams['auto_stop_fail'] = VALUE_OFF
        end
        streams['auto_stop_kind'] = bytes[byteCount + 4]
        streams['auto_stop_percentage'] = bytes[byteCount + 5]
    elseif attr == 0x05B then
        streams['stew_mode_1'] = bytes[byteCount + 3]
    elseif attr == 0x05C then
        streams['stew_mode_2'] = bytes[byteCount + 3]
    elseif attr == 0x05D then
        streams['stew_mode_3'] = bytes[byteCount + 3]
    elseif attr == 0x05E then
        streams['stew_mode_4'] = bytes[byteCount + 3]
    elseif attr == 0x05F then
        streams['stew_mode_5'] = bytes[byteCount + 3]
    elseif attr == 0x060 then
        streams['stew_mode_6'] = bytes[byteCount + 3]
    elseif attr == 0x061 then
        streams['stew_mode_7'] = bytes[byteCount + 3]
    elseif attr == 0x062 then
        streams['stew_mode_8'] = bytes[byteCount + 3]
    elseif attr == 0x063 then
        streams['stew_mode_9'] = bytes[byteCount + 3]
    elseif attr == 0x064 then
        streams['selected_stew_mode'] = bytes[byteCount + 3]
        streams['stew_water'] = bit.lshift(bytes[byteCount + 5], 8) +
                                    bytes[byteCount + 4]
        streams['stew_left_time'] = bytes[byteCount + 6]
    elseif attr == 0x065 then
        streams['keep_warm_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x066 then
        streams['stew_pot_error'] = bytes[byteCount + 3]
    elseif attr == 0x067 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['stew_pot_place'] = VALUE_ON
        else
            streams['stew_pot_place'] = VALUE_OFF
        end
    elseif attr == 0x068 then
        streams['filter_left_days_1'] = bit.lshift(bytes[byteCount + 4], 8) +
                                            bytes[byteCount + 3]
    elseif attr == 0x069 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['soda_board_cool_error'] = VALUE_ON
        else
            streams['soda_board_cool_error'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['soda_board_lack_water'] = VALUE_ON
        else
            streams['soda_board_lack_water'] = VALUE_OFF
        end
    elseif attr == 0x070 then
        if bytes[byteCount + 3] == 0x01 then
            streams['relay_keep_warm'] = VALUE_ON
            streams['relay_keep_warm_2'] = VALUE_OFF
        elseif bytes[byteCount + 3] == 0x02 then
            streams['relay_keep_warm'] = VALUE_OFF
            streams['relay_keep_warm_2'] = VALUE_ON
        else
            streams['relay_keep_warm'] = VALUE_OFF
            streams['relay_keep_warm_2'] = VALUE_OFF
        end
        streams['relay_keep_warm_time'] = bytes[byteCount + 4]
        streams['relay_warm_left_time'] =
            bit.lshift(bytes[byteCount + 6], 8) + bytes[byteCount + 5]
    elseif attr == 0x071 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['cold_water_reflux_switch'] = VALUE_ON
        else
            streams['cold_water_reflux_switch'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['filter_sleep'] = VALUE_ON
        else
            streams['filter_sleep'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x04) == 0x04) then
            streams['filter_door_status'] = VALUE_ON
        else
            streams['filter_door_status'] = VALUE_OFF
        end
    elseif attr == 0x072 then
        streams['cold_water_reflux_hour'] = bytes[byteCount + 3]
    elseif attr == 0x073 then
        streams['first_custom_out_water_sec_mode'] = bytes[byteCount + 3]
        streams['first_custom_out_water_sec'] =
            bit.lshift(bytes[byteCount + 5], 8) + bytes[byteCount + 4]
    elseif attr == 0x074 then
        streams['life_expire_1'] = bit.lshift(bytes[byteCount + 4], 8) +
                                       bytes[byteCount + 3]
    elseif attr == 0x075 then
        streams['life_expire_2'] = bit.lshift(bytes[byteCount + 4], 8) +
                                       bytes[byteCount + 3]
    elseif attr == 0x076 then
        streams['life_expire_3'] = bit.lshift(bytes[byteCount + 4], 8) +
                                       bytes[byteCount + 3]
    elseif attr == 0x077 then
        streams['life_expire_4'] = bit.lshift(bytes[byteCount + 4], 8) +
                                       bytes[byteCount + 3]
    elseif attr == 0x078 then
        streams['life_expire_5'] = bit.lshift(bytes[byteCount + 4], 8) +
                                       bytes[byteCount + 3]
    elseif attr == 0x079 then
        streams['second_custom_out_water_mode'] = bytes[byteCount + 3]
        streams['second_custom_out_water_ml'] =
            bit.lshift(bytes[byteCount + 5], 8) + bytes[byteCount + 4]
    elseif attr == 0x07A then
        streams['third_custom_out_water_mode'] = bytes[byteCount + 3]
        streams['third_custom_out_water_ml'] =
            bit.lshift(bytes[byteCount + 5], 8) + bytes[byteCount + 4]
    elseif attr == 0x07B then
        streams['fourth_custom_out_water_mode'] = bytes[byteCount + 3]
        streams['fourth_custom_out_water_ml'] =
            bit.lshift(bytes[byteCount + 5], 8) + bytes[byteCount + 4]
    elseif attr == 0x07C then
        streams['fifth_custom_out_water_mode'] = bytes[byteCount + 3]
        streams['fifth_custom_out_water_ml'] =
            bit.lshift(bytes[byteCount + 5], 8) + bytes[byteCount + 4]
    elseif attr == 0x07E then
        streams['ice_size'] = bytes[byteCount + 3]
    elseif attr == 0x200 then
        streams['input_pressure_Sensing'] =
            bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x207 then
        if (tonumber(bytes[byteCount + 3]) > 127) then
            streams['input_temperature_Sensing'] = bytes[byteCount + 3] - 256
        else
            streams['input_temperature_Sensing'] = bytes[byteCount + 3]
        end
    elseif (attr == 0x202) and (bytes[byteCount + 4] ~= nil) then
        streams['water_flow'] = bit.lshift(bytes[byteCount + 4], 8) +
                                    bytes[byteCount + 3]
    elseif attr == 0x20A then
        streams['env_temperature'] = bytes[byteCount + 3]
    elseif attr == 0x213 then
        streams['lock_time'] = bytes[byteCount + 3]
    elseif attr == 0x300 then
        streams['prefilter_version'] = bytes[byteCount + 3]
    elseif attr == 0x301 then
        streams['all_water_consumption'] =
            bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x302 then
        streams['today_water_consumption'] =
            bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x30A then
        streams['clean_interval_next_days_remaining'] = bytes[byteCount + 3]
    elseif attr == 0x30B then
        streams['clean_water_consumption_next_remaining'] = bytes[byteCount + 3]
    elseif attr == 0x30D then
        streams['single_max_water_consumption'] = bytes[byteCount + 3]
    elseif attr == 0x30E then
        streams['single_max_water_time'] = bytes[byteCount + 3]
    elseif attr == 0x30F then
        streams['micro_check_remain_time'] = bytes[byteCount + 3]
    elseif attr == 0x310 then
        if bytes[byteCount + 3] > 0 then
            streams['open_close_switch'] = 'on'
        else
            streams['open_close_switch'] = 'off'
        end
    elseif attr == 0x311 then
        if bytes[byteCount + 3] > 0 then
            streams['open_close_water_pressure'] = 'on'
        else
            streams['open_close_water_pressure'] = 'off'
        end
    elseif attr == 0x312 then
        if bytes[byteCount + 3] > 0 then
            streams['start_clean'] = 'on'
        else
            streams['start_clean'] = 'off'
        end
    elseif attr == 0x313 then
        streams['clean_interval'] = bytes[byteCount + 3]
    elseif attr == 0x314 then
        streams['clean_water_consumption'] = bytes[byteCount + 3]
    elseif attr == 0x315 then
        streams['clean_time'] = bytes[byteCount + 3]
    elseif attr == 0x901 then
        streams['velocity'] = bytes[byteCount + 3]
    elseif attr == 0x902 then
        streams['soft_available_big'] = bit.lshift(bytes[byteCount + 6], 24) +
                                            bit.lshift(bytes[byteCount + 5], 16) +
                                            bit.lshift(bytes[byteCount + 4], 8) +
                                            bytes[byteCount + 3]
    elseif attr == 0x903 then
        streams['water_consumption_big'] =
            bit.lshift(bytes[byteCount + 6], 24) +
                bit.lshift(bytes[byteCount + 5], 16) +
                bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x904 then
        streams['water_consumption_today'] =
            bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x905 then
        streams['water_consumption_average'] =
            bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x906 then
        streams['left_salt'] = bytes[byteCount + 3]
    elseif attr == 0x907 then
        streams['salt_alarm_threshold'] = bytes[byteCount + 3]
    elseif attr == 0x908 then
        streams['salt_setting'] = bytes[byteCount + 3]
    elseif attr == 0x909 then
        streams['leak_water_protection_value'] = bytes[byteCount + 3]
        streams['micro_leak_protection_value'] = bytes[byteCount + 4]
    elseif attr == 0x90A then
        streams['water_hardness'] = bit.lshift(bytes[byteCount + 4], 8) +
                                        bytes[byteCount + 3]
    elseif attr == 0x90B then
        streams['pre_regeneration_days'] = bytes[byteCount + 3]
    elseif attr == 0x90C then
        streams['flushing_days'] = bytes[byteCount + 3]
        streams['timing_regeneration_hour'] = bytes[byteCount + 5]
        streams['timing_regeneration_min'] = bytes[byteCount + 6]
    elseif attr == 0x90D then
        streams['regeneration_left_seconds'] =
            bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x90E then
        streams['motor_workstation'] = bytes[byteCount + 4]
    elseif attr == 0x90F then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['leak_water'] = VALUE_ON
        else
            streams['leak_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['micro_leak'] = VALUE_ON
        else
            streams['micro_leak'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x04) == 0x04) then
            streams['low_salt'] = VALUE_ON
        else
            streams['low_salt'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x08) == 0x08) then
            streams['no_salt'] = VALUE_ON
        else
            streams['no_salt'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x10) == 0x10) then
            streams['low_battery'] = VALUE_ON
        else
            streams['low_battery'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x20) == 0x20) then
            streams['maintenance_remind'] = VALUE_ON
        else
            streams['maintenance_remind'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x01) == 0x01) then
            streams['salt_level_sensor_error'] = VALUE_ON
        else
            streams['salt_level_sensor_error'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x02) == 0x02) then
            streams['chlorine_sterilization_error'] = VALUE_ON
        else
            streams['chlorine_sterilization_error'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x04) == 0x04) then
            streams['flowmeter_error'] = VALUE_ON
        else
            streams['flowmeter_error'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x08) == 0x08) then
            streams['rtc_error'] = VALUE_ON
        else
            streams['rtc_error'] = VALUE_OFF
        end
    elseif attr == 0x910 then
        streams['use_days'] = bit.lshift(bytes[byteCount + 4], 8) +
                                  bytes[byteCount + 3]
        streams['regeneration_count'] = bit.lshift(bytes[byteCount + 6], 8) +
                                            bytes[byteCount + 5]
    elseif attr == 0x911 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['rsj_stand_by'] = VALUE_ON
        else
            streams['rsj_stand_by'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['regeneration'] = VALUE_ON
        else
            streams['regeneration'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x04) == 0x04) then
            streams['holiday_mode'] = VALUE_ON
        else
            streams['holiday_mode'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x08) == 0x08) then
            streams['leak_water_protection'] = VALUE_ON
        else
            streams['leak_water_protection'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x10) == 0x10) then
            streams['micro_leak_protection'] = VALUE_ON
        else
            streams['micro_leak_protection'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x20) == 0x20) then
            streams['cl_sterilization'] = VALUE_ON
        else
            streams['cl_sterilization'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x80) == 0x80) then
            streams['maintenance_reminder_switch'] = VALUE_ON
        else
            streams['maintenance_reminder_switch'] = VALUE_OFF
        end
    elseif attr == 0x912 then
        streams['supply_voltage'] = bytes[byteCount + 3]
        streams['battery_voltage'] = bytes[byteCount + 4]
    elseif attr == 0x913 then
        streams['days_since_last_regeneration'] = bytes[byteCount + 5]
        streams['days_since_last_two_regeneration'] = bytes[byteCount + 6]
    elseif attr == 0x914 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['soften'] = VALUE_ON
        else
            streams['soften'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['water_way'] = VALUE_ON
        else
            streams['water_way'] = VALUE_OFF
        end
        streams['mixed_water_gear'] = bytes[byteCount + 4]
    elseif attr == 0x915 then
        streams['maintenance_reminder_setting'] = bytes[byteCount + 3]
        streams['remind_maintenance_days'] =
            bit.lshift(bytes[byteCount + 5], 8) + bytes[byteCount + 4]
    elseif attr == 0x916 then
        streams['pre_regeneration'] = bytes[byteCount + 3]
    elseif attr == 0x917 then
        streams['real_date_setting_year'] = bytes[byteCount + 3]
        streams['real_date_setting_month'] = bytes[byteCount + 4]
        streams['real_date_setting_day'] = bytes[byteCount + 5]
        streams['real_time_setting_hour'] = bytes[byteCount + 6]
        streams['real_time_setting_min'] = bytes[byteCount + 7]
    elseif attr == 0x918 then
        streams['regeneration_stages'] = bytes[byteCount + 3]
        streams['regeneration_current_stages'] = bytes[byteCount + 4]
        streams['regeneration_current_stages_name'] = bytes[byteCount + 5]
    elseif attr == 0x919 then
        streams['salt_usage_past_7'] = bit.lshift(bytes[byteCount + 4], 8) +
                                           bytes[byteCount + 3]
        streams['salt_usage_past_30'] = bit.lshift(bytes[byteCount + 7], 16) +
                                            bit.lshift(bytes[byteCount + 6], 8) +
                                            bytes[byteCount + 5]
    elseif attr == 0x920 then
        streams['clean_available_big'] =
            bit.lshift(bytes[byteCount + 6], 24) +
                bit.lshift(bytes[byteCount + 5], 16) +
                bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x921 then
        streams['cleaning_left_seconds'] =
            bit.lshift(bytes[byteCount + 4], 8) + bytes[byteCount + 3]
    elseif attr == 0x922 then
        streams['cleaning_days'] = bytes[byteCount + 3]
        streams['timing_cleaning_hour'] = bytes[byteCount + 5]
        streams['timing_cleaning_min'] = bytes[byteCount + 6]
    elseif attr == 0x923 then
        streams['pre_cleaning_days'] = bytes[byteCount + 3]
    elseif attr == 0x924 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['filter_switch'] = VALUE_ON
        else
            streams['filter_switch'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['water_way'] = VALUE_ON
        else
            streams['water_way'] = VALUE_OFF
        end
        streams['mixed_water_gear'] = bytes[byteCount + 4]
    elseif attr == 0x926 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['zyj_stand_by'] = VALUE_ON
        else
            streams['zyj_stand_by'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['clean'] = VALUE_ON
        else
            streams['clean'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x04) == 0x04) then
            streams['holiday_mode'] = VALUE_ON
        else
            streams['holiday_mode'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x08) == 0x08) then
            streams['leak_water_protection'] = VALUE_ON
        else
            streams['leak_water_protection'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x10) == 0x10) then
            streams['micro_leak_protection'] = VALUE_ON
        else
            streams['micro_leak_protection'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x20) == 0x20) then
            streams['maintenance_reminder_switch'] = VALUE_ON
        else
            streams['maintenance_reminder_switch'] = VALUE_OFF
        end
    elseif attr == 0x927 then
        streams['days_since_last_cleaning'] = bytes[byteCount + 5]
        streams['days_since_last_two_cleaning'] = bytes[byteCount + 6]
    elseif attr == 0x928 then
        if (bit.band(bytes[byteCount + 3], 0x01) == 0x01) then
            streams['leak_water'] = VALUE_ON
        else
            streams['leak_water'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x02) == 0x02) then
            streams['micro_leak'] = VALUE_ON
        else
            streams['micro_leak'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x04) == 0x04) then
            streams['low_battery'] = VALUE_ON
        else
            streams['low_battery'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 3], 0x08) == 0x08) then
            streams['maintenance_remind'] = VALUE_ON
        else
            streams['maintenance_remind'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x01) == 0x01) then
            streams['flowmeter_error'] = VALUE_ON
        else
            streams['flowmeter_error'] = VALUE_OFF
        end
        if (bit.band(bytes[byteCount + 5], 0x02) == 0x02) then
            streams['rtc_error'] = VALUE_ON
        else
            streams['rtc_error'] = VALUE_OFF
        end
    elseif attr == 0x929 then
        streams['pre_clean'] = bytes[byteCount + 3]
    elseif attr == 0x92A then
        streams['use_days'] = bit.lshift(bytes[byteCount + 4], 8) +
                                  bytes[byteCount + 3]
        streams['cleaning_count'] = bit.lshift(bytes[byteCount + 6], 8) +
                                        bytes[byteCount + 5]
    end
    byteCount = byteCount + leng
    if byteCount < #bytes then statusJudge(streams, bytes) end
end
local function updateGlobalPropertyValueByJson(luaTable) end
local function assembleJsonByGlobalProperty(bodyBytes)
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (dataType == 0x03 and bodyBytes[0] == 0xFF) or
        (dataType == 0x04 and bodyBytes[0] == 0xFF) then
        byteCount = 2
        streams['category'] = bodyBytes[2]
        statusJudge(streams, bodyBytes)
    end
    return streams
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        if (status) then updateGlobalPropertyValueByJson(status) end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyBytes = {}
        bodyBytes[0] = 0x15
        bodyBytes[1] = 0x01
        bodyBytes[2] = 0x00
        if (control["power"] and control["power"] == VALUE_ON) then
            setbytes(0x00, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["power"] and control["power"] == VALUE_OFF) then
            setbytes(0x00, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["standby_status"] and control["standby_status"] == VALUE_ON) then
            setbytes(0x01, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["standby_status"] and control["standby_status"] ==
            VALUE_OFF) then
            setbytes(0x01, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["bottle_reset"] then
            setbytes(0x02, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["bottle_capacity"] then
            setbytes(0x03, 0x01, 0x00, control['bottle_capacity'] % 256,
                     (control['bottle_capacity'] - control['bottle_capacity'] %
                         256) / 256, bodyBytes)
        end
        if (control["sleep"] and control["sleep"] == VALUE_ON) then
            setbytes(0x04, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["sleep"] and control["sleep"] == VALUE_OFF) then
            setbytes(0x04, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["vacation"] and control["vacation"] == VALUE_ON) then
            setbytes(0x05, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["vacation"] and control["vacation"] == VALUE_OFF) then
            setbytes(0x05, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["germicidal"] and control["germicidal"] == VALUE_ON) then
            setbytes(0x06, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["germicidal"] and control["germicidal"] == VALUE_OFF) then
            setbytes(0x06, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["set_germicidal_countdown"] and
            control["set_germicidal_countdown"] == VALUE_ON) then
            if (control["set_germicidal_countdown_days"]) then
                setbytes(0x07, 0x01, 0x01,
                         control['set_germicidal_countdown_days'] % 256,
                         (control['set_germicidal_countdown_days'] -
                             control['set_germicidal_countdown_days'] % 256) /
                             256, bodyBytes)
            else
                setbytes(0x07, 0x01, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["set_germicidal_countdown"] and
            control["set_germicidal_countdown"] == VALUE_OFF) then
            if (control["set_germicidal_countdown_days"]) then
                setbytes(0x07, 0x01, 0x00,
                         control['set_germicidal_countdown_days'] % 256,
                         (control['set_germicidal_countdown_days'] -
                             control['set_germicidal_countdown_days'] % 256) /
                             256, bodyBytes)
            else
                setbytes(0x07, 0x01, 0x00, 0x00, 0x00, bodyBytes)
            end
        end
        if control["screenout_time"] then
            setbytes(0x08, 0x01, 0x00, control['screenout_time'] % 256,
                     bit.rshift(control['screenout_time'], 8), bodyBytes)
        end
        if (control["cloud_wash"] and control["cloud_wash"] == VALUE_ON) then
            setbytes(0x09, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["cloud_wash"] and control["cloud_wash"] == VALUE_OFF) then
            setbytes(0x09, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["gesture"] and control["gesture"] == VALUE_ON) then
            setbytes(0x0a, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["gesture"] and control["gesture"] == VALUE_OFF) then
            setbytes(0x0a, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["gesture_mode"] then
            setbytes(0x0a, 0x01, control['gesture_mode'], 0x00, 0x00, bodyBytes)
        end
        if control["plateau_pressure"] then
            setbytes(0x0B, 0x01, 0x00, control['plateau_pressure'] % 256,
                     bit.rshift(control['plateau_pressure'], 8), bodyBytes)
        end
        if (control["buzzer"] and control["buzzer"] == VALUE_ON) then
            setbytes(0x0D, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["buzzer"] and control["buzzer"] == VALUE_OFF) then
            setbytes(0x0D, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["leaking_protect_time"] then
            setbytes(0x12, 0x01, control['leaking_protect_time'], 0x00, 0x00,
                     bodyBytes)
        end
        if (control["gesture_disable_high_temperature"] and
            control["gesture_disable_high_temperature"] == VALUE_ON) then
            setbytes(0x13, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["gesture_disable_high_temperature"] and
            control["gesture_disable_high_temperature"] == VALUE_OFF) then
            setbytes(0x13, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["first_custom_out_water_ml"] then
            setbytes(0x14, 0x01, control['first_custom_out_water_mode'],
                     control['first_custom_out_water_ml'] % 256,
                     bit.rshift(control['first_custom_out_water_ml'], 8),
                     bodyBytes)
        end
        if (control["uv_led"] and control["uv_led"] == VALUE_ON) then
            setbytes(0x15, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["uv_led"] and control["uv_led"] == VALUE_OFF) then
            setbytes(0x15, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["voice_volume"]) then
            setbytes(0x16, 0x01, control['voice_volume'], 0x00, 0x00, bodyBytes)
        end
        if (control["voice_type"]) then
            setbytes(0x17, 0x01, control['voice_type'], 0x00, 0x00, bodyBytes)
        end
        if (control["human_sensing_switch"] and control["human_sensing_switch"] ==
            VALUE_ON) then
            if control["human_sensing_distance"] then
                setbytes(0x18, 0x01, 0x01,
                         control['human_sensing_distance'] % 256,
                         bit.rshift(control['human_sensing_distance'], 8),
                         bodyBytes)
            else
                setbytes(0x18, 0x01, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["human_sensing_switch"] and
            control["human_sensing_switch"] == VALUE_OFF) then
            if control["human_sensing_distance"] then
                setbytes(0x18, 0x01, 0x00,
                         control['human_sensing_distance'] % 256,
                         bit.rshift(control['human_sensing_distance'], 8),
                         bodyBytes)
            else
                setbytes(0x18, 0x01, 0x00, 0x00, 0x00, bodyBytes)
            end
        elseif control["human_sensing_distance"] then
            setbytes(0x18, 0x01, 0x00, control['human_sensing_distance'] % 256,
                     bit.rshift(control['human_sensing_distance'], 8), bodyBytes)
        end
        if (control["tank_detection_mode"]) then
            setbytes(0x19, 0x01, control['tank_detection_mode'], 0x00, 0x00,
                     bodyBytes)
        end
        if control["gesture_quantify"] then
            setbytes(0x2D, 0x01, 0x00, control['gesture_quantify'] % 256,
                     bit.rshift(control['gesture_quantify'], 8), bodyBytes)
        end
        if (control["night_light"] and control["night_light"] == VALUE_ON) then
            setbytes(0x2E, 0x01, 0x00, 0xFF, 0xFF, bodyBytes)
        elseif (control["night_light"] and control["night_light"] == VALUE_OFF) then
            setbytes(0x2E, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        elseif control["night_light"] then
            setbytes(0x2E, 0x01, 0x00, control['night_light'] % 256,
                     bit.rshift(control['night_light'], 8), bodyBytes)
        end
        if control["hydration_setting"] then
            setbytes(0x2F, 0x01, control['hydration_setting'], 0x00, 0x00,
                     bodyBytes)
        end
        if (control["counterfeiting_detect"] and
            control["counterfeiting_detect"] == VALUE_ON) then
            setbytes(0x30, 0x01, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["counterfeiting_detect"] and
            control["counterfeiting_detect"] == VALUE_OFF) then
            setbytes(0x30, 0x01, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["screen_brightness"] ~= nil then
            setbytes(0x31, 0x01, control['screen_brightness'], 0x00, 0x00,
                     bodyBytes)
        end
        if control["first_custom_out_water_sec"] then
            setbytes(0x32, 0x01, control['first_custom_out_water_sec_mode'],
                     control['first_custom_out_water_sec'] % 256,
                     bit.rshift(control['first_custom_out_water_sec'], 8),
                     bodyBytes)
        end
        if control["second_custom_out_water_ml"] then
            setbytes(0x33, 0x01, control['second_custom_out_water_mode'],
                     control['second_custom_out_water_ml'] % 256,
                     bit.rshift(control['second_custom_out_water_ml'], 8),
                     bodyBytes)
        end
        if control["third_custom_out_water_ml"] then
            setbytes(0x34, 0x01, control['third_custom_out_water_mode'],
                     control['third_custom_out_water_ml'] % 256,
                     bit.rshift(control['third_custom_out_water_ml'], 8),
                     bodyBytes)
        end
        if control["fourth_custom_out_water_ml"] then
            setbytes(0x35, 0x01, control['fourth_custom_out_water_mode'],
                     control['fourth_custom_out_water_ml'] % 256,
                     bit.rshift(control['fourth_custom_out_water_ml'], 8),
                     bodyBytes)
        end
        if control["fifth_custom_out_water_ml"] then
            setbytes(0x36, 0x01, control['fifth_custom_out_water_mode'],
                     control['fifth_custom_out_water_ml'] % 256,
                     bit.rshift(control['fifth_custom_out_water_ml'], 8),
                     bodyBytes)
        end
        if control["out_water"] then
            local item3 = 0x00
            local item4 = 0x00
            local item5 = 0x00
            if control["out_water"] == VALUE_ON then
                item3 = item3 + 1
            end
            if control["out_water_count"] then
                item3 = item3 + control["out_water_count"] * 2
            end
            if control["water_kind"] then
                item4 = control["water_kind"]
            end
            if control["ctrl_out_water_quantify"] then
                item5 = control["ctrl_out_water_quantify"]
            end
            setbytes(0x00, 0x02, item3, item4, item5, bodyBytes)
        end
        if (control["lock"] and control["lock"] == VALUE_ON) then
            if control["lock_time"] ~= nil then
                setbytes(0x01, 0x02, 0x01, control["lock_time"], 0x00, bodyBytes)
            else
                setbytes(0x01, 0x02, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["lock"] and control["lock"] == VALUE_OFF) then
            if control["lock_time"] ~= nil then
                setbytes(0x01, 0x02, 0x00, control["lock_time"], 0x00, bodyBytes)
            else
                setbytes(0x01, 0x02, 0x00, 0x00, 0x00, bodyBytes)
            end
        elseif control["lock_time"] ~= nil then
            setbytes(0x01, 0x02, 0x00, control["lock_time"], 0x00, bodyBytes)
        end
        for i = 1, 25 do
            if (control["quantify_" .. i] and control['brew_tea'] == nil) then
                setbytes(0x02, 0x02, i, control["quantify_" .. i] % 256,
                         (control["quantify_" .. i] - control["quantify_" .. i] %
                             256) / 256, bodyBytes)
            end
        end
        if (control["bubble"] and control["bubble"] == VALUE_ON) then
            setbytes(0x03, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["bubble"] and control["bubble"] == VALUE_OFF) then
            setbytes(0x03, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["drainage"] and control["drainage"] == VALUE_ON) then
            setbytes(0x04, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["drainage"] and control["drainage"] == VALUE_OFF) then
            setbytes(0x04, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["quantify_enable"] and control["quantify_enable"] ==
            VALUE_ON) then
            if control["quantify_enable_timeout"] then
                setbytes(0x05, 0x02, 0x01,
                         control['quantify_enable_timeout'] % 256,
                         bit.rshift(control['quantify_enable_timeout'], 8),
                         bodyBytes)
            else
                setbytes(0x05, 0x02, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["quantify_enable"] and control["quantify_enable"] ==
            VALUE_OFF) then
            if control["quantify_enable_timeout"] then
                setbytes(0x05, 0x02, 0x00,
                         control['quantify_enable_timeout'] % 256,
                         bit.rshift(control['quantify_enable_timeout'], 8),
                         bodyBytes)
            else
                setbytes(0x05, 0x02, 0x00, 0x00, 0x00, bodyBytes)
            end
        end
        if control["rfid_role"] then
            if control["rfid_temp"] then
                if (control["rfid_quantify"]) then
                    setbytes(0x06, 0x02, control["rfid_temp"],
                             control['rfid_quantify'], control["rfid_role"],
                             bodyBytes)
                else
                    setbytes(0x06, 0x02, control["rfid_temp"], 0x00,
                             control["rfid_role"], bodyBytes)
                end
            elseif (control["rfid_quantify"]) then
                setbytes(0x06, 0x02, 0x00, control['rfid_quantify'],
                         control["rfid_role"], bodyBytes)
            else
                setbytes(0x06, 0x02, 0x00, 0x00, control["rfid_role"], bodyBytes)
            end
        end
        if (control["add_rfid_role"]) then
            setbytes(0x07, 0x02, 0x01, control["add_rfid_role"], 0x00, bodyBytes)
        elseif (control["del_rfid_role"]) then
            setbytes(0x07, 0x02, 0x00, control["del_rfid_role"], 0x00, bodyBytes)
        end
        if (control["set_low_code"] and control["set_high_code"]) then
            setbytes(0x08, 0x02, 0x00, control['set_low_code'],
                     control["set_high_code"], bodyBytes)
        end
        for i = 1, 5 do
            if control["quantify_tds_" .. i] then
                setbytes(0x09, 0x02, i, control["quantify_tds_" .. i], 0x00,
                         bodyBytes)
            end
        end
        if control["out_big_water"] then
            local item3 = 0x00
            local item4 = 0x00
            local item5 = 0x00
            if control["out_big_water"] == VALUE_ON then
                item3 = item3 + 1
            end
            if control["out_big_water_kind"] then
                item3 = item3 + control["out_big_water_kind"] * 2
            end
            if control["out_big_water_quantify"] then
                item4 = control['out_big_water_quantify'] % 256
                item5 = (control['out_big_water_quantify'] -
                            control['out_big_water_quantify'] % 256) / 256
            end
            setbytes(0x0a, 0x02, item3, item4, item5, bodyBytes)
        end
        if (control["no_obsolete_water"] and control["no_obsolete_water"] ==
            VALUE_ON) then
            setbytes(0x0b, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["no_obsolete_water"] and control["no_obsolete_water"] ==
            VALUE_OFF) then
            setbytes(0x0b, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["voice_power"] and control["voice_power"] == VALUE_ON) then
            setbytes(0x0c, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["voice_power"] and control["voice_power"] == VALUE_OFF) then
            setbytes(0x0c, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["cur_quantify"] then
            setbytes(0x0d, 0x02, control["cur_quantify"], 0x00, 0x00, bodyBytes)
        end
        if (control["smart_no_obsolete_water"] and
            control["smart_no_obsolete_water"] == VALUE_ON) then
            setbytes(0x0f, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["smart_no_obsolete_water"] and
            control["smart_no_obsolete_water"] == VALUE_OFF) then
            setbytes(0x0f, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["quantify_calibration"] and control["quantify_calibration"] ==
            VALUE_ON) then
            if (control["quantify_calibration_percent"]) then
                set_calibration(0x10, 0x02, 0x01,
                                control["quantify_calibration_percent"], 0x00,
                                bodyBytes)
            else
                set_calibration(0x10, 0x02, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["quantify_calibration"] and
            control["quantify_calibration"] == VALUE_OFF) then
            if (control["quantify_calibration_percent"]) then
                set_calibration(0x10, 0x02, 0x00,
                                control["quantify_calibration_percent"], 0x00,
                                bodyBytes)
            else
                set_calibration(0x10, 0x02, 0x00, 0x00, 0x00, bodyBytes)
            end
        end
        if (control["voice_conversation_power"] and
            control["voice_conversation_power"] == VALUE_ON) then
            setbytes(0x11, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["voice_conversation_power"] and
            control["voice_conversation_power"] == VALUE_OFF) then
            setbytes(0x11, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["auto_continue"] and control["auto_continue"] == VALUE_ON) then
            setbytes(0x12, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["auto_continue"] and control["auto_continue"] ==
            VALUE_OFF) then
            setbytes(0x12, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["extreme_mode"] and control["extreme_mode"] == VALUE_ON) then
            setbytes(0x13, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["extreme_mode"] and control["extreme_mode"] == VALUE_OFF) then
            setbytes(0x13, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["auto_stop_switch"] and control["auto_stop_switch"] ==
            VALUE_ON) then
            if control["auto_stop_kind"] ~= nil then
                if control["auto_stop_percentage"] ~= nil then
                    setbytes(0x14, 0x02, 0x01, control["auto_stop_kind"],
                             control["auto_stop_percentage"], bodyBytes)
                else
                    setbytes(0x14, 0x02, 0x01, control["auto_stop_kind"], 0x00,
                             bodyBytes)
                end
            else
                if control["auto_stop_percentage"] ~= nil then
                    setbytes(0x14, 0x02, 0x01, 0x00,
                             control["auto_stop_percentage"], bodyBytes)
                else
                    setbytes(0x14, 0x02, 0x01, 0x00, 0x00, bodyBytes)
                end
            end
        elseif (control["auto_stop_switch"] and control["auto_stop_switch"] ==
            VALUE_OFF) then
            if control["auto_stop_kind"] ~= nil then
                if control["auto_stop_percentage"] ~= nil then
                    setbytes(0x14, 0x02, 0x00, control["auto_stop_kind"],
                             control["auto_stop_percentage"], bodyBytes)
                else
                    setbytes(0x14, 0x02, 0x00, control["auto_stop_kind"], 0x00,
                             bodyBytes)
                end
            else
                if control["auto_stop_percentage"] ~= nil then
                    setbytes(0x14, 0x02, 0x00, 0x00,
                             control["auto_stop_percentage"], bodyBytes)
                else
                    setbytes(0x14, 0x02, 0x00, 0x00, 0x00, bodyBytes)
                end
            end
        end
        if (control["auto_fill_water"] and control["auto_fill_water"] ==
            VALUE_ON) then
            setbytes(0x15, 0x02, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["auto_fill_water"] and control["auto_fill_water"] ==
            VALUE_OFF) then
            setbytes(0x15, 0x02, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["wash"] and control["wash"] == VALUE_ON) then
            if (control["wash_seconds"]) then
                setbytes(0x00, 0x03, 0x01, control['wash_seconds'] % 256,
                         (control['wash_seconds'] - control['wash_seconds'] %
                             256) / 256, bodyBytes)
            else
                setbytes(0x00, 0x03, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["wash"] and control["wash"] == VALUE_OFF) then
            setbytes(0x00, 0x03, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["save_mode"] and control["save_mode"] == VALUE_ON) then
            setbytes(0x01, 0x03, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["save_mode"] and control["save_mode"] == VALUE_OFF) then
            setbytes(0x01, 0x03, 0x00, 0x00, 0x00, bodyBytes)
        end
        for i = 1, 5 do
            if control["life_" .. i] then
                setbytes(0x02, 0x03, i - 1, control["life_" .. i], 0x00,
                         bodyBytes)
            end
        end
        if (control["wash_enable"] and control["wash_enable"] == VALUE_ON) then
            setbytes(0x03, 0x03, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["wash_enable"] and control["wash_enable"] == VALUE_OFF) then
            setbytes(0x03, 0x03, 0x00, 0x00, 0x00, bodyBytes)
        end
        for i = 1, 6 do
            if control["maxlife_" .. i] then
                setbytes(0x04, 0x03, i - 1, control["maxlife_" .. i] % 256,
                         (control["maxlife_" .. i] - control["maxlife_" .. i] %
                             256) / 256, bodyBytes)
            end
        end
        if control["air_filter"] then
            setbytes(0x02, 0x03, 0x05, 0x64, 0x00, bodyBytes)
        end
        if (control["autoclean_ctrl"] and control["autoclean_ctrl"] == VALUE_ON) then
            setbytes(0x05, 0x03, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["autoclean_ctrl"] and control["autoclean_ctrl"] ==
            VALUE_OFF) then
            setbytes(0x05, 0x03, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["autoclean_remind"] then
            local item3 = 0x00
            if control["autoclean_remind"] == VALUE_ON then
                item3 = item3 + 1
            end
            local item4 = control["autoclean_remind_cycle"] % 256
            local item5 = (control["autoclean_remind_cycle"] -
                              control["autoclean_remind_cycle"] % 256) / 256
            setbytes(0x06, 0x03, item3, item4, item5, bodyBytes)
        end
        if control["autoclean_time"] then
            setbytes(0x07, 0x03, control["autoclean_time"], 0x00, 0x00,
                     bodyBytes)
        end
        if (control["filter_wash"] and control["filter_wash"] == VALUE_ON) then
            setbytes(0x08, 0x03, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["filter_wash"] and control["filter_wash"] == VALUE_OFF) then
            setbytes(0x08, 0x03, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["heat"] then
            if control["heat"] == VALUE_ON then
                setbytes(0x00, 0x04, 0x01, 0x00, 0x00, bodyBytes)
            elseif control["heat"] == VALUE_OFF then
                setbytes(0x00, 0x04, 0x00, 0x00, 0x00, bodyBytes)
            else
                setbytes(0x00, 0x04, control["heat"], 0x00, 0x00, bodyBytes)
            end
        end
        if control["tea_temperature"] then
            set_tembytes(0x01, 0x04, control["tea_temperature"], 0x01, 0x00,
                         bodyBytes)
        end
        if control["medlar_temperature"] then
            set_tembytes(0x01, 0x04, control["medlar_temperature"], 0x02, 0x00,
                         bodyBytes)
        end
        if control["honey_temperature"] then
            set_tembytes(0x01, 0x04, control["honey_temperature"], 0x03, 0x00,
                         bodyBytes)
        end
        if control["milk_temperature"] then
            set_tembytes(0x01, 0x04, control["milk_temperature"], 0x04, 0x00,
                         bodyBytes)
        end
        if control["coffee_temperature"] then
            set_tembytes(0x01, 0x04, control["coffee_temperature"], 0x05, 0x00,
                         bodyBytes)
        end
        if control["red_tea_temperature"] then
            set_tembytes(0x01, 0x04, control["red_tea_temperature"], 0x06, 0x00,
                         bodyBytes)
        end
        if control["black_tea_temperature"] then
            set_tembytes(0x01, 0x04, control["black_tea_temperature"], 0x07,
                         0x00, bodyBytes)
        end
        if control["green_tea_temperature"] then
            set_tembytes(0x01, 0x04, control["green_tea_temperature"], 0x08,
                         0x00, bodyBytes)
        end
        if control["yellow_tea_temperature"] then
            set_tembytes(0x01, 0x04, control["yellow_tea_temperature"], 0x09,
                         0x00, bodyBytes)
        end
        for i = 1, 10 do
            if (control["custom_temperature_" .. i] and control['brew_tea'] ==
                nil) then
                set_tembytes(0x01, 0x04, control["custom_temperature_" .. i],
                             9 + i, 0x00, bodyBytes)
            end
        end
        if (control["heat_return_temperature"] and
            (control["heat_return_temperature"] >= 3 and
                control["heat_return_temperature"] <= 100)) then
            setbytes(0x02, 0x04, control["heat_return_temperature"], 0x00, 0x00,
                     bodyBytes)
        end
        if (control["auto_season"] and control["auto_season"] == VALUE_ON) then
            setbytes(0x03, 0x04, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["auto_season"] and control["auto_season"] == VALUE_OFF) then
            setbytes(0x03, 0x04, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["season"] and control["season"] == 1) then
            setbytes(0x04, 0x04, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["season"] and control["season"] == 0) then
            setbytes(0x04, 0x04, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["heat_tea"] then
            setbytes(0x06, 0x04, control["heat_tea"], 0x00, 0x00, bodyBytes)
        end
        if control["set_heat_time"] then
            setbytes(0x07, 0x04, 0x00, control['set_heat_time'] % 256,
                     (control['set_heat_time'] - control['set_heat_time'] % 256) /
                         256, bodyBytes)
        end
        if control["keep_warm"] then
            if control["keep_warm"] == VALUE_ON then
                if control["keep_warm_time"] then
                    setbytes(0x08, 0x04, 0x01, control['keep_warm_time'] % 256,
                             (control['keep_warm_time'] -
                                 control['keep_warm_time'] % 256) / 256,
                             bodyBytes)
                else
                    setbytes(0x08, 0x04, 0x01, 0x00, 0x00, bodyBytes)
                end
            elseif control["keep_warm"] == VALUE_OFF then
                if control["keep_warm_time"] then
                    setbytes(0x08, 0x04, 0x00, control['keep_warm_time'] % 256,
                             (control['keep_warm_time'] -
                                 control['keep_warm_time'] % 256) / 256,
                             bodyBytes)
                else
                    setbytes(0x08, 0x04, 0x00, 0x00, 0x00, bodyBytes)
                end
            else
                if control["keep_warm_time"] then
                    setbytes(0x08, 0x04, control["keep_warm"],
                             control['keep_warm_time'] % 256,
                             (control['keep_warm_time'] -
                                 control['keep_warm_time'] % 256) / 256,
                             bodyBytes)
                else
                    setbytes(0x08, 0x04, control["keep_warm"], 0x00, 0x00,
                             bodyBytes)
                end
            end
        end
        if control["brew_tea"] then
            setbytes(0x09, 0x04, control["custom_temperature_1"],
                     control["brew_number"], control["quantify_1"], bodyBytes)
        end
        if control["set_tea_washing"] then
            local item4 = 0x00
            if control["set_tea_washing"] == VALUE_ON then
                item4 = item4 + 1
            end
            setbytes(0x0A, 0x04, control["tea_washing_time"], item4,
                     control["tea_washing_quantify"], bodyBytes)
        end
        if (control["plateau_power"] and control["plateau_power"] == VALUE_ON) then
            if control["plateau_boiling_point"] then
                setbytes(0x0B, 0x04, 0x01, control["plateau_boiling_point"],
                         0x00, bodyBytes)
            else
                setbytes(0x0B, 0x04, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["plateau_power"] and control["plateau_power"] ==
            VALUE_OFF) then
            if control["plateau_boiling_point"] then
                setbytes(0x0B, 0x04, 0x00, control["plateau_boiling_point"],
                         0x00, bodyBytes)
            else
                setbytes(0x0B, 0x04, 0x00, 0x00, 0x00, bodyBytes)
            end
        end
        if (control["reheating"] and control["reheating"] == VALUE_ON) then
            setbytes(0x0C, 0x04, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["reheating"] and control["reheating"] == VALUE_OFF) then
            setbytes(0x0C, 0x04, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["single_keep_warm_time"] then
            setbytes(0x0D, 0x04, control["single_keep_warm_time"], 0x00, 0x00,
                     bodyBytes)
        end
        if control["single_keep_warm_temperature"] then
            setbytes(0x0E, 0x04, control["single_keep_warm_temperature"], 0x00,
                     0x00, bodyBytes)
        end
        if control["single_stew_time"] then
            setbytes(0x0F, 0x04, 0x00, control['single_stew_time'] % 256,
                     bit.rshift(control['single_stew_time'], 8), bodyBytes)
        end
        if control["single_stew_temperature"] then
            setbytes(0x10, 0x04, control["single_stew_temperature"], 0x00, 0x00,
                     bodyBytes)
        end
        for i = 1, 5 do
            if control["stew_time_" .. i] then
                set_tembytes(0x11, 0x04, i, control["stew_time_" .. i] % 256,
                             bit.rshift(control["stew_time_" .. i], 8),
                             bodyBytes)
            end
        end
        if control["selected_stew_mode"] then
            setbytes(0x12, 0x04, control["selected_stew_mode"],
                     control["stew_water"] % 256,
                     bit.rshift(control["stew_water"], 8), bodyBytes)
        end
        if control["keep_warm_temperature"] then
            setbytes(0x13, 0x04, control["keep_warm_temperature"], 0x00, 0x00,
                     bodyBytes)
        end
        for i = 1, 9 do
            if control["stew_mode_" .. i] then
                set_tembytes(0x14, 0x04, i, control["stew_mode_" .. i], 0x00,
                             bodyBytes)
            end
        end
        if control["relay_keep_warm"] then
            if control["relay_keep_warm"] == VALUE_ON then
                if control["relay_keep_warm_time"] then
                    setbytes(0x15, 0x04, 0x01,
                             control['relay_keep_warm_time'] % 256,
                             (control['relay_keep_warm_time'] -
                                 control['relay_keep_warm_time'] % 256) / 256,
                             bodyBytes)
                else
                    setbytes(0x15, 0x04, 0x01, 0x00, 0x00, bodyBytes)
                end
            elseif control["relay_keep_warm"] == VALUE_OFF then
                if control["relay_keep_warm_time"] then
                    setbytes(0x15, 0x04, 0x00,
                             control['relay_keep_warm_time'] % 256,
                             (control['relay_keep_warm_time'] -
                                 control['relay_keep_warm_time'] % 256) / 256,
                             bodyBytes)
                else
                    setbytes(0x15, 0x04, 0x00, 0x00, 0x00, bodyBytes)
                end
            else
                if control["relay_keep_warm_time"] then
                    setbytes(0x15, 0x04, control["relay_keep_warm"],
                             control['relay_keep_warm_time'] % 256,
                             (control['relay_keep_warm_time'] -
                                 control['relay_keep_warm_time'] % 256) / 256,
                             bodyBytes)
                else
                    setbytes(0x15, 0x04, control["relay_keep_warm"], 0x00, 0x00,
                             bodyBytes)
                end
            end
        end
        if (control["cool"] and control["cool"] == VALUE_ON) then
            setbytes(0x00, 0x05, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["cool"] and control["cool"] == VALUE_OFF) then
            setbytes(0x00, 0x05, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["cool_target_temperature"] then
            set_tembytes(0x01, 0x05, control["cool_target_temperature"], 0x00,
                         0x00, bodyBytes)
        end
        if control["ice_target_temperature"] then
            set_tembytes(0x02, 0x05, control["ice_target_temperature"], 0x00,
                         0x00, bodyBytes)
        end
        if (control["antifreeze"] and control["antifreeze"] == VALUE_ON) then
            setbytes(0x03, 0x05, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["antifreeze"] and control["antifreeze"] == VALUE_OFF) then
            setbytes(0x03, 0x05, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["ice"] and control["ice"] == VALUE_ON) then
            setbytes(0x04, 0x05, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["ice"] and control["ice"] == VALUE_OFF) then
            setbytes(0x04, 0x05, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["cold_water_reflux_switch"] and
            control["cold_water_reflux_switch"] == VALUE_ON) then
            setbytes(0x05, 0x05, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["cold_water_reflux_switch"] and
            control["cold_water_reflux_switch"] == VALUE_OFF) then
            setbytes(0x05, 0x05, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["cold_water_reflux_hour"] then
            set_tembytes(0x06, 0x05, control["cold_water_reflux_hour"], 0x00,
                         0x00, bodyBytes)
        end
        if control["ice_size"] then
            set_tembytes(0x07, 0x05, control["ice_size"], 0x00, 0x00, bodyBytes)
        end
        if control["heat_start"] then
            setbytes(0x05, 0x04, control["heat_start"], 0x00, 0x00, bodyBytes)
        end
        if control["single_max_water_consumption"] then
            setbytes(0x00, 0x06, control["single_max_water_consumption"], 0x00,
                     0x00, bodyBytes)
        end
        if control["single_max_water_time"] then
            setbytes(0x01, 0x06, control["single_max_water_time"], 0x00, 0x00,
                     bodyBytes)
        end
        if (control["open_close_switch"] and control["open_close_switch"] ==
            VALUE_ON) then
            setbytes(0x02, 0x06, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["open_close_switch"] and control["open_close_switch"] ==
            VALUE_OFF) then
            setbytes(0x02, 0x06, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["open_close_water_pressure"] and
            control["open_close_water_pressure"] == VALUE_ON) then
            setbytes(0x03, 0x06, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["open_close_water_pressure"] and
            control["open_close_water_pressure"] == VALUE_OFF) then
            setbytes(0x03, 0x06, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["start_clean"] and control["start_clean"] == VALUE_ON) then
            setbytes(0x04, 0x06, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["start_clean"] and control["start_clean"] == VALUE_OFF) then
            setbytes(0x04, 0x06, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["clean_interval"] then
            setbytes(0x05, 0x06, control["clean_interval"], 0x00, 0x00,
                     bodyBytes)
        end
        if control["clean_water_consumption"] then
            setbytes(0x06, 0x06, control["clean_water_consumption"], 0x00, 0x00,
                     bodyBytes)
        end
        if control["clean_time"] then
            setbytes(0x07, 0x06, control["clean_time"], 0x00, 0x00, bodyBytes)
        end
        if (control["leak_water_protect"] and control["leak_water_protect"] ==
            VALUE_ON) then
            setbytes(0x0A, 0x06, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["leak_water_protect"] and control["leak_water_protect"] ==
            VALUE_OFF) then
            setbytes(0x0A, 0x06, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["water_hardness"] then
            setbytes(0x00, 0x09, 0x00, control['water_hardness'] % 256,
                     bit.rshift(control['water_hardness'], 8), bodyBytes)
        end
        if control["flushing_days"] then
            setbytes(0x01, 0x09, 0x00, control['flushing_days'] % 256,
                     bit.rshift(control['flushing_days'], 8), bodyBytes)
        end
        if control["timing_regeneration_hour"] then
            if control["timing_regeneration_min"] then
                setbytes(0x02, 0x09, 0x00, control['timing_regeneration_hour'],
                         control["timing_regeneration_min"], bodyBytes)
            else
                setbytes(0x02, 0x09, 0x00, control['timing_regeneration_hour'],
                         0x00, bodyBytes)
            end
        end
        if control["salt_setting"] then
            setbytes(0x03, 0x09, 0x00, control['salt_setting'] % 256,
                     bit.rshift(control['salt_setting'], 8), bodyBytes)
        end
        if (control["regeneration"] and control["regeneration"] == VALUE_ON) then
            setbytes(0x05, 0x09, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["regeneration"] and control["regeneration"] == VALUE_OFF) then
            setbytes(0x05, 0x09, 0x00, 0x00, 0x00, bodyBytes)
        elseif control["regeneration"] ~= nil then
            setbytes(0x05, 0x09, control["regeneration"], 0x00, 0x00, bodyBytes)
        end
        if (control["soften"] and control["soften"] == VALUE_ON) then
            setbytes(0x06, 0x09, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["soften"] and control["soften"] == VALUE_OFF) then
            setbytes(0x06, 0x09, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["water_way"] and control["water_way"] == VALUE_ON) then
            setbytes(0x07, 0x09, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["water_way"] and control["water_way"] == VALUE_OFF) then
            setbytes(0x07, 0x09, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["mixed_water_gear"] then
            setbytes(0x08, 0x09, control["mixed_water_gear"], 0x00, 0x00,
                     bodyBytes)
        end
        if (control["leak_water_protection"] and
            control["leak_water_protection"] == VALUE_ON) then
            if control["leak_water_protection_value"] then
                setbytes(0x09, 0x09, 0x01,
                         control['leak_water_protection_value'] % 256,
                         bit.rshift(control['leak_water_protection_value'], 8),
                         bodyBytes)
            else
                setbytes(0x09, 0x09, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["leak_water_protection"] and
            control["leak_water_protection"] == VALUE_OFF) then
            if control["leak_water_protection_value"] then
                setbytes(0x09, 0x09, 0x00,
                         control['leak_water_protection_value'] % 256,
                         bit.rshift(control['leak_water_protection_value'], 8),
                         bodyBytes)
            else
                setbytes(0x09, 0x09, 0x00, 0x00, 0x00, bodyBytes)
            end
        end
        if (control["micro_leak_protection"] and
            control["micro_leak_protection"] == VALUE_ON) then
            if control["micro_leak_protection_value"] then
                setbytes(0x0A, 0x09, 0x01,
                         control['micro_leak_protection_value'] % 256,
                         bit.rshift(control['micro_leak_protection_value'], 8),
                         bodyBytes)
            else
                setbytes(0x0A, 0x09, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["micro_leak_protection"] and
            control["micro_leak_protection"] == VALUE_OFF) then
            if control["micro_leak_protection_value"] then
                setbytes(0x0A, 0x09, 0x00,
                         control['micro_leak_protection_value'] % 256,
                         bit.rshift(control['micro_leak_protection_value'], 8),
                         bodyBytes)
            else
                setbytes(0x0A, 0x09, 0x00, 0x00, 0x00, bodyBytes)
            end
        end
        if (control["cl_sterilization"] and control["cl_sterilization"] ==
            VALUE_ON) then
            setbytes(0x0C, 0x09, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["cl_sterilization"] and control["cl_sterilization"] ==
            VALUE_OFF) then
            setbytes(0x0C, 0x09, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["real_date_setting_year"] ~= nil then
            if control["real_date_setting_month"] ~= nil then
                if control["real_date_setting_day"] ~= nil then
                    setbytes(0x0D, 0x09, control["real_date_setting_year"],
                             control["real_date_setting_month"],
                             control["real_date_setting_day"], bodyBytes)
                else
                    setbytes(0x0D, 0x09, control["real_date_setting_year"],
                             control["real_date_setting_month"], 0x00, bodyBytes)
                end
            else
                setbytes(0x0D, 0x09, control["real_date_setting_year"], 0x00,
                         0x00, bodyBytes)
            end
        end
        if control["real_time_setting_hour"] ~= nil then
            if control["real_time_setting_min"] ~= nil then
                setbytes(0x0E, 0x09, 0x00, control["real_time_setting_hour"],
                         control["real_time_setting_min"], bodyBytes)
            else
                setbytes(0x0E, 0x09, 0x00, control["real_time_setting_hour"],
                         0x00, bodyBytes)
            end
        end
        if (control["maintenance_reminder_switch"] ~= nil and
            control["maintenance_reminder_switch"] == VALUE_ON) then
            if control["maintenance_reminder_setting"] then
                setbytes(0x0F, 0x09, 0x01,
                         control['maintenance_reminder_setting'] % 256,
                         bit.rshift(control['maintenance_reminder_setting'], 8),
                         bodyBytes)
            else
                setbytes(0x0F, 0x09, 0x01, 0x00, 0x00, bodyBytes)
            end
        elseif (control["maintenance_reminder_switch"] and
            control["maintenance_reminder_switch"] == VALUE_OFF) then
            if control["maintenance_reminder_setting"] then
                setbytes(0x0F, 0x09, 0x00,
                         control['maintenance_reminder_setting'] % 256,
                         bit.rshift(control['maintenance_reminder_setting'], 8),
                         bodyBytes)
            else
                setbytes(0x0F, 0x09, 0x00, 0x00, 0x00, bodyBytes)
            end
        end
        if control["cleaning_days"] then
            setbytes(0x10, 0x09, 0x00, control['cleaning_days'] % 256,
                     bit.rshift(control['cleaning_days'], 8), bodyBytes)
        end
        if control["timing_cleaning_hour"] then
            if control["timing_cleaning_min"] then
                setbytes(0x11, 0x09, 0x00, control['timing_cleaning_hour'],
                         control["timing_cleaning_min"], bodyBytes)
            else
                setbytes(0x11, 0x09, 0x00, control['timing_cleaning_hour'],
                         0x00, bodyBytes)
            end
        end
        if (control["clean"] and control["clean"] == VALUE_ON) then
            setbytes(0x12, 0x09, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["clean"] and control["clean"] == VALUE_OFF) then
            setbytes(0x12, 0x09, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["filter_switch"] and control["filter_switch"] == VALUE_ON) then
            setbytes(0x13, 0x09, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["filter_switch"] and control["filter_switch"] ==
            VALUE_OFF) then
            setbytes(0x13, 0x09, 0x00, 0x00, 0x00, bodyBytes)
        end
        if (control["factory_reset"] and control["factory_reset"] == VALUE_ON) then
            setbytes(0x15, 0x09, 0x01, 0x00, 0x00, bodyBytes)
        elseif (control["factory_reset"] and control["factory_reset"] ==
            VALUE_OFF) then
            setbytes(0x15, 0x09, 0x00, 0x00, 0x00, bodyBytes)
        end
        if control["regenerate_drainage"] ~= nil then
            setbytes(0x16, 0x09, control["regenerate_drainage"], 0x00, 0x00,
                     bodyBytes)
        end
        if #bodyBytes > 2 then
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        end
    elseif (query) then
        local bodyLength = 2
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0xff
        bodyBytes[1] = 0x01
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
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
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10]
    bodyBytes = extractBodyBytes(byteData)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty(bodyBytes)
    local ret = encodeTableToJson(retTable)
    return ret
end
