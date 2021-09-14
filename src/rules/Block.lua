require('env')()

return {
  Block = {
    pattern = V('Statement') ^ 1 + Pad(Cc('')),
    oldcompiler = concat('\n'),
  },
  Statement = {
    pattern = Pad(Sum({
      V('FunctionCall'),
      V('Assignment'),
      V('DestructureDeclaration'),
      V('VarArgsDeclaration'),
      V('NameDeclaration'),
      V('AssignOp'),
      V('Return'),
      V('IfElse'),
      V('Comment'),
    })),
    oldcompiler = echo,
  },
  NameDeclaration = {
    pattern = Product({
      PadC('local') + C(false),
      V('Name'),
      (PadC('=') * Demand(V('Expr'))) ^ -1,
    }),
    oldcompiler = concat(' '),
  },
  VarArgsDeclaration = {
    pattern = Product({
      PadC('local') + C(false),
      Pad('...'),
      V('Name'),
      Demand(Pad('=') * V('Expr')),
    }),
    oldcompiler = function(islocal, name, expr)
      return ('%s%s = { %s }'):format(islocal and 'local ' or '', name, expr)
    end,
  },
  DestructureDeclaration = {
    pattern = Product({
      PadC('local') + C(false),
      V('Destructure'),
      Demand(Pad('=') * V('Expr')),
    }),
    oldcompiler = compiledestructure,
  },
  Assignment = {
    pattern = V('Id') * Pad('=') * V('Expr'),
    oldcompiler = indexchain(template('%1 = %2')),
  },
}
