require('env')()
local inspect = require('inspect')

return {
  SubExpr = {
    pattern = Sum({
      V('FunctionCall'),
      V('Function'),
      V('Id'),
      V('Table'),
      V('String'),
      V('Number'),
      P('true'),
      P('false'),
      Pad('(') * V('Expr') * Pad(')'),
    }),
  },
  Expr = {
    pattern = Sum({
      V('Operation'),
      V('SubExpr'),
    }),
  },
}
