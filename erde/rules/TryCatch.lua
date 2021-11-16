-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

local TryCatch = { ruleName = 'TryCatch' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function TryCatch.parse(ctx)
  local node = {}

  if not ctx:branchWord('try') then
    ctx:throwExpected('try')
  end

  node.try = ctx:Surround('{', '}', ctx.Block)

  if not ctx:branchWord('catch') then
    ctx:throwExpected('catch')
  end

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
    ctx.format('local %1,%2 = pcall(function()', okName, errorName),
    ctx:compile(node.try),
    'end)',
    ctx.format('if %1 == false then', okName),
    node.errorName and ctx.format(
      'local %1 = %2',
      ctx:compile(node.errorName),
      errorName
    ) or '',
    ctx:compile(node.catch),
    'end',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return TryCatch
