local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Space
-- -----------------------------------------------------------------------------

function parser.space(demand)
  if demand and not Whitespace[bufValue] then
    error('missing whitespace')
  end

  while Whitespace[bufValue] do
    consume()
  end
end

-- -----------------------------------------------------------------------------
-- Pad
-- -----------------------------------------------------------------------------

function parser.pad(rule, lhs, rhs)
  if lhs or lhs == nil then
    parser.space()
  end

  local node = rule()

  if rhs or rhs == nil then
    parser.space()
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Name
-- -----------------------------------------------------------------------------

function parser.name()
  if not Alpha[bufValue] then
    error('name must start with alpha')
  end

  local capture = {}
  consume(1, capture)

  while Alpha[bufValue] or Digit[bufValue] do
    consume(1, capture)
  end

  return table.concat(capture)
end

-- -----------------------------------------------------------------------------
-- Surround
-- -----------------------------------------------------------------------------

function parser.surround(openChar, closeChar, rule)
  if not branchChar(openChar) then
    error('expected ' .. openChar)
  end

  local capture = rule()

  if not branchChar(closeChar) then
    error('expected ' .. closeChar)
  end

  return capture
end
