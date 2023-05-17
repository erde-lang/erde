local state = require('erde.tokenize.state')

local tokenize_utils = require('erde.tokenize.utils')
local commit = tokenize_utils.commit
local consume = tokenize_utils.consume
local throw = tokenize_utils.throw

return function()
  consume(2) -- 0[bB]
  local token = 0

  if state.char ~= '0' and state.char ~= '1' then
    throw('malformed binary')
  end

  repeat
    token = 2 * token + tonumber(consume())
  until state.char ~= '0' and state.char ~= '1'

  commit(tostring(token))
end
