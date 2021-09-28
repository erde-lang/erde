local _ = require('erde.rules.helpers')

return {
  SubExpr = {
    pattern = _.Sum({
     _.CsV('ArrowFunction'),
     _.CsV('IdExpr'),
     _.CsV('Table'),
     _.CsV('String'),
     _.CsV('Number'),
     _.C('...'),
     _.C('true'),
     _.C('false'),
     _.Parens(_.CsV('Expr')),
    }),
  },
  Expr = {
    pattern = _.Sum({
      _.CsV('Operation'),
      _.CsV('SubExpr'),
    }),
  },
  ExprList = {
    pattern = _.Parens(_.V('ExprList')) + _.List(_.CsV('Expr')),
  },
}
