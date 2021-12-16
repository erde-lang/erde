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
    error()
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
        -- missing args after method call
        error()
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
  local optChain = ctx:compileOptChain(node)

  if #optChain.optSubChains == 0 then
    return optChain.chain
  end

  local optChecks = {}
  for i, optSubChain in ipairs(optChain.optSubChains) do
    optChecks[#optChecks + 1] = 'if '
      .. optSubChain
      .. ' == nil then return end'
  end

  return table.concat({
    '(function()',
    table.concat(optChecks, '\n'),
    'return ' .. optChain.chain,
    'end)()',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return OptChain
