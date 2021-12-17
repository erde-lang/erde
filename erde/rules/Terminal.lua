local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Terminal
-- -----------------------------------------------------------------------------

local Terminal = { ruleName = 'Terminal' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Terminal.parse(ctx)
  for _, terminal in pairs(constants.TERMINALS) do
    if ctx:branchWord(terminal) then
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
      ctx.Table,
      ctx.Number,
      ctx.String,
      ctx.ArrowFunction, -- Check again for hasImplicitParams!
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
