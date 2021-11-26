local Environment = require('erde.Environment')
local ParserContext = require('erde.ParserContext')
local constants = require('erde.constants')
local rules = require('erde.rules')

-- -----------------------------------------------------------------------------
-- CompilerContext
-- -----------------------------------------------------------------------------

local CompilerContext = {}
local CompilerContextMT = { __index = CompilerContext }

for ruleName, compiler in pairs(rules.compile) do
  CompilerContext[ruleName] = compiler
end

function CompilerContext:compile(node)
  if type(node) == 'string' then
    local parserCtx = ParserContext()
    node = parserCtx:parse(node)
  end

  if type(node) ~= 'table' or not rules.compile[node.ruleName] then
    -- TODO
    error('No node compiler for ' .. require('inspect')(node))
  end

  return rules.compile[node.ruleName](self, node)
end

-- -----------------------------------------------------------------------------
-- Compile Helpers
-- -----------------------------------------------------------------------------

local tmpNameCounter = 1
function CompilerContext.newTmpName()
  tmpNameCounter = tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(tmpNameCounter)
end

function CompilerContext.compileBinop(op, lhs, rhs)
  if op.tag == 'nc' then
    local ncTmpName = CompilerContext.newTmpName()
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

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function()
  return setmetatable({}, CompilerContextMT)
end
