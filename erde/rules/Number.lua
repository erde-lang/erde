local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Number
-- -----------------------------------------------------------------------------

local Number = { ruleName = 'Number' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Number.parse(ctx)
  local value = ''

  if ctx.token == '0' and ctx:peek(1):match('^[xX]$') then
    value = ctx:consume() .. ctx:consume()

    while ctx.token:match('^[a-fA-F0-9]+$') do
      value = value .. ctx:consume()
    end

    if ctx.token == '.' then
      value = value .. ctx:consume()
      while ctx.token:match('^[a-fA-F0-9]+$') do
        value = value .. ctx:consume()
      end
    end

    if ctx.token == 'p' or ctx.token == 'P' then
      value = value .. ctx:consume()

      if ctx.token:match('^[+-]$') then
        value = value .. ctx:consume()
      end

      if not ctx.token:match('^[0-9]+$') then
        error()
      end
    end
  else
    if ctx.token:match('^[0-9]+$') then
      value = ctx:consume()
    end

    if ctx.token == '.' then
      value = value .. ctx:consume()
      if ctx.token:match('^[0-9]+$') then
        value = ctx:consume()
      end
    end

    if #value == 0 then
      error()
    end

    if ctx.token == 'e' or ctx.token == 'E' then
      value = value .. ctx:consume()

      if ctx.token:match('^[+-]$') then
        value = value .. ctx:consume()
      end

      if not ctx.token:match('^[0-9]+$') then
        error()
      end
    end
  end

  return { value = value }
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Number.compile(ctx, node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Number
