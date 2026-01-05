# SlideRule Module

Slide rule simulation for classic analog computing.

## Overview

The SlideRule module simulates classic mechanical slide rules, the analog computers used by engineers and scientists before electronic calculators. It models the physical scales, cursor positioning, and computational techniques that made slide rules essential tools for multiplication, division, powers, roots, logarithms, and trigonometry.

This module is educational, demonstrating how logarithmic scales enable multiplication through addition of lengths, and useful for understanding the precision limitations of analog computation.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the SlideRule module
ModuleRegistry.installSlideRuleModule(in: engine)
```

## Basic Usage

```lua
local sliderule = require("luaswift.sliderule")

-- Create a scientific slide rule
local rule = sliderule.new({model = "scientific", precision = 3})

-- Basic arithmetic
local product = rule:multiply(2.5, 3.2)   -- 8
local quotient = rule:divide(15, 3)        -- 5

-- Powers and roots
local sq = rule:square(5)                  -- 25
local root = rule:sqrt(25)                 -- 5

-- Trigonometry (degrees)
local sine = rule:sin_deg(30)              -- 0.5
local tangent = rule:tan_deg(45)           -- 1
```

## API Reference

### Creating a Slide Rule

#### sliderule.new(options?)
Creates a new slide rule instance.

**Options:**
- `model` - Predefined scale configuration (default: "scientific")
- `precision` - Decimal places in results (default: 3)
- `scales` - Custom scale list (overrides model)

```lua
-- Scientific slide rule (full featured)
local rule = sliderule.new({model = "scientific"})

-- Basic slide rule (C, D, A, B scales only)
local basic = sliderule.new({model = "basic"})

-- Engineering slide rule
local eng = sliderule.new({model = "engineering"})

-- Higher precision
local precise = sliderule.new({model = "scientific", precision = 4})

-- Custom scales
local custom = sliderule.new({scales = {"C", "D", "S", "T"}})
```

### Predefined Models

| Model | Scales | Purpose |
|-------|--------|---------|
| `basic` | C, D, A, B | Simple multiplication, division, squares |
| `scientific` | C, D, CI, CF, DF, A, B, K, LL1-3, S, T, ST | Full scientific computation |
| `engineering` | C, D, CI, K, A, B, S, T, ST | Engineering calculations |
| `log_log` | C, D, LL0-3 | Powers and exponentials |
| `trig` | C, D, S, T, ST | Trigonometric calculations |

### Basic Arithmetic

#### multiply(a, b)
Multiplies two numbers using C/D scales.

```lua
rule:multiply(2, 3)           -- 6
rule:multiply(2.5, 4)         -- 10
rule:multiply(0.5, 0.5)       -- 0.25
rule:multiply(123, 456)       -- 56088 (approximate)
```

#### divide(a, b)
Divides first number by second using C/D scales.

```lua
rule:divide(10, 2)            -- 5
rule:divide(15, 4)            -- 3.75
rule:divide(100, 8)           -- 12.5
```

#### reciprocal(x)
Calculates 1/x using the CI (inverted) scale.

```lua
rule:reciprocal(4)            -- 0.25
rule:reciprocal(2)            -- 0.5
rule:reciprocal(0.5)          -- 2
```

### Powers and Roots

#### square(x)
Calculates x² using A/D scales.

```lua
rule:square(5)                -- 25
rule:square(12)               -- 144
rule:square(0.5)              -- 0.25
```

#### sqrt(x)
Calculates square root using A/D scales.

```lua
rule:sqrt(25)                 -- 5
rule:sqrt(2)                  -- 1.414
rule:sqrt(144)                -- 12
```

#### cube(x)
Calculates x³ using K/D scales.

```lua
rule:cube(3)                  -- 27
rule:cube(2)                  -- 8
rule:cube(10)                 -- 1000
```

#### cbrt(x)
Calculates cube root using K/D scales.

```lua
rule:cbrt(27)                 -- 3
rule:cbrt(8)                  -- 2
rule:cbrt(1000)               -- 10
```

#### power(base, exponent)
Calculates base^exponent using LL scales.

```lua
rule:power(2, 3)              -- 8
rule:power(10, 2)             -- 100
rule:power(2, 0.5)            -- 1.414 (sqrt(2))
rule:power(2.718, 1)          -- 2.718 (e)
```

### Logarithms and Exponentials

#### ln(x)
Calculates natural logarithm.

```lua
rule:ln(2.718)                -- 1 (approximately)
rule:ln(10)                   -- 2.303
rule:ln(1)                    -- 0
```

#### exp(x)
Calculates e^x using LL scales.

```lua
rule:exp(1)                   -- 2.718
rule:exp(2)                   -- 7.389
rule:exp(0)                   -- 1
```

### Trigonometry

All angles are in degrees.

#### sin_deg(angle)
Calculates sine using S scale (5.74° to 90°).

```lua
rule:sin_deg(30)              -- 0.5
rule:sin_deg(45)              -- 0.707
rule:sin_deg(90)              -- 1
rule:sin_deg(0)               -- 0 (small angle approximation)
```

#### tan_deg(angle)
Calculates tangent using T scale (5.71° to 45°).

```lua
rule:tan_deg(45)              -- 1
rule:tan_deg(30)              -- 0.577
rule:tan_deg(60)              -- 1.732
```

#### small_angle_trig(angle)
Uses ST scale for small angles where sin ≈ tan ≈ angle (radians).

```lua
rule:small_angle_trig(1)      -- 0.017 (radians)
rule:small_angle_trig(5)      -- 0.087 (radians)
```

### Special Operations

#### pi_multiply(x)
Multiplies by π using CF/DF scales.

```lua
rule:pi_multiply(1)           -- 3.142
rule:pi_multiply(2)           -- 6.283 (2π)
rule:pi_multiply(0.5)         -- 1.571 (π/2)
```

### Manual Scale Operations

For direct manipulation of cursor and scales.

#### set(scale, value)
Sets the cursor position on a scale.

```lua
rule:set('D', 2.5)
```

#### read(scale)
Reads the value at current cursor position on a scale.

```lua
rule:set('D', 2.5)
local val = rule:read('C')    -- Reads aligned C scale value
```

#### align_index(scale, value)
Aligns the index (1) of a scale to current cursor position.

```lua
rule:set('D', 2)
rule:align_index('C')         -- Aligns C scale index to 2 on D
```

#### clear()
Resets cursor position and state.

```lua
rule:clear()
```

### Scale Information

#### available_scales()
Returns list of scales on this slide rule.

```lua
local scales = rule:available_scales()
-- {"C", "D", "CI", "A", "B", ...}
```

#### has_scale(name)
Checks if the rule has a specific scale.

```lua
if rule:has_scale("LL3") then
    -- Can compute large powers
end
```

### Available Scales

| Scale | Type | Range | Description |
|-------|------|-------|-------------|
| C, D | log | 1-10 | Basic multiplication/division |
| CI | log_inverse | 1-10 | Reciprocals (1/x) |
| CF, DF | log_folded | π-10π | Folded at π |
| A, B | square | 1-100 | Squares (x²) |
| K | cube | 1-1000 | Cubes (x³) |
| LL0 | loglog | 1.001-1.01 | e^0.001x to e^0.01x |
| LL1 | loglog | 1.01-1.105 | e^0.01x to e^0.1x |
| LL2 | loglog | 1.105-2.718 | e^0.1x to e^x |
| LL3 | loglog | 2.718-22026 | e^x to e^10x |
| S | sine | 5.74°-90° | Sine values |
| T | tangent | 5.71°-45° | Tangent values |
| ST | sine_tan | 0.57°-5.73° | Small angle approximation |

## How Slide Rules Work

### The Principle

Slide rules convert multiplication to addition using logarithms:
- log(a × b) = log(a) + log(b)

Physical lengths represent logarithms. By sliding one scale against another, you add logarithmic lengths, effectively multiplying the values.

### Multiplication Example

To multiply 2 × 3:
1. Set cursor to 2 on D scale
2. Align C scale index (1) to cursor
3. Move cursor to 3 on C scale
4. Read result (6) on D scale

```lua
-- Simulating the manual process
rule:set('D', 2)
rule:align_index('C')
-- Move cursor to 3 on C
rule:set('C', 3)
local result = rule:read('D')  -- 6
```

### Decimal Point Tracking

Slide rules show only significant figures. The user must track decimal places mentally:
- 2 × 3 = 6
- 20 × 3 = 60
- 0.2 × 0.3 = 0.06

The module handles this automatically via normalization.

## Common Patterns

### Chained Calculations

```lua
local rule = sliderule.new()

-- Calculate (12 × 5) / 3
local step1 = rule:multiply(12, 5)  -- 60
local result = rule:divide(step1, 3)  -- 20

-- Calculate √(a² + b²) for a=3, b=4
local a2 = rule:square(3)           -- 9
local b2 = rule:square(4)           -- 16
local sum = a2 + b2                 -- 25 (mental addition)
local result = rule:sqrt(sum)       -- 5
```

### Engineering Calculations

```lua
local rule = sliderule.new({model = "engineering"})

-- Area of circle: A = π r²
local r = 5
local r_squared = rule:square(r)        -- 25
local area = rule:pi_multiply(r_squared)  -- 78.54

-- Force calculation: F = ma
local mass = 12.5
local accel = 9.81
local force = rule:multiply(mass, accel)  -- 122.6
```

### Trigonometric Solutions

```lua
local rule = sliderule.new({model = "trig"})

-- Height from angle and distance
-- h = d × tan(θ)
local distance = 100
local angle = 30
local tan_val = rule:tan_deg(angle)      -- 0.577
local height = rule:multiply(distance, tan_val)  -- 57.7

-- Sine rule: a/sin(A) = b/sin(B)
local a = 10
local A = 30
local B = 45
local sin_A = rule:sin_deg(A)            -- 0.5
local sin_B = rule:sin_deg(B)            -- 0.707
local ratio = rule:divide(a, sin_A)      -- 20
local b = rule:multiply(ratio, sin_B)    -- 14.14
```

### Precision Comparison

```lua
-- Compare slide rule precision to exact calculation
local rule = sliderule.new({precision = 3})

local sr_result = rule:multiply(1.234, 5.678)
local exact = 1.234 * 5.678

print("Slide rule:", sr_result)  -- 7.007
print("Exact:", exact)           -- 7.006652
print("Error:", math.abs(sr_result - exact))  -- ~0.0004

-- Higher precision
local precise = sliderule.new({precision = 4})
local pr_result = precise:multiply(1.234, 5.678)
print("4-digit:", pr_result)     -- 7.0067
```

## Historical Context

Slide rules were invented in the 17th century and remained essential tools until electronic calculators replaced them in the 1970s. Engineers used them to design everything from bridges to spacecraft.

The precision limitation of 3-4 significant figures taught users to:
- Understand meaningful precision in calculations
- Estimate results before computing
- Check reasonableness of answers

This module captures that computational philosophy.

## Error Handling

```lua
-- Invalid values
local ok, err = pcall(function()
    rule:sqrt(-1)  -- Error: invalid value
end)

-- Angles out of range
local ok, err = pcall(function()
    rule:sin_deg(100)  -- Error: must be 0-90
end)

-- Unknown scale
local ok, err = pcall(function()
    rule:set('X', 5)  -- Error: unknown scale
end)
```

## See Also

- ``SlideRuleModule``
- ``MathXModule``
- ``MathExprModule``
