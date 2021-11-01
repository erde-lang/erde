local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

local Declaration = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Declaration.parse(ctx)
  local node = { rule = 'Declaration' }

  if ctx:branchWord('local') then
    node.variant = 'local'
  else
    ctx:branchWord('global')
    node.variant = 'global'
  end

  node.nameList = { ctx:Name().value }
  while ctx:branchChar(',') do
    node.nameList[#node.nameList + 1] = ctx:Name().value
  end

  if ctx:branchChar('=') then
    node.exprList = { ctx:Expr() }
    while ctx:branchChar(',') do
      node.exprList[#node.exprList + 1] = ctx:Expr()
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Declaration.compile(ctx, node)
  local compileParts = {}

  if node.variant == 'local' then
    compileParts[#compileParts + 1] = 'local'
  end

  compileParts[#compileParts + 1] = table.concat(node.nameList, ',')

  if node.exprList then
    local exprList = {}
    for i, expr in ipairs(node.exprList) do
      exprList[#exprList + 1] = ctx:compile(expr)
    end

    compileParts[#compileParts + 1] = '='
    compileParts[#compileParts + 1] = table.concat(exprList, ',')
  end

  return table.concat(compileParts, ' ')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Declaration
