-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

local Continue = { ruleName = 'Continue' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Continue.parse(ctx)
  return ctx:branchWord('continue') and {} or ctx:throwExpected('continue')
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