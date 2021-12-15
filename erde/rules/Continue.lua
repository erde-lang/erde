-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

local Continue = { ruleName = 'Continue' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Continue.parse(ctx)
  local node = {}

  if ctx.loopBlock == nil then
    -- No loop for `continue`
    error()
  end

  ctx:assertWord('continue')
  local continueNodes = ctx.loopBlock.continueNodes
  continueNodes[#continueNodes + 1] = node
  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Continue.compile(ctx, node)
  return table.concat({
    node.continueName .. ' = true',
    'break',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Continue
