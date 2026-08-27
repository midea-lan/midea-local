local JSON = require 'cjson'
local KEY_VERSION = 'version'
local KEY_WORK_STATUS = 'work_status'
local KEY_WORK_MODE = 'work_mode'
local KEY_MOVE_DIRECTION = 'move_direction'

local VALUE_VERSION = 6
local VALUE_FUNCTION_ON = 'on'
local VALUE_FUNCTION_OFF = 'off'
local VALUE_STATUS_CHARGE = 'charge'
local VALUE_STATUS_WORK = 'work'
local VALUE_STATUS_STOP = 'stop'
local VALUE_STATUS_CHARGING = 'charging'
local VALUE_STATUS_CHARGING_FINISH = 'charge_finish'
local VALUE_STATUS_WORK_FINISH = 'work_finish'
local VALUE_STATUS_WORK_SET = 'set'
local VALUE_MODE_NO = 'none'
local VALUE_MODE_RANDOM = 'random'
local VALUE_MODE_ARC = 'arc'
local VALUE_MODE_EDGE = 'edge'
local VALUE_MODE_EMPHASES = 'emphases'
local VALUE_MODE_SCREW = 'screw'
local VALUE_MODE_AUTO = 'auto'
local VALUE_DIRECTION_NO = 'none'
local VALUE_DIRECTION_FORWARD = 'forward'
local VALUE_DIRECTION_BACK = 'back'
local VALUE_DIRECTION_LEFT = 'left'
local VALUE_DIRECTION_RIGHT = 'right'
local VALUE_DIRECTION_LEFT_FORWARD = 'left_forward'
local VALUE_DIRECTION_RIGHT_FORWARD = 'right_forward'
local VALUE_DIRECTION_LEFT_BACK = 'left_back'
local VALUE_DIRECTION_RIGHT_BACK = 'right_back'

local BYTE_DEVICE_TYPE = 0xB8
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_STATUS_CHARGE = 0x01
local BYTE_STATUS_WORK = 0x02
local BYTE_STATUS_STOP = 0x03
local BYTE_STATUS_CHARGING = 0x04
local BYTE_STATUS_CHARGE_FINISH = 0x06
local BYTE_STATUS_FINISH = 0x05
local BYTE_STATUS_SET = 0x07
local BYTE_CONTROL_AUTO = 0x02
local BYTE_MODE_MANUAL = 0x01
local BYTE_MODE_NO = 0x00
local BYTE_MODE_RANDOM = 0x01
local BYTE_MODE_ARC = 0x02
local BYTE_MODE_EDGE = 0x03
local BYTE_MODE_EMPHASES = 0x04
local BYTE_MODE_SCREW = 0x05
local BYTE_MODE_AUTO = 0x08
local BYTE_DIRECTION_NO = 0x00
local BYTE_DIRECTION_FORWARD = 0x01
local BYTE_DIRECTION_BACK = 0x02
local BYTE_DIRECTION_LEFT = 0x03
local BYTE_DIRECTION_RIGHT = 0x04
local BYTE_DIRECTION_FORWARD_LEFT = 0x05
local BYTE_DIRECTION_FORWARD_RIGHT = 0x06
local BYTE_DIRECTION_BACK_LEFT = 0x07
local BYTE_DIRECTION_BACK_RIGHT = 0x08

local workStatusValue
local controlModeValue
local workModeValue
local moveDirectionValue = 0
local deviceSubType = '0'
local dataType = 0

local function getSoftVersion()
    if deviceSubType == '11' or deviceSubType == '8' then
        return 1
    else
        return 0
    end
end

function jsonToModel(stateJson, controlJson)
    local oldState = stateJson
    local controlCmd = controlJson
    if getSoftVersion() == 1 then
        if (controlCmd[KEY_MOVE_DIRECTION] ~= nil) then
            if (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_FORWARD) then
                moveDirectionValue = BYTE_DIRECTION_FORWARD
            elseif (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_BACK) then
                moveDirectionValue = BYTE_DIRECTION_BACK
            elseif (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_LEFT) then
                moveDirectionValue = BYTE_DIRECTION_LEFT
            elseif (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_RIGHT) then
                moveDirectionValue = BYTE_DIRECTION_RIGHT
            elseif (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_LEFT_FORWARD) then
                moveDirectionValue = BYTE_DIRECTION_FORWARD_LEFT
            elseif (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_RIGHT_FORWARD) then
                moveDirectionValue = BYTE_DIRECTION_FORWARD_RIGHT
            elseif (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_LEFT_BACK) then
                moveDirectionValue = BYTE_DIRECTION_BACK_LEFT
            elseif (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_RIGHT_BACK) then
                moveDirectionValue = BYTE_DIRECTION_BACK_RIGHT
            elseif (controlCmd[KEY_MOVE_DIRECTION] == VALUE_DIRECTION_NO) then
                moveDirectionValue = BYTE_DIRECTION_NO
            end
        end
        if (controlCmd[KEY_WORK_MODE] ~= nil) then
            if (controlCmd[KEY_WORK_MODE] == VALUE_MODE_AUTO) then
                workModeValue = BYTE_MODE_AUTO
            elseif (controlCmd[KEY_WORK_MODE] == VALUE_MODE_RANDOM) then
                workModeValue = BYTE_MODE_RANDOM
            elseif (controlCmd[KEY_WORK_MODE] == VALUE_MODE_ARC) then
                workModeValue = BYTE_MODE_ARC
            elseif (controlCmd[KEY_WORK_MODE] == VALUE_MODE_EDGE) then
                workModeValue = BYTE_MODE_EDGE
            elseif (controlCmd[KEY_WORK_MODE] == VALUE_MODE_EMPHASES) then
                workModeValue = BYTE_MODE_EMPHASES
            elseif (controlCmd[KEY_WORK_MODE] == VALUE_MODE_SCREW) then
                workModeValue = BYTE_MODE_EMPHASES
            elseif (controlCmd[KEY_WORK_MODE] == VALUE_MODE_NO) then
                workModeValue = BYTE_MODE_NO
            elseif (controlCmd[KEY_WORK_MODE] == 'bed') then
                workModeValue = 0x06
            elseif (controlCmd[KEY_WORK_MODE] == 'wide_screw') then
                workModeValue = 0x07
            elseif (controlCmd[KEY_WORK_MODE] == 'area') then
                workModeValue = 0x09
            elseif (controlCmd[KEY_WORK_MODE] == 'deep') then
                workModeValue = 0x0a
            end
        end
        if (controlCmd[KEY_WORK_STATUS] ~= nil) then
            if (controlCmd[KEY_WORK_STATUS] == VALUE_STATUS_CHARGE) then
                workStatusValue = BYTE_STATUS_CHARGE
            elseif (controlCmd[KEY_WORK_STATUS] == VALUE_STATUS_WORK) then
                workStatusValue = BYTE_STATUS_WORK
            elseif (controlCmd[KEY_WORK_STATUS] == VALUE_STATUS_STOP) then
                workStatusValue = BYTE_STATUS_STOP
            end
        end
        if ((workModeValue == BYTE_MODE_NO) and (moveDirectionValue ~= BYTE_DIRECTION_NO)) then
            controlModeValue = BYTE_MODE_MANUAL
        elseif ((workModeValue ~= BYTE_MODE_NO) and (moveDirectionValue == BYTE_DIRECTION_NO)) then
            controlModeValue = BYTE_CONTROL_AUTO
        else
            controlModeValue = 0
        end
    else
        if (controlCmd[KEY_MOVE_DIRECTION] ~= nil) then
            temValue = controlCmd[KEY_MOVE_DIRECTION]
            controlModeValue = BYTE_MODE_MANUAL
            workStatusValue = BYTE_STATUS_STOP
            workModeValue = BYTE_MODE_NO
            if (temValue == VALUE_DIRECTION_FORWARD) then
                moveDirectionValue = BYTE_DIRECTION_FORWARD
            elseif (temValue == VALUE_DIRECTION_BACK) then
                moveDirectionValue = BYTE_DIRECTION_BACK
            elseif (temValue == VALUE_DIRECTION_LEFT) then
                moveDirectionValue = BYTE_DIRECTION_LEFT
            elseif (temValue == VALUE_DIRECTION_RIGHT) then
                moveDirectionValue = BYTE_DIRECTION_RIGHT
            elseif (temValue == VALUE_DIRECTION_LEFT_FORWARD) then
                moveDirectionValue = BYTE_DIRECTION_FORWARD_LEFT
            elseif (temValue == VALUE_DIRECTION_RIGHT_FORWARD) then
                moveDirectionValue = BYTE_DIRECTION_FORWARD_RIGHT
            elseif (temValue == VALUE_DIRECTION_LEFT_BACK) then
                moveDirectionValue = BYTE_DIRECTION_BACK_LEFT
            elseif (temValue == VALUE_DIRECTION_RIGHT_BACK) then
                moveDirectionValue = BYTE_DIRECTION_BACK_RIGHT
            elseif (temValue == VALUE_DIRECTION_NO) then
                moveDirectionValue = BYTE_DIRECTION_NO
            end
        end
        if (controlCmd[KEY_WORK_MODE] ~= nil) then
            temValue = controlCmd[KEY_WORK_MODE]
            workModeValue = BYTE_MODE_AUTO
            controlModeValue = BYTE_CONTROL_AUTO
            if (temValue == VALUE_MODE_AUTO) then
                workModeValue = BYTE_MODE_AUTO
            elseif (temValue == VALUE_MODE_RANDOM) then
                workModeValue = BYTE_MODE_RANDOM
            elseif (temValue == VALUE_MODE_ARC) then
                workModeValue = BYTE_MODE_ARC
            elseif (temValue == VALUE_MODE_EDGE) then
                workModeValue = BYTE_MODE_EDGE
            elseif (temValue == VALUE_MODE_EMPHASES) then
                workModeValue = BYTE_MODE_EMPHASES
            elseif (temValue == VALUE_MODE_SCREW) then
                workModeValue = BYTE_MODE_EMPHASES
            elseif (temValue == VALUE_MODE_NO) then
                workModeValue = BYTE_MODE_NO
            elseif (temValue == 'bed') then
                workModeValue = 0x06
            elseif (temValue == 'wide_screw') then
                workModeValue = 0x07
            elseif (temValue == 'area') then
                workModeValue = 0x09
            elseif (temValue == 'deep') then
                workModeValue = 0x0a
            end
            if ((workModeValue == BYTE_MODE_NO) and (moveDirectionValue ~= BYTE_DIRECTION_NO)) then
                controlModeValue = BYTE_MODE_MANUAL
            end
        end
        if (controlCmd[KEY_WORK_STATUS] ~= nil) then
            temValue = controlCmd[KEY_WORK_STATUS]
            if (temValue == VALUE_STATUS_CHARGE) then
                workStatusValue = BYTE_STATUS_CHARGE
            elseif (temValue == VALUE_STATUS_WORK) then
                workStatusValue = BYTE_STATUS_WORK
                moveDirectionValue = BYTE_DIRECTION_NO
            elseif (temValue == VALUE_STATUS_STOP) then
                workStatusValue = BYTE_STATUS_STOP
            end
        end
    end
end
local function binToModel(binData)
    if (#binData == 0) then
        return nil
    end
    local messageBytes = binData
    if getSoftVersion() == 1 then
        if ((dataType == 0x03) and (messageBytes[0] == 0x32) and (messageBytes[1] == 0x01)) then
            workStatusValue = messageBytes[2]
            controlModeValue = messageBytes[4]
            moveDirectionValue = messageBytes[5]
            workModeValue = messageBytes[6]
        elseif ((dataType == 0x04) and (messageBytes[0] == 0x42)) then
            workStatusValue = messageBytes[1]
            controlModeValue = messageBytes[3]
            moveDirectionValue = messageBytes[4]
            workModeValue = messageBytes[5]
        elseif ((dataType == 0x02) and (messageBytes[0] == 0x22)) then
            workStatusValue = messageBytes[1]
            controlModeValue = messageBytes[3]
            moveDirectionValue = messageBytes[4]
            workModeValue = messageBytes[5]
        end
    else
        workStatusValue = messageBytes[0]
        controlModeValue = messageBytes[1]
        workModeValue = messageBytes[2]
        moveDirectionValue = messageBytes[4]
    end
end

function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then
        return nil
    end
    local json = decode(jsonCmd)
    deviceSubType = json['deviceinfo']['deviceSubType']
    local query = json['query']
    local control = json['control']
    local status = json['status']
    local infoM = {}
    if getSoftVersion() == 1 then
        local bodyLength = 0
        if (query) then
            bodyLength = 1
        elseif (control) then
            bodyLength = 9
        end
        local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
        local bodyBytes = {}
        for i = 0, bodyLength do
            bodyBytes[i] = 0
        end
        local msgBytes = {}
        for i = 0, msgLength do
            msgBytes[i] = 0
        end
        msgBytes[0] = BYTE_PROTOCOL_HEAD
        msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
        msgBytes[2] = BYTE_DEVICE_TYPE
        if (query) then
            bodyBytes[0] = 0x32
            bodyBytes[1] = 0x01
            msgBytes[9] = BYTE_QUERY_REQUEST
        elseif (control) then
            if (control and status) then
                jsonToModel(status, control)
            end
            bodyBytes[0] = 0x22
            bodyBytes[1] = workStatusValue
            bodyBytes[3] = controlModeValue
            bodyBytes[4] = moveDirectionValue
            bodyBytes[5] = workModeValue
            msgBytes[9] = BYTE_CONTROL_REQUEST
        end
        for i = 0, bodyLength do
            msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
        end
        msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
        for i = 1, msgLength + 1 do
            infoM[i] = msgBytes[i - 1]
        end
    else
        local bodyLength = 0
        if (query) then
            bodyLength = 0
        elseif (control) then
            bodyLength = 10
        end
        local msgLength = bodyLength + BYTE_PROTOCOL_LENGTH + 1
        local bodyBytes = {}
        for i = 0, bodyLength do
            bodyBytes[i] = 0
        end
        local msgBytes = {}
        for i = 0, msgLength do
            msgBytes[i] = 0
        end
        msgBytes[0] = BYTE_PROTOCOL_HEAD
        msgBytes[1] = bodyLength + BYTE_PROTOCOL_LENGTH + 1
        msgBytes[2] = BYTE_DEVICE_TYPE
        if (query) then
            msgBytes[9] = BYTE_QUERY_REQUEST
        elseif (control) then
            if (control and status) then
                jsonToModel(status, control)
            end
            bodyBytes[0] = workStatusValue
            bodyBytes[1] = controlModeValue
            bodyBytes[2] = workModeValue
            bodyBytes[4] = moveDirectionValue
            msgBytes[9] = BYTE_CONTROL_REQUEST
        end
        for i = 0, bodyLength do
            msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
        end
        msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
        for i = 1, msgLength + 1 do
            infoM[i] = msgBytes[i - 1]
        end
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end

function dataToJson(jsonCmd)
    if (not jsonCmd) then
        return nil
    end
    local json = decode(jsonCmd)
    local deviceinfo = json['deviceinfo']
    deviceSubType = deviceinfo['deviceSubType']
    local binData = json['msg']['data']
    local info = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    info = string2table(binData)
    dataType = info[10]
    if ((dataType ~= 0x02) and (dataType ~= 0x03) and (dataType ~= 0x04)) then
        return nil
    end
    for i = 1, #info do
        msgBytes[i - 1] = info[i]
    end
    msgLength = msgBytes[1]
    bodyLength = msgLength - BYTE_PROTOCOL_LENGTH - 1
    local sumRes = makeSum(msgBytes, 1, msgLength - 1)
    if (sumRes ~= msgBytes[msgLength]) then
    end
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + BYTE_PROTOCOL_LENGTH]
    end
    binToModel(bodyBytes)
    local streams = {}
    streams[KEY_VERSION] = VALUE_VERSION
    if (workStatusValue == BYTE_STATUS_WORK) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_WORK
    elseif (workStatusValue == BYTE_STATUS_STOP) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_STOP
    elseif (workStatusValue == BYTE_STATUS_CHARGE) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_CHARGE
    elseif (workStatusValue == BYTE_STATUS_CHARGING) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_CHARGING
    elseif (workStatusValue == BYTE_STATUS_CHARGE_FINISH) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_CHARGING_FINISH
    elseif (workStatusValue == BYTE_STATUS_FINISH) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_WORK_FINISH
    elseif (workStatusValue == BYTE_STATUS_SET) then
        streams[KEY_WORK_STATUS] = VALUE_STATUS_WORK_SET
    end
    if (moveDirectionValue == BYTE_DIRECTION_FORWARD) then
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_FORWARD
    elseif (moveDirectionValue == BYTE_DIRECTION_BACK) then
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_BACK
    elseif (moveDirectionValue == BYTE_DIRECTION_LEFT) then
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_LEFT
    elseif (moveDirectionValue == BYTE_DIRECTION_RIGHT) then
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_RIGHT
    elseif (moveDirectionValue == BYTE_DIRECTION_FORWARD_LEFT) then
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_LEFT_FORWARD
    elseif (moveDirectionValue == BYTE_DIRECTION_FORWARD_RIGHT) then
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_RIGHT_FORWARD
    elseif (moveDirectionValue == BYTE_DIRECTION_BACK_LEFT) then
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_LEFT_BACK
    elseif (moveDirectionValue == BYTE_DIRECTION_BACK_RIGHT) then
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_RIGHT_BACK
    else
        streams[KEY_MOVE_DIRECTION] = VALUE_DIRECTION_NO
    end
    if (workModeValue == BYTE_MODE_NO) then
        streams[KEY_WORK_MODE] = VALUE_MODE_NO
    elseif (workModeValue == BYTE_MODE_RANDOM) then
        streams[KEY_WORK_MODE] = VALUE_MODE_RANDOM
    elseif (workModeValue == BYTE_MODE_ARC) then
        streams[KEY_WORK_MODE] = VALUE_MODE_ARC
    elseif (workModeValue == BYTE_MODE_EDGE) then
        streams[KEY_WORK_MODE] = VALUE_MODE_EDGE
    elseif (workModeValue == BYTE_MODE_EMPHASES) then
        streams[KEY_WORK_MODE] = VALUE_MODE_EMPHASES
    elseif (workModeValue == BYTE_MODE_SCREW) then
        streams[KEY_WORK_MODE] = VALUE_MODE_SCREW
    elseif (workModeValue == 0x06) then
        streams[KEY_WORK_MODE] = 'bed'
    elseif (workModeValue == 0x07) then
        streams[KEY_WORK_MODE] = 'wide_screw'
    elseif (workModeValue == 0x08) then
        streams[KEY_WORK_MODE] = 'auto'
    elseif (workModeValue == 0x09) then
        streams[KEY_WORK_MODE] = 'area'
    elseif (workModeValue == 0x0a) then
        streams[KEY_WORK_MODE] = 'deep'
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
