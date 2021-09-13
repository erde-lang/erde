require('env')()
local supertable = require('supertable')

return {
  Newline = {
    parser = P('\n') * (Cp() / function(position)
      currentline = currentline + 1
      currentlinestart = position
    end),
  },
  Space = {
    parser = (V('Newline') + space) ^ 0,
  },
  Comment = {
    parser = Sum({
      Pad('--') * (P(1) - V('Newline')) ^ 0,
      Pad('--[[') * (P(1) - P(']]--')) ^ 0 * Pad(']]--'),
    }),
  },
  Keyword = {
    parser = Pad(Sum({ 'local', 'if', 'elseif', 'else', 'false', 'true', 'nil', 'return' })),
  },
  Name = {
    parser = C(-V('Keyword') * (alpha + P('_')) * (alnum + P('_')) ^ 0),
    compiler = echo,
  },
  Self = {
    parser = Pad('@'),
    compiler = echo,
  },
  SelfProperty  = {
    parser = Pad(P('@') * V('Name')),
    compiler = template('self.%1'),
  },
  Id = {
    parser = Product({
      Sum({
        PadC('(') * V('Expr') * PadC(')'),
        V('Name'),
        V('SelfProperty'),
        V('Self'),
      }),
      V('IndexChain') + Cc(supertable()),
    }),
    -- compiler = indexchain(template('return %1')),
  },
}
