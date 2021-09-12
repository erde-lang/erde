require('env')()
local Rule = require('rules.registry')

Rule('Block', {
  parser = V('Statement') ^ 1 + Pad(Cc('')),
  compiler = concat('\n'),
})

Rule('Statement', {
  parser = Pad(Sum({
    -- V('FunctionCall'),
    V('Assignment'),
    V('DestructureDeclaration'),
    V('VarArgsDeclaration'),
    V('NameDeclaration'),
    V('AssignOp'),
    -- V('Return'),
    -- V('IfElse'),
    -- V('Comment'),
  })),
  compiler = echo,
})

Rule('NameDeclaration', {
  parser = Product({
    PadC('local') + C(false),
    V('Name'),
    (PadC('=') * Demand(V('Expr'))) ^ -1,
  }),
  compiler = concat(' '),
})

Rule('VarArgsDeclaration', {
  parser = Product({
    PadC('local') + C(false),
    Pad('...'),
    V('Name'),
    Demand(Pad('=') * V('Expr')),
  }),
  compiler = function(islocal, name, expr)
    return ('%s%s = { %s }'):format(islocal and 'local ' or '', name, expr)
  end,
})

Rule('DestructureDeclaration', {
  parser = Product({
    PadC('local') + C(false),
    V('Destructure'),
    Demand(Pad('=') * V('Expr')),
  }),
  compiler = compiledestructure,
})

Rule('Assignment', {
  parser = V('Id') * Pad('=') * V('Expr'),
  compiler = indexchain(template('%1 = %2')),
})
