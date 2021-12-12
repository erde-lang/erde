-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

local TryCatch = { ruleName = 'TryCatch' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function TryCatch.parse(ctx)
  local node = {}

  ctx:assertWord('try')
  node.try = ctx:Surround('{', '}', ctx.Block)

  ctx:assertWord('catch')
  node.errorName = ctx:Surround('(', ')', function()
    return ctx:Try(ctx.Name)
  end)
  node.catch = ctx:Surround('{', '}', ctx.Block)

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function TryCatch.compile(ctx, node)
  local okName = ctx.newTmpName()
  local errorName = ctx.newTmpName()

  return table.concat({
    ('local %s, %s = pcall(function() %s end)'):format(
      okName,
      errorName,
      ctx:compile(node.try)
    ),
    'if ' .. okName .. ' == false then',
    not node.errorName and '' or ('local %s = %s'):format(
      ctx:compile(node.errorName),
      errorName
    ),
    ctx:compile(node.catch),
    'end',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return TryCatch
