local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

local Declaration = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Declaration.parse(ctx)
  local node = {}

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
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Declaration
