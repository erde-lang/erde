-- -----------------------------------------------------------------------------
-- FunctionCall
-- -----------------------------------------------------------------------------

local FunctionCall = { ruleName = 'FunctionCall' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function FunctionCall.parse(ctx)
  local node = ctx:OptChain()
  local last = node[#node]

  if not last or last.variant ~= 'functionCall' then
    error('Missing function call parentheses')
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return FunctionCall
