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

local CONTINUE_TEMPLATE = [[
  local %1 = false

  repeat
    %2
    %1 = true
  until true

  if not %1 then
    break
  end
]]

function Block.compile(ctx, node)
  local compileParts = {}

  for _, statement in ipairs(node) do
    compileParts[#compileParts + 1] = ctx:compile(statement)
  end

  local compiled = table.concat(compileParts, '\n')

  return node.continueName
      and ctx.format(CONTINUE_TEMPLATE, node.continueName, compiled)
    or compiled
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Block
