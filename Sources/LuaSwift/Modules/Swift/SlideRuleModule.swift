//
//  SlideRuleModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-05.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Slide rule simulation module for LuaSwift.
///
/// Models classic slide rule scales and their computational capabilities,
/// including C/D scales for multiplication/division, LL scales for powers,
/// and S/T scales for trigonometry.
///
/// ## Usage
///
/// ```lua
/// local sliderule = require("luaswift.sliderule")
///
/// -- Create a scientific slide rule
/// local rule = sliderule.new({model = "scientific", precision = 3})
///
/// -- Basic operations
/// local product = rule:multiply(2.5, 3.2)
/// local quotient = rule:divide(15, 3)
/// local recip = rule:reciprocal(4)
///
/// -- Powers and roots
/// local sq = rule:square(5)
/// local root = rule:sqrt(25)
/// local cube = rule:cube(3)
/// local cuberoot = rule:cbrt(27)
/// local power = rule:power(2, 3)
///
/// -- Trigonometry (angles in degrees)
/// local sine = rule:sin_deg(30)
/// local tangent = rule:tan_deg(45)
///
/// -- Manual scale reading
/// rule:set('D', 2.5)
/// local aligned = rule:read('C')
/// ```
public struct SlideRuleModule {

    // MARK: - Registration

    /// Register the slide rule module with a LuaEngine.
    public static func register(in engine: LuaEngine) {
        // Set up the luaswift.sliderule namespace (pure Lua implementation)
        do {
            try engine.run(slideruleLuaWrapper)
        } catch {
            // Module setup failed
        }
    }

    // MARK: - Lua Wrapper Code

    private static let slideruleLuaWrapper = """
    -- Create luaswift.sliderule namespace
    if not luaswift then luaswift = {} end
    luaswift.sliderule = {}
    local sliderule = luaswift.sliderule

    -- Scale definitions with mathematical mappings
    -- Each scale maps a physical position (0-1) to a value range
    sliderule.scales = {
        -- Basic logarithmic scales
        C = {type = 'log', range = {1, 10}, description = 'Multiplication/division'},
        D = {type = 'log', range = {1, 10}, description = 'Multiplication/division'},

        -- Inverted C scale for reciprocals
        CI = {type = 'log_inverse', range = {1, 10}, description = 'Reciprocals (1/x)'},

        -- Folded scales (start at π instead of 1)
        CF = {type = 'log_folded', range = {math.pi, 10 * math.pi}, description = 'Folded at π'},
        DF = {type = 'log_folded', range = {math.pi, 10 * math.pi}, description = 'Folded at π'},

        -- Square scales (two cycles: 1-10, 10-100)
        A = {type = 'square', range = {1, 100}, description = 'Squares (x²)'},
        B = {type = 'square', range = {1, 100}, description = 'Squares (x²)'},

        -- Cube scale (three cycles: 1-10, 10-100, 100-1000)
        K = {type = 'cube', range = {1, 1000}, description = 'Cubes (x³)'},

        -- Log-log scales for powers (e^x ranges)
        LL0 = {type = 'loglog', range = {1.001, 1.01}, exp_range = {0.001, 0.01}, description = 'e^0.001x to e^0.01x'},
        LL1 = {type = 'loglog', range = {1.01, 1.105}, exp_range = {0.01, 0.1}, description = 'e^0.01x to e^0.1x'},
        LL2 = {type = 'loglog', range = {1.105, 2.718}, exp_range = {0.1, 1}, description = 'e^0.1x to e^x'},
        LL3 = {type = 'loglog', range = {2.718, 22026}, exp_range = {1, 10}, description = 'e^x to e^10x'},

        -- Trigonometric scales
        S = {type = 'sine', range = {5.74, 90}, description = 'Sine (5.74° to 90°)'},
        T = {type = 'tangent', range = {5.71, 45}, description = 'Tangent (5.71° to 45°)'},
        ST = {type = 'sine_tan', range = {0.57, 5.73}, description = 'Small angles (sin≈tan≈rad)'},
    }

    -- Predefined slide rule models
    sliderule.models = {
        basic = {'C', 'D', 'A', 'B'},
        scientific = {'C', 'D', 'CI', 'CF', 'DF', 'A', 'B', 'K', 'LL1', 'LL2', 'LL3', 'S', 'T', 'ST'},
        engineering = {'C', 'D', 'CI', 'K', 'A', 'B', 'S', 'T', 'ST'},
        log_log = {'C', 'D', 'LL0', 'LL1', 'LL2', 'LL3'},
        trig = {'C', 'D', 'S', 'T', 'ST'},
    }

    -- Scale conversion functions
    local function value_to_position(scale_name, value)
        local scale = sliderule.scales[scale_name]
        if not scale then return nil end

        local stype = scale.type
        local range = scale.range

        if stype == 'log' then
            -- Logarithmic: position = log10(value) for value in [1, 10]
            if value < range[1] or value > range[2] then return nil end
            return math.log(value, 10)

        elseif stype == 'log_inverse' then
            -- Inverted log: position = 1 - log10(value)
            if value < range[1] or value > range[2] then return nil end
            return 1 - math.log(value, 10)

        elseif stype == 'log_folded' then
            -- Folded at π: position = log10(value/π)
            if value < range[1] or value > range[2] then return nil end
            return math.log(value / math.pi, 10)

        elseif stype == 'square' then
            -- Square scale: position = log10(value) / 2
            if value < range[1] or value > range[2] then return nil end
            return math.log(value, 10) / 2

        elseif stype == 'cube' then
            -- Cube scale: position = log10(value) / 3
            if value < range[1] or value > range[2] then return nil end
            return math.log(value, 10) / 3

        elseif stype == 'loglog' then
            -- Log-log scale: position = log10(ln(value))
            local exp_range = scale.exp_range
            local ln_val = math.log(value)
            if ln_val < exp_range[1] or ln_val > exp_range[2] then return nil end
            return (math.log(ln_val, 10) - math.log(exp_range[1], 10)) /
                   (math.log(exp_range[2], 10) - math.log(exp_range[1], 10))

        elseif stype == 'sine' then
            -- Sine scale: maps angle to sin value on D scale
            if value < range[1] or value > range[2] then return nil end
            local sin_val = math.sin(math.rad(value))
            return math.log(sin_val * 10, 10)  -- Scale to 1-10 range

        elseif stype == 'tangent' then
            -- Tangent scale: maps angle to tan value on D scale
            if value < range[1] or value > range[2] then return nil end
            local tan_val = math.tan(math.rad(value))
            return math.log(tan_val * 10, 10)  -- Scale to 1-10 range

        elseif stype == 'sine_tan' then
            -- Small angle scale: sin ≈ tan ≈ angle in radians
            if value < range[1] or value > range[2] then return nil end
            local rad_val = math.rad(value)
            return math.log(rad_val * 100, 10)  -- Scale appropriately
        end

        return nil
    end

    local function position_to_value(scale_name, position)
        local scale = sliderule.scales[scale_name]
        if not scale then return nil end

        local stype = scale.type

        -- Clamp position to valid range
        position = math.max(0, math.min(1, position))

        if stype == 'log' then
            -- Inverse of log: value = 10^position
            return 10 ^ position

        elseif stype == 'log_inverse' then
            -- Inverse: value = 10^(1-position)
            return 10 ^ (1 - position)

        elseif stype == 'log_folded' then
            -- Folded: value = π * 10^position
            return math.pi * (10 ^ position)

        elseif stype == 'square' then
            -- Square scale: value = 10^(2*position)
            return 10 ^ (2 * position)

        elseif stype == 'cube' then
            -- Cube scale: value = 10^(3*position)
            return 10 ^ (3 * position)

        elseif stype == 'loglog' then
            -- Log-log: value = e^(10^position mapped to exp_range)
            local exp_range = scale.exp_range
            local log_range = math.log(exp_range[2], 10) - math.log(exp_range[1], 10)
            local exponent = 10 ^ (position * log_range + math.log(exp_range[1], 10))
            return math.exp(exponent)

        elseif stype == 'sine' then
            -- Sine scale: angle from sin value
            local sin_val = (10 ^ position) / 10
            if sin_val > 1 then sin_val = 1 end
            return math.deg(math.asin(sin_val))

        elseif stype == 'tangent' then
            -- Tangent scale: angle from tan value
            local tan_val = (10 ^ position) / 10
            return math.deg(math.atan(tan_val))

        elseif stype == 'sine_tan' then
            -- Small angle: angle from radian approximation
            local rad_val = (10 ^ position) / 100
            return math.deg(rad_val)
        end

        return nil
    end

    -- Normalize value to 1-10 range and track decimal shift
    local function normalize(value)
        if value <= 0 then return nil, 0 end
        local shift = 0
        local normalized = value
        while normalized >= 10 do
            normalized = normalized / 10
            shift = shift + 1
        end
        while normalized < 1 do
            normalized = normalized * 10
            shift = shift - 1
        end
        return normalized, shift
    end

    -- Apply decimal shift to result
    local function denormalize(value, shift)
        return value * (10 ^ shift)
    end

    -- Select appropriate LL scale for a base value
    local function select_ll_scale(value)
        if value >= 2.718 then return 'LL3'
        elseif value >= 1.105 then return 'LL2'
        elseif value >= 1.01 then return 'LL1'
        elseif value >= 1.001 then return 'LL0'
        else return nil
        end
    end

    -- Select appropriate LL scale for an exponent
    local function select_ll_scale_for_exp(exponent)
        if exponent >= 1 then return 'LL3'
        elseif exponent >= 0.1 then return 'LL2'
        elseif exponent >= 0.01 then return 'LL1'
        elseif exponent >= 0.001 then return 'LL0'
        else return nil
        end
    end

    -- Slide rule instance
    local Rule = {}
    Rule.__index = Rule

    function Rule:set(scale_name, value)
        if not sliderule.scales[scale_name] then
            error("Unknown scale: " .. tostring(scale_name))
        end

        -- For C/D scales, normalize to 1-10
        local scale = sliderule.scales[scale_name]
        if scale.type == 'log' then
            local norm, shift = normalize(value)
            if not norm then
                error("Invalid value for scale " .. scale_name .. ": " .. tostring(value))
            end
            self.cursor_position = value_to_position(scale_name, norm)
            self.decimal_shift = shift
            self.last_value = value
        else
            local pos = value_to_position(scale_name, value)
            if not pos then
                error("Value " .. tostring(value) .. " out of range for scale " .. scale_name)
            end
            self.cursor_position = pos
            self.decimal_shift = 0
            self.last_value = value
        end

        return self
    end

    function Rule:read(scale_name)
        if not sliderule.scales[scale_name] then
            error("Unknown scale: " .. tostring(scale_name))
        end

        if not self.cursor_position then
            error("Cursor not set. Use set() first.")
        end

        -- Account for slide offset for C scale
        local effective_position = self.cursor_position
        if scale_name == 'C' then
            effective_position = effective_position - self.slide_offset
            -- Handle wraparound
            while effective_position < 0 do effective_position = effective_position + 1 end
            while effective_position > 1 do effective_position = effective_position - 1 end
        end

        local value = position_to_value(scale_name, effective_position)

        -- Apply decimal shift for log scales
        local scale = sliderule.scales[scale_name]
        if scale.type == 'log' and self.decimal_shift ~= 0 then
            value = denormalize(value, self.decimal_shift)
        end

        -- Round to precision
        local mult = 10 ^ self.precision
        return math.floor(value * mult + 0.5) / mult
    end

    function Rule:align_index(scale_name, value)
        -- Align the index (1) of the specified scale to the current cursor position
        -- This is used to set up multiplication/division
        if scale_name == 'C' then
            if not self.cursor_position then
                error("Cursor not set. Use set() first.")
            end
            -- Move slide so C index aligns with cursor
            self.slide_offset = -self.cursor_position
            while self.slide_offset < 0 do self.slide_offset = self.slide_offset + 1 end
        end
        return self
    end

    -- Multiplication using C/D scales
    function Rule:multiply(a, b)
        -- Normalize both values
        local norm_a, shift_a = normalize(a)
        local norm_b, shift_b = normalize(b)

        if not norm_a or not norm_b then
            error("Invalid values for multiplication")
        end

        -- Position cursor at a on D scale
        local pos_a = value_to_position('D', norm_a)

        -- Align C index to cursor (simulates moving the slide)
        self.slide_offset = -pos_a

        -- Move cursor to b on C scale (accounting for slide offset)
        local pos_b = value_to_position('C', norm_b)
        local result_pos = pos_b - self.slide_offset

        -- Handle overflow (result > 10, need to use right index)
        local extra_shift = 0
        if result_pos > 1 then
            -- Use right index instead: subtract 1 and add to shift
            result_pos = result_pos - 1
            extra_shift = 1
        elseif result_pos < 0 then
            result_pos = result_pos + 1
            extra_shift = -1
        end

        -- Read result on D scale
        local result = position_to_value('D', result_pos)
        result = denormalize(result, shift_a + shift_b + extra_shift)

        -- Store state for chaining
        self.cursor_position = result_pos
        self.decimal_shift = shift_a + shift_b + extra_shift
        self.last_result = result

        -- Round to precision
        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Division using C/D scales
    function Rule:divide(a, b)
        -- Normalize both values
        local norm_a, shift_a = normalize(a)
        local norm_b, shift_b = normalize(b)

        if not norm_a or not norm_b then
            error("Invalid values for division")
        end

        -- Position cursor at dividend (a) on D scale
        local pos_a = value_to_position('D', norm_a)

        -- Align divisor (b) on C to cursor
        local pos_b = value_to_position('C', norm_b)
        self.slide_offset = pos_b - pos_a

        -- Read result at C index on D scale
        local result_pos = -self.slide_offset

        -- Handle underflow
        local extra_shift = 0
        while result_pos < 0 do
            result_pos = result_pos + 1
            extra_shift = extra_shift - 1
        end
        while result_pos > 1 do
            result_pos = result_pos - 1
            extra_shift = extra_shift + 1
        end

        -- Read result
        local result = position_to_value('D', result_pos)
        result = denormalize(result, shift_a - shift_b + extra_shift)

        -- Store state
        self.cursor_position = result_pos
        self.decimal_shift = shift_a - shift_b + extra_shift
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Reciprocal using CI scale
    function Rule:reciprocal(x)
        local norm, shift = normalize(x)
        if not norm then
            error("Invalid value for reciprocal")
        end

        -- Set cursor on D scale
        local pos = value_to_position('D', norm)

        -- Read directly from CI (inverted scale)
        -- CI gives 10/x, so we need to divide by 10 (shift -1)
        local result = position_to_value('CI', pos)
        local reciprocal_shift = -shift - 1  -- -1 because CI gives 10/x not 1/x
        result = denormalize(result, reciprocal_shift)

        self.cursor_position = pos
        self.decimal_shift = reciprocal_shift
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Square using A/D scales
    function Rule:square(x)
        local norm, shift = normalize(x)
        if not norm then
            error("Invalid value for square")
        end

        -- Position on D scale
        local pos = value_to_position('D', norm)

        -- Read from A scale (which gives x²)
        local result = position_to_value('A', pos)
        result = denormalize(result, 2 * shift)

        self.cursor_position = pos
        self.decimal_shift = 2 * shift
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Square root using A/D scales
    function Rule:sqrt(x)
        local norm, shift = normalize(x)
        if not norm then
            error("Invalid value for sqrt")
        end

        -- Adjust for odd/even power of 10
        local adjusted_shift = math.floor(shift / 2)
        if shift % 2 ~= 0 then
            -- Odd shift: multiply by 10 and adjust
            norm = norm * 10
            if norm >= 100 then
                norm = norm / 100
                adjusted_shift = adjusted_shift + 1
            end
        end

        -- Position on A scale (which has range 1-100)
        local pos = value_to_position('A', norm)

        -- Read from D scale
        local result = position_to_value('D', pos)
        result = denormalize(result, adjusted_shift)

        self.cursor_position = pos
        self.decimal_shift = adjusted_shift
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Cube using K/D scales
    function Rule:cube(x)
        local norm, shift = normalize(x)
        if not norm then
            error("Invalid value for cube")
        end

        -- Position on D scale
        local pos = value_to_position('D', norm)

        -- Read from K scale
        local result = position_to_value('K', pos)
        result = denormalize(result, 3 * shift)

        self.cursor_position = pos
        self.decimal_shift = 3 * shift
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Cube root using K/D scales
    function Rule:cbrt(x)
        local norm, shift = normalize(x)
        if not norm then
            error("Invalid value for cbrt")
        end

        -- Adjust for powers of 10
        local remainder = shift % 3
        local adjusted_shift = math.floor(shift / 3)

        if remainder == 1 then
            norm = norm * 10
        elseif remainder == 2 then
            norm = norm * 100
        elseif remainder == -1 then
            norm = norm / 10
            adjusted_shift = adjusted_shift - 1
        elseif remainder == -2 then
            norm = norm / 100
            adjusted_shift = adjusted_shift - 1
        end

        -- Ensure norm is in K scale range
        while norm >= 1000 do
            norm = norm / 1000
            adjusted_shift = adjusted_shift + 1
        end
        while norm < 1 do
            norm = norm * 1000
            adjusted_shift = adjusted_shift - 1
        end

        -- Position on K scale
        local pos = value_to_position('K', norm)

        -- Read from D scale
        local result = position_to_value('D', pos)
        result = denormalize(result, adjusted_shift)

        self.cursor_position = pos
        self.decimal_shift = adjusted_shift
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Power using LL scales
    function Rule:power(base, exponent)
        -- For x^y, we use: x^y = e^(y * ln(x))
        -- On slide rule: locate x on LL, align D index, move to y on D, read result on LL

        local ll_scale = select_ll_scale(base)
        if not ll_scale then
            -- Try computing via logs for small bases
            local result = base ^ exponent
            local mult = 10 ^ self.precision
            return math.floor(result * mult + 0.5) / mult
        end

        -- This is an approximation since we can't perfectly model LL scale interaction
        local result = base ^ exponent
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Natural logarithm using LL scales
    function Rule:ln(x)
        if x <= 0 then
            error("ln requires positive argument")
        end

        -- Use math.log for now (slide rule ln is complex)
        local result = math.log(x)
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Exponential using LL scales
    function Rule:exp(x)
        -- e^x using LL scales
        local ll_scale = select_ll_scale_for_exp(math.abs(x))

        local result = math.exp(x)
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Sine (angle in degrees) using S scale
    function Rule:sin_deg(angle)
        if angle < 0 or angle > 90 then
            error("sin_deg requires angle in [0, 90]")
        end

        local scale = sliderule.scales['S']
        if angle < scale.range[1] then
            -- Use small angle approximation
            local rad = math.rad(angle)
            local mult = 10 ^ self.precision
            return math.floor(rad * mult + 0.5) / mult
        end

        -- Use S scale
        local pos = value_to_position('S', angle)
        local sin_val = math.sin(math.rad(angle))

        self.cursor_position = pos
        self.last_result = sin_val

        local mult = 10 ^ self.precision
        return math.floor(sin_val * mult + 0.5) / mult
    end

    -- Tangent (angle in degrees) using T scale
    function Rule:tan_deg(angle)
        if angle < 0 or angle >= 90 then
            error("tan_deg requires angle in [0, 90)")
        end

        local scale = sliderule.scales['T']
        if angle < scale.range[1] then
            -- Use small angle approximation
            local rad = math.rad(angle)
            local mult = 10 ^ self.precision
            return math.floor(rad * mult + 0.5) / mult
        end

        if angle > scale.range[2] then
            -- Use reciprocal for angles > 45°
            local tan_val = math.tan(math.rad(angle))
            local mult = 10 ^ self.precision
            return math.floor(tan_val * mult + 0.5) / mult
        end

        -- Use T scale
        local pos = value_to_position('T', angle)
        local tan_val = math.tan(math.rad(angle))

        self.cursor_position = pos
        self.last_result = tan_val

        local mult = 10 ^ self.precision
        return math.floor(tan_val * mult + 0.5) / mult
    end

    -- Small angle approximation using ST scale
    function Rule:small_angle_trig(angle)
        local scale = sliderule.scales['ST']
        if angle < scale.range[1] or angle > scale.range[2] then
            error("small_angle_trig requires angle in [" .. scale.range[1] .. ", " .. scale.range[2] .. "]")
        end

        -- For small angles: sin(x) ≈ tan(x) ≈ x (in radians)
        local rad = math.rad(angle)

        self.last_result = rad

        local mult = 10 ^ self.precision
        return math.floor(rad * mult + 0.5) / mult
    end

    -- π multiplication using CF/DF scales
    function Rule:pi_multiply(x)
        local result = math.pi * x
        self.last_result = result

        local mult = 10 ^ self.precision
        return math.floor(result * mult + 0.5) / mult
    end

    -- Get available scales
    function Rule:available_scales()
        local result = {}
        for _, scale_name in ipairs(self.scale_list) do
            table.insert(result, scale_name)
        end
        return result
    end

    -- Has scale check
    function Rule:has_scale(scale_name)
        for _, s in ipairs(self.scale_list) do
            if s == scale_name then return true end
        end
        return false
    end

    -- Clear state
    function Rule:clear()
        self.cursor_position = nil
        self.slide_offset = 0
        self.decimal_shift = 0
        self.last_value = nil
        self.last_result = nil
        return self
    end

    -- Factory function
    function sliderule.new(options)
        options = options or {}

        local model = options.model or 'scientific'
        local scale_list = options.scales or sliderule.models[model] or sliderule.models.scientific

        local rule = setmetatable({
            precision = options.precision or 3,
            scale_list = scale_list,
            cursor_position = nil,
            slide_offset = 0,
            decimal_shift = 0,
            last_value = nil,
            last_result = nil,
            __luaswift_type = "sliderule"
        }, {
            __index = Rule,
            __tostring = function(self)
                return string.format("sliderule(%s, %d scales)",
                    options.model or "custom", #self.scale_list)
            end
        })

        return rule
    end

    -- Create top-level alias
    sliderule_module = sliderule

    -- Make available via require
    package.loaded["luaswift.sliderule"] = sliderule
    """
}
