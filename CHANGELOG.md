# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Remediation of an independent code audit (2026-06-10 Round 2). All five findings
were documentation drift — no code defect. Round 1's code/security fixes were
re-confirmed intact.

### Fixed
- **Install snippets pinned to the current release.** The SwiftPM dependency
  examples in `README.md` (`from: "1.4.0"`) and the DocC *Getting Started*
  article (`from: "1.3.0"`) now use `from: "1.12.3"`, so new consumers pick up
  the audited cancellation, sandbox, memory-limit, and documentation fixes
  instead of a pre-remediation baseline.
- **Configuration reference corrected (`docs/index.md`).** The reference wrongly
  claimed only `vmMemoryLimit` carried an initializer default; all five
  `LuaEngineConfiguration.init` parameters default. The sample signature now
  shows every default and adds the `cooperativeCancellation` option.
- **Testing guide aligned to current CI topology (`TESTING.md`).** Replaced the
  stale `test-yams-off` / `test-tomlkit-on` job descriptions with the unified
  data-driven `test-toggles` job, documented the required `docs` (DocC) gate,
  corrected the `all-tests` dependency list, and fixed the quick-test
  description (the `--quick` script enables all three sibling-clone optional
  dependencies, not the default dependency set).

## [1.12.3] - 2026-06-10

### Added
- **`LuaEngineConfiguration.cooperativeCancellation`** (default `true`). When set
  to `false` and no instruction limit is configured, the engine no longer arms
  the periodic VM count hook, recovering ~2× throughput on instruction-heavy
  pure-Lua workloads. The trade-off: `requestCancellation()` cannot interrupt
  such an engine's runs and no CPU bound applies. Setting an instruction limit
  re-arms the hook regardless of this flag. Default preserves prior behavior.
  ([#30](https://github.com/ChrisGVE/LuaSwift/issues/30))

### Fixed
- **Count hook no longer armed unconditionally (#30).** Previously the
  cooperative-cancellation count hook was installed on every run even when
  neither an instruction limit nor cancellation was in use, firing every 10 000
  VM instructions for no benefit — a ~2× regression on instruction-heavy runs
  versus pre-cancellation versions. The hook is now armed only when an
  instruction limit is set or `cooperativeCancellation` is `true` (the default).

## [1.12.2] - 2026-06-10

Remediation of an independent code audit (2026-06-09 Round 1). All 28 findings
addressed; full verification matrix green (Lua 5.1–5.5, YAMS=0, TOMLKIT=1, iOS
Simulator build).

### Security
- **Cyclic tables and non-representable numeric keys are rejected.** Converting a
  Lua value to a `LuaValue` (run/evaluate results, callback arguments, coroutine
  yields/returns) now tracks table identity and raises `LuaError.cyclicTable` on
  a reference cycle instead of recursing until the Swift stack is exhausted, and
  validates numeric table keys with `Int(exactly:)`, raising
  `LuaError.numericKeyOutOfRange(_:)` for fractional / out-of-range keys instead
  of silently truncating, wrapping, or trapping. Read-only introspection
  (`globalValue(_:)`) degrades gracefully instead (breaks cycles, skips bad keys)
  since it is a total, non-throwing API.
- **HTTP responses are size-bounded.** The optional HTTP module streams response
  bodies through a bounded delegate and cancels mid-download once the body
  exceeds a cap (`HTTPModule.defaultMaxResponseSizeBytes`, 10 MiB; overridable
  per request via the `max_response_size` option), raising
  `LuaError.responseTooLarge(limit:)`. This stops sandboxed Lua from driving
  unbounded host-heap growth outside `vmMemoryLimit`.
- **HTTP request timeout is clamped** to `[HTTPModule.minTimeout, maxTimeout]`
  (1–120 s) so untrusted Lua cannot pin the engine on a single request, and the
  synchronous wait is now cooperative: `requestCancellation()` from another
  thread interrupts a stalled request (surfaces as `LuaError.cancelled`).
- **Sandboxed `packagePath` confinement is now robust.** With a `packagePath`
  configured, a sandboxed engine installs a validating `require` searcher bound
  to the configured directory and ignores `package.path` entirely, so a script
  can no longer escape confinement by reassigning `package.path` (including via
  `rawset` or after replacing the `package` metatable). Module names are
  validated (no path separators / `..`) and files load text-only on 5.2+.
  Unsandboxed engines keep normal `package.path` semantics. `package.preload`
  remains intentionally script-writable under the sandbox (documented as benign
  for the `package.loaded`-based module model; see [#29](https://github.com/ChrisGVE/LuaSwift/issues/29)).

### Added
- `LuaError` cases: `cyclicTable`, `numericKeyOutOfRange(Double)`,
  `responseTooLarge(limit:)`.
- `HTTPModule.defaultMaxResponseSizeBytes`, `HTTPModule.minTimeout`,
  `HTTPModule.maxTimeout`, and the `max_response_size` request option.
- `docs/architecture.md` — a top-level architecture document (with Mermaid
  diagrams) covering the `LuaEngine` extension decomposition, the vendored CLua
  targets, module install flow, value bridging, resource limits, the sandbox
  model, and the optional-dependency gates.
- `Sources/VENDORED-LUA.md` — provenance manifest (source URL, verified SHA256,
  date) for the bundled Lua sources.

### Fixed
- **Callback function-argument refs no longer leak on the abandon path.** When a
  later callback argument fails to convert, function refs already pinned for the
  call are released before the error is raised (the callback never runs). The
  receiver-owns-and-must-release contract for accepted function arguments is now
  documented on `registerFunction`.
- NumericSwift opt-in build works again (verified against NumericSwift 0.2.1);
  removed the stale README "compile failure" limitation
  ([#8](https://github.com/ChrisGVE/LuaSwift/issues/8) resolved upstream).
- Documentation accuracy: the value-server GettingStarted example now compiles,
  the `LuaValue` API reference lists all public cases/accessors, the DocC topic
  tree includes the previously-orphaned Compat/Serialize articles, opt-in module
  docs carry availability banners, and `TESTING.md` reflects the real CI topology.

### CI / Infrastructure
- A required DocC documentation-build job gates CI.
- The Lua source-updater workflow verifies each downloaded tarball against the
  SHA256 published by lua.org before replacing vendored sources, and records
  provenance.
- The local test matrix folds the Yams/TOMLKit toggles into a single source of
  truth; CI uses one data-driven toggle job. Performance benchmarks remain
  report-only (macOS-runner timing variance), now with baseline artifacts.

## [1.12.1] - 2026-06-09

### Added
- **Coroutine debugging for in-Lua resumes** ([#26](https://github.com/ChrisGVE/LuaSwift/issues/26)).
  A coroutine created and resumed entirely inside Lua via `coroutine.create` /
  `coroutine.wrap` is now stepped *into* while a debug session is active,
  completing the host-driven support added in 1.12.0. For the duration of each
  `runDebug` / `resume(_:with:)` call, `coroutine.create`/`wrap` are transparently
  routed through a hook-arming shim so each new coroutine thread receives the full
  debug mask before it runs; the standard `coroutine` library is restored on exit,
  so non-debug runs are unaffected. In-Lua coroutines now also observe cooperative
  cancellation and the instruction limit while stepped.

### Fixed
- **HTTP module engine retain cycle** ([#24](https://github.com/ChrisGVE/LuaSwift/issues/24)).
  `HTTPModule.install` captured the engine strongly in a callback stored on the
  engine, forming a cycle that prevented `deinit` and leaked the engine's
  `URLSession` pair for its whole lifetime. The callback now captures the engine
  weakly, and a new `deinit` cleanup hook invalidates the engine's sessions
  deterministically.
- **Memory-exhaustion classification across Lua versions.** A `luaL_Buffer`
  allocation failure (e.g. `string.rep` denied by the `vmMemoryLimit` allocator)
  now surfaces as `LuaError.memoryError` on every Lua version. On 5.3 it was
  reported as a `LUA_ERRRUN` whose message the structured-error stash shadowed,
  so it previously surfaced as a plain `.runtimeFailure`.
- **`LuaEngineConfiguration` memory-limit hardening.** `memoryLimit` /
  `vmMemoryLimit` are validated non-negative at construction (a negative value was
  silently treated as unlimited), and `trackAllocation(bytes:)` is now
  overflow-safe and rejects negative byte counts, so a pathological allocation
  surfaces as a `memoryError` instead of wrapping past the limit.

### Changed
- **Thales integration disabled** ([#18](https://github.com/ChrisGVE/LuaSwift/issues/18)).
  The optional `LUASWIFT_INCLUDE_THALES` flag is now a no-op: the upstream Thales
  API dropped `puiseuxSeries`/`residue`/`convergenceRadius`, breaking the opt-in
  build. The Thales code is preserved but compiled out; `SeriesModule` keeps its
  graceful no-Thales fallbacks. The integration will be re-enabled once the
  upstream API stabilises.
- `LuaEngineConfiguration` initializer parameters are now all defaulted, so
  `LuaEngineConfiguration()` equals `.default` and callers can override only the
  options they need.
- Deprecated `register(in:)` / `installModules(in:)` / `compile(_:)` aliases now
  carry a `renamed:` hint so the compiler offers a rename fix-it.

### Notes
- Internal readability refactors (deduplicated value-server metamethods and
  coroutine bridging, split over-budget functions) with no behavior change.
- Added CI jobs for the `LUASWIFT_INCLUDE_YAMS=0` and `LUASWIFT_INCLUDE_TOMLKIT=1`
  dependency configurations, and filled audit-identified test-coverage gaps.

## [1.12.0] - 2026-06-09

### Added
- **Coroutine debugging for host-driven resumes** ([#26](https://github.com/ChrisGVE/LuaSwift/issues/26)).
  When a debug session is active (`setDebugHandler`), `resume(_:with:)` now arms
  the full `LINE|CALL|RET` mask on the coroutine's thread instead of `COUNT` only,
  so the debugger steps *into* a coroutine body resumed through the host API
  rather than over it (`.line`/`.call`/`.ret` events fire; `.stop` aborts the
  coroutine as `.cancelled`). Coroutines created and resumed entirely inside Lua
  via `coroutine.resume` are still stepped over (a thread the host never arms) —
  documented as the remaining limitation.
- **`LuaValue.opaqueReference(LuaRefKind)`** — a typed, non-re-injectable
  reference case ([#27](https://github.com/ChrisGVE/LuaSwift/issues/27), CR-107).
  Read-only introspection (`globalValue(_:)` and the raw global/table walk) now
  represents function/userdata/thread values as `.opaqueReference(.function/.userdata/.thread)`
  instead of `.nil`, so a reference-typed global reads as *present and typed*
  without creating a `luaL_ref` (no registry leak when called after every run).
  It carries no handle: it cannot be called or pushed back into any engine
  (materializes as `nil` if used as an argument). To call a function, obtain a
  `.luaFunction` by passing it to a Swift callback. `LuaRefKind` is now `Equatable`.

### Changed
- **BREAKING:** `CoroutineResult.completed` now carries `[LuaValue]` instead of a
  single `LuaValue` ([#26](https://github.com/ChrisGVE/LuaSwift/issues/26)). A
  coroutine that returns multiple values on completion (`return 1, 2, 3`)
  previously lost all but the last; `resume(_:with:)` now surfaces every return
  value, in order, mirroring `.yielded`. A coroutine that returns nothing yields
  `.completed([])`. Migration: replace `case .completed(let value)` with
  `case .completed(let values)` and read `values.first` (or the full array).

## [1.11.0] - 2026-06-08

### Added
- **Public debug-hook API** (interactive debugger support) — implements [#20](https://github.com/ChrisGVE/LuaSwift/issues/20).
  LuaSwift now exposes a complete event/command-driven debug API for building interactive debuggers (MoonSwift `DebugSession`). Highlights:
  - **New types** (`LuaDebug.swift`): `LuaDebugEvent` (`.line(Int)`, `.call(LuaStackFrame)`, `.ret`), `LuaDebugCommand` (`.continueRun`, `.stepOver`, `.stepInto`, `.stepOut`, `.stop`), `LuaDebugInspector` protocol, `LuaInspectedValue` indirect enum (`.scalar(LuaValue)` / `.reference(kind:preview:children:)`), `LuaRefKind`, `LuaDebugHandler` typealias.
  - **Engine entry points** (`LuaEngine+Debug.swift`): `setDebugHandler(_:)`, `runDebug(_:chunkName:)`, `runDebug(_:CompiledChunk)`. `runDebug` arms the compositor hook with `LUA_MASKLINE | LUA_MASKCALL | LUA_MASKRET | LUA_MASKCOUNT` so line/call/return events flow to the handler while cancellation and instruction limits remain active.
  - **Synchronous concurrency model + atomic `isPaused`**: the handler is called synchronously on the VM thread (lock held). An `ManagedAtomic<Bool> isPaused` flag is set before the handler call and cleared after; every `LuaEngine` public method that touches `L` checks it *before* `lock.lock()` and throws `LuaError.enginePaused` when `true`, preventing deadlocks and C-level UB from concurrent state access during a pause. This satisfies the same contract as the PRD's "release-lock + semaphore" model while being simpler: the lock is never contended across a pause. See the `DebugHookAPI` DocC article for rationale.
  - **Native stepping with tail-call handling**: `stepOver`/`stepInto`/`stepOut` are implemented natively via `StepState` and `shouldPauseForStep`. Stack depth is re-read via `lua_getstack` at each LINE event (not maintained as a counter), which sidesteps the per-version tail-call event divergence: Lua 5.1 emits `LUA_HOOKTAILRET`; Lua 5.2+ emit `LUA_HOOKTAILCALL` with no matching return. The `<`/`<=` depth comparisons work correctly in all cases. Host-side depth counting is NOT required.
  - **Eager-snapshot inspector** (`DebugInspectorImpl`): `callStack` (via `walkLuaStack`, task 3), `locals(frameLevel:)` (via `lua_getlocal`), `upvalues(frameLevel:)` (via `lua_getupvalue`), `globals()` (raw `lua_next` walk). Values are materialised as `LuaInspectedValue` using raw `lua_next` (no `__pairs`/`__index`) up to depth 64, with raw-pointer cycle detection (repeated table pointer → `<cycle>`). Reference types never escape as re-injectable `LuaValue.luaFunction` handles.
  - **Validity token**: inspector `isValid` is `true` during the handler call; `invalidate()` flips it `false` after. Every method short-circuits via `guard valid else { return [] }`, returning a neutral empty result on use-after-callback — a guard, not a `precondition`, so the safety survives `-Ounchecked`. `isValid` is the authoritative signal.
  - **`stop` → `LuaError.cancelled`**: `.stop` reuses the F1 cancellation unwind. `runDebug` surfaces the result as `LuaError.cancelled`. MoonSwift's `DebugSession` distinguishes debugger-stop from a UI-cancel by knowing it issued `.stop` to `runDebug`.
  - **No-debug overhead**: plain `run`/`evaluate` arm only `LUA_MASKCOUNT` (unchanged). The debug branch in `compositorHookCallback` is a `nil`-check eliminated at `-O`.
  - **New `LuaError.enginePaused`** case with `errorDescription`.
  - **DocC article** `DebugHookAPI.md` documents the event/command vocabulary, synchronous concurrency model, native stepping + tail-call handling, inspector lifetime, eager-snapshot rules, and `stop`→`.cancelled` terminal state.
  - **18 new tests** in `DebugTests.swift` covering all PRD §F5 acceptance criteria: line event order, stop at line 2, locals at pause, breakpoint, tail-call `stepOut`, nested `callStack`, `runDebug(CompiledChunk)`, cancel-while-paused, function/table reference values, cyclic table, inspector invalidation, `enginePaused` guard, upvalues, globals, `stepOver`, `stepInto`. All pass on Lua 5.1, 5.4, and 5.5.
- **Engine introspection API** (read-only, raw access) — implements [#21](https://github.com/ChrisGVE/LuaSwift/issues/21).
  Five new properties/methods on `LuaEngine` let tooling (e.g. MoonSwift's Mock Environment navigator) inspect live engine state without executing user code:
  - `registeredValueServerNames: [String]` — names of servers registered via `register(server:)`.
  - `registeredFunctionNames: [String]` — names of Swift callbacks registered via `registerFunction(name:callback:)`.
  - `installedModuleNames: [String]` — names of modules successfully installed via `ModuleRegistry.install(in:)` (or `recordInstalledModule(_:)` for direct installs).
  - `globalNames(includingStandardLibrary: Bool) -> [String]` — raw enumeration of the engine's registry globals table; `false` returns only user-defined globals (those absent at engine init time).
  - `globalValue(_ name: String) -> LuaValue?` — raw read of a global using `lua_rawget`; returns `nil` for absent/nil globals.
  - **Raw access at every depth.** `globalNames` uses `lua_next` (not `pairs` — no `__pairs`); `globalValue` uses `lua_rawget` (not `lua_getglobal` / `lua_gettable` — no `__index`). The recursive table materialiser (`rawValueFromStack` / `rawTableFromStack`, internal) applies the same raw guarantee at every nesting level — a nested table's `__pairs` or `__index` is never invoked.
  - **Globals-table identity.** Enumeration always targets the registry globals table (`LUA_RIDX_GLOBALS` on 5.2+, `LUA_GLOBALSINDEX` on 5.1), not the `_ENV` upvalue. A chunk that rebinds `_ENV` does not affect what `globalNames` enumerates.
  - **Baseline snapshot.** At the end of `init(configuration:)` — after stdlib open, sandbox, and any init-time installs — the raw global key set is snapshotted into `baselineGlobalNames`. `globalNames(includingStandardLibrary: false)` subtracts this set so only user-defined globals (from executed code) are returned. The filter is deterministic and version-agnostic: no hardcoded stdlib name list.
  - **`installedModules` bookkeeping.** `ModuleRegistry.install(in:)` now records each successfully installed module into `LuaEngine.installedModules`. `recordInstalledModule(_:)` is available for modules installed outside the registry.
  - **Between-runs only.** All VM-touching methods are documented as safe only when no run is executing or paused; `NSRecursiveLock` is acquired before every access.
  - **No re-injection.** Returned `.luaFunction` values are bound to the engine they were read from; re-injecting them into a different (especially sandboxed) engine is prohibited and documented.
  - Works on Lua 5.1 through 5.5 (cross-version globals-table access already shimmed in `LuaHelpers.swift`).
- **Structured runtime errors** (`LuaError.runtimeFailure(LuaRuntimeFailure)`) — implements [#19](https://github.com/ChrisGVE/LuaSwift/issues/19).
  Runtime errors from all `lua_pcall` paths now carry a fully-parsed `LuaRuntimeFailure` with `message` (prefix stripped), `rawMessage` (intact), `line` (`Int?`), `traceback` (`String`), and `frames` (`[LuaStackFrame]?`).
  - **Handler mechanism:** a `@convention(c)` free-function error handler is installed as the `errfunc` on every `lua_pcall` (source `run`/`evaluate`, `CompiledChunk`, `callLuaFunction`). It fires while the Lua stack is still intact — before `lua_pcall` unwinds — allowing `lua_getinfo` and traceback-building to see all active frames.
  - **First-non-C-frame line:** the handler scans upward from level 1 for the first frame whose `what != "C"`. For an explicit `error()` call, level 1 is the C `error` builtin and the Lua caller is at level 2; for VM-internal errors (`nil + 1` etc.) the Lua frame is at level 1. Both cases yield the correct line number.
  - **Prefix stripping:** the standard `"chunkname:line: "` prefix is removed from `message` using exact-prefix matching against the known `short_src` and `currentline`, not a regex — this handles chunk names that contain colons (e.g. `config.yaml:$.scripts.init`).
  - **Non-string errors:** `error({table})` / `error(obj)` produce a typed placeholder `"<error: table>"` via `lua_typename` without calling `__tostring` or any other metamethod. Invoking a metamethod from an error handler risks `LUA_ERRERR` and can blow the cancellation instruction budget.
  - **Sentinel pass-through:** cancel and instruction-limit raises reach the handler too. It checks the out-of-band `abortReason` flag first and returns the error object unchanged, preserving `LuaError.cancelled` / `.instructionLimitExceeded`.
  - **5.1 traceback fallback:** Lua 5.1 lacks `luaL_traceback` — on 5.1 a manual `lua_getstack`/`lua_getinfo` walk builds the traceback string. The `traceback` field is always non-nil.
  - **Additive — source compatible:** `LuaError.runtimeError(String)` is unchanged and still matched by existing callers. The new `LuaError.runtimeFailure` case is caught by any `catch let err as LuaError`.
  - **Coroutines:** `lua_resume` takes no errfunc; structured errors for coroutine errors are out of scope for this release. Coroutine runtime errors surface as `LuaError.runtimeError(String)` (unstructured), not `.runtimeFailure`.
- **Chunk names for tracebacks** (`chunkName:` parameter on `run`, `evaluate`, `precompile`, `createCoroutine`) — implements [#23](https://github.com/ChrisGVE/LuaSwift/issues/23).
  An optional `chunkName: String?` parameter (default `nil`) lets callers supply a human-readable name that appears in error messages and tracebacks instead of a truncated snippet of the source code. This is additive — all existing call sites compile unchanged and behavior is byte-for-byte identical when `chunkName` is omitted.
  - **Source chunks** (`run`/`evaluate`/`createCoroutine`): the name is passed to `luaL_loadbuffer` as `"@" + chunkName`. The `@` prefix tells Lua to apply *tail* truncation in `short_src` when the name exceeds `LUA_IDSIZE` (60 bytes): names that fit appear verbatim; longer names show `"…"` followed by the tail, keeping the most-specific path component visible (e.g. the fragment name in `config.yaml:$.scripts.init`). The alternative `=` prefix would truncate from the head, losing specificity.
  - **Bytecode chunks** (`precompile`): the name is embedded into `Proto.source` inside the `lua_dump` output *before* the dump. Lua's loader ignores the load-time name argument for binary chunks — it reads the name directly from the embedded `Proto.source` — so embedding at compile time is the only effective mechanism. `lua_dump` passes `strip=0` on Lua 5.3+ and the 3-arg form on 5.1/5.2 so debug info (including `source`) is retained.
  - **`CompiledChunk` format version bumped 1 → 2**: a new optional `chunkName: String?` field mirrors the name embedded in the bytecode. Decoded with `decodeIfPresent` so v1 chunks (no `chunkName` key) decode cleanly with `chunkName == nil` and no `keyNotFound` error — existing caches remain loadable.
  - **Default behavior preserved exactly**: when `chunkName` is `nil`, `luaL_loadbuffer` is called with the source string itself as the name, which is the exact definition of `luaL_loadstring`. The familiar `[string "…"]` traceback form is unchanged.
  - `luaL_loadbuffer_source` — internal Swift wrapper for the `luaL_loadbuffer` C macro (not directly importable into Swift). On Lua 5.1 delegates to `CLua.luaL_loadbuffer`; on 5.2–5.5 expands to `luaL_loadbufferx` with `mode=nil`.
- **Cooperative cancellation** (`LuaEngine.requestCancellation()` / `resetCancellation()`) — closes [#22](https://github.com/ChrisGVE/LuaSwift/issues/22).
  A periodic compositor hook fires every 10 000 Lua VM instructions (tunable `hookInterval`) and checks an atomic cancellation flag; if set, the in-flight run aborts and throws `LuaError.cancelled`. Measured abort latency is ~1–3 ms on Apple Silicon, well inside the 200 ms target (CI threshold 400 ms).
  - `requestCancellation()` is lock-free (no `NSLock`); safe to call from any thread while Lua executes.
  - `resetCancellation()` clears the flag, the out-of-band abort-reason flag, and the instruction accumulator so the engine can be reused.
  - `LuaError.cancelled` — new additive case.
  - Applied to every execution entry point: `run`/`evaluate` (source and `CompiledChunk`), `callLuaFunction`, and coroutine `resume`.
  - **C-function limitation:** a C function that never returns to the VM loop (e.g. `string.rep("A", 1e9)`) cannot be interrupted — same documented limitation as the instruction limit.
  - **Reuse-safety guarantee:** `lua_error` unwinds to the `pcall` boundary exactly as for `instructionLimitExceeded`; a `#if DEBUG` `lua_gettop` assertion at every pcall boundary confirms the stack is clean. `resetCancellation()` must be called after both `.cancelled` and `.instructionLimitExceeded` before the engine is reused; a normally-completing run never sets the abort flag.
  - Verified on Lua 5.1, 5.4, and 5.5.
- **Compositor hook replaces once-fire instruction hook** — the single `lua_sethook` slot is now multiplexed: (1) cancellation check, (2) instruction-limit accumulation. When `instructionLimit` is set, the hook is armed with `min(hookInterval, instructionLimit)` so the first fire cannot overshoot a limit smaller than the default interval; the exact-at-limit semantics of the existing instruction-limit API are preserved.
- **TLS save/restore for engine recovery** — `setAsCurrentEngine()` now returns the previous occupant and the new `restoreCurrentEngine(_:)` puts it back, so a Swift callback invoked mid-run no longer permanently clears the TLS key the compositor hook uses; the cancel/limit check remains active for the full duration of the run even after callbacks return.

### Security
- **Debug inspector previews use opaque ids, not raw heap addresses.** `LuaInspectedValue` reference previews are now stable per-snapshot opaque ids (`"table #3"`, `"function #4"`) instead of raw `lua_topointer` addresses. This prevents the Lua/host heap pointer from leaking into a preview string that may be serialised off-device (remote-debug wire, uploaded crash log) — which would otherwise be an ASLR-disclosure oracle. Aliased references read as the same `#n` within one snapshot; cycle/depth markers are unchanged. (SEC-202)
- **Optional bounded inspection** for debugging untrusted Lua. The inspector remains unbounded and faithful by default (the host owns the trust decision). Building with `-D LUASWIFT_BOUNDED_INSPECTION` (env `LUASWIFT_BOUNDED_INSPECTION=1`) caps each table — and `_G` itself — at `LuaInspectedValue.boundedInspectionBreadth` (10,000) children plus a single `isBreadthLimited` sentinel, defending a debugger that snapshots a global/local table against an adversarial million-entry "breadth bomb" that would otherwise exhaust host memory under the held lock. New accessors: `LuaInspectedValue.maxInspectionBreadth` / `boundedInspectionBreadth` / `isBreadthLimited`. (SEC-201)

## [1.10.1] - 2026-06-07

### Fixed
- **Module-doc currency for the JSON-null sentinel** - `docs/modules/json.md` and `docs/modules/http.md` now document that `json.null` is the canonical JSON-null representation (preferring `json.is_null`), that the Swift `JSONNull`/`JSONModule.null` are deprecated for 2.0 removal, and that the HTTP `json` body encodes `json.null` as JSON `null`. These markdown references had lagged the v1.10.0 API change ([#17](https://github.com/ChrisGVE/LuaSwift/issues/17), [#25](https://github.com/ChrisGVE/LuaSwift/issues/25)).

## [1.10.0] - 2026-06-07

### Added
- **Provenance-typed bytecode API** - New `CompiledChunk` struct (`Codable`, `Equatable`, `Sendable`) wraps dumped bytecode together with the compiling build's provenance (Lua version, `lua_Integer`/`lua_Number` sizes, endianness, plus a format-version field for safe evolution). `LuaEngine.precompile(_:)` produces chunks; the new `run(_:)`/`evaluate(_:)` overloads validate the chunk's metadata against the running build before any bytes reach the Lua loader, throwing a descriptive `LuaError.runtimeError` on mismatch. This closes the accidental-arbitrary-`Data` misuse of the bytecode path; note there is no cryptographic integrity of persisted caches — a tampered cache file remains the consumer's trust boundary ([#9](https://github.com/ChrisGVE/LuaSwift/issues/9)).
- **Lua VM memory limit** - New `LuaEngineConfiguration.vmMemoryLimit` (default `0` = disabled) bounds **total Lua VM allocation** via a custom `lua_Alloc` allocator installed with `lua_newstate`. Growth beyond the ceiling is denied, surfacing as `LuaError.memoryError`; shrinks and frees are always allowed. This closes the gap where a single VM instruction calling a C function (e.g. `string.rep('A', 1e9)`) bypassed the instruction-count hook and allocated unbounded memory — the instruction limit is now documented as a CPU-bound control only ([#11](https://github.com/ChrisGVE/LuaSwift/issues/11)).
- **Throwing module-install API** - Every Swift-backed module now exposes `install(in:)` (via the new `LuaSwiftModule` protocol), which propagates Lua setup failures instead of swallowing them. `ModuleRegistry.install(in:)` installs the full module set, continuing past individual failures and throwing a single `ModuleInstallError` that lists every module whose setup failed ([#12](https://github.com/ChrisGVE/LuaSwift/issues/12)).
- **`LuaSwiftModule.moduleName`** - Each module now carries its own name, used when reporting install failures. The prerequisite cascade skips dependents of a failed prerequisite, recording a synthetic error for each so the failure report stays complete ([#12](https://github.com/ChrisGVE/LuaSwift/issues/12)).

### Changed
- **`ModuleInstallError` is structured and `Sendable`** - `ModuleInstallError.failures` is now `[ModuleInstallError.Failure]`, a `Sendable` struct pairing `module` with `underlyingError`; the error itself is `Sendable` and `Equatable` and rejects an empty failure list. `ModuleRegistry.install(in:)` is driven by a `[any LuaSwiftModule.Type]` list ([#12](https://github.com/ChrisGVE/LuaSwift/issues/12)).
- **Internal file reorganization** - `LuaEngine.swift` is split into per-concern extension files (configuration, execution, bytecode, function calls, callbacks, coroutines, value servers, value bridging, sandbox, VM allocator) and `ArrayModule+Phase2.swift` into registration, callbacks, Lua wiring, and complex-trig files. No public API or behavior change ([#13](https://github.com/ChrisGVE/LuaSwift/issues/13)).

### Deprecated
- **Raw-`Data` bytecode API** - `LuaEngine.compile(_:)`, `runBytecode(_:)`, and `evaluateBytecode(_:)` are deprecated in favor of `precompile(_:)` and the `CompiledChunk` overloads of `run(_:)`/`evaluate(_:)`. Raw `Data` bypasses provenance validation, and Lua's bytecode verifier is a no-op, so crafted or mismatched bytes can corrupt the VM. Behavior is unchanged until removal. Migration: recompile cached source with `precompile(_:)` and persist the resulting `CompiledChunk` via `Codable` — old raw-`Data` caches cannot be wrapped, only recompiled ([#9](https://github.com/ChrisGVE/LuaSwift/issues/9)).
- **Swallowing module registration** - `ModuleRegistry.installModules(in:)`, the per-module `ModuleRegistry.installXModule(in:)` helpers, and each module's `register(in:)` are deprecated in favor of the throwing `install(in:)` equivalents. They behave exactly as before (failures are swallowed, DEBUG builds print them) and will be removed in the next major release ([#12](https://github.com/ChrisGVE/LuaSwift/issues/12)).
- **Vestigial Swift `JSONNull`** - The Swift-side `JSONNull` struct and `JSONModule.null` static are deprecated: they were never bridged into the Lua conversion paths. The Lua-side `json.null` sentinel (tested with `json.is_null`) is the canonical JSON-null representation. Both will be removed in 2.0 ([#17](https://github.com/ChrisGVE/LuaSwift/issues/17)).

### Fixed
- **`compat` cannot expose `load` as `loadstring`** - The `compat.lua` `loadstring` capture and install steps now guard on `type(load) == "function"`, making the sandbox-ordering invariant explicit so loading `compat` before the sandbox cannot resurrect a callable `loadstring` ([#15](https://github.com/ChrisGVE/LuaSwift/issues/15)).
- **`CompiledChunk` rejects stale format versions** - Decoding a chunk whose `formatVersion` is below `1` is now rejected, and the provenance and binary-signature checks are centralized in `validatedBytecode()` so every load path validates identically ([#9](https://github.com/ChrisGVE/LuaSwift/issues/9)).
- **No phantom nil globals for absent modules** - `extend_stdlib` no longer creates explicit `nil` globals for optional modules that were not compiled in ([#12](https://github.com/ChrisGVE/LuaSwift/issues/12)).
- **Hardened VM memory-limit allocator** - The accounting counter is clamped on every free/shrink so a stale `osize` cannot drive it negative and silently disable the ceiling; the growth check is overflow-safe; shrinks honor Lua's never-fail contract; no block leaks when `ud` is nil; and the panic/warning handlers no longer allocate a Swift `String` under memory pressure (they now write directly via `fputs`/`fwrite`, with the handler types declared `@convention(c)` to prevent bridging thunks) ([#11](https://github.com/ChrisGVE/LuaSwift/issues/11)).
- **`packagePath` set via C API** - `LuaEngineConfiguration.packagePath` is now applied through `lua_getglobal`/`lua_setfield` instead of generated Lua source, so paths containing quotes or other Lua-meaningful characters are set verbatim and can no longer break (or inject into) the assignment ([#16](https://github.com/ChrisGVE/LuaSwift/issues/16)).
- **HTTP `json.null` request bodies** - A `json.null` value inside an HTTP request's `json` body now encodes as JSON `null` instead of leaking the internal marker object, matching `json.encode` ([#17](https://github.com/ChrisGVE/LuaSwift/issues/17)).

### Security
- **Bytecode must be genuine binary** - `CompiledChunk` now requires the Lua binary signature (`\x1bLua`) before any chunk reaches the loader, closing a Lua 5.1 hole where a chunk whose payload was plain Lua source (with matching provenance) compiled and executed as source ([#9](https://github.com/ChrisGVE/LuaSwift/issues/9)).
- **Sandbox install failures surface** - Sandbox installation failures now throw `LuaError.sandboxInstallationFailed` instead of being silently discarded, and the `warn` global is removed under the default sandbox on Lua 5.4/5.5 to close a stderr-flood vector ([#11](https://github.com/ChrisGVE/LuaSwift/issues/11)).

## [1.9.1] - 2026-05-31

### Fixed
- **Top-level JSON scalars decode** - `json.decode` now accepts bare top-level JSON values (`null`, numbers, strings, booleans) via `.fragmentsAllowed` instead of throwing, completing the JSON-`null` round-trip symmetry (`decode(encode(json.null))` now reproduces the sentinel).
- **Build without Yams** - Fixed compilation and test failures under `LUASWIFT_INCLUDE_YAMS=0` (the optional-dependency-free "nimble" build): the YAML `require()` test now compiles only with Yams, and the optional-dependency tests no longer assert `luaswift.yaml` as unconditionally available.
- **iOS alert dismissal delegate** - The alert dismissal delegate is now assigned after presentation begins, so interactive dismissals (notably iPad popover-backed action sheets) are detected promptly instead of relying on the watchdog fallback.

## [1.9.0] - 2026-05-31

### Added
- **Symmetric JSON `null`** - Decoding a JSON `null` now yields a truthy `luaswift.json.null` marker table instead of Lua `nil`, so object keys with `null` values are preserved across a decode/encode round-trip. Encoding the marker (or `luaswift.json.null`) emits `null`. Test membership with `luaswift.json.is_null(v)`. Only a single-key marker table is treated as `null` (collision guard), so ordinary tables are unaffected.

### Changed
- **`bit32` deprecation gate** - The `bit32` compatibility shim now emits its deprecation warning from Lua 5.3 onward (previously 5.4+), matching when upstream Lua deprecated the library.
- **Hermetic HTTP tests** - The HTTP module test suite now runs against an in-process httpbin-compatible server instead of live third-party hosts, making it deterministic and network-independent. No change to the shipped `luaswift.http` API.

### Fixed
- **iOS alert deadlock** - Fixed a main-thread deadlock when presenting the UI `alert`/confirm dialog on iOS. The presentation wait now terminates on every path: button tap (idempotent completion), interactive dismissal, programmatic dismissal, and a watchdog for the never-presented case.
- **`require()` access for Swift-backed modules** - Registered `package.loaded` entries so `require("luaswift.<module>")` resolves the same instances as the `luaswift.*` globals for every module exposed under that namespace (`array`, `complex`, `debug`, `geometry`, `http`, `iox`, `json`, `linalg`, `math`/`mathx`, `mathexpr`, `plot`, `regex`, `stringx`, `svg`, `tablex`, `toml`, `types`, `ui`, `utf8x`, `yaml`, plus `cas` when Thales is enabled). The SciPy-style scientific modules are reached through the `math.*` namespace (e.g. `math.stats`, `math.integrate`) rather than a `luaswift.<name>` require path.
- **`linalg.norm` string orders** - `norm` now accepts string orders (`"fro"`, `"inf"`) and rejects unsupported orders with a clear error instead of misbehaving.

### Documentation
- **Module docs rewrite** - All module articles in the DocC catalog were rewritten to match the current implementation.

## [1.8.5] - 2026-05-30

### Changed
- **License header consistency** - Corrected source-file license headers to match the project's Apache License 2.0 (LICENSE). Stale `Licensed under the MIT License` headers in 74 Swift/Lua source and test files were replaced with `SPDX-License-Identifier: Apache-2.0`. Bundled Lua C sources retain their own (correct) MIT license.

## [1.8.4] - 2026-05-30

### Changed
- **Repository hygiene** - Stopped tracking developer-local files (`CLAUDE.md`, `code_audit.md`) in version control; these are now ignored locally. No public-facing or packaged code is affected.

## [1.8.3] - 2026-05-30

### Changed
- **Optional dependency defaults flipped to OFF** - NumericSwift, ArraySwift, PlotSwift, and TOMLKit are now excluded by default; only Yams (YAML) remains on by default. Set the corresponding `LUASWIFT_INCLUDE_*=1` env var to opt in. This makes the default build lighter; opt into the scientific-computing and TOML stacks explicitly.

## [1.8.2] - 2026-05-30

### Changed
- **Optional Data-Format Dependencies** - Yams (YAML) and TOMLKit (TOML) are now optional dependencies, following the same env-var pattern as NumericSwift/ArraySwift/PlotSwift. Set `LUASWIFT_INCLUDE_YAMS=0` or `LUASWIFT_INCLUDE_TOMLKIT=0` to exclude. Both included by default for backward compatibility. A minimal build with all optional deps excluded has zero external dependencies (JSON via Foundation only).

## [1.8.1] - 2026-05-29

### Fixed
- **Cross-Version Bytecode C-API** - Gated `lua_dump`/`luaL_loadbuffer` bytecode calls by Lua version so the bytecode-compilation path builds correctly on Lua 5.1 and 5.2 (the 1.8.0 release failed to compile on those versions). Lua 5.3–5.5 are unaffected.

## [1.8.0] - 2026-05-29

### Added
- **Instruction-Count Limit** - `LuaEngine.setInstructionLimit(_:)` installs a `lua_sethook` count hook that deterministically aborts runaway Lua code (e.g. infinite loops) with the new `LuaError.instructionLimitExceeded`. The limit re-arms before every `run`/`evaluate` call; pass `0` to disable (default).
- **Bytecode Compilation** - `LuaEngine.compile(_:)`, `runBytecode(_:)`, `evaluateBytecode(_:)` for precompiling Lua source to bytecode and executing it; instruction-count limit applies on the bytecode path.
- **Complex-Dispatch Math** - `mathx` `sin`/`cos`/`tan`/`exp`/`log`/`sqrt` now dispatch on complex arguments, returning complex results while remaining real-valued for real inputs.
- **ArraySwift 0.2.0 Bindings** - Exposed ArraySwift's dtype infrastructure (float64/int64/bool/complex128/date with NumPy-style promotion), FFT family (`fft`/`ifft`/`rfft`/`fft2`/`fftn`/`fftfreq`), set operations (`intersect1d`/`union1d`/`setdiff1d`/`setxor1d`/`in1d`), and boolean/fancy/negative indexing to the Lua `array` module.
- **Power-Series Object** - `series.power` power-series type with `add`/`multiply`/`truncate`/`eval` operations.
- **Thales CAS Module** *(optional, opt-in)* - When built with `LUASWIFT_INCLUDE_THALES=1`, exposes computer-algebra operations to Lua: `asymptotic`, `compose_series`, `revert_series`, `puiseux`, `residue`, `convergence_radius`. Built on the optional Thales v0.4.2 dependency; off by default.
- **Table Comprehensions** - Python-style list/dict/set comprehensions in the `tablex` module.
- **Dialog Module** - UI `alert` and confirmation dialog module.
- **Slice Notation** - Python-style slice notation for `string`, `table`, and `array` modules.

### Changed
- **Dependency Bumps** - ArraySwift → 0.2.0, NumericSwift → 0.2.1.
- **MathExprModule** - Updated to the NumericSwift 0.2.1 parser API (`MathLexExpression`) after NumericSwift removed its public `tokenize` entry point.

### Fixed
- **CI Permissions** - Added write permissions to the Lua version-check workflow.

## [1.7.0] - 2026-04-06

### Added
- **Plot Colormaps** - Colormap support for scatter plots with numeric color arrays
- **Plot Axis Scaling** - Integrated axis scaling (log, symlog, logit) into all plot functions
- **HTTP Follow Redirects** - `follow_redirects` option for HTTP module
- **LuaFunction Auto-Release** - Automatic Lua function reference release mechanism for safer memory management
- **Lua Version Matrix CI** - CI now tests all 5 Lua versions (5.1-5.5)
- **Pure Lua Test Suite** - Standalone Lua test framework with test runner for cross-interpreter validation
- **Version-Specific Tests** - Swift tests with conditional compilation for Lua version differences
- **Test Infrastructure** - Centralized test configuration with data-driven dependency combinations
- **TESTING.md** - Comprehensive documentation for all test configurations and patterns
- **DocC Articles** - Documentation for compat and serialize Lua modules

### Fixed
- **Lua 5.1/5.2 Compatibility** - Enable LUA_COMPAT mode for backwards-compatible features across all supported versions
- **Array Module** - Use Lua 5.1-compatible `unpack` function instead of `table.unpack`
- **Optimize Module** - Use unpack compatibility shim for Lua 5.1
- **String Bridging** - Support embedded NUL bytes in string conversion
- **LuaValue.intValue** - Now returns nil for fractional numbers instead of truncating
- **Sandbox Security** - Harden sandbox to prevent `require()` bypass attempts
- **IO Sandbox** - Resolve symlinks to prevent sandbox directory escape

### Performance
- **HTTP Module** - Reuse URLSession instances per engine instead of creating new sessions per request

## [1.6.0] - 2026-01-19

### Changed
- **Deeper NumericSwift Integration** - Modules now use NumericSwift as thin wrappers:
  - SpatialModule: Delaunay, Voronoi, ConvexHull now delegate to NumericSwift (~290 lines removed)
  - SeriesModule: Taylor coefficient generation delegates to NumericSwift (~90 lines removed)
  - MathExprModule: parse, substitute, to_string, find_variables delegate to NumericSwift (~187 lines removed)
  - All algorithmic code now lives in NumericSwift; LuaSwift modules handle only Lua↔Swift type conversion

### Fixed
- **test-combinations.sh** - Fixed SIGPIPE issue with bash pipefail option causing false test failures

## [1.5.0] - 2026-01-17

### Added
- **Optional Dependencies** - NumericSwift, ArraySwift, and PlotSwift are now optional dependencies:
  - `LUASWIFT_INCLUDE_NUMERICSWIFT=0` to exclude NumericSwift
  - `LUASWIFT_INCLUDE_ARRAYSWIFT=0` to exclude ArraySwift
  - `LUASWIFT_INCLUDE_PLOTSWIFT=0` to exclude PlotSwift
  - All three included by default for backward compatibility
  - Reduces binary size when optional features are not needed
- **Platform Support** - Added support for additional Apple platforms:
  - visionOS 1.0+
  - watchOS 8.0+
  - tvOS 15.0+
- **DocC Documentation Catalog** - Full documentation for Swift Package Index:
  - 37 documentation articles covering all modules
  - Getting started guide and core API documentation
  - Comprehensive examples and usage patterns
  - Automatic documentation hosting via SPI
- **CI Workflow** - GitHub Actions workflow for testing all 8 dependency combinations:
  - Matrix strategy runs combinations in parallel
  - Triggers on push to dev/main and PRs
- **Test Script** - Local script (`scripts/test-combinations.sh`) for testing dependency combinations:
  - Sequential and parallel modes
  - Tests all 8 combinations (standalone through all three)
- **Unit Tests** - `OptionalDependencyTests.swift` verifying optional dependency behavior:
  - Module availability based on compilation flags
  - Graceful handling when dependencies excluded

### Changed
- **Refactored Scientific Modules** - Integrated with NumericSwift for shared algorithms:
  - ComplexModule now uses NumericSwift.Complex type
  - SpecialModule delegates to NumericSwift (beta, bessel, gamma, zeta, elliptic)
  - SeriesModule uses NumericSwift (factorial, Chebyshev, polynomial evaluation)
  - NumberTheoryModule uses NumericSwift (primes, factorization, arithmetic functions)
  - LinAlgModule reduced from 3231 to 1645 lines using NumericSwift.LinAlg
  - DistributionsModule uses NumericSwift for statistical functions
  - OptimizeModule uses NumericSwift (golden section, Brent, Nelder-Mead, Levenberg-Marquardt)
  - InterpolateModule uses NumericSwift (splines, PCHIP, Akima)
  - IntegrateModule uses NumericSwift (Gauss-Kronrod, ODE solvers)
  - GeometryModule integrated with NumericSwift
  - SpatialModule integrated with NumericSwift
  - ClusterModule integrated with NumericSwift
  - RegressModule integrated with NumericSwift
  - MathExprModule integrated with NumericSwift
- **ArrayModule** - Now uses ArraySwift package for NDArray implementation
- **PlotModule** - Now uses PlotSwift package for DrawingContext and styling types
- **Lua Namespaces** - Updated namespace organization:
  - `math.geo` renamed to `math.geometry`
  - Added `math.x` namespace for extended math utilities
  - `plt` global renamed to `plot` (users can alias: `local plt = plot`)

### Performance
- **Table-to-Array Conversion** - Optimized from O(n log n) to O(n) using min/max check instead of sorting

## [1.4.1] - 2026-01-11

### Added
- **Comprehensive API Documentation** for all 28 modules:
  - Standard Library Extensions: stringx, tablex, utf8x, regex, compat
  - Data Formats: json, yaml, toml
  - Math Namespace: linalg, complex, geo, special, stats, distributions, optimize, integrate, interpolate, cluster, spatial, regress, series, eval, constants, numtheory
  - Visualization: plot
  - File and Network: iox, http
- **docs/ folder** with full API reference and usage guides
- **Documentation badge** in README

### Changed
- README restructured with documentation link before examples
- All module docs now use "Function Reference at top" pattern with anchor links
- "External Access" renamed to "File and Network Access" for clarity
- Clarified iox operates within sandbox (not outside)
- Replaced Python-style variable names (np, plt) with descriptive names

## [1.4.0] - 2026-01-11

### Added
- **SciPy-inspired Scientific Computing Modules** (all Swift-backed with Accelerate):
  - `luaswift.distributions` - Probability distributions (norm, t, chi2, f, gamma, beta, uniform) with pdf, cdf, ppf, sf, isf, rvs methods
  - `luaswift.integrate` - Numerical integration (quad, dblquad, tplquad, nquad, odeint, simps, trapz, cumtrapz)
  - `luaswift.optimize` - Optimization (minimize, minimize_scalar, root, root_scalar, curve_fit, least_squares)
  - `luaswift.interpolate` - Interpolation (interp1d, CubicSpline, PCHIP, Akima, make_interp_spline)
  - `luaswift.cluster` - Clustering algorithms (kmeans, hierarchical, DBSCAN, silhouette_score)
  - `luaswift.spatial` - Spatial algorithms (KDTree, Voronoi, Delaunay, ConvexHull, distance functions)
  - `luaswift.special` - Special functions (erf, erfc, gamma, lgamma, digamma, beta, betainc, bessel j0/j1/jn/y0/y1/yn, ellipk, ellipe, zeta, lambertw)
  - `luaswift.regress` - Regression models (OLS, WLS, GLS, GLM with multiple families, ARIMA)
  - `luaswift.series` - Series evaluation (Taylor polynomials, series summation/product, convergence detection, lazy iterators)

- **Visualization Modules**:
  - `luaswift.plot` - Matplotlib/seaborn-compatible plotting with retained vector graphics (figure, subplot, plot, scatter, bar, hist, heatmap, pie, boxplot, violin, contour, imshow)
  - `luaswift.svg` - Swift-backed SVG document generation (complete rewrite from Lua)

- **Math/Expression Modules**:
  - `luaswift.mathexpr` - Mathematical expression parsing with LaTeX support, step-by-step evaluation, equation solving
  - `luaswift.mathsci` - Unified scientific computing namespace (math.stats, math.linalg, math.special, etc.)
  - `luaswift.sliderule` - Slide rule simulation for analog computation

- **Debug Module** (`luaswift.debug`, DEBUG builds only):
  - Structured logging with levels (debug, info, warn, error)
  - Console utilities (print, inspect, trace, assert)
  - Performance timing (time, timeEnd)

- **MathX Extensions**:
  - Additional constants: tau, phi (golden ratio), euler_gamma
  - Probability functions: ncr, npr, factorial

- **LinAlg Extensions**:
  - Singular Value Decomposition (SVD)
  - QR decomposition
  - Eigenvalue decomposition
  - Least squares solver (lstsq)
  - Moore-Penrose pseudo-inverse (pinv)
  - Matrix condition number (cond)

- **Memory Limit Enforcement**:
  - LuaEngine tracks memory allocations from Swift modules
  - `trackAllocation(bytes:)` throws when limit exceeded
  - ArrayModule and LinAlgModule respect configured limits
  - Configurable via `LuaEngineConfiguration.memoryLimit`

- **Geometry Extensions**:
  - Additional 2D/3D utilities
  - Quaternion improvements

### Changed
- All modules now use Swift-backed implementations for performance (previously some were pure Lua)
- Test suite expanded to 2171+ XCTest tests + 202 Swift Testing tests
- MathExpr module rewritten in Swift with LaTeX preprocessing

## [1.3.0] - 2026-01-04

### Added
- **Multi-version Lua support** (5.1.5, 5.2.4, 5.3.6, 5.4.7, 5.5.0)
  - All 715 tests pass on every Lua version
  - Environment variable `LUASWIFT_LUA_VERSION` for version selection
  - Comprehensive compatibility shims in LuaHelpers.swift
- GitHub CI workflows for automated Lua version updates and releases
- Types module for type detection and conversion (`luaswift.types`)
- Stdlib extension capability (`luaswift.extend_stdlib()`)
- Top-level global aliases for all modules (json, yaml, complex, geo, etc.)
- Serialize module for Lua value serialization/deserialization

### Changed
- Default Lua version remains 5.4.7 for backwards compatibility
- Compat module now works across all Lua versions with graceful fallbacks
- Serialize module uses Lua 5.1-compatible string escaping

### Lua Versions
| Series | Bundled Version |
|--------|-----------------|
| 5.1    | 5.1.5           |
| 5.2    | 5.2.4           |
| 5.3    | 5.3.6           |
| 5.4    | 5.4.7           |
| 5.5    | 5.5.0           |

## [1.2.0] - 2026-01-02

### Added
- Types module for type detection and conversion
- Stdlib extension pattern with `import()` functions
- Top-level global aliases for modules

## [1.0.0] - 2025-12-28

### Added
- Initial release
- LuaEngine with sandboxed execution
- LuaValue type-safe value representation
- LuaValueServer protocol for Swift-Lua data bridging
- Coroutine support with CoroutineHandle
- Swift callback registration
- Bundled modules: JSON, YAML, TOML, Regex, StringX, TableX, UTF8X, MathX
- Linear algebra module (vectors, matrices)
- Geometry module (vec2, vec3, quaternion, transform3d)
- Complex number module
- Array module (NumPy-like operations)
- Compat module for Lua version compatibility
