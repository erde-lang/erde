# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning based on [LuaRocks rockspec](https://github.com/luarocks/luarocks/wiki/Rockspec-format).

## [0.2-1] - UNRELEASED

### Added
- Allow parenthesized lists for assignment / declarations vars and expressions.
- Add dedicated rule for Modules (top level block)
- Add `precompile` step for AST validation and node linking

### Changed
- Refactor internal structure (step based rather than rule based).
- AST validation errors no longer throw when parsing
  - Parsing is much more lenient so we may apply formatting
  - AST validation now happens in `resolve.lua`
- Varargs now spreads when used as a table or param expression.

### Fixed
- String interpolation w/ names now compiles correctly.

## [0.1-1] - March 3, 2022

Initial Release
