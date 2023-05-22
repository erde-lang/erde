local CC = require('erde.compile.constants')

local spec_utils = require('spec.utils')
local assert_token = spec_utils.assert_token

spec('tokenize symbols #5.1+', function()
  for symbol in pairs(CC.SYMBOLS) do
    assert_token(symbol)
  end
end)
