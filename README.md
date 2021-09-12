# Erde

## TODO

- order of operations
  - ex) (y.b?.a) ?? 4 (paren necessary here w/ current parser)
- lua table brackets
- optional nested destructure
- restore lua constructs
  - for loop, while loop, repeat until, do block (allow return!)
- function piping (instead of macros!) `>>` syntax
  - take first return of one function as first argument of "next" function
- optional chaining function calls
- `kpairs` keyword
- `global` keyword + scope tracking
- automated tests

## Proposals

- named export
- `recall` keyword? (recall the function of the current scope?)
- `demand` keyword (early return)
- case statement?
- allow self in table declaration?
- replace self `@` with `$`?

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
