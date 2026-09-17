-- Synthetic "classic" Midea Lua plugin used by the extractor unit tests.
-- It mimics the structure shared by the real small/old files (E1, AC v22, ...)
-- without reproducing any proprietary content.

local JSON = require "cjson"

local KEY_POWER = "power"
local KEY_MODE = "mode"
local KEY_TEMPERATURE = "temperature"

local VALUE_VERSION = 7
local VALUE_MODE_AUTO = "auto"
local VALUE_MODE_COOL = "cool"
local VALUE_MODE_HEAT = "heat"

local BYTE_DEVICE_TYPE = 0xAC
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03

local BYTE_MODE_AUTO = 0x10
local BYTE_MODE_COOL = 0x20
local BYTE_MODE_HEAT = 0x30

local powerValue
local modeValue
local temperatureValue
local errorCode
local indoorTemperatureValue

function updateGlobalPropertyValueByByte(messageBytes)
    powerValue = bit.band(messageBytes[1], 0x01)
    modeValue = bit.band(messageBytes[2], 0x30)
    temperatureValue = bit.band(messageBytes[2], 0x0F)
    errorCode = messageBytes[5]
    indoorTemperatureValue = (messageBytes[11] - 50) / 2
    if bit.band(messageBytes[3], 0x80) == 0x80 then
        ecoValue = 0x80
    end
end

function jsonToData(jsonCmd)
    local bodyBytes = {}
    local json = decode(jsonCmd)
    local query = json["query"]
    local control = json["control"]
    if (query) then
        bodyBytes[0] = 0x41
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
    elseif (control) then
        bodyBytes[0] = 0xC3
        bodyBytes[1] = powerValue
        bodyBytes[2] = bit.bor(modeValue, temperatureValue)
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
    end
end
