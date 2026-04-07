//
//  ThalesModuleLua.swift
//  LuaSwift
//
//  Lua wrapper code for the Thales CAS module.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_THALES

extension ThalesModule {

    // swiftlint:disable:next function_body_length
    static let casLuaWrapper = """
    -- CAS module backed by Thales Computer Algebra System
    if not luaswift then luaswift = {} end

    -- Capture Swift callback references
    local _simplify = _luaswift_cas_simplify
    local _simplify_trig = _luaswift_cas_simplify_trig
    local _solve = _luaswift_cas_solve
    local _solve_with_values = _luaswift_cas_solve_with_values
    local _solve_numerically = _luaswift_cas_solve_numerically
    local _solve_system = _luaswift_cas_solve_system
    local _solve_inequality = _luaswift_cas_solve_inequality
    local _differentiate = _luaswift_cas_differentiate
    local _nth_derivative = _luaswift_cas_nth_derivative
    local _integrate = _luaswift_cas_integrate
    local _definite_integral = _luaswift_cas_definite_integral
    local _limit = _luaswift_cas_limit
    local _limit_to_infinity = _luaswift_cas_limit_to_infinity
    local _gradient = _luaswift_cas_gradient
    local _taylor = _luaswift_cas_taylor
    local _maclaurin = _luaswift_cas_maclaurin
    local _laurent = _luaswift_cas_laurent
    local _to_latex = _luaswift_cas_to_latex
    local _parse_latex = _luaswift_cas_parse_latex
    local _evaluate = _luaswift_cas_evaluate
    local _solve_ode = _luaswift_cas_solve_ode
    local _partial_fractions = _luaswift_cas_partial_fractions

    local cas = {}

    -- Module availability flag
    cas.available = true

    -- Simplification
    function cas.simplify(expr)
        return _simplify(expr)
    end

    function cas.simplify_trig(expr)
        return _simplify_trig(expr)
    end

    -- Equation solving
    function cas.solve(equation, var_or_opts, opts)
        if type(var_or_opts) == "table" and not opts then
            -- cas.solve(equation, {known_values})
            return _solve_with_values(equation, "x", var_or_opts)
        elseif type(var_or_opts) == "string" and type(opts) == "table" then
            -- cas.solve(equation, variable, {known_values})
            return _solve_with_values(equation, var_or_opts, opts)
        else
            -- cas.solve(equation, variable)
            return _solve(equation, var_or_opts or "x")
        end
    end

    function cas.solve_numerically(equation, variable, guess)
        return _solve_numerically(equation, variable or "x", guess or 1.0)
    end

    function cas.solve_system(equations)
        return _solve_system(equations)
    end

    function cas.solve_inequality(inequality, variable)
        return _solve_inequality(inequality, variable or "x")
    end

    -- Calculus
    function cas.differentiate(expr, variable)
        return _differentiate(expr, variable or "x")
    end
    cas.diff = cas.differentiate

    function cas.nth_derivative(expr, variable, order)
        return _nth_derivative(expr, variable or "x", order or 2)
    end

    function cas.integrate(expr, variable)
        return _integrate(expr, variable or "x")
    end

    function cas.definite_integral(expr, variable, lower, upper)
        return _definite_integral(expr, variable or "x", lower, upper)
    end

    function cas.limit(expr, variable, value)
        return _limit(expr, variable or "x", value)
    end

    function cas.limit_to_infinity(expr, variable)
        return _limit_to_infinity(expr, variable or "x")
    end

    function cas.gradient(expr, variables)
        return _gradient(expr, variables)
    end

    -- Series
    function cas.taylor(expr, variable, around, terms)
        return _taylor(expr, variable or "x", around or 0, terms or 5)
    end

    function cas.maclaurin(expr, variable, terms)
        return _maclaurin(expr, variable or "x", terms or 5)
    end

    function cas.laurent(expr, variable, center, neg_order, pos_order)
        return _laurent(expr, variable or "x", center or 0, neg_order or 3, pos_order or 3)
    end

    -- Formatting
    function cas.to_latex(expr)
        return _to_latex(expr)
    end

    function cas.parse_latex(latex)
        return _parse_latex(latex)
    end

    -- Evaluation
    function cas.evaluate(expr, values)
        return _evaluate(expr, values or {})
    end

    -- ODE
    function cas.solve_ode(equation, dependent_var, independent_var)
        return _solve_ode(equation, dependent_var or "y", independent_var or "x")
    end

    -- Special operations
    function cas.partial_fractions(numerator, denominator, variable)
        return _partial_fractions(numerator, denominator, variable or "x")
    end

    -- Store in luaswift namespace
    luaswift.cas = cas

    -- Populate math.cas namespace
    if math then
        math.cas = cas
    end

    package.loaded["thales"] = cas
    package.loaded["luaswift.cas"] = cas

    -- Clean up global Swift function references
    _luaswift_cas_simplify = nil
    _luaswift_cas_simplify_trig = nil
    _luaswift_cas_solve = nil
    _luaswift_cas_solve_with_values = nil
    _luaswift_cas_solve_numerically = nil
    _luaswift_cas_solve_system = nil
    _luaswift_cas_solve_inequality = nil
    _luaswift_cas_differentiate = nil
    _luaswift_cas_nth_derivative = nil
    _luaswift_cas_integrate = nil
    _luaswift_cas_definite_integral = nil
    _luaswift_cas_limit = nil
    _luaswift_cas_limit_to_infinity = nil
    _luaswift_cas_gradient = nil
    _luaswift_cas_taylor = nil
    _luaswift_cas_maclaurin = nil
    _luaswift_cas_laurent = nil
    _luaswift_cas_to_latex = nil
    _luaswift_cas_parse_latex = nil
    _luaswift_cas_evaluate = nil
    _luaswift_cas_solve_ode = nil
    _luaswift_cas_partial_fractions = nil
    """
}

#endif  // LUASWIFT_THALES
