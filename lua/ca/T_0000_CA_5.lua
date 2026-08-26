local JSON = require 'cjson'
local KEY_VERSION = 'version'
local VALUE_VERSION = '5'
local BYTE_DEVICE_TYPE = 0xCA
local BYTE_MSG_TYPE_CONTROL = 0x02
local BYTE_MSG_TYPE_QUERY = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_HEAD_LENGTH = 0x0A

local codeMode
local freezingMode
local smartMode
local energySavingMode
local holidayMode
local moisturizeMode
local preservationMode
local acmeFreezingMode
local refrigerationPowerValue
local freezingPowerValue
local lVariablePowerValue
local rVariablePowerValue
local allRefrigerationPower
local refrigerationTemperature
local freezingTemperature
local lVariableTemperature
local rVariableTemperature
local variableModeValue
local removeDew
local humidify
local unfreeze
local temperatureUnit
local floodlight
local functionSwitch
local radarMode
local milkMode
local icedMode
local plasmaAsepticMode
local acquireIceaMode
local brashIceaMode
local acquireWaterMode
local iceMachinePower
local humanInduction
local refrigerationDoorPower
local freezingDoorPower
local variableDoorPower
local barDoorPower
local iceMouthPower
local freezingFahrenheit
local refrigerationFahrenheit
local leachExpireDay
local powerConsumptionLow
local powerConsumptionHigh
local motorResetStatus
local motorDeicingStatus
local iceMachineWaterStatus
local allIceaStatus
local isError
local intervalRoomTemperatureLevel
local refrigerationRealTemperature
local freezingRealTemperature
local lVariableRealTemperature
local rVariableRealTemperature
local fastColdMinuteLow
local fastColdMinuteHigh
local fastFreezeMinuteLow
local fastFreezeMinuteHigh
local foodSite
local beef
local pork
local mutton
local chicken
local duckMeat
local fish
local shrimp
local dumplings
local gluePudding
local iceCream
local performanceMode
local normalTemperatureLevel
local functionZoneLevel
local humiditySetting
local smartHumidity
local dataType = 0

function jsonToModel(jsonCmd)
    local streams = jsonCmd
    if (streams['storage_mode'] == 'on') then
        codeMode = 0x01
    elseif (streams['storage_mode'] == 'off') then
        codeMode = 0x00
    end
    if (streams['freezing_mode'] == 'on') then
        freezingMode = 0x02
    elseif (streams['freezing_mode'] == 'off') then
        freezingMode = 0x00
    end
    if (streams['intelligent_mode'] == 'on') then
        smartMode = 0x04
    elseif (streams['intelligent_mode'] == 'off') then
        smartMode = 0x00
    end
    if (streams['energy_saving_mode'] == 'on') then
        energySavingMode = 0x08
    elseif (streams['energy_saving_mode'] == 'off') then
        energySavingMode = 0x00
    end
    if (streams['holiday_mode'] == 'on') then
        holidayMode = 0x10
    elseif (streams['holiday_mode'] == 'off') then
        holidayMode = 0x00
    end
    if (streams['moisturize_mode'] == 'on') then
        moisturizeMode = 0x20
    elseif (streams['moisturize_mode'] == 'off') then
        moisturizeMode = 0x00
    end
    if (streams['preservation_mode'] == 'on') then
        preservationMode = 0x40
    elseif (streams['preservation_mode'] == 'off') then
        preservationMode = 0x00
    end
    if (streams['acme_freezing_mode'] == 'on') then
        acmeFreezingMode = 0x80
    elseif (streams['acme_freezing_mode'] == 'off') then
        acmeFreezingMode = 0x00
    end
    if (streams['storage_temperature'] ~= nil) then
        refrigerationTemperature = checkBoundary(streams['storage_temperature'], 2, 8)
    end
    if (streams['freezing_temperature'] ~= nil) then
        freezingTemperature = checkBoundary(streams['freezing_temperature'], -24, -15)
        freezingTemperature = freezingTemperature + (((-15 - freezingTemperature) * 2) + 18)
    end
    if (streams['left_flexzone_temperature'] ~= nil) then
        lVariableTemperature = checkBoundary(streams['left_flexzone_temperature'], -24, 10)
        if ((lVariableTemperature >= -18) and (lVariableTemperature <= 10)) then
            lVariableTemperature = lVariableTemperature + 19
        elseif ((lVariableTemperature >= -24) and (lVariableTemperature <= -19)) then
            lVariableTemperature = lVariableTemperature + 30
        else
            lVariableTemperature = 0
        end
    end
    if (streams['right_flexzone_temperature'] ~= nil) then
        rVariableTemperature = checkBoundary(streams['right_flexzone_temperature'], -24, 10)
        if ((rVariableTemperature >= -18) and (rVariableTemperature <= 10)) then
            rVariableTemperature = rVariableTemperature + 19
        elseif ((rVariableTemperature >= -24) and (rVariableTemperature <= -19)) then
            rVariableTemperature = rVariableTemperature + 30
        else
            rVariableTemperature = 0
        end
    end
    if (streams['variable_mode'] == 'soft_freezing_mode') then
        variableModeValue = 0x01
    elseif (streams['variable_mode'] == 'zero_fresh_mode') then
        variableModeValue = 0x02
    elseif (streams['variable_mode'] == 'cold_drink_mode') then
        variableModeValue = 0x03
    elseif (streams['variable_mode'] == 'fresh_product_mode') then
        variableModeValue = 0x04
    elseif (streams['variable_mode'] == 'partial_freezing_mode') then
        variableModeValue = 0x05
    elseif (streams['variable_mode'] == 'dry_zone_mode') then
        variableModeValue = 0x06
    elseif (streams['variable_mode'] == 'freeze_warm_mode') then
        variableModeValue = 0x07
    end
    if (streams['storage_power'] == 'on') then
        refrigerationPowerValue = 0x00
    elseif (streams['storage_power'] == 'off') then
        refrigerationPowerValue = 0x01
    end
    if (streams['left_flexzone_power'] == 'on') then
        lVariablePowerValue = 0x00
    elseif (streams['left_flexzone_power'] == 'off') then
        lVariablePowerValue = 0x04
    end
    if (streams['right_flexzone_power'] == 'on') then
        rVariablePowerValue = 0x00
    elseif (streams['right_flexzone_power'] == 'off') then
        rVariablePowerValue = 0x08
    end
    if (streams['freezing_power'] == 'on') then
        freezingPowerValue = 0x00
    elseif (streams['freezing_power'] == 'off') then
        freezingPowerValue = 0x10
    end
    if (streams['all_refrigeration_power'] == 'on') then
        allRefrigerationPower = 0x80
    elseif (streams['all_refrigeration_power'] == 'off') then
        allRefrigerationPower = 0x00
    end
    if (streams['remove_dew_power'] == 'on') then
        removeDew = 0x01
    elseif (streams['remove_dew_power'] == 'off') then
        removeDew = 0x00
    end
    if (streams['humidify_power'] == 'on') then
        humidify = 0x02
    elseif (streams['humidify_power'] == 'off') then
        humidify = 0x00
    end
    if (streams['unfreeze_power'] == 'on') then
        unfreeze = 0x04
    elseif (streams['unfreeze_power'] == 'off') then
        unfreeze = 0x00
    end
    if (streams['temperature_unit'] == 'fahrenheit') then
        temperatureUnit = 0x08
    elseif (streams['temperature_unit'] == 'celsius') then
        temperatureUnit = 0x00
    end
    if (streams['floodlight_power'] == 'on') then
        floodlight = 0x10
    elseif (streams['floodlight_power'] == 'off') then
        floodlight = 0x00
    end
    if (streams['icea_bar_function_switch'] == 'default') then
        functionSwitch = 0x00
    elseif (streams['icea_bar_function_switch'] == 'refrigeration') then
        functionSwitch = 0x40
    elseif (streams['icea_bar_function_switch'] == 'freezing') then
        functionSwitch = 0x80
    end
    if (streams['radar_mode_power'] == 'on') then
        radarMode = 0x01
    elseif (streams['radar_mode_power'] == 'off') then
        radarMode = 0x00
    end
    if (streams['milk_mode_power'] == 'on') then
        milkMode = 0x02
    elseif (streams['milk_mode_power'] == 'off') then
        milkMode = 0x00
    end
    if (streams['icea_mode_power'] == 'on') then
        icedMode = 0x04
    elseif (streams['icea_mode_power'] == 'off') then
        icedMode = 0x00
    end
    if (streams['plasma_aseptic_mode_power'] == 'on') then
        plasmaAsepticMode = 0x08
    elseif (streams['plasma_aseptic_mode_power'] == 'off') then
        plasmaAsepticMode = 0x00
    end
    if (streams['acquire_icea_mode_power'] == 'on') then
        acquireIceaMode = 0x10
    elseif (streams['acquire_icea_mode_power'] == 'off') then
        acquireIceaMode = 0x00
    end
    if (streams['brash_icea_mode_power'] == 'on') then
        brashIceaMode = 0x20
    elseif (streams['brash_icea_mode_power'] == 'off') then
        brashIceaMode = 0x00
    end
    if (streams['acquire_water_mode_power'] == 'on') then
        acquireWaterMode = 0x40
    elseif (streams['acquire_water_mode_power'] == 'off') then
        acquireWaterMode = 0x00
    end
    if (streams['icea_machine_power'] == 'on') then
        iceMachinePower = 0x80
    elseif (streams['icea_machine_power'] == 'off') then
        iceMachinePower = 0x00
    end
    if (streams['interval_room_temperature_level'] ~= nil) then
        intervalRoomTemperatureLevel = checkBoundary(streams['interval_room_temperature_level'], 0, 127)
    end
    if (streams['food_site'] == 'left_freezing_room') then
        foodSite = 0x00
    elseif (streams['food_site'] == 'right_freezing_room') then
        foodSite = 0x01
    end
    if (streams['performance_mode'] == 'on') then
        performanceMode = 0x80
    elseif (streams['performance_mode'] == 'off') then
        performanceMode = 0x00
    end
    if (streams['normal_zone_level'] ~= nil) then
        normalTemperatureLevel = checkBoundary(streams['normal_zone_level'], 1, 10)
    end
    if (streams['function_zone_level'] ~= nil) then
        functionZoneLevel = checkBoundary(streams['function_zone_level'], 1, 10)
    end
    if (streams['humidify_setting'] ~= nil) then
        humiditySetting = checkBoundary(streams['humidify_setting'], 1, 99)
    end
    if (streams['smart_humidify'] == 'on') then
        smartHumidity = 0x80
    elseif (streams['smart_humidify'] == 'off') then
        smartHumidity = 0x00
    end
end

function binToModel(binData)
    if (#binData < 11) then
        return nil
    end
    local messageBytes = binData
    if
    ((dataType == 0x02 and messageBytes[0] == 0x00) or (dataType == 0x03 and messageBytes[0] == 0x00) or
            (dataType == 0x04 and messageBytes[0] == 0x02))
    then
        codeMode = bit.band(messageBytes[1], 0x01)
        freezingMode = bit.band(messageBytes[1], 0x02)
        smartMode = bit.band(messageBytes[1], 0x04)
        energySavingMode = bit.band(messageBytes[1], 0x08)
        holidayMode = bit.band(messageBytes[1], 0x10)
        moisturizeMode = bit.band(messageBytes[1], 0x20)
        preservationMode = bit.band(messageBytes[1], 0x40)
        acmeFreezingMode = bit.band(messageBytes[1], 0x80)
        refrigerationTemperature = bit.band(messageBytes[2], 0x0F)
        freezingTemperature = bit.rshift(bit.band(messageBytes[2], 0xF0), 4)
        lVariableTemperature = messageBytes[3]
        rVariableTemperature = messageBytes[4]
        variableModeValue = messageBytes[5]
        refrigerationPowerValue = bit.band(messageBytes[6], 0x01)
        lVariablePowerValue = bit.band(messageBytes[6], 0x04)
        rVariablePowerValue = bit.band(messageBytes[6], 0x08)
        freezingPowerValue = bit.band(messageBytes[6], 0x10)
        allRefrigerationPower = bit.band(messageBytes[6], 0x80)
        removeDew = bit.band(messageBytes[7], 0x01)
        humidify = bit.band(messageBytes[7], 0x02)
        unfreeze = bit.band(messageBytes[7], 0x04)
        temperatureUnit = bit.band(messageBytes[7], 0x08)
        floodlight = bit.band(messageBytes[7], 0x10)
        functionSwitch = bit.band(messageBytes[7], 0xC0)
        radarMode = bit.band(messageBytes[8], 0x01)
        milkMode = bit.band(messageBytes[8], 0x02)
        icedMode = bit.band(messageBytes[8], 0x04)
        plasmaAsepticMode = bit.band(messageBytes[8], 0x08)
        acquireIceaMode = bit.band(messageBytes[8], 0x10)
        brashIceaMode = bit.band(messageBytes[8], 0x20)
        acquireWaterMode = bit.band(messageBytes[8], 0x40)
        iceMachinePower = bit.band(messageBytes[8], 0x80)
        freezingFahrenheit = messageBytes[9]
        refrigerationFahrenheit = bit.band(messageBytes[10], 0xFC)
        leachExpireDay = messageBytes[11]
        powerConsumptionLow = messageBytes[12]
        powerConsumptionHigh = messageBytes[13]
        motorResetStatus = bit.band(messageBytes[14], 0x01)
        motorDeicingStatus = bit.band(messageBytes[14], 0x02)
        iceMachineWaterStatus = bit.band(messageBytes[14], 0x04)
        allIceaStatus = bit.band(messageBytes[14], 0x08)
        humanInduction = bit.band(messageBytes[14], 0x10)
        refrigerationDoorPower = bit.band(messageBytes[15], 0x01)
        freezingDoorPower = bit.band(messageBytes[15], 0x02)
        variableDoorPower = bit.band(messageBytes[15], 0x10)
        barDoorPower = bit.band(messageBytes[15], 0x04)
        iceMouthPower = bit.band(messageBytes[15], 0x08)
        isError = bit.band(messageBytes[16], 0x01)
        intervalRoomTemperatureLevel = bit.band(messageBytes[16], 0xFE)
        refrigerationRealTemperature = messageBytes[17]
        freezingRealTemperature = messageBytes[18]
        lVariableRealTemperature = messageBytes[19]
        rVariableRealTemperature = messageBytes[20]
        fastColdMinuteLow = messageBytes[21]
        fastColdMinuteHigh = messageBytes[22]
        fastFreezeMinuteLow = messageBytes[23]
        fastFreezeMinuteHigh = messageBytes[24]
        if (#messageBytes > 25) then
            foodSite = bit.band(messageBytes[25], 0x0F)
            beef = bit.band(messageBytes[25], 0x40)
            pork = bit.band(messageBytes[25], 0x80)
            mutton = bit.band(messageBytes[26], 0x01)
            chicken = bit.band(messageBytes[26], 0x02)
            duckMeat = bit.band(messageBytes[26], 0x04)
            fish = bit.band(messageBytes[26], 0x08)
            shrimp = bit.band(messageBytes[26], 0x10)
            dumplings = bit.band(messageBytes[26], 0x20)
            gluePudding = bit.band(messageBytes[26], 0x40)
            iceCream = bit.band(messageBytes[26], 0x80)
            performanceMode = bit.band(messageBytes[27], 0x80)
            normalTemperatureLevel = messageBytes[28]
            functionZoneLevel = messageBytes[29]
            if (#messageBytes > 30) then
                humiditySetting = bit.band(messageBytes[30], 0x7F)
                smartHumidity = bit.band(messageBytes[30], 0x80)
            end
        end
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then
        return nil
    end
    local infoM = {}
    local bodyBytes = {}
    local json = decode(jsonCmd)
    local deviceSubType = json['deviceinfo']['deviceSubType']
    if (deviceSubType == 1) then
    end
    local query = json['query']
    local control = json['control']
    local status = json['status']
    if (query) then
        bodyBytes[0] = 0x00
        infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_QUERY)
    elseif (control) then
        if (status) then
            jsonToModel(status)
        end
        if (control) then
            jsonToModel(control)
        end
        for i = 0, 30 do
            bodyBytes[i] = 0
        end
        bodyBytes[0] = 0x00
        bodyBytes[1] = bit.bor(
                bit.bor(
                        bit.bor(
                                bit.bor(
                                        bit.bor(
                                                bit.bor(
                                                        bit.bor(bit.band(codeMode, 0x01), bit.band(freezingMode, 0x02)),
                                                        bit.band(smartMode, 0x04)
                                                ),
                                                bit.band(energySavingMode, 0x08)
                                        ),
                                        bit.band(holidayMode, 0x10)
                                ),
                                bit.band(moisturizeMode, 0x20)
                        ),
                        bit.band(preservationMode, 0x40)
                ),
                bit.band(acmeFreezingMode, 0x80)
        )
        bodyBytes[2] = bit.bor(bit.lshift(bit.band(freezingTemperature, 0x0F), 4), bit.band(refrigerationTemperature, 0x0F))
        bodyBytes[3] = lVariableTemperature
        bodyBytes[4] = rVariableTemperature
        bodyBytes[5] = variableModeValue
        bodyBytes[6] = bit.bor(
                bit.bor(
                        bit.bor(
                                bit.bor(bit.band(refrigerationPowerValue, 0x01), bit.band(lVariablePowerValue, 0x04)),
                                bit.band(rVariablePowerValue, 0x08)
                        ),
                        bit.band(freezingPowerValue, 0x10)
                ),
                bit.band(allRefrigerationPower, 0x80)
        )
        bodyBytes[7] = bit.bor(
                bit.bor(
                        bit.bor(
                                bit.bor(bit.bor(bit.band(removeDew, 0x01), bit.band(humidify, 0x02)), bit.band(unfreeze, 0x04)),
                                bit.band(temperatureUnit, 0x08)
                        ),
                        bit.band(floodlight, 0x10)
                ),
                bit.band(functionSwitch, 0xC0)
        )
        bodyBytes[8] = bit.bor(
                bit.bor(
                        bit.bor(
                                bit.bor(
                                        bit.bor(
                                                bit.bor(
                                                        bit.bor(bit.band(radarMode, 0x01), bit.band(milkMode, 0x02)),
                                                        bit.band(icedMode, 0x04)
                                                ),
                                                bit.band(plasmaAsepticMode, 0x08)
                                        ),
                                        bit.band(acquireIceaMode, 0x10)
                                ),
                                bit.band(brashIceaMode, 0x20)
                        ),
                        bit.band(acquireWaterMode, 0x40)
                ),
                bit.band(iceMachinePower, 0x80)
        )
        bodyBytes[16] = bit.band(intervalRoomTemperatureLevel, 0xFE)
        if (foodSite ~= nil) then
            bodyBytes[25] = bit.band(foodSite, 0x0F)
        end
        if (performanceMode ~= nil) then
            bodyBytes[27] = bit.band(performanceMode, 0x80)
        end
        if (normalTemperatureLevel ~= nil) then
            bodyBytes[28] = normalTemperatureLevel
        end
        if (functionZoneLevel ~= nil) then
            bodyBytes[29] = functionZoneLevel
        end
        if (humiditySetting ~= nil and smartHumidity ~= nil) then
            bodyBytes[30] = bit.bor(bit.band(humiditySetting, 0x7F), bit.band(smartHumidity, 0x80))
        end
        infoM = getTotalMsg(bodyBytes, BYTE_MSG_TYPE_CONTROL)
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1
    local msgBytes = {}
    for i = 0, msgLength do
        msgBytes[i] = 0
    end
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[3] = bit.bxor((bodyLength + BYTE_PROTOCOL_HEAD_LENGTH + 1), BYTE_DEVICE_TYPE)
    msgBytes[9] = cType
    for i = 0, bodyLength do
        msgBytes[i + BYTE_PROTOCOL_HEAD_LENGTH] = bodyData[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do
        msgFinal[i] = msgBytes[i - 1]
    end
    return msgFinal
end

function dataToJson(jsonCmd)
    if (not jsonCmd) then
        return nil
    end
    local json = decode(jsonCmd)
    local deviceinfo = json['deviceinfo']
    local deviceSubType = deviceinfo['deviceSubtype']
    if (deviceSubType == 1) then
    end
    local status = json['status']
    if (status) then
        jsonToModel(status)
    end
    local binData = json['msg']['data']
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[10]
    for i = 1, #info do
        msgBytes[i - 1] = info[i]
    end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_HEAD_LENGTH - 1
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_HEAD_LENGTH]
    end
    binToModel(bodyBytes)
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if
    ((dataType == 0x02 and bodyBytes[0] == 0x00) or (dataType == 0x03 and bodyBytes[0] == 0x00) or
            (dataType == 0x04 and bodyBytes[0] == 0x02))
    then
        if (codeMode == 0x01) then
            streams['storage_mode'] = 'on'
        elseif (codeMode == 0x00) then
            streams['storage_mode'] = 'off'
        end
        if (freezingMode == 0x02) then
            streams['freezing_mode'] = 'on'
        elseif (freezingMode == 0x00) then
            streams['freezing_mode'] = 'off'
        end
        if (smartMode == 0x04) then
            streams['intelligent_mode'] = 'on'
        elseif (smartMode == 0x00) then
            streams['intelligent_mode'] = 'off'
        end
        if (energySavingMode == 0x08) then
            streams['energy_saving_mode'] = 'on'
        elseif (energySavingMode == 0x00) then
            streams['energy_saving_mode'] = 'off'
        end
        if (holidayMode == 0x10) then
            streams['holiday_mode'] = 'on'
        elseif (holidayMode == 0x00) then
            streams['holiday_mode'] = 'off'
        end
        if (moisturizeMode == 0x20) then
            streams['moisturize_mode'] = 'on'
        elseif (moisturizeMode == 0x00) then
            streams['moisturize_mode'] = 'off'
        end
        if (preservationMode == 0x40) then
            streams['preservation_mode'] = 'on'
        elseif (preservationMode == 0x00) then
            streams['preservation_mode'] = 'off'
        end
        if (acmeFreezingMode == 0x80) then
            streams['acme_freezing_mode'] = 'on'
        elseif (acmeFreezingMode == 0x00) then
            streams['acme_freezing_mode'] = 'off'
        end
        streams['storage_temperature'] = int2String(refrigerationTemperature)
        streams['freezing_temperature'] = int2String(-12 - freezingTemperature)
        if ((lVariableTemperature >= 1) and (lVariableTemperature <= 29)) then
            streams['left_flexzone_temperature'] = int2String(lVariableTemperature - 19)
        elseif ((lVarTemperatureValue >= 49) and (lVarTemperatureValue <= 54)) then
            streams['left_flexzone_temperature'] = int2String(30 - lVarTemperatureValue)
        else
            streams['left_flexzone_temperature'] = '0'
        end
        if ((rVariableTemperature) and (rVariableTemperature <= 29)) then
            streams['right_flexzone_temperature'] = int2String(rVariableTemperature - 19)
        elseif ((rVariableTemperature >= 49) and (rVariableTemperature <= 54)) then
            streams['right_flexzone_temperature'] = int2String(30 - rVariableTemperature)
        else
            streams['right_flexzone_temperature'] = '0'
        end
        if (variableModeValue == 0x01) then
            streams['variable_mode'] = 'soft_freezing_mode'
        elseif (variableModeValue == 0x02) then
            streams['variable_mode'] = 'zero_fresh_mode'
        elseif (variableModeValue == 0x03) then
            streams['variable_mode'] = 'cold_drink_mode'
        elseif (variableModeValue == 0x04) then
            streams['variable_mode'] = 'fresh_product_mode'
        elseif (variableModeValue == 0x05) then
            streams['variable_mode'] = 'partial_freezing_mode'
        elseif (variableModeValue == 0x06) then
            streams['variable_mode'] = 'dry_zone_mode'
        elseif (variableModeValue == 0x07) then
            streams['variable_mode'] = 'freeze_warm_mode'
        end
        if (refrigerationPowerValue == 0x00) then
            streams['storage_power'] = 'on'
        elseif (refrigerationPowerValue == 0x01) then
            streams['storage_power'] = 'off'
        end
        if (lVariablePowerValue == 0x00) then
            streams['left_flexzone_power'] = 'on'
        elseif (lVariablePowerValue == 0x04) then
            streams['left_flexzone_power'] = 'off'
        end
        if (rVariablePowerValue == 0x00) then
            streams['right_flexzone_power'] = 'on'
        elseif (rVariablePowerValue == 0x08) then
            streams['right_flexzone_power'] = 'off'
        end
        if (freezingPowerValue == 0x00) then
            streams['freezing_power'] = 'on'
        elseif (freezingPowerValue == 0x10) then
            streams['freezing_power'] = 'off'
        end
        if (allRefrigerationPower == 0x80) then
            streams['all_refrigeration_power'] = 'on'
        elseif (allRefrigerationPower == 0x00) then
            streams['all_refrigeration_power'] = 'off'
        end
        if (removeDew == 0x01) then
            streams['remove_dew_power'] = 'on'
        elseif (removeDew == 0x00) then
            streams['remove_dew_power'] = 'off'
        end
        if (humidify == 0x02) then
            streams['humidify_power'] = 'on'
        elseif (humidify == 0x00) then
            streams['humidify_power'] = 'off'
        end
        if (unfreeze == 0x04) then
            streams['unfreeze_power'] = 'on'
        elseif (unfreeze == 0x00) then
            streams['unfreeze_power'] = 'off'
        end
        if (temperatureUnit == 0x08) then
            streams['temperature_unit'] = 'fahrenheit'
        elseif (temperatureUnit == 0x00) then
            streams['temperature_unit'] = 'celsius'
        end
        if (floodlight == 0x10) then
            streams['floodlight_power'] = 'on'
        elseif (floodlight == 0x00) then
            streams['floodlight_power'] = 'off'
        end
        if (functionSwitch == 0x00) then
            streams['icea_bar_function_switch'] = 'default'
        elseif (functionSwitch == 0x40) then
            streams['icea_bar_function_switch'] = 'refrigeration'
        elseif (functionSwitch == 0x80) then
            streams['icea_bar_function_switch'] = 'freezing'
        end
        if (radarMode == 0x01) then
            streams['radar_mode_power'] = 'on'
        elseif (radarMode == 0x00) then
            streams['radar_mode_power'] = 'off'
        end
        if (milkMode == 0x02) then
            streams['milk_mode_power'] = 'on'
        elseif (milkMode == 0x00) then
            streams['milk_mode_power'] = 'off'
        end
        if (icedMode == 0x04) then
            streams['icea_mode_power'] = 'on'
        elseif (icedMode == 0x00) then
            streams['icea_mode_power'] = 'off'
        end
        if (plasmaAsepticMode == 0x08) then
            streams['plasma_aseptic_mode_power'] = 'on'
        elseif (plasmaAsepticMode == 0x00) then
            streams['plasma_aseptic_mode_power'] = 'off'
        end
        if (acquireIceaMode == 0x10) then
            streams['acquire_icea_mode_power'] = 'on'
        elseif (acquireIceaMode == 0x00) then
            streams['acquire_icea_mode_power'] = 'off'
        end
        if (brashIceaMode == 0x20) then
            streams['brash_icea_mode_power'] = 'on'
        elseif (brashIceaMode == 0x00) then
            streams['brash_icea_mode_power'] = 'off'
        end
        if (acquireWaterMode == 0x40) then
            streams['acquire_water_mode_power'] = 'on'
        elseif (acquireWaterMode == 0x00) then
            streams['acquire_water_mode_power'] = 'off'
        end
        if (iceMachinePower == 0x80) then
            streams['icea_machine_power'] = 'on'
        elseif (iceMachinePower == 0x00) then
            streams['icea_machine_power'] = 'off'
        end
        streams['freeze_fahrenheit_level'] = int2String(freezingFahrenheit)
        streams['refrigeration_fahrenheit_level'] = int2String(refrigerationFahrenheit)
        streams['leach_expire_day'] = int2String(leachExpireDay)
        streams['power_consumption_low'] = int2String(powerConsumptionLow)
        streams['power_consumption_high'] = int2String(powerConsumptionHigh)
        if (motorResetStatus == 0x01) then
            streams['motor_reset_status'] = 'valid'
        elseif (motorResetStatus == 0x00) then
            streams['motor_reset_status'] = 'invalid'
        end
        if (motorDeicingStatus == 0x02) then
            streams['motor_deicing_status'] = 'valid'
        elseif (motorDeicingStatus == 0x00) then
            streams['motor_deicing_status'] = 'invalid'
        end
        if (iceMachineWaterStatus == 0x04) then
            streams['ice_machine_water_status'] = 'valid'
        elseif (iceMachineWaterStatus == 0x00) then
            streams['ice_machine_water_status'] = 'invalid'
        end
        if (allIceaStatus == 0x08) then
            streams['all_icea_status'] = 'valid'
        elseif (allIceaStatus == 0x00) then
            streams['all_icea_status'] = 'invalid'
        end
        if (humanInduction == 0x10) then
            streams['human_induction_status'] = 'valid'
        elseif (humanInduction == 0x00) then
            streams['human_induction_status'] = 'invalid'
        end
        if (refrigerationDoorPower == 0x01) then
            streams['storage_door_state'] = 'on'
        elseif (refrigerationDoorPower == 0x00) then
            streams['storage_door_state'] = 'off'
        end
        if (freezingDoorPower == 0x02) then
            streams['freezer_door_state'] = 'on'
        elseif (freezingDoorPower == 0x00) then
            streams['freezer_door_state'] = 'off'
        end
        if (variableDoorPower == 0x10) then
            streams['flexzone_door_state'] = 'on'
        elseif (variableDoorPower == 0x00) then
            streams['flexzone_door_state'] = 'off'
        end
        if (barDoorPower == 0x04) then
            streams['bar_door_state'] = 'on'
        elseif (barDoorPower == 0x00) then
            streams['bar_door_state'] = 'off'
        end
        if (iceMouthPower == 0x08) then
            streams['ice_mouth_power'] = 'on'
        elseif (iceMouthPower == 0x00) then
            streams['ice_mouth_power'] = 'off'
        end
        if (isError == 0x01) then
            streams['is_error'] = 'yes'
        elseif (isError == 0x00) then
            streams['is_error'] = 'no'
        end
        streams['interval_room_temperature_level'] = int2String(intervalRoomTemperatureLevel)
        streams['refrigeration_real_temperature'] = int2String(math.floor((refrigerationRealTemperature - 100) / 2))
        streams['freezing_real_temperature'] = int2String(math.floor((freezingRealTemperature - 100) / 2))
        streams['left_variable_real_temperature'] = int2String(math.floor((lVariableRealTemperature - 100) / 2))
        streams['right_variable_real_temperature'] = int2String(math.floor((rVariableRealTemperature - 100) / 2))
        streams['fast_cold_minute'] = int2String(256 * fastColdMinuteHigh + fastColdMinuteLow)
        streams['fast_cold_minute'] = int2String(256 * fastFreezeMinuteLow + fastFreezeMinuteHigh)
        if (bodyLength > 25) then
            if (foodSite == 0x00) then
                streams['food_site'] = 'left_freezing_room'
            elseif (foodSite == 0x01) then
                streams['food_site'] = 'right_freezing_room'
            end
            if (beef == 0x40) then
                streams['beef'] = 'exist'
            elseif (foodSite == 0x00) then
                streams['beef'] = 'nonexistence'
            end
            if (pork == 0x80) then
                streams['pork'] = 'exist'
            elseif (pork == 0x00) then
                streams['pork'] = 'nonexistence'
            end
            if (mutton == 0x01) then
                streams['mutton'] = 'exist'
            elseif (mutton == 0x00) then
                streams['mutton'] = 'nonexistence'
            end
            if (chicken == 0x02) then
                streams['chicken'] = 'exist'
            elseif (chicken == 0x00) then
                streams['chicken'] = 'nonexistence'
            end
            if (duckMeat == 0x04) then
                streams['duckMeat'] = 'exist'
            elseif (duckMeat == 0x00) then
                streams['duckMeat'] = 'nonexistence'
            end
            if (fish == 0x08) then
                streams['fish'] = 'exist'
            elseif (fish == 0x00) then
                streams['fish'] = 'nonexistence'
            end
            if (shrimp == 0x10) then
                streams['shrimp'] = 'exist'
            elseif (shrimp == 0x00) then
                streams['shrimp'] = 'nonexistence'
            end
            if (dumplings == 0x20) then
                streams['dumplings'] = 'exist'
            elseif (dumplings == 0x00) then
                streams['dumplings'] = 'nonexistence'
            end
            if (gluePudding == 0x40) then
                streams['gluepudding'] = 'exist'
            elseif (gluePudding == 0x00) then
                streams['gluepudding'] = 'nonexistence'
            end
            if (iceCream == 0x80) then
                streams['ice_cream'] = 'exist'
            elseif (iceCream == 0x00) then
                streams['ice_cream'] = 'nonexistence'
            end
            if (performanceMode == 0x80) then
                streams['performance_mode'] = 'on'
            elseif (performanceMode == 0x00) then
                streams['performance_mode'] = 'off'
            end
            streams['normal_zone_level'] = int2String(normalTemperatureLevel)
            streams['function_zone_level'] = int2String(functionZoneLevel)
            if (bodyLength > 30) then
                streams['humidify_setting'] = int2String(humiditySetting)
                if (smartHumidity == 0x80) then
                    streams['smart_humidify'] = 'on'
                elseif (smartHumidity == 0x00) then
                    streams['smart_humidify'] = 'off'
                end
            end
        end
    end
    local retTable = {}
    retTable['status'] = streams
    local ret = encode(retTable)
    return ret
end

function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == 'string' then
            k = string.format('%q', k)
        end
        local szSuffix = ''
        if type(v) == 'table' then
            szSuffix = '{'
        end
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

function checkBoundary(data, min, max)
    if (not data) then
        data = 0
    end
    data = tonumber(data)
    if (data == nil) then
        data = 0
    end
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
    if (not data) then
        data = tonumber('0')
    end
    data = tonumber(data)
    if (data == nil) then
        data = 0
    end
    return data
end

function int2String(data)
    if (not data) then
        data = tostring(0)
    end
    data = tostring(data)
    if (data == nil) then
        data = '0'
    end
    return data
end

function table2string(cmd)
    local ret = ''
    local i
    for i = 1, #cmd do
        ret = ret .. string.char(cmd[i])
    end
    return ret
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
    for i = 1, #str do
        ret = ret .. string.format('%02x', str:byte(i))
    end
    return ret
end

function encode(cmd)
    local tb
    if JSON == nil then
        JSON = require 'cjson'
    end
    tb = JSON.encode(cmd)
    return tb
end

function decode(cmd)
    local tb
    if JSON == nil then
        JSON = require 'cjson'
    end
    tb = JSON.decode(cmd)
    return tb
end

function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then
            resVal = bit.band(resVal, 0xff)
        end
    end
    resVal = 255 - resVal + 1
    return resVal
end

local crc8_854_table = { 0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65, 157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220, 35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98, 190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255, 70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7, 219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154, 101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36, 248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185, 140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205, 17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80, 175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238, 50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115, 202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139, 87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22, 233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168, 116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53 }

function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end
