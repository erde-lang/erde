package = 'erde'
version = '1.0.0-1'
rockspec_format = '3.0'

description = {
  summary = 'A modern Lua dialect',
  detailed = [[
    Erde is an programming language that compiles to Lua. It uses a more symbol
    favored syntax (similar to languages such as Rust, Golang, JavaScript, etc)
    and has been designed to map very closely to Lua.
  ]],
  homepage = 'https://erde-lang.github.io/',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1, <= 5.4',
	'luafilesystem',
}

source = {
   url = 'git://github.com/erde-lang/erde',
   tag = '1.0.0-1',
}

build = {
  type = 'builtin',
  install = {
    bin = {
      ['erde'] = 'erde/cli.lua',
    }
  },
}
