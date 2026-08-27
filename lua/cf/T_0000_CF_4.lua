local uptable = {}
local JSON = require "cjson"
uptable["KEY_POWER_STATE"] = "power_state"
uptable["KEY_PRE_HEAT"] = "pre_heat"
uptable["KEY_SILENCE_SET_STATE"] = "silence_set_state"
uptable["KEY_HOLIDAY_SET_STATE"] = "holiday_set_state"
uptable["KEY_HOLIDAY_ON_STATE"] = "holiday_on_state"
uptable["KEY_TIME_SET_STATE"] = "time_set_state"
uptable["KEY_TEMP_TYPE"] = "temp_type"
uptable["KEY_COMP_STATE"] = "comp_state"
uptable["KEY_DAY_TIME_STATE"] = "day_time_state"
uptable["KEY_WEEK_TIME_STATE"] = "week_time_state"
uptable["KEY_WARN_STATE"] = "warn_state"
uptable["KEY_DEFROST_STATE"] = "defrost_state"
uptable["KEY_FREEZE_STATE"] = "freeze_state"
uptable["KEY_TEMP_SET"] = "temp_set"
uptable["KEY_CUR_TEMP"] = "cur_temp"
uptable["KEY_HEAT_MAX_SET_TEMP"] = "heat_max_set_temp"
uptable["KEY_HEAT_MIN_SET_TEMP"] = "heat_min_set_temp"
uptable["KEY_COOL_MAX_SET_TEMP"] = "cool_max_set_temp"
uptable["KEY_COOL_MIN_SET_TEMP"] = "cool_min_set_temp"
uptable["KEY_AUTO_MAX_SET_TEMP"] = "auto_max_set_temp"
uptable["KEY_AUTO_MIN_SET_TEMP"] = "auto_min_set_temp"
uptable["KEY_PREHEAT_ON_SET_TEMP"] = "preheat_on_set_temp"
uptable["KEY_PREHEAT_MAX_SET_TEMP"] = "preheat_max_set_temp"
uptable["KEY_PREHEAT_MIN_SET_TEMP"] = "preheat_min_set_temp"
uptable["KEY_ZONE1_POWER_STATE"] = "zone1_power_state"
uptable["KEY_ZONE2_POWER_STATE"] = "zone2_power_state"
uptable["KEY_DHW_POWER_STATE"] = "dhw_power_state"
uptable["KEY_ZONE1_CURVE_STATE"] = "zone1_curve_state"
uptable["KEY_ZONE2_CURVE_STATE"] = "zone2_curve_state"
uptable["KEY_DISINFECT_STATE"] = "disinfect_state"
uptable["KEY_FASTDHW_STATE"] = "fastdhw_state"
uptable["KEY_HEAT_ENABLE"] = "heat_enable"
uptable["KEY_COOL_ENABLE"] = "cool_enable"
uptable["KEY_DHW_ENABLE"] = "dhw_enable"
uptable["KEY_DOUBLEZONE_ENABLE"] = "doublezone_enable"
uptable["KEY_ZONE1_TEMP_TYPE"] = "zone1_temp_type"
uptable["KEY_ZONE2_TEMP_TYPE"] = "zone2_temp_type"
uptable["KEY_ROOM_TEMP_CTRL"] = "room_temp_ctrl"
uptable["KEY_ROOM_TEMP_SET"] = "room_temp_set"
uptable["KEY_SCHEDULE_ON_STATE"] = "schedule_on_state"
uptable["KEY_SILENCE_STATE"] = "silence_state"
uptable["KEY_HOLIDAY_STATE"] = "holiday_state"
uptable["KEY_ECO_STATE"] = "eco_state"
uptable["KEY_ZONE1_EMISSION_TYPE"] = "zone1_emission_type"
uptable["KEY_ZONE2_EMISSION_TYPE"] = "zone2_emission_type"
uptable["KEY_SET_MODE"] = "set_mode"
uptable["KEY_RUN_MODE"] = "run_mode"
uptable["KEY_ZONE1_TEMP_SET"] = "zone1_temp_set"
uptable["KEY_ZONE2_TEMP_SET"] = "zone2_temp_set"
uptable["KEY_DHW_TEMP_SET"] = "dhw_temp_set"
uptable["KEY_ROOM_TEMP_SET"] = "room_temp_set"
uptable["KEY_ZONE1_HEAT_MAX_SET_TEMP"] = "zone1_heat_max_set_temp"
uptable["KEY_ZONE1_HEAT_MIN_SET_TEMP"] = "zone1_heat_min_set_temp"
uptable["KEY_ZONE1_COOL_MAX_SET_TEMP"] = "zone1_cool_max_set_temp"
uptable["KEY_ZONE1_COOL_MIN_SET_TEMP"] = "zone1_cool_min_set_temp"
uptable["KEY_ZONE2_HEAT_MAX_SET_TEMP"] = "zone2_heat_max_set_temp"
uptable["KEY_ZONE2_HEAT_MIN_SET_TEMP"] = "zone2_heat_min_set_temp"
uptable["KEY_ZONE2_COOL_MAX_SET_TEMP"] = "zone2_cool_max_set_temp"
uptable["KEY_ZONE2_COOL_MIN_SET_TEMP"] = "zone2_cool_min_set_temp"
uptable["KEY_ROOM_MAX_SET_TEMP"] = "room_max_set_temp"
uptable["KEY_ROOM_MIN_SET_TEMP"] = "room_min_set_temp"
uptable["KEY_DHW_MAX_SET_TEMP"] = "dhw_max_set_temp"
uptable["KEY_DHW_MIN_SET_TEMP"] = "dhw_min_set_temp"
uptable["KEY_TANK_ACTUAL_TEMP"] = "tank_actual_temp"
uptable["KEY_CUR_ERRCODE"] = "error_code"

uptable["VALUE_OFF"] = "off"
uptable["VALUE_ON"] = "on"
uptable["VALUE_MODE_COOL"] = "cool"
uptable["VALUE_MODE_HEAT"] = "heat"
uptable["VALUE_MODE_AUTO"] = "auto"
uptable["VALUE_MODE_DHW"] = "dhw"
uptable["VALUE_NOT_USED"] = "not_used"
uptable["VALUE_ERR_CODE_341L_0"] = "0"
uptable["VALUE_WATER"] = "water_temperature"
uptable["VALUE_AIR"] = "air_temperature"
uptable["VALUE_FCU"] = "fan_coil_unit"
uptable["VALUE_FHL"] = "floor_heating_loop"
uptable["VALUE_RAD"] = "radiation"

uptable["LEVEL1"] = "level_1"
uptable["LEVEL2"] = "level_2"
uptable["VERSION"] = "4"
uptable["BYTE_DEVICE_TYPE"] = 0xCF
uptable["BYTE_CONTROL_REQUEST"] = 0x02
uptable["BYTE_QUERY_STATUS_REQUEST"] = 0x03
uptable["BYTE_PROTOCOL_HEAD"] = 0xAA
uptable["BYTE_PROTOCOL_LENGTH"] = 0x0A
uptable["BYTE_BIT0"] = 0x01
uptable["BYTE_BIT1"] = 0x02
uptable["BYTE_BIT2"] = 0x04
uptable["BYTE_BIT3"] = 0x08
uptable["BYTE_BIT4"] = 0x10
uptable["BYTE_BIT5"] = 0x20
uptable["BYTE_BIT6"] = 0x40
uptable["BYTE_BIT7"] = 0x80

local msgType
local msgSubType
local zone1_power_state = 0
local zone2_power_state = 0
local dhw_power_state = 0
local zone1_curve_state = 0
local zone2_curve_state = 0
local disinfect_state = 0
local fastdhw_state = 0
local dhw_enable
local doublezone_enable
local zone1_temp_type
local zone2_temp_type
local schedule_on_state
local eco_state
local zone1_emission_type
local zone2_emission_type
local zone1_temp_set = 25
local zone2_temp_set = 25
local dhw_temp_set = 40
local zone1_heat_max_set_temp
local zone1_heat_min_set_temp
local zone1_cool_max_set_temp
local zone1_cool_min_set_temp
local zone2_heat_max_set_temp
local zone2_heat_min_set_temp
local zone2_cool_max_set_temp
local zone2_cool_min_set_temp
local room_max_set_temp
local room_min_set_temp
local dhw_max_set_temp
local dhw_min_set_temp
local tank_actual_temp
local mytable = {
    ["room_temp_set"] = 50,
    ["daytimer_timer1en"] = 0,
    ["daytimer_timer2en"] = 0,
    ["daytimer_timer3en"] = 0,
    ["daytimer_timer4en"] = 0,
    ["daytimer_timer5en"] = 0,
    ["daytimer_timer6en"] = 0,
    ["daytimer_timer1_mode"] = 0,
    ["daytimer_timer1_temp"] = 0,
    ["daytimer_timer1_openhour"] = 0,
    ["daytimer_timer1_openmin"] = 0,
    ["daytimer_timer1_closehour"] = 0,
    ["daytimer_timer1_closemin"] = 0,
    ["daytimer_timer2_mode"] = 0,
    ["daytimer_timer2_temp"] = 0,
    ["daytimer_timer2_openhour"] = 0,
    ["daytimer_timer2_openmin"] = 0,
    ["daytimer_timer2_closehour"] = 0,
    ["daytimer_timer2_closemin"] = 0,
    ["daytimer_timer3_mode"] = 0,
    ["daytimer_timer3_temp"] = 0,
    ["daytimer_timer3_openhour"] = 0,
    ["daytimer_timer3_openmin"] = 0,
    ["daytimer_timer3_closehour"] = 0,
    ["daytimer_timer3_closemin"] = 0,
    ["daytimer_timer4_mode"] = 0,
    ["daytimer_timer4_temp"] = 0,
    ["daytimer_timer4_openhour"] = 0,
    ["daytimer_timer4_openmin"] = 0,
    ["daytimer_timer4_closehour"] = 0,
    ["daytimer_timer4_closemin"] = 0,
    ["daytimer_timer5_mode"] = 0,
    ["daytimer_timer5_temp"] = 0,
    ["daytimer_timer5_openhour"] = 0,
    ["daytimer_timer5_openmin"] = 0,
    ["daytimer_timer5_closehour"] = 0,
    ["daytimer_timer5_closemin"] = 0,
    ["daytimer_timer6_mode"] = 0,
    ["daytimer_timer6_temp"] = 0,
    ["daytimer_timer6_openhour"] = 0,
    ["daytimer_timer6_openmin"] = 0,
    ["daytimer_timer6_closehour"] = 0,
    ["daytimer_timer6_closemin"] = 0,
    ["weektimer_setday"] = 1,
    ["weektimer_timer1en"] = 0,
    ["weektimer_timer2en"] = 0,
    ["weektimer_timer3en"] = 0,
    ["weektimer_timer4en"] = 0,
    ["weektimer_timer5en"] = 0,
    ["weektimer_timer6en"] = 0,
    ["weektimer_timer1_mode"] = 0,
    ["weektimer_timer1_temp"] = 0,
    ["weektimer_timer1_openhour"] = 0,
    ["weektimer_timer1_openmin"] = 0,
    ["weektimer_timer1_closehour"] = 0,
    ["weektimer_timer1_closemin"] = 0,
    ["weektimer_timer2_mode"] = 0,
    ["weektimer_timer2_temp"] = 0,
    ["weektimer_timer2_openhour"] = 0,
    ["weektimer_timer2_openmin"] = 0,
    ["weektimer_timer2_closehour"] = 0,
    ["weektimer_timer2_closemin"] = 0,
    ["weektimer_timer3_mode"] = 0,
    ["weektimer_timer3_temp"] = 0,
    ["weektimer_timer3_openhour"] = 0,
    ["weektimer_timer3_openmin"] = 0,
    ["weektimer_timer3_closehour"] = 0,
    ["weektimer_timer3_closemin"] = 0,
    ["weektimer_timer4_mode"] = 0,
    ["weektimer_timer4_temp"] = 0,
    ["weektimer_timer4_openhour"] = 0,
    ["weektimer_timer4_openmin"] = 0,
    ["weektimer_timer4_closehour"] = 0,
    ["weektimer_timer4_closemin"] = 0,
    ["weektimer_timer5_mode"] = 0,
    ["weektimer_timer5_temp"] = 0,
    ["weektimer_timer5_openhour"] = 0,
    ["weektimer_timer5_openmin"] = 0,
    ["weektimer_timer5_closehour"] = 0,
    ["weektimer_timer5_closemin"] = 0,
    ["weektimer_timer6_mode"] = 0,
    ["weektimer_timer6_temp"] = 0,
    ["weektimer_timer6_openhour"] = 0,
    ["weektimer_timer6_openmin"] = 0,
    ["weektimer_timer6_closehour"] = 0,
    ["weektimer_timer6_closemin"] = 0,
    ["holidayaway_state"] = 0,
    ["holidayaway_startyear"] = 0,
    ["holidayaway_startmonth"] = 0,
    ["holidayaway_startdate"] = 0,
    ["holidayaway_endyear"] = 0,
    ["holidayaway_endmonth"] = 0,
    ["holidayaway_enddate"] = 0,
    ["silence_function_state"] = 0,
    ["silence_timer1_state"] = 0,
    ["silence_timer2_state"] = 0,
    ["silence_function_level"] = 0,
    ["silence_timer1_starthour"] = 0,
    ["silence_timer1_startmin"] = 0,
    ["silence_timer1_endhour"] = 0,
    ["silence_timer1_endmin"] = 0,
    ["silence_timer2_starthour"] = 0,
    ["silence_timer2_startmin"] = 0,
    ["silence_timer2_endhour"] = 0,
    ["silence_timer2_endmin"] = 0,
    ["holidayhome_state"] = 0,
    ["holidayhome_startyear"] = 0,
    ["holidayhome_startmonth"] = 0,
    ["holidayhome_startdate"] = 0,
    ["holidayhome_endyear"] = 0,
    ["holidayhome_endmonth"] = 0,
    ["holidayhome_enddate"] = 0,
    ["holhometimer_timer1en"] = 0,
    ["holhometimer_timer2en"] = 0,
    ["holhometimer_timer3en"] = 0,
    ["holhometimer_timer4en"] = 0,
    ["holhometimer_timer5en"] = 0,
    ["holhometimer_timer6en"] = 0,
    ["holhometimer_timer1_mode"] = 0,
    ["holhometimer_timer1_temp"] = 0,
    ["holhometimer_timer1_openhour"] = 0,
    ["holhometimer_timer1_openmin"] = 0,
    ["holhometimer_timer1_closehour"] = 0,
    ["holhometimer_timer1_closemin"] = 0,
    ["holhometimer_timer2_mode"] = 0,
    ["holhometimer_timer2_temp"] = 0,
    ["holhometimer_timer2_openhour"] = 0,
    ["holhometimer_timer2_openmin"] = 0,
    ["holhometimer_timer2_closehour"] = 0,
    ["holhometimer_timer2_closemin"] = 0,
    ["holhometimer_timer3_mode"] = 0,
    ["holhometimer_timer3_temp"] = 0,
    ["holhometimer_timer3_openhour"] = 0,
    ["holhometimer_timer3_openmin"] = 0,
    ["holhometimer_timer3_closehour"] = 0,
    ["holhometimer_timer3_closemin"] = 0,
    ["holhometimer_timer4_mode"] = 0,
    ["holhometimer_timer4_temp"] = 0,
    ["holhometimer_timer4_openhour"] = 0,
    ["holhometimer_timer4_openmin"] = 0,
    ["holhometimer_timer4_closehour"] = 0,
    ["holhometimer_timer4_closemin"] = 0,
    ["holhometimer_timer5_mode"] = 0,
    ["holhometimer_timer5_temp"] = 0,
    ["holhometimer_timer5_openhour"] = 0,
    ["holhometimer_timer5_openmin"] = 0,
    ["holhometimer_timer5_closehour"] = 0,
    ["holhometimer_timer5_closemin"] = 0,
    ["holhometimer_timer6_mode"] = 0,
    ["holhometimer_timer6_temp"] = 0,
    ["holhometimer_timer6_openhour"] = 0,
    ["holhometimer_timer6_openmin"] = 0,
    ["holhometimer_timer6_closehour"] = 0,
    ["holhometimer_timer6_closemin"] = 0,
    ["eco_function_state"] = 0,
    ["eco_timer_state"] = 0,
    ["eco_timer_starthour"] = 0,
    ["eco_timer_startmin"] = 0,
    ["eco_timer_endhour"] = 0,
    ["eco_timer_endmin"] = 0
}

local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
end

local function binToModel(dataType, bodyLength, binData)
    local messageBytes = {}
    messageBytes = binData
    if (dataType ~= 0x04) then
        for i = 0, bodyLength - 1 do messageBytes[i] = binData[1 + i] end
    end

    if ((msgType == 0x02 and msgSubType == 0x01) or
        ((msgType == 0x03) and (msgSubType == 0x01)) or (msgType == 0x04)) then
        mytable["power_state"] = bit.band(messageBytes[0], 0x01)
        mytable["pre_heat"] = bit.band(messageBytes[0], 0x02)
        mytable["silence_set_state"] = bit.band(messageBytes[0], 0x04)
        mytable["holiday_set_state"] = bit.band(messageBytes[0], 0x08)
        mytable["time_set_state"] = bit.band(messageBytes[0], 0x10)
        mytable["holiday_on_state"] = bit.band(messageBytes[0], 0x20)
        mytable["heat_enable"] = bit.band(messageBytes[1], 0x01)
        mytable["cool_enable"] = bit.band(messageBytes[1], 0x02)
        mytable["temp_type"] = bit.band(messageBytes[1], 0x04)
        mytable["room_temp_ctrl"] = bit.band(messageBytes[1], 0x08)
        mytable["room_temp_set"] = bit.band(messageBytes[1], 0x10)
        mytable["comp_state"] = bit.band(messageBytes[2], 0x01)
        mytable["silence_state"] = bit.band(messageBytes[2], 0x02)
        mytable["day_time_state"] = bit.band(messageBytes[2], 0x04)
        mytable["week_time_state"] = bit.band(messageBytes[2], 0x08)
        mytable["warn_state"] = bit.band(messageBytes[2], 0x10)
        mytable["defrost_state"] = bit.band(messageBytes[2], 0x20)
        mytable["freeze_state"] = bit.band(messageBytes[2], 0x40)
        mytable["holiday_state"] = bit.band(messageBytes[2], 0x80)
        mytable["run_mode"] = messageBytes[3]
        mytable["temp_set"] = messageBytes[4]
        mytable["cur_temp"] = messageBytes[5]
        mytable["heat_max_set_temp"] = messageBytes[6]
        mytable["heat_min_set_temp"] = messageBytes[7]
        mytable["cool_max_set_temp"] = messageBytes[8]
        mytable["cool_min_set_temp"] = messageBytes[9]
        mytable["auto_max_set_temp"] = messageBytes[10]
        mytable["auto_min_set_temp"] = messageBytes[11]
        mytable["preheat_on_set_temp"] = messageBytes[12]
        mytable["preheat_max_set_temp"] = messageBytes[13]
        mytable["preheat_min_set_temp"] = messageBytes[14]
        mytable["cur_errcode"] = messageBytes[15]

    elseif ((msgType == 0x03) and (msgSubType == 0x02)) then
        mytable["daytimer_timer1en"] = bit.band(messageBytes[0], 0x01)
        mytable["daytimer_timer2en"] = bit.rshift(
                                           bit.band(messageBytes[0], 0x02), 1)
        mytable["daytimer_timer3en"] = bit.rshift(
                                           bit.band(messageBytes[0], 0x04), 2)
        mytable["daytimer_timer4en"] = bit.rshift(
                                           bit.band(messageBytes[0], 0x08), 3)
        mytable["daytimer_timer5en"] = bit.rshift(
                                           bit.band(messageBytes[0], 0x10), 4)
        mytable["daytimer_timer6en"] = bit.rshift(
                                           bit.band(messageBytes[0], 0x20), 5)
        mytable["daytimer_timer1_mode"] = messageBytes[1]
        mytable["daytimer_timer1_temp"] = messageBytes[2]
        mytable["daytimer_timer1_openhour"] = messageBytes[3]
        mytable["daytimer_timer1_openmin"] = messageBytes[4]
        mytable["daytimer_timer1_closehour"] = messageBytes[5]
        mytable["daytimer_timer1_closemin"] = messageBytes[6]
        mytable["daytimer_timer2_mode"] = messageBytes[7]
        mytable["daytimer_timer2_temp"] = messageBytes[8]
        mytable["daytimer_timer2_openhour"] = messageBytes[9]
        mytable["daytimer_timer2_openmin"] = messageBytes[10]
        mytable["daytimer_timer2_closehour"] = messageBytes[11]
        mytable["daytimer_timer2_closemin"] = messageBytes[12]
        mytable["daytimer_timer3_mode"] = messageBytes[13]
        mytable["daytimer_timer3_temp"] = messageBytes[14]
        mytable["daytimer_timer3_openhour"] = messageBytes[15]
        mytable["daytimer_timer3_openmin"] = messageBytes[16]
        mytable["daytimer_timer3_closehour"] = messageBytes[17]
        mytable["daytimer_timer3_closemin"] = messageBytes[18]
        mytable["daytimer_timer4_mode"] = messageBytes[19]
        mytable["daytimer_timer4_temp"] = messageBytes[20]
        mytable["daytimer_timer4_openhour"] = messageBytes[21]
        mytable["daytimer_timer4_openmin"] = messageBytes[22]
        mytable["daytimer_timer4_closehour"] = messageBytes[23]
        mytable["daytimer_timer4_closemin"] = messageBytes[24]
        mytable["daytimer_timer5_mode"] = messageBytes[25]
        mytable["daytimer_timer5_temp"] = messageBytes[26]
        mytable["daytimer_timer5_openhour"] = messageBytes[27]
        mytable["daytimer_timer5_openmin"] = messageBytes[28]
        mytable["daytimer_timer5_closehour"] = messageBytes[29]
        mytable["daytimer_timer5_closemin"] = messageBytes[30]
        mytable["daytimer_timer6_mode"] = messageBytes[31]
        mytable["daytimer_timer6_temp"] = messageBytes[32]
        mytable["daytimer_timer6_openhour"] = messageBytes[33]
        mytable["daytimer_timer6_openmin"] = messageBytes[34]
        mytable["daytimer_timer6_closehour"] = messageBytes[35]
        mytable["daytimer_timer6_closemin"] = messageBytes[36]

    elseif ((msgType == 0x03) and (msgSubType == 0x03)) then
        if (bit.band(messageBytes[0], 0x01) == 0x01) then
            mytable["queryweekday"] = 1
        elseif (bit.band(messageBytes[0], 0x02) == 0x02) then
            mytable["queryweekday"] = 2
        elseif (bit.band(messageBytes[0], 0x04) == 0x04) then
            mytable["queryweekday"] = 3
        elseif (bit.band(messageBytes[0], 0x08) == 0x08) then
            mytable["queryweekday"] = 4
        elseif (bit.band(messageBytes[0], 0x10) == 0x10) then
            mytable["queryweekday"] = 5
        elseif (bit.band(messageBytes[0], 0x20) == 0x20) then
            mytable["queryweekday"] = 6
        elseif (bit.band(messageBytes[0], 0x40) == 0x40) then
            mytable["queryweekday"] = 7
        end
        mytable["weektimer_timer1en"] = bit.band(messageBytes[1], 0x01)
        mytable["weektimer_timer2en"] = bit.rshift(
                                            bit.band(messageBytes[1], 0x02), 1)
        mytable["weektimer_timer3en"] = bit.rshift(
                                            bit.band(messageBytes[1], 0x04), 2)
        mytable["weektimer_timer4en"] = bit.rshift(
                                            bit.band(messageBytes[1], 0x08), 3)
        mytable["weektimer_timer5en"] = bit.rshift(
                                            bit.band(messageBytes[1], 0x10), 4)
        mytable["weektimer_timer6en"] = bit.rshift(
                                            bit.band(messageBytes[1], 0x20), 5)
        mytable["weektimer_timer1_mode"] = messageBytes[2]
        mytable["weektimer_timer1_temp"] = messageBytes[3]
        mytable["weektimer_timer1_openhour"] = messageBytes[4]
        mytable["weektimer_timer1_openmin"] = messageBytes[5]
        mytable["weektimer_timer1_closehour"] = messageBytes[6]
        mytable["weektimer_timer1_closemin"] = messageBytes[7]
        mytable["weektimer_timer2_mode"] = messageBytes[8]
        mytable["weektimer_timer2_temp"] = messageBytes[9]
        mytable["weektimer_timer2_openhour"] = messageBytes[10]
        mytable["weektimer_timer2_openmin"] = messageBytes[11]
        mytable["weektimer_timer2_closehour"] = messageBytes[12]
        mytable["weektimer_timer2_closemin"] = messageBytes[13]
        mytable["weektimer_timer3_mode"] = messageBytes[14]
        mytable["weektimer_timer3_temp"] = messageBytes[15]
        mytable["weektimer_timer3_openhour"] = messageBytes[16]
        mytable["weektimer_timer3_openmin"] = messageBytes[17]
        mytable["weektimer_timer3_closehour"] = messageBytes[18]
        mytable["weektimer_timer3_closemin"] = messageBytes[19]
        mytable["weektimer_timer4_mode"] = messageBytes[20]
        mytable["weektimer_timer4_temp"] = messageBytes[21]
        mytable["weektimer_timer4_openhour"] = messageBytes[22]
        mytable["weektimer_timer4_openmin"] = messageBytes[23]
        mytable["weektimer_timer4_closehour"] = messageBytes[24]
        mytable["weektimer_timer4_closemin"] = messageBytes[25]
        mytable["weektimer_timer5_mode"] = messageBytes[26]
        mytable["weektimer_timer5_temp"] = messageBytes[27]
        mytable["weektimer_timer5_openhour"] = messageBytes[28]
        mytable["weektimer_timer5_openmin"] = messageBytes[29]
        mytable["weektimer_timer5_closehour"] = messageBytes[30]
        mytable["weektimer_timer5_closemin"] = messageBytes[31]
        mytable["weektimer_timer6_mode"] = messageBytes[32]
        mytable["weektimer_timer6_temp"] = messageBytes[33]
        mytable["weektimer_timer6_openhour"] = messageBytes[34]
        mytable["weektimer_timer6_openmin"] = messageBytes[35]
        mytable["weektimer_timer6_closehour"] = messageBytes[36]
        mytable["weektimer_timer6_closemin"] = messageBytes[37]

    elseif ((msgType == 0x03) and (msgSubType == 0x04)) then
        mytable["holidayaway_state"] = messageBytes[0]
        mytable["holidayaway_startyear"] = messageBytes[1]
        mytable["holidayaway_startmonth"] = messageBytes[2]
        mytable["holidayaway_startdate"] = messageBytes[3]
        mytable["holidayaway_endyear"] = messageBytes[4]
        mytable["holidayaway_endmonth"] = messageBytes[5]
        mytable["holidayaway_enddate"] = messageBytes[6]

    elseif ((msgType == 0x03) and (msgSubType == 0x05)) then
        mytable["silence_function_state"] = bit.band(messageBytes[0], 0x01)
        mytable["silence_timer1_state"] = bit.rshift(
                                              bit.band(messageBytes[0], 0x02), 1)
        mytable["silence_timer2_state"] = bit.rshift(
                                              bit.band(messageBytes[0], 0x04), 2)
        mytable["silence_function_level"] = bit.rshift(
                                                bit.band(messageBytes[0], 0x08),
                                                3)
        mytable["silence_timer1_starthour"] = messageBytes[1]
        mytable["silence_timer1_startmin"] = messageBytes[2]
        mytable["silence_timer1_endhour"] = messageBytes[3]
        mytable["silence_timer1_endmin"] = messageBytes[4]
        mytable["silence_timer2_starthour"] = messageBytes[5]
        mytable["silence_timer2_startmin"] = messageBytes[6]
        mytable["silence_timer2_endhour"] = messageBytes[7]
        mytable["silence_timer2_endmin"] = messageBytes[8]

    elseif ((msgType == 0x03) and (msgSubType == 0x06)) then
        mytable["holidayhome_state"] = messageBytes[0]
        mytable["holidayhome_startyear"] = messageBytes[1]
        mytable["holidayhome_startmonth"] = messageBytes[2]
        mytable["holidayhome_startdate"] = messageBytes[3]
        mytable["holidayhome_endyear"] = messageBytes[4]
        mytable["holidayhome_endmonth"] = messageBytes[5]
        mytable["holidayhome_enddate"] = messageBytes[6]
        mytable["holhometimer_timer1en"] = bit.band(messageBytes[7], 0x01)
        mytable["holhometimer_timer2en"] = bit.rshift(
                                               bit.band(messageBytes[7], 0x02),
                                               1)
        mytable["holhometimer_timer3en"] = bit.rshift(
                                               bit.band(messageBytes[7], 0x04),
                                               2)
        mytable["holhometimer_timer4en"] = bit.rshift(
                                               bit.band(messageBytes[7], 0x08),
                                               3)
        mytable["holhometimer_timer5en"] = bit.rshift(
                                               bit.band(messageBytes[7], 0x10),
                                               4)
        mytable["holhometimer_timer6en"] = bit.rshift(
                                               bit.band(messageBytes[7], 0x20),
                                               5)
        mytable["holhometimer_timer1_mode"] = messageBytes[8]
        mytable["holhometimer_timer1_temp"] = messageBytes[9]
        mytable["holhometimer_timer1_openhour"] = messageBytes[10]
        mytable["holhometimer_timer1_openmin"] = messageBytes[11]
        mytable["holhometimer_timer1_closehour"] = messageBytes[12]
        mytable["holhometimer_timer1_closemin"] = messageBytes[13]
        mytable["holhometimer_timer2_mode"] = messageBytes[14]
        mytable["holhometimer_timer2_temp"] = messageBytes[15]
        mytable["holhometimer_timer2_openhour"] = messageBytes[16]
        mytable["holhometimer_timer2_openmin"] = messageBytes[17]
        mytable["holhometimer_timer2_closehour"] = messageBytes[18]
        mytable["holhometimer_timer2_closemin"] = messageBytes[19]
        mytable["holhometimer_timer3_mode"] = messageBytes[20]
        mytable["holhometimer_timer3_temp"] = messageBytes[21]
        mytable["holhometimer_timer3_openhour"] = messageBytes[22]
        mytable["holhometimer_timer3_openmin"] = messageBytes[23]
        mytable["holhometimer_timer3_closehour"] = messageBytes[24]
        mytable["holhometimer_timer3_closemin"] = messageBytes[25]
        mytable["holhometimer_timer4_mode"] = messageBytes[26]
        mytable["holhometimer_timer4_temp"] = messageBytes[27]
        mytable["holhometimer_timer4_openhour"] = messageBytes[28]
        mytable["holhometimer_timer4_openmin"] = messageBytes[29]
        mytable["holhometimer_timer4_closehour"] = messageBytes[30]
        mytable["holhometimer_timer4_closemin"] = messageBytes[31]
        mytable["holhometimer_timer5_mode"] = messageBytes[32]
        mytable["holhometimer_timer5_temp"] = messageBytes[33]
        mytable["holhometimer_timer5_openhour"] = messageBytes[34]
        mytable["holhometimer_timer5_openmin"] = messageBytes[35]
        mytable["holhometimer_timer5_closehour"] = messageBytes[36]
        mytable["holhometimer_timer5_closemin"] = messageBytes[37]
        mytable["holhometimer_timer6_mode"] = messageBytes[38]
        mytable["holhometimer_timer6_temp"] = messageBytes[39]
        mytable["holhometimer_timer6_openhour"] = messageBytes[40]
        mytable["holhometimer_timer6_openmin"] = messageBytes[41]
        mytable["holhometimer_timer6_closehour"] = messageBytes[42]
        mytable["holhometimer_timer6_closemin"] = messageBytes[43]

    elseif ((msgType == 0x03) and (msgSubType == 0x07)) then
        mytable["eco_function_state"] = bit.band(messageBytes[0], 0x01)
        mytable["eco_timer_state"] = bit.rshift(bit.band(messageBytes[0], 0x02),
                                                1)
        mytable["eco_timer_starthour"] = messageBytes[1]
        mytable["eco_timer_startmin"] = messageBytes[2]
        mytable["eco_timer_endhour"] = messageBytes[3]
        mytable["eco_timer_endmin"] = messageBytes[4]
    end
end

local function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + uptable["BYTE_PROTOCOL_LENGTH"] + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = uptable["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = bodyLength + uptable["BYTE_PROTOCOL_LENGTH"] + 1
    msgBytes[2] = uptable["BYTE_DEVICE_TYPE"]
    msgBytes[9] = cType
    for i = 0, bodyLength do
        msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]] = bodyData[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
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

local function checkBoundary(data, min, max)
    if (not data) then data = 0 end
    data = tonumber(data)
    if (data == nil) then data = 0 end
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

local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
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

local function string2hexstring(str)
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end

local function encode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.encode(cmd)
    return tb
end

local function decode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end

local function jsonToModel(jsonCmd)
    local streams = jsonCmd
    mytable["controltype"] = 0x01
    if (streams["control_type"] ~= nil) then
        mytable["controltype"] = string2Int(streams["control_type"])
    end

    if (mytable["controltype"] == 0x01) then
        if (streams[uptable["KEY_POWER_STATE"]] == uptable["VALUE_ON"]) then
            mytable["power_state"] = 0x01
        elseif (streams[uptable["KEY_POWER_STATE"]] == uptable["VALUE_OFF"]) then
            mytable["power_state"] = 0x00
        end
        if (streams[uptable["KEY_RUN_MODE"]] == uptable["VALUE_MODE_AUTO"]) then
            mytable["run_mode"] = 1
        elseif (streams[uptable["KEY_RUN_MODE"]] == uptable["VALUE_MODE_COOL"]) then
            mytable["run_mode"] = 2
        elseif (streams[uptable["KEY_RUN_MODE"]] == uptable["VALUE_MODE_HEAT"]) then
            mytable["run_mode"] = 3
        end
        if (streams[uptable["KEY_TEMP_SET"]] ~= nil) then
            mytable["temp_set"] = string2Int(streams[uptable["KEY_TEMP_SET"]])
        end
        if (streams[uptable["KEY_PRE_HEAT"]] == uptable["VALUE_ON"]) then
            mytable["pre_heat"] = 1
        elseif (streams[uptable["KEY_PRE_HEAT"]] == uptable["VALUE_OFF"]) then
            mytable["pre_heat"] = 0
        else
            mytable["pre_heat"] = 0xff
        end

    elseif (mytable["controltype"] == 0x02) then
        if (streams["daytimer_timer1en"] == uptable["VALUE_ON"]) then
            mytable["daytimer_timer1en"] = uptable["BYTE_BIT0"]
        elseif (streams["daytimer_timer1en"] == uptable["VALUE_OFF"]) then
            mytable["daytimer_timer1en"] = 0
        end
        if (streams["daytimer_timer2en"] == uptable["VALUE_ON"]) then
            mytable["daytimer_timer2en"] = uptable["BYTE_BIT1"]
        elseif (streams["daytimer_timer2en"] == uptable["VALUE_OFF"]) then
            mytable["daytimer_timer2en"] = 0
        end
        if (streams["daytimer_timer3en"] == uptable["VALUE_ON"]) then
            mytable["daytimer_timer3en"] = uptable["BYTE_BIT2"]
        elseif (streams["daytimer_timer3en"] == uptable["VALUE_OFF"]) then
            mytable["daytimer_timer3en"] = 0
        end
        if (streams["daytimer_timer4en"] == uptable["VALUE_ON"]) then
            mytable["daytimer_timer4en"] = uptable["BYTE_BIT3"]
        elseif (streams["daytimer_timer4en"] == uptable["VALUE_OFF"]) then
            mytable["daytimer_timer4en"] = 0
        end
        if (streams["daytimer_timer5en"] == uptable["VALUE_ON"]) then
            mytable["daytimer_timer5en"] = uptable["BYTE_BIT4"]
        elseif (streams["daytimer_timer5en"] == uptable["VALUE_OFF"]) then
            mytable["daytimer_timer5en"] = 0
        end
        if (streams["daytimer_timer6en"] == uptable["VALUE_ON"]) then
            mytable["daytimer_timer6en"] = uptable["BYTE_BIT5"]
        elseif (streams["daytimer_timer6en"] == uptable["VALUE_OFF"]) then
            mytable["daytimer_timer6en"] = 0
        end
        if (streams["daytimer_timer1_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["daytimer_timer1_mode"] = 2
        elseif (streams["daytimer_timer1_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["daytimer_timer1_mode"] = 3
        elseif (streams["daytimer_timer1_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["daytimer_timer1_mode"] = 5
        end
        if (streams["daytimer_timer1_temp"] ~= nil) then
            mytable["daytimer_timer1_temp"] = string2Int(
                                                  streams["daytimer_timer1_temp"])
        end
        if (streams["daytimer_timer1_openhour"] ~= nil) then
            mytable["daytimer_timer1_openhour"] = string2Int(
                                                      streams["daytimer_timer1_openhour"])
        end
        if (streams["daytimer_timer1_openmin"] ~= nil) then
            mytable["daytimer_timer1_openmin"] = string2Int(
                                                     streams["daytimer_timer1_openmin"])
        end
        if (streams["daytimer_timer1_closehour"] ~= nil) then
            mytable["daytimer_timer1_closehour"] = string2Int(
                                                       streams["daytimer_timer1_closehour"])
        end
        if (streams["daytimer_timer1_closemin"] ~= nil) then
            mytable["daytimer_timer1_closemin"] = string2Int(
                                                      streams["daytimer_timer1_closemin"])
        end
        if (streams["daytimer_timer2_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["daytimer_timer2_mode"] = 2
        elseif (streams["daytimer_timer2_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["daytimer_timer2_mode"] = 3
        elseif (streams["daytimer_timer2_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["daytimer_timer2_mode"] = 5
        end
        if (streams["daytimer_timer2_temp"] ~= nil) then
            mytable["daytimer_timer2_temp"] = string2Int(
                                                  streams["daytimer_timer2_temp"])
        end
        if (streams["daytimer_timer2_openhour"] ~= nil) then
            mytable["daytimer_timer2_openhour"] = string2Int(
                                                      streams["daytimer_timer2_openhour"])
        end
        if (streams["daytimer_timer2_openmin"] ~= nil) then
            mytable["daytimer_timer2_openmin"] = string2Int(
                                                     streams["daytimer_timer2_openmin"])
        end
        if (streams["daytimer_timer2_closehour"] ~= nil) then
            mytable["daytimer_timer2_closehour"] = string2Int(
                                                       streams["daytimer_timer2_closehour"])
        end
        if (streams["daytimer_timer2_closemin"] ~= nil) then
            mytable["daytimer_timer2_closemin"] = string2Int(
                                                      streams["daytimer_timer2_closemin"])
        end
        if (streams["daytimer_timer3_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["daytimer_timer3_mode"] = 2
        elseif (streams["daytimer_timer3_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["daytimer_timer3_mode"] = 3
        elseif (streams["daytimer_timer3_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["daytimer_timer3_mode"] = 5
        end
        if (streams["daytimer_timer3_temp"] ~= nil) then
            mytable["daytimer_timer3_temp"] = string2Int(
                                                  streams["daytimer_timer3_temp"])
        end
        if (streams["daytimer_timer3_openhour"] ~= nil) then
            mytable["daytimer_timer3_openhour"] = string2Int(
                                                      streams["daytimer_timer3_openhour"])
        end
        if (streams["daytimer_timer3_openmin"] ~= nil) then
            mytable["daytimer_timer3_openmin"] = string2Int(
                                                     streams["daytimer_timer3_openmin"])
        end
        if (streams["daytimer_timer3_closehour"] ~= nil) then
            mytable["daytimer_timer3_closehour"] = string2Int(
                                                       streams["daytimer_timer3_closehour"])
        end
        if (streams["daytimer_timer3_closemin"] ~= nil) then
            mytable["daytimer_timer3_closemin"] = string2Int(
                                                      streams["daytimer_timer3_closemin"])
        end
        if (streams["daytimer_timer4_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["daytimer_timer4_mode"] = 2
        elseif (streams["daytimer_timer4_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["daytimer_timer4_mode"] = 3
        elseif (streams["daytimer_timer4_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["daytimer_timer4_mode"] = 5
        end
        if (streams["daytimer_timer4_temp"] ~= nil) then
            mytable["daytimer_timer4_temp"] = string2Int(
                                                  streams["daytimer_timer4_temp"])
        end
        if (streams["daytimer_timer4_openhour"] ~= nil) then
            mytable["daytimer_timer4_openhour"] = string2Int(
                                                      streams["daytimer_timer4_openhour"])
        end
        if (streams["daytimer_timer4_openmin"] ~= nil) then
            mytable["daytimer_timer4_openmin"] = string2Int(
                                                     streams["daytimer_timer4_openmin"])
        end
        if (streams["daytimer_timer4_closehour"] ~= nil) then
            mytable["daytimer_timer4_closehour"] = string2Int(
                                                       streams["daytimer_timer4_closehour"])
        end
        if (streams["daytimer_timer4_closemin"] ~= nil) then
            mytable["daytimer_timer4_closemin"] = string2Int(
                                                      streams["daytimer_timer4_closemin"])
        end
        if (streams["daytimer_timer5_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["daytimer_timer5_mode"] = 2
        elseif (streams["daytimer_timer5_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["daytimer_timer5_mode"] = 3
        elseif (streams["daytimer_timer5_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["daytimer_timer5_mode"] = 5
        end
        if (streams["daytimer_timer5_temp"] ~= nil) then
            mytable["daytimer_timer5_temp"] = string2Int(
                                                  streams["daytimer_timer5_temp"])
        end
        if (streams["daytimer_timer5_openhour"] ~= nil) then
            mytable["daytimer_timer5_openhour"] = string2Int(
                                                      streams["daytimer_timer5_openhour"])
        end
        if (streams["daytimer_timer5_openmin"] ~= nil) then
            mytable["daytimer_timer5_openmin"] = string2Int(
                                                     streams["daytimer_timer5_openmin"])
        end
        if (streams["daytimer_timer5_closehour"] ~= nil) then
            mytable["daytimer_timer5_closehour"] = string2Int(
                                                       streams["daytimer_timer5_closehour"])
        end
        if (streams["daytimer_timer5_closemin"] ~= nil) then
            mytable["daytimer_timer5_closemin"] = string2Int(
                                                      streams["daytimer_timer5_closemin"])
        end
        if (streams["daytimer_timer6_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["daytimer_timer6_mode"] = 2
        elseif (streams["daytimer_timer6_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["daytimer_timer6_mode"] = 3
        elseif (streams["daytimer_timer6_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["daytimer_timer6_mode"] = 5
        end
        if (streams["daytimer_timer6_temp"] ~= nil) then
            mytable["daytimer_timer6_temp"] = string2Int(
                                                  streams["daytimer_timer6_temp"])
        end
        if (streams["daytimer_timer6_openhour"] ~= nil) then
            mytable["daytimer_timer6_openhour"] = string2Int(
                                                      streams["daytimer_timer6_openhour"])
        end
        if (streams["daytimer_timer6_openmin"] ~= nil) then
            mytable["daytimer_timer6_openmin"] = string2Int(
                                                     streams["daytimer_timer6_openmin"])
        end
        if (streams["daytimer_timer6_closehour"] ~= nil) then
            mytable["daytimer_timer6_closehour"] = string2Int(
                                                       streams["daytimer_timer6_closehour"])
        end
        if (streams["daytimer_timer6_closemin"] ~= nil) then
            mytable["daytimer_timer6_closemin"] = string2Int(
                                                      streams["daytimer_timer6_closemin"])
        end

    elseif (mytable["controltype"] == 0x03) then
        if (streams["weektimer_setday"] ~= nil) then
            mytable["weektimer_setday"] =
                string2Int(streams["weektimer_setday"])
        end
        if (streams["weektimer_timer1en"] == uptable["VALUE_ON"]) then
            mytable["weektimer_timer1en"] = uptable["BYTE_BIT0"]
        elseif (streams["weektimer_timer1en"] == uptable["VALUE_OFF"]) then
            mytable["weektimer_timer1en"] = 0
        end
        if (streams["weektimer_timer2en"] == uptable["VALUE_ON"]) then
            mytable["weektimer_timer2en"] = uptable["BYTE_BIT1"]
        elseif (streams["weektimer_timer2en"] == uptable["VALUE_OFF"]) then
            mytable["weektimer_timer2en"] = 0
        end
        if (streams["weektimer_timer3en"] == uptable["VALUE_ON"]) then
            mytable["weektimer_timer3en"] = uptable["BYTE_BIT2"]
        elseif (streams["weektimer_timer3en"] == uptable["VALUE_OFF"]) then
            mytable["weektimer_timer3en"] = 0
        end
        if (streams["weektimer_timer4en"] == uptable["VALUE_ON"]) then
            mytable["weektimer_timer4en"] = uptable["BYTE_BIT3"]
        elseif (streams["weektimer_timer4en"] == uptable["VALUE_OFF"]) then
            mytable["weektimer_timer4en"] = 0
        end
        if (streams["weektimer_timer5en"] == uptable["VALUE_ON"]) then
            mytable["weektimer_timer5en"] = uptable["BYTE_BIT4"]
        elseif (streams["weektimer_timer5en"] == uptable["VALUE_OFF"]) then
            mytable["weektimer_timer5en"] = 0
        end
        if (streams["weektimer_timer6en"] == uptable["VALUE_ON"]) then
            mytable["weektimer_timer6en"] = uptable["BYTE_BIT5"]
        elseif (streams["weektimer_timer6en"] == uptable["VALUE_OFF"]) then
            mytable["weektimer_timer6en"] = 0
        end
        if (streams["weektimer_timer1_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["weektimer_timer1_mode"] = 2
        elseif (streams["weektimer_timer1_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["weektimer_timer1_mode"] = 3
        elseif (streams["weektimer_timer1_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["weektimer_timer1_mode"] = 5
        end
        if (streams["weektimer_timer1_temp"] ~= nil) then
            mytable["weektimer_timer1_temp"] = string2Int(
                                                   streams["weektimer_timer1_temp"])
        end
        if (streams["weektimer_timer1_openhour"] ~= nil) then
            mytable["weektimer_timer1_openhour"] = string2Int(
                                                       streams["weektimer_timer1_openhour"])
        end
        if (streams["weektimer_timer1_openmin"] ~= nil) then
            mytable["weektimer_timer1_openmin"] = string2Int(
                                                      streams["weektimer_timer1_openmin"])
        end
        if (streams["weektimer_timer1_closehour"] ~= nil) then
            mytable["weektimer_timer1_closehour"] = string2Int(
                                                        streams["weektimer_timer1_closehour"])
        end
        if (streams["weektimer_timer1_closemin"] ~= nil) then
            mytable["weektimer_timer1_closemin"] = string2Int(
                                                       streams["weektimer_timer1_closemin"])
        end
        if (streams["weektimer_timer2_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["weektimer_timer2_mode"] = 2
        elseif (streams["weektimer_timer2_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["weektimer_timer2_mode"] = 3
        elseif (streams["weektimer_timer2_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["weektimer_timer2_mode"] = 5
        end
        if (streams["weektimer_timer2_temp"] ~= nil) then
            mytable["weektimer_timer2_temp"] = string2Int(
                                                   streams["weektimer_timer2_temp"])
        end
        if (streams["weektimer_timer2_openhour"] ~= nil) then
            mytable["weektimer_timer2_openhour"] = string2Int(
                                                       streams["weektimer_timer2_openhour"])
        end
        if (streams["weektimer_timer2_openmin"] ~= nil) then
            mytable["weektimer_timer2_openmin"] = string2Int(
                                                      streams["weektimer_timer2_openmin"])
        end
        if (streams["weektimer_timer2_closehour"] ~= nil) then
            mytable["weektimer_timer2_closehour"] = string2Int(
                                                        streams["weektimer_timer2_closehour"])
        end
        if (streams["weektimer_timer2_closemin"] ~= nil) then
            mytable["weektimer_timer2_closemin"] = string2Int(
                                                       streams["weektimer_timer2_closemin"])
        end
        if (streams["weektimer_timer3_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["weektimer_timer3_mode"] = 2
        elseif (streams["weektimer_timer3_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["weektimer_timer3_mode"] = 3
        elseif (streams["weektimer_timer3_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["weektimer_timer3_mode"] = 5
        end
        if (streams["weektimer_timer3_temp"] ~= nil) then
            mytable["weektimer_timer3_temp"] = string2Int(
                                                   streams["weektimer_timer3_temp"])
        end
        if (streams["weektimer_timer3_openhour"] ~= nil) then
            mytable["weektimer_timer3_openhour"] = string2Int(
                                                       streams["weektimer_timer3_openhour"])
        end
        if (streams["weektimer_timer3_openmin"] ~= nil) then
            mytable["weektimer_timer3_openmin"] = string2Int(
                                                      streams["weektimer_timer3_openmin"])
        end
        if (streams["weektimer_timer3_closehour"] ~= nil) then
            mytable["weektimer_timer3_closehour"] = string2Int(
                                                        streams["weektimer_timer3_closehour"])
        end
        if (streams["weektimer_timer3_closemin"] ~= nil) then
            mytable["weektimer_timer3_closemin"] = string2Int(
                                                       streams["weektimer_timer3_closemin"])
        end
        if (streams["weektimer_timer4_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["weektimer_timer4_mode"] = 2
        elseif (streams["weektimer_timer4_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["weektimer_timer4_mode"] = 3
        elseif (streams["weektimer_timer4_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["weektimer_timer4_mode"] = 5
        end
        if (streams["weektimer_timer4_temp"] ~= nil) then
            mytable["weektimer_timer4_temp"] = string2Int(
                                                   streams["weektimer_timer4_temp"])
        end
        if (streams["weektimer_timer4_openhour"] ~= nil) then
            mytable["weektimer_timer4_openhour"] = string2Int(
                                                       streams["weektimer_timer4_openhour"])
        end
        if (streams["weektimer_timer4_openmin"] ~= nil) then
            mytable["weektimer_timer4_openmin"] = string2Int(
                                                      streams["weektimer_timer4_openmin"])
        end
        if (streams["weektimer_timer4_closehour"] ~= nil) then
            mytable["weektimer_timer4_closehour"] = string2Int(
                                                        streams["weektimer_timer4_closehour"])
        end
        if (streams["weektimer_timer4_closemin"] ~= nil) then
            mytable["weektimer_timer4_closemin"] = string2Int(
                                                       streams["weektimer_timer4_closemin"])
        end
        if (streams["weektimer_timer5_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["weektimer_timer5_mode"] = 2
        elseif (streams["weektimer_timer5_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["weektimer_timer5_mode"] = 3
        elseif (streams["weektimer_timer5_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["weektimer_timer5_mode"] = 5
        end
        if (streams["weektimer_timer5_temp"] ~= nil) then
            mytable["weektimer_timer5_temp"] = string2Int(
                                                   streams["weektimer_timer5_temp"])
        end
        if (streams["weektimer_timer5_openhour"] ~= nil) then
            mytable["weektimer_timer5_openhour"] = string2Int(
                                                       streams["weektimer_timer5_openhour"])
        end
        if (streams["weektimer_timer5_openmin"] ~= nil) then
            mytable["weektimer_timer5_openmin"] = string2Int(
                                                      streams["weektimer_timer5_openmin"])
        end
        if (streams["weektimer_timer5_closehour"] ~= nil) then
            mytable["weektimer_timer5_closehour"] = string2Int(
                                                        streams["weektimer_timer5_closehour"])
        end
        if (streams["weektimer_timer5_closemin"] ~= nil) then
            mytable["weektimer_timer5_closemin"] = string2Int(
                                                       streams["weektimer_timer5_closemin"])
        end
        if (streams["weektimer_timer6_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["weektimer_timer6_mode"] = 2
        elseif (streams["weektimer_timer6_mode"] == uptable["VALUE_MODE_HEAT"]) then
            mytable["weektimer_timer6_mode"] = 3
        elseif (streams["weektimer_timer6_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["weektimer_timer6_mode"] = 5
        end
        if (streams["weektimer_timer6_temp"] ~= nil) then
            mytable["weektimer_timer6_temp"] = string2Int(
                                                   streams["weektimer_timer6_temp"])
        end
        if (streams["weektimer_timer6_openhour"] ~= nil) then
            mytable["weektimer_timer6_openhour"] = string2Int(
                                                       streams["weektimer_timer6_openhour"])
        end
        if (streams["weektimer_timer6_openmin"] ~= nil) then
            mytable["weektimer_timer6_openmin"] = string2Int(
                                                      streams["weektimer_timer6_openmin"])
        end
        if (streams["weektimer_timer6_closehour"] ~= nil) then
            mytable["weektimer_timer6_closehour"] = string2Int(
                                                        streams["weektimer_timer6_closehour"])
        end
        if (streams["weektimer_timer6_closemin"] ~= nil) then
            mytable["weektimer_timer6_closemin"] = string2Int(
                                                       streams["weektimer_timer6_closemin"])
        end

    elseif (mytable["controltype"] == 0x04) then
        if (streams["holidayaway_state"] == uptable["VALUE_ON"]) then
            mytable["holidayaway_state"] = uptable["BYTE_BIT0"]
        elseif (streams["holidayaway_state"] == uptable["VALUE_OFF"]) then
            mytable["holidayaway_state"] = 0
        end
        if (streams["holidayaway_startyear"] ~= nil) then
            mytable["holidayaway_startyear"] = string2Int(
                                                   streams["holidayaway_startyear"])
        end
        if (streams["holidayaway_startmonth"] ~= nil) then
            mytable["holidayaway_startmonth"] = string2Int(
                                                    streams["holidayaway_startmonth"])
        end
        if (streams["holidayaway_startdate"] ~= nil) then
            mytable["holidayaway_startdate"] = string2Int(
                                                   streams["holidayaway_startdate"])
        end
        if (streams["holidayaway_endyear"] ~= nil) then
            mytable["holidayaway_endyear"] = string2Int(
                                                 streams["holidayaway_endyear"])
        end
        if (streams["holidayaway_endmonth"] ~= nil) then
            mytable["holidayaway_endmonth"] = string2Int(
                                                  streams["holidayaway_endmonth"])
        end
        if (streams["holidayaway_enddate"] ~= nil) then
            mytable["holidayaway_enddate"] = string2Int(
                                                 streams["holidayaway_enddate"])
        end

    elseif (mytable["controltype"] == 0x05) then
        if (streams["silence_function_state"] == uptable["VALUE_ON"]) then
            mytable["silence_function_state"] = uptable["BYTE_BIT0"]
        elseif (streams["silence_function_state"] == uptable["VALUE_OFF"]) then
            mytable["silence_function_state"] = 0
        end
        if (streams["silence_timer1_state"] == uptable["VALUE_ON"]) then
            mytable["silence_timer1_state"] = uptable["BYTE_BIT2"]
        elseif (streams["silence_timer1_state"] == uptable["VALUE_OFF"]) then
            mytable["silence_timer1_state"] = 0
        end
        if (streams["silence_timer2_state"] == uptable["VALUE_ON"]) then
            mytable["silence_timer2_state"] = uptable["BYTE_BIT3"]
        elseif (streams["silence_timer2_state"] == uptable["VALUE_OFF"]) then
            mytable["silence_timer2_state"] = 0
        end
        if (streams["silence_function_level"] == uptable["LEVEL2"]) then
            mytable["silence_function_level"] = uptable["BYTE_BIT1"]
        elseif (streams["silence_function_level"] == uptable["LEVEL1"]) then
            mytable["silence_function_level"] = 0
        end
        if (streams["silence_timer1_starthour"] ~= nil) then
            mytable["silence_timer1_starthour"] = string2Int(
                                                      streams["silence_timer1_starthour"])
        end
        if (streams["silence_timer1_startmin"] ~= nil) then
            mytable["silence_timer1_startmin"] = string2Int(
                                                     streams["silence_timer1_startmin"])
        end
        if (streams["silence_timer1_endhour"] ~= nil) then
            mytable["silence_timer1_endhour"] = string2Int(
                                                    streams["silence_timer1_endhour"])
        end
        if (streams["silence_timer1_endmin"] ~= nil) then
            mytable["silence_timer1_endmin"] = string2Int(
                                                   streams["silence_timer1_endmin"])
        end
        if (streams["silence_timer2_starthour"] ~= nil) then
            mytable["silence_timer2_starthour"] = string2Int(
                                                      streams["silence_timer2_starthour"])
        end
        if (streams["silence_timer2_startmin"] ~= nil) then
            mytable["silence_timer2_startmin"] = string2Int(
                                                     streams["silence_timer2_startmin"])
        end
        if (streams["silence_timer2_endhour"] ~= nil) then
            mytable["silence_timer2_endhour"] = string2Int(
                                                    streams["silence_timer2_endhour"])
        end
        if (streams["silence_timer2_endmin"] ~= nil) then
            mytable["silence_timer2_endmin"] = string2Int(
                                                   streams["silence_timer2_endmin"])
        end

    elseif (mytable["controltype"] == 0x06) then
        if (streams["holidayhome_state"] == uptable["VALUE_ON"]) then
            mytable["holidayhome_state"] = uptable["BYTE_BIT0"]
        elseif (streams["holidayhome_state"] == uptable["VALUE_OFF"]) then
            mytable["holidayhome_state"] = 0
        end
        if (streams["holidayhome_startyear"] ~= nil) then
            mytable["holidayhome_startyear"] = string2Int(
                                                   streams["holidayhome_startyear"])
        end
        if (streams["holidayhome_startmonth"] ~= nil) then
            mytable["holidayhome_startmonth"] = string2Int(
                                                    streams["holidayhome_startmonth"])
        end
        if (streams["holidayhome_startdate"] ~= nil) then
            mytable["holidayhome_startdate"] = string2Int(
                                                   streams["holidayhome_startdate"])
        end
        if (streams["holidayhome_endyear"] ~= nil) then
            mytable["holidayhome_endyear"] = string2Int(
                                                 streams["holidayhome_endyear"])
        end
        if (streams["holidayhome_endmonth"] ~= nil) then
            mytable["holidayhome_endmonth"] = string2Int(
                                                  streams["holidayhome_endmonth"])
        end
        if (streams["holidayhome_enddate"] ~= nil) then
            mytable["holidayhome_enddate"] = string2Int(
                                                 streams["holidayhome_enddate"])
        end
        if (streams["holhometimer_timer1en"] == uptable["VALUE_ON"]) then
            mytable["holhometimer_timer1en"] = uptable["BYTE_BIT0"]
        elseif (streams["holhometimer_timer1en"] == uptable["VALUE_OFF"]) then
            mytable["holhometimer_timer1en"] = 0
        end
        if (streams["holhometimer_timer2en"] == uptable["VALUE_ON"]) then
            mytable["holhometimer_timer2en"] = uptable["BYTE_BIT1"]
        elseif (streams["holhometimer_timer2en"] == uptable["VALUE_OFF"]) then
            mytable["holhometimer_timer2en"] = 0
        end
        if (streams["holhometimer_timer3en"] == uptable["VALUE_ON"]) then
            mytable["holhometimer_timer3en"] = uptable["BYTE_BIT2"]
        elseif (streams["holhometimer_timer3en"] == uptable["VALUE_OFF"]) then
            mytable["holhometimer_timer3en"] = 0
        end
        if (streams["holhometimer_timer4en"] == uptable["VALUE_ON"]) then
            mytable["holhometimer_timer4en"] = uptable["BYTE_BIT3"]
        elseif (streams["holhometimer_timer4en"] == uptable["VALUE_OFF"]) then
            mytable["holhometimer_timer4en"] = 0
        end
        if (streams["holhometimer_timer5en"] == uptable["VALUE_ON"]) then
            mytable["holhometimer_timer5en"] = uptable["BYTE_BIT4"]
        elseif (streams["holhometimer_timer5en"] == uptable["VALUE_OFF"]) then
            mytable["holhometimer_timer5en"] = 0
        end
        if (streams["holhometimer_timer6en"] == uptable["VALUE_ON"]) then
            mytable["holhometimer_timer6en"] = uptable["BYTE_BIT5"]
        elseif (streams["holhometimer_timer6en"] == uptable["VALUE_OFF"]) then
            mytable["holhometimer_timer6en"] = 0
        end
        if (streams["holhometimer_timer1_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["holhometimer_timer1_mode"] = 2
        elseif (streams["holhometimer_timer1_mode"] ==
            uptable["VALUE_MODE_HEAT"]) then
            mytable["holhometimer_timer1_mode"] = 3
        elseif (streams["holhometimer_timer1_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["holhometimer_timer1_mode"] = 5
        end
        if (streams["holhometimer_timer1_temp"] ~= nil) then
            mytable["holhometimer_timer1_temp"] = string2Int(
                                                      streams["holhometimer_timer1_temp"])
        end
        if (streams["holhometimer_timer1_openhour"] ~= nil) then
            mytable["holhometimer_timer1_openhour"] = string2Int(
                                                          streams["holhometimer_timer1_openhour"])
        end
        if (streams["holhometimer_timer1_openmin"] ~= nil) then
            mytable["holhometimer_timer1_openmin"] = string2Int(
                                                         streams["holhometimer_timer1_openmin"])
        end
        if (streams["holhometimer_timer1_closehour"] ~= nil) then
            mytable["holhometimer_timer1_closehour"] = string2Int(
                                                           streams["holhometimer_timer1_closehour"])
        end
        if (streams["holhometimer_timer1_closemin"] ~= nil) then
            mytable["holhometimer_timer1_closemin"] = string2Int(
                                                          streams["holhometimer_timer1_closemin"])
        end
        if (streams["holhometimer_timer2_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["holhometimer_timer2_mode"] = 2
        elseif (streams["holhometimer_timer2_mode"] ==
            uptable["VALUE_MODE_HEAT"]) then
            mytable["holhometimer_timer2_mode"] = 3
        elseif (streams["holhometimer_timer2_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["holhometimer_timer2_mode"] = 5
        end
        if (streams["holhometimer_timer2_temp"] ~= nil) then
            mytable["holhometimer_timer2_temp"] = string2Int(
                                                      streams["holhometimer_timer2_temp"])
        end
        if (streams["holhometimer_timer2_openhour"] ~= nil) then
            mytable["holhometimer_timer2_openhour"] = string2Int(
                                                          streams["holhometimer_timer2_openhour"])
        end
        if (streams["holhometimer_timer2_openmin"] ~= nil) then
            mytable["holhometimer_timer2_openmin"] = string2Int(
                                                         streams["holhometimer_timer2_openmin"])
        end
        if (streams["holhometimer_timer2_closehour"] ~= nil) then
            mytable["holhometimer_timer2_closehour"] = string2Int(
                                                           streams["holhometimer_timer2_closehour"])
        end
        if (streams["holhometimer_timer2_closemin"] ~= nil) then
            mytable["holhometimer_timer2_closemin"] = string2Int(
                                                          streams["holhometimer_timer2_closemin"])
        end
        if (streams["holhometimer_timer3_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["holhometimer_timer3_mode"] = 2
        elseif (streams["holhometimer_timer3_mode"] ==
            uptable["VALUE_MODE_HEAT"]) then
            mytable["holhometimer_timer3_mode"] = 3
        elseif (streams["holhometimer_timer3_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["holhometimer_timer3_mode"] = 5
        end
        if (streams["holhometimer_timer3_temp"] ~= nil) then
            mytable["holhometimer_timer3_temp"] = string2Int(
                                                      streams["holhometimer_timer3_temp"])
        end
        if (streams["holhometimer_timer3_openhour"] ~= nil) then
            mytable["holhometimer_timer3_openhour"] = string2Int(
                                                          streams["holhometimer_timer3_openhour"])
        end
        if (streams["holhometimer_timer3_openmin"] ~= nil) then
            mytable["holhometimer_timer3_openmin"] = string2Int(
                                                         streams["holhometimer_timer3_openmin"])
        end
        if (streams["holhometimer_timer3_closehour"] ~= nil) then
            mytable["holhometimer_timer3_closehour"] = string2Int(
                                                           streams["holhometimer_timer3_closehour"])
        end
        if (streams["holhometimer_timer3_closemin"] ~= nil) then
            mytable["holhometimer_timer3_closemin"] = string2Int(
                                                          streams["holhometimer_timer3_closemin"])
        end
        if (streams["holhometimer_timer4_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["holhometimer_timer4_mode"] = 2
        elseif (streams["holhometimer_timer4_mode"] ==
            uptable["VALUE_MODE_HEAT"]) then
            mytable["holhometimer_timer4_mode"] = 3
        elseif (streams["holhometimer_timer4_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["holhometimer_timer4_mode"] = 5
        end
        if (streams["holhometimer_timer4_temp"] ~= nil) then
            mytable["holhometimer_timer4_temp"] = string2Int(
                                                      streams["holhometimer_timer4_temp"])
        end
        if (streams["holhometimer_timer4_openhour"] ~= nil) then
            mytable["holhometimer_timer4_openhour"] = string2Int(
                                                          streams["holhometimer_timer4_openhour"])
        end
        if (streams["holhometimer_timer4_openmin"] ~= nil) then
            mytable["holhometimer_timer4_openmin"] = string2Int(
                                                         streams["holhometimer_timer4_openmin"])
        end
        if (streams["holhometimer_timer4_closehour"] ~= nil) then
            mytable["holhometimer_timer4_closehour"] = string2Int(
                                                           streams["holhometimer_timer4_closehour"])
        end
        if (streams["holhometimer_timer4_closemin"] ~= nil) then
            mytable["holhometimer_timer4_closemin"] = string2Int(
                                                          streams["holhometimer_timer4_closemin"])
        end
        if (streams["holhometimer_timer5_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["holhometimer_timer5_mode"] = 2
        elseif (streams["holhometimer_timer5_mode"] ==
            uptable["VALUE_MODE_HEAT"]) then
            mytable["holhometimer_timer5_mode"] = 3
        elseif (streams["holhometimer_timer5_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["holhometimer_timer5_mode"] = 5
        end
        if (streams["holhometimer_timer5_temp"] ~= nil) then
            mytable["holhometimer_timer5_temp"] = string2Int(
                                                      streams["holhometimer_timer5_temp"])
        end
        if (streams["holhometimer_timer5_openhour"] ~= nil) then
            mytable["holhometimer_timer5_openhour"] = string2Int(
                                                          streams["holhometimer_timer5_openhour"])
        end
        if (streams["holhometimer_timer5_openmin"] ~= nil) then
            mytable["holhometimer_timer5_openmin"] = string2Int(
                                                         streams["holhometimer_timer5_openmin"])
        end
        if (streams["holhometimer_timer5_closehour"] ~= nil) then
            mytable["holhometimer_timer5_closehour"] = string2Int(
                                                           streams["holhometimer_timer5_closehour"])
        end
        if (streams["holhometimer_timer5_closemin"] ~= nil) then
            mytable["holhometimer_timer5_closemin"] = string2Int(
                                                          streams["holhometimer_timer5_closemin"])
        end
        if (streams["holhometimer_timer6_mode"] == uptable["VALUE_MODE_COOL"]) then
            mytable["holhometimer_timer6_mode"] = 2
        elseif (streams["holhometimer_timer6_mode"] ==
            uptable["VALUE_MODE_HEAT"]) then
            mytable["holhometimer_timer6_mode"] = 3
        elseif (streams["holhometimer_timer6_mode"] == uptable["VALUE_MODE_DHW"]) then
            mytable["holhometimer_timer6_mode"] = 5
        end
        if (streams["holhometimer_timer6_temp"] ~= nil) then
            mytable["holhometimer_timer6_temp"] = string2Int(
                                                      streams["holhometimer_timer6_temp"])
        end
        if (streams["holhometimer_timer6_openhour"] ~= nil) then
            mytable["holhometimer_timer6_openhour"] = string2Int(
                                                          streams["holhometimer_timer6_openhour"])
        end
        if (streams["holhometimer_timer6_openmin"] ~= nil) then
            mytable["holhometimer_timer6_openmin"] = string2Int(
                                                         streams["holhometimer_timer6_openmin"])
        end
        if (streams["holhometimer_timer6_closehour"] ~= nil) then
            mytable["holhometimer_timer6_closehour"] = string2Int(
                                                           streams["holhometimer_timer6_closehour"])
        end
        if (streams["holhometimer_timer6_closemin"] ~= nil) then
            mytable["holhometimer_timer6_closemin"] = string2Int(
                                                          streams["holhometimer_timer6_closemin"])
        end

    elseif (mytable["controltype"] == 0x07) then
        if (streams["eco_function_state"] == uptable["VALUE_ON"]) then
            mytable["eco_function_state"] = uptable["BYTE_BIT0"]
        elseif (streams["eco_function_state"] == uptable["VALUE_OFF"]) then
            mytable["eco_function_state"] = 0
        end
        if (streams["eco_timer_state"] == uptable["VALUE_ON"]) then
            mytable["eco_timer_state"] = uptable["BYTE_BIT1"]
        elseif (streams["eco_timer_state"] == uptable["VALUE_OFF"]) then
            mytable["eco_timer_state"] = 0
        end
        if (streams["eco_timer_starthour"] ~= nil) then
            mytable["eco_timer_starthour"] = string2Int(
                                                 streams["eco_timer_starthour"])
        end
        if (streams["eco_timer_startmin"] ~= nil) then
            mytable["eco_timer_startmin"] = string2Int(
                                                streams["eco_timer_startmin"])
        end
        if (streams["eco_timer_endhour"] ~= nil) then
            mytable["eco_timer_endhour"] = string2Int(
                                               streams["eco_timer_endhour"])
        end
        if (streams["eco_timer_endmin"] ~= nil) then
            mytable["eco_timer_endmin"] =
                string2Int(streams["eco_timer_endmin"])
        end
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local infoM = {}
    local bodyBytes = {}
    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (query) then
        mytable["queryType"] = 0x01;
        if (query["query_type"] ~= nil) then
            mytable["queryType"] = string2Int(query["query_type"])
        end
        mytable["weekdayquery"] = 0x00;
        if (query["weekday_query"] ~= nil) then
            mytable["weekdayquery"] = string2Int(query["weekday_query"])
        end
        if (mytable["queryType"] == 0x01) then
            bodyBytes[0] = 0x01
        elseif (mytable["queryType"] == 0x02) then
            bodyBytes[0] = 0x02
        elseif (mytable["queryType"] == 0x03) then
            bodyBytes[0] = 0x03
            if (mytable["weekdayquery"] == 0x01) then
                bodyBytes[1] = uptable["BYTE_BIT0"]
            elseif (mytable["weekdayquery"] == 0x02) then
                bodyBytes[1] = uptable["BYTE_BIT1"]
            elseif (mytable["weekdayquery"] == 0x03) then
                bodyBytes[1] = uptable["BYTE_BIT2"]
            elseif (mytable["weekdayquery"] == 0x04) then
                bodyBytes[1] = uptable["BYTE_BIT3"]
            elseif (mytable["weekdayquery"] == 0x05) then
                bodyBytes[1] = uptable["BYTE_BIT4"]
            elseif (mytable["weekdayquery"] == 0x06) then
                bodyBytes[1] = uptable["BYTE_BIT5"]
            elseif (mytable["weekdayquery"] == 0x07) then
                bodyBytes[1] = uptable["BYTE_BIT6"]
            end
        elseif (mytable["queryType"] == 0x04) then
            bodyBytes[0] = 0x04
        elseif (mytable["queryType"] == 0x05) then
            bodyBytes[0] = 0x05
        elseif (mytable["queryType"] == 0x06) then
            bodyBytes[0] = 0x06
        elseif (mytable["queryType"] == 0x07) then
            bodyBytes[0] = 0x07
        end
        infoM = getTotalMsg(bodyBytes, uptable["BYTE_QUERY_STATUS_REQUEST"])
    elseif (control) then
        if (status) then jsonToModel(status) end
        if (control) then jsonToModel(control) end
        for i = 0, 4 do bodyBytes[i] = 0 end

        if (mytable["controltype"] == 0x01) then
            bodyBytes[0] = 0x01
            bodyBytes[1] = mytable["power_state"]
            bodyBytes[2] = mytable["run_mode"]
            bodyBytes[3] = mytable["temp_set"]
            bodyBytes[4] = mytable["pre_heat"]

        elseif (mytable["controltype"] == 0x02) then
            bodyBytes[0] = 0x02
            bodyBytes[1] = bit.bor(bit.bor(
                                       bit.bor(bit.bor(bit.bor(
                                                           mytable["daytimer_timer1en"],
                                                           mytable["daytimer_timer2en"]),
                                                       mytable["daytimer_timer3en"]),
                                               mytable["daytimer_timer4en"]),
                                       mytable["daytimer_timer5en"]),
                                   mytable["daytimer_timer6en"])
            bodyBytes[2] = mytable["daytimer_timer1_mode"]
            bodyBytes[3] = mytable["daytimer_timer1_temp"]
            bodyBytes[4] = mytable["daytimer_timer1_openhour"]
            bodyBytes[5] = mytable["daytimer_timer1_openmin"]
            bodyBytes[6] = mytable["daytimer_timer1_closehour"]
            bodyBytes[7] = mytable["daytimer_timer1_closemin"]
            bodyBytes[8] = mytable["daytimer_timer2_mode"]
            bodyBytes[9] = mytable["daytimer_timer2_temp"]
            bodyBytes[10] = mytable["daytimer_timer2_openhour"]
            bodyBytes[11] = mytable["daytimer_timer2_openmin"]
            bodyBytes[12] = mytable["daytimer_timer2_closehour"]
            bodyBytes[13] = mytable["daytimer_timer2_closemin"]
            bodyBytes[14] = mytable["daytimer_timer3_mode"]
            bodyBytes[15] = mytable["daytimer_timer3_temp"]
            bodyBytes[16] = mytable["daytimer_timer3_openhour"]
            bodyBytes[17] = mytable["daytimer_timer3_openmin"]
            bodyBytes[18] = mytable["daytimer_timer3_closehour"]
            bodyBytes[19] = mytable["daytimer_timer3_closemin"]
            bodyBytes[20] = mytable["daytimer_timer4_mode"]
            bodyBytes[21] = mytable["daytimer_timer4_temp"]
            bodyBytes[22] = mytable["daytimer_timer4_openhour"]
            bodyBytes[23] = mytable["daytimer_timer4_openmin"]
            bodyBytes[24] = mytable["daytimer_timer4_closehour"]
            bodyBytes[25] = mytable["daytimer_timer4_closemin"]
            bodyBytes[26] = mytable["daytimer_timer5_mode"]
            bodyBytes[27] = mytable["daytimer_timer5_temp"]
            bodyBytes[28] = mytable["daytimer_timer5_openhour"]
            bodyBytes[29] = mytable["daytimer_timer5_openmin"]
            bodyBytes[30] = mytable["daytimer_timer5_closehour"]
            bodyBytes[31] = mytable["daytimer_timer5_closemin"]
            bodyBytes[32] = mytable["daytimer_timer6_mode"]
            bodyBytes[33] = mytable["daytimer_timer6_temp"]
            bodyBytes[34] = mytable["daytimer_timer6_openhour"]
            bodyBytes[35] = mytable["daytimer_timer6_openmin"]
            bodyBytes[36] = mytable["daytimer_timer6_closehour"]
            bodyBytes[37] = mytable["daytimer_timer6_closemin"]

        elseif (mytable["controltype"] == 0x03) then
            bodyBytes[0] = 0x03
            bodyBytes[1] = bit.lshift(1, mytable["weektimer_setday"])
            bodyBytes[2] = bit.bor(bit.bor(
                                       bit.bor(bit.bor(bit.bor(
                                                           mytable["weektimer_timer1en"],
                                                           mytable["weektimer_timer2en"]),
                                                       mytable["weektimer_timer3en"]),
                                               mytable["weektimer_timer4en"]),
                                       mytable["weektimer_timer5en"]),
                                   mytable["weektimer_timer6en"])
            bodyBytes[3] = mytable["weektimer_timer1_mode"]
            bodyBytes[4] = mytable["weektimer_timer1_temp"]
            bodyBytes[5] = mytable["weektimer_timer1_openhour"]
            bodyBytes[6] = mytable["weektimer_timer1_openmin"]
            bodyBytes[7] = mytable["weektimer_timer1_closehour"]
            bodyBytes[8] = mytable["weektimer_timer1_closemin"]
            bodyBytes[9] = mytable["weektimer_timer2_mode"]
            bodyBytes[10] = mytable["weektimer_timer2_temp"]
            bodyBytes[11] = mytable["weektimer_timer2_openhour"]
            bodyBytes[12] = mytable["weektimer_timer2_openmin"]
            bodyBytes[13] = mytable["weektimer_timer2_closehour"]
            bodyBytes[14] = mytable["weektimer_timer2_closemin"]
            bodyBytes[15] = mytable["weektimer_timer3_mode"]
            bodyBytes[16] = mytable["weektimer_timer3_temp"]
            bodyBytes[17] = mytable["weektimer_timer3_openhour"]
            bodyBytes[18] = mytable["weektimer_timer3_openmin"]
            bodyBytes[19] = mytable["weektimer_timer3_closehour"]
            bodyBytes[20] = mytable["weektimer_timer3_closemin"]
            bodyBytes[21] = mytable["weektimer_timer4_mode"]
            bodyBytes[22] = mytable["weektimer_timer4_temp"]
            bodyBytes[23] = mytable["weektimer_timer4_openhour"]
            bodyBytes[24] = mytable["weektimer_timer4_openmin"]
            bodyBytes[25] = mytable["weektimer_timer4_closehour"]
            bodyBytes[26] = mytable["weektimer_timer4_closemin"]
            bodyBytes[27] = mytable["weektimer_timer5_mode"]
            bodyBytes[28] = mytable["weektimer_timer5_temp"]
            bodyBytes[29] = mytable["weektimer_timer5_openhour"]
            bodyBytes[30] = mytable["weektimer_timer5_openmin"]
            bodyBytes[31] = mytable["weektimer_timer5_closehour"]
            bodyBytes[32] = mytable["weektimer_timer5_closemin"]
            bodyBytes[33] = mytable["weektimer_timer6_mode"]
            bodyBytes[34] = mytable["weektimer_timer6_temp"]
            bodyBytes[35] = mytable["weektimer_timer6_openhour"]
            bodyBytes[36] = mytable["weektimer_timer6_openmin"]
            bodyBytes[37] = mytable["weektimer_timer6_closehour"]
            bodyBytes[38] = mytable["weektimer_timer6_closemin"]

        elseif (mytable["controltype"] == 0x04) then
            bodyBytes[0] = 0x04
            bodyBytes[1] = mytable["holidayaway_state"]
            bodyBytes[2] = mytable["holidayaway_startyear"]
            bodyBytes[3] = mytable["holidayaway_startmonth"]
            bodyBytes[4] = mytable["holidayaway_startdate"]
            bodyBytes[5] = mytable["holidayaway_endyear"]
            bodyBytes[6] = mytable["holidayaway_endmonth"]
            bodyBytes[7] = mytable["holidayaway_enddate"]

        elseif (mytable["controltype"] == 0x05) then
            bodyBytes[0] = 0x05
            bodyBytes[1] = bit.bor(bit.bor(bit.bor(
                                               mytable["silence_function_state"],
                                               mytable["silence_function_level"]),
                                           mytable["silence_timer1_state"]),
                                   mytable["silence_timer2_state"])
            bodyBytes[2] = mytable["silence_timer1_starthour"]
            bodyBytes[3] = mytable["silence_timer1_startmin"]
            bodyBytes[4] = mytable["silence_timer1_endhour"]
            bodyBytes[5] = mytable["silence_timer1_endmin"]
            bodyBytes[6] = mytable["silence_timer2_starthour"]
            bodyBytes[7] = mytable["silence_timer2_startmin"]
            bodyBytes[8] = mytable["silence_timer2_endhour"]
            bodyBytes[9] = mytable["silence_timer2_endmin"]

        elseif (mytable["controltype"] == 0x06) then
            bodyBytes[0] = 0x06
            bodyBytes[1] = mytable["holidayhome_state"]
            bodyBytes[2] = mytable["holidayhome_startyear"]
            bodyBytes[3] = mytable["holidayhome_startmonth"]
            bodyBytes[4] = mytable["holidayhome_startdate"]
            bodyBytes[5] = mytable["holidayhome_endyear"]
            bodyBytes[6] = mytable["holidayhome_endmonth"]
            bodyBytes[7] = mytable["holidayhome_enddate"]
            bodyBytes[8] = bit.bor(bit.bor(
                                       bit.bor(bit.bor(bit.bor(
                                                           mytable["holhometimer_timer1en"],
                                                           mytable["holhometimer_timer2en"]),
                                                       mytable["holhometimer_timer3en"]),
                                               mytable["holhometimer_timer4en"]),
                                       mytable["holhometimer_timer5en"]),
                                   mytable["holhometimer_timer6en"])
            bodyBytes[9] = mytable["holhometimer_timer1_mode"]
            bodyBytes[10] = mytable["holhometimer_timer1_temp"]
            bodyBytes[11] = mytable["holhometimer_timer1_openhour"]
            bodyBytes[12] = mytable["holhometimer_timer1_openmin"]
            bodyBytes[13] = mytable["holhometimer_timer1_closehour"]
            bodyBytes[14] = mytable["holhometimer_timer1_closemin"]
            bodyBytes[15] = mytable["holhometimer_timer2_mode"]
            bodyBytes[16] = mytable["holhometimer_timer2_temp"]
            bodyBytes[17] = mytable["holhometimer_timer2_openhour"]
            bodyBytes[18] = mytable["holhometimer_timer2_openmin"]
            bodyBytes[19] = mytable["holhometimer_timer2_closehour"]
            bodyBytes[20] = mytable["holhometimer_timer2_closemin"]
            bodyBytes[21] = mytable["holhometimer_timer3_mode"]
            bodyBytes[22] = mytable["holhometimer_timer3_temp"]
            bodyBytes[23] = mytable["holhometimer_timer3_openhour"]
            bodyBytes[24] = mytable["holhometimer_timer3_openmin"]
            bodyBytes[25] = mytable["holhometimer_timer3_closehour"]
            bodyBytes[26] = mytable["holhometimer_timer3_closemin"]
            bodyBytes[27] = mytable["holhometimer_timer4_mode"]
            bodyBytes[28] = mytable["holhometimer_timer4_temp"]
            bodyBytes[29] = mytable["holhometimer_timer4_openhour"]
            bodyBytes[30] = mytable["holhometimer_timer4_openmin"]
            bodyBytes[31] = mytable["holhometimer_timer4_closehour"]
            bodyBytes[32] = mytable["holhometimer_timer4_closemin"]
            bodyBytes[33] = mytable["holhometimer_timer5_mode"]
            bodyBytes[34] = mytable["holhometimer_timer5_temp"]
            bodyBytes[35] = mytable["holhometimer_timer5_openhour"]
            bodyBytes[36] = mytable["holhometimer_timer5_openmin"]
            bodyBytes[37] = mytable["holhometimer_timer5_closehour"]
            bodyBytes[38] = mytable["holhometimer_timer5_closemin"]
            bodyBytes[39] = mytable["holhometimer_timer6_mode"]
            bodyBytes[40] = mytable["holhometimer_timer6_temp"]
            bodyBytes[41] = mytable["holhometimer_timer6_openhour"]
            bodyBytes[42] = mytable["holhometimer_timer6_openmin"]
            bodyBytes[43] = mytable["holhometimer_timer6_closehour"]
            bodyBytes[44] = mytable["holhometimer_timer6_closehour"]

        elseif (mytable["controltype"] == 0x07) then
            bodyBytes[0] = 0x07
            bodyBytes[1] = bit.bor(mytable["eco_function_state"],
                                   mytable["eco_timer_state"])
            bodyBytes[2] = mytable["eco_timer_starthour"]
            bodyBytes[3] = mytable["eco_timer_startmin"]
            bodyBytes[4] = mytable["eco_timer_endhour"]
            bodyBytes[5] = mytable["eco_timer_endmin"]
        end
        infoM = getTotalMsg(bodyBytes, uptable["BYTE_CONTROL_REQUEST"])
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function dataToJson(jsonCmd)
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubtype"]
    if (deviceSubType == 1) then end
    local status = json["status"]
    if (status) then jsonToModel(status) end
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[10];
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - uptable["BYTE_PROTOCOL_LENGTH"] - 1
    msgType = msgBytes[9]
    msgSubType = msgBytes[10]
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]]
    end
    binToModel(dataType, bodyLength, bodyBytes)
    local streams = {}
    streams["version"] = uptable["VERSION"]

    if ((msgType == 0x02 and msgSubType == 0x01) or
        ((msgType == 0x03) and (msgSubType == 0x01)) or (msgType == 0x04)) then
        if (mytable["power_state"] == uptable["BYTE_BIT0"]) then
            streams[uptable["KEY_POWER_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_POWER_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["pre_heat"] == uptable["BYTE_BIT1"]) then
            streams[uptable["KEY_PRE_HEAT"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_PRE_HEAT"]] = uptable["VALUE_OFF"]
        end
        if (mytable["silence_set_state"] == uptable["BYTE_BIT2"]) then
            streams[uptable["KEY_SILENCE_SET_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_SILENCE_SET_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["holiday_set_state"] == uptable["BYTE_BIT3"]) then
            streams[uptable["KEY_HOLIDAY_SET_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_HOLIDAY_SET_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["holiday_on_state"] == uptable["BYTE_BIT4"]) then
            streams[uptable["KEY_HOLIDAY_ON_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_HOLIDAY_ON_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["time_set_state"] == uptable["BYTE_BIT4"]) then
            streams[uptable["KEY_TIME_SET_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_TIME_SET_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["heat_enable"] == uptable["BYTE_BIT0"]) then
            streams[uptable["KEY_HEAT_ENABLE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_HEAT_ENABLE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["cool_enable"] == uptable["BYTE_BIT1"]) then
            streams[uptable["KEY_COOL_ENABLE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_COOL_ENABLE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["temp_type"] == uptable["BYTE_BIT2"]) then
            streams[uptable["KEY_TEMP_TYPE"]] = uptable["VALUE_WATER"]
        else
            streams[uptable["KEY_TEMP_TYPE"]] = uptable["VALUE_AIR"]
        end
        if (mytable["room_temp_ctrl"] == uptable["BYTE_BIT3"]) then
            streams[uptable["KEY_ROOM_TEMP_CTRL"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_ROOM_TEMP_CTRL"]] = uptable["VALUE_OFF"]
        end
        if (mytable["room_temp_set"] == uptable["BYTE_BIT4"]) then
            streams[uptable["KEY_ROOM_TEMP_SET"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_ROOM_TEMP_SET"]] = uptable["VALUE_OFF"]
        end
        if (mytable["comp_state"] == uptable["BYTE_BIT0"]) then
            streams[uptable["KEY_COMP_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_COMP_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["silence_state"] == uptable["BYTE_BIT1"]) then
            streams[uptable["KEY_SILENCE_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_SILENCE_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["day_time_state"] == uptable["BYTE_BIT2"]) then
            streams[uptable["KEY_DAY_TIME_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_DAY_TIME_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["week_time_state"] == uptable["BYTE_BIT3"]) then
            streams[uptable["KEY_WEEK_TIME_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_WEEK_TIME_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["warn_state"] == uptable["BYTE_BIT4"]) then
            streams[uptable["KEY_WARN_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_WARN_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["defrost_state"] == uptable["BYTE_BIT5"]) then
            streams[uptable["KEY_DEFROST_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_DEFROST_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["freeze_state"] == uptable["BYTE_BIT6"]) then
            streams[uptable["KEY_FREEZE_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_FREEZE_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["holiday_state"] == uptable["BYTE_BIT7"]) then
            streams[uptable["KEY_HOLIDAY_STATE"]] = uptable["VALUE_ON"]
        else
            streams[uptable["KEY_HOLIDAY_STATE"]] = uptable["VALUE_OFF"]
        end
        if (mytable["run_mode"] == 1) then
            streams[uptable["KEY_RUN_MODE"]] = uptable["VALUE_MODE_AUTO"]
        elseif (mytable["run_mode"] == 2) then
            streams[uptable["KEY_RUN_MODE"]] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["run_mode"] == 3) then
            streams[uptable["KEY_RUN_MODE"]] = uptable["VALUE_MODE_HEAT"]
        end
        streams[uptable["KEY_TEMP_SET"]] = int2String(mytable["temp_set"])
        streams[uptable["KEY_CUR_TEMP"]] = int2String(mytable["cur_temp"])
        streams[uptable["KEY_HEAT_MAX_SET_TEMP"]] = int2String(
                                                        mytable["heat_max_set_temp"])
        streams[uptable["KEY_HEAT_MIN_SET_TEMP"]] = int2String(
                                                        mytable["heat_min_set_temp"])
        streams[uptable["KEY_COOL_MAX_SET_TEMP"]] = int2String(
                                                        mytable["cool_max_set_temp"])
        streams[uptable["KEY_COOL_MIN_SET_TEMP"]] = int2String(
                                                        mytable["cool_min_set_temp"])
        streams[uptable["KEY_AUTO_MAX_SET_TEMP"]] = int2String(
                                                        mytable["auto_max_set_temp"])
        streams[uptable["KEY_AUTO_MIN_SET_TEMP"]] = int2String(
                                                        mytable["auto_min_set_temp"])
        streams[uptable["KEY_PREHEAT_ON_SET_TEMP"]] = int2String(
                                                          mytable["preheat_on_set_temp"])
        streams[uptable["KEY_PREHEAT_MAX_SET_TEMP"]] = int2String(
                                                           mytable["preheat_max_set_temp"])
        streams[uptable["KEY_PREHEAT_MIN_SET_TEMP"]] = int2String(
                                                           mytable["preheat_min_set_temp"])
        streams[uptable["KEY_CUR_ERRCODE"]] = int2String(mytable["cur_errcode"])

    elseif ((msgType == 0x03) and (msgSubType == 0x02)) then
        if (mytable["daytimer_timer1en"] == 0x01) then
            streams["daytimer_timer1en"] = uptable["VALUE_ON"]
        else
            streams["daytimer_timer1en"] = uptable["VALUE_OFF"]
        end
        if (mytable["daytimer_timer2en"] == 0x01) then
            streams["daytimer_timer2en"] = uptable["VALUE_ON"]
        else
            streams["daytimer_timer2en"] = uptable["VALUE_OFF"]
        end
        if (mytable["daytimer_timer3en"] == 0x01) then
            streams["daytimer_timer3en"] = uptable["VALUE_ON"]
        else
            streams["daytimer_timer3en"] = uptable["VALUE_OFF"]
        end
        if (mytable["daytimer_timer4en"] == 0x01) then
            streams["daytimer_timer4en"] = uptable["VALUE_ON"]
        else
            streams["daytimer_timer4en"] = uptable["VALUE_OFF"]
        end
        if (mytable["daytimer_timer5en"] == 0x01) then
            streams["daytimer_timer5en"] = uptable["VALUE_ON"]
        else
            streams["daytimer_timer5en"] = uptable["VALUE_OFF"]
        end
        if (mytable["daytimer_timer6en"] == 0x01) then
            streams["daytimer_timer6en"] = uptable["VALUE_ON"]
        else
            streams["daytimer_timer6en"] = uptable["VALUE_OFF"]
        end
        if (mytable["daytimer_timer1_mode"] == 2) then
            streams["daytimer_timer1_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["daytimer_timer1_mode"] == 3) then
            streams["daytimer_timer1_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["daytimer_timer1_mode"] == 5) then
            streams["daytimer_timer1_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["daytimer_timer1_temp"] = int2String(
                                              mytable["daytimer_timer1_temp"])
        streams["daytimer_timer1_openhour"] = int2String(
                                                  mytable["daytimer_timer1_openhour"])
        streams["daytimer_timer1_openmin"] = int2String(
                                                 mytable["daytimer_timer1_openmin"])
        streams["daytimer_timer1_closehour"] = int2String(
                                                   mytable["daytimer_timer1_closehour"])
        streams["daytimer_timer1_closemin"] = int2String(
                                                  mytable["daytimer_timer1_closemin"])
        if (mytable["daytimer_timer2_mode"] == 2) then
            streams["daytimer_timer2_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["daytimer_timer2_mode"] == 3) then
            streams["daytimer_timer2_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["daytimer_timer2_mode"] == 5) then
            streams["daytimer_timer2_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["daytimer_timer2_temp"] = int2String(
                                              mytable["daytimer_timer2_temp"])
        streams["daytimer_timer2_openhour"] = int2String(
                                                  mytable["daytimer_timer2_openhour"])
        streams["daytimer_timer2_openmin"] = int2String(
                                                 mytable["daytimer_timer2_openmin"])
        streams["daytimer_timer2_closehour"] = int2String(
                                                   mytable["daytimer_timer2_closehour"])
        streams["daytimer_timer2_closemin"] = int2String(
                                                  mytable["daytimer_timer2_closemin"])
        if (mytable["daytimer_timer3_mode"] == 2) then
            streams["daytimer_timer3_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["daytimer_timer3_mode"] == 3) then
            streams["daytimer_timer3_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["daytimer_timer3_mode"] == 5) then
            streams["daytimer_timer3_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["daytimer_timer3_temp"] = int2String(
                                              mytable["daytimer_timer3_temp"])
        streams["daytimer_timer3_openhour"] = int2String(
                                                  mytable["daytimer_timer3_openhour"])
        streams["daytimer_timer3_openmin"] = int2String(
                                                 mytable["daytimer_timer3_openmin"])
        streams["daytimer_timer3_closehour"] = int2String(
                                                   mytable["daytimer_timer3_closehour"])
        streams["daytimer_timer3_closemin"] = int2String(
                                                  mytable["daytimer_timer3_closemin"])
        if (mytable["daytimer_timer4_mode"] == 2) then
            streams["daytimer_timer4_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["daytimer_timer4_mode"] == 3) then
            streams["daytimer_timer4_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["daytimer_timer4_mode"] == 5) then
            streams["daytimer_timer4_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["daytimer_timer4_temp"] = int2String(
                                              mytable["daytimer_timer4_temp"])
        streams["daytimer_timer4_openhour"] = int2String(
                                                  mytable["daytimer_timer4_openhour"])
        streams["daytimer_timer4_openmin"] = int2String(
                                                 mytable["daytimer_timer4_openmin"])
        streams["daytimer_timer4_closehour"] = int2String(
                                                   mytable["daytimer_timer4_closehour"])
        streams["daytimer_timer4_closemin"] = int2String(
                                                  mytable["daytimer_timer4_closemin"])
        if (mytable["daytimer_timer5_mode"] == 2) then
            streams["daytimer_timer5_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["daytimer_timer5_mode"] == 3) then
            streams["daytimer_timer5_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["daytimer_timer5_mode"] == 5) then
            streams["daytimer_timer5_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["daytimer_timer5_temp"] = int2String(
                                              mytable["daytimer_timer5_temp"])
        streams["daytimer_timer5_openhour"] = int2String(
                                                  mytable["daytimer_timer5_openhour"])
        streams["daytimer_timer5_openmin"] = int2String(
                                                 mytable["daytimer_timer5_openmin"])
        streams["daytimer_timer5_closehour"] = int2String(
                                                   mytable["daytimer_timer5_closehour"])
        streams["daytimer_timer5_closemin"] = int2String(
                                                  mytable["daytimer_timer5_closemin"])
        if (mytable["daytimer_timer6_mode"] == 2) then
            streams["daytimer_timer6_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["daytimer_timer6_mode"] == 3) then
            streams["daytimer_timer6_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["daytimer_timer6_mode"] == 5) then
            streams["daytimer_timer6_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["daytimer_timer6_temp"] = int2String(
                                              mytable["daytimer_timer6_temp"])
        streams["daytimer_timer6_openhour"] = int2String(
                                                  mytable["daytimer_timer6_openhour"])
        streams["daytimer_timer6_openmin"] = int2String(
                                                 mytable["daytimer_timer6_openmin"])
        streams["daytimer_timer6_closehour"] = int2String(
                                                   mytable["daytimer_timer6_closehour"])
        streams["daytimer_timer6_closemin"] = int2String(
                                                  mytable["daytimer_timer6_closemin"])

    elseif ((msgType == 0x03) and (msgSubType == 0x03)) then
        streams["queryweekday"] = int2String(mytable["queryweekday"])
        if (mytable["weektimer_timer1en"] == 0x01) then
            streams["weektimer_timer1en"] = uptable["VALUE_ON"]
        else
            streams["weektimer_timer1en"] = uptable["VALUE_OFF"]
        end
        if (mytable["weektimer_timer2en"] == 0x01) then
            streams["weektimer_timer2en"] = uptable["VALUE_ON"]
        else
            streams["weektimer_timer2en"] = uptable["VALUE_OFF"]
        end
        if (mytable["weektimer_timer3en"] == 0x01) then
            streams["weektimer_timer3en"] = uptable["VALUE_ON"]
        else
            streams["weektimer_timer3en"] = uptable["VALUE_OFF"]
        end
        if (mytable["weektimer_timer4en"] == 0x01) then
            streams["weektimer_timer4en"] = uptable["VALUE_ON"]
        else
            streams["Weektimer_timer4En"] = uptable["VALUE_OFF"]
        end
        if (mytable["weektimer_timer5en"] == 0x01) then
            streams["weektimer_timer5en"] = uptable["VALUE_ON"]
        else
            streams["weektimer_timer5en"] = uptable["VALUE_OFF"]
        end
        if (mytable["weektimer_timer6en"] == 0x01) then
            streams["weektimer_timer6en"] = uptable["VALUE_ON"]
        else
            streams["weektimer_timer6en"] = uptable["VALUE_OFF"]
        end
        if (mytable["weektimer_timer1_mode"] == 2) then
            streams["weektimer_timer1_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["weektimer_timer1_mode"] == 3) then
            streams["weektimer_timer1_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["weektimer_timer1_mode"] == 5) then
            streams["weektimer_timer1_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["weektimer_timer1_temp"] = int2String(
                                               mytable["weektimer_timer1_temp"])
        streams["weektimer_timer1_openhour"] = int2String(
                                                   mytable["weektimer_timer1_openhour"])
        streams["weektimer_timer1_openmin"] = int2String(
                                                  mytable["weektimer_timer1_openmin"])
        streams["weektimer_timer1_closehour"] = int2String(
                                                    mytable["weektimer_timer1_closehour"])
        streams["weektimer_timer1_closemin"] = int2String(
                                                   mytable["weektimer_timer1_closemin"])
        if (mytable["weektimer_timer2_mode"] == 2) then
            streams["weektimer_timer2_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["weektimer_timer2_mode"] == 3) then
            streams["weektimer_timer2_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["weektimer_timer2_mode"] == 5) then
            streams["weektimer_timer2_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["weektimer_timer2_temp"] = int2String(
                                               mytable["weektimer_timer2_temp"])
        streams["weektimer_timer2_openhour"] = int2String(
                                                   mytable["weektimer_timer2_openhour"])
        streams["weektimer_timer2_openmin"] = int2String(
                                                  mytable["weektimer_timer2_openmin"])
        streams["weektimer_timer2_closehour"] = int2String(
                                                    mytable["weektimer_timer2_closehour"])
        streams["weektimer_timer2_closemin"] = int2String(
                                                   mytable["weektimer_timer2_closemin"])
        if (mytable["weektimer_timer3_mode"] == 2) then
            streams["weektimer_timer3_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["weektimer_timer3_mode"] == 3) then
            streams["weektimer_timer3_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["weektimer_timer3_mode"] == 5) then
            streams["weektimer_timer3_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["weektimer_timer3_temp"] = int2String(
                                               mytable["weektimer_timer3_temp"])
        streams["weektimer_timer3_openhour"] = int2String(
                                                   mytable["weektimer_timer3_openhour"])
        streams["weektimer_timer3_openmin"] = int2String(
                                                  mytable["weektimer_timer3_openmin"])
        streams["weektimer_timer3_closehour"] = int2String(
                                                    mytable["weektimer_timer3_closehour"])
        streams["weektimer_timer3_closemin"] = int2String(
                                                   mytable["weektimer_timer3_closemin"])
        if (mytable["weektimer_timer4_mode"] == 2) then
            streams["weektimer_timer4_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["weektimer_timer4_mode"] == 3) then
            streams["weektimer_timer4_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["weektimer_timer4_mode"] == 5) then
            streams["weektimer_timer4_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["weektimer_timer4_temp"] = int2String(
                                               mytable["weektimer_timer4_temp"])
        streams["weektimer_timer4_openhour"] = int2String(
                                                   mytable["weektimer_timer4_openhour"])
        streams["weektimer_timer4_openmin"] = int2String(
                                                  mytable["weektimer_timer4_openmin"])
        streams["weektimer_timer4_closehour"] = int2String(
                                                    mytable["weektimer_timer4_closehour"])
        streams["weektimer_timer4_closemin"] = int2String(
                                                   mytable["weektimer_timer4_closemin"])
        if (mytable["weektimer_timer5_mode"] == 2) then
            streams["weektimer_timer5_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["weektimer_timer5_mode"] == 3) then
            streams["weektimer_timer5_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["weektimer_timer5_mode"] == 5) then
            streams["weektimer_timer5_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["weektimer_timer5_temp"] = int2String(
                                               mytable["weektimer_timer5_temp"])
        streams["weektimer_timer5_openhour"] = int2String(
                                                   mytable["weektimer_timer5_openhour"])
        streams["weektimer_timer5_openmin"] = int2String(
                                                  mytable["weektimer_timer5_openmin"])
        streams["weektimer_timer5_closehour"] = int2String(
                                                    mytable["weektimer_timer5_closehour"])
        streams["weektimer_timer5_closemin"] = int2String(
                                                   mytable["weektimer_timer5_closemin"])
        if (mytable["weektimer_timer6_mode"] == 2) then
            streams["weektimer_timer6_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["weektimer_timer6_mode"] == 3) then
            streams["weektimer_timer6_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["weektimer_timer6_mode"] == 5) then
            streams["weektimer_timer6_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["weektimer_timer6_temp"] = int2String(
                                               mytable["weektimer_timer6_temp"])
        streams["weektimer_timer6_openhour"] = int2String(
                                                   mytable["weektimer_timer6_openhour"])
        streams["weektimer_timer6_openmin"] = int2String(
                                                  mytable["weektimer_timer6_openmin"])
        streams["weektimer_timer6_closehour"] = int2String(
                                                    mytable["weektimer_timer6_closehour"])
        streams["weektimer_timer6_closemin"] = int2String(
                                                   mytable["weektimer_timer6_closemin"])

    elseif ((msgType == 0x03) and (msgSubType == 0x04)) then
        if (mytable["holidayaway_state"] == 0x01) then
            streams["holidayaway_state"] = uptable["VALUE_ON"]
        else
            streams["holidayaway_state"] = uptable["VALUE_OFF"]
        end
        streams["holidayaway_startyear"] = int2String(
                                               mytable["holidayaway_startyear"])
        streams["holidayaway_startmonth"] = int2String(
                                                mytable["holidayaway_startmonth"])
        streams["holidayaway_startdate"] = int2String(
                                               mytable["holidayaway_startdate"])
        streams["holidayaway_endyear"] = int2String(
                                             mytable["holidayaway_endyear"])
        streams["holidayaway_endmonth"] = int2String(
                                              mytable["holidayaway_endmonth"])
        streams["holidayaway_enddate"] = int2String(
                                             mytable["holidayaway_enddate"])

    elseif ((msgType == 0x03) and (msgSubType == 0x05)) then
        if (mytable["silence_function_state"] == 0x01) then
            streams["silence_function_state"] = uptable["VALUE_ON"]
        else
            streams["silence_function_state"] = uptable["VALUE_OFF"]
        end
        if (mytable["silence_timer1_state"] == 0x01) then
            streams["silence_timer1_state"] = uptable["VALUE_ON"]
        else
            streams["silence_timer1_state"] = uptable["VALUE_OFF"]
        end
        if (mytable["silence_timer2_state"] == 0x01) then
            streams["silence_timer2_state"] = uptable["VALUE_ON"]
        else
            streams["silence_timer2_state"] = uptable["VALUE_OFF"]
        end
        if (mytable["silence_function_level"] == 0x01) then
            streams["silence_function_level"] = uptable["LEVEL2"]
        else
            streams["silence_function_level"] = uptable["LEVEL1"]
        end
        streams["silence_timer1_starthour"] = int2String(
                                                  mytable["silence_timer1_starthour"])
        streams["silence_timer1_startmin"] = int2String(
                                                 mytable["silence_timer1_startmin"])
        streams["silence_timer1_endhour"] = int2String(
                                                mytable["silence_timer1_endhour"])
        streams["silence_timer1_endmin"] = int2String(
                                               mytable["silence_timer1_endmin"])
        streams["silence_timer2_starthour"] = int2String(
                                                  mytable["silence_timer2_starthour"])
        streams["silence_timer2_startmin"] = int2String(
                                                 mytable["silence_timer2_startmin"])
        streams["silence_timer2_endhour"] = int2String(
                                                mytable["silence_timer2_endhour"])
        streams["silence_timer2_endmin"] = int2String(
                                               mytable["silence_timer2_endmin"])

    elseif ((msgType == 0x03) and (msgSubType == 0x06)) then
        if (mytable["holidayhome_state"] == 0x01) then
            streams["holidayhome_state"] = uptable["VALUE_ON"]
        else
            streams["holidayhome_state"] = uptable["VALUE_OFF"]
        end
        streams["holidayhome_startyear"] = int2String(
                                               mytable["holidayhome_startyear"])
        streams["holidayhome_startmonth"] = int2String(
                                                mytable["holidayhome_startmonth"])
        streams["holidayhome_startdate"] = int2String(
                                               mytable["holidayhome_startdate"])
        streams["holidayhome_endyear"] = int2String(
                                             mytable["holidayhome_endyear"])
        streams["holidayhome_endmonth"] = int2String(
                                              mytable["holidayhome_endmonth"])
        streams["holidayhome_enddate"] = int2String(
                                             mytable["holidayhome_enddate"])
        if (mytable["holhometimer_timer1en"] == 0x01) then
            streams["holhometimer_timer1en"] = uptable["VALUE_ON"]
        else
            streams["holhometimer_timer1en"] = uptable["VALUE_OFF"]
        end
        if (mytable["holhometimer_timer2en"] == 0x01) then
            streams["holhometimer_timer2en"] = uptable["VALUE_ON"]
        else
            streams["holhometimer_timer2en"] = uptable["VALUE_OFF"]
        end
        if (mytable["holhometimer_timer3en"] == 0x01) then
            streams["holhometimer_timer3en"] = uptable["VALUE_ON"]
        else
            streams["holhometimer_timer3en"] = uptable["VALUE_OFF"]
        end
        if (mytable["holhometimer_timer4en"] == 0x01) then
            streams["holhometimer_timer4en"] = uptable["VALUE_ON"]
        else
            streams["holhometimer_timer4en"] = uptable["VALUE_OFF"]
        end
        if (mytable["holhometimer_timer5en"] == 0x01) then
            streams["holhometimer_timer5en"] = uptable["VALUE_ON"]
        else
            streams["holhometimer_timer5en"] = uptable["VALUE_OFF"]
        end
        if (mytable["holhometimer_timer6en"] == 0x01) then
            streams["holhometimer_timer6en"] = uptable["VALUE_ON"]
        else
            streams["holhometimer_timer6en"] = uptable["VALUE_OFF"]
        end
        if (mytable["holhometimer_timer1_mode"] == 2) then
            streams["holhometimer_timer1_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["holhometimer_timer1_mode"] == 3) then
            streams["holhometimer_timer1_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["holhometimer_timer1_mode"] == 5) then
            streams["holhometimer_timer1_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["holhometimer_timer1_temp"] = int2String(
                                                  mytable["holhometimer_timer1_temp"])
        streams["holhometimer_timer1_openhour"] = int2String(
                                                      mytable["holhometimer_timer1_openhour"])
        streams["holhometimer_timer1_openmin"] = int2String(
                                                     mytable["holhometimer_timer1_openmin"])
        streams["holhometimer_timer1_closehour"] = int2String(
                                                       mytable["holhometimer_timer1_closehour"])
        streams["holhometimer_timer1_closemin"] = int2String(
                                                      mytable["holhometimer_timer1_closemin"])
        if (mytable["holhometimer_timer2_mode"] == 2) then
            streams["holhometimer_timer2_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["holhometimer_timer2_mode"] == 3) then
            streams["holhometimer_timer2_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["holhometimer_timer2_mode"] == 5) then
            streams["holhometimer_timer2_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["holhometimer_timer2_temp"] = int2String(
                                                  mytable["holhometimer_timer2_temp"])
        streams["holhometimer_timer2_openhour"] = int2String(
                                                      mytable["holhometimer_timer2_openhour"])
        streams["holhometimer_timer2_openmin"] = int2String(
                                                     mytable["holhometimer_timer2_openmin"])
        streams["holhometimer_timer2_closehour"] = int2String(
                                                       mytable["holhometimer_timer2_closehour"])
        streams["holhometimer_timer2_closemin"] = int2String(
                                                      mytable["holhometimer_timer2_closemin"])
        if (mytable["holhometimer_timer3_mode"] == 2) then
            streams["holhometimer_timer3_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["holhometimer_timer3_mode"] == 3) then
            streams["holhometimer_timer3_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["holhometimer_timer3_mode"] == 5) then
            streams["holhometimer_timer3_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["holhometimer_timer3_temp"] = int2String(
                                                  mytable["holhometimer_timer3_temp"])
        streams["holhometimer_timer3_openhour"] = int2String(
                                                      mytable["holhometimer_timer3_openhour"])
        streams["holhometimer_timer3_openmin"] = int2String(
                                                     mytable["holhometimer_timer3_openmin"])
        streams["holhometimer_timer3_closehour"] = int2String(
                                                       mytable["holhometimer_timer3_closehour"])
        streams["holhometimer_timer3_closemin"] = int2String(
                                                      mytable["holhometimer_timer3_closemin"])
        if (mytable["holhometimer_timer4_mode"] == 2) then
            streams["holhometimer_timer4_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["holhometimer_timer4_mode"] == 3) then
            streams["holhometimer_timer4_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["holhometimer_timer4_mode"] == 5) then
            streams["holhometimer_timer4_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["holhometimer_timer4_temp"] = int2String(
                                                  mytable["holhometimer_timer4_temp"])
        streams["holhometimer_timer4_openhour"] = int2String(
                                                      mytable["holhometimer_timer4_openhour"])
        streams["holhometimer_timer4_openmin"] = int2String(
                                                     mytable["holhometimer_timer4_openmin"])
        streams["holhometimer_timer4_closehour"] = int2String(
                                                       mytable["holhometimer_timer4_closehour"])
        streams["holhometimer_timer4_closemin"] = int2String(
                                                      mytable["holhometimer_timer4_closemin"])
        if (mytable["holhometimer_timer5_mode"] == 2) then
            streams["holhometimer_timer5_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["holhometimer_timer5_mode"] == 3) then
            streams["holhometimer_timer5_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["holhometimer_timer5_mode"] == 5) then
            streams["holhometimer_timer5_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["holhometimer_timer5_temp"] = int2String(
                                                  mytable["holhometimer_timer5_temp"])
        streams["holhometimer_timer5_openhour"] = int2String(
                                                      mytable["holhometimer_timer5_openhour"])
        streams["holhometimer_timer5_openmin"] = int2String(
                                                     mytable["holhometimer_timer5_openmin"])
        streams["holhometimer_timer5_closehour"] = int2String(
                                                       mytable["holhometimer_timer5_closehour"])
        streams["holhometimer_timer5_closemin"] = int2String(
                                                      mytable["holhometimer_timer5_closemin"])
        if (mytable["holhometimer_timer6_mode"] == 2) then
            streams["holhometimer_timer6_mode"] = uptable["VALUE_MODE_COOL"]
        elseif (mytable["holhometimer_timer6_mode"] == 3) then
            streams["holhometimer_timer6_mode"] = uptable["VALUE_MODE_HEAT"]
        elseif (mytable["holhometimer_timer6_mode"] == 5) then
            streams["holhometimer_timer6_mode"] = uptable["VALUE_MODE_DHW"]
        end
        streams["holhometimer_timer6_temp"] = int2String(
                                                  mytable["holhometimer_timer6_temp"])
        streams["holhometimer_timer6_openhour"] = int2String(
                                                      mytable["holhometimer_timer6_openhour"])
        streams["holhometimer_timer6_openmin"] = int2String(
                                                     mytable["holhometimer_timer6_openmin"])
        streams["holhometimer_timer6_closehour"] = int2String(
                                                       mytable["holhometimer_timer6_closehour"])
        streams["holhometimer_timer6_closemin"] = int2String(
                                                      mytable["holhometimer_timer6_closemin"])

    elseif ((msgType == 0x03) and (msgSubType == 0x07)) then
        if (mytable["eco_function_state"] == 0x01) then
            streams["eco_function_state"] = uptable["VALUE_ON"]
        else
            streams["eco_function_state"] = uptable["VALUE_OFF"]
        end
        if (mytable["eco_timer_state"] == 0x01) then
            streams["eco_timer_state"] = uptable["VALUE_ON"]
        else
            streams["eco_timer_state"] = uptable["VALUE_OFF"]
        end
        streams["eco_timer_starthour"] = int2String(
                                             mytable["eco_timer_starthour"])
        streams["eco_timer_startmin"] =
            int2String(mytable["eco_timer_startmin"])
        streams["eco_timer_endhour"] = int2String(mytable["eco_timer_endhour"])
        streams["eco_timer_endmin"] = int2String(mytable["eco_timer_endmin"])
    end
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
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
