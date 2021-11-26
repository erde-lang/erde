-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

local OptChain = { ruleName = 'OptChain' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function OptChain.parse(ctx)
  local node = {
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
      chain.variant = 'functionCall'
      chain.value = ctx:Parens({
        demand = true,
        rule = function()
          return ctx:List({
            allowEmpty = true,
            allowTrailingComma = true,
            rule = function()
              return ctx:Switch({
                ctx.Expr,
                ctx.Spread,
              })
            end,
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
      optChecks[#optChecks + 1] = 'if ' .. subChain .. ' == nil then return end'
    end

    local newSubChainFormat
    if chainNode.variant == 'dotIndex' then
      subChain = ('%s.%s'):format(subChain, chainNode.value)
    elseif chainNode.variant == 'bracketIndex' then
      -- Space around brackets to avoid long string expressions
      -- [ [=[some string]=] ]
      subChain = ('%s[ %s ]'):format(subChain, ctx:compile(chainNode.value))
    elseif chainNode.variant == 'functionCall' then
      local hasSpread = false
      for i, arg in ipairs(chainNode.value) do
        if arg.ruleName == 'Spread' then
          hasSpread = true
          break
        end
      end

      if hasSpread then
        local spreadFields = {}

        for i, arg in ipairs(chainNode.value) do
          spreadFields[i] = arg.ruleName == 'Spread' and arg
            or { value = ctx:compile(expr) }
        end

        subChain = ('%s(%s(%s))'):format(
          subChain,
          _VERSION:find('5.1') and 'unpack' or 'table.unpack',
          ctx:Spread(spreadFields)
        )
      else
        local args = {}

        for i, arg in ipairs(chainNode.value) do
          args[#args + 1] = ctx:compile(arg)
        end

        subChain = subChain .. '(' .. table.concat(args, ',') .. ')'
      end
    elseif chainNode.variant == 'method' then
      subChain = subChain .. ':' .. chainNode.value
    end
  end

  if #optChecks == 0 then
    return subChain
  end

  return ('(function() %s return %s end)()'):format(
    table.concat(optChecks, ' '),
    subChain
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return OptChain
