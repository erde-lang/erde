# TODO

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
- shebang
- add real README
- release v0.1.0

# v0.2.0

- erde REPL
- Formatting
  - Rule.format method
  - cli support `erde format [FILES]`
- more forgiving parser in order to allow for more convenient formatting
  - try to infer common mistakes (ex. missing comma)
  - separate parse errors from bad runtime prevention errors
    - ex. combining `module` w/ `return`, nested `module`, etc. are _technically_ not parsing errors, just errors that we will not crash at runtime.
    - 1. combining `module` w/ `return` or `main`
    - 1. using `continue` or `break` outside a loop block
- Source maps (for runtime errors when using erde.loader)
- Bug fixes

# v0.3.0

- TYPES
- remove closure compilations (ternary, null coalescence, optchain, etc).
  - analyze usage and inject code. In particular, transform logical operations into if constructs (ex. `local a = b or c ?? d`)
  - NOTE: cannot simply use functions w/ params (need conditional execution)

# Long Term TODO

- officially readd lua5.2+ support?
  - Not supported initially due to ease + not sure if will take advantage of
    LuaJIT specific optimizations + bitwise operator awkwardness
  - DO NOT SUPPORT 5.1. In the future we will make heavy use of `goto` in compiled 
    code in order to avoid closure constructors, which cannot be JIT compiled
- cache unchanged files?
- rewrite erde in erde

# Uncertain Proposals (need community input)

- macros
- decorators
- nested break
- pipes
  - included (and even implemented) in original spec. Removed due to awkardness
    of functional programming style compared to rest of lua.
  - favor simple `do {}` exprs
- `defer` keyword
  - ex) `defer { return myDefaultExport }`
  - difficult, maybe impossible? dont know when return will happen?

# Design Decisions (need to move to erde website)

## Changing negation to `!`

More standard and `~=` conflicts w/ the bitop `~` assignment operator.
