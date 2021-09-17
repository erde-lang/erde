require('env')()

return {
  If = {
    pattern = Pad('if') * CsV('Expr') * Pad('{') * CsV('Block') * Pad('}'),
    compiler = template('if %1 then %2'),
  },
  ElseIf = {
    pattern = Pad('elseif') * CsV('Expr') * Pad('{') * CsV('Block') * Pad('}'),
    compiler = template('elseif %1 then %2'),
  },
  Else = {
    pattern = Pad('else') * Pad('{') * CsV('Block') * Pad('}'),
    compiler = template('else %1'),
  },
  IfElse = {
    pattern = CsV('If') * CsV('ElseIf') ^ 0 * CsV('Else') ^ -1,
    compiler = function(...)
      return supertable({ ... }):push('end'):join(' ')
    end,
  },
}
