-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

local ArrowFunction = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function ArrowFunction.parse(ctx)
  local node = {
    rule = 'ArrowFunction',
    hasImplicitParams = false,
    hasImplicitReturns = false,
  }

  local params = ctx:Switch({
    ctx.Name,
    ctx.Params,
  })

  if params.rule == 'Name' then
    node.paramName = params.value
    node.hasImplicitParams = true
  else
    node.params = params
  end

  if ctx:branchStr('->') then
    node.variant = 'skinny'
  elseif ctx:branchStr('=>') then
    node.variant = 'fat'
  else
    ctx:throwUnexpected()
  end

  if ctx.bufValue == '{' then
    node.body = ctx:Surround('{', '}', ctx.Block)
  else
    node.hasImplicitReturns = true
    node.returns = {}

    repeat
      local expr = ctx:Try(ctx.Expr)

      if not expr then
        break
      end

      node.returns[#node.returns + 1] = expr
    until not ctx:branchChar(',')

    if #node.returns == 0 then
      ctx:throwExpected('expression', true)
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function ArrowFunction.compile(ctx, node)
  local params, paramNames
  if node.hasImplicitParams then
    paramNames = { node.paramName }
  else
    params = ctx:compile(node.params)
    paramNames = params.names
  end

  if node.variant == 'fat' then
    table.insert(paramNames, 1, 'self')
  end

  local body
  if not node.hasImplicitReturns then
    body = ctx:compile(node.body)
  else
    local returns = {}

    for i, value in ipairs(node.returns) do
      returns[i] = ctx:compile(value)
    end

    body = 'return ' .. table.concat(returns, ',')
  end

  return ('function(%s)\n%s\n%s\nend'):format(
    table.concat(paramNames, ','),
    params and params.prebody or '',
    body
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return ArrowFunction
