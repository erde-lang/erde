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
    pattern = C(Product({
      -V('Keyword'),
      alpha + P('_'),
      (alnum + P('_')) ^ 0,
    })),
  },
  Id = {
    pattern = Sum({
      PadC('(') * CV('Expr') * PadC(')') * V('IndexChain'),
      CV('Name') * (V('IndexChain') + Cc(supertable())),
    }),
    compiler = indexchain(template('return %1')),
  },
}
