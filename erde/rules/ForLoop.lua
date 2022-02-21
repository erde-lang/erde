-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

local ForLoop = { ruleName = 'ForLoop' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function ForLoop.parse(ctx)
  local node = {}
  ctx:assert('for')

  local firstName = ctx:Var()

  if ctx:branch('=') then
    node.variant = 'numeric'
    node.name = firstName
    node.parts = ctx:List({ rule = ctx.Expr })

    if type(firstName) == 'table' then
      error('Cannot use destructure in numeric for loop')
    elseif #node.parts < 2 then
      error('Invalid for loop parameters (missing parameters)')
    elseif #node.parts > 3 then
      error('Invalid for loop parameters (too many parameters)')
    end
  else
    node.variant = 'generic'
    node.varList = { firstName }

    while ctx:branch(',') do
      table.insert(node.varList, ctx:Var())
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
      ctx:compile(node.name),
      table.concat(parts, ','),
      ctx:compile(node.body)
    )
  else
    local prebody = {}

    local nameList = {}
    for i, var in ipairs(node.varList) do
      if type(var) == 'table' then
        local destructure = ctx:compile(var)
        nameList[i] = destructure.baseName
        table.insert(prebody, destructure.compiled)
      else
        nameList[i] = ctx:compile(var)
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
