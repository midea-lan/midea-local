local rootPath="/mnt/app/"
package.path = package.path .. ";" .. rootPath .. "lua/?.lua;"
package.cpath = package.path .. ";" .. rootPath .. "libs/?.so;"
--烤箱
local JSON = require "T_0000_B1_0TVN50R6_LATEST"
local JSON = require "cjson"
require "utils"
local function getPowerLevelValue(powerLevelString)
    if(powerLevelString == nil) then return nil end
    if(powerLevelString == "高火" or powerLevelString == "大火" or powerLevelString == "最大火力" or powerLevelString == "最大") then return 235 end
    if(powerLevelString == "中火") then return 175 end
    if(powerLevelString == "低火" or powerLevelString == "小火" or powerLevelString == "最小火力" or powerLevelString == "最小") then return 100 end
    return string.gsub(powerLevelString,"[档级]","")
end

local function getPowerLevelValueByTemp(temperatureString)
    if(temperatureString == nil) then return nil end
    if(temperatureString == "maxWarmth") then return 235 end
    if(temperatureString == "中温") then return 175 end
    if(temperatureString == "minWarmth") then return 100 end
end

local function getMappedMode(nluDeviceMode)
    local modeMapTable = {}
    --烧烤模式判断
    modeMapTable["above_tube"]="core_baking"
    modeMapTable["ferment"]="zymosis"
    modeMapTable["underside_tube"]="underside_tube"
    modeMapTable["hot_wind_bake"]="hot_wind_bake"
    modeMapTable["up_down_baking"]="double_tube"
    modeMapTable["steam_clean"]="scale_clean"
    modeMapTable["heating"]="double_tube"
    modeMapTable["baking"]="double_tube"
    modeMapTable["preheat"]="double_tube"

    if(modeMapTable[nluDeviceMode] ~= nil) then
        return modeMapTable[nluDeviceMode]
    else
        return nluDeviceMode
    end
end

local function getTemperatureValueWithDefault(temperatureString,defaultTemperature,minTemp,maxTemp)
    if(temperatureString == nil) then
	return defaultTemperature
    elseif(temperatureString == "maxWarmth") then
        return 235
    elseif(temperatureString == "最大") then
        return 235
    elseif(temperatureString == "中温") then
        return 175
    elseif(temperatureString == "minWarmth") then
        return 100
    elseif(temperatureString == "最小") then
        return 100
    else
	local temp = string.gsub(temperatureString,"°C","")
	if(minTemp ~= nil and maxTemp ~= nil) then
		--增加温度范围控制30--100
		--local temp = tonumber(temperatureString)
		if(tonumber(temp) > maxTemp) then
			temp = maxTemp
		elseif(tonumber(temp) < minTemp) then
			temp = minTemp
		end
	end
	return temp
    end
end
--根据不同模式设定时间
local function getModeDurationSecondValue(modeString,durationString)
	local durationSecondValue = getDurationSecondValue(durationString)
	if(modeString == "zymosis") then
		if(tonumber(durationSecondValue) > 43200) then
		durationSecondValue = 43200
	end
	else
	if(tonumber(durationSecondValue) > 32400) then
		durationSecondValue = 32400
	end
    end
    return durationSecondValue
end
--
--local function isValid(slotItems)
--     if(slotItems["deviceMode"]=="microwave") then
--        if(slotItems["fire_level"] ==nil) then return false end
--        if(slotItems["duration"] ==nil) then return false end
--     elseif(slotItems["deviceMode"]=="baking" or slotItems["deviceMode"] == "ferment"
--                or slotItems["deviceMode"]=="unfreeze_t" or slotItems["deviceMode"]=="fast_steam" ) then
--         if(slotItems["duration"] ==nil) then return false end
--     elseif(slotItems["deviceMode"]=="unfreeze")   then
--         if(slotItems["weight"] ==nil) then return false end
--     elseif(slotItems["deviceMode"]=="roast" or slotItems["deviceMode"]=="hot_steam"
--                or slotItems["deviceMode"]=="pure_steam") then
--         if(slotItems["temperature"] ==nil) then return false end
--         if(slotItems["duration"] ==nil) then return false end
--     end
--    return true
--end
function intentToJson(nluJson)
    -- extract the fields
    local nluJson = JSON.decode(nluJson)
    local intent = nluJson["intent"]
    local slot = intent["slot"]
    local status = nluJson["status"]

    -- define possible return object
    local slotItems = {}
    local control = {}
    local query = {}
    local retTable = {}
	--local date,time
    if(#slot ~= 0) then
        slotItems = getKVTable(slot, "parameter", "value")
    end
    local parsedIntent = parseIntent(intent,slotItems)
    --查询
    if(parsedIntent == deviceStatePI) then
        retTable["query"] = query

    else --控制指令
        --开机
        if(parsedIntent == deviceStartPI) then
                control["work_status"] = "standby"
            --关机
        elseif(parsedIntent == deviceStopPI)then
                control["work_status"] = "save_power"
            --启动功能模式（可能同时设置参数）
        elseif(parsedIntent == deviceStartFunctionPI or parsedIntent == deviceSetFunctionPI ) then
           -- if(not isValid(slotItems)) then return nil end
           if(slotItems["deviceMode"] == "preheat") then
			control["pre_heat"] = "on"
           end
            control["work_mode"] = getMappedMode(slotItems["deviceMode"])

            if(slotItems["deviceMode"] == nil and slotItems["deviceAspect"] == nil and intent["deviceVerb"] ~= "set") then
		control["work_mode"] = "double_tube" --默认模式
            end
            --初始化时间及温度
            if(control["work_mode"] ~= nil) then
		control["work_hour"] = 0
		control["work_minute"] = 0
		control["temperature"] = 0
		--时间设置
		if(slotItems["duration"]~=nil) then
                    local durationSecondValue = getModeDurationSecondValue(control["work_mode"],slotItems["duration"])
                    control["work_hour"],temp = math.modf(durationSecondValue/(60*60))
                    control["work_minute"],temp = math.modf((durationSecondValue/60)%60)
                else
                    control["work_minute"] = 15 --设置默认时间
                end
            end

            --"上下烧烤 double_tube"、"双上管烧烤 core_baking"和"红外烧烤 total_baking"温度范围为100-235，时间范围为0-9小时。
            if(control["work_mode"] == "double_tube" or control["work_mode"] == "core_baking" or control["work_mode"] == "total_baking") then
                control["temperature"] = getTemperatureValueWithDefault(slotItems["temperature"],150,100,235)  --设置默认温度
            --"热风对流 hot_wind_bake"和"下管烧烤+热风对流 underside_tube_hot_wind_bake"温度范围为50-250，时间范围为0-9小时。
            elseif(control["work_mode"] == "underside_tube_hot_wind_bake" or control["work_mode"] == "hot_wind_bake") then
                control["temperature"] = getTemperatureValueWithDefault(slotItems["temperature"],125,50,250)  --设置默认温度
            --"上下烧烤+风扇 double_tube_fan"和"下管烧烤 underside_tube"温度范围为50-235，时间范围为0-9小时。
            elseif(control["work_mode"] == "double_tube_fan" or control["work_mode"] == "underside_tube") then
		control["temperature"] = getTemperatureValueWithDefault(slotItems["temperature"],125,50,235)  --设置默认温度
            --"双上管+风扇 double_upside_tube_fan"温度范围为100-250度，时间范围为0-9小时。
            elseif(control["work_mode"] == "double_upside_tube_fan") then
		control["temperature"] = getTemperatureValueWithDefault(slotItems["temperature"],125,100,250)  --设置默认温度
            --"发酵 zymosis"温度范围为30-45度，时间范围为0-12小时。
            elseif(control["work_mode"] == "zymosis") then
		control["temperature"] = getTemperatureValueWithDefault(slotItems["temperature"],40,30,45)  --设置默认温度
            end

            --火力设置
            if(slotItems["fire_level"] ~= nil) then
                control["temperature"] = getPowerLevelValue(slotItems["fire_level"])
                control["temp_set"] = control["temperature"]
            end
--            if(slotItems["temperature"] ~= nil) then
--                control["temperature"] = getPowerLevelValueByTemp(slotItems["temperature"])
--            end

            if(slotItems["deviceAspect"] == "light") then
                control["furnace_light"] = "on"
            elseif(slotItems["deviceAspect"] == "childLock") then
                control["lock"] = "on"
            end

             --温度及时间单独设置
            if(intent["deviceVerb"] == "set") then
		--时间设置
		if(slotItems["duration"]~=nil) then
                    local durationSecondValue = getDurationSecondValue(slotItems["duration"])
                    control["hour_set"],temp = math.modf(durationSecondValue/(60*60))
                    control["minute_set"],temp = math.modf((durationSecondValue/60)%60)
                end

                --温度设置
                if(slotItems["temperature"] ~= nil) then
			control["temp_set"] = getTemperatureValueWithDefault(slotItems["temperature"],0,50,230)
                end
            end

            --control["weight"] = getWeightValue(slotItems["weight"])
    --设置参数
      --  elseif(parsedIntent == deviceSetFunctionPI ) then
    --关闭功能模式
        elseif(parsedIntent == deviceStopFunctionPI) then
            if(slotItems["deviceAspect"] == "light") then
                control["furnace_light"] = "off"
            elseif(slotItems["deviceAspect"] == "childLock") then
                control["lock"] = "off"
            else
                control["work_status"] = "standby"
            end
        elseif(parsedIntent == devicePausePI) then
            control["work_status"] = "pause"
        elseif(parsedIntent == deviceResumePI) then
            control["work_status"] = "work"
            --调整参数
        elseif(parsedIntent ==deviceVolumeControlPI ) then
            local durationSecondValue = getDurationSecondValue(slotItems["duration"])
            local secTime = 0 ;
            local temperature = 0 ;
            if(status ~= nil) then
                secTime = status["secTime"]--剩余时间，秒
                temperature = status["temperature"]
                if(secTime == nil or secTime == "null") then
                    secTime = 0
                end
                if(temperature == nil or temperature == "null") then
                    temperature = 0
                end
            end
            if(intent["deviceVerb"]=="up") then
                if(slotItems["duration"] ~= nil) then

                    if(durationSecondValue ~= nil) then
                        durationSecondValue = durationSecondValue + secTime
                        control["hour_set"],temp = math.modf(durationSecondValue/(60*60))
                        control["minute_set"],temp= math.modf((durationSecondValue/60)%60)
                        control["second_set"] = durationSecondValue%60
                    else
                        secTime = secTime + 300 -- 默认增加5分钟
                        control["hour_set"],temp = math.modf(secTime/(60*60))
                        control["minute_set"],temp= math.modf((secTime/60)%60)
                        control["second_set"] = secTime%60
                    end
                end
                if(slotItems["temperature"] ~= nil) then
                    control["temp_set"] = getTemperatureValueWithDefault(slotItems["temperature"],0)
                    if(control["temp_set"] == "null") then
                        control["temp_set"] = 10 + temperature
                    else
                        control["temp_set"] = control["temp_set"] + temperature
                    end
                    if(control["temp_set"] > 235) then
                        control["temp_set"] = 235
                    end
                end

            elseif(intent["deviceVerb"]=="down") then
                if(slotItems["duration"] ~= nil) then
                    if(durationSecondValue ~= nil) then
                        durationSecondValue = secTime - durationSecondValue
                        if(durationSecondValue > 0) then
                            control["hour_set"],temp = math.modf(durationSecondValue/(60*60))
                            control["minute_set"],temp= math.modf((durationSecondValue/60)%60)
                            control["second_set"] = durationSecondValue%60
                        else
                            control["hour_set"] = 0
                            control["minute_set"] = 0
                            control["second_set"] = 0
                        end
                    else
                        secTime = secTime - 300
                        if(secTime > 0) then
                            control["hour_set"],temp = math.modf(durationSecondValue/(60*60))
                            control["minute_set"],temp= math.modf((durationSecondValue/60)%60)
                            control["second_set"] = durationSecondValue%60
                        else
                            control["hour_set"] = 0
                            control["minute_set"] = 0
                            control["second_set"] = 0
                        end
                    end
                elseif(slotItems["temperature"] ~= nil) then
                    control["temp_set"] = getTemperatureValueWithDefault(slotItems["temperature"],0)
                    if(control["temp_set"] == "null") then
                        control["temp_set"] =  temperature - 10
                    else
                        control["temp_set"] =  temperature - control["temp_set"]
                    end
                    if(control["temp_set"] < 30) then
                        control["temp_set"] = 30
                    end
                end
			elseif(intent["deviceVerb"]=="maximize") then
				control["temp_set"] = 230
			elseif(intent["deviceVerb"]=="minimize") then
				control["temp_set"] = 30
            end
        end
            retTable["control"] = control
    end
    return JSON.encode(retTable)
end


local function statusToJson(nluJson)
    local deviceinfo = nluJson["deviceinfo"]
    local status = nluJson["status"]

    if(status == nil) then
        status = "AA20B100000000000003310300000011001D3A4C00B400000000000000B40000DC"
    end

    local statusTable = {}
    local msgTable = {}

    msgTable["data"] = status
    statusTable["msg"] = msgTable
    statusTable["deviceinfo"] = deviceinfo

    local statusCmd = JSON.encode(statusTable)
    local statusJson = dataToJson(statusCmd)

    return JSON.decode(statusJson)["status"];

end

function nluToData(nluJson)
    -- do intentToJson
    if (#nluJson == 0) then
        return nil
    end
    local jsonTable = JSON.decode(intentToJson(nluJson))

    -- append "deviceinfo"
    local nluJson = JSON.decode(nluJson)
    local deviceinfo = nluJson["deviceinfo"]
    jsonTable["deviceinfo"] = deviceinfo

    -- do statusToJson and append
    local statusTemp = statusToJson(nluJson)
    jsonTable["status"] = statusTemp

    -- calculate （if necessary）e.g. increase & decrease TODO

    -- do jsonToData
    encodedJsonTable = JSON.encode(jsonTable)
	print(encodedJsonTable)
    -- response
    return jsonToData(encodedJsonTable)
end
