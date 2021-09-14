require('env')()

return {
  UnaryOp = {
    parser = PadC(S('~-#')) * V('Expr'),
    oldcompiler = function(op, expr)
      return op == '~'
        and ('not %s'):format(expr)
        or op .. expr
    end,
  },
  TernaryOp = {
    parser = V('SubExpr') * Pad('?') * V('Expr') * Pad(':') * V('Expr'),
    oldcompiler = iife('if %1 then return %2 else return %3 end'),
  },
  BinaryOp = {
    parser = V('SubExpr') * Product({
      PadC(Sum({
        '+', '-', '*', '//', '/', '^', '%', -- arithmetic
        '.|', '.&', '.~', '.>>', '.<<',     -- bitwise
        '==', '~=', '<=', '>=', '<', '>',   -- relational
        '&', '|', '..', '??',               -- misc
      })),
      V('Expr'),
    }),
    oldcompiler = function(lhs, op, rhs)
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
    parser = Product({
      V('Id'),
      Pad(C(Sum({
        '+', '-', '*', '//', '/', '^', '%', -- arithmetic
        '.|', '.&', '.~', '.>>', '.<<',     -- bitwise
        '&', '|', '..', '??',               -- misc
      })) * P('=')),
      V('Expr'),
    }),
    oldcompiler = function(id, op, expr)
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
    parser = Sum({
      V('UnaryOp'),
      V('TernaryOp'),
      V('BinaryOp'),
      V('AssignOp'),
    }),
    oldcompiler = echo,
  },
}
