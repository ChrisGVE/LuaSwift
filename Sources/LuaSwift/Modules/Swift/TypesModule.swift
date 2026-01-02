//
//  TypesModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// Type detection and conversion module for LuaSwift interoperability.
///
/// Provides utilities for detecting LuaSwift types and converting between them.
/// All LuaSwift types use the `__luaswift_type` field for identification.
///
/// ## Usage
///
/// ```lua
/// local types = require("luaswift.types")
/// local c = complex.new(1, 2)
/// print(types.typeof(c))  -- "complex"
/// print(types.is(c, "complex"))  -- true
/// ```
public struct TypesModule {

    // MARK: - Registration

    /// Register the types module in the specified engine.
    ///
    /// - Parameter engine: The Lua engine to register the module in
    public static func register(in engine: LuaEngine) {
        do {
            try engine.run(typesLuaCode)
        } catch {
            // Module setup failed - log error if needed
        }
    }

    // MARK: - Lua Wrapper Code

    private static let typesLuaCode = """
    -- Create luaswift.types namespace
    if not luaswift then luaswift = {} end

    local types = {}
    luaswift.types = types

    -- Get type of any value
    -- Returns the __luaswift_type field for tables, or the Lua type for primitives
    function types.typeof(value)
        if type(value) ~= "table" then return type(value) end
        return rawget(value, "__luaswift_type") or "table"
    end

    -- Check if value is a specific type
    function types.is(value, typename)
        return types.typeof(value) == typename
    end

    -- Check if value is any LuaSwift type
    function types.is_luaswift(value)
        if type(value) ~= "table" then return false end
        return rawget(value, "__luaswift_type") ~= nil
    end

    -- Type category checks
    function types.is_numeric(value)
        local t = types.typeof(value)
        return t == "number" or t == "complex"
    end

    function types.is_vector(value)
        local t = types.typeof(value)
        return t == "vec2" or t == "vec3" or t == "linalg.vector"
    end

    function types.is_matrix(value)
        local t = types.typeof(value)
        return t == "linalg.matrix" or t == "array"
    end

    function types.is_geometry(value)
        local t = types.typeof(value)
        return t == "vec2" or t == "vec3" or t == "quaternion" or t == "transform3d"
    end

    -- Conversion functions
    function types.to_array(value)
        local t = types.typeof(value)
        if t == "array" then return value end
        if t == "linalg.vector" or t == "linalg.matrix" then
            return luaswift.array.array(value:toarray())
        end
        if t == "vec2" then
            return luaswift.array.array({value.x, value.y})
        end
        if t == "vec3" then
            return luaswift.array.array({value.x, value.y, value.z})
        end
        if t == "table" then
            return luaswift.array.array(value)
        end
        error("Cannot convert " .. t .. " to array")
    end

    function types.to_vec2(value)
        local t = types.typeof(value)
        if t == "vec2" then return value end
        if t == "array" then
            local list = value:tolist()
            return luaswift.geometry.vec2(list[1], list[2])
        end
        if t == "linalg.vector" then
            local arr = value:toarray()
            return luaswift.geometry.vec2(arr[1], arr[2])
        end
        if t == "table" and value[1] and value[2] then
            return luaswift.geometry.vec2(value[1], value[2])
        end
        error("Cannot convert " .. t .. " to vec2")
    end

    function types.to_vec3(value)
        local t = types.typeof(value)
        if t == "vec3" then return value end
        if t == "vec2" then
            return luaswift.geometry.vec3(value.x, value.y, 0)
        end
        if t == "array" then
            local list = value:tolist()
            return luaswift.geometry.vec3(list[1], list[2], list[3] or 0)
        end
        if t == "linalg.vector" then
            local arr = value:toarray()
            return luaswift.geometry.vec3(arr[1], arr[2], arr[3] or 0)
        end
        if t == "table" and value[1] and value[2] then
            return luaswift.geometry.vec3(value[1], value[2], value[3] or 0)
        end
        error("Cannot convert " .. t .. " to vec3")
    end

    function types.to_complex(value)
        local t = types.typeof(value)
        if t == "complex" then return value end
        if t == "number" then
            return luaswift.complex.new(value, 0)
        end
        if t == "vec2" then
            return luaswift.complex.new(value.x, value.y)
        end
        error("Cannot convert " .. t .. " to complex")
    end

    function types.to_vector(value)
        local t = types.typeof(value)
        if t == "linalg.vector" then return value end
        if t == "array" then
            local list = value:tolist()
            return luaswift.linalg.vector(list)
        end
        if t == "vec2" then
            return luaswift.linalg.vector({value.x, value.y})
        end
        if t == "vec3" then
            return luaswift.linalg.vector({value.x, value.y, value.z})
        end
        if t == "table" then
            return luaswift.linalg.vector(value)
        end
        error("Cannot convert " .. t .. " to linalg.vector")
    end

    function types.to_matrix(value)
        local t = types.typeof(value)
        if t == "linalg.matrix" then return value end
        if t == "array" then
            local list = value:tolist()
            return luaswift.linalg.matrix(list)
        end
        if t == "table" then
            return luaswift.linalg.matrix(value)
        end
        error("Cannot convert " .. t .. " to linalg.matrix")
    end

    -- Clone function that preserves type
    function types.clone(value)
        local t = types.typeof(value)
        if t == "complex" then
            return luaswift.complex.new(value.re, value.im)
        end
        if t == "vec2" then
            return luaswift.geometry.vec2(value.x, value.y)
        end
        if t == "vec3" then
            return luaswift.geometry.vec3(value.x, value.y, value.z)
        end
        if t == "quaternion" then
            return luaswift.geometry.quaternion(value.w, value.x, value.y, value.z)
        end
        if t == "transform3d" then
            -- Deep copy the matrix
            local m = {}
            for i = 1, 16 do m[i] = value._m[i] end
            return luaswift.geometry.transform3d(m)
        end
        if t == "array" then
            return value:copy()
        end
        if t == "linalg.vector" or t == "linalg.matrix" then
            -- Use transpose twice to copy (linalg has no direct copy)
            return value:transpose():transpose()
        end
        -- For plain tables, use tablex if available
        if t == "table" then
            if luaswift.tablex and luaswift.tablex.deepcopy then
                return luaswift.tablex.deepcopy(value)
            end
            -- Simple shallow copy fallback
            local copy = {}
            for k, v in pairs(value) do copy[k] = v end
            return setmetatable(copy, getmetatable(value))
        end
        return value  -- primitives are immutable
    end

    -- Get list of all registered LuaSwift types
    function types.all_types()
        return {
            "complex", "vec2", "vec3", "quaternion", "transform3d",
            "linalg.vector", "linalg.matrix", "array"
        }
    end

    -- Register the module for require()
    package.loaded["luaswift.types"] = types
    """
}
