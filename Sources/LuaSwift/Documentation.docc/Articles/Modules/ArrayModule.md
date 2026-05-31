# Array Module

NumPy-like N-dimensional arrays with hardware-accelerated operations.

> Important: The Array module is **opt-in and disabled by default**. It requires the `ArraySwift` package and must be enabled at build time by setting `LUASWIFT_INCLUDE_ARRAYSWIFT=1` (or the `LUASWIFT_ARRAYSWIFT` Swift compiler flag). Do not call `require("luaswift.array")` unless your build includes this flag.

## Overview

The Array module provides NumPy-style N-dimensional array operations with efficient storage and hardware acceleration via Apple's Accelerate framework. It supports broadcasting, element-wise operations, reductions, reshaping, sorting, statistics, signal processing, FFT, set operations, and advanced indexing.

## Installation

```swift
// Install all modules (Array module is skipped unless LUASWIFT_ARRAYSWIFT is set)
ModuleRegistry.installModules(in: engine)

// Or register the Array module explicitly
ArrayModule.register(in: engine)
```

## Basic Usage

```lua
local np = require("luaswift.array")

-- Create arrays
local a = np.array({1, 2, 3, 4, 5, 6})
local b = np.zeros({2, 3})
local c = np.array({{1, 2, 3}, {4, 5, 6}})

-- Check properties
print(c:shape())    -- {2, 3}
print(c:ndim())     -- 2
print(c:size())     -- 6

-- Element-wise operations
local d = c * 2                    -- Scalar multiplication
local e = c + np.ones({2, 3})     -- Array addition

-- Reductions
print(np.sum(c))        -- 21
print(np.mean(c))       -- 3.5
print(np.max(c))        -- 6
```

## API Reference

### Array Creation

#### array(data)

Creates an array from nested Lua tables.

```lua
local a = np.array({1, 2, 3, 4, 5})              -- 1D
local b = np.array({{1, 2, 3}, {4, 5, 6}})       -- 2D
local c = np.array({{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}})  -- 3D
```

#### zeros(shape, dtype?)

Creates an array filled with zeros. Optional `dtype` string: `"float64"` (default), `"int64"`, `"bool"`, `"complex128"`.

```lua
local a = np.zeros({3})           -- {0, 0, 0}
local b = np.zeros({2, 3})        -- 2x3 zeros
local c = np.zeros({4}, "int64")  -- int64 zeros
```

#### ones(shape, dtype?)

Creates an array filled with ones. Accepts the same optional `dtype` as `zeros`.

```lua
local a = np.ones({4})            -- {1, 1, 1, 1}
local b = np.ones({3, 3})         -- 3x3 ones
```

#### full(shape, value, dtype?)

Creates an array filled with a specific value.

```lua
local a = np.full({3}, 7)         -- {7, 7, 7}
local b = np.full({2, 2}, -1)     -- 2x2 of -1s
```

#### empty(shape)

Creates an uninitialized array with the given shape. Values are undefined.

```lua
local a = np.empty({3, 3})
```

#### zeros_like(a)

Creates a zero-filled array with the same shape as `a`.

```lua
local b = np.zeros_like(a)
```

#### ones_like(a)

Creates a one-filled array with the same shape as `a`.

```lua
local b = np.ones_like(a)
```

#### full_like(a, fill_value)

Creates an array filled with `fill_value` and the same shape as `a`.

```lua
local b = np.full_like(a, 3.14)
```

#### arange(start, stop, step?)

Creates a 1D array with evenly spaced values in `[start, stop)`. Default `step` is 1.

```lua
local a = np.arange(0, 5)       -- {0, 1, 2, 3, 4}
local b = np.arange(0, 10, 2)   -- {0, 2, 4, 6, 8}
local c = np.arange(5, 0, -1)   -- {5, 4, 3, 2, 1}
```

#### linspace(start, stop, num?)

Creates a 1D array with `num` evenly spaced values, inclusive of `stop`. Default `num` is 50.

```lua
local a = np.linspace(0, 1, 5)      -- {0, 0.25, 0.5, 0.75, 1}
local b = np.linspace(0, 10, 11)    -- {0, 1, 2, ..., 10}
```

#### eye(n, m?, k?)

Creates an identity-like 2D array. `n` rows, `m` columns (default `n`), ones on diagonal `k` (default 0).

```lua
local I = np.eye(3)          -- 3x3 identity
local J = np.eye(3, 4, 1)   -- 3x4, ones on superdiagonal
```

#### identity(n)

Creates an `n×n` identity matrix.

```lua
local I = np.identity(4)
```

### Random Arrays

#### random.rand(shape)

Creates an array of uniform random values in `[0, 1)`.

```lua
local a = np.random.rand({3})       -- 1D, 3 values
local b = np.random.rand({2, 3})    -- 2x3 random matrix
```

#### random.randn(shape)

Creates an array of normally distributed random values (mean=0, std=1).

```lua
local a = np.random.randn({1000})   -- 1000 samples from N(0,1)
local b = np.random.randn({10, 10}) -- 10x10 random matrix
```

### Complex Array Creation

#### complex_array(real, imag)

Creates a `complex128` array from real and imaginary part arrays (or tables).

```lua
local r = np.array({1, 2, 3})
local i = np.array({4, 5, 6})
local z = np.complex_array(r, i)   -- [1+4j, 2+5j, 3+6j]
```

#### from_polar(magnitude, angle)

Creates a `complex128` array from polar form: `z = r * (cos θ + i sin θ)`.

```lua
local mag   = np.array({1, 1, 1})
local phase = np.array({0, math.pi/2, math.pi})
local z = np.from_polar(mag, phase)
```

### Properties

#### a:shape()

Returns the array dimensions as a Lua table.

```lua
local a = np.array({{1, 2, 3}, {4, 5, 6}})
print(a:shape())    -- {2, 3}
```

#### a:ndim()

Returns the number of dimensions.

```lua
print(a:ndim())     -- 2
```

#### a:size()

Returns the total number of elements.

```lua
print(a:size())     -- 6
```

#### a:dtype()  /  np.dtype(a)

Returns the dtype string: `"float64"`, `"int64"`, `"bool"`, or `"complex128"`.

```lua
print(a:dtype())            -- "float64"
print(np.dtype(a))          -- "float64"
local b = np.zeros({3}, "int64")
print(b:dtype())            -- "int64"
```

#### a:iscomplex()

Returns `true` if the array has `complex128` dtype.

```lua
local z = np.complex_array(np.ones({3}), np.zeros({3}))
print(z:iscomplex())   -- true
```

### Complex Properties

These are available as both namespace functions and method calls on an array object.

#### np.real(a)  /  a:real()

Extracts the real part. For a real array, returns a copy.

```lua
local r = np.real(z)   -- or z:real()
```

#### np.imag(a)  /  a:imag()

Extracts the imaginary part. For a real array, returns zeros.

```lua
local i = np.imag(z)   -- or z:imag()
```

#### np.conj(a)  /  a:conj()

Returns the complex conjugate. For a real array, returns a copy.

```lua
local zc = np.conj(z)  -- or z:conj()
```

#### np.arg(a)  /  a:arg()

Returns the argument (phase angle) of each element, in radians.

```lua
local theta = np.arg(z)  -- or z:arg()
```

### Element Access

#### a:get(i, j, ...)

Gets an element by 1-based index.

```lua
local a = np.array({{1, 2, 3}, {4, 5, 6}})
print(a:get(1, 2))    -- 2
print(a:get(2, 3))    -- 6
```

#### a:set(i, j, ..., value)

Sets an element by 1-based index. Returns the modified array (mutates in place).

```lua
local a = np.array({{1, 2}, {3, 4}})
a:set(1, 1, 99)
print(a:get(1, 1))    -- 99
```

#### a:slice(start?, stop?, step?)

Returns a 1D sub-array from a 1D array. Indices are 1-based. Negative indices count from the end.

```lua
local a = np.array({10, 20, 30, 40, 50})
local b = a:slice(2, 4)       -- {20, 30, 40}
local c = a:slice(nil, nil, 2) -- {10, 30, 50}
```

### Advanced Indexing

#### np.getmask(a, mask)

Returns elements of `a` where boolean `mask` is true, as a 1D array.

```lua
local a    = np.array({1, 2, 3, 4, 5})
local mask = np.greater(a, 3)
local b    = np.getmask(a, mask)   -- {4, 5}
```

#### np.gather(a, indices)

Selects elements from a flat array by 1-based indices (Lua table or array).

```lua
local a = np.array({10, 20, 30, 40})
local b = np.gather(a, {1, 3, 4})   -- {10, 30, 40}
```

#### np.get_neg(a, index)

Gets a single element using a 1-based or negative index. `-1` is the last element.

```lua
local a = np.array({10, 20, 30})
print(np.get_neg(a, -1))   -- 30
```

#### np.maskset(a, mask, value)

Sets all positions where `mask` is true to `value` (scalar). Mutates and returns `a`.

```lua
local a    = np.array({1, 2, 3, 4, 5})
local mask = np.greater(a, 3)
np.maskset(a, mask, 0)     -- a is now {1, 2, 3, 0, 0}
```

### Reshaping Operations

#### a:reshape(new_shape)  /  np.reshape(a, new_shape)

Returns an array with the same data and a new shape. Total element count must not change.

```lua
local a = np.array({1, 2, 3, 4, 5, 6})
local b = a:reshape({2, 3})
print(b:shape())    -- {2, 3}
```

#### a:flatten()

Returns a 1D array containing all elements in row-major order.

```lua
local a = np.array({{1, 2}, {3, 4}})
local b = a:flatten()
print(b:tolist())   -- {1, 2, 3, 4}
```

#### a:squeeze()

Removes all dimensions of size 1.

```lua
local a = np.array({{{1, 2, 3}}})   -- shape: {1, 1, 3}
local b = a:squeeze()
print(b:shape())    -- {3}
```

#### a:expand_dims(axis)

Inserts a dimension of size 1 at position `axis` (1-based).

```lua
local a = np.array({1, 2, 3})   -- shape: {3}
local b = a:expand_dims(1)
print(b:shape())    -- {1, 3}
```

#### a:T()  /  a:transpose(axes?)  /  np.transpose(a, axes?)

Transposes the array. For 2D, swaps rows and columns. Custom axis permutation with optional 1-based `axes` table.

```lua
local a = np.array({{1, 2, 3}, {4, 5, 6}})
local b = a:T()
print(b:shape())    -- {3, 2}
```

### Arithmetic Operations

Arrays support standard operators with broadcasting. All operators work element-wise. A scalar operand is broadcast across the full array.

| Operator | Description |
|----------|-------------|
| `+` | Element-wise addition |
| `-` | Element-wise subtraction |
| `*` | Element-wise multiplication |
| `/` | Element-wise division |
| `^` | Element-wise power |
| `-` (unary) | Negation |

```lua
local a = np.array({1, 2, 3})
local b = np.array({4, 5, 6})

print((a + b):tolist())    -- {5, 7, 9}
print((a * b):tolist())    -- {4, 10, 18}
print((b / a):tolist())    -- {4, 2.5, 2}
print((a ^ 2):tolist())    -- {1, 4, 9}
print((-a):tolist())       -- {-1, -2, -3}
```

### Math Functions

All math functions operate element-wise and return a new array.

#### Exponential and Logarithm

| Function | Description |
|----------|-------------|
| `np.abs(a)` | Absolute value |
| `np.sqrt(a)` | Square root |
| `np.csqrt(a)` | Complex square root (returns complex128 array) |
| `np.exp(a)` | Exponential (`e^x`) |
| `np.expm1(a)` | `e^x - 1`, accurate near zero |
| `np.log(a)` | Natural logarithm |
| `np.log2(a)` | Base-2 logarithm |
| `np.log10(a)` | Base-10 logarithm |
| `np.log1p(a)` | `log(1 + x)`, accurate near zero |
| `np.clog(a)` | Complex natural logarithm |
| `np.power(a, b)` | Element-wise `a^b` (also available as `a ^ b` operator) |

```lua
local a = np.array({1, 4, 9, 16})
print(np.sqrt(a):tolist())   -- {1, 2, 3, 4}

local b = np.array({0, 1, 2})
print(np.exp(b):tolist())    -- {1, e, e^2}
print(np.log(np.exp(b)):tolist())  -- {0, 1, 2}
```

#### Trigonometric

| Function | Description |
|----------|-------------|
| `np.sin(a)` | Sine (radians) |
| `np.cos(a)` | Cosine (radians) |
| `np.tan(a)` | Tangent (radians); complex-aware when NumericSwift is present |
| `np.arcsin(a)` / `np.asin(a)` | Inverse sine |
| `np.arccos(a)` / `np.acos(a)` | Inverse cosine |
| `np.arctan(a)` / `np.atan(a)` | Inverse tangent |
| `np.arctan2(y, x)` / `np.atan2(y, x)` | Two-argument inverse tangent |

```lua
local t = np.linspace(0, 2 * math.pi, 5)
print(np.sin(t):tolist())   -- approximately {0, 1, 0, -1, 0}
```

#### Hyperbolic

| Function | Description |
|----------|-------------|
| `np.sinh(a)` | Hyperbolic sine; complex-aware when NumericSwift is present |
| `np.cosh(a)` | Hyperbolic cosine; complex-aware when NumericSwift is present |
| `np.tanh(a)` | Hyperbolic tangent; complex-aware when NumericSwift is present |
| `np.asinh(a)` | Inverse hyperbolic sine |
| `np.acosh(a)` | Inverse hyperbolic cosine |
| `np.atanh(a)` | Inverse hyperbolic tangent |

#### Rounding and Sign

| Function | Description |
|----------|-------------|
| `np.floor(a)` | Floor (toward negative infinity) |
| `np.ceil(a)` | Ceiling (toward positive infinity) |
| `np.round(a)` | Round to nearest integer |
| `np.sign(a)` | Sign: `-1`, `0`, or `1` |
| `np.clip(a, min_val, max_val)` | Clamp elements to `[min_val, max_val]` |
| `np.mod(a, b)` | Modulo (floor division remainder) |
| `np.fmod(a, b)` | Floating-point remainder (C-style `fmod`) |

```lua
local a = np.array({-1.7, 0.3, 2.9})
print(np.floor(a):tolist())  -- {-2, 0, 2}
print(np.ceil(a):tolist())   -- {-1, 1, 3}
print(np.round(a):tolist())  -- {-2, 0, 3}
print(np.clip(a, -1, 1):tolist())  -- {-1, 0.3, 1}
```

### Reduction Operations

All reductions accept an optional `axis` parameter. When omitted, the reduction is over the entire array. When provided (1-based), the specified dimension is collapsed.

For a 2D array with shape `{R, C}`:
- `axis=1` collapses the first dimension (rows), giving a result with `C` elements
- `axis=2` collapses the second dimension (columns), giving a result with `R` elements

#### np.sum(a, axis?)

```lua
local a = np.array({{1, 2, 3}, {4, 5, 6}})   -- shape {2, 3}

print(np.sum(a))       -- 21  (all elements)
print(np.sum(a, 1):tolist())  -- {5, 7, 9}  (row axis collapsed → one sum per column)
print(np.sum(a, 2):tolist())  -- {6, 15}    (column axis collapsed → one sum per row)
```

#### np.mean(a, axis?)

```lua
print(np.mean(a))      -- 3.5
```

#### np.std(a, axis?)

Population standard deviation.

```lua
print(np.std(a))       -- ~1.71
```

#### np.var(a, axis?)

Population variance.

```lua
print(np.var(a))       -- ~2.92
```

#### np.min(a, axis?)  /  np.max(a, axis?)

```lua
print(np.min(a))   -- 1
print(np.max(a))   -- 6
```

#### np.argmin(a, axis?)  /  np.argmax(a, axis?)

Returns the 1-based flat index of the minimum or maximum. With `axis`, returns an array of 1-based indices.

```lua
local a = np.array({3, 1, 4, 1, 5})
print(np.argmin(a))    -- 2  (first minimum at 1-based index 2)
print(np.argmax(a))    -- 5
```

#### np.argmin_array(a)  /  np.argmax_array(a)

Returns an `int64` array of 1-based indices (axis-wise argmin/argmax over all axes).

```lua
local idx = np.argmax_array(a)   -- int64 array
```

#### np.prod(a, axis?)

Product of elements.

```lua
local a = np.array({1, 2, 3, 4})
print(np.prod(a))   -- 24
```

#### np.cumsum(a, axis?)  /  np.cumprod(a, axis?)

Cumulative sum or product.

```lua
local a = np.array({1, 2, 3, 4})
print(np.cumsum(a):tolist())   -- {1, 3, 6, 10}
print(np.cumprod(a):tolist())  -- {1, 2, 6, 24}
```

#### np.all(a, axis?)  /  np.any(a, axis?)

Boolean reductions: true if all (or any) elements are non-zero.

```lua
local a = np.array({1, 1, 0})
print(np.all(a))   -- 0 (false)
print(np.any(a))   -- 1 (true)
```

#### np.ptp(a, axis?)

Peak-to-peak (max − min).

```lua
local a = np.array({1, 5, 2, 8})
print(np.ptp(a))   -- 7
```

### Statistics

#### np.median(a, axis?)

```lua
local a = np.array({3, 1, 4, 1, 5, 9})
print(np.median(a))    -- 3.5
```

#### np.percentile(a, q, axis?)

Returns the `q`-th percentile (0–100).

```lua
print(np.percentile(a, 75))   -- 75th percentile
```

#### np.quantile(a, q, axis?)

Same as `percentile` with `q` in `[0, 1]` instead of `[0, 100]`.

```lua
print(np.quantile(a, 0.75))
```

#### np.histogram(a, bins?, range?)

Returns two arrays: `counts`, `edges`.

```lua
local data = np.random.randn({1000})
local counts, edges = np.histogram(data, 20)
```

#### np.bincount(a, weights?, minlength?)

Counts occurrences of non-negative integers.

```lua
local a = np.array({0, 1, 1, 2, 3, 0})
print(np.bincount(a):tolist())   -- {2, 2, 1, 1}
```

### Comparison Operations

All comparison functions return a float64 array with `1.0` for true and `0.0` for false.

| Function | Description |
|----------|-------------|
| `np.equal(a, b)` | Element-wise `a == b` |
| `np.not_equal(a, b)` | Element-wise `a ~= b` |
| `np.greater(a, b)` | Element-wise `a > b` |
| `np.greater_equal(a, b)` | Element-wise `a >= b` |
| `np.less(a, b)` | Element-wise `a < b` |
| `np.less_equal(a, b)` | Element-wise `a <= b` |
| `np.isnan(a)` | Element-wise NaN test |
| `np.isinf(a)` | Element-wise infinity test |
| `np.isfinite(a)` | Element-wise finiteness test |

```lua
local a = np.array({1, 2, 3})
local b = np.array({1, 0, 3})
print(np.equal(a, b):tolist())    -- {1, 0, 1}
print(np.greater(a, b):tolist())  -- {0, 1, 0}
```

#### np.where(condition, x, y)

Selects elements from `x` where `condition` is non-zero, else from `y`.

```lua
local a    = np.array({1, 2, 3, 4, 5})
local mask = np.greater(a, 3)
local b    = np.where(mask, a, 0)   -- {0, 0, 0, 4, 5}
```

### Boolean Logical Operations

These work with any array; non-zero values are treated as true.

```lua
local a = np.greater(x, 0)
local b = np.less(x, 10)

local in_range = np.logical_and(a, b)
local outside  = np.logical_or(np.less_equal(x, 0), np.greater_equal(x, 10))
local inverted = np.logical_not(in_range)
local differs  = np.logical_xor(a, b)
```

Method forms are also available: `a:logical_and(b)`, `a:logical_or(b)`, `a:logical_xor(b)`, `a:logical_not()`.

### Sorting and Searching

#### np.sort(a, axis?)

Returns a sorted copy.

```lua
local a = np.array({3, 1, 4, 1, 5, 9})
print(np.sort(a):tolist())   -- {1, 1, 3, 4, 5, 9}
```

#### np.argsort(a)

Returns an `int64` array of 1-based indices that would sort `a`.

```lua
local idx = np.argsort(a)   -- int64 NDArray
```

#### np.searchsorted(a, v, side?)

Finds insertion points for `v` in sorted array `a`. `side` is `"left"` (default) or `"right"`.

```lua
local a = np.array({1, 2, 4, 7})
print(np.searchsorted(a, 3))   -- 3 (insert before index 3)
```

#### np.argwhere(a)

Returns indices where `a` is non-zero (2D array: each row is one index set).

```lua
local a = np.array({0, 1, 0, 2})
print(np.argwhere(a):tolist())   -- {{2}, {4}}
```

#### np.nonzero(a)

Returns a Lua table of arrays, one per dimension, containing 1-based indices of non-zero elements.

```lua
local a = np.array({{0, 1}, {2, 0}})
local rows, cols = table.unpack(np.nonzero(a))
```

#### np.unique(a, return_index?, return_inverse?, return_counts?)

Returns sorted unique elements. Optional extra return values (1-based indices, inverse map, counts).

```lua
local a = np.array({3, 1, 4, 1, 5, 3})
local u = np.unique(a)
print(u:tolist())   -- {1, 3, 4, 5}

local vals, idx, inv, cnt = np.unique(a, true, true, true)
```

### Linear Algebra

#### np.dot(a, b)  /  a:dot(b)

Matrix multiplication or vector dot product.

```lua
-- Vector dot product (scalar result)
local u = np.array({1, 2, 3})
local v = np.array({4, 5, 6})
print(np.dot(u, v))   -- 32

-- Matrix multiplication
local A = np.array({{1, 2}, {3, 4}})
local B = np.array({{5, 6}, {7, 8}})
local C = np.dot(A, B)   -- {{19, 22}, {43, 50}}
```

#### np.matmul(a, b)

Alias for `np.dot`.

#### np.outer(a, b)

Outer product of two 1D arrays.

```lua
local a = np.array({1, 2, 3})
local b = np.array({0, 1, 0})
local M = np.outer(a, b)   -- shape {3, 3}
```

#### np.trace(a, offset?)

Sum of diagonal elements. `offset` shifts the diagonal (positive = superdiagonal).

```lua
local a = np.array({{1, 2}, {3, 4}})
print(np.trace(a))   -- 5
```

#### np.diagonal(a, offset?)

Extracts the diagonal as a 1D array.

```lua
local d = np.diagonal(a)
print(d:tolist())   -- {1, 4}
```

#### np.diag(a, k?)

If `a` is 1D, creates a 2D diagonal matrix. If `a` is 2D, extracts the `k`-th diagonal.

```lua
local d = np.diag(np.array({1, 2, 3}))   -- 3x3 diagonal matrix
```

### Array Manipulation

#### np.concatenate(arrays, axis?)

Joins arrays along an existing axis (default axis 1).

```lua
local a = np.array({{1, 2}, {3, 4}})
local b = np.array({{5, 6}, {7, 8}})
local c = np.concatenate({a, b}, 1)   -- shape {4, 2}
local d = np.concatenate({a, b}, 2)   -- shape {2, 4}
```

#### np.vstack(arrays)

Stacks arrays vertically (along axis 1). Equivalent to `np.concatenate(arrays, 1)`.

```lua
local c = np.vstack({a, b})   -- shape {4, 2}
```

#### np.hstack(arrays)

Stacks arrays horizontally (along axis 2). Equivalent to `np.concatenate(arrays, 2)`.

```lua
local c = np.hstack({a, b})   -- shape {2, 4}
```

#### np.stack(arrays, axis?)

Joins arrays along a **new** axis.

```lua
local a = np.array({1, 2, 3})
local b = np.array({4, 5, 6})
local c = np.stack({a, b}, 1)   -- shape {2, 3}
```

#### np.split(a, indices_or_sections, axis?)

Splits an array into sub-arrays. Returns a Lua table of arrays.

```lua
local a = np.array({1, 2, 3, 4, 5, 6})
local parts = np.split(a, 3)   -- three arrays of 2 elements
```

#### np.vsplit(a, indices_or_sections)

Splits along axis 1.

#### np.hsplit(a, indices_or_sections)

Splits along axis 2.

#### np.tile(a, reps)

Tiles array `a` by repeating it according to `reps` (Lua table).

```lua
local a = np.array({1, 2, 3})
local b = np.tile(a, {2})   -- {1, 2, 3, 1, 2, 3}
```

#### np.rep(a, repeats, axis?)

Repeats elements of `a`. `repeats` is an integer or array.

> Note: `repeat` is a reserved Lua keyword; the function is named `rep`.

```lua
local a = np.array({1, 2, 3})
local b = np.rep(a, 2)   -- {1, 1, 2, 2, 3, 3}
```

#### np.flip(a, axis?)

Reverses element order along `axis` (or all axes if omitted).

```lua
local a = np.array({1, 2, 3, 4})
print(np.flip(a):tolist())   -- {4, 3, 2, 1}
```

#### np.roll(a, shift, axis?)

Rolls elements by `shift` positions.

```lua
local a = np.array({1, 2, 3, 4, 5})
print(np.roll(a, 2):tolist())   -- {4, 5, 1, 2, 3}
```

#### np.pad(a, pad_width, mode?, constant_value?)

Pads an array. `pad_width` is a Lua table of `{before, after}` pairs per dimension.

```lua
local a = np.array({1, 2, 3})
local b = np.pad(a, {{2, 2}})   -- {0, 0, 1, 2, 3, 0, 0}
```

#### np.insert(a, indices, values, axis?)

Inserts `values` into `a` before `indices`.

```lua
local a = np.array({1, 2, 4, 5})
local b = np.insert(a, 3, np.array({3}))   -- {1, 2, 3, 4, 5}
```

#### np.delete(a, indices, axis?)

Removes elements at `indices`.

```lua
local a = np.array({1, 2, 3, 4, 5})
local b = np.delete(a, {2, 4})   -- {1, 3, 5}
```

#### np.diff(a, n?, axis?)

Discrete difference (1st differences by default, `n`-th differences supported).

```lua
local a = np.array({1, 3, 6, 10})
print(np.diff(a):tolist())   -- {2, 3, 4}
```

### Signal Processing

#### np.correlate(a, v, mode?)

Cross-correlation of two 1D arrays. `mode`: `"full"`, `"valid"` (default), or `"same"`.

```lua
local signal  = np.array({1, 2, 3, 2, 1})
local kernel  = np.array({1, 0, -1})
local out = np.correlate(signal, kernel, "same")
```

#### np.convolve(a, v, mode?)

Convolution of two 1D arrays. Same `mode` options as `correlate`.

```lua
local out = np.convolve(np.array({1, 2, 3}), np.array({1, 1}))
print(out:tolist())   -- {1, 3, 5, 3}
```

#### np.gradient(a, spacing?, axis?)

Approximates the gradient using central differences. Without `axis`, returns one array per dimension as multiple return values.

```lua
local a = np.array({1, 4, 9, 16, 25})
local g = np.gradient(a)
print(g:tolist())   -- {3, 4, 6, 8, 9}
```

#### np.interp(x, xp, fp, left?, right?)

1D linear interpolation of `fp` at `xp` sampled at positions `x`. `left`/`right` are fill values for out-of-range `x`.

```lua
local xp = np.array({0, 1, 2, 3})
local fp = np.array({0, 1, 4, 9})
local x  = np.array({0.5, 1.5, 2.5})
print(np.interp(x, xp, fp):tolist())   -- {0.5, 2.5, 6.5}
```

### FFT

FFT functions live in the `np.fft` sub-table. All FFT functions require `complex128` input except `rfft`, which requires `float64`.

```lua
local np = require("luaswift.array")

-- Forward 1D FFT
local t     = np.linspace(0, 1, 64)
local sig   = np.sin(t * 2 * math.pi * 5)
local z     = np.complex_array(sig, np.zeros({64}))
local Z     = np.fft.fft(z)       -- complex128 result

-- Inverse FFT
local sig2  = np.fft.ifft(Z)

-- Real FFT (float64 input, complex128 output)
local Zr    = np.fft.rfft(sig)

-- 2D FFT
local img   = np.complex_array(np.random.rand({8, 8}), np.zeros({8, 8}))
local IMG   = np.fft.fft2(img)
local img2  = np.fft.ifft2(IMG)

-- N-D FFT
local Zn    = np.fft.fftn(z)
local zn    = np.fft.ifftn(Zn)

-- Frequency bins
local freq  = np.fft.fftfreq(64, 1/64)   -- n samples, sample spacing d
```

| Function | Description |
|----------|-------------|
| `np.fft.fft(a)` | 1D forward FFT (complex128 input) |
| `np.fft.ifft(a)` | 1D inverse FFT (complex128 input) |
| `np.fft.rfft(a)` | 1D FFT for real (float64) input |
| `np.fft.fft2(a)` | 2D forward FFT |
| `np.fft.ifft2(a)` | 2D inverse FFT |
| `np.fft.fftn(a)` | N-D forward FFT |
| `np.fft.ifftn(a)` | N-D inverse FFT |
| `np.fft.fftfreq(n, d?)` | Frequency bins for `n` samples with spacing `d` (default 1.0) |

### Set Operations

All set operations work on 1D arrays and return sorted unique results.

| Function | Description |
|----------|-------------|
| `np.intersect1d(a, b)` | Sorted intersection |
| `np.union1d(a, b)` | Sorted union |
| `np.setdiff1d(a, b)` | Elements in `a` not in `b` |
| `np.setxor1d(a, b)` | Elements in one but not both |
| `np.in1d(a, b)` | Boolean array: is each element of `a` in `b`? |

```lua
local a = np.array({1, 2, 3, 4})
local b = np.array({3, 4, 5, 6})
print(np.intersect1d(a, b):tolist())  -- {3, 4}
print(np.union1d(a, b):tolist())      -- {1, 2, 3, 4, 5, 6}
print(np.setdiff1d(a, b):tolist())    -- {1, 2}
print(np.in1d(a, b):tolist())         -- {0, 0, 1, 1}
```

### Utility Functions

#### a:tolist()

Converts array to nested Lua tables.

```lua
local a = np.array({{1, 2}, {3, 4}})
local t = a:tolist()    -- {{1, 2}, {3, 4}}
```

#### a:copy()

Creates a deep copy of the array.

```lua
local b = a:copy()
b:set(1, 1, 99)   -- does not affect a
```

## Broadcasting

Operations between arrays of different shapes use NumPy-compatible broadcasting rules:

1. If arrays differ in number of dimensions, the smaller is padded with 1s on the left.
2. Two dimensions are compatible if they are equal or one of them is 1.
3. The output shape is the maximum along each dimension.

```lua
-- Scalar broadcast
local a = np.array({{1, 2, 3}, {4, 5, 6}})   -- shape {2, 3}
local b = a + 10                              -- shape {2, 3}

-- Row broadcast
local row = np.array({1, 2, 3})               -- shape {3}
local c = a + row                             -- shape {2, 3}

-- Column broadcast
local col = np.array({{10}, {20}})            -- shape {2, 1}
local d = a + col                             -- {{11, 12, 13}, {24, 25, 26}}
```

## Common Patterns

### Data Normalization

```lua
local np   = require("luaswift.array")
local data = np.array({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})

-- Z-score normalization
local normalized = (data - np.mean(data)) / np.std(data)

-- Min-max normalization to [0, 1]
local scaled = (data - np.min(data)) / (np.max(data) - np.min(data))
```

### Statistical Analysis

```lua
local np      = require("luaswift.array")
local samples = np.random.randn({1000})

print("Mean:",   np.mean(samples))
print("Std:",    np.std(samples))
print("Median:", np.median(samples))
print("P95:",    np.percentile(samples, 95))
```

### Signal Processing

```lua
local np = require("luaswift.array")

-- Generate and convolve a sine wave with a box filter
local t      = np.linspace(0, 2 * math.pi, 128)
local signal = np.sin(t)
local box    = np.full({5}, 0.2)          -- 5-tap mean filter
local smooth = np.convolve(signal, box, "same")

-- Compute gradient
local g = np.gradient(signal)
```

### Working with Complex Arrays

```lua
local np = require("luaswift.array")

-- Build a complex signal
local t   = np.linspace(0, 1, 64)
local re  = np.cos(t * 2 * math.pi * 5)
local im  = np.sin(t * 2 * math.pi * 5)
local z   = np.complex_array(re, im)

-- FFT
local Z = np.fft.fft(z)
print(np.abs(Z):tolist())   -- magnitude spectrum

-- Round-trip
local z2 = np.fft.ifft(Z)
print(z2:real():tolist())   -- should match re
```

## Performance Notes

- Uses Apple's Accelerate framework (BLAS/vDSP) for SIMD-optimized operations.
- All storage is double-precision (`float64`) unless a dtype is specified.
- Broadcasting creates temporary arrays; prefer matching shapes in tight loops.
- Axis reductions are iterative; full reductions use accelerated vDSP routines.
- For high-concurrency workloads, use separate `LuaEngine` instances rather than sharing one.

## See Also

- ``ArrayModule``
- ``LinAlgModule``
- ``MathXModule``
- ``DistributionsModule``
