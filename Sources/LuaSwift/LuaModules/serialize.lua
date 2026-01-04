--[[
    serialize.lua
    Data Serialization Module for LuaSwift

    Provides serialization of Lua values to string representation
    and deserialization back to Lua values.

    Usage:
        local serialize = require("serialize")

        -- Serialize a table to string
        local str = serialize.encode({name = "test", values = {1, 2, 3}})

        -- Deserialize string back to table
        local data = serialize.decode(str)

        -- Pretty print with indentation
        local pretty = serialize.encode(data, {indent = 2})

    Copyright (c) 2026 Christian C. Berclaz
    Licensed under the MIT License
--]]

local serialize = {}

-- Default options
local DEFAULT_OPTIONS = {
    indent = nil,        -- nil for compact, number for spaces
    sort_keys = false,   -- Sort table keys alphabetically
    max_depth = 100,     -- Maximum nesting depth
}

-- Forward declarations
local encode_value

-- Check if a table is an array (sequential integer keys starting from 1)
local function is_array(t)
    if type(t) ~= "table" then return false end
    local count = 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
            return false
        end
        count = count + 1
    end
    -- Check for holes
    return count == #t
end

-- Escape special characters in strings
-- Note: Uses decimal escapes (\ddd) for Lua 5.1 compatibility
-- (Lua 5.1 doesn't support \xNN hex escapes)
local function escape_string(s)
    local result = {}
    for i = 1, #s do
        local c = s:sub(i, i)
        local b = string.byte(c)
        if c == "\\" then
            result[#result + 1] = "\\\\"
        elseif c == "\"" then
            result[#result + 1] = "\\\""
        elseif c == "\n" then
            result[#result + 1] = "\\n"
        elseif c == "\r" then
            result[#result + 1] = "\\r"
        elseif c == "\t" then
            result[#result + 1] = "\\t"
        elseif b == 0 then
            result[#result + 1] = "\\0"
        elseif b < 32 or b >= 127 then
            -- Non-printable: use decimal escape for Lua 5.1 compatibility
            result[#result + 1] = string.format("\\%03d", b)
        else
            result[#result + 1] = c
        end
    end
    return table.concat(result)
end

-- Unescape string
-- Note: Handles both decimal (\ddd) and hex (\xNN) escapes for compatibility
local function unescape_string(s)
    -- Handle hex escapes (Lua 5.2+)
    local unescaped = s:gsub("\\x(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    -- Handle decimal escapes (all Lua versions)
    unescaped = unescaped:gsub("\\(%d%d%d)", function(dec)
        return string.char(tonumber(dec))
    end)
    unescaped = unescaped:gsub("\\0", "\0")
                         :gsub("\\t", "\t")
                         :gsub("\\r", "\r")
                         :gsub("\\n", "\n")
                         :gsub("\\\"", "\"")
                         :gsub("\\\\", "\\")
    return unescaped
end

-- Encode a key for table output
local function encode_key(k)
    if type(k) == "string" and k:match("^[%a_][%w_]*$") then
        return k
    elseif type(k) == "string" then
        return "[\"" .. escape_string(k) .. "\"]"
    elseif type(k) == "number" then
        if k == math.floor(k) then
            return "[" .. tostring(math.floor(k)) .. "]"
        else
            return "[" .. tostring(k) .. "]"
        end
    elseif type(k) == "boolean" then
        return "[" .. tostring(k) .. "]"
    else
        error("Cannot serialize key of type " .. type(k))
    end
end

-- Encode a single value
encode_value = function(v, options, depth, seen, indent_str)
    local t = type(v)

    if depth > options.max_depth then
        error("Maximum serialization depth exceeded")
    end

    if t == "nil" then
        return "nil"
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "number" then
        if v ~= v then  -- NaN check
            return "0/0"
        elseif v == math.huge then
            return "math.huge"
        elseif v == -math.huge then
            return "-math.huge"
        elseif v == math.floor(v) and math.abs(v) < 2^53 then
            return tostring(math.floor(v))
        else
            return string.format("%.17g", v)
        end
    elseif t == "string" then
        return "\"" .. escape_string(v) .. "\""
    elseif t == "table" then
        -- Check for circular reference
        if seen[v] then
            error("Circular reference detected in table")
        end
        seen[v] = true

        local parts = {}
        local is_arr = is_array(v)
        local newline = options.indent and "\n" or ""
        local separator = options.indent and ",\n" or ", "
        local child_indent = indent_str .. (options.indent and string.rep(" ", options.indent) or "")

        if is_arr then
            -- Array-style output
            for i, val in ipairs(v) do
                local encoded = encode_value(val, options, depth + 1, seen, child_indent)
                if options.indent then
                    parts[#parts + 1] = child_indent .. encoded
                else
                    parts[#parts + 1] = encoded
                end
            end
        else
            -- Dictionary-style output
            local keys = {}
            for k in pairs(v) do
                keys[#keys + 1] = k
            end

            if options.sort_keys then
                table.sort(keys, function(a, b)
                    local ta, tb = type(a), type(b)
                    if ta ~= tb then
                        return ta < tb
                    end
                    if ta == "number" or ta == "string" then
                        return a < b
                    end
                    return tostring(a) < tostring(b)
                end)
            end

            for _, k in ipairs(keys) do
                local key_str = encode_key(k)
                local val_str = encode_value(v[k], options, depth + 1, seen, child_indent)
                if options.indent then
                    parts[#parts + 1] = child_indent .. key_str .. " = " .. val_str
                else
                    parts[#parts + 1] = key_str .. " = " .. val_str
                end
            end
        end

        seen[v] = nil  -- Allow same table in different branches

        if #parts == 0 then
            return "{}"
        elseif options.indent then
            return "{" .. newline .. table.concat(parts, separator) .. newline .. indent_str .. "}"
        else
            return "{" .. table.concat(parts, separator) .. "}"
        end
    elseif t == "function" then
        error("Cannot serialize function")
    elseif t == "userdata" then
        error("Cannot serialize userdata")
    elseif t == "thread" then
        error("Cannot serialize thread")
    else
        error("Cannot serialize value of type " .. t)
    end
end

--[[
    serialize.encode(value, options)

    Encode a Lua value to a string representation.

    Parameters:
        value   - The value to serialize (table, string, number, boolean, or nil)
        options - Optional table with:
            indent    - Number of spaces for indentation (nil for compact)
            sort_keys - Sort table keys alphabetically (default: false)
            max_depth - Maximum nesting depth (default: 100)

    Returns:
        String representation of the value

    Throws:
        Error if value contains unsupported types (function, userdata, thread)
        Error if circular reference is detected
--]]
function serialize.encode(value, options)
    options = options or {}
    local opts = {
        indent = options.indent,
        sort_keys = options.sort_keys or DEFAULT_OPTIONS.sort_keys,
        max_depth = options.max_depth or DEFAULT_OPTIONS.max_depth,
    }
    return encode_value(value, opts, 0, {}, "")
end

-- Safe parser state
local Parser = {}
Parser.__index = Parser

function Parser.new(str)
    local self = setmetatable({}, Parser)
    self.str = str
    self.pos = 1
    self.len = #str
    return self
end

function Parser:peek()
    return self.str:sub(self.pos, self.pos)
end

function Parser:advance()
    self.pos = self.pos + 1
end

function Parser:skip_whitespace()
    while self.pos <= self.len do
        local c = self:peek()
        if c == " " or c == "\t" or c == "\n" or c == "\r" then
            self:advance()
        else
            break
        end
    end
end

function Parser:match(pattern)
    local m = self.str:match("^" .. pattern, self.pos)
    if m then
        self.pos = self.pos + #m
        return m
    end
    return nil
end

function Parser:parse_string()
    local quote = self:peek()
    if quote ~= '"' and quote ~= "'" then
        return nil
    end
    self:advance()

    local result = {}
    while self.pos <= self.len do
        local c = self:peek()
        if c == quote then
            self:advance()
            return table.concat(result)
        elseif c == "\\" then
            self:advance()
            local escaped = self:peek()
            self:advance()
            if escaped == "n" then
                result[#result + 1] = "\n"
            elseif escaped == "t" then
                result[#result + 1] = "\t"
            elseif escaped == "r" then
                result[#result + 1] = "\r"
            elseif escaped == "\\" then
                result[#result + 1] = "\\"
            elseif escaped == '"' then
                result[#result + 1] = '"'
            elseif escaped == "'" then
                result[#result + 1] = "'"
            elseif escaped == "0" then
                result[#result + 1] = "\0"
            elseif escaped == "x" then
                local hex = self.str:sub(self.pos, self.pos + 1)
                self.pos = self.pos + 2
                result[#result + 1] = string.char(tonumber(hex, 16) or 0)
            else
                result[#result + 1] = escaped
            end
        else
            result[#result + 1] = c
            self:advance()
        end
    end
    error("Unterminated string")
end

function Parser:parse_number()
    local num = self:match("[%-]?%d+%.?%d*[eE]?[%-+]?%d*")
    if num then
        return tonumber(num)
    end
    return nil
end

function Parser:parse_value()
    self:skip_whitespace()

    if self.pos > self.len then
        error("Unexpected end of input")
    end

    local c = self:peek()

    -- nil
    if self:match("nil") then
        return nil
    end

    -- boolean
    if self:match("true") then
        return true
    end
    if self:match("false") then
        return false
    end

    -- math.huge
    if self:match("math%.huge") then
        return math.huge
    end
    if self:match("%-math%.huge") then
        return -math.huge
    end

    -- 0/0 for NaN
    if self:match("0/0") then
        return 0/0
    end

    -- string
    if c == '"' or c == "'" then
        return self:parse_string()
    end

    -- number (including negative)
    if c:match("[%d%-]") then
        local num = self:parse_number()
        if num then
            return num
        end
    end

    -- table
    if c == "{" then
        return self:parse_table()
    end

    error("Unexpected character: " .. c .. " at position " .. self.pos)
end

function Parser:parse_table()
    if self:peek() ~= "{" then
        error("Expected '{'")
    end
    self:advance()
    self:skip_whitespace()

    local result = {}
    local array_index = 1
    local is_first = true

    while self.pos <= self.len do
        self:skip_whitespace()

        if self:peek() == "}" then
            self:advance()
            return result
        end

        if not is_first then
            if self:peek() == "," then
                self:advance()
                self:skip_whitespace()
            end
        end
        is_first = false

        if self:peek() == "}" then
            self:advance()
            return result
        end

        -- Check for key = value or [key] = value
        local key = nil
        local saved_pos = self.pos

        -- Try [key] = value
        if self:peek() == "[" then
            self:advance()
            self:skip_whitespace()
            key = self:parse_value()
            self:skip_whitespace()
            if self:peek() ~= "]" then
                error("Expected ']'")
            end
            self:advance()
            self:skip_whitespace()
            if self:peek() ~= "=" then
                error("Expected '='")
            end
            self:advance()
            self:skip_whitespace()
            local value = self:parse_value()
            result[key] = value
        else
            -- Try identifier = value
            local ident = self:match("[%a_][%w_]*")
            if ident then
                self:skip_whitespace()
                if self:peek() == "=" then
                    self:advance()
                    self:skip_whitespace()
                    local value = self:parse_value()
                    result[ident] = value
                else
                    -- Not key=value, backtrack and treat as array value
                    self.pos = saved_pos
                    local value = self:parse_value()
                    result[array_index] = value
                    array_index = array_index + 1
                end
            else
                -- Array value
                local value = self:parse_value()
                result[array_index] = value
                array_index = array_index + 1
            end
        end
    end

    error("Unterminated table")
end

--[[
    serialize.decode(str)

    Decode a serialized string back to a Lua value.

    Parameters:
        str - String produced by serialize.encode()

    Returns:
        The deserialized Lua value

    Throws:
        Error if string is malformed or contains invalid syntax
--]]
function serialize.decode(str)
    if type(str) ~= "string" then
        error("Expected string, got " .. type(str))
    end

    local parser = Parser.new(str)
    local result = parser:parse_value()
    parser:skip_whitespace()

    if parser.pos <= parser.len then
        error("Unexpected content after value at position " .. parser.pos)
    end

    return result
end

--[[
    serialize.pretty(value, indent)

    Convenience function for pretty-printed serialization.

    Parameters:
        value  - The value to serialize
        indent - Number of spaces for indentation (default: 2)

    Returns:
        Pretty-printed string representation
--]]
function serialize.pretty(value, indent)
    return serialize.encode(value, {
        indent = indent or 2,
        sort_keys = true,
    })
end

--[[
    serialize.compact(value)

    Convenience function for compact serialization (no whitespace).

    Parameters:
        value - The value to serialize

    Returns:
        Compact string representation
--]]
function serialize.compact(value)
    return serialize.encode(value, {
        indent = nil,
        sort_keys = false,
    })
end

--[[
    serialize.safe_decode(str)

    Safely decode a string, returning nil and error message on failure.

    Parameters:
        str - String to decode

    Returns:
        value, nil on success
        nil, error_message on failure
--]]
function serialize.safe_decode(str)
    local success, result = pcall(serialize.decode, str)
    if success then
        return result, nil
    else
        return nil, result
    end
end

--[[
    serialize.is_serializable(value)

    Check if a value can be serialized.

    Parameters:
        value - The value to check

    Returns:
        true if value can be serialized, false otherwise
--]]
function serialize.is_serializable(value)
    local t = type(value)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then
        return true
    elseif t == "table" then
        local seen = {}
        local function check(v)
            local vt = type(v)
            if vt == "nil" or vt == "boolean" or vt == "number" or vt == "string" then
                return true
            elseif vt == "table" then
                if seen[v] then
                    return false  -- Circular reference
                end
                seen[v] = true
                for k, val in pairs(v) do
                    local kt = type(k)
                    if kt ~= "string" and kt ~= "number" and kt ~= "boolean" then
                        return false
                    end
                    if not check(val) then
                        return false
                    end
                end
                seen[v] = nil
                return true
            else
                return false
            end
        end
        return check(value)
    else
        return false
    end
end

return serialize
