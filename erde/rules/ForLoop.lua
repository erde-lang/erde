local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

local ForLoop = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function ForLoop.parse(ctx)
  if not ctx:branchWord('for') then
    ctx:throwExpected('for')
  end

  local firstName = ctx:Name().value
  local node

  if ctx:branchChar('=') then
    node = { variant = 'numeric', name = firstName, var = ctx:Expr() }

    if not ctx:branchChar(',') then
      ctx:throwExpected(',')
    end

    node.limit = ctx:Expr()

    if ctx:branchChar(',') then
      node.step = ctx:Expr()
    end
  else
    node = { variant = 'generic', nameList = {}, exprList = {} }

    node.nameList[1] = firstName
    while ctx:branchChar(',') do
      node.nameList[#node.nameList + 1] = ctx:Name().value
    end

    if not ctx:branchWord('in') then
      ctx:throwExpected('in')
    end

    node.exprList[1] = ctx:Expr()
    while ctx:branchChar(',') do
      node.exprList[#node.exprList + 1] = ctx:Expr()
    end
  end

  node.body = ctx:Surround'{', '}', ctx.Block)

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function ForLoop.compile(ctx, node)
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return ForLoop
