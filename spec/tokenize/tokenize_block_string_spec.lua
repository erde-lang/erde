local tokenize = require('erde.tokenize')

local spec_utils = require('spec.utils')
local assert_tokens = spec_utils.assert_tokens

spec('tokenize_block_string #5.1+', function()
  assert_tokens({ '[[', ']]' }, '[[]]')
  assert_tokens({ '[[', ' ', ']]' }, '[[ ]]')
  assert_tokens({ '[[', '\t', ']]' }, '[[\t]]')
  assert_tokens({ '[[', '\n', ']]' }, '[[\n]]')

  assert_tokens({ '[[', ' hello world ', ']]' }, '[[ hello world ]]')
  assert_tokens({ '[[', 'hello\nworld', ']]' }, '[[hello\nworld]]')

  assert_tokens({ '[[', '[=[', ']]' }, '[[[=[]]')
  assert_tokens({ '[[', ']=', ']]' }, '[[]=]]')
  assert_tokens({ '[=[', '[[', ']=]' }, '[=[[[]=]')
  assert_tokens({ '[=[', ']]', ']=]' }, '[=[]]]=]')

  assert_tokens({ '[[', '\\', ']]' }, '[[\\]]')
  assert_tokens({ '[[', '\\u', ']]' }, '[[\\u]]')

  assert_tokens({ '[[', '{a}', ']]' }, '[[\\{a}]]')
  assert_tokens({ '[[', '{a}', ']]' }, '[[\\{a\\}]]')
  assert_tokens({ '[[', '{', 'a', '}', ']]' }, '[[{a}]]')

  assert.has_error(function() tokenize('[=hello world]=]') end)
  assert.has_error(function() tokenize('[[hello world') end)
  assert.has_error(function() tokenize('[[hello world]=]') end)
  assert.has_error(function() tokenize('[=[hello world]]') end)
end)
