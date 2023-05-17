local state = require('erde.tokenize.state')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local throw = tokenize_utils.throw

return function(tokenize_token)
  commit(consume()) -- '{'

  -- Keep track of brace depth to differentiate end of interpolation from
  -- nested braces
  local brace_depth, interpolation_line = 0, state.current_line

  while state.char ~= '}' or brace_depth > 0 do
    if state.char == '{' then
      brace_depth = brace_depth + 1
      commit(consume())
    elseif state.char == '}' then
      brace_depth = brace_depth - 1
      commit(consume())
    elseif state.char == '' then
      throw('unterminated interpolation', interpolation_line)
    else
      tokenize_token()
    end
  end

  commit(consume()) -- '}'
end
