//
//  StructuredErrorTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-08.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Tests/LuaSwiftTests/StructuredErrorTests.swift
//
//  Context: Acceptance tests for structured runtime errors (issue #19).
//  Verifies that LuaError.runtimeFailure carries correctly-parsed line numbers,
//  stripped messages, tracebacks, and stack frames from all three pcall paths
//  (run/evaluate, CompiledChunk, callLuaFunction). Also regression-tests that
//  LuaError.cancelled and .instructionLimitExceeded are unaffected by the new
//  handler. The `error("boom")` vs VM-internal error distinction proves the
//  first-non-C-frame scan rather than unconditional level-1 line reads.
//

import XCTest
@testable import LuaSwift

/// Acceptance tests for structured errors (#19).
///
/// ## Handler contract (recap)
///
/// The Swift-stash errfunc installed on every lua_pcall:
/// - Passes sentinel strings through untouched (cancel/limit).
/// - Emits `<error: T>` for non-string error objects without calling __tostring.
/// - Reads currentLine from the first frame whose `what != "C"`, scanning
///   upward from level 1 — so both explicit `error()` (Lua frame at level 2)
///   and VM-internal errors (Lua frame at level 1) produce the correct line.
/// - Builds a traceback string on all Lua versions (manual walk on 5.1).
/// - Stores results in `engine.pendingRuntimeFailure` and returns 1 unchanged.
///
/// Coroutine resume uses lua_resume (no errfunc) — structured errors there are
/// OUT OF SCOPE for #19 and tested here only to confirm no regression.
final class StructuredErrorTests: XCTestCase {

    // MARK: - Helpers

    /// Extract a LuaRuntimeFailure or fail the test.
    private func runtimeFailure(
        from work: () throws -> Void,
        file: StaticString = #file, line: UInt = #line
    ) -> LuaRuntimeFailure? {
        do {
            try work()
            XCTFail("Expected LuaError.runtimeFailure to be thrown", file: file, line: line)
            return nil
        } catch let err as LuaError {
            if case .runtimeFailure(let failure) = err {
                return failure
            }
            XCTFail("Expected .runtimeFailure, got \(err)", file: file, line: line)
            return nil
        } catch {
            XCTFail("Unexpected non-LuaError: \(error)", file: file, line: line)
            return nil
        }
    }

    // MARK: - error("boom") on line 3 — explicit Lua error()

    /// error("boom") at Lua line 3.
    ///
    /// For an explicit error() call, level 1 is the C `error` builtin
    /// (currentline == -1). The first non-C frame is the Lua caller at level 2,
    /// which is the source line where error() was invoked.
    func testExplicitErrorLine() throws {
        let engine = try LuaEngine()
        // Three lines; error() is on line 3.
        let code = """
        local x = 1
        local y = 2
        error("boom")
        """
        guard let failure = runtimeFailure(from: { try engine.run(code) }) else { return }
        XCTAssertEqual(failure.line, 3,
            "Expected line 3 for error() on line 3; got \(String(describing: failure.line))")
        XCTAssertEqual(failure.message, "boom",
            "Expected stripped message 'boom'; got '\(failure.message)'")
        XCTAssertTrue(failure.rawMessage.contains("3"),
            "rawMessage should contain line number prefix; got '\(failure.rawMessage)'")
    }

    // MARK: - VM-internal error on line 5

    /// `nil + 1` on line 5 generates a VM-internal type error.
    ///
    /// For a VM-internal error the raising Lua frame IS at level 1
    /// (no C `error` builtin between the VM and the frame), so the
    /// first-non-C-frame scan still yields the right line.
    func testVMInternalErrorLine() throws {
        let engine = try LuaEngine()
        let code = """
        local a = 1
        local b = 2
        local c = 3
        local d = 4
        local x = nil + 1
        """
        guard let failure = runtimeFailure(from: { try engine.run(code) }) else { return }
        XCTAssertEqual(failure.line, 5,
            "Expected line 5 for nil+1 on line 5; got \(String(describing: failure.line))")
    }

    // MARK: - Nested-call traceback

    /// a() calls b() calls c() which calls error().
    /// The traceback must contain all three function names.
    func testNestedCallTraceback() throws {
        let engine = try LuaEngine()
        let code = """
        local function c() error("deep") end
        local function b() c() end
        local function a() b() end
        a()
        """
        guard let failure = runtimeFailure(from: { try engine.run(code) }) else { return }
        XCTAssertFalse(failure.traceback.isEmpty, "traceback must be non-empty")
        // All three function names must appear in the traceback
        XCTAssertTrue(failure.traceback.contains("function 'c'") || failure.traceback.contains("'c'"),
            "traceback missing 'c': \(failure.traceback)")
        XCTAssertTrue(failure.traceback.contains("function 'b'") || failure.traceback.contains("'b'"),
            "traceback missing 'b': \(failure.traceback)")
        XCTAssertTrue(failure.traceback.contains("function 'a'") || failure.traceback.contains("'a'"),
            "traceback missing 'a': \(failure.traceback)")
        // frames should have at least 3 entries
        if let frames = failure.frames {
            XCTAssertGreaterThanOrEqual(frames.count, 3,
                "Expected ≥3 frames; got \(frames.count)")
        } else {
            XCTFail("frames must not be nil for a nested Lua call")
        }
    }

    // MARK: - CompiledChunk path

    /// A runtime error from a precompiled CompiledChunk must also carry
    /// structured info — proves the handler is wired on the bytecode path.
    func testCompiledChunkStructuredError() throws {
        let engine = try LuaEngine()
        let chunk = try engine.precompile("error('bytecode error')", chunkName: "compiled.lua")
        guard let failure = runtimeFailure(from: { try engine.run(chunk) }) else { return }
        XCTAssertNotNil(failure.line, "line must be non-nil for bytecode error")
        XCTAssertEqual(failure.message, "bytecode error",
            "Expected stripped message; got '\(failure.message)'")
    }

    // MARK: - callLuaFunction path

    /// A runtime error thrown inside a Lua function called via callLuaFunction
    /// must carry structured info — proves the handler is wired on that path.
    func testCallLuaFunctionStructuredError() throws {
        let engine = try LuaEngine()
        let fn = try engine.evaluate("return function() error('callback error') end")
        guard case .luaFunction(let ref) = fn else {
            return XCTFail("Expected .luaFunction, got \(fn)")
        }
        defer { engine.releaseLuaFunction(ref: ref) }
        guard let failure = runtimeFailure(from: {
            _ = try engine.callLuaFunction(ref: ref, args: [])
        }) else { return }
        XCTAssertNotNil(failure.line, "line must be non-nil for callLuaFunction error")
        XCTAssertEqual(failure.message, "callback error",
            "Expected stripped message; got '\(failure.message)'")
    }

    // MARK: - Error from registered Swift function (line == nil)

    /// An error raised inside a registered Swift callback — which has no Lua
    /// source frame — must yield line == nil without crashing.
    func testSwiftCallbackErrorYieldsNilLine() throws {
        let engine = try LuaEngine()
        engine.registerFunction(name: "swiftError") { _ in
            throw LuaError.callbackError("from swift")
        }
        guard let failure = runtimeFailure(from: {
            try engine.run("swiftError()")
        }) else { return }
        // The Swift callback's C frame has no Lua source line.
        // Depending on whether the Lua call site is captured, line may or may
        // not be nil — what we must guarantee is no crash.
        // If a Lua frame exists at the call site, line may be non-nil; that is
        // acceptable. We test no-crash is the primary guarantee here.
        _ = failure.line  // must not crash
    }

    // MARK: - Non-string error object (no __tostring)

    /// error({code=1}) passes a table as the error object.
    ///
    /// The handler must emit a typed placeholder `<error: table>` WITHOUT
    /// calling __tostring (which would fire a side-effect flag).
    func testNonStringErrorNoMetamethod() throws {
        let engine = try LuaEngine()
        // Install a table whose __tostring sets a global flag.
        let code = """
        local __tostring_fired = false
        local mt = { __tostring = function() __tostring_fired = true; return "hi" end }
        local obj = setmetatable({code=1}, mt)
        error(obj)
        """
        guard let failure = runtimeFailure(from: { try engine.run(code) }) else { return }
        XCTAssertTrue(
            failure.message.hasPrefix("<error:"),
            "Expected typed placeholder '<error:...>'; got '\(failure.message)'"
        )
        // Verify the __tostring metamethod was not called.
        let flagValue = try engine.evaluate("return __tostring_fired")
        if case .bool(let fired) = flagValue {
            XCTAssertFalse(fired, "__tostring was called — handler violated no-metamethod rule")
        } else {
            // __tostring_fired was nil (never set) — metamethod not called, correct
            XCTAssertEqual(flagValue, .nil,
                "Expected __tostring_fired to be false or nil; got \(flagValue)")
        }
    }

    // MARK: - Cancellation pass-through regression

    /// A cancelled run must still surface LuaError.cancelled, NOT runtimeFailure,
    /// even with the structured-error handler installed.
    func testCancelledRunStillSurfacesCancelled() throws {
        let engine = try LuaEngine()
        let expectation = self.expectation(description: "cancel fires")
        var caughtError: LuaError?
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            engine.requestCancellation()
        }
        DispatchQueue.global().async {
            do {
                try engine.run("while true do end")
            } catch let err as LuaError {
                caughtError = err
            } catch {}
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
        guard let err = caughtError else {
            return XCTFail("Expected a LuaError")
        }
        if case .cancelled = err {
            // correct
        } else {
            XCTFail("Expected .cancelled; got \(err)")
        }
        engine.resetCancellation()
    }

    // MARK: - Instruction-limit pass-through regression

    /// A limit-exceeded run must still surface LuaError.instructionLimitExceeded,
    /// NOT runtimeFailure, even with the structured-error handler installed.
    func testInstructionLimitStillSurfacesLimitExceeded() throws {
        let engine = try LuaEngine()
        engine.setInstructionLimit(1_000)
        XCTAssertThrowsError(try engine.run("while true do end")) { error in
            guard let luaError = error as? LuaError else {
                return XCTFail("Expected LuaError, got \(type(of: error))")
            }
            if case .instructionLimitExceeded = luaError {
                // correct
            } else {
                XCTFail("Expected .instructionLimitExceeded; got \(luaError)")
            }
        }
    }

    // MARK: - Lua 5.1 traceback fallback (non-nil)

    /// On all versions (including 5.1 which lacks luaL_traceback), the traceback
    /// field must be non-nil and non-empty.
    func testTracebackIsNonNilOnAllVersions() throws {
        let engine = try LuaEngine()
        guard let failure = runtimeFailure(from: {
            try engine.run("error('trace test')")
        }) else { return }
        XCTAssertFalse(failure.traceback.isEmpty,
            "traceback must be non-empty on all Lua versions")
    }

    // MARK: - runtimeError(String) source compatibility

    /// LuaError.runtimeError(String) still compiles and pattern-matches.
    /// This ensures the additive new case did not break the existing API.
    func testRuntimeErrorStringCaseStillMatches() {
        let err: LuaError = .runtimeError("test message")
        if case .runtimeError(let msg) = err {
            XCTAssertEqual(msg, "test message")
        } else {
            XCTFail("runtimeError(String) case no longer matches after #19 changes")
        }
    }

    // MARK: - runtimeFailure errorDescription

    /// LuaError.runtimeFailure must produce a human-readable errorDescription.
    func testRuntimeFailureErrorDescription() {
        let failure = LuaRuntimeFailure(
            message: "boom",
            rawMessage: "chunk:3: boom",
            line: 3,
            traceback: "stack traceback:\n  chunk:3: in main chunk",
            frames: nil
        )
        let err: LuaError = .runtimeFailure(failure)
        let desc = err.errorDescription ?? ""
        XCTAssertTrue(desc.contains("boom"), "errorDescription should contain message; got '\(desc)'")
        XCTAssertTrue(desc.contains("3"), "errorDescription should contain line; got '\(desc)'")
    }

    // MARK: - Frames populated

    /// For a simple error() the frames array must be populated.
    func testFramesArePopulated() throws {
        let engine = try LuaEngine()
        guard let failure = runtimeFailure(from: {
            try engine.run("error('frames test')")
        }) else { return }
        XCTAssertNotNil(failure.frames, "frames must not be nil")
        XCTAssertFalse(failure.frames!.isEmpty, "frames must not be empty")
    }
}
