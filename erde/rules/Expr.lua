local _ = require('erde.rules.helpers')

return {
  SubExpr = {
    pattern = _.Sum({
     _.CsV('ArrowFunction'),
     _.CsV('IdExpr'),
     _.CsV('UnaryOp'),
     _.CsV('Table'),
     _.CsV('String'),
     _.CsV('Number'),
     _.C('...'),
     _.C('true'),
     _.C('false'),
     _.C('nil'),
     _.Parens(_.CsV('Expr')),
    }),
  },
  Expr = {
    pattern = _.Sum({
      _.CsV('BinaryOp'),
      _.CsV('TernaryOp'),
      _.CsV('PipeOp'),
      _.CsV('SubExpr'),
    }),
  },
  ExprList = {
    pattern = _.Sum({
      _.List(_.CsV('Expr')),
      _.Parens(_.V('ExprList')),
    }),
  },
}
