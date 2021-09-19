local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  Block = {
    pattern = _.Pad(_.V('Statement')) ^ 1 + _.Pad(_.Cc('')),
    compiler = _.concat('\n'),
    formatter = _.concat('\n'),
  },
  Statement = {
    pattern = _.Sum({
      _.V('Comment'),
      _.V('FunctionCall'),
      _.V('Assignment'),
      _.V('DestructureDeclaration'),
      _.V('VarArgsDeclaration'),
      _.V('NameDeclaration'),
      _.V('AssignOp'),
      _.V('Return'),
      _.V('IfElse'),
      _.V('NumericFor'),
      _.V('GenericFor'),
      _.V('WhileLoop'),
      _.V('RepeatUntil'),
      _.V('DoBlock'),
    }),
  },
  NameDeclaration = {
    pattern = _.Product({
      _.PadC('local') + _.C(false),
      _.CsV('Name'),
      (_.PadC('=') * _.CsV('Expr')) ^ -1,
    }),
    compiler = _.concat(' '),
  },
  VarArgsDeclaration = {
    pattern = _.Product({
      _.PadC('local') + _.C(false),
      _.Pad('...'),
      _.V('Name'),
      _.Demand(_.Pad('=') * _.V('Expr')),
    }),
    compiler = function(islocal, name, expr)
      return ('%s%s = { %s }'):format(islocal and 'local ' or '', name, expr)
    end,
  },
  DestructureDeclaration = {
    pattern = _.Product({
      _.PadC('local') + _.C(false),
      _.V('Destructure'),
      _.Demand(_.Pad('=') * _.V('Expr')),
    }),
    compiler = compiledestructure,
  },
  Assignment = {
    pattern = _.Sum({
      _.Pad('(') * _.CsV('Expr') * _.Pad(')') * _.V('IndexChain'),
      _.CsV('Name') * (_.V('IndexChain') + _.Cc(supertable())),
    }) * _.Pad('=') * _.CsV('Expr'),
    pattern = _.CsV('Id') * _.Pad('=') * _.CsV('Expr'),
    compiler = _.indexchain(_.template('%1 = %2')),
  },
}
