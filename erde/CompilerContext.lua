local Environment = require('erde.Environment')
local ParserContext = require('erde.ParserContext')
local constants = require('erde.constants')
local rules = require('erde.rules')

-- -----------------------------------------------------------------------------
-- CompilerContext
-- -----------------------------------------------------------------------------

local CompilerContext = {}
local CompilerContextMT = { __index = CompilerContext }

function CompilerContext:compile(node)
  if type(node) == 'string' then
    local parserCtx = ParserContext()
    node = parserCtx:parse(node)
  end

  if type(node) ~= 'table' or not rules[node.rule] then
    -- TODO
    print(require('inspect')(node))
    error('No node compiler for')
  end

  local compiled = rules[node.rule].compile(self, node)

  if node.parens then
    compiled = '(' .. compiled .. ')'
  end

  return compiled
end

-- -----------------------------------------------------------------------------
-- Compile Helpers
-- -----------------------------------------------------------------------------

local tmpNameCounter = 1
function CompilerContext.newTmpName()
  tmpNameCounter = tmpNameCounter + 1
  return ('__ERDE_TMP_%d__'):format(tmpNameCounter)
end

function CompilerContext.format(str, ...)
  for i, value in ipairs({ ... }) do
    str = str:gsub('%%' .. i, tostring(value))
  end

  return str
end

function CompilerContext.compileBinop(op, lhs, rhs)
  if op.tag == 'nc' then
    return CompilerContext.format(
      table.concat({
        '(function()',
        'local %1 = %2',
        'if %1 ~= nil then',
        'return %1',
        'else',
        'return %3',
        'end',
        'end)()',
      }, '\n'),
      CompilerContext.newTmpName(),
      lhs,
      rhs
    )
  elseif op.tag == 'or' then
    return table.concat({ lhs, ' or ', rhs })
  elseif op.tag == 'and' then
    return table.concat({ lhs, ' and ', rhs })
  elseif op.tag == 'bor' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' | ', rhs })
      or CompilerContext.format('require("bit").bor(%1, %2)', lhs, rhs)
  elseif op.tag == 'bxor' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' ~ ', rhs })
      or CompilerContext.format('require("bit").bxor(%1, %2)', lhs, rhs)
  elseif op.tag == 'band' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' & ', rhs })
      or CompilerContext.format('require("bit").band(%1, %2)', lhs, rhs)
  elseif op.tag == 'lshift' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' << ', rhs })
      or CompilerContext.format('require("bit").lshift(%1, %2)', lhs, rhs)
  elseif op.tag == 'rshift' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' >> ', rhs })
      or CompilerContext.format('require("bit").rshift(%1, %2)', lhs, rhs)
  elseif op.tag == 'intdiv' then
    return _VERSION:find('5.[34]') and table.concat({ lhs, ' // ', rhs })
      or CompilerContext.format('math.floor(%s / %s)', lhs, rhs)
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
