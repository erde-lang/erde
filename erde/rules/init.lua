require('erde.env')()

return supertable()
  :merge(require('erde.rules.Core'))
  :merge(require('erde.rules.Primitives'))
  :merge(require('erde.rules.Tables'))
  :merge(require('erde.rules.Functions'))
  :merge(require('erde.rules.Operators'))
  :merge(require('erde.rules.Expr'))
  :merge(require('erde.rules.Logic'))
  :merge(require('erde.rules.Block'))
  :reduce(function(rules, rule, rulename)
    rules.parser:merge({
      [rulename] = Cp() * rule.pattern / function(position, ...)
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
    parser = supertable({ V('Block') }),
    compiler = supertable({ V('Block') }),
    formatter = supertable({ V('Block') }),
  })
