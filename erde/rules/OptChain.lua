local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

local OptChain = {}

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
    local backup = ctx:saveState()
    local chain = { optional = ctx:branchChar('?') }

    if ctx:branchChar('.') then
      local name = ctx:Try(ctx.Name)

      if name then
        chain.variant = 'dotIndex'
        chain.value = name.value
      else
        -- Do not throw error here, as '.' may be from an operator! Simply
        -- revert consumptions and break
        ctx:restoreState(backup)
        break
      end
    elseif bufValue == '[' then
      chain.variant = 'bracketIndex'
      chain.value = ctx:Surround('[', ']', ctx.Expr)
    elseif bufValue == '(' then
      chain.variant = 'params'
      chain.value = ctx:Surround('(', ')', function()
        local args = {}

        while bufValue ~= ')' do
          args[#args + 1] = ctx:Expr()
          if not ctx:branchChar(',') then
            break
          end
        end

        return args
      end)
    elseif ctx:branchChar(':') then
      chain.variant = 'method'
      chain.value = ctx:Name().value
      if bufValue ~= '(' then
        ctx:throwError('missing args after method call')
      end
    else
      -- revert consumption from ctx:branchChar('?')
      ctx:restoreState(backup)
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
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return OptChain
