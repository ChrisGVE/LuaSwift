//
//  LuaDebug.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaDebug.swift
//
//  Context: Public debug-hook API types for LuaSwift (#20). These types
//  form the vocabulary for the event/command exchange between the Lua VM
//  thread and a MoonSwift DebugSession (or other host-side debugger):
//
//  - LuaDebugEvent:    events fired by the hook (line/call/return).
//  - LuaDebugCommand:  commands the handler returns to direct stepping.
//  - LuaDebugInspector: validity-token-guarded snapshot surface (valid
//    only for the duration of the handler callback).
//  - LuaInspectedValue: self-contained eager snapshot of a Lua value,
//    depth-capped at 64 levels with raw-pointer cycle detection.
//  - LuaRefKind:        kind tag for reference-typed Lua values.
//  - LuaDebugHandler:   typealias for the handler closure stored by the
//    engine (setDebugHandler) and invoked synchronously on the VM thread.
//
//  ## Inspector lifetime contract
//
//  The handler receives a `LuaDebugInspector` whose `isValid` flag is
//  `true` for the duration of the call. Once the handler returns,
//  LuaSwift calls `invalidate()` (internal) and every subsequent method
//  invocation on the inspector hits a `precondition(isValid)` trap.
//  Using the inspector outside the callback is a programming error and
//  traps deterministically — there is no silent stack corruption.
//
//  ## LuaInspectedValue snapshot contract
//
//  Reference-typed Lua values (function/table/userdata/thread) are
//  returned as `LuaInspectedValue.reference`, never as a re-invokable
//  `LuaValue.luaFunction` (which would carry a registry index that could
//  be re-injected into another lua_State). The snapshot is taken eagerly
//  at pause time using raw `lua_next` (no `__index`/`__pairs`) up to a
//  depth cap of 64 with raw-pointer cycle detection; a repeated table
//  pointer yields `.reference(kind: .table, preview: "<cycle>",
//  children: nil)`. Scalars (nil/bool/int/number/string) map to
//  `.scalar(LuaValue)` and are trivially copyable. The snapshot is
//  self-contained and valid after the callback ends — it owns all child
//  values and has no dependency on the live Lua state.
//

import Foundation

// MARK: - LuaDebugEvent

/// An event fired by the debug hook to the registered handler.
///
/// Events are dispatched synchronously on the VM thread. The handler must
/// return a ``LuaDebugCommand`` before the VM continues execution.
///
/// ## Version differences
///
/// Tail calls are handled transparently by LuaSwift's native stepping logic:
/// - Lua 5.1 emits `LUA_HOOKTAILRET` (a return-shaped event) for tail calls.
/// - Lua 5.2+ emit `LUA_HOOKTAILCALL` (a call-shaped event) with no
///   matching return.
///
/// Both are normalised to ``call(_:)`` by the compositor hook, carrying the
/// callee's ``LuaStackFrame`` — NOT to ``ret``. The stepping logic uses live
/// ``lua_getstack`` depth measurement rather than CALL/RET event counting,
/// so ``stepOver`` and ``stepOut`` produce the correct pause points on every
/// Lua version regardless of the tail-call event shape.
public enum LuaDebugEvent: Sendable {
    /// The VM is about to execute the given source line number.
    case line(Int)
    /// The VM has just entered a function. The associated ``LuaStackFrame``
    /// is the innermost (level-0) frame at the moment of entry.
    case call(LuaStackFrame)
    /// The VM is about to return from a function.
    case ret
}

// MARK: - LuaDebugCommand

/// A command returned by the debug handler to control VM execution.
///
/// The command is processed synchronously before the VM resumes. Stepping
/// commands are implemented natively by LuaSwift using a ``StepState``
/// comparison against the current call-stack depth; the host does not need
/// to maintain any depth counter.
///
/// ## Tail-call correctness
///
/// `stepOut` and `stepOver` use strict `<` / `<=` depth comparisons against
/// the stack depth at the point where the command was issued. When a tail call
/// collapses a frame, the depth drops by more than one; the strict comparisons
/// handle this correctly — the VM pauses in the tail call's caller rather than
/// overshooting to the grandparent frame.
///
/// ## Stop terminal state
///
/// `.stop` reuses the F1 cancellation unwind path: the compositor hook sets
/// `abortReason = 1` (cancelled) and raises `lua_error` with the cancelled
/// sentinel. A `runDebug` run aborted by `.stop` surfaces as
/// `LuaError.cancelled`. MoonSwift's `DebugSession` distinguishes a debugger
/// stop from a user-initiated cancel by knowing it issued the `.stop` command
/// to `runDebug` — no separate error case is needed.
public enum LuaDebugCommand: Sendable {
    /// Resume normal execution. Step state is cleared; the handler is not
    /// called again until the next breakpoint or step pause.
    case continueRun
    /// Step over: pause at the next source line at the same or shallower call
    /// depth (i.e. does not enter function calls made from the current line).
    case stepOver
    /// Step into: pause at the very next source line, regardless of depth.
    case stepInto
    /// Step out: pause at the next source line in the caller of the current
    /// function (strictly shallower call depth). Handles tail calls correctly.
    case stepOut
    /// Stop execution immediately via the cancellation unwind. The in-flight
    /// `runDebug` call throws `LuaError.cancelled`.
    case stop
}

// MARK: - LuaRefKind

/// The kind of a reference-typed Lua value as exposed by ``LuaInspectedValue``.
public enum LuaRefKind: Sendable {
    /// A Lua function (Lua closure or C function).
    case function
    /// A Lua table.
    case table
    /// A Lua full or light userdata.
    case userdata
    /// A Lua thread (coroutine).
    case thread
}

// MARK: - LuaInspectedValue

/// A self-contained, eagerly-snapshotted, non-callable representation of a
/// Lua value, returned by the ``LuaDebugInspector`` methods at pause time.
///
/// ## Scalar vs. reference
///
/// Scalars (nil, boolean, integer, number, string) are returned as
/// `.scalar(LuaValue)` — trivially copyable, safe across thread boundaries.
///
/// Reference types (function, table, userdata, thread) are returned as
/// `.reference(kind:preview:children:)`:
/// - `kind` identifies the Lua type.
/// - `preview` is a metamethod-free string description (e.g. `"table: 0x1234"`
///   or `"function: 0x5678"`).
/// - `children` contains the eagerly-snapshotted key–value pairs for **tables**
///   (up to ``maxInspectionDepth`` levels deep, raw `lua_next` only — no
///   `__pairs` or `__index`) as a typed `[Child]` array. For functions, userdata,
///   and threads `children` is always `nil`. For a table that was already visited
///   in the current snapshot walk (cycle), `children` is `nil` and `isCycle` is
///   `true`. For a table at the depth cap, `children` is `nil` and
///   `isDepthLimited` is `true`.
///
/// ## Depth cap
///
/// Table children are materialised up to 64 levels of nesting
/// (`LuaInspectedValue.maxInspectionDepth`). Tables at that depth are returned
/// as `.reference(kind:.table, preview:"<depth limit>", children: nil)`.
/// Test with ``isDepthLimited`` rather than matching the preview string.
///
/// ## Re-injection prohibition
///
/// `LuaInspectedValue` intentionally does NOT wrap `LuaValue.luaFunction` —
/// a `.luaFunction(Int32)` carries a raw Lua registry index that could be
/// re-injected into any `lua_State`, creating a dangling reference. Snapshots
/// never hold live registry handles; they are safe to store and render after
/// the debug callback ends.
public indirect enum LuaInspectedValue: Sendable, Equatable {
    /// A scalar Lua value: nil, boolean, integer, number, or string.
    case scalar(LuaValue)
    /// A reference-typed Lua value with a metamethod-free preview string.
    /// `children` is non-nil only for table values and only up to the depth cap.
    /// Use ``isCycle`` / ``isDepthLimited`` to test the marker states without
    /// string-matching the `preview` field.
    case reference(
        kind: LuaRefKind,
        preview: String,
        children: [Child]?
    )
}

extension LuaInspectedValue {
    // MARK: - Child

    /// A typed key–value pair in a table snapshot.
    ///
    /// Using a named struct instead of an anonymous tuple allows
    /// `[Child]` to synthesise `Equatable` and `Sendable` conformances
    /// without custom implementations, and enables `LuaInspectedValue`
    /// itself to be `Equatable`.
    public struct Child: Sendable, Equatable {
        /// The key as a `String` (numeric keys are rendered with `String(format:)`).
        public let key: String
        /// The snapshotted value for this key.
        public let value: LuaInspectedValue
        /// Memberwise initialiser (public so test code can construct expected values).
        public init(key: String, value: LuaInspectedValue) {
            self.key = key
            self.value = value
        }
    }

    // MARK: - Depth

    /// Maximum table nesting depth for eager snapshotting.
    /// Matches MoonSwift's alias-bomb budget.
    public static let maxInspectionDepth: Int = 64

    // MARK: - Typed cycle / depth-limit markers

    /// `true` when this value is a `.reference` placeholder inserted because
    /// the table was already seen in the current DFS path (cycle detection).
    /// Prefer this over matching the `preview` string directly.
    public var isCycle: Bool {
        if case .reference(_, let preview, nil) = self { return preview == "<cycle>" }
        return false
    }

    /// `true` when this value is a `.reference` placeholder inserted because
    /// the recursion reached ``maxInspectionDepth`` before fully materialising
    /// the table's children. Prefer this over matching the `preview` string.
    public var isDepthLimited: Bool {
        if case .reference(_, let preview, nil) = self { return preview == "<depth limit>" }
        return false
    }
}

// MARK: - LuaDebugInspector

/// Read-only inspection surface provided to the debug handler while the VM
/// is paused at a debug event.
///
/// The inspector is valid **only** for the duration of the handler callback.
/// LuaSwift flips ``isValid`` to `false` immediately after the handler
/// returns. Every method `precondition(isValid)` — using the inspector
/// after the callback has returned traps deterministically (never silently).
///
/// ## Inspector scope
///
/// The inspector is the ONLY sanctioned interaction with engine state while
/// the VM is paused. Calling any other `LuaEngine` method while the callback
/// is executing will throw ``LuaError/enginePaused`` because `isPaused` is
/// set and guards every state-touching public method.
///
/// ## Values as snapshots
///
/// Locals, upvalues, and globals are returned as ``LuaInspectedValue`` —
/// eagerly-snapshotted, depth-capped, cycle-detected, and non-re-injectable.
/// The returned values are valid after the callback ends and may be retained
/// for rendering purposes.
public protocol LuaDebugInspector: AnyObject {
    /// Whether the inspector is currently valid.
    ///
    /// `true` during the handler callback; `false` once the callback returns.
    /// Methods `precondition(isValid)` — use after callback returns traps.
    var isValid: Bool { get }

    /// The current call stack, innermost frame first (level 0).
    ///
    /// Uses the same ``walkLuaStack`` implementation as the structured-error
    /// traceback builder (F3 / #19). Sourced from ``LuaStackFrame`` values
    /// populated via `lua_getstack` / `lua_getinfo("Sln")`.
    var callStack: [LuaStackFrame] { get }

    /// Local variables at the given stack frame level.
    ///
    /// - Parameter frameLevel: 0 = innermost frame. Values out of range
    ///   return an empty array.
    /// - Returns: Name–value pairs for all locals visible at that frame.
    func locals(frameLevel: Int) -> [(name: String, value: LuaInspectedValue)]

    /// Upvalues of the function at the given stack frame level.
    ///
    /// - Parameter frameLevel: 0 = innermost frame. Values out of range
    ///   return an empty array.
    /// - Returns: Name–value pairs for all upvalues of the closure at that frame.
    func upvalues(frameLevel: Int) -> [(name: String, value: LuaInspectedValue)]

    /// All globals in the engine's registry globals table, using the same raw
    /// enumeration as ``LuaEngine/globalNames(includingStandardLibrary:)``.
    ///
    /// - Returns: Name–value pairs for every string key in the globals table.
    func globals() -> [(name: String, value: LuaInspectedValue)]
}

// MARK: - LuaDebugHandler

/// The signature of the handler closure stored by ``LuaEngine/setDebugHandler(_:)``.
///
/// The handler is called synchronously on the VM thread at each debug event.
/// The `inspector` parameter is valid only for the duration of the call; using
/// it after the closure returns traps via `precondition`.
///
/// The handler **must not** call back into `LuaEngine` methods that touch the
/// Lua state (`run`, `evaluate`, `callLuaFunction`, etc.) — the VM is
/// non-re-entrant while executing, and those methods will throw
/// ``LuaError/enginePaused``. Only the `inspector` is safe to use.
public typealias LuaDebugHandler = (
    _ event: LuaDebugEvent,
    _ inspector: LuaDebugInspector
) -> LuaDebugCommand
