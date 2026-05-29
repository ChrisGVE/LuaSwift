//
//  BytecodeTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-05-29.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

/// Tests for the bytecode compile/load API: compile(_:), runBytecode(_:), evaluateBytecode(_:).
final class BytecodeTests: XCTestCase {

    // MARK: - Round-trip

    /// compile("return 1 + 2") → evaluateBytecode → returns 3.
    func testRoundTripReturnsCorrectValue() throws {
        let engine = try LuaEngine()
        let bytecode = try engine.compile("return 1 + 2")
        let result = try engine.evaluateBytecode(bytecode)
        XCTAssertEqual(result.numberValue, 3)
    }

    // MARK: - Source vs bytecode parity

    /// evaluate("return 6 * 7") == evaluateBytecode(compile("return 6 * 7")).
    func testSourceAndBytecodeParity() throws {
        let engine = try LuaEngine()
        let sourceResult = try engine.evaluate("return 6 * 7")
        let bytecode = try engine.compile("return 6 * 7")
        let bytecodeResult = try engine.evaluateBytecode(bytecode)
        XCTAssertEqual(sourceResult.numberValue, bytecodeResult.numberValue)
    }

    // MARK: - Side effects persist

    /// runBytecode(compile("x = 10")) then evaluate("return x") == 10.
    func testSideEffectsPeristOnSameEngine() throws {
        let engine = try LuaEngine()
        let bytecode = try engine.compile("x = 10")
        try engine.runBytecode(bytecode)
        let result = try engine.evaluate("return x")
        XCTAssertEqual(result.numberValue, 10)
    }

    // MARK: - Corrupt bytecode throws

    /// evaluateBytecode with bad bytes throws a LuaError.
    func testCorruptBytecodeThrows() throws {
        let engine = try LuaEngine()
        // Lua binary header starts with 0x1b 0x4c 0x75 ("Esc L u"). Feeding garbage
        // or a truncated/invalid header triggers a syntax / load error.
        let garbage = Data([0x1b, 0x4c, 0x00, 0xff, 0xde, 0xad, 0xbe, 0xef])
        XCTAssertThrowsError(try engine.evaluateBytecode(garbage)) { error in
            guard let luaError = error as? LuaError else {
                XCTFail("Expected LuaError, got \(type(of: error))")
                return
            }
            // loadbuffer with mode "b" on invalid data should surface as syntaxError
            if case .syntaxError = luaError {
                // expected
            } else {
                XCTFail("Expected .syntaxError for corrupt bytecode, got \(luaError)")
            }
        }
    }

    // MARK: - Invalid source throws syntaxError

    /// compile("this is not lua ===") throws .syntaxError.
    func testCompileInvalidSourceThrowsSyntaxError() throws {
        let engine = try LuaEngine()
        XCTAssertThrowsError(try engine.compile("this is not lua ===")) { error in
            guard let luaError = error as? LuaError else {
                XCTFail("Expected LuaError, got \(type(of: error))")
                return
            }
            if case .syntaxError = luaError {
                // expected
            } else {
                XCTFail("Expected .syntaxError, got \(luaError)")
            }
        }
    }

    // MARK: - Instruction limit on bytecode path

    /// setInstructionLimit(1000) + runBytecode(compile("while true do end")) throws .instructionLimitExceeded.
    func testInstructionLimitAppliesOnBytecodePath() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)
        let bytecode = try engine.compile("while true do end")
        XCTAssertThrowsError(try engine.runBytecode(bytecode)) { error in
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

    // MARK: - Value types round-trip

    /// A string return value survives compile → evaluateBytecode.
    func testStringValueRoundTrip() throws {
        let engine = try LuaEngine()
        let bytecode = try engine.compile("return \"hello bytecode\"")
        let result = try engine.evaluateBytecode(bytecode)
        XCTAssertEqual(result.stringValue, "hello bytecode")
    }
}
