require('env')()

return {
  SubExpr = {
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
  },
  Expr = {
    parser = Sum({
      V('Operation'),
      V('SubExpr'),
    }),
    compiler = concat(),
  },
}
