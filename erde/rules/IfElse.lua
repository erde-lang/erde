local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

local IfElse = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function IfElse.parse(ctx)
  local node = { rule = 'IfElse', elseifNodes = {} }

  if not ctx:branchWord('if') then
    ctx:throwExpected('if')
  end

  node.ifNode = {
    cond = ctx:Expr(),
    body = ctx:Surround('{', '}', ctx.Block),
  }

  while ctx:branchWord('elseif') do
    node.elseifNodes[#node.elseifNodes + 1] = {
      cond = ctx:Expr(),
      body = ctx:Surround('{', '}', ctx.Block),
    }
  end

  if ctx:branchWord('else') then
    node.elseNode = { body = ctx:Surround('{', '}', ctx.Block) }
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function IfElse.compile(ctx, node)
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return IfElse
