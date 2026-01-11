# TableX Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.tablex` | **Extends:** `table`

Efficient table manipulation utilities with deep copying, merging, and functional operations. Inspired by Lua's Penlight library, implemented in Swift for performance.

## Import into Standard Library

```lua
local tablex = require("luaswift.tablex")
tablex.import()  -- Extends table.* with all functions
```

## Deep Operations

### deepcopy(table[, seen])

Creates a deep copy of a table with automatic cycle detection. Preserves LuaSwift typed objects using `types.clone()`.

```lua
local t1 = {a = 1, b = {c = 2, d = {e = 3}}}
t1.self = t1  -- Circular reference

local t2 = tablex.deepcopy(t1)
t2.a = 999
print(t1.a)  -- Still 1
```

### deepmerge(t1, t2)

Recursively merges two tables. Values in `t2` override those in `t1`. Nested tables are merged recursively. Typed objects are replaced, not merged.

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

### flatten(array[, depth])

Flattens nested arrays to specified depth (default: full flatten).

```lua
local nested = {1, {2, 3}, {4, {5, 6}}}
tablex.flatten(nested)       -- {1, 2, 3, 4, 5, 6}
tablex.flatten(nested, 1)    -- {1, 2, 3, 4, {5, 6}}
```

## Key/Value Operations

### keys(table)

Returns sorted array of table keys.

```lua
local t = {name = "Alice", age = 30, city = "NYC"}
tablex.keys(t)  -- {"age", "city", "name"}
```

### values(table)

Returns array of values (sorted by keys for consistent ordering).

```lua
local t = {x = 10, y = 20, z = 30}
tablex.values(t)  -- {10, 20, 30}
```

### invert(table)

Creates reverse mapping (values become keys).

```lua
local codes = {red = "R", green = "G", blue = "B"}
tablex.invert(codes)  -- {R = "red", G = "green", B = "blue"}
```

## Functional Operations

### copy(table)

Shallow copy (one level only).

```lua
local t1 = {a = 1, b = {c = 2}}
local t2 = tablex.copy(t1)
t2.a = 999  -- t1.a still 1
t2.b.c = 999  -- t1.b.c also 999 (shallow)
```

### map(table, func)

Applies function to each value, returns new table.

```lua
local prices = {apple = 1.50, banana = 0.80}
local doubled = tablex.map(prices, function(v) return v * 2 end)
-- {apple = 3.00, banana = 1.60}

-- Function receives (value, key)
tablex.map({10, 20, 30}, function(v, k) return v + k end)
-- {11, 22, 33}
```

### filter(table, predicate)

Returns new table with elements matching predicate.

```lua
local numbers = {1, 2, 3, 4, 5, 6}
local evens = tablex.filter(numbers, function(v) return v % 2 == 0 end)
-- {2, 4, 6}

local scores = {alice = 85, bob = 92, charlie = 78}
local passing = tablex.filter(scores, function(v) return v >= 80 end)
-- {alice = 85, bob = 92}
```

### reduce(table, func, initial)

Reduces table to single value.

```lua
local sum = tablex.reduce({1, 2, 3, 4}, function(acc, v) return acc + v end, 0)
-- 10

local product = tablex.reduce({2, 3, 4}, function(acc, v) return acc * v end, 1)
-- 24

-- Function receives (accumulator, value, key)
```

### foreach(table, func)

Iterates for side effects only (returns nil).

```lua
tablex.foreach({10, 20, 30}, print)
-- Outputs: 10, 20, 30

local total = 0
tablex.foreach({a = 5, b = 10}, function(v) total = total + v end)
print(total)  -- 15
```

## Search Operations

### find(table, value)

Returns first key matching value, or nil.

```lua
local colors = {"red", "green", "blue"}
tablex.find(colors, "green")  -- 2

local map = {x = 10, y = 20, z = 10}
tablex.find(map, 10)  -- "x" (first match)
```

### contains(table, value)

Checks if value exists.

```lua
tablex.contains({1, 2, 3}, 2)  -- true
tablex.contains({a = 1, b = 2}, 3)  -- false
```

## Size and Type Operations

### size(table)

Counts all elements (including non-array keys).

```lua
local t = {1, 2, 3, x = 10, y = 20}
#t  -- 3 (array part only)
tablex.size(t)  -- 5 (all elements)
```

### isempty(table)

Returns true if table has no elements.

```lua
tablex.isempty({})  -- true
tablex.isempty({1})  -- false
tablex.isempty({x = 1})  -- false
```

### isarray(table)

Returns true if table has sequential integer keys from 1.

```lua
tablex.isarray({1, 2, 3})  -- true
tablex.isarray({1, 2, nil, 4})  -- false
tablex.isarray({x = 1})  -- false
tablex.isarray({[2] = "a", [3] = "b"})  -- false
```

## Array Operations

### slice(array, start[, end])

Extracts subarray. Supports negative indices.

```lua
local arr = {10, 20, 30, 40, 50}
tablex.slice(arr, 2, 4)  -- {20, 30, 40}
tablex.slice(arr, 3)     -- {30, 40, 50}
tablex.slice(arr, -2)    -- {40, 50}
tablex.slice(arr, 2, -1) -- {20, 30, 40, 50}
```

### reverse(array)

Returns reversed copy.

```lua
tablex.reverse({1, 2, 3, 4})  -- {4, 3, 2, 1}
```

### unique(array)

Removes duplicate values.

```lua
tablex.unique({1, 2, 2, 3, 1, 4})  -- {1, 2, 3, 4}
```

### sort(array[, comparator])

Returns sorted copy (original unchanged).

```lua
local nums = {3, 1, 4, 1, 5}
local sorted = tablex.sort(nums)  -- {1, 1, 3, 4, 5}
print(nums[1])  -- Still 3

-- Custom comparator
local desc = tablex.sort(nums, function(a, b) return a > b end)
-- {5, 4, 3, 1, 1}
```

## Set Operations

All set operations treat arrays as sets (ignoring duplicate values).

### union(array1, array2)

Returns combined unique elements.

```lua
tablex.union({1, 2, 3}, {3, 4, 5})  -- {1, 2, 3, 4, 5}
```

### intersection(array1, array2)

Returns common elements.

```lua
tablex.intersection({1, 2, 3, 4}, {3, 4, 5, 6})  -- {3, 4}
```

### difference(array1, array2)

Returns elements in array1 not in array2.

```lua
tablex.difference({1, 2, 3, 4}, {3, 4, 5})  -- {1, 2}
```

## Equality Operations

### equals(t1, t2)

Shallow equality check.

```lua
tablex.equals({a = 1, b = 2}, {a = 1, b = 2})  -- true
tablex.equals({a = 1, b = {c = 3}}, {a = 1, b = {c = 3}})  -- false (different tables)
```

### deepequals(t1, t2)

Recursive equality check.

```lua
local t1 = {a = 1, b = {c = 2, d = {e = 3}}}
local t2 = {a = 1, b = {c = 2, d = {e = 3}}}
tablex.deepequals(t1, t2)  -- true

local t3 = {a = 1, b = {c = 2, d = {e = 4}}}
tablex.deepequals(t1, t3)  -- false
```

## Practical Examples

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

## Function Reference

| Function | Description | Returns |
|----------|-------------|---------|
| `deepcopy(t, seen)` | Deep copy with cycle detection | table |
| `deepmerge(t1, t2)` | Recursive merge | table |
| `flatten(arr, depth)` | Flatten nested arrays | array |
| `keys(t)` | Extract keys (sorted) | array |
| `values(t)` | Extract values | array |
| `invert(t)` | Reverse key-value mapping | table |
| `copy(t)` | Shallow copy | table |
| `map(t, f)` | Apply function to values | table |
| `filter(t, f)` | Filter by predicate | table |
| `reduce(t, f, init)` | Fold/reduce to single value | any |
| `foreach(t, f)` | Iterate with side effects | nil |
| `find(t, val)` | Find key for value | key or nil |
| `contains(t, val)` | Check if value exists | boolean |
| `size(t)` | Count all elements | number |
| `isempty(t)` | Check if empty | boolean |
| `isarray(t)` | Check if array-like | boolean |
| `slice(arr, i, j)` | Extract subarray | array |
| `reverse(arr)` | Reverse array | array |
| `unique(arr)` | Remove duplicates | array |
| `sort(arr, comp)` | Sort array | array |
| `union(a1, a2)` | Set union | array |
| `intersection(a1, a2)` | Set intersection | array |
| `difference(a1, a2)` | Set difference | array |
| `equals(t1, t2)` | Shallow equality | boolean |
| `deepequals(t1, t2)` | Deep equality | boolean |
| `import()` | Extend `table.*` library | void |
