# Array Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.array` | **Global:** `array`

N-dimensional arrays with broadcasting and element-wise operations.

## Creating Arrays

```lua
local arr = require("luaswift.array")

-- From nested tables
local a = arr.array({1, 2, 3, 4, 5, 6})        -- 1D
local b = arr.array({{1, 2, 3}, {4, 5, 6}})    -- 2D (2x3)

-- Special constructors
local c = arr.zeros({2, 3, 4})     -- 3D zeros
local d = arr.ones({3, 3})         -- 3x3 ones
local e = arr.full({2, 2}, 7)      -- 2x2 filled with 7
local I = arr.eye(3)               -- 3x3 identity

-- Ranges
local r = arr.arange(0, 10, 2)     -- {0, 2, 4, 6, 8}
local l = arr.linspace(0, 1, 5)    -- {0, 0.25, 0.5, 0.75, 1}

-- Random arrays
local uniform = arr.random.rand({3, 3})   -- uniform [0, 1)
local normal = arr.random.randn({3, 3})   -- normal distribution
local integers = arr.random.randint(0, 10, {5, 5})  -- random integers
```

## Array Properties

```lua
local b = arr.array({{1, 2, 3}, {4, 5, 6}})

print(b:shape())  -- {2, 3}
print(b:ndim())   -- 2
print(b:size())   -- 6
print(b:dtype())  -- "float64"

-- Element access (1-based indexing)
print(b:get(1, 2))    -- 2
b:set(1, 2, 10)
```

## Reshaping

```lua
local a = arr.array({1, 2, 3, 4, 5, 6})

local reshaped = a:reshape({2, 3})     -- 2x3
local flat = reshaped:flatten()         -- back to 1D
local expanded = a:expand_dims(1)       -- add dimension
local squeezed = expanded:squeeze()     -- remove size-1 dimensions
local transposed = reshaped:transpose() -- or :T()
local copied = a:copy()                 -- deep copy
```

## Arithmetic with Broadcasting

```lua
-- Arrays broadcast to compatible shapes
local x = arr.array({{1}, {2}, {3}})  -- 3x1
local y = arr.array({10, 20, 30})      -- 1x3
local z = x + y  -- broadcasts to 3x3:
-- {{11, 21, 31},
--  {12, 22, 32},
--  {13, 23, 33}}

-- Scalar operations
local doubled = b * 2
local shifted = b + 10

-- Element-wise operations
local sum = x + y
local diff = x - y
local prod = x * y
local quot = x / y
local power = x ^ 2
```

**Broadcasting Rules:**
- Dimensions aligned from right
- Size-1 dimensions broadcast to match
- Missing dimensions treated as size 1

## Element-wise Math

```lua
local a = arr.array({1, 4, 9, 16})

local sq = arr.sqrt(a)      -- {1, 2, 3, 4}
local ex = arr.exp(a)
local logs = arr.log(a)
local sines = arr.sin(a)
local cosines = arr.cos(a)
local absolute = arr.abs(a)
local negated = arr.negative(a)
```

## Reductions

```lua
local b = arr.array({{1, 2, 3}, {4, 5, 6}})

-- Global reductions
print(b:sum())   -- 21
print(b:mean())  -- 3.5
print(b:std())   -- standard deviation
print(b:var())   -- variance
print(b:min())   -- 1
print(b:max())   -- 6
print(b:prod())  -- product of all elements

-- Axis reductions
print(b:sum(1))  -- sum along axis 0: {5, 7, 9}
print(b:sum(2))  -- sum along axis 1: {6, 15}

-- Index of min/max
print(b:argmax())  -- index of maximum (1-based)
print(b:argmin())  -- index of minimum (1-based)
```

## Comparisons

```lua
local a = arr.array({1, 2, 3, 4, 5})

-- Returns boolean arrays
local mask = arr.greater(a, 3)     -- {false, false, false, true, true}
local eq = arr.equal(a, 3)         -- {false, false, true, false, false}
local lt = arr.less(a, 3)          -- {true, true, false, false, false}

-- Conditional selection
local result = arr.where(mask, a, arr.zeros({5}))
-- {0, 0, 0, 4, 5}
```

## Matrix Operations

```lua
local m1 = arr.array({{1, 2}, {3, 4}})
local m2 = arr.array({{5, 6}, {7, 8}})

-- Matrix multiplication
local prod = arr.dot(m1, m2)
-- or: arr.matmul(m1, m2)

-- Vector dot product
local v1 = arr.array({1, 2, 3})
local v2 = arr.array({4, 5, 6})
print(arr.dot(v1, v2))  -- 32 (scalar)

-- Outer product
local outer = arr.outer(v1, v2)
```

## Stacking and Splitting

```lua
local a = arr.array({1, 2, 3})
local b = arr.array({4, 5, 6})

-- Concatenate
local h = arr.hstack({a, b})  -- {1, 2, 3, 4, 5, 6}
local v = arr.vstack({a, b})  -- {{1, 2, 3}, {4, 5, 6}}

-- Stack along new axis
local stacked = arr.stack({a, b}, 1)  -- 2x3

-- Split
local parts = arr.split(h, 2)  -- split into 2 equal parts
```

## Conversion

```lua
local a = arr.array({{1, 2}, {3, 4}})

-- To nested Lua tables
local tbl = a:tolist()  -- {{1, 2}, {3, 4}}
```

## Complex Arrays

```lua
-- Create complex array
local c = arr.array({1, 2, 3}, {dtype = "complex128"})

-- Or from real + imaginary
local re = arr.array({1, 2, 3})
local im = arr.array({4, 5, 6})
local complex = arr.complex(re, im)

-- Extract components
local real_part = complex:real()
local imag_part = complex:imag()
local magnitude = arr.abs(complex)
local phase = arr.angle(complex)
```

## Function Reference

| Category | Functions |
|----------|-----------|
| Creation | `array`, `zeros`, `ones`, `full`, `eye`, `arange`, `linspace`, `random.*` |
| Properties | `shape`, `ndim`, `size`, `dtype`, `get`, `set` |
| Reshaping | `reshape`, `flatten`, `squeeze`, `expand_dims`, `transpose`/`T`, `copy` |
| Math | `abs`, `sqrt`, `exp`, `log`, `sin`, `cos`, `tan`, `negative` |
| Arithmetic | `+`, `-`, `*`, `/`, `^` (with broadcasting) |
| Reductions | `sum`, `mean`, `std`, `var`, `min`, `max`, `argmin`, `argmax`, `prod` |
| Comparison | `equal`, `greater`, `less`, `greater_equal`, `less_equal`, `where` |
| Linear Algebra | `dot`, `matmul`, `outer` |
| Stacking | `hstack`, `vstack`, `stack`, `concatenate`, `split` |
