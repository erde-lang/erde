package = 'erde'
version = '0.1-1'
rockspec_format = '3.0'

description = {
  summary = 'A language that compile to Lua.',
  detailed = [[
    Erde is an expressive language that compiles to Lua. Syntactically it favors 
    symbols over keywords and adds support for many features commonly found in 
    other programming languages that Lua otherwise sacrifices for simplicity.
  ]],
  homepage = 'https://erde-lang.github.io/',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1, <= 5.4',
  'argparse',
	'luafilesystem',
}

source = {
   url = 'git://github.com/erde-lang/erde',
   branch = 'master',
}

build = {
  type = 'builtin',
  install = {
    bin = {
      ['erde'] = 'bin/erde'
    }
  },
}
