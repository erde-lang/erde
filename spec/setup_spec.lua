local busted = require('busted')
local config = require('erde.config')
local lib = require('erde.lib')

config.lua_target = os.getenv('LUA_TARGET') or '5.1+'

function assert_eval(expected, source)
  if expected == nil then
    busted.assert.is_nil(lib.run('return ' .. source))
  else
    busted.assert.are.same(expected, lib.run('return ' .. source))
  end
end

function assert_run(expected, source)
  if expected == nil then
    busted.assert.is_nil(lib.run(source))
  else
    busted.assert.are.same(expected, lib.run(source))
  end
end
