local state = require('erde.tokenize.state')

local tokenize_interpolation = require('erde.tokenize.tokenize_interpolation')
local tokenize_newline = require('erde.tokenize.tokenize_newline')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local peek = tokenize_utils.peek
local throw = tokenize_utils.throw

local function tokenize_block_string_quote()
  consume() -- '['

  local equals = ''
  while state.char == '=' do
    equals = equals .. consume()
  end

  if state.char ~= '[' then
    throw('unterminated block string opening', state.current_line)
  end

  consume() -- '['
  commit('[' .. equals .. '[')

  return ']' .. equals .. ']'
end

return function()
  local close_quote = tokenize_block_string_quote()
  local close_quote_len = #close_quote
  local content_line, content = state.current_line, ''

  -- Check `state.char ~= ']'` first as slight optimization
  while state.char ~= ']' or peek(close_quote_len) ~= close_quote do
    if state.char == '' then
      throw('unterminated block string', content_line)
    elseif state.char == '\n' then
      content = content .. tokenize_newline()
    elseif state.char == '\\' then
      consume()
      content = content .. ((state.char == '{' or state.char == '}') and consume() or '\\')
    elseif state.char == '{' then
      if content ~= '' then commit(content, content_line) end
      content_line, content = state.current_line, ''
      tokenize_interpolation(tokenize_token)
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content, content_line)
  end

  commit(consume(close_quote_len))
end
