local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

-- TODO: create each grammar on demand to reduce loading time

return supertable(
  require('erde.rules.Core'),
  require('erde.rules.Primitives'),
  require('erde.rules.Tables'),
  require('erde.rules.Functions'),
  require('erde.rules.Operators'),
  require('erde.rules.Expr'),
  require('erde.rules.Logic'),
  require('erde.rules.Block')
):reduce(function(rules, rule, ruleName)
  local pattern = type(rule.pattern) == 'function'
    and rule.pattern() or rule.pattern

  rules.parser:merge({
    [ruleName] = _.Cp() * pattern / function(position, ...)
      local node = supertable({ ... })
        :filter(function(value) return value ~= nil end)
        :merge({ rule = ruleName, position = position })
      return #node > 0 and node or nil
    end,
  })

  rules.compiler:merge({
    [ruleName] = rule.compiler ~= nil
      and pattern / rule.compiler
      or pattern,
  })

  rules.formatter:merge({
    [ruleName] = rule.formatter ~= nil
      and pattern / rule.formatter
      or pattern,
  })

  return rules
end, {
  parser = supertable({ _.V('Block') }),
  compiler = supertable({ _.V('Block') }),
  formatter = supertable({ _.V('Block') }),
})
