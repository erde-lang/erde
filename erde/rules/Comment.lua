local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Comment
-- -----------------------------------------------------------------------------

local Comment = { ruleName = 'Comment' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Comment.parse(ctx)
  local capture = {}
  local node = {}

  if ctx:branchStr('---', true) then
    node.variant = 'long'

    while ctx.bufValue ~= '-' or not ctx:branchStr('---', true) do
      ctx:consume(1, capture)
    end
  elseif ctx:branchStr('--', true) then
    node.variant = 'short'

    while ctx.bufValue ~= '\n' and ctx.bufValue ~= constants.EOF do
      ctx:consume(1, capture)
    end
  else
    ctx:throwExpected('comment', true)
  end

  node.value = table.concat(capture)

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Comment.compile(ctx, node)
  return nil
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Comment
