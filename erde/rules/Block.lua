-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local Block = { ruleName = 'Block' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Block.parse(ctx, opts)
  local node = {}

  if opts then
    if opts.isLoopBlock then
      node.continueNodes = {}
      ctx.parentLoopBlock = node
    elseif opts.isFunctionBlock then
      -- Reset parentLoopBlock for function blocks. Break / Continue cannot
      -- traverse these.
      ctx.parentLoopBlock = nil
    end
  end

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

  if not node.continueNodes or #node.continueNodes == 0 then
    for _, statement in ipairs(node) do
      compileParts[#compileParts + 1] = ctx:compile(statement)
    end

    return table.concat(compileParts, '\n')
  else
    local continueName = ctx.newTmpName()

    for i, continueNode in ipairs(node.continueNodes) do
      continueNode.continueName = continueName
    end

    for _, statement in ipairs(node) do
      compileParts[#compileParts + 1] = ctx:compile(statement)
    end

    return ctx.format(
      [[
        local %1 = false

        repeat
          %2
          %1 = true
        until true

        if not %1 then
          break
        end
      ]],
      continueName,
      table.concat(compileParts, '\n')
    )
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Block
