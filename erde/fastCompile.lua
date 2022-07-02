local C = require('erde.constants')
local tokenize = require('erde.tokenize')
local luaTarget = require('erde.luaTarget')

-- Foward declare
local Expr, Block

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local tokens, tokenInfo, newlines
local currentTokenIndex, currentToken

local blockDepth

local tmpNameCounter

-- Keeps track of the closest loop block ancestor. This is used to validate
-- Break / Continue nodes, as well as register nested Continue nodes.
local breakName, hasContinue

-- Table for Declaration and Function to register `module` scope variables.
local moduleNames

-- Keeps track of whether the module has a `return` statement. Used to warn the
-- developer if they try to combine `return` with `module` scopes.
local isModuleReturnBlock, hasModuleReturn

-- -----------------------------------------------------------------------------
-- Parse Helpers
-- -----------------------------------------------------------------------------

local function consume()
  local consumedToken = tokens[currentTokenIndex]
  currentTokenIndex = currentTokenIndex + 1
  currentToken = tokens[currentTokenIndex]
  return consumedToken
end

local function branch(token)
  if token == currentToken then
    consume()
    return true
  end
end

local function expect(token)
  assert(token == currentToken, 'Expected ' .. token .. ' got ' .. tostring(currentToken))
  return consume()
end

local function lookAhead(n)
  return tokens[currentTokenIndex + n]
end

-- -----------------------------------------------------------------------------
-- Compile Helpers
-- -----------------------------------------------------------------------------

local function newTmpName()
  tmpNameCounter = tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(tmpNameCounter)
end

local function compileBinop(opToken, lhs, rhs)
  if opToken == '!=' then
    return table.concat({ lhs, ' ~= ', rhs })
  elseif opToken == '||' then
    return table.concat({ lhs, ' or ', rhs })
  elseif opToken == '&&' then
    return table.concat({ lhs, ' and ', rhs })
  elseif opToken == '|' then
    return ('require("bit").bor(%s, %s)'):format(lhs, rhs)
  elseif opToken == '~' then
    return ('require("bit").bxor(%s, %s)'):format(lhs, rhs)
  elseif opToken == '&' then
    return ('require("bit").band(%s, %s)'):format(lhs, rhs)
  elseif opToken == '<<' then
    return ('require("bit").lshift(%s, %s)'):format(lhs, rhs)
  elseif opToken == '>>' then
    return ('require("bit").rshift(%s, %s)'):format(lhs, rhs)
  else
    return table.concat({ lhs, opToken, rhs }, ' ')
  end
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

local function Try(callback)
  local currentTokenIndexBackup = currentTokenIndex

  local ok, result = pcall(callback)
  if ok then return result, ok end

  currentTokenIndex = currentTokenIndexBackup
  currentToken = tokens[currentTokenIndex]
end

local function Surround(openChar, closeChar, include, callback)
  expect(openChar)
  local result = callback()
  expect(closeChar)
  return include and openChar .. result .. closeChar or result
end

local function Parens(allowRecursion, include, callback)
  return Surround('(', ')', include, function()
    -- Try callback first before recursing, in case the callback itself needs to
    -- consume parentheses! For example, an iife.
    local result, ok = Try(callback)
    if ok then return result end
    return (allowRecursion and currentToken == '(') 
      and Parens(true, include, callback) or callback()
  end)
end

local function List(allowEmpty, allowTrailingComma, callback)
  local list = {}
  local hasTrailingComma = false

  -- Explicitly count numItems in case callback doesn't actually return items.
  local numItems = 0

  repeat
    local result, ok = Try(callback)
    if not ok then break end
    hasTrailingComma = branch(',')
    numItems = numItems + 1
    list[numItems] = result
  until not hasTrailingComma

  assert(allowEmpty or numItems > 0)
  assert(allowTrailingComma or not hasTrailingComma)

  return list
end

-- -----------------------------------------------------------------------------
-- Partials
-- -----------------------------------------------------------------------------

local function Name(allowKeywords)
  assert(
    currentToken:match('^[_a-zA-Z][_a-zA-Z0-9]*$'),
    'Malformed name: ' .. currentToken
  )

  if not allowKeywords then
    for i, keyword in pairs(C.KEYWORDS) do
      assert(currentToken ~= keyword, 'Unexpected keyword: ' .. currentToken)
    end
  end

  return consume()
end

local function Destructure()
  local varName = newTmpName()
  local nameList = {}
  local assignments = {}

  if currentToken == '[' then
    local arrayIndex = 0
    Surround('[', ']', false, function()
      List(false, true, function()
        local name = Name()
        arrayIndex = arrayIndex + 1

        table.insert(nameList, name)
        table.insert(assignments, ('%s = %s[%s]'):format(name, varName, arrayIndex))

        if branch('=') then
          table.insert(
            assignments,
            ('if %s == nil then %s = %s end'):format(name, name, Expr())
          )
        end
      end)
    end)
  else
    Surround('{', '}', false, function()
      List(false, true, function()
        local key = Name()
        local name = branch(':') and Name() or key

        table.insert(nameList, name)
        table.insert(assignments, ('%s = %s.%s'):format(name, varName, key))

        if branch('=') then
          table.insert(
            assignments,
            ('if %s == nil then %s = %s end'):format(name, name, Expr())
          )
        end
      end)
    end)
  end

  return {
    name = varName,
    compiled = table.concat({
      'local ' .. table.concat(nameList, ','),
      table.concat(assignments, '\n'),
    }, '\n')
  }
end

local function Var()
  return (currentToken == '{' or currentToken == '[')
    and Destructure() or Name()
end

local function Params()
  local names = {}
  local preBody = {}

  Parens(false, false, function()
    List(true, true, function()
      local var = Var()

      local name = type(var) == 'string' and var or var.name
      table.insert(names, name)

      if branch('=') then
        table.insert(preBody, table.concat({
          'if ' .. name .. ' == nil then',
          name .. ' = ' .. Expr(),
          'end',
        }, '\n'))
      end

      if type(var) == 'table' then
        table.insert(preBody, var.compiled)
      end
    end)

    if branch('...') then
      table.insert(names, '...')
      local varargsName = Try(Name)
      if varargsName then
        table.insert(preBody, 'local ' .. varargsName .. ' = { ... }')
      end
    end
  end)

  return {
    names = names,
    preBody = table.concat(preBody, '\n'),
  }
end

local function FunctionBlock()
  local oldIsInModuleReturnBlock = isModuleReturnBlock
  local oldBreakName = breakName

  isModuleReturnBlock = false
  breakName = nil

  local block = Surround('{', '}', false, Block)

  isModuleReturnBlock = oldIsModuleReturnBlock
  breakName = oldBreakName
  return block
end

local function LoopBlock()
  local oldBreakName = breakName
  local oldHasContinue = hasContinue

  breakName = newTmpName()
  hasContinue = false

  local block = Surround('{', '}', false, function()
    return Block(true)
  end)

  breakName = oldBreakName
  hasContinue = oldHasContinue
  return block
end

-- -----------------------------------------------------------------------------
-- Expressions
-- -----------------------------------------------------------------------------

local function ArrowFunction()
  local paramNames = {}
  local body = {}

  if currentToken == '(' then
    local params = Params()
    paramNames = params.names
    table.insert(body, params.preBody)
  else
    local var = Var()
    if type(var) == 'string' then
      table.insert(paramNames, var)
    else
      table.insert(paramNames, var.name)
      table.insert(body, var.compiled)
    end
  end

  if consume() == '=>' then
    table.insert(paramNames, 1, 'self')
  end

  if currentToken == '{' then
    table.insert(body, FunctionBlock())
  elseif currentToken == '(' then
    table.insert(body, 'return ' .. Parens(true, false, function()
      return table.concat(List(false, true, Expr), ',')
    end))
  else
    table.insert(body, 'return ' .. Expr())
  end

  return table.concat({
    'function(' .. table.concat(paramNames, ',') .. ')',
    table.concat(body, '\n'),
    'end',
  }, '\n')
end

local function IndexChain(allowArbitraryExpr)
  local hasExprBase = currentToken == '('
  local indexChainBase = hasExprBase and Parens(true, true, Expr) or Name()
  local indexChain = indexChainBase
  local nextIndex = ''

  while nextIndex do
    indexChain = indexChain .. nextIndex
    nextIndex = nil

    if branch('.') then
      nextIndex = '.' .. Name(true)
    elseif currentToken == '[' then
      -- Add space around brackets to handle long string expressions
      -- [ [=[some string]=] ]
      nextIndex = '[ ' .. Surround('[', ']', false, Expr) .. ' ]'
    elseif branch(':') then
      nextIndex = ':' .. Name(true)
      if currentToken ~= '(' then
        error('Missing parentheses for method call')
      end
    elseif currentToken == '(' then
      -- TODO: semicolon
      nextIndex = Parens(false, true, function()
        return table.concat(List(true, true, Expr), ',')
      end)
    end
  end

  if hasExprBase and not allowArbitraryExpr and indexChain == indexChainBase then
    error('Require id')
  end

  return indexChain
end

local function InterpolationString(startQuote, endQuote)
  local interpolationString = startQuote

  while currentToken ~= endQuote do
    if currentToken ~= '{' then
      interpolationString = interpolationString .. consume()
    else
      interpolationString = interpolationString .. table.concat({
        endQuote,
        'tostring(' .. Surround('{', '}', false, Expr) .. ')',
        startQuote,
      }, '..')
    end
  end

  return interpolationString .. consume()
end

local function Table()
  return Surround('{', '}', true, function()
    return table.concat(List(true, true, function()
      if currentToken == '[' then
        -- Add space around brackets to handle long string expressions
        -- [ [=[some string]=] ]
        return '[ ' .. Surround('[', ']', false, Expr) .. ' ]' .. expect('=') .. Expr()
      end

      local expr = Expr()
      return (branch('=') and expr:match('^[_a-zA-Z][_a-zA-Z0-9]*$'))
        and expr .. ' = ' .. Expr() or expr
    end), ',')
  end)
end

local function Terminal()
  for _, terminal in pairs(C.TERMINALS) do
    if branch(terminal) then
      return terminal
    end
  end

  if currentToken:match('^.?[0-9]') then
    -- Only need to check first couple chars, rest is token care of by tokenizer
    return consume()
  elseif currentToken == "'" then
    return consume() .. consume() .. consume()
  elseif branch('"') then
    return InterpolationString('"', '"')
  elseif currentToken:match('^%[[[=]') then
    local startQuote = consume()
    return InterpolationString(startQuote, startQuote:gsub('%[', ']'))
  end

  local nextToken = lookAhead(1)
  local isArrowFunction = nextToken == '->' or nextToken == '=>'
  local surroundEnd = currentToken == '(' and ')'
    or currentToken == '[' and ']'
    or currentToken == '{' and '}'
    or nil

  -- First do a quick check for isArrowFunction (in case of implicit params),
  -- otherwise if surroundEnd is truthy (possible params), need to check the 
  -- next token after. This is _much_ faster than backtracking.
  if not isArrowFunction and surroundEnd then
    local surroundStart = currentToken
    local surroundDepth = 0

    local tokenIndex = currentTokenIndex + 1
    local token = tokens[tokenIndex]

    while token ~= surroundEnd or surroundDepth > 0 do
      if token == nil then
        error('Unexpected EOF')
      elseif token == surroundStart then
        surroundDepth = surroundDepth + 1
      elseif token == surroundEnd then
        surroundDepth = surroundDepth - 1
      end

      tokenIndex = tokenIndex + 1
      token = tokens[tokenIndex]
    end

    -- Check one past surrounds for arrow
    tokenIndex = tokenIndex + 1
    token = tokens[tokenIndex]
    isArrowFunction = token == '->' or token == '=>'
  end

  if isArrowFunction then
    return ArrowFunction()
  elseif currentToken == '{' then
    return Table()
  else
    return IndexChain(true)
  end
end

local function Unop()
  local unop = C.UNOPS[consume()]
  local operand = Expr(unop.prec + 1)

  if unop.token == '~' then
    return 'require("bit").bnot(' .. operand .. ')'
  elseif unop.token == '!' then
    return 'not ' .. operand
  else
    return unop.token .. operand
  end
end

function Expr(minPrec)
  minPrec = minPrec or 1

  local expr = C.UNOPS[currentToken] and Unop() or Terminal()
  local binop = C.BINOPS[currentToken]

  while binop and binop.prec >= minPrec do
    consume()

    local rhsMinPrec = binop.prec
    if binop.assoc == C.LEFT_ASSOCIATIVE then
      rhsMinPrec = rhsMinPrec + 1
    end

    if C.BITOPS[binop.token] and C.INVALID_BITOP_LUA_TARGETS[luaTarget.current] then
      error(table.concat({
        'Cannot use bitwise operators for Lua target',
        luaTarget.current,
        'due to invcompatabilities between bitwise operators across Lua versions.', 
      }, ' '))
    end

    expr = compileBinop(binop.token, expr, Expr(rhsMinPrec))
    binop = C.BINOPS[currentToken]
  end

  return expr
end

-- -----------------------------------------------------------------------------
-- Statements
-- -----------------------------------------------------------------------------

local function Assignment(firstId)
  local idList = { firstId }

  if branch(',') then
    List(false, false, function()
      local indexChain = IndexChain()
      assert(indexChain:sub(-1) ~= ')')
      table.insert(idList, indexChain)
    end)
  end

  local opToken = C.BINOPS[currentToken] and consume()
  if opToken and C.BINOP_ASSIGNMENT_BLACKLIST[opToken] then
    error('Invalid assignment operator: ' .. currentToken)
  end

  expect('=')
  local exprList = List(false, false, Expr)

  if not opToken then
    return table.concat(idList, ',') .. ' = ' .. table.concat(exprList, ',')
  elseif #idList == 1 and #exprList == 1 then
    -- Optimize most common use case
    return firstId .. ' = ' .. firstId .. ' + ' .. exprList[1]
  else
    local binopAssignments = {}
    local assignmentNames = {}

    for i, id in ipairs(idList) do
      local assignmentName = newTmpName()
      table.insert(assignmentNames, assignmentName)
      table.insert(binopAssignments, id .. ' = ' .. compileBinop(opToken, id, assignmentName))
    end

    return table.concat({
      'local ' .. table.concat(assignmentNames, ',') .. ' = ' .. table.concat(exprList, ','),
      table.concat(binopAssignments, '\n'),
    }, '\n')
  end
end

local function Declaration(scope)
  local declaration = {}
  local destructures = {}
  local varList = List(false, false, Var)

  if blockDepth > 1 and scope == 'module' then
    error('module declarations must appear at the top level')
  end

  if scope == 'local' or scope == 'module' then
    table.insert(declaration, 'local')
  end

  do
    local nameList = {}

    for i, var in ipairs(varList) do
      if type(var) == 'string' then
        table.insert(nameList, var)
      else
        table.insert(nameList, var.name)
        table.insert(destructures, var.compiled)
      end
    end

    if scope == 'module' then
      for _, name in ipairs(nameList) do
        table.insert(moduleNames, name)
      end
    end

    table.insert(declaration, table.concat(nameList, ','))
  end

  if branch('=') then
    table.insert(declaration, '=')
    table.insert(declaration, table.concat(List(false, false, Expr), ','))
  end

  return table.concat({
    table.concat(declaration, ' '),
    table.concat(destructures, '\n'),
  }, '\n')
end

local function ForLoop()
  local compiled = {}

  if lookAhead(1) == '=' then
    local name = Name()
    consume() -- '='

    local exprList = List(false, false, Expr)
    local exprListLen = #exprList

    if exprListLen < 2 then
      error('Invalid for loop parameters (missing parameters)')
    elseif exprListLen > 3 then
      error('Invalid for loop parameters (too many parameters)')
    end

    table.insert(compiled, 'for ' .. name .. ' = ' .. table.concat(exprList, ',') .. ' do')
  else
    local nameList = {}
    local preBody = {}

    for i, var in ipairs(List(false, false, Var)) do
      if type(var) == 'string' then
        table.insert(nameList, var)
      else
        table.insert(nameList, var.name)
        table.insert(preBody, var.compiled)
      end
    end

    table.insert(compiled, table.concat({
      'for',
      table.concat(nameList, ','),
      expect('in'),
      -- Generic for parses an expression list!
      -- see https://www.lua.org/pil/7.2.html
      -- TODO: only allow max 3 expressions? Job for linter?
      table.concat(List(false, false, Expr), ','),
      'do',
    }, ' '))

    table.insert(compiled, table.concat(preBody, '\n'))
  end

  table.insert(compiled, LoopBlock())
  table.insert(compiled, 'end')
  return table.concat(compiled, '\n')
end

-- TODO: throw error on 'local' scope used with table values?? seems to be
-- behavior in Lua
local function Function(scope)
  local signature = Name()
  local isTableValue = currentToken == '.'

  while branch('.') do
    signature = signature .. '.' .. Name()
  end

  if branch(':') then
    isTableValue = true
    signature = signature .. ':' .. Name()
  end

  if scope and isTableValue then
    error('Cannot use scope keyword for table values')
  end

  if scope == 'module' then
    if blockDepth > 1 then
      error('module declarations must appear at the top level')
    end
    table.insert(moduleNames, signature)
  end

  local params = Params()

  return table.concat({
    table.concat({
      -- Default functions to local scope _unless_ they are part of a table.
      scope and (scope == 'global' and '' or 'local') or (isTableValue and '' or 'local'),
      'function',
      signature .. '(' .. table.concat(params.names, ',') .. ')',
    }, ' '),
    params.preBody,
    FunctionBlock(),
    'end',
  }, '\n')
end

local function IfElse()
  local compiled = {
    'if ' .. Expr() .. ' then',
    Surround('{', '}', false, Block),
  }

  while branch('elseif') do
    table.insert(compiled, 'elseif ' .. Expr() .. ' then')
    table.insert(compiled, Surround('{', '}', false, Block))
  end

  if branch('else') then
    table.insert(compiled, 'else')
    table.insert(compiled, Surround('{', '}', false, Block))
  end

  table.insert(compiled, 'end')
  return table.concat(compiled, '\n')
end

local function Return()
  local firstReturn = Try(Expr)
  if firstReturn then
    return branch(',')
      and 'return ' .. firstReturn .. ',' .. List(false, false, Expr)
      or 'return ' .. firstReturn
  elseif currentToken == '(' then
    return 'return ' .. table.concat(Parens(true, false, function()
      return List(false, true, Expr)
    end), ',')
  else
    return 'return'
  end
end

local function TryCatch()
  local okName = newTmpName()
  local errorName = newTmpName()

  local compiled = {
    ('local %s, %s = pcall(function() %s end)'):format(
      okName,
      errorName,
      Surround('{', '}', false, Block)
    ),
    'if ' .. okName .. ' == false then',
  }

  expect('catch')
  local errorVar = Try(Var)

  if errorVar then
    if type(errorVar) == 'string' then
      table.insert(compiled, 'local ' .. errorVar .. ' = ' .. errorName)
    else
      table.insert(compiled, ('local ' .. errorVar.name .. ' = ' .. errorName))
      table.insert(compiled, errorVar.compiled)
    end
  end

  table.insert(compiled, Surround('{', '}', false, Block))
  table.insert(compiled, 'end')
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block(isLoopBlock)
  local statements = {}
  blockDepth = blockDepth + 1

  repeat
    local statement

    if branch('break') then
      assert(breakName ~= nil, 'Cannot use `break` outside of loop')
      statement = 'break'
    elseif branch('continue') then
      assert(breakName ~= nil, 'Cannot use `continue` outside of loop')
      hasContinue = true
      -- TODO: compile GOTO `continue` version when possible
      -- return 'goto ' .. gotoLabel
      statement = breakName .. ' = true break'
    elseif branch('goto') then
      statement = 'goto ' .. Name()
    elseif branch('::') then
      statement = '::' .. Name() .. expect('::')
    elseif branch('do') then
      statement = 'do ' .. Surround('{', '}', false, Block) .. ' end'
    elseif branch('if') then
      statement = IfElse()
    elseif branch('for') then
      statement = ForLoop()
    elseif branch('while') then
      statement = 'while ' .. Expr() .. ' do ' .. LoopBlock() .. ' end'
    elseif branch('repeat') then
      statement = table.concat({ 'repeat', LoopBlock(), expect('until'), Expr() }, ' ')
    elseif branch('try') then
      statement = TryCatch()
    elseif branch('return') then
      if isModuleReturnBlock then hasModuleReturn = true end
      statement = Return()
    elseif branch('function') then
      statement = Function()
    elseif currentToken == 'local' or currentToken == 'global' or currentToken == 'module' then
      local scope = consume()
      statement = branch('function') and Function(scope) or Declaration(scope)
    else
      local indexChain = Try(IndexChain)
      if indexChain then
        -- Allow function calls as standalone statements
        statement = indexChain:sub(-1) == ')' and indexChain or Assignment(indexChain)
      end
    end

    table.insert(statements, statement)
  until not statement

  blockDepth = blockDepth - 1

  if isLoopBlock and breakName and hasContinue then
    -- TODO: compile GOTO `continue` version when possible
    return table.concat({
      'local ' .. breakName .. ' = false',
      'repeat',
      table.concat(statements, '\n'),
      breakName .. ' = true',
      'until true',
      'if not ' .. breakName .. ' then break end',
    }, '\n')
  else
    return table.concat(statements, '\n')
  end
end

-- -----------------------------------------------------------------------------
-- Main
-- -----------------------------------------------------------------------------

return function(text)
  tokens, tokenInfo, newlines = tokenize(text)
  currentTokenIndex = 1
  currentToken = tokens[1]

  blockDepth = 0
  isModuleReturnBlock = true
  hasModuleReturn = false
  hasContinue = false
  tmpNameCounter = 1
  moduleNames = {}

  -- Check for empty file or file w/ only comments
  if currentToken == nil then
    return nil
  end

  local module = {}

  if currentToken:match('^#!') then
    table.insert(module, consume())
  end

  table.insert(module, C.COMPILED_HEADER_COMMENT)
  table.insert(module, Block())

  if #moduleNames > 0 then
    if hasModuleReturn then
      error('Cannot use both `return` and `module` together.')
    else
      local moduleTableElements = {}

      for i, moduleName in ipairs(moduleNames) do
        moduleTableElements[i] = moduleName .. '=' .. moduleName
      end

      table.insert(module, 'return { ' .. table.concat(moduleTableElements, ',') .. ' }')
    end
  end

  return table.concat(module, '\n')
end
