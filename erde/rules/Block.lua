-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local Block = { ruleName = 'Block' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Block.parse(ctx, opts)
  ctx.blockDepth = ctx.blockDepth + 1
  opts = opts or {}

  local node = {
    blockDepth = ctx.blockDepth,

    -- Table for Continue nodes to register themselves.
    continueNodes = {},

    -- Table for Declaration and Function nodes to register `module` scope
    -- variables.
    moduleNames = {},
  }

  repeat
    -- Run this on ever iteration in case nested blocks change values
    if opts.isLoopBlock then
      ctx.loopBlock = node
    elseif opts.isFunctionBlock then
      -- Reset loopBlock for function blocks. Break / Continue cannot
      -- traverse these.
      ctx.loopBlock = nil
    elseif node.blockDepth == 1 then
      ctx.moduleBlock = node
    else
      ctx.moduleBlock = nil
    end

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

  if #node.moduleNames > 0 then
    for i, statement in ipairs(node) do
      if statement.ruleName == 'Return' then
        -- Block cannot use both `return` and `module`
        -- TODO: not good enough! What about conditional return?
        error()
      end
    end
  end

  ctx.blockDepth = ctx.blockDepth - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

local function compileBlockStatements(ctx, node)
  local compiledStatements = {}

  for _, statement in ipairs(node) do
    compiledStatements[#compiledStatements + 1] = ctx:compile(statement)
  end

  return table.concat(compiledStatements, '\n')
end

function Block.compile(ctx, node)
  if #node.continueNodes > 0 then
    local continueName = ctx:newTmpName()

    for i, continueNode in ipairs(node.continueNodes) do
      continueNode.continueName = continueName
    end

    return ([[
      local %s = false

      repeat
        %s
        %s = true
      until true

      if not %s then
        break
      end
    ]]):format(
      continueName,
      compileBlockStatements(ctx, node),
      continueName,
      continueName
    )
  elseif #node.moduleNames > 0 then
    local moduleTableElements = {}
    for i, moduleName in ipairs(node.moduleNames) do
      moduleTableElements[i] = moduleName .. '=' .. moduleName
    end

    return table.concat({
      compileBlockStatements(ctx, node),
      'return { ' .. table.concat(moduleTableElements, ',') .. ' }',
    }, '\n')
  else
    return compileBlockStatements(ctx, node)
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Block
