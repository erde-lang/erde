local constants = require('erde.constants')

local BINOP_ASSIGNMENT_BLACKLIST = {
  ['>>'] = true,
  ['?'] = true,
  ['=='] = true,
  ['~='] = true,
  ['<='] = true,
  ['>='] = true,
  ['<'] = true,
  ['>'] = true,
}

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

local Assignment = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Assignment.parse(ctx)
  local node = {}

  node.idList = { ctx:Id() }
  while ctx:branchChar(',') do
    node.idList[#node.idList + 1] = ctx:Id()
  end

  for i = BINOP_MAX_LEN, 1, -1 do
    local opToken = peek(i)
    local op = BINOP_MAP[opToken]

    if op and not BINOP_ASSIGNMENT_BLACKLIST[opToken] then
      if #node.idList > 1 then
        throw.error(
          'Cannot use assignment operations w/ more than 1 assignment'
        )
      else
        ctx:consume(i)
        node.op = op
        break
      end
    end
  end

  if not ctx:branchChar('=') then
    ctx:throwExpected('=')
  end

  node.exprList = { ctx:Expr() }
  while ctx:branchChar(',') do
    node.exprList[#node.exprList + 1] = ctx:Expr()
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Assignment.compile(ctx, node)
  local idList = {}
  for i, id in ipairs(node.idList) do
    idList[#idList + 1] = compile(id)
  end

  local exprList = {}
  for i, expr in ipairs(node.exprList) do
    exprList[#exprList + 1] = compile(expr)
  end

  if node.op then
    return format(
      '%1 = %2',
      idList[1],
      compileBinop(node.op, idList[1], exprList[1])
    )
  else
    return format(
      '%1 = %2',
      table.concat(idList, ','),
      table.concat(exprList, ',')
    )
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Assignment
