local C = require('erde.constants')
local rules = require('erde.rules')
local tokenize = require('erde.tokenize')

-- -----------------------------------------------------------------------------
-- Context
-- -----------------------------------------------------------------------------

local ctx = {}

function ctx:backup()
  return self.tokenIndex
end

function ctx:restore(backup)
  self.tokenIndex = backup
  self.token = self.tokens[backup]
end

function ctx:consume()
  local token = self.token
  self.tokenIndex = self.tokenIndex + 1
  self.token = self.tokens[self.tokenIndex]
  return token
end

function ctx:branch(branchToken)
  if self.token ~= branchToken then
    return false
  end

  self:consume()
  return true
end

-- -----------------------------------------------------------------------------
-- Context Macros
-- -----------------------------------------------------------------------------

-- Allow calling all rule parsers directly from context
for ruleName, parser in pairs(rules.parse) do
  ctx[ruleName] = parser
end

function ctx:Try(rule)
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

function ctx:Switch(rules)
  for i, rule in ipairs(rules) do
    local node = self:Try(rule)
    if node then
      return node
    end
  end
end

function ctx:Surround(openChar, closeChar, rule)
  assert(self:consume() == openChar)
  local capture = rule(self)
  assert(self:consume() == closeChar)
  return capture
end

function ctx:Parens(opts)
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

function ctx:List(opts)
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
-- Parse
-- -----------------------------------------------------------------------------

return function(input)
  ctx.tokens = tokenize(input)
  ctx.tokenIndex = 1
  ctx.token = ctx.tokens[1]
  ctx.blockDepth = 0

  -- Used to tell other rules whether the current expression is part of the
  -- ternary block. Required to know whether ':' should be parsed exclusively
  -- as a method accessor or also consider ternary ':'.
  ctx.isTernaryExpr = false

  -- Keeps track of the Block body of the closest loop ancestor (ForLoop,
  -- RepeatUntil, WhileLoop). This is used to validate and link Break and
  -- Continue statements.
  ctx.loopBlock = nil

  -- Keeps track of the top level Block. This is used to register module
  -- nodes when using the 'module' scope.
  ctx.moduleBlock = nil

  return ctx:Block()
end
