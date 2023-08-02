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

function assert_source_map(expected_error_line, source)
  local ok, result = xpcall(function() lib.run(source) end, lib.rewrite)

  busted.assert.are.equal(false, ok)

  local error_line = result:match('^[^:]+:(%d+)')
  busted.assert.are.equal(expected_error_line, tonumber(error_line))
end
