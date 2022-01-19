-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

local ForLoop = { ruleName = 'ForLoop' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function ForLoop.parse(ctx)
  assert(ctx:consume() == 'for')

  local firstName = ctx:Name().value
  local node

  if ctx:branch('=') then
    node = {
      variant = 'numeric',
      name = firstName,
      parts = ctx:List({ rule = ctx.Expr }),
    }

    if #node.parts < 2 then
      -- numeric for too few parts
      error()
    elseif #node.parts > 3 then
      -- numeric for too many parts
      error()
    end
  else
    node = { variant = 'generic' }

    node.nameList = { firstName }
    while ctx:branch(',') do
      node.nameList[#node.nameList + 1] = ctx:Name().value
    end

    assert(ctx:consume() == 'in')
    node.exprList = ctx:List({ rule = ctx.Expr })
  end

  node.body = ctx:Surround('{', '}', function()
    return ctx:Block({ isLoopBlock = true })
  end)

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
