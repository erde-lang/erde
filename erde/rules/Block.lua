-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local Block = { ruleName = 'Block' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Block.parse(ctx, opts)
  opts = opts or {}
  local node = {}

  if opts.isLoopBlock then
    node.isLoopBlock = true
    node.continueNodes = {}
    ctx.loopBlock = node
  elseif opts.isFunctionBlock then
    -- Reset loopBlock for function blocks. Break / Continue cannot
    -- traverse these.
    ctx.loopBlock = nil
  elseif opts.isModuleBlock then
    node.isModuleBlock = true
    node.moduleNodes = {}
    ctx.moduleBlock = node
  else
    ctx.moduleBlock = nil
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

  if opts.isModuleBlock and #node.moduleNodes > 0 then
    for i, statement in ipairs(node) do
      if statement.ruleName == 'Return' then
        ctx:throwError('Block cannot use both `return` and `module`')
      end
    end
  end

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
  if node.isLoopBlock then
    local continueName = ctx.newTmpName()

    for i, continueNode in ipairs(node.continueNodes) do
      continueNode.continueName = continueName
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
      compileBlockStatements(ctx, node)
    )
  elseif node.isModuleBlock and #node.moduleNodes > 0 then
    local moduleName = ctx.newTmpName()

    for i, moduleNode in ipairs(node.moduleNodes) do
      moduleNode.moduleName = moduleName
    end

    return ctx.format(
      [[
        local %1 = {}
        %2
        return %1
      ]],
      moduleName,
      compileBlockStatements(ctx, node)
    )
  else
    return compileBlockStatements(ctx, node)
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Block
