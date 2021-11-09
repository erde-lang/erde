local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

local Declaration = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Declaration.parse(ctx)
  local node = {
    rule = 'Declaration',
    varList = {},
    exprList = {},
  }

  if ctx:branchWord('local') then
    node.variant = 'local'
  else
    ctx:branchWord('global')
    node.variant = 'global'
  end

  repeat
    local var = ctx:Switch({
      ctx.Name,
      ctx.Destructure,
    })

    if not var then
      ctx:throwExpected('name or destructure', true)
    end

    node.varList[#node.varList + 1] = var
  until not ctx:branchChar(',')

  if ctx:branchChar('=') then
    repeat
      node.exprList[#node.exprList + 1] = ctx:Expr()
    until not ctx:branchChar(',')
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
    if var.rule == 'Name' then
      nameList[#nameList + 1] = ctx:compile(var)
    elseif var.rule == 'Destructure' then
      local destructure = ctx:compile(var)
      nameList[#nameList + 1] = destructure.baseName
      compileParts[#compileParts + 1] = destructure.compiled
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
