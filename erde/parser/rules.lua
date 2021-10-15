local _ENV = require('erde.parser.env').load()
require('erde.parser.utils')

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
-- Rule: Assignment
-- -----------------------------------------------------------------------------

local BINOP_ASSIGNMENT_BLACKLIST = {
  ['?'] = true,
  ['=='] = true,
  ['~='] = true,
  ['<='] = true,
  ['>='] = true,
  ['<'] = true,
  ['>'] = true,
}

function parser.assignment()
  local node = { tag = TAG_ASSIGNMENT, name = parser.pad(parser.name) }

  for i = BINOP_MAX_LEN, 1, -1 do
    local opToken = peek(i)
    local op = BINOPS[opToken]
    if op and not BINOP_ASSIGNMENT_BLACKLIST[opToken] then
      consume(i)
      node.opTag = op.tag
      break
    end
  end

  if not branchChar('=') then
    error('expected =')
  end

  node.expr = parser.pad(parser.expr)

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Comment
-- -----------------------------------------------------------------------------

function parser.comment()
  local capture = {}
  local node = {}

  if branchWord('---') then
    node.tag = TAG_LONG_COMMENT

    while true do
      if bufValue == '-' and branchWord('---') then
        break
      elseif bufValue == EOF then
        error('unterminated long comment')
      else
        consume(1, capture)
      end
    end
  elseif branchWord('--') then
    node.tag = TAG_SHORT_COMMENT

    while true do
      if bufValue == '\n' or bufValue == EOF then
        break
      else
        consume(1, capture)
      end
    end
  else
    error('invalid comment')
  end

  node.value = table.concat(capture)
  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Expr
--
-- This uses precedence climbing and is based on this amazing blog post:
-- https://eli.thegreenplace.net/2012/08/02/parsing-expressions-by-precedence-climbing
-- -----------------------------------------------------------------------------

function parser.expr(minPrec)
  minPrec = minPrec or 1

  local operand
  if branchChar('(') then
    operand = parser.pad(parser.expr)
    operand.parens = true
    if not branchChar(')') then
      error('unbalanced parens')
    end
  elseif UNOPS[bufValue] ~= nil then
    local op = UNOPS[bufValue]
    consume()
    operand = { tag = op.tag, parser.expr(op.prec + 1) }
  elseif bufValue == EOF then
    error('unexpected EOF')
  else
    -- TODO: more terminals
    operand = parser.number()
  end

  local node = operand

  while true do
    parser.space()
    local op, opToken
    for i = BINOP_MAX_LEN, 1, -1 do
      opToken = peek(i)
      op = BINOPS[opToken]
      if op then
        break
      end
    end

    if not op or op.prec < minPrec then
      break
    else
      consume(#opToken)
      node = { tag = op.tag, node }
    end

    if op.tag == TAG_TERNARY then
      node[#node + 1] = parser.pad(parser.expr)
      if not branchChar(':') then
        error('missing : in ternary')
      end
    end

    parser.space()
    node[#node + 1] = op.assoc == LEFT_ASSOCIATIVE
        and parser.expr(op.prec + 1)
      or parser.expr(op.prec)
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Number
-- -----------------------------------------------------------------------------

function parser.number()
  local capture = {}

  if branchWord('0x', capture) or branchWord('0X', capture) then
    stream(Hex, capture, true)

    if branchChar('.', capture) then
      stream(Hex, capture, true)
    end

    if branchChar('pP', capture) then
      branchChar('+-', capture)
      stream(Digit, capture, true)
    end
  else
    while Digit[bufValue] do
      consume(1, capture, true)
    end

    if branchChar('.', capture) then
      stream(Digit, capture, true)
    end

    if #capture > 0 and branchChar('eE', capture) then
      branchChar('+-', capture)
      stream(Digit, capture, true)
    end
  end

  if #capture == 0 then
    error('expected number')
  end

  return { tag = TAG_NUMBER, value = table.concat(capture) }
end

-- -----------------------------------------------------------------------------
-- Rule: String
-- -----------------------------------------------------------------------------

function parser.string()
  if bufValue == "'" or bufValue == '"' then
    local capture = {}
    consume(1, capture)

    while true do
      if bufValue == capture[1] then
        consume(1, capture)
        break
      elseif bufValue == '\n' or bufValue == EOF then
        error('unterminated string')
      else
        consume(1, capture)
      end
    end

    return { tag = TAG_SHORT_STRING, value = table.concat(capture) }
  elseif branchChar('`') then
    local node = { tag = TAG_LONG_STRING }
    local capture = {}

    while true do
      if branchChar('{') then
        if #capture > 0 then
          node[#node + 1] = table.concat(capture)
          capture = {}
        end

        node[#node + 1] = parser.pad(parser.expr)
        if not branchChar('}') then
          error('unclosed interpolation')
        end
      elseif branchChar('`') then
        break
      elseif bufValue == '\\' then
        if ('{}`'):find(buffer[bufIndex + 1]) then
          consume()
          consume(1, capture)
        else
          consume(2, capture)
        end
      elseif bufValue == EOF then
        error('unterminated string')
      else
        consume(1, capture)
      end
    end

    if #capture > 0 then
      node[#node + 1] = table.concat(capture)
    end

    return node
  else
    error('Expected quote (",\',`), found ' .. bufValue)
  end
end

-- -----------------------------------------------------------------------------
-- Rule: Var
-- -----------------------------------------------------------------------------

function parser.var()
  local node = {}

  if Whitespace[buffer[bufIndex + #'local']] and branchWord('local') then
    node.tag = TAG_LOCAL_VAR
  elseif Whitespace[buffer[bufIndex + #'global']] and branchWord('global') then
    node.tag = TAG_GLOBAL_VAR
  else
    return nil
  end

  node.name = parser.pad(parser.name)

  if branchChar('=') then
    node.initValue = parser.pad(parser.expr)
  end

  return node
end
