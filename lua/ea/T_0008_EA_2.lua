local JSON = require "cjson"
local BYTE_PROTOCOL_LENGTH = 0x10
local dataType = 0x0000
local subDataType = 0x00
local version = 1
local keyTable = {
    KEY_VERSION = "version",
    KEY_FUNCTION_TYPE = "function_type",
    KEY_PROPERTY_TYPE = "property_type",
    KEY_SET_MODE = "set_mode",
    KEY_RECIPE_CODE = "recipe_code",
    KEY_RICE_BRAND = "rice_brand",
    KEY_COOKING_TIME = "cooking_time",
    KEY_COOKING_METHOD = "cooking_method",
    KEY_COOKING_TEMPERATURE = "cooking_temperature",
    KEY_RICE_HARDNESS = "rice_hardness",
    KEY_WATER_HARDNESS_SELECT = "water_hardness_select",
    KEY_WATER_HARDNESS_VAL = "water_hardness_val",
    KEY_SOAK_TIME = "soak_time",
    KEY_PUMP_TIME_CORRECTION1 = "pump_time_correction1",
    KEY_PUMP_TIME_CORRECTION2 = "pump_time_correction2",
    KEY_PROCESS_TIME_CORRECTION1 = "process_time_correction1",
    KEY_PROCESS_TIME_CORRECTION2 = "process_time_correction2",
    KEY_ADDITIONAL_CORRECTION1 = "additional_correction1",
    KEY_ADDITIONAL_CORRECTION2 = "additional_correction2",
    KEY_COOKING_END_TIME_H = "cooking_end_time_h",
    KEY_COOKING_END_TIME_M = "cooking_end_time_m",
    KEY_COOKING_COURSE = "cooking_course",
    KEY_COOKING_STATE = "cooking_state",
    KEY_REMAIN_TIME_H = "remain_time_h",
    KEY_REMAIN_TIME_M = "remain_time_m",
    KEY_REMAIN_TIME_S = "remain_time_s",
    KEY_SET_RESULT = "set_result",
    KEY_ERROR_CODE = "error_code",
    KEY_KEEP_WARM_EXCEED = "keep_warm_exceed"
}
local proTable = {
    set_mode = 0x00,
    recipe_code = 0x0000,
    rice_brand = 0xFFFF,
    cooking_time = 0xFF,
    cooking_method = 0xFF,
    cooking_temperature = 0xFF,
    rice_hardness = 0xFF,
    water_hardness_select = 1,
    water_hardness_val = 0xFF,
    soak_time = 0xFF,
    pump_time_correction1 = 0xF,
    pump_time_correction2 = 0xF,
    process_time_correction1 = 0xF,
    process_time_correction2 = 0xF,
    additional_correction1 = 0xF,
    additional_correction2 = 0xF,
    cooking_end_time_h = 0xFF,
    cooking_end_time_m = 0xFF,
    cooking_course = 0xFF,
    cooking_state = nil,
    remain_time_h,
    remain_time_m,
    remain_time_s,
    set_result = nil,
    error_code = 0x0000,
    keep_warm_exceed = 0,
    log_data = 0
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
    msgBytes[7] = 0xEA
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
local function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[keyTable.KEY_SET_MODE] ~= nil then
        if luaTable[keyTable.KEY_SET_MODE] == "recipe" then
            proTable.set_mode = 0x01
        elseif luaTable[keyTable.KEY_SET_MODE] == "history" then
            proTable.set_mode = 0x02
        elseif luaTable[keyTable.KEY_SET_MODE] == "water_hardness" then
            proTable.set_mode = 0x11
        elseif luaTable[keyTable.KEY_SET_MODE] == "reservation_time" then
            proTable.set_mode = 0x21
        end
    end
    if luaTable["cooking_settings"] == nil then
        if luaTable[keyTable.KEY_COOKING_END_TIME_H] ~= nil then
            proTable.cooking_end_time_h = string2Int(
                                              luaTable[keyTable.KEY_COOKING_END_TIME_H] +
                                                  (math.floor(
                                                      luaTable[keyTable.KEY_COOKING_END_TIME_H] /
                                                          10) * 6))
        end
        if luaTable[keyTable.KEY_COOKING_END_TIME_M] ~= nil then
            proTable.cooking_end_time_m = string2Int(
                                              luaTable[keyTable.KEY_COOKING_END_TIME_M] +
                                                  (math.floor(
                                                      luaTable[keyTable.KEY_COOKING_END_TIME_M] /
                                                          10) * 6))
        end
        if luaTable[keyTable.KEY_WATER_HARDNESS_SELECT] ~= nil then
            if luaTable[keyTable.KEY_WATER_HARDNESS_SELECT] == "value" then
                proTable.water_hardness_select = 0x01
            elseif luaTable[keyTable.KEY_WATER_HARDNESS_SELECT] == "level" then
                proTable.water_hardness_select = 0x00
            end
        end
        if luaTable[keyTable.KEY_WATER_HARDNESS_VAL] ~= nil then
            proTable.water_hardness_val = string2Int(
                                              luaTable[keyTable.KEY_WATER_HARDNESS_VAL])
        end
    else
        if luaTable["cooking_settings"][keyTable.KEY_COOKING_END_TIME_H] ~= nil then
            proTable.cooking_end_time_h = string2Int(
                                              luaTable["cooking_settings"][keyTable.KEY_COOKING_END_TIME_H] +
                                                  (math.floor(
                                                      luaTable["cooking_settings"][keyTable.KEY_COOKING_END_TIME_H] /
                                                          10) * 6))
        end
        if luaTable["cooking_settings"][keyTable.KEY_COOKING_END_TIME_M] ~= nil then
            proTable.cooking_end_time_m = string2Int(
                                              luaTable["cooking_settings"][keyTable.KEY_COOKING_END_TIME_M] +
                                                  (math.floor(
                                                      luaTable["cooking_settings"][keyTable.KEY_COOKING_END_TIME_M] /
                                                          10) * 6))
        end
        if luaTable["cooking_settings"][keyTable.KEY_WATER_HARDNESS_SELECT] ~=
            nil then
            proTable.water_hardness_select = string2Int(
                                                 luaTable["cooking_settings"][keyTable.KEY_WATER_HARDNESS_SELECT])
        end
        if luaTable["cooking_settings"][keyTable.KEY_WATER_HARDNESS_VAL] ~= nil then
            proTable.water_hardness_val = string2Int(
                                              luaTable["cooking_settings"][keyTable.KEY_WATER_HARDNESS_VAL])
        end
        if luaTable["cooking_settings"][keyTable.KEY_RICE_BRAND] ~= nil then
            proTable.rice_brand = string2Int(
                                      luaTable["cooking_settings"][keyTable.KEY_RICE_BRAND])
        end
        if luaTable["cooking_settings"][keyTable.KEY_COOKING_METHOD] ~= nil then
            proTable.cooking_method = string2Int(
                                          luaTable["cooking_settings"][keyTable.KEY_COOKING_METHOD])
        end
        if luaTable["cooking_settings"][keyTable.KEY_COOKING_TIME] ~= nil then
            proTable.cooking_time = string2Int(
                                        luaTable["cooking_settings"][keyTable.KEY_COOKING_TIME])
        end
        if luaTable["cooking_settings"][keyTable.KEY_RICE_HARDNESS] ~= nil then
            proTable.rice_hardness = string2Int(
                                         luaTable["cooking_settings"][keyTable.KEY_RICE_HARDNESS])
        end
        if luaTable["cooking_settings"][keyTable.KEY_COOKING_TEMPERATURE] ~= nil then
            proTable.cooking_temperature = string2Int(
                                               luaTable["cooking_settings"][keyTable.KEY_COOKING_TEMPERATURE])
        end
        if luaTable["cooking_settings"][keyTable.KEY_COOKING_COURSE] ~= nil then
            proTable.cooking_course = string2Int(
                                          luaTable["cooking_settings"][keyTable.KEY_COOKING_COURSE])
        end
        if luaTable["cooking_settings"][keyTable.KEY_RECIPE_CODE] ~= nil then
            proTable.recipe_code = string2Int(
                                       luaTable["cooking_settings"][keyTable.KEY_RECIPE_CODE])
        end
        if luaTable["cooking_settings"][keyTable.KEY_SOAK_TIME] ~= nil then
            proTable.soak_time = string2Int(
                                     luaTable["cooking_settings"][keyTable.KEY_SOAK_TIME])
        end
        if luaTable["cooking_settings"][keyTable.KEY_PUMP_TIME_CORRECTION1] ~=
            nil then
            proTable.pump_time_correction1 = string2Int(
                                                 luaTable["cooking_settings"][keyTable.KEY_PUMP_TIME_CORRECTION1])
        end
        if luaTable["cooking_settings"][keyTable.KEY_PUMP_TIME_CORRECTION2] ~=
            nil then
            proTable.pump_time_correction2 = string2Int(
                                                 luaTable["cooking_settings"][keyTable.KEY_PUMP_TIME_CORRECTION2])
        end
        if luaTable["cooking_settings"][keyTable.KEY_PROCESS_TIME_CORRECTION1] ~=
            nil then
            proTable.process_time_correction1 = string2Int(
                                                    luaTable["cooking_settings"][keyTable.KEY_PROCESS_TIME_CORRECTION1])
        end
        if luaTable["cooking_settings"][keyTable.KEY_PROCESS_TIME_CORRECTION2] ~=
            nil then
            proTable.process_time_correction2 = string2Int(
                                                    luaTable["cooking_settings"][keyTable.KEY_PROCESS_TIME_CORRECTION2])
        end
        if luaTable["cooking_settings"][keyTable.KEY_ADDITIONAL_CORRECTION1] ~=
            nil then
            proTable.additional_correction1 = string2Int(
                                                  luaTable["cooking_settings"][keyTable.KEY_ADDITIONAL_CORRECTION1])
        end
        if luaTable["cooking_settings"][keyTable.KEY_ADDITIONAL_CORRECTION2] ~=
            nil then
            proTable.additional_correction2 = string2Int(
                                                  luaTable["cooking_settings"][keyTable.KEY_ADDITIONAL_CORRECTION2])
        end
    end
end
local function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == 0x0280) or (dataType == 0x0400) or (dataType == 0x0300) then
        proTable.set_mode = messageBytes[1]
        proTable.recipe_code = messageBytes[3] * 256 + messageBytes[2]
        proTable.rice_brand = messageBytes[5] * 256 + messageBytes[4]
        if proTable.rice_brand == 0x0013 or proTable.rice_brand == 0x0014 then
            proTable.cooking_time = messageBytes[6]
            proTable.cooking_method = "none"
        else
            proTable.cooking_time = "none"
            proTable.cooking_method = messageBytes[6]
        end
        if proTable.rice_brand == 0x0013 or proTable.rice_brand == 0x0014 then
            proTable.cooking_temperature = messageBytes[7]
            proTable.rice_hardness = "none"
        else
            proTable.cooking_temperature = "none"
            proTable.rice_hardness = messageBytes[7]
        end
        proTable.water_hardness_select = bit.rshift(messageBytes[8], 7)
        if proTable.water_hardness_select == 1 then
            proTable.water_hardness_val = messageBytes[9]
        else
            proTable.water_hardness_val = bit.band(messageBytes[8], 0x7F)
        end
        proTable.soak_time = messageBytes[10]
        proTable.pump_time_correction1 = bit.band(messageBytes[11], 0x0F)
        proTable.pump_time_correction2 = bit.rshift(
                                             bit.band(messageBytes[11], 0xF0), 4)
        proTable.process_time_correction1 = bit.band(messageBytes[12], 0x0F)
        proTable.process_time_correction2 =
            bit.rshift(bit.band(messageBytes[12], 0xF0), 4)
        proTable.additional_correction1 = bit.band(messageBytes[13], 0x0F)
        proTable.additional_correction2 = bit.rshift(
                                              bit.band(messageBytes[13], 0xF0),
                                              4)
        proTable.cooking_end_time_h = messageBytes[15] -
                                          (math.floor(messageBytes[15] / 0x10) *
                                              6)
        proTable.cooking_end_time_m = messageBytes[14] -
                                          (math.floor(messageBytes[14] / 0x10) *
                                              6)
        proTable.cooking_course = messageBytes[16]
        proTable.set_result = messageBytes[17]
        proTable.error_code = messageBytes[19] * 256 + messageBytes[18]
        proTable.remain_time_h = messageBytes[22] -
                                     (math.floor(messageBytes[22] / 0x10) * 6)
        proTable.remain_time_m = messageBytes[21] -
                                     (math.floor(messageBytes[21] / 0x10) * 6)
        proTable.remain_time_s = messageBytes[20] -
                                     (math.floor(messageBytes[20] / 0x10) * 6)
        proTable.cooking_state = messageBytes[23]
        proTable.keep_warm_exceed = bit.rshift(bit.band(messageBytes[24], 0x40),
                                               6)
    end
    if (dataType == 0x0A00) then
        if (messageBytes[0] == 0xFE) and (messageBytes[1] == 0x00) then
            proTable.error_code = messageBytes[3] * 256 + messageBytes[2]
            proTable.recipe_code = messageBytes[33] * 256 + messageBytes[32]
            proTable.rice_brand = messageBytes[35] * 256 + messageBytes[34]
            if proTable.rice_brand == 0x0013 or proTable.rice_brand == 0x0014 then
                proTable.cooking_time = messageBytes[36]
                proTable.cooking_method = "none"
            else
                proTable.cooking_time = "none"
                proTable.cooking_method = messageBytes[36]
            end
            if proTable.rice_brand == 0x0013 or proTable.rice_brand == 0x0014 then
                proTable.cooking_temperature = messageBytes[37]
                proTable.rice_hardness = "none"
            else
                proTable.cooking_temperature = "none"
                proTable.rice_hardness = messageBytes[37]
            end
            proTable.water_hardness_select = bit.rshift(messageBytes[38], 7)
            if proTable.water_hardness_select == 1 then
                proTable.water_hardness_val = messageBytes[39]
            else
                proTable.water_hardness_val = bit.band(messageBytes[38], 0x7F)
            end
            proTable.soak_time = messageBytes[40]
            proTable.pump_time_correction1 = bit.band(messageBytes[41], 0x0F)
            proTable.pump_time_correction2 =
                bit.rshift(bit.band(messageBytes[41], 0xF0), 4)
            proTable.process_time_correction1 = bit.band(messageBytes[42], 0x0F)
            proTable.process_time_correction2 =
                bit.rshift(bit.band(messageBytes[42], 0xF0), 4)
            proTable.additional_correction1 = bit.band(messageBytes[43], 0x0F)
            proTable.additional_correction2 =
                bit.rshift(bit.band(messageBytes[43], 0xF0), 4)
            proTable.cooking_end_time_h = messageBytes[45] -
                                              (math.floor(
                                                  messageBytes[45] / 0x10) * 6)
            proTable.cooking_end_time_m = messageBytes[44] -
                                              (math.floor(
                                                  messageBytes[44] / 0x10) * 6)
            proTable.cooking_course = messageBytes[46]
        end
    end
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[keyTable.KEY_VERSION] = version
    if ((subDataType == 0x00) and (dataType == 0x0400)) or
        ((subDataType == 0x00) and (dataType == 0x0300)) then
        streams[keyTable.KEY_FUNCTION_TYPE] = "base"
        streams[keyTable.KEY_PROPERTY_TYPE] = "base"
        if proTable.cooking_state == 0x01 then
            streams[keyTable.KEY_COOKING_STATE] = "stop"
        elseif proTable.cooking_state == 0x02 then
            streams[keyTable.KEY_COOKING_STATE] = "error"
        elseif proTable.cooking_state == 0x03 then
            streams[keyTable.KEY_COOKING_STATE] = "reserved"
        elseif proTable.cooking_state == 0x04 then
            streams[keyTable.KEY_COOKING_STATE] = "soak"
        elseif proTable.cooking_state == 0x05 then
            streams[keyTable.KEY_COOKING_STATE] = "rice_cooking"
        elseif proTable.cooking_state == 0x06 then
            streams[keyTable.KEY_COOKING_STATE] = "steam"
        elseif proTable.cooking_state == 0x07 then
            streams[keyTable.KEY_COOKING_STATE] = "keep_warm"
        elseif proTable.cooking_state == 0x08 then
            streams[keyTable.KEY_COOKING_STATE] = "heat_cleaning"
        elseif proTable.cooking_state == 0x0A then
            streams[keyTable.KEY_COOKING_STATE] = "cooking"
        else
            streams[keyTable.KEY_COOKING_STATE] = "stop"
        end
        streams[keyTable.KEY_REMAIN_TIME_H] = proTable.remain_time_h
        streams[keyTable.KEY_REMAIN_TIME_M] = proTable.remain_time_m
        streams[keyTable.KEY_REMAIN_TIME_S] = proTable.remain_time_s
        streams[keyTable.KEY_ERROR_CODE] = proTable.error_code
        if proTable.keep_warm_exceed == 0 then
            streams[keyTable.KEY_KEEP_WARM_EXCEED] = "FALSE"
        else
            streams[keyTable.KEY_KEEP_WARM_EXCEED] = "TRUE"
        end
        streams["cooking_settings"] = {}
        streams["cooking_settings"][keyTable.KEY_RECIPE_CODE] =
            proTable.recipe_code
        streams["cooking_settings"][keyTable.KEY_RICE_BRAND] =
            proTable.rice_brand
        streams["cooking_settings"][keyTable.KEY_COOKING_TIME] =
            proTable.cooking_time
        streams["cooking_settings"][keyTable.KEY_COOKING_METHOD] =
            proTable.cooking_method
        streams["cooking_settings"][keyTable.KEY_COOKING_TEMPERATURE] =
            proTable.cooking_temperature
        streams["cooking_settings"][keyTable.KEY_RICE_HARDNESS] =
            proTable.rice_hardness
        streams["cooking_settings"][keyTable.KEY_WATER_HARDNESS_SELECT] =
            proTable.water_hardness_select
        streams["cooking_settings"][keyTable.KEY_WATER_HARDNESS_VAL] =
            proTable.water_hardness_val
        streams["cooking_settings"][keyTable.KEY_SOAK_TIME] = proTable.soak_time
        streams["cooking_settings"][keyTable.KEY_PUMP_TIME_CORRECTION1] =
            proTable.pump_time_correction1
        streams["cooking_settings"][keyTable.KEY_PUMP_TIME_CORRECTION2] =
            proTable.pump_time_correction2
        streams["cooking_settings"][keyTable.KEY_PROCESS_TIME_CORRECTION1] =
            proTable.process_time_correction1
        streams["cooking_settings"][keyTable.KEY_PROCESS_TIME_CORRECTION2] =
            proTable.process_time_correction2
        streams["cooking_settings"][keyTable.KEY_ADDITIONAL_CORRECTION1] =
            proTable.additional_correction1
        streams["cooking_settings"][keyTable.KEY_ADDITIONAL_CORRECTION2] =
            proTable.additional_correction2
        streams["cooking_settings"][keyTable.KEY_COOKING_END_TIME_H] =
            proTable.cooking_end_time_h
        streams["cooking_settings"][keyTable.KEY_COOKING_END_TIME_M] =
            proTable.cooking_end_time_m
        streams["cooking_settings"][keyTable.KEY_COOKING_COURSE] =
            proTable.cooking_course
    elseif (subDataType == 0x00) and (dataType == 0x0280) then
        streams[keyTable.KEY_FUNCTION_TYPE] = "base"
        streams[keyTable.KEY_PROPERTY_TYPE] = "set_response"
        if proTable.set_result == 0x01 then
            streams[keyTable.KEY_SET_RESULT] = "success"
        elseif proTable.set_result == 0x02 then
            streams[keyTable.KEY_SET_RESULT] = "fail1"
        elseif proTable.set_result == 0x03 then
            streams[keyTable.KEY_SET_RESULT] = "fail2"
        elseif proTable.set_result == 0x04 then
            streams[keyTable.KEY_SET_RESULT] = "fail3"
        elseif proTable.set_result == 0x05 then
            streams[keyTable.KEY_SET_RESULT] = "fail4"
        else
            streams[keyTable.KEY_SET_RESULT] = "none"
        end
    elseif (subDataType == 0xFE) then
        streams[keyTable.KEY_FUNCTION_TYPE] = "exception"
        streams[keyTable.KEY_PROPERTY_TYPE] = "error"
        streams[keyTable.KEY_ERROR_CODE] = proTable.error_code
        streams["cooking_settings"] = {}
        streams["cooking_settings"][keyTable.KEY_RECIPE_CODE] =
            proTable.recipe_code
        streams["cooking_settings"][keyTable.KEY_RICE_BRAND] =
            proTable.rice_brand
        streams["cooking_settings"][keyTable.KEY_COOKING_TIME] =
            proTable.cooking_time
        streams["cooking_settings"][keyTable.KEY_COOKING_METHOD] =
            proTable.cooking_method
        streams["cooking_settings"][keyTable.KEY_COOKING_TEMPERATURE] =
            proTable.cooking_temperature
        streams["cooking_settings"][keyTable.KEY_RICE_HARDNESS] =
            proTable.rice_hardness
        streams["cooking_settings"][keyTable.KEY_WATER_HARDNESS_SELECT] =
            proTable.water_hardness_select
        streams["cooking_settings"][keyTable.KEY_WATER_HARDNESS_VAL] =
            proTable.water_hardness_val
        streams["cooking_settings"][keyTable.KEY_SOAK_TIME] = proTable.soak_time
        streams["cooking_settings"][keyTable.KEY_PUMP_TIME_CORRECTION1] =
            proTable.pump_time_correction1
        streams["cooking_settings"][keyTable.KEY_PUMP_TIME_CORRECTION2] =
            proTable.pump_time_correction2
        streams["cooking_settings"][keyTable.KEY_PROCESS_TIME_CORRECTION1] =
            proTable.process_time_correction1
        streams["cooking_settings"][keyTable.KEY_PROCESS_TIME_CORRECTION2] =
            proTable.process_time_correction2
        streams["cooking_settings"][keyTable.KEY_ADDITIONAL_CORRECTION1] =
            proTable.additional_correction1
        streams["cooking_settings"][keyTable.KEY_ADDITIONAL_CORRECTION2] =
            proTable.additional_correction2
        streams["cooking_settings"][keyTable.KEY_COOKING_END_TIME_H] =
            proTable.cooking_end_time_h
        streams["cooking_settings"][keyTable.KEY_COOKING_END_TIME_M] =
            proTable.cooking_end_time_m
        streams["cooking_settings"][keyTable.KEY_COOKING_COURSE] =
            proTable.cooking_course
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
        updateGlobalPropertyValueByJson(control)
        local bodyBytes = {}
        local bodyLength = 32
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
        bodyBytes[0] = 0x00
        bodyBytes[1] = proTable.set_mode
        bodyBytes[2] = bit.band(proTable.recipe_code, 0x00FF)
        bodyBytes[3] = bit.rshift(proTable.recipe_code, 8)
        bodyBytes[4] = bit.band(proTable.rice_brand, 0x00FF)
        bodyBytes[5] = bit.rshift(proTable.rice_brand, 8)
        if proTable.rice_brand == 0x0013 or proTable.rice_brand == 0x0014 then
            bodyBytes[6] = proTable.cooking_time
        else
            bodyBytes[6] = proTable.cooking_method
        end
        if proTable.rice_brand == 0x0013 or proTable.rice_brand == 0x0014 then
            bodyBytes[7] = proTable.cooking_temperature
        else
            bodyBytes[7] = proTable.rice_hardness
        end
        if proTable.water_hardness_select == 0x01 then
            bodyBytes[8] = 0x7F + bit.lshift(proTable.water_hardness_select, 7)
            bodyBytes[9] = proTable.water_hardness_val
        else
            bodyBytes[8] = proTable.water_hardness_val +
                               bit.lshift(proTable.water_hardness_select, 7)
            bodyBytes[9] = 0xFF
        end
        bodyBytes[10] = proTable.soak_time
        bodyBytes[11] = proTable.pump_time_correction1 +
                            bit.lshift(proTable.pump_time_correction2, 4)
        bodyBytes[12] = proTable.process_time_correction1 +
                            bit.lshift(proTable.process_time_correction2, 4)
        bodyBytes[13] = proTable.additional_correction1 +
                            bit.lshift(proTable.additional_correction2, 4)
        bodyBytes[14] = proTable.cooking_end_time_m
        bodyBytes[15] = proTable.cooking_end_time_h
        bodyBytes[16] = proTable.cooking_course
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
    dataType = bit.lshift(byteData[15], 8) + byteData[16]
    subDataType = byteData[17]
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end
