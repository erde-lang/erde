local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Number
-- -----------------------------------------------------------------------------

local Number = { ruleName = 'Number' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Number.parse(ctx)
  local capture = {}

  if
    ctx:branchStr('0x', true, capture) or ctx:branchStr('0X', true, capture)
  then
    ctx:stream(constants.HEX, capture, true)

    if ctx.bufValue == '.' and not ctx:Binop() then
      if _VERSION:find('5%.1') then
        -- Decimal hex values only supported in Lua 5.2+
        error()
      end

      ctx:consume(1, capture)
      ctx:stream(constants.HEX, capture, true)
    end

    if
      ctx:branchChar('p', true, capture) or ctx:branchChar('P', true, capture)
    then
      if _VERSION:find('5%.1') then
        -- Hex exponents only supported in Lua 5.2+
        error()
      end

      ctx:branchChar('+', true, capture)
      ctx:branchChar('-', true, capture)
      ctx:stream(constants.DIGIT, capture, true)
    end
  else
    while constants.DIGIT[ctx.bufValue] do
      ctx:consume(1, capture)
    end

    if ctx.bufValue == '.' and not ctx:Binop() then
      ctx:consume(1, capture)
      ctx:stream(constants.DIGIT, capture, true)
    end

    if
      #capture > 0 and ctx:branchChar('e', true, capture)
      or ctx:branchChar('E', true, capture)
    then
      ctx:branchChar('+', true, capture)
      ctx:branchChar('-', true, capture)
      ctx:stream(constants.DIGIT, capture, true)
    end
  end

  if #capture == 0 then
    error()
  end

  return { value = table.concat(capture) }
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
