require('env')()

return {
  If = {
    pattern = Pad('if') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  },
  ElseIf = {
    pattern = Pad('elseif') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  },
  Else = {
    pattern = Pad('else') * Pad('{') * V('Block') * Pad('}'),
  },
  IfElse = {
    pattern = V('If') * V('ElseIf') ^ 0 * V('Else') ^ -1,
  },
}
