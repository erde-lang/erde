local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- FunctionCall
-- -----------------------------------------------------------------------------

local FunctionCall = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function FunctionCall.parse(ctx)
  local node = ctx:OptChain()
  local last = node[#node]

  if not last then
    ctx:throwExpected('function call', true)
  elseif last.variant ~= 'params' then
    ctx:throwError('Id cannot be function call')
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return FunctionCall
