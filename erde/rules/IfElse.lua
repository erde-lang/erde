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
  local compileParts = {
    ctx.format('if %1 then', ctx:compile(node.ifNode.cond)),
    ctx:compile(node.ifNode.body),
  }

  for _, elseifNode in ipairs(node.elseifNodes) do
    compileParts[#compileParts + 1] = ctx.format(
      'elseif %1 then',
      ctx:compile(elseifNode.cond)
    )
    compileParts[#compileParts + 1] = ctx:compile(elseifNode.body)
  end

  if node.elseNode then
    compileParts[#compileParts + 1] = 'else'
    compileParts[#compileParts + 1] = ctx:compile(node.elseNode.body)
  end

  compileParts[#compileParts + 1] = 'end'
  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return IfElse
