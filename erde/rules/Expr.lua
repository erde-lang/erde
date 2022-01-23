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

  if C.UNOPS[ctx.token] then
    ctx:consume()
    node.variant = 'unop'
    node.operand = ctx:Expr({ minPrec = C.UNOPS[ctx.token].prec + 1 })
    node.op = ctx:consume()
  else
    node = ctx:Terminal()
  end

  while true do
    local binop = C.BINOPS[ctx.token]
    if not binop or binop.prec < minPrec then
      break
    end

    ctx:consume()

    node = {
      ruleName = Expr.ruleName,
      variant = 'binop',
      op = binop,
      node,
    }

    if binop.token == '?' then
      ctx.isTernaryExpr = true
      node[#node + 1] = ctx:Expr()
      ctx.isTernaryExpr = false
      assert(ctx.token == ':')
    end

    node[#node + 1] = binop.assoc == C.LEFT_ASSOCIATIVE
        and ctx:Expr({ minPrec = binop.prec + 1 })
      or ctx:Expr({ minPrec = binop.prec })
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
      return _VERSION:find('5.[34]') and compileUnop('~')
        or ('require("bit").bnot(%1)'):format(operand)
    elseif op.token == '~' then
      return compileUnop('not')
    else
      return op.token .. operand
    end
  elseif node.variant == 'binop' then
    local lhs = ctx:compile(node[1])
    local rhs = ctx:compile(node[2])

    if op.token == '?' then
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
