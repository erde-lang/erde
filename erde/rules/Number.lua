local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Number
-- -----------------------------------------------------------------------------

local Number = {}

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
      ctx:consume(1, capture)
      ctx:stream(constants.HEX, capture, true)
    end

    if ctx:branchChar('pP', true, capture) then
      ctx:branchChar('+-', true, capture)
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

    if #capture > 0 and ctx:branchChar('eE', true, capture) then
      ctx:branchChar('+-', true, capture)
      ctx:stream(constants.DIGIT, capture, true)
    end
  end

  if #capture == 0 then
    ctx:throwExpected('number', true)
  end

  return { rule = 'Number', value = table.concat(capture) }
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Number.compile(ctx, node)
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Number
