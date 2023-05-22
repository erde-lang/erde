local tokenize = require('erde.tokenize')

local spec_utils = require('spec.utils')
local assert_tokens = spec_utils.assert_tokens
local assert_num_tokens = spec_utils.assert_num_tokens

spec('tokenize_comment #5.1+', function()
  assert_num_tokens(0, '--')
  assert_num_tokens(0, '--a')
  assert_num_tokens(0, '-- a')
  assert_num_tokens(1, '--\na')
  assert_num_tokens(1, '--a\nb')

  assert_num_tokens(1, '--[=a\nb')
  assert_num_tokens(1, '-- [[a\nb')

  assert_num_tokens(0, '--[[a]]')
  assert_num_tokens(0, '--[[ a ]]')
  assert_num_tokens(0, '--[[a\nb]]')
  assert_num_tokens(1, '--[[a]]b')

  assert_num_tokens(0, '--[[[=[]]')
  assert_num_tokens(0, '--[[]=]]')
  assert_num_tokens(0, '--[=[[[]=]')
  assert_num_tokens(0, '--[=[]]]=]')

  assert_num_tokens(1, '-- [[a\nb')
  assert_num_tokens(3, 'x + --[[hi]] 4')

  assert.has_error(function() tokenize('--[[hello world') end)
  assert.has_error(function() tokenize('--[[hello world]=]') end)
  assert.has_error(function() tokenize('--[=[hello world]]') end)
end)
