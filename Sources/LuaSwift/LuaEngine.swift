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
///
/// Use this structure to customize the behavior of ``LuaEngine``.
/// The most common use case is choosing between sandboxed (safe) and
/// unrestricted (full access) modes.
///
/// ## Creating a Configuration
///
/// ```swift
/// // Use the default sandboxed configuration
/// let engine1 = try LuaEngine()
///
/// // Or explicitly specify configuration
/// let config = LuaEngineConfiguration(
///     sandboxed: true,
///     packagePath: "/path/to/lua/modules",
///     memoryLimit: 0
/// )
/// let engine2 = try LuaEngine(configuration: config)
/// ```
///
/// ## Sandboxing
///
/// When ``sandboxed`` is `true` (the default), the following functions are disabled:
/// - `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv`, `os.setlocale`
/// - `io.*` (all IO functions)
/// - `debug.*` (all debug functions)
/// - `loadfile`, `dofile`, `load`, `loadstring`
///
/// Safe libraries remain available: `math`, `string`, `table`, `coroutine`, `utf8`
public struct LuaEngineConfiguration {
    /// Whether to remove dangerous functions (os.execute, io.*, etc.)
    ///
    /// When `true`, potentially dangerous functions that could access the
    /// filesystem or execute system commands are removed from the Lua environment.
    /// This is recommended for running untrusted code.
    ///
    /// Default: `true`
    public var sandboxed: Bool

    /// Custom package path for `require()` statements.
    ///
    /// If set, this path is prepended to Lua's package.path, allowing
    /// `require()` to find Lua modules in the specified directory.
    ///
    /// Example: Setting to `"/app/lua"` allows `require("mymodule")` to
    /// find `/app/lua/mymodule.lua`.
    ///
    /// Default: `nil` (use Lua's default package path)
    public var packagePath: String?

    /// Memory limit in bytes (0 = unlimited).
    ///
    /// When set to a positive value, limits the total memory the Lua
    /// state can allocate. Exceeding this limit will cause memory
    /// allocation to fail.
    ///
    /// Default: `0` (unlimited)
    public var memoryLimit: Int

    /// Default configuration with sandboxing enabled.
    ///
    /// This is the recommended configuration for most use cases.
    /// Dangerous functions are disabled but all safe standard libraries
    /// are available.
    public static let `default` = LuaEngineConfiguration(
        sandboxed: true,
        packagePath: nil,
        memoryLimit: 0
    )

    /// Configuration with no restrictions (use with caution).
    ///
    /// - Warning: Only use this configuration with trusted Lua code.
    ///   Unrestricted access allows file operations, system commands,
    ///   and other potentially dangerous operations.
    public static let unrestricted = LuaEngineConfiguration(
        sandboxed: false,
        packagePath: nil,
        memoryLimit: 0
    )

    /// Creates a new engine configuration.
    ///
    /// - Parameters:
    ///   - sandboxed: Whether to disable dangerous functions. Default `true`.
    ///   - packagePath: Custom path for Lua module loading. Default `nil`.
    ///   - memoryLimit: Maximum memory in bytes (0 = unlimited). Default `0`.
    public init(sandboxed: Bool, packagePath: String?, memoryLimit: Int) {
        self.sandboxed = sandboxed
        self.packagePath = packagePath
        self.memoryLimit = memoryLimit
    }
}

/// Main Lua execution engine.
///
/// `LuaEngine` provides a type-safe Swift interface to the Lua interpreter.
/// It supports Lua 5.1 through 5.5, with the version selected at compile time.
///
/// ## Overview
///
/// The engine handles:
/// - Creating and managing the Lua state
/// - Executing Lua code with ``run(_:)`` and ``evaluate(_:)``
/// - Registering value servers for bidirectional data access
/// - Registering Swift callbacks callable from Lua
/// - Creating and managing coroutines
/// - Sandboxing for security
///
/// ## Basic Usage
///
/// ```swift
/// let engine = try LuaEngine()
///
/// // Execute and get result
/// let result = try engine.evaluate("return 1 + 2")
/// print(result.numberValue!) // 3.0
///
/// // Execute without needing result
/// try engine.run("x = 10")
///
/// // Access global variables
/// let x = try engine.evaluate("return x")
/// ```
///
/// ## Swift Callbacks
///
/// Register Swift functions that Lua code can call:
///
/// ```swift
/// engine.registerFunction(name: "add") { args in
///     guard let a = args[0].numberValue,
///           let b = args[1].numberValue else {
///         throw LuaError.callbackError("Expected two numbers")
///     }
///     return .number(a + b)
/// }
///
/// let sum = try engine.evaluate("return add(3, 4)")
/// // sum.numberValue == 7
/// ```
///
/// ## Value Servers
///
/// Expose Swift data structures to Lua with ``LuaValueServer``:
///
/// ```swift
/// engine.register(server: myDataServer)
/// let value = try engine.evaluate("return MyData.user.name")
///
/// // If server supports writing:
/// try engine.run("MyData.cache.result = 42")
/// ```
///
/// ## Coroutines
///
/// Create and manage Lua coroutines:
///
/// ```swift
/// let handle = try engine.createCoroutine(code: """
///     local x = coroutine.yield(1)
///     return x * 2
/// """)
///
/// let result1 = try engine.resume(handle)  // .yielded([.number(1)])
/// let result2 = try engine.resume(handle, with: [.number(5)])  // .completed(.number(10))
/// engine.destroy(handle)
/// ```
///
/// ## Thread Safety
///
/// `LuaEngine` is thread-safe for individual method calls. Each public
/// method acquires a lock before accessing the Lua state. For high
/// concurrency, use a pool of engines rather than sharing one instance.
///
/// ## Topics
///
/// ### Creating an Engine
/// - ``init(configuration:)``
/// - ``LuaEngineConfiguration``
///
/// ### Executing Code
/// - ``run(_:)``
/// - ``evaluate(_:)``
///
/// ### Value Servers
/// - ``register(server:)``
/// - ``unregister(namespace:)``
///
/// ### Swift Callbacks
/// - ``registerFunction(name:callback:)``
/// - ``unregisterFunction(name:)``
///
/// ### Coroutines
/// - ``createCoroutine(code:)``
/// - ``resume(_:with:)``
/// - ``coroutineStatus(_:)``
/// - ``destroy(_:)``
public final class LuaEngine {
    /// The underlying Lua state
    private var L: OpaquePointer?

    /// Registered value servers
    private var servers: [String: LuaValueServer] = [:]

    /// Registered callbacks
    private var callbacks: [String: ([LuaValue]) throws -> LuaValue] = [:]

    /// Active coroutines (UUID -> registry reference for GC protection)
    private var coroutines: [UUID: Int32] = [:]

    /// Configuration
    public let configuration: LuaEngineConfiguration

    /// Lock for thread safety
    private let lock = NSRecursiveLock()

    /// Separate lock for memory tracking to avoid deadlock with main lock.
    /// The main lock is held during Lua execution, and callbacks during execution
    /// may need to track memory allocations.
    private let memoryLock = NSLock()

    /// Last write error (used to communicate errors from __newindex callback)
    fileprivate var lastWriteError: LuaError?

    /// Current allocated bytes tracked by Swift modules
    private var _allocatedBytes: Int = 0

    /// Thread-local key for storing the current engine during callback execution
    private static let currentEngineKey = "LuaSwift.CurrentEngine"

    // MARK: - Memory Tracking

    /// Current allocated bytes tracked by Swift modules.
    ///
    /// This tracks memory allocated by Swift-backed modules like Array and LinAlg.
    /// It does not include Lua's internal memory usage.
    public var allocatedBytes: Int {
        memoryLock.lock()
        defer { memoryLock.unlock() }
        return _allocatedBytes
    }

    /// Track a memory allocation for Swift modules.
    ///
    /// Call this before allocating large data structures in Swift modules.
    /// If the allocation would exceed the configured memory limit, this throws
    /// a `memoryError`.
    ///
    /// - Parameter bytes: Number of bytes to allocate
    /// - Throws: `LuaError.memoryError` if the allocation would exceed the limit
    public func trackAllocation(bytes: Int) throws {
        memoryLock.lock()
        defer { memoryLock.unlock() }

        if configuration.memoryLimit > 0 {
            if _allocatedBytes + bytes > configuration.memoryLimit {
                throw LuaError.memoryError("Memory limit exceeded: tried to allocate \(bytes) bytes, limit is \(configuration.memoryLimit), already allocated \(_allocatedBytes)")
            }
        }
        _allocatedBytes += bytes
    }

    /// Track a memory deallocation for Swift modules.
    ///
    /// Call this when freeing memory in Swift modules.
    ///
    /// - Parameter bytes: Number of bytes freed
    public func trackDeallocation(bytes: Int) {
        memoryLock.lock()
        defer { memoryLock.unlock() }
        _allocatedBytes = max(0, _allocatedBytes - bytes)
    }

    /// Reset the memory tracker to zero.
    ///
    /// Useful for testing or when reusing an engine.
    public func resetMemoryTracker() {
        memoryLock.lock()
        defer { memoryLock.unlock() }
        _allocatedBytes = 0
    }

    /// Get the current engine from thread-local storage.
    ///
    /// This is available during callback execution from Swift modules.
    /// Returns nil if called outside of a callback context.
    public static var currentEngine: LuaEngine? {
        Thread.current.threadDictionary[currentEngineKey] as? LuaEngine
    }

    /// Set the current engine in thread-local storage.
    private func setAsCurrentEngine() {
        Thread.current.threadDictionary[Self.currentEngineKey] = self
    }

    /// Clear the current engine from thread-local storage.
    private func clearCurrentEngine() {
        Thread.current.threadDictionary.removeObject(forKey: Self.currentEngineKey)
    }

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

    // MARK: - Lua Function Calls

    /// Call a Lua function by its registry reference.
    ///
    /// This allows Swift code to call Lua functions that were passed as arguments
    /// to Swift callbacks. The function reference comes from a `LuaValue.luaFunction`
    /// case created when receiving function arguments.
    ///
    /// - Parameters:
    ///   - ref: The registry reference from `LuaValue.luaFunction`
    ///   - args: Arguments to pass to the Lua function
    /// - Returns: The return value from the Lua function
    /// - Throws: `LuaError` if the call fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// engine.registerFunction(name: "map") { args in
    ///     guard case .luaFunction(let funcRef) = args[0],
    ///           let arr = args[1].arrayValue else {
    ///         throw LuaError.callbackError("Expected function and array")
    ///     }
    ///     var result: [LuaValue] = []
    ///     for item in arr {
    ///         let mapped = try engine.callLuaFunction(ref: funcRef, args: [item])
    ///         result.append(mapped)
    ///     }
    ///     return .array(result)
    /// }
    /// ```
    public func callLuaFunction(ref: Int32, args: [LuaValue]) throws -> LuaValue {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Push the function from the registry
        _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(ref))

        // Verify it's a function
        if lua_type(L, -1) != LUA_TFUNCTION {
            lua_pop(L, 1)
            throw LuaError.runtimeError("Invalid function reference")
        }

        // Push arguments
        for arg in args {
            pushSimpleValue(L, arg)
        }

        // Call the function
        let callResult = lua_pcall(L, Int32(args.count), 1, 0)
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.runtimeError(message)
        }

        // Get the result
        let result = valueFromStack(at: -1)
        lua_pop(L, 1)
        return result
    }

    /// Release a Lua function reference.
    ///
    /// Call this when you're done with a function reference to allow
    /// the Lua garbage collector to reclaim the function. This is important
    /// to prevent memory leaks when storing function references long-term.
    ///
    /// - Parameter ref: The registry reference to release
    public func releaseLuaFunction(ref: Int32) {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else { return }
        luaL_unref(L, LUA_REGISTRYINDEX, ref)
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

    // MARK: - Coroutines

    /// Create a new coroutine from Lua code.
    ///
    /// The coroutine starts in a suspended state. Use `resume(_:with:)` to begin
    /// execution. The coroutine can yield values using `coroutine.yield()` in Lua.
    ///
    /// - Parameter code: The Lua code to execute in the coroutine
    /// - Returns: A handle to the coroutine
    /// - Throws: `LuaError` if the code cannot be loaded
    ///
    /// ## Example
    ///
    /// ```swift
    /// let handle = try engine.createCoroutine(code: """
    ///     local x = coroutine.yield(1)
    ///     local y = coroutine.yield(x + 1)
    ///     return y * 2
    /// """)
    /// ```
    public func createCoroutine(code: String) throws -> CoroutineHandle {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Create a new Lua thread
        guard let thread = lua_newthread(L) else {
            throw LuaError.coroutineError("Failed to create thread")
        }

        // Load the code into the thread
        let loadResult = luaL_loadstring(thread, code)
        if loadResult != LUA_OK {
            let message = lua_tostring(thread, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)  // Pop the thread from main state
            throw LuaError.syntaxError(message)
        }

        // Store the thread in the registry to prevent garbage collection
        // Thread is on top of main state stack
        let ref = luaL_ref(L, LUA_REGISTRYINDEX)

        let id = UUID()
        coroutines[id] = ref

        return CoroutineHandle(id: id, thread: thread)
    }

    /// Resume a suspended coroutine.
    ///
    /// Call this to start a new coroutine or continue one that yielded.
    ///
    /// - Parameters:
    ///   - handle: The coroutine handle from `createCoroutine`
    ///   - values: Optional values to pass to the coroutine. On first resume,
    ///             these become the function arguments. On subsequent resumes,
    ///             they become the return values of `coroutine.yield()`.
    /// - Returns: The result of the resume operation
    ///
    /// ## Example
    ///
    /// ```swift
    /// // First resume starts the coroutine
    /// let result1 = try engine.resume(handle)
    /// // result1 == .yielded([.number(1.0)])
    ///
    /// // Pass a value back into the coroutine
    /// let result2 = try engine.resume(handle, with: [.number(10.0)])
    /// // result2 == .yielded([.number(11.0)])
    /// ```
    public func resume(_ handle: CoroutineHandle, with values: [LuaValue] = []) throws -> CoroutineResult {
        lock.lock()
        defer { lock.unlock() }

        guard coroutines[handle.id] != nil else {
            throw LuaError.coroutineError("Coroutine not found or already destroyed")
        }

        let thread = handle.threadPointer

        // Push values onto the thread's stack
        for value in values {
            pushValueOnThread(thread, value)
        }

        // Resume the coroutine
        var nresults: Int32 = 0
        let status = lua_resume(thread, L, Int32(values.count), &nresults)

        switch status {
        case LUA_OK:
            // Coroutine completed normally
            let result = valueFromThread(thread, at: -1)
            if nresults > 0 {
                lua_pop(thread, nresults)
            }
            return .completed(result)

        case LUA_YIELD:
            // Coroutine yielded
            var yieldedValues: [LuaValue] = []
            if nresults > 0 {
                // Read from bottom of result section to top: -nresults, ..., -1
                for i in 0..<nresults {
                    yieldedValues.append(valueFromThread(thread, at: -nresults + i))
                }
                lua_pop(thread, nresults)
            }
            return .yielded(yieldedValues)

        default:
            // Error occurred
            let message = lua_tostring(thread, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(thread, 1)
            return .error(LuaError.coroutineError(message))
        }
    }

    /// Get the status of a coroutine.
    ///
    /// - Parameter handle: The coroutine handle
    /// - Returns: The current status of the coroutine
    public func coroutineStatus(_ handle: CoroutineHandle) -> CoroutineStatus {
        lock.lock()
        defer { lock.unlock() }

        guard coroutines[handle.id] != nil else {
            return .dead
        }

        let thread = handle.threadPointer
        let status = lua_status(thread)

        switch status {
        case LUA_OK:
            // Need to check if it's dead (finished) or suspended
            // A thread with status OK is either new (suspended) or dead (finished)
            // We check the stack: if empty and status OK after a resume, it's dead
            let top = lua_gettop(thread)
            if top == 0 {
                // Check if there's a function to run
                return .dead
            }
            return .suspended

        case LUA_YIELD:
            return .suspended

        default:
            return .dead
        }
    }

    /// Destroy a coroutine and release its resources.
    ///
    /// After calling this, the handle is no longer valid. It's safe to call
    /// this on an already-destroyed or completed coroutine.
    ///
    /// - Parameter handle: The coroutine handle to destroy
    public func destroy(_ handle: CoroutineHandle) {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L, let ref = coroutines[handle.id] else {
            return
        }

        // Remove from registry (allows garbage collection)
        luaL_unref(L, LUA_REGISTRYINDEX, ref)
        coroutines.removeValue(forKey: handle.id)
    }

    // MARK: - Private Coroutine Helpers

    private func pushValueOnThread(_ thread: OpaquePointer, _ value: LuaValue) {
        switch value {
        case .string(let str):
            lua_pushstring(thread, str)
        case .number(let num):
            lua_pushnumber(thread, num)
        case .complex(let re, let im):
            // Push complex as table with marker - metatable will be set if complex module is loaded
            pushComplexOnThread(thread, re: re, im: im)
        case .bool(let b):
            lua_pushboolean(thread, b ? 1 : 0)
        case .nil:
            lua_pushnil(thread)
        case .table(let dict):
            lua_newtable(thread)
            for (k, v) in dict {
                lua_pushstring(thread, k)
                pushValueOnThread(thread, v)
                lua_settable(thread, -3)
            }
        case .array(let arr):
            lua_newtable(thread)
            for (i, v) in arr.enumerated() {
                pushValueOnThread(thread, v)
                lua_rawseti(thread, -2, lua_Integer(i + 1))
            }
        case .luaFunction(let ref):
            // Push the function from the registry
            _ = lua_rawgeti(thread, LUA_REGISTRYINDEX, lua_Integer(ref))
        }
    }

    private func pushComplexOnThread(_ thread: OpaquePointer, re: Double, im: Double) {
        // Try to use complex.new if available for proper metatable support
        lua_getglobal(thread, "complex")
        if lua_istable(thread, -1) {
            lua_getfield(thread, -1, "new")
            if lua_isfunction(thread, -1) {
                lua_pushnumber(thread, re)
                lua_pushnumber(thread, im)
                if lua_pcall(thread, 2, 1, 0) == LUA_OK {
                    // Remove the 'complex' table, keep the result
                    lua_remove(thread, -2)
                    return
                }
                // pcall failed, pop error and fall through
                lua_pop(thread, 1)
            } else {
                lua_pop(thread, 1)  // pop non-function
            }
        }
        lua_pop(thread, 1)  // pop complex table or nil

        // Fallback: create table without metatable
        lua_newtable(thread)
        lua_pushnumber(thread, re)
        lua_setfield(thread, -2, "re")
        lua_pushnumber(thread, im)
        lua_setfield(thread, -2, "im")
        lua_pushstring(thread, "complex")
        lua_setfield(thread, -2, "__luaswift_type")
    }

    private func valueFromThread(_ thread: OpaquePointer, at index: Int32) -> LuaValue {
        let type = lua_type(thread, index)

        switch type {
        case LUA_TNIL:
            return .nil

        case LUA_TBOOLEAN:
            return .bool(lua_toboolean(thread, index) != 0)

        case LUA_TNUMBER:
            return .number(lua_tonumber(thread, index))

        case LUA_TSTRING:
            guard let cstr = lua_tostring(thread, index) else { return .nil }
            return .string(String(cString: cstr))

        case LUA_TTABLE:
            return tableFromThread(thread, at: index)

        default:
            return .nil
        }
    }

    private func tableFromThread(_ thread: OpaquePointer, at index: Int32) -> LuaValue {
        var dict: [String: LuaValue] = [:]
        var intKeyedValues: [Int: LuaValue] = [:]
        var hasStringKeys = false

        // Normalize index to absolute
        let absIndex = index < 0 ? lua_gettop(thread) + index + 1 : index

        lua_pushnil(thread)
        while lua_next(thread, absIndex) != 0 {
            let keyType = lua_type(thread, -2)
            let value = valueFromThread(thread, at: -1)

            if keyType == LUA_TNUMBER {
                let keyNum = Int(lua_tonumber(thread, -2))
                intKeyedValues[keyNum] = value
            } else if keyType == LUA_TSTRING {
                hasStringKeys = true
                if let keyStr = lua_tostring(thread, -2) {
                    let key = String(cString: keyStr)
                    dict[key] = value
                }
            }

            lua_pop(thread, 1)
        }

        // Check for complex number (has __luaswift_type = "complex")
        if let typeMarker = dict["__luaswift_type"]?.stringValue, typeMarker == "complex",
           let re = dict["re"]?.numberValue,
           let im = dict["im"]?.numberValue {
            return .complex(re: re, im: im)
        }

        // Check if integer keys form a contiguous array starting at 1
        if !hasStringKeys, let arr = convertToArrayIfContiguous(intKeyedValues) {
            return .array(arr)
        }

        // Not a pure array - merge all values into dict
        if !intKeyedValues.isEmpty || !dict.isEmpty {
            for (key, val) in intKeyedValues {
                dict[String(key)] = val
            }
            return .table(dict)
        }

        return .table([:])
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

        case LUA_TFUNCTION:
            // Store function in registry and return reference
            lua_pushvalue(L, index)  // Push copy of function
            let ref = luaL_ref(L, LUA_REGISTRYINDEX)
            return .luaFunction(ref)

        default:
            return .nil
        }
    }

    private func tableFromStack(at index: Int32) -> LuaValue {
        guard let L = L else { return .nil }

        var dict: [String: LuaValue] = [:]
        var intKeyedValues: [Int: LuaValue] = [:]
        var hasStringKeys = false

        // Normalize index to absolute
        let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index

        lua_pushnil(L)  // First key
        while lua_next(L, absIndex) != 0 {
            // Key is at -2, value is at -1

            let keyType = lua_type(L, -2)
            let value = valueFromStack(at: -1)

            if keyType == LUA_TNUMBER {
                let keyNum = Int(lua_tonumber(L, -2))
                intKeyedValues[keyNum] = value
            } else if keyType == LUA_TSTRING {
                hasStringKeys = true
                if let keyStr = lua_tostring(L, -2) {
                    let key = String(cString: keyStr)
                    dict[key] = value
                }
            }

            lua_pop(L, 1)  // Pop value, keep key for next iteration
        }

        // Check if integer keys form a contiguous array starting at 1
        if !hasStringKeys, let arr = convertToArrayIfContiguous(intKeyedValues) {
            return .array(arr)
        }

        // Not a pure array - merge all values into dict
        if !intKeyedValues.isEmpty || !dict.isEmpty {
            for (key, val) in intKeyedValues {
                dict[String(key)] = val
            }
            return .table(dict)
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

    case .luaFunction(let ref):
        // Push the function from the registry
        _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(ref))
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

    case LUA_TFUNCTION:
        // Store function in registry and return reference
        lua_pushvalue(L, index)  // Push copy of function
        let ref = luaL_ref(L, LUA_REGISTRYINDEX)
        return .luaFunction(ref)

    default:
        return .nil
    }
}

// MARK: - File-scope Table Conversion Helpers

/// Convert integer-keyed values to a contiguous array if possible.
/// Uses O(n) min/max check instead of O(n log n) sorting.
@inline(__always)
private func convertToArrayIfContiguous(_ intKeyedValues: [Int: LuaValue]) -> [LuaValue]? {
    guard !intKeyedValues.isEmpty else { return nil }

    // O(n) check: find min and max, verify contiguity
    var minKey = Int.max
    var maxKey = Int.min
    for key in intKeyedValues.keys {
        if key < minKey { minKey = key }
        if key > maxKey { maxKey = key }
    }

    // Must start at 1 and be contiguous
    guard minKey == 1 && maxKey == intKeyedValues.count else { return nil }

    // Build array in order (O(n))
    var result = [LuaValue]()
    result.reserveCapacity(intKeyedValues.count)
    for i in 1...maxKey {
        guard let value = intKeyedValues[i] else { return nil }
        result.append(value)
    }
    return result
}

/// Get a table from the Lua stack (static version for use in callbacks)
private func tableFromLuaStack(_ L: OpaquePointer, at index: Int32) -> LuaValue {
    var dict: [String: LuaValue] = [:]
    var intKeyedValues: [Int: LuaValue] = [:]
    var hasStringKeys = false

    // Normalize index to absolute
    let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index

    lua_pushnil(L)  // First key
    while lua_next(L, absIndex) != 0 {
        // Key is at -2, value is at -1

        let keyType = lua_type(L, -2)
        let value = valueFromLuaStack(L, at: -1)

        if keyType == LUA_TNUMBER {
            let keyNum = Int(lua_tonumber(L, -2))
            intKeyedValues[keyNum] = value
        } else if keyType == LUA_TSTRING {
            hasStringKeys = true
            if let keyStr = lua_tostring(L, -2) {
                let key = String(cString: keyStr)
                dict[key] = value
            }
        }

        lua_pop(L, 1)  // Pop value, keep key for next iteration
    }

    // Check for complex number (has __luaswift_type = "complex")
    if let typeMarker = dict["__luaswift_type"]?.stringValue, typeMarker == "complex",
       let re = dict["re"]?.numberValue,
       let im = dict["im"]?.numberValue {
        return .complex(re: re, im: im)
    }

    // Check if integer keys form a contiguous array starting at 1
    if !hasStringKeys, let arr = convertToArrayIfContiguous(intKeyedValues) {
        return .array(arr)
    }

    // Not a pure array - merge all values into dict
    if !intKeyedValues.isEmpty || !dict.isEmpty {
        for (key, val) in intKeyedValues {
            dict[String(key)] = val
        }
        return .table(dict)
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
    case .complex(let re, let im):
        pushComplexValue(L, re: re, im: im)
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
    case .luaFunction(let ref):
        // Push the function from the registry
        _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(ref))
    }
}

/// Push a complex number onto the Lua stack
private func pushComplexValue(_ L: OpaquePointer, re: Double, im: Double) {
    // Try to use complex.new if available for proper metatable support
    lua_getglobal(L, "complex")
    if lua_istable(L, -1) {
        lua_getfield(L, -1, "new")
        if lua_isfunction(L, -1) {
            lua_pushnumber(L, re)
            lua_pushnumber(L, im)
            if lua_pcall(L, 2, 1, 0) == LUA_OK {
                // Remove the 'complex' table, keep the result
                lua_remove(L, -2)
                return
            }
            // pcall failed, pop error and fall through
            lua_pop(L, 1)
        } else {
            lua_pop(L, 1)  // pop non-function
        }
    }
    lua_pop(L, 1)  // pop complex table or nil

    // Fallback: create table without metatable
    lua_newtable(L)
    lua_pushnumber(L, re)
    lua_setfield(L, -2, "re")
    lua_pushnumber(L, im)
    lua_setfield(L, -2, "im")
    lua_pushstring(L, "complex")
    lua_setfield(L, -2, "__luaswift_type")
}

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
