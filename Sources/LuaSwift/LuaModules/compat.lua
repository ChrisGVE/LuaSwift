--[[
    compat.lua
    Lua Version Compatibility Module for LuaSwift

    Provides version detection and compatibility shims for running
    code written for older Lua versions (5.1, 5.2, 5.3) on Lua 5.4.

    Usage:
        local compat = require("compat")

        if compat.lua54 then
            print("Running on Lua 5.4")
        end

        -- bit32 library is available for legacy code
        local result = compat.bit32.band(0xFF, 0x0F)

    Copyright (c) 2026 Christian C. Berclaz
    Licensed under the MIT License
--]]

local compat = {}

-- Version detection
local major, minor = _VERSION:match("Lua (%d+)%.(%d+)")
major = tonumber(major) or 5
minor = tonumber(minor) or 4

compat.version = string.format("%d.%d", major, minor)
compat.lua51 = major == 5 and minor == 1
compat.lua52 = major == 5 and minor == 2
compat.lua53 = major == 5 and minor == 3
compat.lua54 = major == 5 and minor == 4
compat.lua55 = major == 5 and minor == 5
compat.luajit = type(jit) == "table"

-- Lua 5.4 already has these, but document them for clarity
compat.features = {
    table_unpack = true,      -- table.unpack available (5.2+)
    table_pack = true,        -- table.pack available (5.2+)
    utf8_library = true,      -- utf8 library available (5.3+)
    math_type = true,         -- math.type available (5.3+)
    integer_division = true,  -- // operator (5.3+)
    bitwise_ops = true,       -- &, |, ~, <<, >> operators (5.3+)
    const_close = true,       -- <const> and <close> (5.4+)
    warn_function = true,     -- warn() function (5.4+)
}

--[[
    bit32 compatibility library

    Provides the bit32 library that was removed in Lua 5.4.
    Uses Lua 5.3+ native bitwise operators internally.

    This allows legacy code that uses bit32.* to continue working.
--]]
compat.bit32 = {}

-- Helper: Normalize to 32-bit unsigned integer
local function normalize(x)
    return x % 0x100000000
end

-- band(...)
-- Returns the bitwise AND of all arguments
function compat.bit32.band(...)
    local args = {...}
    if #args == 0 then return 0xFFFFFFFF end
    local result = normalize(args[1])
    for i = 2, #args do
        result = result & normalize(args[i])
    end
    return normalize(result)
end

-- bor(...)
-- Returns the bitwise OR of all arguments
function compat.bit32.bor(...)
    local args = {...}
    if #args == 0 then return 0 end
    local result = normalize(args[1])
    for i = 2, #args do
        result = result | normalize(args[i])
    end
    return normalize(result)
end

-- bxor(...)
-- Returns the bitwise XOR of all arguments
function compat.bit32.bxor(...)
    local args = {...}
    if #args == 0 then return 0 end
    local result = normalize(args[1])
    for i = 2, #args do
        result = result ~ normalize(args[i])
    end
    return normalize(result)
end

-- bnot(x)
-- Returns the bitwise NOT of x
function compat.bit32.bnot(x)
    return normalize(~normalize(x))
end

-- lshift(x, disp)
-- Logical left shift
function compat.bit32.lshift(x, disp)
    if disp < 0 then
        return compat.bit32.rshift(x, -disp)
    end
    if disp >= 32 then return 0 end
    return normalize(normalize(x) << disp)
end

-- rshift(x, disp)
-- Logical right shift
function compat.bit32.rshift(x, disp)
    if disp < 0 then
        return compat.bit32.lshift(x, -disp)
    end
    if disp >= 32 then return 0 end
    return normalize(normalize(x) >> disp)
end

-- arshift(x, disp)
-- Arithmetic right shift (preserves sign)
function compat.bit32.arshift(x, disp)
    local val = normalize(x)
    if disp < 0 then
        return compat.bit32.lshift(x, -disp)
    end
    if disp >= 32 then
        if val >= 0x80000000 then
            return 0xFFFFFFFF
        else
            return 0
        end
    end
    if val >= 0x80000000 then
        -- Negative in 32-bit signed representation
        local shifted = val >> disp
        local mask = 0xFFFFFFFF << (32 - disp)
        return normalize(shifted | mask)
    else
        return val >> disp
    end
end

-- lrotate(x, disp)
-- Left rotate
function compat.bit32.lrotate(x, disp)
    disp = disp % 32
    if disp == 0 then return normalize(x) end
    local val = normalize(x)
    return normalize((val << disp) | (val >> (32 - disp)))
end

-- rrotate(x, disp)
-- Right rotate
function compat.bit32.rrotate(x, disp)
    disp = disp % 32
    if disp == 0 then return normalize(x) end
    local val = normalize(x)
    return normalize((val >> disp) | (val << (32 - disp)))
end

-- btest(...)
-- Returns true if bitwise AND of all arguments is not zero
function compat.bit32.btest(...)
    return compat.bit32.band(...) ~= 0
end

-- extract(n, field, width)
-- Extract bits from position field, width bits
function compat.bit32.extract(n, field, width)
    width = width or 1
    assert(field >= 0 and field < 32, "field out of range")
    assert(width > 0 and field + width <= 32, "width out of range")
    local mask = (1 << width) - 1
    return (normalize(n) >> field) & mask
end

-- replace(n, v, field, width)
-- Replace bits at position field with v, width bits
function compat.bit32.replace(n, v, field, width)
    width = width or 1
    assert(field >= 0 and field < 32, "field out of range")
    assert(width > 0 and field + width <= 32, "width out of range")
    local mask = (1 << width) - 1
    v = v & mask  -- Limit v to width bits
    local cleared = normalize(n) & ~(mask << field)
    return normalize(cleared | (v << field))
end

--[[
    Legacy compatibility aliases

    These provide aliases for functions that existed in older Lua versions
    but have different names or locations in Lua 5.4.
--]]

-- unpack was global in 5.1, moved to table.unpack in 5.2+
if not unpack then
    -- Already table.unpack in 5.4, but provide global alias if needed
    compat.unpack = table.unpack
else
    compat.unpack = unpack
end

-- loadstring was removed in 5.2+ (use load instead)
compat.loadstring = load

-- setfenv/getfenv were removed in 5.2+
-- These cannot be fully emulated in 5.2+, but we provide stubs
compat.setfenv = function(f, env)
    -- Cannot be emulated, but provide stub for compatibility checking
    error("setfenv is not supported in Lua 5.2+", 2)
end

compat.getfenv = function(f)
    -- Cannot be emulated, but provide stub for compatibility checking
    error("getfenv is not supported in Lua 5.2+", 2)
end

-- module() function from 5.1 (deprecated in 5.2, removed in 5.3)
-- Not provided as it encourages bad practices

--[[
    Install global polyfills

    Call this function to install compatibility polyfills into the global
    environment. This modifies global state and should be used carefully.
--]]
function compat.install()
    -- Install bit32 globally if not present
    if not bit32 then
        bit32 = compat.bit32
    end

    -- Install global unpack if not present (5.1 compatibility)
    if not rawget(_G, "unpack") then
        rawset(_G, "unpack", table.unpack)
    end

    -- Install loadstring if not present
    if not rawget(_G, "loadstring") then
        rawset(_G, "loadstring", load)
    end

    return compat
end

--[[
    Check if code uses deprecated features

    Returns a table of warnings about deprecated features found in code.
--]]
function compat.check_deprecated(code)
    local warnings = {}

    if code:match("setfenv") then
        table.insert(warnings, "setfenv is not supported in Lua 5.2+")
    end
    if code:match("getfenv") then
        table.insert(warnings, "getfenv is not supported in Lua 5.2+")
    end
    if code:match("module%s*%(") then
        table.insert(warnings, "module() is deprecated since Lua 5.2")
    end
    if code:match("bit32%.") then
        table.insert(warnings, "bit32 was removed in Lua 5.4, use native operators")
    end

    return warnings
end

--[[
    Version comparison utilities
--]]

-- Compare version strings (e.g., "5.3" < "5.4")
function compat.version_compare(v1, v2)
    local major1, minor1 = v1:match("(%d+)%.(%d+)")
    local major2, minor2 = v2:match("(%d+)%.(%d+)")
    major1, minor1 = tonumber(major1) or 0, tonumber(minor1) or 0
    major2, minor2 = tonumber(major2) or 0, tonumber(minor2) or 0

    if major1 ~= major2 then
        return major1 - major2
    end
    return minor1 - minor2
end

-- Check if current version is at least the given version
function compat.version_at_least(v)
    return compat.version_compare(compat.version, v) >= 0
end

return compat
