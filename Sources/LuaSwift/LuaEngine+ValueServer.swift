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
//  paths get proxy tables (pushServerValue) so dotted traversal keeps working.
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
        // Fast-fail when the VM is paused. The Lua state must not be touched
        // while the debug hook holds the run lock. Non-throwing: returns without
        // registering. Callers should register servers before running code (the
        // pre-run contract stated in the documentation); a guard here prevents
        // C-level UB if a caller mistakenly registers from a debug handler.
        guard !isPaused.load(ordering: .acquiring) else { return }
        lock.lock()
        defer { lock.unlock() }

        servers[server.namespace] = server
        registerServerGlobal(server)
    }

    /// Unregister a value server.
    ///
    /// - Parameter namespace: The namespace of the server to unregister
    public func unregister(namespace: String) {
        // Same isPaused guard as register(server:) — Lua state must not be
        // touched while the debug hook holds the run lock.
        guard !isPaused.load(ordering: .acquiring) else { return }
        lock.lock()
        defer { lock.unlock() }

        servers.removeValue(forKey: namespace)
        unregisterServerGlobal(namespace)
    }

    // MARK: - Global Table Setup

    private func registerServerGlobal(_ server: LuaValueServer) {
        guard let L = L else { return }

        // Create the global table for the server and attach the server metatable
        // (engine pointer, namespace, and the __index/__newindex callbacks).
        lua_newtable(L)
        let enginePtr = Unmanaged.passUnretained(self).toOpaque()
        installServerMetatable(L, enginePtr: enginePtr, namespace: server.namespace)
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

/// The data both server metamethods need from their call frame: the owning
/// engine (and its raw pointer, reused when building proxy tables), the server
/// namespace, and the full access path.
private struct ServerContext {
    let enginePtr: UnsafeMutableRawPointer
    let engine: LuaEngine
    let namespace: String
    let path: [String]
}

/// Callback for server __index metamethod (reads).
private func serverIndexCallback(_ L: OpaquePointer?) -> Int32 {
    guard let L = L, let ctx = extractServerContext(L) else { return 0 }

    let result = ctx.engine.resolveServerPath(namespace: ctx.namespace, path: ctx.path)
    // Push the resolved value, or a proxy table that carries the path forward so
    // dotted traversal of an as-yet-unresolved prefix keeps working.
    pushServerValue(L, result, namespace: ctx.namespace, path: ctx.path, enginePtr: ctx.enginePtr)
    return 1
}

/// Callback for server __newindex metamethod (writes).
private func serverNewIndexCallback(_ L: OpaquePointer?) -> Int32 {
    guard let L = L, let ctx = extractServerContext(L) else { return 0 }

    // The value being assigned is at stack index 3. Conversion can reject a
    // cyclic table / non-representable numeric key — surface that as a Lua error
    // rather than crashing across the C boundary.
    let value: LuaValue
    do {
        value = try valueFromLuaStack(L, at: 3)
    } catch {
        lua_pushstring(L, "cannot assign value: \(error.localizedDescription)")
        _ = lua_error(L)
        return 0
    }
    let success = ctx.engine.writeServerPath(namespace: ctx.namespace, path: ctx.path, value: value)
    if !success {
        let errorPath = "\(ctx.namespace).\(ctx.path.joined(separator: "."))"
        lua_pushstring(L, "cannot write to read-only path: \(errorPath)")
        _ = lua_error(L)
    }
    return 0
}

/// Shared __index/__newindex preamble. From the metamethod call frame, recover
/// the owning engine, the server namespace, and the full access path (the
/// traversal-accumulated `_path` plus the current key at stack index 2).
///
/// Returns `nil` — and leaves the caller to `return 0` — if any expected slot is
/// missing or has the wrong type, so a tampered proxy table degrades to a no-op
/// rather than crashing.
private func extractServerContext(_ L: OpaquePointer) -> ServerContext? {
    guard lua_istable(L, 1) else { return nil }
    guard lua_isstring(L, 2) != 0, let key = lua_getstring(L, 2) else { return nil }
    guard lua_getmetatable(L, 1) != 0 else { return nil }

    // _engine: a light-userdata pointer back to the LuaEngine.
    lua_getfield(L, -1, "_engine")
    guard lua_islightuserdata(L, -1) != 0, let enginePtr = lua_touserdata(L, -1) else {
        lua_pop(L, 2)  // _engine + metatable
        return nil
    }
    lua_pop(L, 1)  // _engine

    // _namespace: the server's registered namespace string.
    lua_getfield(L, -1, "_namespace")
    guard lua_isstring(L, -1) != 0, let nsStr = lua_tostring(L, -1) else {
        lua_pop(L, 2)  // _namespace + metatable
        return nil
    }
    let namespace = String(cString: nsStr)
    lua_pop(L, 2)  // _namespace + metatable

    var path = extractServerPath(L)
    path.append(key)

    let engine = Unmanaged<LuaEngine>.fromOpaque(enginePtr).takeUnretainedValue()
    return ServerContext(enginePtr: enginePtr, engine: engine, namespace: namespace, path: path)
}

/// Read the traversal-accumulated `_path` string array off the proxy table at
/// stack index 1, using `rawget`/`lua_next` to bypass the server metamethods.
private func extractServerPath(_ L: OpaquePointer) -> [String] {
    var path: [String] = []
    lua_pushstring(L, "_path")
    lua_rawget(L, 1)  // rawget bypasses __index
    if lua_istable(L, -1) {
        lua_pushnil(L)
        while lua_next(L, -2) != 0 {
            if lua_isstring(L, -1) != 0, let pStr = lua_getstring(L, -1) {
                path.append(pStr)
            }
            lua_pop(L, 1)
        }
    }
    lua_pop(L, 1)  // _path value
    return path
}

/// Attach the server metatable to the table on top of the stack: the engine
/// back-pointer, the namespace, and the `__index`/`__newindex` callbacks. Shared
/// by ``LuaEngine/registerServerGlobal(_:)`` and the proxy-table path in
/// ``pushServerValue(_:_:namespace:path:enginePtr:)``.
private func installServerMetatable(_ L: OpaquePointer, enginePtr: UnsafeMutableRawPointer, namespace: String) {
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
}

/// Store `path` as the raw `_path` array on the proxy table on top of the stack,
/// using `rawset` so the server `__newindex` is not triggered.
private func storeServerPath(_ L: OpaquePointer, _ path: [String]) {
    lua_newtable(L)
    for (i, p) in path.enumerated() {
        lua_pushstring_binary(L, p)
        lua_rawseti(L, -2, lua_Integer(i + 1))
    }
    lua_pushstring(L, "_path")
    lua_insert(L, -2)  // move the "_path" key below the array value
    lua_rawset(L, -3)
}

/// Push a resolved ``LuaValue`` for the server onto the Lua stack.
///
/// A `.nil` result is pushed as a *proxy table* (carrying the accumulated path
/// and the server metatable) rather than a bare `nil`, so that traversal of an
/// unresolved prefix such as `Server.a.b` can continue to resolve `b`.
private func pushServerValue(_ L: OpaquePointer, _ value: LuaValue, namespace: String, path: [String], enginePtr: UnsafeMutableRawPointer) {
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
        // Unresolved (or genuinely nil): hand back a proxy table that remembers
        // the path so far and shares the server metatable for further traversal.
        lua_newtable(L)
        storeServerPath(L, path)
        installServerMetatable(L, enginePtr: enginePtr, namespace: namespace)

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
    case .opaqueReference:
        // Non-re-injectable introspection placeholder — nothing to push.
        lua_pushnil(L)
    }
}
