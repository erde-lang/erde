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

-- -----------------------------------------------------------------------------
-- Helpers
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

local function lookBehind(n)
  return tokens[currentTokenIndex - n] or ''
end

local function lookAhead(n)
  return tokens[currentTokenIndex + n] or ''
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
  return (currentToken == '{' or currentToken == '[')
    and Destructure() or Name()
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

-- -----------------------------------------------------------------------------
-- Expressions
-- -----------------------------------------------------------------------------

local function IndexChain()
  local indexChain = currentToken == '(' and Parens(true, true, Expr) or Name()
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
    return IndexChain()
  end
end

function Expr()
  return Terminal()
end

-- -----------------------------------------------------------------------------
-- Statements
-- -----------------------------------------------------------------------------

local function Declaration()
  local declaration = {}
  local destructures = {}
  local scope = consume()
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

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block()
  local compiled = {}

  repeat
    local statement

    if currentToken == 'local' or currentToken == 'global' or currentToken == 'module' then
      statement = Declaration()
    else
      local indexChain = Try(IndexChain)

      if indexChain then
        if indexChain:sub(-1) == ')' then
          -- Allow function calls as standalone statements
          statement = indexChain
        end
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

  -- Check for empty file or file w/ only comments
  if currentToken == nil then
    return nil
  end

  local shebang = currentToken:match('^#!') and consume() or ''
  return shebang .. Block()
end
