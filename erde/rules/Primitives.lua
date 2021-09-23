local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  Number = {
    pattern = _.Sum({
      _.P('0') * _.S('xX') * (_.xdigit ^ 1),
      _.Product({
        (_.digit ^ 0 * _.P('.')) ^ -1,
        _.digit ^ 1,
        (_.S('eE') * _.S('+-') ^ -1 * _.digit ^ 1) ^ -1,
      }),
    }),
  },
  EscapedChar = {
    pattern = _.V('Newline') + _.P('\\') * _.P(1),
  },
  Interpolation = {
    pattern = _.P('{') * _.Pad(_.Expect(_.CsV('Expr'))) * _.P('}'),
    compiler = function(expr)
      return { interpolation = true, expr = expr }
    end,
  },
  LongString = {
    pattern = _.Product({
      _.P('`'),
      _.Sum({
        _.CsV('EscapedChar'),
        _.V('Interpolation'),
        _.C((_.P(1) - _.S('{`\\')) ^ 1),
      }) ^ 0,
      _.P('`'),
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
            or capture:gsub('\\([`{}])', '%1')
        end):join(),
        eqstr
      )
    end,
  },
  String = {
    pattern = _.Cs(_.Sum({
      _.P("'") * (_.V('EscapedChar') + _.P(1) - _.P("'")) ^ 0 * _.P("'"),
      _.P('"') * (_.V('EscapedChar') + _.P(1) - _.P('"')) ^ 0 * _.P('"'),
      _.V('LongString'),
    })),
    compiler = _.concat(),
  },
}
