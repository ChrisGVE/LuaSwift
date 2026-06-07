//
//  LuaEngine+VMAllocator.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+VMAllocator.swift
//
//  Context: VM-memory-limit concern of LuaEngine. When
//  LuaEngineConfiguration.vmMemoryLimit is set, LuaEngine.init
//  (LuaEngine.swift) calls makeLimitedState/openLibrariesProtected here
//  to create the Lua state with the custom accounting allocator
//  (vmLimitedAlloc) instead of luaL_newstate, and deinit calls
//  freeVMAccounting after lua_close. The file also replicates the
//  panic-handler and warning-system setup that the bundled luaL_newstate
//  would otherwise install. Allocation denials surface as
//  LuaError.memoryError (LuaError.swift); see issue #11.
//

import Foundation
import CLua

extension LuaEngine {

    /// Create a Lua state whose every allocation is accounted against `limit`.
    ///
    /// Replicates the post-creation setup that the bundled `luaL_newstate`
    /// performs (panic handler; warning system on Lua 5.4+), since
    /// `lua_newstate` alone installs neither.
    ///
    /// On success the heap-allocated accounting box is handed to the caller
    /// via `accounting` (ownership transfers; free it after `lua_close`).
    internal static func makeLimitedState(
        limit: Int,
        accounting: inout UnsafeMutablePointer<VMAllocationAccounting>?
    ) throws -> OpaquePointer {
        let box = UnsafeMutablePointer<VMAllocationAccounting>.allocate(capacity: 1)
        box.initialize(to: VMAllocationAccounting(totalBytes: 0, limit: limit))

        // Lua 5.5's lua_newstate takes a third random-seed parameter;
        // mirror the bundled luaL_newstate, which seeds via luaL_makeseed.
        #if LUA_VERSION_55
        let state = lua_newstate(vmLimitedAlloc, box, luaL_makeseed(nil))
        #else
        let state = lua_newstate(vmLimitedAlloc, box)
        #endif
        guard let state = state else {
            // Initial state allocation denied or failed — same error the
            // luaL_newstate path throws.
            box.deinitialize(count: 1)
            box.deallocate()
            throw LuaError.initializationFailed
        }
        accounting = box

        _ = lua_atpanic(state, vmPanic)
        #if LUA_VERSION_54 || LUA_VERSION_55
        // Default is warnings off, switchable with warn("@on") — exactly
        // like the bundled luaL_newstate.
        lua_setwarnf(state, vmWarnOff, UnsafeMutableRawPointer(state))
        #endif
        return state
    }

    /// Run `luaL_openlibs` inside a protected call so that an allocation
    /// denial (VM limit too small for the standard libraries) surfaces as a
    /// thrown ``LuaError`` instead of an unprotected abort.
    internal static func openLibrariesProtected(on state: OpaquePointer) throws {
        // Lua 5.1 cannot push the trampoline without allocating a closure
        // (itself a potential unprotected failure); lua_cpcall avoids that.
        // On 5.2+ a zero-upvalue C function is a light value — no allocation.
        #if LUA_VERSION_51
        let result = lua_cpcall(state, vmOpenLibs, nil)
        #else
        lua_pushcfunction(state, vmOpenLibs)
        let result = lua_pcall(state, 0, 0, 0)
        #endif
        if result != LUA_OK {
            let message = lua_tostring(state, -1).map { String(cString: $0) }
                ?? "not enough memory"
            lua_pop(state, 1)
            switch result {
            case LUA_ERRMEM:
                throw LuaError.memoryError(message)
            default:
                throw LuaError.runtimeError(message)
            }
        }
    }

    /// Free the allocation-accounting box. Only call after `lua_close` (or
    /// when no state was created) — see ``vmAccounting``.
    internal func freeVMAccounting() {
        if let box = vmAccounting {
            box.deinitialize(count: 1)
            box.deallocate()
            vmAccounting = nil
        }
    }
}

// MARK: - VM Memory Limit (custom lua_Alloc)

/// Mutable accounting state shared between ``LuaEngine`` and ``vmLimitedAlloc``.
///
/// Heap-allocated by the engine and passed to `lua_newstate` as the
/// allocator's `ud` pointer, so the capture-less C allocator needs no
/// global state. The Lua state serializes its own allocations, so no
/// additional locking is needed.
struct VMAllocationAccounting {
    /// Total bytes currently allocated by the Lua VM.
    var totalBytes: Int
    /// Ceiling in bytes; growth beyond this is denied.
    var limit: Int
}

/// Custom `lua_Alloc` function enforcing ``LuaEngineConfiguration/vmMemoryLimit``.
///
/// Implements Lua's allocator contract (`(ud, ptr, osize, nsize)`):
/// - `nsize == 0` frees `ptr` (which may be NULL) and returns NULL.
/// - Otherwise the block is (re)allocated to `nsize` bytes.
/// - When `ptr` is NULL, `osize` encodes the **type** of object being created
///   (Lua 5.2+), not a size — the old size is therefore 0.
/// - Shrinks (`nsize <= osize`) must never fail; only **growth** that would
///   exceed the configured limit is denied by returning NULL, which Lua
///   surfaces as `LUA_ERRMEM`.
private func vmLimitedAlloc(
    _ ud: UnsafeMutableRawPointer?,
    _ ptr: UnsafeMutableRawPointer?,
    _ osize: Int,
    _ nsize: Int
) -> UnsafeMutableRawPointer? {
    guard let ud = ud else { return nil }
    let accounting = ud.assumingMemoryBound(to: VMAllocationAccounting.self)

    // For fresh allocations (ptr == NULL) osize is a type tag, not a size.
    let oldSize = (ptr != nil) ? osize : 0

    if nsize == 0 {
        free(ptr)
        accounting.pointee.totalBytes -= oldSize
        return nil
    }

    let delta = nsize - oldSize
    if delta > 0 && accounting.pointee.totalBytes + delta > accounting.pointee.limit {
        return nil  // deny growth beyond the ceiling; Lua raises LUA_ERRMEM
    }

    guard let newPtr = realloc(ptr, nsize) else {
        return nil  // genuine out-of-memory; counter unchanged
    }
    accounting.pointee.totalBytes += delta
    return newPtr
}

/// Panic handler matching the bundled `luaL_newstate` behavior: print the
/// error to stderr and return to Lua, which then aborts. The `lua_type` check
/// avoids memory errors inside `lua_tostring` (mirrors lauxlib.c `panic`).
private func vmPanic(_ L: OpaquePointer?) -> Int32 {
    var message = "error object is not a string"
    if let L = L, lua_type(L, -1) == LUA_TSTRING, let msg = lua_getstring(L, -1) {
        message = msg
    }
    fputs("PANIC: unprotected error in call to Lua API (\(message))\n", stderr)
    return 0  // return to Lua to abort
}

/// Protected trampoline opening the standard libraries; called via
/// `lua_pcall`/`lua_cpcall` so allocation failures unwind instead of aborting.
private func vmOpenLibs(_ L: OpaquePointer?) -> Int32 {
    luaL_openlibs(L)
    return 0
}

#if LUA_VERSION_54 || LUA_VERSION_55
// Warning system replicating the bundled luaL_newstate state machine
// (lauxlib.c warnfoff/warnfon/warnfcont): warnings start off, the control
// messages "@on"/"@off" toggle them, multi-part warnings are concatenated
// and finished with a newline on stderr. `ud` is the main lua_State.

/// Handle a control message ("@on"/"@off"; unknown "@..." ignored).
/// Returns `true` when the message was a control message (consumed).
private func vmWarnControl(_ L: OpaquePointer, _ message: String, _ tocont: Int32) -> Bool {
    guard tocont == 0, message.hasPrefix("@") else { return false }
    if message == "@off" {
        lua_setwarnf(L, vmWarnOff, UnsafeMutableRawPointer(L))
    } else if message == "@on" {
        lua_setwarnf(L, vmWarnOn, UnsafeMutableRawPointer(L))
    }
    return true
}

/// Warning system is off: only watch for control messages.
private func vmWarnOff(_ ud: UnsafeMutableRawPointer?, _ msg: UnsafePointer<CChar>?, _ tocont: Int32) {
    guard let ud = ud, let msg = msg else { return }
    _ = vmWarnControl(OpaquePointer(ud), String(cString: msg), tocont)
}

/// Ready to start a new warning message.
private func vmWarnOn(_ ud: UnsafeMutableRawPointer?, _ msg: UnsafePointer<CChar>?, _ tocont: Int32) {
    guard let ud = ud, let msg = msg else { return }
    let L = OpaquePointer(ud)
    let message = String(cString: msg)
    if vmWarnControl(L, message, tocont) { return }
    fputs("Lua warning: ", stderr)
    vmWarnWrite(L, message, tocont)
}

/// A previous message part is to be continued.
private func vmWarnCont(_ ud: UnsafeMutableRawPointer?, _ msg: UnsafePointer<CChar>?, _ tocont: Int32) {
    guard let ud = ud, let msg = msg else { return }
    vmWarnWrite(OpaquePointer(ud), String(cString: msg), tocont)
}

/// Write one message part and arm the next warn function accordingly.
private func vmWarnWrite(_ L: OpaquePointer, _ message: String, _ tocont: Int32) {
    fputs(message, stderr)
    if tocont != 0 {
        lua_setwarnf(L, vmWarnCont, UnsafeMutableRawPointer(L))
    } else {
        fputs("\n", stderr)
        lua_setwarnf(L, vmWarnOn, UnsafeMutableRawPointer(L))
    }
}
#endif  // LUA_VERSION_54 || LUA_VERSION_55
