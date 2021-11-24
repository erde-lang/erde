-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

local Declaration = { ruleName = 'Declaration' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Declaration.parse(ctx)
  local node = {
    varList = {},
    exprList = {},
  }

  if ctx:branchWord('local') then
    node.variant = 'local'
  elseif ctx:branchWord('module') then
    if not ctx.moduleBlock then
      ctx:throwError('Module declarations only allowed at the top level')
    end

    local moduleNodes = ctx.moduleBlock.moduleNodes
    moduleNodes[#moduleNodes + 1] = node
    node.variant = 'module'
  else
    ctx:branchWord('global')
    node.variant = 'global'
  end

  node.varList = ctx:List({
    rule = function()
      return ctx:Switch({
        ctx.Name,
        ctx.Destructure,
      })
    end,
  })

  if ctx:branchChar('=') then
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

  if node.variant == 'local' then
    declarationParts[#declarationParts + 1] = 'local'
  end

  local nameList = {}

  for i, var in ipairs(node.varList) do
    if var.ruleName == 'Name' then
      nameList[#nameList + 1] = ctx:compile(var)
    elseif var.ruleName == 'Destructure' then
      local destructure = ctx:compile(var)
      nameList[#nameList + 1] = destructure.baseName
      compileParts[#compileParts + 1] = destructure.compiled
    end
  end

  if node.variant == 'module' then
    for i, name in ipairs(nameList) do
      nameList[i] = node.moduleName .. '.' .. name
    end
  end

  declarationParts[#declarationParts + 1] = table.concat(nameList, ',')

  if #node.exprList > 0 then
    local exprList = {}

    for i, expr in ipairs(node.exprList) do
      exprList[#exprList + 1] = ctx:compile(expr)
    end

    declarationParts[#declarationParts + 1] = '='
    declarationParts[#declarationParts + 1] = table.concat(exprList, ',')
  end

  table.insert(compileParts, 1, table.concat(declarationParts, ' '))
  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Declaration
