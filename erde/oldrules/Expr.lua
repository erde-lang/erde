local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Expr
-- -----------------------------------------------------------------------------

local Expr = { ruleName = 'Expr' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Expr.parse(ctx, opts)
  local minPrec = opts and opts.minPrec or 1
  local node = { ruleName = Expr.ruleName }
  local lhs

  local unop = ctx:Unop()
  if unop ~= nil then
    ctx:consume(#unop.token)
    node.variant = 'unop'
    node.op = unop
    node.operand = ctx:Expr({ minPrec = unop.prec + 1 })
  else
    node = ctx:Terminal()
  end

  while true do
    local binop = ctx:Binop()
    if not binop or binop.prec < minPrec then
      break
    end

    ctx:consume(#binop.token)

    node = {
      ruleName = Expr.ruleName,
      variant = 'binop',
      op = binop,
      node,
    }

    if binop.tag == 'ternary' then
      ctx.isTernaryExpr = true
      node[#node + 1] = ctx:Expr()
      ctx.isTernaryExpr = false
      ctx:assertChar(':')
    end

    node[#node + 1] = binop.assoc == C.LEFT_ASSOCIATIVE
        and ctx:Expr({ minPrec = binop.prec + 1 })
      or ctx:Expr({ minPrec = binop.prec })
  end

  if ctx:peek(2) == '>>' then
    return ctx:Pipe({
      initValues = { node },
    })
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Expr.compile(ctx, node)
  local op = node.op

  if node.variant == 'unop' then
    local operand = ctx:compile(node.operand)

    local function compileUnop(token)
      return table.concat({ token, operand }, ' ')
    end

    if op.tag == 'bnot' then
      return _VERSION:find('5.[34]') and compileUnop('~')
        or ('require("bit").bnot(%1)'):format(operand)
    elseif op.tag == 'not' then
      return compileUnop('not')
    else
      return op.token .. operand
    end
  elseif node.variant == 'binop' then
    local lhs = ctx:compile(node[1])
    local rhs = ctx:compile(node[2])

    if op.tag == 'ternary' then
      return table.concat({
        '(function()',
        'if %s then',
        'return %s',
        'else',
        'return %s',
        'end',
        'end)()',
      }, '\n'):format(lhs, rhs, ctx:compile(node[3]))
    else
      return ctx:compileBinop(op, lhs, rhs)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Expr
