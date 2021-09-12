require('env')()
local supertable = require('supertable')
local Rule = require('rules.registry')

Rule('Newline', {
  parser = P('\n') * (Cp() / function(position)
    currentline = currentline + 1
    currentlinestart = position
  end),
})

Rule('Space', {
  parser = (V('Newline') + space) ^ 0,
})

Rule('Name ', {
  parser = C(-V('Keyword') * (alpha + P('_')) * (alnum + P('_')) ^ 0),
  compiler = echo,
})

Rule('Self', {
  parser = template('self'),
  compiler = echo,
})

Rule('SelfProperty ', {
  parser = Pad(P('@') * V('Name')),
  compiler = template('self.%1'),
})

Rule('Id', {
  parser = Product({
    Sum({
      PadC('(') * V('Expr') * PadC(')'),
      V('Name'),
      V('SelfProperty'),
      V('Self'),
    }),
    V('IndexChain') + Cc(supertable()),
  }),
  compiler = indexchain(template('return %1')),
})
