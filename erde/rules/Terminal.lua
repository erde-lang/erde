local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Terminal
-- -----------------------------------------------------------------------------

local Terminal = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Terminal.parse(ctx)
  if bufValue == '(' then
    local node = ctx:Switch({
      ctx.ArrowFunction,
      ctx.OptChain,
      function()
        local node = ctx:Surround('(', ')', ctx.Expr)
        node.parens = true
        return node
      end,
    })

    if node == nil then
      ctx:throwUnexpected()
    end

    return node
  end

  for _, terminal in pairs(constants.TERMINALS) do
    if ctx:branchWord(terminal) then
      return { value = terminal }
    end
  end

  local node = ctx:Switch({
    ctx.Table,
    ctx.Number,
    ctx.String,
    ctx.ArrowFunction, -- Check again for hasImplicitParams!
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
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Terminal
