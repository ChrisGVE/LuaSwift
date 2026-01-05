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
            if "+-*/^".contains(char) {
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

    -- Solve expression with step-by-step evaluation
    function mathexpr.solve(expr, options)
        options = options or {}
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
