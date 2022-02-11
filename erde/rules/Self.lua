-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

local Self = { ruleName = 'Self' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Self.parse(ctx)
  local node = {}
  ctx:assert('$')

  if not ctx.token then
    return { variant = 'self' }
  elseif ctx.token:match('^[_a-zA-Z][_a-zA-Z0-9]*$') then
    return { variant = 'dotIndex', value = ctx:consume() }
  elseif ctx.token:match('^[0-9]+$') then
    return { variant = 'numberIndex', value = ctx:consume() }
  else
    return { variant = 'self' }
  end
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Self.compile(ctx, node)
  if node.variant == 'dotIndex' then
    return 'self.' .. node.value
  elseif node.variant == 'numberIndex' then
    return 'self[' .. node.value .. ']'
  else
    return 'self'
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Self
