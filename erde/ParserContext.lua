local Environment = require('erde.Environment')
local constants = require('erde.constants')
local rules = require('erde.rules')

-- -----------------------------------------------------------------------------
-- ParserContext
-- -----------------------------------------------------------------------------

local ParserContext = {}
local ParserContextMT = { __index = ParserContext }

for name, rule in pairs(rules) do
  ParserContext[name] = function(self, ...)
    self:Space()
    local node = rule.parse(self, ...)
    self:Space()
    return node
  end
end

function ParserContext:load(input)
  self.buffer = {}
  for i = 1, #input do
    self.buffer[i] = input:sub(i, i)
  end
  self.buffer[#self.buffer + 1] = constants.EOF

  self.bufIndex = 1
  self.bufValue = self.buffer[self.bufIndex]
  self.line = 1
  self.column = 1
end

function ParserContext:parse(input)
  self:load(input)
  return self.Block.parse(self)
end

function ParserContext:backup()
  return {
    bufIndex = self.bufIndex,
    bufValue = self.bufValue,
    line = self.line,
    column = self.column,
  }
end

function ParserContext:restore(backup)
  self.bufIndex = backup.bufIndex
  self.bufValue = backup.bufValue
  self.line = backup.line
  self.column = backup.column
end

-- -----------------------------------------------------------------------------
-- Error Handling
-- -----------------------------------------------------------------------------

function ParserContext:getErrorToken()
  if constants.ALNUM[self.bufValue] then
    local word = {}

    while constants.ALNUM[self.bufValue] do
      self:consume(1, word)
    end

    return table.concat(word)
  elseif self.bufValue == constants.EOF then
    return 'EOF'
  else
    return self.bufValue
  end
end

function ParserContext:throwError(msg)
  error(('Error (Line %d, Col %d): %s'):format(self.line, self.column, msg))
end

function ParserContext:throwExpected(expectation, noLiteral)
  local msgFormat = 'Expected '
    .. (noLiteral and '%s' or '`%s`')
    .. ', got `%s`'
  self:throwError(msgFormat:format(expectation, self:getErrorToken()))
end

function ParserContext:throwUnexpected()
  self:throwError(('Unexpected token %s'):format(self:getErrorToken()))
end

-- -----------------------------------------------------------------------------
-- Parsing Helpers
-- -----------------------------------------------------------------------------

function ParserContext:consume(n, capture)
  n = n or 1

  if type(capture) == 'table' then
    for i = 0, n - 1 do
      capture[#capture + 1] = self.buffer[self.bufIndex + i]
    end
  end

  for i = 1, n do
    if self.bufValue == constants.EOF then
      self:throwUnexpected()
    end

    self.bufIndex = self.bufIndex + 1
    self.bufValue = self.buffer[self.bufIndex]

    if self.bufValue == constants.Newline then
      self.line = self.line + 1
      self.column = 1
    else
      self.column = self.column + 1
    end
  end
end

function ParserContext:peek(n)
  local word = { self.bufValue }

  for i = 1, n - 1 do
    local char = self.buffer[self.bufIndex + i]

    if not char or char == constants.EOF then
      break
    end

    word[#word + 1] = char
  end

  return table.concat(word)
end

function ParserContext:stream(lookupTable, capture, demand)
  if demand and not lookupTable[self.bufValue] then
    error('unexpected value')
  end

  while lookupTable[self.bufValue] do
    self:consume(1, capture)
  end
end

function ParserContext:branch(n, isBranch, noPad, capture)
  if not noPad then
    self:Space()
  end

  if isBranch then
    self:consume(n, capture)
  end

  if not noPad then
    self:Space()
  end

  return isBranch
end

function ParserContext:branchChar(char, noPad, capture)
  if #char == 1 then
    -- Slight optimization for most common case
    return self:branch(1, self.bufValue == char, noPad, capture)
  else
    -- DO NOT USE FIND. It takes regex and will cause errors if we pass tokens
    -- such as '.'
    local found = false
    for i = 1, #char do
      if char:sub(i, i) == self.bufValue then
        found = true
        break
      end
    end

    return self:branch(1, found, noPad, capture)
  end
end

function ParserContext:branchStr(str, noPad, capture)
  return self:branch(#str, self:peek(#str) == str, noPad, capture)
end

function ParserContext:branchWord(word, capture)
  local trailingChar = self.buffer[self.bufIndex + #word]
  return not constants.ALNUM[trailingChar]
    and self:branchStr(word, false, capture)
end

-- -----------------------------------------------------------------------------
-- Parsing Macros
-- -----------------------------------------------------------------------------

function ParserContext:Space()
  while constants.WHITESPACE[self.bufValue] do
    self:consume()
  end
end

function ParserContext:Surround(openChar, closeChar, rule)
  if not self:branchChar(openChar) then
    self:throwExpected(openChar)
  end

  local capture = rule(self)

  if not self:branchChar(closeChar) then
    self:throwExpected(closeChar)
  end

  return capture
end

function ParserContext:Try(rule)
  local backup = self:backup()
  local ok, node = pcall(function()
    return rule(self)
  end)

  if ok then
    return node
  else
    self:restore(backup)
  end
end

function ParserContext:Switch(rules)
  for i, rule in ipairs(rules) do
    local node = self:Try(rule)
    if node then
      return node
    end
  end
end

function ParserContext:Op(opMap, opMaxLen)
  for i = opMaxLen, 1, -1 do
    local op = opMap[self:peek(i)]
    if op then
      return op
    end
  end
end

function ParserContext:Unop()
  return self:Op(constants.UNOP_MAP, constants.UNOP_MAX_LEN)
end

function ParserContext:Binop()
  return self:Op(constants.BINOP_MAP, constants.BINOP_MAX_LEN)
end

function ParserContext:ListCore(opts)
  local list = {}

  repeat
    local node = self:Try(opts.rule or self.Expr)

    if not node and not opts.allowTrailingComma then
      self:throwExpected('expression', true)
    end

    list[#list + 1] = node
  until not node or not self:branchChar(',')

  if not opts.allowEmpty and #list == 0 then
    self:throwError('list cannot be empty')
  end

  return list
end

function ParserContext:List(opts)
  if opts.parens == false then
    return self:ListCore(opts)
  elseif opts.parens == true then
    return self:Surround('(', ')', function()
      return self:ListCore(opts)
    end)
  elseif not self:branchChar('(') then
    return self:ListCore(opts)
  else
    local list = self:List(opts)

    if not self:branchChar(')') then
      self:throwExpected(')')
    end

    return list
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function()
  return setmetatable({
    buffer = {},
    bufIndex = 1,
    bufValue = 0,
    line = 1,
    column = 1,
  }, ParserContextMT)
end
