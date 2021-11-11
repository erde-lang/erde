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
      parts = ctx:List({ rule = ctx.Expr }),
    }

    if #node.parts < 2 then
      ctx:throwError('numeric for too few parts')
    elseif #node.parts > 3 then
      ctx:throwError('numeric for too many parts')
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

    node.exprList = ctx:List({ rule = ctx.Expr })
  end

  node.body = ctx:Surround('{', '}', ctx.Block)
  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function ForLoop.compile(ctx, node)
  if node.variant == 'numeric' then
    local parts = {}
    for i, part in ipairs(node.parts) do
      parts[#parts + 1] = ctx:compile(part)
    end

    return ('for %s=%s do\n%s\nend'):format(
      node.name,
      table.concat(parts, ','),
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
