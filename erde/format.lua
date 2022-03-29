local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare rules
local ArrowFunction, Assignment, Block, Break, Continue, Declaration, Destructure, DoBlock, Expr, ForLoop, Function, Goto, IfElse, Module, OptChain, Params, RepeatUntil, Return, Self, Spread, String, Table, TryCatch, WhileLoop
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
  elseif type(SUB_FORMATTERS[node.ruleName]) ~= 'function' then
    error(('Invalid ruleName: %s'):format(node.ruleName))
  end

  local formatted = SUB_FORMATTERS[node.ruleName](node)
  return node.parens and '(' .. formatted .. ')' or formatted
end

-- =============================================================================
-- Macros
-- =============================================================================

local function Line(code)
  return linePrefix .. code
end

local function List(nodes, sep)
  local formattedNodes = {}

  for _, node in ipairs(nodes) do
    table.insert(formattedNodes, formatNode(node))
  end

  return sep and table.concat(formattedNodes, sep) or formattedNodes
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

function Block(node)
  indent(1)
  local formatted = List(node, '\n')
  indent(-1)
  return formatted
end

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

function Break(node)
  return Line('break')
end

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

function Continue(node)
  return Line('continue')
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

local function DeclarationList(nodes, limit)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local list = List(nodes, ', ')
  forceSingleLine = forceSingleLineBackup

  if #list <= limit then
    return list
  end

  local lines = { '(' }
  indent(1)

  for _, node in ipairs(nodes) do
    table.insert(lines, Line(formatNode(node)) .. ',')
  end

  table.insert(lines, ')')
  indent(-1)
  return table.concat(lines, '\n')
end

function Declaration(node)
  local formatted = {
    node.variant,
    DeclarationList(node.varList, subColumnLimit(node.variant, ' ')),
  }

  local exprList = ''
  if #node.exprList > 0 then
    table.insert(formatted, '=')

    local exprListColumnLimit = formatted[2]:sub(1, 1) == '('
        and subColumnLimit(') = ')
      or subColumnLimit(table.concat(formatted, ' '))

    table.insert(formatted, DeclarationList(node.exprList, exprListColumnLimit))
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

function DoBlock(node)
  return table.concat({
    Line('do {'),
    formatNode(node.body),
    Line('}'),
  }, forceSingleLine and ' ' or '\n')
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
        List(node.parts, ', '),
        '{',
      }, ' '))
    )
  else
    table.insert(
      formatted,
      Line(table.concat({
        'for',
        List(node.varList, ', '),
        'in',
        List(node.exprList, ', '),
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
    return Line('goto ' .. node.name)
  elseif node.variant == 'definition' then
    return Line('::' .. node.name .. '::')
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
  return table.concat(formatted, '\n')
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

function RepeatUntil(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return table.concat({
    Line('repeat'),
    formatNode(node.body),
    Line('until ' .. condition),
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

function Return(node)
  local exprList = List(node)
  local singleLineReturn = 'return ' .. table.concat(exprList, ', ')

  if forceSingleLine then
    return singleLineReturn
  elseif #singleLineReturn <= subColumnLimit() then
    return Line(singleLineReturn)
  end

  local lines = { Line('return (') }
  indent(1)

  for _, expr in ipairs(exprList) do
    table.insert(lines, Line(expr) .. ',')
  end

  indent(-1)
  table.insert(lines, Line(')'))
  return table.concat(lines, '\n')
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

function TryCatch(node)
  return table.concat({
    Line('try {'),
    formatNode(node.try),
    Line('} catch (' .. formatNode(node.errorName) .. ') {'),
    formatNode(node.catch),
    Line('}'),
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

function WhileLoop(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return table.concat({
    Line('while ' .. condition .. ' {'),
    formatNode(node.body),
    Line('}'),
  }, '\n')
end

-- =============================================================================
-- Format
-- =============================================================================

local format, formatMT = {}, {}
setmetatable(format, formatMT)

formatMT.__call = function(self, textOrAst)
  return format.Module(textOrAst)
end

SUB_FORMATTERS = {
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

  -- Pseudo-Rules
  -- Var = Var,
  -- Name = Name,
  -- Number = Number,
  -- Terminal = Terminal,
  FunctionCall = OptChain,
  Id = OptChain,
}

for name, subFormatter in pairs(SUB_FORMATTERS) do
  format[name] = function(textOrAst, ...)
    local ast = type(textOrAst) == 'string' and parse[name](textOrAst, ...)
      or textOrAst
    reset()
    return subFormatter(ast)
  end
end

return format
