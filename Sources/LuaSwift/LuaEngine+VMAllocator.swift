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

// MARK: - Explicit C function-pointer types
//
// Declaring the allocator, panic, open-libs and warning handlers as values of
// these `@convention(c)` typealiases guarantees the compiler passes the raw
// function pointers straight to the Lua C API with no bridging thunk inserted
// (CR-014). The signatures mirror the Lua headers' `lua_Alloc`,
// `lua_CFunction` and `lua_WarnFunction` typedefs across all bundled versions.

/// Matches the C `lua_Alloc` typedef: `void *(*)(void *ud, void *ptr, size_t osize, size_t nsize)`.
private typealias VMAllocFunction =
    @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, Int, Int) -> UnsafeMutableRawPointer?

/// Matches the C `lua_CFunction` typedef: `int (*)(lua_State *L)`.
private typealias VMCFunction = @convention(c) (OpaquePointer?) -> Int32

extension LuaEngine {

    /// Create a Lua state whose every allocation is accounted against `limit`.
    ///
    /// Replicates the post-creation setup that the bundled `luaL_newstate`
    /// performs (panic handler; warning system on Lua 5.4+), since
    /// `lua_newstate` alone installs neither.
    ///
    /// On success the heap-allocated accounting box is handed to the caller
    /// via `accounting` as an opaque raw pointer (ownership transfers; free it
    /// after `lua_close` via ``freeVMAccounting()``). The concrete
    /// ``VMAllocationAccounting`` type stays private to this file.
    internal static func makeLimitedState(
        limit: Int,
        accounting: inout UnsafeMutableRawPointer?
    ) throws -> OpaquePointer {
        let box = UnsafeMutablePointer<VMAllocationAccounting>.allocate(capacity: 1)
        box.initialize(to: VMAllocationAccounting(totalBytes: 0, limit: limit))
        let raw = UnsafeMutableRawPointer(box)

        // Lua 5.5's lua_newstate takes a third random-seed parameter;
        // mirror the bundled luaL_newstate, which seeds via luaL_makeseed.
        #if LUA_VERSION_55
        let state = lua_newstate(vmLimitedAlloc, raw, luaL_makeseed(nil))
        #else
        let state = lua_newstate(vmLimitedAlloc, raw)
        #endif
        guard let state = state else {
            // Initial state allocation denied or failed — same error the
            // luaL_newstate path throws.
            box.deinitialize(count: 1)
            box.deallocate()
            throw LuaError.initializationFailed
        }
        accounting = raw

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
            // Guard the error object's type before reading it: under an
            // exhausted allocator, coercing a non-string (e.g. a number) via
            // lua_tostring would itself allocate. Mirrors vmPanic (CR-013).
            let message: String
            if lua_type(state, -1) == LUA_TSTRING, let cstr = lua_tostring(state, -1) {
                message = String(cString: cstr)
            } else {
                message = "not enough memory"
            }
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
        if let raw = vmAccounting {
            let box = raw.assumingMemoryBound(to: VMAllocationAccounting.self)
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
/// additional locking is needed. Kept file-private (CR-016): the engine holds
/// it only as an opaque `UnsafeMutableRawPointer`.
private struct VMAllocationAccounting {
    /// Total bytes currently allocated by the Lua VM.
    var totalBytes: Int
    /// Ceiling in bytes; growth beyond this is denied.
    var limit: Int
}

/// Custom `lua_Alloc` function enforcing ``LuaEngineConfiguration/vmMemoryLimit``.
///
/// Implements Lua's allocator contract as specified in the *Lua 5.4 Reference
/// Manual* §4.13 (`lua_Alloc`), given `(ud, ptr, osize, nsize)`:
/// - `nsize == 0` frees `ptr` (which may be NULL) and returns NULL.
/// - Otherwise the block is (re)allocated to `nsize` bytes.
/// - When `ptr` is NULL, `osize` encodes the **type** of object being created
///   (Lua 5.2+), not a size — the old size is therefore 0.
/// - Shrinks (`nsize <= osize`) **must never fail**; Lua relies on this
///   guarantee. Only **growth** that would exceed the configured limit is
///   denied by returning NULL, which Lua surfaces as `LUA_ERRMEM`.
///
/// Control flow (CR-004/005/006):
/// 1. The free path (`nsize == 0`) runs first and always calls `free`, even
///    when `ud` is nil, so no block is ever leaked; the accounting decrement
///    is the only `ud`-guarded step and is clamped at zero so a stale/oversized
///    `osize` cannot drive the counter negative (which would silently disable
///    the ceiling).
/// 2. With no accounting box and a non-free request, behave like the default
///    allocator.
/// 3. Growth is denied via a subtraction (`delta > limit - total`) so an
///    adversarial huge `nsize` cannot overflow `Int` and trap the process.
/// 4. Shrink/equal never returns NULL: if `realloc` declines, the original
///    (still valid) block is returned, honoring the never-fail contract.
private let vmLimitedAlloc: VMAllocFunction = { ud, ptr, osize, nsize in
    // (1) Free path first — always release the block regardless of `ud`.
    if nsize == 0 {
        free(ptr)
        if let ud = ud {
            let accounting = ud.assumingMemoryBound(to: VMAllocationAccounting.self)
            // A free with a non-NULL ptr carries the real old size in osize.
            // Lua may also pass ptr == NULL here (a no-op free); the guard
            // then subtracts 0 rather than misreading a type tag as a size.
            let oldSize = (ptr != nil) ? osize : 0
            accounting.pointee.totalBytes = max(0, accounting.pointee.totalBytes - oldSize)
            assert(accounting.pointee.totalBytes >= 0)
        }
        return nil
    }

    // (2) Non-free request with no accounting box: plain realloc, no tracking.
    guard let ud = ud else {
        return realloc(ptr, nsize)
    }
    let accounting = ud.assumingMemoryBound(to: VMAllocationAccounting.self)

    // For fresh allocations (ptr == NULL) osize is a type tag, not a size.
    let oldSize = (ptr != nil) ? osize : 0
    let delta = nsize - oldSize

    if delta > 0 {
        // (3) Growth: deny if it would breach the ceiling. Compare via the
        // remaining headroom (limit - total) — both operands are non-negative
        // (total is clamped, limit >= 0), so this cannot overflow, whereas
        // `total + delta` could with an adversarial `nsize`.
        let total = accounting.pointee.totalBytes
        let limit = accounting.pointee.limit
        if delta > limit - total {
            return nil  // deny growth beyond the ceiling; Lua raises LUA_ERRMEM
        }
        guard let newPtr = realloc(ptr, nsize) else {
            return nil  // genuine out-of-memory on growth; counter unchanged
        }
        // total >= 0 and delta > 0 here, so the sum is always positive — no
        // clamp needed (unlike the free/shrink paths where delta can be < 0).
        accounting.pointee.totalBytes = total + delta
        return newPtr
    } else {
        // (4) Shrink or same size (delta <= 0): the contract forbids failure.
        // If realloc declines to move/shrink, the original block stays valid.
        let p = realloc(ptr, nsize) ?? ptr
        accounting.pointee.totalBytes = max(0, accounting.pointee.totalBytes + delta)
        assert(accounting.pointee.totalBytes >= 0)
        return p
    }
}

// MARK: - Zero-heap stderr output
//
// Panic and warning handlers fire during error and out-of-memory conditions.
// Building a Swift `String` there (e.g. `String(cString:)`) routes through
// `_swift_slowAlloc`, which aborts the whole process under true memory
// pressure. These helpers emit only via `fwrite`/`fputs` on storage that is
// already allocated, never touching the Swift heap (CR-012), matching the
// reference lauxlib.c which uses plain `fputs`.

/// Write a compile-time string literal to `stream` with no heap allocation.
/// `StaticString` literals live in static storage, and `withUTF8Buffer`
/// exposes their bytes without copying, so this never calls the Swift
/// allocator (unlike passing a `String` literal to `fputs`, which would
/// materialize a temporary UTF-8 buffer).
@inline(__always)
private func vmFPuts(_ literal: StaticString, _ stream: UnsafeMutablePointer<FILE>!) {
    literal.withUTF8Buffer { buf in
        _ = fwrite(buf.baseAddress, 1, buf.count, stream)
    }
}

/// Panic handler matching the bundled `luaL_newstate` behavior: print the
/// error to stderr and return to Lua, which then aborts. The `lua_type` check
/// avoids memory errors inside `lua_tostring` (mirrors lauxlib.c `panic`), and
/// the message is written straight from Lua's `const char*` with no Swift
/// String allocated (CR-012).
private let vmPanic: VMCFunction = { L in
    vmFPuts("PANIC: unprotected error in call to Lua API (", stderr)
    if let L = L, lua_type(L, -1) == LUA_TSTRING, let msg = lua_tostring(L, -1) {
        fputs(msg, stderr)
    } else {
        vmFPuts("error object is not a string", stderr)
    }
    vmFPuts(")\n", stderr)
    return 0  // return to Lua to abort
}

/// Protected trampoline opening the standard libraries; called via
/// `lua_pcall`/`lua_cpcall` so allocation failures unwind instead of aborting.
private let vmOpenLibs: VMCFunction = { L in
    luaL_openlibs(L)
    return 0
}

#if LUA_VERSION_54 || LUA_VERSION_55
// Warning system replicating the bundled luaL_newstate state machine
// (lauxlib.c warnfoff/warnfon/warnfcont): warnings start off, the control
// messages "@on"/"@off" toggle them, multi-part warnings are concatenated
// and finished with a newline on stderr. `ud` is the main lua_State. All
// output goes straight from Lua's `const char*` to stderr with no Swift String
// allocated (CR-012), since these handlers may fire under memory pressure.

/// Matches the C `lua_WarnFunction` typedef: `void (*)(void *ud, const char *msg, int tocont)`.
private typealias VMWarnFunction =
    @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, Int32) -> Void

/// Compare a NUL-terminated C string against a compile-time literal with no
/// heap allocation (avoids `strcmp` against a bridged `String` temporary).
private func vmCStrEquals(_ cstr: UnsafePointer<CChar>, _ literal: StaticString) -> Bool {
    return literal.withUTF8Buffer { buf in
        for i in 0..<buf.count {
            let c = cstr[i]
            // Stop at the C string's terminator or any byte mismatch.
            if c == 0 || CChar(bitPattern: buf[i]) != c { return false }
        }
        // Equal length: the literal's run must end exactly at the terminator.
        return cstr[buf.count] == 0
    }
}

/// Handle a control message ("@on"/"@off"; unknown "@..." ignored).
/// Returns `true` when the message was a control message (consumed).
private func vmWarnControl(_ L: OpaquePointer, _ msg: UnsafePointer<CChar>, _ tocont: Int32) -> Bool {
    guard tocont == 0, msg.pointee == CChar(UInt8(ascii: "@")) else { return false }
    if vmCStrEquals(msg, "@off") {
        lua_setwarnf(L, vmWarnOff, UnsafeMutableRawPointer(L))
    } else if vmCStrEquals(msg, "@on") {
        lua_setwarnf(L, vmWarnOn, UnsafeMutableRawPointer(L))
    }
    return true
}

/// Warning system is off: only watch for control messages.
private let vmWarnOff: VMWarnFunction = { ud, msg, tocont in
    guard let ud = ud, let msg = msg else { return }
    _ = vmWarnControl(OpaquePointer(ud), msg, tocont)
}

/// Ready to start a new warning message.
private let vmWarnOn: VMWarnFunction = { ud, msg, tocont in
    guard let ud = ud, let msg = msg else { return }
    let L = OpaquePointer(ud)
    if vmWarnControl(L, msg, tocont) { return }
    vmFPuts("Lua warning: ", stderr)
    vmWarnWrite(L, msg, tocont)
}

/// A previous message part is to be continued.
private let vmWarnCont: VMWarnFunction = { ud, msg, tocont in
    guard let ud = ud, let msg = msg else { return }
    vmWarnWrite(OpaquePointer(ud), msg, tocont)
}

/// Write one message part and arm the next warn function accordingly.
private func vmWarnWrite(_ L: OpaquePointer, _ msg: UnsafePointer<CChar>, _ tocont: Int32) {
    fputs(msg, stderr)
    if tocont != 0 {
        lua_setwarnf(L, vmWarnCont, UnsafeMutableRawPointer(L))
    } else {
        vmFPuts("\n", stderr)
        lua_setwarnf(L, vmWarnOn, UnsafeMutableRawPointer(L))
    }
}
#endif  // LUA_VERSION_54 || LUA_VERSION_55
