local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Terminal
-- -----------------------------------------------------------------------------

local Terminal = { ruleName = 'Terminal' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Terminal.parse(ctx)
  for _, terminal in pairs(C.TERMINALS) do
    if ctx:branch(terminal) then
      return { value = terminal }
    end
  end

  local node
  if ctx.bufValue == '(' then
    node = ctx:Switch({
      ctx.ArrowFunction,
      ctx.OptChain,
      function()
        return ctx:Pipe({
          initValues = ctx:Surround('(', ')', function()
            return ctx:List({
              allowTrailingComma = true,
              rule = ctx.Expr,
            })
          end),
        })
      end,
      function()
        local node = ctx:Surround('(', ')', ctx.Expr)
        node.parens = true
        return node
      end,
    })
  else
    node = ctx:Switch({
      ctx.DoBlock,
      -- Check ArrowFunction again for implicit params! This must be checked
      -- before Table for implicit params + destructure
      ctx.ArrowFunction,
      ctx.Table,
      ctx.Number,
      ctx.String,
      ctx.OptChain,
    })
  end

  if not node then
    error()
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Terminal.compile(ctx, node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Terminal
