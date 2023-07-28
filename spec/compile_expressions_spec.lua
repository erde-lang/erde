local config = require('erde.config')
local lib = require('erde.lib')

-- -----------------------------------------------------------------------------
-- Terminal Expressions
-- -----------------------------------------------------------------------------

spec('terminal expression transform Lua keywords #5.1+', function()
  assert_run(1, [[
    local end = 1
    return end
  ]])

  assert_run(2, [[
    local a = { end = 2 }
    return a.end
  ]])

  assert_run(3, [[
    local end = { a = 3 }
    return end.a
  ]])

  assert_run(4, [[
    local t = { end = 4 }
    local key = 'end'
    return t[key]
  ]])
end)

spec('terminal expression use tracked scopes #5.1+', function()
  assert_run(1, [[
    global a = 0
    _G.a = 1
    local result = a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 2, b = 2 }, [[
    module a = 2
    module b = a
  ]])
end)

-- -----------------------------------------------------------------------------
-- Unary Operators
-- -----------------------------------------------------------------------------

spec('unops #5.1+', function()
  assert_eval(-1, '-1')
  assert_eval(1, '#("a")')
  assert_eval(false, '!true')

  if config.lua_target == '5.1+' or config.lua_target == '5.2+' then
    assert.has_error(function() compile('print(~1)') end)
  elseif config.lua_target == '5.2' then
    assert_eval(4294967294, '~1')
  else
    assert_eval(-2, '~1')
  end
end)

describe('unop precedence #5.1+', function()
  spec('below', function()
    assert_eval(1, '-1 + 2')
    assert_run(2, 'local a = "a"; return #a * 2')
    assert_eval(true, '!true || true')

    if config.lua_target == '5.2' then
      assert_eval(4294967299, '~1 + 5')
    elseif config.lua_target ~= '5.1+' and config.lua_target ~= '5.2+' then
      assert_eval(3, '~1 + 5')
    end
  end)

  spec('above', function()
    assert_eval(-1, '-1^2')
    assert.has_error(function() lib.run('local a = "a"; return #a^2') end)
    assert_eval(false, '!2^2')

    if config.lua_target == '5.2' then
      assert_eval(4294967294, '~1^2')
    elseif config.lua_target ~= '5.1+' and config.lua_target ~= '5.2+' then
      assert_eval(-2, '~1^2')
    end
  end)
end)

-- -----------------------------------------------------------------------------
-- Bit Operators
-- -----------------------------------------------------------------------------

spec('bitops #5.1+', function()
  if config.lua_target == '5.1+' or config.lua_target == '5.2+' then
    assert.has_error(function() compile('print(2 >> 1)') end)
    assert.has_error(function() compile('print(1 << 1)') end)
    assert.has_error(function() compile('print(2 | 1)') end)
    assert.has_error(function() compile('print(6 ~ 2)') end)
    assert.has_error(function() compile('print(7 & 5)') end)
  else
    assert_eval(1, '2 >> 1')
    assert_eval(2, '1 << 1')
    assert_eval(3, '2 | 1')
    assert_eval(4, '6 ~ 2')
    assert_eval(5, '7 & 5')
  end
end)

if config.lua_target ~= '5.1+' and config.lua_target ~= '5.2+' then
  describe('bitop precedence #5.1+', function()
    spec('below', function()
      assert_eval(true, '2 >> 1 == 1')
      assert_eval(true, '1 << 1 == 2')
      assert_eval(true, '2 | 1 == 3')
      assert_eval(true, '6 ~ 2 == 4')
      assert_eval(true, '7 & 5 == 5')
    end)

    spec('above', function()
      assert_eval(1, '4 >> 1 + 1')
      assert_eval(2, '1 << 2 - 1')
      assert_eval(3, '1 | 4 / 2')
      assert_eval(4, '2 ~ 3 * 2')
      assert_eval(5, '7 & 3 + 10')
    end)
  end)

  spec('bitop associativity #5.1+', function()
    assert_eval(1, '15 >> 2 >> 1')
    assert_eval(7, '15 >> (2 >> 1)')

    assert_eval(24, '3 << 2 << 1')
    assert_eval(48, '3 << (2 << 1)')
  end)
end

-- -----------------------------------------------------------------------------
-- Binary Operators
-- -----------------------------------------------------------------------------

spec('binop #5.1+', function()
	assert_eval(true, 'true || true')
	assert_eval(true, 'true || false')
	assert_eval(true, 'false || true')
	assert_eval(false, 'false || false')

	assert_eval(true, 'true && true')
	assert_eval(false, 'true && false')
	assert_eval(false, 'false && true')
	assert_eval(false, 'false && false')

	assert_eval(true, '0 == 0')
	assert_eval(false, '0 == 1')

	assert_eval(false, '0 != 0')
	assert_eval(true, '0 != 1')

	assert_eval(true, '0 <= 0')
	assert_eval(true, '0 <= 1')
	assert_eval(false, '0 <= -1')

	assert_eval(true, '0 >= 0')
	assert_eval(false, '0 >= 1')
	assert_eval(true, '0 >= -1')

	assert_eval(false, '0 < 0')
	assert_eval(true, '0 < 1')
	assert_eval(false, '0 < -1')

	assert_eval(false, '0 > 0')
	assert_eval(false, '0 > 1')
	assert_eval(true, '0 > -1')

	assert_eval('ab', '"a" .. "b"')

	assert_eval(1, '-1 + 2')
	assert_eval(2, '5 - 3')
	assert_eval(3, '1.5 * 2')
	assert_eval(4, '8 / 2')
	assert_eval(5, '11 // 2')
	assert_eval(6, '13 % 7')
	assert_eval(8, '2^3')
end)

describe('binop precedence #5.1+', function()
  assert_eval(true, 'true || true && false')
  assert_eval(true, 'true || false && false')
  assert_eval(7, '1 + 2 * 3')
end)

spec('binop associativity #5.1+', function()
  assert_eval(1, '3 - 1 - 1')
  assert_eval(3, '3 - (1 - 1)')

  assert_eval(2, '8 / 2 / 2')
  assert_eval(8, '8 / (2 / 2)')

  assert_eval(3, '14 // 2 // 2')
  assert_eval(14, '14 // (2 // 2)')

  assert_eval(4, '24 % 13 % 7')
  assert_eval(0, '24 % (13 % 7)')

  assert_eval(512, '2^3^2')
  assert_eval(64, '(2^3)^2')
end)

-- -----------------------------------------------------------------------------
-- Expressions
-- -----------------------------------------------------------------------------

spec('expressions #5.1+', function()
  assert_eval(11, '1 + 2 * 3 + 4')
  assert_eval(13, '(5 * 2) + 3')
  assert_eval(25, '5 * (2 + 3)')
end)
