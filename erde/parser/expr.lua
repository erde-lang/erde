local _ENV = require('erde.parser.env').load()

-- -----------------------------------------------------------------------------
-- Constants
-- -----------------------------------------------------------------------------

local LEFT_ASSOCIATIVE = -1
local RIGHT_ASSOCIATIVE = 1

local UNOPS = {
  ['-'] = { tag = TAG_NEG, prec = 14 },
  ['#'] = { tag = TAG_LEN, prec = 14 },
  ['~'] = { tag = TAG_NOT, prec = 14 },
  ['.~'] = { tag = TAG_BNOT, prec = 14 },
}

local BINOPS = {
  ['>>'] = { tag = TAG_PIPE, prec = 1, assoc = LEFT_ASSOCIATIVE },
  ['?'] = { tag = TAG_TERNARY, prec = 2, assoc = LEFT_ASSOCIATIVE },
  ['??'] = { tag = TAG_NC, prec = 3, assoc = LEFT_ASSOCIATIVE },
  ['|'] = { tag = TAG_OR, prec = 4, assoc = LEFT_ASSOCIATIVE },
  ['&'] = { tag = TAG_AND, prec = 5, assoc = LEFT_ASSOCIATIVE },
  ['=='] = { tag = TAG_EQ, prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['~='] = { tag = TAG_NEQ, prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['<='] = { tag = TAG_LTE, prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['>='] = { tag = TAG_GTE, prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['<'] = { tag = TAG_LT, prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['>'] = { tag = TAG_GT, prec = 6, assoc = LEFT_ASSOCIATIVE },
  ['.|'] = { tag = TAG_BOR, prec = 7, assoc = LEFT_ASSOCIATIVE },
  ['.~'] = { tag = TAG_BXOR, prec = 8, assoc = LEFT_ASSOCIATIVE },
  ['.&'] = { tag = TAG_BAND, prec = 9, assoc = LEFT_ASSOCIATIVE },
  ['.<<'] = { tag = TAG_LSHIFT, prec = 10, assoc = LEFT_ASSOCIATIVE },
  ['.>>'] = { tag = TAG_RSHIFT, prec = 10, assoc = LEFT_ASSOCIATIVE },
  ['..'] = { tag = TAG_CONCAT, prec = 11, assoc = LEFT_ASSOCIATIVE },
  ['+'] = { tag = TAG_ADD, prec = 12, assoc = LEFT_ASSOCIATIVE },
  ['-'] = { tag = TAG_SUB, prec = 12, assoc = LEFT_ASSOCIATIVE },
  ['*'] = { tag = TAG_MULT, prec = 13, assoc = LEFT_ASSOCIATIVE },
  ['/'] = { tag = TAG_DIV, prec = 13, assoc = LEFT_ASSOCIATIVE },
  ['//'] = { tag = TAG_INTDIV, prec = 13, assoc = LEFT_ASSOCIATIVE },
  ['%'] = { tag = TAG_MOD, prec = 13, assoc = LEFT_ASSOCIATIVE },
  ['^'] = { tag = TAG_EXP, prec = 15, assoc = RIGHT_ASSOCIATIVE },
}

local BINOP_MAX_LEN = 1
for key, value in pairs(BINOPS) do
  BINOP_MAX_LEN = math.max(BINOP_MAX_LEN, #key)
end

-- -----------------------------------------------------------------------------
-- Parse
--
-- This uses precedence climbing and is based on this amazing blog post:
-- https://eli.thegreenplace.net/2012/08/02/parsing-expressions-by-precedence-climbing
-- -----------------------------------------------------------------------------

function parser.expr(minPrec)
  minPrec = minPrec or 1

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
  elseif UNOPS[bufValue] ~= nil then
    local op = UNOPS[bufValue]
    consume()
    operand = { op, parser.expr(op.prec + 1) }
  elseif bufValue == EOF then
    error('unexpected EOF')
  else
    -- TODO: more terminals
    operand = parser.number()
  end

  local node = { nil, operand, nil }

  while true do
    parser.space()
    local op, opToken
    for i = BINOP_MAX_LEN, 1, -1 do
      if buffer[bufIndex + i - 1] then
        opToken = bufValue
        for j = 1, i - 1 do
          if buffer[bufIndex + j] then
            opToken = opToken .. buffer[bufIndex + j]
          end
        end

        op = BINOPS[opToken]
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

    if node[1] then
      node = { op, node }
    else
      node[1] = op
    end

    if op.tag == TAG_TERNARY then
      parser.space()
      node[3] = parser.expr()
      parser.space()
      if bufValue ~= ':' then
        error('missing : in ternary')
      end
      consume()
    else
    end

    parser.space()
    node[#node + 1] = op.assoc == LEFT_ASSOCIATIVE
        and parser.expr(op.prec + 1)
      or parser.expr(op.prec)
  end

  if not node[1] then
    -- Remove unnecessary nesting for terminals
    return node[2]
  else
    return node
  end
end

-- -----------------------------------------------------------------------------
-- Unit Parse
-- -----------------------------------------------------------------------------

function unit.expr(input)
  loadBuffer(input)
  return parser.expr()
end
