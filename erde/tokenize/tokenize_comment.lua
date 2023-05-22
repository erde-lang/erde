local state = require('erde.tokenize.state')

local tokenize_newline = require('erde.tokenize.tokenize_newline')

local tokenize_utils = require('erde.tokenize.utils')
local consume = tokenize_utils.consume
local peek = tokenize_utils.peek
local throw = tokenize_utils.throw

local function tokenize_comment_head()
  consume(2) -- '--'

  local is_block_comment, equals = false, ''

  if state.char == '[' then
    consume()

    while state.char == '=' do
      equals = equals .. consume()
    end

    if state.char == '[' then
      consume()
      is_block_comment = true
    end
  end

  return is_block_comment, ']' .. equals .. ']'
end

local function tokenize_line_comment()
  while state.char ~= '' and state.char ~= '\n' do
    consume()
  end
end

local function tokenize_block_comment(close_quote)
  local close_quote_len = #close_quote
  local comment_line = state.current_line

  -- Check `state.char ~= ']'` first as slight optimization
  while state.char ~= ']' or peek(close_quote_len) ~= close_quote do
    if state.char == '' then
      throw('unterminated comment', comment_line)
    elseif state.char == '\n' then
      tokenize_newline()
    else
      consume()
    end
  end

  consume(close_quote_len)
end

return function()
  local is_block_comment, close_quote = tokenize_comment_head()

  if is_block_comment then
    tokenize_block_comment(close_quote)
  else
    tokenize_line_comment()
  end
end
