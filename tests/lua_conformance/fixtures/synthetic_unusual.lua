-- Synthetic "unusual" Lua file: no jsonToData / no updateGlobalPropertyValueByByte,
-- a constant with an unparsable RHS, and an odd header length.  Used to check
-- the extractor degrades gracefully instead of raising.

local BYTE_DEVICE_TYPE = 0xB1
local BYTE_PROTOCOL_LENGTH = 0x10
local SOME_TABLE = { 1, 2, 3 }
local COMPUTED = 1 + 2
local VALUE_MODE_A = "a"
local VALUE_MODE_B = "b"

function totally_different_entry_point(x)
    return x + 1
end
