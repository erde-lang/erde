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
    node = {
      rule = 'ForLoop',
      variant = 'numeric',
      name = firstName,
      var = ctx:Expr(),
    }

    if not ctx:branchChar(',') then
      ctx:throwExpected(',')
    end

    node.limit = ctx:Expr()

    if ctx:branchChar(',') then
      node.step = ctx:Expr()
    end
  else
    node = { rule = 'ForLoop', variant = 'generic' }

    node.nameList = { firstName }
    while ctx:branchChar(',') do
      node.nameList[#node.nameList + 1] = ctx:Name().value
    end

    if not ctx:branchWord('in') then
      ctx:throwExpected('in')
    end

    node.exprList = ctx:List({ parens = false })
  end

  node.body = ctx:Surround('{', '}', ctx.Block)
  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function ForLoop.compile(ctx, node)
  if node.variant == 'numeric' then
    return ('for %s=%s,%s,%s do\n%s\nend'):format(
      node.name,
      ctx:compile(node.var),
      ctx:compile(node.limit),
      node.step and ctx:compile(node.step) or '1',
      ctx:compile(node.body)
    )
  else
    local exprList = {}
    for i, expr in ipairs(node.exprList) do
      exprList[i] = ctx:compile(expr)
    end

    return ('for %s in %s do\n%s\nend'):format(
      table.concat(node.nameList, ','),
      table.concat(exprList, ','),
      ctx:compile(node.body)
    )
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return ForLoop
