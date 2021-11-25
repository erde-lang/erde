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

  return { body = ctx:Surround('{', '}', ctx.Block) }
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function DoBlock.compile(ctx, node)
  -- TODO: Better compilation based on usage (statement vs expr)
  -- moonscript does a very good job at this.
  return '(function()\n' .. ctx:compile(node.body) .. '\nend)()'
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return DoBlock
