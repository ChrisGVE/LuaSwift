//
//  CoroutineHandle.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2025-12-30.
//  Copyright © 2025 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

/// A handle to a Lua coroutine.
///
/// Use this handle with `LuaEngine.resume(_:with:)` to resume execution
/// and `LuaEngine.destroy(_:)` to release resources.
///
/// ## Example
///
/// ```swift
/// let engine = try LuaEngine()
/// let handle = try engine.createCoroutine(code: """
///     local x = coroutine.yield(1)
///     return x + 10
/// """)
///
/// // First resume starts the coroutine
/// let result1 = try engine.resume(handle)
/// // result1 == .yielded([.number(1.0)])
///
/// // Second resume continues with a value
/// let result2 = try engine.resume(handle, with: [.number(5.0)])
/// // result2 == .completed(.number(15.0))
///
/// engine.destroy(handle)
/// ```
public struct CoroutineHandle: Equatable, Hashable {
    /// Unique identifier for this coroutine
    public let id: UUID

    /// The underlying Lua thread pointer
    fileprivate let thread: OpaquePointer

    /// Internal initializer
    internal init(id: UUID, thread: OpaquePointer) {
        self.id = id
        self.thread = thread
    }

    public static func == (lhs: CoroutineHandle, rhs: CoroutineHandle) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// The result of resuming a coroutine.
public enum CoroutineResult {
    /// The coroutine yielded with the given values.
    ///
    /// Call `resume(_:with:)` again to continue execution.
    case yielded([LuaValue])

    /// The coroutine completed and returned the given value.
    ///
    /// The coroutine is now dead and cannot be resumed.
    case completed(LuaValue)

    /// An error occurred during execution.
    ///
    /// The coroutine is now dead and cannot be resumed.
    case error(LuaError)
}

/// The status of a coroutine.
public enum CoroutineStatus {
    /// The coroutine is suspended and waiting to be resumed.
    case suspended

    /// The coroutine is currently running.
    case running

    /// The coroutine has finished (returned or errored).
    case dead

    /// The coroutine is active but not running (resumed another coroutine).
    case normal
}

// MARK: - Internal Extension

extension CoroutineHandle {
    /// Access the thread pointer (internal use only)
    internal var threadPointer: OpaquePointer {
        return thread
    }
}
