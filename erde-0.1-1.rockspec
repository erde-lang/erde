package = 'erde'
version = '0.1-1'
rockspec_format = '3.0'

source = {
   url = 'git://github.com/erde-lang/erde',
   branch = 'master',
}

description = {
  summary = 'summary', -- TODO
  detailed = [[
      This is an example for the LuaRocks tutorial.
      Here we would put a detailed, typically
      paragraph-long description.
   ]], -- TODO
  homepage = 'https://erde-lang.github.io/',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1, <= 5.4',
}
