local C = require('erde.constants')
local tokenize = require('erde.tokenize')

-- Foward declare rules
local Block, Destructure, Expr, OptChain, Params, Spread, Table, Unop

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local tokens, tokenInfo, newlines
local currentTokenIndex, currentToken

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

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
  end
end

local function expect(token, skipConsume)
  if token ~= currentToken then
    error('Expected ' .. token .. ' got ' .. tostring(currentToken))
  end
  consume()
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

local function Try(rule)
  local currentTokenIndexBackup = currentTokenIndex
  local ok, node = pcall(rule)

  if ok then
    return node
  else
    currentTokenIndex = currentTokenIndexBackup
    currentToken = tokens[currentTokenIndex]
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

-- -----------------------------------------------------------------------------
-- Pseudo Rules
-- -----------------------------------------------------------------------------

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

local function Id()
  local node = OptChain()
  local last = node[#node]

  if last and last.variant == 'functionCall' then
    error('Unexpected function call')
  end

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

local function MapDestructure()
  return Surround('{', '}', function()
    return List({
      allowTrailingComma = true,
      parse = function()
        return {
          name = Name(),
          variant = 'keyDestruct',
          alias = branch(':') and Name(),
          default = branch('=') and Expr(),
        }
      end,
    })
  end)
end

function Destructure()
  local node = { ruleName = 'Destructure' }

  local destructs = currentToken == '[' and ArrayDestructure()
    or MapDestructure()

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
  else
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
    base = OptChainBase(),
  }

  while true do
    local currentTokenIndexBackup = currentTokenIndex
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
      currentTokenIndex = currentTokenIndexBackup
      currentToken = tokens[currentTokenIndex]
      break
    end

    chain.optional = isOptional
    table.insert(node, chain)
  end

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
  local node = { ruleName = 'Params' }

  local params
  if currentToken ~= '(' and opts.allowImplicitParams then
    params = { { value = Var() } }
  else
    params = Parens({ demand = true, parse = ParamsList })
  end

  for _, param in pairs(params) do
    table.insert(node, param)
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

function Spread()
  expect('...')
  return { ruleName = 'Spread', value = Try(Expr) }
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
  local node = Surround('{', '}', function()
    return List({
      allowEmpty = true,
      allowTrailingComma = true,
      parse = TableField,
    })
  end)

  node.ruleName = 'Table'
  return node
end

-- -----------------------------------------------------------------------------
-- Expr
-- -----------------------------------------------------------------------------

local function ArrowFunction()
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

  return node
end

function Expr(minPrec)
  minPrec = minPrec or 1

  local node
  local unop = C.UNOPS[currentToken]

  if unop then
    consume()
    node = {
      ruleName = 'Unop',
      op = unop,
      operand = Expr(unop.prec + 1),
    }
  else
    for _, terminal in pairs(C.TERMINALS) do
      if branch(terminal) then
        node = terminal
      end
    end

    if not node then
      if currentToken:match('^.?[0-9]') then
        -- Only need to check first couple chars, rest is token care of by tokenizer
        node = consume()
      elseif currentToken == "'" or currentToken == '"' or currentToken:match('^%[[[=]') then
        node = { ruleName = 'String' }
        local terminatingToken

        if currentToken == "'" then
          node.variant = 'single'
          terminatingToken = consume()
        elseif currentToken == '"' then
          node.variant = 'double'
          terminatingToken = consume()
        else
          node.variant = 'long'
          node.equals = ('='):rep(#currentToken - 2)
          terminatingToken = ']' .. node.equals .. ']'
          consume()
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
      elseif branch('do') then
        node = {
          ruleName = 'DoBlock',
          isExpr = true,
          body = Surround('{', '}', Block),
        }
      elseif currentToken == '(' then
        -- Also takes care of parenthesized expressions, since OptChain will unpack
        -- any trivial OptChainBase
        node = Switch({ ArrowFunction, OptChain })
      else
        -- Check ArrowFunction before Table for implicit params + destructure
        node = Switch({ ArrowFunction, Table, OptChain })
      end

      if not node then
        error('Unexpected token ' .. currentToken)
      end
    end
  end

  local binop = C.BINOPS[currentToken]
  while binop and binop.prec >= minPrec do
    consume()

    local rhsPrec = binop.prec
    if binop.assoc == C.LEFT_ASSOCIATIVE then
      rhsPrec = rhsPrec + 1
    end

    node = { ruleName = 'Binop', op = binop, lhs = node, rhs = Expr(rhsPrec) }
    binop = C.BINOPS[currentToken]
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local function Assignment()
  local node = {
    ruleName = 'Assignment',
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

  return node
end

local function Function()
  local node = {
    ruleName = 'Function',
    isMethod = false,
  }

  if
    currentToken == 'local'
    or currentToken == 'global'
    or currentToken == 'module'
  then
    node.variant = consume()
  end

  consume() -- 'function'
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

function Block()
  local node = { ruleName = 'Block' }

  repeat
    local statement

    -- micro-optimization: order by usage
    if currentToken == 'local' or currentToken == 'global' or currentToken == 'module' then
      if lookAhead(1) == 'function' then
        statement = Function()
      else
        statement = {
          ruleName = 'Declaration',
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
          statement.exprList = currentToken ~= '(' and List({ parse = Expr })
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
      end
    elseif branch('if') then
      statement = {
        ruleName = 'IfElse',
        ifNode = { condition = Expr(), body = Surround('{', '}', Block) }
      }

      local elseifNodes = {}
      while branch('elseif') do
        table.insert(elseifNodes, {
          condition = Expr(),
          body = Surround('{', '}', Block),
        })
      end
      statement.elseifNodes = elseifNodes

      if branch('else') then
        statement.elseNode = { body = Surround('{', '}', Block) }
      end
    elseif branch('return') then
      statement = currentToken ~= '('
        and List({ parse = Expr, allowEmpty = true })
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
      statement.ruleName = 'Return'
    elseif currentToken == 'function' then
      statement = Function()
    elseif branch('for') then
      statement = { ruleName = 'ForLoop' }
      local firstName = Var()

      if type(firstName) == 'string' and branch('=') then
        statement.variant = 'numeric'
        statement.name = firstName
        statement.parts = List({ parse = Expr })
      else
        statement.variant = 'generic'
        local varList = { firstName }

        while branch(',') do
          table.insert(varList, Var())
        end

        statement.varList = varList
        expect('in')
        statement.exprList = List({ parse = Expr })
      end

      statement.body = Surround('{', '}', Block)
    elseif branch('while') then
      statement = {
        ruleName = 'WhileLoop',
        condition = Expr(),
        body = Surround('{', '}', Block),
      }
    elseif branch('do') then
      statement = { ruleName = 'DoBlock', body = Surround('{', '}', Block) }
    elseif branch('break') then
      statement = { ruleName = 'Break' }
    elseif branch('continue') then
      statement = { ruleName = 'Continue' }
    elseif branch('repeat') then
      statement = { ruleName = 'RepeatUntil', body = Surround('{', '}', Block) }
      expect('until')
      statement.condition = Expr()
    elseif branch('try') then
      statement = { ruleName = 'TryCatch', try = Surround('{', '}', Block) }
      expect('catch')
      statement.error = Try(Var)
      statement.catch = Surround('{', '}', Block)
    elseif branch('goto') then
      statement = { ruleName = 'Goto', name = Name() }
    elseif branch('::') then
      statement = { ruleName = 'GotoLabel', name = Name() }
      expect('::')
    else
      statement = Switch({ FunctionCall, Assignment })
    end

    table.insert(node, statement)
  until not statement

  return node
end

-- =============================================================================
-- Return
-- =============================================================================

return function(text)
  local ast = {}

  tokens, tokenInfo, newlines = tokenize(text)
  currentTokenIndex = 1
  currentToken = tokens[1]

  -- Check for empty file or file w/ only comments
  if currentToken == nil then
    return nil
  end

  local shebang
  if currentToken:match('^#!') then
    shebang = consume()
  end

  local ast = Block()
  ast.shebang = shebang

  return ast
end
