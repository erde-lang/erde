# TODO

- add block assignment shorthands
  - ex) `local x = do { ... return result }`
- hoist top block vars
- Formatting
  - Rule.format method
  - cli support `erde format [FILES]`
- erde REPL
- update syntax repos w/ changes
- update website (port to hugo?)
- officially readd lua5.2+ support?
  - DO NOT SUPPORT 5.1. In the future we will make heavy use of `goto` in compiled 
  - code in order to avoid closure constructors, which cannot be JIT compiled
- add real README
- release v0.1.0

# v0.2.0

- more forgiving parser in order to allow for more convenient formatting
  - try to infer common mistakes (ex. missing comma)
  - separate parse errors from bad runtime prevention errors
    - ex. combining `module` w/ `return`, nested `module`, etc. are _technically_ not parsing errors, just errors that we will not crash at runtime.
    - 1. combining `module` w/ `return` or `main`
    - 1. using `continue` or `break` outside a loop block
- Source maps (for runtime errors when using erde.loader)
- Bug fixes
- NO NEW LANGUAGE FEATURES. focus on core improvements, more features later.

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
- pipes?
  - included (and even implemented) in original spec. Removed due to awkardness
  - of functional programming style compared to rest of lua.
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
