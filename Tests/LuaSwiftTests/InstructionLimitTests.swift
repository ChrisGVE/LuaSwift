//
//  InstructionLimitTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-05-29.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

/// Tests for the instruction-count limit API that prevents runaway Lua code.
final class InstructionLimitTests: XCTestCase {

    // MARK: - Infinite Loop Interrupted

    /// Verifies that an infinite loop is interrupted and throws .instructionLimitExceeded.
    func testEvaluateInfiniteLoopThrowsWithLimit() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)

        XCTAssertThrowsError(try engine.evaluate("while true do end")) { error in
            guard let luaError = error as? LuaError else {
                XCTFail("Expected LuaError, got \(type(of: error))")
                return
            }
            if case .instructionLimitExceeded = luaError {
                // expected
            } else {
                XCTFail("Expected .instructionLimitExceeded, got \(luaError)")
            }
        }
    }

    // MARK: - Normal Code Unaffected

    /// Verifies that short code completes normally when limit is not tripped.
    func testEvaluateNormalCodeWithHighLimit() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(100_000)

        let result = try engine.evaluate("return 1 + 2")
        XCTAssertEqual(result.numberValue, 3)
    }

    // MARK: - Limit Zero Disables Hook

    /// Verifies that limit 0 disables the hook and normal code still runs.
    func testLimitZeroDisablesHook() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(0)

        // Normal code should run fine
        let result = try engine.evaluate("return 7 * 6")
        XCTAssertEqual(result.numberValue, 42)
    }

    // MARK: - Hook Re-Arms Across Calls

    /// Verifies that the hook re-arms: after a tripped call, subsequent calls still work.
    func testHookRearmsAfterTrip() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)

        // First call: infinite loop trips the limit
        XCTAssertThrowsError(try engine.evaluate("while true do end")) { error in
            guard let luaError = error as? LuaError,
                  case .instructionLimitExceeded = luaError else {
                XCTFail("Expected .instructionLimitExceeded, got \(error)")
                return
            }
        }

        // Second call: normal code completes (proves engine is still usable)
        let result = try engine.evaluate("return 2 + 2")
        XCTAssertEqual(result.numberValue, 4)

        // Third call: another infinite loop also trips (proves re-arm, not one-shot)
        XCTAssertThrowsError(try engine.evaluate("while true do end")) { error in
            guard let luaError = error as? LuaError,
                  case .instructionLimitExceeded = luaError else {
                XCTFail("Expected .instructionLimitExceeded on second infinite loop, got \(error)")
                return
            }
        }
    }

    // MARK: - run() Path

    /// Verifies that run() (no return value) also respects the instruction limit.
    func testRunInfiniteLoopThrowsWithLimit() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)

        XCTAssertThrowsError(try engine.run("while true do end")) { error in
            guard let luaError = error as? LuaError else {
                XCTFail("Expected LuaError, got \(type(of: error))")
                return
            }
            if case .instructionLimitExceeded = luaError {
                // expected
            } else {
                XCTFail("Expected .instructionLimitExceeded, got \(luaError)")
            }
        }
    }
}
