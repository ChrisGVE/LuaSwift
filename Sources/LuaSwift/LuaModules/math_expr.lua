-- math_expr.lua - Mathematical Expression Parser and Evaluator
-- Copyright (c) 2025 LuaSwift
-- Licensed under the MIT License
--
-- A mathematical expression parser that supports:
-- - Operator precedence parsing using the shunting-yard algorithm
-- - Standard math operators: +, -, *, /, ^, unary minus
-- - Mathematical functions: sin, cos, tan, sqrt, abs, log, ln, exp
-- - Constants: pi, e
-- - Variable substitution
-- - Step-by-step evaluation with intermediate steps

local math_expr = {}

-- Constants
local CONSTANTS = {
    pi = math.pi,
    e = math.exp(1)
}

-- Operator definitions with precedence and associativity
local OPERATORS = {
    ["+"] = {precedence = 1, associativity = "left", operands = 2},
    ["-"] = {precedence = 1, associativity = "left", operands = 2},
    ["*"] = {precedence = 2, associativity = "left", operands = 2},
    ["/"] = {precedence = 2, associativity = "left", operands = 2},
    ["^"] = {precedence = 3, associativity = "right", operands = 2},
    ["unary-"] = {precedence = 4, associativity = "right", operands = 1}
}

-- Mathematical functions
local FUNCTIONS = {
    sin = {func = math.sin, args = 1},
    cos = {func = math.cos, args = 1},
    tan = {func = math.tan, args = 1},
    sqrt = {func = math.sqrt, args = 1},
    abs = {func = math.abs, args = 1},
    log = {func = math.log, args = 1},  -- natural log
    ln = {func = math.log, args = 1},   -- alias for log
    exp = {func = math.exp, args = 1}
}

-- Token types
local TOKEN_TYPES = {
    NUMBER = "NUMBER",
    OPERATOR = "OPERATOR",
    FUNCTION = "FUNCTION",
    LPAREN = "LPAREN",
    RPAREN = "RPAREN",
    VARIABLE = "VARIABLE",
    CONSTANT = "CONSTANT"
}

-- Tokenize the input expression
local function tokenize(expr)
    local tokens = {}
    local i = 1
    local len = #expr

    while i <= len do
        local char = expr:sub(i, i)

        -- Skip whitespace
        if char:match("%s") then
            i = i + 1

        -- Numbers (including decimals)
        elseif char:match("%d") or (char == "." and expr:sub(i+1, i+1):match("%d")) then
            local num_str = ""
            while i <= len and (expr:sub(i, i):match("[%d%.]")) do
                num_str = num_str .. expr:sub(i, i)
                i = i + 1
            end
            table.insert(tokens, {type = TOKEN_TYPES.NUMBER, value = tonumber(num_str)})

        -- Operators
        elseif char:match("[%+%-%*/^]") then
            table.insert(tokens, {type = TOKEN_TYPES.OPERATOR, value = char})
            i = i + 1

        -- Parentheses
        elseif char == "(" then
            table.insert(tokens, {type = TOKEN_TYPES.LPAREN, value = char})
            i = i + 1
        elseif char == ")" then
            table.insert(tokens, {type = TOKEN_TYPES.RPAREN, value = char})
            i = i + 1

        -- Functions, constants, and variables
        elseif char:match("[%a]") then
            local word = ""
            while i <= len and expr:sub(i, i):match("[%a%d_]") do
                word = word .. expr:sub(i, i)
                i = i + 1
            end

            if FUNCTIONS[word] then
                table.insert(tokens, {type = TOKEN_TYPES.FUNCTION, value = word})
            elseif CONSTANTS[word] then
                table.insert(tokens, {type = TOKEN_TYPES.CONSTANT, value = word})
            else
                table.insert(tokens, {type = TOKEN_TYPES.VARIABLE, value = word})
            end

        else
            error("Unexpected character: " .. char)
        end
    end

    return tokens
end

-- Convert infix notation to postfix (RPN) using shunting-yard algorithm
local function infix_to_postfix(tokens)
    local output = {}
    local operator_stack = {}
    local prev_token = nil

    for _, token in ipairs(tokens) do
        if token.type == TOKEN_TYPES.NUMBER or
           token.type == TOKEN_TYPES.VARIABLE or
           token.type == TOKEN_TYPES.CONSTANT then
            table.insert(output, token)

        elseif token.type == TOKEN_TYPES.FUNCTION then
            table.insert(operator_stack, token)

        elseif token.type == TOKEN_TYPES.OPERATOR then
            -- Handle unary minus
            local op_name = token.value
            if op_name == "-" and (not prev_token or
               prev_token.type == TOKEN_TYPES.OPERATOR or
               prev_token.type == TOKEN_TYPES.LPAREN) then
                op_name = "unary-"
                token = {type = TOKEN_TYPES.OPERATOR, value = op_name}
            end

            local op_info = OPERATORS[op_name]

            -- Pop operators with higher precedence
            while #operator_stack > 0 do
                local top = operator_stack[#operator_stack]
                if top.type == TOKEN_TYPES.OPERATOR then
                    local top_info = OPERATORS[top.value]
                    if (op_info.associativity == "left" and
                        op_info.precedence <= top_info.precedence) or
                       (op_info.associativity == "right" and
                        op_info.precedence < top_info.precedence) then
                        table.insert(output, table.remove(operator_stack))
                    else
                        break
                    end
                elseif top.type == TOKEN_TYPES.FUNCTION then
                    break
                else
                    break
                end
            end

            table.insert(operator_stack, token)

        elseif token.type == TOKEN_TYPES.LPAREN then
            table.insert(operator_stack, token)

        elseif token.type == TOKEN_TYPES.RPAREN then
            -- Pop until matching left parenthesis
            local found_lparen = false
            while #operator_stack > 0 do
                local top = table.remove(operator_stack)
                if top.type == TOKEN_TYPES.LPAREN then
                    found_lparen = true
                    break
                end
                table.insert(output, top)
            end

            if not found_lparen then
                error("Mismatched parentheses")
            end

            -- If there's a function at the top, pop it
            if #operator_stack > 0 and
               operator_stack[#operator_stack].type == TOKEN_TYPES.FUNCTION then
                table.insert(output, table.remove(operator_stack))
            end
        end

        prev_token = token
    end

    -- Pop remaining operators
    while #operator_stack > 0 do
        local top = table.remove(operator_stack)
        if top.type == TOKEN_TYPES.LPAREN or top.type == TOKEN_TYPES.RPAREN then
            error("Mismatched parentheses")
        end
        table.insert(output, top)
    end

    return output
end

-- Evaluate a postfix expression
local function eval_postfix(postfix, variables)
    local stack = {}
    variables = variables or {}

    for _, token in ipairs(postfix) do
        if token.type == TOKEN_TYPES.NUMBER then
            table.insert(stack, token.value)

        elseif token.type == TOKEN_TYPES.CONSTANT then
            table.insert(stack, CONSTANTS[token.value])

        elseif token.type == TOKEN_TYPES.VARIABLE then
            local value = variables[token.value]
            if value == nil then
                error("Undefined variable: " .. token.value)
            end
            table.insert(stack, value)

        elseif token.type == TOKEN_TYPES.OPERATOR then
            local op_info = OPERATORS[token.value]
            if #stack < op_info.operands then
                error("Invalid expression: not enough operands for operator " .. token.value)
            end

            if op_info.operands == 2 then
                local b = table.remove(stack)
                local a = table.remove(stack)
                local result

                if token.value == "+" then
                    result = a + b
                elseif token.value == "-" then
                    result = a - b
                elseif token.value == "*" then
                    result = a * b
                elseif token.value == "/" then
                    if b == 0 then
                        error("Division by zero")
                    end
                    result = a / b
                elseif token.value == "^" then
                    result = a ^ b
                end

                table.insert(stack, result)
            elseif op_info.operands == 1 then
                local a = table.remove(stack)
                if token.value == "unary-" then
                    table.insert(stack, -a)
                end
            end

        elseif token.type == TOKEN_TYPES.FUNCTION then
            local func_info = FUNCTIONS[token.value]
            if #stack < func_info.args then
                error("Invalid expression: not enough arguments for function " .. token.value)
            end

            local arg = table.remove(stack)
            local result = func_info.func(arg)
            table.insert(stack, result)
        end
    end

    if #stack ~= 1 then
        error("Invalid expression: malformed expression")
    end

    return stack[1]
end

-- Convert postfix back to infix string (for step display)
local function postfix_to_string(postfix)
    local stack = {}

    for _, token in ipairs(postfix) do
        if token.type == TOKEN_TYPES.NUMBER then
            table.insert(stack, tostring(token.value))

        elseif token.type == TOKEN_TYPES.CONSTANT then
            table.insert(stack, token.value)

        elseif token.type == TOKEN_TYPES.VARIABLE then
            table.insert(stack, token.value)

        elseif token.type == TOKEN_TYPES.OPERATOR then
            local op_info = OPERATORS[token.value]

            if op_info.operands == 2 then
                local b = table.remove(stack)
                local a = table.remove(stack)
                local expr = "(" .. a .. " " .. token.value .. " " .. b .. ")"
                table.insert(stack, expr)
            elseif op_info.operands == 1 then
                local a = table.remove(stack)
                if token.value == "unary-" then
                    table.insert(stack, "(-" .. a .. ")")
                end
            end

        elseif token.type == TOKEN_TYPES.FUNCTION then
            local arg = table.remove(stack)
            table.insert(stack, token.value .. "(" .. arg .. ")")
        end
    end

    return stack[1] or ""
end

-- Evaluate expression with optional step-by-step tracking
function math_expr.eval(expr, variables)
    local tokens = tokenize(expr)
    local postfix = infix_to_postfix(tokens)
    return eval_postfix(postfix, variables)
end

-- Solve expression with step-by-step evaluation
function math_expr.solve(expr, options)
    options = options or {}
    local show_steps = options.show_steps
    local variables = options.variables or {}

    if not show_steps then
        return math_expr.eval(expr, variables)
    end

    local steps = {}
    table.insert(steps, {expr = expr, desc = "Original expression"})

    -- Tokenize and convert to postfix
    local tokens = tokenize(expr)
    local postfix = infix_to_postfix(tokens)

    -- Evaluate step by step
    local stack = {}

    for _, token in ipairs(postfix) do
        if token.type == TOKEN_TYPES.NUMBER then
            table.insert(stack, {type = "number", value = token.value})

        elseif token.type == TOKEN_TYPES.CONSTANT then
            local value = CONSTANTS[token.value]
            table.insert(stack, {type = "number", value = value})
            table.insert(steps, {
                expr = expr,
                desc = "Substitute " .. token.value .. " = " .. value
            })

        elseif token.type == TOKEN_TYPES.VARIABLE then
            local value = variables[token.value]
            if value == nil then
                error("Undefined variable: " .. token.value)
            end
            table.insert(stack, {type = "number", value = value})
            table.insert(steps, {
                expr = expr,
                desc = "Substitute " .. token.value .. " = " .. value
            })

        elseif token.type == TOKEN_TYPES.OPERATOR then
            local op_info = OPERATORS[token.value]

            if op_info.operands == 2 then
                local b = table.remove(stack)
                local a = table.remove(stack)
                local result
                local op_symbol = token.value

                if token.value == "+" then
                    result = a.value + b.value
                elseif token.value == "-" then
                    result = a.value - b.value
                elseif token.value == "*" then
                    result = a.value * b.value
                elseif token.value == "/" then
                    if b.value == 0 then
                        error("Division by zero")
                    end
                    result = a.value / b.value
                elseif token.value == "^" then
                    result = a.value ^ b.value
                end

                table.insert(stack, {type = "number", value = result})
                table.insert(steps, {
                    expr = tostring(result),
                    desc = "Evaluate " .. a.value .. " " .. op_symbol .. " " .. b.value .. " = " .. result
                })

            elseif op_info.operands == 1 then
                local a = table.remove(stack)
                if token.value == "unary-" then
                    local result = -a.value
                    table.insert(stack, {type = "number", value = result})
                    table.insert(steps, {
                        expr = tostring(result),
                        desc = "Evaluate -(" .. a.value .. ") = " .. result
                    })
                end
            end

        elseif token.type == TOKEN_TYPES.FUNCTION then
            local func_info = FUNCTIONS[token.value]
            local arg = table.remove(stack)
            local result = func_info.func(arg.value)

            table.insert(stack, {type = "number", value = result})
            table.insert(steps, {
                expr = tostring(result),
                desc = "Evaluate " .. token.value .. "(" .. arg.value .. ") = " .. result
            })
        end
    end

    return steps
end

return math_expr
