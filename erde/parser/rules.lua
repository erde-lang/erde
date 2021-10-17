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

function parser.Assignment()
  local node = { tag = TAG_ASSIGNMENT, name = parser.name() }

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
    throw.expected('=')
  end

  node.expr = parser.Expr()

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Block
-- -----------------------------------------------------------------------------

function parser.Block()
  local node = {}

  while true do
    local statement = parser.switch({
      parser.Comment,
      parser.Return,
    })

    if not statement then
      break
    end

    node[#node + 1] = statement
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Comment
-- -----------------------------------------------------------------------------

function parser.Comment()
  local capture = {}
  local node = {}

  if branchStr('---') then
    node.tag = TAG_LONG_COMMENT

    while true do
      if bufValue == '-' and branchStr('---') then
        break
      else
        consume(1, capture)
      end
    end
  elseif branchStr('--') then
    node.tag = TAG_SHORT_COMMENT

    while true do
      if bufValue == '\n' or bufValue == EOF then
        break
      else
        consume(1, capture)
      end
    end
  else
    throw.expected('comment', true)
  end

  node.value = table.concat(capture)
  return node
end

-- -----------------------------------------------------------------------------
-- Rule: DoBlock
-- -----------------------------------------------------------------------------

function parser.DoBlock()
  if not branchWord('do') then
    throw.expected('do')
  end

  local node = {
    tag = TAG_DO_BLOCK,
    block = parser.surround('{', '}', parser.Block),
  }

  for _, statement in pairs(node.block) do
    if statement.tag == TAG_RETURN then
      node.hasReturn = true
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Expr
--
-- This uses precedence climbing and is based on this amazing blog post:
-- https://eli.thegreenplace.net/2012/08/02/parsing-expressions-by-precedence-climbing
-- -----------------------------------------------------------------------------

function parser.Expr(minPrec)
  minPrec = minPrec or 1

  local operand
  if branchChar('(') then
    operand = parser.Expr()
    operand.parens = true
    if not branchChar(')') then
      throw.expected(')')
    end
  elseif UNOPS[bufValue] ~= nil then
    local op = UNOPS[bufValue]
    consume()
    operand = { tag = op.tag, parser.Expr(op.prec + 1) }
  else
    -- TODO: more terminals
    operand = parser.switch({
      parser.Number,
      parser.String,
    })

    if operand == nil then
      throw.expected('expression', true)
    end
  end

  local node = operand
  parser.space()

  while true do
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
      node[#node + 1] = parser.Expr()
      if not branchChar(':') then
        throw.expected(':')
      end
    end

    node[#node + 1] = op.assoc == LEFT_ASSOCIATIVE
        and parser.Expr(op.prec + 1)
      or parser.Expr(op.prec)
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: ForLoop
-- -----------------------------------------------------------------------------

function parser.ForLoop()
  if not branchWord('for') then
    throw.expected('for')
  end

  local firstName = parser.name()
  local node

  if branchChar('=') then
    node = { tag = TAG_NUMERIC_FOR, name = firstName, var = parser.Expr() }

    if not branchChar(',') then
      throw.expected(',')
    end

    node.limit = parser.Expr()

    if branchChar(',') then
      node.step = parser.Expr()
    end
  else
    node = { tag = TAG_GENERIC_FOR, nameList = {}, exprList = {} }

    node.nameList[1] = firstName
    while branchChar(',') do
      node.nameList[#node.nameList + 1] = parser.name()
    end

    if not branchWord('in') then
      throw.expected('in')
    end

    node.exprList[1] = parser.Expr()
    while branchChar(',') do
      node.exprList[#node.exprList + 1] = parser.Expr()
    end
  end

  node.block = parser.surround('{', '}', parser.Block)

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: IfElse
-- -----------------------------------------------------------------------------

function parser.IfElse()
  local node = { tag = TAG_IF_ELSE, elseifNodes = {} }

  if not branchWord('if') then
    throw.expected('if')
  end

  node.ifNode = {
    cond = parser.Expr(),
    block = parser.surround('{', '}', parser.Block),
  }

  while branchWord('elseif') do
    node.elseifNodes[#node.elseifNodes + 1] = {
      cond = parser.Expr(),
      block = parser.surround('{', '}', parser.Block),
    }
  end

  if branchWord('else') then
    node.elseNode = { block = parser.surround('{', '}', parser.Block) }
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Number
-- -----------------------------------------------------------------------------

function parser.Number()
  local capture = {}

  if branchStr('0x', capture) or branchStr('0X', capture) then
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
    throw.expected('number', true)
  end

  return { tag = TAG_NUMBER, value = table.concat(capture) }
end

-- -----------------------------------------------------------------------------
-- Rule: RepeatUntil
-- -----------------------------------------------------------------------------

function parser.RepeatUntil()
  if not branchWord('repeat') then
    throw.expected('repeat')
  end

  local node = {
    tag = TAG_REPEAT_UNTIL,
    block = parser.surround('{', '}', parser.Block),
  }

  if not branchWord('until') then
    throw.expected('until')
  end

  node.cond = parser.surround('(', ')', parser.Expr)

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Return
-- -----------------------------------------------------------------------------

function parser.Return()
  if not branchWord('return') then
    throw.expected('return')
  end

  return { tag = 'TAG_RETURN', value = parser.Expr() }
end

-- -----------------------------------------------------------------------------
-- Rule: String
-- -----------------------------------------------------------------------------

function parser.String()
  if bufValue == "'" or bufValue == '"' then
    local capture = {}
    consume(1, capture)

    while true do
      if bufValue == capture[1] then
        consume(1, capture)
        break
      elseif bufValue == '\n' then
        throw.error('Unterminated string')
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

        node[#node + 1] = parser.Expr()
        if not branchChar('}') then
          throw.expected('}')
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
      else
        consume(1, capture)
      end
    end

    if #capture > 0 then
      node[#node + 1] = table.concat(capture)
    end

    return node
  else
    throw.expected('quote (",\',`)', true)
  end
end

-- -----------------------------------------------------------------------------
-- Rule: Var
-- -----------------------------------------------------------------------------

function parser.Var()
  local node = {}

  if Whitespace[buffer[bufIndex + #'local']] and branchWord('local') then
    node.tag = TAG_LOCAL_VAR
  elseif Whitespace[buffer[bufIndex + #'global']] and branchWord('global') then
    node.tag = TAG_GLOBAL_VAR
  else
    return nil
  end

  node.name = parser.name()

  if branchChar('=') then
    node.initValue = parser.Expr()
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: WhileLoop
-- -----------------------------------------------------------------------------

function parser.WhileLoop()
  if not branchWord('while') then
    throw.expected('while')
  end

  return {
    tag = TAG_WHILE_LOOP,
    cond = parser.Expr(),
    block = parser.surround('{', '}', parser.Block),
  }
end
