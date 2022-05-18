local C = require('erde.constants')
local parse = require('erde.parse')
local precompile = require('erde.precompile')

-- Foward declare rules
local ArrowFunction, Assignment, Binop, Block, Break, Continue, Declaration, Destructure, DoBlock, Expr, ForLoop, Function, FunctionCall, Goto, Id, IfElse, Module, OptChain, Params, RepeatUntil, Return, Self, Spread, String, Table, TryCatch, Unop, WhileLoop
local SUB_COMPILERS

-- =============================================================================
-- State
-- =============================================================================

local tmpNameCounter

-- =============================================================================
-- Helpers
-- =============================================================================

-- TODO: remove?
local function compileNode(node)
  if type(node) == 'string' then
    return node
  elseif type(node) ~= 'table' then
    error(('Invalid node type (%s): %s'):format(type(node), tostring(node)))
  elseif type(SUB_COMPILERS[node.ruleName]) ~= 'function' then
    error(('Invalid ruleName: %s'):format(node.ruleName))
  end

  local compiled = SUB_COMPILERS[node.ruleName](node)
  return node.parens and '(' .. compiled .. ')' or compiled
end

local function newTmpName()
  tmpNameCounter = tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(tmpNameCounter)
end

-- =============================================================================
-- Macros
-- =============================================================================

-- TODO: rename
local function compileBinop(op, lhs, rhs)
  if op.token == '??' then
    local ncTmpName = newTmpName()
    return table.concat({
      '(function()',
      ('local %s = %s'):format(ncTmpName, lhs),
      'if ' .. ncTmpName .. ' ~= nil then',
      'return ' .. ncTmpName,
      'else',
      'return ' .. rhs,
      'end',
      'end)()',
    }, '\n')
  elseif op.token == '!=' then
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

-- TODO: rename
local function compileOptChain(node)
  local chain = compileNode(node.base)
  local optSubChains = {}

  for i, chainNode in ipairs(node) do
    if chainNode.optional then
      optSubChains[#optSubChains + 1] = chain
    end

    local newSubChainFormat
    if chainNode.variant == 'dotIndex' then
      chain = ('%s.%s'):format(chain, chainNode.value)
    elseif chainNode.variant == 'bracketIndex' then
      -- Space around brackets to avoid long string expressions
      -- [ [=[some string]=] ]
      chain = ('%s[ %s ]'):format(chain, compileNode(chainNode.value))
    elseif chainNode.variant == 'functionCall' then
      local hasSpread = false
      for i, arg in ipairs(chainNode.value) do
        if arg.ruleName == 'Spread' then
          hasSpread = true
          break
        end
      end

      if hasSpread then
        local spreadFields = {}

        for i, arg in ipairs(chainNode.value) do
          spreadFields[i] = arg.ruleName == 'Spread' and arg
            or { value = compileNode(expr) }
        end

        chain = ('%s(%s(%s))'):format(chain, 'unpack', Spread(spreadFields))
      else
        local args = {}

        for i, arg in ipairs(chainNode.value) do
          args[#args + 1] = compileNode(arg)
        end

        chain = chain .. '(' .. table.concat(args, ',') .. ')'
      end
    elseif chainNode.variant == 'method' then
      chain = chain .. ':' .. chainNode.value
    end
  end

  return { optSubChains = optSubChains, chain = chain }
end

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

function ArrowFunction(node)
  local params = compileNode(node.params)
  local paramNames = params.names

  if node.hasFatArrow then
    table.insert(paramNames, 1, 'self')
  end

  local body
  if not node.hasImplicitReturns then
    body = compileNode(node.body)
  else
    local returns = {}

    for i, value in ipairs(node.returns) do
      returns[i] = compileNode(value)
    end

    body = 'return ' .. table.concat(returns, ',')
  end

  return table.concat({
    'function(' .. table.concat(paramNames, ',') .. ')',
    params and params.prebody or '',
    body,
    'end',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

local function compileRawAssignment(node)
  local compiled = {}
  local assignmentNames = {}

  for _, id in ipairs(node.idList) do
    if type(id) == 'string' then
      table.insert(assignmentNames, id)
    elseif id.ruleName ~= 'OptChain' then
      table.insert(assignmentNames, compileNode(id))
    else
      local optChain = compileOptChain(id)

      if #optChain.optSubChains == 0 then
        table.insert(assignmentNames, optChain.chain)
      else
        local assignmentName = newTmpName()
        table.insert(assignmentNames, assignmentName)

        local optChecks = {}
        for i, optSubChain in ipairs(optChain.optSubChains) do
          table.insert(optChecks, optSubChain .. ' ~= nil')
        end

        table.insert(
          compiled,
          ('if %s then %s end'):format(
            table.concat(optChecks, ' and '),
            optChain.chain .. ' = ' .. assignmentName
          )
        )
      end
    end
  end

  local assignmentExprs = {}
  for _, expr in ipairs(node.exprList) do
    table.insert(assignmentExprs, compileNode(expr))
  end

  local assignment = ('%s = %s'):format(
    table.concat(assignmentNames, ','),
    table.concat(assignmentExprs, ',')
  )

  table.insert(compiled, 1, assignment)
  return table.concat(compiled, '\n')
end

local function compileBinopAssignment(node)
  local compiled = {}

  local assignmentNames = {}
  for _, id in ipairs(node.idList) do
    table.insert(assignmentNames, newTmpName())
  end

  local assignmentExprs = {}
  for _, expr in ipairs(node.exprList) do
    table.insert(assignmentExprs, compileNode(expr))
  end

  table.insert(
    compiled,
    ('local %s = %s'):format(
      table.concat(assignmentNames, ','),
      table.concat(assignmentExprs, ',')
    )
  )

  for i, id in ipairs(node.idList) do
    local assignmentName = assignmentNames[i]

    if type(id) == 'string' then
      table.insert(
        compiled,
        id .. ' = ' .. compileBinop(node.op, id, assignmentName)
      )
    elseif id.ruleName ~= 'OptChain' then
      local compiledId = compileNode(id)
      table.insert(
        compiled,
        compiledId .. ' = ' .. compileBinop(node.op, compiledId, assignmentName)
      )
    else
      local optChain = compileOptChain(id)
      local compiledAssignment = optChain.chain
        .. ' = '
        .. compileBinop(node.op, optChain.chain, assignmentName)

      if #optChain.optSubChains == 0 then
        table.insert(compiled, compiledAssignment)
      else
        local optChecks = {}
        for i, optSubChain in ipairs(optChain.optSubChains) do
          table.insert(optChecks, optSubChain .. ' ~= nil')
        end

        table.insert(
          compiled,
          ('if %s then %s end'):format(
            table.concat(optChecks, ' and '),
            table.insert(compiled, compiledAssignment)
          )
        )
      end
    end
  end

  return table.concat(compiled, '\n')
end

function Assignment(node)
  return node.op == nil and compileRawAssignment(node)
    or compileBinopAssignment(node)
end

-- -----------------------------------------------------------------------------
-- Binop
-- -----------------------------------------------------------------------------

function Binop(node)
  local op = node.op
  local lhs = compileNode(node.lhs)
  local rhs = compileNode(node.rhs)

  if op.token == '?' then
    return table.concat({
      '(function()',
      'if %s then',
      'return %s',
      'else',
      'return %s',
      'end',
      'end)()',
    }, '\n'):format(lhs, compileNode(node.ternaryExpr), rhs)
  else
    return compileBinop(op, lhs, rhs)
  end
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local function compileBlockStatements(node)
  local compiledStatements = {}

  for _, statement in ipairs(node) do
    -- As of January 5, 2022, we use a lot of iife statements in compiled code.
    -- This semicolon removes Lua's ambiguous syntax error when using iife by
    -- funtion calls.
    --
    -- http://lua-users.org/lists/lua-l/2009-08/msg00543.html
    table.insert(compiledStatements, compileNode(statement) .. ';')
  end

  return table.concat(compiledStatements, '\n')
end

function Block(node)
  if node.continueNodes and #node.continueNodes > 0 then
    local continueGotoLabel = newTmpName()

    for i, continueNode in ipairs(node.continueNodes) do
      continueNode.gotoLabel = continueGotoLabel
    end

    return ('%s\n::%s::'):format(
      compileBlockStatements(node),
      continueGotoLabel
    )
  else
    return compileBlockStatements(node)
  end
end

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

function Break(node)
  return 'break'
end

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

function Continue(node)
  return 'goto ' .. node.gotoLabel
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

function Declaration(node)
  local declarationParts = {}
  local compileParts = {}

  if node.isHoisted then
    if #node.exprList == 0 then
      -- Nothing to do
      return ''
    end
  elseif node.variant ~= 'global' then
    table.insert(declarationParts, 'local')
  end

  local nameList = {}

  for i, var in ipairs(node.varList) do
    if type(var) == 'string' then
      table.insert(nameList, var)
    else
      local destructure = compileNode(var)
      table.insert(nameList, destructure.baseName)
      table.insert(compileParts, destructure.compiled)
    end
  end

  table.insert(declarationParts, table.concat(nameList, ','))

  if #node.exprList > 0 then
    local exprList = {}

    for i, expr in ipairs(node.exprList) do
      table.insert(exprList, compileNode(expr))
    end

    table.insert(declarationParts, '=')
    table.insert(declarationParts, table.concat(exprList, ','))
  end

  table.insert(compileParts, 1, table.concat(declarationParts, ' '))
  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

function Destructure(node)
  local baseName = newTmpName()
  local varNames = {}
  local numberKeyCounter = 1
  local compileParts = {}

  for i, field in ipairs(node) do
    local varName = field.alias or field.name
    varNames[i] = varName

    if field.variant == 'keyDestruct' then
      table.insert(
        compileParts,
        ('%s = %s.%s'):format(varName, baseName, field.name)
      )
    elseif field.variant == 'numberDestruct' then
      table.insert(
        compileParts,
        ('%s = %s[%s]'):format(varName, baseName, numberKeyCounter)
      )
      numberKeyCounter = numberKeyCounter + 1
    end

    if field.default then
      table.insert(
        compileParts,
        ('if %s == nil then %s = %s end'):format(
          varName,
          varName,
          compileNode(field.default)
        )
      )
    end
  end

  table.insert(compileParts, 1, 'local ' .. table.concat(varNames, ','))

  return {
    baseName = baseName,
    compiled = table.concat(compileParts, '\n'),
  }
end

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

function DoBlock(node)
  if node.isExpr then
    return '(function() ' .. compileNode(node.body) .. ' end)()'
  else
    return 'do\n' .. compileNode(node.body) .. '\nend'
  end
end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

function ForLoop(node)
  if node.variant == 'numeric' then
    local parts = {}
    for i, part in ipairs(node.parts) do
      table.insert(parts, compileNode(part))
    end

    return ('for %s=%s do\n%s\nend'):format(
      compileNode(node.name),
      table.concat(parts, ','),
      compileNode(node.body)
    )
  else
    local prebody = {}

    local nameList = {}
    for i, var in ipairs(node.varList) do
      if type(var) == 'table' then
        local destructure = compileNode(var)
        nameList[i] = destructure.baseName
        table.insert(prebody, destructure.compiled)
      else
        nameList[i] = compileNode(var)
      end
    end

    local exprList = {}
    for i, expr in ipairs(node.exprList) do
      exprList[i] = compileNode(expr)
    end

    return ('for %s in %s do\n%s\n%s\nend'):format(
      table.concat(nameList, ','),
      table.concat(exprList, ','),
      table.concat(prebody, '\n'),
      compileNode(node.body)
    )
  end
end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

function Function(node)
  local params = compileNode(node.params)

  local methodName
  if node.isMethod then
    methodName = table.remove(node.names)
  end

  return ('%s function %s%s(%s)\n%s\n%s\nend'):format(
    (node.variant ~= 'global' and not node.isHoisted) and 'local' or '',
    table.concat(node.names, '.'),
    methodName and ':' .. methodName or '',
    table.concat(params.names, ','),
    params.prebody,
    compileNode(node.body)
  )
end

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

function Goto(node)
  if node.variant == 'jump' then
    return 'goto ' .. node.name
  elseif node.variant == 'definition' then
    return '::' .. node.name .. '::'
  end
end

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

function IfElse(node)
  local compileParts = {
    'if ' .. compileNode(node.ifNode.condition) .. ' then',
    compileNode(node.ifNode.body),
  }

  for _, elseifNode in ipairs(node.elseifNodes) do
    table.insert(
      compileParts,
      'elseif ' .. compileNode(elseifNode.condition) .. ' then'
    )
    table.insert(compileParts, compileNode(elseifNode.body))
  end

  if node.elseNode then
    table.insert(compileParts, 'else')
    table.insert(compileParts, compileNode(node.elseNode.body))
  end

  table.insert(compileParts, 'end')
  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

function Module(node)
  local compiled = {}

  if node.shebang then
    table.insert(compiled, node.shebang)
  end

  table.insert(compiled, C.COMPILED_HEADER_COMMENT)

  if #node.hoistedNames > 0 then
    table.insert(compiled, 'local ' .. table.concat(node.hoistedNames, ','))
  end

  if #node.exportNames > 0 then
    local moduleTableElements = {}
    for i, moduleName in ipairs(node.exportNames) do
      moduleTableElements[i] = moduleName .. '=' .. moduleName
    end

    table.insert(compiled, compileBlockStatements(node))
    table.insert(
      compiled,
      'return { ' .. table.concat(moduleTableElements, ',') .. ' }'
    )
  elseif node.mainName ~= nil then
    table.insert(compiled, compileBlockStatements(node))
    table.insert(compiled, 'return ' .. node.mainName)
  else
    table.insert(compiled, compileBlockStatements(node))
  end

  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

function OptChain(node)
  local optChain = compileOptChain(node)

  if #optChain.optSubChains == 0 then
    return optChain.chain
  end

  local optChecks = {}
  for i, optSubChain in ipairs(optChain.optSubChains) do
    optChecks[i] = 'if ' .. optSubChain .. ' == nil then return end'
  end

  return table.concat({
    '(function()',
    table.concat(optChecks, '\n'),
    'return ' .. optChain.chain,
    'end)()',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

function Params(node)
  local names = {}
  local prebody = {}

  for i, param in ipairs(node) do
    local name, destructure

    if param.varargs then
      name = '...'
      if param.value then
        table.insert(prebody, 'local ' .. param.value .. ' = { ... }')
      end
    elseif type(param.value) == 'string' then
      name = param.value
    else
      destructure = compileNode(param.value)
      name = destructure.baseName
    end

    if param.default then
      table.insert(prebody, 'if ' .. name .. ' == nil then')
      table.insert(prebody, name .. ' = ' .. compileNode(param.default))
      table.insert(prebody, 'end')
    end

    if destructure then
      table.insert(prebody, destructure.compiled)
    end

    table.insert(names, name)
  end

  return { names = names, prebody = table.concat(prebody, '\n') }
end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

function RepeatUntil(node)
  return ('repeat\n%s\nuntil %s'):format(
    compileNode(node.body),
    compileNode(node.condition)
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

function Return(node)
  local returnValues = {}

  for i, returnValue in ipairs(node) do
    returnValues[i] = compileNode(returnValue)
  end

  return 'return ' .. table.concat(returnValues, ',')
end

-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

function Self(node)
  if node.variant == 'dotIndex' then
    return 'self.' .. node.value
  elseif node.variant == 'numberIndex' then
    return 'self[' .. node.value .. ']'
  else
    return 'self'
  end
end

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

function Spread(fields)
  local tableVar = newTmpName()
  local lenVar = newTmpName()
  local hasVarArgs = false

  local compileParts = {
    'local ' .. tableVar .. ' = {}',
    'local ' .. lenVar .. ' = 0',
  }

  for i, field in ipairs(fields) do
    if field.ruleName == 'Spread' then
      local spreadTmpName = newTmpName()

      local spreadValue
      if field.value then
        spreadValue = compileNode(field.value)
      else
        hasVarArgs = true
        spreadValue = '{ ... }'
      end

      table.insert(
        compileParts,
        table.concat({
          'local ' .. spreadTmpName .. ' = ' .. spreadValue,
          'for key, value in pairs(' .. spreadTmpName .. ') do',
          'if type(key) == "number" then',
          ('%s[%s + key] = value'):format(tableVar, lenVar),
          'else',
          tableVar .. '[key] = value',
          'end',
          'end',
          ('%s = %s + #%s'):format(lenVar, lenVar, spreadTmpName),
        }, '\n')
      )
    elseif field.key then
      table.insert(
        compileParts,
        ('%s[%s] = %s'):format(tableVar, field.key, field.value)
      )
    else
      table.insert(
        compileParts,
        table.concat({
          ('%s[%s + 1] = %s'):format(tableVar, lenVar, field.value),
          ('%s = %s + 1'):format(lenVar, lenVar),
        }, '\n')
      )
    end
  end

  -- If varargs are present, proxy it to our iife!
  return table.concat({
    hasVarArgs and '(function(...)' or '(function()',
    table.concat(compileParts, '\n'),
    'return ' .. tableVar,
    hasVarArgs and 'end)(...)' or 'end)()',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

function String(node)
  local openingChar, closingChar

  if node.variant == 'single' then
    openingChar, closingChar = "'", "'"
  elseif node.variant == 'double' then
    openingChar, closingChar = '"', '"'
  elseif node.variant == 'long' then
    openingChar = '[' .. node.equals .. '['
    closingChar = ']' .. node.equals .. ']'
  end

  if #node == 0 then
    return openingChar .. closingChar
  end

  local compiled = ''

  for i, capture in ipairs(node) do
    if capture.variant == 'interpolation' then
      local interpolation = 'tostring(' .. compileNode(capture.value) .. ')'
      compiled = compiled
        .. table.concat({ closingChar, interpolation, openingChar }, '..')
    else
      compiled = compiled .. capture.value
    end
  end

  return openingChar .. compiled .. closingChar
end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

function Table(node)
  local hasSpread = false
  for i, field in ipairs(node) do
    if field.variant == 'spread' then
      hasSpread = true
      break
    end
  end

  if hasSpread then
    local spreadFields = {}

    for i, field in ipairs(node) do
      if field.variant == 'spread' then
        spreadFields[i] = field.value
      else
        local spreadField = {}

        if field.variant == 'nameKey' then
          spreadField.key = '"' .. field.key .. '"'
        elseif field.variant ~= 'numberKey' then
          spreadField.key = compileNode(field.key)
        end

        spreadField.value = compileNode(field.value)
        spreadFields[i] = spreadField
      end
    end

    return Spread(spreadFields)
  else
    local fieldParts = {}

    for i, field in ipairs(node) do
      local fieldPart

      if field.variant == 'nameKey' then
        fieldPart = field.key .. ' = ' .. compileNode(field.value)
      elseif field.variant == 'numberKey' then
        fieldPart = compileNode(field.value)
      elseif field.variant == 'exprKey' then
        fieldPart = ('[%s] = %s'):format(
          compileNode(field.key),
          compileNode(field.value)
        )
      end

      fieldParts[i] = fieldPart
    end

    return '{\n' .. table.concat(fieldParts, ',\n') .. '\n}'
  end
end

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

function TryCatch(node)
  local okName = newTmpName()
  local errorName = newTmpName()

  local compiled = {
    ('local %s, %s = pcall(function() %s end)'):format(
      okName,
      errorName,
      compileNode(node.try)
    ),
    'if ' .. okName .. ' == false then',
  }

  if node.error then
    if type(node.error) == 'string' then
      table.insert(compiled, ('local %s = %s'):format(
        node.error,
        errorName
      ))
    else
      local destructure = compileNode(node.error)
      table.insert(compiled, ('local %s = %s'):format(
        destructure.baseName,
        errorName
      ))
      table.insert(compiled, destructure.compiled)
    end
  end

  table.insert(compiled, compileNode(node.catch))
  table.insert(compiled, 'end')
  return table.concat(compiled, '\n')
end

-- -----------------------------------------------------------------------------
-- Unop
-- -----------------------------------------------------------------------------

function Unop(node)
  local op = node.op
  local operand = compileNode(node.operand)

  if op.token == '~' then
    return ('require("bit").bnot(%1)'):format(operand)
  elseif op.token == '!' then
    return 'not ' .. operand
  else
    return op.token .. operand
  end
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

function WhileLoop(node)
  return ('while %s do\n%s\nend'):format(
    compileNode(node.condition),
    compileNode(node.body)
  )
end

-- =============================================================================
-- Return
-- =============================================================================

SUB_COMPILERS = {
  ArrowFunction = ArrowFunction,
  Assignment = Assignment,
  Binop = Binop,
  Block = Block,
  Break = Break,
  Continue = Continue,
  Declaration = Declaration,
  Destructure = Destructure,
  DoBlock = DoBlock,
  Expr = Expr,
  ForLoop = ForLoop,
  Function = Function,
  Goto = Goto,
  IfElse = IfElse,
  Module = Module,
  OptChain = OptChain,
  Params = Params,
  RepeatUntil = RepeatUntil,
  Return = Return,
  Self = Self,
  Spread = Spread,
  String = String,
  Table = Table,
  TryCatch = TryCatch,
  Unop = Unop,
  WhileLoop = WhileLoop,
}

return function(text)
  local ast = parse(text)
  precompile(ast)
  tmpNameCounter = 1
  return compileNode(ast)
end
