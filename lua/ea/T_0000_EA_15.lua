local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_WORK_STATUS = 'work_status'
local KEY_MODE = 'mode'
local KEY_MOUTHFEEL = 'mouthfeel'
local KEY_RICE_TYPE = 'rice_type'
local KEY_ERROR_CODE = 'error_code'
local KEY_ORDER_TIME_HOUR = 'order_time_hour'
local KEY_ORDER_TIME_MIN = 'order_time_min'
local KEY_LEFT_TIME_HOUR = 'left_time_hour'
local KEY_LEFT_TIME_MIN = 'left_time_min'
local KEY_WARM_TIME_HOUR = 'warm_time_hour'
local KEY_WARM_TIME_MIN = 'warm_time_min'
local KEY_VOLTAGE = 'voltage'
local KEY_INDOOR_TEMPERATURE = 'indoor_temperature'
local KEY_TOP_TEMPERATURE = 'top_temperature'
local KEY_BOTTOM_TEMPERATURE = 'bottom_temperature'
local KEY_WORK_STAGE = 'work_stage'
local KEY_WORK_FLAG = 'work_flag'
local KEY_RICE_LEVEL = 'rice_level'

local VALUE_VERSION = 15
local VALUE_WORK_STATUS_KEEP_WARM = 'keep_warm'
local VALUE_WORK_STATUS_SCHEDULE = 'schedule'
local VALUE_BYTE_COOKING = 'cooking'
local VALUE_BYTE_CANCEL = 'cancel'
local VALUE_BYTE_COOK_RICE = 'cook_rice'
local VALUE_BYTE_FAST_COOK_RICE = 'fast_cook_rice'
local VALUE_BYTE_STANDARD_COOK_RICE = 'standard_cook_rice'
local VALUE_BYTE_GRUEL = 'gruel'
local VALUE_BYTE_COOK_CONGEE = 'cook_congee'
local VALUE_BYTE_STEW_SOUP = 'stew_soup'
local VALUE_BYTE_STEWING = 'stewing'
local VALUE_BYTE_HEAT_RICE = 'heat_rice'
local VALUE_BYTE_MAKE_CAKE = 'make_cake'
local VALUE_BYTE_YOGHOURT = 'yoghourt'
local VALUE_BYTE_SOUP_RICE = 'soup_rice'
local VALUE_BYTE_COARSE_RICE = 'coarse_rice'
local VALUE_BYTE_FIVE_CEREALS_RICE = 'five_ceeals_rice'
local VALUE_BYTE_EIGHT_TREASURES_RICE = 'eight_treasures_rice'
local VALUE_BYTE_CRISPY_RICE = 'crispy_rice'
local VALUE_BYTE_SHELLED_RICE = 'shelled_rice'
local VALUE_BYTE_EIGHT_TREASURES_CONGEE = 'eight_treasures_congee'
local VALUE_BYTE_INFANT_CONGEE = 'infant_congee'
local VALUE_BYTE_OLDER_RICE = 'older_rice'
local VALUE_BYTE_RICE_SOUP = 'rice_soup'
local VALUE_BYTE_RICE_PASTE = 'rice_paste'
local VALUE_BYTE_EGG_CUSTARD = 'egg_custard'
local VALUE_BYTE_WARM_MILK = 'warm_milk'
local VALUE_BYTE_HOT_SPRING_GEE = 'hot_spring_egg'
local VALUE_BYTE_MILLET_CONGEE = 'millet_congee'
local VALUE_BYTE_FIREWOOD_RICE = 'firewood_rice'
local VALUE_BYTE_FEW_RICE = 'few_rice'
local VALUE_BYTE_RED_POTATO = 'red_potato'
local VALUE_BYTE_CORN = 'corn'
local VALUE_BYTE_QUICK_FREEZE_BUN = 'quick_freeze_bun'
local VALUE_BYTE_STEAM_RIBS = 'steam_ribs'
local VALUE_BYTE_STEAM_EGG = 'steam_egg'
local VALUE_BYTE_COARSE_CONGEE = 'coarse_congee'
local VALUE_BYTE_STEEP_RICE = 'steep_rice'
local VALUE_BYTE_APPETIZING_CONGEE = 'appetizing_congee'
local VALUE_BYTE_CORN_CONGEE = 'corn_congee'
local VALUE_BYTE_SPROUT_RICE = 'sprout_rice'
local VALUE_BYTE_LUSCIOUS_RICE = 'luscious_rice'
local VALUE_BYTE_LUSCIOUS_BOILED = 'luscious_boiled'
local VALUE_BYTE_FAST_RICE = 'fast_rice'
local VALUE_BYTE_FAST_BOIL = 'fast_boil'
local VALUE_BYTE_BEAN_RICE_CONGEE = 'bean_rice_congee'
local VALUE_BYTE_FAST_CONGEE = 'fast_congee'
local VALUE_BYTE_BABY_CONGEE = 'baby_congee'
local VALUE_BYTE_COOK_SOUP = 'cook_soup'
local VALUE_BYTE_CONGEE_SOUP = 'congee_coup'
local VALUE_BYTE_STEAM_CORN = 'steam_corn'
local VALUE_BYTE_STEAM_RED_POTATO = 'steam_red_potato'
local VALUE_BYTE_BOIL_CONGEE = 'boil_congee'
local VALUE_BYTE_DELICIOUS_STEAM = 'delicious_steam'
local VALUE_BYTE_BOIL_EGG = 'boil_egg'
local VALUE_BYTE_KEEP_WARM = 'keep_warm'
local VALUE_BYTE_DIY = 'diy'
local VALUE_MOUTHFEEL_NONE = 'none'
local VALUE_MOUTHFEEL_SOFT = 'soft'
local VALUE_MOUTHFEEL_MIDDLE = 'middle'
local VALUE_MOUTHFEEL_HARD = 'hard'
local VALUE_RICE_TYPE_NONE = 'none'
local VALUE_RICE_TYPE_NORTHEAST = 'northeast'
local VALUE_RICE_TYPE_LONGRAIN = 'longrain'
local VALUE_RICE_TYPE_FRAGRANT = 'fragrant'
local VALUE_RICE_TYPE_FIVE = 'five'

local BYTE_DEVICE_TYPE = 0xEA
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_STATUS_KEEP_WARM = 0x03
local BYTE_SCHEDULE = 0x02
local BYTE_COOKING = 0x01
local BYTE_CANCEL = 0x00
local BYTE_COOK_RICE = 0x02
local BYTE_FAST_COOK_RICE = 0x03
local BYTE_STANDARD_COOK_RICE = 0x04
local BYTE_GRUEL = 0x05
local BYTE_COOK_CONGEE = 0x06
local BYTE_STEW_SOUP = 0x07
local BYTE_STEWING = 0x08
local BYTE_HEAT_RICE = 0x09
local BYTE_MAKE_CAKE = 0x0A
local BYTE_YOGHOURT = 0x0B
local BYTE_SOUP_RICE = 0x0C
local BYTE_COARSE_RICE = 0x0D
local BYTE_FIVE_CEREALS_RICE = 0x0E
local BYTE_EIGHT_TREASURES_RICE = 0x0F
local BYTE_CRISPY_RICE = 0x10
local BYTE_SHELLED_RICE = 0x11
local BYTE_EIGHT_TREASURES_CONGEE = 0x12
local BYTE_INFANT_CONGEE = 0x13
local BYTE_OLDER_RICE = 0x14
local BYTE_RICE_SOUP = 0x15
local BYTE_RICE_PASTE = 0x16
local BYTE_EGG_CUSTARD = 0x17
local BYTE_WARM_MILK = 0x18
local BYTE_HOT_SPRING_GEE = 0x19
local BYTE_MILLET_CONGEE = 0x1A
local BYTE_FIREWOOD_RICE = 0x1B
local BYTE_FEW_RICE = 0x1C
local BYTE_RED_POTATO = 0x1D
local BYTE_CORN = 0x1E
local BYTE_QUICK_FREEZE_BUN = 0x1F
local BYTE_STEAM_RIBS = 0x20
local BYTE_STEAM_EGG = 0x21
local BYTE_COARSE_CONGEE = 0x22
local BYTE_STEEP_RICE = 0x23
local BYTE_APPETIZING_CONGEE = 0x24
local BYTE_CORN_CONGEE = 0x25
local BYTE_SPROUT_RICE = 0x26
local BYTE_LUSCIOUS_RICE = 0x27
local BYTE_LUSCIOUS_BOILED = 0x28
local BYTE_FAST_RICE = 0x29
local BYTE_FAST_BOIL = 0x2A
local BYTE_BEAN_RICE_CONGEE = 0x2B
local BYTE_FAST_CONGEE = 0x2C
local BYTE_BABY_CONGEE = 0x2D
local BYTE_COOK_SOUP = 0x2E
local BYTE_CONGEE_SOUP = 0x2F
local BYTE_STEAM_CORN = 0x30
local BYTE_STEAM_RED_POTATO = 0x31
local BYTE_BOIL_CONGEE = 0x32
local BYTE_DELICIOUS_STEAM = 0x33
local BYTE_BOIL_EGG = 0x34
local BYTE_KEEP_WARM = 0xC6
local BYTE_DIY = 0xC7
local BYTE_MOUTHFEEL_NONE = 0x00
local BYTE_MOUTHFEEL_SOFT = 0x01
local BYTE_MOUTHFEEL_MIDDLE = 0x02
local BYTE_MOUTHFEEL_HARD = 0x03
local BYTE_RICE_TYPE_NONE = 0x00
local BYTE_RICE_TYPE_NORTHEAST = 0x01
local BYTE_RICE_TYPE_LONGRAIN = 0x02
local BYTE_RICE_TYPE_FRAGRANT = 0x03
local BYTE_RICE_TYPE_FIVE = 0x04

local workstatus = 0
local mode = 0
local mouthFeel = 0
local riceType = 0
local errorCode = 0
local orderHour = 0
local orderMin = 0
local leftHour = 0
local leftMin = 0
local warmHour = 0
local warmMin = 0
local voltage = 0
local indoorTemperature = 0
local topTemperature = 0
local bottomTemperature = 0
local workStage = 0
local workFlag = 0
local riceLevel = 0
local riceCupNumber = 0
local washNumber = 0
local soakMode = 0
local stepExpectTime = 0
local stepActualTime = 0
local storageVolumeLevel = 0
local storageTemp = 0
local storageHumodity = 0
local storageExpectCup = 0
local storageType = 0
local cuisineEnd = 0
local showTime = 0
local dryBraised = 0
local matRice = 0
local hotCuisine = 0
local flankHot = 0
local topHot = 0
local bottomHot = 0
local dataType = 0
local deviceSubType = 0

local function getSoftVersion()
    if (deviceSubType == '0' or deviceSubType == '1' or deviceSubType == '3' or
        deviceSubType == '4' or deviceSubType == '5' or deviceSubType == '6') then
        return 0
    elseif (deviceSubType == '3000' or deviceSubType == 3000) then
        return 2
    elseif (deviceSubType == '39' or deviceSubType == '40' or deviceSubType ==
        '41' or deviceSubType == '42' or deviceSubType == '43') then
        return 3
    else
        return 1
    end
end

local function jsonToModel(luaTable)
    if (luaTable[KEY_WORK_STATUS] ~= nil) then
        if luaTable[KEY_WORK_STATUS] == VALUE_WORK_STATUS_KEEP_WARM then
            workstatus = BYTE_STATUS_KEEP_WARM
        elseif luaTable[KEY_WORK_STATUS] == VALUE_WORK_STATUS_SCHEDULE then
            if (getSoftVersion() == 3) then
                workstatus = BYTE_COOKING
            else
                workstatus = BYTE_SCHEDULE
            end
        elseif luaTable[KEY_WORK_STATUS] == VALUE_BYTE_COOKING then
            if (getSoftVersion() == 3) then
                workstatus = BYTE_SCHEDULE
            else
                workstatus = BYTE_COOKING
            end
        elseif luaTable[KEY_WORK_STATUS] == VALUE_BYTE_CANCEL then
            workstatus = BYTE_CANCEL
        else
            workstatus = string2Int(luaTable[KEY_WORK_STATUS])
        end
    end
    if (luaTable[KEY_MODE] ~= nil) then
        if luaTable[KEY_MODE] == VALUE_BYTE_COOK_RICE then
            mode = BYTE_COOK_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_FAST_COOK_RICE then
            mode = BYTE_FAST_COOK_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_STANDARD_COOK_RICE then
            mode = BYTE_STANDARD_COOK_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_GRUEL then
            mode = BYTE_GRUEL
        elseif luaTable[KEY_MODE] == VALUE_BYTE_COOK_CONGEE then
            mode = BYTE_COOK_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_STEW_SOUP then
            mode = BYTE_STEW_SOUP
        elseif luaTable[KEY_MODE] == VALUE_BYTE_STEWING then
            mode = BYTE_STEWING
        elseif (luaTable[KEY_MODE] == VALUE_BYTE_HEAT_RICE) then
            mode = BYTE_HEAT_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_MAKE_CAKE then
            mode = BYTE_MAKE_CAKE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_YOGHOURT then
            mode = BYTE_YOGHOURT
        elseif luaTable[KEY_MODE] == VALUE_BYTE_SOUP_RICE then
            mode = BYTE_SOUP_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_COARSE_RICE then
            mode = BYTE_COARSE_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_FIVE_CEREALS_RICE then
            mode = BYTE_FIVE_CEREALS_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_EIGHT_TREASURES_RICE then
            mode = BYTE_EIGHT_TREASURES_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_CRISPY_RICE then
            mode = BYTE_CRISPY_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_SHELLED_RICE then
            mode = BYTE_SHELLED_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_EIGHT_TREASURES_CONGEE then
            mode = BYTE_EIGHT_TREASURES_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_INFANT_CONGEE then
            mode = BYTE_INFANT_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_OLDER_RICE then
            mode = BYTE_OLDER_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_RICE_SOUP then
            mode = BYTE_RICE_SOUP
        elseif luaTable[KEY_MODE] == VALUE_BYTE_RICE_PASTE then
            mode = BYTE_RICE_PASTE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_EGG_CUSTARD then
            mode = BYTE_EGG_CUSTARD
        elseif luaTable[KEY_MODE] == VALUE_BYTE_WARM_MILK then
            mode = BYTE_WARM_MILK
        elseif luaTable[KEY_MODE] == VALUE_BYTE_HOT_SPRING_GEE then
            mode = BYTE_HOT_SPRING_GEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_MILLET_CONGEE then
            mode = BYTE_MILLET_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_FIREWOOD_RICE then
            if (getSoftVersion() == 1 or getSoftVersion() == 2 or
                getSoftVersion() == 3) then mode = BYTE_FIREWOOD_RICE end
        elseif luaTable[KEY_MODE] == VALUE_BYTE_FEW_RICE then
            mode = BYTE_FEW_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_RED_POTATO then
            mode = BYTE_RED_POTATO
        elseif luaTable[KEY_MODE] == VALUE_BYTE_CORN then
            mode = BYTE_CORN
        elseif luaTable[KEY_MODE] == VALUE_BYTE_QUICK_FREEZE_BUN then
            mode = BYTE_QUICK_FREEZE_BUN
        elseif luaTable[KEY_MODE] == VALUE_BYTE_STEAM_RIBS then
            mode = BYTE_STEAM_RIBS
        elseif luaTable[KEY_MODE] == VALUE_BYTE_STEAM_EGG then
            mode = BYTE_STEAM_EGG
        elseif luaTable[KEY_MODE] == VALUE_BYTE_COARSE_CONGEE then
            mode = BYTE_COARSE_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_STEEP_RICE then
            mode = BYTE_STEEP_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_APPETIZING_CONGEE then
            mode = BYTE_APPETIZING_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_CORN_CONGEE then
            mode = BYTE_CORN_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_SPROUT_RICE then
            mode = BYTE_SPROUT_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_LUSCIOUS_RICE then
            mode = BYTE_LUSCIOUS_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_LUSCIOUS_BOILED then
            mode = BYTE_LUSCIOUS_BOILED
        elseif luaTable[KEY_MODE] == VALUE_BYTE_FAST_RICE then
            mode = BYTE_FAST_RICE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_FAST_BOIL then
            mode = BYTE_FAST_BOIL
        elseif luaTable[KEY_MODE] == VALUE_BYTE_BEAN_RICE_CONGEE then
            mode = BYTE_BEAN_RICE_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_FAST_CONGEE then
            mode = BYTE_FAST_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_BABY_CONGEE then
            mode = BYTE_BABY_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_COOK_SOUP then
            mode = BYTE_COOK_SOUP
        elseif luaTable[KEY_MODE] == VALUE_BYTE_CONGEE_SOUP then
            mode = BYTE_CONGEE_SOUP
        elseif luaTable[KEY_MODE] == VALUE_BYTE_STEAM_CORN then
            mode = BYTE_STEAM_CORN
        elseif luaTable[KEY_MODE] == VALUE_BYTE_STEAM_RED_POTATO then
            mode = BYTE_STEAM_RED_POTATO
        elseif luaTable[KEY_MODE] == VALUE_BYTE_BOIL_CONGEE then
            mode = BYTE_BOIL_CONGEE
        elseif luaTable[KEY_MODE] == VALUE_BYTE_DELICIOUS_STEAM then
            mode = BYTE_DELICIOUS_STEAM
        elseif luaTable[KEY_MODE] == VALUE_BYTE_BOIL_EGG then
            mode = BYTE_BOIL_EGG
        elseif luaTable[KEY_MODE] == VALUE_BYTE_KEEP_WARM then
            mode = BYTE_KEEP_WARM
        elseif luaTable[KEY_MODE] == VALUE_BYTE_DIY then
            mode = BYTE_DIY
        elseif luaTable[KEY_MODE] == 'rice_wine' then
            mode = 0x35
        elseif luaTable[KEY_MODE] == 'fruit_vegetable_paste' then
            mode = 0x36
        elseif luaTable[KEY_MODE] == 'vegetable_porridge' then
            mode = 0x37
        elseif luaTable[KEY_MODE] == 'pork_porridge' then
            mode = 0x38
        elseif luaTable[KEY_MODE] == 'fragrant_rice' then
            mode = 0x39
        elseif luaTable[KEY_MODE] == 'assorte_rice' then
            mode = 0x3A
        elseif luaTable[KEY_MODE] == 'steame_fish' then
            mode = 0x3B
        elseif luaTable[KEY_MODE] == 'baby_rice' then
            mode = 0x3C
        elseif luaTable[KEY_MODE] == 'essence_rice' then
            mode = 0x3D
        elseif luaTable[KEY_MODE] == 'fragrant_dense_congee' then
            mode = 0x3E
        elseif luaTable[KEY_MODE] == 'one_two_cook' then
            mode = 0x3F
        elseif luaTable[KEY_MODE] == 'original_steame' then
            mode = 0x40
        elseif luaTable[KEY_MODE] == 'hot_fast_rice' then
            mode = 0x41
        else
            mode = string2Int(luaTable[KEY_MODE])
        end
    end
    if (luaTable[KEY_MOUTHFEEL] ~= nil) then
        if luaTable[KEY_MOUTHFEEL] == VALUE_MOUTHFEEL_NONE then
            mouthFeel = BYTE_MOUTHFEEL_NONE
        elseif luaTable[KEY_MOUTHFEEL] == VALUE_MOUTHFEEL_SOFT then
            mouthFeel = BYTE_MOUTHFEEL_SOFT
        elseif luaTable[KEY_MOUTHFEEL] == VALUE_MOUTHFEEL_MIDDLE then
            mouthFeel = BYTE_MOUTHFEEL_MIDDLE
        elseif luaTable[KEY_MOUTHFEEL] == VALUE_MOUTHFEEL_HARD then
            mouthFeel = BYTE_MOUTHFEEL_HARD
        else
            mouthFeel = string2Int(luaTable[KEY_MOUTHFEEL])
        end
    end
    if (luaTable[KEY_RICE_TYPE] ~= nil) then
        if luaTable[KEY_RICE_TYPE] == VALUE_RICE_TYPE_NONE then
            riceType = BYTE_RICE_TYPE_NONE
        elseif luaTable[KEY_RICE_TYPE] == VALUE_RICE_TYPE_NORTHEAST then
            riceType = BYTE_RICE_TYPE_NORTHEAST
        elseif luaTable[KEY_RICE_TYPE] == VALUE_RICE_TYPE_LONGRAIN then
            riceType = BYTE_RICE_TYPE_LONGRAIN
        elseif luaTable[KEY_RICE_TYPE] == VALUE_RICE_TYPE_FRAGRANT then
            riceType = BYTE_RICE_TYPE_FRAGRANT
        elseif luaTable[KEY_RICE_TYPE] == VALUE_RICE_TYPE_FIVE then
            riceType = BYTE_RICE_TYPE_FIVE
        else
            riceType = string2Int(luaTable[KEY_RICE_TYPE])
        end
    end
    if luaTable[KEY_ORDER_TIME_HOUR] ~= nil then
        orderHour = string2Int(luaTable[KEY_ORDER_TIME_HOUR])
    end
    if luaTable[KEY_ORDER_TIME_MIN] ~= nil then
        orderMin = string2Int(luaTable[KEY_ORDER_TIME_MIN])
    end
    if luaTable[KEY_LEFT_TIME_HOUR] ~= nil then
        leftHour = string2Int(luaTable[KEY_LEFT_TIME_HOUR])
    end
    if luaTable[KEY_LEFT_TIME_MIN] ~= nil then
        leftMin = string2Int(luaTable[KEY_LEFT_TIME_MIN])
    end
    if (luaTable['rice_cup_volume'] ~= nil) then
        if (luaTable['rice_cup_volume'] == 2) then
            riceCupNumber = 0x00
        else
            riceCupNumber = string2Int(luaTable['rice_cup_volume']) / 0.25
        end
    end
    if (luaTable['wash_number'] ~= nil) then
        if (luaTable['wash_number'] == 0) then
            washNumber = 1
        else
            washNumber = checkBoundary(luaTable['wash_number'], 1, 7)
        end
    end
    if (luaTable['soak_mode'] ~= nil) then
        if (luaTable['soak_mode'] == 'quality_soak') then
            soakMode = 0x00
        elseif (luaTable['soak_mode'] == 'fast_soak') then
            soakMode = 0x01
        end
    end
end

function binToModel(messageBytes)
    if (#messageBytes == 0) then return nil end
    if getSoftVersion() == 1 or getSoftVersion() == 3 then
        if ((dataType == 0x02 and messageBytes[3] == 0x02) or
            (dataType == 0x03 and messageBytes[3] == 0x03) or
            (dataType == 0x04 and messageBytes[3] == 0x04)) then
            mode = messageBytes[4] + bit.lshift(messageBytes[5], 8)
            workstatus = messageBytes[8]
            errorCode = messageBytes[9]
            orderHour = messageBytes[10]
            orderMin = messageBytes[11]
            leftHour = messageBytes[12]
            leftMin = messageBytes[13]
            warmHour = messageBytes[22]
            warmMin = messageBytes[23]
            mouthFeel = messageBytes[14]
            riceType = messageBytes[15] + bit.lshift(messageBytes[16], 8)
            voltage = messageBytes[24] + bit.lshift(messageBytes[25], 8)
            indoorTemperature = messageBytes[26]
            topTemperature = messageBytes[20]
            bottomTemperature = messageBytes[21]
            workStage = messageBytes[19]
            workFlag = messageBytes[18]
            riceLevel = messageBytes[17]
        end
    elseif getSoftVersion() == 2 then
        if ((dataType == 0x02 and messageBytes[3] == 0x02) or
            (dataType == 0x03 and messageBytes[3] == 0x03) or
            (dataType == 0x04 and messageBytes[3] == 0x04)) then
            mode = messageBytes[4] + bit.lshift(messageBytes[5], 8)
            workstatus = messageBytes[8]
            errorCode = messageBytes[9]
            orderHour = messageBytes[10]
            orderMin = messageBytes[11]
            leftHour = messageBytes[12]
            leftMin = messageBytes[13]
            warmHour = messageBytes[22]
            warmMin = messageBytes[23]
            mouthFeel = messageBytes[14]
            riceType = messageBytes[15] + bit.lshift(messageBytes[16], 8)
            voltage = messageBytes[24] + bit.lshift(messageBytes[25], 8)
            indoorTemperature = messageBytes[26]
            topTemperature = messageBytes[20]
            bottomTemperature = messageBytes[21]
            workStage = messageBytes[19]
            riceCupNumber = messageBytes[32]
            stepExpectTime = messageBytes[33] + messageBytes[34] * 255
            stepActualTime = messageBytes[35] + messageBytes[36] * 255
            storageVolumeLevel = messageBytes[37]
            storageTemp = messageBytes[38]
            storageHumodity = messageBytes[39]
            storageExpectCup = messageBytes[40]
            storageType = messageBytes[41] + messageBytes[42] * 255
            workFlag = messageBytes[18]
            riceLevel = messageBytes[17]
        end
    else
        if (dataType == 0x02 and messageBytes[5] == 22) then
            mode = messageBytes[6] + bit.lshift(messageBytes[7], 8)
            mouthFeel = messageBytes[9]
            riceType = messageBytes[12] + bit.lshift(messageBytes[13], 8)
            workstatus = messageBytes[14]
            orderHour = messageBytes[20]
            orderMin = messageBytes[21]
            leftHour = messageBytes[22]
            leftMin = messageBytes[23]
            warmHour = messageBytes[26]
            warmMin = messageBytes[27]
            topTemperature = messageBytes[18]
            bottomTemperature = messageBytes[19]
            workStage = messageBytes[17]
            if (#messageBytes > 31) then
                voltage = messageBytes[30] + bit.lshift(messageBytes[31], 8)
            end
            if (#messageBytes > 32) then
                indoorTemperature = messageBytes[32]
            end
        end
        if (dataType == 0x03) then
            if (messageBytes[6] == 0x52 and messageBytes[7] == 0xC3) then
                mode = messageBytes[58] + bit.lshift(messageBytes[59], 8)
                mouthFeel = messageBytes[45]
                riceType = messageBytes[46] + bit.lshift(messageBytes[47], 8)
                workstatus = messageBytes[9]
                orderHour = messageBytes[48]
                orderMin = messageBytes[49]
                leftHour = messageBytes[50]
                leftMin = messageBytes[51]
                warmHour = messageBytes[54]
                warmMin = messageBytes[55]
                voltage = messageBytes[24] + bit.lshift(messageBytes[25], 8)
                indoorTemperature = messageBytes[26]
                topTemperature = messageBytes[21]
                bottomTemperature = messageBytes[20]
                workStage = messageBytes[43]
            elseif (messageBytes[5] == 0x3D) then
                mode = messageBytes[6] + bit.lshift(messageBytes[7], 8)
                mouthFeel = messageBytes[9]
                riceType = messageBytes[12] + bit.lshift(messageBytes[13], 8)
                workstatus = messageBytes[14]
                orderHour = messageBytes[20]
                orderMin = messageBytes[21]
                leftHour = messageBytes[22]
                leftMin = messageBytes[23]
                warmHour = messageBytes[26]
                warmMin = messageBytes[27]
                topTemperature = messageBytes[18]
                bottomTemperature = messageBytes[19]
                workStage = messageBytes[17]
                if (#messageBytes > 31) then
                    voltage = messageBytes[30] + bit.lshift(messageBytes[31], 8)
                end
                if (#messageBytes > 32) then
                    indoorTemperature = messageBytes[32]
                end
            else
                mode = messageBytes[6] + bit.lshift(messageBytes[7], 8)
                mouthFeel = messageBytes[9]
                riceType = messageBytes[12] + bit.lshift(messageBytes[13], 8)
                workstatus = messageBytes[14]
                orderHour = messageBytes[20]
                orderMin = messageBytes[21]
                leftHour = messageBytes[22]
                leftMin = messageBytes[23]
                warmHour = messageBytes[26]
                warmMin = messageBytes[27]
                if (#messageBytes > 31) then
                    voltage = messageBytes[30] + bit.lshift(messageBytes[31], 8)
                end
                if (#messageBytes > 32) then
                    indoorTemperature = messageBytes[32]
                end
                topTemperature = messageBytes[18]
                bottomTemperature = messageBytes[19]
                workStage = messageBytes[17]
            end
        end
        if dataType == 0x04 then
            if messageBytes[5] == 61 then
                mode = messageBytes[6] + bit.lshift(messageBytes[7], 8)
                workstatus = messageBytes[14]
                riceType = messageBytes[12] + bit.lshift(messageBytes[13], 8)
                mouthFeel = messageBytes[9]
                orderHour = messageBytes[20]
                orderMin = messageBytes[21]
                leftHour = messageBytes[22]
                leftMin = messageBytes[23]
                warmHour = messageBytes[26]
                warmMin = messageBytes[27]
                if (#messageBytes > 31) then
                    voltage = messageBytes[30] + bit.lshift(messageBytes[31], 8)
                end
                if (#messageBytes > 32) then
                    indoorTemperature = messageBytes[32]
                end
                topTemperature = messageBytes[18]
                bottomTemperature = messageBytes[19]
                workStage = messageBytes[17]
                workFlag = messageBytes[15]
                riceLevel = messageBytes[8]
            end
            if messageBytes[5] == 69 then errorCode = messageBytes[8] end
        end
    end
end

function assembleJsonByGlobalProperty()
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (workstatus == BYTE_STATUS_KEEP_WARM) then
        streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_KEEP_WARM
    elseif (workstatus == BYTE_SCHEDULE) then
        if (getSoftVersion() == 3) then
            streams[KEY_WORK_STATUS] = VALUE_BYTE_COOKING
        else
            streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_SCHEDULE
        end
    elseif workstatus == BYTE_COOKING then
        if (getSoftVersion() == 3) then
            streams[KEY_WORK_STATUS] = VALUE_WORK_STATUS_SCHEDULE
        else
            streams[KEY_WORK_STATUS] = VALUE_BYTE_COOKING
        end
    elseif workstatus == BYTE_CANCEL then
        streams[KEY_WORK_STATUS] = VALUE_BYTE_CANCEL
    else
        streams[KEY_WORK_STATUS] = int2String(workstatus)
    end
    if (mode == BYTE_COOK_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_COOK_RICE
    elseif (mode == BYTE_FAST_COOK_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_FAST_COOK_RICE
    elseif (mode == BYTE_STANDARD_COOK_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_STANDARD_COOK_RICE
    elseif (mode == BYTE_GRUEL) then
        streams[KEY_MODE] = VALUE_BYTE_GRUEL
    elseif (mode == BYTE_COOK_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_COOK_CONGEE
    elseif (mode == BYTE_STEW_SOUP) then
        streams[KEY_MODE] = VALUE_BYTE_STEW_SOUP
    elseif (mode == BYTE_STEWING) then
        streams[KEY_MODE] = VALUE_BYTE_STEWING
    elseif (mode == BYTE_HEAT_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_HEAT_RICE
    elseif (mode == BYTE_MAKE_CAKE) then
        streams[KEY_MODE] = VALUE_BYTE_MAKE_CAKE
    elseif (mode == BYTE_YOGHOURT) then
        streams[KEY_MODE] = VALUE_BYTE_YOGHOURT
    elseif (mode == BYTE_SOUP_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_SOUP_RICE
    elseif (mode == BYTE_COARSE_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_COARSE_RICE
    elseif (mode == BYTE_FIVE_CEREALS_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_FIVE_CEREALS_RICE
    elseif (mode == BYTE_EIGHT_TREASURES_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_EIGHT_TREASURES_RICE
    elseif (mode == BYTE_CRISPY_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_CRISPY_RICE
    elseif (mode == BYTE_SHELLED_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_SHELLED_RICE
    elseif (mode == BYTE_EIGHT_TREASURES_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_EIGHT_TREASURES_CONGEE
    elseif (mode == BYTE_INFANT_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_INFANT_CONGEE
    elseif (mode == BYTE_OLDER_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_OLDER_RICE
    elseif (mode == BYTE_RICE_SOUP) then
        streams[KEY_MODE] = VALUE_BYTE_RICE_SOUP
    elseif (mode == BYTE_RICE_PASTE) then
        streams[KEY_MODE] = VALUE_BYTE_RICE_PASTE
    elseif (mode == BYTE_EGG_CUSTARD) then
        streams[KEY_MODE] = VALUE_BYTE_EGG_CUSTARD
    elseif (mode == BYTE_WARM_MILK) then
        streams[KEY_MODE] = VALUE_BYTE_WARM_MILK
    elseif (mode == BYTE_HOT_SPRING_GEE) then
        streams[KEY_MODE] = VALUE_BYTE_HOT_SPRING_GEE
    elseif (mode == BYTE_MILLET_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_MILLET_CONGEE
    elseif (mode == BYTE_FIREWOOD_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_FIREWOOD_RICE
    elseif (mode == BYTE_FEW_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_FEW_RICE
    elseif (mode == BYTE_RED_POTATO) then
        streams[KEY_MODE] = VALUE_BYTE_RED_POTATO
    elseif (mode == BYTE_CORN) then
        streams[KEY_MODE] = VALUE_BYTE_CORN
    elseif (mode == BYTE_QUICK_FREEZE_BUN) then
        streams[KEY_MODE] = VALUE_BYTE_QUICK_FREEZE_BUN
    elseif (mode == BYTE_STEAM_RIBS) then
        streams[KEY_MODE] = VALUE_BYTE_STEAM_RIBS
    elseif (mode == BYTE_STEAM_EGG) then
        streams[KEY_MODE] = VALUE_BYTE_STEAM_EGG
    elseif (mode == BYTE_COARSE_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_COARSE_CONGEE
    elseif (mode == BYTE_STEEP_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_STEEP_RICE
    elseif (mode == BYTE_APPETIZING_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_APPETIZING_CONGEE
    elseif (mode == BYTE_CORN_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_CORN_CONGEE
    elseif (mode == BYTE_SPROUT_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_SPROUT_RICE
    elseif (mode == BYTE_LUSCIOUS_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_LUSCIOUS_RICE
    elseif (mode == BYTE_LUSCIOUS_BOILED) then
        streams[KEY_MODE] = VALUE_BYTE_LUSCIOUS_BOILED
    elseif (mode == BYTE_FAST_RICE) then
        streams[KEY_MODE] = VALUE_BYTE_FAST_RICE
    elseif (mode == BYTE_FAST_BOIL) then
        streams[KEY_MODE] = VALUE_BYTE_FAST_BOIL
    elseif (mode == BYTE_BEAN_RICE_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_BEAN_RICE_CONGEE
    elseif (mode == BYTE_FAST_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_FAST_CONGEE
    elseif (mode == BYTE_BABY_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_BABY_CONGEE
    elseif (mode == BYTE_COOK_SOUP) then
        streams[KEY_MODE] = VALUE_BYTE_COOK_SOUP
    elseif (mode == BYTE_CONGEE_SOUP) then
        streams[KEY_MODE] = VALUE_BYTE_CONGEE_SOUP
    elseif (mode == BYTE_STEAM_CORN) then
        streams[KEY_MODE] = VALUE_BYTE_STEAM_CORN
    elseif (mode == BYTE_STEAM_RED_POTATO) then
        streams[KEY_MODE] = VALUE_BYTE_STEAM_RED_POTATO
    elseif (mode == BYTE_BOIL_CONGEE) then
        streams[KEY_MODE] = VALUE_BYTE_BOIL_CONGEE
    elseif (mode == BYTE_DELICIOUS_STEAM) then
        streams[KEY_MODE] = VALUE_BYTE_DELICIOUS_STEAM
    elseif (mode == BYTE_BOIL_EGG) then
        streams[KEY_MODE] = VALUE_BYTE_BOIL_EGG
    elseif (mode == BYTE_KEEP_WARM) then
        streams[KEY_MODE] = VALUE_BYTE_KEEP_WARM
    elseif (mode == BYTE_DIY) then
        streams[KEY_MODE] = VALUE_BYTE_DIY
    elseif (mode == 0x35) then
        streams[KEY_MODE] = 'rice_wine'
    elseif (mode == 0x36) then
        streams[KEY_MODE] = 'fruit_vegetable_paste'
    elseif (mode == 0x37) then
        streams[KEY_MODE] = 'vegetable_porridge'
    elseif (mode == 0x38) then
        streams[KEY_MODE] = 'pork_porridge'
    elseif (mode == 0x39) then
        streams[KEY_MODE] = 'fragrant_rice'
    elseif (mode == 0x3A) then
        streams[KEY_MODE] = 'assorte_rice'
    elseif (mode == 0x3B) then
        streams[KEY_MODE] = 'steame_fish'
    elseif (mode == 0x3C) then
        streams[KEY_MODE] = 'baby_rice'
    elseif (mode == 0x3D) then
        streams[KEY_MODE] = 'essence_rice'
    elseif (mode == 0x3E) then
        streams[KEY_MODE] = 'fragrant_dense_congee'
    elseif (mode == 0x3F) then
        streams[KEY_MODE] = 'one_two_cook'
    elseif (mode == 0x40) then
        streams[KEY_MODE] = 'original_steame'
    elseif (mode == 0x41) then
        streams[KEY_MODE] = 'hot_fast_rice'
    else
        streams[KEY_MODE] = int2String(mode)
    end
    if (mouthFeel == BYTE_MOUTHFEEL_NONE) then
        streams[KEY_MOUTHFEEL] = VALUE_MOUTHFEEL_NONE
    elseif (mouthFeel == BYTE_MOUTHFEEL_SOFT) then
        streams[KEY_MOUTHFEEL] = VALUE_MOUTHFEEL_SOFT
    elseif (mouthFeel == BYTE_MOUTHFEEL_MIDDLE) then
        streams[KEY_MOUTHFEEL] = VALUE_MOUTHFEEL_MIDDLE
    elseif (mouthFeel == BYTE_MOUTHFEEL_HARD) then
        streams[KEY_MOUTHFEEL] = VALUE_MOUTHFEEL_HARD
    else
        streams[KEY_MOUTHFEEL] = int2String(mouthFeel)
    end
    if (riceType == BYTE_RICE_TYPE_NONE) then
        streams[KEY_RICE_TYPE] = VALUE_RICE_TYPE_NONE
    elseif (riceType == BYTE_RICE_TYPE_NORTHEAST) then
        streams[KEY_RICE_TYPE] = VALUE_RICE_TYPE_NORTHEAST
    elseif (riceType == BYTE_RICE_TYPE_LONGRAIN) then
        streams[KEY_RICE_TYPE] = VALUE_RICE_TYPE_LONGRAIN
    elseif (riceType == BYTE_RICE_TYPE_FRAGRANT) then
        streams[KEY_RICE_TYPE] = VALUE_RICE_TYPE_FRAGRANT
    elseif (riceType == BYTE_RICE_TYPE_FIVE) then
        streams[KEY_RICE_TYPE] = VALUE_RICE_TYPE_FIVE
    else
        streams[KEY_RICE_TYPE] = int2String(riceType)
    end
    streams[KEY_ERROR_CODE] = errorCode
    streams[KEY_ORDER_TIME_HOUR] = orderHour
    streams[KEY_ORDER_TIME_MIN] = orderMin
    streams[KEY_LEFT_TIME_HOUR] = leftHour
    streams[KEY_LEFT_TIME_MIN] = leftMin
    streams[KEY_WARM_TIME_HOUR] = warmHour
    streams[KEY_WARM_TIME_MIN] = warmMin
    streams[KEY_VOLTAGE] = voltage
    streams[KEY_INDOOR_TEMPERATURE] = indoorTemperature
    streams[KEY_TOP_TEMPERATURE] = topTemperature
    streams[KEY_BOTTOM_TEMPERATURE] = bottomTemperature
    streams[KEY_WORK_STAGE] = workStage
    if (riceLevel ~= nil) then streams[KEY_RICE_LEVEL] = riceLevel end
    if (workFlag ~= nil) then streams[KEY_WORK_FLAG] = workFlag end
    if (workFlag ~= nil) then
        if (workFlag == 0x80) then
            streams['cuisine_end'] = 1
        elseif (workFlag == 0x00) then
            streams['cuisine_end'] = 0
        end
    end
    if (workFlag ~= nil) then
        if (workFlag == 0x40) then
            streams['show_time'] = 1
        elseif (workFlag == 0x00) then
            streams['show_time'] = 0
        end
    end
    if (workFlag ~= nil) then
        if (workFlag == 0x20) then
            streams['dry_braised'] = 1
        elseif (workFlag == 0x00) then
            streams['dry_braised'] = 0
        end
    end
    if (workFlag ~= nil) then
        if (workFlag == 0x10) then
            streams['mat_rice'] = 1
        elseif (workFlag == 0x00) then
            streams['mat_rice'] = 0
        end
    end
    if (workFlag ~= nil) then
        if (workFlag == 0x08) then
            streams['hot_cuisine'] = 1
        elseif (workFlag == 0x00) then
            streams['hot_cuisine'] = 0
        end
    end
    if (workFlag ~= nil) then
        if (workFlag == 0x04) then
            streams['flank_hot'] = 1
        elseif (workFlag == 0x00) then
            streams['flank_hot'] = 0
        end
    end
    if (workFlag ~= nil) then
        if (workFlag == 0x02) then
            streams['top_hot'] = 1
        elseif (workFlag == 0x00) then
            streams['top_hot'] = 0
        end
    end
    if (workFlag ~= nil) then
        if (workFlag == 0x01) then
            streams['bottom_hot'] = 1
        elseif (workFlag == 0x00) then
            streams['bottom_hot'] = 0
        end
    end
    if (riceCupNumber ~= nil) then
        if (riceCupNumber == 0x00 or riceCupNumber == 0x08) then
            streams['rice_cup_volume'] = 2
        else
            streams['rice_cup_volume'] = riceCupNumber / 4
        end
    end
    if (stepExpectTime ~= nil) then
        if (stepExpectTime <= 1) then
            streams['step_expect_time'] = 1
        else
            streams['step_expect_time'] = stepExpectTime
        end
    end
    if (stepActualTime ~= nil) then
        streams['step_actual_time'] = stepActualTime
    end
    if (storageVolumeLevel ~= nil) then
        if (storageVolumeLevel == 0x01) then
            streams['storage_volume_level'] = 'least'
        elseif (storageVolumeLevel == 0x02) then
            streams['storage_volume_level'] = 'lesser'
        elseif (storageVolumeLevel == 0x03) then
            streams['storage_volume_level'] = 'half'
        elseif (storageVolumeLevel == 0x04) then
            streams['storage_volume_level'] = 'enough'
        elseif (storageVolumeLevel == 0xFF) then
            streams['storage_volume_level'] = 'error'
        end
    end
    if (storageTemp ~= nil) then streams['storage_temp'] = storageTemp end
    if (storageHumodity ~= nil) then
        streams['storage_humodity'] = storageHumodity
    end
    if (storageExpectCup ~= nil) then
        if (storageExpectCup == 0x00 or storageExpectCup == 0x08) then
            streams['storage_cup_volume'] = 2
        else
            streams['storage_cup_volume'] = storageExpectCup / 4
        end
    end
    if (storageType ~= nil) then
        if (storageType == 0x00) then
            streams['storage_rice_type'] = 'none'
        elseif (storageType == 0xFF) then
            streams['storage_rice_type'] = 'discern'
        else
            streams['storage_rice_type'] = int2String(storageType)
        end
    end
    return streams
end

function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then return nil end
    local msgBytes
    local json = decode(jsonCmdStr)
    deviceSubType = json['deviceinfo']['deviceSubType']
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (control) then
        if getSoftVersion() == 1 or getSoftVersion() == 3 then
            if (status) then jsonToModel(status) end
            if (control) then jsonToModel(control) end
            local bodyLength = 16
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x00
            bodyBytes[3] = 0x02
            bodyBytes[4] = bit.band(mode, 0xFF)
            bodyBytes[5] = bit.band(bit.rshift(mode, 8), 0xFF)
            bodyBytes[8] = workstatus
            bodyBytes[9] = orderHour
            bodyBytes[10] = orderMin
            bodyBytes[11] = leftHour
            bodyBytes[12] = leftMin
            bodyBytes[13] = mouthFeel
            bodyBytes[14] = bit.band(riceType, 0xFF)
            bodyBytes[bodyLength - 1] = makeSum(bodyBytes, 0, bodyLength - 2)
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        elseif (getSoftVersion() == 2) then
            if (status) then jsonToModel(status) end
            if (control) then jsonToModel(control) end
            local bodyLength = 74
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x00
            bodyBytes[3] = 0x02
            bodyBytes[4] = bit.band(mode, 0xFF)
            bodyBytes[5] = bit.band(bit.rshift(mode, 8), 0xFF)
            bodyBytes[8] = workstatus
            bodyBytes[9] = orderHour
            bodyBytes[10] = orderMin
            bodyBytes[11] = leftHour
            bodyBytes[12] = leftMin
            bodyBytes[13] = mouthFeel
            bodyBytes[14] = bit.band(riceType, 0xFF)
            bodyBytes[16] = riceCupNumber
            bodyBytes[17] = washNumber
            bodyBytes[18] = soakMode
            bodyBytes[bodyLength - 1] = makeSum(bodyBytes, 0, bodyLength - 2)
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
            msgBytes[8] = 0x02
        else
            if (status) then jsonToModel(status) end
            if (control) then jsonToModel(control) end
            local bodyLength = 25
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x01
            bodyBytes[3] = 0x00
            bodyBytes[4] = 0x19
            bodyBytes[5] = 0x02
            if control[KEY_WORK_STATUS] ~= 'cancel' then
                bodyBytes[6] = bit.band(mode, 0xFF)
                bodyBytes[7] = bit.band(bit.rshift(mode, 8), 0xFF)
            end
            bodyBytes[8] = mouthFeel
            bodyBytes[11] = riceType
            bodyBytes[13] = workstatus
            bodyBytes[16] = orderHour
            bodyBytes[17] = orderMin
            bodyBytes[18] = leftHour
            bodyBytes[19] = leftMin
            bodyBytes[bodyLength - 1] = makeSum(bodyBytes, 0, bodyLength - 2)
            msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        end
    elseif (query) then
        if getSoftVersion() == 1 or getSoftVersion() == 3 then
            local bodyLength = 5
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x00
            bodyBytes[3] = 0x03
            bodyBytes[4] = 0x00
            msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
        elseif (getSoftVersion() == 2) then
            local bodyLength = 5
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x00
            bodyBytes[3] = 0x03
            bodyBytes[4] = 0x00
            msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
            msgBytes[8] = 0x02
        else
            local bodyLength = 23
            local bodyBytes = {}
            for i = 0, bodyLength - 1 do bodyBytes[i] = 0 end
            bodyBytes[0] = 0xAA
            bodyBytes[1] = 0x55
            bodyBytes[2] = 0x01
            bodyBytes[4] = 0x17
            bodyBytes[5] = 0x02
            if (deviceSubType == '1') then
                bodyBytes[6] = 0x52
                bodyBytes[bodyLength - 1] = 0xD2
            else
                bodyBytes[6] = 0x55
                bodyBytes[bodyLength - 1] = 0xCF
            end
            bodyBytes[7] = 0xC3
            msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
        end
    end
    local infoM = {}
    local length = #msgBytes + 1
    for i = 1, length do infoM[i] = msgBytes[i - 1] end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    if control then
        for key, value in pairs(control) do
            if key == 'work_status' then
                if (getSoftVersion() == 1 or getSoftVersion() == 3) and
                    control[key] == 'cancel' then
                    ret =
                        'AA1AEA00000000000102AA550002000000000000000000000000F8'
                    print('特殊')
                end
            end
        end
    end
    return ret
end

function dataToJson(jsonStr)
    if (not jsonStr) then return nil end
    local json = decode(jsonStr)
    local deviceinfo = json['deviceinfo']
    deviceSubType = deviceinfo['deviceSubType']
    local binData = json['msg']['data']
    local status = json['status']
    if (status) then jsonToModel(status) end
    local bodyBytes = {}
    local byteData = string2table(binData)
    dataType = byteData[10]
    bodyBytes = extractBodyBytes(byteData)
    local ret = binToModel(bodyBytes)
    local retTable = {}
    retTable['status'] = assembleJsonByGlobalProperty()
    local ret = encode(retTable)
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
    if #bodyBytes == 0 then return nil end
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do msgBytes[i] = 0 end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    if (getSoftVersion() == 1 or getSoftVersion() == 3) then
        msgBytes[8] = 0x01
    end
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

function decode(cmd)
    local tb
    if JSON == nil then JSON = require 'cjson' end
    tb = JSON.decode(cmd)
    return tb
end

function encode(luaTable)
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

function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = '0' end
    return data
end

function string2Int(data)
    if (not data) then data = tonumber('0') end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
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
