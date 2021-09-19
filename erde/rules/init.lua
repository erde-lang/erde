local _ = require('erde.rules.helpers')
local supertable = require('erde.supertable')

return supertable(
  require('erde.rules.Core'),
  require('erde.rules.Primitives'),
  require('erde.rules.Tables'),
  require('erde.rules.Functions'),
  require('erde.rules.Operators'),
  require('erde.rules.Expr'),
  require('erde.rules.Logic'),
  require('erde.rules.Block')
):reduce(function(rules, rule, rulename)
  rules.parser:merge({
    [rulename] = _.Cp() * rule.pattern / function(position, ...)
      local node = supertable({ ... })
        :filter(function(value) return value ~= nil end)
        :merge({ rule = rulename, position = position })
      return #node > 0 and node or nil
    end,
  })

  rules.compiler:merge({
    [rulename] = rule.compiler ~= nil
      and rule.pattern / rule.compiler
      or rule.pattern,
  })

  rules.formatter:merge({
    [rulename] = rule.formatter ~= nil
      and rule.pattern / rule.formatter
      or rule.pattern,
  })

  return rules
end, {
  parser = supertable({ _.V('Block') }),
  compiler = supertable({ _.V('Block') }),
  formatter = supertable({ _.V('Block') }),
})
