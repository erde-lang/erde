-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

local ForLoop = { ruleName = 'ForLoop' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function ForLoop.parse(ctx)
  local node
  ctx:assert('for')

  local firstName
  if ctx.token == '{' or ctx.token == '[' then
    firstName = ctx:Destructure()
  else
    firstName = ctx:Name()
  end

  if ctx:branch('=') then
    node = {
      variant = 'numeric',
      name = firstName,
      parts = ctx:List({ rule = ctx.Expr }),
    }

    if firstName.ruleName == 'Destructure' then
      error('Cannot use destructure in numeric for loop')
    elseif #node.parts < 2 then
      error('Invalid for loop parameters (missing parameters)')
    elseif #node.parts > 3 then
      error('Invalid for loop parameters (too many parameters)')
    end
  else
    node = { variant = 'generic' }

    node.varList = { firstName }
    while ctx:branch(',') do
      if ctx.token == '{' or ctx.token == '[' then
        table.insert(node.varList, ctx:Destructure())
      else
        table.insert(node.varList, ctx:Name())
      end
    end

    ctx:assert('in')
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
      table.insert(parts, ctx:compile(part))
    end

    return ('for %s=%s do\n%s\nend'):format(
      node.name.value,
      table.concat(parts, ','),
      ctx:compile(node.body)
    )
  else
    local prebody = {}

    local nameList = {}
    for i, var in ipairs(node.varList) do
      if var.ruleName == 'Destructure' then
        local destructure = ctx:compile(var)
        nameList[i] = destructure.baseName
        table.insert(prebody, destructure.compiled)
      else
        nameList[i] = var.value
      end
    end

    local exprList = {}
    for i, expr in ipairs(node.exprList) do
      exprList[i] = ctx:compile(expr)
    end

    return ('for %s in %s do\n%s\n%s\nend'):format(
      table.concat(nameList, ','),
      table.concat(exprList, ','),
      table.concat(prebody, '\n'),
      ctx:compile(node.body)
    )
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return ForLoop
