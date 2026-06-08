//
//  CompiledChunk.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/CompiledChunk.swift
//
//  Context: Provenance-typed container for Lua bytecode. Only
//  LuaEngine.precompile(_:) (LuaEngine+Bytecode.swift) creates instances;
//  the CompiledChunk overloads of LuaEngine.run(_:)/evaluate(_:) consume
//  them after checking the stamped metadata against the running build.
//  Compatibility mismatches surface as LuaError.runtimeError
//  (LuaError.swift). This type supersedes the deprecated raw-Data bytecode
//  API (compile/runBytecode/evaluateBytecode) so arbitrary bytes can no
//  longer reach the Lua loader by accident (issue #9).
//

import Foundation
import CLua

/// Lua bytecode stamped with the provenance metadata of the build that
/// compiled it.
///
/// A `CompiledChunk` is produced by ``LuaEngine/precompile(_:)`` and executed
/// with the `CompiledChunk` overloads of `LuaEngine.run(_:)` and
/// `LuaEngine.evaluate(_:)`. Before any bytes reach the Lua loader, the
/// engine verifies that the chunk's Lua version, `lua_Integer`/`lua_Number`
/// sizes, and byte order match the running build, throwing a descriptive
/// ``LuaError/runtimeError(_:)`` on mismatch.
///
/// ## Persistence
///
/// `CompiledChunk` is `Codable`, so a compiled chunk can be cached to disk
/// (for example with `JSONEncoder`) and decoded in a later launch to skip
/// re-parsing the Lua source. The ``formatVersion`` field allows the encoded
/// representation to evolve safely: chunks encoded by a newer format than
/// this build understands are rejected at execution time.
///
/// ## What this type does — and does not — guarantee
///
/// - **Guaranteed:** the type system ensures that only bytecode produced by
///   this library's own compile step (or decoded from a cache the consumer
///   chose to trust) can be executed, and that stale caches from a different
///   Lua version, word size, or endianness are rejected instead of corrupting
///   the VM. This prevents the accidental-arbitrary-`Data` class of misuse
///   that the deprecated `runBytecode(_:)`/`evaluateBytecode(_:)` allowed.
/// - **Not guaranteed:** there is **no cryptographic integrity** protection
///   of persisted caches. A cache file tampered with on disk remains the
///   consumer's trust boundary — Lua's own bytecode verifier is a no-op, so
///   only store chunk caches in locations untrusted code cannot write to
///   (e.g. the app sandbox), or recompile from source instead.
public struct CompiledChunk: Codable, Equatable, Sendable {

    // MARK: - Current-build provenance

    /// The encoded-representation version this build writes and the highest
    /// it understands.
    ///
    /// **Version history:**
    /// - `1` — initial format (formatVersion, luaVersion, integerSize,
    ///   numberSize, endianness, bytecode).
    /// - `2` — adds the optional `chunkName` field (issue #23). A v1 chunk
    ///   decoded under v2 has `chunkName == nil` (decoded with
    ///   `decodeIfPresent`, so absent keys are silently nil).
    ///
    /// The value is also the **minimum** accepted: a decoded ``formatVersion``
    /// below `1` (producible by a tampered or truncated cache) is rejected,
    /// since no such format ever existed.
    internal static let currentFormatVersion = 2

    /// The Lua version embedded in this LuaSwift build, e.g. `"5.4"`.
    /// Mirrors the `LUA_VERSION_*` compile-time selection (Package.swift).
    internal static let currentLuaVersion: String = {
        #if LUA_VERSION_51
        return "5.1"
        #elseif LUA_VERSION_52
        return "5.2"
        #elseif LUA_VERSION_53
        return "5.3"
        #elseif LUA_VERSION_55
        return "5.5"
        #else
        return "5.4"  // LUA_VERSION_54, the default build
        #endif
    }()

    /// Size of `lua_Integer` in bytes. Bytecode encodes integer constants at
    /// this width, so it must match between compile and load.
    internal static let currentIntegerSize = MemoryLayout<lua_Integer>.size

    /// Size of `lua_Number` in bytes. Bytecode encodes float constants at
    /// this width, so it must match between compile and load.
    internal static let currentNumberSize = MemoryLayout<lua_Number>.size

    /// Host byte order, `"little"` or `"big"`. Bytecode is dumped in host
    /// byte order, so it must match between compile and load.
    internal static let currentEndianness: String =
        (1 as UInt32).littleEndian == 1 ? "little" : "big"

    // MARK: - Stored fields

    /// Version of the encoded representation (for safe future evolution).
    public let formatVersion: Int

    /// Lua version that compiled the bytecode, e.g. `"5.4"`.
    public let luaVersion: String

    /// Size of `lua_Integer` (bytes) in the compiling build.
    public let integerSize: Int

    /// Size of `lua_Number` (bytes) in the compiling build.
    public let numberSize: Int

    /// Byte order of the compiling host, `"little"` or `"big"`.
    public let endianness: String

    /// The raw dumped bytecode. Private so the bytes can only be executed
    /// through ``validatedBytecode()``, which runs both the provenance check
    /// and the Lua binary-signature check before releasing them to the loader.
    private let bytecode: Data

    /// The caller-supplied chunk name from ``LuaEngine/precompile(_:chunkName:)``,
    /// or `nil` when the chunk was compiled without an explicit name.
    ///
    /// This field is **host metadata** — it mirrors the name that was embedded
    /// into the bytecode's `Proto.source` field at compile time and is stored
    /// here for inspection without needing to parse the binary. The traceback
    /// name actually shown by Lua comes from the embedded `Proto.source`;
    /// storing a different value here does not affect traceback output.
    ///
    /// Codable: absent in v1 chunks — decoded as `nil` via `decodeIfPresent`
    /// so old caches remain loadable without a `keyNotFound` error.
    public let chunkName: String?

    /// Explicit keys so the encoded representation is a stable, documented
    /// contract independent of property order or future renames.
    private enum CodingKeys: String, CodingKey {
        case formatVersion
        case luaVersion
        case integerSize
        case numberSize
        case endianness
        case bytecode
        case chunkName
    }

    // MARK: - Creation

    /// Wrap freshly dumped bytecode, stamping the current build's provenance.
    ///
    /// - Parameters:
    ///   - bytecode: The raw bytes produced by `lua_dump`.
    ///   - chunkName: The caller-supplied chunk name used during compilation,
    ///     or `nil` if none was provided. This must match the name that was
    ///     passed to `luaL_loadbuffer` before the dump so that
    ///     ``chunkName`` accurately reflects what is embedded in the bytecode.
    ///
    /// Internal: only ``LuaEngine/precompile(_:chunkName:)`` creates chunks;
    /// consumers persist and restore them via `Codable`.
    internal init(bytecode: Data, chunkName: String? = nil) {
        self.formatVersion = Self.currentFormatVersion
        self.luaVersion = Self.currentLuaVersion
        self.integerSize = Self.currentIntegerSize
        self.numberSize = Self.currentNumberSize
        self.endianness = Self.currentEndianness
        self.bytecode = bytecode
        self.chunkName = chunkName
    }

    // MARK: - Decodable (custom, for v1 forward-compat)

    /// Decode a `CompiledChunk` from a Codable container.
    ///
    /// `chunkName` uses `decodeIfPresent` so that v1 chunks (format version 1,
    /// no `chunkName` key) decode cleanly with `chunkName == nil`. All other
    /// fields were present in v1, so they use the throwing `decode` form.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.formatVersion = try container.decode(Int.self, forKey: .formatVersion)
        self.luaVersion = try container.decode(String.self, forKey: .luaVersion)
        self.integerSize = try container.decode(Int.self, forKey: .integerSize)
        self.numberSize = try container.decode(Int.self, forKey: .numberSize)
        self.endianness = try container.decode(String.self, forKey: .endianness)
        self.bytecode = try container.decode(Data.self, forKey: .bytecode)
        // Optional — absent in v1 chunks; decodeIfPresent returns nil for a
        // missing key instead of throwing keyNotFound.
        self.chunkName = try container.decodeIfPresent(String.self, forKey: .chunkName)
    }

    // MARK: - Compatibility validation

    /// Throw a descriptive ``LuaError/runtimeError(_:)`` unless this chunk's
    /// provenance matches the running build. Called by the engine before any
    /// bytecode byte reaches the Lua loader.
    internal func validateCompatibleWithCurrentBuild() throws {
        if formatVersion < 1 {
            throw LuaError.runtimeError(
                "CompiledChunk has unrecognized format version \(formatVersion) "
                + "(minimum 1)")
        }
        if formatVersion > Self.currentFormatVersion {
            throw LuaError.runtimeError(
                "CompiledChunk format version \(formatVersion) is newer than "
                + "this LuaSwift build understands (\(Self.currentFormatVersion)); "
                + "recompile the source with precompile(_:)")
        }
        if luaVersion != Self.currentLuaVersion {
            throw LuaError.runtimeError(
                "CompiledChunk was compiled for Lua \(luaVersion), "
                + "but the engine is running Lua \(Self.currentLuaVersion); "
                + "recompile the source with precompile(_:)")
        }
        if integerSize != Self.currentIntegerSize {
            throw LuaError.runtimeError(
                "CompiledChunk was compiled with \(integerSize)-byte Lua integers, "
                + "but the engine uses \(Self.currentIntegerSize)-byte integers; "
                + "recompile the source with precompile(_:)")
        }
        if numberSize != Self.currentNumberSize {
            throw LuaError.runtimeError(
                "CompiledChunk was compiled with \(numberSize)-byte Lua numbers, "
                + "but the engine uses \(Self.currentNumberSize)-byte numbers; "
                + "recompile the source with precompile(_:)")
        }
        if endianness != Self.currentEndianness {
            throw LuaError.runtimeError(
                "CompiledChunk was compiled on a \(endianness)-endian host, "
                + "but the engine is running on a \(Self.currentEndianness)-endian host; "
                + "recompile the source with precompile(_:)")
        }
    }

    /// The first four bytes of every Lua binary chunk — `"\x1bLua"`, the value
    /// of Lua's `LUA_SIGNATURE` macro. A chunk that does not begin with these
    /// bytes is Lua *source* text, not dumped bytecode.
    private static let luaSignature: [UInt8] = [0x1b, 0x4c, 0x75, 0x61]

    /// The single choke point through which bytecode reaches the Lua loader.
    ///
    /// Runs **both** ``validateCompatibleWithCurrentBuild()`` (provenance) and
    /// the Lua binary-signature check before returning the bytes. The signature
    /// gate closes a hole on the Lua 5.1 load path, where the loader accepts
    /// text chunks: without it, a chunk decoded from hostile JSON whose
    /// `bytecode` is plain Lua source — with matching 5.1 provenance — would be
    /// compiled and executed as source. Requiring the `\x1bLua` header means
    /// only genuine dumped bytecode is ever loaded, on every Lua version.
    ///
    /// - Returns: The validated bytecode, safe to hand to the loader.
    /// - Throws: `LuaError.runtimeError` if the provenance does not match the
    ///   running build; `LuaError.syntaxError` if the bytes are not a binary
    ///   chunk.
    internal func validatedBytecode() throws -> Data {
        try validateCompatibleWithCurrentBuild()
        if !bytecode.starts(with: Self.luaSignature) {
            throw LuaError.syntaxError("expected binary bytecode chunk")
        }
        return bytecode
    }
}
