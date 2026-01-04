--[[
    compat.lua
    Lua Version Compatibility Module for LuaSwift

    Provides version detection and compatibility shims for running
    code across different Lua versions (5.1, 5.2, 5.3, 5.4, 5.5).

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

-- Feature detection (varies by version)
compat.features = {
    table_unpack = minor >= 2 or compat.luajit,  -- table.unpack available (5.2+)
    table_pack = minor >= 2 or compat.luajit,    -- table.pack available (5.2+)
    utf8_library = minor >= 3,                   -- utf8 library available (5.3+)
    math_type = minor >= 3,                      -- math.type available (5.3+)
    integer_division = minor >= 3,               -- // operator (5.3+)
    bitwise_ops = minor >= 3,                    -- &, |, ~, <<, >> operators (5.3+)
    const_close = minor >= 4,                    -- <const> and <close> (5.4+)
    warn_function = minor >= 4,                  -- warn() function (5.4+)
}

--[[
    bit32 compatibility library

    Provides the bit32 library that was removed in Lua 5.4.
    - Lua 5.2: Uses native bit32 library
    - Lua 5.3+: Uses native bitwise operators
    - Lua 5.1: Uses pure-Lua arithmetic fallback

    This allows legacy code that uses bit32.* to continue working.
--]]

-- For Lua 5.2, just use the native bit32 library
if compat.lua52 and bit32 then
    compat.bit32 = bit32
-- For Lua 5.3+, implement using bitwise operators (loaded dynamically)
-- Note: load() may be sandboxed, so we fall back to pure-Lua if unavailable
elseif minor >= 3 and type(load) == "function" then
    -- Use load() to avoid parse errors in older Lua versions
    local bit32_impl = load([[
        local bit32 = {}

        -- Helper: Normalize to 32-bit unsigned integer
        local function normalize(x)
            return x % 0x100000000
        end

        -- band(...)
        function bit32.band(...)
            local args = {...}
            if #args == 0 then return 0xFFFFFFFF end
            local result = normalize(args[1])
            for i = 2, #args do
                result = result & normalize(args[i])
            end
            return normalize(result)
        end

        -- bor(...)
        function bit32.bor(...)
            local args = {...}
            if #args == 0 then return 0 end
            local result = normalize(args[1])
            for i = 2, #args do
                result = result | normalize(args[i])
            end
            return normalize(result)
        end

        -- bxor(...)
        function bit32.bxor(...)
            local args = {...}
            if #args == 0 then return 0 end
            local result = normalize(args[1])
            for i = 2, #args do
                result = result ~ normalize(args[i])
            end
            return normalize(result)
        end

        -- bnot(x)
        function bit32.bnot(x)
            return normalize(~normalize(x))
        end

        -- lshift(x, disp)
        function bit32.lshift(x, disp)
            if disp < 0 then
                return bit32.rshift(x, -disp)
            end
            if disp >= 32 then return 0 end
            return normalize(normalize(x) << disp)
        end

        -- rshift(x, disp)
        function bit32.rshift(x, disp)
            if disp < 0 then
                return bit32.lshift(x, -disp)
            end
            if disp >= 32 then return 0 end
            return normalize(normalize(x) >> disp)
        end

        -- arshift(x, disp)
        function bit32.arshift(x, disp)
            local val = normalize(x)
            if disp < 0 then
                return bit32.lshift(x, -disp)
            end
            if disp >= 32 then
                if val >= 0x80000000 then
                    return 0xFFFFFFFF
                else
                    return 0
                end
            end
            if val >= 0x80000000 then
                local shifted = val >> disp
                local mask = 0xFFFFFFFF << (32 - disp)
                return normalize(shifted | mask)
            else
                return val >> disp
            end
        end

        -- lrotate(x, disp)
        function bit32.lrotate(x, disp)
            disp = disp % 32
            if disp == 0 then return normalize(x) end
            local val = normalize(x)
            return normalize((val << disp) | (val >> (32 - disp)))
        end

        -- rrotate(x, disp)
        function bit32.rrotate(x, disp)
            disp = disp % 32
            if disp == 0 then return normalize(x) end
            local val = normalize(x)
            return normalize((val >> disp) | (val << (32 - disp)))
        end

        -- btest(...)
        function bit32.btest(...)
            return bit32.band(...) ~= 0
        end

        -- extract(n, field, width)
        function bit32.extract(n, field, width)
            width = width or 1
            assert(field >= 0 and field < 32, "field out of range")
            assert(width > 0 and field + width <= 32, "width out of range")
            local mask = (1 << width) - 1
            return (normalize(n) >> field) & mask
        end

        -- replace(n, v, field, width)
        function bit32.replace(n, v, field, width)
            width = width or 1
            assert(field >= 0 and field < 32, "field out of range")
            assert(width > 0 and field + width <= 32, "width out of range")
            local mask = (1 << width) - 1
            v = v & mask
            local cleared = normalize(n) & ~(mask << field)
            return normalize(cleared | (v << field))
        end

        return bit32
    ]])

    if bit32_impl then
        compat.bit32 = bit32_impl()
    else
        compat.bit32 = {}
    end
else
    -- Lua 5.1: Pure-Lua implementation using arithmetic
    -- bit32 didn't exist in 5.1, but we provide it for forward compatibility
    local bit32 = {}

    local function normalize(x)
        return x % 0x100000000
    end

    -- Helper: get bit at position
    local function getbit(x, n)
        return math.floor(x / 2^n) % 2
    end

    -- Helper: set bit at position
    local function setbit(x, n, b)
        local mask = 2^n
        if b == 1 then
            return x + (1 - getbit(x, n)) * mask
        else
            return x - getbit(x, n) * mask
        end
    end

    function bit32.band(...)
        local args = {...}
        if #args == 0 then return 0xFFFFFFFF end
        local result = normalize(args[1])
        for i = 2, #args do
            local b = normalize(args[i])
            local r = 0
            for j = 0, 31 do
                if getbit(result, j) == 1 and getbit(b, j) == 1 then
                    r = r + 2^j
                end
            end
            result = r
        end
        return result
    end

    function bit32.bor(...)
        local args = {...}
        if #args == 0 then return 0 end
        local result = normalize(args[1])
        for i = 2, #args do
            local b = normalize(args[i])
            local r = 0
            for j = 0, 31 do
                if getbit(result, j) == 1 or getbit(b, j) == 1 then
                    r = r + 2^j
                end
            end
            result = r
        end
        return result
    end

    function bit32.bxor(...)
        local args = {...}
        if #args == 0 then return 0 end
        local result = normalize(args[1])
        for i = 2, #args do
            local b = normalize(args[i])
            local r = 0
            for j = 0, 31 do
                if getbit(result, j) ~= getbit(b, j) then
                    r = r + 2^j
                end
            end
            result = r
        end
        return result
    end

    function bit32.bnot(x)
        local val = normalize(x)
        local r = 0
        for j = 0, 31 do
            if getbit(val, j) == 0 then
                r = r + 2^j
            end
        end
        return r
    end

    function bit32.lshift(x, disp)
        if disp < 0 then return bit32.rshift(x, -disp) end
        if disp >= 32 then return 0 end
        return normalize(normalize(x) * 2^disp)
    end

    function bit32.rshift(x, disp)
        if disp < 0 then return bit32.lshift(x, -disp) end
        if disp >= 32 then return 0 end
        return math.floor(normalize(x) / 2^disp)
    end

    function bit32.arshift(x, disp)
        local val = normalize(x)
        if disp < 0 then return bit32.lshift(x, -disp) end
        if disp >= 32 then
            return val >= 0x80000000 and 0xFFFFFFFF or 0
        end
        local shifted = math.floor(val / 2^disp)
        if val >= 0x80000000 then
            -- Fill with ones from the left
            for j = 31, 32 - disp, -1 do
                shifted = shifted + 2^j
            end
        end
        return normalize(shifted)
    end

    function bit32.lrotate(x, disp)
        disp = disp % 32
        if disp == 0 then return normalize(x) end
        local val = normalize(x)
        local left = bit32.lshift(val, disp)
        local right = bit32.rshift(val, 32 - disp)
        return bit32.bor(left, right)
    end

    function bit32.rrotate(x, disp)
        disp = disp % 32
        if disp == 0 then return normalize(x) end
        local val = normalize(x)
        local right = bit32.rshift(val, disp)
        local left = bit32.lshift(val, 32 - disp)
        return bit32.bor(right, left)
    end

    function bit32.btest(...)
        return bit32.band(...) ~= 0
    end

    function bit32.extract(n, field, width)
        width = width or 1
        assert(field >= 0 and field < 32, "field out of range")
        assert(width > 0 and field + width <= 32, "width out of range")
        local val = bit32.rshift(normalize(n), field)
        local mask = 2^width - 1
        return bit32.band(val, mask)
    end

    function bit32.replace(n, v, field, width)
        width = width or 1
        assert(field >= 0 and field < 32, "field out of range")
        assert(width > 0 and field + width <= 32, "width out of range")
        local mask = 2^width - 1
        v = bit32.band(v, mask)
        local shiftedMask = bit32.lshift(mask, field)
        local cleared = bit32.band(normalize(n), bit32.bnot(shiftedMask))
        return bit32.bor(cleared, bit32.lshift(v, field))
    end

    compat.bit32 = bit32
end

--[[
    Legacy compatibility aliases

    These provide aliases for functions that existed in older Lua versions
    but have different names or locations in later versions.
--]]

-- unpack was global in 5.1, moved to table.unpack in 5.2+
if rawget(_G, "unpack") then
    compat.unpack = rawget(_G, "unpack")
elseif table.unpack then
    compat.unpack = table.unpack
end

-- loadstring was removed in 5.2+ (use load instead)
compat.loadstring = rawget(_G, "loadstring") or load

-- setfenv/getfenv were removed in 5.2+
if rawget(_G, "setfenv") then
    compat.setfenv = rawget(_G, "setfenv")
    compat.getfenv = rawget(_G, "getfenv")
else
    compat.setfenv = function(f, env)
        error("setfenv is not supported in Lua 5.2+", 2)
    end
    compat.getfenv = function(f)
        error("getfenv is not supported in Lua 5.2+", 2)
    end
end

--[[
    Install global polyfills

    Call this function to install compatibility polyfills into the global
    environment. This modifies global state and should be used carefully.
--]]
function compat.install()
    -- Install bit32 globally if not present
    if not rawget(_G, "bit32") then
        rawset(_G, "bit32", compat.bit32)
    end

    -- Install global unpack if not present (5.1 compatibility)
    if not rawget(_G, "unpack") and table.unpack then
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

    if code:match("setfenv") and not compat.lua51 then
        table.insert(warnings, "setfenv is not supported in Lua 5.2+")
    end
    if code:match("getfenv") and not compat.lua51 then
        table.insert(warnings, "getfenv is not supported in Lua 5.2+")
    end
    if code:match("module%s*%(") then
        table.insert(warnings, "module() is deprecated since Lua 5.2")
    end
    if code:match("bit32%.") and minor >= 4 then
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
