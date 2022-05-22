# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning based on [LuaRocks rockspec](https://github.com/luarocks/luarocks/wiki/Rockspec-format).

## [0.1-2] - UNRELEASED

### Removed
- Remove `self` shorthand `$`. Completely unnecessary and confusing.
- Remove `main` keyword. Completely unnecessary and confusing.

### Added
- Allow parenthesized lists for assignment / declarations vars and expressions.
- Add dedicated rule for Modules (top level block)
- Add `precompile` step for AST validation and node linking
- Use newline to differentiate syntax ambiguity

### Changed
- Refactor internal structure.
  - Collapse rules into single files based on steps
  - AST validation errors no longer throw when parsing
  - Split Expr rule into Binop / Unop rules, use Expr as pseudo rule.
  - Steps (`erde.parse`, `erde.compile`, etc) are no longer tables, but pure functions
- No longer parse number destruct aliases as valid syntax
- Varargs now spreads when used as a table or param expression.
- Do not allow trailing comma in Return exprs unless parens are present
- `erde.loader` no longer mutates the global require function, but uses `package.loaders` (as it should)
- `catch` var no longer uses parentheses (more lua like)
- `catch` var can now be a destructure
- Array destructures can no longer be nested inside map destructures

### Fixed
- Tokenizer now correctly consumes whitespace in string interpolation.
- String interpolation w/ names now compiles correctly.
- Parenthesized Return now parses correctly.
- Keywords are now allowed as named index chains (ex: x.if, y:else()).
- `!=` operator is now _actually_ compiled.
- OptChain now correctly parses optional _method_ calls
- Fixed void `return` (i.e. no expressions)

## [0.1-1] - March 3, 2022

Initial Release
