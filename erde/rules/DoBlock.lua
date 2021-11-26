-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

local DoBlock = { ruleName = 'DoBlock' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function DoBlock.parse(ctx)
  if not ctx:branchWord('do') then
    ctx:throwExpected('do')
  end

  local node = { body = ctx:Surround('{', '}', ctx.Block) }

  for _, statement in pairs(node.body) do
    -- TODO: not good enough! what about return in if block?
    if statement.ruleName == 'Return' then
      node.hasReturn = true
      break
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function DoBlock.compile(ctx, node)
  -- TODO: conditional
  return '(function()\n' .. ctx:compile(node.body) .. '\nend)()'
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return DoBlock
