//
//  LuaEngine+Bytecode.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngine+Bytecode.swift
//
//  Context: Bytecode concern of LuaEngine. precompile(_:chunkName:) produces
//  provenance-typed CompiledChunk values (CompiledChunk.swift) that the
//  run(_:)/evaluate(_:) overloads here validate before loading; the
//  deprecated raw-Data compile/runBytecode/evaluateBytecode API is kept
//  alongside until removal (issue #9). All paths funnel through
//  loadAndExecuteBytecode, which arms the compositor hook
//  (LuaEngine+Execution.swift, armCompositorHook) and converts results
//  via valueFromStack (LuaEngine+Bridging.swift). The chunk-name embedding
//  for bytecode happens in compileSource (before lua_dump) via the shared
//  loadSourceChunk helper in LuaEngine+Execution.swift — for binary chunks,
//  Lua's loader ignores the load-time name and reads it from Proto.source,
//  so embedding at compile time is the only effective mechanism (#23).
//

import Foundation
import CLua

extension LuaEngine {

    // MARK: - Bytecode

    /// Precompile Lua source code into a provenance-typed ``CompiledChunk``.
    ///
    /// Use this to cache compiled Lua expressions and avoid repeated parsing
    /// overhead. The resulting chunk is executed with the `CompiledChunk`
    /// overloads of `run(_:)`/`evaluate(_:)`, which verify
    /// the chunk's stamped metadata — Lua version, `lua_Integer`/`lua_Number`
    /// sizes, and byte order — against the running build before any bytes
    /// reach the Lua loader. `CompiledChunk` is `Codable`, so chunks can be
    /// persisted across launches; see ``CompiledChunk`` for the trust
    /// boundary of persisted caches.
    ///
    /// ## Chunk names and bytecode tracebacks
    ///
    /// When `chunkName` is provided, LuaSwift embeds `"@" + chunkName` into the
    /// bytecode's `Proto.source` field **before** `lua_dump`. This is the only
    /// way to influence traceback output for binary chunks: Lua's loader ignores
    /// the name argument passed to `lua_load`/`luaL_loadbuffer` for binary
    /// chunks — it reads the name directly from the embedded `Proto.source`.
    /// Therefore embedding at compile time (here) is mandatory; passing a name
    /// at load time is cosmetic only for binary chunks.
    ///
    /// The `@`-prefix rule (tail truncation at `LUA_IDSIZE` = 60 bytes) is the
    /// same convention as ``run(_:chunkName:)`` — see that method for details.
    ///
    /// The `debug` info (including `source`) is preserved in the dump — `strip`
    /// is passed as `0` on Lua 5.3+ and the 3-arg `lua_dump` on 5.1/5.2
    /// retains debug info by default.
    ///
    /// - Parameters:
    ///   - code: Valid Lua source code to compile.
    ///   - chunkName: An optional caller-supplied name embedded into the
    ///     bytecode at compile time. When `nil`, the source string itself is
    ///     used as the name (same as `luaL_loadstring`), producing the standard
    ///     `[string "…"]` traceback form with no behavior change from pre-#23.
    /// - Returns: The compiled chunk, stamped with this build's provenance.
    /// - Throws: `LuaError.syntaxError` if the source has syntax errors,
    ///   `LuaError.runtimeError` if the bytecode dump fails
    public func precompile(_ code: String, chunkName: String? = nil) throws -> CompiledChunk {
        CompiledChunk(bytecode: try compileSource(code, chunkName: chunkName), chunkName: chunkName)
    }

    /// Execute a precompiled chunk without returning a result.
    ///
    /// The chunk's provenance metadata is validated against the running build
    /// first; a chunk compiled by a different Lua version, word size, or byte
    /// order is rejected with a descriptive ``LuaError/runtimeError(_:)``
    /// instead of being fed to the Lua loader. The bytes must also carry Lua's
    /// binary signature (`\u{1b}Lua`); a chunk whose payload is plain source
    /// text is rejected with `LuaError.syntaxError` rather than executed.
    ///
    /// The instruction-count limit (set via ``setInstructionLimit(_:)``)
    /// applies on this path exactly as it does for source execution.
    ///
    /// - Parameter chunk: A chunk produced by ``precompile(_:)`` (possibly
    ///   decoded from a persisted cache)
    /// - Throws: `LuaError.runtimeError` if the chunk's provenance does not
    ///   match the running build or on runtime failure,
    ///   `LuaError.syntaxError` if the bytecode fails to load,
    ///   `LuaError.instructionLimitExceeded` if the instruction limit is tripped
    public func run(_ chunk: CompiledChunk) throws {
        let bytecode = try chunk.validatedBytecode()
        _ = try loadAndExecuteBytecode(bytecode, returningValue: false)
    }

    /// Execute a precompiled chunk and return the result.
    ///
    /// The chunk's provenance metadata is validated against the running build
    /// first; a chunk compiled by a different Lua version, word size, or byte
    /// order is rejected with a descriptive ``LuaError/runtimeError(_:)``
    /// instead of being fed to the Lua loader. The bytes must also carry Lua's
    /// binary signature (`\u{1b}Lua`); a chunk whose payload is plain source
    /// text is rejected with `LuaError.syntaxError` rather than executed.
    ///
    /// The instruction-count limit (set via ``setInstructionLimit(_:)``)
    /// applies on this path exactly as it does for source evaluation.
    ///
    /// - Parameter chunk: A chunk produced by ``precompile(_:)`` (possibly
    ///   decoded from a persisted cache)
    /// - Returns: The result of the execution as a ``LuaValue``
    /// - Throws: `LuaError.runtimeError` if the chunk's provenance does not
    ///   match the running build or on runtime failure,
    ///   `LuaError.syntaxError` if the bytecode fails to load,
    ///   `LuaError.instructionLimitExceeded` if the instruction limit is tripped
    public func evaluate(_ chunk: CompiledChunk) throws -> LuaValue {
        let bytecode = try chunk.validatedBytecode()
        return try loadAndExecuteBytecode(bytecode, returningValue: true)
    }

    /// Precompile Lua source code to bytecode.
    ///
    /// Use this to cache compiled Lua expressions and avoid repeated parsing overhead.
    /// The resulting `Data` can be passed to ``runBytecode(_:)`` or ``evaluateBytecode(_:)``.
    ///
    /// - Important: Bytecode is **not portable**. It is only valid for the same
    ///   Lua version and CPU architecture/word-size/endianness that produced it,
    ///   and ``runBytecode(_:)``/``evaluateBytecode(_:)`` perform no verification of
    ///   the chunk's provenance — feeding them bytecode from an untrusted source
    ///   (or compiled by a different Lua build) is unsafe and can corrupt the VM.
    ///   Treat compiled bytecode as an in-process / same-build cache only; recompile
    ///   from source after a version or platform change.
    ///
    /// - Parameter code: Valid Lua source code to compile
    /// - Returns: Compiled bytecode as `Data`
    /// - Throws: `LuaError.syntaxError` if the source has syntax errors,
    ///   `LuaError.runtimeError` if the bytecode dump fails
    @available(*, deprecated, message: """
        Use precompile(_:) instead: it returns a provenance-typed \
        CompiledChunk that run(_:)/evaluate(_:) validate before loading. \
        Raw bytecode Data carries no provenance, and Lua's bytecode \
        verifier is a no-op, so loading mismatched or crafted bytes can \
        corrupt the VM.
        """)
    public func compile(_ code: String) throws -> Data {
        try compileSource(code)
    }

    /// Compile Lua source and dump it to bytecode. Shared machinery behind
    /// ``precompile(_:chunkName:)`` and the deprecated ``compile(_:)``.
    ///
    /// Applies the same `"@" + chunkName` name-prefix convention as the source
    /// execution path, but here the name is embedded into `Proto.source` inside
    /// the dump. That embedding is what makes the name appear in tracebacks when
    /// the bytecode is later loaded and run — the load-time name arg for binary
    /// chunks is ignored by Lua's loader.
    ///
    /// - Parameters:
    ///   - code: Lua source text to compile.
    ///   - chunkName: Optional chunk name. When `nil`, the source string itself
    ///     is used (matches `luaL_loadstring`); when non-nil, `"@" + chunkName`
    ///     is used so `short_src` applies tail truncation.
    private func compileSource(_ code: String, chunkName: String? = nil) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Load source — applies the same name-prefix convention as run/evaluate
        // so the name is embedded in Proto.source before lua_dump.
        // luaL_loadstring(L, s) == luaL_loadbuffer(L, s, len, s), so passing
        // the source as name when chunkName is nil is an exact behavioral match.
        let loadResult = loadSourceChunk(L, code: code, chunkName: chunkName)
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Collect dumped bytes via lua_Writer into a heap-allocated Data box.
        // Pass the box as ud pointer (unretained — box outlives the dump call).
        let box = BytecodeBuffer()
        let ud = Unmanaged.passUnretained(box).toOpaque()
        // The `strip` 4th argument was added in Lua 5.3; 5.1/5.2 take 3 args.
        #if LUA_VERSION_51 || LUA_VERSION_52
        let dumpResult = lua_dump(L, luaBytecodeWriter, ud)
        #else
        let dumpResult = lua_dump(L, luaBytecodeWriter, ud, 0)
        #endif

        // Pop the function regardless of dump result
        lua_pop(L, 1)

        if dumpResult != 0 {
            throw LuaError.runtimeError("bytecode dump failed")
        }

        return box.data
    }

    /// Execute precompiled Lua bytecode without returning a result.
    ///
    /// The instruction-count limit (set via ``setInstructionLimit(_:)``) applies
    /// on this path exactly as it does for ``run(_:)``.
    ///
    /// - Parameter bytecode: Bytecode previously produced by ``compile(_:)``
    /// - Throws: `LuaError.syntaxError` if the bytecode is corrupt or invalid,
    ///   `LuaError.runtimeError` on runtime failure,
    ///   `LuaError.instructionLimitExceeded` if the instruction limit is tripped
    @available(*, deprecated, message: """
        Use run(_:) with a CompiledChunk from precompile(_:) instead. \
        Accepting raw Data bypasses provenance validation, and Lua's \
        bytecode verifier is a no-op, so crafted or mismatched bytes can \
        corrupt the VM.
        """)
    public func runBytecode(_ bytecode: Data) throws {
        _ = try loadAndExecuteBytecode(bytecode, returningValue: false)
    }

    /// Execute precompiled Lua bytecode and return the result.
    ///
    /// The instruction-count limit (set via ``setInstructionLimit(_:)``) applies
    /// on this path exactly as it does for source evaluation.
    ///
    /// - Parameter bytecode: Bytecode previously produced by ``compile(_:)``
    /// - Returns: The result of the execution as a ``LuaValue``
    /// - Throws: `LuaError.syntaxError` if the bytecode is corrupt or invalid,
    ///   `LuaError.runtimeError` on runtime failure,
    ///   `LuaError.instructionLimitExceeded` if the instruction limit is tripped
    @available(*, deprecated, message: """
        Use evaluate(_:) with a CompiledChunk from precompile(_:) instead. \
        Accepting raw Data bypasses provenance validation, and Lua's \
        bytecode verifier is a no-op, so crafted or mismatched bytes can \
        corrupt the VM.
        """)
    public func evaluateBytecode(_ bytecode: Data) throws -> LuaValue {
        try loadAndExecuteBytecode(bytecode, returningValue: true)
    }

    /// Load dumped bytecode and execute it under the instruction hook.
    ///
    /// Shared plumbing behind every bytecode execution entry point — the
    /// `CompiledChunk` overloads of `run(_:)`/`evaluate(_:)` (after their
    /// provenance check) and the deprecated raw-`Data`
    /// `runBytecode(_:)`/`evaluateBytecode(_:)`.
    ///
    /// - Parameters:
    ///   - bytecode: Dumped bytecode to load (mode "b") and call
    ///   - returningValue: When `true`, executes with `nresults = 1` and
    ///     returns the top-of-stack value; when `false`, discards results
    ///     and returns `.nil`
    private func loadAndExecuteBytecode(_ bytecode: Data, returningValue: Bool) throws -> LuaValue {
        lock.lock()
        defer { lock.unlock() }

        guard let L = L else {
            throw LuaError.initializationFailed
        }

        // Reset per-run state so a prior cancel/limit abort does not persist.
        abortReason.store(0, ordering: .releasing)
        instructionAccumulator = 0

        // Clear any previous write error
        lastWriteError = nil

        // Load bytecode — mode "b" accepts binary only
        let loadResult = bytecode.withUnsafeBytes { raw -> Int32 in
            guard let ptr = raw.baseAddress else { return LUA_ERRSYNTAX }
            // luaL_loadbufferx (with mode) was added in Lua 5.2; 5.1 has only
            // luaL_loadbuffer, which accepts both text and binary chunks.
            #if LUA_VERSION_51
            return luaL_loadbuffer(L, ptr.assumingMemoryBound(to: CChar.self),
                                   bytecode.count, "=bytecode")
            #else
            return luaL_loadbufferx(L, ptr.assumingMemoryBound(to: CChar.self),
                                    bytecode.count, "=bytecode", "b")
            #endif
        }
        if loadResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)
            throw LuaError.syntaxError(message)
        }

        // Arm the compositor hook and install TLS so the C callback can find us.
        let previousEngine = setAsCurrentEngine()
        defer { restoreCurrentEngine(previousEngine) }
        armCompositorHook(on: L)

        // Execute, keeping one return value only when the caller wants it
        let callResult = lua_pcall(L, 0, returningValue ? 1 : 0, 0)
        if callResult != LUA_OK {
            let message = lua_tostring(L, -1).map { String(cString: $0) } ?? "Unknown error"
            lua_pop(L, 1)

            #if DEBUG
            assert(lua_gettop(L) == 0, "Stack not clean after pcall abort in bytecode path: top=\(lua_gettop(L))")
            #endif

            if let writeError = lastWriteError {
                lastWriteError = nil
                throw writeError
            }

            throw errorFromCode(callResult, message: message)
        }

        guard returningValue else { return .nil }

        // Convert result
        let result = valueFromStack(at: -1)
        lua_pop(L, 1)
        return result
    }
}

// MARK: - Bytecode Writer Support

/// Heap-allocated buffer used to accumulate bytes during `lua_dump`.
///
/// Passed as the `ud` pointer to the `lua_Writer` callback via `Unmanaged`.
private final class BytecodeBuffer {
    var data = Data()
}

/// `lua_Writer` callback that appends each chunk emitted by `lua_dump` into a `BytecodeBuffer`.
///
/// The `ud` parameter is an unretained `Unmanaged<BytecodeBuffer>` raw pointer created in
/// `LuaEngine.compile(_:)`.  Returns 0 on success (Lua convention).
private func luaBytecodeWriter(
    _ L: OpaquePointer?,
    _ p: UnsafeRawPointer?,
    _ sz: Int,
    _ ud: UnsafeMutableRawPointer?
) -> Int32 {
    guard let p = p, sz > 0, let ud = ud else { return 0 }
    let box = Unmanaged<BytecodeBuffer>.fromOpaque(ud).takeUnretainedValue()
    box.data.append(p.assumingMemoryBound(to: UInt8.self), count: sz)
    return 0
}
