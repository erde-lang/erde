-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local Block = { ruleName = 'Block' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Block.parse(ctx)
  local node = {}

  repeat
    local statement = ctx:Switch({
      ctx.Assignment,
      ctx.Break,
      ctx.Comment,
      ctx.Continue,
      ctx.FunctionCall, -- must be before declaration!
      ctx.Declaration,
      ctx.DoBlock,
      ctx.ForLoop,
      ctx.IfElse,
      ctx.Function,
      ctx.RepeatUntil,
      ctx.Return,
      ctx.TryCatch,
      ctx.WhileLoop,
    })

    node[#node + 1] = statement
  until not statement

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Block.compile(ctx, node)
  local compileParts = {}

  for _, statement in ipairs(node) do
    compileParts[#compileParts + 1] = ctx:compile(statement)
  end

  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Block
