local CC = require('erde.compile.constants')
local state = require('erde.tokenize.state')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local look_ahead = tokenize_utils.look_ahead
local throw = tokenize_utils.throw

return function()
  consume(2) -- 0[xX]
  local token = 0

  if not CC.HEX[state.char] and not (state.char == '.' and CC.HEX[look_ahead(1)]) then
    throw('malformed hex')
  end

  while CC.HEX[state.char] do
    token = 16 * token + tonumber(consume(), 16)
  end

  if state.char == '.' and CC.HEX[look_ahead(1)] then
    consume()

    local counter = 1
    token = token + tonumber(consume(), 16) / (16 ^ counter)

    while CC.HEX[state.char] do
      counter = counter + 1
      token = token + tonumber(consume(), 16) / (16 ^ counter)
    end
  end

  if state.char == 'p' or state.char == 'P' then
    consume()
    local exponent, sign = 0, 1

    if state.char == '+' or state.char == '-' then
      sign = sign * tonumber(consume() .. '1')
    end

    if not CC.DIGIT[state.char] then
      throw('missing exponent value')
    end

    while CC.DIGIT[state.char] do
      exponent = 10 * exponent + tonumber(consume())
    end

    token = token * 2 ^ (sign * exponent)
  end

  commit(tostring(token))
end
