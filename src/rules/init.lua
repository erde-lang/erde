local lpeg = require('lpeg')
local supertable = require('supertable')

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
    return {
      parser = rules.parser:merge({
        [rulename] = lpeg.Cp() * rule.parser / function(position, ...)
          local node = supertable({ ... })
            :filter(function(value) return value ~= nil end)
            :merge({ rule = rulename, position = position })
          return #node > 0 and node or nil
        end,
      }),
      compiler = rules.compiler:merge({
        [rulename] = rule.compiler,
      }),
    }
  end, { parser = supertable({ lpeg.V('Block') }), compiler = supertable() })
