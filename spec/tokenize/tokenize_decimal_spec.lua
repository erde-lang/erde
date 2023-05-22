local tokenize = require('erde.tokenize')

local spec_utils = require('spec.utils')
local assert_token = spec_utils.assert_token
local assert_tokens = spec_utils.assert_tokens

spec('tokenize_decimal #5.1+', function()
  for i = 1, 9 do
    assert_token(tostring(i))
  end

  assert_token('123')
  assert_token('12300')
  assert_token('00123')
  assert_token('0012300')

  assert_token('.0')
  assert_token('0.0')
  assert_token('.123')
  assert_token('0.001')
  assert_token('0.100')
  assert_token('0.010')
  assert_token('9.87')

  assert_tokens({ '0', '.' }, '0.')
  assert_tokens({ '0', '.', 'e' }, '0.e')

  assert_token('1e2')
  assert_token('1E2')
  assert_token('1e+2')
  assert_token('1e-2')
  assert_token('1E+2')
  assert_token('1E-2')

  assert_token('1.23e29')
  assert_token('0.11E-39')

  assert.has_error(function() tokenize('9e') end)
  assert.has_error(function() tokenize('9e+') end)
  assert.has_error(function() tokenize('9e-') end)
end)
