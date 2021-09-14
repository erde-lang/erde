require('env')()

return {
  SubExpr = {
    pattern = Sum({
      PadC('(') * V('Expr') * PadC(')'),
      V('FunctionCall'),
      V('Function'),
      V('Id'),
      V('Table'),
      V('String'),
      V('Number'),
      PadC('true'),
      PadC('false'),
    }),
    oldcompiler = echo,
  },
  Expr = {
    pattern = Sum({
      V('Operation'),
      V('SubExpr'),
    }),
    oldcompiler = concat(),
  },
}
