local C = require('erde.constants')
local tokenize = require('erde.tokenize')

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

-- Resolved bit library to use for compiling bit operations. Undefined when
-- compiling to Lua 5.3+ native operators.
local bitLib

-- -----------------------------------------------------------------------------
-- General Helpers
-- -----------------------------------------------------------------------------

local unpack = table.unpack or unpack
local insert = table.insert
local concat = table.concat

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

local function fatal(message)
  error({ severity = 'fatal', message = message })
end

-- -----------------------------------------------------------------------------
-- Compile Helpers
-- -----------------------------------------------------------------------------

local function newTmpName()
  tmpNameCounter = tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(tmpNameCounter)
end

local function weave(t, separator)
  local woven = {}
  local tLen = #t

  for i = 1, tLen - 1 do
    insert(woven, t[i])
    if type(t[i]) ~= 'number' then
      insert(woven, separator)
    end
  end

  insert(woven, t[tLen])
  return woven
end

local function compileBinop(opToken, opLine, lhs, rhs)
  if bitLib and C.BITOPS[opToken] then
    local bitOperation = ('require("%s").%s('):format(bitLib, C.BITLIB_METHODS[opToken])
    return { opLine, bitOperation, lhs, opLine, ',', rhs, opLine, ')' }
  elseif opToken == '!=' then
    return { lhs, opLine, '~=', rhs }
  elseif opToken == '||' then
    return { lhs, opLine, 'or', rhs }
  elseif opToken == '&&' then
    return { lhs, opLine, 'and', rhs }
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

  if type(result) == 'table' and result.severity == 'fatal' then
    error(result.message)
  end

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
      return weave(List(false, true, Expr), ',')
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

  if hasExprBase then
    insert(compileLines, Parens(true, true, Expr))
  else
    insert(compileLines, currentTokenLine)
    insert(compileLines, Name())
  end

  while true do
    if currentToken == '.' then
      insert(compileLines, currentTokenLine)
      insert(compileLines, consume() .. Name(true))
    elseif currentToken == '[' then
      insert(compileLines, currentTokenLine)
      insert(compileLines, '[')
      insert(compileLines, Surround('[', ']', false, Expr))
      insert(compileLines, ']')
    elseif branch(':') then
      insert(compileLines, currentTokenLine)
      insert(compileLines, ':' .. Name(true))
      if currentToken ~= '(' then
        fatal('Missing parentheses for method call')
      end
    elseif currentToken == '(' then
      -- TODO: need semicolon for ambiguous syntax?

      local precedingCompileLines = compileLines
      local precedingCompileLinesLen = #precedingCompileLines
      while type(precedingCompileLines[precedingCompileLinesLen]) == 'table' do
        precedingCompileLines = precedingCompileLines[precedingCompileLinesLen]
        precedingCompileLinesLen = #precedingCompileLines
      end

      -- Include function call parens on same line as function name to prevent
      -- parsing errors in Lua5.1: 
      --    `ambiguous syntax (function call x new statement) near '('`
      precedingCompileLines[precedingCompileLinesLen] = 
        precedingCompileLines[precedingCompileLinesLen] .. '('

      insert(compileLines, Parens(false, false, function()
        return weave(List(true, true, Expr), ',')
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
        insert(compileLines, expect('='))
      elseif lookAhead(1) == '=' then
        insert(compileLines, Name())
        insert(compileLines, consume()) -- '='
      end

      insert(compileLines, Expr())
      insert(compileLines, ',')
    end)

    return compileLines
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
    local quote = consume()
    return currentToken == quote -- check empty string
      and { currentTokenLine, quote .. consume() }
      or { currentTokenLine, quote .. consume() .. consume() }
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
        fatal('Unexpected EOF')
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
    if C.INVALID_BITOP_LUA_TARGETS[C.LUA_TARGET] and not C.BIT_LIB then
      fatal(table.concat({
        'Cannot use bitwise operators for Lua target',
        C.LUA_TARGET,
        'due to incompatabilities between bitwise operators across Lua versions.', 
      }, ' '))
    end

    local bitOperation = ('require("%s").%s('):format(bitLib, 'bnot')
    return { unopLine, bitOperation, operandLine, operand, unopLine, ')' }
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

    if C.BITOPS[binop.token] and C.INVALID_BITOP_LUA_TARGETS[C.LUA_TARGET] and not C.BIT_LIB then
      fatal(table.concat({
        'Cannot use bitwise operators for Lua target',
        C.LUA_TARGET,
        'due to incompatabilities between bitwise operators across Lua versions.', 
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
  local compileLines = {}
  local idList = { firstId }

  while branch(',') do
    local indexChain = IndexChain()

    for _, line in ipairs(indexChain) do
      if line == ')' then
        -- Do not allow function calls anywhere in index chain
        fatal('Invalid id')
      end
    end

    insert(idList, indexChain)
  end

  local opLine, opToken = currentTokenLine, C.BINOPS[currentToken] and consume()
  if opToken and C.BINOP_ASSIGNMENT_BLACKLIST[opToken] then
    -- TODO: use opLine in error
    fatal('Invalid assignment operator: ' .. opToken)
  end

  expect('=')
  local exprList = List(false, false, Expr)

  if not opToken then
    insert(compileLines, weave(idList, ','))
    insert(compileLines, '=')
    insert(compileLines, weave(exprList, ','))
  elseif #compileLines == 1 then
    -- Optimize most common use case
    insert(compileLines, firstId)
    insert(compileLines, opLine)
    insert(compileLines, '=')
    insert(compileLines, firstId)
    insert(compileLines, '+')
    insert(compileLines, exprList[1])
  else
    local assignmentNames = {}
    local assignmentCompileLines = {}

    for i, id in ipairs(idList) do
      local assignmentName = newTmpName()
      insert(assignmentNames, assignmentName)
      insert(assignmentCompileLines, id)
      insert(assignmentCompileLines, '=')
      insert(assignmentCompileLines, compileBinop(opToken, opLine, id, assignmentName))
    end

    insert(compileLines, 'local')
    insert(compileLines, concat(assignmentNames, ','))
    insert(compileLines, '=')
    insert(compileLines, weave(exprList, ','))
    insert(compileLines, assignmentCompileLines)
  end

  return compileLines
end

local function Declaration(scope)
  local compileLines = {}
  local destructureCompileLines = {}
  local names = {}

  if blockDepth > 1 and scope == 'module' then
    fatal('module declarations must appear at the top level')
  end
  
  if scope ~= 'global' then
    insert(compileLines, 'local')
  end

  for i, var in ipairs(List(false, false, Var)) do
    if type(var) == 'string' then
      insert(names, var)
    else
      insert(names, var.name)
      insert(destructureCompileLines, var.compileLines)
    end
  end

  if scope == 'module' then
    for _, name in ipairs(names) do
      insert(moduleNames, name)
    end
  end

  insert(compileLines, weave(names, ','))

  if currentToken == '=' then
    insert(compileLines, consume())
    insert(compileLines, weave(List(false, false, Expr), ','))
  end

  insert(compileLines, destructureCompileLines)
  return compileLines
end

local function ForLoop()
  local compileLines = { consume() }
  local preBodyCompileLines = {}

  if lookAhead(1) == '=' then
    insert(compileLines, currentTokenLine)
    insert(compileLines, Name())
    insert(compileLines, currentTokenLine)
    insert(compileLines, consume())

    local exprList = List(false, false, Expr)
    local exprListLen = #exprList

    if exprListLen < 2 then
      fatal('Invalid for loop parameters (missing parameters)')
    elseif exprListLen > 3 then
      fatal('Invalid for loop parameters (too many parameters)')
    end

    insert(compileLines, weave(exprList, ','))
  else
    local names = {}

    for i, var in ipairs(List(false, false, Var)) do
      if type(var) == 'string' then
        insert(names, var)
      else
        insert(names, var.name)
        insert(preBodyCompileLines, var.compileLines)
      end
    end

    insert(compileLines, weave(names, ','))
    insert(compileLines, expect('in'))

    -- Generic for parses an expression list!
    -- see https://www.lua.org/pil/7.2.html
    -- TODO: only allow max 3 expressions? Job for linter?
    insert(compileLines, weave(List(false, false, Expr), ','))
  end

  insert(compileLines, 'do')
  insert(compileLines, preBodyCompileLines)
  insert(compileLines, LoopBlock())
  insert(compileLines, 'end')
  return compileLines
end

local function Function(scope)
  local compileLines = { consume() }
  local signature = Name()
  local isTableValue = currentToken == '.'

  while branch('.') do
    signature = signature .. '.' .. Name()
  end

  if branch(':') then
    isTableValue = true
    signature = signature .. ':' .. Name()
  end

  insert(compileLines, signature)

  if isTableValue and scope ~= nil then
    -- Lua does not allow scope for table functions (ex. `local function a.b()`)
    fatal('Cannot use scope keyword for table values')
  end

  if not isTableValue and scope ~= 'global' then
    -- Note: This includes when scope is undefined! Default to local scope.
    insert(compileLines, 1, 'local')
  end

  if scope == 'module' then
    if blockDepth > 1 then
      fatal('module declarations must appear at the top level')
    end

    insert(moduleNames, signature)
  end

  local params = Params()
  insert(compileLines, '(' .. concat(params.names, ',') .. ')')
  insert(compileLines, params.compileLines)

  insert(compileLines, FunctionBlock())
  insert(compileLines, 'end')
  return compileLines
end

local function IfElse()
  local compileLines = {}

  insert(compileLines, consume())
  insert(compileLines, Expr())
  insert(compileLines, 'then')
  insert(compileLines, Surround('{', '}', false, Block))

  while currentToken == 'elseif' do
    insert(compileLines, consume())
    insert(compileLines, Expr())
    insert(compileLines, 'then')
    insert(compileLines, Surround('{', '}', false, Block))
  end

  if currentToken == 'else' then
    insert(compileLines, consume())
    insert(compileLines, Surround('{', '}', false, Block))
  end

  insert(compileLines, 'end')
  return compileLines
end

local function Return()
  local compileLines = { currentTokenLine, consume() }
  local firstReturn = Try(Expr)

  if firstReturn then
    insert(compileLines, firstReturn)
    if currentToken == ',' then
      insert(compileLines, consume())
      insert(compileLines, weave(List(false, false, Expr), ','))
    end
  elseif currentToken == '(' then
    insert(compileLines, Parens(true, false, function()
      return weave(List(false, true, Expr), ',')
    end))
  end

  return compileLines
end

local function TryCatch()
  local compileLines = {}
  local okName = newTmpName()
  local errorName = newTmpName()

  consume() -- 'try'
  insert(compileLines, ('local %s, %s = pcall(function()'):format(okName, errorName))
  insert(compileLines, Surround('{', '}', false, Block))
  insert(compileLines, 'end) if ' .. okName .. ' == false then')

  expect('catch')
  local errorVar = Try(Var)

  if errorVar then
    if type(errorVar) == 'string' then
      insert(compileLines, ('local %s = %s'):format(errorVar, errorName))
    else
      insert(compileLines, ('local %s = %s'):format(errorVar.name, errorName))
      insert(compileLines, errorVar.compileLines)
    end
  end

  insert(compileLines, Surround('{', '}', false, Block))
  insert(compileLines, 'end')
  return compileLines
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

      if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
        insert(compileLines, breakName .. ' = true break')
      else
        insert(compileLines, 'goto ' .. breakName)
      end
    elseif currentToken == 'goto' then
      -- TODO: check C.LUA_TARGET
      insert(compileLines, currentTokenLine)
      insert(compileLines, consume())
      insert(compileLines, currentTokenLine)
      insert(compileLines, Name())
    elseif currentToken == '::' then
      -- TODO: check C.LUA_TARGET
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
      insert(compileLines, expect('until'))
      insert(compileLines, Expr())
    elseif currentToken == 'try' then
      insert(compileLines, TryCatch())
    elseif currentToken == 'return' then
      if isModuleReturnBlock then hasModuleReturn = true end
      insert(compileLines, Return())
    elseif currentToken == 'function' then
      insert(compileLines, Function())
    elseif currentToken == 'local' or currentToken == 'global' or currentToken == 'module' then
      local scope = consume()
      insert(
        compileLines,
        currentToken == 'function' and Function(scope) or Declaration(scope)
      )
    else
      local indexChain = Try(IndexChain)
      if not indexChain then
        break
      elseif indexChain[#indexChain] == ')' then
        -- Allow function calls as standalone statements
        insert(compileLines, indexChain)
      else
        insert(compileLines, Assignment(indexChain))
      end
    end
  end

  blockDepth = blockDepth - 1

  if isLoopBlock and breakName and hasContinue then
    if C.LUA_TARGET == '5.1' or C.LUA_TARGET == '5.1+' then
      insert(compileLines, 1, ('local %s = false repeat'):format(breakName))
      insert(
        compileLines,
        ('%s = true until true if not %s then break end'):format(breakName, breakName)
      )
    else
      insert(compileLines, '::' .. breakName .. '::')
    end
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
  currentTokenLine = tokenLines[1]

  blockDepth = 0
  isModuleReturnBlock = true
  hasModuleReturn = false
  hasContinue = false
  tmpNameCounter = 1
  moduleNames = {}

  bitLib = C.BITLIB 
    or (C.LUA_TARGET == '5.1' and 'bit') -- Mike Pall's LuaBitOp
    or (C.LUA_TARGET == 'jit' and 'bit') -- Mike Pall's LuaBitOp
    or (C.LUA_TARGET == '5.2' and 'bit32') -- Lua 5.2's builtin bit32 library

  -- Check for empty file or file w/ only comments
  if currentToken == nil then
    return nil
  end

  local compileLines = {}

  if currentToken:match('^#!') then
    insert(compileLines, consume())
  end

  do
    local ok, result = pcall(Block)

    if not ok then
      if type(result) == 'table' and result.severity == 'fatal' then
        error(result.message)
      else
        error(result)
      end
    elseif currentToken then
      error('unexpected token ' .. currentToken)
    end

    insert(compileLines, result)
  end

  if #moduleNames > 0 then
    if hasModuleReturn then
      error('Cannot use both `return` and `module` together.')
    else
      local moduleTableElements = {}

      for i, moduleName in ipairs(moduleNames) do
        insert(moduleTableElements, moduleName .. '=' .. moduleName)
      end

      insert(compileLines, ('return { %s }'):format(concat(moduleTableElements, ',')))
    end
  end

  -- Free resources (potentially large tables)
  tokens, tokenLines = nil, nil

  local collapsedCompileLines = {}
  local collapsedCompileLineCounter = 0
  local sourceMap = {}

  -- Assign compiled lines with no source to the last known source line. We do
  -- this because Lua may give an error at the line of the _next_ token in
  -- certain cases. For example, the following will give an error at line 3,
  -- instead of line 2 where the nil index actually occurs:
  --   local x = nil
  --   print(x.a
  --   )
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
  insert(collapsedCompileLines, C.COMPILED_FOOTER_COMMENT)
  return concat(collapsedCompileLines, '\n'), sourceMap
end
