-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

local ArrowFunction = { ruleName = 'ArrowFunction' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function ArrowFunction.parse(ctx)
  local node = {
    hasFatArrow = false,
    hasImplicitReturns = false,
    params = ctx.token == '(' and ctx:Params() or {
      ruleName = 'Params',
      ctx:Var(),
    },
  }

  if ctx:branch('=>') then
    node.hasFatArrow = true
  elseif not ctx:branch('->') then
    error('Expected arrow (->, =>), got ' .. ctx.token)
  end

  if ctx.token == '{' then
    node.body = ctx:Surround('{', '}', function()
      return ctx:Block({ isFunctionBlock = true })
    end)
  elseif ctx.token == '(' then
    node.hasImplicitReturns = true
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
    node.hasImplicitReturns = true
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

  if node.hasFatArrow then
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
-- Format
-- -----------------------------------------------------------------------------

function ArrowFunction.format(ctx, node)
  return ('(%s) %s {\n%s\n}'):format(
    ctx:format(node.params),
    node.hasFatArrow and '=>' or '->',
    ctx:format(node.body)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return ArrowFunction
