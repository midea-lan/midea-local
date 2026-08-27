local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_CONTROL_WORK_STATUS = 'control_status'
local KEY_RUNNING_WORK_STATUS = 'running_status'
local KEY_MODE = 'mode'
local KEY_PROGRAM = 'program'
local KEY_WASH_LEVEL = 'wash_level'
local KEY_RINSE_LEVEL = 'rinse_level'
local KEY_WASH_STRENGTH = 'wash_strength'
local KEY_DEHYDRATION_SPEED = 'dehydration_speed'
local KEY_RINSE_COUNT = 'rinse_count'
local KEY_TEMPERATURE = 'temperature'
local KEY_DEHYDRATION_TIME = 'dehydration_time'
local KEY_WASH_TIME = 'wash_time'
local KEY_LOCK = 'lock'
local KEY_INTELLIGENT_WASH = 'intelligent_wash'
local KEY_REMAIN_TIME = 'remain_time'
local KEY_ERROR_CODE = 'error_code'

local VALUE_VERSION = 7
local VALUE_ON = 'on'
local VALUE_OFF = 'off'
local VALUE_CONTROL_WORK_STATUS_START = 'start'
local VALUE_CONTROL_WORK_STATUS_PAUSE = 'pause'
local VALUE_RUNNING_WORK_STATUS_STANDBY = 'standby'
local VALUE_RUNNING_WORK_STATUS_WORK = 'work'
local VALUE_RUNNING_WORK_STATUS_PAUSE = 'pause'
local VALUE_RUNNING_WORK_STATUS_END = 'end'
local VALUE_RUNNING_WORK_STATUS_ERROR = 'error'
local VALUE_RUNNING_WORK_STATUS_ORDER = 'order'
local VALUE_MODE_NORMAL = 'normal'
local VALUE_MODE_DRY = 'dry'
local VALUE_MODE_CONTINUS = 'continus'
local VALUE_PROGRAM_STANDARD = 'standard'
local VALUE_PROGRAM_FAST = 'fast'
local VALUE_PROGRAM_BLANKE = 'blanket'
local VALUE_PROGRAM_WOOL = 'wool'
local VALUE_PROGRAM_EMBATHE = 'embathe'
local VALUE_PROGRAM_MEMORY = 'memory'
local VALUE_PROGRAM_CHILD = 'child'
local VALUE_PROGRAM_STRONG_WASH = 'strong_wash'
local VALUE_PROGRAM_DOWN_JACKET = 'down_jacket'
local VALUE_PROGRAM_STIR = 'stir'
local VALUE_PROGRAM_MUTE = 'mute'
local VALUE_PROGRAM_BUCKET_SELF_CLEAN = 'bucket_self_clean'
local VALUE_PROGRAM_AIR_DRY = 'air_dry'
local VALUE_PROGRAM_CYCLE = 'cycle'
local VALUE_PROGRAM_REMAIN_WATER = 'remain_water'
local VALUE_PROGRAM_SUMMER = 'summer'
local VALUE_PROGRAM_BIG = 'big'
local VALUE_PROGRAM_HOME = 'home'
local VALUE_PROGRAM_COWBAY = 'cowboy'
local VALUE_PROGRAM_SOFT = 'soft'
local VALUE_PROGRAM_HAND_WASH = 'hand_wash'
local VALUE_PROGRAM_WATER_FLOW = 'water_flow'
local VALUE_PROGRAM_FOG = 'fog'
local VALUE_PROGRAM_BUCKET_DRY = 'bucket_dry'
local VALUE_PROGRAM_FAST_CLEAN_WASH = 'fast_clean_wash'
local VALUE_PROGRAM_DEHYDRATION = 'dehydration'
local VALUE_PROGRAM_UNDER_WEAR = 'under_wear'

local BYTE_DEVICE_TYPE = 0xDA
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_POWER_ON = 0x01
local BYTE_POWER_OFF = 0x00
local BYTE_CONTROL_STATUS_START = 0x01
local BYTE_CONTROL_STATUS_PAUSE = 0x00
local BYTE_RUNNING_STATUS_STANDBY = 0x00
local BYTE_RUNNING_STATUS_WORK = 0x01
local BYTE_RUNNING_STATUS_PAUSE = 0x02
local BYTE_RUNNING_STATUS_END = 0x03
local BYTE_RUNNING_STATUS_ERROR = 0x04
local BYTE_RUNNING_STATUS_ORDER = 0x05
local BYTE_MODE_NORMAL = 0x00
local BYTE_MODE_DRY = 0x01
local BYTE_MODE_CONTINUS = 0x80
local BYTE_PROGRAM_STANDARD = 0x00
local BYTE_PROGRAM_FAST = 0x01
local BYTE_PROGRAM_BLANKE = 0x02
local BYTE_PROGRAM_WOOL = 0x03
local BYTE_PROGRAM_EMBATHE = 0x04
local BYTE_PROGRAM_MEMORY = 0x05
local BYTE_PROGRAM_CHILD = 0x06
local BYTE_PROGRAM_STRONG_WASH = 0x07
local BYTE_PROGRAM_DOWN_JACKET = 0x08
local BYTE_PROGRAM_STIR = 0x09
local BYTE_PROGRAM_MUTE = 0x0A
local BYTE_PROGRAM_BUCKET_SELF_CLEAN = 0x0B
local BYTE_PROGRAM_AIR_DRY = 0x0C
local BYTE_PROGRAM_CYCLE = 0x0D
local BYTE_PROGRAM_REMAIN_WATER = 0x10
local BYTE_PROGRAM_SUMMER = 0x11
local BYTE_PROGRAM_BIG = 0x12
local BYTE_PROGRAM_HOME = 0x13
local BYTE_PROGRAM_COWBAY = 0x14
local BYTE_PROGRAM_SOFT = 0x15
local BYTE_PROGRAM_HAND_WASH = 0x16
local BYTE_PROGRAM_WATER_FLOW = 0x17
local BYTE_PROGRAM_FOG = 0x18
local BYTE_PROGRAM_BUCKET_DRY = 0x19
local BYTE_PROGRAM_FAST_CLEAN_WASH = 0x1A
local BYTE_PROGRAM_DEHYDRATION = 0x1B
local BYTE_PROGRAM_UNDER_WEAR = 0x1C
local BYTE_LOCK_ON = 0x01
local BYTE_LOCK_OFF = 0x00

local power
local controlWorkStatus = 0
local runningWorkStatus
local mode = 0
local program = 0
local washLevel = 0
local rinseLevel = 0
local washStrength = 0
local dehydrationSpeed = 0
local rinseCount = 0
local temperature = 0
local dehydrationTime = 0
local washTime = 0
local lock = 0
local intelligentWash = 0
local remainTime = 0
local errorCode = 0

function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_POWER] == VALUE_ON then
        power = BYTE_POWER_ON
    elseif luaTable[KEY_POWER] == VALUE_OFF then
        power = BYTE_POWER_OFF
    end
    if luaTable[KEY_CONTROL_WORK_STATUS] == VALUE_CONTROL_WORK_STATUS_START then
        controlWorkStatus = BYTE_CONTROL_STATUS_START
    else
        controlWorkStatus = BYTE_CONTROL_STATUS_PAUSE
    end
    if luaTable[KEY_RUNNING_WORK_STATUS] == VALUE_RUNNING_WORK_STATUS_STANDBY then
        runningWorkStatus = BYTE_RUNNING_STATUS_STANDBY
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == VALUE_RUNNING_WORK_STATUS_WORK then
        runningWorkStatus = BYTE_RUNNING_STATUS_WORK
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == VALUE_RUNNING_WORK_STATUS_PAUSE then
        runningWorkStatus = BYTE_RUNNING_STATUS_PAUSE
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == VALUE_RUNNING_WORK_STATUS_END then
        runningWorkStatus = BYTE_RUNNING_STATUS_END
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == VALUE_RUNNING_WORK_STATUS_ERROR then
        runningWorkStatus = BYTE_RUNNING_STATUS_ERROR
    end
    if luaTable[KEY_MODE] == VALUE_MODE_NORMAL then
        mode = BYTE_MODE_NORMAL
    elseif luaTable[KEY_MODE] == VALUE_MODE_DRY then
        mode = BYTE_MODE_DRY
    elseif luaTable[KEY_MODE] == VALUE_MODE_CONTINUS then
        mode = BYTE_MODE_CONTINUS
    end
    if luaTable[KEY_PROGRAM] == VALUE_PROGRAM_STANDARD then
        program = BYTE_PROGRAM_STANDARD
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_FAST then
        program = BYTE_PROGRAM_FAST
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_BLANKE then
        program = BYTE_PROGRAM_BLANKE
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_WOOL then
        program = BYTE_PROGRAM_WOOL
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_EMBATHE then
        program = BYTE_PROGRAM_EMBATHE
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_MEMORY then
        program = BYTE_PROGRAM_MEMORY
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_CHILD then
        program = BYTE_PROGRAM_CHILD
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_STRONG_WASH then
        program = BYTE_PROGRAM_STRONG_WASH
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_DOWN_JACKET then
        program = BYTE_PROGRAM_DOWN_JACKET
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_STIR then
        program = BYTE_PROGRAM_STIR
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_MUTE then
        program = BYTE_PROGRAM_MUTE
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_BUCKET_SELF_CLEAN then
        program = BYTE_PROGRAM_BUCKET_SELF_CLEAN
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_AIR_DRY then
        program = BYTE_PROGRAM_AIR_DRY
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_CYCLE then
        program = BYTE_PROGRAM_CYCLE
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_REMAIN_WATER then
        program = BYTE_PROGRAM_REMAIN_WATER
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_SUMMER then
        program = BYTE_PROGRAM_SUMMER
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_BIG then
        program = BYTE_PROGRAM_BIG
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_HOME then
        program = BYTE_PROGRAM_HOME
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_COWBAY then
        program = BYTE_PROGRAM_COWBAY
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_SOFT then
        program = BYTE_PROGRAM_SOFT
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_HAND_WASH then
        program = BYTE_PROGRAM_HAND_WASH
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_WATER_FLOW then
        program = BYTE_PROGRAM_WATER_FLOW
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_FOG then
        program = BYTE_PROGRAM_FOG
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_BUCKET_DRY then
        program = BYTE_PROGRAM_BUCKET_DRY
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_FAST_CLEAN_WASH then
        program = BYTE_PROGRAM_FAST_CLEAN_WASH
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_DEHYDRATION then
        program = BYTE_PROGRAM_DEHYDRATION
    elseif luaTable[KEY_PROGRAM] == VALUE_PROGRAM_UNDER_WEAR then
        program = BYTE_PROGRAM_UNDER_WEAR
    elseif luaTable[KEY_PROGRAM] == 'rinse_dehydration' then
        program = 0x1D
    elseif luaTable[KEY_PROGRAM] == 'five_clean' then
        program = 0x1E
    elseif luaTable[KEY_PROGRAM] == 'degerm' then
        program = 0x1F
    elseif luaTable[KEY_PROGRAM] == 'in_15' then
        program = 0x20
    elseif luaTable[KEY_PROGRAM] == 'in_25' then
        program = 0x21
    elseif luaTable[KEY_PROGRAM] == 'love_baby' then
        program = 0x22
    elseif luaTable[KEY_PROGRAM] == 'outdoor' then
        program = 0x23
    elseif luaTable[KEY_PROGRAM] == 'silk' then
        program = 0x24
    elseif luaTable[KEY_PROGRAM] == 'shirt' then
        program = 0x25
    elseif luaTable[KEY_PROGRAM] == 'cook_wash' then
        program = 0x26
    elseif luaTable[KEY_PROGRAM] == 'towel' then
        program = 0x27
    elseif luaTable[KEY_PROGRAM] == 'memory_2' then
        program = 0x28
    elseif luaTable[KEY_PROGRAM] == 'memory_3' then
        program = 0x29
    elseif luaTable[KEY_PROGRAM] == 'half_energy' then
        program = 0x2A
    elseif luaTable[KEY_PROGRAM] == 'all_energy' then
        program = 0x2B
    elseif luaTable[KEY_PROGRAM] == 'soft_wash' then
        program = 0x2C
    elseif luaTable[KEY_PROGRAM] == 'prevent_allergy' then
        program = 0x2D
    elseif luaTable[KEY_PROGRAM] == 'wash_cube' then
        program = 0x2E
    elseif luaTable[KEY_PROGRAM] == 'winter_jacket' then
        program = 0x2F
    elseif luaTable[KEY_PROGRAM] == 'leisure_wash' then
        program = 0x30
    elseif luaTable[KEY_PROGRAM] == 'no_iron' then
        program = 0x31
    elseif luaTable[KEY_PROGRAM] == 'invalid' then
        program = 0xFF
    end
    if luaTable[KEY_WASH_LEVEL] ~= nil then
        washLevel = string2Int(luaTable[KEY_WASH_LEVEL])
    end
    if luaTable[KEY_RINSE_LEVEL] ~= nil then
        rinseLevel = string2Int(luaTable[KEY_RINSE_LEVEL])
    end
    if luaTable[KEY_WASH_STRENGTH] ~= nil then
        washStrength = string2Int(luaTable[KEY_WASH_STRENGTH])
    end
    if luaTable[KEY_DEHYDRATION_SPEED] ~= nil then
        dehydrationSpeed = string2Int(luaTable[KEY_DEHYDRATION_SPEED])
    end
    if luaTable[KEY_RINSE_COUNT] ~= nil then
        rinseCount = string2Int(luaTable[KEY_RINSE_COUNT])
    end
    if luaTable[KEY_TEMPERATURE] ~= nil then
        temperature = string2Int(luaTable[KEY_TEMPERATURE])
    end
    if luaTable[KEY_DEHYDRATION_TIME] ~= nil then
        dehydrationTime = string2Int(luaTable[KEY_DEHYDRATION_TIME])
    end
    if luaTable[KEY_WASH_TIME] ~= nil then
        washTime = string2Int(luaTable[KEY_WASH_TIME])
    end
    if luaTable[KEY_LOCK] == VALUE_ON then
        lock = BYTE_LOCK_ON
    elseif luaTable[KEY_LOCK] == VALUE_OFF then
        lock = BYTE_LOCK_OFF
    end
    if luaTable[KEY_INTELLIGENT_WASH] == VALUE_ON then
        intelligentWash = 0x80
    elseif luaTable[KEY_INTELLIGENT_WASH] == VALUE_OFF then
        intelligentWash = 0x00
    end
end

function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04) then
        power = messageBytes[1]
        runningWorkStatus = messageBytes[2]
        mode = messageBytes[3]
        program = messageBytes[4]
        washLevel = bit.band(messageBytes[5], 0x0F)
        rinseLevel = bit.rshift(messageBytes[5], 4)
        washStrength = bit.band(messageBytes[6], 0x0F)
        dehydrationSpeed = bit.rshift(messageBytes[6], 4)
        if bit.band(messageBytes[7], 0x01) == 0x01 then
            lock = BYTE_LOCK_ON
        else
            lock = BYTE_LOCK_OFF
        end
        if bit.band(messageBytes[7], 0x80) == 0x80 then
            intelligentWash = 0x80
        else
            intelligentWash = 0x00
        end
        washTime = messageBytes[9]
        rinseCount = bit.band(messageBytes[10], 0x0F)
        dehydrationTime = bit.rshift(messageBytes[10], 4)
        temperature = bit.band(messageBytes[15], 0x0F)
        remainTime = messageBytes[17] + messageBytes[18] * 60
        errorCode = messageBytes[24]
    end
    if (dataType == 0x06) then
        runningWorkStatus = messageBytes[1]
        mode = messageBytes[2]
        program = messageBytes[3]
        errorCode = messageBytes[6]
    end
end

function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (power == BYTE_POWER_ON) then
        streams[KEY_POWER] = VALUE_ON
    elseif (power == BYTE_POWER_OFF) then
        streams[KEY_POWER] = VALUE_OFF
    end
    if (runningWorkStatus == BYTE_RUNNING_STATUS_STANDBY) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_STANDBY
    elseif (runningWorkStatus == BYTE_RUNNING_STATUS_WORK) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_WORK
    elseif (runningWorkStatus == BYTE_RUNNING_STATUS_PAUSE) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_PAUSE
    elseif (runningWorkStatus == BYTE_RUNNING_STATUS_END) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_END
    elseif (runningWorkStatus == BYTE_RUNNING_STATUS_ERROR) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_ERROR
    elseif (runningWorkStatus == BYTE_RUNNING_STATUS_ORDER) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_ORDER
    end
    if (mode == BYTE_MODE_NORMAL) then
        streams[KEY_MODE] = VALUE_MODE_NORMAL
    elseif (mode == BYTE_MODE_DRY) then
        streams[KEY_MODE] = VALUE_MODE_DRY
    elseif (mode == BYTE_MODE_CONTINUS) then
        streams[KEY_MODE] = VALUE_MODE_CONTINUS
    end
    if program == BYTE_PROGRAM_STANDARD then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_STANDARD
    elseif program == BYTE_PROGRAM_FAST then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_FAST
    elseif program == BYTE_PROGRAM_BLANKE then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_BLANKE
    elseif program == BYTE_PROGRAM_WOOL then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_WOOL
    elseif program == BYTE_PROGRAM_EMBATHE then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_EMBATHE
    elseif program == BYTE_PROGRAM_MEMORY then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_MEMORY
    elseif program == BYTE_PROGRAM_CHILD then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_CHILD
    elseif program == BYTE_PROGRAM_STRONG_WASH then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_STRONG_WASH
    elseif program == BYTE_PROGRAM_DOWN_JACKET then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_DOWN_JACKET
    elseif program == BYTE_PROGRAM_STIR then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_STIR
    elseif program == BYTE_PROGRAM_MUTE then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_MUTE
    elseif program == BYTE_PROGRAM_BUCKET_SELF_CLEAN then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_BUCKET_SELF_CLEAN
    elseif program == BYTE_PROGRAM_AIR_DRY then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_AIR_DRY
    elseif program == BYTE_PROGRAM_CYCLE then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_CYCLE
    elseif program == BYTE_PROGRAM_REMAIN_WATER then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_REMAIN_WATER
    elseif program == BYTE_PROGRAM_SUMMER then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_SUMMER
    elseif program == BYTE_PROGRAM_BIG then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_BIG
    elseif program == BYTE_PROGRAM_HOME then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_HOME
    elseif program == BYTE_PROGRAM_COWBAY then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_COWBAY
    elseif program == BYTE_PROGRAM_SOFT then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_SOFT
    elseif program == BYTE_PROGRAM_HAND_WASH then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_HAND_WASH
    elseif program == BYTE_PROGRAM_WATER_FLOW then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_WATER_FLOW
    elseif program == BYTE_PROGRAM_FOG then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_FOG
    elseif program == BYTE_PROGRAM_BUCKET_DRY then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_BUCKET_DRY
    elseif program == BYTE_PROGRAM_FAST_CLEAN_WASH then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_FAST_CLEAN_WASH
    elseif program == BYTE_PROGRAM_DEHYDRATION then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_DEHYDRATION
    elseif program == BYTE_PROGRAM_UNDER_WEAR then
        streams[KEY_PROGRAM] = VALUE_PROGRAM_UNDER_WEAR
    elseif program == 0x1D then
        streams[KEY_PROGRAM] = 'rinse_dehydration'
    elseif program == 0x1E then
        streams[KEY_PROGRAM] = 'five_clean'
    elseif program == 0x1F then
        streams[KEY_PROGRAM] = 'degerm'
    elseif program == 0x20 then
        streams[KEY_PROGRAM] = 'in_15'
    elseif program == 0x21 then
        streams[KEY_PROGRAM] = 'in_25'
    elseif program == 0x22 then
        streams[KEY_PROGRAM] = 'love_baby'
    elseif program == 0x23 then
        streams[KEY_PROGRAM] = 'outdoor'
    elseif program == 0x24 then
        streams[KEY_PROGRAM] = 'silk'
    elseif program == 0x25 then
        streams[KEY_PROGRAM] = 'shirt'
    elseif program == 0x26 then
        streams[KEY_PROGRAM] = 'cook_wash'
    elseif program == 0x27 then
        streams[KEY_PROGRAM] = 'towel'
    elseif program == 0x28 then
        streams[KEY_PROGRAM] = 'memory_2'
    elseif program == 0x29 then
        streams[KEY_PROGRAM] = 'memory_3'
    elseif program == 0x2A then
        streams[KEY_PROGRAM] = 'half_energy'
    elseif program == 0x2B then
        streams[KEY_PROGRAM] = 'all_energy'
    elseif program == 0x2C then
        streams[KEY_PROGRAM] = 'soft_wash'
    elseif program == 0x2D then
        streams[KEY_PROGRAM] = 'prevent_allergy'
    elseif program == 0x2E then
        streams[KEY_PROGRAM] = 'wash_cube'
    elseif program == 0x2F then
        streams[KEY_PROGRAM] = 'winter_jacket'
    elseif program == 0x30 then
        streams[KEY_PROGRAM] = 'leisure_wash'
    elseif program == 0x31 then
        streams[KEY_PROGRAM] = 'no_iron'
    elseif program == 0xFF then
        streams[KEY_PROGRAM] = 'invalid'
    end
    streams[KEY_WASH_LEVEL] = washLevel
    streams[KEY_RINSE_LEVEL] = rinseLevel
    streams[KEY_WASH_STRENGTH] = washStrength
    streams[KEY_DEHYDRATION_SPEED] = dehydrationSpeed
    streams[KEY_RINSE_COUNT] = rinseCount
    streams[KEY_TEMPERATURE] = temperature
    streams[KEY_DEHYDRATION_TIME] = dehydrationTime
    streams[KEY_WASH_TIME] = washTime
    if lock == BYTE_LOCK_ON then
        streams[KEY_LOCK] = VALUE_ON
    else
        streams[KEY_LOCK] = VALUE_OFF
    end
    if intelligentWash == 0x80 then
        streams[KEY_INTELLIGENT_WASH] = VALUE_ON
    else
        streams[KEY_INTELLIGENT_WASH] = VALUE_OFF
    end
    streams[KEY_REMAIN_TIME] = remainTime
    streams[KEY_ERROR_CODE] = errorCode
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (control) then
        if (status) then updateGlobalPropertyValueByJson(status) end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyLength = 20
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
        bodyBytes[0] = BYTE_CONTROL_REQUEST
        if control[KEY_POWER] ~= nil then bodyBytes[1] = power end
        if control[KEY_PROGRAM] ~= nil then bodyBytes[4] = program end
        if control[KEY_LOCK] ~= nil then
            bodyBytes[7] = bit.bor(lock, intelligentWash)
        end
        if control[KEY_CONTROL_WORK_STATUS] ~= nil then
            bodyBytes[2] = controlWorkStatus
            if (control[KEY_PROGRAM] ~= nil) then
                bodyBytes[4] = program
            end
            if (control[KEY_WASH_LEVEL] ~= nil and control[KEY_RINSE_LEVEL] ~=
                nil) then
                bodyBytes[5] = bit.bor(washLevel, bit.lshift(rinseLevel, 4))
            end
            if (control[KEY_WASH_STRENGTH] ~= nil and
                control[KEY_DEHYDRATION_SPEED] ~= nil) then
                bodyBytes[6] = bit.bor(washStrength,
                                       bit.lshift(dehydrationSpeed, 4))
            end
            bodyBytes[7] = bit.bor(lock, intelligentWash)
            if (control[KEY_WASH_TIME] ~= nil) then
                bodyBytes[9] = washTime
            end
            if (control[KEY_RINSE_COUNT] ~= nil and
                control[KEY_DEHYDRATION_TIME] ~= nil) then
                bodyBytes[10] = bit.bor(rinseCount,
                                        bit.lshift(dehydrationTime, 4))
            end
            if (control[KEY_TEMPERATURE] ~= nil) then
                bodyBytes[15] = bit.bor(0xF0, temperature)
            end
            bodyBytes[12] = 0x00
            bodyBytes[13] = 0x00
            bodyBytes[14] = 0x00
            bodyBytes[17] = 0x7F
            bodyBytes[18] = 0xD5
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    elseif (query) then
        local bodyBytes = {}
        bodyBytes[0] = 0x03
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
    local deviceSubType = deviceinfo['deviceSubType']
    if (deviceSubType == 1) then end
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
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[3] = 0xC4
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

function string2Int(data)
    if (not data) then data = tonumber('0') end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
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
