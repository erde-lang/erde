# TODO

- remove ruleName manipulations
- remove rules/init.lua method wrappers
- readd lua5.1+ support
- Formatting
  - Rule.format method
  - cli support `erde format [FILES]`
- erde REPL
- add real README
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

# Design Decisions (need to move to erde website)

## Do not allow multiple assignments at the same time.

This is not too widely used, arguable makes code more difficult to read, and 
isn't possible to support assignment operators and optional assignments due to
functions being able to support multiple returns:

```erde
a, { b }, c += oneOrTwoReturns(), anotherOneOrTwoReturns()
a, b?.c, d = oneOrTwoReturns(), anotherOneOrTwoReturns()
```

This only affects assignment. Multiple _declaractions_ are supported.
