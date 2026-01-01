-- complex.lua - Complex Number Arithmetic for Lua 5.4.7
-- Copyright (c) 2025 LuaSwift Project
-- Licensed under the MIT License
--
-- A pure Lua module for complex number operations.
-- Supports arithmetic operators, trigonometric functions, and conversions.
-- Designed for educational apps on iOS/macOS via LuaSwift wrapper.

local complex = {}

-- Internal: Check if value is a complex number
local function iscomplex(z)
    return type(z) == "table" and getmetatable(z) == complex
end

-- Internal: Ensure value is complex (convert real numbers)
local function tocomplex(z)
    if iscomplex(z) then
        return z
    elseif type(z) == "number" then
        return complex.new(z, 0)
    else
        error("Cannot convert " .. type(z) .. " to complex number")
    end
end

-- Create a new complex number
-- @param re: real part
-- @param im: imaginary part (default 0)
-- @return: complex number
function complex.new(re, im)
    local z = {_re = re or 0, _im = im or 0}
    return setmetatable(z, complex)
end

-- Create complex number from polar form (module function)
-- Also serves as instance method to convert to polar form
-- Usage: complex.polar(r, theta) -> new complex from polar
-- Usage: z:polar() -> returns r, theta
-- @param r_or_self: magnitude (module) or complex number (instance)
-- @param theta: angle in radians (module) or nil (instance)
-- @return: complex number (module) or r, theta (instance)
function complex.polar(r_or_self, theta)
    -- If called as instance method (z:polar()), first arg is the complex number
    if iscomplex(r_or_self) then
        local z = r_or_self
        local r = math.sqrt(z._re * z._re + z._im * z._im)
        local angle = math.atan(z._im, z._re)
        return r, angle
    end
    -- Otherwise called as module function complex.polar(r, theta)
    local r = r_or_self
    return complex.new(r * math.cos(theta), r * math.sin(theta))
end

-- Parse complex number from string
-- Supports formats: "3+4i", "3-4i", "3", "4i", "-4i", "3 + 4i"
-- @param str: string representation
-- @return: complex number or nil, error message
function complex.parse(str)
    if type(str) ~= "string" then
        return nil, "Expected string"
    end

    -- Remove whitespace
    str = str:gsub("%s+", "")

    -- Handle pure imaginary: "4i" or "-4i" or "i" or "-i"
    local im_only = str:match("^([%-%+]?[%d%.]*)i$")
    if im_only then
        if im_only == "" or im_only == "+" then
            return complex.new(0, 1)
        elseif im_only == "-" then
            return complex.new(0, -1)
        else
            return complex.new(0, tonumber(im_only))
        end
    end

    -- Handle real + imaginary: "3+4i" or "3-4i"
    local re, sign, im = str:match("^([%-%+]?[%d%.]+)([%+%-])([%d%.]*)i$")
    if re then
        local re_num = tonumber(re)
        local im_num = tonumber(im)
        if im == "" then im_num = 1 end
        if sign == "-" then im_num = -im_num end
        return complex.new(re_num, im_num)
    end

    -- Handle pure real: "3" or "-3.5"
    local re_only = tonumber(str)
    if re_only then
        return complex.new(re_only, 0)
    end

    return nil, "Invalid complex number format: " .. str
end

-- Metatable index for .re and .im access
complex.__index = function(z, key)
    if key == "re" then
        return z._re
    elseif key == "im" then
        return z._im
    else
        return complex[key]
    end
end

-- Metatable newindex to prevent modification of re/im directly
complex.__newindex = function(z, key, value)
    if key == "re" or key == "im" then
        error("Complex numbers are immutable. Use complex.new() to create a new number.")
    else
        rawset(z, key, value)
    end
end

-- Magnitude (absolute value) |z|
-- @return: magnitude as number
function complex:abs()
    return math.sqrt(self._re * self._re + self._im * self._im)
end

-- Argument (angle in radians)
-- @return: angle in radians
function complex:arg()
    return math.atan(self._im, self._re)
end

-- Complex conjugate
-- @return: complex number
function complex:conj()
    return complex.new(self._re, -self._im)
end

-- String representation
-- @return: string like "3+4i"
function complex:tostring()
    local re, im = self._re, self._im

    if im == 0 then
        return tostring(re)
    elseif re == 0 then
        if im == 1 then
            return "i"
        elseif im == -1 then
            return "-i"
        else
            return tostring(im) .. "i"
        end
    else
        if im == 1 then
            return tostring(re) .. "+i"
        elseif im == -1 then
            return tostring(re) .. "-i"
        elseif im > 0 then
            return tostring(re) .. "+" .. tostring(im) .. "i"
        else
            return tostring(re) .. tostring(im) .. "i"
        end
    end
end

complex.__tostring = complex.tostring

-- Equality comparison
function complex.__eq(a, b)
    a, b = tocomplex(a), tocomplex(b)
    return a._re == b._re and a._im == b._im
end

-- Addition
function complex.__add(a, b)
    a, b = tocomplex(a), tocomplex(b)
    return complex.new(a._re + b._re, a._im + b._im)
end

-- Subtraction
function complex.__sub(a, b)
    a, b = tocomplex(a), tocomplex(b)
    return complex.new(a._re - b._re, a._im - b._im)
end

-- Multiplication
-- (a + bi)(c + di) = (ac - bd) + (ad + bc)i
function complex.__mul(a, b)
    a, b = tocomplex(a), tocomplex(b)
    return complex.new(
        a._re * b._re - a._im * b._im,
        a._re * b._im + a._im * b._re
    )
end

-- Division
-- (a + bi)/(c + di) = ((ac + bd) + (bc - ad)i) / (c^2 + d^2)
function complex.__div(a, b)
    a, b = tocomplex(a), tocomplex(b)
    local denom = b._re * b._re + b._im * b._im
    if denom == 0 then
        error("Division by zero")
    end
    return complex.new(
        (a._re * b._re + a._im * b._im) / denom,
        (a._im * b._re - a._re * b._im) / denom
    )
end

-- Negation
function complex.__unm(a)
    return complex.new(-a._re, -a._im)
end

-- Power (complex exponentiation)
-- z^n = r^n * (cos(n*theta) + i*sin(n*theta)) for real n
-- z^w = exp(w * log(z)) for complex w
function complex.__pow(a, b)
    a = tocomplex(a)

    -- If exponent is a real number, use De Moivre's formula
    if type(b) == "number" then
        local r, theta = a:polar()
        local new_r = r ^ b
        local new_theta = b * theta
        return complex.new(new_r * math.cos(new_theta), new_r * math.sin(new_theta))
    end

    -- For complex exponent: z^w = exp(w * log(z))
    b = tocomplex(b)
    return complex.exp(b * complex.log(a))
end

-- Square root
-- sqrt(z) = sqrt(|z|) * (cos(arg(z)/2) + i*sin(arg(z)/2))
function complex.sqrt(z)
    z = tocomplex(z)
    local r, theta = z:polar()
    local new_r = math.sqrt(r)
    local new_theta = theta / 2
    return complex.new(new_r * math.cos(new_theta), new_r * math.sin(new_theta))
end

-- Exponential
-- exp(a + bi) = exp(a) * (cos(b) + i*sin(b))
function complex.exp(z)
    z = tocomplex(z)
    local exp_re = math.exp(z._re)
    return complex.new(exp_re * math.cos(z._im), exp_re * math.sin(z._im))
end

-- Natural logarithm
-- log(z) = log|z| + i*arg(z)
function complex.log(z)
    z = tocomplex(z)
    local r, theta = z:polar()
    if r == 0 then
        error("Logarithm of zero is undefined")
    end
    return complex.new(math.log(r), theta)
end

-- Sine (complex)
-- sin(z) = (exp(iz) - exp(-iz)) / (2i)
function complex.sin(z)
    z = tocomplex(z)
    local i = complex.new(0, 1)
    local iz = i * z
    return (complex.exp(iz) - complex.exp(-iz)) / complex.new(0, 2)
end

-- Cosine (complex)
-- cos(z) = (exp(iz) + exp(-iz)) / 2
function complex.cos(z)
    z = tocomplex(z)
    local i = complex.new(0, 1)
    local iz = i * z
    return (complex.exp(iz) + complex.exp(-iz)) / complex.new(2, 0)
end

-- Tangent (complex)
-- tan(z) = sin(z) / cos(z)
function complex.tan(z)
    return complex.sin(z) / complex.cos(z)
end

-- Hyperbolic sine
-- sinh(z) = (exp(z) - exp(-z)) / 2
function complex.sinh(z)
    z = tocomplex(z)
    return (complex.exp(z) - complex.exp(-z)) / complex.new(2, 0)
end

-- Hyperbolic cosine
-- cosh(z) = (exp(z) + exp(-z)) / 2
function complex.cosh(z)
    z = tocomplex(z)
    return (complex.exp(z) + complex.exp(-z)) / complex.new(2, 0)
end

-- Hyperbolic tangent
-- tanh(z) = sinh(z) / cosh(z)
function complex.tanh(z)
    return complex.sinh(z) / complex.cosh(z)
end

-- Inverse sine (arcsin)
-- asin(z) = -i * log(iz + sqrt(1 - z^2))
function complex.asin(z)
    z = tocomplex(z)
    local i = complex.new(0, 1)
    local one = complex.new(1, 0)
    return -i * complex.log(i * z + complex.sqrt(one - z * z))
end

-- Inverse cosine (arccos)
-- acos(z) = -i * log(z + sqrt(z^2 - 1))
function complex.acos(z)
    z = tocomplex(z)
    local i = complex.new(0, 1)
    local one = complex.new(1, 0)
    return -i * complex.log(z + complex.sqrt(z * z - one))
end

-- Inverse tangent (arctan)
-- atan(z) = (i/2) * log((i + z) / (i - z))
function complex.atan(z)
    z = tocomplex(z)
    local i = complex.new(0, 1)
    local half_i = complex.new(0, 0.5)
    return half_i * complex.log((i + z) / (i - z))
end

-- Make the module callable: complex(re, im) creates a new complex number
setmetatable(complex, {
    __call = function(_, re, im)
        return complex.new(re, im)
    end
})

return complex
