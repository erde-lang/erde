local _ENV = require('erde.parser.env'):load()

-- -----------------------------------------------------------------------------
-- Save / Restore
-- -----------------------------------------------------------------------------

function parser.saveState()
  return {
    bufIndex = bufIndex,
    bufValue = bufValue,
    line = line,
    column = column,
  }
end

function parser.restoreState(backup)
  bufIndex = backup.bufIndex
  bufValue = backup.bufValue
  line = backup.line
  column = backup.column
end

-- -----------------------------------------------------------------------------
-- Space
-- -----------------------------------------------------------------------------

function parser.space()
  while Whitespace[bufValue] do
    consume()
  end
end

-- -----------------------------------------------------------------------------
-- Switch
-- -----------------------------------------------------------------------------

function parser.switch(rules)
  for _, rule in pairs(rules) do
    local node = parser.try(rule)
    if node then
      return node
    end
  end
end

-- -----------------------------------------------------------------------------
-- Surround
-- -----------------------------------------------------------------------------

function parser.surround(openChar, closeChar, rule)
  if not branchChar(openChar) then
    throw.expected(openChar)
  end

  local capture = rule()

  if not branchChar(closeChar) then
    throw.expected(closeChar)
  end

  return capture
end

-- -----------------------------------------------------------------------------
-- Try
-- -----------------------------------------------------------------------------

function parser.try(rule)
  local backup = parser.saveState()
  local ok, node = pcall(rule)

  if ok then
    return node
  else
    parser.restoreState(backup)
  end
end
