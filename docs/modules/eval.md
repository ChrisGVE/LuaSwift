# Expression Evaluation Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.eval` | **Global:** `math.eval` (after extend_stdlib)

Mathematical expression parsing, evaluation, and solving with support for standard math functions, complex numbers, LaTeX notation, symbolic substitution, and step-by-step evaluation.

## Quick Start

```lua
local eval = require("luaswift.eval")

-- Evaluate with variables
local result = eval("x^2 + 2*x + 1", {x = 3})  -- 16

-- Callable syntax
result = eval("sin(pi/2)")  -- 1.0

-- Compile to function
local f = eval.compile("x^2 + 1")
print(f({x = 2}))  -- 5
print(f({x = 3}))  -- 10

-- Solve equations
local solution = eval.solve("2*x + 5 = 15")  -- {x = 5}
```

## Expression Evaluation

### `eval(expression, variables?)`

Evaluate a mathematical expression with optional variable bindings. The module itself is callable.

```lua
-- Simple expressions
print(eval("2 + 3 * 4"))           -- 14
print(eval("sin(pi/2)"))           -- 1.0
print(eval("sqrt(16)"))            -- 4.0

-- Variables
print(eval("x^2 + 2*x + 1", {x = 3}))        -- 16
print(eval("a*x + b", {x = 5, a = 2, b = 3})) -- 13

-- Complex numbers
print(eval("2i * 3i"))             -- -6 (imaginary literals)
print(eval("(1+2i)/(1+1i)"))       -- 1.5+0.5i
```

### `eval.compile(expression, options?)`

Compile an expression to a native Lua function for faster repeated evaluation.

```lua
-- Compile once, use many times
local f = eval.compile("x^2 + 2*x + 1")
print(f({x = 0}))  -- 1
print(f({x = 1}))  -- 4
print(f({x = 2}))  -- 9

-- Works with single variable as number
local g = eval.compile("sin(x)")
print(g(0))           -- 0
print(g(math.pi/2))   -- 1.0

-- Disable codegen (use AST walker)
local h = eval.compile("x + 1", {codegen = false})
```

**Options:**
- `codegen` (boolean): Generate native Lua code (default: true). Set to false for AST-based evaluation.

## LaTeX Notation Support

### `eval.latexToStandard(latex)`

Convert LaTeX mathematical notation to standard expression syntax.

```lua
-- Fractions
eval.latexToStandard("\\frac{a}{b}")        -- "(a)/(b)"

-- Roots
eval.latexToStandard("\\sqrt{x}")           -- "sqrt(x)"
eval.latexToStandard("\\sqrt[3]{x}")        -- "(x)^(1/(3))"

-- Functions
eval.latexToStandard("\\sin{x}")            -- "sin(x)"

-- Greek letters
eval.latexToStandard("\\pi + \\theta")      -- "pi + theta"

-- Exponents
eval.latexToStandard("x^{2}")               -- "x^(2)"

-- Auto-detection
eval("\\frac{1}{2}")                        -- 0.5 (LaTeX auto-detected)
```

**Supported LaTeX constructs:**
- Fractions: `\frac{num}{den}`
- Square roots: `\sqrt{x}`
- Nth roots: `\sqrt[n]{x}`
- Functions: `\sin`, `\cos`, `\tan`, `\log`, `\ln`, `\exp`, etc.
- Greek letters: `\pi`, `\theta`, `\alpha`, `\beta`, `\gamma`, etc.
- Exponents: `x^{n}` → `x^(n)`
- Parentheses: `\left(`, `\right)`, `\left[`, `\right]`

**Summation/Product notation:**

```lua
-- Requires series module
eval("\\sum_{i=1}^{10} i")          -- 55
eval("\\prod_{i=1}^{5} i")          -- 120
```

## Equation Solving

### `eval.solve_equation(equation, variables?, options?)`

Solve an equation for an unknown variable using analytical or numerical methods.

```lua
-- Linear equations (analytical)
local sol = eval.solve_equation("2*x + 5 = 15")
print(sol.x)  -- 5.0

local sol2 = eval.solve_equation("3*x - 7 = 2*x + 8")
print(sol2.x)  -- 15.0

-- With known variables
local sol3 = eval.solve_equation("a*x + b = c", {a = 2, b = 3, c = 11})
print(sol3.x)  -- 4.0

-- Non-linear equations (numerical)
local sol4 = eval.solve_equation("x^2 = 16", {}, {initial_guess = 1})
print(sol4.x)  -- 4.0

local sol5 = eval.solve_equation("sin(x) = 0.5", {}, {initial_guess = 0})
print(sol5.x)  -- ~0.5236 (π/6)
```

**Options:**
- `solve_for` (string): Specify which variable to solve for (required if multiple unknowns)
- `initial_guess` (number): Starting point for numerical solver (default: 1)
- `tolerance` (number): Convergence tolerance (default: 1e-10)
- `max_iterations` (number): Maximum Newton-Raphson iterations (default: 100)

### `eval.solve_system(equations, variables?, options?)`

Solve a system of equations.

```lua
-- 2x2 linear system
local sys = {
    "2*x + 3*y = 13",
    "x - y = 1"
}
local sol = eval.solve_system(sys)
print(sol.x, sol.y)  -- 4.0, 3.0

-- With known constants
local sys2 = {
    "a*x + b*y = c",
    "x + y = d"
}
local sol2 = eval.solve_system(sys2, {a = 2, b = 3, c = 13, d = 7})
print(sol2.x, sol2.y)  -- 4.0, 3.0
```

### `eval.solve(input, arg2?, arg3?)`

Unified solve function supporting expressions, equations, and systems.

```lua
-- Evaluate expression
eval.solve("2 + 3")  -- 5

-- Solve single equation
eval.solve("x + 5 = 10")  -- {x = 5}

-- Solve with variables
eval.solve("a*x + b = c", {a = 2, b = 3, c = 11})  -- {x = 4}

-- Solve system
eval.solve({"x + y = 5", "x - y = 1"})  -- {x = 3, y = 2}

-- With options
eval.solve("x^2 = 4", {}, {initial_guess = -1})  -- {x = -2}

-- Step-by-step evaluation
local steps = eval.solve("2 * (3 + 4)", {show_steps = true})
-- Returns array of step objects
```

## Tokenization and Parsing

### `eval.tokenize(expression)`

Tokenize an expression into an array of token objects.

```lua
local tokens = eval.tokenize("sin(x) + 2*pi")
-- {
--   {type = "function", value = "sin"},
--   {type = "lparen"},
--   {type = "variable", value = "x"},
--   {type = "rparen"},
--   {type = "operator", value = "+"},
--   {type = "number", value = 2},
--   {type = "operator", value = "*"},
--   {type = "constant", value = "pi"}
-- }

-- Imaginary literals
local tokens2 = eval.tokenize("2+3i")
-- {
--   {type = "number", value = 2},
--   {type = "operator", value = "+"},
--   {type = "imaginary", value = 3}
-- }
```

**Token types:**
- `number`: Numeric literal (supports decimals and scientific notation)
- `imaginary`: Imaginary literal (e.g., `2i`, `5.5i`)
- `operator`: `+`, `-`, `*`, `/`, `^`
- `function`: Known function name
- `variable`: Unknown identifier
- `constant`: Known constant (`pi`, `e`, `inf`, `nan`)
- `lparen`, `rparen`: Parentheses
- `comma`: Argument separator

### `eval.parse(tokens)`

Parse tokens into an Abstract Syntax Tree (AST).

```lua
local tokens = eval.tokenize("2*x + 1")
local ast = eval.parse(tokens)
-- {
--   type = "binop",
--   op = "+",
--   left = {
--     type = "binop",
--     op = "*",
--     left = {type = "number", value = 2},
--     right = {type = "variable", name = "x"}
--   },
--   right = {type = "number", value = 1}
-- }
```

**AST node types:**
- `number`: `{type = "number", value = n}`
- `imaginary`: `{type = "imaginary", value = n}`
- `constant`: `{type = "constant", name = "pi"}`
- `variable`: `{type = "variable", name = "x"}`
- `binop`: `{type = "binop", op = "+", left = ast, right = ast}`
- `call`: `{type = "call", name = "sin", args = {ast, ...}}`

### `eval.eval_ast(ast, variables?)`

Evaluate an AST with variable bindings.

```lua
local tokens = eval.tokenize("x^2 + 1")
local ast = eval.parse(tokens)
local result = eval.eval_ast(ast, {x = 3})  -- 10
```

## Symbolic Manipulation

### `eval.substitute(ast, substitutions)`

Perform symbolic substitution in an AST.

```lua
local tokens = eval.tokenize("a*x + b")
local ast = eval.parse(tokens)

-- Substitute a = 2, b = 3
local new_ast = eval.substitute(ast, {a = 2, b = 3})
print(eval.to_string(new_ast))  -- "2 * x + 3"

-- Substitute with expressions
local new_ast2 = eval.substitute(ast, {a = "sin(y)", b = "cos(y)"})
print(eval.to_string(new_ast2))  -- "sin(y) * x + cos(y)"
```

### `eval.to_string(ast)`

Convert an AST back to expression string.

```lua
local tokens = eval.tokenize("(2 + 3) * 4")
local ast = eval.parse(tokens)
print(eval.to_string(ast))  -- "(2 + 3) * 4"

-- After substitution
local new_ast = eval.substitute(ast, {})
print(eval.to_string(new_ast))  -- "5 * 4"
```

## Step-by-Step Evaluation

Evaluate expressions with detailed step tracking for educational or debugging purposes.

```lua
local steps = eval.solve("2 * (3 + 4)", {show_steps = true})

for i, step in ipairs(steps) do
    print(step.description, "→", step.result or "")
end
-- Initial expression →
-- 3 + 4 → 7
-- 2 × 7 → 14
-- Final result → 14

-- With variables
local steps2 = eval.solve("x^2 + 2*x", {
    show_steps = true,
    variables = {x = 3}
})

-- Control precision
local steps3 = eval.solve("pi * 2", {
    show_steps = true,
    significantDigits = 4
})
```

**Step object format:**
```lua
{
    operation = "binop",           -- or "call", "initial", "result"
    description = "3 + 4",         -- Human-readable description
    operands = {3, 4},             -- Input values
    result = 7,                    -- Computed result
    precision = 4,                 -- Significant digits
    subexpression = "3 + 4"        -- String representation
}
```

## Constants and Functions

### Constants

```lua
eval.constants = {
    pi = 3.141592653589793,     -- π
    e = 2.718281828459045,      -- Euler's number
    inf = math.huge,            -- Infinity
    nan = 0/0                   -- Not a number
}
```

**Note:** The imaginary unit `i` is NOT a constant to avoid conflicts with loop variables. Use `1i` syntax for the pure imaginary unit.

### Functions

**Trigonometric:**
- `sin(x)`, `cos(x)`, `tan(x)`
- `asin(x)`, `acos(x)`, `atan(x)`, `atan2(y, x)`
- `sinh(x)`, `cosh(x)`, `tanh(x)`
- `asinh(x)`, `acosh(x)`, `atanh(x)`

**Exponential and logarithmic:**
- `exp(x)` - e^x
- `log(x)`, `ln(x)` - Natural logarithm
- `log10(x)` - Base-10 logarithm
- `log2(x)` - Base-2 logarithm

**Power and roots:**
- `sqrt(x)` - Square root
- `cbrt(x)` - Cube root
- `pow(x, y)` - x^y

**Rounding and value:**
- `abs(x)` - Absolute value
- `sign(x)` - Sign (-1, 0, or 1)
- `floor(x)`, `ceil(x)` - Floor/ceiling
- `round(x)` - Round to nearest integer
- `trunc(x)` - Truncate to integer

**Min/max and interpolation:**
- `min(a, b, ...)` - Minimum
- `max(a, b, ...)` - Maximum
- `clamp(x, lo, hi)` - Clamp to range
- `lerp(a, b, t)` - Linear interpolation

**Angle conversion:**
- `rad(deg)` - Degrees to radians
- `deg(rad)` - Radians to degrees

## Complex Numbers

Complex numbers are represented as tables with `re` and `im` fields.

```lua
-- Imaginary literals
local z1 = eval("2i")                    -- {re = 0, im = 2}
local z2 = eval("3 + 4i")                -- {re = 3, im = 4}

-- Complex arithmetic
local sum = eval("(1+2i) + (3+4i)")      -- {re = 4, im = 6}
local prod = eval("(1+2i) * (3+4i)")     -- {re = -5, im = 10}
local quot = eval("(1+2i) / (1+1i)")     -- {re = 1.5, im = 0.5}

-- Powers (De Moivre's formula)
local pow = eval("1i^2")                 -- -1 (i² = -1)
local pow2 = eval("(1+1i)^3")            -- {re = -2, im = 2}

-- Simplified results
-- If imaginary part is negligible (< 1e-14), returns real number
local real = eval("(3+4i)*(3-4i)")       -- 25 (conjugate product)
```

## Examples

### Polynomial Evaluation

```lua
local poly = eval.compile("a*x^3 + b*x^2 + c*x + d")

print(poly({x = 1, a = 1, b = 2, c = 3, d = 4}))  -- 10
print(poly({x = 2, a = 1, b = 2, c = 3, d = 4}))  -- 26
```

### Quadratic Formula

```lua
-- Solve ax² + bx + c = 0 using quadratic formula
local function solve_quadratic(a, b, c)
    local disc = b^2 - 4*a*c
    if disc < 0 then
        -- Complex roots
        local real = -b / (2*a)
        local imag = math.sqrt(-disc) / (2*a)
        return {
            {re = real, im = imag},
            {re = real, im = -imag}
        }
    else
        local sqrt_disc = math.sqrt(disc)
        return {
            (-b + sqrt_disc) / (2*a),
            (-b - sqrt_disc) / (2*a)
        }
    end
end

-- Or use eval.solve
local roots = eval.solve("x^2 - 5*x + 6 = 0")  -- {x = 3} or {x = 2}
```

### Physics Formulas

```lua
-- Kinematic equation: v = v0 + a*t
local v = eval("v0 + a*t", {v0 = 10, a = 9.8, t = 2})  -- 29.6

-- Solve for time: when does v = 50?
local sol = eval.solve("v0 + a*t = 50", {v0 = 10, a = 9.8})
print(sol.t)  -- ~4.08

-- Pendulum period: T = 2π√(L/g)
local T = eval("2*pi*sqrt(L/g)", {L = 1, g = 9.8})  -- ~2.006
```

### Expression Transformation

```lua
-- Expand (x+1)²
local tokens = eval.tokenize("(x+1)^2")
local ast = eval.parse(tokens)

-- After manual expansion to x² + 2x + 1
local expanded = {
    type = "binop",
    op = "+",
    left = {
        type = "binop",
        op = "+",
        left = {
            type = "binop",
            op = "^",
            left = {type = "variable", name = "x"},
            right = {type = "number", value = 2}
        },
        right = {
            type = "binop",
            op = "*",
            left = {type = "number", value = 2},
            right = {type = "variable", name = "x"}
        }
    },
    right = {type = "number", value = 1}
}

print(eval.to_string(expanded))  -- "x^2 + 2 * x + 1"
```

## Function Reference

| Function | Description |
|----------|-------------|
| `eval(expr, vars?)` | Evaluate expression with variables |
| `eval.compile(expr, opts?)` | Compile to native function |
| `eval.tokenize(expr)` | Tokenize expression string |
| `eval.parse(tokens)` | Parse tokens to AST |
| `eval.eval_ast(ast, vars?)` | Evaluate AST |
| `eval.latexToStandard(latex)` | Convert LaTeX to standard notation |
| `eval.solve(input, ...)` | Unified solve function |
| `eval.solve_equation(eq, vars?, opts?)` | Solve single equation |
| `eval.solve_system(eqs, vars?, opts?)` | Solve system of equations |
| `eval.substitute(ast, subs)` | Symbolic substitution |
| `eval.to_string(ast)` | Convert AST to string |
| `eval.constants` | Table of mathematical constants |
| `eval.functions` | Table of available functions |
