local C = require('erde.constants')

-- These operators cannot be used w/ operator assignment
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
  local node = { idList = ctx:List({ rule = ctx.Id }) }

  if BINOP_ASSIGNMENT_BLACKLIST[ctx.token] then
    error('Invalid assignment operator: ' .. ctx.token)
  elseif C.BINOPS[ctx.token] then
    node.op = C.BINOPS[ctx:consume()]
  end

  ctx:assert('=')
  node.exprList = ctx:List({ rule = ctx.Expr })
  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Assignment.compile(ctx, node)
  if not node.op then
    local compiled = {}
    local assignmentNames = {}

    for _, id in ipairs(node.idList) do
      if type(id) == 'string' then
        table.insert(assignmentNames, id)
      elseif id.ruleName ~= 'OptChain' then
        table.insert(assignmentNames, ctx:compile(id))
      else
        local optChain = ctx:compileOptChain(id)

        if #optChain.optSubChains == 0 then
          table.insert(assignmentNames, optChain.chain)
        else
          local assignmentName = ctx:newTmpName()
          table.insert(assignmentNames, assignmentName)

          local optChecks = {}
          for i, optSubChain in ipairs(optChain.optSubChains) do
            table.insert(optChecks, optSubChain .. ' ~= nil')
          end

          table.insert(
            compiled,
            ('if %s then %s end'):format(
              table.concat(optChecks, ' and '),
              optChain.chain .. ' = ' .. assignmentName
            )
          )
        end
      end
    end

    local assignmentExprs = {}
    for _, expr in ipairs(node.exprList) do
      table.insert(assignmentExprs, ctx:compile(expr))
    end

    local assignment = ('%s = %s'):format(
      table.concat(assignmentNames, ','),
      table.concat(assignmentExprs, ',')
    )

    table.insert(compiled, 1, assignment)
    return table.concat(compiled, '\n')
  else
    local compiled = {}

    local assignmentNames = {}
    for _, id in ipairs(node.idList) do
      table.insert(assignmentNames, ctx:newTmpName())
    end

    local assignmentExprs = {}
    for _, expr in ipairs(node.exprList) do
      table.insert(assignmentExprs, ctx:compile(expr))
    end

    table.insert(
      compiled,
      ('local %s = %s'):format(
        table.concat(assignmentNames, ','),
        table.concat(assignmentExprs, ',')
      )
    )

    for i, id in ipairs(node.idList) do
      local assignmentName = assignmentNames[i]

      if type(id) == 'string' then
        table.insert(
          compiled,
          id .. ' = ' .. ctx:compileBinop(node.op, id, assignmentName)
        )
      elseif id.ruleName ~= 'OptChain' then
        local compiledId = ctx:compile(id)
        table.insert(
          compiled,
          compiledId
            .. ' = '
            .. ctx:compileBinop(node.op, compiledId, assignmentName)
        )
      else
        local optChain = ctx:compileOptChain(id)
        local compiledAssignment = optChain.chain
          .. ' = '
          .. ctx:compileBinop(node.op, optChain.chain, assignmentName)

        if #optChain.optSubChains == 0 then
          table.insert(compiled, compiledAssignment)
        else
          local optChecks = {}
          for i, optSubChain in ipairs(optChain.optSubChains) do
            table.insert(optChecks, optSubChain .. ' ~= nil')
          end

          table.insert(
            compiled,
            ('if %s then %s end'):format(
              table.concat(optChecks, ' and '),
              table.insert(compiled, compiledAssignment)
            )
          )
        end
      end
    end

    return table.concat(compiled, '\n')
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Assignment
