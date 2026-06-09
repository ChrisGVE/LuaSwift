//
//  LuaEngine+DebugInspector.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+DebugInspector.swift
//
//  Context: Debug-inspector implementation for the debug-hook system
//  (#20 / F5). Contains DebugInspectorImpl (the concrete LuaDebugInspector)
//  and inspectedValueFromStack (the recursive LuaInspectedValue materialiser).
//  Extracted from LuaEngine+Debug.swift so each file has a single concern.
//
//  ## Inspector validity token
//
//  DebugInspectorImpl.isValid is true during the handler call; invalidate()
//  flips it false after the handler returns. Every public method guards on
//  isValid and returns a safe neutral value ([] / empty callStack) when
//  false. This safe-fallback approach is preserved under -Ounchecked
//  (preconditions are elided there). Storing and using the inspector after
//  the callback ends is a programming error; isValid is the signal.
//
//  ## Snapshot semantics
//
//  - Scalars (nil/bool/number/string) → .scalar(LuaValue).
//  - Tables → .reference(kind:.table, preview:, children:) with raw
//    lua_next recursion up to maxInspectionDepth (64) levels.
//    A table seen more than once via raw lua_topointer yields
//    .reference(kind:.table, preview:"<cycle>", children: nil).
//  - Functions/userdata/threads → .reference(kind:, preview:, children: nil).
//
//  Neighbors:
//    LuaEngine+Debug.swift          — public API; runDebug arms the hook
//    LuaEngine+DebugStepping.swift  — dispatchDebugEvent creates the inspector
//    LuaEngine+Introspection.swift  — pushGlobalsTable (shared internal helper)
//

import Foundation
import CLua

// MARK: - Debug Inspector Implementation
// The globals-table push helper (`pushGlobalsTable`) lives in
// LuaEngine+Introspection.swift and is shared `internal`; this file uses it
// directly instead of mirroring it.

/// Concrete implementation of ``LuaDebugInspector``.
///
/// Created inside `dispatchDebugEvent`, valid only while the handler callback
/// executes. After ``invalidate()`` every method short-circuits via
/// `guard valid else { return [] }` and returns a neutral empty result rather
/// than reading a dangling `lua_State` — a guard, not a `precondition`, so the
/// safety holds even under `-Ounchecked` (which elides preconditions). The
/// ``isValid`` flag remains the authoritative use-after-invalidation signal.
///
/// Snapshots are taken lazily per-call but always from inside the valid
/// callback window — the `lua_State` is parked (not executing instructions)
/// and the stack layout is stable for the duration.
internal final class DebugInspectorImpl: LuaDebugInspector {
    private let L: OpaquePointer
    private var valid: Bool = true

    /// Per-snapshot walk state (cycle-detection set + stable opaque-id table for
    /// reference previews). Held as an instance field — rather than a per-call
    /// local — only to reuse allocated capacity across the potentially large
    /// `globals()` walk. It MUST be reset to a fresh ``InspectionContext`` at the
    /// end of every public method so a pointer or id assigned by one call is not
    /// carried into the next. The early-return guards in each method
    /// (`guard valid`, `guard lua_getstack`) all fire BEFORE any insertion, so
    /// those paths leave it already empty — the reset only matters on the
    /// full-walk path.
    private var inspectionContext = InspectionContext()

    internal init(L: OpaquePointer) {
        self.L = L
    }

    internal func invalidate() {
        valid = false
    }

    // MARK: LuaDebugInspector

    public var isValid: Bool { valid }

    public var callStack: [LuaStackFrame] {
        // Return an empty stack rather than precondition-trapping so the safe
        // fallback survives -Ounchecked (which elides preconditions). A stored
        // inspector used after the callback returns will return neutral values
        // instead of silently reading a dangling lua_State pointer. isValid is
        // still the authoritative signal; callers are expected to check it.
        guard valid else { return [] }
        return walkLuaStack(L, startLevel: 0)
    }

    public func locals(frameLevel: Int) -> [(name: String, value: LuaInspectedValue)] {
        guard valid else { return [] }
        var result: [(name: String, value: LuaInspectedValue)] = []
        var ar = lua_Debug()
        guard lua_getstack(L, Int32(frameLevel), &ar) != 0 else { return result }

        var idx: Int32 = 1
        while true {
            guard let rawName = lua_getlocal(L, &ar, idx) else { break }
            let name = String(cString: rawName)
            // Skip internal Lua temporaries (names starting with '(')
            if !name.hasPrefix("(") {
                let value = inspectedValueFromStack(L, at: -1, context: &inspectionContext)
                result.append((name: name, value: value))
            }
            lua_pop(L, 1)
            idx += 1
        }
        inspectionContext = InspectionContext()
        return result
    }

    public func upvalues(frameLevel: Int) -> [(name: String, value: LuaInspectedValue)] {
        guard valid else { return [] }
        var result: [(name: String, value: LuaInspectedValue)] = []

        // Get the function at frameLevel via lua_getinfo("f").
        var ar = lua_Debug()
        guard lua_getstack(L, Int32(frameLevel), &ar) != 0 else { return result }
        guard lua_getinfo(L, "f", &ar) != 0 else { return result }
        // lua_getinfo("f") pushes the function at top; stack: [..., fn]
        let funcIdx = lua_gettop(L)

        var idx: Int32 = 1
        while true {
            guard let rawName = lua_getupvalue(L, funcIdx, idx) else { break }
            let name = String(cString: rawName)
            let value = inspectedValueFromStack(L, at: -1, context: &inspectionContext)
            result.append((name: name, value: value))
            lua_pop(L, 1)
            idx += 1
        }
        lua_pop(L, 1)  // pop the function itself
        inspectionContext = InspectionContext()
        return result
    }

    public func globals() -> [(name: String, value: LuaInspectedValue)] {
        guard valid else { return [] }
        var result: [(name: String, value: LuaInspectedValue)] = []

        pushGlobalsTable(L)
        let globalsIdx = lua_gettop(L)

        var truncated = false
        lua_pushnil(L)
        while lua_next(L, globalsIdx) != 0 {
            // stack: [globals, key, value]
            // Same opt-in breadth bound as materialiseTable: a hostile script
            // can make `_G` itself enormous (SEC-201). Unbounded by default.
            if let cap = LuaInspectedValue.maxInspectionBreadth, result.count >= cap {
                lua_pop(L, 2)  // pop value AND key to abandon the traversal early
                truncated = true
                break
            }
            if lua_type(L, -2) == LUA_TSTRING,
               let key = lua_getstring(L, -2) {
                let value = inspectedValueFromStack(L, at: -1, context: &inspectionContext)
                result.append((name: key, value: value))
            }
            lua_pop(L, 1)  // pop value, keep key
        }
        lua_pop(L, 1)  // pop globals table
        inspectionContext = InspectionContext()
        if truncated {
            let sentinel = breadthLimitSentinelChild()
            result.append((name: sentinel.key, value: sentinel.value))
        }
        return result
    }
}

// MARK: - LuaInspectedValue Materialiser

/// Mutable state threaded through one inspection snapshot walk.
///
/// Carries two concerns that must both be per-snapshot:
///  - `visited`: raw GC-object pointers already on the current DFS path, for
///    cycle detection (a pointer is stable and unique within the state).
///  - opaque-id assignment: each distinct reference object gets a small stable
///    integer, used to build previews like `"table #3"` instead of embedding
///    the raw heap address. This keeps the inspector from leaking Lua/host
///    heap pointers into preview strings that may be serialised off-device
///    (e.g. a remote-debug wire or an uploaded crash log) — an ASLR oracle
///    otherwise (SEC-202). Ids are scoped to one snapshot, so the same object
///    reads as the same `#n` within a single `locals()`/`globals()` call.
internal struct InspectionContext {
    var visited: Set<UnsafeRawPointer> = []
    private var ids: [UnsafeRawPointer: Int] = [:]
    private var nextId = 1

    /// Stable opaque id for `ptr` within this snapshot (assigned on first use).
    mutating func id(for ptr: UnsafeRawPointer) -> Int {
        if let existing = ids[ptr] { return existing }
        let assigned = nextId
        nextId += 1
        ids[ptr] = assigned
        return assigned
    }
}

/// Convert the Lua value at `index` to a ``LuaInspectedValue`` snapshot.
///
/// - Scalars (nil/bool/number/string) → `.scalar(LuaValue)`.
/// - Tables → `.reference(kind:.table, preview:, children:)` with raw
///   `lua_next` recursion up to ``LuaInspectedValue/maxInspectionDepth``
///   levels. A repeated raw pointer → `<cycle>` with `children: nil`.
/// - Functions/userdata/threads → `.reference(kind:, preview:, children: nil)`.
///
/// Uses `lua_topointer` for cycle detection — the pointer is stable for
/// the lifetime of the GC object and unique within the state. The pointer is
/// used only as a key (cycle set + opaque-id table); it never reaches a
/// preview string (see ``InspectionContext``, SEC-202).
///
/// - Parameters:
///   - L: The Lua state (must be mid-debug-pause; no instructions executing).
///   - index: Stack index of the value.
///   - context: In-out per-snapshot walk state (cycle set + opaque ids).
///   - depth: Current nesting depth (starts at 0 for the outermost call).
/// - Returns: The materialised ``LuaInspectedValue``.
///
/// internal: called by DebugInspectorImpl methods and recursively by itself
internal func inspectedValueFromStack(
    _ L: OpaquePointer,
    at index: Int32,
    context: inout InspectionContext,
    depth: Int = 0
) -> LuaInspectedValue {
    // Absolute index so it stays valid while we push/pop during table walk.
    let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index
    let type = lua_type(L, absIndex)

    switch type {
    case LUA_TNIL:    return .scalar(.nil)
    case LUA_TBOOLEAN: return .scalar(.bool(lua_toboolean(L, absIndex) != 0))
    case LUA_TNUMBER:  return .scalar(.number(lua_tonumber(L, absIndex)))
    case LUA_TSTRING:  return materialiseString(L, absIndex: absIndex)
    case LUA_TTABLE:
        return materialiseTable(L, absIndex: absIndex, context: &context, depth: depth)
    case LUA_TFUNCTION:
        return materialisePointerRef(L, absIndex: absIndex, kind: .function, label: "function", context: &context)
    case LUA_TUSERDATA, LUA_TLIGHTUSERDATA:
        return materialisePointerRef(L, absIndex: absIndex, kind: .userdata, label: "userdata", context: &context)
    case LUA_TTHREAD:
        return materialisePointerRef(L, absIndex: absIndex, kind: .thread, label: "thread", context: &context)
    default:           return .scalar(.nil)
    }
}

// MARK: - inspectedValueFromStack private helpers

private func materialiseString(_ L: OpaquePointer, absIndex: Int32) -> LuaInspectedValue {
    if let str = lua_getstring(L, absIndex) {
        return .scalar(.string(str))
    }
    return .scalar(.nil)
}

private func materialiseTable(
    _ L: OpaquePointer,
    absIndex: Int32,
    context: inout InspectionContext,
    depth: Int
) -> LuaInspectedValue {
    guard let ptr = lua_topointer(L, absIndex) else {
        return .reference(kind: .table, preview: "table #?", children: nil)
    }
    let rawPtr = UnsafeRawPointer(ptr)

    if context.visited.contains(rawPtr) {
        return .reference(kind: .table, preview: LuaInspectedValue.cycleMarker, children: nil)
    }
    if depth >= LuaInspectedValue.maxInspectionDepth {
        return .reference(kind: .table, preview: LuaInspectedValue.depthLimitMarker, children: nil)
    }

    // Opaque stable id, not the raw heap address (SEC-202).
    let preview = "table #\(context.id(for: rawPtr))"
    context.visited.insert(rawPtr)
    defer { context.visited.remove(rawPtr) }

    var (children, truncated) = collectTableChildren(L, absIndex: absIndex, context: &context, depth: depth)
    if truncated {
        children.append(breadthLimitSentinelChild())
    }
    return .reference(kind: .table, preview: preview, children: children)
}

/// Walk the table at `absIndex`, materialising each string/number-keyed entry
/// (recursing at `depth + 1`). Non-string/number keys are skipped. Stops early
/// once ``LuaInspectedValue/maxInspectionBreadth`` is reached, returning
/// `truncated: true` so the caller can append the breadth-limit sentinel; in the
/// default unbounded build the cap is `nil` and the loop never fires (SEC-201).
private func collectTableChildren(
    _ L: OpaquePointer,
    absIndex: Int32,
    context: inout InspectionContext,
    depth: Int
) -> (children: [LuaInspectedValue.Child], truncated: Bool) {
    var children: [LuaInspectedValue.Child] = []
    var truncated = false
    lua_pushnil(L)
    while lua_next(L, absIndex) != 0 {
        // stack: [absIndex=table, ..., key@-2, value@-1]
        if let cap = LuaInspectedValue.maxInspectionBreadth, children.count >= cap {
            lua_pop(L, 2)  // pop value AND key to abandon the traversal early
            truncated = true
            break
        }
        let keyType = lua_type(L, -2)
        if keyType == LUA_TSTRING, let k = lua_getstring(L, -2) {
            let val = inspectedValueFromStack(L, at: -1, context: &context, depth: depth + 1)
            children.append(LuaInspectedValue.Child(key: k, value: val))
        } else if keyType == LUA_TNUMBER {
            let k = "\(lua_tonumber(L, -2))"
            let val = inspectedValueFromStack(L, at: -1, context: &context, depth: depth + 1)
            children.append(LuaInspectedValue.Child(key: k, value: val))
        } else {
            // Skip non-string/number keys (uncommon, but safe to omit).
            lua_pop(L, 1)
            continue
        }
        lua_pop(L, 1)  // pop value, keep key
    }
    return (children, truncated)
}

/// Sentinel child appended in place of the entries dropped when a table
/// exceeds ``LuaInspectedValue/maxInspectionBreadth``. Detect it via
/// ``LuaInspectedValue/isBreadthLimited``.
private func breadthLimitSentinelChild() -> LuaInspectedValue.Child {
    LuaInspectedValue.Child(
        key: LuaInspectedValue.breadthLimitMarker,
        value: .reference(kind: .table, preview: LuaInspectedValue.breadthLimitMarker, children: nil)
    )
}

private func materialisePointerRef(
    _ L: OpaquePointer,
    absIndex: Int32,
    kind: LuaRefKind,
    label: String,
    context: inout InspectionContext
) -> LuaInspectedValue {
    // Opaque stable id, not the raw heap address (SEC-202): "function #4".
    guard let ptr = lua_topointer(L, absIndex) else {
        return .reference(kind: kind, preview: "\(label) #?", children: nil)
    }
    let id = context.id(for: UnsafeRawPointer(ptr))
    return .reference(kind: kind, preview: "\(label) #\(id)", children: nil)
}
