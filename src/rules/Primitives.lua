require('env')()
local inspect = require('inspect')
local supertable = require('supertable')

return {
  Number = {
    pattern = Sum({
      P('0') * S('xX') * (xdigit ^ 1),
      Product({
        (digit ^ 0 * P('.')) ^ -1,
        digit ^ 1,
        (S('eE') * S('+-') ^ -1 * digit ^ 1) ^ -1,
      }),
    }),
  },
  EscapedChar = {
    pattern = V('Newline') + P('\\') * P(1),
  },
  Interpolation = {
    pattern = P('{') * Pad(Demand(CsV('Expr'))) * P('}'),
    compiler = function(expr)
      return { interpolation = true, expr = expr }
    end,
  },
  LongString = {
    pattern = Product({
      P('`'),
      Sum({
        CsV('EscapedChar'),
        V('Interpolation'),
        C((P(1) - S('{`\\')) ^ 1),
      }) ^ 0,
      P('`'),
    }),
    compiler = function(...)
      local captures = supertable({ ... })

      local eqstr = '='
      local strcaptures = captures:filter(function(capture)
        return type(capture) == 'string'
      end)
      while strcaptures:find(function(capture) return capture:find(eqstr) end) do
        eqstr = ('='):rep(#eqstr + 1)
      end

      return ('[%s[%s]%s]'):format(
        eqstr,
        captures:map(function(capture)
          return capture.interpolation
            and (']%s]..tostring(%s)..[%s['):format(eqstr, capture.expr, eqstr)
            or capture
        end):join(),
        eqstr
      )
    end,
  },
  String = {
    pattern = SumCs({
      P("'") * (V('EscapedChar') + P(1) - P("'")) ^ 0 * P("'"),
      P('"') * (V('EscapedChar') + P(1) - P('"')) ^ 0 * P('"'),
      V('LongString'),
    }),
    compiler = concat(),
  },
}
