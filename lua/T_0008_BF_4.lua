local JSON = require "cjson"
local BYTE_PROTOCOL_LENGTH = 0x10
local dataType = 0x00
local subDataType = 0x00
local version = 4
local keyTable = {
    KEY_VERSION = "version",
    KEY_FUNCTION_TYPE = "function_type",
    KEY_PROPERTY_TYPE = "property_type",
    KEY_RECIPE_NUMBER = "recipe_number",
    KEY_PROCESS_NUMBER = "process_number",
    KEY_MENU_CODE = "menu_code",
    KEY_COOKING_STRENGTH = "cooking_strength",
    KEY_COOKING_TIME_1 = "cooking_time_1",
    KEY_COOKING_TIME_2 = "cooking_time_2",
    KEY_COOKING_TEMP_OR_POWER_1 = "cooking_temp_or_power_1",
    KEY_COOKING_TEMP_OR_POWER_2 = "cooking_temp_or_power_2",
    KEY_SCREEN_TYPE = "screen_type",
    KEY_SCREEN_LEVEL = "screen_level",
    KEY_DOOR_OPENED = "door_opened",
    KEY_COOKING_PAUSED = "cooking_paused",
    KEY_COOKING_STATE = "cooking_state",
    KEY_DISPLAY_OPERATION_READY = "display_operation_ready",
    KEY_DEMO_OPEN = "demo_open",
    KEY_RECEIVE_RECIPE_READY = "receive_recipe_ready",
    KEY_SETTING_HIGH_TEMPERATURE = "setting_high_temperature",
    KEY_COOKING_HIGH_TEMPERATURE = "cooking_high_temperature",
    KEY_FERMENT_THAW_BAKERY_HIGH_TEMPERATURE = "ferment_thaw_bakery_high_temperature",
    KEY_LOW_TEMP_STEAM_HIGH_TEMPERATURE = "low_temp_steam_high_temperature",
    KEY_CAUTION_HIGH_TEMPERATURE = "caution_high_temperature",
    KEY_CAUTION_DURING_COOLING = "caution_during_cooling",
    KEY_CAUTION_WATER_SUPPLY = "caution_water_supply",
    KEY_REMAINING_TIME_DISPLAY = "remaining_time_display",
    KEY_DURING_COOKING_FINISH_CHANGE = "during_cooking_finish_change",
    KEY_REMAINING_TIME_FINISH_CHANGE = "remaining_time_finish_change",
    KEY_COOKING_TEMPERATURE_FINISH_CHANGE = "cooking_temperature_finish_change",
    KEY_REMAINING_TIME = "remaining_time",
    KEY_OPERATION_SOUND = "operation_sound",
    KEY_COMPLETION_SOUND = "completion_sound",
    KEY_ALARM_SOUND = "alarm_sound",
    KEY_CHAMBER_LIGHT_STATUS_DOOR_OPEN = "chamber_light_status_door_open",
    KEY_CHAMBER_LIGHT_STATUS_PREHEATING = "chamber_light_status_preheating",
    KEY_CHAMBER_LIGHT_STATUS_COOKING = "chamber_light_status_cooking",
    KEY_LCD_BRIGHTNESS = "lcd_brightness",
    KEY_SCREEN_BACKGROUND = "screen_background",
    KEY_ERROR_CODE = "error_code",
    KEY_FIRM = "firm",
    KEY_MACHINE_NAME = "machine_name",
    KEY_E2PROM = "e2prom",
    KEY_E2PROM_START_ADDRESS = "e2prom_start_address",
    KEY_COOKING_SETTING_DATA = "cooking_setting_data",
    KEY_TIME_LAST_START = "time_last_start",
    KEY_OVEN_LOW_TEMPERATURE_CIRCUIT = "oven_low_temperature_circuit",
    KEY_OVEN_HIGH_TEMPERATURE_CIRCUIT = "oven_high_temperature_circuit",
    KEY_STEAM_LOW_TEMPERATURE_CIRCUIT = "steam_low_temperature_circuit",
    KEY_STEAM_HIGH_TEMPERATURE_CIRCUIT = "steam_high_temperature_circuit",
    KEY_PANEL_THERMISTOR_DATA = "panel_thermistor_data",
    KEY_POWER_SUPPLY_VOLTAGE = "power_supply_voltage",
    KEY_PC_BOARD_OPERATING_TIME = "pc_board_operating_time",
    KEY_MICROWAVE_OPERATING_TIME = "microwave_operating_time",
    KEY_OVEN_OPERATING_TIME = "oven_operating_time",
    KEY_STEAM_OPERATING_TIME = "steam_operating_time",
    KEY_DISPLAY_OPERATING_TIME = "display_operating_time",
    KEY_DOOR_OPENING_COUNT = "door_opening_count"
}
local proTable = {
    recipe_number = 0x0000,
    process_number = 0x00,
    menu_code = 0xffff,
    cooking_strength = 0xffff,
    cooking_time_1 = 0x0000,
    cooking_time_2 = 0x0000,
    cooking_temp_or_power_1 = 0xff,
    cooking_temp_or_power_2 = 0xff,
    screen_type = 0x00,
    screen_level = 0x00,
    door_opened = 0x00,
    cooking_paused = 0x00,
    cooking_state = 0x00,
    display_operation_ready = 0x00,
    demo_open = 0x00,
    receive_recipe_ready = 0x00,
    setting_high_temperature = 0x00,
    cooking_high_temperature = 0x00,
    ferment_thaw_bakery_high_temperature = 0x00,
    low_temp_steam_high_temperature = 0x00,
    caution_high_temperature = 0x00,
    caution_during_cooling = 0x00,
    caution_water_supply = 0x00,
    remaining_time_display = 0x00,
    during_cooking_finish_change = 0x00,
    remaining_time_finish_change = 0x00,
    cooking_temperature_finish_change = 0x00,
    remaining_time = 0x00,
    operation_sound = 0x00,
    completion_sound = 0x00,
    alarm_sound = 0x00,
    chamber_light_status_door_open = 0x00,
    chamber_light_status_preheating = 0x00,
    chamber_light_status_cooking = 0x00,
    lcd_brightness = 0x00,
    screen_background = 0x00,
    error_code = 0x00,
    firm = nil,
    machine_name = nil,
    e2prom = nil,
    e2prom_start_address = 0x00,
    cooking_setting_data = nil,
    time_last_start = 0x00,
    oven_low_temperature_circuit = 0x00,
    oven_high_temperature_circuit = 0x00,
    steam_low_temperature_circuit = 0x00,
    steam_high_temperature_circuit = 0x00,
    panel_thermistor_data = 0x00,
    power_supply_voltage = 0x00,
    pc_board_operating_time = 0x00,
    microwave_operating_time = 0x00,
    oven_operating_time = 0x00,
    steam_operating_time = 0x00,
    display_operating_time = 0x00,
    door_opening_count = 0x00
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
    msgBytes[7] = 0xBF
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
local function getMenuCodeType(menu_code)
    if (menu_code >= 0x8001) and (menu_code <= 0x8010) then
        return 1
    else
        return 0
    end
end
local function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[keyTable.KEY_RECIPE_NUMBER] ~= nil then
        proTable.recipe_number =
            string2Int(luaTable[keyTable.KEY_RECIPE_NUMBER])
    end
    if luaTable[keyTable.KEY_PROCESS_NUMBER] ~= nil then
        proTable.process_number = string2Int(
                                      luaTable[keyTable.KEY_PROCESS_NUMBER])
    end
    if luaTable[keyTable.KEY_MENU_CODE] ~= nil then
        proTable.menu_code = string2Int(luaTable[keyTable.KEY_MENU_CODE])
    end
    if luaTable[keyTable.KEY_COOKING_STRENGTH] ~= nil then
        proTable.cooking_strength = string2Int(
                                        luaTable[keyTable.KEY_COOKING_STRENGTH])
    end
    if luaTable[keyTable.KEY_COOKING_TIME_1] ~= nil then
        proTable.cooking_time_1 = string2Int(
                                      luaTable[keyTable.KEY_COOKING_TIME_1])
    end
    if luaTable[keyTable.KEY_COOKING_TIME_2] ~= nil then
        proTable.cooking_time_2 = string2Int(
                                      luaTable[keyTable.KEY_COOKING_TIME_2])
    end
    if luaTable[keyTable.KEY_COOKING_TEMP_OR_POWER_1] ~= nil then
        proTable.cooking_temp_or_power_1 = string2Int(
                                               luaTable[keyTable.KEY_COOKING_TEMP_OR_POWER_1])
    end
    if luaTable[keyTable.KEY_COOKING_TEMP_OR_POWER_2] ~= nil then
        proTable.cooking_temp_or_power_2 = string2Int(
                                               luaTable[keyTable.KEY_COOKING_TEMP_OR_POWER_2])
    end
end
local function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == 0x02) then
        if messageBytes[0] == 0x00 then
            proTable.recipe_number = messageBytes[2] + messageBytes[1] * 256
            proTable.process_number = messageBytes[3]
            proTable.menu_code = messageBytes[5] + messageBytes[4] * 256
            if getMenuCodeType(proTable.menu_code) == 1 then
                proTable.cooking_time_1 =
                    messageBytes[7] + messageBytes[6] * 256
                proTable.cooking_time_2 =
                    messageBytes[9] + messageBytes[8] * 256
                proTable.cooking_temp_or_power_1 = messageBytes[11] +
                                                       messageBytes[10] * 256
                proTable.cooking_temp_or_power_2 = messageBytes[13] +
                                                       messageBytes[12] * 256
            else
                proTable.cooking_strength =
                    messageBytes[7] + messageBytes[6] * 256
            end
        end
    end
    if (dataType == 0x04) or (dataType == 0x03) then
        if messageBytes[0] == 0x00 then
            proTable.recipe_number = messageBytes[2] + messageBytes[1] * 256
            proTable.process_number = messageBytes[3]
            proTable.menu_code = messageBytes[5] + messageBytes[4] * 256
            if getMenuCodeType(proTable.menu_code) == 1 then
                proTable.cooking_time_1 =
                    messageBytes[7] + messageBytes[6] * 256
                proTable.cooking_time_2 =
                    messageBytes[9] + messageBytes[8] * 256
                proTable.cooking_temp_or_power_1 = messageBytes[11] +
                                                       messageBytes[10] * 256
                proTable.cooking_temp_or_power_2 = messageBytes[13] +
                                                       messageBytes[12] * 256
            else
                proTable.cooking_strength =
                    messageBytes[7] + messageBytes[6] * 256
            end
            proTable.screen_type = messageBytes[17]
            proTable.screen_level = messageBytes[18]
            proTable.door_opened = bit.band(messageBytes[19], 0x01)
            proTable.cooking_paused = bit.band(messageBytes[19], 0x02)
            proTable.cooking_state = bit.band(bit.rshift(messageBytes[19], 2),
                                              0x07)
            proTable.display_operation_ready = bit.band(messageBytes[19], 0x20)
            proTable.demo_open = bit.band(messageBytes[19], 0x40)
            proTable.receive_recipe_ready = bit.band(messageBytes[19], 0x80)
            proTable.setting_high_temperature = bit.band(messageBytes[20], 0x01)
            proTable.cooking_high_temperature = bit.band(messageBytes[20], 0x02)
            proTable.ferment_thaw_bakery_high_temperature = bit.band(
                                                                messageBytes[20],
                                                                0x04)
            proTable.low_temp_steam_high_temperature = bit.band(
                                                           messageBytes[20],
                                                           0x08)
            proTable.caution_high_temperature = bit.band(messageBytes[21], 0x01)
            proTable.caution_during_cooling = bit.band(messageBytes[21], 0x02)
            proTable.caution_water_supply = bit.band(messageBytes[21], 0x04)
            proTable.remaining_time_display = bit.band(messageBytes[21], 0x08)
            proTable.during_cooking_finish_change =
                bit.band(messageBytes[21], 0x10)
            proTable.remaining_time_finish_change =
                bit.band(messageBytes[21], 0x20)
            proTable.cooking_temperature_finish_change = bit.band(
                                                             messageBytes[21],
                                                             0x40)
            proTable.remaining_time = messageBytes[23] * 256 + messageBytes[22]
            proTable.operation_sound = bit.band(messageBytes[24], 0x01)
            proTable.completion_sound = bit.band(messageBytes[24], 0x02)
            proTable.alarm_sound = bit.band(messageBytes[24], 0x04)
            proTable.chamber_light_status_door_open =
                bit.band(messageBytes[25], 0x01)
            proTable.chamber_light_status_preheating = bit.band(
                                                           messageBytes[25],
                                                           0x02)
            proTable.chamber_light_status_cooking =
                bit.band(messageBytes[25], 0x04)
            proTable.lcd_brightness = messageBytes[26]
            proTable.screen_background = messageBytes[27]
        end
    end
    if (dataType == 0x03) or (dataType == 0x0A) then
        if (messageBytes[0] == 0x21) or (messageBytes[0] == 0xFE) then
            proTable.error_code = messageBytes[2] * 256 + messageBytes[1]
            local firmTab = {}
            for i = 1, 7 do firmTab[i] = messageBytes[2 + i] end
            local firmTabStr = table2string(firmTab)
            proTable.firm = string2hexstring(firmTabStr)
            local mnTab = {}
            for i = 1, 18 do mnTab[i] = messageBytes[9 + i] end
            local mnTabStr = table2string(mnTab)
            proTable.machine_name = string2hexstring(mnTabStr)
            local e2promTab = {}
            for i = 1, 1024 do e2promTab[i] = messageBytes[27 + i] end
            local e2promTabStr = table2string(e2promTab)
            proTable.e2prom = string2hexstring(e2promTabStr)
            proTable.e2prom_start_address =
                messageBytes[1053] * 256 + messageBytes[1052]
            local cookSettingTab = {}
            for i = 1, 16 do
                cookSettingTab[i] = messageBytes[1053 + i]
            end
            local cookSettingTabStr = table2string(cookSettingTab)
            proTable.cooking_setting_data = string2hexstring(cookSettingTabStr)
            proTable.time_last_start = messageBytes[1072] * 65536 +
                                           messageBytes[1071] * 256 +
                                           messageBytes[1070]
            proTable.oven_low_temperature_circuit = messageBytes[1073]
            proTable.oven_high_temperature_circuit = messageBytes[1074]
            proTable.steam_low_temperature_circuit = messageBytes[1075]
            proTable.steam_high_temperature_circuit = messageBytes[1076]
            proTable.panel_thermistor_data = messageBytes[1077]
            proTable.power_supply_voltage = messageBytes[1078]
            proTable.pc_board_operating_time =
                messageBytes[1081] * 65536 + messageBytes[1080] * 256 +
                    messageBytes[1079]
            proTable.microwave_operating_time =
                messageBytes[1084] * 65536 + messageBytes[1083] * 256 +
                    messageBytes[1082]
            proTable.oven_operating_time =
                messageBytes[1087] * 65536 + messageBytes[1086] * 256 +
                    messageBytes[1085]
            proTable.steam_operating_time =
                messageBytes[1090] * 65536 + messageBytes[1089] * 256 +
                    messageBytes[1088]
            proTable.display_operating_time =
                messageBytes[1093] * 65536 + messageBytes[1092] * 256 +
                    messageBytes[1091]
            proTable.door_opening_count =
                messageBytes[1096] * 65536 + messageBytes[1095] * 256 +
                    messageBytes[1094]
        end
    end
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[keyTable.KEY_VERSION] = version
    if (subDataType == 0x00) then
        streams[keyTable.KEY_FUNCTION_TYPE] = "base"
        streams[keyTable.KEY_PROPERTY_TYPE] = "base"
        streams[keyTable.KEY_RECIPE_NUMBER] = proTable.recipe_number
        streams[keyTable.KEY_PROCESS_NUMBER] = proTable.process_number
        streams[keyTable.KEY_MENU_CODE] = proTable.menu_code
        streams[keyTable.KEY_COOKING_STRENGTH] = proTable.cooking_strength
        streams[keyTable.KEY_COOKING_TIME_1] = proTable.cooking_time_1
        streams[keyTable.KEY_COOKING_TIME_2] = proTable.cooking_time_2
        streams[keyTable.KEY_COOKING_TEMP_OR_POWER_1] =
            proTable.cooking_temp_or_power_1
        streams[keyTable.KEY_COOKING_TEMP_OR_POWER_2] =
            proTable.cooking_temp_or_power_2
        streams[keyTable.KEY_SCREEN_TYPE] = proTable.screen_type
        streams[keyTable.KEY_SCREEN_LEVEL] = proTable.screen_level
        if proTable.door_opened == 0x01 then
            streams[keyTable.KEY_DOOR_OPENED] = "yes"
        else
            streams[keyTable.KEY_DOOR_OPENED] = "no"
        end
        if proTable.cooking_paused == 0x02 then
            streams[keyTable.KEY_COOKING_PAUSED] = "yes"
        else
            streams[keyTable.KEY_COOKING_PAUSED] = "no"
        end
        if proTable.cooking_state == 0x04 then
            streams[keyTable.KEY_COOKING_STATE] = "during_process"
        elseif proTable.cooking_state == 0x07 then
            streams[keyTable.KEY_COOKING_STATE] = "finished_process"
        elseif proTable.cooking_state == 0x01 then
            streams[keyTable.KEY_COOKING_STATE] = "finish_cooking"
        elseif proTable.cooking_state == 0x03 then
            streams[keyTable.KEY_COOKING_STATE] = "error_occur"
        else
            streams[keyTable.KEY_COOKING_STATE] = "before_cooking"
        end
        if proTable.display_operation_ready == 0x20 then
            streams[keyTable.KEY_DISPLAY_OPERATION_READY] = "yes"
        else
            streams[keyTable.KEY_DISPLAY_OPERATION_READY] = "no"
        end
        if proTable.demo_open == 0x40 then
            streams[keyTable.KEY_DEMO_OPEN] = "yes"
        else
            streams[keyTable.KEY_DEMO_OPEN] = "no"
        end
        if proTable.receive_recipe_ready == 0x80 then
            streams[keyTable.KEY_RECEIVE_RECIPE_READY] = "yes"
        else
            streams[keyTable.KEY_RECEIVE_RECIPE_READY] = "no"
        end
        if proTable.setting_high_temperature == 0x01 then
            streams[keyTable.KEY_SETTING_HIGH_TEMPERATURE] = "yes"
        else
            streams[keyTable.KEY_SETTING_HIGH_TEMPERATURE] = "no"
        end
        if proTable.cooking_high_temperature == 0x02 then
            streams[keyTable.KEY_COOKING_HIGH_TEMPERATURE] = "yes"
        else
            streams[keyTable.KEY_COOKING_HIGH_TEMPERATURE] = "no"
        end
        if proTable.ferment_thaw_bakery_high_temperature == 0x04 then
            streams[keyTable.KEY_FERMENT_THAW_BAKERY_HIGH_TEMPERATURE] = "yes"
        else
            streams[keyTable.KEY_FERMENT_THAW_BAKERY_HIGH_TEMPERATURE] = "no"
        end
        if proTable.low_temp_steam_high_temperature == 0x08 then
            streams[keyTable.KEY_LOW_TEMP_STEAM_HIGH_TEMPERATURE] = "yes"
        else
            streams[keyTable.KEY_LOW_TEMP_STEAM_HIGH_TEMPERATURE] = "no"
        end
        if proTable.caution_high_temperature == 0x01 then
            streams[keyTable.KEY_CAUTION_HIGH_TEMPERATURE] = "yes"
        else
            streams[keyTable.KEY_CAUTION_HIGH_TEMPERATURE] = "no"
        end
        if proTable.caution_during_cooling == 0x02 then
            streams[keyTable.KEY_CAUTION_DURING_COOLING] = "yes"
        else
            streams[keyTable.KEY_CAUTION_DURING_COOLING] = "no"
        end
        if proTable.caution_water_supply == 0x04 then
            streams[keyTable.KEY_CAUTION_WATER_SUPPLY] = "yes"
        else
            streams[keyTable.KEY_CAUTION_WATER_SUPPLY] = "no"
        end
        if proTable.remaining_time_display == 0x08 then
            streams[keyTable.KEY_REMAINING_TIME_DISPLAY] = "yes"
        else
            streams[keyTable.KEY_REMAINING_TIME_DISPLAY] = "no"
        end
        if proTable.during_cooking_finish_change == 0x10 then
            streams[keyTable.KEY_DURING_COOKING_FINISH_CHANGE] = "yes"
        else
            streams[keyTable.KEY_DURING_COOKING_FINISH_CHANGE] = "no"
        end
        if proTable.remaining_time_finish_change == 0x20 then
            streams[keyTable.KEY_REMAINING_TIME_FINISH_CHANGE] = "yes"
        else
            streams[keyTable.KEY_REMAINING_TIME_FINISH_CHANGE] = "no"
        end
        if proTable.cooking_temperature_finish_change == 0x40 then
            streams[keyTable.KEY_COOKING_TEMPERATURE_FINISH_CHANGE] = "yes"
        else
            streams[keyTable.KEY_COOKING_TEMPERATURE_FINISH_CHANGE] = "no"
        end
        streams[keyTable.KEY_REMAINING_TIME] = proTable.remaining_time
        if proTable.operation_sound == 0x01 then
            streams[keyTable.KEY_OPERATION_SOUND] = "yes"
        else
            streams[keyTable.KEY_OPERATION_SOUND] = "no"
        end
        if proTable.completion_sound == 0x02 then
            streams[keyTable.KEY_COMPLETION_SOUND] = "yes"
        else
            streams[keyTable.KEY_COMPLETION_SOUND] = "no"
        end
        if proTable.alarm_sound == 0x04 then
            streams[keyTable.KEY_ALARM_SOUND] = "yes"
        else
            streams[keyTable.KEY_ALARM_SOUND] = "no"
        end
        if proTable.chamber_light_status_door_open == 0x01 then
            streams[keyTable.KEY_CHAMBER_LIGHT_STATUS_DOOR_OPEN] = "yes"
        else
            streams[keyTable.KEY_CHAMBER_LIGHT_STATUS_DOOR_OPEN] = "no"
        end
        if proTable.chamber_light_status_preheating == 0x02 then
            streams[keyTable.KEY_CHAMBER_LIGHT_STATUS_PREHEATING] = "yes"
        else
            streams[keyTable.KEY_CHAMBER_LIGHT_STATUS_PREHEATING] = "no"
        end
        if proTable.chamber_light_status_cooking == 0x04 then
            streams[keyTable.KEY_CHAMBER_LIGHT_STATUS_COOKING] = "yes"
        else
            streams[keyTable.KEY_CHAMBER_LIGHT_STATUS_COOKING] = "no"
        end
        streams[keyTable.KEY_LCD_BRIGHTNESS] = proTable.lcd_brightness
        if proTable.screen_background == 0x01 then
            streams[keyTable.KEY_SCREEN_BACKGROUND] = "yes"
        else
            streams[keyTable.KEY_SCREEN_BACKGROUND] = "no"
        end
    else
        streams[keyTable.KEY_FUNCTION_TYPE] = "exception"
        if (subDataType == 0x21) then
            streams[keyTable.KEY_PROPERTY_TYPE] = "periodic"
        elseif (subDataType == 0xFE) then
            streams[keyTable.KEY_PROPERTY_TYPE] = "error"
        else
            streams[keyTable.KEY_PROPERTY_TYPE] = "other"
        end
        streams[keyTable.KEY_ERROR_CODE] = proTable.error_code
        streams[keyTable.KEY_FIRM] = proTable.firm
        streams[keyTable.KEY_MACHINE_NAME] = proTable.machine_name
        streams[keyTable.KEY_E2PROM] = proTable.e2prom
        streams[keyTable.KEY_E2PROM_START_ADDRESS] =
            proTable.e2prom_start_address
        streams[keyTable.KEY_COOKING_SETTING_DATA] =
            proTable.cooking_setting_data
        streams[keyTable.KEY_TIME_LAST_START] = proTable.time_last_start
        streams[keyTable.KEY_OVEN_LOW_TEMPERATURE_CIRCUIT] =
            proTable.oven_low_temperature_circuit
        streams[keyTable.KEY_OVEN_HIGH_TEMPERATURE_CIRCUIT] =
            proTable.oven_high_temperature_circuit
        streams[keyTable.KEY_STEAM_LOW_TEMPERATURE_CIRCUIT] =
            proTable.steam_low_temperature_circuit
        streams[keyTable.KEY_STEAM_HIGH_TEMPERATURE_CIRCUIT] =
            proTable.steam_high_temperature_circuit
        streams[keyTable.KEY_PANEL_THERMISTOR_DATA] =
            proTable.panel_thermistor_data
        streams[keyTable.KEY_POWER_SUPPLY_VOLTAGE] =
            proTable.power_supply_voltage
        streams[keyTable.KEY_PC_BOARD_OPERATING_TIME] =
            proTable.pc_board_operating_time
        streams[keyTable.KEY_MICROWAVE_OPERATING_TIME] =
            proTable.microwave_operating_time
        streams[keyTable.KEY_OVEN_OPERATING_TIME] = proTable.oven_operating_time
        streams[keyTable.KEY_STEAM_OPERATING_TIME] =
            proTable.steam_operating_time
        streams[keyTable.KEY_DISPLAY_OPERATING_TIME] =
            proTable.display_operating_time
        streams[keyTable.KEY_DOOR_OPENING_COUNT] = proTable.door_opening_count
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
        local bodyLength = 28
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
        bodyBytes[0] = 0x00
        bodyBytes[1] = bit.band(bit.rshift(proTable.recipe_number, 8), 0xff)
        bodyBytes[2] = bit.band(proTable.recipe_number, 0xff)
        bodyBytes[3] = proTable.process_number
        bodyBytes[4] = bit.band(bit.rshift(proTable.menu_code, 8), 0xff)
        bodyBytes[5] = bit.band(proTable.menu_code, 0xff)
        if getMenuCodeType(proTable.menu_code) == 1 then
            bodyBytes[6] =
                bit.band(bit.rshift(proTable.cooking_time_1, 8), 0xff)
            bodyBytes[7] = bit.band(proTable.cooking_time_1, 0xff)
            bodyBytes[8] =
                bit.band(bit.rshift(proTable.cooking_time_2, 8), 0xff)
            bodyBytes[9] = bit.band(proTable.cooking_time_2, 0xff)
            bodyBytes[10] = bit.band(bit.rshift(
                                         proTable.cooking_temp_or_power_1, 8),
                                     0xff)
            bodyBytes[11] = bit.band(proTable.cooking_temp_or_power_1, 0xff)
            bodyBytes[12] = bit.band(bit.rshift(
                                         proTable.cooking_temp_or_power_2, 8),
                                     0xff)
            bodyBytes[13] = bit.band(proTable.cooking_temp_or_power_2, 0xff)
        else
            if (proTable.menu_code == 0x0000) then
                bodyBytes[6] = 0x00;
                bodyBytes[7] = 0x00;
            else
                bodyBytes[6] = bit.band(
                                   bit.rshift(proTable.cooking_strength, 8),
                                   0xff)
                bodyBytes[7] = bit.band(proTable.cooking_strength, 0xff)
            end
            bodyBytes[8] = 0x00
            bodyBytes[9] = 0x00
            bodyBytes[10] = 0x00
            bodyBytes[11] = 0x00
            bodyBytes[12] = 0x00
            bodyBytes[13] = 0x00
        end
        bodyBytes[14] = 0x00
        bodyBytes[15] = 0x00
        bodyBytes[16] = 0x00
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
