# MathExpr Module

Mathematical expression parsing and evaluation.

## Overview

The MathExpr module provides tools for parsing and evaluating mathematical expressions from strings. It supports standard mathematical operators, built-in functions, constants, and user-defined variables. Expressions can be evaluated directly or compiled to functions for repeated use.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the MathExpr module
ModuleRegistry.installMathExprModule(in: engine)
```

## Basic Usage

```lua
local mathexpr = require("luaswift.mathexpr")

-- Direct evaluation
local result = mathexpr.eval("2 + 3 * 4")     -- 14
local result = mathexpr.eval("sin(pi/2)")      -- 1

-- With variables
local result = mathexpr.eval("x^2 + 2*x + 1", {x = 3})  -- 16

-- Compile to function for repeated use
local f = mathexpr.compile("x^2")
print(f(2))   -- 4
print(f(5))   -- 25
```

## API Reference

### Expression Evaluation

#### eval(expr, vars?)
Evaluates a mathematical expression string and returns the result.

**Parameters:**
- `expr` - The expression string to evaluate
- `vars` - Optional table of variable values

```lua
-- Basic arithmetic
mathexpr.eval("2 + 3")              -- 5
mathexpr.eval("10 - 4 * 2")         -- 2
mathexpr.eval("2^10")               -- 1024

-- With variables
mathexpr.eval("x + y", {x = 3, y = 4})           -- 7
mathexpr.eval("r * cos(theta)", {r = 5, theta = 0})  -- 5

-- Using constants
mathexpr.eval("2 * pi")             -- 6.283...
mathexpr.eval("e^2")                -- 7.389...

-- Using functions
mathexpr.eval("sqrt(16)")           -- 4
mathexpr.eval("sin(pi/6)")          -- 0.5
mathexpr.eval("log(e)")             -- 1
```

#### compile(expr)
Compiles an expression into a reusable function.

**Returns:** A function that accepts either:
- A number (used as variable `x`)
- A table of variable values

```lua
-- Single variable (x)
local f = mathexpr.compile("x^2 - 4*x + 4")
print(f(0))    -- 4
print(f(2))    -- 0
print(f(5))    -- 9

-- Multi-variable
local g = mathexpr.compile("a*x + b")
print(g({a = 2, x = 3, b = 1}))  -- 7

-- Use in numeric computations
local sine = mathexpr.compile("sin(x)")
for x = 0, 6.28, 0.1 do
    print(x, sine(x))
end
```

### Tokenization and Parsing

For advanced use cases, you can access the tokenizer and parser directly.

#### tokenize(expr)
Tokenizes an expression string into a list of tokens.

```lua
local tokens = mathexpr.tokenize("2 * x + sin(y)")
for i, token in ipairs(tokens) do
    print(i, token.type, token.value)
end
-- 1   number     2
-- 2   operator   *
-- 3   variable   x
-- 4   operator   +
-- 5   function   sin
-- 6   lparen     nil
-- 7   variable   y
-- 8   rparen     nil
```

**Token types:**
- `number` - Numeric literal (value in `token.value`)
- `operator` - Mathematical operator (+, -, *, /, ^)
- `function` - Function name (sin, cos, etc.)
- `variable` - User variable
- `constant` - Built-in constant (pi, e, etc.)
- `lparen` - Left parenthesis
- `rparen` - Right parenthesis
- `comma` - Argument separator

#### parse(tokens)
Parses tokens into an Abstract Syntax Tree (AST).

```lua
local tokens = mathexpr.tokenize("2 * x + 1")
local ast = mathexpr.parse(tokens)
-- Returns nested table structure representing the expression tree
```

#### eval_ast(ast, vars?)
Evaluates an AST with optional variables.

```lua
local tokens = mathexpr.tokenize("x^2")
local ast = mathexpr.parse(tokens)
print(mathexpr.eval_ast(ast, {x = 3}))  -- 9
print(mathexpr.eval_ast(ast, {x = 5}))  -- 25
```

### Built-in Constants

Access via `mathexpr.constants`:

| Constant | Value | Description |
|----------|-------|-------------|
| `pi` | 3.14159... | Pi (π) |
| `e` | 2.71828... | Euler's number |
| `inf` | ∞ | Positive infinity |
| `nan` | NaN | Not a Number |

```lua
print(mathexpr.constants.pi)    -- 3.1415926535898
print(mathexpr.constants.e)     -- 2.718281828...

-- Use in expressions
mathexpr.eval("2 * pi * r", {r = 5})  -- Circumference
```

### Built-in Functions

Access via `mathexpr.functions`:

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

#### Exponential and Logarithmic
| Function | Description |
|----------|-------------|
| `exp(x)` | e^x |
| `log(x)` | Natural logarithm |
| `ln(x)` | Natural logarithm (alias) |
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
| `sign(x)` | Sign (-1, 0, or 1) |
| `floor(x)` | Floor (round down) |
| `ceil(x)` | Ceiling (round up) |
| `round(x)` | Round to nearest integer |

#### Other
| Function | Description |
|----------|-------------|
| `min(a, b)` | Minimum of two values |
| `max(a, b)` | Maximum of two values |
| `rad(x)` | Degrees to radians |
| `deg(x)` | Radians to degrees |

### Operators

| Operator | Description | Precedence |
|----------|-------------|------------|
| `+` | Addition | 1 |
| `-` | Subtraction | 1 |
| `*` | Multiplication | 2 |
| `/` | Division | 2 |
| `^` | Exponentiation | 3 (right-associative) |

Unary minus is supported: `-x`, `2 * -3`

## Common Patterns

### Numerical Integration (Simpson's Rule)

```lua
local function integrate(expr, a, b, n)
    n = n or 100
    local f = mathexpr.compile(expr)
    local h = (b - a) / n
    local sum = f(a) + f(b)

    for i = 1, n - 1 do
        local x = a + i * h
        sum = sum + (i % 2 == 0 and 2 or 4) * f(x)
    end

    return sum * h / 3
end

local area = integrate("x^2", 0, 1, 100)  -- ≈ 0.333...
```

### Function Plotting Data

```lua
local function generate_plot_data(expr, x_min, x_max, points)
    local f = mathexpr.compile(expr)
    local data = {}
    local step = (x_max - x_min) / (points - 1)

    for i = 0, points - 1 do
        local x = x_min + i * step
        data[i + 1] = {x = x, y = f(x)}
    end

    return data
end

local sine_data = generate_plot_data("sin(x)", 0, 2*math.pi, 100)
```

### Root Finding (Newton-Raphson)

```lua
local function find_root(expr, deriv_expr, initial, tolerance)
    tolerance = tolerance or 1e-10
    local f = mathexpr.compile(expr)
    local df = mathexpr.compile(deriv_expr)

    local x = initial
    for i = 1, 100 do
        local fx = f(x)
        if math.abs(fx) < tolerance then
            return x
        end
        x = x - fx / df(x)
    end
    return x
end

-- Find root of x^2 - 2 (should be √2 ≈ 1.414)
local root = find_root("x^2 - 2", "2*x", 1)
print(root)  -- 1.4142135623731
```

### Expression Validation

```lua
local function validate_expression(expr)
    local ok, err = pcall(function()
        mathexpr.tokenize(expr)
    end)
    return ok, err
end

local valid, error = validate_expression("2 + 3 * x")
print(valid)  -- true

local valid, error = validate_expression("2 + @ * x")
print(valid)  -- false
print(error)  -- contains "unexpected character"
```

### Custom Variables Calculator

```lua
local calculator = {
    vars = {},
    history = {}
}

function calculator:set(name, expr)
    local result = mathexpr.eval(expr, self.vars)
    self.vars[name] = result
    table.insert(self.history, {name = name, expr = expr, result = result})
    return result
end

function calculator:get(name)
    return self.vars[name]
end

function calculator:eval(expr)
    return mathexpr.eval(expr, self.vars)
end

-- Usage
calculator:set("radius", "5")
calculator:set("area", "pi * radius^2")
print(calculator:get("area"))  -- 78.539...
```

## Error Handling

The module throws errors for invalid expressions:

```lua
-- Invalid character
local ok, err = pcall(function()
    mathexpr.eval("2 + @")
end)
-- err: "unexpected character '@' at position 4"

-- Undefined variable
local ok, err = pcall(function()
    mathexpr.eval("x + y", {x = 1})  -- y not defined
end)
-- err: "undefined variable: y"

-- Unknown function
local ok, err = pcall(function()
    mathexpr.eval("foo(x)", {x = 1})
end)
-- err: "unknown function: foo"
```

## See Also

- ``MathExprModule``
- ``MathXModule``
- ``ComplexModule``
