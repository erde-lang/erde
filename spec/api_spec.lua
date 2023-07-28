local erde = require('erde')
local config = require('erde.config')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function make_load_spec(callback)
  return function()
    local old_lua_target = config.lua_target
    callback()
    config.lua_target = old_lua_target
  end
end

local function assert_rewrite(source, expected)
  local ok, result = xpcall(function() erde.run(source) end, erde.rewrite)
  assert.are.equal(false, ok)
  assert.are.equal(expected, result)
end

-- -----------------------------------------------------------------------------
-- API
-- -----------------------------------------------------------------------------

spec('api #5.1+', function()
  assert.are.equal(erde.compile, require('erde.compile'))
  assert.are.equal(erde.rewrite, require('erde.lib').rewrite)
  assert.are.equal(erde.traceback, require('erde.lib').traceback)
  assert.are.equal(erde.run, require('erde.lib').run)
  assert.are.equal(erde.load, require('erde.lib').load)
  assert.are.equal(erde.unload, require('erde.lib').unload)
end)

-- -----------------------------------------------------------------------------
-- Rewrite
-- -----------------------------------------------------------------------------

describe('erde.rewrite', function()
  spec('#jit #5.1 #5.2 #5.3', function()
    assert_rewrite(
      [[print('a' + 1)]],
      [[[string "print..."]:1: attempt to perform arithmetic on a string value]]
    )

    assert_rewrite(
      [[

        print('a' + 1)
      ]],
      [[[string "print..."]:2: attempt to perform arithmetic on a string value]]
    )

    assert_rewrite(
      [[print(
        'a' + 1)]],
      [[[string "print..."]:2: attempt to perform arithmetic on a string value]]
    )

    assert_rewrite(
      [[



      error('myerror')
      ]],
      [[[string "error..."]:4: myerror]]
    )
  end)

  spec('#5.4', function()
    assert_rewrite(
      [[print('a' + 1)]],
      [[[string "print..."]:1: attempt to add a 'string' with a 'number']]
    )

    assert_rewrite(
      [[

        print('a' + 1)
      ]],
      [[[string "print..."]:2: attempt to add a 'string' with a 'number']]
    )

    assert_rewrite(
      [[print(
        'a' + 1)]],
      [[[string "print..."]:2: attempt to add a 'string' with a 'number']]
    )

    assert_rewrite(
      [[



      error('myerror')
      ]],
      [[[string "error..."]:4: myerror]]
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

spec('erde.compile #5.1+', function()
  assert.has_no.errors(function()
    erde.compile('')
    erde.compile('', {})
    erde.compile('return')
    erde.compile('return', {})
  end)
end)

spec('erde.compile lua target #5.1+', function()
  assert.has.errors(function()
    erde.compile('goto test', { lua_target = '5.1' })
  end)
  assert.has_no.errors(function()
    erde.compile('goto test', { lua_target = 'jit' })
  end)
end)

spec('erde.compile bitlib #5.1+', function()
  local compiled = erde.compile('print(1 & 1)', { bitlib = 'mybitlib' })
  assert.is_not.falsy(compiled:find('mybitlib'))
end)

spec('erde.compile alias #5.1+', function()
  local ok, result = pcall(function()
    erde.compile('print(', { alias = 'myalias' })
  end)

  assert.are.equal(false, ok)
  assert.are.equal('myalias:1: unexpected eof (expected expression)', result)
end)

spec('erde.compile returns #5.1+', function()
  local compiled, sourcemap = erde.compile('')
  assert.are.equal(type(compiled), 'string')
  assert.are.equal(type(sourcemap), 'table')

  local compiled, sourcemap = erde.compile('print("")')
  assert.are.equal(type(compiled), 'string')
  assert.are.equal(type(sourcemap), 'table')
end)

-- -----------------------------------------------------------------------------
-- Run
-- -----------------------------------------------------------------------------

spec('erde.run #5.1+', function()
  assert.has_no.errors(function()
    erde.run('')
    erde.run('', {})
    erde.run('return')
    erde.run('return', {})
  end)
end)

spec('erde.run bitlib #5.1+', function()
  local ok, result = pcall(function()
    return erde.run('print(1 & 1)', { bitlib = 'mybitlib' })
  end)

  assert.are.equal(false, ok)
  assert.is_not.falsy(result:find("module 'mybitlib' not found"))
end)

spec('erde.run alias #5.1+', function()
  local ok, result = pcall(function()
    erde.run('print(', { alias = 'myalias' })
  end)

  assert.are.equal(false, ok)
  assert.are.equal('myalias:1: unexpected eof (expected expression)', result)

  local ok, result = xpcall(function()
    erde.run('error("myerror")', { alias = 'myalias' })
  end, erde.rewrite)

  assert.are.equal(false, ok)
  assert.are.equal('myalias:1: myerror', result)
end)

spec('erde.run disable source maps #5.1+', function()
  local ok, result = xpcall(function()
    erde.run('error("myerror")', {
      alias = 'myalias',
      disable_source_maps = true,
    })
  end, erde.rewrite)

  assert.are.equal(false, ok)
  assert.are.equal('myalias:(compiled:1): myerror', result)
end)

spec('erde.run multiple returns #5.1+', function()
  local a, b, c = erde.run('return 1, 2, 3')
  assert.are.equal(a, 1)
  assert.are.equal(b, 2)
  assert.are.equal(c, 3)
end)

-- -----------------------------------------------------------------------------
-- Load / Unload
-- -----------------------------------------------------------------------------

local searchers = package.loaders or package.searchers
local native_num_searchers = #searchers
local native_traceback = debug.traceback

spec('erde.load #5.1+', make_load_spec(function()
  erde.load()
  assert.are.equal(native_num_searchers + 1, #searchers)
end))

spec('erde.load repeated calls #5.1+', make_load_spec(function()
  erde.load()
  assert.are.equal(native_num_searchers + 1, #searchers)
  erde.load()
  assert.are.equal(native_num_searchers + 1, #searchers)
end))

spec('erde.load parameters #5.1+', make_load_spec(function()
  assert.has_no.errors(function()
    erde.load()
    erde.load('5.1')
    erde.load('5.1', {})
    erde.load({})
  end)
end))

spec('erde.load Lua target #5.1+', make_load_spec(function()
  erde.load('5.1')
  assert.are.equal('5.1', config.lua_target)

  assert.has.errors(function()
    erde.load('5.5') -- invalid target
  end)
end))

spec('erde.load keep_traceback #5.1+', make_load_spec(function()
  erde.load({ keep_traceback = true })
  assert.are.equal(native_traceback, debug.traceback)

  erde.load({ keep_traceback = false })
  assert.are_not.equal(native_traceback, debug.traceback)
end))

spec('erde.load bitlib #5.1+', make_load_spec(function()
  erde.load({ bitlib = 'mybitlib' })
  assert.are.equal(config.bitlib, 'mybitlib')
end))

spec('erde.load disable_source_maps #5.1+', make_load_spec(function()
  erde.load({ disable_source_maps = true })
  assert.are.equal(true, config.disable_source_maps)

  local ok, result = xpcall(function()
    erde.run('error("myerror")', { alias = 'myalias' })
  end, erde.rewrite)

  assert.are.equal(false, ok)
  assert.are.equal('myalias:(compiled:1): myerror', result)
end))

spec('erde.unload #5.1+', make_load_spec(function()
  erde.load() -- reset any flags
  erde.unload()
  assert.are.equal(native_num_searchers, #searchers)
end))
