local state = require('erde.tokenize.state')

local tokenize_utils = require('erde.tokenize.utils')
local consume = tokenize_utils.consume

return function ()
  state.current_line = state.current_line + 1
  return consume()
end
