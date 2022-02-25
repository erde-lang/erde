-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

local Declaration = { ruleName = 'Declaration' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Declaration.parse(ctx)
  local node = {
    isHoisted = false,
    varList = {},
    exprList = {},
  }

  if ctx:branch('local') then
    node.variant = 'local'
  elseif ctx:branch('global') then
    node.variant = 'global'
  elseif ctx.token == 'module' or ctx.token == 'main' then
    if not ctx.moduleBlock then
      error(ctx.token .. ' declarations cannot be nested')
    end

    node.variant = ctx:consume()
  else
    error('Missing declaration scope')
  end

  node.varList = ctx:List({ rule = ctx.Var })

  if node.variant == 'main' then
    if
      #node.varList > 1
      or type(node.varList[1]) ~= 'string'
      or ctx.moduleBlock.mainName ~= nil
    then
      error('Cannot have multiple main declarations')
    end

    ctx.moduleBlock.mainName = node.varList[1]
  end

  if ctx.moduleBlock and node.variant ~= 'global' then
    node.isHoisted = true
    local nameList = {}

    for _, var in ipairs(node.varList) do
      if type(var) == 'string' then
        table.insert(nameList, var)
      else
        for _, destruct in ipairs(var) do
          table.insert(nameList, destruct.alias or destruct.name)
        end
      end
    end

    for _, name in ipairs(nameList) do
      table.insert(ctx.moduleBlock.hoistedNames, name)
    end

    if node.variant == 'module' then
      for _, name in ipairs(nameList) do
        table.insert(ctx.moduleBlock.moduleNames, name)
      end
    end
  end

  if ctx:branch('=') then
    node.exprList = ctx:List({ rule = ctx.Expr })
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Declaration.compile(ctx, node)
  local declarationParts = {}
  local compileParts = {}

  if node.isHoisted then
    if #node.exprList == 0 then
      -- Nothing to do
      return ''
    end
  elseif node.variant ~= 'global' then
    table.insert(declarationParts, 'local')
  end

  local nameList = {}

  for i, var in ipairs(node.varList) do
    if type(var) == 'string' then
      table.insert(nameList, var)
    else
      local destructure = ctx:compile(var)
      table.insert(nameList, destructure.baseName)
      table.insert(compileParts, destructure.compiled)
    end
  end

  table.insert(declarationParts, table.concat(nameList, ','))

  if #node.exprList > 0 then
    local exprList = {}

    for i, expr in ipairs(node.exprList) do
      table.insert(exprList, ctx:compile(expr))
    end

    table.insert(declarationParts, '=')
    table.insert(declarationParts, table.concat(exprList, ','))
  end

  table.insert(compileParts, 1, table.concat(declarationParts, ' '))
  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Declaration
