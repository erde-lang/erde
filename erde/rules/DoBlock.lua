local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

local DoBlock = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function DoBlock.parse(ctx)
  if not ctx:branchWord('do') then
    ctx:throwExpected('do')
  end

  local node = {
    rule = 'DoBlock',
    body = ctx:Surround('{', '}', ctx.Block),
  }

  for _, statement in pairs(node.body) do
    if statement.rule == 'Return' then
      node.hasReturn = true
      break
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function DoBlock.compile(ctx, node)
  return ctx.format(
    node.hasReturn and 'function()\n%1\nend' or 'do\n%1\nend',
    ctx:compile(node.body)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return DoBlock
