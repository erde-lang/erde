# TODO

# 0.5-1

- change: remove debug cli option
- fix: load erde in repl
- provide tests for error rewriting

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
