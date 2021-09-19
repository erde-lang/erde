local rules = require('erde.rules')
local state = require('erde.state')
local supertable = require('erde.supertable')
local inspect = require('inspect')
local lpeg = require('lpeg')

lpeg.setmaxstack(1000)

local parsergrammar = lpeg.P(rules.parser)
local compilergrammar = lpeg.P(rules.compiler)
local formattergrammar = lpeg.P(rules.formatter)

return {
  parse = function(subject)
    state:reset()
    return parsergrammar:match(subject, nil, {}) or {}
  end,
  compile = function(subject)
    state:reset()
    return compilergrammar:match(subject, nil, {})
  end,
  format = function(subject)
    state:reset()
    return formattergrammar:match(subject, nil, {})
  end,
}
