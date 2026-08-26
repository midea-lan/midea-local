local cloud_bl = true
local JSON = require 'cjson'
local KEY_VERSION = 'version'
local VALUE_UNKNOWN = 'unknown'
local VALUE_INVALID = 'invalid'
local VALUE_VERSION = 1

function jsonToData(jsonCmdStr)
    if jsonCmdStr == nil or #jsonCmdStr == 0 then
        return nil
    end
    local t = decodeJsonStrToTable(jsonCmdStr)
    local control = t.control
    local query = t.query
    local status = t.status
    if control then
        tdlist = {
            [0] = 0xAA,
            [1] = 0x14,
            [2] = 0xB7,
            [3] = 0x00,
            [4] = 0x00,
            [5] = 0x00,
            [6] = 0x00,
            [7] = 0x00,
            [8] = 0x01,
            [9] = 0x02,
            [10] = 0x21,
            [11] = 0x00,
            [12] = 0x00,
            [13] = 0x00,
            [14] = 0x00,
            [15] = 0x00,
            [16] = 0x00,
            [17] = 0x00,
            [18] = 0x00,
            [19] = 0x00,
            [20] = 0x00,
            [21] = 0x00,
            [22] = 0x00,
            [23] = 0x00,
            [24] = 0x00,
            [25] = 0x00,
            [26] = 0x00,
            [27] = 0x00,
            [28] = 0x00,
            [29] = 0x00
        }
        local switch_mode = {
            ['0'] = function()
                for i = #tdlist, 10, -1 do
                    table.remove(tdlist, i)
                end
                if control.query_type ~= nil then
                    tdlist[9] = 3
                    tdlist[10] = control.query_type
                    if control.query_type == '50' then
                        tdlist[11] = '03'
                    end
                end
            end,
            ['1'] = function()
                for i = #tdlist, 21, -1 do
                    table.remove(tdlist, i)
                end
                if control.function_control ~= nil then
                    tdlist[11] = 0x01
                    tdlist[12] = control.function_control
                    if tdlist[12] == '3' then
                        if control.left_gear ~= nil then
                            tdlist[15] = control.left_gear
                        end
                    elseif tdlist[12] == '4' then
                        if control.left_surplus_hours ~= nil then
                            tdlist[13] = control.left_surplus_hours
                        end
                        if control.left_surplus_minutes ~= nil then
                            tdlist[14] = control.left_surplus_minutes
                        end
                    elseif tdlist[12] == '11' or tdlist[12] == '12' or tdlist[12] == '13' or tdlist[12] == '14' then
                        if control.left_temp ~= nil then
                            tdlist[17] = control.left_temp % 256
                            tdlist[16] = (control.left_temp - tdlist[17]) / 256
                        end
                    end
                end
            end,
            ['2'] = function()
                for i = #tdlist, 21, -1 do
                    table.remove(tdlist, i)
                end
                if control.function_control ~= nil then
                    tdlist[11] = 0x02
                    tdlist[12] = control.function_control
                    if tdlist[12] == '3' then
                        if control.right_gear ~= nil then
                            tdlist[15] = control.right_gear
                        end
                        if control.right_temp ~= nil then
                            tdlist[15] = control.right_temp
                        end
                    elseif tdlist[12] == '4' then
                        if control.right_surplus_hours ~= nil then
                            tdlist[13] = control.right_surplus_hours
                        end
                        if control.right_surplus_minutes ~= nil then
                            tdlist[14] = control.right_surplus_minutes
                        end
                    elseif tdlist[12] == '11' or tdlist[12] == '12' or tdlist[12] == '13' or tdlist[12] == '14' then
                        if control.right_temp ~= nil then
                            tdlist[19] = control.right_temp % 256
                            tdlist[18] = (control.right_temp - tdlist[19]) / 256
                        end
                    end
                end
            end,
            ['3'] = function()
                for i = #tdlist, 21, -1 do
                    table.remove(tdlist, i)
                end
                tdlist[11] = 0x03
                if control.function_control == '1' then
                    tdlist[12] = control.function_control
                end
                if control.lock == '0' then
                    tdlist[12] = 0x07
                elseif control.lock == '1' then
                    tdlist[12] = 0x08
                end
            end,
            ['4'] = function()
                for i = #tdlist, 19, -1 do
                    table.remove(tdlist, i)
                end
                tdlist[10] = 0x27
                if control.bind_pot ~= nil then
                    tdlist[11] = control.bind_pot
                    if tdlist[11] == '1' then
                        if (control.bind_mac_add) then
                            mac_temp = control.bind_mac_add
                            local straw = {}
                            j = 12
                            for i = 0, 5, 1 do
                                j = j + 1
                                straw[i] = string.sub(mac_temp, 1, 2)
                                mac_temp = string.sub(mac_temp, 3, -1)
                                tdlist[j] = tonumber(straw[i], 16)
                            end
                        end
                    elseif tdlist[11] == '3' then
                    end
                end
            end,
            ['5'] = function()
                tdlist[10] = 0xCA
                if control.dl_menu ~= nil then
                    tdlist[11] = control.dl_menu
                    if tdlist[11] == '1' then
                        if control.dl_menu_id then
                            tdlist[14] = control.dl_menu_id % 256
                            tdlist[13] = (control.dl_menu_id - tdlist[14]) / 256
                            if tdlist[13] >= 256 then
                                tdlist[12] = (tdlist[13] - tdlist[13] % 256) / 256
                                tdlist[13] = tdlist[13] % 256
                            end
                        end
                        if control.dl_menu_link_str ~= nil then
                            tdlist[32] = #control.dl_menu_link_str
                        end
                        if control.dl_menu_link_str ~= nil then
                            k = 32
                            local dl_char_array = {}
                            for i = 0, #control.dl_menu_link_str - 1, 1 do
                                k = k + 1
                                dl_char_array[i] = string.byte(control.dl_menu_link_str, i + 1)
                                tdlist[k] = dl_char_array[i]
                            end
                        end
                        if dl_menu_pid ~= nil then
                            tdlist[15] = dl_menu_pid
                        end
                        if control.dl_menu_md5 ~= nil then
                            md5_temp = control.dl_menu_md5
                            local straw2 = {}
                            j = 15
                            for i = 0, 15, 1 do
                                j = j + 1
                                straw2[i] = string.sub(md5_temp, 1, 2)
                                md5_temp = string.sub(md5_temp, 3, -1)
                                tdlist[j] = tonumber(straw2[i], 16)
                            end
                        end
                    end
                end
            end,
            ['6'] = function()
                for i = #tdlist, 21, -1 do
                    table.remove(tdlist, i)
                end
                tdlist[11] = 0x04
                tdlist[12] = control.function_control
                tdlist[20] = control.pots[1].pot_id
                pot_temp_moren = 0
                if control.pots[1].pot_temp_chao then
                    pot_temp_moren = control.pots[1].pot_temp_chao
                elseif control.pots[1].pot_temp_dun then
                    pot_temp_moren = control.pots[1].pot_temp_dun
                elseif control.pots[1].pot_temp_zha then
                    pot_temp_moren = control.pots[1].pot_temp_zha
                end
                tdlist[17] = pot_temp_moren % 256
                tdlist[16] = (pot_temp_moren - tdlist[17]) / 256
            end}
        if control.work_burner_control ~= nil then
            switch_mode[control.work_burner_control]()
        end
        tdlist[#tdlist + 1] = 0
        tdlist[1] = #tdlist
        tdlist[#tdlist] = checkSum(tdlist)
        return byteArrayToHexStr(tdlist)
    elseif query then
        if query.query_type then
            if query.query_type == '31' then
                query_cmd = 'AA0BB7000000000001033109'
            elseif query.query_type == '32' then
                query_cmd = 'AA0CB700000000000103320304'
            elseif query.query_type == '37' then
                query_cmd = 'AA0BB7000000000001033703'
            elseif query.query_type == '202' then
                query_cmd = 'AA0BB700000000000103CA70'
            end
        else
            query_cmd = 'AA0BB7000000000001033109'
        end
        return query_cmd
    end
end

function dataToJson(jsonCmdStr)
    local result = {
        status = {
            left_status = 0,
            right_status = 0,
            lock = 0,
            left_gear = 0,
            right_gear = 0,
            left_surplus_hours = 0,
            left_surplus_minutes = 0,
            right_surplus_hours = 0,
            right_surplus_minutes = 0,
            error_code = 0,
            tips_code = 0,
            fail_resp_reason = 0
        }
    }
    if jsonCmdStr == nil or #jsonCmdStr == 0 then
        return nil
    end
    local t = decodeJsonStrToTable(jsonCmdStr)
    if t.msg == nil or t.msg.data == nil then
        return nil
    end
    cmdStr = t.msg.data
    bytecmd = {}
    for i = 0, (#cmdStr / 2), 1 do
        if getByte(cmdStr, i) then
            bytecmd[i] = getByte(cmdStr, i)
        else
            bytecmd[i] = 00
        end
    end
    if bytecmd[9] == '04' and bytecmd[10] == '41' or bytecmd[9] == '03' and bytecmd[10] == '31' then
        result.status.left_status = tonumber(bytecmd[11], 16)
        result.status.right_status = tonumber(bytecmd[12], 16)
        result.status.left_surplus_hours = tonumber(bytecmd[13], 16)
        result.status.left_surplus_minutes = tonumber(bytecmd[14], 16)
        result.status.right_surplus_hours = tonumber(bytecmd[18], 16)
        result.status.right_surplus_minutes = tonumber(bytecmd[19], 16)
        result.status.left_gear = tonumber(bytecmd[23], 16)
        result.status.right_gear = tonumber(bytecmd[24], 16)
        result.status.lock = getBit(bytecmd[27], 0)
        if bytecmd[50] then
            result.status.left_temp = bytecmd[48] and tonumber(bytecmd[47], 16) * 256 + tonumber(bytecmd[48], 16) or 0
            result.status.right_temp = bytecmd[50] and tonumber(bytecmd[49], 16) * 256 + tonumber(bytecmd[50], 16) or 0
        end
        result.status.menu_mark = getBit(bytecmd[27], 1)
        result.status.left_smart_bl = getBit(bytecmd[27], 5)
        result.status.right_smart_bl = getBit(bytecmd[27], 4)
        result.status.left_work_mode = tonumber(bytecmd[25], 16)
        result.status.right_work_mode = tonumber(bytecmd[26], 16)
        result.status.gas_warn = getBit(bytecmd[27], 3)
        result.status.left_work_hours = tonumber(bytecmd[15], 16)
        result.status.left_work_minutes = tonumber(bytecmd[16], 16)
        result.status.left_work_seconds = tonumber(bytecmd[17], 16)
        result.status.right_work_hours = tonumber(bytecmd[20], 16)
        result.status.right_work_minutes = tonumber(bytecmd[21], 16)
        result.status.right_work_seconds = tonumber(bytecmd[22], 16)
        result.status.pots = {}
        local pots_mount = (#cmdStr / 2 - 34) / 17
        for i = 1, pots_mount, 1 do
            result.status.pots[i] = {}
            math_front = i == 1 and 28 + 18 * (i - 1) or 32 + 18 * (i - 1)
            if i == 1 then
                result.status.pots[i].bind_pot_bl = getBit(bytecmd[28], 3)
                result.status.pots[i].bind_pot_online_bl = getBit(bytecmd[28], 2)
            elseif i == 2 then
                result.status.pots[i].bind_pot_bl = getBit(bytecmd[28], 7)
                result.status.pots[i].bind_pot_online_bl = getBit(bytecmd[28], 6)
            end
            result.status.pots[i].pot_id = tonumber(bytecmd[math_front + 6], 16)
            result.status.pots[i].pot_bat = tonumber(bytecmd[math_front + 5], 16)
            if getBit(bytecmd[math_front + 11], 7) == 1 then
                result.status.pots[i].pot_work_side = 1
            elseif getBit(bytecmd[math_front + 11], 6) == 1 then
                result.status.pots[i].pot_work_side = 2
            else
                result.status.pots[i].pot_work_side = 0
            end
            if getBit(bytecmd[math_front + 11], 4) == 1 then
                result.status.pots[i].pot_menu_mode = 1
            elseif getBit(bytecmd[math_front + 11], 5) == 1 then
                result.status.pots[i].pot_menu_mode = 2
            else
                result.status.pots[i].pot_menu_mode = 0
            end
            if getBit(bytecmd[math_front + 11], 0) == 1 then
                result.status.pots[i].pot_menu_dl_state = 1
            elseif getBit(bytecmd[math_front + 11], 0) == 0 then
                result.status.pots[i].pot_menu_dl_state = 2
            else
                result.status.pots[i].pot_menu_dl_state = 0
            end
            if getBit(bytecmd[math_front + 11], 3) == 1 then
                result.status.pots[i].pot_menu_next_med = 1
            elseif getBit(bytecmd[math_front + 11], 2) == 1 then
                result.status.pots[i].pot_menu_next_med = 2
            elseif getBit(bytecmd[math_front + 11], 1) == 1 then
                result.status.pots[i].pot_menu_next_med = 3
            else
                result.status.pots[i].pot_menu_next_med = 0
            end
            result.status.pots[i].pot_menu_step = tonumber(bytecmd[math_front + 9], 16)
            result.status.pots[i].pot_menu_step_dt = tonumber(bytecmd[math_front + 10], 16)
            result.status.pots[i].pot_temp_menu_tag = tonumber(bytecmd[math_front + 7], 16) * 255 + tonumber(bytecmd[math_front + 8], 16)
            result.status.pots[i].pot_temp_top = tonumber(bytecmd[math_front + 1], 16) * 255 + tonumber(bytecmd[math_front + 2], 16)
            result.status.pots[i].pot_temp_bot = tonumber(bytecmd[math_front + 3], 16) * 255 + tonumber(bytecmd[math_front + 4], 16)
            result.status.pots[i].pot_temp_chao = tonumber(bytecmd[math_front + 13], 16) * 255 + tonumber(bytecmd[math_front + 14], 16)
            result.status.pots[i].pot_temp_dun = tonumber(bytecmd[math_front + 15], 16) * 255 + tonumber(bytecmd[math_front + 16], 16)
            result.status.pots[i].pot_temp_zha = tonumber(bytecmd[math_front + 17], 16) * 255 + tonumber(bytecmd[math_front + 18], 16)
            result.status.pots[i].pot_temp_dadao = tonumber(bytecmd[math_front + 12], 16)
        end
    elseif bytecmd[9] == '04' and bytecmd[10] == '47' or bytecmd[9] == '03' and bytecmd[10] == '37' then
        result.status.bt_device_mount = tonumber(bytecmd[11], 16)
        if result.status.bt_device_mount ~= 0 and result.status.bt_device_mount ~= 255 then
            result.status.bt_device = {}
            for i = 1, result.status.bt_device_mount, 1 do
                result.status.bt_device[i] = {}
                math_front = 11 + 12 * (i - 1)
                result.status.bt_device[i].bt_device_type = tonumber(bytecmd[math_front + 1], 16)
                result.status.bt_device[i].bt_device_mac = ''
                j = math_front + 1
                for k = 0, 5, 1 do
                    j = j + 1
                    result.status.bt_device[i].bt_device_mac = result.status.bt_device[i].bt_device_mac .. bytecmd[j]
                end
                result.status.bt_device[i].bt_device_cp = tonumber(bytecmd[math_front + 8], 16)
                result.status.bt_device[i].bt_device_sname = string.char(tonumber(bytecmd[math_front + 9], 16)) ..
                        string.char(tonumber(bytecmd[math_front + 10], 16)) ..
                        string.char(tonumber(bytecmd[math_front + 11], 16))
                result.status.bt_device[i].bt_device_mac_bind_bl = tonumber(bytecmd[math_front + 12], 16)
            end
        end
    elseif
    bytecmd[9] == '04' and bytecmd[10] == 'CA' or bytecmd[9] == '03' and bytecmd[10] == 'CA' or
            bytecmd[9] == '04' and bytecmd[10] == 'ca' or
            bytecmd[9] == '03' and bytecmd[10] == 'ca'
    then
        result.status.dl_menu = tonumber(bytecmd[11], 16)
        result.status.dl_menu_pid = tonumber(bytecmd[15], 16)
        result.status.dl_menu_process = tonumber(bytecmd[16], 16)
        result.status.dl_menu_md5 = ''
        j = 16
        for i = 0, 15, 1 do
            j = j + 1
            result.status.dl_menu_md5 = result.status.dl_menu_md5 .. bytecmd[j]
        end
        k = 33
        result.status.dl_menu_link_str_len = tonumber(bytecmd[33], 16)
        result.status.dl_menu_link_str = ''
        for i = 0, result.status.dl_menu_link_str_len - 1, 1 do
            k = k + 1
            result.status.dl_menu_link_str = result.status.dl_menu_link_str .. string.char(tonumber(bytecmd[k], 16))
        end
    elseif bytecmd[9] == '03' and bytecmd[10] == '32' then
        if bytecmd[11] == '03' then
            for i = 0, 7 do
                bitN = getBit(bytecmd[12], i)
                if bitN == '1' then
                    result.status.error_code = i + 1
                    return encodeTableToJson(result)
                end
            end
            for i = 0, 7 do
                bitN = getBit(bytecmd[13], i)
                if bitN == '1' then
                    result.status.error_code = i + 9
                    return encodeTableToJson(result)
                end
            end
            for i = 0, 5 do
                bitN = getBit(bytecmd[14], i)
                if bitN == '1' then
                    result.status.tips_code = i + 1
                    return encodeTableToJson(result)
                end
            end
            for i = 0, 1 do
                bitN = getBit(bytecmd[15], i)
                if bitN == '1' then
                    result.status.tips_code = i + 7
                    return encodeTableToJson(result)
                end
            end
        end
    elseif bytecmd[9] == '02' then
        if bytecmd[11] == 'FE' then
            result.status.fail_resp_reason = tonumber(bytecmd[13], 16)
        end
    end
    return encodeTableToJson(result)
end

function decodeJsonStrToTable(cmd)
    local tb
    if JSON == nil then
        JSON = require 'cjson'
    end
    tb = JSON.decode(cmd)
    return tb
end

function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then
        JSON = require 'cjson'
    end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
end

function checkSum(data)
    local total = 0
    local i
    for i, v in pairs(data) do
        total = total + v
    end
    total = total - 0xAA
    total = total % 256
    total = 0x100 - total
    return total % 256
end

function byteArrayToHexStr(byteTable)
    local hexStr = ''
    local length = #byteTable
    for i = 0, length, 1 do
        hexStr = hexStr .. string.format('%02X', byteTable[i])
    end
    return hexStr
end

function getByte(frame, index)
    index = index + 1
    local byt = string.sub(frame, index * 2 - 1, index * 2)
    return byt
end

function getBit(oneByte, bitIndex)
    local bytes_high = tonumber(string.sub(oneByte, 1, 1), 16)
    local bytes_low = tonumber(string.sub(oneByte, 2, 2), 16)
    if bitIndex > 3 and bitIndex < 8 then
        if bitIndex == 7 then
            if bit_band(bytes_high, 8) == 8 then
                return '1'
            end
        elseif bitIndex == 6 then
            if bit_band(bytes_high, 4) == 4 then
                return '1'
            end
        elseif bitIndex == 5 then
            if bit_band(bytes_high, 2) == 2 then
                return '1'
            end
        elseif bitIndex == 4 then
            if bit_band(bytes_high, 1) == 1 then
                return '1'
            end
        end
        return '0'
    elseif bitIndex >= 0 and bitIndex <= 3 then
        if bitIndex == 3 then
            if bit_band(bytes_low, 8) == 8 then
                return '1'
            end
        elseif bitIndex == 2 then
            if bit_band(bytes_low, 4) == 4 then
                return '1'
            end
        elseif bitIndex == 1 then
            if bit_band(bytes_low, 2) == 2 then
                return '1'
            end
        elseif bitIndex == 0 then
            if bit_band(bytes_low, 1) == 1 then
                return '1'
            end
        end
        return '0'
    end
    return '2'
end

function bit_band(a, b)
    local ret
    if (cloud_bl) then
        ret = bit.band(a, b)
    else
        ret = bit32.band(a, b)
    end
    return ret
end

function tenToSixteen(src)
    src = tonumber(src)
    return string.format('%#x', src)
end

function sixteenToTen(src)
    src = tonumber(src, 16)
    return string.format('%d', src)
end
