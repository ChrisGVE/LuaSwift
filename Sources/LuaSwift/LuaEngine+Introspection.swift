//
//  LuaEngine+Introspection.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Introspection.swift
//
//  Context: Read-only engine introspection API (F4 / #21). Exposes the
//  engine's registered value servers, registered Swift callbacks, installed
//  modules, and raw global variables for inspection by tooling such as
//  MoonSwift's Mock Environment navigator.
//
//  ## Safety contract
//
//  All methods in this file access the Lua VM directly and are only safe to
//  call **between runs** — when no run is executing or paused. Calling them
//  while a run is in progress is C-level undefined behaviour: `lua_next`
//  against an actively-executing `lua_State` is not re-entrant. The engine's
//  `NSRecursiveLock` would permit a same-thread call, but that is not
//  sufficient — only the absence of an active run is. Document the invariant
//  at every call site.
//
//  ## Raw access guarantee
//
//  Every path that touches the Lua stack uses ONLY raw C API calls:
//  - `lua_next` instead of `pairs()` — never fires `__pairs`
//  - `lua_rawget` instead of `lua_getglobal`/`lua_gettable` — never fires
//    `__index`
//  - The recursive table materialiser (`rawValueFromStack`) applies this
//    rule at every nesting level, so even tables nested inside returned
//    values never trigger metamethods.
//
//  ## Globals-table identity
//
//  Methods enumerate the engine's registry globals table directly:
//  - Lua 5.2+: `lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS)`
//  - Lua 5.1:  `lua_pushvalue(L, LUA_GLOBALSINDEX)`
//
//  This is distinct from the `_ENV` upvalue — a chunk that rebinds `_ENV`
//  does NOT affect what `globalNames` enumerates.
//
//  ## Value re-injection prohibition
//
//  Any `LuaValue` returned by `globalValue(_:)` that wraps a Lua reference
//  (`.luaFunction`) is bound to THIS engine via the Lua registry. It MUST NOT
//  be re-injected into a different engine (in particular a sandboxed child
//  engine). Doing so would expose the parent engine's closures inside the
//  sandbox, violating the isolation contract.
//

import Foundation
import CLua

// MARK: - Internal Raw Helpers

/// Push the engine's registry globals table onto the stack.
///
/// Uses `LUA_RIDX_GLOBALS` on Lua 5.2+ and `LUA_GLOBALSINDEX` on 5.1 so
/// we always enumerate the canonical globals table regardless of whether a
/// chunk has rebound `_ENV`.
///
/// - Parameter L: A valid Lua state.
@inline(__always)
private func pushGlobalsTable(_ L: OpaquePointer) {
    #if LUA_VERSION_51
    lua_pushvalue(L, LUA_GLOBALSINDEX)
    #else
    _ = lua_rawgeti(L, LUA_REGISTRYINDEX, lua_Integer(LUA_RIDX_GLOBALS))
    #endif
}

/// Walk the globals table and collect every string key, using only raw
/// `lua_next` — never `__pairs`.
///
/// Caller must ensure no run is active. The globals table is popped before
/// return; the stack is balanced on entry and exit.
///
/// - Parameter L: A valid Lua state.
/// - Returns: Set of all string keys present in the globals table.
internal func rawGlobalKeySet(on L: OpaquePointer) -> Set<String> {
    var result: Set<String> = []
    pushGlobalsTable(L)                  // [globals]
    lua_pushnil(L)                       // [globals, nil]  — first key
    while lua_next(L, -2) != 0 {
        // stack: [globals, key, value]
        if lua_type(L, -2) == LUA_TSTRING,
           let key = lua_getstring(L, -2)
        {
            result.insert(key)
        }
        lua_pop(L, 1)                    // pop value, keep key for next iteration
    }
    lua_pop(L, 1)                        // pop globals table
    return result
}

/// Convert the Lua value at `index` to a `LuaValue` using ONLY raw C API
/// calls at every depth.
///
/// Unlike `valueFromStack`, this function NEVER fires metamethods:
/// - Table iteration uses `lua_next` (raw), not `pairs` — `__pairs` is not invoked.
/// - Nested table access uses `lua_next` recursively — `__index` is never
///   triggered at any depth.
/// - Functions: when `pinFunctions` is `true` (default, call path), a
///   registry reference is created via `luaL_ref` so the function survives
///   as a re-invokable `.luaFunction(ref)`. When `false` (introspection path),
///   functions are returned as `.nil` — no registry pin is created and no
///   release is required. See `pinFunctions:` below.
///
/// The returned `.luaFunction` values (when `pinFunctions: true`) are bound
/// to the engine that owns `L`; see the module-level re-injection prohibition.
///
/// - Parameters:
///   - L: A valid Lua state. Must have no active run.
///   - index: Stack index of the value to materialise (positive or negative).
///   - pinFunctions: When `false`, Lua functions are returned as `.nil` without
///     creating a `luaL_ref`. Use this for read-only introspection paths where
///     the caller never calls or releases the function reference — avoids
///     an unbounded Lua registry leak when called repeatedly (e.g. after every
///     run). Defaults to `true` to preserve the existing behaviour for all
///     non-introspection call sites.
/// - Returns: The materialised `LuaValue`.
internal func rawValueFromStack(
    _ L: OpaquePointer,
    at index: Int32,
    pinFunctions: Bool = true
) -> LuaValue {
    let type = lua_type(L, index)

    switch type {
    case LUA_TNIL:
        return .nil

    case LUA_TBOOLEAN:
        return .bool(lua_toboolean(L, index) != 0)

    case LUA_TNUMBER:
        return .number(lua_tonumber(L, index))

    case LUA_TSTRING:
        guard let str = lua_getstring(L, index) else { return .nil }
        return .string(str)

    case LUA_TTABLE:
        return rawTableFromStack(L, at: index, pinFunctions: pinFunctions)

    case LUA_TFUNCTION:
        if pinFunctions {
            // Store a reference in the Lua registry so the GC cannot collect
            // the function while Swift holds the LuaValue. The ref is an
            // opaque handle; the caller must not re-inject it into a different
            // engine, and must call releaseLuaFunction(ref:) when done.
            lua_pushvalue(L, index)
            let ref = luaL_ref(L, LUA_REGISTRYINDEX)
            return .luaFunction(ref)
        } else {
            // Read-only introspection path: do not pin the function. Returning
            // .nil signals "present but not representable inertly" and prevents
            // an unbounded registry leak when globalValue is called repeatedly.
            // LuaValue has no dedicated "function placeholder" case; nil is the
            // documented limitation for introspection of function-typed globals.
            return .nil
        }

    default:
        return .nil
    }
}

/// Materialise a Lua table at stack `index` into a `LuaValue` using only
/// raw `lua_next` — `__pairs`, `__index`, and `__len` are never invoked.
///
/// Nested tables are materialised recursively through `rawValueFromStack`,
/// which applies the same raw guarantee at every depth. This satisfies
/// PRD §F4 acceptance criterion: "a **nested** table with a side-effecting
/// `__pairs` is enumerated WITHOUT invoking the metamethod."
private func rawTableFromStack(
    _ L: OpaquePointer,
    at index: Int32,
    pinFunctions: Bool = true
) -> LuaValue {
    // Normalise to an absolute index so it remains valid while we push/pop.
    let absIndex = index < 0 ? lua_gettop(L) + index + 1 : index

    var dict: [String: LuaValue] = [:]
    var intKeyedValues: [Int: LuaValue] = [:]
    var hasStringKeys = false

    lua_pushnil(L)                       // first key
    while lua_next(L, absIndex) != 0 {
        // stack: …, key@-2, value@-1
        let keyType = lua_type(L, -2)
        // Materialise the value via raw recursion before popping it.
        let value = rawValueFromStack(L, at: -1, pinFunctions: pinFunctions)

        if keyType == LUA_TNUMBER {
            let keyNum = Int(lua_tonumber(L, -2))
            intKeyedValues[keyNum] = value
        } else if keyType == LUA_TSTRING {
            hasStringKeys = true
            if let key = lua_getstring(L, -2) {
                dict[key] = value
            }
        }
        // Pop the value; keep the key for the next lua_next call.
        lua_pop(L, 1)
    }

    // Honour the existing LuaValue convention: contiguous integer sequences
    // from 1 become `.array`; mixed / string-keyed tables become `.table`.
    if !hasStringKeys, let arr = convertToArrayIfContiguous(intKeyedValues) {
        return .array(arr)
    }

    if !intKeyedValues.isEmpty || !dict.isEmpty {
        for (key, val) in intKeyedValues {
            dict[String(key)] = val
        }
        return .table(dict)
    }

    return .table([:])
}

// MARK: - Public Introspection API

extension LuaEngine {

    // MARK: Registry introspection

    /// Names of value servers registered via ``register(server:)``.
    ///
    /// Reads the engine's ``servers`` dictionary under the engine lock. The
    /// returned array is a snapshot; it does not update as new servers are
    /// registered.
    ///
    /// **Thread safety:** safe to call from any thread between runs. Acquires
    /// the engine lock before reading.
    ///
    /// **Between-runs only:** calling this while a run is executing on another
    /// thread produces a consistent snapshot of the Swift registry but does
    /// not inspect the Lua VM state.
    public var registeredValueServerNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(servers.keys)
    }

    /// Names of Swift callbacks registered via ``registerFunction(name:callback:)``.
    ///
    /// Reads the engine's ``callbacks`` dictionary under the engine lock. The
    /// returned array is a snapshot; it does not update as new callbacks are
    /// registered.
    ///
    /// **Thread safety:** safe to call from any thread between runs.
    ///
    /// **Between-runs only:** as for ``registeredValueServerNames``.
    public var registeredFunctionNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(callbacks.keys)
    }

    /// Names of modules successfully installed via ``ModuleRegistry/install(in:)``.
    ///
    /// Populated by ``ModuleRegistry/install(in:)`` on each successful module
    /// install. Modules installed directly via their own `install(in:)` outside
    /// the registry are NOT automatically recorded here; callers may call
    /// ``recordInstalledModule(_:)`` to record them explicitly.
    ///
    /// **Thread safety:** safe to call from any thread between runs.
    public var installedModuleNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(installedModules)
    }

    /// Record a module as installed (for modules installed outside the registry).
    ///
    /// ``ModuleRegistry/install(in:)`` calls this automatically. Call it
    /// explicitly only when installing a module directly via its own
    /// `install(in:)` entry point and wanting it reflected by
    /// ``installedModuleNames``.
    ///
    /// - Parameter name: The ``LuaSwiftModule/moduleName`` of the installed module.
    public func recordInstalledModule(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        installedModules.insert(name)
    }

    // MARK: Globals introspection

    /// String keys present in the engine's globals table.
    ///
    /// Enumerates the registry globals table (`LUA_RIDX_GLOBALS` on 5.2+,
    /// `LUA_GLOBALSINDEX` on 5.1) using a raw `lua_next` loop — `__pairs` is
    /// never invoked. A chunk that rebinds `_ENV` does NOT affect what this
    /// method enumerates; it always reads the engine's own registry globals
    /// table.
    ///
    /// - Parameter includingStandardLibrary: When `false`, returns only keys
    ///   that were absent from the globals table at the end of engine
    ///   initialisation (i.e. user-defined globals set by executed code).
    ///   When `true`, returns all current global keys, including those that
    ///   were present at init time (standard library, installed modules, etc.).
    ///   The baseline snapshot is taken once at the end of ``init(configuration:)``
    ///   and never changes, so the filter is deterministic.
    ///
    /// **Between-runs only.** This method accesses the Lua VM with raw C calls
    /// and is only safe when no run is executing or paused. A raw `lua_next`
    /// against an actively-executing `lua_State` is C-level undefined
    /// behaviour even though the `NSRecursiveLock` would permit a same-thread
    /// call.
    ///
    /// **Thread safety:** acquires the engine lock before touching the Lua
    /// state. Callers must ensure no run is active (see above).
    public func globalNames(includingStandardLibrary: Bool = true) -> [String] {
        // Fast-fail when the VM is paused (mid-run, lock held by the VM thread).
        // Returning an empty array is the documented paused behavior for this
        // non-throwing method: callers should test isPaused / catch enginePaused
        // on throwing siblings before calling introspection APIs during a debug
        // session. The guard fires BEFORE lock.lock() so same-thread re-entry
        // from inside a debug handler (lock already held) also short-circuits
        // cleanly without accessing the live Lua state.
        guard !isPaused.load(ordering: .acquiring) else { return [] }
        lock.lock()
        defer { lock.unlock() }
        guard let L = L else { return [] }

        let allKeys = rawGlobalKeySet(on: L)
        if includingStandardLibrary {
            return Array(allKeys)
        } else {
            return Array(allKeys.subtracting(baselineGlobalNames))
        }
    }

    /// The value of a global variable, accessed with raw C API only.
    ///
    /// Uses `lua_rawget` (not `lua_getglobal` / `lua_gettable`) so `__index`
    /// on the globals table metatable is never triggered. Returns `nil` when
    /// the global is absent or its value is Lua `nil`.
    ///
    /// **Function globals:** Lua globals whose type is `function` are returned
    /// as `nil` rather than as `.luaFunction`. Creating a `luaL_ref` for each
    /// function global would grow the Lua registry without bound when
    /// `globalValue` is called repeatedly (e.g. after every run by MoonSwift),
    /// because there is no release path at the call site. The nil return
    /// signals "present but not representable inertly" — the caller can use
    /// ``globalNames(includingStandardLibrary:)`` to confirm the key exists and
    /// inspect its type, but cannot call it via this API (intentional: the
    /// re-injection prohibition applies).
    ///
    /// **Between-runs only.** See ``globalNames(includingStandardLibrary:)``
    /// for the full safety rationale.
    ///
    /// **Thread safety:** acquires the engine lock before touching the Lua
    /// state.
    ///
    /// - Parameter name: The global variable name to look up.
    /// - Returns: The typed `LuaValue`, or `nil` if the variable is absent or `nil`.
    public func globalValue(_ name: String) -> LuaValue? {
        // Fast-fail when paused — same rationale as globalNames above.
        // Returns nil (absent/paused are semantically equivalent for callers).
        guard !isPaused.load(ordering: .acquiring) else { return nil }
        lock.lock()
        defer { lock.unlock() }
        guard let L = L else { return nil }

        pushGlobalsTable(L)              // [globals]
        lua_pushstring_binary(L, name)   // [globals, name]
        lua_rawget(L, -2)                // [globals, value]  — raw: no __index

        // pinFunctions: false — do not create a luaL_ref for function globals.
        // globalValue is called after every run by MoonSwift; pinning functions
        // would grow the Lua registry without bound since there is no release
        // API at the call site. Function globals are returned as .nil.
        // See: LuaEngine+Introspection.swift rawValueFromStack pinFunctions: doc.
        let value = rawValueFromStack(L, at: -1, pinFunctions: false)
        lua_pop(L, 2)                    // pop value + globals table

        // Treat Lua nil as Swift nil — "absent" and "nil" are semantically
        // equivalent for a global lookup.
        if case .nil = value { return nil }
        return value
    }
}
