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
    pattern = P('{') * Pad(Demand(CV('Expr'))) * P('}'),
    compiler = function(expr)
      return { interpolation = true, expr = expr }
    end,
  },
  LongString = {
    pattern = Product({
      P('`'),
      Sum({
        CV('EscapedChar'),
        V('Interpolation'),
        C((P(1) - S('{`\\')) ^ 1),
      }) ^ 0,
      P('`'),
    }),
    compiler = function(...)
      local expressions = supertable({ ... })

      local eqstats = expressions:reduce(function(eqstats, char)
        return char ~= '='
          and { counter = 0, max = eqstats.max }
          or {
            counter = eqstats.counter + 1,
            max = math.max(eqstats.max, eqstats.counter + 1),
          }
      end, { counter = 0, max = 0 })

      local eqstr = ('='):rep(eqstats.max + 1)

      return ('[%s[%s]%s]'):format(
        eqstr,
        expressions:map(function(v)
          return v.interpolation
            and (']%s]..tostring(%s)..[%s['):format(eqstr, v.expr, eqstr)
            or v
        end):join(),
        eqstr
      )
    end,
  },
  String = {
    pattern = Sum({
      C(P("'") * (V('EscapedChar') + P(1) - P("'")) ^ 0 * P("'")),
      C(P('"') * (V('EscapedChar') + P(1) - P('"')) ^ 0 * P('"')),
      V('LongString'),
    }),
    compiler = concat(),
  },
}
