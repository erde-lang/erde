# TODO

# 0.5-1

- refactor rewriting to happen completely in compiled code (not in __erde_internal_load_source__)
- support cli args for repl (target, bitlib, etc)
- infer version automatically for `erde.load`
- override traceback on `erde.load`
- check error rewriting for run_string
- provide tests for error rewriting
- provide CLI option to emit / lookup sourcemaps
  - `erde sourcemap mymodule.erde` -> `mymodule.erde.map`
  - `erde sourcemap mymodule.erde 489` -> `128:73`
- support thread arg for `traceback` (support complete Lua compatability)

# 0.5-2
- add `cli`, `api`, `stability promise`, `new features`, and live editor in documentation
- add columns to source maps
- readd optional chaining
  - avoid iife when possible (be careful of conditional expressions)

# 1.0-1

- rewrite erde in erde

# Future Plans

- formatter (unopiniated!)
  - auto indent
  - fix spaces
  - delete trailing whitespace / newlines
  - infer trailing commas
  - infer single vs multi line lists
- Add erde config file to configure defaults for compiler, formatter, etc.
- converter? (lua -> erde)

# Possible Language Features (needs further discussion)
- function decorators (too non-lua-esque?)
- add autocompletions + command to install / uninstall autocompletions?
  - not tracked by luarocks
  - need to be installed / uninstalled manually by user...
