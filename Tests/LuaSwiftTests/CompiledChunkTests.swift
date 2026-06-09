//
//  CompiledChunkTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Tests/LuaSwiftTests/CompiledChunkTests.swift
//
//  Context: Tests for the provenance-typed bytecode API (issue #9):
//  CompiledChunk (Sources/LuaSwift/CompiledChunk.swift) and the
//  precompile(_:)/run(_:)/evaluate(_:) chunk overloads on LuaEngine.
//  The deprecated raw-Data API keeps its own coverage in BytecodeTests.swift.
//

import XCTest
@testable import LuaSwift

/// Tests for precompile(_:) → CompiledChunk → run(_:)/evaluate(_:), including
/// Codable persistence and rejection of tampered provenance metadata.
final class CompiledChunkTests: XCTestCase {

    /// Encode `chunk` to JSON, let `mutate` tamper with the top-level JSON
    /// object, and decode the result back into a CompiledChunk — simulating
    /// a persisted cache file modified on disk.
    private func reencode(
        _ chunk: CompiledChunk,
        mutating mutate: (inout [String: Any]) -> Void
    ) throws -> CompiledChunk {
        let encoded = try JSONEncoder().encode(chunk)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        mutate(&object)
        let tampered = try JSONSerialization.data(withJSONObject: object)
        return try JSONDecoder().decode(CompiledChunk.self, from: tampered)
    }

    // MARK: - Round-trip

    /// precompile("x = 10") → run(chunk) → the side effect is visible.
    func testRunChunkAppliesSideEffects() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("x = 10")
        try engine.run(chunk)
        let result = try engine.evaluate("return x")
        XCTAssertEqual(result.numberValue, 10)
    }

    /// precompile("return 1 + 2") → evaluate(chunk) → returns 3.
    func testEvaluateChunkReturnsValue() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1 + 2")
        let result = try engine.evaluate(chunk)
        XCTAssertEqual(result.numberValue, 3)
    }

    /// evaluate(source) == evaluate(precompile(source)).
    func testEvaluateChunkMatchesEvaluateSource() throws {
        let engine = try LuaEngine()
        let sourceResult = try engine.evaluate("return 6 * 7")
        let chunk = try engine.precompile("return 6 * 7")
        let chunkResult = try engine.evaluate(chunk)
        XCTAssertEqual(sourceResult.numberValue, chunkResult.numberValue)
    }

    /// Invalid source surfaces as .syntaxError from precompile.
    func testPrecompileInvalidSourceThrowsSyntaxError() throws {
        let engine = try LuaEngine()
        XCTAssertThrowsError(try engine.precompile("this is not lua ===")) { error in
            guard case .syntaxError = error as? LuaError else {
                XCTFail("Expected .syntaxError, got \(error)")
                return
            }
        }
    }

    // MARK: - Codable persistence

    /// JSONEncoder/JSONDecoder round-trip preserves the chunk and it still
    /// evaluates afterwards (the persisted-cache use case).
    func testCodableRoundTripStillEvaluates() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return \"hello chunk\"")
        let encoded = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(CompiledChunk.self, from: encoded)
        XCTAssertEqual(decoded, chunk)
        let result = try engine.evaluate(decoded)
        XCTAssertEqual(result.stringValue, "hello chunk")
    }

    // MARK: - Provenance mismatch rejection

    /// A chunk whose stamped Lua version differs from the running engine is
    /// rejected with a runtimeError naming both versions. The foreign version
    /// is derived relative to the running build, so this passes on every
    /// LUASWIFT_LUA_VERSION.
    func testMismatchedLuaVersionIsRejected() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        let engineVersion = CompiledChunk.currentLuaVersion
        let foreignVersion = engineVersion == "5.1" ? "5.4" : "5.1"
        let tampered = try reencode(chunk) { $0["luaVersion"] = foreignVersion }
        XCTAssertThrowsError(try engine.run(tampered)) { error in
            guard case .runtimeError(let message)? = error as? LuaError else {
                XCTFail("Expected .runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains(foreignVersion),
                          "Message should name the chunk's version: \(message)")
            XCTAssertTrue(message.contains(engineVersion),
                          "Message should name the engine's version: \(message)")
        }
    }

    /// Representative word-size/byte-order check: a chunk stamped with the
    /// opposite endianness is rejected before the loader sees it.
    func testMismatchedEndiannessIsRejected() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        let foreign = CompiledChunk.currentEndianness == "little" ? "big" : "little"
        let tampered = try reencode(chunk) { $0["endianness"] = foreign }
        XCTAssertThrowsError(try engine.evaluate(tampered)) { error in
            guard case .runtimeError(let message)? = error as? LuaError else {
                XCTFail("Expected .runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains(foreign),
                          "Message should name the mismatch: \(message)")
        }
    }

    /// A chunk encoded by a newer format version than this build understands
    /// is rejected instead of being misinterpreted.
    func testNewerFormatVersionIsRejected() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        let tampered = try reencode(chunk) { $0["formatVersion"] = 999 }
        XCTAssertThrowsError(try engine.run(tampered)) { error in
            guard case .runtimeError(let message)? = error as? LuaError else {
                XCTFail("Expected .runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("format version"),
                          "Message should name the format mismatch: \(message)")
        }
    }

    /// A chunk whose `bytecode` is plain Lua source text — not a dumped binary
    /// chunk — must be rejected before the loader sees it, even when the
    /// provenance metadata is otherwise valid. Without the binary-signature
    /// gate this executes as source on the Lua 5.1 load path (which uses
    /// `luaL_loadbuffer`, accepting text), so this is the teeth of the 5.1 fix.
    func testTextChunkDisguisedAsBytecodeIsRejected() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        // Swap the dumped bytecode for plain Lua source while leaving the
        // provenance stamp (luaVersion/sizes/endianness) untouched.
        let source = Data("return os.time()".utf8)
        let tampered = try reencode(chunk) {
            $0["bytecode"] = source.base64EncodedString()
        }
        XCTAssertThrowsError(try engine.run(tampered)) { error in
            guard case .syntaxError? = error as? LuaError else {
                XCTFail("Expected .syntaxError, got \(error)")
                return
            }
        }
        XCTAssertThrowsError(try engine.evaluate(tampered)) { error in
            guard case .syntaxError? = error as? LuaError else {
                XCTFail("Expected .syntaxError, got \(error)")
                return
            }
        }
    }

    /// A chunk whose `formatVersion` decodes as 0 (a value no real format ever
    /// used — producible by a truncated or tampered cache) is rejected with a
    /// runtimeError naming the version, not silently accepted.
    func testZeroFormatVersionIsRejected() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        let tampered = try reencode(chunk) { $0["formatVersion"] = 0 }
        XCTAssertThrowsError(try engine.run(tampered)) { error in
            guard case .runtimeError(let message)? = error as? LuaError else {
                XCTFail("Expected .runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("0"),
                          "Message should name the version: \(message)")
        }
    }

    /// A chunk whose `formatVersion` decodes as a negative number is rejected
    /// with a runtimeError naming the version.
    func testNegativeFormatVersionIsRejected() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        let tampered = try reencode(chunk) { $0["formatVersion"] = -1 }
        XCTAssertThrowsError(try engine.evaluate(tampered)) { error in
            guard case .runtimeError(let message)? = error as? LuaError else {
                XCTFail("Expected .runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("-1"),
                          "Message should name the version: \(message)")
        }
    }

    // MARK: - Tampered bytecode inside a valid envelope

    /// Corrupting the bytecode bytes while keeping the metadata valid must
    /// fail cleanly with a LuaError (the loader's header check), not crash.
    func testTamperedBytecodeFailsWithLuaError() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        // Garbage with a mangled binary header: passes provenance (metadata
        // untouched), but the loader's header check must reject it.
        let garbage = Data([0x1b, 0x4c, 0x00, 0xff, 0xde, 0xad, 0xbe, 0xef])
        let tampered = try reencode(chunk) {
            $0["bytecode"] = garbage.base64EncodedString()
        }
        XCTAssertThrowsError(try engine.evaluate(tampered)) { error in
            XCTAssertNotNil(error as? LuaError,
                            "Expected LuaError, got \(type(of: error))")
        }
    }

    // MARK: - Instruction limit on the chunk path

    /// setInstructionLimit(1000) + run(precompile("while true do end"))
    /// throws .instructionLimitExceeded — mirrors the deprecated-path test.
    func testInstructionLimitAppliesOnChunkPath() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)
        let chunk = try engine.precompile("while true do end")
        XCTAssertThrowsError(try engine.run(chunk)) { error in
            guard case .instructionLimitExceeded? = error as? LuaError else {
                XCTFail("Expected .instructionLimitExceeded, got \(error)")
                return
            }
        }
    }

    // MARK: - Integer / number size mismatch (CR-022)

    /// A chunk whose `integerSize` differs from the current build must be
    /// rejected before the Lua loader sees it, with a descriptive runtimeError
    /// naming the mismatched sizes. 4 bytes is a plausible "other" size for
    /// any build where the native size is 8 bytes, and vice-versa — at least
    /// one of 4 or 8 is guaranteed to differ from the real current size.
    func testMismatchedIntegerSizeIsRejected() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        let currentSize = CompiledChunk.currentIntegerSize
        let foreignSize = currentSize == 8 ? 4 : 8
        let tampered = try reencode(chunk) { $0["integerSize"] = foreignSize }
        XCTAssertThrowsError(try engine.run(tampered)) { error in
            guard case .runtimeError(let message)? = error as? LuaError else {
                XCTFail("Expected .runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("\(foreignSize)"),
                          "Message should name the chunk's integer size: \(message)")
            XCTAssertTrue(message.contains("\(currentSize)"),
                          "Message should name the engine's integer size: \(message)")
        }
    }

    /// A chunk whose `numberSize` differs from the current build must be
    /// rejected with a descriptive runtimeError naming the mismatched sizes.
    func testMismatchedNumberSizeIsRejected() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        let currentSize = CompiledChunk.currentNumberSize
        let foreignSize = currentSize == 8 ? 4 : 8
        let tampered = try reencode(chunk) { $0["numberSize"] = foreignSize }
        XCTAssertThrowsError(try engine.evaluate(tampered)) { error in
            guard case .runtimeError(let message)? = error as? LuaError else {
                XCTFail("Expected .runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("\(foreignSize)"),
                          "Message should name the chunk's number size: \(message)")
            XCTAssertTrue(message.contains("\(currentSize)"),
                          "Message should name the engine's number size: \(message)")
        }
    }

    // MARK: - Golden wire-format fixture (CR-023)

    /// A golden fixture that pins the JSON envelope field set so accidental
    /// format changes are caught. The test verifies that a freshly compiled
    /// chunk's JSON contains exactly the expected top-level keys and that the
    /// decoded chunk round-trips correctly. Any addition or removal of a key
    /// is a format change that must be intentional and reviewed.
    func testGoldenWireFormatKeySet() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 42", chunkName: "fixture")
        let encoded = try JSONEncoder().encode(chunk)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        // Exactly these seven keys must be present — no more, no less.
        let expectedKeys: Set<String> = [
            "formatVersion", "luaVersion", "integerSize",
            "numberSize", "endianness", "bytecode", "chunkName"
        ]
        XCTAssertEqual(Set(object.keys), expectedKeys,
                       "Wire format keys changed — update formatVersion and docs")
        // The fixture round-trips and still evaluates to the original value.
        let decoded = try JSONDecoder().decode(CompiledChunk.self, from: encoded)
        let result = try engine.evaluate(decoded)
        XCTAssertEqual(result.numberValue, 42)
    }

    // MARK: - Empty source (CR-024)

    /// precompile("") on an empty source string must succeed (the Lua compiler
    /// accepts an empty chunk), and the resulting chunk must evaluate to nil
    /// (no `return` statement means the implicit return is nil).
    func testEmptySourcePrecompilesAndRunsCleanly() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("")
        // run should complete without throwing.
        XCTAssertNoThrow(try engine.run(chunk))
        // evaluate should return nil (empty chunk has no return value).
        let result = try engine.evaluate(chunk)
        XCTAssertTrue(result == .nil, "Empty chunk should evaluate to nil, got \(result)")
    }

    // MARK: - run(chunk) after a prior memoryError (CR-024)

    /// After a vmMemoryLimit-triggered memoryError, the engine must still be
    /// able to run a precompiled chunk — the protected call is the isolation
    /// boundary and the prior failure must not have corrupted Lua state.
    func testRunChunkAfterPriorMemoryError() throws {
        let config = LuaEngineConfiguration(
            sandboxed: true, packagePath: nil, memoryLimit: 0, vmMemoryLimit: 10_000_000)
        let engine = try LuaEngine(configuration: config)

        // Trigger a memoryError via a runaway allocation.
        XCTAssertThrowsError(
            try engine.evaluate("return string.rep('A', 100000000)")) { error in
            guard case LuaError.memoryError = error else {
                XCTFail("Expected memoryError, got \(error)")
                return
            }
        }

        // The engine's protected-call boundary must have unwound cleanly.
        // A pre-compiled chunk must execute successfully after the error.
        let chunk = try engine.precompile("return 2 + 2")
        let result = try engine.evaluate(chunk)
        XCTAssertEqual(result.numberValue, 4,
                       "evaluate(chunk) must work after a prior memoryError")
    }
}
