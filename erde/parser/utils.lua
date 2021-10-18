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
  backupBufIndex = bufIndex
  backupBufValue = bufValue
  backupLine = line
  backupColumn = column

  local ok, node = pcall(rule)

  if ok then
    return node
  else
    bufIndex = backupBufIndex
    bufValue = backupBufValue
    line = backupLine
    column = backupColumn
  end
end
