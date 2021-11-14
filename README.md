# Erde

## TODO

- optimistic errors (try to guess the attempted rule)
- Source maps?
- Declaration files?
- Optimizations: remove excessive iife compilation
    - DoBlock
    - Ternary
    - Null coalescence
    - ...

## Intended Proposals

- try catch
- spread operator `local x = { ...y }`
- keywords
  - break
  - kpairs
  - continue?

## Uncertain Proposals (need community input)

- decorators?
- import / export
- case statement?
- shorthand self? need to support optional op?
- boolean flag shorthands
  - local x = { myflag+ }
  - local x = { myotherflag- }
