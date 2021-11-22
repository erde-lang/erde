-- -----------------------------------------------------------------------------
-- Link Rules
-- -----------------------------------------------------------------------------

function linkRules(node, parentRule)
  for key, child in pairs(node) do
    if type(child) == 'table' then
      if child.ruleName == nil then
        linkRules(child, parentRule)
      else
        child.parentRule = parentRule
        parentRule.childRules[#parentRule.childRules + 1] = child
        child.childRules = child.childRules or {}
        linkRules(child, child)
      end
    end
  end
end

-- -----------------------------------------------------------------------------
-- Resolve Continue Statements
-- -----------------------------------------------------------------------------

function resolveLoopStatements(node, loopBodyNode)
  for i, rule in ipairs(node.childRules) do
    if rule.ruleName == 'Continue' then
      if loopBodyNode == nil then
        error('missing loop for continue')
      else
        loopBodyNode.continueNodes = loopBodyNode.continueNodes or {}
        loopBodyNode.continueNodes[#loopBodyNode.continueNodes + 1] = rule
      end
    elseif rule.ruleName == 'Break' then
      if loopBodyNode == nil then
        error('missing loop for break')
      end
    elseif rule.ruleName == 'Function' then
      resolveLoopStatements(rule)
    elseif
      rule.ruleName == 'ForLoop'
      or rule.ruleName == 'RepeatUntil'
      or rule.ruleName == 'WhileLoop'
    then
      resolveLoopStatements(rule.body, rule.body)
    else
      resolveLoopStatements(rule, loopBodyNode)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function(root)
  root.childRules = {}
  linkRules(root, root)
  resolveLoopStatements(root)
end
