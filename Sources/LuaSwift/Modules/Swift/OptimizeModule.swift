//
//  OptimizeModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import NumericSwift

/// Swift-backed optimization module for LuaSwift.
///
/// Provides numerical optimization functions including scalar minimization,
/// root finding, and multivariate optimization. All algorithms implemented
/// in NumericSwift library, with thin Lua bindings here.
///
/// ## Lua API
///
/// ```lua
/// luaswift.extend_stdlib()
///
/// -- Scalar minimization (Golden section / Brent's method)
/// local result = math.optimize.minimize_scalar(function(x) return (x-2)^2 end, {bracket={0,4}})
/// print(result.x, result.fun, result.success)
///
/// -- Root finding (scalar) - Bisection, Newton, Secant methods
/// local result = math.optimize.root_scalar(function(x) return x^2 - 4 end, {bracket={0,5}})
/// print(result.root, result.converged)
///
/// -- Multivariate minimization (Nelder-Mead)
/// local result = math.optimize.minimize(
///     function(x) return (x[1]-1)^2 + (x[2]-2)^2 end,
///     {0, 0}
/// )
/// print(result.x[1], result.x[2], result.fun)
/// ```
public struct OptimizeModule {

    // MARK: - Registration

    /// Register the optimization module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Register Swift callbacks
        engine.registerFunction(name: "_luaswift_optimize_minimize_scalar", callback: makeMinimizeScalarCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_root_scalar", callback: makeRootScalarCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_minimize", callback: makeMinimizeCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_root", callback: makeRootCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_least_squares", callback: makeLeastSquaresCallback(engine))
        engine.registerFunction(name: "_luaswift_optimize_curve_fit", callback: makeCurveFitCallback(engine))

        // Set up Lua namespace
        do {
            try engine.run("""
                if not luaswift then luaswift = {} end
                if not luaswift.optimize then luaswift.optimize = {} end

                local optimize = luaswift.optimize

                -- minimize_scalar: Scalar function minimization
                function optimize.minimize_scalar(func, options)
                    options = options or {}
                    local result = _luaswift_optimize_minimize_scalar(func,
                        options.method or "brent",
                        options.bracket and options.bracket[1],
                        options.bracket and options.bracket[2],
                        options.xtol or 1e-8,
                        options.maxiter or 500)
                    return result
                end

                -- root_scalar: Scalar root finding
                function optimize.root_scalar(func, options)
                    options = options or {}
                    local result = _luaswift_optimize_root_scalar(func,
                        options.method or "bisect",
                        options.bracket and options.bracket[1],
                        options.bracket and options.bracket[2],
                        options.x0,
                        options.x1,
                        options.xtol or 1e-8,
                        options.maxiter or 100)
                    return result
                end

                -- minimize: Multivariate minimization
                function optimize.minimize(func, x0, options)
                    options = options or {}
                    local result = _luaswift_optimize_minimize(func, x0,
                        options.method or "Nelder-Mead",
                        options.xtol or 1e-8,
                        options.ftol or 1e-8,
                        options.maxiter)
                    return result
                end

                -- root: Multivariate root finding
                function optimize.root(func, x0, options)
                    options = options or {}
                    local result = _luaswift_optimize_root(func, x0,
                        options.method or "hybr",
                        options.tol or 1e-8,
                        options.maxiter or 100)
                    return result
                end

                -- least_squares: Nonlinear least squares
                function optimize.least_squares(residuals, x0, options)
                    options = options or {}
                    local result = _luaswift_optimize_least_squares(residuals, x0,
                        options.ftol or 1e-8,
                        options.xtol or 1e-8,
                        options.maxiter or 100)
                    return result
                end

                -- curve_fit: Fit function to data
                -- Supports both f(x, params) and f(x, a, b, c, ...) calling conventions
                function optimize.curve_fit(func, xdata, ydata, p0, options)
                    options = options or {}
                    -- Wrap function to support expanded form: f(x, a, b, c) -> f(x, params)
                    local wrapped_func = function(x, params)
                        -- Try expanded form first (f(x, a, b, c, ...))
                        local success, result = pcall(function()
                            return func(x, table.unpack(params))
                        end)
                        if success then
                            return result
                        end
                        -- Fall back to array form (f(x, params))
                        return func(x, params)
                    end
                    local result = _luaswift_optimize_curve_fit(wrapped_func, xdata, ydata, p0,
                        options.ftol or 1e-8,
                        options.xtol or 1e-8,
                        options.maxiter or 100)
                    -- Unpack array: [popt, pcov, info]
                    return result[1], result[2], result[3]
                end

                -- Also update math.optimize if it exists
                if math then
                    if not math.optimize then math.optimize = {} end
                    for k, v in pairs(optimize) do
                        math.optimize[k] = v
                    end
                end
                """)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Lua Callbacks

    /// Helper to create a Swift closure from a Lua function reference (1D)
    private static func makeLuaFunction1D(_ engine: LuaEngine, _ funcRef: Int32) -> (Double) -> Double {
        return { x in
            do {
                let result = try engine.callLuaFunction(ref: funcRef, args: [.number(x)])
                return result.numberValue ?? 0
            } catch {
                return 0
            }
        }
    }

    /// Helper to create a Swift closure from a Lua function reference (nD)
    private static func makeLuaFunctionND(_ engine: LuaEngine, _ funcRef: Int32) -> ([Double]) -> Double {
        return { x in
            do {
                let xLua = LuaValue.array(x.map { .number($0) })
                let result = try engine.callLuaFunction(ref: funcRef, args: [xLua])
                return result.numberValue ?? 0
            } catch {
                return 0
            }
        }
    }

    /// Helper to create a Swift closure from a Lua function reference (vector-valued)
    private static func makeLuaFunctionVector(_ engine: LuaEngine, _ funcRef: Int32) -> ([Double]) -> [Double] {
        return { x in
            do {
                let xLua = LuaValue.array(x.map { .number($0) })
                let result = try engine.callLuaFunction(ref: funcRef, args: [xLua])
                if let arr = result.arrayValue {
                    return arr.compactMap { $0.numberValue }
                }
                return x
            } catch {
                return x
            }
        }
    }

    /// Factory function for minimize_scalar callback
    private static func makeMinimizeScalarCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 1,
                  case .luaFunction(let funcRef) = args[0] else {
                throw LuaError.runtimeError("minimize_scalar: expected function")
            }

            let method = args.count > 1 ? args[1].stringValue ?? "brent" : "brent"
            let a = args.count > 2 ? args[2].numberValue ?? -10 : -10
            let b = args.count > 3 ? args[3].numberValue ?? 10 : 10
            let xtol = args.count > 4 ? args[4].numberValue ?? optimDefaultXTol : optimDefaultXTol
            let maxiter = args.count > 5 ? Int(args[5].numberValue ?? Double(optimDefaultMaxIter)) : optimDefaultMaxIter

            let f = makeLuaFunction1D(engine, funcRef)
            let result: MinimizeScalarResult

            if method.lowercased() == "golden" {
                result = NumericSwift.goldenSection(f, a: a, b: b, xtol: xtol, maxiter: maxiter)
            } else {
                result = NumericSwift.brent(f, a: a, b: b, xtol: xtol, maxiter: maxiter)
            }

            return .table([
                "x": .number(result.x),
                "fun": .number(result.fun),
                "nfev": .number(Double(result.nfev)),
                "nit": .number(Double(result.nit)),
                "success": .bool(result.success),
                "message": .string(result.message)
            ])
        }
    }

    /// Factory function for root_scalar callback
    private static func makeRootScalarCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 1,
                  case .luaFunction(let funcRef) = args[0] else {
                throw LuaError.runtimeError("root_scalar: expected function")
            }

            let method = args.count > 1 ? args[1].stringValue ?? "bisect" : "bisect"
            let a = args.count > 2 ? args[2].numberValue : nil
            let b = args.count > 3 ? args[3].numberValue : nil
            let x0 = args.count > 4 ? args[4].numberValue : nil
            let x1 = args.count > 5 ? args[5].numberValue : nil
            let xtol = args.count > 6 ? args[6].numberValue ?? optimDefaultXTol : optimDefaultXTol
            let maxiter = args.count > 7 ? Int(args[7].numberValue ?? 100) : 100

            let f = makeLuaFunction1D(engine, funcRef)
            let result: RootScalarResult

            switch method.lowercased() {
            case "bisect", "brentq":
                guard let aVal = a, let bVal = b else {
                    throw LuaError.runtimeError("bisect requires bracket=[a,b]")
                }
                result = NumericSwift.bisect(f, a: aVal, b: bVal, xtol: xtol, maxiter: maxiter)
            case "newton":
                guard let x0Val = x0 else {
                    throw LuaError.runtimeError("newton requires x0")
                }
                result = NumericSwift.newton(f, x0: x0Val, xtol: xtol, maxiter: maxiter)
            case "secant":
                guard let x0Val = x0 else {
                    throw LuaError.runtimeError("secant requires x0")
                }
                result = NumericSwift.secant(f, x0: x0Val, x1: x1, xtol: xtol, maxiter: maxiter)
            default:
                // Default to bisect if bracket provided, newton if x0 provided
                if let aVal = a, let bVal = b {
                    result = NumericSwift.bisect(f, a: aVal, b: bVal, xtol: xtol, maxiter: maxiter)
                } else if let x0Val = x0 {
                    result = NumericSwift.newton(f, x0: x0Val, xtol: xtol, maxiter: maxiter)
                } else {
                    throw LuaError.runtimeError("root_scalar requires either bracket or x0")
                }
            }

            return .table([
                "root": .number(result.root),
                "iterations": .number(Double(result.iterations)),
                "function_calls": .number(Double(result.functionCalls)),
                "converged": .bool(result.converged),
                "message": .string(result.flag),
                "flag": .string(result.flag)  // Keep for compatibility
            ])
        }
    }

    /// Factory function for minimize callback
    private static func makeMinimizeCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  case .luaFunction(let funcRef) = args[0],
                  let x0Table = args[1].arrayValue else {
                throw LuaError.runtimeError("minimize: expected function and x0 array")
            }

            let x0 = x0Table.compactMap { $0.numberValue }
            guard !x0.isEmpty else {
                throw LuaError.runtimeError("minimize: x0 must be non-empty")
            }

            let xtol = args.count > 3 ? args[3].numberValue ?? optimDefaultXTol : optimDefaultXTol
            let ftol = args.count > 4 ? args[4].numberValue ?? optimDefaultFTol : optimDefaultFTol
            let maxiter = args.count > 5 ? (args[5].isNil ? nil : Int(args[5].numberValue ?? 0)) : nil

            let f = makeLuaFunctionND(engine, funcRef)
            let result = NumericSwift.nelderMead(f, x0: x0, xtol: xtol, ftol: ftol, maxiter: maxiter)

            return .table([
                "x": .array(result.x.map { .number($0) }),
                "fun": .number(result.fun),
                "nfev": .number(Double(result.nfev)),
                "nit": .number(Double(result.nit)),
                "success": .bool(result.success),
                "message": .string(result.message)
            ])
        }
    }

    /// Factory function for root callback
    private static func makeRootCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  case .luaFunction(let funcRef) = args[0],
                  let x0Table = args[1].arrayValue else {
                throw LuaError.runtimeError("root: expected function and x0 array")
            }

            let x0 = x0Table.compactMap { $0.numberValue }
            guard !x0.isEmpty else {
                throw LuaError.runtimeError("root: x0 must be non-empty")
            }

            let tol = args.count > 3 ? args[3].numberValue ?? optimDefaultXTol : optimDefaultXTol
            let maxiter = args.count > 4 ? Int(args[4].numberValue ?? Double(optimDefaultMaxIter)) : optimDefaultMaxIter

            let f = makeLuaFunctionVector(engine, funcRef)
            let result = NumericSwift.newtonMulti(f, x0: x0, tol: tol, maxiter: maxiter)

            return .table([
                "x": .array(result.x.map { .number($0) }),
                "fun": .array(result.fun.map { .number($0) }),
                "success": .bool(result.success),
                "message": .string(result.message),
                "nfev": .number(Double(result.nfev)),
                "nit": .number(Double(result.nit))
            ])
        }
    }

    /// Factory function for least_squares callback
    private static func makeLeastSquaresCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 2,
                  case .luaFunction(let funcRef) = args[0],
                  let x0Table = args[1].arrayValue else {
                throw LuaError.runtimeError("least_squares: expected residuals function and x0 array")
            }

            let x0 = x0Table.compactMap { $0.numberValue }
            guard !x0.isEmpty else {
                throw LuaError.runtimeError("least_squares: x0 must be non-empty")
            }

            let ftol = args.count > 2 ? args[2].numberValue ?? 1e-8 : 1e-8
            let xtol = args.count > 3 ? args[3].numberValue ?? 1e-8 : 1e-8
            let maxiter = args.count > 4 ? Int(args[4].numberValue ?? 100) : 100

            let residuals = makeLuaFunctionVector(engine, funcRef)
            let result = NumericSwift.leastSquares(residuals, x0: x0, ftol: ftol, xtol: xtol, maxiter: maxiter)

            return .table([
                "x": .array(result.x.map { .number($0) }),
                "cost": .number(result.cost),
                "fun": .array(result.fun.map { .number($0) }),
                "jac": .array([]),  // Jacobian placeholder (not computed by this implementation)
                "nfev": .number(Double(result.nfev)),
                "njev": .number(Double(result.njev)),
                "success": .bool(result.success),
                "message": .string(result.message)
            ])
        }
    }

    /// Factory function for curve_fit callback
    private static func makeCurveFitCallback(_ engine: LuaEngine) -> ([LuaValue]) throws -> LuaValue {
        return { args in
            guard args.count >= 4,
                  case .luaFunction(let funcRef) = args[0],
                  let xdataTable = args[1].arrayValue,
                  let ydataTable = args[2].arrayValue,
                  let p0Table = args[3].arrayValue else {
                throw LuaError.runtimeError("curve_fit: expected func, xdata, ydata, p0")
            }

            let xdata = xdataTable.compactMap { $0.numberValue }
            let ydata = ydataTable.compactMap { $0.numberValue }
            let p0 = p0Table.compactMap { $0.numberValue }

            guard !xdata.isEmpty, !ydata.isEmpty, !p0.isEmpty else {
                throw LuaError.runtimeError("curve_fit: arrays must be non-empty")
            }
            guard xdata.count == ydata.count else {
                throw LuaError.runtimeError("curve_fit: xdata and ydata must have same length")
            }

            let ftol = args.count > 4 ? args[4].numberValue ?? 1e-8 : 1e-8
            let xtol = args.count > 5 ? args[5].numberValue ?? 1e-8 : 1e-8
            let maxiter = args.count > 6 ? Int(args[6].numberValue ?? 100) : 100

            // Create model function that calls Lua: f(params, x) -> y
            let modelFunc: ([Double], Double) -> Double = { params, x in
                do {
                    let paramsLua = LuaValue.array(params.map { .number($0) })
                    // Lua function expects (x, params) - x first, then params array
                    let result = try engine.callLuaFunction(ref: funcRef, args: [.number(x), paramsLua])
                    return result.numberValue ?? 0
                } catch {
                    return 0
                }
            }

            let (popt, pcov, info) = NumericSwift.curveFit(modelFunc, xdata: xdata, ydata: ydata, p0: p0, ftol: ftol, xtol: xtol, maxiter: maxiter)

            // Return as multiple values: popt, pcov, info
            let poptLua = LuaValue.array(popt.map { .number($0) })
            let pcovLua = LuaValue.array(pcov.map { row in
                LuaValue.array(row.map { .number($0) })
            })
            let infoLua = LuaValue.table([
                "x": .array(info.x.map { .number($0) }),
                "cost": .number(info.cost),
                "fun": .array(info.fun.map { .number($0) }),
                "nfev": .number(Double(info.nfev)),
                "njev": .number(Double(info.njev)),
                "success": .bool(info.success),
                "message": .string(info.message)
            ])

            // Return as table with multiple values for Lua to unpack
            return .array([poptLua, pcovLua, infoLua])
        }
    }
}
