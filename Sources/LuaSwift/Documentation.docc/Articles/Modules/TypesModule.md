# Types Module

Type detection and conversion utilities for LuaSwift interoperability.

## Overview

The Types module provides utilities for detecting and working with LuaSwift types. It enables runtime type checking, category classification, type conversion, and cloning while preserving type information. This is essential for writing type-safe code that works with multiple LuaSwift modules.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the Types module
ModuleRegistry.installTypesModule(in: engine)
```

## Basic Usage

```lua
local types = require("luaswift.types")

-- Type detection
local v = geo.vec2(3, 4)
print(types.typeof(v))           -- "vec2"
print(types.is(v, "vec2"))       -- true
print(types.is_luaswift(v))      -- true

-- Callable and iterable checks
print(types.is_callable(print))  -- true
print(types.is_iterable({1,2}))  -- true

-- Category checks
print(types.is_vector(v))        -- true
print(types.is_geometry(v))      -- true

-- Conversions
local arr = types.to_array(v)    -- Convert vec2 to array

-- Cloning
local v2 = types.clone(v)
```

## API Reference

### Type Detection

#### typeof(value)
Returns the type name of any value. For LuaSwift objects, returns the `__luaswift_type` field; for primitives, returns the Lua type. Plain tables without `__luaswift_type` return `"table"`.

```lua
-- Primitives
types.typeof(42)                 -- "number"
types.typeof("hello")            -- "string"
types.typeof(true)               -- "boolean"
types.typeof(nil)                -- "nil"
types.typeof(print)              -- "function"

-- Plain tables
types.typeof({1, 2, 3})          -- "table"
types.typeof({a = 1})            -- "table"

-- LuaSwift types
types.typeof(complex.new(1, 2))  -- "complex"
types.typeof(geo.vec2(1, 2))     -- "vec2"
types.typeof(geo.vec3(1, 2, 3))  -- "vec3"
types.typeof(geo.quaternion())   -- "quaternion"
types.typeof(geo.transform3d())  -- "transform3d"
types.typeof(linalg.vector({1,2}))  -- "linalg.vector"
types.typeof(linalg.matrix({{1,2}})) -- "linalg.matrix"
types.typeof(np.array({1, 2}))   -- "array"
```

#### is(value, typename)
Checks if a value is a specific type.

```lua
local v = geo.vec2(3, 4)
types.is(v, "vec2")              -- true
types.is(v, "vec3")              -- false
types.is(v, "table")             -- false (vec2, not plain table)

local t = {1, 2, 3}
types.is(t, "table")             -- true
types.is(t, "array")             -- false (plain table, not array)

types.is(42, "number")           -- true
types.is("hi", "string")         -- true
```

#### is_luaswift(value)
Checks if a value is any LuaSwift type (has `__luaswift_type` field). Returns `false` for primitives and plain tables.

```lua
types.is_luaswift(geo.vec2(1, 2))     -- true
types.is_luaswift(complex.new(1, 2))  -- true
types.is_luaswift(np.array({1}))      -- true

types.is_luaswift({1, 2, 3})          -- false (plain table)
types.is_luaswift(42)                 -- false (primitive)
types.is_luaswift("hello")            -- false (primitive)
```

#### is_callable(value)
Returns `true` if the value is a function or a table with a `__call` metamethod.

```lua
types.is_callable(print)              -- true (function)
types.is_callable(math.sqrt)          -- true (function)

-- Table with __call metamethod
local functor = setmetatable({}, {__call = function() end})
types.is_callable(functor)            -- true

types.is_callable({1, 2, 3})          -- false (plain table, no __call)
types.is_callable(42)                 -- false (number)
types.is_callable("hello")            -- false (string)
```

#### is_iterable(value)
Returns `true` if the value is a table. All Lua tables are iterable; non-table values (functions, numbers, strings, userdata) return `false` regardless of metamethods.

```lua
types.is_iterable({1, 2, 3})          -- true
types.is_iterable({a = 1})            -- true
types.is_iterable(geo.vec2(1, 2))     -- true (vec2 is a table)
types.is_iterable(np.array({1}))      -- true (array is a table)

types.is_iterable(42)                 -- false
types.is_iterable("hello")            -- false
types.is_iterable(print)              -- false
```

### Category Checks

These functions check if a value belongs to a category of related types.

#### is_numeric(value)
Returns `true` for `number` or `complex` types.

```lua
types.is_numeric(42)                  -- true
types.is_numeric(3.14)                -- true
types.is_numeric(complex.new(1, 2))   -- true
types.is_numeric("42")                -- false
types.is_numeric(geo.vec2(1, 2))      -- false
```

#### is_vector(value)
Returns `true` for `vec2`, `vec3`, or `linalg.vector` types.

```lua
types.is_vector(geo.vec2(1, 2))       -- true
types.is_vector(geo.vec3(1, 2, 3))    -- true
types.is_vector(linalg.vector({1,2})) -- true

types.is_vector(np.array({1, 2}))     -- false (array, not vector)
types.is_vector({1, 2, 3})            -- false (plain table)
```

#### is_matrix(value)
Returns `true` for `linalg.matrix` or `array` types.

```lua
types.is_matrix(linalg.matrix({{1,2},{3,4}}))  -- true
types.is_matrix(np.array({{1,2},{3,4}}))       -- true

types.is_matrix(linalg.vector({1, 2}))         -- false
types.is_matrix({{1, 2}, {3, 4}})              -- false (plain table)
```

#### is_geometry(value)
Returns `true` for `vec2`, `vec3`, `quaternion`, or `transform3d` types.

```lua
types.is_geometry(geo.vec2(1, 2))        -- true
types.is_geometry(geo.vec3(1, 2, 3))     -- true
types.is_geometry(geo.quaternion())       -- true
types.is_geometry(geo.transform3d())      -- true

types.is_geometry(complex.new(1, 2))      -- false
types.is_geometry(linalg.vector({1, 2}))  -- false
```

### Type Conversion

Convert between compatible LuaSwift types.

#### to_array(value)
Converts to `array` type.

```lua
-- From linalg types
local v = linalg.vector({1, 2, 3})
local arr = types.to_array(v)
print(arr:tolist())              -- {1, 2, 3}

-- From geometry types
local v2 = geo.vec2(3, 4)
local arr = types.to_array(v2)
print(arr:tolist())              -- {3, 4}

-- From plain table
local arr = types.to_array({1, 2, 3})
print(arr:shape())               -- {3}

-- Array passes through unchanged
local arr1 = np.array({1, 2})
local arr2 = types.to_array(arr1)
print(arr1 == arr2)              -- true
```

#### to_vec2(value)
Converts to `vec2` type.

```lua
-- From array
local arr = np.array({3, 4})
local v = types.to_vec2(arr)
print(v.x, v.y)                  -- 3, 4

-- From linalg vector
local lv = linalg.vector({5, 6})
local v = types.to_vec2(lv)
print(v.x, v.y)                  -- 5, 6

-- From plain table
local v = types.to_vec2({1, 2})
print(v.x, v.y)                  -- 1, 2

-- vec2 passes through unchanged
local v1 = geo.vec2(1, 2)
local v2 = types.to_vec2(v1)
print(v1 == v2)                  -- true
```

#### to_vec3(value)
Converts to `vec3` type. Missing z-component defaults to 0.

```lua
-- From vec2 (z becomes 0)
local v2 = geo.vec2(1, 2)
local v3 = types.to_vec3(v2)
print(v3.x, v3.y, v3.z)          -- 1, 2, 0

-- From array
local arr = np.array({3, 4, 5})
local v = types.to_vec3(arr)
print(v.x, v.y, v.z)             -- 3, 4, 5

-- From 2-element array (z defaults to 0)
local arr = np.array({3, 4})
local v = types.to_vec3(arr)
print(v.z)                       -- 0

-- From plain table
local v = types.to_vec3({1, 2, 3})
print(v.x, v.y, v.z)             -- 1, 2, 3
```

#### to_complex(value)
Converts to `complex` type.

```lua
-- From number (real only, imaginary part is 0)
local c = types.to_complex(5)
print(c.re, c.im)                -- 5, 0

-- From vec2 (x maps to real, y maps to imaginary)
local v = geo.vec2(3, 4)
local c = types.to_complex(v)
print(c.re, c.im)                -- 3, 4

-- Complex passes through unchanged
local c1 = complex.new(1, 2)
local c2 = types.to_complex(c1)
print(c1 == c2)                  -- true
```

#### to_vector(value)
Converts to `linalg.vector` type.

```lua
-- From geometry types
local v2 = geo.vec2(3, 4)
local lv = types.to_vector(v2)
print(lv:size())                 -- 2

local v3 = geo.vec3(1, 2, 3)
local lv = types.to_vector(v3)
print(lv:size())                 -- 3

-- From array
local arr = np.array({1, 2, 3, 4})
local lv = types.to_vector(arr)
print(lv:size())                 -- 4

-- From plain table
local lv = types.to_vector({5, 6, 7})
print(lv:size())                 -- 3
```

#### to_matrix(value)
Converts to `linalg.matrix` type.

```lua
-- From array
local arr = np.array({{1, 2}, {3, 4}})
local m = types.to_matrix(arr)
print(m:rows(), m:cols())        -- 2, 2

-- From plain table
local m = types.to_matrix({{1, 2, 3}, {4, 5, 6}})
print(m:rows(), m:cols())        -- 2, 3
```

### Utilities

#### clone(value)
Creates a copy of a value while preserving its LuaSwift type. Behavior varies by type:

| Type | Copy mechanism |
|------|----------------|
| `complex` | Constructs new instance from `re`/`im` fields |
| `vec2` | Constructs new instance from `x`/`y` fields |
| `vec3` | Constructs new instance from `x`/`y`/`z` fields |
| `quaternion` | Constructs new instance from `w`/`x`/`y`/`z` fields |
| `transform3d` | Deep-copies internal `_m[1..16]` matrix array, then constructs |
| `array` | Calls `value:copy()` |
| `linalg.vector` / `linalg.matrix` | Applies `value:transpose():transpose()` — the only available copy path since linalg has no direct copy method |
| plain `table` | Calls `luaswift.tablex.deepcopy` if tablex is loaded; **falls back to a shallow copy** (`for k,v in pairs(...)`) if tablex is unavailable |
| primitives | Returned as-is (immutable) |

> Note: Table cloning is only a true deep copy when the tablex module is loaded. If tablex is absent, nested tables are shared between the original and the copy. For guaranteed deep copies of plain tables, load the tablex module or clone manually.

```lua
-- Clone complex numbers
local c1 = complex.new(3, 4)
local c2 = types.clone(c1)
c2.re = 99
print(c1.re)                     -- 3 (unchanged)

-- Clone geometry types
local v1 = geo.vec2(1, 2)
local v2 = types.clone(v1)

-- Clone arrays (uses array:copy())
local arr1 = np.array({1, 2, 3})
local arr2 = types.clone(arr1)

-- Clone linalg types (double-transpose copy path)
local lv1 = linalg.vector({1, 2, 3})
local lv2 = types.clone(lv1)    -- equivalent to lv1:transpose():transpose()

-- Clone quaternions
local q1 = geo.quaternion()
local q2 = types.clone(q1)

-- Clone transforms (internal _m matrix is deep-copied)
local t1 = geo.transform3d():translate(1, 2, 3)
local t2 = types.clone(t1)

-- Plain table: deep copy only if tablex is loaded; shallow copy otherwise
local t1 = {a = 1, b = {c = 2}}
local t2 = types.clone(t1)
-- With tablex loaded:    t2.b.c = 99  =>  t1.b.c still 2
-- Without tablex loaded: t2.b.c = 99  =>  t1.b.c becomes 99 (shared nested table)

-- Primitives return as-is (immutable)
local n = types.clone(42)        -- 42
local s = types.clone("hi")      -- "hi"
```

#### all_types()
Returns an array of all registered LuaSwift type names.

```lua
local all = types.all_types()
-- {"complex", "vec2", "vec3", "quaternion", "transform3d",
--  "linalg.vector", "linalg.matrix", "array"}
```

## Common Patterns

### Type-Safe Function Arguments

```lua
local function process_vector(input)
    -- Accept any vector-like input
    local v
    if types.is(input, "vec3") then
        v = input
    elseif types.is_vector(input) then
        v = types.to_vec3(input)
    elseif type(input) == "table" then
        v = geo.vec3(input[1], input[2], input[3])
    else
        error("Expected vector, got " .. types.typeof(input))
    end
    return v:normalize()
end

-- All these work:
process_vector(geo.vec3(1, 2, 3))
process_vector(geo.vec2(1, 2))
process_vector(linalg.vector({1, 2, 3}))
process_vector({1, 2, 3})
```

### Guarding Callable Arguments

```lua
local function apply(fn, value)
    if not types.is_callable(fn) then
        error("Expected callable, got " .. types.typeof(fn))
    end
    return fn(value)
end

apply(math.sqrt, 9)              -- 3.0
apply(math.abs, -5)              -- 5
```

### Iterating Unknown Input

```lua
local function sum_all(input)
    if not types.is_iterable(input) then
        -- Scalar: wrap and sum directly
        return input
    end
    local total = 0
    for _, v in ipairs(input) do
        total = total + v
    end
    return total
end
```

### Generic Numeric Operations

```lua
local function magnitude(value)
    if types.is(value, "number") then
        return math.abs(value)
    elseif types.is(value, "complex") then
        return value:abs()
    elseif types.is_vector(value) then
        if types.is(value, "linalg.vector") then
            return value:norm()
        else
            return value:length()
        end
    else
        error("Cannot compute magnitude of " .. types.typeof(value))
    end
end
```

### Safe Deep Copy for Mixed Data

```lua
-- Requires tablex module for guaranteed deep copies of plain tables.
local function safe_copy(data)
    if types.is_luaswift(data) then
        return types.clone(data)
    elseif type(data) == "table" then
        local copy = {}
        for k, v in pairs(data) do
            copy[safe_copy(k)] = safe_copy(v)
        end
        return copy
    else
        return data
    end
end
```

### Type Dispatching

```lua
local handlers = {
    vec2 = function(v) return "2D point at " .. v.x .. "," .. v.y end,
    vec3 = function(v) return "3D point at " .. v.x .. "," .. v.y .. "," .. v.z end,
    complex = function(c) return "Complex number: " .. tostring(c) end,
}

local function describe(value)
    local t = types.typeof(value)
    local handler = handlers[t]
    if handler then
        return handler(value)
    else
        return "Unknown type: " .. t
    end
end
```

### Type Validation

```lua
local function validate_geometry_data(data)
    local errors = {}

    if data.position then
        if not types.is_geometry(data.position) then
            table.insert(errors, "position must be a geometry type")
        end
    end

    if data.rotation then
        if not types.is(data.rotation, "quaternion") then
            table.insert(errors, "rotation must be a quaternion")
        end
    end

    if data.scale then
        if not types.is_numeric(data.scale) and
           not types.is_vector(data.scale) then
            table.insert(errors, "scale must be numeric or vector")
        end
    end

    return #errors == 0, errors
end
```

## LuaSwift Type System

All LuaSwift types use the `__luaswift_type` field for identification:

| Type | `__luaswift_type` value |
|------|-------------------------|
| Complex number | `"complex"` |
| 2D Vector | `"vec2"` |
| 3D Vector | `"vec3"` |
| Quaternion | `"quaternion"` |
| 4x4 Transform | `"transform3d"` |
| Linear algebra vector | `"linalg.vector"` |
| Linear algebra matrix | `"linalg.matrix"` |
| N-dimensional array | `"array"` |

## See Also

- ``TypesModule``
- ``GeometryModule``
- ``ComplexModule``
- ``LinAlgModule``
- ``ArrayModule``
