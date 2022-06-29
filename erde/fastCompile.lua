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

local tmpNameCounter

-- Keeps track of the closest loop block ancestor. This is used to validate
-- Break / Continue nodes, as well as register nested Continue nodes.
local loopRef

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

local function compileBinop(op, lhs, rhs)
  if op.token == '!=' then
    return table.concat({ lhs, ' ~= ', rhs })
  elseif op.token == '||' then
    return table.concat({ lhs, ' or ', rhs })
  elseif op.token == '&&' then
    return table.concat({ lhs, ' and ', rhs })
  elseif op.token == '|' then
    return ('require("bit").bor(%s, %s)'):format(lhs, rhs)
  elseif op.token == '~' then
    return ('require("bit").bxor(%s, %s)'):format(lhs, rhs)
  elseif op.token == '&' then
    return ('require("bit").band(%s, %s)'):format(lhs, rhs)
  elseif op.token == '<<' then
    return ('require("bit").lshift(%s, %s)'):format(lhs, rhs)
  elseif op.token == '>>' then
    return ('require("bit").rshift(%s, %s)'):format(lhs, rhs)
  else
    return table.concat({ lhs, op.token, rhs }, ' ')
  end
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

local function Try(rule)
  local currentTokenIndexBackup = currentTokenIndex

  local ok, node = pcall(rule)
  if ok then return node end

  currentTokenIndex = currentTokenIndexBackup
  currentToken = tokens[currentTokenIndex]
end

local function Surround(openChar, closeChar, include, callback)
  expect(openChar)
  local result = callback()
  expect(closeChar)
  return include and openChar .. result .. closeChar or result
end

local function Parens(allowRecursion, include, parse)
  return Surround('(', ')', include, function()
    return (allowRecursion and currentToken == '(') 
      and Parens(true, parse) or parse()
  end)
end

local function List(opts)
  local list = {}
  local hasTrailingComma = false

  repeat
    local node = Try(opts.parse)
    if not node then break end
    hasTrailingComma = branch(',')
    table.insert(list, node)
  until not hasTrailingComma

  assert(opts.allowTrailingComma or not hasTrailingComma)
  assert(opts.allowEmpty or #list > 0)

  return list
end

-- -----------------------------------------------------------------------------
-- Partials
-- -----------------------------------------------------------------------------

local function Destructure()
  local varName = newTmpName()
  local nameList = {}
  local assignments = {}

  if currentToken == '[' then
    local arrayIndex = 0
    Surround('[', ']', false, function()
      List({
        allowTrailingComma = true,
        parse = function()
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
        end,
      })
    end)
  else
    Surround('{', '}', false, function()
      List({
        allowTrailingComma = true,
        parse = function()
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
        end,
      })
    end)
  end

  return {
    name = varName,
    compiled = table.concat({
      'local ' .. table.concat(nameList, ','),
      table.concat(assignments, ','),
    }, '\n')
  }
end

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

local function Params()
  local names = {}
  local preBody = {}

  Parens(false, false, function()
    List({
      allowEmpty = true,
      allowTrailingComma = true,
      parse = function()
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
      end,
    })

    if branch('...') then
      table.insert(names, '...')
      local varargsName = Try(Name)
      if varargsName then
        table.insert(preBody, 'local ' .. varargsName .. ' = { ... }')
      end
    end
  end)

  return {
    compiled = '(' .. table.concat(names, ',') .. ')',
    preBody = table.concat(preBody, '\n'),
  }
end

local function Var()
  return (currentToken == '{' or currentToken == '[')
    and Destructure() or Name()
end

-- -----------------------------------------------------------------------------
-- Expressions
-- -----------------------------------------------------------------------------

local function IndexChain(allowTrivialChain)
  local indexChainBase = currentToken == '(' and Parens(true, true, Expr) or Name()
  local indexChain = indexChainBase
  local nextIndex = ''

  while nextIndex do
    indexChain = indexChain .. nextIndex
    nextIndex = nil

    if branch('.') then
      nextIndex = '.' .. Name({ allowKeywords = true })
    elseif currentToken == '[' then
      -- Add space around brackets to handle long string expressions
      -- [ [=[some string]=] ]
      nextIndex = '[ ' .. Surround('[', ']', false, Expr) .. ' ]'
    elseif branch(':') then
      nextIndex = ':' .. Name({ allowKeywords = true })
      if currentToken ~= '(' then
        error('Missing parentheses for method call')
      end
    elseif currentToken == '(' then
      -- TODO: semicolon
      nextIndex = Parens(false, true, function()
        return table.concat(List({
          allowEmpty = true,
          allowTrailingComma = true,
          parse = Expr,
        }), ',')
      end)
    end
  end

  if not allowTrivialChain and indexChain == indexChainBase then
    error('Require id')
  end

  return indexChain
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
  else
    return IndexChain(true)
  end
end

function Expr()
  return Terminal()
end

-- -----------------------------------------------------------------------------
-- Statements
-- -----------------------------------------------------------------------------

local function Assignment(firstId)
  local idList = { firstId }

  if branch(',') then
    List({
      parse = function()
        local indexChain = IndexChain()
        assert(indexChain:sub(-1) ~= ')')
        table.insert(idList, indexChain)
        return indexChain
      end,
    })
  end

  local op = C.BINOPS[currentToken] and consume()
  if op and C.BINOP_ASSIGNMENT_BLACKLIST[op.token] then
    error('Invalid assignment operator: ' .. currentToken)
  end

  expect('=')
  local exprList = List({ parse = Expr })

  if not op then
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
      table.insert(binopAssignments, id .. ' = ' .. compileBinop(op, id, assignmentName))
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
  local varList = List({ parse = Var })

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

    table.insert(declaration, table.concat(nameList, ','))
  end

  if branch('=') then
    table.insert(declaration, '=')
    table.insert(declaration, table.concat(List({ parse = Expr }), ','))
  end

  return table.concat({
    table.concat(declaration, ' '),
    table.concat(destructures, '\n'),
  }, '\n')
end

local function ForLoop()
  if lookAhead(1) == '=' then
    local name = Name()
    consume() -- '='

    local exprList = List({ parse = Expr })
    local exprListLen = #exprList

    if exprListLen < 2 then
      error('Invalid for loop parameters (missing parameters)')
    elseif exprListLen > 3 then
      error('Invalid for loop parameters (too many parameters)')
    end

    return table.concat({
      'for ' .. name .. ' = ' .. table.concat(exprList, ',') .. ' do',
      Surround('{', '}', false, Block),
      'end',
    }, '\n')
  else
    local nameList = {}
    local preBody = {}

    for i, var in ipairs(List({ parse = Var })) do
      if type(var) == 'string' then
        table.insert(nameList, var)
      else
        table.insert(nameList, var.name)
        table.insert(prebody, var.compiled)
      end
    end

    return table.concat({
      table.concat({
        'for',
        table.concat(nameList, ','),
        expect('in'),
        -- Generic for parses an expression list!
        -- see https://www.lua.org/pil/7.2.html
        -- TODO: only allow max 3 expressions? Job for linter?
        table.concat(List({ parse = Expr }), ','),
        'do',
      }, ' '),
      Surround('{', '}', false, Block),
      'end',
    }, '\n')
  end

  statement.body = Surround('{', '}', Block)
end

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

  local params = Params()

  return table.concat({
    table.concat({
      -- Default functions to local scope _unless_ they are part of a table.
      scope or (not isTableValue and 'local' or ''),
      'function',
      signature,
      params.compiled,
    }, ' '),
    params.preBody,
    Surround('{', '}', false, Block),
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
      and 'return ' .. firstReturn .. ',' .. List({ parse = Expr })
      or 'return ' .. firstReturn
  elseif currentToken == '(' then
    return 'return ' .. table.concat(Parens(true, false, function()
      return List({ allowTrailingComma = true, parse = Expr })
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

function Block()
  local compiled = {}

  repeat
    local statement

    if branch('break') then
      assert(loopRef ~= nil, 'Cannot use `break` outside of loop')
      statement = 'break'
    elseif branch('continue') then
      assert(loopRef ~= nil, 'Cannot use `continue` outside of loop')
      -- TODO: compile GOTO `continue` version when possible
      -- return 'goto ' .. node.gotoLabel
      statement = loopRef .. ' = true break'
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
      statement = 'while ' .. Expr() .. ' do ' .. Surround('{', '}', false, Block) .. ' end'
    elseif branch('repeat') then
      statement = table.concat({ 'repeat', Surround('{', '}', false, Block), expect('until'), Expr() }, ' ')
    elseif branch('try') then
      statement = TryCatch()
    elseif branch('return') then
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

    table.insert(compiled, statement)
  until not statement

  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Main
-- -----------------------------------------------------------------------------

return function(text)
  tokens, tokenInfo, newlines = tokenize(text)
  currentTokenIndex = 1
  currentToken = tokens[1]
  tmpNameCounter = 1

  -- Check for empty file or file w/ only comments
  if currentToken == nil then
    return nil
  end

  local shebang = currentToken:match('^#!') and consume() or ''
  return shebang .. Block()
end
