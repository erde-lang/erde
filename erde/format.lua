local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare
local SUB_FORMATTERS

-- =============================================================================
-- State
-- =============================================================================

local indentLevel, indentPrefix
local forceSingleLine
local columnOffset

-- =============================================================================
-- Configuration
-- =============================================================================

local indentWidth = 2
local columnLimit = 80

-- =============================================================================
-- Helpers
-- =============================================================================

local function reset(node)
  indentLevel = 0
  indentPrefix = ''
  forceSingleLine = false
  columnOffset = 0
end

local function use(state)
  local forceSingleLineBackup = forceSingleLine

  forceSingleLine = state.forceSingleLine or forceSingleLineBackup

  return function()
    forceSingleLine = forceSingleLineBackup
  end
end

local function indent(levelDiff)
  indentLevel = indentLevel + levelDiff
  indentPrefix = (' '):rep(indentLevel * indentWidth)
end

local function offsetColumn(offset)
  columnOffset = indentLevel * indentWidth
    + (type(offset) == 'number' and offset or #offset)
end

local function fits(line)
  return #line <= columnLimit - columnOffset
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

local function Line(line)
  return (forceSingleLine and '' or indentPrefix) .. line
end

local function Lines(lines)
  return table.concat(lines, forceSingleLine and ' ' or '\n')
end

local function SingleLineList(nodes)
  local revert = use({ forceSingleLine = true })
  local formatted = formatNodes(nodes, ', ')
  revert()
  return formatted
end

local function MultiLineList(nodes)
  local formatted = { '(' }
  indent(1)

  for _, node in ipairs(nodes) do
    table.insert(formatted, Line(formatNode(node)) .. ',')
  end

  indent(-1)
  table.insert(formatted, Line(')'))
  return Lines(formatted)
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
-- Binop
-- -----------------------------------------------------------------------------

local function Binop(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local function Block(node)
  local formatted = {}
  indent(1)

  for _, statement in ipairs(node) do
    table.insert(formatted, Line(formatNode(statement)))
  end

  indent(-1)
  return Lines(formatted)
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

  local hasMultiLineVarList = false
  local singleLineVarList = SingleLineList(node.varList)
  offsetColumn(#node.variant + 1)

  if fits(singleLineVarList) then
    table.insert(formatted, singleLineVarList)
  elseif #node.varList == 1 then
    hasMultiLineVarList = type(node.varList[1]) ~= 'string'
    table.insert(formatted, formatNode(node.varList[1]))
  else
    hasMultiLineVarList = true
    table.insert(formatted, MultiLineList(node.varList))
  end

  if #node.exprList > 0 then
    table.insert(formatted, '=')

    local singleLineExprList = SingleLineList(node.exprList)
    offsetColumn( -- Use 4 for either ') = ' or '} = '
      hasMultiLineVarList and 4 or (#table.concat(formatted, ' ') + 1)
    )

    if fits(singleLineExprList) then
      table.insert(formatted, singleLineExprList)
    elseif
      not hasMultiLineVarList
      and #singleLineExprList <= indentWidth * (indentLevel + 1)
    then
      table.insert(formatted, '\n' .. singleLineExprList)
    elseif #node.exprList == 1 then
      table.insert(formatted, formatNode(node.exprList[1]))
    else
      table.insert(formatted, MultiLineList(node.exprList))
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

local function SingleLineDestructs(node, variant)
  local destructs = {}

  for _, destruct in ipairs(node) do
    if destruct.variant == variant then
      local formatted = destruct.name

      if destruct.alias then
        formatted = formatted .. ': ' .. destruct.alias
      end

      if destruct.default then
        formatted = formatted .. ' = ' .. formatNode(destruct.default)
      end

      table.insert(destructs, formatted)
    end
  end

  return destructs
end

local function MultiLineDestructs(node, variant)
  local destructs = {}

  for _, destruct in ipairs(node) do
    if destruct.variant == variant then
      local formatted = destruct.name

      if destruct.alias then
        formatted = formatted .. ': ' .. destruct.alias
      end

      if destruct.default then
        formatted = formatted .. ' = '

        local revert = use({ forceSingleLine = true })
        offsetColumn(formatted)
        local singleLineDefault = formatNode(destruct.default)
        revert()

        if fits(singleLineDefault) then
          formatted = formatted .. singleLineDefault
        elseif
          #singleLineDefault <= columnLimit - indentWidth * (indentLevel + 1)
        then
          formatted = formatted .. '\n' .. singleLineDefault
        else
          formatted = formatted .. formatNode(destruct.default)
        end
      end

      table.insert(destructs, formatted)
    end
  end

  return destructs
end

local function SingleLineDestructure(node)
  local keyDestructs = SingleLineDestructs(node, 'keyDestruct')
  local numberDestructs = SingleLineDestructs(node, 'numberDestruct')

  if #keyDestructs == 0 then
    return '[ ' .. table.concat(numberDestructs, ', ') .. ' ]'
  end

  local formatted = { '{', table.concat(keyDestructs, ', ') }

  if #numberDestructs > 0 then
    table.insert(
      formatted,
      ', ' .. '[ ' .. table.concat(numberDestructs, ', ') .. ' ]'
    )
  end

  table.insert(formatted, '}')
  return table.concat(formatted, ' ')
end

local function MultiLineDestructure(node)
  local keyDestructs = MultiLineDestructs(node, 'keyDestruct')

  if #keyDestructs == 0 then
    local formatted = { '[' }
    indent(1)

    local numberDestructs = MultiLineDestructs(node, 'numberDestruct')
    for _, numberDestruct in ipairs(numberDestructs) do
      table.insert(formatted, Line(numberDestruct))
    end

    indent(-1)
    table.insert(formatted, ']')
    return table.concat(formatted, '\n')
  else
    local formatted = { '{' }
    indent(1)

    for _, keyDestruct in ipairs(keyDestructs) do
      table.insert(formatted, Line(keyDestruct))
    end

    if #numberDestructs > 0 then
      local numberDestructs = SingleLineDestructs(node, 'numberDestruct')
      if #numberDestructs <= columnLimit - indentWidth * (indentLevel + 1) then
        table.insert(formatted, numberDestructs)
      else
        local formatted = { '[' }
        indent(1)

        local numberDestructs = MultiLineDestructs(node, 'numberDestruct')
        for _, numberDestruct in ipairs(numberDestructs) do
          table.insert(formatted, Line(numberDestruct))
        end

        indent(-1)
        table.insert(formatted, ']')
      end
    end

    indent(-1)
    table.insert(formatted, '}')
    return table.concat(formatted, '\n')
  end
end

local function Destructure(node)
  local singleLineDestructure = SingleLineDestructure(node)
  return (forceSingleLine or fits(singleLineDestructure))
      and singleLineDestructure
    or MultiLineDestructure(node)
end

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

local function DoBlock(node)
  return Lines({ 'do {', formatNode(node.body), Line('}') })
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

  table.insert(formatted, formatNode(node.body))
  table.insert(formatted, Line('}'))
  return Lines(formatted)
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
  local revert = use({ forceSingleLine = true })

  local ifCondition = formatNode(node.ifNode.condition)
  local elseifConditions = {}
  for _, elseifNode in ipairs(node.elseifNodes) do
    table.insert(elseifConditions, formatNode(elseifNode.condition))
  end

  revert()

  local formatted = {
    'if ' .. ifCondition .. ' {',
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
  return Lines(formatted)
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
  local revert = use({ forceSingleLine = true })
  local condition = formatNode(node.condition)
  revert()

  return Lines({
    'repeat',
    formatNode(node.body),
    Line('until ' .. condition),
  })
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

local function Return(node)
  local singleLineReturns = SingleLineList(node)
  offsetColumn('return ')
  return (forceSingleLine or fits(singleLineReturns))
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
  return Lines({
    'try {',
    formatNode(node.try),
    Line('} catch (' .. (node.errorName or '') .. ') {'),
    formatNode(node.catch),
    Line('}'),
  })
end

-- -----------------------------------------------------------------------------
-- Unop
-- -----------------------------------------------------------------------------

local function Unop(node)
  return node.op.token .. formatNode(node.operand)
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

local function WhileLoop(node)
  local revert = use({ forceSingleLine = true })
  local condition = formatNode(node.condition)
  revert()

  return Lines({
    'while ' .. condition .. ' {',
    formatNode(node.body),
    Line('}'),
  })
end

-- =============================================================================
-- Format
-- =============================================================================

SUB_FORMATTERS = {
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

return function(textOrAst, ...)
  local ast = type(textOrAst) == 'string' and parse(textOrAst, ...) or textOrAst
  reset()
  return formatNode(ast)
end
