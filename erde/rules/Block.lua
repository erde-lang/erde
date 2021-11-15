local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local Block = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Block.parse(ctx)
  local node = { rule = 'Block' }

  while true do
    local statement = ctx:Switch({
      ctx.Assignment,
      ctx.Comment,
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

    if not statement then
      break
    end

    node[#node + 1] = statement
  end

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
