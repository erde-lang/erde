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

  if not last then
    error()
  elseif last.variant ~= 'functionCall' then
    -- Id cannot be function call
    error()
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return FunctionCall
