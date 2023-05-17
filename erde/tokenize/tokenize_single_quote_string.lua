local state = require('erde.tokenize.state')

local tokenize_escape_sequence = require('erde.tokenize.tokenize_escape_sequence')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local throw = tokenize_utils.throw

return function()
  commit(consume()) -- quote

  local content = ''

  while state.char ~= "'" do
    if state.char == '' or state.char == '\n' then
      throw('unterminated string')
    elseif state.char == '\\' then
      content = content .. consume() .. tokenize_escape_sequence()
    else
      content = content .. consume()
    end
  end

  if content ~= '' then
    commit(content)
  end

  commit(consume()) -- quote
end
