local state = require('erde.tokenize.state')

local tokenize_newline = require('erde.tokenize.tokenize_newline')

local tokenize_utils = require('erde.tokenize.utils')
local consume = tokenize_utils.consume
local peek = tokenize_utils.peek
local throw = tokenize_utils.throw

return function()
  consume(2) -- '--'

  local is_block_comment, close_quote, close_quote_len = false, ']', 1

  if state.char == '[' then
    consume()

    while state.char == '=' do
      close_quote = close_quote .. consume()
      close_quote_len = close_quote_len + 1
    end

    if state.char == '[' then
      consume()
      is_block_comment = true
      close_quote = close_quote .. ']'
      close_quote_len = close_quote_len + 1
    end
  end

  if not is_block_comment then
    while state.char ~= '' and state.char ~= '\n' do
      consume()
    end
  else
    local comment_line = state.current_line

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
end
