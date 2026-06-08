//
//  LuaEngine+ValueServer.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+ValueServer.swift
//
//  Context: Value-server concern of LuaEngine. register(server:) exposes
//  a LuaValueServer (LuaValueServer.swift) as a Lua global whose
//  __index/__newindex metamethods are the C callbacks defined here; they
//  recover the engine from the metatable, rebuild the access path, and
//  resolve reads/writes through the server. Unresolved intermediate
//  paths get proxy tables (pushValue) so dotted traversal keeps working.
//  Write failures are parked in the engine's lastWriteError and rethrown
//  by the execution paths (LuaEngine+Execution.swift,
//  LuaEngine+Bytecode.swift). Assigned values are converted with
//  valueFromLuaStack/pushSimpleValue (LuaEngine+Bridging.swift).
//

import Foundation
import CLua

extension LuaEngine {

    // MARK: - Value Servers

    /// Register a value server.
    ///
    /// Once registered, Lua code can access the server's values using
    /// the server's namespace: `Namespace.path.to.value`
    ///
    /// If the server implements `canWrite` and `write`, Lua code can also
    /// assign values: `Namespace.path.to.value = newValue`
    ///
    /// - Parameter server: The server to register
    public func register(server: LuaValueServer) {
        // register touches the Lua state (creates global metatables).
        // Non-throwing: if paused, block on lock (waits for pause to end).
        // In practice hosts register servers before running code.
        lock.lock()
        defer { lock.unlock() }

        servers[server.namespace] = server
        registerServerGlobal(server)
    }

    /// Unregister a value server.
    ///
    /// - Parameter namespace: The namespace of the server to unregister
    public func unregister(namespace: String) {
        lock.lock()
        defer { lock.unlock() }

        servers.removeValue(forKey: namespace)
        unregisterServerGlobal(namespace)
    }

    // MARK: - Global Table Setup

    private func registerServerGlobal(_ server: LuaValueServer) {
        guard let L = L else { return }

        // Create a global table for the server
        lua_newtable(L)

        // Set up metatable for __index and __newindex
        lua_newtable(L)

        // Store reference to engine for callback
        let enginePtr = Unmanaged.passUnretained(self).toOpaque()
        lua_pushlightuserdata(L, enginePtr)
        lua_setfield(L, -2, "_engine")

        // Store namespace
        lua_pushstring(L, server.namespace)
        lua_setfield(L, -2, "_namespace")

        // Set __index metamethod (for reads)
        lua_pushcclosure(L, serverIndexCallback, 0)
        lua_setfield(L, -2, "__index")

        // Set __newindex metamethod (for writes)
        lua_pushcclosure(L, serverNewIndexCallback, 0)
        lua_setfield(L, -2, "__newindex")

        // Set metatable
        lua_setmetatable(L, -2)

        // Set as global
        lua_setglobal(L, server.namespace)
    }

    private func unregisterServerGlobal(_ namespace: String) {
        guard let L = L else { return }
        lua_pushnil(L)
        lua_setglobal(L, namespace)
    }

    // MARK: - Server Resolution (called from Lua)

    fileprivate func resolveServerPath(namespace: String, path: [String]) -> LuaValue {
        guard let server = servers[namespace] else {
            return .nil
        }
        return server.resolve(path: path)
    }

    fileprivate func writeServerPath(namespace: String, path: [String], value: LuaValue) -> Bool {
        guard let server = servers[namespace] else {
            lastWriteError = .pathResolutionError(path: "\(namespace).\(path.joined(separator: "."))")
            return false
        }

        guard server.canWrite(path: path) else {
            lastWriteError = .readOnlyAccess(path: "\(namespace).\(path.joined(separator: "."))")
            return false
        }

        do {
            try server.write(path: path, value: value)
            return true
        } catch let error as LuaError {
            lastWriteError = error
            return false
        } catch {
            lastWriteError = .runtimeError(error.localizedDescription)
            return false
        }
    }

    fileprivate func canWriteServerPath(namespace: String, path: [String]) -> Bool {
        guard let server = servers[namespace] else {
            return false
        }
        return server.canWrite(path: path)
    }
}

// MARK: - Lua C Callbacks (metamethods)

/// Callback for server __index metamethod (reads)
private func serverIndexCallback(_ L: OpaquePointer?) -> Int32 {
    guard let L = L else { return 0 }

    // Get the table (self)
    guard lua_istable(L, 1) else { return 0 }

    // Get the key being accessed
    guard lua_isstring(L, 2) != 0 else { return 0 }
    guard let key = lua_getstring(L, 2) else { return 0 }

    // Get metatable to access _engine and _namespace
    guard lua_getmetatable(L, 1) != 0 else { return 0 }

    // Get engine pointer
    lua_getfield(L, -1, "_engine")
    guard lua_islightuserdata(L, -1) != 0 else {
        lua_pop(L, 2)
        return 0
    }
    let enginePtr = lua_touserdata(L, -1)
    lua_pop(L, 1)

    // Get namespace
    lua_getfield(L, -1, "_namespace")
    guard lua_isstring(L, -1) != 0, let nsStr = lua_tostring(L, -1) else {
        lua_pop(L, 2)
        return 0
    }
    let namespace = String(cString: nsStr)
    lua_pop(L, 2)  // Pop namespace and metatable

    // Get path from table (stored during traversal) using raw access to avoid recursion
    var path: [String] = []
    lua_pushstring(L, "_path")
    lua_rawget(L, 1)  // Use rawget to bypass __index metamethod
    if lua_istable(L, -1) {
        // Iterate path array
        lua_pushnil(L)
        while lua_next(L, -2) != 0 {
            if lua_isstring(L, -1) != 0, let pStr = lua_getstring(L, -1) {
                path.append(pStr)
            }
            lua_pop(L, 1)
        }
    }
    lua_pop(L, 1)

    // Add current key to path
    path.append(key)

    // Resolve through engine
    guard let engine = Unmanaged<LuaEngine>.fromOpaque(enginePtr!).takeUnretainedValue() as LuaEngine? else {
        return 0
    }

    let result = engine.resolveServerPath(namespace: namespace, path: path)

    // Push result or proxy table for further traversal
    pushValue(L, result, namespace: namespace, path: path, enginePtr: enginePtr!)

    return 1
}

/// Callback for server __newindex metamethod (writes)
private func serverNewIndexCallback(_ L: OpaquePointer?) -> Int32 {
    guard let L = L else { return 0 }

    // Get the table (self)
    guard lua_istable(L, 1) else { return 0 }

    // Get the key being set
    guard lua_isstring(L, 2) != 0 else { return 0 }
    guard let key = lua_getstring(L, 2) else { return 0 }

    // Get metatable to access _engine and _namespace
    guard lua_getmetatable(L, 1) != 0 else { return 0 }

    // Get engine pointer
    lua_getfield(L, -1, "_engine")
    guard lua_islightuserdata(L, -1) != 0 else {
        lua_pop(L, 2)
        return 0
    }
    let enginePtr = lua_touserdata(L, -1)
    lua_pop(L, 1)

    // Get namespace
    lua_getfield(L, -1, "_namespace")
    guard lua_isstring(L, -1) != 0, let nsStr = lua_tostring(L, -1) else {
        lua_pop(L, 2)
        return 0
    }
    let namespace = String(cString: nsStr)
    lua_pop(L, 2)  // Pop namespace and metatable

    // Get path from table (stored during traversal) using raw access to avoid recursion
    var path: [String] = []
    lua_pushstring(L, "_path")
    lua_rawget(L, 1)  // Use rawget to bypass __newindex metamethod
    if lua_istable(L, -1) {
        // Iterate path array
        lua_pushnil(L)
        while lua_next(L, -2) != 0 {
            if lua_isstring(L, -1) != 0, let pStr = lua_getstring(L, -1) {
                path.append(pStr)
            }
            lua_pop(L, 1)
        }
    }
    lua_pop(L, 1)

    // Add current key to path
    path.append(key)

    // Get engine
    guard let engine = Unmanaged<LuaEngine>.fromOpaque(enginePtr!).takeUnretainedValue() as LuaEngine? else {
        return 0
    }

    // Convert the value being assigned (at stack index 3) using the callback's L
    let value = valueFromLuaStack(L, at: 3)

    // Attempt to write
    let success = engine.writeServerPath(namespace: namespace, path: path, value: value)

    if !success {
        // Raise a Lua error
        let errorPath = "\(namespace).\(path.joined(separator: "."))"
        lua_pushstring(L, "cannot write to read-only path: \(errorPath)")
        _ = lua_error(L)
    }

    return 0
}

/// Push a LuaValue onto the Lua stack
private func pushValue(_ L: OpaquePointer, _ value: LuaValue, namespace: String, path: [String], enginePtr: UnsafeMutableRawPointer) {
    switch value {
    case .string(let str):
        lua_pushstring_binary(L, str)

    case .number(let num):
        lua_pushnumber(L, num)

    case .complex(let re, let im):
        pushComplexValue(L, re: re, im: im)

    case .bool(let b):
        lua_pushboolean(L, b ? 1 : 0)

    case .nil:
        // Could be nil or could be a path that needs further resolution
        // Create a proxy table for potential further access
        lua_newtable(L)

        // Store path using raw access to avoid triggering __newindex
        lua_newtable(L)
        for (i, p) in path.enumerated() {
            lua_pushstring_binary(L, p)
            lua_rawseti(L, -2, lua_Integer(i + 1))
        }
        lua_pushstring(L, "_path")
        lua_insert(L, -2)  // Move key below value
        lua_rawset(L, -3)  // Use rawset to bypass __newindex

        // Set up metatable
        lua_newtable(L)
        lua_pushlightuserdata(L, enginePtr)
        lua_setfield(L, -2, "_engine")
        lua_pushstring(L, namespace)
        lua_setfield(L, -2, "_namespace")
        lua_pushcclosure(L, serverIndexCallback, 0)
        lua_setfield(L, -2, "__index")
        lua_pushcclosure(L, serverNewIndexCallback, 0)
        lua_setfield(L, -2, "__newindex")
        lua_setmetatable(L, -2)

    case .table(let dict):
        lua_newtable(L)
        for (k, v) in dict {
            lua_pushstring_binary(L, k)
            pushSimpleValue(L, v)
            lua_settable(L, -3)
        }

    case .array(let arr):
        lua_newtable(L)
        for (i, v) in arr.enumerated() {
            pushSimpleValue(L, v)
            lua_rawseti(L, -2, lua_Integer(i + 1))
        }

    case .luaFunction(let ref):
        // Push the function from the registry
        _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(ref))
    }
}
