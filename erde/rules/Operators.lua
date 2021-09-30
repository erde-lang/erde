local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

-- NOTE1: Need to refactor to use arbitrary expressions (+ tests)
-- Probably need to recursively generate Expr based on order of operations.

local ArithmeticOp = { '+', _.P('-') - _.P('--'), '*', '//', '/', '^', '%' }
local Bitop = { '.|', '.&', '.~', '.>>', '.<<' }
local RelationalOp = { '==', '~=', '<=', '>=', '<', '>' }
local LogicalOp = { '&', '|' }
local MiscOp = { '..', '??' }

local function compileBinop(lhs, op, rhs)
  if op == '??' then
    local tmpName = _.newTmpName()
    return ([[(function()
      local %s = %s
      if %s ~= nil then return %s else return %s end
    end)()]]):format(tmpName, lhs, tmpName, tmpName, rhs)
  elseif op == '&' then
    return ('%s and %s'):format(lhs, rhs)
  elseif op == '|' then
    return ('%s or %s'):format(lhs, rhs)
  elseif op == '//' and not _VERSION:find('5.[34]') then
    return ('math.floor(%s / %s)'):format(lhs, rhs)
  elseif op == '-' then
    -- Need the space, otherwise expressions like `1 - -1` will produce
    -- comments!
    return lhs ..op..' '..rhs
  elseif op:sub(1, 1) == '.' and op ~= '..' then
    if _VERSION:find('5.[34]') then
      return lhs..op:sub(2)..rhs
    elseif op == '.|' then
      return ('require("bit").bor(%s,%s)'):format(lhs, rhs)
    elseif op == '.&' then
      return ('require("bit").band(%s,%s)'):format(lhs, rhs)
    elseif op == '.~' then
      return ('require("bit").bxor(%s,%s)'):format(lhs, rhs)
    elseif op == '.>>' then
      return ('require("bit").rshift(%s,%s)'):format(lhs, rhs)
    elseif op == '.<<' then
      return ('require("bit").lshift(%s,%s)'):format(lhs, rhs)
    end
  else
    return lhs ..op..rhs
  end
end

return {
  UnaryOp = {
    pattern = _.Product({
      _.Pad(_.C(_.Sum({
        _.P('.~'),
        _.P('~'),
        _.P('-'),
        _.P('#'),
      }))),
      _.CsV('SubExpr'), -- NOTE1
    }),
    compiler = function(op, expr)
      if op == '.~' then
        return _VERSION:find('5.[34]')
          and '~'..expr
          or 'require("bit").bnot('..expr..')'
      elseif op == '~' then
        return 'not '..expr
      else
        return op..expr
      end
    end,
  },
  TernaryOp = {
    pattern = _.Product({
      _.CsV('SubExpr'), -- NOTE1
      _.Pad('?'),
      _.CsV('Expr'),
      _.Pad(':'),
      _.CsV('Expr'),
    }),
    compiler = '(function() if %1 then return %2 else return %3 end end)()',
  },
  BinaryOp = {
    pattern = _.Product({
      _.CsV('SubExpr'), -- NOTE1
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
  PipeOp = {
    pattern = _.Product({
      _.CsV('SubExpr'), -- NOTE1
      _.Pad('>>'),
      _.Sum({
        _.Cc(1) * _.V('Id'),
        _.Cc(2) * _.CsV('Expr'),
      }),
      _.Product({
        -_.Pad(')'),
        _.Pad('?') * _.Cc(true) + _.Cc(false),
      }),
    }),
    compiler = function(pipee, variant, id, opt)
      local idCompiler = _.indexChain(
        function(id) return id end,
        function(id) return 'return '..id end
      )

      if variant == 1 then
        local lastChain = id.chain[#id.chain]

        if lastChain and lastChain.variant == 3 then
          lastChain.value:insert(1, pipee)
        else
          id.chain:push({
            opt = opt,
            variant = 3,
            value = supertable({ pipee }),
          })
        end

        return idCompiler(id)
      else
        return idCompiler({
          base = id,
          chain = {
            opt = opt,
            variant = 3,
            value = supertable({ pipee }),
          },
        })
      end
    end,
  },
}
