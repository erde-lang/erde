local spec_utils = require('spec.utils')
local assert_token_lines = spec_utils.assert_token_lines

spec('tokenize_newline #5.1+', function()
  assert_token_lines({ 1, 2 }, 'a\nb')
  assert_token_lines({ 1, 1, 2, 2 }, 'hello world\ngoodbye world')
end)
