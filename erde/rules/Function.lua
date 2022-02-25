-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

local Function = { ruleName = 'Function' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Function.parse(ctx)
  local node = { isHoisted = false, isMethod = false }

  if ctx:branch('local') then
    node.variant = 'local'
  elseif ctx.token == 'module' or ctx.token == 'main' then
    if not ctx.moduleBlock then
      error(ctx.token .. ' declarations cannot be nested')
    end

    node.variant = ctx:consume()
  else
    ctx:branch('global')
    node.variant = 'global'
  end

  ctx:assert('function')
  node.names = { ctx:Name() }

  while true do
    if ctx:branch('.') then
      table.insert(node.names, ctx:Name())
    else
      if ctx:branch(':') then
        node.isMethod = true
        table.insert(node.names, ctx:Name())
      end

      break
    end
  end

  if node.variant == 'module' or node.variant == 'main' then
    if #node.names > 1 then
      error('Cannot declare nested field as ' .. node.variant)
    end

    if node.variant == 'main' then
      if ctx.moduleBlock.mainName ~= nil then
        error('Cannot have multiple main declarations')
      end

      ctx.moduleBlock.mainName = node.names[1]
    else
      table.insert(ctx.moduleBlock.moduleNames, node.names[1])
    end
  end

  if ctx.moduleBlock and node.variant ~= 'global' and #node.names == 1 then
    node.isHoisted = true
    table.insert(ctx.moduleBlock.hoistedNames, node.names[1])
  end

  node.params = ctx:Params()
  node.body = ctx:Surround('{', '}', function()
    return ctx:Block({ isFunctionBlock = true })
  end)

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Function.compile(ctx, node)
  local params = ctx:compile(node.params)

  local methodName
  if node.isMethod then
    methodName = table.remove(node.names)
  end

  return ('%s function %s%s(%s)\n%s\n%s\nend'):format(
    (node.variant ~= 'global' and not node.isHoisted) and 'local' or '',
    table.concat(node.names, '.'),
    methodName and ':' .. methodName or '',
    table.concat(params.names, ','),
    params.prebody,
    ctx:compile(node.body)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Function
