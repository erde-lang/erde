local inspect = require('inspect')
local lpeg = require('lpeg')
local env = require('erde.env')
local rules = require('erde.rules')
local supertable = require('erde.supertable')

lpeg.setmaxstack(1000)

local parsergrammar = lpeg.P(rules.parser)
local compilergrammar = lpeg.P(rules.compiler)
local formattergrammar = lpeg.P(rules.formatter)

return {
  parse = function(subject)
    env:reset()
    return parsergrammar:match(subject, nil, {}) or {}
  end,
  compile = function(subject)
    env:reset()
    return compilergrammar:match(subject, nil, {})
  end,
  format = function(subject)
    env:reset()
    return formattergrammar:match(subject, nil, {})
  end,
}
