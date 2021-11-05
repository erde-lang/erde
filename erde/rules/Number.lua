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
    stream(constants.HEX, capture, true)

    if bufValue == '.' and not ctx:Binop() then
      ctx:consume(1, capture)
      stream(constants.HEX, capture, true)
    end

    if ctx:branchChar('pP', true, capture) then
      ctx:branchChar('+-', true, capture)
      stream(constants.DIGIT, capture, true)
    end
  else
    while constants.DIGIT[bufValue] do
      ctx:consume(1, capture)
    end

    if bufValue == '.' and not ctx:Binop() then
      ctx:consume(1, capture)
      stream(constants.DIGIT, capture, true)
    end

    if #capture > 0 and ctx:branchChar('eE', true, capture) then
      ctx:branchChar('+-', true, capture)
      stream(constants.DIGIT, capture, true)
    end
  end

  if #capture == 0 then
    ctx:throwExpected('number', true)
  end

  return { value = table.concat(capture) }
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
