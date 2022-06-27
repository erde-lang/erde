# TODO

# 0.3-1

- remove opt chain (make erde more minimal)
- officially readd 5.1+ support
  - support multiple bitwise operator compiles (best effort based on versions)
- throw error if only part of file is parsed
- throw errors for undeclared variables (precompile)
- throw version errors for number forms
- throw version errors for escape valid escape chars
  - https://www.lua.org/manual/5.1/manual.html#2.1
  - https://www.lua.org/manual/5.4/manual.html#3.1
- vastly improve error messages / diagnosis
- Source maps (for runtime errors when using erde.loader)
  - preserve line numbers when compiling

# 0.4-1

- Optimize compiled code
  - Avoid closure creation (slow, cannot be JITed)
    - ex) compile assignment / declaration into if statements
  - allow optimizations depending on compilation target
    - ex) exploit goto when available

# 0.5-1

- +1 new features? macros?
- add CLI REPL

# 1.0-1

- rewrite erde in erde

# Future Proposals

- macros
- stdlib calls shorthand
  - `mytable::concat(',')` -> `table.concat(mytable, ',')`
  - `"some string"::sub(4)` -> `string.sub("some string", 4)`
