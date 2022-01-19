# TODO

- improved error messages (add pcalls, Rule.diagnose)
  - pcalls + Rule.diagnose
  - Continue parsing on errors (ignore rest of line, try next line for Statement until succeeds)
- formatter (Rule.format)
- erde REPL

# Long Term TODO

- add real README
- release v0.1.0
- rewrite erde in erde
- Source maps
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

# Ideas

Modes
- mode operator for statements / blocks. parsed only when mode is active
  - specified via `erde run !dev`
  - uses `!` operator in code
  - allow mode for expressions, `true` when active otherwise false
  - allow mode 'nesting' using `:`

```erde
-- only runs in `dev` mode, i.e. `erde run !dev`
!dev local x = 2

-- runs in `dev` and `test` mode
!dev !test print()

-- functions
!unit local function setupUnitTests() {

}

-- nesting, both run on mode == 'unit:myFunc'
!unit setupUnitTests()
!unit:myFunc myFunc()

-- multiline works nice
!dev !test !debug
print()

-- block, debug mode
!debug {

}

-- mode expressions
local x = !dev ? 1 : 2

if !dev {
  
} else {

}
```
