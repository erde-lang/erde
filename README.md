# Erde

## TODO

- replace in-house recursive compiler w/ native lpeg
    - map(pattern -> pattern / compiler)
    - match on compiler tree directly!
- integrate official erde-lang spec
  - lua table brackets
  - optional nested destructure
  - restore lua constructs
    - for loop, while loop, repeat until, do block (allow return!)
  - function piping (instead of macros!) `>>` syntax
- optional chaining function calls
- `kpairs` keyword
- `global` keyword + scope tracking
- automated tests
- lua versions
- order of operations?

## Proposals

- named export
- `recall` keyword? (recall the function of the current scope?)
- `demand` keyword (early return)
- case statement?
- shorthand self? need to support optional op?

## Long Term TODO

- Syntax highlighting
  - Vim
  - Emacs
  - Vscode
  - Treesitter
- erde cli
  - target various lua versions
  - luajit bytecode option?
- erde lib
  - allow mutating `require` (similar to moonscript)
- docs site
- Formatter
- Source maps?
- performance tuning + optimizations
