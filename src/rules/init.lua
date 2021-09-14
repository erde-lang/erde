require('env')()
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
        [rulename] = Cp() * rule.parser / function(position, ...)
          local node = supertable({ ... })
            :filter(function(value) return value ~= nil end)
            :merge({ rule = rulename, position = position })
          return #node > 0 and node or nil
        end,
      }),
      oldcompiler = rules.oldcompiler:merge({
        [rulename] = rule.oldcompiler,
      }),
      compiler = rules.compiler:merge({
        [rulename] = rule.parser / 
          (type(rule.compiler) == 'function' and rule.compiler or noop),
      })
    }
  end, {
    parser = supertable({ V('Block') }),
    oldcompiler = supertable(),
    compiler = supertable({ V('Block') }),
  })
