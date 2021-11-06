local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

local RepeatUntil = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function RepeatUntil.parse(ctx)
  if not ctx:branchWord('repeat') then
    ctx:throwExpected('repeat')
  end

  local node = {
    rule = 'RepeatUntil',
    body = ctx:Surround('{', '}', ctx.Block),
  }

  if not ctx:branchWord('until') then
    ctx:throwExpected('until')
  end

  node.cond = ctx:Surround('(', ')', ctx.Expr)

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function RepeatUntil.compile(ctx, node)
  return ('repeat\n%s\nuntil (%s)'):format(
    ctx:compile(node.body),
    ctx:compile(node.cond)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return RepeatUntil
