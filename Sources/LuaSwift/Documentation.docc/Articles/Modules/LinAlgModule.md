# LinAlg Module

Hardware-accelerated linear algebra operations for vectors and matrices.

> Important: This module requires the `NumericSwift` optional dependency. It is **opt-in and disabled by default**. Enable it at build time with `LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build`. Without that flag the module is not compiled and `require("luaswift.linalg")` will fail at runtime.

## Overview

The LinAlg module provides comprehensive linear algebra functionality using Apple's Accelerate framework for optimal performance. It supports vector and matrix creation, arithmetic operations, matrix decompositions, linear system solvers, matrix functions, and complex-matrix operations.

## Installation

```swift
// Install all modules
try ModuleRegistry.install(in: engine)

// Or install just the LinAlg module
try LinAlgModule.install(in: engine)
```

Build with NumericSwift enabled:

```bash
LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build
```

## Basic Usage

```lua
local linalg = require("luaswift.linalg")

-- Create vectors
local v = linalg.vector({1, 2, 3, 4})
local u = linalg.ones(4)

-- Vector operations
local sum = v + u
local d   = v:dot(u)     -- scalar dot product
print(v:norm())           -- Euclidean norm (L2)

-- Create matrices
local A = linalg.matrix({{1, 2}, {3, 4}})
local I = linalg.eye(2)

-- Matrix operations
local B    = A + I
local C    = A:dot(A)    -- matrix multiplication
print(A:det())            -- determinant
local Ainv = A:inv()      -- inverse
```

## API Reference

### Vector Creation

#### vector(array)
Creates a column vector from a 1-D array of numbers.

```lua
local v = linalg.vector({1, 2, 3, 4, 5})
print(v:size())    -- 5
print(v:get(1))    -- 1
```

#### zeros(n)
Creates a vector of zeros with `n` elements. When called with two arguments, creates a matrix (see Matrix Creation).

```lua
local v = linalg.zeros(5)
print(v:toarray())    -- {0, 0, 0, 0, 0}
```

#### ones(n)
Creates a vector of ones with `n` elements. When called with two arguments, creates a matrix.

```lua
local v = linalg.ones(3)
print(v:toarray())    -- {1, 1, 1}
```

#### range(start, stop, step?)
Creates a vector with values from `start` up to (but not including) `stop`, with optional `step` (default 1).

```lua
local v = linalg.range(0, 10, 2)
print(v:toarray())    -- {0, 2, 4, 6, 8}

local w = linalg.range(5, 0, -1)
print(w:toarray())    -- {5, 4, 3, 2, 1}
```

#### linspace(start, stop, n)
Creates a vector with `n` evenly spaced values from `start` to `stop` (inclusive). `n` must be at least 2.

```lua
local v = linalg.linspace(0, 1, 5)
print(v:toarray())    -- {0, 0.25, 0.5, 0.75, 1}
```

### Matrix Creation

#### matrix(array)
Creates a matrix from a 2-D array (array of row arrays). All rows must have the same length.

```lua
local A = linalg.matrix({
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9}
})
print(A:rows(), A:cols())    -- 3  3
```

#### zeros(rows, cols)
Creates a matrix of zeros with the specified dimensions.

```lua
local A = linalg.zeros(3, 4)
print(A:shape())    -- {3, 4}
```

#### ones(rows, cols)
Creates a matrix of ones with the specified dimensions.

```lua
local A = linalg.ones(2, 3)
```

#### eye(n)
Creates an n×n identity matrix.

```lua
local I = linalg.eye(3)
-- [[1, 0, 0],
--  [0, 1, 0],
--  [0, 0, 1]]
```

#### diagonal(array) / diag(array)
Creates a diagonal matrix from a 1-D array of values. `diagonal` is the canonical name; `diag` is a legacy alias.

```lua
local D = linalg.diagonal({1, 2, 3})
-- [[1, 0, 0],
--  [0, 2, 0],
--  [0, 0, 3]]

local D2 = linalg.diag({4, 5})    -- legacy alias, identical behaviour
```

### Properties and Access

#### m:rows()
Returns the number of rows.

```lua
local A = linalg.matrix({{1,2},{3,4},{5,6}})
print(A:rows())    -- 3
```

#### m:cols()
Returns the number of columns.

```lua
print(A:cols())    -- 2
```

#### m:shape()
Returns the dimensions as a Lua array. Vectors return a 1-element array; matrices return a 2-element array.

```lua
print(A:shape())               -- {3, 2}
local v = linalg.vector({1,2,3})
print(v:shape())               -- {3}
```

#### m:size()
Returns the total number of elements.

```lua
print(A:size())    -- 6
```

#### m:get(i, j) / v:get(i)
Returns the element at row `i`, column `j` for matrices, or element `i` for vectors. Indices are 1-based.

```lua
local A = linalg.matrix({{1,2},{3,4}})
print(A:get(1, 2))    -- 2

local v = linalg.vector({10, 20, 30})
print(v:get(2))       -- 20
```

#### m:set(i, j, value) / v:set(i, value)
Sets the element at the specified position and returns the modified object.

```lua
local A = linalg.matrix({{1,2},{3,4}})
A:set(1, 2, 99)
print(A:get(1, 2))    -- 99
```

#### m:row(i)
Returns the `i`-th row as a vector (1-based).

```lua
local A = linalg.matrix({{1,2,3},{4,5,6}})
local r = A:row(1)
print(r:toarray())    -- {1, 2, 3}
```

#### m:col(j)
Returns the `j`-th column as a vector (1-based).

```lua
local c = A:col(2)
print(c:toarray())    -- {2, 5}
```

#### m:transpose() / m:T()
Returns the transpose. Both names are equivalent.

```lua
local A  = linalg.matrix({{1,2},{3,4}})
local At = A:transpose()    -- or A:T()
```

#### m:toarray()
Converts to a plain Lua array. Vectors return a 1-D array; matrices return an array of row arrays.

```lua
local A   = linalg.matrix({{1,2},{3,4}})
local arr = A:toarray()    -- {{1, 2}, {3, 4}}

local v    = linalg.vector({1, 2, 3})
local varr = v:toarray()   -- {1, 2, 3}
```

### Arithmetic Operations

Matrices and vectors support standard arithmetic operators.

#### Addition (+)
```lua
local A = linalg.matrix({{1,2},{3,4}})
local B = linalg.matrix({{5,6},{7,8}})
local C = A + B    -- {{6,8},{10,12}}
```

#### Subtraction (-)
```lua
local C = A - B    -- {{-4,-4},{-4,-4}}
```

#### Scalar Multiplication (*)
The `*` operator performs scalar multiplication when one operand is a number, and matrix multiplication when both operands are matrices or vectors.

```lua
local C = A * 2    -- scalar: {{2,4},{6,8}}
local D = 3 * A    -- scalar: {{3,6},{9,12}}
local E = A * B    -- matrix multiply (same as A:dot(B))
```

#### Scalar Division (/)
Divides every element by a scalar. The divisor must be a number; division by zero raises an error.

```lua
local C = A / 2    -- {{0.5,1},{1.5,2}}
```

#### Negation (unary -)
```lua
local C = -A       -- {{-1,-2},{-3,-4}}
```

#### m:dot(other)
Matrix multiplication or vector dot product.

```lua
-- Matrix multiplication
local A = linalg.matrix({{1,2},{3,4}})
local B = linalg.matrix({{5,6},{7,8}})
local C = A:dot(B)    -- {{19,22},{43,50}}

-- Matrix-vector multiplication
local v = linalg.vector({1, 2})
local w = A:dot(v)    -- vector {5, 11}

-- Vector dot product (returns scalar)
local u = linalg.vector({1, 2, 3})
local v = linalg.vector({4, 5, 6})
local d = u:dot(v)    -- 32
```

#### m:hadamard(other)
Element-wise (Hadamard) product. Both operands must have identical dimensions.

```lua
local A = linalg.matrix({{1,2},{3,4}})
local B = linalg.matrix({{5,6},{7,8}})
local C = A:hadamard(B)    -- {{5,12},{21,32}}
```

### Linear Algebra Operations

#### m:det()
Determinant of a square matrix.

```lua
local A = linalg.matrix({{1,2},{3,4}})
print(A:det())    -- -2
```

#### m:inv()
Inverse of a square matrix. Raises an error if the matrix is singular.

```lua
local A    = linalg.matrix({{1,2},{3,4}})
local Ainv = A:inv()
local I    = A:dot(Ainv)    -- identity (within numerical precision)
```

#### m:trace()
Sum of diagonal elements of a square matrix.

```lua
local A = linalg.matrix({{1,2},{3,4}})
print(A:trace())    -- 5 (1 + 4)
```

#### m:norm(order?)
Computes the vector or matrix norm.

**Order argument** — pass a number, `"fro"`, or `"inf"`. Passing any other string raises an error. Default is `2`.

| `order` | Vectors | Matrices |
|---------|---------|----------|
| number `p` | p-norm: `(Σ|xᵢ|^p)^(1/p)` | depends on implementation |
| `2` (default) | L2 / Euclidean | — |
| `1` | L1 (sum of absolute values) | — |
| `"fro"` or `"frobenius"` | same as L2 for vectors | Frobenius norm `sqrt(Σaᵢⱼ²)` |
| `"inf"` or `"infinity"` | max absolute value | max absolute row sum |
| `math.huge` | max absolute value (equivalent to `"inf"`) | — |

```lua
local v = linalg.vector({3, 4})
print(v:norm())         -- 5.0   (L2, default)
print(v:norm(1))        -- 7.0   (L1)
print(v:norm("fro"))    -- 5.0   (Frobenius == L2 for vectors)
print(v:norm("inf"))    -- 4.0   (infinity norm)

local A = linalg.matrix({{1,2},{3,4}})
print(A:norm("fro"))    -- Frobenius norm ≈ 5.477

-- Unknown string order raises an error
local ok, err = pcall(function() return v:norm("nuclear") end)
print(err)    -- linalg.norm: unsupported order 'nuclear'; use a number, 'fro', or 'inf'
```

#### m:rank()
Numerical rank of a matrix (computed via SVD with a tolerance threshold).

```lua
local A = linalg.matrix({{1,2,3},{4,5,6},{7,8,9}})
print(A:rank())    -- 2 (rows are linearly dependent)
```

#### m:cond()
Condition number of a matrix (ratio of largest to smallest singular value). A large condition number indicates a near-singular matrix.

```lua
local A = linalg.matrix({{1,2},{3,4}})
print(A:cond())    -- condition number

local B = linalg.eye(3)
print(B:cond())    -- 1.0 (identity is perfectly conditioned)
```

#### m:pinv(rcond?)
Moore-Penrose pseudoinverse. `rcond` is the cutoff for small singular values (default `1e-15`).

```lua
local A    = linalg.matrix({{1,2},{3,4},{5,6}})   -- non-square
local Ap   = A:pinv()
-- A:dot(Ap):dot(A) ≈ A  (pseudoinverse property)

-- Custom tolerance
local Ap2 = A:pinv(1e-10)
```

Free-function forms also available via the module table:

```lua
local Ap = linalg.pinv(A)
local cn = linalg.cond(A)
```

### Matrix Decompositions

#### m:lu()
LU decomposition with partial pivoting. Returns three matrices L, U, P satisfying P·A = L·U.

```lua
local A        = linalg.matrix({{2,1},{1,3}})
local L, U, P  = A:lu()

-- L: lower triangular with 1s on diagonal
-- U: upper triangular
-- P: permutation matrix
```

#### m:qr()
QR decomposition. Returns Q (orthogonal) and R (upper triangular) satisfying A = Q·R.

```lua
local A    = linalg.matrix({{1,2},{3,4},{5,6}})
local Q, R = A:qr()
-- Q:T():dot(Q) ≈ I
```

#### m:svd(return1D?)
Singular Value Decomposition. Returns U, S, V such that A ≈ U·S·V^T.

When `return1D` is `true`, `S` is returned as a vector of singular values. When `false` (default), `S` is a diagonal matrix with the same shape as `A`.

```lua
local A       = linalg.matrix({{1,2},{3,4},{5,6}})
local U, S, V = A:svd()
-- U: left singular vectors (orthogonal)
-- S: diagonal matrix of singular values (default)
-- V: right singular vectors (orthogonal)

-- Return singular values as a 1-D vector
local U2, s, V2 = A:svd(true)
print(s:toarray())    -- {σ₁, σ₂}
```

#### m:eigen() / m:eig()
Eigenvalue decomposition for square matrices. Returns eigenvalues and eigenvectors. `eigen` is the canonical name; `eig` is a legacy alias.

If the matrix has complex eigenvalues, the eigenvalue result is a complex vector (table with `real` and `imag` arrays); otherwise it is a plain vector.

```lua
local A         = linalg.matrix({{4,2},{1,3}})
local vals, vecs = A:eigen()   -- or A:eig()
-- vals: vector of eigenvalues (may be complex)
-- vecs: matrix with eigenvectors as columns
```

Free-function forms for eigenvalue-only or full decomposition:

```lua
local vals, vecs = linalg.eig(A)     -- same as A:eigen()
local vals_only  = linalg.eigvals(A) -- eigenvalues only, no vectors
```

#### m:eigvals()
Eigenvalues only, without computing eigenvectors (faster than `eigen` when eigenvectors are not needed).

```lua
local A    = linalg.matrix({{4,2},{1,3}})
local vals = A:eigvals()
print(vals:toarray())    -- {5, 2}
```

#### m:chol()
Cholesky decomposition for symmetric positive-definite matrices. Returns the lower triangular factor L such that A = L·L^T. Raises an error if the matrix is not positive definite.

```lua
local A = linalg.matrix({{4,2},{2,5}})
local L = A:chol()
-- L:dot(L:T()) ≈ A
```

#### m:expm()
Matrix exponential e^A (computed via eigendecomposition). A must be square.

```lua
local A  = linalg.matrix({{0,-1},{1,0}})
local eA = A:expm()

-- Free-function form
local eA2 = linalg.expm(A)
```

#### m:logm()
Matrix logarithm. A must be square with all positive eigenvalues; raises an error otherwise.

```lua
local A  = linalg.eye(2)
local lA = A:logm()    -- zero matrix (log of identity)

local lA2 = linalg.logm(A)
```

#### m:sqrtm()
Matrix square root. A must be square with all non-negative eigenvalues; raises an error otherwise.

```lua
local A  = linalg.matrix({{4,0},{0,9}})
local sA = A:sqrtm()   -- {{2,0},{0,3}}

local sA2 = linalg.sqrtm(A)
```

#### m:funm(name)
Apply a named scalar function to a matrix via eigendecomposition. Supported names: `"sin"`, `"cos"`, `"exp"`, `"log"`, `"sqrt"`, `"sinh"`, `"cosh"`, `"tanh"`, `"abs"`. An unsupported name raises an error.

```lua
local A      = linalg.matrix({{0,-1},{1,0}})
local sinA   = A:funm("sin")
local cosA   = A:funm("cos")

-- Free-function form
local sinA2  = linalg.funm(A, "sin")

-- Error on unknown function
local ok, e = pcall(function() return A:funm("tan") end)
print(e)    -- linalg.funm: unsupported function 'tan'. Use: sin, cos, exp, ...
```

### Linear System Solvers

#### linalg.solve(A, b)
Solves the square linear system A·x = b. Raises an error if A is singular.

```lua
local A = linalg.matrix({{3,1},{1,2}})
local b = linalg.vector({9, 8})

local x = linalg.solve(A, b)
-- A:dot(x) ≈ b
print(x:toarray())    -- {2, 3}
```

#### linalg.least_squares(A, b) / linalg.lstsq(A, b)
Least-squares solution to A·x = b. Works for overdetermined (more rows than columns) and underdetermined systems. `least_squares` is the canonical name; `lstsq` is a legacy alias.

```lua
-- Overdetermined system (more equations than unknowns)
local A = linalg.matrix({{1,1},{1,2},{1,3}})
local b = linalg.vector({1, 2, 2})

local x = linalg.least_squares(A, b)    -- or linalg.lstsq(A, b)
-- x minimises ||A·x - b||
```

#### linalg.solve_triangular(A, b, opts?)
Solves a triangular system A·x = b without factorisation. `opts` is an optional table:
- `lower` (boolean, default `true`) — `true` for lower triangular A, `false` for upper triangular.
- `trans` (boolean, default `false`) — if `true`, solves A^T·x = b instead.

```lua
local L = linalg.matrix({{2,0},{1,3}})    -- lower triangular
local b = linalg.vector({4, 5})

local x = linalg.solve_triangular(L, b)
-- opts example: upper triangular, no transpose
local U = linalg.matrix({{2,1},{0,3}})
local y = linalg.solve_triangular(U, b, {lower = false})
```

#### linalg.cho_solve(L, b)
Solves A·x = b given the Cholesky factor L (from `m:chol()`) where A = L·L^T. More efficient than calling `solve` when the factorisation is already available.

```lua
local A = linalg.matrix({{4,2},{2,5}})
local L = A:chol()

local b = linalg.vector({1, 2})
local x = linalg.cho_solve(L, b)
```

#### linalg.lu_solve(L, U, P, b)
Solves A·x = b given the LU factors (L, U, P) from `m:lu()`. More efficient than calling `solve` when the factorisation is already available.

```lua
local A        = linalg.matrix({{2,1},{1,3}})
local L, U, P  = A:lu()

local b = linalg.vector({5, 10})
local x = linalg.lu_solve(L, U, P, b)
```

### Complex Matrix Operations

These free functions operate on **complex matrices** — Lua tables with the structure `{rows=n, cols=m, real={...}, imag={...}}`. They do not use the wrapped matrix objects produced by `linalg.matrix()`.

#### linalg.csolve(A, b)
Solve the complex linear system A·x = b where A and b are complex matrices.

#### linalg.csvd(A)
Complex SVD. Returns `U, s, Vt` where `U` and `Vt` are complex matrices and `s` is a real vector of singular values.

#### linalg.ceig(A)
Eigenvalue decomposition of a complex square matrix. Returns `vals, vecs` both as complex matrices.

#### linalg.ceigvals(A)
Eigenvalues only for a complex square matrix. Returns a complex vector.

#### linalg.cdet(A)
Determinant of a complex square matrix. Returns `{re=..., im=...}`.

#### linalg.cinv(A)
Inverse of a complex square matrix. Returns a complex matrix.

```lua
-- Complex matrix representation
local A = {
    rows = 2, cols = 2,
    real = {1, 0, 0, 1},
    imag = {1, 0, 0, -1}   -- A = [[1+i, 0], [0, 1-i]]
}

local d    = linalg.cdet(A)         -- {re=..., im=...}
local Ainv = linalg.cinv(A)         -- complex matrix table
local vals = linalg.ceigvals(A)     -- complex vector table
```

## Common Patterns

### Solving Linear Systems

```lua
local linalg = require("luaswift.linalg")

-- System: 3x + y = 9, x + 2y = 8
local A = linalg.matrix({{3, 1}, {1, 2}})
local b = linalg.vector({9, 8})

local x = linalg.solve(A, b)
print(x:toarray())    -- {2, 3}

-- Verify: A·x should equal b
local check = A:dot(x)
print(check:toarray())    -- {9, 8}
```

### Computing Matrix Properties

```lua
local A = linalg.matrix({{1, 2, 3}, {4, 5, 6}, {7, 8, 10}})

print("Determinant:", A:det())
print("Trace:",       A:trace())
print("Rank:",        A:rank())
print("Condition:",   A:cond())
print("Frobenius:",   A:norm("fro"))
```

### Norms

```lua
local v = linalg.vector({3, 4})
print(v:norm())         -- 5.0  (L2, default)
print(v:norm(1))        -- 7.0  (L1)
print(v:norm("fro"))    -- 5.0  (Frobenius, same as L2 for vectors)
print(v:norm("inf"))    -- 4.0  (infinity norm)

local A = linalg.matrix({{1,0},{0,2}})
print(A:norm("fro"))    -- sqrt(5) ≈ 2.236
```

### Linear Regression

```lua
-- Data points: (1,2), (2,3), (3,5), (4,4)
local X = linalg.matrix({
    {1, 1},
    {1, 2},
    {1, 3},
    {1, 4}
})
local y = linalg.vector({2, 3, 5, 4})

-- Least squares fit: y = a + b*x
local coeffs = linalg.least_squares(X, y)
local a, b   = coeffs:get(1), coeffs:get(2)
print(string.format("y = %.2f + %.2fx", a, b))
```

### Eigenvalue Analysis

```lua
local A         = linalg.matrix({{4,2},{1,3}})
local vals, vecs = A:eigen()
print(vals:toarray())    -- eigenvalues

-- Values only (cheaper)
local v2 = A:eigvals()
print(v2:toarray())

-- Free-function form
local vals2, vecs2 = linalg.eig(A)
```

### Matrix Functions

```lua
local A    = linalg.matrix({{0,-1},{1,0}})
local eA   = A:expm()          -- matrix exponential
local sinA = A:funm("sin")     -- matrix sine

-- Matrix square root
local B  = linalg.matrix({{4,0},{0,9}})
local sB = B:sqrtm()           -- {{2,0},{0,3}}
```

### Factorisation Reuse

```lua
-- Solve multiple right-hand sides efficiently using LU factorisation
local A       = linalg.matrix({{2,1},{1,3}})
local L, U, P = A:lu()

local x1 = linalg.lu_solve(L, U, P, linalg.vector({5, 10}))
local x2 = linalg.lu_solve(L, U, P, linalg.vector({1, 2}))
```

### Principal Component Analysis (PCA)

```lua
local linalg = require("luaswift.linalg")

local data = linalg.matrix({
    {2.5, 2.4},
    {0.5, 0.7},
    {2.2, 2.9},
    {1.9, 2.2},
    {3.1, 3.0}
})

-- Get principal components via SVD (singular values in descending order)
local U, S, V = data:svd()
-- V columns are principal component directions
```

## Performance Notes

- The LinAlg module uses Apple's Accelerate framework for hardware-accelerated computation via NumericSwift.
- All operations use double-precision (64-bit) floating-point numbers.
- For best performance, avoid creating many small temporary matrices in tight loops.
- Prefer batch operations over element-by-element access.
- When solving the same system for multiple right-hand sides, compute the factorisation once with `m:lu()` or `m:chol()` and reuse it via `lu_solve` / `cho_solve`.

## See Also

- ``LinAlgModule``
- ``MathXModule``
- ``ArrayModule``
- ``ComplexModule``
