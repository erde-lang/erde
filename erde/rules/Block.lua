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
      -- unset? revert nested loop blocks?
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

    local statement
    if ctx.token == 'break' then
      statement = ctx:Break() -- TODO: inline?
    elseif ctx.token == 'continue' then
      statement = ctx:Continue() -- TODO: inline?
    elseif ctx.token == 'goto' or ctx.token == ':' then
      statement = ctx:Goto()
    elseif ctx.token == 'do' then
      statement = ctx:DoBlock()
    elseif ctx.token == 'if' then
      statement = ctx:IfElse()
    elseif ctx.token == 'for' then
      statement = ctx:ForLoop()
    elseif ctx.token == 'repeat' then
      statement = ctx:RepeatUntil()
    elseif ctx.token == 'return' then
      statement = ctx:Return()
    elseif ctx.token == 'try' then
      statement = ctx:TryCatch()
    elseif ctx.token == 'while' then
      statement = ctx:WhileLoop()
    elseif ctx.token == 'function' then
      statement = ctx:Function()
    elseif
      ctx.token == 'local'
      or ctx.token == 'module'
      or ctx.token == 'global'
    then
      if ctx:peek(1) == 'function' then
        statement = ctx:Function()
      else
        statement = ctx:Declaration()
      end
    else
      statement = ctx:Switch({
        ctx.FunctionCall,
        ctx.Assignment,
      })
    end

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
    local compiledStatement = ctx:compile(statement)

    if
      statement.ruleName == 'OptChain'
      and statement[#statement].variant == 'functionCall'
    then
      -- As of January 5, 2022, we use a lot of iife statements in compiled code.
      -- This semicolon removes Lua's ambiguous syntax error when using iife by
      -- funtion calls.
      --
      -- http://lua-users.org/lists/lua-l/2009-08/msg00543.html
      compiledStatement = compiledStatement .. ';'
    end

    compiledStatements[#compiledStatements + 1] = compiledStatement
  end

  return table.concat(compiledStatements, '\n')
end

function Block.compile(ctx, node)
  if #node.continueNodes > 0 then
    local continueGotoLabel = ctx:newTmpName()

    for i, continueNode in ipairs(node.continueNodes) do
      continueNode.gotoLabel = continueGotoLabel
    end

    return ('%s\n::%s::'):format(
      compileBlockStatements(ctx, node),
      continueGotoLabel
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
