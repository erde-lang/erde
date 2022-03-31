local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare
local SUB_FORMATTERS

-- =============================================================================
-- State
-- =============================================================================

local indentLevel

-- The line prefix
local linePrefix

-- Used to indicate to rules to format to a single line.
local forceSingleLine

-- =============================================================================
-- Configuration
-- =============================================================================

local indentWidth = 2
local columnLimit = 80
local overflowLimit = 10

-- =============================================================================
-- Helpers
-- =============================================================================

-- Forward declare
local precompileNode, precompileChildren

local function reset(node)
  indentLevel = 0
  linePrefix = ''
  forceSingleLine = false
end

local function indent(levelDiff)
  indentLevel = indentLevel + levelDiff
  linePrefix = (' '):rep(indentLevel * indentWidth)
end

local function prefix(line)
  return (forceSingleLine and '' or linePrefix) .. line
end

local function join(lines)
  return table.concat(lines, forceSingleLine and ' ' or '\n')
end

local function subColumnLimit(...)
  local limit = columnLimit - #linePrefix

  for _, str in ipairs({ ... }) do
    limit = limit - #str
  end

  return limit
end

local function formatNode(node)
  if type(node) == 'string' then
    return node
  elseif type(node) ~= 'table' then
    error(('Invalid node type (%s): %s'):format(type(node), tostring(node)))
  elseif type(SUB_FORMATTERS[node.ruleName]) ~= 'function' then
    error(('Invalid ruleName: %s'):format(node.ruleName))
  end

  local formatted = SUB_FORMATTERS[node.ruleName](node)
  return node.parens and '(' .. formatted .. ')' or formatted
end

local function formatNodes(nodes, sep)
  local formattedNodes = {}

  for _, node in ipairs(nodes) do
    table.insert(formattedNodes, formatNode(node))
  end

  return sep and table.concat(formattedNodes, sep) or formattedNodes
end

-- =============================================================================
-- Macros
-- =============================================================================

local function SingleLineList(nodes)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local formatted = formatNodes(nodes, ', ')
  forceSingleLine = forceSingleLineBackup
  return formatted
end

local function MultiLineList(nodes)
  local formatted = { '(' }
  indent(1)

  for _, node in ipairs(nodes) do
    table.insert(formatted, prefix(node) .. ',')
  end

  indent(-1)
  table.insert(formatted, prefix(')'))
  return table.concat(formatted, '\n')
end

local function List(nodes, limit)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local list = formatNodes(nodes)
  forceSingleLine = forceSingleLineBackup

  local singleLineList = table.concat(list, ', ')
  if #list < 2 or forceSingleLine or #singleLineList <= limit then
    return singleLineList
  end

  local lines = { '(' }
  indent(1)

  for _, item in ipairs(list) do
    table.insert(lines, prefix(item) .. ',')
  end

  indent(-1)
  table.insert(lines, prefix(')'))
  return table.concat(lines, '\n')
end

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

local function ArrowFunction(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

local function Assignment(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local function Block(node)
  local formatted = {}
  indent(1)

  for _, statement in ipairs(node) do
    table.insert(formatted, prefix(formatNode(statement)))
  end

  indent(-1)
  return join(formatted)
end

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

local function Break(node)
  return 'break'
end

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

local function Continue(node)
  return 'continue'
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

local function SingleLineDeclaration(node)
  local formatted = {
    node.variant,
    SingleLineList(node.varList),
  }

  if #node.exprList > 0 then
    table.insert(formatted, '=')
    table.insert(formatted, SingleLineList(node.exprList))
  end

  return table.concat(formatted, ' ')
end

local function MultiLineDeclaration(node)
  local formatted = { node.variant }

  local singleLineVarList = SingleLineList(node.varList)
  local hasSingleLineVarList = #singleLineVarList
    <= subColumnLimit(node.variant) - 1

  table.insert(
    formatted,
    hasSingleLineVarList and singleLineVarList or MultiLineList(node.varList)
  )

  if #node.exprList > 0 then
    table.insert(formatted, '=')

    -- TODO: fix this
    if #node.exprList == 1 then
      indent(1)
      table.insert(formatted, '\n' .. prefix(formatNode(node.exprList[1])))
      indent(-1)
    else
      local exprListColumnLimit = formatted[2]:sub(1, 1) == '('
          and subColumnLimit(') = ')
        or subColumnLimit(table.concat(formatted, ' '))
      table.insert(formatted, List(node.exprList, exprListColumnLimit))
    end
  end

  return table.concat(formatted, ' ')
end

local function Declaration(node)
  return forceSingleLine and SingleLineDeclaration(node)
    or MultiLineDeclaration(node)
end

-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

local function Destructure(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

local function DoBlock(node)
  return join({ 'do {', formatNode(node.body), prefix('}') })
end

-- -----------------------------------------------------------------------------
-- Expr
-- -----------------------------------------------------------------------------

local function Expr(node)
  -- TODO: wrap
  if node.variant == 'unop' then
    return node.op.token .. formatNode(node.operand)
  elseif node.ternaryExpr then
    return ('%s ? %s : %s'):format(
      formatNode(node.lhs),
      formatNode(node.ternaryExpr),
      formatNode(node.rhs)
    )
  else
    return table.concat({
      formatNode(node.lhs),
      node.op.token,
      formatNode(node.rhs),
    }, ' ')
  end
end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

local function ForLoop(node)
  local formatted = {}
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true

  if node.variant == 'numeric' then
    table.insert(
      formatted,
      table.concat({
        'for',
        node.name,
        '=',
        SingleLineList(node.parts),
        '{',
      }, ' ')
    )
  else
    table.insert(
      formatted,
      table.concat({
        'for',
        SingleLineList(node.varList),
        'in',
        SingleLineList(node.exprList),
        '{',
      }, ' ')
    )
  end

  forceSingleLine = forceSingleLineBackup
  table.insert(formatted, formatNode(node.body))
  table.insert(formatted, prefix('}'))
  return join(formatted)
end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

local function Function(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

local function Goto(node)
  if node.variant == 'jump' then
    return 'goto ' .. node.name
  elseif node.variant == 'definition' then
    return '::' .. node.name .. '::'
  end
end

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

local function IfElse(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true

  local ifCondition = formatNode(node.ifNode.condition)
  local elseifConditions = {}
  for _, elseifNode in ipairs(node.elseifNodes) do
    table.insert(elseifConditions, formatNode(elseifNode.condition))
  end

  forceSingleLine = forceSingleLineBackup

  local formatted = {
    'if ' .. ifCondition .. ' {',
    formatNode(node.ifNode.body),
  }

  for i, elseifNode in ipairs(node.elseifNodes) do
    table.insert(formatted, prefix('} elseif ' .. elseifConditions[i] .. ' {'))
    table.insert(formatted, formatNode(elseifNode.body))
  end

  if node.elseNode then
    table.insert(formatted, prefix('} else {'))
    table.insert(formatted, formatNode(node.elseNode.body))
  end

  table.insert(formatted, prefix('}'))
  return join(formatted)
end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

local function Module(node)
  local formatted = {}

  if node.shebang then
    table.insert(formatted, node.shebang)
  end

  for _, statement in ipairs(node) do
    table.insert(formatted, formatNode(statement))
  end

  return table.concat(formatted, '\n')
end

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

local function OptChain(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

local function Params(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

local function RepeatUntil(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return join({
    'repeat',
    formatNode(node.body),
    prefix('until ' .. condition),
  })
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

local function Return(node)
  local singleLineReturns = SingleLineList(node)
  return #singleLineReturns <= subColumnLimit('return ')
      and 'return ' .. singleLineReturns
    or 'return ' .. MultiLineList(node)
end

-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

local function Self(node)
  if node.variant == 'self' then
    return '$'
  else
    return '$' .. node.value
  end
end

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

local function Spread(node)
  return '...' .. (node.value and formatNode(node.value) or '')
end

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

local function String(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

local function Table(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

local function TryCatch(node)
  return join({
    'try {',
    formatNode(node.try),
    prefix('} catch (' .. (node.errorName or '') .. ') {'),
    formatNode(node.catch),
    prefix('}'),
  })
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

local function WhileLoop(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return join({
    'while ' .. condition .. ' {',
    formatNode(node.body),
    prefix('}'),
  })
end

-- =============================================================================
-- Format
-- =============================================================================

SUB_FORMATTERS = {
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
  WhileLoop = WhileLoop,
}

return function(textOrAst, ...)
  local ast = type(textOrAst) == 'string' and parse(textOrAst, ...) or textOrAst
  reset()
  return formatNode(ast)
end
