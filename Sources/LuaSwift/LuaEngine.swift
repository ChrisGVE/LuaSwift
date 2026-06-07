//
//  LuaEngine.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CLua

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
    /// internal: shared across LuaEngine extension files
    internal var L: OpaquePointer?

    /// Registered value servers
    /// internal: managed by LuaEngine+ValueServer.swift
    internal var servers: [String: LuaValueServer] = [:]

    /// Registered callbacks
    private var callbacks: [String: ([LuaValue]) throws -> LuaValue] = [:]

    /// Active coroutines (UUID -> registry reference for GC protection)
    /// internal: managed by LuaEngine+Coroutines.swift
    internal var coroutines: [UUID: Int32] = [:]

    /// Configuration
    public let configuration: LuaEngineConfiguration

    /// Lock for thread safety
    /// internal: shared across LuaEngine extension files
    internal let lock = NSRecursiveLock()

    /// Maximum instruction count per pcall (0 = unlimited).
    /// internal: shared with LuaEngine+Execution/+Coroutines extensions
    internal var instructionLimit: Int = 0

    /// Separate lock for memory tracking to avoid deadlock with main lock.
    /// The main lock is held during Lua execution, and callbacks during execution
    /// may need to track memory allocations.
    private let memoryLock = NSLock()

    /// Last write error (used to communicate errors from __newindex callback)
    /// internal: set in LuaEngine+ValueServer.swift, checked on execution paths
    internal var lastWriteError: LuaError?

    /// Allocation-accounting box passed as `ud` to the custom `lua_Alloc`
    /// function when ``LuaEngineConfiguration/vmMemoryLimit`` is set.
    /// `nil` when the limit is disabled (state created via `luaL_newstate`).
    /// Freed in `deinit`, strictly **after** `lua_close` — the allocator
    /// dereferences it for every free performed during close.
    /// internal: shared with LuaEngine+VMAllocator.swift
    internal var vmAccounting: UnsafeMutablePointer<VMAllocationAccounting>?

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

        // Create Lua state — with a custom accounting allocator when a VM
        // memory limit is configured, otherwise via luaL_newstate exactly as
        // before (zero behavior change for existing users).
        let state: OpaquePointer
        if configuration.vmMemoryLimit > 0 {
            state = try Self.makeLimitedState(limit: configuration.vmMemoryLimit,
                                              accounting: &vmAccounting)
        } else {
            guard let unlimited = luaL_newstate() else {
                throw LuaError.initializationFailed
            }
            state = unlimited
        }
        self.L = state

        // Open standard libraries. With a VM limit active, run them inside a
        // protected call so an allocation denial during library setup throws
        // cleanly instead of aborting via the panic handler.
        if configuration.vmMemoryLimit > 0 {
            do {
                try Self.openLibrariesProtected(on: state)
            } catch {
                lua_close(state)
                self.L = nil
                freeVMAccounting()
                throw error
            }
        } else {
            luaL_openlibs(state)
        }

        // Apply sandboxing if enabled
        if configuration.sandboxed {
            applySandbox(hasPackagePath: configuration.packagePath != nil)
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
        // The allocator is invoked for every free during lua_close above, so
        // the accounting box must outlive the close call.
        freeVMAccounting()
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

    // MARK: - Private Methods

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
