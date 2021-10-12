local _ENV = require('erde.parser.env').load()

-- TODO: unary ops, ternary

-- -----------------------------------------------------------------------------
-- Constants
-- -----------------------------------------------------------------------------

local LEFT_ASSOCIATIVE = -1
local RIGHT_ASSOCIATIVE = 1

local UNOPS = {
  ['-'] = { tag = TAG_NEG, prec = 1 },
  ['#'] = { tag = TAG_LEN, prec = 2 },
  ['~'] = { tag = TAG_NOT, prec = 2 },
  ['.~'] = { tag = TAG_BNOT, prec = 2 },
}

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
  ['.~'] = { tag = TAG_BXOR, prec = 6, assoc = LEFT_ASSOCIATIVE },
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

function parser.operand()
  local operand
  if bufValue == '(' then
    consume()

    parser.space()
    operand = parser.expr()
    operand.parens = true

    parser.space()
    if bufValue ~= ')' then
      error('unbalanced parens')
    end
  elseif bufValue == EOF then
    error('unexpected EOF')
  else
    -- TODO: more terminals
    operand = parser.number()
  end
  return operand
end

function parser.unop(minPrec)
  local unop = { nil, parser.operand() }

  return unop
end

function parser.binop(minPrec)
  local binop = { nil, parser.operand(), nil }

  while true do
    parser.space()
    local op, opToken
    for i = OPERATOR_MAX_LEN, 1, -1 do
      if buffer[bufIndex + i - 1] then
        opToken = bufValue
        for j = 1, i - 1 do
          if buffer[bufIndex + j] then
            opToken = opToken .. buffer[bufIndex + j]
          end
        end

        op = OPERATORS[opToken]
        if op then
          break
        end
      end
    end

    if not op or op.prec < minPrec then
      break
    else
      consume(#opToken)
    end

    if binop[1] then
      binop = { op, binop }
    else
      binop[1] = op
    end

    parser.space()
    binop[3] = op.assoc == LEFT_ASSOCIATIVE and parser.expr(op.prec + 1)
      or parser.expr(op.prec)
  end

  if not binop[1] then
    -- Remove unnecessary nesting for terminals
    return binop[2]
  else
    return binop
  end
end

function parser.expr(minPrec)
  minPrec = minPrec or 1
  -- TODO: unary ops
  return parser.binop(minPrec)
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.expr(input)
  loadBuffer(input)
  return parser.expr()
end
