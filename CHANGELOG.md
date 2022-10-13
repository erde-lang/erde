# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning based on [LuaRocks rockspec](https://github.com/luarocks/luarocks/wiki/Rockspec-format).

## [] - UNRELEASED

### Removed
- Erde no longer depends on [argparse](https://luarocks.org/modules/argparse/argparse)

### Added
- Added __tostring metamethod for thrown table errors (especially useful for sandboxed, embedded lua such as neovim)
- Added line numbers for errors when using `erde compile`
- Added basic REPL support

### Changed
- `erde run` no longer uses a subcommand
- `erde compile` and `erde clean` no longer default to cwd

### Fixed
- Fix assignment operator compiled operation
- Throw error when `return` statement is not the last statement in a block
- Fixed compilation error rewriting for asserts
- Fixed compilation of exponentiation operator for pre Lua5.3
- Fixed empty message when error does not have stacktrace

## [0.3-1] - August 26, 2022

### Removed
- Removed `do` expressions.
- Removed spread operator.
- Removed optional chaining.
- Removed `erde.loader` (replaced by `require('erde').load` api)

### Added
- Erde now supports running on Lua 5.1+
- `erde` now accepts Lua targets to compile to, with specific Lua version compatabilities
- `erde` now accepts specifying a bit library to compile bit operations to
- Erde now generates souce maps and will rewrite errors when running scripts via the CLI or using `erde.load`.
- Several new apis have been added both to replace `erde.loader` and to allow for better error handling
  - `erde.rewrite` - rewrite Lua errors using a source map. Does a best-effort
    lookup for cached source map when one is not provided
  - `erde.traceback` - erde version of `debug.traceback` w/ line rewrites
  - `erde.load` - replacement for `erde.loader`, with an optional lua target
    as a parameter.
  - `erde.unload` - api to remove the injected erde loader (from a previous call
    to `erde.load`).

### Changed
- Reverted split of `erde` and `erdec` in favor of more `pacman` like "main flags".
- Improved `erde --help` output.
- `erde` now runs with the regular lua shebang (`#!/usr/bin/env lua` instead of `#!/usr/bin/env luajit`)

## [0.2-1] - June 03, 2022

### Removed
- Removed `self` shorthand `$`. Completely unnecessary and confusing.
- Removed `main` keyword. Completely unnecessary and confusing.
- Removed ternary / null coalescing operator
  - Ternary created ambiguous syntax (`a ? b:c() : d()` vs `a ? b : c():d()`)
  - Both difficult to optimize (requires iife)

### Changed
- Refactored internal structure (now cleaner / faster)
- Erde now uses a newline to differentiate syntax ambiguity
- Erde no longer parses number destruct aliases as valid syntax
- Varargs now spreads when used as a table or param expression.
- Erde no longer allows trailing commas in Return expressions unless parentheses are present
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
