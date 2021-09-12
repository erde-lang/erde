local inspect = require('inspect')
local lpeg = require('lpeg')
local rules = require('rules')

-- -----------------------------------------------------------------------------
-- Parser
-- -----------------------------------------------------------------------------

local grammar = lpeg.P(rules.parser)

function parse(subject)
  lpeg.setmaxstack(1000)
  state.reset()
  local ast = grammar:match(subject, nil, {})
  return ast or {}, state
end

return {
  parse = require('parser'),
  compile = require('compiler'),
}
