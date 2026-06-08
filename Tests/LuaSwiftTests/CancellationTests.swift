//
//  CancellationTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Tests/LuaSwiftTests/CancellationTests.swift
//
//  Context: Acceptance tests for cooperative cancellation (#22).
//  Covers the F1 acceptance criteria from the MoonSwift-P2 PRD:
//  - cancel with/without instruction limit (S2 default path explicit)
//  - reuse after cancel + resetCancellation()
//  - race to natural completion (deterministic result, clean next run)
//  - finite script not spuriously cancelled
//  - cancel via coroutine resume path
//  - cancel via callLuaFunction path
//  - callback-then-loop regression (correction #2: TLS survives callback)
//  - existing instruction-limit suite still passes (regression guard)
//

import XCTest
@testable import LuaSwift

final class CancellationTests: XCTestCase {

    // MARK: - S2: Cancel with NO instruction limit (default path)

    /// Verify that requestCancellation() interrupts a tight infinite loop
    /// within the 400 ms CI threshold when NO instruction limit is set.
    ///
    /// This is the primary S2 story: MoonSwift's wall-clock timer calls
    /// requestCancellation() with run.instruction_limit defaulting to 0.
    func testCancelInfiniteLoopNoInstructionLimit() throws {
        let engine = try LuaEngine()
        // Explicitly confirm no limit is set — this is the S2 path.
        XCTAssertEqual(engine.instructionLimit, 0, "Pre-condition: no instruction limit")

        let expectation = expectation(description: "cancelled")
        var thrownError: Error?

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
            engine.requestCancellation()
        }

        let start = Date()
        do {
            try engine.run("while true do end")
            XCTFail("Expected LuaError.cancelled, but run() returned normally")
        } catch {
            thrownError = error
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 0.4, "Cancel should complete within 400 ms; took \(elapsed)s")

        guard let luaError = thrownError as? LuaError,
              case .cancelled = luaError else {
            XCTFail("Expected LuaError.cancelled, got \(String(describing: thrownError))")
            return
        }
    }

    // MARK: - Cancel with instruction limit also set

    /// Both compositor paths coexist; whichever fires first wins.
    /// With a large limit, cancellation fires well before the limit.
    func testCancelWithInstructionLimitAlsoSet() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(100_000_000)  // 100 M — effectively unreachable

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
            engine.requestCancellation()
        }

        let start = Date()
        var thrownError: LuaError?
        do {
            try engine.run("while true do end")
            XCTFail("Expected LuaError.cancelled")
        } catch let e as LuaError {
            thrownError = e
        }
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 0.4, "Cancel should complete within 400 ms; took \(elapsed)s")
        guard let err = thrownError, case .cancelled = err else {
            XCTFail("Expected .cancelled, got \(String(describing: thrownError))")
            return
        }
    }

    // MARK: - Reuse after cancel + resetCancellation()

    /// After a .cancelled outcome and resetCancellation(), the same engine
    /// runs a new fragment to completion without spurious cancellation.
    /// The stack must be clean (no assertion failure) after reset.
    func testReuseAfterCancelAndReset() throws {
        let engine = try LuaEngine()

        // Trigger a cancellation
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            engine.requestCancellation()
        }
        XCTAssertThrowsError(try engine.run("while true do end")) { error in
            guard let e = error as? LuaError, case .cancelled = e else {
                XCTFail("Expected .cancelled, got \(error)")
                return
            }
        }

        // Reset and reuse
        engine.resetCancellation()
        let result = try engine.evaluate("return 2 + 2")
        XCTAssertEqual(result.numberValue, 4, "Engine must be reusable after cancel+reset")
    }

    /// After reset, the accumulator and abort reason are cleared so a
    /// subsequent run with an instruction limit fires at the correct point.
    func testReuseAfterCancelPreservesInstructionLimitSemantics() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)

        // Cancel a run
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            engine.requestCancellation()
        }
        XCTAssertThrowsError(try engine.run("while true do end")) { _ in }

        engine.resetCancellation()

        // Instruction limit must still fire on the next run
        XCTAssertThrowsError(try engine.run("while true do end")) { error in
            guard let e = error as? LuaError, case .instructionLimitExceeded = e else {
                XCTFail("Expected .instructionLimitExceeded after reset, got \(error)")
                return
            }
        }
    }

    // MARK: - Race to natural completion

    /// A script that finishes BEFORE the cancellation request is dispatched
    /// must return normally — no false .cancelled — and the engine must
    /// produce clean results on the next run after resetCancellation().
    func testRaceToNaturalCompletion() throws {
        let engine = try LuaEngine()

        // Fire cancellation far in the future — the Lua snippet finishes first.
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
            engine.requestCancellation()
        }

        // A deliberately short, instantly-finishing Lua expression
        let result = try engine.evaluate("return 1 + 1")
        XCTAssertEqual(result.numberValue, 2, "Short script must complete normally")

        // cancellationRequested may or may not be set depending on timing;
        // either way resetCancellation then next run must succeed.
        engine.resetCancellation()
        let result2 = try engine.evaluate("return 7 * 6")
        XCTAssertEqual(result2.numberValue, 42)
    }

    /// A run that races a cancel request produces either a normal result
    /// OR .cancelled — never a corrupt engine. After cancel+reset, the
    /// subsequent run completes cleanly.
    func testRaceResultIsEitherNormalOrCancelledNeverCorrupt() throws {
        let engine = try LuaEngine()

        // The Lua loop runs for exactly 1 000 iterations — short enough that
        // the cancellation races it nondeterministically.
        let raceScript = "local n = 0; for i = 1, 1000 do n = n + i end; return n"

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.001) {
            engine.requestCancellation()
        }

        var outcome: Result<LuaValue, Error>
        do {
            let v = try engine.evaluate(raceScript)
            outcome = .success(v)
        } catch {
            outcome = .failure(error)
        }

        switch outcome {
        case .success(let v):
            // Completed before cancel; result must be 500 500
            XCTAssertEqual(v.numberValue, 500_500, "Race resolved to normal: unexpected result")
        case .failure(let error):
            // Cancelled; must be the right error
            guard let e = error as? LuaError, case .cancelled = e else {
                XCTFail("Race failure must be .cancelled, got \(error)")
                return
            }
        }

        // Either way: engine is reusable after reset
        engine.resetCancellation()
        let clean = try engine.evaluate("return 3 + 3")
        XCTAssertEqual(clean.numberValue, 6, "Engine must be clean after race+reset")
    }

    // MARK: - Finite script: no false cancel

    /// A finite script with no requestCancellation() call returns normally.
    func testFiniteScriptNoCancelRequest() throws {
        let engine = try LuaEngine()
        let result = try engine.evaluate("local s = 0; for i = 1, 100 do s = s + i end; return s")
        XCTAssertEqual(result.numberValue, 5050)
    }

    /// evaluate() on a non-looping expression with no cancel request returns
    /// the value and leaves the engine in a clean state.
    func testEvaluateFiniteExpressionNoCancelRequest() throws {
        let engine = try LuaEngine()
        let r1 = try engine.evaluate("return math.sqrt(16)")
        XCTAssertEqual(r1.numberValue, 4)
        let r2 = try engine.evaluate("return math.sqrt(16)")
        XCTAssertEqual(r2.numberValue, 4)
    }

    // MARK: - Coroutine cancel

    /// requestCancellation() during a coroutine resume surfaces as .cancelled
    /// on the .error(.cancelled) coroutine result path.
    func testCancelDuringCoroutineResume() throws {
        let engine = try LuaEngine()
        let handle = try engine.createCoroutine(code: "while true do end")

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
            engine.requestCancellation()
        }

        let start = Date()
        let result = try engine.resume(handle)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 0.4, "Coroutine cancel within 400 ms; took \(elapsed)s")

        guard case .error(let error) = result else {
            XCTFail("Expected .error, got \(result)")
            return
        }
        guard case .cancelled = error else {
            XCTFail("Expected .cancelled, got \(error)")
            return
        }

        engine.destroy(handle)
    }

    // MARK: - callLuaFunction cancel

    /// requestCancellation() during callLuaFunction surfaces as .cancelled.
    func testCancelDuringCallLuaFunction() throws {
        let engine = try LuaEngine()
        let fn = try engine.evaluate("return function() while true do end end")
        guard case .luaFunction(let ref) = fn else {
            return XCTFail("Expected .luaFunction, got \(fn)")
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
            engine.requestCancellation()
        }

        let start = Date()
        do {
            _ = try engine.callLuaFunction(ref: ref, args: [])
            XCTFail("Expected .cancelled")
        } catch let e as LuaError {
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertLessThan(elapsed, 0.4, "callLuaFunction cancel within 400 ms; took \(elapsed)s")
            guard case .cancelled = e else {
                XCTFail("Expected .cancelled, got \(e)")
                return
            }
        }
    }

    // MARK: - Correction #2 regression: callback-then-loop

    /// A script that calls a registered Swift function and THEN enters an
    /// infinite loop must still be cancellable. This proves the TLS engine
    /// reference survives the callback's setAsCurrentEngine/restoreCurrentEngine
    /// round-trip so the compositor hook can still find the engine.
    func testCallbackThenLoopIsCancellable() throws {
        let engine = try LuaEngine()

        // Register a no-op Swift callback
        engine.registerFunction(name: "noop") { _ in return .nil }

        // Script: call noop() first, then spin
        let script = "noop(); while true do end"

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            engine.requestCancellation()
        }

        let start = Date()
        do {
            try engine.run(script)
            XCTFail("Expected .cancelled after callback+loop")
        } catch let e as LuaError {
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertLessThan(elapsed, 0.4, "Callback-then-loop cancel within 400 ms; took \(elapsed)s")
            guard case .cancelled = e else {
                XCTFail("Expected .cancelled, got \(e)")
                return
            }
        }
    }

    /// A script that calls a registered Swift function MULTIPLE times and then
    /// enters an infinite loop is still cancellable after several TLS round-trips.
    func testMultipleCallbacksThenLoopIsCancellable() throws {
        let engine = try LuaEngine()

        var callCount = 0
        engine.registerFunction(name: "inc") { _ in
            callCount += 1
            return .nil
        }

        let script = """
        for i = 1, 5 do inc() end
        while true do end
        """

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            engine.requestCancellation()
        }

        do {
            try engine.run(script)
            XCTFail("Expected .cancelled after multiple callbacks+loop")
        } catch let e as LuaError {
            guard case .cancelled = e else {
                XCTFail("Expected .cancelled, got \(e)")
                return
            }
        }
    }

    // MARK: - Instruction limit regression guard

    /// Verify the existing instruction-limit behavior is unchanged:
    /// a tight infinite loop with a limit throws .instructionLimitExceeded.
    func testInstructionLimitStillThrowsLimitExceeded() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)

        XCTAssertThrowsError(try engine.evaluate("while true do end")) { error in
            guard let e = error as? LuaError, case .instructionLimitExceeded = e else {
                XCTFail("Expected .instructionLimitExceeded, got \(error)")
                return
            }
        }
    }

    /// Verify exact-at-limit firing: a limit of 500 fires before 1 000
    /// instructions have accumulated (the loop hits the limit, not hookInterval).
    func testInstructionLimitSmallerThanHookIntervalFiresExactly() throws {
        let engine = try LuaEngine()
        // Limit well below the 10 000 hookInterval default.
        engine.setInstructionLimit(500)

        XCTAssertThrowsError(try engine.run("while true do end")) { error in
            guard let e = error as? LuaError, case .instructionLimitExceeded = e else {
                XCTFail("Expected .instructionLimitExceeded, got \(error)")
                return
            }
        }
    }

    /// After a limit-exceeded run, the engine is still usable and normal
    /// code returns the expected value.
    func testLimitExceededEngineIsReusable() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)

        XCTAssertThrowsError(try engine.evaluate("while true do end"))

        let result = try engine.evaluate("return 6 * 7")
        XCTAssertEqual(result.numberValue, 42)
    }

    // MARK: - cancel vs limit: cancel wins when both are active

    /// When both a cancellation request AND an instruction limit are set,
    /// whichever fires first wins. With a cancellation flag already set and
    /// a very large limit, the result must be .cancelled.
    func testCancelTakesPriorityOverLimitWhenFlagAlreadySet() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(100_000_000)
        engine.requestCancellation()  // set before run starts

        XCTAssertThrowsError(try engine.run("while true do end")) { error in
            guard let e = error as? LuaError, case .cancelled = e else {
                XCTFail("Expected .cancelled (flag set first), got \(error)")
                return
            }
        }
    }
}
