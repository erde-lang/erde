-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

local IfElse = { ruleName = 'IfElse' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function IfElse.parse(ctx)
  local node = { elseifNodes = {} }
  ctx:assert('if')

  node.ifNode = {
    cond = ctx:Expr(),
    body = ctx:Surround('{', '}', ctx.Block),
  }

  while ctx:branch('elseif') do
    table.insert(node.elseifNodes, {
      cond = ctx:Expr(),
      body = ctx:Surround('{', '}', ctx.Block),
    })
  end

  if ctx:branch('else') then
    node.elseNode = { body = ctx:Surround('{', '}', ctx.Block) }
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function IfElse.compile(ctx, node)
  local compileParts = {
    'if ' .. ctx:compile(node.ifNode.cond) .. ' then',
    ctx:compile(node.ifNode.body),
  }

  for _, elseifNode in ipairs(node.elseifNodes) do
    table.insert(
      compileParts,
      'elseif ' .. ctx:compile(elseifNode.cond) .. ' then'
    )
    table.insert(compileParts, ctx:compile(elseifNode.body))
  end

  if node.elseNode then
    table.insert(compileParts, 'else')
    table.insert(compileParts, ctx:compile(node.elseNode.body))
  end

  table.insert(compileParts, 'end')
  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return IfElse
