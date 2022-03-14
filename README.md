# Erde

Erde is an expressive programming language that compiles to Lua. Syntactically 
it favors symbols over keywords and adds support for many features commonly 
found in other programming languages that Lua otherwise sacrifices for 
simplicity.

Erde currently only supports [LuaJIT](https://luajit.org/luajit.html), although
it may work on Lua5.2+ as well (not tested). Support for other Lua versions is 
planned to be added in the future (planned v0.3).

**NOTE:** Erde is still in early development. Some things may be undocumented or 
the documentation may be out of date. This note will be removed once the project 
starts to stabilize but feel free to mess around and open issues about any 
questions or concerns!

## Features

- arrow functions
- function parameter defaults
- table destructuring
- assignment operators (`+=`, `*=`, etc)
- optional chaining (`a?.b.c?[1]`)
- null coalescing operator (`??`)
- table spread operator (`...`)
- `continue` keyword
- try catch statement
- and more!

## Installation

The recommended way to install is via [luarocks](https://luarocks.org):

```
luarocks install erde
```

Alternatively, you can clone this repo and update your `$LUA_PATH`.

## Similar Projects

- [moonscript](https://moonscript.org): A programmer friendly language that compiles into Lua
- [fennel](https://fennel-lang.org): A lisp that compiles to Lua
- [teal](https://github.com/teal-language/tl): A typed dialect of Lua

## License

Copyright 2022 Brian Sutherland

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
