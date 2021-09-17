require('env')()

return {
  Block = {
    pattern = Pad(V('Statement')) ^ 1 + Pad(Cc('')),
    compiler = concat('\n'),
  },
  Statement = {
    pattern = Sum({
      V('Comment'),
      V('FunctionCall'),
      V('Assignment'),
      V('DestructureDeclaration'),
      V('VarArgsDeclaration'),
      V('NameDeclaration'),
      V('AssignOp'),
      V('Return'),
      V('IfElse'),
    }),
  },
  NameDeclaration = {
    pattern = Product({
      PadC('local') + C(false),
      CsV('Name'),
      (PadC('=') * CsV('Expr')) ^ -1,
    }),
    compiler = concat(' '),
  },
  VarArgsDeclaration = {
    pattern = Product({
      PadC('local') + C(false),
      Pad('...'),
      V('Name'),
      Demand(Pad('=') * V('Expr')),
    }),
    compiler = function(islocal, name, expr)
      return ('%s%s = { %s }'):format(islocal and 'local ' or '', name, expr)
    end,
  },
  DestructureDeclaration = {
    pattern = Product({
      PadC('local') + C(false),
      V('Destructure'),
      Demand(Pad('=') * V('Expr')),
    }),
    compiler = compiledestructure,
  },
  Assignment = {
    pattern = V('Id') * Pad('=') * V('Expr'),
    compiler = indexchain(template('%1 = %2')),
  },
}
