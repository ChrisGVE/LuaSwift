//
//  MathExprModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-04.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Swift-backed mathematical expression module for LuaSwift.
///
/// Provides tokenization and parsing of mathematical expressions for evaluation.
/// Supports standard math operators, functions, constants, and variables.
///
/// ## Usage
///
/// ```lua
/// local mathexpr = require("luaswift.mathexpr")
///
/// -- Tokenize an expression
/// local tokens = mathexpr.tokenize("sin(x) + 2*pi")
///
/// -- Evaluate with variables
/// local result = mathexpr.eval("x^2 + 2*x + 1", {x = 3})  -- 16
///
/// -- Create a function from expression
/// local f = mathexpr.compile("sin(x)")
/// print(f(0))        -- 0
/// print(f(math.pi))  -- ~0
/// ```
public struct MathExprModule {

    // MARK: - Token Types

    /// Token types for mathematical expression parsing
    public enum Token: Equatable {
        case number(Double)
        case `operator`(String)
        case function(String)
        case lparen
        case rparen
        case comma
        case variable(String)
        case constant(String)

        /// String description for debugging
        public var description: String {
            switch self {
            case .number(let n):
                return "number(\(n))"
            case .operator(let op):
                return "operator(\(op))"
            case .function(let name):
                return "function(\(name))"
            case .lparen:
                return "lparen"
            case .rparen:
                return "rparen"
            case .comma:
                return "comma"
            case .variable(let name):
                return "variable(\(name))"
            case .constant(let name):
                return "constant(\(name))"
            }
        }
    }

    // MARK: - Known Functions and Constants

    /// Known mathematical functions
    private static let knownFunctions: Set<String> = [
        // Trigonometric
        "sin", "cos", "tan",
        "asin", "acos", "atan", "atan2",
        "sinh", "cosh", "tanh",
        "asinh", "acosh", "atanh",
        // Exponential and logarithmic
        "exp", "log", "log10", "log2", "ln",
        // Power and roots
        "sqrt", "cbrt", "pow",
        // Absolute value and sign
        "abs", "sign", "floor", "ceil", "round", "trunc",
        // Min/max and interpolation
        "min", "max", "clamp", "lerp",
        // Other
        "rad", "deg"
    ]

    /// Known mathematical constants
    private static let knownConstants: Set<String> = [
        "pi", "e", "inf", "nan"
    ]

    // MARK: - Tokenizer

    /// Tokenize a mathematical expression string.
    ///
    /// - Parameter expression: The expression to tokenize
    /// - Returns: Array of tokens
    /// - Throws: Error if expression contains invalid characters
    public static func tokenize(_ expression: String) throws -> [Token] {
        var tokens: [Token] = []
        var index = expression.startIndex

        while index < expression.endIndex {
            let char = expression[index]

            // Skip whitespace
            if char.isWhitespace {
                index = expression.index(after: index)
                continue
            }

            // Numbers (including decimals and scientific notation)
            if char.isNumber || (char == "." && index < expression.endIndex) {
                let (number, endIndex) = try parseNumber(expression, startingAt: index)
                tokens.append(.number(number))
                index = endIndex
                continue
            }

            // Operators
            if "+-*/^=".contains(char) {
                tokens.append(.operator(String(char)))
                index = expression.index(after: index)
                continue
            }

            // Parentheses
            if char == "(" {
                tokens.append(.lparen)
                index = expression.index(after: index)
                continue
            }

            if char == ")" {
                tokens.append(.rparen)
                index = expression.index(after: index)
                continue
            }

            // Comma (for multi-argument functions)
            if char == "," {
                tokens.append(.comma)
                index = expression.index(after: index)
                continue
            }

            // Identifiers (functions, constants, variables)
            if char.isLetter || char == "_" {
                let (identifier, endIndex) = parseIdentifier(expression, startingAt: index)
                index = endIndex

                if knownFunctions.contains(identifier) {
                    tokens.append(.function(identifier))
                } else if knownConstants.contains(identifier) {
                    tokens.append(.constant(identifier))
                } else {
                    tokens.append(.variable(identifier))
                }
                continue
            }

            // Unknown character
            throw MathExprError.unexpectedCharacter(char, at: expression.distance(from: expression.startIndex, to: index))
        }

        return tokens
    }

    /// Parse a number from the expression.
    private static func parseNumber(_ expression: String, startingAt start: String.Index) throws -> (Double, String.Index) {
        var index = start
        var numberString = ""
        var hasDecimal = false
        var hasExponent = false

        while index < expression.endIndex {
            let char = expression[index]

            if char.isNumber {
                numberString.append(char)
                index = expression.index(after: index)
            } else if char == "." && !hasDecimal && !hasExponent {
                numberString.append(char)
                hasDecimal = true
                index = expression.index(after: index)
            } else if (char == "e" || char == "E") && !hasExponent && !numberString.isEmpty {
                numberString.append(char)
                hasExponent = true
                index = expression.index(after: index)
                // Check for optional sign after exponent
                if index < expression.endIndex {
                    let nextChar = expression[index]
                    if nextChar == "+" || nextChar == "-" {
                        numberString.append(nextChar)
                        index = expression.index(after: index)
                    }
                }
            } else {
                break
            }
        }

        guard let number = Double(numberString) else {
            throw MathExprError.invalidNumber(numberString)
        }

        return (number, index)
    }

    /// Parse an identifier from the expression.
    private static func parseIdentifier(_ expression: String, startingAt start: String.Index) -> (String, String.Index) {
        var index = start
        var identifier = ""

        while index < expression.endIndex {
            let char = expression[index]
            if char.isLetter || char.isNumber || char == "_" {
                identifier.append(char)
                index = expression.index(after: index)
            } else {
                break
            }
        }

        return (identifier, index)
    }

    // MARK: - Token to Lua Conversion

    /// Convert a token to a Lua table representation
    private static func tokenToLua(_ token: Token) -> LuaValue {
        switch token {
        case .number(let n):
            return .table(["type": .string("number"), "value": .number(n)])
        case .operator(let op):
            return .table(["type": .string("operator"), "value": .string(op)])
        case .function(let name):
            return .table(["type": .string("function"), "value": .string(name)])
        case .lparen:
            return .table(["type": .string("lparen")])
        case .rparen:
            return .table(["type": .string("rparen")])
        case .comma:
            return .table(["type": .string("comma")])
        case .variable(let name):
            return .table(["type": .string("variable"), "value": .string(name)])
        case .constant(let name):
            return .table(["type": .string("constant"), "value": .string(name)])
        }
    }

    // MARK: - Registration

    /// Register the math expression module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Tokenize callback
        engine.registerFunction(name: "_luaswift_mathexpr_tokenize", callback: tokenizeCallback)

        // Set up the luaswift.mathexpr namespace
        do {
            try engine.run(mathExprLuaWrapper)
        } catch {
            // Module setup failed
        }
    }

    // MARK: - Callbacks

    private static let tokenizeCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let expression = args.first?.stringValue else {
            throw LuaError.callbackError("mathexpr.tokenize requires a string argument")
        }

        do {
            let tokens = try tokenize(expression)
            return .array(tokens.map { tokenToLua($0) })
        } catch let error as MathExprError {
            throw LuaError.callbackError("mathexpr.tokenize error: \(error.description)")
        }
    }

    // MARK: - Lua Wrapper Code

    private static let mathExprLuaWrapper = """
    -- Create luaswift.mathexpr namespace
    if not luaswift then luaswift = {} end
    luaswift.mathexpr = {}
    local mathexpr = luaswift.mathexpr

    -- Store reference to Swift tokenize function
    local _tokenize = _luaswift_mathexpr_tokenize

    -- LaTeX to standard notation preprocessor
    function mathexpr.latexToStandard(latex)
        local expr = latex

        -- Handle fractions: \\frac{a}{b} -> (a)/(b)
        expr = expr:gsub("\\\\frac%s*{([^}]+)}%s*{([^}]+)}", function(num, den)
            return "(" .. num .. ")/(" .. den .. ")"
        end)

        -- Handle nth roots: \\sqrt[n]{x} -> (x)^(1/(n))
        expr = expr:gsub("\\\\sqrt%s*%[([^%]]+)%]%s*{([^}]+)}", function(n, x)
            return "(" .. x .. ")^(1/(" .. n .. "))"
        end)

        -- Handle square roots: \\sqrt{x} -> sqrt(x)
        expr = expr:gsub("\\\\sqrt%s*{([^}]+)}", function(x)
            return "sqrt(" .. x .. ")"
        end)

        -- Handle function names: remove backslash
        local functions = {"sin", "cos", "tan", "asin", "acos", "atan",
                          "sinh", "cosh", "tanh", "asinh", "acosh", "atanh",
                          "log", "ln", "exp", "sqrt"}
        for _, func in ipairs(functions) do
            expr = expr:gsub("\\\\" .. func .. "([^a-zA-Z])", func .. "%1")
            expr = expr:gsub("\\\\" .. func .. "$", func)
        end

        -- Handle Greek letters (both as constants and variables)
        local greekLetters = {
            pi = "pi", theta = "theta", alpha = "alpha", beta = "beta",
            gamma = "gamma", delta = "delta", epsilon = "epsilon",
            lambda = "lambda", mu = "mu", sigma = "sigma", phi = "phi",
            omega = "omega"
        }
        for greek, name in pairs(greekLetters) do
            expr = expr:gsub("\\\\" .. greek .. "([^a-zA-Z])", name .. "%1")
            expr = expr:gsub("\\\\" .. greek .. "$", name)
        end

        -- Handle exponents with braces: x^{n} -> x^(n)
        expr = expr:gsub("%^%s*{([^}]+)}", function(exp)
            return "^(" .. exp .. ")"
        end)

        -- Handle subscripts: x_{i} -> x_i (as variable name)
        expr = expr:gsub("([a-zA-Z])_%s*{([^}]+)}", "%1_%2")

        -- Handle parentheses: \\left( and \\right) -> ( and )
        expr = expr:gsub("\\\\left%s*%(", "(")
        expr = expr:gsub("\\\\right%s*%)", ")")
        expr = expr:gsub("\\\\left%s*%[", "[")
        expr = expr:gsub("\\\\right%s*%]", "]")
        expr = expr:gsub("\\\\left%s*{", "{")
        expr = expr:gsub("\\\\right%s*}", "}")

        return expr
    end

    -- Detect if expression contains LaTeX notation
    local function isLatex(expr)
        -- Check for LaTeX patterns
        return expr:match("\\\\") ~= nil
    end

    -- Constants for evaluation
    mathexpr.constants = {
        pi = math.pi,
        e = math.exp(1),
        inf = math.huge,
        nan = 0/0
    }

    -- Built-in functions for evaluation
    mathexpr.functions = {
        -- Trigonometric
        sin = math.sin, cos = math.cos, tan = math.tan,
        asin = math.asin, acos = math.acos, atan = math.atan,
        atan2 = math.atan2 or function(y, x) return math.atan(y, x) end,
        sinh = function(x) return (math.exp(x) - math.exp(-x)) / 2 end,
        cosh = function(x) return (math.exp(x) + math.exp(-x)) / 2 end,
        tanh = function(x) return (math.exp(2*x) - 1) / (math.exp(2*x) + 1) end,
        -- Inverse hyperbolic
        asinh = function(x) return math.log(x + math.sqrt(x*x + 1)) end,
        acosh = function(x) return math.log(x + math.sqrt(x*x - 1)) end,
        atanh = function(x) return 0.5 * math.log((1 + x) / (1 - x)) end,
        -- Exponential and logarithmic
        exp = math.exp, log = math.log, log10 = math.log10,
        log2 = function(x) return math.log(x) / math.log(2) end,
        ln = math.log,
        -- Power and roots
        sqrt = math.sqrt,
        cbrt = function(x) return x >= 0 and x^(1/3) or -((-x)^(1/3)) end,
        pow = function(x, y) return x^y end,
        -- Absolute value and sign
        abs = math.abs,
        sign = function(x) return x > 0 and 1 or (x < 0 and -1 or 0) end,
        floor = math.floor, ceil = math.ceil,
        round = function(x) return math.floor(x + 0.5) end,
        trunc = function(x) return x >= 0 and math.floor(x) or math.ceil(x) end,
        -- Min/max and interpolation
        min = math.min, max = math.max,
        clamp = function(x, lo, hi) return math.min(math.max(x, lo), hi) end,
        lerp = function(a, b, t) return a + (b - a) * t end,
        -- Angle conversion
        rad = math.rad, deg = math.deg
    }

    -- Tokenize expression (calls Swift)
    function mathexpr.tokenize(expr)
        -- Preprocess LaTeX notation if detected
        if isLatex(expr) then
            expr = mathexpr.latexToStandard(expr)
        end
        return _tokenize(expr)
    end

    -- Operator precedence for parsing
    local precedence = {
        ["+"] = 1, ["-"] = 1,
        ["*"] = 2, ["/"] = 2,
        ["^"] = 3
    }

    local right_associative = {
        ["^"] = true
    }

    -- Parse tokens to AST using shunting-yard algorithm
    function mathexpr.parse(tokens)
        local output = {}
        local operators = {}
        local arg_counts = {}  -- Track argument counts for functions

        local function pop_operator()
            local op = table.remove(operators)
            local right = table.remove(output)
            local left = table.remove(output)
            table.insert(output, {type = "binop", op = op.value, left = left, right = right})
        end

        local prev_token = nil
        for i, token in ipairs(tokens) do
            if token.type == "number" then
                table.insert(output, {type = "number", value = token.value})
            elseif token.type == "constant" then
                table.insert(output, {type = "constant", name = token.value})
            elseif token.type == "variable" then
                table.insert(output, {type = "variable", name = token.value})
            elseif token.type == "function" then
                table.insert(operators, token)
                table.insert(arg_counts, 1)  -- At least 1 argument
            elseif token.type == "comma" then
                while #operators > 0 and operators[#operators].type ~= "lparen" do
                    pop_operator()
                end
                -- Increment arg count for current function
                if #arg_counts > 0 then
                    arg_counts[#arg_counts] = arg_counts[#arg_counts] + 1
                end
            elseif token.type == "operator" then
                -- Handle unary minus
                if token.value == "-" and (prev_token == nil or prev_token.type == "lparen" or prev_token.type == "operator" or prev_token.type == "comma") then
                    table.insert(output, {type = "number", value = 0})
                end

                local op1_prec = precedence[token.value] or 0
                while #operators > 0 do
                    local top = operators[#operators]
                    if top.type ~= "operator" then break end
                    local op2_prec = precedence[top.value] or 0
                    if right_associative[token.value] then
                        if op1_prec >= op2_prec then break end
                    else
                        if op1_prec > op2_prec then break end
                    end
                    pop_operator()
                end
                table.insert(operators, token)
            elseif token.type == "lparen" then
                table.insert(operators, token)
            elseif token.type == "rparen" then
                while #operators > 0 and operators[#operators].type ~= "lparen" do
                    pop_operator()
                end
                if #operators > 0 then
                    table.remove(operators)  -- Remove lparen
                end
                -- Handle function call with multiple arguments
                if #operators > 0 and operators[#operators].type == "function" then
                    local func_token = table.remove(operators)
                    local num_args = table.remove(arg_counts) or 1
                    local args = {}
                    for j = 1, num_args do
                        table.insert(args, 1, table.remove(output))
                    end
                    table.insert(output, {type = "call", name = func_token.value, args = args})
                end
            end
            prev_token = token
        end

        while #operators > 0 do
            pop_operator()
        end

        return output[1]
    end

    -- Evaluate an AST node
    function mathexpr.eval_ast(ast, vars)
        vars = vars or {}

        if ast.type == "number" then
            return ast.value
        elseif ast.type == "constant" then
            return mathexpr.constants[ast.name]
        elseif ast.type == "variable" then
            return vars[ast.name] or error("undefined variable: " .. ast.name)
        elseif ast.type == "binop" then
            local left = mathexpr.eval_ast(ast.left, vars)
            local right = mathexpr.eval_ast(ast.right, vars)
            if ast.op == "+" then return left + right
            elseif ast.op == "-" then return left - right
            elseif ast.op == "*" then return left * right
            elseif ast.op == "/" then return left / right
            elseif ast.op == "^" then return left ^ right
            end
        elseif ast.type == "call" then
            local func = mathexpr.functions[ast.name]
            if not func then error("unknown function: " .. ast.name) end
            local args = {}
            for _, arg in ipairs(ast.args) do
                table.insert(args, mathexpr.eval_ast(arg, vars))
            end
            -- Note: Can't use "table.unpack and table.unpack(args) or unpack(args)"
            -- because and/or truncates multiple return values to just one!
            local u = table.unpack or unpack
            return func(u(args))
        end
    end

    -- Evaluate expression string with variables
    function mathexpr.eval(expr, vars)
        local tokens = mathexpr.tokenize(expr)
        local ast = mathexpr.parse(tokens)
        return mathexpr.eval_ast(ast, vars)
    end

    -- Compile expression to a function
    function mathexpr.compile(expr)
        local tokens = mathexpr.tokenize(expr)
        local ast = mathexpr.parse(tokens)
        return function(vars_or_x)
            if type(vars_or_x) == "number" then
                return mathexpr.eval_ast(ast, {x = vars_or_x})
            else
                return mathexpr.eval_ast(ast, vars_or_x or {})
            end
        end
    end

    -- Helper to format a number for display
    local function format_number(n, precision)
        if precision then
            return string.format("%." .. precision .. "f", n)
        end
        if n == math.floor(n) then
            return tostring(math.floor(n))
        else
            local str = string.format("%.10f", n)
            str = str:gsub("0+$", ""):gsub("%.$", "")
            return str
        end
    end

    -- Helper to get operator symbol for description
    local function op_symbol(op)
        if op == "+" then return "+"
        elseif op == "-" then return "-"
        elseif op == "*" then return "×"
        elseif op == "/" then return "÷"
        elseif op == "^" then return "^"
        else return op
        end
    end

    -- Find all variables in an AST
    local function find_variables(ast, result)
        result = result or {}
        if ast.type == "variable" then
            result[ast.name] = true
        elseif ast.type == "binop" then
            find_variables(ast.left, result)
            find_variables(ast.right, result)
        elseif ast.type == "call" then
            for _, arg in ipairs(ast.args) do
                find_variables(arg, result)
            end
        end
        return result
    end

    -- Find unknowns (variables not in the provided bindings)
    local function find_unknowns(ast, vars)
        local all_vars = find_variables(ast)
        local unknowns = {}
        for name, _ in pairs(all_vars) do
            if vars[name] == nil then
                table.insert(unknowns, name)
            end
        end
        return unknowns
    end

    -- Check if expression is linear in a variable
    local function is_linear_in(ast, var_name)
        if ast.type == "number" or ast.type == "constant" then
            return true
        elseif ast.type == "variable" then
            return true  -- x is linear in x
        elseif ast.type == "binop" then
            if ast.op == "+" or ast.op == "-" then
                return is_linear_in(ast.left, var_name) and is_linear_in(ast.right, var_name)
            elseif ast.op == "*" or ast.op == "/" then
                local left_vars = find_variables(ast.left)
                local right_vars = find_variables(ast.right)
                -- Linear if variable appears in only one side (not both)
                if left_vars[var_name] and right_vars[var_name] then
                    return false  -- x * x is not linear
                end
                return is_linear_in(ast.left, var_name) and is_linear_in(ast.right, var_name)
            elseif ast.op == "^" then
                -- x^2 is not linear, but x^1 is, and 2^x is not linear in x for solving
                local left_vars = find_variables(ast.left)
                local right_vars = find_variables(ast.right)
                if left_vars[var_name] or right_vars[var_name] then
                    -- If variable appears in base or exponent of power, not simple linear
                    return false
                end
                return true
            end
        elseif ast.type == "call" then
            -- Function calls with variable are generally non-linear
            local arg_vars = {}
            for _, arg in ipairs(ast.args) do
                local vars_in_arg = find_variables(arg)
                for k, v in pairs(vars_in_arg) do
                    arg_vars[k] = true
                end
            end
            if arg_vars[var_name] then
                return false
            end
            return true
        end
        return true
    end

    -- Extract coefficient of variable and constant term from linear expression
    -- Returns coef, const such that expr = coef * var + const
    local function extract_linear_coefficients(ast, var_name, vars)
        if ast.type == "number" then
            return 0, ast.value
        elseif ast.type == "constant" then
            return 0, mathexpr.constants[ast.name]
        elseif ast.type == "variable" then
            if ast.name == var_name then
                return 1, 0
            else
                local val = vars[ast.name]
                if val == nil then
                    error("undefined variable: " .. ast.name)
                end
                return 0, val
            end
        elseif ast.type == "binop" then
            local left_coef, left_const = extract_linear_coefficients(ast.left, var_name, vars)
            local right_coef, right_const = extract_linear_coefficients(ast.right, var_name, vars)

            if ast.op == "+" then
                return left_coef + right_coef, left_const + right_const
            elseif ast.op == "-" then
                return left_coef - right_coef, left_const - right_const
            elseif ast.op == "*" then
                -- (a*x + b) * (c*x + d) = ac*x^2 + (ad+bc)*x + bd
                -- For linear, one of them must have coef = 0
                if left_coef == 0 then
                    return left_const * right_coef, left_const * right_const
                elseif right_coef == 0 then
                    return right_const * left_coef, left_const * right_const
                else
                    error("non-linear term in multiplication")
                end
            elseif ast.op == "/" then
                -- (a*x + b) / c where c has no x
                if right_coef ~= 0 then
                    error("cannot divide by expression containing variable")
                end
                return left_coef / right_const, left_const / right_const
            end
        elseif ast.type == "call" then
            -- For function calls, evaluate the result (which should be constant)
            local func = mathexpr.functions[ast.name]
            if not func then error("unknown function: " .. ast.name) end
            local arg_vals = {}
            for _, arg in ipairs(ast.args) do
                table.insert(arg_vals, mathexpr.eval_ast(arg, vars))
            end
            local u = table.unpack or unpack
            return 0, func(u(arg_vals))
        end
        return 0, 0
    end

    -- Solve linear equation: left = right for var_name
    local function solve_linear(left_ast, right_ast, var_name, vars)
        local left_coef, left_const = extract_linear_coefficients(left_ast, var_name, vars)
        local right_coef, right_const = extract_linear_coefficients(right_ast, var_name, vars)

        -- left_coef * x + left_const = right_coef * x + right_const
        -- (left_coef - right_coef) * x = right_const - left_const
        local coef = left_coef - right_coef
        local const = right_const - left_const

        if math.abs(coef) < 1e-15 then
            if math.abs(const) < 1e-15 then
                return nil, "infinite solutions (identity)"
            else
                return nil, "no solution (contradiction)"
            end
        end

        return const / coef
    end

    -- Numerical solver using Newton-Raphson method
    local function solve_numerical(left_ast, right_ast, var_name, vars, options)
        options = options or {}
        local x0 = options.initial_guess or 1
        local tolerance = options.tolerance or 1e-10
        local max_iterations = options.max_iterations or 100
        local h = 1e-8  -- For numerical derivative

        -- Define f(x) = left(x) - right(x), we want f(x) = 0
        local function f(x)
            local v = {}
            for k, val in pairs(vars) do v[k] = val end
            v[var_name] = x
            local left_val = mathexpr.eval_ast(left_ast, v)
            local right_val = mathexpr.eval_ast(right_ast, v)
            return left_val - right_val
        end

        -- Numerical derivative
        local function df(x)
            return (f(x + h) - f(x - h)) / (2 * h)
        end

        local x = x0
        for i = 1, max_iterations do
            local fx = f(x)
            if math.abs(fx) < tolerance then
                return x
            end
            local dfx = df(x)
            if math.abs(dfx) < 1e-15 then
                -- Try a different starting point
                x = x + 1
            else
                x = x - fx / dfx
            end
        end

        -- Return best estimate even if not converged
        return x, "may not have converged"
    end

    -- Parse equation string into left and right ASTs
    local function parse_equation(eq_str)
        -- Find the = sign
        local eq_pos = eq_str:find("=")
        if not eq_pos then
            return nil, nil, "not an equation (no = sign)"
        end

        local left_str = eq_str:sub(1, eq_pos - 1)
        local right_str = eq_str:sub(eq_pos + 1)

        if left_str:match("^%s*$") or right_str:match("^%s*$") then
            return nil, nil, "empty side in equation"
        end

        local left_tokens = mathexpr.tokenize(left_str)
        local right_tokens = mathexpr.tokenize(right_str)

        local left_ast = mathexpr.parse(left_tokens)
        local right_ast = mathexpr.parse(right_tokens)

        return left_ast, right_ast
    end

    -- Solve equation for a specific variable
    function mathexpr.solve_equation(equation, vars, options)
        vars = vars or {}
        options = options or {}

        local left_ast, right_ast, err = parse_equation(equation)
        if err then
            error("equation parse error: " .. err)
        end

        -- Find unknowns
        local left_unknowns = find_unknowns(left_ast, vars)
        local right_unknowns = find_unknowns(right_ast, vars)

        -- Combine unknowns
        local unknowns = {}
        local seen = {}
        for _, u in ipairs(left_unknowns) do
            if not seen[u] then
                table.insert(unknowns, u)
                seen[u] = true
            end
        end
        for _, u in ipairs(right_unknowns) do
            if not seen[u] then
                table.insert(unknowns, u)
                seen[u] = true
            end
        end

        -- If solve_for is specified, use that
        local solve_for = options.solve_for
        if solve_for then
            if not seen[solve_for] then
                error("variable '" .. solve_for .. "' not found in equation")
            end
            unknowns = {solve_for}
        end

        if #unknowns == 0 then
            -- No unknowns, just check if equation is satisfied
            local left_val = mathexpr.eval_ast(left_ast, vars)
            local right_val = mathexpr.eval_ast(right_ast, vars)
            if math.abs(left_val - right_val) < 1e-10 then
                return {satisfied = true, left = left_val, right = right_val}
            else
                return {satisfied = false, left = left_val, right = right_val}
            end
        end

        if #unknowns > 1 then
            error("equation has multiple unknowns: " .. table.concat(unknowns, ", ") .. ". Specify solve_for or provide values for all but one.")
        end

        local var_name = unknowns[1]

        -- Try analytical solution for linear equations
        local is_left_linear = is_linear_in(left_ast, var_name)
        local is_right_linear = is_linear_in(right_ast, var_name)

        if is_left_linear and is_right_linear then
            local result, msg = solve_linear(left_ast, right_ast, var_name, vars)
            if result then
                return {[var_name] = result}
            else
                return {error = msg}
            end
        end

        -- Fall back to numerical solver
        local result, msg = solve_numerical(left_ast, right_ast, var_name, vars, options)
        local solution = {[var_name] = result}
        if msg then
            solution.warning = msg
        end
        return solution
    end

    -- Extract coefficients for two variables from a linear expression
    -- Returns coef_x, coef_y, constant such that expr = coef_x * var1 + coef_y * var2 + constant
    local function extract_2var_coefficients(ast, var1, var2, vars)
        if ast.type == "number" then
            return 0, 0, ast.value
        elseif ast.type == "constant" then
            return 0, 0, mathexpr.constants[ast.name]
        elseif ast.type == "variable" then
            if ast.name == var1 then
                return 1, 0, 0
            elseif ast.name == var2 then
                return 0, 1, 0
            else
                local val = vars[ast.name]
                if val == nil then
                    error("undefined variable: " .. ast.name)
                end
                return 0, 0, val
            end
        elseif ast.type == "binop" then
            local lx, ly, lc = extract_2var_coefficients(ast.left, var1, var2, vars)
            local rx, ry, rc = extract_2var_coefficients(ast.right, var1, var2, vars)

            if ast.op == "+" then
                return lx + rx, ly + ry, lc + rc
            elseif ast.op == "-" then
                return lx - rx, ly - ry, lc - rc
            elseif ast.op == "*" then
                -- (ax + by + c) * (dx + ey + f)
                -- For linear, at most one of the sides can have non-zero coefficients
                if (lx ~= 0 or ly ~= 0) and (rx ~= 0 or ry ~= 0) then
                    error("non-linear term in multiplication (product of variables)")
                end
                if lx == 0 and ly == 0 then
                    -- Left is constant, multiply right by left constant
                    return lc * rx, lc * ry, lc * rc
                else
                    -- Right is constant, multiply left by right constant
                    return rc * lx, rc * ly, lc * rc
                end
            elseif ast.op == "/" then
                -- (ax + by + c) / d where d is constant
                if rx ~= 0 or ry ~= 0 then
                    error("cannot divide by expression containing variable")
                end
                return lx / rc, ly / rc, lc / rc
            end
        elseif ast.type == "call" then
            -- For function calls, evaluate the result (which should be constant)
            local func = mathexpr.functions[ast.name]
            if not func then error("unknown function: " .. ast.name) end
            local arg_vals = {}
            for _, arg in ipairs(ast.args) do
                table.insert(arg_vals, mathexpr.eval_ast(arg, vars))
            end
            local u = table.unpack or unpack
            return 0, 0, func(u(arg_vals))
        end
        return 0, 0, 0
    end

    -- Solve 2x2 linear system using Cramer's rule
    -- Equations in form: a1*x + b1*y = c1 and a2*x + b2*y = c2
    local function solve_2x2_linear(eq1_left, eq1_right, eq2_left, eq2_right, var1, var2, vars)
        -- Extract coefficients for both equations
        local l1x, l1y, l1c = extract_2var_coefficients(eq1_left, var1, var2, vars)
        local r1x, r1y, r1c = extract_2var_coefficients(eq1_right, var1, var2, vars)

        local l2x, l2y, l2c = extract_2var_coefficients(eq2_left, var1, var2, vars)
        local r2x, r2y, r2c = extract_2var_coefficients(eq2_right, var1, var2, vars)

        -- Rearrange: left = right => left - right = 0
        -- So: (l_x - r_x)*x + (l_y - r_y)*y + (l_c - r_c) = 0
        -- Or: coef_x * x + coef_y * y = -constant
        local coef1_x = l1x - r1x
        local coef1_y = l1y - r1y
        local const1 = r1c - l1c  -- moved to right side

        local coef2_x = l2x - r2x
        local coef2_y = l2y - r2y
        local const2 = r2c - l2c  -- moved to right side

        -- System: coef1_x * x + coef1_y * y = const1
        --         coef2_x * x + coef2_y * y = const2
        -- Using Cramer's rule
        local det = coef1_x * coef2_y - coef1_y * coef2_x

        if math.abs(det) < 1e-15 then
            -- System is singular (no unique solution)
            return nil, "system has no unique solution (singular matrix)"
        end

        local det_x = const1 * coef2_y - coef1_y * const2
        local det_y = coef1_x * const2 - const1 * coef2_x

        return det_x / det, det_y / det
    end

    -- Solve system of equations
    function mathexpr.solve_system(equations, vars, options)
        vars = vars or {}
        options = options or {}

        if type(equations) == "string" then
            -- Single equation
            return mathexpr.solve_equation(equations, vars, options)
        end

        if #equations == 1 then
            return mathexpr.solve_equation(equations[1], vars, options)
        end

        -- Parse all equations and collect all unknowns
        local parsed_eqs = {}
        local all_unknowns = {}
        local seen_unknowns = {}

        for i, eq in ipairs(equations) do
            local left_ast, right_ast, err = parse_equation(eq)
            if err then
                error("equation " .. i .. " parse error: " .. err)
            end
            parsed_eqs[i] = {left = left_ast, right = right_ast}

            -- Find unknowns in this equation
            local eq_unknowns = find_unknowns(left_ast, vars)
            for _, u in ipairs(find_unknowns(right_ast, vars)) do
                local found = false
                for _, existing in ipairs(eq_unknowns) do
                    if existing == u then found = true; break end
                end
                if not found then
                    table.insert(eq_unknowns, u)
                end
            end

            for _, u in ipairs(eq_unknowns) do
                if not seen_unknowns[u] then
                    table.insert(all_unknowns, u)
                    seen_unknowns[u] = true
                end
            end
        end

        -- Special case: 2 equations, 2 unknowns - use direct linear solver
        if #equations == 2 and #all_unknowns == 2 then
            local var1, var2 = all_unknowns[1], all_unknowns[2]
            local eq1, eq2 = parsed_eqs[1], parsed_eqs[2]

            -- Check if both equations are linear in both variables
            local is_eq1_linear = is_linear_in(eq1.left, var1) and is_linear_in(eq1.right, var1) and
                                  is_linear_in(eq1.left, var2) and is_linear_in(eq1.right, var2)
            local is_eq2_linear = is_linear_in(eq2.left, var1) and is_linear_in(eq2.right, var1) and
                                  is_linear_in(eq2.left, var2) and is_linear_in(eq2.right, var2)

            if is_eq1_linear and is_eq2_linear then
                local x_val, y_val = solve_2x2_linear(eq1.left, eq1.right, eq2.left, eq2.right, var1, var2, vars)
                if x_val then
                    return {[var1] = x_val, [var2] = y_val}
                else
                    return {error = y_val}  -- y_val contains error message
                end
            end
        end

        -- Fall back to iterative substitution approach
        local solutions = {}
        local current_vars = {}
        for k, v in pairs(vars) do current_vars[k] = v end

        for i, eq in ipairs(equations) do
            -- Try to solve this equation with current known values
            local ok, result = pcall(function()
                return mathexpr.solve_equation(equations[i], current_vars, options)
            end)

            if ok then
                if result.error then
                    return result
                end
                if result.satisfied ~= nil then
                    -- Skip equations that are already satisfied
                else
                    for k, v in pairs(result) do
                        if k ~= "warning" then
                            solutions[k] = v
                            current_vars[k] = v
                        end
                    end
                end
            else
                -- Equation couldn't be solved yet, might need more variables
                -- Continue and try later equations
            end
        end

        -- If we have solutions, return them
        if next(solutions) then
            return solutions
        end

        -- If we couldn't solve any equations, report error
        error("system could not be solved with available methods")
    end

    -- Evaluate AST with step tracking
    local function eval_with_steps(ast, vars, steps, config)
        vars = vars or {}
        config = config or {}

        if ast.type == "number" then
            return ast.value
        elseif ast.type == "constant" then
            return mathexpr.constants[ast.name]
        elseif ast.type == "variable" then
            local val = vars[ast.name]
            if val == nil then
                error("undefined variable: " .. ast.name)
            end
            return val
        elseif ast.type == "binop" then
            local left = eval_with_steps(ast.left, vars, steps, config)
            local right = eval_with_steps(ast.right, vars, steps, config)
            local result
            if ast.op == "+" then result = left + right
            elseif ast.op == "-" then result = left - right
            elseif ast.op == "*" then result = left * right
            elseif ast.op == "/" then result = left / right
            elseif ast.op == "^" then result = left ^ right
            end

            if not config.combineArithmetic or config.showIntermediates then
                local prec = config.significantDigits
                table.insert(steps, {
                    operation = "binop",
                    description = format_number(left, prec) .. " " .. op_symbol(ast.op) .. " " .. format_number(right, prec),
                    operands = {left, right},
                    result = result,
                    precision = prec,
                    subexpression = format_number(left, prec) .. " " .. ast.op .. " " .. format_number(right, prec)
                })
            end

            return result
        elseif ast.type == "call" then
            local func = mathexpr.functions[ast.name]
            if not func then error("unknown function: " .. ast.name) end
            local arg_vals = {}
            for _, arg in ipairs(ast.args) do
                table.insert(arg_vals, eval_with_steps(arg, vars, steps, config))
            end
            local u = table.unpack or unpack
            local result = func(u(arg_vals))

            local arg_strs = {}
            local prec = config.significantDigits
            for _, v in ipairs(arg_vals) do
                table.insert(arg_strs, format_number(v, prec))
            end
            table.insert(steps, {
                operation = "call",
                description = ast.name .. "(" .. table.concat(arg_strs, ", ") .. ")",
                operands = arg_vals,
                result = result,
                precision = prec,
                subexpression = ast.name .. "(" .. table.concat(arg_strs, ", ") .. ")"
            })

            return result
        end
    end

    -- Reserved option keys (not to be confused with variable names)
    local reserved_options = {
        show_steps = true,
        variables = true,
        combineArithmetic = true,
        showIntermediates = true,
        significantDigits = true,
        solve_for = true,
        initial_guess = true,
        tolerance = true,
        max_iterations = true
    }

    -- Check if a table is a variables table (has no reserved option keys)
    local function is_variables_table(t)
        if type(t) ~= "table" then return false end
        for k, _ in pairs(t) do
            if reserved_options[k] then
                return false
            end
        end
        return true
    end

    -- Solve expression with step-by-step evaluation or solve equation for unknowns
    -- API:
    --   solve(expr) - evaluate expression or solve single equation
    --   solve(expr, vars) - with variable bindings
    --   solve(expr, vars, options) - with options like initial_guess, solve_for
    --   solve({eq1, eq2, ...}) - solve system of equations
    --   solve({eq1, eq2, ...}, vars) - system with known variables
    --   solve({eq1, eq2, ...}, vars, options) - system with options
    function mathexpr.solve(input, arg2, arg3)
        -- Case 1: Array of equations -> solve system
        if type(input) == "table" then
            local vars = arg2 or {}
            local options = arg3 or {}
            return mathexpr.solve_system(input, vars, options)
        end

        local expr = input

        -- Case 2: Equation (contains =)
        if expr:find("=") then
            local vars, options

            if arg3 then
                -- Three-argument form: solve(equation, variables, options)
                vars = arg2 or {}
                options = arg3
            elseif arg2 then
                -- Two-argument form: determine if arg2 is vars or options
                if is_variables_table(arg2) then
                    -- arg2 is variables (no reserved keys found)
                    vars = arg2
                    options = {}
                elseif arg2.variables then
                    -- arg2 is options with embedded variables
                    vars = arg2.variables
                    options = arg2
                else
                    -- arg2 is options, extract numeric values as vars but exclude reserved
                    vars = {}
                    for k, v in pairs(arg2) do
                        if type(v) == "number" and not reserved_options[k] then
                            vars[k] = v
                        end
                    end
                    options = arg2
                end
            else
                vars = {}
                options = {}
            end

            return mathexpr.solve_equation(expr, vars, options)
        end

        -- Case 3: Expression evaluation (original behavior)
        -- For backward compatibility, arg2 is options
        local options = arg2 or {}
        local show_steps = options.show_steps
        local vars = options.variables or {}
        local config = {
            combineArithmetic = options.combineArithmetic,
            showIntermediates = options.showIntermediates,
            significantDigits = options.significantDigits
        }

        local tokens = mathexpr.tokenize(expr)
        local ast = mathexpr.parse(tokens)

        if not show_steps then
            return mathexpr.eval_ast(ast, vars)
        end

        local steps = {}

        table.insert(steps, {
            operation = "initial",
            description = "Initial expression",
            operands = {},
            result = nil,
            precision = config.significantDigits,
            subexpression = expr
        })

        local result = eval_with_steps(ast, vars, steps, config)

        table.insert(steps, {
            operation = "result",
            description = "Final result",
            operands = {},
            result = result,
            precision = config.significantDigits,
            subexpression = format_number(result, config.significantDigits)
        })

        return steps
    end

    -- Create top-level alias
    mathexpr_module = mathexpr

    -- Make available via require
    package.loaded["luaswift.mathexpr"] = mathexpr

    -- Clean up
    _luaswift_mathexpr_tokenize = nil
    """
}

// MARK: - Errors

/// Errors for mathematical expression parsing
public enum MathExprError: Error {
    case unexpectedCharacter(Character, at: Int)
    case invalidNumber(String)
    case unexpectedEnd
    case unmatchedParenthesis

    var description: String {
        switch self {
        case .unexpectedCharacter(let char, let pos):
            return "unexpected character '\(char)' at position \(pos)"
        case .invalidNumber(let str):
            return "invalid number '\(str)'"
        case .unexpectedEnd:
            return "unexpected end of expression"
        case .unmatchedParenthesis:
            return "unmatched parenthesis"
        }
    }
}
