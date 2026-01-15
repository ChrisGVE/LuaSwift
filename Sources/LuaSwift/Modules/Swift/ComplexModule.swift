//
//  ComplexModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import NumericSwift

/// Optimized complex number module for LuaSwift.
///
/// Provides high-performance complex number operations using Swift's native math (Darwin).
///
/// ## Usage
///
/// ```lua
/// local complex = require("luaswift.complex")
///
/// local z1 = complex.new(3, 4)
/// local z2 = complex.from_polar(5, math.pi/4)
/// print(z1 + z2)
/// print(z1:abs())  -- 5
/// print(z1:exp())
/// ```
public struct ComplexModule {

    // MARK: - Registration

    /// Register the complex module in the given engine.
    public static func register(in engine: LuaEngine) {
        // Basic operations
        engine.registerFunction(name: "_luaswift_complex_create", callback: createCallback)
        engine.registerFunction(name: "_luaswift_complex_from_polar", callback: fromPolarCallback)

        // Arithmetic
        engine.registerFunction(name: "_luaswift_complex_add", callback: addCallback)
        engine.registerFunction(name: "_luaswift_complex_sub", callback: subCallback)
        engine.registerFunction(name: "_luaswift_complex_mul", callback: mulCallback)
        engine.registerFunction(name: "_luaswift_complex_div", callback: divCallback)
        engine.registerFunction(name: "_luaswift_complex_neg", callback: negCallback)

        // Properties
        engine.registerFunction(name: "_luaswift_complex_abs", callback: absCallback)
        engine.registerFunction(name: "_luaswift_complex_arg", callback: argCallback)
        engine.registerFunction(name: "_luaswift_complex_conj", callback: conjCallback)
        engine.registerFunction(name: "_luaswift_complex_polar", callback: polarCallback)

        // Powers
        engine.registerFunction(name: "_luaswift_complex_pow", callback: powCallback)
        engine.registerFunction(name: "_luaswift_complex_sqrt", callback: sqrtCallback)

        // Exponential and logarithmic
        engine.registerFunction(name: "_luaswift_complex_exp", callback: expCallback)
        engine.registerFunction(name: "_luaswift_complex_log", callback: logCallback)

        // Trigonometric
        engine.registerFunction(name: "_luaswift_complex_sin", callback: sinCallback)
        engine.registerFunction(name: "_luaswift_complex_cos", callback: cosCallback)
        engine.registerFunction(name: "_luaswift_complex_tan", callback: tanCallback)
        engine.registerFunction(name: "_luaswift_complex_asin", callback: asinCallback)
        engine.registerFunction(name: "_luaswift_complex_acos", callback: acosCallback)
        engine.registerFunction(name: "_luaswift_complex_atan", callback: atanCallback)

        // Hyperbolic
        engine.registerFunction(name: "_luaswift_complex_sinh", callback: sinhCallback)
        engine.registerFunction(name: "_luaswift_complex_cosh", callback: coshCallback)
        engine.registerFunction(name: "_luaswift_complex_tanh", callback: tanhCallback)

        // Set up the luaswift.complex namespace
        do {
            try engine.run(complexLuaWrapper)
        } catch {
            // Module setup failed - functions still available as globals
        }
    }

    // MARK: - Helper Functions

    /// Extract complex number from Lua value (either native .complex or table representation)
    private static func extractComplex(_ value: LuaValue) -> (re: Double, im: Double)? {
        // Handle native complex type
        if let (re, im) = value.complexValue {
            return (re, im)
        }
        // Fallback for table representation
        guard let table = value.tableValue,
              let re = table["re"]?.numberValue,
              let im = table["im"]?.numberValue else { return nil }
        return (re, im)
    }

    /// Convert complex number to Lua table
    private static func complexToLua(_ re: Double, _ im: Double) -> LuaValue {
        return .table(["re": .number(re), "im": .number(im)])
    }

    // MARK: - Basic Operations Callbacks

    private static let createCallback: ([LuaValue]) -> LuaValue = { args in
        let re = args.first?.numberValue ?? 0
        let im = args.count > 1 ? (args[1].numberValue ?? 0) : 0
        return complexToLua(re, im)
    }

    private static let fromPolarCallback: ([LuaValue]) -> LuaValue = { args in
        guard let r = args.first?.numberValue,
              let theta = args.count > 1 ? args[1].numberValue : nil else {
            return .nil
        }
        let result = Complex.polar(r: r, theta: theta)
        return complexToLua(result.re, result.im)
    }

    // MARK: - Arithmetic Callbacks

    private static let addCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let z1 = extractComplex(args[0]),
              let z2 = extractComplex(args[1]) else { return .nil }
        let result = Complex(re: z1.re, im: z1.im) + Complex(re: z2.re, im: z2.im)
        return complexToLua(result.re, result.im)
    }

    private static let subCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let z1 = extractComplex(args[0]),
              let z2 = extractComplex(args[1]) else { return .nil }
        let result = Complex(re: z1.re, im: z1.im) - Complex(re: z2.re, im: z2.im)
        return complexToLua(result.re, result.im)
    }

    private static let mulCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let z1 = extractComplex(args[0]),
              let z2 = extractComplex(args[1]) else { return .nil }
        let result = Complex(re: z1.re, im: z1.im) * Complex(re: z2.re, im: z2.im)
        return complexToLua(result.re, result.im)
    }

    private static let divCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let z1 = extractComplex(args[0]),
              let z2 = extractComplex(args[1]) else { return .nil }
        let denom = z2.re * z2.re + z2.im * z2.im
        guard denom != 0 else { return .nil }
        let result = Complex(re: z1.re, im: z1.im) / Complex(re: z2.re, im: z2.im)
        return complexToLua(result.re, result.im)
    }

    private static let negCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = -Complex(re: z.re, im: z.im)
        return complexToLua(result.re, result.im)
    }

    // MARK: - Properties Callbacks

    private static let absCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        return .number(Complex(re: z.re, im: z.im).abs)
    }

    private static let argCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        return .number(Complex(re: z.re, im: z.im).arg)
    }

    private static let conjCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).conj
        return complexToLua(result.re, result.im)
    }

    private static let polarCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let c = Complex(re: z.re, im: z.im)
        return .array([.number(c.abs), .number(c.arg)])
    }

    // MARK: - Powers Callbacks

    private static let powCallback: ([LuaValue]) -> LuaValue = { args in
        guard args.count >= 2,
              let z = extractComplex(args[0]),
              let n = args[1].numberValue else { return .nil }
        let result = Complex(re: z.re, im: z.im).pow(n)
        return complexToLua(result.re, result.im)
    }

    private static let sqrtCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).sqrt
        return complexToLua(result.re, result.im)
    }

    // MARK: - Exponential and Logarithmic Callbacks

    private static let expCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).exp
        return complexToLua(result.re, result.im)
    }

    private static let logCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let c = Complex(re: z.re, im: z.im)
        guard c.abs > 0 else { return .nil }
        let result = c.log
        return complexToLua(result.re, result.im)
    }

    // MARK: - Trigonometric Callbacks

    private static let sinCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).sin
        return complexToLua(result.re, result.im)
    }

    private static let cosCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).cos
        return complexToLua(result.re, result.im)
    }

    private static let tanCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let c = Complex(re: z.re, im: z.im)
        // Check for division by zero in tan
        let cosVal = c.cos
        guard cosVal.abs > 1e-15 else { return .nil }
        let result = c.tan
        return complexToLua(result.re, result.im)
    }

    private static let asinCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).asin
        // Check for NaN (shouldn't happen but guard just in case)
        guard !result.re.isNaN && !result.im.isNaN else { return .nil }
        return complexToLua(result.re, result.im)
    }

    private static let acosCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).acos
        guard !result.re.isNaN && !result.im.isNaN else { return .nil }
        return complexToLua(result.re, result.im)
    }

    private static let atanCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).atan
        guard !result.re.isNaN && !result.im.isNaN else { return .nil }
        return complexToLua(result.re, result.im)
    }

    // MARK: - Hyperbolic Callbacks

    private static let sinhCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).sinh
        return complexToLua(result.re, result.im)
    }

    private static let coshCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let result = Complex(re: z.re, im: z.im).cosh
        return complexToLua(result.re, result.im)
    }

    private static let tanhCallback: ([LuaValue]) -> LuaValue = { args in
        guard let z = extractComplex(args[0]) else { return .nil }
        let c = Complex(re: z.re, im: z.im)
        // Check for division by zero in tanh
        let coshVal = c.cosh
        guard coshVal.abs > 1e-15 else { return .nil }
        let result = c.tanh
        return complexToLua(result.re, result.im)
    }

    // MARK: - Lua Wrapper Code

    private static let complexLuaWrapper = """
    -- Create luaswift.complex namespace
    if not luaswift then luaswift = {} end
    luaswift.complex = {}
    local complex = luaswift.complex

    -- Store references to Swift functions
    local _create = _luaswift_complex_create
    local _from_polar = _luaswift_complex_from_polar
    local _add = _luaswift_complex_add
    local _sub = _luaswift_complex_sub
    local _mul = _luaswift_complex_mul
    local _div = _luaswift_complex_div
    local _neg = _luaswift_complex_neg
    local _abs = _luaswift_complex_abs
    local _arg = _luaswift_complex_arg
    local _conj = _luaswift_complex_conj
    local _polar = _luaswift_complex_polar
    local _pow = _luaswift_complex_pow
    local _sqrt = _luaswift_complex_sqrt
    local _exp = _luaswift_complex_exp
    local _log = _luaswift_complex_log
    local _sin = _luaswift_complex_sin
    local _cos = _luaswift_complex_cos
    local _tan = _luaswift_complex_tan
    local _asin = _luaswift_complex_asin
    local _acos = _luaswift_complex_acos
    local _atan = _luaswift_complex_atan
    local _sinh = _luaswift_complex_sinh
    local _cosh = _luaswift_complex_cosh
    local _tanh = _luaswift_complex_tanh

    -- Complex number metatable
    local complex_mt = {
        __add = function(a, b)
            if type(a) == "number" then a = complex.new(a, 0) end
            if type(b) == "number" then b = complex.new(b, 0) end
            local r = _add(a, b)
            return complex.new(r.re, r.im)
        end,
        __sub = function(a, b)
            if type(a) == "number" then a = complex.new(a, 0) end
            if type(b) == "number" then b = complex.new(b, 0) end
            local r = _sub(a, b)
            return complex.new(r.re, r.im)
        end,
        __mul = function(a, b)
            if type(a) == "number" then a = complex.new(a, 0) end
            if type(b) == "number" then b = complex.new(b, 0) end
            local r = _mul(a, b)
            return complex.new(r.re, r.im)
        end,
        __div = function(a, b)
            if type(a) == "number" then a = complex.new(a, 0) end
            if type(b) == "number" then b = complex.new(b, 0) end
            local r = _div(a, b)
            if not r then error("Division by zero") end
            return complex.new(r.re, r.im)
        end,
        __unm = function(a)
            local r = _neg(a)
            return complex.new(r.re, r.im)
        end,
        __eq = function(a, b)
            if type(b) == "number" then b = complex.new(b, 0) end
            return a.re == b.re and a.im == b.im
        end,
        __tostring = function(a)
            if a.im >= 0 then
                return string.format("%.4f+%.4fi", a.re, a.im)
            else
                return string.format("%.4f%.4fi", a.re, a.im)
            end
        end,
        __index = {
            abs = function(self) return _abs(self) end,
            arg = function(self) return _arg(self) end,
            conj = function(self)
                local r = _conj(self)
                return complex.new(r.re, r.im)
            end,
            polar = function(self) return _polar(self) end,
            pow = function(self, n)
                local r = _pow(self, n)
                return complex.new(r.re, r.im)
            end,
            sqrt = function(self)
                local r = _sqrt(self)
                return complex.new(r.re, r.im)
            end,
            exp = function(self)
                local r = _exp(self)
                return complex.new(r.re, r.im)
            end,
            log = function(self)
                local r = _log(self)
                if not r then error("Logarithm of zero") end
                return complex.new(r.re, r.im)
            end,
            sin = function(self)
                local r = _sin(self)
                return complex.new(r.re, r.im)
            end,
            cos = function(self)
                local r = _cos(self)
                return complex.new(r.re, r.im)
            end,
            tan = function(self)
                local r = _tan(self)
                if not r then error("Tangent undefined") end
                return complex.new(r.re, r.im)
            end,
            asin = function(self)
                local r = _asin(self)
                if not r then error("Arcsine undefined") end
                return complex.new(r.re, r.im)
            end,
            acos = function(self)
                local r = _acos(self)
                if not r then error("Arccosine undefined") end
                return complex.new(r.re, r.im)
            end,
            atan = function(self)
                local r = _atan(self)
                if not r then error("Arctangent undefined") end
                return complex.new(r.re, r.im)
            end,
            sinh = function(self)
                local r = _sinh(self)
                return complex.new(r.re, r.im)
            end,
            cosh = function(self)
                local r = _cosh(self)
                return complex.new(r.re, r.im)
            end,
            tanh = function(self)
                local r = _tanh(self)
                if not r then error("Hyperbolic tangent undefined") end
                return complex.new(r.re, r.im)
            end,
            clone = function(self) return complex.new(self.re, self.im) end
        }
    }

    -- Factory function
    function complex.new(re, im)
        local c = {re = re or 0, im = im or 0, __luaswift_type = "complex"}
        setmetatable(c, complex_mt)
        return c
    end

    -- Polar form constructor
    function complex.from_polar(r, theta)
        local c = _from_polar(r, theta)
        return complex.new(c.re, c.im)
    end

    -- Constants
    complex.i = complex.new(0, 1)

    -- Make available via require
    package.loaded["luaswift.complex"] = complex
    """
}
