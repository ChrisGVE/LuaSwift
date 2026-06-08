//
//  LuaEngine.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-28.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine.swift
//
//  Context: Core of the LuaEngine class — stored state only: the Lua state
//  pointer, server/callback/coroutine registries, locks, atomics, and the
//  init/deinit lifecycle. All methods live in sibling extension files:
//    LuaEngine+Execution.swift      — run/evaluate, instruction limit
//    LuaEngine+Bytecode.swift       — precompile/CompiledChunk
//    LuaEngine+FunctionCalls.swift  — Swift calls Lua
//    LuaEngine+Callbacks.swift      — Lua calls Swift
//    LuaEngine+Coroutines.swift     — coroutine management
//    LuaEngine+ValueServer.swift    — value server registration
//    LuaEngine+Bridging.swift       — LuaValue <-> stack conversion
//    LuaEngine+Sandbox.swift        — sandboxing
//    LuaEngine+VMAllocator.swift    — VM memory limit allocator
//    LuaEngine+TLS.swift            — TLS helpers + Swift memory tracking
//    LuaEngine+Introspection.swift  — globals/modules introspection (#21)
//    LuaEngine+Debug.swift          — debug-hook public API (#20)
//    LuaEngine+CompositorHook.swift — compositor hook callback + sentinels
//  Configuration: LuaEngineConfiguration.swift
//

import Atomics
import Foundation
import CLua

// MARK: - Debug Step State (internal)

/// Tracks the current stepping mode during a debug session.
///
/// Nil means the handler fires on every LINE event (breakpoint mode).
/// Each non-nil case encodes the from-level captured at the point the
/// step command was issued; the `shouldPauseForStep` helper compares
/// the live stack depth against that level to decide when to pause.
///
/// ## Tail-call handling
///
/// Depth comparisons use strict `<` (stepOut) and `<=` (stepOver) so a
/// tail call that collapses a frame still triggers the correct pause:
/// when `f` tail-calls `g`, Lua may not emit a separate HOOKRET for `f`
/// (5.2+: emits HOOKTAILCALL for `g`; 5.1: emits HOOKTAILRET for `f`
/// before the tail call). Either way, the live depth after `g` returns is
/// strictly less than `fromLevel` (stepOut) or equal to `fromLevel`
/// (stepOver), so the comparison fires at the right point.
internal enum StepState {
    case stepOver(fromLevel: Int)
    case stepInto
    case stepOut(fromLevel: Int)
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
    /// internal: shared across LuaEngine extension files
    internal var L: OpaquePointer?

    /// Registered value servers
    /// internal: managed by LuaEngine+ValueServer.swift
    internal var servers: [String: LuaValueServer] = [:]

    /// Registered callbacks
    /// internal: managed by LuaEngine+Callbacks.swift
    internal var callbacks: [String: ([LuaValue]) throws -> LuaValue] = [:]

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

    // MARK: - Cooperative Cancellation State (#22)

    /// Set by ``requestCancellation()`` from any thread; read inside the C
    /// compositor hook on the VM thread. Uses release/acquire ordering so the
    /// store is visible to the hook before the next VM instruction boundary.
    ///
    /// Not cleared automatically on a clean run completion — only
    /// ``resetCancellation()`` clears it (user intent).
    internal let cancellationRequested = ManagedAtomic<Bool>(false)

    /// Out-of-band abort reason written by the compositor hook before it calls
    /// `lua_error`, and consumed by ``errorFromCode(_:message:)`` after
    /// `lua_pcall` returns. Atomic so concurrent engines do not clobber each
    /// other. Values: 0 = none, 1 = cancelled, 2 = instructionLimit.
    ///
    /// Reset to 0 at the start of every run entry point so a stale value from
    /// a prior run cannot affect the next one.
    internal let abortReason = ManagedAtomic<UInt8>(0)

    /// Accumulated instruction count across periodic hook fires within a single
    /// run. Reset to 0 at the start of every run entry point. Not atomic —
    /// only ever written/read on the VM thread (inside or around the C hook).
    internal var instructionAccumulator: Int = 0

    /// Number of Lua VM instructions between compositor hook fires.
    ///
    /// The default of 10 000 was measured to interrupt `while true do end`
    /// within ~1–3 ms on Apple Silicon at 1 GHz-equivalent Lua throughput,
    /// well inside the 200 ms target (CI threshold 400 ms). Tighter values
    /// reduce latency but add proportionally more hook overhead per second of
    /// normal execution; 10 000 represents a good default trade-off.
    ///
    /// When an instructionLimit is set, the hook is armed with
    /// min(hookInterval, instructionLimit) so the first fire cannot overshoot
    /// a limit smaller than K.
    internal let hookInterval: Int = 10_000

    /// The count actually passed to `lua_sethook` in the most recent
    /// ``armCompositorHook`` call. The compositor accumulates this value (not
    /// always `hookInterval`) so instruction-limit accounting is exact when the
    /// limit is smaller than the interval.
    ///
    /// Only written on the VM thread (inside `armCompositorHook`) and read on
    /// the VM thread (inside the compositor callback); no atomic needed.
    internal var armedHookCount: Int = 0

    /// Separate lock for memory tracking to avoid deadlock with main lock.
    /// The main lock is held during Lua execution, and callbacks during execution
    /// may need to track memory allocations.
    /// internal: accessed by memory-tracking methods in LuaEngine+TLS.swift
    internal let memoryLock = NSLock()

    /// Last write error (used to communicate errors from __newindex callback)
    /// internal: set in LuaEngine+ValueServer.swift, checked on execution paths
    internal var lastWriteError: LuaError?

    /// Structured runtime error captured by the errfunc message handler (#19).
    ///
    /// The `@convention(c)` handler (`runtimeErrorHandler` in LuaHelpers.swift)
    /// stores a fully-parsed ``LuaRuntimeFailure`` here while the failing Lua
    /// stack is still intact — before `lua_pcall` unwinds it. After `pcall`
    /// returns, ``errorFromCode(_:message:)`` reads this stash and clears it.
    ///
    /// Reset to `nil` at the start of every run entry point so a stale value
    /// from a prior error run cannot affect the next one.
    ///
    /// internal: written by the errfunc handler, read+cleared by errorFromCode
    internal var pendingRuntimeFailure: LuaRuntimeFailure?

    // MARK: - Debug-Hook State (#20)

    /// The user-supplied debug handler installed via ``setDebugHandler(_:)``.
    ///
    /// `nil` when no handler is active. Written under the engine lock;
    /// read inside the compositor hook on the VM thread (also under lock).
    ///
    /// internal: written by LuaEngine+Debug.swift, read by compositorHookCallback
    internal var debugHandler: LuaDebugHandler?

    /// Atomic pause flag set to `true` immediately before the debug handler is
    /// called and back to `false` immediately after it returns.
    ///
    /// **Purpose:** the engine lock is held by the active run while the hook
    /// fires. To prevent another thread from acquiring the lock and calling
    /// back into the same `lua_State` (C-level UB), every public method that
    /// touches `L` checks this flag **before** `lock.lock()`. If `true`, the
    /// method throws ``LuaError/enginePaused`` immediately. The `<`/`<=` depth
    /// comparisons in the stepping logic also rely on the VM being parked here.
    ///
    /// Uses `ManagedAtomic<Bool>` (swift-atomics) with `.releasing` stores and
    /// `.acquiring` loads. The store-release from the VM thread (setting `true`)
    /// synchronises with the load-acquire from any observer thread, ensuring
    /// that a thread reading `true` sees the fully-consistent paused state before
    /// deciding to throw. Full sequential-consistency (`dmb ish` on ARM64) is not
    /// required here because no other operation must be globally sequenced in
    /// between the store and the load — a release/acquire pair is sufficient.
    ///
    /// internal: written by compositorHookCallback, read by every guarded method
    internal let isPaused = ManagedAtomic<Bool>(false)

    /// The current stepping mode, or `nil` for breakpoint mode (pause on every
    /// LINE event; handler decides via `.continueRun` / `.stop`).
    ///
    /// Only read/written on the VM thread (inside or around the compositor
    /// hook), so no atomic is required.
    ///
    /// internal: managed by compositorHookCallback and LuaEngine+Debug.swift
    internal var stepState: StepState?

    // MARK: - Introspection Bookkeeping (#21)

    /// Names of modules successfully installed via ``ModuleRegistry/install(in:)``
    /// (or individual ``LuaSwiftModule/install(in:)`` calls that call
    /// ``recordInstalledModule(_:)``). Populated on every successful install;
    /// returned by ``installedModuleNames``.
    ///
    /// internal: written by ModuleRegistry.install and recordInstalledModule;
    /// read by the installedModuleNames property under lock.
    internal var installedModules: Set<String> = []

    /// Snapshot of the raw global key set taken at the very end of
    /// ``init(configuration:)`` — after the standard library is opened, all
    /// modules are installed, and sandbox is applied, but before any user code
    /// runs. Used by ``globalNames(includingStandardLibrary:)`` to distinguish
    /// engine-baseline globals from user-defined ones.
    ///
    /// The snapshot uses the same raw ``lua_next`` walk as the introspection
    /// methods — safe at init time because no run is active.
    ///
    /// internal: written once at end of init; read by globalNames under lock.
    internal var baselineGlobalNames: Set<String> = []

    /// Allocation-accounting box passed as `ud` to the custom `lua_Alloc`
    /// function when ``LuaEngineConfiguration/vmMemoryLimit`` is set.
    /// `nil` when the limit is disabled (state created via `luaL_newstate`).
    /// Freed in `deinit`, strictly **after** `lua_close` — the allocator
    /// dereferences it for every free performed during close.
    ///
    /// Held as an opaque raw pointer: the concrete accounting struct stays
    /// private to LuaEngine+VMAllocator.swift, which performs the typed cast
    /// (allocate/free in ``makeLimitedState(limit:accounting:)`` /
    /// ``freeVMAccounting()``).
    /// internal: shared with LuaEngine+VMAllocator.swift
    internal var vmAccounting: UnsafeMutableRawPointer?

    /// Current allocated bytes tracked by Swift modules.
    /// internal: accessed by memory-tracking methods in LuaEngine+TLS.swift
    internal var _allocatedBytes: Int = 0

    /// Thread-local key for storing the current engine during execution.
    ///
    /// The compositor hook reads this key on every fire to recover the owning
    /// engine without a process-global map. The key must survive nested
    /// invocations (callbacks, coroutine resumes) where a deeper frame replaces
    /// the TLS value — see ``setAsCurrentEngine()`` and
    /// ``restoreCurrentEngine(_:)`` (in LuaEngine+TLS.swift).
    internal static let currentEngineKey = "LuaSwift.CurrentEngine"

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

        // Apply sandboxing if enabled. A failure here must surface (the engine
        // would otherwise report itself sandboxed with dangerous globals still
        // live), tearing down the state and accounting box on the way out —
        // same ordering as deinit and the openLibraries throw path above.
        if configuration.sandboxed {
            do {
                try applySandbox(hasPackagePath: configuration.packagePath != nil)
            } catch {
                lua_close(state)
                self.L = nil
                freeVMAccounting()
                throw error
            }
        }

        // Set package path if provided
        if let packagePath = configuration.packagePath {
            setPackagePath(packagePath)
        }

        // Snapshot the baseline global key set for includingStandardLibrary
        // filtering (F4 / #21). This must come last — after stdlib open, sandbox
        // application, and any future init-time module installs — so that the
        // snapshot reflects exactly what the engine exposes before user code runs.
        baselineGlobalNames = rawGlobalKeySet(on: state)
    }

    deinit {
        if let L = L {
            lua_close(L)
        }
        // The allocator is invoked for every free during lua_close above, so
        // the accounting box must outlive the close call.
        freeVMAccounting()
    }
}
