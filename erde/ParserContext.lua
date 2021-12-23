local constants = require('erde.constants')
local rules = require('erde.rules')

-- -----------------------------------------------------------------------------
-- ParserContext
-- -----------------------------------------------------------------------------

local ParserContext = {}
local ParserContextMT = { __index = ParserContext }

for ruleName, parser in pairs(rules.parse) do
  ParserContext[ruleName] = parser
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

  self.stdNames = {}
  self.loopBlock = nil
  self.moduleBlock = nil
end

function ParserContext:backup()
  return {
    bufIndex = self.bufIndex,
    bufValue = self.bufValue,
    line = self.line,
    column = self.column,
    loopBlock = self.loopBlock,
    moduleBlock = self.moduleBlock,
  }
end

function ParserContext:restore(backup)
  self.bufIndex = backup.bufIndex
  self.bufValue = backup.bufValue
  self.line = backup.line
  self.column = backup.column
  self.loopBlock = backup.loopBlock
  self.moduleBlock = backup.moduleBlock
end

function ParserContext:throw(err)
  local line = err.line or self.line
  local column = err.column or self.column
  error(('Error (Line %d, Col %d): %s'):format(line, column, err.msg))
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
      error()
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
    error()
  end

  while lookupTable[self.bufValue] do
    self:consume(1, capture)
  end
end

function ParserContext:branchChar(char, opts)
  opts = opts or {}

  if opts.pad ~= false then
    self:Space()
  end

  if self.bufValue ~= char then
    return false
  end

  self:consume(1, opts.capture)

  if opts.pad ~= false then
    self:Space()
  end

  return true
end

function ParserContext:branchStr(str, opts)
  opts = opts or {}

  if opts.pad ~= false then
    self:Space()
  end

  if self:peek(#str) ~= str then
    return false
  end

  self:consume(#str, opts.capture)

  if opts.pad ~= false then
    self:Space()
  end

  return true
end

function ParserContext:branchWord(word, opts)
  local trailingChar = self.buffer[self.bufIndex + #word]
  return not constants.ALNUM[trailingChar] and self:branchStr(word, opts)
end

function ParserContext:assertChar(char, opts)
  if not self:branchChar(char, opts) then
    error()
  end
end

function ParserContext:assertStr(str, opts)
  if not self:branchStr(str, opts) then
    error()
  end
end

function ParserContext:assertWord(word, opts)
  if not self:branchWord(word, opts) then
    error()
  end
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
    error()
  end

  local capture = rule(self)

  if not self:branchChar(closeChar) then
    error()
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
  for i, opToken in ipairs(constants.OP_BLACKLIST) do
    if self:peek(#opToken) == opToken then
      return nil
    end
  end

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

function ParserContext:Parens(opts)
  if opts.demand or self.bufValue == '(' then
    opts.demand = false

    if opts.prioritizeRule then
      local node = self:Try(opts.rule)
      if node then
        return node
      end
    end

    return self:Surround('(', ')', function()
      return opts.allowRecursion and self:Parens(opts) or opts.rule(self)
    end)
  else
    return opts.rule(self)
  end
end

function ParserContext:List(opts)
  local list = {}
  local hasTrailingComma = false

  repeat
    local node = self:Try(opts.rule)
    if not node then
      break
    end

    hasTrailingComma = self:branchChar(',')
    list[#list + 1] = node
  until not hasTrailingComma

  if #list > 0 and hasTrailingComma and not opts.allowTrailingComma then
    error()
  end

  if #list == 0 and not opts.allowEmpty then
    error()
  end

  return list, hasTrailingComma
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

    -- Keeps track of the referenced erdestd calls.
    stdNames = {},

    -- Keeps track of the Block body of the closest loop ancestor (ForLoop,
    -- RepeatUntil, WhileLoop). This is used to validate and link Break and
    -- Continue statements.
    loopBlock = nil,

    -- Keeps track of the top level Block. This is used to register module
    -- nodes when using the 'module' scope.
    moduleBlock = nil,
  }, ParserContextMT)
end
