local _ENV = require('erde.parser.env').load()
require('erde.parser.rules')
local unit = {}

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
