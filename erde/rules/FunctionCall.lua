local erdestd = require('erde.std')

-- -----------------------------------------------------------------------------
-- FunctionCall
-- -----------------------------------------------------------------------------

local FunctionCall = { ruleName = 'FunctionCall' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function FunctionCall.parse(ctx)
  local isStdFunction = ctx:branchChar('!')
  local node = ctx:OptChain()
  local last = node[#node]

  if not last then
    error()
  elseif last.variant ~= 'functionCall' then
    -- Id cannot be function call
    error()
  end

  if isStdFunction then
    if node.base.ruleName ~= 'Name' then
      error()
    end

    local stdName = node.base.value

    if erdestd[stdName] == nil then
      error()
    end

    node.base.value = erdestd[stdName].name
    ctx.stdNames[stdName] = true
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return FunctionCall
