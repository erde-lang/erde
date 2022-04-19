# TODO

- Fix syntax highlighting
  - parenthesized declaration / assignment
  - `({ x = 1 })()` parens
  - do expressions `if do { ... } { }`
- format.lua
  - add comments / newlines
  - break binop ONLY on lowest precedence level
- fix empty file / only comments parsing
- refactor tests
  - add more compile tests
  - add format tests
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

# v0.3.0

Main Focuses: Error Handling, CLI, 5.1+ Support

- throw error if only part of file is parsed
  - try to diagnose what went wrong?
  - change throw level. For certain errors we _know_ what the developer was 
    trying to do and should fatal exit
- Source maps (for runtime errors when using erde.loader)
  - preserve line numbers when compiling
- upgrade cli
  - autocompletion
  - refactor
  - add REPL
  - official manifest.erde spec
- officially readd 5.1+ support
  - Not supported initially due to ease + not sure if will take advantage of
    LuaJIT specific optimizations + bitwise operator awkwardness
  - default compile to 5.1+ using closure constructors, allow optimizations 
    depending on compilation target (ex. only LuaJIT)
    - analyze usage and inject code. In particular, transform logical operations 
      into if constructs (ex. `local a = b or c ?? d`)

# v0.4.0

- Auto remove unnecessary parens in expressions when formatting

# Long Term TODO

- cache unchanged files?
- rewrite erde in erde
- completion scripts for libraries / environments?
  - want to provide LSP benefits of statically typed languages w/o static typing
  - kind of painful, like documentation needs manual tracking
- builtin unit testing?

# Uncertain Proposals (need community input)

- macros
- python/js like decorators?
  - too magical?
  - hard to read?
- nested break
