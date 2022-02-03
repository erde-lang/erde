# TODO

- add goto rule and use goto in compilation
- Source maps (for runtime errors when using erde.loader)
- erde REPL
- formatter (Rule.format)
- add real README
- final refactor, extensive tests
  - more comments
  - better naming
  - remove workarounds
  - test rule interaction
  - test general parse, compile, etc.
- release v0.1.0

# Long Term TODO

- cache unchanged files?
- rewrite erde in erde
- remove closure compilations (ternary, null coalescence, optchain, etc).
  - analyze usage and inject code. In particular, transform logical operations into if constructs (ex. `local a = b or c ?? d`)
  - NOTE: cannot simply use functions w/ params (need conditional execution)

# Uncertain Proposals (need community input)

- hoist top block vars?
- macros
- decorators
- nested break
- `scope` keyword (allow scoped blocks)
  - ex) `local x = scope { return 4 }`
  - useful for grouping logical computations
- `defer` keyword
  - ex) `defer { return myDefaultExport }`
- optional types
- allow module refs anywhere
  - lua requires declarations to happen before reference
  - compile to forward declare top level module variables
  - ex) 
    ```erde
      local function a() { b() }`
      local function b() { ... }`
    ```
    ```lua
      local a, b
      a = function() b() end
      b = function() ... end
    ```
