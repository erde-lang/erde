# TODO

- Formatting
  - Rule.format method
  - cli support `erde format [FILES]`

# v0.2.0

- refactor tests
  - separate parse and compile tests
  - add resolve tests
  - add format tests
- erde REPL
- Bug fixes

# v0.3.0

- Source maps (for runtime errors when using erde.loader)
- officially readd 5.1+ support
  - Not supported initially due to ease + not sure if will take advantage of
    LuaJIT specific optimizations + bitwise operator awkwardness
  - default compile to 5.1+ using closure constructors, allow optimizations 
    depending on compilation target (ex. only LuaJIT)
    - analyze usage and inject code. In particular, transform logical operations 
      into if constructs (ex. `local a = b or c ?? d`)

# Long Term TODO

- update website
  - remove pipe
  - add `main`
  - self shorthand
  - generic for loop destructuring
  - goto
  - hoisting top block vars
  - multi expression assignment
  - standard operators
  - do block expr
  - breaking varargs change (actually spread in table!)
- cache unchanged files?
- rewrite erde in erde
- completion scripts for libraries / environments?
  - want to provide LSP benefits of statically typed languages w/o static typing
  - kind of painful, like documentation needs manual tracking

# Uncertain Proposals (need community input)

- array destructure skipping
  - ex) `local [a, ..., c] = {1, 2, 3, 4, 5}`, (a, c) == (1, 5)
  - too seldom used??
- function return params (similar to golang)
  - ex) function double(t) (doubled = {}) {
          for _, n in ipairs(t) {
            table.insert(doubled, n * 2)
          }
        }
- macros
- python/js like decorators?
- nested break
- pipes
  - included (and even implemented) in original spec. Removed due to awkardness
    of functional programming style compared to rest of lua.
  - favor simple `do {}` exprs
- `defer` keyword
  - ex) `defer { return myDefaultExport }`
  - hard to optimize?

# Design Decisions (need to move to erde website)

## Changing negation to `!`

More standard and `~=` conflicts w/ the bitop `~` assignment operator.
