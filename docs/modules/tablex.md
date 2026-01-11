# TableX Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.tablex` | **Extends:** `table`

Efficient table manipulation utilities with deep copying, merging, and functional operations. Inspired by Lua's Penlight library, implemented in Swift for performance.

## Function Reference

| Function | Description |
|----------|-------------|
| [import()](#import) | Extend `table.*` library with all functions |
| [deepcopy(table, seen?)](#deepcopy) | Deep copy with cycle detection |
| [deepmerge(t1, t2)](#deepmerge) | Recursive merge |
| [flatten(array, depth?)](#flatten) | Flatten nested arrays |
| [keys(table)](#keys) | Extract keys (sorted) |
| [values(table)](#values) | Extract values |
| [invert(table)](#invert) | Reverse key-value mapping |
| [copy(table)](#copy) | Shallow copy |
| [map(table, func)](#map) | Apply function to values |
| [filter(table, predicate)](#filter) | Filter by predicate |
| [reduce(table, func, initial)](#reduce) | Fold/reduce to single value |
| [foreach(table, func)](#foreach) | Iterate with side effects |
| [find(table, value)](#find) | Find key for value |
| [contains(table, value)](#contains) | Check if value exists |
| [size(table)](#size) | Count all elements |
| [isempty(table)](#isempty) | Check if empty |
| [isarray(table)](#isarray) | Check if array-like |
| [slice(array, start, end?)](#slice) | Extract subarray |
| [reverse(array)](#reverse) | Reverse array |
| [unique(array)](#unique) | Remove duplicates |
| [sort(array, comparator?)](#sort) | Sort array |
| [union(array1, array2)](#union) | Set union |
| [intersection(array1, array2)](#intersection) | Set intersection |
| [difference(array1, array2)](#difference) | Set difference |
| [equals(t1, t2)](#equals) | Shallow equality |
| [deepequals(t1, t2)](#deepequals) | Deep equality |

---

## import

```
tablex.import() -> void
```

Extends the standard `table.*` library with all tablex functions.

```lua
local tablex = require("luaswift.tablex")
tablex.import()

-- Now use via table.* namespace
local copy = table.deepcopy({a = 1, b = {c = 2}})
local keys = table.keys({x = 10, y = 20})
```

---

## deepcopy

```
tablex.deepcopy(table, seen?) -> table
```

Creates a deep copy of a table with automatic cycle detection. Preserves LuaSwift typed objects using `types.clone()`.

**Parameters:**
- `table` - Table to copy
- `seen` (optional) - Internal parameter for cycle detection (do not provide)

```lua
local t1 = {a = 1, b = {c = 2, d = {e = 3}}}
t1.self = t1  -- Circular reference

local t2 = tablex.deepcopy(t1)
t2.a = 999
print(t1.a)  -- Still 1
```

---

## deepmerge

```
tablex.deepmerge(t1, t2) -> table
```

Recursively merges two tables. Values in `t2` override those in `t1`. Nested tables are merged recursively. Typed objects are replaced, not merged.

**Parameters:**
- `t1` - Base table
- `t2` - Override table

```lua
local config = {
    server = {host = "localhost", port = 8080},
    debug = true
}

local overrides = {
    server = {port = 3000, ssl = true},
    verbose = true
}

local merged = tablex.deepmerge(config, overrides)
-- {server = {host = "localhost", port = 3000, ssl = true},
--  debug = true, verbose = true}
```

---

## flatten

```
tablex.flatten(array, depth?) -> array
```

Flattens nested arrays to specified depth.

**Parameters:**
- `array` - Array to flatten
- `depth` (optional) - Maximum nesting depth to flatten (default: infinite)

```lua
local nested = {1, {2, 3}, {4, {5, 6}}}
tablex.flatten(nested)       -- {1, 2, 3, 4, 5, 6}
tablex.flatten(nested, 1)    -- {1, 2, 3, 4, {5, 6}}
```

---

## keys

```
tablex.keys(table) -> array
```

Returns sorted array of table keys.

```lua
local t = {name = "Alice", age = 30, city = "NYC"}
tablex.keys(t)  -- {"age", "city", "name"}
```

---

## values

```
tablex.values(table) -> array
```

Returns array of values (sorted by keys for consistent ordering).

```lua
local t = {x = 10, y = 20, z = 30}
tablex.values(t)  -- {10, 20, 30}
```

---

## invert

```
tablex.invert(table) -> table
```

Creates reverse mapping where values become keys.

```lua
local codes = {red = "R", green = "G", blue = "B"}
tablex.invert(codes)  -- {R = "red", G = "green", B = "blue"}
```

---

## copy

```
tablex.copy(table) -> table
```

Shallow copy (one level only). Nested tables are not copied.

```lua
local t1 = {a = 1, b = {c = 2}}
local t2 = tablex.copy(t1)
t2.a = 999  -- t1.a still 1
t2.b.c = 999  -- t1.b.c also 999 (shallow)
```

---

## map

```
tablex.map(table, func) -> table
```

Applies function to each value, returns new table.

**Parameters:**
- `table` - Input table
- `func` - Function receiving `(value, key)` and returning new value

```lua
local prices = {apple = 1.50, banana = 0.80}
local doubled = tablex.map(prices, function(v) return v * 2 end)
-- {apple = 3.00, banana = 1.60}

-- Function receives (value, key)
tablex.map({10, 20, 30}, function(v, k) return v + k end)
-- {11, 22, 33}
```

---

## filter

```
tablex.filter(table, predicate) -> table
```

Returns new table with elements matching predicate.

**Parameters:**
- `table` - Input table
- `predicate` - Function receiving `(value, key)` and returning boolean

```lua
local numbers = {1, 2, 3, 4, 5, 6}
local evens = tablex.filter(numbers, function(v) return v % 2 == 0 end)
-- {2, 4, 6}

local scores = {alice = 85, bob = 92, charlie = 78}
local passing = tablex.filter(scores, function(v) return v >= 80 end)
-- {alice = 85, bob = 92}
```

---

## reduce

```
tablex.reduce(table, func, initial) -> any
```

Reduces table to single value.

**Parameters:**
- `table` - Input table
- `func` - Function receiving `(accumulator, value, key)` and returning new accumulator
- `initial` - Initial accumulator value

```lua
local sum = tablex.reduce({1, 2, 3, 4}, function(acc, v) return acc + v end, 0)
-- 10

local product = tablex.reduce({2, 3, 4}, function(acc, v) return acc * v end, 1)
-- 24
```

---

## foreach

```
tablex.foreach(table, func) -> nil
```

Iterates for side effects only. Returns nil.

**Parameters:**
- `table` - Input table
- `func` - Function receiving `(value, key)` for side effects

```lua
tablex.foreach({10, 20, 30}, print)
-- Outputs: 10, 20, 30

local total = 0
tablex.foreach({a = 5, b = 10}, function(v) total = total + v end)
print(total)  -- 15
```

---

## find

```
tablex.find(table, value) -> key or nil
```

Returns first key matching value, or nil if not found.

```lua
local colors = {"red", "green", "blue"}
tablex.find(colors, "green")  -- 2

local map = {x = 10, y = 20, z = 10}
tablex.find(map, 10)  -- "x" (first match)
```

---

## contains

```
tablex.contains(table, value) -> boolean
```

Checks if value exists in table.

```lua
tablex.contains({1, 2, 3}, 2)  -- true
tablex.contains({a = 1, b = 2}, 3)  -- false
```

---

## size

```
tablex.size(table) -> number
```

Counts all elements (including non-array keys). Unlike `#` operator which only counts array part.

```lua
local t = {1, 2, 3, x = 10, y = 20}
#t  -- 3 (array part only)
tablex.size(t)  -- 5 (all elements)
```

---

## isempty

```
tablex.isempty(table) -> boolean
```

Returns true if table has no elements.

```lua
tablex.isempty({})  -- true
tablex.isempty({1})  -- false
tablex.isempty({x = 1})  -- false
```

---

## isarray

```
tablex.isarray(table) -> boolean
```

Returns true if table has sequential integer keys starting from 1 with no gaps.

```lua
tablex.isarray({1, 2, 3})  -- true
tablex.isarray({1, 2, nil, 4})  -- false
tablex.isarray({x = 1})  -- false
tablex.isarray({[2] = "a", [3] = "b"})  -- false
```

---

## slice

```
tablex.slice(array, start, end?) -> array
```

Extracts subarray. Supports negative indices.

**Parameters:**
- `array` - Input array
- `start` - Start index (1-based, negative counts from end)
- `end` (optional) - End index (inclusive, negative counts from end, default: last element)

```lua
local arr = {10, 20, 30, 40, 50}
tablex.slice(arr, 2, 4)  -- {20, 30, 40}
tablex.slice(arr, 3)     -- {30, 40, 50}
tablex.slice(arr, -2)    -- {40, 50}
tablex.slice(arr, 2, -1) -- {20, 30, 40, 50}
```

---

## reverse

```
tablex.reverse(array) -> array
```

Returns reversed copy. Original array unchanged.

```lua
tablex.reverse({1, 2, 3, 4})  -- {4, 3, 2, 1}
```

---

## unique

```
tablex.unique(array) -> array
```

Removes duplicate values. Preserves first occurrence.

```lua
tablex.unique({1, 2, 2, 3, 1, 4})  -- {1, 2, 3, 4}
```

---

## sort

```
tablex.sort(array, comparator?) -> array
```

Returns sorted copy. Original array unchanged.

**Parameters:**
- `array` - Input array
- `comparator` (optional) - Function receiving `(a, b)` and returning true if a < b (default: ascending)

```lua
local nums = {3, 1, 4, 1, 5}
local sorted = tablex.sort(nums)  -- {1, 1, 3, 4, 5}
print(nums[1])  -- Still 3

-- Custom comparator
local desc = tablex.sort(nums, function(a, b) return a > b end)
-- {5, 4, 3, 1, 1}
```

---

## union

```
tablex.union(array1, array2) -> array
```

Returns combined unique elements. Treats arrays as sets.

```lua
tablex.union({1, 2, 3}, {3, 4, 5})  -- {1, 2, 3, 4, 5}
```

---

## intersection

```
tablex.intersection(array1, array2) -> array
```

Returns common elements. Treats arrays as sets.

```lua
tablex.intersection({1, 2, 3, 4}, {3, 4, 5, 6})  -- {3, 4}
```

---

## difference

```
tablex.difference(array1, array2) -> array
```

Returns elements in array1 not in array2.

```lua
tablex.difference({1, 2, 3, 4}, {3, 4, 5})  -- {1, 2}
```

---

## equals

```
tablex.equals(t1, t2) -> boolean
```

Shallow equality check. Nested tables must be the same reference.

```lua
tablex.equals({a = 1, b = 2}, {a = 1, b = 2})  -- true
tablex.equals({a = 1, b = {c = 3}}, {a = 1, b = {c = 3}})  -- false (different tables)
```

---

## deepequals

```
tablex.deepequals(t1, t2) -> boolean
```

Recursive equality check. Compares nested tables by value.

```lua
local t1 = {a = 1, b = {c = 2, d = {e = 3}}}
local t2 = {a = 1, b = {c = 2, d = {e = 3}}}
tablex.deepequals(t1, t2)  -- true

local t3 = {a = 1, b = {c = 2, d = {e = 4}}}
tablex.deepequals(t1, t3)  -- false
```

---

## Examples

### Configuration Management

```lua
local defaults = {
    server = {host = "localhost", port = 8080, timeout = 30},
    logging = {level = "info", format = "json"}
}

local production = tablex.deepmerge(defaults, {
    server = {host = "prod.example.com", ssl = true},
    logging = {level = "warn"}
})
-- Result: {
--   server = {host = "prod.example.com", port = 8080, ssl = true, timeout = 30},
--   logging = {level = "warn", format = "json"}
-- }
```

### Data Transformation Pipeline

```lua
local raw_data = {
    {name = "Alice", score = 85, active = true},
    {name = "Bob", score = 62, active = false},
    {name = "Charlie", score = 91, active = true}
}

-- Extract active users' scores
local scores = tablex.map(
    tablex.filter(raw_data, function(user) return user.active end),
    function(user) return user.score end
)
-- {85, 91}

-- Calculate average
local avg = tablex.reduce(scores, function(sum, v) return sum + v end, 0) / #scores
-- 88
```

### Safe Deep Clone

```lua
local original = {
    users = {"alice", "bob"},
    settings = {theme = "dark"}
}

local clone = tablex.deepcopy(original)
clone.users[1] = "charlie"
clone.settings.theme = "light"

print(original.users[1])      -- "alice" (unchanged)
print(original.settings.theme) -- "dark" (unchanged)
```

### Working with Sets

```lua
local current_users = {"alice", "bob", "charlie"}
local new_users = {"charlie", "dave", "eve"}

local all = tablex.union(current_users, new_users)
-- {"alice", "bob", "charlie", "dave", "eve"}

local existing = tablex.intersection(current_users, new_users)
-- {"charlie"}

local to_add = tablex.difference(new_users, current_users)
-- {"dave", "eve"}
```
