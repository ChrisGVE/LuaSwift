//
//  CooperativeCancellationOptOutTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-10.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Tests/LuaSwiftTests/CooperativeCancellationOptOutTests.swift
//
//  Context: Acceptance tests for the cooperativeCancellation opt-out (#30).
//  The periodic COUNT compositor hook (LuaEngine+CompositorHook.swift) is
//  armed by armCompositorHook (LuaEngine+Execution.swift) at every run entry
//  point. Before #30 it was armed unconditionally — even with no instruction
//  limit and no cancellation in use — costing ~2x throughput on
//  instruction-heavy runs. LuaEngineConfiguration.cooperativeCancellation
//  (default true) lets a consumer that needs neither a CPU limit nor
//  cancellation skip the hook. These tests pin the arming matrix:
//
//    cooperativeCancellation | instructionLimit | hook armed?
//    ------------------------|------------------|------------
//    true  (default)         | 0                | yes  (armedHookCount == hookInterval)
//    false                   | 0                | NO   (armedHookCount == 0)
//    false                   | > 0              | yes  (the limit needs the hook)
//
//  Arming is observed directly via the internal armedHookCount (set inside
//  armCompositorHook) and behaviorally: when the hook is not armed, a
//  pending requestCancellation() cannot interrupt a finite heavy loop, and a
//  live instruction limit still trips when the hook IS armed.
//

import XCTest
@testable import LuaSwift

final class CooperativeCancellationOptOutTests: XCTestCase {

    /// A finite, compute-bound loop long enough that, were the COUNT hook armed
    /// (fires every hookInterval == 10 000 instructions), a pending cancellation
    /// would trip on the first fire — far before this completes. Returns the sum
    /// so the run's success is observable.
    private static let heavyFiniteLoop = """
        local s = 0
        for i = 1, 2000000 do
            s = s + i
        end
        return s
        """

    // MARK: - Default: hook armed when no limit (preserves pre-#30 behavior)

    /// A default engine (cooperativeCancellation == true) with no instruction
    /// limit still arms the COUNT hook so requestCancellation() keeps working.
    func testHookArmedByDefaultWithNoLimit() throws {
        let engine = try LuaEngine(configuration: .unrestricted)
        XCTAssertTrue(engine.configuration.cooperativeCancellation,
                      "Pre-condition: cooperativeCancellation defaults to true")
        XCTAssertEqual(engine.instructionLimit, 0, "Pre-condition: no instruction limit")

        _ = try engine.evaluate("return 1 + 1")

        XCTAssertEqual(engine.armedHookCount, engine.hookInterval,
                       "Default no-limit run must arm the COUNT hook at hookInterval")
    }

    // MARK: - Opt-out: hook NOT armed when off AND no limit (#30 fix)

    /// With cooperativeCancellation == false and no instruction limit, the COUNT
    /// hook is not armed — armedHookCount stays 0 after a completed run.
    func testHookNotArmedWhenOptedOutAndNoLimit() throws {
        let config = LuaEngineConfiguration(sandboxed: false, cooperativeCancellation: false)
        let engine = try LuaEngine(configuration: config)

        let result = try engine.evaluate("return 21 * 2")

        XCTAssertEqual(result.intValue, 42, "Run must still execute and return its result")
        XCTAssertEqual(engine.armedHookCount, 0,
                       "Opt-out + no-limit run must NOT arm the COUNT hook")
    }

    /// Behavioral proof: with the hook not armed, a cancellation requested before
    /// the run cannot interrupt a finite heavy loop — it runs to completion and
    /// returns the correct sum rather than throwing .cancelled.
    func testPendingCancellationIgnoredWhenOptedOutAndNoLimit() throws {
        let config = LuaEngineConfiguration(sandboxed: false, cooperativeCancellation: false)
        let engine = try LuaEngine(configuration: config)

        // Flag is set before the run and is NOT auto-cleared on run entry; with
        // the hook armed this would trip on the first fire. With the hook off it
        // is never read.
        engine.requestCancellation()

        let result = try engine.evaluate(Self.heavyFiniteLoop)

        // sum_{i=1}^{2000000} i = 2000000 * 2000001 / 2 = 2000001000000
        XCTAssertEqual(result.numberValue, 2_000_001_000_000,
                       "Opted-out engine must complete the loop, not honor the pending cancellation")
    }

    // MARK: - Opt-out does not disable an instruction limit

    /// cooperativeCancellation == false must NOT suppress the hook when an
    /// instruction limit is set: the limit needs the hook to fire. The hook is
    /// armed and the limit still trips.
    func testInstructionLimitStillEnforcedWhenOptedOut() throws {
        let config = LuaEngineConfiguration(sandboxed: false, cooperativeCancellation: false)
        let engine = try LuaEngine(configuration: config)
        engine.setInstructionLimit(50_000)

        var thrown: LuaError?
        do {
            try engine.run("while true do end")
            XCTFail("Expected LuaError.instructionLimitExceeded")
        } catch let e as LuaError {
            thrown = e
        }

        XCTAssertGreaterThan(engine.armedHookCount, 0,
                             "A live instruction limit must arm the hook even when opted out")
        guard let err = thrown, case .instructionLimitExceeded = err else {
            XCTFail("Expected .instructionLimitExceeded, got \(String(describing: thrown))")
            return
        }
    }

    /// And cancellation itself still works under opt-out when a limit is set,
    /// because the armed hook's first action is the cancellation check.
    func testCancellationStillWorksWhenOptedOutButLimitSet() throws {
        let config = LuaEngineConfiguration(sandboxed: false, cooperativeCancellation: false)
        let engine = try LuaEngine(configuration: config)
        engine.setInstructionLimit(100_000_000)  // high enough to not trip first

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
            engine.requestCancellation()
        }

        var thrown: LuaError?
        do {
            try engine.run("while true do end")
            XCTFail("Expected LuaError.cancelled")
        } catch let e as LuaError {
            thrown = e
        }
        guard let err = thrown, case .cancelled = err else {
            XCTFail("Expected .cancelled, got \(String(describing: thrown))")
            return
        }
    }

    // MARK: - Built-in configurations preserve cancellation by default

    /// The shipped configurations keep cooperativeCancellation == true so the
    /// default and unrestricted engines behave exactly as before #30.
    func testBuiltInConfigsDefaultToCooperativeCancellationOn() {
        XCTAssertTrue(LuaEngineConfiguration.default.cooperativeCancellation,
                      ".default must keep cooperativeCancellation == true")
        XCTAssertTrue(LuaEngineConfiguration.unrestricted.cooperativeCancellation,
                      ".unrestricted must keep cooperativeCancellation == true")
        XCTAssertTrue(LuaEngineConfiguration().cooperativeCancellation,
                      "The memberwise default must be true")
    }
}
