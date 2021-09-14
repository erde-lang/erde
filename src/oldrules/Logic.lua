require('env')()

return {
  If = {
    parser = Pad('if') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  },
  ElseIf = {
    parser = Pad('elseif') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  },
  Else = {
    parser = Pad('else') * Pad('{') * V('Block') * Pad('}'),
  },
  IfElse = {
    parser = V('If') * V('ElseIf') ^ 0 * V('Else') ^ -1,
  },
}
