//
//  LuaEngine+TLS.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+TLS.swift
//
//  Context: Thread-local storage (TLS) helpers and Swift-module memory
//  tracking for LuaEngine. Extracted from LuaEngine.swift to bring the
//  core file toward the 400-line limit while keeping all stored properties
//  centralised there.
//
//  ## TLS pattern
//
//  Each run entry point calls setAsCurrentEngine() before the pcall and
//  restoreCurrentEngine(_:) in a defer block after it. This save/restore
//  contract keeps the TLS key correct through nested invocations (Swift
//  callbacks mid-run that themselves call back into a different engine).
//  The compositor hook reads currentEngine on every fire to recover the
//  owning engine without a process-global lock.
//
//  ## Memory tracking
//
//  trackAllocation/trackDeallocation/resetMemoryTracker are guarded by the
//  private `memoryLock` (an NSLock in LuaEngine.swift) so they are safe to
//  call from Swift callbacks that execute on the VM thread while the main
//  engine lock is already held.
//
//  Neighbors:
//    LuaEngine.swift                — stored properties (currentEngineKey,
//                                     memoryLock, _allocatedBytes)
//    LuaEngine+CompositorHook.swift — reads currentEngine on every hook fire
//    LuaEngine+Execution.swift      — calls set/restoreCurrentEngine
//

import Foundation

extension LuaEngine {

    // MARK: - TLS: Current Engine

    /// Get the current engine from thread-local storage.
    ///
    /// Available during callback execution from Swift modules.
    /// Returns nil if called outside of a callback context.
    public static var currentEngine: LuaEngine? {
        Thread.current.threadDictionary[currentEngineKey] as? LuaEngine
    }

    /// Install this engine as the TLS current engine, returning the previous
    /// occupant so the caller can restore it on exit.
    ///
    /// The return value **must** be passed back to ``restoreCurrentEngine(_:)``
    /// in a `defer` block. This save/restore contract ensures that a Swift
    /// callback invoked mid-run does not permanently clear the TLS key when
    /// it finishes, which would prevent the compositor hook from reading the
    /// engine on subsequent fires within the same run.
    ///
    /// internal: used by run entry points (LuaEngine+Execution/+Bytecode/
    /// +FunctionCalls/+Coroutines) and the callback trampoline (+Callbacks).
    @discardableResult
    internal func setAsCurrentEngine() -> LuaEngine? {
        let previous = Thread.current.threadDictionary[Self.currentEngineKey] as? LuaEngine
        Thread.current.threadDictionary[Self.currentEngineKey] = self
        return previous
    }

    /// Restore the TLS current engine to `previous` (the value captured by the
    /// matching ``setAsCurrentEngine()`` call). Passing `nil` removes the key.
    ///
    /// internal: paired with every ``setAsCurrentEngine()`` call
    internal func restoreCurrentEngine(_ previous: LuaEngine?) {
        if let previous {
            Thread.current.threadDictionary[Self.currentEngineKey] = previous
        } else {
            Thread.current.threadDictionary.removeObject(forKey: Self.currentEngineKey)
        }
    }

    /// Convenience: clear the current engine unconditionally.
    ///
    /// Use only at the outermost run boundary where there is guaranteed to be no
    /// enclosing frame that set the TLS. Run entry points must use the
    /// ``setAsCurrentEngine()``/``restoreCurrentEngine(_:)`` pair instead.
    ///
    /// internal: kept for backward compatibility with any callers that do not
    /// nest; prefer the pair form for new code.
    internal func clearCurrentEngine() {
        Thread.current.threadDictionary.removeObject(forKey: Self.currentEngineKey)
    }

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
                throw LuaError.memoryError(
                    "Memory limit exceeded: tried to allocate \(bytes) bytes, " +
                    "limit is \(configuration.memoryLimit), " +
                    "already allocated \(_allocatedBytes)"
                )
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
}
