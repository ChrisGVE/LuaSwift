//
//  ThalesModuleCallbacks.swift
//  LuaSwift
//
//  Swift callbacks that bridge Thales CAS operations to Lua.
//
//  SPDX-License-Identifier: Apache-2.0
//

#if LUASWIFT_THALES

import Foundation
import Thales

// MARK: - Simplification Callbacks

extension ThalesModule {

    static let simplifyCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expr = args.first?.stringValue else {
            throw LuaError.callbackError("cas.simplify requires a string expression")
        }
        do {
            let result = try Thales.simplify(expr)
            return .table([
                "original": .string(result.original),
                "expression": .string(result.simplified),
                "latex": .string(result.simplifiedLatex)
            ])
        } catch {
            throw LuaError.callbackError("cas.simplify: \(error)")
        }
    }

    static let simplifyTrigCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expr = args.first?.stringValue else {
            throw LuaError.callbackError("cas.simplify_trig requires a string expression")
        }
        do {
            let result = try Thales.simplifyTrig(expr)
            return .table([
                "original": .string(result.original),
                "expression": .string(result.simplified),
                "latex": .string(result.simplifiedLatex)
            ])
        } catch {
            throw LuaError.callbackError("cas.simplify_trig: \(error)")
        }
    }
}

// MARK: - Solving Callbacks

extension ThalesModule {

    static let solveCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let equation = args.first?.stringValue else {
            throw LuaError.callbackError("cas.solve requires an equation string")
        }
        let variable = args.count > 1 ? args[1].stringValue ?? "x" : "x"
        do {
            let result = try Thales.solve(equation, for: variable)
            return .string(result)
        } catch {
            throw LuaError.callbackError("cas.solve: \(error)")
        }
    }

    static let solveWithValuesCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let equation = args[0].stringValue,
              let variable = args[1].stringValue,
              case .table(let valuesTable) = args[2] else {
            throw LuaError.callbackError(
                "cas.solve_with_values requires (equation, variable, values_table)")
        }
        var values: [String: Double] = [:]
        for (key, value) in valuesTable {
            if let n = value.numberValue { values[key] = n }
        }
        do {
            let result = try Thales.solve(equation, for: variable, knownValues: values)
            return .table([
                "initial": .string(result.initialExpression),
                "result": .string(result.result),
                "steps_json": .string(result.stepsJson),
                "success": .bool(result.success)
            ])
        } catch {
            throw LuaError.callbackError("cas.solve_with_values: \(error)")
        }
    }

    static let solveNumericallyCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let equation = args[0].stringValue,
              let variable = args[1].stringValue,
              let guess = args[2].numberValue else {
            throw LuaError.callbackError(
                "cas.solve_numerically requires (equation, variable, initial_guess)")
        }
        do {
            let result = try Thales.solveNumerically(equation, for: variable, initialGuess: guess)
            return .number(result)
        } catch {
            throw LuaError.callbackError("cas.solve_numerically: \(error)")
        }
    }

    static let solveSystemCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let first = args.first else {
            throw LuaError.callbackError("cas.solve_system requires an array of equations")
        }
        var equations: [String] = []
        if case .array(let arr) = first {
            equations = arr.compactMap { $0.stringValue }
        } else if case .table(let tbl) = first {
            for i in 1...tbl.count {
                if let eq = tbl[String(i)]?.stringValue { equations.append(eq) }
            }
        }
        guard !equations.isEmpty else {
            throw LuaError.callbackError("cas.solve_system requires non-empty equation array")
        }
        do {
            let result = try Thales.solveSystem(equations: equations)
            return .string(result)
        } catch {
            throw LuaError.callbackError("cas.solve_system: \(error)")
        }
    }

    static let solveInequalityCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let inequality = args.first?.stringValue else {
            throw LuaError.callbackError("cas.solve_inequality requires a string")
        }
        let variable = args.count > 1 ? args[1].stringValue ?? "x" : "x"
        do {
            let result = try Thales.solveInequality(inequality, for: variable)
            return .string(result)
        } catch {
            throw LuaError.callbackError("cas.solve_inequality: \(error)")
        }
    }
}

// MARK: - Calculus Callbacks

extension ThalesModule {

    static let differentiateCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expr = args.first?.stringValue else {
            throw LuaError.callbackError("cas.differentiate requires an expression string")
        }
        let variable = args.count > 1 ? args[1].stringValue ?? "x" : "x"
        do {
            let result = try Thales.differentiate(expr, withRespectTo: variable)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.derivative),
                "latex": .string(result.derivativeLatex)
            ])
        } catch {
            throw LuaError.callbackError("cas.differentiate: \(error)")
        }
    }

    static let nthDerivativeCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue,
              let order = args[2].numberValue else {
            throw LuaError.callbackError(
                "cas.nth_derivative requires (expression, variable, order)")
        }
        do {
            let result = try Thales.nthDerivative(
                expr, withRespectTo: variable, order: UInt32(order))
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.derivative),
                "latex": .string(result.derivativeLatex)
            ])
        } catch {
            throw LuaError.callbackError("cas.nth_derivative: \(error)")
        }
    }

    static let integrateCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expr = args.first?.stringValue else {
            throw LuaError.callbackError("cas.integrate requires an expression string")
        }
        let variable = args.count > 1 ? args[1].stringValue ?? "x" : "x"
        do {
            let result = try Thales.integrate(expr, withRespectTo: variable)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.integral),
                "latex": .string(result.integralLatex),
                "success": .bool(result.success)
            ])
        } catch {
            throw LuaError.callbackError("cas.integrate: \(error)")
        }
    }

    static let definiteIntegralCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 4,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue,
              let lower = args[2].numberValue,
              let upper = args[3].numberValue else {
            throw LuaError.callbackError(
                "cas.definite_integral requires (expression, variable, lower, upper)")
        }
        do {
            let result = try Thales.definiteIntegral(
                expr, withRespectTo: variable, from: lower, to: upper)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "value": .string(result.value),
                "latex": .string(result.valueLatex),
                "numeric_value": .number(result.numericValue)
            ])
        } catch {
            throw LuaError.callbackError("cas.definite_integral: \(error)")
        }
    }

    static let limitCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue,
              let value = args[2].numberValue else {
            throw LuaError.callbackError("cas.limit requires (expression, variable, value)")
        }
        do {
            let result = try Thales.limit(expr, as: variable, approaches: value)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.value),
                "latex": .string(result.valueLatex)
            ])
        } catch {
            throw LuaError.callbackError("cas.limit: \(error)")
        }
    }

    static let limitToInfinityCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expr = args.first?.stringValue else {
            throw LuaError.callbackError("cas.limit_to_infinity requires an expression")
        }
        let variable = args.count > 1 ? args[1].stringValue ?? "x" : "x"
        do {
            let result = try Thales.limitToInfinity(expr, as: variable)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.value),
                "latex": .string(result.valueLatex)
            ])
        } catch {
            throw LuaError.callbackError("cas.limit_to_infinity: \(error)")
        }
    }

    static let gradientCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expr = args.first?.stringValue else {
            throw LuaError.callbackError("cas.gradient requires an expression string")
        }
        var variables: [String] = []
        if args.count > 1 {
            if case .array(let arr) = args[1] {
                variables = arr.compactMap { $0.stringValue }
            } else if case .table(let tbl) = args[1] {
                for i in 1...tbl.count {
                    if let v = tbl[String(i)]?.stringValue { variables.append(v) }
                }
            }
        }
        guard !variables.isEmpty else {
            throw LuaError.callbackError("cas.gradient requires variables array")
        }
        do {
            let result = try Thales.gradient(expr, variables: variables)
            return .string(result)
        } catch {
            throw LuaError.callbackError("cas.gradient: \(error)")
        }
    }
}

#endif  // LUASWIFT_THALES
