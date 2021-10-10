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
  ['.|'] = { tag = 'TAG_BOR', prec = 1, assoc = LEFT_ASSOCIATIVE },
  ['+'] = { prec = 1, assoc = LEFT_ASSOCIATIVE },
  ['-'] = { prec = 1, assoc = LEFT_ASSOCIATIVE },
}

local OPERATOR_MAX_LEN = 1
for key, value in pairs(OPERATORS) do
  OPERATOR_MAX_LEN = math.max(OPERATOR_MAX_LEN, #key)
end

local OPTREE = {}

-- -----------------------------------------------------------------------------
-- Parse
--
-- Based on this amazing blog post:
-- https://eli.thegreenplace.net/2012/08/02/parsing-expressions-by-precedence-climbing
-- -----------------------------------------------------------------------------

function parser.expr(minPrec)
  minPrec = minPrec or 1
  local expr = {}

  if bufValue == '(' then
    parser.space()
    local lhs = parser.expr()
    lhs.parens = true
    expr[#expr + 1] = lhs

    parser.space()
    if bufValue ~= ')' then
      error('unbalanced parens')
    end
  elseif bufValue == EOF then
    error('unexpected EOF')
    -- TODO: parse unary op here
  else
    parser.space()
    expr[#expr + 1] = parser.number()
  end

  while true do
    parser.space()

    local op
    for i = OPERATOR_MAX_LEN, 1, -1 do
      local opToken = bufValue
      for j = 1, i - 1 do
        opToken = opToken .. buffer[bufIndex + j]
      end

      op = OPERATORS[opToken]
      if op then
        break
      end
    end

    if not op or op.prec < minPrec then
      break
    else
      expr[#expr + 1] = op
    end

    parser.space()
    expr[#expr + 1] = op.assoc == LEFT_ASSOCIATIVE
        and parser.expr(minPrec + 1)
      or parser.expr(minPrec)
  end

  return expr
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.expr(input)
  loadBuffer(input)
  return parser.expr()
end
