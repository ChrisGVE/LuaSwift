//
//  LuaEngineConfiguration.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-06-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//
//  Location: Sources/LuaSwift/LuaEngineConfiguration.swift
//
//  Context: Value-type options consumed once by LuaEngine.init
//  (LuaEngine.swift) when creating the Lua state. `sandboxed` and
//  `packagePath` drive the sandbox setup (LuaEngine+Sandbox.swift),
//  `vmMemoryLimit` selects the custom accounting allocator
//  (LuaEngine+VMAllocator.swift), and `memoryLimit` bounds Swift-module
//  allocations tracked via LuaEngine.trackAllocation(bytes:)
//  (LuaEngine.swift).
//

import Foundation

/// Configuration options for the Lua engine.
///
/// Use this structure to customize the behavior of ``LuaEngine``.
/// The most common use case is choosing between sandboxed (safe) and
/// unrestricted (full access) modes.
///
/// ## Creating a Configuration
///
/// ```swift
/// // Use the default sandboxed configuration
/// let engine1 = try LuaEngine()
///
/// // Or explicitly specify configuration
/// let config = LuaEngineConfiguration(
///     sandboxed: true,
///     packagePath: "/path/to/lua/modules",
///     memoryLimit: 0
/// )
/// let engine2 = try LuaEngine(configuration: config)
/// ```
///
/// ## Sandboxing
///
/// When ``sandboxed`` is `true` (the default), the following functions are disabled:
/// - `os.execute`, `os.exit`, `os.remove`, `os.rename`, `os.tmpname`, `os.getenv`, `os.setlocale`
/// - `io.*` (all IO functions)
/// - `debug.*` (all debug functions)
/// - `loadfile`, `dofile`, `load`, `loadstring`
/// - `package.loadlib` (dynamic library loading)
///
/// Additionally, the `require()` system is hardened:
/// - `package.loaded.io` and `package.loaded.debug` are cleared to prevent bypass via `require()`
/// - File-based `package.searchers` are removed, keeping only the preload searcher
/// - `package.path` and `package.cpath` are cleared (unless `packagePath` is set)
///
/// Safe libraries remain available: `math`, `string`, `table`, `coroutine`, `utf8`
public struct LuaEngineConfiguration {
    /// Whether to remove dangerous functions (os.execute, io.*, etc.)
    ///
    /// When `true`, potentially dangerous functions that could access the
    /// filesystem or execute system commands are removed from the Lua environment.
    /// This is recommended for running untrusted code.
    ///
    /// Default: `true`
    public var sandboxed: Bool

    /// Custom package path for `require()` statements.
    ///
    /// If set, this path is prepended to Lua's package.path, allowing
    /// `require()` to find Lua modules in the specified directory.
    ///
    /// Example: Setting to `"/app/lua"` allows `require("mymodule")` to
    /// find `/app/lua/mymodule.lua`.
    ///
    /// Default: `nil` (use Lua's default package path)
    public var packagePath: String?

    /// Memory limit in bytes for Swift module allocations (0 = unlimited).
    ///
    /// When set to a positive value, limits memory allocated by Swift-backed
    /// modules such as `array`, `linalg`, `plot`, etc. Exceeding this limit
    /// causes those allocations to fail with a memory error.
    ///
    /// - Important: This limit applies **only** to Swift module allocations
    ///   (tracked via ``LuaEngine/trackAllocation(bytes:)``), **not** to Lua VM
    ///   allocations. Lua strings, tables, and other Lua-native objects are not
    ///   tracked by this limit. To bound total Lua VM memory, set
    ///   ``vmMemoryLimit``, which installs a custom allocator.
    ///
    /// - Note: Each `Double` in array modules consumes 8 bytes. A 1000-element
    ///   array requires approximately 8KB of tracked memory.
    ///
    /// Default: `0` (unlimited)
    public var memoryLimit: Int

    /// Ceiling in bytes on **total Lua VM allocation** (0 = disabled).
    ///
    /// When set to a positive value, the engine creates its Lua state with a
    /// custom `lua_Alloc` allocator that accounts every byte the VM allocates
    /// (strings, tables, closures, userdata, internal structures). Any
    /// allocation growth that would push the total beyond this ceiling is
    /// denied; Lua sees an allocation failure and the running script fails
    /// with ``LuaError/memoryError(_:)``. Shrinks and frees are always allowed,
    /// per the Lua allocator contract.
    ///
    /// This **complements** (does not replace) ``memoryLimit``: `memoryLimit`
    /// bounds buffers allocated by Swift-backed modules, while `vmMemoryLimit`
    /// bounds the Lua VM itself. It also complements
    /// ``LuaEngine/setInstructionLimit(_:)``, which is a CPU-bound control
    /// only: a single VM instruction calling a C function — for example
    /// `string.rep('A', 1e9)` — is never interrupted by the instruction hook,
    /// but its ~1 GB allocation is denied by this limit (issue #11).
    ///
    /// - Important: Choose a limit with enough headroom for the standard
    ///   libraries and your scripts' working set. Engine initialization itself
    ///   needs a few hundred kilobytes; a limit below that makes
    ///   ``LuaEngine/init(configuration:)`` throw cleanly
    ///   (``LuaError/initializationFailed`` or ``LuaError/memoryError(_:)``).
    ///   As a rule of thumb, use at least 1 MB.
    ///
    /// Default: `0` (disabled — the state is created with `luaL_newstate`,
    /// exactly as before this option existed)
    public var vmMemoryLimit: Int

    /// Default configuration with sandboxing enabled.
    ///
    /// This is the recommended configuration for most use cases.
    /// Dangerous functions are disabled but all safe standard libraries
    /// are available. Neither memory limit is set (`memoryLimit` and
    /// ``vmMemoryLimit`` are both `0`).
    public static let `default` = LuaEngineConfiguration(
        sandboxed: true,
        packagePath: nil,
        memoryLimit: 0,
        vmMemoryLimit: 0
    )

    /// Configuration with no restrictions (use with caution).
    ///
    /// No sandbox and no memory limits (`memoryLimit` and ``vmMemoryLimit``
    /// are both `0`).
    ///
    /// - Warning: Only use this configuration with trusted Lua code.
    ///   Unrestricted access allows file operations, system commands,
    ///   and other potentially dangerous operations.
    public static let unrestricted = LuaEngineConfiguration(
        sandboxed: false,
        packagePath: nil,
        memoryLimit: 0,
        vmMemoryLimit: 0
    )

    /// Creates a new engine configuration.
    ///
    /// - Parameters:
    ///   - sandboxed: Whether to disable dangerous functions. Default `true`.
    ///   - packagePath: Custom path for Lua module loading. Default `nil`.
    ///   - memoryLimit: Maximum memory in bytes for Swift module allocations
    ///     (0 = unlimited). Does not limit Lua VM allocations. Default `0`.
    ///   - vmMemoryLimit: Ceiling in bytes on total Lua VM allocation,
    ///     enforced by a custom allocator (0 = disabled). See
    ///     ``vmMemoryLimit``. Default `0`.
    public init(sandboxed: Bool, packagePath: String?, memoryLimit: Int, vmMemoryLimit: Int = 0) {
        self.sandboxed = sandboxed
        self.packagePath = packagePath
        self.memoryLimit = memoryLimit
        self.vmMemoryLimit = vmMemoryLimit
    }
}
