local C = require('erde.constants')
local tokenize = require('erde.tokenize')

-- Foward declare rules
local ArrowFunction, Assignment, Block, Break, Continue, Declaration, Destructure, DoBlock, Expr, ForLoop, Function, Goto, IfElse, Module, OptChain, Params, RepeatUntil, Return, Self, Spread, String, Table, TryCatch, WhileLoop

-- =============================================================================
-- State
-- =============================================================================

local tokens
local currentTokenIndex, currentToken

-- Used to tell other rules whether the current expression is part of the
-- ternary block. Required to know whether ':' should be parsed exclusively
-- as a method accessor or also consider ternary ':'.
local isTernaryExpr = false

-- Keeps track of the Block body of the closest loop ancestor (ForLoop,
-- RepeatUntil, WhileLoop). This is used to validate and link Break and
-- Continue statements.
local loopBlock = nil

-- Keeps track of the top level Block. This is used to register module
-- nodes when using the 'module' scope.
local moduleBlock = nil

-- =============================================================================
-- Helpers
-- =============================================================================

local function reset(text)
  -- TODO use other tokenize results
  tokens = tokenize(text).tokens

  currentTokenIndex = 1
  currentToken = tokens[1]

  isTernaryExpr = false
  loopBlock = nil
  moduleBlock = nil
end

local function backup()
  return {
    currentTokenIndex = currentTokenIndex,
    currentToken = currentToken,
    isTernaryExpr = isTernaryExpr,
    loopBlock = loopBlock,
    moduleBlock = moduleBlock,
  }
end

local function restore(backup)
  currentTokenIndex = backup.currentTokenIndex
  currentToken = backup.currentToken
  isTernaryExpr = backup.isTernaryExpr
  loopBlock = backup.loopBlock
  moduleBlock = backup.moduleBlock
end

local function consume()
  local consumedToken = tokens[currentTokenIndex]
  currentTokenIndex = currentTokenIndex + 1
  currentToken = tokens[currentTokenIndex]
  return consumedToken
end

local function peek(n)
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

  return list, hasTrailingComma
end

-- =============================================================================
-- Pseudo Rules
-- =============================================================================

local function Name()
  assert(
    currentToken:match('^[_a-zA-Z][_a-zA-Z0-9]*$'),
    'Malformed name: ' .. currentToken
  )

  for i, keyword in pairs(C.KEYWORDS) do
    assert(
      currentToken ~= keyword,
      'Cannot use keyword as name: ' .. currentToken
    )
  end

  return consume()
end

local function Number()
  if not currentToken:match('^%.?[0-9]') then
    error('Malformed number: ' .. currentToken)
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
    node = Switch({
      ArrowFunction,
      OptChain,
      function()
        local node = Surround('(', ')', Expr)
        node.parens = true
        return node
      end,
    })
  elseif currentToken == 'do' then
    node = DoBlock({ isExpr = true })
  elseif currentToken:match('^[.0-9]') then
    node = Number()
  elseif currentToken:match('^[\'"]$') or currentToken:match('^%[[[=]') then
    node = String()
  else
    node = Switch({
      -- Check ArrowFunction again for implicit params! This must be checked
      -- before Table for implicit params + destructure
      ArrowFunction,
      Table,
      OptChain,
    })
  end

  if not node then
    error('Unexpected token ' .. currentToken)
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

  if last then
    if last.variant == 'functionCall' then
      error('Unexpected function call')
    end
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
    if peek(1) == 'function' then
      return Function()
    else
      return Declaration()
    end
  else
    return Switch({
      FunctionCall,
      Assignment,
    })
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
    node.body = Surround('{', '}', function()
      return Block({ isFunctionBlock = true })
    end)
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

  return node
end

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

function Assignment()
  local node = {
    ruleName = 'Assignment',
    idList = List({ parse = Id }),
  }

  if C.BINOP_ASSIGNMENT_BLACKLIST[currentToken] then
    error('Invalid assignment operator: ' .. currentToken)
  elseif C.BINOPS[currentToken] then
    node.op = C.BINOPS[consume()]
  end

  expect('=')
  node.exprList = List({ parse = Expr })
  return node
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block(opts)
  opts = opts or {}

  -- TODO: remove me
  moduleBlock = nil

  local node = {
    ruleName = 'Block',

    -- Table for Continue nodes to register themselves.
    continueNodes = {},
  }

  repeat
    -- Run this on ever iteration in case nested blocks change values
    if opts.isLoopBlock then
      -- unset? revert nested loop blocks?
      loopBlock = node
    elseif opts.isFunctionBlock then
      -- Reset loopBlock for function blocks. Break / Continue cannot
      -- traverse these.
      loopBlock = nil
    end

    local statement = Statement()
    table.insert(node, statement)
  until not statement

  return node
end

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

function Break()
  assert(loopBlock ~= nil, 'Cannot use `break` outside of loop')
  expect('break')
  return { ruleName = 'Break' }
end

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

function Continue()
  assert(loopBlock ~= nil, 'Cannot use `continue` outside of loop')
  expect('continue')

  local node = { ruleName = 'Continue' }
  table.insert(loopBlock.continueNodes, node)
  return node
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

function Declaration()
  local node = {
    ruleName = 'Declaration',
    isHoisted = false,
    varList = {},
    exprList = {},
  }

  if branch('local') then
    node.variant = 'local'
  elseif branch('global') then
    node.variant = 'global'
  elseif currentToken == 'module' or currentToken == 'main' then
    if not moduleBlock then
      error(currentToken .. ' declarations cannot be nested')
    end

    node.variant = consume()
  else
    error('Missing declaration scope')
  end

  node.varList = List({ parse = Var })

  if node.variant == 'main' then
    if
      #node.varList > 1
      or type(node.varList[1]) ~= 'string'
      or moduleBlock.mainName ~= nil
    then
      error('Cannot have multiple main declarations')
    end

    moduleBlock.mainName = node.varList[1]
  end

  if moduleBlock and node.variant ~= 'global' then
    node.isHoisted = true
    local nameList = {}

    for _, var in ipairs(node.varList) do
      if type(var) == 'string' then
        table.insert(nameList, var)
      else
        for _, destruct in ipairs(var) do
          table.insert(nameList, destruct.alias or destruct.name)
        end
      end
    end

    for _, name in ipairs(nameList) do
      table.insert(moduleBlock.hoistedNames, name)
    end

    if node.variant == 'module' then
      for _, name in ipairs(nameList) do
        table.insert(moduleBlock.moduleNames, name)
      end
    end
  end

  if branch('=') then
    node.exprList = List({ parse = Expr })
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

local function parseDestruct()
  local destruct = { name = Name() }

  if branch(':') then
    destruct.alias = Name()
  end

  if branch('=') then
    destruct.default = Expr()
  end

  return destruct
end

local function parseNumberKeyDestructs()
  return Surround('[', ']', function()
    return List({
      allowTrailingComma = true,
      parse = function()
        local destruct = parseDestruct()
        destruct.variant = 'numberDestruct'
        return destruct
      end,
    })
  end)
end

function Destructure()
  local node = { ruleName = 'Destructure' }

  local destructs = currentToken == '[' and parseNumberKeyDestructs()
    or Surround('{', '}', function()
      return List({
        allowTrailingComma = true,
        parse = function()
          if currentToken == '[' then
            return parseNumberKeyDestructs()
          else
            local destruct = parseDestruct()
            destruct.variant = 'keyDestruct'
            return destruct
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

  return node
end

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

function DoBlock(opts)
  expect('do')
  return {
    ruleName = 'DoBlock',
    isExpr = opts and opts.isExpr,
    body = Surround('{', '}', Block),
  }
end

-- -----------------------------------------------------------------------------
-- Expr
-- -----------------------------------------------------------------------------

function Expr(opts)
  local minPrec = opts and opts.minPrec or 1
  local node

  if C.UNOPS[currentToken] then
    node = { ruleName = 'Expr' }
    node.variant = 'unop'
    node.op = C.UNOPS[consume()]
    node.operand = Expr({ minPrec = node.op.prec + 1 })
  else
    node = Terminal()
  end

  local binop = C.BINOPS[currentToken]
  while binop and binop.prec >= minPrec do
    consume()

    node = {
      ruleName = 'Expr',
      variant = 'binop',
      op = binop,
      lhs = node,
    }

    if binop.token == '?' then
      isTernaryExpr = true
      node.ternaryExpr = Expr()
      isTernaryExpr = false
      expect(':')
    end

    local nextMinPrec = binop.prec
      + (binop.assoc == C.LEFT_ASSOCIATIVE and 1 or 0)
    node.rhs = Expr({ minPrec = nextMinPrec })

    binop = C.BINOPS[currentToken]
  end

  return node
end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

function ForLoop()
  local node = { ruleName = 'ForLoop' }
  expect('for')

  local firstName = Var()

  if branch('=') then
    node.variant = 'numeric'
    node.name = firstName
    node.parts = List({ parse = Expr })

    if type(firstName) == 'table' then
      error('Cannot use destructure in numeric for loop')
    elseif #node.parts < 2 then
      error('Invalid for loop parameters (missing parameters)')
    elseif #node.parts > 3 then
      error('Invalid for loop parameters (too many parameters)')
    end
  else
    node.variant = 'generic'
    node.varList = { firstName }

    while branch(',') do
      table.insert(node.varList, Var())
    end

    expect('in')
    node.exprList = List({ parse = Expr })
  end

  node.body = Surround('{', '}', function()
    return Block({ isLoopBlock = true })
  end)

  return node
end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

function Function()
  local node = {
    ruleName = 'Function',
    isHoisted = false,
    isMethod = false,
  }

  if branch('local') then
    node.variant = 'local'
  elseif currentToken == 'module' or currentToken == 'main' then
    if not moduleBlock then
      error(currentToken .. ' declarations cannot be nested')
    end

    node.variant = consume()
  else
    branch('global')
    node.variant = 'global'
  end

  expect('function')
  node.names = { Name() }

  while true do
    if branch('.') then
      table.insert(node.names, Name())
    else
      if branch(':') then
        node.isMethod = true
        table.insert(node.names, Name())
      end

      break
    end
  end

  if node.variant == 'module' or node.variant == 'main' then
    if #node.names > 1 then
      error('Cannot declare nested field as ' .. node.variant)
    end

    if node.variant == 'main' then
      if moduleBlock.mainName ~= nil then
        error('Cannot have multiple main declarations')
      end

      moduleBlock.mainName = node.names[1]
    else
      table.insert(moduleBlock.moduleNames, node.names[1])
    end
  end

  if moduleBlock and node.variant ~= 'global' and #node.names == 1 then
    node.isHoisted = true
    table.insert(moduleBlock.hoistedNames, node.names[1])
  end

  node.params = Params()
  node.body = Surround('{', '}', function()
    return Block({ isFunctionBlock = true })
  end)

  return node
end

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

function Goto()
  local node = { ruleName = 'Goto' }

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

  return node
end

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

function IfElse()
  local node = {
    ruleName = 'IfElse',
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

  return node
end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

function Module()
  local node = {
    ruleName = 'Module',

    -- Table for Declaration and Function nodes to register `module` scope
    -- variables.
    moduleNames = {},

    -- Return name for this block. Only valid at the top level.
    mainName = nil,

    -- Table for all top-level declared names. These are hoisted for convenience
    -- to have more "module-like" behavior prevalent in other languages.
    hoistedNames = {},
  }

  if currentToken:match('^#!') then
    node.shebang = consume()
  end

  repeat
    -- TODO: remove me
    moduleBlock = node

    local statement = Statement()
    table.insert(node, statement)
  until not statement

  if #node.moduleNames > 0 then
    for i, statement in ipairs(node) do
      if statement.ruleName == 'Return' then
        -- Block cannot use both `return` and `module`
        -- TODO: not good enough! What about conditional return?
        error()
      end
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

function OptChain()
  local node = { ruleName = 'OptChain' }

  if currentToken == '(' then
    node.base = Surround('(', ')', Expr)
    if type(node.base) == 'table' then
      node.base.parens = true
    end
  elseif currentToken == '$' then
    node.base = Self()
  else
    node.base = Name()
  end

  while true do
    local backup = backup()
    local chain = { optional = branch('?') }

    if branch('.') then
      local name = Try(Name)

      if name then
        chain.variant = 'dotIndex'
        chain.value = name
      else
        -- Do not throw error here, as '.' may be from an operator! Simply
        -- revert consumptions and break
        restore(backup)
        break
      end
    elseif currentToken == '[' then
      chain.variant = 'bracketIndex'
      chain.value = Surround('[', ']', Expr)
    elseif currentToken == '(' then
      chain.variant = 'functionCall'
      chain.value = Parens({
        demand = true,
        parse = function()
          return List({
            allowEmpty = true,
            allowTrailingComma = true,
            parse = function()
              return Switch({
                -- Spread must be before Expr, otherwise we will parse the
                -- spread as varargs!
                Spread,
                Expr,
              })
            end,
          })
        end,
      })
    elseif branch(':') then
      local methodName = Try(Name)

      if methodName and currentToken == '(' then
        chain.variant = 'method'
        chain.value = methodName
      elseif isTernaryExpr then
        -- Do not throw error here, instead assume ':' is from ternary
        -- operator. Simply revert consumptions and break
        restore(backup)
        break
      else
        error('Missing parentheses for method call')
      end
    else
      restore(backup) -- revert consumption from branch('?')
      break
    end

    table.insert(node, chain)
  end

  if #node == 0 then
    -- unpack trivial OptChain
    node = node.base

    if type(node) == 'string' then
      if not node:match('^[_a-zA-Z][_a-zA-Z0-9]*$') then
        error('Arbitrary expressions not allowed as OptChains')
      end
    elseif node.ruleName ~= 'Self' and node.ruleName ~= 'OptChain' then
      error('Arbitrary expressions not allowed as OptChains')
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

function Params(opts)
  opts = opts or {}
  local node = { ruleName = 'Params' }

  local params
  if currentToken ~= '(' and opts.allowImplicitParams then
    params = { { value = Var() } }
  else
    params = Parens({
      demand = true,
      parse = function()
        local node, hasTrailingComma = List({
          allowEmpty = true,
          allowTrailingComma = true,
          parse = function()
            local param = { value = Var() }

            if param and branch('=') then
              param.default = Expr()
            end

            return param
          end,
        })

        if (#node == 0 or hasTrailingComma) and branch('...') then
          table.insert(node, {
            varargs = true,
            value = Try(Name),
          })
        end

        return node
      end,
    })
  end

  for _, param in pairs(params) do
    table.insert(node, param)
  end

  return node
end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

function RepeatUntil()
  expect('repeat')

  local node = {
    ruleName = 'RepeatUntil',
    body = Surround('{', '}', function()
      return Block({ isLoopBlock = true })
    end),
  }

  expect('until')
  node.condition = Expr()

  return node
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

function Return()
  expect('return')

  local node = Parens({
    allowRecursion = true,
    prioritizeRule = true,
    parse = function()
      return List({
        allowEmpty = true,
        allowTrailingComma = true,
        parse = Expr,
      })
    end,
  })

  node.ruleName = 'Return'
  return node
end

-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

function Self()
  local node = { ruleName = 'Self', variant = 'self' }
  expect('$')

  if currentToken then
    if currentToken:match('^[_a-zA-Z][_a-zA-Z0-9]*$') then
      node.variant = 'dotIndex'
      node.value = consume()
    elseif currentToken:match('^[0-9]+$') then
      node.variant = 'numberIndex'
      node.value = consume()
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

function Spread()
  expect('...')
  return { ruleName = 'Spread', value = Expr() }
end

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

function String()
  local node = { ruleName = 'String' }
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
      table.insert(node, Surround('{', '}', Expr))
    else
      table.insert(node, consume())
    end
  end

  consume() -- terminatingToken
  return node
end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

local function parseExprKeyField()
  local field = {
    variant = 'exprKey',
    key = Surround('[', ']', Expr),
  }

  expect('=')
  field.value = Expr()
  return field
end

local function parseNameKeyField()
  local field = {
    variant = 'nameKey',
    key = Name(),
  }

  expect('=')
  field.value = Expr()
  return field
end

local function parseNumberKeyField()
  return { variant = 'numberKey', value = Expr() }
end

local function parseSpreadField()
  return { variant = 'spread', value = Spread() }
end

function Table()
  local node = Surround('{', '}', function()
    return List({
      allowEmpty = true,
      allowTrailingComma = true,
      parse = function()
        return Switch({
          parseExprKeyField,
          parseNameKeyField,
          -- Parse spread before expr, otherwise we will parse the spread as
          -- varargs!
          parseSpreadField,
          parseNumberKeyField,
        })
      end,
    })
  end)

  node.ruleName = 'Table'
  return node
end

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

function TryCatch()
  local node = { ruleName = 'TryCatch' }

  expect('try')
  node.try = Surround('{', '}', Block)

  expect('catch')
  node.errorName = Surround('(', ')', function()
    return Try(Name)
  end)
  node.catch = Surround('{', '}', Block)

  return node
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

function WhileLoop()
  expect('while')

  return {
    ruleName = 'WhileLoop',
    condition = Expr(),
    body = Surround('{', '}', function()
      return Block({ isLoopBlock = true })
    end),
  }
end

-- =============================================================================
-- Parse
-- =============================================================================

local parse, parseMT = {}, {}
setmetatable(parse, parseMT)

parseMT.__call = function(self, text)
  return parse.Block(text)
end

local subParsers = {
  -- Rules
  ArrowFunction = ArrowFunction,
  Assignment = Assignment,
  Block = Block,
  Break = Break,
  Continue = Continue,
  Declaration = Declaration,
  Destructure = Destructure,
  DoBlock = DoBlock,
  Expr = Expr,
  ForLoop = ForLoop,
  Function = Function,
  FunctionCall = FunctionCall,
  Goto = Goto,
  Id = Id,
  IfElse = IfElse,
  OptChain = OptChain,
  Module = Module,
  Params = Params,
  RepeatUntil = RepeatUntil,
  Return = Return,
  Self = Self,
  Spread = Spread,
  String = String,
  Table = Table,
  TryCatch = TryCatch,
  WhileLoop = WhileLoop,

  -- Pseudo-Rules
  Var = Var,
  Name = Name,
  Number = Number,
  Terminal = Terminal,
  FunctionCall = FunctionCall,
  Id = Id,
}

for name, subParser in pairs(subParsers) do
  parse[name] = function(text, ...)
    reset(text)
    return subParser(...)
  end
end

return parse
