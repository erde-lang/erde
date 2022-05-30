# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning based on [LuaRocks rockspec](https://github.com/luarocks/luarocks/wiki/Rockspec-format).

## [0.2-1] - UNRELEASED

### Removed
- Remove `self` shorthand `$`. Completely unnecessary and confusing.
- Remove `main` keyword. Completely unnecessary and confusing.
- Remove ternary / null coalescing operator
  - Ternary created ambiguous syntax (`a ? b:c() : d()` vs `a ? b : c():d()`)
  - Both difficult to optimize (requires iife)

### Changed
- Refactor internal structure (now cleaner / faster)
- Use newline to differentiate syntax ambiguity
- No longer parse number destruct aliases as valid syntax
- Varargs now spreads when used as a table or param expression.
- Do not allow trailing comma in Return exprs unless parens are present
- `erde.loader` no longer mutates the global require function, but uses `package.loaders` (as it should)
- `catch` var no longer uses parentheses (more lua like)
- `catch` var can now be a destructure
- Array destructures can no longer be nested inside map destructures
- String interpolation is no longer supported for single quote strings
- The `erde` executable has been split into `erde` (interpreter) and `erdec` (compiler)
  - `argparse` does not allow arguments if subcommands are used, which means we
    could not do: `erde myfile.erde` to run a file. This was very unfriendly to
    scripts that may want to use a shebang with `erde`.
  - Use a similar structure as moonscript for familiarity.

### Fixed
- Tokenizer now correctly consumes whitespace in string interpolation.
- String interpolation w/ names now compiles correctly.
- Parenthesized Return now parses correctly.
- Keywords are now allowed as named index chains (ex: x.if, y:else()).
- `!=` operator is now _actually_ compiled.
- OptChain now correctly parses optional _method_ calls
- Fixed void `return` (i.e. no expressions)
- Parser / compiler no longer crash when the ast is empty

## [0.1-1] - March 3, 2022

Initial Release
