-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

local WhileLoop = { ruleName = 'WhileLoop' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function WhileLoop.parse(ctx)
  if not ctx:branchWord('while') then
    error()
  end

  return {
    cond = ctx:Expr(),
    body = ctx:Surround('{', '}', function()
      return ctx:Block({ isLoopBlock = true })
    end),
  }
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function WhileLoop.compile(ctx, node)
  return ('while %s do\n%s\nend'):format(
    ctx:compile(node.cond),
    ctx:compile(node.body)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return WhileLoop
