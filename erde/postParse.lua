-- -----------------------------------------------------------------------------
-- Link Rules
-- -----------------------------------------------------------------------------

function linkRules(node, parentRule)
  for i, child in ipairs(node) do
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

function resolveLoopStatements(node, loopNode)
  for i, rule in ipairs(node.childRules) do
    if rule.ruleName == 'Continue' then
      if loopNode == nil then
        error('missing loop for continue')
      else
        loopNode.continueNodes = loopNode.continueNodes or {}
        loopNode.continueNodes[#loopNode.continueNodes + 1] = rule
      end
    elseif rule.ruleName == 'Break' then
      if loopNode == nil then
        error('missing loop for break')
      end
    elseif rule.ruleName == 'Function' then
      resolveLoopStatements(rule)
    elseif
      rule.ruleName == 'ForLoop'
      or rule.ruleName == 'RepeatUntil'
      or rule.ruleName == 'WhileLoop'
    then
      resolveLoopStatements(rule, rule)
    else
      resolveLoopStatements(rule, forLoopNode)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return function(root)
  linkRules(root, root)
  resolveLoopStatements(root)
end
