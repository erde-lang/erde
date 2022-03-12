# TODO

- more forgiving parser in order to allow for more convenient formatting
  - try to infer common mistakes (ex. missing comma)
  - separate parse errors from bad runtime prevention errors
    - ex. combining `module` w/ `return`, nested `module`, etc. are _technically_ not parsing errors, just errors that we will not crash at runtime.
    - 1. combining `module` w/ `return` or `main`
    - 1. using `continue` or `break` outside a loop block
- move shebang to separate tokenize field
- Fix String interpolation compilation bug (interpolated Name gets compiled to string content)
- Fix parens compilation
- refactor tests
  - separate parse and compile tests
  - add resolve tests

# v0.2.0

- Formatting
  - Rule.format method
  - cli support `erde format [FILES]`
- erde REPL
- Source maps (for runtime errors when using erde.loader)
- Bug fixes

# v0.3.0

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
- cache unchanged files?
- rewrite erde in erde
- completion scripts for libraries / environments?
  - want to provide LSP benefits of statically typed languages w/o static typing
  - kind of painful, like documentation needs manual tracking

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
