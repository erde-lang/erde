local rules = require('erde.rules')
local state = require('erde.state')
local supertable = require('erde.supertable')
local inspect = require('inspect')
local lpeg = require('lpeg')

local erde = {}
lpeg.setmaxstack(1000)

local parsergrammar = lpeg.P(rules.parser)
local compilergrammar = lpeg.P(rules.compiler)
local formattergrammar = lpeg.P(rules.formatter)

function erde.parse(subject)
  state:reset()
  return parsergrammar:match(subject, nil, {}) or {}
end

function erde.compile(subject)
  state:reset()
  return compilergrammar:match(subject, nil, {})
end

function erde.format(subject)
  state:reset()
  return formattergrammar:match(subject, nil, {})
end

function erde.eval(erdecode)
  if _VERSION:find('5.1') then
    return loadstring(erde.compile(erdecode))()
  else
    return load(erde.compile(erdecode))()
  end
end

return erde
