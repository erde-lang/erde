local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return {
  Block = {
    pattern = _.Sum({
      _.Pad(_.Sum({
        _.CsV('Comment'),
        -- allow function calls as statements
        _.CsV('IdExpr') * _.B(')'),
        _.CsV('Assignment'),
        _.CsV('NameDeclaration'),
        _.CsV('FunctionDeclaration'),
        _.CsV('AssignOp'),
        _.CsV('Return'),
        _.CsV('IfElse'),
        _.CsV('NumericFor'),
        _.CsV('GenericFor'),
        _.CsV('WhileLoop'),
        _.CsV('RepeatUntil'),
        _.CsV('DoBlock'),
      })) ^ 1 / _.pack,
      -- Allow empty blocks. We have to produce at least one capture here or the
      -- entire V('Space') match will be passed
      _.Cc(true) * _.V('Space')
    }),
    compiler = function(block)
      return type(block) == 'table' and table.concat(block, '\n') or ''
    end,
  },
  BraceBlock = {
    pattern = _.Pad('{') * _.CsV('Block') * _.Pad('}') / 1,
  },
  NameDeclaration = {
    pattern = _.Product({
      _.Sum({
        _.Cc(true) * _.Pad('local'),
        _.Cc(false) * _.Pad('global'),
      }),
      _.Sum({
        _.Cc(true) * _.V('Destructure'),
        _.Cc(false) * _.CsV('Name'),
      }),
      (_.Pad('=') * _.CsV('Expr')) ^ -1,
    }),
    compiler = function(isLocal, isDestructure, declaree, expr)
      local prefix = isLocal and 'local ' or ''
      if isDestructure then
        return _.compileDestructure(isLocal, declaree, expr)
      elseif expr then
        return ('%s%s = %s'):format(prefix, declaree, expr)
      elseif isLocal then
        return ('%s%s'):format(prefix, declaree)
      else
        -- global declarations with no initializer do not warrant an output
        -- ex) `global x`
        return ''
      end
    end,
  },
  Assignment = {
    pattern = _.V('Id') * _.Pad('=') * _.CsV('Expr'),
    compiler = _.indexChain(function(id, expr)
      return id..' = '..expr
    end),
  },
}
