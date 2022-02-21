local C = require('erde.constants')
local rules = require('erde.rules')
local tokenize = require('erde.tokenize')

-- =============================================================================
-- ParseCtx
-- =============================================================================

local ParseCtx = {}
local ParseCtxMT = { __index = ParseCtx }

-- Allow calling all rule parsers directly from parser
for ruleName, rule in pairs(rules) do
  ParseCtx[ruleName] = rule.parse
end

-- -----------------------------------------------------------------------------
-- Methods
-- -----------------------------------------------------------------------------

function ParseCtx:backup()
  local backup = {}

  for key, value in pairs(self) do
    if type(value) ~= 'function' then
      backup[key] = value
    end
  end

  return backup
end

function ParseCtx:restore(backup)
  for key, value in pairs(backup) do
    self[key] = value
  end
end

function ParseCtx:consume()
  local token = self.token

  self.tokenIndex = self.tokenIndex + 1
  self.token = self.tokens[self.tokenIndex]
  while self.token and self.token:match('^%-%-') do
    -- Skip comments
    -- TODO
    self.tokenIndex = self.tokenIndex + 1
    self.token = self.tokens[self.tokenIndex]
  end

  return token
end

function ParseCtx:peek(n)
  return self.tokens[self.tokenIndex + n] or ''
end

function ParseCtx:branch(token)
  if self.token ~= token then
    return false
  end

  self:consume()
  return true
end

function ParseCtx:assert(token, skipConsume)
  if self.token ~= token then
    error('Expected ' .. token .. ' got ' .. tostring(self.token))
  elseif not skipConsume then
    self:consume()
  end
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

function ParseCtx:Try(rule)
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

function ParseCtx:Switch(rules)
  for i, rule in ipairs(rules) do
    local node = self:Try(rule)
    if node then
      return node
    end
  end
end

function ParseCtx:Surround(openChar, closeChar, rule)
  self:assert(openChar)
  local capture = rule(self)
  self:assert(closeChar)
  return capture
end

function ParseCtx:Parens(opts)
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

function ParseCtx:List(opts)
  local list = {}
  local hasTrailingComma = false

  repeat
    local node = self:Try(opts.rule)
    if not node then
      break
    end

    if self.token ~= ',' then
      hasTrailingComma = false
    else
      self:consume()
      hasTrailingComma = true
    end

    list[#list + 1] = node
  until not hasTrailingComma

  assert(opts.allowTrailingComma or not hasTrailingComma)
  assert(opts.allowEmpty or #list > 0)

  return list, hasTrailingComma
end

-- =============================================================================
-- Parse
-- =============================================================================

local parse, parseMT = {}, {}

parseMT.__call = function(self, text)
  return parse.Block(text)
end

for ruleName, rule in pairs(rules) do
  parse[ruleName] = function(text, opts)
    local ctx = tokenize(text)
    setmetatable(ctx, ParseCtxMT)

    ctx.tokenIndex = 1
    ctx.token = ctx.tokens[1]

    -- Keep track of block depth. Especially useful to know whether we are at
    -- the top level for `module` declarations.
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

    return rules[ruleName].parse(ctx, opts)
  end
end

setmetatable(parse, parseMT)
return parse
