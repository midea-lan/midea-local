local bit = require "bit"
local JSON = require "cjson"
local KEY_RUNNING_WORK_STATUS = "running_status"
local VALUE_VERSION = 33
local BYTE_DEVICE_TYPE = 0xDB
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local BYTE_CONTROL_WORK_STATUS_START = 0x01
local BYTE_CONTROL_WORK_STATUS_PAUSE = 0x00
local BYTE_RUNNING_WORK_STATUS_IDLE = 0x00
local BYTE_RUNNING_WORK_STATUS_STANDBY = 0x01
local BYTE_RUNNING_WORK_STATUS_START = 0x02
local BYTE_RUNNING_WORK_STATUS_PAUSE = 0x03
local BYTE_RUNNING_WORK_STATUS_END = 0x04
local BYTE_RUNNING_WORK_STATUS_FAULT = 0x05
local BYTE_RUNNING_WORK_STATUS_DELAY = 0x06
local BYTE_MODE_NORMAL = 0x00
local BYTE_MODE_FACTORY_TEST = 0x01
local BYTE_MODE_SERVICE = 0x02
local BYTE_MODE_NORMAL_CONTINUS = 0x03
local power = 0
local controlWorkStatus = 0
local runningWorkStatus = 0
local mode = 0
local program = 0
local waterLevel = 0
local dryer = 0
local soakCount = 0
local temperature = 0
local washTime = 0
local dehydrationMin = 0
local dehydrationSpeed = 0
local detergent = 0
local softener = 0
local byte13 = 0
local progress = 0
local memory = 0
local appointment = 0
local spray_wash = 0
local old_speedy = 0
local nightly = 0
local lock = 0
local down_light = 0
local easy_ironing = 0
local beforehand_wash = 0
local super_clean_wash = 0
local intelligent_wash = 0
local strong_wash = 0
local steam_wash = 0
local fast_clean_wash = 0
local soak = 0
local appointment_time_low_byte = 0
local appointment_time_high_byte = 0
local remainTime = 0
local errorCode = 0
local wash_time_value = 0
local dehydration_time_value = 0
local stains = 0
local dirty_degree = 0
local add_rinse = 0
local ultraviolet_lamp = 0
local eye_wash = 0
local microbubble = 0
local wind_dispel = 0
local speedy = 0
local byte29 = 0
local byte31 = 0
local byte21 = 0
local byte22 = 0
local active_oxygen = 0
local ai = 0
local disinfectant = 0
local deviceSubType = "0"
local expertStep = 0
local byte16 = 0
local ca_dirty_level
local ca_care_level
local ca_cloud_program_status
local ca_cvv
local ca_infrared_door
local protocol_02ca_control = {
    ["ca_dirty_level"] = {["type"] = 0xd2, ["length"] = 1},
    ["ca_care_level"] = {["type"] = 0xd3, ["length"] = 1},
    ["ca_infrared_door"] = {["type"] = 0xde, ["length"] = 1}
}
local water_consumption
local power_consumption
local clean_notification
local fresh_air
local function updateGlobalPropertyValueByJson(luaTable)
    if luaTable["power"] == "on" then
        power = BYTE_POWER_ON
    elseif luaTable["power"] == "off" then
        power = BYTE_POWER_OFF
    else
        power = 0xff
    end
    if luaTable["control_status"] == "pause" then
        controlWorkStatus = BYTE_CONTROL_WORK_STATUS_PAUSE
    elseif luaTable["control_status"] == "start" then
        controlWorkStatus = BYTE_CONTROL_WORK_STATUS_START
    else
        controlWorkStatus = 0xff
    end
    if luaTable[KEY_RUNNING_WORK_STATUS] == "idle" then
        runningWorkStatus = BYTE_RUNNING_WORK_STATUS_IDLE
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == "pause" then
        runningWorkStatus = BYTE_RUNNING_WORK_STATUS_PAUSE
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == "standby" then
        runningWorkStatus = BYTE_RUNNING_WORK_STATUS_STANDBY
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == "start" then
        runningWorkStatus = BYTE_RUNNING_WORK_STATUS_START
    end
    if luaTable["mode"] == "normal" then
        mode = BYTE_MODE_NORMAL
    elseif luaTable["mode"] == "factory_test" then
        mode = BYTE_MODE_FACTORY_TEST
    elseif luaTable["mode"] == "service" then
        mode = BYTE_MODE_SERVICE
    elseif luaTable["mode"] == "normal_continus" then
        mode = BYTE_MODE_NORMAL_CONTINUS
    end
    if luaTable["program"] == "cotton" then
        program = 0x00
    elseif luaTable["program"] == "eco" then
        program = 0x01
    elseif luaTable["program"] == "fast_wash" then
        if (deviceSubType == "14393" or deviceSubType == "28261") then
            program = 0x27
        else
            program = 0x02
        end
    elseif luaTable["program"] == "mixed_wash" then
        if (deviceSubType == "14393" or deviceSubType == "28261") then
            program = 0x28
        else
            program = 0x03
        end
    elseif luaTable["program"] == "wool" then
        program = 0x05
    elseif luaTable["program"] == "ssp" then
        if (deviceSubType == "14393" or deviceSubType == "28261") then
            program = 0x2a
        else
            program = 0x07
        end
    elseif luaTable["program"] == "sport_clothes" then
        program = 0x08
    elseif luaTable["program"] == "single_dehytration" then
        if (deviceSubType == "14393" or deviceSubType == "28261") then
            program = 0x29
        else
            program = 0x09
        end
    elseif luaTable["program"] == "rinsing_dehydration" then
        program = 0x0A
    elseif luaTable["program"] == "big" then
        program = 0x0B
    elseif luaTable["program"] == "baby_clothes" then
        if deviceSubType == "13113" then
            program = 0x13
        else
            program = 0x0C
        end
    elseif luaTable["program"] == "down_jacket" then
        program = 0x0F
    elseif luaTable["program"] == "color" then
        program = 0x10
    elseif luaTable["program"] == "intelligent" then
        program = 0x11
    elseif luaTable["program"] == "quick_wash" then
        program = 0x12
    elseif luaTable["program"] == "shirt" then
        program = 0x1C
    elseif luaTable["program"] == "fiber" then
        program = 0x04
    elseif luaTable["program"] == "enzyme" then
        program = 0x06
    elseif luaTable["program"] == "underwear" then
        program = 0x0D
    elseif luaTable["program"] == "outdoor" then
        program = 0x0E
    elseif luaTable["program"] == "air_wash" then
        program = 0x15
    elseif luaTable["program"] == "single_drying" then
        program = 0x16
    elseif luaTable["program"] == "steep" then
        program = 0x1D
    elseif luaTable["program"] == "kids" then
        if (deviceSubType == "14393" or deviceSubType == "28261") then
            program = 0x2b
        else
            program = 0x13
        end
    elseif luaTable["program"] == "water_cotton" then
        program = 0x14
    elseif luaTable["program"] == "fast_wash_30" then
        program = 0x17
    elseif luaTable["program"] == "fast_wash_60" then
        program = 0x18
    elseif luaTable["program"] == "water_mixed_wash" then
        program = 0x1F
    elseif luaTable["program"] == "water_fiber" then
        program = 0x20
    elseif luaTable["program"] == "water_kids" then
        program = 0x21
    elseif luaTable["program"] == "water_underwear" then
        program = 0x22
    elseif luaTable["program"] == "specialist" then
        program = 0x23
    elseif luaTable["program"] == "love" then
        program = 0xFE
    elseif luaTable["program"] == "water_intelligent" then
        program = 0x19
    elseif luaTable["program"] == "water_steep" then
        program = 0x1A
    elseif luaTable["program"] == "water_fast_wash_30" then
        program = 0x1B
    elseif luaTable["program"] == "new_water_cotton" then
        program = 0x1E
    elseif luaTable["program"] == "water_eco" then
        program = 0x24
    elseif luaTable["program"] == "wash_drying_60" then
        program = 0x25
    elseif luaTable["program"] == "self_wash_5" then
        program = 0x26
    elseif luaTable["program"] == "fast_wash_min" then
        program = 0x27
    elseif luaTable["program"] == "mixed_wash_min" then
        program = 0x28
    elseif luaTable["program"] == "dehydration_min" then
        program = 0x29
    elseif luaTable["program"] == "self_wash_min" then
        program = 0x2A
    elseif luaTable["program"] == "baby_clothes_min" then
        program = 0x2B
    elseif luaTable["program"] == "diy0" then
        program = 0x50
    elseif luaTable["program"] == "diy1" then
        program = 0x51
    elseif luaTable["program"] == "diy2" then
        program = 0x52
    elseif luaTable["program"] == "silk_wash" then
        program = 0x65
    elseif luaTable["program"] == "prevent_allergy" then
        program = 0x2C
    elseif luaTable["program"] == "cold_wash" then
        program = 0x2D
    elseif luaTable["program"] == "soft_wash" then
        program = 0x2E
    elseif luaTable["program"] == "remove_mite_wash" then
        program = 0x2F
    elseif luaTable["program"] == "water_intense_wash" then
        program = 0x30
    elseif luaTable["program"] == "fast_dry" then
        program = 0x31
    elseif luaTable["program"] == "water_outdoor" then
        program = 0x32
    elseif luaTable["program"] == "spring_autumn_wash" then
        program = 0x33
    elseif luaTable["program"] == "summer_wash" then
        program = 0x34
    elseif luaTable["program"] == "winter_wash" then
        program = 0x35
    elseif luaTable["program"] == "jean" then
        program = 0x36
    elseif luaTable["program"] == "new_clothes_wash" then
        program = 0x37
    elseif luaTable["program"] == "silk" then
        program = 0x38
    elseif luaTable["program"] == "insight_wash" then
        program = 0x39
    elseif luaTable["program"] == "fitness_clothes" then
        program = 0x3a
    elseif luaTable["program"] == "mink" then
        program = 0x3b
    elseif luaTable["program"] == "fresh_air" then
        program = 0x3c
    elseif luaTable["program"] == "bucket_dry" then
        program = 0x3d
    elseif luaTable["program"] == "jacket" then
        program = 0x3e
    elseif luaTable["program"] == "bath_towel" then
        program = 0x3f
    elseif luaTable["program"] == "night_fresh_wash" then
        program = 0x40
    elseif luaTable["program"] == "heart_wash" then
        program = 0x60
    elseif luaTable["program"] == "water_cold_wash" then
        program = 0x61
    elseif luaTable["program"] == "water_prevent_allergy" then
        program = 0x62
    elseif luaTable["program"] == "water_remove_mite_wash" then
        program = 0x63
    elseif luaTable["program"] == "water_ssp" then
        program = 0x64
    elseif luaTable["program"] == "standard" then
        program = 0x66
    elseif luaTable["program"] == "green_wool" then
        program = 0x67
    elseif luaTable["program"] == "cook_wash" then
        program = 0x68
    elseif luaTable["program"] == "fresh_remove_wrinkle" then
        program = 0x69
    elseif luaTable["program"] == "steam_sterilize_wash" then
        program = 0x6A
    elseif luaTable["program"] == "aromatherapy" then
        program = 0x6B
    elseif luaTable["program"] == "sterilize_wash" then
        program = 0x70
    else
        program = 0xff
    end
    if luaTable["water_level"] == "low" then
        waterLevel = 0x01
    elseif luaTable["water_level"] == "mid" then
        waterLevel = 0x02
    elseif luaTable["water_level"] == "high" then
        waterLevel = 0x03
    elseif luaTable["water_level"] == "4" then
        waterLevel = 0x04
    elseif luaTable["water_level"] == "auto" then
        waterLevel = 0x05
    else
        waterLevel = 0xff
    end
    if luaTable["dryer"] == "0" then
        dryer = 0xf0
    elseif luaTable["dryer"] == "1" then
        dryer = 0xf1
    elseif luaTable["dryer"] == "2" then
        dryer = 0xf2
    elseif luaTable["dryer"] == "3" then
        dryer = 0xf3
    elseif luaTable["dryer"] == "4" then
        dryer = 0xf4
    elseif luaTable["dryer"] == "5" then
        dryer = 0xf5
    elseif luaTable["dryer"] == "6" then
        dryer = 0xf6
    elseif luaTable["dryer"] == "7" then
        dryer = 0xf7
    elseif luaTable["dryer"] == "8" then
        dryer = 0xf8
    elseif luaTable["dryer"] == "9" then
        dryer = 0xf9
    elseif luaTable["dryer"] == "10" then
        dryer = 0xfa
    elseif luaTable["dryer"] == "11" then
        dryer = 0xfb
    elseif luaTable["dryer"] == "12" then
        dryer = 0xfc
    elseif luaTable["dryer"] == "13" then
        dryer = 0xfd
    elseif luaTable["dryer"] == "14" then
        dryer = 0xfe
    else
        dryer = 0xff
    end
    if luaTable["soak_count"] == "1" then
        soakCount = 0x1f
    elseif luaTable["soak_count"] == "2" then
        soakCount = 0x2f
    elseif luaTable["soak_count"] == "3" then
        soakCount = 0x3f
    elseif luaTable["soak_count"] == "4" then
        soakCount = 0x4f
    elseif luaTable["soak_count"] == "5" then
        soakCount = 0x5f
    elseif luaTable["soak_count"] == "0" then
        soakCount = 0x0f
    else
        soakCount = 0xff
    end
    if luaTable["temperature"] == "0" then
        temperature = 0x01
    elseif luaTable["temperature"] == "20" then
        temperature = 0x02
    elseif luaTable["temperature"] == "30" then
        temperature = 0x03
    elseif luaTable["temperature"] == "40" then
        temperature = 0x04
    elseif luaTable["temperature"] == "60" then
        temperature = 0x05
    elseif luaTable["temperature"] == "70" then
        temperature = 0x07
    elseif luaTable["temperature"] == "95" then
        temperature = 0x06
    else
        temperature = 0xff
    end
    if luaTable["wash_time"] ~= nil then
        washTime = luaTable["wash_time"]
    else
        washTime = 0xff
    end
    if luaTable["dehydration_time"] ~= nil then
        dehydrationMin = luaTable["dehydration_time"]
    else
        dehydrationMin = 0xff
    end
    if luaTable["dehydration_speed"] == "0" then
        dehydrationSpeed = 0x00
    elseif luaTable["dehydration_speed"] == "400" then
        dehydrationSpeed = 0x01
    elseif luaTable["dehydration_speed"] == "600" then
        dehydrationSpeed = 0x02
    elseif luaTable["dehydration_speed"] == "800" then
        dehydrationSpeed = 0x03
    elseif luaTable["dehydration_speed"] == "1000" then
        dehydrationSpeed = 0x04
    elseif luaTable["dehydration_speed"] == "1200" then
        dehydrationSpeed = 0x05
    elseif luaTable["dehydration_speed"] == "1400" then
        dehydrationSpeed = 0x06
    elseif luaTable["dehydration_speed"] == "1600" then
        dehydrationSpeed = 0x07
    elseif luaTable["dehydration_speed"] == "1300" then
        dehydrationSpeed = 0x08
    else
        dehydrationSpeed = 0xff
    end
    if luaTable["detergent"] == "0" then
        detergent = 0x00
    elseif luaTable["detergent"] == "1" then
        detergent = 0x01
    elseif luaTable["detergent"] == "2" then
        detergent = 0x02
    elseif luaTable["detergent"] == "3" then
        detergent = 0x03
    elseif luaTable["detergent"] == "4" then
        detergent = 0x04
    elseif luaTable["detergent"] == "5" then
        detergent = 0x05
    else
        detergent = 0xff
    end
    if luaTable["softener"] == "0" then
        softener = 0x00
    elseif luaTable["softener"] == "1" then
        softener = 0x01
    elseif luaTable["softener"] == "2" then
        softener = 0x02
    elseif luaTable["softener"] == "3" then
        softener = 0x03
    elseif luaTable["softener"] == "4" then
        softener = 0x04
    elseif luaTable["softener"] == "5" then
        softener = 0x05
    else
        softener = 0xff
    end
    if luaTable["memory"] == "on" then
        memory = 1
    elseif luaTable["memory"] == "off" then
        memory = 0
    end
    if luaTable["appointment"] == "on" then
        appointment = 1
        if (luaTable["appointment_time"] ~= nil) then
            appointment_time_low_byte = bit.band(luaTable["appointment_time"],
                                                 0x00ff)
            appointment_time_high_byte =
                bit.rshift(bit.band(luaTable["appointment_time"], 0xff00), 8)
        end
    elseif luaTable["appointment"] == "off" then
        appointment = 0
        if luaTable["appointment_time"] ~= nil then
            appointment_time_low_byte = 0
            appointment_time_high_byte = 0
        else
            appointment_time_low_byte = 0xff
            appointment_time_high_byte = 0xff
        end
    else
        appointment_time_low_byte = 0xff
        appointment_time_high_byte = 0xff
    end
    if luaTable["spray_wash"] == "on" then
        spray_wash = 1
    elseif luaTable["spray_wash"] == "off" then
        spray_wash = 0
    end
    if luaTable["nightly"] == "on" then
        nightly = 1
    elseif luaTable["nightly"] == "off" then
        nightly = 0
    end
    if luaTable["old_speedy"] == "on" then
        old_speedy = 1
    elseif luaTable["old_speedy"] == "off" then
        old_speedy = 0
    end
    if luaTable["lock"] == "on" then
        lock = 1
    elseif luaTable["lock"] == "off" then
        lock = 0
    end
    if luaTable["down_light"] == "on" then
        down_light = 1
    elseif luaTable["down_light"] == "off" then
        down_light = 0
    end
    if luaTable["easy_ironing"] == "on" then
        easy_ironing = 1
    elseif luaTable["easy_ironing"] == "off" then
        easy_ironing = 0
    end
    stains = tonumber(luaTable["stains"])
    if stains == nil then stains = 0xff end
    if luaTable["dirty_degree"] == "0" then
        dirty_degree = 0x00
    elseif luaTable["dirty_degree"] == "1" then
        dirty_degree = 0x01
    elseif luaTable["dirty_degree"] == "2" then
        dirty_degree = 0x02
    elseif luaTable["dirty_degree"] == "3" then
        dirty_degree = 0x03
    elseif luaTable["dirty_degree"] == "4" then
        dirty_degree = 0x04
    else
        dirty_degree = 0xff
    end
    if luaTable["add_rinse"] == "0" then
        add_rinse = 0
    elseif luaTable["add_rinse"] == "1" then
        add_rinse = 1
    else
        add_rinse = 3
    end
    if luaTable["ultraviolet_lamp"] == "0" then
        ultraviolet_lamp = 0
    elseif luaTable["ultraviolet_lamp"] == "1" then
        ultraviolet_lamp = 1
    else
        ultraviolet_lamp = 3
    end
    if luaTable["eye_wash"] == "0" then
        eye_wash = 0
    elseif luaTable["eye_wash"] == "1" then
        eye_wash = 1
    else
        eye_wash = 3
    end
    if luaTable["microbubble"] == "0" then
        microbubble = 0
    elseif luaTable["microbubble"] == "1" then
        microbubble = 1
    else
        microbubble = 3
    end
    if luaTable["wind_dispel"] == "0" then
        wind_dispel = 0
    elseif luaTable["wind_dispel"] == "1" then
        wind_dispel = 1
    else
        wind_dispel = 3
    end
    if luaTable["speedy"] == "off" then
        speedy = 0
    elseif luaTable["speedy"] == "on" then
        speedy = 1
    else
        speedy = 3
    end
    if luaTable["active_oxygen"] == "0" then
        active_oxygen = 0
    elseif luaTable["active_oxygen"] == "1" then
        active_oxygen = 1
    else
        active_oxygen = 3
    end
    if luaTable["ai"] == "0" then
        ai = 0
    elseif luaTable["ai"] == "1" then
        ai = 1
    else
        ai = 3
    end
    if luaTable["disinfectant"] == "0" then
        disinfectant = 0
    elseif luaTable["disinfectant"] == "1" then
        disinfectant = 1
    else
        disinfectant = 3
    end
    if luaTable["beforehand_wash"] == "on" then
        beforehand_wash = 1
    elseif luaTable["beforehand_wash"] == "off" then
        beforehand_wash = 0
    end
    if luaTable["super_clean_wash"] == "on" then
        super_clean_wash = 1
    elseif luaTable["super_clean_wash"] == "off" then
        super_clean_wash = 0
    end
    if luaTable["intelligent_wash"] == "on" then
        intelligent_wash = 1
    elseif luaTable["intelligent_wash"] == "off" then
        intelligent_wash = 0
    end
    if luaTable["strong_wash"] == "on" then
        strong_wash = 1
    elseif luaTable["strong_wash"] == "off" then
        strong_wash = 0
    end
    if luaTable["steam_wash"] == "on" then
        steam_wash = 1
    elseif luaTable["steam_wash"] == "off" then
        steam_wash = 0
    end
    if luaTable["fast_clean_wash"] == "on" then
        fast_clean_wash = 1
    elseif luaTable["fast_clean_wash"] == "off" then
        fast_clean_wash = 0
    end
    if luaTable["soak"] == "on" then
        soak = 1
    elseif luaTable["soak"] == "off" then
        soak = 0
    end
end
local function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == '0202' or dataType == '0303' or dataType == '0404') then
        power = messageBytes[1]
        runningWorkStatus = messageBytes[2]
        mode = messageBytes[3]
        program = messageBytes[4]
        waterLevel = messageBytes[5]
        dryer = bit.band(messageBytes[6], 0x0F)
        soakCount = bit.rshift(bit.band(messageBytes[6], 0xF0), 4)
        temperature = messageBytes[7]
        dehydrationSpeed = messageBytes[8]
        washTime = messageBytes[9]
        dehydrationMin = messageBytes[10]
        detergent = messageBytes[11]
        softener = messageBytes[12]
        byte13 = messageBytes[13]
        appointment_time_low_byte = messageBytes[14]
        appointment_time_high_byte = messageBytes[15]
        progress = messageBytes[16]
        remainTime = messageBytes[17] + bit.lshift(messageBytes[18], 8)
        byte21 = messageBytes[21]
        byte22 = messageBytes[22]
        if messageBytes[24] ~= nil then errorCode = messageBytes[24] end
        if messageBytes[25] ~= nil then byte16 = messageBytes[25] end
        stains = messageBytes[26]
        wash_time_value = messageBytes[27]
        dehydration_time_value = messageBytes[28]
        byte29 = messageBytes[29]
        dirty_degree = messageBytes[30]
        expertStep = messageBytes[19]
        if messageBytes[31] ~= nil then byte31 = messageBytes[31] end
    elseif (dataType == '04ca' or dataType == '03ca' or dataType == '02ca') then
        local ca_start_offset = 23
        while ca_start_offset <= #binData - 2 do
            local type = string.sub(binData, ca_start_offset,
                                    ca_start_offset + 1)
            local length = string.sub(binData, ca_start_offset + 2,
                                      ca_start_offset + 3)
            local value = string.sub(binData, ca_start_offset + 4,
                                     ca_start_offset + 4 + 2 * length - 1)
            if type == 'd2' then
                ca_dirty_level = tonumber(value, 16)
            elseif type == 'd3' then
                ca_care_level = tonumber(value, 16)
            elseif type == 'd4' then
                ca_cloud_program_status = tonumber(value, 16)
            elseif type == 'dd' then
                ca_cvv = tonumber(value, 16)
            elseif type == 'de' then
                ca_infrared_door = tonumber(value, 16)
            end
            ca_start_offset = ca_start_offset + 4 + 2 * length
        end
    elseif (dataType == '0405') then
        water_consumption = 256 * messageBytes[2] + messageBytes[1]
        power_consumption = 256 * messageBytes[4] + messageBytes[3]
        clean_notification = messageBytes[7]
        fresh_air = messageBytes[17]
    end
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams["version"] = VALUE_VERSION
    if (power == BYTE_POWER_ON) then
        streams["power"] = "on"
    elseif (power == BYTE_POWER_OFF) then
        streams["power"] = "off"
    end
    if (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_START) then
        streams[KEY_RUNNING_WORK_STATUS] = "start"
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_PAUSE) then
        if (errorCode ~= 0) then
            streams[KEY_RUNNING_WORK_STATUS] = "fault"
        else
            streams[KEY_RUNNING_WORK_STATUS] = "pause"
        end
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_STANDBY) then
        streams[KEY_RUNNING_WORK_STATUS] = "standby"
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_END) then
        streams[KEY_RUNNING_WORK_STATUS] = "end"
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_FAULT) then
        streams[KEY_RUNNING_WORK_STATUS] = "fault"
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_DELAY) then
        streams[KEY_RUNNING_WORK_STATUS] = "delay"
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_IDLE) then
        streams[KEY_RUNNING_WORK_STATUS] = "idle"
    end
    if (mode == BYTE_MODE_NORMAL) then
        streams["mode"] = "normal"
    elseif (mode == BYTE_MODE_FACTORY_TEST) then
        streams["mode"] = "factory_test"
    elseif (mode == BYTE_MODE_SERVICE) then
        streams["mode"] = "service"
    elseif (mode == BYTE_MODE_NORMAL_CONTINUS) then
        streams["mode"] = "normal_continus"
    end
    if program == 0x00 then
        streams["program"] = "cotton"
    elseif program == 0x01 then
        streams["program"] = "eco"
    elseif program == 0x02 then
        streams["program"] = "fast_wash"
    elseif program == 0x03 then
        streams["program"] = "mixed_wash"
    elseif program == 0x05 then
        streams["program"] = "wool"
    elseif program == 0x07 then
        streams["program"] = "ssp"
    elseif program == 0x08 then
        streams["program"] = "sport_clothes"
    elseif program == 0x09 then
        streams["program"] = "single_dehytration"
    elseif program == 0x0A then
        streams["program"] = "rinsing_dehydration"
    elseif program == 0x0B then
        streams["program"] = "big"
    elseif program == 0x0C then
        streams["program"] = "baby_clothes"
    elseif program == 0x0F then
        streams["program"] = "down_jacket"
    elseif program == 0x10 then
        streams["program"] = "color"
    elseif program == 0x11 then
        streams["program"] = "intelligent"
    elseif program == 0x12 then
        streams["program"] = "quick_wash"
    elseif program == 0x1C then
        streams["program"] = "shirt"
    elseif program == 0x04 then
        streams["program"] = "fiber"
    elseif program == 0x06 then
        streams["program"] = "enzyme"
    elseif program == 0x0D then
        streams["program"] = "underwear"
    elseif program == 0x0E then
        streams["program"] = "outdoor"
    elseif program == 0x15 then
        streams["program"] = "air_wash"
    elseif program == 0x16 then
        streams["program"] = "single_drying"
    elseif program == 0x1D then
        streams["program"] = "steep"
    elseif program == 0x13 then
        if deviceSubType == "13113" then
            streams["program"] = "baby_clothes"
        else
            streams["program"] = "kids"
        end
    elseif program == 0x14 then
        streams["program"] = "water_cotton"
    elseif program == 0x17 then
        streams["program"] = "fast_wash_30"
    elseif program == 0x18 then
        streams["program"] = "fast_wash_60"
    elseif program == 0x1F then
        streams["program"] = "water_mixed_wash"
    elseif program == 0x20 then
        streams["program"] = "water_fiber"
    elseif program == 0x21 then
        streams["program"] = "water_kids"
    elseif program == 0x22 then
        streams["program"] = "water_underwear"
    elseif program == 0x23 then
        streams["program"] = "specialist"
    elseif program == 0xFE then
        streams["program"] = "love"
    elseif program == 0x19 then
        streams["program"] = "water_intelligent"
    elseif program == 0x1A then
        streams["program"] = "water_steep"
    elseif program == 0x1B then
        streams["program"] = "water_fast_wash_30"
    elseif program == 0x1E then
        streams["program"] = "new_water_cotton"
    elseif program == 0x24 then
        streams["program"] = "water_eco"
    elseif program == 0x25 then
        streams["program"] = "wash_drying_60"
    elseif program == 0x26 then
        streams["program"] = "self_wash_5"
    elseif program == 0x27 then
        streams["program"] = "fast_wash_min"
    elseif program == 0x28 then
        streams["program"] = "mixed_wash_min"
    elseif program == 0x29 then
        streams["program"] = "dehydration_min"
    elseif program == 0x2A then
        streams["program"] = "self_wash_min"
    elseif program == 0x2B then
        streams["program"] = "baby_clothes_min"
    elseif program == 0x50 then
        streams["program"] = "diy0"
    elseif program == 0x51 then
        streams["program"] = "diy1"
    elseif program == 0x52 then
        streams["program"] = "diy2"
    elseif program == 0x65 then
        streams["program"] = "silk_wash"
    elseif program == 0x2C then
        streams["program"] = "prevent_allergy"
    elseif program == 0x2D then
        streams["program"] = "cold_wash"
    elseif program == 0x2E then
        streams["program"] = "soft_wash"
    elseif program == 0x2F then
        streams["program"] = "remove_mite_wash"
    elseif program == 0x30 then
        streams["program"] = "water_intense_wash"
    elseif program == 0x31 then
        streams["program"] = "fast_dry"
    elseif program == 0x32 then
        streams["program"] = "water_outdoor"
    elseif program == 0x33 then
        streams["program"] = "spring_autumn_wash"
    elseif program == 0x34 then
        streams["program"] = "summer_wash"
    elseif program == 0x35 then
        streams["program"] = "winter_wash"
    elseif program == 0x36 then
        streams["program"] = "jean"
    elseif program == 0x37 then
        streams["program"] = "new_clothes_wash"
    elseif program == 0x38 then
        streams["program"] = "silk"
    elseif program == 0x39 then
        streams["program"] = "insight_wash"
    elseif program == 0x3a then
        streams["program"] = "fitness_clothes"
    elseif program == 0x3b then
        streams["program"] = "mink"
    elseif program == 0x3c then
        streams["program"] = "fresh_air"
    elseif program == 0x3d then
        streams["program"] = "bucket_dry"
    elseif program == 0x3e then
        streams["program"] = "jacket"
    elseif program == 0x3f then
        streams["program"] = "bath_towel"
    elseif program == 0x40 then
        streams["program"] = "night_fresh_wash"
    elseif program == 0x60 then
        streams["program"] = "heart_wash"
    elseif program == 0x61 then
        streams["program"] = "water_cold_wash"
    elseif program == 0x62 then
        streams["program"] = "water_prevent_allergy"
    elseif program == 0x63 then
        streams["program"] = "water_remove_mite_wash"
    elseif program == 0x64 then
        streams["program"] = "water_ssp"
    elseif program == 0x66 then
        streams["program"] = "standard"
    elseif program == 0x67 then
        streams["program"] = "green_wool"
    elseif program == 0x68 then
        streams["program"] = "cook_wash"
    elseif program == 0x69 then
        streams["program"] = "fresh_remove_wrinkle"
    elseif program == 0x6A then
        streams["program"] = "steam_sterilize_wash"
    elseif program == 0x6B then
        streams["program"] = "aromatherapy"
    elseif program == 0x70 then
        streams["program"] = "sterilize_wash"
    end
    if waterLevel == 0x01 then
        streams["water_level"] = "low"
    elseif waterLevel == 0x02 then
        streams["water_level"] = "mid"
    elseif waterLevel == 0x03 then
        streams["water_level"] = "high"
    elseif waterLevel == 0x05 then
        streams["water_level"] = "auto"
    else
        streams["water_level"] = tostring(waterLevel)
    end
    if dryer == 0x00 then
        streams["dryer"] = "0"
    elseif dryer == 0x01 then
        streams["dryer"] = "1"
    elseif dryer == 0x02 then
        streams["dryer"] = "2"
    elseif dryer == 0x03 then
        streams["dryer"] = "3"
    elseif dryer == 0x04 then
        streams["dryer"] = "4"
    elseif dryer == 0x05 then
        streams["dryer"] = "5"
    elseif dryer == 0x06 then
        streams["dryer"] = "6"
    elseif dryer == 0x07 then
        streams["dryer"] = "7"
    elseif dryer == 0x08 then
        streams["dryer"] = "8"
    elseif dryer == 0x09 then
        streams["dryer"] = "9"
    elseif dryer == 0x0a then
        streams["dryer"] = "10"
    elseif dryer == 0x0b then
        streams["dryer"] = "11"
    elseif dryer == 0x0c then
        streams["dryer"] = "12"
    elseif dryer == 0x0d then
        streams["dryer"] = "13"
    elseif dryer == 0x0e then
        streams["dryer"] = "14"
    end
    if soakCount == 0x01 then
        streams["soak_count"] = "1"
    elseif soakCount == 0x02 then
        streams["soak_count"] = "2"
    elseif soakCount == 0x03 then
        streams["soak_count"] = "3"
    elseif soakCount == 0x04 then
        streams["soak_count"] = "4"
    elseif soakCount == 0x05 then
        streams["soak_count"] = "5"
    elseif soakCount == 0x00 then
        streams["soak_count"] = "0"
    else
        streams["soak_count"] = "invalid"
    end
    if temperature == 0x01 then
        streams["temperature"] = "0"
    elseif temperature == 0x02 then
        streams["temperature"] = "20"
    elseif temperature == 0x03 then
        streams["temperature"] = "30"
    elseif temperature == 0x04 then
        streams["temperature"] = "40"
    elseif temperature == 0x05 then
        streams["temperature"] = "60"
    elseif temperature == 0x06 then
        streams["temperature"] = "95"
    elseif temperature == 0x07 then
        streams["temperature"] = "70"
    else
        streams["temperature"] = "invalid"
    end
    streams["wash_time"] = washTime
    streams["dehydration_time"] = dehydrationMin
    streams["wash_time_value"] = wash_time_value
    streams["dehydration_time_value"] = dehydration_time_value
    if dehydrationSpeed == 0x00 then
        streams["dehydration_speed"] = "0"
    elseif dehydrationSpeed == 0x01 then
        streams["dehydration_speed"] = "400"
    elseif dehydrationSpeed == 0x02 then
        streams["dehydration_speed"] = "600"
    elseif dehydrationSpeed == 0x03 then
        streams["dehydration_speed"] = "800"
    elseif dehydrationSpeed == 0x04 then
        streams["dehydration_speed"] = "1000"
    elseif dehydrationSpeed == 0x05 then
        streams["dehydration_speed"] = "1200"
    elseif dehydrationSpeed == 0x06 then
        streams["dehydration_speed"] = "1400"
    elseif dehydrationSpeed == 0x07 then
        streams["dehydration_speed"] = "1600"
    elseif dehydrationSpeed == 0x08 then
        streams["dehydration_speed"] = "1300"
    end
    streams["detergent"] = tostring(detergent)
    streams["softener"] = tostring(softener)
    streams["stains"] = tostring(stains)
    streams["dirty_degree"] = tostring(dirty_degree)
    streams["progress"] = progress
    if bit.band(byte31, 0x01) == 0x01 then
        streams["ai_flag"] = "on"
    else
        streams["ai_flag"] = "off"
    end
    if bit.band(byte29, 0x01) == 0x01 then
        streams["soak"] = "on"
    else
        streams["soak"] = "off"
    end
    if bit.band(byte29, 0x04) == 0x04 then
        streams["add_rinse"] = "1"
    else
        streams["add_rinse"] = "0"
    end
    if bit.band(byte29, 0x08) == 0x08 then
        streams["ultraviolet_lamp"] = "1"
    else
        streams["ultraviolet_lamp"] = "0"
    end
    if bit.band(byte29, 0x10) == 0x10 then
        streams["eye_wash"] = "1"
    else
        streams["eye_wash"] = "0"
    end
    if bit.band(byte29, 0x20) == 0x20 then
        streams["microbubble"] = "1"
    else
        streams["microbubble"] = "0"
    end
    if bit.band(byte29, 0x40) == 0x40 then
        streams["wind_dispel"] = "1"
    else
        streams["wind_dispel"] = "0"
    end
    if bit.band(byte13, 0x01) == 0x01 then
        streams["memory"] = "on"
    else
        streams["memory"] = "off"
    end
    if bit.band(byte13, 0x02) == 0x02 then
        streams["appointment"] = "on"
    else
        streams["appointment"] = "off"
    end
    if bit.band(byte13, 0x04) == 0x04 then
        streams["spray_wash"] = "on"
    else
        streams["spray_wash"] = "off"
    end
    if bit.band(byte13, 0x08) == 0x08 then
        streams["speedy"] = "on"
        streams["old_speedy"] = "on"
    else
        streams["speedy"] = "off"
        streams["old_speedy"] = "off"
    end
    if bit.band(byte13, 0x10) == 0x10 then
        streams["nightly"] = "on"
    else
        streams["nightly"] = "off"
    end
    if bit.band(byte13, 0x20) == 0x20 then
        streams["lock"] = "on"
    else
        streams["lock"] = "off"
    end
    if bit.band(byte13, 0x40) == 0x40 then
        streams["down_light"] = "on"
    else
        streams["down_light"] = "off"
    end
    if bit.band(byte13, 0x80) == 0x80 then
        streams["easy_ironing"] = "on"
    else
        streams["easy_ironing"] = "off"
    end
    streams["appointment_time"] = tonumber(
                                      string.format("%02x",
                                                    appointment_time_high_byte) ..
                                          string.format("%02x",
                                                        appointment_time_low_byte),
                                      16)
    if bit.band(byte16, 0x01) == 0x01 then
        streams["beforehand_wash"] = "on"
    else
        streams["beforehand_wash"] = "off"
    end
    if bit.band(byte16, 0x02) == 0x02 then
        streams["super_clean_wash"] = "on"
    else
        streams["super_clean_wash"] = "off"
    end
    if bit.band(byte16, 0x04) == 0x04 then
        streams["intelligent_wash"] = "on"
    else
        streams["intelligent_wash"] = "off"
    end
    if bit.band(byte16, 0x08) == 0x08 then
        streams["strong_wash"] = "on"
    else
        streams["strong_wash"] = "off"
    end
    if bit.band(byte16, 0x10) == 0x10 then
        streams["steam_wash"] = "on"
    else
        streams["steam_wash"] = "off"
    end
    if bit.band(byte16, 0x20) == 0x20 then
        streams["fast_clean_wash"] = "on"
    else
        streams["fast_clean_wash"] = "off"
    end
    if bit.band(byte16, 0x40) == 0x40 then
        streams["disinfectant"] = "1"
    else
        streams["disinfectant"] = "0"
    end
    if bit.band(byte16, 0x80) == 0x80 then
        streams["active_oxygen"] = "1"
    else
        streams["active_oxygen"] = "0"
    end
    streams["project_no"] = tonumber(string.format("%02x", byte22) ..
                                         string.format("%02x", byte21), 16)
    streams["remain_time"] = remainTime
    streams["error_code"] = errorCode
    streams["expert_step"] = expertStep
    return streams
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do resVal = resVal + tmpbuf[si] end
    resVal = bit.bnot(resVal) + 1
    resVal = bit.band(resVal, 0x00ff)
    return resVal
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
local function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
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
local function bitBor(num1, num2) return bit.bor(num1, num2) end
local function judge_if_protocol_02ca_control(tab)
    for k in pairs(tab) do
        if (protocol_02ca_control[k] ~= nil) then return true end
    end
    return nil
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    if (control) then
        if judge_if_protocol_02ca_control(control) ~= nil then
            local bodyBytes = {}
            bodyBytes[0] = 0xca
            local offset = 1
            for k in pairs(control) do
                bodyBytes[offset] = protocol_02ca_control[k]["type"]
                bodyBytes[offset + 1] = protocol_02ca_control[k]["length"]
                bodyBytes[offset + 2] = control[k]
                offset = offset + 3
            end
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        else
            if (status) then updateGlobalPropertyValueByJson(status) end
            if (control) then
                updateGlobalPropertyValueByJson(control)
            end
            local bodyLength = 22
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
            bodyBytes[0] = BYTE_CONTROL_REQUEST
            if control["power"] ~= nil then
                bodyBytes[1] = power
            else
                if control["control_status"] ~= nil then
                    bodyBytes[2] = controlWorkStatus
                end
                bodyBytes[4] = program
                bodyBytes[5] = waterLevel
                bodyBytes[6] = bit.band(soakCount, dryer)
                bodyBytes[7] = temperature
                bodyBytes[8] = dehydrationSpeed
                bodyBytes[9] = washTime
                bodyBytes[10] = dehydrationMin
                bodyBytes[11] = detergent
                bodyBytes[12] = softener
                bodyBytes[13] = bitBor(bitBor(bitBor(memory,
                                                     bit.lshift(appointment, 1)),
                                              bitBor(bit.lshift(spray_wash, 2),
                                                     bit.lshift(old_speedy, 3))),
                                       bitBor(
                                           bitBor(bit.lshift(lock, 5),
                                                  bit.lshift(nightly, 4)),
                                           bitBor(bit.lshift(down_light, 6),
                                                  bit.lshift(easy_ironing, 7))))
                bodyBytes[14] = appointment_time_low_byte
                bodyBytes[15] = appointment_time_high_byte
                bodyBytes[16] = bitBor(bitBor(
                                           bitBor(beforehand_wash, bit.lshift(
                                                      super_clean_wash, 1)),
                                           bitBor(
                                               bit.lshift(intelligent_wash, 2),
                                               bit.lshift(strong_wash, 3))),
                                       bitBor(
                                           bitBor(bit.lshift(steam_wash, 4),
                                                  bit.lshift(fast_clean_wash, 5)),
                                           bit.lshift(soak, 6)))
                bodyBytes[17] = stains
                bodyBytes[18] = bitBor(bitBor(add_rinse,
                                              bit.lshift(ultraviolet_lamp, 2)),
                                       bitBor(bit.lshift(eye_wash, 4),
                                              bit.lshift(microbubble, 6)))
                bodyBytes[19] = bitBor(wind_dispel, bit.lshift(speedy, 2))
                bodyBytes[20] = dirty_degree
                bodyBytes[21] = bitBor(bitBor(active_oxygen, bit.lshift(ai, 2)),
                                       bit.lshift(disinfectant, 4))
                if control["control_status"] == "pause" then
                    bodyBytes[4] = 0xff
                end
                if control["merge"] == "false" then
                    bodyBytes[13] = 0xff
                    bodyBytes[16] = 0xff
                end
            end
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        end
    elseif (query) then
        local bodyBytes = {}
        if (query["protocol"] and query["protocol"] == "03ca") then
            bodyBytes[0] = 0xca
            local offset = 1
            for k in pairs(query) do
                if (k ~= "protocol") then
                    bodyBytes[offset] = protocol_02ca_control[k]["type"]
                    bodyBytes[offset + 1] = 0x00
                    offset = offset + 2
                end
            end
            msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
        else
            bodyBytes[0] = 0x03
            msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
        end
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
    deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    binData = string.lower(json["msg"]["data"])
    local status = json["status"]
    if (status) then updateGlobalPropertyValueByJson(status) end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = string.sub(binData, 19, 22)
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    if (dataType == '04ca' or dataType == '03ca' or dataType == '02ca') then
        local temTable = {}
        temTable["version"] = VALUE_VERSION
        temTable["data_type"] = dataType
        temTable["ca_dirty_level"] = ca_dirty_level
        temTable["ca_care_level"] = ca_care_level
        temTable["ca_cloud_program_status"] = ca_cloud_program_status
        temTable["ca_infrared_door"] = ca_infrared_door
        temTable["ca_cvv"] = ca_cvv
        retTable["status"] = temTable
    elseif (dataType == '0405') then
        local temTable = {}
        temTable["version"] = VALUE_VERSION
        temTable["data_type"] = dataType
        temTable["power_consumption"] = power_consumption
        temTable["water_consumption"] = water_consumption
        temTable["clean_notification"] = clean_notification
        temTable["fresh_air"] = fresh_air
        retTable["status"] = temTable
    else
        retTable["status"] = assembleJsonByGlobalProperty()
        retTable["status"]["data_type"] = dataType
    end
    local ret = encodeTableToJson(retTable)
    return ret
end
