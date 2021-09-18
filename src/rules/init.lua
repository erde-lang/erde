require('env')()

return supertable()
  :merge(require('rules.Core'))
  :merge(require('rules.Primitives'))
  :merge(require('rules.Tables'))
  :merge(require('rules.Functions'))
  :merge(require('rules.Operators'))
  :merge(require('rules.Expr'))
  :merge(require('rules.Logic'))
  :merge(require('rules.Block'))
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
