local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Expr
-- -----------------------------------------------------------------------------

local Expr = { ruleName = 'Expr' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Expr.parse(ctx, minPrec)
  minPrec = minPrec or 1
  local node = { ruleName = Expr.ruleName }
  local lhs

  local unop = ctx:Unop()
  if unop ~= nil then
    ctx:consume(#unop.token)
    node.variant = 'unop'
    node.op = unop
    node.operand = ctx:Expr(unop.prec + 1)
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
      node[#node + 1] = ctx:Expr()
      if not ctx:branchChar(':') then
        ctx:throwExpected(':')
      end
    end

    node[#node + 1] = binop.assoc == constants.LEFT_ASSOCIATIVE
        and ctx:Expr(binop.prec + 1)
      or ctx:Expr(binop.prec)
  end

  return ctx:peek(2) == '>>' and ctx:Pipe({ node }) or node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Expr.compile(ctx, node)
  local op = node.op

  if node.variant == 'unop' then
    local operand = ctx:compile(node[1])

    local function compileUnop(token)
      return table.concat({ token, operand }, ' ')
    end

    if op.tag == 'bnot' then
      return _VERSION:find('5.[34]') and compileUnop('~')
        or ctx.format('require("bit").bnot(%1)', operand)
    elseif op.tag == 'not' then
      return compileUnop('not')
    else
      return op.token .. operand
    end
  elseif node.variant == 'binop' then
    local lhs = ctx:compile(node[1])
    local rhs = ctx:compile(node[2])

    if op.tag == 'ternary' then
      return ctx.format(
        table.concat({
          '(function()',
          'if %1 then',
          'return %2',
          'else',
          'return %3',
          'end',
          'end)()',
        }, '\n'),
        lhs,
        rhs,
        ctx:compile(node[3])
      )
    else
      return ctx.compileBinop(op, lhs, rhs)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Expr
