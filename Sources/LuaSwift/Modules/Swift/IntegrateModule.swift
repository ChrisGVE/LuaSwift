//
//  IntegrateModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import NumericSwift

/// Swift-backed numerical integration module for LuaSwift.
///
/// Provides numerical integration functions including adaptive quadrature,
/// multiple integration, and ODE solvers. All algorithms implemented in
/// NumericSwift library, with thin Lua bindings here.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- Single integration (adaptive Gauss-Kronrod)
/// local result, error = math.integrate.quad(function(x) return x^2 end, 0, 1)
/// print(result, error)  -- 0.333..., ~1e-14
///
/// -- Double integration
/// local result, error = math.integrate.dblquad(
///     function(y, x) return x * y end,
///     0, 1,   -- x limits
///     0, 1    -- y limits
/// )
///
/// -- Triple integration
/// local result, error = math.integrate.tplquad(
///     function(z, y, x) return x * y * z end,
///     0, 1, 0, 1, 0, 1
/// )
/// ```
public struct IntegrateModule {

    // MARK: - Helper: Convert String to ODEMethod

    private static func methodFromString(_ str: String) -> ODEMethod {
        switch str.uppercased() {
        case "RK23": return .rk23
        case "RK4": return .rk4
        default: return .rk45
        }
    }

    // MARK: - Registration

    /// Register the integration module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks - use closures that capture the engine
        engine.registerFunction(name: "_luaswift_integrate_quad", callback: makeQuadCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_dblquad", callback: makeDblquadCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_tplquad", callback: makeTplquadCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_fixed_quad", callback: makeFixedQuadCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_romberg", callback: makeRombergCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_simps", callback: simpsCallback)
        engine.registerFunction(name: "_luaswift_integrate_trapz", callback: trapzCallback)
        engine.registerFunction(name: "_luaswift_integrate_solve_ivp", callback: makeSolveIVPCallback(engine))
        engine.registerFunction(name: "_luaswift_integrate_odeint", callback: makeOdeintCallback(engine))

        // Set up Lua namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.integrate then luaswift.integrate = {} end

                local integrate = luaswift.integrate

                -- quad: Adaptive quadrature
                -- Returns: value, error (scipy-style)
                function integrate.quad(f, a, b, options)
                    options = options or {}
                    local result = _luaswift_integrate_quad(f, a, b,
                        options.epsabs or 1.49e-8,
                        options.epsrel or 1.49e-8,
                        options.limit or 50)
                    return result.value, result.error
                end

                -- dblquad: Double integration
                -- Returns: value, error (scipy-style)
                function integrate.dblquad(f, xa, xb, ya, yb, options)
                    options = options or {}
                    local result = _luaswift_integrate_dblquad(f, xa, xb, ya, yb,
                        options.epsabs or 1.49e-8,
                        options.epsrel or 1.49e-8)
                    return result.value, result.error
                end

                -- tplquad: Triple integration
                -- Returns: value, error (scipy-style)
                function integrate.tplquad(f, xa, xb, ya, yb, za, zb, options)
                    options = options or {}
                    local result = _luaswift_integrate_tplquad(f, xa, xb, ya, yb, za, zb,
                        options.epsabs or 1.49e-8,
                        options.epsrel or 1.49e-8)
                    return result.value, result.error
                end

                -- fixed_quad: Fixed-order Gauss quadrature
                -- Returns: single value (scipy-style)
                function integrate.fixed_quad(f, a, b, n)
                    return _luaswift_integrate_fixed_quad(f, a, b, n or 5)
                end

                -- romberg: Romberg integration
                -- Returns: value, error (scipy-style)
                function integrate.romberg(f, a, b, options)
                    options = options or {}
                    local result = _luaswift_integrate_romberg(f, a, b,
                        options.tol or 1e-8,
                        options.divmax or 10)
                    return result.value, result.error
                end

                -- simps: Simpson's rule
                function integrate.simps(y, x, dx)
                    return _luaswift_integrate_simps(y, x, dx)
                end

                -- trapz: Trapezoidal rule
                function integrate.trapz(y, x, dx)
                    return _luaswift_integrate_trapz(y, x, dx)
                end

                -- solve_ivp: ODE solver
                function integrate.solve_ivp(fun, t_span, y0, options)
                    options = options or {}
                    return _luaswift_integrate_solve_ivp(fun, t_span, y0,
                        options.method or "RK45",
                        options.t_eval,
                        options.max_step or math.huge,
                        options.rtol or 1e-3,
                        options.atol or 1e-6,
                        options.first_step)
                end

                -- odeint: scipy-style ODE solver
                function integrate.odeint(func, y0, t, options)
                    options = options or {}
                    local result = _luaswift_integrate_odeint(func, y0, t,
                        options.rtol or 1.49e-8,
                        options.atol or 1.49e-8,
                        options.args,
                        options.full_output or false)
                    if options.full_output then
                        -- result is {y, info}, unpack to two return values
                        return result[1], result[2]
                    else
                        return result
                    end
                end

                -- Also update math.integrate if it exists
                if math then
                    if not math.integrate then math.integrate = {} end
                    for k, v in pairs(integrate) do
                        math.integrate[k] = v
                    end
                end
                """)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Lua Callbacks

    /// Helper to create a Swift closure from a Lua function reference
    private static func makeLuaFunction(_ engine: LuaEngine, _ funcRef: Int32) -> (Double) -> Double {
        return { x in
            do {
                let result = try engine.callLuaFunction(ref: funcRef, args: [.number(x)])
                return result.numberValue ?? 0
            } catch {
                return 0
            }
        }
    }

    /// Factory function for quad callback
    /// Supports both real and complex-valued integrands.
    /// Complex integrands return {re=..., im=...} tables; result is {re=..., im=...}.
    private static func makeQuadCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let a = args[1].numberValue,
                  let b = args[2].numberValue else {
                throw LuaError.runtimeError("quad: expected function, lower, upper")
            }

            let epsabs = args.count > 3 ? args[3].numberValue ?? quadDefaultEpsAbs : quadDefaultEpsAbs
            let epsrel = args.count > 4 ? args[4].numberValue ?? quadDefaultEpsRel : quadDefaultEpsRel
            let limit = args.count > 5 ? Int(args[5].numberValue ?? Double(quadDefaultLimit)) : quadDefaultLimit

            // Sample the function at midpoint to detect if it returns complex values
            let midpoint = (a + b) / 2.0
            let sampleResult: LuaValue
            do {
                sampleResult = try engine.callLuaFunction(ref: funcRef, args: [.number(midpoint)])
            } catch {
                throw LuaError.runtimeError("quad: error evaluating integrand")
            }

            // Check if result is a complex table {re=..., im=...}
            if let table = sampleResult.tableValue,
               table["re"]?.numberValue != nil || table["im"]?.numberValue != nil {
                // Complex integrand: integrate real and imaginary parts separately
                let fReal: (Double) -> Double = { x in
                    do {
                        let result = try engine.callLuaFunction(ref: funcRef, args: [.number(x)])
                        if let t = result.tableValue {
                            return t["re"]?.numberValue ?? 0
                        }
                        return result.numberValue ?? 0
                    } catch {
                        return 0
                    }
                }
                let fImag: (Double) -> Double = { x in
                    do {
                        let result = try engine.callLuaFunction(ref: funcRef, args: [.number(x)])
                        if let t = result.tableValue {
                            return t["im"]?.numberValue ?? 0
                        }
                        return 0
                    } catch {
                        return 0
                    }
                }

                let resultReal = NumericSwift.quad(fReal, a, b, epsabs: epsabs, epsrel: epsrel, limit: limit)
                let resultImag = NumericSwift.quad(fImag, a, b, epsabs: epsabs, epsrel: epsrel, limit: limit)

                // Return complex result with combined error estimate
                let combinedError = sqrt(resultReal.error * resultReal.error + resultImag.error * resultImag.error)
                return .table([
                    "value": .table(["re": .number(resultReal.value), "im": .number(resultImag.value)]),
                    "error": .number(combinedError),
                    "neval": .number(Double(resultReal.neval + resultImag.neval))
                ])
            } else {
                // Real integrand
                let f = makeLuaFunction(engine, funcRef)
                let result = NumericSwift.quad(f, a, b, epsabs: epsabs, epsrel: epsrel, limit: limit)

                return .table([
                    "value": .number(result.value),
                    "error": .number(result.error),
                    "neval": .number(Double(result.neval))
                ])
            }
        }
    }

    /// Factory function for dblquad callback
    private static func makeDblquadCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 5,
                  case .luaFunction(let funcRef) = args[0],
                  let xa = args[1].numberValue,
                  let xb = args[2].numberValue else {
                throw LuaError.runtimeError("dblquad: expected function, xa, xb, ya, yb")
            }

            let epsabs = args.count > 5 ? args[5].numberValue ?? quadDefaultEpsAbs : quadDefaultEpsAbs
            let epsrel = args.count > 6 ? args[6].numberValue ?? quadDefaultEpsRel : quadDefaultEpsRel

            // ya and yb can be numbers or functions
            let yaFunc: (Double) -> Double
            let ybFunc: (Double) -> Double

            if let yaNum = args[3].numberValue {
                yaFunc = { _ in yaNum }
            } else if case .luaFunction(let ref) = args[3] {
                yaFunc = makeLuaFunction(engine, ref)
            } else {
                throw LuaError.runtimeError("dblquad: ya must be number or function")
            }

            if let ybNum = args[4].numberValue {
                ybFunc = { _ in ybNum }
            } else if case .luaFunction(let ref) = args[4] {
                ybFunc = makeLuaFunction(engine, ref)
            } else {
                throw LuaError.runtimeError("dblquad: yb must be number or function")
            }

            let f: (Double, Double) -> Double = { y, x in
                do {
                    let result = try engine.callLuaFunction(ref: funcRef, args: [.number(y), .number(x)])
                    return result.numberValue ?? 0
                } catch {
                    return 0
                }
            }

            let result = NumericSwift.dblquad(f, xa: xa, xb: xb, ya: yaFunc, yb: ybFunc, epsabs: epsabs, epsrel: epsrel)

            return .table([
                "value": .number(result.value),
                "error": .number(result.error),
                "neval": .number(Double(result.neval))
            ])
        }
    }

    /// Factory function for tplquad callback
    private static func makeTplquadCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 7,
                  case .luaFunction(let funcRef) = args[0],
                  let xa = args[1].numberValue,
                  let xb = args[2].numberValue else {
                throw LuaError.runtimeError("tplquad: expected function, xa, xb, ya, yb, za, zb")
            }

            let epsabs = args.count > 7 ? args[7].numberValue ?? quadDefaultEpsAbs : quadDefaultEpsAbs
            let epsrel = args.count > 8 ? args[8].numberValue ?? quadDefaultEpsRel : quadDefaultEpsRel

            // Parse ya, yb (functions of x or constants)
            let yaFunc: (Double) -> Double
            let ybFunc: (Double) -> Double

            if let yaNum = args[3].numberValue {
                yaFunc = { _ in yaNum }
            } else if case .luaFunction(let ref) = args[3] {
                yaFunc = makeLuaFunction(engine, ref)
            } else {
                throw LuaError.runtimeError("tplquad: ya must be number or function")
            }

            if let ybNum = args[4].numberValue {
                ybFunc = { _ in ybNum }
            } else if case .luaFunction(let ref) = args[4] {
                ybFunc = makeLuaFunction(engine, ref)
            } else {
                throw LuaError.runtimeError("tplquad: yb must be number or function")
            }

            // Parse za, zb (functions of x,y or constants)
            let zaFunc: (Double, Double) -> Double
            let zbFunc: (Double, Double) -> Double

            if let zaNum = args[5].numberValue {
                zaFunc = { _, _ in zaNum }
            } else if case .luaFunction(let ref) = args[5] {
                zaFunc = { x, y in
                    do {
                        let result = try engine.callLuaFunction(ref: ref, args: [.number(x), .number(y)])
                        return result.numberValue ?? 0
                    } catch {
                        return 0
                    }
                }
            } else {
                throw LuaError.runtimeError("tplquad: za must be number or function")
            }

            if let zbNum = args[6].numberValue {
                zbFunc = { _, _ in zbNum }
            } else if case .luaFunction(let ref) = args[6] {
                zbFunc = { x, y in
                    do {
                        let result = try engine.callLuaFunction(ref: ref, args: [.number(x), .number(y)])
                        return result.numberValue ?? 0
                    } catch {
                        return 0
                    }
                }
            } else {
                throw LuaError.runtimeError("tplquad: zb must be number or function")
            }

            let f: (Double, Double, Double) -> Double = { z, y, x in
                do {
                    let result = try engine.callLuaFunction(ref: funcRef, args: [.number(z), .number(y), .number(x)])
                    return result.numberValue ?? 0
                } catch {
                    return 0
                }
            }

            let result = NumericSwift.tplquad(f, xa: xa, xb: xb, ya: yaFunc, yb: ybFunc, za: zaFunc, zb: zbFunc, epsabs: epsabs, epsrel: epsrel)

            return .table([
                "value": .number(result.value),
                "error": .number(result.error),
                "neval": .number(Double(result.neval))
            ])
        }
    }

    /// Factory function for fixed_quad callback
    private static func makeFixedQuadCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let a = args[1].numberValue,
                  let b = args[2].numberValue else {
                throw LuaError.runtimeError("fixed_quad: expected function, a, b")
            }

            let n = args.count > 3 ? Int(args[3].numberValue ?? 5) : 5

            let f = makeLuaFunction(engine, funcRef)
            let result = NumericSwift.fixedQuad(f, a, b, n: n)

            return .number(result)
        }
    }

    /// Factory function for romberg callback
    private static func makeRombergCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let a = args[1].numberValue,
                  let b = args[2].numberValue else {
                throw LuaError.runtimeError("romberg: expected function, a, b")
            }

            let tol = args.count > 3 ? args[3].numberValue ?? 1e-8 : 1e-8
            let divmax = args.count > 4 ? Int(args[4].numberValue ?? 10) : 10

            let f = makeLuaFunction(engine, funcRef)
            let result = NumericSwift.romberg(f, a, b, tol: tol, divmax: divmax)

            return .table([
                "value": .number(result.value),
                "error": .number(result.error),
                "neval": .number(Double(result.neval))
            ])
        }
    }

    /// Static callback for simps (doesn't need engine - no Lua functions)
    private static func simpsCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1,
              let yTable = args[0].arrayValue else {
            throw LuaError.runtimeError("simps: expected array of values")
        }

        let y = yTable.compactMap { $0.numberValue }
        guard y.count >= 3 else {
            throw LuaError.runtimeError("simps: need at least 3 points")
        }

        if args.count > 1, let xTable = args[1].arrayValue {
            let x = xTable.compactMap { $0.numberValue }
            return .number(NumericSwift.simps(y, x: x))
        } else {
            let dx = args.count > 2 ? args[2].numberValue ?? 1 : 1
            return .number(NumericSwift.simps(y, dx: dx))
        }
    }

    /// Static callback for trapz (doesn't need engine - no Lua functions)
    private static func trapzCallback(_ args: [LuaValue]) throws -> LuaValue {
        guard args.count >= 1,
              let yTable = args[0].arrayValue else {
            throw LuaError.runtimeError("trapz: expected array of values")
        }

        let y = yTable.compactMap { $0.numberValue }
        guard y.count >= 2 else {
            throw LuaError.runtimeError("trapz: need at least 2 points")
        }

        if args.count > 1, let xTable = args[1].arrayValue {
            let x = xTable.compactMap { $0.numberValue }
            return .number(NumericSwift.trapz(y, x: x))
        } else {
            let dx = args.count > 2 ? args[2].numberValue ?? 1 : 1
            return .number(NumericSwift.trapz(y, dx: dx))
        }
    }

    /// Factory function for solve_ivp callback
    private static func makeSolveIVPCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let tSpanTable = args[1].arrayValue,
                  tSpanTable.count >= 2,
                  let t0 = tSpanTable[0].numberValue,
                  let tf = tSpanTable[1].numberValue,
                  let y0Table = args[2].arrayValue else {
                throw LuaError.runtimeError("solve_ivp: expected function, t_span, y0")
            }

            let y0 = y0Table.compactMap { $0.numberValue }
            guard !y0.isEmpty else {
                throw LuaError.runtimeError("solve_ivp: y0 must be non-empty array")
            }

            let methodStr = args.count > 3 ? args[3].stringValue ?? "RK45" : "RK45"
            let method = methodFromString(methodStr)
            let tEval: [Double]? = args.count > 4 ? args[4].arrayValue?.compactMap { $0.numberValue } : nil
            let maxStep = args.count > 5 ? args[5].numberValue ?? .infinity : .infinity
            let rtol = args.count > 6 ? args[6].numberValue ?? 1e-3 : 1e-3
            let atol = args.count > 7 ? args[7].numberValue ?? 1e-6 : 1e-6
            let firstStep: Double? = args.count > 8 ? args[8].numberValue : nil

            let f: ([Double], Double) -> [Double] = { y, t in
                do {
                    let yLua = LuaValue.array(y.map { .number($0) })
                    let result = try engine.callLuaFunction(ref: funcRef, args: [.number(t), yLua])
                    if let arr = result.arrayValue {
                        return arr.compactMap { $0.numberValue }
                    }
                    return y
                } catch {
                    return y
                }
            }

            let result = NumericSwift.solveIVP(f, tSpan: (t0, tf), y0: y0, method: method, tEval: tEval,
                                               maxStep: maxStep, rtol: rtol, atol: atol, firstStep: firstStep)

            return .table([
                "t": .array(result.t.map { .number($0) }),
                "y": .array(result.y.map { row in .array(row.map { .number($0) }) }),
                "success": .bool(result.success),
                "message": .string(result.message),
                "nfev": .number(Double(result.nfev))
            ])
        }
    }

    /// Factory function for odeint callback
    private static func makeOdeintCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 3,
                  case .luaFunction(let funcRef) = args[0],
                  let y0Table = args[1].arrayValue,
                  let tTable = args[2].arrayValue else {
                throw LuaError.runtimeError("odeint: expected function, y0, t")
            }

            let y0 = y0Table.compactMap { $0.numberValue }
            let t = tTable.compactMap { $0.numberValue }

            guard !y0.isEmpty && t.count >= 2 else {
                throw LuaError.runtimeError("odeint: y0 must be non-empty, t must have at least 2 points")
            }

            let rtol = args.count > 3 ? args[3].numberValue ?? 1.49e-8 : 1.49e-8
            let atol = args.count > 4 ? args[4].numberValue ?? 1.49e-8 : 1.49e-8

            // Parse optional args array (passed to the function)
            let extraArgs: [LuaValue] = args.count > 5 ? (args[5].arrayValue ?? []) : []

            // Parse full_output flag
            let fullOutput = args.count > 6 ? args[6].boolValue ?? false : false

            // Track function evaluation count
            var nfev = 0

            // odeint uses func(y, t, ...) not func(t, y)
            let f: ([Double], Double) -> [Double] = { y, tVal in
                nfev += 1
                do {
                    let yLua = LuaValue.array(y.map { .number($0) })
                    var funcArgs: [LuaValue] = [yLua, .number(tVal)]
                    funcArgs.append(contentsOf: extraArgs)
                    let result = try engine.callLuaFunction(ref: funcRef, args: funcArgs)
                    if let arr = result.arrayValue {
                        return arr.compactMap { $0.numberValue }
                    }
                    return y
                } catch {
                    return y
                }
            }

            let result = NumericSwift.odeint(f, y0: y0, t: t, rtol: rtol, atol: atol)

            let yResult = LuaValue.array(result.map { row in .array(row.map { .number($0) }) })

            if fullOutput {
                // Return (y, info) where info contains nfe
                return .array([yResult, .table(["nfe": .number(Double(nfev))])])
            } else {
                return yResult
            }
        }
    }
}
