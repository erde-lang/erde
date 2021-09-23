# Erde

## TODO

- error handling
- automated tests
- add `...` as expr
- integrate official erde-lang spec
- add returns to do blocks (needs scope tracking)
- custom keywords
  - `global` (needs scope tracking)
  - `kpairs`
- lua versions (bit operators)
- order of operations?

## Proposals

- named export
- case statement?
- shorthand self? need to support optional op?

## Long Term TODO

- throw errors on undeclared variables
  - currently no way to differentiate between assignment + global declaration
- Syntax highlighting
  - Vim
  - Emacs
  - Vscode
  - Treesitter
- erde cli
- erde runtime lib
  - allow mutating `require` (similar to moonscript)
- docs site
- Formatter
- Source maps?
