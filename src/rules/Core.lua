require('env')()
local supertable = require('supertable')

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
      Pad('--') * (P(1) - V('Newline')) ^ 0,
      Pad('--[[') * (P(1) - P(']]--')) ^ 0 * Pad(']]--'),
    }),
  },
  Keyword = {
    pattern = Pad(Sum({ 'local', 'if', 'elseif', 'else', 'false', 'true', 'nil', 'return' })),
  },
  Name = {
    pattern = C(-V('Keyword') * (alpha + P('_')) * (alnum + P('_')) ^ 0),
    oldcompiler = echo,
  },
  Id = {
    pattern = Product({
      Sum({
        PadC('(') * V('Expr') * PadC(')'),
        V('Name'),
      }),
      V('IndexChain') + Cc(supertable()),
    }),
    oldcompiler = indexchain(template('return %1')),
  },
}
