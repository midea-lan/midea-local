local bit = require "bit"
local VALUE_VERSION = 9
local JSON = require "cjson"
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
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
local function tempTransformation(temp)
    local result = 0
    local num = tonumber(temp)
    if (num >= 128) then
        result = result - (num - 128)
    else
        result = num
    end
    return result
end
local function assembleByteFromJson(result, msgBytes)
    local query = result["query"]
    local control = result["control"]
    if (control) then
        msgBytes[10] = 0x02
        for i = 11, 30 do msgBytes[i] = 0x00 end
        if (control["power"] and control["power"] == "on") then
            msgBytes[11] = 0x01
            msgBytes[12] = 0x01
        elseif (control["power"] and control["power"] == "off") then
            msgBytes[11] = 0x02
            msgBytes[12] = 0x01
        else
            msgBytes[11] = 0x04
            if (control["winter_mode"] and control["winter_mode"] == "on" or
                control["summer_mode"] and control["summer_mode"] == "off") then
                msgBytes[12] = 0x01
                msgBytes[13] = 0x01
            elseif (control["winter_mode"] and control["winter_mode"] == "off" or
                control["summer_mode"] and control["summer_mode"] == "on") then
                msgBytes[12] = 0x01
                msgBytes[13] = 0x02
            elseif (control["mode"] and control["mode"] == "normal_mode") then
                msgBytes[12] = 0x02
                msgBytes[13] = 0x01
            elseif (control["mode"] and control["mode"] == "out_mode") then
                msgBytes[12] = 0x02
                msgBytes[13] = 0x02
            elseif (control["mode"] and control["mode"] == "home_mode") then
                msgBytes[12] = 0x02
                msgBytes[13] = 0x04
            elseif (control["mode"] and control["mode"] == "sleep_mode") then
                msgBytes[12] = 0x02
                msgBytes[13] = 0x08
            elseif (control["heat_mode"]) then
                msgBytes[12] = 0x02
                msgBytes[14] = control["heat_mode"]
            elseif (control["current_heat_set_temperature"]) then
                msgBytes[12] = 0x13
                msgBytes[13] = control["current_heat_set_temperature"]
            elseif (control["current_bath_set_temperature"]) then
                msgBytes[12] = 0x12
                msgBytes[13] = control["current_bath_set_temperature"]
            elseif (control["exclusive_temperature"]) then
                msgBytes[12] = 0x16
                msgBytes[13] = control["exclusive_temperature"]
                if (control["exclusive_temperature_switch"] and
                    control["exclusive_temperature_switch"] == "on") then
                    msgBytes[14] = 0x01
                elseif (control["exclusive_temperature_switch"] and
                    control["exclusive_temperature_switch"] == "off") then
                    msgBytes[14] = 0x00
                end
            elseif (control["exclusive_temperature_2"]) then
                msgBytes[12] = 0x16
                msgBytes[15] = control["exclusive_temperature_2"]
                if (control["exclusive_temperature_switch_2"] and
                    control["exclusive_temperature_switch_2"] == "on") then
                    msgBytes[16] = 0x01
                elseif (control["exclusive_temperature_switch_2"] and
                    control["exclusive_temperature_switch_2"] == "off") then
                    msgBytes[16] = 0x00
                end
            elseif (control["exclusive_temperature_3"]) then
                msgBytes[12] = 0x16
                msgBytes[17] = control["exclusive_temperature_3"]
                if (control["exclusive_temperature_switch_3"] and
                    control["exclusive_temperature_switch_3"] == "on") then
                    msgBytes[18] = 0x01
                elseif (control["exclusive_temperature_switch_3"] and
                    control["exclusive_temperature_switch_3"] == "off") then
                    msgBytes[18] = 0x00
                end
            elseif (control["temperature_sensation_switch"] and
                control["temperature_sensation_switch"] == "on") then
                msgBytes[12] = 0x15
                msgBytes[13] = 0x01
            elseif (control["temperature_sensation_switch"] and
                control["temperature_sensation_switch"] == "off") then
                msgBytes[12] = 0x15
                msgBytes[13] = 0x00
            elseif (control["heat_appointment_switch"] and
                control["heat_appointment_switch"] == "off") then
                msgBytes[11] = 0x0A
                msgBytes[12] = 0x01
                msgBytes[13] = 0x00
                msgBytes[14] = 0x00
                msgBytes[15] = 0x00
            elseif (control["bath_mode"]) then
                msgBytes[12] = 0x18
                msgBytes[13] = control["bath_mode"]
                if (control["mode_temperature"]) then
                    msgBytes[14] = control["mode_temperature"]
                end
            elseif (control["buzzing_master_switch"] and
                control["buzzing_master_switch"] == "no_buzzing") then
                msgBytes[12] = 0x17
                msgBytes[13] = 0x01
            elseif (control["buzzing_master_switch"] and
                control["buzzing_master_switch"] == "buzzing") then
                msgBytes[12] = 0x17
                msgBytes[13] = 0x00
            elseif (control["reset_filter"] and control["reset_filter"] == 'on') then
                msgBytes[12] = 0x19
                msgBytes[13] = 0x01
            elseif (control["cold_water_single"] and
                control["cold_water_single"] == "on") then
                msgBytes[12] = 0x1A
                msgBytes[13] = 0x01
            elseif (control["cold_water_single"] and
                control["cold_water_single"] == "off") then
                msgBytes[12] = 0x1A
                msgBytes[13] = 0x00
            elseif (control["cold_water_dot"] and control["cold_water_dot"] ==
                "on") then
                msgBytes[12] = 0x1B
                msgBytes[13] = 0x01
            elseif (control["cold_water_dot"] and control["cold_water_dot"] ==
                "off") then
                msgBytes[12] = 0x1B
                msgBytes[13] = 0x00
            elseif (control["cold_water_appoint_switch"] and
                control["cold_water_appoint_switch"] == "on") then
                msgBytes[12] = 0x1C
                msgBytes[13] = 0x01
            elseif (control["cold_water_appoint_switch"] and
                control["cold_water_appoint_switch"] == "off") then
                msgBytes[12] = 0x1C
                msgBytes[13] = 0x00
            elseif (control["cold_water_has_enabled_appoint"] and
                control["cold_water_has_enabled_appoint"] == "on") then
                msgBytes[12] = 0x1D
                msgBytes[13] = 0x01
            elseif (control["cold_water_has_enabled_appoint"] and
                control["cold_water_has_enabled_appoint"] == "off") then
                msgBytes[12] = 0x1D
                msgBytes[13] = 0x00
            elseif (control["cold_water_appoint_master"] and
                control["cold_water_appoint_master"] == "on") then
                msgBytes[12] = 0x1E
                msgBytes[13] = 0x01
            elseif (control["cold_water_appoint_master"] and
                control["cold_water_appoint_master"] == "off") then
                msgBytes[12] = 0x1E
                msgBytes[13] = 0x00
            elseif (control["cold_water_master"] and
                control["cold_water_master"] == "on") then
                msgBytes[12] = 0x1F
                msgBytes[13] = 0x01
            elseif (control["cold_water_master"] and
                control["cold_water_master"] == "off") then
                msgBytes[12] = 0x1F
                msgBytes[13] = 0x00
            elseif (control["half_pipe_time"]) then
                msgBytes[12] = 0x20
                msgBytes[14] = control["half_pipe_time"]
                if (control["half_pipe_time_switch"] and
                    control["half_pipe_time_switch"] == "on") then
                    msgBytes[13] = 0x01
                elseif (control["half_pipe_time_switch"] and
                    control["half_pipe_time_switch"] == "off") then
                    msgBytes[13] = 0x00
                else
                    msgBytes[13] = 0x01
                end
            elseif (control["cold_water_ai"] and control["cold_water_ai"] ==
                "on") then
                msgBytes[12] = 0x21
                msgBytes[13] = 0x01
            elseif (control["cold_water_ai"] and control["cold_water_ai"] ==
                "off") then
                msgBytes[12] = 0x21
                msgBytes[13] = 0x00
            end
        end
        if (control["buzzing_switch"] and control["buzzing_switch"] ==
            "no_buzzing") then
            msgBytes[30] = 0x01
        elseif (control["buzzing_switch"] and control["buzzing_switch"] ==
            "buzzing") then
            msgBytes[30] = 0x00
        end
    elseif (query) then
        msgBytes[10] = 0x03
        msgBytes[11] = 0x01
        msgBytes[12] = 0x01
        for i = 13, 30 do msgBytes[i] = 0x00 end
    end
    return msgBytes
end
local function parseByteToJson(status, bodyBytes)
    if (bit.band(bodyBytes[13], 0x01) == 0x01) then
        status["antifreezing"] = "first_level_freeze"
    elseif (bit.band(bodyBytes[13], 0x02) == 0x02) then
        status["antifreezing"] = "second_level_freeze"
    else
        status["antifreezing"] = "unfrozen"
    end
    if (bit.band(bodyBytes[13], 0x04) == 0x04) then
        status["power"] = "on"
    else
        status["power"] = "off"
    end
    if (bit.band(bodyBytes[13], 0x08) == 0x08) then
        status["flame_feedback"] = "on"
    else
        status["flame_feedback"] = "off"
    end
    if (bit.band(bodyBytes[13], 0x10) == 0x10) then
        status["heating_work"] = "on"
    else
        status["heating_work"] = "off"
    end
    if (bit.band(bodyBytes[13], 0x20) == 0x20) then
        status["bathing_work"] = "on"
    else
        status["bathing_work"] = "off"
    end
    status["heat_mode"] = tonumber(bodyBytes[14])
    if (bit.band(bodyBytes[15], 0x01) == 0x01) then
        status["winter_mode"] = "on"
    else
        status["winter_mode"] = "off"
    end
    if (bit.band(bodyBytes[15], 0x02) == 0x02) then
        status["summer_mode"] = "on"
    else
        status["summer_mode"] = "off"
    end
    if (bit.band(bodyBytes[15], 0x04) == 0x04) then
        status["mode"] = "normal_mode"
    elseif (bit.band(bodyBytes[15], 0x08) == 0x08) then
        status["mode"] = "out_mode"
    elseif (bit.band(bodyBytes[15], 0x10) == 0x10) then
        status["mode"] = "home_mode"
    elseif (bit.band(bodyBytes[15], 0x20) == 0x20) then
        status["mode"] = "sleep_mode"
    end
    if (bit.band(bodyBytes[16], 0x02) == 0x02) then
        status["temperature_sensation_switch"] = "on"
    else
        status["temperature_sensation_switch"] = "off"
    end
    status["bath_mode"] = tonumber(bodyBytes[16])
    if (bodyBytes[17] == 0x00) then
        status["error"] = "no_error"
    elseif (bodyBytes[17] == 0x01) then
        status["error"] = "ignition_failure"
    elseif (bodyBytes[17] == 0x02) then
        status["error"] = "flameout"
    elseif (bodyBytes[17] == 0x03) then
        status["error"] = "pseudo_fire"
    elseif (bodyBytes[17] == 0x04) then
        status["error"] = "ember"
    elseif (bodyBytes[17] == 0x05) then
        status["error"] = "thermostat_overheating"
    elseif (bodyBytes[17] == 0x06) then
        status["error"] = "temperature_probe_overheating"
    elseif (bodyBytes[17] == 0x07) then
        status["error"] = "fan_failure"
    elseif (bodyBytes[17] == 0x08) then
        status["error"] = "solenoid_valve_failure"
    elseif (bodyBytes[17] == 0x09) then
        status["error"] = "hydraulic_pressure_failure"
    elseif (bodyBytes[17] == 0x0A) then
        status["error"] = "pump_stuck"
    elseif (bodyBytes[17] == 0x0B) then
        status["error"] = "heating_outlet_sensor_short_circuit"
    elseif (bodyBytes[17] == 0x0C) then
        status["error"] = "heating_outlet_sensor_open_circuit"
    elseif (bodyBytes[17] == 0x0D) then
        status["error"] = "freeze_failure"
    elseif (bodyBytes[17] == 0x0E) then
        status["error"] = "bath_outlet_sensor_short_circuit"
    elseif (bodyBytes[17] == 0x0F) then
        status["error"] = "bath_outlet_sensor_open_circuit"
    elseif (bodyBytes[17] == 0x10) then
        status["error"] = "heating_outlet_temperature_failure"
    elseif (bodyBytes[17] == 0x11) then
        status["error"] = "bath_outlet_temperature_failure"
    elseif (bodyBytes[17] == 0x12) then
        status["error"] = "condensate_clogging"
    elseif (bodyBytes[17] == 0x13) then
        status["error"] = "gas_leakage"
    elseif (bodyBytes[17] == 0x14) then
        status["error"] = "communication_failure"
    elseif (bodyBytes[17] == 0x15) then
        status["error"] = "bath_overtime"
    elseif (bodyBytes[17] == 0x16) then
        status["error"] = "co_alarm"
    elseif (bodyBytes[17] == 0x17) then
        status["error"] = "smoke_sensor_short_circuit"
    elseif (bodyBytes[17] == 0x18) then
        status["error"] = "smoke_sensor_open_circuit"
    elseif (bodyBytes[17] == 0x19) then
        status["error"] = "flame_detection_failure"
    end
    status["error_code"] = tonumber(bodyBytes[17])
    status["exclusive_temperature"] = tonumber(bodyBytes[18])
    status["bath_out_water_temperature"] = tonumber(bodyBytes[19])
    status["bath_out_water_temperature_small"] = tonumber(bodyBytes[20])
    status["bath_set_temperature_max"] = tonumber(bodyBytes[21])
    status["bath_set_temperature_min"] = tonumber(bodyBytes[22])
    status["current_bath_set_temperature"] = tonumber(bodyBytes[23])
    status["current_bath_set_temperature_small"] = tonumber(bodyBytes[24])
    status["heat_out_water_temperature"] = tonumber(bodyBytes[25])
    status["heat_set_temperature_max"] = tonumber(bodyBytes[26])
    status["heat_set_temperature_min"] = tonumber(bodyBytes[27])
    status["current_heat_set_temperature"] = tonumber(bodyBytes[28])
    if (bit.band(bodyBytes[29], 0x01) == 0x01) then
        status["fan_type"] = "single_speed"
    elseif (bit.band(bodyBytes[29], 0x02) == 0x02) then
        status["fan_type"] = "double_speed"
    else
        status["fan_type"] = "direct"
    end
    if (bit.band(bodyBytes[29], 0x04) == 0x04) then
        status["gas_valve_manufacturer"] = "aike"
    else
        status["gas_valve_manufacturer"] = "sanguo"
    end
    if (bit.band(bodyBytes[29], 0x08) == 0x08) then
        status["heat_appointment_switch"] = "on"
    else
        status["heat_appointment_switch"] = "off"
    end
    if (bit.band(bodyBytes[29], 0x10) == 0x10) then
        status["appointment"] = "wifi_ap"
    elseif (bit.band(bodyBytes[29], 0x20) == 0x20) then
        status["appointment"] = "wifi_ap_rise"
    elseif (bit.band(bodyBytes[29], 0x30) == 0x30) then
        status["appointment"] = "wifi_ap_sen"
    elseif (bit.band(bodyBytes[29], 0x40) == 0x40) then
        status["appointment"] = "wifi_ap_rise_sen"
    else
        status["appointment"] = "no_wifi"
    end
    status["filter_water"] = bit.lshift(bodyBytes[30], 8) + bodyBytes[31]
    status["proportioner_max_elec"] = tonumber(bodyBytes[32])
    status["proportioner_fire_elec"] = tonumber(bodyBytes[33])
    status["exclusive_temperature_2"] = tonumber(bodyBytes[32])
    status["exclusive_temperature_3"] = tonumber(bodyBytes[33])
    status["heat_back_water_temp_diff"] = tonumber(bodyBytes[34])
    status["half_pipe_time"] = tonumber(bodyBytes[35])
    if (bit.band(bodyBytes[36], 0x01) == 0x01) then
        status["cold_water_single"] = "on"
    else
        status["cold_water_single"] = "off"
    end
    if (bit.band(bodyBytes[36], 0x02) == 0x02) then
        status["cold_water_dot"] = "on"
    else
        status["cold_water_dot"] = "off"
    end
    if (bit.band(bodyBytes[36], 0x04) == 0x04) then
        status["cold_water_appoint_switch"] = "on"
    else
        status["cold_water_appoint_switch"] = "off"
    end
    if (bit.band(bodyBytes[36], 0x08) == 0x08) then
        status["cold_water_master"] = "on"
    else
        status["cold_water_master"] = "off"
    end
    if (bit.band(bodyBytes[36], 0x10) == 0x10) then
        status["heat_exchanger"] = "floor_heating"
    else
        status["heat_exchanger"] = "radiator"
    end
    if (bit.band(bodyBytes[36], 0x20) == 0x20) then
        status["cold_water_appoint_master"] = "on"
    else
        status["cold_water_appoint_master"] = "off"
    end
    if (bit.band(bodyBytes[36], 0x40) == 0x40) then
        status["cold_water_ai"] = "on"
    else
        status["cold_water_ai"] = "off"
    end
    if (bit.band(bodyBytes[36], 0x80) == 0x80) then
        status["cold_water_has_enabled_appoint"] = "on"
    else
        status["cold_water_has_enabled_appoint"] = "off"
    end
    status["rise_number"] = tonumber(bodyBytes[37])
    status["water_gage"] = tonumber(bodyBytes[38])
    status["current_bath_water"] = tonumber(bodyBytes[39])
    status["out_temperature"] = tempTransformation(bodyBytes[40])
    status["in_temperature"] = tonumber(bodyBytes[41])
    status["temperature_sensation"] = tonumber(bodyBytes[42])
    if (bit.band(bodyBytes[43], 0x01) == 0x01) then
        status["ignitor_output"] = "output"
    else
        status["ignitor_output"] = "no_output"
    end
    if (bit.band(bodyBytes[43], 0x02) == 0x02) then
        status["main_gas_valve_output"] = "output"
    else
        status["main_gas_valve_output"] = "no_output"
    end
    if (bit.band(bodyBytes[43], 0x04) == 0x04) then
        status["tee_valve_output"] = "bath_side"
    else
        status["tee_valve_output"] = "heat_side"
    end
    if (bit.band(bodyBytes[43], 0x08) == 0x08) then
        status["fan_output"] = "output"
    else
        status["fan_output"] = "no_output"
    end
    if (bit.band(bodyBytes[43], 0x10) == 0x10) then
        status["heat_pump_output"] = "output"
    else
        status["heat_pump_output"] = "no_output"
    end
    if (bit.band(bodyBytes[43], 0x20) == 0x20) then
        status["sectioning1_output"] = "output"
    else
        status["sectioning1_output"] = "no_output"
    end
    if (bit.band(bodyBytes[43], 0x40) == 0x40) then
        status["sectioning2_output"] = "output"
    else
        status["sectioning2_output"] = "no_output"
    end
    if (bit.band(bodyBytes[43], 0x80) == 0x80) then
        status["zero_cool_pump_output"] = "output"
    else
        status["zero_cool_pump_output"] = "no_output"
    end
    if (bit.band(bodyBytes[44], 0x02) == 0x02) then
        status["in_temperature_switch"] = "off"
    else
        status["in_temperature_switch"] = "on"
    end
    if (bit.band(bodyBytes[44], 0x04) == 0x04) then
        status["buzzing_master_switch"] = "no_buzzing"
    else
        status["buzzing_master_switch"] = "buzzing"
    end
    if (bit.band(bodyBytes[44], 0x01) == 0x01) then
        status["hold_back_43_1"] = "on"
    else
        status["hold_back_43_1"] = "off"
    end
    if (bit.band(bodyBytes[44], 0x08) == 0x08) then
        status["hold_back_43_3"] = "on"
    else
        status["hold_back_43_3"] = "off"
    end
    if (bit.band(bodyBytes[44], 0x10) == 0x10) then
        status["hold_back_43_4"] = "on"
    else
        status["hold_back_43_4"] = "off"
    end
    if (bit.band(bodyBytes[44], 0x20) == 0x20) then
        status["hold_back_43_5"] = "on"
    else
        status["hold_back_43_5"] = "off"
    end
    if (bit.band(bodyBytes[44], 0x40) == 0x40) then
        status["hold_back_43_6"] = "on"
    else
        status["hold_back_43_6"] = "off"
    end
    if (bit.band(bodyBytes[44], 0x80) == 0x80) then
        status["hold_back_43_7"] = "on"
    else
        status["hold_back_43_7"] = "off"
    end
    status["sectioning_output_percent"] = tonumber(bodyBytes[45])
    status["heat_back_water_temp"] = tonumber(bodyBytes[46])
    status["bath_back_water_temp"] = tonumber(bodyBytes[47])
    status["version"] = VALUE_VERSION
    return status
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    result = JSON.decode(jsonCmdStr)
    if result == nil then return end
    local msgBytes = {0xAA, 0x00, 0xE6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
    msgBytes = assembleByteFromJson(result, msgBytes)
    local len = #msgBytes
    msgBytes[2] = len
    msgBytes[len + 1] = makeSum(msgBytes, 2, len)
    local ret = table2string(msgBytes)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(cmdStr)
    if (not cmdStr) then return nil end
    local result
    if JSON == nil then JSON = require "cjson" end
    result = JSON.decode(cmdStr)
    if result == nil then return end
    local binData = result["msg"]["data"]
    local ret = {}
    ret["status"] = {}
    local bodyBytes = string2table(binData)
    ret["status"] = parseByteToJson(ret["status"], bodyBytes)
    local ret = JSON.encode(ret)
    return ret
end
