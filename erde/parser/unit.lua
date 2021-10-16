local _ENV = require('erde.parser.env').load()
require('erde.parser.rules')
local unit = {}

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

function unit.assignment(input)
  loadBuffer(input)
  local node = parser.assignment()
  return node
end

-- -----------------------------------------------------------------------------
-- Comment
-- -----------------------------------------------------------------------------

function unit.comment(input)
  loadBuffer(input)
  local node = parser.comment()
  return node.value
end

-- -----------------------------------------------------------------------------
-- Expr
-- -----------------------------------------------------------------------------

function unit.expr(input)
  loadBuffer(input)
  return parser.expr()
end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

function unit.forLoop(input)
  loadBuffer(input)
  return parser.forLoop()
end

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

function unit.ifElse(input)
  loadBuffer(input)
  return parser.ifElse()
end

-- -----------------------------------------------------------------------------
-- Number
-- -----------------------------------------------------------------------------

function unit.number(input)
  loadBuffer(input)
  return parser.number().value
end

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

function unit.string(input)
  loadBuffer(input)
  local node = parser.string()
  return node.tag == TAG_SHORT_STRING and node.value or node
end

-- -----------------------------------------------------------------------------
-- Var
-- -----------------------------------------------------------------------------

function unit.var(input)
  loadBuffer(input)
  return parser.var()
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return unit
