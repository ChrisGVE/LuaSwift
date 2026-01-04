# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Multi-version Lua support (5.1.5, 5.2.4, 5.3.6, 5.4.7, 5.5.0)
- Environment variable `LUASWIFT_LUA_VERSION` for version selection
- GitHub CI workflow for automated Lua version updates
- Types module for type detection and conversion
- Stdlib extension capability (`luaswift.extend_stdlib()`)
- Top-level global aliases for all modules

### Changed
- Default Lua version remains 5.4.7 for backwards compatibility

### Lua Versions
| Series | Bundled Version |
|--------|-----------------|
| 5.1    | 5.1.5           |
| 5.2    | 5.2.4           |
| 5.3    | 5.3.6           |
| 5.4    | 5.4.7           |
| 5.5    | 5.5.0           |

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
