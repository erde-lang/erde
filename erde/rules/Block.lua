local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  Block = {
    pattern = _.Cc(true) * _.Pad(_.V('Statement')) ^ 1,
    compiler = _.concat('\n'),
    formatter = _.concat('\n'),
  },
  Statement = {
    pattern = _.Sum({
      _.V('Comment'),
      _.V('FunctionCall'),
      _.V('Assignment'),
      _.V('Declaration'),
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
  Declaration = {
    pattern = _.Product({
      _.Sum({
        _.Pad('local') * _.Cc(true),
        _.Pad('global') * _.Cc(false),
      }),
      _.Expect(_.Sum({
        _.V('Destructure') * _.Cc(true),
        _.CsV('Name') * _.Cc(false),
      })),
      (_.Pad('=') * _.CsV('Expr')) ^ -1,
    }),
    compiler = function(islocal, declaree, isdestructure, expr)
      local prefix = islocal and 'local ' or ''
      if isdestructure then
        return _.compiledestructure(islocal, declaree, expr)
      elseif expr then
        return ('%s%s = %s'):format(prefix, declaree, expr)
      elseif islocal then
        return ('%s%s'):format(prefix, declaree)
      end
    end,
  },
  Assignment = {
    pattern = _.V('Id') * _.Pad('=') * _.CsV('Expr'),
    compiler = _.indexchain(_.template('%1 = %2')),
  },
}
