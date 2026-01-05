# Array Module

NumPy-like N-dimensional arrays with hardware-accelerated operations.

## Overview

The Array module provides NumPy-style N-dimensional array operations with efficient storage and hardware acceleration via Apple's Accelerate framework. It supports broadcasting, element-wise operations, reductions, and reshaping.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the Array module
ModuleRegistry.installArrayModule(in: engine)
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
local d = c * 2         -- Scalar multiplication
local e = c + np.ones({2, 3})  -- Array addition

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
-- 1D array
local a = np.array({1, 2, 3, 4, 5})

-- 2D array
local b = np.array({{1, 2, 3}, {4, 5, 6}})

-- 3D array
local c = np.array({{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}})
```

#### zeros(shape)
Creates an array filled with zeros.

```lua
local a = np.zeros({3})         -- 1D: {0, 0, 0}
local b = np.zeros({2, 3})      -- 2D: 2x3 matrix of zeros
local c = np.zeros({2, 3, 4})   -- 3D: 2x3x4 tensor of zeros
```

#### ones(shape)
Creates an array filled with ones.

```lua
local a = np.ones({4})          -- {1, 1, 1, 1}
local b = np.ones({3, 3})       -- 3x3 matrix of ones
```

#### full(shape, value)
Creates an array filled with a specific value.

```lua
local a = np.full({3}, 7)       -- {7, 7, 7}
local b = np.full({2, 2}, -1)   -- 2x2 matrix of -1s
```

#### arange(start, stop, step?)
Creates a 1D array with evenly spaced values in a range (stop exclusive).

```lua
local a = np.arange(0, 5, 1)    -- {0, 1, 2, 3, 4}
local b = np.arange(0, 10, 2)   -- {0, 2, 4, 6, 8}
local c = np.arange(5, 0, -1)   -- {5, 4, 3, 2, 1}
```

#### linspace(start, stop, num?)
Creates a 1D array with `num` evenly spaced values (default 50, stop inclusive).

```lua
local a = np.linspace(0, 1, 5)      -- {0, 0.25, 0.5, 0.75, 1}
local b = np.linspace(0, 10, 11)    -- {0, 1, 2, ..., 10}
```

### Random Arrays

#### random.rand(shape)
Creates an array of uniform random values in [0, 1).

```lua
local a = np.random.rand({3})       -- 1D with 3 random values
local b = np.random.rand({2, 3})    -- 2x3 random matrix
```

#### random.randn(shape)
Creates an array of normally distributed random values (mean=0, std=1).

```lua
local a = np.random.randn({1000})   -- 1000 samples from N(0,1)
local b = np.random.randn({10, 10}) -- 10x10 random matrix
```

### Properties

#### a:shape()
Returns the array dimensions as a table.

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

### Element Access

#### a:get(i, j, ...)
Gets an element by index. Indices are 1-based.

```lua
local a = np.array({{1, 2, 3}, {4, 5, 6}})
print(a:get(1, 2))    -- 2
print(a:get(2, 3))    -- 6
```

#### a:set(i, j, ..., value)
Sets an element by index. Returns the modified array.

```lua
local a = np.array({{1, 2}, {3, 4}})
a:set(1, 1, 99)
print(a:get(1, 1))    -- 99
```

### Reshaping Operations

#### a:reshape(new_shape)
Returns an array with the same data but different shape.

```lua
local a = np.array({1, 2, 3, 4, 5, 6})
local b = a:reshape({2, 3})
print(b:shape())    -- {2, 3}
```

#### a:flatten()
Returns a 1D array with all elements.

```lua
local a = np.array({{1, 2}, {3, 4}})
local b = a:flatten()
print(b:shape())    -- {4}
print(b:tolist())   -- {1, 2, 3, 4}
```

#### a:squeeze()
Removes dimensions of size 1.

```lua
local a = np.array({{{1, 2, 3}}})  -- shape: {1, 1, 3}
local b = a:squeeze()
print(b:shape())    -- {3}
```

#### a:expand_dims(axis)
Adds a dimension of size 1 at the specified axis.

```lua
local a = np.array({1, 2, 3})      -- shape: {3}
local b = a:expand_dims(1)
print(b:shape())    -- {1, 3}
```

#### a:T() / a:transpose(axes?)
Returns the transposed array. For 2D, swaps rows and columns.

```lua
local a = np.array({{1, 2, 3}, {4, 5, 6}})
local b = a:T()
print(b:shape())    -- {3, 2}
```

### Arithmetic Operations

Arrays support standard operators with broadcasting:

#### Addition (+)
```lua
local a = np.array({1, 2, 3})
local b = np.array({4, 5, 6})
local c = a + b         -- {5, 7, 9}
local d = a + 10        -- {11, 12, 13}
```

#### Subtraction (-)
```lua
local c = b - a         -- {3, 3, 3}
```

#### Multiplication (*)
```lua
local c = a * b         -- {4, 10, 18} (element-wise)
local d = a * 2         -- {2, 4, 6}
```

#### Division (/)
```lua
local c = b / a         -- {4, 2.5, 2}
local d = a / 2         -- {0.5, 1, 1.5}
```

#### Power (^)
```lua
local c = a ^ 2         -- {1, 4, 9}
local d = a ^ b         -- {1, 32, 729}
```

#### Negation (-)
```lua
local c = -a            -- {-1, -2, -3}
```

### Math Functions

Element-wise mathematical functions:

#### np.abs(a)
```lua
local a = np.array({-1, 2, -3})
local b = np.abs(a)     -- {1, 2, 3}
```

#### np.sqrt(a)
```lua
local a = np.array({1, 4, 9})
local b = np.sqrt(a)    -- {1, 2, 3}
```

#### np.exp(a)
```lua
local a = np.array({0, 1, 2})
local b = np.exp(a)     -- {1, e, e^2}
```

#### np.log(a)
Natural logarithm.

```lua
local a = np.array({1, math.exp(1), math.exp(2)})
local b = np.log(a)     -- {0, 1, 2}
```

#### np.sin(a), np.cos(a), np.tan(a)
Trigonometric functions (input in radians).

```lua
local a = np.array({0, math.pi/2, math.pi})
local b = np.sin(a)     -- {0, 1, 0}
local c = np.cos(a)     -- {1, 0, -1}
```

### Reduction Operations

All reductions can operate on the entire array or along a specific axis.

#### np.sum(a, axis?)
```lua
local a = np.array({{1, 2, 3}, {4, 5, 6}})

print(np.sum(a))         -- 21 (total)
print(np.sum(a, 1))      -- array({5, 7, 9}) (sum along rows)
print(np.sum(a, 2))      -- array({6, 15}) (sum along columns)
```

#### np.mean(a, axis?)
```lua
print(np.mean(a))        -- 3.5 (average)
```

#### np.std(a, axis?)
Population standard deviation.

```lua
print(np.std(a))         -- ~1.71
```

#### np.var(a, axis?)
Population variance.

```lua
print(np.var(a))         -- ~2.92
```

#### np.min(a, axis?) / np.max(a, axis?)
```lua
print(np.min(a))         -- 1
print(np.max(a))         -- 6
```

#### np.argmin(a, axis?) / np.argmax(a, axis?)
Returns 1-based index of minimum/maximum.

```lua
local a = np.array({3, 1, 4, 1, 5})
print(np.argmin(a))      -- 2 (first occurrence)
print(np.argmax(a))      -- 5
```

#### np.prod(a, axis?)
Product of elements.

```lua
local a = np.array({1, 2, 3, 4})
print(np.prod(a))        -- 24
```

### Comparison Operations

#### np.equal(a, b)
Element-wise equality (returns 1.0 for true, 0.0 for false).

```lua
local a = np.array({1, 2, 3})
local b = np.array({1, 0, 3})
local c = np.equal(a, b)    -- {1, 0, 1}
```

#### np.greater(a, b)
Element-wise greater than.

```lua
local c = np.greater(a, b)  -- {0, 1, 0}
```

#### np.less(a, b)
Element-wise less than.

```lua
local c = np.less(a, b)     -- {0, 0, 0}
```

#### np.where(condition, x, y)
Returns elements from x where condition is true, else from y.

```lua
local a = np.array({1, 2, 3, 4, 5})
local mask = np.greater(a, 3)
local b = np.where(mask, a, 0)    -- {0, 0, 0, 4, 5}
```

### Linear Algebra

#### np.dot(a, b) / a:dot(b)
Matrix multiplication or vector dot product.

```lua
-- Vector dot product (returns scalar)
local u = np.array({1, 2, 3})
local v = np.array({4, 5, 6})
print(np.dot(u, v))         -- 32

-- Matrix multiplication
local A = np.array({{1, 2}, {3, 4}})
local B = np.array({{5, 6}, {7, 8}})
local C = np.dot(A, B)      -- {{19, 22}, {43, 50}}

-- Matrix-vector multiplication
local x = np.array({1, 2})
local y = np.dot(A, x)      -- {5, 11}
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
```

## Broadcasting

Operations between arrays of different shapes use broadcasting rules (similar to NumPy):

1. If arrays have different dimensions, the smaller is padded with 1s on the left
2. Dimensions are compatible if they're equal or one of them is 1
3. The result shape is the maximum along each dimension

```lua
-- Scalar broadcast
local a = np.array({{1, 2, 3}, {4, 5, 6}})  -- shape: {2, 3}
local b = a + 10                             -- shape: {2, 3}

-- Row broadcast
local row = np.array({1, 2, 3})              -- shape: {3}
local c = a + row                            -- shape: {2, 3}

-- Column broadcast
local col = np.array({{10}, {20}})           -- shape: {2, 1}
local d = a + col                            -- shape: {2, 3}
-- Result: {{11, 12, 13}, {24, 25, 26}}
```

## Common Patterns

### Data Normalization

```lua
local data = np.array({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}})

-- Z-score normalization
local mean = np.mean(data)
local std = np.std(data)
local normalized = (data - mean) / std

-- Min-max normalization to [0, 1]
local min_val = np.min(data)
local max_val = np.max(data)
local scaled = (data - min_val) / (max_val - min_val)
```

### Statistical Analysis

```lua
local samples = np.random.randn({1000})

print("Mean:", np.mean(samples))
print("Std:", np.std(samples))
print("Min:", np.min(samples))
print("Max:", np.max(samples))
```

### Signal Processing

```lua
local np = require("luaswift.array")

-- Generate a sine wave
local t = np.linspace(0, 2 * math.pi, 100)
local signal = np.sin(t)

-- Add noise
local noise = np.random.randn({100}) * 0.1
local noisy = signal + noise
```

### Image-like Operations

```lua
-- Create a grayscale "image" (2D array)
local img = np.random.rand({10, 10})

-- Threshold
local mask = np.greater(img, 0.5)
local binary = np.where(mask, 1, 0)

-- Compute row and column means
local row_means = np.mean(img, 2)
local col_means = np.mean(img, 1)
```

## Performance Notes

- Uses Apple's Accelerate framework for SIMD-optimized operations
- Operations are performed in double precision
- Broadcasting creates temporary arrays; for performance-critical code, prefer matching shapes
- Reduction operations along axes are less optimized than full reductions

## See Also

- ``ArrayModule``
- ``LinAlgModule``
- ``MathXModule``
