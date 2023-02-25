# TODO

# 0.5-1

- provide CLI option to emit / lookup sourcemaps
  - `erde sourcemap mymodule.erde` -> `mymodule.erde.map`
  - `erde sourcemap mymodule.erde 489` -> `128:73`
- support thread arg for `traceback`
- test / debug current error rewriting (kinda buggy)
- add columns to source maps
- add `cli`, `api`, `stability promise`, `new features`, and live editor in documentation

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
- optional chaining?
  - avoid iife when possible (be careful of conditional expressions)
- function decorators (too non-lua-esque?)
- add autocompletions + command to install / uninstall autocompletions?
  - not tracked by luarocks
  - need to be installed / uninstalled manually by user...
