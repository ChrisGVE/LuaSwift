//
//  LuaEngine.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import CLua

/// Configuration options for the Lua engine.
public struct LuaEngineConfiguration {
    /// Whether to remove dangerous functions (os.execute, io.*, etc.)
    public var sandboxed: Bool

    /// Custom package path for require() (defaults to none)
    public var packagePath: String?

    /// Memory limit in bytes (0 = unlimited)
    public var memoryLimit: Int

    /// Default configuration with sandboxing enabled
    public static let `default` = LuaEngineConfiguration(
        sandboxed: true,
        packagePath: nil,
        memoryLimit: 0
    )

    /// Configuration with no restrictions (use with caution)
    public static let unrestricted = LuaEngineConfiguration(
        sandboxed: false,
        packagePath: nil,
        memoryLimit: 0
    )

    public init(sandboxed: Bool, packagePath: String?, memoryLimit: Int) {
        self.sandboxed = sandboxed
        self.packagePath = packagePath
        self.memoryLimit = memoryLimit
    }
}

/// Main Lua execution engine.
///
/// `LuaEngine` provides a Swift interface to the Lua 5.4 interpreter.
/// It handles:
/// - Creating and managing the Lua state
/// - Registering value servers for data access (read and write)
/// - Executing Lua code and retrieving results
/// - Sandboxing for security
///
/// ## Basic Usage
///
/// ```swift
/// let engine = try LuaEngine()
///
/// // Execute and get result
/// let result = try engine.evaluate("return 1 + 2")
/// print(result.numberValue) // Optional(3.0)
///
/// // Execute without needing result
/// try engine.run("print('Hello')")
///
/// // Execute with a value server
/// engine.register(server: myServer)
/// let value = try engine.evaluate("return MyServer.User.name")
/// ```
///
/// ## Writing to Value Servers
///
/// ```swift
/// // If server's canWrite returns true for the path:
/// try engine.run("MyServer.Cache.result = 42")
/// ```
public final class LuaEngine {
    /// The underlying Lua state
    private var L: OpaquePointer?

    /// Registered value servers
    private var servers: [String: LuaValueServer] = [:]

    /// Configuration
    public let configuration: LuaEngineConfiguration

    /// Lock for thread safety
    private let lock = NSLock()

    /// Last write error (used to communicate errors from __newindex callback)
    fileprivate var lastWriteError: LuaError?

    // MARK: - Initialization

    /// Create a new Lua engine with the specified configuration.
    ///
    /// - Parameter configuration: Engine configuration (defaults to sandboxed)
    /// - Throws: `LuaError.initializationFailed` if the Lua state cannot be created
    public init(configuration: LuaEngineConfiguration = .default) throws {
        self.configuration = configuration

        // Create Lua state
        guard let state = luaL_newstate() else {
            throw LuaError.initializationFailed
        }
        self.L = state

        // Open standard libraries
        luaL_openlibs(state)

        // Apply sandboxing if enabled
        if configuration.sandboxed {
            applySandbox()
        }

        // Set package path if provided
        if let packagePath = configuration.packagePath {
            setPackagePath(packagePath)
        }
    }

    deinit {
        if let L = L {
            lua_close(L)
        }
    }

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

    // MARK: - Execution

    /// Execute Lua code without returning a result.
    ///
    /// Use this when you don't need the return value. Any return values
    /// from the Lua code are discarded.
    ///
    /// - Parameter code: The Lua code to execute
    /// - Throws: `LuaError` if execution fails
    public func run(_ code: String) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Clear any previous write error
        lastWriteError = nil

        // Load the code
        let loadResult = luaL_loadstring(L, code)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Execute with nresults=0 (discard any return values)
        let callResult = lua_pcall(L, 0, 0, 0)
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            // Check if this was a write error we generated
            if let writeError = lastWriteError {
                lastWriteError = nil
                throw writeError
            }

            throw errorFromCode(callResult, message: message)
        }
    }

    /// Execute Lua code and return the result.
    ///
    /// - Parameter code: The Lua code to execute
    /// - Returns: The result of the execution as a `LuaValue`
    /// - Throws: `LuaError` if execution fails
    public func evaluate(_ code: String) throws -> LuaValue {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Clear any previous write error
        lastWriteError = nil

        // Load the code
        let loadResult = luaL_loadstring(L, code)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Execute with nresults=1 (expect one return value)
        let callResult = lua_pcall(L, 0, 1, 0)
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            // Check if this was a write error we generated
            if let writeError = lastWriteError {
                lastWriteError = nil
                throw writeError
            }

            throw errorFromCode(callResult, message: message)
        }

        // Convert result
        let result = valueFromStack(at: -1)
        lua_pop(L, 1)
        return result
    }

    // MARK: - Random Seeding

    /// Set the random seed for math.random().
    ///
    /// Use a fixed seed for reproducible tests.
    ///
    /// - Parameter seed: The seed value
    public func seed(_ seed: Int) throws {
        try run("math.randomseed(\(seed))")
    }

    // MARK: - Private Methods

    private func applySandbox() {
        guard let L = L else { return }

        // Remove dangerous functions
        let dangerous = """
            os.execute = nil
            os.exit = nil
            os.remove = nil
            os.rename = nil
            os.tmpname = nil
            os.getenv = nil
            os.setlocale = nil
            io = nil
            debug = nil
            loadfile = nil
            dofile = nil
            load = nil
            loadstring = nil
        """

        luaL_dostring(L, dangerous)
    }

    private func setPackagePath(_ path: String) {
        guard let L = L else { return }

        let code = "package.path = '\(path)/?.lua;' .. package.path"
        luaL_dostring(L, code)
    }

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

    fileprivate func valueFromStack(at index: Int32) -> LuaValue {
        guard let L = L else { return .nil }

        let type = lua_type(L, index)

        switch type {
        case LUA_TNIL:
            return .nil

        case LUA_TBOOLEAN:
            return .bool(lua_toboolean(L, index) != 0)

        case LUA_TNUMBER:
            return .number(lua_tonumber(L, index))

        case LUA_TSTRING:
            guard let cstr = lua_tostring(L, index) else { return .nil }
            return .string(String(cString: cstr))

        case LUA_TTABLE:
            return tableFromStack(at: index)

        default:
            return .nil
        }
    }

    private func tableFromStack(at index: Int32) -> LuaValue {
        guard let L = L else { return .nil }

        var isArray = true
        var arrayIndex = 1
        var dict: [String: LuaValue] = [:]
        var arr: [LuaValue] = []

        // Normalize index to absolute
        let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index

        lua_pushnil(L)  // First key
        while lua_next(L, absIndex) != 0 {
            // Key is at -2, value is at -1

            let keyType = lua_type(L, -2)
            let value = valueFromStack(at: -1)

            if keyType == LUA_TNUMBER {
                let keyNum = Int(lua_tonumber(L, -2))
                if keyNum == arrayIndex {
                    arr.append(value)
                    arrayIndex += 1
                } else {
                    isArray = false
                    dict[String(keyNum)] = value
                }
            } else if keyType == LUA_TSTRING {
                isArray = false
                if let keyStr = lua_tostring(L, -2) {
                    let key = String(cString: keyStr)
                    dict[key] = value
                }
            }

            lua_pop(L, 1)  // Pop value, keep key for next iteration
        }

        if isArray && !arr.isEmpty {
            return .array(arr)
        } else if !dict.isEmpty {
            // Merge any array elements into dict
            for (i, val) in arr.enumerated() {
                dict[String(i + 1)] = val
            }
            return .table(dict)
        } else if !arr.isEmpty {
            return .array(arr)
        }

        return .table([:])
    }

    private func errorFromCode(_ code: Int32, message: String) -> LuaError {
        switch code {
        case LUA_ERRSYNTAX:
            return .syntaxError(message)
        case LUA_ERRRUN:
            return .runtimeError(message)
        case LUA_ERRMEM:
            return .memoryError(message)
        case LUA_ERRERR:
            return .errorHandlerError(message)
        default:
            return .unknown(code: Int(code), message: message)
        }
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

// MARK: - Lua C Callbacks

/// Callback for server __index metamethod (reads)
private func serverIndexCallback(_ L: OpaquePointer?) -> Int32 {
    guard let L = L else { return 0 }

    // Get the table (self)
    guard lua_istable(L, 1) else { return 0 }

    // Get the key being accessed
    guard lua_isstring(L, 2) != 0 else { return 0 }
    let key = String(cString: lua_tostring(L, 2)!)

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
            if lua_isstring(L, -1) != 0, let pStr = lua_tostring(L, -1) {
                path.append(String(cString: pStr))
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
    let key = String(cString: lua_tostring(L, 2)!)

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
            if lua_isstring(L, -1) != 0, let pStr = lua_tostring(L, -1) {
                path.append(String(cString: pStr))
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
        lua_pushstring(L, str)

    case .number(let num):
        lua_pushnumber(L, num)

    case .bool(let b):
        lua_pushboolean(L, b ? 1 : 0)

    case .nil:
        // Could be nil or could be a path that needs further resolution
        // Create a proxy table for potential further access
        lua_newtable(L)

        // Store path using raw access to avoid triggering __newindex
        lua_newtable(L)
        for (i, p) in path.enumerated() {
            lua_pushstring(L, p)
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
            lua_pushstring(L, k)
            pushSimpleValue(L, v)
            lua_settable(L, -3)
        }

    case .array(let arr):
        lua_newtable(L)
        for (i, v) in arr.enumerated() {
            pushSimpleValue(L, v)
            lua_rawseti(L, -2, lua_Integer(i + 1))
        }
    }
}

/// Get a LuaValue from the Lua stack (static version for use in callbacks)
private func valueFromLuaStack(_ L: OpaquePointer, at index: Int32) -> LuaValue {
    let type = lua_type(L, index)

    switch type {
    case LUA_TNIL:
        return .nil

    case LUA_TBOOLEAN:
        return .bool(lua_toboolean(L, index) != 0)

    case LUA_TNUMBER:
        return .number(lua_tonumber(L, index))

    case LUA_TSTRING:
        guard let cstr = lua_tostring(L, index) else { return .nil }
        return .string(String(cString: cstr))

    case LUA_TTABLE:
        return tableFromLuaStack(L, at: index)

    default:
        return .nil
    }
}

/// Get a table from the Lua stack (static version for use in callbacks)
private func tableFromLuaStack(_ L: OpaquePointer, at index: Int32) -> LuaValue {
    var isArray = true
    var arrayIndex = 1
    var dict: [String: LuaValue] = [:]
    var arr: [LuaValue] = []

    // Normalize index to absolute
    let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index

    lua_pushnil(L)  // First key
    while lua_next(L, absIndex) != 0 {
        // Key is at -2, value is at -1

        let keyType = lua_type(L, -2)
        let value = valueFromLuaStack(L, at: -1)

        if keyType == LUA_TNUMBER {
            let keyNum = Int(lua_tonumber(L, -2))
            if keyNum == arrayIndex {
                arr.append(value)
                arrayIndex += 1
            } else {
                isArray = false
                dict[String(keyNum)] = value
            }
        } else if keyType == LUA_TSTRING {
            isArray = false
            if let keyStr = lua_tostring(L, -2) {
                let key = String(cString: keyStr)
                dict[key] = value
            }
        }

        lua_pop(L, 1)  // Pop value, keep key for next iteration
    }

    if isArray && !arr.isEmpty {
        return .array(arr)
    } else if !dict.isEmpty {
        // Merge any array elements into dict
        for (i, val) in arr.enumerated() {
            dict[String(i + 1)] = val
        }
        return .table(dict)
    } else if !arr.isEmpty {
        return .array(arr)
    }

    return .table([:])
}

/// Push a simple LuaValue (no proxy tables)
private func pushSimpleValue(_ L: OpaquePointer, _ value: LuaValue) {
    switch value {
    case .string(let str):
        lua_pushstring(L, str)
    case .number(let num):
        lua_pushnumber(L, num)
    case .bool(let b):
        lua_pushboolean(L, b ? 1 : 0)
    case .nil:
        lua_pushnil(L)
    case .table(let dict):
        lua_newtable(L)
        for (k, v) in dict {
            lua_pushstring(L, k)
            pushSimpleValue(L, v)
            lua_settable(L, -3)
        }
    case .array(let arr):
        lua_newtable(L)
        for (i, v) in arr.enumerated() {
            pushSimpleValue(L, v)
            lua_rawseti(L, -2, lua_Integer(i + 1))
        }
    }
}
