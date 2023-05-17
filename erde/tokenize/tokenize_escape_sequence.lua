local C = require('erde.constants')
local CC = require('erde.compile.constants')
local state = require('erde.tokenize.state')

local tokenize_utils = require('erde.tokenize.utils')
local consume = tokenize_utils.consume
local throw = tokenize_utils.throw

local function escape_sequence_z()
  if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
    throw('escape sequence \\z only compatible w/ lua targets 5.2+, jit')
  end

  return consume()
end

local function escape_sequence_x()
  if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
    throw('escape sequence \\xXX only compatible w/ lua targets 5.2+, jit')
  end

  local sequence = consume()

  for i = 1, 2 do
    if not CC.HEX[state.char] then
      throw('escape sequence \\xXX must use exactly 2 hex characters')
    end

    sequence = sequence .. consume()
  end

  return sequence
end

local function escape_sequence_u()
  local sequence = consume()

  if state.char ~= '{' then
    throw('missing { in escape sequence \\u{XXX}')
  elseif C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' or C.LUA_TARGET == '5.2' or C.LUA_TARGET == '5.2+' then
    throw('escape sequence \\u{XXX} only compatible w/ lua targets 5.3+, jit')
  end

  sequence = sequence .. consume()

  if not CC.HEX[state.char] then
    throw('missing hex in escape sequence \\u{XXX}')
  end

  while CC.HEX[state.char] do
    sequence = sequence .. consume()
  end

  if state.char ~= '}' then
    throw('missing } in escape sequence \\u{XXX}')
  end

  return sequence .. consume()
end

return function()
  if CC.STANDARD_ESCAPE_CHARS[state.char] then
    return consume()
  elseif CC.DIGIT[state.char] then
    return consume()
  elseif state.char == 'z' then
    return escape_sequence_z()
  elseif state.char == 'x' then
    return escape_sequence_x()
  elseif state.char == 'u' then
    return escape_sequence_u()
  else
    throw('invalid escape sequence \\' .. state.char)
  end
end
