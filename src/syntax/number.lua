require('env')()

return {
  grammar = {
    Hex = (P('0x') + P('0X')) * xdigit ^ 1,
    Exponent = S('eE') * S('+-') ^ -1 * digit ^ 1,
    Float = Ms({
      ((digit ^ 1 * P('.') * digit ^ 0) + (P('.') * digit ^ 1)) * V('Exponent') ^ -1,
      digit ^ 1 * V('Exponent'),
    }),
    Int = digit ^ 1,
    Number = T('Number', Cg(V('Hex') + V('Float') + V('Int'), 'value')),
  },

  compiler = {
    Number = function(v)
      return v.value
    end,
  },
}
