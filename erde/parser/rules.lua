local _ENV = require('erde.parser.env'):load()
require('erde.parser.utils')

-- -----------------------------------------------------------------------------
-- Rule: ArrowFunction
-- -----------------------------------------------------------------------------

function parser.ArrowFunction()
  local node = { params = parser.Params(), hasImplicitReturns = false }

  if branchStr('->') then
    node.variant = 'skinny'
  elseif branchStr('=>') then
    node.variant = 'fat'
  else
    throw.unexpected()
  end

  if bufValue == '{' then
    node.body = parser.surround('{', '}', parser.Block)
  else
    node.hasImplicitReturns = true
    node.returns = {}

    repeat
      local expr = parser.try(parser.Expr)

      if not expr then
        break
      end

      node.returns[#node.returns + 1] = expr
    until not branchChar(',')

    if #node.returns == 0 then
      throw.exprected('expression', true)
    end
  end

  return node
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
  local node = { name = parser.Name().value }

  for i = BINOP_MAX_LEN, 1, -1 do
    local opToken = peek(i)
    local op = BINOPS[opToken]

    if op and not BINOP_ASSIGNMENT_BLACKLIST[opToken] then
      consume(i)
      node.op = op
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
      parser.Assignment,
      parser.Comment,
      parser.DoBlock,
      parser.ForLoop,
      parser.IfElse,
      parser.Function,
      parser.FunctionCall,
      parser.RepeatUntil,
      parser.Return,
      parser.Var,
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

  if branchStr('---', true) then
    node.variant = 'long'

    while bufValue ~= '-' or not branchStr('---', true) do
      consume(1, capture)
    end
  elseif branchStr('--', true) then
    node.variant = 'short'

    while bufValue ~= '\n' and bufValue ~= EOF do
      consume(1, capture)
    end
  else
    throw.expected('comment', true)
  end

  node.value = table.concat(capture)

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Destructure
-- -----------------------------------------------------------------------------

function parser.Destructure()
  local node = {}
  local keyCounter = 1

  if branchChar('?') then
    node.optional = true
  end

  if not branchChar('{') then
    throw.expected('{')
  end

  while not branchChar('}') do
    local field = {}

    if branchChar(':') then
      field.variant = 'mapDestruct'
      field.name = parser.Name().value
      field.destructure = parser.try(parser.Destructure)
    else
      field.variant = 'arrayDestruct'
      field.key = keyCounter
      keyCounter = keyCounter + 1

      local name = parser.try(parser.Name)
      if name then
        field.name = name.value
      else
        field.destructure = parser.Destructure()
      end
    end

    if branchChar('=') then
      field.default = parser.Expr()
    end

    node[#node + 1] = field

    if not branchChar(',') and bufValue ~= '}' then
      throw.error('Missing trailing comma')
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: DoBlock
-- -----------------------------------------------------------------------------

function parser.DoBlock()
  if not branchWord('do') then
    throw.expected('do')
  end

  local node = { body = parser.surround('{', '}', parser.Block) }

  for _, statement in pairs(node.body) do
    if statement.rule == 'Return' then
      node.hasReturn = true
      break
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
  local node

  if UNOPS[bufValue] ~= nil then
    local op = UNOPS[bufValue]
    consume()
    node = { op = op, parser.Expr(op.prec + 1) }
  else
    node = parser.Terminal()
  end

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
    end

    consume(#opToken)
    node = { op = op, node }

    if op.tag == 'ternary' then
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

  local firstName = parser.Name().value
  local node

  if branchChar('=') then
    node = { variant = 'numeric', name = firstName, var = parser.Expr() }

    if not branchChar(',') then
      throw.expected(',')
    end

    node.limit = parser.Expr()

    if branchChar(',') then
      node.step = parser.Expr()
    end
  else
    node = { variant = 'generic', nameList = {}, exprList = {} }

    node.nameList[1] = firstName
    while branchChar(',') do
      node.nameList[#node.nameList + 1] = parser.Name().value
    end

    if not branchWord('in') then
      throw.expected('in')
    end

    node.exprList[1] = parser.Expr()
    while branchChar(',') do
      node.exprList[#node.exprList + 1] = parser.Expr()
    end
  end

  node.body = parser.surround('{', '}', parser.Block)

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Function
-- -----------------------------------------------------------------------------

function parser.Function()
  local node = {
    variant = branchWord('local') and 'local' or 'global',
    isMethod = false,
  }

  if not branchWord('function') then
    throw.expected('function')
  end

  node.names = { parser.Name().value }

  while true do
    if branchChar('.') then
      node.names[#node.names + 1] = parser.Name().value
    else
      if branchChar(':') then
        node.isMethod = true
        node.names[#node.names + 1] = parser.Name().value
      end

      break
    end
  end

  node.params = parser.Params()
  node.body = parser.surround('{', '}', parser.Block)

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: FunctionCall
-- -----------------------------------------------------------------------------

function parser.FunctionCall()
  local node = parser.OptChain()
  local last = node[#node]

  if not last then
    throw.expected('function call', true)
  elseif last.variant ~= 'params' then
    throw.error('Id cannot be function call')
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Id
-- -----------------------------------------------------------------------------

function parser.Id()
  local node = parser.OptChain()
  local last = node[#node]

  if last and last.variant == 'params' then
    throw.error('Id cannot be function call')
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: IfElse
-- -----------------------------------------------------------------------------

function parser.IfElse()
  local node = { elseifNodes = {} }

  if not branchWord('if') then
    throw.expected('if')
  end

  node.ifNode = {
    cond = parser.Expr(),
    body = parser.surround('{', '}', parser.Block),
  }

  while branchWord('elseif') do
    node.elseifNodes[#node.elseifNodes + 1] = {
      cond = parser.Expr(),
      body = parser.surround('{', '}', parser.Block),
    }
  end

  if branchWord('else') then
    node.elseNode = { body = parser.surround('{', '}', parser.Block) }
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Name
-- -----------------------------------------------------------------------------

function parser.Name()
  if not Alpha[bufValue] then
    error('name must start with alpha')
  end

  local capture = {}
  consume(1, capture)

  while Alpha[bufValue] or Digit[bufValue] or bufValue == '_' do
    consume(1, capture)
  end

  local value = table.concat(capture)
  for _, keyword in pairs(KEYWORDS) do
    if value == keyword then
      throw.error('name cannot be keyword')
    end
  end

  return { value = table.concat(capture) }
end

-- -----------------------------------------------------------------------------
-- Rule: Number
-- -----------------------------------------------------------------------------

function parser.Number()
  local capture = {}

  if branchStr('0x', true, capture) or branchStr('0X', true, capture) then
    stream(Hex, capture, true)

    if branchChar('.', true, capture) then
      stream(Hex, capture, true)
    end

    if branchChar('pP', true, capture) then
      branchChar('+-', true, capture)
      stream(Digit, capture, true)
    end
  else
    while Digit[bufValue] do
      consume(1, capture, true)
    end

    if branchChar('.', true, capture) then
      stream(Digit, capture, true)
    end

    if #capture > 0 and branchChar('eE', true, capture) then
      branchChar('+-', true, capture)
      stream(Digit, capture, true)
    end
  end

  if #capture == 0 then
    throw.expected('number', true)
  end

  return { value = table.concat(capture) }
end

-- -----------------------------------------------------------------------------
-- Rule: OptChain
-- -----------------------------------------------------------------------------

function parser.OptChain()
  local node = {
    base = parser.switch({
      parser.Name,
      function()
        local base = parser.surround('(', ')', parser.Expr)
        base.parens = true
        return base
      end,
    }),
  }

  if not node.base then
    throw.expected('name or expression', true)
  end

  while true do
    local backup = parser.saveState()
    local chain = { optional = branchChar('?') }

    if branchChar('.') then
      chain.variant = 'dotIndex'
      chain.value = parser.Name().value
    elseif bufValue == '[' then
      chain.variant = 'bracketIndex'
      chain.value = parser.surround('[', ']', parser.Expr)
    elseif bufValue == '(' then
      chain.variant = 'params'
      chain.value = parser.surround('(', ')', function()
        local args = {}

        while bufValue ~= ')' do
          args[#args + 1] = parser.Expr()
          if not branchChar(',') then
            break
          end
        end

        return args
      end)
    elseif branchChar(':') then
      chain.variant = 'method'
      chain.value = parser.Name().value
      if bufValue ~= '(' then
        throw.error('missing args after method call')
      end
    else
      -- revert consumption from branchChar('?')
      parser.restoreState(backup)
      break
    end

    node[#node + 1] = chain
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Params
-- -----------------------------------------------------------------------------

function parser.Params()
  return parser.surround('(', ')', function()
    local node = {}

    repeat
      local param = {
        value = parser.switch({
          parser.Name,
          parser.Destructure,
        }),
      }

      if not param.value then
        break
      end

      if branchChar('=') then
        param.default = parser.Expr()
      end

      node[#node + 1] = param
    until not branchChar(',')

    if branchStr('...') then
      local name = parser.try(parser.Name)
      node[#node + 1] = {
        varargs = true,
        name = name and name.value or nil,
      }
    end

    return node
  end)
end

-- -----------------------------------------------------------------------------
-- Rule: RepeatUntil
-- -----------------------------------------------------------------------------

function parser.RepeatUntil()
  if not branchWord('repeat') then
    throw.expected('repeat')
  end

  local node = { body = parser.surround('{', '}', parser.Block) }

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

  return { value = parser.Expr() }
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

    return { variant = 'short', value = table.concat(capture) }
  elseif branchChar('`', true) then
    local node = { variant = 'long' }
    local capture = {}

    while true do
      if branchChar('{', true) then
        if #capture > 0 then
          node[#node + 1] = table.concat(capture)
          capture = {}
        end

        node[#node + 1] = parser.Expr()
        if not branchChar('}', true) then
          throw.expected('}')
        end
      elseif branchChar('`', true) then
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
-- Rule: Table
-- -----------------------------------------------------------------------------

function parser.Table()
  local node = {}
  local keyCounter = 1

  if not branchChar('{') then
    throw.expected('{')
  end

  while not branchChar('}') do
    local field = {}

    if branchChar(':') then
      field.variant = 'inlineKey'
      field.key = parser.Name().value
    elseif bufValue == '[' then
      field.variant = 'exprKey'
      field.key = parser.surround('[', ']', parser.Expr)

      if not branchChar(':') then
        throw.expected(':')
      end

      field.value = parser.Expr()
    else
      local expr = parser.switch({
        parser.Name,
        parser.Expr,
      })

      if not expr then
        throw.unexpected()
      end

      if not branchChar(':') then
        field.variant = 'arrayKey'
        field.key = keyCounter
        field.value = expr
        keyCounter = keyCounter + 1
      elseif expr.rule == 'Name' then
        field.variant = 'nameKey'
        field.key = expr.value
        field.value = parser.Expr()
      elseif expr.rule == 'String' then
        field.variant = 'stringKey'
        field.key = expr
        field.value = parser.Expr()
      else
        throw.unexpected('expression')
      end
    end

    node[#node + 1] = field

    if not branchChar(',') and bufValue ~= '}' then
      throw.error('Missing comma')
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Terminal
-- -----------------------------------------------------------------------------

function parser.Terminal()
  if bufValue == '(' then
    local node = parser.switch({
      parser.ArrowFunction,
      parser.OptChain,
      function()
        return parser.surround('(', ')', parser.Expr)
      end,
    })

    if node == nil then
      throw.unexpected()
    end

    node.parens = true
    return node
  end

  for _, terminal in pairs(TERMINALS) do
    if branchWord(terminal) then
      return { value = terminal }
    end
  end

  local node = parser.switch({
    parser.Table,
    parser.Number,
    parser.String,
    parser.OptChain,
  })

  if not node then
    throw.expected('terminal', true)
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Rule: Var
-- -----------------------------------------------------------------------------

function parser.Var()
  local node = {}

  if branchWord('local') then
    node.variant = 'local'
  else
    branchWord('global')
    node.variant = 'global'
  end

  node.name = parser.Name().value

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
    cond = parser.Expr(),
    body = parser.surround('{', '}', parser.Block),
  }
end
