local rules = require('erde.rules')
local state = require('erde.state')
local supertable = require('erde.supertable')
local inspect = require('inspect')
local lpeg = require('lpeg')

local erde = {}
local grammars = {}
lpeg.setmaxstack(1000)

function erde.parse(subject)
  if not grammars.parser then
    grammars.parser = lpeg.P(rules.parser)
  end
  state:reset()
  return grammars.parser:match(subject, nil, {}) or {}
end

function erde.compile(subject)
  if not grammars.compiler then
    grammars.compiler = lpeg.P(rules.compiler)
  end
  state:reset()
  return grammars.compiler:match(subject, nil, {})
end

function erde.format(subject)
  if not grammars.formatter then
    grammars.formatter = lpeg.P(rules.formatter)
  end
  state:reset()
  return grammars.formatter:match(subject, nil, {})
end

function erde.eval(erdecode)
  if _VERSION:find('5.1') then
    return loadstring(erde.compile(erdecode))()
  else
    return load(erde.compile(erdecode))()
  end
end

return erde
