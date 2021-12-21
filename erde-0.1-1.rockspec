package = 'erde'
version = '0.1-1'
rockspec_format = '3.0'

source = {
   url = 'git://github.com/erde-lang/erde',
   branch = 'master',
}

description = {
  summary = 'A language that compile to Lua.',
  detailed = [[
    Erde is a language that compiles to Lua. It favors symbols over keywords and
    adds support to many features commonly found in other programming languages.
   ]],
  homepage = 'https://erde-lang.github.io/',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1, <= 5.4',
}

install = {
  bin = {
    ['erde'] = 'bin/erde'
  }
}
