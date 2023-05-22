local tokenize = require('erde.tokenize')

local spec_utils = require('spec.utils')
local assert_tokens = spec_utils.assert_tokens

spec('tokenize_single_quote_string #5.1+', function()
  assert_tokens({ "'", "'" }, "''")
  assert_tokens({ "'", ' ', "'" }, "' '")
  assert_tokens({ "'", '\t', "'" }, "'\t'")

  assert_tokens({ "'", 'a', "'" }, "'a'")
  assert_tokens({ "'", ' a b ', "'" }, "' a b '")

  assert_tokens({ "'", "\\'", "'" }, "'\\''")
  assert_tokens({ "'", '\\n', "'" }, "'\\n'")

  assert.has_error(function() tokenize("'a") end)
  assert.has_error(function() tokenize("'\n'") end)
end)
