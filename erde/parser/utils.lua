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

  local node = { tag = TAG_NAME, value = table.concat(capture) }
end
