local JSON = require "cjson"
local KEY_VERSION = "version"
local KEY_FUNCTION_TYPE = "function_type"
local KEY_POWER_SAVING = "power_saving"
local KEY_POWER_SAVING_OUT = "power_saving_out"
local KEY_POWER_LOW_TEMP = "power_low_temp"
local KEY_VEGETABLE_STERILIZATION = "vegetable_sterilization"
local KEY_POWER_SAVING_AUTO = "power_saving_auto"
local KEY_COOLING = "cooling"
local KEY_CHILLING_ROOM_TEMP = "chilling_room_temp"
local KEY_FREEZING_ROOM_TEMP = "freezing_room_temp"
local KEY_ICE_MAKING = "ice_making"
local KEY_ICE_MAKING_STATUS = "ice_making_status"
local KEY_LOCK = "lock"
local KEY_ECO = "eco"
local KEY_AUTO_OPEN_DOOR = "auto_open_door"
local KEY_DEMO_MODE = "demo_mode"
local KEY_FORCE_DEFROST = "force_defrost"
local KEY_DEFROST_STATUS_MOISTURE = "defrost_status_moisture"
local KEY_DEFROST_STATUS_PRECOOL = "defrost_status_precool"
local KEY_DEFROST_STATUS_DEFROST = "defrost_status_defrost"
local KEY_INSTANTANEOUS_POWER = "instantaneous_power"
local KEY_DAILY_ENERGY = "daily_energy"
local KEY_COMPLETION_NOTICE_ONE = "completion_notice_one"
local KEY_ERROR_CODE = "error_code"
local KEY_CAMERA_SHOOTING = "camera_shooting"
local KEY_TIME_YEAR = "time_year"
local KEY_TIME_MONTH = "time_month"
local KEY_TIME_DAY = "time_day"
local KEY_TIME_HOUR = "time_hour"
local KEY_TIME_MIN = "time_min"
local BYTE_PROTOCOL_LENGTH = 0x10
local dataType = 0x00
local propertyTable = {}
propertyTable["powerSaving"] = 0
propertyTable["powerSavingOut"] = 0
propertyTable["powerLowTemp"] = 0
propertyTable["vegetableSterilization"] = 0
propertyTable["powerSavingAuto"] = 0
propertyTable["cooling"] = 0
propertyTable["chillingRoomTemp"] = 0
propertyTable["freezingRoomTemp"] = 0
propertyTable["iceMaking"] = 0
propertyTable["iceMakingStatus"] = 0
propertyTable["lock"] = 0
propertyTable["eco"] = 0
propertyTable["autoOpenDoor"] = 0
propertyTable["demoMode"] = 0
propertyTable["forceDefrost"] = 0
propertyTable["defrostStatus"] = 0
propertyTable["chillingDoorStatus"] = 0
propertyTable["freezingDoorStatus"] = 0
propertyTable["iceDoorStatus"] = 0
propertyTable["instantaneousPower"] = 0
propertyTable["dailyEnergy"] = 0
propertyTable["completionNoticeOne"] = 0
propertyTable["notice"] = 0
propertyTable["errorCode"] = 0
propertyTable["functionType"] = 0
propertyTable["cameraShooting"] = 0
propertyTable["timeYear"] = 0
propertyTable["timeMonth"] = 0
propertyTable["timeDay"] = 0
propertyTable["timeHour"] = 0
propertyTable["timeMin"] = 0
propertyTable["errorMin"] = 0
propertyTable["errorHour"] = 0
propertyTable["errorDay"] = 0
propertyTable["errorMonth"] = 0
propertyTable["errorTimes"] = 0
propertyTable["firmwareVersion"] = ""
propertyTable["firmwareLog"] = ""
propertyTable["vegetableDoorStatus"] = 0
propertyTable["freezingUpStatus"] = 0
propertyTable["freezingDownStatus"] = 0
propertyTable["chillingRoomTempThan12"] = 0
propertyTable["freezingRoomTempThan10"] = 0
propertyTable["rt_sensor"] = 0
propertyTable["r_sensor"] = 0
propertyTable["rd_sensor"] = 0
propertyTable["rd2_sensor"] = 0
propertyTable["f_sensor"] = 0
propertyTable["fd_sensor"] = 0
propertyTable["i_sensor"] = 0
propertyTable["rh_sensor"] = 0
propertyTable["comp_frequency"] = 0
propertyTable["r_fan_frequency"] = 0
propertyTable["r2_fan_frequency"] = 0
propertyTable["f_fan_frequency"] = 0
propertyTable["c_fan_frequency"] = 0
propertyTable["three_way_valve_pulse"] = 0
propertyTable["has_data_one_hour"] = 0
propertyTable["has_data_two_hours"] = 0
propertyTable["status_current"] = 0
propertyTable["status_one_hour"] = 0
propertyTable["status_two_hours"] = 0
propertyTable["r_avarage"] = 0
propertyTable["r_avarage_one_hour"] = 0
propertyTable["r_avarage_two_hours"] = 0
propertyTable["f_avarage"] = 0
propertyTable["f_avarage_one_hour"] = 0
propertyTable["f_avarage_two_hours"] = 0
propertyTable["pulldown_current"] = 0
propertyTable["pulldown_one_hour"] = 0
propertyTable["pulldown_two_hours"] = 0
propertyTable["defrost_current"] = 0
propertyTable["defrost_one_hour"] = 0
propertyTable["defrost_two_hours"] = 0
propertyTable["auto_status_set"] = 0
local function buma(ym)
    if bit.band(ym, 0x8000) == 0x8000 then
        local tmp = bit.band(bit.bnot(ym) + 1, 0xffff);
        return -tmp;
    else
        return ym;
    end
end
local function crc16_ccitt(tmpbuf, start_pos, end_pos)
    local crc = 0;
    for si = start_pos, end_pos do
        local i = 0
        crc = bit.bxor(crc, bit.lshift(tmpbuf[si], 8))
        for i = 0, 7 do
            if bit.band(crc, 0x8000) == 0x8000 then
                crc = bit.bxor(bit.lshift(crc, 1), 0x1021);
            else
                crc = bit.lshift(crc, 1)
            end
        end
    end
    return crc;
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
    msgBytes[7] = 0xCA
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
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    resVal = 255 - resVal + 1
    return resVal
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
local function hexToSignedInt(msb, lsb)
    if (not lsb) then lsb = 0 end
    if (not msb) then msb = 0 end
    local num = bit.lshift(msb, 8) + lsb
    if (bit.band(msb, 0x80) == 0x80) then
        num = -bit.bnot(bit.bor(num - 1, 0xffff0000))
    end
    return num
end
local function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_FUNCTION_TYPE] == "base" then
        propertyTable["functionType"] = 0x00
    elseif luaTable[KEY_FUNCTION_TYPE] == "time" then
        propertyTable["functionType"] = 0x01
    elseif luaTable[KEY_FUNCTION_TYPE] == "camera" then
        propertyTable["functionType"] = 0x02
    elseif luaTable[KEY_FUNCTION_TYPE] == "auto_power_saving_set" then
        propertyTable["functionType"] = 0x06
    end
    if luaTable[KEY_TIME_YEAR] ~= nil then
        propertyTable["timeYear"] = string2Int(luaTable[KEY_TIME_YEAR])
    end
    if luaTable[KEY_TIME_MONTH] ~= nil then
        propertyTable["timeMonth"] = string2Int(luaTable[KEY_TIME_MONTH])
    end
    if luaTable[KEY_TIME_DAY] ~= nil then
        propertyTable["timeDay"] = string2Int(luaTable[KEY_TIME_DAY])
    end
    if luaTable[KEY_TIME_HOUR] ~= nil then
        propertyTable["timeHour"] = string2Int(luaTable[KEY_TIME_HOUR])
    end
    if luaTable[KEY_TIME_MIN] ~= nil then
        propertyTable["timeMin"] = string2Int(luaTable[KEY_TIME_MIN])
    end
    if luaTable[KEY_CAMERA_SHOOTING] == "on" then
        propertyTable["cameraShooting"] = 0x01
    elseif luaTable[KEY_CAMERA_SHOOTING] == "off" then
        propertyTable["cameraShooting"] = 0x00
    end
    if luaTable[KEY_POWER_SAVING] == "on" then
        propertyTable["powerSaving"] = 0x01
    elseif luaTable[KEY_POWER_SAVING] == "off" then
        propertyTable["powerSaving"] = 0x00
    else
        propertyTable["powerSaving"] = 0xFF
    end
    if luaTable[KEY_POWER_SAVING_OUT] == "on" then
        propertyTable["powerSavingOut"] = 0x01
    elseif luaTable[KEY_POWER_SAVING_OUT] == "off" then
        propertyTable["powerSavingOut"] = 0x00
    else
        propertyTable["powerSavingOut"] = 0xFF
    end
    if luaTable[KEY_POWER_LOW_TEMP] == "on" then
        propertyTable["powerLowTemp"] = 0x01
    elseif luaTable[KEY_POWER_LOW_TEMP] == "off" then
        propertyTable["powerLowTemp"] = 0x00
    else
        propertyTable["powerLowTemp"] = 0xFF
    end
    if luaTable[KEY_VEGETABLE_STERILIZATION] == "on" then
        propertyTable["vegetableSterilization"] = 0x01
    elseif luaTable[KEY_VEGETABLE_STERILIZATION] == "off" then
        propertyTable["vegetableSterilization"] = 0x00
    else
        propertyTable["vegetableSterilization"] = 0xFF
    end
    if luaTable[KEY_POWER_SAVING_AUTO] == "on" then
        propertyTable["powerSavingAuto"] = 0x01
    elseif luaTable[KEY_POWER_SAVING_AUTO] == "off" then
        propertyTable["powerSavingAuto"] = 0x00
    else
        propertyTable["powerSavingAuto"] = 0xFF
    end
    if luaTable[KEY_COOLING] == "normal" then
        propertyTable["cooling"] = 0x00
    elseif luaTable[KEY_COOLING] == "quick_freezing" then
        propertyTable["cooling"] = 0x01
    elseif luaTable[KEY_COOLING] == "vegetables" then
        propertyTable["cooling"] = 0x02
    elseif luaTable[KEY_COOLING] == "vegetables_drying" then
        propertyTable["cooling"] = 0x03
    elseif luaTable[KEY_COOLING] == "chilled" then
        propertyTable["cooling"] = 0x04
    elseif luaTable[KEY_COOLING] == "thawing" then
        propertyTable["cooling"] = 0x05
    else
        propertyTable["cooling"] = 0xFF
    end
    if luaTable[KEY_CHILLING_ROOM_TEMP] ~= nil then
        propertyTable["chillingRoomTemp"] = string2Int(
                                                luaTable[KEY_CHILLING_ROOM_TEMP])
    else
        propertyTable["chillingRoomTemp"] = 0xff
    end
    if luaTable[KEY_FREEZING_ROOM_TEMP] ~= nil then
        propertyTable["freezingRoomTemp"] = string2Int(
                                                luaTable[KEY_FREEZING_ROOM_TEMP])
    else
        propertyTable["freezingRoomTemp"] = 0xff
    end
    if luaTable[KEY_ICE_MAKING] == "normal" then
        propertyTable["iceMaking"] = 0x00
    elseif luaTable[KEY_ICE_MAKING] == "quick" then
        propertyTable["iceMaking"] = 0x01
    elseif luaTable[KEY_ICE_MAKING] == "off" then
        propertyTable["iceMaking"] = 0x02
    else
        propertyTable["iceMaking"] = 0x0f
    end
    if luaTable[KEY_LOCK] == "on" then
        propertyTable["lock"] = 0x01
    elseif luaTable[KEY_LOCK] == "off" then
        propertyTable["lock"] = 0x00
    else
        propertyTable["lock"] = 0xFF
    end
    if luaTable[KEY_ECO] == "on" then
        propertyTable["eco"] = 0x01
    elseif luaTable[KEY_ECO] == "off" then
        propertyTable["eco"] = 0x00
    else
        propertyTable["eco"] = 0xFF
    end
    if luaTable[KEY_AUTO_OPEN_DOOR] == "on" then
        propertyTable["autoOpenDoor"] = 0x01
    elseif luaTable[KEY_AUTO_OPEN_DOOR] == "off" then
        propertyTable["autoOpenDoor"] = 0x00
    else
        propertyTable["autoOpenDoor"] = 0xFF
    end
    if luaTable[KEY_DEMO_MODE] == "on" then
        propertyTable["demoMode"] = 0x01
    elseif luaTable[KEY_DEMO_MODE] == "off" then
        propertyTable["demoMode"] = 0x00
    else
        propertyTable["demoMode"] = 0xFF
    end
    if luaTable[KEY_FORCE_DEFROST] == "on" then
        propertyTable["forceDefrost"] = 0x01
    elseif luaTable[KEY_FORCE_DEFROST] == "off" then
        propertyTable["forceDefrost"] = 0x00
    else
        propertyTable["forceDefrost"] = 0xFF
    end
    if luaTable[KEY_DEFROST_STATUS_MOISTURE] == "on" then
        propertyTable["defrostStatus"] = bit.band(
                                             propertyTable["defrostStatus"],
                                             0x01)
    else
        propertyTable["defrostStatus"] = bit.band(
                                             propertyTable["defrostStatus"],
                                             0xFE)
    end
    if luaTable[KEY_DEFROST_STATUS_PRECOOL] == "on" then
        propertyTable["defrostStatus"] = bit.band(
                                             propertyTable["defrostStatus"],
                                             0x02)
    else
        propertyTable["defrostStatus"] = bit.band(
                                             propertyTable["defrostStatus"],
                                             0xFD)
    end
    if luaTable[KEY_DEFROST_STATUS_DEFROST] == "on" then
        propertyTable["defrostStatus"] = bit.band(
                                             propertyTable["defrostStatus"],
                                             0x04)
    else
        propertyTable["defrostStatus"] = bit.band(
                                             propertyTable["defrostStatus"],
                                             0xFB)
    end
    if luaTable["chilling_door_status"] == "on" then
        propertyTable["chillingDoorStatus"] = 0x01
    else
        propertyTable["chillingDoorStatus"] = 0x00
    end
    if luaTable["freezing_door_status"] == "on" then
        propertyTable["freezingDoorStatus"] = 0x01
    else
        propertyTable["freezingDoorStatus"] = 0x00
    end
    if luaTable["ice_door_status"] == "on" then
        propertyTable["iceDoorStatus"] = 0x01
    else
        propertyTable["iceDoorStatus"] = 0x00
    end
    if luaTable["vegetable_door_status"] == "on" then
        propertyTable["vegetableDoorStatus"] = 0x01
    else
        propertyTable["vegetableDoorStatus"] = 0x00
    end
    if luaTable["auto_status_set"] == "normal" then
        propertyTable["auto_status_set"] = 0x00
    elseif luaTable["auto_status_set"] == "eco_auto" then
        propertyTable["auto_status_set"] = 0x01
    elseif luaTable["auto_status_set"] == "precool" then
        propertyTable["auto_status_set"] = 0x02
    else
        propertyTable["auto_status_set"] = 0xFF
    end
end
local function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == 0x02) then
        if messageBytes[0] == 0x00 then
            propertyTable["functionType"] = 0x00
            propertyTable["powerSaving"] = bit.band(messageBytes[1], 0x01)
            propertyTable["powerSavingOut"] =
                bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            propertyTable["powerLowTemp"] = bit.rshift(
                                                bit.band(messageBytes[1], 0x04),
                                                2)
            propertyTable["vegetableSterilization"] =
                bit.rshift(bit.band(messageBytes[1], 0x08), 3)
            propertyTable["powerSavingAuto"] =
                bit.rshift(bit.band(messageBytes[1], 0x010), 4)
            propertyTable["cooling"] = messageBytes[2]
            propertyTable["chillingRoomTemp"] = messageBytes[3]
            propertyTable["freezingRoomTemp"] = messageBytes[4]
            propertyTable["iceMaking"] = bit.band(messageBytes[5], 0x0f)
            propertyTable["iceMakingStatus"] =
                bit.rshift(bit.band(messageBytes[5], 0xf0), 4)
            propertyTable["lock"] = bit.band(messageBytes[6], 0x01)
            propertyTable["eco"] =
                bit.rshift(bit.band(messageBytes[6], 0x02), 1)
            propertyTable["autoOpenDoor"] = bit.rshift(
                                                bit.band(messageBytes[6], 0x04),
                                                2)
            propertyTable["demoMode"] = bit.rshift(
                                            bit.band(messageBytes[6], 0x08), 3)
            propertyTable["forceDefrost"] = bit.rshift(
                                                bit.band(messageBytes[6], 0x10),
                                                4)
            if messageBytes[13] ~= nil and messageBytes[14] ~= nil then
                if messageBytes[13] ~= 0xFF or messageBytes[14] ~= 0xFF then
                    propertyTable["errorCode"] =
                        bit.lshift(messageBytes[14], 8) + messageBytes[13]
                end
            end
            if messageBytes[15] ~= nil and messageBytes[16] ~= nil then
                propertyTable["outRoomTemp"] =
                    bit.lshift(messageBytes[16], 8) + messageBytes[15]
            else
                propertyTable["outRoomTemp"] = nil
            end
        end
        if messageBytes[0] == 0x01 then
            propertyTable["functionType"] = 0x01
            propertyTable["timeMin"] = messageBytes[1]
            propertyTable["timeHour"] = messageBytes[2]
            propertyTable["timeDay"] = messageBytes[3]
            propertyTable["timeMonth"] = messageBytes[4]
            propertyTable["timeYear"] = bit.lshift(messageBytes[6], 8) +
                                            messageBytes[5]
        end
        if messageBytes[0] == 0x02 then
            propertyTable["functionType"] = 0x02
            propertyTable["cameraShooting"] = bit.band(messageBytes[1], 0x01)
        end
        if messageBytes[0] == 0x06 then
            propertyTable["functionType"] = 0x06
            propertyTable["auto_status_set"] = messageBytes[1]
        end
    end
    if (dataType == 0x03) then
        if messageBytes[0] == 0x00 then
            propertyTable["functionType"] = 0x00
            propertyTable["powerSaving"] = bit.band(messageBytes[1], 0x01)
            propertyTable["powerSavingOut"] =
                bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            propertyTable["powerLowTemp"] = bit.rshift(
                                                bit.band(messageBytes[1], 0x04),
                                                2)
            propertyTable["vegetableSterilization"] =
                bit.rshift(bit.band(messageBytes[1], 0x08), 3)
            propertyTable["powerSavingAuto"] =
                bit.rshift(bit.band(messageBytes[1], 0x010), 4)
            propertyTable["cooling"] = messageBytes[2]
            propertyTable["chillingRoomTemp"] = messageBytes[3]
            propertyTable["freezingRoomTemp"] = messageBytes[4]
            propertyTable["iceMaking"] = bit.band(messageBytes[5], 0x0f)
            propertyTable["iceMakingStatus"] =
                bit.rshift(bit.band(messageBytes[5], 0xf0), 4)
            propertyTable["lock"] = bit.band(messageBytes[6], 0x01)
            propertyTable["eco"] =
                bit.rshift(bit.band(messageBytes[6], 0x02), 1)
            propertyTable["autoOpenDoor"] = bit.rshift(
                                                bit.band(messageBytes[6], 0x04),
                                                2)
            propertyTable["demoMode"] = bit.rshift(
                                            bit.band(messageBytes[6], 0x08), 3)
            propertyTable["forceDefrost"] = bit.rshift(
                                                bit.band(messageBytes[6], 0x10),
                                                4)
            propertyTable["defrostStatus"] = messageBytes[7]
            propertyTable["chillingDoorStatus"] =
                bit.band(messageBytes[8], 0x01)
            propertyTable["freezingDoorStatus"] =
                bit.rshift(bit.band(messageBytes[8], 0x02), 1)
            propertyTable["iceDoorStatus"] =
                bit.rshift(bit.band(messageBytes[8], 0x04), 2)
            propertyTable["vegetableDoorStatus"] =
                bit.rshift(bit.band(messageBytes[8], 0x08), 3)
            propertyTable["instantaneousPower"] =
                bit.lshift(messageBytes[10], 8) + messageBytes[9]
            propertyTable["dailyEnergy"] =
                bit.lshift(messageBytes[12], 8) + messageBytes[11]
            if messageBytes[13] ~= nil and messageBytes[14] ~= nil then
                if messageBytes[13] ~= 0xFF or messageBytes[14] ~= 0xFF then
                    propertyTable["errorCode"] =
                        bit.lshift(messageBytes[14], 8) + messageBytes[13]
                end
            end
            if messageBytes[15] ~= nil and messageBytes[16] ~= nil then
                propertyTable["outRoomTemp"] =
                    bit.lshift(messageBytes[16], 8) + messageBytes[15]
            else
                propertyTable["outRoomTemp"] = nil
            end
        end
        if messageBytes[0] == 0x01 then
            propertyTable["functionType"] = 0x01
            propertyTable["timeMin"] = messageBytes[1]
            propertyTable["timeHour"] = messageBytes[2]
            propertyTable["timeDay"] = messageBytes[3]
            propertyTable["timeMonth"] = messageBytes[4]
            propertyTable["timeYear"] = bit.lshift(messageBytes[6], 8) +
                                            messageBytes[5]
        end
        if messageBytes[0] == 0x02 then
            propertyTable["functionType"] = 0x02
            propertyTable["cameraShooting"] = bit.band(messageBytes[1], 0x01)
        end
        if messageBytes[0] == 0xFE then
            propertyTable["functionType"] = 0xFE
            propertyTable["errorCode"] = messageBytes[2] * 256 + messageBytes[1]
            propertyTable["errorMin"] = messageBytes[3]
            propertyTable["errorHour"] = messageBytes[4]
            propertyTable["errorDay"] = messageBytes[5]
            propertyTable["errorMonth"] = messageBytes[6]
            propertyTable["errorTimes"] =
                bit.lshift(messageBytes[8], 8) + messageBytes[7]
            local fv = {}
            for i = 1, 7 do fv[i] = messageBytes[8 + i] end
            local fvstring = table2string(fv)
            local fvhexstring = string2hexstring(fvstring)
            propertyTable["firmwareVersion"] = fvhexstring
            local fl = {}
            for i = 1, 512 do fl[i] = messageBytes[15 + i] end
            local flstring = table2string(fl)
            local flhexstring = string2hexstring(flstring)
            propertyTable["firmwareLog"] = flhexstring
        end
        if messageBytes[0] == 0x21 then
            propertyTable["functionType"] = 0x21
            propertyTable["errorCode"] = messageBytes[2] * 256 + messageBytes[1]
            propertyTable["errorMin"] = messageBytes[3]
            propertyTable["errorHour"] = messageBytes[4]
            propertyTable["errorDay"] = messageBytes[5]
            propertyTable["errorMonth"] = messageBytes[6]
            propertyTable["errorTimes"] =
                bit.lshift(messageBytes[8], 8) + messageBytes[7]
            local fv = {}
            for i = 1, 7 do fv[i] = messageBytes[8 + i] end
            local fvstring = table2string(fv)
            local fvhexstring = string2hexstring(fvstring)
            propertyTable["firmwareVersion"] = fvhexstring
            local fl = {}
            for i = 1, 512 do fl[i] = messageBytes[15 + i] end
            local flstring = table2string(fl)
            local flhexstring = string2hexstring(flstring)
            propertyTable["firmwareLog"] = flhexstring
        end
        if messageBytes[0] == 0x22 then
            propertyTable["functionType"] = 0x22
            propertyTable["chillingDoorStatus"] =
                bit.band(messageBytes[1], 0x01)
            propertyTable["vegetableDoorStatus"] =
                bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            propertyTable["iceDoorStatus"] =
                bit.rshift(bit.band(messageBytes[1], 0x04), 2)
            propertyTable["freezingUpStatus"] =
                bit.rshift(bit.band(messageBytes[1], 0x08), 3)
            propertyTable["freezingDownStatus"] =
                bit.rshift(bit.band(messageBytes[1], 0x10), 4)
            propertyTable["chillingRoomTempThan12"] =
                bit.band(messageBytes[2], 0x01)
            propertyTable["freezingRoomTempThan10"] =
                bit.rshift(bit.band(messageBytes[2], 0x02), 1)
        end
        if messageBytes[0] == 0x03 then
            propertyTable["functionType"] = 0x03
            propertyTable["rt_sensor"] =
                bit.lshift(messageBytes[2], 8) + messageBytes[1]
            propertyTable["r_sensor"] = bit.lshift(messageBytes[4], 8) +
                                            messageBytes[3]
            propertyTable["rd_sensor"] =
                bit.lshift(messageBytes[6], 8) + messageBytes[5]
            propertyTable["rd2_sensor"] =
                bit.lshift(messageBytes[8], 8) + messageBytes[7]
            propertyTable["f_sensor"] = bit.lshift(messageBytes[10], 8) +
                                            messageBytes[9]
            propertyTable["fd_sensor"] =
                bit.lshift(messageBytes[12], 8) + messageBytes[11]
            propertyTable["i_sensor"] = bit.lshift(messageBytes[14], 8) +
                                            messageBytes[13]
            propertyTable["rh_sensor"] =
                bit.lshift(messageBytes[16], 8) + messageBytes[15]
            propertyTable["comp_frequency"] = messageBytes[17]
            propertyTable["r_fan_frequency"] = messageBytes[18]
            propertyTable["r2_fan_frequency"] = messageBytes[19]
            propertyTable["f_fan_frequency"] = messageBytes[20]
            propertyTable["c_fan_frequency"] = messageBytes[21]
            propertyTable["three_way_valve_pulse"] = messageBytes[22]
            if messageBytes[23] ~= nil and messageBytes[24] ~= nil then
                propertyTable["cSensor"] =
                    bit.lshift(messageBytes[24], 8) + messageBytes[23]
            end
        end
    end
    if (dataType == 0x04) then
        if messageBytes[0] == 0x00 then
            propertyTable["functionType"] = 0x00
            propertyTable["powerSaving"] = bit.band(messageBytes[1], 0x01)
            propertyTable["powerSavingOut"] =
                bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            propertyTable["powerLowTemp"] = bit.rshift(
                                                bit.band(messageBytes[1], 0x04),
                                                2)
            propertyTable["vegetableSterilization"] =
                bit.rshift(bit.band(messageBytes[1], 0x08), 3)
            propertyTable["powerSavingAuto"] =
                bit.rshift(bit.band(messageBytes[1], 0x010), 4)
            propertyTable["cooling"] = messageBytes[2]
            propertyTable["chillingRoomTemp"] = messageBytes[3]
            propertyTable["freezingRoomTemp"] = messageBytes[4]
            propertyTable["iceMaking"] = bit.band(messageBytes[5], 0x0f)
            propertyTable["iceMakingStatus"] =
                bit.rshift(bit.band(messageBytes[5], 0xf0), 4)
            propertyTable["lock"] = bit.band(messageBytes[6], 0x01)
            propertyTable["eco"] =
                bit.rshift(bit.band(messageBytes[6], 0x02), 1)
            propertyTable["autoOpenDoor"] = bit.rshift(
                                                bit.band(messageBytes[6], 0x04),
                                                2)
            propertyTable["demoMode"] = bit.rshift(
                                            bit.band(messageBytes[6], 0x08), 3)
            propertyTable["forceDefrost"] = bit.rshift(
                                                bit.band(messageBytes[6], 0x10),
                                                4)
            propertyTable["defrostStatus"] = messageBytes[7]
            propertyTable["chillingDoorStatus"] =
                bit.band(messageBytes[8], 0x01)
            propertyTable["freezingDoorStatus"] =
                bit.rshift(bit.band(messageBytes[8], 0x02), 1)
            propertyTable["iceDoorStatus"] =
                bit.rshift(bit.band(messageBytes[8], 0x04), 2)
            propertyTable["vegetableDoorStatus"] =
                bit.rshift(bit.band(messageBytes[8], 0x08), 3)
            propertyTable["instantaneousPower"] =
                bit.lshift(messageBytes[10], 8) + messageBytes[9]
            propertyTable["dailyEnergy"] =
                bit.lshift(messageBytes[12], 8) + messageBytes[11]
            if messageBytes[13] ~= 0xFF or messageBytes[14] ~= 0xFF then
                propertyTable["errorCode"] =
                    bit.lshift(messageBytes[14], 8) + messageBytes[13]
            end
            if messageBytes[15] ~= nil and messageBytes[16] ~= nil then
                propertyTable["outRoomTemp"] =
                    bit.lshift(messageBytes[16], 8) + messageBytes[15]
            else
                propertyTable["outRoomTemp"] = nil
            end
        end
        if messageBytes[0] == 0x22 then
            propertyTable["functionType"] = 0x22
            propertyTable["chillingDoorStatus"] =
                bit.band(messageBytes[1], 0x01)
            propertyTable["vegetableDoorStatus"] =
                bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            propertyTable["iceDoorStatus"] =
                bit.rshift(bit.band(messageBytes[1], 0x04), 2)
            propertyTable["freezingUpStatus"] =
                bit.rshift(bit.band(messageBytes[1], 0x08), 3)
            propertyTable["freezingDownStatus"] =
                bit.rshift(bit.band(messageBytes[1], 0x10), 4)
            propertyTable["chillingRoomTempThan12"] =
                bit.band(messageBytes[2], 0x01)
            propertyTable["freezingRoomTempThan10"] =
                bit.rshift(bit.band(messageBytes[2], 0x02), 1)
        end
        if messageBytes[0] == 0x03 then
            propertyTable["functionType"] = 0x03
            propertyTable["rt_sensor"] =
                bit.lshift(messageBytes[2], 8) + messageBytes[1]
            propertyTable["r_sensor"] = bit.lshift(messageBytes[4], 8) +
                                            messageBytes[3]
            propertyTable["rd_sensor"] =
                bit.lshift(messageBytes[6], 8) + messageBytes[5]
            propertyTable["rd2_sensor"] =
                bit.lshift(messageBytes[8], 8) + messageBytes[7]
            propertyTable["f_sensor"] = bit.lshift(messageBytes[10], 8) +
                                            messageBytes[9]
            propertyTable["fd_sensor"] =
                bit.lshift(messageBytes[12], 8) + messageBytes[11]
            propertyTable["i_sensor"] = bit.lshift(messageBytes[14], 8) +
                                            messageBytes[13]
            propertyTable["rh_sensor"] =
                bit.lshift(messageBytes[16], 8) + messageBytes[15]
            propertyTable["comp_frequency"] = messageBytes[17]
            propertyTable["r_fan_frequency"] = messageBytes[18]
            propertyTable["r2_fan_frequency"] = messageBytes[19]
            propertyTable["f_fan_frequency"] = messageBytes[20]
            propertyTable["c_fan_frequency"] = messageBytes[21]
            propertyTable["three_way_valve_pulse"] = messageBytes[22]
            if messageBytes[23] ~= nil and messageBytes[24] ~= nil then
                propertyTable["cSensor"] =
                    bit.lshift(messageBytes[24], 8) + messageBytes[23]
            end
        end
        if messageBytes[0] == 0x05 then
            propertyTable["functionType"] = 0x05
            propertyTable["has_data_one_hour"] = bit.band(messageBytes[1], 0x01)
            propertyTable["has_data_two_hours"] =
                bit.rshift(bit.band(messageBytes[1], 0x02), 1)
            propertyTable["status_current"] = messageBytes[2]
            propertyTable["status_one_hour"] = messageBytes[3]
            propertyTable["status_two_hours"] = messageBytes[4]
            propertyTable["r_avarage"] =
                hexToSignedInt(messageBytes[6], messageBytes[5])
            propertyTable["r_avarage_one_hour"] = hexToSignedInt(
                                                      messageBytes[8],
                                                      messageBytes[7])
            propertyTable["r_avarage_two_hours"] = hexToSignedInt(
                                                       messageBytes[10],
                                                       messageBytes[9])
            propertyTable["f_avarage"] =
                hexToSignedInt(messageBytes[12], messageBytes[11])
            propertyTable["f_avarage_one_hour"] = hexToSignedInt(
                                                      messageBytes[14],
                                                      messageBytes[13])
            propertyTable["f_avarage_two_hours"] = hexToSignedInt(
                                                       messageBytes[16],
                                                       messageBytes[15])
            propertyTable["pulldown_current"] = bit.band(messageBytes[17], 0x01)
            propertyTable["pulldown_one_hour"] =
                bit.rshift(bit.band(messageBytes[17], 0x02), 1)
            propertyTable["pulldown_two_hours"] =
                bit.rshift(bit.band(messageBytes[17], 0x04), 2)
            propertyTable["defrost_current"] =
                bit.rshift(bit.band(messageBytes[17], 0x08), 3)
            propertyTable["defrost_one_hour"] =
                bit.rshift(bit.band(messageBytes[17], 0x10), 4)
            propertyTable["defrost_two_hours"] =
                bit.rshift(bit.band(messageBytes[17], 0x20), 5)
        end
    end
    if (dataType == 0x05) then
        if messageBytes[0] == 0x20 then
            propertyTable["functionType"] = 0x20
            propertyTable["completionNoticeOne"] = messageBytes[1]
            propertyTable["notice"] = messageBytes[2]
        end
    end
    if (dataType == 0x0A) then
        if messageBytes[0] == 0xFE then
            propertyTable["functionType"] = 0xFE
            propertyTable["errorCode"] = messageBytes[2] * 256 + messageBytes[1]
            propertyTable["errorMin"] = messageBytes[3]
            propertyTable["errorHour"] = messageBytes[4]
            propertyTable["errorDay"] = messageBytes[5]
            propertyTable["errorMonth"] = messageBytes[6]
            propertyTable["errorTimes"] =
                bit.lshift(messageBytes[8], 8) + messageBytes[7]
            local fv = {}
            for i = 1, 7 do fv[i] = messageBytes[8 + i] end
            local fvstring = table2string(fv)
            local fvhexstring = string2hexstring(fvstring)
            propertyTable["firmwareVersion"] = fvhexstring
            local fl = {}
            for i = 1, 512 do fl[i] = messageBytes[15 + i] end
            local flstring = table2string(fl)
            local flhexstring = string2hexstring(flstring)
            propertyTable["firmwareLog"] = flhexstring
        end
        if messageBytes[0] == 0x21 then
            propertyTable["functionType"] = 0x21
            propertyTable["errorCode"] = messageBytes[2] * 256 + messageBytes[1]
            propertyTable["errorMin"] = messageBytes[3]
            propertyTable["errorHour"] = messageBytes[4]
            propertyTable["errorDay"] = messageBytes[5]
            propertyTable["errorMonth"] = messageBytes[6]
            propertyTable["errorTimes"] =
                bit.lshift(messageBytes[8], 8) + messageBytes[7]
            local fv = {}
            for i = 1, 7 do fv[i] = messageBytes[8 + i] end
            local fvstring = table2string(fv)
            local fvhexstring = string2hexstring(fvstring)
            propertyTable["firmwareVersion"] = fvhexstring
            local fl = {}
            for i = 1, 512 do fl[i] = messageBytes[15 + i] end
            local flstring = table2string(fl)
            local flhexstring = string2hexstring(flstring)
            propertyTable["firmwareLog"] = flhexstring
        end
    end
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = "21"
    if propertyTable["functionType"] == 0x00 then
        streams[KEY_FUNCTION_TYPE] = "base"
        if (propertyTable["powerSaving"] == 0x01) then
            streams[KEY_POWER_SAVING] = "on"
        elseif (propertyTable["powerSaving"] == 0x00) then
            streams[KEY_POWER_SAVING] = "off"
        end
        if (propertyTable["powerSavingOut"] == 0x01) then
            streams[KEY_POWER_SAVING_OUT] = "on"
        elseif (propertyTable["powerSavingOut"] == 0x00) then
            streams[KEY_POWER_SAVING_OUT] = "off"
        end
        if (propertyTable["powerLowTemp"] == 0x01) then
            streams[KEY_POWER_LOW_TEMP] = "on"
        elseif (propertyTable["powerLowTemp"] == 0x00) then
            streams[KEY_POWER_LOW_TEMP] = "off"
        end
        if (propertyTable["vegetableSterilization"] == 0x01) then
            streams[KEY_VEGETABLE_STERILIZATION] = "on"
        elseif (propertyTable["vegetableSterilization"] == 0x00) then
            streams[KEY_VEGETABLE_STERILIZATION] = "off"
        end
        if (propertyTable["powerSavingAuto"] == 0x01) then
            streams[KEY_POWER_SAVING_AUTO] = "on"
        elseif (propertyTable["powerSavingAuto"] == 0x00) then
            streams[KEY_POWER_SAVING_AUTO] = "off"
        end
        if (propertyTable["cooling"] == 0x00) then
            streams[KEY_COOLING] = "normal"
        elseif (propertyTable["cooling"] == 0x01) then
            streams[KEY_COOLING] = "quick_freezing"
        elseif (propertyTable["cooling"] == 0x02) then
            streams[KEY_COOLING] = "vegetables"
        elseif (propertyTable["cooling"] == 0x03) then
            streams[KEY_COOLING] = "vegetables_drying"
        elseif (propertyTable["cooling"] == 0x04) then
            streams[KEY_COOLING] = "chilled"
        elseif (propertyTable["cooling"] == 0x05) then
            streams[KEY_COOLING] = "thawing"
        else
            streams[KEY_COOLING] = "invalid"
        end
        streams[KEY_CHILLING_ROOM_TEMP] = int2String(
                                              propertyTable["chillingRoomTemp"])
        streams[KEY_FREEZING_ROOM_TEMP] = int2String(
                                              propertyTable["freezingRoomTemp"])
        if (propertyTable["iceMaking"] == 0x00) then
            streams[KEY_ICE_MAKING] = "normal"
        elseif (propertyTable["iceMaking"] == 0x01) then
            streams[KEY_ICE_MAKING] = "quick"
        elseif (propertyTable["iceMaking"] == 0x02) then
            streams[KEY_ICE_MAKING] = "off"
        else
            streams[KEY_ICE_MAKING] = "invalid"
        end
        if (propertyTable["iceMakingStatus"] == 0x00) then
            streams[KEY_ICE_MAKING_STATUS] = "running"
        elseif (propertyTable["iceMakingStatus"] == 0x01) then
            streams[KEY_ICE_MAKING_STATUS] = "water_shortage"
        elseif (propertyTable["iceMakingStatus"] == 0x02) then
            streams[KEY_ICE_MAKING_STATUS] = "ice_full"
        elseif (propertyTable["iceMakingStatus"] == 0x03) then
            streams[KEY_ICE_MAKING_STATUS] = "stop"
        end
        if propertyTable["lock"] == 0x01 then
            streams[KEY_LOCK] = "on"
        else
            streams[KEY_LOCK] = "off"
        end
        if propertyTable["eco"] == 0x01 then
            streams[KEY_ECO] = "on"
        else
            streams[KEY_ECO] = "off"
        end
        if propertyTable["autoOpenDoor"] == 0x01 then
            streams[KEY_AUTO_OPEN_DOOR] = "on"
        else
            streams[KEY_AUTO_OPEN_DOOR] = "off"
        end
        if propertyTable["demoMode"] == 0x01 then
            streams[KEY_DEMO_MODE] = "on"
        else
            streams[KEY_DEMO_MODE] = "off"
        end
        if propertyTable["forceDefrost"] == 0x01 then
            streams[KEY_FORCE_DEFROST] = "on"
        else
            streams[KEY_FORCE_DEFROST] = "off"
        end
        if bit.band(propertyTable["defrostStatus"], 0x01) == 0x01 then
            streams[KEY_DEFROST_STATUS_MOISTURE] = "on"
        else
            streams[KEY_DEFROST_STATUS_MOISTURE] = "off"
        end
        if bit.band(propertyTable["defrostStatus"], 0x02) == 0x02 then
            streams[KEY_DEFROST_STATUS_PRECOOL] = "on"
        else
            streams[KEY_DEFROST_STATUS_PRECOOL] = "off"
        end
        if bit.band(propertyTable["defrostStatus"], 0x04) == 0x04 then
            streams[KEY_DEFROST_STATUS_DEFROST] = "on"
        else
            streams[KEY_DEFROST_STATUS_DEFROST] = "off"
        end
        if propertyTable["chillingDoorStatus"] == 0x01 then
            streams["chilling_door_status"] = "on"
        else
            streams["chilling_door_status"] = "off"
        end
        if propertyTable["freezingDoorStatus"] == 0x01 then
            streams["freezing_door_status"] = "on"
        else
            streams["freezing_door_status"] = "off"
        end
        if propertyTable["iceDoorStatus"] == 0x01 then
            streams["ice_door_status"] = "on"
        else
            streams["ice_door_status"] = "off"
        end
        if propertyTable["vegetableDoorStatus"] == 0x01 then
            streams["vegetable_door_status"] = "on"
        else
            streams["vegetable_door_status"] = "off"
        end
        streams[KEY_INSTANTANEOUS_POWER] = int2String(
                                               propertyTable["instantaneousPower"])
        streams[KEY_DAILY_ENERGY] = int2String(propertyTable["dailyEnergy"])
        streams[KEY_ERROR_CODE] = int2String(propertyTable["errorCode"])
        if propertyTable["outRoomTemp"] ~= nil then
            streams["out_room_temp"] = int2String(buma(
                                                      propertyTable["outRoomTemp"]) /
                                                      10)
        end
    elseif propertyTable["functionType"] == 0x01 then
        streams[KEY_FUNCTION_TYPE] = "time"
        streams[KEY_TIME_YEAR] = int2String(propertyTable["timeYear"])
        streams[KEY_TIME_MONTH] = int2String(propertyTable["timeMonth"])
        streams[KEY_TIME_DAY] = int2String(propertyTable["timeDay"])
        streams[KEY_TIME_HOUR] = int2String(propertyTable["timeHour"])
        streams[KEY_TIME_MIN] = int2String(propertyTable["timeMin"])
    elseif propertyTable["functionType"] == 0x02 then
        streams[KEY_FUNCTION_TYPE] = "camera"
        streams[KEY_CAMERA_SHOOTING] = int2String(
                                           propertyTable["cameraShooting"])
    elseif propertyTable["functionType"] == 0x03 then
        streams["functionType"] = "running_info"
        streams["rt_sensor"] = buma(propertyTable["rt_sensor"]) / 10
        streams["r_sensor"] = buma(propertyTable["r_sensor"]) / 10
        streams["rd_sensor"] = buma(propertyTable["rd_sensor"]) / 10
        streams["rd2_sensor"] = buma(propertyTable["rd2_sensor"]) / 10
        streams["f_sensor"] = buma(propertyTable["f_sensor"]) / 10
        streams["fd_sensor"] = buma(propertyTable["fd_sensor"]) / 10
        streams["i_sensor"] = buma(propertyTable["i_sensor"]) / 10
        streams["rh_sensor"] = propertyTable["rh_sensor"] / 10
        streams["comp_frequency"] = propertyTable["comp_frequency"] * 0.6
        streams["r_fan_frequency"] = propertyTable["r_fan_frequency"] * 14.3
        streams["r2_fan_frequency"] = propertyTable["r2_fan_frequency"] * 14.3
        streams["f_fan_frequency"] = propertyTable["f_fan_frequency"] * 14.3
        streams["c_fan_frequency"] = propertyTable["c_fan_frequency"] * 14.3
        streams["three_way_valve_pulse"] =
            propertyTable["three_way_valve_pulse"]
        if propertyTable["cSensor"] ~= nil then
            streams["c_sensor"] = buma(propertyTable["cSensor"]) / 10
        end
    elseif propertyTable["functionType"] == 0x05 then
        streams[KEY_FUNCTION_TYPE] = "auto_power_saving_info"
        if propertyTable["has_data_one_hour"] == 0x01 then
            streams["has_data_one_hour"] = "on"
        else
            streams["has_data_one_hour"] = "off"
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            streams["has_data_two_hours"] = "on"
        else
            streams["has_data_two_hours"] = "off"
        end
        if propertyTable["status_current"] == 0x00 then
            streams["status_current"] = "normal"
        elseif propertyTable["status_current"] == 0x01 then
            streams["status_current"] = "eco_auto"
        elseif propertyTable["status_current"] == 0x02 then
            streams["status_current"] = "precool"
        elseif propertyTable["status_current"] == 0x03 then
            streams["status_current"] = "auto_saving_off"
        else
            streams["status_current"] = "invalid"
        end
        if propertyTable["has_data_one_hour"] == 0x01 then
            if propertyTable["status_one_hour"] == 0x00 then
                streams["status_one_hour"] = "normal"
            elseif propertyTable["status_one_hour"] == 0x01 then
                streams["status_one_hour"] = "eco_auto"
            elseif propertyTable["status_one_hour"] == 0x02 then
                streams["status_one_hour"] = "precool"
            elseif propertyTable["status_one_hour"] == 0x03 then
                streams["status_one_hour"] = "auto_saving_off"
            else
                streams["status_one_hour"] = "invalid"
            end
        else
            streams["status_one_hour"] = "invalid"
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            if propertyTable["status_two_hours"] == 0x00 then
                streams["status_two_hours"] = "normal"
            elseif propertyTable["status_two_hours"] == 0x01 then
                streams["status_two_hours"] = "eco_auto"
            elseif propertyTable["status_two_hours"] == 0x02 then
                streams["status_two_hours"] = "precool"
            elseif propertyTable["status_two_hours"] == 0x03 then
                streams["status_two_hours"] = "auto_saving_off"
            else
                streams["status_two_hours"] = "invalid"
            end
        else
            streams["status_two_hours"] = "invalid"
        end
        streams["r_avarage"] = int2String(propertyTable["r_avarage"])
        if propertyTable["has_data_one_hour"] == 0x01 then
            streams["r_avarage_one_hour"] = int2String(
                                                propertyTable["r_avarage_one_hour"])
        else
            streams["r_avarage_one_hour"] = int2String(0x7FFF)
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            streams["r_avarage_two_hours"] = int2String(
                                                 propertyTable["r_avarage_two_hours"])
        else
            streams["r_avarage_two_hours"] = int2String(0x7FFF)
        end
        streams["f_avarage"] = int2String(propertyTable["f_avarage"])
        if propertyTable["has_data_one_hour"] == 0x01 then
            streams["f_avarage_one_hour"] = int2String(
                                                propertyTable["f_avarage_one_hour"])
        else
            streams["f_avarage_one_hour"] = int2String(0x7FFF)
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            streams["f_avarage_two_hours"] = int2String(
                                                 propertyTable["f_avarage_two_hours"])
        else
            streams["f_avarage_two_hours"] = int2String(0x7FFF)
        end
        if propertyTable["pulldown_current"] == 0x01 then
            streams["pulldown_current"] = "on"
        else
            streams["pulldown_current"] = "off"
        end
        if propertyTable["has_data_one_hour"] == 0x01 then
            if propertyTable["pulldown_one_hour"] == 0x01 then
                streams["pulldown_one_hour"] = "on"
            else
                streams["pulldown_one_hour"] = "off"
            end
        else
            streams["pulldown_one_hour"] = "invalid"
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            if propertyTable["pulldown_two_hours"] == 0x01 then
                streams["pulldown_two_hours"] = "on"
            else
                streams["pulldown_two_hours"] = "off"
            end
        else
            streams["pulldown_two_hours"] = "invalid"
        end
        if propertyTable["defrost_current"] == 0x01 then
            streams["defrost_current"] = "on"
        else
            streams["defrost_current"] = "off"
        end
        if propertyTable["has_data_one_hour"] == 0x01 then
            if propertyTable["defrost_one_hour"] == 0x01 then
                streams["defrost_one_hour"] = "on"
            else
                streams["defrost_one_hour"] = "off"
            end
        else
            streams["defrost_one_hour"] = "invalid"
        end
        if propertyTable["has_data_two_hours"] == 0x01 then
            if propertyTable["defrost_two_hours"] == 0x01 then
                streams["defrost_two_hours"] = "on"
            else
                streams["defrost_two_hours"] = "off"
            end
        else
            streams["defrost_two_hours"] = "invalid"
        end
    elseif propertyTable["functionType"] == 0x06 then
        if propertyTable["auto_status_set"] == 0x00 then
            streams["auto_status_set"] = "normal"
        elseif propertyTable["auto_status_set"] == 0x01 then
            streams["auto_status_set"] = "eco_auto"
        elseif propertyTable["auto_status_set"] == 0x02 then
            streams["auto_status_set"] = "precool"
        else
            streams["auto_status_set"] = "invalid"
        end
    elseif propertyTable["functionType"] == 0x21 then
        streams[KEY_FUNCTION_TYPE] = "periodic"
        streams[KEY_ERROR_CODE] = int2String(propertyTable["errorCode"])
        streams["error_min"] = int2String(propertyTable["errorMin"])
        streams["error_hour"] = int2String(propertyTable["errorHour"])
        streams["error_day"] = int2String(propertyTable["errorDay"])
        streams["error_month"] = int2String(propertyTable["errorMonth"])
        streams["error_times"] = int2String(propertyTable["errorTimes"])
        streams["firmware_version"] = propertyTable["firmwareVersion"]
        streams["firmware_log"] = propertyTable["firmwareLog"]
    elseif propertyTable["functionType"] == 0x20 then
        streams[KEY_FUNCTION_TYPE] = "complete_notice"
        if (bit.band(propertyTable["completionNoticeOne"], 0x80) == 0x80) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "ice_making_normal"
        elseif (bit.band(propertyTable["notice"], 0x01) == 0x01) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "out_of_water"
        elseif (bit.band(propertyTable["completionNoticeOne"], 0x01) == 0x01) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "quick_freezing"
        elseif (bit.band(propertyTable["completionNoticeOne"], 0x02) == 0x02) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "vegetables"
        elseif (bit.band(propertyTable["completionNoticeOne"], 0x04) == 0x04) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "vegetables_drying"
        elseif (bit.band(propertyTable["completionNoticeOne"], 0x08) == 0x08) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "hot_things"
        elseif (bit.band(propertyTable["completionNoticeOne"], 0x10) == 0x10) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "thawing"
        elseif (bit.band(propertyTable["completionNoticeOne"], 0x20) == 0x20) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "thawing_thirty"
        elseif (bit.band(propertyTable["completionNoticeOne"], 0x40) == 0x40) then
            streams[KEY_COMPLETION_NOTICE_ONE] = "ice_making"
        else
            streams[KEY_COMPLETION_NOTICE_ONE] = "invalid"
        end
    elseif propertyTable["functionType"] == 0xFE then
        streams[KEY_FUNCTION_TYPE] = "exception"
        streams[KEY_ERROR_CODE] = int2String(propertyTable["errorCode"])
        streams["error_min"] = int2String(propertyTable["errorMin"])
        streams["error_hour"] = int2String(propertyTable["errorHour"])
        streams["error_day"] = int2String(propertyTable["errorDay"])
        streams["error_month"] = int2String(propertyTable["errorMonth"])
        streams["error_times"] = int2String(propertyTable["errorTimes"])
        streams["firmware_version"] = propertyTable["firmwareVersion"]
        streams["firmware_log"] = propertyTable["firmwareLog"]
    elseif propertyTable["functionType"] == 0x22 then
        streams[KEY_FUNCTION_TYPE] = "door_info"
        if propertyTable["chillingDoorStatus"] == 0x01 then
            streams["chilling_door_status"] = "on"
        else
            streams["chilling_door_status"] = "off"
        end
        if propertyTable["vegetableDoorStatus"] == 0x01 then
            streams["vegetable_door_status"] = "on"
        else
            streams["vegetable_door_status"] = "off"
        end
        if propertyTable["iceDoorStatus"] == 0x01 then
            streams["ice_door_status"] = "on"
        else
            streams["ice_door_status"] = "off"
        end
        if propertyTable["freezingUpStatus"] == 0x01 then
            streams["freezing_up_door_status"] = "on"
        else
            streams["freezing_up_door_status"] = "off"
        end
        if propertyTable["freezingDownStatus"] == 0x01 then
            streams["freezing_down_door_status"] = "on"
        else
            streams["freezing_down_door_status"] = "off"
        end
        streams["chilling_room_temp12"] = int2String(
                                              propertyTable["chillingRoomTempThan12"])
        streams["freezing_room_temp10"] = int2String(
                                              propertyTable["freezingRoomTempThan10"])
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
        if (status) then end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyBytes = {}
        if propertyTable["functionType"] == 0x00 then
            local bodyLength = 13
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
            bodyBytes[0] = 0x00
            local data1 = 0;
            if propertyTable["powerSavingOut"] == 0xFF and
                propertyTable["powerSaving"] == 0xFF and
                propertyTable["powerLowTemp"] == 0xFF and
                propertyTable["vegetableSterilization"] == 0xFF and
                propertyTable["powerSavingAuto"] == 0xFF then
                data1 = 0xFF
            else
                if propertyTable["powerSavingAuto"] ~= 0xFF then
                    data1 = bit.bor(data1, bit.lshift(
                                        propertyTable["powerSavingAuto"], 4))
                end
                if propertyTable["vegetableSterilization"] ~= 0xFF then
                    data1 = bit.bor(data1, bit.lshift(
                                        propertyTable["vegetableSterilization"],
                                        3))
                end
                if propertyTable["powerLowTemp"] ~= 0xFF then
                    data1 = bit.bor(data1, bit.lshift(
                                        propertyTable["powerLowTemp"], 2))
                end
                if propertyTable["powerSavingOut"] ~= 0xFF then
                    data1 = bit.bor(data1, bit.lshift(
                                        propertyTable["powerSavingOut"], 1))
                end
                if propertyTable["powerSaving"] ~= 0xFF then
                    data1 = bit.bor(data1, propertyTable["powerSaving"])
                end
            end
            bodyBytes[1] = data1;
            bodyBytes[2] = propertyTable["cooling"]
            bodyBytes[3] = propertyTable["chillingRoomTemp"]
            bodyBytes[4] = propertyTable["freezingRoomTemp"]
            bodyBytes[5] = propertyTable["iceMaking"]
            local data6 = 0;
            if (propertyTable["lock"] == 0xFF) and
                (propertyTable["eco"] == 0xFF) and
                (propertyTable["autoOpenDoor"] == 0xFF) and
                (propertyTable["demoMode"] == 0xFF) and
                (propertyTable["forceDefrost"] == 0xFF) then
                data6 = 0xFF
            else
                if propertyTable["lock"] ~= 0xFF then
                    data6 = bit.bor(bit.lshift(propertyTable["lock"], 0), data6)
                end
                if propertyTable["eco"] ~= 0xFF then
                    data6 = bit.bor(bit.lshift(propertyTable["eco"], 1), data6)
                end
                if propertyTable["autoOpenDoor"] ~= 0xFF then
                    data6 = bit.bor(
                                bit.lshift(propertyTable["autoOpenDoor"], 2),
                                data6)
                end
                if propertyTable["demoMode"] ~= 0xFF then
                    data6 = bit.bor(bit.lshift(propertyTable["demoMode"], 3),
                                    data6)
                end
                if propertyTable["forceDefrost"] ~= 0xFF then
                    data6 = bit.bor(
                                bit.lshift(propertyTable["forceDefrost"], 4),
                                data6)
                end
            end
            bodyBytes[6] = data6
        end
        if propertyTable["functionType"] == 0x01 then
            bodyBytes[0] = 0x01
            bodyBytes[1] = propertyTable["timeMin"]
            bodyBytes[2] = propertyTable["timeHour"]
            bodyBytes[3] = propertyTable["timeDay"]
            bodyBytes[4] = propertyTable["timeMonth"]
            bodyBytes[5] = bit.band(propertyTable["timeYear"], 0xff)
            bodyBytes[6] = bit.band(bit.rshift(propertyTable["timeYear"], 8),
                                    0xff)
        end
        if propertyTable["functionType"] == 0x02 then
            bodyBytes[0] = 0x02
            bodyBytes[1] = propertyTable["cameraShooting"]
        end
        if propertyTable["functionType"] == 0x06 then
            bodyBytes[0] = 0x06
            bodyBytes[1] = propertyTable["auto_status_set"]
        end
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
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local status = json["status"]
    if (status) then end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[15];
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end
