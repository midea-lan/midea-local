local bit = require "bit"
local JSON = require "cjson"
local BYTE_DEVICE_TYPE = 0x13
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local VALUE_UNKNOWN = "unknown"
local VALUE_INVALID = "invalid"
local dataType = 0
local cmdType = 0
local keytable = {}
keytable["KEY_VERSION"] = "version"
keytable["KEY_TOGGLE_POWER"] = "toggle_power"
keytable["KEY_POWER"] = "power"
keytable["KEY_SCENE_LIGHT"] = "scene_light"
keytable["KEY_COLOR_TEMPERATURE"] = "color_temperature"
keytable["KEY_BRIGHTNESS"] = "brightness"
keytable["KEY_DELAY_LIGHT_OFF"] = "delay_light_off"
keytable["KEY_LIFE_COLOR_TEMPERATURE"] = "life_color_temperature"
keytable["KEY_LIFE_BRIGHTNESS"] = "life_brightness"
keytable["KEY_READ_COLOR_TEMPERATURE"] = "read_color_temperature"
keytable["KEY_READ_BRIGHTNESS"] = "read_brightness"
keytable["KEY_MILD_COLOR_TEMPERATURE"] = "mild_color_temperature"
keytable["KEY_MILD_BRIGHTNESS"] = "mild_brightness"
keytable["KEY_FILM_COLOR_TEMPERATURE"] = "film_color_temperature"
keytable["KEY_FILM_BRIGHTNESS"] = "film_brightness"
keytable["KEY_NIGHT_COLOR_TEMPERATURE"] = "night_color_temperature"
keytable["KEY_NIGHT_BRIGHTNESS"] = "night_brightness"
keytable["KEY_BLUETOOTH_SCENE"] = "bluetooth_scene"
keytable["KEY_SUNSET_EN"] = "en_sunset_model"
keytable["KEY_SUNSET_HOUR"] = "sunset_model_hour"
keytable["KEY_SUNSET_MINUTE"] = "sunset_model_minute"
keytable["KEY_SUNSET_IS_RUN"] = "sunset_is_run"
keytable["KEY_SUNUP_EN"] = "en_sunup_model"
keytable["KEY_SUNUP_HOUR"] = "sunup_model_hour"
keytable["KEY_SUNUP_MINUTE"] = "sunup_model_minute"
keytable["KEY_SUNUP_IS_RUN"] = "sunup_is_run"
keytable["KEY_LINKAGEMODEL"] = "link_age_model"
keytable["KEY_DIM_SPEED"] = "dim_speed"
keytable["KEY_RED_VALUE"] = "red_value"
keytable["KEY_GREEN_VALUE"] = "green_value"
keytable["KEY_BLUE_VALUE"] = "blue_value"
keytable["KEY_COLOR_TEMPERATURE_MIN"] = "temperature_min"
keytable["KEY_COLOR_TEMPERATURE_MAX"] = "temperature_max"
keytable["KEY_RESULT"] = "result"
local valuetable = {}
valuetable["DIMSPEED"] = 2
local valresult = 0
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
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    resVal = 255 - resVal + 1
    if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
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
local function valueTableInitialization()
    valuetable["TOGGLELEDPOWER"] = 1
    valuetable["LEDPOWER"] = 1
    valuetable["SCENEMODEL"] = 1
    valuetable["COLORTEMPERATURE"] = 0
    valuetable["BRIGHTNESSVAL"] = 125
    valuetable["DELAYLIGHTOFF"] = 0
    valuetable["LIFECOLORTEMPERATURE"] = 0
    valuetable["LIFEBRINGHTNESS"] = 125
    valuetable["READCOLORTEMPERATURE"] = 0
    valuetable["READBRINGHTNESS"] = 125
    valuetable["MILDCOLORTEMPERATURE"] = 0
    valuetable["MILDBRINGHTNESS"] = 125
    valuetable["FILMCOLORTEMPERATURE"] = 0
    valuetable["FILMBRINGHTNESS"] = 125
    valuetable["NIGHTCOLORTEMPERATURE"] = 0
    valuetable["NIGHTBRINGHTNESS"] = 30
    valuetable["SUNSETISRUN"] = 0
    valuetable["SUNSETEN"] = 0
    valuetable["SUNSETHOUR"] = 18
    valuetable["SUNSETMINUTE"] = 0
    valuetable["SUNUPISRUN"] = 0
    valuetable["SUNUPEN"] = 0
    valuetable["SUNUPHOUR"] = 6
    valuetable["SUNUPMINUTE"] = 0
    valuetable["LINKAGEMODEL"] = 1
    valuetable["DIMSPEED"] = 2
    valuetable["RED_VALUE"] = 125
    valuetable["GREEN_VALUE"] = 125
    valuetable["BLUE_VALUE"] = 125
    valuetable["bluetooth_scene_value"] = 1
    valuetable["COLORTEMPERATURE_MAX"] = 5700
    valuetable["COLORTEMPERATURE_MIN"] = 3000
    valuetable["MACHINETYPE"] = 5
end
local function updateGlobalPropertyValueByJson(luaTable)
    valueTableInitialization()
    if luaTable[keytable["KEY_TOGGLE_POWER"]] == "1" then
        valuetable["TOGGLELEDPOWER"] = 0x01
    end
    if luaTable[keytable["KEY_POWER"]] == "on" then
        valuetable["LEDPOWER"] = 0x01
    else
        valuetable["LEDPOWER"] = 0x00
    end
    if luaTable[keytable["KEY_SCENE_LIGHT"]] == "manual" then
        valuetable["SCENEMODEL"] = 0x01
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "life" then
        valuetable["SCENEMODEL"] = 0x02
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "read" then
        valuetable["SCENEMODEL"] = 0x03
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "mild" then
        valuetable["SCENEMODEL"] = 0x04
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "film" then
        valuetable["SCENEMODEL"] = 0x05
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "moon" then
        valuetable["SCENEMODEL"] = 0x06
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "breath" then
        valuetable["SCENEMODEL"] = 0x07
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "ambiglow" then
        valuetable["SCENEMODEL"] = 0x08
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "sleep" then
        valuetable["SCENEMODEL"] = 0x09
    elseif luaTable[keytable["KEY_SCENE_LIGHT"]] == "wakeup" then
        valuetable["SCENEMODEL"] = 0x0a
    end
    if luaTable[keytable["KEY_COLOR_TEMPERATURE"]] ~= nil then
        valuetable["COLORTEMPERATURE"] = string2Int(
                                             luaTable[keytable["KEY_COLOR_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_BRIGHTNESS"]] ~= nil then
        valuetable["BRIGHTNESSVAL"] = string2Int(
                                          luaTable[keytable["KEY_BRIGHTNESS"]])
        print("BRIGHTNESSVAL:" .. valuetable["BRIGHTNESSVAL"])
    end
    if luaTable[keytable["KEY_DELAY_LIGHT_OFF"]] ~= nil then
        valuetable["DELAYLIGHTOFF"] = string2Int(
                                          luaTable[keytable["KEY_DELAY_LIGHT_OFF"]])
    end
    if luaTable[keytable["KEY_LIFE_COLOR_TEMPERATURE"]] ~= nil then
        valuetable["LIFECOLORTEMPERATURE"] = string2Int(
                                                 luaTable[keytable["KEY_LIFE_COLOR_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_LIFE_BRIGHTNESS"]] ~= nil then
        valuetable["LIFEBRINGHTNESS"] = string2Int(
                                            luaTable[keytable["KEY_LIFE_BRIGHTNESS"]])
    end
    if luaTable[keytable["KEY_READ_COLOR_TEMPERATURE"]] ~= nil then
        valuetable["READCOLORTEMPERATURE"] = string2Int(
                                                 luaTable[keytable["KEY_READ_COLOR_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_READ_BRIGHTNESS"]] ~= nil then
        valuetable["READBRINGHTNESS"] = string2Int(
                                            luaTable[keytable["KEY_READ_BRIGHTNESS"]])
    end
    if luaTable[keytable["KEY_MILD_COLOR_TEMPERATURE"]] ~= nil then
        valuetable["MILDCOLORTEMPERATURE"] = string2Int(
                                                 luaTable[keytable["KEY_MILD_COLOR_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_MILD_BRIGHTNESS"]] ~= nil then
        valuetable["MILDBRINGHTNESS"] = string2Int(
                                            luaTable[keytable["KEY_MILD_BRIGHTNESS"]])
    end
    if luaTable[keytable["KEY_FILM_COLOR_TEMPERATURE"]] ~= nil then
        valuetable["FILMCOLORTEMPERATURE"] = string2Int(
                                                 luaTable[keytable["KEY_FILM_COLOR_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_FILM_BRIGHTNESS"]] ~= nil then
        valuetable["FILMBRINGHTNESS"] = string2Int(
                                            luaTable[keytable["KEY_FILM_BRIGHTNESS"]])
    end
    if luaTable[keytable["KEY_NIGHT_COLOR_TEMPERATURE"]] ~= nil then
        valuetable["NIGHTCOLORTEMPERATURE"] = string2Int(
                                                  luaTable[keytable["KEY_NIGHT_COLOR_TEMPERATURE"]])
    end
    if luaTable[keytable["KEY_NIGHT_BRIGHTNESS"]] ~= nil then
        valuetable["NIGHTBRINGHTNESS"] = string2Int(
                                             luaTable[keytable["KEY_NIGHT_BRIGHTNESS"]])
    end
    if luaTable[keytable["KEY_SUNSET_EN"]] ~= nil then
        valuetable["SUNSETEN"] = string2Int(luaTable[keytable["KEY_SUNSET_EN"]])
    end
    if luaTable[keytable["KEY_SUNSET_HOUR"]] ~= nil then
        valuetable["SUNSETHOUR"] = string2Int(
                                       luaTable[keytable["KEY_SUNSET_HOUR"]])
    end
    if luaTable[keytable["KEY_SUNSET_MINUTE"]] ~= nil then
        valuetable["SUNSETMINUTE"] = string2Int(
                                         luaTable[keytable["KEY_SUNSET_MINUTE"]])
    end
    if luaTable[keytable["KEY_SUNSET_IS_RUN"]] ~= nil then
        valuetable["SUNSETISRUN"] = string2Int(
                                        luaTable[keytable["KEY_SUNSET_IS_RUN"]])
    end
    if luaTable[keytable["KEY_SUNUP_EN"]] ~= nil then
        valuetable["SUNUPEN"] = string2Int(luaTable[keytable["KEY_SUNUP_EN"]])
    end
    if luaTable[keytable["KEY_SUNUP_HOUR"]] ~= nil then
        valuetable["SUNUPHOUR"] = string2Int(
                                      luaTable[keytable["KEY_SUNUP_HOUR"]])
    end
    if luaTable[keytable["KEY_SUNUP_MINUTE"]] ~= nil then
        valuetable["SUNUPMINUTE"] = string2Int(
                                        luaTable[keytable["KEY_SUNUP_MINUTE"]])
    end
    if luaTable[keytable["KEY_SUNUP_IS_RUN"]] ~= nil then
        valuetable["SUNUPISRUN"] = string2Int(
                                       luaTable[keytable["KEY_SUNUP_IS_RUN"]])
    end
    if luaTable[keytable["KEY_LINKAGEMODEL"]] == "breath" then
        valuetable["LINKAGEMODEL"] = 1
    elseif luaTable[keytable["KEY_LINKAGEMODEL"]] == "blink" then
        valuetable["LINKAGEMODEL"] = 2
    elseif luaTable[keytable["KEY_LINKAGEMODEL"]] == "discolor" then
        valuetable["LINKAGEMODEL"] = 3
    end
    if luaTable[keytable["KEY_BLUETOOTH_SCENE"]] == 'CutTheColor' then
        keytable["bluetooth_scene_value"] = 1
    end
end
local function updateGlobalPropertyValueByByte(messageBytes)
    cmdType = messageBytes[0]
    if cmdType == 0x80 then valresult = 0x01 end
    if cmdType == 0x81 then valresult = 0x01 end
    if cmdType == 0x82 then valresult = 0x01 end
    if cmdType == 0x83 then valresult = 0x01 end
    if cmdType == 0x84 then valresult = 0x01 end
    if cmdType == 0x85 then valresult = 0x01 end
    if cmdType == 0xa4 then
        valuetable["BRIGHTNESSVAL"] = messageBytes[1]
        valuetable["COLORTEMPERATURE"] = messageBytes[2]
        print("COLORTEMPERATURE:" .. valuetable["COLORTEMPERATURE"])
        valuetable["SCENEMODEL"] = messageBytes[3]
        valuetable["DELAYLIGHTOFF"] = messageBytes[4]
        valuetable["RED_VALUE"] = messageBytes[5]
        valuetable["GREEN_VALUE"] = messageBytes[6]
        valuetable["BLUE_VALUE"] = messageBytes[7]
        valuetable["LEDPOWER"] = messageBytes[8]
        valuetable["LIFECOLORTEMPERATURE"] = messageBytes[10]
        valuetable["LIFEBRINGHTNESS"] = messageBytes[9]
        valuetable["READCOLORTEMPERATURE"] = messageBytes[12]
        valuetable["READBRINGHTNESS"] = messageBytes[11]
        valuetable["MILDCOLORTEMPERATURE"] = messageBytes[14]
        valuetable["MILDBRINGHTNESS"] = messageBytes[13]
        valuetable["FILMCOLORTEMPERATURE"] = messageBytes[16]
        valuetable["FILMBRINGHTNESS"] = messageBytes[15]
        print("FILMCOLORTEMPERATURE:" .. valuetable["FILMCOLORTEMPERATURE"])
        print("FILMBRINGHTNESS:" .. valuetable["FILMBRINGHTNESS"])
        valuetable["NIGHTCOLORTEMPERATURE"] = messageBytes[18]
        valuetable["NIGHTBRINGHTNESS"] = messageBytes[17]
        valuetable["SUNUPEN"] = messageBytes[19]
        valuetable["SUNSETEN"] = messageBytes[20]
        valuetable["SUNUPHOUR"] = messageBytes[21]
        valuetable["SUNUPMINUTE"] = messageBytes[22]
        valuetable["SUNSETHOUR"] = messageBytes[23]
        valuetable["SUNSETMINUTE"] = messageBytes[24]
        valuetable["SUNUPISRUN"] = messageBytes[25]
        valuetable["SUNSETISRUN"] = messageBytes[26]
        valuetable["DIMSPEED"] = messageBytes[27]
        valuetable["COLORTEMPERATURE_MIN"] =
            messageBytes[28] * 256 + messageBytes[29]
        valuetable["COLORTEMPERATURE_MAX"] =
            messageBytes[30] * 256 + messageBytes[31]
        valuetable["LINKAGEMODEL"] = messageBytes[32]
    end
    if cmdType == 0x86 then valresult = 0x01 end
    if cmdType == 0x87 then valresult = 0x01 end
    if cmdType == 0x88 then valresult = 0x01 end
    if cmdType == 0x89 then valresult = 0x01 end
    if cmdType == 0x8a then valresult = 0x01 end
    if cmdType == 0x8b then valresult = 0x01 end
    if cmdType == 0x8c then valresult = 0x01 end
    if cmdType == 0x8d then valresult = 0x01 end
    if cmdType == 0x8e then valresult = 0x01 end
end
local function assembleJsonByGlobalProperty()
    local streams = {}
    streams[keytable["KEY_VERSION"]] = "4"
    if cmdType == 0xa4 then
        streams[keytable["KEY_BRIGHTNESS"]] =
            int2String(math.ceil(valuetable["BRIGHTNESSVAL"] / 2.55))
        streams[keytable["KEY_COLOR_TEMPERATURE"]] =
            int2String(math.ceil(valuetable["COLORTEMPERATURE"] / 2.55))
        if valuetable["TOGGLELEDPOWER"] == 0x01 then
            streams[keytable["KEY_TOGGLE_POWER"]] = "1"
        end
        if valuetable["LEDPOWER"] == 0x01 then
            streams[keytable["KEY_POWER"]] = "on"
        else
            streams[keytable["KEY_POWER"]] = "off"
        end
        if valuetable["SCENEMODEL"] == 0x02 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "life"
        elseif valuetable["SCENEMODEL"] == 0x03 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "read"
        elseif valuetable["SCENEMODEL"] == 0x04 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "mild"
        elseif valuetable["SCENEMODEL"] == 0x05 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "film"
        elseif valuetable["SCENEMODEL"] == 0x06 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "moon"
        elseif valuetable["SCENEMODEL"] == 0x01 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "manual"
        elseif valuetable["SCENEMODEL"] == 0x07 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "breath"
        elseif valuetable["SCENEMODEL"] == 0x08 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "ambiglow"
        elseif valuetable["SCENEMODEL"] == 0x09 then
            streams[keytable["KEY_SCENE_LIGHT"]] = "sleep"
        elseif valuetable["SCENEMODEL"] == 0x0a then
            streams[keytable["KEY_SCENE_LIGHT"]] = "wakeup"
        end
        streams[keytable["KEY_DELAY_LIGHT_OFF"]] = int2String(
                                                       valuetable["DELAYLIGHTOFF"])
        streams[keytable["KEY_RED_VALUE"]] = int2String(valuetable["RED_VALUE"])
        streams[keytable["KEY_GREEN_VALUE"]] = int2String(
                                                   valuetable["GREEN_VALUE"])
        streams[keytable["KEY_BLUE_VALUE"]] = int2String(
                                                  valuetable["BLUE_VALUE"])
        streams[keytable["KEY_LIFE_BRIGHTNESS"]] = int2String(
                                                       valuetable["LIFEBRINGHTNESS"])
        streams[keytable["KEY_LIFE_COLOR_TEMPERATURE"]] = int2String(
                                                              valuetable["LIFECOLORTEMPERATURE"])
        streams[keytable["KEY_READ_BRIGHTNESS"]] = int2String(
                                                       valuetable["READBRINGHTNESS"])
        streams[keytable["KEY_READ_COLOR_TEMPERATURE"]] = int2String(
                                                              valuetable["READCOLORTEMPERATURE"])
        streams[keytable["KEY_MILD_BRIGHTNESS"]] = int2String(
                                                       valuetable["MILDBRINGHTNESS"])
        streams[keytable["KEY_MILD_COLOR_TEMPERATURE"]] = int2String(
                                                              valuetable["MILDCOLORTEMPERATURE"])
        streams[keytable["KEY_FILM_BRIGHTNESS"]] = int2String(
                                                       valuetable["FILMBRINGHTNESS"])
        streams[keytable["KEY_FILM_COLOR_TEMPERATURE"]] = int2String(
                                                              valuetable["FILMCOLORTEMPERATURE"])
        streams[keytable["KEY_NIGHT_BRIGHTNESS"]] = int2String(
                                                        valuetable["NIGHTBRINGHTNESS"])
        streams[keytable["KEY_NIGHT_COLOR_TEMPERATURE"]] = int2String(
                                                               valuetable["NIGHTCOLORTEMPERATURE"])
        if valuetable["SUNSETISRUN"] == 1 then
            streams[keytable["KEY_SUNSET_IS_RUN"]] = "on"
        elseif valuetable["SUNSETISRUN"] == 0 then
            streams[keytable["KEY_SUNSET_IS_RUN"]] = "off"
        end
        streams[keytable["KEY_SUNSET_EN"]] = int2String(valuetable["SUNSETEN"])
        streams[keytable["KEY_SUNSET_HOUR"]] = int2String(
                                                   valuetable["SUNSETHOUR"])
        streams[keytable["KEY_SUNSET_MINUTE"]] = int2String(
                                                     valuetable["SUNSETMINUTE"])
        if valuetable["SUNUPISRUN"] == 1 then
            streams[keytable["KEY_SUNUP_IS_RUN"]] = "on"
        elseif valuetable["SUNUPISRUN"] == 0 then
            streams[keytable["KEY_SUNUP_IS_RUN"]] = "off"
        end
        streams[keytable["KEY_SUNUP_EN"]] = int2String(valuetable["SUNUPEN"])
        streams[keytable["KEY_SUNUP_HOUR"]] =
            int2String(valuetable["SUNUPHOUR"])
        streams[keytable["KEY_SUNUP_MINUTE"]] = int2String(
                                                    valuetable["SUNUPMINUTE"])
        if valuetable["LINKAGEMODEL"] == 1 then
            streams[keytable["KEY_LINKAGEMODEL"]] = "breath"
        elseif valuetable["LINKAGEMODEL"] == 2 then
            streams[keytable["KEY_LINKAGEMODEL"]] = "blink"
        elseif valuetable["LINKAGEMODEL"] == 3 then
            streams[keytable["KEY_LINKAGEMODEL"]] = "discolor"
        end
        if valuetable["bluetooth_scene_value"] == 1 then
            streams[keytable["KEY_BLUETOOTH_SCENE"]] = "CutTheColor"
        end
        streams[keytable["KEY_DIM_SPEED"]] = int2String(valuetable["DIMSPEED"])
        streams[keytable["KEY_COLOR_TEMPERATURE_MIN"]] = int2String(
                                                             valuetable["COLORTEMPERATURE_MIN"])
        streams[keytable["KEY_COLOR_TEMPERATURE_MAX"]] = int2String(
                                                             valuetable["COLORTEMPERATURE_MAX"])
        streams[keytable["KEY_RESULT"]] = "1"
    else
        streams[keytable["KEY_RESULT"]] = int2String(valresult)
    end
    return streams
end
local function decodeJsonToTable(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
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
        if (status) then end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyLength = 5
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        if control[keytable["KEY_TOGGLE_POWER"]] ~= nil then
            bodyBytes[0] = 0x00
            bodyBytes[1] = valuetable["TOGGLELEDPOWER"]
            bodyBytes[2] = valuetable["DIMSPEED"]
        end
        if control[keytable["KEY_POWER"]] ~= nil then
            bodyBytes[0] = 0x01
            bodyBytes[1] = valuetable["LEDPOWER"]
            bodyBytes[2] = valuetable["DIMSPEED"]
        end
        if control[keytable["KEY_SCENE_LIGHT"]] ~= nil then
            bodyBytes[0] = 0x02
            bodyBytes[1] = valuetable["SCENEMODEL"]
            bodyBytes[2] = valuetable["DIMSPEED"]
        end
        if control[keytable["KEY_COLOR_TEMPERATURE"]] ~= nil then
            bodyBytes[0] = 0x03
            bodyBytes[1] = math.ceil(valuetable["COLORTEMPERATURE"] * 2.55)
            bodyBytes[2] = valuetable["DIMSPEED"]
        end
        if control[keytable["KEY_BRIGHTNESS"]] ~= nil then
            bodyBytes[0] = 0x04
            bodyBytes[1] = math.ceil(valuetable["BRIGHTNESSVAL"] * 2.55)
            bodyBytes[2] = valuetable["DIMSPEED"]
        end
        if control[keytable["KEY_DELAY_LIGHT_OFF"]] ~= nil then
            bodyBytes[0] = 0x05
            bodyBytes[1] = valuetable["DELAYLIGHTOFF"]
        end
        if control[keytable["KEY_LIFE_COLOR_TEMPERATURE"]] ~= nil then
            if control[keytable["KEY_LIFE_BRIGHTNESS"]] ~= nil then
                bodyBytes[0] = 0x06
                bodyBytes[1] = valuetable["LIFEBRINGHTNESS"]
                bodyBytes[2] = valuetable["LIFECOLORTEMPERATURE"]
            end
        end
        if control[keytable["KEY_READ_COLOR_TEMPERATURE"]] ~= nil then
            if control[keytable["KEY_READ_BRIGHTNESS"]] ~= nil then
                bodyBytes[0] = 0x07
                bodyBytes[1] = valuetable["READBRINGHTNESS"]
                bodyBytes[2] = valuetable["READCOLORTEMPERATURE"]
            end
        end
        if control[keytable["KEY_MILD_COLOR_TEMPERATURE"]] ~= nil then
            if control[keytable["KEY_MILD_BRIGHTNESS"]] ~= nil then
                bodyBytes[0] = 0x08
                bodyBytes[1] = valuetable["MILDBRINGHTNESS"]
                bodyBytes[2] = valuetable["MILDCOLORTEMPERATURE"]
            end
        end
        if control[keytable["KEY_FILM_COLOR_TEMPERATURE"]] ~= nil then
            if control[keytable["KEY_FILM_BRIGHTNESS"]] ~= nil then
                bodyBytes[0] = 0x09
                bodyBytes[1] = valuetable["FILMBRINGHTNESS"]
                bodyBytes[2] = valuetable["FILMCOLORTEMPERATURE"]
            end
        end
        if control[keytable["KEY_NIGHT_COLOR_TEMPERATURE"]] ~= nil then
            if control[keytable["KEY_NIGHT_BRIGHTNESS"]] ~= nil then
                bodyBytes[0] = 0x0a
                bodyBytes[1] = valuetable["NIGHTBRINGHTNESS"]
                bodyBytes[2] = valuetable["NIGHTCOLORTEMPERATURE"]
            end
        end
        if control[keytable["KEY_SUNUP_EN"]] ~= nil then
            if control[keytable["KEY_SUNUP_HOUR"]] ~= nil then
                if control[keytable["KEY_SUNUP_MINUTE"]] ~= nil then
                    bodyBytes[0] = 0x0b
                    bodyBytes[1] = valuetable["SUNUPEN"]
                    bodyBytes[2] = valuetable["SUNUPHOUR"]
                    bodyBytes[3] = valuetable["SUNUPMINUTE"]
                end
            end
        end
        if control[keytable["KEY_SUNSET_EN"]] ~= nil then
            if control[keytable["KEY_SUNSET_HOUR"]] ~= nil then
                if control[keytable["KEY_SUNSET_MINUTE"]] ~= nil then
                    bodyBytes[0] = 0x0c
                    bodyBytes[1] = valuetable["SUNSETEN"]
                    bodyBytes[2] = valuetable["SUNSETHOUR"]
                    bodyBytes[3] = valuetable["SUNSETMINUTE"]
                end
            end
        end
        if control[keytable["KEY_LINKAGEMODEL"]] ~= nil then
            bodyBytes[0] = 0x0d
            bodyBytes[1] = valuetable["LINKAGEMODEL"]
            bodyBytes[2] = valuetable["DIMSPEED"]
        end
        if control[keytable["KEY_BLUETOOTH_SCENE"]] ~= nil then
            bodyBytes[0] = 0x0e
            bodyBytes[1] = valuetable["bluetooth_scene_value"]
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        local bodyLength = 5
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        bodyBytes[0] = 0x24
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
    local status = json["status"]
    if (status) then end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10];
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable["status"] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end
