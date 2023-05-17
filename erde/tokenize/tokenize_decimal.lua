local CC = require('erde.compile.constants')
local state = require('erde.tokenize.state')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local look_ahead = tokenize_utils.look_ahead
local throw = tokenize_utils.throw

return function()
  local token = ''

  while CC.DIGIT[state.char] do
    token = token .. consume()
  end

  if state.char == '.' and CC.DIGIT[look_ahead(1)] then
    token = token .. consume(2)
    while CC.DIGIT[state.char] do
      token = token .. consume()
    end
  end

  if state.char == 'e' or state.char == 'E' then
    token = token .. consume()

    if state.char == '+' or state.char == '-' then
      token = token .. consume()
    end

    if not CC.DIGIT[state.char] then
      throw('missing exponent value')
    end

    while CC.DIGIT[state.char] do
      token = token .. consume()
    end
  end

  commit(token)
end
