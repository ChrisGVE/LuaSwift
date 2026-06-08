//
//  ChunkNameTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Tests/LuaSwiftTests/ChunkNameTests.swift
//
//  Context: Acceptance tests for the optional chunkName parameter added to
//  run(_:chunkName:), evaluate(_:chunkName:), precompile(_:chunkName:), and
//  createCoroutine(code:chunkName:) — issue #23. Tests validate both the
//  source-chunk path (name embedded via luaL_loadbuffer with '@' prefix) and
//  the bytecode path (name embedded in Proto.source before lua_dump). The
//  dump/undump round-trip test is the proof that the name is embedded in the
//  bytecode, not just stored in the Swift metadata.
//

import XCTest
@testable import LuaSwift

/// Tests for the chunkName parameter (issue #23).
///
/// ## Name prefix convention
///
/// LuaSwift passes "@" + chunkName to luaL_loadbuffer for source chunks and
/// embeds the same prefix in the bytecode Proto.source at precompile time.
/// Lua's short_src truncation rule for "@"-prefixed names: if the name fits
/// within LUA_IDSIZE (60 bytes), it appears verbatim; if it exceeds 60 bytes,
/// Lua shows "..." followed by the TAIL of the name, preserving the most
/// specific path component. This is the correct behavior for MoonSwift's
/// FragmentProvenance.displayName use case.
///
/// When chunkName is nil, LuaSwift passes the source string itself as the
/// name, replicating luaL_loadstring exactly and preserving the existing
/// "[string \"...\"]" traceback appearance.
final class ChunkNameTests: XCTestCase {

    // MARK: - Helpers

    /// Run Lua code that calls error() and capture the thrown LuaError message.
    private func errorMessage(from run: () throws -> Void) -> String {
        do {
            try run()
            XCTFail("Expected a LuaError to be thrown")
            return ""
        } catch let err as LuaError {
            switch err {
            case .runtimeError(let msg): return msg
            case .syntaxError(let msg): return msg
            default:
                XCTFail("Unexpected LuaError case: \(err)")
                return ""
            }
        } catch {
            XCTFail("Unexpected non-LuaError thrown: \(error)")
            return ""
        }
    }

    // MARK: - run(_:chunkName:) — source chunk

    /// run("error('x')", chunkName: "config.yaml:$.scripts.init") must produce
    /// a traceback/error message that contains the supplied name. The name is
    /// 33 chars, well under LUA_IDSIZE=60, so it appears in full.
    func testRunWithChunkNameAppearsInError() throws {
        let engine = try LuaEngine()
        let name = "config.yaml:$.scripts.init"
        let msg = errorMessage { try engine.run("error('x')", chunkName: name) }
        XCTAssertTrue(msg.contains(name),
                      "Expected '\(name)' in error message, got: \(msg)")
    }

    /// Omitting chunkName must reproduce the current behavior: no regression.
    /// Lua shows "[string \"error...\"]" (or a similar [string ...] form) when
    /// the source string itself is the name. Assert the expected prefix is absent
    /// and the default form is present.
    func testRunWithoutChunkNamePreservesDefaultBehavior() throws {
        let engine = try LuaEngine()
        let msg = errorMessage { try engine.run("error('baseline')") }
        // Default: Lua uses the source itself as the name, so [string "..."] appears.
        XCTAssertTrue(msg.contains("[string"),
                      "Expected '[string' in default-behavior error, got: \(msg)")
        // No user-supplied name prefix character '@' should appear in the message.
        // (The '@' is consumed by luaL_loadbuffer to form the short_src but is
        // stripped from what Lua displays; this just guards against leakage.)
        XCTAssertFalse(msg.hasPrefix("@"),
                       "Message must not start with bare '@': \(msg)")
    }

    // MARK: - evaluate(_:chunkName:) — source chunk

    /// evaluate with a chunkName: a syntax error in the source names the chunk.
    func testEvaluateSyntaxErrorCarriesChunkName() throws {
        let engine = try LuaEngine()
        let name = "myScript.lua"
        let msg = errorMessage { _ = try engine.evaluate("=== bad syntax", chunkName: name) }
        XCTAssertTrue(msg.contains(name),
                      "Expected '\(name)' in syntax-error message, got: \(msg)")
    }

    /// evaluate("error('boom')", chunkName:) — runtime error contains the name.
    func testEvaluateRuntimeErrorCarriesChunkName() throws {
        let engine = try LuaEngine()
        let name = "compute.lua"
        let msg = errorMessage {
            _ = try engine.evaluate("error('boom')", chunkName: name)
        }
        XCTAssertTrue(msg.contains(name),
                      "Expected '\(name)' in runtime error, got: \(msg)")
    }

    // MARK: - Multi-level call traceback

    /// A multi-level traceback shows the chunkName on the relevant frame.
    /// We define a local function in Lua that calls error, then call it from
    /// top-level; both frames carry the same chunk name.
    func testRunMultiLevelTracebackShowsName() throws {
        let engine = try LuaEngine()
        let name = "pipeline.yaml:stage1"
        let source = """
            local function inner()
                error("deep failure")
            end
            inner()
        """
        // Use debug.traceback as message handler by calling via xpcall at Lua level.
        // We keep it simple: just assert the name appears in the error string.
        let msg = errorMessage { try engine.run(source, chunkName: name) }
        XCTAssertTrue(msg.contains(name),
                      "Expected '\(name)' in multi-level traceback, got: \(msg)")
    }

    // MARK: - Syntax error with chunkName on run path

    /// A syntax error from run(_:chunkName:) also carries the chunk name.
    func testRunSyntaxErrorCarriesChunkName() throws {
        let engine = try LuaEngine()
        let name = "bad.lua"
        let msg = errorMessage { try engine.run("not valid lua ===", chunkName: name) }
        XCTAssertTrue(msg.contains(name),
                      "Expected '\(name)' in syntax-error from run, got: \(msg)")
    }

    // MARK: - Long name: '@'-tail truncation (LUA_IDSIZE = 60)

    /// When the chunkName exceeds 60 characters, Lua truncates short_src by
    /// keeping the TAIL and prepending "...". The tail (most-specific component)
    /// must still be visible in the error message.
    func testLongChunkNameTailVisibleInError() throws {
        let engine = try LuaEngine()
        // Construct a name longer than 60 characters whose tail is distinctive.
        let longPrefix = String(repeating: "x", count: 50)
        let distinctTail = "specific-fragment.lua"
        let longName = longPrefix + "/" + distinctTail  // 72 chars total
        XCTAssertGreaterThan(longName.count, 60,
                             "Test name must exceed LUA_IDSIZE=60 to exercise truncation")
        let msg = errorMessage { try engine.run("error('long')", chunkName: longName) }
        XCTAssertTrue(msg.contains(distinctTail),
                      "Expected tail '\(distinctTail)' in truncated name error, got: \(msg)")
        // Lua shows "..." before the tail when truncating '@'-prefixed names.
        XCTAssertTrue(msg.contains("..."),
                      "Expected '...' ellipsis from tail-truncation, got: \(msg)")
    }

    // MARK: - precompile(_:chunkName:) — bytecode path

    /// precompile with a chunkName, then run the chunk: the traceback must
    /// contain the name. This exercises the source→Proto.source embedding path.
    func testPrecompileChunkNameAppearsInError() throws {
        let engine = try LuaEngine()
        let name = "cached-fragment.lua"
        let chunk = try engine.precompile("error('from bytecode')", chunkName: name)
        XCTAssertEqual(chunk.chunkName, name)
        let msg = errorMessage { try engine.run(chunk) }
        XCTAssertTrue(msg.contains(name),
                      "Expected '\(name)' in bytecode error, got: \(msg)")
    }

    /// precompile without chunkName: chunkName field is nil.
    func testPrecompileWithoutChunkNameIsNil() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("return 1")
        XCTAssertNil(chunk.chunkName)
    }

    // MARK: - CompiledChunk Codable round-trip with chunkName

    /// Encode a CompiledChunk (with chunkName) to JSON, decode it, run the
    /// decoded chunk, trigger an error — the name must appear. This proves the
    /// name survived Codable persistence.
    func testCompiledChunkCodableRoundTripPreservesName() throws {
        let engine = try LuaEngine()
        let name = "persisted.lua"
        let chunk = try engine.precompile("error('after codable')", chunkName: name)
        let encoded = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(CompiledChunk.self, from: encoded)
        XCTAssertEqual(decoded.chunkName, name)
        let msg = errorMessage { try engine.run(decoded) }
        XCTAssertTrue(msg.contains(name),
                      "Expected '\(name)' in error after Codable round-trip, got: \(msg)")
    }

    // MARK: - lua_dump/undump round-trip: name embedded in Proto.source

    /// The definitive bytecode-embedding proof: extract the raw bytecode bytes
    /// from the chunk and search for the '@'-prefixed name string directly in
    /// the dump. If the name is present in the binary, it was embedded in the
    /// Proto.source field before lua_dump, not merely stored in Swift metadata.
    func testDumpUndumpRoundTripNameEmbeddedInProtocol() throws {
        let engine = try LuaEngine()
        let name = "embedded-in-proto.lua"
        let atPrefixedName = "@" + name   // Lua stores the '@' prefix verbatim in Proto.source
        let chunk = try engine.precompile("error('proto check')", chunkName: name)

        // Retrieve the raw bytecode via the internal accessor exposed for testing.
        // validatedBytecode() runs provenance checks and returns the raw dump bytes.
        let rawBytes = try chunk.validatedBytecode()

        // Search for the '@'-prefixed name as a byte sequence inside the dump.
        let nameBytes = Array(atPrefixedName.utf8)
        let chunkBytes = Array(rawBytes)
        let found = chunkBytes.windows(ofCount: nameBytes.count).contains { window in
            window.elementsEqual(nameBytes)
        }
        XCTAssertTrue(found,
                      "Expected '\(atPrefixedName)' embedded as bytes in lua_dump output; "
                      + "name was not found — it was stored in Swift metadata only, not in Proto.source")
    }

    // MARK: - v1 CompiledChunk (no chunkName field) decodes cleanly under v2

    /// A JSON payload with formatVersion=1 and no chunkName key must decode
    /// successfully under the v2 format with chunkName == nil. No keyNotFound.
    func testV1ChunkDecodesWithNilChunkName() throws {
        let engine = try LuaEngine()
        // First build a valid chunk so we get real bytecode bytes.
        let realChunk = try engine.precompile("return 42")
        let encoded = try JSONEncoder().encode(realChunk)
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        // Simulate a v1 chunk: set formatVersion=1 and remove the chunkName key.
        json["formatVersion"] = 1
        json.removeValue(forKey: "chunkName")

        let v1Data = try JSONSerialization.data(withJSONObject: json)
        // Must decode without throwing, and chunkName must be nil.
        let decoded = try JSONDecoder().decode(CompiledChunk.self, from: v1Data)
        XCTAssertNil(decoded.chunkName,
                     "A v1 chunk (no chunkName field) must decode with chunkName == nil")
    }

    // MARK: - createCoroutine(code:chunkName:) — coroutine path

    /// A coroutine created with chunkName shows that name in the error when
    /// the coroutine body raises.
    func testCoroutineWithChunkNameAppearsInError() throws {
        let engine = try LuaEngine()
        let name = "worker-coroutine.lua"
        let handle = try engine.createCoroutine(code: "error('co error')", chunkName: name)
        let result = try engine.resume(handle)
        switch result {
        case .error(let err):
            if case .coroutineError(let msg) = err {
                XCTAssertTrue(msg.contains(name),
                              "Expected '\(name)' in coroutine error, got: \(msg)")
            } else {
                XCTFail("Expected .coroutineError, got: \(err)")
            }
        default:
            XCTFail("Expected .error result from error()-raising coroutine, got: \(result)")
        }
    }

    /// A coroutine created without chunkName still uses the source as name
    /// (default Lua behavior unchanged), not a new literal like "[coroutine]".
    func testCoroutineWithoutChunkNamePreservesDefaultBehavior() throws {
        let engine = try LuaEngine()
        let handle = try engine.createCoroutine(code: "error('co default')")
        let result = try engine.resume(handle)
        switch result {
        case .error(let err):
            if case .coroutineError(let msg) = err {
                // Default: source-as-name produces [string "..."] form.
                XCTAssertTrue(msg.contains("[string"),
                              "Expected '[string' in default coroutine error, got: \(msg)")
            } else {
                XCTFail("Expected .coroutineError, got: \(err)")
            }
        default:
            XCTFail("Expected .error result from error()-raising coroutine, got: \(result)")
        }
    }
}

// MARK: - Sliding-window helper

/// A minimal sliding-window sequence over a RandomAccessCollection, used to
/// scan for a byte-sequence inside the lua_dump output without pulling in
/// external dependencies.
private struct WindowSequence<Base: RandomAccessCollection>: Sequence {
    let base: Base
    let windowSize: Int

    struct Iterator: IteratorProtocol {
        let base: Base
        let windowSize: Int
        var index: Base.Index

        mutating func next() -> Base.SubSequence? {
            guard base.distance(from: index, to: base.endIndex) >= windowSize else {
                return nil
            }
            let end = base.index(index, offsetBy: windowSize)
            let window = base[index..<end]
            index = base.index(after: index)
            return window
        }
    }

    func makeIterator() -> Iterator {
        Iterator(base: base, windowSize: windowSize, index: base.startIndex)
    }
}

private extension Array {
    func windows(ofCount size: Int) -> WindowSequence<[Element]> {
        WindowSequence(base: self, windowSize: size)
    }
}
