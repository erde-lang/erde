local busted = require('busted')
local lib = require('erde.lib')

-- -----------------------------------------------------------------------------
-- General Asserts
-- -----------------------------------------------------------------------------

local function assert_subtable(expected, got)
  busted.assert.is_table(expected)
  busted.assert.is_table(got)

  for key, value in pairs(args[1]) do
    if type(value) == 'table' then
      if not subtable(state, { value, args[2][key] }) then
        return false
      end
    elseif value ~= args[2][key] then
      return false
    end
  end

  return true
end

-- -----------------------------------------------------------------------------
-- Compile Asserts
-- -----------------------------------------------------------------------------

local function assert_eval(expected, source)
  busted.assert.same(expected, lib.run('return ' .. source))
end

local function assert_run(expected, source)
  busted.assert.same(expected, lib.run(source))
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  assert_token = assert_token,
  assert_tokens = assert_tokens,
  assert_num_tokens = assert_num_tokens,
  assert_token_lines = assert_token_lines,
  assert_eval = assert_eval,
  assert_run = assert_run,
}
