local _ = require('erde.rules.helpers')

return {
  UnaryOp = {
    pattern = _.Pad(_.C(_.S('~-#'))) * _.CsV('Expr'),
    compiler = function(op, expr)
      return op == '~' and 'not '..expr or op..expr
    end,
  },
  TernaryOp = {
    pattern = _.Product({
      _.CsV('SubExpr'),
      _.Pad('?'),
      _.CsV('Expr'),
      _.Pad(':'),
      _.CsV('Expr'),
    }),
    compiler = '(function() if %1 then return %2 else return %3 end end)()',
  },
  BinaryOp = {
    pattern = _.CsV('SubExpr') * _.Product({
      _.Pad(_.C(_.Sum({
        '+', _.P('-') - _.P('--'), '*', '//', '/', '^', '%', -- arithmetic
        '.|', '.&', '.~', '.>>', '.<<',     -- bitwise
        '==', '~=', '<=', '>=', '<', '>',   -- relational
        '&', '|', '..', '??',               -- misc
      }))),
      _.CsV('Expr'),
    }),
    compiler = function(lhs, op, rhs)
      if op == '??' then
        return _.iife('local %1 = %2 if %1 ~= nil then return %1 else return %3 end')(_.newtmpname(), lhs, rhs)
      elseif op == '&' then
        return ('%s and %s'):format(lhs, rhs)
      elseif op == '|' then
        return ('%s or %s'):format(lhs, rhs)
      else
        return lhs .. op .. rhs
      end
    end,
  },
  AssignOp = {
    pattern = _.Product({
      _.V('Id'),
      _.Pad(_.Product({
        _.C(_.Sum({
          '+', '-', '*', '//', '/', '^', '%', -- arithmetic
          '.|', '.&', '.~', '.>>', '.<<',     -- bitwise
          '&', '|', '..', '??',               -- misc
        })),
        _.P('=')
      })),
      _.CsV('Expr'),
    }),
    compiler = function(id, op, expr)
      if op == '??' then
        -- TODO: consider optional assign
        return 
      elseif op == '&' then
        return _.template('%1 = %1 and %2')(id, expr)
      elseif op == '|' then
        return _.template('%1 = %1 or %2')(id, expr)
      else
        return _.template('%1 = %1 %2 %3')(id, op, expr)
      end
    end,
  },
  Operator = {
    pattern = _.Sum({
      _.CsV('UnaryOp'),
      _.CsV('TernaryOp'),
      _.CsV('BinaryOp'),
      _.CsV('AssignOp'),
    }),
    compiler = _.echo,
  },
}
