local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare
local SINGLE_LINE_FORMATTERS, MULTI_LINE_FORMATTERS

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

local function backup()
  return {
    indentLevel = indentLevel,
    linePrefix = linePrefix,
    forceSingleLine = forceSingleLine,
  }
end

local function restore(state)
  indentLevel = state.indentLevel
end

local function indent(levelDiff)
  indentLevel = indentLevel + levelDiff
  linePrefix = (' '):rep(indentLevel * indentWidth)
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
  end

  local formatter = forceSingleLine and SINGLE_LINE_FORMATTERS[node.ruleName]
    or MULTI_LINE_FORMATTERS[node.ruleName]

  if type(formatter) ~= 'function' then
    error(('Invalid ruleName: %s'):format(node.ruleName))
  end

  local formatted = formatter(node)
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

local function Line(code)
  return linePrefix .. code
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
    table.insert(lines, Line(item) .. ',')
  end

  indent(-1)
  table.insert(lines, Line(')'))
  return table.concat(lines, '\n')
end

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

function ArrowFunction(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

function Assignment(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function SingleLineBlock(node)
  local formatted = {}
  indent(1)

  for _, statement in ipairs(node) do
    table.insert(formatted, formatNode(statement))
  end

  indent(-1)
  return table.concat(formatted, ' ')
end

function MultiLineBlock(node)
  local formatted = {}
  indent(1)

  for _, statement in ipairs(node) do
    table.insert(formatted, Line(formatNode(statement)))
  end

  indent(-1)
  return table.concat(formatted, '\n')
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
  return 'continue'
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

function Declaration(node)
  local formatted = {
    node.variant,
    List(node.varList, subColumnLimit(node.variant .. ' ')),
  }

  if #node.exprList > 0 then
    table.insert(formatted, '=')

    if #node.exprList == 1 then
      indent(1)
      table.insert(formatted, '\n' .. Line(formatNode(node.exprList[1])))
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

-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

function Destructure(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

function SingleLineDoBlock(node)
  return table.concat({ 'do {', formatNode(node.body), '}' }, ' ')
end

function MultiLineDoBlock(node)
  return table.concat({ 'do {', formatNode(node.body), Line('}') }, '\n')
end

-- -----------------------------------------------------------------------------
-- Expr
-- -----------------------------------------------------------------------------

function Expr(node)
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

function ForLoop(node)
  local formatted = {}
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true

  if node.variant == 'numeric' then
    table.insert(
      formatted,
      Line(table.concat({
        'for',
        node.name,
        '=',
        formatNodes(node.parts, ', '),
        '{',
      }, ' '))
    )
  else
    table.insert(
      formatted,
      Line(table.concat({
        'for',
        formatNodes(node.varList, ', '),
        'in',
        formatNodes(node.exprList, ', '),
        '{',
      }, ' '))
    )
  end

  forceSingleLine = forceSingleLineBackup
  table.insert(formatted, formatNode(node.body))
  table.insert(formatted, Line('}'))
  return table.concat(formatted, '\n')
end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

function Function(node)
  return ''
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
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true

  local ifCondition = formatNode(node.ifNode.condition)
  local elseifConditions = {}
  for _, elseifNode in ipairs(node.elseifNodes) do
    table.insert(elseifConditions, formatNode(elseifNode.condition))
  end

  forceSingleLine = forceSingleLineBackup

  local formatted = {
    Line('if ' .. ifCondition .. ' {'),
    formatNode(node.ifNode.body),
  }

  for i, elseifNode in ipairs(node.elseifNodes) do
    table.insert(formatted, Line('} elseif ' .. elseifConditions[i] .. ' {'))
    table.insert(formatted, formatNode(elseifNode.body))
  end

  if node.elseNode then
    table.insert(formatted, Line('} else {'))
    table.insert(formatted, formatNode(node.elseNode.body))
  end

  table.insert(formatted, Line('}'))
  return table.concat(formatted, forceSingleLine and ' ' or '\n')
end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

function Module(node)
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

function OptChain(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

function Params(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

function SingleLineRepeatUntil(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return table.concat({
    'repeat',
    formatNode(node.body),
    'until ' .. condition,
  }, ' ')
end

function MultiLineRepeatUntil(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return table.concat({
    'repeat',
    formatNode(node.body),
    Line('until ' .. condition),
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

function Return(node)
  return 'return ' .. List(node, subColumnLimit('return '))
end

-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

function Self(node)
  if node.variant == 'self' then
    return '$'
  else
    return '$' .. node.value
  end
end

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

function Spread(node)
  return '...' .. (node.value and formatNode(node.value) or '')
end

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

function String(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

function Table(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

function SingleLineTryCatch(node)
  return table.concat({
    'try {',
    formatNode(node.try),
    '} catch (' .. formatNode(node.errorName) .. ') {',
    formatNode(node.catch),
    '}',
  }, ' ')
end

function MultiLineTryCatch(node)
  return table.concat({
    'try {',
    formatNode(node.try),
    Line('} catch (' .. formatNode(node.errorName) .. ') {'),
    formatNode(node.catch),
    Line('}'),
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

function SingleLineWhileLoop(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return table.concat({
    'while ' .. condition .. ' {',
    formatNode(node.body),
    '}',
  }, ' ')
end

function MultiLineWhileLoop(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return table.concat({
    'while ' .. condition .. ' {',
    formatNode(node.body),
    Line('}'),
  }, '\n')
end

-- =============================================================================
-- Format
-- =============================================================================

SINGLE_LINE_FORMATTERS = {
  ArrowFunction = ArrowFunction,
  Assignment = Assignment,
  Block = SingleLineBlock,
  Break = Break,
  Continue = Continue,
  Declaration = Declaration,
  Destructure = Destructure,
  DoBlock = SingleLineDoBlock,
  Expr = Expr,
  ForLoop = ForLoop,
  Function = Function,
  Goto = Goto,
  IfElse = IfElse,
  Module = Module,
  OptChain = OptChain,
  Params = Params,
  RepeatUntil = SingleLineRepeatUntil,
  Return = Return,
  Self = Self,
  Spread = Spread,
  String = String,
  Table = Table,
  TryCatch = SingleLineTryCatch,
  WhileLoop = SingleLineWhileLoop,
}

MULTI_LINE_FORMATTERS = {
  ArrowFunction = ArrowFunction,
  Assignment = Assignment,
  Block = MultiLineBlock,
  Break = Break,
  Continue = Continue,
  Declaration = Declaration,
  Destructure = Destructure,
  DoBlock = MultiLineDoBlock,
  Expr = Expr,
  ForLoop = ForLoop,
  Function = Function,
  Goto = Goto,
  IfElse = IfElse,
  Module = Module,
  OptChain = OptChain,
  Params = Params,
  RepeatUntil = MultiLineRepeatUntil,
  Return = Return,
  Self = Self,
  Spread = Spread,
  String = String,
  Table = Table,
  TryCatch = MultiLineTryCatch,
  WhileLoop = MultiLineWhileLoop,
}

return function(textOrAst, ...)
  local ast = type(textOrAst) == 'string' and parse(textOrAst, ...) or textOrAst
  reset()
  return formatNode(ast)
end
