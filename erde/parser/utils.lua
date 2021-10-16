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

function parser.pad(rule, ...)
  parser.space()
  local node = rule(...)
  parser.space()
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
-- Switch
-- -----------------------------------------------------------------------------

function parser.switch(rules)
  parser.space()

  for _, rule in pairs(rules) do
    local ok, node = pcall(rule)
    if ok then
      return node
    end
  end

  parser.space()
end

-- -----------------------------------------------------------------------------
-- Surround
-- -----------------------------------------------------------------------------

function parser.surround(openChar, closeChar, rule)
  parser.space()

  if not branchChar(openChar) then
    error('expected ' .. openChar)
  end

  local capture = parser.pad(rule)

  if not branchChar(closeChar) then
    error('expected ' .. closeChar)
  end

  parser.space()
  return capture
end
