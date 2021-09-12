require('env')()
local lpeg = require('lpeg')
local Rule = require('rules.registry')

Rule('SubExpr ', {
  parser = Sum({
    V('FunctionCall'),
    V('Function'),
    V('IdExpr'),
    V('Table'),
    V('String'),
    V('Number'),
    PadC('true'),
    PadC('false'),
  }),
  compiler = echo,
})

Rule('Expr ', {
  parser = Sum({
    V('Operation'),
    V('SubExpr'),
  }),
  compiler = concat(),
})
