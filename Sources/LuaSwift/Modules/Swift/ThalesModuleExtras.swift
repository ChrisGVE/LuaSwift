//
//  ThalesModuleExtras.swift
//  LuaSwift
//
//  Additional Thales CAS callbacks: series, formatting, ODE, special functions.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_THALES

import Foundation
import Thales

// MARK: - Series Callbacks

extension ThalesModule {

    static let taylorCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError("cas.taylor requires (expression, variable[, around, terms])")
        }
        let around = args.count > 2 ? args[2].numberValue ?? 0.0 : 0.0
        let terms = args.count > 3 ? UInt32(args[3].numberValue ?? 5) : 5
        do {
            let result = try Thales.taylorSeries(
                of: expr, variable: variable, around: around, terms: terms)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "center": .number(result.center),
                "terms": .number(Double(result.numTerms))
            ])
        } catch {
            throw LuaError.callbackError("cas.taylor: \(error)")
        }
    }

    static let maclaurinCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError("cas.maclaurin requires (expression, variable[, terms])")
        }
        let terms = args.count > 2 ? UInt32(args[2].numberValue ?? 5) : 5
        do {
            let result = try Thales.maclaurinSeries(of: expr, variable: variable, terms: terms)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "terms": .number(Double(result.numTerms))
            ])
        } catch {
            throw LuaError.callbackError("cas.maclaurin: \(error)")
        }
    }

    static let laurentCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError("cas.laurent requires (expression, variable[, around, terms])")
        }
        let around = args.count > 2 ? args[2].numberValue ?? 0.0 : 0.0
        let terms = args.count > 3 ? UInt32(args[3].numberValue ?? 5) : 5
        do {
            let result = try Thales.laurentSeries(
                of: expr, variable: variable, around: around, terms: terms)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "center": .number(result.center),
                "terms": .number(Double(result.numTerms))
            ])
        } catch {
            throw LuaError.callbackError("cas.laurent: \(error)")
        }
    }
}

// MARK: - Formatting Callbacks

extension ThalesModule {

    static let toLatexCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expr = args.first?.stringValue else {
            throw LuaError.callbackError("cas.to_latex requires an expression string")
        }
        do {
            return .string(try Thales.toLatex(expr))
        } catch {
            throw LuaError.callbackError("cas.to_latex: \(error)")
        }
    }

    static let parseLatexCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let latex = args.first?.stringValue else {
            throw LuaError.callbackError("cas.parse_latex requires a LaTeX string")
        }
        do {
            return .string(try Thales.parseLatex(latex))
        } catch {
            throw LuaError.callbackError("cas.parse_latex: \(error)")
        }
    }

    static let evaluateCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expr = args.first?.stringValue else {
            throw LuaError.callbackError("cas.evaluate requires an expression string")
        }
        var values: [String: Double] = [:]
        if args.count > 1, case .table(let tbl) = args[1] {
            for (key, value) in tbl {
                if let n = value.numberValue { values[key] = n }
            }
        }
        do {
            let result = try Thales.evaluate(expr, with: values)
            return .number(result.numericResult)
        } catch {
            throw LuaError.callbackError("cas.evaluate: \(error)")
        }
    }
}

// MARK: - ODE Callbacks

extension ThalesModule {

    static let solveODECallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let equation = args.first?.stringValue else {
            throw LuaError.callbackError("cas.solve_ode requires an ODE string")
        }
        let indepVar = args.count > 1 ? args[1].stringValue ?? "x" : "x"
        let depFunc = args.count > 2 ? args[2].stringValue ?? "y" : "y"
        do {
            let result = try Thales.solveODE(
                equation: equation, independentVar: indepVar, dependentFunc: depFunc)
            return .table([
                "equation": .string(result.equation),
                "solution": .string(result.solution),
                "latex": .string(result.solutionLatex),
                "method": .string(result.method)
            ])
        } catch {
            throw LuaError.callbackError("cas.solve_ode: \(error)")
        }
    }
}

// MARK: - Partial Fractions Callback

extension ThalesModule {

    static let partialFractionsCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let num = args[0].stringValue,
              let den = args[1].stringValue,
              let variable = args[2].stringValue else {
            throw LuaError.callbackError(
                "cas.partial_fractions requires (numerator, denominator, variable)")
        }
        do {
            let result = try Thales.partialFractions(
                numerator: num, denominator: den, variable: variable)
            return .string(result)
        } catch {
            throw LuaError.callbackError("cas.partial_fractions: \(error)")
        }
    }
}

#endif  // LUASWIFT_THALES
