local C = require('erde.constants')
local tokenize = require('erde.format_tokenize')

-- Foward declare rules
local ArrowFunction, Assignment, Binop, Block, Break, Continue, Declaration, Destructure, DoBlock, ForLoop, Function, Goto, IfElse, Module, OptChain, Params, RepeatUntil, Return, Self, Spread, String, Table, TryCatch, Unop, WhileLoop
local Comments

-- =============================================================================
-- State
-- =============================================================================

local tokens, tokenInfo, newlines
local currentTokenIndex, currentToken

local inlineComment, lineComments, commentNewline

-- TODO: docs
local orphanedComments

-- Used to tell other rules whether the current expression is part of the
-- ternary block. Required to know whether ':' should be parsed exclusively
-- as a method accessor or also consider ternary ':'.
local isTernaryExpr

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

local function backup()
  return {
    currentTokenIndex = currentTokenIndex,
    currentToken = currentToken,
    inlineComment = inlineComment,
    lineComments = lineComments,
    commentNewline = commentNewline,
    orphanedComments = orphanedComments,
    isTernaryExpr = isTernaryExpr,
    indentLevel = indentLevel,
    indentPrefix = indentPrefix,
    forceSingleLine = forceSingleLine,
    availableColumns = availableColumns,
  }
end

local function restore(state)
  currentTokenIndex = state.currentTokenIndex
  currentToken = state.currentToken
  inlineComment = state.inlineComment
  lineComments = state.lineComments
  commentNewline = state.commentNewline
  orphanedComments = state.orphanedComments
  isTernaryExpr = state.isTernaryExpr
  indentLevel = state.indentLevel
  indentPrefix = state.indentPrefix
  forceSingleLine = state.forceSingleLine
  availableColumns = state.availableColumns
end

local function consume()
  if inlineComment then
    table.insert(orphanedComments, inlineComment)
    inlineComment = nil
  end

  if lineComments then
    for i, lineComment in pairs(lineComments) do
      table.insert(orphanedComments, lineComment)
    end
  end

  local consumedToken = tokens[currentTokenIndex]
  currentTokenIndex = currentTokenIndex + 1
  currentToken = tokens[currentTokenIndex]

  if currentToken == '--' then
    local prevTokenInfo = tokenInfo[currentTokenIndex - 1]
    local currentTokenInfo = tokenInfo[currentTokenIndex]

    if prevTokenInfo.line == currentTokenInfo.line then
      inlineComment = '-- ' .. tokens[currentTokenIndex + 1]
      currentTokenIndex = currentTokenIndex + 2
      currentToken = tokens[currentTokenIndex]
    end

    if currentToken == '--' then
      commentNewline = (newlines[currentTokenIndex - 1] or 0) > 1
      lineComments = {}

      repeat
        table.insert(lineComments, '-- ' .. tokens[currentTokenIndex + 1])
        currentTokenIndex = currentTokenIndex + 2
        currentToken = tokens[currentTokenIndex]
      until currentToken ~= '--'
    end
  end

  return consumedToken
end

local function expect(token, skipConsume)
  if token ~= currentToken then
    error('Expected ' .. token .. ' got ' .. tostring(currentToken))
  elseif not skipConsume then
    return consume()
  end
end

local function branch(token)
  if token == currentToken then
    consume()
    return true
  else
    return false
  end
end

local function indent(levelDiff)
  indentLevel = indentLevel + levelDiff
  indentPrefix = (' '):rep(indentLevel * indentWidth)
end

local function reserve(reservation)
  availableColumns = columnLimit
    - indentLevel * indentWidth
    - (type(reservation) == 'number' and reservation or #reservation)
end

-- =============================================================================
-- Macros
-- =============================================================================

local function Try(rule)
  local state = backup()
  local ok, node = pcall(rule)

  if ok then
    return node
  else
    restore(state)
  end
end

local function Switch(rules)
  for i, rule in ipairs(rules) do
    local node = Try(rule)
    if node then
      return node
    end
  end
end

local function Surround(openChar, closeChar, callback)
  expect(openChar)
  local formatted = callback()
  expect(closeChar)
  return formatted
end

local function Parens(opts)
  if currentToken ~= '(' and not opts.demand then
    return opts.parse()
  else
    opts.demand = false

    if opts.prioritizeRule then
      local node = Try(opts.parse)
      if node then
        return node
      end
    end

    return Surround('(', ')', function()
      return opts.allowRecursion and Parens(opts) or opts.parse()
    end)
  end
end

local function List(opts)
  local list = {}
  local hasTrailingComma = false

  repeat
    local node = Try(opts.parse)
    if not node then
      break
    end

    hasTrailingComma = branch(',')
    table.insert(list, node)
  until not hasTrailingComma

  assert(opts.allowTrailingComma or not hasTrailingComma)
  assert(opts.allowEmpty or #list > 0)

  return list
end

local function Line(line)
  local formatted = (forceSingleLine and '' or indentPrefix) .. line

  if inlineComment then
    formatted = formatted .. ' ' .. inlineComment
    inlineComment = nil
  end

  return formatted
end

local function Chunk(formatter)
  local state = backup()

  local formatted = { Comments() }
  local orphanedCommentsBackup = orphanedComments
  orphanedComments = {}

  if (newlines[currentTokenIndex - 1] or 0) > 1 then
    table.insert(formatted, '')
  end

  local chunk = formatter()

  if not chunk then
    restore(state)
    return nil
  elseif #orphanedComments > 0 then
    table.insert(formatted, table.concat(orphanedComments, '\n'))
  end

  orphanedComments = orphanedCommentsBackup
  table.insert(formatted, Line(chunk))
  return table.concat(formatted, '\n')
end

-- =============================================================================
-- Pseudo Rules
-- =============================================================================

function Comments()
  if not inlineComment and not lineComments then
    return nil
  end

  local formatted = {}

  if commentNewline then
    table.insert(formatted, '')
    commentNewline = false
  end

  if inlineComment then
    table.insert(formatted, indentPrefix .. inlineComment)
    inlineComment = nil
  end

  if lineComments then
    for i, comment in ipairs(lineComments) do
      table.insert(formatted, indentPrefix .. comment)
    end

    lineComments = nil
  end

  return table.concat(formatted, '\n')
end

local function BraceBlock()
  local formatted = { Line(expect('{')) }

  indent(1)
  table.insert(formatted, Block())
  indent(-1)

  table.insert(formatted, Line(expect('}')))
  return table.concat(formatted, '\n')
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

local function Var()
  return (currentToken == '{' or currentToken == '[') and Destructure()
    or Name()
end

local function Terminal()
  for _, terminal in pairs(C.TERMINALS) do
    if branch(terminal) then
      return terminal
    end
  end

  local node
  if currentToken == '(' then
    -- Also takes care of parenthesized expressions, since OptChain will unpack
    -- any trivial OptChainBase
    node = Switch({ ArrowFunction, OptChain })
  elseif currentToken == 'do' then
    node = expect('do') .. ' ' .. BraceBlock()
  elseif currentToken:match('^.?[0-9]') then
    -- Only need to check first couple chars, rest is token care of by tokenizer
    node = consume()
  elseif currentToken:match('^[\'"]$') or currentToken:match('^%[[[=]') then
    node = String()
  else
    -- Check ArrowFunction before Table for implicit params + destructure
    node = Switch({ ArrowFunction, Table, OptChain })
  end

  if not node then
    error('Unexpected token ' .. currentToken)
  end

  return node
end

local function Expr(opts)
  local minPrec = opts and opts.minPrec or 1
  local tokenIndexStart = currentTokenIndex
  local node = C.UNOPS[currentToken] and Unop() or Terminal()

  local binop = C.BINOPS[currentToken]
  while binop and binop.prec >= minPrec do
    node = Binop({
      minPrec = minPrec,
      lhs = node,
    })

    binop = C.BINOPS[currentToken]
  end

  return node
end

local function FunctionCall()
  local node = OptChain()
  local last = node[#node]

  if not last or last.variant ~= 'functionCall' then
    error('Missing function call parentheses')
  end

  return node
end

local function Id()
  local node = OptChain()
  local last = node[#node]

  if last and last.variant == 'functionCall' then
    error('Unexpected function call')
  end

  return node
end

local function Statement()
  -- TODO: order these by usage for speed?
  if currentToken == 'break' or currentToken == 'continue' then
    return consume()
  elseif currentToken == 'goto' or currentToken == ':' then
    return Goto()
  elseif currentToken == 'do' then
    return expect('do') .. ' ' .. BraceBlock()
  elseif currentToken == 'if' then
    return IfElse()
  elseif currentToken == 'for' then
    return ForLoop()
  elseif currentToken == 'repeat' then
    return RepeatUntil()
  elseif currentToken == 'return' then
    return Return()
  elseif currentToken == 'try' then
    return TryCatch()
  elseif currentToken == 'while' then
    return WhileLoop()
  elseif currentToken == 'function' then
    return Function()
  elseif
    currentToken == 'local'
    or currentToken == 'global'
    or currentToken == 'module'
    or currentToken == 'main'
  then
    -- TODO: cannot use lookAhead, what about comments?
    -- return lookAhead(1) == 'function' and Function() or Declaration()
  else
    return Switch({ FunctionCall, Assignment })
  end
end

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

function ArrowFunction() end

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

function Assignment() end

-- -----------------------------------------------------------------------------
-- Binop
-- -----------------------------------------------------------------------------

function Binop(opts) end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block()
  local formatted = {}

  repeat
    local chunk = Chunk(Statement)
    table.insert(formatted, chunk)
  until not chunk

  table.insert(formatted, Comments())
  return table.concat(formatted, '\n')
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

function Declaration() end

-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

function Destructure() end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

function ForLoop() end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

function Function() end

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

function Goto()
  if branch('goto') then
    return 'goto ' .. Name()
  else
    expect(':')
    expect(':')
    local name = Name()
    expect(':')
    expect(':')
    return '::' .. name .. '::'
  end
end

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

function IfElse() end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

function Module()
  local formatted = {}

  if currentToken:match('^#!') then
    table.insert(formatted, consume())
  end

  while currentToken == '--' do
    table.insert(formatted, '-- ' .. tokens[currentTokenIndex + 1])
    currentTokenIndex = currentTokenIndex + 2
    currentToken = tokens[currentTokenIndex]
  end

  table.insert(formatted, Block())
  return table.concat(formatted, '\n')
end

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

function OptChain() end

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

function Params(opts) end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

function RepeatUntil() end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

function Return() end

-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

function Self() end

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

function Spread() end

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

function String() end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

function Table() end

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

function TryCatch() end

-- -----------------------------------------------------------------------------
-- Unop
-- -----------------------------------------------------------------------------

function Unop() end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

function WhileLoop() end

-- =============================================================================
-- Return
-- =============================================================================

return function(text)
  tokens, tokenInfo, newlines = tokenize(text)
  currentTokenIndex = 1
  currentToken = tokens[1]

  isTernaryExpr = false
  indentLevel = 0
  indentPrefix = ''
  forceSingleLine = false
  availableColumns = columnLimit

  return Module(text)
end
