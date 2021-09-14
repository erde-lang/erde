local inspect = require('inspect')
local lpeg = require('lpeg')

local env = require('env')
local rules = require('rules')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Erde
-- -----------------------------------------------------------------------------

local grammar = lpeg.P(rules.parser)
local compilergrammar = lpeg.P(rules.compiler)
local erde = {}

-- -----------------------------------------------------------------------------
-- Parser
-- -----------------------------------------------------------------------------

function erde.parse(subject)
  lpeg.setmaxstack(1000)
  env:reset()
  local ast = grammar:match(subject, nil, {})
  return ast or {}
end

-- -----------------------------------------------------------------------------
-- Compiler
-- -----------------------------------------------------------------------------

local function isnode(node)
  return type(node) == 'table' and type(node.rule) == 'string'
end

function erde.oldcompile(node)
  if not isnode(node) then
    return subnode
  elseif type(rules.oldcompiler[node.rule]) == 'function' then
    return rules.oldcompiler[node.rule](unpack(node:ipairs():reduce(function(args, subnode)
      return args:push(unpack(isnode(subnode)
        and { erde.oldcompile(subnode) }
        or { subnode }
      ))
    end, supertable())))
  end
end

function erde.compile(subject)
  lpeg.setmaxstack(1000)
  env:reset()
  return compilergrammar:match(subject, nil, {})
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return erde
