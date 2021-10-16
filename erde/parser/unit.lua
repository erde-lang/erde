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
-- DoBlock
-- -----------------------------------------------------------------------------

function unit.doBlock(input)
  loadBuffer(input)
  return parser.doBlock()
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
-- RepeatUntil
-- -----------------------------------------------------------------------------

function unit.repeatUntil(input)
  loadBuffer(input)
  return parser.repeatUntil()
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
-- WhileLoop
-- -----------------------------------------------------------------------------

function unit.whileLoop(input)
  loadBuffer(input)
  return parser.whileLoop()
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return unit
