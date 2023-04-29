# TODO

# 0.5.1-2
- fix erde loaders not handling multiple returns
- improve programmatic usage
  - allow passing compile options
  - allow passing source map into rewrite
  - allow disabling source maps (`load`, `run`)
  - allow only options are for `load`: `load({ keep_traceback = true })`
  - update `traceback` to handle: "If message is present but is neither a string nor nil, this function returns message without further processing."
  - provide `erde.main` or `erde.mount` api
      - call `load`
      - `xpcall` require
      - rewrite and rethrow on error
- readd optional chaining
  - avoid iife when possible (be careful of conditional expressions)
- add production compiler
  - format compiled code for readability
  - no sourcemap support
  - preserve comments
  - inject comments for compiled code workaround (ex. `continue` statements)
  - default compiler for cli (`erde compile`)

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
- add autocompletions + command to install / uninstall autocompletions?
  - not tracked by luarocks
  - need to be installed / uninstalled manually by user...
