local inspect = require('inspect')
local lpeg = require('lpeg')

local env = require('env')
local oldrules = require('oldrules')
local rules = require('rules')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Erde
-- -----------------------------------------------------------------------------

lpeg.setmaxstack(1000)
local oldgrammar = lpeg.P(oldrules.parser)
local parsergrammar = lpeg.P(rules.parser)
local compilergrammar = lpeg.P(rules.compiler)
local formattergrammar = lpeg.P(rules.formatter)
local erde = {}

-- -----------------------------------------------------------------------------
-- Parser
-- -----------------------------------------------------------------------------

function erde.parse(subject)
  env:reset()
  return parsergrammar:match(subject, nil, {}) or {}
end

function erde.compile(subject)
  env:reset()
  return compilergrammar:match(subject, nil, {})
end

function erde.format(subject)
  env:reset()
  return formattergrammar:match(subject, nil, {})
end

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local function isnode(node)
  return type(node) == 'table' and type(node.rule) == 'string'
end

function erde.compilenode(node)
  if not isnode(node) then
    return subnode
  elseif type(oldrules.compiler[node.rule]) == 'function' then
    return oldrules.compiler[node.rule](unpack(node:ipairs():reduce(function(args, subnode)
      return args:push(unpack(isnode(subnode)
        and { erde.compilenode(subnode) }
        or { subnode }
      ))
    end, supertable())))
  end
end

function erde.oldcompile(subject)
  env:reset()
  local ast = oldgrammar:match(subject, nil, {}) or {}
  return erde.compilenode(ast)
end

function erde.compile(subject)
  env:reset()
  return compilergrammar:match(subject, nil, {})
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return erde
