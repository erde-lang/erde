local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare
local Comments, SUB_FORMATTERS

-- =============================================================================
-- State
-- =============================================================================

local ast, tokenData

-- The current indent level (depth)
local indentLevel

-- The precomputed indent whitespace string
local indentPrefix

-- Flag to force rules from generating newlines
local forceSingleLine

-- The precomputed available columns based on the column limit, current indent
-- level and line lead.
local availableColumns

-- =============================================================================
-- Configuration
-- =============================================================================

local indentWidth = 2
local columnLimit = 80
local quotePreference = 'single'

-- =============================================================================
-- Helpers
-- =============================================================================

local function indent(levelDiff)
  indentLevel = indentLevel + levelDiff
  indentPrefix = (' '):rep(indentLevel * indentWidth)
end

local function reserve(reservation)
  availableColumns = columnLimit
    - indentLevel * indentWidth
    - (type(reservation) == 'number' and reservation or #reservation)
end

local function use(state)
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = state.forceSingleLine or forceSingleLineBackup

  local availableColumnsBackup = availableColumns
  if state.reserve then
    reserve(state.reserve)
  end

  local indentLevelBackup = indentLevel
  local indentPrefixBackup = indentPrefix
  if state.indent then
    indent(state.indent)
  end

  return function()
    forceSingleLine = forceSingleLineBackup
    availableColumns = availableColumnsBackup
    indentLevel = indentLevelBackup
    indentPrefix = indentPrefixBackup
  end
end

local function formatNode(node, state)
  if type(node) == 'string' then
    return node
  elseif type(node) ~= 'table' then
    error(('Invalid node type (%s): %s'):format(type(node), tostring(node)))
  elseif type(SUB_FORMATTERS[node.ruleName]) ~= 'function' then
    error(('Invalid ruleName: %s'):format(node.ruleName))
  end

  local formatted = SUB_FORMATTERS[node.ruleName](node)

  if node.parens then
    formatted = '(' .. formatted .. ')'
  end

  formatted = Comments(node) .. formatted
  return formatted
end

-- =============================================================================
-- Macros
-- =============================================================================

function Comments(node)
  local formatted = {}
  local tokenIndexStart = node.tokenIndexStart or 0
  local precedingComments = tokenData.comments[tokenIndexStart - 1]

  if precedingComments then
    for i, precedingComment in ipairs(precedingComments) do
      local comment

      if not precedingComment.eq then
        comment = '--' .. precedingComment.token .. '\n'
      else
        comment = table.concat({
          '--[' .. precedingComment.eq .. '[',
          precedingComment.token,
          ']' .. precedingComment.eq .. ']',
        })
      end

      table.insert(formatted, comment)
    end
  end

  return table.concat(formatted)
end

local function Line(line)
  return (forceSingleLine and '' or indentPrefix) .. line
end

local function Lines(lines)
  return table.concat(lines, forceSingleLine and ' ' or '\n')
end

local function SingleLineList(nodes)
  local formatted = {}
  local restore = use({ forceSingleLine = true })

  for _, node in ipairs(nodes) do
    table.insert(formatted, formatNode(node))
  end

  restore()
  return table.concat(formatted, ', ')
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

local function Statements(node)
  local formatted = {}

  if forceSingleLine then
    for _, statement in ipairs(node) do
      table.insert(formatted, formatNode(statement))
    end
  else
    for _, statement in ipairs(node) do
      local tokenIndexStart = statement.tokenIndexStart

      if tokenIndexStart then
        local numPrecedingNewlines = tokenData.newlines[tokenIndexStart - 1]
          or 0

        if numPrecedingNewlines > 1 then
          table.insert(formatted, Line(''))
        end
      end

      table.insert(formatted, formatNode(statement))
    end
  end

  return formatted
end

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

local function ArrowFunction(node)
  local formatted = {
    formatNode(node.params),
    node.hasFatArrow and '=>' or '->',
  }

  if not node.hasImplicitReturns then
    table.insert(formatted, Lines({ '{', formatNode(node.body), '}' }))
  elseif #node.returns == 1 then
    table.insert(formatted, formatNode(node.returns[1]))
  else
    local singleLineReturns = SingleLineList(node.returns)

    if forceSingleLine or #singleLineReturns <= availableColumns then
      table.insert(formatted, singleLineReturns)
    else
      table.insert(formatted, MultiLineList(node.returns))
    end
  end

  return table.concat(formatted, ' ')
end

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

local function SingleLineAssignment(node)
  local formatted = {
    node.variant,
    SingleLineList(node.idList),
  }

  if #node.exprList > 0 then
    table.insert(formatted, (node.op and node.op.token or '') .. '=')
    table.insert(formatted, SingleLineList(node.exprList))
  end

  return table.concat(formatted, ' ')
end

local function MultiLineAssignment(node)
  local formatted = {}

  local hasMultiLineIdList = false
  local singleLineIdList = SingleLineList(node.idList)
  reserve(0)

  if #singleLineIdList < availableColumns then
    table.insert(formatted, singleLineIdList)
  else
    hasMultiLineIdList = true
    table.insert(formatted, MultiLineList(node.idList))
  end

  table.insert(formatted, '=')
  reserve(hasMultiLineIdList and ') = ' or (#table.concat(formatted, ' ') + 1))
  local singleLineExprList = SingleLineList(node.exprList)

  if #singleLineExprList <= availableColumns then
    table.insert(formatted, singleLineExprList)
  elseif #node.exprList == 1 then
    local formattedExpr = formatNode(node.exprList[1])

    if not hasMultiLineIdList and not formattedExpr:find('\n') then
      local prefix = '\n' .. (' '):rep(indentWidth * (indentLevel + 1))
      table.insert(formatted, prefix .. singleLineExprList)
    else
      table.insert(formatted, formattedExpr)
    end
  else
    table.insert(formatted, MultiLineList(node.exprList))
  end

  return table.concat(formatted, ' ')
end

local function Assignment(node)
  return forceSingleLine and SingleLineAssignment(node)
    or MultiLineAssignment(node)
end

-- -----------------------------------------------------------------------------
-- Binop
-- -----------------------------------------------------------------------------

local function SingleLineBinop(node)
  local restore = use({ forceSingleLine = true })

  local formatted = table.concat({
    formatNode(node.lhs),
    node.op.token,
    formatNode(node.rhs),
  }, ' ')

  restore()
  return formatted
end

local function MultiLineBinop(node)
  local lowestPrec = node.op.prec
  local binop = node

  local lowestPrecBinops = {}
  while binop.ruleName == 'Binop' and binop.op.prec == lowestPrec do
    table.insert(lowestPrecBinops, binop)
    binop = binop.lhs
  end

  local restore = use({ forceSingleLine = true })
  local formatted = { formatNode(lowestPrecBinops[#lowestPrecBinops].lhs) }

  -- Traverse backwards, since we populated using rhs!
  indent(1)
  for i = #lowestPrecBinops, 1, -1 do
    table.insert(
      formatted,
      table.concat({
        indentPrefix,
        lowestPrecBinops[i].op.token,
        ' ',
        formatNode(lowestPrecBinops[i].rhs),
      })
    )
  end
  indent(-1)

  return table.concat(formatted, '\n')
end

local function Binop(node)
  local singleLineBinop = SingleLineBinop(node)
  return (forceSingleLine or #singleLineBinop <= availableColumns)
      and singleLineBinop
    or MultiLineBinop(node)
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

local function Block(node)
  indent(1)
  local formatted = Statements(node)
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
  reserve(#node.variant + 1)

  if #singleLineVarList < availableColumns then
    table.insert(formatted, singleLineVarList)
  elseif #node.varList == 1 then
    local formattedVar = formatNode(node.varList[1])
    hasMultiLineVarList = formattedVar:find('\n')
    table.insert(formatted, formattedVar)
  else
    hasMultiLineVarList = true
    table.insert(formatted, MultiLineList(node.varList))
  end

  if #node.exprList > 0 then
    table.insert(formatted, '=')
    -- Use 4 for either ') = ' or '} = '
    reserve(hasMultiLineVarList and 4 or (#table.concat(formatted, ' ') + 1))

    local singleLineExprList = SingleLineList(node.exprList)

    if #singleLineExprList <= availableColumns then
      table.insert(formatted, singleLineExprList)
    elseif #node.exprList == 1 then
      local formattedExpr = formatNode(node.exprList[1])

      if not hasMultiLineVarList and not formattedExpr:find('\n') then
        local prefix = '\n' .. (' '):rep(indentWidth * (indentLevel + 1))
        table.insert(formatted, prefix .. singleLineExprList)
      else
        table.insert(formatted, formattedExpr)
      end
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
  local restore = use({ forceSingleLine = true })
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

  restore()
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

        local restore = use({ forceSingleLine = true, reserve = formatted })
        local singleLineDefault = formatNode(destruct.default)
        restore()

        if #singleLineDefault <= availableColumns then
          formatted = formatted .. singleLineDefault
        elseif #singleLineDefault <= availableColumns + indentWidth then
          local prefix = '\n' .. (' '):rep(indentWidth * (indentLevel + 1))
          formatted = formatted .. prefix .. singleLineDefault
        else
          local multiLineDefault = formatNode(destruct.default)

          if multiLineDefault:find('\n') then
            formatted = formatted .. formatNode(destruct.default)
          else
            local prefix = '\n' .. (' '):rep(indentWidth * (indentLevel + 1))
            formatted = formatted .. prefix .. multiLineDefault
          end
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
  elseif #numberDestructs == 0 then
    return '{ ' .. table.concat(keyDestructs, ', ') .. ' }'
  else
    return table.concat({
      '{ ',
      table.concat(keyDestructs, ', '),
      ', ',
      '[ ' .. table.concat(numberDestructs, ', ') .. ' ]',
      ' }',
    })
  end
end

local function MultiLineDestructure(node)
  local hasKeyDestruct, hasNumberDestruct = false, false

  for i, destruct in ipairs(node) do
    if destruct.variant == 'keyDestruct' then
      hasKeyDestruct = true
    else
      hasNumberDestruct = true
    end
  end

  if not hasKeyDestruct then
    local formatted = { '[' }
    indent(1)

    local numberDestructs = MultiLineDestructs(node, 'numberDestruct')
    for _, numberDestruct in ipairs(numberDestructs) do
      table.insert(formatted, Line(numberDestruct) .. ',')
    end

    indent(-1)
    table.insert(formatted, ']')
    return table.concat(formatted, '\n')
  else
    local formatted = { '{' }
    indent(1)
    reserve(0)

    local keyDestructs = MultiLineDestructs(node, 'keyDestruct')
    for _, keyDestruct in ipairs(keyDestructs) do
      table.insert(formatted, Line(keyDestruct) .. ',')
    end

    if hasNumberDestruct then
      local singleLineNumberDestructs = '[ '
        .. table.concat(SingleLineDestructs(node, 'numberDestruct'), ', ')
        .. ' ],'

      if #singleLineNumberDestructs <= availableColumns then
        table.insert(formatted, Line(singleLineNumberDestructs))
      else
        table.insert(formatted, '[')
        indent(1)

        local numberDestructs = MultiLineDestructs(node, 'numberDestruct')
        for _, numberDestruct in ipairs(numberDestructs) do
          table.insert(formatted, Line(numberDestruct) .. ',')
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
  return (forceSingleLine or #singleLineDestructure <= availableColumns)
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
  local formatted = (node.variant ~= 'local' and #node.names == 1)
      and node.variant .. ' function'
    or 'function'

  if #node.names == 1 then
    formatted = formatted .. ' ' .. node.names[1]
  else
    local formattedNames = { node.names[1] }

    for i = 2, #node.names - 1 do
      table.insert(formattedNames, '.' .. node.names[i])
    end

    table.insert(
      formattedNames,
      (node.isMethod and ':' or '.') .. node.names[#node.names]
    )

    formatted = formatted .. ' ' .. table.concat(formattedNames)
  end

  return formatted
    .. formatNode(node.params)
    .. ' '
    .. Lines({ '{', formatNode(node.body), Line('}') })
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
  local restore = use({ forceSingleLine = true })

  local ifCondition = formatNode(node.ifNode.condition)
  local elseifConditions = {}
  for _, elseifNode in ipairs(node.elseifNodes) do
    table.insert(elseifConditions, formatNode(elseifNode.condition))
  end

  restore()

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

  for _, statement in ipairs(Statements(node)) do
    table.insert(formatted, statement)
  end

  return table.concat(formatted, '\n')
end

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

local function OptChain(node)
  local restore = use({ forceSingleLine = true })
  local formattedParts = { formatNode(node.base) }

  for _, chain in ipairs(node) do
    local formattedChain = {}

    if chain.optional then
      table.insert(formattedChain, '?')
    end

    if chain.variant == 'dotIndex' then
      table.insert(formattedChain, '.' .. chain.value)
    elseif chain.variant == 'method' then
      table.insert(formattedChain, ':' .. chain.value)
    elseif chain.variant == 'bracketIndex' then
      table.insert(formattedChain, '[' .. formatNode(chain.value) .. ']')
    elseif chain.variant == 'functionCall' then
      local formattedArgs = {}

      for _, arg in ipairs(chain.value) do
        table.insert(formattedArgs, formatNode(arg))
      end

      table.insert(
        formattedChain,
        '(' .. table.concat(formattedArgs, ', ') .. ')'
      )
    end

    table.insert(formattedParts, table.concat(formattedChain))
  end

  restore()
  indent(1)

  local formatted = { formattedParts[1] }
  for i = 2, #formattedParts do
    -- Do not place function call chains on their own line, simply append to
    -- previous line.
    --
    -- Use i - 1 since the chain base is not included in ipairs
    if node[i - 1].variant == 'functionCall' then
      formatted[#formatted] = formatted[#formatted] .. formattedParts[i]
    else
      table.insert(formatted, Line(formattedParts[i]))
    end
  end

  indent(-1)
  return Lines(formatted)
end

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

local function Params(node)
  local restore = use({ forceSingleLine = true })

  local formatted = {}
  for _, param in ipairs(node) do
    local formattedParam = formatNode(param.value)

    if param.default then
      formattedParam = formattedParam .. ' = ' .. formatNode(param.default)
    end

    if param.varargs then
      formattedParam = '...' .. formattedParam
    end

    table.insert(formatted, formattedParam)
  end

  restore()
  return '(' .. table.concat(formatted, ', ') .. ')'
end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

local function RepeatUntil(node)
  local restore = use({ forceSingleLine = true })
  local condition = formatNode(node.condition)
  restore()

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
  reserve('return ')
  return (forceSingleLine or #singleLineReturns <= availableColumns)
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
  local formatted = {}
  local restore = use({ forceSingleLine = true })

  local quote = quotePreference == 'single' and "'" or "'"
  local unEscapeQuotes = false

  if node.variant ~= 'long' then
    local hasSingleQuoteContent = false
    local hasDoubleQuoteContent = false

    for _, part in ipairs(node) do
      if part.variant == 'content' then
        hasSingleQuoteContent = hasSingleQuoteContent or part.value:match("'")
        hasDoubleQuoteContent = hasDoubleQuoteContent or part.value:match('"')
      end
    end

    unEscapeQuotes = not (hasSingleQuoteContent and hasDoubleQuoteContent)
    if hasSingleQuoteContent ~= hasDoubleQuoteContent then
      quote = hasSingleQuoteContent and '"' or "'"
    end
  end

  for _, part in ipairs(node) do
    if part.variant == 'interpolation' then
      table.insert(formatted, '{' .. formatNode(part.value) .. '}')
    else
      table.insert(
        formatted,
        unEscapeQuotes and part.value:gsub([[\(['"])]], '%1') or part.value
      )
    end
  end

  restore()
  return quote .. table.concat(formatted) .. quote
end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

local function TableField(field)
  if field.variant == 'nameKey' then
    return field.key .. ' = ' .. formatNode(field.value)
  elseif field.variant == 'exprKey' then
    return '[ ' .. formatNode(field.key) .. ' ] = ' .. formatNode(field.value)
  elseif field.variant == 'numberKey' then
    return formatNode(field.value)
  elseif field.variant == 'spread' then
    return formatNode(field.value)
  end
end

local function SingleLineTable(fields)
  local formatted = {}
  local restore = use({ forceSingleLine = true })

  for _, field in ipairs(fields) do
    table.insert(formatted, TableField(field))
  end

  restore()
  return '{ ' .. table.concat(formatted, ', ') .. ' }'
end

local function MultiLineTable(fields)
  local formatted = { '{' }
  indent(1)

  for _, field in ipairs(fields) do
    table.insert(formatted, Line(TableField(field)) .. ',')
  end

  indent(-1)
  table.insert(formatted, Line('}'))
  return Lines(formatted)
end

local function Table(node)
  local sortedFields = {}
  local exprKeyFieldBuffer = {}
  local numberKeyFieldBuffer = {}

  for _, field in ipairs(node) do
    if field.variant == 'nameKey' then
      table.insert(sortedFields, field)
    elseif field.variant == 'exprKey' then
      table.insert(exprKeyFieldBuffer, field)
    elseif field.variant == 'numberKey' then
      table.insert(numberKeyFieldBuffer, field)
    elseif field.variant == 'spread' then
      -- Flush buffers. Do not want to change position of spread, as it may
      -- change structure of table.
      for _, bufferField in ipairs(exprKeyFieldBuffer) do
        table.insert(sortedFields, bufferField)
      end

      for _, bufferField in ipairs(numberKeyFieldBuffer) do
        table.insert(sortedFields, bufferField)
      end

      table.insert(sortedFields, field)
      exprKeyFieldBuffer = {}
      numberKeyFieldBuffer = {}
    end
  end

  for _, bufferField in ipairs(exprKeyFieldBuffer) do
    table.insert(sortedFields, bufferField)
  end

  for _, bufferField in ipairs(numberKeyFieldBuffer) do
    table.insert(sortedFields, bufferField)
  end

  local singleLineTable = SingleLineTable(sortedFields)
  return (forceSingleLine or #singleLineTable <= availableColumns)
      and singleLineTable
    or MultiLineTable(sortedFields)
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
  local restore = use({ forceSingleLine = true })
  local condition = formatNode(node.condition)
  restore()

  return Lines({
    'while ' .. condition .. ' {',
    formatNode(node.body),
    Line('}'),
  })
end

-- =============================================================================
-- Return
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

return function(text)
  ast, tokenData = parse(text)
  indentLevel = 0
  indentPrefix = ''
  forceSingleLine = false
  availableColumns = columnLimit

  return formatNode(ast)
end
