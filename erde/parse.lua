local C = require('erde.constants')
local tokenize = require('erde.tokenize')

-- Foward declare rules
local ArrowFunction, Assignment, Binop, Block, Break, Continue, Declaration, Destructure, DoBlock, ForLoop, Function, Goto, IfElse, Module, OptChain, Params, RepeatUntil, Return, Spread, String, Table, TryCatch, Unop, WhileLoop

-- =============================================================================
-- State
-- =============================================================================

local tokens, tokenInfo, newlines
local currentTokenIndex, currentToken

-- Used to tell other rules whether the current expression is part of the
-- ternary block. Required to know whether ':' should be parsed exclusively
-- as a method accessor or also consider ternary ':'.
local isTernaryExpr = false

-- =============================================================================
-- Helpers
-- =============================================================================

local function backup()
  return {
    currentTokenIndex = currentTokenIndex,
    currentToken = currentToken,
    isTernaryExpr = isTernaryExpr,
  }
end

local function restore(state)
  currentTokenIndex = state.currentTokenIndex
  currentToken = state.currentToken
  isTernaryExpr = state.isTernaryExpr
end

local function consume()
  local consumedToken = tokens[currentTokenIndex]
  currentTokenIndex = currentTokenIndex + 1
  currentToken = tokens[currentTokenIndex]
  return consumedToken
end

local function lookBehind(n)
  return tokens[currentTokenIndex - n] or ''
end

local function lookAhead(n)
  return tokens[currentTokenIndex + n] or ''
end

local function branch(token)
  if token == currentToken then
    consume()
    return true
  else
    return false
  end
end

local function expect(token, skipConsume)
  if token ~= currentToken then
    error('Expected ' .. token .. ' got ' .. tostring(currentToken))
  elseif not skipConsume then
    consume()
  end
end

-- =============================================================================
-- Macros
-- =============================================================================

local function Try(rule)
  local state = backup()
  local ok, node = pcall(rule)

  if ok then
    return node
  else
    restore(state)
  end
end

local function Switch(rules)
  for i, rule in ipairs(rules) do
    local node = Try(rule)
    if node then
      return node
    end
  end
end

local function Surround(openChar, closeChar, parse)
  expect(openChar)
  local node = parse()
  expect(closeChar)
  return node
end

local function Parens(opts)
  if currentToken ~= '(' and not opts.demand then
    return opts.parse()
  else
    opts.demand = false

    if opts.prioritizeRule then
      local node = Try(opts.parse)
      if node then
        return node
      end
    end

    return Surround('(', ')', function()
      return opts.allowRecursion and Parens(opts) or opts.parse()
    end)
  end
end

local function List(opts)
  local list = {}
  local hasTrailingComma = false

  repeat
    local node = Try(opts.parse)
    if not node then
      break
    end

    hasTrailingComma = branch(',')
    table.insert(list, node)
  until not hasTrailingComma

  assert(opts.allowTrailingComma or not hasTrailingComma)
  assert(opts.allowEmpty or #list > 0)

  return list
end

-- =============================================================================
-- Pseudo Rules
-- =============================================================================

local function Name(opts)
  assert(
    currentToken:match('^[_a-zA-Z][_a-zA-Z0-9]*$'),
    'Malformed name: ' .. currentToken
  )

  if not opts or not opts.allowKeywords then
    for i, keyword in pairs(C.KEYWORDS) do
      assert(currentToken ~= keyword, 'Unexpected keyword: ' .. currentToken)
    end
  end

  return consume()
end

local function Var()
  return (currentToken == '{' or currentToken == '[') and Destructure()
    or Name()
end

local function Terminal()
  for _, terminal in pairs(C.TERMINALS) do
    if branch(terminal) then
      return terminal
    end
  end

  local node
  if currentToken == '(' then
    -- Also takes care of parenthesized expressions, since OptChain will unpack
    -- any trivial OptChainBase
    node = Switch({ ArrowFunction, OptChain })
  elseif currentToken == 'do' then
    node = DoBlock({ isExpr = true })
  elseif currentToken:match('^.?[0-9]') then
    -- Only need to check first couple chars, rest is token care of by tokenizer
    node = consume()
  elseif currentToken:match('^[\'"]$') or currentToken:match('^%[[[=]') then
    node = String()
  else
    -- Check ArrowFunction before Table for implicit params + destructure
    node = Switch({ ArrowFunction, Table, OptChain })
  end

  if not node then
    error('Unexpected token ' .. currentToken)
  end

  return node
end

local function Expr(opts)
  local minPrec = opts and opts.minPrec or 1
  local tokenIndexStart = currentTokenIndex
  local node = C.UNOPS[currentToken] and Unop() or Terminal()

  local binop = C.BINOPS[currentToken]
  while binop and binop.prec >= minPrec do
    node = Binop({
      minPrec = minPrec,
      lhs = node,
    })

    binop = C.BINOPS[currentToken]
  end

  return node
end

local function FunctionCall()
  local node = OptChain()
  local last = node[#node]

  if not last or last.variant ~= 'functionCall' then
    error('Missing function call parentheses')
  end

  return node
end

local function Id()
  local node = OptChain()
  local last = node[#node]

  if last and last.variant == 'functionCall' then
    error('Unexpected function call')
  end

  return node
end

local function Statement()
  if currentToken == 'break' then
    return Break()
  elseif currentToken == 'continue' then
    return Continue()
  elseif currentToken == 'goto' or currentToken == ':' then
    return Goto()
  elseif currentToken == 'do' then
    return DoBlock()
  elseif currentToken == 'if' then
    return IfElse()
  elseif currentToken == 'for' then
    return ForLoop()
  elseif currentToken == 'repeat' then
    return RepeatUntil()
  elseif currentToken == 'return' then
    return Return()
  elseif currentToken == 'try' then
    return TryCatch()
  elseif currentToken == 'while' then
    return WhileLoop()
  elseif currentToken == 'function' then
    return Function()
  elseif
    currentToken == 'local'
    or currentToken == 'global'
    or currentToken == 'module'
    or currentToken == 'main'
  then
    return lookAhead(1) == 'function' and Function() or Declaration()
  else
    return Switch({ FunctionCall, Assignment })
  end
end

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

function ArrowFunction()
  local node = {
    ruleName = 'ArrowFunction',
    tokenIndexStart = currentTokenIndex,
    hasFatArrow = false,
    hasImplicitReturns = false,
    params = Params({ allowImplicitParams = true }),
  }

  if branch('=>') then
    node.hasFatArrow = true
  elseif not branch('->') then
    error('Expected arrow (->, =>), got ' .. currentToken)
  end

  if currentToken == '{' then
    node.body = Surround('{', '}', Block)
  elseif currentToken == '(' then
    node.hasImplicitReturns = true
    node.returns = Parens({
      allowRecursion = true,
      parse = function()
        return List({
          allowTrailingComma = true,
          parse = Expr,
        })
      end,
    })
  else
    node.hasImplicitReturns = true
    node.returns = { Expr() }
  end

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

function Assignment()
  local node = {
    ruleName = 'Assignment',
    tokenIndexStart = currentTokenIndex,
    idList = currentToken ~= '(' and List({ parse = Id }) or Parens({
      allowRecursion = true,
      parse = function()
        return List({
          allowTrailingComma = true,
          parse = Id,
        })
      end,
    }),
  }

  if C.BINOP_ASSIGNMENT_BLACKLIST[currentToken] then
    error('Invalid assignment operator: ' .. currentToken)
  elseif C.BINOPS[currentToken] then
    node.op = C.BINOPS[consume()]
  end

  expect('=')
  node.exprList = currentToken ~= '(' and List({ parse = Expr })
    or Parens({
      allowRecursion = true,
      prioritizeRule = true,
      parse = function()
        return List({
          allowTrailingComma = true,
          parse = Expr,
        })
      end,
    })

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Binop
-- -----------------------------------------------------------------------------

function Binop(opts)
  local minPrec = opts and opts.minPrec or 1

  local op = C.BINOPS[currentToken]
  assert(op, 'Invalid binop token: ' .. currentToken)
  assert(op.prec >= minPrec, 'Binop does not have enough precedence.')
  consume()

  local node = {
    ruleName = 'Binop',
    tokenIndexStart = opts.tokenIndexStart,
    op = op,
    lhs = opts.lhs,
  }

  if op.token == '?' then
    isTernaryExpr = true
    node.ternaryExpr = Expr()
    isTernaryExpr = false
    expect(':')
  end

  local newMinPrec = op.prec + (op.assoc == C.LEFT_ASSOCIATIVE and 1 or 0)
  node.rhs = Expr({ minPrec = newMinPrec })
  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block()
  local node = { ruleName = 'Block', tokenIndexStart = currentTokenIndex }

  repeat
    local statement = Statement()
    table.insert(node, statement)
  until not statement

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

function Break()
  expect('break')
  return {
    ruleName = 'Break',
    tokenIndexStart = currentTokenIndex - 1,
    tokenIndexEnd = currentTokenIndex - 1,
  }
end

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

function Continue()
  expect('continue')
  return {
    ruleName = 'Continue',
    tokenIndexStart = currentTokenIndex - 1,
    tokenIndexEnd = currentTokenIndex - 1,
  }
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

function Declaration()
  if
    currentToken ~= 'local'
    and currentToken ~= 'global'
    and currentToken ~= 'module'
    and currentToken ~= 'main'
  then
    error('Missing declaration scope')
  end

  local node = {
    ruleName = 'Declaration',
    tokenIndexStart = currentTokenIndex,
    variant = consume(),
    exprList = {},
    varList = currentToken ~= '(' and List({ parse = Var }) or Parens({
      allowRecursion = true,
      parse = function()
        return List({
          allowTrailingComma = true,
          parse = Var,
        })
      end,
    }),
  }

  if branch('=') then
    node.exprList = currentToken ~= '(' and List({ parse = Expr })
      or Parens({
        allowRecursion = true,
        prioritizeRule = true,
        parse = function()
          return List({
            allowTrailingComma = true,
            parse = Expr,
          })
        end,
      })
  end

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

local function ArrayDestructure()
  return Surround('[', ']', function()
    return List({
      allowTrailingComma = true,
      parse = function()
        return {
          name = Name(),
          variant = 'numberDestruct',
          default = branch('=') and Expr(),
        }
      end,
    })
  end)
end

function Destructure()
  local node = { ruleName = 'Destructure', tokenIndexStart = currentTokenIndex }

  local destructs = currentToken == '[' and ArrayDestructure()
    or Surround('{', '}', function()
      return List({
        allowTrailingComma = true,
        parse = function()
          if currentToken == '[' then
            return ArrayDestructure()
          else
            return {
              name = Name(),
              variant = 'keyDestruct',
              alias = branch(':') and Name(),
              default = branch('=') and Expr(),
            }
          end
        end,
      })
    end)

  for _, destruct in ipairs(destructs) do
    if destruct.variant ~= nil then
      table.insert(node, destruct)
    else
      for _, numberDestruct in ipairs(destruct) do
        table.insert(node, numberDestruct)
      end
    end
  end

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

function DoBlock(opts)
  expect('do')
  return {
    ruleName = 'DoBlock',
    tokenIndexStart = currentTokenIndex,
    isExpr = opts and opts.isExpr,
    body = Surround('{', '}', Block),
    tokenIndexEnd = currentTokenIndex - 1,
  }
end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

function ForLoop()
  local node = { ruleName = 'ForLoop', tokenIndexStart = currentTokenIndex }
  expect('for')

  local firstName = Var()

  if type(firstName) == 'string' and branch('=') then
    node.variant = 'numeric'
    node.name = firstName
    node.parts = List({ parse = Expr })
  else
    node.variant = 'generic'
    node.varList = { firstName }

    while branch(',') do
      table.insert(node.varList, Var())
    end

    expect('in')
    node.exprList = List({ parse = Expr })
  end

  node.body = Surround('{', '}', Block)
  return node
end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

function Function()
  local node = {
    ruleName = 'Function',
    tokenIndexStart = currentTokenIndex,
    isMethod = false,
  }

  if
    currentToken == 'local'
    or currentToken == 'global'
    or currentToken == 'module'
    or currentToken == 'main'
  then
    node.variant = consume()
  end

  expect('function')
  node.names = { Name() }

  while branch('.') do
    table.insert(node.names, Name())
  end

  if branch(':') then
    node.isMethod = true
    table.insert(node.names, Name())
  end

  if not node.variant then
    node.variant = #node.names > 1 and 'global' or 'local'
  end

  node.params = Params()
  node.body = Surround('{', '}', Block)

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

function Goto()
  local node = { ruleName = 'Goto', tokenIndexStart = currentTokenIndex }

  if branch('goto') then
    node.variant = 'jump'
    node.name = Name()
  else
    node.variant = 'definition'
    expect(':')
    expect(':')
    node.name = Name()
    expect(':')
    expect(':')
  end

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

function IfElse()
  local node = {
    ruleName = 'IfElse',
    tokenIndexStart = currentTokenIndex,
    elseifNodes = {},
  }

  expect('if')

  node.ifNode = {
    condition = Expr(),
    body = Surround('{', '}', Block),
  }

  while branch('elseif') do
    table.insert(node.elseifNodes, {
      condition = Expr(),
      body = Surround('{', '}', Block),
    })
  end

  if branch('else') then
    node.elseNode = { body = Surround('{', '}', Block) }
  end

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

function Module()
  local node = { ruleName = 'Module', tokenIndexStart = currentTokenIndex }

  if currentToken:match('^#!') then
    node.shebang = consume()
  end

  repeat
    local statement = Statement()
    table.insert(node, statement)
  until not statement

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

local function OptChainBase()
  if currentToken == '(' then
    local base = Surround('(', ')', Expr)

    if type(base) == 'table' then
      base.parens = true
    end

    return base
  else
    return Name()
  end
end

local function OptChainDotIndex()
  local name = Try(function()
    return Name({ allowKeywords = true })
  end)

  return name and { variant = 'dotIndex', value = name }
end

local function OptChainMethod()
  local name = Try(function()
    return Name({ allowKeywords = true })
  end)

  local isNextChainFunctionCall = currentToken == '('
    or (currentToken == '?' and lookAhead(1) == '(')

  if name and isNextChainFunctionCall then
    return { variant = 'method', value = name }
  elseif not isTernaryExpr then
    -- Do not throw error here if isTernaryExpr, instead assume ':' is from
    -- ternary operator.
    error('Missing parentheses for method call')
  end
end

local function OptChainBracket()
  return {
    variant = 'bracketIndex',
    value = Surround('[', ']', Expr),
  }
end

local function OptChainFunctionCall()
  return {
    variant = 'functionCall',
    value = Parens({
      demand = true,
      parse = function()
        return List({
          allowEmpty = true,
          allowTrailingComma = true,
          parse = function()
            return currentToken == '...' and Spread() or Expr()
          end,
        })
      end,
    }),
  }
end

function OptChain()
  local node = {
    ruleName = 'OptChain',
    tokenIndexStart = currentTokenIndex,
    base = OptChainBase(),
  }

  while true do
    local state = backup()
    local isOptional = branch('?')

    local chain
    if branch('.') then
      chain = OptChainDotIndex()
    elseif branch(':') then
      chain = OptChainMethod()
    elseif currentToken == '[' then
      chain = OptChainBracket()
    elseif currentToken == '(' then
      if not newlines[currentTokenIndex - 1] then
        chain = OptChainFunctionCall()
      end
    end

    if not chain then
      restore(state)
      break
    end

    chain.optional = isOptional
    table.insert(node, chain)
  end

  node.tokenIndexEnd = currentTokenIndex - 1
  return #node == 0 and node.base or node -- unpack trivial OptChain
end

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

local function ParamsList()
  local paramsList = List({
    allowEmpty = true,
    allowTrailingComma = true,
    parse = function()
      return {
        value = Var(),
        default = branch('=') and Expr(),
      }
    end,
  })

  if (#paramsList == 0 or lookBehind(1) == ',') and branch('...') then
    table.insert(paramsList, {
      value = Try(Name),
      varargs = true,
    })
  end

  return paramsList
end

function Params(opts)
  opts = opts or {}
  local node = { ruleName = 'Params', tokenIndexStart = currentTokenIndex }

  local params
  if currentToken ~= '(' and opts.allowImplicitParams then
    params = { { value = Var() } }
  else
    params = Parens({ demand = true, parse = ParamsList })
  end

  for _, param in pairs(params) do
    table.insert(node, param)
  end

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

function RepeatUntil()
  expect('repeat')

  local node = {
    ruleName = 'RepeatUntil',
    tokenIndexStart = currentTokenIndex,
    body = Surround('{', '}', Block),
  }

  expect('until')
  node.condition = Expr()

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

function Return()
  local tokenIndexStart = currentTokenIndex
  expect('return')

  local node = currentToken ~= '(' and List({ parse = Expr, allowEmpty = true })
    or Parens({
      allowRecursion = true,
      prioritizeRule = true,
      parse = function()
        return List({
          allowTrailingComma = true,
          parse = Expr,
        })
      end,
    })

  node.ruleName = 'Return'
  node.tokenIndexStart = tokenIndexStart
  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

function Spread()
  expect('...')
  return {
    ruleName = 'Spread',
    tokenIndexStart = currentTokenIndex,
    value = Try(Expr),
    tokenIndexEnd = currentTokenIndex - 1,
  }
end

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

function String()
  local node = { ruleName = 'String', tokenIndexStart = currentTokenIndex }
  local terminatingToken

  if currentToken == "'" then
    node.variant = 'single'
    terminatingToken = consume()
  elseif currentToken == '"' then
    node.variant = 'double'
    terminatingToken = consume()
  elseif currentToken:match('^%[=*%[$') then
    node.variant = 'long'
    node.equals = ('='):rep(#currentToken - 2)
    terminatingToken = ']' .. node.equals .. ']'
    consume()
  else
    error('Unexpected token: ' .. currentToken)
  end

  while currentToken ~= terminatingToken do
    if currentToken == '{' then
      table.insert(node, {
        variant = 'interpolation',
        value = Surround('{', '}', Expr),
      })
    else
      table.insert(node, {
        variant = 'content',
        value = consume(),
      })
    end
  end

  consume() -- terminatingToken
  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

local function TableField()
  local field = {}

  if currentToken == '[' then
    field.variant = 'exprKey'
    field.key = Surround('[', ']', Expr)
  elseif currentToken == '...' then
    field.variant = 'spread'
    field.value = Spread()
  else
    local expr = Expr()

    if
      currentToken == '='
      and type(expr) == 'string'
      and expr:match('^[_a-zA-Z][_a-zA-Z0-9]*$')
    then
      field.variant = 'nameKey'
      field.key = expr
    else
      field.variant = 'numberKey'
      field.value = expr
    end
  end

  if field.variant == 'exprKey' or field.variant == 'nameKey' then
    expect('=')
    field.value = Expr()
  end

  return field
end

function Table()
  local tokenIndexStart = currentTokenIndex

  local node = Surround('{', '}', function()
    return List({
      allowEmpty = true,
      allowTrailingComma = true,
      parse = TableField,
    })
  end)

  node.ruleName = 'Table'
  node.tokenIndexStart = tokenIndexStart
  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

function TryCatch()
  local node = { ruleName = 'TryCatch', tokenIndexStart = currentTokenIndex }

  expect('try')
  node.try = Surround('{', '}', Block)

  expect('catch')
  node.error = Try(Var)
  node.catch = Surround('{', '}', Block)

  node.tokenIndexEnd = currentTokenIndex - 1
  return node
end

-- -----------------------------------------------------------------------------
-- Unop
-- -----------------------------------------------------------------------------

function Unop()
  local tokenIndexStart = currentTokenIndex
  local op = C.UNOPS[currentToken]
  assert(op, 'Invalid unop token: ' .. currentToken)
  consume()

  return {
    ruleName = 'Unop',
    tokenIndexStart = tokenIndexStart,
    op = op,
    operand = Expr({ minPrec = op.prec + 1 }),
    tokenIndexEnd = currentTokenIndex - 1,
  }
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

function WhileLoop()
  expect('while')
  return {
    ruleName = 'WhileLoop',
    tokenIndexStart = currentTokenIndex,
    condition = Expr(),
    body = Surround('{', '}', Block),
    tokenIndexEnd = currentTokenIndex - 1,
  }
end

-- =============================================================================
-- Return
-- =============================================================================

return function(text)
  tokens, tokenInfo, newlines = tokenize(text)
  currentTokenIndex = 1
  currentToken = tokens[1]
  isTernaryExpr = false
  return Module(text)
end
