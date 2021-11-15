-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

local OptChain = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function OptChain.parse(ctx)
  local node = {
    rule = 'OptChain',
    base = ctx:Switch({
      ctx.Name,
      function()
        local base = ctx:Surround('(', ')', ctx.Expr)
        base.parens = true
        return base
      end,
    }),
  }

  if not node.base then
    ctx:throwExpected('name or (parens expression)', true)
  end

  while true do
    local backup = ctx:backup()
    local chain = { optional = ctx:branchChar('?') }

    if ctx:branchChar('.') then
      local name = ctx:Try(ctx.Name)

      if name then
        chain.variant = 'dotIndex'
        chain.value = name.value
      else
        -- Do not throw error here, as '.' may be from an operator! Simply
        -- revert consumptions and break
        ctx:restore(backup)
        break
      end
    elseif ctx.bufValue == '[' then
      chain.variant = 'bracketIndex'
      chain.value = ctx:Surround('[', ']', ctx.Expr)
    elseif ctx.bufValue == '(' then
      chain.variant = 'params'
      chain.value = ctx:Parens({
        demand = true,
        rule = function()
          return ctx:List({
            allowEmpty = true,
            allowTrailingComma = true,
            rule = ctx.Expr,
          })
        end,
      })
    elseif ctx:branchChar(':') then
      chain.variant = 'method'
      chain.value = ctx:Name().value
      if ctx.bufValue ~= '(' then
        ctx:throwError('missing args after method call')
      end
    else
      ctx:restore(backup) -- revert consumption from ctx:branchChar('?')
      break
    end

    node[#node + 1] = chain
  end

  -- unpack trivial OptChain
  return #node == 0 and node.base or node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function OptChain.compile(ctx, node)
  local optChecks = {}
  local subChain = ctx:compile(node.base)

  for i, chainNode in ipairs(node) do
    if chainNode.optional then
      optChecks[#optChecks + 1] = ctx.format(
        'if %1 == nil then return end',
        subChain
      )
    end

    local newSubChainFormat
    if chainNode.variant == 'dotIndex' then
      subChain = ctx.format('%1.%2', subChain, chainNode.value)
    elseif chainNode.variant == 'bracketIndex' then
      -- Space around brackets to avoid long string expressions
      -- [ [=[some string]=] ]
      subChain = ctx.format('%1[ %2 ]', subChain, ctx:compile(chainNode.value))
    elseif chainNode.variant == 'params' then
      local params = {}

      for _, expr in ipairs(chainNode.value) do
        params[#params + 1] = ctx:compile(expr)
      end

      subChain = ctx.format('%1(%2)', subChain, table.concat(params, ','))
    elseif chainNode.variant == 'method' then
      subChain = ctx.format('%1:%2', subChain, chainNode.value)
    end
  end

  return #optChecks == 0 and subChain
    or ctx.format(
      '(function() %1 return %2 end)()',
      table.concat(optChecks, ' '),
      subChain
    )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return OptChain
