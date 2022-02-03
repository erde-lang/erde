-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

local Function = { ruleName = 'Function' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Function.parse(ctx)
  local node = { isMethod = false }

  if ctx:branch('local') then
    node.variant = 'local'
  elseif ctx:branch('module') then
    if not ctx.moduleBlock then
      error('`module` declarations cannot be nested')
    end

    node.variant = 'module'
  else
    ctx:branch('global')
    node.variant = 'global'
  end

  assert(ctx:consume() == 'function')
  node.names = { ctx:Name().value }

  while true do
    if ctx:branch('.') then
      node.names[#node.names + 1] = ctx:Name().value
    else
      if ctx:branch(':') then
        node.isMethod = true
        node.names[#node.names + 1] = ctx:Name().value
      end

      break
    end
  end

  if node.variant == 'module' then
    if #node.names > 1 then
      error('Cannot declare nested field as `module`')
    end

    table.insert(ctx.moduleBlock.moduleNames, node.names[1])
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
    (node.variant == 'local' or node.variant == 'module') and 'local' or '',
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
