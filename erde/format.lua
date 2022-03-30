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

function Block(node)
  indent(1)
  local formatted = formatNodes(node, '\n')
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

function RepeatUntil(node)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true
  local condition = formatNode(node.condition)
  forceSingleLine = forceSingleLineBackup

  return table.concat({
    Line('repeat'),
    formatNode(node.body),
    Line('until ' .. condition),
  }, forceSingleLine and ' ' or '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

function Return(node)
  local formatted = 'return ' .. List(node, subColumnLimit('return '))
  return forceSingleLine and formatted or Line(formatted)
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
  }, forceSingleLine and ' ' or '\n')
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
  }, forceSingleLine and ' ' or '\n')
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
