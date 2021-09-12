require('erde.env')()

return {
  Newline = {
    pattern = P('\n') * (Cp() / function(position)
      currentline = currentline + 1
      currentlinestart = position
    end),
  },
  Space = {
    pattern = (V('Newline') + space) ^ 0,
  },
  Comment = {
    pattern = Sum({
      Pad('---') * (P(1) - P('---')) ^ 0 * Pad('---'),
      Pad('--') * (P(1) - V('Newline')) ^ 0,
    }),
  },
  Keyword = {
    pattern = Pad(Sum({ 'local', 'if', 'elseif', 'else', 'false', 'true', 'nil', 'return' })),
  },
  Name = {
    pattern = Product({
      -V('Keyword'),
      alpha + P('_'),
      (alnum + P('_')) ^ 0,
    }),
  },
  Id = {
    pattern = Sum({
      Pad('(') * CsV('Expr') * Pad(')') * V('IndexChain'),
      CsV('Name') * (V('IndexChain') + Cc(supertable())),
    }),
    compiler = indexchain(template('return %1')),
  },
  IdExpr = {
    pattern = V('Id'),
    compiler = indexchain(template('return %1')),
  },
}
