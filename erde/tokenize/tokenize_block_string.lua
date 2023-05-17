local state = require('erde.tokenize.state')

local tokenize_interpolation = require('erde.tokenize.tokenize_interpolation')
local tokenize_newline = require('erde.tokenize.tokenize_newline')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local peek = tokenize_utils.peek
local throw = tokenize_utils.throw

return function()
  consume() -- '['

  local open_quote, close_quote, quote_len = '[', ']', 1

  while state.char == '=' do
    consume()
    open_quote = open_quote .. '='
    close_quote = close_quote .. '='
    quote_len = quote_len + 1
  end

  if state.char ~= '[' then
    throw('unterminated block string opening', content_line)
  else
    consume()
    open_quote = open_quote .. '['
    close_quote = close_quote .. ']'
    quote_len = quote_len + 1
  end

  commit(open_quote)

  local content, content_line = '', state.current_line

  while state.char ~= ']' or peek(quote_len) ~= close_quote do
    if state.char == '' then
      throw('unterminated block string', content_line)
    elseif state.char == '\n' then
      content = content .. tokenize_newline()
    elseif state.char == '\\' then
      consume()
      if state.char == '{' or state.char == '}' then
        content = content .. consume()
      else
        content = content .. '\\' .. consume()
      end
    elseif state.char == '{' then
      if content ~= '' then
        commit(content, content_line)
        content, content_line = '', state.current_line
      end

      tokenize_interpolation(tokenize_token)
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content, content_line)
  end

  commit(consume(quote_len))
end
