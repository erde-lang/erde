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
      CV('Number'),
      PadC('true'),
      PadC('false'),
      PadC('(') * V('Expr') * PadC(')'),
    }),
  },
  Expr = {
    pattern = Sum({
      V('Operation'),
      V('SubExpr'),
    }),
  },
}
