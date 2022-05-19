# TODO

# 0.2-1

- fix empty file / only comments parsing
- upgrade cli
  - allow `erde test.erde`
  - autocompletion
  - refactor
  - add REPL
- throw error if only part of file is parsed
  - try to diagnose what went wrong?
  - change throw level. For certain errors we _know_ what the developer was 
    trying to do and should fatal exit
- officially readd 5.1+ support
  - support multiple bitwise operator compiles (best effort based on versions)
- throw errors for undeclared variables
- Source maps (for runtime errors when using erde.loader)
  - preserve line numbers when compiling

# 0.3-1

- Avoid closure creation (slow, cannot be JITed)
  - ex) compile assignment / declaration into if statements
- allow optimizations depending on compilation target
  - ex) exploit goto when available

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
- allow expression lists for assignment / return
  - ex) `local a, b = somecondition ? (1, 2) : (2, 3)`
