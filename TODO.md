# TODO

# 0.5.1-2
- readd optional chaining
  - avoid iife when possible (be careful of conditional expressions)
- improve source map memory size
- add production compiler
  - format compiled code for readability
  - no sourcemap support
  - preserve comments
  - inject comments for compiled code workaround (ex. `continue` statements)
  - default compiler for cli (`erde compile`)
  - default compiler when sourcemaps are disabled

# 1.0-1

- rewrite erde in erde

# Future Plans

- converter? (lua -> erde)
- formatter? (unopiniated!)
  - auto indent
  - fix spaces
  - delete trailing whitespace / newlines
  - infer trailing commas
  - infer single vs multi line lists
  - NOTE: maybe this is better as a separate package?

# Possible Language Features (needs further discussion)
- function decorators (too non-lua-esque?)
- add autocompletions + command to install / uninstall autocompletions?
  - not tracked by luarocks
  - need to be installed / uninstalled manually by user...
