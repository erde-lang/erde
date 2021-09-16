require('env')()

return {
  UnaryOp = {
    pattern = PadC(S('~-#')) * CsV('Expr'),
    compiler = function(op, expr)
      return op == '~'
        and ('not %s'):format(expr)
        or op .. expr
    end,
  },
  TernaryOp = {
    pattern = V('SubExpr') * Pad('?') * V('Expr') * Pad(':') * V('Expr'),
    compiler = iife('if %1 then return %2 else return %3 end'),
  },
  BinaryOp = {
    pattern = V('SubExpr') * Product({
      PadC(Sum({
        '+', P('-') - P('--'), '*', '//', '/', '^', '%', -- arithmetic
        '.|', '.&', '.~', '.>>', '.<<',     -- bitwise
        '==', '~=', '<=', '>=', '<', '>',   -- relational
        '&', '|', '..', '??',               -- misc
      })),
      V('Expr'),
    }),
    compiler = function(lhs, op, rhs)
      if op == '??' then
        return iife('local %1 = %2 if %1 ~= nil then return %1 else return %3 end')(newtmpname(), lhs, rhs)
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
    pattern = Product({
      V('Id'),
      Pad(C(Sum({
        '+', '-', '*', '//', '/', '^', '%', -- arithmetic
        '.|', '.&', '.~', '.>>', '.<<',     -- bitwise
        '&', '|', '..', '??',               -- misc
      })) * P('=')),
      V('Expr'),
    }),
    compiler = function(id, op, expr)
      if op == '??' then
        -- TODO: consider optional assign
        return 
      elseif op == '&' then
        return template('%1 = %1 and %2')(id, expr)
      elseif op == '|' then
        return template('%1 = %1 or %2')(id, expr)
      else
        return template('%1 = %1 %2 %3')(id, op, expr)
      end
    end,
  },
  Operation = {
    pattern = Sum({
      V('UnaryOp'),
      V('TernaryOp'),
      V('BinaryOp'),
      V('AssignOp'),
    }),
    compiler = echo,
  },
}
