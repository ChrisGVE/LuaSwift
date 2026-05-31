# TableX Module

Functional table operations and utilities beyond Lua's standard table library.

## Overview

The TableX module provides comprehensive table manipulation functions including deep copying with cycle detection, recursive merging, functional programming utilities (map, filter, reduce), array operations, and set operations. It extends Lua's built-in `table` library with powerful data manipulation tools.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the TableX module
ModuleRegistry.installTableXModule(in: engine)
```

## Basic Usage

```lua
local tablex = require("luaswift.tablex")

-- Or use the global alias
local t = {a = 1, b = {c = 2}}
local copy = tablex.deepcopy(t)

-- Functional operations
local doubled = tablex.map({1, 2, 3}, function(v) return v * 2 end)
-- {2, 4, 6}

-- Extend standard table library
tablex.import()
local keys = table.keys({a = 1, b = 2})  -- Now available on table
```

## Extending the Standard Table Library

Call `tablex.import()` to add all TableX functions to Lua's standard `table` table:

```lua
tablex.import()

-- Now use directly on table
local copy = table.deepcopy({a = 1, b = {c = 2}})
local keys = table.keys({x = 1, y = 2})
local doubled = table.map({1, 2, 3}, function(v) return v * 2 end)
```

> Note: `tablex.import()` deliberately does **not** override `table.sort`. Lua's built-in `table.sort` sorts in-place and is already available in every sandbox. The tablex-flavoured `sort` (which returns a new sorted copy) is only available as `tablex.sort`.

## API Reference

### Deep Operations

#### deepcopy(t)
Creates a deep copy of a table, handling nested tables and cycles. Preserves metatables and LuaSwift typed objects.

```lua
local original = {
    a = 1,
    b = {c = 2, d = {e = 3}}
}

local copy = tablex.deepcopy(original)
copy.b.c = 99
print(original.b.c)  -- 2 (unchanged)

-- Handles cycles safely
local t = {a = 1}
t.self = t
local copy = tablex.deepcopy(t)  -- Works correctly
```

#### deepmerge(t1, t2)
Recursively merges two tables. Values from `t2` override `t1`, with nested tables merged recursively.

```lua
local t1 = {a = 1, b = {x = 1, y = 2}}
local t2 = {b = {y = 99, z = 3}, c = 4}

local merged = tablex.deepmerge(t1, t2)
-- {a = 1, b = {x = 1, y = 99, z = 3}, c = 4}

-- Non-table values are overwritten
local t1 = {a = {x = 1}}
local t2 = {a = "replaced"}
local merged = tablex.deepmerge(t1, t2)
-- {a = "replaced"}
```

### Copying

#### copy(t)
Creates a shallow copy (one level only).

```lua
local t = {a = 1, b = {c = 2}}
local shallow = tablex.copy(t)
shallow.a = 99
shallow.b.c = 99

print(t.a)    -- 1 (unchanged)
print(t.b.c)  -- 99 (nested object is shared!)
```

### Array Manipulation

#### flatten(t, depth?)
Flattens nested arrays. Optional `depth` limits flattening levels (default: fully flatten).

```lua
local nested = {1, {2, 3}, {4, {5, 6}}}
local flat = tablex.flatten(nested)
-- {1, 2, 3, 4, 5, 6}

-- Partial flatten
local partial = tablex.flatten({1, {2, {3, 4}}}, 1)
-- {1, 2, {3, 4}}

-- Multiple nesting levels
local deep = tablex.flatten({{{{1}}}}, 2)
-- {{1}}
```

#### slice(t, i, j?, step?)
Extracts a portion of an array. `i` and `j` are 1-based, inclusive, and support negative indices (counting from the end). `step` defaults to `1`; a negative step walks backwards. When `step` is negative, the default for `i` is the last element and the default for `j` is the first element. Raises an error if `step` is `0`.

```lua
local t = {1, 2, 3, 4, 5}

tablex.slice(t, 2, 4)        -- {2, 3, 4}
tablex.slice(t, 3)           -- {3, 4, 5} (to end)
tablex.slice(t, -3)          -- {3, 4, 5} (last 3 elements)
tablex.slice(t, 1, -2)       -- {1, 2, 3, 4} (up to 2nd from end)

-- step parameter
tablex.slice(t, 1, 5, 2)     -- {1, 3, 5} (every other element)
tablex.slice(t, nil, nil, -1) -- {5, 4, 3, 2, 1} (reverse)
tablex.slice(t, 5, 1, -2)    -- {5, 3, 1} (backwards, every other)
```

#### reverse(t)
Returns a new array with elements in reverse order.

```lua
local t = {1, 2, 3, 4, 5}
local rev = tablex.reverse(t)
-- {5, 4, 3, 2, 1}
```

#### unique(t)
Returns a new array with duplicate values removed.

```lua
local t = {1, 2, 2, 3, 3, 3}
local u = tablex.unique(t)
-- {1, 2, 3}

local words = {"a", "b", "a", "c", "b"}
local u = tablex.unique(words)
-- {"a", "b", "c"}
```

#### sort(t, comp?)
Returns a new sorted array. Optional comparator function for custom ordering.

```lua
local t = {3, 1, 4, 1, 5, 9}
local sorted = tablex.sort(t)
-- {1, 1, 3, 4, 5, 9}

-- Custom comparator (descending)
local sorted = tablex.sort(t, function(a, b) return a > b end)
-- {9, 5, 4, 3, 1, 1}

-- Sort by property
local items = {{name = "c"}, {name = "a"}, {name = "b"}}
local sorted = tablex.sort(items, function(a, b)
    return a.name < b.name
end)
```

### Key/Value Extraction

#### keys(t)
Returns an array of all keys in a table, sorted alphabetically.

```lua
local t = {c = 3, a = 1, b = 2}
local k = tablex.keys(t)
-- {"a", "b", "c"}
```

#### values(t)
Returns an array of all values in a table, ordered by sorted keys.

```lua
local t = {c = 3, a = 1, b = 2}
local v = tablex.values(t)
-- {1, 2, 3} (ordered by key: a, b, c)
```

#### invert(t)
Swaps keys and values. Original values become keys, original keys become values.

```lua
local t = {a = "x", b = "y", c = "z"}
local inv = tablex.invert(t)
-- {x = "a", y = "b", z = "c"}

-- Numeric values work too
local t = {first = 1, second = 2}
local inv = tablex.invert(t)
-- {["1"] = "first", ["2"] = "second"}
```

### Functional Operations

#### map(t, f)
Transforms each value using function `f(value, key)`. Returns a new table.

```lua
local nums = {1, 2, 3, 4}
local doubled = tablex.map(nums, function(v) return v * 2 end)
-- {2, 4, 6, 8}

-- With key access
local t = {a = 1, b = 2}
local labeled = tablex.map(t, function(v, k)
    return k .. "=" .. v
end)
-- {a = "a=1", b = "b=2"}
```

#### filter(t, f)
Filters elements where `f(value, key)` returns true. Returns a new table.

```lua
local nums = {1, 2, 3, 4, 5, 6}
local evens = tablex.filter(nums, function(v)
    return v % 2 == 0
end)
-- {2, 4, 6}

-- Filter by key
local t = {name = "Alice", age = 30, city = "NYC"}
local strings = tablex.filter(t, function(v)
    return type(v) == "string"
end)
-- {name = "Alice", city = "NYC"}
```

#### reduce(t, f, init)
Reduces table to a single value using `f(accumulator, value, key)`.

```lua
local nums = {1, 2, 3, 4, 5}
local sum = tablex.reduce(nums, function(acc, v)
    return acc + v
end, 0)
-- 15

local product = tablex.reduce(nums, function(acc, v)
    return acc * v
end, 1)
-- 120

-- Find maximum
local max = tablex.reduce(nums, function(acc, v)
    return v > acc and v or acc
end, nums[1])
```

#### foreach(t, f)
Iterates over table calling `f(value, key)` for side effects. Returns nil.

```lua
local t = {a = 1, b = 2, c = 3}
tablex.foreach(t, function(v, k)
    print(k, v)
end)
-- Prints:
-- a  1
-- b  2
-- c  3
```

### Searching

#### find(t, value)
Finds the first key associated with a value. Returns key or nil.

```lua
local t = {a = "x", b = "y", c = "z"}
local key = tablex.find(t, "y")
-- "b"

local key = tablex.find(t, "not found")
-- nil
```

#### contains(t, value)
Checks if table contains a value. Returns boolean.

```lua
local nums = {1, 2, 3, 4, 5}
tablex.contains(nums, 3)       -- true
tablex.contains(nums, 99)      -- false

local t = {a = "x", b = "y"}
tablex.contains(t, "x")        -- true
tablex.contains(t, "a")        -- false (checks values, not keys)
```

### Table Properties

#### size(t)
Counts all elements in a table (not just the array part).

```lua
local t = {1, 2, 3, a = "x", b = "y"}
tablex.size(t)    -- 5

-- Compare with # operator
print(#t)         -- 3 (only array part)
```

#### isempty(t)
Checks if table has no elements.

```lua
tablex.isempty({})              -- true
tablex.isempty({1})             -- false
tablex.isempty({a = 1})         -- false
```

#### isarray(t)
Checks if table is array-like (sequential integer keys from 1).

```lua
tablex.isarray({1, 2, 3})       -- true
tablex.isarray({a = 1, b = 2})  -- false
tablex.isarray({1, 2, a = 3})   -- false (has non-integer key)
tablex.isarray({[1] = "a", [3] = "c"})  -- false (gap at 2)
```

### Set Operations

#### union(t1, t2)
Returns elements that are in either array (set union). Preserves order, removes duplicates.

```lua
local a = {1, 2, 3}
local b = {2, 3, 4, 5}
local u = tablex.union(a, b)
-- {1, 2, 3, 4, 5}
```

#### intersection(t1, t2)
Returns elements that are in both arrays (set intersection).

```lua
local a = {1, 2, 3, 4}
local b = {2, 4, 6, 8}
local i = tablex.intersection(a, b)
-- {2, 4}
```

#### difference(t1, t2)
Returns elements in t1 that are not in t2 (set difference).

```lua
local a = {1, 2, 3, 4, 5}
local b = {2, 4}
local d = tablex.difference(a, b)
-- {1, 3, 5}
```

### Equality

#### equals(t1, t2)
Shallow equality check. Compares all keys and values at top level.

```lua
local a = {x = 1, y = 2}
local b = {x = 1, y = 2}
local c = {x = 1, y = 3}

tablex.equals(a, b)    -- true
tablex.equals(a, c)    -- false

-- Note: nested tables are compared by reference
local a = {data = {1, 2}}
local b = {data = {1, 2}}
tablex.equals(a, b)    -- false (different table references)
```

#### deepequals(t1, t2)
Deep equality check. Recursively compares nested tables.

```lua
local a = {x = 1, data = {a = 1, b = 2}}
local b = {x = 1, data = {a = 1, b = 2}}
local c = {x = 1, data = {a = 1, b = 99}}

tablex.deepequals(a, b)    -- true
tablex.deepequals(a, c)    -- false
```

### Comprehensions

These functions mirror Python list/dict/set comprehensions as explicit function calls.

#### collect(t, transform, filter?)
Iterates the array part of `t` (using `ipairs`), optionally keeps only elements where `filter(value, index)` is truthy, then transforms each passing element with `transform(value, index)`. Returns a new array. The filter receives the **original** value, before transformation.

```lua
local nums = {1, 2, 3, 4, 5, 6}

-- Square the even numbers
local result = tablex.collect(
    nums,
    function(v) return v * v end,       -- transform
    function(v) return v % 2 == 0 end   -- filter
)
-- {4, 16, 36}

-- No filter: transform every element
local doubled = tablex.collect(nums, function(v) return v * 2 end)
-- {2, 4, 6, 8, 10, 12}
```

#### dict_from(t, key_fn, value_fn, filter?)
Builds a `{key = value}` table from the array part of `t`. `key_fn(value, index)` produces the key, `value_fn(value, index)` produces the value. Optional `filter(value, index)` is applied to the original item before key/value functions run.

```lua
local words = {"apple", "banana", "cherry"}

-- Build a word-length lookup
local lengths = tablex.dict_from(
    words,
    function(w) return w end,          -- key_fn: word itself
    function(w) return #w end          -- value_fn: its length
)
-- {apple = 5, banana = 6, cherry = 6}

-- Only words longer than 5 characters
local long_lengths = tablex.dict_from(
    words,
    function(w) return w end,
    function(w) return #w end,
    function(w) return #w > 5 end      -- filter
)
-- {banana = 6, cherry = 6}
```

#### set_from(t, transform, filter?)
Returns a `{value = true}` table of unique transformed values. Useful for fast membership testing. `filter(value, index)` is applied before `transform(value, index)`.

```lua
local items = {"apple", "banana", "APPLE", "cherry"}

-- Unique lowercase names
local name_set = tablex.set_from(
    items,
    function(v) return v:lower() end
)
-- {apple = true, banana = true, cherry = true}

-- Membership test
print(name_set["apple"])   -- true
print(name_set["grape"])   -- nil
```

### Fluent Chaining

#### chain(t)
Wraps the array part of `t` in a chainable object. Operations are applied eagerly in sequence. The chain is terminated by a collector method that returns a plain table.

Chain methods:

| Method | Description |
|---|---|
| `:map(fn)` | Transform each element with `fn(value, index)`; returns chain |
| `:filter(fn)` | Keep elements where `fn(value, index)` is truthy; returns chain |
| `:collect()` | Terminate: return new array |
| `:dict(key_fn, val_fn)` | Terminate: return `{key=value}` table |
| `:set()` | Terminate: return `{value=true}` table |

```lua
local nums = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

-- Filter evens, double them, collect as array
local result = tablex.chain(nums)
    :filter(function(v) return v % 2 == 0 end)
    :map(function(v) return v * 2 end)
    :collect()
-- {4, 8, 12, 16, 20}

-- Build a lookup from even numbers to their squares
local lookup = tablex.chain(nums)
    :filter(function(v) return v % 2 == 0 end)
    :dict(
        function(v) return v end,        -- key
        function(v) return v * v end     -- value
    )
-- {[2]=4, [4]=16, [6]=36, [8]=64, [10]=100}

-- Unique set of first characters
local words = {"apple", "banana", "avocado", "cherry"}
local initials = tablex.chain(words)
    :map(function(w) return w:sub(1, 1) end)
    :set()
-- {a = true, b = true, c = true}
```

## Common Patterns

### Data Transformation Pipeline

```lua
local data = {
    {name = "Alice", age = 30, active = true},
    {name = "Bob", age = 25, active = false},
    {name = "Carol", age = 35, active = true}
}

-- Filter active users, extract names, sort
local active_names = tablex.sort(
    tablex.map(
        tablex.filter(data, function(user)
            return user.active
        end),
        function(user)
            return user.name
        end
    )
)
-- {"Alice", "Carol"}
```

### Configuration Merging

```lua
local defaults = {
    host = "localhost",
    port = 8080,
    options = {
        timeout = 30,
        retries = 3
    }
}

local user_config = {
    port = 9000,
    options = {
        timeout = 60
    }
}

local config = tablex.deepmerge(defaults, user_config)
-- {
--   host = "localhost",
--   port = 9000,
--   options = {timeout = 60, retries = 3}
-- }
```

### Set Operations on Objects

```lua
local admins = {"alice", "bob", "carol"}
local editors = {"bob", "carol", "dave"}

local all_users = tablex.union(admins, editors)
-- {"alice", "bob", "carol", "dave"}

local both_roles = tablex.intersection(admins, editors)
-- {"bob", "carol"}

local admin_only = tablex.difference(admins, editors)
-- {"alice"}
```

### Grouping Data

```lua
local items = {
    {type = "fruit", name = "apple"},
    {type = "vegetable", name = "carrot"},
    {type = "fruit", name = "banana"},
    {type = "vegetable", name = "broccoli"}
}

local grouped = tablex.reduce(items, function(acc, item)
    local key = item.type
    if not acc[key] then
        acc[key] = {}
    end
    acc[key][#acc[key] + 1] = item.name
    return acc
end, {})
-- {fruit = {"apple", "banana"}, vegetable = {"carrot", "broccoli"}}
```

### Safe Table Access

```lua
local function get_nested(t, ...)
    local current = t
    for _, key in ipairs({...}) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[key]
    end
    return current
end

local data = {user = {profile = {name = "Alice"}}}
print(get_nested(data, "user", "profile", "name"))  -- "Alice"
print(get_nested(data, "user", "missing", "name"))  -- nil
```

## LuaSwift Type Preservation

TableX operations preserve LuaSwift typed objects (vec2, complex, etc.):

```lua
local vec = geo.vec2(3, 4)
local data = {position = vec, name = "point"}

-- Deep copy uses types.clone for typed objects
local copy = tablex.deepcopy(data)
print(copy.position:length())  -- 5 (properly cloned vec2)

-- Deep merge handles typed objects correctly
local update = {position = geo.vec2(1, 0)}
local merged = tablex.deepmerge(data, update)
print(merged.position.x)  -- 1
```

## See Also

- ``TableXModule``
- ``StringXModule``
- ``TypesModule``
