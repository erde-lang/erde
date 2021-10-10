local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Constants
-- -----------------------------------------------------------------------------

local LEFT_ASSOCIATIVE = -1
local RIGHT_ASSOCIATIVE = 1

local PRECEDENCE_LEVELS = {
  -- Pipe
  -- Ternary
  { '??' },
  { '|' },
  { '&' },
  { '==', '~=', '<=', '>=', '<', '>' },
  { '.|' },
  { '.~' },
  { '.&' },
  { '.<<', '.>>' },
  { '..' },
  { '+', '-' },
  { '*', '//', '/', '%' },
  { '-' }, -- unary
  { '^' },
}

local OPERATORS = {
  ['+'] = { precedence = 1, associativity = LEFT_ASSOCIATIVE },
  ['-'] = { precedence = 1, associativity = LEFT_ASSOCIATIVE },
}

local OPTREE = {}

-- -----------------------------------------------------------------------------
-- Parse
--
-- Based on this amazing blog post:
-- https://eli.thegreenplace.net/2012/08/02/parsing-expressions-by-precedence-climbing
-- -----------------------------------------------------------------------------

function parser.expr(minPrecedence)
  local minPrecedence = minPrecedence or 1

  local lhs
  if bufValue == '(' then
    parser.space()
    lhs = parser.expr()
    lhs.parens = true

    parser.space()
    if bufValue ~= ')' then
      error('unbalanced parens')
    end
  elseif bufValue == EOF then
    error('unexpected EOF')
  else
    parser.space()
    lhs = parser.number()
  end

  while true do
    parser.space()
    local op = OPERATORS[bufValue]
    if not op or op.precedence < minPrecedence then
      break
    end

    parser.space()
    local rhs = op.associativity == LEFT_ASSOCIATIVE
        and parser.expr(minPrecedence + 1)
      or parser.expr(minPrecedence)
  end

  return lhs
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.expr(input)
  loadBuffer(input)
  return parser.expr()
end
