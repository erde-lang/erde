local BINOP_ASSIGNMENT_BLACKLIST = {
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

local Assignment = { ruleName = 'Assignment' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Assignment.parse(ctx)
  local node = {
    idList = ctx:List({ rule = ctx.Id }),
    op = ctx:Binop(),
  }

  if node.op then
    if BINOP_ASSIGNMENT_BLACKLIST[node.op.token] then
      -- These operators cannot be used w/ operator assignment
      error()
    elseif #node.idList > 1 then
      -- Cannot use assignment operations w/ more than 1 assignment
      error()
    else
      ctx:consume(#node.op.token)
    end
  end

  ctx:assertChar('=')
  node.exprList = ctx:List({ rule = ctx.Expr })
  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

local function compileAssignment(ctx, id, expr, op)
  return op and id .. ' = ' .. ctx.compileBinop(op, id, expr)
    or id .. ' = ' .. expr
end

function Assignment.compile(ctx, node)
  local compiledAssignments = {}

  for i, id in ipairs(node.idList) do
    local optChain = id.ruleName == 'OptChain' and ctx:compileOptChain(id)
    local compiledAssignment = compileAssignment(
      ctx,
      optChain and optChain.chain or ctx:compile(id),
      node.exprList[i] and ctx:compile(node.exprList[i]) or 'nil',
      node.op
    )

    if optChain and #optChain.optSubChains > 0 then
      local optChecks = {}
      for i, optSubChain in ipairs(optChain.optSubChains) do
        optChecks[#optChecks + 1] = optSubChain .. ' ~= nil'
      end

      compiledAssignments[#compiledAssignments + 1] = table.concat({
        'if',
        table.concat(optChecks, ' and '),
        'then',
        compiledAssignment,
        'end',
      }, '\n')
    else
      compiledAssignments[#compiledAssignments + 1] = compiledAssignment
    end
  end

  return table.concat(compiledAssignments, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Assignment
