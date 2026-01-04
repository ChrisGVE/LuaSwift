# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
