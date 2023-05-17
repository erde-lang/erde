local CC = require('erde.compile.constants')
local state = require('erde.tokenize.state')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume

return function()
  local token = consume()

  while CC.WORD_BODY[state.char] do
    token = token .. consume()
  end

  commit(token)
end
