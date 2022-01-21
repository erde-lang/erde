local C = require('erde.constants')
local rules = require('erde.rules')
local Tokenizer = require('erde.Tokenizer')

-- -----------------------------------------------------------------------------
-- Parser
-- -----------------------------------------------------------------------------

local Parser = setmetatable({}, {
  __call = function(self, text)
    local parser = { tokenizer = Tokenizer() }
    setmetatable(parser, { __index = self })

    if text ~= nil then
      parser:reset(text)
    end

    return parser
  end,
})

-- Allow calling all rule parsers directly from parser
for ruleName, ruleParser in pairs(rules.parse) do
  Parser[ruleName] = ruleParser
end

-- -----------------------------------------------------------------------------
-- Methods
-- -----------------------------------------------------------------------------

function Parser:reset(text)
  self.Tokenizer:reset(text)
  self.tokens = self.Tokenizer:tokenize()
  self.tokenIndex = 1
  self.token = self.tokens[1]
  self.blockDepth = 0

  -- Used to tell other rules whether the current expression is part of the
  -- ternary block. Required to know whether ':' should be parsed exclusively
  -- as a method accessor or also consider ternary ':'.
  self.isTernaryExpr = false

  -- Keeps track of the Block body of the closest loop ancestor (ForLoop,
  -- RepeatUntil, WhileLoop). This is used to validate and link Break and
  -- Continue statements.
  self.loopBlock = nil

  -- Keeps track of the top level Block. This is used to register module
  -- nodes when using the 'module' scope.
  self.moduleBlock = nil
end

function Parser:backup()
  return self.tokenIndex
end

function Parser:restore(backup)
  self.tokenIndex = backup
  self.token = self.tokens[backup]
end

function Parser:consume()
  local token = self.token

  self.tokenIndex = self.tokenIndex + 1
  self.token = self.tokens[self.tokenIndex]
  while self.token:match('^--*$') do
    -- Skip comments
    -- TODO
    self.tokenIndex = self.tokenIndex + 1
    self.token = self.tokens[self.tokenIndex]
  end

  return token
end

function Parser:peek()
  return self.tokens[self.tokenIndex + n]
end

function Parser:branch(branchToken)
  if self.token ~= branchToken then
    return false
  end

  self:consume()
  return true
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

function Parser:Try(rule)
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

function Parser:Switch(rules)
  for i, rule in ipairs(rules) do
    local node = self:Try(rule)
    if node then
      return node
    end
  end
end

function Parser:Surround(openChar, closeChar, rule)
  assert(self:consume() == openChar)
  local capture = rule(self)
  assert(self:consume() == closeChar)
  return capture
end

function Parser:Parens(opts)
  if opts.demand or self.token == '(' then
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

function Parser:List(opts)
  local list = {}
  local hasTrailingComma = false

  repeat
    local node = self:Try(opts.rule)
    if not node then
      break
    end

    hasTrailingComma = self:consume() == ','
    list[#list + 1] = node
  until not hasTrailingComma

  assert(opts.allowTrailingComma or not hasTrailingComma)
  assert(opts.allowEmpty or #list > 0)

  return list, hasTrailingComma
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Parser
