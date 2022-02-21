local C = require('erde.constants')
local parse = require('erde.parse')
local rules = require('erde.rules')

-- =============================================================================
-- CompileCtx
-- =============================================================================

local CompileCtx = {}
local CompileCtxMT = { __index = CompileCtx }

-- Allow calling all rule compilers directly from compiler
for ruleName, rule in pairs(rules) do
  CompileCtx[ruleName] = rule.compile
end

-- -----------------------------------------------------------------------------
-- Methods
-- -----------------------------------------------------------------------------

function CompileCtx:compile(node)
  if type(node) ~= 'table' or not rules[node.ruleName] then
    error('No compiler for ruleName: ' .. tostring(node.ruleName))
  end

  return rules[node.ruleName].compile(self, node)
end

function CompileCtx:newTmpName()
  self.tmpNameCounter = self.tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(self.tmpNameCounter)
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

-- TODO: rename
function CompileCtx:compileBinop(op, lhs, rhs)
  if op.token == '??' then
    local ncTmpName = self:newTmpName()
    return table.concat({
      '(function()',
      ('local %s = %s'):format(ncTmpName, lhs),
      'if ' .. ncTmpName .. ' ~= nil then',
      'return ' .. ncTmpName,
      'else',
      'return ' .. rhs,
      'end',
      'end)()',
    }, '\n')
  elseif op.token == '|' then
    return table.concat({ lhs, ' or ', rhs })
  elseif op.token == '&' then
    return table.concat({ lhs, ' and ', rhs })
  elseif op.token == '.|' then
    return ('require("bit").bor(%s, %s)'):format(lhs, rhs)
  elseif op.token == '.~' then
    return ('require("bit").bxor(%s, %s)'):format(lhs, rhs)
  elseif op.token == '.&' then
    return ('require("bit").band(%s, %s)'):format(lhs, rhs)
  elseif op.token == '.<<' then
    return ('require("bit").lshift(%s, %s)'):format(lhs, rhs)
  elseif op.token == '.>>' then
    return ('require("bit").rshift(%s, %s)'):format(lhs, rhs)
  elseif op.token == '//' then
    return ('math.floor(%s / %s)'):format(lhs, rhs)
  else
    return table.concat({ lhs, op.token, rhs }, ' ')
  end
end

-- TODO: rename
function CompileCtx:compileOptChain(node)
  local chain = self:compile(node.base)
  local optSubChains = {}

  for i, chainNode in ipairs(node) do
    if chainNode.optional then
      optSubChains[#optSubChains + 1] = chain
    end

    local newSubChainFormat
    if chainNode.variant == 'dotIndex' then
      chain = ('%s.%s'):format(chain, chainNode.value)
    elseif chainNode.variant == 'bracketIndex' then
      -- Space around brackets to avoid long string expressions
      -- [ [=[some string]=] ]
      chain = ('%s[ %s ]'):format(chain, self:compile(chainNode.value))
    elseif chainNode.variant == 'functionCall' then
      local hasSpread = false
      for i, arg in ipairs(chainNode.value) do
        if arg.ruleName == 'Spread' then
          hasSpread = true
          break
        end
      end

      if hasSpread then
        local spreadFields = {}

        for i, arg in ipairs(chainNode.value) do
          spreadFields[i] = arg.ruleName == 'Spread' and arg
            or { value = self:compile(expr) }
        end

        chain = ('%s(%s(%s))'):format(
          chain,
          'unpack',
          self:Spread(spreadFields)
        )
      else
        local args = {}

        for i, arg in ipairs(chainNode.value) do
          args[#args + 1] = self:compile(arg)
        end

        chain = chain .. '(' .. table.concat(args, ',') .. ')'
      end
    elseif chainNode.variant == 'method' then
      chain = chain .. ':' .. chainNode.value
    end
  end

  return { optSubChains = optSubChains, chain = chain }
end

-- =============================================================================
-- Compile
-- =============================================================================

local compile, compileMT = {}, {}

compileMT.__call = function(self, text)
  return compile.Block(text)
end

for ruleName, rule in pairs(rules) do
  compile[ruleName] = function(text, parseOpts)
    local ast = parse[ruleName](text, parseOpts)

    local ctx = {}
    setmetatable(ctx, CompileCtxMT)

    ctx.tmpNameCounter = 1
    ctx.sourceMap = {}

    return rules[ruleName].compile(ctx, ast)
  end
end

setmetatable(compile, compileMT)
return compile
