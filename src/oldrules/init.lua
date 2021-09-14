local lpeg = require('lpeg')
local supertable = require('supertable')

return supertable()
  :merge(require('oldrules.Core'))
  :merge(require('oldrules.Primitives'))
  :merge(require('oldrules.Tables'))
  :merge(require('oldrules.Functions'))
  :merge(require('oldrules.Operators'))
  :merge(require('oldrules.Expr'))
  :merge(require('oldrules.Logic'))
  :merge(require('oldrules.Block'))
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
