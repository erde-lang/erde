local spec_utils = require('spec.utils')
local assert_token = spec_utils.assert_token
local assert_tokens = spec_utils.assert_tokens

spec('tokenize_word #5.1+', function()
  assert_token('lua')
  assert_token('Erde')
  assert_token('_test')
  assert_token('aa1B_')
  assert_token('_aa1B')

  assert_tokens({ 'a', '-' }, 'a-')
  assert_tokens({ '1', 'abc' }, '1abc')
end)
