//
//  BenchmarkTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-04.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

/// Performance benchmark tests comparing Swift-backed modules vs pure Lua implementations.
///
/// These tests use XCTest's `measure` block to collect performance metrics.
/// Run with `swift test --filter BenchmarkTests` to see timing results.
final class BenchmarkTests: XCTestCase {
    var engine: LuaEngine!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        ModuleRegistry.installModules(in: engine)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Geometry Benchmarks

    #if LUASWIFT_NUMERICSWIFT
    func testVec2OperationsBenchmark() throws {
        // Setup: Create vectors
        try engine.run("""
            local geo = luaswift.geometry
            v1 = geo.vec2(3, 4)
            v2 = geo.vec2(1, 2)
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local v3 = v1 + v2
                    local v4 = v1 - v2
                    local d = v1:dot(v2)
                    local len = v1:length()
                    local norm = v1:normalize()
                    return norm.x
                """)
            }
        }
    }

    func testVec3OperationsBenchmark() throws {
        // Setup: Create 3D vectors
        try engine.run("""
            local geo = luaswift.geometry
            v1 = geo.vec3(1, 2, 3)
            v2 = geo.vec3(4, 5, 6)
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local v3 = v1 + v2
                    local cross = v1:cross(v2)
                    local d = v1:dot(v2)
                    local len = v1:length()
                    return cross.z
                """)
            }
        }
    }

    func testQuaternionSlerpBenchmark() throws {
        // Setup: Create quaternions for interpolation
        try engine.run("""
            local geo = luaswift.geometry
            q1 = geo.quaternion(1, 0, 0, 0)  -- identity
            q2 = geo.quaternion(0.7071, 0, 0.7071, 0)  -- 90 degrees around Y
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local result = q1:slerp(q2, 0.5)
                    return result.w
                """)
            }
        }
    }

    func testConvexHullBenchmark() throws {
        // Setup: Generate 100 random points
        try engine.run("""
            math.randomseed(12345)
            points = {}
            for i = 1, 100 do
                points[i] = {x = math.random() * 100, y = math.random() * 100}
            end
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local hull = luaswift.geometry.convex_hull(points)
                    return #hull
                """)
            }
        }
    }

    func testTransform3DBenchmark() throws {
        // Setup: Create transform and vector
        try engine.run("""
            local geo = luaswift.geometry
            t = geo.transform3d():translate(1, 2, 3):rotate_y(0.5):scale(2, 2, 2)
            v = geo.vec3(1, 1, 1)
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local result = t:apply(v)
                    return result.x
                """)
            }
        }
    }
    #endif  // LUASWIFT_NUMERICSWIFT

    // MARK: - Complex Number Benchmarks

    #if LUASWIFT_NUMERICSWIFT
    func testComplexArithmeticBenchmark() throws {
        // Setup: Create complex numbers
        try engine.run("""
            local complex = luaswift.complex
            z1 = complex.new(3, 4)
            z2 = complex.new(1, 2)
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local z3 = z1 + z2
                    local z4 = z1 * z2
                    local z5 = z1 / z2
                    local m = z1:abs()
                    return z3.re
                """)
            }
        }
    }

    func testComplexTrigBenchmark() throws {
        // Setup: Create complex number
        try engine.run("""
            local complex = luaswift.complex
            z = complex.new(1.5, 2.3)
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local s = luaswift.complex.sin(z)
                    local c = luaswift.complex.cos(z)
                    local t = luaswift.complex.tan(z)
                    return s.re
                """)
            }
        }
    }

    func testComplexExpLogBenchmark() throws {
        // Setup: Create complex number
        try engine.run("""
            local complex = luaswift.complex
            z = complex.new(2.0, 1.5)
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local e = luaswift.complex.exp(z)
                    local l = luaswift.complex.log(z)
                    local sq = luaswift.complex.sqrt(z)
                    return e.re
                """)
            }
        }
    }
    #endif  // LUASWIFT_NUMERICSWIFT

    // MARK: - UTF8 Benchmarks

    func testUTF8WidthBenchmark() throws {
        // Setup: Create CJK string
        try engine.run("""
            cjk_string = string.rep("Hello世界", 100)
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    return luaswift.utf8x.width(cjk_string)
                """)
            }
        }
    }

    func testUTF8SubstringBenchmark() throws {
        // Setup: Create Unicode string
        try engine.run("""
            unicode_string = string.rep("Hëllö Wörld ", 50)
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local sub = luaswift.utf8x.sub(unicode_string, 10, 100)
                    return #sub
                """)
            }
        }
    }

    func testUTF8ReverseBenchmark() throws {
        // Setup: Create Unicode string
        try engine.run("""
            unicode_string = string.rep("Unicode文字", 50)
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    return luaswift.utf8x.reverse(unicode_string)
                """)
            }
        }
    }

    // MARK: - String Extension Benchmarks

    func testStringXTrimBenchmark() throws {
        // Setup: Create strings with whitespace
        try engine.run("""
            test_strings = {}
            for i = 1, 100 do
                test_strings[i] = "   " .. string.rep("Hello World", 10) .. "   "
            end
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local results = {}
                    for i, s in ipairs(test_strings) do
                        results[i] = luaswift.stringx.trim(s)
                    end
                    return #results
                """)
            }
        }
    }

    func testStringXSplitBenchmark() throws {
        // Setup: Create CSV-like data
        try engine.run("""
            csv_line = "apple,banana,cherry,date,elderberry,fig,grape,honeydew,kiwi,lemon"
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local parts = luaswift.stringx.split(csv_line, ",")
                    return #parts
                """)
            }
        }
    }

    func testStringXStartsEndsBenchmark() throws {
        // Setup: Create test string
        try engine.run("""
            test_string = "Hello World, this is a test string!"
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local s = luaswift.stringx.startswith(test_string, "Hello")
                    local e = luaswift.stringx.endswith(test_string, "!")
                    return s and e
                """)
            }
        }
    }

    // MARK: - Table Extension Benchmarks

    func testTableXMapBenchmark() throws {
        // Setup: Create numeric array
        try engine.run("""
            numbers = {}
            for i = 1, 1000 do
                numbers[i] = i
            end
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local doubled = luaswift.tablex.map(numbers, function(x) return x * 2 end)
                    return #doubled
                """)
            }
        }
    }

    func testTableXFilterBenchmark() throws {
        // Setup: Create numeric array
        try engine.run("""
            numbers = {}
            for i = 1, 1000 do
                numbers[i] = i
            end
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local evens = luaswift.tablex.filter(numbers, function(x) return x % 2 == 0 end)
                    return #evens
                """)
            }
        }
    }

    func testTableXReduceBenchmark() throws {
        // Setup: Create numeric array
        try engine.run("""
            numbers = {}
            for i = 1, 1000 do
                numbers[i] = i
            end
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local sum = luaswift.tablex.reduce(numbers, function(acc, x) return acc + x end, 0)
                    return sum
                """)
            }
        }
    }

    // MARK: - Math Extension Benchmarks

    func testMathXStatisticsBenchmark() throws {
        // Setup: Create numeric array
        try engine.run("""
            data = {}
            for i = 1, 1000 do
                data[i] = math.random() * 100
            end
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local m = luaswift.mathx.mean(data)
                    local s = luaswift.mathx.std(data)
                    local v = luaswift.mathx.variance(data)
                    return m
                """)
            }
        }
    }

    func testMathXClampLerpBenchmark() throws {
        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local results = {}
                    for i = 1, 100 do
                        local c = luaswift.mathx.clamp(i * 0.5, 10, 90)
                        local l = luaswift.mathx.lerp(0, 100, i / 100)
                        results[i] = c + l
                    end
                    return #results
                """)
            }
        }
    }

    // MARK: - JSON Benchmarks

    func testJSONEncodeBenchmark() throws {
        // Setup: Create complex data structure
        try engine.run("""
            data = {
                name = "Test",
                values = {},
                nested = {
                    a = 1, b = 2, c = 3,
                    deep = {x = true, y = false, z = nil}
                }
            }
            for i = 1, 100 do
                data.values[i] = {id = i, value = math.random()}
            end
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    return luaswift.json.encode(data)
                """)
            }
        }
    }

    func testJSONDecodeBenchmark() throws {
        // Setup: Create JSON string
        try engine.run("""
            json_string = '{"name":"Test","count":100,"items":['
            for i = 1, 99 do
                json_string = json_string .. '{"id":' .. i .. ',"active":true},'
            end
            json_string = json_string .. '{"id":100,"active":true}]}'
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    return luaswift.json.decode(json_string)
                """)
            }
        }
    }

    // MARK: - Linear Algebra Benchmarks

    #if LUASWIFT_NUMERICSWIFT
    func testLinAlgVectorOperationsBenchmark() throws {
        // Setup: Create vectors
        try engine.run("""
            local linalg = luaswift.linalg
            v1 = linalg.vector({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
            v2 = linalg.vector({10, 9, 8, 7, 6, 5, 4, 3, 2, 1})
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local v3 = v1 + v2
                    local v4 = v1 * 2
                    local d = v1:dot(v2)
                    local n = v1:norm()
                    return d
                """)
            }
        }
    }

    func testLinAlgMatrixMultiplyBenchmark() throws {
        // Setup: Create 4x4 matrices
        try engine.run("""
            local linalg = luaswift.linalg
            m1 = linalg.matrix({
                {1, 2, 3, 4},
                {5, 6, 7, 8},
                {9, 10, 11, 12},
                {13, 14, 15, 16}
            })
            m2 = linalg.matrix({
                {16, 15, 14, 13},
                {12, 11, 10, 9},
                {8, 7, 6, 5},
                {4, 3, 2, 1}
            })
        """)

        measure {
            for _ in 0..<500 {
                _ = try? engine.evaluate("""
                    local m3 = m1 * m2
                    return m3:get(1, 1)
                """)
            }
        }
    }
    #endif  // LUASWIFT_NUMERICSWIFT

    // MARK: - Array Module Benchmarks

    #if LUASWIFT_ARRAYSWIFT
    func testArrayCreationBenchmark() throws {
        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local arr = luaswift.array
                    local a1 = arr.zeros({100, 100})
                    local a2 = arr.ones({100, 100})
                    local a3 = arr.arange(1, 10000)
                    return a3:size()
                """)
            }
        }
    }

    func testArrayOperationsBenchmark() throws {
        // Setup: Create arrays
        try engine.run("""
            local arr = luaswift.array
            a1 = arr.arange(1, 1000)
            a2 = arr.arange(1000, 1, -1)
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local a3 = a1 + a2
                    local a4 = a1 * a2
                    local s = a1:sum()
                    local m = a1:mean()
                    return m
                """)
            }
        }
    }
    #endif  // LUASWIFT_ARRAYSWIFT

    // MARK: - Regex Benchmarks

    func testRegexMatchBenchmark() throws {
        // Setup: Create test string
        try engine.run("""
            text = "The quick brown fox jumps over the lazy dog. " ..
                   "Pack my box with five dozen liquor jugs. " ..
                   "How vexingly quick daft zebras jump!"
            text = string.rep(text, 10)
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local matches = luaswift.regex.findall("[a-z]+", text)
                    return #matches
                """)
            }
        }
    }

    func testRegexReplaceBenchmark() throws {
        // Setup: Create test string
        try engine.run("""
            text = "The quick brown fox jumps over the lazy dog."
            text = string.rep(text, 100)
        """)

        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local result = luaswift.regex.replace(text, "\\\\b\\\\w{4}\\\\b", "WORD")
                    return #result
                """)
            }
        }
    }

    // MARK: - MathExpr Benchmarks

    #if LUASWIFT_NUMERICSWIFT
    func testMathExprEvalBenchmark() throws {
        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local mathexpr = luaswift.mathexpr
                    local result = mathexpr.eval("sin(x)^2 + cos(x)^2", {x = 1.5})
                    return result
                """)
            }
        }
    }

    func testMathExprCompileBenchmark() throws {
        // Setup: Compile expression once
        try engine.run("""
            local mathexpr = luaswift.mathexpr
            f = mathexpr.compile("x^3 - 2*x^2 + 3*x - 4")
        """)

        measure {
            for _ in 0..<1000 {
                _ = try? engine.evaluate("""
                    local sum = 0
                    for i = 1, 100 do
                        sum = sum + f(i * 0.1)
                    end
                    return sum
                """)
            }
        }
    }
    #endif  // LUASWIFT_NUMERICSWIFT

    // MARK: - SVG Generation Benchmarks

    func testSVGCreationBenchmark() throws {
        measure {
            for _ in 0..<100 {
                _ = try? engine.evaluate("""
                    local svg = luaswift.svg
                    local drawing = svg.create(800, 600)
                    for i = 1, 100 do
                        drawing:circle(math.random() * 800, math.random() * 600, 10, {fill = "blue"})
                    end
                    return drawing:render()
                """)
            }
        }
    }

    func testSVGComplexSceneBenchmark() throws {
        measure {
            for _ in 0..<50 {
                _ = try? engine.evaluate("""
                    local svg = luaswift.svg
                    local drawing = svg.create(800, 600, {background = "#ffffff"})

                    -- Add rectangles
                    for i = 1, 20 do
                        drawing:rect(i * 35, 50, 30, 100, {fill = "red", stroke = "black"})
                    end

                    -- Add circles
                    for i = 1, 20 do
                        drawing:circle(i * 35 + 15, 250, 15, {fill = "blue"})
                    end

                    -- Add lines
                    for i = 1, 20 do
                        drawing:line(i * 35, 350, i * 35 + 30, 450, {stroke = "green"})
                    end

                    -- Add text
                    for i = 1, 10 do
                        drawing:text(i * 70, 550, "Label " .. i, {["font-size"] = 12})
                    end

                    return drawing:render()
                """)
            }
        }
    }
}
