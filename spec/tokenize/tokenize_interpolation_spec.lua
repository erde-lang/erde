local tokenize = require('erde.tokenize')

local spec_utils = require('spec.utils')
local assert_tokens = spec_utils.assert_tokens

spec('tokenize_interpolation #5.1+', function()
  assert_tokens({ "'", 'a{bc}d', "'" }, "'a{bc}d'")
  assert_tokens({ '"', 'a', '{', 'bc', '}', 'd', '"' }, '"a{bc}d"')
  assert_tokens({ '[[', 'a', '{', 'bc', '}', 'd', ']]' }, '[[a{bc}d]]')

  assert_tokens({ "'", 'a{ bc  }d', "'" }, "'a{ bc  }d'")
  assert_tokens({ '"', 'a', '{', 'bc', '}', 'd', '"' }, '"a{ bc  }d"')
  assert_tokens({ '[[', 'a', '{', 'bc', '}', 'd', ']]' }, '[[a{ bc  }d]]')

  assert_tokens({ '"', '{', '"', '{', 'a', '}', '"', '}', '"' }, '"{"{a}"}"')
  assert_tokens({ '[[', 'a', '{', '{', 'bc', '}', '}', 'd', ']]' }, '[[a{{bc}}d]]')

  assert.has_error(function() tokenize('"{a"') end)
  assert.has_error(function() tokenize('"{{a}"') end)
end)
