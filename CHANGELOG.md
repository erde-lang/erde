# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning based on [LuaRocks rockspec](https://github.com/luarocks/luarocks/wiki/Rockspec-format).

## [0.2-1] - UNRELEASED

Main Focuses: Internal Restructuring, Formatting, Website

### Added
- Allow parenthesized lists for assignment / declarations vars and expressions.
- Add dedicated rule for Modules (top level block)
- Add `precompile` step for AST validation and node linking
- Use newline to differentiate syntax ambiguity
- Add code formatter

### Changed
- Lua-style block comments are no longer valid
  - Not used often
  - Enforce consistency across projects
  - Completely replaceable w/ single line comments
  - Very hard to preserve when formatting
- Varargs now spreads when used as a table or param expression.
- Do not allow trailing comma in Return exprs unless parens are present
- No longer parse number destruct aliases as valid syntax
- AST validation errors no longer throw when parsing
  - Parsing is much more lenient so we may apply formatting
  - AST validation now happens in `resolve.lua`
- Refactor internal structure (step based rather than rule based).
- Split Expr rule into Binop / Unop rules, use Expr as pseudo rule.
- Steps (`erde.parse`, `erde.compile`, etc) are no longer tables, but pure functions
  - Can no longer call specific rules / pseudo-rules directly
  - Leads to cleaner code and less backwards compat
- `erde.loader` no longer mutates the global require function, but uses `package.loaders` (as it should)
- `catch` var no longer uses parentheses (more lua like)
- `catch` var can now be a destructure

### Fixed
- Tokenizer now correctly consumes whitespace in string interpolation.
- String interpolation w/ names now compiles correctly.
- Parenthesized Return now parses correctly.
- Keywords are now allowed as named index chains (ex: x.if, y:else()).
- `!=` operator is now _actually_ compiled.
- OptChain now correctly parses optional _method_ calls

## [0.1-1] - March 3, 2022

Initial Release
