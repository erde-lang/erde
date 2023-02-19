# TODO

# 0.5-1

- refactor file structure (more modular)
  - make cli subdir (split commands into files)
  - make compile subdir (w/ tokenizer compile)
  - split lib (package.lua, errors.lua)
- Allow strings as index chain bases
  - ex) `"hello %s":format(name)`
- debug compiling for `erde.load` and `erde` cli
  - wrap function call bodies in xpcall to rewrite errors.
  - wrap destructures in case trying to destructure non table
  - allow option to overwrite `debug.traceback` (for environments like neovim)
    - maybe just keep `traceback` exposed in erde api and add documentation
    - `debug.traceback = require('erde').traceback`
- test / debug current error rewriting (kinda buggy)
- add columns to source maps
- provide CLI option to lookup sourcemaps
  - `erde sourcemap mymodule.erde 489` -> `128:73`
- add `api`, `new features`, and live editor in documentation

# 1.0-1

- rewrite erde in erde

# Future Plans

- formatter (unopiniated!)
  - auto indent
  - fix spaces
  - delete trailing whitespace / newlines
  - infer trailing commas
  - infer single vs multi line lists
- converter? (lua -> erde)

# Possible Language Features (needs further discussion)
- function decorators (too non-lua-esque?)
- opt chaining?
  - avoid iife when possible (be careful of conditional expressions)
- add autocompletions + command to install / uninstall autocompletions?
  - not tracked by luarocks
  - need to be installed / uninstalled manually by user...
