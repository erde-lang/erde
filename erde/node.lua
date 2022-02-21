local Rule, RuleMT = {}, {}
setmetatable(Rule, RuleMT)

RuleMT.__call = function(Rule, name)
  local rule = { name = name }
  setmetatable(rule, Rule)
  return rule
end

RuleMT.__newindex = function(rule, key, value)
  if key == 'parse' then
    rawset(rule, key, function(...)
      local node = value(...)

      -- TODO: remove this, assign unconditionally
      if node.ruleName == nil then
        node.ruleName = rule.ruleName
      end

      return node
    end)
  elseif key == 'compile' then
    rawset(rule, key, function(ctx, ...)
      local compiled = rule.compile(ctx, ...)

      -- TODO: move this to ctx:compile?
      if node.parens then
        compiled = '(' .. compiled .. ')'
      end

      return compiled
    end)
  else
    rawset(rule, key, value)
  end
end

return Rule
