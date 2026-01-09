//
//  MemoryLimitTests.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-09.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

/// Tests for memory limit enforcement in LuaEngine and Swift modules.
final class MemoryLimitTests: XCTestCase {

    // MARK: - LuaEngine Memory Tracking

    func testEngineMemoryTrackingProperties() throws {
        let engine = try LuaEngine()

        // Initially no memory allocated
        XCTAssertEqual(engine.allocatedBytes, 0)
    }

    func testEngineTrackAllocationWithNoLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 0))

        // Should not throw when no limit
        XCTAssertNoThrow(try engine.trackAllocation(bytes: 1_000_000))
        XCTAssertEqual(engine.allocatedBytes, 1_000_000)
    }

    func testEngineTrackAllocationWithLimit() throws {
        // Set 1KB limit
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 1024))

        // Allocation under limit should succeed
        XCTAssertNoThrow(try engine.trackAllocation(bytes: 512))
        XCTAssertEqual(engine.allocatedBytes, 512)
    }

    func testEngineTrackAllocationExceedsLimit() throws {
        // Set 1KB limit
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 1024))

        // Allocation exceeding limit should throw
        XCTAssertThrowsError(try engine.trackAllocation(bytes: 2048)) { error in
            guard case LuaError.memoryError(let message) = error else {
                XCTFail("Expected memoryError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testEngineMultipleAllocationsAccumulate() throws {
        // Set 1KB limit
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 1024))

        // First allocation
        try engine.trackAllocation(bytes: 400)
        XCTAssertEqual(engine.allocatedBytes, 400)

        // Second allocation
        try engine.trackAllocation(bytes: 400)
        XCTAssertEqual(engine.allocatedBytes, 800)

        // Third allocation should fail (exceeds limit)
        XCTAssertThrowsError(try engine.trackAllocation(bytes: 400)) { error in
            guard case LuaError.memoryError = error else {
                XCTFail("Expected memoryError")
                return
            }
        }

        // Allocated bytes should not have increased
        XCTAssertEqual(engine.allocatedBytes, 800)
    }

    func testEngineDeallocationTracking() throws {
        let engine = try LuaEngine()

        try engine.trackAllocation(bytes: 1000)
        XCTAssertEqual(engine.allocatedBytes, 1000)

        engine.trackDeallocation(bytes: 400)
        XCTAssertEqual(engine.allocatedBytes, 600)

        // Deallocation should not go below zero
        engine.trackDeallocation(bytes: 1000)
        XCTAssertEqual(engine.allocatedBytes, 0)
    }

    func testEngineResetMemoryTracker() throws {
        let engine = try LuaEngine()

        try engine.trackAllocation(bytes: 5000)
        XCTAssertEqual(engine.allocatedBytes, 5000)

        engine.resetMemoryTracker()
        XCTAssertEqual(engine.allocatedBytes, 0)
    }

    // MARK: - ArrayModule Memory Tracking

    func testArrayZerosRespectsMemoryLimit() throws {
        // Each Double is 8 bytes. 100 doubles = 800 bytes.
        // Set limit to 400 bytes (50 doubles max)
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installArrayModule(in: engine)

        // Creating array of 100 elements (800 bytes) should fail
        XCTAssertThrowsError(try engine.run("luaswift.array.zeros({100})")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"), "Error: \(message)")
        }
    }

    func testArrayZerosSucceedsUnderLimit() throws {
        // 10 doubles = 80 bytes, set limit to 200 bytes
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 200))
        ModuleRegistry.installArrayModule(in: engine)

        // Creating array of 10 elements should succeed
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({10})
            return a:size()
        """)

        XCTAssertEqual(result.numberValue, 10)
    }

    func testArrayOnesRespectsMemoryLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installArrayModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.array.ones({100})")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testArrayFullRespectsMemoryLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installArrayModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.array.full({100}, 3.14)")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testArrayLinspaceRespectsMemoryLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installArrayModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.array.linspace(0, 1, 100)")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testArrayRandRespectsMemoryLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installArrayModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.array.random.rand({100})")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testArrayEyeRespectsMemoryLimit() throws {
        // 10x10 = 100 doubles = 800 bytes
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installArrayModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.array.eye(10)")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    // MARK: - LinAlgModule Memory Tracking

    func testLinalgZerosRespectsMemoryLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installLinAlgModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.linalg.zeros(10, 10)")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testLinalgOnesRespectsMemoryLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installLinAlgModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.linalg.ones(10, 10)")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testLinalgEyeRespectsMemoryLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installLinAlgModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.linalg.eye(10)")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testLinalgDiagRespectsMemoryLimit() throws {
        // Creating 20x20 matrix from 20 element vector = 400 doubles = 3200 bytes
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 1600))
        ModuleRegistry.installLinAlgModule(in: engine)

        XCTAssertThrowsError(try engine.run("""
            local v = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20}
            luaswift.linalg.diag(v)
        """)) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    func testLinalgLinspaceRespectsMemoryLimit() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 400))
        ModuleRegistry.installLinAlgModule(in: engine)

        XCTAssertThrowsError(try engine.run("luaswift.linalg.linspace(0, 1, 100)")) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    // MARK: - Multiple Operations

    func testMultipleArrayOperationsRespectCumulativeLimit() throws {
        // Each 10-element array is 80 bytes
        // Set limit to allow 2 arrays but not 3
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 200))
        ModuleRegistry.installArrayModule(in: engine)

        // First two arrays should succeed
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({10})  -- 80 bytes
            local b = luaswift.array.ones({10})   -- 80 bytes (total 160)
            return a:size() + b:size()
        """)

        XCTAssertEqual(result.numberValue, 20)

        // Third array should fail
        XCTAssertThrowsError(try engine.run("""
            luaswift.array.zeros({10})  -- Would exceed 200 byte limit
        """)) { error in
            guard case LuaError.runtimeError(let message) = error else {
                XCTFail("Expected runtimeError")
                return
            }
            XCTAssertTrue(message.contains("Memory limit exceeded"))
        }
    }

    // MARK: - No Limit (Default Behavior)

    func testNoMemoryLimitAllowsLargeAllocations() throws {
        // Default configuration has no limit
        let engine = try LuaEngine()
        ModuleRegistry.installArrayModule(in: engine)

        // Large array should succeed
        let result = try engine.evaluate("""
            local a = luaswift.array.zeros({1000, 100})  -- 100,000 elements = 800KB
            return a:size()
        """)

        XCTAssertEqual(result.numberValue, 100_000)
    }

    // MARK: - Memory Tracking State

    func testAllocatedBytesIsTrackedCorrectly() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 10000))
        ModuleRegistry.installArrayModule(in: engine)

        // Initial state
        XCTAssertEqual(engine.allocatedBytes, 0)

        // After creating array
        try engine.run("""
            test_arr = luaswift.array.zeros({100})  -- 800 bytes
        """)

        XCTAssertEqual(engine.allocatedBytes, 800)
    }

    func testResetTrackerAllowsNewAllocations() throws {
        let engine = try LuaEngine(configuration: .init(sandboxed: true, packagePath: nil, memoryLimit: 500))
        ModuleRegistry.installArrayModule(in: engine)

        // Fill up to limit
        try engine.run("""
            local a = luaswift.array.zeros({50})  -- 400 bytes
        """)

        // Reset tracker
        engine.resetMemoryTracker()
        XCTAssertEqual(engine.allocatedBytes, 0)

        // New allocation should succeed
        let result = try engine.evaluate("""
            local b = luaswift.array.zeros({50})
            return b:size()
        """)

        XCTAssertEqual(result.numberValue, 50)
    }
}
