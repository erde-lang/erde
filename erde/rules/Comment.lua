local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Comment
-- -----------------------------------------------------------------------------

local Comment = { ruleName = 'Comment' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Comment.parse(ctx)
  local node = { variant = 'short' }

  if not ctx:branchStr('--', true) then
    ctx:throwExpected('--')
  end

  local backup = ctx:backup()
  if ctx:branchChar('[', true) then
    local equals = {}
    ctx:stream({ ['='] = true }, equals)

    if ctx:branchChar('[', true) then
      node.variant = 'long'
      node.equals = table.concat(equals)
    else
      ctx:restore(backup)
    end
  end

  local capture = {}

  if node.variant == 'long' then
    while not ctx:branchStr(']' .. node.equals .. ']', true) do
      ctx:consume(1, capture)
    end
  elseif node.variant == 'short' then
    while ctx.bufValue ~= '\n' and ctx.bufValue ~= constants.EOF do
      ctx:consume(1, capture)
    end
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
