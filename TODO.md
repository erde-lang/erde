# TODO

- do not require expr for destructure declaration (multi returns)
- erde REPL
- add real README
- Formatting
  - Rule.format method
  - cli support `erde format [FILES]`
- release v0.1.0

# v0.2.0

- Source maps (for runtime errors when using erde.loader)
- Bug fixes
- up to 2 new language features

# Long Term TODO

- cache unchanged files?
- rewrite erde in erde
- remove closure compilations (ternary, null coalescence, optchain, etc).
  - analyze usage and inject code. In particular, transform logical operations into if constructs (ex. `local a = b or c ?? d`)
  - NOTE: cannot simply use functions w/ params (need conditional execution)

# Uncertain Proposals (need community input)

- macros
- decorators
- nested break
- `scope` keyword (allow scoped blocks)
  - ex) `local x = scope { return 4 }`
  - useful for grouping logical computations
- `defer` keyword
  - ex) `defer { return myDefaultExport }`
  - difficult, maybe impossible? dont know when return will happen?
- hoist top block vars?
  - or just allow module refs anywhere
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
