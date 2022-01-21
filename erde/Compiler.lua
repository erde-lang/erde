local C = require('erde.constants')
local rules = require('erde.rules')

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local Compiler = setmetatable({}, {
  __call = function(self)
    local compiler = { tmpNameCounter = 1 }
    setmetatable(compiler, { __index = self })
    return compiler
  end,
})

-- Allow calling all rule compilers directly from context
for ruleName, ruleCompiler in pairs(rules.parse) do
  Compiler[ruleName] = ruleCompiler
end

-- -----------------------------------------------------------------------------
-- Methods
-- -----------------------------------------------------------------------------

function Compiler:reset()
  self.tmpNameCounter = 1
end

function Compiler:compile(node)
  if type(node) ~= 'table' or not rules.compile[node.ruleName] then
    -- TODO
    error('No node compiler for ' .. require('inspect')(node))
  end

  return rules.compile[node.ruleName](self, node)
end

function Compiler:newTmpName()
  self.tmpNameCounter = self.tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(self.tmpNameCounter)
end

-- -----------------------------------------------------------------------------
-- Macros
-- -----------------------------------------------------------------------------

-- TODO: rename
function Compiler:compileBinop(op, lhs, rhs)
  if op.tag == 'nc' then
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
  elseif op.tag == 'or' then
    return table.concat({ lhs, ' or ', rhs })
  elseif op.tag == 'and' then
    return table.concat({ lhs, ' and ', rhs })
  elseif op.tag == 'bor' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' | ', rhs })
      or ('require("bit").bor(%s, %s)'):format(lhs, rhs)
  elseif op.tag == 'bxor' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' ~ ', rhs })
      or ('require("bit").bxor(%s, %s)'):format(lhs, rhs)
  elseif op.tag == 'band' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' & ', rhs })
      or ('require("bit").band(%s, %s)'):format(lhs, rhs)
  elseif op.tag == 'lshift' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' << ', rhs })
      or ('require("bit").lshift(%s, %s)'):format(lhs, rhs)
  elseif op.tag == 'rshift' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' >> ', rhs })
      or ('require("bit").rshift(%s, %s)'):format(lhs, rhs)
  elseif op.tag == 'intdiv' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' // ', rhs })
      or ('math.floor(%s / %s)'):format(lhs, rhs)
  else
    return table.concat({ lhs, op.token, rhs }, ' ')
  end
end

-- TODO: rename
function Compiler:compileOptChain(node)
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
          _VERSION:find('5.1') and 'unpack' or 'table.unpack',
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

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Compiler
