local _ = require('erde.rules.helpers')

return {
  SubExpr = {
    pattern = _.Sum({
     _.CsV('ArrowFunction'),
     _.CsV('DoBlock'),
     _.CsV('IdExpr'),
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
      _.CsV('Op1'),
      _.CsV('SubExpr'),
    }),
  },
  ExprList = {
    pattern = _.Sum({
      -- Check list first to allow list items to consume parens
      -- This can be potential slow when ExprList is surrounded by parens
      -- (since List may essentially have to parsed twice), but suffices for
      -- now, as it is not an easy problem to solve and is one that doesn't 
      -- show up often
      _.List(_.CsV('Expr'), { minLen = 1 }),
      _.Parens(_.V('ExprList')),
    }),
  },
}
