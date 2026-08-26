local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_POWER = 'power'
local KEY_CONTROL_WORK_STATUS = 'control_status'
local KEY_RUNNING_WORK_STATUS = 'running_status'
local KEY_MODE = 'mode'
local KEY_PROGRAM = 'program'
local KEY_WATER_LEVEL = 'water_level'
local KEY_SOAK_COUNT = 'soak_count'
local KEY_TEMPERATURE = 'temperature'
local KEY_DEHYDRATION_SPEED = 'dehydration_speed'
local KEY_DEHYDRATION_TIME = 'dehydration_time'
local KEY_LOCK = 'lock'
local KEY_REMAIN_TIME = 'remain_time'
local KEY_ERROR_CODE = 'error_code'

local VALUE_VERSION = 14
local VALUE_POWER_ON = 'on'
local VALUE_POWER_OFF = 'off'
local VALUE_CONTROL_WORK_STATUS_START = 'start'
local VALUE_CONTROL_WORK_STATUS_PAUSE = 'pause'
local VALUE_RUNNING_WORK_STATUS_IDLE = 'idle'
local VALUE_RUNNING_WORK_STATUS_STANDBY = 'standby'
local VALUE_RUNNING_WORK_STATUS_START = 'start'
local VALUE_RUNNING_WORK_STATUS_PAUSE = 'pause'
local VALUE_RUNNING_WORK_STATUS_END = 'end'
local VALUE_RUNNING_WORK_STATUS_FAULT = 'fault'
local VALUE_RUNNING_WORK_STATUS_DELAY = 'delay'
local VALUE_MODE_NORMAL = 'normal'
local VALUE_MODE_FACTORY_TEST = 'factory_test'
local VALUE_MODE_SERVICE = 'service'
local VALUE_MODE_NORMAL_CONTINUS = 'normal_continus'
local VALUE_WATER_LEVEL_LOW = 'low'
local VALUE_WATER_LEVEL_MID = 'mid'
local VALUE_WATER_LEVEL_HIGH = 'high'
local VALUE_WATER_LEVEL_AUTO = 'auto'
local VALUE_SOAK_COUNT_1 = '1'
local VALUE_SOAK_COUNT_2 = '2'
local VALUE_SOAK_COUNT_3 = '3'
local VALUE_SOAK_COUNT_4 = '4'
local VALUE_SOAK_COUNT_5 = '5'
local VALUE_TEMPERATURE_00 = '0'
local VALUE_TEMPERATURE_20 = '20'
local VALUE_TEMPERATURE_30 = '30'
local VALUE_TEMPERATURE_40 = '40'
local VALUE_TEMPERATURE_60 = '60'
local VALUE_TEMPERATURE_95 = '95'
local VALUE_DEHYDRATION_SPEED_0 = '0'
local VALUE_DEHYDRATION_SPEED_600 = '600'
local VALUE_DEHYDRATION_SPEED_800 = '800'
local VALUE_DEHYDRATION_SPEED_1000 = '1000'
local VALUE_DEHYDRATION_SPEED_1400 = '1400'
local VALUE_LOCK_ON = 'on'
local VALUE_LOCK_OFF = 'off'

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
local BYTE_PROGRAM_COTTON = 0x00
local BYTE_PROGRAM_ECO = 0x01
local BYTE_PROGRAM_FAST_WASH = 0x02
local BYTE_PROGRAM_MIXED_WASH = 0x03
local BYTE_PROGRAM_FIBER = 0x04
local BYTE_PROGRAM_WOOL = 0x05
local BYTE_PROGRAM_ENZYME = 0x06
local BYTE_PROGRAM_SIMPLE_SELF_PURIFICATION = 0x07
local BYTE_PROGRAM_SPORT_CLOTHES = 0x08
local BYTE_PROGRAM_SINGLE_DEHYTRATION = 0x09
local BYTE_PROGRAM_RINSING_DEHYDRATION = 0x0A
local BYTE_PROGRAM_BIG = 0x0B
local BYTE_PROGRAM_BABY_CLOTHES = 0x0C
local BYTE_PROGRAM_UNDERWEAR = 0x0D
local BYTE_PROGRAM_OUTDOOR = 0x0E
local BYTE_PROGRAM_DOWN_JACKET = 0x0F
local BYTE_PROGRAM_COLOR = 0x10
local BYTE_PROGRAM_INTELLIGENT = 0x11
local BYTE_PROGRAM_QUICK_WASH = 0x12
local BYTE_PROGRAM_KIDS = 0x13
local BYTE_PROGRAM_WATER_COTTON = 0x14
local BYTE_PROGRAM_AIR_WASH = 0x15
local BYTE_PROGRAM_SINGLE_DRYING = 0x16
local BYTE_PROGRAM_FAST_WASH_30 = 0x17
local BYTE_PROGRAM_FAST_WASH_60 = 0x18
local BYTE_PROGRAM_WATER_INTELLIGENT = 0x19
local BYTE_PROGRAM_WATER_STEEP = 0x1A
local BYTE_PROGRAM_WATER_FAST_WASH_30 = 0x1B
local BYTE_PROGRAM_SHIRT = 0x1C
local BYTE_PROGRAM_STEEP = 0x1D
local BYTE_PROGRAM_NEW_WATER_COTTON = 0x1E
local BYTE_PROGRAM_WATER_MIXED_WASH = 0x1F
local BYTE_PROGRAM_WATER_FIBER = 0x20
local BYTE_PROGRAM_WATER_KIDS = 0x21
local BYTE_PROGRAM_WATER_UNDERWEAR = 0x22
local BYTE_PROGRAM_SPECIALIST = 0x23
local BYTE_PROGRAM_LOVE = 0xFE
local BYTE_PROGRAM_WATER_ECO = 0x24
local BYTE_PROGRAM_WASH_DRYING_60 = 0x25
local BYTE_PROGRAM_SELF_WASH_5 = 0x26
local BYTE_PROGRAM_FAST_WASH_MINI = 0x27
local BYTE_PROGRAM_MIXED_WASH_MINI = 0x28
local BYTE_PROGRAM_DEHYDRATION_MINI = 0x29
local BYTE_PROGRAM_SELF_WASH_MINI = 0x2A
local BYTE_PROGRAM_BABY_CLOTHES_MINI = 0x2B
local BYTE_PROGRAM_DIY0 = 0x50
local BYTE_PROGRAM_DIY1 = 0x51
local BYTE_PROGRAM_DIY2 = 0x52
local BYTE_WATER_LEVEL_LOW = 0x01
local BYTE_WATER_LEVEL_MID = 0x02
local BYTE_WATER_LEVEL_HIGH = 0x03
local BYTE_WATER_LEVEL_AUTO = 0x05
local BYTE_SOAK_COUNT_1 = 0x01
local BYTE_SOAK_COUNT_2 = 0x02
local BYTE_SOAK_COUNT_3 = 0x03
local BYTE_SOAK_COUNT_4 = 0x04
local BYTE_SOAK_COUNT_5 = 0x05
local BYTE_TEMPERATURE_00 = 0x01
local BYTE_TEMPERATURE_20 = 0x02
local BYTE_TEMPERATURE_30 = 0x03
local BYTE_TEMPERATURE_40 = 0x04
local BYTE_TEMPERATURE_60 = 0x05
local BYTE_TEMPERATURE_95 = 0x06
local BYTE_DEHYDRATION_SPEED_0 = 0x00
local BYTE_DEHYDRATION_SPEED_600 = 0x02
local BYTE_DEHYDRATION_SPEED_800 = 0x03
local BYTE_DEHYDRATION_SPEED_1000 = 0x04
local BYTE_DEHYDRATION_SPEED_1400 = 0x06
local BYTE_LOCK_ON = 0x20
local BYTE_LOCK_OFF = 0x00

local power = 0
local controlWorkStatus = 0
local runningWorkStatus = 0
local mode = 0
local program = 0
local waterLevel = 0
local soakCount = 0
local temperature = 0
local dehydrationMin = 0
local dehydrationSpeed = 0
local byte13 = 0
local remainTime = 0
local errorCode = 0
local deviceSubType = '0'
local expertStep = 0
local byte16 = 0

function updateGlobalPropertyValueByJson(luaTable)
    if luaTable[KEY_POWER] == VALUE_POWER_ON then
        power = BYTE_POWER_ON
    elseif luaTable[KEY_POWER] == VALUE_POWER_OFF then
        power = BYTE_POWER_OFF
    end
    if luaTable[KEY_CONTROL_WORK_STATUS] == VALUE_CONTROL_WORK_STATUS_PAUSE then
        controlWorkStatus = BYTE_CONTROL_WORK_STATUS_PAUSE
    elseif luaTable[KEY_CONTROL_WORK_STATUS] == VALUE_CONTROL_WORK_STATUS_START then
        controlWorkStatus = BYTE_CONTROL_WORK_STATUS_START
    end
    if luaTable[KEY_RUNNING_WORK_STATUS] == VALUE_RUNNING_WORK_STATUS_IDLE then
        runningWorkStatus = BYTE_RUNNING_WORK_STATUS_IDLE
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == VALUE_RUNNING_WORK_STATUS_PAUSE then
        runningWorkStatus = BYTE_RUNNING_WORK_STATUS_PAUSE
    elseif luaTable[KEY_RUNNING_WORK_STATUS] ==
        VALUE_RUNNING_WORK_STATUS_STANDBY then
        runningWorkStatus = BYTE_RUNNING_WORK_STATUS_STANDBY
    elseif luaTable[KEY_RUNNING_WORK_STATUS] == VALUE_RUNNING_WORK_STATUS_START then
        runningWorkStatus = BYTE_RUNNING_WORK_STATUS_START
    end
    if luaTable[KEY_MODE] == VALUE_MODE_NORMAL then
        mode = BYTE_MODE_NORMAL
    elseif luaTable[KEY_MODE] == VALUE_MODE_FACTORY_TEST then
        mode = BYTE_MODE_FACTORY_TEST
    elseif luaTable[KEY_MODE] == VALUE_MODE_SERVICE then
        mode = BYTE_MODE_SERVICE
    elseif luaTable[KEY_MODE] == VALUE_MODE_NORMAL_CONTINUS then
        mode = BYTE_MODE_NORMAL_CONTINUS
    end
    if luaTable[KEY_PROGRAM] == 'cotton' then
        program = BYTE_PROGRAM_COTTON
    elseif luaTable[KEY_PROGRAM] == 'eco' then
        program = BYTE_PROGRAM_ECO
    elseif luaTable[KEY_PROGRAM] == 'fast_wash' then
        program = BYTE_PROGRAM_FAST_WASH
    elseif luaTable[KEY_PROGRAM] == 'mixed_wash' then
        program = BYTE_PROGRAM_MIXED_WASH
    elseif luaTable[KEY_PROGRAM] == 'wool' then
        program = BYTE_PROGRAM_WOOL
    elseif luaTable[KEY_PROGRAM] == 'ssp' then
        program = BYTE_PROGRAM_SIMPLE_SELF_PURIFICATION
    elseif luaTable[KEY_PROGRAM] == 'sport_clothes' then
        program = BYTE_PROGRAM_SPORT_CLOTHES
    elseif luaTable[KEY_PROGRAM] == 'single_dehytration' then
        program = BYTE_PROGRAM_SINGLE_DEHYTRATION
    elseif luaTable[KEY_PROGRAM] == 'rinsing_dehydration' then
        program = BYTE_PROGRAM_RINSING_DEHYDRATION
    elseif luaTable[KEY_PROGRAM] == 'big' then
        program = BYTE_PROGRAM_BIG
    elseif luaTable[KEY_PROGRAM] == 'baby_clothes' then
        if deviceSubType == '13113' then
            program = BYTE_PROGRAM_KIDS
        else
            program = BYTE_PROGRAM_BABY_CLOTHES
        end
    elseif luaTable[KEY_PROGRAM] == 'down_jacket' then
        program = BYTE_PROGRAM_DOWN_JACKET
    elseif luaTable[KEY_PROGRAM] == 'color' then
        program = BYTE_PROGRAM_COLOR
    elseif luaTable[KEY_PROGRAM] == 'intelligent' then
        program = BYTE_PROGRAM_INTELLIGENT
    elseif luaTable[KEY_PROGRAM] == 'quick_wash' then
        program = BYTE_PROGRAM_QUICK_WASH
    elseif luaTable[KEY_PROGRAM] == 'shirt' then
        program = BYTE_PROGRAM_SHIRT
    elseif luaTable[KEY_PROGRAM] == 'fiber' then
        program = BYTE_PROGRAM_FIBER
    elseif luaTable[KEY_PROGRAM] == 'enzyme' then
        program = BYTE_PROGRAM_ENZYME
    elseif luaTable[KEY_PROGRAM] == 'underwear' then
        program = BYTE_PROGRAM_UNDERWEAR
    elseif luaTable[KEY_PROGRAM] == 'outdoor' then
        program = BYTE_PROGRAM_OUTDOOR
    elseif luaTable[KEY_PROGRAM] == 'air_wash' then
        program = BYTE_PROGRAM_AIR_WASH
    elseif luaTable[KEY_PROGRAM] == 'single_drying' then
        program = BYTE_PROGRAM_SINGLE_DRYING
    elseif luaTable[KEY_PROGRAM] == 'steep' then
        program = BYTE_PROGRAM_STEEP
    elseif luaTable[KEY_PROGRAM] == 'kids' then
        program = BYTE_PROGRAM_KIDS
    elseif luaTable[KEY_PROGRAM] == 'water_cotton' then
        program = BYTE_PROGRAM_WATER_COTTON
    elseif luaTable[KEY_PROGRAM] == 'fast_wash_30' then
        program = BYTE_PROGRAM_FAST_WASH_30
    elseif luaTable[KEY_PROGRAM] == 'fast_wash_60' then
        program = BYTE_PROGRAM_FAST_WASH_60
    elseif luaTable[KEY_PROGRAM] == 'water_mixed_wash' then
        program = BYTE_PROGRAM_WATER_MIXED_WASH
    elseif luaTable[KEY_PROGRAM] == 'water_fiber' then
        program = BYTE_PROGRAM_WATER_FIBER
    elseif luaTable[KEY_PROGRAM] == 'water_kids' then
        program = BYTE_PROGRAM_WATER_KIDS
    elseif luaTable[KEY_PROGRAM] == 'water_underwear' then
        program = BYTE_PROGRAM_WATER_UNDERWEAR
    elseif luaTable[KEY_PROGRAM] == 'specialist' then
        program = BYTE_PROGRAM_SPECIALIST
    elseif luaTable[KEY_PROGRAM] == 'love' then
        program = BYTE_PROGRAM_LOVE
    elseif luaTable[KEY_PROGRAM] == 'water_intelligent' then
        program = BYTE_PROGRAM_WATER_INTELLIGENT
    elseif luaTable[KEY_PROGRAM] == 'water_steep' then
        program = BYTE_PROGRAM_WATER_STEEP
    elseif luaTable[KEY_PROGRAM] == 'water_fast_wash_30' then
        program = BYTE_PROGRAM_WATER_FAST_WASH_30
    elseif luaTable[KEY_PROGRAM] == 'new_water_cotton' then
        program = BYTE_PROGRAM_NEW_WATER_COTTON
    elseif luaTable[KEY_PROGRAM] == 'water_eco' then
        program = BYTE_PROGRAM_WATER_ECO
    elseif luaTable[KEY_PROGRAM] == 'wash_drying_60' then
        program = BYTE_PROGRAM_WASH_DRYING_60
    elseif luaTable[KEY_PROGRAM] == 'self_wash_5' then
        program = BYTE_PROGRAM_SELF_WASH_5
    elseif luaTable[KEY_PROGRAM] == 'fast_wash_min' then
        program = BYTE_PROGRAM_FAST_WASH_MINI
    elseif luaTable[KEY_PROGRAM] == 'mixed_wash_min' then
        program = BYTE_PROGRAM_MIXED_WASH_MINI
    elseif luaTable[KEY_PROGRAM] == 'dehydration_min' then
        program = BYTE_PROGRAM_DEHYDRATION_MINI
    elseif luaTable[KEY_PROGRAM] == 'self_wash_min' then
        program = BYTE_PROGRAM_SELF_WASH_MINI
    elseif luaTable[KEY_PROGRAM] == 'baby_clothes_min' then
        program = BYTE_PROGRAM_BABY_CLOTHES_MINI
    elseif luaTable[KEY_PROGRAM] == 'diy0' then
        program = BYTE_PROGRAM_DIY0
    elseif luaTable[KEY_PROGRAM] == 'diy1' then
        program = BYTE_PROGRAM_DIY1
    elseif luaTable[KEY_PROGRAM] == 'diy2' then
        program = BYTE_PROGRAM_DIY2
    end
    if luaTable[KEY_WATER_LEVEL] == VALUE_WATER_LEVEL_LOW then
        waterLevel = BYTE_WATER_LEVEL_LOW
    elseif luaTable[KEY_WATER_LEVEL] == VALUE_WATER_LEVEL_MID then
        waterLevel = BYTE_WATER_LEVEL_MID
    elseif luaTable[KEY_WATER_LEVEL] == VALUE_WATER_LEVEL_HIGH then
        waterLevel = BYTE_WATER_LEVEL_HIGH
    elseif luaTable[KEY_WATER_LEVEL] == VALUE_WATER_LEVEL_AUTO then
        waterLevel = BYTE_WATER_LEVEL_AUTO
    elseif luaTable[KEY_WATER_LEVEL] == 'invalid' then
        waterLevel = 0xFF
    end
    if luaTable[KEY_SOAK_COUNT] == VALUE_SOAK_COUNT_1 then
        soakCount = BYTE_SOAK_COUNT_1
    elseif luaTable[KEY_SOAK_COUNT] == VALUE_SOAK_COUNT_2 then
        soakCount = BYTE_SOAK_COUNT_2
    elseif luaTable[KEY_SOAK_COUNT] == VALUE_SOAK_COUNT_3 then
        soakCount = BYTE_SOAK_COUNT_3
    elseif luaTable[KEY_SOAK_COUNT] == VALUE_SOAK_COUNT_4 then
        soakCount = BYTE_SOAK_COUNT_4
    elseif luaTable[KEY_SOAK_COUNT] == '0' then
        soakCount = 0x00
    end
    if luaTable[KEY_TEMPERATURE] == VALUE_TEMPERATURE_00 then
        temperature = BYTE_TEMPERATURE_00
    elseif luaTable[KEY_TEMPERATURE] == VALUE_TEMPERATURE_20 then
        temperature = BYTE_TEMPERATURE_20
    elseif luaTable[KEY_TEMPERATURE] == VALUE_TEMPERATURE_30 then
        temperature = BYTE_TEMPERATURE_30
    elseif luaTable[KEY_TEMPERATURE] == VALUE_TEMPERATURE_40 then
        temperature = BYTE_TEMPERATURE_40
    elseif luaTable[KEY_TEMPERATURE] == VALUE_TEMPERATURE_60 then
        temperature = BYTE_TEMPERATURE_60
    elseif luaTable[KEY_TEMPERATURE] == VALUE_TEMPERATURE_95 then
        temperature = BYTE_TEMPERATURE_95
    elseif luaTable[KEY_TEMPERATURE] == 'invalid' then
        temperature = 0xFF
    end
    if luaTable[KEY_DEHYDRATION_TIME] ~= nil then
        dehydrationMin = luaTable[KEY_DEHYDRATION_TIME]
    end
    if luaTable[KEY_DEHYDRATION_SPEED] == VALUE_DEHYDRATION_SPEED_0 then
        dehydrationSpeed = BYTE_DEHYDRATION_SPEED_0
    elseif luaTable[KEY_DEHYDRATION_SPEED] == VALUE_DEHYDRATION_SPEED_600 then
        dehydrationSpeed = BYTE_DEHYDRATION_SPEED_600
    elseif luaTable[KEY_DEHYDRATION_SPEED] == VALUE_DEHYDRATION_SPEED_800 then
        dehydrationSpeed = BYTE_DEHYDRATION_SPEED_800
    elseif luaTable[KEY_DEHYDRATION_SPEED] == VALUE_DEHYDRATION_SPEED_1000 then
        dehydrationSpeed = BYTE_DEHYDRATION_SPEED_1000
    elseif luaTable[KEY_DEHYDRATION_SPEED] == VALUE_DEHYDRATION_SPEED_1400 then
        dehydrationSpeed = BYTE_DEHYDRATION_SPEED_1400
    end
    if luaTable[KEY_LOCK] == VALUE_LOCK_ON then
        byte13 = bit.bor(byte13, BYTE_LOCK_ON)
    elseif luaTable[KEY_LOCK] == VALUE_LOCK_OFF then
        byte13 = bit.bor(byte13, BYTE_LOCK_OFF)
    end
    if luaTable['beforehand_wash'] == 'on' then
        byte16 = bit.bor(byte16, 0x01)
    elseif luaTable['beforehand_wash'] == 'off' then
        byte16 = bit.bor(byte16, 0x00)
    end
    if luaTable['super_clean_wash'] == 'on' then
        byte16 = bit.bor(byte16, 0x02)
    elseif luaTable['super_clean_wash'] == 'off' then
        byte16 = bit.bor(byte16, 0x00)
    end
    if luaTable['intelligent_wash'] == 'on' then
        byte16 = bit.bor(byte16, 0x04)
    elseif luaTable['intelligent_wash'] == 'off' then
        byte16 = bit.bor(byte16, 0x00)
    end
    if luaTable['strong_wash'] == 'on' then
        byte16 = bit.bor(byte16, 0x08)
    elseif luaTable['strong_wash'] == 'off' then
        byte16 = bit.bor(byte16, 0x00)
    end
    if luaTable['steam_wash'] == 'on' then
        byte16 = bit.bor(byte16, 0x10)
    elseif luaTable['steam_wash'] == 'off' then
        byte16 = bit.bor(byte16, 0x00)
    end
    if luaTable['fast_clean_wash'] == 'on' then
        byte16 = bit.bor(byte16, 0x20)
    elseif luaTable['fast_clean_wash'] == 'off' then
        byte16 = bit.bor(byte16, 0x00)
    end
end

function updateGlobalPropertyValueByByte(messageBytes)
    if (#messageBytes == 0) then return nil end
    if (dataType == 0x02 or dataType == 0x03 or dataType == 0x04) then
        power = messageBytes[1]
        runningWorkStatus = messageBytes[2]
        mode = messageBytes[3]
        program = messageBytes[4]
        waterLevel = messageBytes[5]
        soakCount = bit.rshift(bit.band(messageBytes[6], 0xF0), 4)
        temperature = messageBytes[7]
        dehydrationSpeed = messageBytes[8]
        dehydrationMin = messageBytes[10]
        byte13 = messageBytes[13]
        remainTime = messageBytes[17] + bit.lshift(messageBytes[18], 8)
        if messageBytes[24] ~= nil then errorCode = messageBytes[24] end
        if messageBytes[25] ~= nil then byte16 = messageBytes[25] end
        expertStep = messageBytes[19]
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
        streams[KEY_POWER] = VALUE_POWER_ON
    elseif (power == BYTE_POWER_OFF) then
        streams[KEY_POWER] = VALUE_POWER_OFF
    end
    if (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_START) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_START
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_PAUSE) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_PAUSE
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_STANDBY) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_STANDBY
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_END) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_END
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_FAULT) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_FAULT
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_DELAY) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_DELAY
    elseif (runningWorkStatus == BYTE_RUNNING_WORK_STATUS_IDLE) then
        streams[KEY_RUNNING_WORK_STATUS] = VALUE_RUNNING_WORK_STATUS_IDLE
    end
    if (mode == BYTE_MODE_NORMAL) then
        streams[KEY_MODE] = VALUE_MODE_NORMAL
    elseif (mode == BYTE_MODE_FACTORY_TEST) then
        streams[KEY_MODE] = VALUE_MODE_FACTORY_TEST
    elseif (mode == BYTE_MODE_SERVICE) then
        streams[KEY_MODE] = VALUE_MODE_SERVICE
    elseif (mode == BYTE_MODE_NORMAL_CONTINUS) then
        streams[KEY_MODE] = VALUE_MODE_NORMAL_CONTINUS
    end
    if program == BYTE_PROGRAM_COTTON then
        streams[KEY_PROGRAM] = 'cotton'
    elseif program == BYTE_PROGRAM_ECO then
        streams[KEY_PROGRAM] = 'eco'
    elseif program == BYTE_PROGRAM_FAST_WASH then
        streams[KEY_PROGRAM] = 'fast_wash'
    elseif program == BYTE_PROGRAM_MIXED_WASH then
        streams[KEY_PROGRAM] = 'mixed_wash'
    elseif program == BYTE_PROGRAM_WOOL then
        streams[KEY_PROGRAM] = 'wool'
    elseif program == BYTE_PROGRAM_SIMPLE_SELF_PURIFICATION then
        streams[KEY_PROGRAM] = 'ssp'
    elseif program == BYTE_PROGRAM_SPORT_CLOTHES then
        streams[KEY_PROGRAM] = 'sport_clothes'
    elseif program == BYTE_PROGRAM_SINGLE_DEHYTRATION then
        streams[KEY_PROGRAM] = 'single_dehytration'
    elseif program == BYTE_PROGRAM_RINSING_DEHYDRATION then
        streams[KEY_PROGRAM] = 'rinsing_dehydration'
    elseif program == BYTE_PROGRAM_BIG then
        streams[KEY_PROGRAM] = 'big'
    elseif program == BYTE_PROGRAM_BABY_CLOTHES then
        streams[KEY_PROGRAM] = 'baby_clothes'
    elseif program == BYTE_PROGRAM_DOWN_JACKET then
        streams[KEY_PROGRAM] = 'down_jacket'
    elseif program == BYTE_PROGRAM_COLOR then
        streams[KEY_PROGRAM] = 'color'
    elseif program == BYTE_PROGRAM_INTELLIGENT then
        streams[KEY_PROGRAM] = 'intelligent'
    elseif program == BYTE_PROGRAM_QUICK_WASH then
        streams[KEY_PROGRAM] = 'quick_wash'
    elseif program == BYTE_PROGRAM_SHIRT then
        streams[KEY_PROGRAM] = 'shirt'
    elseif program == BYTE_PROGRAM_FIBER then
        streams[KEY_PROGRAM] = 'fiber'
    elseif program == BYTE_PROGRAM_ENZYME then
        streams[KEY_PROGRAM] = 'enzyme'
    elseif program == BYTE_PROGRAM_UNDERWEAR then
        streams[KEY_PROGRAM] = 'underwear'
    elseif program == BYTE_PROGRAM_OUTDOOR then
        streams[KEY_PROGRAM] = 'outdoor'
    elseif program == BYTE_PROGRAM_AIR_WASH then
        streams[KEY_PROGRAM] = 'air_wash'
    elseif program == BYTE_PROGRAM_SINGLE_DRYING then
        streams[KEY_PROGRAM] = 'single_drying'
    elseif program == BYTE_PROGRAM_STEEP then
        streams[KEY_PROGRAM] = 'steep'
    elseif program == BYTE_PROGRAM_KIDS then
        if deviceSubType == '13113' then
            streams[KEY_PROGRAM] = 'baby_clothes'
        else
            streams[KEY_PROGRAM] = 'kids'
        end
    elseif program == BYTE_PROGRAM_WATER_COTTON then
        streams[KEY_PROGRAM] = 'water_cotton'
    elseif program == BYTE_PROGRAM_FAST_WASH_30 then
        streams[KEY_PROGRAM] = 'fast_wash_30'
    elseif program == BYTE_PROGRAM_FAST_WASH_60 then
        streams[KEY_PROGRAM] = 'fast_wash_60'
    elseif program == BYTE_PROGRAM_WATER_MIXED_WASH then
        streams[KEY_PROGRAM] = 'water_mixed_wash'
    elseif program == BYTE_PROGRAM_WATER_FIBER then
        streams[KEY_PROGRAM] = 'water_fiber'
    elseif program == BYTE_PROGRAM_WATER_KIDS then
        streams[KEY_PROGRAM] = 'water_kids'
    elseif program == BYTE_PROGRAM_WATER_UNDERWEAR then
        streams[KEY_PROGRAM] = 'water_underwear'
    elseif program == BYTE_PROGRAM_SPECIALIST then
        streams[KEY_PROGRAM] = 'specialist'
    elseif program == BYTE_PROGRAM_LOVE then
        streams[KEY_PROGRAM] = 'love'
    elseif program == BYTE_PROGRAM_WATER_INTELLIGENT then
        streams[KEY_PROGRAM] = 'water_intelligent'
    elseif program == BYTE_PROGRAM_WATER_STEEP then
        streams[KEY_PROGRAM] = 'water_steep'
    elseif program == BYTE_PROGRAM_WATER_FAST_WASH_30 then
        streams[KEY_PROGRAM] = 'water_fast_wash_30'
    elseif program == BYTE_PROGRAM_NEW_WATER_COTTON then
        streams[KEY_PROGRAM] = 'new_water_cotton'
    elseif program == BYTE_PROGRAM_WATER_ECO then
        streams[KEY_PROGRAM] = 'water_eco'
    elseif program == BYTE_PROGRAM_WASH_DRYING_60 then
        streams[KEY_PROGRAM] = 'wash_drying_60'
    elseif program == BYTE_PROGRAM_SELF_WASH_5 then
        streams[KEY_PROGRAM] = 'self_wash_5'
    elseif program == BYTE_PROGRAM_FAST_WASH_MINI then
        streams[KEY_PROGRAM] = 'fast_wash_min'
    elseif program == BYTE_PROGRAM_MIXED_WASH_MINI then
        streams[KEY_PROGRAM] = 'mixed_wash_min'
    elseif program == BYTE_PROGRAM_DEHYDRATION_MINI then
        streams[KEY_PROGRAM] = 'dehydration_min'
    elseif program == BYTE_PROGRAM_SELF_WASH_MINI then
        streams[KEY_PROGRAM] = 'self_wash_min'
    elseif program == BYTE_PROGRAM_BABY_CLOTHES_MINI then
        streams[KEY_PROGRAM] = 'baby_clothes_min'
    elseif program == BYTE_PROGRAM_DIY0 then
        streams[KEY_PROGRAM] = 'diy0'
    elseif program == BYTE_PROGRAM_DIY1 then
        streams[KEY_PROGRAM] = 'diy1'
    elseif program == BYTE_PROGRAM_DIY2 then
        streams[KEY_PROGRAM] = 'diy2'
    end
    if waterLevel == BYTE_WATER_LEVEL_LOW then
        streams[KEY_WATER_LEVEL] = VALUE_WATER_LEVEL_LOW
    elseif waterLevel == BYTE_WATER_LEVEL_MID then
        streams[KEY_WATER_LEVEL] = VALUE_WATER_LEVEL_MID
    elseif waterLevel == BYTE_WATER_LEVEL_HIGH then
        streams[KEY_WATER_LEVEL] = VALUE_WATER_LEVEL_HIGH
    elseif waterLevel == BYTE_WATER_LEVEL_AUTO then
        streams[KEY_WATER_LEVEL] = VALUE_WATER_LEVEL_AUTO
    else
        streams[KEY_WATER_LEVEL] = 'invalid'
    end
    if soakCount == BYTE_SOAK_COUNT_1 then
        streams[KEY_SOAK_COUNT] = VALUE_SOAK_COUNT_1
    elseif soakCount == BYTE_SOAK_COUNT_2 then
        streams[KEY_SOAK_COUNT] = VALUE_SOAK_COUNT_2
    elseif soakCount == BYTE_SOAK_COUNT_3 then
        streams[KEY_SOAK_COUNT] = VALUE_SOAK_COUNT_3
    elseif soakCount == BYTE_SOAK_COUNT_4 then
        streams[KEY_SOAK_COUNT] = VALUE_SOAK_COUNT_4
    elseif soakCount == BYTE_SOAK_COUNT_5 then
        streams[KEY_SOAK_COUNT] = VALUE_SOAK_COUNT_5
    elseif soakCount == 0x00 then
        streams[KEY_SOAK_COUNT] = '0'
    end
    if temperature == BYTE_TEMPERATURE_00 then
        streams[KEY_TEMPERATURE] = VALUE_TEMPERATURE_00
    elseif temperature == BYTE_TEMPERATURE_20 then
        streams[KEY_TEMPERATURE] = VALUE_TEMPERATURE_20
    elseif temperature == BYTE_TEMPERATURE_30 then
        streams[KEY_TEMPERATURE] = VALUE_TEMPERATURE_30
    elseif temperature == BYTE_TEMPERATURE_40 then
        streams[KEY_TEMPERATURE] = VALUE_TEMPERATURE_40
    elseif temperature == BYTE_TEMPERATURE_60 then
        streams[KEY_TEMPERATURE] = VALUE_TEMPERATURE_60
    elseif temperature == BYTE_TEMPERATURE_95 then
        streams[KEY_TEMPERATURE] = VALUE_TEMPERATURE_95
    else
        streams[KEY_TEMPERATURE] = 'invalid'
    end
    streams[KEY_DEHYDRATION_TIME] = dehydrationMin
    if dehydrationSpeed == BYTE_DEHYDRATION_SPEED_0 then
        streams[KEY_DEHYDRATION_SPEED] = VALUE_DEHYDRATION_SPEED_0
    elseif dehydrationSpeed == BYTE_DEHYDRATION_SPEED_600 then
        streams[KEY_DEHYDRATION_SPEED] = VALUE_DEHYDRATION_SPEED_600
    elseif dehydrationSpeed == BYTE_DEHYDRATION_SPEED_800 then
        streams[KEY_DEHYDRATION_SPEED] = VALUE_DEHYDRATION_SPEED_800
    elseif dehydrationSpeed == BYTE_DEHYDRATION_SPEED_1000 then
        streams[KEY_DEHYDRATION_SPEED] = VALUE_DEHYDRATION_SPEED_1000
    elseif dehydrationSpeed == BYTE_DEHYDRATION_SPEED_1400 then
        streams[KEY_DEHYDRATION_SPEED] = VALUE_DEHYDRATION_SPEED_1400
    end
    if bit.band(byte13, BYTE_LOCK_ON) == BYTE_LOCK_ON then
        streams[KEY_LOCK] = VALUE_LOCK_ON
    else
        streams[KEY_LOCK] = VALUE_LOCK_OFF
    end
    if bit.band(byte16, 0x01) == 0x01 then
        streams['beforehand_wash'] = 'on'
    else
        streams['beforehand_wash'] = 'off'
    end
    if bit.band(byte16, 0x02) == 0x02 then
        streams['super_clean_wash'] = 'on'
    else
        streams['super_clean_wash'] = 'off'
    end
    if bit.band(byte16, 0x04) == 0x04 then
        streams['intelligent_wash'] = 'on'
    else
        streams['intelligent_wash'] = 'off'
    end
    if bit.band(byte16, 0x08) == 0x08 then
        streams['strong_wash'] = 'on'
    else
        streams['strong_wash'] = 'off'
    end
    if bit.band(byte16, 0x10) == 0x10 then
        streams['steam_wash'] = 'on'
    else
        streams['steam_wash'] = 'off'
    end
    if bit.band(byte16, 0x20) == 0x20 then
        streams['fast_clean_wash'] = 'on'
    else
        streams['fast_clean_wash'] = 'off'
    end
    streams[KEY_REMAIN_TIME] = remainTime
    streams[KEY_ERROR_CODE] = errorCode
    streams['expert_step'] = expertStep
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes = {}
    local json = decodeJsonToTable(jsonCmdStr)
    deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (control) then
        if (status) then updateGlobalPropertyValueByJson(status) end
        if (control) then updateGlobalPropertyValueByJson(control) end
        local bodyLength = 22
        local bodyBytes = {}
        for i = 0, bodyLength - 1 do bodyBytes[i] = 0xFF end
        bodyBytes[0] = BYTE_CONTROL_REQUEST
        if control[KEY_POWER] ~= nil then
            bodyBytes[1] = power
        else
            if control[KEY_CONTROL_WORK_STATUS] ~= nil then
                bodyBytes[2] = controlWorkStatus
            end
            bodyBytes[4] = program
            bodyBytes[5] = waterLevel
            bodyBytes[6] = bit.lshift(soakCount, 4)
            bodyBytes[7] = temperature
            bodyBytes[8] = dehydrationSpeed
            bodyBytes[10] = dehydrationMin
            bodyBytes[13] = byte13
            bodyBytes[16] = byte16
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
    deviceSubType = deviceinfo['deviceSubType']
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
