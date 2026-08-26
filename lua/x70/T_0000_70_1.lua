local JSON = require "cjson"
local uptable = {}
local paramTable = {}

uptable["KEY_VERSION"] = "version"
uptable["KEY_SUB_CMD"] = "sub_cmd"
uptable["KEY_BOX1_TYPE"] = "box1_type"
uptable["KEY_BOX1_STATUS"] = "box1_status"
uptable["KEY_BOX1_ADD_TIME_YEAR"] = "box1_add_time_year"
uptable["KEY_BOX1_ADD_TIME_MONTH"] = "box1_add_time_month"
uptable["KEY_BOX1_ADD_TIME_DAY"] = "box1_add_time_day"
uptable["KEY_BOX1_ADD_TIME_HOUR"] = "box1_add_time_hour"
uptable["KEY_BOX1_ADD_TIME_MINUTE"] = "box1_add_time_minute"
uptable["KEY_BOX1_ADD_TIME_SECOND"] = "box1_add_time_second"
uptable["KEY_BOX1_CLEAN_TIME_YEAR"] = "box1_clean_time_year"
uptable["KEY_BOX1_CLEAN_TIME_MONTH"] = "box1_clean_time_month"
uptable["KEY_BOX1_CLEAN_TIME_DAY"] = "box1_clean_time_day"
uptable["KEY_BOX1_CLEAN_TIME_HOUR"] = "box1_clean_time_hour"
uptable["KEY_BOX1_CLEAN_TIME_MINUTE"] = "box1_clean_time_minute"
uptable["KEY_BOX1_CLEAN_TIME_SECOND"] = "box1_clean_time_second"
uptable["KEY_BOX2_TYPE"] = "box2_type"
uptable["KEY_BOX2_STATUS"] = "box2_status"
uptable["KEY_BOX2_ADD_TIME_YEAR"] = "box2_add_time_year"
uptable["KEY_BOX2_ADD_TIME_MONTH"] = "box2_add_time_month"
uptable["KEY_BOX2_ADD_TIME_DAY"] = "box2_add_time_day"
uptable["KEY_BOX2_ADD_TIME_HOUR"] = "box2_add_time_hour"
uptable["KEY_BOX2_ADD_TIME_MINUTE"] = "box2_add_time_minute"
uptable["KEY_BOX2_ADD_TIME_SECOND"] = "box2_add_time_second"
uptable["KEY_BOX2_CLEAN_TIME_YEAR"] = "box2_clean_time_year"
uptable["KEY_BOX2_CLEAN_TIME_MONTH"] = "box2_clean_time_month"
uptable["KEY_BOX2_CLEAN_TIME_DAY"] = "box2_clean_time_day"
uptable["KEY_BOX2_CLEAN_TIME_HOUR"] = "box2_clean_time_hour"
uptable["KEY_BOX2_CLEAN_TIME_MINUTE"] = "box2_clean_time_minute"
uptable["KEY_BOX2_CLEAN_TIME_SECOND"] = "box2_clean_time_second"
uptable["KEY_BOX3_TYPE"] = "box3_type"
uptable["KEY_BOX3_STATUS"] = "box3_status"
uptable["KEY_BOX3_ADD_TIME_YEAR"] = "box3_add_time_year"
uptable["KEY_BOX3_ADD_TIME_MONTH"] = "box3_add_time_month"
uptable["KEY_BOX3_ADD_TIME_DAY"] = "box3_add_time_day"
uptable["KEY_BOX3_ADD_TIME_HOUR"] = "box3_add_time_hour"
uptable["KEY_BOX3_ADD_TIME_MINUTE"] = "box3_add_time_minute"
uptable["KEY_BOX3_ADD_TIME_SECOND"] = "box3_add_time_second"
uptable["KEY_BOX3_CLEAN_TIME_YEAR"] = "box3_clean_time_year"
uptable["KEY_BOX3_CLEAN_TIME_MONTH"] = "box3_clean_time_month"
uptable["KEY_BOX3_CLEAN_TIME_DAY"] = "box3_clean_time_day"
uptable["KEY_BOX3_CLEAN_TIME_HOUR"] = "box3_clean_time_hour"
uptable["KEY_BOX3_CLEAN_TIME_MINUTE"] = "box3_clean_time_minute"
uptable["KEY_BOX3_CLEAN_TIME_SECOND"] = "box3_clean_time_second"
uptable["KEY_BOX4_TYPE"] = "box4_type"
uptable["KEY_BOX4_STATUS"] = "box4_status"
uptable["KEY_BOX4_ADD_TIME_YEAR"] = "box4_add_time_year"
uptable["KEY_BOX4_ADD_TIME_MONTH"] = "box4_add_time_month"
uptable["KEY_BOX4_ADD_TIME_DAY"] = "box4_add_time_day"
uptable["KEY_BOX4_ADD_TIME_HOUR"] = "box4_add_time_hour"
uptable["KEY_BOX4_ADD_TIME_MINUTE"] = "box4_add_time_minute"
uptable["KEY_BOX4_ADD_TIME_SECOND"] = "box4_add_time_second"
uptable["KEY_BOX4_CLEAN_TIME_YEAR"] = "box4_clean_time_year"
uptable["KEY_BOX4_CLEAN_TIME_MONTH"] = "box4_clean_time_month"
uptable["KEY_BOX4_CLEAN_TIME_DAY"] = "box4_clean_time_day"
uptable["KEY_BOX4_CLEAN_TIME_HOUR"] = "box4_clean_time_hour"
uptable["KEY_BOX4_CLEAN_TIME_MINUTE"] = "box4_clean_time_minute"
uptable["KEY_BOX4_CLEAN_TIME_SECOND"] = "box4_clean_time_second"
uptable["KEY_BOX5_TYPE"] = "box5_type"
uptable["KEY_BOX5_STATUS"] = "box5_status"
uptable["KEY_BOX5_ADD_TIME_YEAR"] = "box5_add_time_year"
uptable["KEY_BOX5_ADD_TIME_MONTH"] = "box5_add_time_month"
uptable["KEY_BOX5_ADD_TIME_DAY"] = "box5_add_time_day"
uptable["KEY_BOX5_ADD_TIME_HOUR"] = "box5_add_time_hour"
uptable["KEY_BOX5_ADD_TIME_MINUTE"] = "box5_add_time_minute"
uptable["KEY_BOX5_ADD_TIME_SECOND"] = "box5_add_time_second"
uptable["KEY_BOX5_CLEAN_TIME_YEAR"] = "box5_clean_time_year"
uptable["KEY_BOX5_CLEAN_TIME_MONTH"] = "box5_clean_time_month"
uptable["KEY_BOX5_CLEAN_TIME_DAY"] = "box5_clean_time_day"
uptable["KEY_BOX5_CLEAN_TIME_HOUR"] = "box5_clean_time_hour"
uptable["KEY_BOX5_CLEAN_TIME_MINUTE"] = "box5_clean_time_minute"
uptable["KEY_BOX5_CLEAN_TIME_SECOND"] = "box5_clean_time_second"
uptable["KEY_BOX6_TYPE"] = "box6_type"
uptable["KEY_BOX6_STATUS"] = "box6_status"
uptable["KEY_BOX6_ADD_TIME_YEAR"] = "box6_add_time_year"
uptable["KEY_BOX6_ADD_TIME_MONTH"] = "box6_add_time_month"
uptable["KEY_BOX6_ADD_TIME_DAY"] = "box6_add_time_day"
uptable["KEY_BOX6_ADD_TIME_HOUR"] = "box6_add_time_hour"
uptable["KEY_BOX6_ADD_TIME_MINUTE"] = "box6_add_time_minute"
uptable["KEY_BOX6_ADD_TIME_SECOND"] = "box6_add_time_second"
uptable["KEY_BOX6_CLEAN_TIME_YEAR"] = "box6_clean_time_year"
uptable["KEY_BOX6_CLEAN_TIME_MONTH"] = "box6_clean_time_month"
uptable["KEY_BOX6_CLEAN_TIME_DAY"] = "box6_clean_time_day"
uptable["KEY_BOX6_CLEAN_TIME_HOUR"] = "box6_clean_time_hour"
uptable["KEY_BOX6_CLEAN_TIME_MINUTE"] = "box6_clean_time_minute"
uptable["KEY_BOX6_CLEAN_TIME_SECOND"] = "box6_clean_time_second"
uptable["KEY_BOX7_TYPE"] = "box7_type"
uptable["KEY_BOX7_STATUS"] = "box7_status"
uptable["KEY_BOX7_ADD_TIME_YEAR"] = "box7_add_time_year"
uptable["KEY_BOX7_ADD_TIME_MONTH"] = "box7_add_time_month"
uptable["KEY_BOX7_ADD_TIME_DAY"] = "box7_add_time_day"
uptable["KEY_BOX7_ADD_TIME_HOUR"] = "box7_add_time_hour"
uptable["KEY_BOX7_ADD_TIME_MINUTE"] = "box7_add_time_minute"
uptable["KEY_BOX7_ADD_TIME_SECOND"] = "box7_add_time_second"
uptable["KEY_BOX7_CLEAN_TIME_YEAR"] = "box7_clean_time_year"
uptable["KEY_BOX7_CLEAN_TIME_MONTH"] = "box7_clean_time_month"
uptable["KEY_BOX7_CLEAN_TIME_DAY"] = "box7_clean_time_day"
uptable["KEY_BOX7_CLEAN_TIME_HOUR"] = "box7_clean_time_hour"
uptable["KEY_BOX7_CLEAN_TIME_MINUTE"] = "box7_clean_time_minute"
uptable["KEY_BOX7_CLEAN_TIME_SECOND"] = "box7_clean_time_second"
uptable["KEY_BOX8_TYPE"] = "box8_type"
uptable["KEY_BOX8_STATUS"] = "box8_status"
uptable["KEY_BOX8_ADD_TIME_YEAR"] = "box8_add_time_year"
uptable["KEY_BOX8_ADD_TIME_MONTH"] = "box8_add_time_month"
uptable["KEY_BOX8_ADD_TIME_DAY"] = "box8_add_time_day"
uptable["KEY_BOX8_ADD_TIME_HOUR"] = "box8_add_time_hour"
uptable["KEY_BOX8_ADD_TIME_MINUTE"] = "box8_add_time_minute"
uptable["KEY_BOX8_ADD_TIME_SECOND"] = "box8_add_time_second"
uptable["KEY_BOX8_CLEAN_TIME_YEAR"] = "box8_clean_time_year"
uptable["KEY_BOX8_CLEAN_TIME_MONTH"] = "box8_clean_time_month"
uptable["KEY_BOX8_CLEAN_TIME_DAY"] = "box8_clean_time_day"
uptable["KEY_BOX8_CLEAN_TIME_HOUR"] = "box8_clean_time_hour"
uptable["KEY_BOX8_CLEAN_TIME_MINUTE"] = "box8_clean_time_minute"
uptable["KEY_BOX8_CLEAN_TIME_SECOND"] = "box8_clean_time_second"
uptable["KEY_CONTROL_RESULT"] = "control_result"
uptable["KEY_SEASONING_NUMBER"] = "seasoning_number"
uptable["KEY_SEASONING1_WEIGHT"] = "seasoning1_weight"
uptable["KEY_SEASONING2_WEIGHT"] = "seasoning2_weight"
uptable["KEY_SEASONING3_WEIGHT"] = "seasoning3_weight"
uptable["KEY_SEASONING4_WEIGHT"] = "seasoning4_weight"
uptable["KEY_SEASONING5_WEIGHT"] = "seasoning5_weight"
uptable["KEY_SEASONING6_WEIGHT"] = "seasoning6_weight"
uptable["KEY_SEASONING7_WEIGHT"] = "seasoning7_weight"
uptable["KEY_SEASONING8_WEIGHT"] = "seasoning8_weight"
uptable["KEY_SEASONING1_TYPE"] = "seasoning1_type"
uptable["KEY_SEASONING2_TYPE"] = "seasoning2_type"
uptable["KEY_SEASONING3_TYPE"] = "seasoning3_type"
uptable["KEY_SEASONING4_TYPE"] = "seasoning4_type"
uptable["KEY_SEASONING5_TYPE"] = "seasoning5_type"
uptable["KEY_SEASONING6_TYPE"] = "seasoning6_type"
uptable["KEY_SEASONING7_TYPE"] = "seasoning7_type"
uptable["KEY_SEASONING8_TYPE"] = "seasoning8_type"

uptable["VALUE_VERSION"] = "1"
uptable["VALUE_BOX_CLEAN"] = "box_clean"
uptable["VALUE_SEASONING_COMPLETE"] = "seasoning_complete"
uptable["VALUE_QUERY_DEVICE"] = "query_device"
uptable["VALUE_SEASONING_SET"] = "seasoning_set"
uptable["VALUE_SEASONING_OUTPUT"] = "seasoning_output"
uptable["VALUE_SUCCESS"] = "success"
uptable["VALUE_DATA_OVERFLOW"] = "data_overflow"
uptable["VALUE_EXECUTION"] = "execution"

uptable["BYTE_DEVICE_TYPE"] = 0x70
uptable["BYTE_CONTROL_REQUEST"] = 0x02
uptable["BYTE_QUERYL_REQUEST"] = 0x03
uptable["BYTE_AUTO_REPORT"] = 0x04
uptable["BYTE_PROTOCOL_HEAD"] = 0xAA
uptable["BYTE_PROTOCOL_LENGTH"] = 0x0A

paramTable["subCmd"] = 0
paramTable["box1Type"] = 0
paramTable["box1Status"] = 0
paramTable["box1AddTimeYear"] = 0
paramTable["box1AddTimeMonth"] = 0
paramTable["box1AddTimeDay"] = 0
paramTable["box1AddTimeHour"] = 0
paramTable["box1AddTimeMinute"] = 0
paramTable["box1AddTimeSecond"] = 0
paramTable["box1CleanTimeYear"] = 0
paramTable["box1CleanTimeMonth"] = 0
paramTable["box1CleanTimeDay"] = 0
paramTable["box1CleanTimeHour"] = 0
paramTable["box1CleanTimeMinute"] = 0
paramTable["box1CleanTimeSecond"] = 0
paramTable["box2Type"] = 0
paramTable["box2Status"] = 0
paramTable["box2AddTimeYear"] = 0
paramTable["box2AddTimeMonth"] = 0
paramTable["box2AddTimeDay"] = 0
paramTable["box2AddTimeHour"] = 0
paramTable["box2AddTimeMinute"] = 0
paramTable["box2AddTimeSecond"] = 0
paramTable["box2CleanTimeYear"] = 0
paramTable["box2CleanTimeMonth"] = 0
paramTable["box2CleanTimeDay"] = 0
paramTable["box2CleanTimeHour"] = 0
paramTable["box2CleanTimeMinute"] = 0
paramTable["box2CleanTimeSecond"] = 0
paramTable["box3Type"] = 0
paramTable["box3Status"] = 0
paramTable["box3AddTimeYear"] = 0
paramTable["box3AddTimeMonth"] = 0
paramTable["box3AddTimeDay"] = 0
paramTable["box3AddTimeHour"] = 0
paramTable["box3AddTimeMinute"] = 0
paramTable["box3AddTimeSecond"] = 0
paramTable["box3CleanTimeYear"] = 0
paramTable["box3CleanTimeMonth"] = 0
paramTable["box3CleanTimeDay"] = 0
paramTable["box3CleanTimeHour"] = 0
paramTable["box3CleanTimeMinute"] = 0
paramTable["box3CleanTimeSecond"] = 0
paramTable["box4Type"] = 0
paramTable["box4Status"] = 0
paramTable["box4AddTimeYear"] = 0
paramTable["box4AddTimeMonth"] = 0
paramTable["box4AddTimeDay"] = 0
paramTable["box4AddTimeHour"] = 0
paramTable["box4AddTimeMinute"] = 0
paramTable["box4AddTimeSecond"] = 0
paramTable["box4CleanTimeYear"] = 0
paramTable["box4CleanTimeMonth"] = 0
paramTable["box4CleanTimeDay"] = 0
paramTable["box4CleanTimeHour"] = 0
paramTable["box4CleanTimeMinute"] = 0
paramTable["box4CleanTimeSecond"] = 0
paramTable["box5Type"] = 0
paramTable["box5Status"] = 0
paramTable["box5AddTimeYear"] = 0
paramTable["box5AddTimeMonth"] = 0
paramTable["box5AddTimeDay"] = 0
paramTable["box5AddTimeHour"] = 0
paramTable["box5AddTimeMinute"] = 0
paramTable["box5AddTimeSecond"] = 0
paramTable["box5CleanTimeYear"] = 0
paramTable["box5CleanTimeMonth"] = 0
paramTable["box5CleanTimeDay"] = 0
paramTable["box5CleanTimeHour"] = 0
paramTable["box5CleanTimeMinute"] = 0
paramTable["box5CleanTimeSecond"] = 0
paramTable["box6Type"] = 0
paramTable["box6Status"] = 0
paramTable["box6AddTimeYear"] = 0
paramTable["box6AddTimeMonth"] = 0
paramTable["box6AddTimeDay"] = 0
paramTable["box6AddTimeHour"] = 0
paramTable["box6AddTimeMinute"] = 0
paramTable["box6AddTimeSecond"] = 0
paramTable["box6CleanTimeYear"] = 0
paramTable["box6CleanTimeMonth"] = 0
paramTable["box6CleanTimeDay"] = 0
paramTable["box6CleanTimeHour"] = 0
paramTable["box6CleanTimeMinute"] = 0
paramTable["box6CleanTimeSecond"] = 0
paramTable["box7Type"] = 0
paramTable["box7Status"] = 0
paramTable["box7AddTimeYear"] = 0
paramTable["box7AddTimeMonth"] = 0
paramTable["box7AddTimeDay"] = 0
paramTable["box7AddTimeHour"] = 0
paramTable["box7AddTimeMinute"] = 0
paramTable["box7AddTimeSecond"] = 0
paramTable["box7CleanTimeYear"] = 0
paramTable["box7CleanTimeMonth"] = 0
paramTable["box7CleanTimeDay"] = 0
paramTable["box7CleanTimeHour"] = 0
paramTable["box7CleanTimeMinute"] = 0
paramTable["box7CleanTimeSecond"] = 0
paramTable["box8Type"] = 0
paramTable["box8Status"] = 0
paramTable["box8AddTimeYear"] = 0
paramTable["box8AddTimeMonth"] = 0
paramTable["box8AddTimeDay"] = 0
paramTable["box8AddTimeHour"] = 0
paramTable["box8AddTimeMinute"] = 0
paramTable["box8AddTimeSecond"] = 0
paramTable["box8CleanTimeYear"] = 0
paramTable["box8CleanTimeMonth"] = 0
paramTable["box8CleanTimeDay"] = 0
paramTable["box8CleanTimeHour"] = 0
paramTable["box8CleanTimeMinute"] = 0
paramTable["box8CleanTimeSecond"] = 0
paramTable["controlResult"] = 0
paramTable["number"] = 1
paramTable["weight1"] = 0
paramTable["weight2"] = 0
paramTable["weight3"] = 0
paramTable["weight4"] = 0
paramTable["weight5"] = 0
paramTable["weight6"] = 0
paramTable["weight7"] = 0
paramTable["weight8"] = 0
paramTable["type1"] = 0
paramTable["type2"] = 0
paramTable["type3"] = 0
paramTable["type4"] = 0
paramTable["type5"] = 0
paramTable["type6"] = 0
paramTable["type7"] = 0
paramTable["type8"] = 0
paramTable["dataType"] = 0

function jsonToModel(controlJson)
    local controlCmd = controlJson
    if controlCmd[uptable["KEY_SUB_CMD"]] ~= nil then
        if controlCmd[uptable["KEY_SUB_CMD"]] == uptable["VALUE_SEASONING_SET"] then
            paramTable["subCmd"] = 0x02
        elseif controlCmd[uptable["KEY_SUB_CMD"]] ==
            uptable["VALUE_SEASONING_OUTPUT"] then
            paramTable["subCmd"] = 0x01
        end
    end
    if controlCmd[uptable["KEY_SEASONING_NUMBER"]] ~= nil then
        paramTable["number"] = checkBoundary(string2Int(
                                                 controlCmd[uptable["KEY_SEASONING_NUMBER"]]),
                                             1, 8)
    end
    if controlCmd[uptable["KEY_SEASONING1_WEIGHT"]] ~= nil then
        paramTable["weight1"] = checkBoundary(string2Int(
                                                  controlCmd[uptable["KEY_SEASONING1_WEIGHT"]]),
                                              1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING2_WEIGHT"]] ~= nil then
        paramTable["weight2"] = checkBoundary(string2Int(
                                                  controlCmd[uptable["KEY_SEASONING2_WEIGHT"]]),
                                              1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING3_WEIGHT"]] ~= nil then
        paramTable["weight3"] = checkBoundary(string2Int(
                                                  controlCmd[uptable["KEY_SEASONING3_WEIGHT"]]),
                                              1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING4_WEIGHT"]] ~= nil then
        paramTable["weight4"] = checkBoundary(string2Int(
                                                  controlCmd[uptable["KEY_SEASONING4_WEIGHT"]]),
                                              1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING5_WEIGHT"]] ~= nil then
        paramTable["weight5"] = checkBoundary(string2Int(
                                                  controlCmd[uptable["KEY_SEASONING5_WEIGHT"]]),
                                              1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING6_WEIGHT"]] ~= nil then
        paramTable["weight6"] = checkBoundary(string2Int(
                                                  controlCmd[uptable["KEY_SEASONING6_WEIGHT"]]),
                                              1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING7_WEIGHT"]] ~= nil then
        paramTable["weight7"] = checkBoundary(string2Int(
                                                  controlCmd[uptable["KEY_SEASONING7_WEIGHT"]]),
                                              1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING8_WEIGHT"]] ~= nil then
        paramTable["weight8"] = checkBoundary(string2Int(
                                                  controlCmd[uptable["KEY_SEASONING8_WEIGHT"]]),
                                              1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING1_TYPE"]] ~= nil then
        paramTable["type1"] = checkBoundary(string2Int(
                                                controlCmd[uptable["KEY_SEASONING1_TYPE"]]),
                                            1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING2_TYPE"]] ~= nil then
        paramTable["type2"] = checkBoundary(string2Int(
                                                controlCmd[uptable["KEY_SEASONING2_TYPE"]]),
                                            1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING3_TYPE"]] ~= nil then
        paramTable["type3"] = checkBoundary(string2Int(
                                                controlCmd[uptable["KEY_SEASONING3_TYPE"]]),
                                            1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING4_TYPE"]] ~= nil then
        paramTable["type4"] = checkBoundary(string2Int(
                                                controlCmd[uptable["KEY_SEASONING4_TYPE"]]),
                                            1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING5_TYPE"]] ~= nil then
        paramTable["type5"] = checkBoundary(string2Int(
                                                controlCmd[uptable["KEY_SEASONING5_TYPE"]]),
                                            1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING6_TYPE"]] ~= nil then
        paramTable["type6"] = checkBoundary(string2Int(
                                                controlCmd[uptable["KEY_SEASONING6_TYPE"]]),
                                            1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING7_TYPE"]] ~= nil then
        paramTable["type7"] = checkBoundary(string2Int(
                                                controlCmd[uptable["KEY_SEASONING7_TYPE"]]),
                                            1, 255)
    end
    if controlCmd[uptable["KEY_SEASONING8_TYPE"]] ~= nil then
        paramTable["type8"] = checkBoundary(string2Int(
                                                controlCmd[uptable["KEY_SEASONING8_TYPE"]]),
                                            1, 255)
    end
end

function binToModel(binData)
    if (#binData == 0) then return nil end
    local messageBytes = {}
    for i = 0, #binData do messageBytes[i] = 0 end
    for i = 0, #binData do messageBytes[i] = binData[i] end
    paramTable["subCmd"] = messageBytes[0]
    if (paramTable["dataType"] == 0x03) then
        paramTable["box1Type"] = messageBytes[1]
        paramTable["box1Status"] = messageBytes[2]
        paramTable["box1AddTimeYear"] = messageBytes[3]
        paramTable["box1AddTimeMonth"] = messageBytes[4]
        paramTable["box1AddTimeDay"] = messageBytes[5]
        paramTable["box1AddTimeHour"] = messageBytes[6]
        paramTable["box1AddTimeMinute"] = messageBytes[7]
        paramTable["box1AddTimeSecond"] = messageBytes[8]
        paramTable["box1CleanTimeYear"] = messageBytes[9]
        paramTable["box1CleanTimeMonth"] = messageBytes[10]
        paramTable["box1CleanTimeDay"] = messageBytes[11]
        paramTable["box1CleanTimeHour"] = messageBytes[12]
        paramTable["box1CleanTimeMinute"] = messageBytes[13]
        paramTable["box1CleanTimeSecond"] = messageBytes[14]
        if #messageBytes > 15 then
            paramTable["box2Type"] = messageBytes[15]
            paramTable["box2Status"] = messageBytes[16]
            paramTable["box2AddTimeYear"] = messageBytes[17]
            paramTable["box2AddTimeMonth"] = messageBytes[18]
            paramTable["box2AddTimeDay"] = messageBytes[19]
            paramTable["box2AddTimeHour"] = messageBytes[20]
            paramTable["box2AddTimeMinute"] = messageBytes[21]
            paramTable["box2AddTimeSecond"] = messageBytes[22]
            paramTable["box2CleanTimeYear"] = messageBytes[23]
            paramTable["box2CleanTimeMonth"] = messageBytes[24]
            paramTable["box2CleanTimeDay"] = messageBytes[25]
            paramTable["box2CleanTimeHour"] = messageBytes[26]
            paramTable["box2CleanTimeMinute"] = messageBytes[27]
            paramTable["box2CleanTimeSecond"] = messageBytes[28]
        end
        if #messageBytes > 29 then
            paramTable["box3Type"] = messageBytes[29]
            paramTable["box3Status"] = messageBytes[30]
            paramTable["box3AddTimeYear"] = messageBytes[31]
            paramTable["box3AddTimeMonth"] = messageBytes[32]
            paramTable["box3AddTimeDay"] = messageBytes[33]
            paramTable["box3AddTimeHour"] = messageBytes[34]
            paramTable["box3AddTimeMinute"] = messageBytes[35]
            paramTable["box3AddTimeSecond"] = messageBytes[36]
            paramTable["box3CleanTimeYear"] = messageBytes[37]
            paramTable["box3CleanTimeMonth"] = messageBytes[38]
            paramTable["box3CleanTimeDay"] = messageBytes[39]
            paramTable["box3CleanTimeHour"] = messageBytes[40]
            paramTable["box3CleanTimeMinute"] = messageBytes[41]
            paramTable["box3CleanTimeSecond"] = messageBytes[42]
        end
        if #messageBytes > 43 then
            paramTable["box4Type"] = messageBytes[43]
            paramTable["box4Status"] = messageBytes[44]
            paramTable["box4AddTimeYear"] = messageBytes[45]
            paramTable["box4AddTimeMonth"] = messageBytes[46]
            paramTable["box4AddTimeDay"] = messageBytes[47]
            paramTable["box4AddTimeHour"] = messageBytes[48]
            paramTable["box4AddTimeMinute"] = messageBytes[49]
            paramTable["box4AddTimeSecond"] = messageBytes[50]
            paramTable["box4CleanTimeYear"] = messageBytes[51]
            paramTable["box4CleanTimeMonth"] = messageBytes[52]
            paramTable["box4CleanTimeDay"] = messageBytes[53]
            paramTable["box4CleanTimeHour"] = messageBytes[54]
            paramTable["box4CleanTimeMinute"] = messageBytes[55]
            paramTable["box4CleanTimeSecond"] = messageBytes[56]
        end
        if #messageBytes > 57 then
            paramTable["box5Type"] = messageBytes[57]
            paramTable["box5Status"] = messageBytes[58]
            paramTable["box5AddTimeYear"] = messageBytes[59]
            paramTable["box5AddTimeMonth"] = messageBytes[60]
            paramTable["box5AddTimeDay"] = messageBytes[61]
            paramTable["box5AddTimeHour"] = messageBytes[62]
            paramTable["box5AddTimeMinute"] = messageBytes[63]
            paramTable["box5AddTimeSecond"] = messageBytes[64]
            paramTable["box5CleanTimeYear"] = messageBytes[65]
            paramTable["box5CleanTimeMonth"] = messageBytes[66]
            paramTable["box5CleanTimeDay"] = messageBytes[67]
            paramTable["box5CleanTimeHour"] = messageBytes[68]
            paramTable["box5CleanTimeMinute"] = messageBytes[69]
            paramTable["box5CleanTimeSecond"] = messageBytes[70]
        end
        if #messageBytes > 71 then
            paramTable["box6Type"] = messageBytes[71]
            paramTable["box6Status"] = messageBytes[72]
            paramTable["box6AddTimeYear"] = messageBytes[73]
            paramTable["box6AddTimeMonth"] = messageBytes[74]
            paramTable["box6AddTimeDay"] = messageBytes[75]
            paramTable["box6AddTimeHour"] = messageBytes[76]
            paramTable["box6AddTimeMinute"] = messageBytes[77]
            paramTable["box6AddTimeSecond"] = messageBytes[78]
            paramTable["box6CleanTimeYear"] = messageBytes[79]
            paramTable["box6CleanTimeMonth"] = messageBytes[80]
            paramTable["box6CleanTimeDay"] = messageBytes[81]
            paramTable["box6CleanTimeHour"] = messageBytes[82]
            paramTable["box6CleanTimeMinute"] = messageBytes[83]
            paramTable["box6CleanTimeSecond"] = messageBytes[84]
        end
        if #messageBytes > 85 then
            paramTable["box7Type"] = messageBytes[85]
            paramTable["box7Status"] = messageBytes[86]
            paramTable["box7AddTimeYear"] = messageBytes[87]
            paramTable["box7AddTimeMonth"] = messageBytes[88]
            paramTable["box7AddTimeDay"] = messageBytes[89]
            paramTable["box7AddTimeHour"] = messageBytes[90]
            paramTable["box7AddTimeMinute"] = messageBytes[91]
            paramTable["box7AddTimeSecond"] = messageBytes[92]
            paramTable["box7CleanTimeYear"] = messageBytes[93]
            paramTable["box7CleanTimeMonth"] = messageBytes[94]
            paramTable["box7CleanTimeDay"] = messageBytes[95]
            paramTable["box7CleanTimeHour"] = messageBytes[96]
            paramTable["box7CleanTimeMinute"] = messageBytes[97]
            paramTable["box7CleanTimeSecond"] = messageBytes[98]
        end
        if #messageBytes > 99 then
            paramTable["box8Type"] = messageBytes[99]
            paramTable["box8Status"] = messageBytes[100]
            paramTable["box8AddTimeYear"] = messageBytes[101]
            paramTable["box8AddTimeMonth"] = messageBytes[102]
            paramTable["box8AddTimeDay"] = messageBytes[103]
            paramTable["box8AddTimeHour"] = messageBytes[104]
            paramTable["box8AddTimeMinute"] = messageBytes[105]
            paramTable["box8AddTimeSecond"] = messageBytes[106]
            paramTable["box8CleanTimeYear"] = messageBytes[107]
            paramTable["box8CleanTimeMonth"] = messageBytes[108]
            paramTable["box8CleanTimeDay"] = messageBytes[109]
            paramTable["box8CleanTimeHour"] = messageBytes[110]
            paramTable["box8CleanTimeMinute"] = messageBytes[111]
            paramTable["box8CleanTimeSecond"] = messageBytes[112]
        end
    elseif paramTable["dataType"] == 0x02 then
        paramTable["controlResult"] = messageBytes[1]
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local json = decode(jsonCmd)
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    local infoM = {}
    local bodyBytes = {}
    if (query) then
        bodyBytes[0] = 0x01
        infoM = getTotalMsg(bodyBytes, uptable["BYTE_QUERYL_REQUEST"])
    elseif (control) then
        if (status) then jsonToModel(status) end
        if (control) then jsonToModel(control) end
        local index = checkBoundary(string2Int(
                                        control[uptable["KEY_SEASONING_NUMBER"]]),
                                    1, 8)
        for i = 0, index * 2 + 1 do bodyBytes[i] = 0 end
        bodyBytes[0] = paramTable["subCmd"]
        bodyBytes[1] = index
        if paramTable["subCmd"] == 0x01 then
            bodyBytes[2] = 0x01
            bodyBytes[3] = paramTable["weight1"]
            if index == 2 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["weight2"]
            elseif index == 3 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["weight2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["weight3"]
            elseif index == 4 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["weight2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["weight3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["weight4"]
            elseif index == 5 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["weight2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["weight3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["weight4"]
                bodyBytes[10] = 0x05
                bodyBytes[11] = paramTable["weight5"]
            elseif index == 6 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["weight2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["weight3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["weight4"]
                bodyBytes[10] = 0x05
                bodyBytes[11] = paramTable["weight5"]
                bodyBytes[12] = 0x06
                bodyBytes[13] = paramTable["weight6"]
            elseif index == 7 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["weight2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["weight3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["weight4"]
                bodyBytes[10] = 0x05
                bodyBytes[11] = paramTable["weight5"]
                bodyBytes[12] = 0x06
                bodyBytes[13] = paramTable["weight6"]
                bodyBytes[14] = 0x07
                bodyBytes[15] = paramTable["weight7"]
            elseif index == 8 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["weight2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["weight3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["weight4"]
                bodyBytes[10] = 0x05
                bodyBytes[11] = paramTable["weight5"]
                bodyBytes[12] = 0x06
                bodyBytes[13] = paramTable["weight6"]
                bodyBytes[14] = 0x07
                bodyBytes[15] = paramTable["weight7"]
                bodyBytes[16] = 0x08
                bodyBytes[17] = paramTable["weight8"]
            end
        elseif paramTable["subCmd"] == 0x02 then
            bodyBytes[2] = 0x01
            bodyBytes[3] = paramTable["type1"]
            if index == 2 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["type2"]
            elseif index == 3 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["type2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["type3"]
            elseif index == 4 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["type2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["type3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["type4"]
            elseif index == 5 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["type2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["type3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["type4"]
                bodyBytes[10] = 0x05
                bodyBytes[11] = paramTable["type5"]
            elseif index == 6 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["type2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["type3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["type4"]
                bodyBytes[10] = 0x05
                bodyBytes[11] = paramTable["type5"]
                bodyBytes[12] = 0x06
                bodyBytes[13] = paramTable["type6"]
            elseif index == 7 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["type2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["type3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["type4"]
                bodyBytes[10] = 0x05
                bodyBytes[11] = paramTable["type5"]
                bodyBytes[12] = 0x06
                bodyBytes[13] = paramTable["type6"]
                bodyBytes[14] = 0x07
                bodyBytes[15] = paramTable["type7"]
            elseif index == 8 then
                bodyBytes[4] = 0x02
                bodyBytes[5] = paramTable["type2"]
                bodyBytes[6] = 0x03
                bodyBytes[7] = paramTable["type3"]
                bodyBytes[8] = 0x04
                bodyBytes[9] = paramTable["type4"]
                bodyBytes[10] = 0x05
                bodyBytes[11] = paramTable["type5"]
                bodyBytes[12] = 0x06
                bodyBytes[13] = paramTable["type6"]
                bodyBytes[14] = 0x07
                bodyBytes[15] = paramTable["type7"]
                bodyBytes[16] = 0x08
                bodyBytes[17] = paramTable["type8"]
            end
        end
        infoM = getTotalMsg(bodyBytes, uptable["BYTE_CONTROL_REQUEST"])
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function getTotalMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + uptable["BYTE_PROTOCOL_LENGTH"] + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = uptable["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = bodyLength + uptable["BYTE_PROTOCOL_LENGTH"] + 1
    msgBytes[2] = uptable["BYTE_DEVICE_TYPE"]
    msgBytes[9] = cType
    for i = 0, bodyLength do
        msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]] = bodyData[i]
    end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
end

function dataToJson(jsonCmd)
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceinfo = json["deviceinfo"]
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then end
    local binData = json["msg"]["data"]
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    local msgSubType = 0
    info = string2table(binData)
    if (#info < 11) then return nil end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    msgLength = msgBytes[1]
    bodyLength = msgLength - uptable["BYTE_PROTOCOL_LENGTH"] - 1
    paramTable["dataType"] = msgBytes[9]
    msgSubType = msgBytes[10]
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then end
    local streams = {}
    streams[uptable["KEY_VERSION"]] = uptable["VALUE_VERSION"]
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + uptable["BYTE_PROTOCOL_LENGTH"]]
    end
    binToModel(bodyBytes)
    if (paramTable["dataType"] == uptable["BYTE_CONTROL_REQUEST"]) then
        if paramTable["subCmd"] == 0x01 then
            streams[uptable["KEY_SUB_CMD"]] = uptable["VALUE_SEASONING_OUTPUT"]
        elseif paramTable["subCmd"] == 0x02 then
            streams[uptable["KEY_SUB_CMD"]] = uptable["VALUE_SEASONING_SET"]
        end
        if paramTable["controlResult"] == 0x00 then
            streams[uptable["KEY_CONTROL_RESULT"]] = uptable["VALUE_SUCCESS"]
        elseif paramTable["controlResult"] == 0x01 then
            streams[uptable["KEY_CONTROL_RESULT"]] =
                uptable["VALUE_DATA_OVERFLOW"]
        elseif paramTable["controlResult"] == 0x02 then
            streams[uptable["KEY_CONTROL_RESULT"]] = uptable["VALUE_EXECUTION"]
        end
    elseif paramTable["dataType"] == uptable["BYTE_AUTO_REPORT"] then
        if paramTable["subCmd"] == 0x01 then
            streams[uptable["KEY_SUB_CMD"]] =
                uptable["VALUE_SEASONING_COMPLETE"]
        elseif paramTable["subCmd"] == 0x02 then
            streams[uptable["KEY_SUB_CMD"]] = uptable["VALUE_BOX_CLEAN"]
        end
    elseif paramTable["dataType"] == uptable["BYTE_QUERYL_REQUEST"] then
        if paramTable["subCmd"] == 0x01 then
            streams[uptable["KEY_SUB_CMD"]] = uptable["VALUE_QUERY_DEVICE"]
        end
        streams[uptable["KEY_BOX1_TYPE"]] = int2String(paramTable["box1Type"])
        if paramTable["box1Status"] == 0x01 then
            streams[uptable["KEY_BOX1_STATUS"]] = "missing"
        elseif paramTable["box1Status"] == 0x00 then
            streams[uptable["KEY_BOX1_STATUS"]] = "no"
        end
        streams[uptable["KEY_BOX1_ADD_TIME_YEAR"]] = int2String(
                                                         paramTable["box1AddTimeYear"])
        streams[uptable["KEY_BOX1_ADD_TIME_MONTH"]] = int2String(
                                                          paramTable["box1AddTimeMonth"])
        streams[uptable["KEY_BOX1_ADD_TIME_DAY"]] = int2String(
                                                        paramTable["box1AddTimeDay"])
        streams[uptable["KEY_BOX1_ADD_TIME_HOUR"]] = int2String(
                                                         paramTable["box1AddTimeHour"])
        streams[uptable["KEY_BOX1_ADD_TIME_MINUTE"]] = int2String(
                                                           paramTable["box1AddTimeMinute"])
        streams[uptable["KEY_BOX1_ADD_TIME_SECOND"]] = int2String(
                                                           paramTable["box1AddTimeSecond"])
        streams[uptable["KEY_BOX1_CLEAN_TIME_YEAR"]] = int2String(
                                                           paramTable["box1CleanTimeYear"])
        streams[uptable["KEY_BOX1_CLEAN_TIME_MONTH"]] = int2String(
                                                            paramTable["box1CleanTimeMonth"])
        streams[uptable["KEY_BOX1_CLEAN_TIME_DAY"]] = int2String(
                                                          paramTable["box1CleanTimeDay"])
        streams[uptable["KEY_BOX1_CLEAN_TIME_HOUR"]] = int2String(
                                                           paramTable["box1CleanTimeHour"])
        streams[uptable["KEY_BOX1_CLEAN_TIME_MINUTE"]] = int2String(
                                                             paramTable["box1CleanTimeMinute"])
        streams[uptable["KEY_BOX1_CLEAN_TIME_SECOND"]] = int2String(
                                                             paramTable["box1CleanTimeSecond"])
        streams[uptable["KEY_BOX2_TYPE"]] = int2String(paramTable["box2Type"])
        if paramTable["box2Status"] == 0x01 then
            streams[uptable["KEY_BOX2_STATUS"]] = "missing"
        elseif paramTable["box2Status"] == 0x00 then
            streams[uptable["KEY_BOX2_STATUS"]] = "no"
        end
        streams[uptable["KEY_BOX2_ADD_TIME_YEAR"]] = int2String(
                                                         paramTable["box2AddTimeYear"])
        streams[uptable["KEY_BOX2_ADD_TIME_MONTH"]] = int2String(
                                                          paramTable["box2AddTimeMonth"])
        streams[uptable["KEY_BOX2_ADD_TIME_DAY"]] = int2String(
                                                        paramTable["box2AddTimeDay"])
        streams[uptable["KEY_BOX2_ADD_TIME_HOUR"]] = int2String(
                                                         paramTable["box2AddTimeHour"])
        streams[uptable["KEY_BOX2_ADD_TIME_MINUTE"]] = int2String(
                                                           paramTable["box2AddTimeMinute"])
        streams[uptable["KEY_BOX2_ADD_TIME_SECOND"]] = int2String(
                                                           paramTable["box2AddTimeSecond"])
        streams[uptable["KEY_BOX2_CLEAN_TIME_YEAR"]] = int2String(
                                                           paramTable["box2CleanTimeYear"])
        streams[uptable["KEY_BOX2_CLEAN_TIME_MONTH"]] = int2String(
                                                            paramTable["box2CleanTimeMonth"])
        streams[uptable["KEY_BOX2_CLEAN_TIME_DAY"]] = int2String(
                                                          paramTable["box2CleanTimeDay"])
        streams[uptable["KEY_BOX2_CLEAN_TIME_HOUR"]] = int2String(
                                                           paramTable["box2CleanTimeHour"])
        streams[uptable["KEY_BOX2_CLEAN_TIME_MINUTE"]] = int2String(
                                                             paramTable["box2CleanTimeMinute"])
        streams[uptable["KEY_BOX2_CLEAN_TIME_SECOND"]] = int2String(
                                                             paramTable["box2CleanTimeSecond"])
        streams[uptable["KEY_BOX3_TYPE"]] = int2String(paramTable["box3Type"])
        if paramTable["box3Status"] == 0x01 then
            streams[uptable["KEY_BOX3_STATUS"]] = "missing"
        elseif paramTable["box3Status"] == 0x00 then
            streams[uptable["KEY_BOX3_STATUS"]] = "no"
        end
        streams[uptable["KEY_BOX3_ADD_TIME_YEAR"]] = int2String(
                                                         paramTable["box3AddTimeYear"])
        streams[uptable["KEY_BOX3_ADD_TIME_MONTH"]] = int2String(
                                                          paramTable["box3AddTimeMonth"])
        streams[uptable["KEY_BOX3_ADD_TIME_DAY"]] = int2String(
                                                        paramTable["box3AddTimeDay"])
        streams[uptable["KEY_BOX3_ADD_TIME_HOUR"]] = int2String(
                                                         paramTable["box3AddTimeHour"])
        streams[uptable["KEY_BOX3_ADD_TIME_MINUTE"]] = int2String(
                                                           paramTable["box3AddTimeMinute"])
        streams[uptable["KEY_BOX3_ADD_TIME_SECOND"]] = int2String(
                                                           paramTable["box3AddTimeSecond"])
        streams[uptable["KEY_BOX3_CLEAN_TIME_YEAR"]] = int2String(
                                                           paramTable["box3CleanTimeYear"])
        streams[uptable["KEY_BOX3_CLEAN_TIME_MONTH"]] = int2String(
                                                            paramTable["box3CleanTimeMonth"])
        streams[uptable["KEY_BOX3_CLEAN_TIME_DAY"]] = int2String(
                                                          paramTable["box3CleanTimeDay"])
        streams[uptable["KEY_BOX3_CLEAN_TIME_HOUR"]] = int2String(
                                                           paramTable["box3CleanTimeHour"])
        streams[uptable["KEY_BOX3_CLEAN_TIME_MINUTE"]] = int2String(
                                                             paramTable["box3CleanTimeMinute"])
        streams[uptable["KEY_BOX3_CLEAN_TIME_SECOND"]] = int2String(
                                                             paramTable["box3CleanTimeSecond"])
        streams[uptable["KEY_BOX4_TYPE"]] = int2String(paramTable["box4Type"])
        if paramTable["box4Status"] == 0x01 then
            streams[uptable["KEY_BOX4_STATUS"]] = "missing"
        elseif paramTable["box4Status"] == 0x00 then
            streams[uptable["KEY_BOX4_STATUS"]] = "no"
        end
        streams[uptable["KEY_BOX4_ADD_TIME_YEAR"]] = int2String(
                                                         paramTable["box4AddTimeYear"])
        streams[uptable["KEY_BOX4_ADD_TIME_MONTH"]] = int2String(
                                                          paramTable["box4AddTimeMonth"])
        streams[uptable["KEY_BOX4_ADD_TIME_DAY"]] = int2String(
                                                        paramTable["box4AddTimeDay"])
        streams[uptable["KEY_BOX4_ADD_TIME_HOUR"]] = int2String(
                                                         paramTable["box4AddTimeHour"])
        streams[uptable["KEY_BOX4_ADD_TIME_MINUTE"]] = int2String(
                                                           paramTable["box4AddTimeMinute"])
        streams[uptable["KEY_BOX4_ADD_TIME_SECOND"]] = int2String(
                                                           paramTable["box4AddTimeSecond"])
        streams[uptable["KEY_BOX4_CLEAN_TIME_YEAR"]] = int2String(
                                                           paramTable["box4CleanTimeYear"])
        streams[uptable["KEY_BOX4_CLEAN_TIME_MONTH"]] = int2String(
                                                            paramTable["box4CleanTimeMonth"])
        streams[uptable["KEY_BOX4_CLEAN_TIME_DAY"]] = int2String(
                                                          paramTable["box4CleanTimeDay"])
        streams[uptable["KEY_BOX4_CLEAN_TIME_HOUR"]] = int2String(
                                                           paramTable["box4CleanTimeHour"])
        streams[uptable["KEY_BOX4_CLEAN_TIME_MINUTE"]] = int2String(
                                                             paramTable["box4CleanTimeMinute"])
        streams[uptable["KEY_BOX4_CLEAN_TIME_SECOND"]] = int2String(
                                                             paramTable["box4CleanTimeSecond"])
        streams[uptable["KEY_BOX5_TYPE"]] = int2String(paramTable["box5Type"])
        if paramTable["box5Status"] == 0x01 then
            streams[uptable["KEY_BOX5_STATUS"]] = "missing"
        elseif paramTable["box5Status"] == 0x00 then
            streams[uptable["KEY_BOX5_STATUS"]] = "no"
        end
        streams[uptable["KEY_BOX5_ADD_TIME_YEAR"]] = int2String(
                                                         paramTable["box5AddTimeYear"])
        streams[uptable["KEY_BOX5_ADD_TIME_MONTH"]] = int2String(
                                                          paramTable["box5AddTimeMonth"])
        streams[uptable["KEY_BOX5_ADD_TIME_DAY"]] = int2String(
                                                        paramTable["box5AddTimeDay"])
        streams[uptable["KEY_BOX5_ADD_TIME_HOUR"]] = int2String(
                                                         paramTable["box5AddTimeHour"])
        streams[uptable["KEY_BOX5_ADD_TIME_MINUTE"]] = int2String(
                                                           paramTable["box5AddTimeMinute"])
        streams[uptable["KEY_BOX5_ADD_TIME_SECOND"]] = int2String(
                                                           paramTable["box5AddTimeSecond"])
        streams[uptable["KEY_BOX5_CLEAN_TIME_YEAR"]] = int2String(
                                                           paramTable["box5CleanTimeYear"])
        streams[uptable["KEY_BOX5_CLEAN_TIME_MONTH"]] = int2String(
                                                            paramTable["box5CleanTimeMonth"])
        streams[uptable["KEY_BOX5_CLEAN_TIME_DAY"]] = int2String(
                                                          paramTable["box5CleanTimeDay"])
        streams[uptable["KEY_BOX5_CLEAN_TIME_HOUR"]] = int2String(
                                                           paramTable["box5CleanTimeHour"])
        streams[uptable["KEY_BOX5_CLEAN_TIME_MINUTE"]] = int2String(
                                                             paramTable["box5CleanTimeMinute"])
        streams[uptable["KEY_BOX5_CLEAN_TIME_SECOND"]] = int2String(
                                                             paramTable["box5CleanTimeSecond"])
        streams[uptable["KEY_BOX6_TYPE"]] = int2String(paramTable["box6Type"])
        if paramTable["box6Status"] == 0x01 then
            streams[uptable["KEY_BOX6_STATUS"]] = "missing"
        elseif paramTable["box6Status"] == 0x00 then
            streams[uptable["KEY_BOX6_STATUS"]] = "no"
        end
        streams[uptable["KEY_BOX6_ADD_TIME_YEAR"]] = int2String(
                                                         paramTable["box6AddTimeYear"])
        streams[uptable["KEY_BOX6_ADD_TIME_MONTH"]] = int2String(
                                                          paramTable["box6AddTimeMonth"])
        streams[uptable["KEY_BOX6_ADD_TIME_DAY"]] = int2String(
                                                        paramTable["box6AddTimeDay"])
        streams[uptable["KEY_BOX6_ADD_TIME_HOUR"]] = int2String(
                                                         paramTable["box6AddTimeHour"])
        streams[uptable["KEY_BOX6_ADD_TIME_MINUTE"]] = int2String(
                                                           paramTable["box6AddTimeMinute"])
        streams[uptable["KEY_BOX6_ADD_TIME_SECOND"]] = int2String(
                                                           paramTable["box6AddTimeSecond"])
        streams[uptable["KEY_BOX6_CLEAN_TIME_YEAR"]] = int2String(
                                                           paramTable["box6CleanTimeYear"])
        streams[uptable["KEY_BOX6_CLEAN_TIME_MONTH"]] = int2String(
                                                            paramTable["box6CleanTimeMonth"])
        streams[uptable["KEY_BOX6_CLEAN_TIME_DAY"]] = int2String(
                                                          paramTable["box6CleanTimeDay"])
        streams[uptable["KEY_BOX6_CLEAN_TIME_HOUR"]] = int2String(
                                                           paramTable["box6CleanTimeHour"])
        streams[uptable["KEY_BOX6_CLEAN_TIME_MINUTE"]] = int2String(
                                                             paramTable["box6CleanTimeMinute"])
        streams[uptable["KEY_BOX6_CLEAN_TIME_SECOND"]] = int2String(
                                                             paramTable["box6CleanTimeSecond"])
        streams[uptable["KEY_BOX7_TYPE"]] = int2String(paramTable["box7Type"])
        if paramTable["box7Status"] == 0x01 then
            streams[uptable["KEY_BOX7_STATUS"]] = "missing"
        elseif paramTable["box7Status"] == 0x00 then
            streams[uptable["KEY_BOX7_STATUS"]] = "no"
        end
        streams[uptable["KEY_BOX7_ADD_TIME_YEAR"]] = int2String(
                                                         paramTable["box7AddTimeYear"])
        streams[uptable["KEY_BOX7_ADD_TIME_MONTH"]] = int2String(
                                                          paramTable["box7AddTimeMonth"])
        streams[uptable["KEY_BOX7_ADD_TIME_DAY"]] = int2String(
                                                        paramTable["box7AddTimeDay"])
        streams[uptable["KEY_BOX7_ADD_TIME_HOUR"]] = int2String(
                                                         paramTable["box7AddTimeHour"])
        streams[uptable["KEY_BOX7_ADD_TIME_MINUTE"]] = int2String(
                                                           paramTable["box7AddTimeMinute"])
        streams[uptable["KEY_BOX7_ADD_TIME_SECOND"]] = int2String(
                                                           paramTable["box7AddTimeSecond"])
        streams[uptable["KEY_BOX7_CLEAN_TIME_YEAR"]] = int2String(
                                                           paramTable["box7CleanTimeYear"])
        streams[uptable["KEY_BOX7_CLEAN_TIME_MONTH"]] = int2String(
                                                            paramTable["box7CleanTimeMonth"])
        streams[uptable["KEY_BOX7_CLEAN_TIME_DAY"]] = int2String(
                                                          paramTable["box7CleanTimeDay"])
        streams[uptable["KEY_BOX7_CLEAN_TIME_HOUR"]] = int2String(
                                                           paramTable["box7CleanTimeHour"])
        streams[uptable["KEY_BOX7_CLEAN_TIME_MINUTE"]] = int2String(
                                                             paramTable["box7CleanTimeMinute"])
        streams[uptable["KEY_BOX7_CLEAN_TIME_SECOND"]] = int2String(
                                                             paramTable["box7CleanTimeSecond"])
        streams[uptable["KEY_BOX8_TYPE"]] = int2String(paramTable["box8Type"])
        if paramTable["box8Status"] == 0x01 then
            streams[uptable["KEY_BOX8_STATUS"]] = "missing"
        elseif paramTable["box8Status"] == 0x00 then
            streams[uptable["KEY_BOX8_STATUS"]] = "no"
        end
        streams[uptable["KEY_BOX8_ADD_TIME_YEAR"]] = int2String(
                                                         paramTable["box8AddTimeYear"])
        streams[uptable["KEY_BOX8_ADD_TIME_MONTH"]] = int2String(
                                                          paramTable["box8AddTimeMonth"])
        streams[uptable["KEY_BOX8_ADD_TIME_DAY"]] = int2String(
                                                        paramTable["box8AddTimeDay"])
        streams[uptable["KEY_BOX8_ADD_TIME_HOUR"]] = int2String(
                                                         paramTable["box8AddTimeHour"])
        streams[uptable["KEY_BOX8_ADD_TIME_MINUTE"]] = int2String(
                                                           paramTable["box8AddTimeMinute"])
        streams[uptable["KEY_BOX8_ADD_TIME_SECOND"]] = int2String(
                                                           paramTable["box8AddTimeSecond"])
        streams[uptable["KEY_BOX8_CLEAN_TIME_YEAR"]] = int2String(
                                                           paramTable["box8CleanTimeYear"])
        streams[uptable["KEY_BOX8_CLEAN_TIME_MONTH"]] = int2String(
                                                            paramTable["box8CleanTimeMonth"])
        streams[uptable["KEY_BOX8_CLEAN_TIME_DAY"]] = int2String(
                                                          paramTable["box8CleanTimeDay"])
        streams[uptable["KEY_BOX8_CLEAN_TIME_HOUR"]] = int2String(
                                                           paramTable["box8CleanTimeHour"])
        streams[uptable["KEY_BOX8_CLEAN_TIME_MINUTE"]] = int2String(
                                                             paramTable["box8CleanTimeMinute"])
        streams[uptable["KEY_BOX8_CLEAN_TIME_SECOND"]] = int2String(
                                                             paramTable["box8CleanTimeSecond"])
    end
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end

function print_lua_table(lua_table, indent)
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

function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
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
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end

function encode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.encode(cmd)
    return tb
end

function decode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
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

function string2Int(data)
    if (not data) then data = tonumber("0") end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    return data
end

function int2String(data)
    if (not data) then data = tostring(0) end
    data = tostring(data)
    if (data == nil) then data = "0" end
    return data
end
