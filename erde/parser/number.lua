local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function parser.number()
  local capture = {}

  if branchWord('0x', capture) or branchWord('0X', capture) then
    stream(Hex, capture, true)

    if branchChar('.', capture) then
      stream(Hex, capture, true)
    end

    if branchChar('pP', capture) then
      branchChar('+-', capture)
      stream(Digit, capture, true)
    end
  else
    while Digit[bufValue] do
      consume(1, capture, true)
    end

    if branchChar('.', capture) then
      stream(Digit, capture, true)
    end

    if #capture > 0 and branchChar('eE', capture) then
      branchChar('+-', capture)
      stream(Digit, capture, true)
    end
  end

  if #capture == 0 then
    error('expected number')
  end

  return { tag = TAG_NUMBER, value = table.concat(capture) }
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.number(input)
  loadBuffer(input)
  return parser.number().value
end
