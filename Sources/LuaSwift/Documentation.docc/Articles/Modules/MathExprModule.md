# MathExpr Module

Parse, evaluate, and solve mathematical expressions from strings.

> Important: This module requires the **NumericSwift** optional dependency and is **disabled by default**. Enable it at build time with `LUASWIFT_INCLUDE_NUMERICSWIFT=1`.
>
> ```bash
> LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build
> LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift test
> ```

## Overview

The MathExpr module provides tokenization, parsing, evaluation, compilation, substitution, and equation-solving for mathematical expression strings. It supports standard arithmetic, trigonometric and transcendental functions, built-in constants, user-defined variables, complex numbers, and LaTeX notation.

The module is exposed as `math.eval` in the Lua environment. It is also available as `luaswift.eval`, `luaswift.mathexpr`, and via `require`:

```lua
local eval = require("luaswift.mathexpr")
-- math.eval and luaswift.eval refer to the same object
```

The `eval` table is callable as a function: `eval(expr, vars)` is equivalent to `eval.eval(expr, vars)`.

## Installation

```swift
// Install all modules (MathSciModule must run before MathExprModule)
ModuleRegistry.installModules(in: engine)

// Or install MathExpr alone
ModuleRegistry.installMathExprModule(in: engine)
```

## Basic Usage

```lua
local eval = require("luaswift.mathexpr")

-- Direct evaluation
local result = eval.eval("2 + 3 * 4")           -- 14
local result = eval.eval("sin(pi/2)")             -- 1.0

-- With variables
local result = eval.eval("x^2 + 2*x + 1", {x = 3})  -- 16

-- Callable shorthand (eval table is callable)
local result = eval("x^2 + 2*x + 1", {x = 3})   -- 16

-- Compile to a reusable function
local f = eval.compile("sin(x)")
print(f(0))          -- 0.0
print(f(math.pi))    -- ~0.0
```

## API Reference

### Expression Evaluation

#### eval.eval(expr, vars?)

Parses and evaluates a mathematical expression string. Supports complex numbers, expression-valued variables, and lazy variable resolution.

**Parameters:**
- `expr` — expression string
- `vars` — optional table mapping variable names to numbers, expression strings, or compiled functions

**Returns:** number, or `{re, im}` complex table if the result is complex

```lua
-- Arithmetic
eval.eval("10 - 4 * 2")               -- 2
eval.eval("2^10")                      -- 1024
eval.eval("(1 + 2) * (3 + 4)")        -- 21

-- Variables
eval.eval("x + y", {x = 3, y = 4})                     -- 7
eval.eval("r * cos(theta)", {r = 5, theta = 0})         -- 5

-- Constants in expressions
eval.eval("2 * pi")                    -- 6.2831853071796
eval.eval("e^2")                       -- 7.3890560989307

-- Functions
eval.eval("sqrt(16)")                  -- 4
eval.eval("sin(pi/6)")                 -- 0.5
eval.eval("log(e)")                    -- 1

-- Expression-valued variables (lazy evaluation)
eval.eval("y + 1", {x = "2 + 3", y = "x * 2"})         -- 11
```

#### eval.eval_swift(expr, vars?)

Evaluates an expression using the NumericSwift backend directly. Handles real-valued expressions only; complex numbers are not supported on this path.

**Parameters:**
- `expr` — expression string
- `vars` — optional table mapping variable names to numbers

**Returns:** number

```lua
local result = eval.eval_swift("sin(pi/2)", {})          -- 1.0
local result = eval.eval_swift("x^2 - 4", {x = 3})      -- 5
```

#### eval.eval_ast(ast, vars?)

Evaluates a parsed AST table directly. Supports complex arithmetic via `{re, im}` tables.

**Parameters:**
- `ast` — AST table as returned by `eval.parse` or `eval.parse_string`
- `vars` — optional table of variable bindings (numbers or `{re, im}` tables)

**Returns:** number, or `{re, im}` complex table

```lua
local ast = eval.parse("x^2 + 1")
print(eval.eval_ast(ast, {x = 3}))    -- 10
print(eval.eval_ast(ast, {x = 5}))    -- 26

-- Complex: i^2 = -1
local ast = eval.parse("i^2")
local r = eval.eval_ast(ast, {})
-- r == -1 (imaginary part collapses to zero)
```

#### eval.compile(input, options?)

Compiles an expression to a native Lua function. The compiled function is faster than repeated calls to `eval.eval` for the same expression.

**Parameters:**
- `input` — expression string, token array, or AST table
- `options` — optional table:
  - `codegen` (boolean) — set to `false` to force AST-walking instead of code generation

**Returns:** a function `f(vars_or_x)` where:
- if called with a number, it is bound to variable `x`
- if called with a table, it is used as the variable map

```lua
-- Single variable (number argument binds to x)
local f = eval.compile("x^2 - 4*x + 4")
print(f(0))                   -- 4
print(f(2))                   -- 0
print(f(5))                   -- 9

-- Multi-variable (table argument)
local g = eval.compile("a*x + b")
print(g({a = 2, x = 3, b = 1}))  -- 7

-- Compile from existing AST
local ast = eval.parse("sin(x) * cos(x)")
local f = eval.compile(ast)
print(f(0))                   -- 0
```

### Tokenization and Parsing

#### eval.tokenize(expr)

Tokenizes an expression string into an array of token tables. Automatically preprocesses LaTeX notation when detected.

**Parameters:**
- `expr` — expression string or LaTeX string

**Returns:** array of token tables, each with fields:
- `type` — one of: `"number"`, `"imaginary"`, `"operator"`, `"function"`, `"variable"`, `"constant"`, `"lparen"`, `"rparen"`, `"comma"`
- `value` — string or number (absent for `lparen`, `rparen`, `comma`)

```lua
local tokens = eval.tokenize("2 * x + sin(y)")
for i, tok in ipairs(tokens) do
    print(i, tok.type, tok.value)
end
-- 1   number     2
-- 2   operator   *
-- 3   variable   x
-- 4   operator   +
-- 5   function   sin
-- 6   lparen
-- 7   variable   y
-- 8   rparen
```

Token types:

| Type | `value` field | Example |
|------|---------------|---------|
| `number` | number | `2`, `3.14`, `1e-5` |
| `imaginary` | number (coefficient) | `2i` → value `2` |
| `operator` | string | `"+"`, `"-"`, `"*"`, `"/"`, `"^"`, `"%"` |
| `function` | string | `"sin"`, `"sqrt"` |
| `variable` | string | `"x"`, `"theta"` |
| `constant` | string | `"pi"`, `"e"`, `"inf"` |
| `lparen` | absent | `(` |
| `rparen` | absent | `)` |
| `comma` | absent | `,` |

#### eval.parse(expr_or_tokens)

Parses an expression string or token array into an AST table using the NumericSwift backend.

**Parameters:**
- `expr_or_tokens` — expression string or token array from `eval.tokenize`

**Returns:** AST table (see AST Structure below)

```lua
local ast = eval.parse("x^2 + 2*x + 1")
-- Returns nested table: {type="binop", op="+", left=..., right=...}

-- Also accepts token arrays
local tokens = eval.tokenize("2 * x + 1")
local ast = eval.parse(tokens)
```

#### eval.parse_string(expr)

Parses an expression string into an AST table. Equivalent to `eval.parse` when given a string.

**Parameters:**
- `expr` — expression string

**Returns:** AST table

```lua
local ast = eval.parse_string("sin(x)^2 + cos(x)^2")
```

#### eval.parse_swift(tokens)

Calls the Swift parse callback directly with a token array or expression string.

**Parameters:**
- `tokens` — token array or expression string

**Returns:** AST table

### AST Structure

AST nodes are Lua tables with a `type` field:

| Node type | Fields | Description |
|-----------|--------|-------------|
| `number` | `value` (number) | Numeric literal |
| `imaginary` | `value` (number) | Imaginary literal (`2i` → value `2`) |
| `constant` | `name` (string) | Built-in constant: `"pi"`, `"e"`, `"i"`, `"inf"`, `"nan"` |
| `variable` | `name` (string) | Variable reference |
| `unary` | `op` (string), `operand` (AST) | Unary operator: `"-"`, `"+"`, `"!"`, `"T"` |
| `binop` | `op` (string), `left` (AST), `right` (AST) | Binary operator: `"+"`, `"-"`, `"*"`, `"/"`, `"^"`, `"%"`, `"±"`, `"∓"` |
| `call` | `name` (string), `args` (array of AST) | Function call |

### Substitution and Inspection

#### eval.substitute(ast, vars)

Substitutes variables in an AST with values or sub-expressions. Returns a new AST with substitutions applied.

**Parameters:**
- `ast` — AST table
- `vars` — table mapping variable names to:
  - numbers (substituted as numeric literals)
  - expression strings (parsed and substituted as sub-ASTs)
  - AST tables (substituted directly)

**Returns:** new AST table

```lua
local ast = eval.parse("a*x^2 + b*x + c")

-- Substitute numeric constants
local simplified = eval.substitute(ast, {a = 1, b = -3, c = 2})
print(eval.eval_ast(simplified, {x = 1}))   -- 0
print(eval.eval_ast(simplified, {x = 2}))   -- 0

-- Substitute a sub-expression
local expanded = eval.substitute(ast, {x = "t + 1"})
print(eval.to_string(expanded))
```

#### eval.substitute_swift(ast, substitutions)

Calls the Swift substitute backend directly. Behaviour is identical to `eval.substitute`.

#### eval.find_variables(ast)

Returns a sorted array of all variable names referenced in an AST.

**Parameters:**
- `ast` — AST table or expression string

**Returns:** sorted array of strings

```lua
local ast = eval.parse("a*x^2 + b*x + c")
local vars = eval.find_variables(ast)
-- {"a", "b", "c", "x"}

-- Also accepts expression strings
local vars = eval.find_variables("r * cos(theta) + r * sin(theta)")
-- {"r", "theta"}
```

#### eval.find_variables_swift(ast)

Calls the Swift find-variables backend directly. Behaviour is identical to `eval.find_variables`.

#### eval.to_string(ast)

Converts an AST table back to a normalised expression string using the NumericSwift backend.

**Parameters:**
- `ast` — AST table or expression string

**Returns:** string

```lua
local ast = eval.parse("x^2 + 2*x + 1")
print(eval.to_string(ast))               -- "x^2 + 2*x + 1" (normalised form)
```

#### eval.to_string_swift(ast)

Calls the Swift to-string backend directly. Behaviour is identical to `eval.to_string`.

### Equation Solving

#### eval.solve(input, arg2?, arg3?)

Unified solver. Behaviour depends on the type of `input`:

- **Expression string without `=`**: evaluates with optional step tracking
- **Equation string containing `=`**: solves for the single unknown
- **Array of equation strings**: solves the system

**Parameters:**
- `input` — expression string, equation string (`"lhs = rhs"`), or array of equation strings
- `arg2` — variable bindings table (for equations), or options table (for expressions)
- `arg3` — options table (when `arg2` is variable bindings)

**Options for expression evaluation:**
- `show_steps` (boolean) — return step table instead of number
- `variables` (table) — variable bindings
- `combineArithmetic` (boolean) — suppress intermediate arithmetic steps
- `showIntermediates` (boolean) — include intermediate results
- `significantDigits` (number) — decimal places for step descriptions

**Options for equation solving:**
- `solve_for` (string) — variable to solve for (when multiple unknowns present)
- `initial_guess` (number) — starting point for numerical solver (default: `1`)
- `tolerance` (number) — convergence tolerance (default: `1e-10`)
- `max_iterations` (number) — Newton-Raphson iteration cap (default: `100`)

**Returns:**
- number (expression evaluation)
- array of step tables (when `show_steps = true`)
- table `{var = value, ...}` (equation/system solution)
- table `{satisfied = bool, left = val, right = val}` (equation with no unknowns)
- table `{error = message}` (no solution or contradiction)

```lua
-- Evaluate expression
print(eval.solve("2^10"))                        -- 1024

-- Evaluate with steps
local steps = eval.solve("2 * 3 + 4", {show_steps = true, variables = {}})
for _, step in ipairs(steps) do
    print(step.operation, step.description, step.result)
end

-- Solve linear equation
local r = eval.solve("2*x + 3 = 7")
print(r.x)                                       -- 2

-- Solve with known variables
local r = eval.solve("a*x = b", {a = 3, b = 9})
print(r.x)                                       -- 3

-- Specify which variable to solve for
local r = eval.solve("a + b = 10", {a = 4}, {solve_for = "b"})
print(r.b)                                       -- 6

-- Solve system of equations
local r = eval.solve({"x + y = 5", "x - y = 1"})
print(r.x, r.y)                                  -- 3   2
```

#### eval.solve_equation(equation, vars?, options?)

Solves a single equation string for one unknown. Uses analytical solution for linear equations; falls back to Newton-Raphson for nonlinear ones.

**Parameters:**
- `equation` — equation string containing `=`
- `vars` — optional table of known variable values
- `options` — optional table with `solve_for`, `initial_guess`, `tolerance`, `max_iterations`

**Returns:** table `{var = value}`, `{error = message}`, or `{satisfied, left, right}` (no unknowns)

```lua
-- Linear equation
local r = eval.solve_equation("3*x - 6 = 0")
print(r.x)                                       -- 2

-- Nonlinear (Newton-Raphson)
local r = eval.solve_equation("x^2 - 2 = 0", {}, {initial_guess = 1})
print(r.x)                                       -- 1.4142135623731

-- With a known variable
local r = eval.solve_equation("m * x + c = 0", {m = 2, c = 4})
print(r.x)                                       -- -2

-- Specify variable when multiple unknowns exist
local r = eval.solve_equation("a + b = 10", {a = 3}, {solve_for = "b"})
print(r.b)                                       -- 7

-- Check equation satisfaction (no unknowns)
local r = eval.solve_equation("2 + 2 = 4", {})
print(r.satisfied)                               -- true
```

A `warning` field is present in the result when the Newton-Raphson solver may not have converged.

#### eval.solve_system(equations, vars?, options?)

Solves a system of equations. For two equations in two unknowns, uses direct linear algebra (Cramer's rule) when the system is linear. Otherwise falls back to iterative substitution.

**Parameters:**
- `equations` — array of equation strings, or a single equation string
- `vars` — optional table of known variable values
- `options` — optional solver options (see `eval.solve_equation`)

**Returns:** table `{var1 = val1, var2 = val2, ...}` or `{error = message}`

```lua
-- 2×2 linear system
local r = eval.solve_system({"2*x + y = 5", "x - y = 1"})
print(r.x, r.y)                                  -- 2   1

-- System with known variables
local r = eval.solve_system({"a*x + y = 10", "x - y = 0"}, {a = 1})
print(r.x, r.y)                                  -- 5   5
```

### LaTeX Support

#### eval.latexToStandard(latex)

Converts a LaTeX expression string to standard notation that the evaluator accepts.

**Parameters:**
- `latex` — LaTeX expression string

**Returns:** standard expression string

Supported conversions:

| LaTeX | Standard |
|-------|----------|
| `\frac{a}{b}` | `(a)/(b)` |
| `\sqrt{x}` | `sqrt(x)` |
| `\sqrt[n]{x}` | `(x)^(1/(n))` |
| `x^{n}` | `x^(n)` |
| `\sin`, `\cos`, … | `sin`, `cos`, … |
| `\pi`, `\theta`, `\alpha`, … | `pi`, `theta`, `alpha`, … |
| `\left(`, `\right)` | `(`, `)` |
| `\sum_{var=a}^{b} body` | delegates to `series.sum` |
| `\prod_{var=a}^{b} body` | delegates to `series.product` |

```lua
local std = eval.latexToStandard("\\frac{x^{2}+1}{2}")
print(std)                               -- (x^(2)+1)/(2)
print(eval.eval(std, {x = 3}))           -- 5.0

-- LaTeX is detected and preprocessed automatically in tokenize and eval_swift
local tokens = eval.tokenize("\\sin(x)")
-- Equivalent to eval.tokenize("sin(x)")
```

### Built-in Constants

Available in `eval.constants` and usable directly in expression strings:

| Name | Value | Notes |
|------|-------|-------|
| `pi` | 3.14159265358979… | π |
| `e` | 2.71828182845904… | Euler's number |
| `inf` | `math.huge` | Positive infinity |
| `nan` | `0/0` | Not a Number |

The imaginary unit `i` (also `j`, `k`) is recognised as a constant in expressions but is intentionally absent from `eval.constants` to avoid shadowing loop variable `i`. It returns `{re=0, im=1}` during AST evaluation unless overridden by a variable binding.

```lua
print(eval.constants.pi)          -- 3.1415926535898
print(eval.eval("2 * pi * r", {r = 5}))   -- 31.415926535898
```

### Built-in Functions

Available in `eval.functions` and usable directly in expression strings:

#### Trigonometric
| Function | Description |
|----------|-------------|
| `sin(x)` | Sine |
| `cos(x)` | Cosine |
| `tan(x)` | Tangent |
| `asin(x)` | Arcsine |
| `acos(x)` | Arccosine |
| `atan(x)` | Arctangent |
| `atan2(y, x)` | Two-argument arctangent |

#### Hyperbolic
| Function | Description |
|----------|-------------|
| `sinh(x)` | Hyperbolic sine |
| `cosh(x)` | Hyperbolic cosine |
| `tanh(x)` | Hyperbolic tangent |
| `asinh(x)` | Inverse hyperbolic sine |
| `acosh(x)` | Inverse hyperbolic cosine |
| `atanh(x)` | Inverse hyperbolic tangent |

#### Exponential and Logarithmic
| Function | Description |
|----------|-------------|
| `exp(x)` | e^x |
| `log(x)` | Natural logarithm |
| `ln(x)` | Natural logarithm (alias for `log`) |
| `log10(x)` | Base-10 logarithm |
| `log2(x)` | Base-2 logarithm |

#### Power and Roots
| Function | Description |
|----------|-------------|
| `sqrt(x)` | Square root |
| `cbrt(x)` | Cube root |
| `pow(x, y)` | x raised to power y |

#### Rounding and Absolute Value
| Function | Description |
|----------|-------------|
| `abs(x)` | Absolute value |
| `sign(x)` | Sign: −1, 0, or 1 |
| `floor(x)` | Round toward −∞ |
| `ceil(x)` | Round toward +∞ |
| `round(x)` | Round to nearest integer |
| `trunc(x)` | Round toward zero |

#### Utility
| Function | Description |
|----------|-------------|
| `min(a, b)` | Minimum |
| `max(a, b)` | Maximum |
| `clamp(x, lo, hi)` | Clamp x to [lo, hi] |
| `lerp(a, b, t)` | Linear interpolation |
| `rad(x)` | Degrees to radians |
| `deg(x)` | Radians to degrees |

### Operators

| Operator | Description | Precedence |
|----------|-------------|------------|
| `+` | Addition | 1 |
| `-` | Subtraction / unary negation | 1 |
| `*` | Multiplication | 2 |
| `/` | Division | 2 |
| `%` | Modulo | 2 |
| `^` | Exponentiation | 3 |

Operator `%` is available in tokenization and AST but is not in the default `eval.functions` arithmetic path; use `math.fmod` via a variable for modulo on evaluated expressions.

## Common Patterns

### Compile Once, Evaluate Many Times

```lua
local eval = require("luaswift.mathexpr")
local f = eval.compile("sin(x)^2 + cos(x)^2")

-- Verify Pythagorean identity at multiple points
for _, x in ipairs({0, 0.5, 1.0, math.pi}) do
    assert(math.abs(f(x) - 1) < 1e-12)
end
```

### Numerical Root Finding via solve_equation

```lua
local eval = require("luaswift.mathexpr")

-- Find root of x^3 - 2 (cube root of 2)
local r = eval.solve_equation("x^3 - 2 = 0", {}, {initial_guess = 1})
print(r.x)     -- 1.2599210498949

if r.warning then
    print("Warning:", r.warning)
end
```

### Symbolic Substitution Pipeline

```lua
local eval = require("luaswift.mathexpr")

-- Parse once, substitute multiple times
local ast = eval.parse("a*x^2 + b*x + c")
local vars = eval.find_variables(ast)
-- {"a", "b", "c", "x"}

-- Instantiate coefficients (keeps x symbolic)
local inst = eval.substitute(ast, {a = 1, b = -5, c = 6})
print(eval.to_string(inst))                       -- "x^2 - 5*x + 6" (normalised)

-- Solve for roots
local r1 = eval.solve_equation(eval.to_string(inst) .. " = 0", {}, {initial_guess = 2})
local r2 = eval.solve_equation(eval.to_string(inst) .. " = 0", {}, {initial_guess = 4})
print(r1.x, r2.x)                                -- 2   3
```

### Step-by-Step Evaluation

```lua
local eval = require("luaswift.mathexpr")

local steps = eval.solve("2 * (3 + 4)", {show_steps = true, variables = {}})
for _, step in ipairs(steps) do
    if step.result then
        print(step.operation, "→", step.result)
    end
end
```

### LaTeX Expression Evaluation

```lua
local eval = require("luaswift.mathexpr")

local latex = "\\frac{\\sin(x)^{2}}{2}"
local std = eval.latexToStandard(latex)
local f = eval.compile(std)
print(f(math.pi / 2))    -- 0.5
```

### Solving a 2×2 System

```lua
local eval = require("luaswift.mathexpr")

-- x + y = 5
-- 2*x - y = 1
local r = eval.solve_system({"x + y = 5", "2*x - y = 1"})
print(r.x, r.y)    -- 2   3
```

## Error Handling

All functions throw on invalid input; use `pcall` to catch errors.

```lua
local eval = require("luaswift.mathexpr")

-- Parse error
local ok, err = pcall(eval.eval, "2 +")
print(ok, err)      -- false   eval.evaluate parse error: ...

-- Undefined variable
local ok, err = pcall(eval.eval, "x + y", {x = 1})
print(ok, err)      -- false   undefined variable: y

-- Unknown function
local ok, err = pcall(eval.eval, "foo(1)")
print(ok, err)      -- false   unknown function: foo

-- Bad equation
local ok, err = pcall(eval.solve_equation, "2 + 2")
print(ok, err)      -- false   equation parse error: not an equation (no = sign)

-- Multiple unknowns without solve_for
local ok, err = pcall(eval.solve_equation, "a + b = 10")
print(ok, err)      -- false   equation has multiple unknowns: a, b. Specify solve_for ...
```

## See Also

- ``MathExprModule``
- ``MathXModule``
- ``ComplexModule``
- ``SeriesModule``
