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
  local node

  if C.UNOPS[ctx.token] then
    node = { ruleName = Expr.ruleName }
    node.variant = 'unop'
    node.op = C.UNOPS[ctx:consume()]
    node.operand = ctx:Expr({ minPrec = node.op.prec + 1 })
  else
    node = ctx:Terminal()
  end

  local binop = C.BINOPS[ctx.token]
  while binop and binop.prec >= minPrec do
    ctx:consume()

    node = {
      ruleName = Expr.ruleName,
      variant = 'binop',
      op = binop,
      lhs = node,
    }

    if binop.token == '?' then
      ctx.isTernaryExpr = true
      node.ternaryExpr = ctx:Expr()
      ctx.isTernaryExpr = false
      ctx:assert(':')
    end

    local nextMinPrec = binop.prec
      + (binop.assoc == C.LEFT_ASSOCIATIVE and 1 or 0)
    node.rhs = ctx:Expr({ minPrec = nextMinPrec })

    binop = C.BINOPS[ctx.token]
  end

  if ctx.token == '>>' then
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

    if op.token == '.~' then
      return ('require("bit").bnot(%1)'):format(operand)
    elseif op.token == '~' then
      return compileUnop('not')
    else
      return op.token .. operand
    end
  elseif node.variant == 'binop' then
    local lhs = ctx:compile(node.lhs)
    local rhs = ctx:compile(node.rhs)

    if op.token == '?' then
      return table.concat({
        '(function()',
        'if %s then',
        'return %s',
        'else',
        'return %s',
        'end',
        'end)()',
      }, '\n'):format(lhs, ctx:compile(node.ternaryExpr), rhs)
    else
      return ctx:compileBinop(op, lhs, rhs)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Expr
