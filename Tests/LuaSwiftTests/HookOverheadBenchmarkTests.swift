//
//  HookOverheadBenchmarkTests.swift
//  LuaSwiftTests
//
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Pins the runtime cost of LuaSwift's compositor hook on the VM hot path:
//  the always-on COUNT hook (cancellation + instruction-limit accounting,
//  including the per-fire `currentEngine` TLS lookup) and the additional
//  LINE/CALL/RET dispatch armed by `runDebug` / a host-resumed coroutine
//  during a debug session.
//
//  These are XCTest `measure` benchmarks: they record wall-clock timings and
//  never fail (no performance baseline is set), so they are report-only and
//  safe to run unconditionally in CI across the Lua-version / dependency
//  matrix. Compare the paired numbers to read the overhead:
//
//    testBaseline_plainRun_countHookOnly   ← COUNT hook only
//    testDebug_runDebug_fullMaskDispatch   ← + LINE/CALL/RET dispatch (no-op handler)
//
//  The delta between the two is the debug-dispatch overhead; the absolute
//  baseline figure is the COUNT-hook + TLS-lookup cost on the hot path
//  (the subject of the deferred TLS-optimization note, kept as-is at <0.1%).
//
//  Run: `swift test --filter HookOverheadBenchmarkTests`
//

import XCTest
@testable import LuaSwift

final class HookOverheadBenchmarkTests: XCTestCase {

    /// A compute-bound Lua workload with no I/O or allocation, chosen so the
    /// measured time is dominated by VM instruction execution (and therefore by
    /// per-instruction hook overhead) rather than by setup. Returns a value so
    /// nothing is dead-code-eliminated.
    private static let workload = """
        local s = 0
        for i = 1, 100000 do
            s = s + i * 2 - 1
        end
        return s
        """

    /// A much shorter loop for the debug-path benchmarks. Under the full
    /// LINE/CALL/RET mask the Swift handler is invoked on *every* executed line,
    /// so the per-iteration cost is ~hundreds of times the COUNT-only path; a
    /// 2,000-iteration loop already yields a stable measure in ~1s instead of the
    /// ~50s a 100k loop would take, keeping the suite fast.
    private static let debugWorkload = """
        local s = 0
        for i = 1, 2000 do
            s = s + i * 2 - 1
        end
        return s
        """

    private func makeEngine() throws -> LuaEngine {
        try LuaEngine()
    }

    // MARK: - Baseline: COUNT hook only (plain run)

    /// Plain `run` arms only `LUA_MASKCOUNT` (cancellation + instruction-limit
    /// accounting). This is the always-on hot-path cost, including the
    /// `currentEngine` TLS lookup performed on every COUNT fire.
    func testBaseline_plainRun_countHookOnly() throws {
        let engine = try makeEngine()
        let code = Self.workload
        measure {
            for _ in 0..<20 {
                _ = try? engine.run(code)
            }
        }
    }

    /// `evaluate` variant (nresults = 1) — same COUNT-only hook, returns the sum.
    func testBaseline_plainEvaluate_countHookOnly() throws {
        let engine = try makeEngine()
        let code = Self.workload
        measure {
            for _ in 0..<20 {
                _ = try? engine.evaluate(code)
            }
        }
    }

    // MARK: - Debug: full LINE/CALL/RET mask dispatch

    /// `runDebug` with a no-op `.continueRun` handler arms the full
    /// `COUNT|LINE|CALL|RET` mask. The delta versus the baseline above is the
    /// debug-event dispatch overhead (the LINE filter + handler call per line).
    func testDebug_runDebug_fullMaskDispatch() throws {
        let engine = try makeEngine()
        engine.setDebugHandler { _, _ in .continueRun }
        let code = Self.debugWorkload
        measure {
            for _ in 0..<20 {
                _ = try? engine.runDebug(code)
            }
        }
    }

    /// Host-resumed coroutine under a debug session — the coroutine thread is
    /// armed with the full mask (#26). Pins the coroutine debug-dispatch cost.
    func testDebug_hostResumedCoroutine_fullMaskDispatch() throws {
        let engine = try makeEngine()
        engine.setDebugHandler { _, _ in .continueRun }
        let code = Self.debugWorkload
        measure {
            for _ in 0..<20 {
                if let handle = try? engine.createCoroutine(code: code) {
                    _ = try? engine.resume(handle)
                    engine.destroy(handle)
                }
            }
        }
    }

    // MARK: - Cancellation-armed (COUNT hook with a live instruction limit)

    /// Same workload with a high instruction limit set, so the COUNT hook also
    /// performs the accumulate-and-compare on every fire. Pins the cost of the
    /// cancellation/limit accounting path specifically.
    func testCancellation_instructionLimitArmed() throws {
        let engine = try makeEngine()
        engine.setInstructionLimit(10_000_000)  // high enough never to trip
        let code = Self.workload
        measure {
            for _ in 0..<20 {
                _ = try? engine.run(code)
                engine.resetCancellation()
            }
        }
    }
}
