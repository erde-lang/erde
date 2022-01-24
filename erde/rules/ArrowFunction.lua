-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

local ArrowFunction = { ruleName = 'ArrowFunction' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function ArrowFunction.parse(ctx)
  local node = {
    hasImplicitReturns = true,
  }

  if ctx.token == '(' then
    node.params = ctx:Params()
  elseif ctx.token == '{' or ctx.token == '[' then
    node.params = { ruleName = 'Params', ctx:Destructure() }
  else
    node.params = { ruleName = 'Params', ctx:Name() }
  end

  if ctx:branch('->') then
    node.variant = 'skinny'
  elseif ctx:branch('=>') then
    node.variant = 'fat'
  else
    error('Unexpected token ' .. ctx.token)
  end

  if ctx.token == '{' then
    node.hasImplicitReturns = false
    node.body = ctx:Surround('{', '}', function()
      return ctx:Block({ isFunctionBlock = true })
    end)
  elseif ctx.token == '(' then
    -- Only allow multiple implicit returns w/ parentheses
    node.returns = ctx:Parens({
      allowRecursion = true,
      rule = function()
        return ctx:List({
          allowTrailingComma = true,
          rule = ctx.Expr,
        })
      end,
    })
  else
    node.returns = { ctx:Expr() }
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function ArrowFunction.compile(ctx, node)
  local params = ctx:compile(node.params)
  local paramNames = params.names

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

  return table.concat({
    'function(' .. table.concat(paramNames, ',') .. ')',
    params and params.prebody or '',
    body,
    'end',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return ArrowFunction
