-- tablex.lua - Extended Table Utilities for Lua 5.4.7
-- Copyright (c) 2025 LuaSwift Project
-- Licensed under the MIT License
--
-- A pure Lua module providing extended table operations including:
-- - Deep copy and shallow copy
-- - Table merging (shallow and deep)
-- - Functional operations (map, filter, reduce, foreach)
-- - Query functions (find, contains, keys, values, size)
-- - Transformation (invert, flatten, slice, reverse)
-- - Set operations (union, intersection, difference)
-- - Equality comparison (shallow and deep)

local tablex = {}

--------------------------------------------------------------------------------
-- Copying
--------------------------------------------------------------------------------

-- Shallow copy of a table
-- @param t: table to copy
-- @return: new table with same key-value pairs (references preserved)
function tablex.copy(t)
    if type(t) ~= "table" then
        return t
    end
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

-- Deep copy of a table, preserving metatables
-- @param t: table to copy
-- @param seen: internal table to track circular references
-- @return: new table with recursively copied values
function tablex.deepcopy(t, seen)
    if type(t) ~= "table" then
        return t
    end

    seen = seen or {}
    if seen[t] then
        return seen[t]
    end

    local result = {}
    seen[t] = result

    for k, v in pairs(t) do
        local key = tablex.deepcopy(k, seen)
        result[key] = tablex.deepcopy(v, seen)
    end

    local mt = getmetatable(t)
    if mt then
        setmetatable(result, tablex.deepcopy(mt, seen))
    end

    return result
end

--------------------------------------------------------------------------------
-- Merging
--------------------------------------------------------------------------------

-- Shallow merge of two tables (t2 values overwrite t1)
-- @param t1: base table
-- @param t2: table to merge into t1
-- @return: new table with merged values
function tablex.merge(t1, t2)
    local result = tablex.copy(t1)
    if type(t2) == "table" then
        for k, v in pairs(t2) do
            result[k] = v
        end
    end
    return result
end

-- Deep merge of two tables (t2 values overwrite t1, nested tables merged)
-- @param t1: base table
-- @param t2: table to merge into t1
-- @param seen: internal table to track circular references
-- @return: new table with deeply merged values
function tablex.deepmerge(t1, t2, seen)
    seen = seen or {}

    if type(t1) ~= "table" then
        return tablex.deepcopy(t2)
    end
    if type(t2) ~= "table" then
        return tablex.deepcopy(t1)
    end

    -- Handle circular references
    local key = tostring(t1) .. tostring(t2)
    if seen[key] then
        return seen[key]
    end

    local result = {}
    seen[key] = result

    -- Copy all from t1
    for k, v in pairs(t1) do
        result[k] = tablex.deepcopy(v)
    end

    -- Merge from t2
    for k, v in pairs(t2) do
        if type(result[k]) == "table" and type(v) == "table" then
            result[k] = tablex.deepmerge(result[k], v, seen)
        else
            result[k] = tablex.deepcopy(v)
        end
    end

    return result
end

--------------------------------------------------------------------------------
-- Functional Operations
--------------------------------------------------------------------------------

-- Apply a function to each value in a table
-- @param t: table to map over
-- @param fn: function(value, key) -> transformed value
-- @return: new table with transformed values
function tablex.map(t, fn)
    if type(t) ~= "table" then
        return {}
    end
    local result = {}
    for k, v in pairs(t) do
        result[k] = fn(v, k)
    end
    return result
end

-- Filter table values by predicate
-- @param t: table to filter
-- @param pred: function(value, key) -> boolean
-- @return: new table with values where pred returns true
function tablex.filter(t, pred)
    if type(t) ~= "table" then
        return {}
    end
    local result = {}
    local is_array = tablex.isarray(t)

    for k, v in pairs(t) do
        if pred(v, k) then
            if is_array then
                table.insert(result, v)
            else
                result[k] = v
            end
        end
    end
    return result
end

-- Reduce table to a single value
-- @param t: table to reduce
-- @param fn: function(accumulator, value, key) -> new accumulator
-- @param init: initial accumulator value
-- @return: final accumulated value
function tablex.reduce(t, fn, init)
    if type(t) ~= "table" then
        return init
    end
    local acc = init
    for k, v in pairs(t) do
        acc = fn(acc, v, k)
    end
    return acc
end

-- Iterate over table with a function
-- @param t: table to iterate
-- @param fn: function(value, key) called for each element
function tablex.foreach(t, fn)
    if type(t) ~= "table" then
        return
    end
    for k, v in pairs(t) do
        fn(v, k)
    end
end

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------

-- Find key for a given value
-- @param t: table to search
-- @param val: value to find
-- @return: key if found, nil otherwise
function tablex.find(t, val)
    if type(t) ~= "table" then
        return nil
    end
    for k, v in pairs(t) do
        if v == val then
            return k
        end
    end
    return nil
end

-- Check if table contains a value
-- @param t: table to search
-- @param val: value to find
-- @return: true if found, false otherwise
function tablex.contains(t, val)
    return tablex.find(t, val) ~= nil
end

-- Get array of all keys in table
-- @param t: table to get keys from
-- @return: array of keys
function tablex.keys(t)
    if type(t) ~= "table" then
        return {}
    end
    local result = {}
    for k, _ in pairs(t) do
        table.insert(result, k)
    end
    return result
end

-- Get array of all values in table
-- @param t: table to get values from
-- @return: array of values
function tablex.values(t)
    if type(t) ~= "table" then
        return {}
    end
    local result = {}
    for _, v in pairs(t) do
        table.insert(result, v)
    end
    return result
end

-- Count key-value pairs in table
-- @param t: table to count
-- @return: number of key-value pairs
function tablex.size(t)
    if type(t) ~= "table" then
        return 0
    end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Check if table is empty
-- @param t: table to check
-- @return: true if empty or not a table, false otherwise
function tablex.isempty(t)
    if type(t) ~= "table" then
        return true
    end
    return next(t) == nil
end

-- Check if table is array-like (consecutive integer keys starting at 1)
-- @param t: table to check
-- @return: true if array-like, false otherwise
function tablex.isarray(t)
    if type(t) ~= "table" then
        return false
    end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    -- Check if all keys are consecutive integers from 1 to count
    for i = 1, count do
        if t[i] == nil then
            return false
        end
    end
    return true
end

--------------------------------------------------------------------------------
-- Transformation
--------------------------------------------------------------------------------

-- Swap keys and values
-- @param t: table to invert
-- @return: new table with keys and values swapped
function tablex.invert(t)
    if type(t) ~= "table" then
        return {}
    end
    local result = {}
    for k, v in pairs(t) do
        result[v] = k
    end
    return result
end

-- Flatten nested tables into single-level array
-- @param t: table to flatten
-- @param depth: maximum depth to flatten (nil = infinite)
-- @return: flattened array
function tablex.flatten(t, depth)
    if type(t) ~= "table" then
        return {t}
    end

    depth = depth or math.huge
    local result = {}

    local function flatten_recursive(tbl, current_depth)
        for _, v in ipairs(tbl) do
            if type(v) == "table" and current_depth < depth then
                flatten_recursive(v, current_depth + 1)
            else
                table.insert(result, v)
            end
        end
    end

    flatten_recursive(t, 0)
    return result
end

-- Get sub-array from index i to j
-- @param t: array to slice
-- @param i: start index (default 1)
-- @param j: end index (default #t)
-- @return: new array containing slice
function tablex.slice(t, i, j)
    if type(t) ~= "table" then
        return {}
    end
    local len = #t
    i = i or 1
    j = j or len

    -- Handle negative indices
    if i < 0 then i = len + i + 1 end
    if j < 0 then j = len + j + 1 end

    -- Clamp to valid range
    if i < 1 then i = 1 end
    if j > len then j = len end

    local result = {}
    for idx = i, j do
        table.insert(result, t[idx])
    end
    return result
end

-- Reverse an array
-- @param t: array to reverse
-- @return: new array with elements in reverse order
function tablex.reverse(t)
    if type(t) ~= "table" then
        return {}
    end
    local result = {}
    local len = #t
    for i = len, 1, -1 do
        table.insert(result, t[i])
    end
    return result
end

--------------------------------------------------------------------------------
-- Set Operations (for array-like tables)
--------------------------------------------------------------------------------

-- Union of two arrays (all unique values from both)
-- @param t1: first array
-- @param t2: second array
-- @return: array containing unique values from both
function tablex.union(t1, t2)
    local seen = {}
    local result = {}

    if type(t1) == "table" then
        for _, v in ipairs(t1) do
            if not seen[v] then
                seen[v] = true
                table.insert(result, v)
            end
        end
    end

    if type(t2) == "table" then
        for _, v in ipairs(t2) do
            if not seen[v] then
                seen[v] = true
                table.insert(result, v)
            end
        end
    end

    return result
end

-- Intersection of two arrays (values present in both)
-- @param t1: first array
-- @param t2: second array
-- @return: array containing values present in both
function tablex.intersection(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return {}
    end

    local set2 = {}
    for _, v in ipairs(t2) do
        set2[v] = true
    end

    local result = {}
    local seen = {}
    for _, v in ipairs(t1) do
        if set2[v] and not seen[v] then
            seen[v] = true
            table.insert(result, v)
        end
    end

    return result
end

-- Difference of two arrays (values in t1 but not in t2)
-- @param t1: first array
-- @param t2: second array
-- @return: array containing values in t1 but not in t2
function tablex.difference(t1, t2)
    if type(t1) ~= "table" then
        return {}
    end

    local set2 = {}
    if type(t2) == "table" then
        for _, v in ipairs(t2) do
            set2[v] = true
        end
    end

    local result = {}
    local seen = {}
    for _, v in ipairs(t1) do
        if not set2[v] and not seen[v] then
            seen[v] = true
            table.insert(result, v)
        end
    end

    return result
end

--------------------------------------------------------------------------------
-- Comparison
--------------------------------------------------------------------------------

-- Shallow equality comparison
-- @param t1: first table
-- @param t2: second table
-- @return: true if tables have same key-value pairs (by reference), false otherwise
function tablex.equals(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
    end

    -- Check all keys in t1 exist in t2 with same value
    for k, v in pairs(t1) do
        if t2[k] ~= v then
            return false
        end
    end

    -- Check no extra keys in t2
    for k, _ in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end

    return true
end

-- Deep equality comparison
-- @param t1: first table
-- @param t2: second table
-- @param seen: internal table to track circular references
-- @return: true if tables are deeply equal, false otherwise
function tablex.deepequals(t1, t2, seen)
    if type(t1) ~= type(t2) then
        return false
    end

    if type(t1) ~= "table" then
        return t1 == t2
    end

    seen = seen or {}
    local key = tostring(t1) .. tostring(t2)
    if seen[key] then
        return true  -- Assume equal for circular references
    end
    seen[key] = true

    -- Check all keys in t1 exist in t2 with deeply equal value
    for k, v in pairs(t1) do
        if not tablex.deepequals(v, t2[k], seen) then
            return false
        end
    end

    -- Check no extra keys in t2
    for k, _ in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end

    return true
end

return tablex
