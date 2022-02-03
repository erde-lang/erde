-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

local RepeatUntil = { ruleName = 'RepeatUntil' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function RepeatUntil.parse(ctx)
  ctx:assert('repeat')

  local node = {
    body = ctx:Surround('{', '}', function()
      return ctx:Block({ isLoopBlock = true })
    end),
  }

  ctx:assert('until')
  node.cond = ctx:Expr()

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function RepeatUntil.compile(ctx, node)
  return ('repeat\n%s\nuntil %s'):format(
    ctx:compile(node.body),
    ctx:compile(node.cond)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return RepeatUntil
