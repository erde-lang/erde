# Erde

Erde is a programming language that compiles to Lua. It uses a more symbol
favored syntax (similar to languages such as Rust, Golang, JavaScript, etc) and
has been designed to map very closely to Lua.

## Installation

The recommended way to install is through [luarocks](https://luarocks.org/modules/bsuth/erde):

```bash
luarocks install erde
```

Alternatively you can clone this repo and update your
[LUA_PATH](https://www.lua.org/pil/8.1.html) accordingly:

```bash
git clone https://github.com/erde-lang/erde.git
ERDE_ROOT="$(pwd)/erde"
export LUA_PATH="$ERDE_ROOT/?.lua;$ERDE_ROOT/?/init.lua;$LUA_PATH"

# To use the CLI:
alias erde="lua $ERDE_ROOT/cli/init.lua"
```

You can check whether Erde is installed correctly by running:

```bash
erde -h
```

## Similar Projects

There is a comprehensive list of [languages that compile to Lua](https://github.com/hengestone/lua-languages),
but the following are some such languages that Erde took inspiration from.

- [moonscript](https://moonscript.org): A programmer friendly language that compiles into Lua
- [fennel](https://fennel-lang.org): A lisp that compiles to Lua
- [teal](https://github.com/teal-language/tl): A typed dialect of Lua

## License

Copyright 2023 Brian Sutherland

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
