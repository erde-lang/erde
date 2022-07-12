local C = require('erde.constants')
local tokenize = require('erde.tokenize')
local luaTarget = require('erde.luaTarget')

-- Foward declare
local Expr, Block

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local tokens, tokenLines
local currentTokenIndex, currentToken, currentTokenLine

-- Current block depth during parsing
local blockDepth = 0

-- Counter for generating unique names in compiled code.
local tmpNameCounter

-- Break name to use for `continue` statements. This is also used to validate
-- the context of `break` and `continue`.
local breakName

-- Flag to keep track of whether the current block has any `continue` statements.
local hasContinue

-- Table for Declaration and Function to register `module` scope variables.
local moduleNames

-- Keeps track of whether the module has a `return` statement. Used to warn the
-- developer if they try to combine `return` with `module` scopes.
local isModuleReturnBlock, hasModuleReturn

-- -----------------------------------------------------------------------------
-- General Helpers
-- -----------------------------------------------------------------------------

local unpack = table.unpack or unpack
local concat = table.concat
local insert = table.insert

local function weave(t, separator)
  separator = separator or ','

  local woven = {}
  local tLen = #t

  for i = 1, tLen - 1 do
    insert(woven, t[i])
    insert(woven, separator)
  end

  insert(woven, t[tLen])
  return woven
end

-- -----------------------------------------------------------------------------
-- Parse Helpers
-- -----------------------------------------------------------------------------

local function consume()
  local consumedToken = currentToken
  currentTokenIndex = currentTokenIndex + 1
  currentToken = tokens[currentTokenIndex]
  currentTokenLine = tokenLines[currentTokenIndex]
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

local function compileBinop(opToken, opLine, lhs, rhs)
  if opToken == '!=' then
    return { lhs, opLine, '~=', rhs }
  elseif opToken == '||' then
    return { lhs, opLine, 'or', rhs }
  elseif opToken == '&&' then
    return { lhs, opLine, 'and', rhs }
  elseif opToken == '|' then
    return { opLine, 'require("bit").bor(', lhs, opLine, ',', rhs, opLine, ')' }
  elseif opToken == '~' then
    return { opLine, 'require("bit").bxor(', lhs, opLine, ',', rhs, opLine, ')' }
  elseif opToken == '&' then
    return { opLine, 'require("bit").band(', lhs, opLine, ',', rhs, opLine, ')' }
  elseif opToken == '<<' then
    return { opLine, 'require("bit").lshift(', lhs, opLine, ',', rhs, opLine, ')' }
  elseif opToken == '>>' then
    return { opLine, 'require("bit").rshift(', lhs, opLine, ',', rhs, opLine, ')' }
  else
    return { lhs, opLine, opToken, rhs }
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
  return include and { openChar, result, closeChar } or result
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
  local compileLines = {}
  local varName = newTmpName()

  if currentToken == '[' then
    local arrayIndex = 0
    Surround('[', ']', false, function()
      List(false, true, function()
        local nameLine, name = currentTokenLine, Name()
        arrayIndex = arrayIndex + 1

        insert(compileLines, nameLine)
        insert(compileLines, ('local %s = %s[%s]'):format(name, varName, arrayIndex))

        if branch('=') then
          insert(compileLines, ('if %s == nil then %s = '):format(name, name))
          insert(compileLines, Expr())
          insert(compileLines, 'end')
        end
      end)
    end)
  else
    Surround('{', '}', false, function()
      List(false, true, function()
        local keyLine, key = currentTokenLine, Name()
        local name = branch(':') and Name() or key

        insert(compileLines, keyLine)
        insert(compileLines, ('local %s = %s.%s'):format(name, varName, key))

        if branch('=') then
          insert(compileLines, ('if %s == nil then %s = '):format(name, name))
          insert(compileLines, Expr())
          insert(compileLines, 'end')
        end
      end)
    end)
  end

  return { name = varName, compileLines = compileLines }
end

local function Var()
  return (currentToken == '{' or currentToken == '[')
    and Destructure() or Name()
end

local function Params()
  local compileLines = {}
  local names = {}

  Parens(false, false, function()
    List(true, true, function()
      local varLine, var = currentTokenLine, Var()

      local name = type(var) == 'string' and var or var.name
      insert(names, name)

      if branch('=') then
        insert(compileLines, ('if %s == nil then %s = '):format(name, name))
        insert(compileLines, Expr())
        insert(compileLines, 'end')
      end

      if type(var) == 'table' then
        insert(compileLines, var.compileLines)
      end
    end)

    if branch('...') then
      insert(names, '...')
      local varargsName = Try(Name)
      if varargsName then
        insert(compileLines, 'local ' .. varargsName .. ' = { ... }')
      end
    end
  end)

  return { names = names, compileLines = compileLines }
end

local function FunctionBlock()
  local oldIsInModuleReturnBlock = isModuleReturnBlock
  local oldBreakName = breakName

  isModuleReturnBlock = false
  breakName = nil

  local compileLines = Surround('{', '}', false, Block)

  isModuleReturnBlock = oldIsModuleReturnBlock
  breakName = oldBreakName
  return compileLines
end

local function LoopBlock()
  local oldBreakName = breakName
  local oldHasContinue = hasContinue

  breakName = newTmpName()
  hasContinue = false

  local compileLines = Surround('{', '}', false, function()
    return Block(true)
  end)

  breakName = oldBreakName
  hasContinue = oldHasContinue
  return compileLines
end

-- -----------------------------------------------------------------------------
-- Expressions
-- -----------------------------------------------------------------------------

local function ArrowFunction()
  local compileLines = {}
  local paramNames = {}

  if currentToken == '(' then
    local params = Params()
    paramNames = params.names
    insert(compileLines, params.compileLines)
  else
    local var = Var()
    if type(var) == 'string' then
      insert(paramNames, var)
    else
      insert(paramNames, var.name)
      insert(compileLines, var.compileLines)
    end
  end

  if consume() == '=>' then
    insert(paramNames, 1, 'self')
  end

  insert(compileLines, 1, 'function(' .. concat(paramNames, ',') .. ')')

  if currentToken == '{' then
    insert(compileLines, FunctionBlock())
  elseif currentToken == '(' then
    insert(compileLines, 'return')
    insert(compileLines, Parens(true, false, function()
      return weave(List(false, true, Expr))
    end))
  else
    insert(compileLines, 'return')
    insert(compileLines, Expr())
  end

  insert(compileLines, 'end')
  return compileLines
end

local function IndexChain(allowArbitraryExpr)
  local compileLines = {}
  local isTrivialChain = true

  local hasExprBase = currentToken == '('
  insert(compileLines, hasExprBase and Parens(true, true, Expr) or Name())

  while true do
    if currentToken == '.' then
      insert(compileLines, currentTokenLine)
      insert(compileLines, consume() .. Name(true))
    elseif currentToken == '[' then
      insert(compileLines, '[')
      insert(compileLines, Surround('[', ']', false, Expr))
      insert(compileLines, ']')
    elseif branch(':') then
      insert(compileLines, ':' .. Name(true))
      if currentToken ~= '(' then
        error('Missing parentheses for method call')
      end
    elseif currentToken == '(' then
      -- TODO: semicolon
      -- Include function call parens on same line as function name to prevent
      -- parsing errors in Lua5.1: 
      --    `ambiguous syntax (function call x new statement) near '('`
      compileLines[#compileLines] = compileLines[#compileLines] .. '('
      insert(compileLines, Parens(false, false, function()
        return weave(List(true, true, Expr))
      end))
      insert(compileLines, ')')
    else
      break
    end

    isTrivialChain = false
  end

  if hasExprBase and not allowArbitraryExpr and isTrivialChain then
    error('Require id')
  end

  return compileLines
end

local function InterpolationString(startQuote, endQuote)
  local compileLines = {}
  local contentLine, content = currentTokenLine, consume()

  if currentToken == endQuote then
    -- Handle empty string case exceptionally so we can make assumptions at the
    -- end to simplify excluding empty string concatenations.
    insert(compileLines, content .. consume())
    return compileLines
  end

  repeat
    if currentToken == '{' then
      if content ~= startQuote then -- only if nonempty
        insert(compileLines, contentLine)
        insert(compileLines, content .. endQuote)
      end

      insert(compileLines, {
        'tostring(',
        Surround('{', '}', false, Expr),
        ')',
      })

      contentLine, content = currentTokenLine, startQuote
    else
      content = content .. consume()
    end
  until currentToken == endQuote

  if content ~= startQuote then -- only if nonempty
    insert(compileLines, contentLine)
    insert(compileLines, content .. endQuote)
  end

  consume() -- endQuote
  return weave(compileLines, '..')
end

local function Table()
  local compileLines = {}

  return Surround('{', '}', true, function()
    List(true, true, function()
      if currentToken == '[' then
        insert(compileLines, '[')
        insert(compileLines, Surround('[', ']', false, Expr))
        insert(compileLines, ']')
        insert(compileLines, '=')
      elseif lookAhead(1) == '=' then
        insert(compileLines, Name())
        insert(compileLines, consume()) -- '='
      end

      insert(compileLines, Expr())
    end)

    return weave(compileLines)
  end)
end

local function Terminal()
  for _, terminal in pairs(C.TERMINALS) do
    if currentToken == terminal then
      return { currentTokenLine, consume() }
    end
  end

  if currentToken:match('^.?[0-9]') then
    -- Only need to check first couple chars, rest is token care of by tokenizer
    return { currentTokenLine, consume() }
  elseif currentToken == "'" then
    return { currentTokenLine, consume() .. consume() .. consume() }
  elseif currentToken == '"' then
    return InterpolationString('"', '"')
  elseif currentToken:match('^%[[[=]') then
    return InterpolationString(currentToken, currentToken:gsub('%[', ']'))
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
  local compileLines  = {}
  local unopLine, unop = currentTokenLine, C.UNOPS[consume()]
  local operandLine, operand = currentTokenLine, Expr(unop.prec + 1)

  if unop.token == '~' then
    return { unopLine, 'require("bit").bnot(', operandLine, operand, unopLine, ')' }
  elseif unop.token == '!' then
    return { unopLine, 'not', operandLine, operand }
  else
    return { unopLine, unop.token, operandLine, operand }
  end
end

function Expr(minPrec)
  minPrec = minPrec or 1

  local compileLines = C.UNOPS[currentToken] and Unop() or Terminal()
  local binop = C.BINOPS[currentToken]

  while binop and binop.prec >= minPrec do
    local binopLine = currentTokenLine
    consume()

    local rhsMinPrec = binop.prec
    if binop.assoc == C.LEFT_ASSOCIATIVE then
      rhsMinPrec = rhsMinPrec + 1
    end

    if C.BITOPS[binop.token] and C.INVALID_BITOP_LUA_TARGETS[luaTarget.current] then
      -- TODO: fatal
      error(table.concat({
        'Cannot use bitwise operators for Lua target',
        luaTarget.current,
        'due to invcompatabilities between bitwise operators across Lua versions.', 
      }, ' '))
    end

    compileLines = compileBinop(binop.token, binopLine, compileLines, Expr(rhsMinPrec))
    binop = C.BINOPS[currentToken]
  end

  return compileLines
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
  -- TODO: move scope logic here
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
  commit(consume())

  if lookAhead(1) == '=' then
    commit(Name() .. consume())

    local exprList = List(false, false, Expr)
    local exprListLen = #exprList

    if exprListLen < 2 then
      error('Invalid for loop parameters (missing parameters)')
    elseif exprListLen > 3 then
      error('Invalid for loop parameters (too many parameters)')
    end

    commit(exprList)
  else
    local nameList = {}
    local preBody = {}

    for i, var in ipairs(List(false, false, Var)) do
      if type(var) == 'string' then
        commit(var)
      else
        commit(var.name)
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

  commit(nil, 'do')
  LoopBlock()
  commit(nil, 'end')
end

-- TODO: throw error on 'local' scope used with table values?? seems to be
-- behavior in Lua
local function Function(scope)
  -- TODO: move scope logic here
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
  commit(consume())
  Expr()
  commit('then')
  Surround('{', '}', false, Block)

  while currentToken == 'elseif' do
    commit(consume())
    commit(Expr())
    commit('then')
    Surround('{', '}', false, Block)
  end

  if currentToken == 'else' then
    commit(consume())
    Surround('{', '}', false, Block)
  end

  commit('end')
end

local function Return()
  local firstReturn = Try(Expr)
  if firstReturn then
    return branch(',')
      and 'return ' .. firstReturn .. ',' .. concat(List(false, false, Expr), ',')
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
  local compileLines = {}
  local blockStartLine = currentTokenLine
  blockDepth = blockDepth + 1

  while true do
    if currentToken == 'break' then
      -- TODO: use currentTokenLine in error
      assert(breakName ~= nil, 'Cannot use `break` outside of loop')
      insert(compileLines, currentTokenLine)
      insert(compileLines, consume())
    elseif branch('continue') then
      -- TODO: use currentTokenLine in error
      assert(breakName ~= nil, 'Cannot use `continue` outside of loop')
      hasContinue = true
      insert(compileLines, breakName .. ' = true break')
    elseif currentToken == 'goto' then
      -- TODO: check luaTarget
      insert(compileLines, currentTokenLine)
      insert(compileLines, consume())
      insert(compileLines, currentTokenLine)
      insert(compileLines, Name())
    elseif currentToken == '::' then
      -- TODO: check luaTarget
      insert(compileLines, currentTokenLine)
      insert(compileLines, consume() .. Name() .. expect('::'))
    elseif currentToken == 'do' then
      insert(compileLines, consume())
      insert(compileLines, Surround('{', '}', false, Block))
      insert(compileLines, 'end')
    elseif currentToken == 'if' then
      insert(compileLines, IfElse())
    elseif currentToken == 'for' then
      insert(compileLines, ForLoop())
    elseif currentToken == 'while' then
      insert(compileLines, consume())
      insert(compileLines, Expr())
      insert(compileLines, 'do')
      insert(compileLines, LoopBlock())
      insert(compileLines, 'end')
    elseif currentToken == 'repeat' then
      insert(compileLines, consume())
      insert(compileLines, LoopBlock())
      insert(compileLines, 'until')
      insert(compileLines, Expr())
    elseif currentToken == 'try' then
      insert(compileLines, TryCatch())
    elseif currentToken == 'return' then
      if isModuleReturnBlock then hasModuleReturn = true end
      insert(compileLines, Return())
    elseif currentToken == 'function' then
      insert(compileLines, Function())
    elseif currentToken == 'local' or currentToken == 'global' or currentToken == 'module' then
      insert(
        compileLines,
        lookAhead(1) == 'function' and Function() or Declaration()
      )
    else
      local indexChain = Try(IndexChain)
      if not indexChain then break end
      -- TODO: properly check for function call
      -- Allow function calls as standalone statements
      insert(compileLines, true and indexChain or Assignment(indexChain))
    end
  end

  blockDepth = blockDepth - 1

  if isLoopBlock and breakName and hasContinue then
    -- TODO: compile GOTO `continue` version when possible
    insert(compileLines, 1, ('local %s = false repeat'):format(breakName))
    insert(
      compileLines,
      ('%s = true until true if not %s then break end'):format(breakName, breakName)
    )
  end

  return compileLines
end

-- -----------------------------------------------------------------------------
-- Main
-- -----------------------------------------------------------------------------

return function(text)
  tokens, tokenLines = tokenize(text)
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

  local compileLines = {}

  if currentToken:match('^#!') then
    insert(compileLines, consume())
  end

  insert(compileLines, Block())

  if #moduleNames > 0 then
    if hasModuleReturn then
      error('Cannot use both `return` and `module` together.')
    else
      local moduleTableElements = {}

      for i, moduleName in ipairs(moduleNames) do
        insert(compileLines, moduleName .. '=' .. moduleName)
      end

      insert(compileLines, ('return { %s }'):format(concat(moduleTableElements, ',')))
    end
  end

  -- Free resources (potentially large tables)
  tokens, tokenLines = nil, nil

  local collapsedCompileLines = {}
  local collapsedCompileLineCounter = 0
  local sourceMap = {}
  local sourceLine = 1

  local function collectLines(lines)
    for _, line in ipairs(lines) do
      if type(line) == 'number' then
        sourceLine = line
      elseif type(line) == 'string' then
        insert(collapsedCompileLines, line)
        collapsedCompileLineCounter = collapsedCompileLineCounter + 1
        sourceMap[collapsedCompileLineCounter] = sourceLine
      else
        collectLines(line)
      end
    end
  end

  collectLines(compileLines)
  print('COMPILE LINES', require('inspect')(compileLines))
  insert(collapsedCompileLines, C.COMPILED_FOOTER_COMMENT)
  return concat(collapsedCompileLines, '\n'), sourceMap
end
