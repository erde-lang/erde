local state = require('erde.tokenize.state')

local tokenize_escape_sequence = require('erde.tokenize.tokenize_escape_sequence')
local tokenize_interpolation = require('erde.tokenize.tokenize_interpolation')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local throw = tokenize_utils.throw

return function(tokenize_token)
  commit(consume()) -- quote

  -- Keep track of content_line in case interpolation has newline
  local content_line, content = state.current_line, ''

  while state.char ~= '"' do
    if state.char == '' or state.char == '\n' then
      throw('unterminated string')
    elseif state.char == '\\' then
      consume()
      content = content .. ((state.char == '{' or state.char == '}') and consume() or '\\' .. tokenize_escape_sequence())
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

  commit(consume()) -- quote
end
