local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

local ArithmeticOp = { '+', _.P('-') - _.P('--'), '*', '//', '/', '^', '%' }
local Bitop = { '.|', '.&', '.~', '.>>', '.<<' }
local RelationalOp = { '==', '~=', '<=', '>=', '<', '>' }
local LogicalOp = { '&', '|' }
local MiscOp = { '..', '??' }

local function compileBinop(lhs, op, rhs)
  if op == '??' then
    return _.iife('local %1 = %2 if %1 ~= nil then return %1 else return %3 end')(_.newTmpName(), lhs, rhs)
  elseif op == '&' then
    return ('%s and %s'):format(lhs, rhs)
  elseif op == '|' then
    return ('%s or %s'):format(lhs, rhs)
  elseif op == '//' then
    -- This operator was added in Lua5.3, but we always use math.floor
    -- because its easier
    return ('math.floor(%s / %s)'):format(lhs, rhs)
  elseif op == '-' then
    -- Need the space, otherwise expressions like `1 - -1` will produce
    -- comments!
    return lhs ..op..' '..rhs
  else
    return lhs ..op..rhs
  end
end

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
    pattern = _.Product({
      _.CsV('SubExpr'),
      _.Pad(_.C(_.Sum(supertable(ArithmeticOp, Bitop, RelationalOp, LogicalOp, MiscOp)))),
      _.CsV('Expr'),
    }),
    compiler = compileBinop,
  },
  AssignOp = {
    pattern = _.Product({
      _.V('Id'),
      _.Pad(_.Product({
        _.C(_.Sum(supertable(ArithmeticOp, Bitop, LogicalOp, MiscOp))),
        _.P('=')
      })),
      _.CsV('Expr'),
    }),
    compiler = _.indexChain(function(id, op, expr)
      return id..'='..compileBinop(id, op, expr)
    end),
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
