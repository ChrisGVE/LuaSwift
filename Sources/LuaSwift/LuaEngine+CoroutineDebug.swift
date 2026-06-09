//
//  LuaEngine+CoroutineDebug.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+CoroutineDebug.swift
//
//  Context: Closes the in-Lua coroutine debugging gap (#26). Lua hooks are
//  per-lua_State, and a coroutine created inside Lua via coroutine.create /
//  coroutine.wrap runs on a fresh thread that never receives the debug hook —
//  so its body was stepped over even during a runDebug session.
//
//  Lua coroutines run cooperatively on the *calling* OS thread, so the engine
//  is still recoverable through the currentEngine TLS slot and the existing
//  dispatchDebugEvent path works unchanged inside a coroutine body — the only
//  missing piece is the lua_sethook call on the new thread. While a debug
//  session is active, this file installs Lua-level overrides of
//  coroutine.create / coroutine.wrap that route each newly created thread
//  through armCoroutineHookCallback, which arms the full debug mask on it
//  before it first runs. The overrides are scoped to a single runDebug/resume
//  call (installed at entry, restored on exit), so non-debug runs see the
//  untouched standard library and pay zero overhead.
//
//  Neighbors:
//    LuaEngine+Debug.swift       — executeWithDebugHook installs/removes shims
//    LuaEngine+Coroutines.swift  — host-driven resume installs/removes shims
//    LuaEngine+CompositorHook.swift — the hook the shims arm on each thread
//

import Foundation
import CLua

// MARK: - Arm-Hook C Function

/// `lua_CFunction` that arms the debug hook on a coroutine passed as argument 1.
///
/// Installed under the hidden global `_luaswift_arm_coroutine_hook` by the
/// coroutine debug shims (see ``LuaEngine/installCoroutineDebugShims(on:)``) and
/// removed again as soon as the shim chunk has captured it. The overridden
/// `coroutine.create` / `coroutine.wrap` call it on every thread they create so
/// the per-`lua_State` debug hook is set before the coroutine first runs (#26).
///
/// The coroutine argument is returned unchanged so the Lua wrapper can write
/// `return _arm(_create(f))`; a non-thread argument simply passes through. When
/// no debug handler is installed the function is inert — but in practice it is
/// only ever reachable while a session is active, since the shims that call it
/// exist only for the duration of a debug run.
internal func armCoroutineHookCallback(_ L: OpaquePointer?) -> Int32 {
    guard let L = L else { return 0 }
    if let engine = LuaEngine.currentEngine,
       engine.debugHandler != nil,
       let coroutine = lua_tothread(L, 1) {
        engine.armDebugHook(on: coroutine)
    }
    // Leave only argument 1 (the coroutine) on the stack as the return value.
    lua_settop(L, 1)
    return 1
}

extension LuaEngine {

    // MARK: - Shim Source

    /// Lua source for the coroutine debug overrides.
    ///
    /// Captures the originals as upvalues so the overrides chain to them, routes
    /// each new thread through the arm-hook C function, and reimplements
    /// `coroutine.wrap` on top of the (already-armed) `create` + `resume` so the
    /// wrapped coroutine is stepped into as well. `table.pack`/`table.unpack`
    /// have version-portable fallbacks (`select`/global `unpack`) so the shim
    /// works identically across Lua 5.1–5.5. The wrapped resumer re-raises with
    /// `error(msg, 0)` to preserve the position-free propagation of the real
    /// `coroutine.wrap`.
    private static let coroutineDebugShimSource = """
        local _arm = _luaswift_arm_coroutine_hook
        local _create = coroutine.create
        local _resume = coroutine.resume
        local _pack = table.pack or function(...)
            local t = {...}
            t.n = select('#', ...)
            return t
        end
        local _unpack = table.unpack or unpack
        coroutine.create = function(f)
            return _arm(_create(f))
        end
        coroutine.wrap = function(f)
            local co = _arm(_create(f))
            return function(...)
                local r = _pack(_resume(co, ...))
                if not r[1] then error(r[2], 0) end
                return _unpack(r, 2, r.n)
            end
        end
        _luaswift_arm_coroutine_hook = nil
        """

    // MARK: - Install / Remove

    /// Install the in-Lua coroutine debug overrides on the given state.
    ///
    /// Saves the original `coroutine.create` / `coroutine.wrap` into the registry
    /// (so ``removeCoroutineDebugShims(on:)`` can restore them), then runs the
    /// shim chunk. Idempotent: a second call while shims are already installed is
    /// a no-op, so it can be invoked unconditionally at every debug entry point.
    ///
    /// internal: called from executeWithDebugHook and resume(_:with:).
    internal func installCoroutineDebugShims(on state: OpaquePointer) {
        guard coroutineShimSavedRefs == nil else { return }

        // Save the originals for restoration. luaL_ref pops the value it refs,
        // leaving the coroutine table balanced on the stack.
        lua_getglobal(state, "coroutine")
        guard lua_type(state, -1) == LUA_TTABLE else {
            lua_pop(state, 1)
            return
        }
        lua_getfield(state, -1, "create")
        let createRef = luaL_ref(state, LUA_REGISTRYINDEX)
        lua_getfield(state, -1, "wrap")
        let wrapRef = luaL_ref(state, LUA_REGISTRYINDEX)
        lua_pop(state, 1)  // pop the coroutine table

        // Expose the arm-hook C function to the shim, then run the overrides.
        lua_pushcfunction(state, armCoroutineHookCallback)
        lua_setglobal(state, "_luaswift_arm_coroutine_hook")

        // Run the trusted shim with the debug hook disabled. Otherwise the hook
        // fires on the shim's own lines and dispatches to the user handler — a
        // handler returning `.stop` would abort the install with the cancel
        // sentinel. The caller re-arms the hook after installing (runDebug), or
        // runs on a different state (resume), so clearing it here is safe.
        lua_sethook(state, nil, 0, 0)

        let loaded = loadSourceChunk(state, code: Self.coroutineDebugShimSource, chunkName: nil)
        if loaded == LUA_OK, lua_pcall(state, 0, 0, 0) == LUA_OK {
            coroutineShimSavedRefs = (create: createRef, wrap: wrapRef)
        } else {
            // Trusted constant source — a failure here is a build defect, not
            // user input. Roll back so the state is never left half-installed.
            let msg = lua_tostring(state, -1).map { String(cString: $0) } ?? "<no message>"
            lua_pop(state, 1)  // pop the error message
            luaL_unref(state, LUA_REGISTRYINDEX, createRef)
            luaL_unref(state, LUA_REGISTRYINDEX, wrapRef)
            #if DEBUG
            assertionFailure("coroutine debug shim failed to install: \(msg)")
            #endif
        }
    }

    /// Restore the original `coroutine.create` / `coroutine.wrap` and release the
    /// saved registry references. No-op when the shims are not installed.
    ///
    /// internal: called from executeWithDebugHook and resume(_:with:).
    internal func removeCoroutineDebugShims(on state: OpaquePointer) {
        guard let refs = coroutineShimSavedRefs else { return }

        lua_getglobal(state, "coroutine")
        if lua_type(state, -1) == LUA_TTABLE {
            _ = lua_rawgeti(state, LUA_REGISTRYINDEX, lua_Integer(refs.create))
            lua_setfield(state, -2, "create")
            _ = lua_rawgeti(state, LUA_REGISTRYINDEX, lua_Integer(refs.wrap))
            lua_setfield(state, -2, "wrap")
        }
        lua_pop(state, 1)  // pop the coroutine table

        luaL_unref(state, LUA_REGISTRYINDEX, refs.create)
        luaL_unref(state, LUA_REGISTRYINDEX, refs.wrap)
        coroutineShimSavedRefs = nil
    }
}
