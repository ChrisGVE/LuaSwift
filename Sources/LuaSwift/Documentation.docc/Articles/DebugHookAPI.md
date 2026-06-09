# Debug Hook API Internals

Internals reference for the public debug-hook API — event/command vocabulary,
the synchronous concurrency model, native stepping with tail-call handling,
inspector lifetime, and the `stop`→`.cancelled` terminal state.

## Overview

The debug-hook API (F5 / #20) lets a host-side debugger (e.g. MoonSwift's
`DebugSession`) receive line/call/return events from the Lua VM, pause
execution at breakpoints, inspect locals/upvalues/globals, and direct the
VM via step-over/step-into/step-out commands. The API is designed for safe
use on a dedicated engine thread with a second thread driving the debugger UI.

## Event/Command vocabulary

### LuaDebugEvent

| Case | When it fires |
|------|--------------|
| `.line(Int)` | VM is **about to execute** the given source line |
| `.call(LuaStackFrame)` | VM has just **entered a function**; frame is level 0 |
| `.ret` | VM is **about to return** from a function |

The handler also receives `.call` for tail calls (normalised from
`LUA_HOOKTAILCALL` on 5.2+ and `LUA_HOOKTAILRET` on 5.1). In stepping mode
only `.line` events produce pauses; `.call`/`.ret` are delivered in
breakpoint mode (nil `stepState`) to inform the host of control flow without
pausing.

### LuaDebugCommand

| Case | Effect |
|------|--------|
| `.continueRun` | Resume execution; clear step state |
| `.stepInto` | Pause on the very next LINE event (any depth) |
| `.stepOver` | Pause on next LINE at current depth or shallower |
| `.stepOut` | Pause on next LINE strictly shallower than current depth |
| `.stop` | Abort via cancellation unwind; `runDebug` throws `.cancelled` |

## Concurrency model (synchronous handler + atomic `isPaused`)

The compositor hook fires **on the VM thread** (which holds the engine's
`NSRecursiveLock`). When a debug event passes the step check, LuaSwift:

1. Sets `isPaused = true` (`ManagedAtomic<Bool>`, sequentially consistent).
2. Creates a `DebugInspectorImpl` (validity-scoped).
3. Calls `handler(event, inspector)` **synchronously** — the lock stays held
   on the VM thread.
4. Invalidates the inspector.
5. Sets `isPaused = false`.
6. Processes the returned `LuaDebugCommand`.

### Why synchronous (divergence from PRD literal wording)

The PRD §F5 Round-2 detail described releasing the lock before blocking on a
semaphore. LuaSwift implements the same safety contract *without* releasing
the lock:

- **No deadlock.** Any concurrent `LuaEngine` method that would touch `L`
  reads `isPaused == true` *before* attempting `lock.lock()` and throws
  `LuaError.enginePaused` immediately. The lock is never contended across a
  debug pause.
- **No UB.** The VM is not executing instructions during the handler call
  (the compositor hook parks it). Only inert `LuaInspectedValue` snapshots —
  never a live `L` pointer — may escape the handler scope.
- **MoonSwift compatibility.** MoonSwift drives the engine on its own
  dedicated thread. The handler blocks *that thread* — which holds the lock
  — until the user issues a command. From other threads, `isPaused` guards
  prevent concurrent access. This is semantically equivalent to "block on
  semaphore" from the perspective of any other caller.

### `isPaused` guard

Every `LuaEngine` public method that touches `L` checks `isPaused` **before**
`lock.lock()`:

```swift
guard !isPaused.load(ordering: .sequentiallyConsistent) else {
    throw LuaError.enginePaused
}
lock.lock()
```

Methods covered: `run`, `evaluate` (source and `CompiledChunk` overloads and
deprecated raw-Data variants), `callLuaFunction`, `createCoroutine`, `resume`,
`globalNames`, `globalValue`. Non-throwing methods (`register`, `unregister`,
`registerFunction`, `unregisterFunction`, `destroy`) do not check the flag
(they cannot throw); a concurrent call from another thread will block on the
lock until the pause ends.

The `LuaDebugInspector` is the ONLY sanctioned interaction while paused.

## Coroutines

Lua installs hooks per `lua_State`, and each coroutine runs on its own thread
(`lua_State`). `runDebug` arms the full debug mask (`COUNT|LINE|CALL|RET`) on its
own thread.

**Host-driven coroutines are debuggable.** When a debug session is active (a
handler is installed via `setDebugHandler`), `resume(_:with:)` arms the *full*
debug mask on the coroutine's thread — not just `COUNT`. So `.line`/`.call`/`.ret`
events fire inside the coroutine body, and the debugger steps *into* a coroutine
resumed through the host API. The coroutine starts each resume in breakpoint mode
(no carried step state); the handler's returned `LuaDebugCommand`s drive stepping
as usual.

**In-Lua coroutines are debuggable too.** A coroutine created and resumed
entirely inside Lua (`co = coroutine.create(...); coroutine.resume(co)`, or
`coroutine.wrap`) is also stepped *into* while a debug session is active. For the
duration of each `runDebug`/`resume(_:with:)` call, `coroutine.create` and
`coroutine.wrap` are transparently routed through a hook-arming shim so every new
coroutine thread receives the full debug mask before it first runs; the standard
library functions are restored when the call returns, so non-debug runs are
untouched. Cancellation and the instruction limit are delivered for in-Lua
coroutines on the same footing as host-driven ones while stepping.

## Native stepping with tail-call handling

### Stack-depth measurement

Stepping decisions use a live stack-depth count:

```swift
func currentStackLevel(_ L: OpaquePointer) -> Int {
    var level: Int32 = 0
    var ar = lua_Debug()
    while lua_getstack(L, level, &ar) != 0 { level += 1 }
    return Int(level)
}
```

This is re-read from `lua_getstack` at every LINE event rather than maintained
as a counter incremented/decremented on CALL/RET. This sidesteps the tail-call
event divergence between Lua versions:

- **Lua 5.1** emits `LUA_HOOKCALL` + `LUA_HOOKTAILRET` for a tail call. The
  TAILRET fires *before* the tail-callee call (it represents the caller's
  return), so a counter would decrement before the callee enters.
- **Lua 5.2+** emit `LUA_HOOKCALL` + `LUA_HOOKTAILCALL` for a tail call. No
  matching return event fires for the tail-callee's return; the depth counter
  approach would over-count depth and incorrectly defer `stepOut`.

By re-reading the actual stack depth at each LINE event, both cases produce
the correct depth and stepping commands work identically on all versions.

### `shouldPauseForStep` semantics

```
stepState     | pauses when
--------------|-------------------------------------------
nil           | every LINE event (breakpoint mode)
.stepInto     | any LINE event
.stepOver(N)  | LINE when currentLevel <= N
.stepOut(N)   | LINE when currentLevel < N
```

The `<`/`<=` comparisons handle tail calls: after `f` tail-calls `g` and `g`
returns, the depth drops from `N` (inside `g`) to `N-1` (f's caller) — both
comparisons fire correctly because the frame collapse is already reflected in
the live `lua_getstack` count.

### Tail-call stepOut example

Given:

```lua
local function g()
  local x = 1      -- line 2
end
local function f()
  return g()       -- line 5: tail call
end
local r = f()      -- line 7
return r           -- line 8
```

Stepping into `f()` → LINE fires at line 5 (inside `f`) → stepInto → enters
`g` (tail call) → LINE fires at line 2 (inside `g`) → issuing `stepOut` here
with `fromLevel = currentLevel` → after `g` returns, the live depth is
`fromLevel - 1` which satisfies `< fromLevel` → pause fires at line 8 (the
return after `f()`'s call site), not at line 7 (already executed) or line 5
(inside `f`, which was collapsed by the tail call).

## Inspector lifetime and validity token

`DebugInspectorImpl.isValid` is `true` for the duration of the handler call.
Immediately after the handler returns, `invalidate()` flips it `false`. Every
public method `precondition(isValid, ...)` — use after the callback has
returned traps at the call site with a deterministic error rather than
silently reading stale state.

```swift
// CORRECT — inside the handler
let locals = inspector.locals(frameLevel: 0)  // fine

// WRONG — after the handler returns — TRAPS
let stale = inspector.locals(frameLevel: 0)   // precondition failure
```

If you need the values after the callback, snapshot them inside the callback:

```swift
engine.setDebugHandler { event, inspector in
    let snapshot = inspector.locals(frameLevel: 0)  // captured
    // Use snapshot later — it's a [LuaInspectedValue] which is Sendable
    return .continueRun
}
```

## LuaInspectedValue — eager snapshot contract

Reference-typed Lua values (function, table, userdata, thread) are returned
as `LuaInspectedValue.reference` — **never** as a re-invokable `LuaValue`.
`LuaValue.luaFunction(Int32)` carries a raw Lua registry index that could be
re-injected into any `lua_State`, creating a dangling reference. By returning
a self-contained snapshot instead, re-injection is impossible by construction
and the snapshot is valid after the callback ends.

### Materialisation rules

| Lua type | Result |
|----------|--------|
| nil/bool/number/string | `.scalar(LuaValue)` |
| table | `.reference(kind:.table, preview:, children:)` with raw `lua_next` (no `__pairs`/`__index`) |
| function/userdata/thread | `.reference(kind:, preview:, children: nil)` |

- **Depth cap:** table children are materialised up to 64 levels
  (`LuaInspectedValue.maxInspectionDepth`). A table at the cap depth returns
  `.reference(kind:.table, preview:"<depth limit>", children: nil)`
  (`isDepthLimited`).
- **Cycle detection:** a table pointer seen twice in the current walk returns
  `.reference(kind:.table, preview:"<cycle>", children: nil)` (`isCycle`).
- **Opaque previews (SEC-202):** reference previews are stable per-snapshot
  opaque ids — `"table #3"`, `"function #4"` — **not** raw heap addresses. The
  same object reads as the same `#n` within one `locals()`/`globals()` call.
  This keeps the Lua/host heap pointer from leaking into a preview string that
  could be serialised off-device (e.g. a remote-debug wire or an uploaded crash
  log), which would otherwise be an ASLR oracle.
- **Breadth bound (opt-in, SEC-201):** the inspector is **unbounded by default**
  — it faithfully materialises every entry of every table, because the host (not
  the library) owns the trust decision. When you debug *untrusted* Lua, build
  with `-D LUASWIFT_BOUNDED_INSPECTION` (env `LUASWIFT_BOUNDED_INSPECTION=1`):
  each table (and `_G` itself) then yields at most
  `LuaInspectedValue.boundedInspectionBreadth` (10,000) real children followed by
  one breadth-limit sentinel child (`isBreadthLimited`), instead of allocating
  one `Child` per entry under the held lock — the defense against an
  adversarial million-entry breadth bomb (host-memory-exhaustion DoS).
- **Raw access:** every level uses `lua_next` only — `__pairs`, `__index`,
  and `__len` are never invoked, consistent with the F4 raw-access discipline.

## `stop` → `LuaError.cancelled` terminal state

When the handler returns `.stop`, the compositor hook sets `abortReason = 1`
and raises `lua_error` with `cancelledSentinel` — the same path as
`requestCancellation()`. The in-flight `runDebug` call surfaces the result as
`LuaError.cancelled`.

MoonSwift's `DebugSession` knows it issued `.stop` (to `runDebug`) and treats
the resulting `.cancelled` as a debugger-stop — no separate `LuaError` case is
needed. A regular UI-cancel issued via `requestCancellation()` also produces
`.cancelled`; `DebugSession` distinguishes the two by tracking which operation
is in flight.

## Cancel-while-paused ordering

`requestCancellation()` is lock-free (atomic) and safe to call from any thread
including from inside the handler. If called while the VM is paused inside the
handler, the atomic cancellation flag is set. On the next run iteration (after
the handler returns `.continueRun`), the compositor hook's Step 1 reads the
flag and aborts, surfacing `LuaError.cancelled`. No automatic watchdog
escalates a pending cancel to `.stop` — the cancel takes effect on resume.

## No-debug overhead guarantee

Plain `run`/`evaluate` (with no `setDebugHandler`) arm ONLY `LUA_MASKCOUNT`
(the existing behaviour). `armDebugHook` is called exclusively from `runDebug`
paths. Inside `compositorHookCallback`, the debug branch is guarded by a
`nil`-check on `engine.debugHandler` — when `nil` the branch is eliminated
at `-O` optimisation level. Existing non-debug tests are unaffected.
