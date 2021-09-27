local _ = require('erde.rules.helpers')

return {
  SubExpr = {
    pattern = _.Sum({
     _.V('ArrowFunction'),
     _.V('IdExpr'),
     _.V('Table'),
     _.V('String'),
     _.V('Number'),
     _.P('true'),
     _.P('false'),
     _.Parens(_.V('Expr')),
    }),
  },
  Expr = {
    pattern = _.Sum({
      _.V('Operation'),
      _.V('SubExpr'),
    }),
  },
  ExprList = {
    pattern = _.Parens(_.V('ExprList')) + _.List(_.V('Expr')),
  },
}
