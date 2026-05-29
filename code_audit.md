# LuaSwift 1.8.0 Code Audit

Date: 2026-05-29
Scope: `git diff v1.7.0..main` — the 1.8.0 release (instruction-count limit, bytecode
compilation, complex-dispatch mathx, ArraySwift 0.2.0 bindings, power-series, optional
Thales CAS, tablex comprehensions, UI dialog module, slice notation).
Method: two parallel adversarial auditors (correctness + security). Cross-confirmed
findings noted. Prior audit `code_audit.md`@2026-01-20 superseded by this file; its
still-open sandbox/memory items are folded into the issues below.

## Headline-feature verdict (the MVP-critical paths SlipStick consumes)

- **Instruction-count limit** — was armed only on `run`/`evaluate`/`runBytecode`/
  `evaluateBytecode`. Two entry points ran unbounded: `callLuaFunction` and coroutine
  `resume` (hooks are per-`lua_State` in 5.4; never set on the coroutine thread). Both
  auditors found this independently. **FIXED** (97a5a93): centralized arming in
  `armInstructionHook(on:)`, called from all six entry points; error paths routed
  through `errorFromCode` so the limit surfaces as `.instructionLimitExceeded`
  consistently. Regression tests added for both paths.
- **Bytecode compile/run/evaluate** — `lua_dump` buffer management and
  `luaL_loadbufferx` mode `"b"` usage are correct and memory-safe; the instruction
  limit applies on the bytecode path. The only gap is provenance (see #9).

## Fixed in this release (committed)

| Finding | Severity | Commit | Resolution |
|---|---|---|---|
| Instruction hook not armed on `callLuaFunction` + coroutine `resume` | HIGH | 97a5a93 | Centralized `armInstructionHook(on:)` at all 6 entry points + tests |
| `Int32(instructionLimit)` traps for values > 2^31-1 | MEDIUM | 97a5a93 | Clamp `setInstructionLimit` to `[0, Int32.max]` + tests |
| Instruction-limit detection via generic substring (misclassification risk) | LOW | 97a5a93 | Private sentinel `__luaswift_instruction_limit_exceeded__` |
| ThalesModule empty `catch {}` on setup (invisible failure) | HIGH* | f5e91d5 | DEBUG log, matching other modules (*opt-in module) |
| Bytecode portability/provenance undocumented | LOW | 97a5a93 | `@Important` doc warning on `compile()` |
| Coroutine bounding undocumented | LOW | 97a5a93 | `setInstructionLimit` doc lists all bounded entry points |

## Deferred → GitHub issues (out of 1.8.0 / MVP scope)

| Issue | Severity | Summary | Why deferred |
|---|---|---|---|
| [#9](https://github.com/ChrisGVE/LuaSwift/issues/9) | HIGH→LOW | Bytecode API loads unvalidated `Data`; Lua 5.4 verifier is a no-op | Residual LOW for self-compiled+cached use under iOS sandbox; doc warning added. Opaque-type fix reworks consumer cache shape. |
| [#10](https://github.com/ChrisGVE/LuaSwift/issues/10) | HIGH | UIModule iOS main-thread deadlock | Opt-in module, not in default `installModules`, unused by SlipStick |
| [#11](https://github.com/ChrisGVE/LuaSwift/issues/11) | MEDIUM | No Lua VM memory limit / single C-function calls uninterruptible | Bigger work (custom allocator); SlipStick mitigates via SEC-03 (removes string.rep/format) |
| [#12](https://github.com/ChrisGVE/LuaSwift/issues/12) | MEDIUM | Module-setup failures silently swallowed in release | Systemic pre-existing pattern; needs `register` signature change |
| [#13](https://github.com/ChrisGVE/LuaSwift/issues/13) | MEDIUM | Code-size: LuaEngine.swift 1997, ArrayModule+Phase2 782 | Tech debt refactor |
| [#14](https://github.com/ChrisGVE/LuaSwift/issues/14) | LOW | Thales (opt-in) package.loaded require-access + unbounded order params | Gated behind LUASWIFT_THALES, not in SlipStick |

## Areas assessed clean

ArrayModule+Phase2 (FFT/setops/indexing), SeriesModulePower, MathXModule complex
dispatch, StringX/UTF8X slice notation (step=0 rejected, bounds clamped), TableX
comprehensions (pure Lua), MathExprModule NumericSwift 0.2.1 migration, ModuleRegistry
refactor. No new sandbox-escape or memory-corruption surface in any of these.
