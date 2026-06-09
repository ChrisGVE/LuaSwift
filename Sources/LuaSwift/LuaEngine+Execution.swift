//
//  LuaEngine+Execution.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Execution.swift
//
//  Context: Source-execution concern of LuaEngine — run(_:)/evaluate(_:)
//  for Lua source strings. The periodic compositor hook is defined in
//  LuaEngine+CompositorHook.swift; armCompositorHook (below) arms it before
//  every protected call here and in LuaEngine+Bytecode.swift,
//  LuaEngine+FunctionCalls.swift, and LuaEngine+Coroutines.swift.
//  errorFromCode reads the out-of-band abortReason flag first (before string
//  matching) so cancel/limit are detected correctly even when the errfunc
//  (#19) reshapes the message. Results are converted via valueFromStack
//  (LuaEngine+Bridging.swift).
//
//  Neighbors:
//    LuaEngine+CompositorHook.swift — compositorHookCallback + sentinels
//    LuaEngine+Bytecode.swift       — precompile / run(CompiledChunk)
//    LuaEngine+FunctionCalls.swift  — callLuaFunction
//    LuaEngine+Coroutines.swift     — coroutine resume
//

import Atomics
import Foundation
import CLua

extension LuaEngine {

    // MARK: - Instruction Limit

    /// Set the maximum number of Lua VM instructions per `run`/`evaluate` call.
    ///
    /// When the running chunk executes more than `count` instructions, a
    /// ``LuaError/instructionLimitExceeded`` error is thrown.  This provides a
    /// deterministic way to abort runaway Lua code (e.g. infinite loops) without
    /// relying on OS-level timeouts or threads.
    ///
    /// The limit is re-applied before every `pcall`, so it applies equally to
    /// each individual `run` and `evaluate` invocation.
    ///
    /// The limit is enforced on every execution entry point — `run`, `evaluate`
    /// (both the source and `CompiledChunk` overloads), the deprecated
    /// `runBytecode`/`evaluateBytecode`, `callLuaFunction`, and coroutine `resume`.
    ///
    /// - Note: The count is **per call**, not a lifetime budget. For coroutines the
    ///   count is reset to the full limit on every `resume`, so a coroutine that
    ///   yields can execute up to `count` instructions between each resume. Do not
    ///   treat the limit as a total instruction ceiling for adversarial code that can
    ///   call `coroutine.yield()`; if you need a hard sandbox, also restrict or remove
    ///   the `coroutine` library.
    ///
    /// - Important: The instruction limit is a **CPU-bound control only**. The
    ///   count hook fires between VM instructions, so a *single* instruction
    ///   that calls a C function — `string.rep('A', 1e9)`, pathological
    ///   `string.find`/`string.gsub` patterns, long-running Swift callbacks —
    ///   runs to completion uninterrupted and is free to allocate unbounded
    ///   memory. Pair the instruction limit with
    ///   ``LuaEngineConfiguration/vmMemoryLimit`` to also bound Lua VM memory.
    ///
    /// - Note: **Overshoot when `count > hookInterval`.** The compositor hook
    ///   fires every `hookInterval` instructions (default 10 000). When `count`
    ///   exceeds `hookInterval`, the abort fires at the first hook fire that
    ///   reaches or surpasses `count` — i.e. the actual abort point is in the
    ///   range `[count, count + hookInterval)`. For precise at-or-before
    ///   semantics, set `count ≤ hookInterval`: the hook is then armed with
    ///   `min(hookInterval, count)` so the first fire cannot overshoot the limit.
    ///
    /// - Parameter count: Maximum instruction count per call. Pass `0` to disable
    ///   the hook entirely (the default). Negative values are treated as `0`.
    ///   Values above `Int32.max` are clamped to `Int32.max` (the hook count is a
    ///   C `int`), avoiding a runtime overflow trap.
    public func setInstructionLimit(_ count: Int) {
        lock.lock()
        defer { lock.unlock() }
        instructionLimit = max(0, min(count, Int(Int32.max)))
    }

    /// Arm the periodic compositor hook on the given Lua state.
    ///
    /// The compositor fires every `min(hookInterval, instructionLimit)` instructions
    /// (or every `hookInterval` when no limit is set). On each fire it checks the
    /// cancellation flag first, then the instruction accumulator against the limit.
    /// Using `min` prevents overshooting a limit that is smaller than `hookInterval`.
    ///
    /// Must be called at the start of every run entry point so cancellation and
    /// the instruction limit apply to source execution, bytecode execution,
    /// stored-function calls, and coroutine resumes alike.
    ///
    /// **TLS side-effect:** Installs this engine as the TLS current engine
    /// (``setAsCurrentEngine()``) so the C compositor callback can recover it
    /// without a global map. Callers must pair this with a restore on exit.
    ///
    /// internal: shared with +Bytecode, +FunctionCalls, +Coroutines
    internal func armCompositorHook(on state: OpaquePointer) {
        // Arm count: use min(hookInterval, limit) when a limit is active so the
        // first fire cannot overshoot a limit smaller than hookInterval.
        // Store the armed count so the hook can accumulate exactly that many
        // instructions per fire regardless of which branch was taken.
        let count: Int32
        if instructionLimit > 0 {
            count = Int32(min(hookInterval, instructionLimit))
        } else {
            count = Int32(hookInterval)
        }
        armedHookCount = Int(count)
        lua_sethook(state, compositorHookCallback, Int32(LUA_MASKCOUNT), count)
    }

    // MARK: - Execution

    /// Execute Lua code without returning a result.
    ///
    /// Use this when you don't need the return value. Any return values
    /// from the Lua code are discarded.
    ///
    /// - Parameters:
    ///   - code: The Lua source code to execute.
    ///   - chunkName: An optional name for this chunk, used in error messages
    ///     and tracebacks instead of a truncated snippet of the source.
    ///     When provided, LuaSwift passes `"@" + chunkName` to `luaL_loadbuffer`
    ///     so that Lua's `short_src` uses the `@`-prefix truncation rule: names
    ///     up to `LUA_IDSIZE` (60 bytes) appear verbatim; longer names are
    ///     tail-preserving — the **leftmost portion is dropped** and the name is
    ///     shown as `"…"` followed by the rightmost (most-specific) characters.
    ///     This keeps the most-specific path component visible — ideal for names
    ///     such as `"config.yaml:$.scripts.init"`. When `nil`, the source text
    ///     itself is used as the name (replicating `luaL_loadstring` exactly),
    ///     which produces the familiar `[string "..."]` traceback form.
    /// - Throws: `LuaError` if execution fails, ``LuaError/cancelled`` if
    ///   ``requestCancellation()`` was called from another thread during execution
    public func run(_ code: String, chunkName: String? = nil) throws {
        guard !isPaused.load(ordering: .acquiring) else {
            throw LuaError.enginePaused
        }
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        try resetStateAndLoadChunk(L, code: code, chunkName: chunkName)

        // Arm the compositor hook and install TLS so the C callback can find us.
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armCompositorHook(on: L)

        let handlerIdx = installErrorHandler(L)

        // Execute with nresults=0 (discard any return values).
        let callResult = lua_pcall(L, 0, 0, handlerIdx)
        lua_remove(L, handlerIdx)
        try throwIfPcallFailed(L, callResult: callResult)
    }

    /// Execute Lua code and return the result.
    ///
    /// - Parameters:
    ///   - code: The Lua source code to execute.
    ///   - chunkName: An optional name for this chunk, used in error messages
    ///     and tracebacks. See ``run(_:chunkName:)`` for the full name-prefix
    ///     convention and `LUA_IDSIZE` truncation behavior.
    /// - Returns: The result of the execution as a `LuaValue`
    /// - Throws: `LuaError` if execution fails, ``LuaError/cancelled`` if
    ///   ``requestCancellation()`` was called from another thread during execution
    public func evaluate(_ code: String, chunkName: String? = nil) throws -> LuaValue {
        guard !isPaused.load(ordering: .acquiring) else {
            throw LuaError.enginePaused
        }
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        try resetStateAndLoadChunk(L, code: code, chunkName: chunkName)

        // Arm the compositor hook and install TLS.
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armCompositorHook(on: L)

        let handlerIdx = installErrorHandler(L)

        // Execute with nresults=1 (expect one return value).
        let callResult = lua_pcall(L, 0, 1, handlerIdx)
        lua_remove(L, handlerIdx)
        try throwIfPcallFailed(L, callResult: callResult)

        // Convert result and pop it.
        let result = try valueFromStack(at: -1)
        lua_pop(L, 1)
        return result
    }

    // MARK: - Shared execution plumbing
    // Reused by run/evaluate here and by loadAndExecuteBytecode
    // (LuaEngine+Bytecode.swift); `internal` so they cross the extension-file
    // boundary. callLuaFunction (LuaEngine+FunctionCalls.swift) deliberately
    // does NOT use these — its re-entrant stack discipline (entryTop base,
    // handler pushed before the function) differs.

    /// Clear all per-run mutable state so a prior cancel/limit abort or
    /// structured-error stash cannot fire spuriously into this execution.
    /// Call with the engine lock held, before loading the chunk.
    internal func resetPerRunState() {
        abortReason.store(AbortReason.none, ordering: .releasing)
        instructionAccumulator = 0
        pendingRuntimeFailure = nil
        lastWriteError = nil
    }

    /// Reset per-run state and load `code` as a chunk onto the stack.
    ///
    /// Must be called with the engine lock held and *before* TLS/hook setup.
    /// On a load failure the error message is popped and a
    /// ``LuaError/syntaxError(_:)`` is thrown.
    ///
    /// Chunk-name convention: when `chunkName` is `nil` the source string is
    /// passed as the name — exactly what `luaL_loadstring` does
    /// (`luaL_loadstring(L,s) == luaL_loadbuffer(L,s,len,s)`). When provided it
    /// is `@`-prefixed so Lua applies tail (not head) truncation in `short_src`.
    private func resetStateAndLoadChunk(
        _ L: OpaquePointer, code: String, chunkName: String?
    ) throws {
        resetPerRunState()

        let loadResult = loadSourceChunk(L, code: code, chunkName: chunkName)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }
    }

    /// Push the runtime-error handler below the just-loaded chunk and return
    /// its (fixed) stack index.
    ///
    /// `lua_pcall` requires the errfunc to sit BELOW the called function. The
    /// chunk is already on the stack, so we push the handler on top and slide it
    /// down with `lua_insert(L, 1)`:
    ///
    ///     before:                  [chunk(1)]
    ///     after lua_pushcfunction: [chunk(1), handler(2)]
    ///     after lua_insert(L, 1):  [handler(1), chunk(2)]   ← desired
    ///
    /// `lua_insert(L, 1)` moves the TOP element to index 1, shifting everything
    /// up; it is shimmed for all Lua versions in LuaHelpers+CMacros.swift.
    internal func installErrorHandler(_ L: OpaquePointer) -> Int32 {
        lua_pushcfunction(L, runtimeErrorHandler)
        lua_insert(L, 1)
        return 1
    }

    /// Throw the appropriate `LuaError` if a pcall (whose handler has already
    /// been removed) failed; no-op on success.
    ///
    /// On entry after an error the stack is `[error_obj]`; this reads and pops
    /// it. A write error generated by LuaSwift takes precedence over the generic
    /// `errorFromCode` mapping.
    internal func throwIfPcallFailed(_ L: OpaquePointer, callResult: Int32) throws {
        guard callResult != LUA_OK else { return }

        let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
        lua_pop(L, 1)

        #if DEBUG
        // After an abort the stack must be back at the pcall base (handler
        // removed, error object popped). A non-zero top means a leak.
        assert(lua_gettop(L) == 0, "Stack not clean after pcall abort: top=\(lua_gettop(L))")
        #endif

        if let writeError = lastWriteError {
            lastWriteError = nil
            throw writeError
        }

        throw errorFromCode(callResult, message: message)
    }

    /// Load a Lua source string onto the stack, applying the chunk-name
    /// convention used throughout LuaSwift.
    ///
    /// **Name-prefix rule (implements issue #23):**
    /// - `chunkName == nil` → pass the source string itself as the name,
    ///   replicating `luaL_loadstring` exactly. Tracebacks show
    ///   `[string "…"]`, preserving pre-#23 behavior byte-for-byte.
    /// - `chunkName != nil` → pass `"@" + chunkName`. Lua's `@` prefix
    ///   directs `short_src` to apply tail truncation when the name exceeds
    ///   `LUA_IDSIZE` (60 bytes): names that fit appear verbatim; longer
    ///   names show `"…"` + the tail. This keeps the most-specific path
    ///   component visible — correct for `FragmentProvenance.displayName`
    ///   style names. The alternative prefix `=` would truncate from the
    ///   head instead, losing specificity.
    ///
    /// internal: shared by run(_:chunkName:), evaluate(_:chunkName:), and
    /// the coroutine load path in LuaEngine+Coroutines.swift.
    ///
    /// - Parameters:
    ///   - L: The Lua state to load into.
    ///   - code: Lua source text.
    ///   - chunkName: Caller-supplied chunk name, or nil for default behavior.
    /// - Returns: Lua status code (`LUA_OK` on success).
    @discardableResult
    internal func loadSourceChunk(
        _ L: OpaquePointer,
        code: String,
        chunkName: String?
    ) -> Int32 {
        // Use luaL_loadbuffer_source (LuaHelpers.swift) — the Swift wrapper
        // for the luaL_loadbuffer macro — so we can supply an explicit name.
        // luaL_loadstring is equivalent to:
        //   luaL_loadbuffer(L, s, strlen(s), s)
        // so passing the source as name reproduces that behavior exactly.
        let name = chunkName.map { "@" + $0 } ?? code
        return code.withCString { codeCStr in
            name.withCString { nameCStr in
                luaL_loadbuffer_source(L, codeCStr, code.utf8.count, nameCStr)
            }
        }
    }

    // MARK: - Random Seeding

    /// Set the random seed for math.random().
    ///
    /// Use a fixed seed for reproducible tests.
    ///
    /// - Parameter seed: The seed value
    public func seed(_ seed: Int) throws {
        try run("math.randomseed(\(seed))")
    }

    // MARK: - Error Classification

    /// Map a Lua status code (and error message) to the matching ``LuaError``.
    ///
    /// Priority order:
    /// 1. **Out-of-band abort reason** (``abortReason`` atomic, set by the
    ///    compositor hook) — checked FIRST so cancel/limit are detected
    ///    correctly even after the errfunc (#19) has run.
    /// 2. **Belt-and-suspenders sentinel matching** — string sentinels for
    ///    the same cancel/limit cases, for rare atomic-write-races on very
    ///    old hardware.
    /// 3. **Structured error stash** (``pendingRuntimeFailure``) — populated
    ///    by the `runtimeErrorHandler` errfunc while the stack was intact.
    ///    Cleared here after reading so it does not persist across calls.
    /// 4. **Plain string fallback** — preserves the pre-#19 `.runtimeError`
    ///    path for coroutine errors (which use `lua_resume`, no errfunc) and
    ///    any edge case where the handler did not run (e.g. `LUA_ERRSYNTAX`).
    ///
    /// internal: shared with the bytecode and function-call paths
    internal func errorFromCode(_ code: Int32, message: String) -> LuaError {
        // Step 1: Out-of-band reason set by the compositor hook — authoritative.
        let reason = abortReason.load(ordering: .acquiring)
        if reason == AbortReason.cancelled { return .cancelled }
        if reason == AbortReason.instructionLimitExceeded { return .instructionLimitExceeded }

        // Step 2: Belt-and-suspenders sentinel matching — only when the hook DID
        // set an abort reason (abortReason != none). This gates the string-fallback
        // behind the atomic, preventing untrusted Lua from manufacturing
        // .cancelled/.instructionLimitExceeded by calling error() with a sentinel
        // string (CR-102). abortReason is reset to .none at every run entry point,
        // so this branch is only reachable after a genuine hook-triggered abort.
        if reason != AbortReason.none && code == LUA_ERRRUN {
            if message.contains(instructionLimitSentinel) {
                return .instructionLimitExceeded
            }
            if message.contains(cancelledSentinel) {
                return .cancelled
            }
        }

        // Lua 5.3's luaL_Buffer reports an allocation failure (e.g. a denial by
        // the vmMemoryLimit allocator during string.rep) as a *runtime* error
        // with this exact lauxlib.c message instead of LUA_ERRMEM. Normalize it
        // so memory exhaustion is .memoryError on every version. This MUST come
        // before the structured-error stash below: the errfunc stashes every
        // non-sentinel LUA_ERRRUN, so leaving it after would let the stash
        // classify a genuine OOM as a plain .runtimeFailure (the failure mode
        // this normalization exists to prevent). Clear the stash too, so it
        // cannot bleed into a subsequent call.
        if code == LUA_ERRRUN && message.contains("not enough memory for buffer allocation") {
            pendingRuntimeFailure = nil
            return .memoryError(message)
        }

        // Step 3: Structured error captured by the errfunc handler (#19).
        // Consume and clear the stash so it cannot bleed into a subsequent call.
        if code == LUA_ERRRUN, let failure = pendingRuntimeFailure {
            pendingRuntimeFailure = nil
            return .runtimeFailure(failure)
        }

        // Step 4: Plain string fallback (pre-#19 behavior, source-compatible).
        switch code {
        case LUA_ERRSYNTAX:
            return .syntaxError(message)
        case LUA_ERRRUN:
            return .runtimeError(message)
        case LUA_ERRMEM:
            return .memoryError(message)
        case LUA_ERRERR:
            return .errorHandlerError(message)
        default:
            return .unknown(code: Int(code), message: message)
        }
    }
}
