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
//  flips it false after the handler returns. Every public method calls
//  precondition(isValid) so use-after-callback traps deterministically at
//  the programming-error call site.
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
//    LuaEngine+Introspection.swift  — pushGlobalsTable (mirrored locally)
//

import Foundation
import CLua

// MARK: - Globals Table Push (local helper for inspector)

/// Push the engine's globals table onto the Lua stack.
/// Mirrors `pushGlobalsTable` in LuaEngine+Introspection.swift but is
/// file-private here to avoid a cross-file dependency on an internal helper.
@inline(__always)
private func pushGlobalsTableForDebug(_ L: OpaquePointer) {
    #if LUA_VERSION_51
    lua_pushvalue(L, LUA_GLOBALSINDEX)
    #else
    _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(LUA_RIDX_GLOBALS))
    #endif
}

// MARK: - Debug Inspector Implementation

/// Concrete implementation of ``LuaDebugInspector``.
///
/// Created inside `dispatchDebugEvent`, valid only while the handler callback
/// executes. All methods `precondition(isValid)` so use-after-invalidation
/// traps at the call site rather than silently reading stale state.
///
/// Snapshots are taken lazily per-call but always from inside the valid
/// callback window — the `lua_State` is parked (not executing instructions)
/// and the stack layout is stable for the duration.
internal final class DebugInspectorImpl: LuaDebugInspector {
    private let L: OpaquePointer
    private var valid: Bool = true

    /// Set of raw table pointers already visited in the current snapshot walk
    /// (cycle detection). Reset after each public method call.
    private var visitedTables: Set<UnsafeRawPointer> = []

    internal init(L: OpaquePointer) {
        self.L = L
    }

    internal func invalidate() {
        valid = false
    }

    // MARK: LuaDebugInspector

    public var isValid: Bool { valid }

    public var callStack: [LuaStackFrame] {
        precondition(valid, "LuaDebugInspector used after callback returned")
        return walkLuaStack(L, startLevel: 0)
    }

    public func locals(frameLevel: Int) -> [(name: String, value: LuaInspectedValue)] {
        precondition(valid, "LuaDebugInspector used after callback returned")
        var result: [(name: String, value: LuaInspectedValue)] = []
        var ar = lua_Debug()
        guard lua_getstack(L, Int32(frameLevel), &ar) != 0 else { return result }

        var idx: Int32 = 1
        while true {
            guard let rawName = lua_getlocal(L, &ar, idx) else { break }
            let name = String(cString: rawName)
            // Skip internal Lua temporaries (names starting with '(')
            if !name.hasPrefix("(") {
                let value = inspectedValueFromStack(L, at: -1, visited: &visitedTables)
                result.append((name: name, value: value))
            }
            lua_pop(L, 1)
            idx += 1
        }
        visitedTables.removeAll()
        return result
    }

    public func upvalues(frameLevel: Int) -> [(name: String, value: LuaInspectedValue)] {
        precondition(valid, "LuaDebugInspector used after callback returned")
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
            let value = inspectedValueFromStack(L, at: -1, visited: &visitedTables)
            result.append((name: name, value: value))
            lua_pop(L, 1)
            idx += 1
        }
        lua_pop(L, 1)  // pop the function itself
        visitedTables.removeAll()
        return result
    }

    public func globals() -> [(name: String, value: LuaInspectedValue)] {
        precondition(valid, "LuaDebugInspector used after callback returned")
        var result: [(name: String, value: LuaInspectedValue)] = []

        pushGlobalsTableForDebug(L)
        let globalsIdx = lua_gettop(L)

        lua_pushnil(L)
        while lua_next(L, globalsIdx) != 0 {
            // stack: [globals, key, value]
            if lua_type(L, -2) == LUA_TSTRING,
               let key = lua_getstring(L, -2) {
                let value = inspectedValueFromStack(L, at: -1, visited: &visitedTables)
                result.append((name: key, value: value))
            }
            lua_pop(L, 1)  // pop value, keep key
        }
        lua_pop(L, 1)  // pop globals table
        visitedTables.removeAll()
        return result
    }
}

// MARK: - LuaInspectedValue Materialiser

/// Convert the Lua value at `index` to a ``LuaInspectedValue`` snapshot.
///
/// - Scalars (nil/bool/number/string) → `.scalar(LuaValue)`.
/// - Tables → `.reference(kind:.table, preview:, children:)` with raw
///   `lua_next` recursion up to ``LuaInspectedValue/maxInspectionDepth``
///   levels. A repeated raw pointer → `<cycle>` with `children: nil`.
/// - Functions/userdata/threads → `.reference(kind:, preview:, children: nil)`.
///
/// Uses `lua_topointer` for cycle detection — the pointer is stable for
/// the lifetime of the GC object and unique within the state.
///
/// - Parameters:
///   - L: The Lua state (must be mid-debug-pause; no instructions executing).
///   - index: Stack index of the value.
///   - visited: In-out set of already-visited table pointers (cycle detection).
///   - depth: Current nesting depth (starts at 0 for the outermost call).
/// - Returns: The materialised ``LuaInspectedValue``.
///
/// internal: called by DebugInspectorImpl methods and recursively by itself
internal func inspectedValueFromStack(
    _ L: OpaquePointer,
    at index: Int32,
    visited: inout Set<UnsafeRawPointer>,
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
    case LUA_TTABLE:   return materialiseTable(L, absIndex: absIndex, visited: &visited, depth: depth)
    case LUA_TFUNCTION:
        return materialisePointerRef(L, absIndex: absIndex, kind: .function, label: "function")
    case LUA_TUSERDATA, LUA_TLIGHTUSERDATA:
        return materialisePointerRef(L, absIndex: absIndex, kind: .userdata, label: "userdata")
    case LUA_TTHREAD:
        return materialisePointerRef(L, absIndex: absIndex, kind: .thread, label: "thread")
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
    visited: inout Set<UnsafeRawPointer>,
    depth: Int
) -> LuaInspectedValue {
    guard let ptr = lua_topointer(L, absIndex) else {
        return .reference(kind: .table, preview: "table: (unknown)", children: nil)
    }
    let rawPtr = UnsafeRawPointer(ptr)

    if visited.contains(rawPtr) {
        return .reference(kind: .table, preview: "<cycle>", children: nil)
    }
    if depth >= LuaInspectedValue.maxInspectionDepth {
        return .reference(kind: .table, preview: "<depth limit>", children: nil)
    }

    let preview = "table: \(String(format: "%p", UInt(bitPattern: rawPtr)))"
    visited.insert(rawPtr)
    defer { visited.remove(rawPtr) }

    var children: [(key: String, value: LuaInspectedValue)] = []
    lua_pushnil(L)
    while lua_next(L, absIndex) != 0 {
        // stack: [absIndex=table, ..., key@-2, value@-1]
        let keyType = lua_type(L, -2)
        if keyType == LUA_TSTRING, let k = lua_getstring(L, -2) {
            let val = inspectedValueFromStack(L, at: -1, visited: &visited, depth: depth + 1)
            children.append((key: k, value: val))
        } else if keyType == LUA_TNUMBER {
            let k = "\(lua_tonumber(L, -2))"
            let val = inspectedValueFromStack(L, at: -1, visited: &visited, depth: depth + 1)
            children.append((key: k, value: val))
        } else {
            // Skip non-string/number keys (uncommon, but safe to omit).
            lua_pop(L, 1)
            continue
        }
        lua_pop(L, 1)  // pop value, keep key
    }
    return .reference(kind: .table, preview: preview, children: children)
}

private func materialisePointerRef(
    _ L: OpaquePointer,
    absIndex: Int32,
    kind: LuaRefKind,
    label: String
) -> LuaInspectedValue {
    let ptr = lua_topointer(L, absIndex)
    let addrStr = ptr.map { String(format: "%p", UInt(bitPattern: UnsafeRawPointer($0))) } ?? "?"
    return .reference(kind: kind, preview: "\(label): \(addrStr)", children: nil)
}
