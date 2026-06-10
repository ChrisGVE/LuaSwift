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

    /// Whether the periodic cooperative-cancellation hook is armed when no
    /// instruction limit is set.
    ///
    /// LuaSwift interrupts running Lua by installing a periodic VM count hook
    /// (every ``LuaEngine/hookInterval`` instructions). That hook serves two
    /// purposes: enforcing ``LuaEngine/setInstructionLimit(_:)`` and honoring
    /// ``LuaEngine/requestCancellation()``. When an instruction limit is set the
    /// hook is always armed. This flag controls only the **no-limit** path:
    ///
    /// - `true` (default): the hook is armed on every run even without a limit,
    ///   so ``LuaEngine/requestCancellation()`` can interrupt a tight Lua loop.
    ///   This is the behavior LuaSwift has always had.
    /// - `false`: when no instruction limit is set, the hook is **not** armed.
    ///   ``LuaEngine/requestCancellation()`` then cannot interrupt a running
    ///   script, and no CPU/instruction bound applies. In exchange,
    ///   instruction-heavy runs avoid the per-`hookInterval` callback overhead
    ///   (~2× throughput on pure-Lua compute workloads; see issue #30).
    ///
    /// Set this to `false` only for engines that run trusted, bounded workloads
    /// and never call ``LuaEngine/requestCancellation()`` — e.g. a synchronous
    /// lint/validation pass. Setting an instruction limit re-arms the hook
    /// regardless of this flag.
    ///
    /// Default: `true` (preserves cancellation on the no-limit path)
    public var cooperativeCancellation: Bool

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
        vmMemoryLimit: 0,
        cooperativeCancellation: true
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
        vmMemoryLimit: 0,
        cooperativeCancellation: true
    )

    /// Creates a new engine configuration.
    ///
    /// Every parameter has a default, so `LuaEngineConfiguration()` is equivalent
    /// to ``default`` and callers can override only the options they care about,
    /// e.g. `LuaEngineConfiguration(memoryLimit: 1 << 20)`.
    ///
    /// ## Init-time consumption
    ///
    /// A configuration is a value type **consumed once** by
    /// ``LuaEngine/init(configuration:)``, which copies it into the engine's
    /// immutable ``LuaEngine/configuration``. Mutating a configuration value
    /// after an engine has been created has **no effect** on that engine — the
    /// stored fields are `var` only so a configuration can be assembled
    /// incrementally before construction.
    ///
    /// - Parameters:
    ///   - sandboxed: Whether to disable dangerous functions. Default `true`.
    ///   - packagePath: Custom path for Lua module loading. Default `nil`.
    ///   - memoryLimit: Maximum memory in bytes for Swift module allocations
    ///     (0 = unlimited). Does not limit Lua VM allocations. Must be
    ///     non-negative. Default `0`.
    ///   - vmMemoryLimit: Ceiling in bytes on total Lua VM allocation,
    ///     enforced by a custom allocator (0 = disabled). Must be non-negative.
    ///     See ``vmMemoryLimit``. Default `0`.
    ///   - cooperativeCancellation: Whether to arm the periodic cancellation
    ///     hook when no instruction limit is set. See ``cooperativeCancellation``.
    ///     Default `true`.
    public init(
        sandboxed: Bool = true,
        packagePath: String? = nil,
        memoryLimit: Int = 0,
        vmMemoryLimit: Int = 0,
        cooperativeCancellation: Bool = true
    ) {
        precondition(memoryLimit >= 0,
                     "LuaEngineConfiguration.memoryLimit must be non-negative (0 = unlimited); got \(memoryLimit)")
        precondition(vmMemoryLimit >= 0,
                     "LuaEngineConfiguration.vmMemoryLimit must be non-negative (0 = disabled); got \(vmMemoryLimit)")
        self.sandboxed = sandboxed
        self.packagePath = packagePath
        self.memoryLimit = memoryLimit
        self.vmMemoryLimit = vmMemoryLimit
        self.cooperativeCancellation = cooperativeCancellation
    }
}
