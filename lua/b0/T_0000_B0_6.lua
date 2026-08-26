local JSON = require 'cjson'
local VALUE_UNKNOWN = 'unknown'
local VALUE_INVALID = 'invalid'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_WORK_STATUS = 'work_status'
local KEY_MODE = 'mode'
local KEY_MINUTES = 'minutes'
local KEY_SECOND = 'second'
local KEY_FIRE_POWER = 'fire_power'
local KEY_WEIGHT = 'weight'
local KEY_DOOR_OPEN = 'door_open'
local KEY_LOCK = 'lock'
local KEY_WORK_STAGE = 'work_stage'
local KEY_ERROR_CODE = 'error_code'
local KEY_TIPS_CODE = 'tips_code'
local KEY_BRITTLE_FIRE_POWER = 'brittle_fire_power'
local KEY_STEAM_TIME = 'steam_time'
local KEY_TEMP_BAKE_OR_FERMENT = 'temp_bake_or_ferment'
local KEY_TEMP_PURE_FERMENT = 'temp_pure_ferment'
local KEY_TEMP_FAST_STEAM = 'temp_fast_steam'
local KEY_CLEAN_TYPE = 'clean_type'
local KEY_MAINTAIN = 'maintain'

local VALUE_VERSION = 6
local VALUE_ON = 'on'
local VALUE_OFF = 'off'
local VALUE_WORK_STATUS_CANCEL = 'cancel'
local VALUE_WORK_STATUS_WORK = 'work'
local VALUE_WORK_STATUS_PAUSE = 'pause'
local VALUE_WORK_STATUS_END = 'end'
local VALUE_WORK_STATUS_ORDER = 'order'
local VALUE_WORK_STATUS_SAVE_POWER = 'save_power'
local VALUE_WORK_STATUS_HEAT = 'heat'
local VALUE_WORK_STATUS_THREE = 'three'
local VALUE_WORK_STATUS_REACTION = 'reaction'
local VALUE_WORK_STATUS_CLOUD = 'cloud'
local VALUE_MODE_MICROWAVE = 'microwave'
local VALUE_MODE_BAKING = 'baking'
local VALUE_MODE_UNFREEZE = 'unfreeze'
local VALUE_MODE_FERMENT = 'ferment'
local VALUE_MODE_ROAST = 'roast'
local VALUE_MODE_HOT_STEAM = 'hot_steam'
local VALUE_MODE_FAST_STEAM = 'fast_steam'
local VALUE_MODE_FAST_HOT = 'fast_hot'
local VALUE_MODE_PURE_STEAM = 'pure_steam'
local VALUE_MODE_METAL_STERILIZE = 'metal_sterilize'
local VALUE_MODE_REMOVE_ODOR = 'remove_odor'
local VALUE_MODE_SMART_CLEAN = 'smart_clean'
local VALUE_MODE_SCALE_CLEAN = 'scale_clean'
local VALUE_MODE_WARM = 'warm'
local VALUE_MODE_PRE_HOT = 'pre_hot'
local VALUE_MODE_FAST_BAKING = 'fast_baking'
local VALUE_MODE_BRITTLE = 'brittle'

local BYTE_DEVICE_TYPE = 0xB0
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x07
local BYTE_STATUS_CANCEL = 0x01
local BYTE_STATUS_WORK = 0x02
local BYTE_STATUS_PAUSE = 0x03
local BYTE_STATUS_END = 0x04
local BYTE_STATUS_ORDER = 0x06
local BYTE_STATUS_SAVE_POWER = 0x07
local BYTE_STATUS_HEAT = 0x08
local BYTE_STATUS_THREE_SEC = 0x09
local BYTE_STATUS_REACTION = 0x0D
local BYTE_STATUS_CLOUD = 0x66
local BYTE_MODE_MICROWAVE = 0x01
local BYTE_MODE_BAKING = 0x02
local BYTE_MODE_FERMENT = 0x03
local BYTE_MODE_UNFREEZE = 0x04
local BYTE_MODE_ROAST = 0x05
local BYTE_MODE_HOT_STEAM = 0x06
local BYTE_MODE_FAST_STEAM = 0x07
local BYTE_MODE_FAST_HOT = 0x08
local BYTE_MODE_PURE_STEAM = 0x09
local BYTE_MODE_METAL_STERILIZE = 0x0A
local BYTE_MODE_REMOVE_ODOR = 0x0B
local BYTE_MODE_SMART_CLEAN = 0x0D
local BYTE_MODE_SCALE_CLEAN = 0x0C
local BYTE_MODE_WARM = 0x41
local BYTE_MODE_PRE_HOT = 0x42
local BYTE_MODE_FAST_BAKING = 0x43
local BYTE_MODE_BRITTLE = 0x44
local BYTE_LOCK_ON = 0x05
local BYTE_LOCK_OFF = 0x01

local workStatus = 0
local mode = 0
local minutes = 0
local second = 0
local firePower = 0
local weight = 0
local doorOpen = 0
local workStage = 0
local errorCode = 0
local tipsCode = 0
local brittleFirePower = 0
local steamTime = 0
local tempBakeOrFerment = 0
local tempPureFerment = 0
local tempFastSteam = 0
local cleanType = 0
local maintain = 0
local dataType = 0
local deviceSubType = 0

function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_POWER] == VALUE_ON then
        workStatus = BYTE_POWER_ON
    elseif luaTable[KEY_POWER] == VALUE_OFF then
        workStatus = BYTE_POWER_OFF
    end
    if luaTable[KEY_WORK_STATUS] == VALUE_WORK_STATUS_CANCEL then
        workStatus = BYTE_STATUS_CANCEL
    elseif luaTable[KEY_WORK_STATUS] == VALUE_WORK_STATUS_PAUSE then
        workStatus = BYTE_STATUS_PAUSE
    elseif luaTable[KEY_WORK_STATUS] == VALUE_WORK_STATUS_WORK then
        workStatus = BYTE_STATUS_WORK
    elseif (luaTable[KEY_WORK_STATUS] == VALUE_WORK_STATUS_SAVE_POWER) then
        workStatus = BYTE_STATUS_SAVE_POWER
    end
    if luaTable[KEY_LOCK] == VALUE_ON then
        workStatus = BYTE_LOCK_ON
    elseif luaTable[KEY_LOCK] == VALUE_OFF then
        workStatus = BYTE_LOCK_OFF
    end
    if luaTable[KEY_MODE] == VALUE_MODE_MICROWAVE then
        mode = BYTE_MODE_MICROWAVE
    elseif luaTable[KEY_MODE] == VALUE_MODE_BAKING then
        mode = BYTE_MODE_BAKING
    elseif luaTable[KEY_MODE] == VALUE_MODE_FERMENT then
        mode = BYTE_MODE_FERMENT
    elseif luaTable[KEY_MODE] == VALUE_MODE_UNFREEZE then
        mode = BYTE_MODE_UNFREEZE
    elseif luaTable[KEY_MODE] == VALUE_MODE_ROAST then
        mode = BYTE_MODE_ROAST
    elseif luaTable[KEY_MODE] == VALUE_MODE_HOT_STEAM then
        mode = BYTE_MODE_HOT_STEAM
    elseif luaTable[KEY_MODE] == VALUE_MODE_FAST_STEAM then
        mode = BYTE_MODE_FAST_STEAM
    elseif luaTable[KEY_MODE] == VALUE_MODE_FAST_HOT then
        mode = BYTE_MODE_FAST_HOT
    elseif luaTable[KEY_MODE] == VALUE_MODE_PURE_STEAM then
        mode = BYTE_MODE_PURE_STEAM
    elseif luaTable[KEY_MODE] == VALUE_MODE_METAL_STERILIZE then
        mode = BYTE_MODE_METAL_STERILIZE
    elseif luaTable[KEY_MODE] == VALUE_MODE_REMOVE_ODOR then
        mode = BYTE_MODE_REMOVE_ODOR
    elseif luaTable[KEY_MODE] == VALUE_MODE_SMART_CLEAN then
        mode = BYTE_MODE_SMART_CLEAN
    elseif luaTable[KEY_MODE] == VALUE_MODE_SCALE_CLEAN then
        mode = BYTE_MODE_SCALE_CLEAN
    elseif luaTable[KEY_MODE] == VALUE_MODE_WARM then
        mode = BYTE_MODE_WARM
    elseif luaTable[KEY_MODE] == VALUE_MODE_PRE_HOT then
        mode = BYTE_MODE_PRE_HOT
    elseif luaTable[KEY_MODE] == VALUE_MODE_FAST_BAKING then
        mode = BYTE_MODE_FAST_BAKING
    elseif luaTable[KEY_MODE] == VALUE_MODE_BRITTLE then
        mode = BYTE_MODE_BRITTLE
    end
    if luaTable[KEY_FIRE_POWER] ~= nil then
        if (luaTable[KEY_FIRE_POWER] == VALUE_INVALID) then
            firePower = 0
        else
            firePower = checkBoundary(luaTable[KEY_FIRE_POWER], 1, 10)
        end
    end
    if (luaTable[KEY_BRITTLE_FIRE_POWER] ~= nil) then
        brittleFirePower =
            checkBoundary(luaTable[KEY_BRITTLE_FIRE_POWER], 1, 10)
    end
    if (luaTable[KEY_TEMP_BAKE_OR_FERMENT] ~= nil) then
        tempBakeOrFerment = checkBoundary(luaTable[KEY_TEMP_BAKE_OR_FERMENT], 5,
                                          300)
    end
    if (luaTable[KEY_STEAM_TIME] ~= nil) then
        steamTime = checkBoundary(luaTable[KEY_STEAM_TIME], 0, 255)
    end
    if luaTable[KEY_WEIGHT] ~= nil then
        local w = luaTable[KEY_WEIGHT]
        w = checkBoundary(w, 100, 2000)
        w = math.floor((w / 100) + 0.5)
        weight = w
    end
    if luaTable[KEY_MINUTES] ~= nil then
        minutes = checkBoundary(luaTable[KEY_MINUTES], 0, 99)
    end
    if luaTable[KEY_SECOND] ~= nil then
        second = checkBoundary(luaTable[KEY_SECOND], 0, 59)
    end
end

function updateGlobalPropertyValueByByte(messageBytes)
    if #messageBytes >= 15 then
        workStatus = bit.band(messageBytes[0], 0x7F)
        if (bit.band(messageBytes[0], 0x80) == 0x80) then
            doorOpen = VALUE_ON
        else
            doorOpen = VALUE_OFF
        end
        mode = messageBytes[1]
        minutes = messageBytes[2]
        second = messageBytes[3]
        workStage = messageBytes[4]
        errorCode = messageBytes[5]
        tipsCode = messageBytes[6]
        maintain = messageBytes[7]
        if (mode == BYTE_MODE_MICROWAVE) then
            firePower = messageBytes[14]
        elseif (mode == BYTE_MODE_BRITTLE) then
            brittleFirePower = messageBytes[14]
        elseif (mode == BYTE_MODE_PURE_STEAM) then
            tempPureFerment = messageBytes[14]
        elseif (mode == BYTE_MODE_SMART_CLEAN) then
            cleanType = messageBytes[14]
        elseif (mode == BYTE_MODE_FAST_STEAM) then
            tempFastSteam = messageBytes[14]
        elseif ((mode == BYTE_MODE_FERMENT) or (mode == BYTE_MODE_ROAST)) then
            tempBakeOrFerment = messageBytes[14] * 5
        end
        if ((mode == BYTE_MODE_FERMENT) or (mode == BYTE_MODE_ROAST)) then
            steamTime = messageBytes[15]
        elseif (mode == BYTE_MODE_UNFREEZE) then
            weight = messageBytes[15]
        end
    end
end

function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (workStatus == BYTE_POWER_OFF) then
        streams[KEY_POWER] = VALUE_OFF
    else
        streams[KEY_POWER] = VALUE_ON
    end
    if (workStatus == BYTE_LOCK_ON) then
        streams[KEY_LOCK] = VALUE_ON
    else
        streams[KEY_LOCK] = VALUE_OFF
    end
    if (workStatus == BYTE_STATUS_CANCEL) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_CANCEL
    elseif (workStatus == BYTE_STATUS_WORK) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_WORK
    elseif (workStatus == BYTE_STATUS_PAUSE) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_PAUSE
    elseif (workStatus == BYTE_STATUS_END) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_END
    elseif (workStatus == BYTE_STATUS_ORDER) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_ORDER
    elseif (workStatus == BYTE_STATUS_HEAT) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_HEAT
    elseif (workStatus == BYTE_STATUS_THREE_SEC) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_THREE
    elseif (workStatus == BYTE_STATUS_REACTION) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_REACTION
    elseif (workStatus == BYTE_STATUS_CLOUD) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_CLOUD
    elseif (workStatus == BYTE_STATUS_SAVE_POWER) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_SAVE_POWER
    end
    if (mode == BYTE_MODE_MICROWAVE) then
        streams[KEY_MODE] = VALUE_MODE_MICROWAVE
    elseif (mode == BYTE_MODE_BAKING) then
        streams[KEY_MODE] = VALUE_MODE_BAKING
    elseif (mode == BYTE_MODE_FERMENT) then
        streams[KEY_MODE] = VALUE_MODE_FERMENT
    elseif (mode == BYTE_MODE_UNFREEZE) then
        streams[KEY_MODE] = VALUE_MODE_UNFREEZE
    elseif (mode == BYTE_MODE_ROAST) then
        streams[KEY_MODE] = VALUE_MODE_ROAST
    elseif (mode == BYTE_MODE_HOT_STEAM) then
        streams[KEY_MODE] = VALUE_MODE_HOT_STEAM
    elseif (mode == BYTE_MODE_FAST_STEAM) then
        streams[KEY_MODE] = VALUE_MODE_FAST_STEAM
    elseif (mode == BYTE_MODE_FAST_HOT) then
        streams[KEY_MODE] = VALUE_MODE_FAST_HOT
    elseif (mode == BYTE_MODE_PURE_STEAM) then
        streams[KEY_MODE] = VALUE_MODE_PURE_STEAM
    elseif (mode == BYTE_MODE_METAL_STERILIZE) then
        streams[KEY_MODE] = VALUE_MODE_METAL_STERILIZE
    elseif (mode == BYTE_MODE_REMOVE_ODOR) then
        streams[KEY_MODE] = VALUE_MODE_REMOVE_ODOR
    elseif (mode == BYTE_MODE_SMART_CLEAN) then
        streams[KEY_MODE] = VALUE_MODE_SMART_CLEAN
    elseif (mode == BYTE_MODE_SCALE_CLEAN) then
        streams[KEY_MODE] = VALUE_MODE_SCALE_CLEAN
    elseif (mode == BYTE_MODE_WARM) then
        streams[KEY_MODE] = VALUE_MODE_WARM
    elseif (mode == BYTE_MODE_PRE_HOT) then
        streams[KEY_MODE] = VALUE_MODE_PRE_HOT
    elseif (mode == BYTE_MODE_FAST_BAKING) then
        streams[KEY_MODE] = VALUE_MODE_FAST_BAKING
    elseif (mode == BYTE_MODE_BRITTLE) then
        streams[KEY_MODE] = VALUE_MODE_BRITTLE
    elseif (mode == 0x11) then
        streams[KEY_MODE] = 'smart_steam_fish'
    elseif (mode == 0x12) then
        streams[KEY_MODE] = 'rice'
    elseif (mode == 0x13) then
        streams[KEY_MODE] = 'steam_ribs'
    elseif (mode == 0x14) then
        streams[KEY_MODE] = 'code_to_hot'
    elseif (mode == 0x15) then
        streams[KEY_MODE] = 'wing'
    elseif (mode == 0x16) then
        streams[KEY_MODE] = 'kebab'
    elseif (mode == 0x18) then
        streams[KEY_MODE] = 'egg'
    elseif (mode == 0x19) then
        streams[KEY_MODE] = 'instant_noodle'
    elseif (mode == 0x1A) then
        streams[KEY_MODE] = 'vegetable'
    elseif (mode == 0x1B) then
        streams[KEY_MODE] = 'meat'
    elseif (mode == 0x1C) then
        streams[KEY_MODE] = 'tofu'
    elseif (mode == 0x1D) then
        streams[KEY_MODE] = 'chicken_soup'
    elseif (mode == 0x1E) then
        streams[KEY_MODE] = 'dumplings'
    elseif (mode == 0x1F) then
        streams[KEY_MODE] = 'porridge'
    elseif (mode == 0x20) then
        streams[KEY_MODE] = 'chicken_block'
    elseif (mode == 0x21) then
        streams[KEY_MODE] = 'pumpkin'
    elseif (mode == 0x22) then
        streams[KEY_MODE] = 'popcorn'
    elseif (mode == 0x23) then
        streams[KEY_MODE] = 'meat_eggplant'
    elseif (mode == 0x24) then
        streams[KEY_MODE] = 'bake_shrimp'
    elseif (mode == 0x25) then
        streams[KEY_MODE] = 'baby_milk'
    elseif (mode == 0x26) then
        streams[KEY_MODE] = 'baby_egg'
    elseif (mode == 0x27) then
        streams[KEY_MODE] = 'carrots'
    elseif (mode == 0x28) then
        streams[KEY_MODE] = 'baby_fruit'
    elseif (mode == 0x29) then
        streams[KEY_MODE] = 'snow_pear'
    elseif (mode == 0x2A) then
        streams[KEY_MODE] = 'papaya_milk'
    elseif (mode == 0x2B) then
        streams[KEY_MODE] = 'jujube_longan'
    elseif (mode == 0x2C) then
        streams[KEY_MODE] = 'lotus_seed'
    elseif (mode == 0x2D) then
        streams[KEY_MODE] = 'fast_soup'
    elseif (mode == 0x2E) then
        streams[KEY_MODE] = 'sirloin'
    elseif (mode == 0x2F) then
        streams[KEY_MODE] = 'coconut_sago'
    elseif (mode == 0x30) then
        streams[KEY_MODE] = 'meat_tofu'
    elseif (mode == 0x31) then
        streams[KEY_MODE] = 'spicy_tofu'
    elseif (mode == 0x32) then
        streams[KEY_MODE] = 'sauted_meat'
    elseif (mode == 0x33) then
        streams[KEY_MODE] = 'steam_corn'
    elseif (mode == 0x34) then
        streams[KEY_MODE] = 'pearl_meat'
    elseif (mode == 0x35) then
        streams[KEY_MODE] = 'bun'
    elseif (mode == 0x36) then
        streams[KEY_MODE] = 'coix_bean'
    elseif (mode == 0x37) then
        streams[KEY_MODE] = 'bake_ribs'
    elseif (mode == 0x38) then
        streams[KEY_MODE] = 'sausage'
    elseif (mode == 0x39) then
        streams[KEY_MODE] = 'bake_cake'
    elseif (mode == 0x3A) then
        streams[KEY_MODE] = 'bake_cookies'
    elseif (mode == 0x3B) then
        streams[KEY_MODE] = 'sweet_potato'
    elseif (mode == 0x3C) then
        streams[KEY_MODE] = 'steam_seafood'
    elseif (mode == 0x3D) then
        streams[KEY_MODE] = 'fans_scallops'
    elseif (mode == 0x3E) then
        streams[KEY_MODE] = 'steam_bun'
    elseif (mode == 0x3F) then
        streams[KEY_MODE] = 'sauerkraut_fish'
    elseif (mode == 0x50) then
        streams[KEY_MODE] = 'frozen_food'
    elseif (mode == 0x51) then
        streams[KEY_MODE] = 'milk_coffee'
    elseif (mode == 0x52) then
        streams[KEY_MODE] = 'spicy_sausage'
    elseif (mode == 0x53) then
        streams[KEY_MODE] = 'bake_swing'
    elseif (mode == 0x54) then
        streams[KEY_MODE] = 'pure_steam_fish'
    elseif (mode == 0x00) then
        streams[KEY_MODE] = 'none'
    end
    streams[KEY_MINUTES] = minutes
    streams[KEY_SECOND] = second
    if (firePower ~= nil) then
        if firePower == 0 then
            streams[KEY_FIRE_POWER] = VALUE_INVALID
        else
            streams[KEY_FIRE_POWER] = firePower
        end
    end
    if (weight ~= nil) then streams[KEY_WEIGHT] = weight * 100 end
    streams[KEY_DOOR_OPEN] = doorOpen
    streams[KEY_WORK_STAGE] = workStage
    streams[KEY_ERROR_CODE] = errorCode
    streams[KEY_TIPS_CODE] = tipsCode
    if (brittleFirePower ~= nil) then
        streams[KEY_BRITTLE_FIRE_POWER] = brittleFirePower
    end
    if (steamTime ~= nil) then streams[KEY_STEAM_TIME] = steamTime end
    if (tempBakeOrFerment ~= nil) then
        streams[KEY_TEMP_BAKE_OR_FERMENT] = tempBakeOrFerment
    end
    if (tempPureFerment ~= nil) then
        streams[KEY_TEMP_PURE_FERMENT] = tempPureFerment
    end
    if (tempFastSteam ~= nil) then
        streams[KEY_TEMP_FAST_STEAM] = tempFastSteam
    end
    if (cleanType ~= nil) then streams[KEY_CLEAN_TYPE] = cleanType end
    if (maintain ~= nil) then streams[KEY_MAINTAIN] = maintain end
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)
    deviceSubType = json['deviceinfo']['deviceSubType']
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (control) then
        if (status) then updateGlobalPropertyValueByJson(status) end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyLength = 13
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
        bodyBytes[0] = workStatus
        bodyBytes[1] = mode
        bodyBytes[2] = minutes
        bodyBytes[3] = second
        bodyBytes[4] = 0x00
        if (mode == BYTE_MODE_MICROWAVE) then
            bodyBytes[4] = firePower
        elseif (mode == BYTE_MODE_BRITTLE) then
            bodyBytes[4] = brittleFirePower
        elseif (mode == BYTE_MODE_BAKING) then
            bodyBytes[4] = 0x01
        elseif ((mode == BYTE_MODE_FERMENT) or (mode == BYTE_MODE_ROAST)) then
            bodyBytes[4] = tempBakeOrFerment / 5
        end
        bodyBytes[5] = 0x00
        if ((mode == BYTE_MODE_FERMENT) or (mode == BYTE_MODE_ROAST)) then
            bodyBytes[5] = steamTime
        elseif (mode == BYTE_MODE_UNFREEZE) then
            bodyBytes[5] = weight
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        local bodyLength = 1
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
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
    local deviceinfo = json['deviceinfo']
    deviceSubType = deviceinfo['deviceSubType']
    local binData = json['msg']['data']
    local status = json['status']
    if (status) then updateGlobalPropertyValueByJson(status) end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10]
    bodyBytes = extractBodyBytes(byteData)
    local ret = updateGlobalPropertyValueByByte(bodyBytes)
    local retTable = {}
    retTable['status'] = assembleJsonByGlobalProperty()
    local ret = encodeTableToJson(retTable)
    return ret
end

function extractBodyBytes(byteData)
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

function assembleUart(bodyBytes, type)
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

function makeSum(tmpbuf, start_pos, end_pos)
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

function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end

function decodeJsonToTable(cmd)
    local tb
    if JSON == nil then JSON = require 'cjson' end
    tb = JSON.decode(cmd)
    return tb
end

function encodeTableToJson(luaTable)
    local jsonStr
    if JSON == nil then JSON = require 'cjson' end
    jsonStr = JSON.encode(luaTable)
    return jsonStr
end

function string2table(hexstr)
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

function string2hexstring(str)
    local ret = ''
    for i = 1, #str do ret = ret .. string.format('%02x', str:byte(i)) end
    return ret
end

function table2string(cmd)
    local ret = ''
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end

function checkBoundary(data, min, max)
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

function string2Int(data)
    if (not data) then data = tonumber('0') end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end

function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = '0' end
    return data
end

function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == 'string' then k = string.format('%q', k) end
        local szSuffix = ''
        if type(v) == 'table' then szSuffix = '{' end
        local szPrefix = string.rep('    ', indent)
        formatting = szPrefix .. '[' .. k .. ']' .. ' = ' .. szSuffix
        if type(v) == 'table' then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix .. '},')
        else
            local szValue = ''
            if type(v) == 'string' then
                szValue = string.format('%q', v)
            else
                szValue = tostring(v)
            end
            print(formatting .. szValue .. ',')
        end
    end
end
