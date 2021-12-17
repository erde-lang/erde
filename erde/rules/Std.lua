local erdestd = require('erde.std')

-- -----------------------------------------------------------------------------
-- Std
-- -----------------------------------------------------------------------------

local Std = { ruleName = 'Std' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Std.parse(ctx)
  ctx:assertChar('!')

  local stdCall = ctx:FunctionCall()
  if stdCall.base.ruleName ~= 'Name' then
    error()
  end

  local name = stdCall.base.value
  if erdestd[name] == nil then
    error()
  end

  stdCall.base.value = erdestd[name].name
  ctx.stdNames[name] = true
  return stdCall
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Std
