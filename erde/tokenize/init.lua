local CC = require('erde.compile.constants')
local state = require('erde.tokenize.state')

local tokenize_binary = require('erde.tokenize.tokenize_binary')
local tokenize_block_string = require('erde.tokenize.tokenize_block_string')
local tokenize_comment = require('erde.tokenize.tokenize_comment')
local tokenize_decimal = require('erde.tokenize.tokenize_decimal')
local tokenize_double_quote_string = require('erde.tokenize.tokenize_double_quote_string')
local tokenize_hex = require('erde.tokenize.tokenize_hex')
local tokenize_newline = require('erde.tokenize.tokenize_newline')
local tokenize_single_quote_string = require('erde.tokenize.tokenize_single_quote_string')
local tokenize_word = require('erde.tokenize.tokenize_word')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local look_ahead = tokenize_utils.look_ahead
local peek = tokenize_utils.peek

function tokenize_token()
  if state.char == '\n' then
    tokenize_newline()
  elseif state.char == ' ' or state.char == '\t' then
    consume()
  elseif CC.WORD_HEAD[state.char] then
    tokenize_word()
  elseif state.char == "'" then
    tokenize_single_quote_string()
  elseif state.char == '"' then
    tokenize_double_quote_string(tokenize_token)
  else
    local peek_two = peek(2)
    if peek_two == '--' then
      tokenize_comment()
    elseif peek_two == '0x' or peek_two == '0X' then
      tokenize_hex()
    elseif peek_two == '0b' or peek_two == '0B' then
      tokenize_binary()
    elseif CC.DIGIT[state.char] or (state.char == '.' and CC.DIGIT[look_ahead(1)]) then
      tokenize_decimal()
    elseif peek_two == '[[' or peek_two == '[=' then
      tokenize_block_string(tokenize_token)
    elseif CC.SYMBOLS[peek(3)] then
      commit(consume(3))
    elseif CC.SYMBOLS[peek_two] then
      commit(consume(2))
    else
      commit(consume())
    end
  end
end

return function(text, source_name)
  state:reset(text, source_name)

  if peek(2) == '#!' then
    local token = consume(2)

    while state.char ~= '' and state.char ~= '\n' do
      token = token .. consume()
    end

    commit(token)
  end

  while state.char ~= '' do
    tokenize_token()
  end

  return state
end
