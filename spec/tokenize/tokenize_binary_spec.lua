local tokenize = require('erde.tokenize')

local spec_utils = require('spec.utils')
local assert_token = spec_utils.assert_token

spec('tokenize_binary #5.1+', function()
  assert_token('0', '0b0')
  assert_token('0', '0B0')
  assert_token('1', '0b1')
  assert_token('1', '0B1')

  assert_token('0', '0b00')
  assert_token('1', '0b01')
  assert_token('2', '0b10')
  assert_token('4', '0b0100')
  assert_token('12', '0B1100')

  assert.has_error(function() tokenize('0b') end)
  assert.has_error(function() tokenize('0B') end)
  assert.has_error(function() tokenize('0b3') end)
  assert.has_error(function() tokenize('0ba') end)
  assert.has_error(function() tokenize('0b.') end)
end)
