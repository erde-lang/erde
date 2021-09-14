require('env')()
local inspect = require('inspect')
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
        [rulename] = Cp() * rule.pattern / function(position, ...)
          local node = supertable({ ... })
            :filter(function(value) return value ~= nil end)
            :merge({ rule = rulename, position = position })
          return #node > 0 and node or nil
        end,
      }),
      compiler = rules.compiler:merge({
        [rulename] = C('') * rule.pattern / function(_, ...)
          if type(rule.compiler) == 'function' and #{...} > 0 then
            return rule.compiler(...)
          end
        end,
      })
    }
  end, {
    parser = supertable({ V('Block') }),
    compiler = supertable({ V('Block') }),
  })
