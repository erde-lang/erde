-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

local Goto = { ruleName = 'Goto' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Goto.parse(ctx)
  local node = {}

  if ctx:branch('goto') then
    node.variant = 'jump'
    node.name = ctx:Name()
  else
    node.variant = 'definition'
    ctx:assert(':')
    ctx:assert(':')
    node.name = ctx:Name()
    ctx:assert(':')
    ctx:assert(':')
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

function Goto.compile(ctx, node)
  if node.variant == 'jump' then
    return 'goto ' .. ctx:compile(node.name)
  elseif node.variant == 'definition' then
    return '::' .. ctx:compile(node.name) .. '::'
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Goto
