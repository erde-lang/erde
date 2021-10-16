local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Space
-- -----------------------------------------------------------------------------

function parser.space()
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

  return table.concat(capture)
end

-- -----------------------------------------------------------------------------
-- Switch
-- -----------------------------------------------------------------------------

function parser.switch(rules)
  for _, rule in pairs(rules) do
    local ok, node = pcall(rule)
    if ok then
      return node
    end
  end
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
