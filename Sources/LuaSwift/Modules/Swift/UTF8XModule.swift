//
//  UTF8XModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-02.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Swift-backed UTF-8 string utilities module for LuaSwift.
///
/// Provides Unicode-aware string operations including display width calculation,
/// character-based substring extraction, reversing, case conversion, and iteration.
/// All operations are optimized using Swift's native Unicode handling.
///
/// ## Lua API
///
/// ```lua
/// local utf8x = require("luaswift.utf8x")
///
/// -- Display width (CJK-aware)
/// local w = utf8x.width("Hello世界")  -- 9 (5 + 2×2)
///
/// -- Character-based substring
/// local s = utf8x.sub("Hello世界", 6, 7)  -- "世界"
/// local s2 = utf8x.sub("Hello", -2, -1)   -- "lo"
///
/// -- Reverse string
/// local rev = utf8x.reverse("Hello世界")  -- "界世olleH"
///
/// -- Case conversion
/// local upper = utf8x.upper("café")       -- "CAFÉ"
/// local lower = utf8x.lower("CAFÉ")       -- "café"
///
/// -- Character count
/// local len = utf8x.len("Hello世界")      -- 7
///
/// -- Iterate characters
/// for char in utf8x.chars("Hello世界") do
///     print(char)
/// end
/// ```
public struct UTF8XModule: LuaSwiftModule {

  /// Register the UTF-8 extension module with a LuaEngine.
  ///
  /// This creates a global table `luaswift` with a nested `utf8x` table containing
  /// Unicode-aware string manipulation functions.
  ///
  /// - Parameter engine: The Lua engine to register with
  /// - Throws: An error if the module's Lua setup code fails to run.
  public static func install(in engine: LuaEngine) throws {
    // Register all functions
    engine.registerFunction(name: "_luaswift_utf8x_width", callback: widthCallback)
    engine.registerFunction(name: "_luaswift_utf8x_sub", callback: subCallback)
    engine.registerFunction(name: "_luaswift_utf8x_reverse", callback: reverseCallback)
    engine.registerFunction(name: "_luaswift_utf8x_upper", callback: upperCallback)
    engine.registerFunction(name: "_luaswift_utf8x_lower", callback: lowerCallback)
    engine.registerFunction(name: "_luaswift_utf8x_len", callback: lenCallback)
    engine.registerFunction(name: "_luaswift_utf8x_chars", callback: charsCallback)
    engine.registerFunction(name: "_luaswift_utf8x_slice", callback: sliceCallback)

    // Set up the luaswift.utf8x namespace
    try engine.run(
      """
      if not luaswift then luaswift = {} end

      -- Store references before cleanup
      local width_fn = _luaswift_utf8x_width
      local sub_fn = _luaswift_utf8x_sub
      local reverse_fn = _luaswift_utf8x_reverse
      local upper_fn = _luaswift_utf8x_upper
      local lower_fn = _luaswift_utf8x_lower
      local len_fn = _luaswift_utf8x_len
      local chars_fn = _luaswift_utf8x_chars
      local slice_fn = _luaswift_utf8x_slice

      luaswift.utf8x = {
          width = width_fn,
          sub = sub_fn,
          reverse = reverse_fn,
          upper = upper_fn,
          lower = lower_fn,
          len = len_fn,
          chars = chars_fn,
          slice = slice_fn,

          -- import() extends the utf8 library (if it exists)
          -- Note: utf8 library was added in Lua 5.3, doesn't exist in 5.1/5.2
          import = function()
              if utf8 then
                  utf8.width = width_fn
                  utf8.sub = sub_fn
                  utf8.reverse = reverse_fn
                  utf8.upper = upper_fn
                  utf8.lower = lower_fn
                  -- Note: utf8.len already exists in Lua, our version is compatible
                  -- utf8.len = len_fn
                  utf8.chars = chars_fn
                  utf8.slice = slice_fn
              end
          end
      }

      -- Create top-level global alias
      utf8x = luaswift.utf8x

      -- Clean up temporary globals
      _luaswift_utf8x_width = nil
      _luaswift_utf8x_sub = nil
      _luaswift_utf8x_reverse = nil
      _luaswift_utf8x_upper = nil
      _luaswift_utf8x_lower = nil
      _luaswift_utf8x_len = nil
      _luaswift_utf8x_chars = nil
      _luaswift_utf8x_slice = nil
      package.loaded["luaswift.utf8x"] = luaswift.utf8x
      """)
  }

  /// Deprecated alias for ``install(in:)`` that swallows setup failures.
  ///
  /// - Parameter engine: The Lua engine to register with
  @available(*, deprecated, message: "Use install(in:) which surfaces setup failures; register(in:) swallows them.")
  public static func register(in engine: LuaEngine) {
    do { try install(in: engine) } catch {
      #if DEBUG
        print("[LuaSwift] UTF8XModule setup failed: \(error)")
      #endif
    }
  }

  // MARK: - Display Width

  /// Calculate the display width of a Unicode scalar.
  ///
  /// Uses efficient range checks for wide character detection. Wide characters
  /// (CJK ideographs, full-width characters, emoji) return 2, others return 1.
  ///
  /// - Parameter scalar: The Unicode scalar to measure
  /// - Returns: Display width (1 or 2)
  private static func charWidth(_ scalar: Unicode.Scalar) -> Int {
    let codepoint = scalar.value

    // CJK Unified Ideographs
    if (0x4E00...0x9FFF).contains(codepoint) {
      return 2
    }

    // CJK Extension A
    if (0x3400...0x4DBF).contains(codepoint) {
      return 2
    }

    // CJK Compatibility Ideographs
    if (0xF900...0xFAFF).contains(codepoint) {
      return 2
    }

    // CJK Extension B
    if (0x20000...0x2A6DF).contains(codepoint) {
      return 2
    }

    // CJK Extension C
    if (0x2A700...0x2B73F).contains(codepoint) {
      return 2
    }

    // CJK Extension D
    if (0x2B740...0x2B81F).contains(codepoint) {
      return 2
    }

    // CJK Extension E
    if (0x2B820...0x2CEAF).contains(codepoint) {
      return 2
    }

    // CJK Extension F
    if (0x2CEB0...0x2EBEF).contains(codepoint) {
      return 2
    }

    // Hangul Syllables
    if (0xAC00...0xD7AF).contains(codepoint) {
      return 2
    }

    // Hiragana and Katakana
    if (0x3040...0x30FF).contains(codepoint) {
      return 2
    }

    // Full-width ASCII variants
    if (0xFF01...0xFF60).contains(codepoint) {
      return 2
    }

    // Emoji and symbols (simplified ranges)
    if (0x1F300...0x1F9FF).contains(codepoint) {
      return 2
    }

    // Emoticons
    if (0x1F600...0x1F64F).contains(codepoint) {
      return 2
    }

    // Miscellaneous Symbols and Pictographs
    if (0x1F680...0x1F6FF).contains(codepoint) {
      return 2
    }

    // Default to single width
    return 1
  }

  private static func widthCallback(_ args: [LuaValue]) throws -> LuaValue {
    guard let str = args.first?.stringValue else {
      throw LuaError.callbackError("width requires a string argument")
    }

    var totalWidth = 0
    for scalar in str.unicodeScalars {
      totalWidth += charWidth(scalar)
    }

    return .number(Double(totalWidth))
  }

  // MARK: - Substring

  private static func subCallback(_ args: [LuaValue]) throws -> LuaValue {
    guard args.count >= 2 else {
      throw LuaError.callbackError("sub requires at least 2 arguments (string, i, [j])")
    }

    guard let str = args[0].stringValue else {
      throw LuaError.callbackError("sub requires a string as first argument")
    }

    guard let i = args[1].intValue else {
      throw LuaError.callbackError("sub requires an integer as second argument")
    }

    // Convert to array of characters for index-based access
    let chars = Array(str)
    let len = chars.count

    // Handle negative indices (from end)
    let startIndex = i < 0 ? max(0, len + i) : max(0, min(i - 1, len))

    // Default j to end of string
    let j: Int
    if args.count >= 3, let jValue = args[2].intValue {
      j = jValue < 0 ? max(0, len + jValue + 1) : min(jValue, len)
    } else {
      j = len
    }

    // Ensure valid range
    guard startIndex < len && j > 0 && startIndex < j else {
      return .string("")
    }

    let endIndex = min(j, len)
    let substring = String(chars[startIndex..<endIndex])

    return .string(substring)
  }

  // MARK: - Reverse

  private static func reverseCallback(_ args: [LuaValue]) throws -> LuaValue {
    guard let str = args.first?.stringValue else {
      throw LuaError.callbackError("reverse requires a string argument")
    }

    // Swift's native Unicode handling correctly reverses by character
    let reversed = String(str.reversed())
    return .string(reversed)
  }

  // MARK: - Case Conversion

  private static func upperCallback(_ args: [LuaValue]) throws -> LuaValue {
    guard let str = args.first?.stringValue else {
      throw LuaError.callbackError("upper requires a string argument")
    }

    // Use Foundation's localized uppercase (handles Unicode properly)
    let upper = str.uppercased()
    return .string(upper)
  }

  private static func lowerCallback(_ args: [LuaValue]) throws -> LuaValue {
    guard let str = args.first?.stringValue else {
      throw LuaError.callbackError("lower requires a string argument")
    }

    // Use Foundation's localized lowercase (handles Unicode properly)
    let lower = str.lowercased()
    return .string(lower)
  }

  // MARK: - Length

  private static func lenCallback(_ args: [LuaValue]) throws -> LuaValue {
    guard let str = args.first?.stringValue else {
      throw LuaError.callbackError("len requires a string argument")
    }

    // Count characters, not bytes
    let len = str.count
    return .number(Double(len))
  }

  // MARK: - Character Iterator

  private static func charsCallback(_ args: [LuaValue]) throws -> LuaValue {
    guard let str = args.first?.stringValue else {
      throw LuaError.callbackError("chars requires a string argument")
    }

    // Return array of individual characters
    let chars = str.map { String($0) }
    let luaChars = chars.map { LuaValue.string($0) }

    return .array(luaChars)
  }

  // MARK: - Slice

  /// Extract a Unicode-aware slice using Python-style start/stop/step semantics.
  ///
  /// Indices are 1-based (Lua convention). Negative indices count from the end.
  /// All indexing operates on Unicode extended grapheme clusters (characters),
  /// not bytes. `stop` is inclusive; `step` defaults to 1.
  private static func sliceCallback(_ args: [LuaValue]) throws -> LuaValue {
    guard let str = args.first?.stringValue else {
      throw LuaError.callbackError("utf8x.slice requires a string as first argument")
    }
    let chars = Array(str)  // Array of Character (grapheme clusters)
    let len = chars.count
    guard len > 0 else { return .string("") }

    let step = args.count >= 4 ? (args[3].intValue ?? 1) : 1
    guard step != 0 else {
      throw LuaError.callbackError("utf8x.slice: step cannot be zero")
    }

    let (start, stop) = StringXModule.resolveSliceIndices(
      rawStart: args.count >= 2 ? args[1].intValue : nil,
      rawStop: args.count >= 3 ? args[2].intValue : nil,
      len: len, step: step)

    var result: [Character] = []
    if step > 0 {
      var i = start
      while i < stop {
        result.append(chars[i])
        i += step
      }
    } else {
      var i = start
      while i > stop {
        result.append(chars[i])
        i += step
      }
    }
    return .string(String(result))
  }
}
