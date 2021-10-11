local _ENV = require('erde.parser.env').load()

-- TODO: unary ops, ternary

-- -----------------------------------------------------------------------------
-- Constants
-- -----------------------------------------------------------------------------

local LEFT_ASSOCIATIVE = -1
local RIGHT_ASSOCIATIVE = 1

local OPERATORS = {
  ['??'] = { tag = TAG_NC, prec = 1, assoc = LEFT_ASSOCIATIVE },
  ['|'] = { tag = TAG_OR, prec = 2, assoc = LEFT_ASSOCIATIVE },
  ['&'] = { tag = TAG_AND, prec = 3, assoc = LEFT_ASSOCIATIVE },
  ['=='] = { tag = TAG_EQ, prec = 4, assoc = LEFT_ASSOCIATIVE },
  ['~='] = { tag = TAG_NEQ, prec = 4, assoc = LEFT_ASSOCIATIVE },
  ['<='] = { tag = TAG_LTE, prec = 4, assoc = LEFT_ASSOCIATIVE },
  ['>='] = { tag = TAG_GTE, prec = 4, assoc = LEFT_ASSOCIATIVE },
  ['<'] = { tag = TAG_LT, prec = 4, assoc = LEFT_ASSOCIATIVE },
  ['>'] = { tag = TAG_GT, prec = 4, assoc = LEFT_ASSOCIATIVE },
  ['.|'] = { tag = TAG_BOR, prec = 5, assoc = LEFT_ASSOCIATIVE },
  ['.~'] = { tag = TAG_BNOT, prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['.&'] = { tag = TAG_BAND, prec = 7, assoc = LEFT_ASSOCIATIVE },
  ['.<<'] = { tag = TAG_LSHIFT, prec = 8, assoc = LEFT_ASSOCIATIVE },
  ['.>>'] = { tag = TAG_RSHIFT, prec = 8, assoc = LEFT_ASSOCIATIVE },
  ['..'] = { tag = TAG_CONCAT, prec = 9, assoc = LEFT_ASSOCIATIVE },
  ['+'] = { tag = TAG_ADD, prec = 10, assoc = LEFT_ASSOCIATIVE },
  ['-'] = { tag = TAG_SUB, prec = 10, assoc = LEFT_ASSOCIATIVE },
  ['*'] = { tag = TAG_MULT, prec = 11, assoc = LEFT_ASSOCIATIVE },
  ['/'] = { tag = TAG_DIV, prec = 11, assoc = LEFT_ASSOCIATIVE },
  ['//'] = { tag = TAG_INTDIV, prec = 11, assoc = LEFT_ASSOCIATIVE },
  ['%'] = { tag = TAG_MOD, prec = 11, assoc = LEFT_ASSOCIATIVE },
  ['^'] = { tag = TAG_EXP, prec = 12, assoc = RIGHT_ASSOCIATIVE },
}

local OPERATOR_MAX_LEN = 1
for key, value in pairs(OPERATORS) do
  OPERATOR_MAX_LEN = math.max(OPERATOR_MAX_LEN, #key)
end

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
      if buffer[bufIndex + i - 1] then
        local opToken = bufValue
        for j = 1, i - 1 do
          if buffer[bufIndex + j] then
            opToken = opToken .. buffer[bufIndex + j]
          end
        end

        op = OPERATORS[opToken]
        if op then
          consume(i)
          break
        end
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
