//
//  LuaEngine+Cancellation.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Cancellation.swift
//
//  Context: Public cooperative-cancellation API for LuaEngine (#22).
//  requestCancellation() and resetCancellation() are the sole interface
//  between the owner thread and the VM thread. The running script is
//  interrupted at the next compositor hook fire (LuaEngine+Execution.swift)
//  and throws LuaError.cancelled (LuaError.swift). Atomic state lives in
//  LuaEngine.swift alongside the other execution-control fields.
//
//  Neighbors:
//    LuaEngine+CompositorHook.swift — hook that reads cancellationRequested
//    LuaEngine+Execution.swift      — errorFromCode reads/clears abortReason
//    LuaEngine.swift                — cancellationRequested, abortReason fields
//

import Atomics
import Foundation

extension LuaEngine {

    // MARK: - Cooperative Cancellation

    /// Request cooperative cancellation of in-flight Lua execution.
    ///
    /// Sets an atomic flag that the periodic compositor hook checks on every
    /// fire (every ``hookInterval`` VM instructions). The running code aborts
    /// at the next hook fire and throws ``LuaError/cancelled``.
    ///
    /// **Thread-safety:** Lock-free. This method MUST NOT and does NOT acquire
    /// the engine's run lock (`lock`), which is held for the entire duration of
    /// any `run`/`evaluate` call. It is safe to call this from any thread or
    /// DispatchQueue while Lua is executing.
    ///
    /// **Latency:** The abort is cooperative — the hook fires at most every
    /// ``hookInterval`` Lua VM instructions, so actual latency depends on Lua
    /// throughput. Measured at ~1–3 ms on Apple Silicon; the documented target
    /// is 200 ms (CI threshold 400 ms). A C function that never returns to the
    /// VM loop (e.g. `string.rep("A", 1e9)`) cannot be interrupted — the same
    /// documented limitation as the instruction limit.
    ///
    /// **No-op if idle:** Setting the flag while no run is active has no effect
    /// (the flag will be cleared by the next ``resetCancellation()`` call).
    ///
    /// **Requires the cancellation hook.** The flag is only observed while the
    /// periodic count hook is armed. An engine created with
    /// ``LuaEngineConfiguration/cooperativeCancellation`` set to `false` and no
    /// instruction limit does **not** arm that hook, so this call cannot
    /// interrupt its runs (issue #30). Setting an instruction limit re-arms the
    /// hook and restores cancellation.
    public func requestCancellation() {
        cancellationRequested.store(true, ordering: .releasing)
    }

    /// Clear a prior cancellation request so the engine can be reused.
    ///
    /// Call this after a ``LuaError/cancelled`` or
    /// ``LuaError/instructionLimitExceeded`` outcome before running another
    /// script on the same engine. Also clears the out-of-band abort-reason flag
    /// and the instruction accumulator so they do not carry over.
    ///
    /// **When is this required?** After both `.cancelled` and
    /// `.instructionLimitExceeded` outcomes: both set `abortReason`, which must
    /// be cleared here so the next run's error-classification is unaffected.
    /// A run that completes normally never sets these flags, so no reset is
    /// needed in the normal case.
    ///
    /// **Must not be called during an active run.** Calling this while a script
    /// is executing on another thread is a programming error: it races with the
    /// compositor hook and can cause the running script to observe an
    /// inconsistent cancellation state.
    ///
    /// **Thread-safety:** May be called from any thread. It is conventional to
    /// call it from the same thread/queue that owns the engine, after awaiting
    /// the result of the aborted run.
    public func resetCancellation() {
        cancellationRequested.store(false, ordering: .releasing)
        abortReason.store(AbortReason.none, ordering: .releasing)
        instructionAccumulator = 0
    }
}
