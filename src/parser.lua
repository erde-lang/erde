local lpeg = require('lpeg')
local grammar = require('grammar')

return {
  parse = function(subject, filename)
    lpeg.setmaxstack(1000)
    local cap = {}
    local ast = grammar:match(subject, nil, cap)
    return ast, cap
  end,
}
