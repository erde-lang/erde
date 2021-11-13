local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Terminal
-- -----------------------------------------------------------------------------

local Terminal = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Terminal.parse(ctx)
  for _, terminal in pairs(constants.TERMINALS) do
    if ctx:branchWord(terminal) then
      return { rule = 'Terminal', value = terminal }
    end
  end

  local node = ctx.bufValue == '('
      and ctx:Switch({
        ctx.ArrowFunction,
        ctx.OptChain,
        function()
          local node = ctx:Surround('(', ')', ctx.Expr)
          node.parens = true
          return node
        end,
      })
    or ctx:Switch({
      ctx.DoBlock,
      ctx.Table,
      ctx.Number,
      ctx.String,
      ctx.ArrowFunction, -- Check again for hasImplicitParams!
      ctx.Pipe,
      ctx.OptChain,
    })

  if not node then
    ctx:throwExpected('terminal', true)
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
