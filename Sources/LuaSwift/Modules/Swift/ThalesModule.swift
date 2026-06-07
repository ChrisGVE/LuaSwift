//
//  ThalesModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-04-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//

#if LUASWIFT_THALES

import Foundation
import Thales

/// CAS module for LuaSwift backed by the Thales Computer Algebra System.
///
/// Provides symbolic simplification, equation solving, calculus, series
/// expansions, and LaTeX formatting to Lua scripts.
///
/// ## Usage
///
/// ```lua
/// local cas = math.cas
///
/// local simplified = cas.simplify("x + x + x")  -- "3*x"
/// local deriv = cas.differentiate("x^3", "x")    -- {expression = "3*x^2", ...}
/// local sol = cas.solve("2*x + 5 = 13", "x")     -- "x = 4"
/// ```
public struct ThalesModule: LuaSwiftModule {

    // MARK: - Registration

    /// Register the CAS module with a LuaEngine.
    /// - Throws: An error if the module's Lua setup code fails to run.
    public static func install(in engine: LuaEngine) throws {
        // Simplification
        engine.registerFunction(name: "_luaswift_cas_simplify", callback: simplifyCallback)
        engine.registerFunction(name: "_luaswift_cas_simplify_trig", callback: simplifyTrigCallback)

        // Equation solving
        engine.registerFunction(name: "_luaswift_cas_solve", callback: solveCallback)
        engine.registerFunction(name: "_luaswift_cas_solve_with_values", callback: solveWithValuesCallback)
        engine.registerFunction(name: "_luaswift_cas_solve_numerically", callback: solveNumericallyCallback)
        engine.registerFunction(name: "_luaswift_cas_solve_system", callback: solveSystemCallback)
        engine.registerFunction(name: "_luaswift_cas_solve_inequality", callback: solveInequalityCallback)

        // Calculus
        engine.registerFunction(name: "_luaswift_cas_differentiate", callback: differentiateCallback)
        engine.registerFunction(name: "_luaswift_cas_nth_derivative", callback: nthDerivativeCallback)
        engine.registerFunction(name: "_luaswift_cas_integrate", callback: integrateCallback)
        engine.registerFunction(name: "_luaswift_cas_definite_integral", callback: definiteIntegralCallback)
        engine.registerFunction(name: "_luaswift_cas_limit", callback: limitCallback)
        engine.registerFunction(name: "_luaswift_cas_limit_to_infinity", callback: limitToInfinityCallback)
        engine.registerFunction(name: "_luaswift_cas_gradient", callback: gradientCallback)

        // Series
        engine.registerFunction(name: "_luaswift_cas_taylor", callback: taylorCallback)
        engine.registerFunction(name: "_luaswift_cas_maclaurin", callback: maclaurinCallback)
        engine.registerFunction(name: "_luaswift_cas_laurent", callback: laurentCallback)
        engine.registerFunction(name: "_luaswift_cas_asymptotic", callback: asymptoticCallback)
        engine.registerFunction(name: "_luaswift_cas_compose_series", callback: composeSeriesCallback)
        engine.registerFunction(name: "_luaswift_cas_revert_series", callback: revertSeriesCallback)
        engine.registerFunction(name: "_luaswift_cas_puiseux", callback: puiseuxCallback)
        engine.registerFunction(name: "_luaswift_cas_residue", callback: residueCallback)
        engine.registerFunction(name: "_luaswift_cas_convergence_radius", callback: convergenceRadiusCallback)

        // Formatting
        engine.registerFunction(name: "_luaswift_cas_to_latex", callback: toLatexCallback)
        engine.registerFunction(name: "_luaswift_cas_parse_latex", callback: parseLatexCallback)
        engine.registerFunction(name: "_luaswift_cas_evaluate", callback: evaluateCallback)

        // ODE
        engine.registerFunction(name: "_luaswift_cas_solve_ode", callback: solveODECallback)

        // Special functions
        engine.registerFunction(name: "_luaswift_cas_partial_fractions", callback: partialFractionsCallback)

        // Set up the Lua namespace
        try engine.run(casLuaWrapper)
    }

    /// Deprecated alias for ``install(in:)`` that swallows setup failures.
    ///
    /// - Parameter engine: The Lua engine to register with
    public static func register(in engine: LuaEngine) {
        do { try install(in: engine) } catch {
            #if DEBUG
                print("[LuaSwift] ThalesModule setup failed: \(error)")
            #endif
        }
    }
}

#endif  // LUASWIFT_THALES
