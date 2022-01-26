-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

local Continue = { ruleName = 'Continue' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Continue.parse(ctx)
  assert(ctx.loopBlock ~= nil)
  assert(ctx:consume() == 'continue')

  local node = {}
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
