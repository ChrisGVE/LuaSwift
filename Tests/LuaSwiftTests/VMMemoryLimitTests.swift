//
//  VMMemoryLimitTests.swift
//  Tests/LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Context: Tests for `LuaEngineConfiguration.vmMemoryLimit`, the ceiling on
//  total Lua VM allocation enforced by a custom `lua_Alloc` allocator
//  (issue #11). Complements MemoryLimitTests.swift, which covers the separate
//  `memoryLimit` knob bounding Swift-module buffers, and
//  InstructionLimitTests.swift, which covers the CPU-bound instruction hook.
//  The VM limit closes the gap those two leave open: a single VM instruction
//  calling a C function (e.g. `string.rep('A', 1e9)`) is never interrupted by
//  the instruction hook and is invisible to Swift-module tracking.
//

import XCTest
@testable import LuaSwift

/// Tests for the Lua VM memory limit enforced via a custom allocator.
final class VMMemoryLimitTests: XCTestCase {

    /// Convenience: sandboxed configuration with only the VM limit set.
    private func configuration(vmMemoryLimit: Int) -> LuaEngineConfiguration {
        LuaEngineConfiguration(
            sandboxed: true,
            packagePath: nil,
            memoryLimit: 0,
            vmMemoryLimit: vmMemoryLimit
        )
    }

    // MARK: - Issue #11 Scenario

    /// A single `string.rep` op allocating ~100 MB must fail against a 10 MB
    /// VM limit with `.memoryError` — the exact scenario from issue #11 that
    /// the instruction-count hook cannot interrupt.
    func testStringRepBeyondLimitThrowsMemoryError() throws {
        let engine = try LuaEngine(configuration: configuration(vmMemoryLimit: 10_000_000))

        XCTAssertThrowsError(try engine.evaluate("return string.rep('A', 100000000)")) { error in
            guard case LuaError.memoryError = error else {
                XCTFail("Expected memoryError, got \(error)")
                return
            }
        }
    }

    // MARK: - Table Growth

    /// A runaway table-growth loop must hit the VM limit and surface
    /// `.memoryError` instead of exhausting process memory.
    func testTableGrowthBeyondLimitThrowsMemoryError() throws {
        let engine = try LuaEngine(configuration: configuration(vmMemoryLimit: 5_000_000))

        XCTAssertThrowsError(try engine.run("""
            local t = {}
            for i = 1, 100000000 do
                t[i] = i
            end
        """)) { error in
            guard case LuaError.memoryError = error else {
                XCTFail("Expected memoryError, got \(error)")
                return
            }
        }
    }

    // MARK: - Normal Scripts Unaffected

    /// Ordinary scripts run unchanged under a generous limit and produce
    /// correct results.
    func testNormalScriptsUnaffectedByGenerousLimit() throws {
        let engine = try LuaEngine(configuration: configuration(vmMemoryLimit: 64_000_000))

        let sum = try engine.evaluate("""
            local total = 0
            for i = 1, 1000 do
                total = total + i
            end
            return total
        """)
        XCTAssertEqual(sum.numberValue, 500_500)

        let text = try engine.evaluate("return string.rep('ab', 500) ")
        XCTAssertEqual(text.stringValue?.count, 1000)

        let table = try engine.evaluate("""
            local t = {}
            for i = 1, 10000 do t[i] = i * 2 end
            return t[10000]
        """)
        XCTAssertEqual(table.numberValue, 20_000)
    }

    // MARK: - Disabled (Default) Limit

    /// `vmMemoryLimit = 0` (the default) keeps the `luaL_newstate` path with
    /// no allocator interposition: a moderately large allocation succeeds.
    func testDefaultZeroLimitIsUnlimited() throws {
        let engine = try LuaEngine()  // .default has vmMemoryLimit = 0

        let result = try engine.evaluate("return #string.rep('A', 20000000)")
        XCTAssertEqual(result.numberValue, 20_000_000)
    }

    /// The default and unrestricted configurations both disable the VM limit.
    func testDefaultConfigurationsDisableVMLimit() {
        XCTAssertEqual(LuaEngineConfiguration.default.vmMemoryLimit, 0)
        XCTAssertEqual(LuaEngineConfiguration.unrestricted.vmMemoryLimit, 0)
    }

    /// Omitting `vmMemoryLimit` from the initializer keeps it disabled
    /// (source compatibility for existing 1.x callers).
    func testInitializerDefaultsVMLimitToZero() {
        let config = LuaEngineConfiguration(sandboxed: true, packagePath: nil, memoryLimit: 0)
        XCTAssertEqual(config.vmMemoryLimit, 0)
    }

    // MARK: - Tiny Limit at Init

    /// With a limit too small for the standard libraries, engine creation must
    /// either succeed or throw a `LuaError` — never crash or abort.
    func testTinyLimitInitThrowsCleanlyOrSucceeds() {
        do {
            let engine = try LuaEngine(configuration: configuration(vmMemoryLimit: 65_536))
            // If init squeezed through, a trivial script either runs or
            // throws cleanly when the headroom runs out.
            _ = try? engine.evaluate("return 1 + 1")
        } catch {
            XCTAssertTrue(error is LuaError, "Expected LuaError, got \(type(of: error))")
        }
    }

    // MARK: - Engine Usability After Denial

    /// After a `.memoryError`, the protected call has unwound and the state
    /// remains consistent: a subsequent small script must still work.
    func testEngineUsableAfterMemoryError() throws {
        let engine = try LuaEngine(configuration: configuration(vmMemoryLimit: 10_000_000))

        XCTAssertThrowsError(try engine.evaluate("return string.rep('A', 100000000)")) { error in
            guard case LuaError.memoryError = error else {
                XCTFail("Expected memoryError, got \(error)")
                return
            }
        }

        // Failed giant allocation must not have corrupted the state; freeing
        // (collectgarbage) and fresh small allocations must both work.
        let result = try engine.evaluate("""
            collectgarbage()
            local t = {}
            for i = 1, 100 do t[i] = string.rep('x', 10) end
            return #t
        """)
        XCTAssertEqual(result.numberValue, 100)
    }

    // MARK: - Repeated Runs Under Limit

    /// Memory freed by the garbage collector is credited back to the
    /// accounting, so repeated transient allocations under the limit succeed.
    func testGarbageCollectedMemoryIsCreditedBack() throws {
        let engine = try LuaEngine(configuration: configuration(vmMemoryLimit: 8_000_000))

        // Each iteration allocates ~2 MB then drops it; without free
        // accounting the third pass would breach the 8 MB ceiling.
        for _ in 1...5 {
            let result = try engine.evaluate("""
                local s = string.rep('y', 2000000)
                local n = #s
                s = nil
                collectgarbage()
                return n
            """)
            XCTAssertEqual(result.numberValue, 2_000_000)
        }
    }

    // MARK: - Shrink Under Limit (CR-004)

    /// A shrink (`nsize <= osize`) must never be denied by the allocator: Lua's
    /// contract (Reference Manual §4.13) guarantees the allocator does not fail
    /// when reducing a block. A script that grows a large buffer right up to
    /// the ceiling and then shrinks it must complete without a `.memoryError`
    /// on the shrink — proving the shrink path returns a valid pointer even
    /// when `realloc` cannot move the block.
    func testShrinkUnderLimitNeverDenied() throws {
        let engine = try LuaEngine(configuration: configuration(vmMemoryLimit: 16_000_000))

        // Build a large table near the limit, then truncate it (shrink) and
        // force a GC pass that reallocates/shrinks internal structures. The
        // final small allocation must succeed.
        let result = try engine.evaluate("""
            local t = {}
            for i = 1, 200000 do t[i] = i end   -- grow large
            for i = 200000, 50, -1 do t[i] = nil end  -- shrink it back down
            collectgarbage()                     -- triggers shrinking reallocs
            local s = string.rep('z', 100000)    -- large, then drop -> shrink
            s = string.sub(s, 1, 10)             -- shrink the string buffer
            collectgarbage()
            return #s + #t
        """)
        XCTAssertEqual(result.numberValue, 10 + 49)
    }

    /// Repeatedly growing to the ceiling and shrinking back must stay healthy:
    /// if the shrink path ever returned nil (the CR-004 bug) or failed to
    /// credit freed bytes, a later pass would spuriously hit `.memoryError`.
    func testRepeatedGrowShrinkStaysHealthy() throws {
        let engine = try LuaEngine(configuration: configuration(vmMemoryLimit: 12_000_000))

        for _ in 1...10 {
            let n = try engine.evaluate("""
                local s = string.rep('q', 3000000)  -- grow
                s = string.sub(s, 1, 1)             -- shrink hard
                collectgarbage()
                return #s
            """)
            XCTAssertEqual(n.numberValue, 1)
        }
    }
}
