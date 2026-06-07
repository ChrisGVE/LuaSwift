//
//  LuaEngine+Callbacks.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Callbacks.swift
//
//  Context: Lua-calls-Swift concern of LuaEngine. registerFunction
//  installs a global Lua closure whose C body (callbackTrampoline)
//  recovers the engine and callback name from its upvalues, converts
//  arguments with valueFromLuaStack and the result with pushSimpleValue
//  (LuaEngine+Bridging.swift), and invokes the stored Swift closure.
//  During invocation the engine is exposed via thread-local storage
//  (LuaEngine.currentEngine, LuaEngine.swift) so Swift modules can
//  track memory. The inverse direction — Swift calling Lua functions —
//  lives in LuaEngine+FunctionCalls.swift.
//

import Foundation
import CLua

extension LuaEngine {

    // MARK: - Callbacks

    /// Register a Swift function that can be called from Lua.
    ///
    /// Once registered, Lua code can call the function using its name.
    ///
    /// - Parameters:
    ///   - name: The global name for the function
    ///   - callback: The Swift closure to execute. Takes an array of LuaValue arguments
    ///               and returns a LuaValue result. Can throw errors.
    public func registerFunction(
        name: String,
        callback: @escaping ([LuaValue]) throws -> LuaValue
    ) {
        lock.lock()
        defer { lock.unlock() }

        callbacks[name] = callback
        registerCallbackGlobal(name)
    }

    /// Unregister a previously registered function.
    ///
    /// - Parameter name: The name of the function to unregister
    public func unregisterFunction(name: String) {
        lock.lock()
        defer { lock.unlock() }

        callbacks.removeValue(forKey: name)
        unregisterCallbackGlobal(name)
    }

    // MARK: - Global Closure Setup

    private func registerCallbackGlobal(_ name: String) {
        guard let L = L else { return }

        // Store engine pointer as upvalue for the closure
        let enginePtr = Unmanaged.passUnretained(self).toOpaque()
        lua_pushlightuserdata(L, enginePtr)

        // Store function name as upvalue
        lua_pushstring(L, name)

        // Create closure with 2 upvalues (engine ptr, function name)
        lua_pushcclosure(L, callbackTrampoline, 2)

        // Set as global
        lua_setglobal(L, name)
    }

    private func unregisterCallbackGlobal(_ name: String) {
        guard let L = L else { return }
        lua_pushnil(L)
        lua_setglobal(L, name)
    }

    // MARK: - Invocation (called from the trampoline)

    fileprivate func invokeCallback(name: String, arguments: [LuaValue]) throws -> LuaValue {
        guard let callback = callbacks[name] else {
            throw LuaError.callbackError("Callback '\(name)' not found")
        }

        // Set this engine as current for the duration of the callback
        // This allows modules to access the engine for memory tracking
        setAsCurrentEngine()
        defer { clearCurrentEngine() }

        return try callback(arguments)
    }
}

// MARK: - Lua C Callbacks

/// Callback trampoline for Swift function calls from Lua
private func callbackTrampoline(_ L: OpaquePointer?) -> Int32 {
    guard let L = L else { return 0 }

    // Get engine pointer from upvalue 1
    guard lua_islightuserdata(L, lua_upvalueindex(1)) != 0 else {
        lua_pushstring(L, "Invalid engine pointer in callback")
        _ = lua_error(L)
        return 0
    }
    let enginePtr = lua_touserdata(L, lua_upvalueindex(1))

    // Get function name from upvalue 2
    guard lua_isstring(L, lua_upvalueindex(2)) != 0,
          let nameStr = lua_tostring(L, lua_upvalueindex(2)) else {
        lua_pushstring(L, "Invalid function name in callback")
        _ = lua_error(L)
        return 0
    }
    let name = String(cString: nameStr)

    // Get engine
    guard let engine = Unmanaged<LuaEngine>.fromOpaque(enginePtr!).takeUnretainedValue() as LuaEngine? else {
        lua_pushstring(L, "Failed to get engine in callback")
        _ = lua_error(L)
        return 0
    }

    // Collect arguments from stack
    let nargs = lua_gettop(L)
    var arguments: [LuaValue] = []
    if nargs > 0 {
        for i in 1...nargs {
            arguments.append(valueFromLuaStack(L, at: i))
        }
    }

    // Invoke the Swift callback
    do {
        let result = try engine.invokeCallback(name: name, arguments: arguments)
        pushSimpleValue(L, result)
        return 1
    } catch let error as LuaError {
        lua_pushstring(L, error.localizedDescription)
        _ = lua_error(L)
        return 0
    } catch {
        lua_pushstring(L, "Swift callback error: \(error.localizedDescription)")
        _ = lua_error(L)
        return 0
    }
}
