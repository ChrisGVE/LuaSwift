//
//  ThalesModuleExtras.swift
//  LuaSwift
//
//  Additional Thales CAS callbacks: series, formatting, ODE, special functions.
//
//  SPDX-License-Identifier: Apache-2.0
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
        let center = args.count > 2 ? args[2].numberValue ?? 0.0 : 0.0
        let order = args.count > 3 ? UInt32(args[3].numberValue ?? 5) : 5
        do {
            let result = try Thales.taylorSeries(
                expr, variable: variable, center: center, order: order)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "center": .number(result.center),
                "terms": .number(Double(result.order))
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
        let order = args.count > 2 ? UInt32(args[2].numberValue ?? 5) : 5
        do {
            let result = try Thales.maclaurinSeries(expr, variable: variable, order: order)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "terms": .number(Double(result.order))
            ])
        } catch {
            throw LuaError.callbackError("cas.maclaurin: \(error)")
        }
    }

    static let laurentCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError(
                "cas.laurent requires (expression, variable[, center, neg_order, pos_order])")
        }
        let center = args.count > 2 ? args[2].numberValue ?? 0.0 : 0.0
        let negOrder = args.count > 3 ? UInt32(args[3].numberValue ?? 3) : 3
        let posOrder = args.count > 4 ? UInt32(args[4].numberValue ?? 3) : 3
        do {
            let result = try Thales.laurentSeries(
                expr, variable: variable, center: center,
                negOrder: negOrder, posOrder: posOrder)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "center": .number(result.center)
            ])
        } catch {
            throw LuaError.callbackError("cas.laurent: \(error)")
        }
    }
}

// MARK: - Extended Series Callbacks (asymptotic, compose, revert, puiseux, residue, convergence_radius)

extension ThalesModule {

    static let asymptoticCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError(
                "cas.asymptotic requires (expression, variable[, direction, terms])")
        }
        let directionStr = args.count > 2 ? args[2].stringValue ?? "pos_infinity" : "pos_infinity"
        let numTerms = args.count > 3 ? UInt32(args[3].numberValue ?? 5) : 5
        let direction: AsymptoticDirection
        switch directionStr {
        case "neg_infinity": direction = .negInfinity
        case "zero": direction = .zero
        default: direction = .posInfinity
        }
        do {
            let result = try Thales.asymptoticSeries(
                expr, variable: variable, direction: direction, numTerms: numTerms)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "direction": .string(result.direction),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex)
            ])
        } catch {
            throw LuaError.callbackError("cas.asymptotic: \(error)")
        }
    }

    static let composeSeriesCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let outer = args[0].stringValue,
              let inner = args[1].stringValue,
              let variable = args[2].stringValue else {
            throw LuaError.callbackError(
                "cas.compose_series requires (outer, inner, variable[, order])")
        }
        let order = args.count > 3 ? UInt32(args[3].numberValue ?? 5) : 5
        do {
            let result = try Thales.composeSeries(
                outer: outer, inner: inner, variable: variable, order: order)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "center": .number(result.center),
                "terms": .number(Double(result.order))
            ])
        } catch {
            throw LuaError.callbackError("cas.compose_series: \(error)")
        }
    }

    static let revertSeriesCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError(
                "cas.revert_series requires (expression, variable[, order])")
        }
        let order = args.count > 2 ? UInt32(args[2].numberValue ?? 5) : 5
        do {
            let result = try Thales.reversionSeries(expr, variable: variable, order: order)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "center": .number(result.center),
                "terms": .number(Double(result.order))
            ])
        } catch {
            throw LuaError.callbackError("cas.revert_series: \(error)")
        }
    }

    static let puiseuxCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError(
                "cas.puiseux requires (expression, variable[, center, order])")
        }
        let center = args.count > 2 ? args[2].numberValue ?? 0.0 : 0.0
        let order = args.count > 3 ? UInt32(args[3].numberValue ?? 5) : 5
        do {
            let result = try Thales.puiseuxSeries(
                expr, variable: variable, center: center, order: order)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "expression": .string(result.series),
                "latex": .string(result.seriesLatex),
                "center": .number(result.center),
                "success": .bool(result.success)
            ])
        } catch {
            throw LuaError.callbackError("cas.puiseux: \(error)")
        }
    }

    static let residueCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError(
                "cas.residue requires (expression, variable[, point])")
        }
        let point = args.count > 2 ? args[2].numberValue ?? 0.0 : 0.0
        do {
            let result = try Thales.residue(expr, variable: variable, at: point)
            return .table([
                "original": .string(result.original),
                "variable": .string(result.variable),
                "point": .number(result.point),
                "value": .string(result.value),
                "latex": .string(result.valueLatex),
                "success": .bool(result.success)
            ])
        } catch {
            throw LuaError.callbackError("cas.residue: \(error)")
        }
    }

    static let convergenceRadiusCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let expr = args[0].stringValue,
              let variable = args[1].stringValue else {
            throw LuaError.callbackError(
                "cas.convergence_radius requires (expression, variable[, center, order])")
        }
        let center = args.count > 2 ? args[2].numberValue ?? 0.0 : 0.0
        let order = args.count > 3 ? UInt32(args[3].numberValue ?? 20) : 20
        do {
            let result = try Thales.convergenceRadius(
                expr, variable: variable, center: center, order: order)
            let radius: LuaValue = result.radius.isNaN ? .nil : .number(result.radius)
            let radiusInf: LuaValue = result.radius.isInfinite ? .bool(true) : .bool(false)
            return .table([
                "expression": .string(result.expression),
                "variable": .string(result.variable),
                "center": .number(result.center),
                "radius": radius,
                "is_entire": .bool(result.isEntire),
                "success": .bool(result.success)
            ])
        } catch {
            throw LuaError.callbackError("cas.convergence_radius: \(error)")
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
            return .number(result.value)
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
        let depVar = args.count > 1 ? args[1].stringValue ?? "y" : "y"
        let indepVar = args.count > 2 ? args[2].stringValue ?? "x" : "x"
        do {
            let result = try Thales.solveODE(
                equation, dependent: depVar, independent: indepVar)
            return .table([
                "equation": .string(result.equation),
                "solution": .string(result.solution),
                "latex": .string(result.solutionLatex),
                "method": .string(result.methodUsed)
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
